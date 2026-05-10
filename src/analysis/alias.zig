const std = @import("std");
const ir = @import("../ir.zig");
const memory_effect = @import("memory_effect.zig");

pub const AliasResult = enum {
    no_alias,
    may_alias,
    must_alias,
};

pub const ModRefInfo = enum {
    no_mod_ref,
    ref,
    mod,
    mod_ref,
    unknown,
};

pub fn alias(function: ir.Function, a: ir.Value, b: ir.Value) AliasResult {
    if (a.eql(b)) return .must_alias;

    const a_object = pointerObject(function, a) orelse return .may_alias;
    const b_object = pointerObject(function, b) orelse return .may_alias;

    if (!std.mem.eql(u8, a_object.root, b_object.root)) return .no_alias;
    return if (a_object.zero_offset and b_object.zero_offset) .must_alias else .may_alias;
}

pub fn modRef(function: ir.Function, instruction: ir.Instruction, pointer: ir.Value) ModRefInfo {
    return switch (instruction.kind) {
        .load => |load| {
            if (memory_effect.classify(instruction) == .volatile_or_atomic_barrier) return .unknown;
            return if (alias(function, load.ptr, pointer) == .no_alias) .no_mod_ref else .ref;
        },
        .store => |store| {
            if (memory_effect.classify(instruction) == .volatile_or_atomic_barrier) return .unknown;
            return if (alias(function, store.ptr, pointer) == .no_alias) .no_mod_ref else .mod;
        },
        .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .gep => .no_mod_ref,
    };
}

const PointerObject = struct {
    root: []const u8,
    zero_offset: bool,
};

fn pointerObject(function: ir.Function, value: ir.Value) ?PointerObject {
    const name = switch (value) {
        .int, .undef => return null,
        .named => |name| name,
    };

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const result = instruction.result orelse continue;
            if (!std.mem.eql(u8, result, name)) continue;

            switch (instruction.kind) {
                .alloca => return .{ .root = result, .zero_offset = true },
                .gep => |gep| {
                    var base = pointerObject(function, gep.ptr) orelse return null;
                    base.zero_offset = base.zero_offset and hasOnlyZeroIndices(gep);
                    return base;
                },
                .binary, .cast, .freeze, .icmp, .select, .phi, .load, .store => return null,
            }
        }
    }
    return null;
}

fn hasOnlyZeroIndices(gep: ir.GepInst) bool {
    for (gep.indices.items) |index| {
        switch (index.value) {
            .int => |value| if (value != 0) return false,
            .named, .undef => return false,
        }
    }
    return true;
}
