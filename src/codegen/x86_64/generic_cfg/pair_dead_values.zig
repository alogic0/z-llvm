//! Remove unused pure pair constructions from an owned private instruction
//! graph. Opaque references disable cleanup; source arrays must be cloned first.
const std = @import("std");
const ir = @import("../../../ir.zig");
const pair: ir.Type = .{ .int = 128 };
const Entry = struct { uses: usize = 0, definition: *ir.Instruction };
const Entries = std.HashMap([]const u8, Entry, ir.identifiers.Context, std.hash_map.default_max_load_percentage);

fn discardable(inst: ir.Instruction) bool {
    return switch (inst.kind) {
        .binary => |binary| binary.ty.eql(pair),
        .cast => |cast| cast.from_ty.eql(pair) or cast.to_ty.eql(pair),
        else => false,
    };
}

const Counter = struct {
    pub const Error = error{};
    entries: *Entries,
    pub fn visit(v: Counter, value: *const ir.Value, _: ir.Type) Error!void {
        if (value.* == .named) if (v.entries.getPtr(value.named)) |entry| {
            entry.uses += 1;
        };
    }
};

const Remover = struct {
    pub const Error = std.mem.Allocator.Error;
    allocator: std.mem.Allocator,
    entries: *Entries,
    pending: *std.ArrayList(*ir.Instruction),
    pub fn visit(v: Remover, value: *const ir.Value, _: ir.Type) Error!void {
        if (value.* == .named) if (v.entries.getPtr(value.named)) |entry| {
            std.debug.assert(entry.uses > 0);
            entry.uses -= 1;
            if (entry.uses == 0 and !entry.definition.removed and discardable(entry.definition.*))
                try v.pending.append(v.allocator, entry.definition);
        };
    }
};

pub fn removeUnused(allocator: std.mem.Allocator, function: *ir.Function) !usize {
    var entries = Entries.init(allocator);
    defer entries.deinit();
    for (function.blocks.items) |block| for (block.instructions.items) |*inst| {
        if (inst.removed) continue;
        if (inst.result) |name| {
            const entry = try entries.getOrPut(name);
            if (entry.found_existing) return error.DuplicatePrivateDefinition;
            entry.value_ptr.* = .{ .definition = inst };
        }
    };
    const counter: Counter = .{ .entries = &entries };
    for (function.blocks.items) |block| {
        for (block.instructions.items) |*inst| {
            if (inst.removed) continue;
            const coverage = try ir.operands.instruction(@as(*const ir.Instruction, inst), counter);
            if (coverage.has_opaque_references) return 0;
        }
        if (block.terminator) |term| {
            if ((try ir.operands.terminator(&term, counter)).has_opaque_references) return 0;
        }
    }
    var pending: std.ArrayList(*ir.Instruction) = .empty;
    defer pending.deinit(allocator);
    var iterator = entries.valueIterator();
    while (iterator.next()) |entry| {
        if (entry.uses == 0 and discardable(entry.definition.*)) try pending.append(allocator, entry.definition);
    }
    const remover: Remover = .{ .allocator = allocator, .entries = &entries, .pending = &pending };
    var removed: usize = 0;
    while (pending.pop()) |inst| {
        if (inst.removed) continue;
        inst.removed = true;
        removed += 1;
        _ = try ir.operands.instruction(@as(*const ir.Instruction, inst), remover);
    }
    return removed;
}
