const std = @import("std");
const alias = @import("../analysis/alias.zig");
const memory_effect = @import("../analysis/memory_effect.zig");
const memory_location = @import("../analysis/memory_location.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "dse",
    .category = .memory,
    .target_status = "fixture-equivalent for listed fixtures",
    .upstream_owner = "llvm/lib/Transforms/Scalar/DeadStoreElimination.cpp",
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
    var changed = false;
    for (function.blocks.items) |*block| {
        var later_stores: std.ArrayList(memory_location.MemoryLocation) = .empty;
        defer later_stores.deinit(allocator);

        var index = block.instructions.items.len;
        while (index > 0) {
            index -= 1;
            const instruction = &block.instructions.items[index];
            if (instruction.removed) continue;

            switch (instruction.kind) {
                .store => |store| {
                    if (memory_effect.classify(instruction.*) == .volatile_or_atomic_barrier) {
                        later_stores.clearRetainingCapacity();
                        continue;
                    }

                    const location = memory_location.forAccess(function.*, store.ptr, store.ty) orelse {
                        later_stores.clearRetainingCapacity();
                        continue;
                    };
                    if (hasMustAliasLaterStore(later_stores.items, location)) {
                        instruction.removed = true;
                        changed = true;
                        continue;
                    }
                    pruneMayAliasStores(&later_stores, location);
                    try later_stores.append(allocator, location);
                },
                .load => |load| {
                    if (memory_effect.classify(instruction.*) == .volatile_or_atomic_barrier) {
                        later_stores.clearRetainingCapacity();
                        continue;
                    }
                    const location = memory_location.forAccess(function.*, load.ptr, load.ty) orelse {
                        later_stores.clearRetainingCapacity();
                        continue;
                    };
                    pruneMayAliasStores(&later_stores, location);
                },
                .call => later_stores.clearRetainingCapacity(),
                .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .gep => {},
            }
        }
    }
    return changed;
}

fn hasMustAliasLaterStore(later_stores: []const memory_location.MemoryLocation, location: memory_location.MemoryLocation) bool {
    for (later_stores) |later| {
        if (alias.aliasLocations(later, location) == .must_alias) return true;
    }
    return false;
}

fn pruneMayAliasStores(later_stores: *std.ArrayList(memory_location.MemoryLocation), location: memory_location.MemoryLocation) void {
    var index = later_stores.items.len;
    while (index > 0) {
        index -= 1;
        if (alias.aliasLocations(later_stores.items[index], location) == .no_alias) continue;
        _ = later_stores.orderedRemove(index);
    }
}
