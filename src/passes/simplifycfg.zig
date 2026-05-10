const std = @import("std");
const cfg = @import("../analysis/cfg.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "simplifycfg",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        changed = simplifyTerminators(function) or changed;
        changed = try removeUnreachableBlocks(module.allocator, function) or changed;
        changed = try mergeTrivialBranchBlocks(module.allocator, function) or changed;
        changed = simplifyTrivialPhis(function) or changed;
        changed = try mergeTrivialBranchBlocks(module.allocator, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn simplifyTerminators(function: *ir.Function) bool {
    var changed = false;
    for (function.blocks.items) |*block| {
        const terminator = block.terminator orelse continue;
        switch (terminator) {
            .condbr => |condbr| {
                if (std.mem.eql(u8, condbr.then_target, condbr.else_target)) {
                    block.terminator = .{ .br = .{ .target = condbr.then_target } };
                    changed = true;
                } else if (condbr.cond == .int) {
                    block.terminator = .{ .br = .{
                        .target = if (condbr.cond.int == 0) condbr.else_target else condbr.then_target,
                    } };
                    changed = true;
                }
            },
            .ret, .br => {},
        }
    }
    return changed;
}

fn mergeTrivialBranchBlocks(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    var changed = false;
    var local_changed = true;
    while (local_changed) {
        local_changed = false;
        var graph = try cfg.Graph.build(allocator, function.*);
        defer graph.deinit();

        for (function.blocks.items, 0..) |*block, block_index| {
            const br = switch (block.terminator orelse continue) {
                .br => |br| br,
                .ret, .condbr => continue,
            };
            const target_index = function.blockIndex(br.target) orelse continue;
            if (target_index == block_index) continue;
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
            replacePhiIncomingBlock(function, target.name, block.name);

            var removed = function.blocks.orderedRemove(target_index);
            removed.deinit(allocator);
            changed = true;
            local_changed = true;
            break;
        }
    }
    return changed;
}

fn replacePhiIncomingBlock(function: *ir.Function, old_name: []const u8, new_name: []const u8) void {
    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .phi => |*phi| for (phi.incoming.items) |*incoming| {
                    if (std.mem.eql(u8, incoming.block, old_name)) incoming.block = new_name;
                },
                .binary, .icmp, .alloca, .load, .store => {},
            }
        }
    }
}

fn hasPhi(block: ir.BasicBlock) bool {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        if (instruction.kind == .phi) return true;
    }
    return false;
}

fn removeUnreachableBlocks(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    if (function.blocks.items.len == 0) return false;

    var graph = try cfg.Graph.build(allocator, function.*);
    defer graph.deinit();

    const reachable = try graph.reachableFromEntry(allocator);
    defer allocator.free(reachable);

    var changed = false;
    changed = prunePhiIncoming(function, reachable) or changed;

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

fn prunePhiIncoming(function: *ir.Function, reachable: []const bool) bool {
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
                .binary, .icmp, .alloca, .load, .store => {},
            }
        }
    }
    return changed;
}

fn simplifyTrivialPhis(function: *ir.Function) bool {
    var changed = false;
    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*instruction| {
            if (instruction.removed) continue;
            const replacement = switch (instruction.kind) {
                .phi => |phi| trivialPhiReplacement(phi),
                .binary, .icmp, .alloca, .load, .store => null,
            } orelse continue;

            const result = instruction.result orelse continue;
            replaceValue(function, result, replacement);
            instruction.removed = true;
            instruction.replacement = replacement;
            changed = true;
        }
    }
    return changed;
}

fn trivialPhiReplacement(phi: ir.PhiInst) ?ir.Value {
    if (phi.incoming.items.len == 0) return null;
    const replacement = phi.incoming.items[0].value;
    for (phi.incoming.items[1..]) |incoming| {
        if (!replacement.eql(incoming.value)) return null;
    }
    return replacement;
}

fn replaceValue(function: *ir.Function, name: []const u8, replacement: ir.Value) void {
    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |*binary| {
                    binary.lhs = replaceOperand(binary.lhs, name, replacement);
                    binary.rhs = replaceOperand(binary.rhs, name, replacement);
                },
                .icmp => |*icmp| {
                    icmp.lhs = replaceOperand(icmp.lhs, name, replacement);
                    icmp.rhs = replaceOperand(icmp.rhs, name, replacement);
                },
                .phi => |*phi| for (phi.incoming.items) |*incoming| {
                    incoming.value = replaceOperand(incoming.value, name, replacement);
                },
                .alloca => {},
                .load => |*load| load.ptr = replaceOperand(load.ptr, name, replacement),
                .store => |*store| {
                    store.value = replaceOperand(store.value, name, replacement);
                    store.ptr = replaceOperand(store.ptr, name, replacement);
                },
            }
        }
        if (block.terminator) |*terminator| switch (terminator.*) {
            .ret => |*ret| ret.value = replaceOperand(ret.value, name, replacement),
            .br => {},
            .condbr => |*condbr| condbr.cond = replaceOperand(condbr.cond, name, replacement),
        };
    }
}

fn replaceOperand(value: ir.Value, name: []const u8, replacement: ir.Value) ir.Value {
    return switch (value) {
        .int => value,
        .named => |value_name| if (std.mem.eql(u8, value_name, name)) replacement else value,
    };
}
