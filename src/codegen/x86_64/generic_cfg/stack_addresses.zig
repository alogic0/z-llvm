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

fn boundedMemoryUses(function: ir.Function, name: []const u8, bytes: u32) bool {
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed or inst.kind != .call) continue;
        const call = inst.kind.call;
        const memory = std.mem.startsWith(u8, call.callee, "llvm.memcpy.") or
            std.mem.startsWith(u8, call.callee, "llvm.memmove.") or
            std.mem.startsWith(u8, call.callee, "llvm.memset.");
        if (!memory) continue;
        for (call.args.items) |arg| if (arg.ty == .ptr and named(arg.value, name)) {
            if (call.args.items.len != 4) return false;
            const length = call.args.items[2].value;
            if (length != .int or length.int < 0 or length.int > bytes) return false;
        };
    };
    return true;
}

fn scalarUse(function: ir.Function, name: []const u8, bytes: u32) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |inst| {
            if (inst.removed) continue;
            switch (inst.kind) {
                .phi => |phi| if (phi.ty == .ptr) {
                    for (phi.incoming.items) |incoming| if (named(incoming.value, name)) return true;
                },
                .select => |select| if (select.ty == .ptr and (named(select.true_value, name) or named(select.false_value, name))) return true,
                .store => |store| {
                    if (store.ty == .ptr and named(store.value, name)) return true;
                    const width: u32 = if (store.ty == .ptr) 64 else if (store.ty == .int) store.ty.int else 0;
                    if (named(store.ptr, name) and width > 0 and width <= 64 and (width + 7) / 8 <= bytes) return true;
                },
                .load => |load| {
                    const width: u32 = if (load.ty == .ptr) 64 else if (load.ty == .int) load.ty.int else 0;
                    if (named(load.ptr, name) and width > 0 and width <= 64 and (width + 7) / 8 <= bytes) return true;
                },
                .call => |call| if (call.inline_asm == null and call.raw_args == null) {
                    const memory = std.mem.startsWith(u8, call.callee, "llvm.memcpy.") or
                        std.mem.startsWith(u8, call.callee, "llvm.memmove.") or
                        std.mem.startsWith(u8, call.callee, "llvm.memset.");
                    for (call.args.items, 0..) |arg, index| {
                        if (arg.ty != .ptr or !named(arg.value, name)) continue;
                        if (memory) {
                            if (index > 1 or call.args.items.len != 4) continue;
                            const length = call.args.items[2].value;
                            if (length != .int or length.int < 0 or length.int > bytes) continue;
                        }
                        return true;
                    }
                },
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
        const layout = storage.query(context, alloca.allocated_ty) orelse continue;
        if (!scalarUse(function, inst.result.?, layout.bytes)) continue;
        if (!boundedMemoryUses(function, inst.result.?, layout.bytes)) return null;
        if (!alloca.isSingleObject() or alloca.allocated_ty_addrspace != null) return null;
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
