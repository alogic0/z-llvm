const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_model = @import("zig_air_model.zig");
const air_types = @import("zig_air_types.zig");
const type_layout = @import("zig_air_type_layout.zig");
const ir = @import("ir.zig");
const target_mod = @import("target.zig");

const ZigType = air_model.ZigType;
const FunctionType = air_model.FunctionType;
const parseZigType = air_types.parseZigType;

pub fn supportedScalarAggregateLeafParamCount(ty: ir.Type, params: []const ZigType) ?usize {
    const plan = aggregateCopyLayoutPlan(ty) orelse return null;
    const leaves = plan.leafSlice();
    if (leaves.len != params.len) return null;
    for (leaves, params) |leaf, param| {
        if (!param.ir_type.eql(leaf.ty)) return null;
    }
    return leaves.len;
}

pub fn supportedAggregateCopyLeafCount(ty: ir.Type) ?usize {
    const plan = aggregateCopyLayoutPlan(ty) orelse return null;
    return plan.leaf_count;
}

pub fn supportedAggregateCopyLeaf(ty: ir.Type) bool {
    return ty.eql(.{ .int = 8 }) or ty.eql(.{ .int = 16 }) or ty.eql(.{ .int = 32 }) or
        ty.eql(.{ .int = 64 }) or ty.eql(.ptr) or ty.eql(.float) or ty.eql(.double);
}

pub fn isAggregateIrType(ty: ir.Type) bool {
    return switch (ty) {
        .aggregate => true,
        .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => false,
    };
}

pub const AggregateCopyLeaf = type_layout.AggregateLeaf;

pub fn collectAggregateCopyLeaves(allocator: std.mem.Allocator, aggregate_ty: ir.Type) ![]AggregateCopyLeaf {
    const plan = aggregateCopyLayoutPlan(aggregate_ty) orelse return error.UnsupportedAir;
    if (plan.leaf_count < 3) return error.UnsupportedAir;
    const leaves = try allocator.alloc(AggregateCopyLeaf, plan.leaf_count);
    @memcpy(leaves, plan.leafSlice());
    return leaves;
}

pub fn validateSretAggregateMakeRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    const plan = aggregateCopyLayoutPlan(function_type.return_type.ir_type) orelse return false;
    const leaves = plan.leafSlice();
    if (leaves.len < 3 or leaves.len != function_type.params.len) return false;
    for (leaves, function_type.params) |leaf, param| {
        if (!leaf.ty.eql(param.ir_type)) return false;
    }
    if (air_model.typedOpcodeCount(structured_air_v2, "arg") != leaves.len) return false;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret_ptr") != 1) return false;
    if (air_model.typedStoreOpcodeCount(structured_air_v2) != leaves.len) return false;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret_load") != 1) return false;
    const layout = x86_64SysVDataLayout() orelse return false;
    const ret_ptr_index = air_model.typedRetPtrIndex(structured_air_v2) orelse return false;
    var seen: [max_mechanical_leaf_validation]bool = .{false} ** max_mechanical_leaf_validation;
    if (leaves.len > seen.len) return false;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "store") and !std.mem.eql(u8, instruction.opcode, "store_safe")) continue;
        if (instruction.operands.len != 2) return false;
        if (!std.mem.eql(u8, instruction.operands[1].kind, "inst")) return false;
        const arg_inst_index = std.fmt.parseInt(usize, instruction.operands[1].value, 10) catch return false;
        if (arg_inst_index >= leaves.len) return false;
        if (seen[arg_inst_index]) return false;
        const operand_type = parseZigType(instruction.operands[1].type_text) orelse return false;
        if (!operand_type.ir_type.eql(leaves[arg_inst_index].ty)) return false;
        const ptr_inst_index = std.fmt.parseInt(u32, instruction.operands[0].value, 10) catch return false;
        var path: [4]usize = undefined;
        const path_len = air_model.typedAggregatePointerPath(structured_air_v2, ptr_inst_index, ret_ptr_index, &path) orelse return false;
        const leaf = type_layout.leafAtIndexPath(layout, function_type.return_type.ir_type, path[0..path_len]) orelse return false;
        if (leaf.offset != leaves[arg_inst_index].offset or !leaf.ty.eql(leaves[arg_inst_index].ty)) return false;
        seen[arg_inst_index] = true;
    }
    for (seen[0..leaves.len]) |was_seen| {
        if (!was_seen) return false;
    }
    return true;
}

pub fn validateSretAggregateCopyRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    const leaf_count = supportedAggregateCopyLeafCount(function_type.return_type.ir_type) orelse return false;
    if (leaf_count < 3 or function_type.params.len != 1) return false;
    if (!function_type.params[0].ir_type.eql(function_type.return_type.ir_type)) return false;
    return air_model.typedOpcodeCount(structured_air_v2, "arg") == 1 and
        air_model.typedHasReturnOpcode(structured_air_v2);
}

pub fn validateSretAggregateCallWrapperRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    const leaf_count = supportedAggregateCopyLeafCount(function_type.return_type.ir_type) orelse return false;
    if (leaf_count < 3 or function_type.params.len < 2) return false;
    if (!function_type.params[function_type.params.len - 1].ir_type.eql(function_type.return_type.ir_type)) return false;
    return air_model.typedOpcodeCount(structured_air_v2, "call") == 1 and
        air_model.typedHasReturnOpcode(structured_air_v2);
}

fn aggregateCopyLayoutPlan(aggregate_ty: ir.Type) ?type_layout.AggregateLayoutPlan {
    const layout = x86_64SysVDataLayout() orelse return null;
    return type_layout.aggregateLayoutPlan(layout, aggregate_ty) catch null;
}

const max_mechanical_leaf_validation = type_layout.max_aggregate_layout_leaves;

fn x86_64SysVDataLayout() ?target_mod.DataLayout {
    return target_mod.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128") catch null;
}

test "collect aggregate copy leaves from nested aggregate" {
    const aggregate_ty: ir.Type = .{ .aggregate = "{ i32, { i64, double }, ptr }" };
    const leaves = try collectAggregateCopyLeaves(std.testing.allocator, aggregate_ty);
    defer std.testing.allocator.free(leaves);

    try std.testing.expectEqual(@as(usize, 4), leaves.len);
    try std.testing.expect(leaves[0].ty.eql(.{ .int = 32 }));
    try std.testing.expect(leaves[1].ty.eql(.{ .int = 64 }));
    try std.testing.expect(leaves[2].ty.eql(.double));
    try std.testing.expect(leaves[3].ty.eql(.ptr));
}

test "aggregate copy leaf counts use shared layout plan" {
    const aggregate_ty: ir.Type = .{ .aggregate = "%frontier_sysv_sret_byval.Big12" };
    try std.testing.expectEqual(@as(usize, 12), supportedAggregateCopyLeafCount(aggregate_ty).?);
    const leaves = try collectAggregateCopyLeaves(std.testing.allocator, aggregate_ty);
    defer std.testing.allocator.free(leaves);
    try std.testing.expectEqual(@as(usize, 12), leaves.len);
    try std.testing.expectEqual(@as(u64, 88), leaves[11].offset);
    try std.testing.expect(leaves[11].ty.eql(.{ .int = 64 }));
}

fn testInstOperand(value: []const u8, type_text: []const u8) air_export.TypedOperand {
    return .{ .kind = "inst", .value = value, .type_text = type_text };
}

test "aggregate copy validates sret make stores against layout leaves" {
    var params = [_]ZigType{
        .{ .ir_type = .{ .int = 64 } },
        .{ .ir_type = .{ .int = 64 } },
        .{ .ir_type = .{ .int = 64 } },
    };
    const function_type = FunctionType{
        .params = params[0..],
        .return_type = .{ .ir_type = .{ .aggregate = "{ i64, i64, i64 }" } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    const field0_details = [_]air_export.TypedDetail{.{ .key = "field_index", .value = "0" }};
    const field1_details = [_]air_export.TypedDetail{.{ .key = "field_index", .value = "1" }};
    const field2_details = [_]air_export.TypedDetail{.{ .key = "field_index", .value = "2" }};
    const field_ops = [_]air_export.TypedOperand{testInstOperand("3", "*Big3")};
    const store0_ops = [_]air_export.TypedOperand{ testInstOperand("4", "*i64"), testInstOperand("0", "i64") };
    const store1_ops = [_]air_export.TypedOperand{ testInstOperand("6", "*i64"), testInstOperand("1", "i64") };
    const store2_ops = [_]air_export.TypedOperand{ testInstOperand("8", "*i64"), testInstOperand("2", "i64") };
    const ret_load_ops = [_]air_export.TypedOperand{testInstOperand("3", "*Big3")};
    var instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "i64", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "arg", .result_type = "i64", .data_kind = "arg", .operands = &.{} },
        .{ .index = 2, .opcode = "arg", .result_type = "i64", .data_kind = "arg", .operands = &.{} },
        .{ .index = 3, .opcode = "ret_ptr", .result_type = "*Big3", .data_kind = "ret_ptr", .operands = &.{} },
        .{ .index = 4, .opcode = "struct_field_ptr_index_0", .result_type = "*i64", .data_kind = "field_ptr", .operands = @constCast(&field_ops), .details = @constCast(&field0_details) },
        .{ .index = 5, .opcode = "store", .result_type = "void", .data_kind = "bin_op", .operands = @constCast(&store0_ops) },
        .{ .index = 6, .opcode = "struct_field_ptr_index_1", .result_type = "*i64", .data_kind = "field_ptr", .operands = @constCast(&field_ops), .details = @constCast(&field1_details) },
        .{ .index = 7, .opcode = "store", .result_type = "void", .data_kind = "bin_op", .operands = @constCast(&store1_ops) },
        .{ .index = 8, .opcode = "struct_field_ptr_index_2", .result_type = "*i64", .data_kind = "field_ptr", .operands = @constCast(&field_ops), .details = @constCast(&field2_details) },
        .{ .index = 9, .opcode = "store", .result_type = "void", .data_kind = "bin_op", .operands = @constCast(&store2_ops) },
        .{ .index = 10, .opcode = "ret_load", .result_type = "Big3", .data_kind = "ret_load", .operands = @constCast(&ret_load_ops) },
    };
    const structured_air_v2 = air_export.StructuredAirV2{ .instructions = instructions[0..] };
    try std.testing.expect(validateSretAggregateMakeRecords(function_type, structured_air_v2));
}
