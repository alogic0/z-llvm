//! Private scalar lanes for FP vector computation. Native 128-bit vectors keep
//! their XMM boundary; <2 x float> uses the same low64 XMM ABI as a raw double.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const sysv = @import("../sysv_abi.zig");
const forms = @import("scalar_forms.zig");
const addresses = @import("../symbol_address.zig");
const max_lanes = 64;
const Lanes = struct { ty: ir.Type, values: [max_lanes]ir.Value = @splat(.poison) };
fn fp(ty: ir.Type) bool {
    return ty == .vector and ty.vector.len > 0 and ty.vector.len <= max_lanes and
        (ty.vector.elem_ty == .half or ty.vector.elem_ty == .float or ty.vector.elem_ty == .double or ty.vector.elem_ty == .x86_fp80 or ty.vector.elem_ty == .fp128);
}
fn width(ty: ir.Type) u16 {
    return if (ty == .half) 16 else if (ty == .float) 32 else if (ty == .double) 64 else if (ty == .x86_fp80) 80 else 128;
}
fn packedPair(ty: ir.Type) bool {
    return fp(ty) and ty.vector.len == 2 and ty.vector.elem_ty == .float;
}
fn abiType(ty: ir.Type) !ir.Type {
    if (!fp(ty)) return ty;
    if (packedPair(ty)) return .double;
    if (sysv.isVector128AbiType(ty)) return ty;
    return error.UnsupportedFloatingVectorAbi;
}
fn needed(function: ir.Function) bool {
    if (packedPair(function.ret_ty)) return true;
    for (function.params.items) |p| if (packedPair(p.ty)) return true;
    var crossing = false;
    var integer_binary = false;
    var shuffle = false;
    var native_fp_cast = false;
    var unsupported_shuffle = false;
    var owned_storage = false;
    // A native vector may also be the physical carrier of a scalar quad
    // parameter. Restrict this additional storage trigger to scalar boundaries;
    // existing vector ABI rewrites retain their original activation rules.
    var scalar_boundary = !fp(function.ret_ty);
    for (function.params.items) |p| scalar_boundary = scalar_boundary and !fp(p.ty);
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed) continue;
        if (inst.resultType()) |ty| if (fp(ty)) {
            if (!sysv.isVector128AbiType(ty) and !packedPair(ty)) return true;
        };
        switch (inst.kind) {
            .alloca => |x| {
                owned_storage = owned_storage or fp(x.allocated_ty);
            },
            .cast => |c| {
                if ((c.op == .fptrunc or c.op == .fpext) and fp(c.from_ty) and fp(c.to_ty)) native_fp_cast = true;
                if ((fp(c.from_ty) and c.to_ty == .vector and c.to_ty.vector.elem_ty == .int) or
                    (fp(c.to_ty) and c.from_ty == .vector and c.from_ty.vector.elem_ty == .int))
                {
                    crossing = true;
                }
            },
            .shufflevector => |s| if (fp(s.lhs_ty)) {
                shuffle = true;
                unsupported_shuffle = unsupported_shuffle or
                    (if (s.lhs_ty.vector.len == 4 and s.lhs_ty.vector.elem_ty == .float)
                        ir.vector_constant.classifyPackedF32x4ShuffleMask(s) == null
                    else
                        ir.vector_constant.classifyPacked2ShuffleMask(s) == null);
            },
            .call => |c| {
                if (packedPair(c.ret_ty)) return true;
                for (c.args.items) |arg| if (packedPair(arg.ty)) return true;
            },
            .binary => |b| if (b.ty == .vector and b.ty.vector.elem_ty == .int) {
                integer_binary = true;
            },
            else => {},
        }
    };
    return (crossing and integer_binary) or unsupported_shuffle or (shuffle and !native_fp_cast) or (owned_storage and scalar_boundary);
}
fn stable(value: ir.Value, ty: ir.Type) !ir.Value {
    if (value == .undef or value == .poison or value == .zero_initializer)
        return .{ .fp = if (ty == .half) "0xH0000" else if (ty == .x86_fp80) "0xK00000000000000000000" else "0.000000e+00" };
    if (value != .named and value != .fp) return error.UnsupportedFloatingVector;
    return value;
}
fn constants(value: ir.Value, ty: ir.Type) !Lanes {
    inline for (1..max_lanes + 1) |count| if (ty.vector.len == count) {
        const parsed = ir.vector_constant.parseFixed(count, value, ty.vector) orelse return error.UnsupportedFloatingVector;
        var result: Lanes = .{ .ty = ty };
        for (parsed.lanes, 0..) |lane, i| result.values[i] = try stable(lane.value(), ty.vector.elem_ty.toType());
        return result;
    };
    return error.UnsupportedFloatingVector;
}
fn index(value: ir.Value, len: usize) !usize {
    if (value != .int or value.int < 0 or value.int >= len) return error.UnsupportedFloatingVector;
    return @intCast(value.int);
}
const Builder = struct {
    a: std.mem.Allocator,
    f: ir.Function,
    block: *ir.BasicBlock,
    names: *forms.TemporaryNames,
    vectors: *std.StringHashMap(Lanes),
    fn emit(b: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const name = try forms.temporary(b.a, b.f, b.names);
        try b.block.instructions.append(b.a, .{ .result = name, .kind = kind });
        return .{ .named = name };
    }
    fn lanes(b: Builder, value: ir.Value, ty: ir.Type) !Lanes {
        if (value != .named) return constants(value, ty);
        const result = b.vectors.get(value.named) orelse return error.UnsupportedFloatingVectorValue;
        if (!result.ty.eql(ty)) return error.UnsupportedFloatingVector;
        return result;
    }
    fn cast(b: Builder, op: ir.CastOp, from: ir.Type, value: ir.Value, to: ir.Type) !ir.Value {
        return b.emit(.{ .cast = .{ .op = op, .from_ty = from, .value = value, .to_ty = to } });
    }
    fn copy(b: Builder, name: []const u8, ty: ir.Type, value: ir.Value) !void {
        const raw: ir.Type = .{ .int = width(ty) };
        const bits = try b.cast(.bitcast, ty, try stable(value, ty), raw);
        try b.block.instructions.append(b.a, .{ .result = name, .kind = .{ .cast = .{ .op = .bitcast, .from_ty = raw, .value = bits, .to_ty = ty } } });
    }
    fn define(b: Builder, name: []const u8, lanes_value: Lanes) !void {
        const destinations = b.vectors.get(name) orelse return error.UnsupportedFloatingVector;
        for (destinations.values[0..lanes_value.ty.vector.len], lanes_value.values[0..lanes_value.ty.vector.len]) |dst, src|
            try b.copy(dst.named, lanes_value.ty.vector.elem_ty.toType(), src);
    }
    fn vector(b: Builder, name: []const u8, ty: ir.Type, values: []const ir.Value) !void {
        var previous: ir.Value = .poison;
        for (values, 0..) |value, i| {
            const kind: @FieldType(ir.Instruction, "kind") = .{ .insertelement = .{ .vector_ty = ty, .vector = previous, .value_ty = ty.vector.elem_ty.toType(), .value = value, .index_ty = .{ .int = 64 }, .index = .{ .int = @intCast(i) } } };
            if (i + 1 == values.len) try b.block.instructions.append(b.a, .{ .result = name, .kind = kind }) else previous = try b.emit(kind);
        }
    }
    fn fromAbi(b: Builder, value: ir.Value, ty: ir.Type) !Lanes {
        var result: Lanes = .{ .ty = ty };
        if (packedPair(ty)) {
            const word: ir.Type = .{ .int = 64 };
            const bits = try b.cast(.bitcast, .double, value, word);
            for (0..2) |i| {
                const shifted = if (i == 0) bits else try b.emit(.{ .binary = .{ .op = .lshr, .ty = word, .lhs = bits, .rhs = .{ .int = 32 } } });
                result.values[i] = try b.cast(.bitcast, .{ .int = 32 }, try b.cast(.trunc, word, shifted, .{ .int = 32 }), .float);
            }
        } else {
            _ = try abiType(ty);
            for (0..ty.vector.len) |i| result.values[i] = try b.emit(.{ .extractelement = .{ .vector_ty = ty, .vector = value, .index_ty = .{ .int = 64 }, .index = .{ .int = @intCast(i) } } });
        }
        return result;
    }
    fn toAbi(b: Builder, value: ir.Value, ty: ir.Type) !ir.Value {
        const lanes_value = try b.lanes(value, ty);
        if (packedPair(ty)) {
            const word: ir.Type = .{ .int = 64 };
            var bits: [2]ir.Value = undefined;
            for (&bits, 0..) |*part, i| part.* = try b.cast(.zext, .{ .int = 32 }, try b.cast(.bitcast, .float, try stable(lanes_value.values[i], .float), .{ .int = 32 }), word);
            const high = try b.emit(.{ .binary = .{ .op = .shl, .ty = word, .lhs = bits[1], .rhs = .{ .int = 32 } } });
            const joined = try b.emit(.{ .binary = .{ .op = .@"or", .ty = word, .lhs = bits[0], .rhs = high } });
            return b.cast(.bitcast, word, joined, .double);
        }
        _ = try abiType(ty);
        const name = try forms.temporary(b.a, b.f, b.names);
        try b.vector(name, ty, lanes_value.values[0..ty.vector.len]);
        return .{ .named = name };
    }
    fn pointer(b: Builder, base: ir.Value, offset: usize) !ir.Value {
        if (offset == 0) return base;
        var indices: std.ArrayList(ir.GepIndex) = .empty;
        try indices.append(b.a, .{ .ty = .{ .int = 64 }, .value = .{ .int = @intCast(offset) } });
        return b.emit(.{ .gep = .{ .source_ty = .{ .int = 8 }, .ptr = base, .indices = indices } });
    }
};
pub fn legalize(a: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    if (!needed(function) or !addresses.supportsLayout(if (context) |c| c.target_datalayout else null)) return null;
    // Lane offsets use the native scalar allocation stride. Explicit vector
    // layout overrides need their own representation rather than this path.
    if (context) |c| if (c.target_datalayout) |layout| {
        var parts = std.mem.splitScalar(u8, layout, '-');
        while (parts.next()) |part| if (part.len != 0 and part[0] == 'v') return null;
    };
    const layout = try @import("../../../target.zig").DataLayout.parse(if (context) |c| c.target_datalayout orelse "" else "");
    return expand(a, function, layout) catch |err| switch (err) {
        error.UnsupportedFloatingVector, error.UnsupportedFloatingVectorAbi, error.UnsupportedFloatingVectorValue, error.UnsupportedFloatingVectorCast, error.UnsupportedFloatingVectorDefinition => blk: {
            break :blk null;
        },
        else => err,
    };
}
fn expand(a: std.mem.Allocator, function: ir.Function, layout: @import("../../../target.zig").DataLayout) !?ir.Function {
    var vectors = std.StringHashMap(Lanes).init(a);
    defer vectors.deinit();
    var names: forms.TemporaryNames = .{};
    defer names.deinit(a);
    for (function.params.items) |p| if (fp(p.ty)) {
        var lanes_value: Lanes = .{ .ty = p.ty };
        for (lanes_value.values[0..p.ty.vector.len]) |*value| value.* = .{ .named = try forms.temporary(a, function, &names) };
        try vectors.put(p.name, lanes_value);
    };
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed) continue;
        const ty = inst.resultType() orelse continue;
        if (!fp(ty)) continue;
        var lanes_value: Lanes = .{ .ty = ty };
        for (lanes_value.values[0..ty.vector.len]) |*value| value.* = .{ .named = try forms.temporary(a, function, &names) };
        try vectors.put(inst.result.?, lanes_value);
    };
    var result = function;
    result.ret_ty = try abiType(function.ret_ty);
    result.params = try function.params.clone(a);
    for (result.params.items) |*p| p.ty = try abiType(p.ty);
    result.blocks = .empty;
    for (function.blocks.items, 0..) |original, bi| {
        var block = original;
        block.instructions = .empty;
        const b: Builder = .{ .a = a, .f = function, .block = &block, .names = &names, .vectors = &vectors };
        if (bi == 0) for (function.params.items) |p| if (fp(p.ty)) try b.define(p.name, try b.fromAbi(.{ .named = p.name }, p.ty));
        for (original.instructions.items) |inst| {
            if (inst.removed) {
                try block.instructions.append(a, inst);
                continue;
            }
            var lanes_value: ?Lanes = null;
            switch (inst.kind) {
                .insertelement => |x| if (fp(x.vector_ty)) {
                    var lanes = try b.lanes(x.vector, x.vector_ty);
                    lanes.values[try index(x.index, x.vector_ty.vector.len)] = try stable(x.value, x.value_ty);
                    lanes_value = lanes;
                },
                .shufflevector => |x| if (fp(x.lhs_ty) and x.lhs_ty.eql(x.rhs_ty)) {
                    const ty = inst.resultType().?;
                    const left = try b.lanes(x.lhs, x.lhs_ty);
                    const right = try b.lanes(x.rhs, x.rhs_ty);
                    var lanes: Lanes = .{ .ty = ty };
                    inline for (1..max_lanes + 1) |count| if (ty.vector.len == count) {
                        const mask = ir.vector_constant.parseFixed(count, x.mask, x.mask_ty.vector) orelse return error.UnsupportedFloatingVector;
                        for (mask.lanes, 0..) |lane, i| {
                            const chosen = if (lane == .undef or lane == .poison or lane == .zero_initializer) 0 else try index(lane.value(), 2 * x.lhs_ty.vector.len);
                            lanes.values[i] = if (chosen < x.lhs_ty.vector.len) left.values[chosen] else right.values[chosen - x.lhs_ty.vector.len];
                        }
                    };
                    lanes_value = lanes;
                },
                .binary => |x| if (fp(x.ty)) {
                    if (x.op != .fadd and x.op != .fsub and x.op != .fmul and x.op != .fdiv and x.op != .frem) return error.UnsupportedFloatingVector;
                    const left = try b.lanes(x.lhs, x.ty);
                    const right = try b.lanes(x.rhs, x.ty);
                    var lanes: Lanes = .{ .ty = x.ty };
                    for (0..x.ty.vector.len) |i| {
                        var scalar = x;
                        scalar.ty = x.ty.vector.elem_ty.toType();
                        scalar.lhs = left.values[i];
                        scalar.rhs = right.values[i];
                        lanes.values[i] = try b.emit(.{ .binary = scalar });
                    }
                    lanes_value = lanes;
                },
                .extractelement => |x| if (fp(x.vector_ty)) {
                    const lanes = try b.lanes(x.vector, x.vector_ty);
                    try b.copy(inst.result.?, x.vector_ty.vector.elem_ty.toType(), lanes.values[try index(x.index, x.vector_ty.vector.len)]);
                    continue;
                },
                .fcmp => |x| if (fp(x.operand_ty)) {
                    const left = try b.lanes(x.lhs, x.operand_ty);
                    const right = try b.lanes(x.rhs, x.operand_ty);
                    var values: [max_lanes]ir.Value = undefined;
                    for (values[0..x.operand_ty.vector.len], 0..) |*value, i| {
                        var scalar = x;
                        scalar.operand_ty = x.operand_ty.vector.elem_ty.toType();
                        scalar.lhs = left.values[i];
                        scalar.rhs = right.values[i];
                        value.* = try b.emit(.{ .fcmp = scalar });
                    }
                    try b.vector(inst.result.?, inst.resultType().?, values[0..x.operand_ty.vector.len]);
                    continue;
                },
                .cast => |x| if (fp(x.from_ty) or fp(x.to_ty)) {
                    if (x.op == .bitcast and packedPair(x.from_ty) and x.to_ty.eql(.{ .int = 64 })) {
                        var copy = inst;
                        copy.kind.cast.from_ty = .double;
                        copy.kind.cast.value = try b.toAbi(x.value, x.from_ty);
                        try block.instructions.append(a, copy);
                        continue;
                    }
                    if (x.op == .bitcast and x.from_ty.eql(.{ .int = 64 }) and packedPair(x.to_ty)) {
                        try b.define(inst.result.?, try b.fromAbi(try b.cast(.bitcast, x.from_ty, x.value, .double), x.to_ty));
                        continue;
                    }
                    if (x.from_ty != .vector or x.to_ty != .vector or x.from_ty.vector.len != x.to_ty.vector.len) return error.UnsupportedFloatingVectorCast;
                    const count = x.from_ty.vector.len;
                    var values: [max_lanes]ir.Value = undefined;
                    const source = if (fp(x.from_ty)) try b.lanes(x.value, x.from_ty) else null;
                    for (values[0..count], 0..) |*value, i| {
                        const input = if (source) |lanes| lanes.values[i] else try b.emit(.{ .extractelement = .{ .vector_ty = x.from_ty, .vector = x.value, .index_ty = .{ .int = 64 }, .index = .{ .int = @intCast(i) } } });
                        value.* = try b.cast(x.op, x.from_ty.vector.elem_ty.toType(), input, x.to_ty.vector.elem_ty.toType());
                    }
                    if (!fp(x.to_ty)) {
                        try b.vector(inst.result.?, x.to_ty, values[0..count]);
                        continue;
                    }
                    var lanes: Lanes = .{ .ty = x.to_ty };
                    @memcpy(lanes.values[0..count], values[0..count]);
                    lanes_value = lanes;
                },
                .phi => |x| if (fp(x.ty)) {
                    const destinations = vectors.get(inst.result.?).?;
                    for (0..x.ty.vector.len) |i| {
                        var scalar = x;
                        scalar.ty = x.ty.vector.elem_ty.toType();
                        scalar.incoming = .empty;
                        for (x.incoming.items) |incoming| {
                            var edge = incoming;
                            edge.value = (try b.lanes(incoming.value, x.ty)).values[i];
                            try scalar.incoming.append(a, edge);
                        }
                        try block.instructions.append(a, .{ .result = destinations.values[i].named, .kind = .{ .phi = scalar } });
                    }
                    continue;
                },
                .select => |x| if (fp(x.ty)) {
                    const yes = try b.lanes(x.true_value, x.ty);
                    const no = try b.lanes(x.false_value, x.ty);
                    var lanes: Lanes = .{ .ty = x.ty };
                    for (0..x.ty.vector.len) |i| {
                        var scalar = x;
                        scalar.ty = x.ty.vector.elem_ty.toType();
                        scalar.true_value = yes.values[i];
                        scalar.false_value = no.values[i];
                        if (x.cond_ty == .vector) {
                            scalar.cond_ty = .{ .int = 1 };
                            scalar.cond = try b.emit(.{ .extractelement = .{ .vector_ty = x.cond_ty, .vector = x.cond, .index_ty = .{ .int = 64 }, .index = .{ .int = @intCast(i) } } });
                        }
                        lanes.values[i] = try b.emit(.{ .select = scalar });
                    }
                    lanes_value = lanes;
                },
                .alloca => |x| if (fp(x.allocated_ty)) {
                    if (!x.isSingleObject()) return error.UnsupportedFloatingVector;
                    var copy = inst;
                    copy.kind.alloca.allocated_ty = .{ .aggregate = try std.fmt.allocPrint(a, "[{d} x i8]", .{try layout.typeAllocSizeBytes(x.allocated_ty)}) };
                    if (copy.kind.alloca.attrs == null) copy.kind.alloca.attrs = try std.fmt.allocPrint(a, "align {d}", .{(try layout.typeAbiAlignmentBits(x.allocated_ty)) / 8});
                    try block.instructions.append(a, copy);
                    continue;
                },
                .load => |x| if (fp(x.ty)) {
                    if (x.attrs.isBarrier() or x.ty_addrspace != null or x.ptr_addrspace != null or x.attrs.syncscope != null) return error.UnsupportedFloatingVector;
                    const scalar = x.ty.vector.elem_ty.toType();
                    var lanes: Lanes = .{ .ty = x.ty };
                    for (0..x.ty.vector.len) |i| lanes.values[i] = try b.emit(.{ .load = .{ .ty = scalar, .ptr = try b.pointer(x.ptr, i * (width(scalar) / 8)), .attrs = .{ .@"align" = 1 } } });
                    lanes_value = lanes;
                },
                .store => |x| if (fp(x.ty)) {
                    if (x.attrs.isBarrier() or x.ty_addrspace != null or x.ptr_addrspace != null or x.attrs.syncscope != null) return error.UnsupportedFloatingVector;
                    const scalar = x.ty.vector.elem_ty.toType();
                    const lanes = try b.lanes(x.value, x.ty);
                    for (0..x.ty.vector.len) |i| try block.instructions.append(a, .{ .result = null, .kind = .{ .store = .{ .ty = scalar, .value = lanes.values[i], .ptr = try b.pointer(x.ptr, i * (width(scalar) / 8)), .attrs = .{ .@"align" = 1 } } } });
                    continue;
                },
                .call => |x| {
                    if (fp(x.ret_ty) and std.mem.startsWith(u8, x.callee, "llvm.")) {
                        const scalar = x.ret_ty.vector.elem_ty.toType();
                        var operation: ?[]const u8 = null;
                        var buffer: [64]u8 = undefined;
                        for ([_][]const u8{ "fabs", "copysign" }) |op| {
                            const spelling = try std.fmt.bufPrint(&buffer, "llvm.{s}.v{d}f{d}", .{ op, x.ret_ty.vector.len, width(scalar) });
                            if (std.mem.eql(u8, x.callee, spelling)) operation = op;
                        }
                        const op = operation orelse return error.UnsupportedFloatingVector;
                        if (x.args.items.len != (if (std.mem.eql(u8, op, "fabs")) @as(usize, 1) else 2) or x.inline_asm != null or x.callee_value != null or x.callee_function_ty != null or x.raw_args != null or x.operand_bundle != null or x.calling_conv != null or x.ret_attrs != null) return error.UnsupportedFloatingVector;
                        if (x.tail_kind) |tail| if (std.mem.eql(u8, tail, "musttail")) return error.UnsupportedFloatingVector;
                        var inputs: [2]Lanes = undefined;
                        for (x.args.items, 0..) |arg, i| {
                            if (!arg.ty.eql(x.ret_ty) or arg.attrs != null) return error.UnsupportedFloatingVector;
                            inputs[i] = try b.lanes(arg.value, arg.ty);
                        }
                        var lanes: Lanes = .{ .ty = x.ret_ty };
                        for (0..x.ret_ty.vector.len) |i| {
                            var call: ir.CallInst = .{ .callee = try std.fmt.allocPrint(a, "llvm.{s}.f{d}", .{ op, width(scalar) }), .ret_ty = scalar, .args = .empty };
                            for (0..x.args.items.len) |j| try call.args.append(a, .{ .ty = scalar, .value = inputs[j].values[i] });
                            lanes.values[i] = try b.emit(.{ .call = call });
                        }
                        try b.define(inst.result.?, lanes);
                        continue;
                    }
                    var copy = inst;
                    var changed = fp(x.ret_ty);
                    copy.kind.call.args = try x.args.clone(a);
                    if (fp(x.ret_ty)) copy.kind.call.ret_ty = try abiType(x.ret_ty);
                    for (copy.kind.call.args.items) |*arg| if (fp(arg.ty)) {
                        changed = true;
                        arg.value = try b.toAbi(arg.value, arg.ty);
                        arg.ty = try abiType(arg.ty);
                    };
                    if (changed) {
                        if (x.inline_asm != null or std.mem.startsWith(u8, x.callee, "llvm.")) return error.UnsupportedFloatingVector;
                        if (fp(x.ret_ty)) {
                            const call_value = try b.emit(copy.kind);
                            lanes_value = try b.fromAbi(call_value, x.ret_ty);
                        } else {
                            try block.instructions.append(a, copy);
                            continue;
                        }
                    }
                },
                else => {},
            }
            if (lanes_value) |lanes| try b.define(inst.result.?, lanes) else {
                if (inst.resultType()) |ty| if (fp(ty)) return error.UnsupportedFloatingVectorDefinition;
                try block.instructions.append(a, inst);
            }
        }
        if (block.terminator) |*term| if (term.* == .ret and fp(term.ret.ty)) {
            term.ret.value = try b.toAbi(term.ret.value orelse return error.UnsupportedFloatingVector, term.ret.ty);
            term.ret.ty = try abiType(term.ret.ty);
        };
        try result.blocks.append(a, block);
    }
    return result;
}
