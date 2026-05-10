const std = @import("std");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "dce",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;

    for (module.functions.items) |*function| {
        var used = std.StringHashMap(void).init(module.allocator);
        defer used.deinit();

        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                if (instruction.removed) continue;
                try markValue(&used, instruction.lhs);
                try markValue(&used, instruction.rhs);
            }
            if (block.terminator) |terminator| switch (terminator) {
                .ret => |ret| try markValue(&used, ret.value),
                .br => {},
                .condbr => |condbr| try markValue(&used, condbr.cond),
            };
        }

        var local_changed = true;
        while (local_changed) {
            local_changed = false;
            for (function.blocks.items) |*block| {
                for (block.instructions.items) |*instruction| {
                    if (instruction.removed) continue;
                    if (used.contains(instruction.result) or instruction.hasSideEffects()) continue;

                    instruction.removed = true;
                    changed = true;
                    local_changed = true;
                }
            }

            if (local_changed) {
                used.clearRetainingCapacity();
                for (function.blocks.items) |block| {
                    for (block.instructions.items) |instruction| {
                        if (instruction.removed) continue;
                        try markValue(&used, instruction.lhs);
                        try markValue(&used, instruction.rhs);
                    }
                    if (block.terminator) |terminator| switch (terminator) {
                        .ret => |ret| try markValue(&used, ret.value),
                        .br => {},
                        .condbr => |condbr| try markValue(&used, condbr.cond),
                    };
                }
            }
        }
    }

    return if (changed) .changed else .unchanged;
}

fn markValue(used: *std.StringHashMap(void), value: ir.Value) !void {
    switch (value) {
        .int => {},
        .named => |name| try used.put(name, {}),
    }
}
