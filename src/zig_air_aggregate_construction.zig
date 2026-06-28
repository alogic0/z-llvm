const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_model = @import("zig_air_model.zig");
const air_types = @import("zig_air_types.zig");
const sysv_abi = @import("codegen/x86_64/sysv_abi.zig");
const ir = @import("ir.zig");
const target = @import("target.zig");
const type_layout = @import("zig_air_type_layout.zig");

const FunctionType = air_model.FunctionType;
const parseZigType = air_types.parseZigType;

fn x86_64SysVDataLayout() ?target.DataLayout {
    return target.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128") catch null;
}

pub fn isSysVRegisterAggregateCandidate(ty: ir.Type) bool {
    if (ty != .aggregate) return false;
    const classification = sysv_abi.classifyAggregate(ty) catch return false;
    return classification.kind == .register;
}

pub fn registerAggregateRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    var leaf_paths: [8][]const u8 = undefined;
    return registerAggregateLeafPaths(function_type, structured_air_v2, &leaf_paths);
}

pub fn registerAggregateLeafPaths(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
    leaf_paths: *[8][]const u8,
) bool {
    if (function_type.return_type.ir_type != .aggregate) return false;
    if (!isSysVRegisterAggregateCandidate(function_type.return_type.ir_type)) return false;
    if (function_type.params.len == 0 or function_type.params.len > leaf_paths.len) return false;
    const layout = x86_64SysVDataLayout() orelse return false;
    const plan = type_layout.aggregateLayoutPlan(layout, function_type.return_type.ir_type) catch return false;
    const leaves = plan.leafSlice();
    if (leaves.len != function_type.params.len) return false;
    for (leaves, function_type.params) |leaf, param| {
        if (!leaf.ty.eql(param.ir_type)) return false;
    }
    if (air_model.typedOpcodeCount(structured_air_v2, "arg") != function_type.params.len) return false;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret_ptr") != 1) return false;
    if (air_model.typedStoreOpcodeCount(structured_air_v2) != function_type.params.len) return false;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret_load") != 1) return false;
    const ret_ptr_index = air_model.typedRetPtrIndex(structured_air_v2) orelse return false;
    var store_index: usize = 0;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "store") and !std.mem.eql(u8, instruction.opcode, "store_safe")) continue;
        if (store_index >= function_type.params.len) return false;
        if (instruction.operands.len != 2) return false;
        if (!std.mem.eql(u8, instruction.operands[1].kind, "inst")) return false;
        const arg_inst_index = std.fmt.parseInt(u32, instruction.operands[1].value, 10) catch return false;
        if (arg_inst_index != store_index) return false;
        const operand_type = parseZigType(instruction.operands[1].type_text) orelse return false;
        if (!function_type.params[store_index].ir_type.eql(operand_type.ir_type)) return false;
        const ptr_inst_index = std.fmt.parseInt(u32, instruction.operands[0].value, 10) catch return false;
        var path: [4]usize = undefined;
        const path_len = air_model.typedAggregatePointerPath(structured_air_v2, ptr_inst_index, ret_ptr_index, &path) orelse return false;
        leaf_paths[store_index] = air_model.aggregateIndexPathText(path[0..path_len]) orelse return false;
        store_index += 1;
    }
    return store_index == function_type.params.len;
}
