const std = @import("std");
const ir = @import("../../../ir.zig");
const selector_types = @import("selector_types.zig");
const sysv_abi = @import("../sysv_abi.zig");

const ArgReg = selector_types.ArgReg;
const RegPair = selector_types.RegPair;
const XmmReg = selector_types.XmmReg;
const VirtualRegClass = selector_types.VirtualRegClass;
const VirtualRegMetadata = selector_types.VirtualRegMetadata;
const argRegIndex = selector_types.argRegIndex;
const selector_allocatable_pairs = selector_types.selector_allocatable_pairs;
const selector_allocatable_regs = selector_types.selector_allocatable_regs;
const selector_allocatable_xmm_regs = selector_types.selector_allocatable_xmm_regs;
const xmmRegIndex = selector_types.xmmRegIndex;

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
const stage2_frame_slots = 32;
pub const stage2_spill_slots = stage2_frame_slots;
pub const stage2_max_blocks = 128;
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
                try addNamedPressureUse(&blocks.items[predecessor_index].phi_out, incoming.value, pressure_exempt_values);
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

pub fn stage2SpillReservedBytes() u32 {
    return @as(u32, stage2_frame_slots) * 8;
}

pub const NameSet = std.StringHashMap(void);

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

pub const SelectorValueInterval = struct {
    name: []const u8,
    class: VirtualRegClass,
    bits: u16,
    start: usize,
    end: usize,
    earliest_use: ?usize = null,
};

pub const ForwardValuePlan = struct {
    definition_position: usize,
    metadata: VirtualRegMetadata,
};

pub const PlannedValueAssignment = union(enum) {
    gpr32: ArgReg,
    gpr64: ArgReg,
    gpr128: RegPair,
    fp16: XmmReg,
    fp32: XmmReg,
    fp64: XmmReg,
    vector_xmm: XmmReg,
    stack_object,
    stack_pointer: ArgReg,
    spill: usize,
};

pub const SelectorAllocationPlan = struct {
    allocator: std.mem.Allocator,
    assignments: std.StringHashMap(PlannedValueAssignment),
    interval_ends: std.StringHashMap(usize),
    forward_values: std.StringHashMap(ForwardValuePlan),
    preservation_values: std.StringHashMap(void),
    spill_slots: usize = 0,
    preservation_spill_slots: usize = 0,
    max_active_values: usize = 0,

    pub fn init(allocator: std.mem.Allocator) SelectorAllocationPlan {
        return .{
            .allocator = allocator,
            .assignments = std.StringHashMap(PlannedValueAssignment).init(allocator),
            .interval_ends = std.StringHashMap(usize).init(allocator),
            .forward_values = std.StringHashMap(ForwardValuePlan).init(allocator),
            .preservation_values = std.StringHashMap(void).init(allocator),
        };
    }

    pub fn deinit(plan: *SelectorAllocationPlan) void {
        plan.preservation_values.deinit();
        plan.forward_values.deinit();
        plan.interval_ends.deinit();
        plan.assignments.deinit();
    }

    pub fn assignment(plan: SelectorAllocationPlan, name: []const u8) ?PlannedValueAssignment {
        return plan.assignments.get(name);
    }

    pub fn intervalEnd(plan: SelectorAllocationPlan, name: []const u8) ?usize {
        return plan.interval_ends.get(name);
    }

    pub fn forwardValue(plan: SelectorAllocationPlan, name: []const u8) ?ForwardValuePlan {
        return plan.forward_values.get(name);
    }
};

const ActiveAllocation = struct {
    end: usize,
    assignment: PlannedValueAssignment,
};

pub const SpillSlotAssignment = struct {
    base: usize,
    slots: usize,
};

pub fn buildSelectorAllocationPlan(allocator: std.mem.Allocator, function: ir.Function) !SelectorAllocationPlan {
    var pressure_exempt_values = NameSet.init(allocator);
    defer pressure_exempt_values.deinit();
    try collectPressureExemptValues(&pressure_exempt_values, function);

    var intervals: std.ArrayList(SelectorValueInterval) = .empty;
    defer intervals.deinit(allocator);

    var interval_indexes = std.StringHashMap(usize).init(allocator);
    defer interval_indexes.deinit();

    var terminator_positions: std.ArrayList(usize) = .empty;
    defer terminator_positions.deinit(allocator);

    var preservation_barrier_positions: std.ArrayList(usize) = .empty;
    defer preservation_barrier_positions.deinit(allocator);

    var simple_loop_backedge_values = NameSet.init(allocator);
    defer simple_loop_backedge_values.deinit();
    const admit_simple_loop_forward_values = isExactEiScalarFamily(function);

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
            if (instruction.kind == .call and callRequiresPreservationFrame(instruction.kind.call)) {
                try preservation_barrier_positions.append(allocator, position);
            }
            position += 1;
        }
        try terminator_positions.append(allocator, position);
        if (block.terminator != null) position += 1;
    }

    position = 1;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            var uses = NameSet.init(allocator);
            defer uses.deinit();
            if (instruction.kind == .phi) {
                if (admit_simple_loop_forward_values and isSimpleScalarSelfLoopPhi(block, instruction.kind.phi)) {
                    for (instruction.kind.phi.incoming.items) |incoming| {
                        if (!std.mem.eql(u8, incoming.block, block.name)) continue;
                        if (namedValue(incoming.value)) |name| try simple_loop_backedge_values.put(name, {});
                    }
                }
                for (instruction.kind.phi.incoming.items) |incoming| {
                    var incoming_use = NameSet.init(allocator);
                    defer incoming_use.deinit();
                    try addNamedPressureUse(&incoming_use, incoming.value, pressure_exempt_values);
                    const predecessor_index = function.blockIndex(incoming.block) orelse return error.UnsupportedCodegenControlFlow;
                    try recordSelectorIntervalUses(intervals.items, interval_indexes, incoming_use, terminator_positions.items[predecessor_index]);
                }
            } else {
                try collectInstructionNamedUses(&uses, instruction, pressure_exempt_values);
                try recordSelectorIntervalUses(intervals.items, interval_indexes, uses, position);
            }
            position += 1;
        }
        if (block.terminator) |terminator| {
            var uses = NameSet.init(allocator);
            defer uses.deinit();
            try collectTerminatorNamedUses(&uses, terminator, pressure_exempt_values);
            try collectAggregateReturnLeafUses(&uses, function, terminator, pressure_exempt_values);
            try recordSelectorIntervalUses(intervals.items, interval_indexes, uses, position);
            position += 1;
        }
    }

    var cfg_liveness = try buildStageTwoLiveness(allocator, function);
    defer cfg_liveness.deinit();
    for (cfg_liveness.blocks.items, 0..) |block, block_index| {
        try recordSelectorIntervalUses(intervals.items, interval_indexes, block.live_out, terminator_positions.items[block_index]);
    }

    var forward_values = std.StringHashMap(ForwardValuePlan).init(allocator);
    defer forward_values.deinit();
    var candidate_it = simple_loop_backedge_values.iterator();
    while (candidate_it.next()) |entry| {
        const index = interval_indexes.get(entry.key_ptr.*) orelse return error.UnsupportedCodegenValue;
        const interval = &intervals.items[index];
        const earliest_use = interval.earliest_use orelse continue;
        if (earliest_use >= interval.start) continue;
        try forward_values.put(interval.name, .{
            .definition_position = interval.start,
            .metadata = .{ .class = interval.class, .bits = interval.bits },
        });
        interval.start = earliest_use;
    }

    var plan = try allocateSelectorIntervals(allocator, intervals.items);
    // Pressure-exempt values historically had no interval entry and were
    // therefore treated as unbounded-live. Preserve that behavior explicitly
    // so every address-dependency owner still has validated plan metadata.
    var exempt_it = pressure_exempt_values.iterator();
    while (exempt_it.next()) |entry| {
        try plan.interval_ends.put(entry.key_ptr.*, std.math.maxInt(usize));
    }
    var forward_it = forward_values.iterator();
    while (forward_it.next()) |entry| try plan.forward_values.put(entry.key_ptr.*, entry.value_ptr.*);
    try recordPreservationDemands(&plan, intervals.items, preservation_barrier_positions.items);
    return plan;
}

pub fn isExactEiScalarFamily(function: ir.Function) bool {
    if (function.blocks.items.len == 0 or
        (!function.ret_ty.eql(.half) and !function.ret_ty.eql(.float) and !function.ret_ty.eql(.double))) return false;
    if (function.params.items.len != 2 or function.params.items[0].ty != .ptr or
        !function.params.items[1].ty.eql(.{ .int = 64 })) return false;
    const pointer_attrs = function.params.items[0].attrs orelse return false;
    if (!hasAttrToken(pointer_attrs, "readonly")) return false;
    const entry_switch = switch (function.blocks.items[0].terminator orelse return false) {
        .@"switch" => |switch_term| switch_term,
        else => return false,
    };
    if (!entry_switch.cond_ty.eql(.{ .int = 16 }) or entry_switch.cases.items.len != 5) return false;
    var seen: [5]bool = .{ false, false, false, false, false };
    for (entry_switch.cases.items) |case| {
        if (!case.value_ty.eql(.{ .int = 16 }) or case.value != .int or case.value.int < 0 or case.value.int > 4) return false;
        const index: usize = @intCast(case.value.int);
        if (seen[index]) return false;
        seen[index] = true;
    }
    var switch_count: usize = 0;
    for (function.blocks.items) |block| switch (block.terminator orelse return false) {
        .@"switch" => switch_count += 1,
        .indirectbr => return false,
        .ret, .br, .condbr, .@"unreachable" => {},
    };
    return switch_count == 1;
}

fn hasAttrToken(attrs: []const u8, expected: []const u8) bool {
    var tokens = std.mem.tokenizeAny(u8, attrs, " \t");
    while (tokens.next()) |token| if (std.mem.eql(u8, token, expected)) return true;
    return false;
}

fn isSimpleScalarSelfLoopPhi(block: ir.BasicBlock, phi: ir.PhiInst) bool {
    if (phi.incoming.items.len != 2) return false;
    const metadata = selectorValueMetadata(phi.ty) orelse return false;
    if (metadata.class != .gpr32 and metadata.class != .gpr64) return false;
    const condbr = switch (block.terminator orelse return false) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    const then_self = std.mem.eql(u8, condbr.then_target, block.name);
    const else_self = std.mem.eql(u8, condbr.else_target, block.name);
    if (then_self == else_self) return false;
    var self_incoming: usize = 0;
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, block.name)) self_incoming += 1;
    }
    return self_incoming == 1;
}

fn callRequiresPreservationFrame(call: ir.CallInst) bool {
    if (call.isDebugVariableLocation()) return false;
    if (!std.mem.startsWith(u8, call.callee, "llvm.")) return true;
    return std.mem.eql(u8, call.callee, "llvm.abs.i32") or
        std.mem.eql(u8, call.callee, "llvm.abs.i64") or
        std.mem.eql(u8, call.callee, "llvm.abs.i128");
}

fn recordPreservationDemands(plan: *SelectorAllocationPlan, intervals: []const SelectorValueInterval, barrier_positions: []const usize) !void {
    for (barrier_positions) |position| {
        var live_slots: usize = 0;
        for (intervals) |interval| {
            if (interval.start >= position or interval.end <= position) continue;
            live_slots += selectorSpillSlotCount(interval);
            try plan.preservation_values.put(interval.name, {});
        }
        plan.preservation_spill_slots = @max(plan.preservation_spill_slots, live_slots);
    }
}

pub fn selectorValueMetadata(ty: ir.Type) ?VirtualRegMetadata {
    if (ty == .ptr) return .{ .class = .gpr64, .bits = 64 };
    return switch (ty) {
        .half => .{ .class = .fp16, .bits = 16 },
        .float => .{ .class = .fp32, .bits = 32 },
        .double => .{ .class = .fp64, .bits = 64 },
        .vector => |vector| if ((vector.len == 2 and (vector.elem_ty == .float or vector.elem_ty == .double or
            (vector.elem_ty == .int and (vector.elem_ty.int == 1 or vector.elem_ty.int == 32 or vector.elem_ty.int == 64)))) or
            (vector.len == 4 and (vector.elem_ty == .float or
                (vector.elem_ty == .int and (vector.elem_ty.int == 1 or vector.elem_ty.int == 32)))))
            .{ .class = .vector_xmm, .bits = 128 }
        else
            null,
        else => selectorIntegerMetadata(ty),
    };
}

fn selectorIntegerMetadata(ty: ir.Type) ?VirtualRegMetadata {
    const bits = intBits(ty) orelse return null;
    return switch (bits) {
        1...32 => .{ .class = .gpr32, .bits = 32 },
        33...64 => .{ .class = .gpr64, .bits = 64 },
        65...128 => .{ .class = .gpr128, .bits = 128 },
        else => null,
    };
}

fn intBits(ty: ir.Type) ?u16 {
    return switch (ty) {
        .int => |bits| bits,
        .void, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate, .vector => null,
    };
}

fn selectorInstructionResultMetadata(instruction: ir.Instruction) ?VirtualRegMetadata {
    return switch (instruction.kind) {
        .binary => |binary| selectorValueMetadata(binary.ty),
        .cast => |cast| selectorValueMetadata(cast.to_ty),
        .freeze => |freeze| selectorValueMetadata(freeze.ty),
        .icmp => |icmp| if (icmp.operand_ty == .vector)
            selectorValueMetadata(.{ .vector = .{ .len = icmp.operand_ty.vector.len, .elem_ty = .{ .int = 1 } } })
        else
            .{ .class = .gpr32, .bits = 32 },
        .fcmp => |fcmp| if (fcmp.operand_ty == .vector)
            selectorValueMetadata(.{ .vector = .{ .len = fcmp.operand_ty.vector.len, .elem_ty = .{ .int = 1 } } })
        else
            .{ .class = .gpr32, .bits = 32 },
        .load => |load| selectorValueMetadata(load.ty),
        .call => |call| if (call.ret_ty == .void) null else selectorValueMetadata(call.ret_ty),
        .select => |select| selectorValueMetadata(select.ty),
        .phi => |phi| selectorValueMetadata(phi.ty),
        .extractvalue => |extract| selectorValueMetadata(extract.result_ty),
        .gep => .{ .class = .stack_pointer, .bits = 64 },
        .alloca => .{ .class = .stack_object, .bits = 0 },
        .store,
        .atomicrmw,
        .cmpxchg,
        .insertvalue,
        .fence,
        => null,
        .extractelement => |extract| if (extract.vector_ty == .vector) selectorValueMetadata(extract.vector_ty.vector.elem_ty.toType()) else null,
        .insertelement => |insert| selectorValueMetadata(insert.vector_ty),
        .shufflevector => |shuffle| selectorValueMetadata(shuffle.lhs_ty),
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
        .earliest_use = null,
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
        if (intervals[index].earliest_use) |earliest| {
            intervals[index].earliest_use = @min(earliest, position);
        } else {
            intervals[index].earliest_use = position;
        }
        intervals[index].end = @max(intervals[index].end, position);
    }
}

pub fn allocateSelectorIntervals(allocator: std.mem.Allocator, intervals: []const SelectorValueInterval) !SelectorAllocationPlan {
    var ordered: std.ArrayList(SelectorValueInterval) = .empty;
    defer ordered.deinit(allocator);
    try ordered.appendSlice(allocator, intervals);
    std.mem.sort(SelectorValueInterval, ordered.items, {}, selectorIntervalLessThan);

    var plan = SelectorAllocationPlan.init(allocator);
    errdefer plan.deinit();

    var active: std.ArrayList(ActiveAllocation) = .empty;
    defer active.deinit(allocator);

    var occupied = SelectorRegisterOccupancy{};
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

const SelectorRegisterOccupancy = struct {
    gpr: [6]bool = [_]bool{false} ** 6,
    xmm: [8]bool = [_]bool{false} ** 8,
};

fn expireSelectorIntervals(active: *std.ArrayList(ActiveAllocation), occupied: *SelectorRegisterOccupancy, position: usize) void {
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

fn allocateSelectorInterval(occupied: *SelectorRegisterOccupancy, interval: SelectorValueInterval, next_spill_slot: usize) PlannedValueAssignment {
    return switch (interval.class) {
        .gpr32 => if (allocateSelectorReg(occupied)) |reg| .{ .gpr32 = reg } else .{ .spill = next_spill_slot },
        .gpr64 => if (allocateSelectorReg(occupied)) |reg| .{ .gpr64 = reg } else .{ .spill = next_spill_slot },
        .gpr128 => if (allocateSelectorPair(occupied)) |pair| .{ .gpr128 = pair } else .{ .spill = next_spill_slot },
        .fp16 => if (allocateSelectorXmm(occupied)) |reg| .{ .fp16 = reg } else .{ .spill = next_spill_slot },
        .fp32 => if (allocateSelectorXmm(occupied)) |reg| .{ .fp32 = reg } else .{ .spill = next_spill_slot },
        .fp64 => if (allocateSelectorXmm(occupied)) |reg| .{ .fp64 = reg } else .{ .spill = next_spill_slot },
        .vector_xmm => if (allocateSelectorXmm(occupied)) |reg| .{ .vector_xmm = reg } else .{ .spill = next_spill_slot },
        .aggregate_sse => unreachable,
        .stack_object => .stack_object,
        .stack_pointer => if (allocateSelectorReg(occupied)) |reg| .{ .stack_pointer = reg } else .{ .spill = next_spill_slot },
    };
}

fn allocateSelectorReg(occupied: *SelectorRegisterOccupancy) ?ArgReg {
    for (selector_allocatable_regs) |reg| {
        const index = argRegIndex(reg);
        if (!occupied.gpr[index]) {
            occupied.gpr[index] = true;
            return reg;
        }
    }
    return null;
}

fn allocateSelectorPair(occupied: *SelectorRegisterOccupancy) ?RegPair {
    for (selector_allocatable_pairs) |pair| {
        const lo = argRegIndex(pair.lo);
        const hi = argRegIndex(pair.hi);
        if (!occupied.gpr[lo] and !occupied.gpr[hi]) {
            occupied.gpr[lo] = true;
            occupied.gpr[hi] = true;
            return pair;
        }
    }
    return null;
}

fn allocateSelectorXmm(occupied: *SelectorRegisterOccupancy) ?XmmReg {
    for (selector_allocatable_xmm_regs) |reg| {
        const index = xmmRegIndex(reg);
        if (!occupied.xmm[index]) {
            occupied.xmm[index] = true;
            return reg;
        }
    }
    return null;
}

fn releaseSelectorAssignment(occupied: *SelectorRegisterOccupancy, assignment: PlannedValueAssignment) void {
    switch (assignment) {
        .gpr32, .gpr64, .stack_pointer => |reg| occupied.gpr[argRegIndex(reg)] = false,
        .gpr128 => |pair| {
            occupied.gpr[argRegIndex(pair.lo)] = false;
            occupied.gpr[argRegIndex(pair.hi)] = false;
        },
        .fp16, .fp32, .fp64, .vector_xmm => |reg| occupied.xmm[xmmRegIndex(reg)] = false,
        .stack_object, .spill => {},
    }
}

fn assignmentUsesRegisters(assignment: PlannedValueAssignment) bool {
    return switch (assignment) {
        .gpr32, .gpr64, .gpr128, .fp16, .fp32, .fp64, .vector_xmm, .stack_pointer => true,
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
                    .insertvalue => |insert| {
                        if (sysv_abi.sseAggregateReturnKind(insert.aggregate_ty) != null and !exempt_values.contains(result)) {
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
                    .call => |call| {
                        const is_overflow_tuple = std.mem.eql(u8, call.callee, "llvm.uadd.with.overflow.i32") or
                            std.mem.eql(u8, call.callee, "llvm.usub.with.overflow.i32") or
                            std.mem.eql(u8, call.callee, "llvm.smul.with.overflow.i64") or
                            std.mem.eql(u8, call.callee, "llvm.smul.with.overflow.i128");
                        if (is_overflow_tuple and !exempt_values.contains(result)) {
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

fn collectAggregateReturnLeafUses(
    uses: *NameSet,
    function: ir.Function,
    terminator: ir.Terminator,
    pressure_exempt_values: NameSet,
) !void {
    const ret = switch (terminator) {
        .ret => |ret| ret,
        else => return,
    };
    if (sysv_abi.sseAggregateReturnKind(ret.ty) == null) return;
    var aggregate = ret.value orelse return;
    var depth: usize = 0;
    while (depth < 2) : (depth += 1) {
        const name = namedValue(aggregate) orelse return;
        const instruction = findInstruction(function, name) orelse return;
        const insert = switch (instruction.kind) {
            .insertvalue => |insert| insert,
            else => return,
        };
        try addNamedPressureUse(uses, insert.value, pressure_exempt_values);
        aggregate = insert.aggregate;
    }
}

fn findInstruction(function: ir.Function, name: []const u8) ?ir.Instruction {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.result) |result| if (std.mem.eql(u8, result, name)) return instruction;
        }
    }
    return null;
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

pub fn instructionUsesName(allocator: std.mem.Allocator, instruction: ir.Instruction, name: []const u8) !bool {
    var uses = NameSet.init(allocator);
    defer uses.deinit();
    var exemptions = NameSet.init(allocator);
    defer exemptions.deinit();
    try collectInstructionNamedUses(&uses, instruction, exemptions);
    return uses.contains(name);
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

pub fn terminatorUsesName(allocator: std.mem.Allocator, terminator: ir.Terminator, name: []const u8) !bool {
    var uses = NameSet.init(allocator);
    defer uses.deinit();
    var exemptions = NameSet.init(allocator);
    defer exemptions.deinit();
    try collectTerminatorNamedUses(&uses, terminator, exemptions);
    return uses.contains(name);
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

pub fn namedValue(value: ir.Value) ?[]const u8 {
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
