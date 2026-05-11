const std = @import("std");
const cfg = @import("../analysis/cfg.zig");
const dominator = @import("../analysis/dominator.zig");
const loop_info = @import("../analysis/loop_info.zig");
const memory_effect = @import("../analysis/memory_effect.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "licm",
    .category = .loop,
    .target_status = "fixture-equivalent for listed fixtures",
    .upstream_owner = "llvm/lib/Transforms/Scalar/LICM.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        changed = try hoistFunction(module.allocator, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn hoistFunction(allocator: std.mem.Allocator, function: *ir.Function) !bool {
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

        var local_changed = true;
        while (local_changed) {
            local_changed = false;
            for (natural_loop.blocks.items) |block_index| {
                if (block_index >= function.blocks.items.len) continue;
                var instruction_index: usize = 0;
                while (instruction_index < function.blocks.items[block_index].instructions.items.len) {
                    const instruction = function.blocks.items[block_index].instructions.items[instruction_index];
                    if (!isHoistable(instruction) or
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

fn isHoistable(instruction: ir.Instruction) bool {
    if (instruction.removed or !memory_effect.isSafeToSpeculativelyExecute(instruction)) return false;
    if (instruction.result == null) return false;
    return switch (instruction.kind) {
        .binary => |binary| !isFpBinary(binary.op),
        .cast, .icmp, .select => true,
        .freeze, .fcmp, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .gep, .call => false,
    };
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
        .freeze, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .gep, .call => false,
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
        .fence => return true,
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
    };
}

fn valueMatchesName(value: ir.Value, name: []const u8) bool {
    return switch (value) {
        .int, .undef, .null_value, .zero_initializer, .vector => false,
        .named => |value_name| std.mem.eql(u8, value_name, name),
    };
}

fn isFpBinary(op: ir.BinaryOp) bool {
    return op == .fadd or op == .fmul;
}
