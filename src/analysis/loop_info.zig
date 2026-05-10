const std = @import("std");
const cfg = @import("cfg.zig");
const dominator = @import("dominator.zig");
const ir = @import("../ir.zig");

pub const NaturalLoop = struct {
    header: usize,
    latch: usize,
    blocks: std.ArrayList(usize),

    pub fn deinit(loop: *NaturalLoop, allocator: std.mem.Allocator) void {
        loop.blocks.deinit(allocator);
    }

    pub fn contains(loop: NaturalLoop, block_index: usize) bool {
        for (loop.blocks.items) |member| {
            if (member == block_index) return true;
        }
        return false;
    }

    pub fn headerBlock(loop: NaturalLoop) usize {
        return loop.header;
    }

    pub fn latchBlock(loop: NaturalLoop) usize {
        return loop.latch;
    }

    pub fn preheader(loop: NaturalLoop, function: ir.Function, graph: cfg.Graph) ?usize {
        var candidate: ?usize = null;
        for (graph.predecessors(loop.header)) |predecessor| {
            if (loop.contains(predecessor)) continue;
            if (candidate != null) return null;
            candidate = predecessor;
        }
        const preheader_index = candidate orelse return null;
        const terminator = function.blocks.items[preheader_index].terminator orelse return null;
        switch (terminator) {
            .br => |br| {
                const target = function.blockIndex(br.target) orelse return null;
                return if (target == loop.header) preheader_index else null;
            },
            .ret, .condbr, .@"unreachable" => return null,
        }
    }

    pub fn exitingBlocks(loop: NaturalLoop, allocator: std.mem.Allocator, graph: cfg.Graph) !std.ArrayList(usize) {
        var exiting: std.ArrayList(usize) = .empty;
        errdefer exiting.deinit(allocator);

        for (loop.blocks.items) |block_index| {
            for (graph.successors(block_index)) |successor| {
                if (!loop.contains(successor)) {
                    try appendUnique(allocator, &exiting, block_index);
                    break;
                }
            }
        }
        sortBlocks(exiting.items);
        return exiting;
    }

    pub fn exitBlocks(loop: NaturalLoop, allocator: std.mem.Allocator, graph: cfg.Graph) !std.ArrayList(usize) {
        var exits: std.ArrayList(usize) = .empty;
        errdefer exits.deinit(allocator);

        for (loop.blocks.items) |block_index| {
            for (graph.successors(block_index)) |successor| {
                if (loop.contains(successor)) continue;
                try appendUnique(allocator, &exits, successor);
            }
        }
        sortBlocks(exits.items);
        return exits;
    }
};

pub const LoopInfo = struct {
    allocator: std.mem.Allocator,
    loops: std.ArrayList(NaturalLoop),

    pub fn build(allocator: std.mem.Allocator, function: ir.Function) !LoopInfo {
        var graph = try cfg.Graph.build(allocator, function);
        defer graph.deinit();

        var dom = try dominator.Dominators.build(allocator, function);
        defer dom.deinit();

        var info: LoopInfo = .{
            .allocator = allocator,
            .loops = .empty,
        };
        errdefer info.deinit();

        for (function.blocks.items, 0..) |_, latch| {
            for (graph.successors(latch)) |header| {
                if (!dom.dominates(header, latch)) continue;
                try info.loops.append(allocator, try buildNaturalLoop(allocator, graph, header, latch));
            }
        }

        return info;
    }

    pub fn deinit(info: *LoopInfo) void {
        for (info.loops.items) |*loop| loop.deinit(info.allocator);
        info.loops.deinit(info.allocator);
    }

    pub fn loopForHeader(info: LoopInfo, header: usize) ?*const NaturalLoop {
        for (info.loops.items) |*loop| {
            if (loop.header == header) return loop;
        }
        return null;
    }
};

fn buildNaturalLoop(allocator: std.mem.Allocator, graph: cfg.Graph, header: usize, latch: usize) !NaturalLoop {
    var loop: NaturalLoop = .{
        .header = header,
        .latch = latch,
        .blocks = .empty,
    };
    errdefer loop.deinit(allocator);

    try appendUnique(allocator, &loop.blocks, header);
    try appendUnique(allocator, &loop.blocks, latch);

    var worklist: std.ArrayList(usize) = .empty;
    defer worklist.deinit(allocator);
    try worklist.append(allocator, latch);

    while (worklist.pop()) |block| {
        for (graph.predecessors(block)) |predecessor| {
            if (predecessor == header) continue;
            const old_len = loop.blocks.items.len;
            try appendUnique(allocator, &loop.blocks, predecessor);
            if (loop.blocks.items.len != old_len) try worklist.append(allocator, predecessor);
        }
    }

    sortBlocks(loop.blocks.items);
    return loop;
}

fn appendUnique(allocator: std.mem.Allocator, list: *std.ArrayList(usize), value: usize) !void {
    for (list.items) |existing| {
        if (existing == value) return;
    }
    try list.append(allocator, value);
}

fn sortBlocks(items: []usize) void {
    var i: usize = 1;
    while (i < items.len) : (i += 1) {
        const value = items[i];
        var j = i;
        while (j > 0 and items[j - 1] > value) : (j -= 1) {
            items[j] = items[j - 1];
        }
        items[j] = value;
    }
}
