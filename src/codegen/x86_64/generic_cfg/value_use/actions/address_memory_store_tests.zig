const support = @import("../test_support.zig");

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
test "value-use i64 store consumes RCX value before staging a spilled pointer" {
    inline for (.{ false, true }) |live_after| {
        var machine = MachineFunction.init("store-rcx-value", .void);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "pointer", "value" }) |name| {
            if (live_after) try addLive(&plan, name) else try addAtCurrent(&plan, name);
        }
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 128;
        selector.next_spill_slot = 1;
        try selector_state.bindValueLoc(&selector, "pointer", .{ .spill64 = .slot0 });
        try selector_state.bindValueLoc(&selector, "value", .{ .scratch64 = .rcx });
        const value_before = selector.values.get("value").?;
        const pointer_before = selector.values.get("pointer").?;
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const value = try transaction.register(preparedSourceRequest("value", .ptr, .gpr64, .pointer));
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
        try std.testing.expectEqual(machine_module.Instruction{ .mov_arg_rax = .rcx }, machine.instructions.items[0]);
        try std.testing.expectEqual(machine_module.Instruction{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot0 } }, machine.instructions.items[machine.instructions.items.len - 2]);
        try std.testing.expectEqual(machine_module.Instruction.store_rax_rcx_ptr, machine.instructions.items[machine.instructions.items.len - 1]);
        if (live_after) {
            try std.testing.expect(selector.values.get("value").?.loc == .spill64);
            try std.testing.expectEqual(value_before.vreg, selector.values.get("value").?.vreg);
        }
        try transaction.rollback();
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(@as(usize, 1), selector.next_spill_slot);
        try std.testing.expectEqual(value_before, selector.values.get("value").?);
        try std.testing.expectEqual(pointer_before, selector.values.get("pointer").?);
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
    _ = try cycle.register(request("writer", .{ .int = 64 }, .gpr64, .gpr64, .{ .gpr64 = .rcx }));
    try cycle.seal();
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try cycle.prepare();
    try cycle.materializeAll();
    try cycle.rollback();
}
