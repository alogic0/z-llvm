const std = @import("std");
const cfg = @import("../analysis/cfg.zig");
const loop_info = @import("../analysis/loop_info.zig");
const memory_effect = @import("../analysis/memory_effect.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "licm",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        changed = try hoistFunction(module.allocator, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn hoistFunction(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    var graph = try cfg.Graph.build(allocator, function.*);
    defer graph.deinit();

    var loops = try loop_info.LoopInfo.build(allocator, function.*);
    defer loops.deinit();

    var def_blocks = std.StringHashMap(usize).init(allocator);
    defer def_blocks.deinit();
    try collectDefinitionBlocks(&def_blocks, function.*);

    var changed = false;
    for (loops.loops.items) |natural_loop| {
        if (!hasUniqueLoopHeader(loops, natural_loop.header)) continue;
        const preheader = natural_loop.preheader(function.*, graph) orelse continue;
        var local_changed = true;
        while (local_changed) {
            local_changed = false;
            for (natural_loop.blocks.items) |block_index| {
                if (block_index >= function.blocks.items.len) continue;
                var instruction_index: usize = 0;
                while (instruction_index < function.blocks.items[block_index].instructions.items.len) {
                    const instruction = function.blocks.items[block_index].instructions.items[instruction_index];
                    if (!isHoistable(instruction) or !isLoopInvariant(instruction, natural_loop, def_blocks)) {
                        instruction_index += 1;
                        continue;
                    }

                    const moved = function.blocks.items[block_index].instructions.orderedRemove(instruction_index);
                    try function.blocks.items[preheader].instructions.append(allocator, moved);
                    if (moved.result) |result| try def_blocks.put(result, preheader);
                    changed = true;
                    local_changed = true;
                }
            }
        }
    }
    return changed;
}

fn hasUniqueLoopHeader(loops: loop_info.LoopInfo, header: usize) bool {
    var count: usize = 0;
    for (loops.loops.items) |natural_loop| {
        if (natural_loop.header != header) continue;
        count += 1;
        if (count > 1) return false;
    }
    return count == 1;
}

fn collectDefinitionBlocks(def_blocks: *std.StringHashMap(usize), function: ir.Function) !void {
    for (function.params.items) |param| try def_blocks.put(param.name, std.math.maxInt(usize));
    for (function.blocks.items, 0..) |block, block_index| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.result) |result| try def_blocks.put(result, block_index);
        }
    }
}

fn isHoistable(instruction: ir.Instruction) bool {
    if (instruction.removed or memory_effect.classify(instruction) != .none) return false;
    if (instruction.result == null) return false;
    return switch (instruction.kind) {
        .binary, .cast, .icmp, .select => true,
        .freeze, .phi, .alloca, .load, .store, .gep => false,
    };
}

fn isLoopInvariant(instruction: ir.Instruction, natural_loop: loop_info.NaturalLoop, def_blocks: std.StringHashMap(usize)) bool {
    return switch (instruction.kind) {
        .binary => |binary| isInvariantValue(binary.lhs, natural_loop, def_blocks) and
            isInvariantValue(binary.rhs, natural_loop, def_blocks),
        .cast => |cast| isInvariantValue(cast.value, natural_loop, def_blocks),
        .icmp => |icmp| isInvariantValue(icmp.lhs, natural_loop, def_blocks) and
            isInvariantValue(icmp.rhs, natural_loop, def_blocks),
        .select => |select| isInvariantValue(select.cond, natural_loop, def_blocks) and
            isInvariantValue(select.true_value, natural_loop, def_blocks) and
            isInvariantValue(select.false_value, natural_loop, def_blocks),
        .freeze, .phi, .alloca, .load, .store, .gep => false,
    };
}

fn isInvariantValue(value: ir.Value, natural_loop: loop_info.NaturalLoop, def_blocks: std.StringHashMap(usize)) bool {
    return switch (value) {
        .int, .undef => true,
        .named => |name| {
            const block = def_blocks.get(name) orelse return false;
            if (block == std.math.maxInt(usize)) return true;
            return !natural_loop.contains(block);
        },
    };
}
