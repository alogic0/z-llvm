const std = @import("std");
const cfg = @import("cfg.zig");
const ir = @import("../ir.zig");

pub const Dominators = struct {
    allocator: std.mem.Allocator,
    block_count: usize,
    bits: []bool,

    pub fn build(allocator: std.mem.Allocator, function: ir.Function) !Dominators {
        var graph = try cfg.Graph.build(allocator, function);
        defer graph.deinit();

        const reachable = try graph.reachableFromEntry(allocator);
        defer allocator.free(reachable);

        const block_count = function.blocks.items.len;
        const bits = try allocator.alloc(bool, block_count * block_count);
        errdefer allocator.free(bits);
        @memset(bits, false);

        var dom: Dominators = .{
            .allocator = allocator,
            .block_count = block_count,
            .bits = bits,
        };

        for (0..block_count) |block_index| {
            if (!reachable[block_index]) continue;
            if (block_index == 0) {
                dom.set(0, 0, true);
            } else {
                for (0..block_count) |candidate| {
                    dom.set(candidate, block_index, reachable[candidate]);
                }
            }
        }

        var changed = true;
        while (changed) {
            changed = false;
            for (1..block_count) |block_index| {
                if (!reachable[block_index]) continue;

                for (0..block_count) |candidate| {
                    var new_value = candidate == block_index;
                    if (!new_value) {
                        var all_preds = true;
                        var saw_reachable_pred = false;
                        for (graph.predecessors(block_index)) |pred| {
                            if (!reachable[pred]) continue;
                            saw_reachable_pred = true;
                            if (!dom.dominates(candidate, pred)) {
                                all_preds = false;
                                break;
                            }
                        }
                        new_value = saw_reachable_pred and all_preds;
                    }

                    if (dom.dominates(candidate, block_index) != new_value) {
                        dom.set(candidate, block_index, new_value);
                        changed = true;
                    }
                }
            }
        }

        return dom;
    }

    pub fn deinit(dom: *Dominators) void {
        dom.allocator.free(dom.bits);
    }

    pub fn dominates(dom: Dominators, dominator: usize, block: usize) bool {
        return dom.bits[dom.index(dominator, block)];
    }

    fn set(dom: *Dominators, dominator: usize, block: usize, value: bool) void {
        dom.bits[dom.index(dominator, block)] = value;
    }

    fn index(dom: Dominators, dominator: usize, block: usize) usize {
        return block * dom.block_count + dominator;
    }
};
