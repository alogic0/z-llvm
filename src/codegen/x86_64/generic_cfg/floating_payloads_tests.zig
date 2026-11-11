const std = @import("std");
const ir = @import("../../../ir.zig");
const payloads = @import("floating_payloads.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");

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
