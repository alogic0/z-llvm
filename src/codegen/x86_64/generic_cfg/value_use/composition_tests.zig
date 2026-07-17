const support = @import("test_support.zig");

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

test "value-use subordinate accumulator lifecycle has one outer commit authority" {
    var machine = MachineFunction.init("value-use-subordinate-accumulator", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "operand");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "operand", .{ .arg32 = .rdi });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    try std.testing.expectError(
        error.ValueUseAccumulatorSessionRequiresSealedPlan,
        transaction.beginAccumulatorSession(),
    );
    _ = try transaction.register(request(
        "operand",
        .{ .int = 32 },
        .gpr32,
        .gpr32,
        .{ .gpr32 = .r8 },
    ));
    try transaction.seal();
    const accumulator = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    try std.testing.expect((try transaction.prepareAccumulator(
        accumulator,
        .preserve,
        .spill_live,
    )) == null);
    try machine.instructions.append(std.testing.allocator, .{ .mov_arg_eax = .r8 });
    try transaction.defineAccumulatorResult(accumulator, "result", .zeroExtending(32));

    try std.testing.expectError(
        error.ValueUseAccumulatorIndependentCommit,
        transaction.commitAccumulatorSession(accumulator),
    );
    try std.testing.expectError(error.ValueUseAccumulatorResultNotFinalized, transaction.commit());
    try transaction.finalizeAccumulatorResult(accumulator);
    try transaction.commit();

    try std.testing.expectEqual(ValueLoc.eax, selector.values.get("result").?.loc);
    try std.testing.expectEqual(@as(u16, 64), selector.accumulator_domain.defined_bits);
    try std.testing.expectEqual(@as(usize, 1), Transaction.address_domain_snapshot_copies);
    try std.testing.expectEqual(
        @as(usize, 0),
        selector_state.AccumulatorDefinitionSession.address_domain_snapshot_copies,
    );
    try std.testing.expectEqual(@as(usize, 0), selector_state.AccumulatorDefinitionSession.snapshot_copies);
    try std.testing.expectEqual(
        @sizeOf(selector_state.AddressDependencies),
        Transaction.address_domain_snapshot_bytes,
    );
}
test "value-use outer rollback restores combined state after accumulator finalization exactly once" {
    var machine = MachineFunction.init("value-use-combined-rollback", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "operand", "index", "pointer" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    selector.next_spill_slot = 1;
    selector.edge_label_count = 4;
    selector.stack_array_count = 3;
    try selector_state.bindValueLoc(&selector, "operand", .{ .arg32 = .rdi });
    try selector_state.bindValueLoc(&selector, "index", .{ .scratch64 = .r9 });
    try selector_state.bindValueLoc(&selector, "pointer", .{ .stack_i32_ptr = .{
        .disp = 8,
        .index = .{ .reg = .r9, .name = "index" },
    } });
    try selector.spill_slots.put("seed-spill", .{ .base = 0, .slots = 1 });
    try selector.phi_destinations.put("seed-phi", .{ .arg32 = .rsi });
    try machine.instructions.append(std.testing.allocator, .{ .mov_imm_eax = 17 });
    try selector.eflags.apply(.definition);
    const retained_label = try selector_state.allocateEdgeLabel(&selector);
    const retained_pointer = retained_label.ptr;

    const operand_binding = selector.values.get("operand").?;
    const index_binding = selector.values.get("index").?;
    const pointer_binding = selector.values.get("pointer").?;
    const saved_dependencies = selector.address_dependencies;
    const saved_eflags = selector.eflags.snapshot();
    const saved_next_vreg = selector.next_virtual_reg;
    const saved_next_spill = selector.next_spill_slot;
    const saved_edge_labels = selector.edge_label_count;
    const saved_stack_arrays = selector.stack_array_count;
    const saved_semantics = selector.eflags_semantics.items.len;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    _ = try transaction.register(request(
        "operand",
        .{ .int = 32 },
        .gpr32,
        .gpr32,
        .{ .gpr32 = .r8 },
    ));
    try transaction.seal();
    const accumulator = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    try std.testing.expect((try transaction.prepareAccumulator(
        accumulator,
        .preserve,
        .spill_live,
    )) == null);
    try machine.instructions.append(std.testing.allocator, .{ .mov_arg_eax = .r8 });
    try transaction.defineAccumulatorResult(accumulator, "result", .zeroExtending(32));
    try transaction.finalizeAccumulatorResult(accumulator);

    _ = selector_state.removeValueBinding(&selector, "pointer");
    try selector_state.bindValueLoc(&selector, "speculative", .{ .scratch64 = .rcx });
    try selector.spill_slots.put("speculative-spill", .{ .base = 2, .slots = 1 });
    try selector.phi_destinations.put("speculative-phi", .rax);
    selector.stack_array_count += 5;
    const speculative_a = try selector_state.allocateEdgeLabel(&selector);
    const speculative_b = try selector_state.allocateEdgeLabel(&selector);
    try machine.instructions.append(std.testing.allocator, .{ .label = speculative_a });
    try machine.instructions.append(std.testing.allocator, .{ .label = speculative_b });

    try transaction.rollback();
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{.{ .mov_imm_eax = 17 }}, machine.instructions.items);
    try std.testing.expectEqual(operand_binding, selector.values.get("operand").?);
    try std.testing.expectEqual(index_binding, selector.values.get("index").?);
    try std.testing.expectEqual(pointer_binding, selector.values.get("pointer").?);
    try std.testing.expect(selector.values.get("result") == null);
    try std.testing.expect(selector.values.get("speculative") == null);
    try std.testing.expectEqual(@as(usize, 1), selector.spill_slots.count());
    try std.testing.expect(selector.spill_slots.get("seed-spill") != null);
    try std.testing.expectEqual(@as(usize, 1), selector.phi_destinations.count());
    try std.testing.expectEqual(ValueLoc{ .arg32 = .rsi }, selector.phi_destinations.get("seed-phi").?);
    try std.testing.expectEqual(saved_next_vreg, selector.next_virtual_reg);
    try std.testing.expectEqual(saved_next_spill, selector.next_spill_slot);
    try std.testing.expectEqual(saved_edge_labels, selector.edge_label_count);
    try std.testing.expectEqual(saved_stack_arrays, selector.stack_array_count);
    try std.testing.expect(selector.address_dependencies.eql(&saved_dependencies));
    try selector.eflags.validateSnapshot(saved_eflags);
    try std.testing.expectEqual(saved_semantics, selector.eflags_semantics.items.len);
    try std.testing.expectEqual(@as(usize, 1), machine.owned_labels.items.len);
    try std.testing.expectEqual(retained_pointer, machine.owned_labels.items[0].ptr);
    try std.testing.expectError(error.ValueUseTransactionClosed, transaction.rollback());
}
test "value-use request provenance survives subordinate accumulator activity and rollback" {
    var machine = MachineFunction.init("value-use-composed-provenance", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "operand");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "operand", .{ .arg64 = .rdi });
    const saved_operand = selector.values.get("operand").?;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const operand = try transaction.register(preparedRequest(
        "operand",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .validate_shape = .{ .register_gpr64 = .rdi } },
    ));
    try transaction.seal();
    const accumulator = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    const lease = try transaction.preparedView(operand);
    try std.testing.expect((try transaction.prepareAccumulator(
        accumulator,
        .preserve,
        .spill_live,
    )) == null);
    try transaction.defineAccumulatorResult(accumulator, "result", .zeroExtending(32));
    _ = selector.values.remove("operand");

    try std.testing.expectError(error.ValueUseUnresolvedSource, transaction.executePreparedAction(lease));
    try std.testing.expect(transaction.failedRequestIs(operand));
    try std.testing.expectEqual(saved_operand, selector.values.get("operand").?);
    try std.testing.expect(selector.values.get("result") == null);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}
test "standalone accumulator transaction preserves its original lifecycle and stream" {
    var machine = MachineFunction.init("standalone-accumulator-unchanged", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "source", .{ .arg32 = .rdi });

    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(&selector);
    defer transaction.deinit();
    try std.testing.expect((try transaction.prepare(.preserve, .spill_live)) == null);
    try transaction.materialize(.{ .named = "source" }, .zeroExtending(32));
    try transaction.define("result", .zeroExtending(32));
    try transaction.commit();

    try std.testing.expectEqualSlices(machine_module.Instruction, &.{.{ .mov_arg_eax = .rdi }}, machine.instructions.items);
    try std.testing.expectEqual(ValueLoc.eax, selector.values.get("result").?.loc);
    try std.testing.expectError(error.AccumulatorTransactionClosed, transaction.commit());
    try std.testing.expectError(
        error.AccumulatorCallMustClobberEflags,
        transaction.prepareCallBeforeArguments(.preserve),
    );
    try std.testing.expectError(
        error.AccumulatorCallPreparationOrder,
        transaction.finishCallPreparationAfterArguments(),
    );
}
