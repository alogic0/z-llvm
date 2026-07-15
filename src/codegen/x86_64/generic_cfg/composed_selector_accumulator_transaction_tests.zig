const std = @import("std");
const machine_module = @import("../machine.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const state = @import("composed_selector_state.zig");

const AccumulatorDefinition = state.AccumulatorDefinition;
const AccumulatorDefinitionTransaction = state.AccumulatorDefinitionTransaction;
const ComposedBlockSelector = state.ComposedBlockSelector;
const MachineFunction = machine_module.MachineFunction;
const SelectorAllocationPlan = stage2_planning.SelectorAllocationPlan;
const ValueBinding = selector_types.ValueBinding;
const ValueLoc = selector_types.ValueLoc;

fn accumulatorBindingCount(selector: *const ComposedBlockSelector) usize {
    var count: usize = 0;
    var it = selector.values.iterator();
    while (it.next()) |entry| switch (entry.value_ptr.loc) {
        .eax, .rax => count += 1,
        else => {},
    };
    return count;
}

test "accumulator transaction commits 8 16 32 and 64 bit definitions in one alias domain" {
    const definitions = [_]AccumulatorDefinition{
        .zeroExtending(8),
        .zeroExtending(16),
        .zeroExtending(32),
        .fullRax(),
    };
    const names = [_][]const u8{ "v8", "v16", "v32", "v64" };

    for (definitions, names) |definition, name| {
        var machine = MachineFunction.init(name, .{ .int = definition.logical_bits });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();

        var transaction = try AccumulatorDefinitionTransaction.begin(&selector);
        try transaction.prepare(.preserve);
        try transaction.define(name, definition);
        try transaction.commit();
        transaction.deinit();

        const binding = selector.values.get(name).?;
        try std.testing.expectEqual(definition.logical_bits, binding.vreg.bits);
        try std.testing.expectEqual(
            if (definition.logical_bits == 64) std.meta.Tag(ValueLoc).rax else std.meta.Tag(ValueLoc).eax,
            std.meta.activeTag(binding.loc),
        );
        try std.testing.expectEqual(@as(u16, 64), selector.accumulator_domain.defined_bits);
        try std.testing.expectEqual(@as(usize, 1), accumulatorBindingCount(&selector));

        const eax_occupant = selector.accumulator_domain.occupantFor(.eax).?;
        const rax_occupant = selector.accumulator_domain.occupantFor(.rax).?;
        try std.testing.expectEqual(eax_occupant, rax_occupant);
        try std.testing.expectEqual(binding, eax_occupant.binding);
        try std.testing.expectEqual(definition.logical_bits, eax_occupant.logical_bits);
    }
}

test "accumulator transaction updates and invalidates EAX RAX aliases atomically" {
    var machine = MachineFunction.init("alias-domain", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    var first = try AccumulatorDefinitionTransaction.begin(&selector);
    try first.prepare(.preserve);
    try first.define("old", .zeroExtending(32));
    try first.commit();
    first.deinit();

    const old_binding = selector.values.get("old").?;
    try std.testing.expectEqual(old_binding, selector.accumulator_domain.occupantFor(.eax).?.binding);
    try std.testing.expectEqual(old_binding, selector.accumulator_domain.occupantFor(.rax).?.binding);

    var second = try AccumulatorDefinitionTransaction.begin(&selector);
    defer second.deinit();
    try second.prepare(.preserve);
    try std.testing.expect(selector.values.get("old") == null);
    try std.testing.expect(selector.accumulator_domain.occupantFor(.eax) == null);
    try std.testing.expect(selector.accumulator_domain.occupantFor(.rax) == null);
    try std.testing.expectEqual(@as(u16, 0), selector.accumulator_domain.defined_bits);
    try std.testing.expectEqual(@as(usize, 0), accumulatorBindingCount(&selector));

    try second.rollback();
    try std.testing.expectEqual(old_binding, selector.values.get("old").?);
    try std.testing.expectEqual(old_binding, selector.accumulator_domain.occupantFor(.eax).?.binding);
    try std.testing.expectEqual(old_binding, selector.accumulator_domain.occupantFor(.rax).?.binding);
    try std.testing.expectEqual(@as(u16, 64), selector.accumulator_domain.defined_bits);
}

test "accumulator transaction lifecycle rejects invalid and stale-upper-bit operations" {
    var machine = MachineFunction.init("transaction-errors", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    var transaction = try AccumulatorDefinitionTransaction.begin(&selector);
    defer transaction.deinit();
    try std.testing.expectError(
        error.AccumulatorTransactionNotPrepared,
        transaction.define("value", .zeroExtending(32)),
    );
    try std.testing.expectError(error.AccumulatorCommitWithoutDefinition, transaction.commit());
    try transaction.prepare(.preserve);
    try std.testing.expectError(error.AccumulatorCommitWithoutDefinition, transaction.commit());
    try transaction.define("value", .zeroExtending(32));
    try std.testing.expectError(
        error.AccumulatorAlreadyDefined,
        transaction.define("second", .zeroExtending(32)),
    );
    try transaction.rollback();
    try std.testing.expectError(error.AccumulatorTransactionClosed, transaction.prepare(.preserve));
    try std.testing.expectError(
        error.AccumulatorTransactionClosed,
        transaction.define("after-rollback", .zeroExtending(32)),
    );
    try std.testing.expectError(error.AccumulatorTransactionClosed, transaction.commit());

    var stale = try AccumulatorDefinitionTransaction.begin(&selector);
    defer stale.deinit();
    try stale.prepare(.preserve);
    const next_virtual_reg = selector.next_virtual_reg;
    try std.testing.expectError(
        error.AccumulatorStaleUpperBits,
        stale.define("stale", .preserving(16)),
    );
    try std.testing.expectEqual(next_virtual_reg, selector.next_virtual_reg);
    try std.testing.expect(selector.accumulator_domain.occupantFor(.eax) == null);
    try std.testing.expect(selector.accumulator_domain.occupantFor(.rax) == null);
    try stale.rollback();
}

test "accumulator transaction rollback restores instructions bindings bits spills vregs and EFLAGS" {
    var machine = MachineFunction.init("transaction-rollback", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("old", 3);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    selector.stack_frame_bytes = 24;

    var initial = try AccumulatorDefinitionTransaction.begin(&selector);
    try initial.prepare(.preserve);
    try initial.define("old", .zeroExtending(32));
    try initial.commit();
    initial.deinit();
    try state.bindValueLoc(&selector, "other", .{ .scratch64 = .r9 });
    try selector.spill_slots.put("seed-spill", .{ .base = 0, .slots = 1 });
    selector.next_spill_slot = 1;
    try machine.instructions.append(std.testing.allocator, .{ .mov_imm_eax = 13 });
    try selector.eflags.apply(.definition);

    const old_binding = selector.values.get("old").?;
    const other_binding = selector.values.get("other").?;
    const saved_domain = selector.accumulator_domain;
    const saved_eflags = selector.eflags.snapshot();
    const saved_next_virtual_reg = selector.next_virtual_reg;
    const saved_next_spill_slot = selector.next_spill_slot;
    const saved_instructions = [_]machine_module.Instruction{.{ .mov_imm_eax = 13 }};

    var transaction = try AccumulatorDefinitionTransaction.begin(&selector);
    defer transaction.deinit();
    try transaction.prepare(.preserve);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot2 }, selector.values.get("old").?.loc);
    try std.testing.expectEqual(@as(usize, 2), selector.spill_slots.count());
    try transaction.spill("old");
    try transaction.materialize(.{ .scratch32 = .r8 }, .zeroExtending(32));
    try transaction.define("new", .zeroExtending(32));
    try std.testing.expect(selector.next_virtual_reg != saved_next_virtual_reg);

    try transaction.rollback();
    try std.testing.expectEqualSlices(machine_module.Instruction, &saved_instructions, machine.instructions.items);
    try std.testing.expectEqual(@as(usize, 2), selector.values.count());
    try std.testing.expectEqual(old_binding, selector.values.get("old").?);
    try std.testing.expectEqual(other_binding, selector.values.get("other").?);
    try std.testing.expect(selector.values.get("new") == null);
    try std.testing.expectEqual(@as(usize, 1), selector.spill_slots.count());
    try std.testing.expectEqual(
        stage2_planning.SpillSlotAssignment{ .base = 0, .slots = 1 },
        selector.spill_slots.get("seed-spill").?,
    );
    try std.testing.expect(selector.spill_slots.get("old") == null);
    try std.testing.expectEqual(saved_next_virtual_reg, selector.next_virtual_reg);
    try std.testing.expectEqual(saved_next_spill_slot, selector.next_spill_slot);
    try std.testing.expectEqual(saved_domain, selector.accumulator_domain);
    try selector.eflags.validateSnapshot(saved_eflags);
}

test "accumulator preparation rejects live-flags clobber before mutation and permits preserve" {
    var machine = MachineFunction.init("transaction-flags", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try state.bindValueLoc(&selector, "kept", .{ .scratch64 = .rcx });
    try machine.instructions.append(std.testing.allocator, .{ .mov_imm_eax = 9 });
    try selector.eflags.apply(.definition);

    const kept_binding = selector.values.get("kept").?;
    const saved_eflags = selector.eflags.snapshot();
    const saved_next_virtual_reg = selector.next_virtual_reg;
    const saved_instruction_len = machine.instructions.items.len;

    var rejected = try AccumulatorDefinitionTransaction.begin(&selector);
    defer rejected.deinit();
    try std.testing.expectError(error.EflagsClobberedWhileLive, rejected.prepare(.clobber));
    try std.testing.expectEqual(kept_binding, selector.values.get("kept").?);
    try std.testing.expectEqual(saved_next_virtual_reg, selector.next_virtual_reg);
    try std.testing.expectEqual(saved_instruction_len, machine.instructions.items.len);
    try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
    try std.testing.expectEqual(@as(usize, 0), accumulatorBindingCount(&selector));
    try selector.eflags.validateSnapshot(saved_eflags);
    try rejected.rollback();

    var preserved = try AccumulatorDefinitionTransaction.begin(&selector);
    defer preserved.deinit();
    try preserved.prepare(.preserve);
    try preserved.define("result", .zeroExtending(32));
    try preserved.commit();
    try selector.eflags.validateSnapshot(saved_eflags);
    try std.testing.expectEqual(@as(u16, 64), selector.accumulator_domain.defined_bits);
}
