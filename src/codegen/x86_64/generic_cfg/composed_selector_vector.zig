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

pub fn lowerBinary(selector: *ComposedBlockSelector, result: ?[]const u8, binary: ir.BinaryInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-vector-missing-result" };
    if (!isF64x2(binary.ty)) return .{ .no_emitter = "composed-vector-binary-type" };
    if (binary.op != .fadd and binary.op != .fmul) return .{ .no_emitter = "composed-vector-binary-op" };

    const lhs_shape = vectorValueShape(selector, binary.lhs) orelse return .{ .unsupported_value = "composed-vector-binary-lhs" };
    const rhs_shape = vectorValueShape(selector, binary.rhs) orelse return .{ .unsupported_value = "composed-vector-binary-rhs" };
    const rhs_reg = vectorValueReg(selector, binary.rhs);
    const dst = resultXmmReg(selector, result_name, binary.lhs, rhs_reg) orelse return .{ .no_spill_envelope = "composed-vector-binary-dst" };
    if (try materializeVectorValue(selector, binary.lhs, dst, lhs_shape, rhs_reg)) |diagnostic| return diagnostic;
    const src = vectorValueReg(selector, binary.rhs) orelse blk: {
        const scratch = scratchXmmReg(selector, dst, null);
        if (try materializeVectorValue(selector, binary.rhs, scratch, rhs_shape, dst)) |diagnostic| return diagnostic;
        break :blk scratch;
    };

    try selector_state.clobberXmmReg(selector, dst);
    try selector.machine.instructions.append(selector.allocator, if (binary.op == .fadd)
        .{ .addpd_xmm = .{ .dst = dst, .src = src } }
    else
        .{ .mulpd_xmm = .{ .dst = dst, .src = src } });
    const result_shape = VectorShape.f64x2(lhs_shape.defined_lanes & rhs_shape.defined_lanes);
    try bindVectorResult(selector, result_name, dst, result_shape);
    return null;
}

pub fn lowerInsertElement(selector: *ComposedBlockSelector, result: ?[]const u8, insert: ir.InsertElementInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-vector-missing-result" };
    if (!isF64x2(insert.vector_ty) or insert.value_ty != .double) return .{ .no_emitter = "composed-vector-insert-type" };
    const lane = constantLane(insert.index) orelse return .{ .no_emitter = "composed-vector-insert-index" };
    const base_shape = vectorValueShape(selector, insert.vector) orelse return .{ .unsupported_value = "composed-vector-insert-base" };
    const scalar_reg = scalarValueReg(selector, insert.value);
    const preserve_scalar = insert.vector != .poison and insert.vector != .undef;
    const dst = resultXmmReg(selector, result_name, insert.vector, if (preserve_scalar) scalar_reg else null) orelse return .{ .no_spill_envelope = "composed-vector-insert-dst" };

    if (insert.vector != .poison and insert.vector != .undef) {
        if (try materializeVectorValue(selector, insert.vector, dst, base_shape, scalar_reg)) |diagnostic| return diagnostic;
    }
    const src = scalar_reg orelse blk: {
        const scratch = scratchXmmReg(selector, dst, null);
        if (try selector_fp.materializeFpValue(selector, insert.value, scratch, 64)) |diagnostic| return diagnostic;
        break :blk scratch;
    };

    try selector_state.clobberXmmReg(selector, dst);
    if (insert.vector == .poison or insert.vector == .undef) {
        if (dst != src) try selector.machine.instructions.append(selector.allocator, .{ .movapd_xmm = .{ .dst = dst, .src = src } });
        if (lane == 1) try selector.machine.instructions.append(selector.allocator, .{ .unpcklpd_xmm = .{ .dst = dst, .src = dst } });
    } else if (lane == 0) {
        try selector.machine.instructions.append(selector.allocator, .{ .movsd_xmm = .{ .dst = dst, .src = src } });
    } else {
        try selector.machine.instructions.append(selector.allocator, .{ .unpcklpd_xmm = .{ .dst = dst, .src = src } });
    }

    const lane_bit: u2 = if (lane == 0) 0b01 else 0b10;
    try bindVectorResult(selector, result_name, dst, VectorShape.f64x2(base_shape.defined_lanes | lane_bit));
    return null;
}

pub fn lowerShuffleVector(selector: *ComposedBlockSelector, result: ?[]const u8, shuffle: ir.ShuffleVectorInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-vector-missing-result" };
    if (!isF64x2(shuffle.lhs_ty) or !shuffle.rhs_ty.eql(shuffle.lhs_ty) or !isSplatMask(shuffle)) {
        return .{ .no_emitter = "composed-vector-shuffle-form" };
    }
    const source_shape = vectorValueShape(selector, shuffle.lhs) orelse return .{ .unsupported_value = "composed-vector-shuffle-source" };
    const dst = resultXmmReg(selector, result_name, shuffle.lhs, null) orelse return .{ .no_spill_envelope = "composed-vector-shuffle-dst" };
    if (try materializeVectorValue(selector, shuffle.lhs, dst, source_shape, null)) |diagnostic| return diagnostic;
    try selector_state.clobberXmmReg(selector, dst);
    try selector.machine.instructions.append(selector.allocator, .{ .unpcklpd_xmm = .{ .dst = dst, .src = dst } });
    const defined: u2 = if ((source_shape.defined_lanes & 0b01) != 0) 0b11 else 0;
    try bindVectorResult(selector, result_name, dst, VectorShape.f64x2(defined));
    return null;
}

pub fn lowerExtractElement(selector: *ComposedBlockSelector, result: ?[]const u8, extract: ir.ExtractElementInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-vector-missing-result" };
    if (!isF64x2(extract.vector_ty)) return .{ .no_emitter = "composed-vector-extract-type" };
    const lane = constantLane(extract.index) orelse return .{ .no_emitter = "composed-vector-extract-index" };
    const source_shape = vectorValueShape(selector, extract.vector) orelse return .{ .unsupported_value = "composed-vector-extract-source" };
    const source_reg = vectorValueReg(selector, extract.vector);
    const dst = plannedXmmReg(selector, result_name, false) orelse scratchXmmReg(selector, source_reg orelse .xmm0, source_reg);
    if (try materializeVectorValue(selector, extract.vector, dst, source_shape, source_reg)) |diagnostic| return diagnostic;
    if (lane == 1) try selector.machine.instructions.append(selector.allocator, .{ .unpckhpd_xmm = .{ .dst = dst, .src = dst } });
    try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = dst, .bits = 64 } });
    return null;
}

fn bindVectorResult(selector: *ComposedBlockSelector, name: []const u8, reg: XmmReg, shape: VectorShape) !void {
    try selector_state.bindResultLoc(selector, name, .{ .xmm = .{
        .reg = reg,
        .bits = 128,
        .shape = .{ .vector = shape },
    } });
}

fn materializeVectorValue(
    selector: *ComposedBlockSelector,
    value: ir.Value,
    dst: XmmReg,
    shape: VectorShape,
    protected: ?XmmReg,
) !?Diagnostic {
    switch (value) {
        .named => {
            const source = selector_state.resolveValue(selector, value) orelse return .{ .unsupported_value = "composed-vector-source" };
            selector_state.materializeLocIntoLoc(selector, source, .{ .xmm = .{
                .reg = dst,
                .bits = 128,
                .shape = .{ .vector = shape },
            } }) catch return .{ .unsupported_value = "composed-vector-source" };
        },
        .vector, .zero_initializer, .poison, .undef => {
            const constant = parseVectorConstant(value) orelse return .{ .unsupported_value = "composed-vector-constant" };
            if (!constant.shape.eql(shape)) return .{ .unsupported_value = "composed-vector-constant-shape" };
            const high = scratchXmmReg(selector, dst, protected);
            try materializeDoubleBits(selector, constant.bits[0], dst);
            try materializeDoubleBits(selector, constant.bits[1], high);
            try selector_state.clobberXmmReg(selector, dst);
            try selector.machine.instructions.append(selector.allocator, .{ .unpcklpd_xmm = .{ .dst = dst, .src = high } });
        },
        else => return .{ .unsupported_value = "composed-vector-source" },
    }
    return null;
}

fn vectorValueShape(selector: *ComposedBlockSelector, value: ir.Value) ?VectorShape {
    return switch (value) {
        .named => switch (selector_state.resolveValue(selector, value) orelse return null) {
            .xmm => |fp| fp.vectorShape(),
            .spill_vector => |vector| vector.shape,
            else => null,
        },
        .vector, .zero_initializer, .poison, .undef => (parseVectorConstant(value) orelse return null).shape,
        else => null,
    };
}

fn vectorValueReg(selector: *ComposedBlockSelector, value: ir.Value) ?XmmReg {
    return switch (selector_state.resolveValue(selector, value) orelse return null) {
        .xmm => |fp| if (fp.vectorShape() != null) fp.reg else null,
        else => null,
    };
}

fn scalarValueReg(selector: *ComposedBlockSelector, value: ir.Value) ?XmmReg {
    return switch (selector_state.resolveValue(selector, value) orelse return null) {
        .xmm => |fp| if (fp.shape == .scalar and fp.bits == 64) fp.reg else null,
        else => null,
    };
}

fn resultXmmReg(selector: *const ComposedBlockSelector, result_name: []const u8, reusable: ir.Value, avoid: ?XmmReg) ?XmmReg {
    if (plannedXmmReg(selector, result_name, true)) |reg| {
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
    for (xmm_regs) |reg| {
        if (avoid == null or reg != avoid.?) return reg;
    }
    return null;
}

fn plannedXmmReg(selector: *const ComposedBlockSelector, result_name: []const u8, vector: bool) ?XmmReg {
    const plan = selector.allocation_plan orelse return null;
    const assignment = plan.assignment(result_name) orelse return null;
    const reg = switch (assignment) {
        .vector_f64x2 => |reg| if (vector) reg else return null,
        .fp64 => |reg| if (!vector) reg else return null,
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
        .xmm => |fp| if (fp.reg == reg and selector_state.valueMustSurviveClobber(selector, entry.key_ptr.*)) return false,
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

fn isSplatMask(shuffle: ir.ShuffleVectorInst) bool {
    return switch (shuffle.mask) {
        .zero_initializer => true,
        .vector => |text| std.mem.eql(u8, std.mem.trim(u8, text, " \t"), "<i32 0, i32 0>") or
            std.mem.eql(u8, std.mem.trim(u8, text, " \t"), "splat (i32 0)"),
        else => false,
    };
}

fn parseVectorConstant(value: ir.Value) ?VectorConstant {
    return switch (value) {
        .zero_initializer => .{ .bits = .{ 0, 0 }, .shape = VectorShape.f64x2(0b11) },
        .poison, .undef => .{ .bits = .{ 0, 0 }, .shape = VectorShape.f64x2(0) },
        .vector => |raw| parseVectorText(raw),
        else => null,
    };
}

fn parseVectorText(raw: []const u8) ?VectorConstant {
    const text = std.mem.trim(u8, raw, " \t");
    if (std.mem.startsWith(u8, text, "splat (double ") and std.mem.endsWith(u8, text, ")")) {
        const lane = parseDoubleLane(text["splat (".len .. text.len - 1]) orelse return null;
        const defined: u2 = if (lane.defined) 0b11 else 0;
        return .{ .bits = .{ lane.bits, lane.bits }, .shape = VectorShape.f64x2(defined) };
    }
    if (text.len < 2 or text[0] != '<' or text[text.len - 1] != '>') return null;
    const body = text[1 .. text.len - 1];
    const comma = std.mem.indexOfScalar(u8, body, ',') orelse return null;
    if (std.mem.indexOfScalar(u8, body[comma + 1 ..], ',') != null) return null;
    const low = parseDoubleLane(body[0..comma]) orelse return null;
    const high = parseDoubleLane(body[comma + 1 ..]) orelse return null;
    var defined: u2 = 0;
    if (low.defined) defined |= 0b01;
    if (high.defined) defined |= 0b10;
    return .{ .bits = .{ low.bits, high.bits }, .shape = VectorShape.f64x2(defined) };
}

const ParsedLane = struct {
    bits: u64,
    defined: bool,
};

fn parseDoubleLane(raw: []const u8) ?ParsedLane {
    const lane = std.mem.trim(u8, raw, " \t");
    if (!std.mem.startsWith(u8, lane, "double ")) return null;
    const value = std.mem.trim(u8, lane["double ".len..], " \t");
    if (std.mem.eql(u8, value, "poison") or std.mem.eql(u8, value, "undef")) return .{ .bits = 0, .defined = false };
    if (std.mem.eql(u8, value, "zeroinitializer")) return .{ .bits = 0, .defined = true };
    return .{
        .bits = x86_64_match.fp64TextBits(.{ .fp = value }) catch return null,
        .defined = true,
    };
}

fn materializeDoubleBits(selector: *ComposedBlockSelector, bits: u64, reg: XmmReg) !void {
    try selector_state.clobberAccumulator(selector);
    try selector_state.clobberXmmReg(selector, reg);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm64_xmm = .{ .reg = reg, .bits = bits } });
}

fn isF64x2(ty: ir.Type) bool {
    return ty == .vector and ty.vector.len == 2 and ty.vector.elem_ty == .double;
}
