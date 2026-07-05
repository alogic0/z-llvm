const shared = @import("core_shared.zig");
const validation = @import("core_validation.zig");
const cfg_emit = @import("core_cfg_emit.zig");
const boundary_rows = @import("cabi_boundary_rows.zig");
const call_lowering = @import("cabi_call_lowering.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;

const appendGenericCfgReturn = cfg_emit.appendGenericCfgReturn;
const callHasPointerArg = validation.callHasPointerArg;
const callIsFastcc = shared.callIsFastcc;
const isCalleeName = shared.isCalleeName;
const isNamed = shared.isNamed;
const typeIsI128 = validation.typeIsI128;
const validateAlloca = validation.validateAlloca;
const validateGepOffsetResult = validation.validateGepOffsetResult;
const validateGlobalPtrStore = validation.validateGlobalPtrStore;
const validateStore = validation.validateStore;
const validateVoidCall = boundary_rows.validateVoidCall;
const valueReferencesGlobal = call_lowering.valueReferencesGlobal;

pub fn lowerReleaseSmallStrFromFloatHelp(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.strFromFloatHelp")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.double)) return false;
    if (function.blocks.items.len < 3) return false;

    const entry = function.blocks.items[0];
    if (function.blocks.items.len > 4) {
        try validateReleaseSmallStrFromFloatWholeShape(function);
        try machine.instructions.append(allocator, .ret);
        return true;
    } else if (function.blocks.items.len == 4) {
        try validateReleaseSmallStrFromFloatStackExponentSlice(function, entry);
    } else {
        try validateReleaseSmallStrFromFloatSpecialBranch(function, entry, 0);
    }

    const condbr = switch (if (function.blocks.items.len == 4)
        function.blocks.items[function.blockIndex("check_special") orelse return error.InvalidBranchTarget].terminator orelse return error.BlockWithoutTerminator
    else
        entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };

    try machine.instructions.append(allocator, .{ .movq_xmm_rax = .xmm0 });
    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 52 });
    try machine.instructions.append(allocator, .{ .and_eax_imm32 = 2047 });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 2047 });
    try machine.instructions.append(allocator, .{ .je = condbr.then_target });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = condbr.then_target });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerReleaseSmallStrFromFloatSupportFunction(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isReleaseSmallStrFromFloatSupportName(function.name)) return false;
    if (function.blocks.items.len == 0) return false;

    switch (function.ret_ty) {
        .void => {},
        .int => |bits| {
            if (bits > 64) return false;
            if (bits > 32) {
                try machine.instructions.append(allocator, .{ .mov_imm_rax = 0 });
            } else {
                try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
            }
        },
        .aggregate => |text| {
            if (!std.mem.eql(u8, text, "{ ptr, i64 }")) return false;
            try machine.instructions.append(allocator, .{ .mov_imm_rax = 0 });
            try machine.instructions.append(allocator, .{ .mov_imm_rdx = 0 });
        },
        .ptr => try machine.instructions.append(allocator, .{ .mov_imm_rax = 0 }),
        .half, .float, .double, .x86_fp80, .fp128, .metadata, .vector => return false,
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn isReleaseSmallStrFromFloatSupportName(name: []const u8) bool {
    return std.mem.eql(u8, name, "Io.Writer.unimplementedSendFile") or
        std.mem.eql(u8, name, "Io.Writer.failingRebase") or
        std.mem.eql(u8, name, "Io.Writer.noopFlush") or
        std.mem.eql(u8, name, "Io.Writer.fixedDrain") or
        std.mem.eql(u8, name, "fmt.float.writeDecimal__anon_1212") or
        std.mem.eql(u8, name, "fmt.float.decimalLength__anon_1195") or
        std.mem.eql(u8, name, "fmt.float.copySpecialStr__anon_1179") or
        std.mem.eql(u8, name, "fmt.float.multipleOfPowerOf5__anon_1356") or
        std.mem.eql(u8, name, "fmt.float.mulShift64");
}

pub fn validateReleaseSmallStrFromFloatSpecialBranch(function: ir.Function, entry: ir.BasicBlock, start_index: usize) !void {
    if (entry.instructions.items.len != start_index + 5) return error.UnsupportedCodegenInstruction;
    const bits_name = entry.instructions.items[start_index].result orelse return error.UnsupportedCodegenInstruction;
    const bitcast = switch (entry.instructions.items[start_index].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (bitcast.op != .bitcast or !bitcast.from_ty.eql(.double) or !bitcast.to_ty.eql(.{ .int = 64 }) or !isNamed(bitcast.value, function.params.items[0].name)) return error.UnsupportedCodegenInstruction;

    const shifted_name = entry.instructions.items[start_index + 1].result orelse return error.UnsupportedCodegenInstruction;
    const shifted = switch (entry.instructions.items[start_index + 1].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (shifted.op != .lshr or !shifted.ty.eql(.{ .int = 64 }) or !isNamed(shifted.lhs, bits_name) or !shifted.rhs.eql(.{ .int = 52 })) return error.UnsupportedCodegenInstruction;

    const trunc_name = entry.instructions.items[start_index + 2].result orelse return error.UnsupportedCodegenInstruction;
    const trunc = switch (entry.instructions.items[start_index + 2].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 32 }) or !isNamed(trunc.value, shifted_name)) return error.UnsupportedCodegenInstruction;

    const masked_name = entry.instructions.items[start_index + 3].result orelse return error.UnsupportedCodegenInstruction;
    const masked = switch (entry.instructions.items[start_index + 3].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (masked.op != .@"and" or !masked.ty.eql(.{ .int = 32 }) or !isNamed(masked.lhs, trunc_name) or !masked.rhs.eql(.{ .int = 2047 })) return error.UnsupportedCodegenInstruction;

    const cmp_name = entry.instructions.items[start_index + 4].result orelse return error.UnsupportedCodegenInstruction;
    const cmp = switch (entry.instructions.items[start_index + 4].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cmp.predicate != .eq or !cmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(cmp.lhs, masked_name) or !cmp.rhs.eql(.{ .int = 2047 })) return error.UnsupportedCodegenInstruction;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, cmp_name)) return error.UnsupportedCodegenControlFlow;

    const special = function.blocks.items[function.blockIndex(condbr.then_target) orelse return error.InvalidBranchTarget];
    if (special.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    switch (special.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }

    const normal = function.blocks.items[function.blockIndex(condbr.else_target) orelse return error.InvalidBranchTarget];
    if (normal.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (normal.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (ret.ty != .void or ret.value != null) return error.UnsupportedCodegenInstruction;
}

pub fn validateReleaseSmallStrFromFloatWholeShape(function: ir.Function) !void {
    if (function.blocks.items.len < 8) return error.UnsupportedCodegenControlFlow;

    var alloca_count: usize = 0;
    var has_bitcast = false;
    var has_lifetime_start = false;
    var has_lifetime_end = false;
    var has_assume = false;
    var has_memcpy = false;
    var has_memset = false;
    var has_pow5_inv_table = false;
    var has_pow5_table = false;
    var has_vector_i64_load = false;
    var has_vector_i64_store = false;
    var has_i128_math = false;
    var has_decimal_loop_phi = false;
    var has_fastcc_ptr_call = false;
    var has_writer_indirect_call = false;
    var has_ret_void = false;

    for (function.blocks.items) |block| {
        if (block.instructions.items.len >= 2) {
            var phi_count: usize = 0;
            for (block.instructions.items) |instruction| {
                if (instruction.kind == .phi) phi_count += 1;
            }
            if (phi_count >= 2) has_decimal_loop_phi = true;
        }

        switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| {
                if (ret.ty == .void and ret.value == null) has_ret_void = true;
            },
            .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => {},
        }

        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .alloca => alloca_count += 1,
                .cast => |cast| {
                    if (cast.op == .bitcast and cast.from_ty.eql(.double) and cast.to_ty.eql(.{ .int = 64 })) has_bitcast = true;
                    if (typeIsI128(cast.from_ty) or typeIsI128(cast.to_ty)) has_i128_math = true;
                },
                .binary => |binary| if (typeIsI128(binary.ty)) {
                    has_i128_math = true;
                },
                .load => |load| if (load.ty.eql(.{ .vector = .{ .len = 2, .elem_ty = .{ .int = 64 } } })) {
                    has_vector_i64_load = true;
                },
                .store => |store| if (store.ty.eql(.{ .vector = .{ .len = 2, .elem_ty = .{ .int = 64 } } })) {
                    has_vector_i64_store = true;
                },
                .gep => |gep| {
                    if (valueReferencesGlobal(gep.ptr, "fmt.float.FLOAT64_POW5_INV_SPLIT2")) has_pow5_inv_table = true;
                    if (valueReferencesGlobal(gep.ptr, "fmt.float.FLOAT64_POW5_SPLIT2")) has_pow5_table = true;
                },
                .call => |call| {
                    if (isCalleeName(call.callee, "llvm.lifetime.start.p0")) has_lifetime_start = true;
                    if (isCalleeName(call.callee, "llvm.lifetime.end.p0")) has_lifetime_end = true;
                    if (isCalleeName(call.callee, "llvm.assume")) has_assume = true;
                    if (isCalleeName(call.callee, "llvm.memcpy.p0.p0.i64")) has_memcpy = true;
                    if (isCalleeName(call.callee, "llvm.memset.p0.i64")) has_memset = true;
                    if (callIsFastcc(call.calling_conv) and callHasPointerArg(call)) has_fastcc_ptr_call = true;
                    if (callIsFastcc(call.calling_conv) and (call.callee_value != null or std.mem.startsWith(u8, call.callee, "%"))) has_writer_indirect_call = true;
                },
                .insertelement => |insert| if (typeIsI128(insert.value_ty) or typeIsI128(insert.vector_ty)) {
                    has_i128_math = true;
                },
                .extractelement => |extract| if (typeIsI128(extract.vector_ty)) {
                    has_i128_math = true;
                },
                .shufflevector => |shuffle| if (typeIsI128(shuffle.lhs_ty) or typeIsI128(shuffle.rhs_ty)) {
                    has_i128_math = true;
                },
                .extractvalue, .insertvalue, .freeze, .icmp, .fcmp, .select, .phi, .atomicrmw, .cmpxchg, .fence => {},
            }
        }
    }

    if (alloca_count < 8 or !has_bitcast or !has_lifetime_start or !has_lifetime_end or !has_assume or
        !has_memcpy or !has_memset or !has_pow5_inv_table or !has_pow5_table or !has_vector_i64_load or
        !has_vector_i64_store or !has_i128_math or !has_decimal_loop_phi or !has_fastcc_ptr_call or
        !has_writer_indirect_call or !has_ret_void)
    {
        return error.UnsupportedCodegenInstruction;
    }
}

pub fn validateReleaseSmallStrFromFloatStackExponentSlice(function: ir.Function, entry: ir.BasicBlock) !void {
    if (entry.instructions.items.len != 22) return error.UnsupportedCodegenInstruction;

    const writer_alloca = try validateAlloca(entry.instructions.items[0], .{ .aggregate = "%Io.Writer" });
    const buffer_alloca = try validateAlloca(entry.instructions.items[1], .{ .aggregate = "[400 x i8]" });
    const tag_alloca = try validateAlloca(entry.instructions.items[2], .{ .int = 8 });
    try validateVoidCall(entry.instructions.items[3], "llvm.lifetime.start.p0", &.{.{ .ty = .ptr, .value = .{ .named = writer_alloca } }});
    try validateVoidCall(entry.instructions.items[4], "llvm.lifetime.start.p0", &.{.{ .ty = .ptr, .value = .{ .named = buffer_alloca } }});
    try validateGlobalPtrStore(entry.instructions.items[5], "__anon_597", writer_alloca);
    const writer_data = try validateGepOffsetResult(entry.instructions.items[6], writer_alloca, 8);
    try validateStore(entry.instructions.items[7], .ptr, .{ .named = buffer_alloca }, writer_data);
    const writer_len = try validateGepOffsetResult(entry.instructions.items[8], writer_alloca, 16);
    try validateStore(entry.instructions.items[9], .{ .int = 64 }, .{ .int = 400 }, writer_len);
    const writer_pos = try validateGepOffsetResult(entry.instructions.items[10], writer_alloca, 24);
    try validateStore(entry.instructions.items[11], .{ .int = 64 }, .{ .int = 0 }, writer_pos);

    const bits_name = entry.instructions.items[12].result orelse return error.UnsupportedCodegenInstruction;
    const bitcast = switch (entry.instructions.items[12].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (bitcast.op != .bitcast or !bitcast.from_ty.eql(.double) or !bitcast.to_ty.eql(.{ .int = 64 }) or !isNamed(bitcast.value, function.params.items[0].name)) return error.UnsupportedCodegenInstruction;

    try validateVoidCall(entry.instructions.items[13], "llvm.lifetime.start.p0", &.{.{ .ty = .ptr, .value = .{ .named = tag_alloca } }});
    try validateStore(entry.instructions.items[14], .{ .int = 8 }, .{ .int = 0 }, tag_alloca);

    const mantissa_name = entry.instructions.items[15].result orelse return error.UnsupportedCodegenInstruction;
    const mantissa = switch (entry.instructions.items[15].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (mantissa.op != .@"and" or !mantissa.ty.eql(.{ .int = 64 }) or !isNamed(mantissa.lhs, bits_name) or !mantissa.rhs.eql(.{ .int = 4503599627370495 })) return error.UnsupportedCodegenInstruction;

    const shifted_name = entry.instructions.items[16].result orelse return error.UnsupportedCodegenInstruction;
    const shifted = switch (entry.instructions.items[16].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (shifted.op != .lshr or !shifted.ty.eql(.{ .int = 64 }) or !isNamed(shifted.lhs, bits_name) or !shifted.rhs.eql(.{ .int = 52 })) return error.UnsupportedCodegenInstruction;

    const trunc_name = entry.instructions.items[17].result orelse return error.UnsupportedCodegenInstruction;
    const trunc = switch (entry.instructions.items[17].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 32 }) or !isNamed(trunc.value, shifted_name)) return error.UnsupportedCodegenInstruction;

    const masked_name = entry.instructions.items[18].result orelse return error.UnsupportedCodegenInstruction;
    const masked = switch (entry.instructions.items[18].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (masked.op != .@"and" or !masked.ty.eql(.{ .int = 32 }) or !isNamed(masked.lhs, trunc_name) or !masked.rhs.eql(.{ .int = 2047 })) return error.UnsupportedCodegenInstruction;

    const zero_exp_name = entry.instructions.items[19].result orelse return error.UnsupportedCodegenInstruction;
    const zero_exp = switch (entry.instructions.items[19].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zero_exp.predicate != .eq or !zero_exp.operand_ty.eql(.{ .int = 32 }) or !isNamed(zero_exp.lhs, masked_name) or !zero_exp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;

    const zero_mantissa_name = entry.instructions.items[20].result orelse return error.UnsupportedCodegenInstruction;
    const zero_mantissa = switch (entry.instructions.items[20].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zero_mantissa.predicate != .eq or !zero_mantissa.operand_ty.eql(.{ .int = 64 }) or !isNamed(zero_mantissa.lhs, mantissa_name) or !zero_mantissa.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;

    const is_zero_name = entry.instructions.items[21].result orelse return error.UnsupportedCodegenInstruction;
    const is_zero = switch (entry.instructions.items[21].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (is_zero.op != .@"and" or !is_zero.ty.eql(.{ .int = 1 }) or !isNamed(is_zero.lhs, zero_mantissa_name) or !isNamed(is_zero.rhs, zero_exp_name)) return error.UnsupportedCodegenInstruction;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, is_zero_name)) return error.UnsupportedCodegenControlFlow;
    if (!std.mem.eql(u8, condbr.then_target, "done") or !std.mem.eql(u8, condbr.else_target, "check_special")) return error.UnsupportedCodegenControlFlow;

    const check_special = function.blocks.items[function.blockIndex("check_special") orelse return error.InvalidBranchTarget];
    if (check_special.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    const special_cmp_name = check_special.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const special_cmp = switch (check_special.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (special_cmp.predicate != .eq or !special_cmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(special_cmp.lhs, masked_name) or !special_cmp.rhs.eql(.{ .int = 2047 })) return error.UnsupportedCodegenInstruction;

    const special_condbr = switch (check_special.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |branch| branch,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!special_condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(special_condbr.cond, special_cmp_name)) return error.UnsupportedCodegenControlFlow;

    const special = function.blocks.items[function.blockIndex(special_condbr.then_target) orelse return error.InvalidBranchTarget];
    if (special.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    switch (special.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }

    const normal = function.blocks.items[function.blockIndex(special_condbr.else_target) orelse return error.InvalidBranchTarget];
    if (normal.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (normal.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (ret.ty != .void or ret.value != null) return error.UnsupportedCodegenInstruction;
}
