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

test "value-use lifetime authority separates plan interval availability and provenance" {
    var machine = MachineFunction.init("value-use-lifetime-authority", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.current_position = 2;
    try selector_state.bindValueLoc(&selector, "first", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "second", .{ .arg64 = .rsi });

    var missing_plan = try Transaction.begin(&selector);
    defer missing_plan.deinit();
    const first = try missing_plan.register(request(
        "first",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .rax,
    ));
    const second = try missing_plan.register(request(
        "second",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .gpr64 = .rcx },
    ));
    try std.testing.expectError(error.ValueUseSourcePlanMissing, missing_plan.seal());
    try std.testing.expect(missing_plan.failedRequestIs(first));
    try std.testing.expect(!missing_plan.failedRequestIs(second));

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    selector.allocation_plan = &plan;

    var missing_interval = try Transaction.begin(&selector);
    defer missing_interval.deinit();
    const missing_interval_handle = try missing_interval.register(request(
        "first",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .rax,
    ));
    try std.testing.expectError(
        error.ValueUseSourceIntervalMissing,
        missing_interval.seal(),
    );
    try std.testing.expect(missing_interval.failedRequestIs(missing_interval_handle));

    try plan.interval_ends.put("first", 1);
    var expired = try Transaction.begin(&selector);
    defer expired.deinit();
    const expired_handle = try expired.register(request(
        "first",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .rax,
    ));
    try std.testing.expectError(error.ValueUseExpiredSource, expired.seal());
    try std.testing.expect(expired.failedRequestIs(expired_handle));

    try plan.interval_ends.put("first", 2);
    var end_at_current = try Transaction.begin(&selector);
    defer end_at_current.deinit();
    _ = try end_at_current.register(request(
        "first",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .rax,
    ));
    try end_at_current.seal();
    try end_at_current.rollback();

    try plan.interval_ends.put("first", 3);
    var survives = try Transaction.begin(&selector);
    defer survives.deinit();
    _ = try survives.register(request(
        "first",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .rax,
    ));
    try survives.seal();
    try survives.rollback();

    selector.allocation_plan = null;
    var typed_null = try Transaction.begin(&selector);
    defer typed_null.deinit();
    _ = try typed_null.register(.{
        .source = .null_value,
        .expected = expected(.ptr, .gpr64),
        .form = .pointer,
        .destination = .rax,
    });
    try typed_null.seal();
    try typed_null.rollback();
}

test "value-use transaction removes dead aliases and preserves live aliases exactly once before re-resolution" {
    var machine = MachineFunction.init("value-use-aliases", .ptr);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("dead", 0);
    try addLive(&plan, "live");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 2;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "dead", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "live", .{ .arg64 = .rdi });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    _ = try transaction.register(.{
        .source = .null_value,
        .expected = expected(.ptr, .gpr64),
        .form = .pointer,
        .destination = .{ .gpr64 = .rdi },
    });
    try transaction.seal();
    try transaction.prepare();
    try std.testing.expect(selector.values.get("dead") == null);
    try std.testing.expect(selector.values.get("live").?.loc == .spill64);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try transaction.materializeAll();
    try transaction.commit();
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
}
