const std = @import("std");
const block_addresses = @import("../analysis/block_addresses.zig");
const cfg = @import("../analysis/cfg.zig");
const cfg_update = @import("../analysis/cfg_update.zig");
const loop_info = @import("../analysis/loop_info.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "loop-simplifycfg",
    .category = .loop,
    .target_status = "LLVM-shaped algorithm subset",
    .upstream_owner = "llvm/lib/Transforms/Scalar/LoopSimplifyCFG.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var address_guard = try block_addresses.Guard.build(module.allocator, module.*);
    defer address_guard.deinit();
    var changed = false;
    for (module.functions.items) |*function| {
        if (address_guard.contains(function.name)) continue;
        changed = try simplifyFunction(module.allocator, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn simplifyFunction(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    var changed = false;
    var local_changed = true;
    while (local_changed) {
        local_changed = false;
        var loops = try loop_info.LoopInfo.build(allocator, function.*);
        defer loops.deinit();

        for (loops.loops.items) |natural_loop| {
            if (try simplifyLoop(allocator, function, natural_loop)) {
                changed = true;
                local_changed = true;
                break;
            }
        }
    }
    return changed;
}

fn simplifyLoop(allocator: std.mem.Allocator, function: *ir.Function, natural_loop: loop_info.NaturalLoop) !bool {
    var graph = try cfg.Graph.build(allocator, function.*);
    defer graph.deinit();

    if (natural_loop.preheader(function.*, graph) == null) return false;
    if (!try natural_loop.hasDedicatedExits(allocator, graph)) return false;
    if (!try natural_loop.hasLcssaForm(allocator, function.*, graph)) return false;

    if (findConstantTerminatorFold(function.*, natural_loop)) |candidate| {
        function.blocks.items[candidate.block_index].terminator = .{ .br = .{ .target = candidate.live_target } };

        var changed = true;
        changed = try cfg_update.prunePhiIncomingToPredecessors(allocator, function) or changed;
        changed = try cfg_update.removeUnreachableBlocks(allocator, function) or changed;
        return changed;
    }

    return try mergeLoopBlocksIntoPredecessors(allocator, function, natural_loop, graph);
}

const TerminatorFold = struct {
    block_index: usize,
    live_target: []const u8,
};

fn findConstantTerminatorFold(function: ir.Function, natural_loop: loop_info.NaturalLoop) ?TerminatorFold {
    for (natural_loop.blocks.items) |block_index| {
        if (block_index == natural_loop.header or block_index == natural_loop.latch) continue;
        if (block_index >= function.blocks.items.len) continue;
        const block = function.blocks.items[block_index];
        const condbr = switch (block.terminator orelse continue) {
            .condbr => |condbr| condbr,
            .ret, .br, .@"switch", .indirectbr, .@"unreachable" => continue,
        };
        if (condbr.cond != .int) continue;

        const live_target = if (condbr.cond.int == 0) condbr.else_target else condbr.then_target;
        const dead_target = if (condbr.cond.int == 0) condbr.then_target else condbr.else_target;
        const live_index = function.blockIndex(live_target) orelse continue;
        const dead_index = function.blockIndex(dead_target) orelse continue;
        if (!natural_loop.contains(live_index) or !natural_loop.contains(dead_index)) continue;
        if (dead_index == natural_loop.header or dead_index == natural_loop.latch) continue;
        return .{
            .block_index = block_index,
            .live_target = live_target,
        };
    }
    return null;
}

fn mergeLoopBlocksIntoPredecessors(allocator: std.mem.Allocator, function: *ir.Function, natural_loop: loop_info.NaturalLoop, graph: cfg.Graph) !bool {
    for (function.blocks.items, 0..) |*block, block_index| {
        if (!natural_loop.contains(block_index)) continue;
        const br = switch (block.terminator orelse continue) {
            .br => |br| br,
            .ret, .condbr, .@"switch", .indirectbr, .@"unreachable" => continue,
        };
        const target_index = function.blockIndex(br.target) orelse continue;
        if (target_index == block_index or target_index == natural_loop.header) continue;
        if (!natural_loop.contains(target_index)) continue;
        if (graph.predecessors(target_index).len != 1) continue;
        if (hasPhi(function.blocks.items[target_index])) continue;

        const target = &function.blocks.items[target_index];
        for (target.instructions.items) |instruction| {
            try block.instructions.append(allocator, instruction);
        }
        target.instructions.deinit(allocator);
        target.instructions = .empty;
        block.terminator = target.terminator;
        target.terminator = null;
        _ = cfg_update.replacePhiIncomingBlock(function, target.name, block.name);

        var removed = function.blocks.orderedRemove(target_index);
        removed.deinit(allocator);
        return true;
    }
    return false;
}

fn hasPhi(block: ir.BasicBlock) bool {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        if (instruction.kind == .phi) return true;
    }
    return false;
}
