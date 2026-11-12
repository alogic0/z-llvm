//! Normalize sub-word arithmetic and signed division to ordinary 32/64-bit
//! operations. Only private selector IR changes; source widths remain visible
//! at every original SSA definition and ABI boundary.
const std = @import("std");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const ir = @import("../../../ir.zig");
const forms = @import("scalar_forms.zig");

fn integer(ty: ir.Type) bool {
    return ty == .int and ty.int > 0 and ty.int <= 64;
}
fn operand(value: ir.Value, bits: u16) bool {
    return switch (value) {
        .named => !std.mem.startsWith(u8, value.named, "@"),
        .int => |v| v >= -(@as(i128, 1) << @as(u7, @intCast(bits - 1))) and v < (@as(i128, 1) << @as(u7, @intCast(bits))),
        else => false,
    };
}
fn emit(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
    const name = try forms.temporary(allocator, function, serial);
    try block.instructions.append(allocator, .{ .result = name, .kind = kind });
    return .{ .named = name };
}
fn binary(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, ty: ir.Type, op: ir.BinaryOp, lhs: ir.Value, rhs: ir.Value) !ir.Value {
    return emit(allocator, function, block, serial, .{ .binary = .{ .op = op, .ty = ty, .lhs = lhs, .rhs = rhs } });
}
fn unsigned(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, ty: ir.Type, wide: ir.Type, value: ir.Value) !ir.Value {
    if (value == .int) return binary(allocator, function, block, serial, wide, .add, .{ .int = value.int & ((@as(i128, 1) << @as(u7, @intCast(ty.int))) - 1) }, .{ .int = 0 });
    if (ty.eql(wide)) return value;
    return emit(allocator, function, block, serial, .{ .cast = .{ .op = .zext, .from_ty = ty, .to_ty = wide, .value = value } });
}
fn signed(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, ty: ir.Type, wide: ir.Type, value: ir.Value) !ir.Value {
    const bits = try unsigned(allocator, function, block, serial, ty, wide, value);
    if (ty.eql(wide)) return bits;
    const amount: ir.Value = .{ .int = wide.int - ty.int };
    const shifted = try binary(allocator, function, block, serial, wide, .shl, bits, amount);
    return binary(allocator, function, block, serial, wide, .ashr, shifted, amount);
}
fn signedDivision(allocator: std.mem.Allocator, function: ir.Function, block: *ir.BasicBlock, serial: *forms.TemporaryNames, ty: ir.Type, op: ir.BinaryOp, lhs: ir.Value, rhs: ir.Value) !ir.Value {
    const sign_a = try binary(allocator, function, block, serial, ty, .ashr, lhs, .{ .int = ty.int - 1 });
    const sign_b = try binary(allocator, function, block, serial, ty, .ashr, rhs, .{ .int = ty.int - 1 });
    const flip_a = try binary(allocator, function, block, serial, ty, .xor, lhs, sign_a);
    const flip_b = try binary(allocator, function, block, serial, ty, .xor, rhs, sign_b);
    const absolute_a = try binary(allocator, function, block, serial, ty, .sub, flip_a, sign_a);
    const absolute_b = try binary(allocator, function, block, serial, ty, .sub, flip_b, sign_b);
    const magnitude = try binary(allocator, function, block, serial, ty, if (op == .sdiv) .udiv else .urem, absolute_a, absolute_b);
    const sign = if (op == .sdiv) try binary(allocator, function, block, serial, ty, .xor, sign_a, sign_b) else sign_a;
    const flipped = try binary(allocator, function, block, serial, ty, .xor, magnitude, sign);
    return binary(allocator, function, block, serial, ty, .sub, flipped, sign);
}
fn finish(allocator: std.mem.Allocator, block: *ir.BasicBlock, original: ir.Instruction, wide: ir.Type, narrow: ir.Type, value: ir.Value) !void {
    var result = original;
    result.kind = if (wide.eql(narrow)) .{ .binary = .{ .op = .add, .ty = wide, .lhs = value, .rhs = .{ .int = 0 } } } else .{ .cast = .{ .op = .trunc, .from_ty = wide, .to_ty = narrow, .value = value } };
    try block.instructions.append(allocator, result);
}
fn supported(op: ir.BinaryOp) bool {
    return switch (op) {
        .add, .sub, .mul, .@"and", .@"or", .xor, .shl, .lshr, .ashr, .udiv, .urem, .sdiv, .srem => true,
        else => false,
    };
}

fn constantPair(value: ir.BinaryInst) ?u64 {
    if (!integer(value.ty) or value.lhs != .int or value.rhs != .int or value.flags.any() or
        !operand(value.lhs, value.ty.int) or !operand(value.rhs, value.ty.int)) return null;
    // Keep the established full-word materialization as the terminal form.
    if (value.op == .add and value.rhs.int == 0 and (value.ty.int == 32 or value.ty.int == 64)) return null;
    const sem = @import("../../../analysis/integer_semantics.zig").Integer.init(value.ty).?;
    const x = sem.unsigned(value.lhs.int);
    const y = sem.unsigned(value.rhs.int);
    const result = switch (value.op) {
        .add => x +% y,
        .sub => x -% y,
        .mul => x *% y,
        .@"and" => x & y,
        .@"or" => x | y,
        .xor => x ^ y,
        .shl => if (y < value.ty.int) x << @as(u7, @intCast(y)) else return null,
        .lshr => if (y < value.ty.int) x >> @as(u7, @intCast(y)) else return null,
        .ashr => if (y < value.ty.int) @as(u128, @bitCast(sem.normalize(value.lhs.int) >> @as(u7, @intCast(y)))) else return null,
        .udiv => if (y != 0) x / y else return null,
        .urem => if (y != 0) x % y else return null,
        // Signed division overflow and poison cases keep their existing paths.
        else => return null,
    };
    return @intCast(result & sem.unsignedMax());
}

fn truncatedWord(function: ir.Function, cast: ir.CastInst) ?ir.Value {
    if (cast.op != .zext or !cast.to_ty.eql(.{ .int = 64 }) or !integer(cast.from_ty) or
        cast.from_ty.int == 64 or cast.value != .named) return null;
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed or inst.result == null or !ir.identifiers.eql(inst.result.?, cast.value.named) or inst.kind != .cast) continue;
        const source = inst.kind.cast;
        if (source.op == .trunc and source.from_ty.eql(cast.to_ty) and source.to_ty.eql(cast.from_ty) and source.value == .named)
            return source.value;
    };
    return null;
}

pub fn requiresNormalization(function: ir.Function) bool {
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed or inst.kind != .binary) continue;
        const value = inst.kind.binary;
        if (!integer(value.ty) or value.ty.int == 32 or value.ty.int == 64) continue;
        switch (value.op) {
            // A nonnegative literal already has a clean carrier, including the
            // frozen parity lookup. Named values may retain upper alias bits.
            .shl, .lshr => {
                // The exact i52 action proves its count provenance and masks
                // the result itself. Retain that established typed action.
                if (@import("value_use/actions/scalar_named.zig").isExactI52Binary(&function, value)) continue;
                if (value.lhs != .int or value.lhs.int < 0) return true;
            },
            .ashr, .udiv, .urem, .sdiv, .srem => return true,
            else => {},
        }
    };
    return false;
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var candidate = Candidate.init(allocator, function);
    var serial: forms.TemporaryNames = .{};
    defer serial.deinit(allocator);
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items, 0..) |inst, instruction_index| {
            if (!inst.removed and inst.result != null) switch (inst.kind) {
                .binary => |value| if (constantPair(value)) |result| {
                    try candidate.begin(&block, block_index, instruction_index);
                    const wide: ir.Type = .{ .int = if (value.ty.int <= 32) 32 else 64 };
                    const answer = try binary(allocator, function, &block, &serial, wide, .add, .{ .int = result }, .{ .int = 0 });
                    try finish(allocator, &block, inst, wide, value.ty, answer);
                    continue;
                } else if ((value.ty.eql(.{ .int = 32 }) or value.ty.eql(.{ .int = 64 })) and
                    (value.op == .shl or value.op == .lshr or value.op == .ashr) and
                    value.lhs == .int and value.rhs == .named and
                    operand(value.lhs, value.ty.int) and operand(value.rhs, value.ty.int))
                {
                    // Use the existing full-word constant and named shift
                    // authorities, retaining the original count and flags.
                    try candidate.begin(&block, block_index, instruction_index);
                    var copy = inst;
                    copy.kind.binary.lhs = try binary(allocator, function, &block, &serial, value.ty, .add, value.lhs, .{ .int = 0 });
                    try block.instructions.append(allocator, copy);
                    continue;
                } else if (integer(value.ty) and supported(value.op) and operand(value.lhs, value.ty.int) and operand(value.rhs, value.ty.int) and
                    ((value.ty.int != 32 and value.ty.int != 64) or value.op == .sdiv or value.op == .srem))
                {
                    // The ordinary two-register multiply action uses a word
                    // carrier. Truncation retains the original modular result.
                    try candidate.begin(&block, block_index, instruction_index);
                    const wide: ir.Type = .{ .int = if (value.ty.int <= 32 and value.op != .mul) 32 else 64 };
                    const is_signed = value.op == .ashr or value.op == .sdiv or value.op == .srem;
                    const lhs = if (is_signed) try signed(allocator, function, &block, &serial, value.ty, wide, value.lhs) else try unsigned(allocator, function, &block, &serial, value.ty, wide, value.lhs);
                    const rhs = if (value.op == .sdiv or value.op == .srem) try signed(allocator, function, &block, &serial, value.ty, wide, value.rhs) else try unsigned(allocator, function, &block, &serial, value.ty, wide, value.rhs);
                    const answer = if (value.op == .sdiv or value.op == .srem) try signedDivision(allocator, function, &block, &serial, wide, value.op, lhs, rhs) else try binary(allocator, function, &block, &serial, wide, value.op, lhs, rhs);
                    // Width-specific overflow and exact flags constrain defined
                    // inputs in the original IR. Expanded intermediates wrap.
                    try finish(allocator, &block, inst, wide, value.ty, answer);
                    continue;
                },
                .cast => |cast| if (cast.op == .zext and integer(cast.from_ty) and integer(cast.to_ty) and
                    cast.from_ty.int < cast.to_ty.int and cast.value == .int and operand(cast.value, cast.from_ty.int) and
                    cast.from_ty.int != 1 and cast.from_ty.int != 8 and cast.from_ty.int != 16 and cast.from_ty.int != 32 and
                    (cast.to_ty.int == 8 or cast.to_ty.int == 16 or cast.to_ty.int == 32 or cast.to_ty.int == 64))
                {
                    // LLVM literals carry the source-width bit pattern. In
                    // particular zext i3 -4 is4, not a sign-extended word.
                    const semantics = @import("../../../analysis/integer_semantics.zig").Integer.init(cast.from_ty).?;
                    try candidate.begin(&block, block_index, instruction_index);
                    var copy = inst;
                    copy.kind = .{ .binary = .{ .op = .add, .ty = cast.to_ty, .lhs = .{ .int = @intCast(semantics.unsigned(cast.value.int)) }, .rhs = .{ .int = 0 } } };
                    try block.instructions.append(allocator, copy);
                    continue;
                } else if (cast.op == .trunc and cast.from_ty.eql(.{ .int = 128 }) and cast.to_ty.eql(.{ .int = 52 }) and
                    (cast.value == .int or (cast.value == .named and !std.mem.startsWith(u8, cast.value.named, "@"))))
                {
                    try candidate.begin(&block, block_index, instruction_index);
                    const wide: ir.Type = .{ .int = 64 };
                    const low = if (cast.value == .int)
                        try binary(allocator, function, &block, &serial, wide, .add, .{ .int = @as(u64, @truncate(@as(u128, @bitCast(cast.value.int)))) }, .{ .int = 0 })
                    else
                        try emit(allocator, function, &block, &serial, .{ .cast = .{ .op = .trunc, .from_ty = cast.from_ty, .value = cast.value, .to_ty = wide } });
                    try finish(allocator, &block, inst, wide, cast.to_ty, low);
                    continue;
                } else if (cast.op == .sext and integer(cast.from_ty) and integer(cast.to_ty) and cast.from_ty.int < cast.to_ty.int and operand(cast.value, cast.from_ty.int)) {
                    try candidate.begin(&block, block_index, instruction_index);
                    const wide: ir.Type = .{ .int = if (cast.to_ty.int <= 32) 32 else 64 };
                    const answer = try signed(allocator, function, &block, &serial, cast.from_ty, wide, cast.value);
                    try finish(allocator, &block, inst, wide, cast.to_ty, answer);
                    continue;
                } else if (cast.op == .zext and integer(cast.from_ty) and integer(cast.to_ty) and
                    cast.from_ty.int < cast.to_ty.int and cast.to_ty.int > 32 and cast.to_ty.int < 64 and operand(cast.value, cast.from_ty.int))
                {
                    // An odd-width extension has the same low bits as a word
                    // extension. Retain the declared SSA width with a truncation
                    // after establishing a clean 64-bit carrier.
                    try candidate.begin(&block, block_index, instruction_index);
                    const wide: ir.Type = .{ .int = 64 };
                    const answer = try unsigned(allocator, function, &block, &serial, cast.from_ty, wide, cast.value);
                    try finish(allocator, &block, inst, wide, cast.to_ty, answer);
                    continue;
                } else if (cast.op == .trunc and integer(cast.from_ty) and integer(cast.to_ty) and
                    cast.from_ty.int > cast.to_ty.int and (cast.from_ty.int == 52 or cast.to_ty.int == 52) and
                    operand(cast.value, cast.from_ty.int) and
                    !@import("value_use/actions/scalar_cast.zig").isAccumulatorScalarCast(cast, false))
                {
                    // Bridge other i52 truncations through the established word
                    // actions. The source remains typed, and the original result
                    // keeps its declared width; no memory or ABI extent changes.
                    try candidate.begin(&block, block_index, instruction_index);
                    const wide: ir.Type = .{ .int = 64 };
                    const answer = try unsigned(allocator, function, &block, &serial, cast.from_ty, wide, cast.value);
                    try finish(allocator, &block, inst, wide, cast.to_ty, answer);
                    continue;
                } else if (truncatedWord(function, cast)) |source| {
                    // zext(trunc(x)) is an ordinary word mask. This also avoids
                    // requiring a separate register carrier for the inner width.
                    try candidate.begin(&block, block_index, instruction_index);
                    var copy = inst;
                    copy.kind = .{ .binary = .{ .op = .@"and", .ty = cast.to_ty, .lhs = source, .rhs = .{ .int = (@as(i128, 1) << @as(u7, @intCast(cast.from_ty.int))) - 1 } } };
                    try block.instructions.append(allocator, copy);
                    continue;
                },
                .select => |select| if (integer(select.ty) and select.ty.int > 32 and select.ty.int < 64 and
                    select.cond_ty.eql(.{ .int = 1 }) and operand(select.cond, 1) and
                    operand(select.true_value, select.ty.int) and operand(select.false_value, select.ty.int))
                {
                    try candidate.begin(&block, block_index, instruction_index);
                    const wide: ir.Type = .{ .int = 64 };
                    var expanded = select;
                    expanded.ty = wide;
                    expanded.true_value = try unsigned(allocator, function, &block, &serial, select.ty, wide, select.true_value);
                    expanded.false_value = try unsigned(allocator, function, &block, &serial, select.ty, wide, select.false_value);
                    const answer = try emit(allocator, function, &block, &serial, .{ .select = expanded });
                    try finish(allocator, &block, inst, wide, select.ty, answer);
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
