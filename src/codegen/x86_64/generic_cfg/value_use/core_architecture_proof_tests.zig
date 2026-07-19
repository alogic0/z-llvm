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

test "value-use generic transaction layout matches frozen R0" {
    try std.testing.expectEqual(@as(usize, 363920), @sizeOf(Transaction));
    try std.testing.expectEqual(@as(usize, 16), @alignOf(Transaction));
    const expected_layout = .{
        .{ "selector", 354256 },
        .{ "snapshot", 34816 },
        .{ "requests", 0 },
        .{ "request_count", 363878 },
        .{ "request_phase", 363877 },
        .{ "lifecycle", 363876 },
        .{ "write_nodes", 363869 },
        .{ "early_plans", 363837 },
        .{ "semantic_order_edges", 363484 },
        .{ "ordered_operands", 363757 },
        .{ "ordered_operand_count", 363740 },
        .{ "early_homes", 33280 },
        .{ "early_home_valid", 363741 },
        .{ "prepared_views", 354264 },
        .{ "prepared_view_valid", 363805 },
        .{ "switch_boundary_applied", 363821 },
        .{ "view_generation", 363480 },
        .{ "action_diagnostic", 354224 },
        .{ "lifetime_context", 185008 },
        .{ "failed_request", 184984 },
        .{ "accumulator_session", 184816 },
        .{ "memcpy_test_failure", 363879 },
        .{ "load_test_failure", 363881 },
        .{ "scratch_compare_test_failure", 363883 },
        .{ "current_home_eq_zero_test_failure", 363885 },
        .{ "setcc_eax_compare_test_failure", 363887 },
        .{ "current_home_sign_bit_test_failure", 363889 },
        .{ "i128_eq_min_test_failure", 363891 },
        .{ "i128_sign_bit_test_failure", 363893 },
        .{ "scalar_cast_test_failure", 363895 },
        .{ "immediate_scalar_test_failure", 363897 },
        .{ "named_scalar_test_failure", 363899 },
        .{ "scalar_multiply_test_failure", 363901 },
        .{ "unsigned_quotient_test_failure", 363903 },
    };
    inline for (expected_layout) |field|
        try std.testing.expectEqual(@as(usize, field[1]), @offsetOf(Transaction, field[0]));
}
test "value-use facade methods retain finite reachable error sets" {
    inline for (comptime std.meta.declarations(Transaction)) |declaration| {
        const declaration_type = @TypeOf(@field(Transaction, declaration.name));
        switch (@typeInfo(declaration_type)) {
            .@"fn" => |function| {
                const return_type = function.return_type orelse continue;
                switch (@typeInfo(return_type)) {
                    .error_union => |error_union| try std.testing.expect(
                        @typeInfo(error_union.error_set).error_set != null,
                    ),
                    else => {},
                }
            },
            else => {},
        }
    }
}
