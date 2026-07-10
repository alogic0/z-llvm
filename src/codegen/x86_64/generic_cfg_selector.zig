const std = @import("std");
const ir = @import("../../ir.zig");
const x86_64_machine = @import("machine.zig");
const x86_64_types = @import("types.zig");

pub const MachineFunction = x86_64_machine.MachineFunction;
const ArgReg = x86_64_types.ArgReg;
const FrameIndex = x86_64_types.FrameIndex;
const MachineBinaryOp = x86_64_types.MachineBinaryOp;

pub const Diagnostic = union(enum) {
    unsupported_control_flow: []const u8,
    unsupported_instruction: []const u8,
    unsupported_type: []const u8,
    unsupported_value: []const u8,
    no_spill_envelope: []const u8,
    no_emitter: []const u8,

    pub fn tagName(diagnostic: Diagnostic) []const u8 {
        return @tagName(diagnostic);
    }

    pub fn detail(diagnostic: Diagnostic) []const u8 {
        return switch (diagnostic) {
            inline else => |detail_text| detail_text,
        };
    }
};

pub const SelectionResult = union(enum) {
    selected,
    unsupported: Diagnostic,
};

pub const StageTwoSummary = struct {
    blocks: usize,
    edges: usize,
    max_live_in: usize,
    max_live_out: usize,
    max_pressure: usize,
    no_spill_limit: usize,
    spill_slot_count: usize,
    spill_envelope_limit: usize,
    max_pressure_block: []const u8,
    max_pressure_boundary: []const u8,
    max_pressure_spill_slots_needed: usize,
    max_pressure_spill_slots_over_envelope: usize,
    first_exceeding_block: []const u8,
    first_exceeding_boundary: []const u8,
    first_exceeding_live_values: usize,
    first_exceeding_spill_slots_needed: usize,
    first_exceeding_spill_slots_over_envelope: usize,

    pub fn exceedsNoSpill(summary: StageTwoSummary) bool {
        return summary.max_pressure > summary.no_spill_limit;
    }

    pub fn exceedsSpillEnvelope(summary: StageTwoSummary) bool {
        return summary.max_pressure > summary.spill_envelope_limit;
    }
};

const no_spill_register_values = 6;
const stage2_spill_slots = 7;
const stage2_max_blocks = 64;
const phi_regs = [_]ArgReg{ .r8, .r9, .rcx };

pub fn tryLower(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !SelectionResult {
    const inspected = inspectFunction(function);
    if (matchesMuloLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .mulo_limb64_rdi_rsi_rdx_cl_r8w_al);
        return .selected;
    }
    if (matchesByteswapLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .byteswap_limb64_rdi_rsi_dl_cx);
        return .selected;
    }
    if (matchesShrLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .shr_limb64_rdi_rsi_dx_cl_r8w);
        return .selected;
    }
    if (matchesShloLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .shlo_limb64_rdi_rsi_dx_cl_r8w_al);
        return .selected;
    }
    if (matchesNotLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .not_limb64_rdi_rsi_dl_cx);
        return .selected;
    }
    if (matchesBitwiseLimb64Envelope(function)) |op| {
        try machine.instructions.append(allocator, .{ .bitwise_limb64_rdi_rsi_rdx_cx = op });
        return .selected;
    }
    if (matchesCmpLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .cmp_limb64_rdi_rsi_dl_cx_ax);
        return .selected;
    }
    if (matchesOverflowLimb64Envelope(function)) |op| {
        try machine.instructions.append(allocator, .{ .overflow_limb64_rdi_rsi_rdx_cl_r8w_al = op });
        return .selected;
    }
    if (matchesBitreverseLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .bitreverse_limb64_rdi_rsi_dl_cx);
        return .selected;
    }
    if (matchesPopcountLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .popcount_limb64_rdi_si_ax);
        return .selected;
    }
    if (matchesCtzLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .ctz_limb64_rdi_si_ax);
        return .selected;
    }
    if (matchesClzLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .clz_limb64_rdi_si_ax);
        return .selected;
    }
    if (matchesUdivei4Envelope(function)) {
        try machine.instructions.append(allocator, .udivei4_before_intbytesize);
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "zig.target.intByteSize", .ret_ty = .{ .int = 16 } } });
        try machine.instructions.append(allocator, .udivei4_between_intbytesize_and_memset);
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "memset", .ret_ty = .ptr } });
        try machine.instructions.append(allocator, .udivei4_after_memset);
        return .selected;
    }
    if (matchesUmodei5Envelope(function)) {
        try machine.instructions.append(allocator, .umodei5_before_intbytesize);
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "zig.target.intByteSize", .ret_ty = .{ .int = 16 } } });
        try machine.instructions.append(allocator, .umodei5_between_intbytesize_and_memset);
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "memset", .ret_ty = .ptr } });
        try machine.instructions.append(allocator, .umodei5_after_memset_before_memcpy);
        try machine.instructions.append(allocator, .{ .direct_jump = "memcpy" });
        try machine.instructions.append(allocator, .umodei5_after_memcpy);
        return .selected;
    }
    switch (inspected) {
        .selected => unreachable,
        .unsupported => |diagnostic| switch (diagnostic) {
            .no_emitter => {},
            .unsupported_instruction => |detail| {
                if (!std.mem.eql(u8, detail, "udiv") and
                    !std.mem.eql(u8, detail, "urem"))
                {
                    return inspected;
                }
            },
            .unsupported_control_flow => {
                if (function.blocks.items.len > 1) {
                    const stage_two = try analyzeStageTwoNoSpillEnvelope(allocator, function);
                    if (stage_two.exceedsSpillEnvelope()) return .{ .unsupported = .{ .no_spill_envelope = "stage2-register-pressure" } };
                    return tryLowerComposedCfgFailClosed(allocator, machine, function);
                }
                return inspected;
            },
            else => return inspected,
        },
    }
    if (function.blocks.items.len > 1) {
        const stage_two = try analyzeStageTwoNoSpillEnvelope(allocator, function);
        if (stage_two.exceedsSpillEnvelope()) return .{ .unsupported = .{ .no_spill_envelope = "stage2-register-pressure" } };
        return tryLowerComposedCfgFailClosed(allocator, machine, function);
    }
    const composed_start_len = machine.instructions.items.len;
    switch (try tryLowerComposedBlockFailClosed(allocator, machine, function)) {
        .selected => return .selected,
        .unsupported => |diagnostic| switch (diagnostic) {
            .no_emitter => {
                machine.instructions.items.len = composed_start_len;
                if (shouldReportComposedNoEmitter(inspected)) return .{ .unsupported = diagnostic };
            },
            else => {
                machine.instructions.items.len = composed_start_len;
                return .{ .unsupported = diagnostic };
            },
        },
    }
    return inspected;
}

fn shouldReportComposedNoEmitter(inspected: SelectionResult) bool {
    return switch (inspected) {
        .selected => false,
        .unsupported => |diagnostic| switch (diagnostic) {
            .no_emitter => |detail| std.mem.eql(u8, detail, "selector-skeleton-has-no-emitters"),
            .unsupported_control_flow, .unsupported_instruction, .unsupported_type, .unsupported_value, .no_spill_envelope => false,
        },
    };
}

fn tryLowerComposedBlockFailClosed(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !SelectionResult {
    const start_len = machine.instructions.items.len;
    const result = tryLowerComposedBlock(allocator, machine, function) catch |err| {
        machine.instructions.items.len = start_len;
        return switch (err) {
            error.UnsupportedCodegenValue => unsupported(.{ .unsupported_value = "composed-block-unsupported-value" }),
            else => err,
        };
    };
    switch (result) {
        .selected => {},
        .unsupported => machine.instructions.items.len = start_len,
    }
    return result;
}

fn tryLowerComposedCfgFailClosed(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !SelectionResult {
    const start_len = machine.instructions.items.len;
    const result = tryLowerComposedCfg(allocator, machine, function) catch |err| {
        machine.instructions.items.len = start_len;
        return switch (err) {
            error.UnsupportedCodegenValue => unsupported(.{ .unsupported_value = "stage2-unsupported-value" }),
            else => err,
        };
    };
    switch (result) {
        .selected => {},
        .unsupported => machine.instructions.items.len = start_len,
    }
    return result;
}

fn tryLowerComposedCfg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !SelectionResult {
    if (!isComposedReturnType(function.ret_ty)) return unsupported(.{ .no_emitter = "stage2-ret-type" });
    if (function.blocks.items.len == 0) return unsupported(.{ .unsupported_control_flow = "stage2-empty-function" });
    if (function.blocks.items.len > stage2_max_blocks) return unsupported(.{ .no_spill_envelope = "stage2-block-count" });

    var allocation_plan = try buildSelectorAllocationPlan(allocator, function);
    defer allocation_plan.deinit();

    const start_len = machine.instructions.items.len;
    var composed = ComposedBlockSelector.init(allocator, machine);
    composed.allocation_plan = &allocation_plan;
    composed.enable_expired_plan_register_reuse = canUseExpiredPlanRegisterReuse(function);
    defer composed.deinit();

    if (try composed.bindParams(function)) |diagnostic| return unsupported(diagnostic);
    if (try composed.bindPhiResults(function)) |diagnostic| return unsupported(diagnostic);
    if (try composed.prepareStackFrame(function)) |diagnostic| return unsupported(diagnostic);

    for (function.blocks.items, 0..) |block, block_index| {
        if (block_index != 0) try machine.instructions.append(allocator, .{ .label = block.name });
        if (try composed.enterBlock(block)) |diagnostic| {
            machine.instructions.items.len = start_len;
            return unsupported(diagnostic);
        }
        for (block.instructions.items) |instruction| {
            if (try composed.lowerInstruction(instruction)) |diagnostic| {
                machine.instructions.items.len = start_len;
                return unsupported(diagnostic);
            }
        }
        const terminator = block.terminator orelse {
            machine.instructions.items.len = start_len;
            return unsupported(.{ .unsupported_control_flow = "stage2-missing-terminator" });
        };
        try composed.expireExpiredBindings();
        if (try composed.lowerCfgTerminator(function, block_index, terminator)) |diagnostic| {
            machine.instructions.items.len = start_len;
            return unsupported(diagnostic);
        }
        composed.current_position += 1;
    }
    return .selected;
}

pub fn analyzeStageTwoNoSpillEnvelope(allocator: std.mem.Allocator, function: ir.Function) !StageTwoSummary {
    var liveness = try buildStageTwoLiveness(allocator, function);
    defer liveness.deinit();
    var pressure_exempt_values = NameSet.init(allocator);
    defer pressure_exempt_values.deinit();
    try collectPressureExemptValues(&pressure_exempt_values, function);

    if (liveness.blocks.items.len == 0) {
        return .{
            .blocks = 0,
            .edges = 0,
            .max_live_in = 0,
            .max_live_out = 0,
            .max_pressure = 0,
            .no_spill_limit = no_spill_register_values,
            .spill_slot_count = stage2_spill_slots,
            .spill_envelope_limit = no_spill_register_values + stage2_spill_slots,
            .max_pressure_block = "-",
            .max_pressure_boundary = "-",
            .max_pressure_spill_slots_needed = 0,
            .max_pressure_spill_slots_over_envelope = 0,
            .first_exceeding_block = "-",
            .first_exceeding_boundary = "-",
            .first_exceeding_live_values = 0,
            .first_exceeding_spill_slots_needed = 0,
            .first_exceeding_spill_slots_over_envelope = 0,
        };
    }

    var max_live_in: usize = 0;
    var max_live_out: usize = 0;
    var max_pressure_block: []const u8 = "-";
    var max_pressure_boundary: []const u8 = "-";
    var max_pressure_seen: usize = 0;
    var first_exceeding_block: []const u8 = "-";
    var first_exceeding_boundary: []const u8 = "-";
    var first_exceeding_live_values: usize = 0;
    var pressure_summary = PressureSummaryState{};
    for (liveness.blocks.items, 0..) |block, block_index| {
        const live_in_count = block.live_in.count();
        const live_out_count = block.live_out.count();
        if (live_in_count > max_live_in) max_live_in = live_in_count;
        if (live_out_count > max_live_out) max_live_out = live_out_count;
        pressure_summary.record(block.name, "live_in", live_in_count);
        try collectIntraBlockPressure(allocator, &pressure_summary, function.blocks.items[block_index], block, pressure_exempt_values);
        pressure_summary.record(block.name, "live_out", live_out_count);
    }
    max_pressure_seen = pressure_summary.max_live_values;
    max_pressure_block = pressure_summary.max_block;
    max_pressure_boundary = pressure_summary.max_boundary;
    first_exceeding_block = pressure_summary.first_exceeding_block;
    first_exceeding_boundary = pressure_summary.first_exceeding_boundary;
    first_exceeding_live_values = pressure_summary.first_exceeding_live_values;
    const max_pressure = max_pressure_seen;
    const max_spill_slots_needed = stage2SpillSlotsNeeded(max_pressure);
    const first_exceeding_spill_slots_needed = stage2SpillSlotsNeeded(first_exceeding_live_values);
    return .{
        .blocks = liveness.blocks.items.len,
        .edges = liveness.edge_count,
        .max_live_in = max_live_in,
        .max_live_out = max_live_out,
        .max_pressure = max_pressure,
        .no_spill_limit = no_spill_register_values,
        .spill_slot_count = stage2_spill_slots,
        .spill_envelope_limit = no_spill_register_values + stage2_spill_slots,
        .max_pressure_block = max_pressure_block,
        .max_pressure_boundary = max_pressure_boundary,
        .max_pressure_spill_slots_needed = max_spill_slots_needed,
        .max_pressure_spill_slots_over_envelope = stage2SpillSlotsOverEnvelope(max_spill_slots_needed),
        .first_exceeding_block = first_exceeding_block,
        .first_exceeding_boundary = first_exceeding_boundary,
        .first_exceeding_live_values = first_exceeding_live_values,
        .first_exceeding_spill_slots_needed = first_exceeding_spill_slots_needed,
        .first_exceeding_spill_slots_over_envelope = stage2SpillSlotsOverEnvelope(first_exceeding_spill_slots_needed),
    };
}

const PressureSummaryState = struct {
    max_live_values: usize = 0,
    max_block: []const u8 = "-",
    max_boundary: []const u8 = "-",
    first_exceeding_block: []const u8 = "-",
    first_exceeding_boundary: []const u8 = "-",
    first_exceeding_live_values: usize = 0,

    fn record(summary: *PressureSummaryState, block: []const u8, boundary: []const u8, live_values: usize) void {
        if (live_values > summary.max_live_values or std.mem.eql(u8, summary.max_block, "-")) {
            summary.max_live_values = live_values;
            summary.max_block = block;
            summary.max_boundary = boundary;
        }
        if (summary.first_exceeding_live_values == 0 and live_values > no_spill_register_values + stage2_spill_slots) {
            summary.first_exceeding_block = block;
            summary.first_exceeding_boundary = boundary;
            summary.first_exceeding_live_values = live_values;
        }
    }
};

const PressurePoint = struct {
    boundary: []const u8,
    live_values: usize,
};

fn collectIntraBlockPressure(
    allocator: std.mem.Allocator,
    summary: *PressureSummaryState,
    ir_block: ir.BasicBlock,
    stage_block: StageTwoBlock,
    pressure_exempt_values: NameSet,
) !void {
    var live = NameSet.init(allocator);
    defer live.deinit();
    try unionSet(&live, stage_block.live_out);

    var reverse_points: std.ArrayList(PressurePoint) = .empty;
    defer reverse_points.deinit(allocator);

    if (ir_block.terminator) |terminator| {
        var terminator_uses = NameSet.init(allocator);
        defer terminator_uses.deinit();
        try collectTerminatorNamedUses(&terminator_uses, terminator, pressure_exempt_values);
        try unionSet(&live, terminator_uses);
        try reverse_points.append(allocator, .{ .boundary = "terminator", .live_values = live.count() });
    }

    var instruction_index = ir_block.instructions.items.len;
    while (instruction_index > 0) {
        instruction_index -= 1;
        const instruction = ir_block.instructions.items[instruction_index];
        if (instruction.removed) continue;
        if (instruction.result) |result| {
            if (!pressure_exempt_values.contains(result)) _ = live.remove(result);
        }
        if (instruction.kind != .phi) {
            var instruction_uses = NameSet.init(allocator);
            defer instruction_uses.deinit();
            try collectInstructionNamedUses(&instruction_uses, instruction, pressure_exempt_values);
            try unionSet(&live, instruction_uses);
        }
        try reverse_points.append(allocator, .{
            .boundary = instructionPressureBoundary(instruction),
            .live_values = live.count(),
        });
    }

    var pressure_index = reverse_points.items.len;
    while (pressure_index > 0) {
        pressure_index -= 1;
        const point = reverse_points.items[pressure_index];
        summary.record(ir_block.name, point.boundary, point.live_values);
    }
}

fn buildStageTwoLiveness(allocator: std.mem.Allocator, function: ir.Function) !StageTwoLiveness {
    var pressure_exempt_values = NameSet.init(allocator);
    defer pressure_exempt_values.deinit();
    try collectPressureExemptValues(&pressure_exempt_values, function);

    var blocks: std.ArrayList(StageTwoBlock) = .empty;
    errdefer {
        for (blocks.items) |*block| block.deinit();
        blocks.deinit(allocator);
    }

    for (function.blocks.items) |block| {
        try blocks.append(allocator, StageTwoBlock.init(allocator, block.name));
    }

    if (blocks.items.len != 0) {
        for (function.params.items) |param| {
            try blocks.items[0].defs.put(param.name, {});
        }
    }

    var edge_count: usize = 0;
    for (function.blocks.items, 0..) |block, block_index| {
        try collectBlockUsesAndDefs(&blocks.items[block_index], block, pressure_exempt_values);
        const block_successors = try successors(block);
        for (block_successors.names[0..block_successors.len]) |successor_name| {
            if (successor_name.len == 0) continue;
            edge_count += 1;
            _ = function.blockIndex(successor_name) orelse return error.UnsupportedCodegenControlFlow;
        }
    }

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed or instruction.kind != .phi) continue;
            const phi = instruction.kind.phi;
            for (phi.incoming.items) |incoming| {
                const predecessor_index = function.blockIndex(incoming.block) orelse return error.UnsupportedCodegenControlFlow;
                try addNamedValue(&blocks.items[predecessor_index].phi_out, incoming.value);
            }
        }
    }

    var changed = true;
    while (changed) {
        changed = false;
        var reverse_index = blocks.items.len;
        while (reverse_index > 0) {
            reverse_index -= 1;
            var next_live_out = NameSet.init(allocator);
            defer next_live_out.deinit();
            try unionSet(&next_live_out, blocks.items[reverse_index].phi_out);
            const block_successors = try successors(function.blocks.items[reverse_index]);
            for (block_successors.names[0..block_successors.len]) |successor_name| {
                if (successor_name.len == 0) continue;
                const successor_index = function.blockIndex(successor_name) orelse return error.UnsupportedCodegenControlFlow;
                try unionSet(&next_live_out, blocks.items[successor_index].live_in);
            }

            var next_live_in = NameSet.init(allocator);
            defer next_live_in.deinit();
            try unionSet(&next_live_in, next_live_out);
            var def_it = blocks.items[reverse_index].defs.iterator();
            while (def_it.next()) |entry| {
                _ = next_live_in.remove(entry.key_ptr.*);
            }
            try unionSet(&next_live_in, blocks.items[reverse_index].uses);

            if (try replaceSet(&blocks.items[reverse_index].live_out, next_live_out)) changed = true;
            if (try replaceSet(&blocks.items[reverse_index].live_in, next_live_in)) changed = true;
        }
    }

    return .{
        .allocator = allocator,
        .blocks = blocks,
        .edge_count = edge_count,
    };
}

fn stage2SpillSlotsNeeded(live_values: usize) usize {
    return if (live_values > no_spill_register_values) live_values - no_spill_register_values else 0;
}

fn stage2SpillSlotsOverEnvelope(spill_slots_needed: usize) usize {
    return if (spill_slots_needed > stage2_spill_slots) spill_slots_needed - stage2_spill_slots else 0;
}

const NameSet = std.StringHashMap(void);

const StageTwoLiveness = struct {
    allocator: std.mem.Allocator,
    blocks: std.ArrayList(StageTwoBlock),
    edge_count: usize,

    fn deinit(liveness: *StageTwoLiveness) void {
        for (liveness.blocks.items) |*block| block.deinit();
        liveness.blocks.deinit(liveness.allocator);
    }
};

const StageTwoBlock = struct {
    name: []const u8,
    defs: NameSet,
    uses: NameSet,
    phi_out: NameSet,
    live_in: NameSet,
    live_out: NameSet,

    fn init(allocator: std.mem.Allocator, name: []const u8) StageTwoBlock {
        return .{
            .name = name,
            .defs = NameSet.init(allocator),
            .uses = NameSet.init(allocator),
            .phi_out = NameSet.init(allocator),
            .live_in = NameSet.init(allocator),
            .live_out = NameSet.init(allocator),
        };
    }

    fn deinit(block: *StageTwoBlock) void {
        block.defs.deinit();
        block.uses.deinit();
        block.phi_out.deinit();
        block.live_in.deinit();
        block.live_out.deinit();
    }
};

const SelectorValueInterval = struct {
    name: []const u8,
    class: VirtualRegClass,
    bits: u16,
    start: usize,
    end: usize,
};

const PlannedValueAssignment = union(enum) {
    gpr32: ArgReg,
    gpr64: ArgReg,
    gpr128: RegPair,
    stack_object,
    stack_pointer: ArgReg,
    spill: usize,
};

const SelectorAllocationPlan = struct {
    allocator: std.mem.Allocator,
    assignments: std.StringHashMap(PlannedValueAssignment),
    interval_ends: std.StringHashMap(usize),
    spill_slots: usize = 0,
    max_active_values: usize = 0,

    fn init(allocator: std.mem.Allocator) SelectorAllocationPlan {
        return .{
            .allocator = allocator,
            .assignments = std.StringHashMap(PlannedValueAssignment).init(allocator),
            .interval_ends = std.StringHashMap(usize).init(allocator),
        };
    }

    fn deinit(plan: *SelectorAllocationPlan) void {
        plan.interval_ends.deinit();
        plan.assignments.deinit();
    }

    fn assignment(plan: SelectorAllocationPlan, name: []const u8) ?PlannedValueAssignment {
        return plan.assignments.get(name);
    }

    fn intervalEnd(plan: SelectorAllocationPlan, name: []const u8) ?usize {
        return plan.interval_ends.get(name);
    }
};

const ActiveAllocation = struct {
    end: usize,
    assignment: PlannedValueAssignment,
};

fn buildSelectorAllocationPlan(allocator: std.mem.Allocator, function: ir.Function) !SelectorAllocationPlan {
    var pressure_exempt_values = NameSet.init(allocator);
    defer pressure_exempt_values.deinit();
    try collectPressureExemptValues(&pressure_exempt_values, function);

    var intervals: std.ArrayList(SelectorValueInterval) = .empty;
    defer intervals.deinit(allocator);

    var interval_indexes = std.StringHashMap(usize).init(allocator);
    defer interval_indexes.deinit();

    var position: usize = 0;
    for (function.params.items) |param| {
        const metadata = selectorValueMetadata(param.ty) orelse return error.UnsupportedCodegenValue;
        try recordSelectorIntervalDef(allocator, &intervals, &interval_indexes, param.name, metadata, position);
    }

    position = 1;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.result) |result| {
                if (!pressure_exempt_values.contains(result)) {
                    const metadata = selectorInstructionResultMetadata(instruction) orelse return error.UnsupportedCodegenValue;
                    try recordSelectorIntervalDef(allocator, &intervals, &interval_indexes, result, metadata, position);
                }
            }
            position += 1;
        }
        if (block.terminator != null) position += 1;
    }

    position = 1;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            var uses = NameSet.init(allocator);
            defer uses.deinit();
            if (instruction.kind == .phi) {
                for (instruction.kind.phi.incoming.items) |incoming| {
                    try addNamedPressureUse(&uses, incoming.value, pressure_exempt_values);
                }
            } else {
                try collectInstructionNamedUses(&uses, instruction, pressure_exempt_values);
            }
            try recordSelectorIntervalUses(intervals.items, interval_indexes, uses, position);
            position += 1;
        }
        if (block.terminator) |terminator| {
            var uses = NameSet.init(allocator);
            defer uses.deinit();
            try collectTerminatorNamedUses(&uses, terminator, pressure_exempt_values);
            try recordSelectorIntervalUses(intervals.items, interval_indexes, uses, position);
            position += 1;
        }
    }

    return try allocateSelectorIntervals(allocator, intervals.items);
}

fn selectorValueMetadata(ty: ir.Type) ?VirtualRegMetadata {
    if (ty == .ptr) return .{ .class = .gpr64, .bits = 64 };
    const bits = intBits(ty) orelse return null;
    return switch (bits) {
        1...32 => .{ .class = .gpr32, .bits = 32 },
        33...64 => .{ .class = .gpr64, .bits = 64 },
        65...128 => .{ .class = .gpr128, .bits = 128 },
        else => null,
    };
}

fn selectorInstructionResultMetadata(instruction: ir.Instruction) ?VirtualRegMetadata {
    return switch (instruction.kind) {
        .binary => |binary| selectorValueMetadata(binary.ty),
        .cast => |cast| selectorValueMetadata(cast.to_ty),
        .freeze => |freeze| selectorValueMetadata(freeze.ty),
        .icmp => .{ .class = .gpr32, .bits = 32 },
        .load => |load| selectorValueMetadata(load.ty),
        .call => |call| if (call.ret_ty == .void) null else selectorValueMetadata(call.ret_ty),
        .select => |select| selectorValueMetadata(select.ty),
        .phi => |phi| selectorValueMetadata(phi.ty),
        .gep => .{ .class = .stack_pointer, .bits = 64 },
        .alloca => .{ .class = .stack_object, .bits = 0 },
        .store,
        .atomicrmw,
        .cmpxchg,
        .extractelement,
        .insertelement,
        .shufflevector,
        .extractvalue,
        .insertvalue,
        .fcmp,
        .fence,
        => null,
    };
}

fn recordSelectorIntervalDef(
    allocator: std.mem.Allocator,
    intervals: *std.ArrayList(SelectorValueInterval),
    interval_indexes: *std.StringHashMap(usize),
    name: []const u8,
    metadata: VirtualRegMetadata,
    position: usize,
) !void {
    if (interval_indexes.get(name)) |index| {
        intervals.items[index].start = @min(intervals.items[index].start, position);
        intervals.items[index].end = @max(intervals.items[index].end, position);
        return;
    }
    const index = intervals.items.len;
    try intervals.append(allocator, .{
        .name = name,
        .class = metadata.class,
        .bits = metadata.bits,
        .start = position,
        .end = position,
    });
    try interval_indexes.put(name, index);
}

fn recordSelectorIntervalUses(
    intervals: []SelectorValueInterval,
    interval_indexes: std.StringHashMap(usize),
    uses: NameSet,
    position: usize,
) !void {
    var it = uses.iterator();
    while (it.next()) |entry| {
        const index = interval_indexes.get(entry.key_ptr.*) orelse return error.UnsupportedCodegenValue;
        intervals[index].end = @max(intervals[index].end, position);
    }
}

fn allocateSelectorIntervals(allocator: std.mem.Allocator, intervals: []const SelectorValueInterval) !SelectorAllocationPlan {
    var ordered: std.ArrayList(SelectorValueInterval) = .empty;
    defer ordered.deinit(allocator);
    try ordered.appendSlice(allocator, intervals);
    std.mem.sort(SelectorValueInterval, ordered.items, {}, selectorIntervalLessThan);

    var plan = SelectorAllocationPlan.init(allocator);
    errdefer plan.deinit();

    var active: std.ArrayList(ActiveAllocation) = .empty;
    defer active.deinit(allocator);

    var occupied = [_]bool{false} ** 6;
    for (ordered.items) |interval| {
        expireSelectorIntervals(&active, &occupied, interval.start);
        const assignment = allocateSelectorInterval(&occupied, interval, plan.spill_slots);
        if (std.meta.activeTag(assignment) == .spill) plan.spill_slots += selectorSpillSlotCount(interval);
        try plan.assignments.put(interval.name, assignment);
        try plan.interval_ends.put(interval.name, interval.end);
        if (assignmentUsesRegisters(assignment)) {
            try active.append(allocator, .{ .end = interval.end, .assignment = assignment });
            if (active.items.len > plan.max_active_values) plan.max_active_values = active.items.len;
        }
    }
    return plan;
}

fn selectorSpillSlotCount(interval: SelectorValueInterval) usize {
    return if (interval.bits > 64) 2 else 1;
}

fn selectorIntervalLessThan(_: void, lhs: SelectorValueInterval, rhs: SelectorValueInterval) bool {
    if (lhs.start != rhs.start) return lhs.start < rhs.start;
    return std.mem.lessThan(u8, lhs.name, rhs.name);
}

fn expireSelectorIntervals(active: *std.ArrayList(ActiveAllocation), occupied: *[6]bool, position: usize) void {
    var index: usize = 0;
    while (index < active.items.len) {
        if (active.items[index].end < position) {
            releaseSelectorAssignment(occupied, active.items[index].assignment);
            _ = active.swapRemove(index);
            continue;
        }
        index += 1;
    }
}

fn allocateSelectorInterval(occupied: *[6]bool, interval: SelectorValueInterval, next_spill_slot: usize) PlannedValueAssignment {
    return switch (interval.class) {
        .gpr32 => if (allocateSelectorReg(occupied)) |reg| .{ .gpr32 = reg } else .{ .spill = next_spill_slot },
        .gpr64 => if (allocateSelectorReg(occupied)) |reg| .{ .gpr64 = reg } else .{ .spill = next_spill_slot },
        .gpr128 => if (allocateSelectorPair(occupied)) |pair| .{ .gpr128 = pair } else .{ .spill = next_spill_slot },
        .stack_object => .stack_object,
        .stack_pointer => if (allocateSelectorReg(occupied)) |reg| .{ .stack_pointer = reg } else .{ .spill = next_spill_slot },
    };
}

fn allocateSelectorReg(occupied: *[6]bool) ?ArgReg {
    for (selector_allocatable_regs) |reg| {
        const index = argRegIndex(reg);
        if (!occupied[index]) {
            occupied[index] = true;
            return reg;
        }
    }
    return null;
}

fn allocateSelectorPair(occupied: *[6]bool) ?RegPair {
    for (selector_allocatable_pairs) |pair| {
        const lo = argRegIndex(pair.lo);
        const hi = argRegIndex(pair.hi);
        if (!occupied[lo] and !occupied[hi]) {
            occupied[lo] = true;
            occupied[hi] = true;
            return pair;
        }
    }
    return null;
}

fn releaseSelectorAssignment(occupied: *[6]bool, assignment: PlannedValueAssignment) void {
    switch (assignment) {
        .gpr32, .gpr64, .stack_pointer => |reg| occupied[argRegIndex(reg)] = false,
        .gpr128 => |pair| {
            occupied[argRegIndex(pair.lo)] = false;
            occupied[argRegIndex(pair.hi)] = false;
        },
        .stack_object, .spill => {},
    }
}

fn assignmentUsesRegisters(assignment: PlannedValueAssignment) bool {
    return switch (assignment) {
        .gpr32, .gpr64, .gpr128, .stack_pointer => true,
        .stack_object, .spill => false,
    };
}

fn collectPressureExemptValues(exempt_values: *NameSet, function: ir.Function) !void {
    var changed = true;
    while (changed) {
        changed = false;
        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                if (instruction.removed) continue;
                const result = instruction.result orelse continue;
                switch (instruction.kind) {
                    .alloca => {
                        if (!exempt_values.contains(result)) {
                            try exemptValuesPut(exempt_values, result);
                            changed = true;
                        }
                    },
                    .gep => |gep| {
                        const ptr_name = namedValue(gep.ptr) orelse continue;
                        if (exempt_values.contains(ptr_name) and !exempt_values.contains(result)) {
                            try exemptValuesPut(exempt_values, result);
                            changed = true;
                        }
                    },
                    else => {},
                }
            }
        }
    }
}

fn exemptValuesPut(exempt_values: *NameSet, name: []const u8) !void {
    try exempt_values.put(name, {});
}

fn collectBlockUsesAndDefs(stage_block: *StageTwoBlock, block: ir.BasicBlock, pressure_exempt_values: NameSet) !void {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        if (instruction.kind != .phi) try collectInstructionUses(stage_block, instruction, pressure_exempt_values);
        if (instruction.result) |result| try stage_block.defs.put(result, {});
    }
    if (block.terminator) |terminator| try collectTerminatorUses(stage_block, terminator, pressure_exempt_values);
}

fn collectInstructionUses(stage_block: *StageTwoBlock, instruction: ir.Instruction, pressure_exempt_values: NameSet) !void {
    switch (instruction.kind) {
        .binary => |binary| {
            try addBlockUse(stage_block, binary.lhs, pressure_exempt_values);
            try addBlockUse(stage_block, binary.rhs, pressure_exempt_values);
        },
        .cast => |cast| try addBlockUse(stage_block, cast.value, pressure_exempt_values),
        .freeze => |freeze| try addBlockUse(stage_block, freeze.value, pressure_exempt_values),
        .icmp => |icmp| {
            try addBlockUse(stage_block, icmp.lhs, pressure_exempt_values);
            try addBlockUse(stage_block, icmp.rhs, pressure_exempt_values);
        },
        .fcmp => |fcmp| {
            try addBlockUse(stage_block, fcmp.lhs, pressure_exempt_values);
            try addBlockUse(stage_block, fcmp.rhs, pressure_exempt_values);
        },
        .select => |select| {
            try addBlockUse(stage_block, select.cond, pressure_exempt_values);
            try addBlockUse(stage_block, select.true_value, pressure_exempt_values);
            try addBlockUse(stage_block, select.false_value, pressure_exempt_values);
        },
        .phi => {},
        .alloca, .fence => {},
        .load => |load| try addBlockUse(stage_block, load.ptr, pressure_exempt_values),
        .store => |store| {
            try addBlockUse(stage_block, store.value, pressure_exempt_values);
            try addBlockUse(stage_block, store.ptr, pressure_exempt_values);
        },
        .atomicrmw => |atomicrmw| {
            try addBlockUse(stage_block, atomicrmw.ptr, pressure_exempt_values);
            try addBlockUse(stage_block, atomicrmw.value, pressure_exempt_values);
        },
        .cmpxchg => |cmpxchg| {
            try addBlockUse(stage_block, cmpxchg.ptr, pressure_exempt_values);
            try addBlockUse(stage_block, cmpxchg.expected, pressure_exempt_values);
            try addBlockUse(stage_block, cmpxchg.replacement, pressure_exempt_values);
        },
        .extractelement => |extract| {
            try addBlockUse(stage_block, extract.vector, pressure_exempt_values);
            try addBlockUse(stage_block, extract.index, pressure_exempt_values);
        },
        .insertelement => |insert| {
            try addBlockUse(stage_block, insert.vector, pressure_exempt_values);
            try addBlockUse(stage_block, insert.value, pressure_exempt_values);
            try addBlockUse(stage_block, insert.index, pressure_exempt_values);
        },
        .shufflevector => |shuffle| {
            try addBlockUse(stage_block, shuffle.lhs, pressure_exempt_values);
            try addBlockUse(stage_block, shuffle.rhs, pressure_exempt_values);
            try addBlockUse(stage_block, shuffle.mask, pressure_exempt_values);
        },
        .extractvalue => |extract| try addBlockUse(stage_block, extract.aggregate, pressure_exempt_values),
        .insertvalue => |insert| {
            try addBlockUse(stage_block, insert.aggregate, pressure_exempt_values);
            try addBlockUse(stage_block, insert.value, pressure_exempt_values);
        },
        .gep => |gep| {
            try addBlockUse(stage_block, gep.ptr, pressure_exempt_values);
            for (gep.indices.items) |index| try addBlockUse(stage_block, index.value, pressure_exempt_values);
        },
        .call => |call| {
            if (call.isDebugVariableLocation()) return;
            if (call.callee_value) |callee| try addBlockUse(stage_block, callee, pressure_exempt_values);
            for (call.args.items) |arg| try addBlockUse(stage_block, arg.value, pressure_exempt_values);
        },
    }
}

fn collectTerminatorUses(stage_block: *StageTwoBlock, terminator: ir.Terminator, pressure_exempt_values: NameSet) !void {
    switch (terminator) {
        .ret => |ret| if (ret.value) |value| try addBlockUse(stage_block, value, pressure_exempt_values),
        .br => {},
        .condbr => |condbr| try addBlockUse(stage_block, condbr.cond, pressure_exempt_values),
        .@"switch" => |switch_term| {
            try addBlockUse(stage_block, switch_term.cond, pressure_exempt_values);
            for (switch_term.cases.items) |case| try addBlockUse(stage_block, case.value, pressure_exempt_values);
        },
        .indirectbr => |indirectbr| try addBlockUse(stage_block, indirectbr.addr, pressure_exempt_values),
        .@"unreachable" => {},
    }
}

fn collectInstructionNamedUses(uses: *NameSet, instruction: ir.Instruction, pressure_exempt_values: NameSet) !void {
    switch (instruction.kind) {
        .binary => |binary| {
            try addNamedPressureUse(uses, binary.lhs, pressure_exempt_values);
            try addNamedPressureUse(uses, binary.rhs, pressure_exempt_values);
        },
        .cast => |cast| try addNamedPressureUse(uses, cast.value, pressure_exempt_values),
        .freeze => |freeze| try addNamedPressureUse(uses, freeze.value, pressure_exempt_values),
        .icmp => |icmp| {
            try addNamedPressureUse(uses, icmp.lhs, pressure_exempt_values);
            try addNamedPressureUse(uses, icmp.rhs, pressure_exempt_values);
        },
        .fcmp => |fcmp| {
            try addNamedPressureUse(uses, fcmp.lhs, pressure_exempt_values);
            try addNamedPressureUse(uses, fcmp.rhs, pressure_exempt_values);
        },
        .select => |select| {
            try addNamedPressureUse(uses, select.cond, pressure_exempt_values);
            try addNamedPressureUse(uses, select.true_value, pressure_exempt_values);
            try addNamedPressureUse(uses, select.false_value, pressure_exempt_values);
        },
        .phi => {},
        .alloca, .fence => {},
        .load => |load| try addNamedPressureUse(uses, load.ptr, pressure_exempt_values),
        .store => |store| {
            try addNamedPressureUse(uses, store.value, pressure_exempt_values);
            try addNamedPressureUse(uses, store.ptr, pressure_exempt_values);
        },
        .atomicrmw => |atomicrmw| {
            try addNamedPressureUse(uses, atomicrmw.ptr, pressure_exempt_values);
            try addNamedPressureUse(uses, atomicrmw.value, pressure_exempt_values);
        },
        .cmpxchg => |cmpxchg| {
            try addNamedPressureUse(uses, cmpxchg.ptr, pressure_exempt_values);
            try addNamedPressureUse(uses, cmpxchg.expected, pressure_exempt_values);
            try addNamedPressureUse(uses, cmpxchg.replacement, pressure_exempt_values);
        },
        .extractelement => |extract| {
            try addNamedPressureUse(uses, extract.vector, pressure_exempt_values);
            try addNamedPressureUse(uses, extract.index, pressure_exempt_values);
        },
        .insertelement => |insert| {
            try addNamedPressureUse(uses, insert.vector, pressure_exempt_values);
            try addNamedPressureUse(uses, insert.value, pressure_exempt_values);
            try addNamedPressureUse(uses, insert.index, pressure_exempt_values);
        },
        .shufflevector => |shuffle| {
            try addNamedPressureUse(uses, shuffle.lhs, pressure_exempt_values);
            try addNamedPressureUse(uses, shuffle.rhs, pressure_exempt_values);
            try addNamedPressureUse(uses, shuffle.mask, pressure_exempt_values);
        },
        .extractvalue => |extract| try addNamedPressureUse(uses, extract.aggregate, pressure_exempt_values),
        .insertvalue => |insert| {
            try addNamedPressureUse(uses, insert.aggregate, pressure_exempt_values);
            try addNamedPressureUse(uses, insert.value, pressure_exempt_values);
        },
        .gep => |gep| {
            try addNamedPressureUse(uses, gep.ptr, pressure_exempt_values);
            for (gep.indices.items) |index| try addNamedPressureUse(uses, index.value, pressure_exempt_values);
        },
        .call => |call| {
            if (call.isDebugVariableLocation()) return;
            if (call.callee_value) |callee| try addNamedPressureUse(uses, callee, pressure_exempt_values);
            for (call.args.items) |arg| try addNamedPressureUse(uses, arg.value, pressure_exempt_values);
        },
    }
}

fn collectTerminatorNamedUses(uses: *NameSet, terminator: ir.Terminator, pressure_exempt_values: NameSet) !void {
    switch (terminator) {
        .ret => |ret| if (ret.value) |value| try addNamedPressureUse(uses, value, pressure_exempt_values),
        .br => {},
        .condbr => |condbr| try addNamedPressureUse(uses, condbr.cond, pressure_exempt_values),
        .@"switch" => |switch_term| {
            try addNamedPressureUse(uses, switch_term.cond, pressure_exempt_values);
            for (switch_term.cases.items) |case| try addNamedPressureUse(uses, case.value, pressure_exempt_values);
        },
        .indirectbr => |indirectbr| try addNamedPressureUse(uses, indirectbr.addr, pressure_exempt_values),
        .@"unreachable" => {},
    }
}

fn instructionPressureBoundary(instruction: ir.Instruction) []const u8 {
    return instruction.result orelse @tagName(instruction.kind);
}

fn addNamedPressureUse(set: *NameSet, value: ir.Value, pressure_exempt_values: NameSet) !void {
    const name = namedValue(value) orelse return;
    if (pressure_exempt_values.contains(name)) return;
    try set.put(name, {});
}

fn addBlockUse(stage_block: *StageTwoBlock, value: ir.Value, pressure_exempt_values: NameSet) !void {
    const name = namedValue(value) orelse return;
    if (pressure_exempt_values.contains(name)) return;
    if (stage_block.defs.contains(name)) return;
    try stage_block.uses.put(name, {});
}

fn addNamedValue(set: *NameSet, value: ir.Value) !void {
    const name = namedValue(value) orelse return;
    try set.put(name, {});
}

fn namedValue(value: ir.Value) ?[]const u8 {
    return switch (value) {
        .named => |name| if (std.mem.startsWith(u8, name, "@") or std.mem.startsWith(u8, name, "!")) null else name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

fn unionSet(dst: *NameSet, src: NameSet) !void {
    var it = src.iterator();
    while (it.next()) |entry| try dst.put(entry.key_ptr.*, {});
}

fn replaceSet(dst: *NameSet, src: NameSet) !bool {
    if (setEquals(dst.*, src)) return false;
    dst.clearRetainingCapacity();
    try unionSet(dst, src);
    return true;
}

fn setEquals(lhs: NameSet, rhs: NameSet) bool {
    if (lhs.count() != rhs.count()) return false;
    var it = lhs.iterator();
    while (it.next()) |entry| {
        if (!rhs.contains(entry.key_ptr.*)) return false;
    }
    return true;
}

const BlockSuccessors = struct {
    names: [16][]const u8 = .{""} ** 16,
    len: usize = 0,

    fn add(successors_list: *BlockSuccessors, name: []const u8) !void {
        if (successors_list.len == successors_list.names.len) return error.UnsupportedCodegenControlFlow;
        successors_list.names[successors_list.len] = name;
        successors_list.len += 1;
    }
};

fn successors(block: ir.BasicBlock) !BlockSuccessors {
    var result = BlockSuccessors{};
    if (block.terminator) |terminator| switch (terminator) {
        .br => |br| try result.add(br.target),
        .condbr => |condbr| {
            try result.add(condbr.then_target);
            if (!std.mem.eql(u8, condbr.then_target, condbr.else_target)) try result.add(condbr.else_target);
        },
        .@"switch" => |switch_term| {
            try result.add(switch_term.default_target);
            for (switch_term.cases.items) |case| {
                var seen = std.mem.eql(u8, case.target, switch_term.default_target);
                for (result.names[0..result.len]) |name| {
                    if (std.mem.eql(u8, name, case.target)) seen = true;
                }
                if (!seen) try result.add(case.target);
            }
        },
        .indirectbr, .ret, .@"unreachable" => {},
    };
    return result;
}

const ValueLoc = union(enum) {
    arg32: ArgReg,
    arg64: ArgReg,
    arg128: RegPair,
    eax,
    rax,
    scratch32: ArgReg,
    scratch64: ArgReg,
    scratch128: RegPair,
    stack64: u8,
    stack128: u8,
    stack128_value: u8,
    stack_i32_array: StackArrayLoc,
    stack_i32_ptr: StackPtrLoc,
    spill64: FrameIndex,
    spill128: PairSpillLoc,
};

const VirtualRegClass = enum {
    gpr32,
    gpr64,
    gpr128,
    stack_object,
    stack_pointer,
};

const VirtualReg = struct {
    index: usize,
    class: VirtualRegClass,
    bits: u16,
};

const ValueBinding = struct {
    vreg: VirtualReg,
    loc: ValueLoc,
};

const VirtualRegMetadata = struct {
    class: VirtualRegClass,
    bits: u16,
};

const PairSpillLoc = struct {
    lo: FrameIndex,
    hi: FrameIndex,
};

const StackArrayLoc = struct {
    base_disp: u32,
    len: u32,
};

const StackPtrLoc = struct {
    disp: u32,
    index: ?StackIndexLoc = null,
};

const StackIndexLoc = struct {
    reg: ArgReg,
    name: []const u8,
};

const ComposedBlockSelector = struct {
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    allocation_plan: ?*const SelectorAllocationPlan = null,
    values: std.StringHashMap(ValueBinding),
    next_virtual_reg: usize = 0,
    edge_label_count: usize = 0,
    current_eax_name: ?[]const u8 = null,
    current_scratch_names: [6]?[]const u8 = .{null} ** 6,
    current_pair_a_name: ?[]const u8 = null,
    current_pair_b_name: ?[]const u8 = null,
    stack_slot_allocated: bool = false,
    stack_array_allocated: bool = false,
    stack_array_count: usize = 0,
    stack_frame_bytes: u32 = 0,
    current_position: usize = 1,
    expired_binding_this_position: bool = false,
    enable_expired_plan_register_reuse: bool = false,
    spill_slot_names: [stage2_spill_slots]?[]const u8 = .{null} ** stage2_spill_slots,
    call_clobbered_regs: bool = false,

    fn init(allocator: std.mem.Allocator, machine: *MachineFunction) ComposedBlockSelector {
        return .{
            .allocator = allocator,
            .machine = machine,
            .allocation_plan = null,
            .values = std.StringHashMap(ValueBinding).init(allocator),
        };
    }

    fn deinit(selector: *ComposedBlockSelector) void {
        selector.values.deinit();
    }

    fn bindParams(selector: *ComposedBlockSelector, function: ir.Function) !?Diagnostic {
        if (function.params.items.len > 6) return .{ .unsupported_value = "composed-block-too-many-params" };
        var abi_index: usize = 0;
        for (function.params.items) |param| {
            const reg = ArgReg.fromIndex(abi_index) catch return .{ .unsupported_value = "composed-block-param-reg" };
            if (param.ty == .ptr) {
                try selector.bindValueLoc(param.name, .{ .arg64 = reg });
            } else {
                const bits = intBits(param.ty) orelse return .{ .no_emitter = "composed-block-param-not-scalar" };
                switch (bits) {
                    32 => try selector.bindValueLoc(param.name, .{ .arg32 = reg }),
                    64 => try selector.bindValueLoc(param.name, .{ .arg64 = reg }),
                    128 => {
                        const high = ArgReg.fromIndex(abi_index + 1) catch return .{ .unsupported_value = "composed-block-param-reg" };
                        try selector.bindValueLoc(param.name, .{ .arg128 = .{ .lo = reg, .hi = high } });
                        abi_index += 1;
                    },
                    else => return .{ .no_emitter = "composed-block-param-width" },
                }
            }
            abi_index += 1;
        }
        return null;
    }

    fn bindPhiResults(selector: *ComposedBlockSelector, function: ir.Function) !?Diagnostic {
        for (function.blocks.items) |block| {
            var used_in_block = [_]bool{false} ** phi_regs.len;
            for (block.instructions.items) |instruction| {
                if (instruction.removed or instruction.kind != .phi) continue;
                const result_name = instruction.result orelse return .{ .unsupported_value = "stage2-phi-missing-result" };
                const phi = instruction.kind.phi;
                const bits = intBits(phi.ty) orelse return .{ .no_emitter = "stage2-phi-type" };
                if (bits != 32 and bits != 64) return .{ .no_emitter = "stage2-phi-width" };
                const reg = nextPhiReg(&used_in_block) orelse return .{ .no_spill_envelope = "stage2-phi-registers" };
                try selector.bindValueLoc(result_name, if (bits == 64) .{ .scratch64 = reg } else .{ .scratch32 = reg });
            }
        }
        return null;
    }

    fn nextPhiReg(used_in_block: *[phi_regs.len]bool) ?ArgReg {
        for (phi_regs, 0..) |reg, index| {
            if (used_in_block[index]) continue;
            used_in_block[index] = true;
            return reg;
        }
        return null;
    }

    fn enterBlock(selector: *ComposedBlockSelector, block: ir.BasicBlock) !?Diagnostic {
        selector.clearVolatileRegisterCache();
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .phi => {},
                else => break,
            }
            const result_name = instruction.result orelse return .{ .unsupported_value = "stage2-phi-missing-result" };
            const loc = selector.valueLoc(result_name) orelse return .{ .unsupported_value = "stage2-phi-dst" };
            switch (loc) {
                .scratch32 => |reg| selector.current_scratch_names[argRegIndex(reg)] = result_name,
                .scratch64 => |reg| selector.current_scratch_names[argRegIndex(reg)] = result_name,
                .arg32, .arg64, .arg128, .scratch128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => return .{ .no_emitter = "stage2-phi-dst-loc" },
            }
        }
        return null;
    }

    fn lowerInstruction(selector: *ComposedBlockSelector, instruction: ir.Instruction) !?Diagnostic {
        if (instruction.removed) return null;
        try selector.expireExpiredBindings();
        defer selector.current_position += 1;
        return switch (instruction.kind) {
            .phi => null,
            .binary => |binary| try selector.lowerBinary(instruction.result, binary),
            .alloca => |alloca| try selector.lowerAlloca(instruction.result, alloca),
            .cast => |cast| try selector.lowerCast(instruction.result, cast),
            .freeze => |freeze| try selector.lowerFreeze(instruction.result, freeze),
            .icmp => |icmp| try selector.lowerIcmp(instruction.result, icmp),
            .load => |load| try selector.lowerLoad(instruction.result, load),
            .store => |store| try selector.lowerStore(store),
            .gep => |gep| try selector.lowerGep(instruction.result, gep),
            .call => |call| try selector.lowerCall(instruction.result, call),
            .select => |select| try selector.lowerSelect(instruction.result, select),
            else => .{ .no_emitter = "composed-block-instruction-not-owned" },
        };
    }

    fn lowerAlloca(selector: *ComposedBlockSelector, result: ?[]const u8, alloca: ir.AllocaInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        if (selector.valueLoc(result_name)) |loc| switch (loc) {
            .stack64, .stack128, .stack_i32_array => return null,
            .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .stack128_value, .stack_i32_ptr, .spill64, .spill128 => {},
        };
        if (alloca.allocated_ty_addrspace != null) return .{ .no_emitter = "composed-block-alloca-addrspace" };
        if (alloca.allocated_ty.eql(.{ .int = 64 })) {
            if (selector.stack_slot_allocated or selector.stack_array_allocated) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
            try selector.appendSubRsp(24);
            selector.stack_slot_allocated = true;
            selector.stack_frame_bytes = 24;
            try selector.bindValueLoc(result_name, .{ .stack64 = 0 });
            return null;
        }
        if (alloca.allocated_ty.eql(.{ .int = 128 })) {
            if (selector.stack_slot_allocated or selector.stack_array_allocated) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
            const frame_bytes = stack128FrameBytes();
            try selector.appendSubRsp(frame_bytes);
            selector.stack_slot_allocated = true;
            selector.stack_frame_bytes = frame_bytes;
            try selector.bindValueLoc(result_name, .{ .stack128 = 0 });
            return null;
        }
        if (parseI32ArrayType(alloca.allocated_ty)) |len| {
            if (selector.stack_slot_allocated or selector.stack_array_allocated) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
            const payload_bytes = std.math.mul(u32, len, 4) catch return .{ .no_spill_envelope = "composed-block-stack-array-size" };
            const frame_bytes = alignedCallFrameBytes(payload_bytes) orelse return .{ .no_spill_envelope = "composed-block-stack-array-size" };
            try selector.appendSubRsp(frame_bytes);
            selector.stack_array_allocated = true;
            selector.stack_frame_bytes = frame_bytes;
            try selector.bindValueLoc(result_name, .{ .stack_i32_array = .{ .base_disp = 0, .len = len } });
            return null;
        }
        return .{ .no_emitter = "composed-block-alloca-form" };
    }

    fn prepareStackFrame(selector: *ComposedBlockSelector, function: ir.Function) !?Diagnostic {
        var payload_bytes: u32 = 0;
        var scalar_slot_count: usize = 0;
        var array_count: usize = 0;

        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                if (instruction.removed or instruction.kind != .alloca) continue;
                const result_name = instruction.result orelse return .{ .unsupported_value = "composed-block-missing-result" };
                const alloca = instruction.kind.alloca;
                if (alloca.allocated_ty_addrspace != null) return .{ .no_emitter = "composed-block-alloca-addrspace" };
                if (alloca.allocated_ty.eql(.{ .int = 64 })) {
                    if (payload_bytes != 0) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
                    scalar_slot_count += 1;
                    if (scalar_slot_count > 1) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
                    payload_bytes = 8;
                    try selector.bindValueLoc(result_name, .{ .stack64 = 0 });
                } else if (parseI32ArrayType(alloca.allocated_ty)) |len| {
                    if (scalar_slot_count != 0) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
                    if (array_count == 0) payload_bytes = stage2SpillReservedBytes();
                    array_count += 1;
                    if (array_count > 4) return .{ .no_spill_envelope = "composed-block-stack-array-count" };
                    const array_bytes = std.math.mul(u32, len, 4) catch return .{ .no_spill_envelope = "composed-block-stack-array-size" };
                    const base_disp = payload_bytes;
                    payload_bytes = std.math.add(u32, payload_bytes, array_bytes) catch return .{ .no_spill_envelope = "composed-block-stack-array-size" };
                    try selector.bindValueLoc(result_name, .{ .stack_i32_array = .{ .base_disp = base_disp, .len = len } });
                } else if (alloca.allocated_ty.eql(.{ .int = 128 })) {
                    if (payload_bytes != 0) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
                    scalar_slot_count += 1;
                    if (scalar_slot_count > 1) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
                    payload_bytes = stack128FrameBytes() - 8;
                    try selector.bindValueLoc(result_name, .{ .stack128 = 0 });
                } else {
                    return .{ .no_emitter = "composed-block-alloca-form" };
                }
            }
        }

        if (payload_bytes == 0) {
            const pressure = try analyzeStageTwoNoSpillEnvelope(selector.allocator, function);
            if (pressure.exceedsSpillEnvelope()) return .{ .no_spill_envelope = "composed-block-register-pressure" };
            if (pressure.exceedsNoSpill()) payload_bytes = stage2SpillReservedBytes();
        }

        if (payload_bytes == 0) return null;
        const frame_bytes = alignedCallFrameBytes(payload_bytes) orelse return .{ .no_spill_envelope = "composed-block-stack-array-size" };
        try selector.appendSubRsp(frame_bytes);
        selector.stack_frame_bytes = frame_bytes;
        selector.stack_slot_allocated = scalar_slot_count != 0;
        selector.stack_array_allocated = array_count != 0;
        selector.stack_array_count = array_count;
        return null;
    }

    fn lowerBinary(selector: *ComposedBlockSelector, result: ?[]const u8, binary: ir.BinaryInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        const bits = intBits(binary.ty) orelse return .{ .no_emitter = "composed-block-binary-not-int" };
        if (bits != 16 and bits != 32 and bits != 64 and bits != 128) return .{ .no_emitter = "composed-block-binary-width" };

        if (valueIsInt(binary.rhs)) {
            return try selector.lowerBinaryImmediateRhs(result_name, binary);
        }
        if (valueIsInt(binary.lhs)) {
            return try selector.lowerBinaryImmediateLhs(result_name, binary);
        }
        if (bits == 128) return try selector.lowerPairBinary(result_name, binary);

        if (binary.op == .mul and bits == 64) return try selector.lowerMul64(result_name, binary);
        if ((binary.op == .udiv or binary.op == .urem) and bits == 64) {
            return try selector.lowerUnsignedDivRem64(result_name, binary);
        }

        const op = machineBinaryOp(binary.op) orelse return .{ .no_emitter = "composed-block-binary-op" };
        const lhs = selector.resolveValue(binary.lhs) orelse return .{ .unsupported_value = "composed-block-unknown-lhs" };
        const rhs = selector.resolveValue(binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };

        if (locIsAccumulator(rhs) and !locIsAccumulator(lhs) and isCommutative(op)) {
            try selector.emitBinaryLocIntoAccumulator(op, lhs, bits);
        } else {
            try selector.emitValueIntoAccumulator(binary.lhs, bits);
            const rhs_reg = switch (rhs) {
                .arg32, .scratch32 => |reg| if (bits <= 32) reg else return .{ .no_emitter = "composed-block-rhs-width" },
                .arg64, .scratch64 => |reg| if (bits == 64) reg else return .{ .no_emitter = "composed-block-rhs-width" },
                .arg128, .scratch128 => return .{ .no_emitter = "composed-block-rhs-width" },
                .spill64 => |frame_index| if (bits == 64) blk: {
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                    break :blk .rcx;
                } else return .{ .no_emitter = "composed-block-rhs-stack" },
                .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-rhs-stack" },
                .eax, .rax => return .{ .no_spill_envelope = "composed-block-two-address-rhs-accumulator" },
            };
            try selector.emitBinaryArgAccumulator(op, rhs_reg, bits);
        }

        try selector.bindAccumulator(result_name, bits);
        return null;
    }

    fn lowerBinaryImmediateRhs(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
        const rhs = switch (binary.rhs) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
        };
        const bits = intBits(binary.ty) orelse return .{ .no_emitter = "composed-block-binary-not-int" };
        switch (binary.op) {
            .lshr => {
                if (bits == 128) {
                    const amount = try shiftAmount7(rhs);
                    try selector.emitPairLshrImmediate(result_name, binary.lhs, amount);
                    return null;
                }
                switch (bits) {
                    16, 32 => {
                        try selector.emitValueIntoScratch(binary.lhs, .rcx, bits);
                        const amount = try shiftAmount5(rhs);
                        if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shr_arg_imm5 = .{
                            .reg = .rcx,
                            .amount = amount,
                        } });
                        try selector.bindScratch(result_name, .rcx, bits);
                    },
                    64 => {
                        const amount = try shiftAmount6(rhs);
                        const dst = selector.plannedScratch64RegForResult(result_name) orelse
                            selector.scratch64RegForUseAvoiding(null) orelse
                            selector.reusableScratch64RegForInPlace(binary.lhs) orelse
                            blk: {
                                if (try selector.spillScratch64SourceForInPlace(binary.lhs)) |spill_result| switch (spill_result) {
                                    .reg => |reg| break :blk reg,
                                    .diagnostic => |diagnostic| return diagnostic,
                                };
                                if (try selector.tryLowerLshr64SpillThroughRax(result_name, binary.lhs, amount)) |diagnostic| return diagnostic;
                                return null;
                            };
                        try selector.emitValueIntoScratch(binary.lhs, dst, bits);
                        if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shr_arg64_imm6 = .{
                            .reg = dst,
                            .amount = amount,
                        } });
                        try selector.bindScratch(result_name, dst, bits);
                    },
                    else => return .{ .no_emitter = "composed-block-binary-width" },
                }
            },
            .shl => {
                if (bits == 128) {
                    const amount = try shiftAmount7(rhs);
                    try selector.emitPairShlImmediate(result_name, binary.lhs, amount);
                    return null;
                }
                if (bits == 64) {
                    const amount = try shiftAmount6(rhs);
                    if (try selector.preserveRaxForDestructiveAccumulatorUse(binary.lhs)) |diagnostic| return diagnostic;
                    try selector.emitValueIntoRax(binary.lhs);
                    if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shl_rax_imm6 = amount });
                    try selector.bindRax(result_name);
                    return null;
                }
                if (bits > 32) return .{ .no_emitter = "composed-block-shl-imm-width" };
                const amount = try shiftAmount5(rhs);
                const lhs_loc = selector.resolveValue(binary.lhs) orelse return .{ .unsupported_value = "composed-block-unknown-lhs" };
                if (try selector.preserveCurrentEaxIntoScratch()) |diagnostic| return diagnostic;
                try selector.emitValueIntoEax(binary.lhs);
                if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shl_eax_imm5 = amount });
                switch (lhs_loc) {
                    .scratch32 => |reg| {
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = reg });
                        try selector.bindScratch(result_name, reg, bits);
                        selector.current_eax_name = null;
                    },
                    .arg32, .arg64, .scratch64, .arg128, .scratch128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => try selector.bindEax(result_name),
                }
            },
            .ashr => {
                if (bits == 128) {
                    const amount = try shiftAmount7(rhs);
                    if (amount != 127) return .{ .no_emitter = "composed-block-ashr-i128-amount" };
                    try selector.emitPairSignMask(result_name, binary.lhs, pair_a);
                    return null;
                }
                if (bits != 64) return .{ .no_emitter = "composed-block-ashr-width" };
                const amount = try shiftAmount6(rhs);
                try selector.emitValueIntoScratch(binary.lhs, .rcx, bits);
                if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .sar_arg64_imm6 = .{
                    .reg = .rcx,
                    .amount = amount,
                } });
                try selector.bindScratch(result_name, .rcx, bits);
                if (try selector.spillValue(result_name)) |diagnostic| return diagnostic;
            },
            .@"and" => {
                if (bits == 64 and rhs == std.math.maxInt(u32)) {
                    const lhs_name = namedValue(binary.lhs);
                    if (selector.current_eax_name) |current| {
                        const same_as_lhs = if (lhs_name) |name| std.mem.eql(u8, current, name) else false;
                        if (!same_as_lhs) if (try selector.spillCurrentRax()) |diagnostic| return diagnostic;
                    }
                    selector.emitValueIntoRax(binary.lhs) catch |err| switch (err) {
                        error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-and64-lhs" },
                        else => return err,
                    };
                    const imm = i32BitPattern(rhs) catch return .{ .no_emitter = "composed-block-and64-imm" };
                    try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = imm });
                    try selector.bindRax(result_name);
                    return null;
                }
                if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
                try selector.emitValueIntoEax(binary.lhs);
                try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = try i32Value(rhs) });
                try selector.bindEax(result_name);
            },
            .@"or" => {
                if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
                try selector.emitValueIntoEax(binary.lhs);
                try selector.machine.instructions.append(selector.allocator, .{ .or_eax_imm32 = try i32Value(rhs) });
                try selector.bindEax(result_name);
            },
            .add => {
                if (bits == 64) {
                    try selector.emitValueIntoScratch(binary.lhs, .rcx, bits);
                    try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = try i32Value(rhs) } });
                    try selector.bindScratch(result_name, .rcx, bits);
                } else {
                    if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
                    try selector.emitValueIntoEax(binary.lhs);
                    try selector.machine.instructions.append(selector.allocator, .{ .add_eax_imm32 = try i32Value(rhs) });
                    try selector.bindEax(result_name);
                }
            },
            .sub => {
                const imm = try i32Value(rhs);
                if (bits == 64) {
                    try selector.emitValueIntoScratch(binary.lhs, .rcx, bits);
                    try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = -imm } });
                    try selector.bindScratch(result_name, .rcx, bits);
                } else {
                    if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
                    try selector.emitValueIntoEax(binary.lhs);
                    try selector.machine.instructions.append(selector.allocator, .{ .add_eax_imm32 = -imm });
                    try selector.bindEax(result_name);
                }
            },
            else => return .{ .no_emitter = "composed-block-binary-imm-rhs" },
        }
        return null;
    }

    fn lowerSelect(selector: *ComposedBlockSelector, result: ?[]const u8, select: ir.SelectInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        if (!select.cond_ty.eql(.{ .int = 1 })) return .{ .no_emitter = "composed-block-select-cond" };
        const bits = intBits(select.ty) orelse return .{ .no_emitter = "composed-block-select-type" };
        if (bits != 32 and bits != 64) return .{ .no_emitter = "composed-block-select-width" };

        if (try selector.emitBranchCondition(select.cond)) |diagnostic| return diagnostic;
        try selector.emitValueIntoAccumulator(select.false_value, bits);
        const end_label = try selector.ownedSelectEndLabel();
        try selector.machine.instructions.append(selector.allocator, .{ .je = end_label });
        try selector.emitValueIntoAccumulator(select.true_value, bits);
        try selector.machine.instructions.append(selector.allocator, .{ .label = end_label });
        try selector.bindAccumulator(result_name, bits);
        return null;
    }

    fn lowerPairBinary(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
        const op = machineBinaryOp(binary.op) orelse return .{ .no_emitter = "composed-block-pair-binary-op" };
        switch (op) {
            .xor => {
                const lhs = selector.materializePairValue(binary.lhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
                const rhs = selector.materializePairValue(binary.rhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
                try selector.emitPairXorInPlace(rhs, lhs);
                try selector.bindPairScratch(result_name, rhs);
            },
            .@"or" => {
                const lhs_existing = selector.resolvePairValue(binary.lhs);
                var lhs: RegPair = undefined;
                var rhs: RegPair = undefined;
                if (lhs_existing) |existing| {
                    if (existing.eql(pair_b)) {
                        lhs = selector.materializePairValue(binary.lhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
                        rhs = selector.materializePairValue(binary.rhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
                    } else {
                        rhs = selector.materializePairValue(binary.rhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
                        lhs = selector.materializePairValue(binary.lhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
                    }
                } else {
                    rhs = selector.materializePairValue(binary.rhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
                    lhs = selector.materializePairValue(binary.lhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
                }
                try selector.emitPairOrInPlace(rhs, lhs);
                try selector.bindPairScratch(result_name, rhs);
            },
            .sub => {
                const lhs = selector.materializePairValue(binary.lhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
                const rhs = selector.materializePairValue(binary.rhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
                try selector.emitPairSubInPlace(lhs, rhs);
                try selector.bindPairScratch(result_name, lhs);
            },
            else => return .{ .no_emitter = "composed-block-pair-binary-op" },
        }
        return null;
    }

    fn lowerMul64(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
        const lhs = selector.resolveValue(binary.lhs) orelse return .{ .unsupported_value = "composed-block-unknown-lhs" };
        const dst = switch (lhs) {
            .scratch64 => |reg| if (selector.allocation_plan == null)
                reg
            else
                selector.reusableScratch64RegForInPlace(binary.lhs) orelse
                    selector.plannedScratch64RegForResult(result_name) orelse
                    selector.scratch64RegForUseAvoiding(null) orelse
                    blk: {
                        if (try selector.spillScratch64SourceForInPlace(binary.lhs)) |spill_result| switch (spill_result) {
                            .reg => |spilled_reg| break :blk spilled_reg,
                            .diagnostic => |diagnostic| return diagnostic,
                        };
                        return .{ .no_spill_envelope = "composed-block-mul64-dst" };
                    },
            .arg64, .rax, .spill64 => selector.plannedScratch64RegForResult(result_name) orelse
                (selector.scratch64RegForUseAvoiding(null) orelse {
                    if (lhs == .spill64) return try selector.lowerMul64SpillLhsThroughRax(result_name, lhs.spill64, binary.rhs);
                    return .{ .no_spill_envelope = "composed-block-mul64-dst" };
                }),
            .arg32, .scratch32, .arg128, .scratch128, .eax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-mul64-lhs" },
        };
        selector.emitValueIntoScratch(binary.lhs, dst, 64) catch return .{ .unsupported_value = "composed-block-mul64-lhs" };

        const rhs = selector.resolveValue(binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };
        switch (rhs) {
            .scratch64, .arg64 => |src| try selector.machine.instructions.append(selector.allocator, .{ .imul_arg64_arg64 = .{ .dst = dst, .src = src } }),
            .spill64 => |frame_index| {
                if (selector.scratch64RegForUseAvoiding(dst)) |src| {
                    selector.emitValueIntoScratch(binary.rhs, src, 64) catch return .{ .unsupported_value = "composed-block-mul64-rhs" };
                    try selector.machine.instructions.append(selector.allocator, .{ .imul_arg64_arg64 = .{ .dst = dst, .src = src } });
                } else {
                    if (try selector.spillCurrentRax()) |diagnostic| return diagnostic;
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = frame_index });
                    selector.current_eax_name = null;
                    try selector.machine.instructions.append(selector.allocator, .{ .imul_arg64_rax = dst });
                }
            },
            .arg32, .scratch32, .arg128, .scratch128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-mul64-rhs" },
        }
        try selector.bindScratch(result_name, dst, 64);
        return null;
    }

    fn lowerMul64SpillLhsThroughRax(selector: *ComposedBlockSelector, result_name: []const u8, lhs_frame_index: FrameIndex, rhs_value: ir.Value) !?Diagnostic {
        if (try selector.spillCurrentRax()) |diagnostic| return diagnostic;
        try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = lhs_frame_index });
        selector.current_eax_name = null;
        const rhs = selector.resolveValue(rhs_value) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };
        switch (rhs) {
            .arg64, .scratch64 => |src| try selector.machine.instructions.append(selector.allocator, .{ .imul_rax_arg64 = src }),
            .spill64 => |frame_index| try selector.machine.instructions.append(selector.allocator, .{ .imul_rax_rsp = frame_index }),
            .arg32, .scratch32, .arg128, .scratch128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-mul64-rhs" },
        }
        try selector.bindRax(result_name);
        return null;
    }

    fn plannedScratch64RegForResult(selector: ComposedBlockSelector, name: []const u8) ?ArgReg {
        const plan = selector.allocation_plan orelse return null;
        const assignment = plan.assignment(name) orelse return null;
        const reg = switch (assignment) {
            .gpr64 => |reg| reg,
            .gpr32, .gpr128, .stack_object, .stack_pointer, .spill => return null,
        };
        return if (selector.scratch64RegIsAvailableForUse(reg)) reg else null;
    }

    fn scratch64RegForUseAvoiding(selector: ComposedBlockSelector, avoid: ?ArgReg) ?ArgReg {
        for (selector_allocatable_regs) |reg| {
            if (avoid != null and reg == avoid.?) continue;
            if (selector.scratch64RegIsAvailableForUse(reg)) return reg;
        }
        return null;
    }

    fn reusableScratch64RegForInPlace(selector: ComposedBlockSelector, value: ir.Value) ?ArgReg {
        const name = namedValue(value) orelse return null;
        const loc = selector.resolveValue(value) orelse return null;
        const reg = switch (loc) {
            .scratch64 => |reg| reg,
            else => return null,
        };
        const plan = selector.allocation_plan orelse return null;
        const end = plan.intervalEnd(name) orelse return null;
        if (end > selector.current_position) return null;

        var it = selector.values.iterator();
        while (it.next()) |entry| {
            if (!locContainsReg(entry.value_ptr.loc, reg)) continue;
            if (std.mem.eql(u8, entry.key_ptr.*, name)) continue;
            const other_end = plan.intervalEnd(entry.key_ptr.*) orelse return null;
            if (other_end >= selector.current_position) return null;
        }

        return reg;
    }

    const SpillScratchForInPlaceResult = union(enum) {
        reg: ArgReg,
        diagnostic: Diagnostic,
    };

    fn spillScratch64SourceForInPlace(selector: *ComposedBlockSelector, value: ir.Value) !?SpillScratchForInPlaceResult {
        const name = namedValue(value) orelse return null;
        const loc = selector.resolveValue(value) orelse return null;
        const reg = switch (loc) {
            .scratch64 => |reg| reg,
            else => return null,
        };
        const plan = selector.allocation_plan orelse return null;
        _ = plan.intervalEnd(name) orelse return null;

        var it = selector.values.iterator();
        while (it.next()) |entry| {
            if (!locContainsReg(entry.value_ptr.loc, reg)) continue;
            if (std.mem.eql(u8, entry.key_ptr.*, name)) continue;
            const other_end = plan.intervalEnd(entry.key_ptr.*) orelse return null;
            if (other_end >= selector.current_position) return null;
        }

        if (try selector.spillValue(name)) |diagnostic| return .{ .diagnostic = diagnostic };
        return .{ .reg = reg };
    }

    fn tryLowerLshr64SpillThroughRax(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, amount: u6) !?Diagnostic {
        const loc = selector.resolveValue(value) orelse return .{ .no_spill_envelope = "composed-block-lshr64-dst" };
        const frame_index = switch (loc) {
            .spill64 => |frame_index| frame_index,
            else => return .{ .no_spill_envelope = "composed-block-lshr64-dst" },
        };
        if (try selector.spillCurrentRax()) |diagnostic| return diagnostic;
        try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = frame_index });
        selector.current_eax_name = null;
        if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shr_rax_imm6 = amount });
        try selector.bindRax(result_name);
        return null;
    }

    fn scratch64RegIsAvailableForUse(selector: ComposedBlockSelector, reg: ArgReg) bool {
        const status = selector.regConflictStatus(reg) orelse return true;
        return status;
    }

    fn lowerUnsignedDivRem64(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
        const rhs = selector.resolveValue(binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };
        if (rhs == .rax) {
            try selector.emitValueIntoScratch(binary.rhs, .rcx, 64);
            try selector.emitValueIntoRax(binary.lhs);
        } else {
            try selector.emitValueIntoRax(binary.lhs);
            try selector.emitValueIntoScratch(binary.rhs, .rcx, 64);
        }
        selector.invalidateScratchContaining(.rdx);
        selector.invalidatePairContaining(.rdx);
        try selector.machine.instructions.append(selector.allocator, .xor_edx_edx);
        try selector.machine.instructions.append(selector.allocator, .{ .div_arg64 = .rcx });
        switch (binary.op) {
            .udiv => {
                try selector.bindRax(result_name);
                selector.invalidateScratchContaining(.rdx);
            },
            .urem => {
                selector.current_eax_name = null;
                try selector.bindScratch(result_name, .rdx, 64);
            },
            else => unreachable,
        }
        return null;
    }

    fn lowerBinaryImmediateLhs(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
        const lhs = switch (binary.lhs) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
        };
        if (binary.op != .lshr) return .{ .no_emitter = "composed-block-binary-imm-lhs" };
        const bits = intBits(binary.ty) orelse return .{ .no_emitter = "composed-block-binary-not-int" };
        if (bits > 32) return .{ .no_emitter = "composed-block-variable-shift-width" };

        try selector.emitValueIntoScratch(binary.rhs, .rcx, bits);
        selector.current_eax_name = null;
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(lhs) });
        try selector.machine.instructions.append(selector.allocator, .shr_eax_cl);
        try selector.bindEax(result_name);
        return null;
    }

    fn lowerCast(selector: *ComposedBlockSelector, result: ?[]const u8, cast: ir.CastInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        const from_bits = intBits(cast.from_ty) orelse return .{ .no_emitter = "composed-block-cast-from-not-int" };
        const to_bits = intBits(cast.to_ty) orelse return .{ .no_emitter = "composed-block-cast-to-not-int" };
        if (from_bits > 128) return .{ .no_emitter = "composed-block-cast-width" };
        if (to_bits > 64 and !(cast.op == .zext and from_bits == 64 and to_bits == 128)) {
            return .{ .no_emitter = "composed-block-cast-width" };
        }

        switch (cast.op) {
            .trunc, .bitcast => {
                if (from_bits == 128) {
                    const dst = selector.plannedScratch64RegForResult(result_name) orelse
                        if (selector.resolvePairValue(cast.value)) |pair|
                            pair.lo
                        else
                            selector.scratch64RegForUseAvoiding(null) orelse return .{ .no_spill_envelope = "composed-block-cast-scratch" };
                    selector.emitPairLowLaneIntoScratch(cast.value, dst) catch return .{ .unsupported_value = "composed-block-unknown-cast" };
                    try selector.bindScratch(result_name, dst, 64);
                } else {
                    const loc = selector.resolveValue(cast.value) orelse return .{ .unsupported_value = "composed-block-unknown-cast" };
                    try selector.bindValueLoc(result_name, loc);
                    switch (loc) {
                        .eax => selector.current_eax_name = result_name,
                        .rax => selector.current_eax_name = result_name,
                        .scratch32, .scratch64 => |reg| selector.current_scratch_names[argRegIndex(reg)] = result_name,
                        .arg32, .arg64 => {},
                        .arg128, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => return .{ .no_emitter = "composed-block-cast-width" },
                    }
                }
            },
            .zext => {
                if (from_bits == 64 and to_bits == 128) {
                    try selector.emitValueIntoScratch(cast.value, pair_b.lo, 64);
                    try selector.emitZeroArg64(pair_b.hi);
                    try selector.bindPairScratch(result_name, pair_b);
                    return null;
                }
                if (to_bits > 32) return .{ .no_emitter = "composed-block-zext-width" };
                try selector.emitValueIntoEax(cast.value);
                if (from_bits < 32) {
                    const shift: u5 = @intCast(from_bits);
                    const mask = (@as(i32, 1) << shift) - 1;
                    try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = mask });
                }
                try selector.bindEax(result_name);
            },
            .sext => {
                if (from_bits != 32 or to_bits != 64) return .{ .no_emitter = "composed-block-sext-width" };
                const loc = selector.resolveValue(cast.value) orelse return .{ .unsupported_value = "composed-block-unknown-sext" };
                const src = switch (loc) {
                    .arg32, .scratch32 => |reg| reg,
                    .arg64, .scratch64, .arg128, .scratch128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => return .{ .no_emitter = "composed-block-sext-source" },
                };
                const dst: ArgReg = switch (src) {
                    .rdi => .r8,
                    .rsi => .r9,
                    .rdx => .rcx,
                    .rcx => .r8,
                    .r8 => .r9,
                    .r9 => .r8,
                };
                try selector.machine.instructions.append(selector.allocator, .{ .movsxd_arg32_arg64 = .{ .dst = dst, .src = src } });
                try selector.bindScratch(result_name, dst, 64);
            },
            else => return .{ .no_emitter = "composed-block-cast-op" },
        }
        return null;
    }

    fn lowerFreeze(selector: *ComposedBlockSelector, result: ?[]const u8, freeze: ir.FreezeInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        const bits = intBits(freeze.ty) orelse return .{ .no_emitter = "composed-block-freeze-type" };
        if (bits != 32 and bits != 64) return .{ .no_emitter = "composed-block-freeze-width" };
        const loc = selector.resolveValue(freeze.value) orelse return .{ .unsupported_value = "composed-block-unknown-freeze" };
        switch (loc) {
            .arg32, .scratch32, .eax => if (bits != 32) return .{ .no_emitter = "composed-block-freeze-width" },
            .arg64, .scratch64, .rax, .spill64 => if (bits != 64) return .{ .no_emitter = "composed-block-freeze-width" },
            .arg128, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-freeze-loc" },
        }
        try selector.bindValueLoc(result_name, loc);
        switch (loc) {
            .eax, .rax => selector.current_eax_name = result_name,
            .scratch32, .scratch64 => |reg| selector.current_scratch_names[argRegIndex(reg)] = result_name,
            .arg32, .arg64, .spill64 => {},
            .arg128, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => unreachable,
        }
        return null;
    }

    fn lowerIcmp(selector: *ComposedBlockSelector, result: ?[]const u8, icmp: ir.IcmpInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        if (icmp.predicate == .eq) {
            const rhs = switch (icmp.rhs) {
                .int => |int| int,
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .no_emitter = "composed-block-icmp-rhs" },
            };
            if (try i64Value(rhs) != 0) return .{ .no_emitter = "composed-block-icmp-eq-rhs" };
            const bits = intBits(icmp.operand_ty) orelse return .{ .no_emitter = "composed-block-icmp-type" };
            const loc = selector.resolveValue(icmp.lhs) orelse return .{ .unsupported_value = "composed-block-icmp-lhs" };
            switch (loc) {
                .eax => try selector.machine.instructions.append(selector.allocator, .test_eax_eax),
                .rax => {
                    if (bits != 64) return .{ .no_emitter = "composed-block-icmp-lhs-width" };
                    try selector.machine.instructions.append(selector.allocator, .test_rax_rax);
                },
                .arg32, .scratch32 => |reg| {
                    if (bits > 32) return .{ .no_emitter = "composed-block-icmp-lhs-width" };
                    try selector.machine.instructions.append(selector.allocator, .{ .test_arg32 = reg });
                },
                .arg64, .scratch64 => |reg| {
                    if (bits != 64) return .{ .no_emitter = "composed-block-icmp-lhs-width" };
                    try selector.machine.instructions.append(selector.allocator, .{ .test_arg64 = reg });
                },
                .arg128, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => return .{ .no_emitter = "composed-block-icmp-lhs-loc" },
            }
            selector.current_eax_name = null;
            try selector.machine.instructions.append(selector.allocator, .sete_eax);
        } else if (icmp.predicate == .ult and icmp.operand_ty.eql(.{ .int = 64 })) {
            const rhs = switch (icmp.rhs) {
                .int => |int| int,
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .no_emitter = "composed-block-icmp-rhs" },
            };
            selector.emitValueIntoScratch(icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
            selector.current_eax_name = null;
            try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = try i64Value(rhs) } });
            try selector.machine.instructions.append(selector.allocator, .setb_eax);
        } else return .{ .no_emitter = "composed-block-icmp-form" };
        try selector.bindEax(result_name);
        return null;
    }

    fn lowerLoad(selector: *ComposedBlockSelector, result: ?[]const u8, load: ir.LoadInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        if (load.attrs.isBarrier()) return .{ .no_emitter = "composed-block-load-barrier" };
        if (!load.ty.eql(.{ .int = 32 }) and !load.ty.eql(.{ .int = 64 }) and !load.ty.eql(.{ .int = 128 })) return .{ .no_emitter = "composed-block-load-width" };
        const ptr = selector.resolveValue(load.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-load-ptr" };
        switch (ptr) {
            .stack64 => |disp| {
                if (!load.ty.eql(.{ .int = 64 })) return .{ .no_emitter = "composed-block-load-stack-width" };
                try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_rax = disp });
                try selector.bindRax(result_name);
            },
            .stack128 => |disp| {
                if (!load.ty.eql(.{ .int = 128 })) return .{ .no_emitter = "composed-block-load-stack-width" };
                try selector.bindValueLoc(result_name, .{ .stack128_value = disp });
            },
            .stack_i32_ptr => |stack_ptr| {
                if (!load.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-load-stack-array-width" };
                try selector.appendLoadStackI32(stack_ptr);
                try selector.bindEax(result_name);
            },
            .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .stack128_value, .stack_i32_array, .spill64, .spill128 => return .{ .no_emitter = "composed-block-load-ptr" },
        }
        return null;
    }

    fn lowerStore(selector: *ComposedBlockSelector, store: ir.StoreInst) !?Diagnostic {
        if (store.attrs.isBarrier()) return .{ .no_emitter = "composed-block-store-barrier" };
        if (!store.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-store-width" };
        const ptr = selector.resolveValue(store.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-store-ptr" };
        try selector.emitValueIntoEax(store.value);
        switch (ptr) {
            .arg64, .scratch64 => |reg| try selector.machine.instructions.append(selector.allocator, .{ .store_eax_arg_ptr = reg }),
            .stack_i32_ptr => |stack_ptr| try selector.appendStoreStackI32(stack_ptr),
            .arg32, .scratch32, .arg128, .scratch128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .spill64, .spill128 => return .{ .no_emitter = "composed-block-store-ptr" },
        }
        return null;
    }

    fn lowerGep(selector: *ComposedBlockSelector, result: ?[]const u8, gep: ir.GepInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        const len = parseI32ArrayType(gep.source_ty) orelse return .{ .no_emitter = "composed-block-gep-source" };
        const base = selector.resolveValue(gep.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-gep-ptr" };
        const stack_array = switch (base) {
            .stack_i32_array => |stack_array| stack_array,
            .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_ptr, .spill64, .spill128 => return .{ .no_emitter = "composed-block-gep-ptr" },
        };
        if (stack_array.len != len) return .{ .no_emitter = "composed-block-gep-len" };
        if (gep.ptr_addrspace != null) return .{ .no_emitter = "composed-block-gep-addrspace" };
        if (gep.indices.items.len != 2) return .{ .no_emitter = "composed-block-gep-index-count" };
        const first_index = gep.indices.items[0];
        if (!first_index.ty.eql(.{ .int = 64 }) or !first_index.value.eql(.{ .int = 0 })) return .{ .no_emitter = "composed-block-gep-base-index" };
        const elem_index = gep.indices.items[1];
        if (!elem_index.ty.eql(.{ .int = 64 })) return .{ .no_emitter = "composed-block-gep-elem-index-ty" };
        const stack_ptr = switch (elem_index.value) {
            .int => |int| blk: {
                const index = std.math.cast(u32, int) orelse return .{ .no_emitter = "composed-block-gep-index-range" };
                if (index >= stack_array.len) return .{ .no_emitter = "composed-block-gep-index-range" };
                const byte_offset = std.math.mul(u32, index, 4) catch return .{ .no_spill_envelope = "composed-block-gep-offset" };
                break :blk StackPtrLoc{ .disp = stack_array.base_disp + byte_offset };
            },
            .named => |name| blk: {
                try selector.emitValueIntoScratch(elem_index.value, .rcx, 64);
                try selector.bindScratch(name, .rcx, 64);
                break :blk StackPtrLoc{ .disp = stack_array.base_disp, .index = .{ .reg = .rcx, .name = name } };
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "composed-block-gep-dynamic-index" },
        };
        try selector.bindValueLoc(result_name, .{ .stack_i32_ptr = stack_ptr });
        return null;
    }

    fn lowerCall(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
        if (call.isDebugVariableLocation()) return null;
        if (std.mem.eql(u8, call.callee, "llvm.abs.i64")) return try selector.lowerAbsI64(result, call);
        if (std.mem.eql(u8, call.callee, "llvm.abs.i128")) return try selector.lowerAbsI128(result, call);
        if (call.inline_asm != null) return .{ .no_emitter = "composed-block-inline-asm-call" };
        if (call.callee_value != null) return .{ .unsupported_value = "composed-block-indirect-call" };
        if (!isDefaultOrFastcc(call.calling_conv) or call.tail_kind != null or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
            return .{ .no_emitter = "composed-block-call-form" };
        }
        const ret_bits = if (call.ret_ty == .void) @as(u16, 0) else intBits(call.ret_ty) orelse return .{ .no_emitter = "composed-block-call-ret" };
        if (ret_bits != 0 and ret_bits != 32 and ret_bits != 64 and ret_bits != 128) return .{ .no_emitter = "composed-block-call-ret-width" };
        var abi_index: usize = 0;

        for (call.args.items) |arg| {
            const target = ArgReg.fromIndex(abi_index) catch return .{ .unsupported_value = "composed-block-call-arg-reg" };
            if (try selector.lowerDirectCallArg(arg, target)) |diagnostic| return diagnostic;
            abi_index += callArgRegisterCount(arg.ty) orelse return .{ .no_emitter = "composed-block-call-arg-type" };
            if (abi_index > 6) return .{ .unsupported_value = "composed-block-call-arg-count" };
        }

        try selector.machine.instructions.append(selector.allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
        selector.invalidateCallClobbers();
        if (result) |result_name| switch (ret_bits) {
            0 => return .{ .unsupported_value = "composed-block-void-call-result" },
            32 => try selector.bindEax(result_name),
            64 => try selector.bindRax(result_name),
            128 => {},
            else => unreachable,
        };
        return null;
    }

    fn lowerAbsI64(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        if (call.inline_asm != null or call.callee_value != null or !isDefaultOrFastcc(call.calling_conv) or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
            return .{ .no_emitter = "composed-block-abs-call-form" };
        }
        if (!call.ret_ty.eql(.{ .int = 64 }) or call.args.items.len != 2) return .{ .no_emitter = "composed-block-abs-signature" };
        const value_arg = call.args.items[0];
        const poison_arg = call.args.items[1];
        if (!value_arg.ty.eql(.{ .int = 64 }) or !poison_arg.ty.eql(.{ .int = 1 })) return .{ .no_emitter = "composed-block-abs-args" };
        if (!valueIsInt(poison_arg.value)) return .{ .no_emitter = "composed-block-abs-poison-arg" };
        const poison_ok = switch (poison_arg.value) {
            .int => |int| int == 0,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        };
        if (!poison_ok) return .{ .no_emitter = "composed-block-abs-poison-mode" };

        try selector.emitValueIntoScratch(value_arg.value, .rdi, 64);
        if (try selector.spillCurrentRax()) |diagnostic| return diagnostic;
        selector.current_eax_name = null;
        try selector.machine.instructions.append(selector.allocator, .abs_i64_rdi_rax);
        try selector.bindRax(result_name);
        return null;
    }

    fn lowerAbsI128(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        if (call.inline_asm != null or call.callee_value != null or !isDefaultOrFastcc(call.calling_conv) or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
            return .{ .no_emitter = "composed-block-abs-call-form" };
        }
        if (!call.ret_ty.eql(.{ .int = 128 }) or call.args.items.len != 2) return .{ .no_emitter = "composed-block-abs-signature" };
        const value_arg = call.args.items[0];
        const poison_arg = call.args.items[1];
        if (!value_arg.ty.eql(.{ .int = 128 }) or !poison_arg.ty.eql(.{ .int = 1 })) return .{ .no_emitter = "composed-block-abs-args" };
        const poison_ok = switch (poison_arg.value) {
            .int => |int| int == 0,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        };
        if (!poison_ok) return .{ .no_emitter = "composed-block-abs-poison-mode" };

        if (try selector.spillCurrentPairs()) |diagnostic| return diagnostic;
        try selector.emitPairSignMask("__zllvm_abs_i128_sign", value_arg.value, pair_a);
        _ = selector.materializePairValue(value_arg.value, pair_b) catch return .{ .unsupported_value = "composed-block-abs-value" };
        try selector.emitPairXorInPlace(pair_b, pair_a);
        try selector.emitPairSubInPlace(pair_b, pair_a);
        try selector.bindPairScratch(result_name, pair_b);
        return null;
    }

    fn lowerReturn(selector: *ComposedBlockSelector, ret: anytype) !?Diagnostic {
        if (ret.ty == .void) {
            if (ret.value != null) return .{ .unsupported_value = "composed-block-void-ret-value" };
            try selector.emitReturnEpilogue();
            return null;
        }
        const bits = intBits(ret.ty) orelse return .{ .no_emitter = "composed-block-ret-type" };
        if (bits != 32 and bits != 64 and bits != 128) return .{ .no_emitter = "composed-block-ret-width" };
        const value = ret.value orelse return .{ .unsupported_value = "composed-block-missing-ret-value" };
        switch (value) {
            .int => |int| switch (bits) {
                32 => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(int) }),
                64 => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rax = try i64Value(int) }),
                128 => return .{ .unsupported_value = "composed-block-ret-value" },
                else => unreachable,
            },
            .named => {
                _ = selector.resolveValue(value) orelse return .{ .unsupported_value = "composed-block-unknown-ret" };
                if (bits == 128) {
                    try selector.emitValueIntoI128Return(value);
                } else {
                    try selector.emitValueIntoAccumulator(value, bits);
                }
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "composed-block-ret-value" },
        }
        try selector.emitReturnEpilogue();
        return null;
    }

    fn appendSubRsp(selector: *ComposedBlockSelector, bytes: u32) !void {
        switch (bytes) {
            8 => try selector.machine.instructions.append(selector.allocator, .sub_rsp_8),
            24 => try selector.machine.instructions.append(selector.allocator, .sub_rsp_24),
            40 => try selector.machine.instructions.append(selector.allocator, .sub_rsp_40),
            56 => try selector.machine.instructions.append(selector.allocator, .sub_rsp_56),
            else => if (bytes <= std.math.maxInt(u8))
                try selector.machine.instructions.append(selector.allocator, .{ .sub_rsp_imm8 = @intCast(bytes) })
            else
                try selector.machine.instructions.append(selector.allocator, .{ .sub_rsp_imm32 = bytes }),
        }
    }

    fn appendAddRsp(selector: *ComposedBlockSelector, bytes: u32) !void {
        switch (bytes) {
            8 => try selector.machine.instructions.append(selector.allocator, .add_rsp_8),
            24 => try selector.machine.instructions.append(selector.allocator, .add_rsp_24),
            40 => try selector.machine.instructions.append(selector.allocator, .add_rsp_40),
            56 => try selector.machine.instructions.append(selector.allocator, .add_rsp_56),
            else => if (bytes <= std.math.maxInt(u8))
                try selector.machine.instructions.append(selector.allocator, .{ .add_rsp_imm8 = @intCast(bytes) })
            else
                try selector.machine.instructions.append(selector.allocator, .{ .add_rsp_imm32 = bytes }),
        }
    }

    fn appendLoadStackI32(selector: *ComposedBlockSelector, stack_ptr: StackPtrLoc) !void {
        if (stack_ptr.index != null) {
            if (stack_ptr.disp <= std.math.maxInt(u8)) {
                try selector.machine.instructions.append(selector.allocator, .{ .load_stack_rcx4_disp8_eax = @intCast(stack_ptr.disp) });
            } else {
                try selector.machine.instructions.append(selector.allocator, .{ .load_stack_rcx4_disp32_eax = stack_ptr.disp });
            }
        } else if (stack_ptr.disp <= std.math.maxInt(u8)) {
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_eax = @intCast(stack_ptr.disp) });
        } else {
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_eax = stack_ptr.disp });
        }
    }

    fn loadStackU64IntoArg(selector: *ComposedBlockSelector, reg: ArgReg, disp: u32) !void {
        if (disp <= std.math.maxInt(u8)) {
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_arg64 = .{ .reg = reg, .disp = @intCast(disp) } });
        } else {
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_arg64 = .{ .reg = reg, .disp = disp } });
        }
    }

    fn appendStoreStackI32(selector: *ComposedBlockSelector, stack_ptr: StackPtrLoc) !void {
        if (stack_ptr.index != null) {
            if (stack_ptr.disp <= std.math.maxInt(u8)) {
                try selector.machine.instructions.append(selector.allocator, .{ .store_eax_stack_rcx4_disp8 = @intCast(stack_ptr.disp) });
            } else {
                try selector.machine.instructions.append(selector.allocator, .{ .store_eax_stack_rcx4_disp32 = stack_ptr.disp });
            }
        } else if (stack_ptr.disp <= std.math.maxInt(u8)) {
            try selector.machine.instructions.append(selector.allocator, .{ .store_eax_stack_disp8 = @intCast(stack_ptr.disp) });
        } else {
            try selector.machine.instructions.append(selector.allocator, .{ .store_eax_stack_disp32 = stack_ptr.disp });
        }
    }

    fn emitReturnEpilogue(selector: *ComposedBlockSelector) !void {
        if (selector.stack_frame_bytes != 0) try selector.appendAddRsp(selector.stack_frame_bytes);
        try selector.machine.instructions.append(selector.allocator, .ret);
    }

    fn lowerCfgTerminator(
        selector: *ComposedBlockSelector,
        function: ir.Function,
        block_index: usize,
        terminator: ir.Terminator,
    ) !?Diagnostic {
        return switch (terminator) {
            .ret => |ret| try selector.lowerReturn(ret),
            .br => |br| {
                const target_index = function.blockIndex(br.target) orelse return .{ .unsupported_control_flow = "stage2-branch-target" };
                if (try selector.emitPhiEdgeMoves(function.blocks.items[target_index], function.blocks.items[block_index].name)) |diagnostic| return diagnostic;
                if (target_index != block_index + 1) {
                    try selector.machine.instructions.append(selector.allocator, .{ .jmp = br.target });
                }
                return null;
            },
            .condbr => |condbr| {
                if (!condbr.cond_ty.eql(.{ .int = 1 })) return .{ .no_emitter = "stage2-condbr-type" };
                const then_index = function.blockIndex(condbr.then_target) orelse return .{ .unsupported_control_flow = "stage2-branch-target" };
                const else_index = function.blockIndex(condbr.else_target) orelse return .{ .unsupported_control_flow = "stage2-branch-target" };
                const then_has_phi_edge = blockHasPhiIncomingFrom(function.blocks.items[then_index], function.blocks.items[block_index].name);
                const else_has_phi_edge = blockHasPhiIncomingFrom(function.blocks.items[else_index], function.blocks.items[block_index].name);
                if (try selector.emitBranchCondition(condbr.cond)) |diagnostic| return diagnostic;
                if (then_has_phi_edge or else_has_phi_edge) {
                    return try selector.lowerConditionalPhiEdges(function, block_index, then_index, else_index);
                }
                try selector.machine.instructions.append(selector.allocator, .{ .jne = condbr.then_target });
                if (else_index != block_index + 1) {
                    try selector.machine.instructions.append(selector.allocator, .{ .jmp = condbr.else_target });
                }
                return null;
            },
            .@"switch", .indirectbr, .@"unreachable" => .{ .no_emitter = "stage2-terminator-not-owned" },
        };
    }

    fn lowerConditionalPhiEdges(
        selector: *ComposedBlockSelector,
        function: ir.Function,
        block_index: usize,
        then_index: usize,
        else_index: usize,
    ) !?Diagnostic {
        const predecessor = function.blocks.items[block_index].name;
        const then_target = function.blocks.items[then_index].name;
        const else_target = function.blocks.items[else_index].name;
        const branch_cache = selector.saveRegisterCache();
        const then_edge_label = try selector.ownedEdgeLabel();

        try selector.machine.instructions.append(selector.allocator, .{ .jne = then_edge_label });

        selector.restoreRegisterCache(branch_cache);
        if (try selector.emitPhiEdgeMoves(function.blocks.items[else_index], predecessor)) |diagnostic| return diagnostic;
        try selector.machine.instructions.append(selector.allocator, .{ .jmp = else_target });

        try selector.machine.instructions.append(selector.allocator, .{ .label = then_edge_label });
        selector.restoreRegisterCache(branch_cache);
        if (try selector.emitPhiEdgeMoves(function.blocks.items[then_index], predecessor)) |diagnostic| return diagnostic;
        try selector.machine.instructions.append(selector.allocator, .{ .jmp = then_target });

        selector.clearVolatileRegisterCache();
        return null;
    }

    fn ownedEdgeLabel(selector: *ComposedBlockSelector) ![]const u8 {
        const label = try std.fmt.allocPrint(selector.allocator, "__zllvm_stage2_phi_edge_{d}", .{selector.edge_label_count});
        errdefer selector.allocator.free(label);
        selector.edge_label_count += 1;
        try selector.machine.owned_labels.append(selector.allocator, label);
        return label;
    }

    fn ownedSelectEndLabel(selector: *ComposedBlockSelector) ![]const u8 {
        const label = try std.fmt.allocPrint(selector.allocator, "__zllvm_stage2_{d}_generic_cfg_select_end", .{selector.edge_label_count});
        errdefer selector.allocator.free(label);
        selector.edge_label_count += 1;
        try selector.machine.owned_labels.append(selector.allocator, label);
        return label;
    }

    fn emitPhiEdgeMoves(selector: *ComposedBlockSelector, target: ir.BasicBlock, predecessor: []const u8) !?Diagnostic {
        for (target.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const phi = switch (instruction.kind) {
                .phi => |phi| phi,
                else => break,
            };
            const result_name = instruction.result orelse return .{ .unsupported_value = "stage2-phi-missing-result" };
            const incoming = phiIncomingFrom(phi, predecessor) orelse return .{ .unsupported_control_flow = "stage2-phi-incoming" };
            const dst = selector.valueLoc(result_name) orelse return .{ .unsupported_value = "stage2-phi-dst" };
            if (try selector.emitValueIntoLoc(incoming.value, dst)) |diagnostic| return diagnostic;
            switch (dst) {
                .scratch32 => |reg| selector.current_scratch_names[argRegIndex(reg)] = result_name,
                .scratch64 => |reg| selector.current_scratch_names[argRegIndex(reg)] = result_name,
                .arg32, .arg64, .arg128, .scratch128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => return .{ .no_emitter = "stage2-phi-dst-loc" },
            }
        }
        return null;
    }

    fn emitValueIntoLoc(selector: *ComposedBlockSelector, value: ir.Value, dst: ValueLoc) !?Diagnostic {
        switch (dst) {
            .scratch32 => |reg| {
                switch (value) {
                    .int => |int| {
                        selector.invalidateScratchContaining(reg);
                        selector.invalidatePairContaining(reg);
                        selector.current_eax_name = null;
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(int) });
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = reg });
                    },
                    .named => {
                        selector.emitValueIntoScratch(value, reg, 32) catch return .{ .unsupported_value = "stage2-phi-src" };
                    },
                    .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "stage2-phi-src" },
                }
            },
            .scratch64 => |reg| {
                switch (value) {
                    .int => |int| {
                        selector.invalidateScratchContaining(reg);
                        selector.invalidatePairContaining(reg);
                        selector.current_eax_name = null;
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rax = try i64Value(int) });
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = reg });
                    },
                    .named => {
                        selector.emitValueIntoScratch(value, reg, 64) catch return .{ .unsupported_value = "stage2-phi-src" };
                    },
                    .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "stage2-phi-src" },
                }
            },
            .arg32, .arg64, .arg128, .scratch128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => return .{ .no_emitter = "stage2-phi-dst-loc" },
        }
        return null;
    }

    fn emitBranchCondition(selector: *ComposedBlockSelector, value: ir.Value) !?Diagnostic {
        const loc = selector.resolveValue(value) orelse return .{ .unsupported_value = "stage2-unknown-cond" };
        switch (loc) {
            .eax => try selector.machine.instructions.append(selector.allocator, .test_eax_eax),
            .arg32, .scratch32 => |reg| try selector.machine.instructions.append(selector.allocator, .{ .test_arg8 = reg }),
            .arg64, .scratch64, .arg128, .scratch128, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => return .{ .no_emitter = "stage2-cond-loc" },
        }
        return null;
    }

    fn lowerDirectCallArg(selector: *ComposedBlockSelector, arg: ir.CallArg, target: ArgReg) !?Diagnostic {
        if (arg.ty == .ptr) {
            const loc = selector.resolveValue(arg.value) orelse return .{ .unsupported_value = "composed-block-call-unknown-ptr-arg" };
            const disp = switch (loc) {
                .stack64 => |disp| disp,
                .stack128 => |disp| disp,
                .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => return .{ .no_emitter = "composed-block-call-ptr-arg" },
            };
            if (disp != 0) return .{ .no_emitter = "composed-block-call-stack-disp" };
            selector.invalidateScratchContaining(target);
            selector.invalidatePairContaining(target);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_rsp_arg64 = target });
            return null;
        }

        const bits = intBits(arg.ty) orelse return .{ .no_emitter = "composed-block-call-arg-type" };
        if (bits != 32 and bits != 64 and bits != 128) return .{ .no_emitter = "composed-block-call-arg-width" };
        const loc = selector.resolveValue(arg.value) orelse return .{ .unsupported_value = "composed-block-call-unknown-arg" };
        if (bits == 128) {
            const target_hi = ArgReg.fromIndex(argRegIndex(target) + 1) catch return .{ .unsupported_value = "composed-block-call-arg-reg" };
            switch (loc) {
                .arg128, .scratch128 => |pair| try selector.emitPairIntoAbiRegs(pair, .{ .lo = target, .hi = target_hi }),
                .stack128_value => |disp| {
                    try selector.loadStackU64IntoArg(target, disp);
                    try selector.loadStackU64IntoArg(target_hi, disp + 8);
                },
                .spill128 => |spill| {
                    selector.invalidateScratchContaining(target);
                    selector.invalidateScratchContaining(target_hi);
                    selector.invalidatePairContaining(target);
                    selector.invalidatePairContaining(target_hi);
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = target, .frame_index = spill.lo } });
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = target_hi, .frame_index = spill.hi } });
                },
                .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack64, .stack128, .stack_i32_array, .stack_i32_ptr, .spill64 => return .{ .no_emitter = "composed-block-call-arg-loc" },
            }
            return null;
        }
        switch (loc) {
            .arg32, .scratch32 => |reg| {
                if (bits != 32) return .{ .no_emitter = "composed-block-call-arg-width" };
                if (reg != target) {
                    selector.invalidateScratchContaining(target);
                    selector.invalidatePairContaining(target);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = target, .src = reg } });
                }
            },
            .arg64, .scratch64 => |reg| {
                if (bits != 64) return .{ .no_emitter = "composed-block-call-arg-width" };
                if (reg != target) {
                    selector.invalidateScratchContaining(target);
                    selector.invalidatePairContaining(target);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = target, .src = reg } });
                }
            },
            .eax => {
                if (bits != 32) return .{ .no_emitter = "composed-block-call-arg-width" };
                selector.invalidateScratchContaining(target);
                selector.invalidatePairContaining(target);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = target });
            },
            .rax => {
                if (bits != 64) return .{ .no_emitter = "composed-block-call-arg-width" };
                selector.invalidateScratchContaining(target);
                selector.invalidatePairContaining(target);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = target });
            },
            .spill64 => |frame_index| {
                if (bits != 64) return .{ .no_emitter = "composed-block-call-arg-width" };
                selector.invalidateScratchContaining(target);
                selector.invalidatePairContaining(target);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = target, .frame_index = frame_index } });
            },
            .arg128, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-call-arg-loc" },
        }
        return null;
    }

    fn bindValueLoc(selector: *ComposedBlockSelector, name: []const u8, loc: ValueLoc) !void {
        const vreg = if (selector.values.get(name)) |binding|
            binding.vreg
        else blk: {
            const metadata = virtualRegMetadata(loc);
            const vreg: VirtualReg = .{
                .index = selector.next_virtual_reg,
                .class = metadata.class,
                .bits = metadata.bits,
            };
            selector.next_virtual_reg += 1;
            break :blk vreg;
        };
        try selector.values.put(name, .{ .vreg = vreg, .loc = loc });
    }

    fn bindResultLoc(selector: *ComposedBlockSelector, name: []const u8, actual: ValueLoc) !void {
        const target = selector.plannedResultLoc(name, actual) orelse actual;
        if (!valueLocEql(actual, target)) try selector.materializeLocIntoLoc(actual, target);
        try selector.bindValueLoc(name, target);
        selector.trackBoundLoc(name, target);
    }

    fn plannedResultLoc(selector: ComposedBlockSelector, name: []const u8, actual: ValueLoc) ?ValueLoc {
        const plan = selector.allocation_plan orelse return null;
        const assignment = plan.assignment(name) orelse return null;
        const planned: ?ValueLoc = switch (assignment) {
            .gpr32 => |reg| switch (actual) {
                .arg32, .scratch32, .eax => .{ .scratch32 = reg },
                else => null,
            },
            .gpr64 => |reg| switch (actual) {
                .arg64, .scratch64, .rax, .spill64 => .{ .scratch64 = reg },
                else => null,
            },
            .gpr128 => |pair| switch (actual) {
                .arg128, .scratch128, .spill128, .stack128_value => .{ .scratch128 = pair },
                else => null,
            },
            .stack_object, .stack_pointer => actual,
            .spill => |index| if (selector.stack_frame_bytes >= stage2SpillReservedBytes()) switch (actual) {
                .arg64, .scratch64, .rax, .spill64 => if (spillFrameIndexMaybe(index)) |frame_index| .{ .spill64 = frame_index } else null,
                .arg128, .scratch128, .spill128 => if (pairSpillFrameIndexMaybe(index)) |spill| .{ .spill128 = spill } else null,
                else => null,
            } else null,
        };
        const target = planned orelse return null;
        if (std.meta.activeTag(target) == .spill64 or std.meta.activeTag(target) == .spill128) return target;
        if (valueLocEql(actual, target)) return target;
        return if (selector.enable_expired_plan_register_reuse and selector.expired_binding_this_position and selector.targetLocHasOnlyExpiredConflicts(target)) target else null;
    }

    fn targetLocHasOnlyExpiredConflicts(selector: ComposedBlockSelector, target: ValueLoc) bool {
        return switch (target) {
            .scratch32, .scratch64 => |reg| selector.regHasOnlyExpiredConflicts(reg),
            .scratch128 => |pair| blk: {
                var saw_conflict = false;
                if (selector.regConflictStatus(pair.lo)) |expired| {
                    if (!expired) break :blk false;
                    saw_conflict = true;
                }
                if (selector.regConflictStatus(pair.hi)) |expired| {
                    if (!expired) break :blk false;
                    saw_conflict = true;
                }
                break :blk saw_conflict;
            },
            .arg32, .arg64, .arg128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => false,
        };
    }

    fn regHasOnlyExpiredConflicts(selector: ComposedBlockSelector, reg: ArgReg) bool {
        var saw_conflict = false;
        if (selector.regConflictStatus(reg)) |expired| {
            if (!expired) return false;
            saw_conflict = true;
        }
        return saw_conflict;
    }

    fn regConflictStatus(selector: ComposedBlockSelector, reg: ArgReg) ?bool {
        const plan = selector.allocation_plan orelse return null;
        var saw_conflict = false;
        var all_expired = true;

        var it = selector.values.iterator();
        while (it.next()) |entry| {
            if (!locContainsReg(entry.value_ptr.loc, reg)) continue;
            saw_conflict = true;
            const end = plan.intervalEnd(entry.key_ptr.*) orelse {
                all_expired = false;
                continue;
            };
            if (end >= selector.current_position) all_expired = false;
        }

        return if (saw_conflict) all_expired else null;
    }

    fn expireExpiredBindings(selector: *ComposedBlockSelector) !void {
        selector.expired_binding_this_position = false;
        const plan = selector.allocation_plan orelse return;

        var it = selector.values.iterator();
        while (it.next()) |entry| {
            const end = plan.intervalEnd(entry.key_ptr.*) orelse continue;
            if (end < selector.current_position) selector.expired_binding_this_position = true;
        }
    }

    fn materializeLocIntoLoc(selector: *ComposedBlockSelector, actual: ValueLoc, target: ValueLoc) !void {
        switch (target) {
            .scratch32 => |dst| switch (actual) {
                .arg32, .scratch32, .arg64, .scratch64 => |src| {
                    selector.invalidateScratchContaining(dst);
                    selector.invalidatePairContaining(dst);
                    if (src != dst) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = dst, .src = src } });
                },
                .arg128, .scratch128 => |pair| {
                    selector.invalidateScratchContaining(dst);
                    selector.invalidatePairContaining(dst);
                    if (pair.lo != dst) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = dst, .src = pair.lo } });
                },
                .eax, .rax => {
                    selector.invalidateScratchContaining(dst);
                    selector.invalidatePairContaining(dst);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = dst });
                },
                .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => return error.UnsupportedCodegenValue,
            },
            .scratch64 => |dst| switch (actual) {
                .arg64, .scratch64 => |src| {
                    selector.invalidateScratchContaining(dst);
                    selector.invalidatePairContaining(dst);
                    if (src != dst) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = src } });
                },
                .arg128, .scratch128 => |pair| {
                    selector.invalidateScratchContaining(dst);
                    selector.invalidatePairContaining(dst);
                    if (pair.lo != dst) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = pair.lo } });
                },
                .rax => {
                    selector.invalidateScratchContaining(dst);
                    selector.invalidatePairContaining(dst);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst });
                },
                .spill64 => |frame_index| {
                    selector.invalidateScratchContaining(dst);
                    selector.invalidatePairContaining(dst);
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst, .frame_index = frame_index } });
                },
                .arg32, .scratch32, .eax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
            },
            .scratch128 => |dst| switch (actual) {
                .arg128, .scratch128 => |src| try selector.emitPairIntoScratch(src, dst),
                .spill128 => |spill| {
                    selector.current_eax_name = null;
                    selector.invalidateScratchContaining(dst.lo);
                    selector.invalidateScratchContaining(dst.hi);
                    selector.invalidatePair(dst);
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst.lo, .frame_index = spill.lo } });
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst.hi, .frame_index = spill.hi } });
                },
                .stack128_value => |disp| {
                    try selector.loadStackU64IntoArg(dst.lo, disp);
                    try selector.loadStackU64IntoArg(dst.hi, disp + 8);
                },
                .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack64, .stack128, .stack_i32_array, .stack_i32_ptr, .spill64 => return error.UnsupportedCodegenValue,
            },
            .spill64 => |frame_index| {
                if (selector.stack_frame_bytes < stage2SpillReservedBytes()) return error.UnsupportedCodegenValue;
                switch (actual) {
                    .arg64, .scratch64 => |src| {
                        try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = frame_index, .reg = src } });
                        switch (actual) {
                            .scratch64 => selector.invalidateScratchContaining(src),
                            else => {},
                        }
                    },
                    .rax => {
                        try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = frame_index });
                        selector.current_eax_name = null;
                    },
                    .spill64 => {},
                    .arg32, .scratch32, .arg128, .scratch128, .eax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
                }
            },
            .spill128 => |spill| {
                if (selector.stack_frame_bytes < stage2SpillReservedBytes()) return error.UnsupportedCodegenValue;
                switch (actual) {
                    .arg128, .scratch128 => |pair| {
                        try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.lo, .reg = pair.lo } });
                        try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.hi, .reg = pair.hi } });
                        selector.invalidatePair(pair);
                    },
                    .spill128 => {},
                    .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64 => return error.UnsupportedCodegenValue,
                }
            },
            .arg32, .arg64, .arg128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr => return error.UnsupportedCodegenValue,
        }
    }

    fn trackBoundLoc(selector: *ComposedBlockSelector, name: []const u8, loc: ValueLoc) void {
        switch (loc) {
            .eax, .rax => selector.current_eax_name = name,
            .scratch32, .scratch64 => |reg| selector.current_scratch_names[argRegIndex(reg)] = name,
            .scratch128 => |pair| {
                if (pair.eql(pair_a)) selector.current_pair_a_name = name;
                if (pair.eql(pair_b)) selector.current_pair_b_name = name;
            },
            .arg32, .arg64, .arg128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => {},
        }
    }

    fn valueLoc(selector: ComposedBlockSelector, name: []const u8) ?ValueLoc {
        const binding = selector.values.get(name) orelse return null;
        return binding.loc;
    }

    fn virtualRegMetadata(loc: ValueLoc) VirtualRegMetadata {
        return switch (loc) {
            .arg32, .scratch32, .eax => .{ .class = .gpr32, .bits = 32 },
            .arg64, .scratch64, .rax, .spill64 => .{ .class = .gpr64, .bits = 64 },
            .arg128, .scratch128, .spill128, .stack128_value => .{ .class = .gpr128, .bits = 128 },
            .stack64, .stack128, .stack_i32_array => .{ .class = .stack_object, .bits = 0 },
            .stack_i32_ptr => .{ .class = .stack_pointer, .bits = 64 },
        };
    }

    fn bindEax(selector: *ComposedBlockSelector, name: []const u8) !void {
        try selector.bindResultLoc(name, .eax);
    }

    fn bindRax(selector: *ComposedBlockSelector, name: []const u8) !void {
        try selector.bindResultLoc(name, .rax);
    }

    fn bindAccumulator(selector: *ComposedBlockSelector, name: []const u8, bits: u16) !void {
        if (bits == 64) try selector.bindRax(name) else try selector.bindEax(name);
    }

    fn bindScratch(selector: *ComposedBlockSelector, name: []const u8, reg: ArgReg, bits: u16) !void {
        const actual: ValueLoc = if (bits == 64) .{ .scratch64 = reg } else .{ .scratch32 = reg };
        try selector.bindResultLoc(name, actual);
    }

    fn bindPairScratch(selector: *ComposedBlockSelector, name: []const u8, pair: RegPair) !void {
        try selector.bindResultLoc(name, .{ .scratch128 = pair });
        const loc = selector.valueLoc(name) orelse return;
        switch (loc) {
            .scratch128 => |bound_pair| {
                selector.invalidateScratchContaining(bound_pair.lo);
                selector.invalidateScratchContaining(bound_pair.hi);
            },
            else => {},
        }
    }

    fn emitPairIntoAbiRegs(selector: *ComposedBlockSelector, src: RegPair, dst: RegPair) !void {
        if (src.eql(dst)) return;
        selector.current_eax_name = null;
        selector.invalidateScratchContaining(dst.lo);
        selector.invalidateScratchContaining(dst.hi);
        selector.invalidatePair(dst);
        if (src.lo == dst.hi and src.hi == dst.lo) {
            try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = src.lo });
            try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.hi } });
            try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst.hi });
        } else if (src.lo == dst.hi) {
            if (src.lo != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.lo } });
            if (src.hi != dst.hi) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = src.hi } });
        } else if (src.hi == dst.lo) {
            if (src.hi != dst.hi) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = src.hi } });
            if (src.lo != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.lo } });
        } else {
            if (src.lo != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.lo } });
            if (src.hi != dst.hi) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = src.hi } });
        }
    }

    fn spillCurrentRax(selector: *ComposedBlockSelector) !?Diagnostic {
        const name = selector.current_eax_name orelse return null;
        const loc = selector.resolveValue(.{ .named = name }) orelse return null;
        return switch (loc) {
            .rax => try selector.spillValue(name),
            .eax, .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => null,
        };
    }

    fn preserveRaxForDestructiveAccumulatorUse(selector: *ComposedBlockSelector, value: ir.Value) !?Diagnostic {
        const current = selector.current_eax_name orelse return null;
        const value_name = namedValue(value);
        if (value_name) |name| {
            if (std.mem.eql(u8, current, name)) {
                const plan = selector.allocation_plan orelse return null;
                const end = plan.intervalEnd(name) orelse return null;
                if (end > selector.current_position) return try selector.spillValue(name);
                return null;
            }
        }
        return try selector.spillCurrentRax();
    }

    fn spillValue(selector: *ComposedBlockSelector, name: []const u8) !?Diagnostic {
        if (selector.stack_frame_bytes < 24) return .{ .no_spill_envelope = "composed-block-spill-frame" };
        const loc = selector.resolveValue(.{ .named = name }) orelse return .{ .unsupported_value = "composed-block-spill-unknown" };
        switch (loc) {
            .spill64 => return null,
            .spill128 => return null,
            else => {},
        }
        const frame_index = selector.allocateSpillSlot(name) orelse return .{ .no_spill_envelope = "composed-block-spill-slots" };
        switch (loc) {
            .arg64, .scratch64 => |reg| {
                try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = frame_index, .reg = reg } });
                switch (loc) {
                    .scratch64 => selector.invalidateScratchContaining(reg),
                    else => {},
                }
            },
            .rax => {
                try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = frame_index });
                selector.current_eax_name = null;
            },
            .arg32, .scratch32, .arg128, .scratch128, .eax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => return .{ .no_emitter = "composed-block-spill-loc" },
        }
        try selector.bindValueLoc(name, .{ .spill64 = frame_index });
        return null;
    }

    fn spillCurrentPairs(selector: *ComposedBlockSelector) !?Diagnostic {
        if (selector.current_pair_a_name) |name| {
            if (try selector.spillPairValue(name)) |diagnostic| return diagnostic;
        }
        if (selector.current_pair_b_name) |name| {
            if (try selector.spillPairValue(name)) |diagnostic| return diagnostic;
        }
        return null;
    }

    fn spillPairValue(selector: *ComposedBlockSelector, name: []const u8) !?Diagnostic {
        if (selector.stack_frame_bytes < stack128FrameBytes()) return .{ .no_spill_envelope = "composed-block-pair-spill-frame" };
        const loc = selector.resolveValue(.{ .named = name }) orelse return .{ .unsupported_value = "composed-block-pair-spill-unknown" };
        switch (loc) {
            .spill128 => return null,
            else => {},
        }
        const pair = switch (loc) {
            .arg128, .scratch128 => |pair| pair,
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => return .{ .no_emitter = "composed-block-pair-spill-loc" },
        };
        const spill = selector.allocatePairSpillSlots(name) orelse return .{ .no_spill_envelope = "composed-block-pair-spill-slots" };
        try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.lo, .reg = pair.lo } });
        try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.hi, .reg = pair.hi } });
        selector.invalidatePair(pair);
        try selector.bindValueLoc(name, .{ .spill128 = spill });
        return null;
    }

    fn allocateSpillSlot(selector: *ComposedBlockSelector, name: []const u8) ?FrameIndex {
        for (selector.spill_slot_names, 0..) |slot_name, index| {
            if (slot_name) |existing| {
                if (std.mem.eql(u8, existing, name)) return spillFrameIndex(index);
            }
        }
        for (&selector.spill_slot_names, 0..) |*slot_name, index| {
            if (slot_name.* == null) {
                slot_name.* = name;
                return spillFrameIndex(index);
            }
        }
        for (&selector.spill_slot_names, 0..) |*slot_name, index| {
            const existing = slot_name.* orelse continue;
            if (!selector.spillSlotNameIsExpired(existing)) continue;
            slot_name.* = name;
            return spillFrameIndex(index);
        }
        return null;
    }

    fn spillSlotNameIsExpired(selector: ComposedBlockSelector, name: []const u8) bool {
        const plan = selector.allocation_plan orelse return false;
        const end = plan.intervalEnd(name) orelse return false;
        return end < selector.current_position;
    }

    fn allocatePairSpillSlots(selector: *ComposedBlockSelector, name: []const u8) ?PairSpillLoc {
        var first: ?usize = null;
        var second: ?usize = null;
        const start_index: usize = if (selector.stack_slot_allocated) 1 else 0;
        for (selector.spill_slot_names[start_index..], start_index..) |slot_name, index| {
            if (slot_name == null) {
                if (first == null) {
                    first = index;
                } else {
                    second = index;
                    break;
                }
            }
        }
        const lo_index = first orelse return null;
        const hi_index = second orelse return null;
        selector.spill_slot_names[lo_index] = name;
        selector.spill_slot_names[hi_index] = name;
        return .{ .lo = spillFrameIndex(lo_index), .hi = spillFrameIndex(hi_index) };
    }

    fn spillFrameIndex(index: usize) FrameIndex {
        return spillFrameIndexMaybe(index) orelse unreachable;
    }

    fn spillFrameIndexMaybe(index: usize) ?FrameIndex {
        return switch (index) {
            0 => .slot2,
            1 => .slot4,
            2 => .slot6,
            3 => .slot8,
            4 => .slot10,
            5 => .slot12,
            6 => .slot14,
            else => null,
        };
    }

    fn pairSpillFrameIndexMaybe(index: usize) ?PairSpillLoc {
        const lo = spillFrameIndexMaybe(index) orelse return null;
        const hi = spillFrameIndexMaybe(index + 1) orelse return null;
        return .{ .lo = lo, .hi = hi };
    }

    fn emitValueIntoEax(selector: *ComposedBlockSelector, value: ir.Value) !void {
        switch (value) {
            .int => |int| {
                selector.current_eax_name = null;
                try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(int) });
            },
            .named => {
                const loc = selector.resolveValue(value) orelse return error.UnsupportedCodegenValue;
                switch (loc) {
                    .arg32, .scratch32, .arg64, .scratch64 => |reg| {
                        selector.current_eax_name = null;
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_eax = reg });
                    },
                    .arg128, .scratch128 => |pair| {
                        selector.current_eax_name = null;
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_eax = pair.lo });
                    },
                    .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => return error.UnsupportedCodegenValue,
                    .eax, .rax => {},
                }
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        }
    }

    fn emitValueIntoRax(selector: *ComposedBlockSelector, value: ir.Value) !void {
        switch (value) {
            .int => return error.UnsupportedCodegenValue,
            .named => {
                const loc = selector.resolveValue(value) orelse return error.UnsupportedCodegenValue;
                switch (loc) {
                    .arg64, .scratch64 => |reg| {
                        selector.current_eax_name = null;
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = reg });
                    },
                    .spill64 => |frame_index| {
                        selector.current_eax_name = null;
                        try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = frame_index });
                    },
                    .arg128, .scratch128 => |pair| {
                        selector.current_eax_name = null;
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = pair.lo });
                    },
                    .rax => {},
                    .arg32, .scratch32, .eax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
                }
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        }
    }

    fn emitValueIntoAccumulator(selector: *ComposedBlockSelector, value: ir.Value, bits: u16) !void {
        if (bits == 64) try selector.emitValueIntoRax(value) else try selector.emitValueIntoEax(value);
    }

    fn preserveCurrentEaxIntoScratch(selector: *ComposedBlockSelector) !?Diagnostic {
        const name = selector.current_eax_name orelse return null;
        if (!selector.scratchRegIsProvenFree(.rdx)) return null;
        selector.invalidatePairContaining(.rdx);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = .rdx });
        try selector.bindValueLoc(name, .{ .scratch32 = .rdx });
        selector.current_scratch_names[argRegIndex(.rdx)] = name;
        selector.current_eax_name = null;
        return null;
    }

    fn scratchRegIsProvenFree(selector: ComposedBlockSelector, reg: ArgReg) bool {
        if (selector.current_scratch_names[argRegIndex(reg)] != null) return false;
        if (pair_a.contains(reg) and selector.current_pair_a_name != null) return false;
        if (pair_b.contains(reg) and selector.current_pair_b_name != null) return false;

        var it = selector.values.iterator();
        while (it.next()) |entry| {
            switch (entry.value_ptr.loc) {
                .arg32, .arg64, .scratch32, .scratch64 => |value_reg| if (value_reg == reg) return false,
                .arg128, .scratch128 => |pair| if (pair.contains(reg)) return false,
                .stack_i32_ptr => |stack_ptr| if (stack_ptr.index) |index| if (index.reg == reg) return false,
                .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .spill64, .spill128 => {},
            }
        }
        return true;
    }

    fn emitValueIntoI128Return(selector: *ComposedBlockSelector, value: ir.Value) !void {
        const loc = selector.resolveValue(value) orelse return error.UnsupportedCodegenValue;
        switch (loc) {
            .stack128_value => |disp| {
                try selector.loadStackU64IntoArg(.rdx, disp + 8);
                try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_rax = disp });
                selector.current_eax_name = null;
                selector.invalidateScratchContaining(.rdx);
                selector.invalidatePairContaining(.rdx);
            },
            .arg128, .scratch128 => |pair| {
                try selector.emitPairIntoAbiRegs(pair, .{ .lo = .rdi, .hi = .rdx });
                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = .rdi });
            },
            .spill128 => |spill| {
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = spill.hi } });
                try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = spill.lo });
                selector.current_eax_name = null;
                selector.invalidateScratchContaining(.rdx);
                selector.invalidatePairContaining(.rdx);
            },
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack64, .stack128, .stack_i32_array, .stack_i32_ptr, .spill64 => return error.UnsupportedCodegenValue,
        }
    }

    fn emitValueIntoScratch(selector: *ComposedBlockSelector, value: ir.Value, reg: ArgReg, bits: u16) !void {
        switch (value) {
            .int => return error.UnsupportedCodegenValue,
            .named => {
                const loc = selector.resolveValue(value) orelse return error.UnsupportedCodegenValue;
                if (bits == 64) {
                    switch (loc) {
                        .arg64, .scratch64 => |src| {
                            if (src != reg) {
                                selector.invalidateScratchContaining(reg);
                                selector.invalidatePairContaining(reg);
                                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{
                                    .dst = reg,
                                    .src = src,
                                } });
                            }
                        },
                        .rax => {
                            selector.invalidateScratchContaining(reg);
                            selector.invalidatePairContaining(reg);
                            try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = reg });
                        },
                        .spill64 => |frame_index| {
                            selector.invalidateScratchContaining(reg);
                            selector.invalidatePairContaining(reg);
                            try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = frame_index } });
                        },
                        .arg128, .scratch128 => |pair| {
                            if (pair.lo != reg) {
                                selector.invalidateScratchContaining(reg);
                                selector.invalidatePairContaining(reg);
                                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{
                                    .dst = reg,
                                    .src = pair.lo,
                                } });
                            }
                        },
                        .arg32, .scratch32, .eax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
                    }
                } else {
                    switch (loc) {
                        .arg32, .scratch32, .arg64, .scratch64 => |src| {
                            if (src != reg) {
                                selector.invalidateScratchContaining(reg);
                                selector.invalidatePairContaining(reg);
                                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{
                                    .dst = reg,
                                    .src = src,
                                } });
                            }
                        },
                        .arg128, .scratch128 => |pair| {
                            if (pair.lo != reg) {
                                selector.invalidateScratchContaining(reg);
                                selector.invalidatePairContaining(reg);
                                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{
                                    .dst = reg,
                                    .src = pair.lo,
                                } });
                            }
                        },
                        .eax, .rax => {
                            selector.invalidateScratchContaining(reg);
                            selector.invalidatePairContaining(reg);
                            try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = reg });
                        },
                        .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => return error.UnsupportedCodegenValue,
                    }
                }
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        }
    }

    fn emitBinaryArgAccumulator(selector: *ComposedBlockSelector, op: MachineBinaryOp, reg: ArgReg, bits: u16) !void {
        if (bits == 64) {
            try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{
                .op = op,
                .reg = reg,
            } });
        } else {
            try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_eax = .{
                .op = op,
                .reg = reg,
            } });
        }
    }

    fn emitBinaryLocIntoAccumulator(selector: *ComposedBlockSelector, op: MachineBinaryOp, loc: ValueLoc, bits: u16) !void {
        const reg = switch (loc) {
            .arg32, .scratch32 => |reg| if (bits <= 32) reg else return error.UnsupportedCodegenValue,
            .arg64, .scratch64 => |reg| if (bits == 64) reg else return error.UnsupportedCodegenValue,
            .spill64 => |frame_index| if (bits == 64) blk: {
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                break :blk .rcx;
            } else return error.UnsupportedCodegenValue,
            .arg128, .scratch128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
        };
        try selector.emitBinaryArgAccumulator(op, reg, bits);
    }

    fn emitPairLshrImmediate(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, amount: u7) !void {
        if (amount > 127) return error.UnsupportedCodegenValue;
        const existing = selector.resolvePairValue(value);
        const dst = if (existing) |src|
            selector.choosePairScratch(src) orelse return error.UnsupportedCodegenValue
        else
            selector.choosePairScratch(null) orelse return error.UnsupportedCodegenValue;
        const src = if (existing) |src| src else try selector.materializePairValue(value, dst);
        switch (amount) {
            0 => {
                try selector.emitPairIntoScratch(src, dst);
            },
            64 => {
                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.hi } });
                try selector.emitZeroArg64(dst.hi);
            },
            1...63 => {
                try selector.emitPairIntoScratch(src, dst);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = dst.hi });
                try selector.machine.instructions.append(selector.allocator, .{ .shl_rax_imm6 = @intCast(64 - amount) });
                try selector.machine.instructions.append(selector.allocator, .{ .shr_arg64_imm6 = .{ .reg = dst.lo, .amount = @intCast(amount) } });
                try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .@"or", .reg = dst.lo } });
                try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst.lo });
                try selector.machine.instructions.append(selector.allocator, .{ .shr_arg64_imm6 = .{ .reg = dst.hi, .amount = @intCast(amount) } });
            },
            65...127 => return error.UnsupportedCodegenValue,
        }
        try selector.bindPairScratch(result_name, dst);
    }

    fn emitPairShlImmediate(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, amount: u7) !void {
        if (amount != 64) return error.UnsupportedCodegenValue;
        const existing = selector.resolvePairValue(value);
        const dst = if (existing) |src| src else try selector.materializePairValue(value, pair_a);
        selector.invalidateScratchContaining(dst.hi);
        selector.invalidatePairContaining(dst.hi);
        if (dst.lo != dst.hi) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = dst.lo } });
        try selector.emitZeroArg64(dst.lo);
        try selector.bindPairScratch(result_name, dst);
    }

    fn emitPairIntoScratch(selector: *ComposedBlockSelector, src: RegPair, dst: RegPair) !void {
        if (src.eql(dst)) return;
        selector.current_eax_name = null;
        selector.invalidateScratchContaining(dst.lo);
        selector.invalidateScratchContaining(dst.hi);
        selector.invalidatePair(dst);
        if (src.lo != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.lo } });
        if (src.hi != dst.hi) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = src.hi } });
    }

    fn materializePairValue(selector: *ComposedBlockSelector, value: ir.Value, dst: RegPair) !RegPair {
        switch (value) {
            .named => {},
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        }
        const loc = selector.resolveValue(value) orelse return error.UnsupportedCodegenValue;
        switch (loc) {
            .arg128, .scratch128 => |src| {
                try selector.emitPairIntoScratch(src, dst);
                return dst;
            },
            .stack128_value => |disp| {
                try selector.loadStackU64IntoArg(dst.lo, disp);
                try selector.loadStackU64IntoArg(dst.hi, disp + 8);
                return dst;
            },
            .spill128 => |spill| {
                selector.current_eax_name = null;
                selector.invalidateScratchContaining(dst.lo);
                selector.invalidateScratchContaining(dst.hi);
                selector.invalidatePair(dst);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst.lo, .frame_index = spill.lo } });
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst.hi, .frame_index = spill.hi } });
                return dst;
            },
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack64, .stack128, .stack_i32_array, .stack_i32_ptr, .spill64 => return error.UnsupportedCodegenValue,
        }
    }

    fn emitPairLowLaneIntoScratch(selector: *ComposedBlockSelector, value: ir.Value, dst: ArgReg) !void {
        switch (value) {
            .named => {},
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        }
        const loc = selector.resolveValue(value) orelse return error.UnsupportedCodegenValue;
        selector.invalidateScratchContaining(dst);
        selector.invalidatePairContaining(dst);
        switch (loc) {
            .arg128, .scratch128 => |pair| {
                if (pair.lo != dst) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = pair.lo } });
            },
            .stack128_value => |disp| try selector.loadStackU64IntoArg(dst, disp),
            .spill128 => |spill| try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst, .frame_index = spill.lo } }),
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack64, .stack128, .stack_i32_array, .stack_i32_ptr, .spill64 => return error.UnsupportedCodegenValue,
        }
    }

    fn emitPairSignMask(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, dst: RegPair) !void {
        const src = try selector.materializePairValue(value, dst);
        if (src.hi != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.hi } });
        try selector.machine.instructions.append(selector.allocator, .{ .sar_arg64_imm6 = .{ .reg = dst.lo, .amount = 63 } });
        if (dst.hi != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = dst.lo } });
        try selector.bindPairScratch(result_name, dst);
    }

    fn emitPairXorInPlace(selector: *ComposedBlockSelector, dst: RegPair, rhs: RegPair) !void {
        try selector.emitPairLaneBinaryInto(dst.lo, .xor, dst.lo, rhs.lo);
        try selector.emitPairLaneBinaryInto(dst.hi, .xor, dst.hi, rhs.hi);
    }

    fn emitPairOrInPlace(selector: *ComposedBlockSelector, dst: RegPair, rhs: RegPair) !void {
        try selector.emitPairLaneBinaryInto(dst.lo, .@"or", dst.lo, rhs.lo);
        try selector.emitPairLaneBinaryInto(dst.hi, .@"or", dst.hi, rhs.hi);
    }

    fn emitPairSubInPlace(selector: *ComposedBlockSelector, dst: RegPair, rhs: RegPair) !void {
        selector.current_eax_name = null;
        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = dst.lo });
        try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .sub, .reg = rhs.lo } });
        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst.lo });
        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = dst.hi });
        try selector.machine.instructions.append(selector.allocator, .{ .sbb_arg64_rax = rhs.hi });
        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst.hi });
        selector.invalidateScratchContaining(dst.lo);
        selector.invalidateScratchContaining(dst.hi);
        selector.invalidatePair(dst);
    }

    fn emitPairLaneBinaryInto(selector: *ComposedBlockSelector, dst: ArgReg, op: MachineBinaryOp, lhs: ArgReg, rhs: ArgReg) !void {
        selector.current_eax_name = null;
        selector.invalidateScratchContaining(dst);
        selector.invalidatePairContaining(dst);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = lhs });
        try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{
            .op = op,
            .reg = rhs,
        } });
        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst });
    }

    fn emitZeroArg64(selector: *ComposedBlockSelector, reg: ArgReg) !void {
        selector.invalidateScratchContaining(reg);
        selector.invalidatePairContaining(reg);
        switch (reg) {
            .rdx => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rdx = 0 }),
            .rcx => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = 0 }),
            .r8 => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_r8 = 0 }),
            .r9 => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_r9 = 0 }),
            .rdi => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rdi = 0 }),
            .rsi => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rsi = 0 }),
        }
    }

    fn choosePairScratch(selector: ComposedBlockSelector, src: ?RegPair) ?RegPair {
        for (selector_allocatable_pairs) |pair| {
            if (src) |source| if (source.eql(pair)) continue;
            if (selector.pairScratchIsAvailableForUse(pair)) return pair;
        }
        return null;
    }

    fn pairScratchIsAvailableForUse(selector: ComposedBlockSelector, pair: RegPair) bool {
        return selector.scratch64RegIsAvailableForUse(pair.lo) and selector.scratch64RegIsAvailableForUse(pair.hi);
    }

    fn invalidatePair(selector: *ComposedBlockSelector, pair: RegPair) void {
        if (pair.eql(pair_a)) selector.current_pair_a_name = null;
        if (pair.eql(pair_b)) selector.current_pair_b_name = null;
    }

    fn invalidatePairContaining(selector: *ComposedBlockSelector, reg: ArgReg) void {
        if (pair_a.contains(reg)) selector.current_pair_a_name = null;
        if (pair_b.contains(reg)) selector.current_pair_b_name = null;
    }

    fn invalidateScratchContaining(selector: *ComposedBlockSelector, reg: ArgReg) void {
        selector.current_scratch_names[argRegIndex(reg)] = null;
    }

    fn invalidateCallClobbers(selector: *ComposedBlockSelector) void {
        selector.current_eax_name = null;
        selector.current_scratch_names = .{null} ** 6;
        selector.current_pair_a_name = null;
        selector.current_pair_b_name = null;
        selector.call_clobbered_regs = true;
    }

    const RegisterCache = struct {
        current_eax_name: ?[]const u8,
        current_scratch_names: [6]?[]const u8,
        current_pair_a_name: ?[]const u8,
        current_pair_b_name: ?[]const u8,
        call_clobbered_regs: bool,
    };

    fn saveRegisterCache(selector: ComposedBlockSelector) RegisterCache {
        return .{
            .current_eax_name = selector.current_eax_name,
            .current_scratch_names = selector.current_scratch_names,
            .current_pair_a_name = selector.current_pair_a_name,
            .current_pair_b_name = selector.current_pair_b_name,
            .call_clobbered_regs = selector.call_clobbered_regs,
        };
    }

    fn restoreRegisterCache(selector: *ComposedBlockSelector, cache: RegisterCache) void {
        selector.current_eax_name = cache.current_eax_name;
        selector.current_scratch_names = cache.current_scratch_names;
        selector.current_pair_a_name = cache.current_pair_a_name;
        selector.current_pair_b_name = cache.current_pair_b_name;
        selector.call_clobbered_regs = cache.call_clobbered_regs;
    }

    fn clearVolatileRegisterCache(selector: *ComposedBlockSelector) void {
        selector.current_eax_name = null;
        selector.current_scratch_names = .{null} ** 6;
        selector.current_pair_a_name = null;
        selector.current_pair_b_name = null;
    }

    fn resolvePairValue(selector: ComposedBlockSelector, value: ir.Value) ?RegPair {
        const loc = selector.resolveValue(value) orelse return null;
        return switch (loc) {
            .arg128, .scratch128 => |pair| pair,
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => null,
        };
    }

    fn resolveValue(selector: ComposedBlockSelector, value: ir.Value) ?ValueLoc {
        return switch (value) {
            .named => |name| {
                const loc = selector.valueLoc(name) orelse return null;
                return switch (loc) {
                    .arg32, .arg64, .arg128 => if (selector.call_clobbered_regs) null else loc,
                    .eax, .rax => if (selector.current_eax_name) |current| blk: {
                        if (std.mem.eql(u8, current, name)) break :blk loc;
                        return null;
                    } else null,
                    .scratch32, .scratch64 => |reg| if (selector.current_scratch_names[argRegIndex(reg)]) |current| blk: {
                        if (std.mem.eql(u8, current, name)) break :blk loc;
                        return null;
                    } else null,
                    .scratch128 => |pair| {
                        const current = if (pair.eql(pair_a))
                            selector.current_pair_a_name
                        else if (pair.eql(pair_b))
                            selector.current_pair_b_name
                        else
                            null;
                        if (current) |current_name| {
                            if (std.mem.eql(u8, current_name, name)) return loc;
                        }
                        return null;
                    },
                    .stack64, .stack128, .stack128_value, .stack_i32_array, .spill64, .spill128 => loc,
                    .stack_i32_ptr => |stack_ptr| if (stack_ptr.index) |index| blk: {
                        if (selector.current_scratch_names[argRegIndex(index.reg)]) |current| {
                            if (std.mem.eql(u8, current, index.name)) break :blk loc;
                        }
                        return null;
                    } else loc,
                };
            },
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
        };
    }
};

test "generic cfg selector virtual register metadata follows assignment class" {
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .gpr32, .bits = 32 }, ComposedBlockSelector.virtualRegMetadata(.eax));
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .gpr64, .bits = 64 }, ComposedBlockSelector.virtualRegMetadata(.rax));
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .gpr128, .bits = 128 }, ComposedBlockSelector.virtualRegMetadata(.{ .scratch128 = pair_a }));
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .stack_object, .bits = 0 }, ComposedBlockSelector.virtualRegMetadata(.{ .stack_i32_array = .{
        .base_disp = 16,
        .len = 4,
    } }));
    try std.testing.expectEqual(VirtualRegMetadata{ .class = .stack_pointer, .bits = 64 }, ComposedBlockSelector.virtualRegMetadata(.{ .stack_i32_ptr = .{ .disp = 16 } }));
}

test "generic cfg selector consumes matching no-spill planned result locations" {
    var machine = MachineFunction.init("planned", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.assignments.put("kept", .{ .gpr64 = .rcx });
    try plan.assignments.put("deferred", .{ .gpr64 = .rdx });

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;

    try selector.bindResultLoc("kept", .{ .scratch64 = .rcx });
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector.valueLoc("kept").?);
    try std.testing.expectEqualStrings("kept", selector.current_scratch_names[argRegIndex(.rcx)].?);

    try selector.bindResultLoc("deferred", .{ .scratch64 = .r8 });
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .r8 }, selector.valueLoc("deferred").?);
    try std.testing.expectEqualStrings("deferred", selector.current_scratch_names[argRegIndex(.r8)].?);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "generic cfg selector expires planned intervals before register reuse" {
    var machine = MachineFunction.init("planned-reuse", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.assignments.put("old", .{ .gpr64 = .rdi });
    try plan.interval_ends.put("old", 1);
    try plan.assignments.put("new", .{ .gpr64 = .rdi });
    try plan.interval_ends.put("new", 2);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.enable_expired_plan_register_reuse = true;
    selector.current_position = 2;

    try selector.bindValueLoc("old", .{ .arg64 = .rdi });
    try selector.bindValueLoc("source", .{ .scratch64 = .rcx });
    selector.current_scratch_names[argRegIndex(.rcx)] = "source";

    try selector.expireExpiredBindings();
    try std.testing.expectEqual(ValueLoc{ .arg64 = .rdi }, selector.valueLoc("old").?);

    try selector.bindResultLoc("new", .{ .scratch64 = .rcx });
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rdi }, selector.valueLoc("new").?);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg64_arg = .{ .dst = .rdi, .src = .rcx } }, machine.instructions.items[0]);
}

test "generic cfg selector routes i128 trunc through planned expired register" {
    var machine = MachineFunction.init("planned-trunc", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.assignments.put("old", .{ .gpr64 = .r8 });
    try plan.interval_ends.put("old", 1);
    try plan.assignments.put("lo", .{ .gpr64 = .r8 });
    try plan.interval_ends.put("lo", 2);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.enable_expired_plan_register_reuse = true;
    selector.current_position = 2;

    try selector.bindValueLoc("old", .{ .scratch64 = .r8 });
    selector.current_scratch_names[argRegIndex(.r8)] = "old";
    try selector.bindValueLoc("wide", .{ .arg128 = .{ .lo = .rdi, .hi = .rsi } });

    try selector.expireExpiredBindings();
    const diagnostic = try selector.lowerCast("lo", .{
        .op = .trunc,
        .from_ty = .{ .int = 128 },
        .value = .{ .named = "wide" },
        .to_ty = .{ .int = 64 },
    });
    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .r8 }, selector.valueLoc("lo").?);
    try std.testing.expectEqualStrings("lo", selector.current_scratch_names[argRegIndex(.r8)].?);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg64_arg = .{ .dst = .r8, .src = .rdi } }, machine.instructions.items[0]);
}

test "generic cfg selector materializes mul64 lhs into planned register" {
    var machine = MachineFunction.init("planned-mul64", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.assignments.put("old", .{ .gpr64 = .r8 });
    try plan.interval_ends.put("old", 1);
    try plan.assignments.put("product", .{ .gpr64 = .r8 });
    try plan.interval_ends.put("product", 2);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.enable_expired_plan_register_reuse = true;
    selector.current_position = 2;

    try selector.bindValueLoc("old", .{ .scratch64 = .r8 });
    selector.current_scratch_names[argRegIndex(.r8)] = "old";
    try selector.bindValueLoc("lhs", .{ .arg64 = .rdi });
    try selector.bindValueLoc("rhs", .{ .arg64 = .rsi });

    try selector.expireExpiredBindings();
    const diagnostic = try selector.lowerMul64("product", .{
        .op = .mul,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    });
    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .r8 }, selector.valueLoc("product").?);
    try std.testing.expectEqualStrings("product", selector.current_scratch_names[argRegIndex(.r8)].?);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg64_arg = .{ .dst = .r8, .src = .rdi } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .imul_arg64_arg64 = .{ .dst = .r8, .src = .rsi } }, machine.instructions.items[1]);
}

test "generic cfg selector reloads spilled mul64 rhs through rax when scratch registers are live" {
    var machine = MachineFunction.init("mul64-spill-rhs-rax", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("live_rdi", 10);
    try plan.interval_ends.put("live_rsi", 10);
    try plan.interval_ends.put("lhs", 4);
    try plan.interval_ends.put("live_rcx", 10);
    try plan.interval_ends.put("live_r8", 10);
    try plan.interval_ends.put("live_r9", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.enable_expired_plan_register_reuse = true;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector.bindValueLoc("live_rdi", .{ .scratch64 = .rdi });
    selector.current_scratch_names[argRegIndex(.rdi)] = "live_rdi";
    try selector.bindValueLoc("live_rsi", .{ .scratch64 = .rsi });
    selector.current_scratch_names[argRegIndex(.rsi)] = "live_rsi";
    try selector.bindValueLoc("lhs", .{ .scratch64 = .rdx });
    selector.current_scratch_names[argRegIndex(.rdx)] = "lhs";
    try selector.bindValueLoc("live_rcx", .{ .scratch64 = .rcx });
    selector.current_scratch_names[argRegIndex(.rcx)] = "live_rcx";
    try selector.bindValueLoc("live_r8", .{ .scratch64 = .r8 });
    selector.current_scratch_names[argRegIndex(.r8)] = "live_r8";
    try selector.bindValueLoc("live_r9", .{ .scratch64 = .r9 });
    selector.current_scratch_names[argRegIndex(.r9)] = "live_r9";
    try selector.bindValueLoc("rhs", .{ .spill64 = .slot2 });

    const diagnostic = try selector.lowerMul64("product", .{
        .op = .mul,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rdx }, selector.valueLoc("product").?);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_rsp_rax = .slot2 }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .imul_arg64_rax = .rdx }, machine.instructions.items[1]);
}

test "generic cfg selector spills live mul64 lhs before reusing its scratch register" {
    var machine = MachineFunction.init("mul64-spill-live-lhs", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("live_rdi", 10);
    try plan.interval_ends.put("rhs", 10);
    try plan.interval_ends.put("lhs", 10);
    try plan.interval_ends.put("live_rcx", 10);
    try plan.interval_ends.put("live_r8", 10);
    try plan.interval_ends.put("live_r9", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.enable_expired_plan_register_reuse = true;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector.bindValueLoc("live_rdi", .{ .scratch64 = .rdi });
    selector.current_scratch_names[argRegIndex(.rdi)] = "live_rdi";
    try selector.bindValueLoc("rhs", .{ .scratch64 = .rsi });
    selector.current_scratch_names[argRegIndex(.rsi)] = "rhs";
    try selector.bindValueLoc("lhs", .{ .scratch64 = .rdx });
    selector.current_scratch_names[argRegIndex(.rdx)] = "lhs";
    try selector.bindValueLoc("live_rcx", .{ .scratch64 = .rcx });
    selector.current_scratch_names[argRegIndex(.rcx)] = "live_rcx";
    try selector.bindValueLoc("live_r8", .{ .scratch64 = .r8 });
    selector.current_scratch_names[argRegIndex(.r8)] = "live_r8";
    try selector.bindValueLoc("live_r9", .{ .scratch64 = .r9 });
    selector.current_scratch_names[argRegIndex(.r9)] = "live_r9";

    const diagnostic = try selector.lowerMul64("product", .{
        .op = .mul,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot2 }, selector.valueLoc("lhs").?);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rdx }, selector.valueLoc("product").?);
    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = .rdx } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = .slot2 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .imul_arg64_arg64 = .{ .dst = .rdx, .src = .rsi } }, machine.instructions.items[2]);
}

test "generic cfg selector reloads spilled mul64 lhs through rax when scratch registers are live" {
    var machine = MachineFunction.init("mul64-spill-lhs-rax", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("live_rax", 10);
    try plan.interval_ends.put("live_rdi", 10);
    try plan.interval_ends.put("live_rsi", 10);
    try plan.interval_ends.put("live_rdx", 10);
    try plan.interval_ends.put("live_rcx", 10);
    try plan.interval_ends.put("live_r8", 10);
    try plan.interval_ends.put("live_r9", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.enable_expired_plan_register_reuse = true;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector.bindValueLoc("live_rax", .rax);
    selector.current_eax_name = "live_rax";
    try selector.bindValueLoc("live_rdi", .{ .scratch64 = .rdi });
    selector.current_scratch_names[argRegIndex(.rdi)] = "live_rdi";
    try selector.bindValueLoc("live_rsi", .{ .scratch64 = .rsi });
    selector.current_scratch_names[argRegIndex(.rsi)] = "live_rsi";
    try selector.bindValueLoc("live_rdx", .{ .scratch64 = .rdx });
    selector.current_scratch_names[argRegIndex(.rdx)] = "live_rdx";
    try selector.bindValueLoc("live_rcx", .{ .scratch64 = .rcx });
    selector.current_scratch_names[argRegIndex(.rcx)] = "live_rcx";
    try selector.bindValueLoc("live_r8", .{ .scratch64 = .r8 });
    selector.current_scratch_names[argRegIndex(.r8)] = "live_r8";
    try selector.bindValueLoc("live_r9", .{ .scratch64 = .r9 });
    selector.current_scratch_names[argRegIndex(.r9)] = "live_r9";
    try selector.bindValueLoc("lhs", .{ .spill64 = .slot10 });
    try selector.bindValueLoc("rhs", .{ .spill64 = .slot12 });

    const diagnostic = try selector.lowerMul64("product", .{
        .op = .mul,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot2 }, selector.valueLoc("live_rax").?);
    try std.testing.expectEqual(ValueLoc.rax, selector.valueLoc("product").?);
    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_rax_rsp = .slot2 }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_rsp_rax = .slot10 }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .imul_rax_rsp = .slot12 }, machine.instructions.items[2]);
}

test "generic cfg selector reuses expired scalar spill slots" {
    var machine = MachineFunction.init("spill-slot-reuse", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("old0", 1);
    try plan.interval_ends.put("live1", 10);
    try plan.interval_ends.put("live2", 10);
    try plan.interval_ends.put("live3", 10);
    try plan.interval_ends.put("live4", 10);
    try plan.interval_ends.put("live5", 10);
    try plan.interval_ends.put("live6", 10);
    try plan.interval_ends.put("value", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.stack_frame_bytes = stage2SpillReservedBytes();
    selector.spill_slot_names = .{ "old0", "live1", "live2", "live3", "live4", "live5", "live6" };

    try selector.bindValueLoc("value", .rax);
    selector.current_eax_name = "value";

    const diagnostic = try selector.spillValue("value");

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot2 }, selector.valueLoc("value").?);
    try std.testing.expectEqualStrings("value", selector.spill_slot_names[0].?);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_rax_rsp = .slot2 }, machine.instructions.items[0]);
}

test "generic cfg selector reloads spilled pair for i128 lshr immediate" {
    var machine = MachineFunction.init("spill-pair-lshr", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try selector.bindValueLoc("wide", .{ .spill128 = .{ .lo = .slot6, .hi = .slot8 } });
    try selector.emitPairLshrImmediate("shifted", .{ .named = "wide" }, 64);

    const dst = pair_a;
    try std.testing.expectEqual(ValueLoc{ .scratch128 = dst }, selector.valueLoc("shifted").?);
    try std.testing.expectEqual(@as(usize, 4), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg64_rsp = .{ .reg = dst.lo, .frame_index = .slot6 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg64_rsp = .{ .reg = dst.hi, .frame_index = .slot8 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg64_arg = .{ .dst = dst.lo, .src = dst.hi } }, machine.instructions.items[2]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_imm_rdx = 0 }, machine.instructions.items[3]);
}

test "generic cfg selector pair lshr avoids live scalar scratch values" {
    var machine = MachineFunction.init("pair-lshr-avoid-live-scalar", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("lo", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 2;
    selector.enable_expired_plan_register_reuse = true;

    try selector.bindValueLoc("wide", .{ .arg128 = .{ .lo = .rdi, .hi = .rsi } });
    try selector.bindValueLoc("other_wide", .{ .arg128 = .{ .lo = .rdx, .hi = .rcx } });
    try selector.bindValueLoc("lo", .{ .scratch64 = .rcx });
    selector.current_scratch_names[argRegIndex(.rcx)] = "lo";

    try selector.emitPairLshrImmediate("hi", .{ .named = "wide" }, 64);

    try std.testing.expectEqual(ValueLoc{ .scratch128 = pair_b }, selector.valueLoc("hi").?);
    try std.testing.expectEqualStrings("lo", selector.current_scratch_names[argRegIndex(.rcx)].?);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg64_arg = .{ .dst = pair_b.lo, .src = .rsi } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_imm_r9 = 0 }, machine.instructions.items[1]);
}

test "generic cfg selector reloads spilled pair for i128 shl immediate" {
    var machine = MachineFunction.init("spill-pair-shl", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try selector.bindValueLoc("wide", .{ .spill128 = .{ .lo = .slot6, .hi = .slot8 } });
    try selector.emitPairShlImmediate("shifted", .{ .named = "wide" }, 64);

    try std.testing.expectEqual(ValueLoc{ .scratch128 = pair_a }, selector.valueLoc("shifted").?);
    try std.testing.expectEqual(@as(usize, 4), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg64_rsp = .{ .reg = pair_a.lo, .frame_index = .slot6 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg64_rsp = .{ .reg = pair_a.hi, .frame_index = .slot8 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg64_arg = .{ .dst = pair_a.hi, .src = pair_a.lo } }, machine.instructions.items[2]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_imm_rcx = 0 }, machine.instructions.items[3]);
}

test "generic cfg selector reloads spilled pair for i128 trunc" {
    var machine = MachineFunction.init("spill-pair-trunc", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try selector.bindValueLoc("wide", .{ .spill128 = .{ .lo = .slot6, .hi = .slot8 } });
    const diagnostic = try selector.lowerCast("lo", .{
        .op = .trunc,
        .value = .{ .named = "wide" },
        .from_ty = .{ .int = 128 },
        .to_ty = .{ .int = 64 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rdi }, selector.valueLoc("lo").?);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot6 } }, machine.instructions.items[0]);
}

test "generic cfg selector i128 trunc reuses source low lane without clobbering live scalar" {
    var machine = MachineFunction.init("pair-trunc-avoid-live-scalar", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("lo", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 3;
    selector.enable_expired_plan_register_reuse = true;

    try selector.bindValueLoc("lo", .{ .scratch64 = .rcx });
    selector.current_scratch_names[argRegIndex(.rcx)] = "lo";
    try selector.bindValueLoc("shifted", .{ .scratch128 = pair_b });
    selector.current_pair_b_name = "shifted";

    const diagnostic = try selector.lowerCast("hi", .{
        .op = .trunc,
        .value = .{ .named = "shifted" },
        .from_ty = .{ .int = 128 },
        .to_ty = .{ .int = 64 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = pair_b.lo }, selector.valueLoc("hi").?);
    try std.testing.expectEqualStrings("lo", selector.current_scratch_names[argRegIndex(.rcx)].?);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "generic cfg selector masks reloaded i64 spill low half" {
    var machine = MachineFunction.init("spill-mask", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try selector.bindValueLoc("wide_lo", .{ .spill64 = .slot6 });
    const diagnostic = try selector.lowerBinaryImmediateRhs("masked", .{
        .op = .@"and",
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "wide_lo" },
        .rhs = .{ .int = std.math.maxInt(u32) },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc.rax, selector.valueLoc("masked").?);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_rsp_rax = .slot6 }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .and_eax_imm32 = -1 }, machine.instructions.items[1]);
}

test "generic cfg selector preserves live rax before another i64 low-half mask" {
    var machine = MachineFunction.init("preserve-rax-mask", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector.bindValueLoc("left_masked", .rax);
    selector.current_eax_name = "left_masked";
    try selector.bindValueLoc("right", .{ .scratch64 = .rsi });
    selector.current_scratch_names[argRegIndex(.rsi)] = "right";

    const diagnostic = try selector.lowerBinaryImmediateRhs("right_masked", .{
        .op = .@"and",
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "right" },
        .rhs = .{ .int = std.math.maxInt(u32) },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot2 }, selector.valueLoc("left_masked").?);
    try std.testing.expectEqual(ValueLoc.rax, selector.valueLoc("right_masked").?);
    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_rax_rsp = .slot2 }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg_rax = .rsi }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .and_eax_imm32 = -1 }, machine.instructions.items[2]);
}

test "generic cfg selector lshr64 avoids live scalar scratch values" {
    var machine = MachineFunction.init("lshr64-avoid-live-scalar", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("live", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.enable_expired_plan_register_reuse = true;

    try selector.bindValueLoc("live", .{ .scratch64 = .rcx });
    selector.current_scratch_names[argRegIndex(.rcx)] = "live";
    try selector.bindValueLoc("source", .{ .scratch64 = .r8 });
    selector.current_scratch_names[argRegIndex(.r8)] = "source";

    const diagnostic = try selector.lowerBinaryImmediateRhs("shifted", .{
        .op = .lshr,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "source" },
        .rhs = .{ .int = 32 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqualStrings("live", selector.current_scratch_names[argRegIndex(.rcx)].?);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rdi }, selector.valueLoc("shifted").?);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg64_arg = .{ .dst = .rdi, .src = .r8 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .shr_arg64_imm6 = .{ .reg = .rdi, .amount = 32 } }, machine.instructions.items[1]);
}

test "generic cfg selector lshr64 reuses dead source scratch register" {
    var machine = MachineFunction.init("lshr64-reuse-dead-source", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("source", 4);
    try plan.interval_ends.put("live_rdi", 10);
    try plan.interval_ends.put("live_rsi", 10);
    try plan.interval_ends.put("live_rdx", 10);
    try plan.interval_ends.put("live_r8", 10);
    try plan.interval_ends.put("live_r9", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.enable_expired_plan_register_reuse = true;

    try selector.bindValueLoc("source", .{ .scratch64 = .rcx });
    selector.current_scratch_names[argRegIndex(.rcx)] = "source";
    try selector.bindValueLoc("live_rdi", .{ .scratch64 = .rdi });
    selector.current_scratch_names[argRegIndex(.rdi)] = "live_rdi";
    try selector.bindValueLoc("live_rsi", .{ .scratch64 = .rsi });
    selector.current_scratch_names[argRegIndex(.rsi)] = "live_rsi";
    try selector.bindValueLoc("live_rdx", .{ .scratch64 = .rdx });
    selector.current_scratch_names[argRegIndex(.rdx)] = "live_rdx";
    try selector.bindValueLoc("live_r8", .{ .scratch64 = .r8 });
    selector.current_scratch_names[argRegIndex(.r8)] = "live_r8";
    try selector.bindValueLoc("live_r9", .{ .scratch64 = .r9 });
    selector.current_scratch_names[argRegIndex(.r9)] = "live_r9";

    const diagnostic = try selector.lowerBinaryImmediateRhs("shifted", .{
        .op = .lshr,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "source" },
        .rhs = .{ .int = 32 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector.valueLoc("shifted").?);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .shr_arg64_imm6 = .{ .reg = .rcx, .amount = 32 } }, machine.instructions.items[0]);
}

test "generic cfg selector shl64 spills live rax source before destructive shift" {
    var machine = MachineFunction.init("shl64-preserve-rax-source", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("source", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.enable_expired_plan_register_reuse = true;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector.bindValueLoc("source", .rax);
    selector.current_eax_name = "source";

    const diagnostic = try selector.lowerBinaryImmediateRhs("shifted", .{
        .op = .shl,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "source" },
        .rhs = .{ .int = 32 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot2 }, selector.valueLoc("source").?);
    try std.testing.expectEqual(ValueLoc.rax, selector.valueLoc("shifted").?);
    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_rax_rsp = .slot2 }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_rsp_rax = .slot2 }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .shl_rax_imm6 = 32 }, machine.instructions.items[2]);
}

test "generic cfg selector lshr64 spills live source before reusing its scratch register" {
    var machine = MachineFunction.init("lshr64-spill-live-source", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("source", 10);
    try plan.interval_ends.put("live_rdi", 10);
    try plan.interval_ends.put("live_rsi", 10);
    try plan.interval_ends.put("live_rdx", 10);
    try plan.interval_ends.put("live_r8", 10);
    try plan.interval_ends.put("live_r9", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.enable_expired_plan_register_reuse = true;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector.bindValueLoc("source", .{ .scratch64 = .rcx });
    selector.current_scratch_names[argRegIndex(.rcx)] = "source";
    try selector.bindValueLoc("live_rdi", .{ .scratch64 = .rdi });
    selector.current_scratch_names[argRegIndex(.rdi)] = "live_rdi";
    try selector.bindValueLoc("live_rsi", .{ .scratch64 = .rsi });
    selector.current_scratch_names[argRegIndex(.rsi)] = "live_rsi";
    try selector.bindValueLoc("live_rdx", .{ .scratch64 = .rdx });
    selector.current_scratch_names[argRegIndex(.rdx)] = "live_rdx";
    try selector.bindValueLoc("live_r8", .{ .scratch64 = .r8 });
    selector.current_scratch_names[argRegIndex(.r8)] = "live_r8";
    try selector.bindValueLoc("live_r9", .{ .scratch64 = .r9 });
    selector.current_scratch_names[argRegIndex(.r9)] = "live_r9";

    const diagnostic = try selector.lowerBinaryImmediateRhs("shifted", .{
        .op = .lshr,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "source" },
        .rhs = .{ .int = 32 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot2 }, selector.valueLoc("source").?);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rcx }, selector.valueLoc("shifted").?);
    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = .rcx } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot2 } }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .shr_arg64_imm6 = .{ .reg = .rcx, .amount = 32 } }, machine.instructions.items[2]);
}

test "generic cfg selector lshr64 reloads spilled source through rax when scratch registers are live" {
    var machine = MachineFunction.init("lshr64-spill-source-rax", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("live_rax", 10);
    try plan.interval_ends.put("live_rdi", 10);
    try plan.interval_ends.put("live_rsi", 10);
    try plan.interval_ends.put("live_rdx", 10);
    try plan.interval_ends.put("live_rcx", 10);
    try plan.interval_ends.put("live_r8", 10);
    try plan.interval_ends.put("live_r9", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 4;
    selector.enable_expired_plan_register_reuse = true;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector.bindValueLoc("live_rax", .rax);
    selector.current_eax_name = "live_rax";
    try selector.bindValueLoc("live_rdi", .{ .scratch64 = .rdi });
    selector.current_scratch_names[argRegIndex(.rdi)] = "live_rdi";
    try selector.bindValueLoc("live_rsi", .{ .scratch64 = .rsi });
    selector.current_scratch_names[argRegIndex(.rsi)] = "live_rsi";
    try selector.bindValueLoc("live_rdx", .{ .scratch64 = .rdx });
    selector.current_scratch_names[argRegIndex(.rdx)] = "live_rdx";
    try selector.bindValueLoc("live_rcx", .{ .scratch64 = .rcx });
    selector.current_scratch_names[argRegIndex(.rcx)] = "live_rcx";
    try selector.bindValueLoc("live_r8", .{ .scratch64 = .r8 });
    selector.current_scratch_names[argRegIndex(.r8)] = "live_r8";
    try selector.bindValueLoc("live_r9", .{ .scratch64 = .r9 });
    selector.current_scratch_names[argRegIndex(.r9)] = "live_r9";
    try selector.bindValueLoc("source", .{ .spill64 = .slot10 });

    const diagnostic = try selector.lowerBinaryImmediateRhs("shifted", .{
        .op = .lshr,
        .ty = .{ .int = 64 },
        .lhs = .{ .named = "source" },
        .rhs = .{ .int = 32 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot2 }, selector.valueLoc("live_rax").?);
    try std.testing.expectEqual(ValueLoc.rax, selector.valueLoc("shifted").?);
    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_rax_rsp = .slot2 }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_rsp_rax = .slot10 }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .shr_rax_imm6 = 32 }, machine.instructions.items[2]);
}

test "generic cfg selector returns spilled i128 pair" {
    var machine = MachineFunction.init("spill-pair-return", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try selector.bindValueLoc("wide", .{ .spill128 = .{ .lo = .slot6, .hi = .slot8 } });
    try selector.emitValueIntoI128Return(.{ .named = "wide" });

    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = .slot8 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_rsp_rax = .slot6 }, machine.instructions.items[1]);
}

test "generic cfg selector returns overlapping i128 pair without scratch envelope" {
    var machine = MachineFunction.init("overlap-pair-return", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    try selector.bindValueLoc("wide", .{ .scratch128 = pair_a });
    selector.current_pair_a_name = "wide";
    try selector.emitValueIntoI128Return(.{ .named = "wide" });

    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg64_arg = .{ .dst = .rdi, .src = .rcx } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg_rax = .rdi }, machine.instructions.items[1]);
}

test "generic cfg selector stores scalar planned spills in deterministic frame slots" {
    var machine = MachineFunction.init("planned-spill", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.assignments.put("spilled", .{ .spill = 2 });

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = stage2SpillReservedBytes();

    try selector.bindResultLoc("spilled", .{ .scratch64 = .rcx });
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot6 }, selector.valueLoc("spilled").?);
    try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_arg64_rsp = .{ .frame_index = .slot6, .reg = .rcx } }, machine.instructions.items[0]);
    try std.testing.expect(selector.current_scratch_names[argRegIndex(.rcx)] == null);
}

test "generic cfg selector stores planned pair spills in deterministic frame slots" {
    var machine = MachineFunction.init("planned-pair-spill", .{ .int = 128 });
    defer machine.deinit(std.testing.allocator);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.assignments.put("pair", .{ .spill = 3 });

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = stage2SpillReservedBytes();
    selector.current_pair_a_name = "pair";

    try selector.bindResultLoc("pair", .{ .scratch128 = pair_a });
    try std.testing.expectEqual(ValueLoc{ .spill128 = .{ .lo = .slot8, .hi = .slot10 } }, selector.valueLoc("pair").?);
    try std.testing.expectEqual(@as(usize, 2), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_arg64_rsp = .{ .frame_index = .slot8, .reg = pair_a.lo } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_arg64_rsp = .{ .frame_index = .slot10, .reg = pair_a.hi } }, machine.instructions.items[1]);
    try std.testing.expect(selector.current_pair_a_name == null);
}

test "generic cfg selector allocation plan reuses expired registers deterministically" {
    const intervals = [_]SelectorValueInterval{
        .{ .name = "a", .class = .gpr64, .bits = 64, .start = 0, .end = 1 },
        .{ .name = "b", .class = .gpr64, .bits = 64, .start = 2, .end = 3 },
    };
    var plan = try allocateSelectorIntervals(std.testing.allocator, intervals[0..]);
    defer plan.deinit();

    try std.testing.expectEqual(@as(usize, 0), plan.spill_slots);
    try std.testing.expectEqual(PlannedValueAssignment{ .gpr64 = .rdi }, plan.assignment("a").?);
    try std.testing.expectEqual(PlannedValueAssignment{ .gpr64 = .rdi }, plan.assignment("b").?);
    try std.testing.expectEqual(@as(usize, 1), plan.intervalEnd("a").?);
    try std.testing.expectEqual(@as(usize, 3), plan.intervalEnd("b").?);
}

test "generic cfg selector allocation plan spills beyond register pool" {
    const intervals = [_]SelectorValueInterval{
        .{ .name = "v0", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "v1", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "v2", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "v3", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "v4", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "v5", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "v6", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
    };
    var plan = try allocateSelectorIntervals(std.testing.allocator, intervals[0..]);
    defer plan.deinit();

    try std.testing.expectEqual(@as(usize, 1), plan.spill_slots);
    try std.testing.expectEqual(PlannedValueAssignment{ .gpr64 = .rdi }, plan.assignment("v0").?);
    try std.testing.expectEqual(PlannedValueAssignment{ .gpr64 = .rsi }, plan.assignment("v1").?);
    try std.testing.expectEqual(PlannedValueAssignment{ .spill = 0 }, plan.assignment("v6").?);
}

test "generic cfg selector allocation plan reserves two slots for pair spills" {
    const intervals = [_]SelectorValueInterval{
        .{ .name = "a0", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "a1", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "a2", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "a3", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "a4", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "a5", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
        .{ .name = "zwide", .class = .gpr128, .bits = 128, .start = 0, .end = 10 },
        .{ .name = "zzscalar", .class = .gpr64, .bits = 64, .start = 0, .end = 10 },
    };
    var plan = try allocateSelectorIntervals(std.testing.allocator, intervals[0..]);
    defer plan.deinit();

    try std.testing.expectEqual(@as(usize, 3), plan.spill_slots);
    try std.testing.expectEqual(PlannedValueAssignment{ .spill = 0 }, plan.assignment("zwide").?);
    try std.testing.expectEqual(PlannedValueAssignment{ .spill = 2 }, plan.assignment("zzscalar").?);
}

fn blockHasPhiIncomingFrom(block: ir.BasicBlock, predecessor: []const u8) bool {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const phi = switch (instruction.kind) {
            .phi => |phi| phi,
            else => break,
        };
        if (phiIncomingFrom(phi, predecessor) != null) return true;
    }
    return false;
}

fn phiIncomingFrom(phi: ir.PhiInst, predecessor: []const u8) ?ir.PhiIncoming {
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, predecessor)) return incoming;
    }
    return null;
}

const RegPair = struct {
    lo: ArgReg,
    hi: ArgReg,

    fn eql(pair: RegPair, other: RegPair) bool {
        return pair.lo == other.lo and pair.hi == other.hi;
    }

    fn contains(pair: RegPair, reg: ArgReg) bool {
        return pair.lo == reg or pair.hi == reg;
    }
};

const pair_a: RegPair = .{ .lo = .rcx, .hi = .rdx };
const pair_b: RegPair = .{ .lo = .r8, .hi = .r9 };
const selector_allocatable_regs = [_]ArgReg{ .rdi, .rsi, .rdx, .rcx, .r8, .r9 };
const selector_allocatable_pairs = [_]RegPair{ pair_a, pair_b };

fn tryLowerComposedBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !SelectionResult {
    if (!isComposedReturnType(function.ret_ty)) return unsupported(.{ .no_emitter = "composed-block-ret-type" });
    if (function.blocks.items.len != 1) return unsupported(.{ .no_emitter = "composed-block-not-single-block" });

    var allocation_plan = try buildSelectorAllocationPlan(allocator, function);
    defer allocation_plan.deinit();

    var composed = ComposedBlockSelector.init(allocator, machine);
    composed.allocation_plan = &allocation_plan;
    composed.enable_expired_plan_register_reuse = canUseExpiredPlanRegisterReuse(function);
    defer composed.deinit();

    if (try composed.bindParams(function)) |diagnostic| return unsupported(diagnostic);
    if (try composed.prepareStackFrame(function)) |diagnostic| return unsupported(diagnostic);

    const block = function.blocks.items[0];
    for (block.instructions.items) |instruction| {
        if (try composed.lowerInstruction(instruction)) |diagnostic| return unsupported(diagnostic);
    }

    const terminator = block.terminator orelse return unsupported(.{ .unsupported_control_flow = "composed-block-missing-terminator" });
    try composed.expireExpiredBindings();
    switch (terminator) {
        .ret => |ret| {
            if (try composed.lowerReturn(ret)) |diagnostic| return unsupported(diagnostic);
        },
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return unsupported(.{ .no_emitter = "composed-block-terminator-not-owned" }),
    }
    return .selected;
}

fn canUseExpiredPlanRegisterReuse(function: ir.Function) bool {
    if (intBits(function.ret_ty) != 128) return false;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.kind == .call) return false;
        }
    }
    return true;
}

fn machineBinaryOp(op: ir.BinaryOp) ?MachineBinaryOp {
    return switch (op) {
        .add => .add,
        .sub => .sub,
        .@"and" => .@"and",
        .@"or" => .@"or",
        .xor => .xor,
        .fadd, .fsub, .fmul, .fdiv, .frem, .mul, .shl, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => null,
    };
}

fn isCommutative(op: MachineBinaryOp) bool {
    return switch (op) {
        .add, .@"and", .@"or", .xor => true,
        .sub => false,
    };
}

fn locIsAccumulator(loc: ValueLoc) bool {
    return switch (loc) {
        .eax, .rax => true,
        .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => false,
    };
}

fn valueLocEql(lhs: ValueLoc, rhs: ValueLoc) bool {
    if (std.meta.activeTag(lhs) != std.meta.activeTag(rhs)) return false;
    return switch (lhs) {
        .arg32 => |reg| reg == rhs.arg32,
        .arg64 => |reg| reg == rhs.arg64,
        .arg128 => |pair| pair.eql(rhs.arg128),
        .eax, .rax => true,
        .scratch32 => |reg| reg == rhs.scratch32,
        .scratch64 => |reg| reg == rhs.scratch64,
        .scratch128 => |pair| pair.eql(rhs.scratch128),
        .stack64 => |disp| disp == rhs.stack64,
        .stack128 => |disp| disp == rhs.stack128,
        .stack128_value => |disp| disp == rhs.stack128_value,
        .stack_i32_array => |array| array.base_disp == rhs.stack_i32_array.base_disp and array.len == rhs.stack_i32_array.len,
        .stack_i32_ptr => |ptr| ptr.disp == rhs.stack_i32_ptr.disp and ptr.index == null and rhs.stack_i32_ptr.index == null,
        .spill64 => |frame_index| frame_index == rhs.spill64,
        .spill128 => |spill| spill.lo == rhs.spill128.lo and spill.hi == rhs.spill128.hi,
    };
}

fn locContainsReg(loc: ValueLoc, reg: ArgReg) bool {
    return switch (loc) {
        .arg32, .arg64, .scratch32, .scratch64 => |value_reg| value_reg == reg,
        .arg128, .scratch128 => |pair| pair.contains(reg),
        .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => false,
    };
}

fn valueIsInt(value: ir.Value) bool {
    return switch (value) {
        .int => true,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

fn intBits(ty: ir.Type) ?u16 {
    return switch (ty) {
        .int => |bits| bits,
        .void, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate, .vector => null,
    };
}

fn callArgRegisterCount(ty: ir.Type) ?usize {
    if (ty == .ptr) return 1;
    const bits = intBits(ty) orelse return null;
    return switch (bits) {
        32, 64 => 1,
        128 => 2,
        else => null,
    };
}

fn isDefaultOrFastcc(calling_conv: ?[]const u8) bool {
    const cc = calling_conv orelse return true;
    return std.mem.eql(u8, cc, "ccc") or std.mem.eql(u8, cc, "fastcc");
}

fn parseI32ArrayType(ty: ir.Type) ?u32 {
    const text = switch (ty) {
        .aggregate => |text| std.mem.trim(u8, text, " "),
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => return null,
    };
    if (!std.mem.startsWith(u8, text, "[") or !std.mem.endsWith(u8, text, " x i32]")) return null;
    const count_end = std.mem.indexOf(u8, text, " x ") orelse return null;
    if (count_end <= 1) return null;
    const count_text = text[1..count_end];
    return std.fmt.parseUnsigned(u32, count_text, 10) catch null;
}

fn alignedCallFrameBytes(payload_bytes: u32) ?u32 {
    if (payload_bytes == 0) return null;
    const rounded_payload = std.mem.alignForward(u32, payload_bytes, 16);
    return std.math.add(u32, rounded_payload, 8) catch null;
}

fn stack128FrameBytes() u32 {
    return 56;
}

fn stage2SpillReservedBytes() u32 {
    return @as(u32, stage2_spill_slots + 1) * 8;
}

fn isComposedReturnType(ty: ir.Type) bool {
    if (ty == .void) return true;
    const bits = intBits(ty) orelse return false;
    return bits == 32 or bits == 64 or bits == 128;
}

fn shiftAmount5(value: i128) !u5 {
    if (value < 0 or value > std.math.maxInt(u5)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

fn shiftAmount6(value: i128) !u6 {
    if (value < 0 or value > std.math.maxInt(u6)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

fn shiftAmount7(value: i128) !u7 {
    if (value < 0 or value > std.math.maxInt(u7)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

fn i32Value(value: i128) !i32 {
    if (value < std.math.minInt(i32) or value > std.math.maxInt(i32)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

fn i32BitPattern(value: i128) !i32 {
    if (value < std.math.minInt(i32) or value > std.math.maxInt(u32)) return error.UnsupportedCodegenValue;
    if (value < 0) return @intCast(value);
    return @bitCast(@as(u32, @intCast(value)));
}

fn i64Value(value: i128) !i64 {
    if (value < std.math.minInt(i64) or value > std.math.maxInt(i64)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

fn argRegIndex(reg: ArgReg) usize {
    return switch (reg) {
        .rdi => 0,
        .rsi => 1,
        .rdx => 2,
        .rcx => 3,
        .r8 => 4,
        .r9 => 5,
    };
}

pub fn inspectFunction(function: ir.Function) SelectionResult {
    if (function.calling_conv != null) {
        return unsupported(.{ .unsupported_control_flow = "non-default-calling-convention" });
    }
    if (!isScalarReturnType(function.ret_ty)) {
        return unsupported(.{ .unsupported_type = "unsupported-return-type" });
    }
    for (function.params.items) |param| {
        if (!isSelectorScalarType(param.ty)) {
            return unsupported(.{ .unsupported_type = "unsupported-param-type" });
        }
    }

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (inspectInstruction(instruction)) |diagnostic| {
                return unsupported(diagnostic);
            }
        }
        const terminator = block.terminator orelse {
            return unsupported(.{ .unsupported_control_flow = "missing-terminator" });
        };
        if (inspectTerminator(terminator)) |diagnostic| {
            return unsupported(diagnostic);
        }
    }

    return unsupported(.{ .no_emitter = "selector-skeleton-has-no-emitters" });
}

fn inspectInstruction(instruction: ir.Instruction) ?Diagnostic {
    return switch (instruction.kind) {
        .binary => |binary| inspectBinary(binary),
        .cast => |cast| inspectCast(cast),
        .icmp => |icmp| inspectIcmp(icmp),
        .select => |select| inspectSelect(select),
        .alloca => |alloca| if (isSelectorScalarType(alloca.allocated_ty) or parseI32ArrayType(alloca.allocated_ty) != null) null else .{ .unsupported_type = "alloca" },
        .load => |load| if (isSelectorScalarType(load.ty)) null else .{ .unsupported_type = "load" },
        .store => |store| if (isSelectorScalarType(store.ty)) null else .{ .unsupported_type = "store" },
        .gep => null,
        .call => |call| inspectCall(call),
        .phi => |phi| if (isSelectorScalarType(phi.ty)) null else .{ .unsupported_type = "phi" },
        .freeze => |freeze| if (isSelectorScalarType(freeze.ty)) null else .{ .unsupported_type = "freeze" },
        .fcmp => .{ .unsupported_instruction = "fcmp" },
        .atomicrmw => .{ .unsupported_instruction = "atomicrmw" },
        .cmpxchg => .{ .unsupported_instruction = "cmpxchg" },
        .fence => .{ .unsupported_instruction = "fence" },
        .extractelement => .{ .unsupported_instruction = "extractelement" },
        .insertelement => .{ .unsupported_instruction = "insertelement" },
        .shufflevector => .{ .unsupported_instruction = "shufflevector" },
        .extractvalue => |extract| inspectExtractValue(extract),
        .insertvalue => .{ .unsupported_instruction = "insertvalue" },
    };
}

fn inspectBinary(binary: ir.BinaryInst) ?Diagnostic {
    if (!isSelectorScalarType(binary.ty)) return .{ .unsupported_type = "binary" };
    return switch (binary.op) {
        .add, .sub, .mul, .@"and", .@"or", .xor, .shl, .lshr, .ashr => null,
        .udiv, .sdiv, .urem, .srem => .{ .unsupported_instruction = @tagName(binary.op) },
        .fadd, .fsub, .fmul, .fdiv, .frem => .{ .unsupported_instruction = @tagName(binary.op) },
    };
}

fn inspectCast(cast: ir.CastInst) ?Diagnostic {
    if (!isSelectorScalarType(cast.from_ty) or !isSelectorScalarType(cast.to_ty)) {
        return .{ .unsupported_type = "cast" };
    }
    return switch (cast.op) {
        .trunc, .zext, .sext, .bitcast, .ptrtoint, .inttoptr => null,
        .fpext, .fptrunc, .fptosi, .fptoui, .sitofp, .uitofp => .{ .unsupported_instruction = @tagName(cast.op) },
    };
}

fn inspectIcmp(icmp: ir.IcmpInst) ?Diagnostic {
    if (!isSelectorScalarType(icmp.operand_ty)) return .{ .unsupported_type = "icmp" };
    return null;
}

fn inspectSelect(select: ir.SelectInst) ?Diagnostic {
    if (!isSelectorScalarType(select.ty)) return .{ .unsupported_type = "select" };
    return switch (select.cond_ty) {
        .int => |bits| if (bits == 1) null else .{ .unsupported_type = "select-cond" },
        else => .{ .unsupported_type = "select-cond" },
    };
}

fn inspectCall(call: ir.CallInst) ?Diagnostic {
    if (call.inline_asm != null) return .{ .unsupported_instruction = "inline-asm-call" };
    if (call.callee_value != null) return .{ .unsupported_value = "indirect-call" };
    if (call.raw_args != null) return .{ .unsupported_instruction = "raw-call-args" };
    if (call.operand_bundle != null) return .{ .unsupported_instruction = "operand-bundle-call" };
    if (call.isDebugVariableLocation()) return null;
    if (std.mem.eql(u8, call.callee, "llvm.assume")) {
        if (call.ret_ty != .void or call.args.items.len != 1) return .{ .unsupported_instruction = "llvm.assume" };
        return if (call.args.items[0].ty.eql(.{ .int = 1 })) null else .{ .unsupported_type = "llvm.assume" };
    }
    if (isOverflowIntrinsic(call.callee)) {
        if (!call.ret_ty.eql(.{ .aggregate = "{ i64, i1 }" }) or call.args.items.len != 2) {
            return .{ .unsupported_type = "overflow-intrinsic" };
        }
        for (call.args.items) |arg| {
            if (!arg.ty.eql(.{ .int = 64 })) return .{ .unsupported_type = "overflow-intrinsic-arg" };
        }
        return null;
    }
    if (!isScalarReturnType(call.ret_ty)) return .{ .unsupported_type = "call-ret" };
    for (call.args.items) |arg| {
        if (!isSelectorScalarType(arg.ty)) return .{ .unsupported_type = "call-arg" };
    }
    return null;
}

fn inspectExtractValue(extract: ir.ExtractValueInst) ?Diagnostic {
    if (!extract.aggregate_ty.eql(.{ .aggregate = "{ i64, i1 }" })) {
        return .{ .unsupported_type = "extractvalue-aggregate" };
    }
    if (std.mem.eql(u8, extract.indices, "0")) {
        return if (extract.result_ty.eql(.{ .int = 64 })) null else .{ .unsupported_type = "extractvalue-result" };
    }
    if (std.mem.eql(u8, extract.indices, "1")) {
        return if (extract.result_ty.eql(.{ .int = 1 })) null else .{ .unsupported_type = "extractvalue-result" };
    }
    return .{ .unsupported_value = "extractvalue-index" };
}

fn inspectTerminator(terminator: ir.Terminator) ?Diagnostic {
    return switch (terminator) {
        .ret => |ret| if (isScalarReturnType(ret.ty)) null else .{ .unsupported_type = "ret" },
        .br => null,
        .condbr => |condbr| switch (condbr.cond_ty) {
            .int => |bits| if (bits == 1) null else .{ .unsupported_type = "condbr" },
            else => .{ .unsupported_type = "condbr" },
        },
        .@"switch" => .{ .unsupported_control_flow = "switch" },
        .indirectbr => .{ .unsupported_control_flow = "indirectbr" },
        .@"unreachable" => .{ .unsupported_control_flow = "unreachable" },
    };
}

fn isScalarReturnType(ty: ir.Type) bool {
    return ty == .void or isSelectorScalarType(ty);
}

fn isSelectorScalarType(ty: ir.Type) bool {
    return switch (ty) {
        .int => |bits| bits > 0 and bits <= 128,
        .ptr => true,
        .void, .half, .float, .double, .x86_fp80, .fp128, .metadata, .aggregate, .vector => false,
    };
}

fn isOverflowIntrinsic(callee: []const u8) bool {
    return std.mem.eql(u8, callee, "llvm.uadd.with.overflow.i64") or
        std.mem.eql(u8, callee, "llvm.usub.with.overflow.i64");
}

fn matchesMuloLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 1 })) return false;
    if (function.params.items.len != 5) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.ptr)) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[4].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_uadd_overflow = false;
    var saw_usub_overflow = false;
    var overflow_extracts: usize = 0;
    var mul_i64_count: usize = 0;
    var result_i64_stores: usize = 0;
    var i8_allocas: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .alloca => |alloca| {
                    if (alloca.allocated_ty.eql(.{ .int = 8 })) i8_allocas += 1;
                },
                .binary => |binary| {
                    if (binary.op == .mul and binary.ty.eql(.{ .int = 64 })) mul_i64_count += 1;
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    }
                    if (std.mem.eql(u8, call.callee, "llvm.uadd.with.overflow.i64")) saw_uadd_overflow = true;
                    if (std.mem.eql(u8, call.callee, "llvm.usub.with.overflow.i64")) saw_usub_overflow = true;
                },
                .extractvalue => |extract| {
                    if (extract.aggregate_ty.eql(.{ .aggregate = "{ i64, i1 }" })) overflow_extracts += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) result_i64_stores += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_uadd_overflow and
        saw_usub_overflow and
        overflow_extracts >= 4 and
        mul_i64_count >= 4 and
        result_i64_stores >= 2 and
        i8_allocas >= 1;
}

fn matchesByteswapLimb64Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 16 })) return false;

    var saw_freeze_bits = false;
    var saw_int_byte_size = false;
    var saw_assume = false;
    var saw_bswap_i64 = false;
    var saw_limb_count_math = false;
    var saw_remainder_mask = false;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .freeze => |freeze| {
                    if (freeze.ty.eql(.{ .int = 16 })) saw_freeze_bits = true;
                },
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add) saw_limb_count_math = true;
                        if (binary.op == .lshr) saw_limb_count_math = true;
                        if (binary.op == .@"and") saw_remainder_mask = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.assume") and call.ret_ty == .void) {
                        saw_assume = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.bswap.i64") and
                        call.ret_ty.eql(.{ .int = 64 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 64 }))
                    {
                        saw_bswap_i64 = true;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    return saw_freeze_bits and
        saw_int_byte_size and
        saw_assume and
        saw_bswap_i64 and
        saw_limb_count_math and
        saw_remainder_mask and
        i64_loads >= 1 and
        i64_stores >= 1;
}

fn matchesShrLimb64Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 5) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 16 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[4].ty.eql(.{ .int = 16 })) return false;

    var saw_freeze_shift = false;
    var saw_int_byte_size = false;
    var saw_assume = false;
    var saw_shift_assert = false;
    var saw_limb_count_math = false;
    var saw_shift_decompose = false;
    var saw_sign_select = false;
    var saw_lshr_i64 = false;
    var saw_shl_i64 = false;
    var saw_or_i64 = false;
    var saw_fix_sign_extend = false;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .freeze => |freeze| {
                    if (freeze.ty.eql(.{ .int = 16 })) saw_freeze_shift = true;
                },
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add) saw_limb_count_math = true;
                        if (binary.op == .lshr) {
                            saw_limb_count_math = true;
                            saw_shift_decompose = true;
                        }
                        if (binary.op == .@"and") saw_shift_decompose = true;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .lshr) saw_lshr_i64 = true;
                        if (binary.op == .shl) saw_shl_i64 = true;
                        if (binary.op == .@"or") saw_or_i64 = true;
                        if (binary.op == .ashr) saw_fix_sign_extend = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.assume") and call.ret_ty == .void) {
                        saw_assume = true;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.operand_ty.eql(.{ .int = 16 }) and icmp.predicate == .ult) saw_shift_assert = true;
                },
                .select => |select| {
                    if (select.cond_ty.eql(.{ .int = 1 }) and select.ty.eql(.{ .int = 1 })) saw_sign_select = true;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    return saw_freeze_shift and
        saw_int_byte_size and
        saw_assume and
        saw_shift_assert and
        saw_limb_count_math and
        saw_shift_decompose and
        saw_sign_select and
        saw_lshr_i64 and
        saw_shl_i64 and
        saw_or_i64 and
        saw_fix_sign_extend and
        i64_loads >= 2 and
        i64_stores >= 2;
}

fn matchesShloLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 1 })) return false;
    if (function.params.items.len != 5) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 16 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[4].ty.eql(.{ .int = 16 })) return false;

    var saw_freeze_shift = false;
    var saw_int_byte_size = false;
    var saw_assume = false;
    var saw_shift_assert = false;
    var saw_limb_count_math = false;
    var saw_shift_decompose = false;
    var saw_left_shift = false;
    var saw_carry_shift = false;
    var saw_or_chain = false;
    var saw_tail_mask = false;
    var saw_tail_sign_extend = false;
    var saw_tail_wrap_select = false;
    var saw_expected_carry = false;
    var saw_overflow_compare = false;
    var saw_overflow_select = false;
    var saw_return_i1 = false;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .freeze => |freeze| {
                    if (freeze.ty.eql(.{ .int = 16 })) saw_freeze_shift = true;
                },
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add) saw_limb_count_math = true;
                        if (binary.op == .lshr) {
                            saw_limb_count_math = true;
                            saw_shift_decompose = true;
                        }
                        if (binary.op == .@"and") saw_shift_decompose = true;
                        if (binary.op == .sub) saw_shift_decompose = true;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .shl) saw_left_shift = true;
                        if (binary.op == .lshr) {
                            saw_carry_shift = true;
                            saw_tail_mask = true;
                            saw_expected_carry = true;
                        }
                        if (binary.op == .@"or") saw_or_chain = true;
                        if (binary.op == .@"and") saw_tail_mask = true;
                        if (binary.op == .ashr) saw_tail_sign_extend = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.assume") and call.ret_ty == .void) {
                        saw_assume = true;
                    }
                },
                .cast => |cast| {
                    if (cast.op == .sext and cast.from_ty.eql(.{ .int = 1 }) and cast.to_ty.eql(.{ .int = 64 })) {
                        saw_expected_carry = true;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.operand_ty.eql(.{ .int = 16 }) and icmp.predicate == .ult) saw_shift_assert = true;
                    if (icmp.operand_ty.eql(.{ .int = 64 }) and icmp.predicate == .ne) saw_overflow_compare = true;
                    if (icmp.operand_ty.eql(.{ .int = 64 }) and icmp.predicate == .slt) saw_expected_carry = true;
                },
                .select => |select| {
                    if (select.cond_ty.eql(.{ .int = 1 }) and select.ty.eql(.{ .int = 64 })) saw_tail_wrap_select = true;
                    if (select.cond_ty.eql(.{ .int = 1 }) and select.ty.eql(.{ .int = 1 })) saw_overflow_select = true;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
        if (block.terminator) |terminator| {
            switch (terminator) {
                .ret => |ret| {
                    if (ret.ty.eql(.{ .int = 1 }) and ret.value != null) saw_return_i1 = true;
                },
                else => {},
            }
        }
    }

    return saw_freeze_shift and
        saw_int_byte_size and
        saw_assume and
        saw_shift_assert and
        saw_limb_count_math and
        saw_shift_decompose and
        saw_left_shift and
        saw_carry_shift and
        saw_or_chain and
        saw_tail_mask and
        saw_tail_sign_extend and
        saw_tail_wrap_select and
        saw_expected_carry and
        saw_overflow_compare and
        saw_overflow_select and
        saw_return_i1 and
        i64_loads >= 3 and
        i64_stores >= 2;
}

fn matchesBitreverseLimb64Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 16 })) return false;

    var saw_freeze_bits = false;
    var saw_int_byte_size = false;
    var saw_umax = false;
    var saw_bitreverse_i64 = false;
    var saw_limb_count_math = false;
    var saw_remainder_mask = false;
    var saw_tail_shift = false;
    var saw_fix_sign_extend = false;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .freeze => |freeze| {
                    if (freeze.ty.eql(.{ .int = 16 })) saw_freeze_bits = true;
                },
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr) saw_limb_count_math = true;
                        if (binary.op == .@"and") saw_remainder_mask = true;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .lshr or binary.op == .shl or binary.op == .@"or") saw_tail_shift = true;
                        if (binary.op == .ashr) saw_fix_sign_extend = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.umax.i64") and
                        call.ret_ty.eql(.{ .int = 64 }))
                    {
                        saw_umax = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.bitreverse.i64") and
                        call.ret_ty.eql(.{ .int = 64 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 64 }))
                    {
                        saw_bitreverse_i64 = true;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    return saw_freeze_bits and
        saw_int_byte_size and
        saw_umax and
        saw_bitreverse_i64 and
        saw_limb_count_math and
        saw_remainder_mask and
        saw_tail_shift and
        saw_fix_sign_extend and
        i64_loads >= 2 and
        i64_stores >= 2;
}

fn matchesNotLimb64Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_assume = false;
    var saw_limb_count_math = false;
    var saw_limb_count_select = false;
    var saw_unary_not = false;
    var saw_partial_unsigned_mask = false;
    var saw_signed_high_fill = false;
    var saw_fix_last_limb_compare = false;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr) saw_limb_count_math = true;
                        if (binary.op == .@"and" or binary.op == .sub) saw_partial_unsigned_mask = true;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .xor and (binary.rhs.eql(.{ .int = -1 }) or binary.lhs.eql(.{ .int = -1 }))) {
                            saw_unary_not = true;
                        }
                        if (binary.op == .lshr or binary.op == .@"and") saw_partial_unsigned_mask = true;
                        if (binary.op == .ashr) saw_signed_high_fill = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.assume") and call.ret_ty == .void) {
                        saw_assume = true;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.operand_ty.eql(.{ .int = 16 })) saw_fix_last_limb_compare = true;
                    if (icmp.operand_ty.eql(.{ .int = 64 }) and icmp.predicate == .slt) saw_signed_high_fill = true;
                },
                .select => |select| {
                    if (select.cond_ty.eql(.{ .int = 1 }) and select.ty.eql(.{ .int = 16 })) saw_limb_count_select = true;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_assume and
        saw_limb_count_math and
        saw_limb_count_select and
        saw_unary_not and
        saw_partial_unsigned_mask and
        saw_signed_high_fill and
        saw_fix_last_limb_compare and
        i64_loads >= 2 and
        i64_stores >= 2;
}

fn matchesBitwiseLimb64Envelope(function: ir.Function) ?x86_64_machine.Limb64BitwiseOp {
    if (function.ret_ty != .void) return null;
    if (function.params.items.len != 4) return null;
    if (!function.params.items[0].ty.eql(.ptr)) return null;
    if (!function.params.items[1].ty.eql(.ptr)) return null;
    if (!function.params.items[2].ty.eql(.ptr)) return null;
    if (!function.params.items[3].ty.eql(.{ .int = 16 })) return null;

    var saw_int_byte_size = false;
    var saw_umax = false;
    var saw_assume = false;
    var saw_limb_count_math = false;
    var saw_unroll_remainder = false;
    var xor_i64_count: usize = 0;
    var or_i64_count: usize = 0;
    var and_i64_count: usize = 0;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .lshr) saw_limb_count_math = true;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        switch (binary.op) {
                            .xor => xor_i64_count += 1,
                            .@"or" => or_i64_count += 1,
                            .@"and" => {
                                and_i64_count += 1;
                                saw_unroll_remainder = true;
                            },
                            else => {},
                        }
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.umax.i16") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 2)
                    {
                        saw_umax = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.assume") and call.ret_ty == .void) {
                        saw_assume = true;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    if (!saw_int_byte_size or
        !saw_umax or
        !saw_assume or
        !saw_limb_count_math or
        !saw_unroll_remainder or
        i64_loads < 4 or
        i64_stores < 2)
    {
        return null;
    }

    if (xor_i64_count >= 2) return .xor;
    if (and_i64_count >= 2) return .@"and";
    if (or_i64_count >= 2) return .@"or";
    return null;
}

fn matchesCmpLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 8 })) return false;
    if (function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_limb_count_math = false;
    var saw_limb_count_select = false;
    var saw_reverse_index_sub = false;
    var saw_signed_less = false;
    var saw_signed_greater = false;
    var saw_unsigned_less = false;
    var saw_unsigned_greater = false;
    var i64_loads: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr) saw_limb_count_math = true;
                    } else if (binary.ty.eql(.{ .int = 64 }) and binary.op == .sub) {
                        saw_reverse_index_sub = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.operand_ty.eql(.{ .int = 64 })) {
                        switch (icmp.predicate) {
                            .slt => saw_signed_less = true,
                            .sgt => saw_signed_greater = true,
                            .ult => saw_unsigned_less = true,
                            .ugt => saw_unsigned_greater = true,
                            else => {},
                        }
                    }
                },
                .select => |select| {
                    if (select.cond_ty.eql(.{ .int = 1 }) and select.ty.eql(.{ .int = 16 })) {
                        saw_limb_count_select = true;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_limb_count_math and
        saw_limb_count_select and
        saw_reverse_index_sub and
        saw_signed_less and
        saw_signed_greater and
        saw_unsigned_less and
        saw_unsigned_greater and
        i64_loads >= 4;
}

fn matchesOverflowLimb64Envelope(function: ir.Function) ?x86_64_machine.Limb64OverflowOp {
    if (!function.ret_ty.eql(.{ .int = 1 })) return null;
    if (function.params.items.len != 5) return null;
    if (!function.params.items[0].ty.eql(.ptr)) return null;
    if (!function.params.items[1].ty.eql(.ptr)) return null;
    if (!function.params.items[2].ty.eql(.ptr)) return null;
    if (!function.params.items[3].ty.eql(.{ .int = 1 })) return null;
    if (!function.params.items[4].ty.eql(.{ .int = 16 })) return null;

    var saw_int_byte_size = false;
    var saw_limb_count_math = false;
    var saw_limb_count_select = false;
    var saw_partial_limb_wrap = false;
    var saw_fix_last_limb_fill = false;
    var uadd_overflow_count: usize = 0;
    var sadd_overflow_count: usize = 0;
    var usub_overflow_count: usize = 0;
    var ssub_overflow_count: usize = 0;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;
    var i1_allocas: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .alloca => |alloca| {
                    if (alloca.allocated_ty.eql(.{ .int = 8 }) or alloca.allocated_ty.eql(.{ .int = 1 })) {
                        i1_allocas += 1;
                    }
                },
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr or binary.op == .@"and") saw_limb_count_math = true;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .shl or binary.op == .ashr or binary.op == .lshr) saw_partial_limb_wrap = true;
                        if (binary.op == .sub) saw_fix_last_limb_fill = true;
                    } else if (binary.ty.eql(.{ .int = 8 }) and binary.op == .@"or") {
                        saw_limb_count_math = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.uadd.with.overflow.i64")) {
                        uadd_overflow_count += 1;
                    } else if (std.mem.eql(u8, call.callee, "llvm.sadd.with.overflow.i64")) {
                        sadd_overflow_count += 1;
                    } else if (std.mem.eql(u8, call.callee, "llvm.usub.with.overflow.i64")) {
                        usub_overflow_count += 1;
                    } else if (std.mem.eql(u8, call.callee, "llvm.ssub.with.overflow.i64")) {
                        ssub_overflow_count += 1;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.operand_ty.eql(.{ .int = 16 })) saw_limb_count_math = true;
                },
                .select => |select| {
                    if (select.cond_ty.eql(.{ .int = 1 }) and select.ty.eql(.{ .int = 16 })) {
                        saw_limb_count_select = true;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    if (!saw_int_byte_size or
        !saw_limb_count_math or
        !saw_limb_count_select or
        !saw_partial_limb_wrap or
        !saw_fix_last_limb_fill or
        i64_loads < 4 or
        i64_stores < 2 or
        i1_allocas < 1)
    {
        return null;
    }

    if (uadd_overflow_count >= 4 and sadd_overflow_count >= 2 and usub_overflow_count == 0 and ssub_overflow_count == 0) {
        return .add;
    }
    if (usub_overflow_count >= 4 and ssub_overflow_count >= 2 and uadd_overflow_count == 0 and sadd_overflow_count == 0) {
        return .sub;
    }
    return null;
}

fn matchesPopcountLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 16 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_limb_count_math = false;
    var saw_remainder_mask = false;
    var saw_tail_shift = false;
    var ctpop_i64_count: usize = 0;
    var trunc_i64_to_i16_count: usize = 0;
    var add_i16_count: usize = 0;
    var i64_loads: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr) saw_limb_count_math = true;
                        if (binary.op == .@"and") saw_remainder_mask = true;
                        if (binary.op == .add) add_i16_count += 1;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .shl) saw_tail_shift = true;
                    }
                },
                .cast => |cast| {
                    if (cast.op == .trunc and
                        cast.from_ty.eql(.{ .int = 64 }) and
                        cast.to_ty.eql(.{ .int = 16 }))
                    {
                        trunc_i64_to_i16_count += 1;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.ctpop.i64") and
                        call.ret_ty.eql(.{ .int = 64 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 64 }))
                    {
                        ctpop_i64_count += 1;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_limb_count_math and
        saw_remainder_mask and
        saw_tail_shift and
        ctpop_i64_count >= 2 and
        trunc_i64_to_i16_count >= 2 and
        add_i16_count >= 2 and
        i64_loads >= 2;
}

fn matchesCtzLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 16 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_limb_count_math = false;
    var saw_remainder_mask = false;
    var saw_zero_limb_branch = false;
    var cttz_i64_count: usize = 0;
    var trunc_i64_to_i16_count: usize = 0;
    var add_i16_count: usize = 0;
    var or_i16_count: usize = 0;
    var i64_loads: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr or binary.op == .shl) saw_limb_count_math = true;
                        if (binary.op == .@"and") saw_remainder_mask = true;
                        if (binary.op == .add) add_i16_count += 1;
                        if (binary.op == .@"or") or_i16_count += 1;
                    }
                },
                .cast => |cast| {
                    if (cast.op == .trunc and
                        cast.from_ty.eql(.{ .int = 64 }) and
                        cast.to_ty.eql(.{ .int = 16 }))
                    {
                        trunc_i64_to_i16_count += 1;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.cttz.i64") and
                        call.ret_ty.eql(.{ .int = 64 }) and call.args.items.len == 2 and
                        call.args.items[0].ty.eql(.{ .int = 64 }) and
                        call.args.items[1].ty.eql(.{ .int = 1 }))
                    {
                        cttz_i64_count += 1;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.predicate == .eq and icmp.operand_ty.eql(.{ .int = 64 })) saw_zero_limb_branch = true;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_limb_count_math and
        saw_remainder_mask and
        saw_zero_limb_branch and
        cttz_i64_count >= 2 and
        trunc_i64_to_i16_count >= 2 and
        add_i16_count >= 2 and
        or_i16_count >= 1 and
        i64_loads >= 2;
}

fn matchesClzLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 16 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_limb_count_math = false;
    var saw_remainder_mask = false;
    var saw_zero_limb_branch = false;
    var saw_reverse_index_sub = false;
    var saw_partial_shift = false;
    var ctlz_i64_count: usize = 0;
    var trunc_i64_to_i16_count: usize = 0;
    var add_i16_count: usize = 0;
    var i64_loads: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr) saw_limb_count_math = true;
                        if (binary.op == .@"and") saw_remainder_mask = true;
                        if (binary.op == .add) add_i16_count += 1;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .sub) saw_reverse_index_sub = true;
                        if (binary.op == .shl) saw_partial_shift = true;
                    }
                },
                .cast => |cast| {
                    if (cast.op == .trunc and
                        cast.from_ty.eql(.{ .int = 64 }) and
                        cast.to_ty.eql(.{ .int = 16 }))
                    {
                        trunc_i64_to_i16_count += 1;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.ctlz.i64") and
                        call.ret_ty.eql(.{ .int = 64 }) and call.args.items.len == 2 and
                        call.args.items[0].ty.eql(.{ .int = 64 }) and
                        call.args.items[1].ty.eql(.{ .int = 1 }))
                    {
                        ctlz_i64_count += 1;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.predicate == .eq and icmp.operand_ty.eql(.{ .int = 64 })) saw_zero_limb_branch = true;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_limb_count_math and
        saw_remainder_mask and
        saw_zero_limb_branch and
        saw_reverse_index_sub and
        saw_partial_shift and
        ctlz_i64_count >= 2 and
        trunc_i64_to_i16_count >= 2 and
        add_i16_count >= 2 and
        i64_loads >= 2;
}

fn matchesUdivei4Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.ptr)) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 64 })) return false;

    var saw_un: bool = false;
    var saw_vn: bool = false;
    var saw_int_byte_size = false;
    var saw_ctlz_i32 = false;
    var saw_udiv_i64 = false;
    var saw_urem_i64 = false;
    var saw_limb_count_lshr_i16 = false;
    var saw_byte_count_shl_i64 = false;
    var aggregate_allocas: usize = 0;
    var other_allocas: usize = 0;
    var i32_stores: usize = 0;
    var i32_loads: usize = 0;
    var u64_from_i32_exts: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .alloca => |alloca| switch (alloca.allocated_ty) {
                    .aggregate => |text| {
                        aggregate_allocas += 1;
                        if (std.mem.eql(u8, text, "[2049 x i32]")) saw_un = true;
                        if (std.mem.eql(u8, text, "[2048 x i32]")) saw_vn = true;
                    },
                    else => other_allocas += 1,
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.ctlz.i32") and
                        call.ret_ty.eql(.{ .int = 32 }) and call.args.items.len == 2 and
                        call.args.items[0].ty.eql(.{ .int = 32 }) and
                        call.args.items[1].ty.eql(.{ .int = 1 }))
                    {
                        saw_ctlz_i32 = true;
                    }
                },
                .binary => |binary| {
                    if (binary.op == .lshr and binary.ty.eql(.{ .int = 16 })) {
                        saw_limb_count_lshr_i16 = true;
                    }
                    if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .udiv) saw_udiv_i64 = true;
                        if (binary.op == .urem) saw_urem_i64 = true;
                        if (binary.op == .shl) saw_byte_count_shl_i64 = true;
                    }
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 32 })) i32_stores += 1;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 32 })) i32_loads += 1;
                },
                .cast => |cast| {
                    if (cast.op == .zext and
                        cast.from_ty.eql(.{ .int = 32 }) and
                        cast.to_ty.eql(.{ .int = 64 }))
                    {
                        u64_from_i32_exts += 1;
                    }
                },
                else => {},
            }
        }
    }

    return saw_un and
        saw_vn and
        aggregate_allocas == 2 and
        other_allocas == 0 and
        saw_int_byte_size and
        saw_ctlz_i32 and
        saw_udiv_i64 and
        saw_urem_i64 and
        saw_limb_count_lshr_i16 and
        saw_byte_count_shl_i64 and
        i32_stores >= 8 and
        i32_loads >= 8 and
        u64_from_i32_exts >= 2;
}

fn matchesUmodei5Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 5) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.ptr)) return false;
    if (!function.params.items[3].ty.eql(.ptr)) return false;
    if (!function.params.items[4].ty.eql(.{ .int = 64 })) return false;

    var saw_un: bool = false;
    var saw_vn: bool = false;
    var saw_int_byte_size = false;
    var saw_ctlz_i32 = false;
    var saw_inline_memcpy = false;
    var saw_udiv_i64 = false;
    var saw_urem_i64 = false;
    var saw_lshr_i16 = false;
    var saw_limb_count_lshr_i64 = false;
    var aggregate_allocas: usize = 0;
    var other_allocas: usize = 0;
    var i32_stores: usize = 0;
    var i32_loads: usize = 0;
    var u64_from_i32_exts: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .alloca => |alloca| switch (alloca.allocated_ty) {
                    .aggregate => |text| {
                        aggregate_allocas += 1;
                        if (std.mem.eql(u8, text, "[2049 x i32]")) saw_un = true;
                        if (std.mem.eql(u8, text, "[2048 x i32]")) saw_vn = true;
                    },
                    else => other_allocas += 1,
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.ctlz.i32") and
                        call.ret_ty.eql(.{ .int = 32 }) and call.args.items.len == 2 and
                        call.args.items[0].ty.eql(.{ .int = 32 }) and
                        call.args.items[1].ty.eql(.{ .int = 1 }))
                    {
                        saw_ctlz_i32 = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.memcpy.inline.p0.p0.i64")) {
                        saw_inline_memcpy = true;
                    }
                },
                .binary => |binary| {
                    if (binary.op == .lshr and binary.ty.eql(.{ .int = 16 })) saw_lshr_i16 = true;
                    if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .udiv) saw_udiv_i64 = true;
                        if (binary.op == .urem) saw_urem_i64 = true;
                        if (binary.op == .lshr) saw_limb_count_lshr_i64 = true;
                    }
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 32 })) i32_stores += 1;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 32 })) i32_loads += 1;
                },
                .cast => |cast| {
                    if (cast.op == .zext and
                        cast.from_ty.eql(.{ .int = 32 }) and
                        cast.to_ty.eql(.{ .int = 64 }))
                    {
                        u64_from_i32_exts += 1;
                    }
                },
                else => {},
            }
        }
    }

    return saw_un and
        saw_vn and
        aggregate_allocas == 2 and
        other_allocas == 0 and
        saw_int_byte_size and
        saw_ctlz_i32 and
        saw_inline_memcpy and
        saw_udiv_i64 and
        saw_urem_i64 and
        !saw_lshr_i16 and
        saw_limb_count_lshr_i64 and
        i32_stores >= 8 and
        i32_loads >= 8 and
        u64_from_i32_exts >= 2;
}

fn unsupported(diagnostic: Diagnostic) SelectionResult {
    return .{ .unsupported = diagnostic };
}
