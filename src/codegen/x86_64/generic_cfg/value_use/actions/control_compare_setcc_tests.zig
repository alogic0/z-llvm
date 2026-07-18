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

test "value-use dormant setcc EAX compare action reproduces all ten audited forms" {
    const write_definition_use = &.{
        selector_state.EflagsEffect.write,
        selector_state.EflagsEffect.definition,
        selector_state.EflagsEffect.use,
    };
    const definition_use = &.{
        selector_state.EflagsEffect.definition,
        selector_state.EflagsEffect.use,
    };
    try executeSetccEaxCompareCase(
        .{ .int = 5 },
        .slt,
        false,
        -1,
        .exact_ei,
        .{ .arg32 = .rdi },
        .gpr32,
        32,
        &.{
            .{ .mov_arg_eax = .rdi },
            .{ .and_eax_imm32 = 31 },
            .{ .shl_eax_imm5 = 27 },
            .{ .sar_eax_imm5 = 27 },
            .{ .cmp_eax_imm32 = -1 },
            .setl_eax,
        },
        &.{
            .write,
            .write,
            .write,
            .definition,
            .use,
        },
    );
    try executeSetccEaxCompareCase(
        .{ .int = 32 },
        .eq,
        false,
        7,
        .ordinary,
        .{ .arg32 = .rdi },
        .gpr32,
        32,
        &.{ .{ .mov_arg_eax = .rdi }, .{ .cmp_eax_imm32 = 7 }, .sete_eax },
        definition_use,
    );
    inline for ([_]struct { bits: u16, mask: i32 }{
        .{ .bits = 6, .mask = 32 },
        .{ .bits = 16, .mask = 32768 },
        .{ .bits = 32, .mask = std.math.minInt(i32) },
    }) |case| {
        try executeSetccEaxCompareCase(
            .{ .int = case.bits },
            .sgt,
            false,
            -1,
            .ordinary,
            .{ .arg32 = .rdi },
            .gpr32,
            32,
            &.{ .{ .mov_arg_eax = .rdi }, .{ .and_eax_imm32 = case.mask }, .sete_eax },
            definition_use,
        );
    }
    try executeSetccEaxCompareCase(
        .{ .int = 32 },
        .sgt,
        false,
        9,
        .ordinary,
        .{ .arg32 = .rdi },
        .gpr32,
        32,
        &.{ .{ .mov_arg_eax = .rdi }, .{ .cmp_eax_imm32 = 9 }, .setg_eax },
        definition_use,
    );
    try executeSetccEaxCompareCase(
        .{ .int = 32 },
        .slt,
        false,
        -7,
        .ordinary,
        .{ .arg32 = .rdi },
        .gpr32,
        32,
        &.{ .{ .mov_arg_eax = .rdi }, .{ .cmp_eax_imm32 = -7 }, .setl_eax },
        definition_use,
    );
    try executeSetccEaxCompareCase(
        .{ .int = 6 },
        .ugt,
        true,
        12,
        .ordinary,
        .{ .arg32 = .rdi },
        .gpr32,
        32,
        &.{
            .{ .mov_arg_eax = .rdi },
            .{ .and_eax_imm32 = 63 },
            .{ .cmp_eax_imm32 = 12 },
            .seta_eax,
        },
        write_definition_use,
    );
    try executeSetccEaxCompareCase(
        .{ .int = 6 },
        .ult,
        false,
        51,
        .ordinary,
        .{ .arg32 = .rdi },
        .gpr32,
        32,
        &.{
            .{ .mov_arg_eax = .rdi },
            .{ .and_eax_imm32 = 63 },
            .{ .cmp_eax_imm32 = 51 },
            .setb_eax,
        },
        write_definition_use,
    );
    try executeSetccEaxCompareCase(
        .{ .int = 32 },
        .ult,
        false,
        99,
        .ordinary,
        .{ .arg32 = .rdi },
        .gpr32,
        32,
        &.{ .{ .mov_arg_eax = .rdi }, .{ .cmp_eax_imm32 = 99 }, .setb_eax },
        definition_use,
    );
}
test "value-use setcc EAX compare preserves live accumulator then re-resolves canonically" {
    var machine = MachineFunction.init("value-use-setcc-eax-compare-preamble", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addLive(&plan, "source");
    try addAtCurrent(&plan, "result");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .eax);

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const source = try registerSetccEaxCompare(
        &transaction,
        .{ .named = "source" },
        "result",
        .{ .int = 32 },
        .ult,
        false,
        8,
        .ordinary,
    );
    try transaction.seal();
    _ = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(source));
    try transaction.commit();

    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_eax_to_arg = .rdi },
        .{ .mov_arg_eax = .rdi },
        .{ .cmp_eax_imm32 = 8 },
        .setb_eax,
    }, machine.instructions.items);
    try std.testing.expectEqual(ValueLoc{ .scratch32 = .rdi }, selector.values.get("source").?.loc);
}
test "value-use setcc EAX compare preserves preparation points and diagnostics" {
    // The sign-bit definition follows preparation; compare definitions
    // precede preparation and remain live through their setcc consumer.
    try executeSetccEaxCompareCase(
        .{ .int = 16 },
        .sgt,
        false,
        -1,
        .ordinary,
        .{ .spill64 = .slot2 },
        .gpr32,
        32,
        &.{
            .{ .reload_rsp_eax = .slot2 },
            .{ .and_eax_imm32 = 32768 },
            .sete_eax,
        },
        &.{ .definition, .use },
    );

    var machine = MachineFunction.init("value-use-setcc-eax-compare-diagnostics", .{ .int = 1 });
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
    const source = try registerSetccEaxCompare(
        &transaction,
        .{ .named = "source" },
        "result",
        .{ .int = 32 },
        .ult,
        false,
        1,
        .ordinary,
    );
    try transaction.seal();
    _ = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    const err = transaction.executePreparedAction(try transaction.preparedView(source));
    try std.testing.expectError(error.ValueUseSetccEaxCompareLocationUnsupported, err);
    try std.testing.expectEqualStrings(
        "composed-block-icmp-lhs-loc",
        setccEaxCompareDiagnosticForTest(
            &transaction,
            source,
            error.ValueUseSetccEaxCompareLocationUnsupported,
        ).?,
    );
}
test "value-use setcc EAX compare keeps exact-EI admission and excluded forms closed" {
    var machine = MachineFunction.init("value-use-setcc-eax-compare-closed-forms", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "source");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg32 = .rdi });

    inline for ([_]struct {
        ty: ir.Type,
        predicate: ir.IcmpPredicate,
        immediate: i128,
        structure: Transaction.SetccEaxCompareStructure,
        expected_error: anyerror,
    }{
        .{
            .ty = .{ .int = 12 },
            .predicate = .eq,
            .immediate = 1,
            .structure = .exact_ei,
            .expected_error = error.ValueUseSetccEaxCompareFormUnsupported,
        },
        .{
            .ty = .{ .int = 55 },
            .predicate = .eq,
            .immediate = 1,
            .structure = .exact_ei,
            .expected_error = error.ValueUseSetccEaxCompareExactEiWidthUnsupported,
        },
        .{
            .ty = .{ .int = 32 },
            .predicate = .slt,
            .immediate = 0,
            .structure = .ordinary,
            .expected_error = error.ValueUseSetccEaxCompareFormUnsupported,
        },
        .{
            .ty = .{ .int = 64 },
            .predicate = .ult,
            .immediate = 1,
            .structure = .ordinary,
            .expected_error = error.ValueUseSetccEaxCompareFormUnsupported,
        },
    }) |case| {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerSetccEaxCompare(
            &transaction,
            .{ .named = "source" },
            "result",
            case.ty,
            case.predicate,
            false,
            case.immediate,
            case.structure,
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        try std.testing.expectError(
            case.expected_error,
            transaction.executePreparedAction(try transaction.preparedView(source)),
        );
        try std.testing.expect(!transaction.failedRequestIs(source));
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
}
test "value-use setcc EAX compare rejects existing pair homes without mutation" {
    var machine = MachineFunction.init("value-use-setcc-eax-compare-pair-reject", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "source");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg128 = .{
        .lo = .rdi,
        .hi = .rsi,
    } });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const source = try registerSetccEaxCompare(
        &transaction,
        .{ .named = "source" },
        "result",
        .{ .int = 32 },
        .ult,
        false,
        1,
        .ordinary,
    );
    try transaction.seal();
    _ = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    try std.testing.expectError(
        error.ValueUseSetccEaxCompareLocationUnsupported,
        transaction.executePreparedAction(try transaction.preparedView(source)),
    );
    try std.testing.expect(transaction.failedRequestIs(source));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}
test "value-use setcc EAX compare preserves unresolved-source provenance" {
    var machine = MachineFunction.init("value-use-setcc-eax-compare-unresolved", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "source");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const source = try registerSetccEaxCompare(
        &transaction,
        .{ .named = "source" },
        "result",
        .{ .int = 32 },
        .ult,
        false,
        1,
        .ordinary,
    );
    try std.testing.expectError(error.ValueUseForwardPlanMissing, transaction.seal());
    try std.testing.expectEqualStrings(
        "composed-block-icmp-lhs",
        setccEaxCompareDiagnosticForTest(
            &transaction,
            source,
            error.ValueUseUnresolvedSource,
        ).?,
    );
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}
test "value-use setcc EAX compare authority failures are unattributed" {
    var machine = MachineFunction.init("value-use-setcc-eax-compare-authority-error", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "source");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg32 = .rdi });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const source = try registerSetccEaxCompare(
        &transaction,
        .{ .named = "source" },
        "result",
        .{ .int = 5 },
        .ule,
        false,
        1,
        .exact_ei,
    );
    try transaction.seal();
    _ = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    try std.testing.expectError(
        error.ValueUseSetccEaxComparePredicateUnsupported,
        transaction.executePreparedAction(try transaction.preparedView(source)),
    );
    try std.testing.expect(!transaction.failedRequestIs(source));
}
test "value-use setcc EAX compare preserves post-materialization immediate failure timing" {
    var machine = MachineFunction.init("value-use-setcc-eax-compare-immediate-timing", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "source");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg32 = .rdi });
    const saved_source = selector.values.get("source").?;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const source = try registerSetccEaxCompare(
        &transaction,
        .{ .named = "source" },
        "result",
        .{ .int = 32 },
        .sgt,
        false,
        @as(i128, std.math.maxInt(i32)) + 1,
        .ordinary,
    );
    try transaction.seal();
    _ = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    try std.testing.expectError(
        error.ValueUseSetccEaxCompareImmediateOutOfRange,
        transaction.executePreparedAction(try transaction.preparedView(source)),
    );
    try std.testing.expect(!transaction.failedRequestIs(source));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(saved_source, selector.values.get("source").?);
}
test "value-use setcc EAX compare result remains durable across teardown and zext" {
    var machine = MachineFunction.init("value-use-setcc-eax-compare-then-zext", .{ .int = 32 });
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
        const source = try registerSetccEaxCompare(
            &transaction,
            .{ .named = "source" },
            "%7",
            .{ .int = 32 },
            .ult,
            false,
            7,
            .ordinary,
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
    try std.testing.expect((try selector_scalar.lowerCast(&selector, "%zext", .{
        .op = .zext,
        .value = .{ .named = "%7" },
        .from_ty = .{ .int = 1 },
        .to_ty = .{ .int = 32 },
    })) == null);
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_arg_eax = .rdi },
        .{ .cmp_eax_imm32 = 7 },
        .setb_eax,
        .{ .and_eax_imm32 = 1 },
    }, machine.instructions.items);
}
test "value-use setcc EAX compare rollback is exact at all eight boundaries" {
    const boundaries = [_]Transaction.SetccEaxCompareTestFailure{
        .after_preamble,
        .after_materialization,
        .after_normalization_or_mask,
        .after_eflags_definition,
        .after_accumulator_preparation,
        .after_setcc,
        .after_result_definition,
        .after_finalization,
    };
    for (boundaries) |boundary| {
        var machine = MachineFunction.init("value-use-setcc-eax-compare-rollback", .{ .int = 1 });
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
        const source = try registerSetccEaxCompare(
            &transaction,
            .{ .named = "source" },
            "result",
            .{ .int = 6 },
            .ult,
            true,
            12,
            .ordinary,
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.setSetccEaxCompareTestFailure(boundary);
        try std.testing.expectError(
            error.ValueUseSetccEaxCompareTestFailure,
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
    }
}
