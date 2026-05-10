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
                    const result = instruction.result orelse return error.InstructionWithoutResult;
                    try aliases.put(result, replacement);
                    changed = true;
                }
            }

            if (block.terminator) |*terminator| switch (terminator.*) {
                .ret => |*ret| ret.value = resolveValue(aliases, ret.value),
                .br => {},
                .@"unreachable" => {},
                .condbr => |*condbr| condbr.cond = resolveValue(aliases, condbr.cond),
            };
        }
    }
    return if (changed) .changed else .unchanged;
}

fn resolveValue(aliases: std.StringHashMap(ir.Value), value: ir.Value) ir.Value {
    return switch (value) {
        .int, .undef => value,
        .named => |name| aliases.get(name) orelse value,
    };
}

fn fold(instruction: ir.Instruction) ?ir.Value {
    return switch (instruction.kind) {
        .binary => |binary| foldBinary(binary),
        .icmp => |icmp| foldIcmp(icmp),
        .select => |select| foldSelect(select),
        .phi, .alloca, .load, .store, .gep => null,
    };
}

fn foldBinary(binary: ir.BinaryInst) ?ir.Value {
    if (binary.lhs == .int and binary.rhs == .int) {
        if (foldBinaryConstants(binary)) |replacement| return replacement;
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
        .@"and" => if (isZero(binary.rhs) or isZero(binary.lhs))
            .{ .int = 0 }
        else if (isAllOnes(binary.rhs))
            binary.lhs
        else if (isAllOnes(binary.lhs))
            binary.rhs
        else if (binary.lhs.eql(binary.rhs))
            binary.lhs
        else
            null,
        .@"or" => if (isZero(binary.rhs))
            binary.lhs
        else if (isZero(binary.lhs))
            binary.rhs
        else if (binary.lhs.eql(binary.rhs))
            binary.lhs
        else
            null,
        .xor => if (isZero(binary.rhs))
            binary.lhs
        else if (isZero(binary.lhs))
            binary.rhs
        else if (binary.lhs.eql(binary.rhs))
            .{ .int = 0 }
        else
            null,
        .shl, .lshr, .ashr => if (isZero(binary.rhs))
            binary.lhs
        else if (isZero(binary.lhs))
            .{ .int = 0 }
        else
            null,
    };
}

fn foldBinaryConstants(binary: ir.BinaryInst) ?ir.Value {
    const lhs = binary.lhs.int;
    const rhs = binary.rhs.int;
    return switch (binary.op) {
        .add => .{ .int = lhs + rhs },
        .sub => .{ .int = lhs - rhs },
        .mul => .{ .int = lhs * rhs },
        .@"and" => .{ .int = lhs & rhs },
        .@"or" => .{ .int = lhs | rhs },
        .xor => .{ .int = lhs ^ rhs },
        .shl, .lshr, .ashr => if (rhs == 0)
            .{ .int = lhs }
        else if (lhs == 0)
            .{ .int = 0 }
        else
            null,
    };
}

fn foldIcmp(icmp: ir.IcmpInst) ?ir.Value {
    if (icmp.lhs == .int and icmp.rhs == .int) {
        return foldIcmpConstants(icmp);
    }

    if (icmp.lhs.eql(icmp.rhs)) {
        return .{ .int = switch (icmp.predicate) {
            .eq => 1,
            .ne => 0,
            .sgt, .slt, .ugt, .ult => 0,
            .sge, .sle, .uge, .ule => 1,
        } };
    }

    return null;
}

fn foldIcmpConstants(icmp: ir.IcmpInst) ?ir.Value {
    const lhs = icmp.lhs.int;
    const rhs = icmp.rhs.int;
    const result = switch (icmp.predicate) {
        .eq => lhs == rhs,
        .ne => lhs != rhs,
        .sgt => lhs > rhs,
        .sge => lhs >= rhs,
        .slt => lhs < rhs,
        .sle => lhs <= rhs,
        .ugt, .uge, .ult, .ule => blk: {
            const lhs_unsigned = unsignedInt(lhs, icmp.operand_ty) orelse return null;
            const rhs_unsigned = unsignedInt(rhs, icmp.operand_ty) orelse return null;
            break :blk switch (icmp.predicate) {
                .ugt => lhs_unsigned > rhs_unsigned,
                .uge => lhs_unsigned >= rhs_unsigned,
                .ult => lhs_unsigned < rhs_unsigned,
                .ule => lhs_unsigned <= rhs_unsigned,
                .eq, .ne, .sgt, .sge, .slt, .sle => unreachable,
            };
        },
    };
    return .{ .int = @intFromBool(result) };
}

fn unsignedInt(value: i128, ty: ir.Type) ?u128 {
    const bits = switch (ty) {
        .int => |bits| bits,
        .ptr => return null,
    };
    if (bits >= 128) return null;
    if (value >= 0) return @intCast(value);
    const modulus: i128 = @as(i128, 1) << @intCast(bits);
    return @intCast(modulus + value);
}

fn foldSelect(select: ir.SelectInst) ?ir.Value {
    if (select.true_value.eql(select.false_value)) return select.true_value;
    if (select.cond == .int) return if (select.cond.int == 0) select.false_value else select.true_value;
    return null;
}

fn isZero(value: ir.Value) bool {
    return value == .int and value.int == 0;
}

fn isOne(value: ir.Value) bool {
    return value == .int and value.int == 1;
}

fn isAllOnes(value: ir.Value) bool {
    return value == .int and value.int == -1;
}
