//! Scalar bit intrinsics expanded into native-width operations. All shifts are
//! defined even at zero and at multiples of the logical width; private calls
//! omit advisory facts that do not describe their widened result.
const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("scalar_forms.zig");
const attrs = @import("intrinsic_attrs.zig");

pub const Operation = enum { ctpop, cttz, ctlz, bswap, abs, fshl, fshr };

pub fn operation(call: ir.CallInst) ?Operation {
    if (!std.mem.startsWith(u8, call.callee, "llvm.") or call.ret_ty != .int or call.ret_ty.int == 0 or
        call.ret_ty.int > 128) return null;
    const bits = call.ret_ty.int;
    var buffer: [48]u8 = undefined;
    inline for (std.meta.tags(Operation)) |op| {
        const name = std.fmt.bufPrint(&buffer, "llvm.{s}.i{d}", .{ @tagName(op), bits }) catch return null;
        if (std.mem.eql(u8, call.callee, name)) {
            if (bits > 64 and op != .bswap and !(bits == 128 and (op == .ctlz or op == .cttz or op == .fshl)) and
                !(bits < 128 and (op == .abs or op == .ctlz or op == .ctpop or op == .cttz))) return null;
            if (!attrs.scalarIntegerCallSupported(call)) return null;
            const flag = op == .cttz or op == .ctlz or op == .abs;
            if (call.args.items.len != (if (flag) @as(usize, 2) else if (op == .fshl or op == .fshr) @as(usize, 3) else @as(usize, 1))) return null;
            for (call.args.items, 0..) |arg, index| {
                const expected: ir.Type = if (flag and index == 1) .{ .int = 1 } else call.ret_ty;
                if (!arg.ty.eql(expected) or (arg.value != .named and arg.value != .int)) return null;
                if (arg.value == .named and std.mem.startsWith(u8, arg.value.named, "@")) return null;
                if (arg.value == .int and expected.int < 128 and (arg.value.int < -(@as(i128, 1) << @as(u7, @intCast(expected.int - 1))) or
                    (arg.value.int >= 0 and @as(u128, @intCast(arg.value.int)) >= (@as(u128, 1) << @as(u7, @intCast(expected.int)))))) return null;
                if (flag and index == 1 and (arg.value != .int or (arg.value.int != 0 and arg.value.int != 1))) return null;
            }
            if (bits == 128 and op == .fshl and call.args.items[2].value != .int) return null;
            // Keep existing native instruction paths. The general expansion
            // handles missing widths and variable funnel counts.
            if (op == .ctpop and bits == 64) return null;
            if (op == .cttz and (bits == 32 or bits == 64)) return null;
            if (op == .ctlz and (bits == 32 or bits == 64)) return null;
            if (op == .abs and (bits == 32 or bits == 64) and call.args.items[1].value.int == 0) return null;
            if (op == .bswap and (bits % 16 != 0 or bits == 16 or bits == 32 or bits == 64)) return null;
            if (op == .fshl and bits == 32 and call.args.items[2].value == .int and call.ret_attrs == null) {
                var plain = true;
                for (call.args.items) |arg| plain = plain and arg.attrs == null;
                if (plain) return null;
            }
            return op;
        }
    }
    return null;
}

const Builder = struct {
    allocator: std.mem.Allocator,
    function: ir.Function,
    block: *ir.BasicBlock,
    serial: *forms.TemporaryNames,
    wide: ir.Type,

    fn emit(b: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const name = try forms.temporary(b.allocator, b.function, b.serial);
        try b.block.instructions.append(b.allocator, .{ .result = name, .kind = kind });
        return .{ .named = name };
    }

    fn binary(b: Builder, op: ir.BinaryOp, lhs: ir.Value, rhs: ir.Value) !ir.Value {
        return b.emit(.{ .binary = .{ .op = op, .ty = b.wide, .lhs = lhs, .rhs = rhs } });
    }

    fn widen(b: Builder, bits: u16, value: ir.Value) !ir.Value {
        if (value == .int) return b.binary(.add, .{ .int = value.int & @as(i128, @intCast((@as(u128, 1) << @as(u7, @intCast(bits))) - 1)) }, .{ .int = 0 });
        if (bits == b.wide.int) return value;
        return b.emit(.{ .cast = .{ .op = .zext, .from_ty = .{ .int = bits }, .value = value, .to_ty = b.wide } });
    }

    fn call(b: Builder, op: Operation, value: ir.Value, flag: bool) !ir.Value {
        var intrinsic: ir.CallInst = .{ .callee = try std.fmt.allocPrint(b.allocator, "llvm.{s}.i{d}", .{ @tagName(op), b.wide.int }), .ret_ty = b.wide, .args = .empty };
        try intrinsic.args.append(b.allocator, .{ .ty = b.wide, .value = value });
        if (flag) try intrinsic.args.append(b.allocator, .{ .ty = .{ .int = 1 }, .value = .{ .int = 0 } });
        return b.emit(.{ .call = intrinsic });
    }

    fn select(b: Builder, condition: ir.Value, yes: ir.Value, no: ir.Value) !ir.Value {
        return b.emit(.{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = condition, .ty = b.wide, .true_value = yes, .false_value = no } });
    }

    fn compare(b: Builder, predicate: ir.IcmpPredicate, lhs: ir.Value, rhs: ir.Value) !ir.Value {
        return b.emit(.{ .icmp = .{ .predicate = predicate, .operand_ty = b.wide, .lhs = lhs, .rhs = rhs } });
    }
};

pub fn expand(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, inst: ir.Instruction, op: Operation) !void {
    const call = inst.kind.call;
    const bits = call.ret_ty.int;
    const b: Builder = .{ .allocator = allocator, .function = function, .block = block, .serial = serial, .wide = .{ .int = if (op == .ctpop or bits >= 32) 64 else 32 } };
    if (bits > 64 and bits < 128 and op != .bswap) {
        const pair: ir.Type = .{ .int = 128 };
        const word: ir.Type = .{ .int = 64 };
        var p = b;
        p.wide = pair;
        const input = if (call.args.items[0].value == .int)
            try @import("binary128_arithmetic.zig").materializeIntegerArgument(allocator, function, block, serial, .{ .op = .uitofp, .from_ty = pair, .value = .{ .int = call.args.items[0].value.int & @as(i128, @intCast((@as(u128, 1) << @as(u7, @intCast(bits))) - 1)) }, .to_ty = .fp128 })
        else
            try p.widen(bits, call.args.items[0].value);
        const answer = switch (op) {
            .abs => blk: {
                const sign = try p.binary(.ashr, try p.binary(.shl, input, .{ .int = 128 - bits }), .{ .int = 127 });
                break :blk try p.binary(.sub, try p.binary(.xor, input, sign), sign);
            },
            .ctlz => try p.binary(.sub, try p.call(.ctlz, input, true), .{ .int = 128 - bits }),
            .ctpop => try p.call(.ctpop, input, false),
            .cttz => blk: {
                const low = try p.emit(.{ .cast = .{ .op = .trunc, .from_ty = pair, .value = input, .to_ty = word } });
                const high = try p.emit(.{ .cast = .{ .op = .trunc, .from_ty = pair, .value = try p.binary(.lshr, input, .{ .int = 64 }), .to_ty = word } });
                const low_count = try b.call(.cttz, low, true);
                const high_count = try b.binary(.add, try b.call(.cttz, high, true), .{ .int = 64 });
                const count = try b.select(try b.compare(.eq, low, .{ .int = 0 }), high_count, low_count);
                const wide = try p.emit(.{ .cast = .{ .op = .zext, .from_ty = word, .value = count, .to_ty = pair } });
                break :blk try p.select(try p.compare(.eq, input, .{ .int = 0 }), .{ .int = bits }, wide);
            },
            else => unreachable,
        };
        try block.instructions.append(allocator, .{ .result = inst.result, .kind = .{ .cast = .{ .op = .trunc, .from_ty = pair, .value = answer, .to_ty = call.ret_ty } } });
        return;
    }
    if (op == .abs and (bits == 32 or bits == 64)) {
        // A fixed result for INT_MIN refines the true-flag poison case. Keep
        // the existing native abs path; do not mutate borrowed argument lists.
        var replacement = inst;
        replacement.kind.call.args = try call.args.clone(allocator);
        if (call.args.items[0].value == .int) {
            const mask = (@as(i128, 1) << @as(u7, @intCast(bits))) - 1;
            replacement.kind.call.args.items[0].value = try b.emit(.{ .binary = .{
                .op = .add,
                .ty = call.ret_ty,
                .lhs = .{ .int = call.args.items[0].value.int & mask },
                .rhs = .{ .int = 0 },
            } });
        }
        replacement.kind.call.args.items[1].value = .{ .int = 0 };
        replacement.kind.call.ret_attrs = null;
        for (replacement.kind.call.args.items) |*arg| arg.attrs = null;
        try block.instructions.append(allocator, replacement);
        return;
    }
    if (bits > 64 and op == .bswap) {
        const word: ir.Type = .{ .int = 64 };
        const pair: ir.Type = .{ .int = 128 };
        const input = call.args.items[0].value;
        var lo: ir.Value = undefined;
        var hi: ir.Value = undefined;
        if (input == .int) {
            const raw = @as(u128, @bitCast(input.int)) & (if (bits == 128) std.math.maxInt(u128) else (@as(u128, 1) << @as(u7, @intCast(bits))) - 1);
            lo = try b.binary(.add, .{ .int = @as(u64, @truncate(raw)) }, .{ .int = 0 });
            hi = try b.binary(.add, .{ .int = @as(u64, @truncate(raw >> 64)) }, .{ .int = 0 });
        } else {
            const wide = if (bits == 128) input else try b.emit(.{ .cast = .{ .op = .zext, .from_ty = call.ret_ty, .value = input, .to_ty = pair } });
            lo = try b.emit(.{ .cast = .{ .op = .trunc, .from_ty = pair, .value = wide, .to_ty = word } });
            hi = try b.emit(.{ .cast = .{ .op = .trunc, .from_ty = pair, .value = try b.emit(.{ .binary = .{ .op = .lshr, .ty = pair, .lhs = wide, .rhs = .{ .int = 64 } } }), .to_ty = word } });
        }
        const lower = try b.emit(.{ .cast = .{ .op = .zext, .from_ty = word, .value = try b.call(.bswap, hi, false), .to_ty = pair } });
        const upper = try b.emit(.{ .cast = .{ .op = .zext, .from_ty = word, .value = try b.call(.bswap, lo, false), .to_ty = pair } });
        const joined = try b.emit(.{ .binary = .{ .op = .@"or", .ty = pair, .lhs = lower, .rhs = try b.emit(.{ .binary = .{ .op = .shl, .ty = pair, .lhs = upper, .rhs = .{ .int = 64 } } }) } });
        const shifted = if (bits == 128) joined else try b.emit(.{ .binary = .{ .op = .lshr, .ty = pair, .lhs = joined, .rhs = .{ .int = 128 - bits } } });
        try block.instructions.append(allocator, .{ .result = inst.result, .kind = if (bits == 128)
            .{ .binary = .{ .op = .add, .ty = pair, .lhs = shifted, .rhs = .{ .int = 0 } } }
        else
            .{ .cast = .{ .op = .trunc, .from_ty = pair, .value = shifted, .to_ty = call.ret_ty } } });
        return;
    }
    if (bits == 128 and op == .fshl) {
        const pair: ir.Type = .{ .int = 128 };
        const shift: u7 = @truncate(@as(u128, @bitCast(call.args.items[2].value.int)));
        const lhs = call.args.items[0].value;
        const rhs = call.args.items[1].value;
        const al = try wordPart(b, lhs, false);
        const ah = try wordPart(b, lhs, true);
        const bl = try wordPart(b, rhs, false);
        const bh = try wordPart(b, rhs, true);
        const low = if (shift == 0) al else if (shift == 64) bh else if (shift < 64)
            try b.binary(.@"or", try b.binary(.shl, al, .{ .int = shift }), try b.binary(.lshr, bh, .{ .int = 64 - @as(u8, shift) }))
        else
            try b.binary(.@"or", try b.binary(.shl, bh, .{ .int = shift - 64 }), try b.binary(.lshr, bl, .{ .int = 128 - @as(u8, shift) }));
        const high = if (shift == 0) ah else if (shift == 64) al else if (shift < 64)
            try b.binary(.@"or", try b.binary(.shl, ah, .{ .int = shift }), try b.binary(.lshr, al, .{ .int = 64 - @as(u8, shift) }))
        else
            try b.binary(.@"or", try b.binary(.shl, al, .{ .int = shift - 64 }), try b.binary(.lshr, bh, .{ .int = 128 - @as(u8, shift) }));
        const lower = try b.emit(.{ .cast = .{ .op = .zext, .from_ty = b.wide, .value = low, .to_ty = pair } });
        const upper = try b.emit(.{ .cast = .{ .op = .zext, .from_ty = b.wide, .value = high, .to_ty = pair } });
        const shifted = try b.emit(.{ .binary = .{ .op = .shl, .ty = pair, .lhs = upper, .rhs = .{ .int = 64 } } });
        try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .binary = .{ .op = .@"or", .ty = pair, .lhs = lower, .rhs = shifted } } });
        return;
    }
    if (bits == 128) {
        std.debug.assert(op == .ctlz or op == .cttz);
        const word: ir.Type = .{ .int = 64 };
        const pair: ir.Type = .{ .int = 128 };
        const input = call.args.items[0].value;
        const lo = if (input == .int)
            try b.binary(.add, .{ .int = @as(u64, @truncate(@as(u128, @bitCast(input.int)))) }, .{ .int = 0 })
        else
            try b.emit(.{ .cast = .{ .op = .trunc, .from_ty = pair, .value = input, .to_ty = word } });
        const hi = if (input == .int)
            try b.binary(.add, .{ .int = @as(u64, @truncate(@as(u128, @bitCast(input.int)) >> 64)) }, .{ .int = 0 })
        else
            try b.emit(.{ .cast = .{ .op = .trunc, .from_ty = pair, .value = try b.emit(.{ .binary = .{ .op = .lshr, .ty = pair, .lhs = input, .rhs = .{ .int = 64 } } }), .to_ty = word } });
        // Both speculative counts are defined at zero. A zero high word
        // contributes64 plus the low count, yielding128 for an all-zero pair.
        const high_count = try b.call(op, hi, true);
        const low_count = try b.call(op, lo, true);
        const value = if (op == .ctlz)
            try b.select(try b.compare(.ne, hi, .{ .int = 0 }), high_count, try b.binary(.add, low_count, .{ .int = 64 }))
        else
            try b.select(try b.compare(.ne, lo, .{ .int = 0 }), low_count, try b.binary(.add, high_count, .{ .int = 64 }));
        try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .cast = .{ .op = .zext, .from_ty = word, .value = value, .to_ty = pair } } });
        return;
    }
    const input = try b.widen(bits, call.args.items[0].value);
    const value = switch (op) {
        .ctpop => try b.call(.ctpop, input, false),
        .cttz => try b.call(.cttz, try b.binary(.@"or", input, .{ .int = @as(i128, 1) << @as(u7, @intCast(bits)) }), true),
        .ctlz => try b.binary(.sub, try b.call(.ctlz, input, true), .{ .int = b.wide.int - bits }),
        .bswap => try b.binary(.lshr, try b.call(.bswap, input, false), .{ .int = b.wide.int - bits }),
        .abs => try b.select(try b.compare(.uge, input, .{ .int = @as(i128, 1) << @as(u7, @intCast(bits - 1)) }), try b.binary(.sub, .{ .int = 0 }, input), input),
        .fshl => blk: {
            const rhs = try b.widen(bits, call.args.items[1].value);
            const amount = call.args.items[2].value;
            if (amount == .int) {
                const shift = @mod(amount.int & ((@as(i128, 1) << @as(u7, @intCast(bits))) - 1), bits);
                if (shift == 0) break :blk input;
                break :blk try b.binary(.@"or", try b.binary(.shl, input, .{ .int = shift }), try b.binary(.lshr, rhs, .{ .int = bits - shift }));
            }
            const count = try b.widen(bits, amount);
            const reduced = try b.binary(if (std.math.isPowerOfTwo(bits)) .@"and" else .urem, count, .{ .int = if (std.math.isPowerOfTwo(bits)) bits - 1 else bits });
            const inverse = try b.binary(.@"and", try b.binary(.sub, .{ .int = bits }, reduced), .{ .int = b.wide.int - 1 });
            const left = try b.binary(.shl, input, reduced);
            const right = try b.binary(.lshr, rhs, inverse);
            // At zero the rhs contribution is zero, including a native-width
            // count where the masked inverse is also zero.
            const tail = try b.select(try b.compare(.ne, reduced, .{ .int = 0 }), right, .{ .int = 0 });
            break :blk try b.binary(.@"or", left, tail);
        },
        .fshr => blk: {
            const rhs = try b.widen(bits, call.args.items[1].value);
            const amount = call.args.items[2].value;
            if (amount == .int) {
                const shift = @mod(amount.int & ((@as(i128, 1) << @as(u7, @intCast(bits))) - 1), bits);
                if (shift == 0) break :blk rhs;
                break :blk try b.binary(.@"or", try b.binary(.shl, input, .{ .int = bits - shift }), try b.binary(.lshr, rhs, .{ .int = shift }));
            }
            const count = try b.widen(bits, amount);
            const reduced = try b.binary(if (std.math.isPowerOfTwo(bits)) .@"and" else .urem, count, .{ .int = if (std.math.isPowerOfTwo(bits)) bits - 1 else bits });
            const inverse = try b.binary(.@"and", try b.binary(.sub, .{ .int = bits }, reduced), .{ .int = b.wide.int - 1 });
            const right = try b.binary(.lshr, rhs, reduced);
            const left = try b.binary(.shl, input, inverse);
            const head = try b.select(try b.compare(.ne, reduced, .{ .int = 0 }), left, .{ .int = 0 });
            break :blk try b.binary(.@"or", right, head);
        },
    };
    try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = if (bits == b.wide.int)
        .{ .binary = .{ .op = .add, .ty = b.wide, .lhs = value, .rhs = .{ .int = 0 } } }
    else
        .{ .cast = .{ .op = .trunc, .from_ty = b.wide, .value = value, .to_ty = call.ret_ty } } });
}

fn wordPart(b: Builder, value: ir.Value, high: bool) !ir.Value {
    if (value == .int) {
        const raw: u128 = @bitCast(value.int);
        return b.binary(.add, .{ .int = @as(u64, @truncate(raw >> @as(u7, if (high) 64 else 0))) }, .{ .int = 0 });
    }
    const pair: ir.Type = .{ .int = 128 };
    const source = if (high) try b.emit(.{ .binary = .{ .op = .lshr, .ty = pair, .lhs = value, .rhs = .{ .int = 64 } } }) else value;
    return b.emit(.{ .cast = .{ .op = .trunc, .from_ty = pair, .value = source, .to_ty = b.wide } });
}

test "integer bit intrinsic admission rejects unsupported signatures and semantic envelopes" {
    for ([_][]const u8{
        "musttail call i16 @llvm.ctpop.i16(i16 %value)",
        "call fastcc i16 @llvm.ctpop.i16(i16 %value)",
        "call signext i16 @llvm.ctpop.i16(i16 %value)",
        "call range(i32 0, 17) i16 @llvm.ctpop.i16(i16 %value)",
        "call i16 @llvm.ctpop.i32(i16 %value)",
        "call i16 @llvm.ctpop.i16(i16 inreg %value)",
        "call i16 @llvm.cttz.i16(i16 %value, i1 %flag)",
        "call i16 @llvm.abs.i16(i16 %value, i1 2)",
        "call i16 @llvm.fshl.i16(i16 %value, i16 %value, i32 2)",
        "call i16 @llvm.fshl.i16(i16 %value, i16 %value, i16 65536)",
        "call i16 @llvm.fshl.i16(i16 %value, i16 %value)",
        "call i16 @llvm.fshr.i16(i16 %value,i16 %value,i32 2)",
        "call i16 @llvm.fshr.i16(i16 %value,i16 %value,i16 65536)",
        "musttail call i16 @llvm.fshr.i16(i16 %value,i16 %value,i16 1)",
        "call i128 @llvm.fshr.i128(i128 1,i128 2,i128 3)",
        "call i8 @llvm.bswap.i8(i8 1)",
    }) |source| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i16 @probe(i16 %value, i1 %flag) {{\nentry:\n %result = {s}\n ret i16 %result\n}}\n", .{source});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try std.testing.expect(operation(module.functions.items[0].blocks.items[0].instructions.items[0].kind.call) == null);
    }
}
