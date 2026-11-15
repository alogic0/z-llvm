const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_types = @import("../types.zig");
const sysv_abi = @import("../sysv_abi.zig");
const inspection = @import("inspection.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const composed_helpers = @import("composed_helpers.zig");
const selector_state = @import("composed_selector_state.zig");
const aggregate_object = @import("aggregate_object.zig");
const selector_scalar = @import("composed_selector_scalar.zig");
const stack_arguments = @import("stack_arguments.zig");

pub const MachineFunction = x86_64_machine.MachineFunction;
const ArgReg = x86_64_types.ArgReg;
const FrameIndex = x86_64_types.FrameIndex;
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
const pair_a = selector_types.pair_a;
const pair_b = selector_types.pair_b;
const selector_allocatable_pairs = selector_types.selector_allocatable_pairs;
const selector_allocatable_regs = selector_types.selector_allocatable_regs;
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

pub const ComposedBlockSelector = selector_state.ComposedBlockSelector;
// Large compiler functions need multi-megabyte spill areas. This bounded limit
// still fits signed x86 displacements; allocateFrame touches every crossed page.
const max_frame_bytes: u32 = selector_types.max_stack_frame_bytes;

pub fn allocaAlignment(attrs: ?[]const u8, natural_alignment: u32) ?u32 {
    const text = attrs orelse return natural_alignment;
    var fields = std.mem.splitScalar(u8, text, ',');
    while (fields.next()) |raw_field| {
        const field = std.mem.trim(u8, raw_field, " \t");
        if (!std.mem.startsWith(u8, field, "align ")) continue;
        const alignment = std.fmt.parseUnsigned(u32, std.mem.trim(u8, field["align ".len..], " \t"), 10) catch return null;
        if (alignment == 0 or !std.math.isPowerOfTwo(alignment)) return null;
        return @max(alignment, natural_alignment);
    }
    return natural_alignment;
}

fn stackFpBits(ty: ir.Type) ?u16 {
    return if (ty == .half) 16 else if (ty == .float) 32 else if (ty == .double) 64 else null;
}

// Scalar conversions, named literals and inline fills use fixed register writes.
// Their preservation demand is additional to virtual-register interval pressure.
fn needsScalarPreservation(inst: ir.Instruction) bool {
    return switch (inst.kind) {
        .call => |call| (sysv_abi.isVariadicCall(call) and call.args.items.len > 3) or
            std.mem.eql(u8, call.callee, "llvm.memset.inline.p0.i64"),
        .cast => |cast| cast.op == .zext and cast.from_ty == .int and cast.to_ty == .int and
            cast.from_ty.int < cast.to_ty.int and (cast.to_ty.int == 32 or cast.to_ty.int == 64),
        .binary => |binary| (binary.ty.eql(.{ .int = 32 }) or binary.ty.eql(.{ .int = 64 })) and
            (binary.lhs == .int or (binary.op == .add and binary.rhs == .int and binary.rhs.int == 0)),
        .gep => |gep| @import("../symbol_address.zig").fromGep(gep) != null,
        else => false,
    };
}

pub fn prepareStackFrame(selector: *ComposedBlockSelector, function: ir.Function) !?Diagnostic {
    var payload_bytes: u32 = 0;
    var scalar_slot_count: usize = 0;
    var array_count: usize = 0;
    var saw_alloca = false;
    var saw_phi = false;
    var saw_array_alloca = false;
    var saw_fixed_smul_overflow = false;
    var saw_wide_icmp = false;
    var saw_pair_intrinsic = false;
    var atomic_slots: u32 = 0;
    var saw_scalar_sse_call = false;
    var saw_memory_fill = false;
    var saw_int_to_fp_cast = false;
    var scalar_conversions: usize = 0;
    var saw_scalar_literal = false;
    var saw_stack_arguments = stack_arguments.hasParameters(function);
    var outgoing_stack_slots: u32 = 0;
    if (selector.allocation_plan) |plan| selector.next_spill_slot = @max(selector.next_spill_slot, plan.spill_slots);

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (needsScalarPreservation(instruction)) {
                if (instruction.kind == .cast) scalar_conversions += 1 else saw_scalar_literal = true;
            }
            if (instruction.kind == .call) if (stack_arguments.callCount(instruction.kind.call)) |count| {
                saw_stack_arguments = true;
                outgoing_stack_slots = @max(outgoing_stack_slots, @as(u32, @intCast(count)));
            };
            if (instruction.kind == .phi) saw_phi = true;
            if (instruction.kind == .atomicrmw) saw_pair_intrinsic = true;
            if (instruction.kind == .cmpxchg) {
                saw_pair_intrinsic = true;
                atomic_slots = std.math.add(u32, atomic_slots, 2) catch return .{ .no_spill_envelope = "scalar-atomic-frame-size" };
            }
            if (instruction.kind == .store and instruction.kind.store.attrs.atomic_ordering != null and
                std.mem.eql(u8, instruction.kind.store.attrs.atomic_ordering.?, "seq_cst"))
            {
                saw_pair_intrinsic = true;
                atomic_slots = std.math.add(u32, atomic_slots, 1) catch return .{ .no_spill_envelope = "scalar-atomic-frame-size" };
            }
            if (instruction.kind == .alloca) {
                saw_alloca = true;
                if (parseI32ArrayType(instruction.kind.alloca.allocated_ty) != null) saw_array_alloca = true;
            }
            if (instruction.kind == .call and
                (std.mem.eql(u8, instruction.kind.call.callee, "llvm.smul.with.overflow.i64") or
                    std.mem.eql(u8, instruction.kind.call.callee, "llvm.umul.with.overflow.i64") or
                    std.mem.eql(u8, instruction.kind.call.callee, "llvm.smul.with.overflow.i128"))) saw_fixed_smul_overflow = true;
            if (instruction.kind == .call and
                (std.mem.eql(u8, instruction.kind.call.callee, "llvm.bswap.i128") or
                    std.mem.eql(u8, instruction.kind.call.callee, "llvm.bitreverse.i32") or
                    std.mem.eql(u8, instruction.kind.call.callee, "llvm.bitreverse.i64") or
                    std.mem.eql(u8, instruction.kind.call.callee, "llvm.bitreverse.i128") or
                    std.mem.eql(u8, instruction.kind.call.callee, "llvm.ctpop.i128"))) saw_pair_intrinsic = true;
            if (instruction.kind == .call and
                (std.mem.eql(u8, instruction.kind.call.callee, "llvm.memset.p0.i64") or
                    std.mem.eql(u8, instruction.kind.call.callee, "llvm.memmove.p0.p0.i64") or
                    std.mem.eql(u8, instruction.kind.call.callee, "llvm.memcpy.p0.p0.i64") or
                    std.mem.eql(u8, instruction.kind.call.callee, "llvm.memcpy.inline.p0.p0.i64"))) saw_memory_fill = true;
            if (instruction.kind == .call and sysv_abi.callHasScalarSseType(instruction.kind.call)) saw_scalar_sse_call = true;
            if (instruction.kind == .cast) {
                const cast = instruction.kind.cast;
                if ((cast.op == .fpext and cast.from_ty == .half and (cast.to_ty == .float or cast.to_ty == .double)) or
                    (cast.op == .fptrunc and cast.from_ty == .float and cast.to_ty == .half)) saw_scalar_sse_call = true;
            }
            if (instruction.kind == .fcmp and instruction.kind.fcmp.operand_ty == .half and
                (instruction.kind.fcmp.predicate == .uno or instruction.kind.fcmp.predicate == .olt)) saw_scalar_sse_call = true;
            if (instruction.kind == .binary and instruction.kind.binary.ty == .half and instruction.kind.binary.op == .fadd) saw_scalar_sse_call = true;
            if (instruction.kind == .icmp and instruction.kind.icmp.operand_ty.eql(.{ .int = 128 })) saw_wide_icmp = true;
            if (instruction.kind == .cast and
                (instruction.kind.cast.op == .sitofp or instruction.kind.cast.op == .uitofp)) saw_int_to_fp_cast = true;
        }
    }

    const pressure = try analyzeStageTwoNoSpillEnvelope(selector.allocator, function);
    const saw_scalar_preservation = scalar_conversions > 1 or saw_scalar_literal;
    const reserve_spill_area = saw_scalar_preservation or saw_stack_arguments or saw_alloca or pressure.exceedsNoSpill() or saw_phi or saw_fixed_smul_overflow or saw_wide_icmp or saw_pair_intrinsic or saw_scalar_sse_call or saw_memory_fill or saw_int_to_fp_cast or (selector.allocation_plan != null and (selector.allocation_plan.?.spill_slots != 0 or selector.allocation_plan.?.preservation_spill_slots != 0));
    const spill_reserved_bytes = std.math.add(u32, spillReservedBytes(selector, reserve_spill_area) orelse return .{ .no_spill_envelope = "composed-block-spill-frame-size" }, std.math.mul(u32, std.math.add(u32, outgoing_stack_slots, atomic_slots) catch return .{ .no_spill_envelope = "scalar-atomic-frame-size" }, 8) catch return .{ .no_spill_envelope = "scalar-atomic-frame-size" }) catch return .{ .no_spill_envelope = "composed-block-call-stack-frame-size" };
    if (spill_reserved_bytes > max_frame_bytes - 24) return .{ .no_spill_envelope = "composed-block-stack-frame-limit" };
    payload_bytes = if (saw_array_alloca) @max(spill_reserved_bytes, stage2SpillReservedBytes()) else 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.kind != .alloca) continue;
            const result_name = instruction.result orelse return .{ .unsupported_value = "composed-block-missing-result" };
            const alloca = instruction.kind.alloca;
            if (alloca.allocated_ty_addrspace != null) return .{ .no_emitter = "composed-block-alloca-addrspace" };
            const integer_bits = if (alloca.allocated_ty == .ptr) @as(?u16, 64) else intBits(alloca.allocated_ty);
            const fp_bits = stackFpBits(alloca.allocated_ty);
            if (integer_bits orelse fp_bits) |raw_bits| {
                if (integer_bits != null and raw_bits > 8 and raw_bits != 64 and raw_bits != 128) return .{ .no_emitter = "composed-block-alloca-form" };
                const bits: u16 = if (integer_bits != null and raw_bits <= 8) 8 else raw_bits;
                payload_bytes = @max(payload_bytes, spill_reserved_bytes);
                scalar_slot_count += 1;
                const natural_alignment: u32 = if (bits == 128) 16 else @max(@as(u32, 1), @as(u32, bits / 8));
                const alignment = allocaAlignment(alloca.attrs, natural_alignment) orelse return .{ .no_emitter = "composed-block-alloca-align" };
                if (alignment > 16) return .{ .no_emitter = "composed-block-alloca-align" };
                payload_bytes = std.mem.alignForward(u32, payload_bytes, alignment);
                const base_disp = payload_bytes;
                const size: u32 = if (bits == 128) stack128FrameBytes() - 8 else @max(@as(u32, 1), @as(u32, bits / 8));
                payload_bytes = std.math.add(u32, payload_bytes, size) catch return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
                if (payload_bytes > max_frame_bytes - 24) return .{ .no_spill_envelope = "composed-block-stack-frame-limit" };
                if (bits == 128) {
                    try selector_state.bindValueLoc(selector, result_name, .{ .stack128 = base_disp });
                } else {
                    try selector_state.bindValueLoc(selector, result_name, .{ .stack_scalar = .{
                        .base_disp = base_disp,
                        .bits = bits,
                        .kind = if (fp_bits != null) .fp else .integer,
                    } });
                }
            } else if (aggregate_object.isF32PairType(selector.module_context, alloca.allocated_ty)) {
                scalar_slot_count += 1;
                const alignment = allocaAlignment(alloca.attrs, aggregate_object.alignment) orelse return .{ .no_emitter = "composed-block-alloca-align" };
                if (alignment != aggregate_object.alignment) return .{ .no_emitter = "composed-block-aggregate-alloca-align" };
                payload_bytes = std.mem.alignForward(u32, @max(payload_bytes, spill_reserved_bytes), alignment);
                const base_disp = payload_bytes;
                payload_bytes = std.math.add(u32, payload_bytes, aggregate_object.byte_size) catch return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
                if (payload_bytes > max_frame_bytes - 24) return .{ .no_spill_envelope = "composed-block-stack-frame-limit" };
                try selector_state.bindValueLoc(selector, result_name, .{ .stack_f32_pair_ptr = .{
                    .object_base_disp = base_disp,
                    .disp = base_disp,
                } });
            } else if (parseI32ArrayType(alloca.allocated_ty)) |len| {
                array_count += 1;
                const alignment = allocaAlignment(alloca.attrs, 4) orelse return .{ .no_emitter = "composed-block-alloca-align" };
                if (alignment > 16) return .{ .no_emitter = "composed-block-alloca-align" };
                payload_bytes = std.mem.alignForward(u32, payload_bytes, alignment);
                const array_bytes = std.math.mul(u32, len, 4) catch return .{ .no_spill_envelope = "composed-block-stack-array-size" };
                const base_disp = payload_bytes;
                payload_bytes = std.math.add(u32, payload_bytes, array_bytes) catch return .{ .no_spill_envelope = "composed-block-stack-array-size" };
                if (payload_bytes > max_frame_bytes - 24) return .{ .no_spill_envelope = "composed-block-stack-frame-limit" };
                try selector_state.bindValueLoc(selector, result_name, .{ .stack_i32_array = .{ .base_disp = base_disp, .len = len } });
            } else {
                return .{ .no_emitter = "composed-block-alloca-form" };
            }
        }
    }

    if (payload_bytes == 0) {
        if (saw_scalar_preservation or saw_stack_arguments or pressure.exceedsNoSpill() or saw_phi or saw_fixed_smul_overflow or saw_wide_icmp or saw_pair_intrinsic or saw_scalar_sse_call or saw_memory_fill or saw_int_to_fp_cast or (selector.allocation_plan != null and selector.allocation_plan.?.preservation_spill_slots != 0)) payload_bytes = spill_reserved_bytes;
    }

    if (payload_bytes == 0) return null;
    const frame_bytes = alignedCallFrameBytes(payload_bytes) orelse return .{ .no_spill_envelope = "composed-block-stack-array-size" };
    if (frame_bytes > max_frame_bytes) return .{ .no_spill_envelope = "composed-block-stack-frame-limit" };
    try allocateFrame(selector, frame_bytes);
    selector.stack_frame_bytes = frame_bytes;
    selector.stack_slot_allocated = scalar_slot_count != 0;
    selector.stack_array_allocated = array_count != 0;
    selector.stack_array_count = array_count;
    return null;
}

// Each push writes the lowest eight bytes of its step. No page can be skipped,
// and the sequence preserves every incoming argument register. The final RSP
// and all frame offsets are identical to a single subtraction.
fn allocateFrame(selector: *ComposedBlockSelector, bytes: u32) !void {
    if (bytes < 4096) return appendSubRsp(selector, bytes);
    var remaining = bytes;
    while (remaining >= 4096) : (remaining -= 4096) {
        try appendSubRsp(selector, 4096 - 8);
        try selector.machine.instructions.append(selector.allocator, .{ .push_imm32 = 0 });
    }
    if (remaining != 0) {
        std.debug.assert(remaining >= 8);
        if (remaining > 8) try appendSubRsp(selector, remaining - 8);
        try selector.machine.instructions.append(selector.allocator, .{ .push_imm32 = 0 });
    }
}

pub fn spillReservedBytes(selector: *const ComposedBlockSelector, reserve_spill_area: bool) ?u32 {
    if (!reserve_spill_area) return 0;
    const preallocated_slots = if (selector.allocation_plan) |plan| @max(plan.spill_slots, selector.next_spill_slot) else selector.next_spill_slot;
    var emergency_slots: usize = stage2_spill_slots;
    if (selector.function) |function| if (stack_arguments.parameters(function.*)) |layout| {
        // The original scalar envelope needs at most ten stack homes plus
        // six register homes. Extended signatures reserve every incoming word.
        emergency_slots = @max(emergency_slots, layout.stack_words + 6);
    };
    if (selector.allocation_plan) |plan| {
        const value_slots = std.math.mul(usize, plan.assignments.count(), 2) catch return null;
        emergency_slots = @max(emergency_slots, value_slots);
    }
    const reserved_slots = std.math.add(usize, preallocated_slots, emergency_slots) catch return null;
    return std.math.mul(u32, std.math.cast(u32, reserved_slots) orelse return null, 8) catch null;
}

pub fn appendSubRsp(selector: *ComposedBlockSelector, bytes: u32) !void {
    switch (bytes) {
        8 => try selector.machine.instructions.append(selector.allocator, .sub_rsp_8),
        24 => try selector.machine.instructions.append(selector.allocator, .sub_rsp_24),
        40 => try selector.machine.instructions.append(selector.allocator, .sub_rsp_40),
        56 => try selector.machine.instructions.append(selector.allocator, .sub_rsp_56),
        else => if (bytes <= std.math.maxInt(i8))
            try selector.machine.instructions.append(selector.allocator, .{ .sub_rsp_imm8 = @intCast(bytes) })
        else
            try selector.machine.instructions.append(selector.allocator, .{ .sub_rsp_imm32 = bytes }),
    }
}

pub fn appendAddRsp(selector: *ComposedBlockSelector, bytes: u32) !void {
    switch (bytes) {
        8 => try selector.machine.instructions.append(selector.allocator, .add_rsp_8),
        24 => try selector.machine.instructions.append(selector.allocator, .add_rsp_24),
        40 => try selector.machine.instructions.append(selector.allocator, .add_rsp_40),
        56 => try selector.machine.instructions.append(selector.allocator, .add_rsp_56),
        else => if (bytes <= std.math.maxInt(i8))
            try selector.machine.instructions.append(selector.allocator, .{ .add_rsp_imm8 = @intCast(bytes) })
        else
            try selector.machine.instructions.append(selector.allocator, .{ .add_rsp_imm32 = bytes }),
    }
}
