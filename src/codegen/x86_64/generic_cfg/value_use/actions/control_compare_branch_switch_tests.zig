const support = @import("../test_support.zig");

const std = support.std;
const ir = support.ir;
const constant_table = support.constant_table;
const machine_module = support.machine_module;
const selector_types = support.selector_types;
const state_data = support.state_data;
const selector_state = support.selector_state;
const selector_scalar = support.selector_scalar;
const stage2_planning = support.stage2_planning;
const value_use = support.value_use;
const ComposedBlockSelector = support.ComposedBlockSelector;
const MachineFunction = support.MachineFunction;
const SelectorAllocationPlan = support.SelectorAllocationPlan;
const Transaction = support.Transaction;
const ValueLoc = support.ValueLoc;
const addLive = support.addLive;
const addAtCurrent = support.addAtCurrent;
const expected = support.expected;
const request = support.request;
const preparedRequest = support.preparedRequest;
const preparedSourceRequest = support.preparedSourceRequest;
const actionIdentity = support.actionIdentity;
const scratchCompareExpected = support.scratchCompareExpected;
const ScratchCompareRequests = support.ScratchCompareRequests;
const registerScratchCompare = support.registerScratchCompare;
const registerCurrentHomeEqZero = support.registerCurrentHomeEqZero;
const registerSetccEaxCompare = support.registerSetccEaxCompare;
const registerCurrentHomeSignBit = support.registerCurrentHomeSignBit;
const I128PairActionKind = support.I128PairActionKind;
const registerI128PairAction = support.registerI128PairAction;
const i128PairDiagnosticForTest = support.i128PairDiagnosticForTest;
const currentHomeSignBitDiagnosticForTest = support.currentHomeSignBitDiagnosticForTest;
const setccEaxCompareDiagnosticForTest = support.setccEaxCompareDiagnosticForTest;
const currentHomeEqZeroDiagnosticForTest = support.currentHomeEqZeroDiagnosticForTest;
const MemcpyRequests = support.MemcpyRequests;
const registerMemcpyRequests = support.registerMemcpyRequests;
const registerMemcpyAction = support.registerMemcpyAction;
const inlineMemcpyValueUseDiagnosticForTest = support.inlineMemcpyValueUseDiagnosticForTest;
const prepareAndExecuteAction = support.prepareAndExecuteAction;
const executeScratchCompareCase = support.executeScratchCompareCase;
const executeCurrentHomeEqZeroCase = support.executeCurrentHomeEqZeroCase;
const executeSetccEaxCompareCase = support.executeSetccEaxCompareCase;
const executeCurrentHomeSignBitCase = support.executeCurrentHomeSignBitCase;
const executeI128PairActionCase = support.executeI128PairActionCase;
const executeBranchConditionCase = support.executeBranchConditionCase;
const oneCaseSwitchAction = support.oneCaseSwitchAction;
const executeSwitchConditionCase = support.executeSwitchConditionCase;
const loadActionRequest = support.loadActionRequest;
const accumulatorLoadDefinition = support.accumulatorLoadDefinition;
const loadDiagnosticForTest = support.loadDiagnosticForTest;
const expectReadOnlyScalarLoadFailure = support.expectReadOnlyScalarLoadFailure;
const expectTableLoadFailure = support.expectTableLoadFailure;
const I128PairRollbackBoundary = support.I128PairRollbackBoundary;
const expectI128PairRollbackExact = support.expectI128PairRollbackExact;

test "value-use branch action reproduces exact accepted homes and commits EFLAGS" {
    try executeBranchConditionCase(.eax, .gpr32, 1, &.{.test_eax_eax});
    try executeBranchConditionCase(.{ .arg32 = .rdi }, .gpr32, 1, &.{.{ .test_arg8 = .rdi }});
    try executeBranchConditionCase(.{ .scratch32 = .r8 }, .gpr32, 1, &.{.{ .test_arg8 = .r8 }});
    try executeBranchConditionCase(.{ .spill64 = .slot2 }, .gpr64, 64, &.{
        .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = .slot2 } },
        .{ .test_arg8 = .rcx },
    });
}
test "value-use branch action rejects generic narrow homes the accepted path rejects" {
    var machine = MachineFunction.init("value-use-branch-exact-home", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "condition");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "condition", .{ .arg64 = .rdi });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    _ = try transaction.register(preparedRequest(
        "condition",
        .{ .int = 1 },
        .gpr32,
        .branch_condition,
        .branch_condition,
    ));
    try std.testing.expectError(error.ValueUseBranchConditionHomeUnsupported, transaction.seal());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}
test "value-use branch action rolls back spill preparation on EFLAGS rejection" {
    var machine = MachineFunction.init("value-use-branch-eflags-rollback", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "condition");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "condition", .{ .spill64 = .slot0 });
    selector.values.getPtr("condition").?.vreg.class = .gpr64;
    selector.values.getPtr("condition").?.vreg.bits = 64;
    try selector_state.emitEflagsInstruction(&selector, .{ .cmp_eax_imm32 = 1 }, .definition);
    const before_binding = selector.values.get("condition").?;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const action = try transaction.register(preparedRequest(
        "condition",
        .{ .int = 1 },
        .gpr32,
        .branch_condition,
        .branch_condition,
    ));
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try std.testing.expectError(
        error.EflagsDefinitionOverwrittenWhileLive,
        transaction.executePreparedAction(try transaction.preparedView(action)),
    );
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{.{ .cmp_eax_imm32 = 1 }}, machine.instructions.items);
    try std.testing.expectEqual(before_binding, selector.values.get("condition").?);
    try std.testing.expectEqual(@as(usize, 1), selector.eflags_semantics.items.len);
}
test "value-use switch action owns intent and reproduces ordinary compare chain" {
    var machine = MachineFunction.init("value-use-switch-chain", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "condition");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "condition", .{ .arg64 = .rdi });

    var case_name = [_]u8{ 'c', 'a', 's', 'e', '-', 's', 'e', 'v', 'e', 'n' };
    var default_name = [_]u8{ 'd', 'e', 'f', 'a', 'u', 'l', 't' };
    const switch_action = try Transaction.SwitchCompareChainAction.init(
        8,
        &.{.{ .value = 7, .target = &case_name }},
        &default_name,
        null,
    );
    @memset(&case_name, 'x');
    @memset(&default_name, 'y');

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const action = try transaction.register(preparedRequest(
        "condition",
        .{ .int = 8 },
        .gpr32,
        .switch_condition,
        .{ .switch_compare_chain = switch_action },
    ));
    try transaction.seal();
    try transaction.applySwitchBoundary(action);
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(action));
    try transaction.commit();

    try std.testing.expectEqual(@as(usize, 5), machine.instructions.items.len);
    try std.testing.expectEqual(machine_module.Instruction{ .mov_arg_eax = .rdi }, machine.instructions.items[0]);
    try std.testing.expectEqual(machine_module.Instruction{ .and_eax_imm32 = 255 }, machine.instructions.items[1]);
    try std.testing.expectEqual(machine_module.Instruction{ .cmp_eax_imm32 = 7 }, machine.instructions.items[2]);
    try std.testing.expect(machine.instructions.items[3] == .je);
    try std.testing.expectEqualStrings("case-seven", machine.instructions.items[3].je);
    try std.testing.expect(machine.instructions.items[4] == .jmp);
    try std.testing.expectEqualStrings("default", machine.instructions.items[4].jmp);
    try std.testing.expectEqual(@as(usize, 2), machine.owned_labels.items.len);
    try std.testing.expectEqual(@as(usize, 0), selector.edge_label_count);
    try std.testing.expectEqual(@as(usize, 3), selector.eflags_semantics.items.len);
}
test "value-use switch action accepts fixed-owned immediate intent" {
    var machine = MachineFunction.init("value-use-switch-immediate", .void);
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    var switch_request = Transaction.Request{
        .source = .{ .int = 7 },
        .expected = expected(.{ .int = 32 }, .gpr32),
        .form = .switch_condition,
        .destination = .prepared_view,
        .prepared_action = .{ .switch_compare_chain = try oneCaseSwitchAction(32) },
    };
    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const action = try transaction.register(switch_request);
    switch_request.source = .{ .int = 99 };
    try transaction.seal();
    try transaction.applySwitchBoundary(action);
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(action));
    try transaction.commit();
    try std.testing.expectEqual(machine_module.Instruction{ .mov_imm_eax = 7 }, machine.instructions.items[0]);
}
test "value-use switch action reproduces every accepted named condition home" {
    try executeSwitchConditionCase(.eax, .gpr32, 32, .{ .cmp_eax_imm32 = 7 });
    try executeSwitchConditionCase(.rax, .gpr64, 64, .{ .cmp_eax_imm32 = 7 });
    try executeSwitchConditionCase(.{ .arg32 = .rdi }, .gpr32, 32, .{ .mov_arg_eax = .rdi });
    try executeSwitchConditionCase(.{ .scratch32 = .r8 }, .gpr32, 32, .{ .mov_arg_eax = .r8 });
    try executeSwitchConditionCase(.{ .arg64 = .rsi }, .gpr64, 64, .{ .mov_arg_eax = .rsi });
    try executeSwitchConditionCase(.{ .scratch64 = .r9 }, .gpr64, 64, .{ .mov_arg_eax = .r9 });
    try executeSwitchConditionCase(
        .{ .arg128 = .{ .lo = .rdi, .hi = .rsi } },
        .gpr128,
        128,
        .{ .mov_arg_eax = .rdi },
    );
    try executeSwitchConditionCase(
        .{ .scratch128 = .{ .lo = .r8, .hi = .r9 } },
        .gpr128,
        128,
        .{ .mov_arg_eax = .r8 },
    );
    try executeSwitchConditionCase(.{ .spill64 = .slot2 }, .gpr64, 64, .{ .reload_rsp_eax = .slot2 });
}
test "value-use switch action rejects invalid fixed storage and unsupported homes" {
    try std.testing.expectError(
        error.ValueUseSwitchDuplicateCase,
        Transaction.SwitchCompareChainAction.init(
            8,
            &.{
                .{ .value = 1, .target = "one" },
                .{ .value = 1, .target = "duplicate" },
            },
            "default",
            null,
        ),
    );
    try std.testing.expectError(
        error.ValueUseSwitchCaseCountUnsupported,
        Transaction.SwitchCompareChainAction.init(8, &.{}, "default", null),
    );

    var machine = MachineFunction.init("value-use-switch-rejected-home", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "condition");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "condition", .{ .spill64 = .slot0 });
    selector.values.getPtr("condition").?.vreg.class = .gpr128;
    selector.values.getPtr("condition").?.vreg.bits = 128;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const action = try transaction.register(preparedRequest(
        "condition",
        .{ .int = 32 },
        .gpr32,
        .switch_condition,
        .{ .switch_compare_chain = try oneCaseSwitchAction(32) },
    ));
    try transaction.seal();
    try std.testing.expectError(error.ValueUseSwitchConditionHomeUnsupported, transaction.applySwitchBoundary(action));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}
test "value-use switch resolves after boundary and rollback restores all boundary state" {
    var machine = MachineFunction.init("value-use-switch-boundary", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addLive(&plan, "condition");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 64;
    try selector_state.bindValueLoc(&selector, "condition", .{ .arg32 = .rdi });
    const before_binding = selector.values.get("condition").?;
    const before_next_spill = selector.next_spill_slot;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const action = try transaction.register(preparedRequest(
        "condition",
        .{ .int = 32 },
        .gpr32,
        .switch_condition,
        .{ .switch_compare_chain = try oneCaseSwitchAction(32) },
    ));
    try transaction.seal();
    try transaction.applySwitchBoundary(action);
    try std.testing.expect(selector.values.get("condition").?.loc == .spill64);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try transaction.prepare();
    try transaction.rollback();

    try std.testing.expectEqual(before_binding, selector.values.get("condition").?);
    try std.testing.expectEqual(before_next_spill, selector.next_spill_slot);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
}
test "value-use switch rollback restores displaced PHI destinations and owned targets" {
    var machine = MachineFunction.init("value-use-switch-phi-rollback", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addLive(&plan, "phi");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector.phi_destinations.put("phi", .{ .scratch64 = .rcx });
    try selector_state.bindValueLoc(&selector, "phi", .{ .spill64 = .slot2 });
    const before_binding = selector.values.get("phi").?;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const action = try transaction.register(.{
        .source = .{ .int = 7 },
        .expected = expected(.{ .int = 32 }, .gpr32),
        .form = .switch_condition,
        .destination = .prepared_view,
        .prepared_action = .{ .switch_compare_chain = try oneCaseSwitchAction(32) },
    });
    try transaction.seal();
    try transaction.applySwitchBoundary(action);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector.values.get("phi").?.loc);
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(action));
    try std.testing.expectEqual(@as(usize, 2), machine.owned_labels.items.len);
    try transaction.rollback();

    try std.testing.expectEqual(before_binding, selector.values.get("phi").?);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector.phi_destinations.get("phi").?);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
}
