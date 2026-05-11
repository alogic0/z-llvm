const std = @import("std");
const loop_info = @import("../analysis/loop_info.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");
const inst_simplify = @import("inst_simplify.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "loop-instsimplify",
    .category = .loop,
    .target_status = "LLVM-shaped algorithm subset",
    .upstream_owner = "llvm/lib/Transforms/Scalar/LoopInstSimplify.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        changed = try simplifyFunction(module.allocator, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn simplifyFunction(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    var loops = try loop_info.LoopInfo.build(allocator, function.*);
    defer loops.deinit();
    if (loops.loops.items.len == 0) return false;

    var loop_blocks = std.AutoHashMap(usize, void).init(allocator);
    defer loop_blocks.deinit();
    for (loops.loops.items) |natural_loop| {
        for (natural_loop.blocks.items) |block_index| try loop_blocks.put(block_index, {});
    }

    var aliases = std.StringHashMap(ir.Value).init(allocator);
    defer aliases.deinit();

    var changed = false;
    for (function.blocks.items, 0..) |*block, block_index| {
        const in_loop = loop_blocks.contains(block_index);
        for (block.instructions.items) |*instruction| {
            if (instruction.removed) continue;
            instruction.mapOperands(aliases);
            if (!in_loop) continue;
            if (inst_simplify.simplify(instruction.*)) |replacement| {
                const result = instruction.result orelse continue;
                instruction.removed = true;
                instruction.replacement = replacement;
                try aliases.put(result, replacement);
                changed = true;
            }
        }
        if (block.terminator) |*terminator| switch (terminator.*) {
            .ret => |*ret| {
                if (ret.value) |value| ret.value = resolveValue(aliases, value);
            },
            .br, .@"unreachable" => {},
            .condbr => |*condbr| condbr.cond = resolveValue(aliases, condbr.cond),
        };
    }
    return changed;
}

fn resolveValue(aliases: std.StringHashMap(ir.Value), value: ir.Value) ir.Value {
    return switch (value) {
        .int, .fp, .undef, .null_value, .zero_initializer, .vector => value,
        .named => |name| aliases.get(name) orelse value,
    };
}
