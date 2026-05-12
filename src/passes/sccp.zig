const std = @import("std");
const cfg = @import("../analysis/cfg.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");
const inst_simplify = @import("inst_simplify.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "sccp",
    .category = .scalar,
    .target_status = "fixture-equivalent for listed fixtures",
    .upstream_owner = "llvm/lib/Transforms/Scalar/SCCP.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        changed = try propagateFunction(module.allocator, module.*, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

const Lattice = union(enum) {
    unknown,
    undef,
    constant_int: i128,
    constant_fp: []const u8,
    overdefined,

    fn fromValue(value: ir.Value) Lattice {
        return switch (value) {
            .int => |int| .{ .constant_int = int },
            .fp => |fp| .{ .constant_fp = fp },
            .undef => .undef,
            .poison, .null_value => .overdefined,
            .zero_initializer, .vector, .constant_expr => .overdefined,
            .named => .overdefined,
        };
    }

    fn asValue(lattice: Lattice) ?ir.Value {
        return switch (lattice) {
            .constant_int => |int| .{ .int = int },
            .constant_fp => |fp| .{ .fp = fp },
            .undef => .undef,
            .unknown, .overdefined => null,
        };
    }

    fn eql(a: Lattice, b: Lattice) bool {
        return switch (a) {
            .unknown => b == .unknown,
            .undef => b == .undef,
            .constant_int => |a_int| switch (b) {
                .constant_int => |b_int| a_int == b_int,
                .unknown, .undef, .constant_fp, .overdefined => false,
            },
            .constant_fp => |a_fp| switch (b) {
                .constant_fp => |b_fp| std.mem.eql(u8, a_fp, b_fp),
                .unknown, .undef, .constant_int, .overdefined => false,
            },
            .overdefined => b == .overdefined,
        };
    }

    fn meet(a: Lattice, b: Lattice) Lattice {
        return switch (a) {
            .unknown => b,
            .undef => switch (b) {
                .unknown, .undef => .undef,
                .constant_int, .constant_fp => b,
                .overdefined => .overdefined,
            },
            .constant_int => |a_int| switch (b) {
                .unknown, .undef => a,
                .constant_int => |b_int| if (a_int == b_int) a else .overdefined,
                .constant_fp => .overdefined,
                .overdefined => .overdefined,
            },
            .constant_fp => |a_fp| switch (b) {
                .unknown, .undef => a,
                .constant_fp => |b_fp| if (std.mem.eql(u8, a_fp, b_fp)) a else .overdefined,
                .constant_int => .overdefined,
                .overdefined => .overdefined,
            },
            .overdefined => .overdefined,
        };
    }
};

const Solver = struct {
    allocator: std.mem.Allocator,
    module: ir.Module,
    function: *ir.Function,
    graph: cfg.Graph,
    executable_blocks: []bool,
    executable_edges: []bool,
    values: std.StringHashMap(Lattice),

    fn build(allocator: std.mem.Allocator, module: ir.Module, function: *ir.Function) !Solver {
        var graph = try cfg.Graph.build(allocator, function.*);
        errdefer graph.deinit();

        const block_count = function.blocks.items.len;
        const executable_blocks = try allocator.alloc(bool, block_count);
        errdefer allocator.free(executable_blocks);
        @memset(executable_blocks, false);

        const executable_edges = try allocator.alloc(bool, block_count * block_count);
        errdefer allocator.free(executable_edges);
        @memset(executable_edges, false);

        var values = std.StringHashMap(Lattice).init(allocator);
        errdefer values.deinit();
        for (function.params.items) |param| try values.put(param.name, .overdefined);

        if (block_count != 0) executable_blocks[0] = true;

        return .{
            .allocator = allocator,
            .module = module,
            .function = function,
            .graph = graph,
            .executable_blocks = executable_blocks,
            .executable_edges = executable_edges,
            .values = values,
        };
    }

    fn deinit(solver: *Solver) void {
        solver.values.deinit();
        solver.allocator.free(solver.executable_edges);
        solver.allocator.free(solver.executable_blocks);
        solver.graph.deinit();
    }

    fn solve(solver: *Solver) !void {
        var changed = true;
        while (changed) {
            changed = false;
            for (solver.function.blocks.items, 0..) |block, block_index| {
                if (!solver.executable_blocks[block_index]) continue;
                for (block.instructions.items) |instruction| {
                    if (instruction.removed) continue;
                    if (instruction.result == null) continue;
                    const lattice = if (instruction.kind == .phi)
                        solver.visitPhi(block_index, instruction)
                    else
                        solver.visitInstruction(instruction);
                    changed = try solver.mergeValue(instruction.result.?, lattice) or changed;
                }
                if (block.terminator) |terminator| {
                    changed = try solver.visitTerminator(block_index, terminator) or changed;
                }
            }
        }
    }

    fn rewrite(solver: *Solver) !bool {
        var aliases = std.StringHashMap(ir.Value).init(solver.allocator);
        defer aliases.deinit();

        var changed = false;
        for (solver.function.blocks.items, 0..) |*block, block_index| {
            if (solver.executable_blocks[block_index]) {
                changed = prunePhiIncomingToExecutableEdges(solver, block, block_index) or changed;
            }

            for (block.instructions.items) |*instruction| {
                if (instruction.removed) continue;
                instruction.mapOperands(aliases);
                const result = instruction.result orelse continue;
                const lattice = if (solver.values.get(result)) |value| value else Lattice.unknown;
                const replacement = lattice.asValue() orelse continue;
                instruction.removed = true;
                instruction.replacement = replacement;
                try aliases.put(result, replacement);
                changed = true;
            }

            if (block.terminator) |*terminator| switch (terminator.*) {
                .ret => |*ret| {
                    if (ret.value) |value| ret.value = resolveValue(aliases, value);
                },
                .br, .@"unreachable" => {},
                .condbr => |*condbr| {
                    condbr.cond = resolveValue(aliases, condbr.cond);
                    if (condbr.cond == .int) {
                        block.terminator = .{ .br = .{
                            .target = if (condbr.cond.int == 0) condbr.else_target else condbr.then_target,
                        } };
                        changed = true;
                    }
                },
                .@"switch" => |*switch_term| {
                    switch_term.cond = resolveValue(aliases, switch_term.cond);
                    for (switch_term.cases.items) |*case| {
                        case.value = resolveValue(aliases, case.value);
                    }
                },
            };
        }

        return changed;
    }

    fn visitPhi(solver: Solver, block_index: usize, instruction: ir.Instruction) Lattice {
        const phi = switch (instruction.kind) {
            .phi => |phi| phi,
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => unreachable,
        };

        var result: Lattice = .unknown;
        var saw_executable_incoming = false;
        for (phi.incoming.items) |incoming| {
            const pred_index = solver.function.blockIndex(incoming.block) orelse continue;
            if (!solver.isExecutableEdge(pred_index, block_index)) continue;
            saw_executable_incoming = true;
            result = result.meet(solver.valueLattice(incoming.value));
        }
        return if (saw_executable_incoming) result else .unknown;
    }

    fn visitInstruction(solver: Solver, instruction: ir.Instruction) Lattice {
        if (simplifyCall(solver.module, instruction)) |replacement| return Lattice.fromValue(replacement);

        const folded = solver.foldInstruction(instruction);
        return folded orelse instructionFallback(instruction);
    }

    fn foldInstruction(solver: Solver, instruction: ir.Instruction) ?Lattice {
        var mapped = instruction;
        var unresolved = false;
        var overdefined = false;
        solver.mapInstructionOperands(&mapped, &unresolved, &overdefined);
        if (overdefined) return .overdefined;
        if (unresolved) return null;
        return if (inst_simplify.simplify(mapped)) |replacement| Lattice.fromValue(replacement) else null;
    }

    fn mapInstructionOperands(solver: Solver, instruction: *ir.Instruction, unresolved: *bool, overdefined: *bool) void {
        switch (instruction.kind) {
            .binary => |*binary| {
                binary.lhs = solver.materialize(binary.lhs, unresolved, overdefined);
                binary.rhs = solver.materialize(binary.rhs, unresolved, overdefined);
            },
            .cast => |*cast| cast.value = solver.materialize(cast.value, unresolved, overdefined),
            .freeze => |*freeze| freeze.value = solver.materialize(freeze.value, unresolved, overdefined),
            .icmp => |*icmp| {
                icmp.lhs = solver.materialize(icmp.lhs, unresolved, overdefined);
                icmp.rhs = solver.materialize(icmp.rhs, unresolved, overdefined);
            },
            .fcmp => |*fcmp| {
                fcmp.lhs = solver.materialize(fcmp.lhs, unresolved, overdefined);
                fcmp.rhs = solver.materialize(fcmp.rhs, unresolved, overdefined);
            },
            .select => |*select| {
                const cond = solver.valueLattice(select.cond);
                switch (cond) {
                    .constant_int => |value| {
                        const chosen = if (value == 0) select.false_value else select.true_value;
                        select.true_value = solver.materialize(chosen, unresolved, overdefined);
                        select.false_value = select.true_value;
                        select.cond = .{ .int = 1 };
                    },
                    .undef => {
                        select.cond = .undef;
                        select.true_value = solver.materialize(select.true_value, unresolved, overdefined);
                        select.false_value = solver.materialize(select.false_value, unresolved, overdefined);
                    },
                    .unknown, .constant_fp, .overdefined => {
                        select.true_value = solver.materialize(select.true_value, unresolved, overdefined);
                        select.false_value = solver.materialize(select.false_value, unresolved, overdefined);
                    },
                }
            },
            .call => |*call| {
                for (call.args.items) |*arg| {
                    arg.value = solver.materialize(arg.value, unresolved, overdefined);
                }
            },
            .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => {},
        }
    }

    fn materialize(solver: Solver, value: ir.Value, unresolved: *bool, overdefined: *bool) ir.Value {
        switch (solver.valueLattice(value)) {
            .constant_int => |int| return .{ .int = int },
            .constant_fp => |fp| return .{ .fp = fp },
            .undef => return .undef,
            .unknown => unresolved.* = true,
            .overdefined => overdefined.* = true,
        }
        return value;
    }

    fn visitTerminator(solver: *Solver, block_index: usize, terminator: ir.Terminator) !bool {
        switch (terminator) {
            .br => |br| {
                const target = solver.function.blockIndex(br.target) orelse return false;
                return try solver.markEdge(block_index, target);
            },
            .condbr => |condbr| {
                const then_index = solver.function.blockIndex(condbr.then_target) orelse return false;
                const else_index = solver.function.blockIndex(condbr.else_target) orelse return false;
                return switch (solver.valueLattice(condbr.cond)) {
                    .constant_int => |value| if (value == 0)
                        try solver.markEdge(block_index, else_index)
                    else
                        try solver.markEdge(block_index, then_index),
                    .unknown, .undef, .constant_fp, .overdefined => (try solver.markEdge(block_index, then_index)) or
                        (try solver.markEdge(block_index, else_index)),
                };
            },
            .@"switch" => |switch_term| {
                var changed = try solver.markEdge(block_index, solver.function.blockIndex(switch_term.default_target) orelse return false);
                for (switch_term.cases.items) |case| {
                    changed = (try solver.markEdge(block_index, solver.function.blockIndex(case.target) orelse return false)) or changed;
                }
                return changed;
            },
            .ret, .@"unreachable" => return false,
        }
    }

    fn markEdge(solver: *Solver, from: usize, to: usize) !bool {
        if (!containsIndex(solver.graph.successors(from), to)) return false;
        var changed = false;
        const edge = solver.edgeIndex(from, to);
        if (!solver.executable_edges[edge]) {
            solver.executable_edges[edge] = true;
            changed = true;
        }
        if (!solver.executable_blocks[to]) {
            solver.executable_blocks[to] = true;
            changed = true;
        }
        return changed;
    }

    fn mergeValue(solver: *Solver, name: []const u8, incoming: Lattice) !bool {
        const current = solver.values.get(name) orelse .unknown;
        const merged = current.meet(incoming);
        if (current.eql(merged)) return false;
        try solver.values.put(name, merged);
        return true;
    }

    fn valueLattice(solver: Solver, value: ir.Value) Lattice {
        return switch (value) {
            .int => |int| .{ .constant_int = int },
            .fp => |fp| .{ .constant_fp = fp },
            .undef => .undef,
            .poison, .null_value => .overdefined,
            .zero_initializer, .vector, .constant_expr => .overdefined,
            .named => |name| solver.values.get(name) orelse .unknown,
        };
    }

    fn isExecutableEdge(solver: Solver, from: usize, to: usize) bool {
        return solver.executable_edges[solver.edgeIndex(from, to)];
    }

    fn edgeIndex(solver: Solver, from: usize, to: usize) usize {
        return from * solver.function.blocks.items.len + to;
    }
};

fn propagateFunction(allocator: std.mem.Allocator, module: ir.Module, function: *ir.Function) !bool {
    var solver = try Solver.build(allocator, module, function);
    defer solver.deinit();

    try solver.solve();
    return try solver.rewrite();
}

fn instructionFallback(instruction: ir.Instruction) Lattice {
    return switch (instruction.kind) {
        .alloca, .load, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => .overdefined,
        .store => .unknown,
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi => .unknown,
    };
}

fn prunePhiIncomingToExecutableEdges(solver: *Solver, block: *ir.BasicBlock, block_index: usize) bool {
    var changed = false;
    for (block.instructions.items) |*instruction| {
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .phi => |*phi| {
                var incoming_index = phi.incoming.items.len;
                while (incoming_index > 0) {
                    incoming_index -= 1;
                    const pred_index = solver.function.blockIndex(phi.incoming.items[incoming_index].block) orelse {
                        _ = phi.incoming.orderedRemove(incoming_index);
                        changed = true;
                        continue;
                    };
                    if (solver.isExecutableEdge(pred_index, block_index)) continue;
                    _ = phi.incoming.orderedRemove(incoming_index);
                    changed = true;
                }
            },
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => {},
        }
    }
    return changed;
}

fn simplifyCall(module: ir.Module, instruction: ir.Instruction) ?ir.Value {
    const call = switch (instruction.kind) {
        .call => |call| call,
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => return null,
    };
    if (call.ret_ty == .void) return null;
    const callee = findFunction(module, call.callee) orelse return null;
    if (!callee.ret_ty.eql(call.ret_ty)) return null;
    if (callee.blocks.items.len != 1) return null;
    const block = callee.blocks.items[0];
    if (block.instructions.items.len != 0) return null;
    return switch (block.terminator orelse return null) {
        .ret => |ret| ret.value,
        .br, .condbr, .@"switch", .@"unreachable" => null,
    };
}

fn findFunction(module: ir.Module, name: []const u8) ?ir.Function {
    for (module.functions.items) |function| {
        if (std.mem.eql(u8, function.name, name)) return function;
    }
    return null;
}

fn resolveValue(aliases: std.StringHashMap(ir.Value), value: ir.Value) ir.Value {
    return switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => value,
        .named => |name| aliases.get(name) orelse value,
    };
}

fn containsIndex(values: []const usize, needle: usize) bool {
    for (values) |value| {
        if (value == needle) return true;
    }
    return false;
}
