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

test "value-use dormant scratch compare action reproduces representative streams and EFLAGS semantics" {
    try executeScratchCompareCase(
        .{ .int = 16 },
        .ne,
        false,
        .{ .named = .{ .arg64 = .r8 } },
        .{ .arg64 = .rcx },
        &.{
            .{ .shl_rcx_imm6 = 48 },
            .{ .sar_arg64_imm6 = .{ .reg = .rcx, .amount = 48 } },
            .{ .shl_r8_imm6 = 48 },
            .{ .sar_arg64_imm6 = .{ .reg = .r8, .amount = 48 } },
            .{ .cmp_ecx_arg32 = .r8 },
            .setne_eax,
        },
        &.{ .write, .write, .write, .write, .definition, .use },
    );
    try executeScratchCompareCase(
        .ptr,
        .eq,
        false,
        .null_pointer,
        .{ .arg64 = .rcx },
        &.{ .{ .test_arg64 = .rcx }, .sete_eax },
        &.{ .definition, .use },
    );
    try executeScratchCompareCase(
        .{ .int = 32 },
        .ugt,
        false,
        .{ .immediate = 9 },
        .{ .arg32 = .rcx },
        &.{
            .{ .mov_imm_r8 = 9 },
            .{ .cmp_r8d_arg32 = .rcx },
            .setb_eax,
        },
        &.{ .definition, .use },
    );
    try executeScratchCompareCase(
        .{ .int = 32 },
        .ult,
        false,
        .{ .named = .{ .arg32 = .rcx } },
        .{ .arg32 = .r8 },
        &.{ .{ .cmp_ecx_arg32 = .r8 }, .setb_eax },
        &.{ .definition, .use },
    );
}
test "value-use scratch compare preserves a prior result before staging the next operand" {
    var machine = MachineFunction.init("value-use-scratch-compare-two-phase", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("lhs", 1);
    try plan.interval_ends.put("rhs", 2);
    try plan.interval_ends.put("first-result", 3);
    try plan.interval_ends.put("second-result", 2);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg32 = .rdi });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .arg32 = .rsi });

    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const requests = try registerScratchCompare(
            &transaction,
            .{ .named = "lhs" },
            .{ .immediate = 0 },
            "first-result",
            .{ .int = 32 },
            .ne,
            false,
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(requests.lhs));
        try transaction.commit();
    }

    selector.current_position = 2;
    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const requests = try registerScratchCompare(
            &transaction,
            .{ .named = "rhs" },
            .{ .immediate = 0 },
            "second-result",
            .{ .int = 32 },
            .ne,
            false,
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(requests.lhs));
        try transaction.commit();
    }

    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rdi } },
        .{ .test_arg32 = .rcx },
        .setne_eax,
        .{ .mov_eax_to_arg = .rdi },
        .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rsi } },
        .{ .test_arg32 = .rcx },
        .setne_eax,
    }, machine.instructions.items);
    try std.testing.expectEqual(ValueLoc{ .scratch32 = .rdi }, selector.values.get("first-result").?.loc);
    try std.testing.expectEqual(ValueLoc.eax, selector.values.get("second-result").?.loc);
    try std.testing.expectEqual(@as(usize, 4), selector.eflags_semantics.items.len);
}
test "value-use scratch compare refreshes an accumulator operand after preservation" {
    var machine = MachineFunction.init("value-use-scratch-compare-accumulator-source", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addLive(&plan, "lhs");
    try addAtCurrent(&plan, "result");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "lhs", .eax);

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const requests = try registerScratchCompare(
        &transaction,
        .{ .named = "lhs" },
        .{ .immediate = 0 },
        "result",
        .{ .int = 32 },
        .ne,
        false,
    );
    try transaction.seal();
    _ = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(requests.lhs));
    try transaction.commit();

    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_eax_to_arg = .rdi },
        .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rdi } },
        .{ .test_arg32 = .rcx },
        .setne_eax,
    }, machine.instructions.items);
    try std.testing.expectEqual(ValueLoc{ .scratch32 = .rdi }, selector.values.get("lhs").?.loc);
    try std.testing.expectEqual(ValueLoc.eax, selector.values.get("result").?.loc);
}
test "value-use scratch compare preserves each live accumulator alias once without duplicate spill" {
    var machine = MachineFunction.init("value-use-scratch-compare-accumulator-aliases", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "lhs");
    try addLive(&plan, "alias-a");
    try addLive(&plan, "alias-b");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg32 = .rdx });
    try selector_state.bindValueLoc(&selector, "alias-a", .eax);
    try selector_state.bindValueLoc(&selector, "alias-b", .eax);

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const requests = try registerScratchCompare(
        &transaction,
        .{ .named = "lhs" },
        .{ .immediate = 0 },
        "result",
        .{ .int = 32 },
        .ne,
        false,
    );
    try transaction.seal();
    _ = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(requests.lhs));
    try transaction.commit();

    var preservation_moves: usize = 0;
    var spills: usize = 0;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .mov_eax_to_arg => preservation_moves += 1,
        .spill_eax_rsp => spills += 1,
        else => {},
    };
    try std.testing.expectEqual(@as(usize, 2), preservation_moves);
    try std.testing.expectEqual(@as(usize, 0), spills);
    try std.testing.expect(selector.values.get("alias-a").?.loc != .eax);
    try std.testing.expect(selector.values.get("alias-b").?.loc != .eax);
}
test "value-use scratch compare preservation leaves EFLAGS unchanged through canonical refresh" {
    var machine = MachineFunction.init("value-use-scratch-compare-preserve-flags", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "lhs");
    try addLive(&plan, "live-accumulator");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg32 = .rsi });
    try selector_state.bindValueLoc(&selector, "live-accumulator", .eax);
    try selector.eflags.apply(.definition);
    const flags_before = selector.eflags.snapshot();

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const requests = try registerScratchCompare(
        &transaction,
        .{ .named = "lhs" },
        .{ .immediate = 0 },
        "result",
        .{ .int = 32 },
        .ne,
        false,
    );
    try transaction.seal();
    _ = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.setScratchCompareTestFailure(.after_canonical_view_refresh);
    try std.testing.expectError(
        error.ValueUseScratchCompareTestFailure,
        transaction.executePreparedAction(try transaction.preparedView(requests.lhs)),
    );

    try selector.eflags.validateSnapshot(flags_before);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(ValueLoc.eax, selector.values.get("live-accumulator").?.loc);
    try std.testing.expectEqual(ValueLoc{ .arg32 = .rsi }, selector.values.get("lhs").?.loc);
}
test "value-use dormant scratch compare action classifies the complete twenty-form matrix" {
    const RhsKind = enum { immediate, null_pointer, named };
    const Case = struct {
        ty: ir.Type,
        predicate: ir.IcmpPredicate,
        samesign: bool = false,
        rhs: RhsKind,
        immediate: i128 = 0,
    };
    const cases = [_]Case{
        .{ .ty = .{ .int = 16 }, .predicate = .ne, .rhs = .immediate },
        .{ .ty = .{ .int = 32 }, .predicate = .ne, .rhs = .immediate },
        .{ .ty = .{ .int = 64 }, .predicate = .ne, .rhs = .immediate },
        .{ .ty = .{ .int = 16 }, .predicate = .ne, .rhs = .named },
        .{ .ty = .ptr, .predicate = .eq, .rhs = .null_pointer },
        .{ .ty = .ptr, .predicate = .eq, .rhs = .named },
        .{ .ty = .{ .int = 52 }, .predicate = .eq, .rhs = .immediate },
        .{ .ty = .{ .int = 32 }, .predicate = .eq, .rhs = .named },
        .{ .ty = .{ .int = 64 }, .predicate = .eq, .rhs = .immediate, .immediate = 7 },
        .{ .ty = .{ .int = 16 }, .predicate = .ult, .rhs = .immediate, .immediate = 0xffff },
        .{ .ty = .{ .int = 32 }, .predicate = .ugt, .rhs = .named },
        .{ .ty = .{ .int = 64 }, .predicate = .ugt, .rhs = .immediate, .immediate = 7 },
        .{ .ty = .{ .int = 32 }, .predicate = .ugt, .rhs = .immediate, .immediate = 7 },
        .{ .ty = .{ .int = 64 }, .predicate = .sgt, .rhs = .immediate, .immediate = -7 },
        .{ .ty = .{ .int = 16 }, .predicate = .slt, .rhs = .immediate },
        .{ .ty = .{ .int = 64 }, .predicate = .slt, .rhs = .immediate, .immediate = -7 },
        .{ .ty = .{ .int = 32 }, .predicate = .sgt, .rhs = .named },
        .{ .ty = .{ .int = 32 }, .predicate = .ult, .rhs = .named },
        .{ .ty = .{ .int = 64 }, .predicate = .ult, .rhs = .named },
        .{ .ty = .{ .int = 64 }, .predicate = .ult, .rhs = .immediate, .immediate = 7 },
    };

    for (cases, 0..) |case, index| {
        var machine = MachineFunction.init("value-use-scratch-compare-matrix", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        var result_storage: [32]u8 = undefined;
        const result = try std.fmt.bufPrint(&result_storage, "result-{d}", .{index});
        _ = try registerScratchCompare(
            &transaction,
            .{ .named = "lhs" },
            switch (case.rhs) {
                .immediate => .{ .immediate = case.immediate },
                .null_pointer => .null_pointer,
                .named => .{ .named = .{ .named = "rhs" } },
            },
            result,
            case.ty,
            case.predicate,
            case.samesign,
        );
        try std.testing.expectEqual(
            @as(usize, if (case.rhs == .named) 2 else 1),
            transaction.requestCount(),
        );
    }
}
test "value-use scratch compare enforces legacy source order validation timing and provenance" {
    {
        var machine = MachineFunction.init("value-use-scratch-compare-order", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const rhs = try transaction.register(.{
            .source = .{ .named = "rhs" },
            .expected = scratchCompareExpected(.{ .int = 32 }),
            .form = .scratch_compare_operand,
            .destination = .prepared_source,
        });
        const lhs = try transaction.register(.{
            .source = .{ .named = "lhs" },
            .expected = scratchCompareExpected(.{ .int = 32 }),
            .form = .scratch_compare_operand,
            .destination = .prepared_view,
        });
        try std.testing.expectError(
            error.ValueUseScratchCompareSourceOrder,
            transaction.attachScratchCompareAction(lhs, .{
                .result = try actionIdentity("result"),
                .operand_ty = .{ .int = 32 },
                .predicate = .eq,
                .samesign = false,
                .rhs = .{ .named = rhs },
            }),
        );
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
    {
        var machine = MachineFunction.init("value-use-scratch-compare-early-range", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const lhs = try transaction.register(.{
            .source = .{ .named = "lhs" },
            .expected = scratchCompareExpected(.{ .int = 16 }),
            .form = .scratch_compare_operand,
            .destination = .prepared_view,
        });
        try std.testing.expectError(
            error.ValueUseScratchCompareImmediateOutOfRange,
            transaction.attachScratchCompareAction(lhs, .{
                .result = try actionIdentity("result"),
                .operand_ty = .{ .int = 16 },
                .predicate = .ult,
                .samesign = false,
                .rhs = .{ .immediate = 0x1_0000 },
            }),
        );
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
    {
        var machine = MachineFunction.init("value-use-scratch-compare-provenance", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "lhs");
        try addAtCurrent(&plan, "rhs");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "lhs", .{ .arg32 = .rdi });

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const requests = try registerScratchCompare(
            &transaction,
            .{ .named = "lhs" },
            .{ .named = .{ .named = "rhs" } },
            "result",
            .{ .int = 32 },
            .eq,
            false,
        );
        try std.testing.expectError(error.ValueUseUnresolvedSource, transaction.seal());
        try std.testing.expect(!transaction.failedRequestIs(requests.lhs));
        try std.testing.expect(transaction.failedRequestIs(requests.rhs.?));
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
    {
        var machine = MachineFunction.init("value-use-scratch-compare-lhs-precedence", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "lhs");
        try addAtCurrent(&plan, "rhs");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const requests = try registerScratchCompare(
            &transaction,
            .{ .named = "lhs" },
            .{ .named = .{ .named = "rhs" } },
            "result",
            .{ .int = 32 },
            .eq,
            false,
        );
        try std.testing.expectError(error.ValueUseUnresolvedSource, transaction.seal());
        try std.testing.expect(transaction.failedRequestIs(requests.lhs));
        try std.testing.expect(!transaction.failedRequestIs(requests.rhs.?));
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
}
test "value-use scratch compare plans every RCX R8 and EAX physical write" {
    const destinations = [_]Transaction.Destination{
        .{ .gpr32 = .rcx },
        .{ .gpr32 = .r8 },
        .eax,
    };
    for (destinations) |destination| {
        var machine = MachineFunction.init("value-use-scratch-compare-write-plan", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "lhs", "rhs", "other" }) |name| try addAtCurrent(&plan, name);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "lhs", .{ .arg32 = .rdi });
        try selector_state.bindValueLoc(&selector, "rhs", .{ .arg32 = .rsi });
        try selector_state.bindValueLoc(&selector, "other", .{ .arg32 = .r9 });

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        _ = try registerScratchCompare(
            &transaction,
            .{ .named = "lhs" },
            .{ .named = .{ .named = "rhs" } },
            "result",
            .{ .int = 32 },
            .eq,
            false,
        );
        _ = try transaction.register(request(
            "other",
            .{ .int = 32 },
            .gpr32,
            .gpr32,
            destination,
        ));
        try std.testing.expectError(error.ValueUseConflictingDestination, transaction.seal());
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
}
test "value-use scratch compare rollback is exact at every action boundary" {
    const Boundary = Transaction.ScratchCompareTestFailure;
    const boundaries = [_]Boundary{
        .after_first_accumulator_preservation,
        .after_canonical_view_refresh,
        .after_lhs_staging,
        .after_rhs_staging,
        .after_lhs_normalize_shl,
        .after_lhs_normalize_sar,
        .after_rhs_normalize_shl,
        .after_rhs_normalize_sar,
        .after_accumulator_preparation,
        .after_flags_definition,
        .after_setcc,
        .after_result_identity_ownership,
        .after_result_definition,
        .after_result_finalization,
    };
    for (boundaries) |boundary| {
        var machine = MachineFunction.init("value-use-scratch-compare-rollback", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "lhs", "rhs" }) |name| try addAtCurrent(&plan, name);
        try addLive(&plan, "live-accumulator");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 128;
        selector.next_spill_slot = 1;
        try selector_state.bindValueLoc(&selector, "lhs", .{ .arg64 = .rdi });
        try selector_state.bindValueLoc(&selector, "rhs", .{ .arg64 = .rsi });
        try selector_state.bindValueLoc(&selector, "live-accumulator", .rax);
        const saved_lhs = selector.values.get("lhs").?;
        const saved_rhs = selector.values.get("rhs").?;
        const saved_accumulator = selector.values.get("live-accumulator").?;
        const saved_next_vreg = selector.next_virtual_reg;
        const saved_next_spill = selector.next_spill_slot;
        const saved_domain = selector.address_dependencies;
        const saved_eflags = selector.eflags.snapshot();
        const saved_semantics = selector.eflags_semantics.items.len;

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const requests = try registerScratchCompare(
            &transaction,
            .{ .named = "lhs" },
            .{ .named = .{ .named = "rhs" } },
            "result",
            .{ .int = 16 },
            .ne,
            false,
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.setScratchCompareTestFailure(boundary);
        try std.testing.expectError(
            error.ValueUseScratchCompareTestFailure,
            transaction.executePreparedAction(try transaction.preparedView(requests.lhs)),
        );
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(saved_lhs, selector.values.get("lhs").?);
        try std.testing.expectEqual(saved_rhs, selector.values.get("rhs").?);
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

    var machine = MachineFunction.init("value-use-scratch-compare-immediate-rollback", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "lhs");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg32 = .rdi });
    const saved_lhs = selector.values.get("lhs").?;
    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const requests = try registerScratchCompare(
        &transaction,
        .{ .named = "lhs" },
        .{ .immediate = 9 },
        "result",
        .{ .int = 32 },
        .ugt,
        false,
    );
    try transaction.seal();
    _ = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.setScratchCompareTestFailure(.after_immediate_staging);
    try std.testing.expectError(
        error.ValueUseScratchCompareTestFailure,
        transaction.executePreparedAction(try transaction.preparedView(requests.lhs)),
    );
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(saved_lhs, selector.values.get("lhs").?);
    try std.testing.expect(selector.values.get("result") == null);
    try std.testing.expectEqual(@as(usize, 0), selector.eflags_semantics.items.len);
}
test "value-use scratch compare owns its result across transaction teardown and following zext" {
    var machine = MachineFunction.init("value-use-scratch-compare-then-zext", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("lhs", 1);
    try plan.interval_ends.put("%7", 2);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg64 = .rdi });

    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const requests = try registerScratchCompare(
            &transaction,
            .{ .named = "lhs" },
            .{ .immediate = -4294967296 },
            "%7",
            .{ .int = 64 },
            .ult,
            false,
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(requests.lhs));
        try transaction.commit();
    }

    try std.testing.expectEqual(ValueLoc.eax, selector_state.resolveValue(&selector, .{ .named = "%7" }).?);
    selector.current_position = 2;
    const diagnostic = try selector_scalar.lowerCast(&selector, "%spec.store.select", .{
        .op = .zext,
        .value = .{ .named = "%7" },
        .from_ty = .{ .int = 1 },
        .to_ty = .{ .int = 32 },
    });
    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc.eax, selector_state.resolveValue(&selector, .{ .named = "%spec.store.select" }).?);
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rdi } },
        .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = -4294967296 } },
        .setb_eax,
        .{ .and_eax_imm32 = 1 },
    }, machine.instructions.items);
}
test "value-use scratch compare identity rollback frees one owned result at each durable boundary" {
    const boundaries = [_]Transaction.ScratchCompareTestFailure{
        .after_result_identity_ownership,
        .after_result_definition,
        .after_result_finalization,
    };
    for (boundaries) |boundary| {
        var failing = std.testing.FailingAllocator.init(std.testing.allocator, .{});
        const allocator = failing.allocator();
        var machine = MachineFunction.init("value-use-scratch-compare-owned-rollback", .{ .int = 1 });
        defer machine.deinit(allocator);
        var plan = SelectorAllocationPlan.init(allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "lhs");
        var selector = ComposedBlockSelector.init(allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "lhs", .{ .arg32 = .rdi });

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const requests = try registerScratchCompare(
            &transaction,
            .{ .named = "lhs" },
            .{ .immediate = 0 },
            "result",
            .{ .int = 32 },
            .ne,
            false,
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        try machine.instructions.ensureUnusedCapacity(allocator, 4);
        try machine.owned_labels.ensureUnusedCapacity(allocator, 1);
        try selector.eflags_semantics.ensureUnusedCapacity(allocator, 4);
        try selector.values.ensureUnusedCapacity(1);
        const allocations_before = failing.allocations;
        const deallocations_before = failing.deallocations;
        try transaction.setScratchCompareTestFailure(boundary);
        try std.testing.expectError(
            error.ValueUseScratchCompareTestFailure,
            transaction.executePreparedAction(try transaction.preparedView(requests.lhs)),
        );
        try std.testing.expectEqual(allocations_before + 1, failing.allocations);
        try std.testing.expectEqual(deallocations_before + 1, failing.deallocations);
        try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
        try std.testing.expect(selector.values.get("result") == null);
    }
}
test "value-use scratch compare identity allocation failure leaves no binding or owned entry" {
    var failing = std.testing.FailingAllocator.init(std.testing.allocator, .{});
    const allocator = failing.allocator();
    var machine = MachineFunction.init("value-use-scratch-compare-owned-oom", .{ .int = 1 });
    defer machine.deinit(allocator);
    var plan = SelectorAllocationPlan.init(allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "lhs");
    var selector = ComposedBlockSelector.init(allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg32 = .rdi });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const requests = try registerScratchCompare(
        &transaction,
        .{ .named = "lhs" },
        .{ .immediate = 0 },
        "result",
        .{ .int = 32 },
        .ne,
        false,
    );
    try transaction.seal();
    _ = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    try machine.instructions.ensureUnusedCapacity(allocator, 4);
    try machine.owned_labels.ensureUnusedCapacity(allocator, 1);
    try selector.eflags_semantics.ensureUnusedCapacity(allocator, 4);
    try selector.values.ensureUnusedCapacity(1);
    const allocations_before = failing.allocations;
    const deallocations_before = failing.deallocations;
    failing.fail_index = failing.alloc_index;
    try std.testing.expectError(
        error.OutOfMemory,
        transaction.executePreparedAction(try transaction.preparedView(requests.lhs)),
    );
    try std.testing.expect(failing.has_induced_failure);
    try std.testing.expectEqual(allocations_before, failing.allocations);
    try std.testing.expectEqual(deallocations_before, failing.deallocations);
    try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
    try std.testing.expect(selector.values.get("result") == null);
}
test "value-use scratch compare requires subordinate accumulator ownership and supports accepted wide homes" {
    var machine = MachineFunction.init("value-use-scratch-compare-wide-homes", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "lhs");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "lhs", .{ .spill64 = .slot3 });

    var missing_session = try Transaction.begin(&selector);
    defer missing_session.deinit();
    const missing_requests = try registerScratchCompare(
        &missing_session,
        .{ .named = "lhs" },
        .{ .immediate = 0 },
        "result",
        .{ .int = 16 },
        .ne,
        false,
    );
    try missing_session.seal();
    try missing_session.prepare();
    try missing_session.materializeAll();
    try std.testing.expectError(
        error.ValueUseScratchCompareAccumulatorSessionRequired,
        missing_session.executePreparedAction(try missing_session.preparedView(missing_requests.lhs)),
    );
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);

    var accepted = try Transaction.begin(&selector);
    defer accepted.deinit();
    const accepted_requests = try registerScratchCompare(
        &accepted,
        .{ .named = "lhs" },
        .{ .immediate = 0 },
        "result",
        .{ .int = 16 },
        .ne,
        false,
    );
    try accepted.seal();
    _ = try accepted.beginAccumulatorSession();
    try accepted.prepare();
    try accepted.materializeAll();
    try accepted.executePreparedAction(try accepted.preparedView(accepted_requests.lhs));
    try accepted.commit();
    try std.testing.expectEqual(ValueLoc.eax, selector.values.get("result").?.loc);
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = .slot3 } },
        .{ .cmp_arg16_imm16 = .{ .reg = .rcx, .imm = 0 } },
        .setne_eax,
    }, machine.instructions.items);

    var pair_machine = MachineFunction.init("value-use-scratch-compare-pair-low", .{ .int = 1 });
    defer pair_machine.deinit(std.testing.allocator);
    var pair_plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer pair_plan.deinit();
    try addAtCurrent(&pair_plan, "pair-lhs");
    var pair_selector = ComposedBlockSelector.init(std.testing.allocator, &pair_machine);
    defer pair_selector.deinit();
    pair_selector.allocation_plan = &pair_plan;
    try selector_state.bindValueLoc(&pair_selector, "pair-lhs", .{ .arg128 = .{
        .lo = .rcx,
        .hi = .rdx,
    } });
    var pair_transaction = try Transaction.begin(&pair_selector);
    defer pair_transaction.deinit();
    const pair_requests = try registerScratchCompare(
        &pair_transaction,
        .{ .named = "pair-lhs" },
        .{ .immediate = 0 },
        "pair-result",
        .{ .int = 64 },
        .ne,
        false,
    );
    try pair_transaction.seal();
    _ = try pair_transaction.beginAccumulatorSession();
    try pair_transaction.prepare();
    try pair_transaction.materializeAll();
    try pair_transaction.executePreparedAction(try pair_transaction.preparedView(pair_requests.lhs));
    try pair_transaction.commit();
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = 0 } },
        .setne_eax,
    }, pair_machine.instructions.items);
}
