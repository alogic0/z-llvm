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
    if (function_type.params.len == 0 or function_type.params.len > leaf_paths.len) return false;
    const inferred_summary = inferRegisterAggregateConstructionLayout(function_type, structured_air_v2) orelse return false;
    if (!isSysVRegisterAggregateCandidate(inferred_summary.ty)) return false;
    const layout = x86_64SysVDataLayout() orelse return false;
    const plan = type_layout.aggregateLayoutPlan(layout, inferred_summary.ty) catch return false;
    const plan_summary = type_layout.summarizeInferredAggregateLayout(function_type.return_type.ir_type.aggregate, plan.ty, .{
        .construction = true,
        .store = true,
        .load = true,
    });
    if (!type_layout.aggregateLayoutSummariesMatch(inferred_summary, plan_summary)) return false;
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

pub fn inferRegisterAggregateConstructionLayout(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?type_layout.AggregateLayoutSummary {
    if (function_type.return_type.ir_type != .aggregate) return null;
    if (function_type.params.len == 0) return null;
    if (air_model.typedOpcodeCount(structured_air_v2, "arg") != function_type.params.len) return null;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret_ptr") != 1) return null;
    if (air_model.typedStoreOpcodeCount(structured_air_v2) != function_type.params.len) return null;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret_load") != 1) return null;
    const ret_ptr_index = air_model.typedRetPtrIndex(structured_air_v2) orelse return null;
    var stores: [8]StorePath = undefined;
    if (function_type.params.len > stores.len) return null;
    var store_count: usize = 0;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "store") and !std.mem.eql(u8, instruction.opcode, "store_safe")) continue;
        if (store_count >= function_type.params.len) return null;
        if (instruction.operands.len != 2) return null;
        if (!std.mem.eql(u8, instruction.operands[1].kind, "inst")) return null;
        const arg_inst_index = std.fmt.parseInt(u32, instruction.operands[1].value, 10) catch return null;
        if (arg_inst_index >= function_type.params.len) return null;
        const operand_type = parseZigType(instruction.operands[1].type_text) orelse return null;
        if (!function_type.params[arg_inst_index].ir_type.eql(operand_type.ir_type)) return null;
        const ptr_inst_index = std.fmt.parseInt(u32, instruction.operands[0].value, 10) catch return null;
        var path: [4]usize = undefined;
        const path_len = air_model.typedAggregatePointerPath(structured_air_v2, ptr_inst_index, ret_ptr_index, &path) orelse return null;
        stores[store_count] = .{
            .path = path,
            .path_len = path_len,
            .ty = operand_type.ir_type,
        };
        store_count += 1;
    }
    if (store_count != function_type.params.len) return null;
    const inferred_ty = inferAggregateTypeFromStorePaths(stores[0..store_count]) orelse return null;
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
