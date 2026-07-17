const std = @import("std");
const ir = @import("../../../ir.zig");
const constant_table = @import("../constant_table.zig");
const machine_module = @import("../machine.zig");
const selector_types = @import("selector_types.zig");
const state_data = @import("composed_selector_state_data.zig");
const selector_state = @import("composed_selector_state.zig");
const selector_scalar = @import("composed_selector_scalar.zig");
const stage2_planning = @import("stage2_planning.zig");
const value_use = @import("composed_selector_value_use_transaction.zig");

const ComposedBlockSelector = state_data.ComposedBlockSelector;
const MachineFunction = machine_module.MachineFunction;
const SelectorAllocationPlan = stage2_planning.SelectorAllocationPlan;
const Transaction = value_use.ValueUseTransaction;
const ValueLoc = selector_types.ValueLoc;

fn addLive(plan: *SelectorAllocationPlan, name: []const u8) !void {
    try plan.interval_ends.put(name, 10);
}

fn addAtCurrent(plan: *SelectorAllocationPlan, name: []const u8) !void {
    try plan.interval_ends.put(name, 1);
}

fn expected(ty: ir.Type, class: selector_types.VirtualRegClass) Transaction.Expected {
    return .{
        .ty = ty,
        .register_class = class,
        .pointer_address_space = if (ty == .ptr) 0 else null,
    };
}

fn request(
    name: []const u8,
    ty: ir.Type,
    class: selector_types.VirtualRegClass,
    form: Transaction.UseForm,
    destination: Transaction.Destination,
) Transaction.Request {
    return .{
        .source = .{ .named = name },
        .expected = expected(ty, class),
        .form = form,
        .destination = destination,
    };
}

fn preparedRequest(
    name: []const u8,
    ty: ir.Type,
    class: selector_types.VirtualRegClass,
    form: Transaction.UseForm,
    action: Transaction.PreparedAction,
) Transaction.Request {
    var result = request(name, ty, class, form, .prepared_view);
    result.prepared_action = action;
    return result;
}

fn preparedSourceRequest(
    name: []const u8,
    ty: ir.Type,
    class: selector_types.VirtualRegClass,
    form: Transaction.UseForm,
) Transaction.Request {
    return request(name, ty, class, form, .prepared_source);
}

fn actionIdentity(name: []const u8) !Transaction.ActionIdentity {
    return Transaction.ActionIdentity.init(name);
}

fn scratchCompareExpected(ty: ir.Type) Transaction.Expected {
    return switch (ty) {
        .int => |bits| expected(ty, if (bits <= 32) .gpr32 else .gpr64),
        .ptr => expected(ty, .gpr64),
        else => unreachable,
    };
}

const ScratchCompareRequests = struct {
    lhs: Transaction.RequestHandle,
    rhs: ?Transaction.RequestHandle,
};

fn registerScratchCompare(
    transaction: *Transaction,
    lhs: ir.Value,
    rhs: union(enum) { immediate: i128, null_pointer, named: ir.Value },
    result: []const u8,
    ty: ir.Type,
    predicate: ir.IcmpPredicate,
    samesign: bool,
) !ScratchCompareRequests {
    const lhs_handle = try transaction.register(.{
        .source = lhs,
        .expected = scratchCompareExpected(ty),
        .form = .scratch_compare_operand,
        .destination = .prepared_view,
    });
    const rhs_handle: ?Transaction.RequestHandle = switch (rhs) {
        .named => |value| try transaction.register(.{
            .source = value,
            .expected = scratchCompareExpected(ty),
            .form = .scratch_compare_operand,
            .destination = .prepared_source,
        }),
        .immediate, .null_pointer => null,
    };
    try transaction.attachScratchCompareAction(lhs_handle, .{
        .result = try actionIdentity(result),
        .operand_ty = ty,
        .predicate = predicate,
        .samesign = samesign,
        .rhs = switch (rhs) {
            .immediate => |value| .{ .immediate = value },
            .null_pointer => .null_pointer,
            .named => .{ .named = rhs_handle.? },
        },
    });
    return .{ .lhs = lhs_handle, .rhs = rhs_handle };
}

fn registerCurrentHomeEqZero(
    transaction: *Transaction,
    source: ir.Value,
    result: []const u8,
    ty: ir.Type,
) !Transaction.RequestHandle {
    return transaction.register(.{
        .source = source,
        .expected = switch (ty) {
            .int => |bits| expected(ty, if (bits <= 32) .gpr32 else .gpr64),
            else => expected(ty, .gpr64),
        },
        .form = .current_home_eq_zero_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .current_home_eq_zero = .{
            .result = try actionIdentity(result),
            .operand_ty = ty,
        } },
    });
}

fn registerSetccEaxCompare(
    transaction: *Transaction,
    source: ir.Value,
    result: []const u8,
    ty: ir.Type,
    predicate: ir.IcmpPredicate,
    samesign: bool,
    immediate: i128,
    structure: Transaction.SetccEaxCompareStructure,
) !Transaction.RequestHandle {
    return transaction.register(.{
        .source = source,
        .expected = switch (ty) {
            .int => |bits| expected(ty, if (bits <= 32) .gpr32 else .gpr64),
            else => expected(ty, .gpr64),
        },
        .form = .setcc_eax_compare_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .setcc_eax_compare = .{
            .result = try actionIdentity(result),
            .operand_ty = ty,
            .predicate = predicate,
            .samesign = samesign,
            .immediate = immediate,
            .structure = structure,
        } },
    });
}

fn registerCurrentHomeSignBit(
    transaction: *Transaction,
    source: ir.Value,
    result: []const u8,
    ty: ir.Type,
) !Transaction.RequestHandle {
    return transaction.register(.{
        .source = source,
        .expected = switch (ty) {
            .int => |bits| expected(ty, if (bits <= 32) .gpr32 else .gpr64),
            else => expected(ty, .gpr64),
        },
        .form = .current_home_sign_bit_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .current_home_sign_bit = .{
            .result = try actionIdentity(result),
            .operand_ty = ty,
        } },
    });
}

const I128PairActionKind = enum {
    eq_min,
    sign_bit,
};

fn registerI128PairAction(
    transaction: *Transaction,
    source: ir.Value,
    result: []const u8,
    kind: I128PairActionKind,
) !Transaction.RequestHandle {
    return transaction.register(.{
        .source = source,
        .expected = expected(.{ .int = 128 }, .gpr128),
        .form = .i128_icmp_pair_operand,
        .destination = .prepared_view,
        .prepared_action = switch (kind) {
            .eq_min => .{ .i128_eq_min = .{
                .result = try actionIdentity(result),
            } },
            .sign_bit => .{ .i128_sign_bit = .{
                .result = try actionIdentity(result),
            } },
        },
    });
}

fn i128PairDiagnosticForTest(
    transaction: *const Transaction,
    source: Transaction.RequestHandle,
    err: anyerror,
) ?[]const u8 {
    if (!transaction.failedRequestIs(source)) return null;
    return switch (err) {
        error.ValueUseUnresolvedSource,
        error.UnsupportedCodegenValue,
        => "composed-block-icmp-lhs",
        error.ValueUseI128PairWidthUnsupported => "composed-block-icmp-lhs-width",
        error.ValueUseI128PairLocationUnsupported => "composed-block-icmp-lhs-loc",
        else => null,
    };
}

fn currentHomeSignBitDiagnosticForTest(
    transaction: *const Transaction,
    source: Transaction.RequestHandle,
    err: anyerror,
) ?[]const u8 {
    if (!transaction.failedRequestIs(source)) return null;
    return switch (err) {
        error.ValueUseUnresolvedSource => "composed-block-icmp-lhs",
        error.ValueUseCurrentHomeSignBitWidthUnsupported => "composed-block-icmp-lhs-width",
        error.ValueUseCurrentHomeSignBitLocationUnsupported => "composed-block-icmp-lhs-loc",
        else => null,
    };
}

fn setccEaxCompareDiagnosticForTest(
    transaction: *const Transaction,
    source: Transaction.RequestHandle,
    err: anyerror,
) ?[]const u8 {
    if (!transaction.failedRequestIs(source)) return null;
    return switch (err) {
        error.ValueUseUnresolvedSource => "composed-block-icmp-lhs",
        error.ValueUseSetccEaxCompareWidthUnsupported => "composed-block-icmp-lhs-width",
        error.ValueUseSetccEaxCompareLocationUnsupported => "composed-block-icmp-lhs-loc",
        else => null,
    };
}

fn currentHomeEqZeroDiagnosticForTest(
    transaction: *const Transaction,
    source: Transaction.RequestHandle,
    err: anyerror,
) ?[]const u8 {
    if (!transaction.failedRequestIs(source)) return null;
    return switch (err) {
        error.ValueUseUnresolvedSource => "composed-block-icmp-lhs",
        error.ValueUseCurrentHomeEqZeroWidthUnsupported => "composed-block-icmp-lhs-width",
        error.ValueUseCurrentHomeEqZeroLocationUnsupported => "composed-block-icmp-lhs-loc",
        else => null,
    };
}

const MemcpyRequests = struct {
    destination: Transaction.RequestHandle,
    source: Transaction.RequestHandle,
    length: Transaction.RequestHandle,
};

fn registerMemcpyRequests(
    transaction: *Transaction,
    destination: ir.Value,
    source: ir.Value,
    length: ir.Value,
) !MemcpyRequests {
    const source_handle = try transaction.register(.{
        .source = source,
        .expected = expected(.ptr, .gpr64),
        .form = .memcpy_pointer,
        .destination = .prepared_source,
    });
    const length_handle = try transaction.register(.{
        .source = length,
        .expected = expected(.{ .int = 64 }, .gpr64),
        .form = .memcpy_length,
        .destination = .prepared_source,
    });
    const destination_handle = try transaction.register(.{
        .source = destination,
        .expected = expected(.ptr, .gpr64),
        .form = .memcpy_pointer,
        .destination = .prepared_view,
        .prepared_action = .{ .inline_memcpy = .{
            .source = source_handle,
            .length = length_handle,
        } },
    });
    return .{
        .destination = destination_handle,
        .source = source_handle,
        .length = length_handle,
    };
}

fn registerMemcpyAction(
    transaction: *Transaction,
    destination: ir.Value,
    source: ir.Value,
    length: ir.Value,
) !Transaction.RequestHandle {
    return (try registerMemcpyRequests(transaction, destination, source, length)).destination;
}

fn inlineMemcpyValueUseDiagnosticForTest(
    transaction: *const Transaction,
    requests: MemcpyRequests,
) ?[]const u8 {
    if (transaction.failedRequestIs(requests.destination)) return "composed-block-memcpy-dst";
    if (transaction.failedRequestIs(requests.source)) return "composed-block-memcpy-src";
    if (transaction.failedRequestIs(requests.length)) return "composed-block-memcpy-len";
    return null;
}

fn prepareAndExecuteAction(
    transaction: *Transaction,
    action: Transaction.RequestHandle,
) !void {
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(action));
}

fn executeScratchCompareCase(
    ty: ir.Type,
    predicate: ir.IcmpPredicate,
    samesign: bool,
    rhs: union(enum) { immediate: i128, null_pointer, named: ValueLoc },
    lhs_loc: ValueLoc,
    expected_instructions: []const machine_module.Instruction,
    expected_effects: []const selector_state.EflagsEffect,
) !void {
    var machine = MachineFunction.init("value-use-scratch-compare-case", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "lhs");
    if (rhs == .named) try addAtCurrent(&plan, "rhs");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "lhs", lhs_loc);
    if (rhs == .named) try selector_state.bindValueLoc(&selector, "rhs", rhs.named);

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const requests = try registerScratchCompare(
        &transaction,
        .{ .named = "lhs" },
        switch (rhs) {
            .immediate => |value| .{ .immediate = value },
            .null_pointer => .null_pointer,
            .named => .{ .named = .{ .named = "rhs" } },
        },
        "result",
        ty,
        predicate,
        samesign,
    );
    try transaction.seal();
    _ = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(requests.lhs));
    try transaction.commit();

    try std.testing.expectEqualSlices(machine_module.Instruction, expected_instructions, machine.instructions.items);
    try std.testing.expectEqual(ValueLoc.eax, selector.values.get("result").?.loc);
    try std.testing.expectEqual(expected_effects.len, selector.eflags_semantics.items.len);
    for (expected_effects, selector.eflags_semantics.items) |effect, record|
        try std.testing.expectEqual(effect, record.effect);
}

fn executeCurrentHomeEqZeroCase(
    ty: ir.Type,
    source_loc: ValueLoc,
    binding_class: selector_types.VirtualRegClass,
    binding_bits: u16,
    expected_instructions: []const machine_module.Instruction,
) !void {
    var machine = MachineFunction.init("value-use-current-home-eq-zero-case", .{ .int = 1 });
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
    selector.values.getPtr("source").?.vreg.class = binding_class;
    selector.values.getPtr("source").?.vreg.bits = binding_bits;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const source = try registerCurrentHomeEqZero(
        &transaction,
        .{ .named = "source" },
        "result",
        ty,
    );
    try transaction.seal();
    _ = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(source));
    try transaction.commit();

    try std.testing.expectEqualSlices(
        machine_module.Instruction,
        expected_instructions,
        machine.instructions.items,
    );
    try std.testing.expectEqual(ValueLoc.eax, selector.values.get("result").?.loc);
    try std.testing.expectEqual(@as(usize, 2), selector.eflags_semantics.items.len);
    try std.testing.expectEqual(selector_state.EflagsEffect.definition, selector.eflags_semantics.items[0].effect);
    try std.testing.expectEqual(selector_state.EflagsEffect.use, selector.eflags_semantics.items[1].effect);
}

fn executeSetccEaxCompareCase(
    ty: ir.Type,
    predicate: ir.IcmpPredicate,
    samesign: bool,
    immediate: i128,
    structure: Transaction.SetccEaxCompareStructure,
    source_loc: ValueLoc,
    binding_class: selector_types.VirtualRegClass,
    binding_bits: u16,
    expected_instructions: []const machine_module.Instruction,
    expected_effects: []const selector_state.EflagsEffect,
) !void {
    var machine = MachineFunction.init("value-use-setcc-eax-compare-case", .{ .int = 1 });
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
    selector.values.getPtr("source").?.vreg.class = binding_class;
    selector.values.getPtr("source").?.vreg.bits = binding_bits;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const source = try registerSetccEaxCompare(
        &transaction,
        .{ .named = "source" },
        "result",
        ty,
        predicate,
        samesign,
        immediate,
        structure,
    );
    try transaction.seal();
    _ = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(source));
    try transaction.commit();

    try std.testing.expectEqualSlices(
        machine_module.Instruction,
        expected_instructions,
        machine.instructions.items,
    );
    try std.testing.expectEqual(ValueLoc.eax, selector.values.get("result").?.loc);
    try std.testing.expectEqual(expected_effects.len, selector.eflags_semantics.items.len);
    for (expected_effects, selector.eflags_semantics.items) |effect, record|
        try std.testing.expectEqual(effect, record.effect);
}

fn executeCurrentHomeSignBitCase(
    ty: ir.Type,
    source_loc: ValueLoc,
    binding_class: selector_types.VirtualRegClass,
    binding_bits: u16,
    expected_instructions: []const machine_module.Instruction,
) !void {
    var machine = MachineFunction.init("value-use-current-home-sign-bit-case", .{ .int = 1 });
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
    selector.values.getPtr("source").?.vreg.class = binding_class;
    selector.values.getPtr("source").?.vreg.bits = binding_bits;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const source = try registerCurrentHomeSignBit(
        &transaction,
        .{ .named = "source" },
        "result",
        ty,
    );
    try transaction.seal();
    _ = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(source));
    try transaction.commit();

    try std.testing.expectEqualSlices(
        machine_module.Instruction,
        expected_instructions,
        machine.instructions.items,
    );
    try std.testing.expectEqual(ValueLoc.eax, selector.values.get("result").?.loc);
    try std.testing.expectEqual(@as(usize, 1), selector.eflags_semantics.items.len);
    try std.testing.expectEqual(
        selector_state.EflagsEffect.write,
        selector.eflags_semantics.items[0].effect,
    );
}

fn executeI128PairActionCase(
    kind: I128PairActionKind,
    source_loc: ValueLoc,
    expected_instructions: []const machine_module.Instruction,
    expected_effects: []const selector_state.EflagsEffect,
) !void {
    var machine = MachineFunction.init("value-use-i128-pair-action-case", .{ .int = 1 });
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

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const source = try registerI128PairAction(
        &transaction,
        .{ .named = "source" },
        "result",
        kind,
    );
    try transaction.seal();
    _ = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(source));
    try transaction.commit();

    try std.testing.expectEqualSlices(
        machine_module.Instruction,
        expected_instructions,
        machine.instructions.items,
    );
    try std.testing.expectEqual(ValueLoc.eax, selector.values.get("result").?.loc);
    try std.testing.expectEqual(expected_effects.len, selector.eflags_semantics.items.len);
    for (expected_effects, selector.eflags_semantics.items) |effect, record|
        try std.testing.expectEqual(effect, record.effect);
}

fn executeBranchConditionCase(
    loc: ValueLoc,
    binding_class: selector_types.VirtualRegClass,
    binding_bits: u16,
    expected_instructions: []const machine_module.Instruction,
) !void {
    var machine = MachineFunction.init("value-use-branch-condition-case", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "condition");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "condition", loc);
    selector.values.getPtr("condition").?.vreg.class = binding_class;
    selector.values.getPtr("condition").?.vreg.bits = binding_bits;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const action = try transaction.register(preparedRequest(
        "condition",
        .{ .int = 1 },
        .gpr32,
        .branch_condition,
        .branch_condition,
    ));
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(action));
    try transaction.commit();

    try std.testing.expectEqualSlices(machine_module.Instruction, expected_instructions, machine.instructions.items);
    try std.testing.expectEqual(@as(usize, 1), selector.eflags_semantics.items.len);
    try selector_state.emitEflagsInstruction(&selector, .sete_eax, .use);
}

fn oneCaseSwitchAction(bits: u8) !Transaction.SwitchCompareChainAction {
    return Transaction.SwitchCompareChainAction.init(
        bits,
        &.{.{ .value = 7, .target = "case-seven" }},
        "default",
        null,
    );
}

fn executeSwitchConditionCase(
    loc: ValueLoc,
    binding_class: selector_types.VirtualRegClass,
    binding_bits: u8,
    expected_first: machine_module.Instruction,
) !void {
    var machine = MachineFunction.init("value-use-switch-condition-case", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "condition");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "condition", loc);
    selector.values.getPtr("condition").?.vreg.class = binding_class;
    selector.values.getPtr("condition").?.vreg.bits = binding_bits;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const action = try transaction.register(preparedRequest(
        "condition",
        .{ .int = 32 },
        .gpr32,
        .switch_condition,
        .{ .switch_compare_chain = try oneCaseSwitchAction(32) },
    ));
    try transaction.seal();
    try transaction.applySwitchBoundary(action);
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(action));
    try transaction.commit();
    try std.testing.expectEqual(expected_first, machine.instructions.items[0]);
}

test "value-use transaction exposes fixed copy-amplification contract" {
    try std.testing.expectEqual(@as(usize, 16), Transaction.max_requests);
    try std.testing.expectEqual(@as(usize, 1), Transaction.address_domain_snapshot_copies);
    try std.testing.expectEqual(@as(usize, 0), Transaction.address_domain_copies_per_request);
    try std.testing.expect(Transaction.address_domain_snapshot_bytes > 0);
}

test "value-use branch action reproduces exact accepted homes and commits EFLAGS" {
    try executeBranchConditionCase(.eax, .gpr32, 1, &.{.test_eax_eax});
    try executeBranchConditionCase(.{ .arg32 = .rdi }, .gpr32, 1, &.{.{ .test_arg8 = .rdi }});
    try executeBranchConditionCase(.{ .scratch32 = .r8 }, .gpr32, 1, &.{.{ .test_arg8 = .r8 }});
    try executeBranchConditionCase(.{ .spill64 = .slot2 }, .gpr64, 64, &.{
        .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = .slot2 } },
        .{ .test_arg8 = .rcx },
    });
}

test "value-use branch action rejects generic narrow homes the accepted path rejects" {
    var machine = MachineFunction.init("value-use-branch-exact-home", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "condition");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "condition", .{ .arg64 = .rdi });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    _ = try transaction.register(preparedRequest(
        "condition",
        .{ .int = 1 },
        .gpr32,
        .branch_condition,
        .branch_condition,
    ));
    try std.testing.expectError(error.ValueUseBranchConditionHomeUnsupported, transaction.seal());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "value-use branch action rolls back spill preparation on EFLAGS rejection" {
    var machine = MachineFunction.init("value-use-branch-eflags-rollback", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "condition");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "condition", .{ .spill64 = .slot0 });
    selector.values.getPtr("condition").?.vreg.class = .gpr64;
    selector.values.getPtr("condition").?.vreg.bits = 64;
    try selector_state.emitEflagsInstruction(&selector, .{ .cmp_eax_imm32 = 1 }, .definition);
    const before_binding = selector.values.get("condition").?;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const action = try transaction.register(preparedRequest(
        "condition",
        .{ .int = 1 },
        .gpr32,
        .branch_condition,
        .branch_condition,
    ));
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try std.testing.expectError(
        error.EflagsDefinitionOverwrittenWhileLive,
        transaction.executePreparedAction(try transaction.preparedView(action)),
    );
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{.{ .cmp_eax_imm32 = 1 }}, machine.instructions.items);
    try std.testing.expectEqual(before_binding, selector.values.get("condition").?);
    try std.testing.expectEqual(@as(usize, 1), selector.eflags_semantics.items.len);
}

test "value-use switch action owns intent and reproduces ordinary compare chain" {
    var machine = MachineFunction.init("value-use-switch-chain", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "condition");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "condition", .{ .arg64 = .rdi });

    var case_name = [_]u8{ 'c', 'a', 's', 'e', '-', 's', 'e', 'v', 'e', 'n' };
    var default_name = [_]u8{ 'd', 'e', 'f', 'a', 'u', 'l', 't' };
    const switch_action = try Transaction.SwitchCompareChainAction.init(
        8,
        &.{.{ .value = 7, .target = &case_name }},
        &default_name,
        null,
    );
    @memset(&case_name, 'x');
    @memset(&default_name, 'y');

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const action = try transaction.register(preparedRequest(
        "condition",
        .{ .int = 8 },
        .gpr32,
        .switch_condition,
        .{ .switch_compare_chain = switch_action },
    ));
    try transaction.seal();
    try transaction.applySwitchBoundary(action);
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(action));
    try transaction.commit();

    try std.testing.expectEqual(@as(usize, 5), machine.instructions.items.len);
    try std.testing.expectEqual(machine_module.Instruction{ .mov_arg_eax = .rdi }, machine.instructions.items[0]);
    try std.testing.expectEqual(machine_module.Instruction{ .and_eax_imm32 = 255 }, machine.instructions.items[1]);
    try std.testing.expectEqual(machine_module.Instruction{ .cmp_eax_imm32 = 7 }, machine.instructions.items[2]);
    try std.testing.expect(machine.instructions.items[3] == .je);
    try std.testing.expectEqualStrings("case-seven", machine.instructions.items[3].je);
    try std.testing.expect(machine.instructions.items[4] == .jmp);
    try std.testing.expectEqualStrings("default", machine.instructions.items[4].jmp);
    try std.testing.expectEqual(@as(usize, 2), machine.owned_labels.items.len);
    try std.testing.expectEqual(@as(usize, 0), selector.edge_label_count);
    try std.testing.expectEqual(@as(usize, 3), selector.eflags_semantics.items.len);
}

test "value-use switch action accepts fixed-owned immediate intent" {
    var machine = MachineFunction.init("value-use-switch-immediate", .void);
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    var switch_request = Transaction.Request{
        .source = .{ .int = 7 },
        .expected = expected(.{ .int = 32 }, .gpr32),
        .form = .switch_condition,
        .destination = .prepared_view,
        .prepared_action = .{ .switch_compare_chain = try oneCaseSwitchAction(32) },
    };
    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const action = try transaction.register(switch_request);
    switch_request.source = .{ .int = 99 };
    try transaction.seal();
    try transaction.applySwitchBoundary(action);
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(action));
    try transaction.commit();
    try std.testing.expectEqual(machine_module.Instruction{ .mov_imm_eax = 7 }, machine.instructions.items[0]);
}

test "value-use switch action reproduces every accepted named condition home" {
    try executeSwitchConditionCase(.eax, .gpr32, 32, .{ .cmp_eax_imm32 = 7 });
    try executeSwitchConditionCase(.rax, .gpr64, 64, .{ .cmp_eax_imm32 = 7 });
    try executeSwitchConditionCase(.{ .arg32 = .rdi }, .gpr32, 32, .{ .mov_arg_eax = .rdi });
    try executeSwitchConditionCase(.{ .scratch32 = .r8 }, .gpr32, 32, .{ .mov_arg_eax = .r8 });
    try executeSwitchConditionCase(.{ .arg64 = .rsi }, .gpr64, 64, .{ .mov_arg_eax = .rsi });
    try executeSwitchConditionCase(.{ .scratch64 = .r9 }, .gpr64, 64, .{ .mov_arg_eax = .r9 });
    try executeSwitchConditionCase(
        .{ .arg128 = .{ .lo = .rdi, .hi = .rsi } },
        .gpr128,
        128,
        .{ .mov_arg_eax = .rdi },
    );
    try executeSwitchConditionCase(
        .{ .scratch128 = .{ .lo = .r8, .hi = .r9 } },
        .gpr128,
        128,
        .{ .mov_arg_eax = .r8 },
    );
    try executeSwitchConditionCase(.{ .spill64 = .slot2 }, .gpr64, 64, .{ .reload_rsp_eax = .slot2 });
}

test "value-use switch action rejects invalid fixed storage and unsupported homes" {
    try std.testing.expectError(
        error.ValueUseSwitchDuplicateCase,
        Transaction.SwitchCompareChainAction.init(
            8,
            &.{
                .{ .value = 1, .target = "one" },
                .{ .value = 1, .target = "duplicate" },
            },
            "default",
            null,
        ),
    );
    try std.testing.expectError(
        error.ValueUseSwitchCaseCountUnsupported,
        Transaction.SwitchCompareChainAction.init(8, &.{}, "default", null),
    );

    var machine = MachineFunction.init("value-use-switch-rejected-home", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "condition");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "condition", .{ .spill64 = .slot0 });
    selector.values.getPtr("condition").?.vreg.class = .gpr128;
    selector.values.getPtr("condition").?.vreg.bits = 128;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const action = try transaction.register(preparedRequest(
        "condition",
        .{ .int = 32 },
        .gpr32,
        .switch_condition,
        .{ .switch_compare_chain = try oneCaseSwitchAction(32) },
    ));
    try transaction.seal();
    try std.testing.expectError(error.ValueUseSwitchConditionHomeUnsupported, transaction.applySwitchBoundary(action));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "value-use switch resolves after boundary and rollback restores all boundary state" {
    var machine = MachineFunction.init("value-use-switch-boundary", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addLive(&plan, "condition");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 64;
    try selector_state.bindValueLoc(&selector, "condition", .{ .arg32 = .rdi });
    const before_binding = selector.values.get("condition").?;
    const before_next_spill = selector.next_spill_slot;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const action = try transaction.register(preparedRequest(
        "condition",
        .{ .int = 32 },
        .gpr32,
        .switch_condition,
        .{ .switch_compare_chain = try oneCaseSwitchAction(32) },
    ));
    try transaction.seal();
    try transaction.applySwitchBoundary(action);
    try std.testing.expect(selector.values.get("condition").?.loc == .spill64);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try transaction.prepare();
    try transaction.rollback();

    try std.testing.expectEqual(before_binding, selector.values.get("condition").?);
    try std.testing.expectEqual(before_next_spill, selector.next_spill_slot);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
}

test "value-use switch rollback restores displaced PHI destinations and owned targets" {
    var machine = MachineFunction.init("value-use-switch-phi-rollback", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addLive(&plan, "phi");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector.phi_destinations.put("phi", .{ .scratch64 = .rcx });
    try selector_state.bindValueLoc(&selector, "phi", .{ .spill64 = .slot2 });
    const before_binding = selector.values.get("phi").?;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const action = try transaction.register(.{
        .source = .{ .int = 7 },
        .expected = expected(.{ .int = 32 }, .gpr32),
        .form = .switch_condition,
        .destination = .prepared_view,
        .prepared_action = .{ .switch_compare_chain = try oneCaseSwitchAction(32) },
    });
    try transaction.seal();
    try transaction.applySwitchBoundary(action);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector.values.get("phi").?.loc);
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(action));
    try std.testing.expectEqual(@as(usize, 2), machine.owned_labels.items.len);
    try transaction.rollback();

    try std.testing.expectEqual(before_binding, selector.values.get("phi").?);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector.phi_destinations.get("phi").?);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
}

test "value-use closed scalar store preserves same-register aliases and live EFLAGS" {
    var machine = MachineFunction.init("value-use-store-scalar-alias", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "value", "pointer" }) |name| try addAtCurrent(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "value", .{ .arg32 = .rdi });
    try selector_state.bindValueLoc(&selector, "pointer", .{ .arg64 = .rdi });
    try selector_state.emitEflagsInstruction(&selector, .{ .cmp_eax_imm32 = 0 }, .definition);

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const pointer = try transaction.register(preparedSourceRequest("pointer", .ptr, .gpr64, .pointer));
    const action = try transaction.register(preparedRequest(
        "value",
        .{ .int = 32 },
        .gpr32,
        .gpr32,
        .{ .store_scalar = .{ .pointer = pointer, .bits = 32 } },
    ));
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(action));
    try transaction.commit();

    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .cmp_eax_imm32 = 0 },
        .{ .mov_arg_eax = .rdi },
        .{ .store_eax_arg_ptr = .rdi },
    }, machine.instructions.items);
    try selector_state.emitEflagsInstruction(&selector, .sete_eax, .use);
}

test "inbox92 actual wide spill binding uses the semantic low32 view through every phase" {
    var machine = MachineFunction.init("inbox92-store-actual-binding", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "%236", "index", "addend", "%166" }) |name| try plan.interval_ends.put(name, 395);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 395;
    selector.stack_frame_bytes = 8192;
    try selector_state.bindValueLoc(&selector, "%236", .{ .spill64 = .{ .slot = 380 } });
    try selector_state.bindValueLoc(&selector, "index", .{ .spill64 = .{ .slot = 486 } });
    try selector_state.bindValueLoc(&selector, "addend", .{ .spill64 = .{ .slot = 450 } });
    try selector_state.bindValueLoc(&selector, "%166", .{ .stack_i32_ptr = .{
        .disp = 0x1b94,
        .index = .{ .reg = .rcx, .name = "index", .addend_name = "addend" },
    } });

    const actual_binding = selector.values.get("%236").?;
    try std.testing.expectEqual(selector_types.VirtualRegClass.gpr64, actual_binding.vreg.class);
    try std.testing.expectEqual(@as(u8, 64), actual_binding.vreg.bits);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .{ .slot = 380 } }, actual_binding.loc);

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const pointer = try transaction.register(preparedSourceRequest("%166", .ptr, .stack_pointer, .pointer));
    const action = try transaction.register(preparedRequest(
        "%236",
        .{ .int = 32 },
        .gpr32,
        .gpr32,
        .{ .store_scalar = .{ .pointer = pointer, .bits = 32 } },
    ));
    try std.testing.expectEqual(@as(usize, 2), transaction.requestCount());
    try std.testing.expectEqual(Transaction.RequestPhase.registering, transaction.phase());
    try std.testing.expectEqual(actual_binding, selector.values.get("%236").?);
    try transaction.seal();
    try std.testing.expectEqual(Transaction.RequestPhase.sealed, transaction.phase());
    try std.testing.expectEqual(actual_binding, selector.values.get("%236").?);
    try transaction.prepare();
    try std.testing.expectEqual(Transaction.RequestPhase.prepared, transaction.phase());
    try std.testing.expectEqual(actual_binding, selector.values.get("%236").?);
    try transaction.materializeAll();
    try std.testing.expectEqual(Transaction.RequestPhase.materialized, transaction.phase());
    try std.testing.expectEqual(actual_binding, selector.values.get("%236").?);
    try transaction.executePreparedAction(try transaction.preparedView(action));
    try transaction.commit();
    try std.testing.expectEqual(actual_binding, selector.values.get("%236").?);
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .reload_rsp_eax = .{ .slot = 380 } },
        .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .{ .slot = 486 } } },
        .{ .reload_arg64_rsp = .{ .reg = .r8, .frame_index = .{ .slot = 450 } } },
        .add_r8_rcx,
        .{ .store_eax_stack_rcx4_disp32 = 0x1b94 },
    }, machine.instructions.items);
}

test "narrow semantic view does not relax its request type contract" {
    var machine = MachineFunction.init("value-use-narrow-view-type-contract", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "value", "pointer" }) |name| try addAtCurrent(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    try selector_state.bindValueLoc(&selector, "value", .{ .spill64 = .slot0 });
    try selector_state.bindValueLoc(&selector, "pointer", .{ .arg64 = .rdi });
    const actual_binding = selector.values.get("value").?;

    var type_transaction = try Transaction.begin(&selector);
    defer type_transaction.deinit();
    const type_pointer = try type_transaction.register(preparedSourceRequest("pointer", .ptr, .gpr64, .pointer));
    _ = try type_transaction.register(preparedRequest(
        "value",
        .{ .int = 32 },
        .gpr64,
        .gpr32,
        .{ .store_scalar = .{ .pointer = type_pointer, .bits = 32 } },
    ));
    try std.testing.expectError(error.ValueUseTypeMismatch, type_transaction.seal());
    try std.testing.expectEqual(Transaction.RequestPhase.registering, type_transaction.phase());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(actual_binding, selector.values.get("value").?);
}

test "inbox92 valid spill32 request remains available through every transaction phase" {
    var machine = MachineFunction.init("inbox92-store-valid-spill-lifecycle", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "value", "index", "pointer" }) |name| try addAtCurrent(&plan, name);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "value", .{ .spill64 = .slot0 });
    selector.values.getPtr("value").?.vreg.class = .gpr32;
    selector.values.getPtr("value").?.vreg.bits = 32;
    try selector_state.bindValueLoc(&selector, "index", .{ .spill64 = .slot2 });
    try selector_state.bindValueLoc(&selector, "pointer", .{ .stack_i32_ptr = .{
        .disp = 24,
        .index = .{ .reg = .rcx, .name = "index" },
    } });
    const saved_value = selector.values.get("value").?;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const pointer = try transaction.register(preparedSourceRequest("pointer", .ptr, .stack_pointer, .pointer));
    const action = try transaction.register(preparedRequest(
        "value",
        .{ .int = 32 },
        .gpr32,
        .gpr32,
        .{ .store_scalar = .{ .pointer = pointer, .bits = 32 } },
    ));
    try std.testing.expectEqual(Transaction.RequestPhase.registering, transaction.phase());
    try std.testing.expectEqual(saved_value, selector.values.get("value").?);
    try transaction.seal();
    try std.testing.expectEqual(Transaction.RequestPhase.sealed, transaction.phase());
    try std.testing.expectEqual(saved_value, selector.values.get("value").?);
    try transaction.prepare();
    try std.testing.expectEqual(Transaction.RequestPhase.prepared, transaction.phase());
    try std.testing.expectEqual(saved_value, selector.values.get("value").?);
    try transaction.materializeAll();
    try std.testing.expectEqual(Transaction.RequestPhase.materialized, transaction.phase());
    try std.testing.expectEqual(saved_value, selector.values.get("value").?);
    try transaction.executePreparedAction(try transaction.preparedView(action));
    try transaction.commit();

    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .reload_rsp_eax = .slot0 },
        .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot2 } },
        .{ .store_eax_stack_rcx4_disp8 = 24 },
    }, machine.instructions.items);
}

test "narrow semantic view admits audited wide register and accumulator homes without rebinding" {
    {
        var machine = MachineFunction.init("value-use-narrow-wide-register", .void);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "value", "pointer" }) |name| try addAtCurrent(&plan, name);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 1;
        try selector_state.bindValueLoc(&selector, "value", .{ .arg64 = .rsi });
        try selector_state.bindValueLoc(&selector, "pointer", .{ .arg64 = .rdi });
        const saved_value = selector.values.get("value").?;

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const pointer = try transaction.register(preparedSourceRequest("pointer", .ptr, .gpr64, .pointer));
        const action = try transaction.register(preparedRequest(
            "value",
            .{ .int = 32 },
            .gpr32,
            .gpr32,
            .{ .store_scalar = .{ .pointer = pointer, .bits = 32 } },
        ));
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(action));
        try transaction.commit();

        try std.testing.expectEqual(saved_value, selector.values.get("value").?);
        try std.testing.expectEqualSlices(machine_module.Instruction, &.{
            .{ .mov_arg_eax = .rsi },
            .{ .store_eax_arg_ptr = .rdi },
        }, machine.instructions.items);
    }

    {
        var machine = MachineFunction.init("value-use-narrow-wide-accumulator", .void);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "value", "pointer" }) |name| try addAtCurrent(&plan, name);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 1;
        try selector_state.bindValueLoc(&selector, "value", .rax);
        try selector_state.bindValueLoc(&selector, "pointer", .{ .arg64 = .rdi });
        const saved_value = selector.values.get("value").?;

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const pointer = try transaction.register(preparedSourceRequest("pointer", .ptr, .gpr64, .pointer));
        const action = try transaction.register(preparedRequest(
            "value",
            .{ .int = 32 },
            .gpr32,
            .gpr32,
            .{ .store_scalar = .{ .pointer = pointer, .bits = 32 } },
        ));
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(action));
        try transaction.commit();

        try std.testing.expectEqual(saved_value, selector.values.get("value").?);
        try std.testing.expectEqualSlices(machine_module.Instruction, &.{
            .{ .store_eax_arg_ptr = .rdi },
        }, machine.instructions.items);
    }
}

test "inbox92 wide spilled value live after store reloads once and retains its binding" {
    var machine = MachineFunction.init("inbox92-wide-spill-live-after", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("value", 2);
    inline for (&.{ "index", "pointer" }) |name| try addAtCurrent(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "value", .{ .spill64 = .slot0 });
    try selector_state.bindValueLoc(&selector, "index", .{ .spill64 = .slot2 });
    try selector_state.bindValueLoc(&selector, "pointer", .{ .stack_i32_ptr = .{
        .disp = 24,
        .index = .{ .reg = .rcx, .name = "index" },
    } });
    const saved_value = selector.values.get("value").?;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const pointer = try transaction.register(preparedSourceRequest("pointer", .ptr, .stack_pointer, .pointer));
    const action = try transaction.register(preparedRequest(
        "value",
        .{ .int = 32 },
        .gpr32,
        .gpr32,
        .{ .store_scalar = .{ .pointer = pointer, .bits = 32 } },
    ));
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(action));
    try transaction.commit();

    var reload_count: usize = 0;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .reload_rsp_eax => |frame_index| if (frame_index.eql(.slot0)) {
            reload_count += 1;
        },
        else => {},
    };
    try std.testing.expectEqual(@as(usize, 1), reload_count);
    try std.testing.expectEqual(saved_value, selector.values.get("value").?);
}

test "inbox92 wide spilled value rollback after preparation restores exact state" {
    var machine = MachineFunction.init("inbox92-wide-spill-rollback", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "value", "index", "addend", "pointer" }) |name| try addAtCurrent(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "value", .{ .spill64 = .slot0 });
    try selector_state.bindValueLoc(&selector, "index", .{ .spill64 = .slot2 });
    try selector_state.bindValueLoc(&selector, "addend", .{ .spill64 = .slot4 });
    try selector_state.bindValueLoc(&selector, "pointer", .{ .stack_i32_ptr = .{
        .disp = 24,
        .index = .{ .reg = .rcx, .name = "index", .addend_name = "addend" },
    } });
    try selector_state.emitEflagsInstruction(&selector, .{ .cmp_eax_imm32 = 0 }, .definition);
    const saved_value = selector.values.get("value").?;
    const saved_pointer = selector.values.get("pointer").?;
    const saved_dependencies = selector.address_dependencies;
    const saved_eflags = selector.eflags.snapshot();

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const pointer = try transaction.register(preparedSourceRequest("pointer", .ptr, .stack_pointer, .pointer));
    const action = try transaction.register(preparedRequest(
        "value",
        .{ .int = 32 },
        .gpr32,
        .gpr32,
        .{ .store_scalar = .{ .pointer = pointer, .bits = 32 } },
    ));
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try std.testing.expectError(
        error.EflagsClobberedWhileLive,
        transaction.executePreparedAction(try transaction.preparedView(action)),
    );

    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(saved_value, selector.values.get("value").?);
    try std.testing.expectEqual(saved_pointer, selector.values.get("pointer").?);
    try std.testing.expect(selector.address_dependencies.eql(&saved_dependencies));
    try selector.eflags.validateSnapshot(saved_eflags);
}

test "narrow semantic view compatibility remains fail closed outside audited cells" {
    {
        var machine = MachineFunction.init("value-use-narrow-insufficient-width", .void);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "value");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 1;
        try selector_state.bindValueLoc(&selector, "value", .{ .arg64 = .rdi });
        selector.values.getPtr("value").?.vreg.bits = 16;
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        _ = try transaction.register(request("value", .{ .int = 32 }, .gpr32, .gpr32, .eax));
        try std.testing.expectError(error.ValueUseRegisterClassMismatch, transaction.seal());
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }

    {
        var machine = MachineFunction.init("value-use-narrow-non-integer", .void);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "value");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 1;
        try selector_state.bindValueLoc(&selector, "value", .{ .arg64 = .rdi });
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        _ = try transaction.register(request("value", .ptr, .gpr32, .gpr32, .eax));
        try std.testing.expectError(error.ValueUseRegisterClassMismatch, transaction.seal());
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }

    {
        var machine = MachineFunction.init("value-use-narrow-unsupported-home", .void);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "value");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 1;
        try selector_state.bindValueLoc(&selector, "value", .{ .arg32 = .rdi });
        selector.values.getPtr("value").?.vreg.class = .gpr64;
        selector.values.getPtr("value").?.vreg.bits = 64;
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        _ = try transaction.register(request("value", .{ .int = 32 }, .gpr32, .gpr32, .eax));
        try std.testing.expectError(error.ValueUseRegisterClassMismatch, transaction.seal());
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }

    {
        var machine = MachineFunction.init("value-use-narrow-pointer-class", .void);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "pointer");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 1;
        try selector_state.bindValueLoc(&selector, "pointer", .{ .stack_i32_ptr = .{ .disp = 24 } });
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        _ = try transaction.register(request("pointer", .ptr, .gpr64, .pointer, .{ .gpr64 = .rcx }));
        try std.testing.expectError(error.ValueUseRegisterClassMismatch, transaction.seal());
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }

    {
        var machine = MachineFunction.init("value-use-narrow-durable-action", .void);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "value");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 1;
        try selector_state.bindValueLoc(&selector, "value", .{ .arg64 = .rdi });
        const saved_value = selector.values.get("value").?;
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        _ = try transaction.register(preparedRequest(
            "value",
            .{ .int = 32 },
            .gpr32,
            .gpr32,
            .{ .form_byte_address = .{
                .result = try actionIdentity("durable"),
                .offset = .{ .constant = 0 },
            } },
        ));
        try std.testing.expectError(error.ValueUsePreparedActionFormMismatch, transaction.seal());
        try std.testing.expectEqual(saved_value, selector.values.get("value").?);
        try std.testing.expect(!selector.values.contains("durable"));
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
}

test "value-use scalar store preserves a live source exactly once before pointer staging" {
    var machine = MachineFunction.init("value-use-store-live-source", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addLive(&plan, "value");
    try addAtCurrent(&plan, "pointer");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "value", .{ .arg32 = .rcx });
    try selector_state.bindValueLoc(&selector, "pointer", .{ .spill64 = .slot4 });
    const value_vreg = selector.values.get("value").?.vreg;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const pointer = try transaction.register(preparedSourceRequest("pointer", .ptr, .gpr64, .pointer));
    const action = try transaction.register(preparedRequest(
        "value",
        .{ .int = 32 },
        .gpr32,
        .gpr32,
        .{ .store_scalar = .{ .pointer = pointer, .bits = 32 } },
    ));
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(action));
    try transaction.commit();

    var preservation_count: usize = 0;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .mov_arg_arg, .mov_arg64_arg, .spill_arg_rsp, .spill_arg64_rsp => preservation_count += 1,
        else => {},
    };
    try std.testing.expectEqual(@as(usize, 1), preservation_count);
    try std.testing.expectEqual(value_vreg, selector.values.get("value").?.vreg);
    try std.testing.expect(switch (selector.values.get("value").?.loc) {
        .arg32, .arg64, .scratch32, .scratch64 => |reg| reg != .rcx,
        else => true,
    });
}

test "value-use closed immediate and i64 stores retain accepted staging order" {
    {
        var machine = MachineFunction.init("value-use-store-immediate", .void);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "slot");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "slot", .{ .stack_scalar = .{
            .base_disp = 12,
            .bits = 8,
            .kind = .integer,
        } });

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const action = try transaction.register(preparedRequest(
            "slot",
            .ptr,
            .stack_object,
            .stack_object_address,
            .{ .store_immediate = .{ .value = 1, .bits = 1 } },
        ));
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(action));
        try transaction.commit();
        try std.testing.expectEqualSlices(machine_module.Instruction, &.{
            .{ .mov_imm_eax = 1 },
            .{ .store_al_stack_disp8 = 12 },
        }, machine.instructions.items);
    }

    {
        var machine = MachineFunction.init("value-use-store-i64", .void);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "pointer", "value" }) |name| try addAtCurrent(&plan, name);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 64;
        try selector_state.bindValueLoc(&selector, "pointer", .{ .spill64 = .slot0 });
        try selector_state.bindValueLoc(&selector, "value", .rax);

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const value = try transaction.register(preparedSourceRequest("value", .{ .int = 64 }, .gpr64, .gpr64));
        const action = try transaction.register(preparedRequest(
            "pointer",
            .ptr,
            .gpr64,
            .pointer,
            .{ .store_i64 = .{ .value = value } },
        ));
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(action));
        try transaction.commit();
        try std.testing.expectEqualSlices(machine_module.Instruction, &.{
            .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot0 } },
            .store_rax_rcx_ptr,
        }, machine.instructions.items);
    }
}

test "value-use store rollback covers scalar dependency and stack-pointer partial stages" {
    {
        var machine = MachineFunction.init("value-use-store-index-rollback", .void);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "value", "index", "addend", "pointer" }) |name| try addAtCurrent(&plan, name);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 128;
        try selector_state.bindValueLoc(&selector, "value", .{ .spill64 = .slot0 });
        selector.values.getPtr("value").?.vreg.class = .gpr32;
        try selector_state.bindValueLoc(&selector, "index", .{ .spill64 = .slot2 });
        try selector_state.bindValueLoc(&selector, "addend", .{ .spill64 = .slot4 });
        try selector_state.bindValueLoc(&selector, "pointer", .{ .stack_i32_ptr = .{
            .disp = 24,
            .index = .{ .reg = .rcx, .name = "index", .addend_name = "addend" },
        } });
        try selector_state.emitEflagsInstruction(&selector, .{ .cmp_eax_imm32 = 0 }, .definition);
        const saved_eflags = selector.eflags.snapshot();
        const saved_domain = selector.address_dependencies;
        const value_binding = selector.values.get("value").?;
        const pointer_binding = selector.values.get("pointer").?;

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const pointer = try transaction.register(preparedSourceRequest("pointer", .ptr, .stack_pointer, .pointer));
        const action = try transaction.register(preparedRequest(
            "value",
            .{ .int = 32 },
            .gpr32,
            .gpr32,
            .{ .store_scalar = .{ .pointer = pointer, .bits = 32 } },
        ));
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try std.testing.expectError(
            error.EflagsClobberedWhileLive,
            transaction.executePreparedAction(try transaction.preparedView(action)),
        );
        try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
        try std.testing.expectEqual(value_binding, selector.values.get("value").?);
        try std.testing.expectEqual(pointer_binding, selector.values.get("pointer").?);
        try std.testing.expect(selector.address_dependencies.eql(&saved_domain));
        try selector.eflags.validateSnapshot(saved_eflags);
    }

    {
        var machine = MachineFunction.init("value-use-store-stack-pointer-rollback", .void);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "source", "destination" }) |name| try addAtCurrent(&plan, name);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "source", .{ .stack_scalar = .{
            .base_disp = 8,
            .bits = 32,
            .kind = .fp,
        } });
        try selector_state.bindValueLoc(&selector, "destination", .{ .stack_scalar = .{
            .base_disp = 16,
            .bits = 64,
            .kind = .integer,
        } });
        try selector_state.emitEflagsInstruction(&selector, .{ .cmp_eax_imm32 = 0 }, .definition);
        const saved_eflags = selector.eflags.snapshot();

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const destination = try transaction.register(preparedSourceRequest(
            "destination",
            .ptr,
            .stack_object,
            .stack_object_address,
        ));
        const action = try transaction.register(preparedRequest(
            "source",
            .ptr,
            .stack_object,
            .stack_object_address,
            .{ .store_stack_pointer = .{ .destination = destination } },
        ));
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try std.testing.expectError(
            error.EflagsClobberedWhileLive,
            transaction.executePreparedAction(try transaction.preparedView(action)),
        );
        try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
        try selector.eflags.validateSnapshot(saved_eflags);
    }
}

test "value-use stack-pointer store commits closed source and destination descriptors" {
    var machine = MachineFunction.init("value-use-store-stack-pointer", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "source", "destination" }) |name| try addAtCurrent(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .{ .stack_scalar = .{
        .base_disp = 8,
        .bits = 32,
        .kind = .fp,
    } });
    try selector_state.bindValueLoc(&selector, "destination", .{ .stack_scalar = .{
        .base_disp = 16,
        .bits = 64,
        .kind = .integer,
    } });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const destination = try transaction.register(preparedSourceRequest(
        "destination",
        .ptr,
        .stack_object,
        .stack_object_address,
    ));
    const action = try transaction.register(preparedRequest(
        "source",
        .ptr,
        .stack_object,
        .stack_object_address,
        .{ .store_stack_pointer = .{ .destination = destination } },
    ));
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(action));
    try transaction.commit();
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_rsp_arg64 = .rcx },
        .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = 8 } },
        .{ .spill_arg64_rsp = .{ .frame_index = .slot4, .reg = .rcx } },
    }, machine.instructions.items);
}

test "value-use indexed scalar store emits value index addend and store in semantic order" {
    var machine = MachineFunction.init("value-use-store-indexed", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "value", "index", "addend", "pointer" }) |name| try addAtCurrent(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "value", .{ .arg32 = .rdi });
    try selector_state.bindValueLoc(&selector, "index", .{ .spill64 = .slot2 });
    try selector_state.bindValueLoc(&selector, "addend", .{ .arg64 = .r8 });
    try selector_state.bindValueLoc(&selector, "pointer", .{ .stack_i32_ptr = .{
        .disp = 24,
        .index = .{ .reg = .rcx, .name = "index", .addend_name = "addend" },
    } });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const pointer = try transaction.register(preparedSourceRequest("pointer", .ptr, .stack_pointer, .pointer));
    const action = try transaction.register(preparedRequest(
        "value",
        .{ .int = 32 },
        .gpr32,
        .gpr32,
        .{ .store_scalar = .{ .pointer = pointer, .bits = 32 } },
    ));
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(action));
    try transaction.commit();
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_arg_eax = .rdi },
        .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot2 } },
        .add_r8_rcx,
        .{ .store_eax_stack_rcx4_disp8 = 24 },
    }, machine.instructions.items);
}

test "value-use store writes participate in conflict and copy-cycle planning" {
    var machine = MachineFunction.init("value-use-store-planning", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "pointer", "value", "writer" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "pointer", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "value", .{ .arg64 = .rcx });
    selector.values.getPtr("value").?.vreg.class = .gpr32;
    try selector_state.bindValueLoc(&selector, "writer", .rax);

    var conflict = try Transaction.begin(&selector);
    defer conflict.deinit();
    const conflict_pointer = try conflict.register(preparedSourceRequest("pointer", .ptr, .gpr64, .pointer));
    _ = try conflict.register(preparedRequest(
        "value",
        .{ .int = 32 },
        .gpr32,
        .gpr32,
        .{ .store_scalar = .{ .pointer = conflict_pointer, .bits = 32 } },
    ));
    _ = try conflict.register(request("writer", .{ .int = 64 }, .gpr64, .gpr64, .rax));
    try std.testing.expectError(error.ValueUseConflictingDestination, conflict.seal());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try conflict.rollback();
    selector.values.getPtr("value").?.vreg.class = .gpr64;

    var cycle = try Transaction.begin(&selector);
    defer cycle.deinit();
    const cycle_value = try cycle.register(preparedSourceRequest("value", .{ .int = 64 }, .gpr64, .gpr64));
    _ = try cycle.register(preparedRequest(
        "pointer",
        .ptr,
        .gpr64,
        .pointer,
        .{ .store_i64 = .{ .value = cycle_value } },
    ));
    _ = try cycle.register(request("writer", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rdi }));
    try std.testing.expectError(error.ValueUseCopyCycleRequiresO4, cycle.seal());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "value-use transaction materializes GPR EAX RAX scalar spill and pointer views without rebinding sources" {
    var machine = MachineFunction.init("value-use-scalars", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "i32", "i64", "spill", "ptr", "eax-source", "rax-source" }) |name| try addLive(&plan, name);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "i32", .{ .arg32 = .rdi });
    try selector_state.bindValueLoc(&selector, "i64", .{ .arg64 = .rsi });
    try selector_state.bindValueLoc(&selector, "spill", .{ .spill64 = .slot0 });
    try selector_state.bindValueLoc(&selector, "ptr", .{ .arg64 = .rdx });
    try selector_state.bindValueLoc(&selector, "eax-source", .eax);
    try selector_state.bindValueLoc(&selector, "rax-source", .rax);
    const sources = [_]ValueLoc{
        selector.values.get("i32").?.loc,
        selector.values.get("i64").?.loc,
        selector.values.get("spill").?.loc,
        selector.values.get("ptr").?.loc,
        selector.values.get("eax-source").?.loc,
        selector.values.get("rax-source").?.loc,
    };
    const source_vregs = [_]selector_types.VirtualReg{
        selector.values.get("i32").?.vreg,
        selector.values.get("i64").?.vreg,
        selector.values.get("spill").?.vreg,
        selector.values.get("ptr").?.vreg,
        selector.values.get("eax-source").?.vreg,
        selector.values.get("rax-source").?.vreg,
    };

    var rax_transaction = try Transaction.begin(&selector);
    defer rax_transaction.deinit();
    _ = try rax_transaction.register(request("rax-source", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .r9 }));
    try rax_transaction.seal();
    try rax_transaction.prepare();
    try rax_transaction.materializeAll();
    try rax_transaction.commit();

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    _ = try transaction.register(request("i32", .{ .int = 32 }, .gpr32, .gpr32, .eax));
    _ = try transaction.register(request("i64", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .r8 }));
    _ = try transaction.register(request("spill", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .r9 }));
    _ = try transaction.register(request("ptr", .ptr, .gpr64, .pointer, .{ .gpr64 = .rdx }));
    _ = try transaction.register(request("eax-source", .{ .int = 32 }, .gpr32, .gpr32, .{ .gpr32 = .rcx }));
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.commit();

    inline for (&.{ "i32", "i64", "spill", "ptr", "eax-source", "rax-source" }, source_vregs) |name, vreg| {
        try std.testing.expectEqual(vreg, selector.values.get(name).?.vreg);
    }
    inline for (&.{ "i32", "i64", "spill", "ptr" }, sources[0..4]) |name, loc| try std.testing.expectEqual(loc, selector.values.get(name).?.loc);
    try std.testing.expect(selector.values.get("eax-source").?.loc == .spill64);
    try std.testing.expect(selector.values.get("rax-source").?.loc == .spill64);
    try std.testing.expect(machine.instructions.items.len >= 6);
}

test "value-use transaction accepts stack addresses and canonical indexed pointer dependencies" {
    var machine = MachineFunction.init("value-use-addresses", .ptr);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "index", "addend", "pointer", "scalar", "array" }) |name| try addLive(&plan, name);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "index", .{ .scratch64 = .r8 });
    try selector_state.bindValueLoc(&selector, "addend", .{ .scratch64 = .r9 });
    try selector_state.bindValueLoc(&selector, "pointer", .{ .stack_i32_ptr = .{
        .disp = 20,
        .index = .{ .reg = .r8, .name = "index", .addend_name = "addend" },
    } });
    try selector_state.bindValueLoc(&selector, "scalar", .{ .stack_scalar = .{ .base_disp = 32, .bits = 64 } });
    try selector_state.bindValueLoc(&selector, "array", .{ .stack_i32_array = .{ .base_disp = 48, .len = 4 } });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    _ = try transaction.register(request("pointer", .ptr, .stack_pointer, .pointer, .{ .gpr64 = .rdi }));
    _ = try transaction.register(request("scalar", .ptr, .stack_object, .stack_object_address, .{ .gpr64 = .rsi }));
    _ = try transaction.register(request("array", .ptr, .stack_object, .stack_object_address, .rax));
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.commit();

    try std.testing.expect(selector.address_dependencies.ownerNamed("pointer") != null);
    try std.testing.expect(selector.values.get("index") != null);
    try std.testing.expect(selector.values.get("addend") != null);
    try std.testing.expect(machine.instructions.items.len > 3);
}

test "value-use transaction supports register and spill table pointers and read-only pair limb orders" {
    var machine = MachineFunction.init("value-use-read-only", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "table-reg", "table-spill", "pair-a", "pair-spill" }) |name| try addLive(&plan, name);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "table-reg", .{ .readonly_table_ptr = .{
        .storage = .{ .reg = .rdi },
        .symbol = "@table",
        .shape = .i16_128,
    } });
    try selector_state.bindValueLoc(&selector, "table-spill", .{ .readonly_table_ptr = .{
        .storage = .{ .spill = .slot0 },
        .symbol = "@table",
        .shape = .i16_128,
    } });
    try selector_state.bindValueLoc(&selector, "pair-a", .{ .arg128 = .{ .lo = .rcx, .hi = .rdx } });
    try selector_state.bindValueLoc(&selector, "pair-spill", .{ .spill128 = .{ .lo = .slot1, .hi = .slot2 } });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    _ = try transaction.register(request("table-reg", .ptr, .stack_pointer, .pointer, .{ .gpr64 = .r8 }));
    _ = try transaction.register(request("table-spill", .ptr, .stack_pointer, .pointer, .rax));
    _ = try transaction.register(request("pair-a", .{ .int = 128 }, .gpr128, .pair_low_high, .{ .pair = .{ .lo = .rcx, .hi = .rdx } }));
    _ = try transaction.register(request("pair-spill", .{ .int = 128 }, .gpr128, .pair_high_low, .{ .pair = .{ .lo = .rsi, .hi = .r9 } }));
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.commit();

    try std.testing.expectEqual(ValueLoc{ .arg128 = .{ .lo = .rcx, .hi = .rdx } }, selector.values.get("pair-a").?.loc);
    try std.testing.expectEqual(ValueLoc{ .spill128 = .{ .lo = .slot1, .hi = .slot2 } }, selector.values.get("pair-spill").?.loc);
}

test "value-use transaction null pointers are typed direct materializations without durable state" {
    var machine = MachineFunction.init("value-use-null", .ptr);
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const accepted = Transaction.Request{
        .source = .null_value,
        .expected = expected(.ptr, .gpr64),
        .form = .pointer,
        .destination = .{ .gpr64 = .rdi },
    };
    _ = try transaction.register(accepted);
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.commit();
    try std.testing.expectEqual(@as(usize, 0), selector.values.count());
    try std.testing.expectEqual(@as(usize, 0), selector.address_dependencies.count());

    var rejected = try Transaction.begin(&selector);
    defer rejected.deinit();
    var untyped = accepted;
    untyped.expected.pointer_address_space = null;
    _ = try rejected.register(untyped);
    try std.testing.expectError(error.ValueUseUntypedNullPointer, rejected.seal());
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);

    var prepared = try Transaction.begin(&selector);
    defer prepared.deinit();
    var prepared_null = accepted;
    prepared_null.destination = .prepared_view;
    prepared_null.prepared_action = .{ .validate_shape = .{ .register_gpr64 = .rdi } };
    _ = try prepared.register(prepared_null);
    try std.testing.expectError(error.ValueUsePreparedViewUnsupported, prepared.seal());
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
}

test "value-use transaction phase capacity identity and coalescing rules fail before mutation" {
    var machine = MachineFunction.init("value-use-plan", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;

    var name_storage: [Transaction.max_requests][24]u8 = undefined;
    var names: [Transaction.max_requests][]const u8 = undefined;
    for (0..Transaction.max_requests) |index| {
        names[index] = try std.fmt.bufPrint(&name_storage[index], "request-{d}", .{index});
        try addLive(&plan, names[index]);
        try selector_state.bindValueLoc(&selector, names[index], .{ .spill64 = .{ .slot = @intCast(index) } });
    }
    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    var capacity_first: ?Transaction.RequestHandle = null;
    for (names, 0..) |name, index| {
        const handle = try transaction.register(request(name, .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = @enumFromInt(index % 6) }));
        if (capacity_first == null) capacity_first = handle;
    }
    try std.testing.expectError(error.ValueUseRequestCapacityExceeded, transaction.register(request(
        "overflow",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .rax,
    )));
    try std.testing.expect(!transaction.failedRequestIs(capacity_first.?));

    var phase = try Transaction.begin(&selector);
    defer phase.deinit();
    var transient_name = [_]u8{ 's', 't', 'a', 'b', 'l', 'e' };
    try addLive(&plan, "stable");
    try selector_state.bindValueLoc(&selector, "stable", .{ .arg64 = .rdi });
    const stable_request = request(&transient_name, .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rsi });
    const first = try phase.register(stable_request);
    try std.testing.expectEqual(first, try phase.register(stable_request));
    var distinct_destination = stable_request;
    distinct_destination.destination = .{ .gpr64 = .rdx };
    const second = try phase.register(distinct_destination);
    try std.testing.expect(first.index != second.index);
    var incompatible_type = stable_request;
    incompatible_type.expected = expected(.{ .int = 63 }, .gpr64);
    try std.testing.expectError(error.ValueUseIncompatibleDuplicate, phase.register(incompatible_type));
    var incompatible_form = stable_request;
    incompatible_form.form = .pointer;
    try std.testing.expectError(error.ValueUseIncompatibleDuplicate, phase.register(incompatible_form));
    @memset(&transient_name, 'x');
    try phase.seal();
    try std.testing.expectError(error.ValueUseLateRegistration, phase.register(stable_request));
    try std.testing.expect(!phase.failedRequestIs(first));

    var unsealed = try Transaction.begin(&selector);
    defer unsealed.deinit();
    try std.testing.expectError(error.ValueUsePrepareBeforeSeal, unsealed.prepare());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);

    var missing_action = try Transaction.begin(&selector);
    defer missing_action.deinit();
    _ = try missing_action.register(request("stable", .{ .int = 64 }, .gpr64, .gpr64, .prepared_view));
    try std.testing.expectError(error.ValueUsePreparedActionMissing, missing_action.seal());

    var unexpected_action = try Transaction.begin(&selector);
    defer unexpected_action.deinit();
    var fixed_with_action = request("stable", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rsi });
    fixed_with_action.prepared_action = .{ .emit_copy_to = .{ .gpr64 = .rsi } };
    _ = try unexpected_action.register(fixed_with_action);
    try std.testing.expectError(error.ValueUsePreparedActionUnexpected, unexpected_action.seal());
}

test "value-use transaction separates safe overlap from genuine copy cycles and conflicting destinations" {
    var machine = MachineFunction.init("value-use-overlap", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "left", "right", "third" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "left", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "right", .{ .arg64 = .rsi });
    try selector_state.bindValueLoc(&selector, "third", .{ .arg64 = .rdx });

    var safe = try Transaction.begin(&selector);
    defer safe.deinit();
    _ = try safe.register(request("left", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rsi }));
    _ = try safe.register(request("right", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rdx }));
    try safe.seal();
    try safe.prepare();
    try std.testing.expect(selector.values.get("right").?.loc == .spill64);
    try safe.rollback();

    var cycle = try Transaction.begin(&selector);
    defer cycle.deinit();
    _ = try cycle.register(request("left", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rsi }));
    _ = try cycle.register(request("right", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rdi }));
    try std.testing.expectError(error.ValueUseCopyCycleRequiresO4, cycle.seal());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);

    var conflict = try Transaction.begin(&selector);
    defer conflict.deinit();
    _ = try conflict.register(request("left", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .r9 }));
    _ = try conflict.register(request("third", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .r9 }));
    try std.testing.expectError(error.ValueUseConflictingDestination, conflict.seal());

    var action_conflict = try Transaction.begin(&selector);
    defer action_conflict.deinit();
    _ = try action_conflict.register(preparedRequest(
        "left",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .emit_copy_to = .{ .gpr64 = .r9 } },
    ));
    _ = try action_conflict.register(request("third", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .r9 }));
    try std.testing.expectError(error.ValueUseConflictingDestination, action_conflict.seal());
}

test "value-use transaction removes dead aliases and preserves live aliases exactly once before re-resolution" {
    var machine = MachineFunction.init("value-use-aliases", .ptr);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("dead", 0);
    try addLive(&plan, "live");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 2;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "dead", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "live", .{ .arg64 = .rdi });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    _ = try transaction.register(.{
        .source = .null_value,
        .expected = expected(.ptr, .gpr64),
        .form = .pointer,
        .destination = .{ .gpr64 = .rdi },
    });
    try transaction.seal();
    try transaction.prepare();
    try std.testing.expect(selector.values.get("dead") == null);
    try std.testing.expect(selector.values.get("live").?.loc == .spill64);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try transaction.materializeAll();
    try transaction.commit();
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
}

test "value-use transaction rollback restores instructions bindings spills counters flags and domains after partial emission" {
    var machine = MachineFunction.init("value-use-rollback", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "source", "late" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    selector.edge_label_count = 3;
    selector.stack_array_count = 4;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "late", .{ .arg64 = .rsi });
    try selector.eflags.apply(.definition);
    const source_binding = selector.values.get("source").?;
    const late_binding = selector.values.get("late").?;
    const saved_eflags = selector.eflags.snapshot();
    const saved_domain = selector.address_dependencies;
    const saved_next_vreg = selector.next_virtual_reg;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    _ = try transaction.register(request("source", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rsi }));
    _ = try transaction.register(request("late", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rdx }));
    try transaction.seal();
    try transaction.prepare();
    try selector_state.bindValueLoc(&selector, "late", .{ .xmm = .{ .reg = .xmm0, .bits = 64 } });
    try std.testing.expectError(error.ValueUseXmmUnsupported, transaction.materializeAll());

    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(source_binding, selector.values.get("source").?);
    try std.testing.expectEqual(late_binding, selector.values.get("late").?);
    try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
    try std.testing.expectEqual(saved_next_vreg, selector.next_virtual_reg);
    try std.testing.expectEqual(@as(usize, 3), selector.edge_label_count);
    try std.testing.expectEqual(@as(usize, 4), selector.stack_array_count);
    try std.testing.expectEqual(@as(usize, 0), transaction.requestCount());
    try std.testing.expectEqual(Transaction.RequestPhase.registering, transaction.phase());
    try std.testing.expectError(error.ValueUseTransactionClosed, transaction.register(request(
        "source",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .rax,
    )));
    try std.testing.expect(selector.address_dependencies.eql(&saved_domain));
    try selector.eflags.validateSnapshot(saved_eflags);
}

test "value-use transaction dependency and unsupported-view failures leave selector unmodified" {
    var machine = MachineFunction.init("value-use-rejections", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "xmm", "aggregate", "integer", "bad-address", "pointer", "missing-index" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "xmm", .{ .xmm = .{ .reg = .xmm0, .bits = 64 } });
    try selector_state.bindValueLoc(&selector, "aggregate", .{ .aggregate_sse = .{ .packed_f32x2 = null } });
    try selector_state.bindValueLoc(&selector, "integer", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "bad-address", .{ .stack_f32_pair_ptr = .{ .object_base_disp = 0, .disp = 4 } });
    const cases = [_]struct { request: Transaction.Request, expected_error: anyerror }{
        .{ .request = request("xmm", .{ .int = 64 }, .gpr64, .gpr64, .rax), .expected_error = error.ValueUseRegisterClassMismatch },
        .{ .request = request("aggregate", .{ .int = 64 }, .gpr64, .gpr64, .rax), .expected_error = error.ValueUseRegisterClassMismatch },
        .{ .request = request("integer", .{ .int = 32 }, .gpr64, .gpr64, .rax), .expected_error = error.ValueUseTypeMismatch },
        .{ .request = request("bad-address", .ptr, .stack_pointer, .pointer, .rax), .expected_error = error.ValueUseUnsupportedAddressForm },
        .{ .request = request("unresolved", .{ .int = 64 }, .gpr64, .gpr64, .rax), .expected_error = error.ValueUseUnresolvedSource },
    };
    for (cases) |case| {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        _ = try transaction.register(case.request);
        try std.testing.expectError(case.expected_error, transaction.seal());
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }

    try selector_state.bindValueLoc(&selector, "missing-index", .{ .scratch64 = .r8 });
    try selector_state.bindValueLoc(&selector, "pointer", .{ .stack_i32_ptr = .{
        .disp = 4,
        .index = .{ .reg = .r8, .name = "missing-index" },
    } });
    _ = selector.values.remove("missing-index");
    var missing_dependency = try Transaction.begin(&selector);
    defer missing_dependency.deinit();
    _ = try missing_dependency.register(request("pointer", .ptr, .stack_pointer, .pointer, .rax));
    try std.testing.expectError(error.AddressDependencyMissingBinding, missing_dependency.seal());

    var stack_arg = try Transaction.begin(&selector);
    defer stack_arg.deinit();
    _ = try stack_arg.register(.{
        .source = .null_value,
        .expected = expected(.ptr, .gpr64),
        .form = .stack_argument,
        .destination = .{ .stack_argument = 0 },
    });
    try std.testing.expectError(error.ValueUseStackArgumentUnsupported, stack_arg.seal());

    var new_pair = try Transaction.begin(&selector);
    defer new_pair.deinit();
    _ = try new_pair.register(.{
        .source = .null_value,
        .expected = expected(.ptr, .gpr64),
        .form = .new_pair_ownership,
        .destination = .new_pair,
    });
    try std.testing.expectError(error.ValueUseNewPairOwnershipUnsupported, new_pair.seal());
}

test "value-use transaction exposes every restricted prepared-view member and both pair orders" {
    var machine = MachineFunction.init("value-use-prepared-views", .ptr);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "reg", "spill", "stack", "index", "addend", "address", "table", "table-reg", "pair-lo", "pair-hi" }) |name|
        try addLive(&plan, name);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "reg", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "spill", .{ .spill64 = .slot0 });
    try selector_state.bindValueLoc(&selector, "stack", .{ .stack_scalar = .{ .base_disp = 16, .bits = 64 } });
    try selector_state.bindValueLoc(&selector, "index", .{ .scratch64 = .r8 });
    try selector_state.bindValueLoc(&selector, "addend", .{ .spill64 = .slot1 });
    try selector_state.bindValueLoc(&selector, "address", .{ .stack_i32_ptr = .{
        .disp = 24,
        .index = .{ .reg = .r8, .name = "index", .addend_name = "addend" },
    } });
    try selector_state.bindValueLoc(&selector, "table", .{ .readonly_table_ptr = .{
        .storage = .{ .spill = .slot2 },
        .symbol = "@prepared-table",
        .shape = .i16_128,
        .offset = 3,
    } });
    try selector_state.bindValueLoc(&selector, "table-reg", .{ .readonly_table_ptr = .{
        .storage = .{ .reg = .r9 },
        .symbol = "@prepared-table-reg",
        .shape = .i16_128,
    } });
    try selector_state.bindValueLoc(&selector, "pair-lo", .{ .arg128 = .{ .lo = .rcx, .hi = .rdx } });
    try selector_state.bindValueLoc(&selector, "pair-hi", .{ .spill128 = .{ .lo = .slot3, .hi = .slot4 } });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const handles = [_]Transaction.RequestHandle{
        try transaction.register(preparedRequest("reg", .{ .int = 64 }, .gpr64, .gpr64, .{ .validate_shape = .{ .register_gpr64 = .rdi } })),
        try transaction.register(preparedRequest("spill", .{ .int = 64 }, .gpr64, .gpr64, .{ .validate_shape = .{ .scalar_spill = .slot0 } })),
        try transaction.register(preparedRequest("stack", .ptr, .stack_object, .stack_object_address, .{ .validate_shape = .{ .stack_scalar = 16 } })),
        try transaction.register(preparedRequest("address", .ptr, .stack_pointer, .pointer, .{ .validate_shape = .{ .address_descriptor = .{ .has_index = true, .has_addend = true } } })),
        try transaction.register(preparedRequest("table", .ptr, .stack_pointer, .pointer, .{ .validate_shape = .{ .table_spill = .slot2 } })),
        try transaction.register(preparedRequest("table-reg", .ptr, .stack_pointer, .pointer, .{ .validate_shape = .{ .table_register = .r9 } })),
        try transaction.register(preparedRequest("pair-lo", .{ .int = 128 }, .gpr128, .pair_low_high, .{ .validate_shape = .{ .pair_register = .{ .lo = .rcx, .hi = .rdx } } })),
        try transaction.register(preparedRequest("pair-hi", .{ .int = 128 }, .gpr128, .pair_high_low, .{ .validate_shape = .{ .pair_spill = .{ .lo = .slot4, .hi = .slot3 } } })),
    };
    try transaction.seal();
    try std.testing.expectError(error.ValueUsePreparedViewUnavailable, transaction.preparedView(handles[0]));
    try transaction.prepare();
    try transaction.materializeAll();

    for (handles) |handle| {
        const lease = try transaction.preparedView(handle);
        try transaction.executePreparedAction(lease);
    }
    try transaction.commit();
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "value-use repeated sources separate destinations and preserve once before re-resolution" {
    var machine = MachineFunction.init("value-use-multi-destination", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "writer", "shared" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "writer", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "shared", .{ .arg64 = .rsi });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    _ = try transaction.register(request("writer", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rsi }));
    const first = try transaction.register(request("shared", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rdx }));
    const coalesced = try transaction.register(request("shared", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rdx }));
    const second = try transaction.register(request("shared", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .r8 }));
    try std.testing.expectEqual(first, coalesced);
    try std.testing.expect(first.index != second.index);
    try transaction.seal();
    try transaction.prepare();
    try std.testing.expect(selector.values.get("shared").?.loc == .spill64);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try transaction.materializeAll();
    try transaction.commit();
    try std.testing.expectEqual(@as(usize, 4), machine.instructions.items.len);
}

test "value-use planner reloads free r8 before preserving live rcx and does not rematerialize" {
    var machine = MachineFunction.init("value-use-early-gep-order", .ptr);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "base", "offset", "live-rcx", "result" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "base", .{ .spill64 = .slot5 });
    try selector_state.bindValueLoc(&selector, "offset", .rax);
    try selector_state.bindValueLoc(&selector, "live-rcx", .{ .arg64 = .rcx });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const offset = try transaction.register(preparedSourceRequest(
        "offset",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
    ));
    const action = try transaction.register(preparedRequest(
        "base",
        .ptr,
        .gpr64,
        .pointer,
        .{ .form_byte_address = .{
            .result = try actionIdentity("result"),
            .offset = .{ .request = offset },
        } },
    ));
    try transaction.seal();
    try transaction.prepare();
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(machine_module.Instruction{
        .reload_arg64_rsp = .{ .reg = .r8, .frame_index = .slot5 },
    }, machine.instructions.items[0]);
    try std.testing.expectEqual(machine_module.Instruction{
        .spill_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot0 },
    }, machine.instructions.items[1]);
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(action));
    try std.testing.expectEqual(@as(usize, 4), machine.instructions.items.len);
    try std.testing.expectEqual(machine_module.Instruction{ .mov_rax_to_arg = .rcx }, machine.instructions.items[2]);
    try std.testing.expectEqual(machine_module.Instruction.add_r8_rcx, machine.instructions.items[3]);
    var r8_reload_count: usize = 0;
    for (machine.instructions.items) |instruction| {
        if (instruction == .reload_arg64_rsp and instruction.reload_arg64_rsp.reg == .r8)
            r8_reload_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 1), r8_reload_count);
    try transaction.commit();
}

test "value-use planner leaves occupied early destination to ordinary preservation" {
    var machine = MachineFunction.init("value-use-early-occupied", .ptr);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "base", "offset", "occupant", "result" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "base", .{ .spill64 = .slot5 });
    try selector_state.bindValueLoc(&selector, "offset", .{ .arg64 = .rcx });
    try selector_state.bindValueLoc(&selector, "occupant", .{ .arg64 = .r8 });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const offset = try transaction.register(preparedSourceRequest("offset", .{ .int = 64 }, .gpr64, .gpr64));
    const action = try transaction.register(preparedRequest(
        "base",
        .ptr,
        .gpr64,
        .pointer,
        .{ .form_byte_address = .{
            .result = try actionIdentity("result"),
            .offset = .{ .request = offset },
        } },
    ));
    try transaction.seal();
    try transaction.prepare();
    for (machine.instructions.items) |instruction| {
        try std.testing.expect(instruction != .reload_arg64_rsp or instruction.reload_arg64_rsp.reg != .r8);
    }
    try std.testing.expect(selector.values.get("occupant").?.loc == .spill64);
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(action));
    var r8_reload_count: usize = 0;
    for (machine.instructions.items) |instruction| {
        if (instruction == .reload_arg64_rsp and instruction.reload_arg64_rsp.reg == .r8)
            r8_reload_count += 1;
    }
    try std.testing.expectEqual(@as(usize, 1), r8_reload_count);
    try transaction.rollback();
}

test "value-use planner handles source aliases and multiple safe early reloads" {
    var machine = MachineFunction.init("value-use-early-multiple", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "alias", "first", "second" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "alias", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "first", .{ .spill64 = .slot3 });
    try selector_state.bindValueLoc(&selector, "second", .{ .spill64 = .slot4 });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    _ = try transaction.register(request("alias", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rdi }));
    _ = try transaction.register(request("first", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rdx }));
    _ = try transaction.register(request("second", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .r8 }));
    try transaction.seal();
    try transaction.prepare();
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try transaction.materializeAll();
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(ValueLoc{ .arg64 = .rdi }, selector.values.get("alias").?.loc);
    try transaction.commit();
}

test "value-use early sequencing rollback covers early and preservation failure points with live EFLAGS" {
    var machine = MachineFunction.init("value-use-early-rollback", .ptr);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "base", "offset", "live-rcx", "dependency", "owner", "result" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "base", .{ .spill64 = .slot5 });
    try selector_state.bindValueLoc(&selector, "offset", .rax);
    try selector_state.bindValueLoc(&selector, "live-rcx", .{ .arg64 = .rcx });
    try selector_state.bindValueLoc(&selector, "dependency", .{ .arg64 = .r9 });
    try selector_state.bindValueLoc(&selector, "owner", .{ .stack_i32_ptr = .{
        .disp = 16,
        .index = .{ .reg = .r9, .name = "dependency" },
    } });
    try selector.eflags.apply(.definition);
    const base_binding = selector.values.get("base").?;
    const offset_binding = selector.values.get("offset").?;
    const live_rcx_binding = selector.values.get("live-rcx").?;
    const saved_eflags = selector.eflags.snapshot();
    const saved_domain = selector.address_dependencies;
    const saved_next_vreg = selector.next_virtual_reg;
    const saved_semantics_len = selector.eflags_semantics.items.len;

    var early_failure = try Transaction.begin(&selector);
    defer early_failure.deinit();
    const early_offset = try early_failure.register(preparedSourceRequest("offset", .{ .int = 64 }, .gpr64, .gpr64));
    _ = try early_failure.register(preparedRequest(
        "base",
        .ptr,
        .gpr64,
        .pointer,
        .{ .form_byte_address = .{
            .result = try actionIdentity("result"),
            .offset = .{ .request = early_offset },
        } },
    ));
    try early_failure.seal();
    try std.testing.expectError(error.UnsupportedCodegenValue, early_failure.prepare());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(base_binding, selector.values.get("base").?);
    try std.testing.expectEqual(offset_binding, selector.values.get("offset").?);
    try std.testing.expectEqual(live_rcx_binding, selector.values.get("live-rcx").?);
    try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
    try std.testing.expectEqual(saved_next_vreg, selector.next_virtual_reg);
    try std.testing.expect(selector.address_dependencies.eql(&saved_domain));
    try std.testing.expectEqual(saved_semantics_len, selector.eflags_semantics.items.len);
    try selector.eflags.validateSnapshot(saved_eflags);

    selector.stack_frame_bytes = 128;
    var post_preservation_failure = try Transaction.begin(&selector);
    defer post_preservation_failure.deinit();
    const preserved_offset = try post_preservation_failure.register(preparedSourceRequest("offset", .{ .int = 64 }, .gpr64, .gpr64));
    _ = try post_preservation_failure.register(preparedRequest(
        "base",
        .ptr,
        .gpr64,
        .pointer,
        .{ .form_byte_address = .{
            .result = try actionIdentity("result"),
            .offset = .{ .request = preserved_offset },
        } },
    ));
    try post_preservation_failure.seal();
    try post_preservation_failure.prepare();
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try selector.eflags.validateSnapshot(saved_eflags);
    selector.values.getPtr("offset").?.loc = .{ .xmm = .{ .reg = .xmm0, .bits = 64 } };
    try std.testing.expectError(error.ValueUseXmmUnsupported, post_preservation_failure.materializeAll());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(base_binding, selector.values.get("base").?);
    try std.testing.expectEqual(offset_binding, selector.values.get("offset").?);
    try std.testing.expectEqual(live_rcx_binding, selector.values.get("live-rcx").?);
    try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
    try std.testing.expectEqual(saved_next_vreg, selector.next_virtual_reg);
    try std.testing.expect(selector.address_dependencies.eql(&saved_domain));
    try std.testing.expectEqual(saved_semantics_len, selector.eflags_semantics.items.len);
    try selector.eflags.validateSnapshot(saved_eflags);
}

test "value-use semantic-role planner orders base before secondary for byte and scaled addresses" {
    {
        var machine = MachineFunction.init("value-use-byte-role-order", .ptr);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "base", "offset", "result" }) |name| try addLive(&plan, name);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 128;
        try selector_state.bindValueLoc(&selector, "base", .{ .spill64 = .slot5 });
        try selector_state.bindValueLoc(&selector, "offset", .{ .spill64 = .slot4 });

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        // Registration is deliberately secondary-first. Semantic action roles
        // must still produce base(r8), then offset(rcx).
        const offset = try transaction.register(preparedSourceRequest("offset", .{ .int = 64 }, .gpr64, .gpr64));
        _ = try transaction.register(preparedRequest(
            "base",
            .ptr,
            .gpr64,
            .pointer,
            .{ .form_byte_address = .{
                .result = try actionIdentity("result"),
                .offset = .{ .request = offset },
            } },
        ));
        try transaction.seal();
        try transaction.prepare();
        try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
        try std.testing.expectEqual(machine_module.Instruction{
            .reload_arg64_rsp = .{ .reg = .r8, .frame_index = .slot5 },
        }, machine.instructions.items[0]);
        try std.testing.expectEqual(machine_module.Instruction{
            .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot4 },
        }, machine.instructions.items[1]);
        try transaction.rollback();
    }

    {
        var machine = MachineFunction.init("value-use-scaled-role-order", .ptr);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "base", "index", "result" }) |name| try addLive(&plan, name);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 128;
        try selector_state.bindValueLoc(&selector, "base", .{ .spill64 = .slot5 });
        try selector_state.bindValueLoc(&selector, "index", .{ .spill64 = .slot4 });

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const index = try transaction.register(preparedSourceRequest("index", .{ .int = 64 }, .gpr64, .gpr64));
        _ = try transaction.register(preparedRequest(
            "base",
            .ptr,
            .gpr64,
            .pointer,
            .{ .form_scaled_address = .{
                .result = try actionIdentity("result"),
                .index = .{ .request = index },
                .scale = 4,
            } },
        ));
        try transaction.seal();
        try transaction.prepare();
        try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
        // Reversed physical destinations do not reverse semantic roles:
        // scaled base(rcx) still precedes index(r8).
        try std.testing.expectEqual(machine_module.Instruction{
            .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot5 },
        }, machine.instructions.items[0]);
        try std.testing.expectEqual(machine_module.Instruction{
            .reload_arg64_rsp = .{ .reg = .r8, .frame_index = .slot4 },
        }, machine.instructions.items[1]);
        try transaction.rollback();
    }
}

test "value-use semantic-role early scheduling is prefix closed" {
    {
        var machine = MachineFunction.init("value-use-noop-then-early", .ptr);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "array", "index", "result" }) |name| try addLive(&plan, name);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 128;
        try selector_state.bindValueLoc(&selector, "array", .{ .stack_i32_array = .{ .base_disp = 48, .len = 8 } });
        try selector_state.bindValueLoc(&selector, "index", .{ .spill64 = .slot4 });

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const index = try transaction.register(preparedSourceRequest("index", .{ .int = 64 }, .gpr64, .gpr64));
        _ = try transaction.register(preparedRequest(
            "array",
            .ptr,
            .stack_object,
            .stack_object_address,
            .{ .form_scaled_address = .{
                .result = try actionIdentity("result"),
                .index = .{ .request = index },
                .scale = 4,
                .expected_stack_array_len = 8,
            } },
        ));
        try transaction.seal();
        try transaction.prepare();
        try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
        try std.testing.expectEqual(machine_module.Instruction{
            .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot4 },
        }, machine.instructions.items[0]);
        try transaction.rollback();
    }

    {
        var machine = MachineFunction.init("value-use-ordinary-blocks-later-early", .ptr);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "base", "offset", "result" }) |name| try addLive(&plan, name);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 128;
        try selector_state.bindValueLoc(&selector, "base", .{ .arg64 = .rdi });
        try selector_state.bindValueLoc(&selector, "offset", .{ .spill64 = .slot4 });

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const offset = try transaction.register(preparedSourceRequest("offset", .{ .int = 64 }, .gpr64, .gpr64));
        const action = try transaction.register(preparedRequest(
            "base",
            .ptr,
            .gpr64,
            .pointer,
            .{ .form_byte_address = .{
                .result = try actionIdentity("result"),
                .offset = .{ .request = offset },
            } },
        ));
        try transaction.seal();
        try transaction.prepare();
        // The otherwise-eligible spill-backed secondary cannot jump ahead of
        // its ordinary in-register primary.
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(action));
        try std.testing.expectEqual(machine_module.Instruction{ .mov_arg64_arg = .{ .src = .rdi, .dst = .r8 } }, machine.instructions.items[0]);
        try std.testing.expectEqual(machine_module.Instruction{
            .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot4 },
        }, machine.instructions.items[1]);
        try transaction.rollback();
    }
}

test "value-use semantic ordering rejects shared role ownership before mutation" {
    var machine = MachineFunction.init("value-use-role-conflict", .ptr);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "first", "second", "offset" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "first", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "second", .{ .arg64 = .rsi });
    try selector_state.bindValueLoc(&selector, "offset", .{ .spill64 = .slot4 });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const offset = try transaction.register(preparedSourceRequest("offset", .{ .int = 64 }, .gpr64, .gpr64));
    inline for (&.{ "first", "second" }) |name| _ = try transaction.register(preparedRequest(
        name,
        .ptr,
        .gpr64,
        .pointer,
        .{ .form_byte_address = .{
            .result = try actionIdentity(name ++ "-result"),
            .offset = .{ .request = offset },
        } },
    ));
    try std.testing.expectError(error.ValueUseEarlyOrderingConflict, transaction.seal());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "value-use semantic-order rollback restores after first and second early copies" {
    {
        var machine = MachineFunction.init("value-use-role-rollback-first", .ptr);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "base", "index", "result" }) |name| try addLive(&plan, name);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 128;
        try selector_state.bindValueLoc(&selector, "base", .{ .spill64 = .slot5 });
        try selector_state.bindValueLoc(&selector, "index", .{ .spill64 = .slot4 });
        try selector.eflags.apply(.definition);
        const saved_eflags = selector.eflags.snapshot();
        const base_binding = selector.values.get("base").?;
        const index_binding = selector.values.get("index").?;

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const index = try transaction.register(preparedSourceRequest("index", .{ .int = 64 }, .gpr64, .gpr64));
        _ = try transaction.register(preparedRequest(
            "base",
            .ptr,
            .gpr64,
            .pointer,
            .{ .form_scaled_address = .{
                .result = try actionIdentity("result"),
                .index = .{ .request = index },
                .scale = 4,
            } },
        ));
        try transaction.seal();
        selector.values.getPtr("index").?.loc = .{ .xmm = .{ .reg = .xmm0, .bits = 64 } };
        try std.testing.expectError(error.ValueUseXmmUnsupported, transaction.prepare());
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(base_binding, selector.values.get("base").?);
        try std.testing.expectEqual(index_binding, selector.values.get("index").?);
        try selector.eflags.validateSnapshot(saved_eflags);
        try std.testing.expectEqual(@as(usize, 0), transaction.requestCount());
    }

    {
        var machine = MachineFunction.init("value-use-role-rollback-second", .ptr);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "base", "index", "writer", "live-rdx", "result" }) |name| try addLive(&plan, name);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "base", .{ .spill64 = .slot5 });
        try selector_state.bindValueLoc(&selector, "index", .{ .spill64 = .slot4 });
        try selector_state.bindValueLoc(&selector, "writer", .{ .arg64 = .rsi });
        try selector_state.bindValueLoc(&selector, "live-rdx", .{ .arg64 = .rdx });
        try selector.eflags.apply(.definition);
        const saved_eflags = selector.eflags.snapshot();
        const saved_next_vreg = selector.next_virtual_reg;
        const saved_domain = selector.address_dependencies;

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const index = try transaction.register(preparedSourceRequest("index", .{ .int = 64 }, .gpr64, .gpr64));
        _ = try transaction.register(preparedRequest(
            "base",
            .ptr,
            .gpr64,
            .pointer,
            .{ .form_scaled_address = .{
                .result = try actionIdentity("result"),
                .index = .{ .request = index },
                .scale = 4,
            } },
        ));
        _ = try transaction.register(request("writer", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rdx }));
        try transaction.seal();
        // Both ordered early reloads succeed; preserving the live rdx then
        // fails because this fixture intentionally has no stack frame.
        try std.testing.expectError(error.UnsupportedCodegenValue, transaction.prepare());
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
        try std.testing.expectEqual(saved_next_vreg, selector.next_virtual_reg);
        try std.testing.expect(selector.address_dependencies.eql(&saved_domain));
        try selector.eflags.validateSnapshot(saved_eflags);
        try std.testing.expectEqual(@as(usize, 0), transaction.requestCount());
    }
}

test "value-use prepared capabilities reject source relocation before production-path emission" {
    var machine = MachineFunction.init("value-use-view-phases", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addLive(&plan, "source");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg64 = .rdi });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const handle = try transaction.register(preparedRequest(
        "source",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .validate_shape = .{ .register_gpr64 = .rdi } },
    ));
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    var missing = handle;
    missing.index = 15;
    try std.testing.expectError(error.ValueUsePreparedViewMissing, transaction.preparedView(missing));

    var invalidated = try Transaction.begin(&selector);
    defer invalidated.deinit();
    const invalidated_handle = try invalidated.register(preparedRequest(
        "source",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .emit_copy_to = .rax },
    ));
    try invalidated.seal();
    try invalidated.prepare();
    try invalidated.materializeAll();
    const lease = try invalidated.preparedView(invalidated_handle);

    // Use the production binding authority to relocate the source after the
    // capability is acquired. Canonical-record validation must reject the old
    // capability before the closed action can append an instruction.
    try selector_state.bindValueLoc(&selector, "source", .{ .arg64 = .rsi });
    try std.testing.expectError(error.ValueUsePreparedViewStale, invalidated.executePreparedAction(lease));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(ValueLoc{ .arg64 = .rdi }, selector.values.get("source").?.loc);

    // The same typed action emits from the internally held view when the
    // canonical source remains unchanged. No location crosses the API.
    var internal_emit = try Transaction.begin(&selector);
    defer internal_emit.deinit();
    const emit_handle = try internal_emit.register(preparedRequest(
        "source",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .emit_copy_to = .rax },
    ));
    try internal_emit.seal();
    try internal_emit.prepare();
    try internal_emit.materializeAll();
    const emit_lease = try internal_emit.preparedView(emit_handle);
    try internal_emit.executePreparedAction(emit_lease);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expect(machine.instructions.items[0] == .mov_arg_rax);
    try std.testing.expectEqual(selector_types.ArgReg.rdi, machine.instructions.items[0].mov_arg_rax);
    try std.testing.expectError(error.ValueUsePreparedViewMissing, internal_emit.executePreparedAction(emit_lease));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);

    var foreign = try Transaction.begin(&selector);
    defer foreign.deinit();
    const foreign_handle = try foreign.register(preparedRequest(
        "source",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .validate_shape = .{ .register_gpr64 = .rdi } },
    ));
    try foreign.seal();
    try foreign.prepare();
    try foreign.materializeAll();
    try std.testing.expectError(error.ValueUsePreparedViewStale, foreign.preparedView(invalidated_handle));
    _ = foreign_handle;
}

test "value-use mixed fixed and prepared requests resolve views only after fixed preparation" {
    var machine = MachineFunction.init("value-use-mixed-views", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "fixed", "view" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "fixed", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "view", .{ .arg64 = .rsi });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    _ = try transaction.register(request("fixed", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rsi }));
    const view_handle = try transaction.register(preparedRequest(
        "view",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .validate_shape = .{ .scalar_spill = .slot0 } },
    ));
    try transaction.seal();
    try transaction.prepare();
    try std.testing.expect(selector.values.get("view").?.loc == .spill64);
    try transaction.materializeAll();
    const lease = try transaction.preparedView(view_handle);
    try transaction.executePreparedAction(lease);
    try transaction.commit();
}

test "value-use prepared actions revalidate type class and canonical dependencies on every execution" {
    var machine = MachineFunction.init("value-use-view-revalidation", .ptr);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "scalar", "index", "address" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "scalar", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "index", .{ .arg64 = .r8 });
    try selector_state.bindValueLoc(&selector, "address", .{ .stack_i32_ptr = .{
        .disp = 4,
        .index = .{ .reg = .r8, .name = "index" },
    } });

    const scalar_binding = selector.values.get("scalar").?;
    var type_transaction = try Transaction.begin(&selector);
    defer type_transaction.deinit();
    const scalar_handle = try type_transaction.register(preparedRequest(
        "scalar",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .validate_shape = .{ .register_gpr64 = .rdi } },
    ));
    try type_transaction.seal();
    try type_transaction.prepare();
    try type_transaction.materializeAll();
    const scalar_lease = try type_transaction.preparedView(scalar_handle);
    selector.values.getPtr("scalar").?.vreg.class = .gpr32;
    try std.testing.expectError(error.ValueUseRegisterClassMismatch, type_transaction.executePreparedAction(scalar_lease));
    try std.testing.expectEqual(scalar_binding, selector.values.get("scalar").?);

    var dependency_transaction = try Transaction.begin(&selector);
    defer dependency_transaction.deinit();
    const address_handle = try dependency_transaction.register(preparedRequest(
        "address",
        .ptr,
        .stack_pointer,
        .pointer,
        .{ .validate_shape = .{ .address_descriptor = .{ .has_index = true, .has_addend = false } } },
    ));
    try dependency_transaction.seal();
    try dependency_transaction.prepare();
    try dependency_transaction.materializeAll();
    const address_lease = try dependency_transaction.preparedView(address_handle);
    _ = selector.values.remove("index");
    try std.testing.expectError(error.AddressDependencyMissingBinding, dependency_transaction.executePreparedAction(address_lease));
    try std.testing.expect(selector.values.get("index") != null);
}

test "value-use rollback releases speculative owned labels after instructions and commit retains them" {
    var machine = MachineFunction.init("value-use-owned-labels", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addLive(&plan, "source");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg64 = .rdi });

    const retained = try selector_state.allocateEdgeLabel(&selector);
    const retained_pointer = retained.ptr;
    try std.testing.expectEqual(@as(usize, 1), machine.owned_labels.items.len);

    var rollback_transaction = try Transaction.begin(&selector);
    defer rollback_transaction.deinit();
    const rollback_handle = try rollback_transaction.register(preparedRequest(
        "source",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .validate_shape = .{ .register_gpr64 = .rdi } },
    ));
    try rollback_transaction.seal();
    try rollback_transaction.prepare();
    try rollback_transaction.materializeAll();
    const rollback_lease = try rollback_transaction.preparedView(rollback_handle);
    try rollback_transaction.executePreparedAction(rollback_lease);
    const first = try selector_state.allocateEdgeLabel(&selector);
    const second = try selector_state.allocateEdgeLabel(&selector);
    try machine.instructions.append(std.testing.allocator, .{ .label = first });
    try machine.instructions.append(std.testing.allocator, .{ .label = second });
    try rollback_transaction.rollback();
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(@as(usize, 1), machine.owned_labels.items.len);
    try std.testing.expectEqual(retained_pointer, machine.owned_labels.items[0].ptr);
    try std.testing.expectEqual(@as(usize, 1), selector.edge_label_count);

    var failure_transaction = try Transaction.begin(&selector);
    defer failure_transaction.deinit();
    const failure_handle = try failure_transaction.register(preparedRequest(
        "source",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .validate_shape = .{ .register_gpr64 = .rdi } },
    ));
    try failure_transaction.seal();
    try failure_transaction.prepare();
    try failure_transaction.materializeAll();
    const failure_lease = try failure_transaction.preparedView(failure_handle);
    const third = try selector_state.allocateEdgeLabel(&selector);
    const fourth = try selector_state.allocateEdgeLabel(&selector);
    try machine.instructions.append(std.testing.allocator, .{ .label = third });
    try machine.instructions.append(std.testing.allocator, .{ .label = fourth });
    _ = selector.values.remove("source");
    try std.testing.expectError(error.ValueUseUnresolvedSource, failure_transaction.executePreparedAction(failure_lease));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(@as(usize, 1), machine.owned_labels.items.len);
    try std.testing.expectEqual(retained_pointer, machine.owned_labels.items[0].ptr);
    try std.testing.expect(selector.values.get("source") != null);

    var commit_transaction = try Transaction.begin(&selector);
    defer commit_transaction.deinit();
    const commit_handle = try commit_transaction.register(preparedRequest(
        "source",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .validate_shape = .{ .register_gpr64 = .rdi } },
    ));
    try commit_transaction.seal();
    try commit_transaction.prepare();
    try commit_transaction.materializeAll();
    _ = try commit_transaction.preparedView(commit_handle);
    const committed = try selector_state.allocateEdgeLabel(&selector);
    try machine.instructions.append(std.testing.allocator, .{ .label = committed });
    try commit_transaction.commit();
    try std.testing.expectEqual(@as(usize, 2), machine.owned_labels.items.len);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(retained_pointer, machine.owned_labels.items[0].ptr);
}

test "value-use address actions derive stack-array descriptors and roll back durable bindings" {
    var machine = MachineFunction.init("value-use-stack-array-action", .ptr);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "array", "index", "derived" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "array", .{ .stack_i32_array = .{ .base_disp = 48, .len = 8 } });
    try selector_state.bindValueLoc(&selector, "index", .{ .arg64 = .rdi });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const index = try transaction.register(preparedSourceRequest(
        "index",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
    ));
    const address = try transaction.register(preparedRequest(
        "array",
        .ptr,
        .stack_object,
        .stack_object_address,
        .{ .form_scaled_address = .{
            .result = try actionIdentity("derived"),
            .index = .{ .request = index },
            .scale = 4,
        } },
    ));
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    const lease = try transaction.preparedView(address);
    try transaction.executePreparedAction(lease);

    const derived = selector.values.get("derived").?.loc.stack_i32_ptr;
    try std.testing.expectEqual(@as(u32, 48), derived.disp);
    try std.testing.expect(derived.index != null);
    try std.testing.expectEqual(selector_types.ArgReg.rcx, derived.index.?.reg);
    try std.testing.expect(std.mem.eql(u8, "index", derived.index.?.name));
    try std.testing.expect(selector.address_dependencies.ownerNamed("derived") != null);
    try std.testing.expectEqual(@as(usize, 2), machine.owned_labels.items.len);
    try std.testing.expect(machine.instructions.items.len != 0);

    try transaction.rollback();
    try std.testing.expect(selector.values.get("derived") == null);
    try std.testing.expect(selector.address_dependencies.ownerNamed("derived") == null);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);

    var constant = try Transaction.begin(&selector);
    defer constant.deinit();
    const constant_address = try constant.register(preparedRequest(
        "array",
        .ptr,
        .stack_object,
        .stack_object_address,
        .{ .form_scaled_address = .{
            .result = try actionIdentity("derived-constant"),
            .index = .{ .constant = 3 },
            .scale = 4,
        } },
    ));
    try constant.seal();
    try constant.prepare();
    try constant.materializeAll();
    try constant.executePreparedAction(try constant.preparedView(constant_address));
    try std.testing.expectEqual(
        @as(u32, 60),
        selector.values.get("derived-constant").?.loc.stack_i32_ptr.disp,
    );
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try constant.rollback();
}

test "value-use byte-address actions support constant and named offsets with atomic multi-source failure" {
    var machine = MachineFunction.init("value-use-byte-address-actions", .ptr);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "base", "offset", "constant-result", "named-result" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "base", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "offset", .{ .arg64 = .rsi });

    var constant = try Transaction.begin(&selector);
    defer constant.deinit();
    const constant_action = try constant.register(preparedRequest(
        "base",
        .ptr,
        .gpr64,
        .pointer,
        .{ .form_byte_address = .{
            .result = try actionIdentity("constant-result"),
            .offset = .{ .constant = 12 },
        } },
    ));
    try constant.seal();
    try constant.prepare();
    try constant.materializeAll();
    try constant.executePreparedAction(try constant.preparedView(constant_action));
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector.values.get("constant-result").?.loc);
    try constant.rollback();
    try std.testing.expect(selector.values.get("constant-result") == null);

    const initial_instruction_len = machine.instructions.items.len;
    const initial_labels_len = machine.owned_labels.items.len;
    try selector.eflags.apply(.definition);
    var named = try Transaction.begin(&selector);
    defer named.deinit();
    const offset = try named.register(preparedSourceRequest(
        "offset",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
    ));
    const named_action = try named.register(preparedRequest(
        "base",
        .ptr,
        .gpr64,
        .pointer,
        .{ .form_byte_address = .{
            .result = try actionIdentity("named-result"),
            .offset = .{ .request = offset },
        } },
    ));
    try named.seal();
    try named.prepare();
    try named.materializeAll();
    const named_lease = try named.preparedView(named_action);
    try std.testing.expectError(error.EflagsClobberedWhileLive, named.executePreparedAction(named_lease));
    try std.testing.expect(selector.values.get("named-result") == null);
    try std.testing.expectEqual(ValueLoc{ .arg64 = .rdi }, selector.values.get("base").?.loc);
    try std.testing.expectEqual(ValueLoc{ .arg64 = .rsi }, selector.values.get("offset").?.loc);
    try std.testing.expectEqual(initial_instruction_len, machine.instructions.items.len);
    try std.testing.expectEqual(initial_labels_len, machine.owned_labels.items.len);
}

test "value-use scaled-address action internally resolves both current homes" {
    var machine = MachineFunction.init("value-use-scaled-address-action", .ptr);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "base", "index", "scaled-result" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "base", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "index", .{ .spill64 = .slot0 });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const index = try transaction.register(preparedSourceRequest(
        "index",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
    ));
    const address = try transaction.register(preparedRequest(
        "base",
        .ptr,
        .gpr64,
        .pointer,
        .{ .form_scaled_address = .{
            .result = try actionIdentity("scaled-result"),
            .index = .{ .request = index },
            .scale = 4,
        } },
    ));
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(address));
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector.values.get("scaled-result").?.loc);
    try std.testing.expect(machine.instructions.items.len >= 4);
    try transaction.rollback();
    try std.testing.expect(selector.values.get("scaled-result") == null);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "value-use address actions include every physical destination in conflict and cycle planning" {
    var machine = MachineFunction.init("value-use-address-action-plan", .ptr);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "base", "offset", "other" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "base", .{ .arg64 = .rcx });
    try selector_state.bindValueLoc(&selector, "offset", .{ .arg64 = .r8 });
    try selector_state.bindValueLoc(&selector, "other", .{ .arg64 = .rdi });

    var cycle = try Transaction.begin(&selector);
    defer cycle.deinit();
    const cycle_offset = try cycle.register(preparedSourceRequest(
        "offset",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
    ));
    _ = try cycle.register(preparedRequest(
        "base",
        .ptr,
        .gpr64,
        .pointer,
        .{ .form_byte_address = .{
            .result = try actionIdentity("cycle-result"),
            .offset = .{ .request = cycle_offset },
        } },
    ));
    try std.testing.expectError(error.ValueUseCopyCycleRequiresO4, cycle.seal());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);

    var conflict = try Transaction.begin(&selector);
    defer conflict.deinit();
    _ = try conflict.register(preparedRequest(
        "base",
        .ptr,
        .gpr64,
        .pointer,
        .{ .form_byte_address = .{
            .result = try actionIdentity("conflict-result"),
            .offset = .{ .constant = 4 },
        } },
    ));
    _ = try conflict.register(request(
        "other",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .gpr64 = .rcx },
    ));
    try std.testing.expectError(error.ValueUseConflictingDestination, conflict.seal());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);

    var malformed = try Transaction.begin(&selector);
    defer malformed.deinit();
    try std.testing.expectError(error.ValueUseEmptyIdentity, malformed.register(preparedRequest(
        "base",
        .ptr,
        .gpr64,
        .pointer,
        .{ .form_byte_address = .{
            .result = .{},
            .offset = .{ .constant = 0 },
        } },
    )));
}

test "value-use readonly-table address action owns semantic symbol and committed result" {
    var machine = MachineFunction.init("value-use-table-address-action", .ptr);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "index", "table-result" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "index", .{ .arg64 = .rdi });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const action = try transaction.register(preparedRequest(
        "index",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .form_readonly_table_address = .{
            .result = try actionIdentity("table-result"),
            .symbol = try actionIdentity("@readonly-table"),
            .shape = .i16_128,
            .scale = 2,
        } },
    ));
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(action));
    const table = selector.values.get("table-result").?.loc.readonly_table_ptr;
    try std.testing.expectEqual(selector_types.ArgReg.rcx, table.storage.reg);
    try std.testing.expect(std.mem.eql(u8, "@readonly-table", table.symbol));
    try std.testing.expect(table.shape == .i16_128);
    try transaction.commit();
    try std.testing.expectEqual(@as(usize, 2), machine.owned_labels.items.len);
    try std.testing.expect(machine.instructions.items.len >= 4);
}

test "value-use f32-pair byte-address action preserves exact bounded descriptor arithmetic" {
    var machine = MachineFunction.init("value-use-f32-pair-byte-bounds", .ptr);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addLive(&plan, "base");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "base", .{ .stack_f32_pair_ptr = .{
        .object_base_disp = 40,
        .disp = 40,
    } });

    inline for ([_]struct { offset: i32, expected_disp: u32 }{
        .{ .offset = 0, .expected_disp = 40 },
        .{ .offset = 4, .expected_disp = 44 },
        .{ .offset = 8, .expected_disp = 48 },
    }) |case| {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const action = try transaction.register(preparedRequest(
            "base",
            .ptr,
            .stack_pointer,
            .stack_f32_pair_byte_address,
            .{ .form_byte_address = .{
                .result = try actionIdentity("bounded-result"),
                .offset = .{ .constant = case.offset },
            } },
        ));
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(action));
        const result = selector.values.get("bounded-result").?.loc.stack_f32_pair_ptr;
        try std.testing.expectEqual(@as(u32, 40), result.object_base_disp);
        try std.testing.expectEqual(case.expected_disp, result.disp);
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(@as(usize, 1), machine.owned_labels.items.len);
        try transaction.rollback();
        try std.testing.expect(selector.values.get("bounded-result") == null);
        try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
    }

    inline for ([_]i32{ -1, 9 }) |offset| {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const action = try transaction.register(preparedRequest(
            "base",
            .ptr,
            .stack_pointer,
            .stack_f32_pair_byte_address,
            .{ .form_byte_address = .{
                .result = try actionIdentity("rejected-result"),
                .offset = .{ .constant = offset },
            } },
        ));
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try std.testing.expectError(
            error.ValueUseAddressOffsetOutOfRange,
            transaction.executePreparedAction(try transaction.preparedView(action)),
        );
        try std.testing.expect(selector.values.get("rejected-result") == null);
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
    }

    try selector_state.bindValueLoc(&selector, "base", .{ .stack_f32_pair_ptr = .{
        .object_base_disp = std.math.maxInt(u32) - 4,
        .disp = std.math.maxInt(u32) - 4,
    } });
    var overflow = try Transaction.begin(&selector);
    defer overflow.deinit();
    const overflow_action = try overflow.register(preparedRequest(
        "base",
        .ptr,
        .stack_pointer,
        .stack_f32_pair_byte_address,
        .{ .form_byte_address = .{
            .result = try actionIdentity("overflow-result"),
            .offset = .{ .constant = 0 },
        } },
    ));
    try overflow.seal();
    try overflow.prepare();
    try overflow.materializeAll();
    try std.testing.expectError(
        error.ValueUseAddressOffsetOutOfRange,
        overflow.executePreparedAction(try overflow.preparedView(overflow_action)),
    );
    try std.testing.expect(selector.values.get("overflow-result") == null);
}

test "value-use f32-pair dynamic byte address materializes in accepted order and drops bounds" {
    var machine = MachineFunction.init("value-use-f32-pair-byte-dynamic", .ptr);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "base", "offset", "other" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "base", .{ .stack_f32_pair_ptr = .{
        .object_base_disp = 32,
        .disp = 36,
    } });
    try selector_state.bindValueLoc(&selector, "offset", .{ .arg64 = .rsi });
    try selector_state.bindValueLoc(&selector, "other", .{ .arg64 = .rdi });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const offset = try transaction.register(preparedSourceRequest(
        "offset",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
    ));
    const action = try transaction.register(preparedRequest(
        "base",
        .ptr,
        .stack_pointer,
        .stack_f32_pair_byte_address,
        .{ .form_byte_address = .{
            .result = try actionIdentity("dynamic-result"),
            .offset = .{ .request = offset },
        } },
    ));
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(action));
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector.values.get("dynamic-result").?.loc);
    try std.testing.expectEqual(@as(usize, 4), machine.instructions.items.len);
    try std.testing.expectEqual(machine_module.Instruction{ .mov_rsp_arg64 = .r8 }, machine.instructions.items[0]);
    try std.testing.expectEqual(machine_module.Instruction{ .add_arg64_imm32 = .{ .reg = .r8, .imm = 36 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(machine_module.Instruction{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rsi } }, machine.instructions.items[2]);
    try std.testing.expectEqual(machine_module.Instruction.add_r8_rcx, machine.instructions.items[3]);
    try transaction.rollback();
    try std.testing.expect(selector.values.get("dynamic-result") == null);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);

    var descriptor_only = try Transaction.begin(&selector);
    defer descriptor_only.deinit();
    _ = try descriptor_only.register(preparedRequest(
        "base",
        .ptr,
        .stack_pointer,
        .stack_f32_pair_byte_address,
        .{ .form_byte_address = .{
            .result = try actionIdentity("descriptor-only-result"),
            .offset = .{ .constant = 4 },
        } },
    ));
    _ = try descriptor_only.register(request("other", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rcx }));
    try descriptor_only.seal();
    try descriptor_only.rollback();

    var conflict = try Transaction.begin(&selector);
    defer conflict.deinit();
    const conflict_offset = try conflict.register(preparedSourceRequest(
        "offset",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
    ));
    _ = try conflict.register(preparedRequest(
        "base",
        .ptr,
        .stack_pointer,
        .stack_f32_pair_byte_address,
        .{ .form_byte_address = .{
            .result = try actionIdentity("conflict-result"),
            .offset = .{ .request = conflict_offset },
        } },
    ));
    _ = try conflict.register(request("other", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .r8 }));
    try std.testing.expectError(error.ValueUseConflictingDestination, conflict.seal());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "value-use f32-pair byte-address form is action-only" {
    var machine = MachineFunction.init("value-use-f32-pair-action-only", .ptr);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addLive(&plan, "base");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "base", .{ .stack_f32_pair_ptr = .{
        .object_base_disp = 0,
        .disp = 0,
    } });

    var copy = try Transaction.begin(&selector);
    defer copy.deinit();
    _ = try copy.register(preparedRequest(
        "base",
        .ptr,
        .stack_pointer,
        .stack_f32_pair_byte_address,
        .{ .emit_copy_to = .{ .gpr64 = .rcx } },
    ));
    try std.testing.expectError(error.ValueUsePreparedActionFormMismatch, copy.seal());

    var fixed = try Transaction.begin(&selector);
    defer fixed.deinit();
    _ = try fixed.register(request(
        "base",
        .ptr,
        .stack_pointer,
        .stack_f32_pair_byte_address,
        .{ .gpr64 = .rcx },
    ));
    try std.testing.expectError(error.ValueUseDestinationFormMismatch, fixed.seal());

    var source = try Transaction.begin(&selector);
    defer source.deinit();
    _ = try source.register(preparedSourceRequest(
        "base",
        .ptr,
        .stack_pointer,
        .stack_f32_pair_byte_address,
    ));
    try std.testing.expectError(error.ValueUsePreparedActionRequired, source.seal());

    var generic = try Transaction.begin(&selector);
    defer generic.deinit();
    _ = try generic.register(request("base", .ptr, .stack_pointer, .pointer, .{ .gpr64 = .rcx }));
    try std.testing.expectError(error.ValueUseUnsupportedAddressForm, generic.seal());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "value-use GEP actions preserve accepted descriptor preconditions" {
    var machine = MachineFunction.init("value-use-gep-action-preconditions", .ptr);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "array", "indexed", "index", "addend", "table" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "array", .{ .stack_i32_array = .{
        .base_disp = 64,
        .len = 4,
    } });
    try selector_state.bindValueLoc(&selector, "index", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "addend", .{ .arg64 = .rsi });
    try selector_state.bindValueLoc(&selector, "indexed", .{ .stack_i32_ptr = .{
        .disp = 64,
        .index = .{ .reg = .r8, .name = "index" },
    } });
    try selector_state.bindValueLoc(&selector, "table", .{ .readonly_table_ptr = .{
        .storage = .{ .reg = .rdx },
        .symbol = "@table",
        .shape = .f64_512_pairs,
    } });

    var array_len = try Transaction.begin(&selector);
    defer array_len.deinit();
    const array_action = try array_len.register(preparedRequest(
        "array",
        .ptr,
        .stack_object,
        .stack_object_address,
        .{ .form_scaled_address = .{
            .result = try actionIdentity("array-result"),
            .index = .{ .constant = 0 },
            .scale = 4,
            .expected_stack_array_len = 5,
        } },
    ));
    try array_len.seal();
    try array_len.prepare();
    try array_len.materializeAll();
    try std.testing.expectError(
        error.ValueUseAddressDescriptorLengthMismatch,
        array_len.executePreparedAction(try array_len.preparedView(array_action)),
    );
    try std.testing.expect(selector.values.get("array-result") == null);

    var index_reg = try Transaction.begin(&selector);
    defer index_reg.deinit();
    const addend = try index_reg.register(preparedSourceRequest(
        "addend",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
    ));
    const indexed_action = try index_reg.register(preparedRequest(
        "indexed",
        .ptr,
        .stack_pointer,
        .pointer,
        .{ .form_scaled_address = .{
            .result = try actionIdentity("indexed-result"),
            .index = .{ .request = addend },
            .scale = 4,
        } },
    ));
    try index_reg.seal();
    try index_reg.prepare();
    try index_reg.materializeAll();
    try std.testing.expectError(
        error.ValueUseUnsupportedAddressForm,
        index_reg.executePreparedAction(try index_reg.preparedView(indexed_action)),
    );
    try std.testing.expect(selector.values.get("indexed-result") == null);

    var table = try Transaction.begin(&selector);
    defer table.deinit();
    const table_action = try table.register(preparedRequest(
        "table",
        .ptr,
        .stack_pointer,
        .pointer,
        .{ .form_byte_address = .{
            .result = try actionIdentity("table-result"),
            .offset = .{ .constant = 8 },
        } },
    ));
    try table.seal();
    try table.prepare();
    try table.materializeAll();
    try table.executePreparedAction(try table.preparedView(table_action));
    try std.testing.expectEqual(@as(u8, 8), selector.values.get("table-result").?.loc.readonly_table_ptr.offset);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try table.rollback();

    var table_wrong_offset = try Transaction.begin(&selector);
    defer table_wrong_offset.deinit();
    const wrong_action = try table_wrong_offset.register(preparedRequest(
        "table",
        .ptr,
        .stack_pointer,
        .pointer,
        .{ .form_byte_address = .{
            .result = try actionIdentity("wrong-table-result"),
            .offset = .{ .constant = 0 },
        } },
    ));
    try table_wrong_offset.seal();
    try table_wrong_offset.prepare();
    try table_wrong_offset.materializeAll();
    try std.testing.expectError(
        error.ValueUseAddressOffsetOutOfRange,
        table_wrong_offset.executePreparedAction(try table_wrong_offset.preparedView(wrong_action)),
    );
    try std.testing.expect(selector.values.get("wrong-table-result") == null);
}

test "value-use inline memcpy action owns exact preservation staging and call clobber" {
    var machine = MachineFunction.init("value-use-inline-memcpy", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "dst", "src", "len" }) |name| try addAtCurrent(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "dst", .{ .arg64 = .r8 });
    try selector_state.bindValueLoc(&selector, "src", .{ .spill64 = .slot3 });
    try selector_state.bindValueLoc(&selector, "len", .rax);

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const requests = try registerMemcpyRequests(&transaction, .{ .named = "dst" }, .{ .named = "src" }, .{ .named = "len" });
    try prepareAndExecuteAction(&transaction, requests.destination);
    try std.testing.expect(!transaction.failedRequestIs(requests.destination));
    try std.testing.expect(!transaction.failedRequestIs(requests.source));
    try std.testing.expect(!transaction.failedRequestIs(requests.length));
    try transaction.commit();
    try std.testing.expect(!transaction.failedRequestIs(requests.destination));

    const expected_stream = [_]machine_module.Instruction{
        .{ .spill_rax_rsp = .slot0 },
        .{ .mov_arg64_arg = .{ .dst = .rdi, .src = .r8 } },
        .{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot3 } },
        .{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = .slot0 } },
        .memcpy_rdi_rsi_rdx_rax,
    };
    try std.testing.expectEqualSlices(machine_module.Instruction, &expected_stream, machine.instructions.items);
    try std.testing.expectEqual(@as(usize, 1), selector.eflags_semantics.items.len);
    try std.testing.expectEqual(selector_state.EflagsEffect.clobber, selector.eflags_semantics.items[0].effect);
}

test "value-use inline memcpy supports same-source destinations and audited pair low views" {
    var machine = MachineFunction.init("value-use-inline-memcpy-alias", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "pointer", "len" }) |name| try addAtCurrent(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "pointer", .{ .arg64 = .r8 });
    try selector_state.bindValueLoc(&selector, "len", .{ .scratch128 = selector_types.pair_a });
    selector.values.getPtr("len").?.vreg.class = .gpr128;
    selector.values.getPtr("len").?.vreg.bits = 128;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const action = try registerMemcpyAction(&transaction, .{ .named = "pointer" }, .{ .named = "pointer" }, .{ .named = "len" });
    try prepareAndExecuteAction(&transaction, action);
    try transaction.commit();

    const expected_stream = [_]machine_module.Instruction{
        .{ .mov_arg64_arg = .{ .dst = .rdi, .src = .r8 } },
        .{ .mov_arg64_arg = .{ .dst = .rsi, .src = .r8 } },
        .{ .mov_arg64_arg = .{ .dst = .rdx, .src = .rcx } },
        .memcpy_rdi_rsi_rdx_rax,
    };
    try std.testing.expectEqualSlices(machine_module.Instruction, &expected_stream, machine.instructions.items);
}

test "value-use inline memcpy rejects unsupported forms and genuine copy cycles before mutation" {
    var machine = MachineFunction.init("value-use-inline-memcpy-negative", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "dst", "src", "len" }) |name| try addAtCurrent(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "dst", .{ .arg64 = .rsi });
    try selector_state.bindValueLoc(&selector, "src", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "len", .{ .arg64 = .r8 });

    var cycle = try Transaction.begin(&selector);
    defer cycle.deinit();
    const cycle_requests = try registerMemcpyRequests(&cycle, .{ .named = "dst" }, .{ .named = "src" }, .{ .named = "len" });
    try std.testing.expectError(error.ValueUseCopyCycleRequiresO4, cycle.seal());
    try std.testing.expect(!cycle.failedRequestIs(cycle_requests.destination));
    try std.testing.expect(!cycle.failedRequestIs(cycle_requests.source));
    try std.testing.expect(!cycle.failedRequestIs(cycle_requests.length));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);

    var immediate = try Transaction.begin(&selector);
    defer immediate.deinit();
    _ = try registerMemcpyAction(&immediate, .null_value, .{ .named = "src" }, .{ .int = 4 });
    try std.testing.expectError(error.ValueUseUnsupportedSource, immediate.seal());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);

    selector.values.getPtr("len").?.vreg.bits = 32;
    var narrow = try Transaction.begin(&selector);
    defer narrow.deinit();
    _ = try registerMemcpyAction(&narrow, .{ .named = "dst" }, .{ .named = "src" }, .{ .named = "len" });
    try std.testing.expectError(error.ValueUseMemcpyLengthWidthMismatch, narrow.seal());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "value-use failure provenance distinguishes every memcpy request and foreign handles" {
    var machine = MachineFunction.init("value-use-memcpy-provenance", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "dst", "src", "len" }) |name| try addAtCurrent(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "dst", .{ .arg64 = .r8 });
    try selector_state.bindValueLoc(&selector, "src", .{ .arg64 = .r9 });
    try selector_state.bindValueLoc(&selector, "len", .rax);

    const cases = [_]struct {
        destination: ir.Value,
        source: ir.Value,
        length: ir.Value,
        failing: enum { destination, source, length },
        detail: []const u8,
    }{
        .{ .destination = .{ .named = "missing-dst" }, .source = .{ .named = "src" }, .length = .{ .named = "len" }, .failing = .destination, .detail = "composed-block-memcpy-dst" },
        .{ .destination = .{ .named = "dst" }, .source = .{ .named = "missing-src" }, .length = .{ .named = "len" }, .failing = .source, .detail = "composed-block-memcpy-src" },
        .{ .destination = .{ .named = "dst" }, .source = .{ .named = "src" }, .length = .{ .named = "missing-len" }, .failing = .length, .detail = "composed-block-memcpy-len" },
    };
    for (cases) |case| {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const requests = try registerMemcpyRequests(&transaction, case.destination, case.source, case.length);
        try std.testing.expectError(error.ValueUseUnresolvedSource, transaction.seal());
        try std.testing.expectEqualStrings(case.detail, inlineMemcpyValueUseDiagnosticForTest(&transaction, requests).?);
        try std.testing.expectEqual(case.failing == .destination, transaction.failedRequestIs(requests.destination));
        try std.testing.expectEqual(case.failing == .source, transaction.failedRequestIs(requests.source));
        try std.testing.expectEqual(case.failing == .length, transaction.failedRequestIs(requests.length));

        var foreign = try Transaction.begin(&selector);
        defer foreign.deinit();
        const foreign_requests = try registerMemcpyRequests(&foreign, .{ .named = "dst" }, .{ .named = "src" }, .{ .named = "len" });
        try std.testing.expect(!transaction.failedRequestIs(foreign_requests.destination));
        try std.testing.expect(!transaction.failedRequestIs(foreign_requests.source));
        try std.testing.expect(!transaction.failedRequestIs(foreign_requests.length));
    }
}

test "value-use action-registration provenance records first secondary exactly once" {
    var machine = MachineFunction.init("value-use-registration-provenance", .void);
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();

    const bad_source = try transaction.register(.{
        .source = .{ .named = "bad-source" },
        .expected = expected(.{ .int = 64 }, .gpr64),
        .form = .memcpy_pointer,
        .destination = .prepared_source,
    });
    const good_source = try transaction.register(.{
        .source = .{ .named = "good-source" },
        .expected = expected(.ptr, .gpr64),
        .form = .memcpy_pointer,
        .destination = .prepared_source,
    });
    const bad_length = try transaction.register(.{
        .source = .{ .named = "bad-length" },
        .expected = expected(.{ .int = 32 }, .gpr32),
        .form = .memcpy_length,
        .destination = .prepared_source,
    });
    try std.testing.expectError(error.ValueUsePreparedActionFormMismatch, transaction.register(.{
        .source = .{ .named = "dst-a" },
        .expected = expected(.ptr, .gpr64),
        .form = .memcpy_pointer,
        .destination = .prepared_view,
        .prepared_action = .{ .inline_memcpy = .{ .source = bad_source, .length = bad_length } },
    }));
    try std.testing.expect(transaction.failedRequestIs(bad_source));
    try std.testing.expect(!transaction.failedRequestIs(bad_length));

    try std.testing.expectError(error.ValueUsePreparedActionFormMismatch, transaction.register(.{
        .source = .{ .named = "dst-b" },
        .expected = expected(.ptr, .gpr64),
        .form = .memcpy_pointer,
        .destination = .prepared_view,
        .prepared_action = .{ .inline_memcpy = .{ .source = good_source, .length = bad_length } },
    }));
    try std.testing.expect(transaction.failedRequestIs(bad_source));
    try std.testing.expect(!transaction.failedRequestIs(bad_length));
}

test "value-use secondary materialization provenance is first and survives rollback" {
    var machine = MachineFunction.init("value-use-memcpy-secondary-provenance", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "dst", "src", "len" }) |name| try addAtCurrent(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "dst", .{ .arg64 = .r8 });
    try selector_state.bindValueLoc(&selector, "src", .{ .spill64 = .slot3 });
    try selector_state.bindValueLoc(&selector, "len", .rax);
    const saved_source = selector.values.get("src").?;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const requests = try registerMemcpyRequests(&transaction, .{ .named = "dst" }, .{ .named = "src" }, .{ .named = "len" });
    try transaction.seal();
    try transaction.prepare();
    selector.values.getPtr("src").?.loc = .{ .xmm = .{ .reg = .xmm0, .bits = 64 } };
    try std.testing.expectError(error.ValueUseMemcpyPointerHomeUnsupported, transaction.materializeAll());
    try std.testing.expect(transaction.failedRequestIs(requests.source));
    try std.testing.expect(!transaction.failedRequestIs(requests.destination));
    try std.testing.expect(!transaction.failedRequestIs(requests.length));
    try std.testing.expectEqual(saved_source, selector.values.get("src").?);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "value-use nested secondary failure does not get overwritten by its action owner" {
    var machine = MachineFunction.init("value-use-memcpy-first-provenance", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "dst", "src", "len" }) |name| try addAtCurrent(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "dst", .{ .arg64 = .r8 });
    try selector_state.bindValueLoc(&selector, "src", .{ .arg64 = .r9 });
    try selector_state.bindValueLoc(&selector, "len", .rax);
    const saved_source = selector.values.get("src").?;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const requests = try registerMemcpyRequests(&transaction, .{ .named = "dst" }, .{ .named = "src" }, .{ .named = "len" });
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    const lease = try transaction.preparedView(requests.destination);
    _ = selector.values.remove("src");
    try std.testing.expectError(error.ValueUseUnresolvedSource, transaction.executePreparedAction(lease));
    try std.testing.expect(transaction.failedRequestIs(requests.source));
    try std.testing.expect(!transaction.failedRequestIs(requests.destination));
    try std.testing.expect(!transaction.failedRequestIs(requests.length));
    try std.testing.expectEqual(saved_source, selector.values.get("src").?);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "value-use inline memcpy rolls back preservation every stage and call append" {
    inline for (std.meta.tags(Transaction.MemcpyTestFailure)) |failure| {
        var machine = MachineFunction.init("value-use-inline-memcpy-rollback", .void);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "dst", "src", "len" }) |name| try addAtCurrent(&plan, name);
        try addLive(&plan, "live-rcx");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 128;
        try selector_state.bindValueLoc(&selector, "dst", .{ .arg64 = .r8 });
        try selector_state.bindValueLoc(&selector, "src", .{ .spill64 = .slot3 });
        try selector_state.bindValueLoc(&selector, "len", .rax);
        try selector_state.bindValueLoc(&selector, "live-rcx", .{ .arg64 = .rcx });
        const dst_binding = selector.values.get("dst").?;
        const src_binding = selector.values.get("src").?;
        const len_binding = selector.values.get("len").?;
        const live_binding = selector.values.get("live-rcx").?;
        const saved_next_vreg = selector.next_virtual_reg;
        const saved_next_spill = selector.next_spill_slot;
        const saved_domain = selector.address_dependencies;
        const saved_eflags = selector.eflags.snapshot();

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const requests = try registerMemcpyRequests(&transaction, .{ .named = "dst" }, .{ .named = "src" }, .{ .named = "len" });
        try transaction.setMemcpyTestFailure(failure);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try std.testing.expectError(error.ValueUseMemcpyTestFailure, transaction.executePreparedAction(try transaction.preparedView(requests.destination)));
        try std.testing.expect(!transaction.failedRequestIs(requests.destination));
        try std.testing.expect(!transaction.failedRequestIs(requests.source));
        try std.testing.expect(!transaction.failedRequestIs(requests.length));
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(dst_binding, selector.values.get("dst").?);
        try std.testing.expectEqual(src_binding, selector.values.get("src").?);
        try std.testing.expectEqual(len_binding, selector.values.get("len").?);
        try std.testing.expectEqual(live_binding, selector.values.get("live-rcx").?);
        try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
        try std.testing.expectEqual(saved_next_vreg, selector.next_virtual_reg);
        try std.testing.expectEqual(saved_next_spill, selector.next_spill_slot);
        try std.testing.expect(selector.address_dependencies.eql(&saved_domain));
        try std.testing.expectEqual(@as(usize, 0), selector.eflags_semantics.items.len);
        try selector.eflags.validateSnapshot(saved_eflags);
    }
}

test "value-use inline memcpy preserves caller diagnostics and validates flags before mutation" {
    var machine = MachineFunction.init("value-use-inline-memcpy-diagnostic", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "dst", "src", "len" }) |name| try addAtCurrent(&plan, name);
    try addLive(&plan, "live-rcx");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "dst", .{ .arg64 = .r8 });
    try selector_state.bindValueLoc(&selector, "src", .{ .arg64 = .r9 });
    try selector_state.bindValueLoc(&selector, "len", .rax);
    try selector_state.bindValueLoc(&selector, "live-rcx", .{ .arg64 = .rcx });

    var diagnostic = try Transaction.begin(&selector);
    defer diagnostic.deinit();
    const diagnostic_requests = try registerMemcpyRequests(&diagnostic, .{ .named = "dst" }, .{ .named = "src" }, .{ .named = "len" });
    try diagnostic.seal();
    try diagnostic.prepare();
    try diagnostic.materializeAll();
    try std.testing.expectError(error.ValueUseActionDiagnostic, diagnostic.executePreparedAction(try diagnostic.preparedView(diagnostic_requests.destination)));
    try std.testing.expect(!diagnostic.failedRequestIs(diagnostic_requests.destination));
    try std.testing.expect(!diagnostic.failedRequestIs(diagnostic_requests.source));
    try std.testing.expect(!diagnostic.failedRequestIs(diagnostic_requests.length));
    switch (diagnostic.actionDiagnostic().?) {
        .no_spill_envelope => |detail| try std.testing.expectEqualStrings("composed-block-spill-frame", detail),
        else => return error.TestUnexpectedResult,
    }
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);

    selector.stack_frame_bytes = 128;
    try selector.eflags.apply(.definition);
    const saved_flags = selector.eflags.snapshot();
    var flags = try Transaction.begin(&selector);
    defer flags.deinit();
    const flags_requests = try registerMemcpyRequests(&flags, .{ .named = "dst" }, .{ .named = "src" }, .{ .named = "len" });
    try flags.seal();
    try flags.prepare();
    try flags.materializeAll();
    try std.testing.expectError(error.EflagsClobberedWhileLive, flags.executePreparedAction(try flags.preparedView(flags_requests.destination)));
    try std.testing.expect(!flags.failedRequestIs(flags_requests.destination));
    try std.testing.expect(!flags.failedRequestIs(flags_requests.source));
    try std.testing.expect(!flags.failedRequestIs(flags_requests.length));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
    try std.testing.expectEqual(@as(usize, 0), selector.eflags_semantics.items.len);
    try selector.eflags.validateSnapshot(saved_flags);
}

test "value-use subordinate accumulator lifecycle has one outer commit authority" {
    var machine = MachineFunction.init("value-use-subordinate-accumulator", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "operand");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "operand", .{ .arg32 = .rdi });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    try std.testing.expectError(
        error.ValueUseAccumulatorSessionRequiresSealedPlan,
        transaction.beginAccumulatorSession(),
    );
    _ = try transaction.register(request(
        "operand",
        .{ .int = 32 },
        .gpr32,
        .gpr32,
        .{ .gpr32 = .r8 },
    ));
    try transaction.seal();
    const accumulator = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    try std.testing.expect((try transaction.prepareAccumulator(
        accumulator,
        .preserve,
        .spill_live,
    )) == null);
    try machine.instructions.append(std.testing.allocator, .{ .mov_arg_eax = .r8 });
    try transaction.defineAccumulatorResult(accumulator, "result", .zeroExtending(32));

    try std.testing.expectError(
        error.ValueUseAccumulatorIndependentCommit,
        transaction.commitAccumulatorSession(accumulator),
    );
    try std.testing.expectError(error.ValueUseAccumulatorResultNotFinalized, transaction.commit());
    try transaction.finalizeAccumulatorResult(accumulator);
    try transaction.commit();

    try std.testing.expectEqual(ValueLoc.eax, selector.values.get("result").?.loc);
    try std.testing.expectEqual(@as(u16, 64), selector.accumulator_domain.defined_bits);
    try std.testing.expectEqual(@as(usize, 1), Transaction.address_domain_snapshot_copies);
    try std.testing.expectEqual(
        @as(usize, 0),
        selector_state.AccumulatorDefinitionSession.address_domain_snapshot_copies,
    );
    try std.testing.expectEqual(@as(usize, 0), selector_state.AccumulatorDefinitionSession.snapshot_copies);
    try std.testing.expectEqual(
        @sizeOf(selector_state.AddressDependencies),
        Transaction.address_domain_snapshot_bytes,
    );
}

test "value-use outer rollback restores combined state after accumulator finalization exactly once" {
    var machine = MachineFunction.init("value-use-combined-rollback", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "operand", "index", "pointer" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    selector.next_spill_slot = 1;
    selector.edge_label_count = 4;
    selector.stack_array_count = 3;
    try selector_state.bindValueLoc(&selector, "operand", .{ .arg32 = .rdi });
    try selector_state.bindValueLoc(&selector, "index", .{ .scratch64 = .r9 });
    try selector_state.bindValueLoc(&selector, "pointer", .{ .stack_i32_ptr = .{
        .disp = 8,
        .index = .{ .reg = .r9, .name = "index" },
    } });
    try selector.spill_slots.put("seed-spill", .{ .base = 0, .slots = 1 });
    try selector.phi_destinations.put("seed-phi", .{ .arg32 = .rsi });
    try machine.instructions.append(std.testing.allocator, .{ .mov_imm_eax = 17 });
    try selector.eflags.apply(.definition);
    const retained_label = try selector_state.allocateEdgeLabel(&selector);
    const retained_pointer = retained_label.ptr;

    const operand_binding = selector.values.get("operand").?;
    const index_binding = selector.values.get("index").?;
    const pointer_binding = selector.values.get("pointer").?;
    const saved_dependencies = selector.address_dependencies;
    const saved_eflags = selector.eflags.snapshot();
    const saved_next_vreg = selector.next_virtual_reg;
    const saved_next_spill = selector.next_spill_slot;
    const saved_edge_labels = selector.edge_label_count;
    const saved_stack_arrays = selector.stack_array_count;
    const saved_semantics = selector.eflags_semantics.items.len;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    _ = try transaction.register(request(
        "operand",
        .{ .int = 32 },
        .gpr32,
        .gpr32,
        .{ .gpr32 = .r8 },
    ));
    try transaction.seal();
    const accumulator = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    try std.testing.expect((try transaction.prepareAccumulator(
        accumulator,
        .preserve,
        .spill_live,
    )) == null);
    try machine.instructions.append(std.testing.allocator, .{ .mov_arg_eax = .r8 });
    try transaction.defineAccumulatorResult(accumulator, "result", .zeroExtending(32));
    try transaction.finalizeAccumulatorResult(accumulator);

    _ = selector_state.removeValueBinding(&selector, "pointer");
    try selector_state.bindValueLoc(&selector, "speculative", .{ .scratch64 = .rcx });
    try selector.spill_slots.put("speculative-spill", .{ .base = 2, .slots = 1 });
    try selector.phi_destinations.put("speculative-phi", .rax);
    selector.stack_array_count += 5;
    const speculative_a = try selector_state.allocateEdgeLabel(&selector);
    const speculative_b = try selector_state.allocateEdgeLabel(&selector);
    try machine.instructions.append(std.testing.allocator, .{ .label = speculative_a });
    try machine.instructions.append(std.testing.allocator, .{ .label = speculative_b });

    try transaction.rollback();
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{.{ .mov_imm_eax = 17 }}, machine.instructions.items);
    try std.testing.expectEqual(operand_binding, selector.values.get("operand").?);
    try std.testing.expectEqual(index_binding, selector.values.get("index").?);
    try std.testing.expectEqual(pointer_binding, selector.values.get("pointer").?);
    try std.testing.expect(selector.values.get("result") == null);
    try std.testing.expect(selector.values.get("speculative") == null);
    try std.testing.expectEqual(@as(usize, 1), selector.spill_slots.count());
    try std.testing.expect(selector.spill_slots.get("seed-spill") != null);
    try std.testing.expectEqual(@as(usize, 1), selector.phi_destinations.count());
    try std.testing.expectEqual(ValueLoc{ .arg32 = .rsi }, selector.phi_destinations.get("seed-phi").?);
    try std.testing.expectEqual(saved_next_vreg, selector.next_virtual_reg);
    try std.testing.expectEqual(saved_next_spill, selector.next_spill_slot);
    try std.testing.expectEqual(saved_edge_labels, selector.edge_label_count);
    try std.testing.expectEqual(saved_stack_arrays, selector.stack_array_count);
    try std.testing.expect(selector.address_dependencies.eql(&saved_dependencies));
    try selector.eflags.validateSnapshot(saved_eflags);
    try std.testing.expectEqual(saved_semantics, selector.eflags_semantics.items.len);
    try std.testing.expectEqual(@as(usize, 1), machine.owned_labels.items.len);
    try std.testing.expectEqual(retained_pointer, machine.owned_labels.items[0].ptr);
    try std.testing.expectError(error.ValueUseTransactionClosed, transaction.rollback());
}

test "value-use request provenance survives subordinate accumulator activity and rollback" {
    var machine = MachineFunction.init("value-use-composed-provenance", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "operand");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "operand", .{ .arg64 = .rdi });
    const saved_operand = selector.values.get("operand").?;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const operand = try transaction.register(preparedRequest(
        "operand",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .validate_shape = .{ .register_gpr64 = .rdi } },
    ));
    try transaction.seal();
    const accumulator = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    const lease = try transaction.preparedView(operand);
    try std.testing.expect((try transaction.prepareAccumulator(
        accumulator,
        .preserve,
        .spill_live,
    )) == null);
    try transaction.defineAccumulatorResult(accumulator, "result", .zeroExtending(32));
    _ = selector.values.remove("operand");

    try std.testing.expectError(error.ValueUseUnresolvedSource, transaction.executePreparedAction(lease));
    try std.testing.expect(transaction.failedRequestIs(operand));
    try std.testing.expectEqual(saved_operand, selector.values.get("operand").?);
    try std.testing.expect(selector.values.get("result") == null);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "standalone accumulator transaction preserves its original lifecycle and stream" {
    var machine = MachineFunction.init("standalone-accumulator-unchanged", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "source", .{ .arg32 = .rdi });

    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(&selector);
    defer transaction.deinit();
    try std.testing.expect((try transaction.prepare(.preserve, .spill_live)) == null);
    try transaction.materialize(.{ .named = "source" }, .zeroExtending(32));
    try transaction.define("result", .zeroExtending(32));
    try transaction.commit();

    try std.testing.expectEqualSlices(machine_module.Instruction, &.{.{ .mov_arg_eax = .rdi }}, machine.instructions.items);
    try std.testing.expectEqual(ValueLoc.eax, selector.values.get("result").?.loc);
    try std.testing.expectError(error.AccumulatorTransactionClosed, transaction.commit());
    try std.testing.expectError(
        error.AccumulatorCallMustClobberEflags,
        transaction.prepareCallBeforeArguments(.preserve),
    );
    try std.testing.expectError(
        error.AccumulatorCallPreparationOrder,
        transaction.finishCallPreparationAfterArguments(),
    );
}

fn loadActionRequest(
    name: []const u8,
    action: Transaction.PreparedAction,
) Transaction.Request {
    return preparedRequest(
        name,
        .ptr,
        .stack_pointer,
        .load_address,
        action,
    );
}

fn accumulatorLoadDefinition(bits: u16) selector_state.AccumulatorDefinition {
    return switch (bits) {
        8, 16, 32 => .zeroExtending(bits),
        56 => .zeroExtendedRax(56),
        64 => .fullRax(),
        else => unreachable,
    };
}

fn loadDiagnosticForTest(err: Transaction.LoadRequestError) []const u8 {
    return switch (err) {
        error.ValueUseLoadOrdinaryStackWidth => "composed-block-load-stack-width",
        error.ValueUseLoadOrdinaryStackArrayWidth => "composed-block-load-stack-array-width",
        error.ValueUseLoadOrdinaryPointerWidth => "composed-block-load-ptr-width",
        error.ValueUseLoadOrdinaryPointerRejected => "composed-block-load-ptr",
        error.ValueUseLoadReadonlyPointerProvenance => "composed-block-load-readonly-param-provenance",
        error.ValueUseLoadReadonlyPointerSpill => "composed-block-load-readonly-param-spill",
        error.ValueUseLoadReadonlyPointerAlias => "composed-block-load-readonly-param-alias",
        error.ValueUseLoadReadonlyWidth => "composed-block-load-width",
        error.ValueUseLoadReadonlyPairUnavailable => "composed-block-load-readonly-param-pair",
        error.ValueUseLoadReadonlyTableOffset => "composed-block-load-readonly-table-offset",
        error.ValueUseLoadReadonlyTableType => "composed-block-load-readonly-table-type",
        error.ValueUseLoadReadonlyTableSpill => "composed-block-load-readonly-table-spill",
    };
}

test "value-use load diagnostic matrix retains all twenty-eight audited rows" {
    const rows = [_][]const u8{
        "ordinary-barrier",
        "ordinary-readonly-table-dispatch",
        "ordinary-readonly-pointer-dispatch",
        "ordinary-fp-dispatch",
        "ordinary-unsupported-width",
        "ordinary-stack-i8",
        "ordinary-stack-i64",
        "ordinary-stack-i128-alias",
        "ordinary-stack-i32-pointer",
        "ordinary-stack-i32-pointer-indexed",
        "ordinary-stack-i32-array",
        "ordinary-gpr-pointer",
        "ordinary-spill-pointer",
        "ordinary-i16-rejections",
        "ordinary-rejected-homes",
        "readonly-address-provenance",
        "readonly-scalar-direct",
        "readonly-scalar-spill",
        "readonly-unsupported-width",
        "readonly-i56-direct",
        "readonly-i56-spill",
        "readonly-i64",
        "readonly-i96-pair",
        "readonly-i128-pair",
        "table-shape-offset-address-space",
        "table-i16-register",
        "table-i16-spill",
        "table-double-o3",
    };
    try std.testing.expectEqual(@as(usize, 28), rows.len);
    for (rows, 0..) |row, index| {
        try std.testing.expect(row.len != 0);
        for (rows[0..index]) |prior| try std.testing.expect(!std.mem.eql(u8, row, prior));
    }
}

test "value-use ordinary load errors preserve source-home classification and provenance" {
    const Case = struct {
        name: []const u8,
        loc: ValueLoc,
        expected_error: Transaction.LoadRequestError,
        diagnostic: []const u8,
    };
    const cases = [_]Case{
        .{
            .name = "stack-scalar",
            .loc = .{ .stack_scalar = .{ .base_disp = 8, .bits = 8 } },
            .expected_error = error.ValueUseLoadOrdinaryStackWidth,
            .diagnostic = "composed-block-load-stack-width",
        },
        .{
            .name = "stack-i128",
            .loc = .{ .stack128 = 16 },
            .expected_error = error.ValueUseLoadOrdinaryStackWidth,
            .diagnostic = "composed-block-load-stack-width",
        },
        .{
            .name = "stack-array",
            .loc = .{ .stack_i32_array = .{ .base_disp = 24, .len = 4 } },
            .expected_error = error.ValueUseLoadOrdinaryStackArrayWidth,
            .diagnostic = "composed-block-load-stack-array-width",
        },
        .{
            .name = "stack-pointer",
            .loc = .{ .stack_i32_ptr = .{ .disp = 32 } },
            .expected_error = error.ValueUseLoadOrdinaryStackArrayWidth,
            .diagnostic = "composed-block-load-stack-array-width",
        },
        .{
            .name = "gpr-pointer",
            .loc = .{ .arg64 = .rdi },
            .expected_error = error.ValueUseLoadOrdinaryPointerWidth,
            .diagnostic = "composed-block-load-ptr-width",
        },
        .{
            .name = "rejected-home",
            .loc = .{ .arg32 = .rdi },
            .expected_error = error.ValueUseLoadOrdinaryPointerRejected,
            .diagnostic = "composed-block-load-ptr",
        },
    };

    for (cases) |case| {
        var machine = MachineFunction.init(case.name, .{ .int = 16 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "pointer");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "pointer", case.loc);

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const action = try transaction.register(loadActionRequest(
            "pointer",
            .{ .load_scalar = .{ .kind = .ordinary, .bits = 16 } },
        ));
        try std.testing.expectError(case.expected_error, transaction.seal());
        try std.testing.expect(transaction.failedRequestIs(action));
        try std.testing.expectEqualStrings(case.diagnostic, loadDiagnosticForTest(case.expected_error));
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
}

test "value-use load resolution precedes invalid-width classification" {
    var machine = MachineFunction.init("value-use-load-resolution-precedence", .{ .int = 24 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "missing");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;

    var missing = try Transaction.begin(&selector);
    defer missing.deinit();
    const missing_action = try missing.register(loadActionRequest(
        "missing",
        .{ .load_scalar = .{ .kind = .ordinary, .bits = 24 } },
    ));
    try std.testing.expectError(error.ValueUseUnresolvedSource, missing.seal());
    try std.testing.expect(missing.failedRequestIs(missing_action));

    try selector_state.bindValueLoc(&selector, "missing", .{ .arg64 = .rdi });
    var resolved = try Transaction.begin(&selector);
    defer resolved.deinit();
    const resolved_action = try resolved.register(loadActionRequest(
        "missing",
        .{ .load_scalar = .{ .kind = .ordinary, .bits = 24 } },
    ));
    try std.testing.expectError(error.ValueUseLoadOrdinaryPointerWidth, resolved.seal());
    try std.testing.expect(resolved.failedRequestIs(resolved_action));
}

test "value-use dormant scalar load actions consume accepted source homes internally" {
    const Case = struct {
        name: []const u8,
        loc: ValueLoc,
        action: Transaction.ScalarLoadAction,
        instructions: []const machine_module.Instruction,
    };
    const cases = [_]Case{
        .{
            .name = "stack-u8",
            .loc = .{ .stack_scalar = .{ .base_disp = 24, .bits = 8 } },
            .action = .{ .kind = .ordinary, .bits = 8 },
            .instructions = &.{.{ .load_stack_disp8_u8_eax = 24 }},
        },
        .{
            .name = "stack-u64",
            .loc = .{ .stack_scalar = .{ .base_disp = 320, .bits = 64 } },
            .action = .{ .kind = .ordinary, .bits = 64 },
            .instructions = &.{.{ .load_stack_disp32_rax = 320 }},
        },
        .{
            .name = "pointer-register",
            .loc = .{ .arg64 = .rdi },
            .action = .{ .kind = .ordinary, .bits = 32 },
            .instructions = &.{.{ .load_arg_ptr_eax = .rdi }},
        },
        .{
            .name = "pointer-spill",
            .loc = .{ .spill64 = .slot3 },
            .action = .{ .kind = .ordinary, .bits = 32 },
            .instructions = &.{
                .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot3 } },
                .{ .load_arg_ptr_eax = .rcx },
            },
        },
        .{
            .name = "readonly-u16",
            .loc = .{ .scratch64 = .rsi },
            .action = .{ .kind = .readonly_pointer, .bits = 16 },
            .instructions = &.{.{ .load_arg_ptr_disp8_u16_eax = .{ .reg = .rsi, .offset = 0 } }},
        },
        .{
            .name = "readonly-u64-spill",
            .loc = .{ .spill64 = .slot2 },
            .action = .{ .kind = .readonly_pointer, .bits = 64 },
            .instructions = &.{
                .{ .reload_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot2 } },
                .{ .load_arg_ptr_disp8_rax = .{ .reg = .rdi, .offset = 0 } },
            },
        },
    };

    for (cases) |case| {
        var machine = MachineFunction.init(case.name, .{ .int = case.action.bits });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "pointer");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 128;
        try selector_state.bindValueLoc(&selector, "pointer", case.loc);

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const action = try transaction.register(loadActionRequest(
            "pointer",
            .{ .load_scalar = case.action },
        ));
        try transaction.seal();
        const accumulator = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(action));
        try transaction.defineAccumulatorResult(
            accumulator,
            "result",
            accumulatorLoadDefinition(case.action.bits),
        );
        try transaction.finalizeAccumulatorResult(accumulator);
        try transaction.commit();

        try std.testing.expectEqualSlices(
            machine_module.Instruction,
            case.instructions,
            machine.instructions.items,
        );
        const expected_result: ValueLoc = if (case.action.bits <= 32) .eax else .rax;
        try std.testing.expectEqual(expected_result, selector.values.get("result").?.loc);
    }
}

fn expectReadOnlyScalarLoadFailure(
    loc: ValueLoc,
    failure: ?Transaction.LoadTestFailure,
    expected_error: Transaction.LoadRequestError,
) !void {
    var machine = MachineFunction.init("value-use-readonly-load-precedence", .{ .int = 24 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "pointer");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "pointer", loc);
    const saved_pointer = selector.values.get("pointer").?;
    const saved_next_vreg = selector.next_virtual_reg;
    const saved_next_spill = selector.next_spill_slot;
    const saved_eflags = selector.eflags.snapshot();

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const action = try transaction.register(loadActionRequest(
        "pointer",
        .{ .load_scalar = .{ .kind = .readonly_pointer, .bits = 24 } },
    ));
    try transaction.seal();
    _ = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    if (failure) |boundary| try transaction.setLoadTestFailure(boundary);
    try std.testing.expectError(
        expected_error,
        transaction.executePreparedAction(try transaction.preparedView(action)),
    );
    try std.testing.expect(transaction.failedRequestIs(action));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(saved_pointer, selector.values.get("pointer").?);
    try std.testing.expectEqual(saved_next_vreg, selector.next_virtual_reg);
    try std.testing.expectEqual(saved_next_spill, selector.next_spill_slot);
    try selector.eflags.validateSnapshot(saved_eflags);
}

test "value-use readonly load precedence stages spills before width and maps staging failures first" {
    try expectReadOnlyScalarLoadFailure(
        .{ .arg64 = .rdi },
        null,
        error.ValueUseLoadReadonlyWidth,
    );
    try expectReadOnlyScalarLoadFailure(
        .{ .spill64 = .slot3 },
        null,
        error.ValueUseLoadReadonlyWidth,
    );
    try expectReadOnlyScalarLoadFailure(
        .{ .spill64 = .slot3 },
        .after_pointer_staging,
        error.ValueUseLoadReadonlyPointerSpill,
    );
    try std.testing.expectEqualStrings(
        "composed-block-load-width",
        loadDiagnosticForTest(error.ValueUseLoadReadonlyWidth),
    );
    try std.testing.expectEqualStrings(
        "composed-block-load-readonly-param-spill",
        loadDiagnosticForTest(error.ValueUseLoadReadonlyPointerSpill),
    );
}

test "value-use readonly load rejects source provenance only after resolution" {
    var machine = MachineFunction.init("value-use-readonly-load-provenance", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "pointer");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "pointer", .{ .arg32 = .rdi });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const action = try transaction.register(loadActionRequest(
        "pointer",
        .{ .load_scalar = .{ .kind = .readonly_pointer, .bits = 32 } },
    ));
    try std.testing.expectError(error.ValueUseLoadReadonlyPointerProvenance, transaction.seal());
    try std.testing.expect(transaction.failedRequestIs(action));
    try std.testing.expectEqualStrings(
        "composed-block-load-readonly-param-provenance",
        loadDiagnosticForTest(error.ValueUseLoadReadonlyPointerProvenance),
    );
}

fn expectTableLoadFailure(
    shape: constant_table.Shape,
    offset: u8,
    failure: ?Transaction.LoadTestFailure,
    expected_error: Transaction.LoadRequestError,
    fails_at_seal: bool,
) !void {
    var machine = MachineFunction.init("value-use-table-load-precedence", .{ .int = 16 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "table");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "table", .{ .readonly_table_ptr = .{
        .storage = .{ .spill = .slot2 },
        .symbol = "@table",
        .shape = shape,
        .offset = offset,
    } });
    const saved_table = selector.values.get("table").?;
    const saved_next_vreg = selector.next_virtual_reg;
    const saved_next_spill = selector.next_spill_slot;
    const saved_eflags = selector.eflags.snapshot();

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const action = try transaction.register(loadActionRequest(
        "table",
        .{ .load_readonly_table_i16 = .{ .result = try actionIdentity("table-result") } },
    ));
    if (fails_at_seal) {
        try std.testing.expectError(expected_error, transaction.seal());
    } else {
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        if (failure) |boundary| try transaction.setLoadTestFailure(boundary);
        try std.testing.expectError(
            expected_error,
            transaction.executePreparedAction(try transaction.preparedView(action)),
        );
    }
    try std.testing.expect(transaction.failedRequestIs(action));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(saved_table, selector.values.get("table").?);
    try std.testing.expect(selector.values.get("table-result") == null);
    try std.testing.expectEqual(saved_next_vreg, selector.next_virtual_reg);
    try std.testing.expectEqual(saved_next_spill, selector.next_spill_slot);
    try selector.eflags.validateSnapshot(saved_eflags);
}

test "value-use table load precedence preserves offset staging and type order" {
    try expectTableLoadFailure(
        .i16_128,
        8,
        null,
        error.ValueUseLoadReadonlyTableOffset,
        true,
    );
    try expectTableLoadFailure(
        .f64_16,
        0,
        null,
        error.ValueUseLoadReadonlyTableType,
        false,
    );
    try expectTableLoadFailure(
        .f64_16,
        0,
        .after_pointer_staging,
        error.ValueUseLoadReadonlyTableSpill,
        false,
    );
    try std.testing.expectEqualStrings(
        "composed-block-load-readonly-table-offset",
        loadDiagnosticForTest(error.ValueUseLoadReadonlyTableOffset),
    );
    try std.testing.expectEqualStrings(
        "composed-block-load-readonly-table-type",
        loadDiagnosticForTest(error.ValueUseLoadReadonlyTableType),
    );
}

test "value-use dormant indexed and readonly i56 load actions preserve semantic instruction order" {
    var machine = MachineFunction.init("value-use-load-address-order", .{ .int = 56 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "pointer", "index", "addend" }) |name| try addAtCurrent(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "index", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "addend", .{ .scratch64 = .rsi });
    try selector_state.bindValueLoc(&selector, "pointer", .{ .stack_i32_ptr = .{
        .disp = 40,
        .index = .{ .reg = .rdi, .name = "index", .addend_name = "addend" },
    } });
    try selector.address_dependencies.replaceAddress("pointer", &.{
        .{ .name = "index", .identity_type = .integer, .role = .index },
        .{ .name = "addend", .identity_type = .integer, .role = .addend },
    });

    var indexed = try Transaction.begin(&selector);
    defer indexed.deinit();
    const indexed_action = try indexed.register(loadActionRequest(
        "pointer",
        .{ .load_scalar = .{ .kind = .ordinary, .bits = 32 } },
    ));
    try indexed.seal();
    const indexed_accumulator = try indexed.beginAccumulatorSession();
    try indexed.prepare();
    try indexed.materializeAll();
    try indexed.executePreparedAction(try indexed.preparedView(indexed_action));
    try indexed.defineAccumulatorResult(indexed_accumulator, "indexed-result", .zeroExtending(32));
    try indexed.finalizeAccumulatorResult(indexed_accumulator);
    try indexed.commit();
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .rdi } },
        .{ .mov_arg64_arg = .{ .dst = .r8, .src = .rsi } },
        .add_r8_rcx,
        .{ .load_stack_rcx4_disp8_eax = 40 },
    }, machine.instructions.items);

    _ = selector_state.removeValueBinding(&selector, "indexed-result");
    machine.instructions.clearRetainingCapacity();
    const semantics_before = selector.eflags_semantics.items.len;
    try selector_state.bindValueLoc(&selector, "readonly", .{ .arg64 = .rdi });
    try addAtCurrent(&plan, "readonly");
    var readonly = try Transaction.begin(&selector);
    defer readonly.deinit();
    const readonly_action = try readonly.register(loadActionRequest(
        "readonly",
        .{ .load_scalar = .{ .kind = .readonly_pointer, .bits = 56 } },
    ));
    try readonly.seal();
    const readonly_accumulator = try readonly.beginAccumulatorSession();
    try readonly.prepare();
    try readonly.materializeAll();
    try readonly.executePreparedAction(try readonly.preparedView(readonly_action));
    try readonly.defineAccumulatorResult(readonly_accumulator, "readonly-result", .zeroExtendedRax(56));
    try readonly.finalizeAccumulatorResult(readonly_accumulator);
    try readonly.commit();
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .load_arg_ptr_disp8_u16_eax = .{ .reg = .rdi, .offset = 4 } },
        .{ .shl_rax_imm6 = 32 },
        .{ .mov_rax_to_arg = .rcx },
        .{ .load_arg_ptr_disp8_u8_eax = .{ .reg = .rdi, .offset = 6 } },
        .{ .shl_rax_imm6 = 48 },
        .{ .binary_arg_rax = .{ .op = .@"or", .reg = .rcx } },
        .{ .mov_rax_to_arg = .rcx },
        .{ .load_arg_ptr_disp8_eax = .{ .reg = .rdi, .offset = 0 } },
        .{ .binary_arg_rax = .{ .op = .@"or", .reg = .rcx } },
    }, machine.instructions.items);
    try std.testing.expectEqual(semantics_before + 4, selector.eflags_semantics.items.len);
}

test "value-use dormant pair and table load actions retain existing non-accumulator ownership" {
    var machine = MachineFunction.init("value-use-load-non-accumulator", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "readonly", "table", "table-reg" }) |name| try addAtCurrent(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "readonly", .{ .arg64 = .rcx });
    try selector_state.bindValueLoc(&selector, "table", .{ .readonly_table_ptr = .{
        .storage = .{ .spill = .slot3 },
        .symbol = "@table",
        .shape = .i16_128,
    } });
    try selector_state.bindValueLoc(&selector, "table-reg", .{ .readonly_table_ptr = .{
        .storage = .{ .reg = .rsi },
        .symbol = "@table-reg",
        .shape = .i16_128,
    } });

    var pair = try Transaction.begin(&selector);
    defer pair.deinit();
    const pair_action = try pair.register(loadActionRequest(
        "readonly",
        .{ .load_readonly_pair = .{
            .result = try actionIdentity("pair-result"),
            .bits = 96,
        } },
    ));
    try prepareAndExecuteAction(&pair, pair_action);
    try pair.commit();
    try std.testing.expectEqual(ValueLoc{ .scratch128 = .{ .lo = .rcx, .hi = .rdx } }, selector.values.get("pair-result").?.loc);
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .mov_arg64_arg = .{ .dst = .rdi, .src = .rcx } },
        .{ .load_arg_ptr_disp8_rax = .{ .reg = .rdi, .offset = 0 } },
        .{ .mov_rax_to_arg = .rcx },
        .{ .load_arg_ptr_disp8_eax = .{ .reg = .rdi, .offset = 8 } },
        .{ .mov_rax_to_arg = .rdx },
    }, machine.instructions.items);

    _ = selector_state.removeValueBinding(&selector, "pair-result");
    machine.instructions.clearRetainingCapacity();
    var table = try Transaction.begin(&selector);
    defer table.deinit();
    const table_action = try table.register(loadActionRequest(
        "table",
        .{ .load_readonly_table_i16 = .{ .result = try actionIdentity("table-result") } },
    ));
    try prepareAndExecuteAction(&table, table_action);
    try table.commit();
    try std.testing.expectEqual(ValueLoc{ .scratch32 = .r8 }, selector.values.get("table-result").?.loc);
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot3 } },
        .{ .load_arg_ptr_disp8_u16_arg = .{ .base = .rcx, .dst = .r8, .offset = 0 } },
    }, machine.instructions.items);

    _ = selector_state.removeValueBinding(&selector, "table-result");
    machine.instructions.clearRetainingCapacity();
    var table_register = try Transaction.begin(&selector);
    defer table_register.deinit();
    const table_register_action = try table_register.register(loadActionRequest(
        "table-reg",
        .{ .load_readonly_table_i16 = .{ .result = try actionIdentity("table-register-result") } },
    ));
    try prepareAndExecuteAction(&table_register, table_register_action);
    try table_register.commit();
    try std.testing.expectEqual(ValueLoc{ .scratch32 = .r8 }, selector.values.get("table-register-result").?.loc);
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .load_arg_ptr_disp8_u16_arg = .{ .base = .rsi, .dst = .r8, .offset = 0 } },
    }, machine.instructions.items);
}

test "value-use dormant stack i128 load is alias-only and table double remains fenced" {
    var machine = MachineFunction.init("value-use-load-fences", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "stack", "double-table" }) |name| try addAtCurrent(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "stack", .{ .stack128 = 48 });
    try selector_state.bindValueLoc(&selector, "double-table", .{ .readonly_table_ptr = .{
        .storage = .{ .reg = .rdi },
        .symbol = "@double-table",
        .shape = .f64_16,
    } });

    var alias = try Transaction.begin(&selector);
    defer alias.deinit();
    const alias_action = try alias.register(loadActionRequest(
        "stack",
        .{ .load_stack_i128_alias = .{ .result = try actionIdentity("alias-result") } },
    ));
    try prepareAndExecuteAction(&alias, alias_action);
    try alias.commit();
    try std.testing.expectEqual(ValueLoc{ .stack128_value = 48 }, selector.values.get("alias-result").?.loc);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);

    var double = try Transaction.begin(&selector);
    defer double.deinit();
    const double_action = try double.register(loadActionRequest(
        "double-table",
        .{ .load_readonly_table_i16 = .{ .result = try actionIdentity("must-not-bind") } },
    ));
    try double.seal();
    try double.prepare();
    try double.materializeAll();
    try std.testing.expectError(
        error.ValueUseLoadReadonlyTableType,
        double.executePreparedAction(try double.preparedView(double_action)),
    );
    try std.testing.expect(selector.values.get("must-not-bind") == null);
}

test "value-use load rollback restores pointer staging preservation partial loads and definitions" {
    const Boundary = enum { pointer, partial, preservation, definition, pair, pair_result, table, table_result };
    for ([_]Boundary{ .pointer, .partial, .preservation, .definition, .pair, .pair_result, .table, .table_result }) |boundary| {
        var machine = MachineFunction.init("value-use-load-rollback", .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "pointer", "live-accumulator", "table" }) |name| try addAtCurrent(&plan, name);
        try addLive(&plan, "live-accumulator");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 128;
        try selector_state.bindValueLoc(&selector, "pointer", .{ .spill64 = .slot3 });
        try selector_state.bindValueLoc(&selector, "live-accumulator", .rax);
        try selector_state.bindValueLoc(&selector, "table", .{ .readonly_table_ptr = .{
            .storage = .{ .spill = .slot2 },
            .symbol = "@table",
            .shape = .i16_128,
        } });
        const saved_pointer = selector.values.get("pointer").?;
        const saved_accumulator = selector.values.get("live-accumulator").?;
        const saved_table = selector.values.get("table").?;
        const saved_next_vreg = selector.next_virtual_reg;
        const saved_next_spill = selector.next_spill_slot;
        const saved_eflags = selector.eflags.snapshot();

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const is_pair = boundary == .pair or boundary == .pair_result;
        const is_table = boundary == .table or boundary == .table_result;
        const action = try transaction.register(loadActionRequest(
            if (is_table) "table" else "pointer",
            if (is_pair)
                .{ .load_readonly_pair = .{
                    .result = try actionIdentity("pair-result"),
                    .bits = 128,
                } }
            else if (is_table)
                .{ .load_readonly_table_i16 = .{ .result = try actionIdentity("table-result") } }
            else
                .{ .load_scalar = .{
                    .kind = .readonly_pointer,
                    .bits = if (boundary == .partial) 56 else 64,
                } },
        ));
        try transaction.seal();
        const accumulator = if (!is_pair and !is_table)
            try transaction.beginAccumulatorSession()
        else
            null;
        try transaction.prepare();
        try transaction.materializeAll();
        if (boundary == .preservation)
            try transaction.setLoadTestFailure(.after_preservation);
        {
            if (boundary == .pointer or boundary == .table)
                try transaction.setLoadTestFailure(.after_pointer_staging);
            if (boundary == .partial or boundary == .pair)
                try transaction.setLoadTestFailure(.after_first_partial_load);
            if (boundary == .definition or boundary == .pair_result or boundary == .table_result) {
                try transaction.executePreparedAction(try transaction.preparedView(action));
                if (boundary == .definition) {
                    try transaction.defineAccumulatorResult(accumulator.?, "result", .fullRax());
                    try transaction.finalizeAccumulatorResult(accumulator.?);
                }
                try transaction.rollback();
            } else {
                try std.testing.expectError(
                    switch (boundary) {
                        .pointer => error.ValueUseLoadReadonlyPointerSpill,
                        .table => error.ValueUseLoadReadonlyTableSpill,
                        else => error.ValueUseLoadTestFailure,
                    },
                    transaction.executePreparedAction(try transaction.preparedView(action)),
                );
            }
        }

        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(saved_pointer, selector.values.get("pointer").?);
        try std.testing.expectEqual(saved_accumulator, selector.values.get("live-accumulator").?);
        try std.testing.expectEqual(saved_table, selector.values.get("table").?);
        try std.testing.expect(selector.values.get("result") == null);
        try std.testing.expect(selector.values.get("pair-result") == null);
        try std.testing.expect(selector.values.get("table-result") == null);
        try std.testing.expectEqual(saved_next_vreg, selector.next_virtual_reg);
        try std.testing.expectEqual(saved_next_spill, selector.next_spill_slot);
        try selector.eflags.validateSnapshot(saved_eflags);
        try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
        try std.testing.expectError(error.ValueUseTransactionClosed, transaction.rollback());
    }
}

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

test "value-use dormant current-home eq-zero action reproduces every admitted home" {
    try executeCurrentHomeEqZeroCase(
        .{ .int = 32 },
        .eax,
        .gpr32,
        32,
        &.{ .test_eax_eax, .sete_eax },
    );
    try executeCurrentHomeEqZeroCase(
        .{ .int = 64 },
        .rax,
        .gpr64,
        64,
        &.{ .test_rax_rax, .sete_eax },
    );
    try executeCurrentHomeEqZeroCase(
        .{ .int = 13 },
        .{ .arg32 = .r8 },
        .gpr32,
        32,
        &.{ .{ .test_arg32 = .r8 }, .sete_eax },
    );
    try executeCurrentHomeEqZeroCase(
        .{ .int = 64 },
        .{ .scratch64 = .r9 },
        .gpr64,
        64,
        &.{ .{ .test_arg64 = .r9 }, .sete_eax },
    );
    try executeCurrentHomeEqZeroCase(
        .{ .int = 32 },
        .{ .spill64 = .slot2 },
        .gpr64,
        64,
        &.{
            .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = .slot2 } },
            .{ .test_arg32 = .rcx },
            .sete_eax,
        },
    );
    try executeCurrentHomeEqZeroCase(
        .{ .int = 64 },
        .{ .spill64 = .slot3 },
        .gpr64,
        64,
        &.{
            .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot3 } },
            .{ .test_arg64 = .rcx },
            .sete_eax,
        },
    );
}

test "value-use current-home eq-zero preserves accumulator sources then re-resolves canonically" {
    const Case = struct {
        ty: ir.Type,
        source_loc: ValueLoc,
        expected_preserve: machine_module.Instruction,
        expected_test: machine_module.Instruction,
        expected_source: ValueLoc,
    };
    const cases = [_]Case{
        .{
            .ty = .{ .int = 32 },
            .source_loc = .eax,
            .expected_preserve = .{ .mov_eax_to_arg = .rdi },
            .expected_test = .{ .test_arg32 = .rdi },
            .expected_source = .{ .scratch32 = .rdi },
        },
        .{
            .ty = .{ .int = 64 },
            .source_loc = .rax,
            .expected_preserve = .{ .mov_rax_to_arg = .rdi },
            .expected_test = .{ .test_arg64 = .rdi },
            .expected_source = .{ .scratch64 = .rdi },
        },
    };
    for (cases) |case| {
        var machine = MachineFunction.init("value-use-current-home-eq-zero-refresh", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addLive(&plan, "source");
        try addAtCurrent(&plan, "result");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "source", case.source_loc);

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerCurrentHomeEqZero(
            &transaction,
            .{ .named = "source" },
            "result",
            case.ty,
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(source));
        try transaction.commit();

        try std.testing.expectEqualSlices(machine_module.Instruction, &.{
            case.expected_preserve,
            case.expected_test,
            .sete_eax,
        }, machine.instructions.items);
        try std.testing.expectEqual(case.expected_source, selector.values.get("source").?.loc);
        try std.testing.expectEqual(ValueLoc.eax, selector.values.get("result").?.loc);
        try std.testing.expectEqual(@as(usize, 2), selector.eflags_semantics.items.len);
    }
}

test "value-use current-home eq-zero preserves the test definition through preparation" {
    var machine = MachineFunction.init("value-use-current-home-eq-zero-flags", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try addAtCurrent(&plan, "source");
    try addLive(&plan, "prior-result");
    try addAtCurrent(&plan, "result");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg32 = .rsi });
    try selector_state.bindValueLoc(&selector, "prior-result", .eax);

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const source = try registerCurrentHomeEqZero(
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
        .{ .test_arg32 = .rsi },
        .sete_eax,
    }, machine.instructions.items);
    try std.testing.expectEqual(selector_state.EflagsEffect.definition, selector.eflags_semantics.items[0].effect);
    try std.testing.expectEqual(selector_state.EflagsEffect.use, selector.eflags_semantics.items[1].effect);
}

test "value-use current-home eq-zero keeps unresolved width and location diagnostics distinct" {
    {
        var machine = MachineFunction.init("value-use-current-home-eq-zero-unresolved", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try addAtCurrent(&plan, "source");
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try registerCurrentHomeEqZero(
            &transaction,
            .{ .named = "source" },
            "result",
            .{ .int = 64 },
        );
        const err = transaction.seal();
        try std.testing.expectError(error.ValueUseUnresolvedSource, err);
        try std.testing.expectEqualStrings(
            "composed-block-icmp-lhs",
            currentHomeEqZeroDiagnosticForTest(&transaction, source, error.ValueUseUnresolvedSource).?,
        );
    }
    {
        var machine = MachineFunction.init("value-use-current-home-eq-zero-width", .{ .int = 1 });
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
        const source = try registerCurrentHomeEqZero(
            &transaction,
            .{ .named = "source" },
            "result",
            .{ .int = 32 },
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        const err = transaction.executePreparedAction(try transaction.preparedView(source));
        try std.testing.expectError(error.ValueUseCurrentHomeEqZeroWidthUnsupported, err);
        try std.testing.expectEqualStrings(
            "composed-block-icmp-lhs-width",
            currentHomeEqZeroDiagnosticForTest(
                &transaction,
                source,
                error.ValueUseCurrentHomeEqZeroWidthUnsupported,
            ).?,
        );
    }
    {
        var machine = MachineFunction.init("value-use-current-home-eq-zero-spill128", .{ .int = 1 });
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
        const source = try registerCurrentHomeEqZero(
            &transaction,
            .{ .named = "source" },
            "result",
            .{ .int = 64 },
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        const err = transaction.executePreparedAction(try transaction.preparedView(source));
        try std.testing.expectError(error.ValueUseCurrentHomeEqZeroLocationUnsupported, err);
        try std.testing.expectEqualStrings(
            "composed-block-icmp-lhs-loc",
            currentHomeEqZeroDiagnosticForTest(
                &transaction,
                source,
                error.ValueUseCurrentHomeEqZeroLocationUnsupported,
            ).?,
        );
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
}

test "value-use current-home eq-zero result remains durable across teardown and zext" {
    var machine = MachineFunction.init("value-use-current-home-eq-zero-then-zext", .{ .int = 32 });
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
        const source = try registerCurrentHomeEqZero(
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

    try std.testing.expectEqual(ValueLoc.eax, selector_state.resolveValue(&selector, .{ .named = "%7" }).?);
    selector.current_position = 2;
    const diagnostic = try selector_scalar.lowerCast(&selector, "%zext", .{
        .op = .zext,
        .value = .{ .named = "%7" },
        .from_ty = .{ .int = 1 },
        .to_ty = .{ .int = 32 },
    });
    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc.eax, selector_state.resolveValue(&selector, .{ .named = "%zext" }).?);
    try std.testing.expectEqualSlices(machine_module.Instruction, &.{
        .{ .test_arg32 = .rdi },
        .sete_eax,
        .{ .and_eax_imm32 = 1 },
    }, machine.instructions.items);
}

test "value-use current-home eq-zero rollback is exact after test and preparation" {
    const boundaries = [_]Transaction.CurrentHomeEqZeroTestFailure{
        .after_test_definition,
        .after_accumulator_preparation,
    };
    for (boundaries) |boundary| {
        var machine = MachineFunction.init("value-use-current-home-eq-zero-rollback", .{ .int = 1 });
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
        const source = try registerCurrentHomeEqZero(
            &transaction,
            .{ .named = "source" },
            "result",
            .{ .int = 32 },
        );
        try transaction.seal();
        _ = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.setCurrentHomeEqZeroTestFailure(boundary);
        try std.testing.expectError(
            error.ValueUseCurrentHomeEqZeroTestFailure,
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
        try std.testing.expectError(error.ValueUseTransactionClosed, transaction.rollback());
    }
}

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
    try std.testing.expectError(error.ValueUseUnresolvedSource, transaction.seal());
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

test "value-use dormant current-home sign-bit action classifies only named i32 i64 slt zero" {
    inline for ([_]u16{ 32, 64 }) |bits| {
        try std.testing.expect(Transaction.isCurrentHomeSignBitIcmp(.{
            .predicate = .slt,
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
        try std.testing.expectError(error.ValueUseUnresolvedSource, transaction.seal());
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

const I128PairRollbackBoundary = union(enum) {
    eq_min: Transaction.I128EqMinTestFailure,
    sign_bit: Transaction.I128SignBitTestFailure,
};

fn expectI128PairRollbackExact(boundary: I128PairRollbackBoundary) !void {
    var machine = MachineFunction.init("value-use-i128-pair-rollback", .{ .int = 1 });
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
    try selector_state.bindValueLoc(&selector, "source", .{ .spill128 = .{
        .lo = .slot0,
        .hi = .slot1,
    } });
    try selector_state.bindValueLoc(&selector, "live-accumulator", .eax);
    const saved_source = selector.values.get("source").?;
    const saved_accumulator = selector.values.get("live-accumulator").?;
    const saved_next_vreg = selector.next_virtual_reg;
    const saved_next_spill = selector.next_spill_slot;
    const saved_domain = selector.address_dependencies;
    const saved_accumulator_domain = selector.accumulator_domain;
    const saved_eflags = selector.eflags.snapshot();
    const saved_semantics = selector.eflags_semantics.items.len;
    const saved_spills = selector.spill_slots.count();

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const source = try registerI128PairAction(
        &transaction,
        .{ .named = "source" },
        "result",
        switch (boundary) {
            .eq_min => .eq_min,
            .sign_bit => .sign_bit,
        },
    );
    try transaction.seal();
    _ = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    switch (boundary) {
        .eq_min => |value| try transaction.setI128EqMinTestFailure(value),
        .sign_bit => |value| try transaction.setI128SignBitTestFailure(value),
    }
    const action_error = transaction.executePreparedAction(
        try transaction.preparedView(source),
    );
    switch (boundary) {
        .eq_min => try std.testing.expectError(error.ValueUseI128EqMinTestFailure, action_error),
        .sign_bit => try std.testing.expectError(error.ValueUseI128SignBitTestFailure, action_error),
    }

    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(saved_source, selector.values.get("source").?);
    try std.testing.expectEqual(saved_accumulator, selector.values.get("live-accumulator").?);
    try std.testing.expect(selector.values.get("result") == null);
    try std.testing.expectEqual(saved_next_vreg, selector.next_virtual_reg);
    try std.testing.expectEqual(saved_next_spill, selector.next_spill_slot);
    try std.testing.expectEqual(saved_spills, selector.spill_slots.count());
    try std.testing.expect(selector.address_dependencies.eql(&saved_domain));
    try std.testing.expect(std.meta.eql(saved_accumulator_domain, selector.accumulator_domain));
    try selector.eflags.validateSnapshot(saved_eflags);
    try std.testing.expectEqual(saved_semantics, selector.eflags_semantics.items.len);
    try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
}

test "value-use i128 equality wrapper rolls back exactly at every partial stage" {
    inline for (std.meta.tags(Transaction.I128EqMinTestFailure)) |boundary|
        try expectI128PairRollbackExact(.{ .eq_min = boundary });
}

test "value-use i128 sign-bit wrapper rolls back exactly at every partial stage" {
    inline for (std.meta.tags(Transaction.I128SignBitTestFailure)) |boundary|
        try expectI128PairRollbackExact(.{ .sign_bit = boundary });
}
