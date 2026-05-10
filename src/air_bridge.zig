const std = @import("std");
const ir = @import("ir.zig");

pub const Param = struct {
    name: []const u8,
    ty: ir.Type,
};

pub const Binary = struct {
    result: []const u8,
    op: ir.BinaryOp,
    ty: ir.Type,
    lhs: ir.Value,
    rhs: ir.Value,
};

pub const Cast = struct {
    result: []const u8,
    op: ir.CastOp,
    from_ty: ir.Type,
    value: ir.Value,
    to_ty: ir.Type,
};

pub const Function = struct {
    name: []const u8,
    ret_ty: ir.Type,
    params: []const Param,
    binaries: []const Binary,
    casts: []const Cast = &.{},
    ret: ?ir.Value = null,
};

pub const Module = struct {
    source_filename: ?[]const u8 = null,
    target_triple: ?[]const u8 = null,
    target_datalayout: ?[]const u8 = null,
    functions: []const Function,
};

pub fn lowerModule(allocator: std.mem.Allocator, spec: Module) !ir.Module {
    var module: ir.Module = .{
        .allocator = allocator,
        .source = try allocator.dupe(u8, ""),
        .owned_strings = .empty,
        .source_filename = spec.source_filename,
        .target_triple = spec.target_triple,
        .target_datalayout = spec.target_datalayout,
        .globals = .empty,
        .functions = .empty,
    };
    errdefer module.deinit();

    for (spec.functions) |function_spec| {
        try module.functions.append(allocator, try lowerFunction(allocator, function_spec));
    }

    return module;
}

fn lowerFunction(allocator: std.mem.Allocator, spec: Function) !ir.Function {
    var function = ir.Function.init(spec.name, spec.ret_ty);
    errdefer function.deinit(allocator);

    for (spec.params) |param| {
        try function.params.append(allocator, .{
            .name = param.name,
            .ty = param.ty,
        });
    }

    var entry = ir.BasicBlock.init("entry");
    errdefer entry.deinit(allocator);

    for (spec.binaries) |binary| {
        try entry.instructions.append(allocator, .{
            .result = binary.result,
            .kind = .{ .binary = .{
                .op = binary.op,
                .ty = binary.ty,
                .lhs = binary.lhs,
                .rhs = binary.rhs,
            } },
        });
    }
    for (spec.casts) |cast| {
        try entry.instructions.append(allocator, .{
            .result = cast.result,
            .kind = .{ .cast = .{
                .op = cast.op,
                .from_ty = cast.from_ty,
                .value = cast.value,
                .to_ty = cast.to_ty,
            } },
        });
    }

    entry.terminator = .{ .ret = .{
        .ty = spec.ret_ty,
        .value = spec.ret,
    } };
    try function.blocks.append(allocator, entry);

    return function;
}
