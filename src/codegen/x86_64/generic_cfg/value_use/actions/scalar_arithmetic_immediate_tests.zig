const support = @import("../test_support.zig");

const std = support.std;
const ir = support.ir;
const machine_module = support.machine_module;
const selector_state = support.selector_state;
const selector_types = support.selector_types;
const ComposedBlockSelector = support.ComposedBlockSelector;
const MachineFunction = support.MachineFunction;
const SelectorAllocationPlan = support.SelectorAllocationPlan;
const Transaction = support.Transaction;
const ValueLoc = support.ValueLoc;
const addAtCurrent = support.addAtCurrent;
const expected = support.expected;
const actionIdentity = support.actionIdentity;

const Direction = enum { rhs, lhs };

const PlanRow = struct {
    id: []const u8,
    direction: Direction,
    operation: ir.BinaryOp,
    bits: u16,
    literal: i128,
    accumulator: bool,
    scratch: bool,
    writes: u8,
};

const immediate_plan = [_]PlanRow{
    .{ .id = "R00", .direction = .rhs, .operation = .sdiv, .bits = 32, .literal = 2, .accumulator = true, .scratch = false, .writes = 3 },
    .{ .id = "R01", .direction = .rhs, .operation = .lshr, .bits = 64, .literal = 7, .accumulator = false, .scratch = true, .writes = 1 },
    .{ .id = "R02", .direction = .rhs, .operation = .shl, .bits = 32, .literal = 3, .accumulator = true, .scratch = true, .writes = 1 },
    .{ .id = "R03", .direction = .rhs, .operation = .ashr, .bits = 64, .literal = 5, .accumulator = false, .scratch = true, .writes = 1 },
    .{ .id = "R04", .direction = .rhs, .operation = .add, .bits = 32, .literal = 9, .accumulator = true, .scratch = false, .writes = 1 },
    .{ .id = "R05", .direction = .rhs, .operation = .@"and", .bits = 64, .literal = 0x123456789, .accumulator = true, .scratch = false, .writes = 1 },
    .{ .id = "R06", .direction = .rhs, .operation = .sub, .bits = 64, .literal = 11, .accumulator = false, .scratch = true, .writes = 1 },
    .{ .id = "L01", .direction = .lhs, .operation = .sub, .bits = 32, .literal = 17, .accumulator = true, .scratch = false, .writes = 1 },
    .{ .id = "L02", .direction = .lhs, .operation = .shl, .bits = 16, .literal = 3, .accumulator = true, .scratch = false, .writes = 2 },
    .{ .id = "L03", .direction = .lhs, .operation = .lshr, .bits = 64, .literal = 0x1000, .accumulator = true, .scratch = false, .writes = 1 },
};

const DeclaredType = enum { non_integer, i1, i16, i32, i64, i128 };
const BindingClass = enum { gpr32, gpr64, gpr128, fp16, fp32, fp64, vector_xmm, aggregate_sse, stack_object, stack_pointer };
const Home = enum {
    arg32,
    arg64,
    arg128,
    eax,
    rax,
    scratch32,
    scratch64,
    scratch128,
    xmm,
    stack_scalar,
    stack128,
    stack128_value,
    stack_i32_array,
    stack_i32_ptr,
    stack_f32_pair_ptr,
    readonly_table_ptr,
    spill64,
    spill128,
    spill_fp,
    spill_vector,
    aggregate_sse,
};
const Admission = enum { accepted, type_error, width_error, location_error };

fn expectedAdmission(ty: DeclaredType, class: BindingClass, home: Home) Admission {
    const bits: u16 = switch (ty) {
        .non_integer => return .type_error,
        .i1 => 1,
        .i16 => 16,
        .i32 => 32,
        .i64 => 64,
        .i128 => return .width_error,
    };
    const class_valid = if (bits <= 32)
        class == .gpr32 or class == .gpr64
    else
        class == .gpr64;
    if (!class_valid) return .width_error;
    const home_valid = if (bits <= 32)
        switch (home) {
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .spill64 => true,
            else => false,
        }
    else switch (home) {
        .arg64, .rax, .scratch64, .spill64 => true,
        else => false,
    };
    return if (home_valid) .accepted else .location_error;
}

fn binary(row: PlanRow) ir.BinaryInst {
    return .{
        .op = row.operation,
        .ty = .{ .int = row.bits },
        .lhs = if (row.direction == .rhs) .{ .named = "source" } else .{ .int = row.literal },
        .rhs = if (row.direction == .rhs) .{ .int = row.literal } else .{ .named = "source" },
    };
}

fn registerImmediate(
    transaction: *Transaction,
    row: PlanRow,
) !Transaction.RequestHandle {
    const ty: ir.Type = .{ .int = row.bits };
    return transaction.register(.{
        .source = .{ .named = "source" },
        .expected = expected(ty, if (row.bits <= 32) .gpr32 else .gpr64),
        .form = if (row.direction == .rhs)
            .immediate_rhs_scalar_operand
        else
            .immediate_lhs_scalar_operand,
        .destination = .prepared_view,
        .prepared_action = if (row.direction == .rhs)
            .{ .immediate_rhs_scalar = .{
                .result = try actionIdentity("result"),
                .operation = row.operation,
                .integer_ty = ty,
                .literal = row.literal,
            } }
        else
            .{ .immediate_lhs_scalar = .{
                .result = try actionIdentity("result"),
                .operation = row.operation,
                .integer_ty = ty,
                .literal = row.literal,
            } },
    });
}

fn executeImmediate(row: PlanRow, source_loc: ValueLoc) !struct {
    instruction_count: usize,
    write_count: usize,
    result: ValueLoc,
} {
    var machine = MachineFunction.init(row.id, .{ .int = row.bits });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "source");
    try addAtCurrent(&plan, "result");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "source", source_loc);

    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handle = try registerImmediate(&transaction, row);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(handle));
        try transaction.commit();
    }

    return .{
        .instruction_count = machine.instructions.items.len,
        .write_count = selector.eflags_semantics.items.len,
        .result = selector_state.resolveValue(&selector, .{ .named = "result" }).?,
    };
}

test "value-use immediate scalar plan table is closed and direction specific" {
    try std.testing.expectEqual(@as(usize, 10), immediate_plan.len);
    for (immediate_plan) |row| {
        const inst = binary(row);
        try std.testing.expectEqual(
            row.direction == .rhs,
            Transaction.isImmediateRhsScalar(inst),
        );
        try std.testing.expectEqual(
            row.direction == .lhs,
            Transaction.isImmediateLhsScalar(inst),
        );
        try std.testing.expect(row.accumulator or row.scratch);
    }

    const l00: ir.BinaryInst = .{
        .op = .sub,
        .ty = .{ .int = 128 },
        .lhs = .{ .int = 0 },
        .rhs = .{ .named = "pair" },
    };
    try std.testing.expect(!Transaction.isImmediateLhsScalar(l00));
    const pair_rhs: ir.BinaryInst = .{
        .op = .lshr,
        .ty = .{ .int = 128 },
        .lhs = .{ .named = "pair" },
        .rhs = .{ .int = 64 },
    };
    try std.testing.expect(!Transaction.isImmediateRhsScalar(pair_rhs));
}

test "value-use immediate scalar declared-type binding-class home cross product is frozen" {
    var cells: usize = 0;
    var accepted: usize = 0;
    var type_errors: usize = 0;
    var width_errors: usize = 0;
    var location_errors: usize = 0;
    for (std.meta.tags(DeclaredType)) |ty| {
        for (std.meta.tags(BindingClass)) |class| {
            for (std.meta.tags(Home)) |home| {
                cells += 1;
                switch (expectedAdmission(ty, class, home)) {
                    .accepted => accepted += 1,
                    .type_error => type_errors += 1,
                    .width_error => width_errors += 1,
                    .location_error => location_errors += 1,
                }
            }
        }
    }
    try std.testing.expectEqual(@as(usize, 6 * 10 * 21), cells);
    try std.testing.expectEqual(cells, accepted + type_errors + width_errors + location_errors);
    try std.testing.expect(accepted > 0);
    try std.testing.expect(type_errors > 0);
    try std.testing.expect(width_errors > 0);
    try std.testing.expect(location_errors > 0);

    try std.testing.expectEqual(Admission.accepted, expectedAdmission(.i32, .gpr64, .spill64));
    try std.testing.expectEqual(Admission.accepted, expectedAdmission(.i64, .gpr64, .rax));
    try std.testing.expectEqual(Admission.width_error, expectedAdmission(.i64, .gpr32, .scratch32));
    try std.testing.expectEqual(Admission.location_error, expectedAdmission(.i32, .gpr32, .stack_scalar));
    try std.testing.expectEqual(Admission.type_error, expectedAdmission(.non_integer, .gpr32, .arg32));
}

test "value-use immediate scalar representatives retain result ownership and writes" {
    for (immediate_plan) |row| {
        const loc: ValueLoc = if (row.bits <= 32)
            .{ .arg32 = .rdi }
        else
            .{ .arg64 = .rdi };
        const actual = try executeImmediate(row, loc);
        try std.testing.expect(actual.instruction_count > 0);
        try std.testing.expectEqual(@as(usize, row.writes), actual.write_count);
        if (row.accumulator and !row.scratch) {
            try std.testing.expect(actual.result == .eax or actual.result == .rax);
        } else {
            try std.testing.expect(actual.result == .scratch32 or
                actual.result == .scratch64 or actual.result == .spill64 or
                actual.result == .eax or actual.result == .rax);
        }
    }
}

test "value-use immediate scalar exact R00 and variable lhs streams" {
    const cases = [_]struct {
        row: PlanRow,
        expected_instructions: []const machine_module.Instruction,
    }{
        .{
            .row = immediate_plan[0],
            .expected_instructions = &.{
                .{ .mov_arg_eax = .rdi },
                .{ .mov_eax_to_arg = .rcx },
                .{ .shr_eax_imm5 = 31 },
                .add_ecx_eax,
                .{ .sar_eax_imm5 = 1 },
            },
        },
        .{
            .row = immediate_plan[7],
            .expected_instructions = &.{
                .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rdi } },
                .{ .mov_imm_eax = 17 },
                .{ .binary_arg_eax = .{ .op = .sub, .reg = .rcx } },
            },
        },
        .{
            .row = immediate_plan[8],
            .expected_instructions = &.{
                .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rdi } },
                .{ .mov_imm_eax = 3 },
                .shl_eax_cl,
                .{ .and_eax_imm32 = 0xffff },
            },
        },
        .{
            .row = immediate_plan[9],
            .expected_instructions = &.{
                .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rdi } },
                .{ .mov_imm_rax = 0x1000 },
                .shr_rax_cl,
            },
        },
    };
    for (cases) |case| {
        var machine = MachineFunction.init(case.row.id, .{ .int = case.row.bits });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        try addAtCurrent(&plan, "result");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(
            &selector,
            "source",
            if (case.row.bits <= 32) .{ .arg32 = .rdi } else .{ .arg64 = .rdi },
        );

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handle = try registerImmediate(&transaction, case.row);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(handle));
        try transaction.commit();
        try std.testing.expectEqualSlices(
            machine_module.Instruction,
            case.expected_instructions,
            machine.instructions.items,
        );
    }
}

test "value-use immediate scalar source-derived result branches retain accepted streams" {
    const cases = [_]struct {
        row: PlanRow,
        source_loc: ValueLoc,
        expected_result: ValueLoc,
        expected_instructions: []const machine_module.Instruction,
    }{
        .{
            .row = .{
                .id = "R01-i16-physical-shift-range",
                .direction = .rhs,
                .operation = .lshr,
                .bits = 16,
                .literal = 31,
                .accumulator = false,
                .scratch = true,
                .writes = 1,
            },
            .source_loc = .{ .arg32 = .rdi },
            .expected_result = .{ .scratch32 = .rcx },
            .expected_instructions = &.{
                .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rdi } },
                .{ .shr_arg_imm5 = .{ .reg = .rcx, .amount = 31 } },
            },
        },
        .{
            .row = .{
                .id = "R02-scratch-writeback",
                .direction = .rhs,
                .operation = .shl,
                .bits = 32,
                .literal = 3,
                .accumulator = false,
                .scratch = true,
                .writes = 1,
            },
            .source_loc = .{ .scratch32 = .rdi },
            .expected_result = .{ .scratch32 = .rdi },
            .expected_instructions = &.{
                .{ .mov_arg_eax = .rdi },
                .{ .shl_eax_imm5 = 3 },
                .{ .mov_eax_to_arg = .rdi },
            },
        },
        .{
            .row = .{
                .id = "R03-narrow-accumulator",
                .direction = .rhs,
                .operation = .ashr,
                .bits = 32,
                .literal = 5,
                .accumulator = true,
                .scratch = false,
                .writes = 1,
            },
            .source_loc = .{ .arg32 = .rdi },
            .expected_result = .eax,
            .expected_instructions = &.{
                .{ .mov_arg_eax = .rdi },
                .{ .sar_eax_imm5 = 5 },
            },
        },
    };
    for (cases) |case| {
        var machine = MachineFunction.init(case.row.id, .{ .int = case.row.bits });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        try addAtCurrent(&plan, "result");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "source", case.source_loc);

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handle = try registerImmediate(&transaction, case.row);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(handle));
        try transaction.commit();
        try std.testing.expectEqualSlices(
            machine_module.Instruction,
            case.expected_instructions,
            machine.instructions.items,
        );
        try std.testing.expectEqual(
            case.expected_result,
            selector_state.resolveValue(&selector, .{ .named = "result" }).?,
        );
    }
}

test "value-use immediate scalar R01 spill source falls back through RAX when scratch is unavailable" {
    const row = immediate_plan[1];
    var machine = MachineFunction.init("R01-spill-through-rax", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "source");
    try addAtCurrent(&plan, "result");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "source", .{ .spill64 = .slot0 });
    const blockers = [_][]const u8{
        "blocker-rdi",
        "blocker-rsi",
        "blocker-rdx",
        "blocker-rcx",
        "blocker-r8",
        "blocker-r9",
    };
    for (selector_types.selector_allocatable_regs, blockers) |reg, blocker| {
        try support.addLive(&plan, blocker);
        try selector_state.bindValueLoc(&selector, blocker, .{ .scratch64 = reg });
    }

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const handle = try registerImmediate(&transaction, row);
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(handle));
    try transaction.commit();
    try std.testing.expectEqualSlices(
        machine_module.Instruction,
        &.{
            .{ .reload_rsp_rax = .slot0 },
            .{ .shr_rax_imm6 = 7 },
        },
        machine.instructions.items,
    );
    try std.testing.expectEqual(
        ValueLoc.rax,
        selector_state.resolveValue(&selector, .{ .named = "result" }).?,
    );
}

test "value-use immediate scalar displacement distinguishes live-after from dies-at-current RAX" {
    const row = PlanRow{
        .id = "R02-i64",
        .direction = .rhs,
        .operation = .shl,
        .bits = 64,
        .literal = 32,
        .accumulator = true,
        .scratch = false,
        .writes = 1,
    };
    inline for (.{
        .{
            .id = "live-after",
            .live_after = true,
            .expected_source = ValueLoc{ .spill64 = .slot0 },
            .expected_instructions = &[_]machine_module.Instruction{
                .{ .spill_rax_rsp = .slot0 },
                .{ .reload_rsp_rax = .slot0 },
                .{ .shl_rax_imm6 = 32 },
            },
        },
        .{
            .id = "dies-at-current",
            .live_after = false,
            .expected_source = ValueLoc.rax,
            .expected_instructions = &[_]machine_module.Instruction{
                .{ .shl_rax_imm6 = 32 },
            },
        },
    }) |case| {
        var machine = MachineFunction.init(case.id, .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        if (case.live_after)
            try support.addLive(&plan, "source")
        else
            try addAtCurrent(&plan, "source");
        try addAtCurrent(&plan, "result");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 128;
        try selector_state.bindValueLoc(&selector, "source", .rax);

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handle = try registerImmediate(&transaction, row);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(handle));
        try transaction.commit();

        try std.testing.expectEqualSlices(
            machine_module.Instruction,
            case.expected_instructions,
            machine.instructions.items,
        );
        try std.testing.expectEqual(
            case.expected_source,
            selector_state.resolveValue(&selector, .{ .named = "source" }).?,
        );
        try std.testing.expectEqual(
            ValueLoc.rax,
            selector_state.resolveValue(&selector, .{ .named = "result" }).?,
        );
    }
}

test "value-use immediate scalar non-accumulator and literal controls remain exact" {
    const cases = [_]struct {
        row: PlanRow,
        source_loc: ValueLoc,
        expected_instructions: []const machine_module.Instruction,
    }{
        .{
            .row = .{
                .id = "R02-non-accumulator",
                .direction = .rhs,
                .operation = .shl,
                .bits = 64,
                .literal = 7,
                .accumulator = true,
                .scratch = false,
                .writes = 1,
            },
            .source_loc = .{ .arg64 = .rdi },
            .expected_instructions = &.{
                .{ .mov_arg_rax = .rdi },
                .{ .shl_rax_imm6 = 7 },
            },
        },
        .{
            .row = immediate_plan[9],
            .source_loc = .{ .arg64 = .rdi },
            .expected_instructions = &.{
                .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rdi } },
                .{ .mov_imm_rax = 0x1000 },
                .shr_rax_cl,
            },
        },
    };
    for (cases) |case| {
        var machine = MachineFunction.init(case.row.id, .{ .int = case.row.bits });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try support.addLive(&plan, "source");
        try addAtCurrent(&plan, "result");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 128;
        try selector_state.bindValueLoc(&selector, "source", case.source_loc);

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handle = try registerImmediate(&transaction, case.row);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(handle));
        try transaction.commit();

        try std.testing.expectEqualSlices(
            machine_module.Instruction,
            case.expected_instructions,
            machine.instructions.items,
        );
    }
}

test "value-use immediate scalar malformed dependency liveness fails closed and rolls back" {
    const row = PlanRow{
        .id = "R02-malformed-domain",
        .direction = .rhs,
        .operation = .shl,
        .bits = 64,
        .literal = 32,
        .accumulator = true,
        .scratch = false,
        .writes = 1,
    };
    var machine = MachineFunction.init(row.id, .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try support.addLive(&plan, "source");
    try addAtCurrent(&plan, "result");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "source", .rax);
    const saved_source = selector.values.get("source").?;
    const saved_next_vreg = selector.next_virtual_reg;
    const saved_next_spill = selector.next_spill_slot;
    const saved_accumulator = selector.accumulator_domain;
    const saved_dependencies = selector.address_dependencies;
    const saved_eflags = selector.eflags.snapshot();
    const saved_semantics = selector.eflags_semantics.items.len;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const handle = try registerImmediate(&transaction, row);
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    const lease = try transaction.preparedView(handle);

    try selector_state.bindValueLoc(&selector, "malformed-owner", .{ .stack_i32_ptr = .{
        .disp = 0,
        .index = .{ .reg = .rdi, .name = "source" },
    } });
    try selector.address_dependencies.replaceAddress("malformed-owner", &.{
        .{ .name = "source", .identity_type = .integer, .role = .index },
    });
    try std.testing.expectError(
        error.AddressDependencyMissingOwnerPlanEntry,
        transaction.executePreparedAction(lease),
    );

    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(saved_source, selector.values.get("source").?);
    try std.testing.expect(selector.values.get("malformed-owner") == null);
    try std.testing.expect(selector.values.get("result") == null);
    try std.testing.expectEqual(saved_next_vreg, selector.next_virtual_reg);
    try std.testing.expectEqual(saved_next_spill, selector.next_spill_slot);
    try std.testing.expectEqual(saved_accumulator, selector.accumulator_domain);
    try std.testing.expect(selector.address_dependencies.eql(&saved_dependencies));
    try selector.eflags.validateSnapshot(saved_eflags);
    try std.testing.expectEqual(saved_semantics, selector.eflags_semantics.items.len);
    try std.testing.expectError(error.ValueUseTransactionClosed, transaction.rollback());
}

test "value-use immediate scalar diagnostics preserve request provenance" {
    const cases = [_]struct {
        loc: ValueLoc,
        row: PlanRow,
        expected_error: anyerror,
    }{
        .{
            .loc = .{ .arg128 = .{ .lo = .rdi, .hi = .rsi } },
            .row = immediate_plan[5],
            .expected_error = error.ValueUseImmediateScalarWidthUnsupported,
        },
    };
    for (cases) |case| {
        var machine = MachineFunction.init("immediate-diagnostic", .{ .int = case.row.bits });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        try addAtCurrent(&plan, "result");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "source", case.loc);

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handle = try registerImmediate(&transaction, case.row);
        try std.testing.expectError(case.expected_error, transaction.seal());
        try std.testing.expect(transaction.failedRequestIs(handle));
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
}

test "value-use immediate scalar literal validation precedes request mutation" {
    const row: PlanRow = .{
        .id = "R06-sub-out-of-range",
        .direction = .rhs,
        .operation = .sub,
        .bits = 64,
        .literal = std.math.maxInt(i32) + 1,
        .accumulator = false,
        .scratch = true,
        .writes = 0,
    };
    var machine = MachineFunction.init(row.id, .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "source");
    try addAtCurrent(&plan, "result");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg64 = .rdi });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    try std.testing.expectError(
        error.ValueUseImmediateScalarLiteralOutOfRange,
        registerImmediate(&transaction, row),
    );
    try std.testing.expectEqual(@as(usize, 0), transaction.requestCount());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "value-use immediate scalar rollback restores every tested boundary" {
    const boundaries = [_]Transaction.ImmediateScalarTestFailure{
        .after_rcx_staging,
        .after_accumulator_preparation,
        .after_eax_staging,
        .after_first_instruction,
        .after_result_identity_ownership,
        .after_result_definition,
        .after_finalization,
    };
    for (boundaries) |boundary| {
        const row = immediate_plan[7];
        var machine = MachineFunction.init("immediate-rollback", .{ .int = 32 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        try addAtCurrent(&plan, "result");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "source", .{ .arg32 = .rdi });
        const saved_source = selector.values.get("source").?;
        const saved_spill = selector.next_spill_slot;
        const saved_accumulator = selector.accumulator_domain;
        const saved_eflags = selector.eflags.snapshot();

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handle = try registerImmediate(&transaction, row);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.setImmediateScalarTestFailure(boundary);
        try std.testing.expectError(
            error.ValueUseImmediateScalarTestFailure,
            transaction.executePreparedAction(try transaction.preparedView(handle)),
        );
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(saved_source, selector.values.get("source").?);
        try std.testing.expect(selector.values.get("result") == null);
        try std.testing.expectEqual(saved_spill, selector.next_spill_slot);
        try std.testing.expectEqual(saved_accumulator, selector.accumulator_domain);
        try std.testing.expectEqual(saved_eflags, selector.eflags.snapshot());
        try std.testing.expectEqual(@as(usize, 0), selector.eflags_semantics.items.len);
    }
}

test "value-use immediate scalar rollback spans preservation scratch and multi-instruction stages" {
    const cases = [_]struct {
        row_index: usize,
        source_loc: ValueLoc,
        boundary: Transaction.ImmediateScalarTestFailure,
    }{
        .{ .row_index = 2, .source_loc = .{ .scratch32 = .rdi }, .boundary = .after_preservation },
        .{ .row_index = 2, .source_loc = .{ .scratch32 = .rdi }, .boundary = .after_eax_staging },
        .{ .row_index = 1, .source_loc = .{ .arg64 = .rdi }, .boundary = .after_scratch_selection },
        .{ .row_index = 1, .source_loc = .{ .arg64 = .rdi }, .boundary = .after_first_instruction },
        .{ .row_index = 5, .source_loc = .{ .arg64 = .rdi }, .boundary = .after_rax_staging },
        .{ .row_index = 5, .source_loc = .{ .arg64 = .rdi }, .boundary = .after_second_instruction },
        .{ .row_index = 0, .source_loc = .{ .arg32 = .rdi }, .boundary = .after_second_instruction },
        .{ .row_index = 0, .source_loc = .{ .arg32 = .rdi }, .boundary = .after_third_instruction },
        .{ .row_index = 6, .source_loc = .{ .arg64 = .rdi }, .boundary = .after_rcx_staging },
        .{ .row_index = 6, .source_loc = .{ .arg64 = .rdi }, .boundary = .after_result_definition },
    };
    for (cases) |case| {
        const row = immediate_plan[case.row_index];
        var machine = MachineFunction.init("immediate-rollback-expanded", .{ .int = row.bits });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        try addAtCurrent(&plan, "result");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 128;
        try selector_state.bindValueLoc(&selector, "source", case.source_loc);
        const saved_source = selector.values.get("source").?;
        const saved_spill = selector.next_spill_slot;
        const saved_accumulator = selector.accumulator_domain;
        const saved_eflags = selector.eflags.snapshot();

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handle = try registerImmediate(&transaction, row);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.setImmediateScalarTestFailure(case.boundary);
        try std.testing.expectError(
            error.ValueUseImmediateScalarTestFailure,
            transaction.executePreparedAction(try transaction.preparedView(handle)),
        );
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(saved_source, selector.values.get("source").?);
        try std.testing.expect(selector.values.get("result") == null);
        try std.testing.expectEqual(saved_spill, selector.next_spill_slot);
        try std.testing.expectEqual(saved_accumulator, selector.accumulator_domain);
        try std.testing.expectEqual(saved_eflags, selector.eflags.snapshot());
        try std.testing.expectEqual(@as(usize, 0), selector.eflags_semantics.items.len);
    }
}
