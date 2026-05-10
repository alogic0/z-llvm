const std = @import("std");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "early-cse",
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
                .ret => |*ret| ret.value = resolveValue(aliases, ret.value),
                .br => {},
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
        if (sameExpression(earlier, instruction)) {
            return .{ .named = earlier.result orelse return null };
        }
    }
    return null;
}

fn isCseCandidate(instruction: ir.Instruction) bool {
    if (instruction.hasSideEffects()) return false;
    return switch (instruction.kind) {
        .binary, .icmp => true,
        .phi, .alloca, .load, .store, .gep => false,
    };
}

fn sameExpression(a: ir.Instruction, b: ir.Instruction) bool {
    return switch (a.kind) {
        .binary => |a_binary| switch (b.kind) {
            .binary => |b_binary| a_binary.op == b_binary.op and
                a_binary.ty.eql(b_binary.ty) and
                a_binary.lhs.eql(b_binary.lhs) and
                a_binary.rhs.eql(b_binary.rhs),
            .icmp, .phi, .alloca, .load, .store, .gep => false,
        },
        .icmp => |a_icmp| switch (b.kind) {
            .icmp => |b_icmp| a_icmp.predicate == b_icmp.predicate and
                a_icmp.operand_ty.eql(b_icmp.operand_ty) and
                a_icmp.lhs.eql(b_icmp.lhs) and
                a_icmp.rhs.eql(b_icmp.rhs),
            .binary, .phi, .alloca, .load, .store, .gep => false,
        },
        .phi, .alloca, .load, .store, .gep => false,
    };
}

fn resolveValue(aliases: std.StringHashMap(ir.Value), value: ir.Value) ir.Value {
    return switch (value) {
        .int, .undef => value,
        .named => |name| aliases.get(name) orelse value,
    };
}
