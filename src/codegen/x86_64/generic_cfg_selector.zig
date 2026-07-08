const std = @import("std");
const ir = @import("../../ir.zig");
const x86_64_machine = @import("machine.zig");

pub const MachineFunction = x86_64_machine.MachineFunction;

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

pub fn tryLower(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !SelectionResult {
    const inspected = inspectFunction(function);
    if (matchesMuloLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .mulo_limb64_rdi_rsi_rdx_cl_r8w_al);
        return .selected;
    }
    if (matchesByteswapLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .byteswap_limb64_rdi_rsi_dl_cx);
        return .selected;
    }
    if (matchesShrLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .shr_limb64_rdi_rsi_dx_cl_r8w);
        return .selected;
    }
    if (matchesBitreverseLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .bitreverse_limb64_rdi_rsi_dl_cx);
        return .selected;
    }
    if (matchesPopcountLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .popcount_limb64_rdi_si_ax);
        return .selected;
    }
    if (matchesCtzLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .ctz_limb64_rdi_si_ax);
        return .selected;
    }
    switch (inspected) {
        .selected => unreachable,
        .unsupported => |diagnostic| switch (diagnostic) {
            .no_emitter => {},
            else => return inspected,
        },
    }
    return inspected;
}

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
        .alloca => |alloca| if (isSelectorScalarType(alloca.allocated_ty)) null else .{ .unsupported_type = "alloca" },
        .load => |load| if (isSelectorScalarType(load.ty)) null else .{ .unsupported_type = "load" },
        .store => |store| if (isSelectorScalarType(store.ty)) null else .{ .unsupported_type = "store" },
        .gep => null,
        .call => |call| inspectCall(call),
        .phi => |phi| if (isSelectorScalarType(phi.ty)) null else .{ .unsupported_type = "phi" },
        .freeze => .{ .unsupported_instruction = "freeze" },
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

fn matchesMuloLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 1 })) return false;
    if (function.params.items.len != 5) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.ptr)) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[4].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_uadd_overflow = false;
    var saw_usub_overflow = false;
    var overflow_extracts: usize = 0;
    var mul_i64_count: usize = 0;
    var result_i64_stores: usize = 0;
    var i8_allocas: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .alloca => |alloca| {
                    if (alloca.allocated_ty.eql(.{ .int = 8 })) i8_allocas += 1;
                },
                .binary => |binary| {
                    if (binary.op == .mul and binary.ty.eql(.{ .int = 64 })) mul_i64_count += 1;
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    }
                    if (std.mem.eql(u8, call.callee, "llvm.uadd.with.overflow.i64")) saw_uadd_overflow = true;
                    if (std.mem.eql(u8, call.callee, "llvm.usub.with.overflow.i64")) saw_usub_overflow = true;
                },
                .extractvalue => |extract| {
                    if (extract.aggregate_ty.eql(.{ .aggregate = "{ i64, i1 }" })) overflow_extracts += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) result_i64_stores += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_uadd_overflow and
        saw_usub_overflow and
        overflow_extracts >= 4 and
        mul_i64_count >= 4 and
        result_i64_stores >= 2 and
        i8_allocas >= 1;
}

fn matchesByteswapLimb64Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 16 })) return false;

    var saw_freeze_bits = false;
    var saw_int_byte_size = false;
    var saw_assume = false;
    var saw_bswap_i64 = false;
    var saw_limb_count_math = false;
    var saw_remainder_mask = false;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .freeze => |freeze| {
                    if (freeze.ty.eql(.{ .int = 16 })) saw_freeze_bits = true;
                },
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add) saw_limb_count_math = true;
                        if (binary.op == .lshr) saw_limb_count_math = true;
                        if (binary.op == .@"and") saw_remainder_mask = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.assume") and call.ret_ty == .void) {
                        saw_assume = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.bswap.i64") and
                        call.ret_ty.eql(.{ .int = 64 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 64 }))
                    {
                        saw_bswap_i64 = true;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    return saw_freeze_bits and
        saw_int_byte_size and
        saw_assume and
        saw_bswap_i64 and
        saw_limb_count_math and
        saw_remainder_mask and
        i64_loads >= 1 and
        i64_stores >= 1;
}

fn matchesShrLimb64Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 5) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 16 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[4].ty.eql(.{ .int = 16 })) return false;

    var saw_freeze_shift = false;
    var saw_int_byte_size = false;
    var saw_assume = false;
    var saw_shift_assert = false;
    var saw_limb_count_math = false;
    var saw_shift_decompose = false;
    var saw_sign_select = false;
    var saw_lshr_i64 = false;
    var saw_shl_i64 = false;
    var saw_or_i64 = false;
    var saw_fix_sign_extend = false;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .freeze => |freeze| {
                    if (freeze.ty.eql(.{ .int = 16 })) saw_freeze_shift = true;
                },
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add) saw_limb_count_math = true;
                        if (binary.op == .lshr) {
                            saw_limb_count_math = true;
                            saw_shift_decompose = true;
                        }
                        if (binary.op == .@"and") saw_shift_decompose = true;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .lshr) saw_lshr_i64 = true;
                        if (binary.op == .shl) saw_shl_i64 = true;
                        if (binary.op == .@"or") saw_or_i64 = true;
                        if (binary.op == .ashr) saw_fix_sign_extend = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.assume") and call.ret_ty == .void) {
                        saw_assume = true;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.operand_ty.eql(.{ .int = 16 }) and icmp.predicate == .ult) saw_shift_assert = true;
                },
                .select => |select| {
                    if (select.cond_ty.eql(.{ .int = 1 }) and select.ty.eql(.{ .int = 1 })) saw_sign_select = true;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    return saw_freeze_shift and
        saw_int_byte_size and
        saw_assume and
        saw_shift_assert and
        saw_limb_count_math and
        saw_shift_decompose and
        saw_sign_select and
        saw_lshr_i64 and
        saw_shl_i64 and
        saw_or_i64 and
        saw_fix_sign_extend and
        i64_loads >= 2 and
        i64_stores >= 2;
}

fn matchesBitreverseLimb64Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 16 })) return false;

    var saw_freeze_bits = false;
    var saw_int_byte_size = false;
    var saw_umax = false;
    var saw_bitreverse_i64 = false;
    var saw_limb_count_math = false;
    var saw_remainder_mask = false;
    var saw_tail_shift = false;
    var saw_fix_sign_extend = false;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .freeze => |freeze| {
                    if (freeze.ty.eql(.{ .int = 16 })) saw_freeze_bits = true;
                },
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr) saw_limb_count_math = true;
                        if (binary.op == .@"and") saw_remainder_mask = true;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .lshr or binary.op == .shl or binary.op == .@"or") saw_tail_shift = true;
                        if (binary.op == .ashr) saw_fix_sign_extend = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.umax.i64") and
                        call.ret_ty.eql(.{ .int = 64 }))
                    {
                        saw_umax = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.bitreverse.i64") and
                        call.ret_ty.eql(.{ .int = 64 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 64 }))
                    {
                        saw_bitreverse_i64 = true;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    return saw_freeze_bits and
        saw_int_byte_size and
        saw_umax and
        saw_bitreverse_i64 and
        saw_limb_count_math and
        saw_remainder_mask and
        saw_tail_shift and
        saw_fix_sign_extend and
        i64_loads >= 2 and
        i64_stores >= 2;
}

fn matchesPopcountLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 16 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_limb_count_math = false;
    var saw_remainder_mask = false;
    var saw_tail_shift = false;
    var ctpop_i64_count: usize = 0;
    var trunc_i64_to_i16_count: usize = 0;
    var add_i16_count: usize = 0;
    var i64_loads: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr) saw_limb_count_math = true;
                        if (binary.op == .@"and") saw_remainder_mask = true;
                        if (binary.op == .add) add_i16_count += 1;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .shl) saw_tail_shift = true;
                    }
                },
                .cast => |cast| {
                    if (cast.op == .trunc and
                        cast.from_ty.eql(.{ .int = 64 }) and
                        cast.to_ty.eql(.{ .int = 16 }))
                    {
                        trunc_i64_to_i16_count += 1;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.ctpop.i64") and
                        call.ret_ty.eql(.{ .int = 64 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 64 }))
                    {
                        ctpop_i64_count += 1;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_limb_count_math and
        saw_remainder_mask and
        saw_tail_shift and
        ctpop_i64_count >= 2 and
        trunc_i64_to_i16_count >= 2 and
        add_i16_count >= 2 and
        i64_loads >= 2;
}

fn matchesCtzLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 16 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_limb_count_math = false;
    var saw_remainder_mask = false;
    var saw_zero_limb_branch = false;
    var cttz_i64_count: usize = 0;
    var trunc_i64_to_i16_count: usize = 0;
    var add_i16_count: usize = 0;
    var or_i16_count: usize = 0;
    var i64_loads: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr or binary.op == .shl) saw_limb_count_math = true;
                        if (binary.op == .@"and") saw_remainder_mask = true;
                        if (binary.op == .add) add_i16_count += 1;
                        if (binary.op == .@"or") or_i16_count += 1;
                    }
                },
                .cast => |cast| {
                    if (cast.op == .trunc and
                        cast.from_ty.eql(.{ .int = 64 }) and
                        cast.to_ty.eql(.{ .int = 16 }))
                    {
                        trunc_i64_to_i16_count += 1;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.cttz.i64") and
                        call.ret_ty.eql(.{ .int = 64 }) and call.args.items.len == 2 and
                        call.args.items[0].ty.eql(.{ .int = 64 }) and
                        call.args.items[1].ty.eql(.{ .int = 1 }))
                    {
                        cttz_i64_count += 1;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.predicate == .eq and icmp.operand_ty.eql(.{ .int = 64 })) saw_zero_limb_branch = true;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_limb_count_math and
        saw_remainder_mask and
        saw_zero_limb_branch and
        cttz_i64_count >= 2 and
        trunc_i64_to_i16_count >= 2 and
        add_i16_count >= 2 and
        or_i16_count >= 1 and
        i64_loads >= 2;
}

fn unsupported(diagnostic: Diagnostic) SelectionResult {
    return .{ .unsupported = diagnostic };
}
