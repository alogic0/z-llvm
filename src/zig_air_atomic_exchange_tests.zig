const std = @import("std");
const air_export = @import("zig_air_export.zig");
const ir = @import("ir.zig");

test "typed atomic exchange binds width constants ordering and returned dataflow" {
    const types = @import("zig_air_types.zig");
    const recognize = @import("zig_air_model_typed_recognizers_impl.zig").typedAtomicTryLockSummary;
    var module = try air_export.parse(std.testing.allocator, @embedFile("distribution_execution_breadth/fixtures/mutex_ReleaseFast.air"));
    defer module.deinit();
    var function = module.functions[0];
    const signature = try types.parseFunctionType(std.testing.allocator, function.type_text);
    defer signature.deinit(std.testing.allocator);
    const typed = function.structured_air_v2.?;
    const original = recognize(function, signature, typed).?;
    try std.testing.expectEqual(ir.Type{ .int = 8 }, original.ty);
    try std.testing.expectEqual(ir.Value{ .int = 0 }, original.expected);
    try std.testing.expectEqual(ir.Value{ .int = 1 }, original.replacement);
    function.name = "unrelated.exchange.name";
    try std.testing.expect(recognize(function, signature, typed) != null);
    const exchange_payload = function.instructions[2].payload;
    for ([_][]const u8{
        "%9!, <atomic.Mutex, .unlocked>, <atomic.Mutex, .locked>, acquire, monotonic",
        "%0!, <u32, 0>, <u32, 1>, acquire, monotonic",
        "%0!, <u8, 256>, <u8, 1>, acquire, monotonic",
        "%0!, <unknown.Enum, .unlocked>, <unknown.Enum, .locked>, acquire, monotonic",
        "%0!, <atomic.Mutex, .unlocked>, <atomic.Mutex, .locked>, monotonic, acquire",
        "%0!, <atomic.Mutex, .unlocked>, <atomic.Mutex, .locked>, acquire, release",
        "%0!, <atomic.Mutex, .unlocked>, <atomic.Mutex, .locked>, acquire, monotonic, extra",
    }) |payload| {
        function.instructions[2].payload = payload;
        try std.testing.expect(recognize(function, signature, typed) == null);
    }
    function.instructions[2].payload = exchange_payload;
    function.instructions[5].payload = "%0!";
    try std.testing.expect(recognize(function, signature, typed) == null);
    function.instructions[5].payload = "%3!";
    const old_operand = typed.instructions[3].operands[0];
    @constCast(typed.instructions[3].operands)[0].value = "0";
    try std.testing.expect(recognize(function, signature, typed) == null);
    @constCast(typed.instructions[3].operands)[0] = old_operand;
    // The same semantic proof admits other widths and non-lock constants.
    signature.params[0].pointer_child = .{ .int = 16 };
    @constCast(typed.instructions)[0].result_type = "*u16";
    function.instructions[0].payload = "*u16, 0";
    function.instructions[2].payload = "%0!, <u16, 7>, <u16, 9>, seq_cst, acquire";
    @constCast(typed.instructions[3].operands)[0].type_text = "?u16";
    const generalized = recognize(function, signature, typed).?;
    try std.testing.expectEqual(ir.Type{ .int = 16 }, generalized.ty);
    try std.testing.expectEqual(ir.Value{ .int = 7 }, generalized.expected);
    try std.testing.expectEqual(ir.Value{ .int = 9 }, generalized.replacement);
    try std.testing.expectEqualStrings("seq_cst", generalized.success_ordering);
    try std.testing.expectEqualStrings("acquire", generalized.failure_ordering);
}
