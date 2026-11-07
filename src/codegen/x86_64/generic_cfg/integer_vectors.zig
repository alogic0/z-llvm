//! Private scalar lanes for bounded integer vectors. Memory uses the exact
//! byte extent (including packed i1 masks). Native 128-bit ABI values bridge
//! through full XMM bit carriers; vector PHIs and barriers remain closed.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const forms = @import("scalar_forms.zig");
const addresses = @import("../symbol_address.zig");
const integer = @import("../../../analysis/integer_semantics.zig").Integer;
const abi = @import("../sysv_abi.zig");
const xmm_carrier: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .double } };

const Shape = struct {
    len: u32,
    bits: u16,
    fn scalar(s: Shape) ir.Type {
        return .{ .int = s.bits };
    }
};
const Lanes = struct { ty: ir.Type, values: [16]ir.Value };

fn shape(ty: ir.Type) ?Shape {
    if (ty != .vector or ty.vector.len == 0 or ty.vector.len > 16 or ty.vector.elem_ty != .int or
        ty.vector.elem_ty.int == 0 or ty.vector.elem_ty.int > 64 or ty.vector.len * ty.vector.elem_ty.int > 128) return null;
    return .{ .len = ty.vector.len, .bits = ty.vector.elem_ty.int };
}
fn defined(value: ir.Value) !ir.Value {
    if (value != .int and value != .named) return error.UnsupportedIntegerVector;
    return value;
}
fn constantLanes(value: ir.Value, ty: ir.Type) ?Lanes {
    if (ty != .vector or ty.vector.len > 16) return null;
    inline for (1..17) |count| if (ty.vector.len == count) {
        const parsed = ir.vector_constant.parseFixed(count, value, ty.vector) orelse return null;
        var result: Lanes = .{ .ty = ty, .values = @splat(.poison) };
        for (parsed.lanes, 0..) |lane, i| result.values[i] = if (lane == .zero_initializer) .{ .int = 0 } else lane.value();
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
        _ = try defined(value);
        if (from.eql(to)) return value;
        if (value == .int) {
            const sem = integer.init(from) orelse return error.UnsupportedIntegerVector;
            const extended: i128 = if (op == .sext) sem.normalize(value.int) else @bitCast(sem.unsigned(value.int));
            return .{ .int = @bitCast((integer.init(to) orelse return error.UnsupportedIntegerVector).unsigned(extended)) };
        }
        return b.emit(.{ .cast = .{ .op = op, .from_ty = from, .value = value, .to_ty = to } });
    }
    fn binary(b: Builder, op: ir.BinaryOp, ty: ir.Type, a: ir.Value, c: ir.Value) !ir.Value {
        return b.emit(.{ .binary = .{ .op = op, .ty = ty, .lhs = try defined(a), .rhs = try defined(c) } });
    }
    fn copy(b: Builder, original: ir.Instruction, ty: ir.Type, value: ir.Value) !void {
        try b.block.instructions.append(b.allocator, .{ .result = original.result, .metadata = original.metadata, .kind = .{ .cast = .{ .op = .bitcast, .from_ty = ty, .value = try defined(value), .to_ty = ty } } });
    }
    fn address(b: Builder, ptr: ir.Value, offset: usize) !ir.Value {
        if (offset == 0) return ptr;
        var indices: std.ArrayList(ir.GepIndex) = .empty;
        try indices.append(b.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(offset) } });
        return b.emit(.{ .gep = .{ .source_ty = .{ .int = 8 }, .ptr = ptr, .indices = indices } });
    }
    fn indexIs(b: Builder, index: ir.Value, ty: ir.Type, lane: usize) !ir.Value {
        if (ty != .int or (ty.int != 32 and ty.int != 64)) return error.UnsupportedIntegerVector;
        return b.emit(.{ .icmp = .{ .predicate = .eq, .operand_ty = ty, .lhs = try defined(index), .rhs = .{ .int = @intCast(lane) } } });
    }
    fn select(b: Builder, condition: ir.Value, ty: ir.Type, yes: ir.Value, no: ir.Value) !ir.Value {
        return b.emit(.{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = condition, .ty = ty, .true_value = try defined(yes), .false_value = try defined(no) } });
    }
    fn pack(b: Builder, vector: Lanes) !ir.Value {
        const s = shape(vector.ty) orelse return error.UnsupportedIntegerVector;
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
        var result: Lanes = .{ .ty = ty, .values = @splat(.poison) };
        for (result.values[0..s.len], 0..) |*lane, i| {
            const part = if (i == 0) value else try b.binary(.lshr, carrier, value, .{ .int = @intCast(i * s.bits) });
            lane.* = try b.cast(.trunc, carrier, part, s.scalar());
        }
        return result;
    }
    fn fromAbi(b: Builder, value: ir.Value, ty: ir.Type) !Lanes {
        const s = shape(ty) orelse return error.UnsupportedIntegerVector;
        if (!abi.isVector128AbiType(ty)) return error.UnsupportedIntegerVector;
        const bits = try b.emit(.{ .cast = .{ .op = .bitcast, .from_ty = ty, .value = value, .to_ty = xmm_carrier } });
        var words: [2]ir.Value = undefined;
        for (&words, 0..) |*word, i| {
            const lane = try b.emit(.{ .extractelement = .{ .vector_ty = xmm_carrier, .vector = bits, .index_ty = .{ .int = 64 }, .index = .{ .int = @intCast(i) } } });
            word.* = try b.emit(.{ .cast = .{ .op = .bitcast, .from_ty = .double, .value = lane, .to_ty = .{ .int = 64 } } });
        }
        var result: Lanes = .{ .ty = ty, .values = @splat(.poison) };
        for (result.values[0..s.len], 0..) |*lane, i| {
            const offset = i * s.bits;
            const word = words[offset / 64];
            const part = if (offset % 64 == 0) word else try b.binary(.lshr, .{ .int = 64 }, word, .{ .int = @intCast(offset % 64) });
            lane.* = try b.cast(.trunc, .{ .int = 64 }, part, s.scalar());
        }
        return result;
    }
    fn toAbi(b: Builder, lanes_value: Lanes) !ir.Value {
        const s = shape(lanes_value.ty) orelse return error.UnsupportedIntegerVector;
        if (!abi.isVector128AbiType(lanes_value.ty)) return error.UnsupportedIntegerVector;
        var vector: ir.Value = .poison;
        for (0..2) |word_index| {
            var word: ir.Value = .{ .int = 0 };
            for (0..64 / s.bits) |lane_index| {
                var lane = try b.cast(.zext, s.scalar(), lanes_value.values[word_index * (64 / s.bits) + lane_index], .{ .int = 64 });
                if (lane_index != 0) lane = try b.binary(.shl, .{ .int = 64 }, lane, .{ .int = @intCast(lane_index * s.bits) });
                word = if (lane_index == 0) lane else try b.binary(.@"or", .{ .int = 64 }, word, lane);
            }
            const fp = try b.emit(.{ .cast = .{ .op = .bitcast, .from_ty = .{ .int = 64 }, .value = word, .to_ty = .double } });
            vector = try b.emit(.{ .insertelement = .{ .vector_ty = xmm_carrier, .vector = vector, .value_ty = .double, .value = fp, .index_ty = .{ .int = 64 }, .index = .{ .int = @intCast(word_index) } } });
        }
        return b.emit(.{ .cast = .{ .op = .bitcast, .from_ty = xmm_carrier, .value = vector, .to_ty = lanes_value.ty } });
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
    if (function.ret_ty == .vector and !abi.isVector128AbiType(function.ret_ty)) return null;
    for (function.params.items) |param| if (param.ty == .vector and !abi.isVector128AbiType(param.ty)) return null;
    // The native boundary bitcasts mark an already expanded private graph.
    // Leave these to vector selection instead of recursively unpacking them.
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (!inst.removed and inst.kind == .cast and inst.kind.cast.op == .bitcast and
            ((shape(inst.kind.cast.from_ty) != null and inst.kind.cast.to_ty.eql(xmm_carrier)) or
                (inst.kind.cast.from_ty.eql(xmm_carrier) and shape(inst.kind.cast.to_ty) != null))) return null;
    };
    var result = function;
    result.blocks = .empty;
    var vectors = std.StringHashMap(Lanes).init(allocator);
    defer vectors.deinit();
    var serial: forms.TemporaryNames = .{};
    defer serial.deinit(allocator);
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
                    if (alignment > 16 or alignment == 0 or !std.math.isPowerOfTwo(alignment)) return error.UnsupportedIntegerVector;
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
                    if (s.bits == 8 or s.bits == 16 or s.bits == 32 or s.bits == 64) {
                        for (lanes.values[0..s.len], 0..) |*lane, i| lane.* = try b.emit(.{ .load = .{
                            .ty = s.scalar(),
                            .ptr = try b.address(load.ptr, i * (s.bits / 8)),
                            .attrs = .{ .@"align" = 1 },
                        } });
                    } else {
                        const bits = s.len * s.bits;
                        if (bits != 8 and bits != 16 and bits != 32 and bits != 64 and bits != 128) return error.UnsupportedIntegerVector;
                        const ty: ir.Type = .{ .int = @intCast(bits) };
                        const packed_value = try b.emit(.{ .load = .{ .ty = ty, .ptr = load.ptr, .attrs = load.attrs } });
                        lanes = try b.unpack(packed_value, ty, load.ty);
                    }
                    value = lanes;
                } else {
                    handled = false;
                },
                .store => |store| if (shape(store.ty)) |s| {
                    if (store.attrs.isBarrier() or store.attrs.syncscope != null or store.ty_addrspace != null or store.ptr_addrspace != null) return error.UnsupportedIntegerVector;
                    const lanes = try b.lanes(store.value, store.ty);
                    if (s.bits == 8 or s.bits == 16 or s.bits == 32 or s.bits == 64) {
                        for (lanes.values[0..s.len], 0..) |lane, i| try block.instructions.append(allocator, .{ .result = null, .kind = .{ .store = .{
                            .ty = s.scalar(),
                            .value = try defined(lane),
                            .ptr = try b.address(store.ptr, i * (s.bits / 8)),
                            .attrs = .{ .@"align" = 1 },
                        } } });
                    } else {
                        const bits = s.len * s.bits;
                        if (bits != 8 and bits != 16 and bits != 32 and bits != 64 and bits != 128) return error.UnsupportedIntegerVector;
                        const carrier: ir.Type = .{ .int = if (bits > 64) 128 else 64 };
                        const ty: ir.Type = .{ .int = @intCast(bits) };
                        try block.instructions.append(allocator, .{ .result = null, .kind = .{ .store = .{
                            .ty = ty,
                            .value = try b.cast(.trunc, carrier, try b.pack(lanes), ty),
                            .ptr = store.ptr,
                            .attrs = store.attrs,
                        } } });
                    }
                } else {
                    handled = false;
                },
                .insertelement => |insert| if (shape(insert.vector_ty)) |s| {
                    var lanes = try b.lanes(insert.vector, insert.vector_ty);
                    if (insert.index == .int) {
                        lanes.values[try laneIndex(insert.index, insert.index_ty, s.len)] = try defined(insert.value);
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
                    var selected: ir.Value = .{ .int = 0 };
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
                    const left = try b.lanes(binary.lhs, binary.ty);
                    const right = try b.lanes(binary.rhs, binary.ty);
                    var lanes: Lanes = .{ .ty = binary.ty, .values = @splat(.poison) };
                    for (lanes.values[0..s.len], 0..) |*lane, i| {
                        var scalar = binary;
                        scalar.ty = s.scalar();
                        scalar.lhs = try defined(left.values[i]);
                        scalar.rhs = try defined(right.values[i]);
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
                        scalar.lhs = try defined(left.values[i]);
                        scalar.rhs = try defined(right.values[i]);
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
                        .cond = try defined(if (conditions) |v| v.values[i] else select.cond),
                        .ty = s.scalar(),
                        .true_value = try defined(yes.values[i]),
                        .false_value = try defined(no.values[i]),
                    } });
                    value = lanes;
                } else {
                    handled = false;
                },
                .cast => |cast| if (shape(cast.from_ty) != null or shape(cast.to_ty) != null) {
                    const from = shape(cast.from_ty) orelse return error.UnsupportedIntegerVector;
                    const to = shape(cast.to_ty) orelse return error.UnsupportedIntegerVector;
                    const source = try b.lanes(cast.value, cast.from_ty);
                    if (cast.op == .bitcast) {
                        if (from.len * from.bits != to.len * to.bits) return error.UnsupportedIntegerVector;
                        value = try b.unpack(try b.pack(source), .{ .int = if (from.len * from.bits > 64) 128 else 64 }, cast.to_ty);
                    } else {
                        if (from.len != to.len or (cast.op != .trunc and cast.op != .zext and cast.op != .sext)) return error.UnsupportedIntegerVector;
                        var lanes: Lanes = .{ .ty = cast.to_ty, .values = @splat(.poison) };
                        for (lanes.values[0..to.len], 0..) |*lane, i| lane.* = try b.cast(cast.op, from.scalar(), source.values[i], to.scalar());
                        value = lanes;
                    }
                } else {
                    handled = false;
                },
                .call => |call| if (call.args.items.len == 1 and shape(call.args.items[0].ty) != null and std.mem.startsWith(u8, call.callee, "llvm.vector.reduce.")) {
                    if (call.inline_asm != null or call.raw_args != null or call.operand_bundle != null or call.callee_value != null or call.ret_attrs != null or call.calling_conv != null or call.args.items[0].attrs != null) return error.UnsupportedIntegerVector;
                    const lanes = try b.lanes(call.args.items[0].value, call.args.items[0].ty);
                    const s = shape(lanes.ty).?;
                    if (!call.ret_ty.eql(s.scalar())) return error.UnsupportedIntegerVector;
                    var accumulator = try defined(lanes.values[0]);
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
                                const condition = try b.emit(.{ .icmp = .{ .predicate = predicates[op_index - 4], .operand_ty = s.scalar(), .lhs = accumulator, .rhs = try defined(lane) } });
                                accumulator = try b.emit(.{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = condition, .ty = s.scalar(), .true_value = accumulator, .false_value = lane } });
                            }
                        }
                    }
                    if (!matched) return error.UnsupportedIntegerVector;
                    try b.copy(inst, s.scalar(), accumulator);
                } else if (hasVectorCall(call)) {
                    if (call.callee_value != null or call.inline_asm != null or call.raw_args != null or call.operand_bundle != null or call.tail_kind != null or std.mem.startsWith(u8, call.callee, "llvm.")) return error.UnsupportedIntegerVector;
                    var copy = inst;
                    copy.kind.call.args = try call.args.clone(allocator);
                    for (copy.kind.call.args.items) |*arg| if (shape(arg.ty) != null) {
                        arg.value = try b.toAbi(try b.lanes(arg.value, arg.ty));
                    };
                    try block.instructions.append(allocator, copy);
                    if (shape(call.ret_ty) != null) value = try b.fromAbi(.{ .named = inst.result orelse return error.UnsupportedIntegerVector }, call.ret_ty);
                } else {
                    handled = false;
                },
                else => handled = false,
            }
            if (handled) {
                changed = true;
                if (value) |lanes| try vectors.put(inst.result orelse return error.UnsupportedIntegerVector, lanes);
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
