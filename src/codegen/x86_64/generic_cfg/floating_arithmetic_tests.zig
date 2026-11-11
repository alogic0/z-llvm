const std = @import("std");
const ir = @import("../../../ir.zig");
const machine_module = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");

test "floating storage captures store-only half bits in a larger owned object" {
    const text =
        \\define i64 @store_only(i16 %raw, ptr %output, i64 %keep) {
        \\entry:
        \\ %slab = alloca [32 x i8], align 16
        \\ %at = getelementptr i8, ptr %slab, i64 3
        \\ %value = bitcast i16 %raw to half
        \\ store half %value, ptr %at, align 1
        \\ %loaded = load i16, ptr %at, align 1
        \\ store i16 %loaded, ptr %output, align 1
        \\ %wide = zext i16 %loaded to i64
        \\ %answer = xor i64 %wide, %keep
        \\ ret i64 %answer
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var machine = machine_module.MachineFunction.init("store_only", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    const result = try selector.tryLower(std.testing.allocator, &machine, module.functions.items[0]);
    if (result == .unsupported) std.debug.print("store-only half: {s}\n", .{result.unsupported.detail()});
    try std.testing.expectEqual(selector.SelectionResult.selected, result);
    try verify.verifyFunction(machine);
    try std.testing.expectEqual(ir.Type.half, module.functions.items[0].blocks.items[0].instructions.items[3].kind.store.ty);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(code);
    @memcpy(code[0..bytes.len], bytes);
    const run: *const fn (u16, *u8, u64) callconv(.c) u64 = @ptrCast(code.ptr);
    for (0..65536) |raw| {
        var guarded: [8]u8 = @splat(0xa7);
        const keep: u64 = 0xface0123456789ab ^ raw;
        try std.testing.expectEqual(keep ^ raw, run(@intCast(raw), &guarded[1], keep));
        try std.testing.expectEqual(@as(u16, @intCast(raw)), std.mem.readInt(u16, guarded[1..3], .little));
        try std.testing.expectEqual(@as(u8, 0xa7), guarded[0]);
        for (guarded[3..]) |byte| try std.testing.expectEqual(@as(u8, 0xa7), byte);
    }
}

test "floating storage store-only views reject effects and incompatible strides" {
    const memory = @import("half_memory.zig");
    for ([_][]const u8{ "store volatile half %value,ptr %output,align 2", "store half %value,ptr addrspace(1) %output,align 2", "store atomic half %value,ptr %output unordered,align 2" }) |store| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define void @closed(half %value,ptr %output) {{\nentry:\n {s}\n ret void\n}}\n", .{store});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try memory.legalizeOrdinaryStores(arena.allocator(), module.functions.items[0], null)) == null);
    }
    var module = try ir.Module.parse(std.testing.allocator, "target datalayout = \"e-i16:32\"\ndefine void @closed(half %value,ptr %output) {\nentry:\n store half %value,ptr %output,align 2\n ret void\n}\n");
    defer module.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const context: machine_module.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    try std.testing.expect((try memory.legalizeOrdinaryStores(arena.allocator(), module.functions.items[0], &context)) == null);
}

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
