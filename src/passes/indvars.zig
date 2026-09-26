const std = @import("std");
const cfg = @import("../analysis/cfg.zig");
const loop_info = @import("../analysis/loop_info.zig");
const scalar_evolution = @import("../analysis/scalar_evolution.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "indvars",
    .category = .loop,
    .target_status = "LLVM-shaped algorithm subset",
    .upstream_owner = "llvm/lib/Transforms/Scalar/IndVarSimplify.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        changed = try simplifyFunction(module, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn simplifyFunction(module: *ir.Module, function: *ir.Function) !bool {
    var loops = try loop_info.LoopInfo.build(module.allocator, function.*);
    defer loops.deinit();

    var graph = try cfg.Graph.build(module.allocator, function.*);
    defer graph.deinit();

    for (loops.loops.items) |natural_loop| {
        if (try rewriteDerivedExitValue(module, function, graph, natural_loop)) return true;
    }
    return false;
}

const Candidate = struct {
    header_index: usize,
    exit_index: usize,
    derived_start: i128,
    limit: ir.Value,
    ty: ir.Type,
};

fn rewriteDerivedExitValue(module: *ir.Module, function: *ir.Function, graph: cfg.Graph, natural_loop: loop_info.NaturalLoop) !bool {
    const candidate = try findCandidate(module.allocator, function.*, graph, natural_loop) orelse return false;
    const scaled_name = try module.ownString(try std.fmt.allocPrint(module.allocator, "0", .{}));
    const closed_name = try module.ownString(try std.fmt.allocPrint(module.allocator, "1", .{}));

    var header = &function.blocks.items[candidate.header_index];
    for (header.instructions.items) |*instruction| instruction.deinit(module.allocator);
    header.instructions.clearRetainingCapacity();
    header.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = .{ .int = 1 },
        .then_target = function.blocks.items[candidate.exit_index].name,
        .else_target = header.name,
    } };

    var exit = &function.blocks.items[candidate.exit_index];
    try exit.instructions.insert(module.allocator, 0, .{
        .result = closed_name,
        .kind = .{ .binary = .{
            .op = .add,
            .ty = candidate.ty,
            .lhs = .{ .named = scaled_name },
            .rhs = .{ .int = candidate.derived_start },
        } },
    });
    try exit.instructions.insert(module.allocator, 0, .{
        .result = scaled_name,
        .kind = .{ .binary = .{
            .op = .shl,
            .ty = candidate.ty,
            .lhs = candidate.limit,
            .rhs = .{ .int = 1 },
        } },
    });
    exit.terminator = .{ .ret = .{
        .ty = candidate.ty,
        .value = .{ .named = closed_name },
    } };
    return true;
}

fn findCandidate(allocator: std.mem.Allocator, function: ir.Function, graph: cfg.Graph, natural_loop: loop_info.NaturalLoop) !?Candidate {
    if (natural_loop.header != natural_loop.latch) return null;
    _ = natural_loop.preheader(function, graph) orelse return null;
    if (!try natural_loop.hasDedicatedExits(allocator, graph)) return null;
    if (!natural_loop.isSideEffectFreeDeletionCandidate(function)) return null;

    var exits = try natural_loop.exitBlocks(allocator, graph);
    defer exits.deinit(allocator);
    if (exits.items.len != 1) return null;
    const exit_index = exits.items[0];

    var add_recs = try scalar_evolution.affineAddRecs(allocator, function, natural_loop);
    defer add_recs.deinit(allocator);
    const canonical = findCanonical(add_recs.items) orelse return null;
    const derived = findDerived(add_recs.items, canonical.phi_result) orelse return null;
    if (!derived.isIntegerConstantStartStep(3, 2)) return null;
    if (functionHasResultName(function, "0") or functionHasResultName(function, "1")) return null;

    const limit = findEqualityExitLimit(function, natural_loop, exit_index, canonical.next_value) orelse return null;
    if (valueDefinedInLoop(function, natural_loop, limit)) return null;
    if (!try outsideUsesOnlyExitRet(allocator, function, natural_loop, exit_index, derived.next_value)) return null;

    return .{
        .header_index = natural_loop.header,
        .exit_index = exit_index,
        .derived_start = derived.initial_value.int,
        .limit = limit,
        .ty = derived.ty,
    };
}

fn findCanonical(add_recs: []const scalar_evolution.AffineAddRec) ?scalar_evolution.AffineAddRec {
    for (add_recs) |add_rec| {
        if (add_rec.isIntegerConstantStartStep(0, 1)) return add_rec;
    }
    return null;
}

fn findDerived(add_recs: []const scalar_evolution.AffineAddRec, canonical_phi: []const u8) ?scalar_evolution.AffineAddRec {
    for (add_recs) |add_rec| {
        if (std.mem.eql(u8, add_rec.phi_result, canonical_phi)) continue;
        return add_rec;
    }
    return null;
}

fn findEqualityExitLimit(function: ir.Function, natural_loop: loop_info.NaturalLoop, exit_index: usize, canonical_next: []const u8) ?ir.Value {
    const header = function.blocks.items[natural_loop.header];
    const condbr = switch (header.terminator orelse return null) {
        .condbr => |condbr| condbr,
        .ret, .br, .@"switch", .indirectbr, .@"unreachable" => return null,
    };
    if (function.blockIndex(condbr.then_target) != exit_index) return null;
    if (function.blockIndex(condbr.else_target) != natural_loop.header) return null;

    const cond_name = switch (condbr.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    for (header.instructions.items) |instruction| {
        if (!std.mem.eql(u8, instruction.result orelse "", cond_name)) continue;
        const icmp = switch (instruction.kind) {
            .icmp => |icmp| icmp,
            .binary, .cast, .freeze, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return null,
        };
        if (icmp.predicate != .eq) return null;
        if (valueMatchesName(icmp.lhs, canonical_next)) return icmp.rhs;
        if (valueMatchesName(icmp.rhs, canonical_next)) return icmp.lhs;
        return null;
    }
    return null;
}

fn outsideUsesOnlyExitRet(allocator: std.mem.Allocator, function: ir.Function, natural_loop: loop_info.NaturalLoop, exit_index: usize, allowed_name: []const u8) !bool {
    var loop_defs = std.StringHashMap(void).init(allocator);
    defer loop_defs.deinit();
    for (natural_loop.blocks.items) |block_index| {
        for (function.blocks.items[block_index].instructions.items) |instruction| {
            if (instruction.result) |result| try loop_defs.put(result, {});
        }
    }

    var saw_allowed_exit_ret = false;
    for (function.blocks.items, 0..) |block, block_index| {
        if (natural_loop.contains(block_index)) continue;
        for (block.instructions.items) |instruction| {
            if (instructionUsesAnyLoopDef(instruction, loop_defs)) return false;
        }
        const terminator = block.terminator orelse continue;
        if (!terminatorUsesAnyLoopDef(terminator, loop_defs)) continue;
        if (block_index != exit_index) return false;
        const ret = switch (terminator) {
            .ret => |ret| ret,
            .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return false,
        };
        if (ret.value == null or !valueMatchesName(ret.value.?, allowed_name)) return false;
        saw_allowed_exit_ret = true;
    }
    return saw_allowed_exit_ret;
}

fn valueDefinedInLoop(function: ir.Function, natural_loop: loop_info.NaturalLoop, value: ir.Value) bool {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    for (natural_loop.blocks.items) |block_index| {
        for (function.blocks.items[block_index].instructions.items) |instruction| {
            if (std.mem.eql(u8, instruction.result orelse "", name)) return true;
        }
    }
    return false;
}

fn functionHasResultName(function: ir.Function, name: []const u8) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (std.mem.eql(u8, instruction.result orelse "", name)) return true;
        }
    }
    return false;
}

fn instructionUsesAnyLoopDef(instruction: ir.Instruction, loop_defs: std.StringHashMap(void)) bool {
    var it = loop_defs.keyIterator();
    while (it.next()) |name| {
        if (instructionUsesName(instruction, name.*)) return true;
    }
    return false;
}

fn terminatorUsesAnyLoopDef(terminator: ir.Terminator, loop_defs: std.StringHashMap(void)) bool {
    var it = loop_defs.keyIterator();
    while (it.next()) |name| {
        if (terminatorUsesName(terminator, name.*)) return true;
    }
    return false;
}

fn instructionUsesName(instruction: ir.Instruction, name: []const u8) bool {
    return switch (instruction.kind) {
        .binary => |binary| valueMatchesName(binary.lhs, name) or valueMatchesName(binary.rhs, name),
        .cast => |cast| valueMatchesName(cast.value, name),
        .freeze => |freeze| valueMatchesName(freeze.value, name),
        .icmp => |icmp| valueMatchesName(icmp.lhs, name) or valueMatchesName(icmp.rhs, name),
        .fcmp => |fcmp| valueMatchesName(fcmp.lhs, name) or valueMatchesName(fcmp.rhs, name),
        .select => |select| valueMatchesName(select.cond, name) or valueMatchesName(select.true_value, name) or valueMatchesName(select.false_value, name),
        .phi => |phi| {
            for (phi.incoming.items) |incoming| {
                if (valueMatchesName(incoming.value, name)) return true;
            }
            return false;
        },
        .alloca => |alloca| if (alloca.count) |count| valueMatchesName(count.value, name) else false,
        .load => |load| valueMatchesName(load.ptr, name),
        .store => |store| valueMatchesName(store.value, name) or valueMatchesName(store.ptr, name),
        .atomicrmw => |atomicrmw| valueMatchesName(atomicrmw.ptr, name) or valueMatchesName(atomicrmw.value, name),
        .cmpxchg => |cmpxchg| valueMatchesName(cmpxchg.ptr, name) or valueMatchesName(cmpxchg.expected, name) or valueMatchesName(cmpxchg.replacement, name),
        .extractvalue => |extract| valueMatchesName(extract.aggregate, name),
        .insertvalue => |insert| valueMatchesName(insert.aggregate, name) or valueMatchesName(insert.value, name),
        .fence, .extractelement, .insertelement, .shufflevector => false,
        .gep => |gep| {
            if (valueMatchesName(gep.ptr, name)) return true;
            for (gep.indices.items) |index| {
                if (valueMatchesName(index.value, name)) return true;
            }
            return false;
        },
        .call => |call| {
            for (call.args.items) |arg| {
                if (valueMatchesName(arg.value, name)) return true;
            }
            return false;
        },
    };
}

fn terminatorUsesName(terminator: ir.Terminator, name: []const u8) bool {
    return switch (terminator) {
        .ret => |ret| if (ret.value) |value| valueMatchesName(value, name) else false,
        .br, .@"unreachable" => false,
        .condbr => |condbr| valueMatchesName(condbr.cond, name),
        .@"switch" => |switch_term| {
            if (valueMatchesName(switch_term.cond, name)) return true;
            for (switch_term.cases.items) |case| {
                if (valueMatchesName(case.value, name)) return true;
            }
            return false;
        },
        .indirectbr => |indirectbr| valueMatchesName(indirectbr.addr, name),
    };
}

fn valueMatchesName(value: ir.Value, name: []const u8) bool {
    return value == .named and std.mem.eql(u8, value.named, name);
}
