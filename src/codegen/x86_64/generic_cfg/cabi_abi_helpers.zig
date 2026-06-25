const std = @import("std");
const ir = @import("../../../ir.zig");
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
    if (!ty.eql(.{ .int = 32 }) and !ty.eql(.{ .int = 64 }) and !ty.eql(.ptr)) return error.UnsupportedCodegenType;
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
    return ty.eql(.{ .int = 1 }) or ty.eql(.{ .int = 8 }) or ty.eql(.{ .int = 16 }) or
        ty.eql(.{ .int = 32 }) or ty.eql(.{ .int = 64 }) or ty.eql(.ptr);
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
