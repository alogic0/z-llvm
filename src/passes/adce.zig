const std = @import("std");
const cfg = @import("../analysis/cfg.zig");
const memory_effect = @import("../analysis/memory_effect.zig");
const postdominator = @import("../analysis/postdominator.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "adce",
    .category = .scalar,
    .target_status = "fixture-equivalent for listed fixtures",
    .upstream_owner = "llvm/lib/Transforms/Scalar/ADCE.cpp",
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
    var changed = try removeDeadControlFlow(allocator, function);
    changed = try removeDeadInstructions(allocator, function) or changed;
    return changed;
}

const InstRef = struct {
    block_index: usize,
    instruction_index: usize,
};

const LiveInstructions = struct {
    allocator: std.mem.Allocator,
    function: *ir.Function,
    refs: std.ArrayList(InstRef),
    defs: std.StringHashMap(usize),
    live: []bool,
    worklist: std.ArrayList(usize),

    fn build(allocator: std.mem.Allocator, function: *ir.Function) !LiveInstructions {
        var refs: std.ArrayList(InstRef) = .empty;
        errdefer refs.deinit(allocator);

        var defs = std.StringHashMap(usize).init(allocator);
        errdefer defs.deinit();

        for (function.blocks.items, 0..) |block, block_index| {
            for (block.instructions.items, 0..) |instruction, instruction_index| {
                if (instruction.removed) continue;
                const index = refs.items.len;
                try refs.append(allocator, .{
                    .block_index = block_index,
                    .instruction_index = instruction_index,
                });
                if (instruction.result) |result| try defs.put(result, index);
            }
        }

        const live = try allocator.alloc(bool, refs.items.len);
        errdefer allocator.free(live);
        @memset(live, false);

        var worklist: std.ArrayList(usize) = .empty;
        errdefer worklist.deinit(allocator);

        return .{
            .allocator = allocator,
            .function = function,
            .refs = refs,
            .defs = defs,
            .live = live,
            .worklist = worklist,
        };
    }

    fn deinit(liveness: *LiveInstructions) void {
        liveness.worklist.deinit(liveness.allocator);
        liveness.allocator.free(liveness.live);
        liveness.defs.deinit();
        liveness.refs.deinit(liveness.allocator);
    }

    fn markSeeds(liveness: *LiveInstructions) !void {
        for (liveness.refs.items, 0..) |ref, index| {
            const instruction = liveness.getInstruction(ref).*;
            if (!memory_effect.isSafeToDelete(instruction)) try liveness.mark(index);
        }

        for (liveness.function.blocks.items) |block| {
            if (block.terminator) |terminator| try liveness.markTerminatorOperands(terminator);
        }
    }

    fn propagate(liveness: *LiveInstructions) !void {
        while (liveness.worklist.pop()) |index| {
            try liveness.markInstructionOperands(liveness.getInstruction(liveness.refs.items[index]).*);
        }
    }

    fn mark(liveness: *LiveInstructions, index: usize) !void {
        if (liveness.live[index]) return;
        liveness.live[index] = true;
        try liveness.worklist.append(liveness.allocator, index);
    }

    fn markValue(liveness: *LiveInstructions, value: ir.Value) !void {
        switch (value) {
            .int, .undef => {},
            .named => |name| if (liveness.defs.get(name)) |index| try liveness.mark(index),
        }
    }

    fn markInstructionOperands(liveness: *LiveInstructions, instruction: ir.Instruction) !void {
        switch (instruction.kind) {
            .binary => |binary| {
                try liveness.markValue(binary.lhs);
                try liveness.markValue(binary.rhs);
            },
            .cast => |cast| try liveness.markValue(cast.value),
            .freeze => |freeze| try liveness.markValue(freeze.value),
            .icmp => |icmp| {
                try liveness.markValue(icmp.lhs);
                try liveness.markValue(icmp.rhs);
            },
            .select => |select| {
                try liveness.markValue(select.cond);
                try liveness.markValue(select.true_value);
                try liveness.markValue(select.false_value);
            },
            .phi => |phi| for (phi.incoming.items) |incoming| {
                try liveness.markValue(incoming.value);
            },
            .alloca => {},
            .load => |load| try liveness.markValue(load.ptr),
            .store => |store| {
                try liveness.markValue(store.value);
                try liveness.markValue(store.ptr);
            },
            .gep => |gep| {
                try liveness.markValue(gep.ptr);
                for (gep.indices.items) |index| try liveness.markValue(index.value);
            },
            .call => |call| for (call.args.items) |arg| {
                try liveness.markValue(arg.value);
            },
        }
    }

    fn markTerminatorOperands(liveness: *LiveInstructions, terminator: ir.Terminator) !void {
        switch (terminator) {
            .ret => |ret| if (ret.value) |value| try liveness.markValue(value),
            .br => {},
            .@"unreachable" => {},
            .condbr => |condbr| try liveness.markValue(condbr.cond),
        }
    }

    fn getInstruction(liveness: LiveInstructions, ref: InstRef) *ir.Instruction {
        return &liveness.function.blocks.items[ref.block_index].instructions.items[ref.instruction_index];
    }
};

fn removeDeadInstructions(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    var liveness = try LiveInstructions.build(allocator, function);
    defer liveness.deinit();

    try liveness.markSeeds();
    try liveness.propagate();

    var changed = false;
    for (liveness.refs.items, 0..) |ref, index| {
        if (liveness.live[index]) continue;
        const instruction = liveness.getInstruction(ref);
        if (!memory_effect.isSafeToDelete(instruction.*)) continue;
        instruction.removed = true;
        changed = true;
    }

    return changed;
}

fn removeDeadControlFlow(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    if (function.blocks.items.len == 0) return false;

    var graph = try cfg.Graph.build(allocator, function.*);
    defer graph.deinit();

    var postdom = try postdominator.PostDominators.build(allocator, function.*);
    defer postdom.deinit();

    var changed = false;
    for (function.blocks.items, 0..) |*block, block_index| {
        const condbr = switch (block.terminator orelse continue) {
            .condbr => |condbr| condbr,
            .ret, .br, .@"unreachable" => continue,
        };

        const ipdom_index = postdom.immediatePostDominator(block_index) orelse continue;
        if (hasPhi(function.blocks.items[ipdom_index])) continue;

        const then_index = function.blockIndex(condbr.then_target) orelse continue;
        const else_index = function.blockIndex(condbr.else_target) orelse continue;

        const then_safe = regionIsLinearAndDead(function.*, graph, then_index, ipdom_index);
        const else_safe = regionIsLinearAndDead(function.*, graph, else_index, ipdom_index);
        if (!then_safe or !else_safe) continue;

        const target = if (then_index == ipdom_index)
            condbr.then_target
        else if (else_index == ipdom_index)
            condbr.else_target
        else
            condbr.then_target;

        block.terminator = .{ .br = .{ .target = target } };
        changed = true;
    }

    return changed;
}

fn regionIsLinearAndDead(function: ir.Function, graph: cfg.Graph, start_index: usize, join_index: usize) bool {
    if (start_index == join_index) return true;

    var current = start_index;
    var steps: usize = 0;
    while (current != join_index) {
        if (steps >= function.blocks.items.len) return false;
        steps += 1;

        const block = function.blocks.items[current];
        if (hasPhi(block)) return false;
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (!memory_effect.isSafeToDelete(instruction)) return false;
        }

        const terminator = block.terminator orelse return false;
        const successor_name = switch (terminator) {
            .br => |br| br.target,
            .ret, .condbr, .@"unreachable" => return false,
        };
        const successor_index = function.blockIndex(successor_name) orelse return false;
        if (!containsIndex(graph.successors(current), successor_index)) return false;
        current = successor_index;
    }

    return true;
}

fn hasPhi(block: ir.BasicBlock) bool {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        if (instruction.kind == .phi) return true;
    }
    return false;
}

fn containsIndex(values: []const usize, needle: usize) bool {
    for (values) |value| {
        if (value == needle) return true;
    }
    return false;
}
