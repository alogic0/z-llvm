const std = @import("std");
const block_addresses = @import("../analysis/block_addresses.zig");
const cfg = @import("../analysis/cfg.zig");
const cfg_update = @import("../analysis/cfg_update.zig");
const def_use = @import("../analysis/def_use.zig");
const loop_info = @import("../analysis/loop_info.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "loop-deletion",
    .category = .loop,
    .target_status = "LLVM-shaped algorithm subset",
    .upstream_owner = "llvm/lib/Transforms/Scalar/LoopDeletion.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var address_guard = try block_addresses.Guard.build(module.allocator, module.*);
    defer address_guard.deinit();
    var changed = false;
    for (module.functions.items) |*function| {
        if (address_guard.contains(function.name)) continue;
        changed = try deleteFunctionLoops(module.*, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn deleteFunctionLoops(module: ir.Module, function: *ir.Function) !bool {
    const allocator = module.allocator;
    if (!functionHasMustProgress(module, function.*)) return false;

    var changed = false;
    var local_changed = true;
    while (local_changed) {
        local_changed = false;
        var loops = try loop_info.LoopInfo.build(allocator, function.*);
        defer loops.deinit();
        var graph = try cfg.Graph.build(allocator, function.*);
        defer graph.deinit();

        for (loops.loops.items) |natural_loop| {
            if (try deleteLoop(allocator, function, graph, natural_loop)) {
                changed = true;
                local_changed = true;
                break;
            }
        }
    }
    return changed;
}

fn deleteLoop(allocator: std.mem.Allocator, function: *ir.Function, graph: cfg.Graph, natural_loop: loop_info.NaturalLoop) !bool {
    if (!natural_loop.isSideEffectFreeDeletionCandidate(function.*)) return false;
    if (!hasSimpleFiniteExit(function.*, natural_loop)) return false;
    if (try hasOutsideUses(allocator, function.*, natural_loop)) return false;

    const preheader_index = natural_loop.preheader(function.*, graph) orelse return false;
    var exits = try natural_loop.exitBlocks(allocator, graph);
    defer exits.deinit(allocator);
    if (exits.items.len != 1) return false;
    if (!try natural_loop.hasDedicatedExits(allocator, graph)) return false;

    function.blocks.items[preheader_index].terminator = .{ .br = .{ .target = function.blocks.items[exits.items[0]].name } };
    _ = try cfg_update.prunePhiIncomingToPredecessors(allocator, function);
    _ = try cfg_update.removeUnreachableBlocks(allocator, function);
    return true;
}

fn functionHasMustProgress(module: ir.Module, function: ir.Function) bool {
    const attrs = function.attrs orelse return false;
    if (std.mem.indexOf(u8, attrs, "mustprogress") != null) return true;
    var it = std.mem.tokenizeAny(u8, attrs, " \t,");
    while (it.next()) |token| {
        if (!std.mem.startsWith(u8, token, "#")) continue;
        const group_text = findAttributeGroup(module, token[1..]) orelse continue;
        if (std.mem.indexOf(u8, group_text, "mustprogress") != null) return true;
    }
    return false;
}

fn findAttributeGroup(module: ir.Module, group_id: []const u8) ?[]const u8 {
    for (module.attribute_groups.items) |group| {
        var rest = std.mem.trim(u8, group["attributes ".len..], " \t");
        if (!std.mem.startsWith(u8, rest, "#")) continue;
        rest = rest[1..];
        const id_end = std.mem.indexOfAny(u8, rest, " \t") orelse continue;
        if (std.mem.eql(u8, rest[0..id_end], group_id)) return group;
    }
    return null;
}

fn hasSimpleFiniteExit(function: ir.Function, natural_loop: loop_info.NaturalLoop) bool {
    if (natural_loop.header >= function.blocks.items.len) return false;
    const header = function.blocks.items[natural_loop.header];
    if (header.instructions.items.len < 2) return false;
    const phi_name = header.instructions.items[0].result orelse return false;
    if (header.instructions.items[0].kind != .phi) return false;
    const cond_name = header.instructions.items[1].result orelse return false;
    const cond = switch (header.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        .binary, .cast, .freeze, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return false,
    };
    if (!usesValue(cond.lhs, phi_name) and !usesValue(cond.rhs, phi_name)) return false;
    if (cond.lhs != .int and cond.rhs != .int) return false;
    const terminator = switch (header.terminator orelse return false) {
        .condbr => |condbr| condbr,
        .ret, .br, .@"switch", .indirectbr, .@"unreachable" => return false,
    };
    return terminator.cond.eql(.{ .named = cond_name });
}

fn hasOutsideUses(allocator: std.mem.Allocator, function: ir.Function, natural_loop: loop_info.NaturalLoop) !bool {
    var loop_defs = std.StringHashMap(void).init(allocator);
    defer loop_defs.deinit();
    for (natural_loop.blocks.items) |block_index| {
        for (function.blocks.items[block_index].instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.result) |result| try loop_defs.put(result, {});
        }
    }

    var outside_uses = def_use.UseCounts.init(allocator);
    defer outside_uses.deinit();
    for (function.blocks.items, 0..) |block, block_index| {
        if (natural_loop.contains(block_index)) continue;
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            try outside_uses.addInstructionOperands(instruction);
        }
        if (block.terminator) |terminator| try outside_uses.addTerminator(terminator);
    }

    var it = loop_defs.keyIterator();
    while (it.next()) |name| {
        if (outside_uses.isUsed(name.*)) return true;
    }
    return false;
}

fn usesValue(value: ir.Value, name: []const u8) bool {
    return value == .named and std.mem.eql(u8, value.named, name);
}
