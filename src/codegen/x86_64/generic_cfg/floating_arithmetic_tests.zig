const std = @import("std");
const ir = @import("../../../ir.zig");
const machine_module = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");

fn extendHalf(value: f16) callconv(.c) f32 {
    return value;
}
fn truncateFloat(value: f32) callconv(.c) f16 {
    return @floatCast(value);
}
fn jump(stub: []u8, target: usize) void {
    stub[0] = 0x48;
    stub[1] = 0xb8;
    std.mem.writeInt(u64, stub[2..10], target, .little);
    stub[10] = 0xff;
    stub[11] = 0xe0;
}

test "floating arithmetic executes half products and quotients in every operand position" {
    const cases = [_]struct { lhs: []const u8, rhs: []const u8, lhs_literal: ?u16 = null, rhs_literal: ?u16 = null, memory: bool = false }{
        .{ .lhs = "%lhs", .rhs = "%rhs" },
        .{ .lhs = "%lhs", .rhs = "0xH70E2", .rhs_literal = 0x70e2 },
        .{ .lhs = "0xH70E2", .rhs = "%rhs", .lhs_literal = 0x70e2 },
        .{ .lhs = "0xH3C01", .rhs = "0xH3C01", .lhs_literal = 0x3c01, .rhs_literal = 0x3c01 },
        .{ .lhs = "%loaded", .rhs = "%rhs", .memory = true },
    };
    for ([_][]const u8{ "fmul", "fdiv" }) |op| for (cases) |case| {
        const text = try std.fmt.allocPrint(
            std.testing.allocator,
            "define half @multiply(half %lhs, half %rhs) {{\nentry:\n{s} %answer = {s} half {s}, {s}\n ret half %answer\n}}\n",
            .{ if (case.memory) " %slot = alloca half, align 2\n store half %lhs, ptr %slot, align 2\n %loaded = load half, ptr %slot, align 2\n" else "", op, case.lhs, case.rhs },
        );
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var machine = machine_module.MachineFunction.init("multiply", .half);
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]));
        try verify.verifyFunction(machine);
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len + 24, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping[0..bytes.len], bytes);
        jump(mapping[bytes.len..][0..12], @intFromPtr(&extendHalf));
        jump(mapping[bytes.len + 12 ..][0..12], @intFromPtr(&truncateFloat));
        var offset: usize = 0;
        for (machine.instructions.items) |instruction| {
            if (instruction == .direct_call) {
                const target = if (std.mem.eql(u8, instruction.direct_call.symbol, "__extendhfsf2")) bytes.len else if (std.mem.eql(u8, instruction.direct_call.symbol, "__truncsfhf2")) bytes.len + 12 else return error.TestUnexpectedHelper;
                const displacement: i32 = @intCast(@intFromPtr(mapping.ptr + target) - (@intFromPtr(mapping.ptr) + offset + 5));
                std.mem.writeInt(i32, mapping[offset + 1 ..][0..4], displacement, .little);
            }
            offset += encoding.instructionSize(instruction);
        }
        const multiply: *const fn (f16, f16) callconv(.c) f16 = @ptrCast(mapping.ptr);
        const inputs = [_]u16{ 0, 1, 0x03ff, 0x0400, 0x3555, 0x3bff, 0x3c00, 0x3c01, 0x4000, 0x70e2, 0x7bff, 0x7c00, 0x7e55, 0x8000, 0xbc00, 0xfc00, 0xffff };
        for (inputs) |a| for (inputs) |b| {
            const lhs: f16 = @bitCast(case.lhs_literal orelse a);
            const rhs: f16 = @bitCast(case.rhs_literal orelse b);
            const expected: f16 = @floatCast(if (std.mem.eql(u8, op, "fmul")) @as(f64, lhs) * @as(f64, rhs) else @as(f64, lhs) / @as(f64, rhs));
            const actual = multiply(@bitCast(a), @bitCast(b));
            if (std.math.isNan(expected)) try std.testing.expect(std.math.isNan(actual)) else try std.testing.expectEqual(@as(u16, @bitCast(expected)), @as(u16, @bitCast(actual)));
        };
    };
}

test "floating arithmetic negates every half representation without quieting NaNs" {
    for ([_]?u16{ null, 0x7d01, 0x8000, 0xffff }) |literal| {
        const operand = if (literal) |raw| try std.fmt.allocPrint(std.testing.allocator, "0xH{X:0>4}", .{raw}) else try std.testing.allocator.dupe(u8, "%value");
        defer std.testing.allocator.free(operand);
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i16 @negate(i16 %raw) {{\nentry:\n %value = bitcast i16 %raw to half\n %negative = fneg half {s}\n %answer = bitcast half %negative to i16\n ret i16 %answer\n}}\n", .{operand});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var machine = machine_module.MachineFunction.init("negate", .{ .int = 16 });
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]));
        try verify.verifyFunction(machine);
        for (machine.instructions.items) |instruction| try std.testing.expect(instruction != .direct_call);
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(code);
        @memcpy(code[0..bytes.len], bytes);
        const negate: *const fn (u16) callconv(.c) u16 = @ptrCast(code.ptr);
        for (0..65536) |raw| try std.testing.expectEqual((literal orelse @as(u16, @intCast(raw))) ^ 0x8000, negate(@intCast(raw)));
    }
}
