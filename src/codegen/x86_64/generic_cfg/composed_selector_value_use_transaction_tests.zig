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
    var incompatible = stable_request;
    incompatible.destination = .{ .gpr64 = .rdx };
    try std.testing.expectError(error.ValueUseIncompatibleDuplicate, phase.register(incompatible));
    @memset(&transient_name, 'x');
    try phase.seal();
    try std.testing.expectError(error.ValueUseLateRegistration, phase.register(stable_request));

    var unsealed = try Transaction.begin(&selector);
    defer unsealed.deinit();
    try std.testing.expectError(error.ValueUsePrepareBeforeSeal, unsealed.prepare());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
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
