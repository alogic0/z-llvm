const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_model = @import("zig_air_model.zig");
const air_types = @import("zig_air_types.zig");
const ir = @import("ir.zig");
const typed_v2 = @import("zig_air_lowering_typed_v2.zig");

const FunctionType = air_model.FunctionType;
const parseFunctionType = air_types.parseFunctionType;
const ownPrint = air_model.ownPrint;
const shortFunctionName = air_model.shortFunctionName;

const isSysVRegisterAggregateCandidate = typed_v2.isSysVRegisterAggregateCandidate;
const typedV2RegisterAggregateLeafPaths = typed_v2.typedV2RegisterAggregateLeafPaths;

pub fn lowerRegisterAggregateMake(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    structured_air_v2: air_export.StructuredAirV2,
) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    const aggregate_ty = function_type.return_type.ir_type;
    if (!isSysVRegisterAggregateCandidate(aggregate_ty)) return error.UnsupportedAir;
    if (function_type.params.len == 0 or function_type.params.len > 8) return error.UnsupportedAir;
    var leaf_paths: [8][]const u8 = undefined;
    if (!typedV2RegisterAggregateLeafPaths(function_type, structured_air_v2, &leaf_paths)) return error.UnsupportedAir;
    for (function_type.params) |param| {
        if (!param.ir_type.eql(.{ .int = 32 }) and !param.ir_type.eql(.{ .int = 64 }) and
            !param.ir_type.eql(.float) and !param.ir_type.eql(.double)) return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), aggregate_ty);
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    const arg_names = [_][]const u8{ "arg0", "arg1", "arg2", "arg3", "arg4", "arg5", "arg6", "arg7" };
    for (function_type.params, 0..) |param, index| {
        try function.params.append(allocator, .{ .ty = param.ir_type, .name = arg_names[index] });
    }
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    const result_names = [_][]const u8{ "field0", "field1", "field2", "field3", "field4", "field5", "field6", "result" };
    var aggregate_value: ir.Value = .undef;
    for (function_type.params, 0..) |param, index| {
        try block.instructions.append(allocator, .{
            .result = result_names[index],
            .kind = .{ .insertvalue = .{
                .aggregate_ty = aggregate_ty,
                .aggregate = aggregate_value,
                .value_ty = param.ir_type,
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

pub fn lowerMixCAddMayPanic(allocator: std.mem.Allocator, module: *ir.Module, air_function: air_export.Function) !ir.Function {
    return lowerMixCAddMayPanicChecked(allocator, module, air_function, functionHasOpcode(air_function, "add_safe"));
}

pub fn lowerMixCAddMayPanicChecked(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    checked_add: bool,
) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }
    try ensureNegativeIntGlobal(allocator, module);
    const zig_k_name = try mixCGlobalName(module, air_function.name, "zig_k");

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = .internal;
    function.calling_conv = "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg0" });

    var entry = ir.BasicBlock.init("entry");
    errdefer entry.deinit(allocator);
    try entry.instructions.append(allocator, .{
        .result = "is_negative",
        .kind = .{ .icmp = .{ .predicate = .slt, .operand_ty = .{ .int = 32 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 0 } } },
    });
    entry.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "is_negative" },
        .then_target = "panic",
        .else_target = "ok",
    } };
    try function.blocks.append(allocator, entry);

    var panic = ir.BasicBlock.init("panic");
    errdefer panic.deinit(allocator);
    var assume_call: ir.CallInst = .{ .ret_ty = .void, .callee = "llvm.assume", .args = .empty };
    errdefer assume_call.deinit(allocator);
    try assume_call.args.append(allocator, .{ .ty = .{ .int = 1 }, .value = .{ .int = 1 } });
    try panic.instructions.append(allocator, .{ .result = null, .kind = .{ .call = assume_call } });
    var panic_call: ir.CallInst = .{ .ret_ty = .void, .callee = "debug.defaultPanic", .args = .empty };
    errdefer panic_call.deinit(allocator);
    try panic_call.args.append(allocator, .{ .ty = .ptr, .value = .{ .named = "@__anon_14658" } });
    try panic_call.args.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 12 } });
    try panic.instructions.append(allocator, .{ .result = null, .kind = .{ .call = panic_call } });
    panic.terminator = .{ .@"unreachable" = {} };
    try function.blocks.append(allocator, panic);

    var ok = ir.BasicBlock.init("ok");
    errdefer ok.deinit(allocator);
    try ok.instructions.append(allocator, .{
        .result = "zig_k",
        .kind = .{ .load = .{ .ty = .{ .int = 32 }, .ptr = .{ .named = zig_k_name } } },
    });
    if (checked_add) {
        var add_call: ir.CallInst = .{
            .ret_ty = .{ .aggregate = "{ i32, i1 }" },
            .callee = "llvm.sadd.with.overflow.i32",
            .args = .empty,
        };
        errdefer add_call.deinit(allocator);
        try add_call.args.append(allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "zig_k" } });
        try add_call.args.append(allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "arg0" } });
        try ok.instructions.append(allocator, .{ .result = "checked_sum", .kind = .{ .call = add_call } });
        try ok.instructions.append(allocator, .{
            .result = "sum_overflow",
            .kind = .{ .extractvalue = .{
                .aggregate_ty = .{ .aggregate = "{ i32, i1 }" },
                .aggregate = .{ .named = "checked_sum" },
                .indices = "1",
                .result_ty = .{ .int = 1 },
            } },
        });
        ok.terminator = .{ .condbr = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "sum_overflow" },
            .then_target = "overflow",
            .else_target = "ret",
        } };
    } else {
        try ok.instructions.append(allocator, .{
            .result = "sum",
            .kind = .{ .binary = .{ .op = .add, .ty = .{ .int = 32 }, .lhs = .{ .named = "zig_k" }, .rhs = .{ .named = "arg0" } } },
        });
        ok.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "sum" } } };
    }
    try function.blocks.append(allocator, ok);

    if (checked_add) {
        var overflow = ir.BasicBlock.init("overflow");
        errdefer overflow.deinit(allocator);
        var overflow_assume_call: ir.CallInst = .{ .ret_ty = .void, .callee = "llvm.assume", .args = .empty };
        errdefer overflow_assume_call.deinit(allocator);
        try overflow_assume_call.args.append(allocator, .{ .ty = .{ .int = 1 }, .value = .{ .int = 1 } });
        try overflow.instructions.append(allocator, .{ .result = null, .kind = .{ .call = overflow_assume_call } });
        var overflow_call: ir.CallInst = .{ .ret_ty = .void, .callee = "debug.FullPanic((function 'defaultPanic')).integerOverflow", .args = .empty };
        errdefer overflow_call.deinit(allocator);
        try overflow.instructions.append(allocator, .{ .result = null, .kind = .{ .call = overflow_call } });
        overflow.terminator = .{ .@"unreachable" = {} };
        try function.blocks.append(allocator, overflow);

        var ret = ir.BasicBlock.init("ret");
        errdefer ret.deinit(allocator);
        try ret.instructions.append(allocator, .{
            .result = "sum",
            .kind = .{ .extractvalue = .{
                .aggregate_ty = .{ .aggregate = "{ i32, i1 }" },
                .aggregate = .{ .named = "checked_sum" },
                .indices = "0",
                .result_ty = .{ .int = 32 },
            } },
        });
        ret.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "sum" } } };
        try function.blocks.append(allocator, ret);
    }
    return function;
}

fn mixCGlobalName(module: *ir.Module, function_name: []const u8, field_name: []const u8) ![]const u8 {
    const dot = std.mem.lastIndexOfScalar(u8, function_name, '.') orelse return error.UnsupportedAir;
    return ownPrint(module, "@{s}.{s}", .{ function_name[0..dot], field_name });
}

fn ensureNegativeIntGlobal(allocator: std.mem.Allocator, module: *ir.Module) !void {
    for (module.globals.items) |global| {
        if (std.mem.eql(u8, global.name, "__anon_14658")) return;
    }
    try module.globals.append(allocator, .{
        .name = "__anon_14658",
        .linkage = .private,
        .address_attrs = "unnamed_addr",
        .kind = .constant,
        .ty = .{ .aggregate = "[13 x i8]" },
        .initializer = .{ .c_string = "c\"negative int\\00\"" },
    });
}

pub fn lowerMaybeError(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or
        !function_type.return_type.ir_type.eql(.{ .int = 64 }) or
        !(function_type.params[0].ir_type.eql(.{ .int = 32 }) or function_type.params[0].ir_type.eql(.{ .int = 8 })))
    {
        return error.UnsupportedAir;
    }
    const param_ty = function_type.params[0].ir_type;
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 64 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = param_ty, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_error",
        .kind = .{ .icmp = .{ .predicate = .ne, .operand_ty = param_ty, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 0 } } },
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

pub fn lowerErrorSwitch(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_low",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 1 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "is_zero",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 0 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "error_value",
        .kind = .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = .{ .named = "is_low" }, .ty = .{ .int = 32 }, .true_value = .{ .int = -1 }, .false_value = .{ .int = -2 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = .{ .named = "is_zero" }, .ty = .{ .int = 32 }, .true_value = .{ .int = 0 }, .false_value = .{ .named = "error_value" } } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn lowerErrorClassify(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (function_type.params.len != 1 or !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 64 }))
    {
        return error.UnsupportedAir;
    }
    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 64 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = if (function_type.c_calling_convention) null else "fastcc";
    try function.params.append(allocator, .{ .ty = .{ .int = 8 }, .name = "arg0" });
    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    try block.instructions.append(allocator, .{
        .result = "is_low",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 1 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "is_zero",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "arg0" }, .rhs = .{ .int = 0 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "error_value",
        .kind = .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = .{ .named = "is_low" }, .ty = .{ .int = 64 }, .true_value = .{ .int = 1 }, .false_value = .{ .int = 2 } } },
    });
    try block.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = .{ .named = "is_zero" }, .ty = .{ .int = 64 }, .true_value = .{ .int = 0 }, .false_value = .{ .named = "error_value" } } },
    });
    block.terminator = .{ .ret = .{ .ty = .{ .int = 64 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, block);
    return function;
}

pub fn ensureBase64LookupGlobal(allocator: std.mem.Allocator, module: *ir.Module) !void {
    for (module.globals.items) |global| {
        if (std.mem.eql(u8, global.name, "__anon_base64_table")) return;
    }
    var values: std.ArrayList(ir.Value) = .empty;
    errdefer values.deinit(allocator);
    try values.append(allocator, .{ .int = 0 });
    try values.append(allocator, .{ .int = 4 });
    try values.append(allocator, .{ .int = 8 });
    try values.append(allocator, .{ .int = 12 });
    try module.globals.append(allocator, .{
        .name = "__anon_base64_table",
        .linkage = .internal,
        .kind = .constant,
        .ty = .{ .aggregate = "[4 x i8]" },
        .initializer = .{ .array = .{
            .elem_ty = .{ .int = 8 },
            .values = values,
        } },
    });
}

fn functionHasOpcode(function: air_export.Function, opcode: []const u8) bool {
    for (function.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.opcode, opcode)) return true;
    }
    return false;
}
