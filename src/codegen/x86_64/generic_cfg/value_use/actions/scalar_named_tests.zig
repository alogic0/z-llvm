const support = @import("../test_support.zig");
const scalar_named = @import("scalar_named.zig");

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

const Family = enum { b01, b03, b04, b05, b06, b07, i52b0 };
const Fixture = struct {
    family: Family,
    operation: ir.BinaryOp,
    bits: u16,
    exact_ei: bool = false,
    lhs_loc: ValueLoc,
    rhs_loc: ValueLoc,
    expected_first: machine_module.Instruction,
};

const fixtures = [_]Fixture{
    .{ .family = .b01, .operation = .@"and", .bits = 1, .lhs_loc = .eax, .rhs_loc = .{ .arg32 = .rdi }, .expected_first = .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rdi } } },
    .{ .family = .b03, .operation = .mul, .bits = 32, .lhs_loc = .{ .arg32 = .rdi }, .rhs_loc = .{ .arg32 = .rsi }, .expected_first = .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rsi } } },
    .{ .family = .b04, .operation = .shl, .bits = 16, .lhs_loc = .{ .arg32 = .rdi }, .rhs_loc = .{ .arg32 = .rsi }, .expected_first = .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rsi } } },
    .{ .family = .b05, .operation = .lshr, .bits = 64, .lhs_loc = .{ .arg64 = .rdi }, .rhs_loc = .{ .arg64 = .rsi }, .expected_first = .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rsi } } },
    .{ .family = .b06, .operation = .@"or", .bits = 56, .exact_ei = true, .lhs_loc = .{ .arg64 = .rdi }, .rhs_loc = .{ .arg64 = .rsi }, .expected_first = .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rsi } } },
    .{ .family = .b07, .operation = .add, .bits = 32, .lhs_loc = .{ .arg32 = .rdi }, .rhs_loc = .{ .arg32 = .rsi }, .expected_first = .{ .mov_arg_eax = .rdi } },
    .{ .family = .i52b0, .operation = .shl, .bits = 52, .lhs_loc = .{ .arg64 = .rdi }, .rhs_loc = .{ .arg64 = .rsi }, .expected_first = .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rsi } } },
};

fn registerFixture(
    transaction: *Transaction,
    fixture: Fixture,
) !Transaction.RequestHandle {
    const ty: ir.Type = .{ .int = fixture.bits };
    const class: support.selector_types.VirtualRegClass =
        if (fixture.bits <= 32) .gpr32 else .gpr64;
    const lhs = try transaction.register(.{
        .source = .{ .named = "lhs" },
        .expected = expected(ty, class),
        .form = .named_scalar_operand,
        .destination = .prepared_view,
    });
    const rhs = try transaction.register(.{
        .source = .{ .named = "rhs" },
        .expected = expected(ty, class),
        .form = .named_scalar_operand,
        .destination = .prepared_source,
    });
    if (fixture.family == .i52b0) {
        try transaction.attachExactI52BinaryAction(lhs, .{
            .result = try actionIdentity("result"),
            .rhs = rhs,
        });
    } else {
        try transaction.attachNamedScalarBinaryAction(lhs, .{
            .result = try actionIdentity("result"),
            .operation = fixture.operation,
            .integer_ty = ty,
            .exact_ei = fixture.exact_ei,
            .rhs = rhs,
        });
    }
    return lhs;
}

fn registerNamedAction(
    transaction: *Transaction,
    lhs_name: []const u8,
    rhs_name: []const u8,
    operation: ir.BinaryOp,
    bits: u16,
) !Transaction.RequestHandle {
    const ty: ir.Type = .{ .int = bits };
    const class: support.selector_types.VirtualRegClass = if (bits <= 32) .gpr32 else .gpr64;
    const lhs = try transaction.register(.{
        .source = .{ .named = lhs_name },
        .expected = expected(ty, class),
        .form = .named_scalar_operand,
        .destination = .prepared_view,
    });
    const rhs = try transaction.register(.{
        .source = .{ .named = rhs_name },
        .expected = expected(ty, class),
        .form = .named_scalar_operand,
        .destination = .prepared_source,
    });
    try transaction.attachNamedScalarBinaryAction(lhs, .{
        .result = try actionIdentity("result"),
        .operation = operation,
        .integer_ty = ty,
        .exact_ei = false,
        .rhs = rhs,
    });
    return lhs;
}

fn binaryNamed(function: ir.Function, result_name: []const u8) ir.BinaryInst {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.result) |result| {
                if (!std.mem.eql(u8, result, result_name)) continue;
                return instruction.kind.binary;
            }
        }
    }
    unreachable;
}

fn runFixture(fixture: Fixture) !struct {
    instruction_count: usize,
    eflags_count: usize,
    result: ValueLoc,
} {
    var machine = MachineFunction.init(@tagName(fixture.family), .{ .int = fixture.bits });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("lhs", 1);
    try plan.interval_ends.put("rhs", 1);
    try plan.interval_ends.put("result", 2);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "lhs", fixture.lhs_loc);
    try selector_state.bindValueLoc(&selector, "rhs", fixture.rhs_loc);

    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const lhs = try registerFixture(&transaction, fixture);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try std.testing.expectEqual(fixture.lhs_loc, selector_state.valueLoc(&selector, "lhs").?);
        try std.testing.expectEqual(fixture.rhs_loc, selector_state.valueLoc(&selector, "rhs").?);
        try std.testing.expectEqual(fixture.lhs_loc, transaction.prepared_views[lhs.index].canonical_source_loc);
        const action = transaction.requests[lhs.index].prepared_action.?;
        const rhs = switch (action) {
            .named_scalar_binary => |named| named.rhs,
            .exact_i52_binary => |named| named.rhs,
            else => unreachable,
        };
        try std.testing.expectEqual(@as(u8, 1), rhs.index);
        try std.testing.expectEqual(fixture.rhs_loc, transaction.prepared_views[rhs.index].canonical_source_loc);
        try transaction.executePreparedAction(try transaction.preparedView(lhs));
        try transaction.commit();
    }
    try std.testing.expect(machine.instructions.items.len != 0);
    try std.testing.expectEqual(fixture.expected_first, machine.instructions.items[0]);
    switch (fixture.family) {
        .b01 => try std.testing.expectEqualSlices(machine_module.Instruction, &.{
            .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rdi } },
            .{ .binary_arg_eax = .{ .op = .@"and", .reg = .rcx } },
        }, machine.instructions.items),
        .b03 => try std.testing.expectEqualSlices(machine_module.Instruction, &.{
            .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rsi } },
            .{ .mov_arg_eax = .rdi },
            .{ .imul_eax_arg32 = .rcx },
        }, machine.instructions.items),
        .b04 => try std.testing.expectEqualSlices(machine_module.Instruction, &.{
            .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rsi } },
            .{ .mov_arg_eax = .rdi },
            .shl_eax_cl,
        }, machine.instructions.items),
        .b05 => try std.testing.expectEqualSlices(machine_module.Instruction, &.{
            .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rsi } },
            .{ .mov_arg_rax = .rdi },
            .shr_rax_cl,
        }, machine.instructions.items),
        .b06 => try std.testing.expectEqualSlices(machine_module.Instruction, &.{
            .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rsi } },
            .{ .mov_arg_rax = .rdi },
            .{ .binary_arg_rax = .{ .op = .@"or", .reg = .rcx } },
        }, machine.instructions.items),
        .b07 => try std.testing.expectEqualSlices(machine_module.Instruction, &.{
            .{ .mov_arg_eax = .rdi },
            .{ .binary_arg_eax = .{ .op = .add, .reg = .rsi } },
        }, machine.instructions.items),
        .i52b0 => try std.testing.expectEqualSlices(machine_module.Instruction, &.{
            .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rsi } },
            .{ .mov_arg_rax = .rdi },
            .shl_rax_cl,
            .{ .mov_imm_rcx = (1 << 52) - 1 },
            .{ .binary_arg_rax = .{ .op = .@"and", .reg = .rcx } },
        }, machine.instructions.items),
    }
    const expected_writes: usize = if (fixture.family == .i52b0) 2 else 1;
    try std.testing.expectEqual(expected_writes, selector.eflags_semantics.items.len);
    for (selector.eflags_semantics.items) |record|
        try std.testing.expectEqual(selector_state.EflagsEffect.write, record.effect);
    try std.testing.expectEqual(@as(usize, 0), selector.address_dependencies.count());
    return .{
        .instruction_count = machine.instructions.items.len,
        .eflags_count = selector.eflags_semantics.items.len,
        .result = selector_state.resolveValue(&selector, .{ .named = "result" }).?,
    };
}

test "value-use named scalar closed family table preserves distinct plans" {
    try std.testing.expectEqual(@as(usize, 7), fixtures.len);
    for (fixtures) |fixture| {
        const binary = ir.BinaryInst{
            .op = fixture.operation,
            .ty = .{ .int = fixture.bits },
            .lhs = .{ .named = "lhs" },
            .rhs = .{ .named = "rhs" },
        };
        if (fixture.family == .i52b0) {
            try std.testing.expect(!scalar_named.isExactI52Binary(null, binary));
        } else {
            try std.testing.expect(scalar_named.isNamedScalarBinary(binary, fixture.exact_ei));
        }
        const result = try runFixture(fixture);
        try std.testing.expect(result.instruction_count >= 2);
        try std.testing.expect(result.eflags_count >= 1);
        try std.testing.expect(switch (result.result) {
            .eax => fixture.bits <= 32,
            .rax => fixture.bits > 32,
            else => false,
        });
    }
    const excluded_i64_multiply = ir.BinaryInst{
        .op = .mul,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    };
    try std.testing.expect(!scalar_named.isNamedScalarBinary(excluded_i64_multiply, false));
}

test "value-use exact i52 classifier admits only the structural ctlz envelope" {
    const input =
        \\declare i52 @llvm.ctlz.i52(i52, i1 immarg)
        \\define i52 @arbitrary_name(i52 %lhs) {
        \\entry:
        \\  %count = tail call range(i52 0, 53) i52 @llvm.ctlz.i52(i52 %lhs, i1 true)
        \\  %count6 = trunc nuw i52 %count to i6
        \\  %shift6 = add nuw i6 %count6, 1
        \\  %shift52 = zext i6 %shift6 to i52
        \\  %result = shl i52 %lhs, %shift52
        \\  ret i52 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    const function = &module.functions.items[0];
    const binary = binaryNamed(function.*, "result");
    try std.testing.expect(scalar_named.isExactI52Binary(function, binary));
    var wrong_operation = binary;
    wrong_operation.op = .lshr;
    try std.testing.expect(!scalar_named.isExactI52Binary(function, wrong_operation));
    var wrong_rhs = binary;
    wrong_rhs.rhs = .{ .named = "count" };
    try std.testing.expect(!scalar_named.isExactI52Binary(function, wrong_rhs));
}

test "value-use named scalar durable result survives transaction teardown and is usable" {
    const fixture = fixtures[5];
    var machine = MachineFunction.init("durable", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("lhs", 1);
    try plan.interval_ends.put("rhs", 1);
    try plan.interval_ends.put("result", 3);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    try selector_state.bindValueLoc(&selector, "lhs", fixture.lhs_loc);
    try selector_state.bindValueLoc(&selector, "rhs", fixture.rhs_loc);
    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const lhs = try registerFixture(&transaction, fixture);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(lhs));
        try transaction.commit();
    }
    try selector_state.emitValueIntoScratch(&selector, .{ .named = "result" }, .rcx, 32);
    try std.testing.expectEqual(
        std.meta.Tag(ValueLoc).eax,
        std.meta.activeTag(selector_state.resolveValue(&selector, .{ .named = "result" }).?),
    );
}

test "value-use named scalar B03 prepares before rhs staging" {
    var machine = MachineFunction.init("b03-prepare-before-rhs", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try support.addLive(&plan, "live");
    try support.addAtCurrent(&plan, "lhs");
    try support.addAtCurrent(&plan, "rhs");
    try plan.interval_ends.put("result", 2);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "live", .eax);
    try selector_state.bindValueLoc(&selector, "lhs", .{ .spill64 = .slot2 });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .spill64 = .slot3 });
    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const lhs = try registerNamedAction(&transaction, "lhs", "rhs", .mul, 32);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(lhs));
        try transaction.commit();
    }
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_eax_to_arg = .rdi },
        .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = .slot3 } },
        .{ .reload_rsp_eax = .slot2 },
        .{ .imul_eax_arg32 = .rcx },
    }, machine.instructions.items);
}

test "value-use named scalar B07 preserves accepted accumulator topology branches" {
    inline for (.{
        .{
            .name = "both-accumulator-distinct",
            .operation = ir.BinaryOp.add,
            .lhs_loc = ValueLoc.eax,
            .rhs_loc = ValueLoc.eax,
            .expected = &[_]machine_module.Instruction{
                .{ .mov_eax_to_arg = .rcx },
                .{ .binary_arg_eax = .{ .op = .add, .reg = .rcx } },
            },
        },
        .{
            .name = "rhs-accumulator-commutative",
            .operation = ir.BinaryOp.xor,
            .lhs_loc = ValueLoc{ .arg32 = .rdi },
            .rhs_loc = ValueLoc.eax,
            .expected = &[_]machine_module.Instruction{
                .{ .binary_arg_eax = .{ .op = .xor, .reg = .rdi } },
            },
        },
        .{
            .name = "rhs-accumulator-ordered",
            .operation = ir.BinaryOp.sub,
            .lhs_loc = ValueLoc{ .arg32 = .rcx },
            .rhs_loc = ValueLoc.eax,
            .expected = &[_]machine_module.Instruction{
                .{ .mov_eax_to_arg = .rdx },
                .{ .mov_arg_eax = .rcx },
                .{ .binary_arg_eax = .{ .op = .sub, .reg = .rdx } },
            },
        },
    }) |case| {
        var machine = MachineFunction.init(case.name, .{ .int = 32 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try support.addAtCurrent(&plan, "lhs");
        try support.addAtCurrent(&plan, "rhs");
        try plan.interval_ends.put("result", 2);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 1;
        selector.stack_frame_bytes = 128;
        try selector_state.bindValueLoc(&selector, "lhs", case.lhs_loc);
        try selector_state.bindValueLoc(&selector, "rhs", case.rhs_loc);
        {
            var transaction = try Transaction.begin(&selector);
            defer transaction.deinit();
            const lhs = try registerNamedAction(&transaction, "lhs", "rhs", case.operation, 32);
            try transaction.seal();
            try transaction.prepare();
            try transaction.materializeAll();
            try transaction.executePreparedAction(try transaction.preparedView(lhs));
            try transaction.commit();
        }
        try std.testing.expectEqualSlices(
            machine_module.Instruction,
            case.expected,
            machine.instructions.items,
        );
    }
}

test "value-use named scalar rollback is exact at every declared boundary" {
    const boundaries = std.meta.tags(Transaction.NamedScalarTestFailure);
    for (boundaries) |boundary| {
        const fixture = switch (boundary) {
            .after_preamble, .after_canonical_refresh => fixtures[5],
            .after_first_operand_staging => fixtures[0],
            .after_second_arithmetic_write => fixtures[6],
            else => fixtures[5],
        };
        var machine = MachineFunction.init(@tagName(boundary), .{ .int = fixture.bits });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try plan.interval_ends.put("lhs", 1);
        try plan.interval_ends.put("rhs", 1);
        try plan.interval_ends.put("result", 2);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 1;
        selector.stack_frame_bytes = 128;
        try selector_state.bindValueLoc(&selector, "lhs", fixture.lhs_loc);
        try selector_state.bindValueLoc(&selector, "rhs", fixture.rhs_loc);
        const value_count = selector.values.count();
        {
            var transaction = try Transaction.begin(&selector);
            defer transaction.deinit();
            transaction.named_scalar_test_failure = boundary;
            const lhs = try registerFixture(&transaction, fixture);
            try transaction.seal();
            try transaction.prepare();
            try transaction.materializeAll();
            try std.testing.expectError(
                error.ValueUseNamedScalarTestFailure,
                transaction.executePreparedAction(try transaction.preparedView(lhs)),
            );
        }
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(value_count, selector.values.count());
        try std.testing.expect(selector_state.resolveValue(&selector, .{ .named = "result" }) == null);
        try std.testing.expectEqual(@as(usize, 0), selector.eflags_semantics.items.len);
    }
}

test "value-use named scalar request provenance distinguishes lhs and rhs failures" {
    var machine = MachineFunction.init("provenance", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("lhs", 1);
    try plan.interval_ends.put("rhs", 1);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    try selector_state.bindValueLoc(&selector, "lhs", .{ .arg32 = .rdi });
    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const lhs = try registerFixture(&transaction, fixtures[5]);
    const rhs = transaction.requests[lhs.index].prepared_action.?.named_scalar_binary.rhs;
    try std.testing.expectError(error.ValueUseUnresolvedSource, transaction.seal());
    try std.testing.expect(!transaction.failedRequestIs(lhs));
    try std.testing.expect(transaction.failedRequestIs(rhs));
}
