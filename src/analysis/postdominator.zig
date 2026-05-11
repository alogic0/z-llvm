const std = @import("std");
const cfg = @import("cfg.zig");
const ir = @import("../ir.zig");

pub const PostDominators = struct {
    allocator: std.mem.Allocator,
    block_count: usize,
    bits: []bool,

    pub fn build(allocator: std.mem.Allocator, function: ir.Function) !PostDominators {
        var graph = try cfg.Graph.build(allocator, function);
        defer graph.deinit();

        const reachable = try graph.reachableFromEntry(allocator);
        defer allocator.free(reachable);

        const block_count = function.blocks.items.len;
        const bits = try allocator.alloc(bool, block_count * block_count);
        errdefer allocator.free(bits);
        @memset(bits, false);

        var postdom: PostDominators = .{
            .allocator = allocator,
            .block_count = block_count,
            .bits = bits,
        };

        for (0..block_count) |block_index| {
            if (!reachable[block_index]) continue;
            if (isExitBlock(graph, block_index)) {
                postdom.set(block_index, block_index, true);
            } else {
                for (0..block_count) |candidate| {
                    postdom.set(candidate, block_index, reachable[candidate]);
                }
            }
        }

        var changed = true;
        while (changed) {
            changed = false;
            for (0..block_count) |block_index| {
                if (!reachable[block_index] or isExitBlock(graph, block_index)) continue;

                for (0..block_count) |candidate| {
                    var new_value = candidate == block_index;
                    if (!new_value) {
                        var all_successors = true;
                        var saw_reachable_successor = false;
                        for (graph.successors(block_index)) |successor| {
                            if (!reachable[successor]) continue;
                            saw_reachable_successor = true;
                            if (!postdom.postdominates(candidate, successor)) {
                                all_successors = false;
                                break;
                            }
                        }
                        new_value = saw_reachable_successor and all_successors;
                    }

                    if (postdom.postdominates(candidate, block_index) != new_value) {
                        postdom.set(candidate, block_index, new_value);
                        changed = true;
                    }
                }
            }
        }

        return postdom;
    }

    pub fn deinit(postdom: *PostDominators) void {
        postdom.allocator.free(postdom.bits);
    }

    pub fn postdominates(postdom: PostDominators, postdominator: usize, block: usize) bool {
        return postdom.bits[postdom.index(postdominator, block)];
    }

    pub fn immediatePostDominator(postdom: PostDominators, block: usize) ?usize {
        if (block >= postdom.block_count) return null;
        var best: ?usize = null;
        for (0..postdom.block_count) |candidate| {
            if (candidate == block or !postdom.postdominates(candidate, block)) continue;
            if (best == null or postdom.postdominates(best.?, candidate)) {
                best = candidate;
            }
        }
        return best;
    }

    fn set(postdom: *PostDominators, postdominator: usize, block: usize, value: bool) void {
        postdom.bits[postdom.index(postdominator, block)] = value;
    }

    fn index(postdom: PostDominators, postdominator: usize, block: usize) usize {
        return block * postdom.block_count + postdominator;
    }
};

pub const ControlDependence = struct {
    graph: cfg.Graph,
    postdom: PostDominators,

    pub fn isControlDependentOn(dependence: ControlDependence, dependent_block: usize, controller_block: usize) bool {
        if (dependent_block >= dependence.postdom.block_count or controller_block >= dependence.postdom.block_count) return false;
        const successors = dependence.graph.successors(controller_block);
        if (successors.len < 2) return false;
        if (dependence.postdom.postdominates(dependent_block, controller_block)) return false;

        for (successors) |successor| {
            if (dependence.postdom.postdominates(dependent_block, successor)) return true;
        }
        return false;
    }
};

fn isExitBlock(graph: cfg.Graph, block_index: usize) bool {
    return graph.successors(block_index).len == 0;
}
