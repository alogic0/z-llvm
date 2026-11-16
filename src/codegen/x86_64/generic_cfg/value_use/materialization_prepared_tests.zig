const table_descriptions = @import("../../constant_table.zig").Description;
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

test "value-use transaction exposes every restricted prepared-view member and both pair orders" {
    var machine = MachineFunction.init("value-use-prepared-views", .ptr);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "reg", "spill", "stack", "index", "addend", "address", "table", "table-reg", "pair-lo", "pair-hi" }) |name|
        try addLive(&plan, name);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "reg", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "spill", .{ .spill64 = .slot0 });
    try selector_state.bindValueLoc(&selector, "stack", .{ .stack_scalar = .{ .base_disp = 16, .bits = 64 } });
    try selector_state.bindValueLoc(&selector, "index", .{ .scratch64 = .r8 });
    try selector_state.bindValueLoc(&selector, "addend", .{ .spill64 = .slot1 });
    try selector_state.bindValueLoc(&selector, "address", .{ .stack_i32_ptr = .{
        .disp = 24,
        .index = .{ .reg = .r8, .name = "index", .addend_name = "addend" },
    } });
    try selector_state.bindValueLoc(&selector, "table", .{ .readonly_table_ptr = .{
        .storage = .{ .spill = .slot2 },
        .symbol = "@prepared-table",
        .shape = table_descriptions.i16_128,
        .offset = 3,
    } });
    try selector_state.bindValueLoc(&selector, "table-reg", .{ .readonly_table_ptr = .{
        .storage = .{ .reg = .r9 },
        .symbol = "@prepared-table-reg",
        .shape = table_descriptions.i16_128,
    } });
    try selector_state.bindValueLoc(&selector, "pair-lo", .{ .arg128 = .{ .lo = .rcx, .hi = .rdx } });
    try selector_state.bindValueLoc(&selector, "pair-hi", .{ .spill128 = .{ .lo = .slot3, .hi = .slot4 } });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const handles = [_]Transaction.RequestHandle{
        try transaction.register(preparedRequest("reg", .{ .int = 64 }, .gpr64, .gpr64, .{ .validate_shape = .{ .register_gpr64 = .rdi } })),
        try transaction.register(preparedRequest("spill", .{ .int = 64 }, .gpr64, .gpr64, .{ .validate_shape = .{ .scalar_spill = .slot0 } })),
        try transaction.register(preparedRequest("stack", .ptr, .stack_object, .stack_object_address, .{ .validate_shape = .{ .stack_scalar = 16 } })),
        try transaction.register(preparedRequest("address", .ptr, .stack_pointer, .pointer, .{ .validate_shape = .{ .address_descriptor = .{ .has_index = true, .has_addend = true } } })),
        try transaction.register(preparedRequest("table", .ptr, .stack_pointer, .pointer, .{ .validate_shape = .{ .table_spill = .slot2 } })),
        try transaction.register(preparedRequest("table-reg", .ptr, .stack_pointer, .pointer, .{ .validate_shape = .{ .table_register = .r9 } })),
        try transaction.register(preparedRequest("pair-lo", .{ .int = 128 }, .gpr128, .pair_low_high, .{ .validate_shape = .{ .pair_register = .{ .lo = .rcx, .hi = .rdx } } })),
        try transaction.register(preparedRequest("pair-hi", .{ .int = 128 }, .gpr128, .pair_high_low, .{ .validate_shape = .{ .pair_spill = .{ .lo = .slot4, .hi = .slot3 } } })),
    };
    try transaction.seal();
    try std.testing.expectError(error.ValueUsePreparedViewUnavailable, transaction.preparedView(handles[0]));
    try transaction.prepare();
    try transaction.materializeAll();

    for (handles) |handle| {
        const lease = try transaction.preparedView(handle);
        try transaction.executePreparedAction(lease);
    }
    try transaction.commit();
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}
test "value-use repeated sources separate destinations and preserve once before re-resolution" {
    var machine = MachineFunction.init("value-use-multi-destination", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "writer", "shared" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "writer", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "shared", .{ .arg64 = .rsi });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    _ = try transaction.register(request("writer", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rsi }));
    const first = try transaction.register(request("shared", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rdx }));
    const coalesced = try transaction.register(request("shared", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rdx }));
    const second = try transaction.register(request("shared", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .r8 }));
    try std.testing.expectEqual(first, coalesced);
    try std.testing.expect(first.index != second.index);
    try transaction.seal();
    try transaction.prepare();
    try std.testing.expect(selector.values.get("shared").?.loc == .spill64);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try transaction.materializeAll();
    try transaction.commit();
    try std.testing.expectEqual(@as(usize, 4), machine.instructions.items.len);
}
