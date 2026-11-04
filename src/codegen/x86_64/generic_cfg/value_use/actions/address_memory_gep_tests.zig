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
test "value-use scaled-address action preserves sources already in its scratch destinations" {
    for ([_]u8{ 1, 3, 8, 12, 15, 56, 128, 255 }) |scale| {
        var machine = MachineFunction.init("scaled-in-place", .ptr);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "base", "index", "result" }) |name| try addLive(&plan, name);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 128;
        try selector_state.bindValueLoc(&selector, "base", .{ .arg64 = .rcx });
        try selector_state.bindValueLoc(&selector, "index", .{ .arg64 = .r8 });
        const base_before = selector.values.get("base").?;
        const index_before = selector.values.get("index").?;
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const index = try transaction.register(preparedSourceRequest("index", .{ .int = 64 }, .gpr64, .gpr64));
        const action = try transaction.register(preparedRequest(
            "base",
            .ptr,
            .gpr64,
            .pointer,
            .{ .form_scaled_address = .{
                .result = try actionIdentity("result"),
                .index = .{ .request = index },
                .scale = scale,
            } },
        ));
        try transaction.seal();
        try transaction.prepare();
        try std.testing.expect(selector.values.get("base").?.loc == .spill64);
        try std.testing.expect(selector.values.get("index").?.loc == .spill64);
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(action));
        try std.testing.expectEqual(base_before.vreg, selector.values.get("base").?.vreg);
        try std.testing.expectEqual(index_before.vreg, selector.values.get("index").?.vreg);
        try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector.values.get("result").?.loc);
        try transaction.rollback();
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(base_before, selector.values.get("base").?);
        try std.testing.expectEqual(index_before, selector.values.get("index").?);
        try std.testing.expect(selector.values.get("result") == null);
    }
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

test "value-use byte-address preserves a live source already in the result register" {
    for ([_]bool{ false, true }) |dynamic| {
        var machine = MachineFunction.init("byte-address-live-rcx", .ptr);
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        inline for (&.{ "base", "index", "derived" }) |name| try addLive(&plan, name);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 128;
        const base: ValueLoc = .{ .arg64 = if (dynamic) .rdi else .rcx };
        try selector_state.bindValueLoc(&selector, "base", base);
        try selector_state.bindValueLoc(&selector, "index", .{ .arg64 = .rcx });
        const original_next_spill = selector.next_spill_slot;
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const index = if (dynamic) try transaction.register(preparedSourceRequest("index", .{ .int = 64 }, .gpr64, .gpr64)) else null;
        const address = try transaction.register(preparedRequest("base", .ptr, .gpr64, .pointer, .{ .form_byte_address = .{
            .result = try actionIdentity("derived"),
            .offset = if (index) |handle| .{ .request = handle } else .{ .constant = 3 },
        } }));
        try transaction.seal();
        try transaction.prepare();
        const preserved_name = if (dynamic) "index" else "base";
        try std.testing.expect(selector.values.get(preserved_name).?.loc == .spill64);
        try transaction.materializeAll();
        try transaction.executePreparedAction(try transaction.preparedView(address));
        try std.testing.expect(selector.values.get(preserved_name).?.loc == .spill64);
        try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector.values.get("derived").?.loc);
        try transaction.rollback();
        try std.testing.expectEqual(base, selector.values.get("base").?.loc);
        try std.testing.expectEqual(ValueLoc{ .arg64 = .rcx }, selector.values.get("index").?.loc);
        try std.testing.expectEqual(original_next_spill, selector.next_spill_slot);
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expect(selector.values.get("derived") == null);
    }
}
