const std = @import("std");
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
        changed = simplifyTrivialPhis(function) or changed;
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

fn removeUnreachableBlocks(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    if (function.blocks.items.len == 0) return false;

    var reachable = std.StringHashMap(void).init(allocator);
    defer reachable.deinit();

    var worklist: std.ArrayList([]const u8) = .empty;
    defer worklist.deinit(allocator);

    try markReachable(&reachable, &worklist, function.blocks.items[0].name);

    while (worklist.pop()) |block_name| {
        const block_index = function.blockIndex(block_name) orelse continue;
        const block = function.blocks.items[block_index];
        const terminator = block.terminator orelse continue;
        switch (terminator) {
            .ret => {},
            .br => |br| try markReachable(&reachable, &worklist, br.target),
            .condbr => |condbr| {
                try markReachable(&reachable, &worklist, condbr.then_target);
                try markReachable(&reachable, &worklist, condbr.else_target);
            },
        }
    }

    var changed = false;
    changed = prunePhiIncoming(function, reachable) or changed;

    var index = function.blocks.items.len;
    while (index > 0) {
        index -= 1;
        if (reachable.contains(function.blocks.items[index].name)) continue;

        var removed = function.blocks.orderedRemove(index);
        removed.deinit(allocator);
        changed = true;
    }
    return changed;
}

fn prunePhiIncoming(function: *ir.Function, reachable: std.StringHashMap(void)) bool {
    var changed = false;
    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .phi => |*phi| {
                    var index = phi.incoming.items.len;
                    while (index > 0) {
                        index -= 1;
                        if (reachable.contains(phi.incoming.items[index].block)) continue;
                        _ = phi.incoming.orderedRemove(index);
                        changed = true;
                    }
                },
                .binary, .icmp => {},
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
                .binary, .icmp => null,
            } orelse continue;

            replaceValue(function, instruction.result, replacement);
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

fn markReachable(reachable: *std.StringHashMap(void), worklist: *std.ArrayList([]const u8), block_name: []const u8) !void {
    const gop = try reachable.getOrPut(block_name);
    if (gop.found_existing) return;
    try worklist.append(reachable.allocator, block_name);
}
