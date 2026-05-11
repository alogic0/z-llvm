const std = @import("std");
const cfg = @import("cfg.zig");
const ir = @import("../ir.zig");

pub fn retargetBranches(function: *ir.Function, old_target: []const u8, new_target: []const u8) bool {
    var changed = false;
    for (function.blocks.items) |*block| {
        changed = retargetBlockTerminator(block, old_target, new_target) or changed;
    }
    return changed;
}

pub fn retargetBlockTerminator(block: *ir.BasicBlock, old_target: []const u8, new_target: []const u8) bool {
    var changed = false;
    if (block.terminator) |*terminator| switch (terminator.*) {
        .br => |*br| {
            if (std.mem.eql(u8, br.target, old_target)) {
                br.target = new_target;
                changed = true;
            }
        },
        .condbr => |*condbr| {
            if (std.mem.eql(u8, condbr.then_target, old_target)) {
                condbr.then_target = new_target;
                changed = true;
            }
            if (std.mem.eql(u8, condbr.else_target, old_target)) {
                condbr.else_target = new_target;
                changed = true;
            }
        },
        .ret => {},
        .@"unreachable" => {},
    };
    return changed;
}

pub fn replacePhiIncomingBlock(function: *ir.Function, old_name: []const u8, new_name: []const u8) bool {
    var changed = false;
    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .phi => |*phi| for (phi.incoming.items) |*incoming| {
                    if (std.mem.eql(u8, incoming.block, old_name)) {
                        incoming.block = new_name;
                        changed = true;
                    }
                },
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .gep, .call => {},
            }
        }
    }
    return changed;
}

pub fn prunePhiIncomingToPredecessors(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    var graph = try cfg.Graph.build(allocator, function.*);
    defer graph.deinit();

    var changed = false;
    for (function.blocks.items, 0..) |*block, block_index| {
        const predecessors = graph.predecessors(block_index);
        for (block.instructions.items) |*instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .phi => |*phi| {
                    var index = phi.incoming.items.len;
                    while (index > 0) {
                        index -= 1;
                        const incoming_block_index = function.blockIndex(phi.incoming.items[index].block) orelse {
                            _ = phi.incoming.orderedRemove(index);
                            changed = true;
                            continue;
                        };
                        if (containsIndex(predecessors, incoming_block_index)) continue;
                        _ = phi.incoming.orderedRemove(index);
                        changed = true;
                    }
                },
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .gep, .call => {},
            }
        }
    }
    return changed;
}

pub fn prunePhiIncomingByReachability(function: *ir.Function, reachable: []const bool) bool {
    var changed = false;
    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .phi => |*phi| {
                    var index = phi.incoming.items.len;
                    while (index > 0) {
                        index -= 1;
                        const incoming_block_index = function.blockIndex(phi.incoming.items[index].block) orelse {
                            _ = phi.incoming.orderedRemove(index);
                            changed = true;
                            continue;
                        };
                        if (reachable[incoming_block_index]) continue;
                        _ = phi.incoming.orderedRemove(index);
                        changed = true;
                    }
                },
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .gep, .call => {},
            }
        }
    }
    return changed;
}

pub fn removeUnreachableBlocks(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    if (function.blocks.items.len == 0) return false;

    var graph = try cfg.Graph.build(allocator, function.*);
    defer graph.deinit();

    const reachable = try graph.reachableFromEntry(allocator);
    defer allocator.free(reachable);

    var changed = false;
    changed = prunePhiIncomingByReachability(function, reachable) or changed;

    var index = function.blocks.items.len;
    while (index > 0) {
        index -= 1;
        if (reachable[index]) continue;

        var removed = function.blocks.orderedRemove(index);
        removed.deinit(allocator);
        changed = true;
    }
    return changed;
}

fn containsIndex(values: []const usize, needle: usize) bool {
    for (values) |value| {
        if (value == needle) return true;
    }
    return false;
}
