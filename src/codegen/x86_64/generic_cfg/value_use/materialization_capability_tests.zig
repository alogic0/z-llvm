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

test "value-use prepared capabilities reject source relocation before production-path emission" {
    var machine = MachineFunction.init("value-use-view-phases", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addLive(&plan, "source");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg64 = .rdi });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const handle = try transaction.register(preparedRequest(
        "source",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .validate_shape = .{ .register_gpr64 = .rdi } },
    ));
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    var missing = handle;
    missing.index = 15;
    try std.testing.expectError(error.ValueUsePreparedViewMissing, transaction.preparedView(missing));

    var invalidated = try Transaction.begin(&selector);
    defer invalidated.deinit();
    const invalidated_handle = try invalidated.register(preparedRequest(
        "source",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .emit_copy_to = .rax },
    ));
    try invalidated.seal();
    try invalidated.prepare();
    try invalidated.materializeAll();
    const lease = try invalidated.preparedView(invalidated_handle);

    // Use the production binding authority to relocate the source after the
    // capability is acquired. Canonical-record validation must reject the old
    // capability before the closed action can append an instruction.
    try selector_state.bindValueLoc(&selector, "source", .{ .arg64 = .rsi });
    try std.testing.expectError(error.ValueUsePreparedViewStale, invalidated.executePreparedAction(lease));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(ValueLoc{ .arg64 = .rdi }, selector.values.get("source").?.loc);

    // The same typed action emits from the internally held view when the
    // canonical source remains unchanged. No location crosses the API.
    var internal_emit = try Transaction.begin(&selector);
    defer internal_emit.deinit();
    const emit_handle = try internal_emit.register(preparedRequest(
        "source",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .emit_copy_to = .rax },
    ));
    try internal_emit.seal();
    try internal_emit.prepare();
    try internal_emit.materializeAll();
    const emit_lease = try internal_emit.preparedView(emit_handle);
    try internal_emit.executePreparedAction(emit_lease);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expect(machine.instructions.items[0] == .mov_arg_rax);
    try std.testing.expectEqual(selector_types.ArgReg.rdi, machine.instructions.items[0].mov_arg_rax);
    try std.testing.expectError(error.ValueUsePreparedViewMissing, internal_emit.executePreparedAction(emit_lease));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);

    var foreign = try Transaction.begin(&selector);
    defer foreign.deinit();
    const foreign_handle = try foreign.register(preparedRequest(
        "source",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .validate_shape = .{ .register_gpr64 = .rdi } },
    ));
    try foreign.seal();
    try foreign.prepare();
    try foreign.materializeAll();
    try std.testing.expectError(error.ValueUsePreparedViewStale, foreign.preparedView(invalidated_handle));
    _ = foreign_handle;
}
test "value-use mixed fixed and prepared requests resolve views only after fixed preparation" {
    var machine = MachineFunction.init("value-use-mixed-views", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "fixed", "view" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "fixed", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "view", .{ .arg64 = .rsi });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    _ = try transaction.register(request("fixed", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rsi }));
    const view_handle = try transaction.register(preparedRequest(
        "view",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .validate_shape = .{ .scalar_spill = .slot0 } },
    ));
    try transaction.seal();
    try transaction.prepare();
    try std.testing.expect(selector.values.get("view").?.loc == .spill64);
    try transaction.materializeAll();
    const lease = try transaction.preparedView(view_handle);
    try transaction.executePreparedAction(lease);
    try transaction.commit();
}
test "value-use prepared actions revalidate type class and canonical dependencies on every execution" {
    var machine = MachineFunction.init("value-use-view-revalidation", .ptr);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "scalar", "index", "address" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "scalar", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "index", .{ .arg64 = .r8 });
    try selector_state.bindValueLoc(&selector, "address", .{ .stack_i32_ptr = .{
        .disp = 4,
        .index = .{ .reg = .r8, .name = "index" },
    } });

    const scalar_binding = selector.values.get("scalar").?;
    var type_transaction = try Transaction.begin(&selector);
    defer type_transaction.deinit();
    const scalar_handle = try type_transaction.register(preparedRequest(
        "scalar",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .validate_shape = .{ .register_gpr64 = .rdi } },
    ));
    try type_transaction.seal();
    try type_transaction.prepare();
    try type_transaction.materializeAll();
    const scalar_lease = try type_transaction.preparedView(scalar_handle);
    selector.values.getPtr("scalar").?.vreg.class = .gpr32;
    try std.testing.expectError(error.ValueUseRegisterClassMismatch, type_transaction.executePreparedAction(scalar_lease));
    try std.testing.expectEqual(scalar_binding, selector.values.get("scalar").?);

    var dependency_transaction = try Transaction.begin(&selector);
    defer dependency_transaction.deinit();
    const address_handle = try dependency_transaction.register(preparedRequest(
        "address",
        .ptr,
        .stack_pointer,
        .pointer,
        .{ .validate_shape = .{ .address_descriptor = .{ .has_index = true, .has_addend = false } } },
    ));
    try dependency_transaction.seal();
    try dependency_transaction.prepare();
    try dependency_transaction.materializeAll();
    const address_lease = try dependency_transaction.preparedView(address_handle);
    _ = selector.values.remove("index");
    try std.testing.expectError(error.AddressDependencyMissingBinding, dependency_transaction.executePreparedAction(address_lease));
    try std.testing.expect(selector.values.get("index") != null);
}
