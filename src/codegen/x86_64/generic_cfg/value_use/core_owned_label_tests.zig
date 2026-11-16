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

test "value-use spill checkpoint avoids copying retained history and restores subordinate insertions" {
    var failing = std.testing.FailingAllocator.init(std.testing.allocator, .{});
    const allocator = failing.allocator();
    var machine = support.MachineFunction.init("value-use-spill-history", .{ .int = 64 });
    defer machine.deinit(allocator);
    var selector = support.ComposedBlockSelector.init(allocator, &machine);
    defer selector.deinit();
    for (0..1024) |index| {
        var storage: [32]u8 = undefined;
        const name = try std.fmt.bufPrint(&storage, "retained-{d}", .{index});
        try std.testing.expect(selector_state.allocateSpillSlot(&selector, name) != null);
    }
    const allocations = failing.allocations;
    failing.fail_index = failing.alloc_index;
    var transaction = try support.Transaction.begin(&selector);
    defer transaction.deinit();
    try std.testing.expectEqual(allocations, failing.allocations);
    failing.fail_index = std.math.maxInt(usize);
    try std.testing.expect(selector_state.allocatePairSpillSlots(&selector, "speculative-pair") != null);
    try std.testing.expect(selector_state.allocateSpillSlot(&selector, "speculative-scalar") != null);
    try transaction.rollback();
    try std.testing.expectEqual(@as(usize, 1024), selector.spill_slots.count());
    try std.testing.expectEqual(@as(usize, 1024), selector.owned_spill_slot_keys.count());
    try std.testing.expectEqual(@as(usize, 1024), selector.next_spill_slot);
    try std.testing.expectEqual(@as(usize, 1023), selector.spill_slots.get("retained-1023").?.base);
    try std.testing.expect(selector.spill_slots.get("speculative-pair") == null);
    try std.testing.expect(selector.spill_slots.get("speculative-scalar") == null);
}
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

test "value-use unmigrated action identities retain their explicit owned name bound" {
    const model = @import("model.zig");
    var names: [2][model.max_identity_bytes + 1]u8 = @splat(@splat('x'));
    names[0][model.max_identity_bytes - 1] = 'a';
    names[1][model.max_identity_bytes - 1] = 'b';
    inline for (.{model.ActionIdentity}) |IdentityType| {
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
    var names: [2][4096]u8 = @splat(@splat('p'));
    names[0][4095] = 'a';
    names[1][4095] = 'b';
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
    try std.testing.expectError(error.ValueUseEmptyIdentity, transaction.register(preparedRequest("", .{ .int = 64 }, .gpr64, .gpr64, .{ .validate_shape = .{ .register_gpr64 = .rdi } })));
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

test "value-use scoped names survive rollback without aliasing and registration OOM is atomic" {
    var failing = std.testing.FailingAllocator.init(std.testing.allocator, .{});
    const allocator = failing.allocator();
    var machine = MachineFunction.init("identity-rollback", .{ .int = 64 });
    defer machine.deinit(allocator);
    var selector = ComposedBlockSelector.init(allocator, &machine);
    defer selector.deinit();
    var first_identity: @import("model.zig").Identity = undefined;
    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        _ = try transaction.register(request("first", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rdi }));
        first_identity = transaction.requests[0].source.named;
        const count = selector.value_use_names.names.count();
        failing.fail_index = failing.alloc_index;
        try std.testing.expectError(error.OutOfMemory, transaction.register(request("different", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rsi })));
        try std.testing.expectEqual(count, selector.value_use_names.names.count());
        try std.testing.expectEqual(@as(u8, 1), transaction.request_count);
        try std.testing.expect(first_identity.eql(&transaction.requests[0].source.named));
        failing.fail_index = std.math.maxInt(usize);
        try transaction.rollback();
    }
    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        _ = try transaction.register(request("different", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rsi }));
        try std.testing.expect(!first_identity.eql(&transaction.requests[0].source.named));
        try std.testing.expectEqualStrings("first", try first_identity.slice(&selector.value_use_names));
        try std.testing.expectEqualStrings("different", try transaction.requests[0].source.named.slice(&selector.value_use_names));
        try transaction.rollback();
    }
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
}

test "value-use request and accumulator handles reject a new transaction at the same address" {
    var machine = MachineFunction.init("same-address-identities", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addLive(&plan, "source");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg64 = .rdi });
    var transaction: Transaction = undefined;
    var old_request: Transaction.RequestHandle = undefined;
    var old_session: Transaction.AccumulatorSessionHandle = undefined;
    {
        transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        old_request = try transaction.register(preparedRequest("source", .{ .int = 64 }, .gpr64, .gpr64, .{ .validate_shape = .{ .register_gpr64 = .rdi } }));
        try transaction.seal();
        old_session = try transaction.beginAccumulatorSession();
    }
    {
        transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const current = try transaction.register(preparedRequest("source", .{ .int = 64 }, .gpr64, .gpr64, .{ .validate_shape = .{ .register_gpr64 = .rdi } }));
        try std.testing.expectEqual(old_request.authority, current.authority);
        try std.testing.expectEqual(old_request.index, current.index);
        try std.testing.expectEqual(old_request.generation, current.generation);
        try std.testing.expect(old_request.namespace != current.namespace);
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try std.testing.expectError(error.ValueUseAccumulatorSessionStale, transaction.commitAccumulatorSession(old_session));
        try transaction.prepare();
        try transaction.materializeAll();
        try std.testing.expectError(error.ValueUsePreparedViewStale, transaction.preparedView(old_request));
    }
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
}

test "value-use foreign source identity rejects before selector writes" {
    var machine = MachineFunction.init("foreign-identity", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addLive(&plan, "source");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg64 = .rdi });
    var foreign: @import("scoped_names.zig").Pool = .{};
    defer foreign.deinit(std.testing.allocator);
    const foreign_name = try foreign.intern(std.testing.allocator, "source");
    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    _ = try transaction.register(preparedRequest("source", .{ .int = 64 }, .gpr64, .gpr64, .{ .validate_shape = .{ .register_gpr64 = .rdi } }));
    try std.testing.expectEqual(foreign_name.slot, transaction.requests[0].source.named.slot);
    transaction.requests[0].source.named = foreign_name;
    try std.testing.expectError(error.ValueUseIdentityStale, transaction.seal());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
    try std.testing.expectEqual(.rdi, selector.values.get("source").?.loc.arg64);
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
