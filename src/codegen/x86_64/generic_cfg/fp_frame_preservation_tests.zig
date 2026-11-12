const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const encoding = @import("../../../mc/encoding.zig");
test "scalar floating writes reserve homes for live inputs below register pressure" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define float @probe(double %x) {
        \\entry:
        \\ %square = fmul double %x, %x
        \\ %fourth = fmul double %square, %square
        \\ %first = fadd double %x, %fourth
        \\ %sum = fadd double %first, %square
        \\ %answer = fptrunc double %sum to float
        \\ ret float %answer
        \\}
    );
    defer module.deinit();
    try module.verify();
    var plan = try @import("stage2_planning.zig").buildSelectorAllocationPlan(std.testing.allocator, module.functions.items[0]);
    defer plan.deinit();
    try std.testing.expectEqual(@as(usize, 0), plan.spill_slots);
    try std.testing.expect(plan.preservation_spill_slots != 0);
    var output = machine.MachineFunction.init("probe", .float);
    defer output.deinit(std.testing.allocator);
    const selected = try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]);
    if (selected == .unsupported) std.debug.print("FP frame: {s}\n", .{selected.unsupported.detail()});
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try @import("../verify.zig").verifyFunction(output);
    const code = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(code);
    const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(memory);
    @memcpy(memory[0..code.len], code);
    const run: *const fn (f64) callconv(.c) f32 = @ptrCast(memory.ptr);
    for (0..65) |index| {
        const input = (@as(f64, @floatFromInt(index)) - 32.0) / 8.0;
        const square = input * input;
        const expected: f32 = @floatCast((input + square * square) + square);
        try std.testing.expectEqual(@as(u32, @bitCast(expected)), @as(u32, @bitCast(run(input))));
    }
}
