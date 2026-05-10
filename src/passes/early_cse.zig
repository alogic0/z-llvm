const std = @import("std");
const alias = @import("../analysis/alias.zig");
const dominator = @import("../analysis/dominator.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");
const inst_simplify = @import("inst_simplify.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "early-cse",
    .category = .canonicalization,
    .target_status = "LLVM-shaped algorithm subset",
    .upstream_owner = "llvm/lib/Transforms/Scalar/EarlyCSE.cpp",
    .run = run,
};

const AvailableInstruction = struct {
    block_index: usize,
    instruction_index: usize,
    instruction: ir.Instruction,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        changed = try eliminateFunction(module.allocator, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn eliminateFunction(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    var dom = try dominator.Dominators.build(allocator, function.*);
    defer dom.deinit();

    var aliases = std.StringHashMap(ir.Value).init(allocator);
    defer aliases.deinit();

    var available: std.ArrayList(AvailableInstruction) = .empty;
    defer available.deinit(allocator);

    return try visitBlock(allocator, function, dom, &aliases, &available, 0);
}

fn visitBlock(
    allocator: std.mem.Allocator,
    function: *ir.Function,
    dom: dominator.Dominators,
    aliases: *std.StringHashMap(ir.Value),
    available: *std.ArrayList(AvailableInstruction),
    block_index: usize,
) !bool {
    const old_available_len = available.items.len;
    defer available.shrinkRetainingCapacity(old_available_len);

    var changed = false;
    const block = &function.blocks.items[block_index];
    for (block.instructions.items, 0..) |*instruction, instruction_index| {
        instruction.mapOperands(aliases.*);
        if (instruction.removed) continue;

        if (!isCseCandidate(instruction.*)) continue;
        if (findAvailableEquivalent(function.*, available.items, block_index, instruction_index, instruction.*)) |replacement| {
            instruction.removed = true;
            instruction.replacement = replacement;
            const result = instruction.result orelse return error.InstructionWithoutResult;
            try aliases.put(result, replacement);
            changed = true;
            continue;
        }

        try available.append(allocator, .{
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
    };

    for (0..function.blocks.items.len) |child_index| {
        if (dom.immediateDominator(child_index) != block_index) continue;
        changed = try visitBlock(allocator, function, dom, aliases, available, child_index) or changed;
    }

    return changed;
}

fn findAvailableEquivalent(
    function: ir.Function,
    available: []const AvailableInstruction,
    block_index: usize,
    instruction_index: usize,
    instruction: ir.Instruction,
) ?ir.Value {
    var index = available.len;
    while (index > 0) {
        index -= 1;
        const candidate = available[index];
        if (!sameAvailableExpression(function, candidate, block_index, instruction_index, instruction)) continue;
        return .{ .named = candidate.instruction.result orelse return null };
    }
    return null;
}

fn sameAvailableExpression(
    function: ir.Function,
    candidate: AvailableInstruction,
    block_index: usize,
    instruction_index: usize,
    instruction: ir.Instruction,
) bool {
    if (inst_simplify.sameExpression(candidate.instruction, instruction)) return true;
    if (candidate.instruction.kind != .load or instruction.kind != .load) return false;
    const candidate_load = candidate.instruction.kind.load;
    const load = instruction.kind.load;
    if (!candidate_load.ty.eql(load.ty)) return false;
    if (alias.alias(function, candidate_load.ptr, load.ptr) != .must_alias) return false;
    return !hasClobber(function, candidate, block_index, instruction_index, load.ptr);
}

fn hasClobber(function: ir.Function, candidate: AvailableInstruction, block_index: usize, instruction_index: usize, ptr: ir.Value) bool {
    for (function.blocks.items, 0..) |block, current_block_index| {
        for (block.instructions.items, 0..) |instruction, current_instruction_index| {
            if (instruction.removed) continue;
            if (current_block_index == candidate.block_index and current_instruction_index <= candidate.instruction_index) continue;
            if (current_block_index == block_index and current_instruction_index >= instruction_index) continue;
            switch (alias.modRef(function, instruction, ptr)) {
                .mod, .mod_ref, .unknown => return true,
                .no_mod_ref, .ref => {},
            }
        }
    }
    return false;
}

fn isCseCandidate(instruction: ir.Instruction) bool {
    if (instruction.hasSideEffects()) return false;
    return switch (instruction.kind) {
        .binary, .cast, .icmp, .load => true,
        .freeze, .select, .phi, .alloca, .store, .gep, .call => false,
    };
}

fn resolveValue(aliases: std.StringHashMap(ir.Value), value: ir.Value) ir.Value {
    return switch (value) {
        .int, .undef => value,
        .named => |name| aliases.get(name) orelse value,
    };
}
