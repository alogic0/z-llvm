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
    if (!isPackedFp(binary.ty)) return .{ .no_emitter = "composed-vector-binary-type" };
    if (binary.op != .fadd and binary.op != .fsub and binary.op != .fmul) return .{ .no_emitter = "composed-vector-binary-op" };

    const lhs = describeVectorValue(selector, binary.lhs, binary.ty) orelse return .{ .unsupported_value = "composed-vector-binary-lhs" };
    const rhs = describeVectorValue(selector, binary.rhs, binary.ty) orelse return .{ .unsupported_value = "composed-vector-binary-rhs" };
    const rhs_reg = vectorValueReg(selector, binary.rhs);
    const dst = try resultXmmReg(selector, result_name, binary.lhs, rhs_reg) orelse return .{ .no_spill_envelope = "composed-vector-binary-dst" };
    if (try materializeVectorValue(selector, binary.lhs, lhs, dst, rhs_reg)) |diagnostic| return diagnostic;
    const src = vectorValueReg(selector, binary.rhs) orelse blk: {
        const scratch = try scratchXmmReg(selector, dst, null);
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

pub fn lowerSelect(selector: *ComposedBlockSelector, result: ?[]const u8, select: ir.SelectInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-vector-select-result" };
    const f32x2: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .float } };
    const f64x2: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .double } };
    const lane_type: VectorShape.LaneType = if (select.ty.eql(f32x2))
        .float
    else if (select.ty.eql(f64x2))
        .double
    else
        return .{ .no_emitter = "composed-vector-select-form" };
    const mask_ty: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .{ .int = 1 } } };
    if (!select.cond_ty.eql(mask_ty)) return .{ .no_emitter = "composed-vector-select-form" };
    const expected_shape = if (lane_type == .float) VectorShape.f32x2(0b11) else VectorShape.f64x2(0b11);
    const expected_mask = if (lane_type == .float) VectorShape.mask32x2(0b11) else VectorShape.mask64x2(0b11);

    const condition = describeVectorValue(selector, select.cond, mask_ty) orelse return .{ .unsupported_value = "composed-vector-select-cond" };
    const true_value = describeVectorValue(selector, select.true_value, select.ty) orelse return .{ .unsupported_value = "composed-vector-select-true" };
    const false_value = describeVectorValue(selector, select.false_value, select.ty) orelse return .{ .unsupported_value = "composed-vector-select-false" };
    if (!condition.shape.eql(expected_mask)) return .{ .unsupported_value = "composed-vector-select-cond" };
    if (!true_value.shape.eql(expected_shape)) return .{ .unsupported_value = "composed-vector-select-true" };
    if (!false_value.shape.eql(expected_shape)) return .{ .unsupported_value = "composed-vector-select-false" };

    const false_initial = vectorValueReg(selector, select.false_value);
    const condition_initial = vectorValueReg(selector, select.cond);
    const dst = try resultXmmRegAvoidingTwo(selector, result_name, select.true_value, false_initial, condition_initial) orelse
        return .{ .no_spill_envelope = "composed-vector-select-dst" };
    if (try materializeVectorValue(selector, select.true_value, true_value, dst, false_initial)) |_| return .{ .unsupported_value = "composed-vector-select-true-materialize" };
    const false_reg = vectorValueReg(selector, select.false_value) orelse blk: {
        const scratch = if (condition_initial) |condition_reg|
            try scratchXmmRegAvoidingTwo(selector, dst, condition_reg)
        else
            try scratchXmmReg(selector, dst, null);
        if (try materializeVectorValueAvoidingTwo(selector, select.false_value, false_value, scratch, dst, condition_initial)) |_| return .{ .unsupported_value = "composed-vector-select-false-materialize" };
        break :blk scratch;
    };
    const condition_reg = vectorValueReg(selector, select.cond) orelse blk: {
        const scratch = try scratchXmmReg(selector, dst, false_reg);
        if (try materializeVectorValue(selector, select.cond, condition, scratch, dst)) |_| return .{ .unsupported_value = "composed-vector-select-cond-materialize" };
        break :blk scratch;
    };

    try selector_state.clobberXmmReg(selector, dst);
    try selector.machine.instructions.appendSlice(selector.allocator, &.{
        .{ .pxor_xmm = .{ .dst = dst, .src = false_reg } },
        .{ .andps_xmm = .{ .dst = dst, .src = condition_reg } },
        .{ .pxor_xmm = .{ .dst = dst, .src = false_reg } },
    });
    try bindVectorResult(selector, result_name, dst, expected_shape);
    return null;
}

pub fn lowerCopySignV2F32(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    return lowerCopySign(selector, result, call, .float);
}

pub fn lowerCopySignV2F64(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    return lowerCopySign(selector, result, call, .double);
}

fn lowerCopySign(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst, lane_type: VectorShape.LaneType) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-vector-copysign-result" };
    const ty: ir.Type = switch (lane_type) {
        .float => .{ .vector = .{ .len = 2, .elem_ty = .float } },
        .double => .{ .vector = .{ .len = 2, .elem_ty = .double } },
        .integer => unreachable,
    };
    if (!call.ret_ty.eql(ty) or call.args.items.len != 2 or
        !call.args.items[0].ty.eql(ty) or !call.args.items[1].ty.eql(ty) or
        call.inline_asm != null or call.callee_value != null or call.callee_function_ty != null or
        call.calling_conv != null or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null)
    {
        return .{ .no_emitter = "composed-vector-copysign-form" };
    }
    if (call.tail_kind) |tail_kind| {
        if (!std.mem.eql(u8, tail_kind, "tail") and !std.mem.eql(u8, tail_kind, "notail")) {
            return .{ .no_emitter = "composed-vector-copysign-tail-kind" };
        }
    }

    const magnitude = describeVectorValue(selector, call.args.items[0].value, ty) orelse return .{ .unsupported_value = "composed-vector-copysign-magnitude" };
    const sign = describeVectorValue(selector, call.args.items[1].value, ty) orelse return .{ .unsupported_value = "composed-vector-copysign-sign" };
    const expected_shape = if (lane_type == .float) VectorShape.f32x2(0b11) else VectorShape.f64x2(0b11);
    if (!magnitude.shape.eql(expected_shape)) return .{ .unsupported_value = "composed-vector-copysign-magnitude" };
    if (!sign.shape.eql(expected_shape)) return .{ .unsupported_value = "composed-vector-copysign-sign" };

    const sign_initial = vectorValueReg(selector, call.args.items[1].value);
    const dst = try resultXmmReg(selector, result_name, call.args.items[0].value, sign_initial) orelse
        return .{ .no_spill_envelope = "composed-vector-copysign-dst" };
    if (try materializeVectorValue(selector, call.args.items[0].value, magnitude, dst, sign_initial)) |_| return .{ .unsupported_value = "composed-vector-copysign-magnitude-materialize" };
    const sign_reg = vectorValueReg(selector, call.args.items[1].value) orelse blk: {
        const scratch = try scratchXmmReg(selector, dst, null);
        if (try materializeVectorValue(selector, call.args.items[1].value, sign, scratch, dst)) |_| return .{ .unsupported_value = "composed-vector-copysign-sign-materialize" };
        break :blk scratch;
    };
    const mask = try scratchXmmReg(selector, dst, sign_reg);
    try materializeLaneSplat(selector, if (lane_type == .float) 0x8000_0000 else 0x8000_0000_0000_0000, mask, expected_shape.lane_bits);
    try selector_state.clobberXmmReg(selector, sign_reg);
    try selector.machine.instructions.appendSlice(selector.allocator, &.{
        .{ .pxor_xmm = .{ .dst = sign_reg, .src = dst } },
        .{ .andps_xmm = .{ .dst = sign_reg, .src = mask } },
    });
    try selector_state.clobberXmmReg(selector, dst);
    try selector.machine.instructions.append(selector.allocator, .{ .pxor_xmm = .{ .dst = dst, .src = sign_reg } });
    try bindVectorResult(selector, result_name, dst, expected_shape);
    return null;
}

pub fn lowerFabsV2F32(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    return lowerFabs(selector, result, call, .float, 2);
}

pub fn lowerFabsV4F32(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    return lowerFabs(selector, result, call, .float, 4);
}

pub fn lowerFabsV2F64(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    return lowerFabs(selector, result, call, .double, 2);
}

fn lowerFabs(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst, comptime lane_type: VectorShape.LaneType, comptime lane_count: u32) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-vector-fabs-result" };
    const ty: ir.Type = .{ .vector = .{ .len = lane_count, .elem_ty = if (lane_type == .float) .float else .double } };
    if (!call.ret_ty.eql(ty) or call.args.items.len != 1 or !call.args.items[0].ty.eql(ty) or call.inline_asm != null or call.callee_value != null) {
        return .{ .no_emitter = "composed-vector-fabs-form" };
    }
    const value = call.args.items[0].value;
    const operand = describeVectorValue(selector, value, ty) orelse return .{ .unsupported_value = "composed-vector-fabs-source" };
    if (operand.shape.kind != .data or operand.shape.lane_type != lane_type) return .{ .unsupported_value = "composed-vector-fabs-source" };
    const source_reg = vectorValueReg(selector, value);
    const dst = try resultXmmReg(selector, result_name, value, null) orelse return .{ .no_spill_envelope = "composed-vector-fabs-dst" };
    if (try materializeVectorValue(selector, value, operand, dst, source_reg)) |diagnostic| return diagnostic;
    const mask = try scratchXmmReg(selector, dst, null);
    try materializeLaneSplat(selector, if (lane_type == .float) 0x7fff_ffff else 0x7fff_ffff_ffff_ffff, mask, operand.shape.lane_bits);
    try selector_state.clobberXmmReg(selector, dst);
    try selector.machine.instructions.append(selector.allocator, .{ .andps_xmm = .{ .dst = dst, .src = mask } });
    try bindVectorResult(selector, result_name, dst, operand.shape);
    return null;
}

pub fn lowerBitcast(selector: *ComposedBlockSelector, result: ?[]const u8, cast: ir.CastInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-vector-bitcast-result" };
    if (cast.op == .bitcast and isMask4(cast.from_ty) and cast.to_ty.eql(.{ .int = 4 })) {
        return lowerMask4ToI4(selector, result_name, cast);
    }
    if (cast.op != .bitcast or !isPackedFp2(cast.from_ty)) return .{ .no_emitter = "composed-vector-bitcast-form" };
    const result_shape = shapeForType(cast.to_ty, 0) orelse return .{ .no_emitter = "composed-vector-bitcast-form" };
    if (result_shape.lane_type != .integer or result_shape.lane_bits != shapeForType(cast.from_ty, 0).?.lane_bits) {
        return .{ .no_emitter = "composed-vector-bitcast-form" };
    }
    const operand = describeVectorValue(selector, cast.value, cast.from_ty) orelse return .{ .unsupported_value = "composed-vector-bitcast-source" };
    if (operand.shape.kind != .data) return .{ .unsupported_value = "composed-vector-bitcast-source" };
    const source_reg = vectorValueReg(selector, cast.value);
    const dst = try resultXmmReg(selector, result_name, cast.value, null) orelse return .{ .no_spill_envelope = "composed-vector-bitcast-dst" };
    if (try materializeVectorValue(selector, cast.value, operand, dst, source_reg)) |diagnostic| return diagnostic;
    var retagged = result_shape;
    retagged.defined_lanes = operand.shape.defined_lanes;
    try bindVectorResult(selector, result_name, dst, retagged);
    return null;
}

fn lowerMask4ToI4(selector: *ComposedBlockSelector, result_name: []const u8, cast: ir.CastInst) !?Diagnostic {
    const operand = describeVectorValue(selector, cast.value, cast.from_ty) orelse return .{ .unsupported_value = "composed-vector-bitcast-source" };
    if (!operand.shape.eql(VectorShape.mask32x4(0b1111))) return .{ .unsupported_value = "composed-vector-bitcast-source" };
    const source_reg = vectorValueReg(selector, cast.value);
    const reg = source_reg orelse try scratchXmmReg(selector, .xmm0, null);
    if (source_reg == null) {
        if (try materializeVectorValue(selector, cast.value, operand, reg, null)) |diagnostic| return diagnostic;
    }
    selector_state.clobberAccumulator(selector) catch return .{ .no_spill_envelope = "composed-vector-bitcast-accumulator" };
    try selector.machine.instructions.appendSlice(selector.allocator, &.{
        .{ .movmskps_xmm_eax = reg },
        .{ .and_eax_imm32 = 0xf },
    });
    return bindMaskScalarResult(selector, result_name, 4);
}

pub fn lowerIcmp(selector: *ComposedBlockSelector, result: ?[]const u8, icmp: ir.IcmpInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-vector-icmp-result" };
    const shape = shapeForType(icmp.operand_ty, 0) orelse return .{ .no_emitter = "composed-vector-icmp-form" };
    if (!icmp.samesign) return .{ .no_emitter = "composed-vector-icmp-samesign" };
    if (icmp.predicate != .ugt and icmp.predicate != .ult) return .{ .no_emitter = "composed-vector-icmp-predicate" };
    if (shape.lane_type != .integer or shape.lane_bits != 32) return .{ .no_emitter = "composed-vector-icmp-shape" };
    const lhs_value = if (icmp.predicate == .ugt) icmp.lhs else icmp.rhs;
    const rhs_value = if (icmp.predicate == .ugt) icmp.rhs else icmp.lhs;
    const lhs = describeVectorValue(selector, lhs_value, icmp.operand_ty) orelse return .{ .unsupported_value = "composed-vector-icmp-lhs" };
    const rhs = describeVectorValue(selector, rhs_value, icmp.operand_ty) orelse return .{ .unsupported_value = "composed-vector-icmp-rhs" };
    if (lhs.shape.kind != .data or rhs.shape.kind != .data) return .{ .unsupported_value = "composed-vector-icmp-operand" };
    const rhs_reg = vectorValueReg(selector, rhs_value);
    const dst = try resultXmmReg(selector, result_name, lhs_value, rhs_reg) orelse return .{ .no_spill_envelope = "composed-vector-icmp-dst" };
    if (try materializeVectorValue(selector, lhs_value, lhs, dst, rhs_reg)) |diagnostic| return diagnostic;
    const src = rhs_reg orelse blk: {
        const scratch = try scratchXmmReg(selector, dst, null);
        if (try materializeVectorValue(selector, rhs_value, rhs, scratch, dst)) |diagnostic| return diagnostic;
        break :blk scratch;
    };
    const bias = try scratchXmmRegAvoidingTwo(selector, dst, src);
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
    const dst = try resultXmmReg(selector, result_name, fcmp.lhs, rhs_reg) orelse return .{ .no_spill_envelope = "composed-vector-fcmp-dst" };
    if (try materializeVectorValue(selector, fcmp.lhs, lhs, dst, rhs_reg)) |diagnostic| return diagnostic;
    const src = rhs_reg orelse blk: {
        const scratch = try scratchXmmReg(selector, dst, null);
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
    try bindVectorResult(selector, result_name, dst, if (shape.lane_count == 4)
        VectorShape.mask32x4(defined_lanes)
    else if (shape.lane_bits == 32)
        VectorShape.mask32x2(defined_lanes)
    else
        VectorShape.mask64x2(defined_lanes));
    return null;
}

pub fn lowerInsertElement(selector: *ComposedBlockSelector, result: ?[]const u8, insert: ir.InsertElementInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-vector-missing-result" };
    if (!isPackedFp(insert.vector_ty) or !insert.value_ty.eql(insert.vector_ty.vector.elem_ty.toType())) {
        return .{ .no_emitter = "composed-vector-insert-type" };
    }
    const lane = constantLane(insert.index) orelse return .{ .no_emitter = "composed-vector-insert-index" };
    const base = describeVectorValue(selector, insert.vector, insert.vector_ty) orelse return .{ .unsupported_value = "composed-vector-insert-base" };
    const scalar_reg = scalarValueReg(selector, insert.value, base.shape.lane_bits);
    const preserve_scalar = insert.vector != .poison and insert.vector != .undef;
    const dst = try resultXmmReg(selector, result_name, insert.vector, if (preserve_scalar) scalar_reg else null) orelse return .{ .no_spill_envelope = "composed-vector-insert-dst" };

    if (insert.vector != .poison and insert.vector != .undef) {
        if (try materializeVectorValue(selector, insert.vector, base, dst, scalar_reg)) |diagnostic| return diagnostic;
    }
    const src = scalar_reg orelse blk: {
        const scratch = try scratchXmmReg(selector, dst, null);
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
    if (isPackedF32x4(shuffle.lhs_ty)) return lowerF32x4Shuffle(selector, result_name, shuffle);
    if (!isPackedFp2(shuffle.lhs_ty)) return .{ .no_emitter = "composed-vector-shuffle-form" };
    const mask = ir.vector_constant.classifyPacked2ShuffleMask(shuffle) orelse return .{ .no_emitter = "composed-vector-shuffle-form" };
    const source = describeVectorValue(selector, shuffle.lhs, shuffle.lhs_ty) orelse return .{ .unsupported_value = "composed-vector-shuffle-source" };
    const rhs = if (mask == .f64_lane0_lane3)
        describeVectorValue(selector, shuffle.rhs, shuffle.rhs_ty) orelse return .{ .unsupported_value = "composed-vector-shuffle-rhs" }
    else
        null;
    const rhs_reg = if (rhs != null) vectorValueReg(selector, shuffle.rhs) else null;
    const dst = try resultXmmReg(selector, result_name, shuffle.lhs, rhs_reg) orelse return .{ .no_spill_envelope = "composed-vector-shuffle-dst" };
    if (try materializeVectorValue(selector, shuffle.lhs, source, dst, rhs_reg)) |diagnostic| return diagnostic;
    const src = if (rhs) |rhs_operand| vectorValueReg(selector, shuffle.rhs) orelse blk: {
        const scratch = try scratchXmmReg(selector, dst, null);
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
        .f64_swap_lanes => {
            try selector.machine.instructions.append(selector.allocator, .{ .shufpd_xmm = .{ .dst = dst, .src = dst, .imm = 1 } });
            result_shape.defined_lanes = ((source.shape.defined_lanes & 0b10) >> 1) |
                ((source.shape.defined_lanes & 0b01) << 1);
        },
        .f64_splat_lane1 => {
            try selector.machine.instructions.append(selector.allocator, .{ .shufpd_xmm = .{ .dst = dst, .src = dst, .imm = 3 } });
            result_shape.defined_lanes = if ((source.shape.defined_lanes & 0b10) != 0) 0b11 else 0;
        },
        .f64_lane0_lane3 => {
            try selector.machine.instructions.append(selector.allocator, .{ .shufpd_xmm = .{ .dst = dst, .src = src.?, .imm = 2 } });
            result_shape.defined_lanes = (source.shape.defined_lanes & 0b01) |
                (rhs.?.shape.defined_lanes & 0b10);
        },
    }
    try bindVectorResult(selector, result_name, dst, result_shape);
    return null;
}

fn lowerF32x4Shuffle(selector: *ComposedBlockSelector, result_name: []const u8, shuffle: ir.ShuffleVectorInst) !?Diagnostic {
    const mask = ir.vector_constant.classifyPackedF32x4ShuffleMask(shuffle) orelse return .{ .no_emitter = "composed-vector-shuffle-form" };
    const source = describeVectorValue(selector, shuffle.lhs, shuffle.lhs_ty) orelse return .{ .unsupported_value = "composed-vector-shuffle-source" };
    const dst = try resultXmmReg(selector, result_name, shuffle.lhs, null) orelse return .{ .no_spill_envelope = "composed-vector-shuffle-dst" };
    if (try materializeVectorValue(selector, shuffle.lhs, source, dst, null)) |diagnostic| return diagnostic;
    try selector_state.clobberXmmReg(selector, dst);
    const immediate: u8 = switch (mask) {
        .pair_0110 => 0x14,
        .pair_0101 => 0x44,
        .lane1_to_lane0 => 0x01,
        .lane3_to_lane2 => 0x30,
    };
    try selector.machine.instructions.append(selector.allocator, .{ .shufps_xmm = .{ .dst = dst, .src = dst, .imm = immediate } });
    var result_shape = VectorShape.f32x4(0);
    result_shape.defined_lanes = switch (mask) {
        .pair_0110 => if ((source.shape.defined_lanes & 0b0011) == 0b0011) 0b1111 else 0,
        .pair_0101 => if ((source.shape.defined_lanes & 0b0011) == 0b0011) 0b1111 else 0,
        .lane1_to_lane0 => if ((source.shape.defined_lanes & 0b0010) != 0) 0b0001 else 0,
        .lane3_to_lane2 => if ((source.shape.defined_lanes & 0b1000) != 0) 0b0100 else 0,
    };
    try bindVectorResult(selector, result_name, dst, result_shape);
    return null;
}

pub fn lowerExtractElement(selector: *ComposedBlockSelector, result: ?[]const u8, extract: ir.ExtractElementInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-vector-missing-result" };
    if (isMask2(extract.vector_ty)) return lowerMaskExtractElement(selector, result_name, extract);
    if (extract.vector_ty.eql(.{ .vector = .{ .len = 2, .elem_ty = .{ .int = 64 } } })) {
        return lowerI64x2ExtractElement(selector, result_name, extract);
    }
    if (!isPackedFp(extract.vector_ty)) return .{ .no_emitter = "composed-vector-extract-type" };
    const lane = constantExtractLane(extract.index, extract.vector_ty) orelse return .{ .no_emitter = "composed-vector-extract-index" };
    const source = describeVectorValue(selector, extract.vector, extract.vector_ty) orelse return .{ .unsupported_value = "composed-vector-extract-source" };
    const source_reg = vectorValueReg(selector, extract.vector);
    const dst = try plannedScalarXmmReg(selector, result_name, source.shape.lane_bits) orelse try scratchXmmReg(selector, source_reg orelse .xmm0, source_reg);
    if (try materializeVectorValue(selector, extract.vector, source, dst, source_reg)) |diagnostic| return diagnostic;
    if (lane == 2) {
        try selector.machine.instructions.append(selector.allocator, .{ .shufps_xmm = .{ .dst = dst, .src = dst, .imm = 0xaa } });
    } else if (lane == 1) switch (source.shape.lane_type) {
        .float => try selector.machine.instructions.append(selector.allocator, .{ .shufps_high_f32_to_low = dst }),
        .double => try selector.machine.instructions.append(selector.allocator, .{ .unpckhpd_xmm = .{ .dst = dst, .src = dst } }),
        .integer => unreachable,
    };
    try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = dst, .bits = source.shape.lane_bits } });
    return null;
}

fn lowerI64x2ExtractElement(selector: *ComposedBlockSelector, result_name: []const u8, extract: ir.ExtractElementInst) !?Diagnostic {
    const lane = constantLane(extract.index) orelse return .{ .no_emitter = "composed-vector-extract-index" };
    const source = describeVectorValue(selector, extract.vector, extract.vector_ty) orelse return .{ .unsupported_value = "composed-vector-extract-source" };
    if (!source.shape.eql(VectorShape.i64x2(0b11))) return .{ .unsupported_value = "composed-vector-extract-shape" };

    const source_reg = vectorValueReg(selector, extract.vector);
    const reg = if (lane == 0 and source_reg != null) source_reg.? else blk: {
        const scratch = try scratchXmmReg(selector, source_reg orelse .xmm0, source_reg);
        if (try materializeVectorValue(selector, extract.vector, source, scratch, source_reg)) |diagnostic| return diagnostic;
        break :blk scratch;
    };
    if (lane == 1) {
        try selector_state.clobberXmmReg(selector, reg);
        try selector.machine.instructions.append(selector.allocator, .{ .unpckhpd_xmm = .{ .dst = reg, .src = reg } });
    }
    selector_state.clobberAccumulator(selector) catch return .{ .no_spill_envelope = "composed-vector-extract-accumulator" };
    try selector.machine.instructions.append(selector.allocator, .{ .movq_xmm_rax = reg });
    try selector_state.bindRax(selector, result_name);
    return null;
}

fn lowerMaskExtractElement(selector: *ComposedBlockSelector, result_name: []const u8, extract: ir.ExtractElementInst) !?Diagnostic {
    const lane = constantLane(extract.index) orelse return .{ .no_emitter = "composed-vector-extract-index" };
    const source = describeVectorValue(selector, extract.vector, extract.vector_ty) orelse return .{ .unsupported_value = "composed-vector-mask-extract-source" };
    if (source.shape.kind != .canonical_mask or source.shape.lane_count != 2 or
        (source.shape.defined_lanes & (@as(u4, 1) << lane)) == 0)
    {
        return .{ .unsupported_value = "composed-vector-mask-extract-shape" };
    }
    const source_reg = vectorValueReg(selector, extract.vector);
    const reg = source_reg orelse try scratchXmmReg(selector, .xmm0, null);
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
    if (try bindMaskScalarResult(selector, result_name, 1)) |diagnostic| return diagnostic;
    return null;
}

fn bindMaskScalarResult(selector: *ComposedBlockSelector, result_name: []const u8, bits: u16) !?Diagnostic {
    const plan = selector.allocation_plan orelse {
        try selector_state.bindAccumulator(selector, result_name, bits);
        return null;
    };
    const assignment = plan.assignment(result_name) orelse {
        try selector_state.bindAccumulator(selector, result_name, bits);
        return null;
    };
    switch (assignment) {
        .gpr32 => |reg| {
            selector_state.materializeLocIntoLoc(selector, .eax, .{ .scratch32 = reg }) catch return .{ .no_spill_envelope = "composed-vector-mask-extract-result-reg" };
            try selector_state.bindScratch(selector, result_name, reg, bits);
        },
        .spill => try selector_state.bindAccumulator(selector, result_name, bits),
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
    return materializeVectorValueAvoidingTwo(selector, value, operand, dst, protected, null);
}

fn materializeVectorValueAvoidingTwo(
    selector: *ComposedBlockSelector,
    value: ir.Value,
    operand: VectorOperand,
    dst: XmmReg,
    protected: ?XmmReg,
    second_protected: ?XmmReg,
) !?Diagnostic {
    if (operand.constant) |constant| {
        const high = try scratchXmmRegAvoidingThree(selector, dst, protected, second_protected);
        const materialized_bits: u16 = if (constant.shape.lane_count == 4) 64 else constant.shape.lane_bits;
        try materializeLaneBits(selector, constant.bits[0], dst, materialized_bits);
        try materializeLaneBits(selector, constant.bits[1], high, materialized_bits);
        try selector_state.clobberXmmReg(selector, dst);
        if (constant.shape.lane_count == 4) {
            try selector.machine.instructions.append(selector.allocator, .{ .unpcklpd_xmm = .{ .dst = dst, .src = high } });
        } else {
            try appendUnpackLow(selector, constant.shape.lane_type, dst, high);
        }
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

fn resultXmmReg(selector: *const ComposedBlockSelector, result_name: []const u8, reusable: ir.Value, avoid: ?XmmReg) !?XmmReg {
    if (try plannedVectorXmmReg(selector, result_name)) |reg| {
        if (avoid == null or reg != avoid.?) return reg;
    }
    if (reusable == .named) {
        if (vectorValueReg(@constCast(selector), reusable)) |reg| {
            if (avoid == null or reg != avoid.?) return reg;
        }
    }
    for (xmm_regs) |reg| {
        if (avoid != null and reg == avoid.?) continue;
        if (try xmmRegAvailable(selector, reg)) return reg;
    }
    for (xmm_regs) |reg| if (avoid == null or reg != avoid.?) return reg;
    return null;
}

fn resultXmmRegAvoidingTwo(
    selector: *const ComposedBlockSelector,
    result_name: []const u8,
    reusable: ir.Value,
    first_avoid: ?XmmReg,
    second_avoid: ?XmmReg,
) !?XmmReg {
    if (try plannedVectorXmmReg(selector, result_name)) |reg| {
        if ((first_avoid == null or reg != first_avoid.?) and (second_avoid == null or reg != second_avoid.?)) return reg;
    }
    if (reusable == .named) {
        if (vectorValueReg(@constCast(selector), reusable)) |reg| {
            if ((first_avoid == null or reg != first_avoid.?) and (second_avoid == null or reg != second_avoid.?)) return reg;
        }
    }
    for (xmm_regs) |reg| {
        if ((first_avoid != null and reg == first_avoid.?) or (second_avoid != null and reg == second_avoid.?)) continue;
        if (try xmmRegAvailable(selector, reg)) return reg;
    }
    for (xmm_regs) |reg| {
        if ((first_avoid == null or reg != first_avoid.?) and (second_avoid == null or reg != second_avoid.?)) return reg;
    }
    return null;
}

fn plannedVectorXmmReg(selector: *const ComposedBlockSelector, result_name: []const u8) !?XmmReg {
    const plan = selector.allocation_plan orelse return null;
    const assignment = plan.assignment(result_name) orelse return null;
    const reg = switch (assignment) {
        .vector_xmm => |reg| reg,
        else => return null,
    };
    return if (try xmmRegAvailable(selector, reg)) reg else null;
}

fn plannedScalarXmmReg(selector: *const ComposedBlockSelector, result_name: []const u8, bits: u16) !?XmmReg {
    const plan = selector.allocation_plan orelse return null;
    const assignment = plan.assignment(result_name) orelse return null;
    const reg = switch (assignment) {
        .fp32 => |reg| if (bits == 32) reg else return null,
        .fp64 => |reg| if (bits == 64) reg else return null,
        else => return null,
    };
    return if (try xmmRegAvailable(selector, reg)) reg else null;
}

fn scratchXmmReg(selector: *const ComposedBlockSelector, avoid: XmmReg, second_avoid: ?XmmReg) !XmmReg {
    return scratchXmmRegAvoidingThree(selector, avoid, second_avoid, null);
}

fn scratchXmmRegAvoidingThree(selector: *const ComposedBlockSelector, first: XmmReg, second: ?XmmReg, third: ?XmmReg) !XmmReg {
    for (xmm_regs) |reg| {
        if (reg == first or (second != null and reg == second.?) or (third != null and reg == third.?)) continue;
        if (try xmmRegAvailable(selector, reg)) return reg;
    }
    for (xmm_regs) |reg| {
        if (reg != first and (second == null or reg != second.?) and (third == null or reg != third.?)) return reg;
    }
    unreachable;
}

fn xmmRegAvailable(selector: *const ComposedBlockSelector, reg: XmmReg) !bool {
    return selector_state.xmmRegAvailable(selector, reg);
}

fn constantLane(value: ir.Value) ?u1 {
    return switch (value) {
        .int => |lane| if (lane == 0 or lane == 1) @intCast(lane) else null,
        else => null,
    };
}

fn constantExtractLane(value: ir.Value, ty: ir.Type) ?u2 {
    return switch (value) {
        .int => |lane| if ((ty.vector.len == 2 and (lane == 0 or lane == 1)) or
            (ty.vector.len == 4 and (lane == 0 or lane == 2))) @intCast(lane) else null,
        else => null,
    };
}

fn parseVectorConstant(value: ir.Value, ty: ir.Type) ?VectorConstant {
    if (isPackedF32x4(ty)) return parseF32x4Constant(value, ty);
    if (!isPackedFp2(ty) and !isPackedI32x2(ty)) return null;
    const parsed = ir.vector_constant.parseFixed(2, value, ty.vector) orelse return null;
    const shape = shapeForType(ty, definedLaneMask(2, parsed.lanes)) orelse return null;
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

fn parseF32x4Constant(value: ir.Value, ty: ir.Type) ?VectorConstant {
    const parsed = ir.vector_constant.parseFixed(4, value, ty.vector) orelse return null;
    var lane_bits: [4]u32 = undefined;
    for (parsed.lanes, 0..) |lane, index| {
        lane_bits[index] = if (!lane.isDefined()) 0 else switch (lane) {
            .zero_initializer => 0,
            .fp => |text| x86_64_match.fp32TextBits(.{ .fp = text }) catch return null,
            else => return null,
        };
    }
    return .{
        .bits = .{
            @as(u64, lane_bits[0]) | (@as(u64, lane_bits[1]) << 32),
            @as(u64, lane_bits[2]) | (@as(u64, lane_bits[3]) << 32),
        },
        .shape = VectorShape.f32x4(definedLaneMask(4, parsed.lanes)),
    };
}

fn definedLaneMask(comptime lane_count: usize, lanes: [lane_count]ir.vector_constant.Lane) u4 {
    var mask: u4 = 0;
    for (lanes, 0..) |lane, index| {
        if (lane.isDefined()) mask |= @as(u4, 1) << @intCast(index);
    }
    return mask;
}

fn shapeForType(ty: ir.Type, defined_lanes: u4) ?VectorShape {
    if (ty != .vector) return null;
    if (ty.vector.len == 4) return switch (ty.vector.elem_ty) {
        .float => VectorShape.f32x4(defined_lanes),
        .int => |bits| if (bits == 32) VectorShape.i32x4(defined_lanes) else null,
        else => null,
    };
    if (ty.vector.len != 2) return null;
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

fn isPackedF32x4(ty: ir.Type) bool {
    return ty == .vector and ty.vector.len == 4 and ty.vector.elem_ty == .float;
}

fn isPackedFp(ty: ir.Type) bool {
    return isPackedFp2(ty) or isPackedF32x4(ty);
}

fn isPackedI32x2(ty: ir.Type) bool {
    return ty == .vector and ty.vector.len == 2 and ty.vector.elem_ty == .int and ty.vector.elem_ty.int == 32;
}

fn isMask2(ty: ir.Type) bool {
    return ty == .vector and ty.vector.len == 2 and ty.vector.elem_ty == .int and ty.vector.elem_ty.int == 1;
}

fn isMask4(ty: ir.Type) bool {
    return ty == .vector and ty.vector.len == 4 and ty.vector.elem_ty == .int and ty.vector.elem_ty.int == 1;
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
    try materializeLaneSplat(selector, bits, reg, 32);
}

fn materializeLaneSplat(selector: *ComposedBlockSelector, bits: u64, reg: XmmReg, lane_bits: u16) !void {
    try materializeLaneBits(selector, bits, reg, lane_bits);
    if (lane_bits == 32) {
        try selector.machine.instructions.appendSlice(selector.allocator, &.{
            .{ .unpcklps_xmm = .{ .dst = reg, .src = reg } },
            .{ .unpcklps_xmm = .{ .dst = reg, .src = reg } },
        });
    } else {
        try selector.machine.instructions.append(selector.allocator, .{ .unpcklpd_xmm = .{ .dst = reg, .src = reg } });
    }
}

fn scratchXmmRegAvoidingTwo(selector: *const ComposedBlockSelector, first: XmmReg, second: XmmReg) !XmmReg {
    for (xmm_regs) |reg| {
        if (reg == first or reg == second) continue;
        if (try xmmRegAvailable(selector, reg)) return reg;
    }
    for (xmm_regs) |reg| if (reg != first and reg != second) return reg;
    unreachable;
}
