const std = @import("std");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "instcombine",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        var aliases = std.StringHashMap(ir.Value).init(module.allocator);
        defer aliases.deinit();

        for (function.blocks.items) |*block| {
            for (block.instructions.items) |*instruction| {
                instruction.lhs = resolveValue(aliases, instruction.lhs);
                instruction.rhs = resolveValue(aliases, instruction.rhs);

                if (fold(instruction.*)) |replacement| {
                    instruction.removed = true;
                    instruction.replacement = replacement;
                    try aliases.put(instruction.result, replacement);
                    changed = true;
                }
            }

            if (block.terminator) |*terminator| switch (terminator.*) {
                .ret => |*ret| ret.value = resolveValue(aliases, ret.value),
            };
        }
    }
    return if (changed) .changed else .unchanged;
}

fn resolveValue(aliases: std.StringHashMap(ir.Value), value: ir.Value) ir.Value {
    return switch (value) {
        .int => value,
        .named => |name| aliases.get(name) orelse value,
    };
}

fn fold(instruction: ir.Instruction) ?ir.Value {
    if (instruction.lhs == .int and instruction.rhs == .int) {
        const lhs = instruction.lhs.int;
        const rhs = instruction.rhs.int;
        return .{ .int = switch (instruction.op) {
            .add => lhs + rhs,
            .sub => lhs - rhs,
            .mul => lhs * rhs,
        } };
    }

    return switch (instruction.op) {
        .add => if (isZero(instruction.rhs))
            instruction.lhs
        else if (isZero(instruction.lhs))
            instruction.rhs
        else
            null,
        .sub => if (isZero(instruction.rhs)) instruction.lhs else null,
        .mul => if (isOne(instruction.rhs))
            instruction.lhs
        else if (isOne(instruction.lhs))
            instruction.rhs
        else if (isZero(instruction.rhs) or isZero(instruction.lhs))
            .{ .int = 0 }
        else
            null,
    };
}

fn isZero(value: ir.Value) bool {
    return value == .int and value.int == 0;
}

fn isOne(value: ir.Value) bool {
    return value == .int and value.int == 1;
}
