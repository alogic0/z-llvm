//! Ordered/unordered extended80 predicates through exact integer payloads.
const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("scalar_forms.zig");
const carrier: ir.Type = .{ .int = 80 };
const word: ir.Type = .{ .int = 64 };

const Operand = struct { sign: ir.Value, magnitude: ir.Value, nan: ir.Value, zero: ir.Value };
const Builder = struct {
    allocator: std.mem.Allocator,
    function: ir.Function,
    block: *ir.BasicBlock,
    serial: *forms.TemporaryNames,
    fn emit(b: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const name = try forms.temporary(b.allocator, b.function, b.serial);
        try b.block.instructions.append(b.allocator, .{ .result = name, .kind = kind });
        return .{ .named = name };
    }
    fn cast(b: Builder, op: ir.CastOp, from: ir.Type, value: ir.Value, to: ir.Type) !ir.Value {
        return b.emit(.{ .cast = .{ .op = op, .from_ty = from, .value = value, .to_ty = to } });
    }
    fn binary(b: Builder, ty: ir.Type, op: ir.BinaryOp, lhs: ir.Value, rhs: ir.Value) !ir.Value {
        return b.emit(.{ .binary = .{ .op = op, .ty = ty, .lhs = lhs, .rhs = rhs } });
    }
    fn flag(b: Builder, predicate: ir.IcmpPredicate, lhs: ir.Value, rhs: ir.Value) !ir.Value {
        const condition = try b.emit(.{ .icmp = .{ .predicate = predicate, .operand_ty = carrier, .lhs = lhs, .rhs = rhs } });
        return b.cast(.zext, .{ .int = 1 }, condition, word);
    }
    fn combine(b: Builder, op: ir.BinaryOp, lhs: ir.Value, rhs: ir.Value) !ir.Value {
        return b.binary(word, op, lhs, rhs);
    }
    fn not(b: Builder, value: ir.Value) !ir.Value {
        return b.combine(.xor, value, .{ .int = 1 });
    }
    fn choose(b: Builder, ty: ir.Type, flag_word: ir.Value, yes: ir.Value, no: ir.Value) !ir.Value {
        return b.emit(.{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = try b.cast(.trunc, word, flag_word, .{ .int = 1 }), .ty = ty, .true_value = yes, .false_value = no } });
    }
    fn operand(b: Builder, raw: ir.Value) !Operand {
        const sign = try b.cast(.trunc, carrier, try b.binary(carrier, .lshr, raw, .{ .int = 79 }), word);
        const magnitude = try b.binary(carrier, .@"and", raw, .{ .int = (@as(i128, 1) << 79) - 1 });
        const exponent = try b.binary(carrier, .lshr, magnitude, .{ .int = 64 });
        const integer_bit = try b.flag(.ne, try b.binary(carrier, .@"and", magnitude, .{ .int = @as(i128, 1) << 63 }), .{ .int = 0 });
        const exponent_nonzero = try b.flag(.ne, exponent, .{ .int = 0 });
        const unsupported = try b.combine(.@"and", exponent_nonzero, try b.not(integer_bit));
        const fraction = try b.binary(carrier, .@"and", magnitude, .{ .int = (@as(i128, 1) << 63) - 1 });
        const special = try b.flag(.eq, exponent, .{ .int = 0x7fff });
        const nan = try b.combine(.@"or", unsupported, try b.combine(.@"and", special, try b.flag(.ne, fraction, .{ .int = 0 })));
        // x87 pseudo-denormals encode the same value as exponent one with the
        // explicit integer bit set; compare their canonical magnitudes.
        const pseudo = try b.combine(.@"and", try b.not(exponent_nonzero), integer_bit);
        const canonical = try b.choose(carrier, pseudo, try b.binary(carrier, .@"or", magnitude, .{ .int = @as(i128, 1) << 64 }), magnitude);
        return .{ .sign = sign, .magnitude = canonical, .nan = nan, .zero = try b.flag(.eq, magnitude, .{ .int = 0 }) };
    }
};

pub fn emit(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, original: ir.Instruction, lhs: ir.Value, rhs: ir.Value) !void {
    const b: Builder = .{ .allocator = allocator, .function = function, .block = block, .serial = serial };
    const x = try b.operand(lhs);
    const y = try b.operand(rhs);
    const unordered = try b.combine(.@"or", x.nan, y.nan);
    const ordered = try b.not(unordered);
    const both_zero = try b.combine(.@"and", x.zero, y.zero);
    const different_sign = try b.combine(.xor, x.sign, y.sign);
    const equal = try b.combine(.@"or", both_zero, try b.combine(.@"and", try b.not(different_sign), try b.flag(.eq, x.magnitude, y.magnitude)));
    const magnitude_less = try b.flag(.ult, x.magnitude, y.magnitude);
    const magnitude_greater = try b.flag(.ugt, x.magnitude, y.magnitude);
    const same_sign_less = try b.choose(word, x.sign, magnitude_greater, magnitude_less);
    const negative_less = try b.combine(.@"and", x.sign, try b.not(both_zero));
    const less = try b.choose(word, different_sign, negative_less, same_sign_less);
    const greater = try b.not(try b.combine(.@"or", less, equal));
    const value = switch (original.kind.fcmp.predicate) {
        .false => ir.Value{ .int = 0 },
        .true => ir.Value{ .int = 1 },
        .ord => ordered,
        .uno => unordered,
        .oeq => try b.combine(.@"and", equal, ordered),
        .one => try b.combine(.@"and", try b.not(equal), ordered),
        .olt => try b.combine(.@"and", less, ordered),
        .ole => try b.combine(.@"and", try b.combine(.@"or", less, equal), ordered),
        .ogt => try b.combine(.@"and", greater, ordered),
        .oge => try b.combine(.@"and", try b.combine(.@"or", greater, equal), ordered),
        .ueq => try b.combine(.@"or", equal, unordered),
        .une => try b.combine(.@"or", try b.not(equal), unordered),
        .ult => try b.combine(.@"or", less, unordered),
        .ule => try b.combine(.@"or", try b.combine(.@"or", less, equal), unordered),
        .ugt => try b.combine(.@"or", greater, unordered),
        .uge => try b.combine(.@"or", try b.combine(.@"or", greater, equal), unordered),
    };
    var copy = original;
    const materialized = if (value == .named) value else try b.binary(word, .add, value, .{ .int = 0 });
    copy.kind = .{ .cast = .{ .op = .trunc, .from_ty = word, .value = materialized, .to_ty = .{ .int = 1 } } };
    copy.metadata = null;
    try block.instructions.append(allocator, copy);
}
