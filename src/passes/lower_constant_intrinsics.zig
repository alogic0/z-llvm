const std = @import("std");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");
const inst_simplify = @import("inst_simplify.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "lower-constant-intrinsics",
    .category = .canonicalization,
    .target_status = "conservative integer min/max intrinsic subset",
    .upstream_owner = "llvm/lib/Transforms/Scalar/LowerConstantIntrinsics.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        var aliases = std.StringHashMap(ir.Value).init(module.allocator);
        defer aliases.deinit();

        for (function.blocks.items) |*block| {
            for (block.instructions.items) |*instruction| {
                instruction.mapOperands(aliases);
                if (instruction.kind != .call) continue;
                if (inst_simplify.simplify(instruction.*)) |replacement| {
                    instruction.removed = true;
                    instruction.replacement = replacement;
                    const result = instruction.result orelse return error.InstructionWithoutResult;
                    try aliases.put(result, replacement);
                    changed = true;
                }
            }

            if (block.terminator) |*terminator| mapTerminatorOperands(terminator, aliases);
        }
    }
    return if (changed) .changed else .unchanged;
}

fn mapTerminatorOperands(terminator: *ir.Terminator, aliases: std.StringHashMap(ir.Value)) void {
    switch (terminator.*) {
        .ret => |*ret| {
            if (ret.value) |value| ret.value = resolveValue(aliases, value);
        },
        .br => {},
        .@"unreachable" => {},
        .condbr => |*condbr| condbr.cond = resolveValue(aliases, condbr.cond),
        .indirectbr => |*indirectbr| indirectbr.addr = resolveValue(aliases, indirectbr.addr),
        .@"switch" => |*switch_term| {
            switch_term.cond = resolveValue(aliases, switch_term.cond);
            for (switch_term.cases.items) |*case| {
                case.value = resolveValue(aliases, case.value);
            }
        },
    }
}

fn resolveValue(aliases: std.StringHashMap(ir.Value), value: ir.Value) ir.Value {
    return switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => value,
        .named => |name| aliases.get(name) orelse value,
    };
}
