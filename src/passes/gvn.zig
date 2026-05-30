const std = @import("std");
const alias = @import("../analysis/alias.zig");
const cfg = @import("../analysis/cfg.zig");
const def_use = @import("../analysis/def_use.zig");
const dominator = @import("../analysis/dominator.zig");
const expression_key = @import("../analysis/expression_key.zig");
const fast_math = @import("../analysis/fast_math.zig");
const function_attrs = @import("../analysis/function_attrs.zig");
const memory_effect = @import("../analysis/memory_effect.zig");
const memory_ssa = @import("../analysis/memory_ssa.zig");
const ir = @import("../ir.zig");
const inst_simplify = @import("inst_simplify.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "gvn",
    .category = .scalar,
    .target_status = "fixture-equivalent for listed fixtures",
    .upstream_owner = "llvm/lib/Transforms/Scalar/GVN.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        changed = try eliminateFunction(module.allocator, module, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

const ValueNumber = usize;

const NumberedExpression = struct {
    number: ValueNumber,
    hash: u64,
    instruction: ir.Instruction,
};

const Leader = struct {
    number: ValueNumber,
    block_index: usize,
    instruction_index: usize,
    instruction: ir.Instruction,
};

const ValueTable = struct {
    allocator: std.mem.Allocator,
    module: ir.Module,
    function: ir.Function,
    next_number: ValueNumber = 1,
    entries: std.ArrayList(NumberedExpression) = .empty,

    fn init(allocator: std.mem.Allocator, module: ir.Module, function: ir.Function) ValueTable {
        return .{
            .allocator = allocator,
            .module = module,
            .function = function,
        };
    }

    fn deinit(table: *ValueTable) void {
        table.entries.deinit(table.allocator);
    }

    fn numberFor(table: *ValueTable, instruction: ir.Instruction) !ValueNumber {
        const hash = expression_key.hash(instruction);
        for (table.entries.items) |entry| {
            if (entry.hash != hash) continue;
            if (sameValueExpression(table.module, table.function, entry.instruction, instruction)) return entry.number;
        }

        const number = table.next_number;
        table.next_number += 1;
        try table.entries.append(table.allocator, .{
            .number = number,
            .hash = hash,
            .instruction = instruction,
        });
        return number;
    }
};

fn eliminateFunction(allocator: std.mem.Allocator, module: *ir.Module, function: *ir.Function) !bool {
    var changed = try performSimpleLoadPre(allocator, module, function);
    changed = try performSimpleScalarPre(allocator, module, function) or changed;

    var dom = try dominator.Dominators.build(allocator, function.*);
    defer dom.deinit();

    var aliases = std.StringHashMap(ir.Value).init(allocator);
    defer aliases.deinit();

    var table = ValueTable.init(allocator, module.*, function.*);
    defer table.deinit();

    var memory = try memory_ssa.MemorySSA.build(allocator, module.*, function.*);
    defer memory.deinit();

    var graph = try cfg.Graph.build(allocator, function.*);
    defer graph.deinit();

    var leaders: std.ArrayList(Leader) = .empty;
    defer leaders.deinit(allocator);

    changed = try visitBlock(allocator, function, dom, graph, &aliases, &table, memory, &leaders, 0) or changed;
    return changed;
}

const PreIncoming = struct {
    block_index: usize,
    value: ir.Value,
};

fn performSimpleLoadPre(allocator: std.mem.Allocator, module: *ir.Module, function: *ir.Function) !bool {
    var graph = try cfg.Graph.build(allocator, function.*);
    defer graph.deinit();

    var dom = try dominator.Dominators.build(allocator, function.*);
    defer dom.deinit();

    var block_index: usize = 0;
    while (block_index < function.blocks.items.len) : (block_index += 1) {
        const predecessors = graph.predecessors(block_index);
        if (predecessors.len != 2) continue;

        const load_index = firstPreloadCandidateIndex(function.blocks.items[block_index]) orelse continue;
        const load_instruction = function.blocks.items[block_index].instructions.items[load_index];
        const load = switch (load_instruction.kind) {
            .load => |load| load,
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => continue,
        };
        if (load.attrs.isBarrier()) continue;
        if (!valueAvailableAtEndOfBlock(function.*, dom, load.ptr, predecessors[0])) continue;
        if (!valueAvailableAtEndOfBlock(function.*, dom, load.ptr, predecessors[1])) continue;
        if (joinPrefixClobbers(module.*, function.*, block_index, load_index, load)) continue;

        var incoming: std.ArrayList(PreIncoming) = .empty;
        defer incoming.deinit(allocator);
        var insertions: std.ArrayList(usize) = .empty;
        defer insertions.deinit(allocator);

        var existing_count: usize = 0;
        for (predecessors) |predecessor| {
            if (findAvailablePredecessorLoad(module.*, function.*, predecessor, load)) |value| {
                try incoming.append(allocator, .{ .block_index = predecessor, .value = value });
                existing_count += 1;
                continue;
            }
            if (!hasSingleSuccessorTo(graph, predecessor, block_index)) {
                incoming.clearRetainingCapacity();
                break;
            }
            try incoming.append(allocator, .{ .block_index = predecessor, .value = .undef });
            try insertions.append(allocator, predecessor);
        }

        if (incoming.items.len != predecessors.len) continue;
        if (existing_count == 0 or insertions.items.len > 1) continue;

        if (insertions.items.len == 1) {
            const inserted_value = try insertPreLoad(allocator, module, function, insertions.items[0], load_instruction.result orelse continue, load);
            for (incoming.items) |*entry| {
                if (entry.block_index == insertions.items[0]) {
                    entry.value = inserted_value;
                    break;
                }
            }
        } else if (findStoreIncomingIndex(module.*, function.*, incoming.items, load)) |store_index| {
            if (store_index != 0) {
                const store_incoming = incoming.orderedRemove(store_index);
                try incoming.insert(allocator, 0, store_incoming);
            }
        }

        try replaceLoadWithPhi(allocator, function, block_index, load_index, load_instruction.result orelse continue, load.ty, incoming.items);
        return true;
    }

    return false;
}

fn performSimpleScalarPre(allocator: std.mem.Allocator, module: *ir.Module, function: *ir.Function) !bool {
    var graph = try cfg.Graph.build(allocator, function.*);
    defer graph.deinit();

    var dom = try dominator.Dominators.build(allocator, function.*);
    defer dom.deinit();

    var block_index: usize = 0;
    while (block_index < function.blocks.items.len) : (block_index += 1) {
        const predecessors = graph.predecessors(block_index);
        if (predecessors.len != 2) continue;

        const scalar_index = firstPreScalarCandidateIndex(module.*, function.blocks.items[block_index]) orelse continue;
        const scalar_instruction = function.blocks.items[block_index].instructions.items[scalar_index];
        const scalar_result = scalar_instruction.result orelse continue;
        const scalar_ty = scalarResultType(scalar_instruction) orelse continue;
        if (!scalarOperandsAvailableAtPredecessors(function.*, dom, scalar_instruction, predecessors)) continue;

        var incoming: std.ArrayList(PreIncoming) = .empty;
        defer incoming.deinit(allocator);
        var insertions: std.ArrayList(usize) = .empty;
        defer insertions.deinit(allocator);
        var split_predecessor: ?usize = null;

        var existing_count: usize = 0;
        for (predecessors) |predecessor| {
            if (findAvailablePredecessorScalar(function.*, predecessor, scalar_instruction)) |value| {
                try incoming.append(allocator, .{ .block_index = predecessor, .value = value });
                existing_count += 1;
                continue;
            }
            if (!hasSingleSuccessorTo(graph, predecessor, block_index)) {
                if (split_predecessor != null or !canSplitCriticalScalarPreEdge(function.*, predecessor, block_index)) {
                    incoming.clearRetainingCapacity();
                    break;
                }
                split_predecessor = predecessor;
            }
            try incoming.append(allocator, .{ .block_index = predecessor, .value = .undef });
            try insertions.append(allocator, predecessor);
        }

        if (incoming.items.len != predecessors.len) continue;
        if (existing_count == 0 or insertions.items.len != 1) continue;

        var inserted_block_index = insertions.items[0];
        var phi_block_index = block_index;
        if (split_predecessor) |predecessor| {
            inserted_block_index = try splitCriticalScalarPreEdge(allocator, module, function, predecessor, block_index);
            const insertion_index = inserted_block_index;
            if (insertion_index <= phi_block_index) phi_block_index += 1;
            for (incoming.items) |*entry| {
                if (entry.block_index >= insertion_index) entry.block_index += 1;
                if (entry.block_index == predecessor) {
                    entry.block_index = inserted_block_index;
                }
            }
        }

        const inserted_value = try insertPreScalar(allocator, module, function, inserted_block_index, scalar_instruction);
        for (incoming.items) |*entry| {
            if (entry.block_index == inserted_block_index) {
                entry.value = inserted_value;
                break;
            }
        }

        const phi_result = try uniqueScalarPrePhiName(allocator, module, function.*, scalar_result);
        try replaceScalarWithPhi(allocator, function, phi_block_index, scalar_index, scalar_result, phi_result, scalar_ty, incoming.items, inserted_block_index);
        return true;
    }

    return false;
}

fn firstPreloadCandidateIndex(block: ir.BasicBlock) ?usize {
    for (block.instructions.items, 0..) |instruction, index| {
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .phi => continue,
            .load => return index,
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return null,
        }
    }
    return null;
}

fn firstPreScalarCandidateIndex(module: ir.Module, block: ir.BasicBlock) ?usize {
    for (block.instructions.items, 0..) |instruction, index| {
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .phi => continue,
            .binary => |binary| {
                if (isFpBinary(binary.op) or binary.ty.isVector()) return null;
                return if (isCandidate(module, instruction)) index else null;
            },
            .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return null,
        }
    }
    return null;
}

fn hasSingleSuccessorTo(graph: cfg.Graph, predecessor: usize, block_index: usize) bool {
    const successors = graph.successors(predecessor);
    return successors.len == 1 and successors[0] == block_index;
}

fn canSplitCriticalScalarPreEdge(function: ir.Function, predecessor: usize, block_index: usize) bool {
    const target_name = function.blocks.items[block_index].name;
    const terminator = function.blocks.items[predecessor].terminator orelse return false;
    return switch (terminator) {
        .condbr => |condbr| {
            const then_matches = std.mem.eql(u8, condbr.then_target, target_name);
            const else_matches = std.mem.eql(u8, condbr.else_target, target_name);
            return then_matches != else_matches;
        },
        .ret, .br, .@"switch", .indirectbr, .@"unreachable" => false,
    };
}

fn splitCriticalScalarPreEdge(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    function: *ir.Function,
    predecessor: usize,
    block_index: usize,
) !usize {
    const predecessor_name = function.blocks.items[predecessor].name;
    const target_name = function.blocks.items[block_index].name;
    const split_name = try uniqueCriticalEdgeBlockName(allocator, module, function.*, predecessor_name, target_name);

    switch (function.blocks.items[predecessor].terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |*condbr| {
            if (std.mem.eql(u8, condbr.then_target, target_name)) {
                condbr.then_target = split_name;
            } else if (std.mem.eql(u8, condbr.else_target, target_name)) {
                condbr.else_target = split_name;
            } else {
                return error.InvalidBranchTarget;
            }
        },
        .ret, .br, .@"switch", .indirectbr, .@"unreachable" => return error.InvalidBranchTarget,
    }

    rewritePhiIncomingBlock(&function.blocks.items[block_index], predecessor_name, split_name);

    var split_block = ir.BasicBlock.init(split_name);
    errdefer split_block.deinit(allocator);
    split_block.terminator = .{ .br = .{ .target = target_name } };
    const insertion_index = predecessor + 1;
    try function.blocks.insert(allocator, insertion_index, split_block);
    return insertion_index;
}

fn uniqueCriticalEdgeBlockName(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    function: ir.Function,
    predecessor_name: []const u8,
    target_name: []const u8,
) ![]const u8 {
    var suffix: usize = 0;
    while (true) : (suffix += 1) {
        const candidate = if (suffix == 0)
            try std.fmt.allocPrint(allocator, "{s}.{s}_crit_edge", .{ predecessor_name, target_name })
        else
            try std.fmt.allocPrint(allocator, "{s}.{s}_crit_edge{}", .{ predecessor_name, target_name, suffix });
        errdefer allocator.free(candidate);
        if (function.blockIndex(candidate) == null) return try module.ownString(candidate);
        allocator.free(candidate);
    }
}

fn rewritePhiIncomingBlock(block: *ir.BasicBlock, old_name: []const u8, new_name: []const u8) void {
    for (block.instructions.items) |*instruction| {
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .phi => |*phi| for (phi.incoming.items) |*incoming| {
                if (std.mem.eql(u8, incoming.block, old_name)) incoming.block = new_name;
            },
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return,
        }
    }
}

fn joinPrefixClobbers(module: ir.Module, function: ir.Function, block_index: usize, load_index: usize, load: ir.LoadInst) bool {
    const block = function.blocks.items[block_index];
    for (block.instructions.items[0..load_index]) |instruction| {
        if (instruction.removed or instruction.kind == .phi) continue;
        if (memory_ssa.isBarrierForAccess(module, function, instruction, load.ptr, load.ty)) return true;
    }
    return false;
}

fn findAvailablePredecessorLoad(module: ir.Module, function: ir.Function, block_index: usize, load: ir.LoadInst) ?ir.Value {
    const block = function.blocks.items[block_index];
    var index = block.instructions.items.len;
    while (index > 0) {
        index -= 1;
        const instruction = block.instructions.items[index];
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .load => |candidate| {
                if (candidate.attrs.isBarrier()) return null;
                if (!candidate.ty.eql(load.ty)) {
                    if (memory_ssa.isBarrierForAccess(module, function, instruction, load.ptr, load.ty)) return null;
                    continue;
                }
                if (alias.accessAliasInModule(module, function, candidate.ptr, candidate.ty, load.ptr, load.ty) == .must_alias) {
                    return .{ .named = instruction.result orelse return null };
                }
                if (memory_ssa.isBarrierForAccess(module, function, instruction, load.ptr, load.ty)) return null;
            },
            .store, .atomicrmw, .cmpxchg, .fence, .call => {
                switch (instruction.kind) {
                    .store => |store| {
                        if (store.attrs.isBarrier()) return null;
                        if (store.ty.eql(load.ty)) {
                            switch (alias.accessAliasInModule(module, function, store.ptr, store.ty, load.ptr, load.ty)) {
                                .must_alias => return store.value,
                                .no_alias => continue,
                                .may_alias, .partial_alias => return null,
                            }
                        }
                    },
                    .atomicrmw, .cmpxchg, .fence, .call => {},
                    .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .gep, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => unreachable,
                }
                if (memory_ssa.isBarrierForAccess(module, function, instruction, load.ptr, load.ty)) return null;
            },
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .gep, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => {},
        }
    }
    return null;
}

fn findStoreIncomingIndex(module: ir.Module, function: ir.Function, values: []const PreIncoming, load: ir.LoadInst) ?usize {
    for (values, 0..) |incoming, index| {
        if (predecessorProvidesAvailableStore(module, function, incoming.block_index, load)) return index;
    }
    return null;
}

fn predecessorProvidesAvailableStore(module: ir.Module, function: ir.Function, block_index: usize, load: ir.LoadInst) bool {
    const block = function.blocks.items[block_index];
    var index = block.instructions.items.len;
    while (index > 0) {
        index -= 1;
        const instruction = block.instructions.items[index];
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .store => |store| {
                if (store.attrs.isBarrier()) return false;
                if (store.ty.eql(load.ty)) {
                    switch (alias.accessAliasInModule(module, function, store.ptr, store.ty, load.ptr, load.ty)) {
                        .must_alias => return true,
                        .no_alias => continue,
                        .may_alias, .partial_alias => return false,
                    }
                }
                if (memory_ssa.isBarrierForAccess(module, function, instruction, load.ptr, load.ty)) return false;
            },
            .load => |candidate| {
                if (candidate.attrs.isBarrier()) return false;
                if (candidate.ty.eql(load.ty) and alias.accessAliasInModule(module, function, candidate.ptr, candidate.ty, load.ptr, load.ty) == .must_alias) return false;
                if (memory_ssa.isBarrierForAccess(module, function, instruction, load.ptr, load.ty)) return false;
            },
            .call, .atomicrmw, .cmpxchg, .fence => {
                if (memory_ssa.isBarrierForAccess(module, function, instruction, load.ptr, load.ty)) return false;
            },
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .gep, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => {},
        }
    }
    return false;
}

fn findAvailablePredecessorScalar(function: ir.Function, block_index: usize, instruction: ir.Instruction) ?ir.Value {
    const block = function.blocks.items[block_index];
    var index = block.instructions.items.len;
    while (index > 0) {
        index -= 1;
        const candidate = block.instructions.items[index];
        if (candidate.removed) continue;
        if (expression_key.sameScalarExpression(candidate, instruction)) {
            return .{ .named = candidate.result orelse return null };
        }
    }
    return null;
}

fn insertPreLoad(allocator: std.mem.Allocator, module: *ir.Module, function: *ir.Function, block_index: usize, base: []const u8, load: ir.LoadInst) !ir.Value {
    const name = try uniquePreResultName(allocator, module, function.*, base);
    try function.blocks.items[block_index].instructions.append(allocator, .{
        .result = name,
        .kind = .{ .load = load },
    });
    return .{ .named = name };
}

fn insertPreScalar(allocator: std.mem.Allocator, module: *ir.Module, function: *ir.Function, block_index: usize, instruction: ir.Instruction) !ir.Value {
    const name = try uniqueScalarPreInsertName(allocator, module, function.*);
    try function.blocks.items[block_index].instructions.append(allocator, .{
        .result = name,
        .kind = instruction.kind,
    });
    return .{ .named = name };
}

fn replaceLoadWithPhi(
    allocator: std.mem.Allocator,
    function: *ir.Function,
    block_index: usize,
    instruction_index: usize,
    result: []const u8,
    ty: ir.Type,
    values: []const PreIncoming,
) !void {
    var incoming: std.ArrayList(ir.PhiIncoming) = .empty;
    errdefer incoming.deinit(allocator);
    for (values) |value| {
        try incoming.append(allocator, .{
            .value = value.value,
            .block = function.blocks.items[value.block_index].name,
        });
    }
    const phi_instruction: ir.Instruction = .{
        .result = result,
        .kind = .{ .phi = .{ .ty = ty, .incoming = incoming } },
    };
    try function.blocks.items[block_index].instructions.insert(allocator, 0, phi_instruction);
    _ = function.blocks.items[block_index].instructions.orderedRemove(instruction_index + 1);
}

fn replaceScalarWithPhi(
    allocator: std.mem.Allocator,
    function: *ir.Function,
    block_index: usize,
    instruction_index: usize,
    old_result: []const u8,
    phi_result: []const u8,
    ty: ir.Type,
    values: []const PreIncoming,
    inserted_block_index: usize,
) !void {
    var incoming: std.ArrayList(ir.PhiIncoming) = .empty;
    errdefer incoming.deinit(allocator);
    for (values) |value| {
        if (value.block_index != inserted_block_index) continue;
        try incoming.append(allocator, .{
            .value = value.value,
            .block = function.blocks.items[value.block_index].name,
        });
    }
    for (values) |value| {
        if (value.block_index == inserted_block_index) continue;
        try incoming.append(allocator, .{
            .value = value.value,
            .block = function.blocks.items[value.block_index].name,
        });
    }
    const phi_instruction: ir.Instruction = .{
        .result = phi_result,
        .kind = .{ .phi = .{ .ty = ty, .incoming = incoming } },
    };
    try function.blocks.items[block_index].instructions.insert(allocator, 0, phi_instruction);
    _ = function.blocks.items[block_index].instructions.orderedRemove(instruction_index + 1);
    replaceValue(function, old_result, .{ .named = phi_result });
}

fn uniquePreResultName(allocator: std.mem.Allocator, module: *ir.Module, function: ir.Function, base: []const u8) ![]const u8 {
    var suffix: usize = 0;
    while (true) : (suffix += 1) {
        const candidate = if (suffix == 0)
            try std.fmt.allocPrint(allocator, "{s}.pre", .{base})
        else
            try std.fmt.allocPrint(allocator, "{s}.pre{}", .{ base, suffix });
        errdefer allocator.free(candidate);
        if (!hasResultName(function, candidate)) return try module.ownString(candidate);
        allocator.free(candidate);
    }
}

fn uniqueScalarPreInsertName(allocator: std.mem.Allocator, module: *ir.Module, function: ir.Function) ![]const u8 {
    var suffix: usize = 0;
    while (true) : (suffix += 1) {
        const candidate = if (suffix == 0)
            try allocator.dupe(u8, ".pre")
        else
            try std.fmt.allocPrint(allocator, ".pre{}", .{suffix});
        errdefer allocator.free(candidate);
        if (!hasResultName(function, candidate)) return try module.ownString(candidate);
        allocator.free(candidate);
    }
}

fn uniqueScalarPrePhiName(allocator: std.mem.Allocator, module: *ir.Module, function: ir.Function, base: []const u8) ![]const u8 {
    var suffix: usize = 0;
    while (true) : (suffix += 1) {
        const candidate = if (suffix == 0)
            try std.fmt.allocPrint(allocator, "{s}.pre-phi", .{base})
        else
            try std.fmt.allocPrint(allocator, "{s}.pre-phi{}", .{ base, suffix });
        errdefer allocator.free(candidate);
        if (!hasResultName(function, candidate)) return try module.ownString(candidate);
        allocator.free(candidate);
    }
}

fn hasResultName(function: ir.Function, name: []const u8) bool {
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) return true;
    }
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.result) |result| {
                if (std.mem.eql(u8, result, name)) return true;
            }
        }
    }
    return false;
}

fn scalarResultType(instruction: ir.Instruction) ?ir.Type {
    return switch (instruction.kind) {
        .binary => |binary| binary.ty,
        .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => null,
    };
}

fn scalarOperandsAvailableAtPredecessors(function: ir.Function, dom: dominator.Dominators, instruction: ir.Instruction, predecessors: []const usize) bool {
    switch (instruction.kind) {
        .binary => |binary| {
            for (predecessors) |predecessor| {
                if (!valueAvailableAtEndOfBlock(function, dom, binary.lhs, predecessor)) return false;
                if (!valueAvailableAtEndOfBlock(function, dom, binary.rhs, predecessor)) return false;
            }
            return true;
        },
        .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return false,
    }
}

fn valueAvailableAtEndOfBlock(function: ir.Function, dom: dominator.Dominators, value: ir.Value, block_index: usize) bool {
    return switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => true,
        .named => |name| {
            for (function.params.items) |param| {
                if (std.mem.eql(u8, param.name, name)) return true;
            }
            for (function.blocks.items, 0..) |block, defining_block| {
                for (block.instructions.items) |instruction| {
                    if (instruction.result) |result| {
                        if (std.mem.eql(u8, result, name)) return dom.dominates(defining_block, block_index);
                    }
                }
            }
            return true;
        },
    };
}

fn visitBlock(
    allocator: std.mem.Allocator,
    function: *ir.Function,
    dom: dominator.Dominators,
    graph: cfg.Graph,
    aliases: *std.StringHashMap(ir.Value),
    table: *ValueTable,
    memory: memory_ssa.MemorySSA,
    leaders: *std.ArrayList(Leader),
    block_index: usize,
) !bool {
    const old_leader_len = leaders.items.len;
    defer leaders.shrinkRetainingCapacity(old_leader_len);

    var changed = false;
    const block = &function.blocks.items[block_index];
    for (block.instructions.items, 0..) |*instruction, instruction_index| {
        instruction.mapOperands(aliases.*);
        if (instruction.removed) continue;

        if (simplifyMappedSelect(instruction.*)) |replacement| {
            instruction.removed = true;
            instruction.replacement = replacement;
            const result = instruction.result orelse return error.InstructionWithoutResult;
            try aliases.put(result, replacement);
            replaceValue(function, result, replacement);
            changed = true;
            continue;
        }

        if (forwardSameBlockStoreToLoad(table.module, function.*, block_index, instruction_index, instruction.*)) |replacement| {
            instruction.removed = true;
            instruction.replacement = replacement;
            const result = instruction.result orelse return error.InstructionWithoutResult;
            try aliases.put(result, replacement);
            replaceValue(function, result, replacement);
            changed = true;
            continue;
        }

        if (!isCandidate(table.module, instruction.*)) continue;

        const number = try table.numberFor(instruction.*);
        if (findLeader(table.module, function.*, memory, leaders.items, number, block_index, instruction_index, instruction.*)) |leader_index| {
            const leader = leaders.items[leader_index];
            if (try replaceUnusedLoadLeader(allocator, function, graph, leaders, leader_index, block_index, instruction_index, instruction.*)) {
                changed = true;
                continue;
            }
            expression_key.intersectRetainedFpFlags(&function.blocks.items[leader.block_index].instructions.items[leader.instruction_index], instruction.*);
            leaders.items[leader_index].instruction = function.blocks.items[leader.block_index].instructions.items[leader.instruction_index];
            const replacement: ir.Value = .{ .named = leader.instruction.result orelse return error.InstructionWithoutResult };
            instruction.removed = true;
            instruction.replacement = replacement;
            const result = instruction.result orelse return error.InstructionWithoutResult;
            try aliases.put(result, replacement);
            replaceValue(function, result, replacement);
            changed = true;
            continue;
        }

        try leaders.append(allocator, .{
            .number = number,
            .block_index = block_index,
            .instruction_index = instruction_index,
            .instruction = instruction.*,
        });
    }

    if (block.terminator) |*terminator| switch (terminator.*) {
        .ret => |*ret| {
            if (ret.value) |value| ret.value = resolveValue(aliases.*, value);
        },
        .br => {},
        .@"unreachable" => {},
        .condbr => |*condbr| condbr.cond = resolveValue(aliases.*, condbr.cond),
        .indirectbr => |*indirectbr| indirectbr.addr = resolveValue(aliases.*, indirectbr.addr),
        .@"switch" => |*switch_term| {
            switch_term.cond = resolveValue(aliases.*, switch_term.cond);
            for (switch_term.cases.items) |*case| {
                case.value = resolveValue(aliases.*, case.value);
            }
        },
    };

    for (0..function.blocks.items.len) |child_index| {
        if (dom.immediateDominator(child_index) != block_index) continue;
        changed = try visitBlock(allocator, function, dom, graph, aliases, table, memory, leaders, child_index) or changed;
    }

    return changed;
}

fn simplifyMappedSelect(instruction: ir.Instruction) ?ir.Value {
    return switch (instruction.kind) {
        .select => inst_simplify.simplify(instruction),
        .binary, .cast, .freeze, .icmp, .fcmp, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => null,
    };
}

fn forwardSameBlockStoreToLoad(
    module: ir.Module,
    function: ir.Function,
    block_index: usize,
    instruction_index: usize,
    instruction: ir.Instruction,
) ?ir.Value {
    const load = switch (instruction.kind) {
        .load => |load| load,
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return null,
    };
    if (load.attrs.isBarrier()) return null;

    const block = function.blocks.items[block_index];
    var index = instruction_index;
    while (index > 0) {
        index -= 1;
        const candidate = block.instructions.items[index];
        if (candidate.removed) continue;
        switch (candidate.kind) {
            .store => |store| {
                if (store.attrs.isBarrier()) return null;
                if (store.ty.eql(load.ty)) {
                    switch (alias.accessAliasInModule(module, function, store.ptr, store.ty, load.ptr, load.ty)) {
                        .must_alias => return store.value,
                        .no_alias => continue,
                        .may_alias, .partial_alias => return null,
                    }
                }
                if (memory_ssa.isBarrierForAccess(module, function, candidate, load.ptr, load.ty)) return null;
            },
            .call, .atomicrmw, .cmpxchg, .fence => {
                if (memory_ssa.isBarrierForAccess(module, function, candidate, load.ptr, load.ty)) return null;
            },
            .load => |candidate_load| {
                if (candidate_load.attrs.isBarrier()) return null;
            },
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .gep, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => {},
        }
    }
    return null;
}

fn findLeader(
    module: ir.Module,
    function: ir.Function,
    memory: memory_ssa.MemorySSA,
    leaders: []const Leader,
    number: ValueNumber,
    block_index: usize,
    instruction_index: usize,
    instruction: ir.Instruction,
) ?usize {
    var index = leaders.len;
    while (index > 0) {
        index -= 1;
        const leader = leaders[index];
        if (leader.number != number) continue;
        if (!isMemoryAvailable(module, function, memory, leader, block_index, instruction_index, instruction)) continue;
        return index;
    }
    return null;
}

fn replaceUnusedLoadLeader(
    allocator: std.mem.Allocator,
    function: *ir.Function,
    graph: cfg.Graph,
    leaders: *std.ArrayList(Leader),
    leader_index: usize,
    block_index: usize,
    instruction_index: usize,
    instruction: ir.Instruction,
) !bool {
    const leader = leaders.items[leader_index];
    const leader_result = leader.instruction.result orelse return false;
    const current_result = instruction.result orelse return false;
    if (std.mem.eql(u8, leader_result, current_result)) return false;
    if (leader.instruction.kind != .load or instruction.kind != .load) return false;
    if (leader.block_index == block_index) {
        if (!hasVectorLaneOperationBetween(function.*, block_index, leader.instruction_index, instruction_index)) return false;
    } else {
        if (!isSimpleDiamondJoin(graph, leader.block_index, block_index)) return false;
    }

    var uses = try def_use.UseCounts.collectFunction(allocator, function.*);
    defer uses.deinit();
    if (uses.isUsed(leader_result)) return false;

    function.blocks.items[leader.block_index].instructions.items[leader.instruction_index].removed = true;
    leaders.items[leader_index].block_index = block_index;
    leaders.items[leader_index].instruction_index = instruction_index;
    leaders.items[leader_index].instruction = instruction;
    return true;
}

fn isSimpleDiamondJoin(graph: cfg.Graph, leader_block_index: usize, join_block_index: usize) bool {
    const successors = graph.successors(leader_block_index);
    if (successors.len != 2) return false;

    const predecessors = graph.predecessors(join_block_index);
    if (predecessors.len != successors.len) return false;

    for (successors) |successor| {
        const successor_successors = graph.successors(successor);
        if (successor_successors.len != 1 or successor_successors[0] != join_block_index) return false;

        var is_predecessor = false;
        for (predecessors) |predecessor| {
            if (predecessor == successor) {
                is_predecessor = true;
                break;
            }
        }
        if (!is_predecessor) return false;
    }

    return true;
}

fn hasVectorLaneOperationBetween(function: ir.Function, block_index: usize, earlier_index: usize, later_index: usize) bool {
    if (earlier_index + 1 >= later_index) return false;
    const block = function.blocks.items[block_index];
    for (block.instructions.items[earlier_index + 1 .. later_index]) |instruction| {
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .extractelement, .insertelement, .shufflevector => return true,
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractvalue, .insertvalue, .gep, .call => {},
        }
    }
    return false;
}

fn isCandidate(module: ir.Module, instruction: ir.Instruction) bool {
    const effect = memory_effect.classify(instruction);
    if (effect != .none and effect != .readonly_load) {
        const call = switch (instruction.kind) {
            .call => |call| call,
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => return false,
        };
        return call.ret_ty != .void and function_attrs.callMemoryEffect(module, call) == .none;
    }
    return switch (instruction.kind) {
        .binary => |binary| !isFpBinary(binary.op) or fast_math.allowFpValueNumbering(binary.fp_flags),
        .cast, .icmp, .select, .phi, .load => true,
        .fcmp => |fcmp| fast_math.allowFpValueNumbering(fcmp.fp_flags),
        .freeze, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => false,
    };
}

fn sameValueExpression(module: ir.Module, function: ir.Function, candidate: ir.Instruction, instruction: ir.Instruction) bool {
    return expression_key.sameValueExpression(module, function, candidate, instruction);
}

fn isMemoryAvailable(module: ir.Module, function: ir.Function, memory: memory_ssa.MemorySSA, leader: Leader, block_index: usize, instruction_index: usize, instruction: ir.Instruction) bool {
    if (instruction.kind != .load) return true;
    _ = module;
    _ = function;
    return !memory.hasClobberBetweenAccess(
        .{ .block_index = leader.block_index, .instruction_index = leader.instruction_index },
        .{ .block_index = block_index, .instruction_index = instruction_index },
        instruction.kind.load.ptr,
        instruction.kind.load.ty,
    );
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

fn resolveValue(aliases: std.StringHashMap(ir.Value), value: ir.Value) ir.Value {
    return switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => value,
        .named => |name| aliases.get(name) orelse value,
    };
}

fn isFpBinary(op: ir.BinaryOp) bool {
    return op == .fadd or op == .fsub or op == .fmul or op == .fdiv or op == .frem;
}
