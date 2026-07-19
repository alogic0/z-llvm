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
