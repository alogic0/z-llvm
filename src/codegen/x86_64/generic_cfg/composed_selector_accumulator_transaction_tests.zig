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

test "accumulator transaction separates logical widths from physical EAX RAX binding widths" {
    const definitions = [_]AccumulatorDefinition{
        .zeroExtending(1),
        .zeroExtending(6),
        .zeroExtending(8),
        .zeroExtending(16),
        .zeroExtending(32),
        .zeroExtendedRax(52),
        .zeroExtendedRax(56),
        .fullRax(),
    };
    const names = [_][]const u8{ "v1", "v6", "v8", "v16", "v32", "v52", "v56", "v64" };

    for (definitions, names) |definition, name| {
        var machine = MachineFunction.init(name, .{ .int = definition.logical_bits });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();

        var transaction = try AccumulatorDefinitionTransaction.begin(&selector);
        _ = try transaction.prepare(.preserve, .spill_live);
        try transaction.define(name, definition);
        try transaction.commit();
        transaction.deinit();

        const binding = selector.values.get(name).?;
        try std.testing.expectEqual(definition.bindingBits(), binding.vreg.bits);
        try std.testing.expectEqual(
            if (definition.bindingBits() == 64) std.meta.Tag(ValueLoc).rax else std.meta.Tag(ValueLoc).eax,
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
    _ = try first.prepare(.preserve, .spill_live);
    try first.define("old", .zeroExtending(32));
    try first.commit();
    first.deinit();

    const old_binding = selector.values.get("old").?;
    try std.testing.expectEqual(old_binding, selector.accumulator_domain.occupantFor(.eax).?.binding);
    try std.testing.expectEqual(old_binding, selector.accumulator_domain.occupantFor(.rax).?.binding);

    var second = try AccumulatorDefinitionTransaction.begin(&selector);
    defer second.deinit();
    _ = try second.prepare(.preserve, .spill_live);
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

test "accumulator transaction uses physical binding width for planned scratch and spill materialization" {
    var machine = MachineFunction.init("physical-binding-plans", .{ .int = 56 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.assignments.put("scratch", .{ .gpr64 = .r8 });
    try plan.assignments.put("spilled", .{ .spill = 0 });
    try plan.forward_values.put("scratch", .{
        .definition_position = 0,
        .metadata = .{ .class = .gpr64, .bits = 64 },
    });

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 24;

    var scratch = try AccumulatorDefinitionTransaction.begin(&selector);
    _ = try scratch.prepare(.preserve, .spill_live);
    try scratch.define("scratch", .zeroExtendedRax(56));
    try scratch.commit();
    scratch.deinit();
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .r8 }, selector.values.get("scratch").?.loc);
    try std.testing.expectEqual(@as(u16, 64), selector.values.get("scratch").?.vreg.bits);

    var spilled = try AccumulatorDefinitionTransaction.begin(&selector);
    _ = try spilled.prepare(.preserve, .spill_live);
    try spilled.define("spilled", .zeroExtendedRax(52));
    try spilled.commit();
    spilled.deinit();
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector.values.get("spilled").?.loc);
    try std.testing.expectEqual(@as(u16, 64), selector.values.get("spilled").?.vreg.bits);

    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_rax_to_arg = .r8 },
        .{ .spill_rax_rsp = .slot0 },
    }, machine.instructions.items);
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
    _ = try transaction.prepare(.preserve, .spill_live);
    try std.testing.expectError(error.AccumulatorCommitWithoutDefinition, transaction.commit());
    try transaction.define("value", .zeroExtending(32));
    try std.testing.expectError(
        error.AccumulatorAlreadyDefined,
        transaction.define("second", .zeroExtending(32)),
    );
    try transaction.rollback();
    try std.testing.expectError(error.AccumulatorTransactionClosed, transaction.prepare(.preserve, .spill_live));
    try std.testing.expectError(
        error.AccumulatorTransactionClosed,
        transaction.define("after-rollback", .zeroExtending(32)),
    );
    try std.testing.expectError(error.AccumulatorTransactionClosed, transaction.commit());

    var stale = try AccumulatorDefinitionTransaction.begin(&selector);
    defer stale.deinit();
    _ = try stale.prepare(.preserve, .spill_live);
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
    _ = try initial.prepare(.preserve, .spill_live);
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
    const saved_eflags_semantics_len = selector.eflags_semantics.items.len;
    const saved_next_virtual_reg = selector.next_virtual_reg;
    const saved_next_spill_slot = selector.next_spill_slot;
    const saved_instructions = [_]machine_module.Instruction{.{ .mov_imm_eax = 13 }};

    var transaction = try AccumulatorDefinitionTransaction.begin(&selector);
    defer transaction.deinit();
    _ = try transaction.prepare(.preserve, .spill_live);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot2 }, selector.values.get("old").?.loc);
    try std.testing.expectEqual(@as(usize, 2), selector.spill_slots.count());
    try transaction.spill("old");
    try transaction.materialize(.{ .named = "other" }, .zeroExtending(32));
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
    try std.testing.expectEqual(saved_eflags_semantics_len, selector.eflags_semantics.items.len);
}

test "EFLAGS append rejection after preparation and materialization rolls back full transaction state" {
    var machine = MachineFunction.init("transaction-eflags-reject", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = 24;

    var initial = try AccumulatorDefinitionTransaction.begin(&selector);
    _ = try initial.prepare(.preserve, .spill_live);
    try initial.define("old", .zeroExtending(32));
    try initial.commit();
    initial.deinit();
    try state.bindValueLoc(&selector, "source", .{ .arg32 = .rdi });
    try machine.instructions.append(std.testing.allocator, .{ .mov_imm_eax = 9 });
    try selector.eflags.defineFor(.comparison);

    const old_binding = selector.values.get("old").?;
    const source_binding = selector.values.get("source").?;
    const saved_domain = selector.accumulator_domain;
    const saved_eflags = selector.eflags.snapshot();
    const saved_eflags_semantics_len = selector.eflags_semantics.items.len;
    const saved_next_virtual_reg = selector.next_virtual_reg;
    const saved_next_spill_slot = selector.next_spill_slot;

    var transaction = try AccumulatorDefinitionTransaction.begin(&selector);
    defer transaction.deinit();
    _ = try transaction.prepare(.preserve, .spill_live);
    try transaction.materialize(.{ .named = "source" }, .zeroExtending(32));
    try std.testing.expectError(
        error.EflagsClobberedWhileLive,
        state.emitEflagsInstruction(&selector, .{ .add_eax_imm32 = 1 }, .write),
    );
    try transaction.rollback();

    try std.testing.expectEqualSlices(machine_module.Instruction, &.{.{ .mov_imm_eax = 9 }}, machine.instructions.items);
    try std.testing.expectEqual(@as(usize, 2), selector.values.count());
    try std.testing.expectEqual(old_binding, selector.values.get("old").?);
    try std.testing.expectEqual(source_binding, selector.values.get("source").?);
    try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
    try std.testing.expectEqual(saved_next_virtual_reg, selector.next_virtual_reg);
    try std.testing.expectEqual(saved_next_spill_slot, selector.next_spill_slot);
    try std.testing.expectEqual(saved_domain, selector.accumulator_domain);
    try selector.eflags.validateSnapshot(saved_eflags);
    try std.testing.expectEqual(saved_eflags_semantics_len, selector.eflags_semantics.items.len);
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
    try std.testing.expectError(error.EflagsClobberedWhileLive, rejected.prepare(.clobber, .spill_live));
    try std.testing.expectEqual(kept_binding, selector.values.get("kept").?);
    try std.testing.expectEqual(saved_next_virtual_reg, selector.next_virtual_reg);
    try std.testing.expectEqual(saved_instruction_len, machine.instructions.items.len);
    try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
    try std.testing.expectEqual(@as(usize, 0), accumulatorBindingCount(&selector));
    try selector.eflags.validateSnapshot(saved_eflags);
    try rejected.rollback();

    var preserved = try AccumulatorDefinitionTransaction.begin(&selector);
    defer preserved.deinit();
    _ = try preserved.prepare(.preserve, .spill_live);
    try preserved.define("result", .zeroExtending(32));
    try preserved.commit();
    try selector.eflags.validateSnapshot(saved_eflags);
    try std.testing.expectEqual(@as(u16, 64), selector.accumulator_domain.defined_bits);
}

test "accumulator reuse source emits no preservation and spills only another live alias" {
    var machine = MachineFunction.init("reuse-source", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("source", 5);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    selector.stack_frame_bytes = 24;
    try state.bindValueLoc(&selector, "source", .eax);

    var transaction = try AccumulatorDefinitionTransaction.begin(&selector);
    defer transaction.deinit();
    try std.testing.expect((try transaction.prepare(
        .preserve,
        .{ .reuse_source = "source" },
    )) == null);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try transaction.materialize(.{ .named = "source" }, .zeroExtending(16));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try transaction.define("result", .fullRax());
    try transaction.commit();
    try std.testing.expectEqual(ValueLoc.eax, selector.values.get("source").?.loc);
    try std.testing.expectEqual(ValueLoc.rax, selector.values.get("result").?.loc);

    var alias_machine = MachineFunction.init("reuse-source-alias", .{ .int = 64 });
    defer alias_machine.deinit(std.testing.allocator);
    var alias_plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer alias_plan.deinit();
    try alias_plan.interval_ends.put("source", 5);
    try alias_plan.interval_ends.put("other", 5);
    var alias_selector = ComposedBlockSelector.init(std.testing.allocator, &alias_machine);
    defer alias_selector.deinit();
    alias_selector.allocation_plan = &alias_plan;
    alias_selector.current_position = 1;
    alias_selector.stack_frame_bytes = 24;
    try state.bindValueLoc(&alias_selector, "source", .eax);
    try state.bindValueLoc(&alias_selector, "other", .rax);

    var alias_transaction = try AccumulatorDefinitionTransaction.begin(&alias_selector);
    defer alias_transaction.deinit();
    try std.testing.expect((try alias_transaction.prepare(
        .preserve,
        .{ .reuse_source = "source" },
    )) == null);
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .spill_rax_rsp = .slot0 },
    }, alias_machine.instructions.items);
    try std.testing.expectEqual(ValueLoc.eax, alias_selector.values.get("source").?.loc);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, alias_selector.values.get("other").?.loc);
}

test "reuse source pins only the exact EAX RAX identity at current position" {
    inline for (.{
        .{
            .name = "reuse-eax-current",
            .source_loc = ValueLoc.eax,
            .live_loc = ValueLoc.rax,
            .definition = AccumulatorDefinition.zeroExtending(32),
            .result_loc = ValueLoc.eax,
            .expected_spill = machine_module.Instruction{ .spill_rax_rsp = .slot0 },
        },
        .{
            .name = "reuse-rax-current",
            .source_loc = ValueLoc.rax,
            .live_loc = ValueLoc.eax,
            .definition = AccumulatorDefinition.fullRax(),
            .result_loc = ValueLoc.rax,
            .expected_spill = machine_module.Instruction{ .spill_eax_rsp = .slot0 },
        },
    }) |case| {
        var machine = MachineFunction.init(case.name, .{ .int = case.definition.logical_bits });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try plan.interval_ends.put("source", 1);
        try plan.interval_ends.put("expired", 0);
        try plan.interval_ends.put("live", 2);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 1;
        selector.stack_frame_bytes = 24;
        try state.bindValueLoc(&selector, "source", case.source_loc);
        try state.bindValueLoc(&selector, "expired", case.live_loc);
        try state.bindValueLoc(&selector, "live", case.live_loc);
        const source_binding = selector.values.get("source").?;

        var transaction = try AccumulatorDefinitionTransaction.begin(&selector);
        defer transaction.deinit();
        try std.testing.expect((try transaction.prepare(
            .preserve,
            .{ .reuse_source = "source" },
        )) == null);
        try std.testing.expectEqual(source_binding, selector.values.get("source").?);
        try std.testing.expect(selector.values.get("expired") == null);
        try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector.values.get("live").?.loc);
        try std.testing.expectEqualSlices(machine_module.Instruction, &.{case.expected_spill}, machine.instructions.items);

        try transaction.materialize(.{ .named = "source" }, case.definition);
        try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
        try transaction.define("result", case.definition);
        try transaction.commit();
        try std.testing.expectEqual(source_binding, selector.values.get("source").?);
        try std.testing.expectEqual(case.result_loc, selector.values.get("result").?.loc);
        try std.testing.expectEqual(@as(usize, 3), selector.values.count());
    }
}

test "accumulator materialization re-resolves named spill and scratch homes" {
    inline for (.{
        .{
            .name = "rax-source",
            .source = ValueLoc.rax,
            .definition = AccumulatorDefinition.fullRax(),
            .expected_spill = machine_module.Instruction{ .spill_rax_rsp = .slot0 },
            .expected_reload = machine_module.Instruction{ .reload_rsp_rax = .slot0 },
        },
        .{
            .name = "eax-source",
            .source = ValueLoc.eax,
            .definition = AccumulatorDefinition.zeroExtending(32),
            .expected_spill = machine_module.Instruction{ .spill_eax_rsp = .slot0 },
            .expected_reload = machine_module.Instruction{ .reload_rsp_eax = .slot0 },
        },
    }) |case| {
        var machine = MachineFunction.init(case.name, .{ .int = case.definition.logical_bits });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try plan.interval_ends.put("source", 5);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 1;
        selector.stack_frame_bytes = 24;
        try state.bindValueLoc(&selector, "source", case.source);

        var transaction = try AccumulatorDefinitionTransaction.begin(&selector);
        defer transaction.deinit();
        try std.testing.expect((try transaction.prepare(.preserve, .spill_live)) == null);
        try transaction.materialize(.{ .named = "source" }, case.definition);
        try std.testing.expectEqualSlices(machine_module.Instruction, &.{
            case.expected_spill,
            case.expected_reload,
        }, machine.instructions.items);
    }

    var scratch_machine = MachineFunction.init("scratch-source", .{ .int = 32 });
    defer scratch_machine.deinit(std.testing.allocator);
    var scratch_plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer scratch_plan.deinit();
    try scratch_plan.interval_ends.put("source", 5);
    var scratch_selector = ComposedBlockSelector.init(std.testing.allocator, &scratch_machine);
    defer scratch_selector.deinit();
    scratch_selector.allocation_plan = &scratch_plan;
    scratch_selector.current_position = 1;
    scratch_selector.stack_frame_bytes = 24;
    try state.bindValueLoc(&scratch_selector, "source", .eax);

    var scratch = try AccumulatorDefinitionTransaction.begin(&scratch_selector);
    defer scratch.deinit();
    try std.testing.expect((try scratch.prepare(.preserve, .scratch_preferred)) == null);
    try scratch.materialize(.{ .named = "source" }, .zeroExtending(32));
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_eax_to_arg = .rdi },
        .{ .mov_arg_eax = .rdi },
    }, scratch_machine.instructions.items);
}

test "accumulator materialization handles stable and immediate sources without spurious reloads" {
    var machine = MachineFunction.init("stable-source", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try state.bindValueLoc(&selector, "source", .{ .scratch32 = .r8 });

    var named = try AccumulatorDefinitionTransaction.begin(&selector);
    try std.testing.expect((try named.prepare(.preserve, .spill_live)) == null);
    try named.materialize(.{ .named = "source" }, .zeroExtending(32));
    try named.define("named-result", .zeroExtending(32));
    try named.commit();
    named.deinit();
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_arg_eax = .r8 },
    }, machine.instructions.items);

    var immediate = try AccumulatorDefinitionTransaction.begin(&selector);
    defer immediate.deinit();
    try std.testing.expect((try immediate.prepare(.preserve, .spill_live)) == null);
    try immediate.materialize(.{ .int = 37 }, .zeroExtending(16));
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_arg_eax = .r8 },
        .{ .mov_imm_eax = 37 },
    }, machine.instructions.items);
}

test "missing named source after preparation rolls back the complete transaction" {
    var machine = MachineFunction.init("missing-current-source", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("source", 1);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    selector.stack_frame_bytes = 24;
    try state.bindValueLoc(&selector, "source", .eax);
    try machine.instructions.append(std.testing.allocator, .{ .mov_imm_eax = 9 });
    try selector.eflags.apply(.definition);

    const saved_binding = selector.values.get("source").?;
    const saved_domain = selector.accumulator_domain;
    const saved_eflags = selector.eflags.snapshot();
    const saved_eflags_semantics_len = selector.eflags_semantics.items.len;
    const saved_next_virtual_reg = selector.next_virtual_reg;
    const saved_next_spill_slot = selector.next_spill_slot;
    const saved_instructions = [_]machine_module.Instruction{.{ .mov_imm_eax = 9 }};

    var transaction = try AccumulatorDefinitionTransaction.begin(&selector);
    defer transaction.deinit();
    try std.testing.expect((try transaction.prepare(
        .preserve,
        .{ .reuse_source = "source" },
    )) == null);
    try std.testing.expectEqual(saved_binding, selector.values.get("source").?);
    _ = selector.values.remove("source");
    try std.testing.expectError(
        error.UnsupportedCodegenValue,
        transaction.materialize(.{ .named = "source" }, .zeroExtending(32)),
    );
    try std.testing.expectEqualSlices(machine_module.Instruction, &saved_instructions, machine.instructions.items);
    try std.testing.expectEqual(saved_binding, selector.values.get("source").?);
    try std.testing.expectEqual(saved_domain, selector.accumulator_domain);
    try std.testing.expectEqual(saved_next_virtual_reg, selector.next_virtual_reg);
    try std.testing.expectEqual(saved_next_spill_slot, selector.next_spill_slot);
    try selector.eflags.validateSnapshot(saved_eflags);
    try std.testing.expectEqual(saved_eflags_semantics_len, selector.eflags_semantics.items.len);
}

test "accumulator typed displacement preserves scratch preference and unconditional spill" {
    var scratch_machine = MachineFunction.init("scratch-preferred", .{ .int = 32 });
    defer scratch_machine.deinit(std.testing.allocator);
    var scratch_plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer scratch_plan.deinit();
    try scratch_plan.interval_ends.put("old", 5);
    var scratch_selector = ComposedBlockSelector.init(std.testing.allocator, &scratch_machine);
    defer scratch_selector.deinit();
    scratch_selector.allocation_plan = &scratch_plan;
    scratch_selector.current_position = 1;
    scratch_selector.stack_frame_bytes = 24;
    try state.bindValueLoc(&scratch_selector, "old", .eax);

    var scratch = try AccumulatorDefinitionTransaction.begin(&scratch_selector);
    defer scratch.deinit();
    try std.testing.expect((try scratch.prepare(.preserve, .scratch_preferred)) == null);
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_eax_to_arg = .rdi },
    }, scratch_machine.instructions.items);
    try std.testing.expectEqual(ValueLoc{ .scratch32 = .rdi }, scratch_selector.values.get("old").?.loc);

    var spill_machine = MachineFunction.init("spill-live", .{ .int = 32 });
    defer spill_machine.deinit(std.testing.allocator);
    var spill_plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer spill_plan.deinit();
    try spill_plan.interval_ends.put("old", 5);
    var spill_selector = ComposedBlockSelector.init(std.testing.allocator, &spill_machine);
    defer spill_selector.deinit();
    spill_selector.allocation_plan = &spill_plan;
    spill_selector.current_position = 1;
    spill_selector.stack_frame_bytes = 24;
    try state.bindValueLoc(&spill_selector, "old", .eax);

    var spill = try AccumulatorDefinitionTransaction.begin(&spill_selector);
    defer spill.deinit();
    try std.testing.expect((try spill.prepare(.preserve, .spill_live)) == null);
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .spill_eax_rsp = .slot0 },
    }, spill_machine.instructions.items);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, spill_selector.values.get("old").?.loc);

    var fallback_machine = MachineFunction.init("scratch-fallback", .{ .int = 32 });
    defer fallback_machine.deinit(std.testing.allocator);
    var fallback_plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer fallback_plan.deinit();
    try fallback_plan.interval_ends.put("old", 5);
    inline for (.{ "rdi", "rsi", "rdx", "rcx", "r8", "r9" }) |name| {
        try fallback_plan.interval_ends.put(name, 5);
    }
    var fallback_selector = ComposedBlockSelector.init(std.testing.allocator, &fallback_machine);
    defer fallback_selector.deinit();
    fallback_selector.allocation_plan = &fallback_plan;
    fallback_selector.current_position = 1;
    fallback_selector.stack_frame_bytes = 24;
    try state.bindValueLoc(&fallback_selector, "old", .eax);
    try state.bindValueLoc(&fallback_selector, "rdi", .{ .scratch64 = .rdi });
    try state.bindValueLoc(&fallback_selector, "rsi", .{ .scratch64 = .rsi });
    try state.bindValueLoc(&fallback_selector, "rdx", .{ .scratch64 = .rdx });
    try state.bindValueLoc(&fallback_selector, "rcx", .{ .scratch64 = .rcx });
    try state.bindValueLoc(&fallback_selector, "r8", .{ .scratch64 = .r8 });
    try state.bindValueLoc(&fallback_selector, "r9", .{ .scratch64 = .r9 });

    var fallback = try AccumulatorDefinitionTransaction.begin(&fallback_selector);
    defer fallback.deinit();
    try std.testing.expect((try fallback.prepare(.preserve, .scratch_preferred)) == null);
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .spill_eax_rsp = .slot0 },
    }, fallback_machine.instructions.items);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, fallback_selector.values.get("old").?.loc);
}

test "accumulator EFLAGS and displacement policies are independent and roll back together" {
    var machine = MachineFunction.init("independent-policies", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("old", 5);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    selector.stack_frame_bytes = 24;
    try state.bindValueLoc(&selector, "old", .eax);
    try machine.instructions.append(std.testing.allocator, .{ .mov_imm_eax = 7 });
    try selector.eflags.apply(.definition);

    const saved_binding = selector.values.get("old").?;
    const saved_domain = selector.accumulator_domain;
    const saved_eflags = selector.eflags.snapshot();
    const saved_next_spill_slot = selector.next_spill_slot;
    const saved_instructions = [_]machine_module.Instruction{.{ .mov_imm_eax = 7 }};

    var scratch = try AccumulatorDefinitionTransaction.begin(&selector);
    try std.testing.expect((try scratch.prepare(.preserve, .scratch_preferred)) == null);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectError(
        error.AccumulatorDefinitionAlreadyBound,
        scratch.define("old", .zeroExtending(32)),
    );
    try scratch.rollback();
    scratch.deinit();
    try std.testing.expectEqualSlices(machine_module.Instruction, &saved_instructions, machine.instructions.items);
    try std.testing.expectEqual(saved_binding, selector.values.get("old").?);
    try std.testing.expectEqual(saved_domain, selector.accumulator_domain);
    try std.testing.expectEqual(saved_next_spill_slot, selector.next_spill_slot);
    try selector.eflags.validateSnapshot(saved_eflags);

    var rejected = try AccumulatorDefinitionTransaction.begin(&selector);
    defer rejected.deinit();
    try std.testing.expectError(
        error.EflagsClobberedWhileLive,
        rejected.prepare(.clobber, .scratch_preferred),
    );
    try std.testing.expectEqualSlices(machine_module.Instruction, &saved_instructions, machine.instructions.items);
    try std.testing.expectEqual(saved_binding, selector.values.get("old").?);
    try selector.eflags.validateSnapshot(saved_eflags);
}
