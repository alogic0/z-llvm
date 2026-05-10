const std = @import("std");
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

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        for (function.blocks.items) |*block| {
            var aliases = std.StringHashMap(ir.Value).init(module.allocator);
            defer aliases.deinit();

            for (block.instructions.items, 0..) |*instruction, index| {
                instruction.mapOperands(aliases);
                if (instruction.removed or !isCseCandidate(instruction.*)) continue;

                if (findEarlierEquivalent(block.*, index, instruction.*)) |replacement| {
                    instruction.removed = true;
                    instruction.replacement = replacement;
                    const result = instruction.result orelse return error.InstructionWithoutResult;
                    try aliases.put(result, replacement);
                    changed = true;
                }
            }

            if (block.terminator) |*terminator| switch (terminator.*) {
                .ret => |*ret| {
                    if (ret.value) |value| ret.value = resolveValue(aliases, value);
                },
                .br => {},
                .@"unreachable" => {},
                .condbr => |*condbr| condbr.cond = resolveValue(aliases, condbr.cond),
            };
        }
    }
    return if (changed) .changed else .unchanged;
}

fn findEarlierEquivalent(block: ir.BasicBlock, before_index: usize, instruction: ir.Instruction) ?ir.Value {
    var index = before_index;
    while (index > 0) {
        index -= 1;
        const earlier = block.instructions.items[index];
        if (earlier.removed or !isCseCandidate(earlier)) continue;
        if (inst_simplify.sameExpression(earlier, instruction)) {
            return .{ .named = earlier.result orelse return null };
        }
    }
    return null;
}

fn isCseCandidate(instruction: ir.Instruction) bool {
    if (instruction.hasSideEffects()) return false;
    return switch (instruction.kind) {
        .binary, .cast, .icmp => true,
        .freeze, .select, .phi, .alloca, .load, .store, .gep, .call => false,
    };
}

fn resolveValue(aliases: std.StringHashMap(ir.Value), value: ir.Value) ir.Value {
    return switch (value) {
        .int, .undef => value,
        .named => |name| aliases.get(name) orelse value,
    };
}
