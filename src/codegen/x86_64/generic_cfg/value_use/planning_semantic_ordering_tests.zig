const support = @import("test_support.zig");

const std = support.std;
const ir = support.ir;
const constant_table = support.constant_table;
const machine_module = support.machine_module;
const selector_types = support.selector_types;
const state_data = support.state_data;
const selector_state = support.selector_state;
const selector_scalar = support.selector_scalar;
const stage2_planning = support.stage2_planning;
const value_use = support.value_use;
const ComposedBlockSelector = support.ComposedBlockSelector;
const MachineFunction = support.MachineFunction;
const SelectorAllocationPlan = support.SelectorAllocationPlan;
const Transaction = support.Transaction;
const ValueLoc = support.ValueLoc;
const addLive = support.addLive;
const addAtCurrent = support.addAtCurrent;
const expected = support.expected;
const request = support.request;
const preparedRequest = support.preparedRequest;
const preparedSourceRequest = support.preparedSourceRequest;
const actionIdentity = support.actionIdentity;
const scratchCompareExpected = support.scratchCompareExpected;
const ScratchCompareRequests = support.ScratchCompareRequests;
const registerScratchCompare = support.registerScratchCompare;
const registerCurrentHomeEqZero = support.registerCurrentHomeEqZero;
const registerSetccEaxCompare = support.registerSetccEaxCompare;
const registerCurrentHomeSignBit = support.registerCurrentHomeSignBit;
const I128PairActionKind = support.I128PairActionKind;
const registerI128PairAction = support.registerI128PairAction;
const i128PairDiagnosticForTest = support.i128PairDiagnosticForTest;
const currentHomeSignBitDiagnosticForTest = support.currentHomeSignBitDiagnosticForTest;
const setccEaxCompareDiagnosticForTest = support.setccEaxCompareDiagnosticForTest;
const currentHomeEqZeroDiagnosticForTest = support.currentHomeEqZeroDiagnosticForTest;
const MemcpyRequests = support.MemcpyRequests;
const registerMemcpyRequests = support.registerMemcpyRequests;
const registerMemcpyAction = support.registerMemcpyAction;
const inlineMemcpyValueUseDiagnosticForTest = support.inlineMemcpyValueUseDiagnosticForTest;
const prepareAndExecuteAction = support.prepareAndExecuteAction;
const executeScratchCompareCase = support.executeScratchCompareCase;
const executeCurrentHomeEqZeroCase = support.executeCurrentHomeEqZeroCase;
const executeSetccEaxCompareCase = support.executeSetccEaxCompareCase;
const executeCurrentHomeSignBitCase = support.executeCurrentHomeSignBitCase;
const executeI128PairActionCase = support.executeI128PairActionCase;
const executeBranchConditionCase = support.executeBranchConditionCase;
const oneCaseSwitchAction = support.oneCaseSwitchAction;
const executeSwitchConditionCase = support.executeSwitchConditionCase;
const loadActionRequest = support.loadActionRequest;
const accumulatorLoadDefinition = support.accumulatorLoadDefinition;
const loadDiagnosticForTest = support.loadDiagnosticForTest;
const expectReadOnlyScalarLoadFailure = support.expectReadOnlyScalarLoadFailure;
const expectTableLoadFailure = support.expectTableLoadFailure;
const I128PairRollbackBoundary = support.I128PairRollbackBoundary;
const expectI128PairRollbackExact = support.expectI128PairRollbackExact;

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
