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

test "value-use generic transaction layout pins bounded store and parallel plans" {
    // Owned 512-byte identities with u16 lengths add 322,368 bytes over the
    // 192-byte layout. The transaction remains bounded, with one snapshot.
    try std.testing.expectEqual(@as(usize, 688656), @sizeOf(Transaction));
    try std.testing.expectEqual(@as(usize, 16), @alignOf(Transaction));
    const expected_layout = .{
        .{ "selector", 668672 },
        .{ "snapshot", 90704 },
        .{ "requests", 0 },
        .{ "request_count", 688566 },
        .{ "request_phase", 688565 },
        .{ "lifecycle", 688564 },
        .{ "write_nodes", 688557 },
        .{ "parallel_sources", 688550 },
        .{ "transfer_nodes", 688543 },
        .{ "store_address_registers", 688479 },
        .{ "early_plans", 688172 },
        .{ "semantic_order_edges", 688207 },
        .{ "ordered_operands", 688568 },
        .{ "ordered_operand_count", 688206 },
        .{ "early_homes", 89168 },
        .{ "early_home_valid", 688463 },
        .{ "prepared_views", 668680 },
        .{ "prepared_view_valid", 688511 },
        .{ "switch_boundary_applied", 688527 },
        .{ "view_generation", 688168 },
        .{ "action_diagnostic", 688136 },
        .{ "lifetime_context", 240896 },
        .{ "failed_request", 240872 },
        .{ "accumulator_session", 240704 },
        .{ "call_action", 84480 },
        .{ "call_action_executed", 688567 },
        .{ "call_test_failure", 688204 },
        .{ "call_test_argument_index", 688616 },
        .{ "memcpy_test_failure", 688617 },
        .{ "load_test_failure", 688619 },
        .{ "scratch_compare_test_failure", 688621 },
        .{ "current_home_eq_zero_test_failure", 688623 },
        .{ "setcc_eax_compare_test_failure", 688625 },
        .{ "current_home_sign_bit_test_failure", 688627 },
        .{ "i128_eq_min_test_failure", 688629 },
        .{ "i128_sign_bit_test_failure", 688631 },
        .{ "scalar_cast_test_failure", 688633 },
        .{ "immediate_scalar_test_failure", 688635 },
        .{ "named_scalar_test_failure", 688637 },
        .{ "scalar_multiply_test_failure", 688639 },
        .{ "unsigned_quotient_test_failure", 688641 },
    };
    inline for (expected_layout) |field|
        try std.testing.expectEqual(@as(usize, field[1]), @offsetOf(Transaction, field[0]));
}
test "value-use facade methods retain finite reachable error sets" {
    inline for (comptime std.meta.declarations(Transaction)) |declaration| {
        const declaration_type = @TypeOf(@field(Transaction, declaration));
        switch (@typeInfo(declaration_type)) {
            .@"fn" => |function| {
                const return_type = function.return_type orelse continue;
                switch (@typeInfo(return_type)) {
                    .error_union => |error_union| try std.testing.expect(
                        @typeInfo(error_union.error_set).error_set.error_names != null,
                    ),
                    else => {},
                }
            },
            else => {},
        }
    }
}
