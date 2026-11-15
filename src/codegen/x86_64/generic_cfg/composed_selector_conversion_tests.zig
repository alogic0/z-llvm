const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");
const inspection = @import("inspection.zig");
const selector_impl = @import("composed_selector_impl.zig");

test "generic cfg selector converts every sub-byte integer to scalar FP exactly" {
    for (1..8) |width| for ([_]bool{ false, true }) |signed| for ([_]bool{ false, true }) |to_float| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i64 @convert(i8 %input) {{\nentry:\n %narrow = trunc i8 %input to i{d}\n %fp = {s} i{d} %narrow to {s}\n %raw = bitcast {s} %fp to i{d}\n{s} ret i64 %answer\n}}\n", .{ width, if (signed) "sitofp" else "uitofp", width, if (to_float) "float" else "double", if (to_float) "float" else "double", @as(u16, if (to_float) 32 else 64), if (to_float) " %answer = zext i32 %raw to i64\n" else " %answer = add i64 %raw,0\n" });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var machine = x86_64_machine.MachineFunction.init("convert", .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        const selected = try @import("../generic_cfg_selector.zig").tryLower(std.testing.allocator, &machine, module.functions.items[0]);
        if (selected == .unsupported) std.debug.print("sub-byte FP i{d}: {s}\n", .{ width, selected.unsupported.detail() });
        try std.testing.expectEqual(inspection.SelectionResult.selected, selected);
        try x86_64_verify.verifyFunction(machine);
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping[0..bytes.len], bytes);
        const run: *const fn (u8) callconv(.c) u64 = @ptrCast(mapping.ptr);
        for (0..256) |input| {
            const modulus = @as(u16, 1) << @as(u4, @intCast(width));
            const raw: i32 = @intCast(input & (modulus - 1));
            const integer: i32 = if (signed and raw >= modulus / 2) raw - modulus else raw;
            const expected_bits: u64 = if (to_float) @as(u32, @bitCast(@as(f32, @floatFromInt(integer)))) else @bitCast(@as(f64, @floatFromInt(integer)));
            try std.testing.expectEqual(expected_bits, run(@intCast(input)));
        }
        try module.verify();
    };
}

const ConversionCase = struct {
    op: ir.CastOp,
    bits: u16,
    raw: u64,
    f32_bits: u32,
    f64_bits: u64,
};

test "generic cfg selector executes signed and unsigned integer to FP conversions exactly" {
    const cases = [_]ConversionCase{
        .{ .op = .sitofp, .bits = 8, .raw = 0x80, .f32_bits = 0xc300_0000, .f64_bits = 0xc060_0000_0000_0000 },
        .{ .op = .sitofp, .bits = 8, .raw = 0x7f, .f32_bits = 0x42fe_0000, .f64_bits = 0x405f_c000_0000_0000 },
        .{ .op = .sitofp, .bits = 12, .raw = 0x800, .f32_bits = 0xc500_0000, .f64_bits = 0xc0a0_0000_0000_0000 },
        .{ .op = .sitofp, .bits = 12, .raw = 0x7ff, .f32_bits = 0x44ff_e000, .f64_bits = 0x409f_fc00_0000_0000 },
        .{ .op = .sitofp, .bits = 16, .raw = 0x8000, .f32_bits = 0xc700_0000, .f64_bits = 0xc0e0_0000_0000_0000 },
        .{ .op = .sitofp, .bits = 16, .raw = 0x7fff, .f32_bits = 0x46ff_fe00, .f64_bits = 0x40df_ffc0_0000_0000 },
        .{ .op = .sitofp, .bits = 32, .raw = 0x8000_0000, .f32_bits = 0xcf00_0000, .f64_bits = 0xc1e0_0000_0000_0000 },
        .{ .op = .sitofp, .bits = 32, .raw = 0x7fff_ffff, .f32_bits = 0x4f00_0000, .f64_bits = 0x41df_ffff_ffc0_0000 },
        .{ .op = .sitofp, .bits = 33, .raw = 0x1_0000_0000, .f32_bits = 0xcf80_0000, .f64_bits = 0xc1f0_0000_0000_0000 },
        .{ .op = .sitofp, .bits = 33, .raw = 0xffff_ffff, .f32_bits = 0x4f80_0000, .f64_bits = 0x41ef_ffff_ffe0_0000 },
        .{ .op = .sitofp, .bits = 63, .raw = 0x4000_0000_0000_0000, .f32_bits = 0xde80_0000, .f64_bits = 0xc3d0_0000_0000_0000 },
        .{ .op = .sitofp, .bits = 63, .raw = 0x3fff_ffff_ffff_ffff, .f32_bits = 0x5e80_0000, .f64_bits = 0x43d0_0000_0000_0000 },
        .{ .op = .sitofp, .bits = 64, .raw = 0x8000_0000_0000_0000, .f32_bits = 0xdf00_0000, .f64_bits = 0xc3e0_0000_0000_0000 },
        .{ .op = .sitofp, .bits = 64, .raw = 0x7fff_ffff_ffff_ffff, .f32_bits = 0x5f00_0000, .f64_bits = 0x43e0_0000_0000_0000 },
        .{ .op = .sitofp, .bits = 64, .raw = 0x0020_0000_0000_0001, .f32_bits = 0x5a00_0000, .f64_bits = 0x4340_0000_0000_0000 },
        .{ .op = .sitofp, .bits = 64, .raw = 0x0020_0000_0000_0003, .f32_bits = 0x5a00_0000, .f64_bits = 0x4340_0000_0000_0002 },
        .{ .op = .uitofp, .bits = 8, .raw = 0xff, .f32_bits = 0x437f_0000, .f64_bits = 0x406f_e000_0000_0000 },
        .{ .op = .uitofp, .bits = 12, .raw = 0xfff, .f32_bits = 0x457f_f000, .f64_bits = 0x40af_fe00_0000_0000 },
        .{ .op = .uitofp, .bits = 16, .raw = 0xffff, .f32_bits = 0x477f_ff00, .f64_bits = 0x40ef_ffe0_0000_0000 },
        .{ .op = .uitofp, .bits = 31, .raw = 0x7fff_ffff, .f32_bits = 0x4f00_0000, .f64_bits = 0x41df_ffff_ffc0_0000 },
        .{ .op = .uitofp, .bits = 32, .raw = 0xffff_ffff, .f32_bits = 0x4f80_0000, .f64_bits = 0x41ef_ffff_ffe0_0000 },
        .{ .op = .uitofp, .bits = 33, .raw = 0x1_ffff_ffff, .f32_bits = 0x5000_0000, .f64_bits = 0x41ff_ffff_fff0_0000 },
        .{ .op = .uitofp, .bits = 63, .raw = 0x7fff_ffff_ffff_ffff, .f32_bits = 0x5f00_0000, .f64_bits = 0x43e0_0000_0000_0000 },
        .{ .op = .uitofp, .bits = 64, .raw = 0, .f32_bits = 0, .f64_bits = 0 },
        .{ .op = .uitofp, .bits = 64, .raw = 0x8000_0000_0000_0000, .f32_bits = 0x5f00_0000, .f64_bits = 0x43e0_0000_0000_0000 },
        .{ .op = .uitofp, .bits = 64, .raw = 0x8000_0000_0000_0001, .f32_bits = 0x5f00_0000, .f64_bits = 0x43e0_0000_0000_0000 },
        .{ .op = .uitofp, .bits = 64, .raw = 0xffff_ffff_ffff_ffff, .f32_bits = 0x5f80_0000, .f64_bits = 0x43f0_0000_0000_0000 },
    };

    for (cases) |case| try expectConversion(case);
}

fn expectConversion(case: ConversionCase) !void {
    const input = if (case.bits == 64)
        try std.fmt.allocPrint(std.testing.allocator,
            \\define void @convert(ptr %out, i64 %raw) {{
            \\entry:
            \\  %f = {s} i64 %raw to float
            \\  %d = {s} i64 %raw to double
            \\  %fb = bitcast float %f to i32
            \\  %db = bitcast double %d to i64
            \\  store i32 %fb, ptr %out, align 4
            \\  %dout = getelementptr i8, ptr %out, i64 8
            \\  store i64 %db, ptr %dout, align 8
            \\  ret void
            \\}}
            \\
        , .{ @tagName(case.op), @tagName(case.op) })
    else
        try std.fmt.allocPrint(std.testing.allocator,
            \\define void @convert(ptr %out, i64 %raw) {{
            \\entry:
            \\  %source = trunc i64 %raw to i{d}
            \\  %f = {s} i{d} %source to float
            \\  %d = {s} i{d} %source to double
            \\  %fb = bitcast float %f to i32
            \\  %db = bitcast double %d to i64
            \\  store i32 %fb, ptr %out, align 4
            \\  %dout = getelementptr i8, ptr %out, i64 8
            \\  store i64 %db, ptr %dout, align 8
            \\  ret void
            \\}}
            \\
        , .{ case.bits, @tagName(case.op), case.bits, @tagName(case.op), case.bits });
    defer std.testing.allocator.free(input);

    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = x86_64_machine.MachineFunction.init("convert", .void);
    defer machine.deinit(std.testing.allocator);
    const selection = try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, selection);

    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const canary: *const fn (*[2]u64, u64) callconv(.c) void = @ptrCast(mapping.ptr);
    var output = [2]u64{ 0, 0 };
    canary(&output, case.raw);
    try std.testing.expectEqual(case.f32_bits, @as(u32, @truncate(output[0])));
    try std.testing.expectEqual(case.f64_bits, output[1]);
}

test "generic cfg selector executes readonly wide integer loads and FP conversion bit exactly" {
    const input =
        \\define i32 @u96f32(ptr nonnull readonly align 1 captures(none) %p) {
        \\entry:
        \\  %x = load i96, ptr %p, align 4
        \\  %f = uitofp i96 %x to float
        \\  %r = bitcast float %f to i32
        \\  ret i32 %r
        \\}
        \\define i64 @u96f64(ptr nonnull readonly align 1 captures(none) %p) {
        \\entry:
        \\  %x = load i96, ptr %p, align 4
        \\  %f = uitofp i96 %x to double
        \\  %r = bitcast double %f to i64
        \\  ret i64 %r
        \\}
        \\define i32 @s96f32(ptr nonnull readonly align 1 captures(none) %p) {
        \\entry:
        \\  %x = load i96, ptr %p, align 4
        \\  %f = sitofp i96 %x to float
        \\  %r = bitcast float %f to i32
        \\  ret i32 %r
        \\}
        \\define i64 @s96f64(ptr nonnull readonly align 1 captures(none) %p) {
        \\entry:
        \\  %x = load i96, ptr %p, align 4
        \\  %f = sitofp i96 %x to double
        \\  %r = bitcast double %f to i64
        \\  ret i64 %r
        \\}
        \\define i32 @u128f32(ptr nonnull readonly align 1 captures(none) %p) {
        \\entry:
        \\  %x = load i128, ptr %p, align 4
        \\  %f = uitofp i128 %x to float
        \\  %r = bitcast float %f to i32
        \\  ret i32 %r
        \\}
        \\define i64 @u128f64(ptr nonnull readonly align 1 captures(none) %p) {
        \\entry:
        \\  %x = load i128, ptr %p, align 4
        \\  %f = uitofp i128 %x to double
        \\  %r = bitcast double %f to i64
        \\  ret i64 %r
        \\}
        \\define i32 @s128f32(ptr nonnull readonly align 1 captures(none) %p) {
        \\entry:
        \\  %x = load i128, ptr %p, align 4
        \\  %f = sitofp i128 %x to float
        \\  %r = bitcast float %f to i32
        \\  ret i32 %r
        \\}
        \\define i64 @s128f64(ptr nonnull readonly align 1 captures(none) %p) {
        \\entry:
        \\  %x = load i128, ptr %p, align 4
        \\  %f = sitofp i128 %x to double
        \\  %r = bitcast double %f to i64
        \\  ret i64 %r
        \\}
        \\define i64 @u64loadf64(ptr nonnull readonly align 1 captures(none) %p) {
        \\entry:
        \\  %x = load i64, ptr %p, align 4
        \\  %f = uitofp i64 %x to double
        \\  %r = bitcast double %f to i64
        \\  ret i64 %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const UCase = struct { raw: u128, f32_bits: u32, f64_bits: u64 };
    const unsigned96 = [_]UCase{
        .{ .raw = 0, .f32_bits = 0x0000_0000, .f64_bits = 0x0000_0000_0000_0000 },
        .{ .raw = 1, .f32_bits = 0x3f80_0000, .f64_bits = 0x3ff0_0000_0000_0000 },
        .{ .raw = 0x0020_0000_0000_0001, .f32_bits = 0x5a00_0000, .f64_bits = 0x4340_0000_0000_0000 },
        .{ .raw = 0x0020_0000_0000_0003, .f32_bits = 0x5a00_0000, .f64_bits = 0x4340_0000_0000_0002 },
        .{ .raw = 0xffff_ffff_ffff_ffff, .f32_bits = 0x5f80_0000, .f64_bits = 0x43f0_0000_0000_0000 },
        .{ .raw = 0x1_0000_0000_0000_0000, .f32_bits = 0x5f80_0000, .f64_bits = 0x43f0_0000_0000_0000 },
        .{ .raw = 0x7fff_ffff_ffff_ffff_ffff_ffff, .f32_bits = 0x6f00_0000, .f64_bits = 0x45e0_0000_0000_0000 },
        .{ .raw = 0xffff_ffff_ffff_ffff_ffff_ffff, .f32_bits = 0x6f80_0000, .f64_bits = 0x45f0_0000_0000_0000 },
    };
    const unsigned128 = unsigned96 ++ [_]UCase{
        .{ .raw = 0x8000_0000_0000_0000_0000_0000_0000_0000, .f32_bits = 0x7f00_0000, .f64_bits = 0x47e0_0000_0000_0000 },
        .{ .raw = 0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff, .f32_bits = 0x7f80_0000, .f64_bits = 0x47f0_0000_0000_0000 },
    };
    const SCase = struct { raw: u128, f32_bits: u32, f64_bits: u64 };
    const signed96 = [_]SCase{
        .{ .raw = 0, .f32_bits = 0x0000_0000, .f64_bits = 0x0000_0000_0000_0000 },
        .{ .raw = 1, .f32_bits = 0x3f80_0000, .f64_bits = 0x3ff0_0000_0000_0000 },
        .{ .raw = 0xffff_ffff_ffff_ffff_ffff_ffff, .f32_bits = 0xbf80_0000, .f64_bits = 0xbff0_0000_0000_0000 },
        .{ .raw = 0x0020_0000_0000_0001, .f32_bits = 0x5a00_0000, .f64_bits = 0x4340_0000_0000_0000 },
        .{ .raw = 0xffff_ffff_ffdf_ffff_ffff_ffff, .f32_bits = 0xda00_0000, .f64_bits = 0xc340_0000_0000_0000 },
        .{ .raw = 0x7fff_ffff_ffff_ffff_ffff_ffff, .f32_bits = 0x6f00_0000, .f64_bits = 0x45e0_0000_0000_0000 },
        .{ .raw = 0x8000_0000_0000_0000_0000_0000, .f32_bits = 0xef00_0000, .f64_bits = 0xc5e0_0000_0000_0000 },
    };
    const signed128 = [_]SCase{
        .{ .raw = 0, .f32_bits = 0x0000_0000, .f64_bits = 0x0000_0000_0000_0000 },
        .{ .raw = 1, .f32_bits = 0x3f80_0000, .f64_bits = 0x3ff0_0000_0000_0000 },
        .{ .raw = 0xffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff, .f32_bits = 0xbf80_0000, .f64_bits = 0xbff0_0000_0000_0000 },
        .{ .raw = 0x0020_0000_0000_0001, .f32_bits = 0x5a00_0000, .f64_bits = 0x4340_0000_0000_0000 },
        .{ .raw = 0xffff_ffff_ffff_ffff_ffdf_ffff_ffff_ffff, .f32_bits = 0xda00_0000, .f64_bits = 0xc340_0000_0000_0000 },
        .{ .raw = 0x7fff_ffff_ffff_ffff_ffff_ffff, .f32_bits = 0x6f00_0000, .f64_bits = 0x45e0_0000_0000_0000 },
        .{ .raw = 0xffff_ffff_8000_0000_0000_0000_0000_0000, .f32_bits = 0xef00_0000, .f64_bits = 0xc5e0_0000_0000_0000 },
        .{ .raw = 0x7fff_ffff_ffff_ffff_ffff_ffff_ffff_ffff, .f32_bits = 0x7f00_0000, .f64_bits = 0x47e0_0000_0000_0000 },
        .{ .raw = 0x8000_0000_0000_0000_0000_0000_0000_0000, .f32_bits = 0xff00_0000, .f64_bits = 0xc7e0_0000_0000_0000 },
    };

    try expectWidePointerResults(u32, module.functions.items[0], unsigned96, "f32_bits");
    try expectWidePointerResults(u64, module.functions.items[1], unsigned96, "f64_bits");
    try expectWidePointerResults(u32, module.functions.items[2], signed96, "f32_bits");
    try expectWidePointerResults(u64, module.functions.items[3], signed96, "f64_bits");
    try expectWidePointerResults(u32, module.functions.items[4], unsigned128, "f32_bits");
    try expectWidePointerResults(u64, module.functions.items[5], unsigned128, "f64_bits");
    try expectWidePointerResults(u32, module.functions.items[6], signed128, "f32_bits");
    try expectWidePointerResults(u64, module.functions.items[7], signed128, "f64_bits");
    try expectWidePointerResults(u64, module.functions.items[8], unsigned96[4..5], "f64_bits");
}

fn expectWidePointerResults(comptime T: type, function: ir.Function, cases: anytype, comptime expected_field: []const u8) !void {
    var machine = x86_64_machine.MachineFunction.init(function.name, function.ret_ty);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, function));
    try x86_64_verify.verifyFunction(machine);
    for (machine.instructions.items) |instruction| try std.testing.expect(std.meta.activeTag(instruction) != .direct_call);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const canary: *const fn (*const u128) callconv(.c) T = @ptrCast(mapping.ptr);
    for (cases) |case| try std.testing.expectEqual(@field(case, expected_field), canary(&case.raw));
}

test "integer-to-half f32 composition is exact at every rounding and overflow boundary" {
    const Case = struct { value: i128, bits: u16 };
    const cases = [_]Case{
        .{ .value = -65521, .bits = 0xfc00 }, .{ .value = -65520, .bits = 0xfc00 }, .{ .value = -65519, .bits = 0xfbff },
        .{ .value = -65505, .bits = 0xfbff }, .{ .value = -65504, .bits = 0xfbff }, .{ .value = -65503, .bits = 0xfbff },
        .{ .value = -2049, .bits = 0xe800 },  .{ .value = -2048, .bits = 0xe800 },  .{ .value = -2047, .bits = 0xe7ff },
        .{ .value = 2047, .bits = 0x67ff },   .{ .value = 2048, .bits = 0x6800 },   .{ .value = 2049, .bits = 0x6800 },
        .{ .value = 65503, .bits = 0x7bff },  .{ .value = 65504, .bits = 0x7bff },  .{ .value = 65505, .bits = 0x7bff },
        .{ .value = 65519, .bits = 0x7bff },  .{ .value = 65520, .bits = 0x7c00 },  .{ .value = 65521, .bits = 0x7c00 },
    };
    for (cases) |case| {
        const through_f32: f16 = @floatCast(@as(f32, @floatFromInt(case.value)));
        try std.testing.expectEqual(case.bits, @as(u16, @bitCast(through_f32)));
    }
}

test "generic cfg selector admits only nonrecursive integer-to-half composition" {
    const admitted =
        \\define half @wide_to_half(i128 %x) {
        \\entry:
        \\  %r = sitofp i128 %x to half
        \\  ret half %r
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, admitted);
    defer module.deinit();
    try module.verify();
    var machine = x86_64_machine.MachineFunction.init("wide_to_half", .half);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    var trunc_calls: usize = 0;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .direct_call => |call| {
            if (std.mem.eql(u8, call.symbol, "__truncsfhf2")) trunc_calls += 1;
        },
        else => {},
    };
    try std.testing.expectEqual(@as(usize, 1), trunc_calls);

    const recursive =
        \\define half @__truncsfhf2(i32 %x) {
        \\entry:
        \\  %r = sitofp i32 %x to half
        \\  ret half %r
        \\}
        \\
    ;
    var recursive_module = try ir.Module.parse(std.testing.allocator, recursive);
    defer recursive_module.deinit();
    try recursive_module.verify();
    var recursive_machine = x86_64_machine.MachineFunction.init("__truncsfhf2", .half);
    defer recursive_machine.deinit(std.testing.allocator);
    const selection = try selector_impl.tryLowerComposedCfg(std.testing.allocator, &recursive_machine, recursive_module.functions.items[0]);
    try std.testing.expect(selection == .unsupported);
    try std.testing.expectEqualStrings("composed-int-fp-half-recursive", selection.unsupported.detail());
}

test "readonly wide loads keep provenance widths and stores fail closed" {
    const Case = struct { ir_text: []const u8, detail: []const u8 };
    const cases = [_]Case{
        .{ .ir_text =
        \\define float @bad(ptr %p) {
        \\entry:
        \\  %x = load i96, ptr %p, align 4
        \\  %r = uitofp i96 %x to float
        \\  ret float %r
        \\}
        , .detail = "composed-block-load-width" },
        .{ .ir_text =
        \\define float @bad(ptr readonly %p) {
        \\entry:
        \\  %x = load i80, ptr %p, align 4
        \\  %r = uitofp i80 %x to float
        \\  ret float %r
        \\}
        , .detail = "composed-block-load-width" },
        .{ .ir_text =
        \\define void @bad(ptr readonly %p, i32 %x) {
        \\entry:
        \\  store i32 %x, ptr %p, align 4
        \\  ret void
        \\}
        , .detail = "composed-block-store-readonly-param" },
    };
    for (cases) |case| {
        var module = try ir.Module.parse(std.testing.allocator, case.ir_text);
        defer module.deinit();
        try module.verify();
        var machine = x86_64_machine.MachineFunction.init("bad", module.functions.items[0].ret_ty);
        defer machine.deinit(std.testing.allocator);
        const selection = try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]);
        try std.testing.expect(selection == .unsupported);
        try std.testing.expectEqualStrings(case.detail, selection.unsupported.detail());
    }
}

test "generic cfg selector keeps unsupported integer to FP shapes fail closed" {
    const Case = struct { ir_text: []const u8, tag: std.meta.Tag(inspection.Diagnostic), detail: []const u8 };
    const cases = [_]Case{
        .{ .ir_text =
        \\define double @bad(i7 %x) {
        \\entry:
        \\  %r = sitofp i7 %x to double
        \\  ret double %r
        \\}
        , .tag = .unsupported_instruction, .detail = "sitofp" },
        .{ .ir_text =
        \\define double @bad(i65 %x) {
        \\entry:
        \\  %r = uitofp i65 %x to double
        \\  ret double %r
        \\}
        , .tag = .unsupported_instruction, .detail = "uitofp" },
        .{ .ir_text =
        \\define float @bad(i95 %x) {
        \\entry:
        \\  %r = sitofp i95 %x to float
        \\  ret float %r
        \\}
        , .tag = .unsupported_instruction, .detail = "sitofp" },
        .{ .ir_text =
        \\define half @bad(i12 %x) {
        \\entry:
        \\  %r = sitofp i12 %x to half
        \\  ret half %r
        \\}
        , .tag = .unsupported_instruction, .detail = "sitofp" },
    };

    for (cases) |case| {
        var module = try ir.Module.parse(std.testing.allocator, case.ir_text);
        defer module.deinit();
        try module.verify();
        const result = inspection.inspectFunction(module.functions.items[0]);
        try std.testing.expect(result == .unsupported);
        try std.testing.expectEqual(case.tag, std.meta.activeTag(result.unsupported));
        try std.testing.expectEqualStrings(case.detail, result.unsupported.detail());
    }
}

test "generic cfg selector executes scalar FP to signed i32 conversions exactly" {
    const input =
        \\define i32 @convert(float %f, double %d) {
        \\entry:
        \\  %fi = fptosi float %f to i32
        \\  %di = fptosi double %d to i32
        \\  %sum = add i32 %fi, %di
        \\  ret i32 %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = x86_64_machine.MachineFunction.init("convert", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    switch (try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0])) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("FP-to-i32 diagnostic={s}\n", .{diagnostic.detail()});
            return error.TestUnexpectedResult;
        },
    }
    try x86_64_verify.verifyFunction(machine);

    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const convert: *const fn (f32, f64) callconv(.c) i32 = @ptrCast(mapping.ptr);

    const Case = struct { f: f32, d: f64, expected: i32 };
    const cases = [_]Case{
        .{ .f = 0.0, .d = -0.0, .expected = 0 },
        .{ .f = 0.999, .d = -0.999, .expected = 0 },
        .{ .f = 1.999, .d = -1.999, .expected = 0 },
        .{ .f = 2147483520.0, .d = 0.0, .expected = 2147483520 },
        .{ .f = 0.0, .d = 2147483647.0, .expected = 2147483647 },
        .{ .f = -2147483648.0, .d = 0.0, .expected = -2147483648 },
        .{ .f = 0.0, .d = -2147483648.0, .expected = -2147483648 },
        .{ .f = @bitCast(@as(u32, 1)), .d = @bitCast(@as(u64, 0x8000_0000_0000_0001)), .expected = 0 },
    };
    for (cases) |case| {
        try std.testing.expectEqual(case.expected, convert(case.f, case.d));
    }
}

test "generic cfg selector keeps unadmitted FP to integer conversions fail closed" {
    const Case = struct { ir_text: []const u8, detail: []const u8 };
    const cases = [_]Case{
        .{ .ir_text =
        \\define i32 @bad(float %x) {
        \\entry:
        \\  %r = fptoui float %x to i32
        \\  ret i32 %r
        \\}
        , .detail = "fptoui" },
        .{ .ir_text =
        \\define i64 @bad(double %x) {
        \\entry:
        \\  %r = fptosi double %x to i64
        \\  ret i64 %r
        \\}
        , .detail = "fptosi" },
        .{ .ir_text =
        \\define i32 @bad(half %x) {
        \\entry:
        \\  %r = fptosi half %x to i32
        \\  ret i32 %r
        \\}
        , .detail = "fptosi" },
    };

    for (cases) |case| {
        var module = try ir.Module.parse(std.testing.allocator, case.ir_text);
        defer module.deinit();
        try module.verify();
        const result = inspection.inspectFunction(module.functions.items[0]);
        try std.testing.expect(result == .unsupported);
        try std.testing.expectEqual(inspection.Diagnostic.unsupported_instruction, std.meta.activeTag(result.unsupported));
        try std.testing.expectEqualStrings(case.detail, result.unsupported.detail());
    }
}
