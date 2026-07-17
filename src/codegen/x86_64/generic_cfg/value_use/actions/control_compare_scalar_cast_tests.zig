const support = @import("../test_support.zig");

const std = support.std;
const ir = support.ir;
const machine_module = support.machine_module;
const selector_types = support.selector_types;
const selector_state = support.selector_state;
const ComposedBlockSelector = support.ComposedBlockSelector;
const MachineFunction = support.MachineFunction;
const SelectorAllocationPlan = support.SelectorAllocationPlan;
const Transaction = support.Transaction;
const ValueLoc = support.ValueLoc;
const addAtCurrent = support.addAtCurrent;
const expected = support.expected;
const actionIdentity = support.actionIdentity;

fn registerPairLowCast(
    transaction: *Transaction,
    result: []const u8,
    to_bits: u16,
) !Transaction.RequestHandle {
    return transaction.register(.{
        .source = .{ .named = "source" },
        .expected = expected(.{ .int = 128 }, .gpr128),
        .form = .pair_low_scalar_cast_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .pair_low_scalar_cast = .{
            .result = try actionIdentity(result),
            .op = .trunc,
            .from_bits = 128,
            .to_bits = to_bits,
        } },
    });
}

fn registerAccumulatorCast(
    transaction: *Transaction,
    source: ir.Value,
    result: []const u8,
    op: ir.CastOp,
    from_bits: u16,
    to_bits: u16,
    exact_ei: bool,
) !Transaction.RequestHandle {
    return transaction.register(.{
        .source = source,
        .expected = expected(
            .{ .int = from_bits },
            if (from_bits <= 32) .gpr32 else .gpr64,
        ),
        .form = .accumulator_scalar_cast_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .accumulator_scalar_cast = .{
            .result = try actionIdentity(result),
            .op = op,
            .from_bits = from_bits,
            .to_bits = to_bits,
            .immediate = switch (source) {
                .int => |value| value,
                else => null,
            },
            .exact_ei = exact_ei,
        } },
    });
}

fn registerSignExtend(transaction: *Transaction, result: []const u8) !Transaction.RequestHandle {
    return transaction.register(.{
        .source = .{ .named = "source" },
        .expected = expected(.{ .int = 32 }, .gpr32),
        .form = .sign_extend_scratch_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .sign_extend_scratch = .{
            .result = try actionIdentity(result),
        } },
    });
}

fn executePairLowCase(
    source_loc: ValueLoc,
    expected_instructions: []const machine_module.Instruction,
) !void {
    var machine = MachineFunction.init("value-use-pair-low-cast", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "source");
    try addAtCurrent(&plan, "result");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", source_loc);

    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerPairLowCast(&transaction, "result", 64);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(source));
        try transaction.commit();
    }

    try std.testing.expectEqualSlices(
        machine_module.Instruction,
        expected_instructions,
        machine.instructions.items,
    );
    try std.testing.expect(selector_state.resolveValue(&selector, .{ .named = "result" }) != null);
}

fn executeAccumulatorCase(
    source: ir.Value,
    source_loc: ?ValueLoc,
    op: ir.CastOp,
    from_bits: u16,
    to_bits: u16,
    exact_ei: bool,
    expected_instructions: []const machine_module.Instruction,
    expected_writes: usize,
) !void {
    var machine = MachineFunction.init("value-use-accumulator-cast", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    if (source == .named) try addAtCurrent(&plan, "source");
    try addAtCurrent(&plan, "result");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    if (source_loc) |loc| try selector_state.bindValueLoc(&selector, "source", loc);

    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handle = try registerAccumulatorCast(
            &transaction,
            source,
            "result",
            op,
            from_bits,
            to_bits,
            exact_ei,
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(handle));
        try transaction.commit();
    }

    try std.testing.expectEqualSlices(
        machine_module.Instruction,
        expected_instructions,
        machine.instructions.items,
    );
    try std.testing.expectEqual(expected_writes, selector.eflags_semantics.items.len);
    for (selector.eflags_semantics.items) |record|
        try std.testing.expectEqual(selector_state.EflagsEffect.write, record.effect);
}

test "value-use scalar cast classifiers are pure and fence alias and pair-result casts" {
    try std.testing.expect(Transaction.isPairLowScalarCast(.{
        .op = .trunc,
        .value = .{ .named = "source" },
        .from_ty = .{ .int = 128 },
        .to_ty = .{ .int = 64 },
    }));
    try std.testing.expect(Transaction.isAccumulatorScalarCast(.{
        .op = .zext,
        .value = .{ .named = "source" },
        .from_ty = .{ .int = 55 },
        .to_ty = .{ .int = 64 },
    }, true));
    try std.testing.expect(Transaction.isSignExtendScratchCast(.{
        .op = .sext,
        .value = .{ .named = "source" },
        .from_ty = .{ .int = 32 },
        .to_ty = .{ .int = 64 },
    }));

    // C02 alias-only and C03 pair-result remain with their O4 owners.
    try std.testing.expect(!Transaction.isPairLowScalarCast(.{
        .op = .trunc,
        .value = .{ .named = "source" },
        .from_ty = .{ .int = 64 },
        .to_ty = .{ .int = 32 },
    }));
    try std.testing.expect(!Transaction.isAccumulatorScalarCast(.{
        .op = .zext,
        .value = .{ .named = "source" },
        .from_ty = .{ .int = 64 },
        .to_ty = .{ .int = 128 },
    }, false));
}

test "value-use pair-low scalar cast preserves existing pair low-limb streams" {
    try executePairLowCase(.{ .arg128 = selector_types.pair_a }, &.{});
    try executePairLowCase(.{ .scratch128 = selector_types.pair_b }, &.{});
    try executePairLowCase(
        .{ .stack128_value = 32 },
        &.{.{ .load_stack_disp8_arg64 = .{ .reg = .rdi, .disp = 32 } }},
    );
    try executePairLowCase(
        .{ .spill128 = .{ .lo = .slot0, .hi = .slot1 } },
        &.{.{ .reload_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot0 } }},
    );
}

test "value-use accumulator scalar cast reproduces ordinary exact-EI and i52 streams" {
    try executeAccumulatorCase(
        .{ .named = "source" },
        .{ .arg32 = .rdi },
        .zext,
        6,
        64,
        false,
        &.{ .{ .mov_arg_eax = .rdi }, .{ .and_eax_imm32 = 63 } },
        1,
    );
    try executeAccumulatorCase(
        .{ .int = 7 },
        null,
        .zext,
        6,
        32,
        false,
        &.{ .{ .mov_imm_eax = 7 }, .{ .and_eax_imm32 = 63 } },
        1,
    );
    try executeAccumulatorCase(
        .{ .named = "source" },
        .{ .arg64 = .rdi },
        .zext,
        55,
        64,
        true,
        &.{
            .{ .mov_arg_rax = .rdi },
            .{ .mov_imm_rcx = (@as(i64, 1) << 55) - 1 },
            .{ .binary_arg_rax = .{ .op = .@"and", .reg = .rcx } },
        },
        1,
    );
    try executeAccumulatorCase(
        .{ .named = "source" },
        .{ .arg64 = .rdi },
        .trunc,
        64,
        52,
        false,
        &.{
            .{ .mov_arg_rax = .rdi },
            .{ .mov_imm_rcx = (@as(i64, 1) << 52) - 1 },
            .{ .binary_arg_rax = .{ .op = .@"and", .reg = .rcx } },
        },
        1,
    );
    try executeAccumulatorCase(
        .{ .named = "source" },
        .{ .arg64 = .rdi },
        .zext,
        52,
        64,
        false,
        &.{.{ .mov_arg_rax = .rdi }},
        0,
    );
    try executeAccumulatorCase(
        .{ .named = "source" },
        .{ .arg64 = .rdi },
        .trunc,
        52,
        6,
        false,
        &.{ .{ .mov_arg_eax = .rdi }, .{ .and_eax_imm32 = 63 } },
        1,
    );
}

test "value-use sign-extend scratch cast is sessionless durable and byte exact" {
    var machine = MachineFunction.init("value-use-sign-extend-cast", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "source");
    try addAtCurrent(&plan, "result");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg32 = .rdi });

    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerSignExtend(&transaction, "result");
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(source));
        try transaction.commit();
    }
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .movsxd_arg32_arg64 = .{ .dst = .r8, .src = .rdi } },
    }, machine.instructions.items);
    try std.testing.expectEqual(
        ValueLoc{ .scratch64 = .r8 },
        selector_state.resolveValue(&selector, .{ .named = "result" }).?,
    );
}

test "value-use scalar cast request provenance preserves rejected home diagnostics" {
    const cases = [_]struct {
        loc: ValueLoc,
        class: selector_types.VirtualRegClass,
        bits: u16,
        expected_error: anyerror,
    }{
        .{ .loc = .eax, .class = .gpr32, .bits = 32, .expected_error = error.ValueUseScalarCastLocationUnsupported },
        .{ .loc = .{ .spill64 = .slot0 }, .class = .gpr32, .bits = 32, .expected_error = error.ValueUseScalarCastLocationUnsupported },
        .{ .loc = .{ .arg64 = .rdi }, .class = .gpr64, .bits = 64, .expected_error = error.ValueUseScalarCastWidthUnsupported },
    };
    for (cases) |case| {
        var machine = MachineFunction.init("value-use-sign-extend-reject", .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "source", case.loc);
        selector.values.getPtr("source").?.vreg.class = case.class;
        selector.values.getPtr("source").?.vreg.bits = case.bits;
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerSignExtend(&transaction, "result");
        const outcome = transaction.seal();
        if (outcome) |_| {
            try transaction.prepare();
            try transaction.materializeAll();
            try std.testing.expectError(
                case.expected_error,
                transaction.executePreparedAction(try transaction.preparedView(source)),
            );
        } else |err| {
            try std.testing.expectEqual(case.expected_error, err);
        }
        try std.testing.expect(transaction.failedRequestIs(source));
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
}

test "value-use scalar cast unresolved source fails before home classification" {
    var machine = MachineFunction.init("value-use-sign-extend-unresolved", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "source");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const source = try registerSignExtend(&transaction, "result");
    try std.testing.expectError(error.ValueUseUnresolvedSource, transaction.seal());
    try std.testing.expect(transaction.failedRequestIs(source));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "value-use pair-low scalar cast preserves width-before-home diagnostic precedence" {
    const cases = [_]struct {
        loc: ValueLoc,
        class: selector_types.VirtualRegClass,
        bits: u16,
        expected_error: Transaction.ScalarCastRequestError,
    }{
        .{
            .loc = .{ .arg64 = .rdi },
            .class = .gpr64,
            .bits = 64,
            .expected_error = error.ValueUseScalarCastWidthUnsupported,
        },
        .{
            .loc = .{ .arg64 = .rdi },
            .class = .gpr128,
            .bits = 128,
            .expected_error = error.ValueUseScalarCastLocationUnsupported,
        },
    };
    for (cases) |case| {
        var machine = MachineFunction.init("value-use-pair-low-reject", .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "source", case.loc);
        selector.values.getPtr("source").?.vreg.class = case.class;
        selector.values.getPtr("source").?.vreg.bits = case.bits;
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerPairLowCast(&transaction, "result", 64);
        const outcome = transaction.seal();
        if (outcome) |_| {
            try transaction.prepare();
            try transaction.materializeAll();
            try std.testing.expectError(
                case.expected_error,
                transaction.executePreparedAction(try transaction.preparedView(source)),
            );
        } else |err| {
            try std.testing.expectEqual(case.expected_error, err);
        }
        try std.testing.expect(transaction.failedRequestIs(source));
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
}

test "value-use scalar cast rollback restores every partial action boundary" {
    const boundaries = [_]Transaction.ScalarCastTestFailure{
        .after_accumulator_preparation,
        .after_accumulator_materialization,
        .after_mask_materialization,
        .after_mask,
        .after_result_identity_ownership,
        .after_result_definition,
        .after_finalization,
    };
    for (boundaries) |boundary| {
        var machine = MachineFunction.init("value-use-accumulator-cast-rollback", .{ .int = 64 });
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
        const source = try registerAccumulatorCast(
            &transaction,
            .{ .named = "source" },
            "result",
            .trunc,
            64,
            52,
            false,
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.setScalarCastTestFailure(boundary);
        try std.testing.expectError(
            error.ValueUseScalarCastTestFailure,
            transaction.executePreparedAction(try transaction.preparedView(source)),
        );
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
        try std.testing.expect(selector.values.get("result") == null);
        try std.testing.expectEqual(@as(usize, 0), selector.eflags_semantics.items.len);
    }
}

test "value-use sessionless scalar cast rollback frees owned result exactly once" {
    const boundaries = [_]Transaction.ScalarCastTestFailure{
        .after_result_identity_ownership,
        .after_result_definition,
    };
    for (boundaries) |boundary| {
        var failing = std.testing.FailingAllocator.init(std.testing.allocator, .{});
        const allocator = failing.allocator();
        var machine = MachineFunction.init("value-use-sign-extend-owned-rollback", .{ .int = 64 });
        defer machine.deinit(allocator);
        var plan = SelectorAllocationPlan.init(allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        var selector = ComposedBlockSelector.init(allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "source", .{ .arg32 = .rdi });
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerSignExtend(&transaction, "result");
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try machine.instructions.ensureUnusedCapacity(allocator, 1);
        try machine.owned_labels.ensureUnusedCapacity(allocator, 1);
        try selector.values.ensureUnusedCapacity(1);
        const allocations_before = failing.allocations;
        const deallocations_before = failing.deallocations;
        try transaction.setScalarCastTestFailure(boundary);
        try std.testing.expectError(
            error.ValueUseScalarCastTestFailure,
            transaction.executePreparedAction(try transaction.preparedView(source)),
        );
        try std.testing.expectEqual(allocations_before + 1, failing.allocations);
        try std.testing.expectEqual(deallocations_before + 1, failing.deallocations);
        try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
        try std.testing.expect(selector.values.get("result") == null);
    }
}

test "value-use pair-low scalar cast rollback frees owned result exactly once" {
    const boundaries = [_]Transaction.ScalarCastTestFailure{
        .after_result_identity_ownership,
        .after_result_definition,
    };
    for (boundaries) |boundary| {
        var failing = std.testing.FailingAllocator.init(std.testing.allocator, .{});
        const allocator = failing.allocator();
        var machine = MachineFunction.init("value-use-pair-low-owned-rollback", .{ .int = 64 });
        defer machine.deinit(allocator);
        var plan = SelectorAllocationPlan.init(allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        var selector = ComposedBlockSelector.init(allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "source", .{ .arg128 = selector_types.pair_a });
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerPairLowCast(&transaction, "result", 64);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try machine.instructions.ensureUnusedCapacity(allocator, 1);
        try machine.owned_labels.ensureUnusedCapacity(allocator, 1);
        try selector.values.ensureUnusedCapacity(1);
        const allocations_before = failing.allocations;
        const deallocations_before = failing.deallocations;
        try transaction.setScalarCastTestFailure(boundary);
        try std.testing.expectError(
            error.ValueUseScalarCastTestFailure,
            transaction.executePreparedAction(try transaction.preparedView(source)),
        );
        try std.testing.expectEqual(allocations_before + 1, failing.allocations);
        try std.testing.expectEqual(deallocations_before + 1, failing.deallocations);
        try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
        try std.testing.expect(selector.values.get("result") == null);
    }
}

test "value-use pair-low scalar cast rolls back scratch selection and pair staging" {
    const boundaries = [_]Transaction.ScalarCastTestFailure{
        .after_scratch_selection,
        .after_pair_staging,
    };
    for (boundaries) |boundary| {
        var machine = MachineFunction.init("value-use-pair-low-staging-rollback", .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "source", .{ .stack128_value = 32 });
        const binding_before = selector.values.get("source").?;
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerPairLowCast(&transaction, "result", 64);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.setScalarCastTestFailure(boundary);
        try std.testing.expectError(
            error.ValueUseScalarCastTestFailure,
            transaction.executePreparedAction(try transaction.preparedView(source)),
        );
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqualDeep(binding_before, selector.values.get("source").?);
        try std.testing.expect(selector.values.get("result") == null);
    }
}

test "value-use sessionless scalar cast identity allocation failures leave no durable state" {
    {
        var failing = std.testing.FailingAllocator.init(std.testing.allocator, .{});
        const allocator = failing.allocator();
        var machine = MachineFunction.init("value-use-pair-low-owned-oom", .{ .int = 64 });
        defer machine.deinit(allocator);
        var plan = SelectorAllocationPlan.init(allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        var selector = ComposedBlockSelector.init(allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "source", .{ .arg128 = selector_types.pair_a });
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerPairLowCast(&transaction, "result", 64);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try machine.instructions.ensureUnusedCapacity(allocator, 1);
        try machine.owned_labels.ensureUnusedCapacity(allocator, 1);
        try selector.values.ensureUnusedCapacity(1);
        failing.fail_index = failing.alloc_index;
        try std.testing.expectError(
            error.OutOfMemory,
            transaction.executePreparedAction(try transaction.preparedView(source)),
        );
        try std.testing.expect(failing.has_induced_failure);
        try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
        try std.testing.expect(selector.values.get("result") == null);
    }
    {
        var failing = std.testing.FailingAllocator.init(std.testing.allocator, .{});
        const allocator = failing.allocator();
        var machine = MachineFunction.init("value-use-sign-extend-owned-oom", .{ .int = 64 });
        defer machine.deinit(allocator);
        var plan = SelectorAllocationPlan.init(allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        var selector = ComposedBlockSelector.init(allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "source", .{ .arg32 = .rdi });
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerSignExtend(&transaction, "result");
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try machine.instructions.ensureUnusedCapacity(allocator, 1);
        try machine.owned_labels.ensureUnusedCapacity(allocator, 1);
        try selector.values.ensureUnusedCapacity(1);
        failing.fail_index = failing.alloc_index;
        try std.testing.expectError(
            error.OutOfMemory,
            transaction.executePreparedAction(try transaction.preparedView(source)),
        );
        try std.testing.expect(failing.has_induced_failure);
        try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
        try std.testing.expect(selector.values.get("result") == null);
    }
}
