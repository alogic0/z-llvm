const std = @import("std");
const cfg = @import("../analysis/cfg.zig");
const cfg_update = @import("../analysis/cfg_update.zig");
const dominator = @import("../analysis/dominator.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "jump-threading",
    .category = .scalar,
    .target_status = "LLVM-shaped subset for branch-on-PHI predecessor constants",
    .upstream_owner = "llvm/lib/Transforms/Scalar/JumpThreading.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        changed = try threadFunction(module.allocator, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn threadFunction(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    var changed = false;
    var local_changed = true;
    while (local_changed) {
        local_changed = false;

        var graph = try cfg.Graph.build(allocator, function.*);
        defer graph.deinit();

        var dom = try dominator.Dominators.build(allocator, function.*);
        defer dom.deinit();

        for (function.blocks.items, 0..) |_, block_index| {
            if (isLoopHeader(graph, dom, block_index)) continue;
            if (try threadBlock(allocator, function, graph, dom, block_index)) {
                _ = try cfg_update.prunePhiIncomingToPredecessors(allocator, function);
                _ = try cfg_update.removeUnreachableBlocks(allocator, function);
                changed = true;
                local_changed = true;
                break;
            }
        }
    }
    return changed;
}

fn isLoopHeader(graph: cfg.Graph, dom: dominator.Dominators, block_index: usize) bool {
    for (graph.predecessors(block_index)) |predecessor| {
        if (predecessor != block_index and dom.dominates(block_index, predecessor)) return true;
    }
    return false;
}

fn threadBlock(allocator: std.mem.Allocator, function: *ir.Function, graph: cfg.Graph, dom: dominator.Dominators, block_index: usize) !bool {
    const block = function.blocks.items[block_index];
    const condbr = switch (block.terminator orelse return false) {
        .condbr => |condbr| condbr,
        .ret, .br, .@"switch", .indirectbr, .@"unreachable" => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 })) return false;

    const cond_name = switch (condbr.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const cond_phi = findPhiByResult(block, cond_name) orelse return false;
    if (!cond_phi.ty.eql(.{ .int = 1 })) return false;

    var changed = false;
    const predecessors = graph.predecessors(block_index);
    for (predecessors) |predecessor_index| {
        if (predecessor_index == block_index) continue;

        const incoming = phiIncomingForBlock(cond_phi, function.blocks.items[predecessor_index].name) orelse continue;
        const known = switch (incoming) {
            .int => |value| value,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => continue,
        };
        const destination = if (known == 0) condbr.else_target else condbr.then_target;
        const destination_index = function.blockIndex(destination) orelse continue;
        if (destination_index == block_index) continue;
        if (isLoopHeader(graph, dom, destination_index)) continue;

        var predecessor = &function.blocks.items[predecessor_index];
        const predecessor_branch = switch (predecessor.terminator orelse continue) {
            .br => |br| br,
            .ret, .condbr, .@"switch", .indirectbr, .@"unreachable" => continue,
        };
        if (!std.mem.eql(u8, predecessor_branch.target, block.name)) continue;

        try addPhiEntriesForThreadedEdge(allocator, function, block_index, predecessor_index, destination_index);
        predecessor.terminator = .{ .br = .{
            .target = destination,
            .metadata = predecessor_branch.metadata,
        } };
        changed = true;
    }

    return changed;
}

fn findPhiByResult(block: ir.BasicBlock, result_name: []const u8) ?ir.PhiInst {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const result = instruction.result orelse continue;
        if (!std.mem.eql(u8, result, result_name)) continue;
        return switch (instruction.kind) {
            .phi => |phi| phi,
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => null,
        };
    }
    return null;
}

fn phiIncomingForBlock(phi: ir.PhiInst, block_name: []const u8) ?ir.Value {
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, block_name)) return incoming.value;
    }
    return null;
}

fn addPhiEntriesForThreadedEdge(
    allocator: std.mem.Allocator,
    function: *ir.Function,
    old_block_index: usize,
    predecessor_index: usize,
    destination_index: usize,
) !void {
    const old_block = function.blocks.items[old_block_index];
    const predecessor_name = function.blocks.items[predecessor_index].name;
    for (function.blocks.items[destination_index].instructions.items) |*instruction| {
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .phi => |*phi| {
                if (hasPhiIncomingFrom(phi.*, predecessor_name)) continue;
                const old_value = phiIncomingForBlock(phi.*, old_block.name) orelse continue;
                const translated = translateValueThroughBlock(old_block, predecessor_name, old_value);
                try phi.incoming.append(allocator, .{
                    .value = translated,
                    .block = predecessor_name,
                });
            },
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => {},
        }
    }
}

fn hasPhiIncomingFrom(phi: ir.PhiInst, block_name: []const u8) bool {
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, block_name)) return true;
    }
    return false;
}

fn translateValueThroughBlock(block: ir.BasicBlock, predecessor_name: []const u8, value: ir.Value) ir.Value {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return value,
    };
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const result = instruction.result orelse continue;
        if (!std.mem.eql(u8, result, name)) continue;
        return switch (instruction.kind) {
            .phi => |phi| phiIncomingForBlock(phi, predecessor_name) orelse value,
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => value,
        };
    }
    return value;
}
