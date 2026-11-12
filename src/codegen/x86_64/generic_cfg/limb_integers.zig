//! Private bounded u64 limbs. Source types/values and transfer inventories stay
//! immutable. Exact byte accesses and separately split LLVM integer arguments
//! retain their physical ABI; three-register returns remain closed.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const forms = @import("scalar_forms.zig");
const raw = @import("../../../ir/wide_integers.zig");
const helpers = @import("composed_helpers.zig");
const addresses = @import("../symbol_address.zig");
const stack = @import("stack_arguments.zig");
const word: ir.Type = .{ .int = 64 };
const boolean: ir.Type = .{ .int = 1 };
const max_words = 8;

fn divisionTarget(op: ir.BinaryOp) []const u8 {
    return switch (op) {
        .udiv => "__udivei4",
        .urem => "__umodei4",
        .sdiv => "__divei4",
        .srem => "__modei4",
        else => unreachable,
    };
}
fn validateDivisionProvider(context: ?*const machine.ReadOnlyModuleContext, callee: []const u8) !void {
    const ctx = context orelse return error.UnsupportedLimbInteger;
    // These are reserved runtime dependencies, not Source definitions whose
    // reachability or implementation may be silently replaced by a libcall.
    for (ctx.functions) |function| if (ir.identifiers.eql(function.name, callee)) return error.UnsupportedLimbInteger;
    for (ctx.aliases) |alias| if (ir.identifiers.eql(alias.name, callee)) return error.UnsupportedLimbInteger;
    if (ctx.findGlobal(callee) != null) return error.UnsupportedLimbInteger;
    var declared = false;
    for (ctx.declarations) |decl| if (ir.identifiers.eql(decl.name, callee)) {
        if (declared or decl.ret_ty != .void or decl.ret_attrs != null or decl.calling_conv != null or decl.is_varargs or decl.params.items.len != 4) return error.UnsupportedLimbInteger;
        if (decl.linkage != .default and decl.linkage != .external) return error.UnsupportedLimbInteger;
        for (decl.params.items, 0..) |param, i| if (!param.ty.eql(if (i == 3) word else .ptr) or param.attrs != null) return error.UnsupportedLimbInteger;
        declared = true;
    };
}

fn wide(ty: ir.Type) bool {
    return (raw.width(ty) orelse 0) > 128;
}
fn width(ty: ir.Type) !u16 {
    const bits = raw.width(ty) orelse return error.UnsupportedLimbInteger;
    if (bits == 0 or bits > max_words * 64) return error.UnsupportedLimbInteger;
    return @intCast(bits);
}
fn mask(bits: u16) u64 {
    return if (bits % 64 == 0) std.math.maxInt(u64) else (@as(u64, 1) << @as(u6, @intCast(bits % 64))) - 1;
}
fn advisory(attrs: ?[]const u8) bool {
    return attrs == null or std.mem.eql(u8, std.mem.trim(u8, attrs.?, " \t"), "noundef");
}
fn allocaAttrs(attrs: ?[]const u8) bool {
    const text = attrs orelse return true;
    var tokens = std.mem.tokenizeAny(u8, text, " ,\t");
    if (!std.mem.eql(u8, tokens.next() orelse return false, "align")) return false;
    const alignment = std.fmt.parseUnsigned(u32, tokens.next() orelse return false, 10) catch return false;
    return alignment != 0 and alignment <= 4096 and std.math.isPowerOfTwo(alignment) and tokens.next() == null;
}
const Parts = struct {
    bits: u16,
    values: [max_words]ir.Value = @splat(.{ .int = 0 }),
    fn count(p: Parts) usize {
        return (p.bits + 63) / 64;
    }
};
const OverflowTuple = struct { value: Parts, flag: ir.Value };
const CheckedKind = struct { bits: u16, op: ir.BinaryOp, signed: bool };
fn tupleBits(ty: ir.Type) ?u16 {
    if (ty != .aggregate) return null;
    var fields = @import("../../../ir/structure.zig").Fields.init(ty.aggregate) orelse return null;
    if (fields.packed_type) return null;
    const first = fields.next() orelse return null;
    if (first.len < 2 or first[0] != 'i' or !std.mem.eql(u8, fields.next() orelse return null, "i1") or fields.next() != null) return null;
    const bits = std.fmt.parseUnsigned(u16, first[1..], 10) catch return null;
    return if (bits > 128 and bits <= max_words * 64) bits else null;
}
fn checkedKind(a: std.mem.Allocator, call: ir.CallInst) !?CheckedKind {
    const bits = tupleBits(call.ret_ty) orelse return null;
    for ([_][]const u8{ "uadd", "usub", "sadd", "ssub" }, 0..) |name, i| {
        if (std.mem.eql(u8, call.callee, try std.fmt.allocPrint(a, "llvm.{s}.with.overflow.i{d}", .{ name, bits })))
            return .{ .bits = bits, .op = if (i % 2 == 0) .add else .sub, .signed = i >= 2 };
    }
    return null;
}
const TupleUses = struct {
    pub const Error = error{UnsupportedLimbInteger};
    tuples: *const std.StringHashMap(OverflowTuple),
    allowed: ?[]const u8 = null,
    pub fn visit(check: TupleUses, value: *const ir.Value, _: ir.Type) Error!void {
        if (value.* == .named and check.tuples.contains(value.named) and (check.allowed == null or !std.mem.eql(u8, check.allowed.?, value.named))) return error.UnsupportedLimbInteger;
        if ((value.* == .constant_expr and std.mem.indexOfScalar(u8, value.constant_expr, '%') != null) or (value.* == .vector and std.mem.indexOfScalar(u8, value.vector, '%') != null)) return error.UnsupportedLimbInteger;
    }
};
const Touched = struct {
    pub const Error = error{};
    found: *bool,
    pub fn visit(t: Touched, _: *const ir.Value, ty: ir.Type) Error!void {
        t.found.* = t.found.* or wide(ty);
    }
};
fn touches(inst: *const ir.Instruction) bool {
    var found = if (inst.resultType()) |ty| wide(ty) else false;
    _ = ir.operands.instruction(inst, Touched{ .found = &found }) catch unreachable;
    if (inst.kind == .alloca) found = found or wide(inst.kind.alloca.allocated_ty);
    if (inst.kind == .gep) found = found or wide(inst.kind.gep.source_ty);
    return found;
}

const Builder = struct {
    a: std.mem.Allocator,
    source: ir.Function,
    block: *ir.BasicBlock,
    names: *forms.TemporaryNames,
    values: *std.StringHashMap(Parts),
    tuples: *std.StringHashMap(OverflowTuple),

    fn emit(b: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const name = try forms.temporary(b.a, b.source, b.names);
        try b.block.instructions.append(b.a, .{ .result = name, .kind = kind });
        return .{ .named = name };
    }
    fn binary(b: Builder, op: ir.BinaryOp, ty: ir.Type, x: ir.Value, y: ir.Value) !ir.Value {
        return b.emit(.{ .binary = .{ .op = op, .ty = ty, .lhs = x, .rhs = y } });
    }
    fn bin(b: Builder, op: ir.BinaryOp, x: ir.Value, y: ir.Value) !ir.Value {
        const lhs = if (x == .int) try b.emit(.{ .binary = .{ .op = .add, .ty = word, .lhs = x, .rhs = .{ .int = 0 } } }) else x;
        const rhs = if (y == .int) try b.emit(.{ .binary = .{ .op = .add, .ty = word, .lhs = y, .rhs = .{ .int = 0 } } }) else y;
        return b.binary(op, word, lhs, rhs);
    }
    fn cmp(b: Builder, predicate: ir.IcmpPredicate, x: ir.Value, y: ir.Value) !ir.Value {
        return b.emit(.{ .icmp = .{ .predicate = predicate, .operand_ty = word, .lhs = x, .rhs = y } });
    }
    fn choose(b: Builder, condition: ir.Value, yes: ir.Value, no: ir.Value) !ir.Value {
        return b.emit(.{ .select = .{ .cond_ty = boolean, .cond = condition, .ty = word, .true_value = yes, .false_value = no } });
    }
    fn cast(b: Builder, op: ir.CastOp, from: ir.Type, value: ir.Value, to: ir.Type) !ir.Value {
        if (from.eql(to)) return value;
        return b.emit(.{ .cast = .{ .op = op, .from_ty = from, .value = value, .to_ty = to } });
    }
    fn address(b: Builder, ptr: ir.Value, offset: usize) !ir.Value {
        if (offset == 0) return ptr;
        var indices: std.ArrayList(ir.GepIndex) = .empty;
        try indices.append(b.a, .{ .ty = word, .value = .{ .int = @intCast(offset) } });
        return b.emit(.{ .gep = .{ .source_ty = .{ .int = 8 }, .ptr = ptr, .indices = indices } });
    }
    fn get(b: Builder, value: ir.Value, ty: ir.Type) !Parts {
        const bits = try width(ty);
        if (wide(ty) and value == .named) {
            const p = b.values.get(value.named) orelse return error.UnsupportedLimbInteger;
            if (p.bits != bits) return error.UnsupportedLimbInteger;
            return p;
        }
        var p: Parts = .{ .bits = bits };
        if (value != .named) {
            const words = raw.decode(b.a, bits, value) catch |err| switch (err) {
                error.OutOfMemory => return err,
                else => return error.UnsupportedLimbInteger,
            };
            defer b.a.free(words);
            for (words, 0..) |v, i| p.values[i] = .{ .int = @intCast(v) };
            return p;
        }
        if (bits <= 64) {
            p.values[0] = try b.cast(.zext, ty, value, word);
        } else if (bits <= 128) {
            p.values[0] = try b.cast(.trunc, ty, value, word);
            const upper = try b.binary(.lshr, ty, value, .{ .int = 64 });
            p.values[1] = try b.cast(.trunc, ty, upper, word);
        } else return error.UnsupportedLimbInteger;
        return p;
    }
    fn normalize(b: Builder, p: *Parts) !void {
        if (p.bits % 64 != 0) {
            const last = p.count() - 1;
            p.values[last] = try b.bin(.@"and", p.values[last], .{ .int = @intCast(mask(p.bits)) });
        }
    }
    fn copy(b: Builder, name: []const u8, ty: ir.Type, value: ir.Value) !void {
        const kind: @FieldType(ir.Instruction, "kind") = if (value == .int)
            .{ .binary = .{ .op = .add, .ty = ty, .lhs = value, .rhs = .{ .int = 0 } } }
        else if (ty == .int and ty.int > 64 and ty.int <= 128)
            .{ .binary = .{ .op = .@"or", .ty = ty, .lhs = value, .rhs = .{ .int = 0 } } }
        else
            .{ .cast = .{ .op = .bitcast, .from_ty = ty, .value = value, .to_ty = ty } };
        try b.block.instructions.append(b.a, .{ .result = name, .kind = kind });
    }
    fn define(b: Builder, name: []const u8, input: Parts) !void {
        const destination = b.values.get(name) orelse return error.UnsupportedLimbInteger;
        if (destination.bits != input.bits) return error.UnsupportedLimbInteger;
        var p = input;
        try b.normalize(&p);
        for (destination.values[0..p.count()], p.values[0..p.count()]) |to, from| try b.copy(to.named, word, from);
    }
    fn narrow(b: Builder, p: Parts, ty: ir.Type) !ir.Value {
        const bits = try width(ty);
        if (bits <= 64) return b.cast(.trunc, word, p.values[0], ty);
        if (bits > 128) return error.UnsupportedLimbInteger;
        const low = try b.cast(.zext, word, p.values[0], ty);
        const high = try b.binary(.shl, ty, try b.cast(.zext, word, p.values[1], ty), .{ .int = 64 });
        return b.binary(.@"or", ty, low, high);
    }
    fn sign(b: Builder, p: Parts) !ir.Value {
        const tail = (p.bits - 1) % 64;
        const top = try b.bin(.shl, p.values[p.count() - 1], .{ .int = 63 - tail });
        return b.bin(.ashr, top, .{ .int = 63 });
    }
    fn resize(b: Builder, p: Parts, bits: u16, signed: bool) !Parts {
        var result: Parts = .{ .bits = bits };
        const fill = if (signed and bits > p.bits) try b.sign(p) else ir.Value{ .int = 0 };
        for (result.values[0..result.count()], 0..) |*v, i| v.* = if (i < p.count()) p.values[i] else fill;
        if (signed and bits > p.bits and p.bits % 64 != 0) {
            const i = p.count() - 1;
            const padding = try b.bin(.@"and", fill, .{ .int = @intCast(~mask(p.bits)) });
            result.values[i] = try b.bin(.@"or", result.values[i], padding);
        }
        try b.normalize(&result);
        return result;
    }
    fn arithmetic(b: Builder, op: ir.BinaryOp, x: Parts, y: Parts) !Parts {
        var result: Parts = .{ .bits = x.bits };
        var carry: ir.Value = .{ .int = 0 };
        for (result.values[0..result.count()], 0..) |*v, i| {
            if (op == .add or op == .sub) {
                const first = try b.bin(op, x.values[i], y.values[i]);
                const c0 = try b.cmp(.ult, if (op == .add) first else x.values[i], if (op == .add) x.values[i] else y.values[i]);
                v.* = try b.bin(op, first, carry);
                const c1 = try b.cmp(.ult, if (op == .add) v.* else first, if (op == .add) first else carry);
                carry = try b.cast(.zext, boolean, try b.binary(.@"or", boolean, c0, c1), word);
            } else switch (op) {
                .@"and", .@"or", .xor => v.* = try b.bin(op, x.values[i], y.values[i]),
                else => return error.UnsupportedLimbInteger,
            }
        }
        return result;
    }
    fn division(b: Builder, op: ir.BinaryOp, x: Parts, y: Parts) !Parts {
        const signed = op == .sdiv or op == .srem;
        const count = x.count();
        const backing_count = try std.math.ceilPowerOfTwo(usize, count);
        const backing: ir.Type = .{ .aggregate = try std.fmt.allocPrint(b.a, "[{d} x i64]", .{backing_count}) };
        const output = try b.emit(.{ .alloca = .{ .allocated_ty = backing, .attrs = "align 8" } });
        const numerator = try b.emit(.{ .alloca = .{ .allocated_ty = backing, .attrs = "align 8" } });
        const denominator = try b.emit(.{ .alloca = .{ .allocated_ty = backing, .attrs = "align 8" } });
        const zero: Parts = .{ .bits = y.bits };
        const is_zero = try b.comparison(.eq, y, zero);
        var safe_y = y;
        for (safe_y.values[0..count], 0..) |*v, i| v.* = try b.choose(is_zero, .{ .int = if (i == 0) 1 else 0 }, v.*);
        const sx: ir.Value = if (signed) try b.sign(x) else .{ .int = 0 };
        const sy: ir.Value = if (signed) try b.sign(safe_y) else .{ .int = 0 };
        for (0..backing_count) |i| {
            var a = if (i < count) x.values[i] else sx;
            var c = if (i < count) safe_y.values[i] else sy;
            if (signed and i + 1 == count and x.bits % 64 != 0) {
                const padding: ir.Value = .{ .int = @intCast(~mask(x.bits)) };
                a = try b.bin(.@"or", a, try b.bin(.@"and", sx, padding));
                c = try b.bin(.@"or", c, try b.bin(.@"and", sy, padding));
            }
            try b.block.instructions.append(b.a, .{ .result = null, .kind = .{ .store = .{ .ty = word, .value = a, .ptr = try b.address(numerator, i * 8), .attrs = .{ .@"align" = 8 } } } });
            try b.block.instructions.append(b.a, .{ .result = null, .kind = .{ .store = .{ .ty = word, .value = c, .ptr = try b.address(denominator, i * 8), .attrs = .{ .@"align" = 8 } } } });
        }
        var args: std.ArrayList(ir.CallArg) = .empty;
        for ([_]ir.Value{ output, numerator, denominator }) |ptr| try args.append(b.a, .{ .ty = .ptr, .value = ptr });
        // The pinned integer ABI rounds byte size to its C integer alignment:
        // e.g.192 bits occupies32 bytes. Use256/512-bit buffers, fill every
        // padding word, and keep Source's logical width unchanged.
        try args.append(b.a, .{ .ty = word, .value = .{ .int = @intCast(backing_count * 64) } });
        try b.block.instructions.append(b.a, .{ .result = null, .kind = .{ .call = .{ .callee = divisionTarget(op), .ret_ty = .void, .args = args } } });
        var result: Parts = .{ .bits = x.bits };
        for (result.values[0..count], 0..) |*v, i| v.* = try b.emit(.{ .load = .{ .ty = word, .ptr = try b.address(output, i * 8), .attrs = .{ .@"align" = 8 } } });
        try b.normalize(&result);
        return result;
    }
    fn checked(b: Builder, call: ir.CallInst, kind: CheckedKind) !OverflowTuple {
        if (call.args.items.len != 2 or call.callee_value != null or call.callee_function_ty != null or call.inline_asm != null or call.raw_args != null or call.operand_bundle != null or call.calling_conv != null or !advisory(call.ret_attrs)) return error.UnsupportedLimbInteger;
        if (call.tail_kind) |tail| if (std.mem.eql(u8, tail, "musttail")) return error.UnsupportedLimbInteger;
        const ty: ir.Type = .{ .int = kind.bits };
        for (call.args.items) |arg| if (!arg.ty.eql(ty) or !advisory(arg.attrs) or arg.abi_x87_memory or arg.abi_split_integer) return error.UnsupportedLimbInteger;
        const x = try b.get(call.args.items[0].value, ty);
        const y = try b.get(call.args.items[1].value, ty);
        var result = try b.arithmetic(kind.op, x, y);
        try b.normalize(&result);
        const flag = if (kind.signed) blk: {
            const sx = try b.sign(x);
            const sy = try b.sign(y);
            const sr = try b.sign(result);
            break :blk try b.binary(.@"and", boolean, try b.cmp(if (kind.op == .add) .eq else .ne, sx, sy), try b.cmp(.ne, sx, sr));
        } else try b.comparison(.ult, if (kind.op == .sub) x else result, if (kind.op == .sub) y else x);
        return .{ .value = result, .flag = flag };
    }
    fn comparison(b: Builder, predicate: ir.IcmpPredicate, input_x: Parts, input_y: Parts) !ir.Value {
        var x = input_x;
        var y = input_y;
        const signed = switch (predicate) {
            .slt, .sle, .sgt, .sge => true,
            else => false,
        };
        if (signed) {
            const top = x.count() - 1;
            const sign_bit: ir.Value = .{ .int = @as(i128, 1) << @as(u6, @intCast((x.bits - 1) % 64)) };
            x.values[top] = try b.bin(.xor, x.values[top], sign_bit);
            y.values[top] = try b.bin(.xor, y.values[top], sign_bit);
        }
        var less: ir.Value = .{ .int = 0 };
        var equal: ir.Value = .{ .int = 1 };
        for (0..x.count()) |i| {
            const eq = try b.cmp(.eq, x.values[i], y.values[i]);
            const lt = try b.cmp(.ult, x.values[i], y.values[i]);
            less = try b.emit(.{ .select = .{ .cond_ty = boolean, .cond = eq, .ty = boolean, .true_value = less, .false_value = lt } });
            equal = try b.binary(.@"and", boolean, equal, eq);
        }
        return switch (predicate) {
            .eq => equal,
            .ne => b.binary(.xor, boolean, equal, .{ .int = 1 }),
            .ult, .slt => less,
            .ule, .sle => b.binary(.@"or", boolean, less, equal),
            .ugt, .sgt => b.binary(.xor, boolean, try b.binary(.@"or", boolean, less, equal), .{ .int = 1 }),
            .uge, .sge => b.binary(.xor, boolean, less, .{ .int = 1 }),
        };
    }
    fn shifted(b: Builder, op: ir.BinaryOp, input: Parts, amount: Parts) !Parts {
        var x = input;
        const signed = op == .ashr;
        const left = op == .shl;
        const fill: ir.Value = if (signed) try b.sign(x) else .{ .int = 0 };
        if (signed and x.bits % 64 != 0) x.values[x.count() - 1] = try b.bin(.@"or", x.values[x.count() - 1], try b.bin(.@"and", fill, .{ .int = @intCast(~mask(x.bits)) }));
        const low = try b.bin(.@"and", amount.values[0], .{ .int = 63 });
        const whole = try b.bin(.lshr, amount.values[0], .{ .int = 6 });
        const complement = try b.bin(.@"and", try b.bin(.sub, .{ .int = 64 }, low), .{ .int = 63 });
        const zero = try b.cmp(.eq, low, .{ .int = 0 });
        var result: Parts = .{ .bits = input.bits };
        for (result.values[0..result.count()], 0..) |*value, i| {
            value.* = fill;
            for (0..x.count()) |j| {
                const index: i32 = if (left) @as(i32, @intCast(i)) - @as(i32, @intCast(j)) else @intCast(i + j);
                const adjacent = index + @as(i32, if (left) -1 else 1);
                const a = if (index >= 0 and index < x.count()) x.values[@intCast(index)] else fill;
                const c = if (adjacent >= 0 and adjacent < x.count()) x.values[@intCast(adjacent)] else fill;
                const main = try b.bin(if (left) .shl else .lshr, a, low);
                const carry = try b.choose(zero, .{ .int = 0 }, try b.bin(if (left) .lshr else .shl, c, complement));
                const part = try b.bin(.@"or", main, carry);
                value.* = try b.choose(try b.cmp(.eq, whole, .{ .int = @intCast(j) }), part, value.*);
            }
        }
        return result;
    }

    fn wordIntrinsic(b: Builder, name: []const u8, value: ir.Value, zero_flag: bool) !ir.Value {
        var args: std.ArrayList(ir.CallArg) = .empty;
        try args.append(b.a, .{ .ty = word, .value = value });
        if (zero_flag) try args.append(b.a, .{ .ty = boolean, .value = .{ .int = 0 } });
        return b.emit(.{ .call = .{ .callee = name, .ret_ty = word, .args = args } });
    }
    fn intrinsic(b: Builder, call: ir.CallInst) !?Parts {
        if (!wide(call.ret_ty) or call.callee_value != null or call.callee_function_ty != null or call.inline_asm != null or call.raw_args != null or call.operand_bundle != null or call.calling_conv != null) return null;
        if (call.tail_kind) |kind| if (std.mem.eql(u8, kind, "musttail")) return null;
        const bits = try width(call.ret_ty);
        const kinds = [_]struct { name: []const u8, arity: usize, flag: bool }{
            .{ .name = "abs", .arity = 2, .flag = true },         .{ .name = "ctpop", .arity = 1, .flag = false },
            .{ .name = "ctlz", .arity = 2, .flag = true },        .{ .name = "cttz", .arity = 2, .flag = true },
            .{ .name = "bitreverse", .arity = 1, .flag = false }, .{ .name = "bswap", .arity = 1, .flag = false },
            .{ .name = "uadd.sat", .arity = 2, .flag = false },   .{ .name = "usub.sat", .arity = 2, .flag = false },
            .{ .name = "sadd.sat", .arity = 2, .flag = false },   .{ .name = "ssub.sat", .arity = 2, .flag = false },
            .{ .name = "fshl", .arity = 3, .flag = false },       .{ .name = "fshr", .arity = 3, .flag = false },
        };
        const kind = for (kinds) |k| {
            if (std.mem.eql(u8, call.callee, try std.fmt.allocPrint(b.a, "llvm.{s}.i{d}", .{ k.name, bits }))) break k;
        } else return null;
        if (call.args.items.len != kind.arity) return null;
        const count_kind = std.mem.eql(u8, kind.name, "ctpop") or std.mem.eql(u8, kind.name, "ctlz") or std.mem.eql(u8, kind.name, "cttz");
        if (!advisory(call.ret_attrs) and !(count_kind and @import("intrinsic_attrs.zig").matchesIntegerRange(call.ret_attrs, bits, 0, @as(u128, bits) + 1))) return null;
        for (call.args.items, 0..) |arg, i| {
            if (!advisory(arg.attrs) or arg.abi_x87_memory or arg.abi_split_integer) return null;
            if (kind.flag and i + 1 == kind.arity) {
                if (!arg.ty.eql(boolean) or arg.value != .int or (arg.value.int != 0 and arg.value.int != 1)) return null;
            } else if (!arg.ty.eql(call.ret_ty)) return null;
        }
        const x = try b.get(call.args.items[0].value, call.ret_ty);
        var result: Parts = .{ .bits = bits };
        if (std.mem.eql(u8, kind.name, "abs")) {
            const sign_fill = try b.sign(x);
            var signs: Parts = .{ .bits = bits };
            for (signs.values[0..signs.count()]) |*v| v.* = sign_fill;
            try b.normalize(&signs);
            result = try b.arithmetic(.sub, try b.arithmetic(.xor, x, signs), signs);
        } else if (count_kind) {
            if (std.mem.eql(u8, kind.name, "ctpop")) {
                var sum: ir.Value = .{ .int = 0 };
                for (x.values[0..x.count()]) |value| sum = try b.bin(.add, sum, try b.wordIntrinsic("llvm.ctpop.i64", value, false));
                result.values[0] = sum;
            } else {
                const leading = std.mem.eql(u8, kind.name, "ctlz");
                var count: ir.Value = .{ .int = bits };
                for (0..x.count()) |step| {
                    const i = if (leading) step else x.count() - 1 - step;
                    const local = try b.wordIntrinsic(if (leading) "llvm.ctlz.i64" else "llvm.cttz.i64", x.values[i], true);
                    const offset: i128 = if (leading) @as(i128, bits) - @as(i128, @intCast((i + 1) * 64)) else @intCast(i * 64);
                    const candidate = try b.bin(.add, local, .{ .int = offset });
                    count = try b.choose(try b.cmp(.eq, x.values[i], .{ .int = 0 }), count, candidate);
                }
                result.values[0] = count;
            }
        } else if (std.mem.eql(u8, kind.name, "bitreverse") or std.mem.eql(u8, kind.name, "bswap")) {
            const bytes = std.mem.eql(u8, kind.name, "bswap");
            if (bytes and bits % 16 != 0) return null;
            var reversed: Parts = .{ .bits = bits };
            for (0..x.count()) |i| reversed.values[i] = try b.wordIntrinsic(if (bytes) "llvm.bswap.i64" else "llvm.bitreverse.i64", x.values[x.count() - 1 - i], false);
            const padding = x.count() * 64 - bits;
            for (result.values[0..result.count()], 0..) |*v, i| {
                if (padding == 0) {
                    v.* = reversed.values[i];
                    continue;
                }
                const low = try b.bin(.lshr, reversed.values[i], .{ .int = @intCast(padding) });
                v.* = if (i + 1 == x.count()) low else try b.bin(.@"or", low, try b.bin(.shl, reversed.values[i + 1], .{ .int = @intCast(64 - padding) }));
            }
        } else if (std.mem.eql(u8, kind.name, "fshl") or std.mem.eql(u8, kind.name, "fshr")) {
            const y = try b.get(call.args.items[1].value, call.ret_ty);
            const amount = try b.get(call.args.items[2].value, call.ret_ty);
            var remainder: ir.Value = .{ .int = 0 };
            const radix: u64 = @intCast((@as(u128, 1) << 64) % bits);
            var i = amount.count();
            while (i != 0) {
                i -= 1;
                const digit = try b.bin(.urem, amount.values[i], .{ .int = bits });
                remainder = try b.bin(.urem, try b.bin(.add, try b.bin(.mul, remainder, .{ .int = radix }), digit), .{ .int = bits });
            }
            var forward: Parts = .{ .bits = bits };
            forward.values[0] = remainder;
            var reverse_amount: Parts = .{ .bits = bits };
            reverse_amount.values[0] = try b.bin(.sub, .{ .int = bits }, remainder);
            const left = std.mem.eql(u8, kind.name, "fshl");
            const low = try b.shifted(if (left) .shl else .lshr, if (left) x else y, forward);
            const high = try b.shifted(if (left) .lshr else .shl, if (left) y else x, reverse_amount);
            result = try b.arithmetic(.@"or", low, high);
        } else {
            const y = try b.get(call.args.items[1].value, call.ret_ty);
            const subtract = std.mem.eql(u8, kind.name, "usub.sat") or std.mem.eql(u8, kind.name, "ssub.sat");
            const signed = kind.name[0] == 's';
            result = try b.arithmetic(if (subtract) .sub else .add, x, y);
            try b.normalize(&result);
            var limit: Parts = .{ .bits = bits };
            const overflow = if (signed) blk: {
                const sx = try b.sign(x);
                const sy = try b.sign(y);
                const sr = try b.sign(result);
                const same = try b.cmp(if (subtract) .ne else .eq, sx, sy);
                const changed = try b.cmp(.ne, sx, sr);
                const negative = try b.cmp(.ne, sx, .{ .int = 0 });
                for (limit.values[0..limit.count()], 0..) |*v, i| {
                    const top = i + 1 == limit.count();
                    const sign_bit = @as(u64, 1) << @as(u6, @intCast((bits - 1) % 64));
                    const positive: u64 = if (top) sign_bit - 1 else std.math.maxInt(u64);
                    v.* = try b.choose(negative, .{ .int = if (top) sign_bit else 0 }, .{ .int = positive });
                }
                break :blk try b.binary(.@"and", boolean, same, changed);
            } else blk: {
                if (!subtract) for (limit.values[0..limit.count()]) |*v| {
                    v.* = .{ .int = std.math.maxInt(u64) };
                };
                break :blk try b.comparison(.ult, if (subtract) x else result, if (subtract) y else x);
            };
            for (result.values[0..result.count()], limit.values[0..limit.count()]) |*v, cap| v.* = try b.choose(overflow, cap, v.*);
        }
        try b.normalize(&result);
        return result;
    }
    fn load(b: Builder, ptr: ir.Value, bits: u16) !Parts {
        var result: Parts = .{ .bits = bits };
        const bytes = (bits + 7) / 8;
        for (result.values[0..result.count()], 0..) |*v, i| {
            const end = @min(bytes, i * 8 + 8);
            var offset = i * 8;
            v.* = .{ .int = 0 };
            while (offset < end) {
                const size: u16 = if (end - offset >= 8) 8 else if (end - offset >= 4) 4 else if (end - offset >= 2) 2 else 1;
                const ty: ir.Type = .{ .int = size * 8 };
                var p = try b.cast(.zext, ty, try b.emit(.{ .load = .{ .ty = ty, .ptr = try b.address(ptr, offset), .attrs = .{ .@"align" = 1 } } }), word);
                if (offset % 8 != 0) p = try b.bin(.shl, p, .{ .int = @intCast(offset % 8 * 8) });
                v.* = if (offset == i * 8) p else try b.bin(.@"or", v.*, p);
                offset += size;
            }
        }
        try b.normalize(&result);
        return result;
    }
    fn store(b: Builder, ptr: ir.Value, p: Parts) !void {
        const bytes = (p.bits + 7) / 8;
        var offset: usize = 0;
        while (offset < bytes) {
            const remaining = @min(bytes - offset, 8 - offset % 8);
            const size: u16 = if (remaining >= 8) 8 else if (remaining >= 4) 4 else if (remaining >= 2) 2 else 1;
            const ty: ir.Type = .{ .int = size * 8 };
            const value = if (offset % 8 == 0) p.values[offset / 8] else try b.bin(.lshr, p.values[offset / 8], .{ .int = @intCast(offset % 8 * 8) });
            try b.block.instructions.append(b.a, .{ .result = null, .kind = .{ .store = .{ .ty = ty, .value = try b.cast(.trunc, word, value, ty), .ptr = try b.address(ptr, offset), .attrs = .{ .@"align" = 1 } } } });
            offset += size;
        }
    }
};

fn allocateParts(a: std.mem.Allocator, source: ir.Function, names: *forms.TemporaryNames, bits: u16) !Parts {
    var p: Parts = .{ .bits = bits };
    for (p.values[0..p.count()]) |*value| value.* = .{ .named = try forms.temporary(a, source, names) };
    return p;
}
fn storageType(a: std.mem.Allocator, bits: u16) !ir.Type {
    return .{ .aggregate = try std.fmt.allocPrint(a, "[{d} x i128]", .{(bits + 127) / 128}) };
}
pub fn privateReturnType(source: ir.Type) ?ir.Type {
    const bits = raw.width(source) orelse return null;
    return if (bits >= 193 and bits <= max_words * 64) .ptr else null;
}

pub fn legalize(a: std.mem.Allocator, source: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    return lower(a, source, context) catch |err| switch (err) {
        error.UnsupportedLimbInteger => null,
        else => return err,
    };
}
fn lower(a: std.mem.Allocator, source: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    var needed = wide(source.ret_ty);
    for (source.params.items) |param| needed = needed or wide(param.ty);
    for (source.blocks.items) |block| for (block.instructions.items) |*inst| if (!inst.removed) {
        needed = needed or touches(inst);
    };
    if (!needed or source.blocks.items.len == 0) return null;
    if (source.is_varargs or !helpers.isDefaultOrFastcc(source.calling_conv) or
        !addresses.supportsLayout(if (context) |ctx| ctx.target_datalayout else null)) return error.UnsupportedLimbInteger;
    // This private backing layout requires the actual pinned i128 alignment.
    const layout = if (context) |ctx| ctx.target_datalayout orelse "" else "";
    var fields = std.mem.splitScalar(u8, layout, '-');
    var aligned = false;
    while (fields.next()) |f| {
        if (std.mem.eql(u8, f, "i128:128")) aligned = true;
    }
    if (!aligned) return error.UnsupportedLimbInteger;
    var names: forms.TemporaryNames = .{};
    defer names.deinit(a);
    var values = std.StringHashMap(Parts).init(a);
    defer values.deinit();
    var tuples = std.StringHashMap(OverflowTuple).init(a);
    defer tuples.deinit();
    var result = source;
    result.blocks = .empty;
    result.params = .empty;
    var incoming = std.StringHashMap(Parts).init(a);
    defer incoming.deinit();
    const return_ptr = if (wide(source.ret_ty)) blk: {
        _ = try width(source.ret_ty);
        result.ret_ty = privateReturnType(source.ret_ty) orelse return error.UnsupportedLimbInteger;
        if (!advisory(source.ret_attrs)) return error.UnsupportedLimbInteger;
        result.ret_attrs = null;
        const name = try forms.temporary(a, source, &names);
        try result.params.append(a, .{ .name = name, .ty = .ptr });
        break :blk ir.Value{ .named = name };
    } else null;
    for (source.params.items) |param| {
        if (!wide(param.ty)) {
            try result.params.append(a, param);
            continue;
        }
        if (!advisory(param.attrs) or param.abi_incoming_address != null or param.abi_x87_memory or param.abi_split_integer) return error.UnsupportedLimbInteger;
        const bits = try width(param.ty);
        const raw_parts = try allocateParts(a, source, &names, bits);
        const normalized = try allocateParts(a, source, &names, bits);
        try incoming.put(param.name, raw_parts);
        try values.put(param.name, normalized);
        for (raw_parts.values[0..raw_parts.count()]) |v| try result.params.append(a, .{ .ty = word, .name = v.named });
    }
    if (stack.parameters(result) == null) return error.UnsupportedLimbInteger;
    for (source.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed or inst.kind != .call or inst.result == null) continue;
        if (try checkedKind(a, inst.kind.call)) |kind| {
            const entry = try tuples.getOrPut(inst.result.?);
            if (entry.found_existing) return error.UnsupportedLimbInteger;
            entry.value_ptr.* = .{ .value = try allocateParts(a, source, &names, kind.bits), .flag = .{ .named = try forms.temporary(a, source, &names) } };
        }
    };
    if (tuples.count() != 0) for (source.blocks.items) |block| {
        for (block.instructions.items) |inst| {
            if (inst.removed) continue;
            var check: TupleUses = .{ .tuples = &tuples };
            if (inst.kind == .extractvalue and inst.kind.extractvalue.aggregate == .named) {
                const x = inst.kind.extractvalue;
                if (tuples.get(x.aggregate.named)) |tuple| {
                    if (tupleBits(x.aggregate_ty) != tuple.value.bits or (!std.mem.eql(u8, x.indices, "0") and !std.mem.eql(u8, x.indices, "1"))) return error.UnsupportedLimbInteger;
                    check.allowed = x.aggregate.named;
                }
            }
            if (inst.kind == .call) {
                for ([_]?[]const u8{ inst.kind.call.raw_args, inst.kind.call.operand_bundle }) |text| if (text) |raw_text| if (std.mem.indexOfScalar(u8, raw_text, '%') != null) return error.UnsupportedLimbInteger;
            }
            _ = try ir.operands.instruction(&inst, check);
        }
        if (block.terminator) |term| _ = try ir.operands.terminator(&term, TupleUses{ .tuples = &tuples });
    };
    for (source.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed or inst.result == null) continue;
        if (inst.resultType()) |ty| if (wide(ty)) {
            if ((try values.getOrPut(inst.result.?)).found_existing) return error.UnsupportedLimbInteger;
            try values.put(inst.result.?, try allocateParts(a, source, &names, try width(ty)));
        };
    };
    for (source.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        const b: Builder = .{ .a = a, .source = source, .block = &block, .names = &names, .values = &values, .tuples = &tuples };
        if (block_index == 0) {
            var it = incoming.iterator();
            while (it.next()) |entry| try b.define(entry.key_ptr.*, entry.value_ptr.*);
        }
        for (original.instructions.items) |inst| {
            if (inst.removed) {
                try block.instructions.append(a, inst);
                continue;
            }
            if (inst.kind == .extractvalue and inst.kind.extractvalue.aggregate == .named) {
                const x = inst.kind.extractvalue;
                if (tuples.get(x.aggregate.named)) |tuple| {
                    if (std.mem.eql(u8, x.indices, "0")) try b.define(inst.result.?, tuple.value) else try b.copy(inst.result.?, boolean, tuple.flag);
                    continue;
                }
            }
            if (!touches(&inst)) {
                try block.instructions.append(a, inst);
                continue;
            }
            switch (inst.kind) {
                .binary => |x| {
                    if (!wide(x.ty)) return error.UnsupportedLimbInteger;
                    const lhs = try b.get(x.lhs, x.ty);
                    const rhs = try b.get(x.rhs, x.ty);
                    const p = switch (x.op) {
                        .shl, .lshr, .ashr => try b.shifted(x.op, lhs, rhs),
                        .udiv, .urem, .sdiv, .srem => blk: {
                            try validateDivisionProvider(context, divisionTarget(x.op));
                            break :blk try b.division(x.op, lhs, rhs);
                        },
                        else => try b.arithmetic(x.op, lhs, rhs),
                    };
                    try b.define(inst.result.?, p);
                },
                .cast => |x| {
                    if (x.op != .trunc and x.op != .zext and x.op != .sext and x.op != .bitcast) return error.UnsupportedLimbInteger;
                    const from = try width(x.from_ty);
                    const to = try width(x.to_ty);
                    if ((x.op == .trunc and from <= to) or ((x.op == .zext or x.op == .sext) and from >= to) or (x.op == .bitcast and from != to)) return error.UnsupportedLimbInteger;
                    const p = try b.resize(try b.get(x.value, x.from_ty), to, x.op == .sext);
                    if (wide(x.to_ty)) try b.define(inst.result.?, p) else try b.copy(inst.result.?, x.to_ty, try b.narrow(p, x.to_ty));
                },
                .icmp => |x| {
                    const p = try b.comparison(x.predicate, try b.get(x.lhs, x.operand_ty), try b.get(x.rhs, x.operand_ty));
                    try b.copy(inst.result.?, boolean, p);
                },
                .select => |x| {
                    if (!x.cond_ty.eql(boolean) or !wide(x.ty)) return error.UnsupportedLimbInteger;
                    const yes = try b.get(x.true_value, x.ty);
                    const no = try b.get(x.false_value, x.ty);
                    var p: Parts = .{ .bits = yes.bits };
                    for (p.values[0..p.count()], 0..) |*v, i| v.* = try b.choose(x.cond, yes.values[i], no.values[i]);
                    try b.define(inst.result.?, p);
                },
                .phi => |x| {
                    const destination = values.get(inst.result.?) orelse return error.UnsupportedLimbInteger;
                    for (destination.values[0..destination.count()], 0..) |v, i| {
                        var copy = inst;
                        copy.result = v.named;
                        copy.metadata = null;
                        copy.kind.phi.ty = word;
                        copy.kind.phi.incoming = try x.incoming.clone(a);
                        for (copy.kind.phi.incoming.items) |*entry| {
                            // PHI constants need no predecessor instructions.
                            if (entry.value == .named) {
                                const p = values.get(entry.value.named) orelse return error.UnsupportedLimbInteger;
                                if (p.bits != destination.bits) return error.UnsupportedLimbInteger;
                                entry.value = p.values[i];
                            } else entry.value = (try b.get(entry.value, x.ty)).values[i];
                        }
                        try block.instructions.append(a, copy);
                    }
                },
                .freeze => |x| try b.define(inst.result.?, try b.get(x.value, x.ty)),
                .load => |x| {
                    if (x.attrs.isBarrier() or x.attrs.syncscope != null or x.ty_addrspace != null or x.ptr_addrspace != null) return error.UnsupportedLimbInteger;
                    try b.define(inst.result.?, try b.load(x.ptr, try width(x.ty)));
                },
                .store => |x| {
                    if (x.attrs.isBarrier() or x.attrs.syncscope != null or x.ty_addrspace != null or x.ptr_addrspace != null) return error.UnsupportedLimbInteger;
                    try b.store(x.ptr, try b.get(x.value, x.ty));
                },
                .alloca => |x| {
                    if (!x.isSingleObject() or x.allocated_ty_addrspace != null or !allocaAttrs(x.attrs)) return error.UnsupportedLimbInteger;
                    var copy = inst;
                    copy.kind.alloca.allocated_ty = try storageType(a, try width(x.allocated_ty));
                    copy.kind.alloca.attrs = x.attrs orelse "align 16";
                    try block.instructions.append(a, copy);
                },
                .gep => |x| {
                    if (!wide(x.source_ty) or x.indices.items.len != 1) return error.UnsupportedLimbInteger;
                    var copy = inst;
                    copy.kind.gep.source_ty = try storageType(a, try width(x.source_ty));
                    try block.instructions.append(a, copy);
                },
                .call => |x| {
                    if (try checkedKind(a, x)) |kind| {
                        const computed = try b.checked(x, kind);
                        if (inst.result) |name| {
                            const tuple = tuples.get(name) orelse return error.UnsupportedLimbInteger;
                            const entry = try values.getOrPut(name);
                            if (entry.found_existing) return error.UnsupportedLimbInteger;
                            entry.value_ptr.* = tuple.value;
                            try b.define(name, computed.value);
                            try b.copy(tuple.flag.named, boolean, computed.flag);
                        }
                        continue;
                    }
                    if (std.mem.startsWith(u8, x.callee, "llvm.") and wide(x.ret_ty)) {
                        const p = (try b.intrinsic(x)) orelse return error.UnsupportedLimbInteger;
                        if (inst.result) |name| try b.define(name, p);
                        continue;
                    }
                    if (x.va_arg or x.native_query != null or x.inline_asm != null or x.callee_value != null or x.callee_function_ty != null or x.raw_args != null or x.operand_bundle != null or
                        !helpers.isDefaultOrFastcc(x.calling_conv) or std.mem.startsWith(u8, x.callee, "llvm.")) return error.UnsupportedLimbInteger;
                    if (x.tail_kind) |kind| if (std.mem.eql(u8, kind, "musttail")) return error.UnsupportedLimbInteger;
                    var copy = inst;
                    copy.kind.call.args = .empty;
                    copy.kind.call.tail_kind = null;
                    var output: ?ir.Value = null;
                    if (wide(x.ret_ty)) {
                        if (!advisory(x.ret_attrs) or privateReturnType(x.ret_ty) == null) return error.UnsupportedLimbInteger;
                        const backing = try storageType(a, try width(x.ret_ty));
                        output = try b.emit(.{ .alloca = .{ .allocated_ty = backing, .attrs = "align 16" } });
                        copy.kind.call.ret_ty = .ptr;
                        copy.kind.call.ret_attrs = null;
                        copy.result = null;
                        try copy.kind.call.args.append(a, .{ .ty = .ptr, .value = output.? });
                    }
                    for (x.args.items) |arg| {
                        if (!wide(arg.ty)) {
                            try copy.kind.call.args.append(a, arg);
                            continue;
                        }
                        if (!advisory(arg.attrs) or arg.abi_x87_memory or arg.abi_split_integer) return error.UnsupportedLimbInteger;
                        const p = try b.get(arg.value, arg.ty);
                        for (p.values[0..p.count()]) |v| try copy.kind.call.args.append(a, .{ .ty = word, .value = v });
                    }
                    if (stack.callLayout(copy.kind.call) == null) return error.UnsupportedLimbInteger;
                    try block.instructions.append(a, copy);
                    if (output) |ptr| if (inst.result) |name| try b.define(name, try b.load(ptr, try width(x.ret_ty)));
                },
                else => return error.UnsupportedLimbInteger,
            }
        }
        if (original.terminator) |term| switch (term) {
            .ret => |x| if (wide(x.ty)) {
                if (return_ptr == null or !x.ty.eql(source.ret_ty) or x.ptr_addrspace != null) return error.UnsupportedLimbInteger;
                try b.store(return_ptr.?, try b.get(x.value orelse return error.UnsupportedLimbInteger, x.ty));
                block.terminator = .{ .ret = .{ .ty = .ptr, .value = return_ptr.? } };
            },
            .@"switch" => |x| if (wide(x.cond_ty)) {
                return error.UnsupportedLimbInteger;
            },
            else => {},
        };
        try result.blocks.append(a, block);
    }
    return result;
}
