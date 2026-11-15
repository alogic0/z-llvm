//! Keep an odd word of a bounded double pair behind the existing table home.
//! Prove the even base independently, then use its already admitted +8 field.
//! No wider table-index or pointer-offset envelope is introduced.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const tables = @import("../constant_table.zig");
const proof = @import("../constant_table_index.zig");
const forms = @import("scalar_forms.zig");

fn definition(function: ir.Function, name: []const u8) ?ir.Instruction {
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (!inst.removed and inst.result != null and ir.identifiers.eql(inst.result.?, name)) return inst;
    };
    return null;
}
const Tail = struct { base: []const u8, ty: ir.Type };
fn oddTail(function: ir.Function, index: ir.Value) ?Tail {
    if (index != .named) return null;
    var inst = definition(function, index.named) orelse return null;
    var ty: ir.Type = .{ .int = 64 };
    if (inst.kind == .cast) {
        const cast = inst.kind.cast;
        if (cast.op != .zext or !cast.to_ty.eql(ty) or cast.from_ty != .int or
            cast.from_ty.int == 0 or cast.from_ty.int >= 64 or cast.value != .named) return null;
        ty = cast.from_ty;
        inst = definition(function, cast.value.named) orelse return null;
    }
    if (inst.kind != .binary or !inst.kind.binary.ty.eql(ty) or inst.kind.binary.op != .add) return null;
    const binary = inst.kind.binary;
    if (binary.lhs == .named and binary.rhs.eql(.{ .int = 1 })) return .{ .base = binary.lhs.named, .ty = ty };
    if (binary.rhs == .named and binary.lhs.eql(.{ .int = 1 })) return .{ .base = binary.rhs.named, .ty = ty };
    return null;
}

pub fn legalize(a: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    const ctx = context orelse return null;
    var names: forms.TemporaryNames = .{ .prefix = "__zllvm_table_tail_" };
    defer names.deinit(a);
    var result = function;
    result.blocks = .empty;
    var changed = false;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            rewrite: {
                if (inst.removed or inst.result == null or inst.kind != .gep) break :rewrite;
                const gep = inst.kind.gep;
                if (gep.ptr_addrspace != null or gep.ptr != .named or !std.mem.startsWith(u8, gep.ptr.named, "@") or
                    gep.indices.items.len != 1 or !gep.indices.items[0].ty.eql(.{ .int = 64 })) break :rewrite;
                const tail = oddTail(function, gep.indices.items[0].value) orelse break :rewrite;
                var decoded = (tables.decodeSymbol(a, ctx.*, gep.ptr.named) catch |err| {
                    if (err == error.OutOfMemory) return err;
                    break :rewrite;
                }) orelse break :rewrite;
                defer decoded.deinit(a);
                if (decoded.shape != .f64_512_pairs or !tables.sourceStrideMatches(gep.source_ty, decoded.shape) or
                    !try proof.proves(a, context, function, tail.base, 510)) break :rewrite;
                // An even in-range base cannot wrap when one is added, at
                // either admitted integer width. Zero extension is exact.
                var index: ir.Value = .{ .named = tail.base };
                if (!tail.ty.eql(.{ .int = 64 })) {
                    const wide = try forms.temporary(a, function, &names);
                    try block.instructions.append(a, .{ .result = wide, .kind = .{ .cast = .{ .op = .zext, .from_ty = tail.ty, .value = index, .to_ty = .{ .int = 64 } } } });
                    index = .{ .named = wide };
                }
                const base = try forms.temporary(a, function, &names);
                var base_gep = inst;
                base_gep.result = base;
                base_gep.metadata = null;
                base_gep.kind.gep.indices = .empty;
                try base_gep.kind.gep.indices.append(a, .{ .ty = .{ .int = 64 }, .value = index });
                try block.instructions.append(a, base_gep);
                var field = inst;
                field.kind.gep.source_ty = .{ .int = 8 };
                field.kind.gep.ptr = .{ .named = base };
                field.kind.gep.indices = .empty;
                try field.kind.gep.indices.append(a, .{ .ty = .{ .int = 64 }, .value = .{ .int = 8 } });
                try block.instructions.append(a, field);
                changed = true;
                continue;
            }
            try block.instructions.append(a, inst);
        }
        try result.blocks.append(a, block);
    }
    return if (changed) result else null;
}

test "readonly table offsets require a proven even base within the original paired envelope" {
    const elements: [512][]const u8 = @splat("double 1.000000e+00");
    const initializer = try std.mem.join(std.testing.allocator, ",", &elements);
    defer std.testing.allocator.free(initializer);
    for ([_]struct { base: []const u8, accepted: bool }{
        .{ .base = "shl i64 %masked,1", .accepted = true },
        .{ .base = "or i64 %masked,1", .accepted = false },
        .{ .base = "shl i64 %input,1", .accepted = false },
    }) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128\"\n@table = private constant [512 x double] [{s}], align 8\ndefine double @read(i64 %input) {{\nentry:\n %masked = and i64 %input,255\n %base = {s}\n %odd = add i64 %base,1\n %p = getelementptr [8 x i8],ptr @table,i64 %odd\n %value = load double,ptr %p\n ret double %value\n}}\n", .{ initializer, case.base });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const rewritten = try legalize(arena.allocator(), module.functions.items[0], &context);
        try std.testing.expectEqual(case.accepted, rewritten != null);
        try std.testing.expectEqual(@as(usize, 5), module.functions.items[0].blocks.items[0].instructions.items.len);
        if (rewritten) |candidate| try std.testing.expect((try legalize(arena.allocator(), candidate, &context)) == null);
    }
}
