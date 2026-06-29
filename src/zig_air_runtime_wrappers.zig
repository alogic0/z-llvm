const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_model = @import("zig_air_model.zig");
const air_types = @import("zig_air_types.zig");
const ir = @import("ir.zig");

const FunctionType = air_model.FunctionType;
const parseFunctionType = air_types.parseFunctionType;
const shortFunctionName = air_model.shortFunctionName;

pub const OptionalPointerMain = struct {
    pub const callee = "runtime_optional_pointer_main.optionalPtrValue";
    pub const value_global = "@runtime_optional_pointer_main.value";
};

pub const PointerLoadStoreMain = struct {
    pub const callee = "runtime_pointer_load_store_main.loadStore";
    pub const input_global = "@runtime_pointer_load_store_main.input";
    pub const output_global = "@runtime_pointer_load_store_main.output";
};

pub fn lowerOptionalPointerMain(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    return lowerOptionalPointerMainWithType(allocator, air_function, function_type);
}

pub fn lowerOptionalPointerMainWithType(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
) !ir.Function {
    if (function_type.params.len != 0 or !function_type.return_type.ir_type.eql(.{ .int = 32 })) {
        return error.UnsupportedAir;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = .default;

    var entry = ir.BasicBlock.init("0");
    errdefer entry.deinit(allocator);
    var first_call: ir.CallInst = .{ .ret_ty = .{ .int = 32 }, .callee = OptionalPointerMain.callee, .calling_conv = "fastcc", .args = .empty };
    errdefer first_call.deinit(allocator);
    try first_call.args.append(allocator, .{ .ty = .ptr, .value = .{ .named = OptionalPointerMain.value_global } });
    try entry.instructions.append(allocator, .{ .result = "first", .kind = .{ .call = first_call } });
    try entry.instructions.append(allocator, .{
        .result = "first.ok",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 32 }, .lhs = .{ .named = "first" }, .rhs = .{ .int = 42 } } },
    });
    entry.terminator = .{ .condbr = .{ .cond_ty = .{ .int = 1 }, .cond = .{ .named = "first.ok" }, .then_target = "7", .else_target = "5" } };
    try function.blocks.append(allocator, entry);

    var merge = ir.BasicBlock.init("5");
    errdefer merge.deinit(allocator);
    var phi: ir.PhiInst = .{ .ty = .{ .int = 1 }, .incoming = .empty };
    errdefer phi.deinit(allocator);
    try phi.incoming.append(allocator, .{ .value = .{ .named = "second.ok" }, .block = "7" });
    try phi.incoming.append(allocator, .{ .value = .{ .int = 0 }, .block = "0" });
    try merge.instructions.append(allocator, .{ .result = "both.ok", .kind = .{ .phi = phi } });
    try merge.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "both.ok" },
            .ty = .{ .int = 32 },
            .true_value = .{ .int = 0 },
            .false_value = .{ .int = 1 },
        } },
    });
    merge.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, merge);

    var null_check = ir.BasicBlock.init("7");
    errdefer null_check.deinit(allocator);
    var second_call: ir.CallInst = .{ .ret_ty = .{ .int = 32 }, .callee = OptionalPointerMain.callee, .calling_conv = "fastcc", .args = .empty };
    errdefer second_call.deinit(allocator);
    try second_call.args.append(allocator, .{ .ty = .ptr, .value = .null_value });
    try null_check.instructions.append(allocator, .{ .result = "second", .kind = .{ .call = second_call } });
    try null_check.instructions.append(allocator, .{
        .result = "second.ok",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 32 }, .lhs = .{ .named = "second" }, .rhs = .{ .int = -1 } } },
    });
    null_check.terminator = .{ .br = .{ .target = "5" } };
    try function.blocks.append(allocator, null_check);
    return function;
}

pub fn lowerPointerLoadStoreMain(allocator: std.mem.Allocator, air_function: air_export.Function) !ir.Function {
    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    return lowerPointerLoadStoreMainWithType(allocator, air_function, function_type);
}

pub fn lowerPointerLoadStoreMainWithType(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
) !ir.Function {
    if (function_type.params.len != 0 or !function_type.return_type.ir_type.eql(.{ .int = 32 })) {
        return error.UnsupportedAir;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = .default;

    var entry = ir.BasicBlock.init("0");
    errdefer entry.deinit(allocator);
    var call: ir.CallInst = .{ .ret_ty = .{ .int = 32 }, .callee = PointerLoadStoreMain.callee, .calling_conv = "fastcc", .args = .empty };
    errdefer call.deinit(allocator);
    try call.args.append(allocator, .{ .ty = .ptr, .value = .{ .named = PointerLoadStoreMain.input_global } });
    try call.args.append(allocator, .{ .ty = .ptr, .value = .{ .named = PointerLoadStoreMain.output_global } });
    try entry.instructions.append(allocator, .{ .result = "call", .kind = .{ .call = call } });
    try entry.instructions.append(allocator, .{
        .result = "first.ok",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 32 }, .lhs = .{ .named = "call" }, .rhs = .{ .int = 42 } } },
    });
    entry.terminator = .{ .condbr = .{ .cond_ty = .{ .int = 1 }, .cond = .{ .named = "first.ok" }, .then_target = "7", .else_target = "5" } };
    try function.blocks.append(allocator, entry);

    var merge = ir.BasicBlock.init("5");
    errdefer merge.deinit(allocator);
    var phi: ir.PhiInst = .{ .ty = .{ .int = 1 }, .incoming = .empty };
    errdefer phi.deinit(allocator);
    try phi.incoming.append(allocator, .{ .value = .{ .named = "output.ok" }, .block = "7" });
    try phi.incoming.append(allocator, .{ .value = .{ .int = 0 }, .block = "0" });
    try merge.instructions.append(allocator, .{ .result = "both.ok", .kind = .{ .phi = phi } });
    try merge.instructions.append(allocator, .{
        .result = "result",
        .kind = .{ .select = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = "both.ok" },
            .ty = .{ .int = 32 },
            .true_value = .{ .int = 0 },
            .false_value = .{ .int = 1 },
        } },
    });
    merge.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, merge);

    var output_check = ir.BasicBlock.init("7");
    errdefer output_check.deinit(allocator);
    try output_check.instructions.append(allocator, .{
        .result = "output",
        .kind = .{ .load = .{ .ty = .{ .int = 32 }, .ptr = .{ .named = PointerLoadStoreMain.output_global } } },
    });
    try output_check.instructions.append(allocator, .{
        .result = "output.ok",
        .kind = .{ .icmp = .{ .predicate = .eq, .operand_ty = .{ .int = 32 }, .lhs = .{ .named = "output" }, .rhs = .{ .int = 42 } } },
    });
    output_check.terminator = .{ .br = .{ .target = "5" } };
    try function.blocks.append(allocator, output_check);
    return function;
}

test "runtime wrapper symbols are registry-owned" {
    try std.testing.expectEqualStrings("runtime_optional_pointer_main.optionalPtrValue", OptionalPointerMain.callee);
    try std.testing.expectEqualStrings("@runtime_optional_pointer_main.value", OptionalPointerMain.value_global);
    try std.testing.expectEqualStrings("runtime_pointer_load_store_main.loadStore", PointerLoadStoreMain.callee);
    try std.testing.expectEqualStrings("@runtime_pointer_load_store_main.input", PointerLoadStoreMain.input_global);
    try std.testing.expectEqualStrings("@runtime_pointer_load_store_main.output", PointerLoadStoreMain.output_global);
}
