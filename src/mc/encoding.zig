const std = @import("std");
const x86_64 = @import("../codegen/x86_64.zig");

pub fn encodeFunction(allocator: std.mem.Allocator, function: x86_64.MachineFunction) ![]u8 {
    try x86_64.verifyFunction(function);

    var offsets = std.StringHashMap(u32).init(allocator);
    defer offsets.deinit();

    var offset: u32 = 0;
    for (function.instructions.items) |instruction| {
        switch (instruction) {
            .label => |label| try offsets.put(label, offset),
            else => offset += instructionSize(instruction),
        }
    }

    var bytes: std.ArrayList(u8) = .empty;
    errdefer bytes.deinit(allocator);

    offset = 0;
    for (function.instructions.items) |instruction| {
        switch (instruction) {
            .label => {},
            .mov_imm_eax => |value| {
                try bytes.append(allocator, 0xb8);
                try appendI32(&bytes, allocator, value);
            },
            .mov_arg_eax => |reg| try encodeRegToEax(&bytes, allocator, 0x89, reg),
            .mov_arg_arg => |mov| try encodeRegToReg(&bytes, allocator, mov.dst, mov.src),
            .binary_arg_eax => |binary| try encodeRegToEax(&bytes, allocator, binaryOpcode(binary.op), binary.reg),
            .add_eax_imm32 => |value| {
                try bytes.append(allocator, 0x05);
                try appendI32(&bytes, allocator, value);
            },
            .shl_eax_imm5 => |amount| {
                try bytes.appendSlice(allocator, &.{ 0xc1, 0xe0 });
                try bytes.append(allocator, amount);
            },
            .or_eax_imm32 => |value| {
                try bytes.append(allocator, 0x0d);
                try appendI32(&bytes, allocator, value);
            },
            .imul_eax_imm32 => |value| {
                try bytes.appendSlice(allocator, &.{ 0x69, 0xc0 });
                try appendI32(&bytes, allocator, value);
            },
            .shl_rdx_imm6 => |amount| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0xc1, 0xe2 });
                try bytes.append(allocator, amount);
            },
            .or_rdx_rax => try bytes.appendSlice(allocator, &.{ 0x48, 0x09, 0xd0 }),
            .add_ecx_eax => try bytes.appendSlice(allocator, &.{ 0x01, 0xc8 }),
            .xor_ecx_ecx => try bytes.appendSlice(allocator, &.{ 0x31, 0xc9 }),
            .add_rdi_rcx4_ptr_eax => try bytes.appendSlice(allocator, &.{ 0x03, 0x04, 0x8f }),
            .inc_rcx => try bytes.appendSlice(allocator, &.{ 0x48, 0xff, 0xc1 }),
            .smin_i32_edi_esi_eax => try bytes.appendSlice(allocator, &.{ 0x89, 0xf8, 0x39, 0xf7, 0x0f, 0x4f, 0xc6 }),
            .shift_mix_i32_edi_esi_eax => try bytes.appendSlice(allocator, &.{ 0x89, 0xf1, 0x83, 0xe1, 0x1f, 0x89, 0xf8, 0xd3, 0xe0, 0x89, 0xfa, 0xd3, 0xea, 0x31, 0xd0 }),
            .replace_low_i8_dil_sil_al => try bytes.appendSlice(allocator, &.{ 0x89, 0xf8, 0x83, 0xe0, 0xf8, 0x89, 0xf2, 0x83, 0xe2, 0x07, 0x09, 0xd0 }),
            .read_flag_i8_dil_al => try bytes.appendSlice(allocator, &.{ 0x31, 0xc0, 0x40, 0x84, 0xff, 0x0f, 0x98, 0xc0 }),
            .store_imm8_abs => |store| {
                try bytes.appendSlice(allocator, &.{ 0xc6, 0x04, 0x25 });
                try appendU32(&bytes, allocator, store.address);
                try bytes.append(allocator, store.value);
            },
            .cmp_ecx_arg32 => |reg| try encodeCmpEcxToArg32(&bytes, allocator, reg),
            .cmp_rcx_arg64 => |reg| try encodeCmpRcxToArg64(&bytes, allocator, reg),
            .cmp_ecx_imm32 => |value| {
                try bytes.appendSlice(allocator, &.{ 0x81, 0xf9 });
                try appendI32(&bytes, allocator, value);
            },
            .test_eax_eax => try bytes.appendSlice(allocator, &.{ 0x85, 0xc0 }),
            .mulsd_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x59, 0xc1 }),
            .addss_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x58, 0xc1 }),
            .subss_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x5c, 0xc1 }),
            .divsd_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x5e, 0xc1 }),
            .movapd_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0x66, 0x0f, 0x28, 0xc1 }),
            .mov_imm64_xmm0 => |value| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0xb8 });
                try appendU64(&bytes, allocator, value);
                try bytes.appendSlice(allocator, &.{ 0x66, 0x48, 0x0f, 0x6e, 0xc0 });
            },
            .mov_imm32_xmm0 => |value| {
                try bytes.append(allocator, 0xb8);
                try appendU32(&bytes, allocator, value);
                try bytes.appendSlice(allocator, &.{ 0x66, 0x0f, 0x6e, 0xc0 });
            },
            .oltss_xmm0_xmm1_al => try bytes.appendSlice(allocator, &.{ 0x31, 0xc0, 0x0f, 0x2e, 0xc8, 0x0f, 0x97, 0xc0 }),
            .sub_rsp_8 => try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xec, 0x08 }),
            .add_rsp_8 => try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xc4, 0x08 }),
            .sub_rsp_24 => try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xec, 0x18 }),
            .add_rsp_24 => try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xc4, 0x18 }),
            .spill_arg_rsp => |spill| try encodeRegToFrameSlot(&bytes, allocator, 0x89, spill.reg, spill.frame_index),
            .reload_arg_rsp => |reload| try encodeFrameSlotToReg(&bytes, allocator, 0x8b, reload.reg, reload.frame_index),
            .spill_rdi_rsi_rsp24 => try bytes.appendSlice(allocator, &.{ 0x48, 0x89, 0x7c, 0x24, 0x08, 0x48, 0x89, 0x74, 0x24, 0x10 }),
            .reload_rdi_rsp24 => try bytes.appendSlice(allocator, &.{ 0x48, 0x8b, 0x7c, 0x24, 0x08 }),
            .reload_rsi_rsp24 => try bytes.appendSlice(allocator, &.{ 0x48, 0x8b, 0x74, 0x24, 0x10 }),
            .reload_rsp_eax => try bytes.appendSlice(allocator, &.{ 0x8b, 0x04, 0x24 }),
            .load_arg_ptr_eax => |reg| try encodeArgPtrToEax(&bytes, allocator, reg),
            .add_arg_ptr_disp4_eax => |reg| try encodeArgPtrDisp4ToEax(&bytes, allocator, reg),
            .store_eax_arg_ptr => |reg| try encodeEaxToArgPtr(&bytes, allocator, reg),
            .load_f128_arg_ptr_xmm0 => |load| try encodeF128ArgPtrToXmm0(&bytes, allocator, load.reg, load.offset),
            .load_f128_const_xmm0 => try bytes.appendSlice(allocator, &.{ 0x0f, 0x28, 0x05, 0, 0, 0, 0 }),
            .load_f128_const_xmm1 => try bytes.appendSlice(allocator, &.{ 0x0f, 0x28, 0x0d, 0, 0, 0, 0 }),
            .store_f128_xmm0_arg_ptr => |store| try encodeF128Xmm0ToArgPtr(&bytes, allocator, store.reg, store.offset),
            .volatile_roundtrip_rdi_esi_eax => try bytes.appendSlice(allocator, &.{ 0x89, 0x37, 0x8b, 0x07 }),
            .load_global_i32_eax => try bytes.appendSlice(allocator, &.{ 0x8b, 0x05, 0, 0, 0, 0 }),
            .store_eax_global_i32 => try bytes.appendSlice(allocator, &.{ 0x89, 0x05, 0, 0, 0, 0 }),
            .load_tls_i32_eax => try bytes.appendSlice(allocator, &.{ 0x64, 0x8b, 0x04, 0x25, 0, 0, 0, 0 }),
            .store_eax_tls_i32 => try bytes.appendSlice(allocator, &.{ 0x64, 0x89, 0x04, 0x25, 0, 0, 0, 0 }),
            .atomic_xadd_global_eax => try bytes.appendSlice(allocator, &.{ 0xf0, 0x0f, 0xc1, 0x05, 0, 0, 0, 0 }),
            .direct_call => {
                try bytes.append(allocator, 0xe8);
                try appendI32(&bytes, allocator, 0);
            },
            .cmp_arg8_imm8 => |cmp| try encodeCmp8Imm(&bytes, allocator, cmp.reg, cmp.imm),
            .test_arg8 => |reg| try encodeTest8(&bytes, allocator, reg),
            .test_arg32 => |reg| try encodeTest32(&bytes, allocator, reg),
            .test_arg64 => |reg| try encodeTest64(&bytes, allocator, reg),
            .ud2 => try bytes.appendSlice(allocator, &.{ 0x0f, 0x0b }),
            .je => |label| {
                const target = offsets.get(label) orelse return error.InvalidBranchTarget;
                const next = offset + instructionSize(instruction);
                const displacement: i64 = @as(i64, @intCast(target)) - @as(i64, @intCast(next));
                if (displacement < std.math.minInt(i32) or displacement > std.math.maxInt(i32)) return error.BranchOutOfRange;
                try bytes.appendSlice(allocator, &.{ 0x0f, 0x84 });
                try appendI32(&bytes, allocator, @intCast(displacement));
            },
            .jne => |label| {
                const target = offsets.get(label) orelse return error.InvalidBranchTarget;
                const next = offset + instructionSize(instruction);
                const displacement: i64 = @as(i64, @intCast(target)) - @as(i64, @intCast(next));
                if (displacement < std.math.minInt(i32) or displacement > std.math.maxInt(i32)) return error.BranchOutOfRange;
                try bytes.appendSlice(allocator, &.{ 0x0f, 0x85 });
                try appendI32(&bytes, allocator, @intCast(displacement));
            },
            .jo => |label| {
                const target = offsets.get(label) orelse return error.InvalidBranchTarget;
                const next = offset + instructionSize(instruction);
                const displacement: i64 = @as(i64, @intCast(target)) - @as(i64, @intCast(next));
                if (displacement < std.math.minInt(i32) or displacement > std.math.maxInt(i32)) return error.BranchOutOfRange;
                try bytes.appendSlice(allocator, &.{ 0x0f, 0x80 });
                try appendI32(&bytes, allocator, @intCast(displacement));
            },
            .js => |label| {
                const target = offsets.get(label) orelse return error.InvalidBranchTarget;
                const next = offset + instructionSize(instruction);
                const displacement: i64 = @as(i64, @intCast(target)) - @as(i64, @intCast(next));
                if (displacement < std.math.minInt(i32) or displacement > std.math.maxInt(i32)) return error.BranchOutOfRange;
                try bytes.appendSlice(allocator, &.{ 0x0f, 0x88 });
                try appendI32(&bytes, allocator, @intCast(displacement));
            },
            .ret => try bytes.append(allocator, 0xc3),
        }
        offset += instructionSize(instruction);
    }

    return try bytes.toOwnedSlice(allocator);
}

pub fn instructionSize(instruction: x86_64.Instruction) u32 {
    return switch (instruction) {
        .label => 0,
        .mov_imm_eax => 5,
        .mov_arg_eax => |reg| if (reg.rexR()) 3 else 2,
        .mov_arg_arg => |mov| if (mov.src.rexR() or mov.dst.rexR()) 3 else 2,
        .binary_arg_eax => |binary| if (binary.reg.rexR()) 3 else 2,
        .add_eax_imm32 => 5,
        .shl_eax_imm5 => 3,
        .or_eax_imm32 => 5,
        .imul_eax_imm32 => 6,
        .shl_rdx_imm6 => 4,
        .or_rdx_rax => 3,
        .add_ecx_eax => 2,
        .xor_ecx_ecx => 2,
        .add_rdi_rcx4_ptr_eax => 3,
        .inc_rcx => 3,
        .smin_i32_edi_esi_eax => 7,
        .shift_mix_i32_edi_esi_eax => 15,
        .replace_low_i8_dil_sil_al => 12,
        .read_flag_i8_dil_al => 8,
        .store_imm8_abs => 8,
        .cmp_ecx_arg32 => |reg| if (reg.rexB()) 3 else 2,
        .cmp_rcx_arg64 => |reg| if (reg.rexB()) 4 else 3,
        .cmp_ecx_imm32 => 6,
        .test_eax_eax => 2,
        .mulsd_xmm1_xmm0 => 4,
        .addss_xmm1_xmm0 => 4,
        .subss_xmm1_xmm0 => 4,
        .divsd_xmm1_xmm0 => 4,
        .movapd_xmm1_xmm0 => 4,
        .mov_imm64_xmm0 => 15,
        .mov_imm32_xmm0 => 9,
        .oltss_xmm0_xmm1_al => 8,
        .sub_rsp_8, .add_rsp_8 => 4,
        .sub_rsp_24, .add_rsp_24 => 4,
        .spill_arg_rsp => |spill| if (spill.reg.rexR()) 4 else 3,
        .reload_arg_rsp => |reload| if (reload.reg.rexR()) 4 else 3,
        .spill_rdi_rsi_rsp24 => 10,
        .reload_rdi_rsp24, .reload_rsi_rsp24 => 5,
        .reload_rsp_eax => 3,
        .load_arg_ptr_eax => |reg| if (reg.rexB()) 3 else 2,
        .add_arg_ptr_disp4_eax => |reg| if (reg.rexB()) 4 else 3,
        .store_eax_arg_ptr => |reg| if (reg.rexB()) 3 else 2,
        .load_f128_arg_ptr_xmm0 => |load| f128ArgPtrInstructionSize(load.reg, load.offset),
        .load_f128_const_xmm0, .load_f128_const_xmm1 => 7,
        .store_f128_xmm0_arg_ptr => |store| f128ArgPtrInstructionSize(store.reg, store.offset),
        .volatile_roundtrip_rdi_esi_eax => 4,
        .load_global_i32_eax, .store_eax_global_i32 => 6,
        .load_tls_i32_eax, .store_eax_tls_i32 => 8,
        .atomic_xadd_global_eax => 8,
        .direct_call => 5,
        .cmp_arg8_imm8 => |cmp| if (cmp.reg.needsRex8()) 4 else 3,
        .test_arg8 => |reg| if (reg.needsRex8()) 3 else 2,
        .test_arg32 => |reg| if (reg.rexR()) 3 else 2,
        .test_arg64 => 3,
        .ud2 => 2,
        .je, .jne, .jo, .js => 6,
        .ret => 1,
    };
}

fn binaryOpcode(op: x86_64.MachineBinaryOp) u8 {
    return switch (op) {
        .add => 0x01,
        .sub => 0x29,
        .@"and" => 0x21,
        .@"or" => 0x09,
        .xor => 0x31,
    };
}

fn encodeRegToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, opcode: u8, reg: x86_64.ArgReg) !void {
    if (reg.rexR()) try bytes.append(allocator, 0x44);
    try bytes.append(allocator, opcode);
    try bytes.append(allocator, 0xc0 | (@as(u8, reg.lowCode()) << 3));
}

fn encodeRegToReg(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, dst: x86_64.ArgReg, src: x86_64.ArgReg) !void {
    if (src.rexR() or dst.rexR()) {
        var rex: u8 = 0x40;
        if (src.rexR()) rex |= 0x04;
        if (dst.rexR()) rex |= 0x01;
        try bytes.append(allocator, rex);
    }
    try bytes.append(allocator, 0x89);
    try bytes.append(allocator, 0xc0 | (@as(u8, src.lowCode()) << 3) | @as(u8, dst.lowCode()));
}

fn encodeRegToFrameSlot(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, opcode: u8, reg: x86_64.ArgReg, frame_index: x86_64.FrameIndex) !void {
    if (frame_index != .slot0) return error.UnsupportedFrameIndex;
    if (reg.rexR()) try bytes.append(allocator, 0x44);
    try bytes.append(allocator, opcode);
    try bytes.append(allocator, 0x04 | (@as(u8, reg.lowCode()) << 3));
    try bytes.append(allocator, 0x24);
}

fn encodeFrameSlotToReg(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, opcode: u8, reg: x86_64.ArgReg, frame_index: x86_64.FrameIndex) !void {
    if (frame_index != .slot0) return error.UnsupportedFrameIndex;
    if (reg.rexR()) try bytes.append(allocator, 0x44);
    try bytes.append(allocator, opcode);
    try bytes.append(allocator, 0x04 | (@as(u8, reg.lowCode()) << 3));
    try bytes.append(allocator, 0x24);
}

fn encodeArgPtrToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x8b);
    try bytes.append(allocator, @as(u8, reg.lowCode()));
}

fn encodeEaxToArgPtr(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x89);
    try bytes.append(allocator, @as(u8, reg.lowCode()));
}

fn encodeArgPtrDisp4ToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x03);
    try bytes.append(allocator, 0x40 | @as(u8, reg.lowCode()));
    try bytes.append(allocator, 0x04);
}

fn encodeF128ArgPtrToXmm0(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.appendSlice(allocator, &.{ 0x0f, 0x28 });
    if (offset == 0) {
        try bytes.append(allocator, @as(u8, reg.lowCode()));
    } else {
        try bytes.append(allocator, 0x40 | @as(u8, reg.lowCode()));
        try bytes.append(allocator, offset);
    }
}

fn encodeF128Xmm0ToArgPtr(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.appendSlice(allocator, &.{ 0x0f, 0x29 });
    if (offset == 0) {
        try bytes.append(allocator, @as(u8, reg.lowCode()));
    } else {
        try bytes.append(allocator, 0x40 | @as(u8, reg.lowCode()));
        try bytes.append(allocator, offset);
    }
}

fn f128ArgPtrInstructionSize(reg: x86_64.ArgReg, offset: u8) u32 {
    return (if (reg.rexB()) @as(u32, 1) else 0) + 3 + if (offset == 0) @as(u32, 0) else 1;
}

fn encodeCmp8Imm(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, imm: u8) !void {
    if (reg.needsRex8()) {
        var rex: u8 = 0x40;
        if (reg.rexB()) rex |= 0x01;
        try bytes.append(allocator, rex);
    }
    try bytes.append(allocator, 0x80);
    try bytes.append(allocator, 0xf8 | @as(u8, reg.lowCode()));
    try bytes.append(allocator, imm);
}

fn encodeCmpRcxToArg64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    var rex: u8 = 0x48;
    if (reg.rexB()) rex |= 0x01;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0x39);
    try bytes.append(allocator, 0xc0 | (@as(u8, x86_64.ArgReg.rcx.lowCode()) << 3) | @as(u8, reg.lowCode()));
}

fn encodeCmpEcxToArg32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x39);
    try bytes.append(allocator, 0xc0 | (@as(u8, x86_64.ArgReg.rcx.lowCode()) << 3) | @as(u8, reg.lowCode()));
}

fn encodeTest8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    if (reg.needsRex8()) {
        var rex: u8 = 0x40;
        if (reg.rexR()) rex |= 0x05;
        try bytes.append(allocator, rex);
    }
    const code: u8 = @intCast(reg.lowCode());
    try bytes.append(allocator, 0x84);
    try bytes.append(allocator, 0xc0 | (code << 3) | code);
}

fn encodeTest32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    if (reg.rexR()) {
        var rex: u8 = 0x40;
        rex |= 0x05;
        try bytes.append(allocator, rex);
    }
    const code: u8 = @intCast(reg.lowCode());
    try bytes.append(allocator, 0x85);
    try bytes.append(allocator, 0xc0 | (code << 3) | code);
}

fn encodeTest64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    var rex: u8 = 0x48;
    if (reg.rexR()) rex |= 0x04;
    if (reg.rexB()) rex |= 0x01;
    const code: u8 = @intCast(reg.lowCode());
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0x85);
    try bytes.append(allocator, 0xc0 | (code << 3) | code);
}

fn appendI32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, value: i32) !void {
    const raw: u32 = @bitCast(value);
    try appendU32(bytes, allocator, raw);
}

fn appendU32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, value: u32) !void {
    try bytes.append(allocator, @intCast(value & 0xff));
    try bytes.append(allocator, @intCast((value >> 8) & 0xff));
    try bytes.append(allocator, @intCast((value >> 16) & 0xff));
    try bytes.append(allocator, @intCast((value >> 24) & 0xff));
}

fn appendU64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, value: u64) !void {
    try appendU32(bytes, allocator, @intCast(value & 0xffff_ffff));
    try appendU32(bytes, allocator, @intCast(value >> 32));
}
