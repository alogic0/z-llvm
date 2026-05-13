const std = @import("std");
const cfg = @import("../analysis/cfg.zig");
const memory_ssa = @import("../analysis/memory_ssa.zig");
const dominator = @import("../analysis/dominator.zig");
const loop_info = @import("../analysis/loop_info.zig");
const memory_effect = @import("../analysis/memory_effect.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "licm",
    .category = .loop,
    .target_status = "LLVM-shaped algorithm subset",
    .upstream_owner = "llvm/lib/Transforms/Scalar/LICM.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        changed = try hoistFunction(module.allocator, module, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn hoistFunction(allocator: std.mem.Allocator, module: *ir.Module, function: *ir.Function) !bool {
    var graph = try cfg.Graph.build(allocator, function.*);
    defer graph.deinit();

    var dom = try dominator.Dominators.build(allocator, function.*);
    defer dom.deinit();

    var loops = try loop_info.LoopInfo.build(allocator, function.*);
    defer loops.deinit();

    var def_blocks = std.StringHashMap(usize).init(allocator);
    defer def_blocks.deinit();
    try collectDefinitionBlocks(&def_blocks, function.*);

    var changed = false;
    for (loops.loops.items) |natural_loop| {
        if (!hasUniqueLoopHeader(loops, natural_loop.header)) continue;
        const preheader = natural_loop.preheader(function.*, graph) orelse continue;
        if (!dom.dominates(preheader, natural_loop.header)) continue;
        if (try promoteLoopAccessesToScalars(module, function, graph, natural_loop, preheader)) return true;

        var local_changed = true;
        while (local_changed) {
            local_changed = false;
            for (natural_loop.blocks.items) |block_index| {
                if (block_index >= function.blocks.items.len) continue;
                var instruction_index: usize = 0;
                while (instruction_index < function.blocks.items[block_index].instructions.items.len) {
                    const instruction = function.blocks.items[block_index].instructions.items[instruction_index];
                    if (!isHoistable(module.*, function.*, natural_loop, block_index, instruction) or
                        !isLoopInvariant(instruction, natural_loop, def_blocks) or
                        !hoistDestinationDominatesUses(function.*, dom, instruction.result.?, preheader))
                    {
                        instruction_index += 1;
                        continue;
                    }

                    const moved = function.blocks.items[block_index].instructions.orderedRemove(instruction_index);
                    try function.blocks.items[preheader].instructions.append(allocator, moved);
                    if (moved.result) |result| try def_blocks.put(result, preheader);
                    changed = true;
                    local_changed = true;
                }
            }
        }
    }
    return changed;
}

const PromotionCandidate = struct {
    ptr: ir.Value,
    ty: ir.Type,
    load_index: usize,
    load_result: []const u8,
    store_index: usize,
    store_value: ir.Value,
    exit_index: usize,
};

fn promoteLoopAccessesToScalars(module: *ir.Module, function: *ir.Function, graph: cfg.Graph, natural_loop: loop_info.NaturalLoop, preheader: usize) !bool {
    const candidate = (try findPromotionCandidate(module.allocator, function.*, graph, natural_loop, preheader)) orelse return false;
    const ptr_name = switch (candidate.ptr) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const promoted_load_name = try module.ownString(try std.fmt.allocPrint(module.allocator, "{s}.promoted", .{ptr_name}));
    const phi_name = try module.ownString(try std.fmt.allocPrint(module.allocator, "{s}1", .{valueName(candidate.store_value) orelse "promoted"}));
    const lcssa_name = try module.ownString(try std.fmt.allocPrint(module.allocator, "{s}.lcssa", .{valueName(candidate.store_value) orelse phi_name}));

    try function.blocks.items[preheader].instructions.append(module.allocator, .{
        .result = promoted_load_name,
        .kind = .{ .load = .{
            .ty = candidate.ty,
            .ptr = candidate.ptr,
        } },
    });

    var incoming: std.ArrayList(ir.PhiIncoming) = .empty;
    errdefer incoming.deinit(module.allocator);
    try incoming.append(module.allocator, .{
        .value = .{ .named = promoted_load_name },
        .block = function.blocks.items[preheader].name,
    });
    try incoming.append(module.allocator, .{
        .value = candidate.store_value,
        .block = function.blocks.items[natural_loop.latch].name,
    });
    try function.blocks.items[natural_loop.header].instructions.insert(module.allocator, 0, .{
        .result = phi_name,
        .kind = .{ .phi = .{
            .ty = candidate.ty,
            .incoming = incoming,
        } },
    });

    replaceValue(function, candidate.load_result, .{ .named = phi_name });
    removeInstructionPair(module.allocator, &function.blocks.items[natural_loop.header], candidate.load_index + 1, candidate.store_index + 1);

    var exit_incoming: std.ArrayList(ir.PhiIncoming) = .empty;
    errdefer exit_incoming.deinit(module.allocator);
    try exit_incoming.append(module.allocator, .{
        .value = candidate.store_value,
        .block = function.blocks.items[natural_loop.latch].name,
    });
    try function.blocks.items[candidate.exit_index].instructions.insert(module.allocator, 0, .{
        .result = lcssa_name,
        .kind = .{ .phi = .{
            .ty = candidate.ty,
            .incoming = exit_incoming,
        } },
    });
    try function.blocks.items[candidate.exit_index].instructions.insert(module.allocator, 1, .{
        .result = null,
        .kind = .{ .store = .{
            .ty = candidate.ty,
            .value = .{ .named = lcssa_name },
            .ptr = candidate.ptr,
        } },
    });
    return true;
}

fn findPromotionCandidate(allocator: std.mem.Allocator, function: ir.Function, graph: cfg.Graph, natural_loop: loop_info.NaturalLoop, preheader: usize) !?PromotionCandidate {
    if (natural_loop.header != natural_loop.latch) return null;
    if (!try natural_loop.hasDedicatedExits(allocator, graph)) return null;
    var exits = try natural_loop.exitBlocks(allocator, graph);
    defer exits.deinit(allocator);
    if (exits.items.len != 1) return null;
    const exit_index = exits.items[0];
    if (!exitStartsWithNonPhi(function.blocks.items[exit_index])) return null;

    var candidate: ?PromotionCandidate = null;
    for (natural_loop.blocks.items) |block_index| {
        if (block_index != natural_loop.header) return null;
        const block = function.blocks.items[block_index];
        for (block.instructions.items, 0..) |instruction, instruction_index| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .load => |load| {
                    if (load.attrs.isBarrier()) return null;
                    if (!pointerDefinedInBlock(function, load.ptr, preheader)) return null;
                    if (candidate) |existing| {
                        if (!existing.ptr.eql(load.ptr) or !existing.ty.eql(load.ty) or existing.load_result.len != 0) return null;
                        candidate.?.load_index = instruction_index;
                        candidate.?.load_result = instruction.result orelse return null;
                    } else {
                        candidate = .{
                            .ptr = load.ptr,
                            .ty = load.ty,
                            .load_index = instruction_index,
                            .load_result = instruction.result orelse return null,
                            .store_index = std.math.maxInt(usize),
                            .store_value = .undef,
                            .exit_index = exit_index,
                        };
                    }
                },
                .store => |store| {
                    if (store.attrs.isBarrier()) return null;
                    if (!pointerDefinedInBlock(function, store.ptr, preheader)) return null;
                    if (candidate) |existing| {
                        if (!existing.ptr.eql(store.ptr) or !existing.ty.eql(store.ty) or existing.store_index != std.math.maxInt(usize)) return null;
                        candidate.?.store_index = instruction_index;
                        candidate.?.store_value = store.value;
                    } else {
                        candidate = .{
                            .ptr = store.ptr,
                            .ty = store.ty,
                            .load_index = std.math.maxInt(usize),
                            .load_result = "",
                            .store_index = instruction_index,
                            .store_value = store.value,
                            .exit_index = exit_index,
                        };
                    }
                },
                .call, .atomicrmw, .cmpxchg, .fence => return null,
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => {},
            }
        }
    }
    const result = candidate orelse return null;
    if (result.load_index == std.math.maxInt(usize) or result.store_index == std.math.maxInt(usize)) return null;
    if (result.load_index >= result.store_index) return null;
    if (!loopValueAvailableOnLatch(function, natural_loop, result.store_value)) return null;
    return result;
}

fn hasUniqueLoopHeader(loops: loop_info.LoopInfo, header: usize) bool {
    var count: usize = 0;
    for (loops.loops.items) |natural_loop| {
        if (natural_loop.header != header) continue;
        count += 1;
        if (count > 1) return false;
    }
    return count == 1;
}

fn collectDefinitionBlocks(def_blocks: *std.StringHashMap(usize), function: ir.Function) !void {
    for (function.params.items) |param| try def_blocks.put(param.name, std.math.maxInt(usize));
    for (function.blocks.items, 0..) |block, block_index| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.result) |result| try def_blocks.put(result, block_index);
        }
    }
}

fn isHoistable(module: ir.Module, function: ir.Function, natural_loop: loop_info.NaturalLoop, block_index: usize, instruction: ir.Instruction) bool {
    if (instruction.removed) return false;
    if (instruction.result == null) return false;
    return switch (instruction.kind) {
        .binary => |binary| memory_effect.isSafeToSpeculativelyExecute(instruction) and !isFpBinary(binary.op),
        .cast, .icmp, .select => memory_effect.isSafeToSpeculativelyExecute(instruction),
        .load => |load| isHoistableLoad(module, function, natural_loop, block_index, instruction, load),
        .freeze, .fcmp, .phi, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => false,
    };
}

fn exitStartsWithNonPhi(block: ir.BasicBlock) bool {
    if (block.instructions.items.len == 0) return true;
    return block.instructions.items[0].kind != .phi;
}

fn pointerDefinedInBlock(function: ir.Function, ptr: ir.Value, block_index: usize) bool {
    const name = valueName(ptr) orelse return false;
    if (block_index >= function.blocks.items.len) return false;
    for (function.blocks.items[block_index].instructions.items) |instruction| {
        if (std.mem.eql(u8, instruction.result orelse "", name)) return instruction.kind == .alloca;
    }
    return false;
}

fn loopValueAvailableOnLatch(function: ir.Function, natural_loop: loop_info.NaturalLoop, value: ir.Value) bool {
    const name = valueName(value) orelse return true;
    for (natural_loop.blocks.items) |block_index| {
        for (function.blocks.items[block_index].instructions.items) |instruction| {
            if (!std.mem.eql(u8, instruction.result orelse "", name)) continue;
            return block_index == natural_loop.latch;
        }
    }
    return false;
}

fn removeInstructionPair(allocator: std.mem.Allocator, block: *ir.BasicBlock, first_index: usize, second_index: usize) void {
    if (first_index > second_index) {
        removeInstructionAt(allocator, block, first_index);
        removeInstructionAt(allocator, block, second_index);
    } else {
        removeInstructionAt(allocator, block, second_index);
        removeInstructionAt(allocator, block, first_index);
    }
}

fn removeInstructionAt(allocator: std.mem.Allocator, block: *ir.BasicBlock, index: usize) void {
    var removed = block.instructions.orderedRemove(index);
    removed.deinit(allocator);
}

fn replaceValue(function: *ir.Function, name: []const u8, replacement: ir.Value) void {
    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*instruction| {
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
                .extractvalue => |*extract| extract.aggregate = replaceOperand(extract.aggregate, name, replacement),
                .insertvalue => |*insert| {
                    insert.aggregate = replaceOperand(insert.aggregate, name, replacement);
                    insert.value = replaceOperand(insert.value, name, replacement);
                },
                .fence, .extractelement, .insertelement, .shufflevector => {},
                .gep => |*gep| {
                    gep.ptr = replaceOperand(gep.ptr, name, replacement);
                    for (gep.indices.items) |*index| index.value = replaceOperand(index.value, name, replacement);
                },
                .call => |*call| for (call.args.items) |*arg| {
                    arg.value = replaceOperand(arg.value, name, replacement);
                },
            }
        }
        if (block.terminator) |*terminator| {
            switch (terminator.*) {
                .ret => |*ret| {
                    if (ret.value) |value| ret.value = replaceOperand(value, name, replacement);
                },
                .br, .@"unreachable" => {},
                .condbr => |*condbr| condbr.cond = replaceOperand(condbr.cond, name, replacement),
                .@"switch" => |*switch_term| {
                    switch_term.cond = replaceOperand(switch_term.cond, name, replacement);
                    for (switch_term.cases.items) |*case| case.value = replaceOperand(case.value, name, replacement);
                },
                .indirectbr => |*indirectbr| indirectbr.addr = replaceOperand(indirectbr.addr, name, replacement),
            }
        }
    }
}

fn replaceOperand(value: ir.Value, name: []const u8, replacement: ir.Value) ir.Value {
    return if (valueMatchesName(value, name)) replacement else value;
}

fn valueName(value: ir.Value) ?[]const u8 {
    return switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

fn isHoistableLoad(module: ir.Module, function: ir.Function, natural_loop: loop_info.NaturalLoop, block_index: usize, instruction: ir.Instruction, load: ir.LoadInst) bool {
    if (block_index != natural_loop.header) return false;
    if (load.attrs.isBarrier()) return false;
    for (natural_loop.blocks.items) |loop_block_index| {
        const block = function.blocks.items[loop_block_index];
        for (block.instructions.items) |candidate| {
            if (candidate.removed) continue;
            if (candidate.result != null and instruction.result != null and std.mem.eql(u8, candidate.result.?, instruction.result.?)) continue;
            if (memory_ssa.isBarrierForAccess(module, function, candidate, load.ptr, load.ty)) return false;
        }
    }
    return true;
}

fn isLoopInvariant(instruction: ir.Instruction, natural_loop: loop_info.NaturalLoop, def_blocks: std.StringHashMap(usize)) bool {
    return switch (instruction.kind) {
        .binary => |binary| natural_loop.isLoopInvariantValue(binary.lhs, def_blocks) and
            natural_loop.isLoopInvariantValue(binary.rhs, def_blocks),
        .cast => |cast| natural_loop.isLoopInvariantValue(cast.value, def_blocks),
        .icmp => |icmp| natural_loop.isLoopInvariantValue(icmp.lhs, def_blocks) and
            natural_loop.isLoopInvariantValue(icmp.rhs, def_blocks),
        .fcmp => return false,
        .select => |select| natural_loop.isLoopInvariantValue(select.cond, def_blocks) and
            natural_loop.isLoopInvariantValue(select.true_value, def_blocks) and
            natural_loop.isLoopInvariantValue(select.false_value, def_blocks),
        .load => |load| natural_loop.isLoopInvariantValue(load.ptr, def_blocks),
        .freeze, .phi, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => false,
    };
}

fn hoistDestinationDominatesUses(function: ir.Function, dom: dominator.Dominators, result: []const u8, destination_block: usize) bool {
    for (function.blocks.items, 0..) |block, block_index| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.result) |defined| {
                if (std.mem.eql(u8, defined, result)) continue;
            }
            if (!instructionUsesAreDominated(function, dom, instruction, result, destination_block, block_index)) return false;
        }
        if (block.terminator) |terminator| {
            if (terminatorUsesValue(terminator, result) and !dominatesTerminatorUse(dom, destination_block, block_index)) return false;
        }
    }
    return true;
}

fn instructionUsesAreDominated(
    function: ir.Function,
    dom: dominator.Dominators,
    instruction: ir.Instruction,
    result: []const u8,
    destination_block: usize,
    use_block: usize,
) bool {
    switch (instruction.kind) {
        .phi => |phi| {
            for (phi.incoming.items) |incoming| {
                if (!valueMatchesName(incoming.value, result)) continue;
                const incoming_block = function.blockIndex(incoming.block) orelse return false;
                if (!dominatesPhiIncomingUse(dom, destination_block, incoming_block)) return false;
            }
            return true;
        },
        .binary => |binary| return regularUsesAreDominated(dom, destination_block, use_block, result, &.{ binary.lhs, binary.rhs }),
        .cast => |cast| return regularUsesAreDominated(dom, destination_block, use_block, result, &.{cast.value}),
        .freeze => |freeze| return regularUsesAreDominated(dom, destination_block, use_block, result, &.{freeze.value}),
        .icmp => |icmp| return regularUsesAreDominated(dom, destination_block, use_block, result, &.{ icmp.lhs, icmp.rhs }),
        .fcmp => |fcmp| return regularUsesAreDominated(dom, destination_block, use_block, result, &.{ fcmp.lhs, fcmp.rhs }),
        .select => |select| return regularUsesAreDominated(dom, destination_block, use_block, result, &.{ select.cond, select.true_value, select.false_value }),
        .alloca => return true,
        .load => |load| return regularUsesAreDominated(dom, destination_block, use_block, result, &.{load.ptr}),
        .store => |store| return regularUsesAreDominated(dom, destination_block, use_block, result, &.{ store.value, store.ptr }),
        .atomicrmw => |atomicrmw| return regularUsesAreDominated(dom, destination_block, use_block, result, &.{ atomicrmw.ptr, atomicrmw.value }),
        .cmpxchg => |cmpxchg| return regularUsesAreDominated(dom, destination_block, use_block, result, &.{ cmpxchg.ptr, cmpxchg.expected, cmpxchg.replacement }),
        .fence, .extractelement, .insertelement, .shufflevector => return true,
        .extractvalue => |extract| return regularUsesAreDominated(dom, destination_block, use_block, result, &.{extract.aggregate}),
        .insertvalue => |insert| return regularUsesAreDominated(dom, destination_block, use_block, result, &.{ insert.aggregate, insert.value }),
        .gep => |gep| {
            if (valueMatchesName(gep.ptr, result) and !dominatesRegularInstructionUse(dom, destination_block, use_block)) return false;
            for (gep.indices.items) |index| {
                if (valueMatchesName(index.value, result) and !dominatesRegularInstructionUse(dom, destination_block, use_block)) return false;
            }
            return true;
        },
        .call => |call| {
            for (call.args.items) |arg| {
                if (valueMatchesName(arg.value, result) and !dominatesRegularInstructionUse(dom, destination_block, use_block)) return false;
            }
            return true;
        },
    }
}

fn regularUsesAreDominated(dom: dominator.Dominators, destination_block: usize, use_block: usize, result: []const u8, values: []const ir.Value) bool {
    for (values) |value| {
        if (valueMatchesName(value, result) and !dominatesRegularInstructionUse(dom, destination_block, use_block)) return false;
    }
    return true;
}

fn dominatesRegularInstructionUse(dom: dominator.Dominators, destination_block: usize, use_block: usize) bool {
    return destination_block != use_block and dom.dominates(destination_block, use_block);
}

fn dominatesPhiIncomingUse(dom: dominator.Dominators, destination_block: usize, incoming_block: usize) bool {
    return destination_block == incoming_block or dom.dominates(destination_block, incoming_block);
}

fn dominatesTerminatorUse(dom: dominator.Dominators, destination_block: usize, terminator_block: usize) bool {
    return destination_block == terminator_block or dom.dominates(destination_block, terminator_block);
}

fn terminatorUsesValue(terminator: ir.Terminator, result: []const u8) bool {
    return switch (terminator) {
        .ret => |ret| if (ret.value) |value| valueMatchesName(value, result) else false,
        .br, .@"unreachable" => false,
        .condbr => |condbr| valueMatchesName(condbr.cond, result),
        .@"switch" => |switch_term| {
            if (valueMatchesName(switch_term.cond, result)) return true;
            for (switch_term.cases.items) |case| {
                if (valueMatchesName(case.value, result)) return true;
            }
            return false;
        },
        .indirectbr => |indirectbr| valueMatchesName(indirectbr.addr, result),
    };
}

fn valueMatchesName(value: ir.Value, name: []const u8) bool {
    return switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        .named => |value_name| std.mem.eql(u8, value_name, name),
    };
}

fn isFpBinary(op: ir.BinaryOp) bool {
    return op == .fadd or op == .fsub or op == .fmul or op == .fdiv or op == .frem;
}
