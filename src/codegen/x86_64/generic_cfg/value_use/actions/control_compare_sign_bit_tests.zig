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

test "value-use current-home sign-bit action classifies named i32 i64 slt and sge zero" {
    inline for ([_]u16{ 32, 64 }) |bits| {
        inline for ([_]ir.IcmpPredicate{ .slt, .sge }) |predicate| try std.testing.expect(Transaction.isCurrentHomeSignBitIcmp(.{
            .predicate = predicate,
            .operand_ty = .{ .int = bits },
            .lhs = .{ .named = "source" },
            .rhs = .{ .int = 0 },
        }));
    }
    inline for ([_]ir.IcmpInst{
        .{
            .predicate = .slt,
            .operand_ty = .{ .int = 128 },
            .lhs = .{ .named = "source" },
            .rhs = .{ .int = 0 },
        },
        .{
            .predicate = .sgt,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = "source" },
            .rhs = .{ .int = 0 },
        },
        .{
            .predicate = .slt,
            .operand_ty = .{ .int = 64 },
            .lhs = .{ .named = "source" },
            .rhs = .{ .int = 1 },
        },
        .{
            .predicate = .slt,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .int = 0 },
            .rhs = .{ .int = 0 },
        },
        .{
            .predicate = .slt,
            .operand_ty = .{ .int = 64 },
            .lhs = .{ .named = "source" },
            .rhs = .{ .named = "rhs" },
        },
    }) |icmp| try std.testing.expect(!Transaction.isCurrentHomeSignBitIcmp(icmp));
}
test "value-use dormant current-home sign-bit action reproduces i32 i64 SHR homes" {
    try executeCurrentHomeSignBitCase(
        .{ .int = 32 },
        .eax,
        .gpr32,
        32,
        &.{.{ .shr_eax_imm5 = 31 }},
    );
    try executeCurrentHomeSignBitCase(
        .{ .int = 32 },
        .{ .arg32 = .rdi },
        .gpr32,
        32,
        &.{ .{ .mov_arg_eax = .rdi }, .{ .shr_eax_imm5 = 31 } },
    );
    try executeCurrentHomeSignBitCase(
        .{ .int = 32 },
        .{ .scratch32 = .r8 },
        .gpr32,
        32,
        &.{ .{ .mov_arg_eax = .r8 }, .{ .shr_eax_imm5 = 31 } },
    );
    try executeCurrentHomeSignBitCase(
        .{ .int = 32 },
        .{ .spill64 = .slot2 },
        .gpr64,
        64,
        &.{ .{ .reload_rsp_eax = .slot2 }, .{ .shr_eax_imm5 = 31 } },
    );
    try executeCurrentHomeSignBitCase(
        .{ .int = 64 },
        .rax,
        .gpr64,
        64,
        &.{.{ .shr_rax_imm6 = 63 }},
    );
    try executeCurrentHomeSignBitCase(
        .{ .int = 64 },
        .{ .arg64 = .rsi },
        .gpr64,
        64,
        &.{ .{ .mov_arg_rax = .rsi }, .{ .shr_rax_imm6 = 63 } },
    );
    try executeCurrentHomeSignBitCase(
        .{ .int = 64 },
        .{ .scratch64 = .r9 },
        .gpr64,
        64,
        &.{ .{ .mov_arg_rax = .r9 }, .{ .shr_rax_imm6 = 63 } },
    );
    try executeCurrentHomeSignBitCase(
        .{ .int = 64 },
        .{ .spill64 = .slot3 },
        .gpr64,
        64,
        &.{ .{ .reload_rsp_rax = .slot3 }, .{ .shr_rax_imm6 = 63 } },
    );
}
test "value-use current-home sign-bit preserves live source once and re-resolves canonically" {
    var machine = MachineFunction.init("value-use-current-home-sign-bit-live", .{ .int = 1 });
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
    const source = try registerCurrentHomeSignBit(
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
        .{ .mov_arg_eax = .rdi },
        .{ .shr_eax_imm5 = 31 },
    }, machine.instructions.items);
    try std.testing.expectEqual(
        ValueLoc{ .scratch32 = .rdi },
        selector.values.get("source").?.loc,
    );
    try std.testing.expectEqual(@as(usize, 1), selector.eflags_semantics.items.len);
    try std.testing.expectEqual(
        selector_state.EflagsEffect.write,
        selector.eflags_semantics.items[0].effect,
    );
}
test "value-use current-home sign-bit preserves accumulator aliases without duplicate movement" {
    var machine = MachineFunction.init("value-use-current-home-sign-bit-aliases", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "source");
    try addLive(&plan, "live-a");
    try addLive(&plan, "live-b");
    try addAtCurrent(&plan, "result");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg32 = .rsi });
    try selector_state.bindValueLoc(&selector, "live-a", .eax);
    try selector_state.bindValueLoc(&selector, "live-b", .eax);

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const source = try registerCurrentHomeSignBit(
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
        .{ .mov_arg_eax = .rsi },
        .{ .shr_eax_imm5 = 31 },
    }, machine.instructions.items);
    try std.testing.expectEqual(
        selector.values.get("live-a").?.loc,
        selector.values.get("live-b").?.loc,
    );
}
test "value-use current-home sign-bit diagnostics are provenance scoped and pair homes reject" {
    {
        var machine = MachineFunction.init("value-use-current-home-sign-bit-unresolved", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerCurrentHomeSignBit(
            &transaction,
            .{ .named = "source" },
            "result",
            .{ .int = 32 },
        );
        try std.testing.expectError(error.ValueUseForwardPlanMissing, transaction.seal());
        try std.testing.expectEqualStrings(
            "composed-block-icmp-lhs",
            currentHomeSignBitDiagnosticForTest(
                &transaction,
                source,
                error.ValueUseUnresolvedSource,
            ).?,
        );
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }

    inline for ([_]struct {
        ty: ir.Type,
        loc: ValueLoc,
        expected_error: anyerror,
        diagnostic: []const u8,
    }{
        .{
            .ty = .{ .int = 16 },
            .loc = .{ .arg32 = .rdi },
            .expected_error = error.ValueUseCurrentHomeSignBitWidthUnsupported,
            .diagnostic = "composed-block-icmp-lhs-width",
        },
        .{
            .ty = .{ .int = 32 },
            .loc = .{ .arg128 = .{ .lo = .rdi, .hi = .rsi } },
            .expected_error = error.ValueUseCurrentHomeSignBitLocationUnsupported,
            .diagnostic = "composed-block-icmp-lhs-loc",
        },
        .{
            .ty = .{ .int = 64 },
            .loc = .{ .spill128 = .{ .lo = .slot0, .hi = .slot1 } },
            .expected_error = error.ValueUseCurrentHomeSignBitLocationUnsupported,
            .diagnostic = "composed-block-icmp-lhs-loc",
        },
    }) |case| {
        var machine = MachineFunction.init("value-use-current-home-sign-bit-reject", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "source", case.loc);
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerCurrentHomeSignBit(
            &transaction,
            .{ .named = "source" },
            "result",
            case.ty,
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        try std.testing.expectError(
            case.expected_error,
            transaction.executePreparedAction(try transaction.preparedView(source)),
        );
        try std.testing.expectEqualStrings(
            case.diagnostic,
            currentHomeSignBitDiagnosticForTest(
                &transaction,
                source,
                case.expected_error,
            ).?,
        );
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
}
test "value-use current-home sign-bit authority failures remain unattributed" {
    var machine = MachineFunction.init("value-use-current-home-sign-bit-authority", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "source");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .eax);

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const source = try registerCurrentHomeSignBit(
        &transaction,
        .{ .named = "source" },
        "result",
        .{ .int = 32 },
    );
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try std.testing.expectError(
        error.ValueUseCurrentHomeSignBitAccumulatorSessionRequired,
        transaction.executePreparedAction(try transaction.preparedView(source)),
    );
    try std.testing.expect(!transaction.failedRequestIs(source));
}
test "value-use current-home sign-bit result remains durable across teardown and zext" {
    var machine = MachineFunction.init("value-use-current-home-sign-bit-then-zext", .{ .int = 32 });
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
        const source = try registerCurrentHomeSignBit(
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
    try std.testing.expectEqual(
        ValueLoc.eax,
        selector_state.resolveValue(&selector, .{ .named = "%7" }).?,
    );
    selector.current_position = 2;
    try std.testing.expect((try selector_scalar.lowerCast(&selector, "%zext", .{
        .op = .zext,
        .value = .{ .named = "%7" },
        .from_ty = .{ .int = 1 },
        .to_ty = .{ .int = 32 },
    })) == null);
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_arg_eax = .rdi },
        .{ .shr_eax_imm5 = 31 },
        .{ .and_eax_imm32 = 1 },
    }, machine.instructions.items);
}
test "value-use current-home sign-bit rollback is exact at all seven boundaries" {
    const boundaries = [_]Transaction.CurrentHomeSignBitTestFailure{
        .after_global_preamble,
        .after_current_home_preservation,
        .after_materialization,
        .after_accumulator_preparation,
        .after_shift,
        .after_result_definition,
        .after_finalization,
    };
    for (boundaries) |boundary| {
        var machine = MachineFunction.init("value-use-current-home-sign-bit-rollback", .{ .int = 1 });
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
        try selector_state.bindValueLoc(&selector, "source", .{ .arg64 = .rsi });
        try selector_state.bindValueLoc(&selector, "live-accumulator", .rax);
        const saved_source = selector.values.get("source").?;
        const saved_accumulator = selector.values.get("live-accumulator").?;
        const saved_next_vreg = selector.next_virtual_reg;
        const saved_next_spill = selector.next_spill_slot;
        const saved_domain = selector.address_dependencies;
        const saved_eflags = selector.eflags.snapshot();
        const saved_semantics = selector.eflags_semantics.items.len;

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerCurrentHomeSignBit(
            &transaction,
            .{ .named = "source" },
            "result",
            .{ .int = 64 },
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.setCurrentHomeSignBitTestFailure(boundary);
        try std.testing.expectError(
            error.ValueUseCurrentHomeSignBitTestFailure,
            transaction.executePreparedAction(try transaction.preparedView(source)),
        );

        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(saved_source, selector.values.get("source").?);
        try std.testing.expectEqual(
            saved_accumulator,
            selector.values.get("live-accumulator").?,
        );
        try std.testing.expect(selector.values.get("result") == null);
        try std.testing.expectEqual(saved_next_vreg, selector.next_virtual_reg);
        try std.testing.expectEqual(saved_next_spill, selector.next_spill_slot);
        try std.testing.expect(selector.address_dependencies.eql(&saved_domain));
        try selector.eflags.validateSnapshot(saved_eflags);
        try std.testing.expectEqual(saved_semantics, selector.eflags_semantics.items.len);
        try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
    }
}
