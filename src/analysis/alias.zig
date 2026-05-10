const std = @import("std");
const ir = @import("../ir.zig");

pub const AliasResult = enum {
    no_alias,
    may_alias,
    must_alias,
};

pub fn alias(function: ir.Function, a: ir.Value, b: ir.Value) AliasResult {
    if (a.eql(b)) return .must_alias;

    const a_alloca = definingAlloca(function, a) orelse return .may_alias;
    const b_alloca = definingAlloca(function, b) orelse return .may_alias;

    return if (std.mem.eql(u8, a_alloca, b_alloca)) .must_alias else .no_alias;
}

fn definingAlloca(function: ir.Function, value: ir.Value) ?[]const u8 {
    const name = switch (value) {
        .int => return null,
        .named => |name| name,
    };

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed or instruction.kind != .alloca) continue;
            const result = instruction.result orelse continue;
            if (std.mem.eql(u8, result, name)) return result;
        }
    }
    return null;
}
