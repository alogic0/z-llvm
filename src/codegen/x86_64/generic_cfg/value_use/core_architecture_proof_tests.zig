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
    // Two seven-node bitmaps add sixteen bytes including alignment to the
    // bounded store plan. There is still only one binding/rollback snapshot.
    try std.testing.expectEqual(@as(usize, 366288), @sizeOf(Transaction));
    try std.testing.expectEqual(@as(usize, 16), @alignOf(Transaction));
    const expected_layout = .{
        .{ "selector", 356544 },
        .{ "snapshot", 36624 },
        .{ "requests", 0 },
        .{ "request_count", 366198 },
        .{ "request_phase", 366197 },
        .{ "lifecycle", 366196 },
        .{ "write_nodes", 366189 },
        .{ "parallel_sources", 366182 },
        .{ "transfer_nodes", 366175 },
        .{ "store_address_registers", 366111 },
        .{ "early_plans", 365804 },
        .{ "semantic_order_edges", 365839 },
        .{ "ordered_operands", 366200 },
        .{ "ordered_operand_count", 365838 },
        .{ "early_homes", 35088 },
        .{ "early_home_valid", 366095 },
        .{ "prepared_views", 356552 },
        .{ "prepared_view_valid", 366143 },
        .{ "switch_boundary_applied", 366159 },
        .{ "view_generation", 365800 },
        .{ "action_diagnostic", 365768 },
        .{ "lifetime_context", 186816 },
        .{ "failed_request", 186792 },
        .{ "accumulator_session", 186624 },
        .{ "call_action", 33280 },
        .{ "call_action_executed", 366199 },
        .{ "call_test_failure", 365836 },
        .{ "call_test_argument_index", 366248 },
        .{ "memcpy_test_failure", 366249 },
        .{ "load_test_failure", 366251 },
        .{ "scratch_compare_test_failure", 366253 },
        .{ "current_home_eq_zero_test_failure", 366255 },
        .{ "setcc_eax_compare_test_failure", 366257 },
        .{ "current_home_sign_bit_test_failure", 366259 },
        .{ "i128_eq_min_test_failure", 366261 },
        .{ "i128_sign_bit_test_failure", 366263 },
        .{ "scalar_cast_test_failure", 366265 },
        .{ "immediate_scalar_test_failure", 366267 },
        .{ "named_scalar_test_failure", 366269 },
        .{ "scalar_multiply_test_failure", 366271 },
        .{ "unsigned_quotient_test_failure", 366273 },
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
