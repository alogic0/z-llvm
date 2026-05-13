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
        changed = try foldSimpleDiamondSelectReturns(module, function) or changed;
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
                    if (!canCollapseDuplicatePhiIncoming(function.*, condbr.then_target, block.name)) continue;
                    _ = collapseDuplicatePhiIncoming(function, condbr.then_target, block.name);
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
            .@"switch" => {},
            .indirectbr => {},
            .@"unreachable" => {},
        }
    }
    return changed;
}

fn canCollapseDuplicatePhiIncoming(function: ir.Function, target_name: []const u8, predecessor_name: []const u8) bool {
    const target_index = function.blockIndex(target_name) orelse return false;
    const target = function.blocks.items[target_index];
    for (target.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const phi = switch (instruction.kind) {
            .phi => |phi| phi,
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => continue,
        };

        var value: ?ir.Value = null;
        for (phi.incoming.items) |incoming| {
            if (!std.mem.eql(u8, incoming.block, predecessor_name)) continue;
            if (value) |existing| {
                if (!existing.eql(incoming.value)) return false;
            } else {
                value = incoming.value;
            }
        }
    }
    return true;
}

fn collapseDuplicatePhiIncoming(function: *ir.Function, target_name: []const u8, predecessor_name: []const u8) bool {
    const target_index = function.blockIndex(target_name) orelse return false;
    var changed = false;
    for (function.blocks.items[target_index].instructions.items) |*instruction| {
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .phi => |*phi| {
                var saw_incoming = false;
                var index: usize = 0;
                while (index < phi.incoming.items.len) {
                    if (!std.mem.eql(u8, phi.incoming.items[index].block, predecessor_name)) {
                        index += 1;
                        continue;
                    }
                    if (!saw_incoming) {
                        saw_incoming = true;
                        index += 1;
                        continue;
                    }
                    _ = phi.incoming.orderedRemove(index);
                    changed = true;
                }
            },
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => {},
        }
    }
    return changed;
}

fn foldSimpleDiamondSelectReturns(module: *ir.Module, function: *ir.Function) !bool {
    const allocator = module.allocator;
    var changed = false;
    var local_changed = true;
    while (local_changed) {
        local_changed = false;
        var graph = try cfg.Graph.build(allocator, function.*);
        defer graph.deinit();

        for (function.blocks.items, 0..) |*block, block_index| {
            const condbr = switch (block.terminator orelse continue) {
                .condbr => |condbr| condbr,
                .ret, .br, .@"switch", .indirectbr, .@"unreachable" => continue,
            };
            const shape = simpleDiamondSelectReturn(function.*, graph, block_index, condbr) orelse continue;

            const select_name_text = try diamondSelectName(allocator, shape);
            const select_name = try module.ownString(select_name_text);
            try block.instructions.append(allocator, .{
                .result = select_name,
                .kind = .{ .select = .{
                    .cond_ty = .{ .int = 1 },
                    .cond = condbr.cond,
                    .ty = shape.ty,
                    .true_value = shape.true_value,
                    .false_value = shape.false_value,
                } },
            });
            block.terminator = .{ .ret = .{
                .ty = shape.ty,
                .value = .{ .named = select_name },
            } };

            removeBlocksDescending(allocator, function, &.{ shape.merge_index, shape.else_index, shape.then_index });
            changed = true;
            local_changed = true;
            break;
        }
    }
    return changed;
}

fn diamondSelectName(allocator: std.mem.Allocator, shape: DiamondSelectReturn) ![]u8 {
    if (shape.true_value == .named and shape.false_value == .named) {
        return std.fmt.allocPrint(allocator, "{s}.{s}", .{ shape.true_value.named, shape.false_value.named });
    }
    return std.fmt.allocPrint(allocator, "{s}.select", .{shape.phi_name});
}

const DiamondSelectReturn = struct {
    then_index: usize,
    else_index: usize,
    merge_index: usize,
    phi_name: []const u8,
    ty: ir.Type,
    true_value: ir.Value,
    false_value: ir.Value,
};

fn simpleDiamondSelectReturn(function: ir.Function, graph: cfg.Graph, block_index: usize, condbr: anytype) ?DiamondSelectReturn {
    const then_index = function.blockIndex(condbr.then_target) orelse return null;
    const else_index = function.blockIndex(condbr.else_target) orelse return null;
    if (then_index == else_index or then_index == block_index or else_index == block_index) return null;
    if (graph.predecessors(then_index).len != 1 or graph.predecessors(else_index).len != 1) return null;

    const then_target = emptyBranchTarget(function.blocks.items[then_index]) orelse return null;
    const else_target = emptyBranchTarget(function.blocks.items[else_index]) orelse return null;
    if (!std.mem.eql(u8, then_target, else_target)) return null;

    const merge_index = function.blockIndex(then_target) orelse return null;
    if (merge_index == block_index or merge_index == then_index or merge_index == else_index) return null;
    const merge_preds = graph.predecessors(merge_index);
    if (merge_preds.len != 2) return null;
    if (!containsIndex(merge_preds, then_index) or !containsIndex(merge_preds, else_index)) return null;

    const merge = function.blocks.items[merge_index];
    if (merge.instructions.items.len != 1) return null;
    const phi_inst = merge.instructions.items[0];
    if (phi_inst.removed or phi_inst.kind != .phi) return null;
    const phi_name = phi_inst.result orelse return null;
    const phi = phi_inst.kind.phi;
    if (phi.incoming.items.len != 2) return null;

    const true_value = phiValueForBlock(phi, condbr.then_target) orelse return null;
    const false_value = phiValueForBlock(phi, condbr.else_target) orelse return null;
    const ret = switch (merge.terminator orelse return null) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return null,
    };
    const ret_value = ret.value orelse return null;
    if (!ret.ty.eql(phi.ty) or !ret_value.eql(.{ .named = phi_name })) return null;

    return .{
        .then_index = then_index,
        .else_index = else_index,
        .merge_index = merge_index,
        .phi_name = phi_name,
        .ty = phi.ty,
        .true_value = true_value,
        .false_value = false_value,
    };
}

fn emptyBranchTarget(block: ir.BasicBlock) ?[]const u8 {
    if (block.instructions.items.len != 0) return null;
    return switch (block.terminator orelse return null) {
        .br => |br| br.target,
        .ret, .condbr, .@"switch", .indirectbr, .@"unreachable" => null,
    };
}

fn phiValueForBlock(phi: ir.PhiInst, block_name: []const u8) ?ir.Value {
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, block_name)) return incoming.value;
    }
    return null;
}

fn containsIndex(indices: []const usize, needle: usize) bool {
    for (indices) |index| {
        if (index == needle) return true;
    }
    return false;
}

fn removeBlocksDescending(allocator: std.mem.Allocator, function: *ir.Function, indices: []const usize) void {
    var sorted = [_]usize{ 0, 0, 0 };
    for (indices, 0..) |index, i| sorted[i] = index;
    std.sort.heap(usize, &sorted, {}, comptime std.sort.desc(usize));
    var last: ?usize = null;
    for (sorted) |index| {
        if (last) |last_index| {
            if (last_index == index) continue;
        }
        last = index;
        var removed = function.blocks.orderedRemove(index);
        removed.deinit(allocator);
    }
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
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => null,
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
                .ret, .condbr, .@"switch", .indirectbr, .@"unreachable" => continue,
            };
            const target_index = function.blockIndex(br.target) orelse continue;
            if (target_index == block_index) continue;
            const predecessors = graph.predecessors(block_index);
            if (predecessors.len == 0) continue;
            if (hasPhi(function.blocks.items[target_index])) {
                if (predecessors.len != 1) continue;
                if (terminatorTargetEdgeCount(function.blocks.items[predecessors[0]].terminator, block.name) != 1) continue;
                _ = cfg_update.replacePhiIncomingBlock(function, block.name, function.blocks.items[predecessors[0]].name);
            }

            _ = cfg_update.retargetBranches(function, block.name, br.target);
            changed = true;
            local_changed = true;
            break;
        }
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
            for (indirectbr.targets.items) |target_name_candidate| {
                if (std.mem.eql(u8, target_name_candidate, target_name)) count += 1;
            }
        },
    }
    return count;
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
                .@"switch" => continue,
                .indirectbr => continue,
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
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => null,
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
                .atomicrmw => |*atomicrmw| {
                    atomicrmw.ptr = replaceOperand(atomicrmw.ptr, name, replacement);
                    atomicrmw.value = replaceOperand(atomicrmw.value, name, replacement);
                },
                .cmpxchg => |*cmpxchg| {
                    cmpxchg.ptr = replaceOperand(cmpxchg.ptr, name, replacement);
                    cmpxchg.expected = replaceOperand(cmpxchg.expected, name, replacement);
                    cmpxchg.replacement = replaceOperand(cmpxchg.replacement, name, replacement);
                },
                .fence, .extractelement, .insertelement, .shufflevector => {},
                .extractvalue => |*extract| extract.aggregate = replaceOperand(extract.aggregate, name, replacement),
                .insertvalue => |*insert| {
                    insert.aggregate = replaceOperand(insert.aggregate, name, replacement);
                    insert.value = replaceOperand(insert.value, name, replacement);
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
            .indirectbr => |*indirectbr| indirectbr.addr = replaceOperand(indirectbr.addr, name, replacement),
            .@"switch" => |*switch_term| {
                switch_term.cond = replaceOperand(switch_term.cond, name, replacement);
                for (switch_term.cases.items) |*case| {
                    case.value = replaceOperand(case.value, name, replacement);
                }
            },
        };
    }
}

fn replaceOperand(value: ir.Value, name: []const u8, replacement: ir.Value) ir.Value {
    return switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => value,
        .named => |value_name| if (std.mem.eql(u8, value_name, name)) replacement else value,
    };
}
