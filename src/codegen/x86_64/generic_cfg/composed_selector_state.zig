const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_types = @import("../types.zig");
const inspection = @import("inspection.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const composed_helpers = @import("composed_helpers.zig");
const state_data = @import("composed_selector_state_data.zig");
const eflags = @import("composed_selector_eflags.zig");

pub const MachineFunction = x86_64_machine.MachineFunction;
const ArgReg = x86_64_types.ArgReg;
const FrameIndex = x86_64_types.FrameIndex;
const XmmReg = x86_64_types.XmmReg;
const MachineBinaryOp = x86_64_types.MachineBinaryOp;
const PairSpillLoc = selector_types.PairSpillLoc;
const RegPair = selector_types.RegPair;
const StackArrayLoc = selector_types.StackArrayLoc;
const StackPtrLoc = selector_types.StackPtrLoc;
const ValueBinding = selector_types.ValueBinding;
const ValueLoc = selector_types.ValueLoc;
const VirtualReg = selector_types.VirtualReg;
const VirtualRegClass = selector_types.VirtualRegClass;
const VirtualRegMetadata = selector_types.VirtualRegMetadata;
const VectorShape = selector_types.VectorShape;
const pair_a = selector_types.pair_a;
const pair_b = selector_types.pair_b;
const selector_allocatable_pairs = selector_types.selector_allocatable_pairs;
const selector_allocatable_regs = selector_types.selector_allocatable_regs;
const selector_allocatable_xmm_regs = selector_types.selector_allocatable_xmm_regs;
const argRegIndex = selector_types.argRegIndex;

pub const Diagnostic = inspection.Diagnostic;
pub const SelectionResult = inspection.SelectionResult;

const NameSet = stage2_planning.NameSet;
const PlannedValueAssignment = stage2_planning.PlannedValueAssignment;
const SelectorAllocationPlan = stage2_planning.SelectorAllocationPlan;
const SelectorValueInterval = stage2_planning.SelectorValueInterval;
const SpillSlotAssignment = stage2_planning.SpillSlotAssignment;
const allocateSelectorIntervals = stage2_planning.allocateSelectorIntervals;
const analyzeStageTwoNoSpillEnvelope = stage2_planning.analyzeStageTwoNoSpillEnvelope;
const buildSelectorAllocationPlan = stage2_planning.buildSelectorAllocationPlan;
const namedValue = stage2_planning.namedValue;
const selectorValueMetadata = stage2_planning.selectorValueMetadata;
const stage2SpillReservedBytes = stage2_planning.stage2SpillReservedBytes;
const stage2_max_blocks = stage2_planning.stage2_max_blocks;
const stage2_spill_slots = stage2_planning.stage2_spill_slots;
const phi_regs = [_]ArgReg{ .r8, .r9, .rcx };

const blockHasPhiIncomingFrom = composed_helpers.blockHasPhiIncomingFrom;
const phiIncomingFrom = composed_helpers.phiIncomingFrom;
const canUseExpiredPlanRegisterReuse = composed_helpers.canUseExpiredPlanRegisterReuse;
const machineBinaryOp = composed_helpers.machineBinaryOp;
const isCommutative = composed_helpers.isCommutative;
const locIsAccumulator = composed_helpers.locIsAccumulator;
const valueLocEql = composed_helpers.valueLocEql;
const locContainsReg = composed_helpers.locContainsReg;
const valueIsInt = composed_helpers.valueIsInt;
const intBits = composed_helpers.intBits;
const callArgRegisterCount = composed_helpers.callArgRegisterCount;
const isDefaultOrFastcc = composed_helpers.isDefaultOrFastcc;
const parseI32ArrayType = composed_helpers.parseI32ArrayType;
const alignedCallFrameBytes = composed_helpers.alignedCallFrameBytes;
const stack128FrameBytes = composed_helpers.stack128FrameBytes;
const isComposedReturnType = composed_helpers.isComposedReturnType;
const shiftAmount5 = composed_helpers.shiftAmount5;
const shiftAmount6 = composed_helpers.shiftAmount6;
const shiftAmount7 = composed_helpers.shiftAmount7;
const i32Value = composed_helpers.i32Value;
const i32BitPattern = composed_helpers.i32BitPattern;
const i64Value = composed_helpers.i64Value;

pub const ComposedBlockSelector = state_data.ComposedBlockSelector;
pub const EflagsEffect = eflags.Effect;
pub const EflagsLiveness = eflags.Liveness;

pub fn eflagsInstructionEffect(instruction: x86_64_machine.Instruction) EflagsEffect {
    return eflags.instructionEffect(instruction);
}

pub fn validateEflagsInstructions(
    selector: *const ComposedBlockSelector,
    instructions: []const x86_64_machine.Instruction,
) !void {
    const saved = selector.eflags.snapshot();
    try eflags.validateInstructions(selector.allocator, instructions);
    try selector.eflags.validateSnapshot(saved);
}

fn scratch64RegForUseAvoiding(selector: *const ComposedBlockSelector, avoid: ?ArgReg) ?ArgReg {
    for (selector_allocatable_regs) |reg| {
        if (avoid != null and reg == avoid.?) continue;
        if (scratch64RegIsAvailableForUse(selector, reg)) return reg;
    }
    return null;
}

fn scratch64RegIsAvailableForUse(selector: *const ComposedBlockSelector, reg: ArgReg) bool {
    const status = regConflictStatus(selector, reg) orelse return true;
    return status;
}

fn loadStackU64IntoArg(selector: *ComposedBlockSelector, reg: ArgReg, disp: u32) !void {
    try clobberArgReg(selector, reg);
    if (disp <= std.math.maxInt(u8)) {
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_arg64 = .{ .reg = reg, .disp = @intCast(disp) } });
    } else {
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_arg64 = .{ .reg = reg, .disp = disp } });
    }
}

fn loadStackU64IntoRax(selector: *ComposedBlockSelector, disp: u32) !void {
    try clobberAccumulator(selector);
    if (disp <= std.math.maxInt(u8)) {
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_rax = @intCast(disp) });
    } else {
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_rax = disp });
    }
}

pub fn allocateEdgeLabel(selector: *ComposedBlockSelector) ![]const u8 {
    const label = try std.fmt.allocPrint(selector.allocator, "__zllvm_edge_{d}", .{selector.edge_label_count});
    errdefer selector.allocator.free(label);
    try selector.machine.owned_labels.append(selector.allocator, label);
    selector.edge_label_count += 1;
    return label;
}

pub fn allocateEaxJoinLabel(selector: *ComposedBlockSelector) ![]const u8 {
    const label = try std.fmt.allocPrint(selector.allocator, "__zllvm_edge_{d}_generic_cfg_select_end", .{selector.edge_label_count});
    errdefer selector.allocator.free(label);
    try selector.machine.owned_labels.append(selector.allocator, label);
    selector.edge_label_count += 1;
    return label;
}

pub fn bindValueLoc(selector: *ComposedBlockSelector, name: []const u8, loc: ValueLoc) !void {
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

pub fn bindResultLoc(selector: *ComposedBlockSelector, name: []const u8, actual: ValueLoc) !void {
    const target = plannedResultLoc(selector, name, actual) orelse actual;
    const vreg = if (selector.values.get(name)) |binding|
        binding.vreg
    else blk: {
        const metadata = virtualRegMetadata(actual);
        const created: VirtualReg = .{
            .index = selector.next_virtual_reg,
            .class = metadata.class,
            .bits = metadata.bits,
        };
        selector.next_virtual_reg += 1;
        break :blk created;
    };
    if (!valueLocEql(actual, target)) try materializeLocIntoLocWithBits(selector, actual, target, vreg.bits);
    try selector.values.put(name, .{ .vreg = vreg, .loc = target });
}

pub fn prepareFixedProductDefs(selector: *ComposedBlockSelector) !void {
    try clobberAccumulator(selector);
    try clobberArgReg(selector, .rdx);
}

pub fn bindFixedProductResult(selector: *ComposedBlockSelector, name: []const u8) !void {
    const plan = selector.allocation_plan orelse return error.UnsupportedCodegenValue;
    const assignment = plan.assignment(name) orelse {
        const spill = allocatePairSpillSlots(selector, name) orelse return error.UnsupportedCodegenValue;
        try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = spill.lo });
        try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.hi, .reg = .rdx } });
        try bindValueLoc(selector, name, .{ .spill128 = spill });
        return;
    };
    switch (assignment) {
        .gpr128 => |pair| {
            try clobberArgReg(selector, pair.lo);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = pair.lo });
            if (pair.hi != .rdx) {
                try clobberArgReg(selector, pair.hi);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = pair.hi, .src = .rdx } });
            }
            try bindValueLoc(selector, name, .{ .scratch128 = pair });
        },
        .spill => |index| {
            const spill = pairSpillFrameIndexMaybe(index) orelse return error.UnsupportedCodegenValue;
            if (!frameIndexFitsFrame(selector, spill.lo) or !frameIndexFitsFrame(selector, spill.hi)) return error.UnsupportedCodegenValue;
            try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = spill.lo });
            try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.hi, .reg = .rdx } });
            try bindValueLoc(selector, name, .{ .spill128 = spill });
        },
        .gpr32, .gpr64, .fp16, .fp32, .fp64, .vector_xmm, .stack_object, .stack_pointer => return error.UnsupportedCodegenValue,
    }
}

pub fn plannedResultLoc(selector: *const ComposedBlockSelector, name: []const u8, actual: ValueLoc) ?ValueLoc {
    const plan = selector.allocation_plan orelse return null;
    const assignment = plan.assignment(name) orelse return null;
    const planned: ?ValueLoc = switch (assignment) {
        .gpr32 => |reg| switch (actual) {
            .arg32, .scratch32, .eax, .spill64 => .{ .scratch32 = reg },
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
        .fp16 => |reg| switch (actual) {
            .xmm => |fp| if (fp.bits == 16) .{ .xmm = .{ .reg = reg, .bits = 16 } } else null,
            .spill_fp => |fp| if (fp.bits == 16) .{ .xmm = .{ .reg = reg, .bits = 16 } } else null,
            else => null,
        },
        .fp32 => |reg| switch (actual) {
            .xmm => |fp| if (fp.bits == 32) .{ .xmm = .{ .reg = reg, .bits = 32 } } else null,
            .spill_fp => |fp| if (fp.bits == 32) .{ .xmm = .{ .reg = reg, .bits = 32 } } else null,
            else => null,
        },
        .fp64 => |reg| switch (actual) {
            .xmm => |fp| if (fp.bits == 64) .{ .xmm = .{ .reg = reg, .bits = 64 } } else null,
            .spill_fp => |fp| if (fp.bits == 64) .{ .xmm = .{ .reg = reg, .bits = 64 } } else null,
            else => null,
        },
        .vector_xmm => |reg| switch (actual) {
            .xmm => |fp| if (fp.vectorShape()) |shape| .{ .xmm = .{ .reg = reg, .bits = 128, .shape = .{ .vector = shape } } } else null,
            .spill_vector => |vector| .{ .xmm = .{ .reg = reg, .bits = 128, .shape = .{ .vector = vector.shape } } },
            else => null,
        },
        .stack_object, .stack_pointer => actual,
        .spill => |index| switch (actual) {
            .arg32, .scratch32, .eax => if (spillFrameIndexMaybe(index)) |frame_index| if (frameIndexFitsFrame(selector, frame_index)) .{ .spill64 = frame_index } else null else null,
            .arg64, .scratch64, .rax, .spill64 => if (spillFrameIndexMaybe(index)) |frame_index| if (frameIndexFitsFrame(selector, frame_index)) .{ .spill64 = frame_index } else null else null,
            .arg128, .scratch128, .spill128 => if (pairSpillFrameIndexMaybe(index)) |spill| if (frameIndexFitsFrame(selector, spill.lo) and frameIndexFitsFrame(selector, spill.hi)) .{ .spill128 = spill } else null else null,
            .xmm => |fp| if (fp.vectorShape()) |shape|
                if (pairSpillFrameIndexMaybe(index)) |frames|
                    if (frameIndexFitsFrame(selector, frames.lo) and frameIndexFitsFrame(selector, frames.hi)) .{ .spill_vector = .{ .frames = frames, .shape = shape } } else null
                else
                    null
            else if (spillFrameIndexMaybe(index)) |frame_index|
                if (frameIndexFitsFrame(selector, frame_index)) .{ .spill_fp = .{ .frame_index = frame_index, .bits = fp.bits } } else null
            else
                null,
            .spill_fp => actual,
            .spill_vector => actual,
            else => null,
        },
    };
    const target = planned orelse return null;
    if (plan.forwardValue(name) != null) return target;
    if (std.meta.activeTag(target) == .spill64 or std.meta.activeTag(target) == .spill128 or std.meta.activeTag(target) == .spill_fp or std.meta.activeTag(target) == .spill_vector) return target;
    if (valueLocEql(actual, target)) return target;
    return if (selector.enable_expired_plan_register_reuse and selector.expired_binding_this_position and targetLocHasOnlyExpiredConflicts(selector, target)) target else null;
}

pub fn targetLocHasOnlyExpiredConflicts(selector: *const ComposedBlockSelector, target: ValueLoc) bool {
    return switch (target) {
        .scratch32, .scratch64 => |reg| regHasOnlyExpiredConflicts(selector, reg),
        .scratch128 => |pair| blk: {
            var saw_conflict = false;
            if (regConflictStatus(selector, pair.lo)) |expired| {
                if (!expired) break :blk false;
                saw_conflict = true;
            }
            if (regConflictStatus(selector, pair.hi)) |expired| {
                if (!expired) break :blk false;
                saw_conflict = true;
            }
            break :blk saw_conflict;
        },
        .arg32, .arg64, .arg128, .xmm, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => false,
    };
}

pub fn regHasOnlyExpiredConflicts(selector: *const ComposedBlockSelector, reg: ArgReg) bool {
    var saw_conflict = false;
    if (regConflictStatus(selector, reg)) |expired| {
        if (!expired) return false;
        saw_conflict = true;
    }
    return saw_conflict;
}

pub fn regConflictStatus(selector: *const ComposedBlockSelector, reg: ArgReg) ?bool {
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

pub fn expireExpiredBindings(selector: *ComposedBlockSelector) !void {
    selector.expired_binding_this_position = false;
    const plan = selector.allocation_plan orelse return;

    var it = selector.values.iterator();
    while (it.next()) |entry| {
        const end = plan.intervalEnd(entry.key_ptr.*) orelse continue;
        if (end < selector.current_position) selector.expired_binding_this_position = true;
    }
}

pub fn materializeLocIntoLoc(selector: *ComposedBlockSelector, actual: ValueLoc, target: ValueLoc) !void {
    switch (target) {
        .scratch32 => |dst| switch (actual) {
            .arg32, .scratch32, .arg64, .scratch64 => |src| {
                if (src != dst) {
                    try clobberArgReg(selector, dst);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = dst, .src = src } });
                }
            },
            .arg128, .scratch128 => |pair| {
                if (pair.lo != dst) {
                    try clobberArgReg(selector, dst);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = dst, .src = pair.lo } });
                }
            },
            .eax, .rax => {
                try clobberArgReg(selector, dst);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = dst });
            },
            .spill64 => |frame_index| {
                try clobberArgReg(selector, dst);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = dst, .frame_index = frame_index } });
            },
            .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
        },
        .xmm => |dst| switch (actual) {
            .xmm => |src| {
                if (!src.shapeEql(dst)) return error.UnsupportedCodegenValue;
                if (src.reg != dst.reg) {
                    try clobberXmmReg(selector, dst.reg);
                    try selector.machine.instructions.append(selector.allocator, .{ .movapd_xmm = .{ .dst = dst.reg, .src = src.reg } });
                }
            },
            .spill_fp => |src| {
                if (src.bits != dst.bits) return error.UnsupportedCodegenValue;
                try clobberXmmReg(selector, dst.reg);
                if (dst.bits == 64) {
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_xmm64_rsp = .{ .frame_index = src.frame_index, .reg = dst.reg } });
                } else if (dst.bits == 16 or dst.bits == 32) {
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_xmm32_rsp = .{ .frame_index = src.frame_index, .reg = dst.reg } });
                } else return error.UnsupportedCodegenValue;
            },
            .spill_vector => |src| {
                const dst_shape = dst.vectorShape() orelse return error.UnsupportedCodegenValue;
                if (!src.shape.eql(dst_shape) or !frameIndexFitsFrame(selector, src.frames.lo) or !frameIndexFitsFrame(selector, src.frames.hi)) return error.UnsupportedCodegenValue;
                try clobberXmmReg(selector, dst.reg);
                try selector.machine.instructions.append(selector.allocator, switch (src.shape.lane_type) {
                    .float => .{ .reload_xmm128ps_rsp = .{ .frame_index = src.frames.lo, .reg = dst.reg } },
                    .double => .{ .reload_xmm128_rsp = .{ .frame_index = src.frames.lo, .reg = dst.reg } },
                    .integer => if (src.shape.lane_bits == 32)
                        .{ .reload_xmm128ps_rsp = .{ .frame_index = src.frames.lo, .reg = dst.reg } }
                    else
                        .{ .reload_xmm128_rsp = .{ .frame_index = src.frames.lo, .reg = dst.reg } },
                });
            },
            else => return error.UnsupportedCodegenValue,
        },
        .spill_fp => |dst| switch (actual) {
            .xmm => |src| {
                if (src.bits != dst.bits or !frameIndexFitsFrame(selector, dst.frame_index)) return error.UnsupportedCodegenValue;
                if (dst.bits == 64) {
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_xmm64_rsp = .{ .frame_index = dst.frame_index, .reg = src.reg } });
                } else if (dst.bits == 16 or dst.bits == 32) {
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_xmm32_rsp = .{ .frame_index = dst.frame_index, .reg = src.reg } });
                } else return error.UnsupportedCodegenValue;
            },
            .spill_fp => |src| {
                if (src.bits != dst.bits) return error.UnsupportedCodegenValue;
                if (!src.frame_index.eql(dst.frame_index)) {
                    try clobberXmmReg(selector, .xmm0);
                    try materializeLocIntoLoc(selector, actual, .{ .xmm = .{ .reg = .xmm0, .bits = src.bits } });
                    try materializeLocIntoLoc(selector, .{ .xmm = .{ .reg = .xmm0, .bits = src.bits } }, target);
                }
            },
            else => return error.UnsupportedCodegenValue,
        },
        .spill_vector => |dst| switch (actual) {
            .xmm => |src| {
                const src_shape = src.vectorShape() orelse return error.UnsupportedCodegenValue;
                if (!src_shape.eql(dst.shape) or !frameIndexFitsFrame(selector, dst.frames.lo) or !frameIndexFitsFrame(selector, dst.frames.hi)) return error.UnsupportedCodegenValue;
                try selector.machine.instructions.append(selector.allocator, switch (src_shape.lane_type) {
                    .float => .{ .spill_xmm128ps_rsp = .{ .frame_index = dst.frames.lo, .reg = src.reg } },
                    .double => .{ .spill_xmm128_rsp = .{ .frame_index = dst.frames.lo, .reg = src.reg } },
                    .integer => if (src_shape.lane_bits == 32)
                        .{ .spill_xmm128ps_rsp = .{ .frame_index = dst.frames.lo, .reg = src.reg } }
                    else
                        .{ .spill_xmm128_rsp = .{ .frame_index = dst.frames.lo, .reg = src.reg } },
                });
            },
            .spill_vector => |src| {
                if (!src.shape.eql(dst.shape)) return error.UnsupportedCodegenValue;
                if (!src.frames.lo.eql(dst.frames.lo)) {
                    const scratch: ValueLoc = .{ .xmm = .{ .reg = .xmm0, .bits = 128, .shape = .{ .vector = src.shape } } };
                    try materializeLocIntoLoc(selector, actual, scratch);
                    try materializeLocIntoLoc(selector, scratch, target);
                }
            },
            else => return error.UnsupportedCodegenValue,
        },
        .scratch64 => |dst| switch (actual) {
            .arg64, .scratch64 => |src| {
                if (src != dst) {
                    try clobberArgReg(selector, dst);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = src } });
                }
            },
            .arg128, .scratch128 => |pair| {
                if (pair.lo != dst) {
                    try clobberArgReg(selector, dst);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = pair.lo } });
                }
            },
            .rax => {
                try clobberArgReg(selector, dst);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst });
            },
            .spill64 => |frame_index| {
                try clobberArgReg(selector, dst);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst, .frame_index = frame_index } });
            },
            .readonly_table_ptr => |ptr| switch (ptr.storage) {
                .reg => |src| {
                    if (src != dst) {
                        try clobberArgReg(selector, dst);
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = src } });
                    }
                },
                .spill => |frame_index| {
                    try clobberArgReg(selector, dst);
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst, .frame_index = frame_index } });
                },
            },
            .stack_f32_pair_ptr => |ptr| {
                try clobberArgReg(selector, dst);
                try emitStackF32PairPointerIntoReg(selector, ptr, dst);
            },
            .arg32, .scratch32, .xmm, .eax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
        },
        .scratch128 => |dst| switch (actual) {
            .arg128, .scratch128 => |src| try emitPairIntoScratch(selector, src, dst),
            .spill128 => |spill| {
                try clobberAccumulator(selector);
                try clobberArgReg(selector, dst.lo);
                try clobberArgReg(selector, dst.hi);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst.lo, .frame_index = spill.lo } });
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst.hi, .frame_index = spill.hi } });
            },
            .stack128_value => |disp| {
                try loadStackU64IntoArg(selector, dst.lo, disp);
                try loadStackU64IntoArg(selector, dst.hi, disp + 8);
            },
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .xmm, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
        },
        .spill64 => |frame_index| {
            if (!frameIndexFitsFrame(selector, frame_index)) return error.UnsupportedCodegenValue;
            switch (actual) {
                .arg32, .scratch32 => |src| {
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg_rsp = .{ .frame_index = frame_index, .reg = src } });
                },
                .arg64, .scratch64 => |src| {
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = frame_index, .reg = src } });
                },
                .eax => {
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_eax_rsp = frame_index });
                },
                .rax => {
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = frame_index });
                },
                .spill64 => |source| if (!source.eql(frame_index)) {
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = source });
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = frame_index });
                },
                .stack_f32_pair_ptr => |ptr| {
                    try clobberArgReg(selector, .rcx);
                    try emitStackF32PairPointerIntoReg(selector, ptr, .rcx);
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = frame_index, .reg = .rcx } });
                },
                .arg128, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
            }
        },
        .spill128 => |spill| {
            if (!frameIndexFitsFrame(selector, spill.lo) or !frameIndexFitsFrame(selector, spill.hi)) return error.UnsupportedCodegenValue;
            switch (actual) {
                .arg128, .scratch128 => |pair| {
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.lo, .reg = pair.lo } });
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.hi, .reg = pair.hi } });
                },
                .spill128 => |source| {
                    if (source.lo.eql(spill.lo) and source.hi.eql(spill.hi)) return;
                    try clobberAccumulator(selector);
                    if (source.hi.eql(spill.lo)) {
                        if (!source.hi.eql(spill.hi)) {
                            try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = source.hi });
                            try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = spill.hi });
                        }
                        if (!source.lo.eql(spill.lo)) {
                            try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = source.lo });
                            try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = spill.lo });
                        }
                    } else {
                        if (!source.lo.eql(spill.lo)) {
                            try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = source.lo });
                            try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = spill.lo });
                        }
                        if (!source.hi.eql(spill.hi)) {
                            try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = source.hi });
                            try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = spill.hi });
                        }
                    }
                },
                .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
            }
        },
        .arg32, .arg64, .arg128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .aggregate_sse => return error.UnsupportedCodegenValue,
    }
}

fn emitStackF32PairPointerIntoReg(selector: *ComposedBlockSelector, ptr: selector_types.StackF32PairPtrLoc, reg: ArgReg) !void {
    const disp = std.math.cast(i32, ptr.disp) orelse return error.UnsupportedCodegenValue;
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rsp_arg64 = reg });
    if (disp != 0) try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_imm32 = .{ .reg = reg, .imm = disp } });
}

pub fn materializeLocIntoLocWithBits(selector: *ComposedBlockSelector, actual: ValueLoc, target: ValueLoc, bits: u16) !void {
    const target_frame = switch (target) {
        .spill64 => |frame_index| frame_index,
        else => return materializeLocIntoLoc(selector, actual, target),
    };
    const actual_frame = switch (actual) {
        .spill64 => |frame_index| frame_index,
        else => return materializeLocIntoLoc(selector, actual, target),
    };
    if (bits > 32 or actual_frame.eql(target_frame)) return materializeLocIntoLoc(selector, actual, target);
    if (!frameIndexFitsFrame(selector, target_frame)) return error.UnsupportedCodegenValue;
    try clobberAccumulator(selector);
    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_eax = actual_frame });
    try selector.machine.instructions.append(selector.allocator, .{ .spill_eax_rsp = target_frame });
}

pub fn frameIndexFitsFrame(selector: *const ComposedBlockSelector, frame_index: FrameIndex) bool {
    const offset = frame_index.byteOffset() catch return false;
    const end = std.math.add(u32, offset, 8) catch return false;
    return end <= selector.stack_frame_bytes;
}

pub fn valueLoc(selector: *const ComposedBlockSelector, name: []const u8) ?ValueLoc {
    const binding = selector.values.get(name) orelse return null;
    return binding.loc;
}

pub fn virtualRegMetadata(loc: ValueLoc) VirtualRegMetadata {
    return switch (loc) {
        .arg32, .scratch32, .eax => .{ .class = .gpr32, .bits = 32 },
        .arg64, .scratch64, .rax, .spill64 => .{ .class = .gpr64, .bits = 64 },
        .arg128, .scratch128, .spill128, .stack128_value => .{ .class = .gpr128, .bits = 128 },
        .xmm => |fp| .{ .class = switch (fp.bits) {
            16 => .fp16,
            32 => .fp32,
            64 => .fp64,
            128 => if (fp.vectorShape() != null) .vector_xmm else unreachable,
            else => unreachable,
        }, .bits = fp.bits },
        .spill_fp => |fp| .{ .class = switch (fp.bits) {
            16 => .fp16,
            32 => .fp32,
            64 => .fp64,
            else => unreachable,
        }, .bits = fp.bits },
        .spill_vector => .{ .class = .vector_xmm, .bits = 128 },
        .stack_scalar, .stack128, .stack_i32_array => .{ .class = .stack_object, .bits = 0 },
        .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr => .{ .class = .stack_pointer, .bits = 64 },
        .aggregate_sse => .{ .class = .aggregate_sse, .bits = 128 },
    };
}

pub fn bindEax(selector: *ComposedBlockSelector, name: []const u8) !void {
    try bindResultLoc(selector, name, .eax);
}

pub fn bindRax(selector: *ComposedBlockSelector, name: []const u8) !void {
    try bindResultLoc(selector, name, .rax);
}

pub fn bindAccumulator(selector: *ComposedBlockSelector, name: []const u8, bits: u16) !void {
    if (bits == 64) try bindRax(selector, name) else try bindEax(selector, name);
}

pub fn bindScratch(selector: *ComposedBlockSelector, name: []const u8, reg: ArgReg, bits: u16) !void {
    const actual: ValueLoc = if (bits == 64) .{ .scratch64 = reg } else .{ .scratch32 = reg };
    try bindResultLoc(selector, name, actual);
}

pub fn bindPairScratch(selector: *ComposedBlockSelector, name: []const u8, pair: RegPair) !void {
    try bindResultLoc(selector, name, .{ .scratch128 = pair });
}

pub fn emitPairIntoAbiRegs(selector: *ComposedBlockSelector, src: RegPair, dst: RegPair) !void {
    if (src.eql(dst)) return;
    try clobberAccumulator(selector);
    try clobberArgReg(selector, dst.lo);
    try clobberArgReg(selector, dst.hi);
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

pub fn spillCurrentAccumulator(selector: *ComposedBlockSelector) !?Diagnostic {
    const name = liveAccumulatorName(selector) orelse return null;
    return try spillValue(selector, name);
}

pub fn preserveRaxForDestructiveAccumulatorUse(selector: *ComposedBlockSelector, value: ir.Value) !?Diagnostic {
    _ = value;
    return try spillCurrentAccumulator(selector);
}

pub fn preserveLiveAccumulatorValue(selector: *ComposedBlockSelector, name: []const u8) !?Diagnostic {
    const binding = selector.values.get(name) orelse return .{ .unsupported_value = "composed-block-preserve-live-lhs" };
    const loc = binding.loc;
    const bits = binding.vreg.bits;
    switch (loc) {
        .eax, .rax => {},
        else => return null,
    }
    const dst = scratch64RegForUseAvoiding(selector, null) orelse return try spillValue(selector, name);
    try clobberArgReg(selector, dst);
    if (bits == 64) {
        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst });
        try bindValueLoc(selector, name, .{ .scratch64 = dst });
    } else if (bits <= 32) {
        try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = dst });
        try bindValueLoc(selector, name, .{ .scratch32 = dst });
    } else return .{ .no_emitter = "composed-block-preserve-live-lhs-width" };
    return null;
}

pub fn spillValue(selector: *ComposedBlockSelector, name: []const u8) !?Diagnostic {
    if (selector.stack_frame_bytes < 24) return .{ .no_spill_envelope = "composed-block-spill-frame" };
    const loc = resolveValue(selector, .{ .named = name }) orelse return .{ .unsupported_value = "composed-block-spill-unknown" };
    switch (loc) {
        .spill64 => return null,
        .spill128, .spill_fp, .spill_vector => return null,
        .aggregate_sse => return .{ .no_emitter = "composed-block-aggregate-spill" },
        .readonly_table_ptr => |ptr| if (ptr.storage == .spill) return null,
        else => {},
    }
    if (loc == .xmm and loc.xmm.vectorShape() != null) {
        const shape = loc.xmm.vectorShape().?;
        const frames = allocatePairSpillSlots(selector, name) orelse return .{ .no_spill_envelope = "composed-block-vector-spill-slots" };
        try selector.machine.instructions.append(selector.allocator, switch (shape.lane_type) {
            .float => .{ .spill_xmm128ps_rsp = .{ .frame_index = frames.lo, .reg = loc.xmm.reg } },
            .double => .{ .spill_xmm128_rsp = .{ .frame_index = frames.lo, .reg = loc.xmm.reg } },
            .integer => if (shape.lane_bits == 32)
                .{ .spill_xmm128ps_rsp = .{ .frame_index = frames.lo, .reg = loc.xmm.reg } }
            else
                .{ .spill_xmm128_rsp = .{ .frame_index = frames.lo, .reg = loc.xmm.reg } },
        });
        try bindValueLoc(selector, name, .{ .spill_vector = .{ .frames = frames, .shape = shape } });
        return null;
    }
    const frame_index = allocateSpillSlot(selector, name) orelse return .{ .no_spill_envelope = "composed-block-spill-slots" };
    switch (loc) {
        .arg32, .scratch32 => |reg| {
            try selector.machine.instructions.append(selector.allocator, .{ .spill_arg_rsp = .{ .frame_index = frame_index, .reg = reg } });
        },
        .arg64, .scratch64 => |reg| {
            try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = frame_index, .reg = reg } });
        },
        .eax => {
            try selector.machine.instructions.append(selector.allocator, .{ .spill_eax_rsp = frame_index });
        },
        .rax => {
            try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = frame_index });
        },
        .xmm => |fp| {
            if (fp.bits == 64) {
                try selector.machine.instructions.append(selector.allocator, .{ .spill_xmm64_rsp = .{ .frame_index = frame_index, .reg = fp.reg } });
            } else if (fp.bits == 16 or fp.bits == 32) {
                try selector.machine.instructions.append(selector.allocator, .{ .spill_xmm32_rsp = .{ .frame_index = frame_index, .reg = fp.reg } });
            } else return .{ .no_emitter = "composed-block-spill-fp-width" };
            try bindValueLoc(selector, name, .{ .spill_fp = .{ .frame_index = frame_index, .bits = fp.bits } });
            return null;
        },
        .readonly_table_ptr => |ptr| switch (ptr.storage) {
            .reg => |reg| {
                try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = frame_index, .reg = reg } });
                var spilled = ptr;
                spilled.storage = .{ .spill = frame_index };
                try bindValueLoc(selector, name, .{ .readonly_table_ptr = spilled });
                return null;
            },
            .spill => return null,
        },
        .arg128, .scratch128 => return .{ .no_emitter = "composed-block-spill-loc-pair" },
        .stack_scalar => return .{ .no_emitter = "composed-block-spill-loc-stack64" },
        .stack128 => return .{ .no_emitter = "composed-block-spill-loc-stack128" },
        .stack128_value => return .{ .no_emitter = "composed-block-spill-loc-stack128-value" },
        .stack_i32_array => return .{ .no_emitter = "composed-block-spill-loc-stack-i32-array" },
        .stack_i32_ptr => return .{ .no_emitter = "composed-block-spill-loc-stack-i32-ptr" },
        .stack_f32_pair_ptr => return .{ .no_emitter = "composed-block-spill-loc-stack-f32-pair-ptr" },
        .spill64 => return .{ .no_emitter = "composed-block-spill-loc-spill64" },
        .spill128 => return .{ .no_emitter = "composed-block-spill-loc-spill128" },
        .spill_fp => return .{ .no_emitter = "composed-block-spill-loc-spill-fp" },
        .spill_vector => return .{ .no_emitter = "composed-block-spill-loc-spill-vector" },
        .aggregate_sse => return .{ .no_emitter = "composed-block-spill-loc-aggregate" },
    }
    try bindValueLoc(selector, name, .{ .spill64 = frame_index });
    return null;
}

pub fn spillPairValue(selector: *ComposedBlockSelector, name: []const u8) !?Diagnostic {
    if (selector.stack_frame_bytes < stack128FrameBytes()) return .{ .no_spill_envelope = "composed-block-pair-spill-frame" };
    const loc = resolveValue(selector, .{ .named = name }) orelse return .{ .unsupported_value = "composed-block-pair-spill-unknown" };
    switch (loc) {
        .spill128 => return null,
        else => {},
    }
    const pair = switch (loc) {
        .arg128, .scratch128 => |pair| pair,
        .arg32, .scratch32, .eax => return .{ .no_emitter = "composed-block-pair-spill-loc-gpr32" },
        .arg64, .scratch64, .rax, .spill64 => return .{ .no_emitter = "composed-block-pair-spill-loc-gpr64" },
        .xmm, .spill_fp, .spill_vector => return .{ .no_emitter = "composed-block-pair-spill-loc-fp" },
        .aggregate_sse => return .{ .no_emitter = "composed-block-pair-spill-loc-aggregate" },
        .stack_scalar => return .{ .no_emitter = "composed-block-pair-spill-loc-stack64" },
        .stack128 => return .{ .no_emitter = "composed-block-pair-spill-loc-stack128" },
        .stack128_value => return .{ .no_emitter = "composed-block-pair-spill-loc-stack128-value" },
        .stack_i32_array => return .{ .no_emitter = "composed-block-pair-spill-loc-stack-i32-array" },
        .stack_i32_ptr => return .{ .no_emitter = "composed-block-pair-spill-loc-stack-i32-ptr" },
        .stack_f32_pair_ptr => return .{ .no_emitter = "composed-block-pair-spill-loc-stack-f32-pair-ptr" },
        .readonly_table_ptr => return .{ .no_emitter = "composed-block-pair-spill-loc-readonly-table-ptr" },
        .spill128 => return .{ .no_emitter = "composed-block-pair-spill-loc-spill128" },
    };
    const spill = allocatePairSpillSlots(selector, name) orelse return .{ .no_spill_envelope = "composed-block-pair-spill-slots" };
    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.lo, .reg = pair.lo } });
    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.hi, .reg = pair.hi } });
    try bindValueLoc(selector, name, .{ .spill128 = spill });
    return null;
}

pub fn ensurePairSpill(selector: *ComposedBlockSelector, value: ir.Value) !PairSpillLoc {
    const name = namedValue(value) orelse return error.UnsupportedCodegenValue;
    if (resolveValue(selector, value)) |loc| switch (loc) {
        .spill128 => |spill| return spill,
        else => {},
    } else return error.UnsupportedCodegenValue;
    if (try spillPairValue(selector, name)) |_| return error.UnsupportedCodegenValue;
    return switch (resolveValue(selector, value) orelse return error.UnsupportedCodegenValue) {
        .spill128 => |spill| spill,
        else => error.UnsupportedCodegenValue,
    };
}

pub fn emitUnsignedLimbProduct(selector: *ComposedBlockSelector, lhs: FrameIndex, rhs: FrameIndex, name: []const u8) !PairSpillLoc {
    try prepareFixedProductDefs(selector);
    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = lhs });
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = rhs } });
    try selector.machine.instructions.append(selector.allocator, .{ .mul_rax_arg64_full = .rcx });
    try bindFixedProductResult(selector, name);
    return switch (valueLoc(selector, name) orelse return error.UnsupportedCodegenValue) {
        .spill128 => |spill| spill,
        else => error.UnsupportedCodegenValue,
    };
}

pub fn accumulateLimbWithCarry(selector: *ComposedBlockSelector, lhs: FrameIndex, rhs: FrameIndex, sum: ArgReg, carry: ArgReg) !void {
    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = lhs });
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = rhs } });
    try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_rax = .rcx });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = sum });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = carry });
    try selector.machine.instructions.append(selector.allocator, .adc_rax_imm0);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = carry });
}

pub fn accumulateRegWithCarry(selector: *ComposedBlockSelector, lhs: ArgReg, rhs: FrameIndex, sum: ArgReg, carry: ArgReg) !void {
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = lhs });
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = rhs } });
    try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_rax = .rcx });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = sum });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = carry });
    try selector.machine.instructions.append(selector.allocator, .adc_rax_imm0);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = carry });
}

pub fn emitSignedUpperCorrection(selector: *ComposedBlockSelector, sign_limb: FrameIndex, subtract: PairSpillLoc) !void {
    const correction_label = try allocateEdgeLabel(selector);
    const end_label = try allocateEdgeLabel(selector);
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = sign_limb } });
    try selector.machine.instructions.append(selector.allocator, .{ .test_arg64 = .rcx });
    try selector.machine.instructions.append(selector.allocator, .{ .js = correction_label });
    try selector.machine.instructions.append(selector.allocator, .{ .jmp = end_label });
    try selector.machine.instructions.append(selector.allocator, .{ .label = correction_label });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = .r9 });
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = subtract.lo } });
    try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .sub, .reg = .rcx } });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = .r9 });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = .rdx });
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = subtract.hi } });
    try selector.machine.instructions.append(selector.allocator, .{ .sbb_arg64_rax = .rcx });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = .rdx });
    try selector.machine.instructions.append(selector.allocator, .{ .label = end_label });
}

pub fn allocateSpillSlot(selector: *ComposedBlockSelector, name: []const u8) ?FrameIndex {
    if (selector.spill_slots.get(name)) |assignment| return spillFrameIndexMaybe(assignment.base);
    const base = selector.next_spill_slot;
    const frame_index = spillFrameIndexMaybe(base) orelse return null;
    if (selector.stack_frame_bytes != 0 and !frameIndexFitsFrame(selector, frame_index)) return null;
    selector.spill_slots.put(name, .{ .base = base, .slots = 1 }) catch return null;
    selector.next_spill_slot = base + 1;
    return frame_index;
}

pub fn allocatePairSpillSlots(selector: *ComposedBlockSelector, name: []const u8) ?PairSpillLoc {
    if (selector.spill_slots.get(name)) |assignment| {
        if (assignment.slots < 2) return null;
        return pairSpillFrameIndexMaybe(assignment.base);
    }
    const base = selector.next_spill_slot;
    const spill = pairSpillFrameIndexMaybe(base) orelse return null;
    if (selector.stack_frame_bytes != 0 and (!frameIndexFitsFrame(selector, spill.lo) or !frameIndexFitsFrame(selector, spill.hi))) return null;
    selector.spill_slots.put(name, .{ .base = base, .slots = 2 }) catch return null;
    selector.next_spill_slot = base + 2;
    return spill;
}

pub fn spillFrameIndex(index: usize) FrameIndex {
    return spillFrameIndexMaybe(index) orelse unreachable;
}

pub fn spillFrameIndexMaybe(index: usize) ?FrameIndex {
    const byte_offset = std.math.mul(usize, index, 8) catch return null;
    return frameIndexForByteOffset(byte_offset);
}

pub fn frameIndexForByteOffset(byte_offset: usize) ?FrameIndex {
    if (byte_offset % 4 != 0) return null;
    return FrameIndex.fromSlot(byte_offset / 4) catch null;
}

pub fn pairSpillFrameIndexMaybe(index: usize) ?PairSpillLoc {
    const lo = spillFrameIndexMaybe(index) orelse return null;
    const hi = spillFrameIndexMaybe(index + 1) orelse return null;
    return .{ .lo = lo, .hi = hi };
}

pub fn emitValueIntoEax(selector: *ComposedBlockSelector, value: ir.Value) !void {
    switch (value) {
        .int => |int| {
            try clobberAccumulator(selector);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(int) });
        },
        .named => {
            const loc = resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
            switch (loc) {
                .arg32, .scratch32, .arg64, .scratch64 => |reg| {
                    try clobberAccumulator(selector);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_eax = reg });
                },
                .arg128, .scratch128 => |pair| {
                    try clobberAccumulator(selector);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_eax = pair.lo });
                },
                .spill64 => |frame_index| {
                    try clobberAccumulator(selector);
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_eax = frame_index });
                },
                .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
                .eax, .rax => {},
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn emitValueIntoRax(selector: *ComposedBlockSelector, value: ir.Value) !void {
    switch (value) {
        .int => return error.UnsupportedCodegenValue,
        .named => {
            const loc = resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
            switch (loc) {
                .arg64, .scratch64 => |reg| {
                    try clobberAccumulator(selector);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = reg });
                },
                .spill64 => |frame_index| {
                    try clobberAccumulator(selector);
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = frame_index });
                },
                .arg128, .scratch128 => |pair| {
                    try clobberAccumulator(selector);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = pair.lo });
                },
                .rax => {},
                .arg32, .scratch32, .xmm, .eax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn emitValueIntoAccumulator(selector: *ComposedBlockSelector, value: ir.Value, bits: u16) !void {
    if (bits == 64) try emitValueIntoRax(selector, value) else try emitValueIntoEax(selector, value);
}

pub fn preserveCurrentEaxIntoScratch(selector: *ComposedBlockSelector) !?Diagnostic {
    const name = liveEaxName(selector) orelse return null;
    const dst = scratch64RegForUseAvoiding(selector, null) orelse {
        try spillValueOrError(selector, name);
        return null;
    };
    try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = dst });
    try bindValueLoc(selector, name, .{ .scratch32 = dst });
    return null;
}

pub fn preserveCurrentRaxIntoScratch(selector: *ComposedBlockSelector) !?Diagnostic {
    const name = liveRaxName(selector) orelse return null;
    const dst = scratch64RegForUseAvoiding(selector, null) orelse
        return .{ .no_spill_envelope = "composed-block-preserve-rax" };
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst });
    try bindValueLoc(selector, name, .{ .scratch64 = dst });
    return null;
}

pub fn scratchRegIsProvenFree(selector: *const ComposedBlockSelector, reg: ArgReg) bool {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        switch (entry.value_ptr.loc) {
            .arg32, .arg64, .scratch32, .scratch64 => |value_reg| if (value_reg == reg) return false,
            .arg128, .scratch128 => |pair| if (pair.contains(reg)) return false,
            .stack_i32_ptr => |stack_ptr| if (stack_ptr.index) |index| if (index.reg == reg) return false,
            .readonly_table_ptr => |ptr| switch (ptr.storage) {
                .reg => |value_reg| if (value_reg == reg) return false,
                .spill => {},
            },
            .eax, .rax, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return true;
}

pub fn emitValueIntoI128Return(selector: *ComposedBlockSelector, value: ir.Value) !void {
    const loc = resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
    switch (loc) {
        .stack128_value => |disp| {
            try loadStackU64IntoArg(selector, .rdx, disp + 8);
            try loadStackU64IntoRax(selector, disp);
            try clobberArgReg(selector, .rdx);
        },
        .arg128, .scratch128 => |pair| {
            try emitPairIntoAbiRegs(selector, pair, .{ .lo = .rdi, .hi = .rdx });
            try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = .rdi });
        },
        .spill128 => |spill| {
            try clobberArgReg(selector, .rdx);
            try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = spill.hi } });
            try clobberAccumulator(selector);
            try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = spill.lo });
        },
        .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .xmm, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
    }
}

pub fn emitValueIntoFpReturn(selector: *ComposedBlockSelector, value: ir.Value, bits: u16) !void {
    const loc = resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
    switch (loc) {
        .xmm => |fp| {
            if (fp.bits != bits) return error.UnsupportedCodegenValue;
            if (fp.reg != .xmm0) try selector.machine.instructions.append(selector.allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = fp.reg } });
        },
        .spill_fp => |fp| {
            if (fp.bits != bits) return error.UnsupportedCodegenValue;
            if (bits == 64) {
                try selector.machine.instructions.append(selector.allocator, .{ .reload_xmm64_rsp = .{ .frame_index = fp.frame_index, .reg = .xmm0 } });
            } else if (bits == 16 or bits == 32) {
                try selector.machine.instructions.append(selector.allocator, .{ .reload_xmm32_rsp = .{ .frame_index = fp.frame_index, .reg = .xmm0 } });
            } else return error.UnsupportedCodegenValue;
        },
        else => return error.UnsupportedCodegenValue,
    }
}

pub fn emitValueIntoScratch(selector: *ComposedBlockSelector, value: ir.Value, reg: ArgReg, bits: u16) !void {
    try emitValueIntoScratchExcept(selector, value, reg, bits, null);
}

pub fn emitPhiValueIntoScratch(selector: *ComposedBlockSelector, value: ir.Value, reg: ArgReg, bits: u16) !void {
    switch (value) {
        .named => {
            const loc = resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
            if (bits == 64) {
                switch (loc) {
                    .arg64, .scratch64 => |src| if (src != reg) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = reg, .src = src } }),
                    .rax => try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = reg }),
                    .spill64 => |frame_index| try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = frame_index } }),
                    .arg128, .scratch128 => |pair| if (pair.lo != reg) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = reg, .src = pair.lo } }),
                    .stack_f32_pair_ptr => |ptr| try emitStackF32PairPointerIntoReg(selector, ptr, reg),
                    .arg32, .scratch32, .xmm, .eax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
                }
            } else {
                switch (loc) {
                    .arg32, .scratch32, .arg64, .scratch64 => |src| if (src != reg) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = reg, .src = src } }),
                    .arg128, .scratch128 => |pair| if (pair.lo != reg) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = reg, .src = pair.lo } }),
                    .eax, .rax => try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = reg }),
                    .spill64 => |frame_index| try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = reg, .frame_index = frame_index } }),
                    .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
                }
            }
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn phiSourceDiagnostic(selector: *const ComposedBlockSelector, value: ir.Value) []const u8 {
    const loc = resolveValue(selector, value) orelse return "stage2-phi-src-unknown";
    return switch (loc) {
        .arg32 => "stage2-phi-src-arg32",
        .arg64 => "stage2-phi-src-arg64",
        .arg128 => "stage2-phi-src-arg128",
        .eax => "stage2-phi-src-eax",
        .rax => "stage2-phi-src-rax",
        .scratch32 => "stage2-phi-src-scratch32",
        .scratch64 => "stage2-phi-src-scratch64",
        .scratch128 => "stage2-phi-src-scratch128",
        .stack_scalar => "stage2-phi-src-stack64",
        .stack128 => "stage2-phi-src-stack128",
        .stack128_value => "stage2-phi-src-stack128-value",
        .stack_i32_array => "stage2-phi-src-stack-i32-array",
        .stack_i32_ptr => "stage2-phi-src-stack-i32-ptr",
        .stack_f32_pair_ptr => "stage2-phi-src-stack-f32-pair-ptr",
        .readonly_table_ptr => "stage2-phi-src-readonly-table-ptr",
        .spill64 => "stage2-phi-src-spill64",
        .spill128 => "stage2-phi-src-spill128",
        .xmm => "stage2-phi-src-xmm",
        .spill_fp => "stage2-phi-src-spill-fp",
        .spill_vector => "stage2-phi-src-spill-vector",
        .aggregate_sse => "stage2-phi-src-aggregate-sse",
    };
}

pub fn emitValueIntoScratchExcept(selector: *ComposedBlockSelector, value: ir.Value, reg: ArgReg, bits: u16, ignore_name: ?[]const u8) !void {
    switch (value) {
        .int => return error.UnsupportedCodegenValue,
        .named => {
            const loc = resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
            if (bits == 64) {
                switch (loc) {
                    .arg64, .scratch64 => |src| {
                        if (src != reg) {
                            try clobberArgRegExcept(selector, reg, ignore_name);
                            try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{
                                .dst = reg,
                                .src = src,
                            } });
                        }
                    },
                    .rax => {
                        try clobberArgRegExcept(selector, reg, ignore_name);
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = reg });
                    },
                    .spill64 => |frame_index| {
                        try clobberArgRegExcept(selector, reg, ignore_name);
                        try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = frame_index } });
                    },
                    .arg128, .scratch128 => |pair| {
                        if (pair.lo != reg) {
                            try clobberArgRegExcept(selector, reg, ignore_name);
                            try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{
                                .dst = reg,
                                .src = pair.lo,
                            } });
                        }
                    },
                    .arg32, .scratch32, .xmm, .eax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
                }
            } else {
                switch (loc) {
                    .arg32, .scratch32, .arg64, .scratch64 => |src| {
                        if (src != reg) {
                            try clobberArgRegExcept(selector, reg, ignore_name);
                            try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{
                                .dst = reg,
                                .src = src,
                            } });
                        }
                    },
                    .arg128, .scratch128 => |pair| {
                        if (pair.lo != reg) {
                            try clobberArgRegExcept(selector, reg, ignore_name);
                            try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{
                                .dst = reg,
                                .src = pair.lo,
                            } });
                        }
                    },
                    .eax, .rax => {
                        try clobberArgRegExcept(selector, reg, ignore_name);
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = reg });
                    },
                    .spill64 => |frame_index| {
                        try clobberArgRegExcept(selector, reg, ignore_name);
                        try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = reg, .frame_index = frame_index } });
                    },
                    .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
                }
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn emitBinaryArgAccumulator(selector: *ComposedBlockSelector, op: MachineBinaryOp, reg: ArgReg, bits: u16) !void {
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

pub fn emitBinaryLocIntoAccumulator(selector: *ComposedBlockSelector, op: MachineBinaryOp, loc: ValueLoc, bits: u16) !void {
    const reg: ArgReg = switch (loc) {
        .arg32, .scratch32 => |reg| if (bits <= 32) reg else return error.UnsupportedCodegenValue,
        .arg64, .scratch64 => |reg| if (bits == 64) reg else return error.UnsupportedCodegenValue,
        .spill64 => |frame_index| if (bits == 64) blk: {
            try clobberArgReg(selector, .rcx);
            try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
            break :blk .rcx;
        } else if (bits <= 32) blk: {
            try clobberArgReg(selector, .rcx);
            try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
            break :blk .rcx;
        } else return error.UnsupportedCodegenValue,
        .arg128, .scratch128, .xmm, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
    };
    try emitBinaryArgAccumulator(selector, op, reg, bits);
}

pub fn emitPairLshrImmediate(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, amount: u7) !void {
    if (amount > 127) return error.UnsupportedCodegenValue;
    const existing = resolvePairValue(selector, value);
    const dst = if (existing) |src|
        choosePairScratch(selector, src) orelse return error.UnsupportedCodegenValue
    else
        choosePairScratch(selector, null) orelse return error.UnsupportedCodegenValue;
    const src = if (existing) |src| src else try materializePairValue(selector, value, dst);
    switch (amount) {
        0 => {
            try emitPairIntoScratch(selector, src, dst);
        },
        64 => {
            try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.hi } });
            try emitZeroArg64(selector, dst.hi);
        },
        1...63 => {
            try emitPairIntoScratch(selector, src, dst);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = dst.hi });
            try selector.machine.instructions.append(selector.allocator, .{ .shl_rax_imm6 = @intCast(64 - amount) });
            try selector.machine.instructions.append(selector.allocator, .{ .shr_arg64_imm6 = .{ .reg = dst.lo, .amount = @intCast(amount) } });
            try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .@"or", .reg = dst.lo } });
            try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst.lo });
            try selector.machine.instructions.append(selector.allocator, .{ .shr_arg64_imm6 = .{ .reg = dst.hi, .amount = @intCast(amount) } });
        },
        65...127 => return error.UnsupportedCodegenValue,
    }
    try bindPairScratch(selector, result_name, dst);
}

pub fn emitPairShlImmediate(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, amount: u7) !void {
    if (amount != 64) return error.UnsupportedCodegenValue;
    const existing = resolvePairValue(selector, value);
    const dst = if (existing) |src| src else try materializePairValue(selector, value, pair_a);
    try clobberArgReg(selector, dst.hi);
    if (dst.lo != dst.hi) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = dst.lo } });
    try emitZeroArg64(selector, dst.lo);
    try bindPairScratch(selector, result_name, dst);
}

pub fn emitPairIntoScratch(selector: *ComposedBlockSelector, src: RegPair, dst: RegPair) !void {
    if (src.eql(dst)) return;
    try clobberAccumulator(selector);
    try clobberArgReg(selector, dst.lo);
    try clobberArgReg(selector, dst.hi);
    if (src.lo != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.lo } });
    if (src.hi != dst.hi) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = src.hi } });
}

pub fn materializePairValue(selector: *ComposedBlockSelector, value: ir.Value, dst: RegPair) !RegPair {
    switch (value) {
        .named => {},
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
    const loc = resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
    switch (loc) {
        .arg128, .scratch128 => |src| {
            try emitPairIntoScratch(selector, src, dst);
            return dst;
        },
        .stack128_value => |disp| {
            try loadStackU64IntoArg(selector, dst.lo, disp);
            try loadStackU64IntoArg(selector, dst.hi, disp + 8);
            return dst;
        },
        .spill128 => |spill| {
            try clobberAccumulator(selector);
            try clobberArgReg(selector, dst.lo);
            try clobberArgReg(selector, dst.hi);
            try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst.lo, .frame_index = spill.lo } });
            try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst.hi, .frame_index = spill.hi } });
            return dst;
        },
        .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .xmm, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
    }
}

pub fn emitPairLowLaneIntoScratch(selector: *ComposedBlockSelector, value: ir.Value, dst: ArgReg) !void {
    switch (value) {
        .named => {},
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
    const loc = resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
    switch (loc) {
        .arg128, .scratch128 => |pair| {
            if (pair.lo != dst) {
                try clobberArgReg(selector, dst);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = pair.lo } });
            }
        },
        .stack128_value => |disp| {
            try clobberArgReg(selector, dst);
            try loadStackU64IntoArg(selector, dst, disp);
        },
        .spill128 => |spill| {
            try clobberArgReg(selector, dst);
            try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst, .frame_index = spill.lo } });
        },
        .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .xmm, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
    }
}

pub fn emitPairHighLaneIntoRax(selector: *ComposedBlockSelector, value: ir.Value) !void {
    const loc = resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
    try clobberAccumulator(selector);
    switch (loc) {
        .arg128, .scratch128 => |pair| try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = pair.hi }),
        .stack128_value => |disp| if (disp + 8 <= std.math.maxInt(u8))
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_rax = @intCast(disp + 8) })
        else
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_rax = disp + 8 }),
        .spill128 => |spill| try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = spill.hi }),
        .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .xmm, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
    }
}

pub fn emitPairSignMask(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, dst: RegPair) !void {
    const src = try materializePairValue(selector, value, dst);
    if (src.hi != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.hi } });
    try selector.machine.instructions.append(selector.allocator, .{ .sar_arg64_imm6 = .{ .reg = dst.lo, .amount = 63 } });
    if (dst.hi != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = dst.lo } });
    try bindPairScratch(selector, result_name, dst);
}

pub fn emitPairXorInPlace(selector: *ComposedBlockSelector, dst: RegPair, rhs: RegPair) !void {
    try emitPairLaneBinaryInto(selector, dst.lo, .xor, dst.lo, rhs.lo);
    try emitPairLaneBinaryInto(selector, dst.hi, .xor, dst.hi, rhs.hi);
}

pub fn emitPairOrInPlace(selector: *ComposedBlockSelector, dst: RegPair, rhs: RegPair) !void {
    try emitPairLaneBinaryInto(selector, dst.lo, .@"or", dst.lo, rhs.lo);
    try emitPairLaneBinaryInto(selector, dst.hi, .@"or", dst.hi, rhs.hi);
}

pub fn emitPairSubInPlace(selector: *ComposedBlockSelector, dst: RegPair, rhs: RegPair) !void {
    try clobberAccumulator(selector);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = dst.lo });
    try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .sub, .reg = rhs.lo } });
    try clobberArgReg(selector, dst.lo);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst.lo });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = dst.hi });
    try selector.machine.instructions.append(selector.allocator, .{ .sbb_arg64_rax = rhs.hi });
    try clobberArgReg(selector, dst.hi);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst.hi });
}

pub fn emitPairLaneBinaryInto(selector: *ComposedBlockSelector, dst: ArgReg, op: MachineBinaryOp, lhs: ArgReg, rhs: ArgReg) !void {
    try clobberAccumulator(selector);
    try clobberArgReg(selector, dst);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = lhs });
    try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{
        .op = op,
        .reg = rhs,
    } });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst });
}

pub fn emitZeroArg64(selector: *ComposedBlockSelector, reg: ArgReg) !void {
    try clobberArgReg(selector, reg);
    switch (reg) {
        .rdx => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rdx = 0 }),
        .rcx => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = 0 }),
        .r8 => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_r8 = 0 }),
        .r9 => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_r9 = 0 }),
        .rdi => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rdi = 0 }),
        .rsi => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rsi = 0 }),
    }
}

pub fn choosePairScratch(selector: *const ComposedBlockSelector, src: ?RegPair) ?RegPair {
    for (selector_allocatable_pairs) |pair| {
        if (src) |source| if (source.eql(pair)) continue;
        if (pairScratchIsAvailableForUse(selector, pair)) return pair;
    }
    return null;
}

pub fn choosePairScratchForClobber(selector: *const ComposedBlockSelector, src: ?RegPair) ?RegPair {
    if (!nextSpillSlotsFit(selector, 2)) return choosePairScratch(selector, src);
    for (selector_allocatable_pairs) |pair| {
        if (src) |source| if (source.eql(pair)) continue;
        if (livePairNameContainingReg(selector, pair.lo) != null) continue;
        if (livePairNameContainingReg(selector, pair.hi) != null) continue;
        return pair;
    }
    return null;
}

pub fn nextSpillSlotsFit(selector: *const ComposedBlockSelector, slots: usize) bool {
    if (slots == 0) return true;
    const last = std.math.add(usize, selector.next_spill_slot, slots - 1) catch return false;
    const frame_index = spillFrameIndexMaybe(last) orelse return false;
    return frameIndexFitsFrame(selector, frame_index);
}

pub fn pairScratchIsAvailableForUse(selector: *const ComposedBlockSelector, pair: RegPair) bool {
    return scratch64RegIsAvailableForUse(selector, pair.lo) and scratch64RegIsAvailableForUse(selector, pair.hi);
}

pub fn clobberArgReg(selector: *ComposedBlockSelector, reg: ArgReg) !void {
    try clobberArgRegExcept(selector, reg, null);
}

pub fn clobberArgRegExcept(selector: *ComposedBlockSelector, reg: ArgReg, ignore_name: ?[]const u8) !void {
    while (pairNameContainingRegExcept(selector, reg, ignore_name)) |name| {
        if (valueMustSurviveClobber(selector, name)) {
            try spillPairValueOrError(selector, name);
        } else {
            _ = selector.values.remove(name);
        }
    }
    while (scalarNameInRegExcept(selector, reg, ignore_name)) |name| {
        if (valueMustSurviveClobber(selector, name)) {
            try spillValueOrError(selector, name);
        } else {
            _ = selector.values.remove(name);
        }
    }
}

pub fn clobberXmmReg(selector: *ComposedBlockSelector, reg: XmmReg) !void {
    while (fpNameInReg(selector, reg)) |name| {
        if (valueMustSurviveClobber(selector, name)) {
            try spillValueOrError(selector, name);
        } else {
            _ = selector.values.remove(name);
        }
    }
}

fn fpNameInReg(selector: *const ComposedBlockSelector, reg: XmmReg) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| switch (entry.value_ptr.loc) {
        .xmm => |fp| if (fp.reg == reg) return entry.key_ptr.*,
        else => {},
    };
    return null;
}

pub fn valueMustSurviveClobber(selector: *const ComposedBlockSelector, name: []const u8) bool {
    if (selector.phi_results.contains(name)) return true;
    return if (selector.preserve_current_position_values)
        valueIsLiveAtOrAfterCurrent(selector, name)
    else
        valueIsLiveAfterCurrent(selector, name);
}

pub fn clobberAccumulator(selector: *ComposedBlockSelector) !void {
    dropExpiredAccumulatorBindings(selector);
    while (liveAccumulatorName(selector)) |name| {
        try spillValueOrError(selector, name);
    }
}

pub fn spillAccumulatorAliasesExcept(selector: *ComposedBlockSelector, value: ir.Value) !void {
    const ignored = switch (value) {
        .named => |name| name,
        else => return,
    };
    while (liveAccumulatorNameExcept(selector, ignored)) |name| {
        try spillValueOrError(selector, name);
    }
}

pub fn liveAccumulatorNameExcept(selector: *const ComposedBlockSelector, ignored: []const u8) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (std.mem.eql(u8, entry.key_ptr.*, ignored)) continue;
        if (!valueIsLiveAtOrAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .eax, .rax => return entry.key_ptr.*,
            .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return null;
}

pub fn dropExpiredAccumulatorBindings(selector: *ComposedBlockSelector) void {
    while (true) {
        var expired_name: ?[]const u8 = null;
        var it = selector.values.iterator();
        while (it.next()) |entry| {
            switch (entry.value_ptr.loc) {
                .eax, .rax => {},
                .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => continue,
            }
            if (valueMustSurviveClobber(selector, entry.key_ptr.*)) continue;
            expired_name = entry.key_ptr.*;
            break;
        }
        if (expired_name) |name| {
            _ = selector.values.remove(name);
            continue;
        }
        break;
    }
}

pub fn spillLiveCallerClobbersForCall(selector: *ComposedBlockSelector) !?Diagnostic {
    if (try spillCurrentAccumulator(selector)) |diagnostic| return diagnostic;
    for (selector_allocatable_regs) |reg| {
        if (livePairNameContainingReg(selector, reg)) |name| {
            if (try spillPairValue(selector, name)) |diagnostic| return diagnostic;
        }
        if (liveScalarNameInReg(selector, reg)) |name| {
            if (try spillValue(selector, name)) |diagnostic| return diagnostic;
        }
    }
    for (selector_allocatable_xmm_regs) |reg| {
        while (liveFpNameInReg(selector, reg)) |name| {
            if (try spillValue(selector, name)) |diagnostic| return diagnostic;
        }
    }
    return null;
}

fn liveFpNameInReg(selector: *const ComposedBlockSelector, reg: XmmReg) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (!valueIsLiveAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .xmm => |fp| if (fp.reg == reg) return entry.key_ptr.*,
            else => {},
        }
    }
    return null;
}

pub fn liveAccumulatorName(selector: *const ComposedBlockSelector) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (!valueIsLiveAtOrAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .eax, .rax => return entry.key_ptr.*,
            .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return null;
}

pub fn liveAccumulatorNameAfterCurrent(selector: *const ComposedBlockSelector) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (!valueIsLiveAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .eax, .rax => return entry.key_ptr.*,
            .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return null;
}

pub fn valueIsLiveAtOrAfterCurrent(selector: *const ComposedBlockSelector, name: []const u8) bool {
    const plan = selector.allocation_plan orelse return false;
    const end = plan.intervalEnd(name) orelse return true;
    return end >= selector.current_position;
}

pub fn liveEaxName(selector: *const ComposedBlockSelector) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (!valueIsLiveAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .eax => return entry.key_ptr.*,
            .arg32, .arg64, .arg128, .rax, .scratch32, .scratch64, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return null;
}

pub fn liveRaxName(selector: *const ComposedBlockSelector) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (!valueIsLiveAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .rax => return entry.key_ptr.*,
            .arg32, .arg64, .arg128, .eax, .scratch32, .scratch64, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return null;
}

pub fn liveScalarNameInReg(selector: *const ComposedBlockSelector, reg: ArgReg) ?[]const u8 {
    return liveScalarNameInRegExcept(selector, reg, null);
}

pub fn scalarNameInRegExcept(selector: *const ComposedBlockSelector, reg: ArgReg, ignore_name: ?[]const u8) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (ignore_name) |ignored| {
            if (std.mem.eql(u8, entry.key_ptr.*, ignored)) continue;
        }
        switch (entry.value_ptr.loc) {
            .arg32, .arg64, .scratch32, .scratch64 => |value_reg| if (value_reg == reg) return entry.key_ptr.*,
            .readonly_table_ptr => |ptr| switch (ptr.storage) {
                .reg => |value_reg| if (value_reg == reg) return entry.key_ptr.*,
                .spill => {},
            },
            .arg128, .scratch128, .xmm, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return null;
}

pub fn liveScalarNameInRegExcept(selector: *const ComposedBlockSelector, reg: ArgReg, ignore_name: ?[]const u8) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (ignore_name) |ignored| {
            if (std.mem.eql(u8, entry.key_ptr.*, ignored)) continue;
        }
        if (!valueIsLiveAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .arg32, .arg64, .scratch32, .scratch64 => |value_reg| if (value_reg == reg) return entry.key_ptr.*,
            .readonly_table_ptr => |ptr| switch (ptr.storage) {
                .reg => |value_reg| if (value_reg == reg) return entry.key_ptr.*,
                .spill => {},
            },
            .arg128, .scratch128, .xmm, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return null;
}

pub fn livePairNameContainingReg(selector: *const ComposedBlockSelector, reg: ArgReg) ?[]const u8 {
    return livePairNameContainingRegExcept(selector, reg, null);
}

pub fn pairNameContainingRegExcept(selector: *const ComposedBlockSelector, reg: ArgReg, ignore_name: ?[]const u8) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (ignore_name) |ignored| {
            if (std.mem.eql(u8, entry.key_ptr.*, ignored)) continue;
        }
        switch (entry.value_ptr.loc) {
            .arg128, .scratch128 => |pair| if (pair.contains(reg)) return entry.key_ptr.*,
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return null;
}

pub fn livePairNameContainingRegExcept(selector: *const ComposedBlockSelector, reg: ArgReg, ignore_name: ?[]const u8) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (ignore_name) |ignored| {
            if (std.mem.eql(u8, entry.key_ptr.*, ignored)) continue;
        }
        if (!valueIsLiveAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .arg128, .scratch128 => |pair| if (pair.contains(reg)) return entry.key_ptr.*,
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return null;
}

pub fn valueIsLiveAfterCurrent(selector: *const ComposedBlockSelector, name: []const u8) bool {
    const plan = selector.allocation_plan orelse return false;
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        const stack_ptr = switch (entry.value_ptr.loc) {
            .stack_i32_ptr => |stack_ptr| stack_ptr,
            else => continue,
        };
        const index = stack_ptr.index orelse continue;
        if (!std.mem.eql(u8, index.name, name) and
            (index.addend_name == null or !std.mem.eql(u8, index.addend_name.?, name))) continue;
        const pointer_end = plan.intervalEnd(entry.key_ptr.*) orelse return true;
        if (pointer_end > selector.current_position) return true;
    }
    const end = plan.intervalEnd(name) orelse return true;
    return end > selector.current_position;
}

pub fn spillValueOrError(selector: *ComposedBlockSelector, name: []const u8) !void {
    if (try spillValue(selector, name)) |_| return error.UnsupportedCodegenValue;
}

pub fn spillPairValueOrError(selector: *ComposedBlockSelector, name: []const u8) !void {
    if (try spillPairValue(selector, name)) |_| return error.UnsupportedCodegenValue;
}

pub fn spillLiveValuesForCfgBoundary(selector: *ComposedBlockSelector) !void {
    while (liveRegisterValueName(selector)) |name| {
        const loc = selector.values.get(name).?.loc;
        switch (loc) {
            .arg128, .scratch128 => try spillPairValueOrError(selector, name),
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64 => try spillValueOrError(selector, name),
            .xmm, .readonly_table_ptr => try spillValueOrError(selector, name),
            .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => unreachable,
        }
        if (selector.phi_results.contains(name)) {
            try selector.phi_destinations.put(name, selector.values.get(name).?.loc);
        }
    }
}

fn liveRegisterValueName(selector: *const ComposedBlockSelector) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (!valueIsLiveAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .xmm => return entry.key_ptr.*,
            .readonly_table_ptr => |ptr| if (ptr.storage == .reg) return entry.key_ptr.*,
            .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return null;
}

pub fn resolvePairValue(selector: *const ComposedBlockSelector, value: ir.Value) ?RegPair {
    const loc = resolveValue(selector, value) orelse return null;
    return switch (loc) {
        .arg128, .scratch128 => |pair| pair,
        .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => null,
    };
}

pub fn resolveValue(selector: *const ComposedBlockSelector, value: ir.Value) ?ValueLoc {
    return switch (value) {
        .named => |name| {
            const loc = valueLoc(selector, name) orelse resolveForwardValue(selector, name) orelse return null;
            return switch (loc) {
                .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .xmm => loc,
                .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .spill64, .spill128, .spill_fp, .spill_vector => loc,
                .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .aggregate_sse => loc,
            };
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

fn resolveForwardValue(selector: *const ComposedBlockSelector, name: []const u8) ?ValueLoc {
    const plan = selector.allocation_plan orelse return null;
    const forward = plan.forwardValue(name) orelse return null;
    if (selector.current_position >= forward.definition_position) return null;
    return switch (plan.assignment(name) orelse return null) {
        .gpr32 => |reg| if (forward.metadata.class == .gpr32) .{ .scratch32 = reg } else null,
        .gpr64 => |reg| if (forward.metadata.class == .gpr64) .{ .scratch64 = reg } else null,
        .spill => |index| switch (forward.metadata.class) {
            .gpr32, .gpr64 => if (spillFrameIndexMaybe(index)) |frame_index|
                if (frameIndexFitsFrame(selector, frame_index)) .{ .spill64 = frame_index } else null
            else
                null,
            .gpr128, .fp16, .fp32, .fp64, .vector_xmm, .aggregate_sse, .stack_object, .stack_pointer => null,
        },
        .gpr128, .fp16, .fp32, .fp64, .vector_xmm, .stack_object, .stack_pointer => null,
    };
}
