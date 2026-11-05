//! Materialize bounded frame addresses used as scalar SSA values. The private
//! allocation retains storage ownership; the original name becomes a pointer.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const storage = @import("storage_layout.zig");
const helpers = @import("composed_helpers.zig");
const forms = @import("scalar_forms.zig");

fn named(value: ir.Value, name: []const u8) bool {
    return value == .named and ir.identifiers.eql(value.named, name);
}

fn scalarUse(function: ir.Function, name: []const u8) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |inst| {
            if (inst.removed) continue;
            switch (inst.kind) {
                .phi => |phi| if (phi.ty == .ptr) {
                    for (phi.incoming.items) |incoming| if (named(incoming.value, name)) return true;
                },
                .select => |select| if (select.ty == .ptr and (named(select.true_value, name) or named(select.false_value, name))) return true,
                .store => |store| if (store.ty == .ptr and named(store.value, name)) return true,
                .cast => |cast| if (cast.from_ty == .ptr and named(cast.value, name)) return true,
                .icmp => |icmp| if (icmp.operand_ty == .ptr and (named(icmp.lhs, name) or named(icmp.rhs, name))) return true,
                .gep => |gep| if (named(gep.ptr, name)) {
                    for (gep.indices.items) |index| if (index.value == .named) return true;
                },
                else => {},
            }
        }
        if (block.terminator) |term| if (term == .ret and term.ret.ty == .ptr and term.ret.value != null and named(term.ret.value.?, name)) return true;
    }
    return false;
}

const Slot = struct { backing: []const u8, bytes: u32, alignment: u32 };

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    var slots = std.StringHashMap(Slot).init(allocator);
    var serial: usize = 0;
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed or inst.result == null or inst.kind != .alloca) continue;
        const alloca = inst.kind.alloca;
        // Aggregate allocation admission belongs to padded_frame. Only its
        // concrete array carrier and native scalar objects enter this view.
        if (alloca.allocated_ty == .aggregate and helpers.parseI32ArrayType(alloca.allocated_ty) == null) continue;
        if (!scalarUse(function, inst.result.?)) continue;
        if (!alloca.isSingleObject() or alloca.allocated_ty_addrspace != null) return null;
        const layout = storage.query(context, alloca.allocated_ty) orelse return null;
        var alignment = layout.alignment;
        if (alloca.attrs) |attrs| {
            const text = std.mem.trim(u8, attrs, " \t\r\n");
            if (!std.mem.startsWith(u8, text, "align ")) return null;
            const explicit = std.fmt.parseUnsigned(u32, std.mem.trim(u8, text[6..], " \t"), 10) catch return null;
            if (explicit == 0 or explicit > 16 or !std.math.isPowerOfTwo(explicit)) return null;
            alignment = @max(alignment, explicit);
        }
        try slots.put(inst.result.?, .{ .backing = try forms.temporary(allocator, function, &serial), .bytes = layout.bytes, .alignment = @max(4, alignment) });
    };
    if (slots.count() == 0) return null;
    var result = function;
    result.blocks = .empty;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            if (!inst.removed and inst.kind == .alloca and inst.result != null) if (slots.get(inst.result.?)) |slot| {
                var copy = inst;
                copy.result = slot.backing;
                copy.kind.alloca.allocated_ty = .{ .aggregate = try std.fmt.allocPrint(allocator, "[{d} x i32]", .{std.mem.alignForward(u32, @max(1, slot.bytes), 4) / 4}) };
                copy.kind.alloca.attrs = try std.fmt.allocPrint(allocator, "align {d}", .{slot.alignment});
                try block.instructions.append(allocator, copy);
                var indices: std.ArrayList(ir.GepIndex) = .empty;
                try indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
                try block.instructions.append(allocator, .{ .result = inst.result, .kind = .{ .gep = .{
                    .source_ty = .{ .int = 8 },
                    .ptr = .{ .named = slot.backing },
                    .indices = indices,
                } } });
                continue;
            };
            try block.instructions.append(allocator, inst);
        }
        try result.blocks.append(allocator, block);
    }
    return result;
}
