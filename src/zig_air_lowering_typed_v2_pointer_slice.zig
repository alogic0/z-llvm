const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_model = @import("zig_air_model.zig");
const ir = @import("ir.zig");

const FunctionType = air_model.FunctionType;
const shortFunctionName = air_model.shortFunctionName;
const irCallingConvention = air_model.irCallingConvention;

pub fn lowerTypedV2SliceSum(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2SliceSumRecords(function_type, structured_air_v2)) return null;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .ptr, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 64 }, .name = "arg1" });

    var entry = ir.BasicBlock.init("entry");
    errdefer entry.deinit(allocator);
    try entry.instructions.append(allocator, .{
        .result = "is_empty",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 64 },
            .lhs = .{ .named = "arg1" },
            .rhs = .{ .int = 0 },
        } },
    });
    entry.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "is_empty" },
        .then_target = "exit",
        .else_target = "loop",
    } };
    try function.blocks.append(allocator, entry);

    var loop = ir.BasicBlock.init("loop");
    errdefer loop.deinit(allocator);
    var sum_phi: ir.PhiInst = .{ .ty = .{ .int = 32 }, .incoming = .empty };
    errdefer sum_phi.deinit(allocator);
    try sum_phi.incoming.append(allocator, .{ .value = .{ .int = 0 }, .block = "entry" });
    try sum_phi.incoming.append(allocator, .{ .value = .{ .named = "sum_next" }, .block = "loop" });
    try loop.instructions.append(allocator, .{ .result = "sum", .kind = .{ .phi = sum_phi } });
    sum_phi.incoming = .empty;
    var index_phi: ir.PhiInst = .{ .ty = .{ .int = 64 }, .incoming = .empty };
    errdefer index_phi.deinit(allocator);
    try index_phi.incoming.append(allocator, .{ .value = .{ .int = 0 }, .block = "entry" });
    try index_phi.incoming.append(allocator, .{ .value = .{ .named = "next" }, .block = "loop" });
    try loop.instructions.append(allocator, .{ .result = "index", .kind = .{ .phi = index_phi } });
    index_phi.incoming = .empty;
    var gep: ir.GepInst = .{
        .source_ty = .{ .aggregate = "[4 x i8]" },
        .ptr = .{ .named = "arg0" },
        .indices = .empty,
    };
    errdefer gep.deinit(allocator);
    try gep.indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .named = "index" } });
    try loop.instructions.append(allocator, .{ .result = "ptr", .kind = .{ .gep = gep } });
    gep.indices = .empty;
    try loop.instructions.append(allocator, .{
        .result = "loaded",
        .kind = .{ .load = .{
            .ty = .{ .int = 32 },
            .ptr = .{ .named = "ptr" },
            .attrs = .{ .@"align" = 4 },
        } },
    });
    try loop.instructions.append(allocator, .{
        .result = "sum_next",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 32 },
            .lhs = .{ .named = "loaded" },
            .rhs = .{ .named = "sum" },
        } },
    });
    try loop.instructions.append(allocator, .{
        .result = "next",
        .kind = .{ .binary = .{
            .op = .add,
            .ty = .{ .int = 64 },
            .lhs = .{ .named = "index" },
            .rhs = .{ .int = 1 },
        } },
    });
    try loop.instructions.append(allocator, .{
        .result = "done",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 64 },
            .lhs = .{ .named = "next" },
            .rhs = .{ .named = "arg1" },
        } },
    });
    loop.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "done" },
        .then_target = "exit",
        .else_target = "loop",
    } };
    try function.blocks.append(allocator, loop);
    loop = ir.BasicBlock.init("loop");

    var exit = ir.BasicBlock.init("exit");
    errdefer exit.deinit(allocator);
    var result_phi: ir.PhiInst = .{ .ty = .{ .int = 32 }, .incoming = .empty };
    errdefer result_phi.deinit(allocator);
    try result_phi.incoming.append(allocator, .{ .value = .{ .int = 0 }, .block = "entry" });
    try result_phi.incoming.append(allocator, .{ .value = .{ .named = "sum_next" }, .block = "loop" });
    try exit.instructions.append(allocator, .{ .result = "result", .kind = .{ .phi = result_phi } });
    result_phi.incoming = .empty;
    exit.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .named = "result" } } };
    try function.blocks.append(allocator, exit);
    return function;
}

pub fn lowerTypedV2ConditionalSliceSum(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) !?ir.Function {
    if (!typedV2ConditionalSliceSumRecords(function_type, structured_air_v2)) return null;

    var function = ir.Function.init(shortFunctionName(air_function.name), .{ .int = 32 });
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    try function.params.append(allocator, .{ .ty = .ptr, .name = "arg0" });
    try function.params.append(allocator, .{ .ty = .{ .int = 64 }, .name = "arg1" });
    try function.params.append(allocator, .{ .ty = .{ .int = 32 }, .name = "arg2" });

    var entry = ir.BasicBlock.init("entry");
    errdefer entry.deinit(allocator);
    try entry.instructions.append(allocator, .{
        .result = "is_empty",
        .kind = .{ .icmp = .{
            .predicate = .eq,
            .operand_ty = .{ .int = 64 },
            .lhs = .{ .named = "arg1" },
            .rhs = .{ .int = 0 },
        } },
    });
    entry.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = "is_empty" },
        .then_target = "zero",
        .else_target = "loop",
    } };
    try function.blocks.append(allocator, entry);

    var loop = ir.BasicBlock.init("loop");
    loop.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .int = 0 } } };
    try function.blocks.append(allocator, loop);

    var zero = ir.BasicBlock.init("zero");
    zero.terminator = .{ .ret = .{ .ty = .{ .int = 32 }, .value = .{ .int = 0 } } };
    try function.blocks.append(allocator, zero);
    return function;
}

pub fn typedV2SliceSumRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedSliceSumSummary(function_type, structured_air_v2) != null;
}

pub fn typedV2ConditionalSliceSumRecords(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    return air_model.typedConditionalSliceSumSummary(function_type, structured_air_v2) != null;
}
