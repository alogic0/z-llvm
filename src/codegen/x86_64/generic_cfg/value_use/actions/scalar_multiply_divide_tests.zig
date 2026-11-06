const support = @import("../test_support.zig");
const scalar_multiply = @import("scalar_multiply_divide.zig");

const std = support.std;
const ir = support.ir;
const machine_module = support.machine_module;
const selector_state = support.selector_state;
const ComposedBlockSelector = support.ComposedBlockSelector;
const MachineFunction = support.MachineFunction;
const SelectorAllocationPlan = support.SelectorAllocationPlan;
const Transaction = support.Transaction;
const ValueLoc = support.ValueLoc;
const expected = support.expected;
const actionIdentity = support.actionIdentity;

const frame_lhs = support.selector_types.FrameIndex{ .slot = 8 };
const frame_rhs = support.selector_types.FrameIndex{ .slot = 10 };

const Handles = struct {
    lhs: Transaction.RequestHandle,
    rhs: Transaction.RequestHandle,
};

const QuotientHandles = struct {
    rhs: Transaction.RequestHandle,
    lhs: Transaction.RequestHandle,
};

fn registerMultiply(transaction: *Transaction) !Handles {
    const lhs = try transaction.register(.{
        .source = .{ .named = "lhs" },
        .expected = expected(.{ .int = 64 }, .gpr64),
        .form = .named_scalar_operand,
        .destination = .prepared_view,
    });
    const rhs = try transaction.register(.{
        .source = .{ .named = "rhs" },
        .expected = expected(.{ .int = 64 }, .gpr64),
        .form = .named_scalar_operand,
        .destination = .prepared_source,
    });
    try transaction.attachScalarMultiplyAction(lhs, .{
        .result = try actionIdentity("result"),
        .integer_ty = .{ .int = 64 },
        .rhs = rhs,
    });
    return .{ .lhs = lhs, .rhs = rhs };
}

fn registerQuotient(transaction: *Transaction, bits: u16) !QuotientHandles {
    const ty: ir.Type = .{ .int = bits };
    const class: support.selector_types.VirtualRegClass = if (bits == 32) .gpr32 else .gpr64;
    const rhs = try transaction.register(.{
        .source = .{ .named = "rhs" },
        .expected = expected(ty, class),
        .form = .named_scalar_operand,
        .destination = .prepared_source,
    });
    const lhs = try transaction.register(.{
        .source = .{ .named = "lhs" },
        .expected = expected(ty, class),
        .form = .named_scalar_operand,
        .destination = .prepared_view,
    });
    try transaction.attachUnsignedQuotientAction(lhs, .{
        .result = try actionIdentity("result"),
        .integer_ty = ty,
        .rhs = rhs,
    });
    return .{ .rhs = rhs, .lhs = lhs };
}

fn installPlan(
    plan: *SelectorAllocationPlan,
    lhs_end: usize,
    rhs_end: usize,
) !void {
    try plan.interval_ends.put("lhs", lhs_end);
    try plan.interval_ends.put("rhs", rhs_end);
    try plan.interval_ends.put("result", 2);
}

fn blockScratchRegs(
    selector: *ComposedBlockSelector,
    plan: *SelectorAllocationPlan,
    except: ?support.selector_types.ArgReg,
) !void {
    for (support.selector_types.selector_allocatable_regs, 0..) |reg, index| {
        if (except != null and reg == except.?) continue;
        var name_buffer: [16]u8 = undefined;
        const name = try std.fmt.bufPrint(&name_buffer, "blocker{d}", .{index});
        const owned = try selector.allocator.dupe(u8, name);
        try selector.machine.owned_labels.append(selector.allocator, owned);
        try plan.interval_ends.put(owned, 10);
        try selector_state.bindValueLoc(selector, owned, .{ .scratch64 = reg });
    }
}

fn executeAndCommit(transaction: *Transaction, handles: Handles) !void {
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(handles.lhs));
    try transaction.commit();
}

fn executeQuotientAndCommit(
    transaction: *Transaction,
    handles: QuotientHandles,
) !void {
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(handles.lhs));
    try transaction.commit();
}

test "scalar multiply classifier and closed action admit only named i64 multiply" {
    const admitted = ir.BinaryInst{
        .op = .mul,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    };
    try std.testing.expect(scalar_multiply.isScalarMultiply(admitted));
    var rejected = admitted;
    rejected.op = .add;
    try std.testing.expect(!scalar_multiply.isScalarMultiply(rejected));
    rejected = admitted;
    rejected.ty = .{ .int = 32 };
    try std.testing.expect(!scalar_multiply.isScalarMultiply(rejected));
    rejected = admitted;
    rejected.rhs = .{ .int = 7 };
    try std.testing.expect(!scalar_multiply.isScalarMultiply(rejected));
}

test "scalar multiply M64-D derives planned destination and retains durable result" {
    var machine = MachineFunction.init("m64-d", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try installPlan(&plan, 1, 1);
    try plan.assignments.put("result", .{ .gpr64 = .r8 });
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .arg64 = .rsi });

    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handles = try registerMultiply(&transaction);
        try executeAndCommit(&transaction, handles);
    }
    try selector_state.emitValueIntoScratch(
        &selector,
        .{ .named = "result" },
        .r9,
        64,
    );
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_arg64_arg = .{ .dst = .r8, .src = .rdi } },
        .{ .imul_arg64_arg64 = .{ .dst = .r8, .src = .rsi } },
        .{ .mov_arg64_arg = .{ .dst = .r9, .src = .r8 } },
    }, machine.instructions.items);
    try std.testing.expectEqual(
        ValueLoc{ .scratch64 = .r8 },
        selector_state.resolveValue(&selector, .{ .named = "result" }).?,
    );
    try std.testing.expectEqual(
        ValueLoc{ .scratch64 = .r8 },
        selector_state.resolveValue(&selector, .{ .named = "result" }).?,
    );
}

test "scalar multiply M64-D uses accumulator only when a second scratch is unavailable" {
    var machine = MachineFunction.init("m64-d-rhs-spill", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try installPlan(&plan, 1, 1);
    try plan.assignments.put("result", .{ .gpr64 = .r8 });
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .spill64 = frame_rhs });
    try blockScratchRegs(&selector, &plan, .r8);

    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handles = try registerMultiply(&transaction);
        try executeAndCommit(&transaction, handles);
    }
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_arg64_arg = .{ .dst = .r8, .src = .rdi } },
        .{ .reload_rsp_rax = frame_rhs },
        .{ .imul_arg64_rax = .r8 },
    }, machine.instructions.items);
}

test "scalar multiply M64-R is selected internally for spill lhs without result scratch" {
    var machine = MachineFunction.init("m64-r", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try installPlan(&plan, 1, 1);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "lhs", .{ .spill64 = frame_lhs });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .spill64 = frame_rhs });
    try blockScratchRegs(&selector, &plan, null);

    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handles = try registerMultiply(&transaction);
        try executeAndCommit(&transaction, handles);
    }
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .reload_rsp_rax = frame_lhs },
        .{ .imul_rax_rsp = frame_rhs },
    }, machine.instructions.items);
    try std.testing.expectEqual(
        ValueLoc.rax,
        selector_state.resolveValue(&selector, .{ .named = "result" }).?,
    );
}

test "scalar multiply source-order errors retain exact request provenance in both plans" {
    const PlanKind = enum { destination, accumulator };
    inline for (std.meta.tags(PlanKind)) |kind| {
        inline for ([_]bool{ false, true }) |fail_rhs| {
            var machine = MachineFunction.init(@tagName(kind), .{ .int = 64 });
            defer machine.deinit(std.testing.allocator);
            var plan = SelectorAllocationPlan.init(std.testing.allocator);
            defer plan.deinit();
            try installPlan(&plan, 1, 1);
            if (kind == .destination)
                try plan.assignments.put("result", .{ .gpr64 = .r8 });
            var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
            defer selector.deinit();
            selector.allocation_plan = &plan;
            selector.current_position = 1;
            selector.stack_frame_bytes = 128;
            if (fail_rhs) {
                try selector_state.bindValueLoc(
                    &selector,
                    "lhs",
                    if (kind == .destination) .{ .arg64 = .rdi } else .{ .spill64 = frame_lhs },
                );
            } else {
                try selector_state.bindValueLoc(&selector, "rhs", .{ .arg64 = .rsi });
            }
            if (kind == .accumulator) try blockScratchRegs(&selector, &plan, null);

            var transaction = try Transaction.begin(&selector);
            defer transaction.deinit();
            const handles = try registerMultiply(&transaction);
            try std.testing.expectError(error.ValueUseForwardPlanMissing, transaction.seal());
            try std.testing.expectEqual(!fail_rhs, transaction.failedRequestIs(handles.lhs));
            try std.testing.expectEqual(fail_rhs, transaction.failedRequestIs(handles.rhs));
            try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        }
    }
}

test "scalar multiply width diagnostics precede both closed plan branches" {
    const PlanKind = enum { destination, accumulator };
    inline for (std.meta.tags(PlanKind)) |kind| {
        var machine = MachineFunction.init(@tagName(kind), .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try installPlan(&plan, 1, 1);
        if (kind == .destination)
            try plan.assignments.put("result", .{ .gpr64 = .r8 });
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 1;
        selector.stack_frame_bytes = 128;
        try selector_state.bindValueLoc(
            &selector,
            "lhs",
            if (kind == .destination) .{ .arg64 = .rdi } else .{ .spill64 = frame_lhs },
        );
        try selector_state.bindValueLoc(&selector, "rhs", .{ .arg64 = .rsi });
        selector.values.getPtr("rhs").?.vreg.bits = 32;
        if (kind == .accumulator) try blockScratchRegs(&selector, &plan, null);

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handles = try registerMultiply(&transaction);
        try std.testing.expectError(
            error.ValueUseNamedScalarWidthUnsupported,
            transaction.seal(),
        );
        try std.testing.expect(!transaction.failedRequestIs(handles.lhs));
        try std.testing.expect(transaction.failedRequestIs(handles.rhs));
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
}

test "scalar multiply rollback is exact at every declared destination and accumulator boundary" {
    inline for (std.meta.tags(Transaction.ScalarMultiplyTestFailure)) |failure| {
        const accumulator_plan = switch (failure) {
            .after_accumulator_preparation, .after_lhs_accumulator_reload => true,
            else => false,
        };
        const preservation_plan = failure == .after_lhs_preservation or
            failure == .after_canonical_refresh;
        const rhs_stage_plan = failure == .after_rhs_staging;

        var machine = MachineFunction.init(@tagName(failure), .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try installPlan(&plan, if (preservation_plan) 10 else 1, 1);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 1;
        selector.stack_frame_bytes = 128;

        if (accumulator_plan) {
            try selector_state.bindValueLoc(&selector, "lhs", .{ .spill64 = frame_lhs });
            try selector_state.bindValueLoc(&selector, "rhs", .{ .spill64 = frame_rhs });
            try blockScratchRegs(&selector, &plan, null);
        } else if (preservation_plan) {
            try selector_state.bindValueLoc(&selector, "lhs", .{ .scratch64 = .r8 });
            try selector_state.bindValueLoc(&selector, "rhs", .{ .arg64 = .rsi });
            try blockScratchRegs(&selector, &plan, .r8);
        } else {
            try plan.assignments.put("result", .{ .gpr64 = .r8 });
            try selector_state.bindValueLoc(&selector, "lhs", .{ .arg64 = .rdi });
            try selector_state.bindValueLoc(
                &selector,
                "rhs",
                if (rhs_stage_plan) .{ .spill64 = frame_rhs } else .{ .arg64 = .rsi },
            );
            if (rhs_stage_plan) try blockScratchRegs(&selector, &plan, .r8);
        }
        const initial_lhs = selector_state.resolveValue(&selector, .{ .named = "lhs" }).?;
        const initial_rhs = selector_state.resolveValue(&selector, .{ .named = "rhs" }).?;

        {
            var transaction = try Transaction.begin(&selector);
            defer transaction.deinit();
            const handles = try registerMultiply(&transaction);
            try transaction.seal();
            try transaction.prepare();
            try transaction.materializeAll();
            transaction.scalar_multiply_test_failure = failure;
            try std.testing.expectError(
                error.ValueUseScalarMultiplyTestFailure,
                transaction.executePreparedAction(try transaction.preparedView(handles.lhs)),
            );
        }
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(
            initial_lhs,
            selector_state.resolveValue(&selector, .{ .named = "lhs" }).?,
        );
        try std.testing.expectEqual(
            initial_rhs,
            selector_state.resolveValue(&selector, .{ .named = "rhs" }).?,
        );
        try std.testing.expect(selector_state.resolveValue(
            &selector,
            .{ .named = "result" },
        ) == null);
        try std.testing.expectEqual(@as(usize, 0), selector.eflags_semantics.items.len);
    }
}

test "unsigned quotient classifier and closed action admit only named udiv i32 and i64" {
    const admitted32 = ir.BinaryInst{
        .op = .udiv,
        .ty = .{ .int = 32 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    };
    try std.testing.expect(scalar_multiply.isUnsignedQuotient(admitted32));
    var admitted64 = admitted32;
    admitted64.ty = .{ .int = 64 };
    try std.testing.expect(scalar_multiply.isUnsignedQuotient(admitted64));

    var rejected = admitted32;
    rejected.op = .urem;
    try std.testing.expect(!scalar_multiply.isUnsignedQuotient(rejected));
    rejected = admitted32;
    rejected.ty = .{ .int = 16 };
    try std.testing.expect(!scalar_multiply.isUnsignedQuotient(rejected));
    rejected = admitted32;
    rejected.rhs = .{ .int = 7 };
    try std.testing.expect(!scalar_multiply.isUnsignedQuotient(rejected));
}

test "unsigned quotient UQ32 derives non-accumulator staging and retains durable result" {
    var machine = MachineFunction.init("uq32-non-accumulator", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try installPlan(&plan, 1, 1);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg32 = .rdi });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .arg32 = .rsi });

    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handles = try registerQuotient(&transaction, 32);
        try executeQuotientAndCommit(&transaction, handles);
    }
    try selector_state.emitValueIntoScratch(
        &selector,
        .{ .named = "result" },
        .r9,
        32,
    );
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_arg_eax = .rdi },
        .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rsi } },
        .xor_edx_edx,
        .{ .div_arg32 = .rcx },
        .{ .mov_eax_to_arg = .r9 },
    }, machine.instructions.items);
    try std.testing.expectEqual(
        ValueLoc.eax,
        selector_state.resolveValue(&selector, .{ .named = "result" }).?,
    );
}

test "unsigned quotient UQ32 derives accumulator-first RHS staging" {
    var machine = MachineFunction.init("uq32-accumulator-rhs", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try installPlan(&plan, 1, 1);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    try selector_state.bindValueLoc(&selector, "rhs", .eax);
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg32 = .rdi });

    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handles = try registerQuotient(&transaction, 32);
        try executeQuotientAndCommit(&transaction, handles);
    }
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_eax_to_arg = .rcx },
        .{ .mov_arg_eax = .rdi },
        .xor_edx_edx,
        .{ .div_arg32 = .rcx },
    }, machine.instructions.items);
}

test "unsigned quotient UQ64 derives non-accumulator staging and retains durable result" {
    var machine = MachineFunction.init("uq64-non-accumulator", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try installPlan(&plan, 1, 1);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .arg64 = .rsi });

    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handles = try registerQuotient(&transaction, 64);
        try executeQuotientAndCommit(&transaction, handles);
    }
    try selector_state.emitValueIntoScratch(
        &selector,
        .{ .named = "result" },
        .r9,
        64,
    );
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_arg_rax = .rdi },
        .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rsi } },
        .xor_edx_edx,
        .{ .div_arg64 = .rcx },
        .{ .mov_rax_to_arg = .r9 },
    }, machine.instructions.items);
    try std.testing.expectEqual(
        ValueLoc.rax,
        selector_state.resolveValue(&selector, .{ .named = "result" }).?,
    );
}

test "unsigned quotient UQ64 derives accumulator-first RHS staging" {
    var machine = MachineFunction.init("uq64-accumulator-rhs", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try installPlan(&plan, 1, 1);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    try selector_state.bindValueLoc(&selector, "rhs", .rax);
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg64 = .rdi });

    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handles = try registerQuotient(&transaction, 64);
        try executeQuotientAndCommit(&transaction, handles);
    }
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_rax_to_arg = .rcx },
        .{ .mov_arg_rax = .rdi },
        .xor_edx_edx,
        .{ .div_arg64 = .rcx },
    }, machine.instructions.items);
}

test "unsigned quotient preserves live RCX and RDX occupants in frozen order" {
    var machine = MachineFunction.init("uq64-fixed-register-preservation", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try installPlan(&plan, 1, 1);
    try plan.interval_ends.put("live_rcx", 2);
    try plan.interval_ends.put("live_rdx", 2);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .arg64 = .rsi });
    try selector_state.bindValueLoc(&selector, "live_rcx", .{ .scratch64 = .rcx });
    try selector_state.bindValueLoc(&selector, "live_rdx", .{ .scratch64 = .rdx });

    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handles = try registerQuotient(&transaction, 64);
        try executeQuotientAndCommit(&transaction, handles);
    }
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_arg_rax = .rdi },
        .{ .spill_arg64_rsp = .{ .frame_index = .slot0, .reg = .rcx } },
        .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rsi } },
        .{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = .rdx } },
        .xor_edx_edx,
        .{ .div_arg64 = .rcx },
    }, machine.instructions.items);
    try std.testing.expectEqual(
        ValueLoc{ .spill64 = .slot0 },
        selector_state.resolveValue(&selector, .{ .named = "live_rcx" }).?,
    );
    try std.testing.expectEqual(
        ValueLoc{ .spill64 = .slot2 },
        selector_state.resolveValue(&selector, .{ .named = "live_rdx" }).?,
    );
}

test "unsigned quotient request failures preserve RHS-before-lhs provenance" {
    inline for ([_]bool{ true, false }) |fail_rhs| {
        var machine = MachineFunction.init(if (fail_rhs) "uq-rhs-fail" else "uq-lhs-fail", .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try installPlan(&plan, 1, 1);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 1;
        if (fail_rhs)
            try selector_state.bindValueLoc(&selector, "lhs", .{ .arg64 = .rdi })
        else
            try selector_state.bindValueLoc(&selector, "rhs", .{ .arg64 = .rsi });

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handles = try registerQuotient(&transaction, 64);
        try std.testing.expectError(error.ValueUseForwardPlanMissing, transaction.seal());
        try std.testing.expectEqual(fail_rhs, transaction.failedRequestIs(handles.rhs));
        try std.testing.expectEqual(!fail_rhs, transaction.failedRequestIs(handles.lhs));
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
}

test "unsigned quotient rollback is exact at every declared failure boundary" {
    inline for (std.meta.tags(Transaction.UnsignedQuotientTestFailure)) |failure| {
        const accumulator_rhs = failure == .after_rhs_accumulator_staging;
        var machine = MachineFunction.init(@tagName(failure), .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try installPlan(&plan, 1, 1);
        try plan.interval_ends.put("live_rdx", 2);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 1;
        selector.stack_frame_bytes = 128;
        try selector_state.bindValueLoc(&selector, "lhs", .{ .arg64 = .rdi });
        try selector_state.bindValueLoc(
            &selector,
            "rhs",
            if (accumulator_rhs) .rax else .{ .arg64 = .rsi },
        );
        try selector_state.bindValueLoc(&selector, "live_rdx", .{ .scratch64 = .rdx });
        const initial_lhs = selector_state.resolveValue(&selector, .{ .named = "lhs" }).?;
        const initial_rhs = selector_state.resolveValue(&selector, .{ .named = "rhs" }).?;
        const initial_rdx = selector_state.resolveValue(&selector, .{ .named = "live_rdx" }).?;

        {
            var transaction = try Transaction.begin(&selector);
            defer transaction.deinit();
            const handles = try registerQuotient(&transaction, 64);
            try transaction.seal();
            try transaction.prepare();
            try transaction.materializeAll();
            transaction.unsigned_quotient_test_failure = failure;
            try std.testing.expectError(
                error.ValueUseUnsignedQuotientTestFailure,
                transaction.executePreparedAction(try transaction.preparedView(handles.lhs)),
            );
        }
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(
            initial_lhs,
            selector_state.resolveValue(&selector, .{ .named = "lhs" }).?,
        );
        try std.testing.expectEqual(
            initial_rhs,
            selector_state.resolveValue(&selector, .{ .named = "rhs" }).?,
        );
        try std.testing.expectEqual(
            initial_rdx,
            selector_state.resolveValue(&selector, .{ .named = "live_rdx" }).?,
        );
        try std.testing.expect(selector_state.resolveValue(
            &selector,
            .{ .named = "result" },
        ) == null);
        try std.testing.expectEqual(@as(usize, 0), selector.eflags_semantics.items.len);
    }
}

test "unsigned quotient executes RCX dividend and accumulator divisor with final uses and live aliases" {
    const encoding = @import("../../../../../mc/encoding.zig");
    for ([_]u16{ 32, 64 }) |bits| for ([_]bool{ false, true }) |live| {
        var output = MachineFunction.init("quotient-overlap", .{ .int = bits });
        defer output.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try installPlan(&plan, 1, 1);
        if (live) {
            try plan.interval_ends.put("lhs-alias", 10);
            try plan.interval_ends.put("rhs-alias", 10);
        }
        var state = ComposedBlockSelector.init(std.testing.allocator, &output);
        defer state.deinit();
        state.allocation_plan = &plan;
        state.current_position = 1;
        state.stack_frame_bytes = 136;
        const lhs: ValueLoc = if (bits == 64) .{ .arg64 = .rcx } else .{ .arg32 = .rcx };
        const rhs: ValueLoc = if (bits == 64) .rax else .eax;
        try selector_state.bindValueLoc(&state, "lhs", lhs);
        try selector_state.bindValueLoc(&state, "rhs", rhs);
        if (live) {
            try selector_state.bindValueLoc(&state, "lhs-alias", lhs);
            try selector_state.bindValueLoc(&state, "rhs-alias", rhs);
        }
        try output.instructions.appendSlice(std.testing.allocator, &.{
            .{ .sub_rsp_imm32 = 136 },
            .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rdi } },
            .{ .mov_arg_rax = .rsi },
        });
        var transaction = try Transaction.begin(&state);
        defer transaction.deinit();
        const handles = try registerQuotient(&transaction, bits);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(handles.lhs));
        try transaction.commit();
        if (live) {
            try selector_state.emitBinaryLocIntoAccumulator(&state, .xor, selector_state.valueLoc(&state, "lhs-alias").?, bits);
            try selector_state.emitBinaryLocIntoAccumulator(&state, .xor, selector_state.valueLoc(&state, "rhs-alias").?, bits);
        }
        try output.instructions.appendSlice(std.testing.allocator, &.{ .{ .add_rsp_imm32 = 136 }, .ret });
        const bytes = try encoding.encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(bytes);
        const memory = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..bytes.len], bytes);
        const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(memory.ptr);
        const values = [_]u64{ 0, 1, 2, 3, 0x7fff_ffff, 0x8000_0000, 0xffff_ffff, 0x7fff_ffff_ffff_ffff, 0x8000_0000_0000_0000, 0xffff_ffff_0000_0001, 0xffff_ffff_ffff_ffff };
        for (values) |a| for (values) |b| {
            const mask: u64 = if (bits == 64) std.math.maxInt(u64) else 0xffff_ffff;
            const x = a & mask;
            const y = b & mask;
            if (y == 0) continue;
            const wanted = (x / y) ^ (if (live) x ^ y else @as(u64, 0));
            try std.testing.expectEqual(wanted, run(a, b));
        };
    };
}
