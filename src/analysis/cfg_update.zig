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
        .@"switch" => |*switch_term| {
            if (std.mem.eql(u8, switch_term.default_target, old_target)) {
                switch_term.default_target = new_target;
                changed = true;
            }
            for (switch_term.cases.items) |*case| {
                if (std.mem.eql(u8, case.target, old_target)) {
                    case.target = new_target;
                    changed = true;
                }
            }
        },
        .indirectbr => |*indirectbr| {
            for (indirectbr.targets.items) |*target| {
                if (std.mem.eql(u8, target.*, old_target)) {
                    target.* = new_target;
                    changed = true;
                }
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
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => {},
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
                    for (predecessors) |predecessor_index| {
                        changed = pruneExcessPhiIncomingForPredecessor(function.*, block.name, phi, predecessor_index) or changed;
                    }
                },
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => {},
            }
        }
    }
    return changed;
}

fn pruneExcessPhiIncomingForPredecessor(
    function: ir.Function,
    target_name: []const u8,
    phi: *ir.PhiInst,
    predecessor_index: usize,
) bool {
    const predecessor = function.blocks.items[predecessor_index];
    const edge_count = terminatorTargetEdgeCount(predecessor.terminator, target_name);
    if (edge_count == 0) return false;

    var incoming_count: usize = 0;
    var incoming_value: ?ir.Value = null;
    for (phi.incoming.items) |incoming| {
        if (!std.mem.eql(u8, incoming.block, predecessor.name)) continue;
        incoming_count += 1;
        if (incoming_value) |value| {
            if (!value.eql(incoming.value)) return false;
        } else {
            incoming_value = incoming.value;
        }
    }
    if (incoming_count <= edge_count) return false;

    var changed = false;
    var kept: usize = 0;
    var index: usize = 0;
    while (index < phi.incoming.items.len) {
        if (!std.mem.eql(u8, phi.incoming.items[index].block, predecessor.name)) {
            index += 1;
            continue;
        }
        if (kept < edge_count) {
            kept += 1;
            index += 1;
            continue;
        }
        _ = phi.incoming.orderedRemove(index);
        changed = true;
    }
    return changed;
}

fn terminatorTargetEdgeCount(terminator: ?ir.Terminator, target_name: []const u8) usize {
    const term = terminator orelse return 0;
    var count: usize = 0;
    switch (term) {
        .ret, .@"unreachable" => {},
        .br => |br| {
            if (std.mem.eql(u8, br.target, target_name)) count += 1;
        },
        .condbr => |condbr| {
            if (std.mem.eql(u8, condbr.then_target, target_name)) count += 1;
            if (std.mem.eql(u8, condbr.else_target, target_name)) count += 1;
        },
        .@"switch" => |switch_term| {
            if (std.mem.eql(u8, switch_term.default_target, target_name)) count += 1;
            for (switch_term.cases.items) |case| {
                if (std.mem.eql(u8, case.target, target_name)) count += 1;
            }
        },
        .indirectbr => |indirectbr| {
            for (indirectbr.targets.items) |target| {
                if (std.mem.eql(u8, target, target_name)) count += 1;
            }
        },
    }
    return count;
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
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => {},
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
