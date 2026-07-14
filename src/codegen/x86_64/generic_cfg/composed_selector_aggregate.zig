const std = @import("std");
const ir = @import("../../../ir.zig");
const sysv_abi = @import("../sysv_abi.zig");
const selector_types = @import("selector_types.zig");
const selector_state = @import("composed_selector_state.zig");
const state_data = @import("composed_selector_state_data.zig");
const stage2_planning = @import("stage2_planning.zig");

const ComposedBlockSelector = state_data.ComposedBlockSelector;
const SseAggregateLeaf = selector_types.SseAggregateLeaf;
const SseAggregateLoc = selector_types.SseAggregateLoc;
const ValueLoc = selector_types.ValueLoc;
const XmmReg = selector_types.XmmReg;

pub fn lowerInsertValue(selector: *ComposedBlockSelector, result: ?[]const u8, insert: ir.InsertValueInst) !?selector_state.Diagnostic {
    const result_name = result orelse return error.UnsupportedCodegenValue;
    const function = selector.function orelse return error.UnsupportedCodegenValue;
    const leaf_name = namedLeafName(insert.value) orelse return error.UnsupportedCodegenValue;
    const kind = sysv_abi.sseAggregateReturnKind(insert.aggregate_ty) orelse return error.UnsupportedCodegenValue;

    switch (kind) {
        .packed_f32x2 => {
            if (!std.mem.eql(u8, insert.indices, "0") or insert.aggregate != .poison or !isF32x2(insert.value_ty))
                return error.UnsupportedCodegenValue;
            try requireLeafShape(selector, leaf_name, .f32x2);
            try requireOnlyReturnUse(selector, function.*, result_name);
            try selector_state.bindValueLoc(selector, result_name, .{ .aggregate_sse = .{
                .packed_f32x2 = .{ .name = leaf_name, .kind = .f32x2 },
            } });
        },
        .split_f64x2 => {
            if (insert.value_ty != .double) return error.UnsupportedCodegenValue;
            try requireLeafShape(selector, leaf_name, .f64);
            if (std.mem.eql(u8, insert.indices, "0")) {
                if (insert.aggregate != .poison) return error.UnsupportedCodegenValue;
                try requireOnlyInsertUse(selector, function.*, result_name, insert.aggregate_ty);
                try selector_state.bindValueLoc(selector, result_name, .{ .aggregate_sse = .{
                    .split_f64x2 = .{
                        .{ .name = leaf_name, .kind = .f64 },
                        null,
                    },
                } });
                return null;
            }
            if (!std.mem.eql(u8, insert.indices, "1")) return error.UnsupportedCodegenValue;
            const aggregate = selector_state.resolveValue(selector, insert.aggregate) orelse return error.UnsupportedCodegenValue;
            const leaves = switch (aggregate) {
                .aggregate_sse => |value| switch (value) {
                    .split_f64x2 => |leaves| leaves,
                    .packed_f32x2 => return error.UnsupportedCodegenValue,
                },
                else => return error.UnsupportedCodegenValue,
            };
            if (leaves[0] == null or leaves[1] != null) return error.UnsupportedCodegenValue;
            try requireOnlyReturnUse(selector, function.*, result_name);
            try selector_state.bindValueLoc(selector, result_name, .{ .aggregate_sse = .{
                .split_f64x2 = .{
                    leaves[0],
                    .{ .name = leaf_name, .kind = .f64 },
                },
            } });
        },
    }
    return null;
}

pub fn emitReturn(selector: *ComposedBlockSelector, value: ir.Value, kind: sysv_abi.SseAggregateReturnKind) !void {
    const loc = selector_state.resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
    const aggregate = switch (loc) {
        .aggregate_sse => |aggregate| aggregate,
        else => return error.UnsupportedCodegenValue,
    };
    switch (kind) {
        .packed_f32x2 => {
            const leaf = switch (aggregate) {
                .packed_f32x2 => |leaf| leaf orelse return error.UnsupportedCodegenValue,
                .split_f64x2 => return error.UnsupportedCodegenValue,
            };
            if (leaf.kind != .f32x2) return error.UnsupportedCodegenValue;
            try materializePackedLeaf(selector, leaf.name, .xmm0);
        },
        .split_f64x2 => {
            const leaves = switch (aggregate) {
                .split_f64x2 => |leaves| leaves,
                .packed_f32x2 => return error.UnsupportedCodegenValue,
            };
            const first = leaves[0] orelse return error.UnsupportedCodegenValue;
            const second = leaves[1] orelse return error.UnsupportedCodegenValue;
            if (first.kind != .f64 or second.kind != .f64) return error.UnsupportedCodegenValue;
            const first_loc = selector_state.valueLoc(selector, first.name) orelse return error.UnsupportedCodegenValue;
            const second_loc = selector_state.valueLoc(selector, second.name) orelse return error.UnsupportedCodegenValue;
            const scratch = splitReturnScratch(first_loc, second_loc);
            try materializeF64Loc(selector, first_loc, scratch);
            try materializeF64Loc(selector, second_loc, .xmm1);
            try selector.machine.instructions.append(selector.allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = scratch } });
        },
    }
}

fn requireOnlyInsertUse(selector: *ComposedBlockSelector, function: ir.Function, name: []const u8, aggregate_ty: ir.Type) !void {
    var uses: usize = 0;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (!try stage2_planning.instructionUsesName(selector.allocator, instruction, name)) continue;
            uses += 1;
            const insert = switch (instruction.kind) {
                .insertvalue => |insert| insert,
                else => return error.UnsupportedCodegenValue,
            };
            if (!insert.aggregate_ty.eql(aggregate_ty) or insert.aggregate != .named or
                !std.mem.eql(u8, insert.aggregate.named, name)) return error.UnsupportedCodegenValue;
        }
        if (block.terminator) |terminator| {
            if (try stage2_planning.terminatorUsesName(selector.allocator, terminator, name)) return error.UnsupportedCodegenValue;
        }
    }
    if (uses != 1) return error.UnsupportedCodegenValue;
}

fn requireOnlyReturnUse(selector: *ComposedBlockSelector, function: ir.Function, name: []const u8) !void {
    var uses: usize = 0;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (try stage2_planning.instructionUsesName(selector.allocator, instruction, name)) return error.UnsupportedCodegenValue;
        }
        if (block.terminator) |terminator| {
            if (!try stage2_planning.terminatorUsesName(selector.allocator, terminator, name)) continue;
            uses += 1;
            const ret = switch (terminator) {
                .ret => |ret| ret,
                else => return error.UnsupportedCodegenValue,
            };
            if (ret.value == null or ret.value.? != .named or !std.mem.eql(u8, ret.value.?.named, name))
                return error.UnsupportedCodegenValue;
        }
    }
    if (uses != 1) return error.UnsupportedCodegenValue;
}

fn requireLeafShape(selector: *const ComposedBlockSelector, name: []const u8, kind: SseAggregateLeaf.Kind) !void {
    const loc = selector_state.valueLoc(selector, name) orelse return error.UnsupportedCodegenValue;
    switch (kind) {
        .f32x2 => switch (loc) {
            .xmm => |xmm| if (xmm.bits != 128 or xmm.vectorShape() == null or
                !xmm.vectorShape().?.eql(selector_types.VectorShape.f32x2(0b11))) return error.UnsupportedCodegenValue,
            .spill_vector => |vector| if (!vector.shape.eql(selector_types.VectorShape.f32x2(0b11))) return error.UnsupportedCodegenValue,
            else => return error.UnsupportedCodegenValue,
        },
        .f64 => switch (loc) {
            .xmm => |xmm| if (xmm.bits != 64 or xmm.vectorShape() != null) return error.UnsupportedCodegenValue,
            .spill_fp => |fp| if (fp.bits != 64) return error.UnsupportedCodegenValue,
            else => return error.UnsupportedCodegenValue,
        },
    }
}

fn materializePackedLeaf(selector: *ComposedBlockSelector, name: []const u8, dst: XmmReg) !void {
    const loc = selector_state.valueLoc(selector, name) orelse return error.UnsupportedCodegenValue;
    switch (loc) {
        .xmm => |xmm| {
            try requireLeafShape(selector, name, .f32x2);
            if (xmm.reg != dst) try selector.machine.instructions.append(selector.allocator, .{ .movapd_xmm = .{ .dst = dst, .src = xmm.reg } });
        },
        .spill_vector => |vector| {
            try requireLeafShape(selector, name, .f32x2);
            try selector.machine.instructions.append(selector.allocator, .{ .reload_xmm128ps_rsp = .{ .frame_index = vector.frames.lo, .reg = dst } });
        },
        else => return error.UnsupportedCodegenValue,
    }
}

fn materializeF64Loc(selector: *ComposedBlockSelector, loc: ValueLoc, dst: XmmReg) !void {
    switch (loc) {
        .xmm => |xmm| {
            if (xmm.bits != 64 or xmm.vectorShape() != null) return error.UnsupportedCodegenValue;
            if (xmm.reg != dst) try selector.machine.instructions.append(selector.allocator, .{ .movapd_xmm = .{ .dst = dst, .src = xmm.reg } });
        },
        .spill_fp => |fp| {
            if (fp.bits != 64) return error.UnsupportedCodegenValue;
            try selector.machine.instructions.append(selector.allocator, .{ .reload_xmm64_rsp = .{ .frame_index = fp.frame_index, .reg = dst } });
        },
        else => return error.UnsupportedCodegenValue,
    }
}

fn splitReturnScratch(first: ValueLoc, second: ValueLoc) XmmReg {
    for (selector_types.selector_allocatable_xmm_regs[2..]) |reg| {
        if (!locUsesXmm(first, reg) and !locUsesXmm(second, reg)) return reg;
    }
    unreachable;
}

fn locUsesXmm(loc: ValueLoc, reg: XmmReg) bool {
    return switch (loc) {
        .xmm => |xmm| xmm.reg == reg,
        else => false,
    };
}

fn namedLeafName(value: ir.Value) ?[]const u8 {
    return switch (value) {
        .named => |name| name,
        else => null,
    };
}

fn isF32x2(ty: ir.Type) bool {
    return ty == .vector and ty.vector.len == 2 and ty.vector.elem_ty == .float;
}
