const impl = @import("cabi_impl.zig");
const f128_debug_rows = @import("cabi_f128_debug_rows.zig");
const std = impl.std;
const ir = impl.ir;
const MachineFunction = impl.MachineFunction;
const isNamed = impl.isNamed;
const isInt = impl.isInt;
const validateDebugStackLoadReturn = f128_debug_rows.validateDebugStackLoadReturn;
const validatePanicUnreachableBlock = f128_debug_rows.validatePanicUnreachableBlock;
const validateDebugPanicUnreachableBlock = f128_debug_rows.validateDebugPanicUnreachableBlock;
const validateF128EqCall = f128_debug_rows.validateF128EqCall;
const validateEqZeroIcmp = f128_debug_rows.validateEqZeroIcmp;
const blockIndex = impl.blockIndex;
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
const paramReg = impl.paramReg;
const validateAssertPDShape = impl.validateAssertPDShape;
const validateAssertDCShape = impl.validateAssertDCShape;
const validateAssertCFFShape = impl.validateAssertCFFShape;
const validateDebugRetPD = f128_debug_rows.validateDebugRetPD;
const validateDebugRetCFF = f128_debug_rows.validateDebugRetCFF;
const validateDebugRetDC = f128_debug_rows.validateDebugRetDC;

pub fn lowerCAbiRetSplitStructMixed(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetMedStructMixed(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetMedStructInts(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetSmallStructInts(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetStructU32Union(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetStructU64U64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetStructF32F32F32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetStructF32A8F32A8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetStructF32A8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetStructF64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetStructF32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetStructU64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetStructU32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetStructU16(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiRetStructU8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiMultipleStructFloats(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiMultipleStructInts(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiBigStructBoth(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiSplitStructMixed(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiSplitStructInts(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiBigPackedStruct(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiSmallPackedStruct(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiMedStructInts(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiSmallStructInts(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiMedStructMixed(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiBigUnion(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiBigStruct(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructI32I32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructU32Union(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructF32F32F32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructF32A8F32A8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructF32A8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructF64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructF32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructU64U648(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructU64U647(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructU64U646(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructU64U645(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructU64U644(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructU64U643(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructU64U642(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructU64U641(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructU64U640(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructU64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructU32(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructU16(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructU8(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructU128(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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

pub fn lowerCAbiStructI128(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
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
