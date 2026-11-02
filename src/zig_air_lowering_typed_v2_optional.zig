const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_model = @import("zig_air_model.zig");
const ir = @import("ir.zig");

const FunctionType = air_model.FunctionType;
const irCallingConvention = air_model.irCallingConvention;
const ownPrint = air_model.ownPrint;
const shortFunctionName = air_model.shortFunctionName;

pub fn lowerTypedV2MaybeError(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = air_model.typedMaybeErrorSummary(function_type, structured_air_v2) orelse return null;
    if (summary.kind != .maybe_error) return error.UnsupportedAir;
    const param_ty = function_type.params[0].ir_type;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 64 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = param_ty, .name = "arg0" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_error",
        .kind = .{ .icmp = .{
            .predicate = .ne,
            .operand_ty = param_ty,
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = 0 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "is_error" },
            .ty = .{ .int = 64 },
            .true_value = .{ .int = 1 },
            .false_value = .{ .int = 7 },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 64 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn typedV2MaybeErrorRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedMaybeErrorSummary(function_type, structured_air_v2) != null;
}

pub fn lowerTypedV2OptionalPayload(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = air_model.typedOptionalPayloadSummary(function_type, structured_air_v2) orelse return null;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg1" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    const payload_value: ir.Value = switch (summary.kind) {
        .local_merge => .{ .named = "arg1" },
        .helper_return => helper_return: {
            if (summary.callee_external) return error.UnsupportedAir;
            const dot = std.mem.lastIndexOfScalar(u8, air_function.name, '.') orelse return error.UnsupportedAir;
            const callee_name = try ownPrint(module, "{s}.{s}", .{ air_function.name[0..dot], summary.callee_name });
            var call = ir.CallInst{
                .ret_ty = .{ .int = 32 },
                .callee = callee_name,
                .calling_conv = "fastcc",
                .args = .empty,
            };
            errdefer call.deinit(allocator);
            try call.args.append(allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "arg0" } });
            try call.args.append(allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "arg1" } });
            try block.instructions.append(allocator, .{ .result = "optional_value", .kind = .{ .call = call } });
            call.args = .empty;
            break :helper_return .{ .named = "optional_value" };
        },
    };
    try block.instructions.append(allocator, .{
        .result = "is_null",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 32 },
            .lhs = switch (summary.kind) {
                .local_merge => .{ .named = "arg0" },
                .helper_return => payload_value,
            },
            .rhs = .{ .int = 0 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "is_null" },
            .ty = .{ .int = 32 },
            .true_value = .{ .int = summary.fallback },
            .false_value = payload_value,
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn lowerTypedV2OptionalPayloadBranch(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = air_model.typedOptionalPayloadBranchSummary(function_type, structured_air_v2) orelse return null;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg1" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg2" });

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "has_value",
        .kind = .{ .icmp = .{
            .predicate = .ne,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = 0 },
        } },
    });
    if (summary.threshold == std.math.maxInt(i32)) return error.UnsupportedAir;
    try block.instructions.append(allocator, .{
        .result = "payload_low",
        .kind = .{ .icmp = .{
            .predicate = .slt,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = "arg1" },
            .rhs = .{ .int = summary.threshold + 1 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "high_result",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "arg1" },
            .rhs = .{ .named = "arg2" },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "low_result",
        .kind = .{ .binary = .{
            .op = .sub,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "arg1" },
            .rhs = .{ .named = "arg2" },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "payload_result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "payload_low" },
            .ty = .{ .int = 32 },
            .true_value = .{ .named = "low_result" },
            .false_value = .{ .named = "high_result" },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "has_value" },
            .ty = .{ .int = 32 },
            .true_value = .{ .named = "payload_result" },
            .false_value = .{ .int = summary.fallback },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn typedV2OptionalPayloadBranchRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedOptionalPayloadBranchSummary(function_type, structured_air_v2) != null;
}

pub fn typedV2OptionalPayloadRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedOptionalPayloadSummary(function_type, structured_air_v2) != null;
}

pub fn lowerTypedV2OptionalPointer(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    const summary = air_model.typedOptionalPointerSummary(function_type, structured_air_v2) orelse return null;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .ptr, .name = "arg0" });

    var entry = ir.BasicBlock.init("entry");
    errdefer entry.deinit(allocator);
    try entry.instructions.append(allocator, .{
        .result = "is_null",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .ptr,
            .lhs = .{ .named = "arg0" },
            .rhs = .null_value,
        } },
    });
    entry.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "is_null" },
        .then_target = "merge",
        .else_target = "load",
    } };
    try function.blocks.append(allocator, entry);

    var load = ir.BasicBlock.init("load");
    errdefer load.deinit(allocator);
    try load.instructions.append(allocator, .{
        .result = "loaded",
        .kind = .{ .load = .{ .ty = .{ .int = 32 }, .ptr = .{ .named = "arg0" } } },
    });
    const loaded_value_name = if (summary.add_imm == 0) "loaded" else "adjusted";
    if (summary.add_imm != 0) {
        try load.instructions.append(allocator, .{
            .result = loaded_value_name,
            .kind = .{ .binary = .{
                .op = .add,
                .ty = .{ .int = 32 },
                .lhs = .{ .named = "loaded" },
                .rhs = .{ .int = summary.add_imm },
            } },
        });
    }
    load.terminator = .{ .br = .{ .target = "merge" } };
    try function.blocks.append(allocator, load);

    var merge = ir.BasicBlock.init("merge");
    errdefer merge.deinit(allocator);
    var phi: ir.PhiInst = .{ .ty = .{ .int = 32 }, .incoming = .empty };
    errdefer phi.deinit(allocator);
    try phi.incoming.append(allocator, .{ .value = .{ .int = summary.fallback }, .block = "entry" });
    try phi.incoming.append(allocator, .{ .value = .{ .named = loaded_value_name }, .block = "load" });
    try merge.instructions.append(allocator, .{ .result = "result", .kind = .{ .phi = phi } });
    merge.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, merge);
    return function;
}

pub fn typedV2OptionalPointerRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedOptionalPointerSummary(function_type, structured_air_v2) != null;
}

test "typed-v2 optional payload lowers helper-return optional flow" {
    var call_operands = [_]air_export.TypedOperand{
        .{ .kind = "const", .value = "809", .type_text = "fn (i32, i32) ?i32" },
        .{ .kind = "inst", .value = "0", .type_text = "i32" },
        .{ .kind = "inst", .value = "1", .type_text = "i32" },
    };
    var call_details = [_]air_export.TypedDetail{
        .{ .key = "callee_text", .value = "<fn (i32, i32) ?i32, (function 'frontierMaybeOptionalReturn')>" },
        .{ .key = "call_signature", .value = "fn (i32, i32) ?i32" },
    };
    var optional_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "3", .type_text = "?i32" },
    };
    var payload_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "3", .type_text = "?i32" },
    };
    var payload_br_operands = [_]air_export.TypedOperand{
        .{ .kind = "block", .value = "6", .type_text = "block" },
        .{ .kind = "inst", .value = "8", .type_text = "i32" },
    };
    var fallback_br_operands = [_]air_export.TypedOperand{
        .{ .kind = "block", .value = "6", .type_text = "block" },
        .{ .kind = "const", .value = "814", .type_text = "i32" },
    };
    var fallback_br_details = [_]air_export.TypedDetail{
        .{ .key = "operand1_text", .value = "<i32, -74>" },
    };
    var cond_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "7", .type_text = "bool" },
    };
    var ret_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "6", .type_text = "i32" },
    };
    var instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "i32", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "arg", .result_type = "i32", .data_kind = "arg", .operands = &.{} },
        .{ .index = 3, .opcode = "call", .result_type = "call-result", .data_kind = "call", .operands = &call_operands, .details = &call_details },
        .{ .index = 6, .opcode = "block", .result_type = "block-result", .data_kind = "opaque", .operands = &.{} },
        .{ .index = 7, .opcode = "is_non_null", .result_type = "typed-result", .data_kind = "un_op", .operands = &optional_operands },
        .{ .index = 8, .opcode = "optional_payload", .result_type = "i32", .data_kind = "ty_op", .operands = &payload_operands },
        .{ .index = 9, .opcode = "br", .result_type = "noreturn", .data_kind = "br", .operands = &payload_br_operands },
        .{ .index = 10, .opcode = "br", .result_type = "noreturn", .data_kind = "br", .operands = &fallback_br_operands, .details = &fallback_br_details },
        .{ .index = 11, .opcode = "cond_br", .result_type = "noreturn", .data_kind = "cond_br", .operands = &cond_operands },
        .{ .index = 13, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = &ret_operands },
    };
    const structured_air_v2 = air_export.StructuredAirV2{ .instructions = &instructions };
    var params = [_]air_model.ZigType{
        .{ .ir_type = .{ .int = 32 } },
        .{ .ir_type = .{ .int = 32 } },
    };
    const function_type = FunctionType{
        .params = &params,
        .return_type = .{ .ir_type = .{ .int = 32 } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    const air_function = air_export.Function{
        .name = "frontier_optionals_errors.frontier_optional_return_match",
        .type_text = "fn (i32, i32) callconv(.c) i32",
        .instruction_count = instructions.len,
        .main_body_count = instructions.len,
        .has_liveness = false,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = structured_air_v2,
        .instructions = &.{},
    };
    var module: ir.Module = .{
        .allocator = std.testing.allocator,
        .source = try std.testing.allocator.dupe(u8, ""),
        .owned_strings = .empty,
        .module_asm = .empty,
        .named_types = .empty,
        .globals = .empty,
        .aliases = .empty,
        .comdats = .empty,
        .declarations = .empty,
        .functions = .empty,
        .attribute_groups = .empty,
        .metadata = .empty,
    };
    defer module.deinit();

    var function = (try lowerTypedV2OptionalPayload(std.testing.allocator, &module, air_function, function_type, structured_air_v2)).?;
    defer function.deinit(std.testing.allocator);
    try std.testing.expectEqualStrings("frontier_optionals_errors.frontier_optional_return_match", function.name);
}
