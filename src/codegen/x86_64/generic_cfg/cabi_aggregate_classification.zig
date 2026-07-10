const std = @import("std");
const ir = @import("../../../ir.zig");
const target = @import("../../../target.zig");
const type_layout = @import("../../../zig_air_type_layout.zig");
const x86_64_types = @import("../types.zig");
const sysv_abi = @import("../sysv_abi.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");

const ArgReg = x86_64_types.ArgReg;
const XmmReg = x86_64_types.XmmReg;
const SysVAggregateClassification = sysv_abi.AggregateClassification;
const SysVRegisterNeeds = sysv_abi.RegisterNeeds;
const SysVSmallIntegerAggregate = sysv_abi.SmallIntegerAggregate;

const fpParamIndex = cabi_abi_helpers.fpParamIndex;

pub fn x86_64SysVDataLayout() !target.DataLayout {
    return target.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128");
}

pub fn classifySysVAggregateForTest(ty: ir.Type) !SysVAggregateClassification {
    return try sysv_abi.classifyAggregateForTest(ty);
}

pub fn classifySysVAggregate(ty: ir.Type) !SysVAggregateClassification {
    return try sysv_abi.classifyAggregate(ty);
}

pub fn classifySysVSmallIntegerAggregate(ty: ir.Type) ?SysVSmallIntegerAggregate {
    return sysv_abi.classifySmallIntegerAggregate(ty);
}

pub const AggregateReturnLeaf = struct {
    value: ir.Value,
    ty: ir.Type,
    offset: u64,
};

pub fn aggregateInsertByteOffset(aggregate_ty: ir.Type, indices: []const u8, value_ty: ir.Type) !u64 {
    const layout = try x86_64SysVDataLayout();
    var current_ty = aggregate_ty;
    var offset: u64 = 0;
    var rest = indices;
    while (rest.len != 0) {
        const comma = std.mem.indexOfScalar(u8, rest, ',');
        const part = std.mem.trim(u8, if (comma) |pos| rest[0..pos] else rest, " \t");
        const field_index = std.fmt.parseInt(usize, part, 10) catch return error.UnsupportedCodegenAbi;
        offset += type_layout.fieldByteOffset(layout, current_ty, field_index) orelse
            return error.UnsupportedCodegenAbi;
        current_ty = type_layout.fieldType(current_ty, field_index) orelse return error.UnsupportedCodegenAbi;
        rest = if (comma) |pos| rest[pos + 1 ..] else "";
    }
    if (!current_ty.eql(value_ty)) return error.UnsupportedCodegenAbi;
    return offset;
}

pub fn aggregateFieldCount(ty: ir.Type) ?usize {
    return type_layout.fieldCount(ty);
}

pub fn aggregateFieldEightbyte(aggregate_ty: ir.Type, field_index: usize) !usize {
    const layout = try x86_64SysVDataLayout();
    const field_offset = type_layout.fieldByteOffset(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    return @intCast(field_offset / 8);
}

pub fn fpParamIndexFromValue(function: ir.Function, value: ir.Value, ty: ir.Type) !usize {
    return switch (value) {
        .named => |name| try fpParamIndex(function, name, ty),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

pub fn valuesEqual(a: ir.Value, b: ir.Value) bool {
    return switch (a) {
        .named => |a_name| switch (b) {
            .named => |b_name| std.mem.eql(u8, a_name, b_name),
            else => false,
        },
        .undef => b == .undef,
        .poison => b == .poison,
        .null_value => b == .null_value,
        .zero_initializer => b == .zero_initializer,
        .int => |a_int| switch (b) {
            .int => |b_int| a_int == b_int,
            else => false,
        },
        .fp => |a_fp| switch (b) {
            .fp => |b_fp| std.mem.eql(u8, a_fp, b_fp),
            else => false,
        },
        .vector, .constant_expr => false,
    };
}

pub fn isScalarElementGepType(ty: ir.Type) bool {
    return switch (ty) {
        .int, .float, .double, .ptr => true,
        .void, .half, .x86_fp80, .fp128, .metadata, .aggregate, .vector => false,
    };
}

pub fn isAggregateType(ty: ir.Type) bool {
    return type_layout.isAggregateType(ty);
}

pub const SysVIntegerAggregateFieldLocation = union(enum) {
    gpr: struct {
        reg: ArgReg,
        offset_in_eightbyte: u3,
    },
    stack: u32,
};

pub fn isI64Aggregate(aggregate_ty: ir.Type) bool {
    const field_count = aggregateFieldCount(aggregate_ty) orelse return false;
    if (field_count == 0) return false;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = type_layout.fieldType(aggregate_ty, field_index) orelse return false;
        if (!field_ty.eql(.{ .int = 64 })) return false;
    }
    return true;
}

pub fn isI64LeafAggregate(aggregate_ty: ir.Type) bool {
    const field_count = aggregateFieldCount(aggregate_ty) orelse return false;
    if (field_count == 0) return false;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = type_layout.fieldType(aggregate_ty, field_index) orelse return false;
        if (field_ty.eql(.{ .int = 64 })) continue;
        if (isAggregateType(field_ty) and isI64LeafAggregate(field_ty)) continue;
        return false;
    }
    return true;
}

pub const SysVAggregateFieldLocation = union(enum) {
    gpr: ArgReg,
    sse: XmmReg,
    stack: u32,
};

pub fn sysvAggregateRegisterNeeds(classification: SysVAggregateClassification) SysVRegisterNeeds {
    return sysv_abi.aggregateRegisterNeeds(classification);
}

pub fn sysvAggregateRegisterNeedsBefore(classification: SysVAggregateClassification, limit: usize) SysVRegisterNeeds {
    return sysv_abi.aggregateRegisterNeedsBefore(classification, limit);
}
