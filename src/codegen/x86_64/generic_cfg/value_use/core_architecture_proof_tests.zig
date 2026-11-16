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
    // Scoped source/prepared identities remove 418,672 inline bytes despite
    // adding explicit transaction namespaces. Action names remain bounded and
    // owned; the transaction still retains exactly one selector snapshot.
    try std.testing.expectEqual(@as(usize, 269984), @sizeOf(Transaction));
    try std.testing.expectEqual(@as(usize, 16), @alignOf(Transaction));
    const expected_layout = .{
        .{ "selector", 265912 },
        .{ "identity_namespace", 82768 },
        .{ "snapshot", 82776 },
        .{ "requests", 0 },
        .{ "request_count", 269902 },
        .{ "request_phase", 269901 },
        .{ "lifecycle", 269900 },
        .{ "write_nodes", 269893 },
        .{ "parallel_sources", 269886 },
        .{ "transfer_nodes", 269879 },
        .{ "store_address_registers", 269508 },
        .{ "early_plans", 269815 },
        .{ "semantic_order_edges", 269543 },
        .{ "ordered_operands", 269904 },
        .{ "ordered_operand_count", 269542 },
        .{ "early_homes", 81232 },
        .{ "early_home_valid", 269799 },
        .{ "prepared_views", 265920 },
        .{ "prepared_view_valid", 269847 },
        .{ "switch_boundary_applied", 269863 },
        .{ "view_generation", 269504 },
        .{ "action_diagnostic", 265880 },
        .{ "lifetime_context", 232984 },
        .{ "failed_request", 232952 },
        .{ "accumulator_session", 232784 },
        .{ "call_action", 76544 },
        .{ "call_action_executed", 269903 },
        .{ "call_test_failure", 269540 },
        .{ "call_test_argument_index", 269952 },
        .{ "memcpy_test_failure", 269953 },
        .{ "load_test_failure", 269955 },
        .{ "scratch_compare_test_failure", 269957 },
        .{ "current_home_eq_zero_test_failure", 269959 },
        .{ "setcc_eax_compare_test_failure", 269961 },
        .{ "current_home_sign_bit_test_failure", 269963 },
        .{ "i128_eq_min_test_failure", 269965 },
        .{ "i128_sign_bit_test_failure", 269967 },
        .{ "scalar_cast_test_failure", 269969 },
        .{ "immediate_scalar_test_failure", 269971 },
        .{ "named_scalar_test_failure", 269973 },
        .{ "scalar_multiply_test_failure", 269975 },
        .{ "unsigned_quotient_test_failure", 269977 },
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
