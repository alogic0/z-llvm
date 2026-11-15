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
    first_accumulator_write: []const u8 = "test-specific closed plan",
    accumulator_preamble: []const u8 = "derived internally from the closed plan",
    displacement_authority: []const u8 = "closed-plan test-specific",
};

const immediate_plan = [_]PlanRow{
    .{ .id = "R00", .direction = .rhs, .operation = .sdiv, .bits = 32, .literal = 2, .accumulator = true, .scratch = false, .writes = 3, .first_accumulator_write = "session materializes source into EAX", .accumulator_preamble = "none; session owns liveness-aware displacement", .displacement_authority = "Q2 strict-after; scratch-preferred fallback" },
    .{ .id = "R01", .direction = .rhs, .operation = .lshr, .bits = 64, .literal = 7, .accumulator = false, .scratch = true, .writes = 1, .first_accumulator_write = "pressure fallback materializes RAX; scratch form has none", .accumulator_preamble = "none", .displacement_authority = "sessionless scratch; hard spill-live on accumulator fallback" },
    .{ .id = "R02", .direction = .rhs, .operation = .shl, .bits = 32, .literal = 3, .accumulator = true, .scratch = true, .writes = 1, .first_accumulator_write = "session materializes EAX/RAX; scratch32 form stages EAX", .accumulator_preamble = "scratch-preferred <=32; spill-source at 64", .displacement_authority = "<=32 Q2 strict-after; i64 inclusive preserve-current" },
    .{ .id = "R03", .direction = .rhs, .operation = .ashr, .bits = 64, .literal = 5, .accumulator = false, .scratch = true, .writes = 1, .first_accumulator_write = "accumulator form materializes EAX; scratch64 form has none", .accumulator_preamble = "scratch-preferred accumulator; none scratch64", .displacement_authority = "<=32 Q2 strict-after; i64 sessionless scratch" },
    .{ .id = "R04", .direction = .rhs, .operation = .add, .bits = 32, .literal = 9, .accumulator = true, .scratch = false, .writes = 1, .first_accumulator_write = "session materializes source into EAX", .accumulator_preamble = "scratch-preferred", .displacement_authority = "Q2 strict-after; scratch-preferred fallback" },
    .{ .id = "R05", .direction = .rhs, .operation = .@"and", .bits = 64, .literal = 0x123456789, .accumulator = true, .scratch = false, .writes = 1, .first_accumulator_write = "session materializes source into RAX", .accumulator_preamble = "spill-source", .displacement_authority = "inclusive preserve-current; spill-live fallback" },
    .{ .id = "R05-sub", .direction = .rhs, .operation = .sub, .bits = 64, .literal = 0x123456789, .accumulator = true, .scratch = false, .writes = 1, .first_accumulator_write = "session materializes source into RAX", .accumulator_preamble = "spill-source", .displacement_authority = "inclusive preserve-current; spill-live fallback" },
    .{ .id = "R05-sub-min-i32", .direction = .rhs, .operation = .sub, .bits = 64, .literal = std.math.minInt(i32), .accumulator = true, .scratch = false, .writes = 1, .first_accumulator_write = "session materializes source into RAX", .accumulator_preamble = "spill-source", .displacement_authority = "inclusive preserve-current; spill-live fallback" },
    .{ .id = "R06", .direction = .rhs, .operation = .sub, .bits = 64, .literal = 11, .accumulator = false, .scratch = true, .writes = 1, .first_accumulator_write = "none; result remains in RCX", .accumulator_preamble = "none", .displacement_authority = "sessionless scratch" },
    .{ .id = "L01", .direction = .lhs, .operation = .sub, .bits = 32, .literal = 17, .accumulator = true, .scratch = false, .writes = 1, .first_accumulator_write = "literal materialization into EAX/RAX", .accumulator_preamble = "none; session spill-live authority", .displacement_authority = "hard spill-live" },
    .{ .id = "L02", .direction = .lhs, .operation = .shl, .bits = 16, .literal = 3, .accumulator = true, .scratch = false, .writes = 2, .first_accumulator_write = "literal materialization into EAX", .accumulator_preamble = "none; session spill-live authority", .displacement_authority = "hard spill-live" },
    .{ .id = "L03", .direction = .lhs, .operation = .lshr, .bits = 64, .literal = 0x1000, .accumulator = true, .scratch = false, .writes = 1, .first_accumulator_write = "literal materialization into EAX/RAX", .accumulator_preamble = "none; session spill-live authority", .displacement_authority = "hard spill-live" },
};

const DeclaredType = enum { non_integer, i1, i16, i32, i64, i128 };
fn planRow(id: []const u8) PlanRow {
    for (immediate_plan) |row| if (std.mem.eql(u8, row.id, id)) return row;
    unreachable;
}
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

test "value-use immediate scalar plan representatives have unique identities and directions" {
    try std.testing.expectEqual(@as(usize, 12), immediate_plan.len);
    for (immediate_plan, 0..) |row, index| {
        for (immediate_plan[0..index]) |prior| try std.testing.expect(!std.mem.eql(u8, row.id, prior.id));
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
        try std.testing.expect(row.first_accumulator_write.len != 0);
        try std.testing.expect(row.accumulator_preamble.len != 0);
        try std.testing.expect(row.displacement_authority.len != 0);
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
            .row = planRow("R00"),
            .expected_instructions = &.{
                .{ .mov_arg_eax = .rdi },
                .{ .mov_eax_to_arg = .rcx },
                .{ .shr_eax_imm5 = 31 },
                .add_ecx_eax,
                .{ .sar_eax_imm5 = 1 },
            },
        },
        .{
            .row = planRow("L01"),
            .expected_instructions = &.{
                .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rdi } },
                .{ .mov_imm_eax = 17 },
                .{ .binary_arg_eax = .{ .op = .sub, .reg = .rcx } },
            },
        },
        .{
            .row = planRow("L02"),
            .expected_instructions = &.{
                .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rdi } },
                .{ .mov_imm_eax = 3 },
                .shl_eax_cl,
                .{ .and_eax_imm32 = 0xffff },
            },
        },
        .{
            .row = planRow("L03"),
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
    const row = planRow("R01");
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

test "value-use immediate scalar R01 register pressure preserves aliases and rolls back fallback" {
    const homes = [_]ValueLoc{ .{ .arg64 = .rdi }, .{ .scratch64 = .rdi }, .rax, .{ .spill64 = .slot0 } };
    const boundaries = [_]?Transaction.ImmediateScalarTestFailure{ null, .after_accumulator_preparation, .after_rax_staging, .after_result_definition };
    for (homes) |home| for (boundaries) |boundary| {
        var machine = MachineFunction.init("R01-register-pressure", .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        try addAtCurrent(&plan, "result");
        try support.addLive(&plan, "wide-accumulator");
        try support.addLive(&plan, "narrow-accumulator");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 512;
        selector.next_spill_slot = 1;
        try selector_state.bindValueLoc(&selector, "source", home);
        try selector_state.bindValueLoc(&selector, "wide-accumulator", .rax);
        try selector_state.bindValueLoc(&selector, "narrow-accumulator", .eax);
        const blockers = [_][]const u8{ "blocked-rdi", "blocked-rsi", "blocked-rdx", "blocked-rcx", "blocked-r8", "blocked-r9" };
        for (selector_types.selector_allocatable_regs, blockers) |reg, name| {
            try support.addLive(&plan, name);
            try selector_state.bindValueLoc(&selector, name, .{ .scratch64 = reg });
        }
        const saved_source = selector.values.get("source").?;
        const saved_wide = selector.values.get("wide-accumulator").?;
        const saved_narrow = selector.values.get("narrow-accumulator").?;
        const saved_flags = selector.eflags.snapshot();
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handle = try registerImmediate(&transaction, planRow("R01"));
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        if (boundary) |point| {
            try transaction.setImmediateScalarTestFailure(point);
            try std.testing.expectError(error.ValueUseImmediateScalarTestFailure, transaction.executePreparedAction(try transaction.preparedView(handle)));
            try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
            try std.testing.expectEqual(saved_source, selector.values.get("source").?);
            try std.testing.expectEqual(saved_wide, selector.values.get("wide-accumulator").?);
            try std.testing.expectEqual(saved_narrow, selector.values.get("narrow-accumulator").?);
            try std.testing.expectEqual(@as(usize, 1), selector.next_spill_slot);
            try std.testing.expectEqual(saved_flags, selector.eflags.snapshot());
            try std.testing.expect(selector.values.get("result") == null);
        } else {
            transaction.executePreparedAction(try transaction.preparedView(handle)) catch |err| {
                std.debug.print("R01 pressure home={any}\n", .{home});
                return err;
            };
            try transaction.commit();
            try std.testing.expect(selector.values.get("wide-accumulator").?.loc == .spill64);
            try std.testing.expect(selector.values.get("narrow-accumulator").?.loc == .spill64);
            try std.testing.expectEqual(@as(u16, 64), selector.values.get("wide-accumulator").?.vreg.bits);
            try std.testing.expectEqual(ValueLoc.rax, selector_state.resolveValue(&selector, .{ .named = "result" }).?);
            var shifts: usize = 0;
            for (machine.instructions.items) |instruction| if (instruction == .shr_rax_imm6) {
                try std.testing.expect(instruction.shr_rax_imm6 == 7);
                shifts += 1;
            };
            try std.testing.expectEqual(@as(usize, 1), shifts);
        }
        for (selector_types.selector_allocatable_regs, blockers) |reg, name|
            try std.testing.expectEqual(ValueLoc{ .scratch64 = reg }, selector.values.get(name).?.loc);
    };
}

test "value-use immediate scalar displacement distinguishes live-after from dies-at-current RAX" {
    const row = PlanRow{
        .id = "R04-i32",
        .direction = .rhs,
        .operation = .add,
        .bits = 32,
        .literal = 9,
        .accumulator = true,
        .scratch = false,
        .writes = 1,
    };
    inline for (.{
        .{
            .id = "live-after",
            .live_after = true,
            .expected_source = ValueLoc{ .scratch64 = .rdi },
            .expected_instructions = &[_]machine_module.Instruction{
                .{ .mov_rax_to_arg = .rdi },
                .{ .mov_arg_eax = .rdi },
                .{ .add_eax_imm32 = 9 },
            },
        },
        .{
            .id = "dies-at-current",
            .live_after = false,
            .expected_source = ValueLoc.rax,
            .expected_instructions = &[_]machine_module.Instruction{
                .{ .add_eax_imm32 = 9 },
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
            ValueLoc.eax,
            selector_state.resolveValue(&selector, .{ .named = "result" }).?,
        );
    }
}

test "value-use immediate scalar real __multi3 percent-11 uses inclusive policy without a Q3 alias" {
    const row = PlanRow{
        .id = "__multi3-%11",
        .direction = .rhs,
        .operation = .@"and",
        .bits = 64,
        .literal = std.math.maxInt(u32),
        .accumulator = true,
        .scratch = false,
        .writes = 1,
    };
    var machine = MachineFunction.init(row.id, .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("9", 16);
    try plan.interval_ends.put("10", 29);
    try plan.interval_ends.put("11", 19);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 16;
    selector.stack_frame_bytes = 256;
    var seed = try selector_state.AccumulatorDefinitionTransaction.begin(&selector);
    defer seed.deinit();
    _ = try seed.prepare(.preserve, .spill_live);
    try seed.define("9", .fullRax());
    try seed.commit();
    try selector_state.bindValueLoc(
        &selector,
        "10",
        .{ .spill64 = selector_state.spillFrameIndex(9) },
    );
    try selector.spill_slots.put("10", .{ .base = 9, .slots = 1 });
    selector.next_spill_slot = 10;
    try selector.eflags.apply(.definition);
    try selector.eflags.apply(.use);

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const handle = try transaction.register(.{
        .source = .{ .named = "9" },
        .expected = expected(.{ .int = 64 }, .gpr64),
        .form = .immediate_rhs_scalar_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .immediate_rhs_scalar = .{
            .result = try actionIdentity("11"),
            .operation = row.operation,
            .integer_ty = .{ .int = 64 },
            .literal = row.literal,
        } },
    });
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(handle));
    try transaction.commit();

    try std.testing.expectEqualSlices(
        machine_module.Instruction,
        &.{
            .{ .spill_rax_rsp = .{ .slot = 20 } },
            .{ .reload_rsp_rax = .{ .slot = 20 } },
            .{ .and_eax_imm32 = -1 },
        },
        machine.instructions.items,
    );
    try std.testing.expectEqual(
        ValueLoc{ .spill64 = .{ .slot = 20 } },
        selector_state.resolveValue(&selector, .{ .named = "9" }).?,
    );
    try std.testing.expectEqual(
        ValueLoc{ .spill64 = .{ .slot = 18 } },
        selector_state.resolveValue(&selector, .{ .named = "10" }).?,
    );
    try std.testing.expectEqual(ValueLoc.rax, selector_state.resolveValue(
        &selector,
        .{ .named = "11" },
    ).?);
    try std.testing.expectEqual(@as(usize, 2), selector.spill_slots.count());
    try std.testing.expect(selector.spill_slots.get("9") != null);
    try std.testing.expect(selector.spill_slots.get("10") != null);
    try std.testing.expectEqual(@as(usize, 11), selector.next_spill_slot);
    try std.testing.expectEqual(@as(usize, 1), selector.eflags_semantics.items.len);
    try std.testing.expectEqual(
        @as(usize, 2),
        selector.eflags_semantics.items[0].instruction_index,
    );
    try std.testing.expectEqual(
        selector_state.EflagsEffect.write,
        selector.eflags_semantics.items[0].effect,
    );
}

test "value-use subordinate spill key survives teardown churn rehash and later transaction" {
    const row = PlanRow{
        .id = "durable-subordinate-spill",
        .direction = .rhs,
        .operation = .@"and",
        .bits = 64,
        .literal = std.math.maxInt(u32),
        .accumulator = true,
        .scratch = false,
        .writes = 1,
    };
    var machine = MachineFunction.init(row.id, .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "source");
    try support.addLive(&plan, "result");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 1024;
    try selector_state.bindValueLoc(&selector, "source", .rax);

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

    try std.testing.expectEqual(@as(usize, 1), selector.owned_spill_slot_keys.count());
    const committed = selector.spill_slots.get("source").?;
    for (0..128) |index| {
        const churn = try std.testing.allocator.alloc(u8, 17 + index);
        @memset(churn, @intCast(index));
        std.testing.allocator.free(churn);
    }
    for (0..64) |index| {
        var name_storage: [32]u8 = undefined;
        const name = try std.fmt.bufPrint(&name_storage, "post-commit-{d}", .{index});
        try std.testing.expect(selector_state.allocateSpillSlot(&selector, name) != null);
    }
    try std.testing.expectEqual(committed, selector.spill_slots.get("source").?);

    var later = try Transaction.begin(&selector);
    try later.seal();
    try later.prepare();
    try later.materializeAll();
    try later.commit();
    later.deinit();
    try std.testing.expectEqual(committed, selector.spill_slots.get("source").?);
    try std.testing.expect(selector_state.allocateSpillSlot(&selector, "later") != null);
}

test "value-use outer rollback frees a subordinate speculative spill key exactly once" {
    const row = PlanRow{
        .id = "durable-subordinate-spill-rollback",
        .direction = .rhs,
        .operation = .@"and",
        .bits = 64,
        .literal = std.math.maxInt(u32),
        .accumulator = true,
        .scratch = false,
        .writes = 1,
    };
    var failing = std.testing.FailingAllocator.init(std.testing.allocator, .{});
    const allocator = failing.allocator();
    var machine = MachineFunction.init(row.id, .{ .int = 64 });
    defer machine.deinit(allocator);
    var plan = SelectorAllocationPlan.init(allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "source");
    try support.addLive(&plan, "result");
    var selector = ComposedBlockSelector.init(allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector.spill_slots.ensureUnusedCapacity(1);
    try selector.owned_spill_slot_keys.ensureUnusedCapacity(allocator, 1);
    try selector.values.ensureUnusedCapacity(2);
    try machine.instructions.ensureUnusedCapacity(allocator, 4);
    try selector_state.bindValueLoc(&selector, "source", .rax);
    const source_before = selector.values.get("source").?;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const handle = try registerImmediate(&transaction, row);
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.setImmediateScalarTestFailure(.after_accumulator_preparation);
    const allocations_before = failing.allocations;
    const deallocations_before = failing.deallocations;
    try std.testing.expectError(
        error.ValueUseImmediateScalarTestFailure,
        transaction.executePreparedAction(try transaction.preparedView(handle)),
    );
    try std.testing.expectEqual(allocations_before + 1, failing.allocations);
    try std.testing.expectEqual(deallocations_before + 1, failing.deallocations);
    try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
    try std.testing.expectEqual(@as(usize, 0), selector.owned_spill_slot_keys.count());
    try std.testing.expectEqual(source_before, selector.values.get("source").?);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "value-use immediate scalar R05 inclusive policy and genuine Q3 aliases are exact" {
    const row = PlanRow{
        .id = "R05-alias-controls",
        .direction = .rhs,
        .operation = .@"and",
        .bits = 64,
        .literal = std.math.maxInt(u32),
        .accumulator = true,
        .scratch = false,
        .writes = 1,
    };
    inline for (.{
        .{
            .id = "no-alias",
            .alias_count = @as(u8, 0),
            .expected_instructions = &[_]machine_module.Instruction{
                .{ .spill_rax_rsp = .slot0 },
                .{ .reload_rsp_rax = .slot0 },
                .{ .and_eax_imm32 = -1 },
            },
            .expected_source = ValueLoc{ .spill64 = .slot0 },
            .expected_spills = @as(usize, 1),
        },
        .{
            .id = "multiple-aliases",
            .alias_count = @as(u8, 2),
            .expected_instructions = &[_]machine_module.Instruction{
                .{ .spill_rax_rsp = .slot0 },
                .{ .reload_rsp_rax = .slot0 },
                .{ .and_eax_imm32 = -1 },
            },
            .expected_source = ValueLoc{ .spill64 = .slot0 },
            .expected_spills = @as(usize, 1),
        },
    }) |case| {
        var machine = MachineFunction.init(case.id, .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        if (case.alias_count != 0) {
            try support.addLive(&plan, "alias-a");
            try support.addLive(&plan, "alias-b");
        }
        try addAtCurrent(&plan, "result");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 128;
        try selector_state.bindValueLoc(&selector, "source", .rax);
        if (case.alias_count != 0) {
            try selector_state.bindValueLoc(&selector, "alias-a", .rax);
            try selector_state.bindValueLoc(&selector, "alias-b", .rax);
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
            case.expected_instructions,
            machine.instructions.items,
        );
        try std.testing.expectEqual(
            case.expected_source,
            selector_state.resolveValue(&selector, .{ .named = "source" }).?,
        );
        try std.testing.expectEqual(case.expected_spills, selector.spill_slots.count());
        if (case.alias_count != 0) {
            try std.testing.expectEqual(
                ValueLoc{ .spill64 = .slot0 },
                selector_state.resolveValue(&selector, .{ .named = "alias-a" }).?,
            );
            try std.testing.expectEqual(
                ValueLoc{ .spill64 = .slot0 },
                selector_state.resolveValue(&selector, .{ .named = "alias-b" }).?,
            );
        }
    }
}

test "value-use immediate scalar unrelated-alias preamble rollback preserves flags and state" {
    const row = PlanRow{
        .id = "R05-preamble-rollback",
        .direction = .rhs,
        .operation = .@"and",
        .bits = 64,
        .literal = std.math.maxInt(u32),
        .accumulator = true,
        .scratch = false,
        .writes = 1,
    };
    inline for ([_]Transaction.ImmediateScalarTestFailure{
        .after_preservation,
        .after_canonical_refresh,
    }) |boundary| {
        var machine = MachineFunction.init(@tagName(boundary), .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        try support.addLive(&plan, "prior-result");
        try addAtCurrent(&plan, "result");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 128;
        try selector_state.bindValueLoc(&selector, "source", .rax);
        try selector_state.bindValueLoc(&selector, "prior-result", .rax);
        try selector.eflags.apply(.definition);
        const saved_source = selector.values.get("source").?;
        const saved_alias = selector.values.get("prior-result").?;
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
        try transaction.setImmediateScalarTestFailure(boundary);
        try std.testing.expectError(
            error.ValueUseImmediateScalarTestFailure,
            transaction.executePreparedAction(try transaction.preparedView(handle)),
        );

        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(saved_source, selector.values.get("source").?);
        try std.testing.expectEqual(saved_alias, selector.values.get("prior-result").?);
        try std.testing.expect(selector.values.get("result") == null);
        try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
        try std.testing.expectEqual(saved_next_vreg, selector.next_virtual_reg);
        try std.testing.expectEqual(saved_next_spill, selector.next_spill_slot);
        try std.testing.expectEqual(saved_accumulator, selector.accumulator_domain);
        try std.testing.expect(selector.address_dependencies.eql(&saved_dependencies));
        try selector.eflags.validateSnapshot(saved_eflags);
        try std.testing.expectEqual(saved_semantics, selector.eflags_semantics.items.len);
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
            .row = planRow("L03"),
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

test "value-use immediate scalar unrelated-alias malformed liveness fails closed before preservation" {
    const row = PlanRow{
        .id = "R05-malformed-alias-domain",
        .direction = .rhs,
        .operation = .@"and",
        .bits = 64,
        .literal = std.math.maxInt(u32),
        .accumulator = true,
        .scratch = false,
        .writes = 1,
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
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "source", .rax);
    const saved_source = selector.values.get("source").?;
    const saved_next_vreg = selector.next_virtual_reg;
    const saved_next_spill = selector.next_spill_slot;
    const saved_accumulator = selector.accumulator_domain;
    const saved_dependencies = selector.address_dependencies;
    const saved_eflags = selector.eflags.snapshot();

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const handle = try registerImmediate(&transaction, row);
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    const lease = try transaction.preparedView(handle);
    try selector_state.bindValueLoc(&selector, "malformed-alias", .rax);
    try selector.address_dependencies.replaceAddress("malformed-alias", &.{
        .{ .name = "source", .identity_type = .integer, .role = .index },
    });
    try std.testing.expectError(
        error.AddressDependencyMissingOwnerPlanEntry,
        transaction.executePreparedAction(lease),
    );

    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(saved_source, selector.values.get("source").?);
    try std.testing.expect(selector.values.get("malformed-alias") == null);
    try std.testing.expect(selector.values.get("result") == null);
    try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
    try std.testing.expectEqual(saved_next_vreg, selector.next_virtual_reg);
    try std.testing.expectEqual(saved_next_spill, selector.next_spill_slot);
    try std.testing.expectEqual(saved_accumulator, selector.accumulator_domain);
    try std.testing.expect(selector.address_dependencies.eql(&saved_dependencies));
    try selector.eflags.validateSnapshot(saved_eflags);
}

test "value-use immediate scalar diagnostics preserve request provenance" {
    const cases = [_]struct {
        loc: ValueLoc,
        row: PlanRow,
        expected_error: anyerror,
    }{
        .{
            .loc = .{ .arg128 = .{ .lo = .rdi, .hi = .rsi } },
            .row = planRow("R05"),
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
        .id = "R05-sub-out-of-range",
        .direction = .rhs,
        .operation = .sub,
        .bits = 64,
        .literal = @as(i128, 1) << 64,
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
        const row = planRow("L01");
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
        row_id: []const u8,
        source_loc: ValueLoc,
        boundary: Transaction.ImmediateScalarTestFailure,
    }{
        .{ .row_id = "R02", .source_loc = .{ .scratch32 = .rdi }, .boundary = .after_preservation },
        .{ .row_id = "R02", .source_loc = .{ .scratch32 = .rdi }, .boundary = .after_eax_staging },
        .{ .row_id = "R01", .source_loc = .{ .arg64 = .rdi }, .boundary = .after_scratch_selection },
        .{ .row_id = "R01", .source_loc = .{ .arg64 = .rdi }, .boundary = .after_first_instruction },
        .{ .row_id = "R05", .source_loc = .{ .arg64 = .rdi }, .boundary = .after_rax_staging },
        .{ .row_id = "R05", .source_loc = .{ .arg64 = .rdi }, .boundary = .after_second_instruction },
        .{ .row_id = "R00", .source_loc = .{ .arg32 = .rdi }, .boundary = .after_second_instruction },
        .{ .row_id = "R00", .source_loc = .{ .arg32 = .rdi }, .boundary = .after_third_instruction },
        .{ .row_id = "R06", .source_loc = .{ .arg64 = .rdi }, .boundary = .after_rcx_staging },
        .{ .row_id = "R06", .source_loc = .{ .arg64 = .rdi }, .boundary = .after_result_definition },
    };
    for (cases) |case| {
        const row = planRow(case.row_id);
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

test "value-use immediate mixed-width accumulator aliases retain full bits through poisoned spills" {
    const encoding = @import("../../../../../mc/encoding.zig");
    const verify = @import("../../../verify.zig");
    const row = PlanRow{ .id = "mixed-width-spill", .direction = .rhs, .operation = .add, .bits = 32, .literal = 9, .accumulator = true, .scratch = false, .writes = 1 };
    for ([_][]const u8{ "wide", "9", "alias-a", "prior-result" }) |wide_name| {
        var machine = MachineFunction.init(row.id, .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try support.addLive(&plan, wide_name);
        try support.addLive(&plan, "narrow");
        try addAtCurrent(&plan, "source");
        try addAtCurrent(&plan, "result");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 136;
        try selector_state.bindValueLoc(&selector, wide_name, .rax);
        try selector_state.bindValueLoc(&selector, "narrow", .eax);
        try selector_state.bindValueLoc(&selector, "source", .{ .arg32 = .rsi });
        try machine.instructions.appendSlice(std.testing.allocator, &.{ .{ .sub_rsp_imm32 = 136 }, .{ .mov_imm_rax = -1 } });
        for (0..16) |slot| try machine.instructions.append(std.testing.allocator, .{ .spill_rax_rsp = selector_state.spillFrameIndex(slot) });
        try machine.instructions.append(std.testing.allocator, .{ .mov_arg_rax = .rdi });
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
        try std.testing.expect((try selector_state.spillValue(&selector, wide_name)) == null);
        try selector_state.emitValueIntoRax(&selector, .{ .named = wide_name });
        try machine.instructions.appendSlice(std.testing.allocator, &.{ .{ .add_rsp_imm32 = 136 }, .ret });
        try verify.verifyFunction(machine);
        const code = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(code);
        const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..code.len], code);
        const run: *const fn (u64, u32) callconv(.c) u64 = @ptrCast(memory.ptr);
        for ([_]u64{ 0, 1, 65535, 0xffffffff, 0x123456789abcdef0, std.math.maxInt(u64) }) |input| {
            try std.testing.expectEqual(input, run(input, 17));
        }
    }
}

test "value-use immediate mixed-width preservation rolls back every alias" {
    const row = PlanRow{ .id = "mixed-width-rollback", .direction = .rhs, .operation = .add, .bits = 32, .literal = 9, .accumulator = true, .scratch = false, .writes = 1 };
    for ([_]Transaction.ImmediateScalarTestFailure{ .after_preservation, .after_canonical_refresh }) |boundary| {
        var machine = MachineFunction.init(row.id, .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try support.addLive(&plan, "wide");
        try support.addLive(&plan, "narrow");
        try addAtCurrent(&plan, "source");
        try addAtCurrent(&plan, "result");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 136;
        try selector_state.bindValueLoc(&selector, "wide", .rax);
        try selector_state.bindValueLoc(&selector, "narrow", .eax);
        try selector_state.bindValueLoc(&selector, "source", .{ .arg32 = .rsi });
        const before_wide = selector.values.get("wide").?;
        const before_narrow = selector.values.get("narrow").?;
        const before_source = selector.values.get("source").?;
        const before_next = selector.next_virtual_reg;
        const before_dependencies = selector.address_dependencies;
        const before_flags = selector.eflags.snapshot();
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handle = try registerImmediate(&transaction, row);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.setImmediateScalarTestFailure(boundary);
        try std.testing.expectError(error.ValueUseImmediateScalarTestFailure, transaction.executePreparedAction(try transaction.preparedView(handle)));
        try std.testing.expectEqual(before_wide, selector.values.get("wide").?);
        try std.testing.expectEqual(before_narrow, selector.values.get("narrow").?);
        try std.testing.expectEqual(before_source, selector.values.get("source").?);
        try std.testing.expectEqual(before_next, selector.next_virtual_reg);
        try std.testing.expect(std.meta.eql(before_dependencies, selector.address_dependencies));
        try selector.eflags.validateSnapshot(before_flags);
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
        try std.testing.expect(selector.values.get("result") == null);
    }
}

test "value-use immediate RCX writes preserve live sources and aliases" {
    const encoding = @import("../../../../../mc/encoding.zig");
    const verify = @import("../../../verify.zig");
    for ([_]ir.BinaryOp{ .ashr, .add, .sub }) |operation| for ([_]bool{ false, true }) |typed| for ([_]bool{ false, true }) |alias| {
        const row = PlanRow{ .id = "rcx-live-write", .direction = .rhs, .operation = operation, .bits = 64, .literal = if (operation == .ashr) 63 else 7, .accumulator = false, .scratch = true, .writes = 1 };
        var machine = MachineFunction.init(row.id, .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        if (alias) {
            try support.addLive(&plan, "wide-alias");
            try addAtCurrent(&plan, "source");
        } else try support.addLive(&plan, "source");
        try addAtCurrent(&plan, "result");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 136;
        try selector_state.bindValueLoc(&selector, "source", .{ .scratch64 = .rcx });
        if (alias) try selector_state.bindValueLoc(&selector, "wide-alias", .{ .scratch64 = .rcx });
        try machine.instructions.appendSlice(std.testing.allocator, &.{ .{ .sub_rsp_imm32 = 136 }, .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rdi } } });
        if (typed) {
            var transaction = try Transaction.begin(&selector);
            defer transaction.deinit();
            const handle = try registerImmediate(&transaction, row);
            try transaction.seal();
            try transaction.prepare();
            try transaction.materializeAll();
            try transaction.executePreparedAction(try transaction.preparedView(handle));
            try transaction.commit();
        } else {
            try std.testing.expect((try support.selector_scalar.lowerBinary(&selector, "result", binary(row))) == null);
        }
        try selector_state.emitValueIntoRax(&selector, .{ .named = if (alias) "wide-alias" else "source" });
        try machine.instructions.appendSlice(std.testing.allocator, &.{ .{ .add_rsp_imm32 = 136 }, .ret });
        try verify.verifyFunction(machine);
        const code = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(code);
        const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..code.len], code);
        const run: *const fn (u64) callconv(.c) u64 = @ptrCast(memory.ptr);
        for ([_]u64{ 0, 1, 2, 0x7fffffffffffffff, 0x8000000000000000, 0x8000000000000001, 0xdeadbeef12345678, std.math.maxInt(u64) }) |input| {
            try std.testing.expectEqual(input, run(input));
        }
    };
}

test "value-use immediate RCX writes restore aliases on rollback" {
    for ([_]ir.BinaryOp{ .ashr, .add, .sub }) |operation| for ([_]Transaction.ImmediateScalarTestFailure{ .after_first_instruction, .after_result_definition }) |boundary| {
        const row = PlanRow{ .id = "rcx-write-rollback", .direction = .rhs, .operation = operation, .bits = 64, .literal = if (operation == .ashr) 63 else 7, .accumulator = false, .scratch = true, .writes = 1 };
        var machine = MachineFunction.init(row.id, .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try support.addLive(&plan, "source");
        try support.addLive(&plan, "alias");
        try addAtCurrent(&plan, "result");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 136;
        try selector_state.bindValueLoc(&selector, "source", .{ .scratch64 = .rcx });
        try selector_state.bindValueLoc(&selector, "alias", .{ .scratch64 = .rcx });
        const before_source = selector.values.get("source").?;
        const before_alias = selector.values.get("alias").?;
        const before_flags = selector.eflags.snapshot();
        const before_virtual = selector.next_virtual_reg;
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handle = try registerImmediate(&transaction, row);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.setImmediateScalarTestFailure(boundary);
        try std.testing.expectError(error.ValueUseImmediateScalarTestFailure, transaction.executePreparedAction(try transaction.preparedView(handle)));
        try std.testing.expectEqual(before_source, selector.values.get("source").?);
        try std.testing.expectEqual(before_alias, selector.values.get("alias").?);
        try std.testing.expectEqual(before_virtual, selector.next_virtual_reg);
        try selector.eflags.validateSnapshot(before_flags);
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
        try std.testing.expect(selector.values.get("result") == null);
    };
}

test "value-use immediate shift writeback preserves narrow sources and wide register aliases" {
    const encoding = @import("../../../../../mc/encoding.zig");
    for (std.meta.tags(@import("../../../types.zig").ArgReg)) |reg| for ([_]bool{ false, true }) |wide_alias| {
        const row = PlanRow{ .id = "shift-writeback", .direction = .rhs, .operation = .shl, .bits = 32, .literal = 7, .accumulator = true, .scratch = true, .writes = 1 };
        var machine = MachineFunction.init(row.id, .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        if (wide_alias) {
            try addAtCurrent(&plan, "source");
            try support.addLive(&plan, "wide-alias");
        } else try support.addLive(&plan, "source");
        try addAtCurrent(&plan, "result");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 136;
        try selector_state.bindValueLoc(&selector, "source", .{ .scratch32 = reg });
        if (wide_alias) try selector_state.bindValueLoc(&selector, "wide-alias", .{ .scratch64 = reg });
        try machine.instructions.appendSlice(std.testing.allocator, &.{
            .{ .sub_rsp_imm32 = 136 },
            .{ .mov_arg64_arg = .{ .dst = reg, .src = .rdi } },
        });
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
        try selector_state.emitValueIntoEax(&selector, .{ .named = "result" });
        try selector_state.emitBinaryLocIntoAccumulator(&selector, .xor, selector_state.valueLoc(&selector, if (wide_alias) "wide-alias" else "source").?, if (wide_alias) 64 else 32);
        try machine.instructions.appendSlice(std.testing.allocator, &.{ .{ .add_rsp_imm32 = 136 }, .ret });
        const code = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(code);
        const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..code.len], code);
        const run: *const fn (u64) callconv(.c) u64 = @ptrCast(memory.ptr);
        for ([_]u64{ 0, 1, 2, 0x7ff00000, 0x80000000, 0xffffffff, 0xdeadbeef12345678, std.math.maxInt(u64) }) |input| {
            const low: u32 = @truncate(input);
            const retained: u64 = if (wide_alias) input else low;
            try std.testing.expectEqual(@as(u64, low << 7) ^ retained, run(input));
        }
    };
}
