const std = @import("std");
const cfg = @import("cfg.zig");
const dominator = @import("dominator.zig");
const ir = @import("../ir.zig");

pub const Backedge = struct {
    latch: usize,
    header: usize,
};

pub const InductionVariable = struct {
    phi_result: []const u8,
    initial_value: ir.Value,
    step_value: ir.Value,
    next_value: []const u8,
};

pub const LoopRotateStatus = enum {
    unsupported_self_latch_header,
    unsupported_no_preheader,
    unsupported_not_implemented,
};

pub const LoopDeletionStatus = enum {
    rejected_side_effects,
    rejected_multiple_exits,
    rejected_no_proven_exit,
    eligible_not_implemented,
};

pub const NaturalLoop = struct {
    header: usize,
    latch: usize,
    blocks: std.ArrayList(usize),
    parent_index: ?usize = null,
    depth: usize = 0,

    pub fn deinit(loop: *NaturalLoop, allocator: std.mem.Allocator) void {
        loop.blocks.deinit(allocator);
    }

    pub fn contains(loop: NaturalLoop, block_index: usize) bool {
        for (loop.blocks.items) |member| {
            if (member == block_index) return true;
        }
        return false;
    }

    pub fn containsBlock(loop: NaturalLoop, block_index: usize) bool {
        return loop.contains(block_index);
    }

    pub fn headerBlock(loop: NaturalLoop) usize {
        return loop.header;
    }

    pub fn latchBlock(loop: NaturalLoop) usize {
        return loop.latch;
    }

    pub fn latchBlocks(loop: NaturalLoop, allocator: std.mem.Allocator) !std.ArrayList(usize) {
        var latches: std.ArrayList(usize) = .empty;
        errdefer latches.deinit(allocator);
        try latches.append(allocator, loop.latch);
        return latches;
    }

    pub fn backedge(loop: NaturalLoop) Backedge {
        return .{
            .latch = loop.latch,
            .header = loop.header,
        };
    }

    pub fn depthLevel(loop: NaturalLoop) usize {
        return loop.depth + 1;
    }

    pub fn preheader(loop: NaturalLoop, function: ir.Function, graph: cfg.Graph) ?usize {
        var candidate: ?usize = null;
        for (graph.predecessors(loop.header)) |predecessor| {
            if (loop.contains(predecessor)) continue;
            if (candidate != null) return null;
            candidate = predecessor;
        }
        const preheader_index = candidate orelse return null;
        const terminator = function.blocks.items[preheader_index].terminator orelse return null;
        switch (terminator) {
            .br => |br| {
                const target = function.blockIndex(br.target) orelse return null;
                return if (target == loop.header) preheader_index else null;
            },
            .ret, .condbr, .@"unreachable" => return null,
        }
    }

    pub fn exitingBlocks(loop: NaturalLoop, allocator: std.mem.Allocator, graph: cfg.Graph) !std.ArrayList(usize) {
        var exiting: std.ArrayList(usize) = .empty;
        errdefer exiting.deinit(allocator);

        for (loop.blocks.items) |block_index| {
            for (graph.successors(block_index)) |successor| {
                if (!loop.contains(successor)) {
                    try appendUnique(allocator, &exiting, block_index);
                    break;
                }
            }
        }
        sortBlocks(exiting.items);
        return exiting;
    }

    pub fn exitBlocks(loop: NaturalLoop, allocator: std.mem.Allocator, graph: cfg.Graph) !std.ArrayList(usize) {
        var exits: std.ArrayList(usize) = .empty;
        errdefer exits.deinit(allocator);

        for (loop.blocks.items) |block_index| {
            for (graph.successors(block_index)) |successor| {
                if (loop.contains(successor)) continue;
                try appendUnique(allocator, &exits, successor);
            }
        }
        sortBlocks(exits.items);
        return exits;
    }

    pub fn hasDedicatedExits(loop: NaturalLoop, allocator: std.mem.Allocator, graph: cfg.Graph) !bool {
        var exits = try loop.exitBlocks(allocator, graph);
        defer exits.deinit(allocator);

        for (exits.items) |exit_block| {
            for (graph.predecessors(exit_block)) |predecessor| {
                if (!loop.contains(predecessor)) return false;
            }
        }
        return true;
    }

    pub fn hasLcssaForm(loop: NaturalLoop, allocator: std.mem.Allocator, function: ir.Function, graph: cfg.Graph) !bool {
        var loop_defs = std.StringHashMap(void).init(allocator);
        defer loop_defs.deinit();

        for (loop.blocks.items) |block_index| {
            if (block_index >= function.blocks.items.len) return false;
            for (function.blocks.items[block_index].instructions.items) |instruction| {
                if (instruction.removed) continue;
                if (instruction.result) |result| try loop_defs.put(result, {});
            }
        }

        var exits = try loop.exitBlocks(allocator, graph);
        defer exits.deinit(allocator);

        for (function.blocks.items, 0..) |block, block_index| {
            if (loop.contains(block_index)) continue;
            for (block.instructions.items) |instruction| {
                if (instruction.removed) continue;
                if (!outsideInstructionUsesAreLcssa(function, loop, loop_defs, exits.items, instruction, block_index)) return false;
            }
            if (block.terminator) |terminator| {
                if (terminatorUsesLoopDefinition(terminator, loop_defs)) return false;
            }
        }

        return true;
    }

    pub fn isLoopInvariantValue(loop: NaturalLoop, value: ir.Value, def_blocks: std.StringHashMap(usize)) bool {
        return switch (value) {
            .int, .fp, .undef, .null_value, .zero_initializer, .vector => true,
            .named => |name| {
                const block = def_blocks.get(name) orelse return false;
                if (block == std.math.maxInt(usize)) return true;
                return !loop.contains(block);
            },
        };
    }

    pub fn simpleInductionVariables(loop: NaturalLoop, allocator: std.mem.Allocator, function: ir.Function) !std.ArrayList(InductionVariable) {
        var inductions: std.ArrayList(InductionVariable) = .empty;
        errdefer inductions.deinit(allocator);

        if (loop.header >= function.blocks.items.len or loop.latch >= function.blocks.items.len) return inductions;
        const header = function.blocks.items[loop.header];
        const latch = function.blocks.items[loop.latch];

        for (header.instructions.items) |instruction| {
            const phi = switch (instruction.kind) {
                .phi => |phi| phi,
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .gep, .call => continue,
            };
            const phi_result = instruction.result orelse continue;
            const incoming = classifyInductionIncoming(loop, function, phi) orelse continue;
            const step = findIntegerStep(latch, phi.ty, phi_result, incoming.latch_value) orelse continue;
            try inductions.append(allocator, .{
                .phi_result = phi_result,
                .initial_value = incoming.initial_value,
                .step_value = step,
                .next_value = incoming.latch_value,
            });
        }

        return inductions;
    }

    pub fn rotationStatus(loop: NaturalLoop, function: ir.Function, graph: cfg.Graph) LoopRotateStatus {
        if (loop.header == loop.latch) return .unsupported_self_latch_header;
        if (loop.preheader(function, graph) == null) return .unsupported_no_preheader;
        return .unsupported_not_implemented;
    }

    pub fn deletionStatus(loop: NaturalLoop, allocator: std.mem.Allocator, function: ir.Function, graph: cfg.Graph) !LoopDeletionStatus {
        if (!loop.isSideEffectFreeDeletionCandidate(function)) return .rejected_side_effects;

        var exits = try loop.exitBlocks(allocator, graph);
        defer exits.deinit(allocator);
        if (exits.items.len != 1) return .rejected_multiple_exits;

        var exiting = try loop.exitingBlocks(allocator, graph);
        defer exiting.deinit(allocator);
        if (exiting.items.len == 0) return .rejected_no_proven_exit;

        return .eligible_not_implemented;
    }

    pub fn isSideEffectFreeDeletionCandidate(loop: NaturalLoop, function: ir.Function) bool {
        for (loop.blocks.items) |block_index| {
            if (block_index >= function.blocks.items.len) return false;
            for (function.blocks.items[block_index].instructions.items) |instruction| {
                if (instruction.removed) continue;
                switch (instruction.kind) {
                    .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .gep => {},
                    .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .call => return false,
                }
            }
        }
        return true;
    }
};

pub fn formSimpleLcssa(module: *ir.Module, function_index: usize, loop: NaturalLoop, graph: cfg.Graph) !bool {
    if (function_index >= module.functions.items.len) return false;
    const allocator = module.allocator;
    var changed = false;

    while (true) {
        const function = &module.functions.items[function_index];
        const candidate = try findSimpleLcssaCandidate(allocator, function.*, loop, graph) orelse return changed;
        const phi_name = try module.ownString(try std.fmt.allocPrint(allocator, "{s}.lcssa", .{candidate.value_name}));
        const incoming = try buildExitIncoming(allocator, function.*, loop, graph, candidate.value_name, candidate.exit_block);
        const phi_instruction: ir.Instruction = .{
            .result = phi_name,
            .kind = .{ .phi = .{
                .ty = candidate.ty,
                .incoming = incoming,
            } },
        };
        try function.blocks.items[candidate.exit_block].instructions.insert(allocator, 0, phi_instruction);
        rewriteOutsideLoopUses(function, loop, candidate.value_name, phi_name);
        changed = true;
    }
}

const LcssaCandidate = struct {
    value_name: []const u8,
    ty: ir.Type,
    exit_block: usize,
};

fn findSimpleLcssaCandidate(allocator: std.mem.Allocator, function: ir.Function, loop: NaturalLoop, graph: cfg.Graph) !?LcssaCandidate {
    if (!try loop.hasDedicatedExits(allocator, graph)) return null;

    var exits = try loop.exitBlocks(allocator, graph);
    defer exits.deinit(allocator);
    if (exits.items.len != 1) return null;
    const exit_block = exits.items[0];

    for (loop.blocks.items) |block_index| {
        if (block_index >= function.blocks.items.len) return null;
        for (function.blocks.items[block_index].instructions.items) |instruction| {
            if (instruction.removed) continue;
            const value_name = instruction.result orelse continue;
            if (alreadyHasExitPhi(function, exit_block, value_name)) continue;
            if (!outsideUsesValue(function, loop, value_name)) continue;
            const ty = instruction.resultType() orelse continue;
            return .{
                .value_name = value_name,
                .ty = ty,
                .exit_block = exit_block,
            };
        }
    }
    return null;
}

fn buildExitIncoming(allocator: std.mem.Allocator, function: ir.Function, loop: NaturalLoop, graph: cfg.Graph, value_name: []const u8, exit_block: usize) !std.ArrayList(ir.PhiIncoming) {
    var incoming: std.ArrayList(ir.PhiIncoming) = .empty;
    errdefer incoming.deinit(allocator);

    for (graph.predecessors(exit_block)) |predecessor| {
        if (!loop.contains(predecessor)) continue;
        try incoming.append(allocator, .{
            .value = .{ .named = value_name },
            .block = function.blocks.items[predecessor].name,
        });
    }
    if (incoming.items.len == 0) return error.MissingPhiIncoming;
    return incoming;
}

fn alreadyHasExitPhi(function: ir.Function, exit_block: usize, value_name: []const u8) bool {
    for (function.blocks.items[exit_block].instructions.items) |instruction| {
        const phi = switch (instruction.kind) {
            .phi => |phi| phi,
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .gep, .call => break,
        };
        for (phi.incoming.items) |incoming| {
            if (valueMatchesName(incoming.value, value_name)) return true;
        }
    }
    return false;
}

fn outsideUsesValue(function: ir.Function, loop: NaturalLoop, value_name: []const u8) bool {
    for (function.blocks.items, 0..) |block, block_index| {
        if (loop.contains(block_index)) continue;
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instructionUsesValue(instruction, value_name)) return true;
        }
        if (block.terminator) |terminator| {
            if (terminatorUsesValue(terminator, value_name)) return true;
        }
    }
    return false;
}

fn rewriteOutsideLoopUses(function: *ir.Function, loop: NaturalLoop, value_name: []const u8, replacement_name: []const u8) void {
    const replacement: ir.Value = .{ .named = replacement_name };
    for (function.blocks.items, 0..) |*block, block_index| {
        if (loop.contains(block_index)) continue;
        for (block.instructions.items) |*instruction| {
            if (instruction.removed) continue;
            if (instruction.kind == .phi and std.mem.eql(u8, instruction.result orelse "", replacement_name)) continue;
            replaceInstructionUse(instruction, value_name, replacement);
        }
        if (block.terminator) |*terminator| replaceTerminatorUse(terminator, value_name, replacement);
    }
}

fn instructionUsesValue(instruction: ir.Instruction, value_name: []const u8) bool {
    return switch (instruction.kind) {
        .binary => |binary| valueMatchesName(binary.lhs, value_name) or valueMatchesName(binary.rhs, value_name),
        .cast => |cast| valueMatchesName(cast.value, value_name),
        .freeze => |freeze| valueMatchesName(freeze.value, value_name),
        .icmp => |icmp| valueMatchesName(icmp.lhs, value_name) or valueMatchesName(icmp.rhs, value_name),
        .fcmp => |fcmp| valueMatchesName(fcmp.lhs, value_name) or valueMatchesName(fcmp.rhs, value_name),
        .select => |select| valueMatchesName(select.cond, value_name) or valueMatchesName(select.true_value, value_name) or valueMatchesName(select.false_value, value_name),
        .phi => |phi| {
            for (phi.incoming.items) |incoming| {
                if (valueMatchesName(incoming.value, value_name)) return true;
            }
            return false;
        },
        .alloca => false,
        .load => |load| valueMatchesName(load.ptr, value_name),
        .store => |store| valueMatchesName(store.value, value_name) or valueMatchesName(store.ptr, value_name),
        .atomicrmw => |atomicrmw| valueMatchesName(atomicrmw.ptr, value_name) or valueMatchesName(atomicrmw.value, value_name),
        .cmpxchg => |cmpxchg| valueMatchesName(cmpxchg.ptr, value_name) or valueMatchesName(cmpxchg.expected, value_name) or valueMatchesName(cmpxchg.replacement, value_name),
        .fence, .extractelement, .insertelement, .shufflevector => false,
        .gep => |gep| {
            if (valueMatchesName(gep.ptr, value_name)) return true;
            for (gep.indices.items) |index| {
                if (valueMatchesName(index.value, value_name)) return true;
            }
            return false;
        },
        .call => |call| {
            for (call.args.items) |arg| {
                if (valueMatchesName(arg.value, value_name)) return true;
            }
            return false;
        },
    };
}

fn terminatorUsesValue(terminator: ir.Terminator, value_name: []const u8) bool {
    return switch (terminator) {
        .ret => |ret| if (ret.value) |value| valueMatchesName(value, value_name) else false,
        .br, .@"unreachable" => false,
        .condbr => |condbr| valueMatchesName(condbr.cond, value_name),
    };
}

fn replaceInstructionUse(instruction: *ir.Instruction, value_name: []const u8, replacement: ir.Value) void {
    switch (instruction.kind) {
        .binary => |*binary| {
            binary.lhs = replaceValue(binary.lhs, value_name, replacement);
            binary.rhs = replaceValue(binary.rhs, value_name, replacement);
        },
        .cast => |*cast| cast.value = replaceValue(cast.value, value_name, replacement),
        .freeze => |*freeze| freeze.value = replaceValue(freeze.value, value_name, replacement),
        .icmp => |*icmp| {
            icmp.lhs = replaceValue(icmp.lhs, value_name, replacement);
            icmp.rhs = replaceValue(icmp.rhs, value_name, replacement);
        },
        .fcmp => |*fcmp| {
            fcmp.lhs = replaceValue(fcmp.lhs, value_name, replacement);
            fcmp.rhs = replaceValue(fcmp.rhs, value_name, replacement);
        },
        .select => |*select| {
            select.cond = replaceValue(select.cond, value_name, replacement);
            select.true_value = replaceValue(select.true_value, value_name, replacement);
            select.false_value = replaceValue(select.false_value, value_name, replacement);
        },
        .phi => |*phi| for (phi.incoming.items) |*incoming| {
            incoming.value = replaceValue(incoming.value, value_name, replacement);
        },
        .alloca => {},
        .load => |*load| load.ptr = replaceValue(load.ptr, value_name, replacement),
        .store => |*store| {
            store.value = replaceValue(store.value, value_name, replacement);
            store.ptr = replaceValue(store.ptr, value_name, replacement);
        },
        .atomicrmw => |*atomicrmw| {
            atomicrmw.ptr = replaceValue(atomicrmw.ptr, value_name, replacement);
            atomicrmw.value = replaceValue(atomicrmw.value, value_name, replacement);
        },
        .cmpxchg => |*cmpxchg| {
            cmpxchg.ptr = replaceValue(cmpxchg.ptr, value_name, replacement);
            cmpxchg.expected = replaceValue(cmpxchg.expected, value_name, replacement);
            cmpxchg.replacement = replaceValue(cmpxchg.replacement, value_name, replacement);
        },
        .fence, .extractelement, .insertelement, .shufflevector => {},
        .gep => |*gep| {
            gep.ptr = replaceValue(gep.ptr, value_name, replacement);
            for (gep.indices.items) |*index| index.value = replaceValue(index.value, value_name, replacement);
        },
        .call => |*call| for (call.args.items) |*arg| {
            arg.value = replaceValue(arg.value, value_name, replacement);
        },
    }
}

fn replaceTerminatorUse(terminator: *ir.Terminator, value_name: []const u8, replacement: ir.Value) void {
    switch (terminator.*) {
        .ret => |*ret| {
            if (ret.value) |value| ret.value = replaceValue(value, value_name, replacement);
        },
        .br, .@"unreachable" => {},
        .condbr => |*condbr| condbr.cond = replaceValue(condbr.cond, value_name, replacement),
    }
}

fn replaceValue(value: ir.Value, value_name: []const u8, replacement: ir.Value) ir.Value {
    return if (valueMatchesName(value, value_name)) replacement else value;
}

const InductionIncoming = struct {
    initial_value: ir.Value,
    latch_value: []const u8,
};

fn classifyInductionIncoming(loop: NaturalLoop, function: ir.Function, phi: ir.PhiInst) ?InductionIncoming {
    var initial_value: ?ir.Value = null;
    var latch_value: ?[]const u8 = null;

    for (phi.incoming.items) |incoming| {
        const incoming_block = function.blockIndex(incoming.block) orelse return null;
        if (incoming_block == loop.latch) {
            latch_value = switch (incoming.value) {
                .named => |name| name,
                .int, .fp, .undef, .null_value, .zero_initializer, .vector => return null,
            };
        } else if (incoming_block != loop.latch) {
            if (initial_value != null) return null;
            initial_value = incoming.value;
        } else {
            return null;
        }
    }

    return .{
        .initial_value = initial_value orelse return null,
        .latch_value = latch_value orelse return null,
    };
}

fn findIntegerStep(latch: ir.BasicBlock, ty: ir.Type, phi_result: []const u8, next_value: []const u8) ?ir.Value {
    for (latch.instructions.items) |instruction| {
        const result = instruction.result orelse continue;
        if (!std.mem.eql(u8, result, next_value)) continue;
        const binary = switch (instruction.kind) {
            .binary => |binary| binary,
            .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .gep, .call => return null,
        };
        if (binary.op != .add or !binary.ty.eql(ty)) return null;
        if (valueMatchesName(binary.lhs, phi_result)) return binary.rhs;
        if (valueMatchesName(binary.rhs, phi_result)) return binary.lhs;
        return null;
    }
    return null;
}

fn valueMatchesName(value: ir.Value, name: []const u8) bool {
    return switch (value) {
        .int, .fp, .undef, .null_value, .zero_initializer, .vector => false,
        .named => |value_name| std.mem.eql(u8, value_name, name),
    };
}

fn outsideInstructionUsesAreLcssa(
    function: ir.Function,
    loop: NaturalLoop,
    loop_defs: std.StringHashMap(void),
    exit_blocks: []const usize,
    instruction: ir.Instruction,
    block_index: usize,
) bool {
    return switch (instruction.kind) {
        .phi => |phi| {
            for (phi.incoming.items) |incoming| {
                if (!valueNamesLoopDefinition(incoming.value, loop_defs)) continue;
                if (!containsIndex(exit_blocks, block_index)) return false;
                const incoming_block = function.blockIndex(incoming.block) orelse return false;
                if (!loop.contains(incoming_block)) return false;
            }
            return true;
        },
        .binary => |binary| !valuesUseLoopDefinition(loop_defs, &.{ binary.lhs, binary.rhs }),
        .cast => |cast| !valueNamesLoopDefinition(cast.value, loop_defs),
        .freeze => |freeze| !valueNamesLoopDefinition(freeze.value, loop_defs),
        .icmp => |icmp| !valuesUseLoopDefinition(loop_defs, &.{ icmp.lhs, icmp.rhs }),
        .fcmp => |fcmp| !valuesUseLoopDefinition(loop_defs, &.{ fcmp.lhs, fcmp.rhs }),
        .select => |select| !valuesUseLoopDefinition(loop_defs, &.{ select.cond, select.true_value, select.false_value }),
        .alloca => true,
        .load => |load| !valueNamesLoopDefinition(load.ptr, loop_defs),
        .store => |store| !valuesUseLoopDefinition(loop_defs, &.{ store.value, store.ptr }),
        .atomicrmw => |atomicrmw| !valuesUseLoopDefinition(loop_defs, &.{ atomicrmw.ptr, atomicrmw.value }),
        .cmpxchg => |cmpxchg| !valuesUseLoopDefinition(loop_defs, &.{ cmpxchg.ptr, cmpxchg.expected, cmpxchg.replacement }),
        .fence, .extractelement, .insertelement, .shufflevector => true,
        .gep => |gep| {
            if (valueNamesLoopDefinition(gep.ptr, loop_defs)) return false;
            for (gep.indices.items) |index| {
                if (valueNamesLoopDefinition(index.value, loop_defs)) return false;
            }
            return true;
        },
        .call => |call| {
            for (call.args.items) |arg| {
                if (valueNamesLoopDefinition(arg.value, loop_defs)) return false;
            }
            return true;
        },
    };
}

fn terminatorUsesLoopDefinition(terminator: ir.Terminator, loop_defs: std.StringHashMap(void)) bool {
    return switch (terminator) {
        .ret => |ret| if (ret.value) |value| valueNamesLoopDefinition(value, loop_defs) else false,
        .br, .@"unreachable" => false,
        .condbr => |condbr| valueNamesLoopDefinition(condbr.cond, loop_defs),
    };
}

fn valuesUseLoopDefinition(loop_defs: std.StringHashMap(void), values: []const ir.Value) bool {
    for (values) |value| {
        if (valueNamesLoopDefinition(value, loop_defs)) return true;
    }
    return false;
}

fn valueNamesLoopDefinition(value: ir.Value, loop_defs: std.StringHashMap(void)) bool {
    return switch (value) {
        .int, .fp, .undef, .null_value, .zero_initializer, .vector => false,
        .named => |name| loop_defs.contains(name),
    };
}

fn containsIndex(items: []const usize, value: usize) bool {
    for (items) |item| {
        if (item == value) return true;
    }
    return false;
}

pub const LoopInfo = struct {
    allocator: std.mem.Allocator,
    loops: std.ArrayList(NaturalLoop),

    pub fn build(allocator: std.mem.Allocator, function: ir.Function) !LoopInfo {
        var graph = try cfg.Graph.build(allocator, function);
        defer graph.deinit();

        var dom = try dominator.Dominators.build(allocator, function);
        defer dom.deinit();

        var info: LoopInfo = .{
            .allocator = allocator,
            .loops = .empty,
        };
        errdefer info.deinit();

        for (function.blocks.items, 0..) |_, latch| {
            for (graph.successors(latch)) |header| {
                if (!dom.dominates(header, latch)) continue;
                try info.loops.append(allocator, try buildNaturalLoop(allocator, graph, header, latch));
            }
        }
        info.computeNesting();

        return info;
    }

    pub fn deinit(info: *LoopInfo) void {
        for (info.loops.items) |*loop| loop.deinit(info.allocator);
        info.loops.deinit(info.allocator);
    }

    pub fn loopForHeader(info: LoopInfo, header: usize) ?*const NaturalLoop {
        for (info.loops.items) |*loop| {
            if (loop.header == header) return loop;
        }
        return null;
    }

    pub fn loopForBlock(info: LoopInfo, block_index: usize) ?*const NaturalLoop {
        var best: ?*const NaturalLoop = null;
        for (info.loops.items) |*loop| {
            if (!loop.contains(block_index)) continue;
            if (best == null or loop.depth > best.?.depth) best = loop;
        }
        return best;
    }

    pub fn loopDepth(info: LoopInfo, block_index: usize) usize {
        const loop = info.loopForBlock(block_index) orelse return 0;
        return loop.depthLevel();
    }

    pub fn latchesForHeader(info: LoopInfo, allocator: std.mem.Allocator, header: usize) !std.ArrayList(usize) {
        var latches: std.ArrayList(usize) = .empty;
        errdefer latches.deinit(allocator);
        for (info.loops.items) |loop| {
            if (loop.header != header) continue;
            try appendUnique(allocator, &latches, loop.latch);
        }
        sortBlocks(latches.items);
        return latches;
    }

    pub fn backedges(info: LoopInfo, allocator: std.mem.Allocator) !std.ArrayList(Backedge) {
        var edges: std.ArrayList(Backedge) = .empty;
        errdefer edges.deinit(allocator);
        for (info.loops.items) |loop| {
            try edges.append(allocator, loop.backedge());
        }
        sortBackedges(edges.items);
        return edges;
    }

    fn computeNesting(info: *LoopInfo) void {
        for (info.loops.items, 0..) |*child, child_index| {
            var parent_index: ?usize = null;
            for (info.loops.items, 0..) |parent, maybe_parent_index| {
                if (child_index == maybe_parent_index) continue;
                if (!containsLoop(parent, child.*)) continue;
                if (parent_index == null or parent.blocks.items.len < info.loops.items[parent_index.?].blocks.items.len) {
                    parent_index = maybe_parent_index;
                }
            }
            child.parent_index = parent_index;
        }

        var changed = true;
        while (changed) {
            changed = false;
            for (info.loops.items) |*loop| {
                const new_depth = if (loop.parent_index) |parent_index| info.loops.items[parent_index].depth + 1 else 0;
                if (loop.depth == new_depth) continue;
                loop.depth = new_depth;
                changed = true;
            }
        }
    }
};

fn containsLoop(parent: NaturalLoop, child: NaturalLoop) bool {
    if (parent.blocks.items.len <= child.blocks.items.len) return false;
    for (child.blocks.items) |block_index| {
        if (!parent.contains(block_index)) return false;
    }
    return true;
}

fn buildNaturalLoop(allocator: std.mem.Allocator, graph: cfg.Graph, header: usize, latch: usize) !NaturalLoop {
    var loop: NaturalLoop = .{
        .header = header,
        .latch = latch,
        .blocks = .empty,
    };
    errdefer loop.deinit(allocator);

    try appendUnique(allocator, &loop.blocks, header);
    try appendUnique(allocator, &loop.blocks, latch);

    var worklist: std.ArrayList(usize) = .empty;
    defer worklist.deinit(allocator);
    try worklist.append(allocator, latch);

    while (worklist.pop()) |block| {
        for (graph.predecessors(block)) |predecessor| {
            if (predecessor == header) continue;
            const old_len = loop.blocks.items.len;
            try appendUnique(allocator, &loop.blocks, predecessor);
            if (loop.blocks.items.len != old_len) try worklist.append(allocator, predecessor);
        }
    }

    sortBlocks(loop.blocks.items);
    return loop;
}

fn appendUnique(allocator: std.mem.Allocator, list: *std.ArrayList(usize), value: usize) !void {
    for (list.items) |existing| {
        if (existing == value) return;
    }
    try list.append(allocator, value);
}

fn sortBlocks(items: []usize) void {
    var i: usize = 1;
    while (i < items.len) : (i += 1) {
        const value = items[i];
        var j = i;
        while (j > 0 and items[j - 1] > value) : (j -= 1) {
            items[j] = items[j - 1];
        }
        items[j] = value;
    }
}

fn sortBackedges(items: []Backedge) void {
    var i: usize = 1;
    while (i < items.len) : (i += 1) {
        const value = items[i];
        var j = i;
        while (j > 0 and (items[j - 1].header > value.header or
            (items[j - 1].header == value.header and items[j - 1].latch > value.latch))) : (j -= 1)
        {
            items[j] = items[j - 1];
        }
        items[j] = value;
    }
}
