const std = @import("std");
const enum_facts = @import("zig_air_enum_facts.zig");
const air_export = @import("zig_air_export.zig");
const exported_aggregate_layout_facts = @import("zig_air_exported_aggregate_layout_facts.zig");
const air_model = @import("zig_air_model.zig");
const air_types = @import("zig_air_types.zig");
const sysv_abi = @import("codegen/x86_64/sysv_abi.zig");
const ir = @import("ir.zig");
const target = @import("target.zig");
const type_layout = @import("zig_air_type_layout.zig");

const FunctionType = air_model.FunctionType;
const parseZigType = air_types.parseZigType;

pub const StorePath = struct {
    path: [4]usize = undefined,
    path_len: usize = 0,
    ty: ir.Type,
};

fn x86_64SysVDataLayout() ?target.DataLayout {
    return target.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128") catch null;
}

pub fn isSysVRegisterAggregateCandidate(ty: ir.Type) bool {
    if (ty != .aggregate) return false;
    const classification = sysv_abi.classifyAggregate(ty) catch return false;
    return classification.kind == .register;
}

pub const RegisterAggregateLeafSource = union(enum) {
    param: usize,
    constant_int: i128,
};

pub const RegisterAggregateLeafPlan = struct {
    path_text: []const u8,
    ty: ir.Type,
    source: RegisterAggregateLeafSource,
};

pub const RegisterAggregatePlan = struct {
    leaf_count: usize = 0,
    leaves: [8]RegisterAggregateLeafPlan = undefined,
};

pub fn parseConstIntOperand(instruction: air_export.TypedInstruction, operand_index: usize) ?i128 {
    if (operand_index >= instruction.operands.len) return null;
    const operand = instruction.operands[operand_index];
    if (!std.mem.eql(u8, operand.kind, "const")) return null;
    const text = air_model.operandTextDetail(instruction, operand_index) orelse operand.value;
    const trimmed = std.mem.trim(u8, text, " ");
    if (std.mem.startsWith(u8, trimmed, "<") and std.mem.endsWith(u8, trimmed, ">")) {
        const inner = trimmed[1 .. trimmed.len - 1];
        if (std.mem.indexOfScalar(u8, inner, ',')) |comma| {
            const type_str = std.mem.trim(u8, inner[0..comma], " ");
            const val_str = std.mem.trim(u8, inner[comma + 1 ..], " ");
            if (std.fmt.parseInt(i128, val_str, 0)) |val| {
                return val;
            } else |_| {
                if (enum_facts.enumeratorValue(type_str, val_str)) |val| {
                    return val;
                }
            }
            return null;
        }
    }
    return std.fmt.parseInt(i128, trimmed, 0) catch null;
}

pub fn registerAggregateRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return planRegisterAggregateConstruction(function_type, structured_air_v2) != null;
}

pub fn registerAggregateLeafPaths(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
    leaf_paths: *[8][]const u8,
) bool {
    const plan = planRegisterAggregateConstruction(function_type, structured_air_v2) orelse return false;
    for (plan.leaves[0..plan.leaf_count]) |leaf| {
        switch (leaf.source) {
            .param => |param_index| {
                if (param_index < leaf_paths.len) {
                    leaf_paths[param_index] = leaf.path_text;
                }
            },
            .constant_int => {},
        }
    }
    return true;
}

pub fn registerConstantZeroAggregateRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (function_type.return_type.ir_type != .aggregate) return false;
    if (!isSysVRegisterAggregateCandidate(function_type.return_type.ir_type)) return false;
    if (function_type.params.len != 0) return false;
    if (air_model.typedOpcodeCount(structured_air_v2, "arg") != 0) return false;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret_ptr") != 1) return false;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret_load") != 1) return false;
    const ret_ptr_index = air_model.typedRetPtrIndex(structured_air_v2) orelse return false;
    const store_count = air_model.typedStoreOpcodeCount(structured_air_v2);
    if (store_count == 0) return false;

    var stores_seen: usize = 0;
    for (structured_air_v2.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.opcode, "ret_ptr") or
            std.mem.eql(u8, instruction.opcode, "ret_load") or
            air_model.isTypedFieldPtrDataKind(instruction.data_kind) or
            std.mem.eql(u8, instruction.opcode, "dbg_stmt"))
        {
            continue;
        }
        if (std.mem.eql(u8, instruction.opcode, "store") or std.mem.eql(u8, instruction.opcode, "store_safe")) {
            if (instruction.operands.len != 2) return false;
            if (!isConstZero(instruction, 1)) return false;
            const ptr_inst_index = std.fmt.parseInt(u32, instruction.operands[0].value, 10) catch return false;
            var path: [4]usize = undefined;
            _ = air_model.typedAggregatePointerPath(structured_air_v2, ptr_inst_index, ret_ptr_index, &path) orelse return false;
            stores_seen += 1;
            continue;
        }
        return false;
    }
    return stores_seen == store_count;
}

fn isConstZero(instruction: air_export.TypedInstruction, operand_index: usize) bool {
    if (operand_index >= instruction.operands.len) return false;
    const operand = instruction.operands[operand_index];
    if (!std.mem.eql(u8, operand.kind, "const")) return false;
    if (isZeroString(operand.value)) return true;
    if (air_model.operandTextDetail(instruction, operand_index)) |text| {
        if (isZeroString(text)) return true;
    }
    return false;
}

fn isZeroString(text: []const u8) bool {
    const trimmed = std.mem.trim(u8, text, " ");
    if (std.mem.startsWith(u8, trimmed, "<") and std.mem.endsWith(u8, trimmed, ">")) {
        const inner = trimmed[1 .. trimmed.len - 1];
        if (std.mem.indexOfScalar(u8, inner, ',')) |comma| {
            const val = std.mem.trim(u8, inner[comma + 1 ..], " ");
            return std.mem.eql(u8, val, "0") or std.mem.eql(u8, val, "0.0") or std.mem.eql(u8, val, "0x0");
        }
    }
    return std.mem.eql(u8, trimmed, "0") or std.mem.eql(u8, trimmed, "0.0") or std.mem.eql(u8, trimmed, "0x0");
}

pub fn resolveParamIndex(structured_air_v2: air_export.StructuredAirV2, inst_index: usize) ?usize {
    var cur = inst_index;
    while (true) {
        var found = false;
        for (structured_air_v2.instructions) |inst| {
            if (inst.index == cur) {
                if (std.mem.eql(u8, inst.opcode, "arg")) {
                    var arg_idx: usize = 0;
                    for (structured_air_v2.instructions) |ai| {
                        if (ai.index == cur) return arg_idx;
                        if (std.mem.eql(u8, ai.opcode, "arg")) arg_idx += 1;
                    }
                    return arg_idx;
                } else if (std.mem.eql(u8, inst.opcode, "bit_cast") or
                    std.mem.eql(u8, inst.opcode, "bit_cast_safe") or
                    std.mem.eql(u8, inst.opcode, "bitcast") or
                    std.mem.eql(u8, inst.opcode, "bitcast_safe") or
                    std.mem.eql(u8, inst.opcode, "ptr_cast") or
                    std.mem.eql(u8, inst.opcode, "ptr_cast_safe") or
                    std.mem.eql(u8, inst.opcode, "int_cast") or
                    std.mem.eql(u8, inst.opcode, "int_cast_safe") or
                    std.mem.eql(u8, inst.opcode, "intcast") or
                    std.mem.eql(u8, inst.opcode, "intcast_safe") or
                    std.mem.eql(u8, inst.opcode, "cast"))
                {
                    if (inst.operands.len >= 1 and std.mem.eql(u8, inst.operands[0].kind, "inst")) {
                        cur = std.fmt.parseInt(u32, inst.operands[0].value, 10) catch return null;
                        found = true;
                        break;
                    }
                    if (std.mem.eql(u8, inst.opcode, "ptr_cast") or std.mem.eql(u8, inst.opcode, "ptr_cast_safe")) {
                        for (structured_air_v2.instructions) |other_inst| {
                            if (other_inst.index < cur and std.mem.eql(u8, other_inst.opcode, "arg")) {
                                cur = other_inst.index;
                                found = true;
                                break;
                            }
                        }
                        if (found) break;
                    }
                }
                return null;
            }
        }
        if (!found) return null;
    }
}

fn planRegisterAggregateFromStores(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?RegisterAggregatePlan {
    const layout = x86_64SysVDataLayout() orelse return null;
    const target_ty: ir.Type = blk: {
        if (type_layout.aggregateLayoutPlan(layout, function_type.return_type.ir_type)) |_| {
            break :blk function_type.return_type.ir_type;
        } else |_| {
            const inferred = inferRegisterAggregateConstructionLayout(function_type, structured_air_v2) orelse return null;
            break :blk inferred.ty;
        }
    };
    const is_candidate = isSysVRegisterAggregateCandidate(target_ty);
    if (!is_candidate) return null;
    const plan = type_layout.aggregateLayoutPlan(layout, target_ty) catch return null;
    const leaves = plan.leafSlice();
    if (leaves.len == 0 or leaves.len > 8) return null;

    if (air_model.typedOpcodeCount(structured_air_v2, "arg") != function_type.params.len) return null;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret_ptr") != 1) return null;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret_load") != 1) return null;
    const store_count = air_model.typedStoreOpcodeCount(structured_air_v2);
    const target_field_count = type_layout.fieldCount(target_ty);
    const is_field_mode = (store_count == target_field_count and target_field_count > 0 and store_count != leaves.len);
    if (!is_field_mode and store_count != leaves.len) return null;
    const ret_ptr_index = air_model.typedRetPtrIndex(structured_air_v2) orelse return null;

    if (is_field_mode) {
        var result_plan = RegisterAggregatePlan{ .leaf_count = target_field_count };
        var field_filled: [8]bool = @splat(false);
        var params_used: [8]bool = @splat(false);

        for (structured_air_v2.instructions) |instruction| {
            if (!std.mem.eql(u8, instruction.opcode, "store") and !std.mem.eql(u8, instruction.opcode, "store_safe")) continue;
            if (instruction.operands.len != 2) return null;

            const ptr_inst_index = std.fmt.parseInt(u32, instruction.operands[0].value, 10) catch return null;
            var path: [4]usize = undefined;
            const path_len = air_model.typedAggregatePointerPath(structured_air_v2, ptr_inst_index, ret_ptr_index, &path) orelse return null;
            if (path_len != 1) return null;
            const field_idx = path[0];
            if (field_idx >= target_field_count or field_filled[field_idx]) return null;

            const field_ty = type_layout.fieldType(target_ty, field_idx) orelse return null;
            const operand_type = parseZigType(instruction.operands[1].type_text) orelse return null;
            if (!operand_type.ir_type.eql(field_ty)) return null;

            const path_text = air_model.aggregateIndexPathText(path[0..path_len]) orelse return null;

            if (std.mem.eql(u8, instruction.operands[1].kind, "inst")) {
                const raw_inst_index = std.fmt.parseInt(u32, instruction.operands[1].value, 10) catch return null;
                const arg_inst_index = resolveParamIndex(structured_air_v2, raw_inst_index) orelse return null;
                const param_ty = function_type.params[arg_inst_index].ir_type;
                const types_compatible = param_ty.eql(field_ty) or (param_ty == .int and field_ty == .int and param_ty.int >= field_ty.int);
                if (!types_compatible) return null;
                params_used[arg_inst_index] = true;
                result_plan.leaves[field_idx] = .{
                    .path_text = path_text,
                    .ty = field_ty,
                    .source = .{ .param = arg_inst_index },
                };
            } else if (std.mem.eql(u8, instruction.operands[1].kind, "const")) {
                const const_val = parseConstIntOperand(instruction, 1) orelse return null;
                result_plan.leaves[field_idx] = .{
                    .path_text = path_text,
                    .ty = field_ty,
                    .source = .{ .constant_int = const_val },
                };
            } else return null;

            field_filled[field_idx] = true;
        }

        for (0..target_field_count) |i| {
            if (!field_filled[i]) return null;
        }
        for (0..function_type.params.len) |p| {
            if (!params_used[p]) return null;
        }
        return result_plan;
    }

    var result_plan = RegisterAggregatePlan{ .leaf_count = leaves.len };
    var leaf_filled: [8]bool = @splat(false);
    var params_used: [8]bool = @splat(false);

    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "store") and !std.mem.eql(u8, instruction.opcode, "store_safe")) continue;
        if (instruction.operands.len != 2) return null;

        const ptr_inst_index = std.fmt.parseInt(u32, instruction.operands[0].value, 10) catch return null;
        var path: [4]usize = undefined;
        var path_len = air_model.typedAggregatePointerPath(structured_air_v2, ptr_inst_index, ret_ptr_index, &path) orelse return null;

        var current_field_ty = target_ty;
        for (path[0..path_len]) |p_idx| {
            current_field_ty = type_layout.fieldType(current_field_ty, p_idx) orelse return null;
        }
        while (path_len < path.len) {
            const norm = type_layout.normalizeAggregateType(current_field_ty);
            if (!type_layout.isAggregateType(norm)) break;
            if (type_layout.fieldCount(norm) != 1) break;
            current_field_ty = type_layout.fieldType(norm, 0) orelse break;
            path[path_len] = 0;
            path_len += 1;
        }

        const target_leaf = type_layout.leafAtIndexPath(layout, target_ty, path[0..path_len]) orelse return null;

        var matched_leaf_index: ?usize = null;
        for (leaves, 0..) |leaf, i| {
            if (leaf.offset == target_leaf.offset and leaf.ty.eql(target_leaf.ty)) {
                matched_leaf_index = i;
                break;
            }
        }
        const leaf_index = matched_leaf_index orelse return null;
        if (leaf_filled[leaf_index]) return null;

        const operand_type = parseZigType(instruction.operands[1].type_text) orelse return null;
        if (!operand_type.ir_type.eql(target_leaf.ty)) return null;

        const path_text = air_model.aggregateIndexPathText(path[0..path_len]) orelse return null;

        if (std.mem.eql(u8, instruction.operands[1].kind, "inst")) {
            const raw_inst_index = std.fmt.parseInt(u32, instruction.operands[1].value, 10) catch return null;
            const arg_inst_index = resolveParamIndex(structured_air_v2, raw_inst_index) orelse return null;
            const param_ty = function_type.params[arg_inst_index].ir_type;
            const types_compatible = param_ty.eql(target_leaf.ty) or (param_ty == .int and target_leaf.ty == .int and param_ty.int >= target_leaf.ty.int);
            if (!types_compatible) return null;
            params_used[arg_inst_index] = true;
            result_plan.leaves[leaf_index] = .{
                .path_text = path_text,
                .ty = target_leaf.ty,
                .source = .{ .param = arg_inst_index },
            };

        } else if (std.mem.eql(u8, instruction.operands[1].kind, "const")) {
            const const_val = parseConstIntOperand(instruction, 1) orelse return null;
            result_plan.leaves[leaf_index] = .{
                .path_text = path_text,
                .ty = target_leaf.ty,
                .source = .{ .constant_int = const_val },
            };
        } else return null;
        leaf_filled[leaf_index] = true;
    }

    for (0..leaves.len) |i| {
        if (!leaf_filled[i]) return null;
    }
    for (0..function_type.params.len) |p| {
        if (!params_used[p]) return null;
    }
    return result_plan;
}

fn planRegisterAggregateFromAggregateInit(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?RegisterAggregatePlan {
    var leaf_paths: [8][]const u8 = undefined;
    if (!registerAggregateLeafPathsFromAggregateInit(function_type, structured_air_v2, &leaf_paths)) return null;
    var plan = RegisterAggregatePlan{ .leaf_count = function_type.params.len };
    for (0..function_type.params.len) |i| {
        plan.leaves[i] = .{
            .path_text = leaf_paths[i],
            .ty = function_type.params[i].ir_type,
            .source = .{ .param = i },
        };
    }
    return plan;
}

pub fn planRegisterAggregateConstruction(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?RegisterAggregatePlan {
    if (function_type.return_type.ir_type != .aggregate) return null;
    if (planRegisterAggregateFromStores(function_type, structured_air_v2)) |plan| return plan;
    if (planRegisterAggregateFromAggregateInit(function_type, structured_air_v2)) |plan| return plan;
    return null;
}

fn registerAggregateLeafPathsFromAggregateInit(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
    leaf_paths: *[8][]const u8,
) bool {
    if (!isSysVRegisterAggregateCandidate(function_type.return_type.ir_type)) return false;
    if (air_model.typedOpcodeCount(structured_air_v2, "arg") != function_type.params.len) return false;
    if (air_model.typedOpcodeCount(structured_air_v2, "aggregate_init") != 1) return false;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret") != 1) return false;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret_ptr") != 0) return false;
    if (air_model.typedStoreOpcodeCount(structured_air_v2) != 0) return false;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret_load") != 0) return false;

    const aggregate_init = air_model.singleInstructionByOpcode(structured_air_v2, "aggregate_init") orelse return false;
    if (aggregate_init.operands.len != function_type.params.len) return false;
    const init_type = parseZigType(aggregate_init.result_type) orelse return false;
    if (!init_type.ir_type.eql(function_type.return_type.ir_type)) return false;

    const ret = air_model.singleInstructionByOpcode(structured_air_v2, "ret") orelse return false;
    if (ret.operands.len != 1) return false;
    if (!std.mem.eql(u8, ret.operands[0].kind, "inst")) return false;
    const ret_inst_index = std.fmt.parseInt(u32, ret.operands[0].value, 10) catch return false;
    if (ret_inst_index != aggregate_init.index) return false;

    const layout = x86_64SysVDataLayout() orelse return false;
    const plan = type_layout.aggregateLayoutPlan(layout, function_type.return_type.ir_type) catch return false;
    if (plan.field_count != function_type.params.len) return false;
    const leaves = plan.leafSlice();
    if (leaves.len != function_type.params.len) return false;

    for (aggregate_init.operands, function_type.params, leaves, 0..) |operand, param, leaf, index| {
        if (!std.mem.eql(u8, operand.kind, "inst")) return false;
        const arg_inst_index = std.fmt.parseInt(u32, operand.value, 10) catch return false;
        if (arg_inst_index != index) return false;
        const operand_type = parseZigType(operand.type_text) orelse return false;
        if (!operand_type.ir_type.eql(param.ir_type)) return false;
        if (!leaf.ty.eql(param.ir_type)) return false;
        leaf_paths[index] = air_model.aggregateIndexPathText(&.{index}) orelse return false;
    }
    return true;
}

pub fn inferRegisterAggregateConstructionLayout(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?type_layout.AggregateLayoutSummary {
    if (function_type.return_type.ir_type != .aggregate) return null;
    if (air_model.typedOpcodeCount(structured_air_v2, "arg") != function_type.params.len) return null;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret_ptr") != 1) return null;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret_load") != 1) return null;
    const store_count = air_model.typedStoreOpcodeCount(structured_air_v2);
    if (store_count == 0 or store_count > 8) return null;
    const ret_ptr_index = air_model.typedRetPtrIndex(structured_air_v2) orelse return null;
    var stores: [8]StorePath = undefined;
    var stores_seen: usize = 0;
    var params_used: [8]bool = @splat(false);
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "store") and !std.mem.eql(u8, instruction.opcode, "store_safe")) continue;
        if (stores_seen >= stores.len) return null;
        if (instruction.operands.len != 2) return null;
        const operand_type = parseZigType(instruction.operands[1].type_text) orelse return null;
        if (std.mem.eql(u8, instruction.operands[1].kind, "inst")) {
            const raw_inst_index = std.fmt.parseInt(u32, instruction.operands[1].value, 10) catch return null;
            const arg_inst_index = resolveParamIndex(structured_air_v2, raw_inst_index) orelse return null;
            if (arg_inst_index >= function_type.params.len) return null;
            if (!function_type.params[arg_inst_index].ir_type.eql(operand_type.ir_type)) return null;
            params_used[arg_inst_index] = true;
        } else if (std.mem.eql(u8, instruction.operands[1].kind, "const")) {
            if (parseConstIntOperand(instruction, 1) == null) return null;
        } else return null;
        const ptr_inst_index = std.fmt.parseInt(u32, instruction.operands[0].value, 10) catch return null;
        var path: [4]usize = undefined;
        const path_len = air_model.typedAggregatePointerPath(structured_air_v2, ptr_inst_index, ret_ptr_index, &path) orelse return null;
        stores[stores_seen] = .{
            .path = path,
            .path_len = path_len,
            .ty = operand_type.ir_type,
        };
        stores_seen += 1;
    }
    for (0..function_type.params.len) |p| {
        if (!params_used[p]) return null;
    }
    if (stores_seen != store_count) return null;
    const inferred_ty = inferAggregateTypeFromStorePaths(stores[0..stores_seen]) orelse return null;
    return type_layout.summarizeInferredAggregateLayout(function_type.return_type.ir_type.aggregate, inferred_ty, .{
        .construction = true,
        .store = true,
        .load = true,
    });
}

pub fn inferAggregateTypeFromStorePaths(stores: []const StorePath) ?ir.Type {
    var max_top: usize = 0;
    for (stores) |store| {
        if (store.path_len == 0 or store.path_len > 2) return null;
        max_top = @max(max_top, store.path[0]);
    }
    var aggregate_text: std.ArrayList(u8) = .empty;
    aggregate_text.appendSlice(std.heap.page_allocator, "{ ") catch return null;
    var top_index: usize = 0;
    while (top_index <= max_top) : (top_index += 1) {
        if (top_index != 0) aggregate_text.appendSlice(std.heap.page_allocator, ", ") catch return null;
        const direct = storeForPath(stores, &.{top_index});
        if (direct) |store| {
            appendIrTypeText(&aggregate_text, store.ty) catch return null;
            continue;
        }
        const nested = appendNestedAggregateType(&aggregate_text, stores, top_index, max_top == 0) orelse return null;
        _ = nested;
    }
    aggregate_text.appendSlice(std.heap.page_allocator, " }") catch return null;
    return .{ .aggregate = aggregate_text.toOwnedSlice(std.heap.page_allocator) catch return null };
}

fn appendNestedAggregateType(aggregate_text: *std.ArrayList(u8), stores: []const StorePath, top_index: usize, prefer_array: bool) ?void {
    var max_child: usize = 0;
    var count: usize = 0;
    var first_ty: ?ir.Type = null;
    var same_ty = true;
    for (stores) |store| {
        if (store.path_len != 2 or store.path[0] != top_index) continue;
        max_child = @max(max_child, store.path[1]);
        count += 1;
        if (first_ty) |ty| {
            if (!ty.eql(store.ty)) same_ty = false;
        } else {
            first_ty = store.ty;
        }
    }
    if (count == 0 or count != max_child + 1) return null;
    if (prefer_array and same_ty and count > 1) {
        const ty = first_ty orelse return null;
        const count_text = std.fmt.allocPrint(std.heap.page_allocator, "[{} x ", .{count}) catch return null;
        aggregate_text.appendSlice(std.heap.page_allocator, count_text) catch return null;
        appendIrTypeText(aggregate_text, ty) catch return null;
        aggregate_text.appendSlice(std.heap.page_allocator, "]") catch return null;
        return;
    }
    aggregate_text.appendSlice(std.heap.page_allocator, "{ ") catch return null;
    var child_index: usize = 0;
    while (child_index <= max_child) : (child_index += 1) {
        if (child_index != 0) aggregate_text.appendSlice(std.heap.page_allocator, ", ") catch return null;
        const store = storeForPath(stores, &.{ top_index, child_index }) orelse return null;
        appendIrTypeText(aggregate_text, store.ty) catch return null;
    }
    aggregate_text.appendSlice(std.heap.page_allocator, " }") catch return null;
}

fn storeForPath(stores: []const StorePath, path: []const usize) ?StorePath {
    for (stores) |store| {
        if (store.path_len != path.len) continue;
        var matches = true;
        for (path, 0..) |path_index, index| {
            if (store.path[index] != path_index) {
                matches = false;
                break;
            }
        }
        if (matches) return store;
    }
    return null;
}

fn appendIrTypeText(aggregate_text: *std.ArrayList(u8), ty: ir.Type) !void {
    switch (ty) {
        .void => try aggregate_text.appendSlice(std.heap.page_allocator, "void"),
        .int => |bits| {
            const text = try std.fmt.allocPrint(std.heap.page_allocator, "i{}", .{bits});
            try aggregate_text.appendSlice(std.heap.page_allocator, text);
        },
        .half => try aggregate_text.appendSlice(std.heap.page_allocator, "half"),
        .float => try aggregate_text.appendSlice(std.heap.page_allocator, "float"),
        .double => try aggregate_text.appendSlice(std.heap.page_allocator, "double"),
        .x86_fp80 => try aggregate_text.appendSlice(std.heap.page_allocator, "x86_fp80"),
        .fp128 => try aggregate_text.appendSlice(std.heap.page_allocator, "fp128"),
        .metadata => try aggregate_text.appendSlice(std.heap.page_allocator, "metadata"),
        .ptr => try aggregate_text.appendSlice(std.heap.page_allocator, "ptr"),
        .aggregate => |text| try aggregate_text.appendSlice(std.heap.page_allocator, text),
        .vector => return error.UnsupportedAir,
    }
}

fn testInstOperand(value: []const u8, type_text: []const u8) air_export.TypedOperand {
    return .{ .kind = "inst", .value = value, .type_text = type_text };
}

fn testConstOperand(value: []const u8, type_text: []const u8) air_export.TypedOperand {
    return .{ .kind = "const", .value = value, .type_text = type_text };
}

test "aggregate construction infers simple register aggregate layout from typed AIR stores" {
    var params = [_]air_model.ZigType{
        .{ .ir_type = .{ .int = 32 } },
        .{ .ir_type = .{ .int = 32 } },
    };
    const function_type = FunctionType{
        .params = params[0..],
        .return_type = .{ .ir_type = .{ .aggregate = "{ i32, i32 }" } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    const field0_details = [_]air_export.TypedDetail{.{ .key = "field_index", .value = "0" }};
    const field1_details = [_]air_export.TypedDetail{.{ .key = "field_index", .value = "1" }};
    const field0_ops = [_]air_export.TypedOperand{testInstOperand("2", "*Pair")};
    const field1_ops = [_]air_export.TypedOperand{testInstOperand("2", "*Pair")};
    const store0_ops = [_]air_export.TypedOperand{
        testInstOperand("3", "*i32"),
        testInstOperand("0", "i32"),
    };
    const store1_ops = [_]air_export.TypedOperand{
        testInstOperand("5", "*i32"),
        testInstOperand("1", "i32"),
    };
    const ret_load_ops = [_]air_export.TypedOperand{testInstOperand("2", "*Pair")};
    var instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "i32", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "arg", .result_type = "i32", .data_kind = "arg", .operands = &.{} },
        .{ .index = 2, .opcode = "ret_ptr", .result_type = "*Pair", .data_kind = "ret_ptr", .operands = &.{} },
        .{ .index = 3, .opcode = "struct_field_ptr_index_0", .result_type = "*i32", .data_kind = "field_ptr", .operands = @constCast(&field0_ops), .details = @constCast(&field0_details) },
        .{ .index = 4, .opcode = "store", .result_type = "void", .data_kind = "bin_op", .operands = @constCast(&store0_ops) },
        .{ .index = 5, .opcode = "struct_field_ptr_index_1", .result_type = "*i32", .data_kind = "field_ptr", .operands = @constCast(&field1_ops), .details = @constCast(&field1_details) },
        .{ .index = 6, .opcode = "store", .result_type = "void", .data_kind = "bin_op", .operands = @constCast(&store1_ops) },
        .{ .index = 7, .opcode = "ret_load", .result_type = "Pair", .data_kind = "ret_load", .operands = @constCast(&ret_load_ops) },
    };
    const structured_air_v2 = air_export.StructuredAirV2{ .instructions = instructions[0..] };
    const summary = inferRegisterAggregateConstructionLayout(function_type, structured_air_v2).?;
    try std.testing.expect(summary.ty.eql(.{ .aggregate = "{ i32, i32 }" }));
    try std.testing.expectEqual(type_layout.AggregateLayoutSource.inference, summary.source);
    try std.testing.expect(registerAggregateRecords(function_type, structured_air_v2));

    const unknown_nominal_function_type = FunctionType{
        .params = params[0..],
        .return_type = .{ .ir_type = .{ .aggregate = "%AdHocPair" } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    try std.testing.expect(registerAggregateRecords(unknown_nominal_function_type, structured_air_v2));
}

test "aggregate construction accepts direct aggregate_init return" {
    const facts = [_]exported_aggregate_layout_facts.Fact{
        .{ .nominal_type_name = "sort.block.Range", .aggregate_text = "{ i64, i64 }" },
    };
    const previous_provider = exported_aggregate_layout_facts.active_provider;
    exported_aggregate_layout_facts.setActiveProvider(.{ .facts = facts[0..] });
    defer exported_aggregate_layout_facts.setActiveProvider(previous_provider);

    var params = [_]air_model.ZigType{
        .{ .ir_type = .{ .int = 64 } },
        .{ .ir_type = .{ .int = 64 } },
    };
    const function_type = FunctionType{
        .params = params[0..],
        .return_type = .{ .ir_type = .{ .aggregate = "{ i64, i64 }" } },
        .c_calling_convention = false,
        .non_default_calling_convention = false,
    };
    const init_ops = [_]air_export.TypedOperand{
        testInstOperand("0", "usize"),
        testInstOperand("1", "usize"),
    };
    const ret_ops = [_]air_export.TypedOperand{testInstOperand("3", "sort.block.Range")};
    var instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "usize", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "arg", .result_type = "usize", .data_kind = "arg", .operands = &.{} },
        .{ .index = 2, .opcode = "dbg_stmt", .result_type = "void", .data_kind = "opaque", .operands = &.{} },
        .{ .index = 3, .opcode = "aggregate_init", .result_type = "sort.block.Range", .data_kind = "aggregate_init", .operands = @constCast(&init_ops) },
        .{ .index = 4, .opcode = "dbg_stmt", .result_type = "void", .data_kind = "opaque", .operands = &.{} },
        .{ .index = 5, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = @constCast(&ret_ops) },
    };
    const structured_air_v2 = air_export.StructuredAirV2{ .instructions = instructions[0..] };
    var leaf_paths: [8][]const u8 = undefined;
    try std.testing.expect(registerAggregateLeafPaths(function_type, structured_air_v2, &leaf_paths));
    try std.testing.expectEqualStrings("0", leaf_paths[0]);
    try std.testing.expectEqualStrings("1", leaf_paths[1]);
    try std.testing.expect(registerAggregateRecords(function_type, structured_air_v2));
}

test "aggregate construction infers array leaf layout from typed AIR element stores" {
    var params = [_]air_model.ZigType{
        .{ .ir_type = .float },
        .{ .ir_type = .float },
        .{ .ir_type = .float },
        .{ .ir_type = .float },
    };
    const function_type = FunctionType{
        .params = params[0..],
        .return_type = .{ .ir_type = .{ .aggregate = "{ [4 x float] }" } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    const field_details = [_]air_export.TypedDetail{.{ .key = "field_index", .value = "0" }};
    const field_ops = [_]air_export.TypedOperand{testInstOperand("4", "*FloatArray")};
    const elem0_ops = [_]air_export.TypedOperand{ testInstOperand("5", "*[4]f32"), testConstOperand("<usize, 0>", "usize") };
    const elem1_ops = [_]air_export.TypedOperand{ testInstOperand("5", "*[4]f32"), testConstOperand("<usize, 1>", "usize") };
    const elem2_ops = [_]air_export.TypedOperand{ testInstOperand("5", "*[4]f32"), testConstOperand("<usize, 2>", "usize") };
    const elem3_ops = [_]air_export.TypedOperand{ testInstOperand("5", "*[4]f32"), testConstOperand("<usize, 3>", "usize") };
    const store0_ops = [_]air_export.TypedOperand{ testInstOperand("6", "*f32"), testInstOperand("0", "f32") };
    const store1_ops = [_]air_export.TypedOperand{ testInstOperand("8", "*f32"), testInstOperand("1", "f32") };
    const store2_ops = [_]air_export.TypedOperand{ testInstOperand("10", "*f32"), testInstOperand("2", "f32") };
    const store3_ops = [_]air_export.TypedOperand{ testInstOperand("12", "*f32"), testInstOperand("3", "f32") };
    const ret_load_ops = [_]air_export.TypedOperand{testInstOperand("4", "*FloatArray")};
    var instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "f32", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "arg", .result_type = "f32", .data_kind = "arg", .operands = &.{} },
        .{ .index = 2, .opcode = "arg", .result_type = "f32", .data_kind = "arg", .operands = &.{} },
        .{ .index = 3, .opcode = "arg", .result_type = "f32", .data_kind = "arg", .operands = &.{} },
        .{ .index = 4, .opcode = "ret_ptr", .result_type = "*FloatArray", .data_kind = "ret_ptr", .operands = &.{} },
        .{ .index = 5, .opcode = "struct_field_ptr_index_0", .result_type = "*[4]f32", .data_kind = "field_ptr", .operands = @constCast(&field_ops), .details = @constCast(&field_details) },
        .{ .index = 6, .opcode = "ptr_elem_ptr", .result_type = "*f32", .data_kind = "bin_ty_pl", .operands = @constCast(&elem0_ops) },
        .{ .index = 7, .opcode = "store", .result_type = "void", .data_kind = "bin_op", .operands = @constCast(&store0_ops) },
        .{ .index = 8, .opcode = "ptr_elem_ptr", .result_type = "*f32", .data_kind = "bin_ty_pl", .operands = @constCast(&elem1_ops) },
        .{ .index = 9, .opcode = "store", .result_type = "void", .data_kind = "bin_op", .operands = @constCast(&store1_ops) },
        .{ .index = 10, .opcode = "ptr_elem_ptr", .result_type = "*f32", .data_kind = "bin_ty_pl", .operands = @constCast(&elem2_ops) },
        .{ .index = 11, .opcode = "store", .result_type = "void", .data_kind = "bin_op", .operands = @constCast(&store2_ops) },
        .{ .index = 12, .opcode = "ptr_elem_ptr", .result_type = "*f32", .data_kind = "bin_ty_pl", .operands = @constCast(&elem3_ops) },
        .{ .index = 13, .opcode = "store", .result_type = "void", .data_kind = "bin_op", .operands = @constCast(&store3_ops) },
        .{ .index = 14, .opcode = "ret_load", .result_type = "FloatArray", .data_kind = "ret_load", .operands = @constCast(&ret_load_ops) },
    };
    const structured_air_v2 = air_export.StructuredAirV2{ .instructions = instructions[0..] };
    const summary = inferRegisterAggregateConstructionLayout(function_type, structured_air_v2).?;
    try std.testing.expect(summary.ty.eql(.{ .aggregate = "{ [4 x float] }" }));
    try std.testing.expect(registerAggregateRecords(function_type, structured_air_v2));
}

test "constant zero register aggregate records matches BiasedFp(f64).zero shape" {
    const function_type = FunctionType{
        .params = &.{},
        .return_type = .{ .ir_type = .{ .aggregate = "{ i64, i32 }" } },
        .c_calling_convention = false,
        .non_default_calling_convention = false,
    };
    const field0_ops = [_]air_export.TypedOperand{testInstOperand("0", "*fmt.parse_float.common.BiasedFp(f64)")};
    const field1_ops = [_]air_export.TypedOperand{testInstOperand("0", "*fmt.parse_float.common.BiasedFp(f64)")};
    const store0_ops = [_]air_export.TypedOperand{ testInstOperand("1", "*u64"), testConstOperand("<u64, 0>", "u64") };
    const store1_ops = [_]air_export.TypedOperand{ testInstOperand("3", "*i32"), testConstOperand("<i32, 0>", "i32") };
    const store0_details = [_]air_export.TypedDetail{.{ .key = "operand1_text", .value = "<u64, 0>" }};
    const store1_details = [_]air_export.TypedDetail{.{ .key = "operand1_text", .value = "<i32, 0>" }};
    const field0_details = [_]air_export.TypedDetail{.{ .key = "field_index", .value = "0" }};
    const field1_details = [_]air_export.TypedDetail{.{ .key = "field_index", .value = "1" }};
    var instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "ret_ptr", .result_type = "*fmt.parse_float.common.BiasedFp(f64)", .data_kind = "ret_ptr", .operands = &.{} },
        .{ .index = 1, .opcode = "struct_field_ptr_index_0", .result_type = "*u64", .data_kind = "field_ptr", .operands = @constCast(&field0_ops), .details = @constCast(&field0_details) },
        .{ .index = 2, .opcode = "store", .result_type = "void", .data_kind = "store", .operands = @constCast(&store0_ops), .details = @constCast(&store0_details) },
        .{ .index = 3, .opcode = "struct_field_ptr_index_1", .result_type = "*i32", .data_kind = "field_ptr", .operands = @constCast(&field1_ops), .details = @constCast(&field1_details) },
        .{ .index = 4, .opcode = "store", .result_type = "void", .data_kind = "store", .operands = @constCast(&store1_ops), .details = @constCast(&store1_details) },
        .{ .index = 5, .opcode = "ret_load", .result_type = "noreturn", .data_kind = "ret_load", .operands = &.{} },
    };
    const structured_air_v2 = air_export.StructuredAirV2{ .instructions = instructions[0..] };
    try std.testing.expect(registerConstantZeroAggregateRecords(function_type, structured_air_v2));
}

test "mixed param and constant register aggregate records matches PartIterator.initOne shape" {
    var params = [_]air_model.ZigType{
        .{ .ir_type = .{ .int = 32 } },
    };
    const function_type = FunctionType{
        .params = params[0..],
        .return_type = .{ .ir_type = .{ .aggregate = "{ i32, i5 }" } },
        .c_calling_convention = false,
        .non_default_calling_convention = false,
    };
    const field0_ops = [_]air_export.TypedOperand{testInstOperand("2", "*PartIterator")};
    const field1_ops = [_]air_export.TypedOperand{testInstOperand("2", "*PartIterator")};
    const store0_ops = [_]air_export.TypedOperand{ testInstOperand("3", "*i32"), testInstOperand("0", "i32") };
    const store1_ops = [_]air_export.TypedOperand{ testInstOperand("5", "*u5"), testConstOperand("1", "u5") };
    const store1_details = [_]air_export.TypedDetail{.{ .key = "operand1_text", .value = "<u5, 1>" }};
    const field0_details = [_]air_export.TypedDetail{.{ .key = "field_index", .value = "0" }};
    const field1_details = [_]air_export.TypedDetail{.{ .key = "field_index", .value = "1" }};
    var instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "i32", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "dbg_stmt", .result_type = "void", .data_kind = "opaque", .operands = &.{} },
        .{ .index = 2, .opcode = "ret_ptr", .result_type = "*PartIterator", .data_kind = "ret_ptr", .operands = &.{} },
        .{ .index = 3, .opcode = "struct_field_ptr_index_0", .result_type = "*i32", .data_kind = "field_ptr", .operands = @constCast(&field0_ops), .details = @constCast(&field0_details) },
        .{ .index = 4, .opcode = "store", .result_type = "void", .data_kind = "store", .operands = @constCast(&store0_ops) },
        .{ .index = 5, .opcode = "struct_field_ptr_index_1", .result_type = "*u5", .data_kind = "field_ptr", .operands = @constCast(&field1_ops), .details = @constCast(&field1_details) },
        .{ .index = 6, .opcode = "store", .result_type = "void", .data_kind = "store", .operands = @constCast(&store1_ops), .details = @constCast(&store1_details) },
        .{ .index = 7, .opcode = "dbg_stmt", .result_type = "void", .data_kind = "opaque", .operands = &.{} },
        .{ .index = 8, .opcode = "ret_load", .result_type = "noreturn", .data_kind = "ret_load", .operands = &.{} },
    };
    const structured_air_v2 = air_export.StructuredAirV2{ .instructions = instructions[0..] };
    const plan = planRegisterAggregateConstruction(function_type, structured_air_v2).?;
    try std.testing.expectEqual(@as(usize, 2), plan.leaf_count);
    try std.testing.expectEqual(RegisterAggregateLeafSource{ .param = 0 }, plan.leaves[0].source);
    try std.testing.expectEqual(RegisterAggregateLeafSource{ .constant_int = 1 }, plan.leaves[1].source);
    try std.testing.expect(registerAggregateRecords(function_type, structured_air_v2));
}
