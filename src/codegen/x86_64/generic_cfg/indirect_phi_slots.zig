//! Private memory transport for PHIs reached by indirect branches. Original
//! block addresses/terminators stay intact. Distinct slots and frozen incoming
//! SSA values permit eager stores to every possible target without copy cycles.
const std = @import("std");
const ir = @import("../../../ir.zig");
const cfg = @import("../../../analysis/cfg.zig");
const forms = @import("scalar_forms.zig");
const SlotMap = std.HashMap([]const u8, usize, ir.identifiers.Context, std.hash_map.default_max_load_percentage);
const Slot = struct {
    source_ty: ir.Type,
    payload_ty: ir.Type,
    storage: []const u8,
    address: []const u8,
};
const Write = struct { slot: usize, value: ir.Value };

fn payloadType(ty: ir.Type) ?ir.Type {
    return switch (ty) {
        .int => |bits| if (bits == 0 or bits > 128) null else .{ .int = if (bits <= 32) 32 else if (bits <= 64) 64 else 128 },
        .ptr => .ptr,
        .half, .float => .{ .int = 32 },
        .double => .{ .int = 64 },
        else => null,
    };
}
fn fpBits(ty: ir.Type) ?u16 {
    return switch (ty) {
        .half => 16,
        .float => 32,
        .double => 64,
        else => null,
    };
}
fn hasPhi(block: ir.BasicBlock) bool {
    for (block.instructions.items) |inst| if (!inst.removed and inst.kind == .phi) return true;
    return false;
}
const Builder = struct {
    allocator: std.mem.Allocator,
    function: ir.Function,
    block: *ir.BasicBlock,
    serial: *forms.TemporaryNames,

    fn emit(b: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const name = try forms.temporary(b.allocator, b.function, b.serial);
        try b.block.instructions.append(b.allocator, .{ .result = name, .kind = kind });
        return .{ .named = name };
    }
    fn cast(b: Builder, op: ir.CastOp, from: ir.Type, value: ir.Value, to: ir.Type) !ir.Value {
        return b.emit(.{ .cast = .{ .op = op, .from_ty = from, .value = value, .to_ty = to } });
    }
    fn storeValue(b: Builder, slot: Slot, original: ir.Value) !ir.Value {
        if (original == .undef or original == .poison or original == .zero_initializer)
            return if (slot.payload_ty == .ptr) .null_value else .{ .int = 0 };
        var value = original;
        if (fpBits(slot.source_ty)) |bits| {
            const integer: ir.Type = .{ .int = bits };
            value = try b.cast(.bitcast, slot.source_ty, value, integer);
            if (!integer.eql(slot.payload_ty)) value = try b.cast(.zext, integer, value, slot.payload_ty);
        } else if (!slot.source_ty.eql(slot.payload_ty)) {
            value = try b.cast(.zext, slot.source_ty, value, slot.payload_ty);
        } else if (slot.source_ty == .ptr and value != .null_value) {
            // Materialize global/constant-expression and frame pointer values
            // as an ordinary named pointer before the existing freeze alias.
            var indices: std.ArrayList(ir.GepIndex) = .empty;
            try indices.append(b.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
            value = try b.emit(.{ .gep = .{ .source_ty = .{ .int = 8 }, .ptr = value, .indices = indices } });
        }
        if (value == .named or value == .constant_expr)
            value = try b.emit(.{ .freeze = .{ .ty = slot.payload_ty, .value = value } });
        return value;
    }
    fn load(b: Builder, name: []const u8, slot: Slot) !void {
        const memory: ir.LoadInst = .{ .ty = slot.payload_ty, .ptr = .{ .named = slot.address }, .attrs = .{ .@"align" = 16 } };
        if (slot.source_ty.eql(slot.payload_ty)) {
            try b.block.instructions.append(b.allocator, .{ .result = name, .kind = .{ .load = memory } });
            return;
        }
        var value = try b.emit(.{ .load = memory });
        if (fpBits(slot.source_ty)) |bits| {
            const integer: ir.Type = .{ .int = bits };
            if (!slot.payload_ty.eql(integer)) value = try b.cast(.trunc, slot.payload_ty, value, integer);
            try b.block.instructions.append(b.allocator, .{ .result = name, .kind = .{ .cast = .{
                .op = .bitcast,
                .from_ty = integer,
                .value = value,
                .to_ty = slot.source_ty,
            } } });
        } else {
            try b.block.instructions.append(b.allocator, .{ .result = name, .kind = .{ .cast = .{
                .op = .trunc,
                .from_ty = slot.payload_ty,
                .value = value,
                .to_ty = slot.source_ty,
            } } });
        }
    }
};

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var indirect = false;
    var any_phi = false;
    for (function.blocks.items) |block| {
        any_phi = any_phi or hasPhi(block);
        if (block.terminator) |term| indirect = indirect or term == .indirectbr;
    }
    if (!indirect or !any_phi or function.blocks.items.len == 0) return null;
    var graph = cfg.Graph.build(allocator, function) catch |err| {
        if (err == error.UnknownBlock or err == error.DuplicateBlock) return null;
        return err;
    };
    defer graph.deinit();
    const targets = try allocator.alloc(bool, function.blocks.items.len);
    defer allocator.free(targets);
    @memset(targets, false);
    var count: usize = 0;
    for (function.blocks.items, 0..) |block, index| if (block.terminator) |term| {
        if (term != .indirectbr) continue;
        for (graph.successors(index)) |target| if (!targets[target] and hasPhi(function.blocks.items[target])) {
            targets[target] = true;
            count += 1;
        };
    };
    if (count == 0 or targets[0]) return null;
    for (function.blocks.items, targets) |block, target| if (target) {
        for (block.instructions.items) |inst| {
            if (inst.removed or inst.kind != .phi) continue;
            _ = payloadType(inst.kind.phi.ty) orelse return null;
            if (inst.result == null) return null;
        }
    };

    var serial: forms.TemporaryNames = .{ .prefix = "__zllvm_indirect_phi_" };
    defer serial.deinit(allocator);
    var slots: std.ArrayList(Slot) = .empty;
    defer slots.deinit(allocator);
    var slot_names = SlotMap.init(allocator);
    defer slot_names.deinit();
    const writes = try allocator.alloc(std.ArrayList(Write), function.blocks.items.len);
    @memset(writes, .empty);
    defer {
        for (writes) |*list| list.deinit(allocator);
        allocator.free(writes);
    }
    for (function.blocks.items, targets, 0..) |block, target, target_index| if (target) {
        for (block.instructions.items) |inst| {
            if (inst.removed or inst.kind != .phi) continue;
            const phi = inst.kind.phi;
            const entry = try slot_names.getOrPut(inst.result.?);
            if (entry.found_existing) return null;
            const slot_index = slots.items.len;
            entry.value_ptr.* = slot_index;
            try slots.append(allocator, .{
                .source_ty = phi.ty,
                .payload_ty = payloadType(phi.ty).?,
                .storage = try forms.temporary(allocator, function, &serial),
                .address = try forms.temporary(allocator, function, &serial),
            });
            var predecessors = std.AutoHashMap(usize, ir.Value).init(allocator);
            defer predecessors.deinit();
            for (phi.incoming.items) |incoming| {
                const predecessor = graph.blockIndex(incoming.block) orelse return null;
                if (graph.edgeCount(predecessor, target_index) == 0) return null;
                const seen = try predecessors.getOrPut(predecessor);
                if (seen.found_existing) {
                    if (!seen.value_ptr.eql(incoming.value)) return null;
                    continue;
                }
                seen.value_ptr.* = incoming.value;
                try writes[predecessor].append(allocator, .{ .slot = slot_index, .value = incoming.value });
            }
            if (predecessors.count() != graph.predecessors(target_index).len) return null;
        }
    };
    var result = function;
    result.blocks = .empty;
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        const b: Builder = .{ .allocator = allocator, .function = function, .block = &block, .serial = &serial };
        if (block_index == 0) for (slots.items) |slot| {
            const bytes: u16 = if (slot.payload_ty == .ptr) 8 else slot.payload_ty.int / 8;
            const words = (bytes + 3) / 4;
            try block.instructions.append(allocator, .{ .result = slot.storage, .kind = .{ .alloca = .{
                .allocated_ty = .{ .aggregate = try std.fmt.allocPrint(allocator, "[{d} x i32]", .{words}) },
                .attrs = "align 16",
            } } });
            var indices: std.ArrayList(ir.GepIndex) = .empty;
            try indices.append(allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
            try block.instructions.append(allocator, .{ .result = slot.address, .kind = .{ .gep = .{
                .source_ty = .{ .int = 8 },
                .ptr = .{ .named = slot.storage },
                .indices = indices,
            } } });
        };
        for (original.instructions.items) |inst| {
            if (!inst.removed and inst.kind == .phi and targets[block_index]) {
                try b.load(inst.result.?, slots.items[slot_names.get(inst.result.?).?]);
            } else try block.instructions.append(allocator, inst);
        }
        for (writes[block_index].items) |write| {
            const slot = slots.items[write.slot];
            try block.instructions.append(allocator, .{ .result = null, .kind = .{ .store = .{
                .ty = slot.payload_ty,
                .value = try b.storeValue(slot, write.value),
                .ptr = .{ .named = slot.address },
                .attrs = .{ .@"align" = 16 },
            } } });
        }
        try result.blocks.append(allocator, block);
    }
    return result;
}
