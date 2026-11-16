const table_descriptions = @import("../../../constant_table.zig").Description;
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
        bits: u16 = 16,
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
            .bits = 48,
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
        const bits = case.bits;
        var machine = MachineFunction.init(case.name, .{ .int = bits });
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
            .{ .load_scalar = .{ .kind = .ordinary, .bits = bits } },
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
    try std.testing.expectError(error.ValueUseForwardPlanMissing, missing.seal());
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
            .name = "pointer-u16",
            .loc = .{ .arg64 = .rdi },
            .action = .{ .kind = .ordinary, .bits = 16 },
            .instructions = &.{.{ .load_arg_ptr_disp8_u16_eax = .{ .reg = .rdi, .offset = 0 } }},
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
test "value-use table load precedence preserves offset staging and type order" {
    try expectTableLoadFailure(
        table_descriptions.i16_128,
        8,
        null,
        error.ValueUseLoadReadonlyTableOffset,
        true,
    );
    try expectTableLoadFailure(
        table_descriptions.f64_16,
        0,
        null,
        error.ValueUseLoadReadonlyTableType,
        false,
    );
    try expectTableLoadFailure(
        table_descriptions.f64_16,
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
        .shape = table_descriptions.i16_128,
    } });
    try selector_state.bindValueLoc(&selector, "table-reg", .{ .readonly_table_ptr = .{
        .storage = .{ .reg = .rsi },
        .symbol = "@table-reg",
        .shape = table_descriptions.i16_128,
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
        .shape = table_descriptions.f64_16,
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
            .shape = table_descriptions.i16_128,
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
