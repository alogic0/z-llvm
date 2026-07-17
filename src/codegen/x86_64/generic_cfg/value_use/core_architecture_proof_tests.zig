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
    try std.testing.expectEqual(@as(usize, 194688), @sizeOf(Transaction));
    try std.testing.expectEqual(@as(usize, 16), @alignOf(Transaction));
    const expected_layout = .{
        .{ "selector", 185040 },
        .{ "snapshot", 34816 },
        .{ "requests", 0 },
        .{ "request_count", 194662 },
        .{ "request_phase", 194661 },
        .{ "lifecycle", 194660 },
        .{ "write_nodes", 194653 },
        .{ "early_plans", 194605 },
        .{ "semantic_order_edges", 194349 },
        .{ "ordered_operands", 194285 },
        .{ "ordered_operand_count", 194284 },
        .{ "early_homes", 33280 },
        .{ "early_home_valid", 194333 },
        .{ "prepared_views", 185048 },
        .{ "prepared_view_valid", 194268 },
        .{ "switch_boundary_applied", 194637 },
        .{ "view_generation", 194264 },
        .{ "action_diagnostic", 185008 },
        .{ "failed_request", 184984 },
        .{ "accumulator_session", 184816 },
        .{ "memcpy_test_failure", 194663 },
        .{ "load_test_failure", 194665 },
        .{ "scratch_compare_test_failure", 194667 },
        .{ "current_home_eq_zero_test_failure", 194669 },
        .{ "setcc_eax_compare_test_failure", 194671 },
        .{ "current_home_sign_bit_test_failure", 194673 },
        .{ "i128_eq_min_test_failure", 194675 },
        .{ "i128_sign_bit_test_failure", 194677 },
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
