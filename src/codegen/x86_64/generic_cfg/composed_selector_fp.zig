const std = @import("std");
const ir = @import("../../../ir.zig");
const fp_semantics = @import("../../../analysis/fp_semantics.zig");
const x86_64_match = @import("../match.zig");
const x86_64_types = @import("../types.zig");
const inspection = @import("inspection.zig");
const selector_state = @import("composed_selector_state.zig");
const selector_frame = @import("composed_selector_frame.zig");
const state_data = @import("composed_selector_state_data.zig");
const selector_types = @import("selector_types.zig");

const ComposedBlockSelector = state_data.ComposedBlockSelector;
const Diagnostic = inspection.Diagnostic;
const XmmReg = x86_64_types.XmmReg;
const scalar_xmm_regs = selector_types.selector_allocatable_xmm_regs;

pub fn lowerFpBinary(selector: *ComposedBlockSelector, result: ?[]const u8, binary: ir.BinaryInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (binary.ty == .half) return lowerHalfFadd(selector, result_name, binary);
    const bits = fpBits(binary.ty) orelse return .{ .no_emitter = "composed-block-fp-binary-type" };
    return switch (binary.op) {
        .fadd, .fmul, .fsub, .fdiv => lowerFpRegisterBinary(selector, result_name, binary, bits),
        else => .{ .no_emitter = "composed-block-fp-binary-type" },
    };
}

fn lowerHalfFadd(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
    if (binary.op != .fadd) return .{ .no_emitter = "composed-block-half-binary-op" };
    const lhs_named = binary.lhs == .named;
    const rhs_named = binary.rhs == .named;
    if ((!lhs_named and halfLiteralFloatBits(binary.lhs) == null) or
        (!rhs_named and halfLiteralFloatBits(binary.rhs) == null))
    {
        return .{ .no_emitter = "composed-block-half-fadd-operands" };
    }

    var sum_reg: XmmReg = undefined;
    if (lhs_named and rhs_named) {
        const frames = selector_state.allocatePairSpillSlots(selector, result_name) orelse return .{ .no_spill_envelope = "composed-block-half-fadd-spill" };
        const rhs_source = selector_state.resolveValue(selector, binary.rhs) orelse return .{ .unsupported_value = "composed-block-half-fadd-rhs" };
        selector_state.materializeLocIntoLoc(selector, rhs_source, .{ .spill_fp = .{ .frame_index = frames.lo, .bits = 16 } }) catch return .{ .unsupported_value = "composed-block-half-fadd-rhs" };
        if (try lowerHalfValueToFloatXmm0(selector, binary.lhs)) |diagnostic| return diagnostic;
        try selector.machine.instructions.append(selector.allocator, .{ .spill_xmm32_rsp = .{ .frame_index = frames.hi, .reg = .xmm0 } });
        if (try lowerHalfLocToFloatXmm0(selector, .{ .spill_fp = .{ .frame_index = frames.lo, .bits = 16 } })) |diagnostic| return diagnostic;
        selector_state.materializeLocIntoLoc(selector, .{ .spill_fp = .{ .frame_index = frames.hi, .bits = 32 } }, .{ .xmm = .{ .reg = .xmm1, .bits = 32 } }) catch return .{ .unsupported_value = "composed-block-half-fadd-spill" };
        try selector_state.clobberXmmReg(selector, .xmm1);
        try selector.machine.instructions.append(selector.allocator, .{ .addss_xmm = .{ .dst = .xmm1, .src = .xmm0 } });
        sum_reg = .xmm1;
    } else if (lhs_named or rhs_named) {
        const named_value = if (lhs_named) binary.lhs else binary.rhs;
        const literal_value = if (lhs_named) binary.rhs else binary.lhs;
        if (try lowerHalfValueToFloatXmm0(selector, named_value)) |diagnostic| return diagnostic;
        try selector_state.clobberXmmReg(selector, .xmm1);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm32_xmm = .{ .reg = .xmm1, .bits = halfLiteralFloatBits(literal_value).? } });
        try selector_state.clobberXmmReg(selector, .xmm0);
        try selector.machine.instructions.append(selector.allocator, .{ .addss_xmm = .{ .dst = .xmm0, .src = .xmm1 } });
        sum_reg = .xmm0;
    } else {
        try selector_state.clobberXmmReg(selector, .xmm0);
        try selector_state.clobberXmmReg(selector, .xmm1);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm32_xmm = .{ .reg = .xmm0, .bits = halfLiteralFloatBits(binary.lhs).? } });
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm32_xmm = .{ .reg = .xmm1, .bits = halfLiteralFloatBits(binary.rhs).? } });
        try selector.machine.instructions.append(selector.allocator, .{ .addss_xmm = .{ .dst = .xmm0, .src = .xmm1 } });
        sum_reg = .xmm0;
    }

    if (try selector_state.spillLiveCallerClobbersForCall(selector)) |diagnostic| return diagnostic;
    if (sum_reg != .xmm0) {
        selector_state.materializeLocIntoLoc(selector, .{ .xmm = .{ .reg = sum_reg, .bits = 32 } }, .{ .xmm = .{ .reg = .xmm0, .bits = 32 } }) catch return .{ .unsupported_value = "composed-block-half-fadd-result" };
    }
    const needs_alignment = selector.stack_frame_bytes == 0;
    if (needs_alignment) try selector_frame.appendSubRsp(selector, 8);
    try selector.machine.instructions.append(selector.allocator, .{ .direct_call = .{ .symbol = "__truncsfhf2", .ret_ty = .half } });
    if (needs_alignment) try selector_frame.appendAddRsp(selector, 8);
    try selector_state.bindValueLoc(selector, result_name, .{ .xmm = .{ .reg = .xmm0, .bits = 16 } });
    return null;
}

fn halfLiteralFloatBits(value: ir.Value) ?u32 {
    const text = switch (value) {
        .fp => |text| text,
        else => return null,
    };
    const bits = fp_semantics.halfLiteralBits(text) catch return null;
    const half: f16 = @bitCast(bits);
    return @bitCast(@as(f32, half));
}

fn lowerFpRegisterBinary(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst, bits: u16) !?Diagnostic {
    if (binary.op == .fsub and isScalarFneg(binary.lhs, bits)) {
        return lowerScalarFneg(selector, result_name, binary, bits);
    }
    const dst = fpValueReg(selector, binary.lhs, bits) orelse blk: {
        const rhs_reg = fpValueReg(selector, binary.rhs, bits);
        break :blk firstXmmExcept(rhs_reg);
    };
    if (try materializeFpValue(selector, binary.lhs, dst, bits)) |diagnostic| return diagnostic;
    const src = if (fpValueReg(selector, binary.rhs, bits)) |reg| reg else blk: {
        const scratch = firstXmmExcept(dst);
        if (try materializeFpValue(selector, binary.rhs, scratch, bits)) |diagnostic| return diagnostic;
        break :blk scratch;
    };
    try selector_state.clobberXmmReg(selector, dst);
    switch (binary.op) {
        .fadd => try selector.machine.instructions.append(selector.allocator, if (bits == 32)
            .{ .addss_xmm = .{ .dst = dst, .src = src } }
        else
            .{ .addsd_xmm = .{ .dst = dst, .src = src } }),
        .fmul => try selector.machine.instructions.append(selector.allocator, if (bits == 32)
            .{ .mulss_xmm = .{ .dst = dst, .src = src } }
        else
            .{ .mulsd_xmm = .{ .dst = dst, .src = src } }),
        .fsub => try selector.machine.instructions.append(selector.allocator, if (bits == 32)
            .{ .subss_xmm = .{ .dst = dst, .src = src } }
        else
            .{ .subsd_xmm = .{ .dst = dst, .src = src } }),
        .fdiv => try selector.machine.instructions.append(selector.allocator, if (bits == 32)
            .{ .divss_xmm = .{ .dst = dst, .src = src } }
        else
            .{ .divsd_xmm = .{ .dst = dst, .src = src } }),
        else => unreachable,
    }
    try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = dst, .bits = bits } });
    return null;
}

fn lowerScalarFneg(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst, bits: u16) !?Diagnostic {
    const dst = fpValueReg(selector, binary.rhs, bits) orelse firstXmmExcept(null);
    if (try materializeFpValue(selector, binary.rhs, dst, bits)) |diagnostic| return diagnostic;
    const sign = firstXmmExcept(dst);
    if (try materializeFpValue(selector, binary.lhs, sign, bits)) |diagnostic| return diagnostic;
    try selector_state.clobberXmmReg(selector, dst);
    try selector.machine.instructions.append(selector.allocator, .{ .pxor_xmm = .{ .dst = dst, .src = sign } });
    try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = dst, .bits = bits } });
    return null;
}

fn isScalarFneg(value: ir.Value, bits: u16) bool {
    const sign_bit: u64 = @as(u64, 1) << @intCast(bits - 1);
    const literal_bits: u64 = switch (bits) {
        32 => @as(u64, x86_64_match.fp32TextBits(value) catch return false),
        64 => x86_64_match.fp64TextBits(value) catch return false,
        else => return false,
    };
    return literal_bits == sign_bit;
}

fn fpValueReg(selector: *ComposedBlockSelector, value: ir.Value, bits: u16) ?XmmReg {
    const source = selector_state.resolveValue(selector, value) orelse return null;
    return switch (source) {
        .xmm => |fp| if (fp.bits == bits) fp.reg else null,
        else => null,
    };
}

fn firstXmmExcept(avoid: ?XmmReg) XmmReg {
    for (scalar_xmm_regs) |reg| {
        if (avoid == null or reg != avoid.?) return reg;
    }
    unreachable;
}

fn fpBits(ty: ir.Type) ?u16 {
    return if (ty == .float) 32 else if (ty == .double) 64 else null;
}

pub fn lowerMaxNum(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst, bits: u16) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-maxnum-result" };
    const ty: ir.Type = if (bits == 32) .float else if (bits == 64) .double else unreachable;
    if (!call.ret_ty.eql(ty) or call.args.items.len != 2 or
        !call.args.items[0].ty.eql(ty) or !call.args.items[1].ty.eql(ty) or
        call.inline_asm != null or call.callee_value != null or call.callee_function_ty != null or
        call.calling_conv != null or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null)
    {
        return .{ .no_emitter = "composed-block-maxnum-form" };
    }
    if (call.tail_kind) |tail_kind| {
        if (!std.mem.eql(u8, tail_kind, "tail") and !std.mem.eql(u8, tail_kind, "notail")) {
            return .{ .no_emitter = "composed-block-maxnum-tail-kind" };
        }
    }

    const lhs = fpValueReg(selector, call.args.items[0].value, bits) orelse blk: {
        const rhs_reg = fpValueReg(selector, call.args.items[1].value, bits);
        break :blk firstXmmExcept(rhs_reg);
    };
    if (try materializeFpValue(selector, call.args.items[0].value, lhs, bits)) |diagnostic| return diagnostic;
    const rhs = if (fpValueReg(selector, call.args.items[1].value, bits)) |reg| reg else blk: {
        const scratch = firstXmmExcept(lhs);
        if (try materializeFpValue(selector, call.args.items[1].value, scratch, bits)) |diagnostic| return diagnostic;
        break :blk scratch;
    };
    const dst = firstXmmExceptTwo(lhs, rhs);
    if (try materializeFpValue(selector, call.args.items[1].value, dst, bits)) |diagnostic| return diagnostic;

    const lhs_at_least_rhs = try selector_state.allocateEdgeLabel(selector);
    const choose_lhs = try selector_state.allocateEdgeLabel(selector);
    const end = try selector_state.allocateEdgeLabel(selector);

    try appendScalarCompare(selector, lhs, lhs, bits);
    try selector.machine.instructions.append(selector.allocator, .{ .jp = end });
    try appendScalarCompare(selector, rhs, rhs, bits);
    try selector.machine.instructions.append(selector.allocator, .{ .jp = choose_lhs });
    try appendScalarCompare(selector, lhs, rhs, bits);
    try selector.machine.instructions.append(selector.allocator, .{ .jae = lhs_at_least_rhs });
    try selector.machine.instructions.append(selector.allocator, .{ .jmp = end });

    try selector.machine.instructions.append(selector.allocator, .{ .label = lhs_at_least_rhs });
    try selector.machine.instructions.append(selector.allocator, .{ .jne = choose_lhs });
    try selector_state.clobberXmmReg(selector, dst);
    try selector.machine.instructions.append(selector.allocator, .{ .andps_xmm = .{ .dst = dst, .src = lhs } });
    try selector.machine.instructions.append(selector.allocator, .{ .jmp = end });

    try selector.machine.instructions.append(selector.allocator, .{ .label = choose_lhs });
    if (try materializeFpValue(selector, call.args.items[0].value, dst, bits)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, .{ .label = end });
    try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = dst, .bits = bits } });
    return null;
}

pub fn lowerCopySignF32(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    return lowerCopySign(selector, result, call, 32);
}

pub fn lowerCopySignF64(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    return lowerCopySign(selector, result, call, 64);
}

fn lowerCopySign(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst, comptime bits: u16) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-copysign-result" };
    const ty: ir.Type = if (bits == 32) .float else .double;
    if (!call.ret_ty.eql(ty) or call.args.items.len != 2 or
        !call.args.items[0].ty.eql(ty) or !call.args.items[1].ty.eql(ty) or
        call.inline_asm != null or call.callee_value != null or call.callee_function_ty != null or
        call.calling_conv != null or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null)
    {
        return .{ .no_emitter = "composed-block-copysign-form" };
    }
    if (call.tail_kind) |tail_kind| {
        if (!std.mem.eql(u8, tail_kind, "tail") and !std.mem.eql(u8, tail_kind, "notail")) {
            return .{ .no_emitter = "composed-block-copysign-tail-kind" };
        }
    }

    const lhs = fpValueReg(selector, call.args.items[0].value, bits) orelse blk: {
        const rhs_reg = fpValueReg(selector, call.args.items[1].value, bits);
        break :blk firstXmmExcept(rhs_reg);
    };
    if (try materializeFpValue(selector, call.args.items[0].value, lhs, bits)) |diagnostic| return diagnostic;
    const rhs = fpValueReg(selector, call.args.items[1].value, bits) orelse blk: {
        const scratch = firstXmmExcept(lhs);
        if (try materializeFpValue(selector, call.args.items[1].value, scratch, bits)) |diagnostic| return diagnostic;
        break :blk scratch;
    };
    const dst = firstXmmExceptTwo(lhs, rhs);
    const magnitude = firstXmmExceptThree(lhs, rhs, dst);
    const mask = firstXmmExceptFour(lhs, rhs, dst, magnitude);

    if (try materializeFpValue(selector, call.args.items[1].value, dst, bits)) |diagnostic| return diagnostic;
    if (try materializeFpValue(selector, call.args.items[0].value, magnitude, bits)) |diagnostic| return diagnostic;
    try selector_state.clobberAccumulator(selector);
    try selector_state.clobberXmmReg(selector, mask);
    try selector.machine.instructions.append(selector.allocator, if (bits == 32)
        .{ .mov_imm32_xmm = .{ .reg = mask, .bits = 0x8000_0000 } }
    else
        .{ .mov_imm64_xmm = .{ .reg = mask, .bits = 0x8000_0000_0000_0000 } });
    try selector_state.clobberXmmReg(selector, dst);
    try selector.machine.instructions.appendSlice(selector.allocator, &.{
        .{ .pxor_xmm = .{ .dst = dst, .src = magnitude } },
        .{ .andps_xmm = .{ .dst = dst, .src = mask } },
    });
    try selector_state.clobberXmmReg(selector, magnitude);
    try selector.machine.instructions.append(selector.allocator, .{ .pxor_xmm = .{ .dst = magnitude, .src = dst } });
    try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = magnitude, .bits = bits } });
    return null;
}

fn firstXmmExceptTwo(first: XmmReg, second: XmmReg) XmmReg {
    for (scalar_xmm_regs) |reg| {
        if (reg != first and reg != second) return reg;
    }
    unreachable;
}

fn firstXmmExceptThree(first: XmmReg, second: XmmReg, third: XmmReg) XmmReg {
    for (scalar_xmm_regs) |reg| {
        if (reg != first and reg != second and reg != third) return reg;
    }
    unreachable;
}

fn firstXmmExceptFour(first: XmmReg, second: XmmReg, third: XmmReg, fourth: XmmReg) XmmReg {
    for (scalar_xmm_regs) |reg| {
        if (reg != first and reg != second and reg != third and reg != fourth) return reg;
    }
    unreachable;
}

fn appendScalarCompare(selector: *ComposedBlockSelector, lhs: XmmReg, rhs: XmmReg, bits: u16) !void {
    try selector.machine.instructions.append(selector.allocator, if (bits == 32)
        .{ .ucomiss = .{ .dst = lhs, .src = rhs } }
    else
        .{ .ucomisd = .{ .dst = lhs, .src = rhs } });
}

pub fn materializeFpValue(selector: *ComposedBlockSelector, value: ir.Value, dst: XmmReg, bits: u16) !?Diagnostic {
    switch (value) {
        .named => {
            const source = selector_state.resolveValue(selector, value) orelse return .{ .unsupported_value = "composed-block-fp-source" };
            selector_state.materializeLocIntoLoc(selector, source, .{ .xmm = .{ .reg = dst, .bits = bits } }) catch return .{ .unsupported_value = "composed-block-fp-source" };
        },
        .fp => {
            try selector_state.clobberAccumulator(selector);
            try selector_state.clobberXmmReg(selector, dst);
            switch (bits) {
                16 => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm32_xmm = .{ .reg = dst, .bits = try fp_semantics.halfLiteralBits(value.fp) } }),
                32 => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm32_xmm = .{ .reg = dst, .bits = try x86_64_match.fp32TextBits(value) } }),
                64 => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm64_xmm = .{ .reg = dst, .bits = try x86_64_match.fp64TextBits(value) } }),
                else => return .{ .no_emitter = "composed-block-fp-immediate-width" },
            }
        },
        .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "composed-block-fp-source" },
    }
    return null;
}

pub fn lowerFcmp(selector: *ComposedBlockSelector, result: ?[]const u8, fcmp: ir.FcmpInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (halfOeqZeroSource(fcmp)) |source_value| return lowerHalfOeqZero(selector, result_name, source_value);
    if (fcmp.operand_ty == .half) return lowerHalfFcmp(selector, result_name, fcmp);
    const bits = fpBits(fcmp.operand_ty) orelse return .{ .no_emitter = "composed-block-fcmp-type" };

    if (fcmp.predicate != .false and fcmp.predicate != .true) {
        const lhs = fpValueReg(selector, fcmp.lhs, bits) orelse blk: {
            const rhs_reg = fpValueReg(selector, fcmp.rhs, bits);
            break :blk firstXmmExcept(rhs_reg);
        };
        if (try materializeFpValue(selector, fcmp.lhs, lhs, bits)) |diagnostic| return diagnostic;
        const rhs = if (fpValueReg(selector, fcmp.rhs, bits)) |reg| reg else blk: {
            const scratch = firstXmmExcept(lhs);
            if (try materializeFpValue(selector, fcmp.rhs, scratch, bits)) |diagnostic| return diagnostic;
            break :blk scratch;
        };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, if (bits == 32)
            .{ .ucomiss = .{ .dst = lhs, .src = rhs } }
        else
            .{ .ucomisd = .{ .dst = lhs, .src = rhs } });
    } else {
        try selector_state.clobberAccumulator(selector);
    }
    try selector.machine.instructions.append(selector.allocator, .{ .set_fcmp_eax = fcmp.predicate });
    try selector_state.bindEax(selector, result_name);
    return null;
}

fn halfOeqZeroSource(fcmp: ir.FcmpInst) ?ir.Value {
    if (fcmp.operand_ty != .half or fcmp.predicate != .oeq) return null;
    if (fcmp.lhs == .named and isHalfZeroLiteral(fcmp.rhs)) return fcmp.lhs;
    if (fcmp.rhs == .named and isHalfZeroLiteral(fcmp.lhs)) return fcmp.rhs;
    return null;
}

fn isHalfZeroLiteral(value: ir.Value) bool {
    const text = switch (value) {
        .fp => |text| text,
        else => return false,
    };
    return fp_semantics.isHalfZeroLiteral(text);
}

fn lowerHalfOeqZero(selector: *ComposedBlockSelector, result_name: []const u8, source_value: ir.Value) !?Diagnostic {
    const source = selector_state.resolveValue(selector, source_value) orelse return .{ .unsupported_value = "composed-block-half-zero-source" };
    try selector_state.clobberAccumulator(selector);
    const reg = switch (source) {
        .xmm => |fp| if (fp.bits == 16) fp.reg else return .{ .unsupported_value = "composed-block-half-zero-source" },
        .spill_fp => |fp| blk: {
            if (fp.bits != 16) return .{ .unsupported_value = "composed-block-half-zero-source" };
            selector_state.materializeLocIntoLoc(selector, source, .{ .xmm = .{ .reg = .xmm0, .bits = 16 } }) catch return .{ .unsupported_value = "composed-block-half-zero-source" };
            break :blk .xmm0;
        },
        else => return .{ .unsupported_value = "composed-block-half-zero-source" },
    };
    try selector.machine.instructions.append(selector.allocator, .{ .movd_xmm_eax = reg });
    try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = 0x7fff });
    try selector.machine.instructions.append(selector.allocator, .test_eax_eax);
    try selector.machine.instructions.append(selector.allocator, .sete_eax);
    try selector_state.bindEax(selector, result_name);
    return null;
}

fn lowerHalfFcmp(selector: *ComposedBlockSelector, result_name: []const u8, fcmp: ir.FcmpInst) !?Diagnostic {
    if (fcmp.predicate != .uno and fcmp.predicate != .olt) return .{ .no_emitter = "composed-block-half-fcmp-predicate" };
    const lhs_named = fcmp.lhs == .named;
    const rhs_named = fcmp.rhs == .named;
    if ((!lhs_named and !isHalfZeroLiteral(fcmp.lhs)) or (!rhs_named and !isHalfZeroLiteral(fcmp.rhs)) or (!lhs_named and !rhs_named)) {
        return .{ .no_emitter = "composed-block-half-fcmp-operands" };
    }

    var lhs_reg: XmmReg = undefined;
    var rhs_reg: XmmReg = undefined;
    if (lhs_named and rhs_named) {
        const frames = selector_state.allocatePairSpillSlots(selector, result_name) orelse return .{ .no_spill_envelope = "composed-block-half-fcmp-spill" };
        const rhs_source = selector_state.resolveValue(selector, fcmp.rhs) orelse return .{ .unsupported_value = "composed-block-half-fcmp-rhs" };
        selector_state.materializeLocIntoLoc(selector, rhs_source, .{ .spill_fp = .{ .frame_index = frames.lo, .bits = 16 } }) catch return .{ .unsupported_value = "composed-block-half-fcmp-rhs" };
        if (try lowerHalfValueToFloatXmm0(selector, fcmp.lhs)) |diagnostic| return diagnostic;
        try selector.machine.instructions.append(selector.allocator, .{ .spill_xmm32_rsp = .{ .frame_index = frames.hi, .reg = .xmm0 } });
        if (try lowerHalfLocToFloatXmm0(selector, .{ .spill_fp = .{ .frame_index = frames.lo, .bits = 16 } })) |diagnostic| return diagnostic;
        selector_state.materializeLocIntoLoc(selector, .{ .spill_fp = .{ .frame_index = frames.hi, .bits = 32 } }, .{ .xmm = .{ .reg = .xmm1, .bits = 32 } }) catch return .{ .unsupported_value = "composed-block-half-fcmp-spill" };
        lhs_reg = .xmm1;
        rhs_reg = .xmm0;
    } else {
        const named_value = if (lhs_named) fcmp.lhs else fcmp.rhs;
        if (try lowerHalfValueToFloatXmm0(selector, named_value)) |diagnostic| return diagnostic;
        try selector_state.clobberAccumulator(selector);
        try selector_state.clobberXmmReg(selector, .xmm1);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm32_xmm = .{ .reg = .xmm1, .bits = 0 } });
        lhs_reg = if (lhs_named) .xmm0 else .xmm1;
        rhs_reg = if (rhs_named) .xmm0 else .xmm1;
    }

    try selector_state.clobberAccumulator(selector);
    try selector.machine.instructions.append(selector.allocator, .{ .ucomiss = .{ .dst = lhs_reg, .src = rhs_reg } });
    try selector.machine.instructions.append(selector.allocator, .{ .set_fcmp_eax = fcmp.predicate });
    try selector_state.bindEax(selector, result_name);
    return null;
}

pub fn lowerFpCast(selector: *ComposedBlockSelector, result: ?[]const u8, cast: ir.CastInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    return switch (cast.op) {
        .fpext => if (cast.from_ty == .float and cast.to_ty == .double)
            lowerScalarFpCast(selector, result_name, cast, 32, 64)
        else
            lowerHalfExtension(selector, result_name, cast),
        .fptrunc => if (cast.from_ty == .double and cast.to_ty == .float)
            lowerScalarFpCast(selector, result_name, cast, 64, 32)
        else
            lowerFloatToHalf(selector, result_name, cast),
        .bitcast => lowerFpIntBitcast(selector, result_name, cast),
        else => .{ .no_emitter = "composed-block-fp-cast-op" },
    };
}

fn lowerScalarFpCast(selector: *ComposedBlockSelector, result_name: []const u8, cast: ir.CastInst, from_bits: u16, to_bits: u16) !?Diagnostic {
    const dst = fpValueReg(selector, cast.value, from_bits) orelse .xmm0;
    if (try materializeFpValue(selector, cast.value, dst, from_bits)) |diagnostic| return diagnostic;
    try selector_state.clobberXmmReg(selector, dst);
    try selector.machine.instructions.append(selector.allocator, if (from_bits == 32)
        .{ .cvtss2sd_xmm = .{ .dst = dst, .src = dst } }
    else
        .{ .cvtsd2ss_xmm = .{ .dst = dst, .src = dst } });
    try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = dst, .bits = to_bits } });
    return null;
}

pub fn isFpIntBitcast(cast: ir.CastInst) bool {
    return (cast.from_ty == .half and cast.to_ty.eql(.{ .int = 16 })) or
        (cast.from_ty.eql(.{ .int = 16 }) and cast.to_ty == .half) or
        (cast.from_ty == .float and cast.to_ty.eql(.{ .int = 32 })) or
        (cast.from_ty.eql(.{ .int = 32 }) and cast.to_ty == .float) or
        (cast.from_ty == .double and cast.to_ty.eql(.{ .int = 64 })) or
        (cast.from_ty.eql(.{ .int = 64 }) and cast.to_ty == .double);
}

fn lowerFpIntBitcast(selector: *ComposedBlockSelector, result_name: []const u8, cast: ir.CastInst) !?Diagnostic {
    if (!isFpIntBitcast(cast)) return .{ .no_emitter = "composed-block-fp-bitcast-type" };
    if (cast.from_ty == .half or cast.from_ty == .float or cast.from_ty == .double) {
        const bits: u16 = if (cast.from_ty == .half) 16 else if (cast.from_ty == .float) 32 else 64;
        const source = if (cast.value == .fp) blk: {
            if (try materializeFpValue(selector, cast.value, .xmm0, bits)) |diagnostic| return diagnostic;
            break :blk selector_types.ValueLoc{ .xmm = .{ .reg = .xmm0, .bits = bits } };
        } else selector_state.resolveValue(selector, cast.value) orelse return .{ .unsupported_value = "composed-block-fp-bitcast-source" };
        try selector_state.clobberAccumulator(selector);
        const reg = switch (source) {
            .xmm => |fp| if (fp.bits == bits) fp.reg else return .{ .unsupported_value = "composed-block-fp-bitcast-source" },
            .spill_fp => |fp| blk: {
                if (fp.bits != bits) return .{ .unsupported_value = "composed-block-fp-bitcast-source" };
                selector_state.materializeLocIntoLoc(selector, source, .{ .xmm = .{ .reg = .xmm0, .bits = bits } }) catch return .{ .unsupported_value = "composed-block-fp-bitcast-source" };
                break :blk .xmm0;
            },
            else => return .{ .unsupported_value = "composed-block-fp-bitcast-source" },
        };
        if (bits == 64) {
            try selector.machine.instructions.append(selector.allocator, .{ .movq_xmm_rax = reg });
            try selector_state.bindRax(selector, result_name);
        } else {
            try selector.machine.instructions.append(selector.allocator, .{ .movd_xmm_eax = reg });
            try selector_state.bindEax(selector, result_name);
        }
        return null;
    }

    const bits: u16 = if (cast.to_ty == .half) 16 else if (cast.to_ty == .float) 32 else 64;
    if (bits == 64) {
        selector_state.emitValueIntoRax(selector, cast.value) catch return .{ .unsupported_value = "composed-block-fp-bitcast-source" };
    } else {
        selector_state.emitValueIntoEax(selector, cast.value) catch return .{ .unsupported_value = "composed-block-fp-bitcast-source" };
    }
    try selector_state.clobberXmmReg(selector, .xmm0);
    try selector.machine.instructions.append(selector.allocator, if (bits == 64) .{ .movq_rax_xmm = .xmm0 } else .{ .movd_eax_xmm = .xmm0 });
    try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = .xmm0, .bits = bits } });
    return null;
}

fn lowerFloatToHalf(selector: *ComposedBlockSelector, result_name: []const u8, cast: ir.CastInst) !?Diagnostic {
    if (cast.from_ty != .float or cast.to_ty != .half) return .{ .no_emitter = "composed-block-fptrunc-type" };
    if (try selector_state.spillLiveCallerClobbersForCall(selector)) |diagnostic| return diagnostic;
    const source = selector_state.resolveValue(selector, cast.value) orelse return .{ .unsupported_value = "composed-block-fptrunc-source" };
    selector_state.materializeLocIntoLoc(selector, source, .{ .xmm = .{ .reg = .xmm0, .bits = 32 } }) catch return .{ .unsupported_value = "composed-block-fptrunc-source" };

    const needs_alignment = selector.stack_frame_bytes == 0;
    if (needs_alignment) try selector_frame.appendSubRsp(selector, 8);
    try selector.machine.instructions.append(selector.allocator, .{ .direct_call = .{ .symbol = "__truncsfhf2", .ret_ty = .half } });
    if (needs_alignment) try selector_frame.appendAddRsp(selector, 8);
    try selector_state.bindValueLoc(selector, result_name, .{ .xmm = .{ .reg = .xmm0, .bits = 16 } });
    return null;
}

fn lowerHalfExtension(selector: *ComposedBlockSelector, result_name: []const u8, cast: ir.CastInst) !?Diagnostic {
    if (cast.from_ty != .half or (cast.to_ty != .float and cast.to_ty != .double)) return .{ .no_emitter = "composed-block-fpext-type" };
    if (try lowerHalfValueToFloatXmm0(selector, cast.value)) |diagnostic| return diagnostic;
    if (cast.to_ty == .double) try selector.machine.instructions.append(selector.allocator, .{ .cvtss2sd_xmm = .{ .dst = .xmm0, .src = .xmm0 } });
    try selector_state.bindValueLoc(selector, result_name, .{ .xmm = .{ .reg = .xmm0, .bits = if (cast.to_ty == .double) 64 else 32 } });
    return null;
}

fn lowerHalfValueToFloatXmm0(selector: *ComposedBlockSelector, value: ir.Value) !?Diagnostic {
    if (try selector_state.spillLiveCallerClobbersForCall(selector)) |diagnostic| return diagnostic;
    const source = selector_state.resolveValue(selector, value) orelse return .{ .unsupported_value = "composed-block-fpext-source" };
    return lowerHalfLocToFloatXmm0(selector, source);
}

fn lowerHalfLocToFloatXmm0(selector: *ComposedBlockSelector, source: selector_types.ValueLoc) !?Diagnostic {
    selector_state.materializeLocIntoLoc(selector, source, .{ .xmm = .{ .reg = .xmm0, .bits = 16 } }) catch return .{ .unsupported_value = "composed-block-fpext-source" };

    const needs_alignment = selector.stack_frame_bytes == 0;
    if (needs_alignment) try selector_frame.appendSubRsp(selector, 8);
    try selector.machine.instructions.append(selector.allocator, .{ .direct_call = .{ .symbol = "__extendhfsf2", .ret_ty = .float } });
    if (needs_alignment) try selector_frame.appendAddRsp(selector, 8);
    return null;
}
