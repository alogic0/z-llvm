const std = @import("std");
const ir = @import("../ir.zig");

pub const AliasResult = enum {
    no_alias,
    may_alias,
    must_alias,
};

pub fn alias(function: ir.Function, a: ir.Value, b: ir.Value) AliasResult {
    if (a.eql(b)) return .must_alias;

    const a_object = pointerObject(function, a) orelse return .may_alias;
    const b_object = pointerObject(function, b) orelse return .may_alias;

    if (!std.mem.eql(u8, a_object.root, b_object.root)) return .no_alias;
    return if (a_object.zero_offset and b_object.zero_offset) .must_alias else .may_alias;
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
                .binary, .icmp, .select, .phi, .load, .store => return null,
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
