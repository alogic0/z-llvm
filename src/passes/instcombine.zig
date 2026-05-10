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
                instruction.mapOperands(aliases);

                if (fold(instruction.*)) |replacement| {
                    instruction.removed = true;
                    instruction.replacement = replacement;
                    try aliases.put(instruction.result, replacement);
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

fn resolveValue(aliases: std.StringHashMap(ir.Value), value: ir.Value) ir.Value {
    return switch (value) {
        .int => value,
        .named => |name| aliases.get(name) orelse value,
    };
}

fn fold(instruction: ir.Instruction) ?ir.Value {
    return switch (instruction.kind) {
        .binary => |binary| foldBinary(binary),
        .icmp => |icmp| foldIcmp(icmp),
    };
}

fn foldBinary(binary: ir.BinaryInst) ?ir.Value {
    if (binary.lhs == .int and binary.rhs == .int) {
        const lhs = binary.lhs.int;
        const rhs = binary.rhs.int;
        return .{ .int = switch (binary.op) {
            .add => lhs + rhs,
            .sub => lhs - rhs,
            .mul => lhs * rhs,
        } };
    }

    return switch (binary.op) {
        .add => if (isZero(binary.rhs))
            binary.lhs
        else if (isZero(binary.lhs))
            binary.rhs
        else
            null,
        .sub => if (isZero(binary.rhs)) binary.lhs else null,
        .mul => if (isOne(binary.rhs))
            binary.lhs
        else if (isOne(binary.lhs))
            binary.rhs
        else if (isZero(binary.rhs) or isZero(binary.lhs))
            .{ .int = 0 }
        else
            null,
    };
}

fn foldIcmp(icmp: ir.IcmpInst) ?ir.Value {
    if (icmp.lhs == .int and icmp.rhs == .int) {
        return .{ .int = switch (icmp.predicate) {
            .eq => @intFromBool(icmp.lhs.int == icmp.rhs.int),
            .ne => @intFromBool(icmp.lhs.int != icmp.rhs.int),
        } };
    }

    if (icmp.lhs.eql(icmp.rhs)) {
        return .{ .int = switch (icmp.predicate) {
            .eq => 1,
            .ne => 0,
        } };
    }

    return null;
}

fn isZero(value: ir.Value) bool {
    return value == .int and value.int == 0;
}

fn isOne(value: ir.Value) bool {
    return value == .int and value.int == 1;
}
