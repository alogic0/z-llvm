const std = @import("std");
const alias = @import("../analysis/alias.zig");
const cfg = @import("../analysis/cfg.zig");
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
        const function_changed = try eliminateFunction(module.allocator, module.*, layout, function);
        changed = function_changed or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn eliminateFunction(allocator: std.mem.Allocator, module: ir.Module, layout: ?target.DataLayout, function: *ir.Function) !bool {
    var changed = false;
    var graph = try cfg.Graph.build(allocator, function.*);
    defer graph.deinit();

    for (function.blocks.items, 0..) |*block, block_index| {
        for (block.instructions.items, 0..) |*instruction, index| {
            if (instruction.removed) continue;

            switch (instruction.kind) {
                .store => |store| {
                    if (memory_effect.classify(instruction.*) == .volatile_or_atomic_barrier) {
                        continue;
                    }
                    _ = store;
                    if (memory_ssa.storeOverwrittenInBlock(function.*, layout, block.*, index) or
                        storeOverwrittenInSingleSuccessor(module, function.*, graph, block_index, index))
                    {
                        instruction.removed = true;
                        changed = true;
                    }
                },
                .load, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .call => {},
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .gep => {},
            }
        }
    }
    if (changed) try memory_ssa.verifyFunction(allocator, module, function.*);
    return changed;
}

fn storeOverwrittenInSingleSuccessor(module: ir.Module, function: ir.Function, graph: cfg.Graph, block_index: usize, store_index: usize) bool {
    const block = function.blocks.items[block_index];
    if (store_index >= block.instructions.items.len) return false;
    const store_instruction = block.instructions.items[store_index];
    const store = switch (store_instruction.kind) {
        .store => |store| store,
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .gep, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .call => return false,
    };
    if (memory_effect.classify(store_instruction) == .volatile_or_atomic_barrier) return false;
    if (!suffixHasNoBlockingAccess(module, function, block, store_index + 1, store)) return false;

    const successors = graph.successors(block_index);
    if (successors.len != 1) return false;
    const successor_index = successors[0];
    if (graph.predecessors(successor_index).len != 1) return false;

    var visited_storage: [64]bool = undefined;
    if (function.blocks.items.len > visited_storage.len) return false;
    const visited = visited_storage[0..function.blocks.items.len];
    @memset(visited, false);
    return successorChainFindsOverwrite(module, function, graph, successor_index, store, visited);
}

fn successorChainFindsOverwrite(module: ir.Module, function: ir.Function, graph: cfg.Graph, block_index: usize, store: ir.StoreInst, visited: []bool) bool {
    if (visited[block_index]) return false;
    visited[block_index] = true;

    if (graph.predecessors(block_index).len != 1) return false;

    const block = function.blocks.items[block_index];
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .store => |later_store| {
                if (memory_effect.classify(instruction) == .volatile_or_atomic_barrier) return false;
                if (later_store.ty.eql(store.ty) and
                    alias.accessAliasInModule(module, function, later_store.ptr, later_store.ty, store.ptr, store.ty) == .must_alias)
                {
                    return true;
                }
                if (accessBlocksDse(module, function, instruction, store)) return false;
            },
            .load, .atomicrmw, .cmpxchg, .fence, .call => {
                if (accessBlocksDse(module, function, instruction, store)) return false;
            },
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .gep, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => {},
        }
    }

    const successors = graph.successors(block_index);
    if (successors.len != 1) return false;
    return successorChainFindsOverwrite(module, function, graph, successors[0], store, visited);
}

fn suffixHasNoBlockingAccess(module: ir.Module, function: ir.Function, block: ir.BasicBlock, start_index: usize, store: ir.StoreInst) bool {
    for (block.instructions.items[start_index..]) |instruction| {
        if (instruction.removed) continue;
        if (accessBlocksDse(module, function, instruction, store)) return false;
    }
    return true;
}

fn accessBlocksDse(module: ir.Module, function: ir.Function, instruction: ir.Instruction, store: ir.StoreInst) bool {
    return switch (instruction.kind) {
        .load => |load| {
            if (memory_effect.classify(instruction) == .volatile_or_atomic_barrier) return true;
            return alias.accessAliasInModule(module, function, load.ptr, load.ty, store.ptr, store.ty) != .no_alias;
        },
        .store => |other_store| {
            if (memory_effect.classify(instruction) == .volatile_or_atomic_barrier) return true;
            return alias.accessAliasInModule(module, function, other_store.ptr, other_store.ty, store.ptr, store.ty) != .no_alias;
        },
        .atomicrmw, .cmpxchg, .fence, .call => true,
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .gep, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => false,
    };
}

fn moduleLayout(module: ir.Module) ?target.DataLayout {
    const text = module.target_datalayout orelse return null;
    return target.DataLayout.parse(text) catch null;
}
