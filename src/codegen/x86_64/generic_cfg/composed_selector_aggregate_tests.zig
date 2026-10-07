const std = @import("std");
const ir = @import("../../../ir.zig");
const encoding = @import("../../../mc/encoding.zig");
const machine = @import("../machine.zig");
const verify = @import("../verify.zig");
const selector_aggregate = @import("composed_selector_aggregate.zig");
const selector = @import("composed_selector_impl.zig");
const selector_state = @import("composed_selector_state.zig");
const state_data = @import("composed_selector_state_data.zig");

const DoublePair = extern struct {
    first: f64,
    second: f64,
};

const FloatVectorPair = extern struct {
    value: [2]f32,
};

test "generic cfg selector returns exact SSE aggregate leaves" {
    const input =
        \\define { double, double } @double_pair(double %a, double %b) {
        \\entry:
        \\  %first = insertvalue { double, double } poison, double %a, 0
        \\  %pair = insertvalue { double, double } %first, double %b, 1
        \\  ret { double, double } %pair
        \\}
        \\
        \\define { <2 x float> } @float_pair(float %a, float %b) {
        \\entry:
        \\  %lane0 = insertelement <2 x float> poison, float %a, i64 0
        \\  %lanes = insertelement <2 x float> %lane0, float %b, i64 1
        \\  %pair = insertvalue { <2 x float> } poison, <2 x float> %lanes, 0
        \\  ret { <2 x float> } %pair
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var double_machine = machine.MachineFunction.init("double_pair", module.functions.items[0].ret_ty);
    defer double_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLowerComposedCfg(
        std.testing.allocator,
        &double_machine,
        module.functions.items[0],
    ));
    try verify.verifyFunction(double_machine);
    const double_bytes = try encoding.encodeFunction(std.testing.allocator, double_machine);
    defer std.testing.allocator.free(double_bytes);
    const double_mapping = try executableMapping(double_bytes);
    defer std.posix.munmap(double_mapping);
    const double_pair: *const fn (f64, f64) callconv(.c) DoublePair = @ptrCast(double_mapping.ptr);
    const doubles = double_pair(@as(f64, @bitCast(@as(u64, 0x7ff8000000001234))), -0.0);
    try std.testing.expectEqual(@as(u64, 0x7ff8000000001234), @as(u64, @bitCast(doubles.first)));
    try std.testing.expectEqual(@as(u64, 0x8000000000000000), @as(u64, @bitCast(doubles.second)));

    var float_machine = machine.MachineFunction.init("float_pair", module.functions.items[1].ret_ty);
    defer float_machine.deinit(std.testing.allocator);
    const float_selection = try selector.tryLowerComposedCfg(
        std.testing.allocator,
        &float_machine,
        module.functions.items[1],
    );
    try std.testing.expectEqual(selector.SelectionResult.selected, float_selection);
    try verify.verifyFunction(float_machine);
    const float_bytes = try encoding.encodeFunction(std.testing.allocator, float_machine);
    defer std.testing.allocator.free(float_bytes);
    const float_mapping = try executableMapping(float_bytes);
    defer std.posix.munmap(float_mapping);
    const float_pair: *const fn (f32, f32) callconv(.c) FloatVectorPair = @ptrCast(float_mapping.ptr);
    const floats = float_pair(@as(f32, @bitCast(@as(u32, 0x7fa01234))), -0.0).value;
    try std.testing.expectEqual(@as(u32, 0x7fa01234), @as(u32, @bitCast(floats[0])));
    try std.testing.expectEqual(@as(u32, 0x80000000), @as(u32, @bitCast(floats[1])));
}

test "x86_64 verifier rejects incomplete SSE aggregate return registers" {
    var missing_second = machine.MachineFunction.init("missing_second", .{ .aggregate = "{ double, double }" });
    defer missing_second.deinit(std.testing.allocator);
    try missing_second.instructions.appendSlice(std.testing.allocator, &.{
        .{ .mov_imm64_xmm0 = 0 },
        .ret,
    });
    try std.testing.expectError(error.ReturnRegisterUndefined, verify.verifyFunction(missing_second));

    var incomplete_packed = machine.MachineFunction.init("incomplete_packed", .{ .aggregate = "{ <2 x float> }" });
    defer incomplete_packed.deinit(std.testing.allocator);
    try incomplete_packed.instructions.appendSlice(std.testing.allocator, &.{
        .{ .mov_imm32_xmm0 = 0 },
        .ret,
    });
    try std.testing.expectError(error.ReturnRegisterUndefined, verify.verifyFunction(incomplete_packed));
}

test "split SSE aggregate return materialization is alias safe" {
    var function = machine.MachineFunction.init("swapped_pair", .{ .aggregate = "{ double, double }" });
    defer function.deinit(std.testing.allocator);
    var block_selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &function);
    defer block_selector.deinit();

    try selector_state.bindValueLoc(&block_selector, "first", .{ .xmm = .{ .reg = .xmm1, .bits = 64 } });
    try selector_state.bindValueLoc(&block_selector, "second", .{ .xmm = .{ .reg = .xmm0, .bits = 64 } });
    try selector_state.bindValueLoc(&block_selector, "pair", .{ .aggregate_sse = .{
        .split_f64x2 = .{
            .{ .name = "first", .kind = .f64 },
            .{ .name = "second", .kind = .f64 },
        },
    } });

    try selector_aggregate.emitReturn(&block_selector, .{ .named = "pair" }, .split_f64x2);
    try std.testing.expectEqualSlices(machine.Instruction, &.{
        .{ .movapd_xmm = .{ .dst = .xmm2, .src = .xmm1 } },
        .{ .movapd_xmm = .{ .dst = .xmm1, .src = .xmm0 } },
        .{ .movapd_xmm = .{ .dst = .xmm0, .src = .xmm2 } },
    }, function.instructions.items);
}

test "generic cfg selector rejects incomplete and non-whitelisted SSE aggregates" {
    const input =
        \\define { double, double } @incomplete(double %a) {
        \\entry:
        \\  %first = insertvalue { double, double } poison, double %a, 0
        \\  ret { double, double } %first
        \\}
        \\
        \\define { float, float } @not_whitelisted(float %a, float %b) {
        \\entry:
        \\  %first = insertvalue { float, float } poison, float %a, 0
        \\  %pair = insertvalue { float, float } %first, float %b, 1
        \\  ret { float, float } %pair
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    for (module.functions.items) |function| {
        var rejected = machine.MachineFunction.init(function.name, function.ret_ty);
        defer rejected.deinit(std.testing.allocator);
        try std.testing.expect(try selector.tryLowerComposedCfg(std.testing.allocator, &rejected, function) != .selected);
    }
}

fn executableMapping(bytes: []const u8) ![]align(std.heap.page_size_min) u8 {
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(mapping, bytes);
    return mapping;
}
