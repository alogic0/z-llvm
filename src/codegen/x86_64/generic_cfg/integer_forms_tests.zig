const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("integer_forms.zig");
const narrow = @import("narrow_abi.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");

test "integer forms bridge pair truncation to i52 with clean word bits" {
    for ([_]bool{ false, true }) |literal| {
        const fixed: u128 = 0xfedcba98765432100123456789abcdef;
        const operand = if (literal) try std.fmt.allocPrint(std.testing.allocator, "{d}", .{@as(i128, @bitCast(fixed))}) else try std.testing.allocator.dupe(u8, "%input");
        defer std.testing.allocator.free(operand);
        const source = try std.fmt.allocPrint(std.testing.allocator, "define i64 @bridge(i128 %input,i64 %seed) {{\nentry:\n %small = trunc i128 {s} to i52\n %wide = zext i52 %small to i64\n %answer = xor i64 %wide,%seed\n ret i64 %answer\n}}\n", .{operand});
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        var output = machine.MachineFunction.init("bridge", .{ .int = 64 });
        defer output.deinit(std.testing.allocator);
        const result = try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]);
        if (result == .unsupported) std.debug.print("pair to i52: {s}\n", .{result.unsupported.detail()});
        try std.testing.expectEqual(selector.SelectionResult.selected, result);
        try verify.verifyFunction(output);
        const bytes = try encoding.encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(bytes);
        const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(code);
        @memcpy(code[0..bytes.len], bytes);
        const run: *const fn (u128, u64) callconv(.c) u64 = @ptrCast(code.ptr);
        for ([_]u128{ 0, 1, 0xfffffffffffff, 0x10000000000000, fixed, std.math.maxInt(u128) }) |raw| {
            const seed: u64 = @truncate(raw >> 51);
            const expected: u64 = @as(u64, @truncate(if (literal) fixed else raw)) & 0xfffffffffffff;
            try std.testing.expectEqual(expected ^ seed, run(raw, seed));
        }
    }
}

test "integer forms zero-extended returns publish clean native carriers" {
    for ([_]u16{ 1, 7, 8, 16, 23, 31 }) |bits| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\define zeroext i{d} @run(i64 %input, i64 %seed) {{
            \\entry:
            \\ %mixed = xor i64 %input, %seed
            \\ %small = trunc i64 %mixed to i{d}
            \\ ret i{d} %small
            \\}}
        , .{ bits, bits, bits });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var lowered = machine.MachineFunction.init("run", .{ .int = bits });
        defer lowered.deinit(std.testing.allocator);
        const selected = try selector.tryLower(std.testing.allocator, &lowered, module.functions.items[0]);
        if (selected == .unsupported) std.debug.print("zero-extended return i{d}: {s}\n", .{ bits, selected.unsupported.detail() });
        try std.testing.expectEqual(selector.SelectionResult.selected, selected);
        try verify.verifyFunction(lowered);
        const bytes = try encoding.encodeFunction(std.testing.allocator, lowered);
        defer std.testing.allocator.free(bytes);
        const executable = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(executable);
        @memcpy(executable[0..bytes.len], bytes);
        const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(executable.ptr);
        const mask = (@as(u64, 1) << @as(u6, @intCast(bits))) - 1;
        const values = [_]u64{ 0, 1, 127, 128, 255, 65535, 0x0123456789abcdef, std.math.maxInt(u64) };
        for (values) |input| for (values) |seed| try std.testing.expectEqual((input ^ seed) & mask, run(input, seed));
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const original = module.functions.items[0];
        const view = (try narrow.legalize(arena.allocator(), original)) orelse return error.TestExpectedRewrite;
        try std.testing.expectEqualStrings("zeroext", original.ret_attrs.?);
        try std.testing.expect(original.ret_ty.eql(.{ .int = bits }));
        try std.testing.expect(view.ret_ty.eql(.{ .int = 32 }) and view.ret_attrs == null);
        try std.testing.expect(try narrow.legalize(arena.allocator(), view) == null);
        try module.verify();
    }
}

test "integer forms execute constant-left shifts with live count aliases" {
    for ([_]u16{ 32, 64 }) |bits| for ([_][]const u8{ "shl", "lshr", "ashr" }) |operation| {
        const top: u64 = @as(u64, 1) << @as(u6, @intCast(bits - 1));
        const mask: u64 = if (bits == 64) std.math.maxInt(u64) else std.math.maxInt(u32);
        for ([_]bool{ false, true }) |unsigned_spelling| for ([_]bool{ false, true }) |spill_count| {
            const text = try std.fmt.allocPrint(std.testing.allocator,
                \\define i64 @run(i64 %count, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g) {{
                \\entry:
                \\ %masked = and i64 %count, {d}
                \\ {s}
                \\ {s}
                \\ %shifted = {s} i{d} {d}, {s}
                \\ {s}
                \\ {s}
                \\ %one = xor i64 %wide, %marker
                \\ %two = add i64 %one, %c
                \\ %three = xor i64 %two, %d
                \\ %four = sub i64 %three, %e
                \\ %five = xor i64 %four, %f
                \\ %result = add i64 %five, %g
                \\ ret i64 %result
                \\}}
            , .{
                bits - 1,
                if (bits == 32) "%narrow_count = trunc i64 %masked to i32" else "",
                if (spill_count) "%marker = xor i64 %a, %b" else "",
                operation,
                bits,
                if (unsigned_spelling) @as(i128, top) else -@as(i128, top),
                if (bits == 32) "%narrow_count" else "%masked",
                if (bits == 32) "%wide = zext i32 %shifted to i64" else "%wide = xor i64 %shifted, 0",
                if (spill_count) "" else "%marker = xor i64 %a, %b",
            });
            defer std.testing.allocator.free(text);
            var module = try ir.Module.parse(std.testing.allocator, text);
            defer module.deinit();
            try module.verify();
            var lowered = machine.MachineFunction.init("run", .{ .int = 64 });
            defer lowered.deinit(std.testing.allocator);
            const selected = try selector.tryLower(std.testing.allocator, &lowered, module.functions.items[0]);
            if (selected == .unsupported) std.debug.print("literal-left {s} i{d} spill={} unsigned={}: {s}\n", .{ operation, bits, spill_count, unsigned_spelling, selected.unsupported.detail() });
            try std.testing.expectEqual(selector.SelectionResult.selected, selected);
            try verify.verifyFunction(lowered);
            const bytes = try encoding.encodeFunction(std.testing.allocator, lowered);
            defer std.testing.allocator.free(bytes);
            const executable = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
            defer std.posix.munmap(executable);
            @memcpy(executable[0..bytes.len], bytes);
            const run: *const fn (u64, u64, u64, u64, u64, u64, u64, u64) callconv(.c) u64 = @ptrCast(executable.ptr);
            for (0..bits) |amount| for ([_]u64{ 0, 0x0123456789abcdef, std.math.maxInt(u64) }) |seed| {
                const count: u6 = @intCast(amount);
                const shifted: u64 = if (std.mem.eql(u8, operation, "shl")) (top << count) & mask else if (std.mem.eql(u8, operation, "lshr")) top >> count else if (bits == 64) @bitCast(@as(i64, @bitCast(top)) >> count) else @as(u32, @bitCast(@as(i32, @bitCast(@as(u32, @truncate(top)))) >> @as(u5, @intCast(amount))));
                const a = seed;
                const b = seed ^ 0xa55a55aa12345678;
                const c = seed +% amount;
                const d = ~seed;
                const e = seed *% 17;
                const f = seed ^ amount;
                const g = seed -% amount;
                const expected = (((((shifted ^ (a ^ b)) +% c) ^ d) -% e) ^ f) +% g;
                try std.testing.expectEqual(expected, run(amount | 0xfedcba9876543200, a, b, c, d, e, f, g));
            };
        };
    };
}

test "integer forms literal-shift views preserve flags identities and fixed points" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i64 @shift(i64 %__zllvm_scalar_form_0) {
        \\entry:
        \\ %answer = ashr exact i64 -9223372036854775808, %__zllvm_scalar_form_0
        \\ ret i64 %answer
        \\}
    );
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const original = module.functions.items[0];
    try std.testing.expect(!forms.requiresNormalization(original));
    const view = (try forms.legalize(arena.allocator(), original)) orelse return error.TestExpectedRewrite;
    try std.testing.expect(try forms.legalize(arena.allocator(), view) == null);
    try std.testing.expectEqual(@as(usize, 1), original.blocks.items[0].instructions.items.len);
    try std.testing.expect(original.blocks.items[0].instructions.items[0].kind.binary.lhs == .int);
    const retained = view.blocks.items[0].instructions.items[1];
    try std.testing.expectEqualStrings("answer", retained.result.?);
    try std.testing.expect(retained.kind.binary.op == .ashr and retained.kind.binary.flags.exact);
    try std.testing.expectEqualStrings("__zllvm_scalar_form_0", retained.kind.binary.rhs.named);
    module.functions.items[0] = view;
    defer module.functions.items[0] = original;
    try module.verify();
}

test "pair shifts execute constant projections from zero extensions" {
    for ([_]u8{ 40, 1, 7, 31, 32, 48, 56, 63, 64, 65, 96, 127 }) |amount| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\define i64 @run(i64 %input, i64 %live) {{
            \\entry:
            \\ %pair = zext i64 %input to i128
            \\ %shifted = lshr i128 %pair, {d}
            \\ %byte = trunc i128 %shifted to i8
            \\ %wide = zext i8 %byte to i64
            \\ %one = xor i64 %wide, %input
            \\ %result = xor i64 %one, %live
            \\ ret i64 %result
            \\}}
        , .{amount});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var lowered = machine.MachineFunction.init("run", .{ .int = 64 });
        defer lowered.deinit(std.testing.allocator);
        const selected = try selector.tryLower(std.testing.allocator, &lowered, module.functions.items[0]);
        if (selected == .unsupported) std.debug.print("pair projection {d}: {s}\n", .{ amount, selected.unsupported.detail() });
        try std.testing.expectEqual(selector.SelectionResult.selected, selected);
        try verify.verifyFunction(lowered);
        const bytes = try encoding.encodeFunction(std.testing.allocator, lowered);
        defer std.testing.allocator.free(bytes);
        const executable = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(executable);
        @memcpy(executable[0..bytes.len], bytes);
        const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(executable.ptr);
        for ([_]u64{ 0, 1, 0x0123456789abcdef, 0x8000000000000000, std.math.maxInt(u64) }) |input| for ([_]u64{ 0, 0xa55a55aa12345678, std.math.maxInt(u64) }) |live| {
            const projected: u64 = @intCast((@as(u128, input) >> @as(u7, @intCast(amount))) & 255);
            try std.testing.expectEqual(projected ^ input ^ live, run(input, live));
        };
    }
}

test "pair shifts serialize widened words with live vector projections" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
        \\define void @run(ptr %output, i64 %input, i64 %live, i64 %length) {
        \\entry:
        \\ %copy_source = alloca i64, align 8
        \\ store i64 %input, ptr %copy_source, align 8
        \\ call void @llvm.memcpy.p0.p0.i64(ptr %output, ptr %copy_source, i64 %length, i1 false)
        \\ br label %serialize
        \\serialize:
        \\ %first_word = add i64 %input, %live
        \\ %first = zext i64 %first_word to i128
        \\ %second_word = xor i64 %input, %live
        \\ %second = zext i64 %second_word to i128
        \\ %a = lshr i128 %first, 40
        \\ %b = lshr i128 %first, 48
        \\ %c = lshr i128 %first, 56
        \\ %a8 = trunc i128 %a to i8
        \\ %b8 = trunc i128 %b to i8
        \\ %c8 = trunc i128 %c to i8
        \\ %low = trunc i64 %first_word to i8
        \\ %insert = insertelement <4 x i128> poison, i128 %first, i64 0
        \\ %splat = shufflevector <4 x i128> %insert, <4 x i128> poison, <4 x i32> zeroinitializer
        \\ %shifted = lshr <4 x i128> %splat, <i128 8, i128 16, i128 24, i128 32>
        \\ %bytes = trunc <4 x i128> %shifted to <4 x i8>
        \\ store i8 %low, ptr %output, align 1
        \\ %p1 = getelementptr i8, ptr %output, i64 1
        \\ store <4 x i8> %bytes, ptr %p1, align 1
        \\ %p5 = getelementptr i8, ptr %output, i64 5
        \\ store i8 %a8, ptr %p5, align 1
        \\ %p6 = getelementptr i8, ptr %output, i64 6
        \\ store i8 %b8, ptr %p6, align 1
        \\ %p7 = getelementptr i8, ptr %output, i64 7
        \\ store i8 %c8, ptr %p7, align 1
        \\ %d = lshr i128 %second, 40
        \\ %e = lshr i128 %second, 48
        \\ %f = lshr i128 %second, 56
        \\ %d8 = trunc i128 %d to i8
        \\ %e8 = trunc i128 %e to i8
        \\ %f8 = trunc i128 %f to i8
        \\ %second_low = trunc i64 %second_word to i8
        \\ %insert2 = insertelement <4 x i128> poison, i128 %second, i64 0
        \\ %splat2 = shufflevector <4 x i128> %insert2, <4 x i128> poison, <4 x i32> zeroinitializer
        \\ %shifted2 = lshr <4 x i128> %splat2, <i128 8, i128 16, i128 24, i128 32>
        \\ %bytes2 = trunc <4 x i128> %shifted2 to <4 x i8>
        \\ %p8 = getelementptr i8, ptr %output, i64 8
        \\ store i8 %second_low, ptr %p8, align 1
        \\ %p9 = getelementptr i8, ptr %output, i64 9
        \\ store <4 x i8> %bytes2, ptr %p9, align 1
        \\ %p13 = getelementptr i8, ptr %output, i64 13
        \\ store i8 %d8, ptr %p13, align 1
        \\ %p14 = getelementptr i8, ptr %output, i64 14
        \\ store i8 %e8, ptr %p14, align 1
        \\ %p15 = getelementptr i8, ptr %output, i64 15
        \\ store i8 %f8, ptr %p15, align 1
        \\ ret void
        \\}
    );
    defer module.deinit();
    try module.verify();
    var lowered = machine.MachineFunction.init("run", .void);
    defer lowered.deinit(std.testing.allocator);
    const selected = try selector.tryLower(std.testing.allocator, &lowered, module.functions.items[0]);
    if (selected == .unsupported) std.debug.print("pair/vector serialization: {s}\n", .{selected.unsupported.detail()});
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try verify.verifyFunction(lowered);
    const bytes = try encoding.encodeFunction(std.testing.allocator, lowered);
    defer std.testing.allocator.free(bytes);
    const executable = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(executable);
    @memcpy(executable[0..bytes.len], bytes);
    const run: *const fn ([*]u8, u64, u64, u64) callconv(.c) void = @ptrCast(executable.ptr);
    const values = [_]u64{ 0, 1, 0x0123456789abcdef, 0x8000000000000000, std.math.maxInt(u64) };
    for (values) |input| for (values) |live| for ([_]u64{ 0, 1, 7, 8 }) |length| {
        var output: [32]u8 = @splat(0xa5);
        var expected = output;
        for (0..8) |index| {
            const shift: u6 = @intCast(index * 8);
            expected[8 + index] = @truncate((input +% live) >> shift);
            expected[16 + index] = @truncate((input ^ live) >> shift);
        }
        run(output[8..].ptr, input, live, length);
        try std.testing.expectEqualSlices(u8, &expected, &output);
    };
}

test "integer forms execute odd-width zero extension with dirty upper bits and live aliases" {
    for ([_][2]u16{ .{ 8, 33 }, .{ 32, 39 }, .{ 33, 39 }, .{ 39, 51 }, .{ 51, 52 }, .{ 52, 63 } }) |widths| {
        const source = try std.fmt.allocPrint(std.testing.allocator,
            \\define i64 @extend(i64 %input, i64 %live) {{
            \\entry:
            \\ %narrow = trunc i64 %input to i{d}
            \\ %middle = zext i{d} %narrow to i{d}
            \\ %wide = zext i{d} %middle to i64
            \\ %mixed = xor i64 %wide, %input
            \\ %result = xor i64 %mixed, %live
            \\ ret i64 %result
            \\}}
        , .{ widths[0], widths[0], widths[1], widths[1] });
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        var output = machine.MachineFunction.init("extend", .{ .int = 64 });
        defer output.deinit(std.testing.allocator);
        const selected = try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]);
        if (selected == .unsupported) std.debug.print("zero extension {d}->{d}: {s}\n", .{ widths[0], widths[1], selected.unsupported.detail() });
        try std.testing.expectEqual(selector.SelectionResult.selected, selected);
        try verify.verifyFunction(output);
        const code = try encoding.encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(code);
        const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..code.len], code);
        const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(memory.ptr);
        const values = [_]u64{ 0, 1, 255, 0x7fffffff, 0xffffffff, 1 << 39, 1 << 51, 1 << 52, 0xdeadbeef12345678, std.math.maxInt(u64) };
        const mask = (@as(u64, 1) << @as(u6, @intCast(widths[0]))) - 1;
        for (values) |input| for (values) |live| try std.testing.expectEqual((input & mask) ^ input ^ live, run(input, live));
    }
}

test "integer forms private expansion preserves source widths and reaches a fixed point" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i31 @narrow(i31 %a, i31 %b) {
        \\entry:
        \\  %sum = add nuw i31 %a, %b
        \\  %signed = sext i31 %sum to i64
        \\  %quotient = sdiv i64 %signed, 3
        \\  %answer = trunc i64 %quotient to i31
        \\  ret i31 %answer
        \\}
    );
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const original = module.functions.items[0];
    const expanded = (try forms.legalize(arena.allocator(), original)).?;
    try std.testing.expectEqual(@as(usize, 4), original.blocks.items[0].instructions.items.len);
    try std.testing.expect(original.blocks.items[0].instructions.items[0].kind.binary.flags.nuw);
    try std.testing.expectEqual(original.ret_ty, expanded.ret_ty);
    try std.testing.expectEqual(original.params.items.ptr, expanded.params.items.ptr);
    try std.testing.expect((try forms.legalize(arena.allocator(), expanded)) == null);
    var retained_sum = false;
    for (expanded.blocks.items[0].instructions.items) |inst| {
        if (inst.result) |name| if (std.mem.eql(u8, name, "sum")) {
            try std.testing.expect(inst.kind == .cast and inst.kind.cast.op == .trunc and inst.kind.cast.to_ty.eql(.{ .int = 31 }));
            retained_sum = true;
        };
        if (inst.kind == .binary) {
            try std.testing.expect(inst.kind.binary.ty.eql(.{ .int = 32 }) or inst.kind.binary.ty.eql(.{ .int = 64 }));
            try std.testing.expect(!inst.kind.binary.flags.any());
            try std.testing.expect(inst.kind.binary.op != .sdiv and inst.kind.binary.op != .srem);
        }
    }
    try std.testing.expect(retained_sum);
}

test "integer forms leave vectors wide integers and unsupported operands at their boundary" {
    for ([_][]const u8{
        "define i65 @wide(i65 %a, i65 %b) {\nentry:\n %sum = add i65 %a, %b\n ret i65 %sum\n}\n",
        "define <2 x i8> @vector(<2 x i8> %a, <2 x i8> %b) {\nentry:\n %sum = add <2 x i8> %a, %b\n ret <2 x i8> %sum\n}\n",
        "define i8 @undefined(i8 %a) {\nentry:\n %sum = add i8 %a, undef\n ret i8 %sum\n}\n",
        "define i128 @extend(i64 %a) {\nentry:\n %sum = sext i64 %a to i128\n ret i128 %sum\n}\n",
    }) |text| {
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try forms.legalize(arena.allocator(), module.functions.items[0])) == null);
    }
}

test "integer forms narrow ABI carriers admit seventeen through thirty-one bits without extension attributes" {
    for ([_]u16{ 17, 18, 23, 24, 30, 31 }) |bits| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\declare i{d} @callee(i{d})
            \\define i{d} @caller(i{d} %value) {{
            \\entry:
            \\  %answer = call i{d} @callee(i{d} %value)
            \\  ret i{d} %answer
            \\}}
        , .{ bits, bits, bits, bits, bits, bits, bits });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const expanded = (try narrow.legalize(arena.allocator(), module.functions.items[0])).?;
        try std.testing.expect(expanded.ret_ty.eql(.{ .int = 32 }));
        try std.testing.expect(expanded.params.items[0].ty.eql(.{ .int = 32 }));
        for (expanded.blocks.items[0].instructions.items) |inst| if (inst.kind == .call) {
            try std.testing.expect(inst.kind.call.ret_ty.eql(.{ .int = 32 }));
            try std.testing.expect(inst.kind.call.args.items[0].ty.eql(.{ .int = 32 }));
        };
        var excluded = module.functions.items[0];
        excluded.ret_attrs = "signext";
        try std.testing.expect((try narrow.legalize(arena.allocator(), excluded)) == null);
    }
}

test "integer forms execute signed narrow arithmetic with live values and dirty input padding" {
    const cases = [_]struct { operation: []const u8, expected: enum { shift, quotient, extend, zero52, trunc52, trunc2 } }{
        .{ .operation = "%n = trunc i64 %input to i7\n  %v = ashr i7 %n, 3\n  %wide = zext i7 %v to i64", .expected = .shift },
        .{ .operation = "%n = trunc i64 %input to i7\n  %v = ashr i7 %n, 3\n  %gate = icmp eq i64 %input, 64\n  %wide = zext i7 %v to i64", .expected = .shift },
        .{ .operation = "%n = trunc i64 %input to i31\n  %v = sdiv i31 %n, 3\n  %wide = zext i31 %v to i64", .expected = .quotient },
        .{ .operation = "%n = trunc i64 %input to i8\n  %v = sext i8 %n to i31\n  %wide = zext i31 %v to i64", .expected = .extend },
        .{ .operation = "%n = trunc i64 %input to i52\n  %v = icmp eq i52 %n, 0\n  %wide = zext i1 %v to i64", .expected = .zero52 },
        .{ .operation = "%n = trunc i64 %input to i53\n  %v = trunc i53 %n to i52\n  %wide = zext i52 %v to i64", .expected = .trunc52 },
        .{ .operation = "%n = trunc i64 %input to i52\n  %v = trunc i52 %n to i2\n  %wide = zext i2 %v to i64", .expected = .trunc2 },
    };
    for (cases) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\define i64 @run(i64 %input, i64 %live) {{
            \\entry:
            \\  {s}
            \\  %answer = xor i64 %wide, %live
            \\  ret i64 %answer
            \\}}
        , .{case.operation});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var lowered = machine.MachineFunction.init("run", .{ .int = 64 });
        defer lowered.deinit(std.testing.allocator);
        try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLower(std.testing.allocator, &lowered, module.functions.items[0]));
        try std.testing.expect(lowered.selection_owner == .composed_block or lowered.selection_owner == .composed_cfg);
        try verify.verifyFunction(lowered);
        const bytes = try encoding.encodeFunction(std.testing.allocator, lowered);
        defer std.testing.allocator.free(bytes);
        const executable = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(executable);
        @memcpy(executable[0..bytes.len], bytes);
        const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(executable.ptr);
        const values = [_]u64{ 0, 1, 63, 64, 127, 128, 255, 0x3fffffff, 0x40000000, 0x7fffffff, 1 << 52, 0xdeadbeef12345678, std.math.maxInt(u64) };
        for (values) |input| for (values) |live| {
            const answer: i64 = switch (case.expected) {
                .shift => (@as(i64, @intCast((input & 127) ^ 64)) - 64) >> 3,
                .quotient => @divTrunc(@as(i64, @intCast((input & 0x7fffffff) ^ 0x40000000)) - 0x40000000, 3),
                .extend => @as(i64, @intCast((input & 255) ^ 128)) - 128,
                .zero52 => @intFromBool(input & ((@as(u64, 1) << 52) - 1) == 0),
                .trunc52 => @intCast(input & ((@as(u64, 1) << 52) - 1)),
                .trunc2 => @intCast(input & 3),
            };
            const expected = @as(u64, @bitCast(answer)) & switch (case.expected) {
                .shift => @as(u64, 127),
                .trunc52 => (@as(u64, 1) << 52) - 1,
                else => 0x7fffffff,
            };
            try std.testing.expectEqual(expected ^ live, run(input, live));
        };
    }
}
