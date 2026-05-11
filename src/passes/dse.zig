const std = @import("std");
const memory_effect = @import("../analysis/memory_effect.zig");
const memory_ssa = @import("../analysis/memory_ssa.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");
const target = @import("../target.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "dse",
    .category = .memory,
    .target_status = "fixture-equivalent for listed fixtures",
    .upstream_owner = "llvm/lib/Transforms/Scalar/DeadStoreElimination.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    const layout = moduleLayout(module.*);
    for (module.functions.items) |*function| {
        changed = try eliminateFunction(module.allocator, layout, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn eliminateFunction(allocator: std.mem.Allocator, layout: ?target.DataLayout, function: *ir.Function) !bool {
    _ = allocator;
    var changed = false;
    for (function.blocks.items) |*block| {
        for (block.instructions.items, 0..) |*instruction, index| {
            if (instruction.removed) continue;

            switch (instruction.kind) {
                .store => |store| {
                    if (memory_effect.classify(instruction.*) == .volatile_or_atomic_barrier) {
                        continue;
                    }
                    _ = store;
                    if (memory_ssa.storeOverwrittenInBlock(function.*, layout, block.*, index)) {
                        instruction.removed = true;
                        changed = true;
                    }
                },
                .load, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .call => {},
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .gep => {},
            }
        }
    }
    return changed;
}

fn moduleLayout(module: ir.Module) ?target.DataLayout {
    const text = module.target_datalayout orelse return null;
    return target.DataLayout.parse(text) catch null;
}
