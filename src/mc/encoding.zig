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
            .mov_imm_rax => |value| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0xb8 });
                try appendU64(&bytes, allocator, @bitCast(value));
            },
            .mov_imm_rdi => |value| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0xbf });
                try appendU64(&bytes, allocator, @bitCast(value));
            },
            .mov_imm_rdx => |value| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0xba });
                try appendU64(&bytes, allocator, @bitCast(value));
            },
            .mov_imm_rsi => |value| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0xbe });
                try appendU64(&bytes, allocator, @bitCast(value));
            },
            .mov_imm_rcx => |value| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0xb9 });
                try appendU64(&bytes, allocator, @bitCast(value));
            },
            .mov_imm_r8 => |value| {
                try bytes.appendSlice(allocator, &.{ 0x49, 0xb8 });
                try appendU64(&bytes, allocator, @bitCast(value));
            },
            .mov_imm_r9 => |value| {
                try bytes.appendSlice(allocator, &.{ 0x49, 0xb9 });
                try appendU64(&bytes, allocator, @bitCast(value));
            },
            .mov_rax_rdi => try bytes.appendSlice(allocator, &.{ 0x48, 0x89, 0xc7 }),
            .mov_arg_rax => |reg| try encodeRegToRax64(&bytes, allocator, reg),
            .movq_xmm_rax => |reg| try bytes.appendSlice(allocator, &.{ 0x66, 0x48, 0x0f, 0x7e, @as(u8, 0xc0) + (@as(u8, reg.lowCode()) << 3) }),
            .mov_arg_eax => |reg| try encodeRegToEax(&bytes, allocator, 0x89, reg),
            .mov_arg_arg => |mov| try encodeRegToReg(&bytes, allocator, mov.dst, mov.src),
            .mov_arg64_arg => |mov| try encodeReg64ToReg64(&bytes, allocator, mov.dst, mov.src),
            .push_arg => |reg| try encodePushArg(&bytes, allocator, reg),
            .pop_arg => |reg| try encodePopArg(&bytes, allocator, reg),
            .push_rax => try bytes.append(allocator, 0x50),
            .push_xmm64 => |reg| try encodePushXmm64(&bytes, allocator, reg),
            .push_byval_tail_arg_ptr => |copy| try encodePushByvalTailArgPtr(&bytes, allocator, copy.reg, copy.offset, copy.len),
            .push_byval_tail_stack_ptr => |copy| try encodePushByvalTailStackPtr(&bytes, allocator, copy.stack_disp, copy.offset, copy.len),
            .binary_arg_eax => |binary| try encodeRegToEax(&bytes, allocator, binaryOpcode(binary.op), binary.reg),
            .add_arg64_rax => |reg| try encodeRegToRax64Binary(&bytes, allocator, 0x01, reg),
            .add_arg_high32_eax => |reg| try encodeAddHigh32ToEax(&bytes, allocator, reg),
            .add_stack_disp8_eax => |disp| {
                try bytes.appendSlice(allocator, &.{ 0x03, 0x44, 0x24 });
                try bytes.append(allocator, disp);
            },
            .add_stack_disp8_rax => |disp| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0x03, 0x44, 0x24 });
                try bytes.append(allocator, disp);
            },
            .add_stack_disp32_eax => |disp| {
                try bytes.appendSlice(allocator, &.{ 0x03, 0x84, 0x24 });
                try appendU32(&bytes, allocator, disp);
            },
            .add_stack_disp32_rax => |disp| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0x03, 0x84, 0x24 });
                try appendU32(&bytes, allocator, disp);
            },
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
            .and_eax_imm32 => |value| {
                try bytes.appendSlice(allocator, &.{0x25});
                try appendI32(&bytes, allocator, value);
            },
            .shr_rax_imm6 => |amount| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0xc1, 0xe8 });
                try bytes.append(allocator, amount);
            },
            .shl_rdx_imm6 => |amount| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0xc1, 0xe2 });
                try bytes.append(allocator, amount);
            },
            .or_rdx_rax => try bytes.appendSlice(allocator, &.{ 0x48, 0x09, 0xd0 }),
            .shl_rcx_imm6 => |amount| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0xc1, 0xe1 });
                try bytes.append(allocator, amount);
            },
            .or_rcx_rax => try bytes.appendSlice(allocator, &.{ 0x48, 0x09, 0xc8 }),
            .or_rcx_rdx => try bytes.appendSlice(allocator, &.{ 0x48, 0x09, 0xca }),
            .add_rax_imm8 => |value| try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xc0, value }),
            .add_ecx_eax => try bytes.appendSlice(allocator, &.{ 0x01, 0xc8 }),
            .xor_ecx_ecx => try bytes.appendSlice(allocator, &.{ 0x31, 0xc9 }),
            .xor_ebp_ebp => try bytes.appendSlice(allocator, &.{ 0x31, 0xed }),
            .add_rdi_rcx4_ptr_eax => try bytes.appendSlice(allocator, &.{ 0x03, 0x04, 0x8f }),
            .load_rdi_rcx4_ptr_r8d => try bytes.appendSlice(allocator, &.{ 0x44, 0x8b, 0x04, 0x8f }),
            .cmp_r8d_arg32 => |reg| try encodeCmpArg32ToR8d(&bytes, allocator, reg),
            .add_r8d_eax => try bytes.appendSlice(allocator, &.{ 0x44, 0x01, 0xc0 }),
            .inc_rcx => try bytes.appendSlice(allocator, &.{ 0x48, 0xff, 0xc1 }),
            .movzx_dil_edi => try bytes.appendSlice(allocator, &.{ 0x40, 0x0f, 0xb6, 0xff }),
            .and_edi_imm8 => |value| try bytes.appendSlice(allocator, &.{ 0x83, 0xe7, value }),
            .load_rax_rdi_u8_eax => try bytes.appendSlice(allocator, &.{ 0x0f, 0xb6, 0x04, 0x38 }),
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
            .cmp_eax_imm32 => |value| {
                try bytes.append(allocator, 0x3d);
                try appendI32(&bytes, allocator, value);
            },
            .cmp_arg64_imm64 => |cmp| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0xb8 });
                try appendU64(&bytes, allocator, @bitCast(cmp.imm));
                const modrm = @as(u8, 0xc0) + cmp.reg.lowCode();
                if (cmp.reg.rexB()) try bytes.appendSlice(allocator, &.{ 0x49, 0x39, modrm }) else try bytes.appendSlice(allocator, &.{ 0x48, 0x39, modrm });
            },
            .cmp_arg16_imm16 => |cmp| try encodeCmp16Imm(&bytes, allocator, cmp.reg, cmp.imm),
            .cmp_rdi_imm64 => |value| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0xb8 });
                try appendU64(&bytes, allocator, @bitCast(value));
                try bytes.appendSlice(allocator, &.{ 0x48, 0x39, 0xc7 });
            },
            .cmp_rdx_rdi => try bytes.appendSlice(allocator, &.{ 0x48, 0x39, 0xfa }),
            .cmp_rax_rdx => try bytes.appendSlice(allocator, &.{ 0x48, 0x39, 0xd0 }),
            .test_eax_eax => try bytes.appendSlice(allocator, &.{ 0x85, 0xc0 }),
            .test_rax_rax => try bytes.appendSlice(allocator, &.{ 0x48, 0x85, 0xc0 }),
            .test_rdx_rdx => try bytes.appendSlice(allocator, &.{ 0x48, 0x85, 0xd2 }),
            .mulsd_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x59, 0xc1 }),
            .mulss_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x59, 0xc1 }),
            .addss_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x58, 0xc1 }),
            .subss_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x5c, 0xc1 }),
            .divsd_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x5e, 0xc1 }),
            .movapd_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0x66, 0x0f, 0x28, 0xc1 }),
            .movapd_xmm => |mov| try encodeMovapdXmm(&bytes, allocator, mov.dst, mov.src),
            .unpcklps_xmm => |mov| try bytes.appendSlice(allocator, &.{ 0x0f, 0x14, 0xc0 | (@as(u8, mov.dst.lowCode()) << 3) | @as(u8, mov.src.lowCode()) }),
            .shufps_high_f32_to_low => |reg| try bytes.appendSlice(allocator, &.{ 0x0f, 0xc6, 0xc0 | (@as(u8, reg.lowCode()) << 3) | @as(u8, reg.lowCode()), 0x55 }),
            .cvtsi2ss_edi_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x2a, 0xc7 }),
            .cvtsi2sd_edi_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x2a, 0xc7 }),
            .cvtsi2ss_rdi_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf3, 0x48, 0x0f, 0x2a, 0xc7 }),
            .cvtsi2sd_rdi_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf2, 0x48, 0x0f, 0x2a, 0xc7 }),
            .cvttss2si_xmm0_eax => try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x2c, 0xc0 }),
            .cvttsd2si_xmm0_eax => try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x2c, 0xc0 }),
            .cvtsd2ss_xmm0_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x5a, 0xc0 }),
            .cvtss2sd_xmm0_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x5a, 0xc0 }),
            .mov_edi_edi => try bytes.appendSlice(allocator, &.{ 0x89, 0xff }),
            .mov_imm64_xmm0 => |value| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0xb8 });
                try appendU64(&bytes, allocator, value);
                try bytes.appendSlice(allocator, &.{ 0x66, 0x48, 0x0f, 0x6e, 0xc0 });
            },
            .mov_imm64_xmm1 => |value| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0xb8 });
                try appendU64(&bytes, allocator, value);
                try bytes.appendSlice(allocator, &.{ 0x66, 0x48, 0x0f, 0x6e, 0xc8 });
            },
            .mov_imm32_xmm0 => |value| {
                try bytes.append(allocator, 0xb8);
                try appendU32(&bytes, allocator, value);
                try bytes.appendSlice(allocator, &.{ 0x66, 0x0f, 0x6e, 0xc0 });
            },
            .mov_imm32_xmm1 => |value| {
                try bytes.append(allocator, 0xb8);
                try appendU32(&bytes, allocator, value);
                try bytes.appendSlice(allocator, &.{ 0x66, 0x0f, 0x6e, 0xc8 });
            },
            .mov_imm64_xmm => |load| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0xb8 });
                try appendU64(&bytes, allocator, load.bits);
                try bytes.appendSlice(allocator, &.{ 0x66, 0x48, 0x0f, 0x6e, 0xc0 | (@as(u8, load.reg.lowCode()) << 3) });
            },
            .mov_imm32_xmm => |load| {
                try bytes.append(allocator, 0xb8);
                try appendU32(&bytes, allocator, load.bits);
                try bytes.appendSlice(allocator, &.{ 0x66, 0x0f, 0x6e, 0xc0 | (@as(u8, load.reg.lowCode()) << 3) });
            },
            .ucomisd => |cmp| try bytes.appendSlice(allocator, &.{ 0x66, 0x0f, 0x2e, 0xc0 | (@as(u8, cmp.dst.lowCode()) << 3) | @as(u8, cmp.src.lowCode()) }),
            .ucomisd_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0x66, 0x0f, 0x2e, 0xc1 }),
            .ucomiss_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0x0f, 0x2e, 0xc1 }),
            .ucomiss_xmm0_xmm1 => try bytes.appendSlice(allocator, &.{ 0x0f, 0x2e, 0xc8 }),
            .oltss_xmm0_xmm1_al => try bytes.appendSlice(allocator, &.{ 0x31, 0xc0, 0x0f, 0x2e, 0xc8, 0x0f, 0x97, 0xc0 }),
            .addsd_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x58, 0xc1 }),
            .sub_rsp_8 => try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xec, 0x08 }),
            .add_rsp_8 => try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xc4, 0x08 }),
            .push_imm32 => |value| {
                try bytes.append(allocator, 0x68);
                try appendI32(&bytes, allocator, value);
            },
            .push_stack_disp8 => |disp| try bytes.appendSlice(allocator, &.{ 0xff, 0x74, 0x24, disp }),
            .push_stack_disp32 => |disp| {
                try bytes.appendSlice(allocator, &.{ 0xff, 0xb4, 0x24 });
                try appendU32(&bytes, allocator, disp);
            },
            .sub_rsp_24 => try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xec, 0x18 }),
            .add_rsp_24 => try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xc4, 0x18 }),
            .sub_rsp_40 => try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xec, 0x28 }),
            .add_rsp_40 => try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xc4, 0x28 }),
            .sub_rsp_56 => try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xec, 0x38 }),
            .add_rsp_56 => try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xc4, 0x38 }),
            .add_rsp_imm8 => |value| try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xc4, value }),
            .add_rsp_imm32 => |value| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0x81, 0xc4 });
                try appendU32(&bytes, allocator, value);
            },
            .spill_arg_rsp => |spill| try encodeRegToFrameSlot(&bytes, allocator, 0x89, spill.reg, spill.frame_index),
            .spill_arg64_rsp => |spill| try encodeReg64ToFrameSlot(&bytes, allocator, 0x89, spill.reg, spill.frame_index),
            .reload_arg_rsp => |reload| try encodeFrameSlotToReg(&bytes, allocator, 0x8b, reload.reg, reload.frame_index),
            .reload_arg64_rsp => |reload| try encodeFrameSlotToReg64(&bytes, allocator, 0x8b, reload.reg, reload.frame_index),
            .spill_xmm32_rsp => |spill| try encodeXmmFrameSlot(&bytes, allocator, 0xf3, 0x11, spill.reg, spill.frame_index),
            .reload_xmm32_rsp => |reload| try encodeXmmFrameSlot(&bytes, allocator, 0xf3, 0x10, reload.reg, reload.frame_index),
            .spill_xmm64_rsp => |spill| try encodeXmmFrameSlot(&bytes, allocator, 0xf2, 0x11, spill.reg, spill.frame_index),
            .reload_xmm64_rsp => |reload| try encodeXmmFrameSlot(&bytes, allocator, 0xf2, 0x10, reload.reg, reload.frame_index),
            .spill_rdi_rsi_rsp24 => try bytes.appendSlice(allocator, &.{ 0x48, 0x89, 0x7c, 0x24, 0x08, 0x48, 0x89, 0x74, 0x24, 0x10 }),
            .reload_rdi_rsp24 => try bytes.appendSlice(allocator, &.{ 0x48, 0x8b, 0x7c, 0x24, 0x08 }),
            .reload_rsi_rsp24 => try bytes.appendSlice(allocator, &.{ 0x48, 0x8b, 0x74, 0x24, 0x10 }),
            .spill_eax_rsp => |frame_index| try encodeEaxToFrameSlot(&bytes, allocator, frame_index),
            .reload_rsp_eax => try bytes.appendSlice(allocator, &.{ 0x8b, 0x04, 0x24 }),
            .spill_rax_rsp => |frame_index| try encodeRaxToFrameSlot(&bytes, allocator, frame_index),
            .reload_rsp_rax => |frame_index| try encodeFrameSlotToRax(&bytes, allocator, frame_index),
            .load_stack_disp8_rax => |disp| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0x8b, 0x44, 0x24 });
                try bytes.append(allocator, disp);
            },
            .load_stack_disp32_rax => |disp| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0x8b, 0x84, 0x24 });
                try appendU32(&bytes, allocator, disp);
            },
            .load_stack_disp8_u8_eax => |disp| try encodeStackDisp8U8ToEax(&bytes, allocator, disp),
            .load_stack_disp32_u8_eax => |disp| try encodeStackDisp32U8ToEax(&bytes, allocator, disp),
            .load_stack_disp8_u16_eax => |disp| try encodeStackDisp8U16ToEax(&bytes, allocator, disp),
            .load_stack_disp32_u16_eax => |disp| try encodeStackDisp32U16ToEax(&bytes, allocator, disp),
            .load_stack_disp8_xmm0 => |disp| {
                try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x10, 0x44, 0x24 });
                try bytes.append(allocator, disp);
            },
            .load_stack_disp32_xmm0 => |disp| {
                try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x10, 0x84, 0x24 });
                try appendU32(&bytes, allocator, disp);
            },
            .load_stack_disp8_xmm0_f32 => |disp| {
                try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x10, 0x44, 0x24 });
                try bytes.append(allocator, disp);
            },
            .load_stack_disp32_xmm0_f32 => |disp| {
                try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x10, 0x84, 0x24 });
                try appendU32(&bytes, allocator, disp);
            },
            .load_stack_disp8_xmm => |load| {
                try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x10 });
                try bytes.append(allocator, 0x44 | (@as(u8, load.reg.lowCode()) << 3));
                try bytes.append(allocator, 0x24);
                try bytes.append(allocator, load.disp);
            },
            .load_stack_disp32_xmm => |load| {
                try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x10 });
                try bytes.append(allocator, 0x84 | (@as(u8, load.reg.lowCode()) << 3));
                try bytes.append(allocator, 0x24);
                try appendU32(&bytes, allocator, load.disp);
            },
            .load_stack_disp8_arg32 => |load| try encodeStackDisp8ToArg32(&bytes, allocator, load.reg, load.disp),
            .load_stack_disp8_arg64 => |load| try encodeStackDisp8ToArg64(&bytes, allocator, load.reg, load.disp),
            .load_stack_disp32_arg32 => |load| try encodeStackDisp32ToArg32(&bytes, allocator, load.reg, load.disp),
            .load_stack_disp32_arg64 => |load| try encodeStackDisp32ToArg64(&bytes, allocator, load.reg, load.disp),
            .load_rax_ptr_disp8_rax => |disp| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0x8b });
                if (disp == 0) {
                    try bytes.append(allocator, 0x00);
                } else {
                    try bytes.append(allocator, 0x40);
                    try bytes.append(allocator, disp);
                }
            },
            .load_rax_ptr_disp8_u8_eax => |disp| {
                try bytes.appendSlice(allocator, &.{ 0x0f, 0xb6 });
                try encodeRaxPtrDisp8Tail(&bytes, allocator, disp);
            },
            .load_rax_ptr_disp8_u16_eax => |disp| {
                try bytes.appendSlice(allocator, &.{ 0x0f, 0xb7 });
                try encodeRaxPtrDisp8Tail(&bytes, allocator, disp);
            },
            .load_rax_ptr_disp8_eax => |disp| {
                try bytes.append(allocator, 0x8b);
                try encodeRaxPtrDisp8Tail(&bytes, allocator, disp);
            },
            .load_rax_ptr_rdx => try bytes.appendSlice(allocator, &.{ 0x48, 0x8b, 0x10 }),
            .load_rax_ptr_eax => try bytes.appendSlice(allocator, &.{ 0x8b, 0x00 }),
            .load_arg_ptr_eax => |reg| try encodeArgPtrToEax(&bytes, allocator, reg),
            .load_arg_ptr_disp8_rax => |load| try encodeArgPtrDisp8ToRax(&bytes, allocator, load.reg, load.offset),
            .load_arg_ptr_disp8_eax => |load| try encodeArgPtrDisp8ToEax(&bytes, allocator, load.reg, load.offset),
            .load_arg_ptr_disp8_u8_eax => |load| try encodeArgPtrDisp8U8ToEax(&bytes, allocator, load.reg, load.offset),
            .load_arg_ptr_disp8_u16_eax => |load| try encodeArgPtrDisp8U16ToEax(&bytes, allocator, load.reg, load.offset),
            .add_arg_ptr_disp4_eax => |reg| try encodeArgPtrDisp4ToEax(&bytes, allocator, reg),
            .store_eax_arg_ptr => |reg| try encodeEaxToArgPtr(&bytes, allocator, reg),
            .store_imm64_arg_ptr_disp8 => |store| try encodeStoreImm64ArgPtrDisp8(&bytes, allocator, store.reg, store.offset, store.imm),
            .store_arg64_arg_ptr_disp8 => |store| try encodeStoreArg64ToArgPtrDisp8(&bytes, allocator, store.ptr_reg, store.src_reg, store.offset),
            .store_arg64_arg_ptr_disp32 => |store| try encodeStoreArg64ToArgPtrDisp32(&bytes, allocator, store.ptr_reg, store.src_reg, store.offset),
            .store_rax_arg_ptr_disp8 => |store| try encodeStoreRaxToArgPtrDisp8(&bytes, allocator, store.reg, store.offset),
            .store_rax_arg_ptr_disp32 => |store| try encodeStoreRaxToArgPtrDisp32(&bytes, allocator, store.reg, store.offset),
            .store_eax_arg_ptr_disp8 => |store| try encodeStoreEaxToArgPtrDisp8(&bytes, allocator, store.reg, store.offset),
            .store_eax_arg_ptr_disp32 => |store| try encodeStoreEaxToArgPtrDisp32(&bytes, allocator, store.reg, store.offset),
            .store_al_arg_ptr_disp8 => |store| try encodeStoreAlToArgPtrDisp8(&bytes, allocator, store.reg, store.offset),
            .store_al_arg_ptr_disp32 => |store| try encodeStoreAlToArgPtrDisp32(&bytes, allocator, store.reg, store.offset),
            .store_ax_arg_ptr_disp8 => |store| try encodeStoreAxToArgPtrDisp8(&bytes, allocator, store.reg, store.offset),
            .store_ax_arg_ptr_disp32 => |store| try encodeStoreAxToArgPtrDisp32(&bytes, allocator, store.reg, store.offset),
            .store_xmm0_arg_ptr_disp8 => |store| try encodeStoreXmm0ToArgPtrDisp8(&bytes, allocator, store.reg, store.offset),
            .store_xmm0_arg_ptr_disp32 => |store| try encodeStoreXmm0ToArgPtrDisp32(&bytes, allocator, store.reg, store.offset),
            .store_xmm0_f32_arg_ptr_disp8 => |store| try encodeStoreXmm0F32ToArgPtrDisp8(&bytes, allocator, store.reg, store.offset),
            .store_xmm0_f32_arg_ptr_disp32 => |store| try encodeStoreXmm0F32ToArgPtrDisp32(&bytes, allocator, store.reg, store.offset),
            .store_imm8_arg_ptr_disp8 => |store| try encodeStoreImm8ArgPtrDisp8(&bytes, allocator, store.reg, store.offset, store.imm),
            .load_f128_arg_ptr_xmm0 => |load| try encodeF128ArgPtrToXmm0(&bytes, allocator, load.reg, load.offset),
            .load_f128_const_xmm0 => try bytes.appendSlice(allocator, &.{ 0x0f, 0x28, 0x05, 0, 0, 0, 0 }),
            .load_f128_const_xmm1 => try bytes.appendSlice(allocator, &.{ 0x0f, 0x28, 0x0d, 0, 0, 0, 0 }),
            .store_f128_xmm0_arg_ptr => |store| try encodeF128Xmm0ToArgPtr(&bytes, allocator, store.reg, store.offset),
            .volatile_roundtrip_rdi_esi_eax => try bytes.appendSlice(allocator, &.{ 0x89, 0x37, 0x8b, 0x07 }),
            .load_global_i32_eax => try bytes.appendSlice(allocator, &.{ 0x8b, 0x05, 0, 0, 0, 0 }),
            .load_global_ptr_rax => try bytes.appendSlice(allocator, &.{ 0x48, 0x8b, 0x05, 0, 0, 0, 0 }),
            .lea_global_rax => try bytes.appendSlice(allocator, &.{ 0x48, 0x8d, 0x05, 0, 0, 0, 0 }),
            .lea_global_rdi => try bytes.appendSlice(allocator, &.{ 0x48, 0x8d, 0x3d, 0, 0, 0, 0 }),
            .lea_global_rsi => try bytes.appendSlice(allocator, &.{ 0x48, 0x8d, 0x35, 0, 0, 0, 0 }),
            .lea_global_rdx => try bytes.appendSlice(allocator, &.{ 0x48, 0x8d, 0x15, 0, 0, 0, 0 }),
            .store_eax_global_i32 => try bytes.appendSlice(allocator, &.{ 0x89, 0x05, 0, 0, 0, 0 }),
            .load_tls_i32_eax => try bytes.appendSlice(allocator, &.{ 0x64, 0x8b, 0x04, 0x25, 0, 0, 0, 0 }),
            .add_tls_i32_eax => try bytes.appendSlice(allocator, &.{ 0x64, 0x03, 0x04, 0x25, 0, 0, 0, 0 }),
            .store_eax_tls_i32 => try bytes.appendSlice(allocator, &.{ 0x64, 0x89, 0x04, 0x25, 0, 0, 0, 0 }),
            .atomic_xadd_global_eax => try bytes.appendSlice(allocator, &.{ 0xf0, 0x0f, 0xc1, 0x05, 0, 0, 0, 0 }),
            .mov_rsp_rdi => try bytes.appendSlice(allocator, &.{ 0x48, 0x89, 0xe7 }),
            .and_rsp_neg16 => try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xe4, 0xf0 }),
            .direct_call, .noreturn_direct_call => {
                try bytes.append(allocator, 0xe8);
                try appendI32(&bytes, allocator, 0);
            },
            .indirect_call_rax => try bytes.appendSlice(allocator, &.{ 0xff, 0xd0 }),
            .cmp_arg8_imm8 => |cmp| try encodeCmp8Imm(&bytes, allocator, cmp.reg, cmp.imm),
            .test_arg8 => |reg| try encodeTest8(&bytes, allocator, reg),
            .test_arg32 => |reg| try encodeTest32(&bytes, allocator, reg),
            .test_arg64 => |reg| try encodeTest64(&bytes, allocator, reg),
            .base64_raw_args_to_decode4_regs => try bytes.appendSlice(allocator, base64RawArgsToDecode4RegsBytes()),
            .base64_decode4_from_table_rax => try bytes.appendSlice(allocator, base64Decode4FromTableRaxBytes()),
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
            .jp => |label| {
                const target = offsets.get(label) orelse return error.InvalidBranchTarget;
                const next = offset + instructionSize(instruction);
                const displacement: i64 = @as(i64, @intCast(target)) - @as(i64, @intCast(next));
                if (displacement < std.math.minInt(i32) or displacement > std.math.maxInt(i32)) return error.BranchOutOfRange;
                try bytes.appendSlice(allocator, &.{ 0x0f, 0x8a });
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
            .jae => |label| {
                const target = offsets.get(label) orelse return error.InvalidBranchTarget;
                const next = offset + instructionSize(instruction);
                const displacement: i64 = @as(i64, @intCast(target)) - @as(i64, @intCast(next));
                if (displacement < std.math.minInt(i32) or displacement > std.math.maxInt(i32)) return error.BranchOutOfRange;
                try bytes.appendSlice(allocator, &.{ 0x0f, 0x83 });
                try appendI32(&bytes, allocator, @intCast(displacement));
            },
            .jle => |label| {
                const target = offsets.get(label) orelse return error.InvalidBranchTarget;
                const next = offset + instructionSize(instruction);
                const displacement: i64 = @as(i64, @intCast(target)) - @as(i64, @intCast(next));
                if (displacement < std.math.minInt(i32) or displacement > std.math.maxInt(i32)) return error.BranchOutOfRange;
                try bytes.appendSlice(allocator, &.{ 0x0f, 0x8e });
                try appendI32(&bytes, allocator, @intCast(displacement));
            },
            .jmp => |label| {
                const target = offsets.get(label) orelse return error.InvalidBranchTarget;
                const next = offset + instructionSize(instruction);
                const displacement: i64 = @as(i64, @intCast(target)) - @as(i64, @intCast(next));
                if (displacement < std.math.minInt(i32) or displacement > std.math.maxInt(i32)) return error.BranchOutOfRange;
                try bytes.append(allocator, 0xe9);
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
        .mov_imm_rax => 10,
        .mov_imm_rdi => 10,
        .mov_imm_rdx => 10,
        .mov_imm_rsi => 10,
        .mov_imm_rcx => 10,
        .mov_imm_r8 => 10,
        .mov_imm_r9 => 10,
        .mov_rax_rdi => 3,
        .mov_arg_rax => 3,
        .movq_xmm_rax => 5,
        .mov_arg_eax => |reg| if (reg.rexR()) 3 else 2,
        .mov_arg_arg => |mov| if (mov.src.rexR() or mov.dst.rexR()) 3 else 2,
        .mov_arg64_arg => 3,
        .push_arg => |reg| if (reg.rexB()) 2 else 1,
        .pop_arg => |reg| if (reg.rexB()) 2 else 1,
        .push_rax => 1,
        .push_xmm64 => 9,
        .push_byval_tail_arg_ptr => |copy| pushByvalTailArgPtrSize(copy.reg, copy.offset, copy.len),
        .push_byval_tail_stack_ptr => |copy| pushByvalTailStackPtrSize(copy.len),
        .binary_arg_eax => |binary| if (binary.reg.rexR()) 3 else 2,
        .add_arg64_rax => |reg| if (reg.rexR()) 3 else 2,
        .add_arg_high32_eax => |reg| (if (reg.rexR()) @as(u32, 3) else 3) + 6,
        .add_stack_disp8_eax => 4,
        .add_stack_disp8_rax => 5,
        .add_stack_disp32_eax => 7,
        .add_stack_disp32_rax => 8,
        .add_eax_imm32 => 5,
        .shl_eax_imm5 => 3,
        .or_eax_imm32 => 5,
        .imul_eax_imm32 => 6,
        .and_eax_imm32 => 5,
        .shr_rax_imm6 => 4,
        .shl_rdx_imm6 => 4,
        .or_rdx_rax => 3,
        .shl_rcx_imm6 => 4,
        .or_rcx_rax => 3,
        .or_rcx_rdx => 3,
        .add_rax_imm8 => 4,
        .add_ecx_eax => 2,
        .xor_ecx_ecx => 2,
        .xor_ebp_ebp => 2,
        .add_rdi_rcx4_ptr_eax => 3,
        .load_rdi_rcx4_ptr_r8d => 4,
        .cmp_r8d_arg32 => |reg| if (reg.rexR()) 4 else 3,
        .add_r8d_eax => 3,
        .inc_rcx => 3,
        .movzx_dil_edi, .load_rax_rdi_u8_eax => 4,
        .and_edi_imm8 => 3,
        .smin_i32_edi_esi_eax => 7,
        .shift_mix_i32_edi_esi_eax => 15,
        .replace_low_i8_dil_sil_al => 12,
        .read_flag_i8_dil_al => 8,
        .store_imm8_abs => 8,
        .cmp_ecx_arg32 => |reg| if (reg.rexB()) 3 else 2,
        .cmp_rcx_arg64 => |reg| if (reg.rexB()) 4 else 3,
        .cmp_ecx_imm32 => 6,
        .cmp_eax_imm32 => 5,
        .cmp_arg64_imm64 => |cmp| if (cmp.reg.rexB()) 14 else 13,
        .cmp_arg16_imm16 => |cmp| if (cmp.reg.rexB()) 6 else 5,
        .cmp_rdi_imm64 => 13,
        .cmp_rdx_rdi => 3,
        .cmp_rax_rdx => 3,
        .test_eax_eax => 2,
        .test_rax_rax, .test_rdx_rdx => 3,
        .mulsd_xmm1_xmm0 => 4,
        .mulss_xmm1_xmm0 => 4,
        .addss_xmm1_xmm0 => 4,
        .subss_xmm1_xmm0 => 4,
        .divsd_xmm1_xmm0 => 4,
        .movapd_xmm1_xmm0, .movapd_xmm => 4,
        .unpcklps_xmm => 3,
        .shufps_high_f32_to_low => 4,
        .cvtsi2ss_edi_xmm0 => 4,
        .cvtsi2sd_edi_xmm0 => 4,
        .cvtsi2ss_rdi_xmm0 => 5,
        .cvtsi2sd_rdi_xmm0 => 5,
        .cvttss2si_xmm0_eax => 4,
        .cvttsd2si_xmm0_eax => 4,
        .cvtsd2ss_xmm0_xmm0 => 4,
        .cvtss2sd_xmm0_xmm0 => 4,
        .mov_edi_edi => 2,
        .mov_imm64_xmm0 => 15,
        .mov_imm64_xmm1 => 15,
        .mov_imm32_xmm0 => 9,
        .mov_imm32_xmm1 => 9,
        .mov_imm64_xmm => 15,
        .mov_imm32_xmm => 9,
        .ucomisd => 4,
        .ucomisd_xmm1_xmm0 => 4,
        .ucomiss_xmm1_xmm0 => 3,
        .ucomiss_xmm0_xmm1 => 3,
        .oltss_xmm0_xmm1_al => 8,
        .addsd_xmm1_xmm0 => 4,
        .sub_rsp_8, .add_rsp_8 => 4,
        .push_imm32 => 5,
        .push_stack_disp8 => 4,
        .push_stack_disp32 => 7,
        .sub_rsp_24, .add_rsp_24, .sub_rsp_40, .add_rsp_40, .sub_rsp_56, .add_rsp_56, .add_rsp_imm8 => 4,
        .add_rsp_imm32 => 7,
        .spill_arg_rsp => |spill| frameSlotInstructionSize(spill.reg, spill.frame_index),
        .spill_arg64_rsp => |spill| frameSlotInstructionSize64(spill.reg, spill.frame_index),
        .reload_arg_rsp => |reload| frameSlotInstructionSize(reload.reg, reload.frame_index),
        .reload_arg64_rsp => |reload| frameSlotInstructionSize64(reload.reg, reload.frame_index),
        .spill_xmm32_rsp, .reload_xmm32_rsp, .spill_xmm64_rsp, .reload_xmm64_rsp => 6,
        .spill_rdi_rsi_rsp24 => 10,
        .reload_rdi_rsp24, .reload_rsi_rsp24 => 5,
        .spill_eax_rsp => |frame_index| eaxFrameSlotInstructionSize(frame_index),
        .reload_rsp_eax => 3,
        .spill_rax_rsp, .reload_rsp_rax => |frame_index| raxFrameSlotInstructionSize(frame_index),
        .load_stack_disp8_rax => 5,
        .load_stack_disp32_rax => 8,
        .load_stack_disp8_u8_eax, .load_stack_disp8_u16_eax => 5,
        .load_stack_disp32_u8_eax, .load_stack_disp32_u16_eax => 8,
        .load_stack_disp8_xmm0 => 6,
        .load_stack_disp32_xmm0 => 9,
        .load_stack_disp8_xmm0_f32 => 6,
        .load_stack_disp32_xmm0_f32 => 9,
        .load_stack_disp8_xmm => 6,
        .load_stack_disp32_xmm => 9,
        .load_stack_disp8_arg32 => |load| if (load.reg.rexR()) 5 else 4,
        .load_stack_disp8_arg64 => 5,
        .load_stack_disp32_arg32 => |load| if (load.reg.rexR()) 8 else 7,
        .load_stack_disp32_arg64 => 8,
        .load_rax_ptr_disp8_rax => |offset| 3 + if (offset == 0) @as(u32, 0) else 1,
        .load_rax_ptr_disp8_u8_eax => |offset| 3 + if (offset == 0) @as(u32, 0) else 1,
        .load_rax_ptr_disp8_u16_eax => |offset| 3 + if (offset == 0) @as(u32, 0) else 1,
        .load_rax_ptr_disp8_eax => |offset| 2 + if (offset == 0) @as(u32, 0) else 1,
        .load_rax_ptr_rdx => 3,
        .load_rax_ptr_eax => 2,
        .load_arg_ptr_eax => |reg| if (reg.rexB()) 3 else 2,
        .load_arg_ptr_disp8_rax => |load| 3 + if (load.offset == 0) @as(u32, 0) else 1,
        .load_arg_ptr_disp8_eax => |load| (if (load.reg.rexB()) @as(u32, 1) else 0) + 2 + if (load.offset == 0) @as(u32, 0) else 1,
        .load_arg_ptr_disp8_u8_eax => |load| (if (load.reg.rexB()) @as(u32, 1) else 0) + 3 + if (load.offset == 0) @as(u32, 0) else 1,
        .load_arg_ptr_disp8_u16_eax => |load| (if (load.reg.rexB()) @as(u32, 1) else 0) + 3 + if (load.offset == 0) @as(u32, 0) else 1,
        .add_arg_ptr_disp4_eax => |reg| if (reg.rexB()) 4 else 3,
        .store_eax_arg_ptr => |reg| if (reg.rexB()) 3 else 2,
        .store_imm64_arg_ptr_disp8 => |store| 7 + if (store.offset == 0) @as(u32, 0) else 1,
        .store_arg64_arg_ptr_disp8 => |store| 3 + if (store.offset == 0) @as(u32, 0) else 1,
        .store_arg64_arg_ptr_disp32 => 7,
        .store_rax_arg_ptr_disp8 => |store| 3 + if (store.offset == 0) @as(u32, 0) else 1,
        .store_rax_arg_ptr_disp32 => 7,
        .store_eax_arg_ptr_disp8 => |store| (if (store.reg.rexB()) @as(u32, 1) else 0) + 2 + if (store.offset == 0) @as(u32, 0) else 1,
        .store_eax_arg_ptr_disp32 => |store| (if (store.reg.rexB()) @as(u32, 1) else 0) + 6,
        .store_al_arg_ptr_disp8 => |store| (if (store.reg.rexB()) @as(u32, 1) else 0) + 2 + if (store.offset == 0) @as(u32, 0) else 1,
        .store_al_arg_ptr_disp32 => |store| (if (store.reg.rexB()) @as(u32, 1) else 0) + 6,
        .store_ax_arg_ptr_disp8 => |store| 1 + (if (store.reg.rexB()) @as(u32, 1) else 0) + 2 + if (store.offset == 0) @as(u32, 0) else 1,
        .store_ax_arg_ptr_disp32 => |store| 1 + (if (store.reg.rexB()) @as(u32, 1) else 0) + 6,
        .store_xmm0_arg_ptr_disp8 => |store| (if (store.reg.rexB()) @as(u32, 1) else 0) + 4 + if (store.offset == 0) @as(u32, 0) else 1,
        .store_xmm0_arg_ptr_disp32 => |store| (if (store.reg.rexB()) @as(u32, 1) else 0) + 8,
        .store_xmm0_f32_arg_ptr_disp8 => |store| (if (store.reg.rexB()) @as(u32, 1) else 0) + 4 + if (store.offset == 0) @as(u32, 0) else 1,
        .store_xmm0_f32_arg_ptr_disp32 => |store| (if (store.reg.rexB()) @as(u32, 1) else 0) + 8,
        .store_imm8_arg_ptr_disp8 => |store| (if (store.reg.rexB()) @as(u32, 1) else 0) + 3 + if (store.offset == 0) @as(u32, 0) else 1,
        .load_f128_arg_ptr_xmm0 => |load| f128ArgPtrInstructionSize(load.reg, load.offset),
        .load_f128_const_xmm0, .load_f128_const_xmm1 => 7,
        .store_f128_xmm0_arg_ptr => |store| f128ArgPtrInstructionSize(store.reg, store.offset),
        .volatile_roundtrip_rdi_esi_eax => 4,
        .load_global_i32_eax, .store_eax_global_i32 => 6,
        .load_global_ptr_rax, .lea_global_rax, .lea_global_rdi, .lea_global_rsi, .lea_global_rdx => 7,
        .load_tls_i32_eax, .add_tls_i32_eax, .store_eax_tls_i32 => 8,
        .atomic_xadd_global_eax => 8,
        .mov_rsp_rdi => 3,
        .and_rsp_neg16 => 4,
        .direct_call, .noreturn_direct_call => 5,
        .indirect_call_rax => 2,
        .cmp_arg8_imm8 => |cmp| if (cmp.reg.needsRex8()) 4 else 3,
        .test_arg8 => |reg| if (reg.needsRex8()) 3 else 2,
        .test_arg32 => |reg| if (reg.rexR()) 3 else 2,
        .test_arg64 => 3,
        .base64_raw_args_to_decode4_regs => @intCast(base64RawArgsToDecode4RegsBytes().len),
        .base64_decode4_from_table_rax => @intCast(base64Decode4FromTableRaxBytes().len),
        .ud2 => 2,
        .je, .jne, .jo, .jp, .js, .jae, .jle => 6,
        .jmp => 5,
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

fn base64Decode4FromTableRaxBytes() []const u8 {
    return &.{
        0x48, 0x83, 0xfe, 0x04, 0x0f, 0x85, 0xf7, 0x00,
        0x00, 0x00, 0x44, 0x0f, 0xb6, 0x07, 0x46, 0x0f,
        0xb6, 0x04, 0x00, 0x41, 0x80, 0xf8, 0xff, 0x0f,
        0x84, 0xe4, 0x00, 0x00, 0x00, 0x44, 0x0f, 0xb6,
        0x4f, 0x01, 0x46, 0x0f, 0xb6, 0x0c, 0x08, 0x41,
        0x80, 0xf9, 0xff, 0x0f, 0x84, 0xd0, 0x00, 0x00,
        0x00, 0x44, 0x0f, 0xb6, 0x57, 0x02, 0x41, 0x80,
        0xfa, 0x3d, 0x0f, 0x84, 0x9a, 0x00, 0x00, 0x00,
        0x46, 0x0f, 0xb6, 0x14, 0x10, 0x41, 0x80, 0xfa,
        0xff, 0x0f, 0x84, 0xb2, 0x00, 0x00, 0x00, 0x44,
        0x0f, 0xb6, 0x5f, 0x03, 0x41, 0x80, 0xfb, 0x3d,
        0x74, 0x4d, 0x46, 0x0f, 0xb6, 0x1c, 0x18, 0x41,
        0x80, 0xfb, 0xff, 0x0f, 0x84, 0x98, 0x00, 0x00,
        0x00, 0x48, 0x83, 0xf9, 0x03, 0x0f, 0x82, 0x8e,
        0x00, 0x00, 0x00, 0x41, 0xc1, 0xe0, 0x12, 0x41,
        0xc1, 0xe1, 0x0c, 0x45, 0x09, 0xc8, 0x41, 0xc1,
        0xe2, 0x06, 0x45, 0x09, 0xd0, 0x45, 0x09, 0xd8,
        0x45, 0x89, 0xc1, 0x41, 0xc1, 0xe9, 0x10, 0x44,
        0x88, 0x0a, 0x45, 0x89, 0xc1, 0x41, 0xc1, 0xe9,
        0x08, 0x44, 0x88, 0x4a, 0x01, 0x44, 0x88, 0x42,
        0x02, 0xb8, 0x03, 0x00, 0x00, 0x00, 0xc3, 0x48,
        0x83, 0xf9, 0x02, 0x72, 0x54, 0x41, 0xc1, 0xe0,
        0x12, 0x41, 0xc1, 0xe1, 0x0c, 0x45, 0x09, 0xc8,
        0x41, 0xc1, 0xe2, 0x06, 0x45, 0x09, 0xd0, 0x45,
        0x89, 0xc1, 0x41, 0xc1, 0xe9, 0x10, 0x44, 0x88,
        0x0a, 0x45, 0x89, 0xc1, 0x41, 0xc1, 0xe9, 0x08,
        0x44, 0x88, 0x4a, 0x01, 0xb8, 0x02, 0x00, 0x00,
        0x00, 0xc3, 0x80, 0x7f, 0x03, 0x3d, 0x75, 0x21,
        0x48, 0x83, 0xf9, 0x01, 0x72, 0x1b, 0x41, 0xc1,
        0xe0, 0x12, 0x41, 0xc1, 0xe1, 0x0c, 0x45, 0x09,
        0xc8, 0x45, 0x89, 0xc1, 0x41, 0xc1, 0xe9, 0x10,
        0x44, 0x88, 0x0a, 0xb8, 0x01, 0x00, 0x00, 0x00,
        0xc3, 0x48, 0xb8, 0xff, 0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xc3,
    };
}

fn base64RawArgsToDecode4RegsBytes() []const u8 {
    return &.{
        0x48, 0x05, 0x00, 0x10, 0x00, 0x00, 0x49, 0x89,
        0xf8, 0x48, 0x89, 0xd7, 0x4c, 0x89, 0xc2, 0x49,
        0x89, 0xf0, 0x48, 0x89, 0xce, 0x4c, 0x89, 0xc1,
    };
}

fn encodeRegToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, opcode: u8, reg: x86_64.ArgReg) !void {
    if (reg.rexR()) try bytes.append(allocator, 0x44);
    try bytes.append(allocator, opcode);
    try bytes.append(allocator, 0xc0 | (@as(u8, reg.lowCode()) << 3));
}

fn encodeRegToRax64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    try bytes.append(allocator, if (reg.rexB()) 0x49 else 0x48);
    try bytes.append(allocator, 0x8b);
    try bytes.append(allocator, 0xc0 | @as(u8, reg.lowCode()));
}

fn encodeRegToRax64Binary(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, opcode: u8, reg: x86_64.ArgReg) !void {
    var rex: u8 = 0x48;
    if (reg.rexR()) rex |= 0x04;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, opcode);
    try bytes.append(allocator, 0xc0 | (@as(u8, reg.lowCode()) << 3));
}

fn encodeAddHigh32ToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    try encodeReg64ToReg64(bytes, allocator, .rcx, reg);
    try bytes.appendSlice(allocator, &.{ 0x48, 0xc1, 0xe9, 0x20, 0x01, 0xc8 });
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

fn encodeReg64ToReg64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, dst: x86_64.ArgReg, src: x86_64.ArgReg) !void {
    var rex: u8 = 0x48;
    if (src.rexR()) rex |= 0x04;
    if (dst.rexR()) rex |= 0x01;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0x89);
    try bytes.append(allocator, 0xc0 | (@as(u8, src.lowCode()) << 3) | @as(u8, dst.lowCode()));
}

fn encodePushArg(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x50 + @as(u8, reg.lowCode()));
}

fn encodePopArg(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x58 + @as(u8, reg.lowCode()));
}

fn encodePushXmm64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.XmmReg) !void {
    try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xec, 0x08 });
    try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x11, 0x04 | (@as(u8, reg.lowCode()) << 3), 0x24 });
}

fn encodeRegToFrameSlot(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, opcode: u8, reg: x86_64.ArgReg, frame_index: x86_64.FrameIndex) !void {
    if (reg.rexR()) try bytes.append(allocator, 0x44);
    try bytes.append(allocator, opcode);
    const disp = frameSlotDisp(frame_index);
    try bytes.append(allocator, (if (disp == 0) @as(u8, 0x04) else @as(u8, 0x44)) | (@as(u8, reg.lowCode()) << 3));
    try bytes.append(allocator, 0x24);
    if (disp != 0) try bytes.append(allocator, disp);
}

fn encodeReg64ToFrameSlot(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, opcode: u8, reg: x86_64.ArgReg, frame_index: x86_64.FrameIndex) !void {
    try bytes.append(allocator, 0x48 | if (reg.rexR()) @as(u8, 0x04) else 0);
    try bytes.append(allocator, opcode);
    const disp = frameSlotDisp(frame_index);
    try bytes.append(allocator, (if (disp == 0) @as(u8, 0x04) else @as(u8, 0x44)) | (@as(u8, reg.lowCode()) << 3));
    try bytes.append(allocator, 0x24);
    if (disp != 0) try bytes.append(allocator, disp);
}

fn encodeFrameSlotToReg(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, opcode: u8, reg: x86_64.ArgReg, frame_index: x86_64.FrameIndex) !void {
    if (reg.rexR()) try bytes.append(allocator, 0x44);
    try bytes.append(allocator, opcode);
    const disp = frameSlotDisp(frame_index);
    try bytes.append(allocator, (if (disp == 0) @as(u8, 0x04) else @as(u8, 0x44)) | (@as(u8, reg.lowCode()) << 3));
    try bytes.append(allocator, 0x24);
    if (disp != 0) try bytes.append(allocator, disp);
}

fn encodeFrameSlotToReg64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, opcode: u8, reg: x86_64.ArgReg, frame_index: x86_64.FrameIndex) !void {
    try bytes.append(allocator, 0x48 | if (reg.rexR()) @as(u8, 0x04) else 0);
    try bytes.append(allocator, opcode);
    const disp = frameSlotDisp(frame_index);
    try bytes.append(allocator, (if (disp == 0) @as(u8, 0x04) else @as(u8, 0x44)) | (@as(u8, reg.lowCode()) << 3));
    try bytes.append(allocator, 0x24);
    if (disp != 0) try bytes.append(allocator, disp);
}

fn encodeEaxToFrameSlot(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, frame_index: x86_64.FrameIndex) !void {
    try bytes.append(allocator, 0x89);
    const disp = frameSlotDisp(frame_index);
    try bytes.append(allocator, if (disp == 0) @as(u8, 0x04) else @as(u8, 0x44));
    try bytes.append(allocator, 0x24);
    if (disp != 0) try bytes.append(allocator, disp);
}

fn encodeRaxToFrameSlot(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, frame_index: x86_64.FrameIndex) !void {
    try bytes.appendSlice(allocator, &.{ 0x48, 0x89 });
    const disp = frameSlotDisp(frame_index);
    try bytes.append(allocator, if (disp == 0) @as(u8, 0x04) else @as(u8, 0x44));
    try bytes.append(allocator, 0x24);
    if (disp != 0) try bytes.append(allocator, disp);
}

fn encodeFrameSlotToRax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, frame_index: x86_64.FrameIndex) !void {
    try bytes.appendSlice(allocator, &.{ 0x48, 0x8b });
    const disp = frameSlotDisp(frame_index);
    try bytes.append(allocator, if (disp == 0) @as(u8, 0x04) else @as(u8, 0x44));
    try bytes.append(allocator, 0x24);
    if (disp != 0) try bytes.append(allocator, disp);
}

fn encodeStackDisp8ToArg32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, disp: u8) !void {
    if (reg.rexR()) try bytes.append(allocator, 0x44);
    try bytes.append(allocator, 0x8b);
    try bytes.append(allocator, 0x44 | (@as(u8, reg.lowCode()) << 3));
    try bytes.append(allocator, 0x24);
    try bytes.append(allocator, disp);
}

fn encodeStackDisp32ToArg32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, disp: u32) !void {
    if (reg.rexR()) try bytes.append(allocator, 0x44);
    try bytes.append(allocator, 0x8b);
    try bytes.append(allocator, 0x84 | (@as(u8, reg.lowCode()) << 3));
    try bytes.append(allocator, 0x24);
    try appendU32(bytes, allocator, disp);
}

fn encodeStackDisp8ToArg64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, disp: u8) !void {
    var rex: u8 = 0x48;
    if (reg.rexR()) rex |= 0x04;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0x8b);
    try bytes.append(allocator, 0x44 | (@as(u8, reg.lowCode()) << 3));
    try bytes.append(allocator, 0x24);
    try bytes.append(allocator, disp);
}

fn encodeStackDisp32ToArg64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, disp: u32) !void {
    var rex: u8 = 0x48;
    if (reg.rexR()) rex |= 0x04;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0x8b);
    try bytes.append(allocator, 0x84 | (@as(u8, reg.lowCode()) << 3));
    try bytes.append(allocator, 0x24);
    try appendU32(bytes, allocator, disp);
}

fn encodeStackDisp8U8ToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, disp: u8) !void {
    try bytes.appendSlice(allocator, &.{ 0x0f, 0xb6, 0x44, 0x24 });
    try bytes.append(allocator, disp);
}

fn encodeStackDisp32U8ToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, disp: u32) !void {
    try bytes.appendSlice(allocator, &.{ 0x0f, 0xb6, 0x84, 0x24 });
    try appendU32(bytes, allocator, disp);
}

fn encodeStackDisp8U16ToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, disp: u8) !void {
    try bytes.appendSlice(allocator, &.{ 0x0f, 0xb7, 0x44, 0x24 });
    try bytes.append(allocator, disp);
}

fn encodeStackDisp32U16ToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, disp: u32) !void {
    try bytes.appendSlice(allocator, &.{ 0x0f, 0xb7, 0x84, 0x24 });
    try appendU32(bytes, allocator, disp);
}

fn encodeXmmFrameSlot(
    bytes: *std.ArrayList(u8),
    allocator: std.mem.Allocator,
    prefix: u8,
    opcode: u8,
    reg: x86_64.XmmReg,
    frame_index: x86_64.FrameIndex,
) !void {
    try bytes.appendSlice(allocator, &.{ prefix, 0x0f, opcode });
    try bytes.append(allocator, 0x44 | (@as(u8, reg.lowCode()) << 3));
    try bytes.append(allocator, 0x24);
    try bytes.append(allocator, frameSlotDisp(frame_index));
}

fn frameSlotDisp(frame_index: x86_64.FrameIndex) u8 {
    return switch (frame_index) {
        .slot0 => 0,
        .slot1 => 4,
        .slot2 => 8,
        .slot3 => 12,
        .slot4 => 16,
        .slot5 => 20,
        .slot6 => 24,
        .slot7 => 28,
        .slot8 => 32,
        .slot9 => 36,
        .slot10 => 40,
    };
}

fn frameSlotInstructionSize(reg: x86_64.ArgReg, frame_index: x86_64.FrameIndex) u32 {
    return (if (reg.rexR()) @as(u32, 1) else 0) + 3 + if (frameSlotDisp(frame_index) == 0) @as(u32, 0) else 1;
}

fn frameSlotInstructionSize64(reg: x86_64.ArgReg, frame_index: x86_64.FrameIndex) u32 {
    _ = reg;
    return 4 + if (frameSlotDisp(frame_index) == 0) @as(u32, 0) else 1;
}

fn eaxFrameSlotInstructionSize(frame_index: x86_64.FrameIndex) u32 {
    return 3 + if (frameSlotDisp(frame_index) == 0) @as(u32, 0) else 1;
}

fn raxFrameSlotInstructionSize(frame_index: x86_64.FrameIndex) u32 {
    return 4 + if (frameSlotDisp(frame_index) == 0) @as(u32, 0) else 1;
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

fn encodeArgPtrDisp8ToRax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    try bytes.append(allocator, if (reg.rexB()) 0x49 else 0x48);
    try bytes.append(allocator, 0x8b);
    try encodeArgPtrDisp8Tail(bytes, allocator, reg, offset);
}

fn encodeArgPtrDisp8ToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x8b);
    try encodeArgPtrDisp8Tail(bytes, allocator, reg, offset);
}

fn encodeArgPtrDisp8U8ToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.appendSlice(allocator, &.{ 0x0f, 0xb6 });
    try encodeArgPtrDisp8Tail(bytes, allocator, reg, offset);
}

fn encodeArgPtrDisp8U16ToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.appendSlice(allocator, &.{ 0x0f, 0xb7 });
    try encodeArgPtrDisp8Tail(bytes, allocator, reg, offset);
}

fn encodePushByvalTailArgPtr(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8, len: u8) !void {
    try validateByvalTail(offset, len);
    try encodeReserveZeroedStackEightbyte(bytes, allocator);
    var index: u8 = 0;
    while (index < len) : (index += 1) {
        try encodeArgPtrDisp8U8ToEax(bytes, allocator, reg, offset + index);
        try encodeStoreAlToRspDisp8(bytes, allocator, index);
    }
}

fn encodePushByvalTailStackPtr(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, stack_disp: u8, offset: u8, len: u8) !void {
    try validateByvalTail(offset, len);
    try encodeStackDisp8ToRdx(bytes, allocator, stack_disp);
    try encodeReserveZeroedStackEightbyte(bytes, allocator);
    var index: u8 = 0;
    while (index < len) : (index += 1) {
        try encodeRdxPtrDisp8U8ToEax(bytes, allocator, offset + index);
        try encodeStoreAlToRspDisp8(bytes, allocator, index);
    }
}

fn validateByvalTail(offset: u8, len: u8) !void {
    switch (len) {
        3, 5, 6, 7 => {},
        else => return error.UnsupportedSretByvalAbi,
    }
    if (@as(u16, offset) + @as(u16, len) > 256) return error.UnsupportedCodegenAbi;
}

fn encodeReserveZeroedStackEightbyte(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator) !void {
    try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xec, 0x08 });
    try bytes.appendSlice(allocator, &.{ 0x48, 0xc7, 0x04, 0x24, 0x00, 0x00, 0x00, 0x00 });
}

fn encodeStackDisp8ToRdx(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, stack_disp: u8) !void {
    try bytes.appendSlice(allocator, &.{ 0x48, 0x8b, 0x54, 0x24, stack_disp });
}

fn encodeRdxPtrDisp8U8ToEax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, offset: u8) !void {
    try bytes.appendSlice(allocator, &.{ 0x0f, 0xb6, 0x42, offset });
}

fn encodeStoreAlToRspDisp8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, offset: u8) !void {
    try bytes.appendSlice(allocator, &.{ 0x88, 0x44, 0x24, offset });
}

fn pushByvalTailArgPtrSize(reg: x86_64.ArgReg, offset: u8, len: u8) u32 {
    var size: u32 = 12;
    var index: u8 = 0;
    while (index < len) : (index += 1) {
        const current = offset + index;
        size += (if (reg.rexB()) @as(u32, 1) else 0) + 3 + if (current == 0) @as(u32, 0) else 1;
        size += 4;
    }
    return size;
}

fn pushByvalTailStackPtrSize(len: u8) u32 {
    return 5 + 12 + @as(u32, len) * 8;
}

fn encodeStoreImm64ArgPtrDisp8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8, imm: i32) !void {
    try bytes.append(allocator, if (reg.rexB()) 0x49 else 0x48);
    try bytes.append(allocator, 0xc7);
    try encodeArgPtrDisp8Tail(bytes, allocator, reg, offset);
    try appendI32(bytes, allocator, imm);
}

fn encodeStoreArg64ToArgPtrDisp8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, ptr_reg: x86_64.ArgReg, src_reg: x86_64.ArgReg, offset: u8) !void {
    var rex: u8 = 0x48;
    if (src_reg.rexR()) rex |= 0x04;
    if (ptr_reg.rexB()) rex |= 0x01;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0x89);
    if (offset == 0) {
        try bytes.append(allocator, (@as(u8, src_reg.lowCode()) << 3) | @as(u8, ptr_reg.lowCode()));
    } else {
        try bytes.append(allocator, 0x40 | (@as(u8, src_reg.lowCode()) << 3) | @as(u8, ptr_reg.lowCode()));
        try bytes.append(allocator, offset);
    }
}

fn encodeStoreArg64ToArgPtrDisp32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, ptr_reg: x86_64.ArgReg, src_reg: x86_64.ArgReg, offset: u32) !void {
    var rex: u8 = 0x48;
    if (src_reg.rexR()) rex |= 0x04;
    if (ptr_reg.rexB()) rex |= 0x01;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0x89);
    try bytes.append(allocator, 0x80 | (@as(u8, src_reg.lowCode()) << 3) | @as(u8, ptr_reg.lowCode()));
    try appendU32(bytes, allocator, offset);
}

fn encodeStoreRaxToArgPtrDisp8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    try bytes.append(allocator, if (reg.rexB()) 0x49 else 0x48);
    try bytes.append(allocator, 0x89);
    if (offset == 0) {
        try bytes.append(allocator, @as(u8, reg.lowCode()));
    } else {
        try bytes.append(allocator, 0x40 | @as(u8, reg.lowCode()));
        try bytes.append(allocator, offset);
    }
}

fn encodeStoreRaxToArgPtrDisp32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u32) !void {
    try bytes.append(allocator, if (reg.rexB()) 0x49 else 0x48);
    try bytes.append(allocator, 0x89);
    try bytes.append(allocator, 0x80 | @as(u8, reg.lowCode()));
    try appendU32(bytes, allocator, offset);
}

fn encodeStoreEaxToArgPtrDisp8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x89);
    if (offset == 0) {
        try bytes.append(allocator, @as(u8, reg.lowCode()));
    } else {
        try bytes.append(allocator, 0x40 | @as(u8, reg.lowCode()));
        try bytes.append(allocator, offset);
    }
}

fn encodeStoreEaxToArgPtrDisp32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u32) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x89);
    try bytes.append(allocator, 0x80 | @as(u8, reg.lowCode()));
    try appendU32(bytes, allocator, offset);
}

fn encodeStoreAlToArgPtrDisp8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x88);
    try encodeArgPtrDisp8Tail(bytes, allocator, reg, offset);
}

fn encodeStoreAlToArgPtrDisp32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u32) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x88);
    try bytes.append(allocator, 0x80 | @as(u8, reg.lowCode()));
    try appendU32(bytes, allocator, offset);
}

fn encodeStoreAxToArgPtrDisp8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    try bytes.append(allocator, 0x66);
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x89);
    try encodeArgPtrDisp8Tail(bytes, allocator, reg, offset);
}

fn encodeStoreAxToArgPtrDisp32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u32) !void {
    try bytes.append(allocator, 0x66);
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x89);
    try bytes.append(allocator, 0x80 | @as(u8, reg.lowCode()));
    try appendU32(bytes, allocator, offset);
}

fn encodeStoreXmm0ToArgPtrDisp8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    try bytes.append(allocator, 0xf2);
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.appendSlice(allocator, &.{ 0x0f, 0x11 });
    if (offset == 0) {
        try bytes.append(allocator, @as(u8, reg.lowCode()));
    } else {
        try bytes.append(allocator, 0x40 | @as(u8, reg.lowCode()));
        try bytes.append(allocator, offset);
    }
}

fn encodeStoreXmm0ToArgPtrDisp32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u32) !void {
    try bytes.append(allocator, 0xf2);
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.appendSlice(allocator, &.{ 0x0f, 0x11 });
    try bytes.append(allocator, 0x80 | @as(u8, reg.lowCode()));
    try appendU32(bytes, allocator, offset);
}

fn encodeStoreXmm0F32ToArgPtrDisp8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    try bytes.append(allocator, 0xf3);
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.appendSlice(allocator, &.{ 0x0f, 0x11 });
    if (offset == 0) {
        try bytes.append(allocator, @as(u8, reg.lowCode()));
    } else {
        try bytes.append(allocator, 0x40 | @as(u8, reg.lowCode()));
        try bytes.append(allocator, offset);
    }
}

fn encodeStoreXmm0F32ToArgPtrDisp32(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u32) !void {
    try bytes.append(allocator, 0xf3);
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.appendSlice(allocator, &.{ 0x0f, 0x11 });
    try bytes.append(allocator, 0x80 | @as(u8, reg.lowCode()));
    try appendU32(bytes, allocator, offset);
}

fn encodeStoreImm8ArgPtrDisp8(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8, imm: u8) !void {
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0xc6);
    try encodeArgPtrDisp8Tail(bytes, allocator, reg, offset);
    try bytes.append(allocator, imm);
}

fn encodeArgPtrDisp8Tail(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u8) !void {
    if (offset == 0) {
        try bytes.append(allocator, @as(u8, reg.lowCode()));
    } else {
        try bytes.append(allocator, 0x40 | @as(u8, reg.lowCode()));
        try bytes.append(allocator, offset);
    }
}

fn encodeRaxPtrDisp8Tail(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, offset: u8) !void {
    if (offset == 0) {
        try bytes.append(allocator, 0x00);
    } else {
        try bytes.append(allocator, 0x40);
        try bytes.append(allocator, offset);
    }
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

fn encodeCmp16Imm(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, imm: u16) !void {
    try bytes.append(allocator, 0x66);
    if (reg.rexB()) try bytes.append(allocator, 0x41);
    try bytes.append(allocator, 0x81);
    try bytes.append(allocator, 0xf8 | @as(u8, reg.lowCode()));
    try appendU16(bytes, allocator, imm);
}

fn encodeMovapdXmm(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, dst: x86_64.XmmReg, src: x86_64.XmmReg) !void {
    try bytes.appendSlice(allocator, &.{ 0x66, 0x0f, 0x28 });
    try bytes.append(allocator, 0xc0 | (@as(u8, dst.lowCode()) << 3) | @as(u8, src.lowCode()));
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

fn encodeCmpArg32ToR8d(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg) !void {
    var rex: u8 = 0x41;
    if (reg.rexR()) rex |= 0x04;
    try bytes.append(allocator, rex);
    try bytes.append(allocator, 0x39);
    try bytes.append(allocator, 0xc0 | (@as(u8, reg.lowCode()) << 3) | @as(u8, x86_64.ArgReg.r8.lowCode()));
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

fn appendU16(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, value: u16) !void {
    try bytes.append(allocator, @intCast(value & 0xff));
    try bytes.append(allocator, @intCast((value >> 8) & 0xff));
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
