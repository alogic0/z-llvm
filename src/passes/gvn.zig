const std = @import("std");
const dominator = @import("../analysis/dominator.zig");
const memory_effect = @import("../analysis/memory_effect.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");
const inst_simplify = @import("inst_simplify.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "gvn",
    .category = .scalar,
    .target_status = "LLVM-shaped algorithm subset",
    .upstream_owner = "llvm/lib/Transforms/Scalar/GVN.cpp",
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
    var dom = try dominator.Dominators.build(allocator, function.*);
    defer dom.deinit();

    var aliases = std.StringHashMap(ir.Value).init(allocator);
    defer aliases.deinit();

    var changed = false;
    for (function.blocks.items, 0..) |*block, block_index| {
        for (block.instructions.items, 0..) |*instruction, instruction_index| {
            instruction.mapOperands(aliases);
            if (instruction.removed or !isCandidate(instruction.*)) continue;

            if (findDominatingEquivalent(function.*, dom, block_index, instruction_index, instruction.*)) |replacement| {
                instruction.removed = true;
                instruction.replacement = replacement;
                const result = instruction.result orelse return error.InstructionWithoutResult;
                try aliases.put(result, replacement);
                replaceValue(function, result, replacement);
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
    return changed;
}

fn findDominatingEquivalent(
    function: ir.Function,
    dom: dominator.Dominators,
    block_index: usize,
    instruction_index: usize,
    instruction: ir.Instruction,
) ?ir.Value {
    for (function.blocks.items, 0..) |block, candidate_block_index| {
        for (block.instructions.items, 0..) |candidate, candidate_index| {
            if (candidate.removed or !isCandidate(candidate)) continue;
            if (candidate_block_index == block_index and candidate_index >= instruction_index) continue;
            if (candidate_block_index != block_index and !dom.dominates(candidate_block_index, block_index)) continue;
            if (!inst_simplify.sameExpression(candidate, instruction)) continue;
            return .{ .named = candidate.result orelse return null };
        }
    }
    return null;
}

fn isCandidate(instruction: ir.Instruction) bool {
    if (memory_effect.classify(instruction) != .none) return false;
    return switch (instruction.kind) {
        .binary, .cast, .icmp, .select => true,
        .freeze, .phi, .alloca, .load, .store, .gep, .call => false,
    };
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
        };
    }
}

fn replaceOperand(value: ir.Value, name: []const u8, replacement: ir.Value) ir.Value {
    return switch (value) {
        .int, .undef => value,
        .named => |value_name| if (std.mem.eql(u8, value_name, name)) replacement else value,
    };
}

fn resolveValue(aliases: std.StringHashMap(ir.Value), value: ir.Value) ir.Value {
    return switch (value) {
        .int, .undef => value,
        .named => |name| aliases.get(name) orelse value,
    };
}
