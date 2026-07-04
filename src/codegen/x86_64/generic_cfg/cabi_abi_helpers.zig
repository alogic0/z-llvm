const std = @import("std");
const ir = @import("../../../ir.zig");
const type_layout = @import("../../../zig_air_type_layout.zig");
const x86_64_types = @import("../types.zig");
const sysv_abi = @import("../sysv_abi.zig");

const ArgReg = x86_64_types.ArgReg;

pub fn paramValueReg(function: ir.Function, value: ir.Value, ty: ir.Type) !ArgReg {
    return switch (value) {
        .named => |name| try paramReg(function, name, ty),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

pub fn paramReg(function: ir.Function, name: []const u8, ty: ir.Type) !ArgReg {
    return try paramRegOrNull(function, name, ty) orelse error.UnsupportedCodegenValue;
}

pub fn sysvIntegerParamReg(function: ir.Function, name: []const u8, ty: ir.Type) !ArgReg {
    return try sysvIntegerParamRegOrNull(function, name, ty) orelse error.UnsupportedCodegenValue;
}

pub fn sysvIntegerParamRegOrNull(function: ir.Function, name: []const u8, ty: ir.Type) !?ArgReg {
    if (!isSysVIntegerParamType(ty)) return error.UnsupportedCodegenType;
    return try paramRegOrNull(function, name, ty);
}

pub fn paramRegOrNull(function: ir.Function, name: []const u8, ty: ir.Type) !?ArgReg {
    return try paramRegOrNullWithInitialGpr(function, name, ty, 0);
}

pub fn paramRegWithInitialGpr(function: ir.Function, name: []const u8, ty: ir.Type, initial_gpr: usize) !ArgReg {
    return try paramRegOrNullWithInitialGpr(function, name, ty, initial_gpr) orelse error.UnsupportedCodegenValue;
}

pub fn paramRegOrNullWithInitialGpr(function: ir.Function, name: []const u8, ty: ir.Type, initial_gpr: usize) !?ArgReg {
    if (!isSysVIntegerParamType(ty)) return error.UnsupportedCodegenType;
    var gpr_index: usize = initial_gpr;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) {
            if (!param.ty.eql(ty) or !isSysVIntegerParamType(param.ty)) return error.UnsupportedCodegenValue;
            if (gpr_index >= 6) return error.UnsupportedCodegenAbi;
            return try ArgReg.fromIndex(gpr_index);
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return null;
}

pub fn scalarParamStackDisp8(function: ir.Function, name: []const u8, ty: ir.Type) !u32 {
    if (!isSysVIntegerParamType(ty) and !ty.eql(.float) and !ty.eql(.double)) return error.UnsupportedCodegenType;
    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) {
            if (!param.ty.eql(ty)) return error.UnsupportedCodegenValue;
            const in_register = if (isSysVIntegerParamType(ty)) gpr_index < 6 else sse_index < 8;
            if (in_register) return error.UnsupportedCodegenAbi;
            const offset = 8 + stack_eightbytes * 8;
            if (offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
            return @intCast(offset);
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return error.UnsupportedCodegenValue;
}

pub fn isSysVIntegerParamType(ty: ir.Type) bool {
    return switch (ty) {
        .int => |bits| bits >= 1 and bits <= 64,
        .ptr => true,
        else => false,
    };
}

pub fn fpParamIndex(function: ir.Function, name: []const u8, ty: ir.Type) !usize {
    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        const param_is_fp = param.ty.eql(.float) or param.ty.eql(.double);
        if (std.mem.eql(u8, param.name, name)) {
            if (!param.ty.eql(ty) or !param_is_fp) return error.UnsupportedCodegenValue;
            if (sse_index >= 8) return error.UnsupportedCodegenAbi;
            return sse_index;
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return error.UnsupportedCodegenValue;
}

pub fn stackParamDisp8OrNull(function: ir.Function, name: []const u8, ty: ir.Type) !?u32 {
    if (!isSysVIntegerParamType(ty) and !ty.eql(.float) and !ty.eql(.double)) return error.UnsupportedCodegenType;
    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) {
            if (!param.ty.eql(ty)) return error.UnsupportedCodegenValue;
            const in_register = if (isSysVIntegerParamType(ty)) gpr_index < 6 else sse_index < 8;
            if (in_register) return null;
            const offset = 8 + stack_eightbytes * 8;
            if (offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
            return @intCast(offset);
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return null;
}

pub fn registerParamRegOrNull(function: ir.Function, name: []const u8, ty: ir.Type) !?ArgReg {
    return paramRegOrNull(function, name, ty) catch |err| switch (err) {
        error.UnsupportedCodegenAbi => null,
        else => return err,
    };
}

pub fn bitcastScalarParamRegOrNull(function: ir.Function, name: []const u8, from_ty: ir.Type, to_ty: ir.Type) !?ArgReg {
    const to_bits = switch (to_ty) {
        .int => |bits| bits,
        else => return error.UnsupportedCodegenType,
    };
    if (to_bits == 0 or to_bits > 64) return error.UnsupportedCodegenType;

    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) {
            if (!param.ty.eql(from_ty)) return error.UnsupportedCodegenValue;
            if (gpr_index >= 6) return error.UnsupportedCodegenAbi;
            return try ArgReg.fromIndex(gpr_index);
        }
        if (isSysVIntegerParamType(param.ty)) {
            if (gpr_index < 6) {
                gpr_index += 1;
            }
        } else if (param.ty.eql(.float) or param.ty.eql(.double)) {
            if (sse_index < 8) {
                sse_index += 1;
            }
        } else {
            return error.UnsupportedCodegenAbi;
        }
    }
    return null;
}

pub fn blockIndex(function: ir.Function, name: []const u8) ?usize {
    for (function.blocks.items, 0..) |block, index| {
        if (std.mem.eql(u8, block.name, name)) return index;
    }
    return null;
}

pub fn advanceSysVParamCursors(
    ty: ir.Type,
    gpr_index: *usize,
    sse_index: *usize,
    stack_eightbytes: *usize,
) !void {
    return sysv_abi.advanceParamCursors(ty, gpr_index, sse_index, stack_eightbytes);
}

pub const SysVIntegerAggregateFieldLocation = union(enum) {
    gpr: struct {
        reg: ArgReg,
        offset_in_eightbyte: u3,
    },
    stack: u32,
};

pub fn sysvIntegerAggregateFieldLocation(
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_offset: u64,
    field_ty: ir.Type,
) !SysVIntegerAggregateFieldLocation {
    const layout = try sysv_abi.dataLayout();
    const field_size = try layout.typeStoreSizeBytes(field_ty);
    const opaque_offset_zero_i32 = field_offset == 0 and field_ty.eql(.{ .int = 32 }) and type_layout.fieldCount(aggregate_ty) == 0;
    if (!opaque_offset_zero_i32) {
        const aggregate_size = try layout.typeStoreSizeBytes(aggregate_ty);
        if (field_size == 0 or field_offset + field_size > aggregate_size) return error.UnsupportedCodegenAbi;
    }
    if (field_size != 4 and field_size != 8) return error.UnsupportedCodegenAbi;
    if (!opaque_offset_zero_i32) {
        _ = type_layout.fieldIndexAtOffset(layout, aggregate_ty, field_offset, field_ty) orelse
            return error.UnsupportedCodegenAbi;
    }

    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, param_name)) {
            if (!param.ty.eql(aggregate_ty)) return error.UnsupportedCodegenValue;
            if (opaque_offset_zero_i32) {
                if (gpr_index >= 6) {
                    const offset = 8 + stack_eightbytes * 8;
                    if (offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
                    return .{ .stack = @intCast(offset) };
                }
                return .{ .gpr = .{
                    .reg = try ArgReg.fromIndex(gpr_index),
                    .offset_in_eightbyte = 0,
                } };
            }
            const classification = try sysv_abi.classifyAggregate(param.ty);
            const field_eightbyte = field_offset / 8;
            if (field_eightbyte >= classification.eightbyte_count) return error.UnsupportedCodegenAbi;
            const field_class = classification.eightbytes[@intCast(field_eightbyte)] orelse
                return error.UnsupportedCodegenAbi;
            if (field_class != .integer) return error.UnsupportedCodegenAbi;
            const needed = sysv_abi.aggregateRegisterNeeds(classification);
            if (gpr_index + needed.gpr > 6 or sse_index + needed.sse > 8) {
                const offset = 8 + stack_eightbytes * 8 + field_offset;
                if (offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
                return .{ .stack = @intCast(offset) };
            }
            const prior = sysv_abi.aggregateRegisterNeedsBefore(classification, @intCast(field_eightbyte));
            return .{ .gpr = .{
                .reg = try ArgReg.fromIndex(gpr_index + prior.gpr),
                .offset_in_eightbyte = @intCast(field_offset % 8),
            } };
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return error.UnsupportedCodegenValue;
}
