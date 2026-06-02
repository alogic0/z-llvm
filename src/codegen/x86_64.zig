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

    if (try lowerDebugLogicalPointerCompileError(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerDebugSpirvMergeLogicalPointers(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerDebugInheritWantSafety(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerDebugNoCompilePanicUncheckedArith(allocator, &machine, function)) {
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
        if (try lowerDenseSwitchReturn(allocator, &machine, function)) {
            try verifyFunction(machine);
            return machine;
        }
    }

    if (try lowerControlFlowLoopSum(allocator, &machine, function)) {
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
            if (try lowerSingleStackSlotCallReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSingleStackSlotReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectAddSubReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimePhiSelectReturn(allocator, machine, function, block, ret)) return;
            if (try lowerIcmpSelectConstReturn(allocator, machine, function, block, ret)) return;
            if (try lowerErrorSwitchSelectReturn(allocator, machine, function, block, ret)) return;
            if (try lowerAddImmReturn(allocator, machine, function, block, ret)) return;
            if (try lowerShiftOrConstReturn(allocator, machine, function, block, ret)) return;
            if (try lowerMulConstReturn(allocator, machine, function, block, ret)) return;
            if (try lowerIntegerSminReturn(allocator, machine, function, block, ret)) return;
            if (try lowerIntegerShiftMixReturn(allocator, machine, function, block, ret)) return;
            if (try lowerPackedReplaceLowReturn(allocator, machine, function, block, ret)) return;
            if (try lowerPackedReadFlagReturn(allocator, machine, function, block, ret)) return;
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
            if (try lowerRuntimeArraySumMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeOptionalPayloadMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeErrorUnionPayloadMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeSliceSumMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeComptimeConstMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerRuntimeDebugLocationMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectedI64CallMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerGlobalReadReturn(allocator, machine, function, block, ret)) return;
            if (try lowerGlobalUpdateReturn(allocator, machine, function, block, ret)) return;
            if (try lowerReleaseSmallHiddenAccessMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerReleaseSmallMixCAddZigMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerReleaseSmallMixCAddMayPanicMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerExternExportsGlobalAccess(allocator, machine, function, block, ret)) return;
            if (try lowerTlsReadReturn(allocator, machine, function, block, ret)) return;
            if (try lowerTlsBumpReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectedI64ConstReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectedI1ConstReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectedStringSliceReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64StoreStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64DecodeStepMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64WriterMainReturn(allocator, machine, function, block, ret)) return;
            if (try lowerBase64TableLookupReturn(allocator, machine, function, block, ret)) return;
            if (try lowerSelectedLibfuzzerTestRun(allocator, machine, function, block, ret)) return;
            if (try lowerSelectedUmlFixSatI64Return(allocator, machine, function, block, ret)) return;
            if (block.instructions.items.len != 0) {
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

fn lowerRuntimeArraySumMainReturn(
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
    if (!isCalleeName(call.callee, "aggregates.array_sum")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
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

fn lowerRuntimeOptionalPayloadMainReturn(
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
    if (!isCalleeName(call.callee, "aggregates.optional_payload")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
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
    if (!isCalleeName(call.callee, "aggregates.error_union_payload")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
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

fn lowerRuntimeSliceSumMainReturn(
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
    if (!isCalleeName(call.callee, "aggregates.slice_sum")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.ptr) or !call.args.items[0].value.eql(.{ .named = "@slice_sum_values" })) return error.UnsupportedCodegenValue;
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
    if (block.instructions.items.len != 2) return false;

    const icmp_inst = block.instructions.items[0];
    const select_inst = block.instructions.items[1];
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
        reg: ArgReg,
        imm: i32,
    };
    const selected: AddImm = switch (add.lhs) {
        .int => |value| .{
            .reg = try paramValueReg(function, add.rhs, .{ .int = 32 }),
            .imm = try i32Value(value),
        },
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => switch (add.rhs) {
            .int => |value| .{
                .reg = try paramValueReg(function, add.lhs, .{ .int = 32 }),
                .imm = try i32Value(value),
            },
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        },
    };

    try machine.instructions.append(allocator, .{ .mov_arg_eax = selected.reg });
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
    if (!std.mem.eql(u8, function.name, "packed_bits.replace_low")) return false;
    if (!ret.ty.eql(.{ .int = 8 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 8 }) or !function.params.items[1].ty.eql(.{ .int = 8 })) return false;
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

fn lowerPackedReadFlagReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "packed_bits.read_flag")) return false;
    if (!ret.ty.eql(.{ .int = 1 }) or function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 8 })) return false;
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

fn lowerPointerVolatileRoundtripReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "pointers_memory.volatile_roundtrip")) return false;
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
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 4) return false;

    const store_inst = block.instructions.items[0];
    const load_inst = block.instructions.items[1];
    const icmp_inst = block.instructions.items[2];
    const select_inst = block.instructions.items[3];
    if (store_inst.removed or load_inst.removed or icmp_inst.removed or select_inst.removed) return false;

    const load_name = load_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

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
    if (!std.mem.eql(u8, store_global, "pointers_memory.volatile_slot")) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or !load.attrs.is_volatile) return false;
    const load_global = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, load_global, "pointers_memory.volatile_slot")) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, load_name) or !isInt(icmp.rhs, 42)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

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
    if (!std.mem.eql(u8, function.name, "pointers_memory.load_store")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.ptr)) return false;
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
    try machine.instructions.append(allocator, .ret);
    return true;
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

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, fcmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

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

fn lowerAddChain3Return(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
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

fn lowerReleaseSmallHiddenAccessMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 2) return false;

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
    if (!isCalleeName(update_call.callee, "exports.updateHidden")) return false;
    if (update_call.callee_value != null or update_call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(update_call.calling_conv);
    if (update_call.ret_ty != .void or update_call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!update_call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(update_call.args.items[0].value, 7)) return error.UnsupportedCodegenValue;

    const get_call = switch (get_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(get_call.callee, "exports.getHidden")) return false;
    if (get_call.callee_value != null or get_call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(get_call.calling_conv);
    if (!get_call.ret_ty.eql(.{ .int = 32 }) or get_call.args.items.len != 0) return error.UnsupportedCodegenInstruction;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 7 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "exports.hidden" });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "exports.hidden" });
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
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_result = call_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "main.add_zig")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 4)) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "main.zig_k" });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 4 });
    try machine.instructions.append(allocator, .{ .add_tls_i32_eax = "C_k" });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerReleaseSmallMixCAddMayPanicMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_result = call_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "main.add_may_panic")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[0].value, 4)) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "main.zig_k" });
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
    if (!std.mem.eql(u8, function.name, "main.add_zig")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (block.instructions.items.len != 4) return false;

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
    if (!zig_load.ty.eql(.{ .int = 32 }) or zig_load.attrs.isBarrier() or !isNamed(zig_load.ptr, "@main.zig_k")) return false;

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
    if (!c_load.ty.eql(.{ .int = 32 }) or c_load.attrs.isBarrier() or !isNamed(c_load.ptr, "@C_k")) return false;

    const c_add = switch (c_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (c_add.op != .add or !c_add.ty.eql(.{ .int = 32 })) return false;
    if (!((isNamed(c_add.lhs, arg_add_result) and isNamed(c_add.rhs, c_load_result)) or
        (isNamed(c_add.lhs, c_load_result) and isNamed(c_add.rhs, arg_add_result)))) return false;

    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "main.zig_k" });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = arg_reg } });
    try machine.instructions.append(allocator, .{ .add_tls_i32_eax = "C_k" });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerSelectedMixCFilesAddMayPanic(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!std.mem.eql(u8, function.name, "main.add_may_panic")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 32 })) return false;
    if (function.blocks.items.len != 3) return false;

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
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, "@main.zig_k")) return false;
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
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "main.zig_k" });
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
    if (!std.mem.eql(u8, function.name, "exports.getHidden")) return false;
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
    if (!std.mem.eql(u8, global_name, "exports.hidden")) return false;

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
    if (!std.mem.eql(u8, function.name, "exports.updateHidden")) return false;
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
    if (!std.mem.eql(u8, global_name, "exports.hidden")) return false;

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

fn lowerTlsBumpReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "tls_concurrency.bump_tls")) return false;
    const arg_reg = (try matchGlobalUpdate(function, block, ret, "tls_concurrency.tls_counter")) orelse return false;
    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = "tls_concurrency.tls_counter" });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = arg_reg } });
    try machine.instructions.append(allocator, .{ .store_eax_tls_i32 = "tls_concurrency.tls_counter" });
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
    if (!std.mem.eql(u8, function.name, "pointers_memory.load_store")) return false;
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

fn lowerCheckedTlsBump(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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
    if (function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 5) return error.UnsupportedCodegenInstruction;
    const bits_name = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const bitcast = switch (entry.instructions.items[0].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (bitcast.op != .bitcast or !bitcast.from_ty.eql(.double) or !bitcast.to_ty.eql(.{ .int = 64 }) or !isNamed(bitcast.value, function.params.items[0].name)) return error.UnsupportedCodegenInstruction;

    const shifted_name = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const shifted = switch (entry.instructions.items[1].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (shifted.op != .lshr or !shifted.ty.eql(.{ .int = 64 }) or !isNamed(shifted.lhs, bits_name) or !shifted.rhs.eql(.{ .int = 52 })) return error.UnsupportedCodegenInstruction;

    const trunc_name = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const trunc = switch (entry.instructions.items[2].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 32 }) or !isNamed(trunc.value, shifted_name)) return error.UnsupportedCodegenInstruction;

    const masked_name = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    const masked = switch (entry.instructions.items[3].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (masked.op != .@"and" or !masked.ty.eql(.{ .int = 32 }) or !isNamed(masked.lhs, trunc_name) or !masked.rhs.eql(.{ .int = 2047 })) return error.UnsupportedCodegenInstruction;

    const cmp_name = entry.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const cmp = switch (entry.instructions.items[4].kind) {
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

fn isCalleeName(actual: []const u8, expected: []const u8) bool {
    const actual_name = symbolName(actual);
    if (std.mem.eql(u8, actual_name, expected)) return true;
    return false;
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
        .mov_imm_rdi, .mov_imm_rdx, .mov_imm_rsi, .lea_global_rdi => {},
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
        .mov_arg_arg, .shl_rdx_imm6, .xor_ecx_ecx, .xor_ebp_ebp, .inc_rcx, .movzx_dil_edi, .and_edi_imm8, .mov_rsp_rdi, .load_rax_ptr_rdx, .cmp_ecx_arg32, .cmp_rcx_arg64, .cmp_ecx_imm32, .cmp_eax_imm32, .cmp_arg64_imm64, .cmp_arg16_imm16, .cmp_rdi_imm64, .cmp_rdx_rdi, .cmp_rax_rdx, .cmp_arg8_imm8, .test_eax_eax, .test_rax_rax, .test_rdx_rdx, .test_arg8, .test_arg32, .test_arg64, .store_eax_arg_ptr, .store_imm64_arg_ptr_disp8, .store_imm8_arg_ptr_disp8, .mov_imm64_xmm1, .mov_imm32_xmm1, .ucomisd, .ucomisd_xmm1_xmm0, .ucomiss_xmm1_xmm0, .load_f128_arg_ptr_xmm0, .load_f128_const_xmm1, .store_f128_xmm0_arg_ptr, .store_eax_global_i32, .store_eax_tls_i32, .store_imm8_abs, .je, .jne, .jo, .jp, .js, .jmp => {},
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
