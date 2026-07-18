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
const PlannedValueAssignment = stage2_planning.PlannedValueAssignment;
const ForwardValuePlan = stage2_planning.ForwardValuePlan;
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

const ForwardCharacterization = struct {
    name: []const u8,
    source: []const u8,
    current_position: usize,
    interval_end: usize,
    forward: ForwardValuePlan,
    assignment: ?PlannedValueAssignment,
    legacy_resolution: ?ValueLoc,
};

fn expectForwardCharacterization(fixture: ForwardCharacterization) !void {
    var machine = MachineFunction.init(fixture.name, .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put(fixture.source, fixture.interval_end);
    try plan.forward_values.put(fixture.source, fixture.forward);
    if (fixture.assignment) |assignment|
        try plan.assignments.put(fixture.source, assignment);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = fixture.current_position;
    selector.stack_frame_bytes = 128;
    try std.testing.expectEqual(@as(usize, 0), selector.address_dependencies.count());
    try std.testing.expectEqual(
        fixture.legacy_resolution,
        selector_state.resolveValue(&selector, .{ .named = fixture.source }),
    );

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const source = try transaction.register(request(
        fixture.source,
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .rax,
    ));
    try std.testing.expectError(error.ValueUseUnresolvedSource, transaction.seal());
    try std.testing.expect(transaction.failedRequestIs(source));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "value-use current binding characterizes missing plan and missing interval" {
    var machine = MachineFunction.init("current-binding-plan-errors", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.current_position = 2;
    try selector_state.bindValueLoc(&selector, "source", .{ .arg64 = .rdi });
    const binding = selector.values.get("source").?;
    try std.testing.expectEqual(
        ValueLoc{ .arg64 = .rdi },
        selector_state.resolveValue(&selector, .{ .named = "source" }).?,
    );

    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try transaction.register(request(
            "source",
            .{ .int = 64 },
            .gpr64,
            .gpr64,
            .rax,
        ));
        try std.testing.expectError(error.ValueUseSourcePlanMissing, transaction.seal());
        try std.testing.expect(transaction.failedRequestIs(source));
    }

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.assignments.put("source", .{ .gpr64 = .rdi });
    selector.allocation_plan = &plan;
    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const source = try transaction.register(request(
            "source",
            .{ .int = 64 },
            .gpr64,
            .gpr64,
            .rax,
        ));
        try std.testing.expectError(error.ValueUseSourceIntervalMissing, transaction.seal());
        try std.testing.expect(transaction.failedRequestIs(source));
    }

    try std.testing.expectEqual(binding, selector.values.get("source").?);
    try std.testing.expectEqual(@as(usize, 0), selector.address_dependencies.count());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "value-use forward metadata characterizes legacy resolution before Q1 admission" {
    const cases = [_]ForwardCharacterization{
        .{
            .name = "valid-forward",
            .source = "forward",
            .current_position = 2,
            .interval_end = 7,
            .forward = .{
                .definition_position = 5,
                .metadata = .{ .class = .gpr64, .bits = 64 },
            },
            .assignment = .{ .gpr64 = .r9 },
            .legacy_resolution = .{ .scratch64 = .r9 },
        },
        .{
            .name = "stale-forward-definition",
            .source = "forward",
            .current_position = 5,
            .interval_end = 7,
            .forward = .{
                .definition_position = 5,
                .metadata = .{ .class = .gpr64, .bits = 64 },
            },
            .assignment = .{ .gpr64 = .r9 },
            .legacy_resolution = null,
        },
        .{
            .name = "expired-forward-interval",
            .source = "forward",
            .current_position = 3,
            .interval_end = 2,
            .forward = .{
                .definition_position = 5,
                .metadata = .{ .class = .gpr64, .bits = 64 },
            },
            .assignment = .{ .gpr64 = .r9 },
            // Legacy forward resolution does not consult the interval.
            .legacy_resolution = .{ .scratch64 = .r9 },
        },
        .{
            .name = "forward-class-mismatch",
            .source = "forward",
            .current_position = 2,
            .interval_end = 7,
            .forward = .{
                .definition_position = 5,
                .metadata = .{ .class = .gpr32, .bits = 32 },
            },
            .assignment = .{ .gpr64 = .r9 },
            .legacy_resolution = null,
        },
        .{
            .name = "forward-defined-width-mismatch",
            .source = "forward",
            .current_position = 2,
            .interval_end = 7,
            .forward = .{
                .definition_position = 5,
                .metadata = .{ .class = .gpr64, .bits = 32 },
            },
            .assignment = .{ .gpr64 = .r9 },
            // Legacy checks the class but does not validate defined width.
            .legacy_resolution = .{ .scratch64 = .r9 },
        },
        .{
            .name = "forward-missing-assignment",
            .source = "forward",
            .current_position = 2,
            .interval_end = 7,
            .forward = .{
                .definition_position = 5,
                .metadata = .{ .class = .gpr64, .bits = 64 },
            },
            .assignment = null,
            .legacy_resolution = null,
        },
    };
    inline for (cases) |fixture| try expectForwardCharacterization(fixture);
}

test "value-use preserves the six B07 forward-RHS cohort traces as future inputs" {
    const cases = [_]ForwardCharacterization{
        .{
            .name = "compiler_rt.floatuneidf.__floatuneidf position 25 sub 12 20",
            .source = "20",
            .current_position = 25,
            .interval_end = 42,
            .forward = .{
                .definition_position = 37,
                .metadata = .{ .class = .gpr64, .bits = 64 },
            },
            .assignment = .{ .gpr64 = .r9 },
            .legacy_resolution = .{ .scratch64 = .r9 },
        },
        .{
            .name = "compiler_rt.floatuneisf.__floatuneisf position 25 sub 12 20",
            .source = "20",
            .current_position = 25,
            .interval_end = 42,
            .forward = .{
                .definition_position = 37,
                .metadata = .{ .class = .gpr64, .bits = 64 },
            },
            .assignment = .{ .gpr64 = .r9 },
            .legacy_resolution = .{ .scratch64 = .r9 },
        },
        .{
            .name = "compiler_rt.floatuneihf.__floatuneihf position 25 sub 12 20",
            .source = "20",
            .current_position = 25,
            .interval_end = 42,
            .forward = .{
                .definition_position = 37,
                .metadata = .{ .class = .gpr64, .bits = 64 },
            },
            .assignment = .{ .gpr64 = .r9 },
            .legacy_resolution = .{ .scratch64 = .r9 },
        },
        .{
            .name = "compiler_rt.floateidf.__floateidf position 29 sub .neg 26",
            .source = "26",
            .current_position = 29,
            .interval_end = 47,
            .forward = .{
                .definition_position = 42,
                .metadata = .{ .class = .gpr64, .bits = 64 },
            },
            .assignment = .{ .spill = 0 },
            .legacy_resolution = .{ .spill64 = .slot0 },
        },
        .{
            .name = "compiler_rt.floateisf.__floateisf position 29 sub .neg 26",
            .source = "26",
            .current_position = 29,
            .interval_end = 47,
            .forward = .{
                .definition_position = 42,
                .metadata = .{ .class = .gpr64, .bits = 64 },
            },
            .assignment = .{ .spill = 0 },
            .legacy_resolution = .{ .spill64 = .slot0 },
        },
        .{
            .name = "compiler_rt.floateihf.__floateihf position 29 sub .neg 26",
            .source = "26",
            .current_position = 29,
            .interval_end = 47,
            .forward = .{
                .definition_position = 42,
                .metadata = .{ .class = .gpr64, .bits = 64 },
            },
            .assignment = .{ .spill = 0 },
            .legacy_resolution = .{ .spill64 = .slot0 },
        },
    };
    inline for (cases) |fixture| try expectForwardCharacterization(fixture);
}

test "value-use lifetime authority separates plan interval availability and provenance" {
    var machine = MachineFunction.init("value-use-lifetime-authority", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.current_position = 2;
    try selector_state.bindValueLoc(&selector, "first", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "second", .{ .arg64 = .rsi });

    var missing_plan = try Transaction.begin(&selector);
    defer missing_plan.deinit();
    const first = try missing_plan.register(request(
        "first",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .rax,
    ));
    const second = try missing_plan.register(request(
        "second",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .gpr64 = .rcx },
    ));
    try std.testing.expectError(error.ValueUseSourcePlanMissing, missing_plan.seal());
    try std.testing.expect(missing_plan.failedRequestIs(first));
    try std.testing.expect(!missing_plan.failedRequestIs(second));

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    selector.allocation_plan = &plan;

    var missing_interval = try Transaction.begin(&selector);
    defer missing_interval.deinit();
    const missing_interval_handle = try missing_interval.register(request(
        "first",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .rax,
    ));
    try std.testing.expectError(
        error.ValueUseSourceIntervalMissing,
        missing_interval.seal(),
    );
    try std.testing.expect(missing_interval.failedRequestIs(missing_interval_handle));

    try plan.interval_ends.put("first", 1);
    var expired = try Transaction.begin(&selector);
    defer expired.deinit();
    const expired_handle = try expired.register(request(
        "first",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .rax,
    ));
    try std.testing.expectError(error.ValueUseExpiredSource, expired.seal());
    try std.testing.expect(expired.failedRequestIs(expired_handle));

    try plan.interval_ends.put("first", 2);
    var end_at_current = try Transaction.begin(&selector);
    defer end_at_current.deinit();
    _ = try end_at_current.register(request(
        "first",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .rax,
    ));
    try end_at_current.seal();
    try end_at_current.rollback();

    try plan.interval_ends.put("first", 3);
    var survives = try Transaction.begin(&selector);
    defer survives.deinit();
    _ = try survives.register(request(
        "first",
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .rax,
    ));
    try survives.seal();
    try survives.rollback();

    selector.allocation_plan = null;
    var typed_null = try Transaction.begin(&selector);
    defer typed_null.deinit();
    _ = try typed_null.register(.{
        .source = .null_value,
        .expected = expected(.ptr, .gpr64),
        .form = .pointer,
        .destination = .rax,
    });
    try typed_null.seal();
    try typed_null.rollback();
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
