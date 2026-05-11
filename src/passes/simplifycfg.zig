const std = @import("std");
const cfg = @import("../analysis/cfg.zig");
const cfg_update = @import("../analysis/cfg_update.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "simplifycfg",
    .category = .canonicalization,
    .target_status = "fixture-equivalent for listed fixtures",
    .upstream_owner = "llvm/lib/Transforms/Scalar/SimplifyCFGPass.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        changed = simplifyTerminators(function) or changed;
        changed = try threadEmptyBranchBlocks(module.allocator, function) or changed;
        changed = simplifyTerminators(function) or changed;
        changed = try cfg_update.prunePhiIncomingToPredecessors(module.allocator, function) or changed;
        changed = try cfg_update.removeUnreachableBlocks(module.allocator, function) or changed;
        changed = try mergeTrivialBranchBlocks(module.allocator, function) or changed;
        changed = try cfg_update.prunePhiIncomingToPredecessors(module.allocator, function) or changed;
        changed = simplifyTrivialPhis(function) or changed;
        changed = try mergeTrivialBranchBlocks(module.allocator, function) or changed;
        changed = try cfg_update.prunePhiIncomingToPredecessors(module.allocator, function) or changed;
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
                } else if (commonReturn(function.*, condbr)) |ret| {
                    block.terminator = .{ .ret = .{ .ty = ret.ty, .value = ret.value } };
                    changed = true;
                } else if (condbr.cond == .int) {
                    block.terminator = .{ .br = .{
                        .target = if (condbr.cond.int == 0) condbr.else_target else condbr.then_target,
                    } };
                    changed = true;
                }
            },
            .ret => {},
            .br => {},
            .@"unreachable" => {},
        }
    }
    return changed;
}

const RetInfo = struct {
    ty: ir.Type,
    value: ?ir.Value,
};

fn commonReturn(function: ir.Function, condbr: anytype) ?RetInfo {
    const then_block = retOnlyBlock(function, condbr.then_target) orelse return null;
    const else_block = retOnlyBlock(function, condbr.else_target) orelse return null;
    if (!then_block.ty.eql(else_block.ty)) return null;
    if (then_block.value) |then_value| {
        const else_value = else_block.value orelse return null;
        if (!then_value.eql(else_value)) return null;
    } else if (else_block.value != null) {
        return null;
    }
    return then_block;
}

fn retOnlyBlock(function: ir.Function, name: []const u8) ?RetInfo {
    const block_index = function.blockIndex(name) orelse return null;
    const block = function.blocks.items[block_index];
    if (block.instructions.items.len != 0) return null;
    return switch (block.terminator orelse return null) {
        .ret => |ret| .{ .ty = ret.ty, .value = ret.value },
        .br, .condbr, .@"unreachable" => null,
    };
}

fn threadEmptyBranchBlocks(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    var changed = false;
    var local_changed = true;
    while (local_changed) {
        local_changed = false;
        var graph = try cfg.Graph.build(allocator, function.*);
        defer graph.deinit();

        for (function.blocks.items, 0..) |block, block_index| {
            if (block_index == 0) continue;
            if (block.instructions.items.len != 0) continue;
            const br = switch (block.terminator orelse continue) {
                .br => |br| br,
                .ret, .condbr, .@"unreachable" => continue,
            };
            const target_index = function.blockIndex(br.target) orelse continue;
            if (target_index == block_index) continue;
            if (hasPhi(function.blocks.items[target_index])) continue;
            if (graph.predecessors(block_index).len == 0) continue;

            _ = cfg_update.retargetBranches(function, block.name, br.target);
            changed = true;
            local_changed = true;
            break;
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
                .ret => continue,
                .condbr => continue,
                .@"unreachable" => continue,
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
            _ = cfg_update.replacePhiIncomingBlock(function, target.name, block.name);

            var removed = function.blocks.orderedRemove(target_index);
            removed.deinit(allocator);
            changed = true;
            local_changed = true;
            break;
        }
    }
    return changed;
}

fn hasPhi(block: ir.BasicBlock) bool {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        if (instruction.kind == .phi) return true;
    }
    return false;
}

fn simplifyTrivialPhis(function: *ir.Function) bool {
    var changed = false;
    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*instruction| {
            if (instruction.removed) continue;
            const replacement = switch (instruction.kind) {
                .phi => |phi| trivialPhiReplacement(phi),
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .gep, .call => null,
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
                .cast => |*cast| cast.value = replaceOperand(cast.value, name, replacement),
                .freeze => |*freeze| freeze.value = replaceOperand(freeze.value, name, replacement),
                .icmp => |*icmp| {
                    icmp.lhs = replaceOperand(icmp.lhs, name, replacement);
                    icmp.rhs = replaceOperand(icmp.rhs, name, replacement);
                },
                .fcmp => |*fcmp| {
                    fcmp.lhs = replaceOperand(fcmp.lhs, name, replacement);
                    fcmp.rhs = replaceOperand(fcmp.rhs, name, replacement);
                },
                .select => |*select| {
                    select.cond = replaceOperand(select.cond, name, replacement);
                    select.true_value = replaceOperand(select.true_value, name, replacement);
                    select.false_value = replaceOperand(select.false_value, name, replacement);
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
                .gep => |*gep| {
                    gep.ptr = replaceOperand(gep.ptr, name, replacement);
                    for (gep.indices.items) |*index| {
                        index.value = replaceOperand(index.value, name, replacement);
                    }
                },
                .call => |*call| for (call.args.items) |*arg| {
                    arg.value = replaceOperand(arg.value, name, replacement);
                },
            }
        }
        if (block.terminator) |*terminator| switch (terminator.*) {
            .ret => |*ret| {
                if (ret.value) |value| ret.value = replaceOperand(value, name, replacement);
            },
            .br => {},
            .@"unreachable" => {},
            .condbr => |*condbr| condbr.cond = replaceOperand(condbr.cond, name, replacement),
        };
    }
}

fn replaceOperand(value: ir.Value, name: []const u8, replacement: ir.Value) ir.Value {
    return switch (value) {
        .int, .undef, .null_value => value,
        .named => |value_name| if (std.mem.eql(u8, value_name, name)) replacement else value,
    };
}
