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
        try std.testing.expectError(error.ValueUseForwardPlanMissing, transaction.seal());
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
