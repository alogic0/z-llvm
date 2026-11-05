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

test "value-use generic transaction layout pins the bounded store plan" {
    // The R0-derived transaction grows by exactly 32 bytes for sixteen
    // optional address registers. No extra binding or rollback snapshot is
    // introduced. Pin the compiler's resulting field placement explicitly.
    try std.testing.expectEqual(@as(usize, 366272), @sizeOf(Transaction));
    try std.testing.expectEqual(@as(usize, 16), @alignOf(Transaction));
    const expected_layout = .{
        .{ "selector", 356544 },
        .{ "snapshot", 36624 },
        .{ "requests", 0 },
        .{ "request_count", 366231 },
        .{ "request_phase", 366230 },
        .{ "lifecycle", 366229 },
        .{ "write_nodes", 366222 },
        .{ "store_address_registers", 366190 },
        .{ "early_plans", 366158 },
        .{ "semantic_order_edges", 365804 },
        .{ "ordered_operands", 366078 },
        .{ "ordered_operand_count", 366233 },
        .{ "early_homes", 35088 },
        .{ "early_home_valid", 366062 },
        .{ "prepared_views", 356584 },
        .{ "prepared_view_valid", 366126 },
        .{ "switch_boundary_applied", 366142 },
        .{ "view_generation", 365800 },
        .{ "action_diagnostic", 356552 },
        .{ "lifetime_context", 186816 },
        .{ "failed_request", 186792 },
        .{ "accumulator_session", 186624 },
        .{ "call_action", 33280 },
        .{ "call_action_executed", 366232 },
        .{ "call_test_failure", 366060 },
        .{ "call_test_argument_index", 366234 },
        .{ "memcpy_test_failure", 366235 },
        .{ "load_test_failure", 366237 },
        .{ "scratch_compare_test_failure", 366239 },
        .{ "current_home_eq_zero_test_failure", 366241 },
        .{ "setcc_eax_compare_test_failure", 366243 },
        .{ "current_home_sign_bit_test_failure", 366245 },
        .{ "i128_eq_min_test_failure", 366247 },
        .{ "i128_sign_bit_test_failure", 366249 },
        .{ "scalar_cast_test_failure", 366251 },
        .{ "immediate_scalar_test_failure", 366253 },
        .{ "named_scalar_test_failure", 366255 },
        .{ "scalar_multiply_test_failure", 366257 },
        .{ "unsigned_quotient_test_failure", 366259 },
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
