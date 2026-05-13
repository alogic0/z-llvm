const std = @import("std");
const cfg = @import("../analysis/cfg.zig");
const loop_info = @import("../analysis/loop_info.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "loop-rotate",
    .category = .loop,
    .target_status = "LLVM-shaped algorithm subset",
    .upstream_owner = "llvm/lib/Transforms/Scalar/LoopRotation.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        changed = try rotateFunction(module, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn rotateFunction(module: *ir.Module, function: *ir.Function) !bool {
    var loops = try loop_info.LoopInfo.build(module.allocator, function.*);
    defer loops.deinit();

    var graph = try cfg.Graph.build(module.allocator, function.*);
    defer graph.deinit();

    for (loops.loops.items) |natural_loop| {
        if (try rotateLoop(module, function, graph, natural_loop)) return true;
    }
    return false;
}

const Rotation = struct {
    preheader_index: usize,
    header_index: usize,
    body_index: usize,
    latch_index: usize,
    exit_index: usize,
    phi_index: usize,
    cond_index: usize,
    latch_next_index: usize,
    phi_name: []const u8,
    next_name: []const u8,
    cond_name: []const u8,
    initial_value: ir.Value,
    exit_name: []const u8,
    cond: ir.IcmpInst,
    next: ir.BinaryInst,
};

fn rotateLoop(module: *ir.Module, function: *ir.Function, graph: cfg.Graph, natural_loop: loop_info.NaturalLoop) !bool {
    const candidate = findRotation(function.*, graph, natural_loop) orelse return false;
    const preheader_name = function.blocks.items[candidate.preheader_index].name;
    const old_header_name = function.blocks.items[candidate.header_index].name;
    const body_name = function.blocks.items[candidate.body_index].name;
    const latch_name = function.blocks.items[candidate.latch_index].name;

    const preheader_cond_name = try module.ownString(try std.fmt.allocPrint(module.allocator, "{s}1", .{candidate.cond_name}));
    const lr_ph_name = try module.ownString(try std.fmt.allocPrint(module.allocator, "{s}.lr.ph", .{body_name}));
    const rotated_phi_name = try module.ownString(try std.fmt.allocPrint(module.allocator, "{s}2", .{candidate.phi_name}));
    const split_block_name = try module.ownString(try std.fmt.allocPrint(module.allocator, "{s}.exit_crit_edge", .{old_header_name}));
    const split_phi_name = try module.ownString(try std.fmt.allocPrint(module.allocator, "split", .{}));

    var preheader_cond = candidate.cond;
    preheader_cond.lhs = replaceValue(preheader_cond.lhs, candidate.phi_name, candidate.initial_value);
    preheader_cond.rhs = replaceValue(preheader_cond.rhs, candidate.phi_name, candidate.initial_value);
    try function.blocks.items[candidate.preheader_index].instructions.append(module.allocator, .{
        .result = preheader_cond_name,
        .kind = .{ .icmp = preheader_cond },
    });
    function.blocks.items[candidate.preheader_index].terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = preheader_cond_name },
        .then_target = lr_ph_name,
        .else_target = candidate.exit_name,
    } };

    var header = &function.blocks.items[candidate.header_index];
    for (header.instructions.items) |*instruction| instruction.deinit(module.allocator);
    header.instructions.clearRetainingCapacity();
    header.name = lr_ph_name;
    header.terminator = .{ .br = .{ .target = body_name } };

    var body_phi_incoming: std.ArrayList(ir.PhiIncoming) = .empty;
    try body_phi_incoming.append(module.allocator, .{ .value = candidate.initial_value, .block = lr_ph_name });
    try body_phi_incoming.append(module.allocator, .{ .value = .{ .named = candidate.next_name }, .block = latch_name });
    try function.blocks.items[candidate.body_index].instructions.insert(module.allocator, 0, .{
        .result = rotated_phi_name,
        .kind = .{ .phi = .{
            .ty = candidate.next.ty,
            .incoming = body_phi_incoming,
        } },
    });

    var latch = &function.blocks.items[candidate.latch_index];
    latch.instructions.items[candidate.latch_next_index].kind.binary.lhs = replaceValue(latch.instructions.items[candidate.latch_next_index].kind.binary.lhs, candidate.phi_name, .{ .named = rotated_phi_name });
    latch.instructions.items[candidate.latch_next_index].kind.binary.rhs = replaceValue(latch.instructions.items[candidate.latch_next_index].kind.binary.rhs, candidate.phi_name, .{ .named = rotated_phi_name });
    var latch_cond = candidate.cond;
    latch_cond.lhs = replaceValue(latch_cond.lhs, candidate.phi_name, .{ .named = candidate.next_name });
    latch_cond.rhs = replaceValue(latch_cond.rhs, candidate.phi_name, .{ .named = candidate.next_name });
    try latch.instructions.append(module.allocator, .{
        .result = candidate.cond_name,
        .kind = .{ .icmp = latch_cond },
    });
    latch.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .named = candidate.cond_name },
        .then_target = body_name,
        .else_target = split_block_name,
    } };

    var split_incoming: std.ArrayList(ir.PhiIncoming) = .empty;
    try split_incoming.append(module.allocator, .{ .value = .{ .named = candidate.next_name }, .block = latch_name });
    var split_block = ir.BasicBlock.init(split_block_name);
    errdefer split_block.deinit(module.allocator);
    try split_block.instructions.append(module.allocator, .{
        .result = split_phi_name,
        .kind = .{ .phi = .{
            .ty = candidate.next.ty,
            .incoming = split_incoming,
        } },
    });
    split_block.terminator = .{ .br = .{ .target = candidate.exit_name } };
    try function.blocks.insert(module.allocator, candidate.exit_index, split_block);

    try rewriteExitPhis(module.allocator, &function.blocks.items[candidate.exit_index + 1], old_header_name, split_block_name, preheader_name, candidate.phi_name, split_phi_name, candidate.initial_value);
    return true;
}

fn findRotation(function: ir.Function, graph: cfg.Graph, natural_loop: loop_info.NaturalLoop) ?Rotation {
    const preheader_index = natural_loop.preheader(function, graph) orelse return null;
    if (natural_loop.header == natural_loop.latch) return null;
    if (graph.predecessors(natural_loop.header).len != 2) return null;

    const header = function.blocks.items[natural_loop.header];
    if (header.instructions.items.len != 2) return null;
    const phi_inst = header.instructions.items[0];
    const phi_name = phi_inst.result orelse return null;
    const phi = switch (phi_inst.kind) {
        .phi => |phi| phi,
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return null,
    };
    if (phi.incoming.items.len != 2) return null;
    const initial_value = phiIncomingForBlock(phi, function.blocks.items[preheader_index].name) orelse return null;

    const cond_inst = header.instructions.items[1];
    const cond_name = cond_inst.result orelse return null;
    const cond = switch (cond_inst.kind) {
        .icmp => |icmp| icmp,
        .binary, .cast, .freeze, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return null,
    };
    const condbr = switch (header.terminator orelse return null) {
        .condbr => |condbr| condbr,
        .ret, .br, .@"switch", .indirectbr, .@"unreachable" => return null,
    };
    if (!condbr.cond.eql(.{ .named = cond_name })) return null;
    const body_index = function.blockIndex(condbr.then_target) orelse return null;
    const exit_index = function.blockIndex(condbr.else_target) orelse return null;
    if (!natural_loop.contains(body_index) or natural_loop.contains(exit_index)) return null;
    if (function.blocks.items[body_index].instructions.items.len != 0) return null;
    const body_br = switch (function.blocks.items[body_index].terminator orelse return null) {
        .br => |br| br,
        .ret, .condbr, .@"switch", .indirectbr, .@"unreachable" => return null,
    };
    if (!std.mem.eql(u8, body_br.target, function.blocks.items[natural_loop.latch].name)) return null;

    const latch = function.blocks.items[natural_loop.latch];
    if (latch.instructions.items.len != 1) return null;
    const next_inst = latch.instructions.items[0];
    const next_name = next_inst.result orelse return null;
    const next = switch (next_inst.kind) {
        .binary => |binary| binary,
        .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return null,
    };
    const latch_br = switch (latch.terminator orelse return null) {
        .br => |br| br,
        .ret, .condbr, .@"switch", .indirectbr, .@"unreachable" => return null,
    };
    if (!std.mem.eql(u8, latch_br.target, header.name)) return null;
    const latch_value = phiIncomingForBlock(phi, latch.name) orelse return null;
    if (!latch_value.eql(.{ .named = next_name })) return null;
    if (!usesValue(next.lhs, phi_name) and !usesValue(next.rhs, phi_name)) return null;
    if (!usesValue(cond.lhs, phi_name) and !usesValue(cond.rhs, phi_name)) return null;

    return .{
        .preheader_index = preheader_index,
        .header_index = natural_loop.header,
        .body_index = body_index,
        .latch_index = natural_loop.latch,
        .exit_index = exit_index,
        .phi_index = 0,
        .cond_index = 1,
        .latch_next_index = 0,
        .phi_name = phi_name,
        .next_name = next_name,
        .cond_name = cond_name,
        .initial_value = initial_value,
        .exit_name = function.blocks.items[exit_index].name,
        .cond = cond,
        .next = next,
    };
}

fn rewriteExitPhis(allocator: std.mem.Allocator, exit: *ir.BasicBlock, old_header_name: []const u8, split_block_name: []const u8, preheader_name: []const u8, phi_name: []const u8, split_phi_name: []const u8, initial_value: ir.Value) !void {
    for (exit.instructions.items) |*instruction| {
        if (instruction.kind != .phi) continue;
        var has_preheader = false;
        for (instruction.kind.phi.incoming.items) |*incoming| {
            if (std.mem.eql(u8, incoming.block, preheader_name)) has_preheader = true;
            if (!std.mem.eql(u8, incoming.block, old_header_name)) continue;
            incoming.block = split_block_name;
            if (incoming.value.eql(.{ .named = phi_name })) incoming.value = .{ .named = split_phi_name };
        }
        if (!has_preheader) {
            try instruction.kind.phi.incoming.append(allocator, .{
                .value = initial_value,
                .block = preheader_name,
            });
        }
    }
}

fn phiIncomingForBlock(phi: ir.PhiInst, block_name: []const u8) ?ir.Value {
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, block_name)) return incoming.value;
    }
    return null;
}

fn usesValue(value: ir.Value, name: []const u8) bool {
    return value == .named and std.mem.eql(u8, value.named, name);
}

fn replaceValue(value: ir.Value, old_name: []const u8, new_value: ir.Value) ir.Value {
    return if (usesValue(value, old_name)) new_value else value;
}
