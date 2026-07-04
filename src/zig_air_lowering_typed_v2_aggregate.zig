const std = @import("std");
const air_aggregate_construction = @import("zig_air_aggregate_construction.zig");
const air_aggregate_copy = @import("zig_air_aggregate_copy.zig");
const air_export = @import("zig_air_export.zig");
const air_model = @import("zig_air_model.zig");
const air_types = @import("zig_air_types.zig");
const ir = @import("ir.zig");
const type_layout = @import("zig_air_type_layout.zig");

const FunctionType = air_model.FunctionType;
const collectAggregateCopyLeaves = air_aggregate_copy.collectAggregateCopyLeaves;
const validateSretAggregateMakeRecords = air_aggregate_copy.validateSretAggregateMakeRecords;
const validateSretAggregateCopyRecords = air_aggregate_copy.validateSretAggregateCopyRecords;
const validateSretAggregateCallWrapperRecords = air_aggregate_copy.validateSretAggregateCallWrapperRecords;
const sretAggregateFieldWrapper = air_aggregate_copy.sretAggregateFieldWrapper;
const isSysVRegisterAggregateCandidate = air_aggregate_construction.isSysVRegisterAggregateCandidate;
const typedDetail = air_model.detail;
const typedCallee = air_model.callee;
const typedSingleInstructionByOpcode = air_model.singleInstructionByOpcode;
const shortFunctionName = air_model.shortFunctionName;
const ownPrint = air_model.ownPrint;
const irCallingConvention = air_model.irCallingConvention;
const parseZigType = air_types.parseZigType;

fn lowerRegisterAggregateMake(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !ir.Function {
    const aggregate_ty = function_type.return_type.ir_type;
    if (!isSysVRegisterAggregateCandidate(aggregate_ty)) return error.UnsupportedAir;
    if (function_type.params.len == 0 or function_type.params.len > 8) return error.UnsupportedAir;
    var leaf_paths: [8][]const u8 = undefined;
    if (!typedV2RegisterAggregateLeafPaths(function_type, structured_air_v2, &leaf_paths)) return error.UnsupportedAir;
    for (function_type.params) |param| {
        if (!param.ir_type.eql(.{ .int = 32 }) and !param.ir_type.eql(.{ .int = 64 }) and
            !param.ir_type.eql(.float) and !param.ir_type.eql(.double) and
            !param.ir_type.eql(.ptr)) return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), aggregate_ty);
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    const arg_names = [_][]const u8{ "arg0", "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7" };
    for (function_type.params, 0..) |param, index| {
        try function.params.append(allocator, .{ .ty = param.ir_type, .name = arg_names[index] });
    }
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    const result_names = [_][]const u8{ "field0", "field1", "field2", "field3", "field4", "field5", "result", "result" };
    var aggregate_value: ir.Value = .undef;
    for (function_type.params, 0..) |_, index| {
        try block.instructions.append(allocator, .{
            .result = result_names[index],
            .kind = .{ .insertvalue = .{
                .aggregate_ty = aggregate_ty,
                .aggregate = aggregate_value,
                .value_ty = function_type.params[index].ir_type,
                .value = .{ .named = arg_names[index] },
                .indices = leaf_paths[index],
            } },
        });
        aggregate_value = .{ .named = result_names[index] };
    }
    block.terminator = .{ .ret = .{ .ty = aggregate_ty, .value = aggregate_value } };
    try function.blocks.append(allocator, block);
    return function;
}
pub fn lowerTypedV2SmallIntegerAggregateAbi(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (try lowerRegisterAggregateFieldWriteBeforeCall(allocator, module, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (!typedV2RegisterAggregateRecords(function_type, structured_air_v2)) return null;
    return try lowerRegisterAggregateMake(allocator, air_function, function_type, structured_air_v2);
}

const FieldWriteCallSummary = struct {
    aggregate_ty: ir.Type,
    alloc_index: u32,
    load_index: u32,
    call_instruction: air_export.TypedInstruction,
    call_result_ty: ir.Type,
    store_count: usize,
    stores: [8]FieldStore,
};

const FieldStore = struct {
    path: [4]usize = undefined,
    path_len: usize = 0,
    value_index: u32,
    ty: ir.Type,
};

fn lowerRegisterAggregateFieldWriteBeforeCall(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = registerAggregateFieldWriteBeforeCallSummary(function_type, structured_air_v2) orelse return null;
    var function = ir.Function.init(shortFunctionName(air_function.name), summary.call_result_ty);
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    const arg_names = [_][]const u8{ "arg0", "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7" };
    for (function_type.params, 0..) |param, index| {
        try function.params.append(allocator, .{ .ty = param.ir_type, .name = arg_names[index] });
    }

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    var aggregate_value: ir.Value = .undef;
    const field_names = [_][]const u8{ "field0", "field1", "field2", "field3", "field4", "field5", "field6", "field7" };
    for (summary.stores[0..summary.store_count], 0..) |store, index| {
        const value = try lowerTypedAggregateStoreValue(allocator, module, &block, function_type, structured_air_v2, store.value_index);
        try block.instructions.append(allocator, .{
            .result = field_names[index],
            .kind = .{ .insertvalue = .{
                .aggregate_ty = summary.aggregate_ty,
                .aggregate = aggregate_value,
                .value_ty = store.ty,
                .value = value,
                .indices = air_model.aggregateIndexPathText(store.path[0..store.path_len]) orelse return error.UnsupportedAir,
            } },
        });
        aggregate_value = .{ .named = field_names[index] };
    }

    const callee_text = typedDetail(summary.call_instruction, "callee_text") orelse return error.UnsupportedAir;
    const parsed_callee = typedCallee(callee_text) orelse return error.UnsupportedAir;
    if (parsed_callee.external) return error.UnsupportedAir;
    const dot = std.mem.lastIndexOfScalar(u8, air_function.name, '.') orelse return error.UnsupportedAir;
    var call: ir.CallInst = .{
        .ret_ty = summary.call_result_ty,
        .callee = try ownPrint(module, "{s}.{s}", .{ air_function.name[0..dot], parsed_callee.name }),
        .calling_conv = "fastcc",
        .args = .empty,
    };
    errdefer call.deinit(allocator);
    try call.args.append(allocator, .{ .ty = summary.aggregate_ty, .value = aggregate_value });
    try block.instructions.append(allocator, .{ .result = "call", .kind = .{ .call = call } });
    block.terminator = .{ .ret = .{ .ty = summary.call_result_ty, .value = .{ .named = "call" } } };
    try function.blocks.append(allocator, block);
    return function;
}

fn registerAggregateFieldWriteBeforeCallSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?FieldWriteCallSummary {
    if (function_type.return_type.ir_type == .aggregate or function_type.params.len == 0 or function_type.params.len > 8) return null;
    var alloc_instruction: ?air_export.TypedInstruction = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "alloc")) continue;
        if (alloc_instruction != null) return null;
        alloc_instruction = instruction;
    }
    const alloc = alloc_instruction orelse return null;
    const allocated_text = typedDetail(alloc, "allocated_type") orelse return null;
    const aggregate_ty = (parseZigType(allocated_text) orelse return null).ir_type;
    if (!isSysVRegisterAggregateCandidate(aggregate_ty)) return null;

    var summary = FieldWriteCallSummary{
        .aggregate_ty = aggregate_ty,
        .alloc_index = alloc.index,
        .load_index = 0,
        .call_instruction = undefined,
        .call_result_ty = function_type.return_type.ir_type,
        .store_count = 0,
        .stores = undefined,
    };
    var saw_undefined_store = false;
    for (structured_air_v2.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.opcode, "load")) {
            if (instruction.operands.len != 1) return null;
            const load_base = air_model.typedInstOperandIndex(instruction.operands[0]) orelse return null;
            if (load_base != alloc.index) return null;
            if (summary.load_index != 0) return null;
            summary.load_index = instruction.index;
            continue;
        }
        if (std.mem.eql(u8, instruction.opcode, "call")) {
            if (instruction.operands.len != 2) return null;
            const call_arg = air_model.typedInstOperandIndex(instruction.operands[1]) orelse return null;
            if (call_arg != summary.load_index or summary.load_index == 0) return null;
            summary.call_instruction = instruction;
            continue;
        }
        if (!std.mem.eql(u8, instruction.opcode, "store") and !std.mem.eql(u8, instruction.opcode, "store_safe")) continue;
        if (instruction.operands.len != 2) return null;
        const ptr_index = air_model.typedInstOperandIndex(instruction.operands[0]) orelse return null;
        if (ptr_index == alloc.index and air_model.isTypedConstOperand(instruction.operands[1])) {
            const text = typedDetail(instruction, "operand1_text") orelse return null;
            if (std.mem.indexOf(u8, text, "undefined") == null) return null;
            saw_undefined_store = true;
            continue;
        }
        if (summary.store_count >= summary.stores.len) return null;
        const value_index = air_model.typedInstOperandIndex(instruction.operands[1]) orelse return null;
        var path: [4]usize = undefined;
        const path_len = air_model.typedAggregatePointerPath(structured_air_v2, ptr_index, alloc.index, &path) orelse return null;
        if (path_len == 0) return null;
        const value_ty = (parseZigType(instruction.operands[1].type_text) orelse return null).ir_type;
        summary.stores[summary.store_count] = .{
            .path = path,
            .path_len = path_len,
            .value_index = value_index,
            .ty = value_ty,
        };
        summary.store_count += 1;
    }
    if (!saw_undefined_store or summary.load_index == 0 or summary.call_instruction.index == 0 or summary.store_count == 0) return null;
    return summary;
}

fn lowerTypedAggregateStoreValue(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    block: *ir.BasicBlock,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
    value_index: u32,
) !ir.Value {
    if (value_index < function_type.params.len) return .{ .named = argName(value_index) orelse return error.UnsupportedAir };
    const instruction = air_model.instructionByIndex(structured_air_v2, value_index) orelse return error.UnsupportedAir;
    const op = typedAggregateBinaryOp(instruction.opcode) orelse return error.UnsupportedAir;
    if (instruction.operands.len != 2) return error.UnsupportedAir;
    const ty = (parseZigType(instruction.result_type) orelse return error.UnsupportedAir).ir_type;
    if (!ty.eql(.{ .int = 64 }) and !ty.eql(.{ .int = 32 })) return error.UnsupportedAir;
    const lhs = try typedValueOperand(function_type, instruction.operands[0]);
    const rhs = try typedValueOperand(function_type, instruction.operands[1]);
    const result = try ownPrint(module, "v{}", .{value_index});
    try block.instructions.append(allocator, .{ .result = result, .kind = .{ .binary = .{
        .op = op,
        .ty = ty,
        .lhs = lhs,
        .rhs = rhs,
    } } });
    return .{ .named = result };
}

fn typedAggregateBinaryOp(opcode: []const u8) ?ir.BinaryOp {
    if (ir.BinaryOp.parse(opcode)) |op| return op;
    if (!std.mem.endsWith(u8, opcode, "_safe")) return null;
    return ir.BinaryOp.parse(opcode[0 .. opcode.len - "_safe".len]);
}

fn typedValueOperand(
    function_type: FunctionType,
    operand: air_export.TypedOperand,
) !ir.Value {
    if (air_model.typedInstOperandIndex(operand)) |index| {
        if (index >= function_type.params.len) return error.UnsupportedAir;
        return .{ .named = argName(index) orelse return error.UnsupportedAir };
    }
    if (air_model.isTypedConstOperand(operand)) {
        const text = operand.value;
        const int = std.fmt.parseInt(i128, text, 10) catch return error.UnsupportedAir;
        return .{ .int = int };
    }
    return error.UnsupportedAir;
}

fn argName(index: u32) ?[]const u8 {
    const names = [_][]const u8{ "arg0", "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7" };
    if (index >= names.len) return null;
    return names[index];
}

pub fn typedV2RegisterAggregateRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_aggregate_construction.registerAggregateRecords(function_type, structured_air_v2);
}

pub fn typedV2RegisterAggregateLeafPaths(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
    leaf_paths: *[8][]const u8,
) bool {
    return air_aggregate_construction.registerAggregateLeafPaths(function_type, structured_air_v2, leaf_paths);
}

pub fn aggregateFieldCount(ty: ir.Type) ?usize {
    return type_layout.fieldCount(ty);
}

pub fn lowerTypedV2SretIntegerAggregateAbi(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (typedV2SretIntegerAggregateCallWrapperRecords(function_type, structured_air_v2)) {
        return try lowerSretIntegerAggregateCallWrapper(allocator, module, air_function, function_type, structured_air_v2);
    }
    if (typedV2SretIntegerAggregateCopyRecords(function_type, structured_air_v2)) {
        return try lowerSretIntegerAggregateCopy(allocator, module, air_function, function_type.return_type.ir_type);
    }
    if (typedV2SretIntegerAggregateFieldWrapperRecords(function_type, structured_air_v2)) |wrapper| {
        return try lowerSretIntegerAggregateFieldWrapper(allocator, module, air_function, function_type.return_type.ir_type, wrapper);
    }
    if (!typedV2SretIntegerAggregateRecords(function_type, structured_air_v2)) return null;
    return try lowerSretIntegerAggregateMake(allocator, module, air_function, function_type.return_type.ir_type);
}

pub fn typedV2SretIntegerAggregateRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (isSysVRegisterAggregateCandidate(function_type.return_type.ir_type)) return false;
    return validateSretAggregateMakeRecords(function_type, structured_air_v2);
}

pub fn typedV2SretIntegerAggregateCopyRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (isSysVRegisterAggregateCandidate(function_type.return_type.ir_type)) return false;
    return validateSretAggregateCopyRecords(function_type, structured_air_v2);
}

pub fn typedV2SretIntegerAggregateFieldWrapperRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?air_aggregate_copy.AggregateFieldWrapper {
    if (isSysVRegisterAggregateCandidate(function_type.return_type.ir_type)) return null;
    return sretAggregateFieldWrapper(function_type, structured_air_v2);
}

pub fn typedV2SretIntegerAggregateCallWrapperRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (isSysVRegisterAggregateCandidate(function_type.return_type.ir_type)) return false;
    return validateSretAggregateCallWrapperRecords(function_type, structured_air_v2);
}

pub fn lowerSretIntegerAggregateMake(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    aggregate_ty: ir.Type,
) !ir.Function {
    var function = ir.Function.init(shortFunctionName(air_function.name), .void);
    errdefer function.deinit(allocator);
    function.linkage = .default;
    function.calling_conv = null;
    const leaves = try collectAggregateCopyLeaves(allocator, aggregate_ty);
    defer allocator.free(leaves);
    try function.params.append(allocator, .{ .ty = .ptr, .attrs = try sretAttrsForAggregate(module, aggregate_ty), .name = "sret" });
    var param_index: usize = 0;
    while (param_index < leaves.len) : (param_index += 1) {
        const arg_name = try ownPrint(module, "arg{}", .{param_index});
        try function.params.append(allocator, .{ .ty = leaves[param_index].ty, .name = arg_name });
    }

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    for (leaves, 0..) |leaf, leaf_index| {
        const field_name = try ownPrint(module, "leaf{}", .{leaf_index});
        const arg_name = function.params.items[leaf_index + 1].name;
        var gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = "sret" }, .indices = .empty };
        errdefer gep.deinit(allocator);
        try gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(leaf.offset) } });
        try block.instructions.append(allocator, .{ .result = field_name, .kind = .{ .gep = gep } });
        try block.instructions.append(allocator, .{
            .result = null,
            .kind = .{ .store = .{
                .ty = function.params.items[leaf_index + 1].ty,
                .value = .{ .named = arg_name },
                .ptr = .{ .named = field_name },
            } },
        });
    }
    block.terminator = .{ .ret = .{ .ty = .void } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn lowerSretIntegerAggregateCopy(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    aggregate_ty: ir.Type,
) !ir.Function {
    var function = ir.Function.init(shortFunctionName(air_function.name), .void);
    errdefer function.deinit(allocator);
    function.linkage = .default;
    function.calling_conv = null;
    const leaves = try collectAggregateCopyLeaves(allocator, aggregate_ty);
    defer allocator.free(leaves);
    try function.params.append(allocator, .{ .ty = .ptr, .attrs = try sretAttrsForAggregate(module, aggregate_ty), .name = "sret" });
    try function.params.append(allocator, .{ .ty = .ptr, .attrs = try byvalAttrsForAggregate(module, aggregate_ty), .name = "arg0" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    for (leaves, 0..) |leaf, field_index| {
        const src_result = try ownPrint(module, "src_leaf{}", .{field_index});
        const load_result = try ownPrint(module, "load{}", .{field_index});
        const dst_result = try ownPrint(module, "dst_leaf{}", .{field_index});

        var src_gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = "arg0" }, .indices = .empty };
        errdefer src_gep.deinit(allocator);
        try src_gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(leaf.offset) } });
        try block.instructions.append(allocator, .{ .result = src_result, .kind = .{ .gep = src_gep } });

        try block.instructions.append(allocator, .{ .result = load_result, .kind = .{ .load = .{
            .ty = leaf.ty,
            .ptr = .{ .named = src_result },
        } } });

        var dst_gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = "sret" }, .indices = .empty };
        errdefer dst_gep.deinit(allocator);
        try dst_gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(leaf.offset) } });
        try block.instructions.append(allocator, .{ .result = dst_result, .kind = .{ .gep = dst_gep } });

        try block.instructions.append(allocator, .{
            .result = null,
            .kind = .{ .store = .{
                .ty = leaf.ty,
                .value = .{ .named = load_result },
                .ptr = .{ .named = dst_result },
            } },
        });
    }
    block.terminator = .{ .ret = .{ .ty = .void } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn lowerSretIntegerAggregateFieldWrapper(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    aggregate_ty: ir.Type,
    wrapper: air_aggregate_copy.AggregateFieldWrapper,
) !ir.Function {
    var function = ir.Function.init(shortFunctionName(air_function.name), .void);
    errdefer function.deinit(allocator);
    function.linkage = .default;
    function.calling_conv = null;
    const leaves = try collectAggregateCopyLeaves(allocator, wrapper.param_ty);
    defer allocator.free(leaves);
    try function.params.append(allocator, .{ .ty = .ptr, .attrs = try sretAttrsForAggregate(module, aggregate_ty), .name = "sret" });
    try function.params.append(allocator, .{ .ty = .ptr, .attrs = try byvalAttrsForAggregate(module, wrapper.param_ty), .name = "arg0" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    for (leaves, 0..) |leaf, leaf_index| {
        const src_result = try ownPrint(module, "src_leaf{}", .{leaf_index});
        const load_result = try ownPrint(module, "load{}", .{leaf_index});
        const dst_result = try ownPrint(module, "dst_leaf{}", .{leaf_index});

        var src_gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = "arg0" }, .indices = .empty };
        errdefer src_gep.deinit(allocator);
        try src_gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(leaf.offset) } });
        try block.instructions.append(allocator, .{ .result = src_result, .kind = .{ .gep = src_gep } });

        try block.instructions.append(allocator, .{ .result = load_result, .kind = .{ .load = .{
            .ty = leaf.ty,
            .ptr = .{ .named = src_result },
        } } });

        var dst_gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = "sret" }, .indices = .empty };
        errdefer dst_gep.deinit(allocator);
        try dst_gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(wrapper.field_offset + leaf.offset) } });
        try block.instructions.append(allocator, .{ .result = dst_result, .kind = .{ .gep = dst_gep } });

        try block.instructions.append(allocator, .{
            .result = null,
            .kind = .{ .store = .{
                .ty = leaf.ty,
                .value = .{ .named = load_result },
                .ptr = .{ .named = dst_result },
            } },
        });
    }
    block.terminator = .{ .ret = .{ .ty = .void } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn lowerSretIntegerAggregateCallWrapper(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !ir.Function {
    const aggregate_ty = function_type.return_type.ir_type;
    const call_instruction = typedSingleInstructionByOpcode(structured_air_v2, "call") orelse return error.UnsupportedAir;
    const callee_text = typedDetail(call_instruction, "callee_text") orelse return error.UnsupportedAir;
    const parsed_callee = typedCallee(callee_text);

    var function = ir.Function.init(shortFunctionName(air_function.name), .void);
    errdefer function.deinit(allocator);
    function.linkage = .default;
    function.calling_conv = null;
    try function.params.append(allocator, .{ .ty = .ptr, .attrs = try sretAttrsForAggregate(module, aggregate_ty), .name = "sret" });
    for (function_type.params, 0..) |param, param_index| {
        const name = try ownPrint(module, "arg{}", .{param_index});
        if (param_index == function_type.params.len - 1) {
            try function.params.append(allocator, .{ .ty = .ptr, .attrs = try byvalAttrsForAggregate(module, aggregate_ty), .name = name });
        } else {
            try function.params.append(allocator, .{ .ty = param.ir_type, .name = name });
        }
    }

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    var call: ir.CallInst = .{
        .ret_ty = .void,
        .callee = "",
        .calling_conv = null,
        .args = .empty,
    };
    errdefer call.deinit(allocator);
    if (parsed_callee) |direct| {
        if (direct.external) return error.UnsupportedAir;
        const dot = std.mem.lastIndexOfScalar(u8, air_function.name, '.') orelse return error.UnsupportedAir;
        call.callee = try ownPrint(module, "{s}.{s}", .{ air_function.name[0..dot], direct.name });
    } else {
        call.callee_value = .{ .named = "arg0" };
    }
    try call.args.append(allocator, .{
        .ty = .ptr,
        .value = .{ .named = "sret" },
        .attrs = try sretAttrsForAggregate(module, aggregate_ty),
    });
    const byval_arg_name = function.params.items[function.params.items.len - 1].name;
    try call.args.append(allocator, .{
        .ty = .ptr,
        .value = .{ .named = byval_arg_name },
        .attrs = try byvalAttrsForAggregate(module, aggregate_ty),
    });
    try block.instructions.append(allocator, .{ .result = null, .kind = .{ .call = call } });
    block.terminator = .{ .ret = .{ .ty = .void } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn sretAttrsForAggregate(module: *ir.Module, aggregate_ty: ir.Type) ![]const u8 {
    return try aggregateAbiAttrsForAggregate(module, "sret", aggregate_ty);
}

pub fn byvalAttrsForAggregate(module: *ir.Module, aggregate_ty: ir.Type) ![]const u8 {
    return try aggregateAbiAttrsForAggregate(module, "byval", aggregate_ty);
}

pub fn aggregateAbiAttrsForAggregate(module: *ir.Module, attr_name: []const u8, aggregate_ty: ir.Type) ![]const u8 {
    return switch (aggregate_ty) {
        .aggregate => |text| try ownPrint(module, "{s}({s})", .{ attr_name, text }),
        .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => error.UnsupportedAir,
    };
}
pub fn lowerTypedV2PackedBits(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (typedV2PackedReadFlagRecords(function_type, structured_air_v2)) {
        var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 1 });
        errdefer function.deinit(allocator);
        function.linkage = if (function_type.c_calling_convention) .default else .internal;
        function.calling_conv = irCallingConvention(function_type);
        try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });
        var block = ir.BasicBlock.init("entry");
        errdefer block.deinit(allocator);
        try block.instructions.append(allocator, .{
            .result = "flag",
            .kind = .{ .icmp = .{
                .predicate = .slt,
                .operand_ty = .{ .int = 8 },
                .lhs = .{ .named = "arg0" },
                .rhs = .{ .int = 0 },
            } },
        });
        block.terminator = .{ .ret = .{ .ty = .{ .int = 1 }, .value = .{ .named = "flag" } } };
        try function.blocks.append(allocator, block);
        return function;
    }
    if (typedV2PackedReplaceLowRecords(function_type, structured_air_v2)) {
        var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 8 });
        errdefer function.deinit(allocator);
        function.linkage = if (function_type.c_calling_convention) .default else .internal;
        function.calling_conv = irCallingConvention(function_type);
        try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });
        try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg1" });
        var block = ir.BasicBlock.init("entry");
        errdefer block.deinit(allocator);
        try block.instructions.append(allocator, .{
            .result = "high",
            .kind = .{ .binary = .{ .op = .@"and", .ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = -8 } } },
        });
        try block.instructions.append(allocator, .{
            .result = "low",
            .kind = .{ .binary = .{ .op = .@"and", .ty = .{ .int = 8 }, .lhs = .{ .named = "arg1" }, .rhs = .{ .int = 7 } } },
        });
        try block.instructions.append(allocator, .{
            .result = "result",
            .kind = .{ .binary = .{ .op = .@"or", .ty = .{ .int = 8 }, .lhs = .{ .named = "high" }, .rhs = .{ .named = "low" } } },
        });
        block.terminator = .{ .ret = .{ .ty = .{ .int = 8 }, .value = .{ .named = "result" } } };
        try function.blocks.append(allocator, block);
        return function;
    }
    return null;
}

pub fn typedV2PackedReadFlagRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedPackedReadFlagSummary(function_type, structured_air_v2) != null;
}

pub fn typedV2PackedReplaceLowRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedPackedReplaceLowSummary(function_type, structured_air_v2) != null;
}
