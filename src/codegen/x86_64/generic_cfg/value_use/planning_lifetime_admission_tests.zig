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
    admission_error: ?anyerror = null,
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
    if (fixture.admission_error) |expected_error| {
        try std.testing.expectError(expected_error, transaction.seal());
        try std.testing.expect(transaction.failedRequestIs(source));
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    } else {
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.rollback();
    }
}

fn installForward(
    plan: *SelectorAllocationPlan,
    name: []const u8,
    definition_position: usize,
    interval_end: usize,
    class: selector_types.VirtualRegClass,
    bits: u16,
    assignment: PlannedValueAssignment,
) !void {
    try plan.interval_ends.put(name, interval_end);
    try plan.forward_values.put(name, .{
        .definition_position = definition_position,
        .metadata = .{ .class = class, .bits = bits },
    });
    try plan.assignments.put(name, assignment);
}

fn registerForwardGpr64(transaction: *Transaction, name: []const u8, destination: Transaction.Destination) !Transaction.RequestHandle {
    return transaction.register(request(
        name,
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        destination,
    ));
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
            .admission_error = error.ValueUseForwardPlanMalformed,
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
            .admission_error = error.ValueUseForwardIntervalExpired,
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
            .admission_error = error.ValueUseForwardTypeMismatch,
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
            .admission_error = error.ValueUseForwardTypeMismatch,
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
            .admission_error = error.ValueUseForwardAssignmentMissing,
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

test "value-use forward Q1 admits register and spill assignments without creating bindings" {
    const cases = [_]struct {
        name: []const u8,
        assignment: PlannedValueAssignment,
        destination: Transaction.Destination,
    }{
        .{ .name = "register-forward", .assignment = .{ .gpr64 = .r9 }, .destination = .rax },
        .{ .name = "spill-forward", .assignment = .{ .spill = 0 }, .destination = .{ .gpr64 = .rcx } },
    };
    inline for (cases) |case| {
        var machine = MachineFunction.init(case.name, .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try installForward(&plan, "forward", 5, 7, .gpr64, 64, case.assignment);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 2;
        selector.stack_frame_bytes = 128;

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        _ = try registerForwardGpr64(&transaction, "forward", case.destination);
        try transaction.seal();
        try std.testing.expect(selector.values.get("forward") == null);
        try transaction.prepare();
        try transaction.materializeAll();
        try std.testing.expect(selector.values.get("forward") == null);
        try transaction.rollback();
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expect(selector.values.get("forward") == null);
    }
}

test "value-use forward Q1 has a closed request-attributable admission error table" {
    const cases = [_]struct {
        name: []const u8,
        install_interval: bool = true,
        interval_end: usize = 7,
        definition_position: usize = 5,
        class: selector_types.VirtualRegClass = .gpr64,
        bits: u16 = 64,
        assignment: ?PlannedValueAssignment = .{ .gpr64 = .r9 },
        expected_error: anyerror,
    }{
        .{ .name = "no-valid-plan", .install_interval = false, .expected_error = error.ValueUseForwardPlanMissing },
        .{ .name = "malformed-definition", .definition_position = 2, .expected_error = error.ValueUseForwardPlanMalformed },
        .{ .name = "expired-interval", .interval_end = 1, .expected_error = error.ValueUseForwardIntervalExpired },
        .{ .name = "class-mismatch", .class = .gpr32, .bits = 64, .assignment = .{ .gpr32 = .r9 }, .expected_error = error.ValueUseForwardTypeMismatch },
        .{ .name = "width-mismatch", .bits = 32, .expected_error = error.ValueUseForwardTypeMismatch },
        .{ .name = "missing-assignment", .assignment = null, .expected_error = error.ValueUseForwardAssignmentMissing },
    };
    inline for (cases) |case| {
        var machine = MachineFunction.init(case.name, .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        if (case.install_interval) try plan.interval_ends.put("forward", case.interval_end);
        try plan.forward_values.put("forward", .{
            .definition_position = case.definition_position,
            .metadata = .{ .class = case.class, .bits = case.bits },
        });
        if (case.assignment) |assignment| try plan.assignments.put("forward", assignment);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 2;
        selector.stack_frame_bytes = 128;

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handle = try registerForwardGpr64(&transaction, "forward", .rax);
        try std.testing.expectError(case.expected_error, transaction.seal());
        try std.testing.expect(transaction.failedRequestIs(handle));
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
}

test "value-use forward snapshot rejects every changed admission fact before emission" {
    const Mutation = enum {
        request_identity,
        instruction_position,
        definition_position,
        interval_end,
        virtual_class,
        defined_width,
        assignment_tag,
        assignment_payload,
        spill_frame_extent,
        entry_removed,
    };
    inline for (std.meta.tags(Mutation)) |mutation| {
        var machine = MachineFunction.init(@tagName(mutation), .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try installForward(
            &plan,
            "forward",
            8,
            10,
            .gpr64,
            64,
            if (mutation == .spill_frame_extent) .{ .spill = 0 } else .{ .gpr64 = .r9 },
        );
        if (mutation == .request_identity)
            try installForward(&plan, "replacement", 8, 10, .gpr64, 64, .{ .gpr64 = .r9 });
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.current_position = 2;
        selector.stack_frame_bytes = 128;

        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const handle = try transaction.register(preparedSourceRequest(
            "forward",
            .{ .int = 64 },
            .gpr64,
            .gpr64,
        ));
        if (mutation == .request_identity)
            _ = try transaction.register(preparedSourceRequest(
                "replacement",
                .{ .int = 64 },
                .gpr64,
                .gpr64,
            ));
        try transaction.seal();
        try transaction.prepare();
        switch (mutation) {
            .request_identity => transaction.requests[0].source = transaction.requests[1].source,
            .instruction_position => selector.current_position = 3,
            .definition_position => plan.forward_values.getPtr("forward").?.definition_position = 9,
            .interval_end => plan.interval_ends.getPtr("forward").?.* = 11,
            .virtual_class => {
                plan.forward_values.getPtr("forward").?.metadata.class = .gpr32;
                plan.assignments.getPtr("forward").?.* = .{ .gpr32 = .r9 };
            },
            .defined_width => plan.forward_values.getPtr("forward").?.metadata.bits = 63,
            .assignment_tag => plan.assignments.getPtr("forward").?.* = .{ .spill = 0 },
            .assignment_payload => plan.assignments.getPtr("forward").?.* = .{ .gpr64 = .r8 },
            .spill_frame_extent => selector.stack_frame_bytes = 0,
            .entry_removed => _ = plan.forward_values.remove("forward"),
        }
        try std.testing.expectError(error.ValueUseForwardPlanStale, transaction.materializeAll());
        try std.testing.expect(transaction.failedRequestIs(handle));
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expect(selector.values.get("forward") == null);
    }
}

test "value-use forward snapshot rejects allocation-plan replacement" {
    var machine = MachineFunction.init("forward-plan-replacement", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var admitted_plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer admitted_plan.deinit();
    try installForward(&admitted_plan, "forward", 8, 10, .gpr64, 64, .{ .gpr64 = .r9 });
    var replacement_plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer replacement_plan.deinit();
    try installForward(&replacement_plan, "forward", 8, 10, .gpr64, 64, .{ .gpr64 = .r9 });
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &admitted_plan;
    selector.current_position = 2;

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const handle = try registerForwardGpr64(&transaction, "forward", .rax);
    try transaction.seal();
    try transaction.prepare();
    selector.allocation_plan = &replacement_plan;
    try std.testing.expectError(error.ValueUseForwardPlanStale, transaction.materializeAll());
    try std.testing.expect(transaction.failedRequestIs(handle));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "value-use forward snapshot captures canonical dependency facts and rejects mutation" {
    var machine = MachineFunction.init("forward-dependency-snapshot", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try installForward(&plan, "forward", 8, 10, .gpr64, 64, .{ .gpr64 = .r9 });
    inline for (&.{ "owner", "index", "replacement-index" }) |name| try addLive(&plan, name);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 2;
    try selector_state.bindValueLoc(&selector, "index", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "replacement-index", .{ .arg64 = .rsi });
    try selector_state.bindValueLoc(&selector, "owner", .{ .stack_i32_ptr = .{
        .disp = 8,
        .index = .{ .reg = .rdi, .name = "index" },
    } });

    {
        var unchanged = try Transaction.begin(&selector);
        defer unchanged.deinit();
        _ = try registerForwardGpr64(&unchanged, "forward", .rax);
        try unchanged.seal();
        try unchanged.prepare();
        try unchanged.materializeAll();
        try unchanged.rollback();
    }

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const handle = try registerForwardGpr64(&transaction, "forward", .rax);
    try transaction.seal();
    try transaction.prepare();
    try selector_state.bindValueLoc(&selector, "owner", .{ .stack_i32_ptr = .{
        .disp = 8,
        .index = .{ .reg = .rsi, .name = "replacement-index" },
    } });
    try std.testing.expectError(error.ValueUseForwardPlanStale, transaction.materializeAll());
    try std.testing.expect(transaction.failedRequestIs(handle));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "value-use forward malformed dependency metadata is a closed request error" {
    var machine = MachineFunction.init("forward-malformed-dependency", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try installForward(&plan, "forward", 8, 10, .gpr64, 64, .{ .gpr64 = .r9 });
    try addLive(&plan, "owner");
    try addLive(&plan, "index");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 2;
    try selector_state.bindValueLoc(&selector, "index", .{ .arg64 = .rdi });
    try selector.address_dependencies.replaceAddress("owner", &.{
        .{ .name = "index", .identity_type = .integer, .role = .index },
    });

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const handle = try registerForwardGpr64(&transaction, "forward", .rax);
    try std.testing.expectError(error.ValueUseForwardPlanMalformed, transaction.seal());
    try std.testing.expect(transaction.failedRequestIs(handle));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "value-use forward snapshot capacity fails closed" {
    var machine = MachineFunction.init("forward-dependency-capacity", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try installForward(&plan, "forward", 8, 10, .gpr64, 64, .{ .gpr64 = .r9 });
    try addLive(&plan, "index");
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 2;
    try selector_state.bindValueLoc(&selector, "index", .{ .arg64 = .rdi });
    inline for (0..5) |owner_index| {
        const owner = std.fmt.comptimePrint("owner-{d}", .{owner_index});
        try addLive(&plan, owner);
        try selector_state.bindValueLoc(&selector, owner, .{ .stack_i32_ptr = .{
            .disp = @intCast(owner_index * 4),
            .index = .{ .reg = .rdi, .name = "index" },
        } });
    }

    var transaction = try Transaction.begin(&selector);
    defer transaction.deinit();
    const handle = try registerForwardGpr64(&transaction, "forward", .rax);
    try std.testing.expectError(
        error.ValueUseForwardSnapshotCapacityExceeded,
        transaction.seal(),
    );
    try std.testing.expect(transaction.failedRequestIs(handle));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "value-use forward duplicate requests and first-failure provenance remain exact" {
    var machine = MachineFunction.init("forward-duplicate-provenance", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try installForward(&plan, "forward", 8, 10, .gpr64, 64, .{ .gpr64 = .r9 });
    try plan.forward_values.put("broken", .{
        .definition_position = 8,
        .metadata = .{ .class = .gpr64, .bits = 64 },
    });
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 2;

    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        _ = try registerForwardGpr64(&transaction, "forward", .rax);
        _ = try registerForwardGpr64(&transaction, "forward", .{ .gpr64 = .rcx });
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.rollback();
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        const first = try registerForwardGpr64(&transaction, "forward", .rax);
        const second = try registerForwardGpr64(&transaction, "broken", .{ .gpr64 = .rcx });
        try std.testing.expectError(error.ValueUseForwardPlanMissing, transaction.seal());
        try std.testing.expect(!transaction.failedRequestIs(first));
        try std.testing.expect(transaction.failedRequestIs(second));
    }
}

test "value-use forward snapshot rollback and teardown retain no binding or snapshot state" {
    var machine = MachineFunction.init("forward-rollback-teardown", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try installForward(&plan, "forward", 8, 10, .gpr64, 64, .{ .gpr64 = .r9 });
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 2;

    {
        var transaction = try Transaction.begin(&selector);
        defer transaction.deinit();
        _ = try registerForwardGpr64(&transaction, "forward", .rax);
        try transaction.seal();
        try std.testing.expect(transaction.lifetime_context.forward_snapshots[0] != null);
        try transaction.rollback();
        try std.testing.expect(transaction.lifetime_context.forward_snapshots[0] == null);
    }
    {
        var transaction = try Transaction.begin(&selector);
        _ = try registerForwardGpr64(&transaction, "forward", .rax);
        try transaction.seal();
        try transaction.prepare();
        try transaction.materializeAll();
        try transaction.rollback();
        transaction.deinit();
    }
    try std.testing.expect(selector.values.get("forward") == null);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
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
