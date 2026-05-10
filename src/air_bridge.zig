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

pub const Alloca = struct {
    result: []const u8,
    allocated_ty: ir.Type,
};

pub const Load = struct {
    result: []const u8,
    ty: ir.Type,
    ptr: ir.Value,
    attrs: ir.MemoryAttrs = .{},
};

pub const Store = struct {
    ty: ir.Type,
    value: ir.Value,
    ptr: ir.Value,
    attrs: ir.MemoryAttrs = .{},
};

pub const Gep = struct {
    result: []const u8,
    source_ty: ir.Type,
    ptr: ir.Value,
    indices: []const ir.GepIndex,
};

pub const Terminator = union(enum) {
    ret: struct {
        ty: ir.Type,
        value: ?ir.Value = null,
    },
    br: struct {
        target: []const u8,
    },
    condbr: struct {
        cond_ty: ir.Type,
        cond: ir.Value,
        then_target: []const u8,
        else_target: []const u8,
    },
    @"unreachable",
};

pub const Block = struct {
    name: []const u8,
    allocas: []const Alloca = &.{},
    binaries: []const Binary = &.{},
    casts: []const Cast = &.{},
    loads: []const Load = &.{},
    stores: []const Store = &.{},
    geps: []const Gep = &.{},
    terminator: Terminator,
};

pub const Function = struct {
    name: []const u8,
    ret_ty: ir.Type,
    params: []const Param,
    allocas: []const Alloca = &.{},
    binaries: []const Binary = &.{},
    casts: []const Cast = &.{},
    loads: []const Load = &.{},
    stores: []const Store = &.{},
    geps: []const Gep = &.{},
    blocks: []const Block = &.{},
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

    if (spec.blocks.len != 0) {
        for (spec.blocks) |block| {
            try function.blocks.append(allocator, try lowerBlock(allocator, block));
        }
        return function;
    }

    const entry_spec: Block = .{
        .name = "entry",
        .allocas = spec.allocas,
        .binaries = spec.binaries,
        .casts = spec.casts,
        .loads = spec.loads,
        .stores = spec.stores,
        .geps = spec.geps,
        .terminator = .{ .ret = .{
            .ty = spec.ret_ty,
            .value = spec.ret,
        } },
    };
    try function.blocks.append(allocator, try lowerBlock(allocator, entry_spec));

    return function;
}

fn lowerBlock(allocator: std.mem.Allocator, spec: Block) !ir.BasicBlock {
    var block = ir.BasicBlock.init(spec.name);
    errdefer block.deinit(allocator);

    for (spec.allocas) |alloca| {
        try block.instructions.append(allocator, .{
            .result = alloca.result,
            .kind = .{ .alloca = .{ .allocated_ty = alloca.allocated_ty } },
        });
    }
    for (spec.binaries) |binary| {
        try block.instructions.append(allocator, .{
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
        try block.instructions.append(allocator, .{
            .result = cast.result,
            .kind = .{ .cast = .{
                .op = cast.op,
                .from_ty = cast.from_ty,
                .value = cast.value,
                .to_ty = cast.to_ty,
            } },
        });
    }
    for (spec.geps) |gep| {
        var lowered_gep: ir.GepInst = .{
            .source_ty = gep.source_ty,
            .ptr = gep.ptr,
            .indices = .empty,
        };
        errdefer lowered_gep.deinit(allocator);
        for (gep.indices) |index| try lowered_gep.indices.append(allocator, index);
        try block.instructions.append(allocator, .{
            .result = gep.result,
            .kind = .{ .gep = lowered_gep },
        });
    }
    for (spec.stores) |store| {
        try block.instructions.append(allocator, .{
            .result = null,
            .kind = .{ .store = .{
                .ty = store.ty,
                .value = store.value,
                .ptr = store.ptr,
                .attrs = store.attrs,
            } },
        });
    }
    for (spec.loads) |load| {
        try block.instructions.append(allocator, .{
            .result = load.result,
            .kind = .{ .load = .{
                .ty = load.ty,
                .ptr = load.ptr,
                .attrs = load.attrs,
            } },
        });
    }

    block.terminator = switch (spec.terminator) {
        .ret => |ret| .{ .ret = .{
            .ty = ret.ty,
            .value = ret.value,
        } },
        .br => |br| .{ .br = .{ .target = br.target } },
        .condbr => |condbr| .{ .condbr = .{
            .cond_ty = condbr.cond_ty,
            .cond = condbr.cond,
            .then_target = condbr.then_target,
            .else_target = condbr.else_target,
        } },
        .@"unreachable" => .{ .@"unreachable" = {} },
    };

    return block;
}
