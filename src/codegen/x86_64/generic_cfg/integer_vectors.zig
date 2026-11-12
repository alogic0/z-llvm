//! Private scalar lanes for bounded integer vectors. Memory uses the exact
//! byte extent (including packed i1 masks). Native 128-bit ABI values bridge
//! through full XMM bit carriers; barriers retain their separate boundaries.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const forms = @import("scalar_forms.zig");
const addresses = @import("../symbol_address.zig");
const integer = @import("../../../analysis/integer_semantics.zig").Integer;
const abi = @import("../sysv_abi.zig");
const xmm_carrier: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .double } };

// Exact LLVM integer vector shapes use packed low XMM bits. Up to64-bit
// shapes occupy an8-byte overflow slot; a private double preserves that ABI.
// 128-bit shapes keep their existing two-double raw boundary. Non-native
// integer widths use promoted cells; three i32 lanes retain XMM tail padding.
fn abiType(ty: ir.Type) ?ir.Type {
    if (abi.isVector128AbiType(ty)) return ty;
    return privateAbiType(ty);
}
pub fn privateAbiType(ty: ir.Type) ?ir.Type {
    if (promotedLaneBits(ty) != null or (ty == .vector and ty.vector.len == 3 and ty.vector.elem_ty == .int and ty.vector.elem_ty.int == 32)) return xmm_carrier;
    if (ty == .vector and ty.vector.elem_ty == .int) {
        const n = ty.vector.len;
        const bits = ty.vector.elem_ty.int;
        if ((bits == 8 and (n == 2 or n == 4 or n == 8)) or
            (bits == 16 and (n == 2 or n == 4)) or (bits == 32 and n == 2)) return .double;
    }
    if (ty == .vector and ty.vector.elem_ty == .int and
        ((ty.vector.len == 16 and ty.vector.elem_ty.int == 8) or
            (ty.vector.len == 8 and ty.vector.elem_ty.int == 16))) return xmm_carrier;
    return null;
}

fn promotedLaneBits(ty: ir.Type) ?u16 {
    if (ty != .vector or ty.vector.elem_ty != .int) return null;
    const n = ty.vector.len;
    const bits = ty.vector.elem_ty.int;
    // These non-native element widths use LLVM's full-width promoted XMM
    // cells, unlike their densely packed memory representation.
    // The established scalar cast actions keep general i51/i52 carriers
    // closed. Promoted ABI admission does not widen that frozen authority.
    if (bits == 0 or bits == 8 or bits == 16 or bits == 32 or bits == 51 or bits == 52 or bits == 64) return null;
    if ((n == 2 or n == 4 or n == 8 or n == 16) and bits < 128 / n) return @intCast(128 / n);
    return null;
}

const Shape = struct {
    len: u32,
    bits: u16,
    pointer: bool = false,
    fn scalar(s: Shape) ir.Type {
        return if (s.pointer) .ptr else .{ .int = s.bits };
    }
};
const max_lanes = 64;
const Lanes = struct { ty: ir.Type, values: [max_lanes]ir.Value };

fn shape(ty: ir.Type) ?Shape {
    if (ty != .vector or ty.vector.len == 0 or ty.vector.len > max_lanes) return null;
    if (ty.vector.elem_ty == .ptr) return .{ .len = ty.vector.len, .bits = 64, .pointer = true };
    if (ty.vector.elem_ty != .int or ty.vector.elem_ty.int == 0 or ty.vector.elem_ty.int > 128) return null;
    return .{ .len = ty.vector.len, .bits = ty.vector.elem_ty.int };
}
fn defined(value: ir.Value, ty: ir.Type) !ir.Value {
    if (value == .undef or value == .poison or value == .zero_initializer)
        return if (ty == .ptr) .null_value else .{ .int = 0 };
    if (value != .named and !(if (ty == .ptr) value == .null_value else value == .int)) return error.UnsupportedIntegerVector;
    return value;
}
fn constantLanes(value: ir.Value, ty: ir.Type) ?Lanes {
    if (ty != .vector or ty.vector.len > max_lanes) return null;
    inline for (1..max_lanes + 1) |count| if (ty.vector.len == count) {
        const parsed = ir.vector_constant.parseFixed(count, value, ty.vector) orelse return null;
        var result: Lanes = .{ .ty = ty, .values = @splat(.poison) };
        for (parsed.lanes, 0..) |lane, i| result.values[i] = if (lane == .zero_initializer)
            (if (ty.vector.elem_ty == .ptr) .null_value else .{ .int = 0 })
        else
            lane.value();
        return result;
    };
    return null;
}
fn laneIndex(value: ir.Value, ty: ir.Type, len: u32) !usize {
    if (value != .int) return error.UnsupportedIntegerVector;
    const sem = integer.init(ty) orelse return error.UnsupportedIntegerVector;
    const index = sem.unsigned(value.int);
    if (index >= len) return error.UnsupportedIntegerVector;
    return @intCast(index);
}

fn laneIntrinsic(allocator: std.mem.Allocator, call: ir.CallInst) !?[]const u8 {
    const s = shape(call.ret_ty) orelse return null;
    if (s.pointer) return null;
    const Kind = struct { name: []const u8, vectors: usize, extra: ?u16 = null };
    const kinds = [_]Kind{
        .{ .name = "fshl", .vectors = 3 },       .{ .name = "fshr", .vectors = 3 },            .{ .name = "bswap", .vectors = 1 },                     .{ .name = "ctpop", .vectors = 1 },
        .{ .name = "bitreverse", .vectors = 1 }, .{ .name = "abs", .vectors = 1, .extra = 1 }, .{ .name = "ctlz", .vectors = 1, .extra = 1 },          .{ .name = "cttz", .vectors = 1, .extra = 1 },
        .{ .name = "uadd.sat", .vectors = 2 },   .{ .name = "usub.sat", .vectors = 2 },        .{ .name = "sadd.sat", .vectors = 2 },                  .{ .name = "ssub.sat", .vectors = 2 },
        .{ .name = "umin", .vectors = 2 },       .{ .name = "umax", .vectors = 2 },            .{ .name = "smin", .vectors = 2 },                      .{ .name = "smax", .vectors = 2 },
        .{ .name = "ushl.sat", .vectors = 2 },   .{ .name = "sshl.sat", .vectors = 2 },        .{ .name = "umul.fix.sat", .vectors = 2, .extra = 32 }, .{ .name = "smul.fix.sat", .vectors = 2, .extra = 32 },
    };
    for (kinds) |kind| {
        const name = kind.name;
        const arity = kind.vectors + @intFromBool(kind.extra != null);
        const vector_name = try std.fmt.allocPrint(allocator, "llvm.{s}.v{d}i{d}", .{ name, s.len, s.bits });
        if (!std.mem.eql(u8, call.callee, vector_name)) continue;
        // Existing byte swap/count/funnel paths keep their original width
        // envelope. New lane operations use the proved scalar<=64 contracts.
        const pair_scalar = s.bits == 128 and (std.mem.eql(u8, name, "uadd.sat") or std.mem.eql(u8, name, "usub.sat") or
            std.mem.eql(u8, name, "sadd.sat") or std.mem.eql(u8, name, "ssub.sat") or std.mem.eql(u8, name, "umin") or
            std.mem.eql(u8, name, "umax") or std.mem.eql(u8, name, "smin") or std.mem.eql(u8, name, "smax"));
        if (s.bits > 64 and !pair_scalar and !std.mem.eql(u8, name, "fshl") and !std.mem.eql(u8, name, "bswap") and !std.mem.eql(u8, name, "ctpop") and !std.mem.eql(u8, name, "usub.sat")) return error.UnsupportedIntegerVector;
        if (std.mem.eql(u8, name, "bswap") and s.bits % 16 != 0) return error.UnsupportedIntegerVector;
        if (call.args.items.len != arity or call.callee_value != null or call.callee_function_ty != null or
            call.inline_asm != null or call.raw_args != null or call.operand_bundle != null or call.calling_conv != null)
            return error.UnsupportedIntegerVector;
        if (call.ret_attrs != null and !((std.mem.eql(u8, name, "ctpop") or std.mem.eql(u8, name, "ctlz") or std.mem.eql(u8, name, "cttz")) and
            @import("intrinsic_attrs.zig").matchesIntegerRange(call.ret_attrs, s.bits, 0, @as(u128, s.bits) + 1)))
            return error.UnsupportedIntegerVector;
        if (call.tail_kind) |tail| if (std.mem.eql(u8, tail, "musttail")) return error.UnsupportedIntegerVector;
        for (call.args.items[0..kind.vectors]) |arg| if (!arg.ty.eql(call.ret_ty) or arg.attrs != null) return error.UnsupportedIntegerVector;
        if (kind.extra) |bits| {
            const arg = call.args.items[kind.vectors];
            if (!arg.ty.eql(.{ .int = bits }) or arg.attrs != null or arg.value != .int) return error.UnsupportedIntegerVector;
            if (bits == 1) {
                if (arg.value.int != 0 and arg.value.int != 1) return error.UnsupportedIntegerVector;
            } else if (arg.value.int != 0) return error.UnsupportedIntegerVector;
        }
        return try std.fmt.allocPrint(allocator, "llvm.{s}.i{d}", .{ name, s.bits });
    }
    return null;
}

const Builder = struct {
    allocator: std.mem.Allocator,
    function: ir.Function,
    block: *ir.BasicBlock,
    serial: *forms.TemporaryNames,
    vectors: *std.StringHashMap(Lanes),

    fn emit(b: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const name = try forms.temporary(b.allocator, b.function, b.serial);
        try b.block.instructions.append(b.allocator, .{ .result = name, .kind = kind });
        return .{ .named = name };
    }
    fn lanes(b: Builder, value: ir.Value, ty: ir.Type) !Lanes {
        if (value == .named) {
            const result = b.vectors.get(value.named) orelse return error.UnsupportedIntegerVector;
            if (!result.ty.eql(ty)) return error.UnsupportedIntegerVector;
            return result;
        }
        return constantLanes(value, ty) orelse error.UnsupportedIntegerVector;
    }
    fn cast(b: Builder, op: ir.CastOp, from: ir.Type, value: ir.Value, to: ir.Type) !ir.Value {
        const concrete = try defined(value, from);
        if (from.eql(to)) return concrete;
        if (from == .ptr or to == .ptr) {
            const word: ir.Type = .{ .int = 64 };
            if (op == .ptrtoint and from == .ptr and to == .int) {
                const bits: ir.Value = if (concrete == .null_value) .{ .int = 0 } else try b.emit(.{ .cast = .{ .op = .ptrtoint, .from_ty = .ptr, .value = concrete, .to_ty = word } });
                return b.cast(if (to.int < 64) .trunc else .zext, word, bits, to);
            }
            if (op == .inttoptr and from == .int and to == .ptr) {
                const bits = try b.cast(if (from.int > 64) .trunc else .zext, from, concrete, word);
                if (bits == .int and bits.int == 0) return .null_value;
                return b.emit(.{ .cast = .{ .op = .inttoptr, .from_ty = word, .value = bits, .to_ty = .ptr } });
            }
            return error.UnsupportedIntegerVector;
        }
        if (concrete == .int) {
            const sem = integer.init(from) orelse return error.UnsupportedIntegerVector;
            const extended: i128 = if (op == .sext) sem.normalize(concrete.int) else @bitCast(sem.unsigned(concrete.int));
            return .{ .int = @bitCast((integer.init(to) orelse return error.UnsupportedIntegerVector).unsigned(extended)) };
        }
        return b.emit(.{ .cast = .{ .op = op, .from_ty = from, .value = concrete, .to_ty = to } });
    }
    fn binary(b: Builder, op: ir.BinaryOp, ty: ir.Type, a: ir.Value, c: ir.Value) !ir.Value {
        return b.emit(.{ .binary = .{ .op = op, .ty = ty, .lhs = try defined(a, ty), .rhs = try defined(c, ty) } });
    }
    fn copy(b: Builder, original: ir.Instruction, ty: ir.Type, value: ir.Value) !void {
        const concrete = try defined(value, ty);
        if (ty == .ptr) {
            if (concrete == .null_value) {
                try b.block.instructions.append(b.allocator, .{ .result = original.result, .metadata = original.metadata, .kind = .{ .cast = .{ .op = .inttoptr, .from_ty = .{ .int = 64 }, .value = .{ .int = 0 }, .to_ty = .ptr } } });
            } else {
                var indices: std.ArrayList(ir.GepIndex) = .empty;
                try indices.append(b.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
                try b.block.instructions.append(b.allocator, .{ .result = original.result, .metadata = original.metadata, .kind = .{ .gep = .{ .source_ty = .{ .int = 8 }, .ptr = concrete, .indices = indices } } });
            }
            return;
        }
        const kind: @FieldType(ir.Instruction, "kind") = if (concrete == .int)
            .{ .binary = .{ .op = .add, .ty = ty, .lhs = concrete, .rhs = .{ .int = 0 } } }
        else if (ty == .int and ty.int > 64 and ty.int <= 128)
            .{ .binary = .{ .op = .@"or", .ty = ty, .lhs = concrete, .rhs = .{ .int = 0 } } }
        else
            .{ .cast = .{ .op = .bitcast, .from_ty = ty, .value = concrete, .to_ty = ty } };
        try b.block.instructions.append(b.allocator, .{ .result = original.result, .metadata = original.metadata, .kind = kind });
    }
    fn address(b: Builder, ptr: ir.Value, offset: usize) !ir.Value {
        if (offset == 0) return ptr;
        var indices: std.ArrayList(ir.GepIndex) = .empty;
        try indices.append(b.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(offset) } });
        return b.emit(.{ .gep = .{ .source_ty = .{ .int = 8 }, .ptr = ptr, .indices = indices } });
    }
    fn indexIs(b: Builder, index: ir.Value, ty: ir.Type, lane: usize) !ir.Value {
        if (ty != .int or (ty.int != 32 and ty.int != 64)) return error.UnsupportedIntegerVector;
        return b.emit(.{ .icmp = .{ .predicate = .eq, .operand_ty = ty, .lhs = try defined(index, ty), .rhs = .{ .int = @intCast(lane) } } });
    }
    fn select(b: Builder, condition: ir.Value, ty: ir.Type, yes: ir.Value, no: ir.Value) !ir.Value {
        return b.emit(.{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = condition, .ty = ty, .true_value = try defined(yes, ty), .false_value = try defined(no, ty) } });
    }
    fn pack(b: Builder, vector: Lanes) !ir.Value {
        const s = shape(vector.ty) orelse return error.UnsupportedIntegerVector;
        if (s.pointer or s.len * s.bits > 128) return error.UnsupportedIntegerVector;
        const carrier: ir.Type = .{ .int = if (s.len * s.bits > 64) 128 else 64 };
        var result: ir.Value = .{ .int = 0 };
        for (vector.values[0..s.len], 0..) |value, i| {
            var part = try b.cast(.zext, s.scalar(), value, carrier);
            if (i != 0) part = try b.binary(.shl, carrier, part, .{ .int = @intCast(i * s.bits) });
            result = if (i == 0) part else try b.binary(.@"or", carrier, result, part);
        }
        return result;
    }
    fn unpack(b: Builder, value: ir.Value, carrier: ir.Type, ty: ir.Type) !Lanes {
        const s = shape(ty) orelse return error.UnsupportedIntegerVector;
        if (s.pointer or s.len * s.bits > 128) return error.UnsupportedIntegerVector;
        var result: Lanes = .{ .ty = ty, .values = @splat(.poison) };
        for (result.values[0..s.len], 0..) |*lane, i| {
            const part = if (i == 0) value else try b.binary(.lshr, carrier, value, .{ .int = @intCast(i * s.bits) });
            lane.* = try b.cast(.trunc, carrier, part, s.scalar());
        }
        return result;
    }
    fn repack(b: Builder, source: Lanes, ty: ir.Type) !Lanes {
        const input = shape(source.ty) orelse return error.UnsupportedIntegerVector;
        const output = shape(ty) orelse return error.UnsupportedIntegerVector;
        if (input.pointer or output.pointer or input.len * input.bits != output.len * output.bits) return error.UnsupportedIntegerVector;
        var result: Lanes = .{ .ty = ty, .values = @splat(.poison) };
        const from: ir.Type = .{ .int = if (input.bits > 64) 128 else 64 };
        const to: ir.Type = .{ .int = if (output.bits > 64) 128 else 64 };
        for (result.values[0..output.len], 0..) |*lane, i| {
            const begin = i * output.bits;
            const end = begin + output.bits;
            var value: ir.Value = .{ .int = 0 };
            var first = true;
            for (source.values[0..input.len], 0..) |part, j| {
                const source_begin = j * input.bits;
                const overlap_begin = @max(begin, source_begin);
                const overlap_end = @min(end, source_begin + input.bits);
                if (overlap_begin >= overlap_end) continue;
                var bits = try b.cast(.zext, input.scalar(), part, from);
                if (overlap_begin != source_begin) bits = try b.binary(.lshr, from, bits, .{ .int = @intCast(overlap_begin - source_begin) });
                bits = try b.cast(if (from.int > to.int) .trunc else .zext, from, bits, to);
                const width = overlap_end - overlap_begin;
                if (width < to.int) {
                    const mask: i128 = @bitCast((@as(u128, 1) << @as(u7, @intCast(width))) - 1);
                    bits = try b.binary(.@"and", to, bits, .{ .int = mask });
                }
                if (overlap_begin != begin) bits = try b.binary(.shl, to, bits, .{ .int = @intCast(overlap_begin - begin) });
                value = if (first) bits else try b.binary(.@"or", to, value, bits);
                first = false;
            }
            lane.* = try b.cast(.trunc, to, value, output.scalar());
        }
        return result;
    }
    fn defineVector(b: Builder, original: ir.Instruction, value: Lanes) !void {
        const result = b.vectors.get(original.result orelse return error.UnsupportedIntegerVector) orelse return error.UnsupportedIntegerVector;
        if (!result.ty.eql(value.ty)) return error.UnsupportedIntegerVector;
        const s = shape(value.ty).?;
        for (result.values[0..s.len], value.values[0..s.len]) |destination, source| {
            var alias = original;
            alias.result = destination.named;
            try b.copy(alias, s.scalar(), source);
        }
    }
    fn fromAbi(b: Builder, value: ir.Value, ty: ir.Type) !Lanes {
        const s = shape(ty) orelse return error.UnsupportedIntegerVector;
        const incoming = abiType(ty) orelse return error.UnsupportedIntegerVector;
        if (incoming == .double) {
            const bits = try b.emit(.{ .cast = .{ .op = .bitcast, .from_ty = .double, .value = value, .to_ty = .{ .int = 64 } } });
            return b.unpack(bits, .{ .int = 64 }, ty);
        }
        const bits = try b.emit(.{ .cast = .{ .op = .bitcast, .from_ty = incoming, .value = value, .to_ty = xmm_carrier } });
        var words: [2]ir.Value = undefined;
        for (&words, 0..) |*word, i| {
            const lane = try b.emit(.{ .extractelement = .{ .vector_ty = xmm_carrier, .vector = bits, .index_ty = .{ .int = 64 }, .index = .{ .int = @intCast(i) } } });
            word.* = try b.emit(.{ .cast = .{ .op = .bitcast, .from_ty = .double, .value = lane, .to_ty = .{ .int = 64 } } });
        }
        var result: Lanes = .{ .ty = ty, .values = @splat(.poison) };
        for (result.values[0..s.len], 0..) |*lane, i| {
            const offset = i * (promotedLaneBits(ty) orelse s.bits);
            const word = words[offset / 64];
            const part = if (offset % 64 == 0) word else try b.binary(.lshr, .{ .int = 64 }, word, .{ .int = @intCast(offset % 64) });
            lane.* = try b.cast(.trunc, .{ .int = 64 }, part, s.scalar());
        }
        return result;
    }
    fn toAbi(b: Builder, lanes_value: Lanes) !ir.Value {
        const s = shape(lanes_value.ty) orelse return error.UnsupportedIntegerVector;
        const outgoing = abiType(lanes_value.ty) orelse return error.UnsupportedIntegerVector;
        if (outgoing == .double) return b.emit(.{ .cast = .{ .op = .bitcast, .from_ty = .{ .int = 64 }, .value = try b.pack(lanes_value), .to_ty = .double } });
        var vector: ir.Value = .poison;
        const stride = promotedLaneBits(lanes_value.ty) orelse s.bits;
        for (0..2) |word_index| {
            var word: ir.Value = .{ .int = 0 };
            for (0..64 / stride) |lane_index| {
                const source_index = word_index * (64 / stride) + lane_index;
                if (source_index >= s.len) continue;
                var lane = try b.cast(.zext, s.scalar(), lanes_value.values[source_index], .{ .int = 64 });
                if (lane_index != 0) lane = try b.binary(.shl, .{ .int = 64 }, lane, .{ .int = @intCast(lane_index * stride) });
                word = if (lane_index == 0) lane else try b.binary(.@"or", .{ .int = 64 }, word, lane);
            }
            const fp = try b.emit(.{ .cast = .{ .op = .bitcast, .from_ty = .{ .int = 64 }, .value = word, .to_ty = .double } });
            vector = try b.emit(.{ .insertelement = .{ .vector_ty = xmm_carrier, .vector = vector, .value_ty = .double, .value = fp, .index_ty = .{ .int = 64 }, .index = .{ .int = @intCast(word_index) } } });
        }
        return b.emit(.{ .cast = .{ .op = .bitcast, .from_ty = xmm_carrier, .value = vector, .to_ty = outgoing } });
    }
};

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    return expand(allocator, function, context) catch |err| switch (err) {
        error.UnsupportedIntegerVector => null,
        else => err,
    };
}

fn expand(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    if (!addresses.supportsLayout(if (context) |ctx| ctx.target_datalayout else null)) return null;
    if (context) |ctx| if (ctx.target_datalayout) |layout| {
        var parts = std.mem.splitScalar(u8, layout, '-');
        while (parts.next()) |part| if (part.len != 0 and part[0] == 'v') return null;
    };
    if (function.ret_ty == .vector and abiType(function.ret_ty) == null) return null;
    for (function.params.items) |param| if (param.ty == .vector and abiType(param.ty) == null) return null;
    // The native boundary bitcasts mark an already expanded private graph.
    // Leave these to vector selection instead of recursively unpacking them.
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (!inst.removed and inst.kind == .cast and inst.kind.cast.op == .bitcast and
            ((shape(inst.kind.cast.from_ty) != null and inst.kind.cast.to_ty.eql(xmm_carrier)) or
                (inst.kind.cast.from_ty.eql(xmm_carrier) and shape(inst.kind.cast.to_ty) != null))) return null;
    };
    var result = function;
    if (result.ret_ty == .vector) result.ret_ty = abiType(result.ret_ty).?;
    var parameters_cloned = false;
    for (function.params.items, 0..) |param, i| if (privateAbiType(param.ty)) |physical| {
        if (!parameters_cloned) {
            result.params = try function.params.clone(allocator);
            parameters_cloned = true;
        }
        result.params.items[i].ty = physical;
    };
    result.blocks = .empty;
    var vectors = std.StringHashMap(Lanes).init(allocator);
    defer vectors.deinit();
    var serial: forms.TemporaryNames = .{};
    defer serial.deinit(allocator);
    // PHI inputs may name any later vector producer. Give every lane a stable
    // private identity before traversal, then define those identities at each
    // producer. Backedges never depend on which block is visited first.
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed) continue;
        const ty = inst.resultType() orelse continue;
        const s = shape(ty) orelse continue;
        var lanes: Lanes = .{ .ty = ty, .values = @splat(.poison) };
        for (lanes.values[0..s.len]) |*lane| lane.* = .{ .named = try forms.temporary(allocator, function, &serial) };
        try vectors.put(inst.result orelse return error.UnsupportedIntegerVector, lanes);
    };
    var changed = false;
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        const b: Builder = .{ .allocator = allocator, .function = function, .block = &block, .serial = &serial, .vectors = &vectors };
        if (block_index == 0) for (function.params.items) |param| if (shape(param.ty) != null) {
            try vectors.put(param.name, try b.fromAbi(.{ .named = param.name }, param.ty));
            changed = true;
        };
        for (original.instructions.items) |inst| {
            if (inst.removed) {
                try block.instructions.append(allocator, inst);
                continue;
            }
            var value: ?Lanes = null;
            var handled = true;
            switch (inst.kind) {
                .gep => |gep| if (shape(gep.resultType())) |s| {
                    if (!s.pointer or gep.ptr_addrspace != null) return error.UnsupportedIntegerVector;
                    var lanes: Lanes = .{ .ty = gep.resultType(), .values = @splat(.poison) };
                    for (lanes.values[0..s.len], 0..) |*lane, i| {
                        var scalar = gep;
                        scalar.indices = try gep.indices.clone(allocator);
                        for (scalar.indices.items) |*index| if (shape(index.ty)) |indices| {
                            if (indices.pointer or indices.len != s.len) return error.UnsupportedIntegerVector;
                            index.value = try defined((try b.lanes(index.value, index.ty)).values[i], indices.scalar());
                            index.ty = indices.scalar();
                        };
                        lane.* = try b.emit(.{ .gep = scalar });
                    }
                    value = lanes;
                } else {
                    handled = false;
                },
                .phi => |phi| if (shape(phi.ty)) |s| {
                    const destinations = vectors.get(inst.result orelse return error.UnsupportedIntegerVector).?;
                    for (destinations.values[0..s.len], 0..) |destination, i| {
                        var copy = inst;
                        copy.result = destination.named;
                        copy.kind.phi.ty = s.scalar();
                        copy.kind.phi.incoming = try phi.incoming.clone(allocator);
                        for (copy.kind.phi.incoming.items) |*incoming|
                            incoming.value = try defined((try b.lanes(incoming.value, phi.ty)).values[i], s.scalar());
                        try block.instructions.append(allocator, copy);
                    }
                    changed = true;
                    continue;
                } else {
                    handled = false;
                },
                .freeze => |freeze| if (shape(freeze.ty)) |s| {
                    var lanes = try b.lanes(freeze.value, freeze.ty);
                    for (lanes.values[0..s.len]) |*lane| {
                        const concrete = try defined(lane.*, s.scalar());
                        lane.* = if (concrete == .named)
                            try b.emit(.{ .freeze = .{ .ty = s.scalar(), .value = concrete } })
                        else
                            concrete;
                    }
                    value = lanes;
                } else {
                    handled = false;
                },
                .alloca => |alloca| if (shape(alloca.allocated_ty)) |s| {
                    if (!alloca.isSingleObject() or alloca.allocated_ty_addrspace != null) return error.UnsupportedIntegerVector;
                    const bytes = (s.len * s.bits + 7) / 8;
                    const natural = try std.math.ceilPowerOfTwo(u32, bytes);
                    var alignment = natural;
                    if (alloca.attrs) |attrs| {
                        const text = std.mem.trim(u8, attrs, " \t");
                        if (!std.mem.startsWith(u8, text, "align ")) return error.UnsupportedIntegerVector;
                        alignment = @max(alignment, std.fmt.parseUnsigned(u32, text[6..], 10) catch return error.UnsupportedIntegerVector);
                    }
                    if (alignment > 4096 or alignment == 0 or !std.math.isPowerOfTwo(alignment) or (alignment > 16 and natural > 512)) return error.UnsupportedIntegerVector;
                    var copy = inst;
                    copy.kind.alloca.allocated_ty = .{ .aggregate = try std.fmt.allocPrint(allocator, "[{d} x i32]", .{@max(natural, 4) / 4}) };
                    copy.kind.alloca.attrs = try std.fmt.allocPrint(allocator, "align {d}", .{@max(alignment, 4)});
                    try block.instructions.append(allocator, copy);
                } else {
                    handled = false;
                },
                .load => |load| if (shape(load.ty)) |s| {
                    if (load.attrs.isBarrier() or load.attrs.syncscope != null or load.ty_addrspace != null or load.ptr_addrspace != null) return error.UnsupportedIntegerVector;
                    var lanes: Lanes = .{ .ty = load.ty, .values = @splat(.poison) };
                    if (s.bits % 8 == 0) {
                        for (lanes.values[0..s.len], 0..) |*lane, i| lane.* = try b.emit(.{ .load = .{
                            .ty = s.scalar(),
                            .ptr = try b.address(load.ptr, i * (s.bits / 8)),
                            .attrs = .{ .@"align" = 1 },
                        } });
                    } else {
                        const bits = s.len * s.bits;
                        if (bits == 8 or bits == 16 or bits == 32 or bits == 64 or bits == 128) {
                            const ty: ir.Type = .{ .int = @intCast(bits) };
                            const packed_value = try b.emit(.{ .load = .{ .ty = ty, .ptr = load.ptr, .attrs = load.attrs } });
                            lanes = try b.unpack(packed_value, ty, load.ty);
                        } else {
                            if (bits > 128) return error.UnsupportedIntegerVector;
                            const carrier: ir.Type = .{ .int = if (bits > 64) 128 else 64 };
                            var packed_value: ir.Value = .{ .int = 0 };
                            for (0..(bits + 7) / 8) |byte| {
                                const loaded = try b.emit(.{ .load = .{ .ty = .{ .int = 8 }, .ptr = try b.address(load.ptr, byte), .attrs = .{ .@"align" = 1 } } });
                                var part = try b.cast(.zext, .{ .int = 8 }, loaded, carrier);
                                if (byte != 0) part = try b.binary(.shl, carrier, part, .{ .int = @intCast(byte * 8) });
                                packed_value = if (byte == 0) part else try b.binary(.@"or", carrier, packed_value, part);
                            }
                            lanes = try b.unpack(packed_value, carrier, load.ty);
                        }
                    }
                    value = lanes;
                } else {
                    handled = false;
                },
                .store => |store| if (shape(store.ty)) |s| {
                    if (store.attrs.isBarrier() or store.attrs.syncscope != null or store.ty_addrspace != null or store.ptr_addrspace != null) return error.UnsupportedIntegerVector;
                    const lanes = try b.lanes(store.value, store.ty);
                    if (s.bits % 8 == 0) {
                        for (lanes.values[0..s.len], 0..) |lane, i| try block.instructions.append(allocator, .{ .result = null, .kind = .{ .store = .{
                            .ty = s.scalar(),
                            .value = try defined(lane, s.scalar()),
                            .ptr = try b.address(store.ptr, i * (s.bits / 8)),
                            .attrs = .{ .@"align" = 1 },
                        } } });
                    } else {
                        const bits = s.len * s.bits;
                        const carrier: ir.Type = .{ .int = if (bits > 64) 128 else 64 };
                        if (bits == 8 or bits == 16 or bits == 32 or bits == 64 or bits == 128) {
                            const ty: ir.Type = .{ .int = @intCast(bits) };
                            try block.instructions.append(allocator, .{ .result = null, .kind = .{ .store = .{
                                .ty = ty,
                                .value = try b.cast(.trunc, carrier, try b.pack(lanes), ty),
                                .ptr = store.ptr,
                                .attrs = store.attrs,
                            } } });
                        } else {
                            if (bits > 128) return error.UnsupportedIntegerVector;
                            const packed_value = try b.pack(lanes);
                            for (0..(bits + 7) / 8) |byte| {
                                const part = if (byte == 0) packed_value else try b.binary(.lshr, carrier, packed_value, .{ .int = @intCast(byte * 8) });
                                try block.instructions.append(allocator, .{ .result = null, .kind = .{ .store = .{ .ty = .{ .int = 8 }, .value = try b.cast(.trunc, carrier, part, .{ .int = 8 }), .ptr = try b.address(store.ptr, byte), .attrs = .{ .@"align" = 1 } } } });
                            }
                        }
                    }
                } else {
                    handled = false;
                },
                .insertelement => |insert| if (shape(insert.vector_ty)) |s| {
                    var lanes = try b.lanes(insert.vector, insert.vector_ty);
                    if (insert.index == .int) {
                        lanes.values[try laneIndex(insert.index, insert.index_ty, s.len)] = try defined(insert.value, s.scalar());
                    } else {
                        for (lanes.values[0..s.len], 0..) |*lane, i| lane.* = try b.select(try b.indexIs(insert.index, insert.index_ty, i), s.scalar(), insert.value, lane.*);
                    }
                    value = lanes;
                } else {
                    handled = false;
                },
                .shufflevector => |shuffle| if (shape(shuffle.lhs_ty)) |s| {
                    const output_ty = inst.resultType() orelse return error.UnsupportedIntegerVector;
                    const out = shape(output_ty) orelse return error.UnsupportedIntegerVector;
                    const left = try b.lanes(shuffle.lhs, shuffle.lhs_ty);
                    const right = try b.lanes(shuffle.rhs, shuffle.rhs_ty);
                    const mask = constantLanes(shuffle.mask, shuffle.mask_ty) orelse return error.UnsupportedIntegerVector;
                    var lanes: Lanes = .{ .ty = output_ty, .values = @splat(.poison) };
                    for (lanes.values[0..out.len], 0..) |*lane, i| {
                        if (mask.values[i] == .poison or mask.values[i] == .undef) continue;
                        const index = try laneIndex(mask.values[i], shuffle.mask_ty.vector.elem_ty.toType(), 2 * s.len);
                        lane.* = if (index < s.len) left.values[index] else right.values[index - s.len];
                    }
                    value = lanes;
                } else {
                    handled = false;
                },
                .extractelement => |extract| if (shape(extract.vector_ty)) |s| {
                    const lanes = try b.lanes(extract.vector, extract.vector_ty);
                    var selected: ir.Value = if (s.pointer) .null_value else .{ .int = 0 };
                    if (extract.index == .int) {
                        selected = lanes.values[try laneIndex(extract.index, extract.index_ty, s.len)];
                    } else {
                        // An out-of-range LLVM index produces poison; a defined
                        // zero is a valid refinement without an out-of-bounds load.
                        for (lanes.values[0..s.len], 0..) |lane, i| selected = try b.select(try b.indexIs(extract.index, extract.index_ty, i), s.scalar(), lane, selected);
                    }
                    try b.copy(inst, s.scalar(), selected);
                } else {
                    handled = false;
                },
                .binary => |binary| if (shape(binary.ty)) |s| {
                    if (s.pointer) return error.UnsupportedIntegerVector;
                    const left = try b.lanes(binary.lhs, binary.ty);
                    const right = try b.lanes(binary.rhs, binary.ty);
                    var lanes: Lanes = .{ .ty = binary.ty, .values = @splat(.poison) };
                    for (lanes.values[0..s.len], 0..) |*lane, i| {
                        var scalar = binary;
                        scalar.ty = s.scalar();
                        scalar.lhs = try defined(left.values[i], s.scalar());
                        scalar.rhs = try defined(right.values[i], s.scalar());
                        lane.* = try b.emit(.{ .binary = scalar });
                    }
                    value = lanes;
                } else {
                    handled = false;
                },
                .icmp => |cmp| if (shape(cmp.operand_ty)) |s| {
                    const left = try b.lanes(cmp.lhs, cmp.operand_ty);
                    const right = try b.lanes(cmp.rhs, cmp.operand_ty);
                    var lanes: Lanes = .{ .ty = inst.resultType().?, .values = @splat(.poison) };
                    for (lanes.values[0..s.len], 0..) |*lane, i| {
                        var scalar = cmp;
                        scalar.operand_ty = s.scalar();
                        scalar.lhs = try defined(left.values[i], s.scalar());
                        scalar.rhs = try defined(right.values[i], s.scalar());
                        lane.* = try b.emit(.{ .icmp = scalar });
                    }
                    value = lanes;
                } else {
                    handled = false;
                },
                .select => |select| if (shape(select.ty)) |s| {
                    const yes = try b.lanes(select.true_value, select.ty);
                    const no = try b.lanes(select.false_value, select.ty);
                    const conditions: ?Lanes = if (select.cond_ty == .vector) try b.lanes(select.cond, select.cond_ty) else null;
                    var lanes: Lanes = .{ .ty = select.ty, .values = @splat(.poison) };
                    for (lanes.values[0..s.len], 0..) |*lane, i| lane.* = try b.emit(.{ .select = .{
                        .cond_ty = .{ .int = 1 },
                        .cond = try defined(if (conditions) |v| v.values[i] else select.cond, .{ .int = 1 }),
                        .ty = s.scalar(),
                        .true_value = try defined(yes.values[i], s.scalar()),
                        .false_value = try defined(no.values[i], s.scalar()),
                    } });
                    value = lanes;
                } else {
                    handled = false;
                },
                .cast => |cast| if (shape(cast.from_ty) != null or shape(cast.to_ty) != null) {
                    const from = shape(cast.from_ty);
                    const to = shape(cast.to_ty);
                    if (from) |input| {
                        const source = try b.lanes(cast.value, cast.from_ty);
                        const bits = input.len * input.bits;
                        const carrier: ir.Type = .{ .int = if (bits > 64) 128 else 64 };
                        if (to) |output| {
                            if (cast.op == .bitcast) {
                                if (bits != output.len * output.bits) return error.UnsupportedIntegerVector;
                                if (input.pointer or output.pointer) {
                                    if (!cast.from_ty.eql(cast.to_ty)) return error.UnsupportedIntegerVector;
                                    value = source;
                                } else value = try b.repack(source, cast.to_ty);
                            } else {
                                if (input.len != output.len or (cast.op != .trunc and cast.op != .zext and cast.op != .sext and cast.op != .ptrtoint and cast.op != .inttoptr)) return error.UnsupportedIntegerVector;
                                var lanes: Lanes = .{ .ty = cast.to_ty, .values = @splat(.poison) };
                                for (lanes.values[0..output.len], 0..) |*lane, i| lane.* = try b.cast(cast.op, input.scalar(), source.values[i], output.scalar());
                                value = lanes;
                            }
                        } else {
                            if (input.pointer or cast.op != .bitcast or cast.to_ty != .int or cast.to_ty.int != bits) return error.UnsupportedIntegerVector;
                            try b.copy(inst, cast.to_ty, try b.cast(.trunc, carrier, try b.pack(source), cast.to_ty));
                        }
                    } else {
                        const output = to orelse unreachable;
                        if (output.pointer or cast.op != .bitcast or cast.from_ty != .int or cast.from_ty.int != output.len * output.bits) return error.UnsupportedIntegerVector;
                        value = try b.unpack(cast.value, cast.from_ty, cast.to_ty);
                    }
                } else {
                    handled = false;
                },
                .call => |call| if (call.args.items.len == 1 and shape(call.args.items[0].ty) != null and std.mem.startsWith(u8, call.callee, "llvm.vector.reduce.")) {
                    if (call.inline_asm != null or call.raw_args != null or call.operand_bundle != null or call.callee_value != null or call.ret_attrs != null or call.calling_conv != null or call.args.items[0].attrs != null) return error.UnsupportedIntegerVector;
                    const lanes = try b.lanes(call.args.items[0].value, call.args.items[0].ty);
                    const s = shape(lanes.ty).?;
                    if (s.pointer) return error.UnsupportedIntegerVector;
                    if (!call.ret_ty.eql(s.scalar())) return error.UnsupportedIntegerVector;
                    var accumulator = try defined(lanes.values[0], s.scalar());
                    var matched = false;
                    for ([_][]const u8{ "add", "and", "or", "xor", "umin", "umax", "smin", "smax" }, 0..) |op, op_index| {
                        const name = try std.fmt.allocPrint(allocator, "llvm.vector.reduce.{s}.v{d}i{d}", .{ op, s.len, s.bits });
                        if (!std.mem.eql(u8, name, call.callee)) continue;
                        matched = true;
                        for (lanes.values[1..s.len]) |lane| {
                            if (op_index < 4) {
                                const operations = [_]ir.BinaryOp{ .add, .@"and", .@"or", .xor };
                                accumulator = try b.binary(operations[op_index], s.scalar(), accumulator, lane);
                            } else {
                                const predicates = [_]ir.IcmpPredicate{ .ult, .ugt, .slt, .sgt };
                                const condition = try b.emit(.{ .icmp = .{ .predicate = predicates[op_index - 4], .operand_ty = s.scalar(), .lhs = accumulator, .rhs = try defined(lane, s.scalar()) } });
                                accumulator = try b.emit(.{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = condition, .ty = s.scalar(), .true_value = accumulator, .false_value = lane } });
                            }
                        }
                    }
                    if (!matched) return error.UnsupportedIntegerVector;
                    try b.copy(inst, s.scalar(), accumulator);
                } else if (try laneIntrinsic(allocator, call)) |callee| {
                    const s = shape(call.ret_ty).?;
                    var inputs: [3]Lanes = undefined;
                    for (call.args.items, 0..) |arg, i| if (arg.ty.eql(call.ret_ty)) {
                        inputs[i] = try b.lanes(arg.value, arg.ty);
                    };
                    var lanes: Lanes = .{ .ty = call.ret_ty, .values = @splat(.poison) };
                    for (lanes.values[0..s.len], 0..) |*lane, i| {
                        var scalar = call;
                        scalar.callee = callee;
                        scalar.ret_ty = s.scalar();
                        scalar.args = try call.args.clone(allocator);
                        for (scalar.args.items, 0..) |*arg, j| if (arg.ty.eql(call.ret_ty)) {
                            arg.ty = s.scalar();
                            arg.value = try defined(inputs[j].values[i], s.scalar());
                        };
                        lane.* = try b.emit(.{ .call = scalar });
                    }
                    value = lanes;
                } else if (hasVectorCall(call)) {
                    if (call.callee_value != null or call.inline_asm != null or call.raw_args != null or call.operand_bundle != null or call.tail_kind != null or std.mem.startsWith(u8, call.callee, "llvm.")) return error.UnsupportedIntegerVector;
                    var copy = inst;
                    copy.kind.call.args = try call.args.clone(allocator);
                    for (copy.kind.call.args.items) |*arg| if (shape(arg.ty) != null) {
                        arg.value = try b.toAbi(try b.lanes(arg.value, arg.ty));
                        arg.ty = abiType(arg.ty) orelse return error.UnsupportedIntegerVector;
                    };
                    if (shape(call.ret_ty) != null) copy.kind.call.ret_ty = abiType(call.ret_ty) orelse return error.UnsupportedIntegerVector;
                    try block.instructions.append(allocator, copy);
                    if (shape(call.ret_ty) != null) value = try b.fromAbi(.{ .named = inst.result orelse return error.UnsupportedIntegerVector }, call.ret_ty);
                } else {
                    handled = false;
                },
                else => handled = false,
            }
            if (handled) {
                changed = true;
                if (value) |lanes| try b.defineVector(inst, lanes);
            } else {
                // A partially expanded vector graph must never reach selection.
                var touches = false;
                _ = ir.operands.instruction(&inst, VectorUse{ .found = &touches }) catch unreachable;
                if (touches or (if (inst.resultType()) |ty| shape(ty) != null else false)) return error.UnsupportedIntegerVector;
                try block.instructions.append(allocator, inst);
            }
        }
        if (block.terminator) |*term| if (term.* == .ret and shape(term.ret.ty) != null) {
            term.ret.value = try b.toAbi(try b.lanes(term.ret.value orelse return error.UnsupportedIntegerVector, term.ret.ty));
            term.ret.ty = abiType(term.ret.ty) orelse return error.UnsupportedIntegerVector;
            changed = true;
        };
        try result.blocks.append(allocator, block);
    }
    return if (changed) result else null;
}

fn hasVectorCall(call: ir.CallInst) bool {
    if (shape(call.ret_ty) != null) return true;
    for (call.args.items) |arg| if (shape(arg.ty) != null) return true;
    return false;
}

const VectorUse = struct {
    pub const Error = error{};
    found: *bool,
    pub fn visit(v: VectorUse, _: *const ir.Value, ty: ir.Type) Error!void {
        if (shape(ty) != null) v.found.* = true;
    }
};
