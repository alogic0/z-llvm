const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_match = @import("../match.zig");
const x86_64_types = @import("../types.zig");
const inspection = @import("inspection.zig");
const selector_fp = @import("composed_selector_fp.zig");
const selector_state = @import("composed_selector_state.zig");
const state_data = @import("composed_selector_state_data.zig");
const selector_types = @import("selector_types.zig");

const ComposedBlockSelector = state_data.ComposedBlockSelector;
const Diagnostic = inspection.Diagnostic;
const VectorShape = selector_types.VectorShape;
const XmmReg = x86_64_types.XmmReg;
const xmm_regs = selector_types.selector_allocatable_xmm_regs;

const VectorConstant = struct {
    bits: [2]u64,
    shape: VectorShape,
};

const VectorOperand = struct {
    shape: VectorShape,
    constant: ?VectorConstant,
};

pub fn lowerBinary(selector: *ComposedBlockSelector, result: ?[]const u8, binary: ir.BinaryInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-vector-missing-result" };
    if (!isPackedFp2(binary.ty)) return .{ .no_emitter = "composed-vector-binary-type" };
    if (binary.op != .fadd and binary.op != .fsub and binary.op != .fmul) return .{ .no_emitter = "composed-vector-binary-op" };

    const lhs = describeVectorValue(selector, binary.lhs, binary.ty) orelse return .{ .unsupported_value = "composed-vector-binary-lhs" };
    const rhs = describeVectorValue(selector, binary.rhs, binary.ty) orelse return .{ .unsupported_value = "composed-vector-binary-rhs" };
    const rhs_reg = vectorValueReg(selector, binary.rhs);
    const dst = resultXmmReg(selector, result_name, binary.lhs, rhs_reg) orelse return .{ .no_spill_envelope = "composed-vector-binary-dst" };
    if (try materializeVectorValue(selector, binary.lhs, lhs, dst, rhs_reg)) |diagnostic| return diagnostic;
    const src = vectorValueReg(selector, binary.rhs) orelse blk: {
        const scratch = scratchXmmReg(selector, dst, null);
        if (try materializeVectorValue(selector, binary.rhs, rhs, scratch, dst)) |diagnostic| return diagnostic;
        break :blk scratch;
    };

    try selector_state.clobberXmmReg(selector, dst);
    try selector.machine.instructions.append(selector.allocator, switch (lhs.shape.lane_type) {
        .float => switch (binary.op) {
            .fadd => .{ .addps_xmm = .{ .dst = dst, .src = src } },
            .fsub => .{ .subps_xmm = .{ .dst = dst, .src = src } },
            .fmul => .{ .mulps_xmm = .{ .dst = dst, .src = src } },
            else => unreachable,
        },
        .double => switch (binary.op) {
            .fadd => .{ .addpd_xmm = .{ .dst = dst, .src = src } },
            .fsub => .{ .subpd_xmm = .{ .dst = dst, .src = src } },
            .fmul => .{ .mulpd_xmm = .{ .dst = dst, .src = src } },
            else => unreachable,
        },
        .integer => unreachable,
    });
    var result_shape = lhs.shape;
    result_shape.defined_lanes &= rhs.shape.defined_lanes;
    try bindVectorResult(selector, result_name, dst, result_shape);
    return null;
}

pub fn lowerFabsV2F32(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-vector-fabs-result" };
    const ty: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .float } };
    if (!call.ret_ty.eql(ty) or call.args.items.len != 1 or !call.args.items[0].ty.eql(ty) or call.inline_asm != null or call.callee_value != null) {
        return .{ .no_emitter = "composed-vector-fabs-form" };
    }
    const value = call.args.items[0].value;
    const operand = describeVectorValue(selector, value, ty) orelse return .{ .unsupported_value = "composed-vector-fabs-source" };
    if (operand.shape.kind != .data or operand.shape.lane_type != .float) return .{ .unsupported_value = "composed-vector-fabs-source" };
    const source_reg = vectorValueReg(selector, value);
    const dst = resultXmmReg(selector, result_name, value, null) orelse return .{ .no_spill_envelope = "composed-vector-fabs-dst" };
    if (try materializeVectorValue(selector, value, operand, dst, source_reg)) |diagnostic| return diagnostic;
    const mask = scratchXmmReg(selector, dst, null);
    try materializeI32Splat(selector, 0x7fff_ffff, mask);
    try selector_state.clobberXmmReg(selector, dst);
    try selector.machine.instructions.append(selector.allocator, .{ .andps_xmm = .{ .dst = dst, .src = mask } });
    try bindVectorResult(selector, result_name, dst, operand.shape);
    return null;
}

pub fn lowerBitcast(selector: *ComposedBlockSelector, result: ?[]const u8, cast: ir.CastInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-vector-bitcast-result" };
    if (cast.op != .bitcast or !isPackedFp2(cast.from_ty)) return .{ .no_emitter = "composed-vector-bitcast-form" };
    const result_shape = shapeForType(cast.to_ty, 0) orelse return .{ .no_emitter = "composed-vector-bitcast-form" };
    if (result_shape.lane_type != .integer or result_shape.lane_bits != shapeForType(cast.from_ty, 0).?.lane_bits) {
        return .{ .no_emitter = "composed-vector-bitcast-form" };
    }
    const operand = describeVectorValue(selector, cast.value, cast.from_ty) orelse return .{ .unsupported_value = "composed-vector-bitcast-source" };
    if (operand.shape.kind != .data) return .{ .unsupported_value = "composed-vector-bitcast-source" };
    const source_reg = vectorValueReg(selector, cast.value);
    const dst = resultXmmReg(selector, result_name, cast.value, null) orelse return .{ .no_spill_envelope = "composed-vector-bitcast-dst" };
    if (try materializeVectorValue(selector, cast.value, operand, dst, source_reg)) |diagnostic| return diagnostic;
    var retagged = result_shape;
    retagged.defined_lanes = operand.shape.defined_lanes;
    try bindVectorResult(selector, result_name, dst, retagged);
    return null;
}

pub fn lowerIcmp(selector: *ComposedBlockSelector, result: ?[]const u8, icmp: ir.IcmpInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-vector-icmp-result" };
    const shape = shapeForType(icmp.operand_ty, 0) orelse return .{ .no_emitter = "composed-vector-icmp-form" };
    if (!icmp.samesign or icmp.predicate != .ugt or shape.lane_type != .integer or shape.lane_bits != 32) {
        return .{ .no_emitter = "composed-vector-icmp-form" };
    }
    const lhs = describeVectorValue(selector, icmp.lhs, icmp.operand_ty) orelse return .{ .unsupported_value = "composed-vector-icmp-lhs" };
    const rhs = describeVectorValue(selector, icmp.rhs, icmp.operand_ty) orelse return .{ .unsupported_value = "composed-vector-icmp-rhs" };
    if (lhs.shape.kind != .data or rhs.shape.kind != .data) return .{ .unsupported_value = "composed-vector-icmp-operand" };
    const rhs_reg = vectorValueReg(selector, icmp.rhs);
    const dst = resultXmmReg(selector, result_name, icmp.lhs, rhs_reg) orelse return .{ .no_spill_envelope = "composed-vector-icmp-dst" };
    if (try materializeVectorValue(selector, icmp.lhs, lhs, dst, rhs_reg)) |diagnostic| return diagnostic;
    const src = rhs_reg orelse blk: {
        const scratch = scratchXmmReg(selector, dst, null);
        if (try materializeVectorValue(selector, icmp.rhs, rhs, scratch, dst)) |diagnostic| return diagnostic;
        break :blk scratch;
    };
    const bias = scratchXmmRegAvoidingTwo(selector, dst, src);
    try materializeI32Splat(selector, 0x8000_0000, bias);
    try selector_state.clobberXmmReg(selector, dst);
    try selector_state.clobberXmmReg(selector, src);
    try selector.machine.instructions.appendSlice(selector.allocator, &.{
        .{ .pxor_xmm = .{ .dst = dst, .src = bias } },
        .{ .pxor_xmm = .{ .dst = src, .src = bias } },
        .{ .pcmpgtd_xmm = .{ .dst = dst, .src = src } },
    });
    try bindVectorResult(selector, result_name, dst, VectorShape.mask32x2(lhs.shape.defined_lanes & rhs.shape.defined_lanes));
    return null;
}

pub fn lowerFcmp(selector: *ComposedBlockSelector, result: ?[]const u8, fcmp: ir.FcmpInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-vector-fcmp-result" };
    const shape = shapeForType(fcmp.operand_ty, 0) orelse return .{ .no_emitter = "composed-vector-fcmp-form" };
    if (fcmp.predicate != .oeq or (shape.lane_type != .float and shape.lane_type != .double)) {
        return .{ .no_emitter = "composed-vector-fcmp-form" };
    }
    const lhs = describeVectorValue(selector, fcmp.lhs, fcmp.operand_ty) orelse return .{ .unsupported_value = "composed-vector-fcmp-lhs" };
    const rhs = describeVectorValue(selector, fcmp.rhs, fcmp.operand_ty) orelse return .{ .unsupported_value = "composed-vector-fcmp-rhs" };
    const rhs_reg = vectorValueReg(selector, fcmp.rhs);
    const dst = resultXmmReg(selector, result_name, fcmp.lhs, rhs_reg) orelse return .{ .no_spill_envelope = "composed-vector-fcmp-dst" };
    if (try materializeVectorValue(selector, fcmp.lhs, lhs, dst, rhs_reg)) |diagnostic| return diagnostic;
    const src = rhs_reg orelse blk: {
        const scratch = scratchXmmReg(selector, dst, null);
        if (try materializeVectorValue(selector, fcmp.rhs, rhs, scratch, dst)) |diagnostic| return diagnostic;
        break :blk scratch;
    };
    try selector_state.clobberXmmReg(selector, dst);
    try selector.machine.instructions.append(selector.allocator, switch (shape.lane_type) {
        .float => .{ .cmpeqps_xmm = .{ .dst = dst, .src = src } },
        .double => .{ .cmpeqpd_xmm = .{ .dst = dst, .src = src } },
        .integer => unreachable,
    });
    const defined_lanes = lhs.shape.defined_lanes & rhs.shape.defined_lanes;
    try bindVectorResult(selector, result_name, dst, if (shape.lane_bits == 32)
        VectorShape.mask32x2(defined_lanes)
    else
        VectorShape.mask64x2(defined_lanes));
    return null;
}

pub fn lowerInsertElement(selector: *ComposedBlockSelector, result: ?[]const u8, insert: ir.InsertElementInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-vector-missing-result" };
    if (!isPackedFp2(insert.vector_ty) or !insert.value_ty.eql(insert.vector_ty.vector.elem_ty.toType())) {
        return .{ .no_emitter = "composed-vector-insert-type" };
    }
    const lane = constantLane(insert.index) orelse return .{ .no_emitter = "composed-vector-insert-index" };
    const base = describeVectorValue(selector, insert.vector, insert.vector_ty) orelse return .{ .unsupported_value = "composed-vector-insert-base" };
    const scalar_reg = scalarValueReg(selector, insert.value, base.shape.lane_bits);
    const preserve_scalar = insert.vector != .poison and insert.vector != .undef;
    const dst = resultXmmReg(selector, result_name, insert.vector, if (preserve_scalar) scalar_reg else null) orelse return .{ .no_spill_envelope = "composed-vector-insert-dst" };

    if (insert.vector != .poison and insert.vector != .undef) {
        if (try materializeVectorValue(selector, insert.vector, base, dst, scalar_reg)) |diagnostic| return diagnostic;
    }
    const src = scalar_reg orelse blk: {
        const scratch = scratchXmmReg(selector, dst, null);
        if (try selector_fp.materializeFpValue(selector, insert.value, scratch, base.shape.lane_bits)) |diagnostic| return diagnostic;
        break :blk scratch;
    };

    try selector_state.clobberXmmReg(selector, dst);
    if (insert.vector == .poison or insert.vector == .undef) {
        if (dst != src) try selector.machine.instructions.append(selector.allocator, .{ .movapd_xmm = .{ .dst = dst, .src = src } });
        if (lane == 1) try appendUnpackLow(selector, base.shape.lane_type, dst, dst);
    } else if (lane == 0) {
        try selector.machine.instructions.append(selector.allocator, switch (base.shape.lane_type) {
            .float => .{ .movss_xmm = .{ .dst = dst, .src = src } },
            .double => .{ .movsd_xmm = .{ .dst = dst, .src = src } },
            .integer => unreachable,
        });
    } else {
        try appendUnpackLow(selector, base.shape.lane_type, dst, src);
    }

    var result_shape = base.shape;
    result_shape.defined_lanes |= if (lane == 0) 0b01 else 0b10;
    try bindVectorResult(selector, result_name, dst, result_shape);
    return null;
}

pub fn lowerShuffleVector(selector: *ComposedBlockSelector, result: ?[]const u8, shuffle: ir.ShuffleVectorInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-vector-missing-result" };
    if (!isPackedFp2(shuffle.lhs_ty)) return .{ .no_emitter = "composed-vector-shuffle-form" };
    const mask = ir.vector_constant.classifyPacked2ShuffleMask(shuffle) orelse return .{ .no_emitter = "composed-vector-shuffle-form" };
    const source = describeVectorValue(selector, shuffle.lhs, shuffle.lhs_ty) orelse return .{ .unsupported_value = "composed-vector-shuffle-source" };
    const rhs = if (mask == .f64_lane0_lane3)
        describeVectorValue(selector, shuffle.rhs, shuffle.rhs_ty) orelse return .{ .unsupported_value = "composed-vector-shuffle-rhs" }
    else
        null;
    const rhs_reg = if (rhs != null) vectorValueReg(selector, shuffle.rhs) else null;
    const dst = resultXmmReg(selector, result_name, shuffle.lhs, rhs_reg) orelse return .{ .no_spill_envelope = "composed-vector-shuffle-dst" };
    if (try materializeVectorValue(selector, shuffle.lhs, source, dst, rhs_reg)) |diagnostic| return diagnostic;
    const src = if (rhs) |rhs_operand| vectorValueReg(selector, shuffle.rhs) orelse blk: {
        const scratch = scratchXmmReg(selector, dst, null);
        if (try materializeVectorValue(selector, shuffle.rhs, rhs_operand, scratch, dst)) |diagnostic| return diagnostic;
        break :blk scratch;
    } else null;
    try selector_state.clobberXmmReg(selector, dst);
    var result_shape = source.shape;
    switch (mask) {
        .splat_lane0 => {
            try appendUnpackLow(selector, source.shape.lane_type, dst, dst);
            result_shape.defined_lanes = if ((source.shape.defined_lanes & 0b01) != 0) 0b11 else 0;
        },
        .lane1_to_lane0 => {
            try appendHighToLow(selector, source.shape.lane_type, dst);
            result_shape.defined_lanes = if ((source.shape.defined_lanes & 0b10) != 0) 0b01 else 0;
        },
        .f64_lane0_lane3 => {
            try selector.machine.instructions.append(selector.allocator, .{ .shufpd_lane0_lane3_xmm = .{ .dst = dst, .src = src.? } });
            result_shape.defined_lanes = (source.shape.defined_lanes & 0b01) |
                (rhs.?.shape.defined_lanes & 0b10);
        },
    }
    try bindVectorResult(selector, result_name, dst, result_shape);
    return null;
}

pub fn lowerExtractElement(selector: *ComposedBlockSelector, result: ?[]const u8, extract: ir.ExtractElementInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-vector-missing-result" };
    if (isMask2(extract.vector_ty)) return lowerMaskExtractElement(selector, result_name, extract);
    if (!isPackedFp2(extract.vector_ty)) return .{ .no_emitter = "composed-vector-extract-type" };
    const lane = constantLane(extract.index) orelse return .{ .no_emitter = "composed-vector-extract-index" };
    const source = describeVectorValue(selector, extract.vector, extract.vector_ty) orelse return .{ .unsupported_value = "composed-vector-extract-source" };
    const source_reg = vectorValueReg(selector, extract.vector);
    const dst = plannedScalarXmmReg(selector, result_name, source.shape.lane_bits) orelse scratchXmmReg(selector, source_reg orelse .xmm0, source_reg);
    if (try materializeVectorValue(selector, extract.vector, source, dst, source_reg)) |diagnostic| return diagnostic;
    if (lane == 1) switch (source.shape.lane_type) {
        .float => try selector.machine.instructions.append(selector.allocator, .{ .shufps_high_f32_to_low = dst }),
        .double => try selector.machine.instructions.append(selector.allocator, .{ .unpckhpd_xmm = .{ .dst = dst, .src = dst } }),
        .integer => unreachable,
    };
    try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = dst, .bits = source.shape.lane_bits } });
    return null;
}

fn lowerMaskExtractElement(selector: *ComposedBlockSelector, result_name: []const u8, extract: ir.ExtractElementInst) !?Diagnostic {
    const lane = constantLane(extract.index) orelse return .{ .no_emitter = "composed-vector-extract-index" };
    const source = describeVectorValue(selector, extract.vector, extract.vector_ty) orelse return .{ .unsupported_value = "composed-vector-mask-extract-source" };
    if (source.shape.kind != .canonical_mask or source.shape.lane_count != 2 or
        (source.shape.defined_lanes & (@as(u2, 1) << lane)) == 0)
    {
        return .{ .unsupported_value = "composed-vector-mask-extract-shape" };
    }
    const source_reg = vectorValueReg(selector, extract.vector);
    const reg = source_reg orelse scratchXmmReg(selector, .xmm0, null);
    if (source_reg == null) {
        if (try materializeVectorValue(selector, extract.vector, source, reg, null)) |diagnostic| return diagnostic;
    }
    selector_state.clobberAccumulator(selector) catch return .{ .no_spill_envelope = "composed-vector-mask-extract-accumulator" };
    try selector.machine.instructions.append(selector.allocator, if (source.shape.lane_bits == 32)
        .{ .movmskps_xmm_eax = reg }
    else
        .{ .movmskpd_xmm_eax = reg });
    if (lane == 1) try selector.machine.instructions.append(selector.allocator, .{ .shr_eax_imm5 = 1 });
    try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = 1 });
    if (try bindMaskScalarResult(selector, result_name)) |diagnostic| return diagnostic;
    return null;
}

fn bindMaskScalarResult(selector: *ComposedBlockSelector, result_name: []const u8) !?Diagnostic {
    const plan = selector.allocation_plan orelse {
        try selector_state.bindAccumulator(selector, result_name, 1);
        return null;
    };
    const assignment = plan.assignment(result_name) orelse {
        try selector_state.bindAccumulator(selector, result_name, 1);
        return null;
    };
    switch (assignment) {
        .gpr32 => |reg| {
            selector_state.materializeLocIntoLoc(selector, .eax, .{ .scratch32 = reg }) catch return .{ .no_spill_envelope = "composed-vector-mask-extract-result-reg" };
            try selector_state.bindScratch(selector, result_name, reg, 1);
        },
        .spill => try selector_state.bindAccumulator(selector, result_name, 1),
        .gpr64, .gpr128, .fp16, .fp32, .fp64, .vector_xmm, .stack_object, .stack_pointer => return .{ .unsupported_value = "composed-vector-mask-extract-result-plan" },
    }
    return null;
}

fn bindVectorResult(selector: *ComposedBlockSelector, name: []const u8, reg: XmmReg, shape: VectorShape) !void {
    try selector_state.bindResultLoc(selector, name, .{ .xmm = .{
        .reg = reg,
        .bits = 128,
        .shape = .{ .vector = shape },
    } });
}

fn describeVectorValue(selector: *ComposedBlockSelector, value: ir.Value, ty: ir.Type) ?VectorOperand {
    return switch (value) {
        .named => switch (selector_state.resolveValue(selector, value) orelse return null) {
            .xmm => |xmm| .{ .shape = xmm.vectorShape() orelse return null, .constant = null },
            .spill_vector => |vector| .{ .shape = vector.shape, .constant = null },
            else => null,
        },
        .vector, .zero_initializer, .poison, .undef => blk: {
            const constant = parseVectorConstant(value, ty) orelse return null;
            break :blk .{ .shape = constant.shape, .constant = constant };
        },
        else => null,
    };
}

fn materializeVectorValue(
    selector: *ComposedBlockSelector,
    value: ir.Value,
    operand: VectorOperand,
    dst: XmmReg,
    protected: ?XmmReg,
) !?Diagnostic {
    if (operand.constant) |constant| {
        const high = scratchXmmReg(selector, dst, protected);
        try materializeLaneBits(selector, constant.bits[0], dst, constant.shape.lane_bits);
        try materializeLaneBits(selector, constant.bits[1], high, constant.shape.lane_bits);
        try selector_state.clobberXmmReg(selector, dst);
        try appendUnpackLow(selector, constant.shape.lane_type, dst, high);
        return null;
    }
    const source = selector_state.resolveValue(selector, value) orelse return .{ .unsupported_value = "composed-vector-source" };
    selector_state.materializeLocIntoLoc(selector, source, .{ .xmm = .{
        .reg = dst,
        .bits = 128,
        .shape = .{ .vector = operand.shape },
    } }) catch return .{ .unsupported_value = "composed-vector-source" };
    return null;
}

fn vectorValueReg(selector: *ComposedBlockSelector, value: ir.Value) ?XmmReg {
    return switch (selector_state.resolveValue(selector, value) orelse return null) {
        .xmm => |xmm| if (xmm.vectorShape() != null) xmm.reg else null,
        else => null,
    };
}

fn scalarValueReg(selector: *ComposedBlockSelector, value: ir.Value, bits: u16) ?XmmReg {
    return switch (selector_state.resolveValue(selector, value) orelse return null) {
        .xmm => |xmm| if (xmm.shape == .scalar and xmm.bits == bits) xmm.reg else null,
        else => null,
    };
}

fn resultXmmReg(selector: *const ComposedBlockSelector, result_name: []const u8, reusable: ir.Value, avoid: ?XmmReg) ?XmmReg {
    if (plannedVectorXmmReg(selector, result_name)) |reg| {
        if (avoid == null or reg != avoid.?) return reg;
    }
    if (reusable == .named) {
        if (vectorValueReg(@constCast(selector), reusable)) |reg| {
            if (avoid == null or reg != avoid.?) return reg;
        }
    }
    for (xmm_regs) |reg| {
        if (avoid != null and reg == avoid.?) continue;
        if (xmmRegAvailable(selector, reg)) return reg;
    }
    for (xmm_regs) |reg| if (avoid == null or reg != avoid.?) return reg;
    return null;
}

fn plannedVectorXmmReg(selector: *const ComposedBlockSelector, result_name: []const u8) ?XmmReg {
    const plan = selector.allocation_plan orelse return null;
    const assignment = plan.assignment(result_name) orelse return null;
    const reg = switch (assignment) {
        .vector_xmm => |reg| reg,
        else => return null,
    };
    return if (xmmRegAvailable(selector, reg)) reg else null;
}

fn plannedScalarXmmReg(selector: *const ComposedBlockSelector, result_name: []const u8, bits: u16) ?XmmReg {
    const plan = selector.allocation_plan orelse return null;
    const assignment = plan.assignment(result_name) orelse return null;
    const reg = switch (assignment) {
        .fp32 => |reg| if (bits == 32) reg else return null,
        .fp64 => |reg| if (bits == 64) reg else return null,
        else => return null,
    };
    return if (xmmRegAvailable(selector, reg)) reg else null;
}

fn scratchXmmReg(selector: *const ComposedBlockSelector, avoid: XmmReg, second_avoid: ?XmmReg) XmmReg {
    for (xmm_regs) |reg| {
        if (reg == avoid or (second_avoid != null and reg == second_avoid.?)) continue;
        if (xmmRegAvailable(selector, reg)) return reg;
    }
    for (xmm_regs) |reg| {
        if (reg != avoid and (second_avoid == null or reg != second_avoid.?)) return reg;
    }
    unreachable;
}

fn xmmRegAvailable(selector: *const ComposedBlockSelector, reg: XmmReg) bool {
    var it = selector.values.iterator();
    while (it.next()) |entry| switch (entry.value_ptr.loc) {
        .xmm => |xmm| if (xmm.reg == reg and selector_state.valueMustSurviveClobber(selector, entry.key_ptr.*)) return false,
        else => {},
    };
    return true;
}

fn constantLane(value: ir.Value) ?u1 {
    return switch (value) {
        .int => |lane| if (lane == 0 or lane == 1) @intCast(lane) else null,
        else => null,
    };
}

fn parseVectorConstant(value: ir.Value, ty: ir.Type) ?VectorConstant {
    if (!isPackedFp2(ty) and !isPackedI32x2(ty)) return null;
    const parsed = ir.vector_constant.parseFixed(2, value, ty.vector) orelse return null;
    const shape = shapeForType(ty, definedLaneMask(parsed.lanes)) orelse return null;
    var bits: [2]u64 = undefined;
    for (parsed.lanes, 0..) |lane, index| {
        bits[index] = if (!lane.isDefined()) 0 else switch (lane) {
            .zero_initializer => 0,
            .fp => |text| switch (shape.lane_type) {
                .float => x86_64_match.fp32TextBits(.{ .fp = text }) catch return null,
                .double => x86_64_match.fp64TextBits(.{ .fp = text }) catch return null,
                .integer => return null,
            },
            .int => |int_value| integerLaneBits(int_value, shape.lane_bits) orelse return null,
            else => return null,
        };
    }
    return .{ .bits = bits, .shape = shape };
}

fn definedLaneMask(lanes: [2]ir.vector_constant.Lane) u2 {
    var mask: u2 = 0;
    if (lanes[0].isDefined()) mask |= 0b01;
    if (lanes[1].isDefined()) mask |= 0b10;
    return mask;
}

fn shapeForType(ty: ir.Type, defined_lanes: u2) ?VectorShape {
    if (ty != .vector or ty.vector.len != 2) return null;
    return switch (ty.vector.elem_ty) {
        .float => VectorShape.f32x2(defined_lanes),
        .double => VectorShape.f64x2(defined_lanes),
        .int => |bits| switch (bits) {
            32 => VectorShape.i32x2(defined_lanes),
            64 => VectorShape.i64x2(defined_lanes),
            else => null,
        },
        else => null,
    };
}

fn appendUnpackLow(selector: *ComposedBlockSelector, lane_type: VectorShape.LaneType, dst: XmmReg, src: XmmReg) !void {
    try selector.machine.instructions.append(selector.allocator, switch (lane_type) {
        .float => .{ .unpcklps_xmm = .{ .dst = dst, .src = src } },
        .double => .{ .unpcklpd_xmm = .{ .dst = dst, .src = src } },
        .integer => .{ .unpcklps_xmm = .{ .dst = dst, .src = src } },
    });
}

fn appendHighToLow(selector: *ComposedBlockSelector, lane_type: VectorShape.LaneType, dst: XmmReg) !void {
    try selector.machine.instructions.append(selector.allocator, switch (lane_type) {
        .float => .{ .shufps_high_f32_to_low = dst },
        .double => .{ .unpckhpd_xmm = .{ .dst = dst, .src = dst } },
        .integer => unreachable,
    });
}

fn materializeLaneBits(selector: *ComposedBlockSelector, bits: u64, reg: XmmReg, lane_bits: u16) !void {
    try selector_state.clobberAccumulator(selector);
    try selector_state.clobberXmmReg(selector, reg);
    switch (lane_bits) {
        32 => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm32_xmm = .{ .reg = reg, .bits = @intCast(bits) } }),
        64 => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm64_xmm = .{ .reg = reg, .bits = bits } }),
        else => unreachable,
    }
}

fn isPackedFp2(ty: ir.Type) bool {
    return ty == .vector and ty.vector.len == 2 and
        (ty.vector.elem_ty == .float or ty.vector.elem_ty == .double);
}

fn isPackedI32x2(ty: ir.Type) bool {
    return ty == .vector and ty.vector.len == 2 and ty.vector.elem_ty == .int and ty.vector.elem_ty.int == 32;
}

fn isMask2(ty: ir.Type) bool {
    return ty == .vector and ty.vector.len == 2 and ty.vector.elem_ty == .int and ty.vector.elem_ty.int == 1;
}

fn integerLaneBits(value: i128, bits: u16) ?u64 {
    return switch (bits) {
        32 => if (value >= std.math.minInt(i32) and value <= std.math.maxInt(u32))
            @intCast(if (value < 0) value + (@as(i128, 1) << 32) else value)
        else
            null,
        else => null,
    };
}

fn materializeI32Splat(selector: *ComposedBlockSelector, bits: u32, reg: XmmReg) !void {
    try materializeLaneBits(selector, bits, reg, 32);
    try selector.machine.instructions.append(selector.allocator, .{ .unpcklps_xmm = .{ .dst = reg, .src = reg } });
}

fn scratchXmmRegAvoidingTwo(selector: *const ComposedBlockSelector, first: XmmReg, second: XmmReg) XmmReg {
    for (xmm_regs) |reg| {
        if (reg == first or reg == second) continue;
        if (xmmRegAvailable(selector, reg)) return reg;
    }
    for (xmm_regs) |reg| if (reg != first and reg != second) return reg;
    unreachable;
}
