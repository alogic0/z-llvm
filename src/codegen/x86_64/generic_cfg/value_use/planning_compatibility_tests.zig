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

test "value-use transaction dependency and unsupported-view failures leave selector unmodified" {
    var machine = MachineFunction.init("value-use-rejections", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "xmm", "aggregate", "integer", "bad-address", "pointer", "missing-index" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "xmm", .{ .xmm = .{ .reg = .xmm0, .bits = 64 } });
    try selector_state.bindValueLoc(&selector, "aggregate", .{ .aggregate_sse = .{ .packed_f32x2 = null } });
    try selector_state.bindValueLoc(&selector, "integer", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "bad-address", .{ .stack_f32_pair_ptr = .{ .object_base_disp = 0, .disp = 4 } });
    const cases = [_]struct { request: Transaction.Request, expected_error: anyerror }{
        .{ .request = request("xmm", .{ .int = 64 }, .gpr64, .gpr64, .rax), .expected_error = error.ValueUseRegisterClassMismatch },
        .{ .request = request("aggregate", .{ .int = 64 }, .gpr64, .gpr64, .rax), .expected_error = error.ValueUseRegisterClassMismatch },
        .{ .request = request("integer", .{ .int = 32 }, .gpr64, .gpr64, .rax), .expected_error = error.ValueUseTypeMismatch },
        .{ .request = request("bad-address", .ptr, .stack_pointer, .pointer, .rax), .expected_error = error.ValueUseUnsupportedAddressForm },
        .{ .request = request("unresolved", .{ .int = 64 }, .gpr64, .gpr64, .rax), .expected_error = error.ValueUseForwardPlanMissing },
    };
    for (cases) |case| {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        _ = try transaction.register(case.request);
        try std.testing.expectError(case.expected_error, transaction.seal());
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }

    try selector_state.bindValueLoc(&selector, "missing-index", .{ .scratch64 = .r8 });
    try selector_state.bindValueLoc(&selector, "pointer", .{ .stack_i32_ptr = .{
        .disp = 4,
        .index = .{ .reg = .r8, .name = "missing-index" },
    } });
    _ = selector.values.remove("missing-index");
    var missing_dependency = try Transaction.begin(&selector);
    defer missing_dependency.deinit();
    const missing_dependency_handle = try missing_dependency.register(
        request("pointer", .ptr, .stack_pointer, .pointer, .rax),
    );
    try std.testing.expectError(error.AddressDependencyMissingBinding, missing_dependency.seal());
    try std.testing.expect(missing_dependency.failedRequestIs(missing_dependency_handle));

    var stack_arg = try Transaction.begin(&selector);
    defer stack_arg.deinit();
    _ = try stack_arg.register(.{
        .source = .null_value,
        .expected = expected(.ptr, .gpr64),
        .form = .stack_argument,
        .destination = .{ .stack_argument = 0 },
    });
    try std.testing.expectError(error.ValueUseStackArgumentUnsupported, stack_arg.seal());

    var new_pair = try Transaction.begin(&selector);
    defer new_pair.deinit();
    _ = try new_pair.register(.{
        .source = .null_value,
        .expected = expected(.ptr, .gpr64),
        .form = .new_pair_ownership,
        .destination = .new_pair,
    });
    try std.testing.expectError(error.ValueUseNewPairOwnershipUnsupported, new_pair.seal());
}
