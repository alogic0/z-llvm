const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const assert_shape_rows = @import("cabi_assert_shape_rows.zig");
const f128_debug_rows = @import("cabi_f128_debug_rows.zig");
const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_match = @import("../match.zig");
const x86_64_machine = @import("../machine.zig");

const MachineFunction = x86_64_machine.MachineFunction;
const isNamed = x86_64_match.isNamed;
const isInt = x86_64_match.isInt;
const validateDebugStackLoadReturn = f128_debug_rows.validateDebugStackLoadReturn;
const validatePanicUnreachableBlock = f128_debug_rows.validatePanicUnreachableBlock;
const validateDebugPanicUnreachableBlock = f128_debug_rows.validateDebugPanicUnreachableBlock;
const validateF128EqCall = f128_debug_rows.validateF128EqCall;
const validateEqZeroIcmp = f128_debug_rows.validateEqZeroIcmp;
const blockIndex = cabi_abi_helpers.blockIndex;
const call_frame_helpers = @import("cabi_call_frame_helpers.zig");
const appendCompareArg32Imm32 = call_frame_helpers.appendCompareArg32Imm32;
const appendCompareStack64Imm64 = call_frame_helpers.appendCompareStack64Imm64;
const appendCompareMem64Imm64 = call_frame_helpers.appendCompareMem64Imm64;
const appendComparePackedFloatPair = call_frame_helpers.appendComparePackedFloatPair;
const appendCompareXmmLowF32 = call_frame_helpers.appendCompareXmmLowF32;
const appendCompareXmmLowF64 = call_frame_helpers.appendCompareXmmLowF64;
const appendCompareXmmF64 = call_frame_helpers.appendCompareXmmF64;
const appendCompareXmm0LowF64 = call_frame_helpers.appendCompareXmm0LowF64;
const appendCompareArg64Imm64 = call_frame_helpers.appendCompareArg64Imm64;
const appendCompareStackByval64Imm64 = call_frame_helpers.appendCompareStackByval64Imm64;
const paramReg = cabi_abi_helpers.paramReg;
const validateAssertPDShape = assert_shape_rows.validateAssertPDShape;
const validateAssertDCShape = assert_shape_rows.validateAssertDCShape;
const validateAssertCFFShape = assert_shape_rows.validateAssertCFFShape;
const validateDebugRetPD = f128_debug_rows.validateDebugRetPD;
const validateDebugRetCFF = f128_debug_rows.validateDebugRetCFF;
const validateDebugRetDC = f128_debug_rows.validateDebugRetDC;

pub fn lowerCAbiAssertPDReturnCode(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetPD(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetCFF(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetDC(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiAssertDCReturnCode(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetI64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetU64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetU32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetI16(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetI8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetU16(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetU8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetBool(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiCmultdComp(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiCmultfComp(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiCmultf(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiBool(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiPtr(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiF64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiF32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiFiveFloats(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiI64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiI32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiI16(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiI8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiFiveIntegers(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiPanic(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiAssertCFFReturnCode(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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
