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

test "value-use dormant i128 pair classifiers admit only the two corrected semantic forms" {
    try std.testing.expect(Transaction.isI128EqMinIcmp(.{
        .predicate = .eq,
        .operand_ty = .{ .int = 128 },
        .lhs = .{ .named = "source" },
        .rhs = .{ .int = std.math.minInt(i128) },
    }));
    try std.testing.expect(Transaction.isI128SignBitIcmp(.{
        .predicate = .slt,
        .samesign = true,
        .operand_ty = .{ .int = 128 },
        .lhs = .{ .named = "source" },
        .rhs = .{ .int = 0 },
    }));
    inline for ([_]ir.IcmpInst{
        .{
            .predicate = .ne,
            .operand_ty = .{ .int = 128 },
            .lhs = .{ .named = "source" },
            .rhs = .{ .int = std.math.minInt(i128) },
        },
        .{
            .predicate = .eq,
            .operand_ty = .{ .int = 64 },
            .lhs = .{ .named = "source" },
            .rhs = .{ .int = std.math.minInt(i128) },
        },
        .{
            .predicate = .eq,
            .operand_ty = .{ .int = 128 },
            .lhs = .{ .named = "source" },
            .rhs = .{ .int = 0 },
        },
        .{
            .predicate = .slt,
            .operand_ty = .{ .int = 128 },
            .lhs = .{ .named = "source" },
            .rhs = .{ .int = 1 },
        },
        .{
            .predicate = .slt,
            .operand_ty = .{ .int = 128 },
            .lhs = .{ .int = 0 },
            .rhs = .{ .int = 0 },
        },
    }) |icmp| {
        try std.testing.expect(!Transaction.isI128EqMinIcmp(icmp));
        try std.testing.expect(!Transaction.isI128SignBitIcmp(icmp));
    }
}
test "value-use dormant i128 equality action preserves pair chooser sequence and EFLAGS" {
    try executeI128PairActionCase(
        .eq_min,
        .{ .arg128 = selector_types.pair_a },
        &.{
            .{ .mov_arg64_arg = .{ .dst = .r8, .src = .rcx } },
            .{ .mov_arg64_arg = .{ .dst = .r9, .src = .rdx } },
            .{ .mov_arg_rax = .r9 },
            .{ .mov_imm_rcx = std.math.minInt(i64) },
            .{ .binary_arg_rax = .{ .op = .xor, .reg = .rcx } },
            .{ .binary_arg_rax = .{ .op = .@"or", .reg = .r8 } },
            .{ .mov_rax_to_arg = .rcx },
            .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = 0 } },
            .sete_eax,
        },
        &.{ .write, .write, .definition, .use },
    );
    try executeI128PairActionCase(
        .eq_min,
        .{ .scratch128 = selector_types.pair_b },
        &.{
            .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .r8 } },
            .{ .mov_arg64_arg = .{ .dst = .rdx, .src = .r9 } },
            .{ .mov_arg_rax = .rdx },
            .{ .mov_imm_r8 = std.math.minInt(i64) },
            .{ .binary_arg_rax = .{ .op = .xor, .reg = .r8 } },
            .{ .binary_arg_rax = .{ .op = .@"or", .reg = .rcx } },
            .{ .mov_rax_to_arg = .r8 },
            .{ .cmp_arg64_imm64 = .{ .reg = .r8, .imm = 0 } },
            .sete_eax,
        },
        &.{ .write, .write, .definition, .use },
    );
    try executeI128PairActionCase(
        .eq_min,
        .{ .stack128_value = 32 },
        &.{
            .{ .load_stack_disp8_arg64 = .{ .reg = .rcx, .disp = 32 } },
            .{ .load_stack_disp8_arg64 = .{ .reg = .rdx, .disp = 40 } },
            .{ .mov_arg_rax = .rdx },
            .{ .mov_imm_r8 = std.math.minInt(i64) },
            .{ .binary_arg_rax = .{ .op = .xor, .reg = .r8 } },
            .{ .binary_arg_rax = .{ .op = .@"or", .reg = .rcx } },
            .{ .mov_rax_to_arg = .r8 },
            .{ .cmp_arg64_imm64 = .{ .reg = .r8, .imm = 0 } },
            .sete_eax,
        },
        &.{ .write, .write, .definition, .use },
    );
    try executeI128PairActionCase(
        .eq_min,
        .{ .spill128 = .{ .lo = .slot0, .hi = .slot1 } },
        &.{
            .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot0 } },
            .{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = .slot1 } },
            .{ .mov_arg_rax = .rdx },
            .{ .mov_imm_r8 = std.math.minInt(i64) },
            .{ .binary_arg_rax = .{ .op = .xor, .reg = .r8 } },
            .{ .binary_arg_rax = .{ .op = .@"or", .reg = .rcx } },
            .{ .mov_rax_to_arg = .r8 },
            .{ .cmp_arg64_imm64 = .{ .reg = .r8, .imm = 0 } },
            .sete_eax,
        },
        &.{ .write, .write, .definition, .use },
    );
}
test "value-use dormant i128 sign-bit action wraps high-limb helper and logical SHR" {
    try executeI128PairActionCase(
        .sign_bit,
        .{ .arg128 = selector_types.pair_a },
        &.{ .{ .mov_arg_rax = .rdx }, .{ .shr_rax_imm6 = 63 } },
        &.{.write},
    );
    try executeI128PairActionCase(
        .sign_bit,
        .{ .scratch128 = selector_types.pair_b },
        &.{ .{ .mov_arg_rax = .r9 }, .{ .shr_rax_imm6 = 63 } },
        &.{.write},
    );
    try executeI128PairActionCase(
        .sign_bit,
        .{ .stack128_value = 32 },
        &.{ .{ .load_stack_disp8_rax = 40 }, .{ .shr_rax_imm6 = 63 } },
        &.{.write},
    );
    try executeI128PairActionCase(
        .sign_bit,
        .{ .spill128 = .{ .lo = .slot0, .hi = .slot1 } },
        &.{
            .{ .reload_rsp_rax = .slot1 },
            .{ .shr_rax_imm6 = 63 },
        },
        &.{.write},
    );
}
test "value-use i128 spill pair actions reproduce __muloti4 __negvti2 and framed negation streams" {
    const eq_min_stream = [_]machine_module.Instruction{
        .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot0 } },
        .{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = .slot1 } },
        .{ .mov_arg_rax = .rdx },
        .{ .mov_imm_r8 = std.math.minInt(i64) },
        .{ .binary_arg_rax = .{ .op = .xor, .reg = .r8 } },
        .{ .binary_arg_rax = .{ .op = .@"or", .reg = .rcx } },
        .{ .mov_rax_to_arg = .r8 },
        .{ .cmp_arg64_imm64 = .{ .reg = .r8, .imm = 0 } },
        .sete_eax,
    };

    // __muloti4 sign-bit comparison over the first spill-backed operand.
    try executeI128PairActionCase(
        .sign_bit,
        .{ .spill128 = .{ .lo = .slot0, .hi = .slot1 } },
        &.{
            .{ .reload_rsp_rax = .slot1 },
            .{ .shr_rax_imm6 = 63 },
        },
        &.{.write},
    );
    // __muloti4 eq-min comparison over the second spill-backed operand.
    try executeI128PairActionCase(
        .eq_min,
        .{ .spill128 = .{ .lo = .slot2, .hi = .slot3 } },
        &.{
            .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot2 } },
            .{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = .slot3 } },
            .{ .mov_arg_rax = .rdx },
            .{ .mov_imm_r8 = std.math.minInt(i64) },
            .{ .binary_arg_rax = .{ .op = .xor, .reg = .r8 } },
            .{ .binary_arg_rax = .{ .op = .@"or", .reg = .rcx } },
            .{ .mov_rax_to_arg = .r8 },
            .{ .cmp_arg64_imm64 = .{ .reg = .r8, .imm = 0 } },
            .sete_eax,
        },
        &.{ .write, .write, .definition, .use },
    );
    // __negvti2 and the framed i128-negation test share this exact eq-min
    // spill materialization and comparison stream.
    try executeI128PairActionCase(
        .eq_min,
        .{ .spill128 = .{ .lo = .slot0, .hi = .slot1 } },
        &eq_min_stream,
        &.{ .write, .write, .definition, .use },
    );
    try executeI128PairActionCase(
        .eq_min,
        .{ .spill128 = .{ .lo = .slot0, .hi = .slot1 } },
        &eq_min_stream,
        &.{ .write, .write, .definition, .use },
    );
}
test "value-use i128 pair wrappers reject unsupported homes and malformed semantic requests without mutation" {
    inline for ([_]struct {
        loc: ValueLoc,
        expected_error: anyerror,
        diagnostic: []const u8,
    }{
        .{
            .loc = .{ .arg64 = .rdi },
            .expected_error = error.ValueUseI128PairWidthUnsupported,
            .diagnostic = "composed-block-icmp-lhs-width",
        },
        .{
            .loc = .{ .stack128 = 32 },
            .expected_error = error.ValueUseI128PairWidthUnsupported,
            .diagnostic = "composed-block-icmp-lhs-width",
        },
    }) |case| {
        var machine = MachineFunction.init("value-use-i128-pair-reject-home", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "source", case.loc);
        const saved = selector.values.get("source").?;

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerI128PairAction(
            &transaction,
            .{ .named = "source" },
            "result",
            .eq_min,
        );
        try std.testing.expectError(
            case.expected_error,
            transaction.seal(),
        );
        try std.testing.expect(transaction.failedRequestIs(source));
        try std.testing.expectEqualStrings(
            case.diagnostic,
            i128PairDiagnosticForTest(
                &transaction,
                source,
                case.expected_error,
            ).?,
        );
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(saved, selector.values.get("source").?);
    }

    var machine = MachineFunction.init("value-use-i128-pair-reject-type", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "source");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg128 = selector_types.pair_a });
    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    _ = try transaction.register(.{
        .source = .{ .named = "source" },
        .expected = expected(.{ .int = 64 }, .gpr64),
        .form = .i128_icmp_pair_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .i128_sign_bit = .{
            .result = try actionIdentity("result"),
        } },
    });
    try std.testing.expectError(error.ValueUsePreparedActionFormMismatch, transaction.seal());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}
test "value-use i128 pair materializer failure maps to lhs while authority failure is unattributed" {
    {
        var machine = MachineFunction.init("value-use-i128-pair-helper-failure", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        try addLive(&plan, "occupied-pair");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(
            &selector,
            "source",
            .{ .arg128 = selector_types.pair_a },
        );
        try selector_state.bindValueLoc(
            &selector,
            "occupied-pair",
            .{ .scratch128 = selector_types.pair_b },
        );

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerI128PairAction(
            &transaction,
            .{ .named = "source" },
            "result",
            .eq_min,
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        const err = transaction.executePreparedAction(
            try transaction.preparedView(source),
        );
        try std.testing.expectError(error.UnsupportedCodegenValue, err);
        try std.testing.expectEqualStrings(
            "composed-block-icmp-lhs",
            i128PairDiagnosticForTest(
                &transaction,
                source,
                error.UnsupportedCodegenValue,
            ).?,
        );
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }

    {
        var machine = MachineFunction.init("value-use-i128-pair-authority", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(
            &selector,
            "source",
            .{ .arg128 = selector_types.pair_a },
        );
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerI128PairAction(
            &transaction,
            .{ .named = "source" },
            "result",
            .sign_bit,
        );
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try std.testing.expectError(
            error.ValueUseI128SignBitAccumulatorSessionRequired,
            transaction.executePreparedAction(try transaction.preparedView(source)),
        );
        try std.testing.expect(!transaction.failedRequestIs(source));
    }
}
test "value-use i128 pair actions run the global preamble once and retain source ownership" {
    var machine = MachineFunction.init("value-use-i128-pair-preamble", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addLive(&plan, "source");
    try addLive(&plan, "live-accumulator");
    try addAtCurrent(&plan, "result");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "source", .{ .stack128_value = 32 });
    try selector_state.bindValueLoc(&selector, "live-accumulator", .eax);
    const source_binding = selector.values.get("source").?;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const source = try registerI128PairAction(
        &transaction,
        .{ .named = "source" },
        "result",
        .sign_bit,
    );
    try transaction.seal();
    _ = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(source));
    try transaction.commit();

    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_eax_to_arg = .rdi },
        .{ .load_stack_disp8_rax = 40 },
        .{ .shr_rax_imm6 = 63 },
    }, machine.instructions.items);
    try std.testing.expectEqual(source_binding, selector.values.get("source").?);
    try std.testing.expectEqual(
        ValueLoc{ .scratch32 = .rdi },
        selector.values.get("live-accumulator").?.loc,
    );
    try std.testing.expectEqual(@as(usize, 1), selector.eflags_semantics.items.len);
}
test "value-use i128 pair result remains durable after transaction teardown" {
    var machine = MachineFunction.init("value-use-i128-pair-then-zext", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("source", 1);
    try plan.interval_ends.put("%pair-result", 2);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    try selector_state.bindValueLoc(
        &selector,
        "source",
        .{ .arg128 = selector_types.pair_a },
    );

    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerI128PairAction(
            &transaction,
            .{ .named = "source" },
            "%pair-result",
            .sign_bit,
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
        selector_state.resolveValue(&selector, .{ .named = "%pair-result" }).?,
    );
    selector.current_position = 2;
    try std.testing.expect((try selector_scalar.lowerCast(&selector, "%zext", .{
        .op = .zext,
        .value = .{ .named = "%pair-result" },
        .from_ty = .{ .int = 1 },
        .to_ty = .{ .int = 32 },
    })) == null);
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_arg_rax = .rdx },
        .{ .shr_rax_imm6 = 63 },
        .{ .and_eax_imm32 = 1 },
    }, machine.instructions.items);
}
test "value-use i128 eq-min rolls back after the first spill reload" {
    var failing = std.testing.FailingAllocator.init(std.testing.allocator, .{});
    const allocator = failing.allocator();
    var machine = MachineFunction.init("value-use-i128-pair-partial-spill", .{ .int = 1 });
    defer machine.deinit(allocator);
    var plan = SelectorAllocationPlan.init(allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "source");
    try addAtCurrent(&plan, "result");
    var selector = ComposedBlockSelector.init(allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "source", .{ .spill128 = .{
        .lo = .slot0,
        .hi = .slot1,
    } });
    const saved_source = selector.values.get("source").?;
    const saved_accumulator_domain = selector.accumulator_domain;
    const saved_eflags = selector.eflags.snapshot();
    const saved_semantics = selector.eflags_semantics.items.len;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const source = try registerI128PairAction(
        &transaction,
        .{ .named = "source" },
        "result",
        .eq_min,
    );
    try transaction.seal();
    _ = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();

    // The first reload fits. Growing for the second reload fails, so the
    // transaction must roll the already-appended low-limb reload back.
    try machine.instructions.ensureTotalCapacityPrecise(allocator, 1);
    failing.resize_fail_index = failing.resize_index;
    failing.fail_index = failing.alloc_index;
    try std.testing.expectError(
        error.OutOfMemory,
        transaction.executePreparedAction(try transaction.preparedView(source)),
    );

    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.capacity);
    try std.testing.expectEqual(
        machine_module.Instruction{ .reload_arg64_rsp = .{
            .reg = .rcx,
            .frame_index = .slot0,
        } },
        machine.instructions.items.ptr[0],
    );
    try std.testing.expectEqual(saved_source, selector.values.get("source").?);
    try std.testing.expect(selector.values.get("result") == null);
    try std.testing.expect(std.meta.eql(saved_accumulator_domain, selector.accumulator_domain));
    try selector.eflags.validateSnapshot(saved_eflags);
    try std.testing.expectEqual(saved_semantics, selector.eflags_semantics.items.len);
}
test "value-use i128 equality wrapper rolls back exactly at every partial stage" {
    inline for (std.meta.tags(Transaction.I128EqMinTestFailure)) |boundary|
        try expectI128PairRollbackExact(.{ .eq_min = boundary });
}
test "value-use i128 sign-bit wrapper rolls back exactly at every partial stage" {
    inline for (std.meta.tags(Transaction.I128SignBitTestFailure)) |boundary|
        try expectI128PairRollbackExact(.{ .sign_bit = boundary });
}
