const std = @import("std");
const ir = @import("../../../ir.zig");
const fp_semantics = @import("../../../analysis/fp_semantics.zig");
const sysv_abi = @import("../sysv_abi.zig");
const x86_64_types = @import("../types.zig");
const aggregate_object = @import("aggregate_object.zig");
const intrinsic_attrs = @import("intrinsic_attrs.zig");

pub const Diagnostic = union(enum) {
    unsupported_control_flow: []const u8,
    unsupported_instruction: []const u8,
    unsupported_type: []const u8,
    unsupported_value: []const u8,
    no_spill_envelope: []const u8,
    no_emitter: []const u8,

    pub fn tagName(diagnostic: Diagnostic) []const u8 {
        return @tagName(diagnostic);
    }

    pub fn detail(diagnostic: Diagnostic) []const u8 {
        return switch (diagnostic) {
            inline else => |detail_text| detail_text,
        };
    }
};

pub const SelectionResult = union(enum) {
    selected,
    unsupported: Diagnostic,
};

pub fn inspectFunction(function: ir.Function) SelectionResult {
    return inspectFunctionWithContext(function, null);
}

pub fn inspectFunctionWithContext(function: ir.Function, context: ?*const x86_64_types.ReadOnlyModuleContext) SelectionResult {
    if (function.calling_conv) |cc| {
        if (!std.mem.eql(u8, cc, "ccc") and !std.mem.eql(u8, cc, "fastcc")) {
            return unsupported(.{ .unsupported_control_flow = "non-default-calling-convention" });
        }
    }
    if (!isScalarReturnType(function.ret_ty)) {
        return unsupported(.{ .unsupported_type = "unsupported-return-type" });
    }
    for (function.params.items) |param| {
        if (!isSelectorScalarType(param.ty)) {
            return unsupported(.{ .unsupported_type = "unsupported-param-type" });
        }
    }

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (inspectInstruction(instruction, context)) |diagnostic| {
                return unsupported(diagnostic);
            }
        }
        const terminator = block.terminator orelse {
            return unsupported(.{ .unsupported_control_flow = "missing-terminator" });
        };
        if (inspectTerminator(block, terminator)) |diagnostic| {
            return unsupported(diagnostic);
        }
    }

    return unsupported(.{ .no_emitter = "selector-skeleton-has-no-emitters" });
}

fn inspectInstruction(instruction: ir.Instruction, context: ?*const x86_64_types.ReadOnlyModuleContext) ?Diagnostic {
    return switch (instruction.kind) {
        .binary => |binary| inspectBinary(binary),
        .cast => |cast| inspectCast(cast),
        .icmp => |icmp| inspectIcmp(icmp),
        .select => |select| inspectSelect(select),
        .alloca => |alloca| if (isSelectorScalarType(alloca.allocated_ty) or parseI32ArrayType(alloca.allocated_ty) != null or aggregate_object.isF32PairType(context, alloca.allocated_ty)) null else .{ .unsupported_type = "alloca" },
        .load => |load| if (isSelectorScalarType(load.ty) or isPackedF32x2(load.ty) or isByteVector128(load.ty)) null else .{ .unsupported_type = "load" },
        .store => |store| if (isSelectorScalarType(store.ty) or isByteVector128(store.ty)) null else .{ .unsupported_type = "store" },
        .gep => null,
        .call => |call| inspectCall(call),
        .phi => |phi| if (isSelectorScalarType(phi.ty)) null else .{ .unsupported_type = "phi" },
        .freeze => |freeze| if (isSelectorScalarType(freeze.ty)) null else .{ .unsupported_type = "freeze" },
        .fcmp => |fcmp| inspectFcmp(fcmp),
        .atomicrmw => .{ .unsupported_instruction = "atomicrmw" },
        .cmpxchg => .{ .unsupported_instruction = "cmpxchg" },
        .fence => .{ .unsupported_instruction = "fence" },
        .extractelement => |extract| inspectExtractElement(extract),
        .insertelement => |insert| inspectInsertElement(insert),
        .shufflevector => |shuffle| inspectShuffleVector(shuffle),
        .extractvalue => |extract| inspectExtractValue(extract),
        .insertvalue => |insert| if (sysv_abi.sseAggregateReturnKind(insert.aggregate_ty) != null) null else .{ .unsupported_instruction = "insertvalue" },
    };
}

fn isPackedF32x2(ty: ir.Type) bool {
    return ty == .vector and ty.vector.len == 2 and ty.vector.elem_ty == .float;
}

pub fn isByteVector128(ty: ir.Type) bool {
    return ty.eql(.{ .vector = .{ .len = 16, .elem_ty = .{ .int = 8 } } });
}

fn inspectFcmp(fcmp: ir.FcmpInst) ?Diagnostic {
    if (isPackedFp2(fcmp.operand_ty) or isPackedF32x4(fcmp.operand_ty)) {
        if (fcmp.predicate != .oeq or !isVectorOperand(fcmp.lhs, fcmp.operand_ty) or !isVectorOperand(fcmp.rhs, fcmp.operand_ty)) {
            return .{ .unsupported_type = "fcmp" };
        }
        return null;
    }
    if (fcmp.operand_ty == .float or fcmp.operand_ty == .double) return null;
    if (fcmp.operand_ty != .half) return .{ .unsupported_type = "fcmp" };
    if (fcmp.predicate == .oeq) {
        if (valueIsNamed(fcmp.lhs) and valueIsHalfZeroLiteral(fcmp.rhs)) return null;
        if (valueIsNamed(fcmp.rhs) and valueIsHalfZeroLiteral(fcmp.lhs)) return null;
    }
    if (fcmp.predicate == .uno or fcmp.predicate == .olt) {
        const lhs_supported = valueIsNamed(fcmp.lhs) or valueIsHalfZeroLiteral(fcmp.lhs);
        const rhs_supported = valueIsNamed(fcmp.rhs) or valueIsHalfZeroLiteral(fcmp.rhs);
        if (lhs_supported and rhs_supported and (valueIsNamed(fcmp.lhs) or valueIsNamed(fcmp.rhs))) return null;
    }
    return .{ .unsupported_type = "fcmp" };
}

fn valueIsNamed(value: ir.Value) bool {
    return value == .named;
}

fn valueIsHalfZeroLiteral(value: ir.Value) bool {
    return switch (value) {
        .fp => |text| fp_semantics.isHalfZeroLiteral(text),
        else => false,
    };
}

fn inspectBinary(binary: ir.BinaryInst) ?Diagnostic {
    if (isPackedFp2(binary.ty) or isPackedF32x4(binary.ty)) return switch (binary.op) {
        .fadd, .fsub, .fmul => null,
        else => .{ .unsupported_instruction = @tagName(binary.op) },
    };
    if (!isSelectorScalarType(binary.ty)) return .{ .unsupported_type = "binary" };
    return switch (binary.op) {
        .add, .sub, .mul, .@"and", .@"or", .xor, .shl, .lshr, .ashr => null,
        .sdiv => if (binary.ty.eql(.{ .int = 32 }) and valueIsNamed(binary.lhs) and binary.rhs == .int and @import("composed_helpers.zig").isPositivePowerOfTwoDivisor(binary.rhs.int)) null else .{ .unsupported_instruction = @tagName(binary.op) },
        .udiv, .urem, .srem => .{ .unsupported_instruction = @tagName(binary.op) },
        .fadd => if (binary.ty == .half or binary.ty == .float or binary.ty == .double) null else .{ .unsupported_instruction = @tagName(binary.op) },
        .fsub, .fmul, .fdiv => if (binary.ty == .float or binary.ty == .double) null else .{ .unsupported_instruction = @tagName(binary.op) },
        .frem => .{ .unsupported_instruction = @tagName(binary.op) },
    };
}

fn inspectExtractElement(extract: ir.ExtractElementInst) ?Diagnostic {
    if (isPackedF32x4(extract.vector_ty)) {
        if (!extract.index_ty.eql(.{ .int = 64 })) return .{ .unsupported_type = "extractelement-index" };
        return inspectF32x4ExtractLane(extract.index);
    }
    const is_i64x2 = extract.vector_ty.eql(.{ .vector = .{ .len = 2, .elem_ty = .{ .int = 64 } } });
    if (!isPackedFp2(extract.vector_ty) and !isMask2(extract.vector_ty) and !is_i64x2) return .{ .unsupported_type = "extractelement" };
    if (!extract.index_ty.eql(.{ .int = 64 })) return .{ .unsupported_type = "extractelement-index" };
    return inspectLaneIndex(extract.index, "extractelement");
}

fn inspectInsertElement(insert: ir.InsertElementInst) ?Diagnostic {
    if ((!isPackedFp2(insert.vector_ty) and !isPackedF32x4(insert.vector_ty)) or !insert.value_ty.eql(insert.vector_ty.vector.elem_ty.toType())) return .{ .unsupported_type = "insertelement" };
    if (!insert.index_ty.eql(.{ .int = 64 })) return .{ .unsupported_type = "insertelement-index" };
    return inspectLaneIndex(insert.index, "insertelement");
}

fn inspectShuffleVector(shuffle: ir.ShuffleVectorInst) ?Diagnostic {
    if (isPackedF32x4(shuffle.lhs_ty)) {
        return if (ir.vector_constant.classifyPackedF32x4ShuffleMask(shuffle) != null) null else .{ .unsupported_instruction = "shufflevector-mask" };
    }
    if (!isPackedFp2(shuffle.lhs_ty) or !shuffle.rhs_ty.eql(shuffle.lhs_ty) or
        !shuffle.mask_ty.eql(.{ .vector = .{ .len = 2, .elem_ty = .{ .int = 32 } } }))
    {
        return .{ .unsupported_type = "shufflevector" };
    }
    return if (ir.vector_constant.classifyPacked2ShuffleMask(shuffle) != null) null else .{ .unsupported_instruction = "shufflevector-mask" };
}

fn inspectLaneIndex(index: ir.Value, comptime operation: []const u8) ?Diagnostic {
    return switch (index) {
        .int => |lane| if (lane == 0 or lane == 1) null else .{ .unsupported_instruction = operation ++ "-index" },
        .named => .{ .unsupported_instruction = operation ++ "-dynamic-index" },
        else => .{ .unsupported_instruction = operation ++ "-index" },
    };
}

fn inspectF32x4ExtractLane(index: ir.Value) ?Diagnostic {
    return switch (index) {
        .int => |lane| if (lane == 0 or lane == 2) null else .{ .unsupported_instruction = "extractelement-index" },
        .named => .{ .unsupported_instruction = "extractelement-dynamic-index" },
        else => .{ .unsupported_instruction = "extractelement-index" },
    };
}

fn isPackedFp2(ty: ir.Type) bool {
    return ty == .vector and ty.vector.len == 2 and
        (ty.vector.elem_ty == .float or ty.vector.elem_ty == .double);
}

fn isPackedF32x4(ty: ir.Type) bool {
    return ty == .vector and ty.vector.len == 4 and ty.vector.elem_ty == .float;
}

fn isMask2(ty: ir.Type) bool {
    return ty == .vector and ty.vector.len == 2 and ty.vector.elem_ty == .int and ty.vector.elem_ty.int == 1;
}

fn isMask4(ty: ir.Type) bool {
    return ty == .vector and ty.vector.len == 4 and ty.vector.elem_ty == .int and ty.vector.elem_ty.int == 1;
}

fn isVectorOperand(value: ir.Value, ty: ir.Type) bool {
    if (value == .named) return true;
    return switch (ty.vector.len) {
        2 => ir.vector_constant.parseFixed(2, value, ty.vector) != null,
        4 => ir.vector_constant.parseFixed(4, value, ty.vector) != null,
        else => false,
    };
}

fn inspectCast(cast: ir.CastInst) ?Diagnostic {
    if (cast.op == .bitcast and isMask4(cast.from_ty) and cast.to_ty.eql(.{ .int = 4 })) return null;
    if (cast.op == .bitcast and isPackedFp2(cast.from_ty) and cast.to_ty == .vector and
        cast.to_ty.vector.len == 2 and cast.to_ty.vector.elem_ty == .int and
        cast.to_ty.vector.elem_ty.int == packedFpLaneBits(cast.from_ty).?)
    {
        return null;
    }
    if (!isSelectorScalarType(cast.from_ty) or !isSelectorScalarType(cast.to_ty)) {
        return .{ .unsupported_type = "cast" };
    }
    return switch (cast.op) {
        .trunc, .zext, .sext, .bitcast, .ptrtoint, .inttoptr => null,
        .fpext => if ((cast.from_ty == .half and (cast.to_ty == .float or cast.to_ty == .double)) or (cast.from_ty == .float and cast.to_ty == .double)) null else .{ .unsupported_instruction = @tagName(cast.op) },
        .fptrunc => if ((cast.from_ty == .float and cast.to_ty == .half) or (cast.from_ty == .double and cast.to_ty == .float)) null else .{ .unsupported_instruction = @tagName(cast.op) },
        .sitofp, .uitofp => switch (cast.from_ty) {
            .int => |bits| if (bits >= 8 and bits <= 64 and (cast.to_ty == .float or cast.to_ty == .double)) null else .{ .unsupported_instruction = @tagName(cast.op) },
            else => .{ .unsupported_instruction = @tagName(cast.op) },
        },
        .fptosi => if ((cast.from_ty == .float or cast.from_ty == .double) and cast.to_ty.eql(.{ .int = 32 })) null else .{ .unsupported_instruction = @tagName(cast.op) },
        .fptoui => .{ .unsupported_instruction = @tagName(cast.op) },
    };
}

fn packedFpLaneBits(ty: ir.Type) ?u16 {
    if (!isPackedFp2(ty)) return null;
    return switch (ty.vector.elem_ty) {
        .float => 32,
        .double => 64,
        else => null,
    };
}

fn inspectIcmp(icmp: ir.IcmpInst) ?Diagnostic {
    if (icmp.operand_ty == .vector) {
        const vector = icmp.operand_ty.vector;
        if (!icmp.samesign or (icmp.predicate != .ugt and icmp.predicate != .ult) or vector.len != 2 or vector.elem_ty != .int or vector.elem_ty.int != 32 or
            !isVectorOperand(icmp.lhs, icmp.operand_ty) or !isVectorOperand(icmp.rhs, icmp.operand_ty))
        {
            return .{ .unsupported_type = "icmp" };
        }
        return null;
    }
    if (!isSelectorScalarType(icmp.operand_ty)) return .{ .unsupported_type = "icmp" };
    return null;
}

fn inspectSelect(select: ir.SelectInst) ?Diagnostic {
    const f32x2: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .float } };
    const f64x2: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .double } };
    if (select.ty.eql(f32x2) or select.ty.eql(f64x2)) {
        const mask2: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .{ .int = 1 } } };
        return if (select.cond_ty.eql(mask2) and
            isVectorOperand(select.true_value, select.ty) and
            isVectorOperand(select.false_value, select.ty)) null else .{ .unsupported_type = "select-cond" };
    }
    if (!isSelectorScalarType(select.ty)) return .{ .unsupported_type = "select" };
    return switch (select.cond_ty) {
        .int => |bits| if (bits == 1) null else .{ .unsupported_type = "select-cond" },
        else => .{ .unsupported_type = "select-cond" },
    };
}

fn inspectCall(call: ir.CallInst) ?Diagnostic {
    if (call.inline_asm) |inline_asm| {
        const stack_memory_barrier = inline_asm.sideeffect and inline_asm.template.len == 0 and
            std.mem.eql(u8, inline_asm.constraints, "m,~{memory},~{dirflag},~{fpsr},~{flags}") and
            call.ret_ty == .void and call.args.items.len == 1 and call.args.items[0].ty == .ptr;
        if (stack_memory_barrier) return null;
        if (!inline_asm.sideeffect or inline_asm.template.len != 0 or
            !std.mem.eql(u8, inline_asm.constraints, "rm,~{dirflag},~{fpsr},~{flags}") or
            call.ret_ty != .void or call.args.items.len != 1 or
            (call.args.items[0].ty != .float and call.args.items[0].ty != .double))
        {
            return .{ .unsupported_instruction = "inline-asm-call" };
        }
        return null;
    }
    if (call.callee_value != null) return .{ .unsupported_value = "indirect-call" };
    if (call.raw_args != null) return .{ .unsupported_instruction = "raw-call-args" };
    if (call.isDebugVariableLocation()) return null;
    if (std.mem.eql(u8, call.callee, "llvm.experimental.noalias.scope.decl"))
        return if (intrinsic_attrs.isNoAliasScopeDecl(call)) null else .{ .unsupported_instruction = "llvm.experimental.noalias.scope.decl" };
    if (std.mem.eql(u8, call.callee, "llvm.assume")) {
        if (call.ret_ty != .void or call.args.items.len != 1) return .{ .unsupported_instruction = "llvm.assume" };
        if (call.operand_bundle) |bundle| {
            if (!isColdAssumeBundle(bundle)) return .{ .unsupported_instruction = "operand-bundle-call" };
        }
        return if (call.args.items[0].ty.eql(.{ .int = 1 })) null else .{ .unsupported_type = "llvm.assume" };
    }
    if (std.mem.eql(u8, call.callee, "llvm.trap")) {
        if (call.ret_ty != .void or call.args.items.len != 0 or call.calling_conv != null or call.ret_attrs != null or call.operand_bundle != null) {
            return .{ .unsupported_instruction = "llvm.trap" };
        }
        return null;
    }
    if (std.mem.eql(u8, call.callee, "llvm.fabs.f16")) {
        return if (call.ret_ty == .half and call.args.items.len == 1 and call.args.items[0].ty == .half) null else .{ .unsupported_type = "llvm.fabs.f16" };
    }
    if (std.mem.eql(u8, call.callee, "llvm.fabs.f32")) {
        return if (call.ret_ty == .float and call.args.items.len == 1 and call.args.items[0].ty == .float) null else .{ .unsupported_type = "llvm.fabs.f32" };
    }
    if (std.mem.eql(u8, call.callee, "llvm.fabs.f64")) {
        return if (call.ret_ty == .double and call.args.items.len == 1 and call.args.items[0].ty == .double) null else .{ .unsupported_type = "llvm.fabs.f64" };
    }
    if (std.mem.eql(u8, call.callee, "llvm.maxnum.f32")) {
        return if (call.ret_ty == .float and call.args.items.len == 2 and
            call.args.items[0].ty == .float and call.args.items[1].ty == .float) null else .{ .unsupported_type = "llvm.maxnum.f32" };
    }
    if (std.mem.eql(u8, call.callee, "llvm.maxnum.f64")) {
        return if (call.ret_ty == .double and call.args.items.len == 2 and
            call.args.items[0].ty == .double and call.args.items[1].ty == .double) null else .{ .unsupported_type = "llvm.maxnum.f64" };
    }
    if (std.mem.eql(u8, call.callee, "llvm.copysign.f32")) {
        return if (call.ret_ty == .float and call.args.items.len == 2 and
            call.args.items[0].ty == .float and call.args.items[1].ty == .float) null else .{ .unsupported_type = "llvm.copysign.f32" };
    }
    if (std.mem.eql(u8, call.callee, "llvm.copysign.f64")) {
        return if (call.ret_ty == .double and call.args.items.len == 2 and
            call.args.items[0].ty == .double and call.args.items[1].ty == .double) null else .{ .unsupported_type = "llvm.copysign.f64" };
    }
    if (std.mem.eql(u8, call.callee, "llvm.copysign.v2f32")) {
        const vector_ty: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .float } };
        return if (call.ret_ty.eql(vector_ty) and call.args.items.len == 2 and
            call.args.items[0].ty.eql(vector_ty) and call.args.items[1].ty.eql(vector_ty)) null else .{ .unsupported_type = "llvm.copysign.v2f32" };
    }
    if (std.mem.eql(u8, call.callee, "llvm.copysign.v2f64")) {
        const vector_ty: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .double } };
        return if (call.ret_ty.eql(vector_ty) and call.args.items.len == 2 and
            call.args.items[0].ty.eql(vector_ty) and call.args.items[1].ty.eql(vector_ty)) null else .{ .unsupported_type = "llvm.copysign.v2f64" };
    }
    if (std.mem.eql(u8, call.callee, "llvm.fabs.v2f32")) {
        const vector_ty: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .float } };
        return if (call.ret_ty.eql(vector_ty) and call.args.items.len == 1 and call.args.items[0].ty.eql(vector_ty)) null else .{ .unsupported_type = "llvm.fabs.v2f32" };
    }
    if (std.mem.eql(u8, call.callee, "llvm.fabs.v4f32")) {
        const vector_ty: ir.Type = .{ .vector = .{ .len = 4, .elem_ty = .float } };
        return if (call.ret_ty.eql(vector_ty) and call.args.items.len == 1 and call.args.items[0].ty.eql(vector_ty)) null else .{ .unsupported_type = "llvm.fabs.v4f32" };
    }
    if (std.mem.eql(u8, call.callee, "llvm.fabs.v2f64")) {
        const vector_ty: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .double } };
        return if (call.ret_ty.eql(vector_ty) and call.args.items.len == 1 and call.args.items[0].ty.eql(vector_ty)) null else .{ .unsupported_type = "llvm.fabs.v2f64" };
    }
    if (std.mem.eql(u8, call.callee, "llvm.bswap.i128") or std.mem.eql(u8, call.callee, "llvm.bitreverse.i128")) {
        const ty: ir.Type = .{ .int = 128 };
        return if (call.ret_ty.eql(ty) and call.args.items.len == 1 and call.args.items[0].ty.eql(ty)) null else .{ .unsupported_type = "bit-permutation-i128" };
    }
    if (std.mem.eql(u8, call.callee, "llvm.bitreverse.i32")) {
        const ty: ir.Type = .{ .int = 32 };
        return if (call.ret_ty.eql(ty) and call.args.items.len == 1 and call.args.items[0].ty.eql(ty)) null else .{ .unsupported_type = "bit-permutation-i32" };
    }
    if (std.mem.eql(u8, call.callee, "llvm.bitreverse.i64")) {
        const ty: ir.Type = .{ .int = 64 };
        return if (call.ret_ty.eql(ty) and call.args.items.len == 1 and call.args.items[0].ty.eql(ty)) null else .{ .unsupported_type = "bit-permutation-i64" };
    }
    if (std.mem.eql(u8, call.callee, "llvm.ctpop.i64") or std.mem.eql(u8, call.callee, "llvm.ctpop.i128")) {
        const bits: u16 = if (std.mem.endsWith(u8, call.callee, ".i64")) 64 else 128;
        const ty: ir.Type = .{ .int = bits };
        return if (call.ret_ty.eql(ty) and call.args.items.len == 1 and call.args.items[0].ty.eql(ty) and
            intrinsic_attrs.matchesIntegerRange(call.ret_attrs, bits, 0, @as(u128, bits) + 1)) null else .{ .unsupported_type = "llvm.ctpop" };
    }
    if (std.mem.eql(u8, call.callee, "llvm.ctlz.i16")) {
        return if (call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 2 and
            call.args.items[0].ty.eql(.{ .int = 16 }) and call.args.items[1].ty.eql(.{ .int = 1 })) null else .{ .unsupported_type = "llvm.ctlz.i16" };
    }
    if (call.operand_bundle != null) return .{ .unsupported_instruction = "operand-bundle-call" };
    if (isOverflowIntrinsic(call.callee)) {
        const bits: u16 = if (std.mem.endsWith(u8, call.callee, ".i32"))
            32
        else if (std.mem.endsWith(u8, call.callee, ".i64"))
            64
        else
            128;
        const aggregate_ty = switch (bits) {
            32 => "{ i32, i1 }",
            64 => "{ i64, i1 }",
            128 => "{ i128, i1 }",
            else => unreachable,
        };
        if (!call.ret_ty.eql(.{ .aggregate = aggregate_ty }) or call.args.items.len != 2) {
            return .{ .unsupported_type = "overflow-intrinsic" };
        }
        for (call.args.items) |arg| {
            if (!arg.ty.eql(.{ .int = bits })) return .{ .unsupported_type = "overflow-intrinsic-arg" };
        }
        return null;
    }
    if (!isScalarReturnType(call.ret_ty)) return .{ .unsupported_type = "call-ret" };
    for (call.args.items) |arg| {
        if (!isSelectorScalarType(arg.ty)) return .{ .unsupported_type = "call-arg" };
    }
    return null;
}

fn inspectExtractValue(extract: ir.ExtractValueInst) ?Diagnostic {
    const value_bits: u16 = if (extract.aggregate_ty.eql(.{ .aggregate = "{ i32, i1 }" }))
        32
    else if (extract.aggregate_ty.eql(.{ .aggregate = "{ i64, i1 }" }))
        64
    else if (extract.aggregate_ty.eql(.{ .aggregate = "{ i128, i1 }" }))
        128
    else
        return .{ .unsupported_type = "extractvalue-aggregate" };
    if (std.mem.eql(u8, extract.indices, "0")) {
        return if (extract.result_ty.eql(.{ .int = value_bits })) null else .{ .unsupported_type = "extractvalue-result" };
    }
    if (std.mem.eql(u8, extract.indices, "1")) {
        return if (extract.result_ty.eql(.{ .int = 1 })) null else .{ .unsupported_type = "extractvalue-result" };
    }
    return .{ .unsupported_value = "extractvalue-index" };
}

fn inspectTerminator(block: ir.BasicBlock, terminator: ir.Terminator) ?Diagnostic {
    return switch (terminator) {
        .ret => |ret| if (isScalarReturnType(ret.ty)) null else .{ .unsupported_type = "ret" },
        .br => null,
        .condbr => |condbr| switch (condbr.cond_ty) {
            .int => |bits| if (bits == 1) null else .{ .unsupported_type = "condbr" },
            else => .{ .unsupported_type = "condbr" },
        },
        .@"switch" => .{ .unsupported_control_flow = "switch" },
        .indirectbr => .{ .unsupported_control_flow = "indirectbr" },
        .@"unreachable" => if (blockEndsInTrap(block)) null else .{ .unsupported_control_flow = "unreachable" },
    };
}

fn blockEndsInTrap(block: ir.BasicBlock) bool {
    var index = block.instructions.items.len;
    while (index > 0) {
        index -= 1;
        const instruction = block.instructions.items[index];
        if (instruction.removed) continue;
        const call = switch (instruction.kind) {
            .call => |call| call,
            else => return false,
        };
        if (call.isDebugVariableLocation()) continue;
        return std.mem.eql(u8, call.callee, "llvm.trap") and call.ret_ty == .void and call.args.items.len == 0;
    }
    return false;
}

fn isScalarReturnType(ty: ir.Type) bool {
    return ty == .void or isSelectorScalarType(ty) or sysv_abi.sseAggregateReturnKind(ty) != null;
}

fn isSelectorScalarType(ty: ir.Type) bool {
    return switch (ty) {
        .int => |bits| bits > 0 and bits <= 128,
        .half, .float, .double, .ptr => true,
        .void, .x86_fp80, .fp128, .metadata, .aggregate, .vector => false,
    };
}

fn isOverflowIntrinsic(callee: []const u8) bool {
    return std.mem.eql(u8, callee, "llvm.uadd.with.overflow.i32") or
        std.mem.eql(u8, callee, "llvm.usub.with.overflow.i32") or
        std.mem.eql(u8, callee, "llvm.uadd.with.overflow.i64") or
        std.mem.eql(u8, callee, "llvm.usub.with.overflow.i64") or
        std.mem.eql(u8, callee, "llvm.smul.with.overflow.i64") or
        std.mem.eql(u8, callee, "llvm.smul.with.overflow.i128");
}

fn isColdAssumeBundle(bundle: []const u8) bool {
    return std.mem.eql(u8, std.mem.trim(u8, bundle, " \t"), "[ \"cold\"() ]");
}

fn parseI32ArrayType(ty: ir.Type) ?u32 {
    const text = switch (ty) {
        .aggregate => |text| text,
        else => return null,
    };
    if (!std.mem.startsWith(u8, text, "[") or !std.mem.endsWith(u8, text, " x i32]")) return null;
    const len_text = text[1 .. text.len - " x i32]".len];
    return std.fmt.parseUnsigned(u32, len_text, 10) catch null;
}

fn unsupported(diagnostic: Diagnostic) SelectionResult {
    return .{ .unsupported = diagnostic };
}
