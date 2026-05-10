const std = @import("std");
const def_use = @import("../analysis/def_use.zig");
const memory_effect = @import("../analysis/memory_effect.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "adce",
    .category = .scalar,
    .target_status = "local conservative substitute",
    .upstream_owner = "llvm/lib/Transforms/Scalar/ADCE.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        changed = try eliminateFunction(module.allocator, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn eliminateFunction(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    var uses = try def_use.UseCounts.collectFunction(allocator, function.*);
    defer uses.deinit();

    var changed = false;
    var local_changed = true;
    while (local_changed) {
        local_changed = false;
        var block_index = function.blocks.items.len;
        while (block_index > 0) {
            block_index -= 1;
            const block = &function.blocks.items[block_index];
            var instruction_index = block.instructions.items.len;
            while (instruction_index > 0) {
                instruction_index -= 1;
                const instruction = &block.instructions.items[instruction_index];
                if (instruction.removed or memory_effect.hasSideEffects(instruction.*)) continue;
                const result = instruction.result orelse continue;
                if (uses.isUsed(result)) continue;

                uses.removeInstructionOperands(instruction.*);
                instruction.removed = true;
                changed = true;
                local_changed = true;
            }
        }
    }
    return changed;
}
