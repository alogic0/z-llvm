const std = @import("std");
const air_aggregate_construction = @import("zig_air_aggregate_construction.zig");
const air_aggregate_copy = @import("zig_air_aggregate_copy.zig");
const air_export = @import("zig_air_export.zig");
const air_model = @import("zig_air_model.zig");
const air_types = @import("zig_air_types.zig");
const ir = @import("ir.zig");
const target = @import("target.zig");
const type_layout = @import("zig_air_type_layout.zig");
const aggregate_layout_facts = @import("zig_air_aggregate_layout_facts.zig");
const air_capabilities = @import("zig_air_capabilities.zig");

fn x86_64SysVDataLayout() ?target.DataLayout {
    return target.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128") catch null;
}

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
    if (function_type.params.len > 8) return error.UnsupportedAir;
    const plan = air_aggregate_construction.planRegisterAggregateConstruction(function_type, structured_air_v2) orelse return error.UnsupportedAir;
    for (function_type.params) |param| {
        if (!param.ir_type.eql(.{ .int = 8 }) and !param.ir_type.eql(.{ .int = 16 }) and
            !param.ir_type.eql(.{ .int = 32 }) and !param.ir_type.eql(.{ .int = 64 }) and
            !param.ir_type.eql(.float) and !param.ir_type.eql(.double) and
            !param.ir_type.eql(.ptr) and !param.ir_type.eql(.{ .aggregate = "{ i32, i32 }" })) return error.UnsupportedAir;
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
    const result_names = [_][]const u8{ "field0", "field1", "field2", "field3", "field4", "field5", "field6", "result" };
    const trunc_names = [_][]const u8{ "trunc0", "trunc1", "trunc2", "trunc3", "trunc4", "trunc5", "trunc6", "trunc7" };
    const shr_names = [_][]const u8{ "shr0", "shr1", "shr2", "shr3", "shr4", "shr5", "shr6", "shr7" };
    const bits_names = [_][]const u8{ "bits0", "bits1", "bits2", "bits3", "bits4", "bits5", "bits6", "bits7" };

    var param_val_names: [8][]const u8 = undefined;
    var param_val_types: [8]ir.Type = undefined;
    for (function_type.params, 0..) |param, p_idx| {
        if (param.ir_type.eql(.double)) {
            const bits_name = bits_names[p_idx];
            try block.instructions.append(allocator, .{
                .result = bits_name,
                .kind = .{ .cast = .{
                    .op = .bitcast,
                    .from_ty = .double,
                    .value = .{ .named = arg_names[p_idx] },
                    .to_ty = .{ .int = 64 },
                } },
            });
            param_val_names[p_idx] = bits_name;
            param_val_types[p_idx] = .{ .int = 64 };
        } else if (param.ir_type.eql(.float)) {
            const bits_name = bits_names[p_idx];
            try block.instructions.append(allocator, .{
                .result = bits_name,
                .kind = .{ .cast = .{
                    .op = .bitcast,
                    .from_ty = .float,
                    .value = .{ .named = arg_names[p_idx] },
                    .to_ty = .{ .int = 32 },
                } },
            });
            param_val_names[p_idx] = bits_name;
            param_val_types[p_idx] = .{ .int = 32 };
        } else {
            param_val_names[p_idx] = arg_names[p_idx];
            param_val_types[p_idx] = param.ir_type;
        }
    }

    var aggregate_value: ir.Value = .undef;
    for (plan.leaves[0..plan.leaf_count], 0..) |leaf, index| {
        const value: ir.Value = switch (leaf.source) {
            .param => |param_index| blk: {
                const param_ty = param_val_types[param_index];
                const param_name = param_val_names[param_index];
                if (param_ty == .int and leaf.ty == .int and param_ty.int > leaf.ty.int) {
                    const trunc_name = trunc_names[index];
                    try block.instructions.append(allocator, .{
                        .result = trunc_name,
                        .kind = .{ .cast = .{
                            .op = .trunc,
                            .from_ty = param_ty,
                            .value = .{ .named = param_name },
                            .to_ty = leaf.ty,
                        } },
                    });
                    break :blk .{ .named = trunc_name };
                }
                break :blk .{ .named = param_name };
            },
            .param_shr => |info| blk: {
                const param_ty = param_val_types[info.param];
                const param_name = param_val_names[info.param];
                const shr_name = shr_names[index];
                try block.instructions.append(allocator, .{
                    .result = shr_name,
                    .kind = .{ .binary = .{
                        .op = .lshr,
                        .ty = param_ty,
                        .lhs = .{ .named = param_name },
                        .rhs = .{ .int = info.shift },
                    } },
                });
                if (param_ty == .int and leaf.ty == .int and param_ty.int > leaf.ty.int) {
                    const trunc_name = trunc_names[index];
                    try block.instructions.append(allocator, .{
                        .result = trunc_name,
                        .kind = .{ .cast = .{
                            .op = .trunc,
                            .from_ty = param_ty,
                            .value = .{ .named = shr_name },
                            .to_ty = leaf.ty,
                        } },
                    });
                    break :blk .{ .named = trunc_name };
                }
                break :blk .{ .named = shr_name };
            },
            .constant_int => |int_val| if (leaf.ty == .ptr and int_val == 0) .null_value else .{ .int = int_val },
        };
        const result_name = if (index + 1 == plan.leaf_count) "result" else result_names[index];
        try block.instructions.append(allocator, .{
            .result = result_name,
            .kind = .{ .insertvalue = .{
                .aggregate_ty = aggregate_ty,
                .aggregate = aggregate_value,
                .value_ty = leaf.ty,
                .value = value,
                .indices = leaf.path_text,
            } },
        });
        aggregate_value = .{ .named = result_name };
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
    if (typedV2ConstantZeroAggregateRecords(function_type, structured_air_v2)) {
        return try lowerRegisterAggregateZero(allocator, air_function, function_type);
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

pub fn typedV2ConstantZeroAggregateRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_aggregate_construction.registerConstantZeroAggregateRecords(function_type, structured_air_v2);
}

pub fn lowerRegisterAggregateZero(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
) !ir.Function {
    const aggregate_ty = function_type.return_type.ir_type;
    var function = ir.Function.init(shortFunctionName(air_function.name), aggregate_ty);
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    block.terminator = .{ .ret = .{ .ty = aggregate_ty, .value = .zero_initializer } };
    try function.blocks.append(allocator, block);
    return function;
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

pub const SretFieldAction = union(enum) {
    param_field_load: struct {
        param_index: usize,
        src_offset: u64,
        dst_offset: u64,
        ty: ir.Type,
    },
    param_copy: struct {
        param_index: usize,
        dst_offset: u64,
        byte_count: u64,
    },
    param_field_copy: struct {
        param_index: usize,
        src_offset: u64,
        dst_offset: u64,
        byte_count: u64,
    },
    param_scalar: struct {
        param_index: usize,
        dst_offset: u64,
        ty: ir.Type,
    },
    constant: struct {
        dst_offset: u64,
        value: i128,
        ty: ir.Type,
    },
};

pub const SretFieldLoaderPlan = struct {
    actions: [8]SretFieldAction = undefined,
    action_count: usize = 0,
};

fn pathByteOffset(layout: target.DataLayout, aggregate_ty: ir.Type, path: []const usize) ?u64 {
    if (path.len == 0) return null;
    var current_ty = aggregate_ty;
    var offset: u64 = 0;
    for (path) |field_index| {
        const field_ty = type_layout.fieldType(current_ty, field_index) orelse return null;
        offset += type_layout.fieldByteOffset(layout, current_ty, field_index) orelse return null;
        current_ty = field_ty;
    }
    return offset;
}

pub fn planSretFieldLoaderConstructor(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?SretFieldLoaderPlan {
    if (isSysVRegisterAggregateCandidate(function_type.return_type.ir_type)) return null;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret_ptr") != 1) return null;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret_load") != 1) return null;
    const ret_ptr_index = air_model.typedRetPtrIndex(structured_air_v2) orelse return null;

    var ret_nominal_name: []const u8 = "";
    for (structured_air_v2.instructions) |inst| {
        if (inst.index == ret_ptr_index) {
            var raw = std.mem.trim(u8, inst.result_type, " ");
            if (std.mem.startsWith(u8, raw, "*const ")) {
                raw = std.mem.trim(u8, raw[7..], " ");
            } else if (std.mem.startsWith(u8, raw, "*")) {
                raw = std.mem.trim(u8, raw[1..], " ");
            }
            ret_nominal_name = raw;
            break;
        }
    }
    const layout = x86_64SysVDataLayout() orelse return null;
    var plan = SretFieldLoaderPlan{};

    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "store") and !std.mem.eql(u8, instruction.opcode, "store_safe")) continue;
        if (instruction.operands.len != 2) return null;

        const ptr_inst_index = std.fmt.parseInt(u32, instruction.operands[0].value, 10) catch return null;
        var path: [4]usize = undefined;
        const path_len = air_model.typedAggregatePointerPath(structured_air_v2, ptr_inst_index, ret_ptr_index, &path) orelse continue;
        if (path_len == 0) continue;

        const dst_offset = blk: {
            if (pathByteOffset(layout, function_type.return_type.ir_type, path[0..path_len])) |off| {
                break :blk off;
            }
            if (path_len == 1) {
                if (ret_nominal_name.len > 0 and aggregate_layout_facts.nominalFieldByteOffset(ret_nominal_name, path[0]) != null) {
                    break :blk aggregate_layout_facts.nominalFieldByteOffset(ret_nominal_name, path[0]).?;
                }
                if (type_layout.fieldByteOffset(layout, function_type.return_type.ir_type, path[0])) |off| {
                    break :blk off;
                }
            }
            return null;
        };

        const val_operand = instruction.operands[1];
        if (std.mem.eql(u8, val_operand.kind, "inst")) {
            const val_inst_index = std.fmt.parseInt(u32, val_operand.value, 10) catch {
                return null;
            };
            var val_inst: ?air_export.TypedInstruction = null;
            for (structured_air_v2.instructions) |inst| {
                if (inst.index == val_inst_index) {
                    val_inst = inst;
                    break;
                }
            }
            const vi = val_inst orelse {
                return null;
            };
            if (std.mem.eql(u8, vi.opcode, "load") or std.mem.eql(u8, vi.opcode, "load_safe")) {
                if (vi.operands.len < 1) return null;
                const load_ptr_index = std.fmt.parseInt(u32, vi.operands[0].value, 10) catch return null;
                var cur_ptr_idx = load_ptr_index;
                var total_src_offset: u64 = 0;
                var found_param_idx: ?usize = null;

                while (true) {
                    var cur_inst: ?air_export.TypedInstruction = null;
                    for (structured_air_v2.instructions) |inst| {
                        if (inst.index == cur_ptr_idx) {
                            cur_inst = inst;
                            break;
                        }
                    }
                    const ci = cur_inst orelse break;

                    if (air_capabilities.isFieldPtrOpcode(ci.opcode) or air_model.isTypedFieldPtrDataKind(ci.data_kind)) {
                        const src_field_idx: usize = blk: {
                            if (typedDetail(ci, "field_index")) |idx_text| {
                                break :blk std.fmt.parseInt(usize, idx_text, 10) catch return null;
                            } else if (std.mem.startsWith(u8, ci.opcode, "struct_field_ptr_index_")) {
                                const idx_part = ci.opcode["struct_field_ptr_index_".len..];
                                break :blk std.fmt.parseInt(usize, idx_part, 10) catch return null;
                            } else return null;
                        };

                        if (ci.operands.len < 1) return null;
                        var base_nominal_name = std.mem.trim(u8, ci.operands[0].type_text, " ");
                        if (std.mem.startsWith(u8, base_nominal_name, "*const ")) {
                            base_nominal_name = std.mem.trim(u8, base_nominal_name[7..], " ");
                        } else if (std.mem.startsWith(u8, base_nominal_name, "*")) {
                            base_nominal_name = std.mem.trim(u8, base_nominal_name[1..], " ");
                        }

                        const field_off = if (base_nominal_name.len > 0 and aggregate_layout_facts.nominalFieldByteOffset(base_nominal_name, src_field_idx) != null)
                            aggregate_layout_facts.nominalFieldByteOffset(base_nominal_name, src_field_idx).?
                        else if (parseZigType(base_nominal_name)) |zt|
                            type_layout.fieldByteOffset(layout, zt.ir_type, src_field_idx) orelse return null
                        else
                            return null;

                        total_src_offset += field_off;
                        if (ci.operands.len >= 1 and std.mem.eql(u8, ci.operands[0].kind, "inst")) {
                            cur_ptr_idx = std.fmt.parseInt(u32, ci.operands[0].value, 10) catch return null;
                        } else {
                            var found_idx: ?usize = null;
                            var arg_idx: usize = 0;
                            for (structured_air_v2.instructions) |inst| {
                                if (std.mem.eql(u8, inst.opcode, "arg")) {
                                    const arg_ty = std.mem.trim(u8, inst.result_type, " ");
                                    if (std.mem.eql(u8, arg_ty, base_nominal_name) or
                                        std.mem.endsWith(u8, arg_ty, base_nominal_name) or
                                        std.mem.endsWith(u8, base_nominal_name, arg_ty))
                                    {
                                        found_idx = arg_idx;
                                        break;
                                    }
                                    arg_idx += 1;
                                }
                            }
                            found_param_idx = found_idx orelse return null;
                            break;
                        }
                    } else if (std.mem.eql(u8, ci.opcode, "ptr_cast") or std.mem.eql(u8, ci.opcode, "ptr_cast_safe") or
                        std.mem.eql(u8, ci.opcode, "bit_cast") or std.mem.eql(u8, ci.opcode, "bit_cast_safe"))
                    {
                        if (ci.operands.len >= 1 and std.mem.eql(u8, ci.operands[0].kind, "inst")) {
                            cur_ptr_idx = std.fmt.parseInt(u32, ci.operands[0].value, 10) catch return null;
                        } else {
                            var found_idx: ?u32 = null;
                            var search = ci.index;
                            while (search > 0) {
                                search -= 1;
                                if (air_model.instructionByIndex(structured_air_v2, search)) |prior| {
                                    if (std.mem.eql(u8, prior.opcode, "alloc") or std.mem.eql(u8, prior.opcode, "arg")) {
                                        found_idx = prior.index;
                                        break;
                                    }
                                }
                            }
                            cur_ptr_idx = found_idx orelse return null;
                        }
                    } else if (std.mem.eql(u8, ci.opcode, "load") or std.mem.eql(u8, ci.opcode, "load_safe")) {
                        if (ci.operands.len >= 1 and std.mem.eql(u8, ci.operands[0].kind, "inst")) {
                            cur_ptr_idx = std.fmt.parseInt(u32, ci.operands[0].value, 10) catch return null;
                        } else return null;
                    } else if (std.mem.eql(u8, ci.opcode, "alloc")) {
                        var found_val_idx: ?u32 = null;
                        for (structured_air_v2.instructions) |inst| {
                            if (std.mem.eql(u8, inst.opcode, "store") or std.mem.eql(u8, inst.opcode, "store_safe")) {
                                if (inst.operands.len == 2 and ((std.fmt.parseInt(u32, inst.operands[0].value, 10) catch 0) == ci.index)) {
                                    found_val_idx = std.fmt.parseInt(u32, inst.operands[1].value, 10) catch null;
                                    break;
                                }
                            }
                        }
                        const val_idx = found_val_idx orelse return null;
                        found_param_idx = air_aggregate_construction.resolveParamIndex(structured_air_v2, val_idx) orelse return null;
                        break;
                    } else if (std.mem.eql(u8, ci.opcode, "arg")) {
                        found_param_idx = air_aggregate_construction.resolveParamIndex(structured_air_v2, ci.index) orelse return null;
                        break;
                    } else {
                        return null;
                    }
                }

                const p_idx = found_param_idx orelse {
                    return null;
                };
                const field_ty = (parseZigType(instruction.operands[1].type_text) orelse {
                    return null;
                }).ir_type;

                if (plan.action_count >= plan.actions.len) return null;
                if (field_ty == .aggregate) {
                    const byte_count = aggregate_layout_facts.nominalTypeByteSize(instruction.operands[1].type_text) orelse blk: {
                        const layout_val = x86_64SysVDataLayout() orelse return null;
                        break :blk layout_val.typeStoreSizeBytes(field_ty) catch return null;
                    };
                    plan.actions[plan.action_count] = .{
                        .param_field_copy = .{
                            .param_index = p_idx,
                            .src_offset = total_src_offset,
                            .dst_offset = dst_offset,
                            .byte_count = byte_count,
                        },
                    };
                    plan.action_count += 1;
                } else {
                    plan.actions[plan.action_count] = .{
                        .param_field_load = .{
                            .param_index = p_idx,
                            .src_offset = total_src_offset,
                            .dst_offset = dst_offset,
                            .ty = field_ty,
                        },
                    };
                    plan.action_count += 1;
                }
            } else if (air_aggregate_construction.resolveParamIndex(structured_air_v2, val_inst_index)) |p_idx| {
                if (p_idx >= function_type.params.len) return null;
                const p_ty = function_type.params[p_idx].ir_type;
                const store_zig_ty = parseZigType(instruction.operands[1].type_text) orelse parseZigType(vi.result_type);
                const store_val_ty = if (store_zig_ty) |zt| zt.ir_type else p_ty;
                if (p_ty == .ptr and store_val_ty == .aggregate) {
                    if (plan.action_count >= plan.actions.len) return null;
                    const byte_count = aggregate_layout_facts.nominalTypeByteSize(instruction.operands[1].type_text) orelse blk: {
                        const layout_val = x86_64SysVDataLayout() orelse return null;
                        break :blk layout_val.typeStoreSizeBytes(store_val_ty) catch return null;
                    };
                    plan.actions[plan.action_count] = .{
                        .param_copy = .{
                            .param_index = p_idx,
                            .dst_offset = dst_offset,
                            .byte_count = byte_count,
                        },
                    };
                    plan.action_count += 1;
                } else {
                    if (plan.action_count >= plan.actions.len) return null;
                    plan.actions[plan.action_count] = .{
                        .param_scalar = .{
                            .param_index = p_idx,
                            .dst_offset = dst_offset,
                            .ty = if (store_val_ty == .ptr) .ptr else p_ty,
                        },
                    };
                    plan.action_count += 1;
                }
            } else {
                return null;
            }
        } else if (std.mem.eql(u8, val_operand.kind, "const")) {
            if (std.mem.indexOf(u8, val_operand.value, "undefined") != null or
                (air_model.operandTextDetail(instruction, 1) != null and
                    std.mem.indexOf(u8, air_model.operandTextDetail(instruction, 1).?, "undefined") != null))
            {
                continue;
            }
            const const_val = air_aggregate_construction.parseConstIntOperand(instruction, 1) orelse return null;
            const val_ty = (parseZigType(instruction.operands[1].type_text) orelse return null).ir_type;
            if (plan.action_count >= plan.actions.len) return null;
            plan.actions[plan.action_count] = .{
                .constant = .{
                    .dst_offset = dst_offset,
                    .value = const_val,
                    .ty = val_ty,
                },
            };
            plan.action_count += 1;
        } else return null;
    }

    if (plan.action_count == 0) return null;
    return plan;
}

pub fn lowerSretFieldLoaderPlan(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    plan: SretFieldLoaderPlan,
) !ir.Function {
    var function = ir.Function.init(shortFunctionName(air_function.name), .void);
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = null;

    const aggregate_ty = function_type.return_type.ir_type;
    try function.params.append(allocator, .{
        .ty = .ptr,
        .attrs = try sretAttrsForAggregate(module, aggregate_ty),
        .name = "sret",
    });

    for (function_type.params, 0..) |param, p_idx| {
        const arg_name = try ownPrint(module, "arg{}", .{p_idx});
        try function.params.append(allocator, .{ .ty = param.ir_type, .name = arg_name });
    }

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);

    var temp_idx: usize = 0;
    for (plan.actions[0..plan.action_count]) |action| {
        switch (action) {
            .param_field_load => |info| {
                const src_ptr_name = function.params.items[info.param_index + 1].name;
                const src_gep_name = try ownPrint(module, "src_gep{}", .{temp_idx});
                const load_name = try ownPrint(module, "val{}", .{temp_idx});
                const dst_gep_name = try ownPrint(module, "dst_gep{}", .{temp_idx});
                temp_idx += 1;

                var src_gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = src_ptr_name }, .indices = .empty };
                errdefer src_gep.deinit(allocator);
                try src_gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(info.src_offset) } });
                try block.instructions.append(allocator, .{ .result = src_gep_name, .kind = .{ .gep = src_gep } });

                try block.instructions.append(allocator, .{ .result = load_name, .kind = .{ .load = .{
                    .ty = info.ty,
                    .ptr = .{ .named = src_gep_name },
                } } });

                var dst_gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = "sret" }, .indices = .empty };
                errdefer dst_gep.deinit(allocator);
                try dst_gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(info.dst_offset) } });
                try block.instructions.append(allocator, .{ .result = dst_gep_name, .kind = .{ .gep = dst_gep } });

                try block.instructions.append(allocator, .{ .result = null, .kind = .{ .store = .{
                    .ty = info.ty,
                    .value = .{ .named = load_name },
                    .ptr = .{ .named = dst_gep_name },
                } } });
            },
            .param_copy => |info| {
                const src_ptr_name = function.params.items[info.param_index + 1].name;
                var chunk: u64 = 0;
                while (chunk < info.byte_count) {
                    const remaining = info.byte_count - chunk;
                    if (remaining >= 8) {
                        const src_gep_name = try ownPrint(module, "cpy_src{}", .{temp_idx});
                        const load_name = try ownPrint(module, "cpy_val{}", .{temp_idx});
                        const dst_gep_name = try ownPrint(module, "cpy_dst{}", .{temp_idx});
                        temp_idx += 1;

                        var src_gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = src_ptr_name }, .indices = .empty };
                        errdefer src_gep.deinit(allocator);
                        try src_gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(chunk) } });
                        try block.instructions.append(allocator, .{ .result = src_gep_name, .kind = .{ .gep = src_gep } });

                        try block.instructions.append(allocator, .{ .result = load_name, .kind = .{ .load = .{
                            .ty = .{ .int = 64 },
                            .ptr = .{ .named = src_gep_name },
                        } } });

                        var dst_gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = "sret" }, .indices = .empty };
                        errdefer dst_gep.deinit(allocator);
                        try dst_gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(info.dst_offset + chunk) } });
                        try block.instructions.append(allocator, .{ .result = dst_gep_name, .kind = .{ .gep = dst_gep } });

                        try block.instructions.append(allocator, .{ .result = null, .kind = .{ .store = .{
                            .ty = .{ .int = 64 },
                            .value = .{ .named = load_name },
                            .ptr = .{ .named = dst_gep_name },
                        } } });
                        chunk += 8;
                    } else if (remaining >= 4) {
                        const src_gep_name = try ownPrint(module, "cpy_src{}", .{temp_idx});
                        const load_name = try ownPrint(module, "cpy_val{}", .{temp_idx});
                        const dst_gep_name = try ownPrint(module, "cpy_dst{}", .{temp_idx});
                        temp_idx += 1;

                        var src_gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = src_ptr_name }, .indices = .empty };
                        errdefer src_gep.deinit(allocator);
                        try src_gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(chunk) } });
                        try block.instructions.append(allocator, .{ .result = src_gep_name, .kind = .{ .gep = src_gep } });

                        try block.instructions.append(allocator, .{ .result = load_name, .kind = .{ .load = .{
                            .ty = .{ .int = 32 },
                            .ptr = .{ .named = src_gep_name },
                        } } });

                        var dst_gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = "sret" }, .indices = .empty };
                        errdefer dst_gep.deinit(allocator);
                        try dst_gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(info.dst_offset + chunk) } });
                        try block.instructions.append(allocator, .{ .result = dst_gep_name, .kind = .{ .gep = dst_gep } });

                        try block.instructions.append(allocator, .{ .result = null, .kind = .{ .store = .{
                            .ty = .{ .int = 32 },
                            .value = .{ .named = load_name },
                            .ptr = .{ .named = dst_gep_name },
                        } } });
                        chunk += 4;
                    } else return error.UnsupportedAir;
                }
            },
            .param_field_copy => |info| {
                const src_ptr_name = function.params.items[info.param_index + 1].name;
                var chunk: u64 = 0;
                while (chunk < info.byte_count) {
                    const remaining = info.byte_count - chunk;
                    if (remaining >= 8) {
                        const src_gep_name = try ownPrint(module, "cpy_src{}", .{temp_idx});
                        const load_name = try ownPrint(module, "cpy_val{}", .{temp_idx});
                        const dst_gep_name = try ownPrint(module, "cpy_dst{}", .{temp_idx});
                        temp_idx += 1;

                        var src_gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = src_ptr_name }, .indices = .empty };
                        errdefer src_gep.deinit(allocator);
                        try src_gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(info.src_offset + chunk) } });
                        try block.instructions.append(allocator, .{ .result = src_gep_name, .kind = .{ .gep = src_gep } });

                        try block.instructions.append(allocator, .{ .result = load_name, .kind = .{ .load = .{
                            .ty = .{ .int = 64 },
                            .ptr = .{ .named = src_gep_name },
                        } } });

                        var dst_gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = "sret" }, .indices = .empty };
                        errdefer dst_gep.deinit(allocator);
                        try dst_gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(info.dst_offset + chunk) } });
                        try block.instructions.append(allocator, .{ .result = dst_gep_name, .kind = .{ .gep = dst_gep } });

                        try block.instructions.append(allocator, .{ .result = null, .kind = .{ .store = .{
                            .ty = .{ .int = 64 },
                            .value = .{ .named = load_name },
                            .ptr = .{ .named = dst_gep_name },
                        } } });
                        chunk += 8;
                    } else if (remaining >= 4) {
                        const src_gep_name = try ownPrint(module, "cpy_src{}", .{temp_idx});
                        const load_name = try ownPrint(module, "cpy_val{}", .{temp_idx});
                        const dst_gep_name = try ownPrint(module, "cpy_dst{}", .{temp_idx});
                        temp_idx += 1;

                        var src_gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = src_ptr_name }, .indices = .empty };
                        errdefer src_gep.deinit(allocator);
                        try src_gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(info.src_offset + chunk) } });
                        try block.instructions.append(allocator, .{ .result = src_gep_name, .kind = .{ .gep = src_gep } });

                        try block.instructions.append(allocator, .{ .result = load_name, .kind = .{ .load = .{
                            .ty = .{ .int = 32 },
                            .ptr = .{ .named = src_gep_name },
                        } } });

                        var dst_gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = "sret" }, .indices = .empty };
                        errdefer dst_gep.deinit(allocator);
                        try dst_gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(info.dst_offset + chunk) } });
                        try block.instructions.append(allocator, .{ .result = dst_gep_name, .kind = .{ .gep = dst_gep } });

                        try block.instructions.append(allocator, .{ .result = null, .kind = .{ .store = .{
                            .ty = .{ .int = 32 },
                            .value = .{ .named = load_name },
                            .ptr = .{ .named = dst_gep_name },
                        } } });
                        chunk += 4;
                    } else return error.UnsupportedAir;
                }
            },
            .param_scalar => |info| {
                const arg_name = function.params.items[info.param_index + 1].name;
                const dst_gep_name = try ownPrint(module, "dst_gep{}", .{temp_idx});
                temp_idx += 1;

                var dst_gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = "sret" }, .indices = .empty };
                errdefer dst_gep.deinit(allocator);
                try dst_gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(info.dst_offset) } });
                try block.instructions.append(allocator, .{ .result = dst_gep_name, .kind = .{ .gep = dst_gep } });

                try block.instructions.append(allocator, .{ .result = null, .kind = .{ .store = .{
                    .ty = info.ty,
                    .value = .{ .named = arg_name },
                    .ptr = .{ .named = dst_gep_name },
                } } });
            },
            .constant => |info| {
                const dst_gep_name = try ownPrint(module, "dst_gep{}", .{temp_idx});
                temp_idx += 1;

                var dst_gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = "sret" }, .indices = .empty };
                errdefer dst_gep.deinit(allocator);
                try dst_gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(info.dst_offset) } });
                try block.instructions.append(allocator, .{ .result = dst_gep_name, .kind = .{ .gep = dst_gep } });

                try block.instructions.append(allocator, .{ .result = null, .kind = .{ .store = .{
                    .ty = info.ty,
                    .value = .{ .int = info.value },
                    .ptr = .{ .named = dst_gep_name },
                } } });
            },
        }
    }

    block.terminator = .{ .ret = .{ .ty = .void } };
    try function.blocks.append(allocator, block);
    return function;
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
    if (air_aggregate_construction.planSretAggregateFromStores(function_type, structured_air_v2)) |plan| {
        return try lowerSretAggregateFromPlan(allocator, module, air_function, function_type, plan);
    }
    if (planSretFieldLoaderConstructor(function_type, structured_air_v2)) |plan| {
        return try lowerSretFieldLoaderPlan(allocator, module, air_function, function_type, plan);
    }
    if (!typedV2SretIntegerAggregateRecords(function_type, structured_air_v2)) return null;
    if (air_aggregate_copy.validateSretParamFieldConstructorRecords(function_type, structured_air_v2)) {
        return try lowerSretParamFieldConstructor(allocator, module, air_function, function_type, structured_air_v2);
    }
    return try lowerSretIntegerAggregateMake(allocator, module, air_function, function_type.return_type.ir_type);
}

pub fn typedV2SretIntegerAggregateRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (isSysVRegisterAggregateCandidate(function_type.return_type.ir_type)) return false;
    return validateSretAggregateMakeRecords(function_type, structured_air_v2) or
        air_aggregate_copy.validateSretParamFieldConstructorRecords(function_type, structured_air_v2) or
        air_aggregate_construction.planSretAggregateFromStores(function_type, structured_air_v2) != null or
        planSretFieldLoaderConstructor(function_type, structured_air_v2) != null;
}

pub fn lowerSretAggregateFromPlan(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    plan: air_aggregate_construction.RegisterAggregatePlan,
) !ir.Function {
    var function = ir.Function.init(shortFunctionName(air_function.name), .void);
    errdefer function.deinit(allocator);
    function.linkage = .default;
    function.calling_conv = null;

    const aggregate_ty = function_type.return_type.ir_type;
    try function.params.append(allocator, .{
        .ty = .ptr,
        .attrs = try sretAttrsForAggregate(module, aggregate_ty),
        .name = "sret",
    });

    for (function_type.params, 0..) |param, p_idx| {
        const arg_name = try ownPrint(module, "arg{}", .{p_idx});
        try function.params.append(allocator, .{ .ty = param.ir_type, .name = arg_name });
    }

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);

    const layout = x86_64SysVDataLayout() orelse return error.UnsupportedAir;
    const agg_plan = type_layout.aggregateLayoutPlan(layout, aggregate_ty) catch return error.UnsupportedAir;
    const leaves = agg_plan.leafSlice();

    for (0..plan.leaf_count) |leaf_idx| {
        const leaf_plan = plan.leaves[leaf_idx];
        const leaf_offset = leaves[leaf_idx].offset;
        const leaf_field_name = try ownPrint(module, "leaf{}", .{leaf_idx});

        var gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = "sret" }, .indices = .empty };
        errdefer gep.deinit(allocator);
        try gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(leaf_offset) } });
        try block.instructions.append(allocator, .{ .result = leaf_field_name, .kind = .{ .gep = gep } });

        const store_val: ir.Value = switch (leaf_plan.source) {
            .param => |p_idx| .{ .named = function.params.items[p_idx + 1].name },
            .param_shr => return error.UnsupportedAir,
            .constant_int => |c_val| if (leaf_plan.ty == .ptr and c_val == 0) .null_value else .{ .int = c_val },
        };
        try block.instructions.append(allocator, .{
            .result = null,
            .kind = .{ .store = .{
                .ty = leaf_plan.ty,
                .value = store_val,
                .ptr = .{ .named = leaf_field_name },
            } },
        });
    }

    block.terminator = .{ .ret = .{ .ty = .void } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn lowerSretParamFieldConstructor(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !ir.Function {
    const layout = x86_64SysVDataLayout() orelse return error.UnsupportedAir;
    const aggregate_ty = function_type.return_type.ir_type;
    const plan = type_layout.aggregateLayoutPlan(layout, aggregate_ty) catch return error.UnsupportedAir;
    const leaves = plan.leafSlice();
    if (leaves.len < 3) return error.UnsupportedAir;

    var function = ir.Function.init(shortFunctionName(air_function.name), .void);
    errdefer function.deinit(allocator);
    function.linkage = .default;
    function.calling_conv = null;

    try function.params.append(allocator, .{ .ty = .ptr, .attrs = try sretAttrsForAggregate(module, aggregate_ty), .name = "sret" });

    var param_leaf_names: [8][8][]const u8 = undefined;
    var param_leaf_counts: [8]usize = @splat(0);
    var global_arg_idx: usize = 0;
    for (function_type.params, 0..) |param, p_idx| {
        if (p_idx >= 8) return error.UnsupportedAir;
        if (param.ir_type == .aggregate) {
            const p_plan = type_layout.aggregateLayoutPlan(layout, param.ir_type) catch return error.UnsupportedAir;
            const p_leaves = p_plan.leafSlice();
            if (p_leaves.len > 8) return error.UnsupportedAir;
            param_leaf_counts[p_idx] = p_leaves.len;
            for (p_leaves, 0..) |p_leaf, pl_idx| {
                const arg_name = try ownPrint(module, "arg{}", .{global_arg_idx});
                global_arg_idx += 1;
                param_leaf_names[p_idx][pl_idx] = arg_name;
                try function.params.append(allocator, .{ .ty = p_leaf.ty, .name = arg_name });
            }
        } else {
            param_leaf_counts[p_idx] = 1;
            const arg_name = try ownPrint(module, "arg{}", .{global_arg_idx});
            global_arg_idx += 1;
            param_leaf_names[p_idx][0] = arg_name;
            try function.params.append(allocator, .{ .ty = param.ir_type, .name = arg_name });
        }
    }

    var field_param_map: [8]usize = undefined;
    const ret_ptr_index = air_model.typedRetPtrIndex(structured_air_v2) orelse return error.UnsupportedAir;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "store") and !std.mem.eql(u8, instruction.opcode, "store_safe")) continue;
        const raw_inst_index = std.fmt.parseInt(usize, instruction.operands[1].value, 10) catch return error.UnsupportedAir;
        const arg_inst_index = air_aggregate_construction.resolveParamIndex(structured_air_v2, raw_inst_index) orelse return error.UnsupportedAir;
        const ptr_inst_index = std.fmt.parseInt(u32, instruction.operands[0].value, 10) catch return error.UnsupportedAir;
        var path: [4]usize = undefined;
        const path_len = air_model.typedAggregatePointerPath(structured_air_v2, ptr_inst_index, ret_ptr_index, &path) orelse return error.UnsupportedAir;
        if (path_len != 1) return error.UnsupportedAir;
        const field_idx = path[0];
        if (field_idx >= 8) return error.UnsupportedAir;
        field_param_map[field_idx] = arg_inst_index;
    }

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);

    var leaf_idx: usize = 0;
    for (0..function_type.params.len) |field_idx| {
        const p_idx = field_param_map[field_idx];
        const count = param_leaf_counts[p_idx];
        for (0..count) |c| {
            if (leaf_idx >= leaves.len) return error.UnsupportedAir;
            const leaf = leaves[leaf_idx];
            leaf_idx += 1;
            const arg_name = param_leaf_names[p_idx][c];
            const leaf_field_name = try ownPrint(module, "leaf{}", .{leaf_idx - 1});

            var gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = .{ .named = "sret" }, .indices = .empty };
            errdefer gep.deinit(allocator);
            try gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(leaf.offset) } });
            try block.instructions.append(allocator, .{ .result = leaf_field_name, .kind = .{ .gep = gep } });
            try block.instructions.append(allocator, .{
                .result = null,
                .kind = .{ .store = .{
                    .ty = leaf.ty,
                    .value = .{ .named = arg_name },
                    .ptr = .{ .named = leaf_field_name },
                } },
            });
        }
    }

    block.terminator = .{ .ret = .{ .ty = .void } };
    try function.blocks.append(allocator, block);
    return function;
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
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => error.UnsupportedAir,
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
    if (try lowerTypedV2PackedBitfieldStore(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2PackedBitfieldLoad(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2PackedConstructor(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    return null;
}

pub const PackedBitfieldPtrInfo = air_model.PackedBitfieldPtrInfo;
pub const parsePackedBitfieldPointerType = air_types.parsePackedBitfieldPointerType;

pub const TypedPackedBitfieldStoreSummary = struct {
    host_bytes: u32,
    bit_offset: u32,
    field_bits: u32,
    value: bool,
};

pub fn typedPackedBitfieldStoreSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedPackedBitfieldStoreSummary {
    if (function_type.params.len != 1 or !function_type.params[0].ir_type.eql(.ptr) or
        !function_type.return_type.ir_type.eql(.void))
    {
        return null;
    }

    var field_ptr_inst_index: ?u32 = null;
    var bitfield_info: ?PackedBitfieldPtrInfo = null;

    for (structured_air_v2.instructions) |inst| {
        if (std.mem.startsWith(u8, inst.opcode, "struct_field_ptr")) {
            if (parsePackedBitfieldPointerType(inst.result_type)) |info| {
                field_ptr_inst_index = inst.index;
                bitfield_info = info;
                break;
            }
        }
    }

    const target_field_index = field_ptr_inst_index orelse return null;
    const info = bitfield_info orelse return null;

    for (structured_air_v2.instructions) |inst| {
        if (std.mem.eql(u8, inst.opcode, "store") or std.mem.eql(u8, inst.opcode, "store_safe")) {
            if (inst.operands.len >= 2) {
                const dst_idx = air_model.typedInstOperandIndex(inst.operands[0]) orelse continue;
                if (dst_idx == target_field_index) {
                    const operand1_text = air_model.operandTextDetail(inst, 1) orelse inst.operands[1].value;
                    const val: bool = if (std.mem.eql(u8, operand1_text, "@.bool_true"))
                        true
                    else if (std.mem.eql(u8, operand1_text, "@.bool_false"))
                        false
                    else
                        return null;

                    return .{
                        .host_bytes = info.host_bytes,
                        .bit_offset = info.bit_offset,
                        .field_bits = info.field_bits,
                        .value = val,
                    };
                }
            }
        }
    }

    return null;
}

pub fn lowerTypedV2PackedBitfieldStore(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = typedPackedBitfieldStoreSummary(function_type, structured_air_v2) orelse return null;
    var function = ir.Function.init(shortFunctionName(air_function.name), .void);
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .ptr, .name = "arg0" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);

    const host_ty: ir.Type = .{ .int = @intCast(summary.host_bytes * 8) };

    try block.instructions.append(allocator, .{
        .result = "air0",
        .kind = .{ .load = .{ .ty = host_ty, .ptr = .{ .named = "arg0" } } },
    });

    const mask: i128 = @as(i128, 1) << @intCast(summary.bit_offset);
    try block.instructions.append(allocator, .{
        .result = "air1",
        .kind = .{ .binary = .{
            .op = if (summary.value) .@"or" else .@"and",
            .ty = host_ty,
            .lhs = .{ .named = "air0" },
            .rhs = .{ .int = if (summary.value) mask else ~mask },
        } },
    });

    try block.instructions.append(allocator, .{
        .result = null,
        .kind = .{ .store = .{
            .ty = host_ty,
            .ptr = .{ .named = "arg0" },
            .value = .{ .named = "air1" },
        } },
    });

    block.terminator = .{ .ret = .{ .ty = .void, .value = null } };
    try function.blocks.append(allocator, block);
    return function;
}

pub const TypedPackedBitfieldLoadSummary = struct {
    arg_is_ptr_addr: bool,
    arg_is_ptr_mem: bool,
    host_bytes: u32,
    bit_offset: u32,
    field_bits: u32,
};

pub fn typedPackedBitfieldLoadSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedPackedBitfieldLoadSummary {
    if (function_type.params.len != 1) return null;
    const ret_bits: u32 = switch (function_type.return_type.ir_type) {
        .int => |b| b,
        else => return null,
    };

    var field_ptr_inst_index: ?u32 = null;
    var bitfield_info: ?PackedBitfieldPtrInfo = null;

    for (structured_air_v2.instructions) |inst| {
        if (std.mem.startsWith(u8, inst.opcode, "struct_field_ptr")) {
            if (parsePackedBitfieldPointerType(inst.result_type)) |info| {
                field_ptr_inst_index = inst.index;
                bitfield_info = info;
                break;
            }
        }
    }

    const target_field_index = field_ptr_inst_index orelse return null;
    const info = bitfield_info orelse return null;
    if (info.field_bits != ret_bits) return null;

    var load_inst_index: ?u32 = null;
    for (structured_air_v2.instructions) |inst| {
        if (std.mem.eql(u8, inst.opcode, "load")) {
            if (inst.operands.len >= 1) {
                const src_idx = air_model.typedInstOperandIndex(inst.operands[0]) orelse continue;
                if (src_idx == target_field_index) {
                    load_inst_index = inst.index;
                    break;
                }
            }
        }
    }
    _ = load_inst_index orelse return null;

    var has_int_from_ptr = false;
    for (structured_air_v2.instructions) |inst| {
        if (std.mem.eql(u8, inst.opcode, "int_from_ptr")) {
            has_int_from_ptr = true;
            break;
        }
    }

    const is_ptr = function_type.params[0].ir_type == .ptr;

    return .{
        .arg_is_ptr_addr = is_ptr and has_int_from_ptr,
        .arg_is_ptr_mem = is_ptr and !has_int_from_ptr,
        .host_bytes = info.host_bytes,
        .bit_offset = info.bit_offset,
        .field_bits = info.field_bits,
    };
}

pub fn lowerTypedV2PackedBitfieldLoad(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = typedPackedBitfieldLoadSummary(function_type, structured_air_v2) orelse return null;
    const ret_ty = function_type.return_type.ir_type;
    var function = ir.Function.init(shortFunctionName(air_function.name), ret_ty);
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    const attrs: ?[]const u8 = if (function_type.params[0].ir_type.eql(.{ .int = 8 }) and !function_type.params[0].signed)
        "zeroext"
    else
        null;
    try function.params.append(allocator, .{
        .ty = function_type.params[0].ir_type,
        .attrs = attrs,
        .name = "arg0",
    });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);

    const host_bits = @as(u16, @intCast(summary.host_bytes * 8));
    const host_ty: ir.Type = .{ .int = host_bits };

    var host_val: ir.Value = undefined;

    if (summary.arg_is_ptr_addr) {
        try block.instructions.append(allocator, .{
            .result = "air0",
            .kind = .{ .cast = .{
                .op = .ptrtoint,
                .from_ty = .ptr,
                .value = .{ .named = "arg0" },
                .to_ty = host_ty,
            } },
        });
        host_val = .{ .named = "air0" };
    } else if (summary.arg_is_ptr_mem) {
        try block.instructions.append(allocator, .{
            .result = "air0",
            .kind = .{ .load = .{ .ty = host_ty, .ptr = .{ .named = "arg0" } } },
        });
        host_val = .{ .named = "air0" };
    } else {
        host_val = .{ .named = "arg0" };
    }

    var shifted_val = host_val;
    if (summary.bit_offset > 0) {
        try block.instructions.append(allocator, .{
            .result = "air_shift",
            .kind = .{ .binary = .{
                .op = .lshr,
                .ty = host_ty,
                .lhs = host_val,
                .rhs = .{ .int = summary.bit_offset },
            } },
        });
        shifted_val = .{ .named = "air_shift" };
    }

    var result_val = shifted_val;
    if (summary.field_bits < host_bits) {
        try block.instructions.append(allocator, .{
            .result = "air_trunc",
            .kind = .{ .cast = .{
                .op = .trunc,
                .from_ty = host_ty,
                .value = shifted_val,
                .to_ty = ret_ty,
            } },
        });
        result_val = .{ .named = "air_trunc" };
    }

    block.terminator = .{ .ret = .{ .ty = ret_ty, .value = result_val } };
    try function.blocks.append(allocator, block);
    return function;
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

pub const PackedConstructorFieldSource = union(enum) {
    param: usize,
    constant_int: u128,
};

pub const PackedConstructorField = struct {
    bit_offset: u32,
    field_bits: u32,
    source: PackedConstructorFieldSource,
};

pub const PackedConstructorSummary = struct {
    host_bits: u16,
    field_count: usize,
    fields: [16]PackedConstructorField,
};

pub fn typedPackedConstructorSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?PackedConstructorSummary {
    const host_bits = switch (function_type.return_type.ir_type) {
        .int => |b| b,
        else => return null,
    };
    if (host_bits == 0 or host_bits > 64) return null;

    const ret_ptr_index = air_model.typedRetPtrIndex(structured_air_v2) orelse return null;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret_ptr") != 1) return null;
    if (air_model.typedOpcodeCount(structured_air_v2, "ret_load") != 1) return null;

    var summary = PackedConstructorSummary{
        .host_bits = host_bits,
        .field_count = 0,
        .fields = undefined,
    };

    for (structured_air_v2.instructions) |inst| {
        if (!std.mem.eql(u8, inst.opcode, "store") and !std.mem.eql(u8, inst.opcode, "store_safe")) continue;
        if (inst.operands.len < 2) return null;

        const ptr_idx = air_model.typedInstOperandIndex(inst.operands[0]) orelse return null;
        const ptr_inst = air_model.instructionByIndex(structured_air_v2, ptr_idx) orelse return null;
        if (!std.mem.startsWith(u8, ptr_inst.opcode, "struct_field_ptr")) return null;
        if (ptr_inst.operands.len < 1) return null;
        const base_idx = air_model.typedInstOperandIndex(ptr_inst.operands[0]) orelse return null;
        if (base_idx != ret_ptr_index) return null;

        const info = parsePackedBitfieldPointerType(ptr_inst.result_type) orelse return null;
        var field_bits = info.field_bits;
        if (info.bit_offset >= host_bits) return null;
        if (field_bits > host_bits - info.bit_offset) {
            field_bits = host_bits - info.bit_offset;
        }

        const source: PackedConstructorFieldSource = blk: {
            if (std.mem.eql(u8, inst.operands[1].kind, "const")) {
                const c = air_aggregate_construction.parseConstIntOperand(inst, 1) orelse return null;
                break :blk .{ .constant_int = @intCast(c) };
            } else if (std.mem.eql(u8, inst.operands[1].kind, "inst")) {
                const val_idx = air_model.typedInstOperandIndex(inst.operands[1]) orelse return null;
                const param_idx = air_aggregate_construction.resolveParamIndex(structured_air_v2, val_idx) orelse return null;
                if (param_idx >= function_type.params.len) return null;
                break :blk .{ .param = param_idx };
            } else return null;
        };

        if (summary.field_count >= summary.fields.len) return null;
        summary.fields[summary.field_count] = .{
            .bit_offset = info.bit_offset,
            .field_bits = field_bits,
            .source = source,
        };
        summary.field_count += 1;
    }

    if (summary.field_count == 0) return null;
    return summary;
}

pub fn typedV2PackedConstructorRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return typedPackedConstructorSummary(function_type, structured_air_v2) != null;
}

const packed_arg_names = [_][]const u8{
    "arg0", "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7",
};
const packed_cast_names = [_][]const u8{
    "cast0", "cast1", "cast2",  "cast3",  "cast4",  "cast5",  "cast6",  "cast7",
    "cast8", "cast9", "cast10", "cast11", "cast12", "cast13", "cast14", "cast15",
};
const packed_mask_names = [_][]const u8{
    "mask0", "mask1", "mask2",  "mask3",  "mask4",  "mask5",  "mask6",  "mask7",
    "mask8", "mask9", "mask10", "mask11", "mask12", "mask13", "mask14", "mask15",
};
const packed_shl_names = [_][]const u8{
    "shl0", "shl1", "shl2",  "shl3",  "shl4",  "shl5",  "shl6",  "shl7",
    "shl8", "shl9", "shl10", "shl11", "shl12", "shl13", "shl14", "shl15",
};
const packed_comb_names = [_][]const u8{
    "comb0", "comb1", "comb2",  "comb3",  "comb4",  "comb5",  "comb6",  "comb7",
    "comb8", "comb9", "comb10", "comb11", "comb12", "comb13", "comb14", "comb15",
};
const packed_const_names = [_][]const u8{
    "const_or0", "const_or1", "const_or2", "const_or3",
};

pub fn lowerTypedV2PackedConstructor(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = typedPackedConstructorSummary(function_type, structured_air_v2) orelse return null;
    const host_ty: ir.Type = .{ .int = summary.host_bits };

    var function = ir.Function.init(shortFunctionName(air_function.name), host_ty);
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);

    for (function_type.params, 0..) |param, p_idx| {
        if (p_idx >= packed_arg_names.len) return error.UnsupportedAir;
        try function.params.append(allocator, .{ .ty = param.ir_type, .name = packed_arg_names[p_idx] });
    }

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);

    var constant_accum: u128 = 0;
    var current_result_name: ?[]const u8 = null;
    var inst_counter: usize = 0;

    for (summary.fields[0..summary.field_count]) |field| {
        const mask: u128 = if (field.field_bits >= 128)
            ~@as(u128, 0)
        else
            (@as(u128, 1) << @intCast(field.field_bits)) - 1;

        switch (field.source) {
            .constant_int => |c| {
                constant_accum |= (c & mask) << @intCast(field.bit_offset);
            },
            .param => |p_idx| {
                const param_ty = function_type.params[p_idx].ir_type;
                var val_name = function.params.items[p_idx].name;

                if (!param_ty.eql(host_ty)) {
                    if (inst_counter >= packed_cast_names.len) return error.UnsupportedAir;
                    const cast_name = packed_cast_names[inst_counter];
                    inst_counter += 1;
                    const param_bits = switch (param_ty) {
                        .int => |b| b,
                        else => return error.UnsupportedAir,
                    };
                    try block.instructions.append(allocator, .{
                        .result = cast_name,
                        .kind = .{ .cast = .{
                            .op = if (param_bits < summary.host_bits) .zext else .trunc,
                            .from_ty = param_ty,
                            .to_ty = host_ty,
                            .value = .{ .named = val_name },
                        } },
                    });
                    val_name = cast_name;
                }

                var masked_name = val_name;
                const full_host_mask: u128 = if (summary.host_bits >= 128)
                    ~@as(u128, 0)
                else
                    (@as(u128, 1) << @intCast(summary.host_bits)) - 1;

                if (mask != full_host_mask) {
                    if (inst_counter >= packed_mask_names.len) return error.UnsupportedAir;
                    const m_name = packed_mask_names[inst_counter];
                    inst_counter += 1;
                    try block.instructions.append(allocator, .{
                        .result = m_name,
                        .kind = .{ .binary = .{
                            .op = .@"and",
                            .ty = host_ty,
                            .lhs = .{ .named = val_name },
                            .rhs = .{ .int = @intCast(mask) },
                        } },
                    });
                    masked_name = m_name;
                }

                var shifted_name = masked_name;
                if (field.bit_offset != 0) {
                    if (inst_counter >= packed_shl_names.len) return error.UnsupportedAir;
                    const s_name = packed_shl_names[inst_counter];
                    inst_counter += 1;
                    try block.instructions.append(allocator, .{
                        .result = s_name,
                        .kind = .{ .binary = .{
                            .op = .shl,
                            .ty = host_ty,
                            .lhs = .{ .named = masked_name },
                            .rhs = .{ .int = field.bit_offset },
                        } },
                    });
                    shifted_name = s_name;
                }

                if (current_result_name) |prev| {
                    if (inst_counter >= packed_comb_names.len) return error.UnsupportedAir;
                    const comb_name = packed_comb_names[inst_counter];
                    inst_counter += 1;
                    try block.instructions.append(allocator, .{
                        .result = comb_name,
                        .kind = .{ .binary = .{
                            .op = .@"or",
                            .ty = host_ty,
                            .lhs = .{ .named = prev },
                            .rhs = .{ .named = shifted_name },
                        } },
                    });
                    current_result_name = comb_name;
                } else {
                    current_result_name = shifted_name;
                }
            },
        }
    }

    if (constant_accum != 0) {
        if (current_result_name) |prev| {
            const final_name = packed_const_names[0];
            try block.instructions.append(allocator, .{
                .result = final_name,
                .kind = .{ .binary = .{
                    .op = .@"or",
                    .ty = host_ty,
                    .lhs = .{ .named = prev },
                    .rhs = .{ .int = @intCast(constant_accum) },
                } },
            });
            current_result_name = final_name;
        } else {
            block.terminator = .{ .ret = .{ .ty = host_ty, .value = .{ .int = @intCast(constant_accum) } } };
            try function.blocks.append(allocator, block);
            return function;
        }
    }

    const ret_val: ir.Value = if (current_result_name) |name|
        .{ .named = name }
    else
        .{ .int = 0 };

    block.terminator = .{ .ret = .{ .ty = host_ty, .value = ret_val } };
    try function.blocks.append(allocator, block);
    return function;
}
