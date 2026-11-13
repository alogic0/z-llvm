//! Exact byte snapshots bridge native-lane vectors and bounded limb integers.
//! The bitcast happens at its original SSA position; subsequent stores/calls
//! cannot change the captured bits. No ABI, Source or value-use expansion.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const forms = @import("scalar_forms.zig");
const raw = @import("../../../ir/wide_integers.zig");
fn vectorBits(ty: ir.Type) ?u32 {
    if (ty != .vector or ty.vector.len == 0 or ty.vector.len > 64 or ty.vector.elem_ty != .int) return null;
    const bits = ty.vector.elem_ty.int;
    if (bits != 8 and bits != 16 and bits != 32 and bits != 64 and bits != 128) return null;
    const total = @as(u32, bits) * ty.vector.len;
    return if (total > 128 and total <= 512 and total % 8 == 0) total else null;
}
pub fn legalize(a: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    if (!@import("../symbol_address.zig").supportsLayout(if (context) |ctx| ctx.target_datalayout else null)) return null;
    var names: forms.TemporaryNames = .{ .prefix = "__zllvm_bitcast_memory_" };
    defer names.deinit(a);
    var prefixes: std.ArrayList(ir.Instruction) = .empty;
    defer prefixes.deinit(a);
    var result = function;
    result.blocks = .empty;
    var changed = false;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            if (!inst.removed and inst.result != null and inst.kind == .cast and inst.kind.cast.op == .bitcast and !inst.kind.cast.flags.any()) {
                const cast = inst.kind.cast;
                const bits = if (vectorBits(cast.from_ty)) |n| (if ((raw.width(cast.to_ty) orelse 0) == n) n else 0) else if (vectorBits(cast.to_ty)) |n| (if ((raw.width(cast.from_ty) orelse 0) == n) n else 0) else 0;
                if (bits != 0) {
                    const buffer = try forms.temporary(a, function, &names);
                    try prefixes.append(a, .{ .result = buffer, .kind = .{ .alloca = .{ .allocated_ty = .{ .aggregate = try std.fmt.allocPrint(a, "[{d} x i32]", .{bits / 32}) }, .attrs = "align 16" } } });
                    try block.instructions.append(a, .{ .result = null, .kind = .{ .store = .{ .ty = cast.from_ty, .value = cast.value, .ptr = .{ .named = buffer }, .attrs = .{ .@"align" = 1 } } } });
                    var load = inst;
                    load.kind = .{ .load = .{ .ty = cast.to_ty, .ptr = .{ .named = buffer }, .attrs = .{ .@"align" = 1 } } };
                    try block.instructions.append(a, load);
                    changed = true;
                    continue;
                }
            }
            try block.instructions.append(a, inst);
        }
        try result.blocks.append(a, block);
    }
    if (!changed) return null;
    var entry = result.blocks.items[0];
    var instructions: std.ArrayList(ir.Instruction) = .empty;
    var leading: usize = 0;
    while (leading < entry.instructions.items.len and entry.instructions.items[leading].kind == .phi) : (leading += 1) {}
    try instructions.appendSlice(a, entry.instructions.items[0..leading]);
    try instructions.appendSlice(a, prefixes.items);
    try instructions.appendSlice(a, entry.instructions.items[leading..]);
    entry.instructions = instructions;
    result.blocks.items[0] = entry;
    return result;
}
