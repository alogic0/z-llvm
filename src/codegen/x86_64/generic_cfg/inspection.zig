const std = @import("std");
const ir = @import("../../../ir.zig");

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
    if (function.calling_conv != null) {
        return unsupported(.{ .unsupported_control_flow = "non-default-calling-convention" });
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
            if (inspectInstruction(instruction)) |diagnostic| {
                return unsupported(diagnostic);
            }
        }
        const terminator = block.terminator orelse {
            return unsupported(.{ .unsupported_control_flow = "missing-terminator" });
        };
        if (inspectTerminator(terminator)) |diagnostic| {
            return unsupported(diagnostic);
        }
    }

    return unsupported(.{ .no_emitter = "selector-skeleton-has-no-emitters" });
}

fn inspectInstruction(instruction: ir.Instruction) ?Diagnostic {
    return switch (instruction.kind) {
        .binary => |binary| inspectBinary(binary),
        .cast => |cast| inspectCast(cast),
        .icmp => |icmp| inspectIcmp(icmp),
        .select => |select| inspectSelect(select),
        .alloca => |alloca| if (isSelectorScalarType(alloca.allocated_ty) or parseI32ArrayType(alloca.allocated_ty) != null) null else .{ .unsupported_type = "alloca" },
        .load => |load| if (isSelectorScalarType(load.ty)) null else .{ .unsupported_type = "load" },
        .store => |store| if (isSelectorScalarType(store.ty)) null else .{ .unsupported_type = "store" },
        .gep => null,
        .call => |call| inspectCall(call),
        .phi => |phi| if (isSelectorScalarType(phi.ty)) null else .{ .unsupported_type = "phi" },
        .freeze => |freeze| if (isSelectorScalarType(freeze.ty)) null else .{ .unsupported_type = "freeze" },
        .fcmp => .{ .unsupported_instruction = "fcmp" },
        .atomicrmw => .{ .unsupported_instruction = "atomicrmw" },
        .cmpxchg => .{ .unsupported_instruction = "cmpxchg" },
        .fence => .{ .unsupported_instruction = "fence" },
        .extractelement => .{ .unsupported_instruction = "extractelement" },
        .insertelement => .{ .unsupported_instruction = "insertelement" },
        .shufflevector => .{ .unsupported_instruction = "shufflevector" },
        .extractvalue => |extract| inspectExtractValue(extract),
        .insertvalue => .{ .unsupported_instruction = "insertvalue" },
    };
}

fn inspectBinary(binary: ir.BinaryInst) ?Diagnostic {
    if (!isSelectorScalarType(binary.ty)) return .{ .unsupported_type = "binary" };
    return switch (binary.op) {
        .add, .sub, .mul, .@"and", .@"or", .xor, .shl, .lshr, .ashr => null,
        .udiv, .sdiv, .urem, .srem => .{ .unsupported_instruction = @tagName(binary.op) },
        .fadd, .fsub, .fmul, .fdiv, .frem => .{ .unsupported_instruction = @tagName(binary.op) },
    };
}

fn inspectCast(cast: ir.CastInst) ?Diagnostic {
    if (!isSelectorScalarType(cast.from_ty) or !isSelectorScalarType(cast.to_ty)) {
        return .{ .unsupported_type = "cast" };
    }
    return switch (cast.op) {
        .trunc, .zext, .sext, .bitcast, .ptrtoint, .inttoptr => null,
        .fpext, .fptrunc, .fptosi, .fptoui, .sitofp, .uitofp => .{ .unsupported_instruction = @tagName(cast.op) },
    };
}

fn inspectIcmp(icmp: ir.IcmpInst) ?Diagnostic {
    if (!isSelectorScalarType(icmp.operand_ty)) return .{ .unsupported_type = "icmp" };
    return null;
}

fn inspectSelect(select: ir.SelectInst) ?Diagnostic {
    if (!isSelectorScalarType(select.ty)) return .{ .unsupported_type = "select" };
    return switch (select.cond_ty) {
        .int => |bits| if (bits == 1) null else .{ .unsupported_type = "select-cond" },
        else => .{ .unsupported_type = "select-cond" },
    };
}

fn inspectCall(call: ir.CallInst) ?Diagnostic {
    if (call.inline_asm != null) return .{ .unsupported_instruction = "inline-asm-call" };
    if (call.callee_value != null) return .{ .unsupported_value = "indirect-call" };
    if (call.raw_args != null) return .{ .unsupported_instruction = "raw-call-args" };
    if (call.operand_bundle != null) return .{ .unsupported_instruction = "operand-bundle-call" };
    if (call.isDebugVariableLocation()) return null;
    if (std.mem.eql(u8, call.callee, "llvm.assume")) {
        if (call.ret_ty != .void or call.args.items.len != 1) return .{ .unsupported_instruction = "llvm.assume" };
        return if (call.args.items[0].ty.eql(.{ .int = 1 })) null else .{ .unsupported_type = "llvm.assume" };
    }
    if (isOverflowIntrinsic(call.callee)) {
        if (!call.ret_ty.eql(.{ .aggregate = "{ i64, i1 }" }) or call.args.items.len != 2) {
            return .{ .unsupported_type = "overflow-intrinsic" };
        }
        for (call.args.items) |arg| {
            if (!arg.ty.eql(.{ .int = 64 })) return .{ .unsupported_type = "overflow-intrinsic-arg" };
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
    if (!extract.aggregate_ty.eql(.{ .aggregate = "{ i64, i1 }" })) {
        return .{ .unsupported_type = "extractvalue-aggregate" };
    }
    if (std.mem.eql(u8, extract.indices, "0")) {
        return if (extract.result_ty.eql(.{ .int = 64 })) null else .{ .unsupported_type = "extractvalue-result" };
    }
    if (std.mem.eql(u8, extract.indices, "1")) {
        return if (extract.result_ty.eql(.{ .int = 1 })) null else .{ .unsupported_type = "extractvalue-result" };
    }
    return .{ .unsupported_value = "extractvalue-index" };
}

fn inspectTerminator(terminator: ir.Terminator) ?Diagnostic {
    return switch (terminator) {
        .ret => |ret| if (isScalarReturnType(ret.ty)) null else .{ .unsupported_type = "ret" },
        .br => null,
        .condbr => |condbr| switch (condbr.cond_ty) {
            .int => |bits| if (bits == 1) null else .{ .unsupported_type = "condbr" },
            else => .{ .unsupported_type = "condbr" },
        },
        .@"switch" => .{ .unsupported_control_flow = "switch" },
        .indirectbr => .{ .unsupported_control_flow = "indirectbr" },
        .@"unreachable" => .{ .unsupported_control_flow = "unreachable" },
    };
}

fn isScalarReturnType(ty: ir.Type) bool {
    return ty == .void or isSelectorScalarType(ty);
}

fn isSelectorScalarType(ty: ir.Type) bool {
    return switch (ty) {
        .int => |bits| bits > 0 and bits <= 128,
        .ptr => true,
        .void, .half, .float, .double, .x86_fp80, .fp128, .metadata, .aggregate, .vector => false,
    };
}

fn isOverflowIntrinsic(callee: []const u8) bool {
    return std.mem.eql(u8, callee, "llvm.uadd.with.overflow.i64") or
        std.mem.eql(u8, callee, "llvm.usub.with.overflow.i64");
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
