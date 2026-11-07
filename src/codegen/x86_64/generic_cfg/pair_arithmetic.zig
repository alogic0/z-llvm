//! Expand two-word integer operations through ordinary scalar SSA operations.
//! Existing pair loads, stores, casts and ABI actions retain their ownership.
const std = @import("std");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const ir = @import("../../../ir.zig");
const forms = @import("scalar_forms.zig");
const word: ir.Type = .{ .int = 64 };
const pair: ir.Type = .{ .int = 128 };
const Parts = struct { lo: ir.Value, hi: ir.Value };

fn operand(value: ir.Value) bool {
    return value == .int or (value == .named and !std.mem.startsWith(u8, value.named, "@"));
}

const Builder = struct {
    allocator: std.mem.Allocator,
    function: ir.Function,
    block: *ir.BasicBlock,
    serial: *forms.TemporaryNames,
    known_parts: *std.StringHashMap(Parts),

    fn emit(self: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const name = try forms.temporary(self.allocator, self.function, self.serial);
        try self.block.instructions.append(self.allocator, .{ .result = name, .kind = kind });
        return .{ .named = name };
    }
    fn literal(self: Builder, value: ir.Value) !ir.Value {
        if (value == .named) return value;
        return self.emit(.{ .binary = .{ .op = .add, .ty = word, .lhs = value, .rhs = .{ .int = 0 } } });
    }
    fn binary(self: Builder, op: ir.BinaryOp, lhs: ir.Value, rhs: ir.Value) !ir.Value {
        return self.emit(.{ .binary = .{ .op = op, .ty = word, .lhs = try self.literal(lhs), .rhs = if (op == .mul or op == .udiv or op == .urem) try self.literal(rhs) else rhs } });
    }
    fn cast(self: Builder, op: ir.CastOp, from: ir.Type, value: ir.Value, to: ir.Type) !ir.Value {
        return self.emit(.{ .cast = .{ .op = op, .from_ty = from, .value = value, .to_ty = to } });
    }
    fn compare(self: Builder, predicate: ir.IcmpPredicate, lhs: ir.Value, rhs: ir.Value) !ir.Value {
        return self.emit(.{ .icmp = .{ .predicate = predicate, .operand_ty = word, .lhs = try self.literal(lhs), .rhs = try self.literal(rhs) } });
    }
    fn choose(self: Builder, condition: ir.Value, yes: ir.Value, no: ir.Value) !ir.Value {
        return self.emit(.{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = condition, .ty = word, .true_value = try self.literal(yes), .false_value = try self.literal(no) } });
    }
    fn split(self: Builder, value: ir.Value) !Parts {
        if (value == .int) {
            const bits: u128 = @bitCast(value.int);
            return .{ .lo = .{ .int = @as(u64, @truncate(bits)) }, .hi = .{ .int = @as(u64, @truncate(bits >> 64)) } };
        }
        // Expanded definitions already have exact scalar SSA words. Reuse
        // those words across later operations instead of projecting a newly
        // constructed pair and demanding another two-register scratch home.
        if (self.known_parts.get(value.named)) |parts| return parts;
        // A zero extension already proves the upper word. Use its original
        // scalar operand instead of materializing a redundant pair projection.
        for (self.function.blocks.items) |block| for (block.instructions.items) |inst| {
            if (inst.removed or inst.result == null or !ir.identifiers.eql(inst.result.?, value.named) or inst.kind != .cast) continue;
            const source = inst.kind.cast;
            if (source.op == .zext and source.to_ty.eql(pair) and source.from_ty == .int and source.from_ty.int > 0 and source.from_ty.int <= 64 and operand(source.value)) {
                const low = if (source.from_ty.eql(word)) source.value else try self.cast(.zext, source.from_ty, source.value, word);
                return .{ .lo = low, .hi = .{ .int = 0 } };
            }
        };
        const lo = try self.cast(.trunc, pair, value, word);
        const shifted = try self.emit(.{ .binary = .{ .op = .lshr, .ty = pair, .lhs = value, .rhs = .{ .int = 64 } } });
        return .{ .lo = lo, .hi = try self.cast(.trunc, pair, shifted, word) };
    }
    fn finish(self: Builder, original: ir.Instruction, parts: Parts) !void {
        const lo = try self.cast(.zext, word, try self.literal(parts.lo), pair);
        const hi = try self.cast(.zext, word, try self.literal(parts.hi), pair);
        const shifted = try self.emit(.{ .binary = .{ .op = .shl, .ty = pair, .lhs = hi, .rhs = .{ .int = 64 } } });
        var copy = original;
        copy.kind = .{ .binary = .{ .op = .@"or", .ty = pair, .lhs = lo, .rhs = shifted } };
        try self.block.instructions.append(self.allocator, copy);
        try self.known_parts.put(original.result.?, parts);
    }
    fn sign(self: Builder, parts: Parts) !ir.Value {
        return self.binary(.ashr, parts.hi, .{ .int = 63 });
    }
    fn conditionalNegate(self: Builder, parts: Parts, sign_mask: ir.Value) !Parts {
        const flipped_lo = try self.binary(.xor, parts.lo, sign_mask);
        const increment = try self.binary(.@"and", sign_mask, .{ .int = 1 });
        const lo = try self.binary(.add, flipped_lo, increment);
        const carry = try self.cast(.zext, .{ .int = 1 }, try self.compare(.ult, lo, flipped_lo), word);
        const flipped_hi = try self.binary(.xor, parts.hi, sign_mask);
        return .{ .lo = lo, .hi = try self.binary(.add, flipped_hi, carry) };
    }
    fn multiplyWords(self: Builder, a: ir.Value, b: ir.Value) !Parts {
        // Base-2^32 products keep every intermediate within a 64-bit word.
        const mask: ir.Value = .{ .int = 0xffffffff };
        const a0 = try self.binary(.@"and", a, mask);
        const a1 = try self.binary(.lshr, a, .{ .int = 32 });
        const b0 = try self.binary(.@"and", b, mask);
        const b1 = try self.binary(.lshr, b, .{ .int = 32 });
        const p00 = try self.binary(.mul, a0, b0);
        const t = try self.binary(.add, try self.binary(.mul, a1, b0), try self.binary(.lshr, p00, .{ .int = 32 }));
        const u = try self.binary(.add, try self.binary(.mul, a0, b1), try self.binary(.@"and", t, mask));
        const high_product = try self.binary(.mul, a1, b1);
        const high_carries = try self.binary(.add, try self.binary(.lshr, t, .{ .int = 32 }), try self.binary(.lshr, u, .{ .int = 32 }));
        return .{ .lo = try self.binary(.mul, a, b), .hi = try self.binary(.add, high_product, high_carries) };
    }
    fn unsignedDivide(self: Builder, parts: Parts, denominator: u32, remainder: bool) !Parts {
        const digits = [_]ir.Value{
            try self.binary(.lshr, parts.hi, .{ .int = 32 }),
            try self.binary(.@"and", parts.hi, .{ .int = 0xffffffff }),
            try self.binary(.lshr, parts.lo, .{ .int = 32 }),
            try self.binary(.@"and", parts.lo, .{ .int = 0xffffffff }),
        };
        var quotient: [4]ir.Value = undefined;
        var rest: ir.Value = .{ .int = 0 };
        for (digits, 0..) |digit, i| {
            const current = try self.binary(.@"or", try self.binary(.shl, rest, .{ .int = 32 }), digit);
            quotient[i] = try self.binary(.udiv, current, .{ .int = denominator });
            rest = try self.binary(.urem, current, .{ .int = denominator });
        }
        if (remainder) return .{ .lo = rest, .hi = .{ .int = 0 } };
        return .{
            .lo = try self.binary(.@"or", try self.binary(.shl, quotient[2], .{ .int = 32 }), quotient[3]),
            .hi = try self.binary(.@"or", try self.binary(.shl, quotient[0], .{ .int = 32 }), quotient[1]),
        };
    }
    fn shift(self: Builder, op: ir.BinaryOp, parts: Parts, count: ir.Value) !Parts {
        // Every defined i128 shift count is below 128, so only its low word is
        // consumed. Do not create an unused high-word projection.
        const low_count = if (count == .int) (try self.split(count)).lo else try self.cast(.trunc, pair, count, word);
        const small = try self.compare(.ult, low_count, .{ .int = 64 });
        const n = try self.binary(.@"and", low_count, .{ .int = 63 });
        const nonzero = try self.compare(.ne, n, .{ .int = 0 });
        const opposite = try self.binary(.@"and", try self.binary(.sub, .{ .int = 64 }, n), .{ .int = 63 });
        if (op == .shl) {
            const lo = try self.binary(.shl, parts.lo, n);
            const cross = try self.choose(nonzero, try self.binary(.lshr, parts.lo, opposite), .{ .int = 0 });
            const hi = try self.binary(.@"or", try self.binary(.shl, parts.hi, n), cross);
            return .{ .lo = try self.choose(small, lo, .{ .int = 0 }), .hi = try self.choose(small, hi, lo) };
        }
        const hi = try self.binary(op, parts.hi, n);
        const cross = try self.choose(nonzero, try self.binary(.shl, parts.hi, opposite), .{ .int = 0 });
        const lo = try self.binary(.@"or", try self.binary(.lshr, parts.lo, n), cross);
        const fill = if (op == .ashr) try self.sign(parts) else ir.Value{ .int = 0 };
        return .{ .lo = try self.choose(small, lo, hi), .hi = try self.choose(small, hi, fill) };
    }
};

fn divisor(value: ir.BinaryInst) ?u32 {
    if (value.rhs != .int) return null;
    const signed = value.op == .sdiv or value.op == .srem;
    const number = value.rhs.int;
    if (number == 0 or number < -@as(i128, std.math.maxInt(u32)) or number > std.math.maxInt(u32) or (!signed and number < 0)) return null;
    return @intCast(if (number < 0) -number else number);
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var candidate = Candidate.init(allocator, function);
    var serial: forms.TemporaryNames = .{};
    defer serial.deinit(allocator);
    var known_parts = std.StringHashMap(Parts).init(allocator);
    defer known_parts.deinit();
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        const builder: Builder = .{ .allocator = allocator, .function = function, .block = &block, .serial = &serial, .known_parts = &known_parts };
        for (original.instructions.items, 0..) |inst, instruction_index| {
            if (!inst.removed and inst.result != null) switch (inst.kind) {
                .binary => |value| if (value.ty.eql(pair) and operand(value.lhs) and operand(value.rhs)) {
                    const expanded = switch (value.op) {
                        .add, .sub, .mul, .@"and", .xor => true,
                        .@"or" => value.lhs == .int or value.rhs == .int,
                        .shl => value.rhs == .named or value.rhs.int != 64,
                        .lshr => value.rhs == .named or value.rhs.int > 64,
                        .ashr => value.rhs == .named or value.rhs.int != 127,
                        .udiv, .urem, .sdiv, .srem => divisor(value) != null,
                        else => false,
                    };
                    if (expanded) {
                        try candidate.begin(&block, block_index, instruction_index);
                        const a = try builder.split(value.lhs);
                        var answer: Parts = undefined;
                        switch (value.op) {
                            .add => {
                                const b = try builder.split(value.rhs);
                                const lo = try builder.binary(.add, a.lo, b.lo);
                                const carry = try builder.cast(.zext, .{ .int = 1 }, try builder.compare(.ult, lo, a.lo), word);
                                answer = .{ .lo = lo, .hi = try builder.binary(.add, try builder.binary(.add, a.hi, b.hi), carry) };
                            },
                            .sub => {
                                const b = try builder.split(value.rhs);
                                const lo = try builder.binary(.sub, a.lo, b.lo);
                                const borrow = try builder.cast(.zext, .{ .int = 1 }, try builder.compare(.ult, a.lo, b.lo), word);
                                answer = .{ .lo = lo, .hi = try builder.binary(.sub, try builder.binary(.sub, a.hi, b.hi), borrow) };
                            },
                            .@"and", .@"or", .xor => {
                                const b = try builder.split(value.rhs);
                                answer = .{ .lo = try builder.binary(value.op, a.lo, b.lo), .hi = try builder.binary(value.op, a.hi, b.hi) };
                            },
                            .mul => {
                                const b = try builder.split(value.rhs);
                                answer = try builder.multiplyWords(a.lo, b.lo);
                                const cross = try builder.binary(.add, try builder.binary(.mul, a.lo, b.hi), try builder.binary(.mul, a.hi, b.lo));
                                answer.hi = try builder.binary(.add, answer.hi, cross);
                            },
                            .shl, .lshr, .ashr => answer = try builder.shift(value.op, a, value.rhs),
                            .udiv, .urem => answer = try builder.unsignedDivide(a, divisor(value).?, value.op == .urem),
                            .sdiv, .srem => {
                                const sign = try builder.sign(a);
                                const magnitude = try builder.conditionalNegate(a, sign);
                                const unsigned = try builder.unsignedDivide(magnitude, divisor(value).?, value.op == .srem);
                                const restored = if (value.op == .sdiv and value.rhs.int < 0) try builder.binary(.xor, sign, .{ .int = -1 }) else sign;
                                answer = try builder.conditionalNegate(unsigned, restored);
                            },
                            else => unreachable,
                        }
                        try builder.finish(inst, answer);
                        continue;
                    }
                },
                .icmp => |cmp| if (cmp.operand_ty.eql(pair) and operand(cmp.lhs) and operand(cmp.rhs)) {
                    try candidate.begin(&block, block_index, instruction_index);
                    const a = try builder.split(cmp.lhs);
                    const b = try builder.split(cmp.rhs);
                    const high_equal = try builder.compare(.eq, a.hi, b.hi);
                    const low_predicate: ir.IcmpPredicate = switch (cmp.predicate) {
                        .slt => .ult,
                        .sle => .ule,
                        .sgt => .ugt,
                        .sge => .uge,
                        else => cmp.predicate,
                    };
                    const low = try builder.cast(.zext, .{ .int = 1 }, try builder.compare(low_predicate, a.lo, b.lo), word);
                    const high = if (cmp.predicate == .eq) ir.Value{ .int = 0 } else if (cmp.predicate == .ne) ir.Value{ .int = 1 } else try builder.cast(.zext, .{ .int = 1 }, try builder.compare(cmp.predicate, a.hi, b.hi), word);
                    const selected = try builder.choose(high_equal, low, high);
                    var copy = inst;
                    copy.kind = .{ .cast = .{ .op = .trunc, .from_ty = word, .value = selected, .to_ty = .{ .int = 1 } } };
                    try block.instructions.append(allocator, copy);
                    continue;
                },
                .select => |select| if (select.ty.eql(pair) and select.cond_ty.eql(.{ .int = 1 }) and select.cond == .named and operand(select.true_value) and operand(select.false_value)) {
                    try candidate.begin(&block, block_index, instruction_index);
                    const a = try builder.split(select.true_value);
                    const b = try builder.split(select.false_value);
                    try builder.finish(inst, .{ .lo = try builder.choose(select.cond, a.lo, b.lo), .hi = try builder.choose(select.cond, a.hi, b.hi) });
                    continue;
                },
                .cast => |cast| if (cast.to_ty.eql(pair) and cast.from_ty == .int and cast.from_ty.int > 0 and cast.from_ty.int < 128 and cast.value == .int and (cast.op == .zext or cast.op == .sext)) {
                    try candidate.begin(&block, block_index, instruction_index);
                    const mask = (@as(u128, 1) << @as(u7, @intCast(cast.from_ty.int))) - 1;
                    var bits = @as(u128, @bitCast(cast.value.int)) & mask;
                    if (cast.op == .sext and bits & (@as(u128, 1) << @as(u7, @intCast(cast.from_ty.int - 1))) != 0) bits |= ~mask;
                    if (bits >> 64 == 0) {
                        // Keep zero extensions in the existing single-pair
                        // action, including constants introduced by aggregate
                        // legalization. A second pair would add false pressure.
                        var copy = inst;
                        copy.kind = .{ .cast = .{ .op = .zext, .from_ty = word, .value = try builder.literal(.{ .int = @intCast(bits) }), .to_ty = pair } };
                        try block.instructions.append(allocator, copy);
                    } else try builder.finish(inst, try builder.split(.{ .int = @bitCast(bits) }));
                    continue;
                } else if (cast.to_ty.eql(pair) and cast.from_ty == .int and cast.from_ty.int > 0 and cast.from_ty.int <= 64 and cast.value == .named and
                    (cast.op == .sext or (cast.op == .zext and cast.from_ty.int < 64)))
                {
                    try candidate.begin(&block, block_index, instruction_index);
                    const low = if (cast.from_ty.eql(word)) cast.value else try builder.cast(cast.op, cast.from_ty, cast.value, word);
                    if (cast.op == .sext) {
                        try builder.finish(inst, .{ .lo = low, .hi = try builder.binary(.ashr, low, .{ .int = 63 }) });
                    } else {
                        var copy = inst;
                        copy.kind = .{ .cast = .{ .op = .zext, .from_ty = word, .value = low, .to_ty = pair } };
                        try block.instructions.append(allocator, copy);
                    }
                    continue;
                } else if (cast.from_ty.eql(pair) and cast.to_ty == .int and cast.to_ty.int > 0 and cast.to_ty.int <= 64 and cast.op == .trunc and cast.value == .int) {
                    try candidate.begin(&block, block_index, instruction_index);
                    const low: ir.Value = .{ .int = @as(u64, @truncate(@as(u128, @bitCast(cast.value.int)))) };
                    var copy = inst;
                    copy.kind = if (cast.to_ty.eql(word))
                        .{ .binary = .{ .op = .add, .ty = word, .lhs = low, .rhs = .{ .int = 0 } } }
                    else
                        .{ .cast = .{ .op = .trunc, .from_ty = word, .value = try builder.literal(low), .to_ty = cast.to_ty } };
                    try block.instructions.append(allocator, copy);
                    continue;
                },
                else => {},
            };
            try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}
