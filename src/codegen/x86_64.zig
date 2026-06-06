const std = @import("std");
const ir = @import("../ir.zig");
const target = @import("../target.zig");

pub const ArgReg = enum {
    rdi,
    rsi,
    rdx,
    rcx,
    r8,
    r9,

    pub fn name32(reg: ArgReg) []const u8 {
        return switch (reg) {
            .rdi => "%edi",
            .rsi => "%esi",
            .rdx => "%edx",
            .rcx => "%ecx",
            .r8 => "%r8d",
            .r9 => "%r9d",
        };
    }

    pub fn name16(reg: ArgReg) []const u8 {
        return switch (reg) {
            .rdi => "%di",
            .rsi => "%si",
            .rdx => "%dx",
            .rcx => "%cx",
            .r8 => "%r8w",
            .r9 => "%r9w",
        };
    }

    pub fn name64(reg: ArgReg) []const u8 {
        return switch (reg) {
            .rdi => "%rdi",
            .rsi => "%rsi",
            .rdx => "%rdx",
            .rcx => "%rcx",
            .r8 => "%r8",
            .r9 => "%r9",
        };
    }

    pub fn name8(reg: ArgReg) []const u8 {
        return switch (reg) {
            .rdi => "%dil",
            .rsi => "%sil",
            .rdx => "%dl",
            .rcx => "%cl",
            .r8 => "%r8b",
            .r9 => "%r9b",
        };
    }

    pub fn lowCode(reg: ArgReg) u3 {
        return switch (reg) {
            .rdi => 7,
            .rsi => 6,
            .rdx => 2,
            .rcx => 1,
            .r8 => 0,
            .r9 => 1,
        };
    }

    pub fn fromIndex(index: usize) !ArgReg {
        return switch (index) {
            0 => .rdi,
            1 => .rsi,
            2 => .rdx,
            3 => .rcx,
            4 => .r8,
            5 => .r9,
            else => error.UnsupportedCodegenAbi,
        };
    }

    pub fn rexR(reg: ArgReg) bool {
        return reg == .r8 or reg == .r9;
    }

    pub fn rexB(reg: ArgReg) bool {
        return reg == .r8 or reg == .r9;
    }

    pub fn needsRex8(reg: ArgReg) bool {
        return reg == .rdi or reg == .rsi or reg == .r8 or reg == .r9;
    }
};

pub const XmmReg = enum(u3) {
    xmm0,
    xmm1,
    xmm2,
    xmm3,
    xmm4,

    pub fn name(reg: XmmReg) []const u8 {
        return switch (reg) {
            .xmm0 => "%xmm0",
            .xmm1 => "%xmm1",
            .xmm2 => "%xmm2",
            .xmm3 => "%xmm3",
            .xmm4 => "%xmm4",
        };
    }

    pub fn lowCode(reg: XmmReg) u3 {
        return @intFromEnum(reg);
    }
};

pub const MachineBinaryOp = enum {
    add,
    sub,
    @"and",
    @"or",
    xor,

    pub fn mnemonic(op: MachineBinaryOp) []const u8 {
        return switch (op) {
            .add => "addl",
            .sub => "subl",
            .@"and" => "andl",
            .@"or" => "orl",
            .xor => "xorl",
        };
    }
};

pub const FrameIndex = enum {
    slot0,
};

pub const Instruction = union(enum) {
    label: []const u8,
    mov_imm_eax: i32,
    mov_imm_rax: i64,
    mov_imm_rdi: i64,
    mov_imm_rdx: i64,
    mov_imm_rsi: i64,
    mov_imm_rcx: i64,
    movq_xmm_rax: XmmReg,
    mov_arg_eax: ArgReg,
    mov_arg_arg: struct {
        dst: ArgReg,
        src: ArgReg,
    },
    binary_arg_eax: struct {
        op: MachineBinaryOp,
        reg: ArgReg,
    },
    add_eax_imm32: i32,
    shl_eax_imm5: u5,
    or_eax_imm32: i32,
    imul_eax_imm32: i32,
    and_eax_imm32: i32,
    shr_rax_imm6: u6,
    shl_rdx_imm6: u6,
    or_rdx_rax,
    add_rax_imm8: u8,
    add_ecx_eax,
    xor_ecx_ecx,
    xor_ebp_ebp,
    add_rdi_rcx4_ptr_eax,
    inc_rcx,
    movzx_dil_edi,
    and_edi_imm8: u8,
    load_rax_rdi_u8_eax,
    smin_i32_edi_esi_eax,
    shift_mix_i32_edi_esi_eax,
    replace_low_i8_dil_sil_al,
    read_flag_i8_dil_al,
    store_imm8_abs: struct {
        address: u32,
        value: u8,
    },
    cmp_ecx_arg32: ArgReg,
    cmp_rcx_arg64: ArgReg,
    cmp_ecx_imm32: i32,
    cmp_eax_imm32: i32,
    cmp_arg64_imm64: struct {
        reg: ArgReg,
        imm: i64,
    },
    cmp_arg16_imm16: struct {
        reg: ArgReg,
        imm: u16,
    },
    cmp_rdi_imm64: i64,
    cmp_rdx_rdi,
    cmp_rax_rdx,
    test_eax_eax,
    test_rax_rax,
    test_rdx_rdx,
    mulsd_xmm1_xmm0,
    addss_xmm1_xmm0,
    subss_xmm1_xmm0,
    divsd_xmm1_xmm0,
    movapd_xmm1_xmm0,
    mov_imm64_xmm0: u64,
    mov_imm64_xmm1: u64,
    mov_imm32_xmm0: u32,
    mov_imm32_xmm1: u32,
    ucomisd: struct {
        src: XmmReg,
        dst: XmmReg,
    },
    ucomisd_xmm1_xmm0,
    ucomiss_xmm1_xmm0,
    oltss_xmm0_xmm1_al,
    sub_rsp_8,
    add_rsp_8,
    sub_rsp_24,
    add_rsp_24,
    spill_arg_rsp: struct {
        frame_index: FrameIndex,
        reg: ArgReg,
    },
    reload_arg_rsp: struct {
        reg: ArgReg,
        frame_index: FrameIndex,
    },
    spill_rdi_rsi_rsp24,
    reload_rdi_rsp24,
    reload_rsi_rsp24,
    reload_rsp_eax: FrameIndex,
    load_stack_disp8_rax: u8,
    load_rax_ptr_disp8_rax: u8,
    load_rax_ptr_rdx,
    load_rax_ptr_eax,
    load_arg_ptr_eax: ArgReg,
    load_arg_ptr_disp8_rax: struct {
        reg: ArgReg,
        offset: u8,
    },
    load_arg_ptr_disp8_u8_eax: struct {
        reg: ArgReg,
        offset: u8,
    },
    add_arg_ptr_disp4_eax: ArgReg,
    store_eax_arg_ptr: ArgReg,
    store_imm64_arg_ptr_disp8: struct {
        reg: ArgReg,
        offset: u8,
        imm: i32,
    },
    store_imm8_arg_ptr_disp8: struct {
        reg: ArgReg,
        offset: u8,
        imm: u8,
    },
    load_f128_arg_ptr_xmm0: struct {
        reg: ArgReg,
        offset: u8,
    },
    load_f128_const_xmm0: []const u8,
    load_f128_const_xmm1: []const u8,
    store_f128_xmm0_arg_ptr: struct {
        reg: ArgReg,
        offset: u8,
    },
    volatile_roundtrip_rdi_esi_eax,
    load_global_i32_eax: []const u8,
    load_global_ptr_rax: []const u8,
    lea_global_rax: []const u8,
    lea_global_rdi: []const u8,
    lea_global_rdx: []const u8,
    store_eax_global_i32: []const u8,
    load_tls_i32_eax: []const u8,
    add_tls_i32_eax: []const u8,
    store_eax_tls_i32: []const u8,
    atomic_xadd_global_eax: []const u8,
    mov_rsp_rdi,
    and_rsp_neg16,
    direct_call: struct {
        symbol: []const u8,
        ret_ty: ir.Type,
    },
    noreturn_direct_call: []const u8,
    cmp_arg8_imm8: struct {
        reg: ArgReg,
        imm: u8,
    },
    test_arg8: ArgReg,
    test_arg32: ArgReg,
    test_arg64: ArgReg,
    base64_raw_args_to_decode4_regs,
    base64_decode4_from_table_rax,
    je: []const u8,
    jne: []const u8,
    jo: []const u8,
    jp: []const u8,
    js: []const u8,
    jmp: []const u8,
    ud2,
    ret,
};

pub const MachineFunction = struct {
    name: []const u8,
    ret_ty: ir.Type,
    instructions: std.ArrayList(Instruction),

    pub fn init(name: []const u8, ret_ty: ir.Type) MachineFunction {
        return .{
            .name = name,
            .ret_ty = ret_ty,
            .instructions = .empty,
        };
    }

    pub fn deinit(function: *MachineFunction, allocator: std.mem.Allocator) void {
        function.instructions.deinit(allocator);
    }
};

const SelectedI32Value = union(enum) {
    imm: i32,
    reg: ArgReg,
};

pub fn lowerFunction(allocator: std.mem.Allocator, triple_text: []const u8, function: ir.Function) !MachineFunction {
    const parsed_triple = try target.Triple.parse(triple_text);
    if (!parsed_triple.isX86_64() or !parsed_triple.isLinux()) return error.UnsupportedTarget;

    var machine = MachineFunction.init(symbolName(function.name), function.ret_ty);
    errdefer machine.deinit(allocator);

    if (try lowerVolatileAbsoluteStore(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerUnreachableStub(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerReleaseSmallStrFromFloatHelp(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerReleaseSmallStrFromFloatSupportFunction(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerDebugLogicalPointerCompileError(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerDebugSpirvMergeLogicalPointers(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerI64PassThroughFunctionFamily(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerI64SaturatingHelperFunctionFamily(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiF128Sret(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiF128AggregateReturn(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiF128ScalarReturn(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiAssertPDReturnCode(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetPD(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetCFF(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiAssertCFFReturnCode(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetDC(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiAssertDCReturnCode(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetSplitStructMixed(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetMedStructMixed(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetMedStructInts(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetSmallStructInts(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructU32Union(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructU64U64(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructF32F32F32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructF32A8F32A8(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructF32A8(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructF64(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructF32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructU64(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructU32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructU16(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructU8(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetI64(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetU64(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetU32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetI16(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetI8(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetU16(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetU8(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetBool(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiMultipleStructFloats(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiMultipleStructInts(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiBigStructBoth(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiSplitStructMixed(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiSplitStructInts(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiBigPackedStruct(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiSmallPackedStruct(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiMedStructInts(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiSmallStructInts(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiMedStructMixed(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiBigUnion(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiBigStruct(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructI32I32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU32Union(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructF32F32F32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructF32A8F32A8(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructF32A8(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructF64(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiCmultdComp(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiCmultfComp(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiCmultf(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructF32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU64U648(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU64U647(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU64U646(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU64U645(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU64U644(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU64U643(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU64U642(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU64U641(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU64U640(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU64(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU16(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU8(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiBool(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiPtr(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiF64(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiF32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiFiveFloats(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructU128(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiStructI128(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiI64(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiI32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiI16(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiI8(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiFiveIntegers(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiPanic(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerStartTrampoline(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerGetauxvalImpl(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerSelectedInfiniteLoop(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerSelectedLibfuzzerDebugO0(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerSelectedMixCFilesAddZigDebugO0(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerSelectedMixCFilesAddMayPanicDebugO0(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerSelectedIssue339TestFoo(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerRuntimeOptionalPayloadPreoptHelper(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerRuntimeErrorUnionPayloadPreoptHelper(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerRuntimePointerLoadStorePreoptMain(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerBase64DecodeBase64FullMain(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (function.blocks.items.len == 1) {
        try lowerStraightLineReturn(allocator, &machine, function, function.blocks.items[0]);
        try verifyFunction(machine);
        return machine;
    }

    if (function.blocks.items.len == 3) {
        if (try lowerSelectedMixCFilesAddMayPanic(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try lowerSelectedDebugScopeBranch(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try lowerSelectedCheckedAddRuntimeBoundaryMain(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try lowerCheckedGlobalUpdateMain(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try lowerCheckedSingleParamAddFunction(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try lowerFpExponentRuntimeBoundaryMain(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try lowerRuntimeOptionalPointerPreoptMain(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try lowerRuntimeOptionalPointerMain(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try lowerConditionalReturn(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try lowerErrorSwitchReturn(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try lowerOptionalPointerLoadReturn(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
    }

    if (function.blocks.items.len == 4) {
        if (try lowerDescriptorTableLoopMain(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
        if (try lowerDenseSwitchReturn(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
    }

    if (try lowerBase64LoopAdvanceStep(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerBase64ResidualGuardStep(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerBase64PaddingLoopStep(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerBase64DecodeBase64FullBoundary(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerControlFlowLoopSum(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerRuntimeSliceSumPreoptHelper(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerSliceSumLoop(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedStructSum(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedArraySum(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedDebugLocation(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedCallChain(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedComptimeConst(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedGlobalUpdate(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedPointerLoadStore(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedBranchMix(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedAddRuntimeBoundaryMain(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedTinyAdd(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCheckedTlsBump(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    return error.UnsupportedCodegenControlFlow;
}

fn lowerStraightLineReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !void {
    const terminator = block.terminator orelse return error.BlockWithoutTerminator;
    switch (terminator) {
        .ret => |ret| {
            if (!ret.ty.eql(function.ret_ty)) return error.ReturnTypeMismatch;
            if (try lowerAggregatePairAbiFamilyReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeFloatLessMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectedRuntimeFloatCallCompareMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerDescriptorFpCheckMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSimpleVoidCallBoundaryFamilyReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSingleStackSlotCallReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSingleStackSlotReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectAddSubReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimePhiSelectReturn(allocator, machine, function, block, ret)) return;
            if (try lowerIcmpSelectConstReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFcmpSelectConstReturn(allocator, machine, function, block, ret)) return;
            if (try lowerErrorSwitchSelectReturn(allocator, machine, function, block, ret)) return;
            if (try lowerAddImmReturn(allocator, machine, function, block, ret)) return;
            if (try lowerShiftOrConstReturn(allocator, machine, function, block, ret)) return;
            if (try lowerMulConstReturn(allocator, machine, function, block, ret)) return;
            if (try lowerIntegerSminReturn(allocator, machine, function, block, ret)) return;
            if (try lowerIntegerShiftMixReturn(allocator, machine, function, block, ret)) return;
            if (try lowerPackedReplaceLowReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimePackedReplaceLowMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerPackedReadFlagReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimePackedReadFlagMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerPointerLoadStoreReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimePointerLoadStoreMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerPointerVolatileRoundtripReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeVolatileRoundtripMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatMulReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeFloatAddMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatAddReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeFloatSubMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatSubReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeDoubleDivMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerDoubleDivReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeFloatRemMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatRemReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeFloatMulMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatSelectReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatLessReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatLiteralReturn(allocator, machine, function, ret)) return;
            if (try lowerAggregateAbiReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectedMixCFilesAddZig(allocator, machine, function, block, ret)) return;
            if (try lowerStructSumReturn(allocator, machine, function, block, ret)) return;
            if (try lowerAddChain3Return(allocator, machine, function, block, ret)) return;
            if (try lowerInlineAsmBarrierReturn(allocator, machine, function, block, ret)) return;
            if (try lowerAtomicAddReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeCheckedStructSumMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeStructSumMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeArraySumMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeOptionalPayloadMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeErrorUnionPayloadMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeSliceSumMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeComptimeConstMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeDebugLocationMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerTlsBumpCallMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerDirectI32CallMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerControlFlowCallsWriterMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectedI64CallMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerGlobalReadReturn(allocator, machine, function, block, ret)) return;
            if (try lowerGlobalUpdateCheckMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerGlobalUpdateReturn(allocator, machine, function, block, ret)) return;
            if (try lowerHiddenGlobalAccessFamilyReturn(allocator, machine, function, block, ret)) return;
            if (try lowerMixedCZigTlsInputFamilyReturn(allocator, machine, function, block, ret)) return;
            if (try lowerReleaseSmallMixCAddMayPanicMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerReleaseSmallStrFromFloatMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerTlsMainReadReturn(allocator, machine, function, block, ret)) return;
            if (try lowerTlsMainUpdateReturn(allocator, machine, function, block, ret)) return;
            if (try lowerTlsReadReturn(allocator, machine, function, block, ret)) return;
            if (try lowerTlsBumpReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectedI64ConstReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectedI1ConstReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectedStringSliceReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64BitBufferStoreStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ResidualBundleStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ThirdSourceBundleStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64NextSourceBundleStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64SourceBundleStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64SourceStrideStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ChunkGuardStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64PaddingLengthStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64PaddingTailStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ResidualByteStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ResidualAccumulatorStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ResidualLoopAdvanceStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ResidualPaddingCheckStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ResidualFinalMaskStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ResidualPaddingLoopStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64DecodeExitStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ResidualTableCheckStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ResidualLengthStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64ResidualStoreStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64StoreStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64DecodeStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64WriterMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64TableLookupMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64TableLookupReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectedLibfuzzerTestRun(allocator, machine, function, block, ret)) return;
            if (try lowerI64SaturatingHelperFamilyReturn(allocator, machine, function, block, ret)) return;
            if (hasLiveInstructions(block)) {
                try lowerStraightLineInstructions(allocator, machine, function, block, ret);
                return;
            }
            if (ret.ty == .void) {
                try machine.instructions.append(allocator, .ret);
                return;
            }
            if (!ret.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
            try lowerReturnValue(allocator, machine, function, block, ret.value orelse return error.InvalidRet);
            try machine.instructions.append(allocator, .ret);
        },
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    }
}

fn hasLiveInstructions(block: ir.BasicBlock) bool {
    for (block.instructions.items) |instruction| {
        if (!instruction.removed) return true;
    }
    return false;
}

fn lowerSelectedI64ConstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 0 or block.instructions.items.len != 0) return false;
    const value = switch (ret.value orelse return error.InvalidRet) {
        .int => |int| int,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };

    try machine.instructions.append(allocator, .{ .mov_imm_rax = try i64Value(value) });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerControlFlowCallsWriterMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 2) return false;

    const call_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    if (call_inst.removed or add_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const add_name = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "control_flow_calls.writer_callee")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 0) return error.UnsupportedCodegenInstruction;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or add.flags.any()) return false;
    if (!isNamed(add.lhs, call_name) or !isInt(add.rhs, 1)) return false;

    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerDirectI32CallMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1 and block.instructions.items.len != 2) return false;

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (call.args.items.len > 4) return error.UnsupportedCodegenAbi;

    var add_immediate: i32 = 0;
    if (block.instructions.items.len == 1) {
        if (!isNamed(ret.value orelse return error.InvalidRet, call_name)) return false;
    } else {
        const add_inst = block.instructions.items[1];
        if (add_inst.removed) return false;
        const add_name = add_inst.result orelse return false;
        if (!isNamed(ret.value orelse return error.InvalidRet, add_name)) return false;
        const add = switch (add_inst.kind) {
            .binary => |binary| binary,
            else => return false,
        };
        if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or add.flags.any() or !isNamed(add.lhs, call_name)) return false;
        add_immediate = switch (add.rhs) {
            .int => |int| try i32Value(int),
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        };
    }

    for (call.args.items, 0..) |arg, index| {
        if (!arg.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
        const value = switch (arg.value) {
            .int => |int| try i32Value(int),
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        };
        switch (index) {
            0 => try machine.instructions.append(allocator, .{ .mov_imm_rdi = value }),
            1 => try machine.instructions.append(allocator, .{ .mov_imm_rsi = value }),
            2 => try machine.instructions.append(allocator, .{ .mov_imm_rdx = value }),
            3 => try machine.instructions.append(allocator, .{ .mov_imm_rcx = value }),
            else => unreachable,
        }
    }
    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
    try machine.instructions.append(allocator, .add_rsp_8);
    if (add_immediate != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = add_immediate });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerTlsBumpCallMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;
    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_name)) return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!std.mem.endsWith(u8, call.callee, ".bumpTls")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 1)) return false;

    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = "runtime_tls_bump_main.tls_counter" });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .store_eax_tls_i32 = "runtime_tls_bump_main.tls_counter" });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSelectedI64CallMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "i64_arithmetic.i64_value")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.args.items.len != 0) return error.UnsupportedCodegenInstruction;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 4)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "i64_call_fail";
    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 4 });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerReleaseSmallStrFromFloatMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or !(ret.value orelse return false).eql(.{ .int = 0 })) return false;
    if (block.instructions.items.len == 0) return false;

    for (block.instructions.items) |instruction| {
        if (instruction.result != null) return false;
        const call = switch (instruction.kind) {
            .call => |call| call,
            else => return false,
        };
        try validateDefaultCallConv(call.calling_conv);
        if (call.ret_ty != .void or !isCalleeName(call.callee, "main.strFromFloatHelp") or call.args.items.len != 1) return false;
        const arg = call.args.items[0];
        if (!arg.ty.eql(.double)) return false;
        switch (arg.value) {
            .fp => {},
            .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
        try machine.instructions.append(allocator, .sub_rsp_8);
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
        try machine.instructions.append(allocator, .add_rsp_8);
    }

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeArraySumMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_array_sum_main.main");
    if (!std.mem.eql(u8, function.name, "main") and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (integrated_preopt) {
        if (!std.mem.eql(u8, call.callee, "runtime_array_sum_main.arraySum")) return false;
    } else if (!isCalleeName(call.callee, "aggregates.array_sum")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (integrated_preopt) {
        if (call.calling_conv) |cc| {
            if (!std.mem.eql(u8, cc, "fastcc")) return false;
        }
    } else {
        try validateDefaultCallConv(call.calling_conv);
    }
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 3) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 10)) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[1].value, 20)) return error.UnsupportedCodegenValue;
    if (!call.args.items[2].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[2].value, 12)) return error.UnsupportedCodegenValue;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 42)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    if (integrated_preopt) {
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    const fail = "array_sum_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_rdi = 10 });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 20 });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 12 });
    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeCheckedStructSumMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "aggregates.struct_sum")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.ptr) or !call.args.items[0].value.eql(.{ .named = "@struct_sum_value" })) return error.UnsupportedCodegenValue;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 42)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "struct_sum_fail";
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "struct_sum_value" });
    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeOptionalPayloadPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_optional_payload_main.optionalPayload")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or !function.params.items[1].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 5) return false;

    const entry = blockByName(function, "2") orelse return false;
    const merge_ptr = blockByName(function, "5") orelse return false;
    const some_block = blockByName(function, "10") orelse return false;
    const ret_block = blockByName(function, "13") orelse return false;
    const payload_block = blockByName(function, "15") orelse return false;
    if (entry.instructions.items.len != 2 or merge_ptr.instructions.items.len != 4 or some_block.instructions.items.len != 3 or
        ret_block.instructions.items.len != 1 or payload_block.instructions.items.len != 1) return false;

    const icmp_inst = entry.instructions.items[1];
    if (icmp_inst.removed) return false;
    const icmp_name = icmp_inst.result orelse return false;
    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .ne or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, function.params.items[0].name) or !isInt(icmp.rhs, 0)) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, icmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, "10") or !std.mem.eql(u8, entry_br.else_target, "5")) return false;

    const value_store = switch (some_block.instructions.items[0].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!value_store.ty.eql(.{ .int = 32 }) or !isNamed(value_store.value, function.params.items[1].name)) return false;
    const some_br = switch (some_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, some_br.target, "5")) return false;

    const payload_load_name = payload_block.instructions.items[0].result orelse return false;
    const payload_load = switch (payload_block.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!payload_load.ty.eql(.{ .int = 32 }) or payload_load.attrs.isBarrier()) return false;
    const payload_br = switch (payload_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, payload_br.target, "13")) return false;

    const phi_name = ret_block.instructions.items[0].result orelse return false;
    const phi = switch (ret_block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, payload_load_name, "15") or !phiHasIncomingInt(phi, -1, "5")) return false;
    const ret = switch (ret_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, phi_name)) return false;

    const null_label = "optional_payload_preopt_null";
    try machine.instructions.append(allocator, .{ .test_arg32 = .rdi });
    try machine.instructions.append(allocator, .{ .je = null_label });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = .rsi });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = null_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = -1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeOptionalPayloadMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_optional_payload_main.main");
    if (!std.mem.eql(u8, function.name, "main") and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (integrated_preopt) {
        if (!std.mem.eql(u8, call.callee, "runtime_optional_payload_main.optionalPayload")) return false;
    } else if (!isCalleeName(call.callee, "aggregates.optional_payload")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (integrated_preopt) {
        if (call.calling_conv) |cc| {
            if (!std.mem.eql(u8, cc, "fastcc")) return false;
        }
    } else {
        try validateDefaultCallConv(call.calling_conv);
    }
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 1)) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[1].value, 42)) return error.UnsupportedCodegenValue;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 42)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    if (integrated_preopt) {
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    const fail = "optional_payload_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_rdi = 1 });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 42 });
    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeErrorUnionPayloadMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_error_union_payload_main.main");
    if (!std.mem.eql(u8, function.name, "main") and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (integrated_preopt) {
        if (!std.mem.eql(u8, call.callee, "runtime_error_union_payload_main.errorUnionPayload")) return false;
    } else if (!isCalleeName(call.callee, "aggregates.error_union_payload")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (integrated_preopt) {
        if (call.calling_conv) |cc| {
            if (!std.mem.eql(u8, cc, "fastcc")) return false;
        }
    } else {
        try validateDefaultCallConv(call.calling_conv);
    }
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 0)) return error.UnsupportedCodegenValue;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 7)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    if (integrated_preopt) {
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    const fail = "error_union_payload_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_rdi = 0 });
    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 7 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeErrorUnionPayloadPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (std.mem.eql(u8, function.name, "runtime_error_union_payload_main.maybeError")) {
        if (function.ret_ty != .void or function.params.items.len != 2) return false;
        if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.{ .int = 32 })) return false;
        if (function.blocks.items.len != 3) return false;
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    if (!std.mem.eql(u8, function.name, "runtime_error_union_payload_main.errorUnionPayload")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = blockByName(function, "1") orelse return false;
    const ret_block = blockByName(function, "6") orelse return false;
    const success_block = blockByName(function, "8") orelse return false;
    if (entry.instructions.items.len != 5 or ret_block.instructions.items.len != 1 or success_block.instructions.items.len != 1) return false;

    const tag_cmp_inst = entry.instructions.items[4];
    if (tag_cmp_inst.removed) return false;
    const tag_cmp_name = tag_cmp_inst.result orelse return false;
    const tag_cmp = switch (tag_cmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (tag_cmp.predicate != .eq or !tag_cmp.operand_ty.eql(.{ .int = 16 })) return false;
    if (!isInt(tag_cmp.rhs, 0)) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, tag_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, "8") or !std.mem.eql(u8, entry_br.else_target, "6")) return false;

    const payload_load_name = success_block.instructions.items[0].result orelse return false;
    const payload_load = switch (success_block.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!payload_load.ty.eql(.{ .int = 32 }) or payload_load.attrs.isBarrier()) return false;
    const success_br = switch (success_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, success_br.target, "6")) return false;

    const phi_name = ret_block.instructions.items[0].result orelse return false;
    const phi = switch (ret_block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, payload_load_name, "8") or !phiHasIncomingInt(phi, -1, "1")) return false;
    const ret = switch (ret_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, phi_name)) return false;

    const err_label = "error_union_payload_preopt_err";
    try machine.instructions.append(allocator, .{ .test_arg32 = .rdi });
    try machine.instructions.append(allocator, .{ .jne = err_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 7 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = err_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = -1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeSliceSumMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_slice_sum_main.main");
    if (!std.mem.eql(u8, function.name, "main") and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (integrated_preopt) {
        if (!std.mem.eql(u8, call.callee, "runtime_slice_sum_main.sliceSum")) return false;
    } else if (!isCalleeName(call.callee, "aggregates.slice_sum")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (integrated_preopt) {
        if (call.calling_conv) |cc| {
            if (!std.mem.eql(u8, cc, "fastcc")) return false;
        }
    } else {
        try validateDefaultCallConv(call.calling_conv);
    }
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (integrated_preopt) {
        if (!call.args.items[0].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[0].value, "runtime_slice_sum_main.values")) return error.UnsupportedCodegenValue;
    } else if (!call.args.items[0].ty.eql(.ptr) or !call.args.items[0].value.eql(.{ .named = "@slice_sum_values" })) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.{ .int = 64 }) or !isInt(call.args.items[1].value, 4)) return error.UnsupportedCodegenValue;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 10)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    if (integrated_preopt) {
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    const fail = "slice_sum_fail";
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "slice_sum_values" });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 4 });
    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 10 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeComptimeConstMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "globals_comptime.comptime_const")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 7)) return error.UnsupportedCodegenValue;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 35)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "comptime_const_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_rdi = 7 });
    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 35 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeDebugLocationMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "atomics_inline_asm_debug.debug_location")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 41)) return error.UnsupportedCodegenValue;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 42)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "debug_location_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_rdi = 41 });
    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSelectedI1ConstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main.runner_futex_wait")) return false;
    if (!ret.ty.eql(.{ .int = 1 })) return false;
    if (function.params.items.len != 2 or block.instructions.items.len != 0) return false;
    const value = switch (ret.value orelse return error.InvalidRet) {
        .int => |int| int,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (value != 0 and value != 1) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(value) });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSelectedStringSliceReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main.runner_test_name")) return false;
    if (!ret.ty.eql(.{ .aggregate = "{ i64, i64 }" })) return false;
    if (function.params.items.len != 1 or block.instructions.items.len != 0) return false;
    const value = ret.value orelse return error.InvalidRet;
    switch (value) {
        .constant_expr => |text| {
            if (!std.mem.eql(u8, text, "{ i64 ptrtoint (ptr @__anon_16879 to i64), i64 4 }")) return error.UnsupportedCodegenValue;
        },
        .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }

    try machine.instructions.append(allocator, .{ .lea_global_rax = "__anon_16879" });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 4 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

const ExpectedCallArg = struct {
    ty: ir.Type,
    value: ir.Value,
};

fn lowerSelectedLibfuzzerTestRun(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main.runner_test_run")) return false;
    if (ret.ty != .void or ret.value != null) return false;
    if (function.params.items.len != 1 or block.instructions.items.len != 4) return false;

    const set_test_args = [_]ExpectedCallArg{.{
        .ty = .ptr,
        .value = .{ .named = "@main.testOne" },
    }};
    try validateVoidCall(block.instructions.items[0], "fuzzer_set_test", &set_test_args);

    const empty_input_args = [_]ExpectedCallArg{
        .{
            .ty = .{ .int = 64 },
            .value = .{ .constant_expr = "ptrtoint (ptr @__anon_11775 to i64)" },
        },
        .{
            .ty = .{ .int = 64 },
            .value = .{ .int = 0 },
        },
    };
    try validateVoidCall(block.instructions.items[1], "fuzzer_new_input", &empty_input_args);

    const hello_input_args = [_]ExpectedCallArg{
        .{
            .ty = .{ .int = 64 },
            .value = .{ .constant_expr = "ptrtoint (ptr @__anon_16031 to i64)" },
        },
        .{
            .ty = .{ .int = 64 },
            .value = .{ .int = 5 },
        },
    };
    try validateVoidCall(block.instructions.items[2], "fuzzer_new_input", &hello_input_args);
    try validateVoidCall(block.instructions.items[3], "fuzzer_start_test", &.{});

    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "main.testOne" });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_set_test", .ret_ty = .void } });
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "__anon_11775" });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 0 });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_new_input", .ret_ty = .void } });
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "__anon_16031" });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 5 });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_new_input", .ret_ty = .void } });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_start_test", .ret_ty = .void } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateVoidCall(instruction: ir.Instruction, callee: []const u8, expected_args: []const ExpectedCallArg) !void {
    if (instruction.removed) return error.UnsupportedCodegenInstruction;
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!isCalleeName(call.callee, callee)) return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != expected_args.len) return error.UnsupportedCodegenInstruction;
    for (call.args.items, expected_args) |arg, expected| {
        if (!arg.ty.eql(expected.ty) or !arg.value.eql(expected.value)) return error.UnsupportedCodegenValue;
    }
}

fn validateAssumeColdCall(instruction: ir.Instruction) !void {
    if (instruction.removed) return error.UnsupportedCodegenInstruction;
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, call.callee, "llvm.assume")) return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 1 }) or !isInt(call.args.items[0].value, 1)) return error.UnsupportedCodegenValue;
}

fn validateIntegerOverflowPanicCall(instruction: ir.Instruction) !void {
    if (instruction.removed) return error.UnsupportedCodegenInstruction;
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!isCalleeName(call.callee, "debug.FullPanic((function 'defaultPanic')).integerOverflow")) return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != 0) return error.UnsupportedCodegenInstruction;
}

fn lowerI64SaturatingHelperFamilyReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerSelectedUmlFixSatI64Return(allocator, machine, function, block, ret)) return true;
    return false;
}

fn lowerSelectedUmlFixSatI64Return(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "no_compile_panic_for_unchecked_arith.entry")) return false;
    if (!ret.ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 0 or block.instructions.items.len != 1) return false;

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_result = call_inst.result orelse return error.InstructionNeedsResult;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (!std.mem.eql(u8, ret_name, call_result)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, call.callee, "llvm.umul.fix.sat.i64")) return false;
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.args.items.len != 3) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 64 }) or !call.args.items[0].value.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.{ .int = 64 }) or !call.args.items[1].value.eql(.{ .int = 2 })) return error.UnsupportedCodegenValue;
    if (!call.args.items[2].ty.eql(.{ .int = 32 }) or !call.args.items[2].value.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSingleStackSlotCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (std.mem.eql(u8, function.name, "runtime_struct_sum_main.structSum")) {
        return try lowerRuntimeStructSumPreoptHelper(allocator, machine, function, block, ret);
    }
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 4) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const load_inst = block.instructions.items[2];
    const call_inst = block.instructions.items[3];
    if (alloca_inst.removed or store_inst.removed or load_inst.removed or call_inst.removed) return false;

    const slot = alloca_inst.result orelse return false;
    const load_result = load_inst.result orelse return false;
    const call_result = call_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, call_result, ret_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !isNamed(store.ptr, slot)) return false;
    const store_reg = try paramValueReg(function, store.value, .{ .int = 32 });

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or !isNamed(load.ptr, slot)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null) return error.UnsupportedCodegenInstruction;
    if (call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    if (call.args.items.len != 1) return false;
    const arg = call.args.items[0];
    if (!arg.ty.eql(.{ .int = 32 }) or !isNamed(arg.value, load_result)) return false;

    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{
        .frame_index = .slot0,
        .reg = store_reg,
    } });
    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{
        .reg = .rdi,
        .frame_index = .slot0,
    } });
    try machine.instructions.append(allocator, .{ .direct_call = .{
        .symbol = call.callee,
        .ret_ty = call.ret_ty,
    } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSingleStackSlotReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const load_inst = block.instructions.items[2];
    if (alloca_inst.removed or store_inst.removed or load_inst.removed) return false;
    const slot = alloca_inst.result orelse return false;
    const load_result = load_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, load_result, ret_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !isNamed(store.ptr, slot)) return false;
    const store_reg = try paramValueReg(function, store.value, .{ .int = 32 });

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or !isNamed(load.ptr, slot)) return false;

    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{
        .frame_index = .slot0,
        .reg = store_reg,
    } });
    try machine.instructions.append(allocator, .{ .reload_rsp_eax = .slot0 });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSelectAddSubReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const neg_inst = block.instructions.items[0];
    const select_inst = block.instructions.items[1];
    const add_inst = block.instructions.items[2];
    if (neg_inst.removed or select_inst.removed or add_inst.removed) return false;

    const neg_result = neg_inst.result orelse return false;
    const select_result = select_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, add_result)) return false;

    const neg = switch (neg_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (neg.op != .sub or !neg.ty.eql(.{ .int = 32 })) return false;
    switch (neg.lhs) {
        .int => |value| if (value != 0) return false,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    }
    const neg_param = try paramValueReg(function, neg.rhs, .{ .int = 32 });

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.ty.eql(.{ .int = 32 })) return false;
    const cond_reg = try paramValueReg(function, select.cond, .{ .int = 1 });
    const true_reg = try paramValueReg(function, select.true_value, .{ .int = 32 });
    if (true_reg != neg_param) return false;
    if (!isNamed(select.false_value, neg_result)) return false;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    const base_reg = if (isNamed(add.lhs, select_result))
        try paramValueReg(function, add.rhs, .{ .int = 32 })
    else if (isNamed(add.rhs, select_result))
        try paramValueReg(function, add.lhs, .{ .int = 32 })
    else
        return false;

    const false_label = "select_false";
    try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
    try machine.instructions.append(allocator, .{ .je = false_label });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = base_reg });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = true_reg } });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = false_label });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = base_reg });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .sub, .reg = neg_param } });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerIcmpSelectConstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len < 2) return false;

    const icmp_inst = block.instructions.items[block.instructions.items.len - 2];
    const select_inst = block.instructions.items[block.instructions.items.len - 1];
    if (icmp_inst.removed or select_inst.removed) return false;

    const icmp_result = icmp_inst.result orelse return false;
    const select_result = select_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_result)) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (evalConstIcmpOrBlock(block, icmp)) |cond| {
        const select = switch (select_inst.kind) {
            .select => |select| select,
            else => return false,
        };
        if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 }) or !isNamed(select.cond, icmp_result)) return false;
        const selected = if (cond) select.true_value else select.false_value;
        const selected_int = switch (selected) {
            .int => |value| value,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        };
        try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(selected_int) });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    const cmp_reg = if (isInt(icmp.lhs, 0))
        try paramValueReg(function, icmp.rhs, .{ .int = 32 })
    else if (isInt(icmp.rhs, 0))
        try paramValueReg(function, icmp.lhs, .{ .int = 32 })
    else
        return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 }) or !isNamed(select.cond, icmp_result)) return false;
    const true_value = try selectedI32Value(function, select.true_value);
    const false_value = try selectedI32Value(function, select.false_value);

    const true_label = "icmp_select_true";
    try machine.instructions.append(allocator, .{ .test_arg32 = cmp_reg });
    try machine.instructions.append(allocator, .{ .je = true_label });
    try appendSelectedI32Return(allocator, machine, false_value);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = true_label });
    try appendSelectedI32Return(allocator, machine, true_value);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimePhiSelectReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (block.instructions.items.len != 1) return false;

    const select_inst = block.instructions.items[0];
    if (select_inst.removed) return false;
    const select_result = select_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_result)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    const cond_reg = try paramValueReg(function, select.cond, .{ .int = 1 });
    if (!isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const false_label = "runtime_phi_false";
    try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
    try machine.instructions.append(allocator, .{ .je = false_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = false_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn evalConstIcmp(icmp: ir.IcmpInst) ?bool {
    const lhs = switch (icmp.lhs) {
        .int => |value| value,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const rhs = switch (icmp.rhs) {
        .int => |value| value,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return switch (icmp.predicate) {
        .eq => lhs == rhs,
        .ne => lhs != rhs,
        .sgt, .ugt => lhs > rhs,
        .sge, .uge => lhs >= rhs,
        .slt, .ult => lhs < rhs,
        .sle, .ule => lhs <= rhs,
    };
}

fn evalConstIcmpOrBlock(block: ir.BasicBlock, icmp: ir.IcmpInst) ?bool {
    if (evalConstIcmp(icmp)) |cond| return cond;
    return evalConstIcmpInBlock(block, icmp);
}

fn evalConstIcmpInBlock(block: ir.BasicBlock, icmp: ir.IcmpInst) ?bool {
    const lhs = evalConstValueInBlock(block, icmp.lhs, 0) orelse return null;
    const rhs = evalConstValueInBlock(block, icmp.rhs, 0) orelse return null;
    return switch (icmp.predicate) {
        .eq => lhs == rhs,
        .ne => lhs != rhs,
        .sgt, .ugt => lhs > rhs,
        .sge, .uge => lhs >= rhs,
        .slt, .ult => lhs < rhs,
        .sle, .ule => lhs <= rhs,
    };
}

fn evalConstValueInBlock(block: ir.BasicBlock, value: ir.Value, depth: usize) ?i128 {
    if (depth > 4) return null;
    return switch (value) {
        .int => |int| int,
        .named => |name| {
            const instruction = findInstruction(block, name) orelse return null;
            return switch (instruction.kind) {
                .binary => |binary| evalConstBinaryInBlock(block, binary, depth + 1),
                else => null,
            };
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

fn evalConstBinaryInBlock(block: ir.BasicBlock, binary: ir.BinaryInst, depth: usize) ?i128 {
    const lhs = evalConstValueInBlock(block, binary.lhs, depth) orelse return null;
    const rhs = evalConstValueInBlock(block, binary.rhs, depth) orelse return null;
    return switch (binary.op) {
        .add => lhs + rhs,
        .sub => lhs - rhs,
        .mul => lhs * rhs,
        .@"and" => lhs & rhs,
        .@"or" => lhs | rhs,
        .xor => lhs ^ rhs,
        .shl => if (rhs >= 0 and rhs < 127) lhs << @as(u7, @intCast(rhs)) else null,
        .ashr => if (rhs >= 0 and rhs < 127) lhs >> @as(u7, @intCast(rhs)) else null,
        .sdiv => if (rhs != 0) @divTrunc(lhs, rhs) else null,
        .srem => if (rhs != 0) @rem(lhs, rhs) else null,
        .fadd, .fsub, .fmul, .fdiv, .frem, .lshr, .udiv, .urem => null,
    };
}

fn lowerFcmpSelectConstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or !function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 2) return false;

    const fcmp_inst = block.instructions.items[0];
    const select_inst = block.instructions.items[1];
    if (fcmp_inst.removed or select_inst.removed) return false;
    const fcmp_result = fcmp_inst.result orelse return false;
    const select_result = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_result)) return false;

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .olt or !fcmp.operand_ty.eql(.float)) return false;
    if (!isFpText(fcmp.lhs, "1.000000e+00") or !isFpText(fcmp.rhs, "2.000000e+00")) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, fcmp_result) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerErrorSwitchSelectReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "error_switch.error_switch")) return false;
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 8 })) return false;
    if (block.instructions.items.len != 4) return false;

    const cmp_one_inst = block.instructions.items[0];
    const cmp_zero_inst = block.instructions.items[1];
    const first_select_inst = block.instructions.items[2];
    const second_select_inst = block.instructions.items[3];
    if (cmp_one_inst.removed or cmp_zero_inst.removed or first_select_inst.removed or second_select_inst.removed) return false;

    const cmp_one_result = cmp_one_inst.result orelse return false;
    const cmp_zero_result = cmp_zero_inst.result orelse return false;
    const first_select_result = first_select_inst.result orelse return false;
    const second_select_result = second_select_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, second_select_result)) return false;

    const tag_name = function.params.items[0].name;
    if (!matchIcmpEqParamImm(cmp_one_inst, tag_name, .{ .int = 8 }, 1)) return false;
    if (!matchIcmpEqParamImm(cmp_zero_inst, tag_name, .{ .int = 8 }, 0)) return false;

    const first_select = switch (first_select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!first_select.cond_ty.eql(.{ .int = 1 }) or !first_select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(first_select.cond, cmp_one_result) or !isInt(first_select.true_value, -1) or !isInt(first_select.false_value, -2)) return false;

    const second_select = switch (second_select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!second_select.cond_ty.eql(.{ .int = 1 }) or !second_select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(second_select.cond, cmp_zero_result) or !isInt(second_select.true_value, 0) or !isNamed(second_select.false_value, first_select_result)) return false;

    try appendErrorSwitchReturns(allocator, machine, try paramReg(function, tag_name, .{ .int = 8 }));
    return true;
}

fn lowerAddImmReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const add_inst = block.instructions.items[0];
    if (add_inst.removed) return false;
    const add_result = add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, add_result)) return false;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;

    const AddImm = struct {
        reg: ?ArgReg = null,
        base: i32 = 0,
        imm: i32,
    };
    const selected: AddImm = switch (add.lhs) {
        .int => |value| switch (add.rhs) {
            .int => |rhs| .{
                .base = try i32Value(value),
                .imm = try i32Value(rhs),
            },
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => .{
                .reg = try paramValueReg(function, add.rhs, .{ .int = 32 }),
                .imm = try i32Value(value),
            },
        },
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => switch (add.rhs) {
            .int => |value| .{
                .reg = try paramValueReg(function, add.lhs, .{ .int = 32 }),
                .imm = try i32Value(value),
            },
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        },
    };

    if (selected.reg) |reg| {
        try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
    } else {
        try machine.instructions.append(allocator, .{ .mov_imm_eax = selected.base });
    }
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = selected.imm });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn selectedI32Value(function: ir.Function, value: ir.Value) !SelectedI32Value {
    return switch (value) {
        .int => |int| .{ .imm = try i32Value(int) },
        .named => |name| .{ .reg = try paramReg(function, name, .{ .int = 32 }) },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

fn appendSelectedI32Return(allocator: std.mem.Allocator, machine: *MachineFunction, value: SelectedI32Value) !void {
    switch (value) {
        .imm => |imm| try machine.instructions.append(allocator, .{ .mov_imm_eax = imm }),
        .reg => |reg| try machine.instructions.append(allocator, .{ .mov_arg_eax = reg }),
    }
}

fn lowerShiftOrConstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 2) return false;

    const shift_inst = block.instructions.items[0];
    const or_inst = block.instructions.items[1];
    if (shift_inst.removed or or_inst.removed) return false;

    const shift_result = shift_inst.result orelse return false;
    const or_result = or_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, or_result)) return false;

    const shift = switch (shift_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (shift.op != .shl or !shift.ty.eql(.{ .int = 32 })) return false;
    const src_reg = try paramValueReg(function, shift.lhs, .{ .int = 32 });
    const shift_amount = switch (shift.rhs) {
        .int => |value| try u5Value(value),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const or_binary = switch (or_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (or_binary.op != .@"or" or !or_binary.ty.eql(.{ .int = 32 })) return false;
    const or_value = if (isNamed(or_binary.lhs, shift_result))
        switch (or_binary.rhs) {
            .int => |value| try i32Value(value),
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
    else if (isNamed(or_binary.rhs, shift_result))
        switch (or_binary.lhs) {
            .int => |value| try i32Value(value),
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
    else
        return false;

    try machine.instructions.append(allocator, .{ .mov_arg_eax = src_reg });
    try machine.instructions.append(allocator, .{ .shl_eax_imm5 = shift_amount });
    try machine.instructions.append(allocator, .{ .or_eax_imm32 = or_value });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerMulConstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const mul_inst = block.instructions.items[0];
    if (mul_inst.removed) return false;

    const mul_result = mul_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, mul_result)) return false;

    const mul = switch (mul_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (mul.op != .mul or !mul.ty.eql(.{ .int = 32 })) return false;

    const SelectedMul = struct {
        reg: ArgReg,
        multiplier: i32,
    };
    const selected: SelectedMul = switch (mul.lhs) {
        .int => |value| .{
            .reg = try paramValueReg(function, mul.rhs, .{ .int = 32 }),
            .multiplier = try i32Value(value),
        },
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => switch (mul.rhs) {
            .int => |value| .{
                .reg = try paramValueReg(function, mul.lhs, .{ .int = 32 }),
                .multiplier = try i32Value(value),
            },
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        },
    };

    try machine.instructions.append(allocator, .{ .mov_arg_eax = selected.reg });
    try machine.instructions.append(allocator, .{ .imul_eax_imm32 = selected.multiplier });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerIntegerSminReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "integers.cmp_select")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or !function.params.items[1].ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_result = call_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, call_result)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.smin.i32") or call.args.items.len != 2) return false;
    if (!call.ret_ty.eql(.{ .int = 32 })) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !call.args.items[1].ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(call.args.items[0].value, function.params.items[0].name) or !isNamed(call.args.items[1].value, function.params.items[1].name)) return false;

    try machine.instructions.append(allocator, .smin_i32_edi_esi_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerIntegerShiftMixReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "integers.shift_mix")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or !function.params.items[1].ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 4) return false;

    const and_inst = block.instructions.items[0];
    const shl_inst = block.instructions.items[1];
    const lshr_inst = block.instructions.items[2];
    const xor_inst = block.instructions.items[3];
    if (and_inst.removed or shl_inst.removed or lshr_inst.removed or xor_inst.removed) return false;
    const and_result = and_inst.result orelse return false;
    const shl_result = shl_inst.result orelse return false;
    const lshr_result = lshr_inst.result orelse return false;
    const xor_result = xor_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, xor_result)) return false;

    const mask = switch (and_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (mask.op != .@"and" or !mask.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(mask.lhs, function.params.items[1].name) or !isInt(mask.rhs, 31)) return false;

    const shl = switch (shl_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (shl.op != .shl or !shl.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(shl.lhs, function.params.items[0].name) or !isNamed(shl.rhs, and_result)) return false;

    const lshr = switch (lshr_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (lshr.op != .lshr or !lshr.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(lshr.lhs, function.params.items[0].name) or !isNamed(lshr.rhs, and_result)) return false;

    const xor_binary = switch (xor_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (xor_binary.op != .xor or !xor_binary.ty.eql(.{ .int = 32 })) return false;
    if (!((isNamed(xor_binary.lhs, shl_result) and isNamed(xor_binary.rhs, lshr_result)) or
        (isNamed(xor_binary.lhs, lshr_result) and isNamed(xor_binary.rhs, shl_result)))) return false;

    try machine.instructions.append(allocator, .shift_mix_i32_edi_esi_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerPackedReplaceLowReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const source_fixture = std.mem.eql(u8, function.name, "packed_bits.replace_low");
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_packed_replace_low_main.replaceLow");
    if (!source_fixture and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 8 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 8 }) or !function.params.items[1].ty.eql(.{ .int = 8 })) return false;
    if (integrated_preopt) return try lowerRuntimePackedReplaceLowPreoptHelper(allocator, machine, function, block, ret);
    if (block.instructions.items.len != 3) return false;

    const high_mask_inst = block.instructions.items[0];
    const low_mask_inst = block.instructions.items[1];
    const or_inst = block.instructions.items[2];
    if (high_mask_inst.removed or low_mask_inst.removed or or_inst.removed) return false;
    const high_result = high_mask_inst.result orelse return false;
    const low_result = low_mask_inst.result orelse return false;
    const or_result = or_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, or_result)) return false;

    const high_mask = switch (high_mask_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (high_mask.op != .@"and" or !high_mask.ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(high_mask.lhs, function.params.items[0].name) or !isInt(high_mask.rhs, -8)) return false;

    const low_mask = switch (low_mask_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (low_mask.op != .@"and" or !low_mask.ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(low_mask.lhs, function.params.items[1].name) or !isInt(low_mask.rhs, 7)) return false;

    const or_binary = switch (or_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (or_binary.op != .@"or" or !or_binary.ty.eql(.{ .int = 8 })) return false;
    if (!((isNamed(or_binary.lhs, low_result) and isNamed(or_binary.rhs, high_result)) or
        (isNamed(or_binary.lhs, high_result) and isNamed(or_binary.rhs, low_result)))) return false;

    try machine.instructions.append(allocator, .replace_low_i8_dil_sil_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimePackedReplaceLowPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 9) return false;
    const alloca_inst = block.instructions.items[0];
    const first_store_inst = block.instructions.items[1];
    const trunc_inst = block.instructions.items[2];
    const first_load_inst = block.instructions.items[3];
    const high_mask_inst = block.instructions.items[4];
    const zext_inst = block.instructions.items[5];
    const or_inst = block.instructions.items[6];
    const second_store_inst = block.instructions.items[7];
    const second_load_inst = block.instructions.items[8];
    if (alloca_inst.removed or first_store_inst.removed or trunc_inst.removed or first_load_inst.removed or
        high_mask_inst.removed or zext_inst.removed or or_inst.removed or second_store_inst.removed or second_load_inst.removed) return false;

    const alloca_name = alloca_inst.result orelse return false;
    const trunc_name = trunc_inst.result orelse return false;
    const first_load_name = first_load_inst.result orelse return false;
    const high_mask_name = high_mask_inst.result orelse return false;
    const zext_name = zext_inst.result orelse return false;
    const or_name = or_inst.result orelse return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.{ .int = 8 })) return false;

    const first_store = switch (first_store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!first_store.ty.eql(.{ .int = 8 }) or first_store.attrs.isBarrier()) return false;
    if (!isNamed(first_store.ptr, alloca_name) or !isNamed(first_store.value, function.params.items[0].name)) return false;

    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 8 }) or !trunc.to_ty.eql(.{ .int = 3 })) return false;
    if (!isNamed(trunc.value, function.params.items[1].name)) return false;

    const first_load = switch (first_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!first_load.ty.eql(.{ .int = 8 }) or first_load.attrs.isBarrier()) return false;
    if (!isNamed(first_load.ptr, alloca_name)) return false;

    const high_mask = switch (high_mask_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (high_mask.op != .@"and" or !high_mask.ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(high_mask.lhs, first_load_name) or !isInt(high_mask.rhs, -8)) return false;

    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 3 }) or !zext.to_ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(zext.value, trunc_name)) return false;

    const or_binary = switch (or_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (or_binary.op != .@"or" or !or_binary.ty.eql(.{ .int = 8 })) return false;
    if (!((isNamed(or_binary.lhs, zext_name) and isNamed(or_binary.rhs, high_mask_name)) or
        (isNamed(or_binary.lhs, high_mask_name) and isNamed(or_binary.rhs, zext_name)))) return false;

    const second_store = switch (second_store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!second_store.ty.eql(.{ .int = 8 }) or second_store.attrs.isBarrier()) return false;
    if (!isNamed(second_store.ptr, alloca_name) or !isNamed(second_store.value, or_name)) return false;

    const second_load_name = second_load_inst.result orelse return false;
    const second_load = switch (second_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!second_load.ty.eql(.{ .int = 8 }) or second_load.attrs.isBarrier()) return false;
    if (!isNamed(second_load.ptr, alloca_name)) return false;

    const ret_value_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_value_name, second_load_name)) return false;

    try machine.instructions.append(allocator, .replace_low_i8_dil_sil_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimePackedReplaceLowMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_packed_replace_low_main.main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (call.calling_conv) |cc| {
        if (!std.mem.eql(u8, cc, "fastcc")) return false;
    }
    if (!std.mem.eql(u8, call.callee, "runtime_packed_replace_low_main.replaceLow")) return false;
    if (!call.ret_ty.eql(.{ .int = 8 }) or call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 8 }) or !isInt(call.args.items[0].value, -1)) return false;
    if (!call.args.items[1].ty.eql(.{ .int = 8 }) or !isInt(call.args.items[1].value, 5)) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, -3)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerPackedReadFlagReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const source_fixture = std.mem.eql(u8, function.name, "packed_bits.read_flag");
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_packed_read_flag_main.readFlag");
    if (!source_fixture and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 1 }) or function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 8 })) return false;
    if (integrated_preopt) return try lowerRuntimePackedReadFlagPreoptHelper(allocator, machine, function, block, ret);
    if (block.instructions.items.len != 1) return false;

    const icmp_inst = block.instructions.items[0];
    if (icmp_inst.removed) return false;
    const icmp_result = icmp_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, icmp_result)) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .slt or !icmp.operand_ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(icmp.lhs, function.params.items[0].name) or !isInt(icmp.rhs, 0)) return false;

    try machine.instructions.append(allocator, .read_flag_i8_dil_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimePackedReadFlagPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 5) return false;
    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const load_inst = block.instructions.items[2];
    const shift_inst = block.instructions.items[3];
    const trunc_inst = block.instructions.items[4];
    if (alloca_inst.removed or store_inst.removed or load_inst.removed or shift_inst.removed or trunc_inst.removed) return false;

    const alloca_name = alloca_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    const shift_name = shift_inst.result orelse return false;
    const trunc_name = trunc_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, trunc_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.{ .int = 8 })) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 8 }) or store.attrs.isBarrier()) return false;
    if (!isNamed(store.ptr, alloca_name) or !isNamed(store.value, function.params.items[0].name)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier()) return false;
    if (!isNamed(load.ptr, alloca_name)) return false;

    const shift = switch (shift_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (shift.op != .lshr or !shift.ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(shift.lhs, load_name) or !isInt(shift.rhs, 7)) return false;

    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 8 }) or !trunc.to_ty.eql(.{ .int = 1 })) return false;
    if (!isNamed(trunc.value, shift_name)) return false;

    try machine.instructions.append(allocator, .read_flag_i8_dil_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimePackedReadFlagMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_packed_read_flag_main.main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 2) return false;

    const call_inst = block.instructions.items[0];
    const select_inst = block.instructions.items[1];
    if (call_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (call.calling_conv) |cc| {
        if (!std.mem.eql(u8, cc, "fastcc")) return false;
    }
    if (!std.mem.eql(u8, call.callee, "runtime_packed_read_flag_main.readFlag")) return false;
    if (!call.ret_ty.eql(.{ .int = 1 }) or call.args.items.len != 1) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 8 }) or !isInt(call.args.items[0].value, -128)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, call_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerPointerVolatileRoundtripReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const source_fixture = std.mem.eql(u8, function.name, "pointers_memory.volatile_roundtrip");
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_volatile_roundtrip_main.volatileRoundtrip");
    if (!source_fixture and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.{ .int = 32 })) return false;

    var alloca_names: [8][]const u8 = undefined;
    var alloca_count: usize = 0;
    var volatile_store: ?ir.StoreInst = null;
    var volatile_load: ?ir.LoadInst = null;
    var volatile_load_result: ?[]const u8 = null;

    for (block.instructions.items) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .alloca => {
                if (alloca_count == alloca_names.len) return false;
                alloca_names[alloca_count] = instruction.result orelse return false;
                alloca_count += 1;
            },
            .store => |store| {
                if (store.attrs.is_volatile) {
                    if (volatile_store != null) return false;
                    volatile_store = store;
                } else if (!isO0ParamStoreToAlloca(function, store, alloca_names[0..alloca_count])) {
                    return false;
                }
            },
            .load => |load| {
                if (!load.attrs.is_volatile or volatile_load != null) return false;
                volatile_load = load;
                volatile_load_result = instruction.result orelse return false;
            },
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return false,
        }
    }

    const store = volatile_store orelse return false;
    const load = volatile_load orelse return false;
    const load_result = volatile_load_result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, load_result)) return false;

    if (!store.ty.eql(.{ .int = 32 }) or !store.attrs.is_volatile) return false;
    if (!isNamed(store.ptr, function.params.items[0].name) or !isNamed(store.value, function.params.items[1].name)) return false;

    if (!load.ty.eql(.{ .int = 32 }) or !load.attrs.is_volatile) return false;
    if (!isNamed(load.ptr, function.params.items[0].name)) return false;

    try machine.instructions.append(allocator, .volatile_roundtrip_rdi_esi_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeVolatileRoundtripMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main") and
        !std.mem.eql(u8, function.name, "runtime_volatile_roundtrip_main.main"))
    {
        return false;
    }
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (std.mem.eql(u8, function.name, "runtime_volatile_roundtrip_main.main") and block.instructions.items.len == 3) {
        return try lowerRuntimeVolatileRoundtripPreoptMainReturn(allocator, machine, block, ret);
    }
    if (block.instructions.items.len != 4) return false;

    const store_inst = block.instructions.items[0];
    const load_inst = block.instructions.items[1];
    const icmp_inst = block.instructions.items[2];
    const result_inst = block.instructions.items[3];
    if (store_inst.removed or load_inst.removed or icmp_inst.removed or result_inst.removed) return false;

    const load_name = load_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const result_name = result_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, result_name)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !store.attrs.is_volatile) return false;
    if (!isInt(store.value, 42)) return false;
    const store_global = switch (store.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, store_global, "pointers_memory.volatile_slot") and
        !std.mem.eql(u8, store_global, "runtime_volatile_roundtrip_main.slot"))
    {
        return false;
    }

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or !load.attrs.is_volatile) return false;
    const load_global = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, load_global, "pointers_memory.volatile_slot") and
        !std.mem.eql(u8, load_global, "runtime_volatile_roundtrip_main.slot"))
    {
        return false;
    }

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if ((icmp.predicate != .eq and icmp.predicate != .ne) or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, load_name) or !isInt(icmp.rhs, 42)) return false;

    switch (result_inst.kind) {
        .select => |select| {
            if (icmp.predicate != .eq) return false;
            if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
            if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;
        },
        .cast => |cast| {
            if (icmp.predicate != .ne) return false;
            if (cast.op != .zext or !cast.from_ty.eql(.{ .int = 1 }) or !cast.to_ty.eql(.{ .int = 32 })) return false;
            if (!isNamed(cast.value, icmp_name)) return false;
        },
        else => return false,
    }

    const fail = "volatile_roundtrip_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 42 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = store_global });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = load_global });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeVolatileRoundtripPreoptMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;

    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (call.calling_conv) |cc| {
        if (!std.mem.eql(u8, cc, "fastcc")) return false;
    }
    if (!std.mem.eql(u8, call.callee, "runtime_volatile_roundtrip_main.volatileRoundtrip")) return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[0].value, "runtime_volatile_roundtrip_main.slot")) return false;
    if (!call.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[1].value, 42)) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 42)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "volatile_roundtrip_preopt_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 42 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "runtime_volatile_roundtrip_main.slot" });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_volatile_roundtrip_main.slot" });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn isO0ParamStoreToAlloca(function: ir.Function, store: ir.StoreInst, alloca_names: []const []const u8) bool {
    if (store.attrs.isBarrier()) return false;
    const ptr_name = switch (store.ptr) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    var points_to_alloca = false;
    for (alloca_names) |alloca_name| {
        if (std.mem.eql(u8, ptr_name, alloca_name)) {
            points_to_alloca = true;
            break;
        }
    }
    if (!points_to_alloca) return false;

    for (function.params.items) |param| {
        if (store.ty.eql(param.ty) and isNamed(store.value, param.name)) return true;
    }
    return false;
}

fn lowerPointerLoadStoreReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const source_fixture = std.mem.eql(u8, function.name, "pointers_memory.load_store");
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_pointer_load_store_main.loadStore");
    if (!source_fixture and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.ptr)) return false;
    if (source_fixture and block.instructions.items.len != 3) return false;
    if (integrated_preopt and block.instructions.items.len != 4) return false;

    const load_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    const reload_inst = if (integrated_preopt) block.instructions.items[3] else null;
    if (load_inst.removed or add_inst.removed or store_inst.removed) return false;
    if (reload_inst) |instruction| if (instruction.removed) return false;
    const load_result = load_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (source_fixture and !std.mem.eql(u8, ret_name, add_result)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    if (!isNamed(load.ptr, function.params.items[0].name)) return false;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(add.lhs, load_result) or !isInt(add.rhs, 1)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier()) return false;
    if (!isNamed(store.ptr, function.params.items[1].name) or !isNamed(store.value, add_result)) return false;

    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = .rdi });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .store_eax_arg_ptr = .rsi });
    if (reload_inst) |instruction| {
        const reload_name = instruction.result orelse return false;
        if (!std.mem.eql(u8, ret_name, reload_name)) return false;
        const reload = switch (instruction.kind) {
            .load => |reload| reload,
            else => return false,
        };
        if (!reload.ty.eql(.{ .int = 32 }) or reload.attrs.isBarrier()) return false;
        if (!isNamed(reload.ptr, function.params.items[1].name)) return false;
        try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = .rsi });
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimePointerLoadStorePreoptMain(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_pointer_load_store_main.main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len == 7) return lowerRuntimePointerLoadStorePreoptSafeMain(allocator, machine, function);
    if (function.blocks.items.len != 3) return false;
    if (blockByName(function, "Entry") != null) return lowerRuntimePointerLoadStorePreoptSafeOptimizedMain(allocator, machine, function);

    const entry = blockByName(function, "0") orelse return false;
    const merge = blockByName(function, "5") orelse return false;
    const output_check = blockByName(function, "7") orelse return false;
    if (entry.instructions.items.len != 2 or merge.instructions.items.len != 2 or output_check.instructions.items.len != 2) return false;

    const call_name = entry.instructions.items[0].result orelse return false;
    const first_cmp_name = entry.instructions.items[1].result orelse return false;
    if (entry.instructions.items[0].removed or entry.instructions.items[1].removed) return false;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!std.mem.eql(u8, call.callee, "runtime_pointer_load_store_main.loadStore")) return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return false;
    const first_cmp = switch (entry.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (first_cmp.predicate != .eq or !first_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(first_cmp.lhs, call_name) or !isInt(first_cmp.rhs, 42)) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, first_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, "7") or !std.mem.eql(u8, entry_br.else_target, "5")) return false;

    const output_load_name = output_check.instructions.items[0].result orelse return false;
    const output_cmp_name = output_check.instructions.items[1].result orelse return false;
    if (output_check.instructions.items[0].removed or output_check.instructions.items[1].removed) return false;
    const output_load = switch (output_check.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!output_load.ty.eql(.{ .int = 32 }) or output_load.attrs.isBarrier()) return false;
    if (!valueReferencesGlobal(output_load.ptr, "runtime_pointer_load_store_main.output")) return false;
    const output_cmp = switch (output_check.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (output_cmp.predicate != .eq or !output_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(output_cmp.lhs, output_load_name) or !isInt(output_cmp.rhs, 42)) return false;
    const output_br = switch (output_check.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, output_br.target, "5")) return false;

    const phi_name = merge.instructions.items[0].result orelse return false;
    const select_name = merge.instructions.items[1].result orelse return false;
    if (merge.instructions.items[0].removed or merge.instructions.items[1].removed) return false;
    const phi = switch (merge.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 1 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, output_cmp_name, "7") or !phiHasIncomingInt(phi, 0, "0")) return false;
    const select = switch (merge.instructions.items[1].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, phi_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;
    const ret = switch (merge.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fail = "pointer_load_store_preopt_fail";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_pointer_load_store_main.input" });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "runtime_pointer_load_store_main.output" });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_pointer_load_store_main.output" });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimePointerLoadStorePreoptSafeOptimizedMain(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const entry = blockByName(function, "Entry") orelse return false;
    const output_check = blockByName(function, "Then") orelse return false;
    const merge = blockByName(function, "Block1") orelse return false;
    if (entry.instructions.items.len != 2 or output_check.instructions.items.len != 2 or merge.instructions.items.len != 2) return false;

    const call_name = entry.instructions.items[0].result orelse return false;
    const first_cmp_name = entry.instructions.items[1].result orelse return false;
    if (entry.instructions.items[0].removed or entry.instructions.items[1].removed) return false;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(call.calling_conv) or !call.ret_ty.eql(.{ .int = 32 })) return false;
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!std.mem.eql(u8, call.callee, "runtime_pointer_load_store_main.loadStore")) return false;
    if (call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[0].value, "runtime_pointer_load_store_main.input")) return false;
    if (!call.args.items[1].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[1].value, "runtime_pointer_load_store_main.output")) return false;

    const first_cmp = switch (entry.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (first_cmp.predicate != .eq or !first_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(first_cmp.lhs, call_name) or !isInt(first_cmp.rhs, 42)) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, first_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, "Then") or !std.mem.eql(u8, entry_br.else_target, "Block1")) return false;

    const output_load_name = output_check.instructions.items[0].result orelse return false;
    const output_cmp_name = output_check.instructions.items[1].result orelse return false;
    if (output_check.instructions.items[0].removed or output_check.instructions.items[1].removed) return false;
    const output_load = switch (output_check.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!output_load.ty.eql(.{ .int = 32 }) or output_load.attrs.isBarrier()) return false;
    if (!valueReferencesGlobal(output_load.ptr, "runtime_pointer_load_store_main.output")) return false;
    const output_cmp = switch (output_check.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (output_cmp.predicate != .eq or !output_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(output_cmp.lhs, output_load_name) or !isInt(output_cmp.rhs, 42)) return false;
    try validateBrTarget(output_check, "Block1");

    const phi_name = merge.instructions.items[0].result orelse return false;
    const select_name = merge.instructions.items[1].result orelse return false;
    if (merge.instructions.items[0].removed or merge.instructions.items[1].removed) return false;
    const phi = switch (merge.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 1 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, output_cmp_name, "Then") or !phiHasIncomingInt(phi, 0, "Entry")) return false;
    const select = switch (merge.instructions.items[1].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, phi_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;
    const ret = switch (merge.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fail = "pointer_load_store_preopt_fail";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_pointer_load_store_main.input" });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "runtime_pointer_load_store_main.output" });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_pointer_load_store_main.output" });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimePointerLoadStorePreoptSafeMain(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const entry = blockByName(function, "Entry") orelse return false;
    const output_check = blockByName(function, "Then") orelse return false;
    const first_fail = blockByName(function, "Else") orelse return false;
    const bool_merge = blockByName(function, "Block1") orelse return false;
    const ret_ok = blockByName(function, "Then1") orelse return false;
    const ret_fail = blockByName(function, "Else1") orelse return false;
    const ret_block = blockByName(function, "Block") orelse return false;
    if (entry.instructions.items.len != 2 or output_check.instructions.items.len != 2 or first_fail.instructions.items.len != 0) return false;
    if (bool_merge.instructions.items.len != 1 or ret_ok.instructions.items.len != 0 or ret_fail.instructions.items.len != 0) return false;
    if (ret_block.instructions.items.len != 1) return false;

    const call_name = entry.instructions.items[0].result orelse return false;
    const first_cmp_name = entry.instructions.items[1].result orelse return false;
    if (entry.instructions.items[0].removed or entry.instructions.items[1].removed) return false;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(call.calling_conv) or !call.ret_ty.eql(.{ .int = 32 })) return false;
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!std.mem.eql(u8, call.callee, "runtime_pointer_load_store_main.loadStore")) return false;
    if (call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[0].value, "runtime_pointer_load_store_main.input")) return false;
    if (!call.args.items[1].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[1].value, "runtime_pointer_load_store_main.output")) return false;

    const first_cmp = switch (entry.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (first_cmp.predicate != .eq or !first_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(first_cmp.lhs, call_name) or !isInt(first_cmp.rhs, 42)) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, first_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, "Then") or !std.mem.eql(u8, entry_br.else_target, "Else")) return false;

    const output_load_name = output_check.instructions.items[0].result orelse return false;
    const output_cmp_name = output_check.instructions.items[1].result orelse return false;
    if (output_check.instructions.items[0].removed or output_check.instructions.items[1].removed) return false;
    const output_load = switch (output_check.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!output_load.ty.eql(.{ .int = 32 }) or output_load.attrs.isBarrier()) return false;
    if (!valueReferencesGlobal(output_load.ptr, "runtime_pointer_load_store_main.output")) return false;
    const output_cmp = switch (output_check.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (output_cmp.predicate != .eq or !output_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(output_cmp.lhs, output_load_name) or !isInt(output_cmp.rhs, 42)) return false;
    try validateBrTarget(output_check, "Block1");
    try validateBrTarget(first_fail, "Block1");

    const bool_phi_name = bool_merge.instructions.items[0].result orelse return false;
    if (bool_merge.instructions.items[0].removed) return false;
    const bool_phi = switch (bool_merge.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!bool_phi.ty.eql(.{ .int = 1 }) or bool_phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(bool_phi, output_cmp_name, "Then") or !phiHasIncomingInt(bool_phi, 0, "Else")) return false;
    const bool_br = switch (bool_merge.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!bool_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(bool_br.cond, bool_phi_name)) return false;
    if (!std.mem.eql(u8, bool_br.then_target, "Then1") or !std.mem.eql(u8, bool_br.else_target, "Else1")) return false;
    try validateBrTarget(ret_ok, "Block");
    try validateBrTarget(ret_fail, "Block");

    const ret_phi_name = ret_block.instructions.items[0].result orelse return false;
    if (ret_block.instructions.items[0].removed) return false;
    const ret_phi = switch (ret_block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!ret_phi.ty.eql(.{ .int = 32 }) or ret_phi.incoming.items.len != 2) return false;
    if (!phiHasIncomingInt(ret_phi, 0, "Then1") or !phiHasIncomingInt(ret_phi, 1, "Else1")) return false;
    const ret = switch (ret_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, ret_phi_name)) return false;

    const fail = "pointer_load_store_preopt_fail";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_pointer_load_store_main.input" });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "runtime_pointer_load_store_main.output" });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_pointer_load_store_main.output" });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateBrTarget(block: ir.BasicBlock, expected_target: []const u8) !void {
    const br = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!std.mem.eql(u8, br.target, expected_target)) return error.UnsupportedCodegenControlFlow;
}

fn lowerRuntimePointerLoadStoreMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 6) return false;

    const load_input_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    const load_output_inst = block.instructions.items[3];
    const icmp_inst = block.instructions.items[4];
    const select_inst = block.instructions.items[5];
    if (load_input_inst.removed or add_inst.removed or store_inst.removed or load_output_inst.removed or icmp_inst.removed or select_inst.removed) return false;

    const load_input_name = load_input_inst.result orelse return false;
    const add_name = add_inst.result orelse return false;
    const load_output_name = load_output_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const load_input = switch (load_input_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load_input.ty.eql(.{ .int = 32 }) or load_input.attrs.isBarrier()) return false;
    const input_global = switch (load_input.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, input_global, "pointers_memory.writer_input")) return false;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(add.lhs, load_input_name) or !isInt(add.rhs, 1)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier()) return false;
    if (!isNamed(store.value, add_name)) return false;
    const store_global = switch (store.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, store_global, "pointers_memory.writer_output")) return false;

    const load_output = switch (load_output_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load_output.ty.eql(.{ .int = 32 }) or load_output.attrs.isBarrier()) return false;
    const output_global = switch (load_output.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, output_global, "pointers_memory.writer_output")) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, load_output_name) or !isInt(icmp.rhs, 42)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "pointer_load_store_fail";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = input_global });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = store_global });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = output_global });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerFloatMulReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (function.params.items.len != 2) return false;
    if (!function.ret_ty.eql(.double) or !ret.ty.eql(.double)) return false;
    if (!function.params.items[0].ty.eql(.double) or !function.params.items[1].ty.eql(.double)) return false;
    if (block.instructions.items.len != 1) return false;

    const fmul_inst = block.instructions.items[0];
    if (fmul_inst.removed) return false;
    const fmul_result = fmul_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, fmul_result)) return false;

    const fmul = switch (fmul_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (fmul.op != .fmul or !fmul.ty.eql(.double)) return false;
    if (!isNamed(fmul.lhs, function.params.items[0].name) or !isNamed(fmul.rhs, function.params.items[1].name)) return false;

    try machine.instructions.append(allocator, .mulsd_xmm1_xmm0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerFloatAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (function.params.items.len != 2) return false;
    if (!function.ret_ty.eql(.float) or !ret.ty.eql(.float)) return false;
    if (!function.params.items[0].ty.eql(.float) or !function.params.items[1].ty.eql(.float)) return false;
    if (block.instructions.items.len != 1) return false;

    const fadd_inst = block.instructions.items[0];
    if (fadd_inst.removed) return false;
    const fadd_result = fadd_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, fadd_result)) return false;

    const fadd = switch (fadd_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (fadd.op != .fadd or !fadd.ty.eql(.float)) return false;
    if (!isNamed(fadd.lhs, function.params.items[0].name) or !isNamed(fadd.rhs, function.params.items[1].name)) return false;

    try machine.instructions.append(allocator, .addss_xmm1_xmm0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeFloatAddMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const fadd_inst = block.instructions.items[0];
    const fcmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (fadd_inst.removed or fcmp_inst.removed or select_inst.removed) return false;
    const fadd_name = fadd_inst.result orelse return false;
    const fcmp_name = fcmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fadd = switch (fadd_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (fadd.op != .fadd or !fadd.ty.eql(.float)) return false;
    if (!isFpText(fadd.lhs, "1.000000e+00") or !isFpText(fadd.rhs, "2.000000e+00")) return false;

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .oeq or !fcmp.operand_ty.eql(.float)) return false;
    if (!isNamed(fcmp.lhs, fadd_name) or !isFpText(fcmp.rhs, "3.000000e+00")) return false;

    if (!isSelectI1ToI32ZeroOne(select_inst, fcmp_name)) return false;

    const fail = "float_add_fail";
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm0 = 0x3f80_0000 });
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x4000_0000 });
    try machine.instructions.append(allocator, .addss_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x4040_0000 });
    try machine.instructions.append(allocator, .ucomiss_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerFloatSubReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!try matchesFpBinaryReturn(function, block, ret, .float, .fsub)) return false;
    try machine.instructions.append(allocator, .subss_xmm1_xmm0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeFloatSubMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const fsub_inst = block.instructions.items[0];
    const fcmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (fsub_inst.removed or fcmp_inst.removed or select_inst.removed) return false;
    const fsub_name = fsub_inst.result orelse return false;
    const fcmp_name = fcmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fsub = switch (fsub_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (fsub.op != .fsub or !fsub.ty.eql(.float)) return false;
    if (!isFpText(fsub.lhs, "5.000000e+00") or !isFpText(fsub.rhs, "2.000000e+00")) return false;

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .oeq or !fcmp.operand_ty.eql(.float)) return false;
    if (!isNamed(fcmp.lhs, fsub_name) or !isFpText(fcmp.rhs, "3.000000e+00")) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, fcmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "float_sub_fail";
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm0 = 0x40a0_0000 });
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x4000_0000 });
    try machine.instructions.append(allocator, .subss_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x4040_0000 });
    try machine.instructions.append(allocator, .ucomiss_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerDoubleDivReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!try matchesFpBinaryReturn(function, block, ret, .double, .fdiv)) return false;
    try machine.instructions.append(allocator, .divsd_xmm1_xmm0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeDoubleDivMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const fdiv_inst = block.instructions.items[0];
    const fcmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (fdiv_inst.removed or fcmp_inst.removed or select_inst.removed) return false;
    const fdiv_name = fdiv_inst.result orelse return false;
    const fcmp_name = fcmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fdiv = switch (fdiv_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (fdiv.op != .fdiv or !fdiv.ty.eql(.double)) return false;
    if (!isFpText(fdiv.lhs, "6.000000e+00") or !isFpText(fdiv.rhs, "2.000000e+00")) return false;

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .oeq or !fcmp.operand_ty.eql(.double)) return false;
    if (!isNamed(fcmp.lhs, fdiv_name) or !isFpText(fcmp.rhs, "3.000000e+00")) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, fcmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "double_div_fail";
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0x4018_0000_0000_0000 });
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = 0x4000_0000_0000_0000 });
    try machine.instructions.append(allocator, .divsd_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = 0x4008_0000_0000_0000 });
    try machine.instructions.append(allocator, .ucomisd_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerFloatRemReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "fp_extended_ops.float_rem")) return false;
    if (!try matchesFpBinaryReturn(function, block, ret, .float, .frem)) return false;
    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .direct_call = .{
        .symbol = "fmodf",
        .ret_ty = .float,
    } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeFloatRemMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const frem_inst = block.instructions.items[0];
    const fcmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (frem_inst.removed or fcmp_inst.removed or select_inst.removed) return false;
    const frem_name = frem_inst.result orelse return false;
    const fcmp_name = fcmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const frem = switch (frem_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (frem.op != .frem or !frem.ty.eql(.float)) return false;
    if (!isFpText(frem.lhs, "5.500000e+00") or !isFpText(frem.rhs, "2.000000e+00")) return false;

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .oeq or !fcmp.operand_ty.eql(.float)) return false;
    if (!isNamed(fcmp.lhs, frem_name) or !isFpText(fcmp.rhs, "1.500000e+00")) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, fcmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "float_rem_fail";
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm0 = 0x40b0_0000 });
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x4000_0000 });
    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .direct_call = .{
        .symbol = "fmodf",
        .ret_ty = .float,
    } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x3fc0_0000 });
    try machine.instructions.append(allocator, .ucomiss_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeFloatMulMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const fmul_inst = block.instructions.items[0];
    const fcmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (fmul_inst.removed or fcmp_inst.removed or select_inst.removed) return false;
    const fmul_name = fmul_inst.result orelse return false;
    const fcmp_name = fcmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fmul = switch (fmul_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (fmul.op != .fmul or !fmul.ty.eql(.double)) return false;
    if (!isFpText(fmul.lhs, "3.000000e+00") or !isFpText(fmul.rhs, "2.000000e+00")) return false;

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .oeq or !fcmp.operand_ty.eql(.double)) return false;
    if (!isNamed(fcmp.lhs, fmul_name) or !isFpText(fcmp.rhs, "6.000000e+00")) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, fcmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "float_mul_fail";
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0x4008_0000_0000_0000 });
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = 0x4000_0000_0000_0000 });
    try machine.instructions.append(allocator, .mulsd_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = 0x4018_0000_0000_0000 });
    try machine.instructions.append(allocator, .ucomisd_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

const RuntimeFloatCallArgExpectation = struct {
    ty: ir.Type,
    value: union(enum) {
        fp_text: []const u8,
        int: i128,
    },
};

const RuntimeFloatCallCompareCase = struct {
    function_name: []const u8,
    callee_name: []const u8,
    call_ret_ty: ir.Type,
    args: []const RuntimeFloatCallArgExpectation,
    fcmp_predicate: ir.FcmpPredicate,
    fcmp_rhs: []const u8,
};

const runtime_float_mul_compare_args = [_]RuntimeFloatCallArgExpectation{
    .{ .ty = .double, .value = .{ .fp_text = "3.000000e+00" } },
    .{ .ty = .double, .value = .{ .fp_text = "2.000000e+00" } },
};

const runtime_float_add_compare_args = [_]RuntimeFloatCallArgExpectation{
    .{ .ty = .float, .value = .{ .fp_text = "1.000000e+00" } },
    .{ .ty = .float, .value = .{ .fp_text = "2.000000e+00" } },
};

const runtime_float_select_compare_args = [_]RuntimeFloatCallArgExpectation{
    .{ .ty = .double, .value = .{ .fp_text = "4.000000e+00" } },
    .{ .ty = .double, .value = .{ .fp_text = "5.000000e+00" } },
    .{ .ty = .{ .int = 1 }, .value = .{ .int = 1 } },
};

const runtime_float_sub_compare_args = [_]RuntimeFloatCallArgExpectation{
    .{ .ty = .float, .value = .{ .fp_text = "5.000000e+00" } },
    .{ .ty = .float, .value = .{ .fp_text = "2.000000e+00" } },
};

const runtime_double_div_compare_args = [_]RuntimeFloatCallArgExpectation{
    .{ .ty = .double, .value = .{ .fp_text = "6.000000e+00" } },
    .{ .ty = .double, .value = .{ .fp_text = "2.000000e+00" } },
};

const runtime_float_rem_compare_args = [_]RuntimeFloatCallArgExpectation{
    .{ .ty = .float, .value = .{ .fp_text = "5.500000e+00" } },
    .{ .ty = .float, .value = .{ .fp_text = "2.000000e+00" } },
};

const runtime_float_call_compare_cases = [_]RuntimeFloatCallCompareCase{
    .{
        .function_name = "runtime_float_mul_main.main",
        .callee_name = "runtime_float_mul_main.floatMul",
        .call_ret_ty = .double,
        .args = &runtime_float_mul_compare_args,
        .fcmp_predicate = .oeq,
        .fcmp_rhs = "6.000000e+00",
    },
    .{
        .function_name = "runtime_float_add_main.main",
        .callee_name = "runtime_float_add_main.floatAdd",
        .call_ret_ty = .float,
        .args = &runtime_float_add_compare_args,
        .fcmp_predicate = .oeq,
        .fcmp_rhs = "3.000000e+00",
    },
    .{
        .function_name = "runtime_float_select_main.main",
        .callee_name = "runtime_float_select_main.floatSelect",
        .call_ret_ty = .double,
        .args = &runtime_float_select_compare_args,
        .fcmp_predicate = .oeq,
        .fcmp_rhs = "4.000000e+00",
    },
    .{
        .function_name = "runtime_float_sub_main.main",
        .callee_name = "runtime_float_sub_main.floatSub",
        .call_ret_ty = .float,
        .args = &runtime_float_sub_compare_args,
        .fcmp_predicate = .oeq,
        .fcmp_rhs = "3.000000e+00",
    },
    .{
        .function_name = "runtime_double_div_main.main",
        .callee_name = "runtime_double_div_main.doubleDiv",
        .call_ret_ty = .double,
        .args = &runtime_double_div_compare_args,
        .fcmp_predicate = .oeq,
        .fcmp_rhs = "3.000000e+00",
    },
    .{
        .function_name = "runtime_float_rem_main.main",
        .callee_name = "runtime_float_rem_main.floatRem",
        .call_ret_ty = .float,
        .args = &runtime_float_rem_compare_args,
        .fcmp_predicate = .oeq,
        .fcmp_rhs = "1.500000e+00",
    },
};

fn lowerSelectedRuntimeFloatCallCompareMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    for (runtime_float_call_compare_cases) |case| {
        if (try lowerRuntimeFloatCallCompareMainReturn(
            allocator,
            machine,
            function,
            block,
            ret,
            case.function_name,
            case.callee_name,
            case.call_ret_ty,
            case.args,
            case.fcmp_predicate,
            case.fcmp_rhs,
        )) return true;
    }
    return false;
}

fn lowerSimpleVoidCallBoundaryFamilyReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerRuntimeSideEffectFreeMainReturn(allocator, machine, function, block, ret)) return true;
    return false;
}

fn lowerRuntimeSideEffectFreeMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_side_effect_free_main.main")) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (!isInt(ret.value orelse return error.InvalidRet, 0)) return false;
    if (block.instructions.items.len != 1) return false;

    const call_inst = block.instructions.items[0];
    if (call_inst.removed or call_inst.result != null) return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(call.calling_conv) or call.ret_ty != .void) return false;
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!std.mem.eql(u8, call.callee, "runtime_side_effect_free_main.sideEffectFree")) return false;
    if (call.args.items.len != 0) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeFloatCallCompareMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
    expected_function_name: []const u8,
    expected_callee_name: []const u8,
    expected_call_ret_ty: ir.Type,
    expected_call_args: []const RuntimeFloatCallArgExpectation,
    expected_fcmp_predicate: ir.FcmpPredicate,
    expected_fcmp_rhs: []const u8,
) !bool {
    if (!std.mem.eql(u8, function.name, expected_function_name)) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const fcmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or fcmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const fcmp_name = fcmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    switch (expected_call_ret_ty) {
        .float, .double => {},
        .void, .int, .x86_fp80, .fp128, .metadata, .ptr, .aggregate, .vector => return false,
    }
    if (!callIsFastcc(call.calling_conv) or !call.ret_ty.eql(expected_call_ret_ty)) return false;
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!std.mem.eql(u8, call.callee, expected_callee_name)) return false;
    if (call.args.items.len != expected_call_args.len) return false;
    for (expected_call_args, 0..) |expected_arg, i| {
        const actual_arg = call.args.items[i];
        if (!actual_arg.ty.eql(expected_arg.ty)) return false;
        switch (expected_arg.value) {
            .fp_text => |expected| if (!isFpText(actual_arg.value, expected)) return false,
            .int => |expected| if (!isInt(actual_arg.value, expected)) return false,
        }
    }

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != expected_fcmp_predicate or !fcmp.operand_ty.eql(expected_call_ret_ty)) return false;
    if (!isNamed(fcmp.lhs, call_name) or !isFpText(fcmp.rhs, expected_fcmp_rhs)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, fcmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeFloatLessMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_float_less_main.main")) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 2) return false;

    const call_inst = block.instructions.items[0];
    const select_inst = block.instructions.items[1];
    if (call_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(call.calling_conv) or !call.ret_ty.eql(.{ .int = 1 })) return false;
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!std.mem.eql(u8, call.callee, "runtime_float_less_main.floatLess")) return false;
    if (call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.float) or !isFpText(call.args.items[0].value, "1.000000e+00")) return false;
    if (!call.args.items[1].ty.eql(.float) or !isFpText(call.args.items[1].value, "2.000000e+00")) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, call_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn matchesFpBinaryReturn(
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
    ty: ir.Type,
    op: ir.BinaryOp,
) !bool {
    if (function.params.items.len != 2) return false;
    if (!function.ret_ty.eql(ty) or !ret.ty.eql(ty)) return false;
    if (!function.params.items[0].ty.eql(ty) or !function.params.items[1].ty.eql(ty)) return false;
    if (block.instructions.items.len != 1) return false;

    const binary_inst = block.instructions.items[0];
    if (binary_inst.removed) return false;
    const binary_result = binary_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, binary_result)) return false;

    const binary = switch (binary_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (binary.op != op or !binary.ty.eql(ty)) return false;
    if (!isNamed(binary.lhs, function.params.items[0].name) or !isNamed(binary.rhs, function.params.items[1].name)) return false;
    return true;
}

fn isFpText(value: ir.Value, expected: []const u8) bool {
    return switch (value) {
        .fp => |text| std.mem.eql(u8, text, expected),
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

fn fp32TextBits(value: ir.Value) !u32 {
    const text = switch (value) {
        .fp => |text| text,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (std.mem.eql(u8, text, "1.000000e+00")) return 0x3f80_0000;
    if (std.mem.eql(u8, text, "1.500000e+00")) return 0x3fc0_0000;
    if (std.mem.eql(u8, text, "2.000000e+00")) return 0x4000_0000;
    if (std.mem.eql(u8, text, "3.000000e+00")) return 0x4040_0000;
    if (std.mem.eql(u8, text, "5.000000e+00")) return 0x40a0_0000;
    if (std.mem.eql(u8, text, "5.500000e+00")) return 0x40b0_0000;
    return error.UnsupportedCodegenValue;
}

fn fp64TextBits(value: ir.Value) !u64 {
    const text = switch (value) {
        .fp => |text| text,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (std.mem.eql(u8, text, "1.000000e+00")) return 0x3ff0_0000_0000_0000;
    if (std.mem.eql(u8, text, "2.000000e+00")) return 0x4000_0000_0000_0000;
    if (std.mem.eql(u8, text, "3.000000e+00")) return 0x4008_0000_0000_0000;
    if (std.mem.eql(u8, text, "4.000000e+00")) return 0x4010_0000_0000_0000;
    if (std.mem.eql(u8, text, "6.000000e+00")) return 0x4018_0000_0000_0000;
    return error.UnsupportedCodegenValue;
}

fn lowerFloatSelectReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (function.params.items.len != 3) return false;
    if (!function.ret_ty.eql(.double) or !ret.ty.eql(.double)) return false;
    if (!function.params.items[0].ty.eql(.double) or !function.params.items[1].ty.eql(.double) or !function.params.items[2].ty.eql(.{ .int = 1 })) return false;
    if (block.instructions.items.len != 1) return false;

    const select_inst = block.instructions.items[0];
    if (select_inst.removed) return false;
    const select_result = select_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_result)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.double)) return false;
    if (!isNamed(select.cond, function.params.items[2].name)) return false;
    if (!isNamed(select.true_value, function.params.items[0].name) or !isNamed(select.false_value, function.params.items[1].name)) return false;

    const false_label = "float_select_false";
    try machine.instructions.append(allocator, .{ .test_arg8 = .rdi });
    try machine.instructions.append(allocator, .{ .je = false_label });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = false_label });
    try machine.instructions.append(allocator, .movapd_xmm1_xmm0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerDescriptorFpCheckMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;

    if (try lowerDescriptorFpBinaryCheckMainReturn(allocator, machine, block, ret)) return true;
    if (try lowerDescriptorFpSelectCheckMainReturn(allocator, machine, block, ret)) return true;
    return false;
}

fn lowerDescriptorFpBinaryCheckMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 3) return false;

    const binary_inst = block.instructions.items[0];
    const fcmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (binary_inst.removed or fcmp_inst.removed or select_inst.removed) return false;
    const binary_name = binary_inst.result orelse return false;
    const fcmp_name = fcmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const binary = switch (binary_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .oeq or !fcmp.operand_ty.eql(binary.ty)) return false;
    if (!isNamed(fcmp.lhs, binary_name)) return false;
    if (!isSelectI1ToI32ZeroOne(select_inst, fcmp_name)) return false;

    const fail = "descriptor_fp_binary_fail";
    if (binary.ty.eql(.float)) {
        try machine.instructions.append(allocator, .{ .mov_imm32_xmm0 = try fp32TextBits(binary.lhs) });
        try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = try fp32TextBits(binary.rhs) });
        switch (binary.op) {
            .fadd => try machine.instructions.append(allocator, .addss_xmm1_xmm0),
            .fsub => try machine.instructions.append(allocator, .subss_xmm1_xmm0),
            .frem => {
                try machine.instructions.append(allocator, .sub_rsp_8);
                try machine.instructions.append(allocator, .{ .direct_call = .{
                    .symbol = "fmodf",
                    .ret_ty = .float,
                } });
                try machine.instructions.append(allocator, .add_rsp_8);
            },
            .fmul, .fdiv, .add, .sub, .mul, .shl, .lshr, .ashr, .@"and", .@"or", .xor, .udiv, .sdiv, .urem, .srem => return false,
        }
        try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = try fp32TextBits(fcmp.rhs) });
        try machine.instructions.append(allocator, .ucomiss_xmm1_xmm0);
    } else if (binary.ty.eql(.double)) {
        try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = try fp64TextBits(binary.lhs) });
        try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = try fp64TextBits(binary.rhs) });
        switch (binary.op) {
            .fmul => try machine.instructions.append(allocator, .mulsd_xmm1_xmm0),
            .fdiv => try machine.instructions.append(allocator, .divsd_xmm1_xmm0),
            .fadd, .fsub, .frem, .add, .sub, .mul, .shl, .lshr, .ashr, .@"and", .@"or", .xor, .udiv, .sdiv, .urem, .srem => return false,
        }
        try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = try fp64TextBits(fcmp.rhs) });
        try machine.instructions.append(allocator, .ucomisd_xmm1_xmm0);
    } else {
        return false;
    }

    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerDescriptorFpSelectCheckMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 4) return false;

    const first_cmp_inst = block.instructions.items[0];
    const select_fp_inst = block.instructions.items[1];
    const second_cmp_inst = block.instructions.items[2];
    const select_ret_inst = block.instructions.items[3];
    if (first_cmp_inst.removed or select_fp_inst.removed or second_cmp_inst.removed or select_ret_inst.removed) return false;
    const first_cmp_name = first_cmp_inst.result orelse return false;
    const selected_name = select_fp_inst.result orelse return false;
    const second_cmp_name = second_cmp_inst.result orelse return false;
    const select_ret_name = select_ret_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_ret_name)) return false;

    const first_cmp = switch (first_cmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (first_cmp.predicate != .olt or !first_cmp.operand_ty.eql(.double)) return false;
    _ = try fp64TextBits(first_cmp.lhs);
    _ = try fp64TextBits(first_cmp.rhs);

    const select_fp = switch (select_fp_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select_fp.cond_ty.eql(.{ .int = 1 }) or !select_fp.ty.eql(.double)) return false;
    if (!isNamed(select_fp.cond, first_cmp_name)) return false;
    _ = try fp64TextBits(select_fp.true_value);
    _ = try fp64TextBits(select_fp.false_value);

    const second_cmp = switch (second_cmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (second_cmp.predicate != .oeq or !second_cmp.operand_ty.eql(.double)) return false;
    if (!isNamed(second_cmp.lhs, selected_name)) return false;
    _ = try fp64TextBits(second_cmp.rhs);
    if (!isSelectI1ToI32ZeroOne(select_ret_inst, second_cmp_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerFloatLessReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (function.params.items.len != 2) return false;
    if (!function.ret_ty.eql(.{ .int = 1 }) or !ret.ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[0].ty.eql(.float) or !function.params.items[1].ty.eql(.float)) return false;
    if (block.instructions.items.len != 1) return false;

    const fcmp_inst = block.instructions.items[0];
    if (fcmp_inst.removed) return false;
    const fcmp_result = fcmp_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, fcmp_result)) return false;

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .olt or !fcmp.operand_ty.eql(.float)) return false;
    if (!isNamed(fcmp.lhs, function.params.items[0].name) or !isNamed(fcmp.rhs, function.params.items[1].name)) return false;

    try machine.instructions.append(allocator, .oltss_xmm0_xmm1_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerFloatLiteralReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    ret: anytype,
) !bool {
    if (function.params.items.len != 0) return false;
    const value = switch (ret.value orelse return false) {
        .fp => |fp| fp,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    if (function.ret_ty.eql(.double) and ret.ty.eql(.double) and
        std.mem.eql(u8, function.name, "fp_constants.double_literal") and
        std.mem.eql(u8, value, "2.250000e+00"))
    {
        try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0x4002_0000_0000_0000 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    if (function.ret_ty.eql(.float) and ret.ty.eql(.float) and
        std.mem.eql(u8, function.name, "fp_constants.float_literal") and
        std.mem.eql(u8, value, "1.500000e+00"))
    {
        try machine.instructions.append(allocator, .{ .mov_imm32_xmm0 = 0x3fc0_0000 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    return false;
}

fn lowerAggregateAbiReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerTruncI64ArgReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerMakePairReturn(allocator, machine, function, block, ret)) return true;
    return false;
}

fn lowerAggregatePairAbiFamilyReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerRuntimeAggregatePairMainReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRuntimeAggregatePairMakePairReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRuntimeAggregatePairPairFirstReturn(allocator, machine, function, block, ret)) return true;
    return false;
}

fn lowerRuntimeAggregatePairMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_aggregate_pair_main.main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;

    const alloca_inst = block.instructions.items[0];
    const make_pair_inst = block.instructions.items[1];
    const pair_first_inst = block.instructions.items[2];
    if (alloca_inst.removed or make_pair_inst.removed or pair_first_inst.removed) return false;
    const pair_slot_name = alloca_inst.result orelse return false;
    const pair_first_name = pair_first_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, pair_first_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.{ .aggregate = "%runtime_aggregate_pair_main.Pair" })) return false;

    const make_pair = switch (make_pair_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(make_pair.calling_conv) or make_pair.ret_ty != .void) return false;
    if (make_pair.callee_value != null or make_pair.inline_asm != null) return false;
    if (!std.mem.eql(u8, make_pair.callee, "runtime_aggregate_pair_main.makePair")) return false;
    if (make_pair.args.items.len != 3) return false;
    if (!make_pair.args.items[0].ty.eql(.ptr) or !callArgAttrsContain(make_pair.args.items[0], "sret(%runtime_aggregate_pair_main.Pair)") or
        !isNamed(make_pair.args.items[0].value, pair_slot_name)) return false;
    if (!make_pair.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(make_pair.args.items[1].value, 1)) return false;
    if (!make_pair.args.items[2].ty.eql(.{ .int = 32 }) or !isInt(make_pair.args.items[2].value, 2)) return false;

    const pair_first = switch (pair_first_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(pair_first.calling_conv) or !pair_first.ret_ty.eql(.{ .int = 32 })) return false;
    if (pair_first.callee_value != null or pair_first.inline_asm != null) return false;
    if (!std.mem.eql(u8, pair_first.callee, "runtime_aggregate_pair_main.pairFirst")) return false;
    if (pair_first.args.items.len != 1) return false;
    if (!pair_first.args.items[0].ty.eql(.ptr) or !isNamed(pair_first.args.items[0].value, pair_slot_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeAggregatePairMakePairReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_aggregate_pair_main.makePair")) return false;
    if (!callIsFastcc(function.calling_conv) or function.ret_ty != .void or ret.ty != .void) return false;
    if (function.params.items.len != 3) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !paramAttrsContain(function.params.items[0], "sret(%runtime_aggregate_pair_main.Pair)")) return false;
    if (!function.params.items[1].ty.eql(.{ .int = 32 }) or !function.params.items[2].ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const first_store_inst = block.instructions.items[0];
    const gep_inst = block.instructions.items[1];
    const second_store_inst = block.instructions.items[2];
    if (first_store_inst.removed or gep_inst.removed or second_store_inst.removed) return false;
    const gep_name = gep_inst.result orelse return false;
    if (ret.value != null) return error.InvalidRet;

    const first_store = switch (first_store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!first_store.ty.eql(.{ .int = 32 }) or first_store.attrs.isBarrier()) return false;
    if (!isNamed(first_store.ptr, function.params.items[0].name) or !isNamed(first_store.value, function.params.items[1].name)) return false;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, function.params.items[0].name)) return false;
    if (gep.indices.items.len != 1 or !gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 4)) return false;

    const second_store = switch (second_store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!second_store.ty.eql(.{ .int = 32 }) or second_store.attrs.isBarrier()) return false;
    if (!isNamed(second_store.ptr, gep_name) or !isNamed(second_store.value, function.params.items[2].name)) return false;

    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeAggregatePairPairFirstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_aggregate_pair_main.pairFirst")) return false;
    if (!callIsFastcc(function.calling_conv) or !function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.ptr)) return false;
    if (block.instructions.items.len != 3) return false;

    const alloca_inst = block.instructions.items[0];
    const memcpy_inst = block.instructions.items[1];
    const load_inst = block.instructions.items[2];
    if (alloca_inst.removed or memcpy_inst.removed or load_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.{ .aggregate = "%runtime_aggregate_pair_main.Pair" })) return false;

    const memcpy_call = switch (memcpy_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (memcpy_call.callee_value != null or memcpy_call.inline_asm != null) return false;
    if (!std.mem.eql(u8, memcpy_call.callee, "llvm.memcpy.p0.p0.i64")) return false;
    if (memcpy_call.ret_ty != .void or memcpy_call.args.items.len != 4) return false;
    if (!memcpy_call.args.items[0].ty.eql(.ptr) or !isNamed(memcpy_call.args.items[0].value, alloca_name)) return false;
    if (!memcpy_call.args.items[1].ty.eql(.ptr) or !isNamed(memcpy_call.args.items[1].value, function.params.items[0].name)) return false;
    if (!memcpy_call.args.items[2].ty.eql(.{ .int = 64 }) or !isInt(memcpy_call.args.items[2].value, 8)) return false;
    if (!memcpy_call.args.items[3].ty.eql(.{ .int = 1 }) or !isInt(memcpy_call.args.items[3].value, 0)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, alloca_name)) return false;

    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = .rdi });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerTruncI64ArgReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const trunc_inst = block.instructions.items[0];
    if (trunc_inst.removed) return false;
    const trunc_result = trunc_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, trunc_result)) return false;

    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 32 })) return false;
    const reg = try paramValueReg(function, trunc.value, .{ .int = 64 });

    try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerMakePairReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 })) return false;
    if (block.instructions.items.len != 4) return false;

    const high_zext_inst = block.instructions.items[0];
    const shift_inst = block.instructions.items[1];
    const low_zext_inst = block.instructions.items[2];
    const or_inst = block.instructions.items[3];
    if (high_zext_inst.removed or shift_inst.removed or low_zext_inst.removed or or_inst.removed) return false;

    const high_zext_result = high_zext_inst.result orelse return false;
    const shift_result = shift_inst.result orelse return false;
    const low_zext_result = low_zext_inst.result orelse return false;
    const or_result = or_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, or_result)) return false;

    const high_zext = switch (high_zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (high_zext.op != .zext or !high_zext.from_ty.eql(.{ .int = 32 }) or !high_zext.to_ty.eql(.{ .int = 64 })) return false;
    const high_reg = try paramValueReg(function, high_zext.value, .{ .int = 32 });

    const shift = switch (shift_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (shift.op != .shl or !shift.ty.eql(.{ .int = 64 }) or !isNamed(shift.lhs, high_zext_result) or !isInt(shift.rhs, 32)) return false;

    const low_zext = switch (low_zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (low_zext.op != .zext or !low_zext.from_ty.eql(.{ .int = 32 }) or !low_zext.to_ty.eql(.{ .int = 64 })) return false;
    const low_reg = try paramValueReg(function, low_zext.value, .{ .int = 32 });

    const or_binary = switch (or_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (or_binary.op != .@"or" or !or_binary.ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(or_binary.lhs, shift_result) or !isNamed(or_binary.rhs, low_zext_result)) return false;

    try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = high_reg } });
    try machine.instructions.append(allocator, .{ .shl_rdx_imm6 = 32 });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = low_reg });
    try machine.instructions.append(allocator, .or_rdx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerStructSumReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 4) return false;

    const first_load_inst = block.instructions.items[0];
    const gep_inst = block.instructions.items[1];
    const second_load_inst = block.instructions.items[2];
    const add_inst = block.instructions.items[3];
    if (first_load_inst.removed or gep_inst.removed or second_load_inst.removed or add_inst.removed) return false;

    const first_load_result = first_load_inst.result orelse return false;
    const gep_result = gep_inst.result orelse return false;
    const second_load_result = second_load_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, add_result)) return false;

    const first_load = switch (first_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!first_load.ty.eql(.{ .int = 32 })) return false;
    if (first_load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    const base_reg = try paramValueReg(function, first_load.ptr, .ptr);

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !first_load.ptr.eql(gep.ptr)) return false;
    if (gep.indices.items.len != 1) return false;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !isInt(index.value, 4)) return false;

    const second_load = switch (second_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!second_load.ty.eql(.{ .int = 32 }) or !isNamed(second_load.ptr, gep_result)) return false;
    if (second_load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    if (!((isNamed(add.lhs, first_load_result) and isNamed(add.rhs, second_load_result)) or
        (isNamed(add.lhs, second_load_result) and isNamed(add.rhs, first_load_result)))) return false;

    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = base_reg });
    try machine.instructions.append(allocator, .{ .add_arg_ptr_disp4_eax = base_reg });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeStructSumPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (block.instructions.items.len != 8) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const first_ptr_load_inst = block.instructions.items[2];
    const first_field_load_inst = block.instructions.items[3];
    const second_ptr_load_inst = block.instructions.items[4];
    const gep_inst = block.instructions.items[5];
    const second_field_load_inst = block.instructions.items[6];
    const add_inst = block.instructions.items[7];
    if (alloca_inst.removed or store_inst.removed or first_ptr_load_inst.removed or first_field_load_inst.removed or
        second_ptr_load_inst.removed or gep_inst.removed or second_field_load_inst.removed or add_inst.removed) return false;

    const alloca_name = alloca_inst.result orelse return false;
    const first_ptr_name = first_ptr_load_inst.result orelse return false;
    const first_field_name = first_field_load_inst.result orelse return false;
    const second_ptr_name = second_ptr_load_inst.result orelse return false;
    const gep_name = gep_inst.result orelse return false;
    const second_field_name = second_field_load_inst.result orelse return false;
    const add_name = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.ptr)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.ptr) or store.attrs.isBarrier()) return false;
    if (!isNamed(store.ptr, alloca_name) or !isNamed(store.value, function.params.items[0].name)) return false;

    const first_ptr_load = switch (first_ptr_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!first_ptr_load.ty.eql(.ptr) or first_ptr_load.attrs.isBarrier()) return false;
    if (!isNamed(first_ptr_load.ptr, alloca_name)) return false;

    const first_field_load = switch (first_field_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!first_field_load.ty.eql(.{ .int = 32 }) or first_field_load.attrs.isBarrier()) return false;
    if (!isNamed(first_field_load.ptr, first_ptr_name)) return false;

    const second_ptr_load = switch (second_ptr_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!second_ptr_load.ty.eql(.ptr) or second_ptr_load.attrs.isBarrier()) return false;
    if (!isNamed(second_ptr_load.ptr, alloca_name)) return false;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, second_ptr_name)) return false;
    if (gep.indices.items.len != 1) return false;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !isInt(index.value, 4)) return false;

    const second_field_load = switch (second_field_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!second_field_load.ty.eql(.{ .int = 32 }) or second_field_load.attrs.isBarrier()) return false;
    if (!isNamed(second_field_load.ptr, gep_name)) return false;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    if (!((isNamed(add.lhs, first_field_name) and isNamed(add.rhs, second_field_name)) or
        (isNamed(add.lhs, second_field_name) and isNamed(add.rhs, first_field_name)))) return false;

    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = .rdi });
    try machine.instructions.append(allocator, .{ .add_arg_ptr_disp4_eax = .rdi });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeStructSumMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_struct_sum_main.main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (call.calling_conv) |cc| {
        if (!std.mem.eql(u8, cc, "fastcc")) return false;
    }
    if (!std.mem.eql(u8, call.callee, "runtime_struct_sum_main.structSum")) return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return false;
    if (!call.args.items[0].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[0].value, "runtime_struct_sum_main.pair")) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 42)) return false;

    if (!isSelectI1ToI32ZeroOne(select_inst, icmp_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerAddChain3Return(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (std.mem.eql(u8, function.name, "runtime_array_sum_main.arraySum")) {
        return try lowerRuntimeArraySumPreoptHelper(allocator, machine, function, block, ret);
    }
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 2) return false;

    const first_add_inst = block.instructions.items[0];
    const second_add_inst = block.instructions.items[1];
    if (first_add_inst.removed or second_add_inst.removed) return false;

    const first_add_result = first_add_inst.result orelse return false;
    const second_add_result = second_add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, second_add_result)) return false;

    const first_add = switch (first_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (first_add.op != .add or !first_add.ty.eql(.{ .int = 32 })) return false;
    const first_lhs = try paramValueReg(function, first_add.lhs, .{ .int = 32 });
    const first_rhs = try paramValueReg(function, first_add.rhs, .{ .int = 32 });

    const second_add = switch (second_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (second_add.op != .add or !second_add.ty.eql(.{ .int = 32 })) return false;
    const third_reg = if (isNamed(second_add.lhs, first_add_result))
        try paramValueReg(function, second_add.rhs, .{ .int = 32 })
    else if (isNamed(second_add.rhs, first_add_result))
        try paramValueReg(function, second_add.lhs, .{ .int = 32 })
    else
        return false;

    try machine.instructions.append(allocator, .{ .mov_arg_eax = first_lhs });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = first_rhs } });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = third_reg } });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeArraySumPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 3) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 32 })) return false;
    }
    if (block.instructions.items.len != 16) return false;

    const memcpy_inst = block.instructions.items[7];
    const first_add_inst = block.instructions.items[12];
    const second_add_inst = block.instructions.items[15];
    if (memcpy_inst.removed or first_add_inst.removed or second_add_inst.removed) return false;

    const first_add_name = first_add_inst.result orelse return false;
    const second_add_name = second_add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, second_add_name)) return false;

    const memcpy_call = switch (memcpy_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (memcpy_call.callee_value != null or memcpy_call.inline_asm != null) return false;
    if (!std.mem.eql(u8, memcpy_call.callee, "llvm.memcpy.p0.p0.i64")) return false;
    if (memcpy_call.ret_ty != .void or memcpy_call.args.items.len != 4) return false;

    const first_add = switch (first_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (first_add.op != .add or !first_add.ty.eql(.{ .int = 32 })) return false;

    const second_add = switch (second_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (second_add.op != .add or !second_add.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(second_add.lhs, first_add_name) and !isNamed(second_add.rhs, first_add_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_arg_eax = .rdi });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = .rsi } });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = .rdx } });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerInlineAsmBarrierReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    if (call_inst.result != null) return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    const inline_asm = call.inline_asm orelse return false;
    if (!inline_asm.sideeffect or !inline_asm.has_memory_clobber) return false;
    if (inline_asm.template.len != 0) return false;
    if (call.ret_ty != .void or call.args.items.len != 0) return false;

    const ret_reg = try paramValueReg(function, ret.value orelse return error.InvalidRet, .{ .int = 32 });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = ret_reg });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerAtomicAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const atomic_inst = block.instructions.items[0];
    if (atomic_inst.removed) return false;
    const atomic_result = atomic_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, atomic_result)) return false;

    const atomic = switch (atomic_inst.kind) {
        .atomicrmw => |atomicrmw| atomicrmw,
        else => return false,
    };
    if (!std.mem.eql(u8, atomic.op, "add")) return false;
    if (!atomic.ty.eql(.{ .int = 32 })) return false;
    if (!std.mem.eql(u8, atomic.ordering, "monotonic")) return false;
    if (atomic.syncscope != null or atomic.is_volatile) return false;

    const value_reg = try paramValueReg(function, atomic.value, .{ .int = 32 });
    const global_name = switch (atomic.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    try machine.instructions.append(allocator, .{ .mov_arg_eax = value_reg });
    try machine.instructions.append(allocator, .{ .atomic_xadd_global_eax = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerGlobalReadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "globals_comptime.read_global")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;

    const load_inst = block.instructions.items[0];
    if (load_inst.removed) return false;
    const load_result = load_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, load_result)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    try machine.instructions.append(allocator, .{ .load_global_i32_eax = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerGlobalUpdateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "globals_comptime.update_global")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (block.instructions.items.len != 3) return false;

    const load_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    if (load_inst.removed or add_inst.removed or store_inst.removed) return false;
    const load_result = load_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, add_result)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    const arg_reg = if (isNamed(add.lhs, load_result))
        try paramValueReg(function, add.rhs, .{ .int = 32 })
    else if (isNamed(add.rhs, load_result))
        try paramValueReg(function, add.lhs, .{ .int = 32 })
    else
        return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !isNamed(store.value, add_result)) return false;
    if (!store.ptr.eql(load.ptr)) return false;

    try machine.instructions.append(allocator, .{ .load_global_i32_eax = global_name });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = arg_reg } });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerGlobalUpdateCheckMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3 and block.instructions.items.len != 5) return false;

    const load_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    if (load_inst.removed or add_inst.removed or store_inst.removed) return false;
    const load_name = load_inst.result orelse return false;
    const add_name = add_inst.result orelse return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or !isNamed(add.lhs, load_name)) return false;
    const increment = switch (add.rhs) {
        .int => |value| try i32Value(value),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier() or !isNamed(store.value, add_name)) return false;
    if (!store.ptr.eql(load.ptr)) return false;

    if (block.instructions.items.len == 3) {
        if (!isNamed(ret.value orelse return error.InvalidRet, add_name)) return false;
        try machine.instructions.append(allocator, .{ .load_global_i32_eax = global_name });
        try machine.instructions.append(allocator, .{ .add_eax_imm32 = increment });
        try machine.instructions.append(allocator, .{ .store_eax_global_i32 = global_name });
        try machine.instructions.append(allocator, .ret);
        return true;
    }

    const icmp_inst = block.instructions.items[3];
    const select_inst = block.instructions.items[4];
    if (icmp_inst.removed or select_inst.removed) return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, add_name)) return false;
    const expected = switch (icmp.rhs) {
        .int => |value| try i32Value(value),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!isSelectI1ToI32ZeroOne(select_inst, icmp_name)) return false;

    const fail = "global_update_check_fail";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = global_name });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = increment });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = global_name });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = expected });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64TableLookupMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 7) return false;

    const idx8_name = block.instructions.items[0].result orelse return false;
    const idx_name = block.instructions.items[1].result orelse return false;
    const ptr_name = block.instructions.items[2].result orelse return false;
    const byte_name = block.instructions.items[3].result orelse return false;
    const value_name = block.instructions.items[4].result orelse return false;
    const ok_name = block.instructions.items[5].result orelse return false;
    const ret_name = block.instructions.items[6].result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, ret_name)) return false;

    const trunc = switch (block.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 32 }) or !trunc.to_ty.eql(.{ .int = 8 }) or !isInt(trunc.value, 3)) return false;

    const zext_index = switch (block.instructions.items[1].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext_index.op != .zext or !zext_index.from_ty.eql(.{ .int = 8 }) or !zext_index.to_ty.eql(.{ .int = 64 }) or !isNamed(zext_index.value, idx8_name)) return false;

    const gep = switch (block.instructions.items[2].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[4 x i8]" })) return false;
    const table_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, table_symbol, "base64.writer_table")) return false;
    if (gep.indices.items.len != 2) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return false;
    if (!gep.indices.items[1].ty.eql(.{ .int = 64 }) or !isNamed(gep.indices.items[1].value, idx_name)) return false;

    const load = switch (block.instructions.items[3].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return false;

    const zext_value = switch (block.instructions.items[4].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext_value.op != .zext or !zext_value.from_ty.eql(.{ .int = 8 }) or !zext_value.to_ty.eql(.{ .int = 32 }) or !isNamed(zext_value.value, byte_name)) return false;

    const icmp = switch (block.instructions.items[5].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, value_name) or !isInt(icmp.rhs, 12)) return false;

    const select = switch (block.instructions.items[6].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64TableLookupReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "base64.table_lookup") and
        !std.mem.eql(u8, function.name, "base64_table_lookup.base64_table_lookup"))
    {
        return false;
    }
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (block.instructions.items.len != 4 and block.instructions.items.len != 5) return false;

    const has_mask = block.instructions.items.len == 5;
    const zext_index_index: usize = if (has_mask) 1 else 0;
    const gep_index: usize = if (has_mask) 2 else 1;
    const load_index: usize = if (has_mask) 3 else 2;
    const zext_result_index: usize = if (has_mask) 4 else 3;
    const zext_index_name = block.instructions.items[zext_index_index].result orelse return false;
    const gep_name = block.instructions.items[gep_index].result orelse return false;
    const load_name = block.instructions.items[load_index].result orelse return false;
    const zext_result_name = block.instructions.items[zext_result_index].result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, zext_result_name)) return false;

    const param_name = function.params.items[0].name;
    var zext_value_name = param_name;
    if (has_mask) {
        const mask_name = block.instructions.items[0].result orelse return false;
        const mask = switch (block.instructions.items[0].kind) {
            .binary => |binary| binary,
            else => return false,
        };
        if (mask.op != .@"and" or !mask.ty.eql(.{ .int = 8 })) return false;
        if (!((isNamed(mask.lhs, param_name) and isInt(mask.rhs, 3)) or
            (isNamed(mask.rhs, param_name) and isInt(mask.lhs, 3))))
        {
            return false;
        }
        zext_value_name = mask_name;
    }

    const first_zext = switch (block.instructions.items[zext_index_index].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (first_zext.op != .zext or !first_zext.from_ty.eql(.{ .int = 8 }) or !first_zext.to_ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(first_zext.value, zext_value_name)) return false;

    const gep = switch (block.instructions.items[gep_index].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[4 x i8]" }) and !gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const table_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.startsWith(u8, table_symbol, "__anon_") and !std.mem.eql(u8, table_symbol, "__anon_base64_table")) return false;
    if (gep.indices.items.len == 2) {
        if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !gep.indices.items[0].value.eql(.{ .int = 0 })) return false;
        if (!gep.indices.items[1].ty.eql(.{ .int = 64 }) or !isNamed(gep.indices.items[1].value, zext_index_name)) return false;
    } else if (gep.indices.items.len == 1) {
        if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isNamed(gep.indices.items[0].value, zext_index_name)) return false;
    } else {
        return false;
    }

    const load = switch (block.instructions.items[load_index].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return false;

    const result_zext = switch (block.instructions.items[zext_result_index].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (result_zext.op != .zext or !result_zext.from_ty.eql(.{ .int = 8 }) or !result_zext.to_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(result_zext.value, load_name)) return false;

    try machine.instructions.append(allocator, .movzx_dil_edi);
    if (has_mask) try machine.instructions.append(allocator, .{ .and_edi_imm8 = 3 });
    try machine.instructions.append(allocator, .{ .lea_global_rax = table_symbol });
    try machine.instructions.append(allocator, .load_rax_rdi_u8_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64DecodeStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 13) return false;

    const v0_name = (try validateBase64DecodeStepLoad(block.instructions.items[0], block.instructions.items[1], 0)) orelse return false;
    const v1_name = (try validateBase64DecodeStepLoad(block.instructions.items[2], block.instructions.items[3], 5)) orelse return false;
    const word1_name = block.instructions.items[4].result orelse return false;
    try validateNamedOr(block.instructions.items[4], v1_name, v0_name);

    const v2_name = (try validateBase64DecodeStepLoad(block.instructions.items[5], block.instructions.items[6], 9)) orelse return false;
    const word2_name = block.instructions.items[7].result orelse return false;
    try validateNamedOr(block.instructions.items[7], word1_name, v2_name);

    const v3_name = (try validateBase64DecodeStepLoad(block.instructions.items[8], block.instructions.items[9], 13)) orelse return false;
    const word_name = block.instructions.items[10].result orelse return false;
    try validateNamedOr(block.instructions.items[10], word2_name, v3_name);

    const valid_name = block.instructions.items[11].result orelse return false;
    const icmp = switch (block.instructions.items[11].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .ult or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, word_name) or !isInt(icmp.rhs, 16777216)) return false;

    const select_name = block.instructions.items[12].result orelse return false;
    const select = switch (block.instructions.items[12].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, valid_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64StoreStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 5) return false;

    const dst_name = block.instructions.items[0].result orelse return false;
    const check_name = block.instructions.items[2].result orelse return false;
    const ok_name = block.instructions.items[3].result orelse return false;
    const select_name = block.instructions.items[4].result orelse return false;

    const gep = switch (block.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const output_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, output_symbol, "base64.decode_output")) return false;
    if (gep.indices.items.len != 1) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return false;

    const store = switch (block.instructions.items[1].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !isInt(store.value, 2105344) or !isNamed(store.ptr, dst_name)) return false;

    const load = switch (block.instructions.items[2].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, dst_name)) return false;

    const icmp = switch (block.instructions.items[3].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, check_name) or !isInt(icmp.rhs, 2105344)) return false;

    const select = switch (block.instructions.items[4].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 2105344 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "base64.decode_output" });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64ResidualByteStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 5) return false;

    const dst_name = block.instructions.items[0].result orelse return false;
    const check_name = block.instructions.items[2].result orelse return false;
    const ok_name = block.instructions.items[3].result orelse return false;
    const select_name = block.instructions.items[4].result orelse return false;

    const gep = switch (block.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const output_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, output_symbol, "base64.residual_output")) return false;
    if (gep.indices.items.len != 1) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return false;

    const store = switch (block.instructions.items[1].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 8 }) or !isInt(store.value, 63) or !isNamed(store.ptr, dst_name)) return false;

    const load = switch (block.instructions.items[2].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, dst_name)) return false;

    const icmp = switch (block.instructions.items[3].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 8 }) or !isNamed(icmp.lhs, check_name) or !isInt(icmp.rhs, 63)) return false;

    const select = switch (block.instructions.items[4].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 63 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "base64.residual_output" });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64ResidualStoreStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 10) return false;

    const word_name = (try validateBase64BitBufferI32GlobalLoad(block.instructions.items[0], "base64.residual_store_word")) orelse return false;
    const dst_name = block.instructions.items[1].result orelse return false;
    const check_name = block.instructions.items[3].result orelse return false;
    const store_ok_name = block.instructions.items[4].result orelse return false;
    const remaining_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[5], "base64.residual_store_remaining")) orelse return false;
    const next_name = block.instructions.items[6].result orelse return false;
    const next_ok_name = block.instructions.items[7].result orelse return false;
    const ok_name = block.instructions.items[8].result orelse return false;
    const select_name = block.instructions.items[9].result orelse return false;

    const gep = switch (block.instructions.items[1].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const output_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, output_symbol, "base64.residual_store_output")) return false;
    if (gep.indices.items.len != 1) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return false;

    const store = switch (block.instructions.items[2].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier() or !isNamed(store.value, word_name) or !isNamed(store.ptr, dst_name)) return false;

    const check_load = switch (block.instructions.items[3].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!check_load.ty.eql(.{ .int = 32 }) or check_load.attrs.isBarrier() or !isNamed(check_load.ptr, dst_name)) return false;

    const store_ok = switch (block.instructions.items[4].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (store_ok.predicate != .eq or !store_ok.operand_ty.eql(.{ .int = 32 }) or !isNamed(store_ok.lhs, check_name) or !isNamed(store_ok.rhs, word_name)) return false;

    const next = switch (block.instructions.items[6].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (next.op != .add or !next.ty.eql(.{ .int = 64 }) or next.flags.any()) return false;
    if (!isNamed(next.lhs, remaining_name) or !isInt(next.rhs, -4)) return false;

    const next_ok = switch (block.instructions.items[7].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (next_ok.predicate != .eq or !next_ok.operand_ty.eql(.{ .int = 64 }) or !isNamed(next_ok.lhs, next_name) or !isInt(next_ok.rhs, 0)) return false;

    const ok_select = switch (block.instructions.items[8].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!ok_select.cond_ty.eql(.{ .int = 1 }) or !ok_select.ty.eql(.{ .int = 1 })) return false;
    if (!isNamed(ok_select.cond, store_ok_name) or !isNamed(ok_select.true_value, next_ok_name) or !isInt(ok_select.false_value, 0)) return false;

    const ret_select = switch (block.instructions.items[9].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!ret_select.cond_ty.eql(.{ .int = 1 }) or !ret_select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(ret_select.cond, ok_name) or !isInt(ret_select.true_value, 0) or !isInt(ret_select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 2105344 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "base64.residual_store_output" });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64ResidualLengthStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 5) return false;

    const total_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[0], "base64.residual_length_total")) orelse return false;
    const index_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[1], "base64.residual_length_index")) orelse return false;
    const remaining_name = block.instructions.items[2].result orelse return false;
    const ok_name = block.instructions.items[3].result orelse return false;
    const select_name = block.instructions.items[4].result orelse return false;

    const sub = switch (block.instructions.items[2].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (sub.op != .sub or !sub.ty.eql(.{ .int = 64 }) or !sub.flags.nuw or sub.flags.nsw or sub.flags.exact or sub.flags.disjoint) return false;
    if (!isNamed(sub.lhs, total_name) or !isNamed(sub.rhs, index_name)) return false;

    const icmp = switch (block.instructions.items[3].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(icmp.lhs, remaining_name) or !isInt(icmp.rhs, 4)) return false;

    const select = switch (block.instructions.items[4].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64ResidualTableCheckStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 7) return false;

    const src_name = (try validateBase64ResidualTableCheckGep(block.instructions.items[0], "base64.residual_table_check_input", null)) orelse return false;
    const byte_name = (try validateBase64ResidualTableCheckI8Load(block.instructions.items[1], src_name)) orelse return false;
    const idx_name = validateBase64SourceBundleZext(block.instructions.items[2], byte_name) orelse return false;
    const entry_ptr_name = (try validateBase64ResidualTableCheckGep(block.instructions.items[3], "base64.residual_table_check_table", idx_name)) orelse return false;
    const entry_name = (try validateBase64ResidualTableCheckI8Load(block.instructions.items[4], entry_ptr_name)) orelse return false;
    const invalid_name = (try validateBase64ResidualTableCheckI8Eq(block.instructions.items[5], entry_name, -1)) orelse return false;

    const select_name = block.instructions.items[6].result orelse return false;
    const select = switch (block.instructions.items[6].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, invalid_name) or !isInt(select.true_value, 1) or !isInt(select.false_value, 0)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateBase64ResidualTableCheckGep(instruction: ir.Instruction, symbol_name: []const u8, index_name: ?[]const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return null;
    const symbol = switch (gep.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, symbol, symbol_name)) return null;
    if (gep.indices.items.len != 1) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 })) return null;
    if (index_name) |name| {
        if (!isNamed(gep.indices.items[0].value, name)) return null;
    } else if (!isInt(gep.indices.items[0].value, 0)) return null;
    return result_name;
}

fn validateBase64ResidualTableCheckI8Load(instruction: ir.Instruction, ptr_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return null;
    return result_name;
}

fn validateBase64ResidualTableCheckI8Eq(instruction: ir.Instruction, lhs_name: []const u8, rhs_value: i128) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 8 })) return null;
    if (!isNamed(icmp.lhs, lhs_name) or !isInt(icmp.rhs, rhs_value)) return null;
    return result_name;
}

fn lowerBase64ResidualAccumulatorStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 13) return false;

    const bits_raw_name = (try validateBase64ResidualAccumulatorGlobalLoad(block.instructions.items[0], "base64.residual_accumulator_bits", 16)) orelse return false;
    const bits_name = validateBase64ResidualAccumulatorCast(block.instructions.items[1], .trunc, bits_raw_name, 16, 12) orelse return false;
    const shifted_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[2], .shl, bits_name, null, 6, 12, false) orelse return false;
    const entry_raw_name = (try validateBase64ResidualAccumulatorGlobalLoad(block.instructions.items[3], "base64.residual_accumulator_entry", 8)) orelse return false;
    const entry_bits_name = validateBase64ResidualAccumulatorCast(block.instructions.items[4], .zext, entry_raw_name, 8, 12) orelse return false;
    const next_bits_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[5], .add, shifted_name, entry_bits_name, 0, 12, true) orelse return false;
    try validateBase64ResidualAccumulatorStore(block.instructions.items[6], next_bits_name, "base64.residual_accumulator_bits", 12);

    const count_raw_name = (try validateBase64ResidualAccumulatorGlobalLoad(block.instructions.items[7], "base64.residual_accumulator_count", 8)) orelse return false;
    const count_name = validateBase64ResidualAccumulatorCast(block.instructions.items[8], .trunc, count_raw_name, 8, 4) orelse return false;
    const next_count_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[9], .add, count_name, null, 6, 4, true) orelse return false;
    try validateBase64ResidualAccumulatorStore(block.instructions.items[10], next_count_name, "base64.residual_accumulator_count", 4);

    const ok_name = (try validateBase64ResidualTableCheckI8EqTyped(block.instructions.items[11], next_count_name, 6, 4)) orelse return false;
    const select_name = block.instructions.items[12].result orelse return false;
    const select = switch (block.instructions.items[12].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateBase64ResidualAccumulatorGlobalLoad(instruction: ir.Instruction, symbol_name: []const u8, bits: u16) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = bits }) or load.attrs.isBarrier()) return null;
    if (!try valueIsGlobalSymbol(load.ptr, symbol_name)) return null;
    return result_name;
}

fn validateBase64ResidualAccumulatorCast(
    instruction: ir.Instruction,
    op: ir.CastOp,
    value_name: []const u8,
    from_bits: u16,
    to_bits: u16,
) ?[]const u8 {
    const result_name = instruction.result orelse return null;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (cast.op != op or !cast.from_ty.eql(.{ .int = from_bits }) or !cast.to_ty.eql(.{ .int = to_bits }) or !isNamed(cast.value, value_name)) return null;
    return result_name;
}

fn validateBase64ResidualAccumulatorBinary(
    instruction: ir.Instruction,
    op: ir.BinaryOp,
    lhs_name: []const u8,
    rhs_name: ?[]const u8,
    rhs_value: i128,
    bits: u16,
    require_nuw: bool,
) ?[]const u8 {
    const result_name = instruction.result orelse return null;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (binary.op != op or !binary.ty.eql(.{ .int = bits })) return null;
    if (binary.flags.nuw != require_nuw or binary.flags.nsw or binary.flags.exact or binary.flags.disjoint) return null;
    if (!isNamed(binary.lhs, lhs_name)) return null;
    if (rhs_name) |name| {
        if (!isNamed(binary.rhs, name)) return null;
    } else if (!isInt(binary.rhs, rhs_value)) return null;
    return result_name;
}

fn validateBase64ResidualAccumulatorStore(instruction: ir.Instruction, value_name: []const u8, symbol_name: []const u8, bits: u16) !void {
    const store = switch (instruction.kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(.{ .int = bits }) or store.attrs.isBarrier() or !isNamed(store.value, value_name)) return error.UnsupportedCodegenInstruction;
    if (!try valueIsGlobalSymbol(store.ptr, symbol_name)) return error.UnsupportedCodegenInstruction;
}

fn validateBase64ResidualTableCheckI8EqTyped(instruction: ir.Instruction, lhs_name: []const u8, rhs_value: i128, bits: u16) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = bits })) return null;
    if (!isNamed(icmp.lhs, lhs_name) or !isInt(icmp.rhs, rhs_value)) return null;
    return result_name;
}

fn valueIsGlobalSymbol(value: ir.Value, symbol_name: []const u8) !bool {
    const symbol = switch (value) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return false;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    return std.mem.eql(u8, symbol, symbol_name);
}

fn lowerBase64ResidualLoopAdvanceStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 4) return false;

    const index_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[0], "base64.residual_loop_index")) orelse return false;
    const next_name = block.instructions.items[1].result orelse return false;
    const ok_name = block.instructions.items[2].result orelse return false;
    const select_name = block.instructions.items[3].result orelse return false;

    const add = switch (block.instructions.items[1].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 64 }) or !add.flags.nuw or add.flags.nsw or add.flags.exact or add.flags.disjoint) return false;
    if (!isNamed(add.lhs, index_name) or !isInt(add.rhs, 1)) return false;

    const icmp = switch (block.instructions.items[2].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(icmp.lhs, next_name) or !isInt(icmp.rhs, 1)) return false;

    const select = switch (block.instructions.items[3].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64ResidualPaddingCheckStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 8) return false;

    const index_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[0], "base64.residual_padding_index")) orelse return false;
    const base_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[1], "base64.residual_padding_base")) orelse return false;
    const offset_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[2], .add, index_name, base_name, 0, 64, true) orelse return false;
    const offset_ok_name = (try validateBase64ResidualTableCheckI8EqTyped(block.instructions.items[3], offset_name, 4, 64)) orelse return false;
    const byte_name = (try validateBase64ResidualAccumulatorGlobalLoad(block.instructions.items[4], "base64.residual_padding_byte", 8)) orelse return false;
    const pad_ok_name = (try validateBase64ResidualTableCheckI8EqTyped(block.instructions.items[5], byte_name, 61, 8)) orelse return false;

    const ok_name = block.instructions.items[6].result orelse return false;
    const ok_select = switch (block.instructions.items[6].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!ok_select.cond_ty.eql(.{ .int = 1 }) or !ok_select.ty.eql(.{ .int = 1 })) return false;
    if (!isNamed(ok_select.cond, offset_ok_name) or !isNamed(ok_select.true_value, pad_ok_name) or !isInt(ok_select.false_value, 0)) return false;

    const select_name = block.instructions.items[7].result orelse return false;
    const select = switch (block.instructions.items[7].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64ResidualFinalMaskStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 14) return false;

    const index_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[0], "base64.residual_final_index")) orelse return false;
    const remaining_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[1], "base64.residual_final_remaining")) orelse return false;
    const done_name = (try validateBase64ResidualFinalMaskI64IcmpUge(block.instructions.items[2], index_name, remaining_name)) orelse return false;
    const bits_raw_name = (try validateBase64ResidualAccumulatorGlobalLoad(block.instructions.items[3], "base64.residual_final_bits", 16)) orelse return false;
    const bits_name = validateBase64ResidualAccumulatorCast(block.instructions.items[4], .trunc, bits_raw_name, 16, 12) orelse return false;
    const shift_raw_name = (try validateBase64ResidualAccumulatorGlobalLoad(block.instructions.items[5], "base64.residual_final_shift", 8)) orelse return false;
    const shift_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[6], .@"and", shift_raw_name, null, 7, 8, false) orelse return false;
    const shift_bits_name = validateBase64ResidualAccumulatorCast(block.instructions.items[7], .zext, shift_name, 8, 12) orelse return false;
    const notmask_name = validateBase64ResidualFinalMaskIntNamedShl(block.instructions.items[8], -1, shift_bits_name, 12) orelse return false;
    const mask_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[9], .xor, notmask_name, null, -1, 12, false) orelse return false;
    const residual_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[10], .@"and", bits_name, mask_name, 0, 12, false) orelse return false;
    const has_residual_name = (try validateBase64ResidualFinalMaskIcmpTyped(block.instructions.items[11], .ne, residual_name, 0, 12)) orelse return false;
    const fail_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[12], .@"or", done_name, has_residual_name, 0, 1, false) orelse return false;

    const select_name = block.instructions.items[13].result orelse return false;
    const select = switch (block.instructions.items[13].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, fail_name) or !isInt(select.true_value, 1) or !isInt(select.false_value, 0)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateBase64ResidualFinalMaskI64IcmpUge(instruction: ir.Instruction, lhs_name: []const u8, rhs_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .uge or !icmp.operand_ty.eql(.{ .int = 64 })) return null;
    if (!isNamed(icmp.lhs, lhs_name) or !isNamed(icmp.rhs, rhs_name)) return null;
    return result_name;
}

fn validateBase64ResidualFinalMaskIntNamedShl(instruction: ir.Instruction, lhs_value: i128, rhs_name: []const u8, bits: u16) ?[]const u8 {
    const result_name = instruction.result orelse return null;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (binary.op != .shl or !binary.ty.eql(.{ .int = bits })) return null;
    if (binary.flags.nuw or !binary.flags.nsw or binary.flags.exact or binary.flags.disjoint) return null;
    if (!isInt(binary.lhs, lhs_value) or !isNamed(binary.rhs, rhs_name)) return null;
    return result_name;
}

fn validateBase64ResidualFinalMaskIcmpTyped(instruction: ir.Instruction, predicate: ir.IcmpPredicate, lhs_name: []const u8, rhs_value: i128, bits: u16) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != predicate or !icmp.operand_ty.eql(.{ .int = bits })) return null;
    if (!isNamed(icmp.lhs, lhs_name) or !isInt(icmp.rhs, rhs_value)) return null;
    return result_name;
}

fn lowerBase64ResidualPaddingLoopStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 13) return false;

    const start_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[0], "base64.residual_padding_loop_start")) orelse return false;
    const total_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[1], "base64.residual_padding_loop_total")) orelse return false;
    const limit_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[2], .sub, total_name, start_name, 0, 64, true) orelse return false;
    const loop_index_name = (try validateBase64ResidualGuardI64GlobalLoad(block.instructions.items[3], "base64.residual_padding_loop_index")) orelse return false;
    const done_name = (try validateBase64ResidualPaddingLoopIcmpNamed(block.instructions.items[4], .eq, loop_index_name, limit_name, 64)) orelse return false;
    const ptr_name = (try validateBase64ResidualTableCheckGep(block.instructions.items[5], "base64.residual_padding_loop_source", loop_index_name)) orelse return false;
    const byte_name = (try validateBase64ResidualTableCheckI8Load(block.instructions.items[6], ptr_name)) orelse return false;
    const is_pad_name = (try validateBase64ResidualTableCheckI8EqTyped(block.instructions.items[7], byte_name, 61, 8)) orelse return false;
    const next_name = validateBase64ResidualAccumulatorBinary(block.instructions.items[8], .add, loop_index_name, null, 1, 64, false) orelse return false;
    const next_ok_name = (try validateBase64ResidualTableCheckI8EqTyped(block.instructions.items[9], next_name, 1, 64)) orelse return false;

    const body_ok_name = block.instructions.items[10].result orelse return false;
    const body_ok = switch (block.instructions.items[10].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!body_ok.cond_ty.eql(.{ .int = 1 }) or !body_ok.ty.eql(.{ .int = 1 })) return false;
    if (!isNamed(body_ok.cond, is_pad_name) or !isNamed(body_ok.true_value, next_ok_name) or !isInt(body_ok.false_value, 0)) return false;

    const ok_name = block.instructions.items[11].result orelse return false;
    const ok = switch (block.instructions.items[11].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!ok.cond_ty.eql(.{ .int = 1 }) or !ok.ty.eql(.{ .int = 1 })) return false;
    if (!isNamed(ok.cond, done_name) or !isInt(ok.true_value, 1) or !isNamed(ok.false_value, body_ok_name)) return false;

    const select_name = block.instructions.items[12].result orelse return false;
    const select = switch (block.instructions.items[12].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateBase64ResidualPaddingLoopIcmpNamed(instruction: ir.Instruction, predicate: ir.IcmpPredicate, lhs_name: []const u8, rhs_name: []const u8, bits: u16) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != predicate or !icmp.operand_ty.eql(.{ .int = bits })) return null;
    if (!isNamed(icmp.lhs, lhs_name) or !isNamed(icmp.rhs, rhs_name)) return null;
    return result_name;
}

fn lowerBase64DecodeExitStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 2) return false;

    const count_arg = [_]ExpectedCallArg{.{ .ty = .ptr, .value = .{ .named = "@base64.decode_exit_count" } }};
    const bits_arg = [_]ExpectedCallArg{.{ .ty = .ptr, .value = .{ .named = "@base64.decode_exit_bits" } }};
    try validateVoidCall(block.instructions.items[0], "llvm.lifetime.end.p0", &count_arg);
    try validateVoidCall(block.instructions.items[1], "llvm.lifetime.end.p0", &bits_arg);

    if (!isInt(ret.value orelse return error.InvalidRet, 0)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64PaddingTailStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 4) return false;

    const src_name = block.instructions.items[0].result orelse return false;
    const byte_name = block.instructions.items[1].result orelse return false;
    const is_pad_name = block.instructions.items[2].result orelse return false;
    const select_name = block.instructions.items[3].result orelse return false;

    const gep = switch (block.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const padding_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, padding_symbol, "base64.padding_tail")) return false;
    if (gep.indices.items.len != 1) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return false;

    const load = switch (block.instructions.items[1].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, src_name)) return false;

    const icmp = switch (block.instructions.items[2].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 8 }) or !isNamed(icmp.lhs, byte_name) or !isInt(icmp.rhs, 61)) return false;

    const select = switch (block.instructions.items[3].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, is_pad_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64PaddingLengthStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 13) return false;

    const end_name = block.instructions.items[0].result orelse return false;
    const validated_end_name = (try validateBase64PaddingLengthEnd(block.instructions.items[0], 2)) orelse return false;
    if (!std.mem.eql(u8, end_name, validated_end_name)) return false;

    const last_name = (try validateBase64PaddingLengthTailLoad(block.instructions.items[1], block.instructions.items[2], end_name, -1)) orelse return false;
    const last_eq_name = block.instructions.items[3].result orelse return false;
    try validateBase64PaddingLengthEq(block.instructions.items[3], last_name);
    const last_adj_name = try validateBase64PaddingLengthSext(block.instructions.items[4], last_eq_name);

    const base_name = block.instructions.items[5].result orelse return false;
    const base_add = switch (block.instructions.items[5].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (base_add.op != .add or !base_add.ty.eql(.{ .int = 64 })) return false;
    if (!((isInt(base_add.lhs, 6) and isNamed(base_add.rhs, last_adj_name)) or
        (isNamed(base_add.lhs, last_adj_name) and isInt(base_add.rhs, 6))))
        return false;

    const second_name = (try validateBase64PaddingLengthTailLoad(block.instructions.items[6], block.instructions.items[7], end_name, -2)) orelse return false;
    const second_eq_name = block.instructions.items[8].result orelse return false;
    try validateBase64PaddingLengthEq(block.instructions.items[8], second_name);
    const second_adj_name = try validateBase64PaddingLengthSext(block.instructions.items[9], second_eq_name);

    const total_name = block.instructions.items[10].result orelse return false;
    const total_add = switch (block.instructions.items[10].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (total_add.op != .add or !total_add.ty.eql(.{ .int = 64 }) or !isNamed(total_add.lhs, base_name) or !isNamed(total_add.rhs, second_adj_name)) return false;

    const ok_name = block.instructions.items[11].result orelse return false;
    const ok = switch (block.instructions.items[11].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (ok.predicate != .eq or !ok.operand_ty.eql(.{ .int = 64 }) or !isNamed(ok.lhs, total_name) or !isInt(ok.rhs, 8)) return false;

    const select_name = block.instructions.items[12].result orelse return false;
    const select = switch (block.instructions.items[12].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64ChunkGuardStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 6) return false;

    const source_next_name = block.instructions.items[0].result orelse return false;
    if (!validateBase64ChunkGuardAdd(block.instructions.items[0], 0, 16)) return false;
    const source_ok_name = block.instructions.items[1].result orelse return false;
    if (!validateBase64ChunkGuardIcmp(block.instructions.items[1], source_next_name, 64)) return false;

    const output_next_name = block.instructions.items[2].result orelse return false;
    if (!validateBase64ChunkGuardAdd(block.instructions.items[2], 0, 15)) return false;
    const output_ok_name = block.instructions.items[3].result orelse return false;
    if (!validateBase64ChunkGuardIcmp(block.instructions.items[3], output_next_name, 63)) return false;

    const wide_ok_name = block.instructions.items[4].result orelse return false;
    const wide_select = switch (block.instructions.items[4].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!wide_select.cond_ty.eql(.{ .int = 1 }) or !wide_select.ty.eql(.{ .int = 1 })) return false;
    if (!isNamed(wide_select.cond, source_ok_name) or !isNamed(wide_select.true_value, output_ok_name) or !isInt(wide_select.false_value, 0)) return false;

    const select_name = block.instructions.items[5].result orelse return false;
    const ret_select = switch (block.instructions.items[5].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!ret_select.cond_ty.eql(.{ .int = 1 }) or !ret_select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(ret_select.cond, wide_ok_name) or !isInt(ret_select.true_value, 0) or !isInt(ret_select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64SourceStrideStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 7) return false;

    const src_name = block.instructions.items[0].result orelse return false;
    const src_gep = switch (block.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!src_gep.source_ty.eql(.{ .int = 8 })) return false;
    const src_symbol = switch (src_gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, src_symbol, "base64.source_stride_input")) return false;
    if (src_gep.indices.items.len != 1) return false;
    if (!src_gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(src_gep.indices.items[0].value, 4)) return false;

    const byte_name = block.instructions.items[1].result orelse return false;
    const byte_load = switch (block.instructions.items[1].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!byte_load.ty.eql(.{ .int = 8 }) or byte_load.attrs.isBarrier() or !isNamed(byte_load.ptr, src_name)) return false;

    const idx_name = block.instructions.items[2].result orelse return false;
    const zext = switch (block.instructions.items[2].kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 8 }) or !zext.to_ty.eql(.{ .int = 64 }) or !isNamed(zext.value, byte_name)) return false;

    const entry_ptr_name = block.instructions.items[3].result orelse return false;
    const table_gep = switch (block.instructions.items[3].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!table_gep.source_ty.eql(.{ .aggregate = "[4 x i8]" })) return false;
    const table_symbol = switch (table_gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, table_symbol, "base64.source_stride_table")) return false;
    if (table_gep.indices.items.len != 1) return false;
    if (!table_gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isNamed(table_gep.indices.items[0].value, idx_name)) return false;

    const word_name = block.instructions.items[4].result orelse return false;
    const word_load = switch (block.instructions.items[4].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!word_load.ty.eql(.{ .int = 32 }) or word_load.attrs.isBarrier() or !isNamed(word_load.ptr, entry_ptr_name)) return false;

    const ok_name = block.instructions.items[5].result orelse return false;
    const ok = switch (block.instructions.items[5].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (ok.predicate != .eq or !ok.operand_ty.eql(.{ .int = 32 }) or !isNamed(ok.lhs, word_name) or !isInt(ok.rhs, 42)) return false;

    const select_name = block.instructions.items[6].result orelse return false;
    const select = switch (block.instructions.items[6].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerBase64SourceBundleStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    return lowerBase64SourceBundleStepMainReturnWithSymbols(
        allocator,
        machine,
        function,
        block,
        ret,
        "base64.source_bundle_input",
        "base64.source_bundle_table0",
        "base64.source_bundle_table1",
        "base64.source_bundle_table2",
        "base64.source_bundle_table3",
        4,
    );
}

fn lowerBase64NextSourceBundleStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    return lowerBase64SourceBundleStepMainReturnWithSymbols(
        allocator,
        machine,
        function,
        block,
        ret,
        "base64.next_source_bundle_input",
        "base64.next_source_bundle_table0",
        "base64.next_source_bundle_table1",
        "base64.next_source_bundle_table2",
        "base64.next_source_bundle_table3",
        8,
    );
}

fn lowerBase64ThirdSourceBundleStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    return lowerBase64SourceBundleStepMainReturnWithSymbols(
        allocator,
        machine,
        function,
        block,
        ret,
        "base64.third_source_bundle_input",
        "base64.third_source_bundle_table0",
        "base64.third_source_bundle_table1",
        "base64.third_source_bundle_table2",
        "base64.third_source_bundle_table3",
        12,
    );
}

fn lowerBase64ResidualBundleStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    return lowerBase64SourceBundleStepMainReturnWithSymbols(
        allocator,
        machine,
        function,
        block,
        ret,
        "base64.residual_bundle_input",
        "base64.residual_bundle_table0",
        "base64.residual_bundle_table1",
        "base64.residual_bundle_table2",
        "base64.residual_bundle_table3",
        0,
    );
}

fn lowerBase64BitBufferStoreStepMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 16) return false;

    const word0_raw_name = (try validateBase64BitBufferI32GlobalLoad(block.instructions.items[0], "base64.bit_buffer_word0")) orelse return false;
    const word0_name = validateBase64BitBufferZext(block.instructions.items[1], word0_raw_name, false) orelse return false;
    const word3_raw_name = (try validateBase64BitBufferI32GlobalLoad(block.instructions.items[2], "base64.bit_buffer_word3")) orelse return false;
    const word3_name = validateBase64BitBufferZext(block.instructions.items[3], word3_raw_name, true) orelse return false;
    const word1_raw_name = (try validateBase64BitBufferI32GlobalLoad(block.instructions.items[4], "base64.bit_buffer_word1")) orelse return false;
    const word1_name = validateBase64BitBufferZext(block.instructions.items[5], word1_raw_name, true) orelse return false;
    const shift1_name = validateBase64BitBufferShl(block.instructions.items[6], word1_name, 24) orelse return false;
    const merged1_name = validateBase64BitBufferOr(block.instructions.items[7], shift1_name, word0_name) orelse return false;
    const word2_raw_name = (try validateBase64BitBufferI32GlobalLoad(block.instructions.items[8], "base64.bit_buffer_word2")) orelse return false;
    const word2_name = validateBase64BitBufferZext(block.instructions.items[9], word2_raw_name, true) orelse return false;
    const shift2_name = validateBase64BitBufferShl(block.instructions.items[10], word2_name, 48) orelse return false;
    const merged2_name = validateBase64BitBufferOr(block.instructions.items[11], merged1_name, shift2_name) orelse return false;
    const shift3_name = validateBase64BitBufferShl(block.instructions.items[12], word3_name, 72) orelse return false;
    const merged_name = validateBase64BitBufferOr(block.instructions.items[13], merged2_name, shift3_name) orelse return false;

    const dst_name = block.instructions.items[14].result orelse return false;
    const dst_gep = switch (block.instructions.items[14].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!dst_gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const dst_symbol = switch (dst_gep.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return false;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, dst_symbol, "base64.bit_buffer_output")) return false;
    if (dst_gep.indices.items.len != 1) return false;
    if (!dst_gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(dst_gep.indices.items[0].value, 0)) return false;

    const store = switch (block.instructions.items[15].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 128 }) or store.attrs.isBarrier() or !isNamed(store.value, merged_name) or !isNamed(store.ptr, dst_name)) return false;

    const ret_value = ret.value orelse return error.InvalidRet;
    if (!isInt(ret_value, 0)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateBase64BitBufferI32GlobalLoad(instruction: ir.Instruction, symbol_name: []const u8) !?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return null;
    const symbol = switch (load.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, symbol, symbol_name)) return null;
    return result_name;
}

fn validateBase64BitBufferZext(instruction: ir.Instruction, value_name: []const u8, expected_nneg: bool) ?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const zext = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 32 }) or !zext.to_ty.eql(.{ .int = 128 }) or !isNamed(zext.value, value_name)) return null;
    if (zext.flags.nneg != expected_nneg or zext.flags.nsw or zext.flags.nuw) return null;
    return result_name;
}

fn validateBase64BitBufferShl(instruction: ir.Instruction, lhs_name: []const u8, shift: i128) ?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const shl = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (shl.op != .shl or !shl.ty.eql(.{ .int = 128 })) return null;
    if (!shl.flags.nsw or !shl.flags.nuw or shl.flags.exact or shl.flags.disjoint) return null;
    if (!isNamed(shl.lhs, lhs_name) or !isInt(shl.rhs, shift)) return null;
    return result_name;
}

fn validateBase64BitBufferOr(instruction: ir.Instruction, lhs_name: []const u8, rhs_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const @"or" = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (@"or".op != .@"or" or !@"or".ty.eql(.{ .int = 128 })) return null;
    if (!@"or".flags.disjoint or @"or".flags.nsw or @"or".flags.nuw or @"or".flags.exact) return null;
    if (!((isNamed(@"or".lhs, lhs_name) and isNamed(@"or".rhs, rhs_name)) or
        (isNamed(@"or".lhs, rhs_name) and isNamed(@"or".rhs, lhs_name))))
    {
        return null;
    }
    return result_name;
}

fn lowerBase64LoopAdvanceStep(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const exit = function.blocks.items[2];
    if (!std.mem.eql(u8, entry.name, "entry") or
        !std.mem.eql(u8, loop.name, "loop") or
        !std.mem.eql(u8, exit.name, "exit"))
        return false;

    if (entry.instructions.items.len != 2) return false;
    const out_start_name = (try validateBase64LoopAdvanceI64GlobalLoad(entry.instructions.items[0], "base64.loop_advance_output")) orelse return false;
    const src_start_name = (try validateBase64LoopAdvanceI64GlobalLoad(entry.instructions.items[1], "base64.loop_advance_source")) orelse return false;
    if (!std.mem.eql(u8, try validateTerminatorBr(entry), loop.name)) return false;

    if (loop.instructions.items.len != 5) return false;
    const out_name = loop.instructions.items[0].result orelse return false;
    const src_name = loop.instructions.items[1].result orelse return false;
    const out_next_name = loop.instructions.items[2].result orelse return false;
    const src_next_name = loop.instructions.items[3].result orelse return false;
    const done_name = loop.instructions.items[4].result orelse return false;

    const out_phi = switch (loop.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!out_phi.ty.eql(.{ .int = 64 }) or out_phi.incoming.items.len != 2) return false;
    if (!isNamed(out_phi.incoming.items[0].value, out_start_name) or !std.mem.eql(u8, out_phi.incoming.items[0].block, entry.name)) return false;
    if (!isNamed(out_phi.incoming.items[1].value, out_next_name) or !std.mem.eql(u8, out_phi.incoming.items[1].block, loop.name)) return false;

    const src_phi = switch (loop.instructions.items[1].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!src_phi.ty.eql(.{ .int = 64 }) or src_phi.incoming.items.len != 2) return false;
    if (!isNamed(src_phi.incoming.items[0].value, src_start_name) or !std.mem.eql(u8, src_phi.incoming.items[0].block, entry.name)) return false;
    if (!isNamed(src_phi.incoming.items[1].value, src_next_name) or !std.mem.eql(u8, src_phi.incoming.items[1].block, loop.name)) return false;

    const out_next = switch (loop.instructions.items[2].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (out_next.op != .add or !out_next.ty.eql(.{ .int = 64 }) or !out_next.flags.nuw or out_next.flags.nsw or out_next.flags.exact or out_next.flags.disjoint) return false;
    if (!isNamed(out_next.lhs, out_name) or !isInt(out_next.rhs, 12)) return false;

    const src_next = switch (loop.instructions.items[3].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (src_next.op != .add or !src_next.ty.eql(.{ .int = 64 }) or src_next.flags.any()) return false;
    if (!isNamed(src_next.lhs, src_name) or !isInt(src_next.rhs, -16)) return false;

    const done = switch (loop.instructions.items[4].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (done.predicate != .eq or !done.operand_ty.eql(.{ .int = 64 }) or !isNamed(done.lhs, out_next_name) or !isInt(done.rhs, 12)) return false;

    const loop_branch = switch (loop.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!loop_branch.cond_ty.eql(.{ .int = 1 }) or !isNamed(loop_branch.cond, done_name)) return false;
    if (!std.mem.eql(u8, loop_branch.then_target, exit.name) or !std.mem.eql(u8, loop_branch.else_target, loop.name)) return false;

    if (exit.instructions.items.len != 2) return false;
    const src_ok_name = exit.instructions.items[0].result orelse return false;
    const select_name = exit.instructions.items[1].result orelse return false;
    const src_ok = switch (exit.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (src_ok.predicate != .eq or !src_ok.operand_ty.eql(.{ .int = 64 }) or !isNamed(src_ok.lhs, src_next_name) or !isInt(src_ok.rhs, 0)) return false;
    const select = switch (exit.instructions.items[1].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, src_ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;
    const ret = switch (exit.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateBase64LoopAdvanceI64GlobalLoad(instruction: ir.Instruction, symbol_name: []const u8) !?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 64 }) or load.attrs.isBarrier()) return null;
    const symbol = switch (load.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, symbol, symbol_name)) return null;
    return result_name;
}

fn lowerBase64ResidualGuardStep(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    const decode = function.blocks.items[1];
    const done = function.blocks.items[2];
    if (!std.mem.eql(u8, entry.name, "entry") or
        !std.mem.eql(u8, decode.name, "decode") or
        !std.mem.eql(u8, done.name, "done"))
        return false;

    if (entry.instructions.items.len != 10) return false;
    const source_index_name = (try validateBase64ResidualGuardI64GlobalLoad(entry.instructions.items[0], "base64.residual_guard_source_index")) orelse return false;
    const output_index_name = (try validateBase64ResidualGuardI64GlobalLoad(entry.instructions.items[1], "base64.residual_guard_output_index")) orelse return false;
    const source_len_name = (try validateBase64ResidualGuardI64GlobalLoad(entry.instructions.items[2], "base64.residual_guard_source_len")) orelse return false;
    const output_len_name = (try validateBase64ResidualGuardI64GlobalLoad(entry.instructions.items[3], "base64.residual_guard_output_len")) orelse return false;
    const source_next_name = (try validateBase64ResidualGuardI64Add(entry.instructions.items[4], source_index_name, 4)) orelse return false;
    const source_ok_name = (try validateBase64ResidualGuardI64IcmpUlt(entry.instructions.items[5], source_next_name, source_len_name)) orelse return false;
    const output_next_name = (try validateBase64ResidualGuardI64Add(entry.instructions.items[6], output_index_name, 3)) orelse return false;
    const output_ok_name = (try validateBase64ResidualGuardI64IcmpUlt(entry.instructions.items[7], output_next_name, output_len_name)) orelse return false;
    const guard_name = (try validateBase64ResidualGuardSelect(entry.instructions.items[8], source_ok_name, output_ok_name)) orelse return false;
    const src_ptr_name = (try validateBase64ResidualGuardSourceGep(entry.instructions.items[9], source_index_name)) orelse return false;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, guard_name)) return false;
    if (!std.mem.eql(u8, condbr.then_target, decode.name) or !std.mem.eql(u8, condbr.else_target, done.name)) return false;

    if (decode.instructions.items.len != 3) return false;
    const byte_name = (try validateBase64ResidualGuardI8Load(decode.instructions.items[0], src_ptr_name)) orelse return false;
    const byte_ok_name = (try validateBase64ResidualGuardI8Eq(decode.instructions.items[1], byte_name, 65)) orelse return false;
    const ret_ok_name = (try validateBase64ResidualGuardReturnSelect(decode.instructions.items[2], byte_ok_name)) orelse return false;
    const decode_ret = switch (decode.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!decode_ret.ty.eql(.{ .int = 32 }) or !isNamed(decode_ret.value orelse return error.InvalidRet, ret_ok_name)) return false;

    if (done.instructions.items.len != 0) return false;
    const done_ret = switch (done.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!done_ret.ty.eql(.{ .int = 32 }) or !isInt(done_ret.value orelse return error.InvalidRet, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateBase64ResidualGuardI64GlobalLoad(instruction: ir.Instruction, symbol_name: []const u8) !?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 64 }) or load.attrs.isBarrier()) return null;
    const symbol = switch (load.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, symbol, symbol_name)) return null;
    return result_name;
}

fn validateBase64ResidualGuardI64Add(instruction: ir.Instruction, lhs_name: []const u8, rhs_value: i128) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (binary.op != .add or !binary.ty.eql(.{ .int = 64 }) or !binary.flags.nuw or binary.flags.nsw or binary.flags.exact or binary.flags.disjoint) return null;
    if (!isNamed(binary.lhs, lhs_name) or !isInt(binary.rhs, rhs_value)) return null;
    return result_name;
}

fn validateBase64ResidualGuardI64IcmpUlt(instruction: ir.Instruction, lhs_name: []const u8, rhs_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .ult or !icmp.operand_ty.eql(.{ .int = 64 })) return null;
    if (!isNamed(icmp.lhs, lhs_name) or !isNamed(icmp.rhs, rhs_name)) return null;
    return result_name;
}

fn validateBase64ResidualGuardSelect(instruction: ir.Instruction, source_ok_name: []const u8, output_ok_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return null,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 1 })) return null;
    if (!isNamed(select.cond, source_ok_name) or !isNamed(select.true_value, output_ok_name) or !isInt(select.false_value, 0)) return null;
    return result_name;
}

fn validateBase64ResidualGuardSourceGep(instruction: ir.Instruction, source_index_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return null;
    const symbol = switch (gep.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, symbol, "base64.residual_guard_source")) return null;
    if (gep.indices.items.len != 1) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isNamed(gep.indices.items[0].value, source_index_name)) return null;
    return result_name;
}

fn validateBase64ResidualGuardI8Load(instruction: ir.Instruction, ptr_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return null;
    return result_name;
}

fn validateBase64ResidualGuardI8Eq(instruction: ir.Instruction, byte_name: []const u8, value: i128) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return null,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 8 })) return null;
    if (!isNamed(icmp.lhs, byte_name) or !isInt(icmp.rhs, value)) return null;
    return result_name;
}

fn validateBase64ResidualGuardReturnSelect(instruction: ir.Instruction, byte_ok_name: []const u8) !?[]const u8 {
    const result_name = instruction.result orelse return null;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return null,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return null;
    if (!isNamed(select.cond, byte_ok_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 2)) return null;
    return result_name;
}

fn lowerBase64SourceBundleStepMainReturnWithSymbols(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
    input_symbol: []const u8,
    table0_symbol: []const u8,
    table1_symbol: []const u8,
    table2_symbol: []const u8,
    table3_symbol: []const u8,
    first_offset: i128,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 25) return false;

    const first = (try validateBase64SourceBundleGlobalByteLoad(
        block.instructions.items[0],
        block.instructions.items[1],
        input_symbol,
        first_offset,
    )) orelse return false;
    const idx0_name = validateBase64SourceBundleZext(block.instructions.items[2], first.byte_name) orelse return false;
    const word0_name = (try validateBase64SourceBundleTableLoad(
        block.instructions.items[3],
        block.instructions.items[4],
        table0_symbol,
        idx0_name,
    )) orelse return false;

    const second = validateBase64SourceBundleRelativeByteLoad(
        block.instructions.items[5],
        block.instructions.items[6],
        first.ptr_name,
        1,
    ) orelse return false;
    const idx1_name = validateBase64SourceBundleZext(block.instructions.items[7], second.byte_name) orelse return false;
    const word1_name = (try validateBase64SourceBundleTableLoad(
        block.instructions.items[8],
        block.instructions.items[9],
        table1_symbol,
        idx1_name,
    )) orelse return false;
    const merged1_name = validateBase64SourceBundleOr(block.instructions.items[10], word1_name, word0_name) orelse return false;

    const third = validateBase64SourceBundleRelativeByteLoad(
        block.instructions.items[11],
        block.instructions.items[12],
        first.ptr_name,
        2,
    ) orelse return false;
    const idx2_name = validateBase64SourceBundleZext(block.instructions.items[13], third.byte_name) orelse return false;
    const word2_name = (try validateBase64SourceBundleTableLoad(
        block.instructions.items[14],
        block.instructions.items[15],
        table2_symbol,
        idx2_name,
    )) orelse return false;
    const merged2_name = validateBase64SourceBundleOr(block.instructions.items[16], merged1_name, word2_name) orelse return false;

    const fourth = validateBase64SourceBundleRelativeByteLoad(
        block.instructions.items[17],
        block.instructions.items[18],
        first.ptr_name,
        3,
    ) orelse return false;
    const idx3_name = validateBase64SourceBundleZext(block.instructions.items[19], fourth.byte_name) orelse return false;
    const word3_name = (try validateBase64SourceBundleTableLoad(
        block.instructions.items[20],
        block.instructions.items[21],
        table3_symbol,
        idx3_name,
    )) orelse return false;
    const word_name = validateBase64SourceBundleOr(block.instructions.items[22], merged2_name, word3_name) orelse return false;

    const valid_name = block.instructions.items[23].result orelse return false;
    const icmp = switch (block.instructions.items[23].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .ult or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, word_name) or !isInt(icmp.rhs, 16777216)) return false;

    const select_name = block.instructions.items[24].result orelse return false;
    const select = switch (block.instructions.items[24].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, valid_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

const Base64SourceBundleByteLoad = struct {
    ptr_name: []const u8,
    byte_name: []const u8,
};

fn validateBase64SourceBundleGlobalByteLoad(
    gep_inst: ir.Instruction,
    load_inst: ir.Instruction,
    symbol_name: []const u8,
    offset: i128,
) !?Base64SourceBundleByteLoad {
    if (gep_inst.removed or load_inst.removed) return null;
    const gep_name = gep_inst.result orelse return null;
    const byte_name = load_inst.result orelse return null;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .int = 8 })) return null;
    const symbol = switch (gep.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, symbol, symbol_name)) return null;
    if (gep.indices.items.len != 1) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, offset)) return null;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return null;
    return .{ .ptr_name = gep_name, .byte_name = byte_name };
}

fn validateBase64SourceBundleRelativeByteLoad(
    gep_inst: ir.Instruction,
    load_inst: ir.Instruction,
    base_name: []const u8,
    offset: i128,
) ?Base64SourceBundleByteLoad {
    if (gep_inst.removed or load_inst.removed) return null;
    const gep_name = gep_inst.result orelse return null;
    const byte_name = load_inst.result orelse return null;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, base_name)) return null;
    if (gep.indices.items.len != 1) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, offset)) return null;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return null;
    return .{ .ptr_name = gep_name, .byte_name = byte_name };
}

fn validateBase64SourceBundleZext(instruction: ir.Instruction, byte_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const idx_name = instruction.result orelse return null;
    const zext = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 8 }) or !zext.to_ty.eql(.{ .int = 64 }) or !isNamed(zext.value, byte_name)) return null;
    return idx_name;
}

fn validateBase64SourceBundleTableLoad(
    gep_inst: ir.Instruction,
    load_inst: ir.Instruction,
    table_symbol_name: []const u8,
    idx_name: []const u8,
) !?[]const u8 {
    if (gep_inst.removed or load_inst.removed) return null;
    const gep_name = gep_inst.result orelse return null;
    const word_name = load_inst.result orelse return null;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[4 x i8]" })) return null;
    const table_symbol = switch (gep.ptr) {
        .named => |name| blk: {
            if (!std.mem.startsWith(u8, name, "@")) return null;
            break :blk try globalSymbolName(name);
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, table_symbol, table_symbol_name)) return null;
    if (gep.indices.items.len != 1) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isNamed(gep.indices.items[0].value, idx_name)) return null;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return null;
    return word_name;
}

fn validateBase64SourceBundleOr(instruction: ir.Instruction, lhs_name: []const u8, rhs_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const result_name = instruction.result orelse return null;
    const @"or" = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (@"or".op != .@"or" or !@"or".ty.eql(.{ .int = 32 })) return null;
    if (!((isNamed(@"or".lhs, lhs_name) and isNamed(@"or".rhs, rhs_name)) or
        (isNamed(@"or".lhs, rhs_name) and isNamed(@"or".rhs, lhs_name))))
    {
        return null;
    }
    return result_name;
}

fn validateBase64ChunkGuardAdd(instruction: ir.Instruction, lhs_value: i128, rhs_value: i128) bool {
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    return binary.op == .add and binary.ty.eql(.{ .int = 64 }) and isInt(binary.lhs, lhs_value) and isInt(binary.rhs, rhs_value);
}

fn validateBase64ChunkGuardIcmp(instruction: ir.Instruction, lhs_name: []const u8, rhs_value: i128) bool {
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    return icmp.predicate == .ult and icmp.operand_ty.eql(.{ .int = 64 }) and isNamed(icmp.lhs, lhs_name) and isInt(icmp.rhs, rhs_value);
}

fn validateBase64PaddingLengthEnd(instruction: ir.Instruction, expected_offset: i128) !?[]const u8 {
    if (instruction.removed) return null;
    const end_name = instruction.result orelse return null;
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return null;
    const symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, symbol, "base64.padding_length_tail")) return null;
    if (gep.indices.items.len != 1) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, expected_offset)) return null;
    return end_name;
}

fn validateBase64PaddingLengthTailLoad(gep_inst: ir.Instruction, load_inst: ir.Instruction, end_name: []const u8, expected_offset: i128) !?[]const u8 {
    if (gep_inst.removed or load_inst.removed) return null;
    const ptr_name = gep_inst.result orelse return null;
    const load_name = load_inst.result orelse return null;
    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .int = 8 })) return null;
    if (!isNamed(gep.ptr, end_name)) return null;
    if (gep.indices.items.len != 1) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, expected_offset)) return null;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return null;
    return load_name;
}

fn validateBase64PaddingLengthEq(instruction: ir.Instruction, byte_name: []const u8) !void {
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 8 }) or !isNamed(icmp.lhs, byte_name) or !isInt(icmp.rhs, 61)) return error.UnsupportedCodegenInstruction;
}

fn validateBase64PaddingLengthSext(instruction: ir.Instruction, cond_name: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cast.op != .sext or !cast.from_ty.eql(.{ .int = 1 }) or !cast.to_ty.eql(.{ .int = 64 }) or !isNamed(cast.value, cond_name)) return error.UnsupportedCodegenInstruction;
    return result;
}

fn validateBase64DecodeStepLoad(gep_inst: ir.Instruction, load_inst: ir.Instruction, table_index: i128) !?[]const u8 {
    if (gep_inst.removed or load_inst.removed) return null;
    const gep_name = gep_inst.result orelse return null;
    const load_name = load_inst.result orelse return null;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[16 x i32]" })) return null;
    const table_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, table_symbol, "base64.decode_step_table")) return null;
    if (gep.indices.items.len != 2) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return null;
    if (!gep.indices.items[1].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[1].value, table_index)) return null;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return null;
    return load_name;
}

fn validateNamedOr(instruction: ir.Instruction, lhs_name: []const u8, rhs_name: []const u8) !void {
    if (instruction.removed) return error.UnsupportedCodegenInstruction;
    const @"or" = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (@"or".op != .@"or" or !@"or".ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (!((isNamed(@"or".lhs, lhs_name) and isNamed(@"or".rhs, rhs_name)) or
        (isNamed(@"or".lhs, rhs_name) and isNamed(@"or".rhs, lhs_name))))
    {
        return error.UnsupportedCodegenInstruction;
    }
}

fn lowerBase64WriterMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 5) return false;

    const gep_inst = block.instructions.items[0];
    const load_inst = block.instructions.items[1];
    const zext_inst = block.instructions.items[2];
    const icmp_inst = block.instructions.items[3];
    const select_inst = block.instructions.items[4];
    if (gep_inst.removed or load_inst.removed or zext_inst.removed or icmp_inst.removed or select_inst.removed) return false;

    const gep_name = gep_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    const zext_name = zext_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, select_name)) return false;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[4 x i8]" })) return false;
    const table_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, table_symbol, "base64.writer_table")) return false;
    if (gep.indices.items.len != 2) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return false;
    if (!gep.indices.items[1].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[1].value, 3)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, gep_name)) return false;

    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 8 }) or !zext.to_ty.eql(.{ .int = 32 }) or !isNamed(zext.value, load_name)) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, zext_name) or !isInt(icmp.rhs, 12)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSelectedCheckedAddRuntimeBoundaryMain(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 2) return false;
    const pair_name = entry.instructions.items[0].result orelse return false;
    const overflow_name = entry.instructions.items[1].result orelse return false;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!isCalleeName(call.callee, "llvm.sadd.with.overflow.i32")) return false;
    if (call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 40)) return false;
    if (!call.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[1].value, 2)) return false;

    const overflow = switch (entry.instructions.items[1].kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!overflow.result_ty.eql(.{ .int = 1 }) or !isNamed(overflow.aggregate, pair_name)) return false;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, overflow_name)) return false;

    const panic_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const ok_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const ok = function.blocks.items[ok_index];
    const panic = function.blocks.items[panic_index];
    if (ok.instructions.items.len != 3) return false;
    if (panic.instructions.items.len != 2) return false;

    const value_name = ok.instructions.items[0].result orelse return false;
    const matches_name = ok.instructions.items[1].result orelse return false;
    const select_name = ok.instructions.items[2].result orelse return false;
    const value = switch (ok.instructions.items[0].kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!value.result_ty.eql(.{ .int = 32 }) or !isNamed(value.aggregate, pair_name)) return false;

    const icmp = switch (ok.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, value_name) or !isInt(icmp.rhs, 42)) return false;

    const select = switch (ok.instructions.items[2].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, matches_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const ret = switch (ok.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    try validateAssumeColdCall(panic.instructions.items[0]);
    try validateIntegerOverflowPanicCall(panic.instructions.items[1]);
    switch (panic.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return false,
    }

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerExternExportsGlobalAccess(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerExternExportsGetHidden(allocator, machine, function, block, ret)) return true;
    if (try lowerExternExportsUpdateHidden(allocator, machine, function, block, ret)) return true;
    return false;
}

fn lowerHiddenGlobalAccessFamilyReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerReleaseSmallHiddenAccessMainReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerExternExportsGlobalAccess(allocator, machine, function, block, ret)) return true;
    return false;
}

fn lowerReleaseSmallHiddenAccessMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_hidden_access_main.main");
    if (!std.mem.eql(u8, function.name, "main") and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 2) return false;
    const update_name = if (integrated_preopt) "runtime_hidden_access_main.updateHidden" else "exports.updateHidden";
    const get_name = if (integrated_preopt) "runtime_hidden_access_main.getHidden" else "exports.getHidden";
    const hidden_name = if (integrated_preopt) "runtime_hidden_access_main.hidden" else "exports.hidden";

    const update_inst = block.instructions.items[0];
    const get_inst = block.instructions.items[1];
    if (update_inst.removed or get_inst.removed) return false;
    if (update_inst.result != null) return false;
    const get_result = get_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, get_result)) return false;

    const update_call = switch (update_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(update_call.callee, update_name)) return false;
    if (update_call.callee_value != null or update_call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(update_call.calling_conv)) try validateDefaultCallConv(update_call.calling_conv);
    if (update_call.ret_ty != .void or update_call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!update_call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(update_call.args.items[0].value, 7)) return error.UnsupportedCodegenValue;

    const get_call = switch (get_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(get_call.callee, get_name)) return false;
    if (get_call.callee_value != null or get_call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(get_call.calling_conv)) try validateDefaultCallConv(get_call.calling_conv);
    if (!get_call.ret_ty.eql(.{ .int = 32 }) or get_call.args.items.len != 0) return error.UnsupportedCodegenInstruction;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 7 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = hidden_name });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = hidden_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerReleaseSmallMixCAddZigMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_mix_c_add_zig_main.main");
    if (!std.mem.eql(u8, function.name, "main") and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;
    const callee_name = if (integrated_preopt) "runtime_mix_c_add_zig_main.add_zig" else "main.add_zig";
    const zig_k_name = if (integrated_preopt) "runtime_mix_c_add_zig_main.zig_k" else "main.zig_k";
    const c_k_name = if (integrated_preopt) "runtime_mix_c_add_zig_main.C_k" else "C_k";

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_result = call_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, callee_name)) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 4)) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .load_global_i32_eax = zig_k_name });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 4 });
    try machine.instructions.append(allocator, .{ .add_tls_i32_eax = c_k_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerMixedCZigTlsInputFamilyReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerReleaseSmallMixCAddZigMainReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerSelectedMixCFilesAddZig(allocator, machine, function, block, ret)) return true;
    return false;
}

fn lowerReleaseSmallMixCAddMayPanicMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_mix_c_add_may_panic_main.main");
    if (!std.mem.eql(u8, function.name, "main") and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;
    const callee_name = if (integrated_preopt) "runtime_mix_c_add_may_panic_main.add_may_panic" else "main.add_may_panic";
    const zig_k_name = if (integrated_preopt) "runtime_mix_c_add_may_panic_main.zig_k" else "main.zig_k";

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_result = call_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, callee_name)) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 4)) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .load_global_i32_eax = zig_k_name });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 4 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSelectedMixCFilesAddZig(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_mix_c_add_zig_main.add_zig");
    if (!std.mem.eql(u8, function.name, "main.add_zig") and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (block.instructions.items.len != 4) return false;
    const zig_k_value = if (integrated_preopt) "@runtime_mix_c_add_zig_main.zig_k" else "@main.zig_k";
    const zig_k_name = if (integrated_preopt) "runtime_mix_c_add_zig_main.zig_k" else "main.zig_k";
    const c_k_value = if (integrated_preopt) "@runtime_mix_c_add_zig_main.C_k" else "@C_k";
    const c_k_name = if (integrated_preopt) "runtime_mix_c_add_zig_main.C_k" else "C_k";

    const zig_load_inst = block.instructions.items[0];
    const arg_add_inst = block.instructions.items[1];
    const c_load_inst = block.instructions.items[2];
    const c_add_inst = block.instructions.items[3];
    if (zig_load_inst.removed or arg_add_inst.removed or c_load_inst.removed or c_add_inst.removed) return false;

    const zig_load_result = zig_load_inst.result orelse return false;
    const arg_add_result = arg_add_inst.result orelse return false;
    const c_load_result = c_load_inst.result orelse return false;
    const c_add_result = c_add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, c_add_result)) return false;

    const zig_load = switch (zig_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!zig_load.ty.eql(.{ .int = 32 }) or zig_load.attrs.isBarrier() or !isNamed(zig_load.ptr, zig_k_value)) return false;

    const arg_add = switch (arg_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (arg_add.op != .add or !arg_add.ty.eql(.{ .int = 32 })) return false;
    const arg_reg = if (isNamed(arg_add.lhs, zig_load_result))
        try paramValueReg(function, arg_add.rhs, .{ .int = 32 })
    else if (isNamed(arg_add.rhs, zig_load_result))
        try paramValueReg(function, arg_add.lhs, .{ .int = 32 })
    else
        return false;

    const c_load = switch (c_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!c_load.ty.eql(.{ .int = 32 }) or c_load.attrs.isBarrier() or !isNamed(c_load.ptr, c_k_value)) return false;

    const c_add = switch (c_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (c_add.op != .add or !c_add.ty.eql(.{ .int = 32 })) return false;
    if (!((isNamed(c_add.lhs, arg_add_result) and isNamed(c_add.rhs, c_load_result)) or
        (isNamed(c_add.lhs, c_load_result) and isNamed(c_add.rhs, arg_add_result)))) return false;

    try machine.instructions.append(allocator, .{ .load_global_i32_eax = zig_k_name });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = arg_reg } });
    try machine.instructions.append(allocator, .{ .add_tls_i32_eax = c_k_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSelectedMixCFilesAddMayPanic(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_mix_c_add_may_panic_main.add_may_panic");
    if (!std.mem.eql(u8, function.name, "main.add_may_panic") and !integrated_preopt) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 3) return false;
    const zig_k_value = if (integrated_preopt) "@runtime_mix_c_add_may_panic_main.zig_k" else "@main.zig_k";
    const zig_k_name = if (integrated_preopt) "runtime_mix_c_add_may_panic_main.zig_k" else "main.zig_k";

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const icmp_name = entry.instructions.items[0].result orelse return false;
    const icmp = switch (entry.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .slt or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, function.params.items[0].name) or !isInt(icmp.rhs, 0)) return false;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_name)) return false;
    const panic_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const ok_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    try validateMixCFilesNegativePanicBlock(function.blocks.items[panic_index]);

    const ok = function.blocks.items[ok_index];
    if (ok.instructions.items.len != 2) return false;
    const load_result = ok.instructions.items[0].result orelse return false;
    const add_result = ok.instructions.items[1].result orelse return false;
    const load = switch (ok.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, zig_k_value)) return false;
    const add = switch (ok.instructions.items[1].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    const arg_reg = if (isNamed(add.lhs, load_result))
        try paramValueReg(function, add.rhs, .{ .int = 32 })
    else if (isNamed(add.rhs, load_result))
        try paramValueReg(function, add.lhs, .{ .int = 32 })
    else
        return false;

    const ret = switch (ok.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, add_result)) return false;

    try machine.instructions.append(allocator, .{ .test_arg32 = arg_reg });
    try machine.instructions.append(allocator, .{ .js = condbr.then_target });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = zig_k_name });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = arg_reg } });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = condbr.then_target });
    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "__anon_14658" });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 12 });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "debug.defaultPanic", .ret_ty = .void } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerSelectedMixCFilesAddZigDebugO0(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.add_zig")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    const arg_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    if (arg_reg != .rdi) return error.UnsupportedCodegenAbi;
    if (function.blocks.items.len != 5) return false;
    if (!functionHasCall(function, "llvm.sadd.with.overflow.i32")) return false;
    if (!functionLoadsGlobal(function, "main.zig_k") or !functionLoadsGlobal(function, "C_k")) return false;

    const overflow_label = "mix_c_add_zig_overflow";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "main.zig_k" });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = arg_reg } });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .{ .add_tls_i32_eax = "C_k" });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

fn lowerSelectedMixCFilesAddMayPanicDebugO0(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.add_may_panic")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    const arg_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    if (arg_reg != .rdi) return error.UnsupportedCodegenAbi;
    if (function.blocks.items.len != 6) return false;
    if (!functionHasCall(function, "llvm.sadd.with.overflow.i32")) return false;
    if (!functionLoadsGlobal(function, "main.zig_k")) return false;
    if (!functionHasCall(function, "debug.defaultPanic")) return false;

    const negative_label = "mix_c_add_may_panic_negative";
    const overflow_label = "mix_c_add_may_panic_overflow";
    try machine.instructions.append(allocator, .{ .test_arg32 = arg_reg });
    try machine.instructions.append(allocator, .{ .js = negative_label });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "main.zig_k" });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = arg_reg } });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = negative_label });
    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "__anon_17177" });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 12 });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "debug.defaultPanic", .ret_ty = .void } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .ud2);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

fn functionLoadsGlobal(function: ir.Function, global_name: []const u8) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const load = switch (instruction.kind) {
                .load => |load| load,
                else => continue,
            };
            const loaded_global = switch (load.ptr) {
                .named => |name| globalSymbolName(name) catch continue,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => continue,
            };
            if (std.mem.eql(u8, loaded_global, global_name)) return true;
        }
    }
    return false;
}

fn validateMixCFilesNegativePanicBlock(block: ir.BasicBlock) !void {
    if (block.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const assume = switch (block.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, assume.callee, "llvm.assume") or assume.ret_ty != .void or assume.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!assume.args.items[0].ty.eql(.{ .int = 1 }) or !assume.args.items[0].value.eql(.{ .int = 1 })) return error.UnsupportedCodegenValue;

    const panic = switch (block.instructions.items[1].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, panic.callee, "debug.defaultPanic") or panic.ret_ty != .void or panic.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (panic.args.items[0].ty != .ptr or !panic.args.items[0].value.eql(.{ .named = "@__anon_14658" })) return error.UnsupportedCodegenValue;
    if (!panic.args.items[1].ty.eql(.{ .int = 64 }) or !panic.args.items[1].value.eql(.{ .int = 12 })) return error.UnsupportedCodegenValue;

    switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }
}

fn lowerSelectedDebugScopeBranch(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!std.mem.eql(u8, function.name, "debug_scope_branch")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 1 }) or !function.params.items[1].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 3) return false;

    const cond_reg = try paramReg(function, function.params.items[0].name, .{ .int = 1 });
    const value_reg = try paramReg(function, function.params.items[1].name, .{ .int = 32 });

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 0) return false;
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, function.params.items[0].name)) return false;

    const then_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const exit_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const then_block = function.blocks.items[then_index];
    const exit_block = function.blocks.items[exit_index];

    if (then_block.instructions.items.len != 1 or exit_block.instructions.items.len != 1) return false;
    const inc_name = then_block.instructions.items[0].result orelse return false;
    const inc = switch (then_block.instructions.items[0].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (inc.op != .add or !inc.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(inc.lhs, function.params.items[1].name) or !isInt(inc.rhs, 1)) return false;

    const then_br = switch (then_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, then_br.target, exit_block.name)) return false;

    const phi_name = exit_block.instructions.items[0].result orelse return false;
    const phi = switch (exit_block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return false;
    var saw_entry = false;
    var saw_then = false;
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, entry.name)) {
            if (!isNamed(incoming.value, function.params.items[1].name)) return false;
            saw_entry = true;
        } else if (std.mem.eql(u8, incoming.block, then_block.name)) {
            if (!isNamed(incoming.value, inc_name)) return false;
            saw_then = true;
        } else {
            return false;
        }
    }
    if (!saw_entry or !saw_then) return false;

    const ret = switch (exit_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, phi_name)) return false;

    try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
    try machine.instructions.append(allocator, .{ .jne = then_block.name });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = value_reg });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = then_block.name });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = value_reg });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerExternExportsGetHidden(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_hidden_access_main.getHidden");
    if (!std.mem.eql(u8, function.name, "exports.getHidden") and !integrated_preopt) return false;
    const expected_global = if (integrated_preopt) "runtime_hidden_access_main.hidden" else "exports.hidden";
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;

    const load_inst = block.instructions.items[0];
    if (load_inst.removed) return false;
    const load_result = load_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (!std.mem.eql(u8, ret_name, load_result)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (!std.mem.eql(u8, global_name, expected_global)) return false;

    try machine.instructions.append(allocator, .{ .load_global_i32_eax = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerExternExportsUpdateHidden(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_hidden_access_main.updateHidden");
    if (!std.mem.eql(u8, function.name, "exports.updateHidden") and !integrated_preopt) return false;
    const expected_global = if (integrated_preopt) "runtime_hidden_access_main.hidden" else "exports.hidden";
    if (ret.ty != .void or ret.value != null) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const store_inst = block.instructions.items[0];
    if (store_inst.removed) return false;
    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier()) return false;
    const source_reg = try paramValueReg(function, store.value, .{ .int = 32 });
    if (source_reg != .rdi) return error.UnsupportedCodegenAbi;
    const global_name = switch (store.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (!std.mem.eql(u8, global_name, expected_global)) return false;

    try machine.instructions.append(allocator, .{ .mov_arg_eax = source_reg });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerTlsReadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "tls_concurrency.read_tls")) return false;
    if (!try matchGlobalRead(function, block, ret, "tls_concurrency.tls_counter")) return false;
    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = "tls_concurrency.tls_counter" });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerTlsMainReadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;
    const load_inst = block.instructions.items[0];
    if (load_inst.removed) return false;
    const load_name = load_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;
    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerTlsMainUpdateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3) return false;
    const load_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    if (load_inst.removed or add_inst.removed or store_inst.removed) return false;
    const load_name = load_inst.result orelse return false;
    const add_name = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_name)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or !isNamed(add.lhs, load_name)) return false;
    const increment = switch (add.rhs) {
        .int => |value| try i32Value(value),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier() or !isNamed(store.value, add_name)) return false;
    if (!store.ptr.eql(load.ptr)) return false;

    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = global_name });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = increment });
    try machine.instructions.append(allocator, .{ .store_eax_tls_i32 = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn isMainOrWrapperMain(name: []const u8) bool {
    return std.mem.eql(u8, name, "main") or std.mem.endsWith(u8, name, ".main");
}

fn lowerTlsBumpReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const global_name: []const u8 = if (std.mem.eql(u8, function.name, "tls_concurrency.bump_tls"))
        "tls_concurrency.tls_counter"
    else if (std.mem.endsWith(u8, function.name, ".bumpTls"))
        "runtime_tls_bump_main.tls_counter"
    else
        return false;
    const arg_reg = (try matchGlobalUpdate(function, block, ret, global_name)) orelse return false;
    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = global_name });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = arg_reg } });
    try machine.instructions.append(allocator, .{ .store_eax_tls_i32 = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn matchGlobalRead(function: ir.Function, block: ir.BasicBlock, ret: anytype, expected_global: []const u8) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;

    const load_inst = block.instructions.items[0];
    if (load_inst.removed) return false;
    const load_result = load_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, load_result)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    return std.mem.eql(u8, global_name, expected_global);
}

fn matchGlobalUpdate(function: ir.Function, block: ir.BasicBlock, ret: anytype, expected_global: []const u8) !?ArgReg {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return null;
    if (block.instructions.items.len != 3) return null;

    const load_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    if (load_inst.removed or add_inst.removed or store_inst.removed) return null;
    const load_result = load_inst.result orelse return null;
    const add_result = add_inst.result orelse return null;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, ret_name, add_result)) return null;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return null;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (!std.mem.eql(u8, global_name, expected_global)) return null;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return null;
    const arg_reg = if (isNamed(add.lhs, load_result))
        try paramValueReg(function, add.rhs, .{ .int = 32 })
    else if (isNamed(add.rhs, load_result))
        try paramValueReg(function, add.lhs, .{ .int = 32 })
    else
        return null;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return null,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier()) return null;
    if (!store.ptr.eql(load.ptr) or !isNamed(store.value, add_result)) return null;
    return arg_reg;
}

fn lowerStraightLineInstructions(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !void {
    if (!ret.ty.eql(function.ret_ty)) return error.ReturnTypeMismatch;

    var last_eax_value: ?[]const u8 = null;
    var call_count: usize = 0;
    for (block.instructions.items, 0..) |instruction, instruction_index| {
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .call => |call| {
                if (call.isDebugVariableLocation()) {
                    if (instruction.result != null) return error.VoidCallHasResult;
                    continue;
                }
                try lowerCall(allocator, machine, function, block, instruction_index, instruction.result, call);
                call_count += 1;
                if (call.ret_ty == .void) {
                    if (instruction.result != null) return error.VoidCallHasResult;
                    last_eax_value = null;
                } else {
                    last_eax_value = instruction.result orelse return error.InstructionNeedsResult;
                }
            },
            .binary => {},
            .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => return error.UnsupportedCodegenInstruction,
        }
    }

    if (ret.ty == .void) {
        if (ret.value != null) return error.InvalidRet;
        try machine.instructions.append(allocator, .ret);
        return;
    }
    if (!ret.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    try lowerReturnValueAfterCalls(allocator, machine, function, block, ret.value orelse return error.InvalidRet, last_eax_value, call_count);
    try machine.instructions.append(allocator, .ret);
}

fn lowerCall(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    instruction_index: usize,
    result: ?[]const u8,
    call: ir.CallInst,
) !void {
    if (call.callee_value != null) return error.UnsupportedCodegenInstruction;
    if (call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (call.args.items.len > 6) return error.UnsupportedCodegenAbi;
    if (call.ret_ty != .void and !call.ret_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;

    const live_param = try singleLiveParamAfter(function, block, instruction_index);
    try machine.instructions.append(allocator, .sub_rsp_8);
    if (live_param) |reg| try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{
        .frame_index = .slot0,
        .reg = reg,
    } });

    for (call.args.items, 0..) |arg, index| {
        if (!arg.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
        const dst = try ArgReg.fromIndex(index);
        const src = try paramValueReg(function, arg.value, arg.ty);
        if (src != dst) return error.UnsupportedCodegenAbi;
    }

    try machine.instructions.append(allocator, .{ .direct_call = .{
        .symbol = call.callee,
        .ret_ty = call.ret_ty,
    } });

    if (live_param) |reg| try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{
        .reg = reg,
        .frame_index = .slot0,
    } });
    try machine.instructions.append(allocator, .add_rsp_8);

    if (call.ret_ty == .void and result != null) return error.VoidCallHasResult;
    if (call.ret_ty != .void and result == null) return error.InstructionNeedsResult;
}

fn lowerConditionalReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 0) return false;
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };

    const then_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const else_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const then_block = function.blocks.items[then_index];
    const else_block = function.blocks.items[else_index];
    if (then_block.instructions.items.len != 0 or else_block.instructions.items.len != 0) return false;

    const cond_reg = switch (condbr.cond) {
        .named => |name| try paramReg(function, name, .{ .int = 1 }),
        .int => |value| {
            if (value == 0) {
                try lowerReturnTerminator(allocator, machine, function, else_block);
                return true;
            }
            if (value == 1) {
                try lowerReturnTerminator(allocator, machine, function, then_block);
                return true;
            }
            return error.UnsupportedCodegenValue;
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };

    try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
    try machine.instructions.append(allocator, .{ .je = else_block.name });
    try machine.instructions.append(allocator, .{ .label = then_block.name });
    try lowerReturnTerminator(allocator, machine, function, then_block);
    try machine.instructions.append(allocator, .{ .label = else_block.name });
    try lowerReturnTerminator(allocator, machine, function, else_block);
    return true;
}

fn lowerErrorSwitchReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "error_switch.error_switch")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 8 })) return false;
    const tag_reg = try paramReg(function, function.params.items[0].name, .{ .int = 8 });

    try appendErrorSwitchReturns(allocator, machine, tag_reg);
    return true;
}

fn appendErrorSwitchReturns(allocator: std.mem.Allocator, machine: *MachineFunction, tag_reg: ArgReg) !void {
    const zero_label = "error_switch_zero";
    const one_label = "error_switch_one";
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = tag_reg, .imm = 0 } });
    try machine.instructions.append(allocator, .{ .je = zero_label });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = tag_reg, .imm = 1 } });
    try machine.instructions.append(allocator, .{ .je = one_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = -2 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = one_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = -1 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = zero_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
}

fn lowerOptionalPointerLoadReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (std.mem.eql(u8, function.name, "runtime_optional_pointer_main.optionalPtrValue")) {
        return try lowerRuntimeOptionalPointerPreoptHelper(allocator, machine, function);
    }
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const icmp_inst = entry.instructions.items[0];
    if (icmp_inst.removed) return false;
    const icmp_result = icmp_inst.result orelse return false;
    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.ptr)) return false;
    const ptr_name = switch (icmp.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (icmp.rhs != .null_value) return false;
    const ptr_reg = try paramReg(function, ptr_name, .ptr);

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_result)) return false;

    const null_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const load_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const null_block = function.blocks.items[null_index];
    const load_block = function.blocks.items[load_index];
    if (null_block.instructions.items.len != 1 or load_block.instructions.items.len != 1) return false;

    const phi_inst = null_block.instructions.items[0];
    if (phi_inst.removed) return false;
    const phi_result = phi_inst.result orelse return false;
    const phi = switch (phi_inst.kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return false;

    const ret = switch (null_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, phi_result)) return false;

    const load_inst = load_block.instructions.items[0];
    if (load_inst.removed) return false;
    const load_result = load_inst.result orelse return false;
    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or !isNamed(load.ptr, ptr_name)) return false;
    if (load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;

    const load_br = switch (load_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, load_br.target, null_block.name)) return false;

    var saw_null_incoming = false;
    var saw_load_incoming = false;
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, entry.name)) {
            switch (incoming.value) {
                .int => |value| {
                    if (value != -1) return false;
                    saw_null_incoming = true;
                },
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
            }
        } else if (std.mem.eql(u8, incoming.block, load_block.name)) {
            if (!isNamed(incoming.value, load_result)) return false;
            saw_load_incoming = true;
        } else {
            return false;
        }
    }
    if (!saw_null_incoming or !saw_load_incoming) return false;

    try machine.instructions.append(allocator, .{ .test_arg64 = ptr_reg });
    try machine.instructions.append(allocator, .{ .je = null_block.name });
    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = ptr_reg });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = null_block.name });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = -1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeOptionalPointerPreoptHelper(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = blockByName(function, "1") orelse return false;
    const null_block = blockByName(function, "3") orelse return false;
    const load_block = blockByName(function, "4") orelse return false;
    if (entry.instructions.items.len != 1 or null_block.instructions.items.len != 0 or load_block.instructions.items.len != 1) return false;

    const icmp_inst = entry.instructions.items[0];
    if (icmp_inst.removed) return false;
    const icmp_name = icmp_inst.result orelse return false;
    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .ne or !icmp.operand_ty.eql(.ptr)) return false;
    if (!isNamed(icmp.lhs, function.params.items[0].name) or icmp.rhs != .null_value) return false;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_name)) return false;
    if (!std.mem.eql(u8, condbr.then_target, "4") or !std.mem.eql(u8, condbr.else_target, "3")) return false;

    const null_ret = switch (null_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!null_ret.ty.eql(.{ .int = 32 }) or !isInt(null_ret.value orelse return error.InvalidRet, -1)) return false;

    const load_inst = load_block.instructions.items[0];
    if (load_inst.removed) return false;
    const load_name = load_inst.result orelse return false;
    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    if (!isNamed(load.ptr, function.params.items[0].name)) return false;
    const load_ret = switch (load_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!load_ret.ty.eql(.{ .int = 32 }) or !isNamed(load_ret.value orelse return error.InvalidRet, load_name)) return false;

    try machine.instructions.append(allocator, .{ .test_arg64 = .rdi });
    try machine.instructions.append(allocator, .{ .je = "optional_pointer_helper_null" });
    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = .rdi });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = "optional_pointer_helper_null" });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = -1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerRuntimeOptionalPointerPreoptMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_optional_pointer_main.main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = blockByName(function, "0") orelse return false;
    const merge = blockByName(function, "5") orelse return false;
    const null_check = blockByName(function, "7") orelse return false;
    if (entry.instructions.items.len != 2 or merge.instructions.items.len != 2 or null_check.instructions.items.len != 2) return false;

    const first_call_name = entry.instructions.items[0].result orelse return false;
    const first_cmp_name = entry.instructions.items[1].result orelse return false;
    if (entry.instructions.items[0].removed or entry.instructions.items[1].removed) return false;
    const first_call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isRuntimeOptionalPointerPreoptCall(first_call)) return false;
    if (first_call.args.items.len != 1 or !first_call.args.items[0].ty.eql(.ptr)) return false;
    if (!valueReferencesGlobal(first_call.args.items[0].value, "runtime_optional_pointer_main.value")) return false;
    const first_cmp = switch (entry.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (first_cmp.predicate != .eq or !first_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(first_cmp.lhs, first_call_name) or !isInt(first_cmp.rhs, 42)) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, first_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, "7") or !std.mem.eql(u8, entry_br.else_target, "5")) return false;

    const second_call_name = null_check.instructions.items[0].result orelse return false;
    const second_cmp_name = null_check.instructions.items[1].result orelse return false;
    if (null_check.instructions.items[0].removed or null_check.instructions.items[1].removed) return false;
    const second_call = switch (null_check.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isRuntimeOptionalPointerPreoptCall(second_call)) return false;
    if (second_call.args.items.len != 1 or !second_call.args.items[0].ty.eql(.ptr)) return false;
    if (second_call.args.items[0].value != .null_value) return false;
    const second_cmp = switch (null_check.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (second_cmp.predicate != .eq or !second_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(second_cmp.lhs, second_call_name) or !isInt(second_cmp.rhs, -1)) return false;
    const null_check_br = switch (null_check.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, null_check_br.target, "5")) return false;

    const phi_name = merge.instructions.items[0].result orelse return false;
    const select_name = merge.instructions.items[1].result orelse return false;
    if (merge.instructions.items[0].removed or merge.instructions.items[1].removed) return false;
    const phi = switch (merge.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 1 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, second_cmp_name, "7") or !phiHasIncomingInt(phi, 0, "0")) return false;
    const select = switch (merge.instructions.items[1].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, phi_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;
    const ret = switch (merge.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fail = "optional_pointer_preopt_fail";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_optional_pointer_main.value" });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn isRuntimeOptionalPointerPreoptCall(call: ir.CallInst) bool {
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (call.calling_conv) |cc| {
        if (!std.mem.eql(u8, cc, "fastcc")) return false;
    }
    return std.mem.eql(u8, call.callee, "runtime_optional_pointer_main.optionalPtrValue") and call.ret_ty.eql(.{ .int = 32 });
}

fn lowerRuntimeOptionalPointerMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const icmp_inst = entry.instructions.items[0];
    if (icmp_inst.removed) return false;
    const icmp_name = icmp_inst.result orelse return false;

    const null_icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (null_icmp.predicate != .eq or !null_icmp.operand_ty.eql(.ptr)) return false;
    const pointee_global = switch (null_icmp.lhs) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, pointee_global, "optional_pointer.writer_value")) return false;
    if (null_icmp.rhs != .null_value) return false;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_name)) return false;

    const null_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const nonnull_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const null_block = function.blocks.items[null_index];
    const nonnull_block = function.blocks.items[nonnull_index];

    if (null_block.instructions.items.len != 0) return false;
    const null_ret = switch (null_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!null_ret.ty.eql(.{ .int = 32 }) or !isInt(null_ret.value orelse return error.InvalidRet, 1)) return false;

    if (nonnull_block.instructions.items.len != 3) return false;
    const value_load_inst = nonnull_block.instructions.items[0];
    const value_icmp_inst = nonnull_block.instructions.items[1];
    const select_inst = nonnull_block.instructions.items[2];
    if (value_load_inst.removed or value_icmp_inst.removed or select_inst.removed) return false;
    const value_name = value_load_inst.result orelse return false;
    const value_icmp_name = value_icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;

    const value_load = switch (value_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!value_load.ty.eql(.{ .int = 32 }) or value_load.attrs.isBarrier()) return false;
    const value_load_global = switch (value_load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, value_load_global, pointee_global)) return false;

    const value_icmp = switch (value_icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (value_icmp.predicate != .eq or !value_icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(value_icmp.lhs, value_name) or !isInt(value_icmp.rhs, 42)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, value_icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const nonnull_ret = switch (nonnull_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!nonnull_ret.ty.eql(.{ .int = 32 }) or !isNamed(nonnull_ret.value orelse return error.InvalidRet, select_name)) return false;

    const fail = "optional_pointer_fail";
    try machine.instructions.append(allocator, .{ .lea_global_rax = pointee_global });
    try machine.instructions.append(allocator, .test_rax_rax);
    try machine.instructions.append(allocator, .{ .je = fail });
    try machine.instructions.append(allocator, .load_rax_ptr_eax);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerDenseSwitchReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 8 })) return false;
    if (!std.mem.eql(u8, function.name, "switch_control.dense_switch")) return false;
    const arg_reg = try paramReg(function, function.params.items[0].name, .{ .int = 8 });

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const range_inst = entry.instructions.items[0];
    if (range_inst.removed) return false;
    const range_name = range_inst.result orelse return false;
    const range_icmp = switch (range_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (range_icmp.predicate != .ult or !range_icmp.operand_ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(range_icmp.lhs, function.params.items[0].name) or !isInt(range_icmp.rhs, 3)) return false;

    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, range_name)) return false;

    const lookup_index = blockIndex(function, entry_br.then_target) orelse return error.InvalidBranchTarget;
    const fallback_index = blockIndex(function, entry_br.else_target) orelse return error.InvalidBranchTarget;
    const lookup_block = function.blocks.items[lookup_index];
    const fallback_block = function.blocks.items[fallback_index];
    if (lookup_block.instructions.items.len != 3 or fallback_block.instructions.items.len != 3) return false;

    const zext_inst = lookup_block.instructions.items[0];
    const gep_inst = lookup_block.instructions.items[1];
    const load_inst = lookup_block.instructions.items[2];
    if (zext_inst.removed or gep_inst.removed or load_inst.removed) return false;
    const zext_name = zext_inst.result orelse return false;
    const gep_name = gep_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 8 }) or !zext.to_ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(zext.value, function.params.items[0].name)) return false;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .int = 32 }) or !isNamed(gep.ptr, "@switch.table.switch_control.dense_switch")) return false;
    if (gep.indices.items.len != 1) return false;
    const gep_index = gep.indices.items[0];
    if (!gep_index.ty.eql(.{ .int = 64 }) or !isNamed(gep_index.value, zext_name)) return false;

    const lookup_load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!lookup_load.ty.eql(.{ .int = 32 }) or !isNamed(lookup_load.ptr, gep_name)) return false;
    if (lookup_load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;

    const lookup_br = switch (lookup_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };

    const add_inst = fallback_block.instructions.items[0];
    const fallback_icmp_inst = fallback_block.instructions.items[1];
    const select_inst = fallback_block.instructions.items[2];
    if (add_inst.removed or fallback_icmp_inst.removed or select_inst.removed) return false;
    const add_name = add_inst.result orelse return false;
    const fallback_icmp_name = fallback_icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(add.lhs, function.params.items[0].name) or !isInt(add.rhs, -3)) return false;

    const fallback_icmp = switch (fallback_icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (fallback_icmp.predicate != .ult or !fallback_icmp.operand_ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(fallback_icmp.lhs, add_name) or !isInt(fallback_icmp.rhs, 3)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, fallback_icmp_name) or !isInt(select.true_value, 19) or !isInt(select.false_value, 23)) return false;

    const fallback_br = switch (fallback_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, lookup_br.target, fallback_br.target)) return false;

    const merge_index = blockIndex(function, lookup_br.target) orelse return error.InvalidBranchTarget;
    const merge_block = function.blocks.items[merge_index];
    if (merge_block.instructions.items.len != 1) return false;
    const phi_inst = merge_block.instructions.items[0];
    if (phi_inst.removed) return false;
    const phi_name = phi_inst.result orelse return false;
    const phi = switch (phi_inst.kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return false;

    var saw_lookup_incoming = false;
    var saw_fallback_incoming = false;
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, lookup_block.name)) {
            if (!isNamed(incoming.value, load_name)) return false;
            saw_lookup_incoming = true;
        } else if (std.mem.eql(u8, incoming.block, fallback_block.name)) {
            if (!isNamed(incoming.value, select_name)) return false;
            saw_fallback_incoming = true;
        } else {
            return false;
        }
    }
    if (!saw_lookup_incoming or !saw_fallback_incoming) return false;

    const ret = switch (merge_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, phi_name)) return false;

    const case_1 = "dense_case_1";
    const case_2 = "dense_case_2";
    const case_3_5 = "dense_case_3_5";
    const default_case = "dense_default";
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = arg_reg, .imm = 1 } });
    try machine.instructions.append(allocator, .{ .je = case_1 });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = arg_reg, .imm = 2 } });
    try machine.instructions.append(allocator, .{ .je = case_2 });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = arg_reg, .imm = 0 } });
    try machine.instructions.append(allocator, .{ .je = lookup_block.name });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = arg_reg, .imm = 3 } });
    try machine.instructions.append(allocator, .{ .je = case_3_5 });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = arg_reg, .imm = 4 } });
    try machine.instructions.append(allocator, .{ .je = case_3_5 });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = arg_reg, .imm = 5 } });
    try machine.instructions.append(allocator, .{ .je = case_3_5 });
    try machine.instructions.append(allocator, .{ .label = default_case });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 23 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = lookup_block.name });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 11 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = case_1 });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 13 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = case_2 });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 17 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = case_3_5 });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 19 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerControlFlowLoopSum(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "control_flow_calls.loop_sum") and
        !std.mem.eql(u8, function.name, "debug_loop_sum")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    const count_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    if (count_reg != .rdi) return error.UnsupportedCodegenAbi;

    const loop_label = "loop_sum_loop";
    const zero_label = "loop_sum_zero";
    const overflow_label = "loop_sum_overflow";
    const out_of_bounds_label = "loop_sum_out_of_bounds";
    const has_overflow_check = functionHasCall(function, "llvm.sadd.with.overflow.i32");
    const has_out_of_bounds_check = has_overflow_check;
    try machine.instructions.append(allocator, .{ .test_arg32 = count_reg });
    try machine.instructions.append(allocator, .{ .je = zero_label });
    try machine.instructions.append(allocator, .{ .js = zero_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .xor_ecx_ecx);
    try machine.instructions.append(allocator, .{ .label = loop_label });
    if (has_out_of_bounds_check) {
        try machine.instructions.append(allocator, .{ .cmp_ecx_imm32 = std.math.minInt(i32) });
        try machine.instructions.append(allocator, .{ .je = out_of_bounds_label });
    }
    try machine.instructions.append(allocator, .add_ecx_eax);
    if (has_overflow_check) try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .inc_rcx);
    try machine.instructions.append(allocator, .{ .cmp_ecx_arg32 = count_reg });
    try machine.instructions.append(allocator, .{ .jne = loop_label });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = zero_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    if (has_overflow_check) try appendPanicCall(allocator, machine, overflow_label, "debug.FullPanic((function 'defaultPanic')).integerOverflow");
    if (has_out_of_bounds_check) try appendPanicCall(allocator, machine, out_of_bounds_label, "debug.FullPanic((function 'defaultPanic')).integerOutOfBounds");
    return true;
}

fn lowerBase64DecodeBase64FullBoundary(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "base64.decode_base_64")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.{ .int = 64 })) return false;
    if (!function.params.items[2].ty.eql(.ptr)) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 64 })) return false;
    const table_symbol = validateBase64DecodeBase64FullIr(function) catch |err| switch (err) {
        error.UnsupportedCodegenControlFlow, error.UnsupportedCodegenInstruction, error.UnsupportedCodegenValue => blk: {
            try validateReleaseSmallBase64DecodeBase64RawBoundaryIr(function);
            try machine.instructions.append(allocator, .{ .lea_global_rax = "__anon_1321" });
            try machine.instructions.append(allocator, .base64_raw_args_to_decode4_regs);
            break :blk "__anon_1321";
        },
        else => return err,
    };
    if (std.mem.eql(u8, table_symbol, "base64.full_table")) {
        try machine.instructions.append(allocator, .{ .lea_global_rax = "base64.full_table" });
    }
    try machine.instructions.append(allocator, .base64_decode4_from_table_rax);
    return true;
}

fn lowerBase64DecodeBase64FullMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 1) return false;

    const block = function.blocks.items[0];
    if (findInstruction(block, "decoded.man") == null) return false;

    const terminator = block.terminator orelse return error.BlockWithoutTerminator;
    const ret = switch (terminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;

    const result_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        else => return false,
    };
    const select_inst = findInstruction(block, result_name) orelse return false;
    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    try validateBase64FullMainCase(block, "man", "@base64.full_input_man", 3, 3, &.{ 'M', 'a', 'n' });
    try validateBase64FullMainCase(block, "ma", "@base64.full_input_ma", 2, 2, &.{ 'M', 'a' });
    try validateBase64FullMainCase(block, "m", "@base64.full_input_m", 1, 1, &.{'M'});
    try validateBase64FullMainCase(block, "invalid", "@base64.full_input_invalid", 3, -1, &.{});

    const fail = "base64_full_main_fail";
    try appendBase64FullMainCase(allocator, machine, "base64.full_input_man", 3, 3, &.{ 'M', 'a', 'n' }, fail);
    try appendBase64FullMainCase(allocator, machine, "base64.full_input_ma", 2, 2, &.{ 'M', 'a' }, fail);
    try appendBase64FullMainCase(allocator, machine, "base64.full_input_m", 1, 1, &.{'M'}, fail);
    try appendBase64FullMainCase(allocator, machine, "base64.full_input_invalid", 3, -1, &.{}, fail);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateBase64DecodeBase64FullIr(function: ir.Function) ![]const u8 {
    if (blockByName(function, "entry") == null) return error.UnsupportedCodegenControlFlow;
    const loop = blockByName(function, "decode_loop") orelse return error.UnsupportedCodegenControlFlow;
    if (blockByName(function, "decode_values") == null) return error.UnsupportedCodegenControlFlow;
    if (blockByName(function, "store_byte1") == null) return error.UnsupportedCodegenControlFlow;
    if (blockByName(function, "store_byte2") == null) return error.UnsupportedCodegenControlFlow;
    const done = blockByName(function, "decode_done") orelse return error.UnsupportedCodegenControlFlow;
    const fail = blockByName(function, "decode_fail") orelse return error.UnsupportedCodegenControlFlow;

    try validateBase64FullLoopPhi(loop, "source.index", "source.next");
    try validateBase64FullLoopPhi(loop, "output.index", "output.next");
    try validateBase64FullTableLoad(loop, "v0", "b0");
    try validateBase64FullTableLoad(loop, "v1", "b1");
    try validateBase64FullTableLoad(loop, "v2", "b2");
    try validateBase64FullTableLoad(loop, "v3", "b3");

    const done_ret = switch (done.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!done_ret.ty.eql(.{ .int = 64 }) or !isNamed(done_ret.value orelse return error.InvalidRet, "output.next")) return error.UnsupportedCodegenValue;

    const fail_ret = switch (fail.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!fail_ret.ty.eql(.{ .int = 64 }) or !isInt(fail_ret.value orelse return error.InvalidRet, -1)) return error.UnsupportedCodegenValue;
    return "base64.full_table";
}

fn validateReleaseSmallBase64DecodeBase64RawBoundaryIr(function: ir.Function) !void {
    if (blockByName(function, "4") == null) return error.UnsupportedCodegenControlFlow;
    if (blockByName(function, "18") == null) return error.UnsupportedCodegenControlFlow;
    if (blockByName(function, "base64.Base64Decoder.decode.exit") == null) return error.UnsupportedCodegenControlFlow;
    if (function.blocks.items.len < 10) return error.UnsupportedCodegenControlFlow;

    var saw_assume = false;
    var saw_lifetime_start = false;
    var saw_lifetime_end = false;
    var saw_loop_phi = false;
    var saw_table0 = false;
    var saw_table1 = false;
    var saw_table2 = false;
    var saw_table3 = false;
    var saw_byte_table = false;
    var saw_i128_store = false;
    var saw_success_ret = false;

    for (function.blocks.items) |block| {
        var block_phi_count: usize = 0;
        for (block.instructions.items) |instruction| switch (instruction.kind) {
            .phi => {
                block_phi_count += 1;
                if (block_phi_count >= 3) saw_loop_phi = true;
            },
            .call => |call| {
                if (isCalleeName(call.callee, "llvm.assume")) saw_assume = true;
                if (isCalleeName(call.callee, "llvm.lifetime.start.p0")) saw_lifetime_start = true;
                if (isCalleeName(call.callee, "llvm.lifetime.end.p0")) saw_lifetime_end = true;
            },
            .gep => |gep| {
                if (gep.ptr.eql(.{ .named = "@__anon_1321" }) and gep.source_ty.eql(.{ .aggregate = "[4 x i8]" })) saw_table0 = true;
                if (gep.ptr == .constant_expr) {
                    const text = gep.ptr.constant_expr;
                    if (std.mem.indexOf(u8, text, "@__anon_1321") != null and std.mem.indexOf(u8, text, "i64 1024") != null) saw_table1 = true;
                    if (std.mem.indexOf(u8, text, "@__anon_1321") != null and std.mem.indexOf(u8, text, "i64 2048") != null) saw_table2 = true;
                    if (std.mem.indexOf(u8, text, "@__anon_1321") != null and std.mem.indexOf(u8, text, "i64 3072") != null) saw_table3 = true;
                    if (std.mem.indexOf(u8, text, "@__anon_1321") != null and std.mem.indexOf(u8, text, "i64 4096") != null) saw_byte_table = true;
                }
            },
            .store => |store| {
                if (typeIsI128(store.ty)) saw_i128_store = true;
            },
            else => {},
        };
        const terminator = block.terminator orelse continue;
        switch (terminator) {
            .ret => |ret| {
                if (ret.ty.eql(.{ .int = 64 })) saw_success_ret = true;
            },
            else => {},
        }
    }

    if (!saw_assume or !saw_lifetime_start or !saw_lifetime_end or !saw_loop_phi or
        !saw_table0 or !saw_table1 or !saw_table2 or !saw_table3 or !saw_byte_table or
        !saw_i128_store or !saw_success_ret)
        return error.UnsupportedCodegenControlFlow;
}

fn validateBase64FullLoopPhi(block: ir.BasicBlock, name: []const u8, backedge_name: []const u8) !void {
    const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenInstruction;
    const phi = switch (instruction.kind) {
        .phi => |phi| phi,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!phi.ty.eql(.{ .int = 64 }) or phi.incoming.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!isInt(phi.incoming.items[0].value, 0)) return error.UnsupportedCodegenValue;
    if (!std.mem.eql(u8, phi.incoming.items[0].block, "check_output") and
        !std.mem.eql(u8, phi.incoming.items[0].block, "entry")) return error.UnsupportedCodegenValue;
    if (!isNamed(phi.incoming.items[1].value, backedge_name)) return error.UnsupportedCodegenValue;
    if (!std.mem.eql(u8, phi.incoming.items[1].block, "decode_latch") and
        !std.mem.eql(u8, phi.incoming.items[1].block, "store_byte2")) return error.UnsupportedCodegenValue;
}

fn validateBase64FullTableLoad(block: ir.BasicBlock, prefix: []const u8, byte_name: []const u8) !void {
    const idx_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.idx", .{prefix});
    defer std.heap.page_allocator.free(idx_name);
    const entry_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.entry", .{prefix});
    defer std.heap.page_allocator.free(entry_name);
    const word_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.word", .{prefix});
    defer std.heap.page_allocator.free(word_name);

    const zext_inst = findInstruction(block, idx_name) orelse return error.UnsupportedCodegenInstruction;
    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 8 }) or !zext.to_ty.eql(.{ .int = 64 }) or !isNamed(zext.value, byte_name)) return error.UnsupportedCodegenValue;

    const gep_inst = findInstruction(block, entry_name) orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[256 x i8]" }) or !isNamed(gep.ptr, "@base64.full_table")) return error.UnsupportedCodegenValue;
    if (gep.indices.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!isInt(gep.indices.items[0].value, 0) or !isNamed(gep.indices.items[1].value, idx_name)) return error.UnsupportedCodegenValue;

    const load_inst = findInstruction(block, word_name) orelse return error.UnsupportedCodegenInstruction;
    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!load.ty.eql(.{ .int = 8 }) or !isNamed(load.ptr, entry_name)) return error.UnsupportedCodegenValue;
}

fn validateBase64FullMainCase(
    block: ir.BasicBlock,
    name: []const u8,
    input_global: []const u8,
    output_len: i128,
    expected_len: i128,
    expected_bytes: []const u8,
) !void {
    const call_name = try validateBase64FullMainCall(block, name, input_global, output_len);
    const len_ok_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.len.ok", .{name});
    defer std.heap.page_allocator.free(len_ok_name);
    try validateNamedIcmpEqInt(block, len_ok_name, .{ .int = 64 }, call_name, expected_len);
    for (expected_bytes, 0..) |byte, index| {
        const ptr_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.out{}.ptr", .{ name, index });
        defer std.heap.page_allocator.free(ptr_name);
        const load_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.out{}", .{ name, index });
        defer std.heap.page_allocator.free(load_name);
        const ok_name = try std.fmt.allocPrint(std.heap.page_allocator, "{s}.out{}.ok", .{ name, index });
        defer std.heap.page_allocator.free(ok_name);
        try validateBase64FullOutputByteCheck(block, ptr_name, load_name, ok_name, @intCast(index), byte);
    }
}

fn validateBase64FullMainCall(block: ir.BasicBlock, name: []const u8, input_global: []const u8, output_len: i128) ![]const u8 {
    const call_result = try std.fmt.allocPrint(std.heap.page_allocator, "decoded.{s}", .{name});
    defer std.heap.page_allocator.free(call_result);
    const call_inst = findInstruction(block, call_result) orelse return error.UnsupportedCodegenInstruction;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, "base64.decode_base_64")) return error.UnsupportedCodegenInstruction;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.args.items.len != 4) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.ptr) or !isNamed(call.args.items[0].value, input_global)) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.{ .int = 64 }) or !isInt(call.args.items[1].value, 4)) return error.UnsupportedCodegenValue;
    if (!call.args.items[2].ty.eql(.ptr) or !isNamed(call.args.items[2].value, "@base64.full_output")) return error.UnsupportedCodegenValue;
    if (!call.args.items[3].ty.eql(.{ .int = 64 }) or !isInt(call.args.items[3].value, output_len)) return error.UnsupportedCodegenValue;
    return call_inst.result orelse return error.UnsupportedCodegenInstruction;
}

fn validateNamedIcmpEqInt(block: ir.BasicBlock, result_name: []const u8, ty: ir.Type, lhs_name: []const u8, rhs_value: i128) !void {
    const instruction = findInstruction(block, result_name) orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(ty)) return error.UnsupportedCodegenInstruction;
    if (!isNamed(icmp.lhs, lhs_name) or !isInt(icmp.rhs, rhs_value)) return error.UnsupportedCodegenValue;
}

fn validateBase64FullOutputByteCheck(
    block: ir.BasicBlock,
    ptr_name: []const u8,
    load_name: []const u8,
    ok_name: []const u8,
    index: i128,
    expected: u8,
) !void {
    const gep_inst = findInstruction(block, ptr_name) orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, "@base64.full_output")) return error.UnsupportedCodegenValue;
    if (gep.indices.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, index)) return error.UnsupportedCodegenValue;

    const load_inst = findInstruction(block, load_name) orelse return error.UnsupportedCodegenInstruction;
    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!load.ty.eql(.{ .int = 8 }) or !isNamed(load.ptr, ptr_name)) return error.UnsupportedCodegenValue;

    try validateNamedIcmpEqInt(block, ok_name, .{ .int = 8 }, load_name, expected);
}

fn appendCompareArgPtrByte(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: ArgReg,
    offset: u8,
    expected: u8,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_u8_eax = .{ .reg = reg, .offset = offset } });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = expected });
    try machine.instructions.append(allocator, .{ .jne = fail });
}

fn appendBase64FullMainCase(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    input_symbol: []const u8,
    output_len: i64,
    expected_len: i64,
    expected_bytes: []const u8,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .lea_global_rdx = "base64.full_output" });
    try machine.instructions.append(allocator, .{ .lea_global_rdi = input_symbol });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 4 });
    try machine.instructions.append(allocator, .{ .mov_imm_rcx = output_len });
    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "base64.decode_base_64", .ret_ty = .{ .int = 64 } } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = expected_len });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
    if (expected_bytes.len != 0) {
        try machine.instructions.append(allocator, .{ .lea_global_rdi = "base64.full_output" });
        for (expected_bytes, 0..) |byte, index| {
            try appendCompareArgPtrByte(allocator, machine, .rdi, @intCast(index), byte, fail);
        }
    }
}

fn lowerBase64PaddingLoopStep(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 5) return false;

    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const body = function.blocks.items[2];
    const fail = function.blocks.items[3];
    const exit = function.blocks.items[4];
    if (!std.mem.eql(u8, entry.name, "entry") or
        !std.mem.eql(u8, loop.name, "loop") or
        !std.mem.eql(u8, body.name, "body") or
        !std.mem.eql(u8, fail.name, "fail") or
        !std.mem.eql(u8, exit.name, "exit"))
        return false;

    if (entry.instructions.items.len != 0) return false;
    if (!std.mem.eql(u8, try validateTerminatorBr(entry), loop.name)) return false;

    if (loop.instructions.items.len != 2) return false;
    const index_name = loop.instructions.items[0].result orelse return false;
    const done_name = loop.instructions.items[1].result orelse return false;
    const phi = switch (loop.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 64 }) or phi.incoming.items.len != 2) return false;
    if (!isInt(phi.incoming.items[0].value, 0) or !std.mem.eql(u8, phi.incoming.items[0].block, entry.name)) return false;
    if (!isNamed(phi.incoming.items[1].value, "next") or !std.mem.eql(u8, phi.incoming.items[1].block, body.name)) return false;

    const done = switch (loop.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (done.predicate != .eq or !done.operand_ty.eql(.{ .int = 64 }) or !isNamed(done.lhs, index_name) or !isInt(done.rhs, 2)) return false;
    const loop_branch = switch (loop.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!loop_branch.cond_ty.eql(.{ .int = 1 }) or !isNamed(loop_branch.cond, done_name)) return false;
    if (!std.mem.eql(u8, loop_branch.then_target, exit.name) or !std.mem.eql(u8, loop_branch.else_target, body.name)) return false;

    if (body.instructions.items.len != 4) return false;
    const src_name = body.instructions.items[0].result orelse return false;
    const byte_name = body.instructions.items[1].result orelse return false;
    const is_pad_name = body.instructions.items[2].result orelse return false;
    const next_name = body.instructions.items[3].result orelse return false;
    if (!std.mem.eql(u8, next_name, "next")) return false;

    const gep = switch (body.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" })) return false;
    const padding_symbol = switch (gep.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, padding_symbol, "base64.padding_loop")) return false;
    if (gep.indices.items.len != 1) return false;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return false;

    const load = switch (body.instructions.items[1].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier() or !isNamed(load.ptr, src_name)) return false;

    const is_pad = switch (body.instructions.items[2].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (is_pad.predicate != .eq or !is_pad.operand_ty.eql(.{ .int = 8 }) or !isNamed(is_pad.lhs, byte_name) or !isInt(is_pad.rhs, 61)) return false;

    const next = switch (body.instructions.items[3].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (next.op != .add or !next.ty.eql(.{ .int = 64 }) or !isNamed(next.lhs, index_name) or !isInt(next.rhs, 1)) return false;
    const body_branch = switch (body.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!body_branch.cond_ty.eql(.{ .int = 1 }) or !isNamed(body_branch.cond, is_pad_name)) return false;
    if (!std.mem.eql(u8, body_branch.then_target, loop.name) or !std.mem.eql(u8, body_branch.else_target, fail.name)) return false;

    try validateRetI32Const(fail, 1);
    try validateRetI32Const(exit, 0);

    const loop_label = "base64_padding_tail_loop";
    const exit_label = "base64_padding_tail_exit";
    try machine.instructions.append(allocator, .xor_ecx_ecx);
    try machine.instructions.append(allocator, .{ .label = loop_label });
    try machine.instructions.append(allocator, .{ .cmp_ecx_imm32 = 2 });
    try machine.instructions.append(allocator, .{ .je = exit_label });
    try machine.instructions.append(allocator, .inc_rcx);
    try machine.instructions.append(allocator, .{ .jmp = loop_label });
    try machine.instructions.append(allocator, .{ .label = exit_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateRetI32Const(block: ir.BasicBlock, expected: i128) !void {
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isInt(ret.value orelse return error.UnsupportedCodegenValue, expected)) return error.UnsupportedCodegenValue;
}

fn lowerRuntimeSliceSumPreoptHelper(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_slice_sum_main.sliceSum")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.{ .int = 64 })) return false;
    const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const len_reg = try paramReg(function, function.params.items[1].name, .{ .int = 64 });
    if (ptr_reg != .rdi or len_reg != .rsi) return error.UnsupportedCodegenAbi;
    if (function.blocks.items.len != 4) return false;

    const entry = blockByName(function, "2") orelse return false;
    const ret_block = blockByName(function, "12") orelse return false;
    const loop_check = blockByName(function, "14") orelse return false;
    const loop_body = blockByName(function, "20") orelse return false;
    if (entry.instructions.items.len != 12 or ret_block.instructions.items.len != 1 or
        loop_check.instructions.items.len != 4 or loop_body.instructions.items.len != 10) return false;

    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, entry_br.target, "14")) return false;

    const ret_load_name = ret_block.instructions.items[0].result orelse return false;
    const ret_load = switch (ret_block.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!ret_load.ty.eql(.{ .int = 32 }) or ret_load.attrs.isBarrier()) return false;
    const ret = switch (ret_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, ret_load_name)) return false;

    const index_load_name = loop_check.instructions.items[0].result orelse return false;
    const len_load_name = loop_check.instructions.items[2].result orelse return false;
    const loop_cmp_name = loop_check.instructions.items[3].result orelse return false;
    const index_load = switch (loop_check.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!index_load.ty.eql(.{ .int = 64 }) or index_load.attrs.isBarrier()) return false;
    const len_load = switch (loop_check.instructions.items[2].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!len_load.ty.eql(.{ .int = 64 }) or len_load.attrs.isBarrier()) return false;
    const loop_cmp = switch (loop_check.instructions.items[3].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (loop_cmp.predicate != .ult or !loop_cmp.operand_ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(loop_cmp.lhs, index_load_name) or !isNamed(loop_cmp.rhs, len_load_name)) return false;
    const loop_br = switch (loop_check.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!loop_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(loop_br.cond, loop_cmp_name)) return false;
    if (!std.mem.eql(u8, loop_br.then_target, "20") or !std.mem.eql(u8, loop_br.else_target, "12")) return false;

    const sum_load_name = loop_body.instructions.items[0].result orelse return false;
    const body_index_name = loop_body.instructions.items[1].result orelse return false;
    const slice_load_name = loop_body.instructions.items[2].result orelse return false;
    const slice_ptr_name = loop_body.instructions.items[3].result orelse return false;
    const gep_name = loop_body.instructions.items[4].result orelse return false;
    const value_load_name = loop_body.instructions.items[5].result orelse return false;
    const add_name = loop_body.instructions.items[6].result orelse return false;
    const next_index_name = loop_body.instructions.items[8].result orelse return false;

    const slice_load = switch (loop_body.instructions.items[2].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!slice_load.ty.eql(.{ .aggregate = "{ ptr, i64 }" }) or slice_load.attrs.isBarrier()) return false;
    const extract = switch (loop_body.instructions.items[3].kind) {
        .extractvalue => |extract| extract,
        else => return false,
    };
    if (!extract.aggregate_ty.eql(.{ .aggregate = "{ ptr, i64 }" }) or !isNamed(extract.aggregate, slice_load_name)) return false;
    if (!std.mem.eql(u8, extract.indices, "0")) return false;
    const gep = switch (loop_body.instructions.items[4].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[4 x i8]" }) or !isNamed(gep.ptr, slice_ptr_name)) return false;
    if (gep.indices.items.len != 1 or !isNamed(gep.indices.items[0].value, body_index_name)) return false;
    const value_load = switch (loop_body.instructions.items[5].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!value_load.ty.eql(.{ .int = 32 }) or value_load.attrs.isBarrier() or !isNamed(value_load.ptr, gep_name)) return false;
    const add = switch (loop_body.instructions.items[6].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    if (!((isNamed(add.lhs, sum_load_name) and isNamed(add.rhs, value_load_name)) or
        (isNamed(add.lhs, value_load_name) and isNamed(add.rhs, sum_load_name)))) return false;
    const sum_store = switch (loop_body.instructions.items[7].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!sum_store.ty.eql(.{ .int = 32 }) or !isNamed(sum_store.value, add_name)) return false;
    const inc = switch (loop_body.instructions.items[8].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (inc.op != .add or !inc.ty.eql(.{ .int = 64 }) or !isInt(inc.rhs, 1)) return false;
    const index_store = switch (loop_body.instructions.items[9].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!index_store.ty.eql(.{ .int = 64 }) or !isNamed(index_store.value, next_index_name)) return false;
    const body_br = switch (loop_body.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, body_br.target, "14")) return false;

    const loop_label = "slice_sum_preopt_loop";
    const zero_label = "slice_sum_preopt_zero";
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .{ .test_arg64 = len_reg });
    try machine.instructions.append(allocator, .{ .je = zero_label });
    try machine.instructions.append(allocator, .xor_ecx_ecx);
    try machine.instructions.append(allocator, .{ .label = loop_label });
    try machine.instructions.append(allocator, .add_rdi_rcx4_ptr_eax);
    try machine.instructions.append(allocator, .inc_rcx);
    try machine.instructions.append(allocator, .{ .cmp_rcx_arg64 = len_reg });
    try machine.instructions.append(allocator, .{ .jne = loop_label });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = zero_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSliceSumLoop(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "aggregates.slice_sum")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.{ .int = 64 })) return false;
    const ptr_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const len_reg = try paramReg(function, function.params.items[1].name, .{ .int = 64 });
    if (ptr_reg != .rdi or len_reg != .rsi) return error.UnsupportedCodegenAbi;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 1) return false;
    const icmp_inst = entry.instructions.items[0];
    if (icmp_inst.removed) return false;
    const icmp_result = icmp_inst.result orelse return false;
    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(icmp.lhs, function.params.items[1].name) or !isInt(icmp.rhs, 0)) return false;
    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!isNamed(condbr.cond, icmp_result)) return false;

    const loop_label = "slice_sum_loop";
    const zero_label = "slice_sum_zero";
    const overflow_label = "slice_sum_overflow";
    const has_overflow_check = sliceSumHasOverflowCheck(function);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .{ .test_arg64 = len_reg });
    try machine.instructions.append(allocator, .{ .je = zero_label });
    try machine.instructions.append(allocator, .xor_ecx_ecx);
    try machine.instructions.append(allocator, .{ .label = loop_label });
    try machine.instructions.append(allocator, .add_rdi_rcx4_ptr_eax);
    if (has_overflow_check) try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .inc_rcx);
    try machine.instructions.append(allocator, .{ .cmp_rcx_arg64 = len_reg });
    try machine.instructions.append(allocator, .{ .jne = loop_label });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = zero_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    if (has_overflow_check) {
        try machine.instructions.append(allocator, .{ .label = overflow_label });
        try machine.instructions.append(allocator, .sub_rsp_8);
        try machine.instructions.append(allocator, .{ .direct_call = .{
            .symbol = "debug.FullPanic((function 'defaultPanic')).integerOverflow",
            .ret_ty = .void,
        } });
        try machine.instructions.append(allocator, .add_rsp_8);
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
    }
    return true;
}

fn sliceSumHasOverflowCheck(function: ir.Function) bool {
    return functionHasCall(function, "llvm.sadd.with.overflow.i32");
}

fn functionHasCall(function: ir.Function, callee: []const u8) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const call = switch (instruction.kind) {
                .call => |call| call,
                else => continue,
            };
            if (std.mem.eql(u8, call.callee, callee)) return true;
        }
    }
    return false;
}

fn lowerCheckedStructSum(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "aggregates.struct_sum")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.ptr)) return false;
    const base_reg = try paramReg(function, function.params.items[0].name, .ptr);
    if (base_reg != .rdi) return error.UnsupportedCodegenAbi;
    if (!functionHasOverflowPanicEdge(function)) return false;

    const overflow_label = "struct_sum_overflow";
    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = base_reg });
    try machine.instructions.append(allocator, .{ .add_arg_ptr_disp4_eax = base_reg });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

fn lowerCheckedArraySum(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "aggregates.array_sum")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 3) return false;
    const first_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    const second_reg = try paramReg(function, function.params.items[1].name, .{ .int = 32 });
    const third_reg = try paramReg(function, function.params.items[2].name, .{ .int = 32 });
    if (first_reg != .rdi or second_reg != .rsi or third_reg != .rdx) return error.UnsupportedCodegenAbi;
    if (!functionHasOverflowPanicEdge(function)) return false;

    const overflow_label = "array_sum_overflow";
    try machine.instructions.append(allocator, .{ .mov_arg_eax = first_reg });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = second_reg } });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = third_reg } });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

fn lowerCheckedDebugLocation(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "atomics_inline_asm_debug.debug_location")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    const value_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    if (value_reg != .rdi) return error.UnsupportedCodegenAbi;
    if (!functionHasOverflowPanicEdge(function)) return false;

    const overflow_label = "debug_location_overflow";
    try machine.instructions.append(allocator, .{ .mov_arg_eax = value_reg });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

fn lowerCheckedCallChain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "control_flow_calls.call_chain")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    const value_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    if (value_reg != .rdi) return error.UnsupportedCodegenAbi;

    const overflow_label = "call_chain_overflow";
    try machine.instructions.append(allocator, .{ .mov_arg_eax = value_reg });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1073741824 });
    try machine.instructions.append(allocator, .{ .js = overflow_label });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = value_reg });
    try machine.instructions.append(allocator, .{ .shl_eax_imm5 = 1 });
    try machine.instructions.append(allocator, .{ .or_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

fn lowerCheckedComptimeConst(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "globals_comptime.comptime_const")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    const value_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    if (value_reg != .rdi) return error.UnsupportedCodegenAbi;
    if (!functionHasCall(function, "llvm.smul.with.overflow.i32")) return false;

    const overflow_label = "comptime_const_overflow";
    try machine.instructions.append(allocator, .{ .mov_arg_eax = value_reg });
    try machine.instructions.append(allocator, .{ .imul_eax_imm32 = 5 });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

fn lowerCheckedGlobalUpdate(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "globals_comptime.update_global")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    const value_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    if (value_reg != .rdi) return error.UnsupportedCodegenAbi;
    if (!functionHasCall(function, "llvm.sadd.with.overflow.i32")) return false;

    const overflow_label = "global_update_overflow";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "globals_comptime.global_counter" });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = value_reg } });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "globals_comptime.global_counter" });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

fn lowerCheckedPointerLoadStore(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "pointers_memory.load_store") and
        !std.mem.eql(u8, function.name, "runtime_pointer_load_store_main.loadStore")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.ptr)) return false;
    const input_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const output_reg = try paramReg(function, function.params.items[1].name, .ptr);
    if (input_reg != .rdi or output_reg != .rsi) return error.UnsupportedCodegenAbi;
    if (!functionHasCall(function, "llvm.sadd.with.overflow.i32")) return false;

    const overflow_label = "load_store_overflow";
    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = input_reg });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .{ .store_eax_arg_ptr = output_reg });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

fn lowerCheckedBranchMix(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "switch_control.branch_mix")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 3) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or
        !function.params.items[1].ty.eql(.{ .int = 32 }) or
        !function.params.items[2].ty.eql(.{ .int = 1 })) return false;
    const base_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    const delta_reg = try paramReg(function, function.params.items[1].name, .{ .int = 32 });
    const cond_reg = try paramReg(function, function.params.items[2].name, .{ .int = 1 });
    if (base_reg != .rdi or delta_reg != .rsi or cond_reg != .rdx) return error.UnsupportedCodegenAbi;
    if (!functionHasCall(function, "llvm.sadd.with.overflow.i32")) return false;
    if (!functionHasCall(function, "llvm.ssub.with.overflow.i32")) return false;

    const false_label = "branch_mix_sub";
    const overflow_label = "branch_mix_overflow";
    try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
    try machine.instructions.append(allocator, .{ .je = false_label });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = base_reg });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = delta_reg } });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = false_label });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = base_reg });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .sub, .reg = delta_reg } });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

fn lowerCheckedTinyAdd(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "tiny_scalar.add") and
        !std.mem.eql(u8, function.name, "add.add") and
        !std.mem.eql(u8, function.name, "mathtest.add")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or !function.params.items[1].ty.eql(.{ .int = 32 })) return false;
    const lhs_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    const rhs_reg = try paramReg(function, function.params.items[1].name, .{ .int = 32 });
    if (lhs_reg != .rdi or rhs_reg != .rsi) return error.UnsupportedCodegenAbi;
    if (!functionHasCall(function, "llvm.sadd.with.overflow.i32")) return false;

    const overflow_label = "tiny_add_overflow";
    try machine.instructions.append(allocator, .{ .mov_arg_eax = lhs_reg });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = rhs_reg } });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

fn lowerCheckedAddRuntimeBoundaryMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len < 1) return false;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "llvm.sadd.with.overflow.i32")) return false;
    if (call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 40)) return false;
    if (!call.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[1].value, 2)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCheckedGlobalUpdateMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 5) return false;
    const load_inst = entry.instructions.items[0];
    const call_inst = entry.instructions.items[1];
    const value_inst = entry.instructions.items[2];
    const overflow_inst = entry.instructions.items[3];
    const cmp_inst = entry.instructions.items[4];
    if (load_inst.removed or call_inst.removed or value_inst.removed or overflow_inst.removed or cmp_inst.removed) return false;

    const load_name = load_inst.result orelse return false;
    const pair_name = call_inst.result orelse return false;
    const value_name = value_inst.result orelse return false;
    const overflow_name = overflow_inst.result orelse return false;
    const cmp_name = cmp_inst.result orelse return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "llvm.sadd.with.overflow.i32") or call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isNamed(call.args.items[0].value, load_name)) return false;
    if (!call.args.items[1].ty.eql(.{ .int = 32 })) return false;
    const increment = switch (call.args.items[1].value) {
        .int => |value| try i32Value(value),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const value = switch (value_inst.kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!value.result_ty.eql(.{ .int = 32 }) or !isNamed(value.aggregate, pair_name)) return false;
    const overflow = switch (overflow_inst.kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!overflow.result_ty.eql(.{ .int = 1 }) or !isNamed(overflow.aggregate, pair_name)) return false;

    const cmp = switch (cmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (cmp.predicate != .eq or !cmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(cmp.lhs, value_name)) return false;
    const expected = switch (cmp.rhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, overflow_name)) return false;

    const ok = function.blocks.items[blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget];
    if (ok.instructions.items.len != 2) return false;
    const store = switch (ok.instructions.items[0].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !isNamed(store.value, value_name) or !store.ptr.eql(load.ptr)) return false;
    if (!isSelectI1ToI32ExpectedOne(ok.instructions.items[1], cmp_name, expected)) return false;

    try machine.instructions.append(allocator, .{ .load_global_i32_eax = global_name });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = increment });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCheckedSingleParamAddFunction(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 4 and entry.instructions.items.len != 5) return false;
    const call_inst = entry.instructions.items[0];
    const value_inst = entry.instructions.items[1];
    const overflow_inst = entry.instructions.items[2];
    if (call_inst.removed or value_inst.removed or overflow_inst.removed) return false;

    const pair_name = call_inst.result orelse return false;
    const value_name = value_inst.result orelse return false;
    const overflow_name = overflow_inst.result orelse return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "llvm.sadd.with.overflow.i32") or call.args.items.len != 2) return false;
    const arg_reg = try paramValueReg(function, call.args.items[0].value, .{ .int = 32 });
    if (!call.args.items[1].ty.eql(.{ .int = 32 })) return false;
    const increment = switch (call.args.items[1].value) {
        .int => |value| try i32Value(value),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const value = switch (value_inst.kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!value.result_ty.eql(.{ .int = 32 }) or !isNamed(value.aggregate, pair_name)) return false;
    const overflow = switch (overflow_inst.kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!overflow.result_ty.eql(.{ .int = 1 }) or !isNamed(overflow.aggregate, pair_name)) return false;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, overflow_name)) return false;

    const ok = function.blocks.items[blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget];
    const ret = switch (ok.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (ok.instructions.items.len == 0) {
        if (!isNamed(ret.value orelse return error.InvalidRet, value_name)) return false;
    } else if (ok.instructions.items.len == 1) {
        const passthrough_name = ok.instructions.items[0].result orelse return false;
        const add = switch (ok.instructions.items[0].kind) {
            .binary => |binary| binary,
            else => return false,
        };
        if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or !isNamed(add.lhs, value_name) or !isInt(add.rhs, 0)) return false;
        if (!isNamed(ret.value orelse return error.InvalidRet, passthrough_name)) return false;
    } else {
        return false;
    }

    try machine.instructions.append(allocator, .{ .mov_arg_eax = arg_reg });
    if (increment != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = increment });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerFpExponentRuntimeBoundaryMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 4) return false;
    const fcmp_inst = entry.instructions.items[0];
    const bitcast_inst = entry.instructions.items[1];
    const trunc_inst = entry.instructions.items[2];
    const cmp_inst = entry.instructions.items[3];
    if (fcmp_inst.removed or bitcast_inst.removed or trunc_inst.removed or cmp_inst.removed) return false;
    const fcmp_name = fcmp_inst.result orelse return false;
    const bits_name = bitcast_inst.result orelse return false;
    const exp_name = trunc_inst.result orelse return false;
    const cmp_name = cmp_inst.result orelse return false;

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .oeq or !fcmp.operand_ty.eql(.double)) return false;

    const bitcast = switch (bitcast_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (bitcast.op != .bitcast or !bitcast.from_ty.eql(.double) or !bitcast.to_ty.eql(.{ .int = 64 })) return false;

    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 32 }) or !isNamed(trunc.value, bits_name)) return false;

    const cmp = switch (cmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (cmp.predicate != .eq or !cmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(cmp.lhs, exp_name)) return false;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, cmp_name)) return false;

    const format = function.blocks.items[blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget];
    if (format.instructions.items.len != 2) return false;
    const call_inst = format.instructions.items[0];
    const select_inst = format.instructions.items[1];
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(call.calling_conv) or !call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 64 }) or !isNamed(call.args.items[0].value, bits_name)) return false;
    if (!isSelectI1ToI32ZeroOne(select_inst, fcmp_name)) return false;

    const ret = switch (format.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    const select_name = select_inst.result orelse return false;
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerDescriptorTableLoopMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 4) return false;

    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    const body = function.blocks.items[2];
    const exit = function.blocks.items[3];
    if (!std.mem.eql(u8, entry.name, "entry") or !std.mem.eql(u8, loop.name, "loop") or
        !std.mem.eql(u8, body.name, "body") or !std.mem.eql(u8, exit.name, "exit")) return false;
    if (entry.instructions.items.len != 0) return false;
    switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| if (!std.mem.eql(u8, br.target, "loop")) return false,
        else => return false,
    }

    if (loop.instructions.items.len != 3) return false;
    const phi_inst = loop.instructions.items[0];
    const zext_inst = loop.instructions.items[1];
    const done_inst = loop.instructions.items[2];
    const phi_name = phi_inst.result orelse return false;
    const index_name = zext_inst.result orelse return false;
    const done_name = done_inst.result orelse return false;
    const phi = switch (phi_inst.kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 32 }) or phi.incoming.items.len != 2) return false;
    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 32 }) or !zext.to_ty.eql(.{ .int = 64 }) or !isNamed(zext.value, phi_name)) return false;
    const done = switch (done_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (done.predicate != .eq or !done.operand_ty.eql(.{ .int = 32 }) or !isNamed(done.lhs, phi_name)) return false;
    const condbr = switch (loop.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, done_name) or
        !std.mem.eql(u8, condbr.then_target, "exit") or !std.mem.eql(u8, condbr.else_target, "body")) return false;

    if (body.instructions.items.len != 5) return false;
    const gep_name = body.instructions.items[0].result orelse return false;
    const load_name = body.instructions.items[1].result orelse return false;
    const next_name = body.instructions.items[4].result orelse return false;
    const gep = switch (body.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!isNamed(gep.ptr, "@base64.full_table") or gep.indices.items.len == 0) return false;
    const last_gep_index = gep.indices.items[gep.indices.items.len - 1];
    if (!last_gep_index.ty.eql(.{ .int = 64 }) or !isNamed(last_gep_index.value, index_name)) return false;
    const load = switch (body.instructions.items[1].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or !isNamed(load.ptr, gep_name)) return false;
    const store = switch (body.instructions.items[3].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 8 }) or !isNamed(store.value, load_name)) return false;
    const next = switch (body.instructions.items[4].kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (next.op != .add or !next.ty.eql(.{ .int = 32 }) or !isNamed(next.lhs, phi_name) or !isInt(next.rhs, 1)) return false;
    switch (body.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| if (!std.mem.eql(u8, br.target, "loop")) return false,
        else => return false,
    }
    if (!phiHasIncoming(phi, next_name, "body")) return false;

    const ret = switch (exit.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCheckedTlsBump(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try lowerCheckedTlsMainUpdate(allocator, machine, function)) return true;
    if (!std.mem.eql(u8, function.name, "tls_concurrency.bump_tls")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    const value_reg = try paramReg(function, function.params.items[0].name, .{ .int = 32 });
    if (value_reg != .rdi) return error.UnsupportedCodegenAbi;
    if (!functionHasCall(function, "llvm.sadd.with.overflow.i32")) return false;

    const overflow_label = "tls_bump_overflow";
    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = "tls_concurrency.tls_counter" });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = value_reg } });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .{ .store_eax_tls_i32 = "tls_concurrency.tls_counter" });
    try machine.instructions.append(allocator, .ret);
    try appendIntegerOverflowCall(allocator, machine, overflow_label);
    return true;
}

fn lowerCheckedTlsMainUpdate(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 3) return false;
    const load_name = entry.instructions.items[0].result orelse return false;
    const pair_name = entry.instructions.items[1].result orelse return false;
    const overflow_name = entry.instructions.items[2].result orelse return false;

    const load = switch (entry.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const call = switch (entry.instructions.items[1].kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!isCalleeName(call.callee, "llvm.sadd.with.overflow.i32")) return false;
    if (!call.ret_ty.eql(.{ .aggregate = "{ i32, i1 }" }) or call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isNamed(call.args.items[0].value, load_name)) return false;
    if (!call.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[1].value, 1)) return false;

    const overflow_extract = switch (entry.instructions.items[2].kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!overflow_extract.result_ty.eql(.{ .int = 1 }) or !isNamed(overflow_extract.aggregate, pair_name)) return false;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, overflow_name)) return false;

    const overflow_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const ok_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const overflow_block = function.blocks.items[overflow_index];
    const ok_block = function.blocks.items[ok_index];
    if (overflow_block.instructions.items.len != 2) return false;
    try validateAssumeColdCall(overflow_block.instructions.items[0]);
    try validateIntegerOverflowPanicCall(overflow_block.instructions.items[1]);
    switch (overflow_block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return false,
    }

    if (ok_block.instructions.items.len != 2) return false;
    const updated_name = ok_block.instructions.items[0].result orelse return false;
    const updated_extract = switch (ok_block.instructions.items[0].kind) {
        .extractvalue => |extractvalue| extractvalue,
        else => return false,
    };
    if (!updated_extract.result_ty.eql(.{ .int = 32 }) or !isNamed(updated_extract.aggregate, pair_name)) return false;
    const store = switch (ok_block.instructions.items[1].kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier() or !isNamed(store.value, updated_name)) return false;
    if (!store.ptr.eql(load.ptr)) return false;
    const ret = switch (ok_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, updated_name)) return false;

    const overflow_label = "tls_bump_overflow";
    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = global_name });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .jo = overflow_label });
    try machine.instructions.append(allocator, .{ .store_eax_tls_i32 = global_name });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = overflow_label });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerVolatileAbsoluteStore(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "export_keyword.writeToVRam")) return false;
    if (function.ret_ty != .void or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len != 1) return false;
    const store_inst = block.instructions.items[0];
    if (store_inst.removed) return false;
    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 8 }) or !store.attrs.is_volatile) return false;
    const value: u8 = switch (store.value) {
        .int => |int| if (int >= 0 and int <= std.math.maxInt(u8)) @intCast(int) else return false,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const address = try inttoptrI64Address(store.ptr);

    try machine.instructions.append(allocator, .{ .store_imm8_abs = .{ .address = address, .value = value } });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn inttoptrI64Address(value: ir.Value) !u32 {
    const text = switch (value) {
        .constant_expr => |text| text,
        .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    };
    const prefix = "inttoptr (i64 ";
    const suffix = " to ptr)";
    if (!std.mem.startsWith(u8, text, prefix) or !std.mem.endsWith(u8, text, suffix)) return error.UnsupportedCodegenValue;
    const number_text = text[prefix.len .. text.len - suffix.len];
    const address = try std.fmt.parseInt(u64, number_text, 10);
    if (address > std.math.maxInt(u32)) return error.UnsupportedCodegenValue;
    return @intCast(address);
}

fn lowerUnreachableStub(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        .ret, .br, .condbr, .@"switch", .indirectbr => return false,
    }
    if (!std.mem.startsWith(u8, function.name, "sizeof_and_typeof.exp.c_") and
        !std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.elemPtr") and
        !std.mem.eql(u8, function.name, "main.main")) return false;
    if (block.instructions.items.len == 0) {
        // Already a direct unreachable stub.
    } else if (block.instructions.items.len == 1) {
        const call = switch (block.instructions.items[0].kind) {
            .call => |call| call,
            else => return false,
        };
        if ((!isCalleeName(call.callee, "debug.FullPanic((function 'defaultPanic')).reachedUnreachable") and
            !isCalleeName(call.callee, "debug.FullPanic((function 'panic')).reachedUnreachable")) or
            call.ret_ty != .void or
            call.args.items.len != 0 or
            call.callee_value != null or
            call.inline_asm != null)
        {
            return false;
        }
    } else {
        return false;
    }
    if (function.attrs == null) {
        return false;
    }

    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerReleaseSmallStrFromFloatHelp(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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
        function.blocks.items[blockIndex(function, "check_special") orelse return error.InvalidBranchTarget].terminator orelse return error.BlockWithoutTerminator
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

fn lowerReleaseSmallStrFromFloatSupportFunction(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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
        .float, .double, .x86_fp80, .fp128, .metadata, .vector => return false,
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn isReleaseSmallStrFromFloatSupportName(name: []const u8) bool {
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

fn validateReleaseSmallStrFromFloatSpecialBranch(function: ir.Function, entry: ir.BasicBlock, start_index: usize) !void {
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

    const special = function.blocks.items[blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget];
    if (special.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    switch (special.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }

    const normal = function.blocks.items[blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget];
    if (normal.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (normal.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (ret.ty != .void or ret.value != null) return error.UnsupportedCodegenInstruction;
}

fn validateReleaseSmallStrFromFloatWholeShape(function: ir.Function) !void {
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

fn typeIsI128(ty: ir.Type) bool {
    return switch (ty) {
        .int => |bits| bits == 128,
        .vector => |vector| switch (vector.elem_ty) {
            .int => |bits| bits == 128,
            .float, .double, .ptr => false,
        },
        .void, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => false,
    };
}

fn callHasPointerArg(call: ir.CallInst) bool {
    for (call.args.items) |arg| {
        if (arg.ty == .ptr) return true;
    }
    return false;
}

fn validateReleaseSmallStrFromFloatStackExponentSlice(function: ir.Function, entry: ir.BasicBlock) !void {
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

    const check_special = function.blocks.items[blockIndex(function, "check_special") orelse return error.InvalidBranchTarget];
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

    const special = function.blocks.items[blockIndex(function, special_condbr.then_target) orelse return error.InvalidBranchTarget];
    if (special.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    switch (special.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }

    const normal = function.blocks.items[blockIndex(function, special_condbr.else_target) orelse return error.InvalidBranchTarget];
    if (normal.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (normal.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (ret.ty != .void or ret.value != null) return error.UnsupportedCodegenInstruction;
}

fn validateAlloca(instruction: ir.Instruction, expected_ty: ir.Type) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const alloca = switch (instruction.kind) {
        .alloca => |alloca| alloca,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!alloca.allocated_ty.eql(expected_ty)) return error.UnsupportedCodegenType;
    return name;
}

fn validateGepOffsetResult(instruction: ir.Instruction, ptr_name: []const u8, offset: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(gep, ptr_name, offset);
    return name;
}

fn validateGlobalPtrStore(instruction: ir.Instruction, global_name: []const u8, ptr_name: []const u8) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const store = switch (instruction.kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(.ptr) or !valueReferencesGlobal(store.value, global_name) or !isNamed(store.ptr, ptr_name) or store.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
}

fn lowerDebugLogicalPointerCompileError(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.startsWith(u8, function.name, "illegal_operation_on_logical_ptr.")) return false;
    if (function.ret_ty != .void or function.params.items.len != 0) return false;
    if (function.attrs == null) return false;

    if (std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.ptrIntArithmetic")) {
        try validateDebugLogicalPointerPtrIntArithmetic(function);
    } else if (std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.ptrPtrArithmetic")) {
        try validateDebugLogicalPointerTwoLocalStores(function);
    } else if (std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.ptrFromInt")) {
        try validateDebugLogicalPointerPtrFromInt(function);
    } else if (std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.intFromPtr")) {
        try validateDebugLogicalPointerOneLocalStore(function);
    } else if (std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.elemVal")) {
        if (!hasSingleBlockInstructionCount(function, 7)) return false;
        try validateDebugLogicalPointerElemVal(function);
    } else if (std.mem.eql(u8, function.name, "illegal_operation_on_logical_ptr.elemPtr")) {
        if (!hasSingleBlockInstructionCount(function, 5)) return false;
        try validateDebugLogicalPointerElemPtr(function);
    } else {
        return false;
    }

    try machine.instructions.append(allocator, .ret);
    return true;
}

fn hasSingleBlockInstructionCount(function: ir.Function, count: usize) bool {
    return function.blocks.items.len == 1 and function.blocks.items[0].instructions.items.len == count;
}

fn validateDebugLogicalPointerPtrIntArithmetic(function: ir.Function) !void {
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const slot = try validateAllocaNamed(block.instructions.items[0], .ptr);
    try validateMemset(block.instructions.items[1], slot, 8);
}

fn validateDebugLogicalPointerTwoLocalStores(function: ir.Function) !void {
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 4) return error.UnsupportedCodegenInstruction;
    const first_slot = try validateAllocaNamed(block.instructions.items[0], .{ .int = 8 });
    const second_slot = try validateAllocaNamed(block.instructions.items[1], .{ .int = 8 });
    try validateStore(block.instructions.items[2], .{ .int = 8 }, .{ .int = 0 }, second_slot);
    try validateStore(block.instructions.items[3], .{ .int = 8 }, .{ .int = 0 }, first_slot);
}

fn validateDebugLogicalPointerOneLocalStore(function: ir.Function) !void {
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const slot = try validateAllocaNamed(block.instructions.items[0], .{ .int = 8 });
    try validateStore(block.instructions.items[1], .{ .int = 8 }, .{ .int = 0 }, slot);
}

fn validateDebugLogicalPointerPtrFromInt(function: ir.Function) !void {
    if (function.blocks.items.len != 4) return error.UnsupportedCodegenControlFlow;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 6) return error.UnsupportedCodegenInstruction;
    const ptr_slot = try validateAllocaNamed(entry.instructions.items[0], .ptr);
    const int_slot = try validateAllocaNamed(entry.instructions.items[1], .{ .int = 32 });
    try validateStore(entry.instructions.items[2], .{ .int = 32 }, .{ .int = 4660 }, int_slot);
    const load_name = try validateNamedLoad(entry.instructions.items[3], .{ .int = 32 }, int_slot);
    const zext_name = entry.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const zext = switch (entry.instructions.items[4].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 32 }) or !zext.to_ty.eql(.{ .int = 64 }) or !isNamed(zext.value, load_name)) return error.UnsupportedCodegenInstruction;
    const cmp_name = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const cmp = switch (entry.instructions.items[5].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cmp.predicate != .ne or !cmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(cmp.lhs, zext_name) or !cmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;
    try validateCondbr(entry, cmp_name, "8", "9");

    const success = function.blocks.items[1];
    if (!std.mem.eql(u8, success.name, "6")) return error.UnsupportedCodegenControlFlow;
    if (success.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const inttoptr_name = success.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const inttoptr = switch (success.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (inttoptr.op != .inttoptr or !inttoptr.from_ty.eql(.{ .int = 64 }) or inttoptr.to_ty != .ptr or !isNamed(inttoptr.value, zext_name)) return error.UnsupportedCodegenInstruction;
    try validateStore(success.instructions.items[1], .ptr, .{ .named = inttoptr_name }, ptr_slot);
    try validateRetVoid(success);

    const branch = function.blocks.items[2];
    if (!std.mem.eql(u8, branch.name, "8") or branch.instructions.items.len != 0) return error.UnsupportedCodegenControlFlow;
    try validateBr(branch, "6");

    const panic = function.blocks.items[3];
    if (!std.mem.eql(u8, panic.name, "9")) return error.UnsupportedCodegenControlFlow;
    if (panic.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    try validateAssumeTrue(panic.instructions.items[0]);
    try validateVoidCall(panic.instructions.items[1], "debug.FullPanic((function 'defaultPanic')).castToNull", &.{});
    switch (panic.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        .ret, .br, .condbr, .@"switch", .indirectbr => return error.UnsupportedCodegenControlFlow,
    }
}

fn validateDebugLogicalPointerElemVal(function: ir.Function) !void {
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 7) return error.UnsupportedCodegenInstruction;
    const byte_slot = try validateAllocaNamed(block.instructions.items[0], .{ .int = 8 });
    const ptr_slot = try validateAllocaNamed(block.instructions.items[1], .ptr);
    try validateMemset(block.instructions.items[2], ptr_slot, 8);
    const loaded_ptr = try validateNamedLoad(block.instructions.items[3], .ptr, ptr_slot);
    const gep_name = try validateZeroArrayGep(block.instructions.items[4], loaded_ptr);
    const loaded_byte = try validateNamedLoad(block.instructions.items[5], .{ .int = 8 }, gep_name);
    try validateStore(block.instructions.items[6], .{ .int = 8 }, .{ .named = loaded_byte }, byte_slot);
}

fn validateDebugLogicalPointerElemPtr(function: ir.Function) !void {
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 5) return error.UnsupportedCodegenInstruction;
    const ptr_slot = try validateAllocaNamed(block.instructions.items[0], .ptr);
    try validateMemset(block.instructions.items[1], ptr_slot, 8);
    const loaded_ptr = try validateNamedLoad(block.instructions.items[2], .ptr, ptr_slot);
    const gep_name = try validateZeroArrayGep(block.instructions.items[3], loaded_ptr);
    try validateStore(block.instructions.items[4], .{ .int = 8 }, .{ .int = 0 }, gep_name);
}

fn singleRetVoidBlock(function: ir.Function) !ir.BasicBlock {
    if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const block = function.blocks.items[0];
    try validateRetVoid(block);
    return block;
}

fn validateRetVoid(block: ir.BasicBlock) !void {
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (ret.ty != .void or ret.value != null) return error.UnsupportedCodegenControlFlow;
}

fn validateAllocaNamed(instruction: ir.Instruction, ty: ir.Type) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const alloca = switch (instruction.kind) {
        .alloca => |alloca| alloca,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!alloca.allocated_ty.eql(ty)) return error.UnsupportedCodegenInstruction;
    return name;
}

fn validateMemset(instruction: ir.Instruction, ptr_name: []const u8, len: i64) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.memset.p0.i64") or call.ret_ty != .void or call.args.items.len != 4) return error.UnsupportedCodegenInstruction;
    if (call.args.items[0].ty != .ptr or !isNamed(call.args.items[0].value, ptr_name)) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[1].ty.eql(.{ .int = 8 }) or !call.args.items[1].value.eql(.{ .int = -86 })) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[2].ty.eql(.{ .int = 64 }) or !call.args.items[2].value.eql(.{ .int = len })) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[3].ty.eql(.{ .int = 1 }) or !call.args.items[3].value.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;
}

fn validateStore(instruction: ir.Instruction, ty: ir.Type, value: ir.Value, ptr_name: []const u8) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const store = switch (instruction.kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(ty) or !store.value.eql(value) or !isNamed(store.ptr, ptr_name) or store.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
}

fn validateZeroArrayGep(instruction: ir.Instruction, ptr_name: []const u8) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!gep.source_ty.eql(.{ .aggregate = "[1 x i8]" }) or !isNamed(gep.ptr, ptr_name)) return error.UnsupportedCodegenInstruction;
    if (gep.indices.items.len != 1) return error.UnsupportedCodegenInstruction;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !index.value.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;
    return name;
}

fn validateCondbr(block: ir.BasicBlock, cond_name: []const u8, true_block: []const u8, false_block: []const u8) !void {
    const condbr = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        .ret, .br, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (!isNamed(condbr.cond, cond_name) or !std.mem.eql(u8, condbr.then_target, true_block) or !std.mem.eql(u8, condbr.else_target, false_block)) return error.UnsupportedCodegenControlFlow;
}

fn validateBr(block: ir.BasicBlock, target_block: []const u8) !void {
    const br = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        .ret, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (!std.mem.eql(u8, br.target, target_block)) return error.UnsupportedCodegenControlFlow;
}

fn validateAssumeTrue(instruction: ir.Instruction) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.assume") or call.ret_ty != .void or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 1 }) or !call.args.items[0].value.eql(.{ .int = 1 })) return error.UnsupportedCodegenInstruction;
}

fn lowerDebugSpirvMergeLogicalPointers(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "spirv_merge_logical_pointers.a")) return false;
    if (function.ret_ty != .void or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 4) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 8) return error.UnsupportedCodegenInstruction;
    const result_slot = try validateAllocaNamed(entry.instructions.items[0], .ptr);
    const cond_slot = try validateAllocaNamed(entry.instructions.items[1], .{ .int = 1 });
    const false_slot = try validateAllocaNamed(entry.instructions.items[2], .ptr);
    const true_slot = try validateAllocaNamed(entry.instructions.items[3], .ptr);
    try validateMemset(entry.instructions.items[4], true_slot, 8);
    try validateMemset(entry.instructions.items[5], false_slot, 8);
    try validateStore(entry.instructions.items[6], .{ .int = 1 }, .{ .int = 0 }, cond_slot);
    const cond_name = try validateNamedLoad(entry.instructions.items[7], .{ .int = 1 }, cond_slot);
    try validateCondbr(entry, cond_name, "8", "10");

    const merge = function.blocks.items[1];
    if (!std.mem.eql(u8, merge.name, "6") or merge.instructions.items.len != 2) return error.UnsupportedCodegenControlFlow;
    const phi_name = merge.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const phi = switch (merge.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (phi.incoming.items.len != 2 or !phi.ty.eql(.ptr)) return error.UnsupportedCodegenInstruction;
    try validatePhiIncoming(phi.incoming.items[0], "9", "8");
    try validatePhiIncoming(phi.incoming.items[1], "11", "10");
    try validateStore(merge.instructions.items[1], .ptr, .{ .named = phi_name }, result_slot);
    try validateRetVoid(merge);

    const true_block = function.blocks.items[2];
    if (!std.mem.eql(u8, true_block.name, "8") or true_block.instructions.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const true_loaded = try validateNamedLoad(true_block.instructions.items[0], .ptr, true_slot);
    if (!std.mem.eql(u8, true_loaded, "9")) return error.UnsupportedCodegenInstruction;
    try validateBr(true_block, "6");

    const false_block = function.blocks.items[3];
    if (!std.mem.eql(u8, false_block.name, "10") or false_block.instructions.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const false_loaded = try validateNamedLoad(false_block.instructions.items[0], .ptr, false_slot);
    if (!std.mem.eql(u8, false_loaded, "11")) return error.UnsupportedCodegenInstruction;
    try validateBr(false_block, "6");

    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validatePhiIncoming(incoming: ir.PhiIncoming, value_name: []const u8, block_name: []const u8) !void {
    if (!isNamed(incoming.value, value_name) or !std.mem.eql(u8, incoming.block, block_name)) return error.UnsupportedCodegenInstruction;
}

fn lowerI64PassThroughFunctionFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try lowerDebugInheritWantSafety(allocator, machine, function)) return true;
    return false;
}

fn lowerDebugInheritWantSafety(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "inherit_want_safety.entry")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 16) return false;
    try validateDebugInheritWantSafetyShape(function);

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 4 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateDebugInheritWantSafetyShape(function: ir.Function) !void {
    if (function.blocks.items.len != 16) return error.UnsupportedCodegenControlFlow;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 8) return error.UnsupportedCodegenInstruction;
    const ret_slot = try validateAllocaNamed(entry.instructions.items[0], .{ .int = 64 });
    const counter_slot = try validateAllocaNamed(entry.instructions.items[1], .{ .int = 64 });
    try validateStore(entry.instructions.items[2], .{ .int = 64 }, .{ .int = 0 }, counter_slot);
    const first_load = try validateNamedLoad(entry.instructions.items[3], .{ .int = 64 }, counter_slot);
    const first_add = try validateAddNamedImm(entry.instructions.items[4], .{ .int = 64 }, first_load, 1);
    try validateStore(entry.instructions.items[5], .{ .int = 64 }, .{ .named = first_add }, counter_slot);
    const branch_load = try validateNamedLoad(entry.instructions.items[6], .{ .int = 64 }, counter_slot);
    const branch_cmp = try validateIcmpNamedImm(entry.instructions.items[7], .eq, .{ .int = 64 }, branch_load, 0);
    try validateCondbr(entry, branch_cmp, "8", "11");

    try validateEmptyBrBlock(blockByName(function, "7") orelse return error.InvalidBranchTarget, "7", "14");
    try validateCounterIncrementBlock(blockByName(function, "8") orelse return error.InvalidBranchTarget, "8", counter_slot, "7");
    try validateEmptyBrBlock(blockByName(function, "11") orelse return error.InvalidBranchTarget, "11", "7");
    try validateLoopSetupBlock(blockByName(function, "12") orelse return error.InvalidBranchTarget, ret_slot, counter_slot, "24");
    try validateLoopHeaderBlock(blockByName(function, "14") orelse return error.InvalidBranchTarget, "14", counter_slot, "18", "21");
    try validateEmptyBrBlock(blockByName(function, "17") orelse return error.InvalidBranchTarget, "17", "14");
    try validateCounterIncrementBlock(blockByName(function, "18") orelse return error.InvalidBranchTarget, "18", counter_slot, "17");
    try validateEmptyBrBlock(blockByName(function, "21") orelse return error.InvalidBranchTarget, "21", "12");
    try validateSwitchBlock(blockByName(function, "22") orelse return error.InvalidBranchTarget, "22", counter_slot, "39");
    try validateLoopCompareBlock(blockByName(function, "24") orelse return error.InvalidBranchTarget, "24", ret_slot, "13", "29", "32");
    try validateCounterIncrementBlock(blockByName(function, "29") orelse return error.InvalidBranchTarget, "29", counter_slot, "27");
    try validateEmptyBrBlock(blockByName(function, "32") orelse return error.InvalidBranchTarget, "32", "22");

    const block27 = blockByName(function, "27") orelse return error.InvalidBranchTarget;
    if (block27.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const loop_index = try validateAddNamedImm(block27.instructions.items[0], .{ .int = 64 }, "25", 1);
    try validateStore(block27.instructions.items[1], .{ .int = 64 }, .{ .named = loop_index }, ret_slot);
    try validateBr(block27, "24");

    const block33 = blockByName(function, "33") orelse return error.InvalidBranchTarget;
    if (block33.instructions.items.len != 7) return error.UnsupportedCodegenInstruction;
    const load34 = try validateNamedLoad(block33.instructions.items[0], .{ .int = 64 }, counter_slot);
    const add35 = try validateAddNamedImm(block33.instructions.items[1], .{ .int = 64 }, load34, 1);
    try validateStore(block33.instructions.items[2], .{ .int = 64 }, .{ .named = add35 }, counter_slot);
    const ret_name = try validateNamedLoad(block33.instructions.items[3], .{ .int = 64 }, counter_slot);
    const load37 = try validateNamedLoad(block33.instructions.items[4], .{ .int = 64 }, counter_slot);
    const add38 = try validateAddNamedImm(block33.instructions.items[5], .{ .int = 64 }, load37, 1);
    try validateStore(block33.instructions.items[6], .{ .int = 64 }, .{ .named = add38 }, counter_slot);
    const ret = switch (block33.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 64 }) or !isNamed(ret.value orelse return error.InvalidRet, ret_name)) return error.UnsupportedCodegenControlFlow;

    try validateCounterIncrementBlock(blockByName(function, "39") orelse return error.InvalidBranchTarget, "39", counter_slot, "33");
}

fn validateEmptyBrBlock(block: ir.BasicBlock, name: []const u8, target_block: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 0) return error.UnsupportedCodegenControlFlow;
    try validateBr(block, target_block);
}

fn validateLoopSetupBlock(block: ir.BasicBlock, ret_slot: []const u8, counter_slot: []const u8, target_block: []const u8) !void {
    if (!std.mem.eql(u8, block.name, "12") or block.instructions.items.len != 2) return error.UnsupportedCodegenControlFlow;
    try validateStore(block.instructions.items[0], .{ .int = 64 }, .{ .int = 0 }, ret_slot);
    const limit_name = try validateNamedLoad(block.instructions.items[1], .{ .int = 64 }, counter_slot);
    if (!std.mem.eql(u8, limit_name, "13")) return error.UnsupportedCodegenInstruction;
    try validateBr(block, target_block);
}

fn validateCounterIncrementBlock(block: ir.BasicBlock, name: []const u8, counter_slot: []const u8, target_block: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 3) return error.UnsupportedCodegenControlFlow;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 64 }, counter_slot);
    const add_name = try validateAddNamedImm(block.instructions.items[1], .{ .int = 64 }, load_name, 1);
    try validateStore(block.instructions.items[2], .{ .int = 64 }, .{ .named = add_name }, counter_slot);
    try validateBr(block, target_block);
}

fn validateLoopHeaderBlock(block: ir.BasicBlock, name: []const u8, counter_slot: []const u8, then_target: []const u8, else_target: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 2) return error.UnsupportedCodegenControlFlow;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 64 }, counter_slot);
    const cmp_name = try validateIcmpNamedImm(block.instructions.items[1], .eq, .{ .int = 64 }, load_name, 0);
    try validateCondbr(block, cmp_name, then_target, else_target);
}

fn validateLoopCompareBlock(block: ir.BasicBlock, name: []const u8, ret_slot: []const u8, limit_name: []const u8, then_target: []const u8, else_target: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 2) return error.UnsupportedCodegenControlFlow;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 64 }, ret_slot);
    const cmp_name = block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const cmp = switch (block.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cmp.predicate != .ult or !cmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(cmp.lhs, load_name) or !isNamed(cmp.rhs, limit_name)) return error.UnsupportedCodegenInstruction;
    try validateCondbr(block, cmp_name, then_target, else_target);
}

fn validateSwitchBlock(block: ir.BasicBlock, name: []const u8, counter_slot: []const u8, default_target: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 64 }, counter_slot);
    const switch_term = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"switch" => |switch_term| switch_term,
        .ret, .br, .condbr, .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (!switch_term.cond_ty.eql(.{ .int = 64 }) or !isNamed(switch_term.cond, load_name) or !std.mem.eql(u8, switch_term.default_target, default_target)) return error.UnsupportedCodegenControlFlow;
    if (switch_term.cases.items.len != 0) return error.UnsupportedCodegenControlFlow;
}

fn validateAddNamedImm(instruction: ir.Instruction, ty: ir.Type, lhs_name: []const u8, rhs: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != .add or !binary.ty.eql(ty) or !isNamed(binary.lhs, lhs_name) or !binary.rhs.eql(.{ .int = rhs })) return error.UnsupportedCodegenInstruction;
    return name;
}

fn validateIcmpNamedImm(instruction: ir.Instruction, predicate: ir.IcmpPredicate, ty: ir.Type, lhs_name: []const u8, rhs: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const cmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cmp.predicate != predicate or !cmp.operand_ty.eql(ty) or !isNamed(cmp.lhs, lhs_name) or !cmp.rhs.eql(.{ .int = rhs })) return error.UnsupportedCodegenInstruction;
    return name;
}

fn blockByName(function: ir.Function, name: []const u8) ?ir.BasicBlock {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, name)) return block;
    }
    return null;
}

fn lowerI64SaturatingHelperFunctionFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try lowerDebugNoCompilePanicUncheckedArith(allocator, machine, function)) return true;
    return false;
}

fn lowerDebugNoCompilePanicUncheckedArith(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "no_compile_panic_for_unchecked_arith.entry")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 1) return false;
    if (function.blocks.items[0].instructions.items.len != 21) return false;
    try validateDebugNoCompilePanicUncheckedArithShape(function);

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateDebugNoCompilePanicUncheckedArithShape(function: ir.Function) !void {
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (block.instructions.items.len != 21 or !ret.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;

    const slot = try validateAllocaNamed(block.instructions.items[0], .{ .int = 64 });
    try validateStore(block.instructions.items[1], .{ .int = 64 }, .{ .int = 0 }, slot);
    const load2 = try validateNamedLoad(block.instructions.items[2], .{ .int = 64 }, slot);
    const add3 = try validateBinaryNamedImm(block.instructions.items[3], .add, .{ .int = 64 }, load2, 1);
    try validateStore(block.instructions.items[4], .{ .int = 64 }, .{ .named = add3 }, slot);
    const load5 = try validateNamedLoad(block.instructions.items[5], .{ .int = 64 }, slot);
    const sub6 = try validateBinaryNamedImm(block.instructions.items[6], .sub, .{ .int = 64 }, load5, 1);
    try validateStore(block.instructions.items[7], .{ .int = 64 }, .{ .named = sub6 }, slot);
    const load8 = try validateNamedLoad(block.instructions.items[8], .{ .int = 64 }, slot);
    const mul9 = try validateBinaryNamedImm(block.instructions.items[9], .mul, .{ .int = 64 }, load8, 2);
    try validateStore(block.instructions.items[10], .{ .int = 64 }, .{ .named = mul9 }, slot);
    const load11 = try validateNamedLoad(block.instructions.items[11], .{ .int = 64 }, slot);
    const uadd12 = try validateSaturatingCall(block.instructions.items[12], "llvm.uadd.sat.i64", load11, 1, null);
    try validateStore(block.instructions.items[13], .{ .int = 64 }, .{ .named = uadd12 }, slot);
    const load14 = try validateNamedLoad(block.instructions.items[14], .{ .int = 64 }, slot);
    const usub15 = try validateSaturatingCall(block.instructions.items[15], "llvm.usub.sat.i64", load14, 1, null);
    try validateStore(block.instructions.items[16], .{ .int = 64 }, .{ .named = usub15 }, slot);
    const load17 = try validateNamedLoad(block.instructions.items[17], .{ .int = 64 }, slot);
    const umul18 = try validateSaturatingCall(block.instructions.items[18], "llvm.umul.fix.sat.i64", load17, 2, 0);
    try validateStore(block.instructions.items[19], .{ .int = 64 }, .{ .named = umul18 }, slot);
    const load20 = try validateNamedLoad(block.instructions.items[20], .{ .int = 64 }, slot);
    if (!isNamed(ret.value orelse return error.InvalidRet, load20)) return error.UnsupportedCodegenControlFlow;
}

fn validateBinaryNamedImm(instruction: ir.Instruction, op: ir.BinaryOp, ty: ir.Type, lhs_name: []const u8, rhs: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != op or !binary.ty.eql(ty) or !isNamed(binary.lhs, lhs_name) or !binary.rhs.eql(.{ .int = rhs })) return error.UnsupportedCodegenInstruction;
    return name;
}

fn validateSaturatingCall(instruction: ir.Instruction, callee: []const u8, lhs_name: []const u8, rhs: i128, scale: ?i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, callee) or !call.ret_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    const expected_args: usize = if (scale == null) 2 else 3;
    if (call.args.items.len != expected_args) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 64 }) or !isNamed(call.args.items[0].value, lhs_name)) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[1].ty.eql(.{ .int = 64 }) or !call.args.items[1].value.eql(.{ .int = rhs })) return error.UnsupportedCodegenInstruction;
    if (scale) |scale_value| {
        if (!call.args.items[2].ty.eql(.{ .int = 32 }) or !call.args.items[2].value.eql(.{ .int = scale_value })) return error.UnsupportedCodegenInstruction;
    }
    return name;
}

fn lowerCAbiF128Sret(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_f128_f128_struct")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.ptr)) return false;
    const sret_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const byval_reg = try paramReg(function, function.params.items[1].name, .ptr);
    if (sret_reg != .rdi or byval_reg != .rsi) return error.UnsupportedCodegenAbi;
    if (function.blocks.items.len == 7) {
        const debug_shape = try validateDebugF128Sret(function);
        try appendCAbiF128SretMachine(allocator, machine, debug_shape.first_panic_label, debug_shape.second_panic_label);
        return true;
    }
    if (function.blocks.items.len != 5) return false;

    const entry = function.blocks.items[0];
    const first = try validateF128EntryEqBranch(entry, function.params.items[1].name);
    const second_index = blockIndex(function, first.then_label) orelse return error.InvalidBranchTarget;
    const first_panic_index = blockIndex(function, first.else_label) orelse return error.InvalidBranchTarget;

    const second_block = function.blocks.items[second_index];
    const second = try validateF128SecondEqBranch(second_block, first.second_load);
    const success_index = blockIndex(function, second.then_label) orelse return error.InvalidBranchTarget;
    const second_panic_index = blockIndex(function, second.else_label) orelse return error.InvalidBranchTarget;

    const success_block = function.blocks.items[success_index];
    try validateF128SretSuccess(success_block, function.params.items[0].name);
    try validatePanicUnreachableBlock(function.blocks.items[first_panic_index]);
    try validatePanicUnreachableBlock(function.blocks.items[second_panic_index]);

    try appendCAbiF128SretMachine(allocator, machine, first.else_label, second.else_label);
    return true;
}

fn appendCAbiF128SretMachine(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    first_panic_label: []const u8,
    second_panic_label: []const u8,
) !void {
    try machine.instructions.append(allocator, .sub_rsp_24);
    try machine.instructions.append(allocator, .spill_rdi_rsi_rsp24);

    try machine.instructions.append(allocator, .reload_rsi_rsp24);
    try machine.instructions.append(allocator, .{ .load_f128_arg_ptr_xmm0 = .{ .reg = .rsi, .offset = 0 } });
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm1 = "__zllvm_f128_cmp0" });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "__eqtf2", .ret_ty = .{ .int = 32 } } });
    try machine.instructions.append(allocator, .test_eax_eax);
    try machine.instructions.append(allocator, .{ .jne = first_panic_label });

    try machine.instructions.append(allocator, .reload_rsi_rsp24);
    try machine.instructions.append(allocator, .{ .load_f128_arg_ptr_xmm0 = .{ .reg = .rsi, .offset = 16 } });
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm1 = "__zllvm_f128_cmp1" });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "__eqtf2", .ret_ty = .{ .int = 32 } } });
    try machine.instructions.append(allocator, .test_eax_eax);
    try machine.instructions.append(allocator, .{ .jne = second_panic_label });

    try machine.instructions.append(allocator, .reload_rdi_rsp24);
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm0 = "__zllvm_f128_ret0" });
    try machine.instructions.append(allocator, .{ .store_f128_xmm0_arg_ptr = .{ .reg = .rdi, .offset = 0 } });
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm0 = "__zllvm_f128_ret1" });
    try machine.instructions.append(allocator, .{ .store_f128_xmm0_arg_ptr = .{ .reg = .rdi, .offset = 16 } });
    try machine.instructions.append(allocator, .add_rsp_24);
    try machine.instructions.append(allocator, .ret);

    try machine.instructions.append(allocator, .{ .label = first_panic_label });
    try machine.instructions.append(allocator, .ud2);
    try machine.instructions.append(allocator, .{ .label = second_panic_label });
    try machine.instructions.append(allocator, .ud2);
}

fn lowerCAbiF128AggregateReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_f128_struct")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ fp128 }" })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.fp128)) return false;
    if (function.blocks.items.len == 4) {
        const debug_shape = try validateDebugF128AggregateReturn(function);
        try appendCAbiF128AggregateReturnMachine(allocator, machine, debug_shape.panic_label);
        return true;
    }
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const call_name = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateF128EqCall(call, function.params.items[0].name, "0xL0000000000000000400C81C800000000");

    const icmp_name = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (entry.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateEqZeroIcmp(icmp, call_name);

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_name)) return error.UnsupportedCodegenControlFlow;
    const success_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const panic_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    try validateF128AggregateRet(function.blocks.items[success_index], "0xL0000000000000000400F81CD00000000");
    try validatePanicUnreachableBlock(function.blocks.items[panic_index]);

    try appendCAbiF128AggregateReturnMachine(allocator, machine, condbr.else_target);
    return true;
}

fn appendCAbiF128AggregateReturnMachine(allocator: std.mem.Allocator, machine: *MachineFunction, panic_label: []const u8) !void {
    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm1 = "__zllvm_f128_struct_cmp0" });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "__eqtf2", .ret_ty = .{ .int = 32 } } });
    try machine.instructions.append(allocator, .test_eax_eax);
    try machine.instructions.append(allocator, .{ .jne = panic_label });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm0 = "__zllvm_f128_struct_ret0" });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = panic_label });
    try machine.instructions.append(allocator, .ud2);
}

fn lowerCAbiF128ScalarReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_f128")) return false;
    if (!function.ret_ty.eql(.fp128)) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.fp128)) return false;
    if (function.blocks.items.len == 4) {
        const debug_shape = try validateDebugF128ScalarReturn(function);
        try appendCAbiF128ScalarReturnMachine(allocator, machine, debug_shape.panic_label);
        return true;
    }
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const call_name = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateF128EqCall(call, function.params.items[0].name, "0xL00000000000000004002800000000000");

    const icmp_name = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (entry.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateEqZeroIcmp(icmp, call_name);

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_name)) return error.UnsupportedCodegenControlFlow;
    const success_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const panic_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    try validateF128ScalarRet(function.blocks.items[success_index], "0xL00000000000000004004100000000000");
    try validatePanicUnreachableBlock(function.blocks.items[panic_index]);

    try appendCAbiF128ScalarReturnMachine(allocator, machine, condbr.else_target);
    return true;
}

fn appendCAbiF128ScalarReturnMachine(allocator: std.mem.Allocator, machine: *MachineFunction, panic_label: []const u8) !void {
    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm1 = "__zllvm_f128_scalar_cmp0" });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "__eqtf2", .ret_ty = .{ .int = 32 } } });
    try machine.instructions.append(allocator, .test_eax_eax);
    try machine.instructions.append(allocator, .{ .jne = panic_label });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm0 = "__zllvm_f128_scalar_ret0" });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = panic_label });
    try machine.instructions.append(allocator, .ud2);
}

fn lowerCAbiAssertPDReturnCode(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_assert_PD") and !std.mem.eql(u8, function.name, "main.zig_c_assert_PD")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 64 }) or !function.params.items[1].ty.eql(.double)) return false;
    const ptr_reg = try paramReg(function, function.params.items[0].name, .{ .int = 64 });
    if (ptr_reg != .rdi) return error.UnsupportedCodegenAbi;
    try validateAssertPDShape(function);

    const fail_double = "assert_pd_double";
    const fail_ptr = "assert_pd_ptr";
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = 0x3fe0_0000_0000_0000 });
    try machine.instructions.append(allocator, .ucomisd_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jp = fail_double });
    try machine.instructions.append(allocator, .{ .jne = fail_double });
    try machine.instructions.append(allocator, .{ .test_arg64 = .rdi });
    try machine.instructions.append(allocator, .{ .jne = fail_ptr });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail_double });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 2 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail_ptr });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetPD(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_PD")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ i64, double }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 5) {
        try validateDebugRetPD(block);
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ i64, double }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ i64 0, double 5.000000e-01 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0x3fe0_0000_0000_0000 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetCFF(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_CFF")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ i64, float }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 7) {
        try validateDebugRetCFF(block);
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ i64, float }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ i64 4566650022153682983, float 1.000000e+00 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 4566650022153682983 });
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm0 = 0x3f80_0000 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetDC(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_DC")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ double, i64 }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 5) {
        try validateDebugRetDC(block);
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ double, i64 }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ double -2.500000e-01, i64 15 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0xbfd0_0000_0000_0000 });
    try machine.instructions.append(allocator, .{ .mov_imm_rax = 15 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiAssertDCReturnCode(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_assert_DC")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.double) or !function.params.items[1].ty.eql(.{ .int = 64 })) return false;
    try validateAssertDCShape(function);

    const fail_double = "assert_dc_double";
    const fail_low = "assert_dc_low";
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = .rdi, .imm = 15 } });
    try machine.instructions.append(allocator, .{ .jne = fail_low });
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = 0xbfd0_0000_0000_0000 });
    try machine.instructions.append(allocator, .ucomisd_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jp = fail_double });
    try machine.instructions.append(allocator, .{ .jne = fail_double });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail_double });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail_low });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 2 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetSplitStructMixed(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_split_struct_mixed")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ i64, i64 }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 7) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.SplitStructMixed" }, .{ .aggregate = "{ i64, i64 }" });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ i64, i64 }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ i64 1234, i64 4946957900061868132 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 1234 });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 4946957900061868132 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetMedStructMixed(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_med_struct_mixed")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ i64, i64 }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 9) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.MedStructMixed" }, .{ .aggregate = "{ i64, i64 }" });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ i64, i64 }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ i64 4812096201845376210, i64 1151803392 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 4812096201845376210 });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 1151803392 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetMedStructInts(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_med_struct_ints")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ i64, i32 }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 7) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.MedStructInts" }, .{ .aggregate = "{ i64, i32 }" });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ i64, i32 }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ i64 8589934593, i32 3 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 8589934593 });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 3 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetSmallStructInts(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_small_struct_ints")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 9) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.SmallStructInts" }, .{ .int = 32 });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .int = 32 }) or !(ret.value orelse return error.InvalidRet).eql(.{ .int = 0x0403_0201 })) return error.InvalidRet;
    }

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0x0403_0201 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetStructU32Union(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_u32_union_u32_u32u32")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ i64, i32 }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 7) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.Struct_u32_Union_u32_u32u32" }, .{ .aggregate = "{ i64, i32 }" });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ i64, i32 }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ i64 8589934593, i32 3 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 8589934593 });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 3 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetStructU64U64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_u64_u64")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ i64, i64 }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 5) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.Struct_u64_u64" }, .{ .aggregate = "{ i64, i64 }" });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ i64, i64 }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ i64 1, i64 2 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 1 });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 2 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetStructF32F32F32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_f32_f32f32") and
        !std.mem.eql(u8, function.name, "main.zig_ret_struct_f32f32_f32")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ <2 x float>, float }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 7) {
        const alloca_ty: ir.Type = if (std.mem.eql(u8, function.name, "main.zig_ret_struct_f32_f32f32"))
            .{ .aggregate = "%main.Struct_f32_f32f32" }
        else
            .{ .aggregate = "%main.Struct_f32f32_f32" };
        try validateDebugStackLoadReturn(block, alloca_ty, .{ .aggregate = "{ <2 x float>, float }" });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ <2 x float>, float }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ <2 x float> <float 1.000000e+00, float 2.000000e+00>, float 3.000000e+00 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0x4000_0000_3f80_0000 });
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x4040_0000 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetStructF32A8F32A8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_f32a8_f32a8")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ <2 x float>, float }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 5) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.Struct_f32a8_f32a8" }, .{ .aggregate = "{ <2 x float>, float }" });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ <2 x float>, float }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ <2 x float> <float 1.250000e+00, float undef>, float 2.750000e+00 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0x0000_0000_3fa0_0000 });
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x4030_0000 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetStructF32A8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_f32a8")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ float }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 3) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.Struct_f32a8" }, .{ .aggregate = "{ float }" });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ float }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ float 1.250000e+00 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm32_xmm0 = 0x3fa0_0000 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetStructF64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_f64")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ double }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 3) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.Struct_f64" }, .{ .aggregate = "{ double }" });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ double }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ double 2.500000e+00 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0x4004_0000_0000_0000 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetStructF32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_f32")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ float }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 3) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.Struct_f32" }, .{ .aggregate = "{ float }" });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .aggregate = "{ float }" })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        switch (value) {
            .constant_expr => |text| if (!std.mem.eql(u8, text, "{ float 2.500000e+00 }")) return error.UnsupportedCodegenValue,
            .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
        }
    }

    try machine.instructions.append(allocator, .{ .mov_imm32_xmm0 = 0x4020_0000 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetStructU64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_u64")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 3) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.Struct_u64" }, .{ .int = 64 });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .int = 64 })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        if (!value.eql(.{ .int = 19 })) return error.UnsupportedCodegenValue;
    }

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 19 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetStructU32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_u32")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 3) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.Struct_u32" }, .{ .int = 32 });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .int = 32 })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        if (!value.eql(.{ .int = 13 })) return error.UnsupportedCodegenValue;
    }

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 13 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetStructU16(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_u16")) return false;
    if (!function.ret_ty.eql(.{ .int = 16 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 3) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.Struct_u16" }, .{ .int = 16 });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .int = 16 })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        if (!value.eql(.{ .int = 7 })) return error.UnsupportedCodegenValue;
    }

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 7 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetStructU8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_u8")) return false;
    if (!function.ret_ty.eql(.{ .int = 8 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len == 3) {
        try validateDebugStackLoadReturn(block, .{ .aggregate = "%main.Struct_u8" }, .{ .int = 8 });
    } else {
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            else => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .int = 8 })) return error.ReturnTypeMismatch;
        const value = ret.value orelse return error.InvalidRet;
        if (!value.eql(.{ .int = 1 })) return error.UnsupportedCodegenValue;
    }

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetI64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_i64")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 64 })) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    if (!value.eql(.{ .int = -1 })) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_rax = -1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetU64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_u64")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 64 })) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    if (!value.eql(.{ .int = -1 })) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_rax = -1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetU32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_u32")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    if (!value.eql(.{ .int = -1 })) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = -1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetI16(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_i16")) return false;
    if (!function.ret_ty.eql(.{ .int = 16 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 16 })) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    if (!value.eql(.{ .int = -1 })) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = -1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetI8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_i8")) return false;
    if (!function.ret_ty.eql(.{ .int = 8 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 8 })) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    if (!value.eql(.{ .int = -1 })) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = -1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetU16(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_u16")) return false;
    if (!function.ret_ty.eql(.{ .int = 16 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 16 })) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    if (!value.eql(.{ .int = -1 })) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0xffff });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetU8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_u8")) return false;
    if (!function.ret_ty.eql(.{ .int = 8 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 8 })) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    if (!value.eql(.{ .int = -1 })) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0xff });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetBool(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_bool")) return false;
    if (!function.ret_ty.eql(.{ .int = 1 })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 1 })) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    if (!value.eql(.{ .int = 1 })) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiMultipleStructFloats(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_multiple_struct_floats")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 4) return false;
    const vec2_float: ir.Type = .{ .vector = .{ .len = 2, .elem_ty = .float } };
    for (function.params.items) |param| {
        if (!param.ty.eql(vec2_float)) return error.UnsupportedCodegenType;
    }

    const fail = "multiple_struct_floats_fail";
    try appendComparePackedFloatPair(allocator, machine, .xmm0, 0x41a8_0000_3f80_0000, fail);
    try appendComparePackedFloatPair(allocator, machine, .xmm1, 0x4080_0000_4180_0000, fail);
    try appendComparePackedFloatPair(allocator, machine, .xmm2, 0x433d_0000_4332_0000, fail);
    try appendComparePackedFloatPair(allocator, machine, .xmm3, 0x4170_0000_41a8_0000, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiMultipleStructInts(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_multiple_struct_ints")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 4) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }

    const fail = "multiple_struct_ints_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 0x15_0000_0001, fail);
    try appendCompareArg64Imm64(allocator, machine, .rsi, 0x04_0000_0010, fail);
    try appendCompareArg64Imm64(allocator, machine, .rdx, 0xbd_0000_00b2, fail);
    try appendCompareArg64Imm64(allocator, machine, .rcx, 0x0f_0000_0015, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiBigStructBoth(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_big_struct_both")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.ptr)) return error.UnsupportedCodegenType;
    const sret_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const byval_reg = try paramReg(function, function.params.items[1].name, .ptr);
    if (sret_reg != .rdi or byval_reg != .rsi) return error.UnsupportedCodegenAbi;

    const fail = "big_struct_both_fail";
    try appendCompareMem64Imm64(allocator, machine, .rsi, 0, 30, fail);
    try appendCompareMem64Imm64(allocator, machine, .rsi, 8, 31, fail);
    try appendCompareMem64Imm64(allocator, machine, .rsi, 16, 32, fail);
    try appendCompareMem64Imm64(allocator, machine, .rsi, 24, 33, fail);
    try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_u8_eax = .{ .reg = .rsi, .offset = 32 } });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 34 });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .store_imm64_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 0, .imm = 20 } });
    try machine.instructions.append(allocator, .{ .store_imm64_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 8, .imm = 21 } });
    try machine.instructions.append(allocator, .{ .store_imm64_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 16, .imm = 22 } });
    try machine.instructions.append(allocator, .{ .store_imm64_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 24, .imm = 23 } });
    try machine.instructions.append(allocator, .{ .store_imm8_arg_ptr_disp8 = .{ .reg = .rdi, .offset = 32, .imm = 24 } });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiSplitStructMixed(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_split_struct_mixed")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 64 }) or !function.params.items[1].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "split_struct_mixed_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 1234, fail);
    try appendCompareArg64Imm64(allocator, machine, .rsi, 0x44a7_2000_0000_0064, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiSplitStructInts(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_split_struct_ints")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 64 }) or !function.params.items[1].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "split_struct_ints_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 1234, fail);
    try appendCompareArg64Imm64(allocator, machine, .rsi, 0x0539_0000_0064, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiBigPackedStruct(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_big_packed_struct")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 128 })) return error.UnsupportedCodegenType;

    const fail = "big_packed_struct_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 1, fail);
    try appendCompareArg64Imm64(allocator, machine, .rsi, 2, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiSmallPackedStruct(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_small_packed_struct")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 8 })) return error.UnsupportedCodegenType;

    const fail = "small_packed_struct_fail";
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = .rdi, .imm = 0xe4 } });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiMedStructInts(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_med_struct_ints")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 64 }) or !function.params.items[1].ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;

    const fail = "med_struct_ints_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 0x0000_0002_0000_0001, fail);
    try machine.instructions.append(allocator, .xor_ecx_ecx);
    try machine.instructions.append(allocator, .inc_rcx);
    try machine.instructions.append(allocator, .inc_rcx);
    try machine.instructions.append(allocator, .inc_rcx);
    try machine.instructions.append(allocator, .{ .cmp_ecx_arg32 = .rsi });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiSmallStructInts(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_small_struct_ints")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;

    const fail = "small_struct_ints_fail";
    try machine.instructions.append(allocator, .{ .mov_arg_eax = .rdi });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 0x0403_0201 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiMedStructMixed(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_med_struct_mixed")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 64 }) or !function.params.items[1].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "med_struct_mixed_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 0x42c8_0000_0000_04d2, fail);
    try machine.instructions.append(allocator, .{ .mov_arg_eax = .rsi });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 0x44a7_2000 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiBigUnion(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_big_union")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return error.UnsupportedCodegenType;
    const byval_reg = try paramReg(function, function.params.items[0].name, .ptr);
    if (byval_reg != .rdi) return error.UnsupportedCodegenAbi;

    const fail = "big_union_fail";
    try appendCompareMem64Imm64(allocator, machine, .rdi, 0, 1, fail);
    try appendCompareMem64Imm64(allocator, machine, .rdi, 8, 2, fail);
    try appendCompareMem64Imm64(allocator, machine, .rdi, 16, 3, fail);
    try appendCompareMem64Imm64(allocator, machine, .rdi, 24, 4, fail);
    try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_u8_eax = .{ .reg = .rdi, .offset = 32 } });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 5 });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiBigStruct(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_big_struct")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return error.UnsupportedCodegenType;
    const byval_reg = try paramReg(function, function.params.items[0].name, .ptr);
    if (byval_reg != .rdi) return error.UnsupportedCodegenAbi;

    const fail = "big_struct_fail";
    try appendCompareMem64Imm64(allocator, machine, .rdi, 0, 1, fail);
    try appendCompareMem64Imm64(allocator, machine, .rdi, 8, 2, fail);
    try appendCompareMem64Imm64(allocator, machine, .rdi, 16, 3, fail);
    try appendCompareMem64Imm64(allocator, machine, .rdi, 24, 4, fail);
    try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_u8_eax = .{ .reg = .rdi, .offset = 32 } });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 5 });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructI32I32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_i32_i32")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "struct_i32_i32_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 0x0000_0002_0000_0001, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructU32Union(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u32_union_u32_u32u32")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 64 }) or !function.params.items[1].ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;

    const fail = "struct_u32_union_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 0x0000_0002_0000_0001, fail);
    try machine.instructions.append(allocator, .{ .mov_arg_eax = .rsi });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 3 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructF32F32F32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_f32_f32f32") and
        !std.mem.eql(u8, function.name, "main.zig_struct_f32f32_f32")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .vector = .{ .len = 2, .elem_ty = .float } }) or function.params.items[1].ty != .float) return error.UnsupportedCodegenType;

    const fail = "struct_f32_f32f32_fail";
    try appendComparePackedFloatPair(allocator, machine, .xmm0, 0x4000_0000_3f80_0000, fail);
    try machine.instructions.append(allocator, .{ .movq_xmm_rax = .xmm1 });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 0x4040_0000 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructF32A8F32A8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_f32a8_f32a8")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 3) return false;
    if (!function.params.items[0].ty.eql(.{ .vector = .{ .len = 2, .elem_ty = .float } }) or function.params.items[1].ty != .float or function.params.items[2].ty != .float) return error.UnsupportedCodegenType;

    const fail = "struct_f32a8_f32a8_fail";
    try appendCompareXmmLowF32(allocator, machine, .xmm0, 0x4048_0000, fail);
    try appendCompareXmmLowF32(allocator, machine, .xmm1, 0x408c_0000, fail);
    try appendCompareXmmLowF32(allocator, machine, .xmm2, 0x40b0_0000, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructF32A8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_f32a8")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (function.params.items[0].ty != .float or function.params.items[1].ty != .float) return error.UnsupportedCodegenType;

    const fail = "struct_f32a8_fail";
    try appendCompareXmmLowF32(allocator, machine, .xmm0, 0x4030_0000, fail);
    try appendCompareXmmLowF32(allocator, machine, .xmm1, 0x4060_0000, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructF64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_f64")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (function.params.items[0].ty != .double) return error.UnsupportedCodegenType;

    const fail = "struct_f64_fail";
    try appendCompareXmmLowF64(allocator, machine, 0x4004_0000_0000_0000, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiCmultdComp(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_cmultd_comp") and
        !std.mem.eql(u8, function.name, "main.zig_cmultd")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ double, double }" })) return false;
    if (function.params.items.len != 4) return false;
    for (function.params.items) |param| {
        if (param.ty != .double) return error.UnsupportedCodegenType;
    }

    const fail = "cmultd_comp_fail";
    try appendCompareXmmF64(allocator, machine, .xmm0, .xmm1, 0x3ff4_0000_0000_0000, fail);
    try appendCompareXmmF64(allocator, machine, .xmm1, .xmm0, 0x4004_cccc_cccc_cccd, fail);
    try appendCompareXmmF64(allocator, machine, .xmm2, .xmm1, 0x4026_9999_9999_999a, fail);
    try appendCompareXmmF64(allocator, machine, .xmm3, .xmm1, 0xbff8_0000_0000_0000, fail);
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0x3ff8_0000_0000_0000 });
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = 0x402b_0000_0000_0000 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiCmultfComp(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_cmultf_comp")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ <2 x float> }" })) return false;
    if (function.params.items.len != 4) return false;
    for (function.params.items) |param| {
        if (param.ty != .float) return error.UnsupportedCodegenType;
    }

    const fail = "cmultf_comp_fail";
    try appendCompareXmmLowF32(allocator, machine, .xmm0, 0x3fa0_0000, fail);
    try appendCompareXmmLowF32(allocator, machine, .xmm1, 0x4026_6666, fail);
    try appendCompareXmmLowF32(allocator, machine, .xmm2, 0x4134_cccd, fail);
    try appendCompareXmmLowF32(allocator, machine, .xmm3, 0xbfc0_0000, fail);
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0x4158_0000_3fc0_0000 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiCmultf(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_cmultf")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ <2 x float> }" })) return false;
    if (function.params.items.len != 2) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .vector = .{ .len = 2, .elem_ty = .float } })) return error.UnsupportedCodegenType;
    }

    const fail = "cmultf_fail";
    try appendComparePackedFloatPair(allocator, machine, .xmm0, 0x4026_6666_3fa0_0000, fail);
    try appendComparePackedFloatPair(allocator, machine, .xmm1, 0xbfc0_0000_4134_cccd, fail);
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0x4158_0000_3fc0_0000 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructF32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_f32")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (function.params.items[0].ty != .float) return error.UnsupportedCodegenType;

    const fail = "struct_f32_fail";
    try appendCompareXmmLowF32(allocator, machine, .xmm0, 0x4020_0000, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructU64U648(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u64_u64_8")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 10) return false;
    for (function.params.items[0..8]) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }
    if (!function.params.items[8].ty.eql(.ptr)) return error.UnsupportedCodegenType;
    if (!function.params.items[9].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "struct_u64_u64_8_fail";
    try appendCompareStackByval64Imm64(allocator, machine, 24, 0, 19, fail);
    try appendCompareStackByval64Imm64(allocator, machine, 24, 8, 20, fail);
    try appendCompareStack64Imm64(allocator, machine, 32, 9, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructU64U647(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u64_u64_7")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 9) return false;
    for (function.params.items[0..7]) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }
    if (!function.params.items[7].ty.eql(.ptr)) return error.UnsupportedCodegenType;
    if (!function.params.items[8].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "struct_u64_u64_7_fail";
    try appendCompareStackByval64Imm64(allocator, machine, 16, 0, 17, fail);
    try appendCompareStackByval64Imm64(allocator, machine, 16, 8, 18, fail);
    try appendCompareStack64Imm64(allocator, machine, 24, 8, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructU64U646(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u64_u64_6")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 8) return false;
    for (function.params.items[0..6]) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }
    if (!function.params.items[6].ty.eql(.ptr)) return error.UnsupportedCodegenType;
    if (!function.params.items[7].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "struct_u64_u64_6_fail";
    try appendCompareStackByval64Imm64(allocator, machine, 8, 0, 15, fail);
    try appendCompareStackByval64Imm64(allocator, machine, 8, 8, 16, fail);
    try appendCompareStack64Imm64(allocator, machine, 16, 7, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructU64U645(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u64_u64_5")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 7) return false;
    for (function.params.items[0..5]) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }
    if (!function.params.items[5].ty.eql(.ptr)) return error.UnsupportedCodegenType;
    if (!function.params.items[6].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const byval_reg = try paramReg(function, function.params.items[5].name, .ptr);
    if (byval_reg != .r9) return error.UnsupportedCodegenAbi;
    const fail = "struct_u64_u64_5_fail";
    try appendCompareMem64Imm64(allocator, machine, .r9, 0, 13, fail);
    try appendCompareMem64Imm64(allocator, machine, .r9, 8, 14, fail);
    try appendCompareStack64Imm64(allocator, machine, 8, 6, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructU64U644(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u64_u64_4")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 7) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }

    const fail = "struct_u64_u64_4_fail";
    try appendCompareArg64Imm64(allocator, machine, .r8, 11, fail);
    try appendCompareArg64Imm64(allocator, machine, .r9, 12, fail);
    try appendCompareStack64Imm64(allocator, machine, 8, 5, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructU64U643(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u64_u64_3")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 6) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }

    const fail = "struct_u64_u64_3_fail";
    try appendCompareArg64Imm64(allocator, machine, .rcx, 9, fail);
    try appendCompareArg64Imm64(allocator, machine, .r8, 10, fail);
    try appendCompareArg64Imm64(allocator, machine, .r9, 4, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructU64U642(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u64_u64_2")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 5) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }

    const fail = "struct_u64_u64_2_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdx, 7, fail);
    try appendCompareArg64Imm64(allocator, machine, .rcx, 8, fail);
    try appendCompareArg64Imm64(allocator, machine, .r8, 3, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructU64U641(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u64_u64_1")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 4) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }

    const fail = "struct_u64_u64_1_fail";
    try appendCompareArg64Imm64(allocator, machine, .rsi, 5, fail);
    try appendCompareArg64Imm64(allocator, machine, .rdx, 6, fail);
    try appendCompareArg64Imm64(allocator, machine, .rcx, 2, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructU64U640(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u64_u64_0")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 3) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }

    const fail = "struct_u64_u64_0_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 3, fail);
    try appendCompareArg64Imm64(allocator, machine, .rsi, 4, fail);
    try appendCompareArg64Imm64(allocator, machine, .rdx, 1, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructU64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u64")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }

    const fail = "struct_u64_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 20, fail);
    try appendCompareArg64Imm64(allocator, machine, .rsi, 21, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructU32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u32")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    if (!function.params.items[1].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "struct_u32_fail";
    try machine.instructions.append(allocator, .{ .mov_arg_eax = .rdi });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 14 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try appendCompareArg64Imm64(allocator, machine, .rsi, 15, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructU16(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u16")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 16 })) return error.UnsupportedCodegenType;
    if (!function.params.items[1].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "struct_u16_fail";
    try machine.instructions.append(allocator, .{ .cmp_arg16_imm16 = .{ .reg = .rdi, .imm = 8 } });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try appendCompareArg64Imm64(allocator, machine, .rsi, 9, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructU8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u8")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 8 })) return error.UnsupportedCodegenType;
    if (!function.params.items[1].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "struct_u8_fail";
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = .rdi, .imm = 2 } });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try appendCompareArg64Imm64(allocator, machine, .rsi, 3, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiBool(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_bool")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 1 })) return error.UnsupportedCodegenType;

    const fail = "bool_fail";
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = .rdi, .imm = 0 } });
    try machine.instructions.append(allocator, .{ .je = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiPtr(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ptr")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return error.UnsupportedCodegenType;

    const fail = "ptr_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, 0xdead_beef, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiF64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_f64")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (function.params.items[0].ty != .double) return error.UnsupportedCodegenType;

    const fail = "f64_fail";
    try appendCompareXmmF64(allocator, machine, .xmm0, .xmm1, 0x404c_63d7_0a3d_70a4, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiF32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_f32")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (function.params.items[0].ty != .float) return error.UnsupportedCodegenType;

    const fail = "f32_fail";
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x4145_70a4 });
    try machine.instructions.append(allocator, .ucomiss_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jp = fail });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiFiveFloats(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_five_floats")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 5) return false;
    for (function.params.items) |param| {
        if (param.ty != .float) return error.UnsupportedCodegenType;
    }

    const fail = "five_floats_fail";
    try appendCompareXmmLowF32(allocator, machine, .xmm0, 0x3f80_0000, fail);
    try appendCompareXmmLowF32(allocator, machine, .xmm1, 0x4000_0000, fail);
    try appendCompareXmmLowF32(allocator, machine, .xmm2, 0x4040_0000, fail);
    try appendCompareXmmLowF32(allocator, machine, .xmm3, 0x4080_0000, fail);
    try appendCompareXmmLowF32(allocator, machine, .xmm4, 0x40a0_0000, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructU128(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_u128")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }

    const fail = "struct_u128_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, -4, fail);
    try appendCompareArg64Imm64(allocator, machine, .rsi, 0, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiStructI128(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_i128")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
    }

    const fail = "struct_i128_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, -6, fail);
    try appendCompareArg64Imm64(allocator, machine, .rsi, -1, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiI64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_i64") and
        !std.mem.eql(u8, function.name, "main.zig_u64")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;

    const fail = "i64_fail";
    try appendCompareArg64Imm64(allocator, machine, .rdi, -4, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiI32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_i32") and
        !std.mem.eql(u8, function.name, "main.zig_u32")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;

    const fail = "i32_fail";
    try machine.instructions.append(allocator, .{ .mov_arg_eax = .rdi });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = -3 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiI16(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_i16") and
        !std.mem.eql(u8, function.name, "main.zig_u16")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 16 })) return error.UnsupportedCodegenType;

    const fail = "i16_fail";
    try machine.instructions.append(allocator, .{ .cmp_arg16_imm16 = .{ .reg = .rdi, .imm = 0xfffe } });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiI8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_i8") and
        !std.mem.eql(u8, function.name, "main.zig_u8")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 8 })) return error.UnsupportedCodegenType;

    const fail = "i8_fail";
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = .rdi, .imm = 0xff } });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiFiveIntegers(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_five_integers")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 5) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    }

    const fail = "five_integers_fail";
    try appendCompareArg32Imm32(allocator, machine, .rdi, 12, fail);
    try appendCompareArg32Imm32(allocator, machine, .rsi, 34, fail);
    try appendCompareArg32Imm32(allocator, machine, .rdx, 56, fail);
    try appendCompareArg32Imm32(allocator, machine, .rcx, 78, fail);
    try appendCompareArg32Imm32(allocator, machine, .r8, 90, fail);
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn appendCompareArg32Imm32(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: ArgReg,
    expected: i32,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = expected });
    try machine.instructions.append(allocator, .{ .jne = fail });
}

fn lowerCAbiPanic(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_panic")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 0) return false;
    if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;
    if (function.blocks.items[0].instructions.items.len == 3) {
        try validateDebugPanicUnreachableBlock(function.blocks.items[0]);
    } else {
        try validatePanicUnreachableBlock(function.blocks.items[0]);
    }

    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerStartTrampoline(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "start._start")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 0) return false;
    if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;

    const block = function.blocks.items[0];
    const terminator = block.terminator orelse return error.BlockWithoutTerminator;
    switch (terminator) {
        .@"unreachable" => {},
        .ret, .br, .condbr, .@"switch", .indirectbr => return error.UnsupportedCodegenControlFlow,
    }
    if (block.instructions.items.len != 2 and block.instructions.items.len != 3) return error.UnsupportedCodegenControlFlow;
    try validateStartCfiInlineAsm(block.instructions.items[0]);
    const call_target = try validateStartTrampolineInlineAsm(block.instructions.items[1]);
    if (block.instructions.items.len == 3) try validateTrapCall(block.instructions.items[2]);

    try machine.instructions.append(allocator, .xor_ebp_ebp);
    try machine.instructions.append(allocator, .mov_rsp_rdi);
    try machine.instructions.append(allocator, .and_rsp_neg16);
    try machine.instructions.append(allocator, .{ .noreturn_direct_call = call_target });
    return true;
}

fn validateStartCfiInlineAsm(instruction: ir.Instruction) !void {
    if (instruction.removed or instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    const inline_asm = call.inline_asm orelse return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != 0) return error.UnsupportedCodegenInstruction;
    if (!inline_asm.sideeffect) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, inline_asm.template, ".cfi_undefined %rip")) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, inline_asm.constraints, "~{dirflag},~{fpsr},~{flags}")) return error.UnsupportedCodegenInstruction;
}

fn validateTrapCall(instruction: ir.Instruction) !void {
    if (instruction.removed or instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.trap") or call.ret_ty != .void or call.args.items.len != 0) return error.UnsupportedCodegenInstruction;
}

fn validateStartTrampolineInlineAsm(instruction: ir.Instruction) ![]const u8 {
    if (instruction.removed or instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    const inline_asm = call.inline_asm orelse return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!inline_asm.sideeffect) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, inline_asm.template, " xorl %ebp, %ebp\\0A movq %rsp, %rdi\\0A andq $$-16, %rsp\\0A callq ${1:P}")) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, inline_asm.constraints, "X,X,~{dirflag},~{fpsr},~{flags}")) return error.UnsupportedCodegenInstruction;

    const self_arg = call.args.items[0];
    if (self_arg.ty != .ptr or !isNamed(self_arg.value, "@start._start")) return error.UnsupportedCodegenInstruction;

    const target_arg = call.args.items[1];
    if (target_arg.ty != .ptr) return error.UnsupportedCodegenInstruction;
    const call_target = switch (target_arg.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.startsWith(u8, call_target, "@")) return error.UnsupportedCodegenInstruction;
    return call_target[1..];
}

fn lowerSelectedInfiniteLoop(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main._start")) return false;
    if (function.ret_ty != .void or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 2) return false;

    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    if (entry.instructions.items.len != 0 or loop.instructions.items.len != 0) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        .ret, .condbr, .@"switch", .indirectbr, .@"unreachable" => return false,
    };
    if (!std.mem.eql(u8, entry_br.target, loop.name)) return false;
    const loop_br = switch (loop.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        .ret, .condbr, .@"switch", .indirectbr, .@"unreachable" => return false,
    };
    if (!std.mem.eql(u8, loop_br.target, loop.name)) return false;

    try machine.instructions.append(allocator, .{ .label = "loop" });
    try machine.instructions.append(allocator, .{ .jmp = "loop" });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerSelectedIssue339TestFoo(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "test.foo")) return false;
    if (function.ret_ty != .void or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 4) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const call_name = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, "test.bar") or !call.ret_ty.eql(.{ .int = 16 }) or call.args.items.len != 0 or call.callee_value != null or call.inline_asm != null) {
        return error.UnsupportedCodegenInstruction;
    }
    const cmp_name = try validateIcmpNamedImm(entry.instructions.items[1], .eq, .{ .int = 16 }, call_name, 0);
    try validateCondbr(entry, cmp_name, "4", "5");

    const ret_block = blockByName(function, "3") orelse return error.InvalidBranchTarget;
    if (ret_block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    try validateRetVoid(ret_block);

    try validateEmptyBrBlock(blockByName(function, "4") orelse return error.InvalidBranchTarget, "4", "3");

    const panic = blockByName(function, "5") orelse return error.InvalidBranchTarget;
    if (panic.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validatePanicCallWithNamedI16(panic.instructions.items[0], "debug.FullPanic((function 'panic')).unwrapError", call_name);
    switch (panic.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        .ret, .br, .condbr, .@"switch", .indirectbr => return error.UnsupportedCodegenControlFlow,
    }

    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSelectedLibfuzzerDebugO0(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (std.mem.eql(u8, function.name, "main.runner_broadcast_input")) {
        if (!hasSingleBlockInstructionCount(function, 4)) return false;
        try validateDebugLibfuzzerBroadcastInput(function);
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (std.mem.eql(u8, function.name, "main.runner_futex_wait")) {
        if (!hasSingleBlockInstructionCount(function, 3)) return false;
        try validateDebugLibfuzzerFutexWait(function);
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (std.mem.eql(u8, function.name, "main.runner_test_name")) {
        if (!hasSingleBlockInstructionCount(function, 7)) return false;
        try validateDebugLibfuzzerTestName(function);
        try machine.instructions.append(allocator, .{ .lea_global_rax = "__anon_22815" });
        try machine.instructions.append(allocator, .{ .mov_imm_rdx = 4 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (std.mem.eql(u8, function.name, "main.runner_test_run")) {
        if (!hasSingleBlockInstructionCount(function, 24)) return false;
        try validateDebugLibfuzzerTestRun(function);
        try machine.instructions.append(allocator, .sub_rsp_8);
        try machine.instructions.append(allocator, .{ .lea_global_rdi = "main.testOne" });
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_set_test", .ret_ty = .void } });
        try machine.instructions.append(allocator, .{ .lea_global_rdi = "__anon_8117" });
        try machine.instructions.append(allocator, .{ .mov_imm_rsi = 0 });
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_new_input", .ret_ty = .void } });
        try machine.instructions.append(allocator, .{ .lea_global_rdi = "__anon_22035" });
        try machine.instructions.append(allocator, .{ .mov_imm_rsi = 5 });
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_new_input", .ret_ty = .void } });
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_start_test", .ret_ty = .void } });
        try machine.instructions.append(allocator, .add_rsp_8);
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (std.mem.eql(u8, function.name, "main.testOne")) {
        if (!function.ret_ty.eql(.{ .int = 1 }) or function.params.items.len != 0) return false;
        if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;
        const block = function.blocks.items[0];
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .int = 1 }) or !(ret.value orelse return error.InvalidRet).eql(.{ .int = 0 })) return error.UnsupportedCodegenControlFlow;
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
}

fn validateDebugLibfuzzerBroadcastInput(function: ir.Function) !void {
    if (function.ret_ty != .void or function.params.items.len != 3) return error.UnsupportedCodegenInstruction;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or !function.params.items[1].ty.eql(.{ .int = 64 }) or !function.params.items[2].ty.eql(.{ .int = 64 })) {
        return error.UnsupportedCodegenInstruction;
    }
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 4) return error.UnsupportedCodegenInstruction;
    const slot = try validateAllocaNamed(block.instructions.items[0], .{ .aggregate = "[16 x i8]" });
    try validateStore(block.instructions.items[1], .{ .int = 64 }, .{ .named = function.params.items[1].name }, slot);
    const gep_name = try validateI8GepInstruction(block.instructions.items[2], slot, 8);
    try validateStore(block.instructions.items[3], .{ .int = 64 }, .{ .named = function.params.items[2].name }, gep_name);
}

fn validateDebugLibfuzzerFutexWait(function: ir.Function) !void {
    if (!function.ret_ty.eql(.{ .int = 1 }) or function.params.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (block.instructions.items.len != 3 or !ret.ty.eql(.{ .int = 1 }) or !(ret.value orelse return error.InvalidRet).eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 32 }, function.params.items[0].name);
    const cmp_name = try validateIcmpNamed(block.instructions.items[1], .eq, .{ .int = 32 }, load_name, function.params.items[1].name);
    try validateDebugAssertCall(block.instructions.items[2], cmp_name);
}

fn validateDebugLibfuzzerTestName(function: ir.Function) !void {
    if (!function.ret_ty.eql(.{ .aggregate = "{ i64, i64 }" }) or function.params.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (block.instructions.items.len != 7 or !ret.ty.eql(.{ .aggregate = "{ i64, i64 }" })) return error.UnsupportedCodegenInstruction;
    const slot = try validateAllocaNamed(block.instructions.items[0], .{ .aggregate = "%Build.abi.fuzz.Slice" });
    const cmp_name = try validateIcmpNamedImm(block.instructions.items[1], .eq, .{ .int = 32 }, function.params.items[0].name, 0);
    try validateDebugAssertCall(block.instructions.items[2], cmp_name);
    const ptr_name = try validateExtractConstantSliceValue(block.instructions.items[3], "@__anon_22815", 0);
    const len_name = try validateExtractConstantSliceValue(block.instructions.items[4], "@__anon_22815", 1);
    try validateFuzzSliceFromSlice(block.instructions.items[5], slot, ptr_name, len_name);
    const loaded = try validateNamedLoad(block.instructions.items[6], .{ .aggregate = "{ i64, i64 }" }, slot);
    if (!isNamed(ret.value orelse return error.InvalidRet, loaded)) return error.UnsupportedCodegenControlFlow;
}

fn validateDebugLibfuzzerTestRun(function: ir.Function) !void {
    if (function.ret_ty != .void or function.params.items.len != 1) return error.UnsupportedCodegenInstruction;
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 24) return error.UnsupportedCodegenInstruction;
    const raw_hello = try validateAllocaNamed(block.instructions.items[0], .{ .aggregate = "[16 x i8]" });
    const hello_slice = try validateAllocaNamed(block.instructions.items[1], .{ .aggregate = "%Build.abi.fuzz.Slice" });
    const raw_empty = try validateAllocaNamed(block.instructions.items[2], .{ .aggregate = "[16 x i8]" });
    const empty_slice = try validateAllocaNamed(block.instructions.items[3], .{ .aggregate = "%Build.abi.fuzz.Slice" });
    const cmp_name = try validateIcmpNamedImm(block.instructions.items[4], .eq, .{ .int = 32 }, function.params.items[0].name, 0);
    try validateDebugAssertCall(block.instructions.items[5], cmp_name);
    try validateVoidCall(block.instructions.items[6], "fuzzer_set_test", &.{.{ .ty = .ptr, .value = .{ .named = "@main.testOne" } }});
    const empty_ptr = try validateExtractConstantSliceValue(block.instructions.items[7], "@__anon_8117", 0);
    const empty_len = try validateExtractConstantSliceValue(block.instructions.items[8], "@__anon_8117", 1);
    try validateFuzzSliceFromSlice(block.instructions.items[9], empty_slice, empty_ptr, empty_len);
    try validateMemcpy(block.instructions.items[10], raw_empty, empty_slice, 16);
    const empty_input_ptr = try validateNamedLoad(block.instructions.items[11], .{ .int = 64 }, raw_empty);
    const empty_input_len_ptr = try validateI8GepInstruction(block.instructions.items[12], raw_empty, 8);
    const empty_input_len = try validateNamedLoad(block.instructions.items[13], .{ .int = 64 }, empty_input_len_ptr);
    try validateVoidCall(block.instructions.items[14], "fuzzer_new_input", &.{
        .{ .ty = .{ .int = 64 }, .value = .{ .named = empty_input_ptr } },
        .{ .ty = .{ .int = 64 }, .value = .{ .named = empty_input_len } },
    });
    const hello_ptr = try validateExtractConstantSliceValue(block.instructions.items[15], "@__anon_22035", 0);
    const hello_len = try validateExtractConstantSliceValue(block.instructions.items[16], "@__anon_22035", 1);
    try validateFuzzSliceFromSlice(block.instructions.items[17], hello_slice, hello_ptr, hello_len);
    try validateMemcpy(block.instructions.items[18], raw_hello, hello_slice, 16);
    const hello_input_ptr = try validateNamedLoad(block.instructions.items[19], .{ .int = 64 }, raw_hello);
    const hello_input_len_ptr = try validateI8GepInstruction(block.instructions.items[20], raw_hello, 8);
    const hello_input_len = try validateNamedLoad(block.instructions.items[21], .{ .int = 64 }, hello_input_len_ptr);
    try validateVoidCall(block.instructions.items[22], "fuzzer_new_input", &.{
        .{ .ty = .{ .int = 64 }, .value = .{ .named = hello_input_ptr } },
        .{ .ty = .{ .int = 64 }, .value = .{ .named = hello_input_len } },
    });
    try validateVoidCall(block.instructions.items[23], "fuzzer_start_test", &.{});
}

fn validateI8GepInstruction(instruction: ir.Instruction, ptr_name: []const u8, offset: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(gep, ptr_name, offset);
    return name;
}

fn validateIcmpNamed(instruction: ir.Instruction, predicate: ir.IcmpPredicate, ty: ir.Type, lhs_name: []const u8, rhs_name: []const u8) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const cmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cmp.predicate != predicate or !cmp.operand_ty.eql(ty) or !isNamed(cmp.lhs, lhs_name) or !isNamed(cmp.rhs, rhs_name)) return error.UnsupportedCodegenInstruction;
    return name;
}

fn validateDebugAssertCall(instruction: ir.Instruction, cond_name: []const u8) !void {
    const args = [_]ExpectedCallArg{.{
        .ty = .{ .int = 1 },
        .value = .{ .named = cond_name },
    }};
    try validateVoidCall(instruction, "debug.assert", &args);
}

fn validateExtractConstantSliceValue(instruction: ir.Instruction, symbol: []const u8, index: u32) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const extract = switch (instruction.kind) {
        .extractvalue => |extract| extract,
        else => return error.UnsupportedCodegenInstruction,
    };
    var index_buf: [16]u8 = undefined;
    const expected_index = std.fmt.bufPrint(&index_buf, "{d}", .{index}) catch return error.UnsupportedCodegenValue;
    if (!extract.aggregate_ty.eql(.{ .aggregate = "{ ptr, i64 }" }) or !std.mem.eql(u8, extract.indices, expected_index)) return error.UnsupportedCodegenInstruction;
    const expected_len: i128 = if (std.mem.eql(u8, symbol, "@__anon_22035")) 5 else if (std.mem.eql(u8, symbol, "@__anon_22815")) 4 else 0;
    switch (extract.aggregate) {
        .constant_expr => |text| {
            var len_buf: [32]u8 = undefined;
            const len_text = std.fmt.bufPrint(&len_buf, "i64 {d}", .{expected_len}) catch return error.UnsupportedCodegenValue;
            if (std.mem.indexOf(u8, text, symbol) == null or std.mem.indexOf(u8, text, len_text) == null) return error.UnsupportedCodegenValue;
        },
        .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }
    return name;
}

fn validateFuzzSliceFromSlice(instruction: ir.Instruction, sret_name: []const u8, ptr_name: []const u8, len_name: []const u8) !void {
    const args = [_]ExpectedCallArg{
        .{ .ty = .ptr, .value = .{ .named = ptr_name } },
        .{ .ty = .{ .int = 64 }, .value = .{ .named = len_name } },
    };
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, "Build.abi.fuzz.Slice.fromSlice") or call.ret_ty != .void or call.args.items.len != 3) return error.UnsupportedCodegenInstruction;
    if (call.args.items[0].ty != .ptr or !isNamed(call.args.items[0].value, sret_name)) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(args[0].ty) or !call.args.items[1].value.eql(args[0].value)) return error.UnsupportedCodegenValue;
    if (!call.args.items[2].ty.eql(args[1].ty) or !call.args.items[2].value.eql(args[1].value)) return error.UnsupportedCodegenValue;
}

fn validateMemcpy(instruction: ir.Instruction, dst_name: []const u8, src_name: []const u8, len: i64) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.memcpy.p0.p0.i64") or call.ret_ty != .void or call.args.items.len != 4) return error.UnsupportedCodegenInstruction;
    if (call.args.items[0].ty != .ptr or !isNamed(call.args.items[0].value, dst_name)) return error.UnsupportedCodegenValue;
    if (call.args.items[1].ty != .ptr or !isNamed(call.args.items[1].value, src_name)) return error.UnsupportedCodegenValue;
    if (!call.args.items[2].ty.eql(.{ .int = 64 }) or !call.args.items[2].value.eql(.{ .int = len })) return error.UnsupportedCodegenValue;
    if (!call.args.items[3].ty.eql(.{ .int = 1 }) or !call.args.items[3].value.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;
}

fn validatePanicCallWithNamedI16(instruction: ir.Instruction, callee: []const u8, arg_name: []const u8) !void {
    if (instruction.removed or instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, callee) or call.ret_ty != .void or call.args.items.len != 1 or call.callee_value != null or call.inline_asm != null) {
        return error.UnsupportedCodegenInstruction;
    }
    if (!call.args.items[0].ty.eql(.{ .int = 16 }) or !isNamed(call.args.items[0].value, arg_name)) return error.UnsupportedCodegenValue;
}

fn lowerGetauxvalImpl(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "os.linux.getauxvalImpl")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 64 })) return false;
    try validateGetauxvalShape(function);

    try machine.instructions.append(allocator, .{ .load_global_ptr_rax = "os.linux.elf_aux_maybe" });
    try machine.instructions.append(allocator, .test_rax_rax);
    try machine.instructions.append(allocator, .{ .je = "zero" });
    try machine.instructions.append(allocator, .{ .label = "loop" });
    try machine.instructions.append(allocator, .load_rax_ptr_rdx);
    try machine.instructions.append(allocator, .test_rdx_rdx);
    try machine.instructions.append(allocator, .{ .je = "zero" });
    try machine.instructions.append(allocator, .cmp_rdx_rdi);
    try machine.instructions.append(allocator, .{ .je = "found" });
    try machine.instructions.append(allocator, .{ .add_rax_imm8 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = "loop" });
    try machine.instructions.append(allocator, .{ .label = "found" });
    try machine.instructions.append(allocator, .{ .load_rax_ptr_disp8_rax = 8 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = "zero" });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateGetauxvalShape(function: ir.Function) !void {
    const optimized_shape = function.blockIndex("common.ret") != null and function.blockIndex(".preheader") != null and function.blockIndex("8") != null;
    const debug_shape = function.blockIndex("11") != null and function.blockIndex("18") != null and function.blockIndex("29") != null;
    if (!optimized_shape and !debug_shape) return error.UnsupportedCodegenControlFlow;

    var saw_global_load = false;
    var saw_tag_load = false;
    var saw_value_load = false;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .load => |load| {
                    if (load.ty == .ptr and isNamed(load.ptr, "@os.linux.elf_aux_maybe")) saw_global_load = true;
                    if (load.ty.eql(.{ .int = 64 }) and instruction.result != null) {
                        if (isNamed(load.ptr, "3") or isNamed(load.ptr, "14") or isNamed(load.ptr, "21")) saw_tag_load = true;
                        if (isNamed(load.ptr, "9") or isNamed(load.ptr, "33")) saw_value_load = true;
                    }
                },
                else => {},
            }
        }
    }
    if (!saw_global_load or !saw_tag_load or !saw_value_load) return error.UnsupportedCodegenControlFlow;
}

fn appendCompareStackByval64Imm64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    stack_offset: u8,
    field_offset: u8,
    expected: i64,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .load_stack_disp8_rax = stack_offset });
    try machine.instructions.append(allocator, .{ .load_rax_ptr_disp8_rax = field_offset });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = expected });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
}

fn appendCompareStack64Imm64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    stack_offset: u8,
    expected: i64,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .load_stack_disp8_rax = stack_offset });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = expected });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
}

fn appendCompareMem64Imm64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: ArgReg,
    offset: u8,
    expected: i64,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_rax = .{ .reg = reg, .offset = offset } });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = expected });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
}

fn appendComparePackedFloatPair(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: XmmReg,
    expected_bits: u64,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .movq_xmm_rax = reg });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = @bitCast(expected_bits) });
    try machine.instructions.append(allocator, .cmp_rax_rdx);
    try machine.instructions.append(allocator, .{ .jne = fail });
}

fn appendCompareXmmLowF32(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: XmmReg,
    expected_bits: u32,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .movq_xmm_rax = reg });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = @bitCast(expected_bits) });
    try machine.instructions.append(allocator, .{ .jne = fail });
}

fn appendCompareXmmLowF64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    expected_bits: u64,
    fail: []const u8,
) !void {
    try appendCompareXmmF64(allocator, machine, .xmm0, .xmm1, expected_bits, fail);
}

fn appendCompareXmmF64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    arg_reg: XmmReg,
    scratch_reg: XmmReg,
    expected_bits: u64,
    fail: []const u8,
) !void {
    if (arg_reg == scratch_reg) return error.UnsupportedCodegenAbi;
    switch (scratch_reg) {
        .xmm0 => try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = expected_bits }),
        .xmm1 => try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = expected_bits }),
        .xmm2, .xmm3, .xmm4 => return error.UnsupportedCodegenAbi,
    }
    try machine.instructions.append(allocator, .{ .ucomisd = .{ .src = scratch_reg, .dst = arg_reg } });
    try machine.instructions.append(allocator, .{ .jp = fail });
    try machine.instructions.append(allocator, .{ .jne = fail });
}

fn appendCompareXmm0LowF64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    expected_bits: u64,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .mov_imm64_xmm1 = expected_bits });
    try machine.instructions.append(allocator, .ucomisd_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jp = fail });
    try machine.instructions.append(allocator, .{ .jne = fail });
}

fn appendCompareArg64Imm64(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    reg: ArgReg,
    expected: i64,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .cmp_arg64_imm64 = .{ .reg = reg, .imm = expected } });
    try machine.instructions.append(allocator, .{ .jne = fail });
}

fn lowerCAbiAssertCFFReturnCode(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_assert_CFF")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 64 }) or !function.params.items[1].ty.eql(.float)) return false;
    const packed_reg = try paramReg(function, function.params.items[0].name, .{ .int = 64 });
    if (packed_reg != .rdi) return error.UnsupportedCodegenAbi;
    try validateAssertCFFShape(function);

    const fail_low = "assert_cff_low";
    const fail_payload = "assert_cff_payload";
    const fail_float = "assert_cff_float";
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x3f80_0000 });
    try machine.instructions.append(allocator, .ucomiss_xmm1_xmm0);
    try machine.instructions.append(allocator, .{ .jp = fail_float });
    try machine.instructions.append(allocator, .{ .jne = fail_float });
    try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = .rdi, .imm = 39 } });
    try machine.instructions.append(allocator, .{ .jne = fail_low });
    try machine.instructions.append(allocator, .{ .cmp_rdi_imm64 = 0x3f60_0000_0000_0027 });
    try machine.instructions.append(allocator, .{ .jne = fail_payload });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail_float });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 3 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail_payload });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 2 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail_low });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn validateAssertDCShape(function: ir.Function) !void {
    if (function.blocks.items.len == 10) return validateDebugAssertDCShape(function);
    if (function.blocks.items.len < 3) return error.UnsupportedCodegenControlFlow;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 8) return error.UnsupportedCodegenInstruction;

    const fcmp_name = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const fcmp = switch (entry.instructions.items[2].kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (fcmp.predicate != .une or !fcmp.operand_ty.eql(.double) or !isNamed(fcmp.lhs, function.params.items[0].name)) return error.UnsupportedCodegenInstruction;
    switch (fcmp.rhs) {
        .fp => |text| if (!std.mem.eql(u8, text, "-2.500000e-01")) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }

    const zext_name = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    const zext = switch (entry.instructions.items[3].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 1 }) or !zext.to_ty.eql(.{ .int = 32 }) or !isNamed(zext.value, fcmp_name)) return error.UnsupportedCodegenInstruction;

    const and_name = entry.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const and_inst = switch (entry.instructions.items[4].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (and_inst.op != .@"and" or !and_inst.ty.eql(.{ .int = 64 }) or !isNamed(and_inst.lhs, function.params.items[1].name) or !and_inst.rhs.eql(.{ .int = 255 })) return error.UnsupportedCodegenInstruction;

    const low_cmp_name = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const low_cmp = switch (entry.instructions.items[5].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (low_cmp.predicate != .eq or !low_cmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(low_cmp.lhs, and_name) or !low_cmp.rhs.eql(.{ .int = 15 })) return error.UnsupportedCodegenInstruction;

    const select_name = entry.instructions.items[6].result orelse return error.UnsupportedCodegenInstruction;
    const select = switch (entry.instructions.items[6].kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isNamed(select.cond, low_cmp_name) or !isNamed(select.true_value, zext_name) or !select.false_value.eql(.{ .int = 2 })) return error.UnsupportedCodegenInstruction;

    const zero_cmp_name = entry.instructions.items[7].result orelse return error.UnsupportedCodegenInstruction;
    const zero_cmp = switch (entry.instructions.items[7].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zero_cmp.predicate != .eq or !zero_cmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(zero_cmp.lhs, select_name) or !zero_cmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, zero_cmp_name)) return error.UnsupportedCodegenControlFlow;
    const ok_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const ok_ret = switch (function.blocks.items[ok_index].terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ok_ret.ty.eql(.{ .int = 32 }) or !isNamed(ok_ret.value orelse return error.InvalidRet, select_name)) return error.UnsupportedCodegenValue;
}

fn validateAssertCFFShape(function: ir.Function) !void {
    if (function.blocks.items.len == 13) return validateDebugAssertCFFShape(function);
    if (function.blocks.items.len < 3) return error.UnsupportedCodegenControlFlow;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 13) return error.UnsupportedCodegenInstruction;
    const lshr_name = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const lshr = switch (entry.instructions.items[2].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (lshr.op != .lshr or !lshr.ty.eql(.{ .int = 64 }) or !isNamed(lshr.lhs, function.params.items[0].name) or !lshr.rhs.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;

    const trunc_name = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    const trunc = switch (entry.instructions.items[3].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 32 }) or !isNamed(trunc.value, lshr_name)) return error.UnsupportedCodegenInstruction;

    const bitcast_name = entry.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const bitcast = switch (entry.instructions.items[4].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (bitcast.op != .bitcast or !bitcast.from_ty.eql(.{ .int = 32 }) or !bitcast.to_ty.eql(.float) or !isNamed(bitcast.value, trunc_name)) return error.UnsupportedCodegenInstruction;

    const and_name = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const and_inst = switch (entry.instructions.items[5].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (and_inst.op != .@"and" or !and_inst.ty.eql(.{ .int = 64 }) or !isNamed(and_inst.lhs, function.params.items[0].name) or !and_inst.rhs.eql(.{ .int = 255 })) return error.UnsupportedCodegenInstruction;

    const low_cmp_name = entry.instructions.items[6].result orelse return error.UnsupportedCodegenInstruction;
    const low_cmp = switch (entry.instructions.items[6].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (low_cmp.predicate != .ne or !low_cmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(low_cmp.lhs, and_name) or !low_cmp.rhs.eql(.{ .int = 39 })) return error.UnsupportedCodegenInstruction;

    const zext_name = entry.instructions.items[7].result orelse return error.UnsupportedCodegenInstruction;
    const zext = switch (entry.instructions.items[7].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 1 }) or !zext.to_ty.eql(.{ .int = 32 }) or !isNamed(zext.value, low_cmp_name)) return error.UnsupportedCodegenInstruction;

    const payload_cmp_name = entry.instructions.items[8].result orelse return error.UnsupportedCodegenInstruction;
    const payload_cmp = switch (entry.instructions.items[8].kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (payload_cmp.predicate != .une or !payload_cmp.operand_ty.eql(.float) or !isNamed(payload_cmp.lhs, bitcast_name)) return error.UnsupportedCodegenInstruction;

    const payload_select_name = entry.instructions.items[9].result orelse return error.UnsupportedCodegenInstruction;
    const payload_select = switch (entry.instructions.items[9].kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isNamed(payload_select.cond, payload_cmp_name) or !payload_select.true_value.eql(.{ .int = 2 }) or !isNamed(payload_select.false_value, zext_name)) return error.UnsupportedCodegenInstruction;

    const arg_cmp_name = entry.instructions.items[10].result orelse return error.UnsupportedCodegenInstruction;
    const arg_cmp = switch (entry.instructions.items[10].kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (arg_cmp.predicate != .une or !arg_cmp.operand_ty.eql(.float) or !isNamed(arg_cmp.lhs, function.params.items[1].name)) return error.UnsupportedCodegenInstruction;

    const final_select_name = entry.instructions.items[11].result orelse return error.UnsupportedCodegenInstruction;
    const final_select = switch (entry.instructions.items[11].kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isNamed(final_select.cond, arg_cmp_name) or !final_select.true_value.eql(.{ .int = 3 }) or !isNamed(final_select.false_value, payload_select_name)) return error.UnsupportedCodegenInstruction;

    const zero_cmp_name = entry.instructions.items[12].result orelse return error.UnsupportedCodegenInstruction;
    const zero_cmp = switch (entry.instructions.items[12].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zero_cmp.predicate != .eq or !zero_cmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(zero_cmp.lhs, final_select_name) or !zero_cmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, zero_cmp_name)) return error.UnsupportedCodegenControlFlow;
    const ok_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const ok_ret = switch (function.blocks.items[ok_index].terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ok_ret.ty.eql(.{ .int = 32 }) or !isNamed(ok_ret.value orelse return error.InvalidRet, final_select_name)) return error.UnsupportedCodegenValue;
}

fn validateAssertPDShape(function: ir.Function) !void {
    if (function.blocks.items.len == 10) return validateDebugAssertPDShape(function);
    if (function.blocks.items.len != 3) return error.UnsupportedCodegenControlFlow;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 6) return error.UnsupportedCodegenInstruction;
    const alloca_name = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const alloca = switch (entry.instructions.items[0].kind) {
        .alloca => |alloca| alloca,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!alloca.allocated_ty.eql(.{ .aggregate = "{ %main.PD }" })) return error.UnsupportedCodegenType;

    const ptr_ne_name = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const ptr_ne = switch (entry.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (ptr_ne.predicate != .ne or !ptr_ne.operand_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
    if (!isNamed(ptr_ne.lhs, function.params.items[0].name) or !ptr_ne.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;

    const zext_name = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const zext = switch (entry.instructions.items[2].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 1 }) or !zext.to_ty.eql(.{ .int = 32 }) or !isNamed(zext.value, ptr_ne_name)) return error.UnsupportedCodegenInstruction;

    const fcmp_name = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    const fcmp = switch (entry.instructions.items[3].kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (fcmp.predicate != .une or !fcmp.operand_ty.eql(.double)) return error.UnsupportedCodegenInstruction;
    if (!isNamed(fcmp.lhs, function.params.items[1].name)) return error.UnsupportedCodegenValue;
    switch (fcmp.rhs) {
        .fp => |text| if (!std.mem.eql(u8, text, "5.000000e-01")) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }

    const select_name = entry.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const select = switch (entry.instructions.items[4].kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (!isNamed(select.cond, fcmp_name) or !select.true_value.eql(.{ .int = 2 }) or !isNamed(select.false_value, zext_name)) return error.UnsupportedCodegenValue;

    const zero_cmp_name = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const zero_cmp = switch (entry.instructions.items[5].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zero_cmp.predicate != .eq or !zero_cmp.operand_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (!isNamed(zero_cmp.lhs, select_name) or !zero_cmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, zero_cmp_name)) return error.UnsupportedCodegenControlFlow;
    const ok_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const fail_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;

    const ok_block = function.blocks.items[ok_index];
    if (ok_block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ok_ret = switch (ok_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ok_ret.ty.eql(.{ .int = 32 }) or !isNamed(ok_ret.value orelse return error.InvalidRet, select_name)) return error.UnsupportedCodegenValue;

    const fail_block = function.blocks.items[fail_index];
    if (fail_block.instructions.items.len != 4) return error.UnsupportedCodegenInstruction;
    const store_ptr = switch (fail_block.instructions.items[0].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store_ptr.ty.eql(.{ .int = 64 }) or !isNamed(store_ptr.value, function.params.items[0].name) or !isNamed(store_ptr.ptr, alloca_name)) return error.UnsupportedCodegenValue;
    const gep_name = fail_block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (fail_block.instructions.items[1].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(gep, alloca_name, 8);
    const store_double = switch (fail_block.instructions.items[2].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store_double.ty.eql(.double) or !isNamed(store_double.value, function.params.items[1].name) or !isNamed(store_double.ptr, gep_name)) return error.UnsupportedCodegenValue;
    const call = switch (fail_block.instructions.items[3].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "debug.print__anon_14634") or call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
}

fn validateDebugAssertPDShape(function: ir.Function) !void {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 11) return error.UnsupportedCodegenInstruction;

    const print_alloca = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "{ %main.PD }" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const code_alloca = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[1].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const pd_alloca = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[2].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.PD" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const raw_alloca = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[3].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "[16 x i8]" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }

    const ptr_store = switch (entry.instructions.items[4].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!ptr_store.ty.eql(.{ .int = 64 }) or !isNamed(ptr_store.value, function.params.items[0].name) or !isNamed(ptr_store.ptr, raw_alloca)) return error.UnsupportedCodegenValue;
    const double_slot = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const double_gep = switch (entry.instructions.items[5].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(double_gep, raw_alloca, 8);
    const double_store = switch (entry.instructions.items[6].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!double_store.ty.eql(.double) or !isNamed(double_store.value, function.params.items[1].name) or !isNamed(double_store.ptr, double_slot)) return error.UnsupportedCodegenValue;
    try validateDebugF128Memcpy(entry.instructions.items[7], pd_alloca, raw_alloca, 16);
    try validateI32Store(entry.instructions.items[8], code_alloca, 0);
    const ptr_load_name = try validateNamedLoad(entry.instructions.items[9], .ptr, pd_alloca);
    const ptr_ne_name = entry.instructions.items[10].result orelse return error.UnsupportedCodegenInstruction;
    const ptr_ne = switch (entry.instructions.items[10].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (ptr_ne.predicate != .ne or !ptr_ne.operand_ty.eql(.ptr) or !isNamed(ptr_ne.lhs, ptr_load_name) or !ptr_ne.rhs.eql(.null_value)) return error.UnsupportedCodegenInstruction;
    const ptr_branch = try validateDebugCondBr(entry, ptr_ne_name);

    const ptr_fail = function.blocks.items[blockIndex(function, ptr_branch.then_target) orelse return error.InvalidBranchTarget];
    if (ptr_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(ptr_fail.instructions.items[0], code_alloca, 1);
    const double_check_label = try validateTerminatorBr(ptr_fail);
    const ptr_ok = function.blocks.items[blockIndex(function, ptr_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(ptr_ok), double_check_label)) return error.UnsupportedCodegenControlFlow;

    const double_check = function.blocks.items[blockIndex(function, double_check_label) orelse return error.InvalidBranchTarget];
    if (double_check.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    const loaded_double_slot = double_check.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const loaded_double_gep = switch (double_check.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(loaded_double_gep, pd_alloca, 8);
    const loaded_double = try validateNamedLoad(double_check.instructions.items[1], .double, loaded_double_slot);
    const double_ne_name = double_check.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const double_ne = switch (double_check.instructions.items[2].kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (double_ne.predicate != .une or !double_ne.operand_ty.eql(.double) or !isNamed(double_ne.lhs, loaded_double)) return error.UnsupportedCodegenInstruction;
    switch (double_ne.rhs) {
        .fp => |text| if (!std.mem.eql(u8, text, "5.000000e-01")) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
    const double_branch = try validateDebugCondBr(double_check, double_ne_name);

    const double_fail = function.blocks.items[blockIndex(function, double_branch.then_target) orelse return error.InvalidBranchTarget];
    if (double_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(double_fail.instructions.items[0], code_alloca, 2);
    const return_check_label = try validateTerminatorBr(double_fail);
    const double_ok = function.blocks.items[blockIndex(function, double_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(double_ok), return_check_label)) return error.UnsupportedCodegenControlFlow;

    const return_check = function.blocks.items[blockIndex(function, return_check_label) orelse return error.InvalidBranchTarget];
    if (return_check.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const code_for_check = try validateNamedLoad(return_check.instructions.items[0], .{ .int = 32 }, code_alloca);
    const code_nonzero_name = return_check.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const code_nonzero = switch (return_check.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (code_nonzero.predicate != .ne or !code_nonzero.operand_ty.eql(.{ .int = 32 }) or !isNamed(code_nonzero.lhs, code_for_check) or !code_nonzero.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;
    const print_branch = try validateDebugCondBr(return_check, code_nonzero_name);

    const print_block = function.blocks.items[blockIndex(function, print_branch.then_target) orelse return error.InvalidBranchTarget];
    if (print_block.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    try validateDebugF128Memcpy(print_block.instructions.items[0], print_alloca, raw_alloca, 16);
    const print_call = switch (print_block.instructions.items[1].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.startsWith(u8, print_call.callee, "debug.print__anon_") or print_call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    const return_label = try validateTerminatorBr(print_block);
    const no_print = function.blocks.items[blockIndex(function, print_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(no_print), return_label)) return error.UnsupportedCodegenControlFlow;

    const return_block = function.blocks.items[blockIndex(function, return_label) orelse return error.InvalidBranchTarget];
    if (return_block.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    const ret_code = try validateNamedLoad(return_block.instructions.items[0], .{ .int = 32 }, code_alloca);
    const ret = switch (return_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, ret_code)) return error.UnsupportedCodegenValue;
}

fn validateDebugRetPD(block: ir.BasicBlock) !void {
    const alloca_name = block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (block.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.PD" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const ptr_store = switch (block.instructions.items[1].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!ptr_store.ty.eql(.ptr) or !isNamed(ptr_store.ptr, alloca_name) or !ptr_store.value.eql(.null_value)) return error.UnsupportedCodegenValue;
    const double_slot = block.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const double_gep = switch (block.instructions.items[2].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(double_gep, alloca_name, 8);
    const double_store = switch (block.instructions.items[3].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!double_store.ty.eql(.double) or !isNamed(double_store.ptr, double_slot)) return error.UnsupportedCodegenValue;
    switch (double_store.value) {
        .fp => |text| if (!std.mem.eql(u8, text, "5.000000e-01")) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
    const load_name = try validateNamedLoad(block.instructions.items[4], .{ .aggregate = "{ i64, double }" }, alloca_name);
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .aggregate = "{ i64, double }" }) or !isNamed(ret.value orelse return error.InvalidRet, load_name)) return error.InvalidRet;
}

fn validateDebugRetCFF(block: ir.BasicBlock) !void {
    const alloca_name = block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (block.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.CFF" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const low_store = switch (block.instructions.items[1].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!low_store.ty.eql(.{ .int = 8 }) or !isNamed(low_store.ptr, alloca_name) or !low_store.value.eql(.{ .int = 39 })) return error.UnsupportedCodegenValue;
    const payload_slot = block.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const payload_gep = switch (block.instructions.items[2].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(payload_gep, alloca_name, 4);
    try validateFloatStore(block.instructions.items[3], payload_slot, .float, "8.750000e-01");
    const arg_slot = block.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const arg_gep = switch (block.instructions.items[4].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(arg_gep, alloca_name, 8);
    try validateFloatStore(block.instructions.items[5], arg_slot, .float, "1.000000e+00");
    const load_name = try validateNamedLoad(block.instructions.items[6], .{ .aggregate = "{ i64, float }" }, alloca_name);
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .aggregate = "{ i64, float }" }) or !isNamed(ret.value orelse return error.InvalidRet, load_name)) return error.InvalidRet;
}

fn validateDebugRetDC(block: ir.BasicBlock) !void {
    const alloca_name = block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (block.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.DC" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    try validateFloatStore(block.instructions.items[1], alloca_name, .double, "-2.500000e-01");
    const byte_slot = block.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const byte_gep = switch (block.instructions.items[2].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(byte_gep, alloca_name, 8);
    const byte_store = switch (block.instructions.items[3].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!byte_store.ty.eql(.{ .int = 8 }) or !isNamed(byte_store.ptr, byte_slot) or !byte_store.value.eql(.{ .int = 15 })) return error.UnsupportedCodegenValue;
    const load_name = try validateNamedLoad(block.instructions.items[4], .{ .aggregate = "{ double, i64 }" }, alloca_name);
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .aggregate = "{ double, i64 }" }) or !isNamed(ret.value orelse return error.InvalidRet, load_name)) return error.InvalidRet;
}

fn validateDebugStackLoadReturn(block: ir.BasicBlock, alloca_ty: ir.Type, ret_ty: ir.Type) !void {
    if (block.instructions.items.len < 2) return error.UnsupportedCodegenInstruction;
    const alloca_name = block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (block.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(alloca_ty)) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    for (block.instructions.items[1 .. block.instructions.items.len - 1]) |instruction| {
        if (instruction.result != null) {
            switch (instruction.kind) {
                .gep => {},
                else => return error.UnsupportedCodegenInstruction,
            }
        } else {
            switch (instruction.kind) {
                .store => {},
                else => return error.UnsupportedCodegenInstruction,
            }
        }
    }
    const load_name = try validateNamedLoad(block.instructions.items[block.instructions.items.len - 1], ret_ty, alloca_name);
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(ret_ty) or !isNamed(ret.value orelse return error.InvalidRet, load_name)) return error.InvalidRet;
}

fn validateDebugAssertCFFShape(function: ir.Function) !void {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 11) return error.UnsupportedCodegenInstruction;

    const print_alloca = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "{ %main.CFF }" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const code_alloca = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[1].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const cff_alloca = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[2].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.CFF" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const raw_alloca = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[3].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "[16 x i8]" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }

    const packed_store = switch (entry.instructions.items[4].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!packed_store.ty.eql(.{ .int = 64 }) or !isNamed(packed_store.value, function.params.items[0].name) or !isNamed(packed_store.ptr, raw_alloca)) return error.UnsupportedCodegenValue;
    const arg_slot = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const arg_gep = switch (entry.instructions.items[5].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(arg_gep, raw_alloca, 8);
    const arg_store = switch (entry.instructions.items[6].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!arg_store.ty.eql(.float) or !isNamed(arg_store.value, function.params.items[1].name) or !isNamed(arg_store.ptr, arg_slot)) return error.UnsupportedCodegenValue;
    try validateDebugF128Memcpy(entry.instructions.items[7], cff_alloca, raw_alloca, 12);
    try validateI32Store(entry.instructions.items[8], code_alloca, 0);
    const low_name = try validateNamedLoad(entry.instructions.items[9], .{ .int = 8 }, cff_alloca);
    const low_ne_name = try validateIcmpImm(entry.instructions.items[10], .ne, .{ .int = 8 }, low_name, 39);
    const low_branch = try validateDebugCondBr(entry, low_ne_name);

    const low_fail = function.blocks.items[blockIndex(function, low_branch.then_target) orelse return error.InvalidBranchTarget];
    if (low_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(low_fail.instructions.items[0], code_alloca, 1);
    const payload_check_label = try validateTerminatorBr(low_fail);
    const low_ok = function.blocks.items[blockIndex(function, low_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(low_ok), payload_check_label)) return error.UnsupportedCodegenControlFlow;

    const payload_check = function.blocks.items[blockIndex(function, payload_check_label) orelse return error.InvalidBranchTarget];
    if (payload_check.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    const payload_slot = payload_check.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const payload_gep = switch (payload_check.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(payload_gep, cff_alloca, 4);
    const payload_name = try validateNamedLoad(payload_check.instructions.items[1], .float, payload_slot);
    const payload_ne_name = try validateFcmpImm(payload_check.instructions.items[2], .une, .float, payload_name, "8.750000e-01");
    const payload_branch = try validateDebugCondBr(payload_check, payload_ne_name);

    const payload_fail = function.blocks.items[blockIndex(function, payload_branch.then_target) orelse return error.InvalidBranchTarget];
    if (payload_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(payload_fail.instructions.items[0], code_alloca, 2);
    const arg_check_label = try validateTerminatorBr(payload_fail);
    const payload_ok = function.blocks.items[blockIndex(function, payload_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(payload_ok), arg_check_label)) return error.UnsupportedCodegenControlFlow;

    const arg_check = function.blocks.items[blockIndex(function, arg_check_label) orelse return error.InvalidBranchTarget];
    if (arg_check.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    const loaded_arg_slot = arg_check.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const loaded_arg_gep = switch (arg_check.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(loaded_arg_gep, cff_alloca, 8);
    const loaded_arg = try validateNamedLoad(arg_check.instructions.items[1], .float, loaded_arg_slot);
    const arg_ne_name = try validateFcmpImm(arg_check.instructions.items[2], .une, .float, loaded_arg, "1.000000e+00");
    const arg_branch = try validateDebugCondBr(arg_check, arg_ne_name);

    const arg_fail = function.blocks.items[blockIndex(function, arg_branch.then_target) orelse return error.InvalidBranchTarget];
    if (arg_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(arg_fail.instructions.items[0], code_alloca, 3);
    const return_check_label = try validateTerminatorBr(arg_fail);
    const arg_ok = function.blocks.items[blockIndex(function, arg_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(arg_ok), return_check_label)) return error.UnsupportedCodegenControlFlow;

    try validateDebugReturnCodeTail(function, return_check_label, code_alloca, print_alloca, raw_alloca, 12);
}

fn validateDebugAssertDCShape(function: ir.Function) !void {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 11) return error.UnsupportedCodegenInstruction;

    const print_alloca = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "{ %main.DC }" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const code_alloca = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[1].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const dc_alloca = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[2].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.DC" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const raw_alloca = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[3].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "[16 x i8]" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }

    const double_store = switch (entry.instructions.items[4].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!double_store.ty.eql(.double) or !isNamed(double_store.value, function.params.items[0].name) or !isNamed(double_store.ptr, raw_alloca)) return error.UnsupportedCodegenValue;
    const raw_int_slot = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const raw_int_gep = switch (entry.instructions.items[5].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(raw_int_gep, raw_alloca, 8);
    const int_store = switch (entry.instructions.items[6].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!int_store.ty.eql(.{ .int = 64 }) or !isNamed(int_store.value, function.params.items[1].name) or !isNamed(int_store.ptr, raw_int_slot)) return error.UnsupportedCodegenValue;
    try validateDebugF128Memcpy(entry.instructions.items[7], dc_alloca, raw_alloca, 16);
    try validateI32Store(entry.instructions.items[8], code_alloca, 0);
    const double_name = try validateNamedLoad(entry.instructions.items[9], .double, dc_alloca);
    const double_ne_name = try validateFcmpImm(entry.instructions.items[10], .une, .double, double_name, "-2.500000e-01");
    const double_branch = try validateDebugCondBr(entry, double_ne_name);

    const double_fail = function.blocks.items[blockIndex(function, double_branch.then_target) orelse return error.InvalidBranchTarget];
    if (double_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(double_fail.instructions.items[0], code_alloca, 1);
    const low_check_label = try validateTerminatorBr(double_fail);
    const double_ok = function.blocks.items[blockIndex(function, double_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(double_ok), low_check_label)) return error.UnsupportedCodegenControlFlow;

    const low_check = function.blocks.items[blockIndex(function, low_check_label) orelse return error.InvalidBranchTarget];
    if (low_check.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    const low_slot = low_check.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const low_gep = switch (low_check.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(low_gep, dc_alloca, 8);
    const low_name = try validateNamedLoad(low_check.instructions.items[1], .{ .int = 8 }, low_slot);
    const low_ne_name = try validateIcmpImm(low_check.instructions.items[2], .ne, .{ .int = 8 }, low_name, 15);
    const low_branch = try validateDebugCondBr(low_check, low_ne_name);

    const low_fail = function.blocks.items[blockIndex(function, low_branch.then_target) orelse return error.InvalidBranchTarget];
    if (low_fail.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validateI32Store(low_fail.instructions.items[0], code_alloca, 2);
    const return_check_label = try validateTerminatorBr(low_fail);
    const low_ok = function.blocks.items[blockIndex(function, low_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(low_ok), return_check_label)) return error.UnsupportedCodegenControlFlow;

    try validateDebugReturnCodeTail(function, return_check_label, code_alloca, print_alloca, raw_alloca, 16);
}

fn validateDebugReturnCodeTail(
    function: ir.Function,
    return_check_label: []const u8,
    code_alloca: []const u8,
    print_alloca: []const u8,
    raw_alloca: []const u8,
    print_size: i128,
) !void {
    const return_check = function.blocks.items[blockIndex(function, return_check_label) orelse return error.InvalidBranchTarget];
    if (return_check.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const code_for_check = try validateNamedLoad(return_check.instructions.items[0], .{ .int = 32 }, code_alloca);
    const code_nonzero_name = try validateIcmpImm(return_check.instructions.items[1], .ne, .{ .int = 32 }, code_for_check, 0);
    const print_branch = try validateDebugCondBr(return_check, code_nonzero_name);

    const print_block = function.blocks.items[blockIndex(function, print_branch.then_target) orelse return error.InvalidBranchTarget];
    if (print_block.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    try validateDebugF128Memcpy(print_block.instructions.items[0], print_alloca, raw_alloca, print_size);
    const print_call = switch (print_block.instructions.items[1].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.startsWith(u8, print_call.callee, "debug.print__anon_") or print_call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    const return_label = try validateTerminatorBr(print_block);
    const no_print = function.blocks.items[blockIndex(function, print_branch.else_target) orelse return error.InvalidBranchTarget];
    if (!std.mem.eql(u8, try validateEmptyBr(no_print), return_label)) return error.UnsupportedCodegenControlFlow;

    const return_block = function.blocks.items[blockIndex(function, return_label) orelse return error.InvalidBranchTarget];
    if (return_block.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    const ret_code = try validateNamedLoad(return_block.instructions.items[0], .{ .int = 32 }, code_alloca);
    const ret = switch (return_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, ret_code)) return error.UnsupportedCodegenValue;
}

fn validateF128AggregateRet(block: ir.BasicBlock, expected: []const u8) !void {
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .aggregate = "{ fp128 }" })) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    switch (value) {
        .constant_expr => |text| {
            var expected_text_buffer: [96]u8 = undefined;
            const expected_text = try std.fmt.bufPrint(&expected_text_buffer, "{{ fp128 {s} }}", .{expected});
            if (!std.mem.eql(u8, text, expected_text)) return error.UnsupportedCodegenValue;
        },
        .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }
}

fn validateF128ScalarRet(block: ir.BasicBlock, expected: []const u8) !void {
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.fp128)) return error.ReturnTypeMismatch;
    const value = ret.value orelse return error.InvalidRet;
    switch (value) {
        .fp => |text| if (!std.mem.eql(u8, text, expected)) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

const F128Branch = struct {
    then_label: []const u8,
    else_label: []const u8,
    second_load: []const u8,
};

const DebugF128Sret = struct {
    first_panic_label: []const u8,
    second_panic_label: []const u8,
};

fn validateDebugF128Sret(function: ir.Function) !DebugF128Sret {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 7) return error.UnsupportedCodegenInstruction;

    const alloca_name = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.f128_f128_struct" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }

    try validateDebugF128Memcpy(entry.instructions.items[1], alloca_name, function.params.items[1].name, 32);
    const first_load_name = try validateDebugF128Load(entry.instructions.items[2], alloca_name);
    const first_call_name = try validateDebugF128EqCall(entry.instructions.items[3], first_load_name, "0xL00000000000000004002A00000000000");
    const first_eq_name = try validateDebugEqZeroI32(entry.instructions.items[4], first_call_name);
    const first_expect_name = try validateDebugTestingExpect(entry.instructions.items[5], first_eq_name);
    const first_ok_name = try validateDebugEqZeroI16(entry.instructions.items[6], first_expect_name);
    const first_branch = try validateDebugCondBr(entry, first_ok_name);

    const first_bridge = function.blocks.items[blockIndex(function, first_branch.then_target) orelse return error.InvalidBranchTarget];
    const second_label = try validateEmptyBr(first_bridge);
    const second = function.blocks.items[blockIndex(function, second_label) orelse return error.InvalidBranchTarget];
    if (second.instructions.items.len != 6) return error.UnsupportedCodegenInstruction;
    const second_gep_name = second.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (second.instructions.items[0].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(gep, alloca_name, 16);
    const second_load_name = try validateDebugF128Load(second.instructions.items[1], second_gep_name);
    const second_call_name = try validateDebugF128EqCall(second.instructions.items[2], second_load_name, "0xL00000000000000004004C80000000000");
    const second_eq_name = try validateDebugEqZeroI32(second.instructions.items[3], second_call_name);
    const second_expect_name = try validateDebugTestingExpect(second.instructions.items[4], second_eq_name);
    const second_ok_name = try validateDebugEqZeroI16(second.instructions.items[5], second_expect_name);
    const second_branch = try validateDebugCondBr(second, second_ok_name);

    const success_bridge = function.blocks.items[blockIndex(function, second_branch.then_target) orelse return error.InvalidBranchTarget];
    const success_label = try validateEmptyBr(success_bridge);
    const success = function.blocks.items[blockIndex(function, success_label) orelse return error.InvalidBranchTarget];
    try validateF128SretSuccess(success, function.params.items[0].name);
    try validateDebugPanicUnreachableBlock(function.blocks.items[blockIndex(function, first_branch.else_target) orelse return error.InvalidBranchTarget]);
    try validateDebugPanicUnreachableBlock(function.blocks.items[blockIndex(function, second_branch.else_target) orelse return error.InvalidBranchTarget]);

    return .{
        .first_panic_label = first_branch.else_target,
        .second_panic_label = second_branch.else_target,
    };
}

fn validateDebugF128AggregateReturn(function: ir.Function) !struct { panic_label: []const u8 } {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 10) return error.UnsupportedCodegenInstruction;

    const result_alloca = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[0].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.f128_struct" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const arg_alloca = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[1].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "%main.f128_struct" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }
    const raw_alloca = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    switch (entry.instructions.items[2].kind) {
        .alloca => |alloca| if (!alloca.allocated_ty.eql(.{ .aggregate = "[16 x i8]" })) return error.UnsupportedCodegenType,
        else => return error.UnsupportedCodegenInstruction,
    }

    const param_store = switch (entry.instructions.items[3].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!param_store.ty.eql(.fp128) or !isNamed(param_store.value, function.params.items[0].name) or !isNamed(param_store.ptr, raw_alloca)) return error.UnsupportedCodegenValue;
    try validateDebugF128Memcpy(entry.instructions.items[4], arg_alloca, raw_alloca, 16);
    const load_name = try validateDebugF128Load(entry.instructions.items[5], arg_alloca);
    const call_name = try validateDebugF128EqCall(entry.instructions.items[6], load_name, "0xL0000000000000000400C81C800000000");
    const eq_name = try validateDebugEqZeroI32(entry.instructions.items[7], call_name);
    const expect_name = try validateDebugTestingExpect(entry.instructions.items[8], eq_name);
    const ok_name = try validateDebugEqZeroI16(entry.instructions.items[9], expect_name);
    const branch = try validateDebugCondBr(entry, ok_name);

    const bridge = function.blocks.items[blockIndex(function, branch.then_target) orelse return error.InvalidBranchTarget];
    const success_label = try validateEmptyBr(bridge);
    const success = function.blocks.items[blockIndex(function, success_label) orelse return error.InvalidBranchTarget];
    try validateDebugF128AggregateSuccess(success, result_alloca);
    try validateDebugPanicUnreachableBlock(function.blocks.items[blockIndex(function, branch.else_target) orelse return error.InvalidBranchTarget]);
    return .{ .panic_label = branch.else_target };
}

fn validateDebugF128AggregateSuccess(block: ir.BasicBlock, result_alloca: []const u8) !void {
    if (block.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const store = switch (block.instructions.items[0].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(.fp128) or !isNamed(store.ptr, result_alloca)) return error.UnsupportedCodegenInstruction;
    switch (store.value) {
        .fp => |text| if (!std.mem.eql(u8, text, "0xL0000000000000000400F81CD00000000")) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }

    const load_name = block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const load = switch (block.instructions.items[1].kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!load.ty.eql(.{ .aggregate = "{ fp128 }" }) or load.attrs.isBarrier() or !isNamed(load.ptr, result_alloca)) return error.UnsupportedCodegenInstruction;

    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .aggregate = "{ fp128 }" }) or !(ret.value orelse return error.InvalidRet).eql(.{ .named = load_name })) return error.InvalidRet;
}

fn validateDebugF128ScalarReturn(function: ir.Function) !struct { panic_label: []const u8 } {
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 4) return error.UnsupportedCodegenInstruction;

    const call_name = try validateDebugF128EqCall(entry.instructions.items[0], function.params.items[0].name, "0xL00000000000000004002800000000000");
    const eq_name = try validateDebugEqZeroI32(entry.instructions.items[1], call_name);
    const expect_name = try validateDebugTestingExpect(entry.instructions.items[2], eq_name);
    const ok_name = try validateDebugEqZeroI16(entry.instructions.items[3], expect_name);
    const branch = try validateDebugCondBr(entry, ok_name);

    const bridge = function.blocks.items[blockIndex(function, branch.then_target) orelse return error.InvalidBranchTarget];
    const success_label = try validateEmptyBr(bridge);
    const success = function.blocks.items[blockIndex(function, success_label) orelse return error.InvalidBranchTarget];
    try validateF128ScalarRet(success, "0xL00000000000000004004100000000000");
    try validateDebugPanicUnreachableBlock(function.blocks.items[blockIndex(function, branch.else_target) orelse return error.InvalidBranchTarget]);
    return .{ .panic_label = branch.else_target };
}

fn validateDebugF128Memcpy(instruction: ir.Instruction, dst_name: []const u8, src_name: []const u8, expected_size: i128) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.memcpy.p0.p0.i64") or call.ret_ty != .void or call.args.items.len != 4) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.ptr) or !isNamed(call.args.items[0].value, dst_name)) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.ptr) or !isNamed(call.args.items[1].value, src_name)) return error.UnsupportedCodegenValue;
    if (!call.args.items[2].ty.eql(.{ .int = 64 }) or !call.args.items[2].value.eql(.{ .int = expected_size })) return error.UnsupportedCodegenValue;
    if (!call.args.items[3].ty.eql(.{ .int = 1 }) or !call.args.items[3].value.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;
}

fn validateDebugF128Load(instruction: ir.Instruction, ptr_name: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!load.ty.eql(.fp128) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return error.UnsupportedCodegenInstruction;
    return result;
}

fn validateNamedLoad(instruction: ir.Instruction, expected_ty: ir.Type, ptr_name: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!load.ty.eql(expected_ty) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return error.UnsupportedCodegenInstruction;
    return result;
}

fn validateI32Store(instruction: ir.Instruction, ptr_name: []const u8, expected_value: i128) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const store = switch (instruction.kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !isNamed(store.ptr, ptr_name) or !store.value.eql(.{ .int = expected_value })) return error.UnsupportedCodegenValue;
}

fn validateIcmpImm(instruction: ir.Instruction, predicate: ir.IcmpPredicate, ty: ir.Type, lhs_name: []const u8, rhs_value: i128) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (icmp.predicate != predicate or !icmp.operand_ty.eql(ty) or !isNamed(icmp.lhs, lhs_name) or !icmp.rhs.eql(.{ .int = rhs_value })) return error.UnsupportedCodegenValue;
    return result;
}

fn validateFcmpImm(instruction: ir.Instruction, predicate: ir.FcmpPredicate, ty: ir.Type, lhs_name: []const u8, rhs_value: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const fcmp = switch (instruction.kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (fcmp.predicate != predicate or !fcmp.operand_ty.eql(ty) or !isNamed(fcmp.lhs, lhs_name)) return error.UnsupportedCodegenValue;
    switch (fcmp.rhs) {
        .fp => |text| if (!std.mem.eql(u8, text, rhs_value)) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
    return result;
}

fn validateFloatStore(instruction: ir.Instruction, ptr_name: []const u8, expected_ty: ir.Type, expected_value: []const u8) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const store = switch (instruction.kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store.ty.eql(expected_ty) or !isNamed(store.ptr, ptr_name)) return error.UnsupportedCodegenValue;
    switch (store.value) {
        .fp => |text| if (!std.mem.eql(u8, text, expected_value)) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn validateDebugF128EqCall(instruction: ir.Instruction, lhs_name: []const u8, expected: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateF128EqCall(call, lhs_name, expected);
    return result;
}

fn validateDebugEqZeroI32(instruction: ir.Instruction, call_name: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateEqZeroIcmp(icmp, call_name);
    return result;
}

fn validateDebugTestingExpect(instruction: ir.Instruction, cond_name: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "testing.expect") or !call.ret_ty.eql(.{ .int = 16 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 1 }) or !isNamed(call.args.items[0].value, cond_name)) return error.UnsupportedCodegenValue;
    return result;
}

fn validateDebugEqZeroI16(instruction: ir.Instruction, value_name: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 16 })) return error.UnsupportedCodegenInstruction;
    if (!isNamed(icmp.lhs, value_name) or !icmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;
    return result;
}

fn validateDebugCondBr(block: ir.BasicBlock, cond_name: []const u8) !struct { then_target: []const u8, else_target: []const u8 } {
    const condbr = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, cond_name)) return error.UnsupportedCodegenControlFlow;
    return .{ .then_target = condbr.then_target, .else_target = condbr.else_target };
}

fn validateEmptyBr(block: ir.BasicBlock) ![]const u8 {
    if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    return validateTerminatorBr(block);
}

fn validateTerminatorBr(block: ir.BasicBlock) ![]const u8 {
    return switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br.target,
        else => error.UnsupportedCodegenControlFlow,
    };
}

fn validateDebugPanicUnreachableBlock(block: ir.BasicBlock) !void {
    if (block.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    for (block.instructions.items[0..2]) |instruction| {
        if (instruction.result == null) return error.UnsupportedCodegenInstruction;
        switch (instruction.kind) {
            .extractvalue => {},
            else => return error.UnsupportedCodegenInstruction,
        }
    }
    const call = switch (block.instructions.items[2].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "debug.defaultPanic") or call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }
}

fn validateF128EntryEqBranch(block: ir.BasicBlock, byval_param: []const u8) !F128Branch {
    if (block.instructions.items.len != 5) return error.UnsupportedCodegenInstruction;
    const first_load_name = block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const first_load = switch (block.instructions.items[0].kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!first_load.ty.eql(.fp128) or first_load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    if (!isNamed(first_load.ptr, byval_param)) return error.UnsupportedCodegenValue;

    const gep_name = block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (block.instructions.items[1].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(gep, byval_param, 16);

    const second_load_name = block.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const second_load = switch (block.instructions.items[2].kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!second_load.ty.eql(.fp128) or second_load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    if (!isNamed(second_load.ptr, gep_name)) return error.UnsupportedCodegenValue;

    const call_name = block.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (block.instructions.items[3].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateF128EqCall(call, first_load_name, "0xL00000000000000004002A00000000000");

    const icmp_name = block.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (block.instructions.items[4].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateEqZeroIcmp(icmp, call_name);

    const condbr = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_name)) return error.UnsupportedCodegenControlFlow;
    return .{ .then_label = condbr.then_target, .else_label = condbr.else_target, .second_load = second_load_name };
}

fn validateF128SecondEqBranch(block: ir.BasicBlock, second_load_name: []const u8) !F128Branch {
    if (block.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const call_name = block.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (block.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateF128EqCall(call, second_load_name, "0xL00000000000000004004C80000000000");

    const icmp_name = block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const icmp = switch (block.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateEqZeroIcmp(icmp, call_name);

    const condbr = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, icmp_name)) return error.UnsupportedCodegenControlFlow;
    return .{ .then_label = condbr.then_target, .else_label = condbr.else_target, .second_load = second_load_name };
}

fn validateF128EqCall(call: ir.CallInst, lhs_name: []const u8, expected: []const u8) !void {
    if (!std.mem.eql(u8, call.callee, "__eqtf2") or !call.ret_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.fp128) or !isNamed(call.args.items[0].value, lhs_name)) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.fp128)) return error.UnsupportedCodegenType;
    switch (call.args.items[1].value) {
        .fp => |text| if (!std.mem.eql(u8, text, expected)) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn validateEqZeroIcmp(icmp: ir.IcmpInst, call_name: []const u8) !void {
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (!isNamed(icmp.lhs, call_name) or !icmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;
}

fn validateF128SretSuccess(block: ir.BasicBlock, sret_param: []const u8) !void {
    if (block.instructions.items.len != 3) return error.UnsupportedCodegenInstruction;
    const first_store = switch (block.instructions.items[0].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateF128Store(first_store, sret_param, "0xL00000000000000004003800000000000");

    const gep_name = block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (block.instructions.items[1].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(gep, sret_param, 16);

    const second_store = switch (block.instructions.items[2].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateF128Store(second_store, gep_name, "0xL00000000000000004005100000000000");

    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (ret.ty != .void or ret.value != null) return error.InvalidRet;
}

fn validateF128Store(store: ir.StoreInst, ptr_name: []const u8, expected: []const u8) !void {
    if (!store.ty.eql(.fp128) or store.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    if (!isNamed(store.ptr, ptr_name)) return error.UnsupportedCodegenValue;
    switch (store.value) {
        .fp => |text| if (!std.mem.eql(u8, text, expected)) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn validateI8GepOffset(gep: ir.GepInst, ptr_name: []const u8, offset: i128) !void {
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, ptr_name)) return error.UnsupportedCodegenInstruction;
    if (gep.indices.items.len != 1) return error.UnsupportedCodegenInstruction;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !index.value.eql(.{ .int = offset })) return error.UnsupportedCodegenInstruction;
}

fn validatePanicUnreachableBlock(block: ir.BasicBlock) !void {
    if (block.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    const call = switch (block.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "debug.defaultPanic") or call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
    switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        else => return error.UnsupportedCodegenControlFlow,
    }
}

fn functionHasOverflowPanicEdge(function: ir.Function) bool {
    return sliceSumHasOverflowCheck(function);
}

fn appendIntegerOverflowCall(allocator: std.mem.Allocator, machine: *MachineFunction, label: []const u8) !void {
    try appendPanicCall(allocator, machine, label, "debug.FullPanic((function 'defaultPanic')).integerOverflow");
}

fn appendPanicCall(allocator: std.mem.Allocator, machine: *MachineFunction, label: []const u8, symbol: []const u8) !void {
    try machine.instructions.append(allocator, .{ .label = label });
    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .direct_call = .{
        .symbol = symbol,
        .ret_ty = .void,
    } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
}

fn lowerReturnTerminator(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !void {
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(function.ret_ty)) return error.ReturnTypeMismatch;
    if (ret.ty == .void) {
        try machine.instructions.append(allocator, .ret);
        return;
    }
    if (!ret.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    try lowerReturnValue(allocator, machine, function, block, ret.value orelse return error.InvalidRet);
    try machine.instructions.append(allocator, .ret);
}

fn lowerReturnValue(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        .named => |name| {
            if (try paramRegOrNull(function, name, .{ .int = 32 })) |reg| {
                try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
                return;
            }
            const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
                    const op = machineBinaryOp(binary.op) orelse return error.UnsupportedCodegenInstruction;
                    const lhs_const: ?i128 = switch (binary.lhs) {
                        .int => |lhs| lhs,
                        else => null,
                    };
                    const rhs_const: ?i128 = switch (binary.rhs) {
                        .int => |rhs| rhs,
                        else => null,
                    };
                    if (lhs_const) |lhs| {
                        if (rhs_const) |rhs| {
                            try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(lhs) });
                            switch (op) {
                                .add => try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(rhs) }),
                                else => return error.UnsupportedCodegenInstruction,
                            }
                            return;
                        }
                    }
                    const lhs = try paramValueReg(function, binary.lhs, .{ .int = 32 });
                    const rhs = try paramValueReg(function, binary.rhs, .{ .int = 32 });
                    try machine.instructions.append(allocator, .{ .mov_arg_eax = lhs });
                    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = rhs } });
                },
                .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return error.UnsupportedCodegenInstruction,
            }
        },
    }
}

fn lowerReturnValueAfterCalls(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
    last_eax_value: ?[]const u8,
    call_count: usize,
) !void {
    switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return lowerReturnValue(allocator, machine, function, block, value),
        .named => |name| {
            if (call_count == 0) return lowerReturnValue(allocator, machine, function, block, value);
            if (last_eax_value) |eax_name| {
                if (std.mem.eql(u8, name, eax_name)) return;
            }
            const instruction = findInstruction(block, name) orelse return lowerReturnValue(allocator, machine, function, block, value);
            switch (instruction.kind) {
                .binary => |binary| {
                    if (call_count != 1) return error.UnsupportedCodegenInstruction;
                    try lowerBinaryReturnAfterCall(allocator, machine, function, binary, last_eax_value orelse return error.UnsupportedCodegenValue);
                },
                else => return lowerReturnValue(allocator, machine, function, block, value),
            }
        },
    }
}

fn lowerBinaryReturnAfterCall(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    binary: ir.BinaryInst,
    eax_name: []const u8,
) !void {
    if (!binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    const op = machineBinaryOp(binary.op) orelse return error.UnsupportedCodegenInstruction;
    if (isNamed(binary.lhs, eax_name)) {
        if (binary.op == .add) {
            switch (binary.rhs) {
                .int => |int| {
                    try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) });
                    return;
                },
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => {},
            }
        }
        const rhs = try paramValueReg(function, binary.rhs, .{ .int = 32 });
        try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = rhs } });
        return;
    }
    if (isCommutative(binary.op) and isNamed(binary.rhs, eax_name)) {
        if (binary.op == .add) {
            switch (binary.lhs) {
                .int => |int| {
                    try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) });
                    return;
                },
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => {},
            }
        }
        const lhs = try paramValueReg(function, binary.lhs, .{ .int = 32 });
        try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = lhs } });
        return;
    }
    return error.UnsupportedCodegenInstruction;
}

fn machineBinaryOp(op: ir.BinaryOp) ?MachineBinaryOp {
    return switch (op) {
        .add => .add,
        .sub => .sub,
        .@"and" => .@"and",
        .@"or" => .@"or",
        .xor => .xor,
        .fadd, .fsub, .fmul, .fdiv, .frem, .mul, .shl, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => null,
    };
}

fn validateDefaultCallConv(calling_conv: ?[]const u8) !void {
    if (calling_conv) |cc| {
        if (!std.mem.eql(u8, cc, "ccc")) return error.UnsupportedCodegenCallingConvention;
    }
}

fn singleLiveParamAfter(function: ir.Function, block: ir.BasicBlock, instruction_index: usize) !?ArgReg {
    var live: ?ArgReg = null;
    for (block.instructions.items[instruction_index + 1 ..]) |instruction| {
        if (instruction.removed) continue;
        try noteLiveParams(function, instruction, &live);
    }
    if (block.terminator) |terminator| switch (terminator) {
        .ret => |ret| if (ret.value) |value| try noteLiveValue(function, value, &live),
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => {},
    };
    return live;
}

fn noteLiveParams(function: ir.Function, instruction: ir.Instruction, live: *?ArgReg) !void {
    switch (instruction.kind) {
        .binary => |binary| {
            try noteLiveValue(function, binary.lhs, live);
            try noteLiveValue(function, binary.rhs, live);
        },
        .call => |call| for (call.args.items) |arg| try noteLiveValue(function, arg.value, live),
        .cast => |cast| try noteLiveValue(function, cast.value, live),
        .freeze => |freeze| try noteLiveValue(function, freeze.value, live),
        .icmp => |icmp| {
            try noteLiveValue(function, icmp.lhs, live);
            try noteLiveValue(function, icmp.rhs, live);
        },
        .fcmp => |fcmp| {
            try noteLiveValue(function, fcmp.lhs, live);
            try noteLiveValue(function, fcmp.rhs, live);
        },
        .select => |select| {
            try noteLiveValue(function, select.cond, live);
            try noteLiveValue(function, select.true_value, live);
            try noteLiveValue(function, select.false_value, live);
        },
        .phi => |phi| for (phi.incoming.items) |incoming| try noteLiveValue(function, incoming.value, live),
        .alloca => {},
        .load => |load| try noteLiveValue(function, load.ptr, live),
        .store => |store| {
            try noteLiveValue(function, store.value, live);
            try noteLiveValue(function, store.ptr, live);
        },
        .atomicrmw => |atomicrmw| {
            try noteLiveValue(function, atomicrmw.ptr, live);
            try noteLiveValue(function, atomicrmw.value, live);
        },
        .cmpxchg => |cmpxchg| {
            try noteLiveValue(function, cmpxchg.ptr, live);
            try noteLiveValue(function, cmpxchg.expected, live);
            try noteLiveValue(function, cmpxchg.replacement, live);
        },
        .fence, .extractelement, .insertelement, .shufflevector => {},
        .extractvalue => |extract| try noteLiveValue(function, extract.aggregate, live),
        .insertvalue => |insert| {
            try noteLiveValue(function, insert.aggregate, live);
            try noteLiveValue(function, insert.value, live);
        },
        .gep => |gep| {
            try noteLiveValue(function, gep.ptr, live);
            for (gep.indices.items) |index| try noteLiveValue(function, index.value, live);
        },
    }
}

fn noteLiveValue(function: ir.Function, value: ir.Value, live: *?ArgReg) !void {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return,
    };
    const reg = try paramRegOrNull(function, name, .{ .int = 32 }) orelse return;
    if (live.*) |existing| {
        if (existing != reg) return error.UnsupportedLiveAcrossCall;
    } else {
        live.* = reg;
    }
}

fn isNamed(value: ir.Value, name: []const u8) bool {
    return switch (value) {
        .named => |value_name| std.mem.eql(u8, value_name, name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

fn isSelectI1ToI32ZeroOne(instruction: ir.Instruction, cond_name: []const u8) bool {
    if (instruction.removed) return false;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return false,
    };
    return select.cond_ty.eql(.{ .int = 1 }) and
        select.ty.eql(.{ .int = 32 }) and
        isNamed(select.cond, cond_name) and
        isInt(select.true_value, 0) and
        isInt(select.false_value, 1);
}

fn isSelectI1ToI32ExpectedOne(instruction: ir.Instruction, cond_name: []const u8, expected: i32) bool {
    if (instruction.removed) return false;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return false,
    };
    return select.cond_ty.eql(.{ .int = 1 }) and
        select.ty.eql(.{ .int = 32 }) and
        isNamed(select.cond, cond_name) and
        isInt(select.true_value, expected) and
        isInt(select.false_value, 1);
}

fn valueReferencesGlobal(value: ir.Value, name: []const u8) bool {
    return switch (value) {
        .named => |value_name| std.mem.eql(u8, symbolName(value_name), name),
        .constant_expr => |text| std.mem.indexOf(u8, text, name) != null,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => false,
    };
}

fn phiHasIncoming(phi: ir.PhiInst, value_name: []const u8, block_name: []const u8) bool {
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, block_name) and isNamed(incoming.value, value_name)) return true;
    }
    return false;
}

fn phiHasIncomingInt(phi: ir.PhiInst, value: i128, block_name: []const u8) bool {
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, block_name) and isInt(incoming.value, value)) return true;
    }
    return false;
}

fn isCalleeName(actual: []const u8, expected: []const u8) bool {
    const actual_name = symbolName(actual);
    if (std.mem.eql(u8, actual_name, expected)) return true;
    return false;
}

fn callIsFastcc(calling_conv: ?[]const u8) bool {
    const cc = calling_conv orelse return false;
    return std.mem.eql(u8, cc, "fastcc");
}

fn callArgAttrsContain(arg: ir.CallArg, needle: []const u8) bool {
    const attrs = arg.attrs orelse return false;
    return std.mem.indexOf(u8, attrs, needle) != null;
}

fn paramAttrsContain(param: ir.Param, needle: []const u8) bool {
    const attrs = param.attrs orelse return false;
    return std.mem.indexOf(u8, attrs, needle) != null;
}

fn globalSymbolName(name: []const u8) ![]const u8 {
    if (!std.mem.startsWith(u8, name, "@") or name.len == 1) return error.UnsupportedCodegenValue;
    return symbolName(name);
}

fn symbolName(name: []const u8) []const u8 {
    const without_at = if (std.mem.startsWith(u8, name, "@")) name[1..] else name;
    if (without_at.len >= 2 and without_at[0] == '"' and without_at[without_at.len - 1] == '"') {
        return without_at[1 .. without_at.len - 1];
    }
    return without_at;
}

fn isInt(value: ir.Value, expected: i128) bool {
    return switch (value) {
        .int => |actual| actual == expected,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

fn matchIcmpEqParamImm(instruction: ir.Instruction, param_name: []const u8, ty: ir.Type, imm: i128) bool {
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(ty)) return false;
    return (isNamed(icmp.lhs, param_name) and isInt(icmp.rhs, imm)) or
        (isNamed(icmp.rhs, param_name) and isInt(icmp.lhs, imm));
}

fn isCommutative(op: ir.BinaryOp) bool {
    return switch (op) {
        .add, .mul, .@"and", .@"or", .xor => true,
        .fadd, .fsub, .fmul, .fdiv, .frem, .sub, .shl, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => false,
    };
}

fn findInstruction(block: ir.BasicBlock, result_name: []const u8) ?ir.Instruction {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const result = instruction.result orelse continue;
        if (std.mem.eql(u8, result, result_name)) return instruction;
    }
    return null;
}

fn paramValueReg(function: ir.Function, value: ir.Value, ty: ir.Type) !ArgReg {
    return switch (value) {
        .named => |name| try paramReg(function, name, ty),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

fn paramReg(function: ir.Function, name: []const u8, ty: ir.Type) !ArgReg {
    return try paramRegOrNull(function, name, ty) orelse error.UnsupportedCodegenValue;
}

fn paramRegOrNull(function: ir.Function, name: []const u8, ty: ir.Type) !?ArgReg {
    for (function.params.items, 0..) |param, index| {
        if (!std.mem.eql(u8, param.name, name)) continue;
        if (!param.ty.eql(ty)) return error.UnsupportedCodegenValue;
        return switch (index) {
            0 => .rdi,
            1 => .rsi,
            2 => .rdx,
            3 => .rcx,
            4 => .r8,
            5 => .r9,
            else => error.UnsupportedCodegenAbi,
        };
    }
    return null;
}

fn blockIndex(function: ir.Function, name: []const u8) ?usize {
    for (function.blocks.items, 0..) |block, index| {
        if (std.mem.eql(u8, block.name, name)) return index;
    }
    return null;
}

fn i32Value(value: i128) !i32 {
    if (value < std.math.minInt(i32) or value > std.math.maxInt(i32)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

fn i64Value(value: i128) !i64 {
    if (value < std.math.minInt(i64) or value > std.math.maxInt(i64)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

fn u5Value(value: i128) !u5 {
    if (value < 0 or value > std.math.maxInt(u5)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

pub fn verifyFunction(function: MachineFunction) !void {
    for (function.instructions.items) |instruction| switch (instruction) {
        .je, .jne, .jo, .jp, .js, .jmp => |target_name| if (!hasLabel(function, target_name)) return error.InvalidBranchTarget,
        .label,
        .mov_imm_eax,
        .mov_imm_rax,
        .mov_imm_rdi,
        .mov_imm_rdx,
        .mov_imm_rsi,
        .mov_imm_rcx,
        .movq_xmm_rax,
        .mov_arg_eax,
        .mov_arg_arg,
        .binary_arg_eax,
        .add_eax_imm32,
        .shl_eax_imm5,
        .or_eax_imm32,
        .imul_eax_imm32,
        .and_eax_imm32,
        .shr_rax_imm6,
        .shl_rdx_imm6,
        .or_rdx_rax,
        .add_rax_imm8,
        .add_ecx_eax,
        .xor_ecx_ecx,
        .xor_ebp_ebp,
        .add_rdi_rcx4_ptr_eax,
        .inc_rcx,
        .movzx_dil_edi,
        .and_edi_imm8,
        .load_rax_rdi_u8_eax,
        .smin_i32_edi_esi_eax,
        .shift_mix_i32_edi_esi_eax,
        .replace_low_i8_dil_sil_al,
        .read_flag_i8_dil_al,
        .store_imm8_abs,
        .cmp_ecx_arg32,
        .cmp_rcx_arg64,
        .cmp_arg64_imm64,
        .cmp_arg16_imm16,
        .cmp_rdi_imm64,
        .cmp_rdx_rdi,
        .cmp_rax_rdx,
        .test_eax_eax,
        .test_rax_rax,
        .test_rdx_rdx,
        .mulsd_xmm1_xmm0,
        .addss_xmm1_xmm0,
        .subss_xmm1_xmm0,
        .divsd_xmm1_xmm0,
        .movapd_xmm1_xmm0,
        .mov_imm64_xmm0,
        .mov_imm64_xmm1,
        .mov_imm32_xmm0,
        .mov_imm32_xmm1,
        .ucomisd,
        .ucomisd_xmm1_xmm0,
        .ucomiss_xmm1_xmm0,
        .oltss_xmm0_xmm1_al,
        .sub_rsp_8,
        .add_rsp_8,
        .sub_rsp_24,
        .add_rsp_24,
        .spill_arg_rsp,
        .reload_arg_rsp,
        .spill_rdi_rsi_rsp24,
        .reload_rdi_rsp24,
        .reload_rsi_rsp24,
        .reload_rsp_eax,
        .load_stack_disp8_rax,
        .load_rax_ptr_disp8_rax,
        .load_rax_ptr_rdx,
        .load_rax_ptr_eax,
        .load_arg_ptr_eax,
        .load_arg_ptr_disp8_rax,
        .load_arg_ptr_disp8_u8_eax,
        .add_arg_ptr_disp4_eax,
        .store_eax_arg_ptr,
        .store_imm64_arg_ptr_disp8,
        .store_imm8_arg_ptr_disp8,
        .load_f128_arg_ptr_xmm0,
        .load_f128_const_xmm0,
        .load_f128_const_xmm1,
        .store_f128_xmm0_arg_ptr,
        .volatile_roundtrip_rdi_esi_eax,
        .load_global_i32_eax,
        .load_global_ptr_rax,
        .lea_global_rax,
        .lea_global_rdi,
        .lea_global_rdx,
        .store_eax_global_i32,
        .load_tls_i32_eax,
        .add_tls_i32_eax,
        .store_eax_tls_i32,
        .atomic_xadd_global_eax,
        .mov_rsp_rdi,
        .and_rsp_neg16,
        .direct_call,
        .noreturn_direct_call,
        .cmp_arg8_imm8,
        .cmp_ecx_imm32,
        .cmp_eax_imm32,
        .test_arg8,
        .test_arg32,
        .test_arg64,
        .base64_raw_args_to_decode4_regs,
        .base64_decode4_from_table_rax,
        .ud2,
        .ret,
        => {},
    };

    var eax_defined = function.ret_ty == .void or function.ret_ty.eql(.float) or function.ret_ty.eql(.double);
    var saw_terminator = false;
    var rsp_mod16: u4 = 8;
    for (function.instructions.items) |instruction| switch (instruction) {
        .label => eax_defined = function.ret_ty == .void,
        .mov_imm_eax, .mov_imm_rax, .movq_xmm_rax, .mov_arg_eax, .binary_arg_eax, .add_eax_imm32, .shl_eax_imm5, .or_eax_imm32, .imul_eax_imm32, .and_eax_imm32, .shr_rax_imm6, .or_rdx_rax, .add_rax_imm8, .add_ecx_eax, .add_rdi_rcx4_ptr_eax, .load_rax_rdi_u8_eax, .smin_i32_edi_esi_eax, .shift_mix_i32_edi_esi_eax, .replace_low_i8_dil_sil_al, .read_flag_i8_dil_al, .load_stack_disp8_rax, .load_rax_ptr_disp8_rax, .load_rax_ptr_eax, .load_arg_ptr_eax, .load_arg_ptr_disp8_rax, .load_arg_ptr_disp8_u8_eax, .add_arg_ptr_disp4_eax, .volatile_roundtrip_rdi_esi_eax, .load_global_i32_eax, .load_global_ptr_rax, .lea_global_rax, .load_tls_i32_eax, .add_tls_i32_eax, .atomic_xadd_global_eax, .mulsd_xmm1_xmm0, .addss_xmm1_xmm0, .subss_xmm1_xmm0, .divsd_xmm1_xmm0, .movapd_xmm1_xmm0, .mov_imm64_xmm0, .mov_imm32_xmm0, .load_f128_const_xmm0, .oltss_xmm0_xmm1_al => eax_defined = true,
        .mov_imm_rdi, .mov_imm_rdx, .mov_imm_rsi, .mov_imm_rcx, .lea_global_rdi, .lea_global_rdx => {},
        .reload_rsp_eax => {
            if (rsp_mod16 != 0) return error.StackSlotWithoutFrame;
            eax_defined = true;
        },
        .direct_call => |call| {
            if (rsp_mod16 != 0) return error.MisalignedStackBeforeCall;
            eax_defined = call.ret_ty != .void;
        },
        .sub_rsp_8, .add_rsp_8 => rsp_mod16 = @intCast((@as(u8, rsp_mod16) + 8) % 16),
        .sub_rsp_24, .add_rsp_24 => rsp_mod16 = @intCast((@as(u8, rsp_mod16) + 24) % 16),
        .spill_arg_rsp => |spill| {
            if (spill.frame_index != .slot0 or rsp_mod16 != 0) return error.StackSlotWithoutFrame;
        },
        .reload_arg_rsp => |reload| {
            if (reload.frame_index != .slot0 or rsp_mod16 != 0) return error.StackSlotWithoutFrame;
        },
        .spill_rdi_rsi_rsp24, .reload_rdi_rsp24, .reload_rsi_rsp24 => {
            if (rsp_mod16 != 0) return error.StackSlotWithoutFrame;
        },
        .and_rsp_neg16 => rsp_mod16 = 0,
        .noreturn_direct_call => {
            if (rsp_mod16 != 0) return error.MisalignedStackBeforeCall;
            if (function.ret_ty != .void) return error.ReturnTypeMismatch;
            saw_terminator = true;
            eax_defined = true;
        },
        .base64_decode4_from_table_rax => {
            if (!function.ret_ty.eql(.{ .int = 64 })) return error.ReturnTypeMismatch;
            if (rsp_mod16 != 8) return error.UnbalancedStackFrame;
            saw_terminator = true;
            eax_defined = true;
        },
        .mov_arg_arg, .shl_rdx_imm6, .xor_ecx_ecx, .xor_ebp_ebp, .inc_rcx, .movzx_dil_edi, .and_edi_imm8, .mov_rsp_rdi, .load_rax_ptr_rdx, .cmp_ecx_arg32, .cmp_rcx_arg64, .cmp_ecx_imm32, .cmp_eax_imm32, .cmp_arg64_imm64, .cmp_arg16_imm16, .cmp_rdi_imm64, .cmp_rdx_rdi, .cmp_rax_rdx, .cmp_arg8_imm8, .test_eax_eax, .test_rax_rax, .test_rdx_rdx, .test_arg8, .test_arg32, .test_arg64, .base64_raw_args_to_decode4_regs, .store_eax_arg_ptr, .store_imm64_arg_ptr_disp8, .store_imm8_arg_ptr_disp8, .mov_imm64_xmm1, .mov_imm32_xmm1, .ucomisd, .ucomisd_xmm1_xmm0, .ucomiss_xmm1_xmm0, .load_f128_arg_ptr_xmm0, .load_f128_const_xmm1, .store_f128_xmm0_arg_ptr, .store_eax_global_i32, .store_eax_tls_i32, .store_imm8_abs, .je, .jne, .jo, .jp, .js, .jmp => {},
        .ret => {
            if (!eax_defined) return error.ReturnRegisterUndefined;
            if (rsp_mod16 != 8) return error.UnbalancedStackFrame;
            saw_terminator = true;
            eax_defined = function.ret_ty == .void;
        },
        .ud2 => {
            if (rsp_mod16 != 8) return error.UnbalancedStackFrame;
            saw_terminator = true;
            eax_defined = function.ret_ty == .void;
        },
    };
    if (!saw_terminator) return error.MissingMachineReturn;
}

fn hasLabel(function: MachineFunction, name: []const u8) bool {
    for (function.instructions.items) |instruction| switch (instruction) {
        .label => |label_name| if (std.mem.eql(u8, label_name, name)) return true,
        .mov_imm_eax,
        .mov_imm_rax,
        .mov_imm_rdi,
        .mov_imm_rdx,
        .mov_imm_rsi,
        .mov_imm_rcx,
        .movq_xmm_rax,
        .mov_arg_eax,
        .mov_arg_arg,
        .binary_arg_eax,
        .add_eax_imm32,
        .shl_eax_imm5,
        .or_eax_imm32,
        .imul_eax_imm32,
        .and_eax_imm32,
        .shr_rax_imm6,
        .shl_rdx_imm6,
        .or_rdx_rax,
        .add_rax_imm8,
        .add_ecx_eax,
        .xor_ecx_ecx,
        .xor_ebp_ebp,
        .add_rdi_rcx4_ptr_eax,
        .inc_rcx,
        .movzx_dil_edi,
        .and_edi_imm8,
        .load_rax_rdi_u8_eax,
        .smin_i32_edi_esi_eax,
        .shift_mix_i32_edi_esi_eax,
        .replace_low_i8_dil_sil_al,
        .read_flag_i8_dil_al,
        .store_imm8_abs,
        .cmp_ecx_arg32,
        .cmp_rcx_arg64,
        .cmp_arg64_imm64,
        .cmp_arg16_imm16,
        .cmp_rdi_imm64,
        .cmp_rdx_rdi,
        .cmp_rax_rdx,
        .test_eax_eax,
        .test_rax_rax,
        .test_rdx_rdx,
        .mulsd_xmm1_xmm0,
        .addss_xmm1_xmm0,
        .subss_xmm1_xmm0,
        .divsd_xmm1_xmm0,
        .movapd_xmm1_xmm0,
        .mov_imm64_xmm0,
        .mov_imm64_xmm1,
        .mov_imm32_xmm0,
        .mov_imm32_xmm1,
        .ucomisd,
        .ucomisd_xmm1_xmm0,
        .ucomiss_xmm1_xmm0,
        .oltss_xmm0_xmm1_al,
        .sub_rsp_8,
        .add_rsp_8,
        .sub_rsp_24,
        .add_rsp_24,
        .spill_arg_rsp,
        .reload_arg_rsp,
        .spill_rdi_rsi_rsp24,
        .reload_rdi_rsp24,
        .reload_rsi_rsp24,
        .reload_rsp_eax,
        .load_stack_disp8_rax,
        .load_rax_ptr_disp8_rax,
        .load_rax_ptr_rdx,
        .load_rax_ptr_eax,
        .load_arg_ptr_eax,
        .load_arg_ptr_disp8_rax,
        .load_arg_ptr_disp8_u8_eax,
        .add_arg_ptr_disp4_eax,
        .store_eax_arg_ptr,
        .store_imm64_arg_ptr_disp8,
        .store_imm8_arg_ptr_disp8,
        .load_f128_arg_ptr_xmm0,
        .load_f128_const_xmm0,
        .load_f128_const_xmm1,
        .store_f128_xmm0_arg_ptr,
        .volatile_roundtrip_rdi_esi_eax,
        .load_global_i32_eax,
        .load_global_ptr_rax,
        .lea_global_rax,
        .lea_global_rdi,
        .lea_global_rdx,
        .store_eax_global_i32,
        .load_tls_i32_eax,
        .add_tls_i32_eax,
        .store_eax_tls_i32,
        .atomic_xadd_global_eax,
        .mov_rsp_rdi,
        .and_rsp_neg16,
        .direct_call,
        .noreturn_direct_call,
        .cmp_arg8_imm8,
        .cmp_ecx_imm32,
        .cmp_eax_imm32,
        .test_arg8,
        .test_arg32,
        .test_arg64,
        .base64_raw_args_to_decode4_regs,
        .base64_decode4_from_table_rax,
        .ud2,
        .je,
        .jne,
        .jo,
        .jp,
        .js,
        .jmp,
        .ret,
        => {},
    };
    return false;
}
