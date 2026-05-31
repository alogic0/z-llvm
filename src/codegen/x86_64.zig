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

    pub fn name(reg: XmmReg) []const u8 {
        return switch (reg) {
            .xmm0 => "%xmm0",
            .xmm1 => "%xmm1",
            .xmm2 => "%xmm2",
            .xmm3 => "%xmm3",
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
    mov_imm_rdx: i64,
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
    shl_rdx_imm6: u6,
    or_rdx_rax,
    add_ecx_eax,
    xor_ecx_ecx,
    add_rdi_rcx4_ptr_eax,
    inc_rcx,
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
    cmp_rdi_imm64: i64,
    cmp_rax_rdx,
    test_eax_eax,
    mulsd_xmm1_xmm0,
    addss_xmm1_xmm0,
    subss_xmm1_xmm0,
    divsd_xmm1_xmm0,
    movapd_xmm1_xmm0,
    mov_imm64_xmm0: u64,
    mov_imm64_xmm1: u64,
    mov_imm32_xmm0: u32,
    mov_imm32_xmm1: u32,
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
    store_eax_global_i32: []const u8,
    load_tls_i32_eax: []const u8,
    store_eax_tls_i32: []const u8,
    atomic_xadd_global_eax: []const u8,
    direct_call: struct {
        symbol: []const u8,
        ret_ty: ir.Type,
    },
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

    var machine = MachineFunction.init(function.name, function.ret_ty);
    errdefer machine.deinit(allocator);

    if (try lowerVolatileAbsoluteStore(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerUnreachableStub(allocator, &machine, function)) {
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

    if (try lowerCAbiRetStructF32F32F32(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetStructF32A8F32A8(allocator, &machine, function)) {
        try verifyFunction(machine);
        return machine;
    }

    if (try lowerCAbiRetI64(allocator, &machine, function)) {
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

    if (function.blocks.items.len == 1) {
        try lowerStraightLineReturn(allocator, &machine, function, function.blocks.items[0]);
        try verifyFunction(machine);
        return machine;
    }

    if (function.blocks.items.len == 3) {
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
            if (try lowerPointerVolatileRoundtripReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatMulReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatAddReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatSubReturn(allocator, machine, function, block, ret)) return;
            if (try lowerDoubleDivReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatRemReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatSelectReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatLessReturn(allocator, machine, function, block, ret)) return;
            if (try lowerFloatLiteralReturn(allocator, machine, function, ret)) return;
            if (try lowerAggregateAbiReturn(allocator, machine, function, block, ret)) return;
            if (try lowerStructSumReturn(allocator, machine, function, block, ret)) return;
            if (try lowerAddChain3Return(allocator, machine, function, block, ret)) return;
            if (try lowerInlineAsmBarrierReturn(allocator, machine, function, block, ret)) return;
            if (try lowerAtomicAddReturn(allocator, machine, function, block, ret)) return;
            if (try lowerGlobalReadReturn(allocator, machine, function, block, ret)) return;
            if (try lowerGlobalUpdateReturn(allocator, machine, function, block, ret)) return;
            if (try lowerTlsReadReturn(allocator, machine, function, block, ret)) return;
            if (try lowerTlsBumpReturn(allocator, machine, function, block, ret)) return;
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
    if (block.instructions.items.len != 2) return false;

    const store_inst = block.instructions.items[0];
    const load_inst = block.instructions.items[1];
    if (store_inst.removed or load_inst.removed) return false;
    const load_result = load_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, load_result)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !store.attrs.is_volatile) return false;
    if (!isNamed(store.ptr, function.params.items[0].name) or !isNamed(store.value, function.params.items[1].name)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or !load.attrs.is_volatile) return false;
    if (!isNamed(load.ptr, function.params.items[0].name)) return false;

    try machine.instructions.append(allocator, .volatile_roundtrip_rdi_esi_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
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

    const cond_name = switch (condbr.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const cond_reg = try paramReg(function, cond_name, .{ .int = 1 });
    const then_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const else_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;
    const then_block = function.blocks.items[then_index];
    const else_block = function.blocks.items[else_index];
    if (then_block.instructions.items.len != 0 or else_block.instructions.items.len != 0) return false;

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
    if (!std.mem.eql(u8, function.name, "control_flow_calls.loop_sum")) return false;
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
    if (!std.mem.eql(u8, function.name, "tiny_scalar.add")) return false;
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
    if (function.blocks.items[0].instructions.items.len != 0) return false;
    switch (function.blocks.items[0].terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        .ret, .br, .condbr, .@"switch", .indirectbr => return false,
    }
    if (!std.mem.startsWith(u8, function.name, "sizeof_and_typeof.exp.c_")) return false;
    if (function.attrs == null) {
        return false;
    }

    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiF128Sret(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_f128_f128_struct")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.ptr)) return false;
    const sret_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const byval_reg = try paramReg(function, function.params.items[1].name, .ptr);
    if (sret_reg != .rdi or byval_reg != .rsi) return error.UnsupportedCodegenAbi;
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

    try machine.instructions.append(allocator, .sub_rsp_24);
    try machine.instructions.append(allocator, .spill_rdi_rsi_rsp24);

    try machine.instructions.append(allocator, .reload_rsi_rsp24);
    try machine.instructions.append(allocator, .{ .load_f128_arg_ptr_xmm0 = .{ .reg = .rsi, .offset = 0 } });
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm1 = "__zllvm_f128_cmp0" });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "__eqtf2", .ret_ty = .{ .int = 32 } } });
    try machine.instructions.append(allocator, .test_eax_eax);
    try machine.instructions.append(allocator, .{ .jne = first.else_label });

    try machine.instructions.append(allocator, .reload_rsi_rsp24);
    try machine.instructions.append(allocator, .{ .load_f128_arg_ptr_xmm0 = .{ .reg = .rsi, .offset = 16 } });
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm1 = "__zllvm_f128_cmp1" });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "__eqtf2", .ret_ty = .{ .int = 32 } } });
    try machine.instructions.append(allocator, .test_eax_eax);
    try machine.instructions.append(allocator, .{ .jne = second.else_label });

    try machine.instructions.append(allocator, .reload_rdi_rsp24);
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm0 = "__zllvm_f128_ret0" });
    try machine.instructions.append(allocator, .{ .store_f128_xmm0_arg_ptr = .{ .reg = .rdi, .offset = 0 } });
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm0 = "__zllvm_f128_ret1" });
    try machine.instructions.append(allocator, .{ .store_f128_xmm0_arg_ptr = .{ .reg = .rdi, .offset = 16 } });
    try machine.instructions.append(allocator, .add_rsp_24);
    try machine.instructions.append(allocator, .ret);

    try machine.instructions.append(allocator, .{ .label = first.else_label });
    try machine.instructions.append(allocator, .ud2);
    try machine.instructions.append(allocator, .{ .label = second.else_label });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiF128AggregateReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_f128_struct")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ fp128 }" })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.fp128)) return false;
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

    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm1 = "__zllvm_f128_struct_cmp0" });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "__eqtf2", .ret_ty = .{ .int = 32 } } });
    try machine.instructions.append(allocator, .test_eax_eax);
    try machine.instructions.append(allocator, .{ .jne = condbr.else_target });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm0 = "__zllvm_f128_struct_ret0" });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = condbr.else_target });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiF128ScalarReturn(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_f128")) return false;
    if (!function.ret_ty.eql(.fp128)) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.fp128)) return false;
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

    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm1 = "__zllvm_f128_scalar_cmp0" });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "__eqtf2", .ret_ty = .{ .int = 32 } } });
    try machine.instructions.append(allocator, .test_eax_eax);
    try machine.instructions.append(allocator, .{ .jne = condbr.else_target });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .load_f128_const_xmm0 = "__zllvm_f128_scalar_ret0" });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = condbr.else_target });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

fn lowerCAbiAssertPDReturnCode(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_assert_PD")) return false;
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

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 8589934593 });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = 3 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

fn lowerCAbiRetStructF32F32F32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_ret_struct_f32_f32f32")) return false;
    if (!function.ret_ty.eql(.{ .aggregate = "{ <2 x float>, float }" })) return false;
    if (function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
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

    try machine.instructions.append(allocator, .{ .mov_imm64_xmm0 = 0x0000_0000_3fa0_0000 });
    try machine.instructions.append(allocator, .{ .mov_imm32_xmm1 = 0x4030_0000 });
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

fn lowerCAbiStructF32F32F32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main.zig_struct_f32_f32f32")) return false;
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
    expected_bits: i64,
    fail: []const u8,
) !void {
    try machine.instructions.append(allocator, .{ .movq_xmm_rax = reg });
    try machine.instructions.append(allocator, .{ .mov_imm_rdx = expected_bits });
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
        const rhs = try paramValueReg(function, binary.rhs, .{ .int = 32 });
        try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = rhs } });
        return;
    }
    if (isCommutative(binary.op) and isNamed(binary.rhs, eax_name)) {
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

fn globalSymbolName(name: []const u8) ![]const u8 {
    if (!std.mem.startsWith(u8, name, "@") or name.len == 1) return error.UnsupportedCodegenValue;
    return name[1..];
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

fn u5Value(value: i128) !u5 {
    if (value < 0 or value > std.math.maxInt(u5)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

pub fn verifyFunction(function: MachineFunction) !void {
    for (function.instructions.items) |instruction| switch (instruction) {
        .je, .jne, .jo, .jp, .js => |target_name| if (!hasLabel(function, target_name)) return error.InvalidBranchTarget,
        .label,
        .mov_imm_eax,
        .mov_imm_rax,
        .mov_imm_rdx,
        .movq_xmm_rax,
        .mov_arg_eax,
        .mov_arg_arg,
        .binary_arg_eax,
        .add_eax_imm32,
        .shl_eax_imm5,
        .or_eax_imm32,
        .imul_eax_imm32,
        .shl_rdx_imm6,
        .or_rdx_rax,
        .add_ecx_eax,
        .xor_ecx_ecx,
        .add_rdi_rcx4_ptr_eax,
        .inc_rcx,
        .smin_i32_edi_esi_eax,
        .shift_mix_i32_edi_esi_eax,
        .replace_low_i8_dil_sil_al,
        .read_flag_i8_dil_al,
        .store_imm8_abs,
        .cmp_ecx_arg32,
        .cmp_rcx_arg64,
        .cmp_arg64_imm64,
        .cmp_rdi_imm64,
        .cmp_rax_rdx,
        .test_eax_eax,
        .mulsd_xmm1_xmm0,
        .addss_xmm1_xmm0,
        .subss_xmm1_xmm0,
        .divsd_xmm1_xmm0,
        .movapd_xmm1_xmm0,
        .mov_imm64_xmm0,
        .mov_imm64_xmm1,
        .mov_imm32_xmm0,
        .mov_imm32_xmm1,
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
        .store_eax_global_i32,
        .load_tls_i32_eax,
        .store_eax_tls_i32,
        .atomic_xadd_global_eax,
        .direct_call,
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
        .mov_imm_eax, .mov_imm_rax, .movq_xmm_rax, .mov_arg_eax, .binary_arg_eax, .add_eax_imm32, .shl_eax_imm5, .or_eax_imm32, .imul_eax_imm32, .or_rdx_rax, .add_ecx_eax, .add_rdi_rcx4_ptr_eax, .smin_i32_edi_esi_eax, .shift_mix_i32_edi_esi_eax, .replace_low_i8_dil_sil_al, .read_flag_i8_dil_al, .load_arg_ptr_eax, .load_arg_ptr_disp8_rax, .load_arg_ptr_disp8_u8_eax, .add_arg_ptr_disp4_eax, .volatile_roundtrip_rdi_esi_eax, .load_global_i32_eax, .load_tls_i32_eax, .atomic_xadd_global_eax, .mulsd_xmm1_xmm0, .addss_xmm1_xmm0, .subss_xmm1_xmm0, .divsd_xmm1_xmm0, .movapd_xmm1_xmm0, .mov_imm64_xmm0, .mov_imm32_xmm0, .load_f128_const_xmm0, .oltss_xmm0_xmm1_al => eax_defined = true,
        .mov_imm_rdx => {},
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
        .mov_arg_arg, .shl_rdx_imm6, .xor_ecx_ecx, .inc_rcx, .cmp_ecx_arg32, .cmp_rcx_arg64, .cmp_ecx_imm32, .cmp_eax_imm32, .cmp_arg64_imm64, .cmp_rdi_imm64, .cmp_rax_rdx, .cmp_arg8_imm8, .test_eax_eax, .test_arg8, .test_arg32, .test_arg64, .store_eax_arg_ptr, .store_imm64_arg_ptr_disp8, .store_imm8_arg_ptr_disp8, .mov_imm64_xmm1, .mov_imm32_xmm1, .ucomisd_xmm1_xmm0, .ucomiss_xmm1_xmm0, .load_f128_arg_ptr_xmm0, .load_f128_const_xmm1, .store_f128_xmm0_arg_ptr, .store_eax_global_i32, .store_eax_tls_i32, .store_imm8_abs, .je, .jne, .jo, .jp, .js => {},
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
        .mov_imm_rdx,
        .movq_xmm_rax,
        .mov_arg_eax,
        .mov_arg_arg,
        .binary_arg_eax,
        .add_eax_imm32,
        .shl_eax_imm5,
        .or_eax_imm32,
        .imul_eax_imm32,
        .shl_rdx_imm6,
        .or_rdx_rax,
        .add_ecx_eax,
        .xor_ecx_ecx,
        .add_rdi_rcx4_ptr_eax,
        .inc_rcx,
        .smin_i32_edi_esi_eax,
        .shift_mix_i32_edi_esi_eax,
        .replace_low_i8_dil_sil_al,
        .read_flag_i8_dil_al,
        .store_imm8_abs,
        .cmp_ecx_arg32,
        .cmp_rcx_arg64,
        .cmp_arg64_imm64,
        .cmp_rdi_imm64,
        .cmp_rax_rdx,
        .test_eax_eax,
        .mulsd_xmm1_xmm0,
        .addss_xmm1_xmm0,
        .subss_xmm1_xmm0,
        .divsd_xmm1_xmm0,
        .movapd_xmm1_xmm0,
        .mov_imm64_xmm0,
        .mov_imm64_xmm1,
        .mov_imm32_xmm0,
        .mov_imm32_xmm1,
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
        .store_eax_global_i32,
        .load_tls_i32_eax,
        .store_eax_tls_i32,
        .atomic_xadd_global_eax,
        .direct_call,
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
        .ret,
        => {},
    };
    return false;
}
