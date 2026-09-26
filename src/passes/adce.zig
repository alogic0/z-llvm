const std = @import("std");
const cfg = @import("../analysis/cfg.zig");
const cfg_update = @import("../analysis/cfg_update.zig");
const memory_effect = @import("../analysis/memory_effect.zig");
const postdominator = @import("../analysis/postdominator.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "adce",
    .category = .scalar,
    .target_status = "fixture-equivalent for listed fixtures",
    .upstream_owner = "llvm/lib/Transforms/Scalar/ADCE.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        changed = try eliminateFunction(module.allocator, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn eliminateFunction(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    // Opaque text can hide value dependencies. Check before either CFG or
    // instruction deletion; an empty structured walk is not proof of no uses.
    if (hasOpaqueOperands(function)) return false;
    var changed = false;
    while (try removeDeadControlFlow(allocator, function)) {
        changed = true;
    }
    if (try removeDeadInstructions(allocator, function)) {
        changed = true;
        while (try removeDeadControlFlow(allocator, function)) {
            changed = true;
        }
    }
    return changed;
}

const CoverageVisitor = struct {
    pub const Error = error{};
    pub fn visit(_: CoverageVisitor, _: *const ir.Value, _: ir.Type) Error!void {}
};

fn hasOpaqueOperands(function: *const ir.Function) bool {
    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*instruction| {
            if (instruction.removed) continue;
            const coverage = ir.operands.instruction(@as(*const ir.Instruction, instruction), CoverageVisitor{}) catch unreachable;
            if (coverage.has_opaque_references) return true;
        }
        if (block.terminator) |*terminator| {
            const coverage = ir.operands.terminator(@as(*const ir.Terminator, terminator), CoverageVisitor{}) catch unreachable;
            if (coverage.has_opaque_references) return true;
        }
    }
    return false;
}

const InstRef = struct {
    block_index: usize,
    instruction_index: usize,
};

const LiveInstructions = struct {
    allocator: std.mem.Allocator,
    function: *ir.Function,
    refs: std.ArrayList(InstRef),
    defs: std.StringHashMap(usize),
    live: []bool,
    worklist: std.ArrayList(usize),

    fn build(allocator: std.mem.Allocator, function: *ir.Function) !LiveInstructions {
        var refs: std.ArrayList(InstRef) = .empty;
        errdefer refs.deinit(allocator);

        var defs = std.StringHashMap(usize).init(allocator);
        errdefer defs.deinit();

        for (function.blocks.items, 0..) |block, block_index| {
            for (block.instructions.items, 0..) |instruction, instruction_index| {
                if (instruction.removed) continue;
                const index = refs.items.len;
                try refs.append(allocator, .{
                    .block_index = block_index,
                    .instruction_index = instruction_index,
                });
                if (instruction.result) |result| try defs.put(result, index);
            }
        }

        const live = try allocator.alloc(bool, refs.items.len);
        errdefer allocator.free(live);
        @memset(live, false);

        var worklist: std.ArrayList(usize) = .empty;
        errdefer worklist.deinit(allocator);

        return .{
            .allocator = allocator,
            .function = function,
            .refs = refs,
            .defs = defs,
            .live = live,
            .worklist = worklist,
        };
    }

    fn deinit(liveness: *LiveInstructions) void {
        liveness.worklist.deinit(liveness.allocator);
        liveness.allocator.free(liveness.live);
        liveness.defs.deinit();
        liveness.refs.deinit(liveness.allocator);
    }

    fn markSeeds(liveness: *LiveInstructions) !void {
        for (liveness.refs.items, 0..) |ref, index| {
            const instruction = liveness.getInstruction(ref).*;
            if (!memory_effect.isSafeToDelete(instruction)) try liveness.mark(index);
        }

        for (liveness.function.blocks.items) |block| {
            if (block.terminator) |terminator| try liveness.markTerminatorOperands(terminator);
        }
    }

    fn propagate(liveness: *LiveInstructions) !void {
        while (liveness.worklist.pop()) |index| {
            try liveness.markInstructionOperands(liveness.getInstruction(liveness.refs.items[index]).*);
        }
    }

    fn mark(liveness: *LiveInstructions, index: usize) !void {
        if (liveness.live[index]) return;
        liveness.live[index] = true;
        try liveness.worklist.append(liveness.allocator, index);
    }

    fn markValue(liveness: *LiveInstructions, value: ir.Value) !void {
        switch (value) {
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => {},
            .named => |name| if (liveness.defs.get(name)) |index| try liveness.mark(index),
        }
    }

    const OperandVisitor = struct {
        pub const Error = std.mem.Allocator.Error;
        liveness: *LiveInstructions,
        pub fn visit(visitor: OperandVisitor, value: *const ir.Value, _: ir.Type) Error!void {
            try visitor.liveness.markValue(value.*);
        }
    };

    fn markInstructionOperands(liveness: *LiveInstructions, instruction: ir.Instruction) !void {
        // Coverage was checked before any mutation in eliminateFunction.
        _ = try ir.operands.instruction(&instruction, OperandVisitor{ .liveness = liveness });
    }

    fn markTerminatorOperands(liveness: *LiveInstructions, terminator: ir.Terminator) !void {
        _ = try ir.operands.terminator(&terminator, OperandVisitor{ .liveness = liveness });
    }

    fn getInstruction(liveness: LiveInstructions, ref: InstRef) *ir.Instruction {
        return &liveness.function.blocks.items[ref.block_index].instructions.items[ref.instruction_index];
    }
};

fn removeDeadInstructions(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    var liveness = try LiveInstructions.build(allocator, function);
    defer liveness.deinit();

    try liveness.markSeeds();
    try liveness.propagate();

    var changed = false;
    for (liveness.refs.items, 0..) |ref, index| {
        if (liveness.live[index]) continue;
        const instruction = liveness.getInstruction(ref);
        if (!memory_effect.isSafeToDelete(instruction.*)) continue;
        instruction.removed = true;
        changed = true;
    }

    return changed;
}

fn removeDeadControlFlow(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    if (function.blocks.items.len == 0) return false;

    var graph = try cfg.Graph.build(allocator, function.*);
    defer graph.deinit();

    var postdom = try postdominator.PostDominators.build(allocator, function.*);
    defer postdom.deinit();

    var changed = false;
    for (function.blocks.items, 0..) |*block, block_index| {
        const terminator = block.terminator orelse continue;

        const ipdom_index = postdom.immediatePostDominator(block_index) orelse continue;
        if (hasPhi(function.blocks.items[ipdom_index])) continue;

        const target = switch (terminator) {
            .condbr => |condbr| blk: {
                const then_index = function.blockIndex(condbr.then_target) orelse continue;
                const else_index = function.blockIndex(condbr.else_target) orelse continue;

                const then_safe = try regionIsDeadAndAcyclic(allocator, function.*, graph, then_index, ipdom_index);
                const else_safe = try regionIsDeadAndAcyclic(allocator, function.*, graph, else_index, ipdom_index);
                if (!then_safe or !else_safe) continue;

                break :blk if (then_index == ipdom_index)
                    condbr.then_target
                else if (else_index == ipdom_index)
                    condbr.else_target
                else
                    condbr.then_target;
            },
            .@"switch" => |switch_term| blk: {
                const default_index = function.blockIndex(switch_term.default_target) orelse continue;
                if (!try regionIsDeadAndAcyclic(allocator, function.*, graph, default_index, ipdom_index)) continue;
                var all_cases_safe = true;
                for (switch_term.cases.items) |case| {
                    const case_index = function.blockIndex(case.target) orelse {
                        all_cases_safe = false;
                        break;
                    };
                    if (!try regionIsDeadAndAcyclic(allocator, function.*, graph, case_index, ipdom_index)) {
                        all_cases_safe = false;
                        break;
                    }
                }
                if (!all_cases_safe) continue;
                break :blk switch_term.default_target;
            },
            .ret, .br, .indirectbr, .@"unreachable" => continue,
        };

        if (block.terminator) |*old_terminator| old_terminator.deinit(allocator);
        block.terminator = .{ .br = .{ .target = target } };
        _ = try cfg_update.prunePhiIncomingToPredecessors(allocator, function);
        changed = true;
        break;
    }

    return changed;
}

fn regionIsDeadAndAcyclic(allocator: std.mem.Allocator, function: ir.Function, graph: cfg.Graph, start_index: usize, join_index: usize) !bool {
    const visiting = try allocator.alloc(bool, function.blocks.items.len);
    defer allocator.free(visiting);
    @memset(visiting, false);
    return regionPathReachesJoin(function, graph, start_index, join_index, visiting);
}

fn regionPathReachesJoin(function: ir.Function, graph: cfg.Graph, block_index: usize, join_index: usize, visiting: []bool) bool {
    if (block_index == join_index) return true;
    if (visiting[block_index]) return false;
    visiting[block_index] = true;
    defer visiting[block_index] = false;

    const block = function.blocks.items[block_index];
    if (hasPhi(block)) return false;
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        if (!memory_effect.isSafeToDelete(instruction)) return false;
    }

    const terminator = block.terminator orelse return false;
    switch (terminator) {
        .br => |br| {
            const successor_index = function.blockIndex(br.target) orelse return false;
            if (!containsIndex(graph.successors(block_index), successor_index)) return false;
            return regionPathReachesJoin(function, graph, successor_index, join_index, visiting);
        },
        .condbr => |condbr| {
            const then_index = function.blockIndex(condbr.then_target) orelse return false;
            const else_index = function.blockIndex(condbr.else_target) orelse return false;
            if (!containsIndex(graph.successors(block_index), then_index)) return false;
            if (!containsIndex(graph.successors(block_index), else_index)) return false;
            return regionPathReachesJoin(function, graph, then_index, join_index, visiting) and
                regionPathReachesJoin(function, graph, else_index, join_index, visiting);
        },
        .ret, .@"switch", .indirectbr, .@"unreachable" => return false,
    }
}

fn hasPhi(block: ir.BasicBlock) bool {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        if (instruction.kind == .phi) return true;
    }
    return false;
}

fn containsIndex(values: []const usize, needle: usize) bool {
    for (values) |value| {
        if (value == needle) return true;
    }
    return false;
}
