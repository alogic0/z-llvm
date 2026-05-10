const std = @import("std");
const def_use = @import("../analysis/def_use.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "dce",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;

    for (module.functions.items) |*function| {
        var uses = try def_use.UseCounts.collectFunction(module.allocator, function.*);
        defer uses.deinit();

        var local_changed = true;
        while (local_changed) {
            local_changed = false;
            for (function.blocks.items) |*block| {
                for (block.instructions.items) |*instruction| {
                    if (instruction.removed) continue;
                    if (uses.isUsed(instruction.result) or instruction.hasSideEffects()) continue;

                    uses.removeInstructionOperands(instruction.*);
                    instruction.removed = true;
                    changed = true;
                    local_changed = true;
                }
            }
        }
    }

    return if (changed) .changed else .unchanged;
}
