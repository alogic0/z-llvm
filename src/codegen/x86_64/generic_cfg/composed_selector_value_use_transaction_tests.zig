const std = @import("std");
const ir = @import("../../../ir.zig");
const machine_module = @import("../machine.zig");
const selector_types = @import("selector_types.zig");
const state_data = @import("composed_selector_state_data.zig");
const selector_state = @import("composed_selector_state.zig");
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

test "value-use transaction exposes fixed copy-amplification contract" {
    try std.testing.expectEqual(@as(usize, 16), Transaction.max_requests);
    try std.testing.expectEqual(@as(usize, 1), Transaction.address_domain_snapshot_copies);
    try std.testing.expectEqual(@as(usize, 0), Transaction.address_domain_copies_per_request);
    try std.testing.expect(Transaction.address_domain_snapshot_bytes > 0);
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
    for (names, 0..) |name, index| {
        _ = try transaction.register(request(name, .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = @enumFromInt(index % 6) }));
    }
    try std.testing.expectError(error.ValueUseRequestCapacityExceeded, transaction.register(request(
        "overflow",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .rax,
    )));

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
