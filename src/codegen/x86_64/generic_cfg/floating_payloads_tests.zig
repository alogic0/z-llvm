const std = @import("std");
const ir = @import("../../../ir.zig");
const payloads = @import("floating_payloads.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");

test "native floating literal returns preserve payloads branch effects and source IR" {
    inline for (.{ .{ "half", 16 }, .{ "float", 32 }, .{ "double", 64 } }) |shape| {
        const ty = shape[0];
        const bits = shape[1];
        const F = if (bits == 16) f16 else if (bits == 32) f32 else f64;
        const U = @Int(.unsigned, bits);
        const literals = if (bits == 16) [_][]const u8{ "0xH0000", "0xH8000", "0xH0001", "0xH7C00", "0xH7C01", "0xH7E23", "0xH3555" } else if (bits == 32) [_][]const u8{ "0.000000e+00", "-0.000000e+00", "0x36A0000000000000", "0x7FF0000000000000", "0x7FF0000020000000", "0x7FF8002460000000", "0x3FD5555560000000" } else [_][]const u8{ "0x0000000000000000", "0x8000000000000000", "0x0000000000000001", "0x7FF0000000000000", "0x7FF0000000000001", "0x7FF8000000000123", "0x3FD5555555555555" };
        const expected = if (bits == 16) [_]u64{ 0, 0x8000, 1, 0x7c00, 0x7c01, 0x7e23, 0x3555 } else if (bits == 32) [_]u64{ 0, 0x80000000, 1, 0x7f800000, 0x7f800001, 0x7fc00123, 0x3eaaaaab } else [_]u64{ 0, 0x8000000000000000, 1, 0x7ff0000000000000, 0x7ff0000000000001, 0x7ff8000000000123, 0x3fd5555555555555 };
        for (literals, expected) |literal, raw| for ([_]bool{ false, true }) |fast| {
            const text = try std.fmt.allocPrint(std.testing.allocator, "define {s}{s} @literal(i1 %choice,i64 %salt,ptr %out) {{\nentry:\n store volatile i64 %salt,ptr %out,align 1\n br i1 %choice,label %yes,label %no\nyes:\n ret {s} {s}\nno:\n ret {s} {s}\n}}\n", .{ if (fast) "fastcc " else "", ty, ty, literal, ty, literals[1] });
            defer std.testing.allocator.free(text);
            var module = try ir.Module.parse(std.testing.allocator, text);
            defer module.deinit();
            try module.verify();
            var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
            defer arena.deinit();
            const original = module.functions.items[0];
            const view = (try payloads.legalize(arena.allocator(), original, null)).?;
            var private = module;
            private.functions = try module.functions.clone(arena.allocator());
            private.functions.items[0] = view;
            try private.verify();
            try std.testing.expect((try payloads.legalize(arena.allocator(), view, null)) == null);
            try std.testing.expect(original.blocks.items[1].terminator.?.ret.value.? == .fp);
            const code = try executable(text);
            defer std.posix.munmap(code);
            const run: *const fn (bool, u64, *u64) callconv(.c) F = @ptrCast(code.ptr);
            for ([_]bool{ false, true }) |choice| for ([_]u64{ 0, 1, 0xf06dea67e461de5b, std.math.maxInt(u64) }) |salt| {
                var out: u64 = 0xa5a5a5a5a5a5a5a5;
                try std.testing.expectEqual(@as(U, @intCast(if (choice) raw else expected[1])), @as(U, @bitCast(run(choice, salt, &out))));
                try std.testing.expectEqual(salt, out);
            };
            try module.verify();
        };
    }
}

test "native floating literal returns reject malformed or nonrepresentable spellings" {
    for ([_][]const u8{ "half 0xH123", "float 0x3FF0000000000001", "float 0x7FF0000000000001", "double 0xFFFFFFFFFFFFFFFFF" }) |typed| {
        const space = std.mem.indexOfScalar(u8, typed, ' ').?;
        const text = try std.fmt.allocPrint(std.testing.allocator, "define {s} @closed(ptr %unused) {{\nentry:\n ret {s}\n}}\n", .{ typed[0..space], typed });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try payloads.legalize(arena.allocator(), module.functions.items[0], null)) == null);
    }
}

fn executable(source: []const u8) ![]align(std.heap.page_size_min) u8 {
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    const function = module.functions.items[0];
    var output = machine.MachineFunction.init(function.name, function.ret_ty);
    defer output.deinit(std.testing.allocator);
    const selected = try selector.tryLower(std.testing.allocator, &output, function);
    if (selected == .unsupported) std.debug.print("floating payload {s}: {s}\n", .{ function.name, selected.unsupported.detail() });
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try verify.verifyFunction(output);
    const bytes = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(bytes);
    const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(code[0..bytes.len], bytes);
    return code;
}

const payload_cases = [_]u128{ 0, 1, @as(u128, 1) << 127, @as(u128, 0x3fff) << 112, @as(u128, 0x7fff) << 112, (@as(u128, 0x7fff) << 112) | 1, (@as(u128, 0xffff800000000123) << 64) | 0xfeedface01234567, std.math.maxInt(u128) };

test "floating payload scalar selects preserve whole quad representations and literal arms" {
    for (0..3) |literal| {
        const left = if (literal == 1) "0xL00000000000000017FFF000000000000" else "%a";
        const right = if (literal == 2) "0xL00000000000000008000000000000000" else "%b";
        const text = try std.fmt.allocPrint(std.testing.allocator, "define void @choose(ptr %left,ptr %right,ptr %output,i64 %choice) {{\nentry:\n %a = load fp128,ptr %left,align 1\n %b = load fp128,ptr %right,align 1\n %condition = trunc i64 %choice to i1\n %selected = select i1 %condition,fp128 {s},fp128 {s}\n store fp128 %selected,ptr %output,align 1\n ret void\n}}\n", .{ left, right });
        defer std.testing.allocator.free(text);
        const code = try executable(text);
        defer std.posix.munmap(code);
        const run: *const fn (*const u128, *const u128, *u8, u64) callconv(.c) void = @ptrCast(code.ptr);
        for (payload_cases) |a| for (payload_cases) |b| for ([_]u64{ 0, 1, 2, 3, std.math.maxInt(u64) }) |choice| {
            var guarded: [24]u8 = @splat(0xa7);
            run(&a, &b, &guarded[1], choice);
            const lhs = if (literal == 1) (@as(u128, 0x7fff) << 112) | 1 else a;
            const rhs = if (literal == 2) @as(u128, 1) << 127 else b;
            try std.testing.expectEqual(if (choice & 1 != 0) lhs else rhs, std.mem.readInt(u128, guarded[1..17], .little));
            try std.testing.expectEqual(@as(u8, 0xa7), guarded[0]);
            for (guarded[17..]) |byte| try std.testing.expectEqual(@as(u8, 0xa7), byte);
        };
    }
}

test "floating payload verifier requires all 128 XMM return bits" {
    var output = machine.MachineFunction.init("quad_return", .fp128);
    defer output.deinit(std.testing.allocator);
    try output.instructions.appendSlice(std.testing.allocator, &.{ .{ .mov_imm_eax = 42 }, .ret });
    try std.testing.expectError(error.ReturnRegisterUndefined, verify.verifyFunction(output));
    output.entry_xmm_defined_bits[0] = 64;
    try std.testing.expectError(error.ReturnRegisterUndefined, verify.verifyFunction(output));
    output.entry_xmm_defined_bits[0] = 128;
    try verify.verifyFunction(output);
}

test "floating payload executes exact XMM parameters phi freeze memory and returns" {
    const code = try executable(
        \\define fp128 @transport(fp128 %a, fp128 %b, i32 %choice, ptr %out) {
        \\entry:
        \\ %slot = alloca fp128, align 16
        \\ store fp128 %a, ptr %slot, align 16
        \\ %loaded = load fp128, ptr %slot, align 16
        \\ %cond = icmp ne i32 %choice, 0
        \\ br i1 %cond, label %left, label %right
        \\left:
        \\ %stable = freeze fp128 %loaded
        \\ br label %join
        \\right:
        \\ br label %join
        \\join:
        \\ %v = phi fp128 [ %stable, %left ], [ %b, %right ]
        \\ store fp128 %v, ptr %out, align 1
        \\ ret fp128 %v
        \\}
    );
    defer std.posix.munmap(code);
    const run: *const fn (f128, f128, u32, *u64) callconv(.c) f128 = @ptrCast(code.ptr);
    for (payload_cases) |a| for (payload_cases) |b| for ([_]u32{ 0, 1, std.math.maxInt(u32) }) |choice| {
        var output: [4]u64 align(16) = .{ 0x123456789abcdef0, 0, 0, 0xfedcba9876543210 };
        const expected = if (choice != 0) a else b;
        try std.testing.expectEqual(expected, @as(u128, @bitCast(run(@bitCast(a), @bitCast(b), choice, &output[1]))));
        try std.testing.expectEqual(expected, @as(u128, output[1]) | (@as(u128, output[2]) << 64));
        try std.testing.expectEqual(@as(u64, 0x123456789abcdef0), output[0]);
        try std.testing.expectEqual(@as(u64, 0xfedcba9876543210), output[3]);
    };
}

test "floating payload executes scalar pair bitcasts in both ABI directions" {
    const forward = try executable("define i128 @bits(fp128 %a) {\nentry:\n %r = bitcast fp128 %a to i128\n ret i128 %r\n}\n");
    defer std.posix.munmap(forward);
    const inverse = try executable("define fp128 @bits(i128 %a) {\nentry:\n %r = bitcast i128 %a to fp128\n ret fp128 %r\n}\n");
    defer std.posix.munmap(inverse);
    const read: *const fn (f128) callconv(.c) u128 = @ptrCast(forward.ptr);
    const write: *const fn (u128) callconv(.c) f128 = @ptrCast(inverse.ptr);
    for (payload_cases) |bits| {
        try std.testing.expectEqual(bits, read(@bitCast(bits)));
        try std.testing.expectEqual(bits, @as(u128, @bitCast(write(bits))));
    }
}

test "floating payload executes frameless identity exact literals and undefined freeze" {
    const code = try executable("define fp128 @identity(fp128 %a) {\nentry:\n ret fp128 %a\n}\n");
    defer std.posix.munmap(code);
    const identity: *const fn (f128) callconv(.c) f128 = @ptrCast(code.ptr);
    for (payload_cases) |bits| {
        try std.testing.expectEqual(bits, @as(u128, @bitCast(identity(@bitCast(bits)))));
        const source = try std.fmt.allocPrint(std.testing.allocator, "define fp128 @constant() {{\nentry:\n ret fp128 0xL{X:0>16}{X:0>16}\n}}\n", .{ @as(u64, @truncate(bits)), @as(u64, @truncate(bits >> 64)) });
        defer std.testing.allocator.free(source);
        const literal_code = try executable(source);
        defer std.posix.munmap(literal_code);
        const literal: *const fn () callconv(.c) f128 = @ptrCast(literal_code.ptr);
        try std.testing.expectEqual(bits, @as(u128, @bitCast(literal())));
    }
    for ([_][]const u8{ "undef", "poison" }) |unknown| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "define fp128 @frozen() {{\nentry:\n %v = freeze fp128 {s}\n ret fp128 %v\n}}\n", .{unknown});
        defer std.testing.allocator.free(source);
        const frozen_code = try executable(source);
        defer std.posix.munmap(frozen_code);
        const frozen: *const fn () callconv(.c) f128 = @ptrCast(frozen_code.ptr);
        try std.testing.expectEqual(@as(u128, 0), @as(u128, @bitCast(frozen())));
    }
}

test "floating payload arithmetic maps standard compiler-rt types without changing sources" {
    const arithmetic = @import("binary128_arithmetic.zig");
    const source =
        \\define fp128 @f(float %f, double %d, i32 %i, i64 %j, fp128 %a, half %h, i128 %k) {
        \\entry:
        \\ %fwide = fpext float %f to fp128
        \\ %dwide = fpext double %d to fp128
        \\ %s32 = sitofp i32 %i to fp128
        \\ %u32 = uitofp i32 %i to fp128
        \\ %s64 = sitofp i64 %j to fp128
        \\ %u64 = uitofp i64 %j to fp128
        \\ %hwide = fpext half %h to fp128
        \\ %s128 = sitofp i128 %k to fp128
        \\ %u128 = uitofp i128 %k to fp128
        \\ %narrowf = fptrunc fp128 %a to float
        \\ %narrowd = fptrunc fp128 %a to double
        \\ %si32 = fptosi fp128 %a to i32
        \\ %ui32 = fptoui fp128 %a to i32
        \\ %si64 = fptosi fp128 %a to i64
        \\ %ui64 = fptoui fp128 %a to i64
        \\ %narrowh = fptrunc fp128 %a to half
        \\ %si128 = fptosi fp128 %a to i128
        \\ %ui128 = fptoui fp128 %a to i128
        \\ %sum = fadd fp128 %a, %fwide
        \\ %difference = fsub fp128 %sum, %dwide
        \\ %product = fmul fp128 %difference, %u32
        \\ %quotient = fdiv fp128 %product, %u64
        \\ ret fp128 %quotient
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const original = module.functions.items[0];
    const private = (try arithmetic.legalize(arena.allocator(), original)).?;
    const names = [_][]const u8{ "__extendsftf2", "__extenddftf2", "__floatsitf", "__floatunsitf", "__floatditf", "__floatunditf", "__extendhftf2", "__floattitf", "__floatuntitf", "__trunctfsf2", "__trunctfdf2", "__fixtfsi", "__fixunstfsi", "__fixtfdi", "__fixunstfdi", "__trunctfhf2", "__fixtfti", "__fixunstfti", "__addtf3", "__subtf3", "__multf3", "__divtf3" };
    for (private.blocks.items[0].instructions.items, names) |inst, name| try std.testing.expectEqualStrings(name, inst.kind.call.callee);
    try std.testing.expect(original.blocks.items[0].instructions.items[0].kind == .cast);
    try std.testing.expect((try arithmetic.legalize(arena.allocator(), private)) == null);
}

test "floating payload arithmetic leaves synthetic negation to its bitwise fallback" {
    var module = try ir.Module.parse(std.testing.allocator, "define fp128 @neg(fp128 %a) {\nentry:\n %r = fneg fp128 %a\n ret fp128 %r\n}\n");
    defer module.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expect((try @import("binary128_arithmetic.zig").legalize(arena.allocator(), module.functions.items[0])) == null);
    const x86 = @import("../../x86_64.zig");
    var output = try x86.lowerFunctionWithOptions(std.testing.allocator, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true });
    defer output.deinit(std.testing.allocator);
    try std.testing.expectEqual(@import("../types.zig").SelectionOwner.structural_fallback, output.selection_owner);
    try verify.verifyFunction(output);
    const bytes = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(bytes);
    const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(code);
    @memcpy(code[0..bytes.len], bytes);
    const run: *const fn (f128) callconv(.c) f128 = @ptrCast(code.ptr);
    for (payload_cases) |bits| try std.testing.expectEqual(bits ^ (@as(u128, 1) << 127), @as(u128, @bitCast(run(@bitCast(bits)))));
}

test "floating payload extended conversions do not outline a runtime helper into itself" {
    const cases = [_]struct { symbol: []const u8, from: []const u8, to: []const u8, op: []const u8 }{
        .{ .symbol = "__extendhftf2", .from = "half", .to = "fp128", .op = "fpext" },
        .{ .symbol = "__trunctfhf2", .from = "fp128", .to = "half", .op = "fptrunc" },
        .{ .symbol = "__floattitf", .from = "i128", .to = "fp128", .op = "sitofp" },
        .{ .symbol = "__floatuntitf", .from = "i128", .to = "fp128", .op = "uitofp" },
        .{ .symbol = "__fixtfti", .from = "fp128", .to = "i128", .op = "fptosi" },
        .{ .symbol = "__fixunstfti", .from = "fp128", .to = "i128", .op = "fptoui" },
    };
    for (cases) |case| for ([_]bool{ false, true }) |quoted| {
        const name = if (quoted) try std.fmt.allocPrint(std.testing.allocator, "\"\\5F{s}\"", .{case.symbol[1..]}) else try std.testing.allocator.dupe(u8, case.symbol);
        defer std.testing.allocator.free(name);
        const text = try std.fmt.allocPrint(std.testing.allocator, "define {s} @{s}({s} %input) {{\nentry:\n %r = {s} {s} %input to {s}\n ret {s} %r\n}}\n", .{ case.to, name, case.from, case.op, case.from, case.to, case.to });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try @import("binary128_arithmetic.zig").legalize(arena.allocator(), module.functions.items[0])) == null);
    };
}

test "floating payload extended conversions pass native helper ABI verification" {
    const cases = [_]struct { from: []const u8, to: []const u8, op: []const u8 }{
        .{ .from = "half", .to = "fp128", .op = "fpext" },
        .{ .from = "i128", .to = "fp128", .op = "sitofp" },
        .{ .from = "i128", .to = "fp128", .op = "uitofp" },
        .{ .from = "fp128", .to = "half", .op = "fptrunc" },
        .{ .from = "fp128", .to = "i128", .op = "fptosi" },
        .{ .from = "fp128", .to = "i128", .op = "fptoui" },
    };
    for (cases) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define {s} @convert({s} %input) {{\nentry:\n %r = {s} {s} %input to {s}\n ret {s} %r\n}}\n", .{ case.to, case.from, case.op, case.from, case.to, case.to });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var output = try @import("../../x86_64.zig").lowerFunctionWithOptions(std.testing.allocator, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true });
        defer output.deinit(std.testing.allocator);
        try verify.verifyFunction(output);
        const bytes = try encoding.encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(bytes);
        try std.testing.expect(bytes.len > 0);
    }
}

test "floating payload constant comparisons discharge mandatory width normalization" {
    for ([_][]const u8{ "false", "true" }, [_]u32{ 0, 1 }) |predicate, expected| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "define i32 @f(fp128 %a, fp128 %b, ptr %out) {{\nentry:\n %c = fcmp {s} fp128 %a, %b\n store fp128 %a, ptr %out, align 1\n %r = zext i1 %c to i32\n ret i32 %r\n}}\n", .{predicate});
        defer std.testing.allocator.free(source);
        const code = try executable(source);
        defer std.posix.munmap(code);
        const run: *const fn (f128, f128, *u64) callconv(.c) u32 = @ptrCast(code.ptr);
        for (payload_cases) |bits| {
            var output: [4]u64 = .{ 0x123456789abcdef0, 0, 0, 0xfedcba9876543210 };
            try std.testing.expectEqual(expected, run(@bitCast(bits), @bitCast(~bits), &output[1]));
            try std.testing.expectEqual(bits, @as(u128, output[1]) | (@as(u128, output[2]) << 64));
            try std.testing.expectEqual(@as(u64, 0x123456789abcdef0), output[0]);
            try std.testing.expectEqual(@as(u64, 0xfedcba9876543210), output[3]);
        }
    }
}

test "floating payload preserves original types declarations promises and literals" {
    const source =
        \\declare noundef fp128 @callee(fp128)
        \\define noundef fp128 @f(fp128 noundef %a, ptr %out, i1 %cond) {
        \\entry:
        \\ %slot = alloca fp128, align 16
        \\ store fp128 %a, ptr %slot, align 16
        \\ %loaded = load fp128, ptr %slot, align 16
        \\ %s = select i1 %cond, fp128 %loaded, fp128 0xL0123456789ABCDEF7FFF000000000001
        \\ %r = tail call noundef fp128 @callee(fp128 %s)
        \\ store fp128 %r, ptr %out, align 1
        \\ ret fp128 %r
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    const original = module.functions.items[0];
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const private = (try payloads.legalize(arena.allocator(), original, null)).?;
    try std.testing.expect(original.ret_ty == .fp128);
    try std.testing.expect(original.params.items[0].ty == .fp128);
    try std.testing.expect(module.declarations.items[0].ret_ty == .fp128);
    try std.testing.expect(private.ret_ty == .vector);
    try std.testing.expectEqualStrings("noundef", private.params.items[0].attrs.?);
    const selected = private.blocks.items[0].instructions.items[3].kind.select;
    try std.testing.expectEqualStrings("<double 0x0123456789ABCDEF, double 0x7FFF000000000001>", selected.false_value.vector);
    try std.testing.expect(private.blocks.items[0].instructions.items[4].kind.call.tail_kind == null);
    try std.testing.expectEqualStrings("tail", original.blocks.items[0].instructions.items[4].kind.call.tail_kind.?);
    try std.testing.expect((try payloads.legalize(arena.allocator(), private, null)) == null);
}

test "floating payload does not reinterpret arithmetic conversions barriers or mandatory tails" {
    for ([_][]const u8{
        "define fp128 @f(fp128 %a) {\nentry:\n %r = fadd fp128 %a, %a\n ret fp128 %r\n}\n",
        "define double @f(fp128 %a) {\nentry:\n %r = fptrunc fp128 %a to double\n ret double %r\n}\n",
        "define fp128 @f(ptr %p) {\nentry:\n %r = load volatile fp128, ptr %p\n ret fp128 %r\n}\n",
        "define void @f(fp128 %a, ptr %p) {\nentry:\n store volatile fp128 %a, ptr %p\n ret void\n}\n",
        "declare fp128 @callee(fp128)\ndefine fp128 @f(fp128 %a) {\nentry:\n %r = musttail call fp128 @callee(fp128 %a)\n ret fp128 %r\n}\n",
    }) |source| {
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try payloads.legalize(arena.allocator(), module.functions.items[0], null)) == null);
    }
}

fn quadLiteralProbe(a: f128, b: f128) callconv(.c) f128 {
    return @bitCast(@as(u128, @bitCast(a)) ^ @as(u128, @bitCast(b)));
}

test "floating payload later literal call arguments preserve the first XMM operand" {
    for ([_]usize{ 1, 97 }) |call_count| {
        var source_writer: std.Io.Writer.Allocating = .init(std.testing.allocator);
        defer source_writer.deinit();
        try source_writer.writer.writeAll("declare fp128 @quad_probe(fp128,fp128)\ndefine void @probe(ptr %input,ptr %output) {\nentry:\n %a = load fp128,ptr %input,align 1\n");
        for (0..call_count) |index| {
            if (index == 0) {
                try source_writer.writer.writeAll(" %r0 = call fp128 @quad_probe(fp128 %a,fp128 0xL00000000000000004000400000000000)\n");
            } else try source_writer.writer.print(" %r{d} = call fp128 @quad_probe(fp128 %r{d},fp128 0xL00000000000000004000400000000000)\n", .{ index, index - 1 });
        }
        try source_writer.writer.print(" store fp128 %r{d},ptr %output,align 1\n ret void\n}}\n", .{call_count - 1});
        const source = source_writer.written();
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        var output = machine.MachineFunction.init("probe", .void);
        defer output.deinit(std.testing.allocator);
        try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]));
        try verify.verifyFunction(output);
        const bytes = try encoding.encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(bytes);
        const code = try std.posix.mmap(null, bytes.len + 12, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(code);
        @memcpy(code[0..bytes.len], bytes);
        const stub = code[bytes.len..][0..12];
        stub[0] = 0x48;
        stub[1] = 0xb8;
        std.mem.writeInt(u64, stub[2..10], @intFromPtr(&quadLiteralProbe), .little);
        stub[10] = 0xff;
        stub[11] = 0xe0;
        var offset: usize = 0;
        for (output.instructions.items) |instruction| {
            if (instruction == .direct_call) {
                try std.testing.expectEqualStrings("quad_probe", instruction.direct_call.symbol);
                const displacement: i32 = @intCast(bytes.len - (offset + 5));
                std.mem.writeInt(i32, code[offset + 1 ..][0..4], displacement, .little);
            }
            offset += encoding.instructionSize(instruction);
        }
        const run: *const fn (*const u128, *u8) callconv(.c) void = @ptrCast(code.ptr);
        for (payload_cases) |raw| {
            var guarded: [24]u8 = @splat(0xa7);
            run(&raw, &guarded[1]);
            try std.testing.expectEqual(raw ^ (@as(u128, 0x4000400000000000) << 64), std.mem.readInt(u128, guarded[1..17], .little));
            try std.testing.expectEqual(@as(u8, 0xa7), guarded[0]);
            for (guarded[17..]) |byte| try std.testing.expectEqual(@as(u8, 0xa7), byte);
        }
    }
}
