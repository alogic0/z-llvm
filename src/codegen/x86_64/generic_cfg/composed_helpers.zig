const std = @import("std");
const ir = @import("../../../ir.zig");
const sysv_abi = @import("../sysv_abi.zig");
const x86_64_types = @import("../types.zig");
const selector_types = @import("selector_types.zig");

const ArgReg = selector_types.ArgReg;
const ValueLoc = selector_types.ValueLoc;
pub const MachineBinaryOp = x86_64_types.MachineBinaryOp;

pub fn blockHasPhiIncomingFrom(block: ir.BasicBlock, predecessor: []const u8) bool {
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

pub fn phiIncomingFrom(phi: ir.PhiInst, predecessor: []const u8) ?ir.PhiIncoming {
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, predecessor)) return incoming;
    }
    return null;
}

pub fn canUseExpiredPlanRegisterReuse(function: ir.Function) bool {
    if (intBits(function.ret_ty) != 128) return false;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.kind == .call) return false;
        }
    }
    return true;
}

pub fn machineBinaryOp(op: ir.BinaryOp) ?MachineBinaryOp {
    return switch (op) {
        .add => .add,
        .sub => .sub,
        .@"and" => .@"and",
        .@"or" => .@"or",
        .xor => .xor,
        .fadd, .fsub, .fmul, .fdiv, .frem, .mul, .shl, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => null,
    };
}

pub fn isCommutative(op: MachineBinaryOp) bool {
    return switch (op) {
        .add, .@"and", .@"or", .xor => true,
        .sub => false,
    };
}

pub fn locIsAccumulator(loc: ValueLoc) bool {
    return switch (loc) {
        .eax, .rax => true,
        .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => false,
    };
}

pub fn valueLocEql(lhs: ValueLoc, rhs: ValueLoc) bool {
    if (std.meta.activeTag(lhs) != std.meta.activeTag(rhs)) return false;
    return switch (lhs) {
        .arg32 => |reg| reg == rhs.arg32,
        .arg64 => |reg| reg == rhs.arg64,
        .arg128 => |pair| pair.eql(rhs.arg128),
        .eax, .rax => true,
        .scratch32 => |reg| reg == rhs.scratch32,
        .scratch64 => |reg| reg == rhs.scratch64,
        .scratch128 => |pair| pair.eql(rhs.scratch128),
        .xmm => |fp| fp.reg == rhs.xmm.reg and fp.shapeEql(rhs.xmm),
        .stack_scalar => |stack| stack.base_disp == rhs.stack_scalar.base_disp and stack.bits == rhs.stack_scalar.bits and stack.kind == rhs.stack_scalar.kind,
        .stack128 => |disp| disp == rhs.stack128,
        .stack128_value => |disp| disp == rhs.stack128_value,
        .stack_i32_array => |array| array.base_disp == rhs.stack_i32_array.base_disp and array.len == rhs.stack_i32_array.len,
        .stack_i32_ptr => |ptr| ptr.disp == rhs.stack_i32_ptr.disp and ptr.index == null and rhs.stack_i32_ptr.index == null,
        .readonly_table_ptr => |ptr| blk: {
            const other = rhs.readonly_table_ptr;
            if (!std.mem.eql(u8, ptr.symbol, other.symbol) or ptr.shape != other.shape or ptr.offset != other.offset or std.meta.activeTag(ptr.storage) != std.meta.activeTag(other.storage)) break :blk false;
            break :blk switch (ptr.storage) {
                .reg => |reg| reg == other.storage.reg,
                .spill => |frame_index| frame_index.eql(other.storage.spill),
            };
        },
        .spill64 => |frame_index| frame_index.eql(rhs.spill64),
        .spill128 => |spill| spill.lo.eql(rhs.spill128.lo) and spill.hi.eql(rhs.spill128.hi),
        .spill_fp => |fp| fp.frame_index.eql(rhs.spill_fp.frame_index) and fp.bits == rhs.spill_fp.bits,
        .spill_vector => |vector| vector.frames.lo.eql(rhs.spill_vector.frames.lo) and
            vector.frames.hi.eql(rhs.spill_vector.frames.hi) and vector.shape.eql(rhs.spill_vector.shape),
        .aggregate_sse => |aggregate| sseAggregateLocEql(aggregate, rhs.aggregate_sse),
    };
}

pub fn locContainsReg(loc: ValueLoc, reg: ArgReg) bool {
    return switch (loc) {
        .arg32, .arg64, .scratch32, .scratch64 => |value_reg| value_reg == reg,
        .arg128, .scratch128 => |pair| pair.contains(reg),
        .readonly_table_ptr => |ptr| switch (ptr.storage) {
            .reg => |value_reg| value_reg == reg,
            .spill => false,
        },
        .eax, .rax, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => false,
    };
}

fn sseAggregateLocEql(lhs: selector_types.SseAggregateLoc, rhs: selector_types.SseAggregateLoc) bool {
    if (std.meta.activeTag(lhs) != std.meta.activeTag(rhs)) return false;
    return switch (lhs) {
        .packed_f32x2 => |leaf| optionalSseLeafEql(leaf, rhs.packed_f32x2),
        .split_f64x2 => |leaves| optionalSseLeafEql(leaves[0], rhs.split_f64x2[0]) and
            optionalSseLeafEql(leaves[1], rhs.split_f64x2[1]),
    };
}

fn optionalSseLeafEql(lhs: ?selector_types.SseAggregateLeaf, rhs: ?selector_types.SseAggregateLeaf) bool {
    if (lhs == null or rhs == null) return lhs == null and rhs == null;
    return lhs.?.kind == rhs.?.kind and std.mem.eql(u8, lhs.?.name, rhs.?.name);
}

pub fn valueIsInt(value: ir.Value) bool {
    return switch (value) {
        .int => true,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn intBits(ty: ir.Type) ?u16 {
    return switch (ty) {
        .int => |bits| bits,
        .void, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate, .vector => null,
    };
}

pub fn callArgRegisterCount(ty: ir.Type) ?usize {
    if (ty == .ptr) return 1;
    const bits = intBits(ty) orelse return null;
    return switch (bits) {
        32, 64 => 1,
        128 => 2,
        else => null,
    };
}

pub fn isDefaultOrFastcc(calling_conv: ?[]const u8) bool {
    const cc = calling_conv orelse return true;
    return std.mem.eql(u8, cc, "ccc") or std.mem.eql(u8, cc, "fastcc");
}

pub fn parseI32ArrayType(ty: ir.Type) ?u32 {
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

pub fn alignedCallFrameBytes(payload_bytes: u32) ?u32 {
    if (payload_bytes == 0) return null;
    const rounded_payload = std.mem.alignForward(u32, payload_bytes, 16);
    return std.math.add(u32, rounded_payload, 8) catch null;
}

pub fn stack128FrameBytes() u32 {
    return 56;
}

pub fn isComposedReturnType(ty: ir.Type) bool {
    if (ty == .void or ty == .half or ty == .float or ty == .double) return true;
    if (sysv_abi.sseAggregateReturnKind(ty) != null) return true;
    const bits = intBits(ty) orelse return false;
    return bits == 32 or bits == 64 or bits == 128;
}

pub fn shiftAmount5(value: i128) !u5 {
    if (value < 0 or value > std.math.maxInt(u5)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

pub fn shiftAmount6(value: i128) !u6 {
    if (value < 0 or value > std.math.maxInt(u6)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

pub fn shiftAmount7(value: i128) !u7 {
    if (value < 0 or value > std.math.maxInt(u7)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

pub fn i32Value(value: i128) !i32 {
    if (value < std.math.minInt(i32) or value > std.math.maxInt(i32)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

pub fn i32BitPattern(value: i128) !i32 {
    if (value < std.math.minInt(i32) or value > std.math.maxInt(u32)) return error.UnsupportedCodegenValue;
    if (value < 0) return @intCast(value);
    return @bitCast(@as(u32, @intCast(value)));
}

pub fn i64Value(value: i128) !i64 {
    if (value < std.math.minInt(i64) or value > std.math.maxInt(i64)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}
