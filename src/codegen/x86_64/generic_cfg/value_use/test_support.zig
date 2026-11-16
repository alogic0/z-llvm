pub const std = @import("std");
pub const ir = @import("../../../../ir.zig");
pub const constant_table = @import("../../constant_table.zig");
pub const machine_module = @import("../../machine.zig");
pub const selector_types = @import("../selector_types.zig");
pub const state_data = @import("../composed_selector_state_data.zig");
pub const selector_state = @import("../composed_selector_state.zig");
pub const selector_scalar = @import("../composed_selector_scalar.zig");
pub const stage2_planning = @import("../stage2_planning.zig");
pub const value_use = @import("../composed_selector_value_use_transaction.zig");
pub const ComposedBlockSelector = state_data.ComposedBlockSelector;
pub const MachineFunction = machine_module.MachineFunction;
pub const SelectorAllocationPlan = stage2_planning.SelectorAllocationPlan;
pub const Transaction = value_use.ValueUseTransaction;
pub const ValueLoc = selector_types.ValueLoc;
pub fn addLive(plan: *SelectorAllocationPlan, name: []const u8) !void {
    try plan.interval_ends.put(name, 10);
}
pub fn addAtCurrent(plan: *SelectorAllocationPlan, name: []const u8) !void {
    try plan.interval_ends.put(name, 1);
}
pub fn expected(ty: ir.Type, class: selector_types.VirtualRegClass) Transaction.Expected {
    return .{
        .ty = ty,
        .register_class = class,
        .pointer_address_space = if (ty == .ptr) 0 else null,
    };
}
pub fn request(
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
pub fn preparedRequest(
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
pub fn preparedSourceRequest(
    name: []const u8,
    ty: ir.Type,
    class: selector_types.VirtualRegClass,
    form: Transaction.UseForm,
) Transaction.Request {
    return request(name, ty, class, form, .prepared_source);
}
pub fn actionIdentity(name: []const u8) !Transaction.ActionIdentity {
    return Transaction.ActionIdentity.init(name);
}
pub fn scratchCompareExpected(ty: ir.Type) Transaction.Expected {
    return switch (ty) {
        .int => |bits| expected(ty, if (bits <= 32) .gpr32 else .gpr64),
        .ptr => expected(ty, .gpr64),
        else => unreachable,
    };
}
pub const ScratchCompareRequests = struct {
    lhs: Transaction.RequestHandle,
    rhs: ?Transaction.RequestHandle,
};
pub fn registerScratchCompare(
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
pub fn registerCurrentHomeEqZero(
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
pub fn registerSetccEaxCompare(
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
pub fn registerCurrentHomeSignBit(
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
pub const I128PairActionKind = enum {
    eq_min,
    sign_bit,
};
pub fn registerI128PairAction(
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
pub fn i128PairDiagnosticForTest(
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
pub fn currentHomeSignBitDiagnosticForTest(
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
pub fn setccEaxCompareDiagnosticForTest(
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
pub fn currentHomeEqZeroDiagnosticForTest(
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
pub const MemcpyRequests = struct {
    destination: Transaction.RequestHandle,
    source: Transaction.RequestHandle,
    length: Transaction.RequestHandle,
};
pub fn registerMemcpyRequests(
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
pub fn registerMemcpyAction(
    transaction: *Transaction,
    destination: ir.Value,
    source: ir.Value,
    length: ir.Value,
) !Transaction.RequestHandle {
    return (try registerMemcpyRequests(transaction, destination, source, length)).destination;
}
pub fn inlineMemcpyValueUseDiagnosticForTest(
    transaction: *const Transaction,
    requests: MemcpyRequests,
) ?[]const u8 {
    if (transaction.failedRequestIs(requests.destination)) return "composed-block-memcpy-dst";
    if (transaction.failedRequestIs(requests.source)) return "composed-block-memcpy-src";
    if (transaction.failedRequestIs(requests.length)) return "composed-block-memcpy-len";
    return null;
}
pub fn prepareAndExecuteAction(
    transaction: *Transaction,
    action: Transaction.RequestHandle,
) !void {
    try transaction.seal();
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.executePreparedAction(try transaction.preparedView(action));
}
pub fn executeScratchCompareCase(
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
pub fn executeCurrentHomeEqZeroCase(
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
pub fn executeSetccEaxCompareCase(
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
pub fn executeCurrentHomeSignBitCase(
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
pub fn executeI128PairActionCase(
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
pub fn executeBranchConditionCase(
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
pub fn oneCaseSwitchAction(bits: u8) !Transaction.SwitchCompareChainAction {
    return Transaction.SwitchCompareChainAction.init(
        bits,
        &.{.{ .value = 7, .target = "case-seven" }},
        "default",
        null,
    );
}
pub fn executeSwitchConditionCase(
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
pub fn loadActionRequest(
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
pub fn accumulatorLoadDefinition(bits: u16) selector_state.AccumulatorDefinition {
    return switch (bits) {
        8, 16, 32 => .zeroExtending(bits),
        56 => .zeroExtendedRax(56),
        64 => .fullRax(),
        else => unreachable,
    };
}
pub fn loadDiagnosticForTest(err: Transaction.LoadRequestError) []const u8 {
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
pub fn expectReadOnlyScalarLoadFailure(
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
pub fn expectTableLoadFailure(
    shape: constant_table.Description,
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
pub const I128PairRollbackBoundary = union(enum) {
    eq_min: Transaction.I128EqMinTestFailure,
    sign_bit: Transaction.I128SignBitTestFailure,
};
pub fn expectI128PairRollbackExact(boundary: I128PairRollbackBoundary) !void {
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
