const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const impl = @import("composed_selector_impl.zig");
const selector_calls = @import("composed_selector_calls.zig");
const selector_state = @import("composed_selector_state.zig");
const selector_scalar = @import("composed_selector_scalar.zig");
const selector_cfg = @import("composed_selector_cfg.zig");
const selector_frame = @import("composed_selector_frame.zig");
const selector_memory = @import("composed_selector_memory.zig");

const MachineFunction = impl.MachineFunction;
const ComposedBlockSelector = impl.ComposedBlockSelector;
const ValueLoc = selector_types.ValueLoc;
const VirtualRegMetadata = selector_types.VirtualRegMetadata;
const pair_a = selector_types.pair_a;
const pair_b = selector_types.pair_b;
const PlannedValueAssignment = stage2_planning.PlannedValueAssignment;
const SelectorAllocationPlan = stage2_planning.SelectorAllocationPlan;
const SelectorValueInterval = stage2_planning.SelectorValueInterval;
const SpillSlotAssignment = stage2_planning.SpillSlotAssignment;
const allocateSelectorIntervals = stage2_planning.allocateSelectorIntervals;
const stage2SpillReservedBytes = stage2_planning.stage2SpillReservedBytes;

test "generic cfg selector lowers lifetime markers as checked no-ops" {
    var machine = MachineFunction.init("lifetime-markers", .void);
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "slot", .{ .stack_scalar = .{ .base_disp = 0, .bits = 8 } });

    inline for (.{ "llvm.lifetime.start.p0", "llvm.lifetime.end.p0" }) |callee| {
        var call = ir.CallInst{
            .ret_ty = .void,
            .callee = callee,
            .args = .empty,
        };
        defer call.deinit(std.testing.allocator);
        try call.args.append(std.testing.allocator, .{ .ty = .ptr, .value = .{ .named = "slot" } });
        try std.testing.expect((try impl.lowerInstruction(&selector, .{ .result = null, .kind = .{ .call = call } })) == null);
    }

    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "generic cfg selector lowers i16 count-leading-zeros" {
    inline for (.{ 0, 1 }) |zero_is_poison| {
        var machine = MachineFunction.init("ctlz-i16", .{ .int = 16 });
        defer machine.deinit(std.testing.allocator);

        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "value", .{ .arg32 = .rsi });

        var call = ir.CallInst{
            .ret_ty = .{ .int = 16 },
            .callee = "llvm.ctlz.i16",
            .tail_kind = "tail",
            .args = .empty,
        };
        defer call.deinit(std.testing.allocator);
        try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 16 }, .value = .{ .named = "value" } });
        try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 1 }, .value = .{ .int = zero_is_poison } });

        try std.testing.expect((try selector_calls.lowerCtlzI16(&selector, "count", call)) == null);
        try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "count").?);
        try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
            .{ .mov_arg_eax = .rsi },
            .{ .and_eax_imm32 = 0xffff },
            .{ .mov_eax_to_arg = .rdi },
            .clz_i32_edi_eax,
            .{ .add_eax_imm32 = -16 },
        }, machine.instructions.items);
    }
}

test "composed selector stages swapped scalar SSE call arguments" {
    const input =
        \\declare float @callee(float, float)
        \\define float @caller(float %a, float %b) {
        \\entry:
        \\  %result = call float @callee(float %b, float %a)
        \\  ret float %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = MachineFunction.init("caller", .float);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));

    var spilled_xmm0 = false;
    var spilled_xmm1 = false;
    var reloaded_xmm0 = false;
    var reloaded_xmm1 = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .spill_xmm32_rsp => |spill| {
            spilled_xmm0 = spilled_xmm0 or spill.reg == .xmm0;
            spilled_xmm1 = spilled_xmm1 or spill.reg == .xmm1;
        },
        .reload_xmm32_rsp => |reload| {
            reloaded_xmm0 = reloaded_xmm0 or reload.reg == .xmm0;
            reloaded_xmm1 = reloaded_xmm1 or reload.reg == .xmm1;
        },
        else => {},
    };
    try std.testing.expect(spilled_xmm0 and spilled_xmm1 and reloaded_xmm0 and reloaded_xmm1);
    try x86_64_verify.verifyFunction(machine);
}

test "composed selector numbers mixed GPR and SSE call arguments independently" {
    const input =
        \\declare double @callee(i32, double, i64, float)
        \\define double @caller(i32 %a, float %x, i64 %b, double %y) {
        \\entry:
        \\  %result = call double @callee(i32 %a, double %y, i64 %b, float %x)
        \\  ret double %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = MachineFunction.init("caller", .double);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));

    var reloaded_xmm0 = false;
    var reloaded_xmm1 = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .reload_xmm64_rsp => |reload| reloaded_xmm0 = reloaded_xmm0 or reload.reg == .xmm0,
        .reload_xmm32_rsp => |reload| reloaded_xmm1 = reloaded_xmm1 or reload.reg == .xmm1,
        else => {},
    };
    try std.testing.expect(reloaded_xmm0 and reloaded_xmm1);
    try x86_64_verify.verifyFunction(machine);
}

test "composed selector preserves a live XMM value across a direct call" {
    const input =
        \\declare float @callee(float)
        \\define float @caller(float %a, float %b, float %c) {
        \\entry:
        \\  %sum = fadd float %a, %b
        \\  %called = call float @callee(float %c)
        \\  %result = fadd float %sum, %called
        \\  ret float %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = MachineFunction.init("caller", .float);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));

    var call_index: ?usize = null;
    var spill_before_call = false;
    var reload_after_call = false;
    for (machine.instructions.items, 0..) |instruction, index| switch (instruction) {
        .direct_call => call_index = index,
        .spill_xmm32_rsp => if (call_index == null) {
            spill_before_call = true;
        },
        .reload_xmm32_rsp => if (call_index) |at| {
            if (index > at) reload_after_call = true;
        },
        else => {},
    };
    try std.testing.expect(call_index != null and spill_before_call and reload_after_call);
    try x86_64_verify.verifyFunction(machine);
}

test "composed selector binds half float and double direct call results in XMM0" {
    const input =
        \\declare half @half_callee(half)
        \\declare float @float_callee(float)
        \\declare double @double_callee(double)
        \\define half @half_caller(half %value) {
        \\entry:
        \\  %result = call half @half_callee(half %value)
        \\  ret half %result
        \\}
        \\define float @float_caller(float %value) {
        \\entry:
        \\  %result = call float @float_callee(float %value)
        \\  ret float %result
        \\}
        \\define double @double_caller(double %value) {
        \\entry:
        \\  %result = call double @double_callee(double %value)
        \\  ret double %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    for (module.functions.items) |function| {
        var machine = MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function));
        try x86_64_verify.verifyFunction(machine);
    }
}

test "composed selector lowers tail and notail calls ordinarily and rejects musttail" {
    const input =
        \\declare float @callee(float)
        \\define float @tail_caller(float %value) {
        \\entry:
        \\  %result = tail call float @callee(float %value)
        \\  ret float %result
        \\}
        \\define float @notail_caller(float %value) {
        \\entry:
        \\  %result = notail call float @callee(float %value)
        \\  ret float %result
        \\}
        \\define float @musttail_caller(float %value) {
        \\entry:
        \\  %result = musttail call float @callee(float %value)
        \\  ret float %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    for (module.functions.items[0..2]) |function| {
        var machine = MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function));
        var saw_call = false;
        for (machine.instructions.items) |instruction| switch (instruction) {
            .direct_call => saw_call = true,
            .direct_jump => return error.UnexpectedTailJump,
            else => {},
        };
        try std.testing.expect(saw_call);
    }
    var musttail_machine = MachineFunction.init("musttail_caller", .float);
    defer musttail_machine.deinit(std.testing.allocator);
    try std.testing.expectError(error.UnsupportedTailCallAbi, impl.tryLowerComposedCfg(std.testing.allocator, &musttail_machine, module.functions.items[2]));
}

test "machine verifier assigns direct call results to their ABI register class" {
    var fp_machine = MachineFunction.init("fp", .float);
    defer fp_machine.deinit(std.testing.allocator);
    try fp_machine.instructions.appendSlice(std.testing.allocator, &.{
        .sub_rsp_8,
        .{ .direct_call = .{ .symbol = "callee", .ret_ty = .float } },
        .add_rsp_8,
        .ret,
    });
    try x86_64_verify.verifyFunction(fp_machine);

    var integer_machine = MachineFunction.init("integer", .{ .int = 32 });
    defer integer_machine.deinit(std.testing.allocator);
    try integer_machine.instructions.appendSlice(std.testing.allocator, &.{
        .sub_rsp_8,
        .{ .direct_call = .{ .symbol = "callee", .ret_ty = .float } },
        .add_rsp_8,
        .ret,
    });
    try std.testing.expectError(error.ReturnRegisterUndefined, x86_64_verify.verifyFunction(integer_machine));
}
