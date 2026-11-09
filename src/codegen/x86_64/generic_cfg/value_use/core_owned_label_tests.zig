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

test "value-use long owned identities preserve shared prefixes and reject beyond bound" {
    const model = @import("model.zig");
    var names: [2][model.max_identity_bytes + 1]u8 = @splat(@splat('x'));
    names[0][model.max_identity_bytes - 1] = 'a';
    names[1][model.max_identity_bytes - 1] = 'b';
    inline for (.{ model.ActionIdentity, model.PreparedIdentity, model.Identity }) |IdentityType| {
        const first = try IdentityType.init(names[0][0..model.max_identity_bytes]);
        const second = try IdentityType.init(names[1][0..model.max_identity_bytes]);
        try std.testing.expectEqual(@as(u16, 512), first.len);
        try std.testing.expectEqualStrings(names[0][0..model.max_identity_bytes], first.slice());
        try std.testing.expect(!std.mem.eql(u8, first.slice(), second.slice()));
        try std.testing.expectError(error.ValueUseEmptyIdentity, IdentityType.init(""));
        try std.testing.expectError(error.ValueUseIdentityTooLong, IdentityType.init(&names[0]));
    }
    var owned = try model.ActionIdentity.init(names[0][0..406]);
    names[0][0] = 'y';
    try std.testing.expectEqual(@as(u8, 'x'), owned.slice()[0]);
    owned.len = model.max_identity_bytes + 1;
    try std.testing.expectError(error.ValueUseIdentityTooLong, owned.validate());
}

test "value-use long source identity registration has exact rollback and no prefix collisions" {
    var machine = MachineFunction.init("long-owned-identities", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    var names: [2][406]u8 = @splat(@splat('p'));
    names[0][405] = 'a';
    names[1][405] = 'b';
    for (&names) |*name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, &names[0], .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, &names[1], .{ .arg64 = .rsi });
    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const first = try transaction.register(preparedRequest(&names[0], .{ .int = 64 }, .gpr64, .gpr64, .{ .validate_shape = .{ .register_gpr64 = .rdi } }));
    const second = try transaction.register(preparedRequest(&names[1], .{ .int = 64 }, .gpr64, .gpr64, .{ .validate_shape = .{ .register_gpr64 = .rsi } }));
    try std.testing.expect(first.index != second.index);
    const oversized: [513]u8 = @splat('q');
    try std.testing.expectError(error.ValueUseIdentityTooLong, transaction.register(preparedRequest(&oversized, .{ .int = 64 }, .gpr64, .gpr64, .{ .validate_shape = .{ .register_gpr64 = .rdi } })));
    try std.testing.expectEqual(@as(u8, 2), transaction.request_count);
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    const first_view = try transaction.preparedView(first);
    const second_view = try transaction.preparedView(second);
    try transaction.executePreparedAction(first_view);
    try transaction.executePreparedAction(second_view);
    try transaction.rollback();
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
    try std.testing.expect(selector.values.get(&names[0]).?.loc == .arg64);
    try std.testing.expectEqual(.rdi, selector.values.get(&names[0]).?.loc.arg64);
    try std.testing.expectEqual(.rsi, selector.values.get(&names[1]).?.loc.arg64);
}

test "value-use rollback releases speculative owned labels after instructions and commit retains them" {
    var machine = MachineFunction.init("value-use-owned-labels", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addLive(&plan, "source");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg64 = .rdi });

    const retained = try selector_state.allocateEdgeLabel(&selector);
    const retained_pointer = retained.ptr;
    try std.testing.expectEqual(@as(usize, 1), machine.owned_labels.items.len);

    var rollback_transaction = try Transaction.begin(&selector);
    defer rollback_transaction.deinit();
    const rollback_handle = try rollback_transaction.register(preparedRequest(
        "source",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .validate_shape = .{ .register_gpr64 = .rdi } },
    ));
    try rollback_transaction.seal();
    try rollback_transaction.prepare();
    try rollback_transaction.materializeAll();
    const rollback_lease = try rollback_transaction.preparedView(rollback_handle);
    try rollback_transaction.executePreparedAction(rollback_lease);
    const first = try selector_state.allocateEdgeLabel(&selector);
    const second = try selector_state.allocateEdgeLabel(&selector);
    try machine.instructions.append(std.testing.allocator, .{ .label = first });
    try machine.instructions.append(std.testing.allocator, .{ .label = second });
    try rollback_transaction.rollback();
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(@as(usize, 1), machine.owned_labels.items.len);
    try std.testing.expectEqual(retained_pointer, machine.owned_labels.items[0].ptr);
    try std.testing.expectEqual(@as(usize, 1), selector.edge_label_count);

    var failure_transaction = try Transaction.begin(&selector);
    defer failure_transaction.deinit();
    const failure_handle = try failure_transaction.register(preparedRequest(
        "source",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .validate_shape = .{ .register_gpr64 = .rdi } },
    ));
    try failure_transaction.seal();
    try failure_transaction.prepare();
    try failure_transaction.materializeAll();
    const failure_lease = try failure_transaction.preparedView(failure_handle);
    const third = try selector_state.allocateEdgeLabel(&selector);
    const fourth = try selector_state.allocateEdgeLabel(&selector);
    try machine.instructions.append(std.testing.allocator, .{ .label = third });
    try machine.instructions.append(std.testing.allocator, .{ .label = fourth });
    _ = selector.values.remove("source");
    try std.testing.expectError(error.ValueUseUnresolvedSource, failure_transaction.executePreparedAction(failure_lease));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(@as(usize, 1), machine.owned_labels.items.len);
    try std.testing.expectEqual(retained_pointer, machine.owned_labels.items[0].ptr);
    try std.testing.expect(selector.values.get("source") != null);

    var commit_transaction = try Transaction.begin(&selector);
    defer commit_transaction.deinit();
    const commit_handle = try commit_transaction.register(preparedRequest(
        "source",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .validate_shape = .{ .register_gpr64 = .rdi } },
    ));
    try commit_transaction.seal();
    try commit_transaction.prepare();
    try commit_transaction.materializeAll();
    _ = try commit_transaction.preparedView(commit_handle);
    const committed = try selector_state.allocateEdgeLabel(&selector);
    try machine.instructions.append(std.testing.allocator, .{ .label = committed });
    try commit_transaction.commit();
    try std.testing.expectEqual(@as(usize, 2), machine.owned_labels.items.len);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(retained_pointer, machine.owned_labels.items[0].ptr);
}
