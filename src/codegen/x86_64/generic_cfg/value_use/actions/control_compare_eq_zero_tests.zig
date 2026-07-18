const support = @import("../test_support.zig");

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

test "value-use dormant current-home eq-zero action reproduces every admitted home" {
    try executeCurrentHomeEqZeroCase(
        .{ .int = 32 },
        .eax,
        .gpr32,
        32,
        &.{ .test_eax_eax, .sete_eax },
    );
    try executeCurrentHomeEqZeroCase(
        .{ .int = 64 },
        .rax,
        .gpr64,
        64,
        &.{ .test_rax_rax, .sete_eax },
    );
    try executeCurrentHomeEqZeroCase(
        .{ .int = 13 },
        .{ .arg32 = .r8 },
        .gpr32,
        32,
        &.{ .{ .test_arg32 = .r8 }, .sete_eax },
    );
    try executeCurrentHomeEqZeroCase(
        .{ .int = 64 },
        .{ .scratch64 = .r9 },
        .gpr64,
        64,
        &.{ .{ .test_arg64 = .r9 }, .sete_eax },
    );
    try executeCurrentHomeEqZeroCase(
        .{ .int = 32 },
        .{ .spill64 = .slot2 },
        .gpr64,
        64,
        &.{
            .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = .slot2 } },
            .{ .test_arg32 = .rcx },
            .sete_eax,
        },
    );
    try executeCurrentHomeEqZeroCase(
        .{ .int = 64 },
        .{ .spill64 = .slot3 },
        .gpr64,
        64,
        &.{
            .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot3 } },
            .{ .test_arg64 = .rcx },
            .sete_eax,
        },
    );
}
test "value-use current-home eq-zero preserves accumulator sources then re-resolves canonically" {
    const Case = struct {
        ty: ir.Type,
        source_loc: ValueLoc,
        expected_preserve: machine_module.Instruction,
        expected_test: machine_module.Instruction,
        expected_source: ValueLoc,
    };
    const cases = [_]Case{
        .{
            .ty = .{ .int = 32 },
            .source_loc = .eax,
            .expected_preserve = .{ .mov_eax_to_arg = .rdi },
            .expected_test = .{ .test_arg32 = .rdi },
            .expected_source = .{ .scratch32 = .rdi },
        },
        .{
            .ty = .{ .int = 64 },
            .source_loc = .rax,
            .expected_preserve = .{ .mov_rax_to_arg = .rdi },
            .expected_test = .{ .test_arg64 = .rdi },
            .expected_source = .{ .scratch64 = .rdi },
        },
    };
    for (cases) |case| {
        var machine = MachineFunction.init("value-use-current-home-eq-zero-refresh", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addLive(&plan, "source");
        try addAtCurrent(&plan, "result");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "source", case.source_loc);

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerCurrentHomeEqZero(
            &transaction,
            .{ .named = "source" },
            "result",
            case.ty,
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(source));
        try transaction.commit();

        try std.testing.expectEqualSlices(machine_module.Instruction, &.{
            case.expected_preserve,
            case.expected_test,
            .sete_eax,
        }, machine.instructions.items);
        try std.testing.expectEqual(case.expected_source, selector.values.get("source").?.loc);
        try std.testing.expectEqual(ValueLoc.eax, selector.values.get("result").?.loc);
        try std.testing.expectEqual(@as(usize, 2), selector.eflags_semantics.items.len);
    }
}
test "value-use current-home eq-zero preserves the test definition through preparation" {
    var machine = MachineFunction.init("value-use-current-home-eq-zero-flags", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "source");
    try addLive(&plan, "prior-result");
    try addAtCurrent(&plan, "result");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg32 = .rsi });
    try selector_state.bindValueLoc(&selector, "prior-result", .eax);

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const source = try registerCurrentHomeEqZero(
        &transaction,
        .{ .named = "source" },
        "result",
        .{ .int = 32 },
    );
    try transaction.seal();
    _ = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(source));
    try transaction.commit();

    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_eax_to_arg = .rdi },
        .{ .test_arg32 = .rsi },
        .sete_eax,
    }, machine.instructions.items);
    try std.testing.expectEqual(selector_state.EflagsEffect.definition, selector.eflags_semantics.items[0].effect);
    try std.testing.expectEqual(selector_state.EflagsEffect.use, selector.eflags_semantics.items[1].effect);
}
test "value-use current-home eq-zero keeps unresolved width and location diagnostics distinct" {
    {
        var machine = MachineFunction.init("value-use-current-home-eq-zero-unresolved", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerCurrentHomeEqZero(
            &transaction,
            .{ .named = "source" },
            "result",
            .{ .int = 64 },
        );
        const err = transaction.seal();
        try std.testing.expectError(error.ValueUseForwardPlanMissing, err);
        try std.testing.expectEqualStrings(
            "composed-block-icmp-lhs",
            currentHomeEqZeroDiagnosticForTest(&transaction, source, error.ValueUseUnresolvedSource).?,
        );
    }
    {
        var machine = MachineFunction.init("value-use-current-home-eq-zero-width", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "source", .{ .arg64 = .rdi });

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerCurrentHomeEqZero(
            &transaction,
            .{ .named = "source" },
            "result",
            .{ .int = 32 },
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        const err = transaction.executePreparedAction(try transaction.preparedView(source));
        try std.testing.expectError(error.ValueUseCurrentHomeEqZeroWidthUnsupported, err);
        try std.testing.expectEqualStrings(
            "composed-block-icmp-lhs-width",
            currentHomeEqZeroDiagnosticForTest(
                &transaction,
                source,
                error.ValueUseCurrentHomeEqZeroWidthUnsupported,
            ).?,
        );
    }
    {
        var machine = MachineFunction.init("value-use-current-home-eq-zero-spill128", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "source", .{ .spill128 = .{
            .lo = .slot0,
            .hi = .slot1,
        } });

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerCurrentHomeEqZero(
            &transaction,
            .{ .named = "source" },
            "result",
            .{ .int = 64 },
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        const err = transaction.executePreparedAction(try transaction.preparedView(source));
        try std.testing.expectError(error.ValueUseCurrentHomeEqZeroLocationUnsupported, err);
        try std.testing.expectEqualStrings(
            "composed-block-icmp-lhs-loc",
            currentHomeEqZeroDiagnosticForTest(
                &transaction,
                source,
                error.ValueUseCurrentHomeEqZeroLocationUnsupported,
            ).?,
        );
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
}
test "value-use current-home eq-zero result remains durable across teardown and zext" {
    var machine = MachineFunction.init("value-use-current-home-eq-zero-then-zext", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("source", 1);
    try plan.interval_ends.put("%7", 2);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg32 = .rdi });

    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerCurrentHomeEqZero(
            &transaction,
            .{ .named = "source" },
            "%7",
            .{ .int = 32 },
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(source));
        try transaction.commit();
    }

    try std.testing.expectEqual(ValueLoc.eax, selector_state.resolveValue(&selector, .{ .named = "%7" }).?);
    selector.current_position = 2;
    const diagnostic = try selector_scalar.lowerCast(&selector, "%zext", .{
        .op = .zext,
        .value = .{ .named = "%7" },
        .from_ty = .{ .int = 1 },
        .to_ty = .{ .int = 32 },
    });
    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc.eax, selector_state.resolveValue(&selector, .{ .named = "%zext" }).?);
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .test_arg32 = .rdi },
        .sete_eax,
        .{ .and_eax_imm32 = 1 },
    }, machine.instructions.items);
}
test "value-use current-home eq-zero rollback is exact after test and preparation" {
    const boundaries = [_]Transaction.CurrentHomeEqZeroTestFailure{
        .after_test_definition,
        .after_accumulator_preparation,
    };
    for (boundaries) |boundary| {
        var machine = MachineFunction.init("value-use-current-home-eq-zero-rollback", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        try addLive(&plan, "live-accumulator");
        try addAtCurrent(&plan, "result");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 128;
        selector.next_spill_slot = 1;
        try selector_state.bindValueLoc(&selector, "source", .{ .arg32 = .rsi });
        try selector_state.bindValueLoc(&selector, "live-accumulator", .eax);
        const saved_source = selector.values.get("source").?;
        const saved_accumulator = selector.values.get("live-accumulator").?;
        const saved_next_vreg = selector.next_virtual_reg;
        const saved_next_spill = selector.next_spill_slot;
        const saved_domain = selector.address_dependencies;
        const saved_eflags = selector.eflags.snapshot();
        const saved_semantics = selector.eflags_semantics.items.len;

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerCurrentHomeEqZero(
            &transaction,
            .{ .named = "source" },
            "result",
            .{ .int = 32 },
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.setCurrentHomeEqZeroTestFailure(boundary);
        try std.testing.expectError(
            error.ValueUseCurrentHomeEqZeroTestFailure,
            transaction.executePreparedAction(try transaction.preparedView(source)),
        );

        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(saved_source, selector.values.get("source").?);
        try std.testing.expectEqual(saved_accumulator, selector.values.get("live-accumulator").?);
        try std.testing.expect(selector.values.get("result") == null);
        try std.testing.expectEqual(saved_next_vreg, selector.next_virtual_reg);
        try std.testing.expectEqual(saved_next_spill, selector.next_spill_slot);
        try std.testing.expect(selector.address_dependencies.eql(&saved_domain));
        try selector.eflags.validateSnapshot(saved_eflags);
        try std.testing.expectEqual(saved_semantics, selector.eflags_semantics.items.len);
        try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
        try std.testing.expectError(error.ValueUseTransactionClosed, transaction.rollback());
    }
}
