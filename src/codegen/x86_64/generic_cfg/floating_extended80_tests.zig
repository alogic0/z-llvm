const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");

test "floating extended sign operations preserve every payload bit" {
    const values = [_]u128{ 0, 1, @as(u128, 1) << 127, std.math.maxInt(u128),
        0x7fff8000000000000001, 0xffffc000000000000123,
        0x7fff0000000000000000000000000001, 0xffff8000000000000000000000000123 };
    for ([_]u16{ 80, 128 }) |width| for (0..3) |operation| {
        const ty = if (width == 80) "x86_fp80" else "fp128";
        const suffix = if (width == 80) "f80" else "f128";
        const statement = switch (operation) {
            0 => try std.fmt.allocPrint(std.testing.allocator, " %r = fneg {s} %a\n", .{ty}),
            1 => try std.fmt.allocPrint(std.testing.allocator, " %r = call {s} @llvm.fabs.{s}({s} %a)\n", .{ ty, suffix, ty }),
            else => try std.fmt.allocPrint(std.testing.allocator, " %r = call {s} @llvm.copysign.{s}({s} %a,{s} %b)\n", .{ ty, suffix, ty, ty }),
        };
        defer std.testing.allocator.free(statement);
        const finish = if (width == 80) " %answer = zext i80 %raw to i128\n" else " %answer = add i128 %raw,0\n";
        const source = try std.fmt.allocPrint(std.testing.allocator,
            "target datalayout = \"e-i128:128-f80:128\"\ndeclare {s} @llvm.fabs.{s}({s})\ndeclare {s} @llvm.copysign.{s}({s},{s})\ndefine i128 @sign(ptr %left,ptr %right,ptr %output) {{\nentry:\n %a = load {s},ptr %left,align 1\n %b = load {s},ptr %right,align 1\n{s} store {s} %r,ptr %output,align 1\n %raw = bitcast {s} %r to i{d}\n{s} ret i128 %answer\n}}\n",
            .{ ty, suffix, ty, ty, suffix, ty, ty, ty, ty, statement, ty, ty, width, finish });
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
        var output = machine.MachineFunction.init("sign", .{ .int = 128 });
        defer output.deinit(std.testing.allocator);
        const selected = try selector.tryLowerWithContext(std.testing.allocator, &output, module.functions.items[0], &context);
        if (selected == .unsupported) std.debug.print("floating sign width={d} operation={d}: {s}\n", .{ width, operation, selected.unsupported.detail() });
        try std.testing.expectEqual(selector.SelectionResult.selected, selected);
        try verify.verifyFunction(output);
        const bytes = try encoding.encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(bytes);
        const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(code);
        @memcpy(code[0..bytes.len], bytes);
        const run: *const fn (*const u8, *const u8, *u8) callconv(.c) u128 = @ptrCast(code.ptr);
        const bit: u128 = @as(u128, 1) << @as(u7, @intCast(width - 1));
        const mask: u128 = if (width == 128) std.math.maxInt(u128) else (@as(u128, 1) << 80) - 1;
        for (values) |left| for (values) |right| {
            const expected = switch (operation) { 0 => (left ^ bit) & mask, 1 => left & (bit - 1), else => (left & (bit - 1)) | (right & bit) };
            var a: [16]u8 = undefined;
            var b: [16]u8 = undefined;
            var stored: [32]u8 = @splat(0xa7);
            std.mem.writeInt(u128, &a, left, .little);
            std.mem.writeInt(u128, &b, right, .little);
            try std.testing.expectEqual(expected, run(&a[0], &b[0], &stored[1]));
            var decoded: [16]u8 = @splat(0);
            const size = width / 8;
            @memcpy(decoded[0..size], stored[1..][0..size]);
            try std.testing.expectEqual(expected, std.mem.readInt(u128, &decoded, .little));
            try std.testing.expectEqual(@as(u8, 0xa7), stored[0]);
            for (stored[1 + size ..]) |byte| try std.testing.expectEqual(@as(u8, 0xa7), byte);
        };
    };
}

test "extended80 predicates match native comparisons including NaNs zeros and pseudo-denormals" {
    const predicates = [_]ir.FcmpPredicate{ .false, .oeq, .ogt, .oge, .olt, .ole, .one, .ord, .ueq, .ugt, .uge, .ult, .ule, .une, .uno, .true };
    const values = [_]u80{ 0, @as(u80, 1) << 79, 1, 0x80000000000000000001, 0x00008000000000000000, 0x00018000000000000000, 0x3fff8000000000000000, 0xbfff8000000000000000, 0x7fff8000000000000000, 0xffff8000000000000000, 0x7fffc000000000000123, 0x7fff8000000000000001, 0x3fff0000000000000000, 0x7fff0000000000000000 };
    for (predicates) |predicate| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "target datalayout = \"e-i128:128-f80:128\"\ndefine i64 @compare(ptr %a,ptr %b) {{\nentry:\n %x = load x86_fp80,ptr %a,align 1\n %y = load x86_fp80,ptr %b,align 1\n %c = fcmp {s} x86_fp80 %x,%y\n %answer = zext i1 %c to i64\n ret i64 %answer\n}}\n", .{@tagName(predicate)});
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
        var output = machine.MachineFunction.init("compare", .{ .int = 64 });
        defer output.deinit(std.testing.allocator);
        const selected = try selector.tryLowerWithContext(std.testing.allocator, &output, module.functions.items[0], &context);
        if (selected == .unsupported) std.debug.print("extended80 predicate {s}: {s}\n", .{ @tagName(predicate), selected.unsupported.detail() });
        try std.testing.expectEqual(selector.SelectionResult.selected, selected);
        try verify.verifyFunction(output);
        const bytes = try encoding.encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(bytes);
        const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(code);
        @memcpy(code[0..bytes.len], bytes);
        const run: *const fn (*const u8, *const u8) callconv(.c) u64 = @ptrCast(code.ptr);
        for (values) |a| for (values) |b| {
            const x: f80 = @bitCast(a);
            const y: f80 = @bitCast(b);
            const unordered = x != x or y != y;
            const expected = switch (predicate) {
                .false => false,
                .true => true,
                .oeq => !unordered and x == y,
                .one => !unordered and x != y,
                .olt => !unordered and x < y,
                .ole => !unordered and x <= y,
                .ogt => !unordered and x > y,
                .oge => !unordered and x >= y,
                .ord => !unordered,
                .uno => unordered,
                .ueq => unordered or x == y,
                .une => unordered or x != y,
                .ult => unordered or x < y,
                .ule => unordered or x <= y,
                .ugt => unordered or x > y,
                .uge => unordered or x >= y,
            };
            var ab: [10]u8 = undefined;
            var bb: [10]u8 = undefined;
            std.mem.writeInt(u80, &ab, a, .little);
            std.mem.writeInt(u80, &bb, b, .little);
            const actual = run(&ab[0], &bb[0]);
            if (actual != @intFromBool(expected)) std.debug.print("predicate={s} x={x} y={x} actual={d} expected={}\n", .{ @tagName(predicate), a, b, actual, expected });
            try std.testing.expectEqual(@as(u64, @intFromBool(expected)), actual);
        };
    }
}

test "extended80 floating casts use exact wide intermediates and mixed ABI helpers" {
    for ([_]ir.Type{ .half, .float, .double, .fp128 }) |other| for ([_]bool{ false, true }) |to_extended| {
        const from: ir.Type = if (to_extended) other else .x86_fp80;
        const to: ir.Type = if (to_extended) .x86_fp80 else other;
        const widen = if (to_extended) other != .fp128 else other == .fp128;
        const source = try std.fmt.allocPrint(std.testing.allocator, "target datalayout = \"e-i128:128-f80:128\"\ndefine void @convert(ptr %input,ptr %output) {{\nentry:\n %x = load {f},ptr %input,align 1\n %r = {s} {f} %x to {f}\n store {f} %r,ptr %output,align 1\n ret void\n}}\n", .{ from, if (widen) "fpext" else "fptrunc", from, to, to });
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
        var output = machine.MachineFunction.init("convert", .void);
        defer output.deinit(std.testing.allocator);
        const selected = try selector.tryLowerWithContext(std.testing.allocator, &output, module.functions.items[0], &context);
        if (selected == .unsupported) std.debug.print("extended80 floating cast {f}->{f}: {s}\n", .{ from, to, selected.unsupported.detail() });
        try std.testing.expectEqual(selector.SelectionResult.selected, selected);
        try verify.verifyFunction(output);
    };
}

test "extended80 incoming mixed SSE layout keeps independent physical cursors" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\target datalayout = "e-i128:128-f80:128"
        \\define i128 @mixed(double %sse, x86_fp80 %payload, i64 %mask) {
        \\entry:
        \\ %bits = bitcast x86_fp80 %payload to i80
        \\ %wide = zext i80 %bits to i128
        \\ %m = zext i64 %mask to i128
        \\ %scalar = bitcast double %sse to i64
        \\ %sw = zext i64 %scalar to i128
        \\ %first = xor i128 %wide,%m
        \\ %answer = xor i128 %first,%sw
        \\ ret i128 %answer
        \\}
    );
    defer module.deinit();
    try module.verify();
    const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    var output = machine.MachineFunction.init("mixed", .{ .int = 128 });
    defer output.deinit(std.testing.allocator);
    const result = try selector.tryLowerWithContext(std.testing.allocator, &output, module.functions.items[0], &context);
    if (result == .unsupported) std.debug.print("extended80 mixed incoming: {s}\n", .{result.unsupported.detail()});
    try std.testing.expectEqual(selector.SelectionResult.selected, result);
    try verify.verifyFunction(output);
    const bytes = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(bytes);
    const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(code);
    @memcpy(code[0..bytes.len], bytes);
    const run: *const fn (f64, f80, u64) callconv(.c) u128 = @ptrCast(code.ptr);
    const payloads = [_]u80{ 0, 1, @as(u80, 1) << 79, 0x3fff8000000000000000, 0x7fff8000000000000001, 0xffffc000000000000123 };
    for (payloads) |payload| for ([_]u64{ 0, 1, 0x8000000000000000, 0x7ff0000000000001, 0xffffffffffffffff }) |scalar| {
        const mask_value: u64 = 0x9e3779b97f4a7c15;
        try std.testing.expectEqual(@as(u128, payload) ^ mask_value ^ scalar, run(@bitCast(scalar), @bitCast(payload), mask_value));
    };
}

test "extended80 integer helpers do not outline their own canonical symbols" {
    for ([_][]const u8{
        "define x86_fp80 @__floattixf(i128 %x) {\nentry:\n %r = sitofp i128 %x to x86_fp80\n ret x86_fp80 %r\n}\n",
        "define x86_fp80 @\"\\5F\\5Ffloatuntixf\"(i128 %x) {\nentry:\n %r = uitofp i128 %x to x86_fp80\n ret x86_fp80 %r\n}\n",
        "define i128 @__fixxfti(x86_fp80 %x) {\nentry:\n %r = fptosi x86_fp80 %x to i128\n ret i128 %r\n}\n",
        "define i128 @\"\\5F\\5Ffixunsxfti\"(x86_fp80 %x) {\nentry:\n %r = fptoui x86_fp80 %x to i128\n ret i128 %r\n}\n",
    }) |source| {
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try @import("binary128_arithmetic.zig").legalize(arena.allocator(), module.functions.items[0])) == null);
    }
}

test "extended80 integer casts use standard runtime helpers and preserve original forms" {
    const widths = [_]u16{ 1, 8, 16, 32, 52, 64, 65, 80, 127, 128 };
    for (widths) |width| for ([_]bool{ false, true }) |signed| for ([_]bool{ false, true }) |to_float| {
        const symbol = if (to_float) (if (signed) "__floattixf" else "__floatuntixf") else (if (signed) "__fixxfti" else "__fixunsxfti");
        const narrow = if (width == 128) try std.testing.allocator.dupe(u8, "add i128 %raw, 0") else if (width < 64)
            try std.fmt.allocPrint(std.testing.allocator, "trunc i64 %word to i{d}", .{width})
        else
            try std.fmt.allocPrint(std.testing.allocator, "trunc i128 %raw to i{d}", .{width});
        defer std.testing.allocator.free(narrow);
        const widen = if (width == 128) try std.testing.allocator.dupe(u8, "add i128 %r, 0") else try std.fmt.allocPrint(std.testing.allocator, "{s} i{d} %r to i128", .{ if (signed) "sext" else "zext", width });
        defer std.testing.allocator.free(widen);
        const source = if (to_float) try std.fmt.allocPrint(std.testing.allocator, "target datalayout = \"e-i128:128-f80:128\"\ndefine void @convert(i128 %raw, ptr %out) {{\nentry:\n %word = trunc i128 %raw to i64\n %narrow = {s}\n %r = {s} i{d} %narrow to x86_fp80\n store x86_fp80 %r, ptr %out, align 1\n ret void\n}}\n", .{ narrow, if (signed) "sitofp" else "uitofp", width }) else try std.fmt.allocPrint(std.testing.allocator, "target datalayout = \"e-i128:128-f80:128\"\ndefine i128 @convert(ptr %input) {{\nentry:\n %x = load x86_fp80, ptr %input, align 1\n %r = {s} x86_fp80 %x to i{d}\n %wide = {s}\n ret i128 %wide\n}}\n", .{ if (signed) "fptosi" else "fptoui", width, widen });
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
        var output = machine.MachineFunction.init("convert", if (to_float) .void else .{ .int = 128 });
        defer output.deinit(std.testing.allocator);
        const selected = try selector.tryLowerWithContext(std.testing.allocator, &output, module.functions.items[0], &context);
        if (selected == .unsupported) std.debug.print("extended80 integer cast width={d} signed={} to_float={}: {s}\n", .{ width, signed, to_float, selected.unsupported.detail() });
        try std.testing.expectEqual(selector.SelectionResult.selected, selected);
        try verify.verifyFunction(output);
        var calls: usize = 0;
        for (output.instructions.items) |inst| if (inst == .direct_call) {
            try std.testing.expectEqualStrings(symbol, inst.direct_call.symbol);
            try std.testing.expectEqual(if (to_float) ir.Type.x86_fp80 else ir.Type{ .int = 128 }, inst.direct_call.ret_ty);
            calls += 1;
        };
        try std.testing.expectEqual(@as(usize, 1), calls);
        var original_cast = false;
        for (module.functions.items[0].blocks.items[0].instructions.items) |inst| if (inst.kind == .cast) {
            if (inst.kind.cast.op == (if (to_float) (if (signed) ir.CastOp.sitofp else .uitofp) else (if (signed) ir.CastOp.fptosi else .fptoui))) original_cast = true;
        };
        try std.testing.expect(original_cast);
    };
}

test "extended80 direct calls retain memory arguments and capture every ST0 result" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\target datalayout = "e-i128:128-f80:128"
        \\declare x86_fp80 @callee(x86_fp80, i64, x86_fp80)
        \\define i128 @caller(ptr %input, i64 %mask) {
        \\entry:
        \\ %loaded = load x86_fp80, ptr %input, align 1
        \\ %r = call x86_fp80 @callee(x86_fp80 %loaded, i64 %mask, x86_fp80 0xK7FFF8000000000000001)
        \\ %ignored = call x86_fp80 @callee(x86_fp80 %loaded, i64 %mask, x86_fp80 0xK00000000000000000000)
        \\ %bits = bitcast x86_fp80 %r to i80
        \\ %wide = zext i80 %bits to i128
        \\ %mw = zext i64 %mask to i128
        \\ %answer = xor i128 %wide, %mw
        \\ ret i128 %answer
        \\}
    );
    defer module.deinit();
    try module.verify();
    const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    const source = module.functions.items[0];
    try std.testing.expect(!source.blocks.items[0].instructions.items[1].kind.call.abi_x87_return);
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const view = (try @import("extended80_payloads.zig").legalize(arena.allocator(), source, &context)).?;
    const call = view.blocks.items[0].instructions.items[1].kind.call;
    try std.testing.expect(call.abi_x87_return);
    try std.testing.expect(call.args.items[0].abi_x87_memory);
    try std.testing.expect(call.args.items[2].abi_x87_memory);
    try std.testing.expectEqual(@as(u16, 80), call.ret_ty.int);
    try std.testing.expect((try @import("extended80_payloads.zig").legalize(arena.allocator(), view, &context)) == null);
    var output = machine.MachineFunction.init("caller", .{ .int = 128 });
    defer output.deinit(std.testing.allocator);
    const selected = try selector.tryLowerWithContext(std.testing.allocator, &output, source, &context);
    if (selected == .unsupported) std.debug.print("extended80 call: {s}\n", .{selected.unsupported.detail()});
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try verify.verifyFunction(output);
    var calls: usize = 0;
    var captures: usize = 0;
    for (output.instructions.items) |inst| switch (inst) {
        .direct_call => |c| {
            try std.testing.expectEqual(ir.Type.x86_fp80, c.ret_ty);
            calls += 1;
        },
        .x87_st0_i80_rax_rdx => captures += 1,
        else => {},
    };
    try std.testing.expectEqual(@as(usize, 2), calls);
    try std.testing.expectEqual(calls, captures);
    try std.testing.expectEqual(ir.Type.x86_fp80, source.blocks.items[0].instructions.items[1].kind.call.ret_ty);
}

test "extended80 verifier rejects an integer register in place of ST0" {
    var output = machine.MachineFunction.init("missing_x87", .x86_fp80);
    defer output.deinit(std.testing.allocator);
    try output.instructions.appendSlice(std.testing.allocator, &.{ .{ .mov_imm_eax = 42 }, .ret });
    try std.testing.expectError(error.ReturnRegisterUndefined, verify.verifyFunction(output));
}

test "extended80 ABI transfer zero pads captures and verifies x87 paths" {
    const values = [_]u80{ 0, 1, @as(u80, 1) << 79, 0x3fff8000000000000000, 0x7fff8000000000000001, std.math.maxInt(u80) };
    for (values) |raw| {
        var output = machine.MachineFunction.init("capture", .{ .int = 128 });
        defer output.deinit(std.testing.allocator);
        try output.instructions.appendSlice(std.testing.allocator, &.{
            .{ .mov_imm_rax = @bitCast(@as(u64, @truncate(raw))) },
            .{ .mov_imm_rdx = @bitCast(@as(u64, @truncate((@as(u128, 0xfeedface1234) << 16) | (raw >> 64)))) },
            .i80_rax_rdx_st0,
            .x87_st0_i80_rax_rdx,
            .ret,
        });
        try verify.verifyFunction(output);
        const bytes = try encoding.encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(bytes);
        const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(code);
        @memcpy(code[0..bytes.len], bytes);
        const run: *const fn () callconv(.c) u128 = @ptrCast(code.ptr);
        try std.testing.expectEqual(@as(u128, raw), run());
    }
    var empty = machine.MachineFunction.init("underflow", .{ .int = 128 });
    defer empty.deinit(std.testing.allocator);
    try empty.instructions.appendSlice(std.testing.allocator, &.{ .x87_st0_i80_rax_rdx, .ret });
    try std.testing.expectError(error.X87StackUnderflow, verify.verifyFunction(empty));

    var joined = machine.MachineFunction.init("joined", .x86_fp80);
    defer joined.deinit(std.testing.allocator);
    try joined.instructions.appendSlice(std.testing.allocator, &.{
        .{ .test_arg32 = .rdi }, .{ .je = "right" },        .fneg_x86_fp80_stack8_st0, .{ .jmp = "join" },
        .{ .label = "right" },   .fneg_x86_fp80_stack8_st0, .{ .label = "join" },      .ret,
    });
    try verify.verifyFunction(joined);
    // An extra value on either incoming edge cannot be hidden by a join.
    try joined.instructions.insert(std.testing.allocator, 5, .fneg_x86_fp80_stack8_st0);
    const result = verify.verifyFunction(joined);
    try std.testing.expectError(error.X87StackMergeMismatch, result);
}

test "extended80 returns occupy ST0 and do not leak stack entries" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\target datalayout = "e-i128:128-f80:128"
        \\define x86_fp80 @identity(x86_fp80 %input) {
        \\entry:
        \\ ret x86_fp80 %input
        \\}
    );
    defer module.deinit();
    try module.verify();
    const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    var output = machine.MachineFunction.init("identity", .x86_fp80);
    defer output.deinit(std.testing.allocator);
    const selected = try selector.tryLowerWithContext(std.testing.allocator, &output, module.functions.items[0], &context);
    if (selected == .unsupported) std.debug.print("extended80 return: {s}\n", .{selected.unsupported.detail()});
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try verify.verifyFunction(output);
    const bytes = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(bytes);
    const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(code);
    @memcpy(code[0..bytes.len], bytes);
    const run: *const fn (f80) callconv(.c) f80 = @ptrCast(code.ptr);
    const values = [_]u80{ 0, 1, @as(u80, 1) << 79, 0x3fff8000000000000000, 0x7fff8000000000000000, 0x7fff8000000000000001, 0xffffc000000000000123 };
    for (0..4096) |index| {
        const raw = values[index % values.len];
        try std.testing.expectEqual(raw, @as(u80, @bitCast(run(@bitCast(raw)))));
    }
}

test "extended80 incoming values use aligned memory independently of integer registers" {
    const source =
        \\target datalayout = "e-i128:128-f80:128"
        \\define i128 @incoming(i64 %a, x86_fp80 %x, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, x86_fp80 %y, ptr %output) {
        \\entry:
        \\ store x86_fp80 %x, ptr %output, align 1
        \\ %next = getelementptr i8, ptr %output, i64 10
        \\ store x86_fp80 %y, ptr %next, align 1
        \\ %xb = bitcast x86_fp80 %x to i80
        \\ %yb = bitcast x86_fp80 %y to i80
        \\ %xw = zext i80 %xb to i128
        \\ %yw = zext i80 %yb to i128
        \\ %one = xor i64 %a, %b
        \\ %two = add i64 %one, %c
        \\ %three = xor i64 %two, %d
        \\ %four = add i64 %three, %e
        \\ %five = xor i64 %four, %f
        \\ %six = add i64 %five, %g
        \\ %mask = zext i64 %six to i128
        \\ %xy = xor i128 %xw, %yw
        \\ %answer = xor i128 %xy, %mask
        \\ ret i128 %answer
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    var output = machine.MachineFunction.init("incoming", .{ .int = 128 });
    defer output.deinit(std.testing.allocator);
    const selected = try selector.tryLowerWithContext(std.testing.allocator, &output, module.functions.items[0], &context);
    if (selected == .unsupported) std.debug.print("extended80 incoming: {s}\n", .{selected.unsupported.detail()});
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try verify.verifyFunction(output);
    const bytes = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(bytes);
    const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(code);
    @memcpy(code[0..bytes.len], bytes);
    const run: *const fn (u64, f80, u64, u64, u64, u64, u64, u64, f80, *u8) callconv(.c) u128 = @ptrCast(code.ptr);
    const cases = [_]u80{ 0, 1, @as(u80, 1) << 79, 0x3fff8000000000000000, 0x7fff8000000000000000, 0x7fff8000000000000001, 0xffffc000000000000123 };
    for (cases, 0..) |x, index| for (cases) |y| {
        const a: u64 = index;
        const b: u64 = 0x123456789abcdef0;
        const c: u64 = ~a;
        const d: u64 = 0x9e3779b97f4a7c15;
        const e: u64 = 0xaabbccddeeff0011;
        const f: u64 = 0x1122334455667788;
        const g: u64 = ~b;
        const mixed = ((((((a ^ b) +% c) ^ d) +% e) ^ f) +% g);
        var stored: [22]u8 = @splat(0xa7);
        try std.testing.expectEqual(@as(u128, x) ^ @as(u128, y) ^ mixed, run(a, @bitCast(x), b, c, d, e, f, g, @bitCast(y), &stored[1]));
        try std.testing.expectEqual(x, std.mem.readInt(u80, stored[1..11], .little));
        try std.testing.expectEqual(y, std.mem.readInt(u80, stored[11..21], .little));
        try std.testing.expectEqual(@as(u8, 0xa7), stored[0]);
        try std.testing.expectEqual(@as(u8, 0xa7), stored[21]);
    };
}

test "extended80 payload transport preserves all bits and exact ten-byte access extents" {
    for ([_]bool{ false, true }) |owned| {
        const source = try std.fmt.allocPrint(std.testing.allocator,
            \\target datalayout = "e-i128:128-f80:128"
            \\define i128 @transport(ptr %input, ptr %output, i128 %mask) {{
            \\entry:
            \\ %source = load x86_fp80, ptr %input, align 1
            \\{s}
            \\ %stable = freeze x86_fp80 {s}
            \\ store x86_fp80 %stable, ptr %output, align 1
            \\ %bits = bitcast x86_fp80 %stable to i80
            \\ %wide = zext i80 %bits to i128
            \\ %answer = xor i128 %wide, %mask
            \\ ret i128 %answer
            \\}}
            \\
        , .{ if (owned) " %slot = alloca x86_fp80, align 16\n store x86_fp80 %source, ptr %slot, align 16\n %loaded = load x86_fp80, ptr %slot, align 16" else "", if (owned) "%loaded" else "%source" });
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
        var output = machine.MachineFunction.init("transport", .{ .int = 128 });
        defer output.deinit(std.testing.allocator);
        const selected = try selector.tryLowerWithContext(std.testing.allocator, &output, module.functions.items[0], &context);
        if (selected == .unsupported) std.debug.print("extended80 payload: {s}\n", .{selected.unsupported.detail()});
        try std.testing.expectEqual(selector.SelectionResult.selected, selected);
        try std.testing.expectEqual(ir.Type.x86_fp80, module.functions.items[0].blocks.items[0].instructions.items[0].kind.load.ty);
        try verify.verifyFunction(output);
        for (output.instructions.items) |instruction| try std.testing.expect(instruction != .direct_call);
        const bytes = try encoding.encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(bytes);
        const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(code);
        @memcpy(code[0..bytes.len], bytes);
        const run: *const fn (*const u8, *u8, u128) callconv(.c) u128 = @ptrCast(code.ptr);
        const payloads = [_]u80{ 0, 1, @as(u80, 1) << 79, 0x3fff8000000000000000, 0x7fff8000000000000000, 0x7fffc000000000000123, 0x7fff8000000000000001, 0xfeedface0123456789ab, std.math.maxInt(u80) };
        for (payloads) |payload| for ([_]u128{ 0, 1, std.math.maxInt(u128), 0x123456789abcdef098765432fedcba09 }) |mask| {
            var input: [12]u8 = @splat(0xa7);
            var result: [12]u8 = @splat(0x5b);
            std.mem.writeInt(u80, input[1..11], payload, .little);
            const before = input;
            try std.testing.expectEqual(@as(u128, payload) ^ mask, run(&input[1], &result[1], mask));
            try std.testing.expectEqual(payload, std.mem.readInt(u80, result[1..11], .little));
            try std.testing.expectEqual(@as(u8, 0x5b), result[0]);
            try std.testing.expectEqual(@as(u8, 0x5b), result[11]);
            try std.testing.expectEqualSlices(u8, &before, &input);
        };
    }
}

test "extended80 payload views preserve sources and reject unsupported effects and call envelopes" {
    const payloads = @import("extended80_payloads.zig");
    const context: machine.ReadOnlyModuleContext = .{ .globals = &.{}, .named_types = &.{}, .target_datalayout = "e-i128:128-f80:128" };
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i128 @view(ptr %input, ptr %output, i32 %choice) {
        \\entry:
        \\ %loaded = load x86_fp80, ptr %input, align 1
        \\ %condition = icmp ne i32 %choice, 0
        \\ %chosen = select i1 %condition, x86_fp80 %loaded, x86_fp80 0xK7FFF8000000000000001
        \\ br i1 %condition, label %left, label %right
        \\left:
        \\ br label %join
        \\right:
        \\ br label %join
        \\join:
        \\ %merged = phi x86_fp80 [ %chosen, %left ], [ 0xKFFFFC000000000000123, %right ]
        \\ %stable = freeze x86_fp80 %merged
        \\ store x86_fp80 %stable, ptr %output, align 1
        \\ %bits = bitcast x86_fp80 %stable to i80
        \\ %result = zext i80 %bits to i128
        \\ ret i128 %result
        \\}
    );
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const source = module.functions.items[0];
    const view = (try payloads.legalize(arena.allocator(), source, &context)).?;
    var private = module;
    private.functions = try module.functions.clone(arena.allocator());
    private.functions.items[0] = view;
    try private.verify();
    try std.testing.expect((try payloads.legalize(arena.allocator(), view, &context)) == null);
    try std.testing.expectEqual(ir.Type.x86_fp80, source.blocks.items[0].instructions.items[0].kind.load.ty);
    try std.testing.expectEqual(ir.Type.x86_fp80, source.blocks.items[0].instructions.items[2].kind.select.ty);
    try std.testing.expectEqual(ir.Type.x86_fp80, source.blocks.items[3].instructions.items[0].kind.phi.ty);
    for ([_][]const u8{
        "define void @boundary(ptr %p) {\nentry:\n %x = load volatile x86_fp80, ptr %p\n store x86_fp80 %x, ptr %p\n ret void\n}\n",
        "define void @boundary(ptr %p) {\nentry:\n %x = load x86_fp80, ptr %p\n %r = fadd x86_fp80 %x, %x\n store x86_fp80 %r, ptr %p\n ret void\n}\n",
        "define void @boundary(ptr %p, ptr %callee) {\nentry:\n %x = load x86_fp80, ptr %p\n %r = call x86_fp80 %callee(x86_fp80 %x)\n store x86_fp80 %r, ptr %p\n ret void\n}\n",
        "declare x86_fp80 @callee(x86_fp80)\ndefine x86_fp80 @boundary(x86_fp80 %x) {\nentry:\n %r = musttail call x86_fp80 @callee(x86_fp80 %x)\n ret x86_fp80 %r\n}\n",
    }) |text| {
        var closed = try ir.Module.parse(std.testing.allocator, text);
        defer closed.deinit();
        try closed.verify();
        try std.testing.expect((try payloads.legalize(arena.allocator(), closed.functions.items[0], &context)) == null);
    }
    for ([_][]const u8{ "e-i128:256-f80:128", "e-i128:128-f80:64" }) |layout| {
        var incompatible = context;
        incompatible.target_datalayout = layout;
        try std.testing.expect((try payloads.legalize(arena.allocator(), source, &incompatible)) == null);
    }
}
