const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");
fn fixSf(x: f32) callconv(.c) i128 {
    return @intFromFloat(x);
}
fn fixUnsSf(x: f32) callconv(.c) u128 {
    return @intFromFloat(x);
}
fn fixDf(x: f64) callconv(.c) i128 {
    return @intFromFloat(x);
}
fn fixUnsDf(x: f64) callconv(.c) u128 {
    return @intFromFloat(x);
}
fn fixTf(x: f128) callconv(.c) i128 {
    return @intFromFloat(x);
}
fn fixUnsTf(x: f128) callconv(.c) u128 {
    return @intFromFloat(x);
}
fn fixTf32(x: f128) callconv(.c) i32 {
    return @intFromFloat(x);
}
fn fixUnsTf32(x: f128) callconv(.c) u32 {
    return @intFromFloat(x);
}
fn fixTf64(x: f128) callconv(.c) i64 {
    return @intFromFloat(x);
}
fn fixUnsTf64(x: f128) callconv(.c) u64 {
    return @intFromFloat(x);
}
fn extendHalf(x: f16) callconv(.c) f32 {
    return x;
}

fn executable(source: []const u8) ![]align(std.heap.page_size_min) u8 {
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    var output = machine.MachineFunction.init("convert", module.functions.items[0].ret_ty);
    defer output.deinit(std.testing.allocator);
    const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    const selected = try selector.tryLowerWithContext(std.testing.allocator, &output, module.functions.items[0], &context);
    if (selected == .unsupported) std.debug.print("scalar integer conversion: {s}\n", .{selected.unsupported.detail()});
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try verify.verifyFunction(output);
    const providers = [_]struct { symbol: []const u8, address: usize }{
        .{ .symbol = "__fixsfti", .address = @intFromPtr(&fixSf) },          .{ .symbol = "__fixunssfti", .address = @intFromPtr(&fixUnsSf) },
        .{ .symbol = "__fixdfti", .address = @intFromPtr(&fixDf) },          .{ .symbol = "__fixunsdfti", .address = @intFromPtr(&fixUnsDf) },
        .{ .symbol = "__fixtfti", .address = @intFromPtr(&fixTf) },          .{ .symbol = "__fixunstfti", .address = @intFromPtr(&fixUnsTf) },
        .{ .symbol = "__fixtfsi", .address = @intFromPtr(&fixTf32) },        .{ .symbol = "__fixunstfsi", .address = @intFromPtr(&fixUnsTf32) },
        .{ .symbol = "__fixtfdi", .address = @intFromPtr(&fixTf64) },        .{ .symbol = "__fixunstfdi", .address = @intFromPtr(&fixUnsTf64) },
        .{ .symbol = "__extendhfsf2", .address = @intFromPtr(&extendHalf) },
    };
    const bytes = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(bytes);
    const code = try std.posix.mmap(null, bytes.len + providers.len * 12, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    errdefer std.posix.munmap(code);
    @memcpy(code[0..bytes.len], bytes);
    for (providers, 0..) |provider, index| {
        const stub = code[bytes.len + 12 * index ..][0..12];
        stub[0] = 0x48;
        stub[1] = 0xb8;
        std.mem.writeInt(u64, stub[2..10], provider.address, .little);
        stub[10] = 0xff;
        stub[11] = 0xe0;
    }
    var offset: usize = 0;
    for (output.instructions.items) |instruction| {
        if (instruction == .direct_call) {
            const index = for (providers, 0..) |provider, index| {
                if (std.mem.eql(u8, provider.symbol, instruction.direct_call.symbol)) break index;
            } else return error.UnexpectedConversionHelper;
            const relative: i32 = @intCast(bytes.len + 12 * index - offset - 5);
            std.mem.writeInt(i32, code[offset + 1 ..][0..4], relative, .little);
        }
        offset += encoding.instructionSize(instruction);
    }
    return code;
}

test "scalar integer conversion bridges execute every logical width and floating source" {
    for ([_][]const u8{ "half", "float", "double", "fp128" }) |ty| for ([_]u16{ 1, 8, 16, 32, 52, 64, 65, 80, 113, 127, 128 }) |bits| for ([_]bool{ false, true }) |signed| {
        const finish = if (bits == 128) " %wide = add i128 %converted,0\n" else try std.fmt.allocPrint(std.testing.allocator, " %wide = zext i{d} %converted to i128\n", .{bits});
        defer if (bits != 128) std.testing.allocator.free(finish);
        const source = try std.fmt.allocPrint(std.testing.allocator, "target datalayout = \"e-i128:128\"\ndefine i128 @convert(ptr %input) {{\nentry:\n %value = load {s},ptr %input,align 1\n %converted = {s} {s} %value to i{d}\n{s} ret i128 %wide\n}}\n", .{ ty, if (signed) "fptosi" else "fptoui", ty, bits, finish });
        defer std.testing.allocator.free(source);
        const code = try executable(source);
        defer std.posix.munmap(code);
        const run: *const fn (*const u8) callconv(.c) u128 = @ptrCast(code.ptr);
        const sample: f64 = if (bits == 1) (if (signed) -0.75 else 1.75) else if (signed) -37.75 else 37.75;
        var raw: [16]u8 = @splat(0);
        if (std.mem.eql(u8, ty, "half")) std.mem.writeInt(u16, raw[0..2], @bitCast(@as(f16, @floatCast(sample))), .little) else if (std.mem.eql(u8, ty, "float")) std.mem.writeInt(u32, raw[0..4], @bitCast(@as(f32, @floatCast(sample))), .little) else if (std.mem.eql(u8, ty, "double")) std.mem.writeInt(u64, raw[0..8], @bitCast(sample), .little) else std.mem.writeInt(u128, &raw, @bitCast(@as(f128, sample)), .little);
        const expected: u128 = @bitCast(@as(i128, @intFromFloat(sample)));
        const mask = if (bits == 128) std.math.maxInt(u128) else (@as(u128, 1) << @as(u7, @intCast(bits))) - 1;
        try std.testing.expectEqual(expected & mask, run(&raw[0]));
    };
}

test "scalar integer conversion helpers never outline their own canonical symbol" {
    for ([_][]const u8{ "__fixsfti", "\"\\5F_fixsfti\"" }) |name| {
        const source = try std.fmt.allocPrint(std.testing.allocator, "define i128 @{s}(float %value) {{\nentry:\n %converted = fptosi float %value to i128\n ret i128 %converted\n}}\n", .{name});
        defer std.testing.allocator.free(source);
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try @import("scalar_integer_conversions.zig").legalize(arena.allocator(), module.functions.items[0])) == null);
    }
}
