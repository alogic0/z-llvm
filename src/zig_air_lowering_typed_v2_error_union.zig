const std = @import("std");
const air_export = @import("zig_air_export.zig");
const error_union_call_facts = @import("zig_air_error_union_call_facts.zig");
const air_model = @import("zig_air_model.zig");
const ir = @import("ir.zig");

const FunctionType = air_model.FunctionType;
const ZigType = air_model.ZigType;
const irCallingConvention = air_model.irCallingConvention;
const shortFunctionName = air_model.shortFunctionName;

pub fn lowerTypedV2ErrorUnionPayload(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
    fact_provider: ?error_union_call_facts.Provider,
    fact_fallback_reason: ?*?[]const u8,
) !?ir.Function {
    const flow = switch (air_model.typedErrorUnionFlow(function_type, structured_air_v2)) {
        .flow => |flow| flow,
        .diagnostic => return null,
    };
    if (flow.payload_kind != .call_produced) return null;
    return try lowerErrorUnionPayloadFromFact(allocator, module, air_function, function_type, flow, fact_provider, fact_fallback_reason);
}

pub fn typedV2ErrorUnionPayloadRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedErrorUnionPayloadSummary(function_type, structured_air_v2) != null;
}

fn lowerErrorUnionPayloadFromFact(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    flow: air_model.TypedErrorUnionFlow,
    fact_provider: ?error_union_call_facts.Provider,
    fact_fallback_reason: ?*?[]const u8,
) !ir.Function {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        setErrorUnionCallFactFallback(fact_fallback_reason, "unsupported_error_union_payload_signature");
        return error.UnsupportedAir;
    }
    const call_inst = flow.call_result_owner orelse {
        setErrorUnionCallFactFallback(fact_fallback_reason, "missing_call_result_owner");
        return error.UnsupportedAir;
    };
    if (flow.post_success_branch_target == null or flow.post_catch_branch_target == null) {
        setErrorUnionCallFactFallback(fact_fallback_reason, "missing_error_union_branch_target");
        return error.UnsupportedAir;
    }
    const catch_value = flow.catch_value_i32 orelse {
        setErrorUnionCallFactFallback(fact_fallback_reason, "missing_catch_i32_value");
        return error.UnsupportedAir;
    };
    const provider = fact_provider orelse {
        setErrorUnionCallFactFallback(fact_fallback_reason, "missing_error_union_call_fact_provider");
        return error.UnsupportedAir;
    };
    const fact = provider.lookup(air_function.name, call_inst) orelse {
        setErrorUnionCallFactFallback(fact_fallback_reason, "missing_error_union_call_fact");
        return error.UnsupportedAir;
    };
    if (fact.success_arg_index != 0) {
        setErrorUnionCallFactFallback(fact_fallback_reason, "unsupported_error_union_success_argument");
        return error.UnsupportedAir;
    }
    if (!isI32ErrorUnionResultType(fact.result_type)) {
        setErrorUnionCallFactFallback(fact_fallback_reason, "unsupported_error_union_fact_result_type");
        return error.UnsupportedAir;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_success",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 32 },
            .lhs = .{ .named = "arg0" },
            .rhs = .{ .int = fact.success_arg_eq_i32 },
        } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "is_success" },
            .ty = .{ .int = 32 },
            .true_value = .{ .int = fact.success_payload_i32 },
            .false_value = .{ .int = catch_value },
        } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    _ = module;
    return function;
}

fn isI32ErrorUnionResultType(text: []const u8) bool {
    return std.mem.startsWith(u8, text, "error{") and std.mem.endsWith(u8, text, "!i32");
}

fn setErrorUnionCallFactFallback(fallback_reason: ?*?[]const u8, reason: []const u8) void {
    const slot = fallback_reason orelse return;
    if (slot.* != null) return;
    slot.* = reason;
}

test "typed-v2 error-union payload reports missing call fact provider" {
    var i32_param = [_]ZigType{
        .{ .ir_type = .{ .int = 32 } },
    };
    const function_type = FunctionType{
        .params = &i32_param,
        .return_type = .{ .ir_type = .{ .int = 32 } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    var is_non_err_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "1", .type_text = "error{Bad}!i32" },
    };
    var payload_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "1", .type_text = "error{Bad}!i32" },
    };
    var err_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "1", .type_text = "error{Bad}!i32" },
    };
    var success_br_operands = [_]air_export.TypedOperand{
        .{ .kind = "block", .value = "5", .type_text = "block" },
        .{ .kind = "inst", .value = "3", .type_text = "i32" },
    };
    var catch_br_operands = [_]air_export.TypedOperand{
        .{ .kind = "block", .value = "5", .type_text = "block" },
        .{ .kind = "const", .value = "-", .type_text = "i32" },
    };
    var catch_br_details = [_]air_export.TypedDetail{
        .{ .key = "operand1_text", .value = "<i32, -1>" },
    };
    var cond_br_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "2", .type_text = "bool" },
    };
    var call_details = [_]air_export.TypedDetail{
        .{ .key = "call_signature", .value = "fn (i32) error{Bad}!i32" },
        .{ .key = "callee_text", .value = "(function 'maybeError')" },
    };
    var instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "i32", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "call", .result_type = "error{Bad}!i32", .data_kind = "pl_op", .operands = &.{}, .details = &call_details },
        .{ .index = 2, .opcode = "is_non_err", .result_type = "i1", .data_kind = "un_op", .operands = &is_non_err_operands },
        .{ .index = 3, .opcode = "unwrap_errunion_payload", .result_type = "i32", .data_kind = "ty_op", .operands = &payload_operands },
        .{ .index = 4, .opcode = "unwrap_errunion_err", .result_type = "i16", .data_kind = "ty_op", .operands = &err_operands },
        .{ .index = 5, .opcode = "block", .result_type = "void", .data_kind = "ty_pl", .operands = &.{} },
        .{ .index = 6, .opcode = "br", .result_type = "noreturn", .data_kind = "br", .operands = &success_br_operands },
        .{ .index = 7, .opcode = "br", .result_type = "noreturn", .data_kind = "br", .operands = &catch_br_operands, .details = &catch_br_details },
        .{ .index = 8, .opcode = "cond_br", .result_type = "noreturn", .data_kind = "pl_op", .operands = &cond_br_operands },
        .{ .index = 9, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = &.{} },
    };
    const structured_air_v2 = air_export.StructuredAirV2{ .instructions = &instructions };
    const air_function = air_export.Function{
        .name = "aggregates.error_union_payload",
        .type_text = "fn(i32) callconv(.c) i32",
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

    var module: ir.Module = undefined;
    var reason: ?[]const u8 = null;
    try std.testing.expectError(
        error.UnsupportedAir,
        lowerTypedV2ErrorUnionPayload(
            std.testing.allocator,
            &module,
            air_function,
            function_type,
            structured_air_v2,
            null,
            &reason,
        ),
    );
    try std.testing.expectEqualStrings("missing_error_union_call_fact_provider", reason.?);
}
