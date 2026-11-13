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
fn smallAbi(ty: ir.Type) ?ir.Type {
    if (!fp(ty)) return null;
    const n = ty.vector.len;
    const elem = ty.vector.elem_ty;
    if (n == 1 and (elem == .half or elem == .float or elem == .double)) return elem.toType();
    if (packedPair(ty) or (elem == .half and (n == 2 or n == 4))) return .double;
    if (elem == .half and n == 8) return .{ .vector = .{ .len = 2, .elem_ty = .double } };
    if (elem == .float and n == 3) return .{ .vector = .{ .len = 4, .elem_ty = .float } };
    return null;
}
fn abiType(ty: ir.Type) !ir.Type {
    if (!fp(ty)) return ty;
    if (smallAbi(ty)) |physical| return physical;
    if (sysv.isVector128AbiType(ty)) return ty;
    return error.UnsupportedFloatingVectorAbi;
}
const Reduction = enum { add, mul, min, max };
fn scalarMinimum(call: ir.CallInst) bool {
    if (call.ret_ty != .half and call.ret_ty != .float and call.ret_ty != .double and call.ret_ty != .x86_fp80 and call.ret_ty != .fp128) return false;
    if (call.inline_asm != null or call.callee_value != null or call.callee_function_ty != null or call.raw_args != null or
        call.operand_bundle != null or call.calling_conv != null or call.ret_attrs != null or call.tail_kind != null or call.args.items.len != 2) return false;
    sysv.rejectUnsupportedCallEnvelope(call) catch return false;
    for (call.args.items) |arg| if (!arg.ty.eql(call.ret_ty) or arg.attrs != null) return false;
    var buffer: [48]u8 = undefined;
    const spelling = std.fmt.bufPrint(&buffer, "llvm.minnum.f{d}", .{width(call.ret_ty)}) catch return false;
    return std.mem.eql(u8, call.callee, spelling);
}
const LaneOperation = struct { name: []const u8, arity: usize };
fn laneOperation(call: ir.CallInst) ?LaneOperation {
    if (!fp(call.ret_ty) or call.inline_asm != null or call.callee_value != null or call.callee_function_ty != null or
        call.raw_args != null or call.operand_bundle != null or call.calling_conv != null or call.ret_attrs != null) return null;
    sysv.rejectUnsupportedCallEnvelope(call) catch return null;
    const scalar = call.ret_ty.vector.elem_ty.toType();
    const operations = [_][]const u8{ "fabs", "copysign", "minnum", "maxnum" } ++ @import("extended_math_intrinsics.zig").operations;
    for (operations) |op| {
        var buffer: [96]u8 = undefined;
        const spelling = std.fmt.bufPrint(&buffer, "llvm.{s}.v{d}f{d}", .{ op, call.ret_ty.vector.len, width(scalar) }) catch return null;
        if (!std.mem.eql(u8, call.callee, spelling)) continue;
        const arity: usize = if (std.mem.eql(u8, op, "fma")) 3 else if (std.mem.eql(u8, op, "copysign") or std.mem.eql(u8, op, "minnum") or std.mem.eql(u8, op, "maxnum")) 2 else 1;
        if (call.args.items.len != arity) return null;
        for (call.args.items) |arg| if (!arg.ty.eql(call.ret_ty) or arg.attrs != null) return null;
        return .{ .name = op, .arity = arity };
    }
    return null;
}
fn reduction(call: ir.CallInst) ?Reduction {
    if (call.inline_asm != null or call.callee_value != null or call.callee_function_ty != null or call.raw_args != null or
        call.operand_bundle != null or call.calling_conv != null or call.ret_attrs != null) return null;
    sysv.rejectUnsupportedCallEnvelope(call) catch return null;
    for ([_][]const u8{ "fadd", "fmul", "fmin", "fmax" }, std.enums.values(Reduction)) |name, op| {
        const seeded = op == .add or op == .mul;
        if (call.args.items.len != @as(usize, if (seeded) 2 else 1)) continue;
        const vector = call.args.items[if (seeded) 1 else 0];
        if (!fp(vector.ty) or vector.attrs != null or !vector.ty.vector.elem_ty.toType().eql(call.ret_ty)) continue;
        if (seeded and (!call.args.items[0].ty.eql(call.ret_ty) or call.args.items[0].attrs != null)) continue;
        var buffer: [96]u8 = undefined;
        const spelling = std.fmt.bufPrint(&buffer, "llvm.vector.reduce.{s}.v{d}f{d}", .{ name, vector.ty.vector.len, width(call.ret_ty) }) catch return null;
        if (std.mem.eql(u8, call.callee, spelling)) return op;
    }
    return null;
}
fn needed(function: ir.Function) bool {
    if (smallAbi(function.ret_ty) != null) return true;
    for (function.params.items) |p| if (smallAbi(p.ty) != null or inputPieces(p.ty) != null) return true;
    var crossing = false;
    var integer_binary = false;
    var shuffle = false;
    var native_fp_cast = false;
    var unsupported_shuffle = false;
    var owned_storage = false;
    var byte_storage = false;
    var native_memory_store = false;
    // A native vector may also be the physical carrier of a scalar quad
    // parameter. Restrict this additional storage trigger to scalar boundaries;
    // existing vector ABI rewrites retain their original activation rules.
    var scalar_boundary = !fp(function.ret_ty);
    const native_float: ir.Type = .{ .vector = .{ .len = 4, .elem_ty = .float } };
    var native_float_boundary = function.ret_ty.eql(native_float);
    for (function.params.items) |p| {
        scalar_boundary = scalar_boundary and !fp(p.ty);
        native_float_boundary = native_float_boundary or p.ty.eql(native_float);
    }
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.removed) continue;
        if (inst.resultType()) |ty| if (fp(ty)) {
            if (!sysv.isVector128AbiType(ty) and !packedPair(ty)) return true;
        };
        switch (inst.kind) {
            .alloca => |x| {
                owned_storage = owned_storage or fp(x.allocated_ty);
                if (x.allocated_ty == .aggregate) {
                    const text = std.mem.trim(u8, x.allocated_ty.aggregate, " \t");
                    byte_storage = byte_storage or (std.mem.startsWith(u8, text, "[") and (std.mem.endsWith(u8, text, " x i8]") or std.mem.endsWith(u8, text, " x i32]")));
                }
            },
            .store => |x| {
                const native_half: ir.Type = .{ .vector = .{ .len = 8, .elem_ty = .half } };
                native_memory_store = native_memory_store or ((!x.attrs.isBarrier() and x.ty_addrspace == null and x.ptr_addrspace == null) and (x.ty.eql(native_float) or x.ty.eql(native_half)));
            },
            .fcmp => |x| {
                if (fp(x.operand_ty)) return true;
            },
            .extractelement => |x| {
                // Packed float pairs have independent scalar lanes and an
                // eight-byte storage extent; they are not quad carriers.
                if (packedPair(x.vector_ty)) return true;
            },
            .select => |x| {
                // Scalar conditions also select opaque quad XMM carriers.
                // Only a vector mask establishes floating lane semantics.
                if (fp(x.ty) and x.cond_ty == .vector) return true;
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
                if (scalarMinimum(c)) return true;
                if (reduction(c) != null) return true;
                if (laneOperation(c)) |op| if (!std.mem.eql(u8, op.name, "fabs") and !std.mem.eql(u8, op.name, "copysign")) return true;
                if (smallAbi(c.ret_ty) != null) return true;
                for (c.args.items) |arg| if (smallAbi(arg.ty) != null or inputPieces(arg.ty) != null) return true;
            },
            .binary => |b| if (b.ty == .vector and b.ty.vector.elem_ty == .int) {
                integer_binary = true;
            },
            else => {},
        }
    };
    return (crossing and integer_binary) or unsupported_shuffle or (shuffle and !native_fp_cast) or
        ((owned_storage or (byte_storage and native_memory_store)) and (scalar_boundary or native_float_boundary));
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
    fn negateBits(b: Builder, ty: ir.Type, value: ir.Value) !ir.Value {
        const bits = width(ty);
        const raw: ir.Type = .{ .int = bits };
        const carrier: ir.Type = .{ .int = if (bits == 80) 128 else bits };
        var payload = try b.cast(.bitcast, ty, try stable(value, ty), raw);
        if (!raw.eql(carrier)) payload = try b.cast(.zext, raw, payload, carrier);
        const sign: i128 = @bitCast(@as(u128, 1) << @as(u7, @intCast(bits - 1)));
        payload = try b.emit(.{ .binary = .{ .op = .xor, .ty = carrier, .lhs = payload, .rhs = .{ .int = sign } } });
        if (!raw.eql(carrier)) payload = try b.cast(.trunc, carrier, payload, raw);
        return b.cast(.bitcast, raw, payload, ty);
    }
    const ZeroTie = struct { condition: ir.Value, payload: ir.Value };
    fn zeroTie(b: Builder, ty: ir.Type, x: ir.Value, y: ir.Value, minimum: bool) !ZeroTie {
        const zero: ir.Value = .{ .fp = if (ty == .half) "0xH0000" else if (ty == .x86_fp80) "0xK00000000000000000000" else "0.000000e+00" };
        const zx = try b.emit(.{ .fcmp = .{ .predicate = .oeq, .operand_ty = ty, .lhs = x, .rhs = zero } });
        const zy = try b.emit(.{ .fcmp = .{ .predicate = .oeq, .operand_ty = ty, .lhs = y, .rhs = zero } });
        const condition = try b.emit(.{ .binary = .{ .op = .@"and", .ty = .{ .int = 1 }, .lhs = zx, .rhs = zy } });
        const raw: ir.Type = .{ .int = width(ty) };
        const carrier: ir.Type = .{ .int = if (width(ty) == 80) 128 else width(ty) };
        var left = try b.cast(.bitcast, ty, x, raw);
        var right = try b.cast(.bitcast, ty, y, raw);
        if (!raw.eql(carrier)) {
            left = try b.cast(.zext, raw, left, carrier);
            right = try b.cast(.zext, raw, right, carrier);
        }
        const joined = try b.emit(.{ .binary = .{ .op = if (minimum) .@"or" else .@"and", .ty = carrier, .lhs = left, .rhs = right } });
        // Only a signed zero reaches the FP bitcast. Unselected arithmetic on
        // arbitrary payloads must not create an invalid x87 encoding.
        const safe = try b.emit(.{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = condition, .ty = carrier, .true_value = joined, .false_value = .{ .int = 0 } } });
        return .{ .condition = condition, .payload = safe };
    }
    fn zeroFromPayload(b: Builder, ty: ir.Type, payload: ir.Value) !ir.Value {
        const raw: ir.Type = .{ .int = width(ty) };
        const bits = if (width(ty) == 80) try b.cast(.trunc, .{ .int = 128 }, payload, raw) else payload;
        return b.cast(.bitcast, raw, bits, ty);
    }
    fn maximumValue(b: Builder, ty: ir.Type, x: ir.Value, y: ir.Value) !ir.Value {
        const left = try stable(x, ty);
        const right = try stable(y, ty);
        const tie = try b.zeroTie(ty, left, right, false);
        var call: ir.CallInst = .{ .callee = try std.fmt.allocPrint(b.a, "llvm.maxnum.f{d}", .{width(ty)}), .ret_ty = ty, .args = .empty };
        try call.args.append(b.a, .{ .ty = ty, .value = left });
        try call.args.append(b.a, .{ .ty = ty, .value = right });
        const ordinary = try b.emit(.{ .call = call });
        const signed_zero = try b.zeroFromPayload(ty, tie.payload);
        return b.emit(.{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = tie.condition, .ty = ty, .true_value = signed_zero, .false_value = ordinary } });
    }
    fn minimumValue(b: Builder, ty: ir.Type, x: ir.Value, y: ir.Value) !ir.Value {
        const left = try stable(x, ty);
        const right = try stable(y, ty);
        const tie = try b.zeroTie(ty, left, right, true);
        var call: ir.CallInst = .{ .callee = try std.fmt.allocPrint(b.a, "llvm.maxnum.f{d}", .{width(ty)}), .ret_ty = ty, .args = .empty };
        try call.args.append(b.a, .{ .ty = ty, .value = try b.negateBits(ty, left) });
        try call.args.append(b.a, .{ .ty = ty, .value = try b.negateBits(ty, right) });
        const maximum = try b.emit(.{ .call = call });
        const ordinary = try b.negateBits(ty, maximum);
        const signed_zero = try b.zeroFromPayload(ty, tie.payload);
        return b.emit(.{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = tie.condition, .ty = ty, .true_value = signed_zero, .false_value = ordinary } });
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
    fn fromInputPieces(b: Builder, pieces: []const ir.Value, ty: ir.Type) !Lanes {
        const plan = inputPieces(ty) orelse return error.UnsupportedFloatingVector;
        if (pieces.len != plan.count) return error.UnsupportedFloatingVector;
        var output_lanes: Lanes = .{ .ty = ty };
        if (plan.lanes_per_piece == 1) {
            @memcpy(output_lanes.values[0..plan.count], pieces);
        } else {
            for (pieces, 0..) |piece, i| {
                const part = try b.fromAbi(piece, plan.ty);
                @memcpy(output_lanes.values[i * 2 ..][0..2], part.values[0..2]);
            }
        }
        return output_lanes;
    }
    fn toInputPieces(b: Builder, value: ir.Value, ty: ir.Type) ![]ir.Value {
        const plan = inputPieces(ty) orelse return error.UnsupportedFloatingVector;
        const input_lanes = try b.lanes(value, ty);
        const pieces = try b.a.alloc(ir.Value, plan.count);
        for (pieces, 0..) |*piece, i| {
            if (plan.lanes_per_piece == 1) {
                piece.* = try stable(input_lanes.values[i], plan.ty);
            } else {
                const name = try forms.temporary(b.a, b.f, b.names);
                try b.vector(name, plan.ty, input_lanes.values[i * 2 ..][0..2]);
                piece.* = .{ .named = name };
            }
        }
        return pieces;
    }
    fn fromAbi(b: Builder, value: ir.Value, ty: ir.Type) !Lanes {
        var result: Lanes = .{ .ty = ty };
        const physical = try abiType(ty);
        if (ty.vector.len == 1 and physical != .vector) {
            result.values[0] = value;
        } else if (physical == .double) {
            const word: ir.Type = .{ .int = 64 };
            const bits = try b.cast(.bitcast, .double, value, word);
            const scalar = ty.vector.elem_ty.toType();
            const raw: ir.Type = .{ .int = width(scalar) };
            for (0..ty.vector.len) |i| {
                const shifted = if (i == 0) bits else try b.emit(.{ .binary = .{ .op = .lshr, .ty = word, .lhs = bits, .rhs = .{ .int = @intCast(i * width(scalar)) } } });
                result.values[i] = try b.cast(.bitcast, raw, try b.cast(.trunc, word, shifted, raw), scalar);
            }
        } else if ((ty.vector.elem_ty == .half and ty.vector.len == 8) or (ty.vector.elem_ty == .float and (ty.vector.len == 3 or ty.vector.len == 4))) {
            const carrier: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .double } };
            const source = if (physical.eql(carrier)) value else try b.cast(.bitcast, physical, value, carrier);
            const scalar = ty.vector.elem_ty.toType();
            const raw: ir.Type = .{ .int = width(scalar) };
            const per_word = 64 / width(scalar);
            for (0..2) |word| {
                const lane = try b.emit(.{ .extractelement = .{ .vector_ty = carrier, .vector = source, .index_ty = .{ .int = 64 }, .index = .{ .int = @intCast(word) } } });
                const bits = try b.cast(.bitcast, .double, lane, .{ .int = 64 });
                for (0..per_word) |i| {
                    if (word * per_word + i >= ty.vector.len) break;
                    const shifted = if (i == 0) bits else try b.emit(.{ .binary = .{ .op = .lshr, .ty = .{ .int = 64 }, .lhs = bits, .rhs = .{ .int = @intCast(i * width(scalar)) } } });
                    result.values[word * per_word + i] = try b.cast(.bitcast, raw, try b.cast(.trunc, .{ .int = 64 }, shifted, raw), scalar);
                }
            }
        } else {
            for (0..ty.vector.len) |i| result.values[i] = try b.emit(.{ .extractelement = .{ .vector_ty = physical, .vector = value, .index_ty = .{ .int = 64 }, .index = .{ .int = @intCast(i) } } });
        }
        return result;
    }
    fn toAbi(b: Builder, value: ir.Value, ty: ir.Type) !ir.Value {
        const lanes_value = try b.lanes(value, ty);
        const physical = try abiType(ty);
        const scalar = ty.vector.elem_ty.toType();
        if (ty.vector.len == 1 and physical != .vector) return stable(lanes_value.values[0], scalar);
        if (physical == .double or (ty.vector.elem_ty == .half and ty.vector.len == 8) or (ty.vector.elem_ty == .float and (ty.vector.len == 3 or ty.vector.len == 4))) {
            const word: ir.Type = .{ .int = 64 };
            const raw: ir.Type = .{ .int = width(scalar) };
            const words: usize = if (physical == .double) 1 else 2;
            const per_word: usize = if (words == 1) ty.vector.len else 64 / width(scalar);
            var carriers: [2]ir.Value = undefined;
            for (0..words) |wi| {
                var payload: ir.Value = .{ .int = 0 };
                for (0..per_word) |i| {
                    if (wi * per_word + i >= ty.vector.len) break;
                    const part = try b.cast(.zext, raw, try b.cast(.bitcast, scalar, try stable(lanes_value.values[wi * per_word + i], scalar), raw), word);
                    const shifted = if (i == 0) part else try b.emit(.{ .binary = .{ .op = .shl, .ty = word, .lhs = part, .rhs = .{ .int = @intCast(i * width(scalar)) } } });
                    payload = if (i == 0) shifted else try b.emit(.{ .binary = .{ .op = .@"or", .ty = word, .lhs = payload, .rhs = shifted } });
                }
                carriers[wi] = try b.cast(.bitcast, word, payload, .double);
            }
            if (words == 1) return carriers[0];
            const carrier: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .double } };
            const name = try forms.temporary(b.a, b.f, b.names);
            try b.vector(name, carrier, carriers[0..2]);
            return if (physical.eql(carrier)) .{ .named = name } else try b.cast(.bitcast, carrier, .{ .named = name }, physical);
        }
        const name = try forms.temporary(b.a, b.f, b.names);
        if (physical.vector.len != ty.vector.len) {
            var padded: [max_lanes]ir.Value = @splat(.{ .fp = "0.000000e+00" });
            @memcpy(padded[0..ty.vector.len], lanes_value.values[0..ty.vector.len]);
            try b.vector(name, physical, padded[0..physical.vector.len]);
        } else try b.vector(name, physical, lanes_value.values[0..ty.vector.len]);
        return .{ .named = name };
    }
    fn pointer(b: Builder, base: ir.Value, offset: usize) !ir.Value {
        // Scalar FP memory actions need an owned register for global bases.
        const global = base == .named and std.mem.startsWith(u8, base.named, "@");
        if (offset == 0 and !global) return base;
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
    var pieces = std.StringHashMap([]ir.Value).init(a);
    defer pieces.deinit();
    var has_parameter_pieces = false;
    for (function.params.items) |p| if (inputPieces(p.ty) != null) {
        if (function.is_varargs or p.abi_x87_memory or p.abi_split_integer or p.abi_incoming_address != null or !inputPieceAttrs(p.attrs)) return error.UnsupportedFloatingVector;
        has_parameter_pieces = true;
    };
    if (has_parameter_pieces) {
        result.params = .empty;
        for (function.params.items) |p| {
            if (inputPieces(p.ty)) |plan| {
                const values = try a.alloc(ir.Value, plan.count);
                for (values) |*value| {
                    var physical = p;
                    physical.ty = plan.ty;
                    physical.name = try forms.temporary(a, function, &names);
                    physical.attrs = null;
                    value.* = .{ .named = physical.name };
                    try result.params.append(a, physical);
                }
                try pieces.put(p.name, values);
            } else {
                var physical = p;
                physical.ty = try abiType(p.ty);
                try result.params.append(a, physical);
            }
        }
    } else {
        result.params = try function.params.clone(a);
        for (result.params.items) |*p| p.ty = try abiType(p.ty);
    }

    result.blocks = .empty;
    for (function.blocks.items, 0..) |original, bi| {
        var block = original;
        block.instructions = .empty;
        const b: Builder = .{ .a = a, .f = function, .block = &block, .names = &names, .vectors = &vectors };
        if (bi == 0) for (function.params.items) |p| if (fp(p.ty)) try b.define(p.name, if (pieces.get(p.name)) |values| try b.fromInputPieces(values, p.ty) else try b.fromAbi(.{ .named = p.name }, p.ty));
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
                    for (0..x.ty.vector.len) |i| {
                        const pointer_value = try b.pointer(x.ptr, i * (width(scalar) / 8));
                        lanes.values[i] = if (packedPair(x.ty)) blk: {
                            const raw_type: ir.Type = .{ .int = 32 };
                            const raw_value = try b.emit(.{ .load = .{ .ty = raw_type, .ptr = pointer_value, .attrs = .{ .@"align" = 1 } } });
                            break :blk try b.cast(.bitcast, raw_type, raw_value, scalar);
                        } else try b.emit(.{ .load = .{ .ty = scalar, .ptr = pointer_value, .attrs = .{ .@"align" = 1 } } });
                    }
                    lanes_value = lanes;
                },
                .store => |x| if (fp(x.ty)) {
                    if (x.attrs.isBarrier() or x.ty_addrspace != null or x.ptr_addrspace != null or x.attrs.syncscope != null) return error.UnsupportedFloatingVector;
                    const scalar = x.ty.vector.elem_ty.toType();
                    const lanes = try b.lanes(x.value, x.ty);
                    for (0..x.ty.vector.len) |i| {
                        const memory_type: ir.Type = if (packedPair(x.ty)) .{ .int = 32 } else scalar;
                        const memory_value = if (packedPair(x.ty)) try b.cast(.bitcast, scalar, try stable(lanes.values[i], scalar), memory_type) else lanes.values[i];
                        try block.instructions.append(a, .{ .result = null, .kind = .{ .store = .{
                            .ty = memory_type,
                            .value = memory_value,
                            .ptr = try b.pointer(x.ptr, i * (width(scalar) / 8)),
                            .attrs = .{ .@"align" = 1 },
                        } } });
                    }
                    continue;
                },
                .call => |x| {
                    if (scalarMinimum(x)) {
                        try b.copy(inst.result.?, x.ret_ty, try b.minimumValue(x.ret_ty, x.args.items[0].value, x.args.items[1].value));
                        continue;
                    }
                    if (reduction(x)) |op| {
                        const seeded = op == .add or op == .mul;
                        const argument = x.args.items[if (seeded) 1 else 0];
                        const lanes = try b.lanes(argument.value, argument.ty);
                        var accumulator = try stable(if (seeded) x.args.items[0].value else lanes.values[0], x.ret_ty);
                        const begin: usize = if (seeded) 0 else 1;
                        for (lanes.values[begin..argument.ty.vector.len]) |lane| {
                            const input = try stable(lane, x.ret_ty);
                            if (seeded) {
                                // Unflagged reductions retain the LLVM source
                                // order and round after every scalar operation.
                                accumulator = try b.emit(.{ .binary = .{ .op = if (op == .add) .fadd else .fmul, .ty = x.ret_ty, .lhs = accumulator, .rhs = input } });
                            } else {
                                // Bitwise negation is exact for every payload.
                                // min(a,b)=-max(-a,-b) retains the pinned scalar
                                // maxnum owner, including its GNU provider ABI.
                                const tie = try b.zeroTie(x.ret_ty, accumulator, input, op == .min);
                                const left = if (op == .min) try b.negateBits(x.ret_ty, accumulator) else accumulator;
                                const right = if (op == .min) try b.negateBits(x.ret_ty, input) else input;
                                var call: ir.CallInst = .{ .callee = try std.fmt.allocPrint(a, "llvm.maxnum.f{d}", .{width(x.ret_ty)}), .ret_ty = x.ret_ty, .args = .empty };
                                try call.args.append(a, .{ .ty = x.ret_ty, .value = left });
                                try call.args.append(a, .{ .ty = x.ret_ty, .value = right });
                                const maximum = try b.emit(.{ .call = call });
                                const ordinary = if (op == .min) try b.negateBits(x.ret_ty, maximum) else maximum;
                                const signed_zero = try b.zeroFromPayload(x.ret_ty, tie.payload);
                                accumulator = try b.emit(.{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = tie.condition, .ty = x.ret_ty, .true_value = signed_zero, .false_value = ordinary } });
                            }
                        }
                        try b.copy(inst.result.?, x.ret_ty, accumulator);
                        continue;
                    }
                    if (fp(x.ret_ty) and std.mem.startsWith(u8, x.callee, "llvm.")) {
                        const scalar = x.ret_ty.vector.elem_ty.toType();
                        const operation = laneOperation(x) orelse return error.UnsupportedFloatingVector;
                        var inputs: [3]Lanes = undefined;
                        for (x.args.items, 0..) |arg, i| {
                            inputs[i] = try b.lanes(arg.value, arg.ty);
                        }
                        var lanes: Lanes = .{ .ty = x.ret_ty };
                        for (0..x.ret_ty.vector.len) |i| {
                            if (std.mem.eql(u8, operation.name, "minnum")) {
                                lanes.values[i] = try b.minimumValue(scalar, inputs[0].values[i], inputs[1].values[i]);
                                continue;
                            }
                            if (std.mem.eql(u8, operation.name, "maxnum")) {
                                lanes.values[i] = try b.maximumValue(scalar, inputs[0].values[i], inputs[1].values[i]);
                                continue;
                            }
                            var call: ir.CallInst = .{ .callee = try std.fmt.allocPrint(a, "llvm.{s}.f{d}", .{ operation.name, width(scalar) }), .ret_ty = scalar, .args = .empty };
                            for (0..operation.arity) |j| try call.args.append(a, .{ .ty = scalar, .value = inputs[j].values[i] });
                            lanes.values[i] = try b.emit(.{ .call = call });
                        }
                        try b.define(inst.result.?, lanes);
                        continue;
                    }
                    var copy = inst;
                    var changed = fp(x.ret_ty);
                    var has_argument_pieces = false;
                    for (x.args.items) |arg| has_argument_pieces = has_argument_pieces or inputPieces(arg.ty) != null;
                    if (fp(x.ret_ty)) copy.kind.call.ret_ty = try abiType(x.ret_ty);
                    if (has_argument_pieces) {
                        if (x.callee_value != null or x.callee_function_ty != null or x.inline_asm != null or x.raw_args != null or x.operand_bundle != null or x.va_arg or x.native_query != null) return error.UnsupportedFloatingVector;
                        if (x.calling_conv) |cc| if (!std.mem.eql(u8, cc, "fastcc")) return error.UnsupportedFloatingVector;
                        // Optional hints do not require a tail transfer. Keep
                        // their new piecewise admission within the explicit
                        // fastcc contract; ordinary ABI admission is unchanged.
                        if (x.tail_kind != null and !std.mem.eql(u8, x.calling_conv orelse return error.UnsupportedFloatingVector, "fastcc")) return error.UnsupportedFloatingVector;
                        sysv.rejectUnsupportedCallEnvelope(x) catch return error.UnsupportedFloatingVector;
                        copy.kind.call.tail_kind = null;
                        copy.kind.call.args = .empty;
                        for (x.args.items) |arg| {
                            if (inputPieces(arg.ty)) |plan| {
                                if (arg.abi_x87_memory or arg.abi_split_integer or !inputPieceAttrs(arg.attrs)) return error.UnsupportedFloatingVector;
                                const values = try b.toInputPieces(arg.value, arg.ty);
                                for (values) |value| {
                                    var physical = arg;
                                    physical.ty = plan.ty;
                                    physical.value = value;
                                    physical.attrs = null;
                                    try copy.kind.call.args.append(a, physical);
                                }
                                changed = true;
                            } else {
                                var physical = arg;
                                if (fp(arg.ty)) {
                                    physical.value = try b.toAbi(arg.value, arg.ty);
                                    physical.ty = try abiType(arg.ty);
                                    changed = true;
                                }
                                try copy.kind.call.args.append(a, physical);
                            }
                        }
                    } else {
                        copy.kind.call.args = try x.args.clone(a);
                        for (copy.kind.call.args.items) |*arg| if (fp(arg.ty)) {
                            changed = true;
                            arg.value = try b.toAbi(arg.value, arg.ty);
                            arg.ty = try abiType(arg.ty);
                        };
                    }

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

const FpInputPieces = struct { count: usize, lanes_per_piece: usize, ty: ir.Type };
fn inputPieces(ty: ir.Type) ?FpInputPieces {
    if (!fp(ty) or ty.vector.len != 4) return null;
    return switch (ty.vector.elem_ty) {
        .double => .{ .count = 2, .lanes_per_piece = 2, .ty = .{ .vector = .{ .len = 2, .elem_ty = .double } } },
        .x86_fp80, .fp128 => .{ .count = 4, .lanes_per_piece = 1, .ty = ty.vector.elem_ty.toType() },
        else => null,
    };
}
fn inputPieceAttrs(attrs: ?[]const u8) bool {
    var words = std.mem.tokenizeAny(u8, attrs orelse return true, " \t\r\n");
    while (words.next()) |word| if (!std.mem.eql(u8, word, "noundef")) return false;
    return true;
}
