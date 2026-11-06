const std = @import("std");
const ir = @import("../ir.zig");
const x86_64 = @import("../codegen/x86_64.zig");
const selector_bytes = @import("../codegen/x86_64/selector_bytes.zig");
const encoding_helpers = @import("encoding_helpers.zig");
const binaryOpcode = encoding_helpers.binaryOpcode;
const base64Decode4FromTableRaxBytes = encoding_helpers.base64Decode4FromTableRaxBytes;
const base64RawArgsToDecode4RegsBytes = encoding_helpers.base64RawArgsToDecode4RegsBytes;
const encodeRegToEax = encoding_helpers.encodeRegToEax;
const encodeEaxToReg32 = encoding_helpers.encodeEaxToReg32;
const encodeRaxToReg64 = encoding_helpers.encodeRaxToReg64;
const encodeShiftReg32Imm5 = encoding_helpers.encodeShiftReg32Imm5;
const encodeShiftReg64Imm6 = encoding_helpers.encodeShiftReg64Imm6;
const encodeRegToRax64 = encoding_helpers.encodeRegToRax64;
const encodeRegToRax64Binary = encoding_helpers.encodeRegToRax64Binary;
const encodeDivReg64 = encoding_helpers.encodeDivReg64;
const encodeIdivReg64 = encoding_helpers.encodeIdivReg64;
const encodeDivReg32 = encoding_helpers.encodeDivReg32;
const encodeFullMulReg64 = encoding_helpers.encodeFullMulReg64;
const encodeAddHigh32ToEax = encoding_helpers.encodeAddHigh32ToEax;
const encodeRegToReg = encoding_helpers.encodeRegToReg;
const encodeReg64ToReg64 = encoding_helpers.encodeReg64ToReg64;
const encodeRspToReg64 = encoding_helpers.encodeRspToReg64;
const encodeMovsxdReg32ToReg64 = encoding_helpers.encodeMovsxdReg32ToReg64;
const encodeImulReg64Reg64 = encoding_helpers.encodeImulReg64Reg64;
const encodeImulEaxReg32 = encoding_helpers.encodeImulEaxReg32;
const encodeImulReg64Rax = encoding_helpers.encodeImulReg64Rax;
const encodeImulRaxReg64 = encoding_helpers.encodeImulRaxReg64;
const encodeImulRaxFrameSlot = encoding_helpers.encodeImulRaxFrameSlot;
const encodeAddReg64Imm32 = encoding_helpers.encodeAddReg64Imm32;
const encodePushArg = encoding_helpers.encodePushArg;
const encodePopArg = encoding_helpers.encodePopArg;
const encodePushXmm64 = encoding_helpers.encodePushXmm64;
const encodeRegToFrameSlot = encoding_helpers.encodeRegToFrameSlot;
const encodeReg64ToFrameSlot = encoding_helpers.encodeReg64ToFrameSlot;
const encodeFrameSlotToReg = encoding_helpers.encodeFrameSlotToReg;
const encodeFrameSlotToReg64 = encoding_helpers.encodeFrameSlotToReg64;
const encodeFrameSlotToEax = encoding_helpers.encodeFrameSlotToEax;
const encodeEaxToFrameSlot = encoding_helpers.encodeEaxToFrameSlot;
const encodeRaxToFrameSlot = encoding_helpers.encodeRaxToFrameSlot;
const encodeFrameSlotToRax = encoding_helpers.encodeFrameSlotToRax;
const encodeStackDisp8ToArg32 = encoding_helpers.encodeStackDisp8ToArg32;
const encodeStackDisp32ToArg32 = encoding_helpers.encodeStackDisp32ToArg32;
const encodeStackDisp8ToArg64 = encoding_helpers.encodeStackDisp8ToArg64;
const encodeStackDisp32ToArg64 = encoding_helpers.encodeStackDisp32ToArg64;
const encodeStackDisp8U8ToEax = encoding_helpers.encodeStackDisp8U8ToEax;
const encodeStackDisp32U8ToEax = encoding_helpers.encodeStackDisp32U8ToEax;
const encodeStackDisp8U16ToEax = encoding_helpers.encodeStackDisp8U16ToEax;
const encodeStackDisp32U16ToEax = encoding_helpers.encodeStackDisp32U16ToEax;
const encodeXmmFrameSlot = encoding_helpers.encodeXmmFrameSlot;
const frameSlotInstructionSize = encoding_helpers.frameSlotInstructionSize;
const frameSlotInstructionSize64 = encoding_helpers.frameSlotInstructionSize64;
const eaxFrameSlotInstructionSize = encoding_helpers.eaxFrameSlotInstructionSize;
const raxFrameSlotInstructionSize = encoding_helpers.raxFrameSlotInstructionSize;
const imulRaxFrameSlotInstructionSize = encoding_helpers.imulRaxFrameSlotInstructionSize;
const xmmFrameSlotInstructionSize = encoding_helpers.xmmFrameSlotInstructionSize;
const encodeArgPtrToEax = encoding_helpers.encodeArgPtrToEax;
const encodeEaxToArgPtr = encoding_helpers.encodeEaxToArgPtr;
const encodeArgPtrDisp4ToEax = encoding_helpers.encodeArgPtrDisp4ToEax;
const encodeIncArgPtrDisp8 = encoding_helpers.encodeIncArgPtrDisp8;
const encodeArgPtrDisp8ToRax = encoding_helpers.encodeArgPtrDisp8ToRax;
const encodeArgPtrDisp32ToRax = encoding_helpers.encodeArgPtrDisp32ToRax;
const encodeArgPtrDisp8ToEax = encoding_helpers.encodeArgPtrDisp8ToEax;
const encodeArgPtrDisp8U8ToEax = encoding_helpers.encodeArgPtrDisp8U8ToEax;
const encodeArgPtrDisp8U16ToEax = encoding_helpers.encodeArgPtrDisp8U16ToEax;
const encodeArgPtrDisp8U16ToArg = encoding_helpers.encodeArgPtrDisp8U16ToArg;
const encodeArgPtrDisp8ToXmm = encoding_helpers.encodeArgPtrDisp8ToXmm;
const encodePushByvalTailArgPtr = encoding_helpers.encodePushByvalTailArgPtr;
const encodePushByvalTailStackPtr = encoding_helpers.encodePushByvalTailStackPtr;
const pushByvalTailArgPtrSize = encoding_helpers.pushByvalTailArgPtrSize;
const pushByvalTailStackPtrSize = encoding_helpers.pushByvalTailStackPtrSize;
const encodeStoreImm64ArgPtrDisp8 = encoding_helpers.encodeStoreImm64ArgPtrDisp8;
const encodeStoreArg64ToArgPtrDisp8 = encoding_helpers.encodeStoreArg64ToArgPtrDisp8;
const encodeStoreArg64ToArgPtrDisp32 = encoding_helpers.encodeStoreArg64ToArgPtrDisp32;
const encodeStoreRaxToArgPtrDisp8 = encoding_helpers.encodeStoreRaxToArgPtrDisp8;
const encodeStoreRaxToArgPtrDisp32 = encoding_helpers.encodeStoreRaxToArgPtrDisp32;
const encodeStoreEaxToArgPtrDisp8 = encoding_helpers.encodeStoreEaxToArgPtrDisp8;
const encodeStoreEaxToArgPtrDisp32 = encoding_helpers.encodeStoreEaxToArgPtrDisp32;
const encodeStoreAlToArgPtrDisp8 = encoding_helpers.encodeStoreAlToArgPtrDisp8;
const encodeStoreAlToArgPtrDisp32 = encoding_helpers.encodeStoreAlToArgPtrDisp32;
const encodeStoreAxToArgPtrDisp8 = encoding_helpers.encodeStoreAxToArgPtrDisp8;
const encodeStoreAxToArgPtrDisp32 = encoding_helpers.encodeStoreAxToArgPtrDisp32;
const encodeStoreXmm0ToArgPtrDisp8 = encoding_helpers.encodeStoreXmm0ToArgPtrDisp8;
const encodeStoreXmm0ToArgPtrDisp32 = encoding_helpers.encodeStoreXmm0ToArgPtrDisp32;
const encodeStoreXmm0F32ToArgPtrDisp8 = encoding_helpers.encodeStoreXmm0F32ToArgPtrDisp8;
const encodeStoreXmm0F32ToArgPtrDisp32 = encoding_helpers.encodeStoreXmm0F32ToArgPtrDisp32;
const encodeStoreImm8ArgPtrDisp8 = encoding_helpers.encodeStoreImm8ArgPtrDisp8;
const encodeRaxPtrDisp8Tail = encoding_helpers.encodeRaxPtrDisp8Tail;
const encodeF128ArgPtrToXmm0 = encoding_helpers.encodeF128ArgPtrToXmm0;
const encodeF128Xmm0ToArgPtr = encoding_helpers.encodeF128Xmm0ToArgPtr;
const f128ArgPtrInstructionSize = encoding_helpers.f128ArgPtrInstructionSize;
const encodeCmp8Imm = encoding_helpers.encodeCmp8Imm;
const encodeCmp16Imm = encoding_helpers.encodeCmp16Imm;
const encodeMovapdXmm = encoding_helpers.encodeMovapdXmm;
const encodeScalarXmmOp = encoding_helpers.encodeScalarXmmOp;
const encodeCmpRcxToArg64 = encoding_helpers.encodeCmpRcxToArg64;
const encodeCmpEcxToArg32 = encoding_helpers.encodeCmpEcxToArg32;
const encodeCmpArg32ToR8d = encoding_helpers.encodeCmpArg32ToR8d;
const encodeTest8 = encoding_helpers.encodeTest8;
const encodeTest32 = encoding_helpers.encodeTest32;
const encodeTest64 = encoding_helpers.encodeTest64;
const appendI32 = encoding_helpers.appendI32;
const appendU32 = encoding_helpers.appendU32;
const appendU64 = encoding_helpers.appendU64;

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
            .mov_rax_rsi => try bytes.appendSlice(allocator, &.{ 0x48, 0x89, 0xc6 }),
            .mov_arg_rax => |reg| try encodeRegToRax64(&bytes, allocator, reg),
            .movq_xmm_rax => |reg| try bytes.appendSlice(allocator, &.{ 0x66, 0x48, 0x0f, 0x7e, @as(u8, 0xc0) + (@as(u8, reg.lowCode()) << 3) }),
            .movq_rax_xmm => |reg| try bytes.appendSlice(allocator, &.{ 0x66, 0x48, 0x0f, 0x6e, @as(u8, 0xc0) + (@as(u8, reg.lowCode()) << 3) }),
            .movd_xmm_eax => |reg| try bytes.appendSlice(allocator, &.{ 0x66, 0x0f, 0x7e, @as(u8, 0xc0) + (@as(u8, reg.lowCode()) << 3) }),
            .movd_eax_xmm => |reg| try bytes.appendSlice(allocator, &.{ 0x66, 0x0f, 0x6e, @as(u8, 0xc0) + (@as(u8, reg.lowCode()) << 3) }),
            .mov_arg_eax => |reg| try encodeRegToEax(&bytes, allocator, 0x89, reg),
            .mov_eax_to_arg => |reg| try encodeEaxToReg32(&bytes, allocator, reg),
            .mov_rax_to_arg => |reg| try encodeRaxToReg64(&bytes, allocator, reg),
            .mov_arg_arg => |mov| try encodeRegToReg(&bytes, allocator, mov.dst, mov.src),
            .mov_arg64_arg => |mov| try encodeReg64ToReg64(&bytes, allocator, mov.dst, mov.src),
            .mov_rsp_arg64 => |reg| try encodeRspToReg64(&bytes, allocator, reg),
            .movsxd_arg32_arg64 => |mov| try encodeMovsxdReg32ToReg64(&bytes, allocator, mov.dst, mov.src),
            .push_arg => |reg| try encodePushArg(&bytes, allocator, reg),
            .pop_arg => |reg| try encodePopArg(&bytes, allocator, reg),
            .push_rax => try bytes.append(allocator, 0x50),
            .linux_syscall => |count| {
                if (count > 6) return error.UnsupportedCodegenInstruction;
                if (count >= 4) try bytes.appendSlice(allocator, &.{ 0x49, 0x89, 0xca });
                try bytes.appendSlice(allocator, &.{ 0x0f, 0x05 });
            },
            .register_snapshot_rdi => {
                for ([_]u8{ 0, 2, 1, 3, 6, 7, 5, 4, 8, 9, 10, 11, 12, 13, 14, 15 }, 0..) |reg, index| {
                    try bytes.appendSlice(allocator, &.{ @as(u8, 0x48) | (if (reg >= 8) @as(u8, 4) else 0), 0x89, 0x47 | ((reg & 7) << 3), @intCast(index * 8) });
                }
                try bytes.appendSlice(allocator, &.{ 0x48, 0x8d, 0x05, 0, 0, 0, 0, 0x48, 0x89, 0x87, 0x80, 0, 0, 0 });
            },
            .push_xmm64 => |reg| try encodePushXmm64(&bytes, allocator, reg),
            .push_byval_tail_arg_ptr => |copy| try encodePushByvalTailArgPtr(&bytes, allocator, copy.reg, copy.offset, copy.len),
            .push_byval_tail_stack_ptr => |copy| try encodePushByvalTailStackPtr(&bytes, allocator, copy.stack_disp, copy.offset, copy.len),
            .binary_arg_eax => |binary| try encodeRegToEax(&bytes, allocator, binaryOpcode(binary.op), binary.reg),
            .binary_arg_rax => |binary| try encodeRegToRax64Binary(&bytes, allocator, binaryOpcode(binary.op), binary.reg),
            .sbb_arg64_rax => |reg| try encodeRegToRax64Binary(&bytes, allocator, 0x19, reg),
            .adc_rax_imm0 => try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xd0, 0x00 }),
            .imul_eax_arg32 => |src| try encodeImulEaxReg32(&bytes, allocator, src),
            .imul_arg64_arg64 => |imul| try encodeImulReg64Reg64(&bytes, allocator, imul.dst, imul.src),
            .imul_arg64_rax => |dst| try encodeImulReg64Rax(&bytes, allocator, dst),
            .imul_rax_arg64 => |src| try encodeImulRaxReg64(&bytes, allocator, src),
            .imul_rax_rsp => |frame_index| try encodeImulRaxFrameSlot(&bytes, allocator, frame_index),
            .mul_rax_arg64_full => |src| try encodeFullMulReg64(&bytes, allocator, src, false),
            .imul_rax_arg64_full => |src| try encodeFullMulReg64(&bytes, allocator, src, true),
            .xor_edx_edx => try bytes.appendSlice(allocator, &.{ 0x31, 0xd2 }),
            .div_arg32 => |reg| try encodeDivReg32(&bytes, allocator, reg),
            .div_arg64 => |reg| try encodeDivReg64(&bytes, allocator, reg),
            .idiv_arg64 => |reg| try encodeIdivReg64(&bytes, allocator, reg),
            .add_arg64_rax => |reg| try encodeRegToRax64Binary(&bytes, allocator, 0x01, reg),
            .add_arg64_imm32 => |add| try encodeAddReg64Imm32(&bytes, allocator, add.reg, add.imm),
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
            .shr_eax_imm5 => |amount| {
                try bytes.appendSlice(allocator, &.{ 0xc1, 0xe8 });
                try bytes.append(allocator, amount);
            },
            .sar_eax_imm5 => |amount| {
                try bytes.appendSlice(allocator, &.{ 0xc1, 0xf8 });
                try bytes.append(allocator, amount);
            },
            .shr_arg_imm5 => |shift| try encodeShiftReg32Imm5(&bytes, allocator, 5, shift.reg, shift.amount),
            .shr_arg64_imm6 => |shift| try encodeShiftReg64Imm6(&bytes, allocator, 5, shift.reg, shift.amount),
            .sar_arg64_imm6 => |shift| try encodeShiftReg64Imm6(&bytes, allocator, 7, shift.reg, shift.amount),
            .shl_eax_cl => try bytes.appendSlice(allocator, &.{ 0xd3, 0xe0 }),
            .shr_eax_cl => try bytes.appendSlice(allocator, &.{ 0xd3, 0xe8 }),
            .sar_eax_cl => try bytes.appendSlice(allocator, &.{ 0xd3, 0xf8 }),
            .shl_rax_cl => try bytes.appendSlice(allocator, &.{ 0x48, 0xd3, 0xe0 }),
            .shr_rax_cl => try bytes.appendSlice(allocator, &.{ 0x48, 0xd3, 0xe8 }),
            .sar_rax_cl => try bytes.appendSlice(allocator, &.{ 0x48, 0xd3, 0xf8 }),
            .fshl_eax_arg32_imm5 => |shift| {
                if (shift.reg.rexR()) try bytes.append(allocator, 0x44);
                try bytes.appendSlice(allocator, &.{ 0x0f, 0xa4, 0xc0 | (@as(u8, shift.reg.lowCode()) << 3), shift.amount });
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
            .xor_eax_imm32 => |value| {
                try bytes.appendSlice(allocator, &.{0x35});
                try appendI32(&bytes, allocator, value);
            },
            .abs_i32_edi_eax => try bytes.appendSlice(allocator, &.{ 0x89, 0xf8, 0x89, 0xfa, 0xf7, 0xda, 0x85, 0xff, 0x0f, 0x48, 0xc2 }),
            .abs_i64_rdi_rax => try bytes.appendSlice(allocator, &.{ 0x48, 0x89, 0xf8, 0x48, 0x89, 0xfa, 0x48, 0xf7, 0xda, 0x48, 0x85, 0xff, 0x48, 0x0f, 0x48, 0xc2 }),
            .wide_int_to_fp_rdi_rsi_xmm0 => |conversion| try bytes.appendSlice(allocator, switch (conversion.to_bits) {
                32 => if (conversion.signed) &selector_bytes.wide_sitofp_i128_f32 else &selector_bytes.wide_uitofp_i128_f32,
                64 => if (conversion.signed) &selector_bytes.wide_sitofp_i128_f64 else &selector_bytes.wide_uitofp_i128_f64,
                else => return error.InvalidMachineInstruction,
            }),
            .clz_i128_rdi_rsi_eax => try bytes.appendSlice(allocator, &.{
                0x48, 0x85, 0xf6, 0x74, 0x09, 0x48, 0x0f, 0xbd, 0xc6, 0x83, 0xf0, 0x3f, 0xeb, 0x14,
                0xb8, 0x80, 0x00, 0x00, 0x00, 0x48, 0x85, 0xff, 0x74, 0x0a, 0x48, 0x0f, 0xbd, 0xc7,
                0x83, 0xf0, 0x3f, 0x83, 0xc0, 0x40,
            }),
            .clz_i64_rdi_eax => try bytes.appendSlice(allocator, &.{ 0xb8, 0x40, 0x00, 0x00, 0x00, 0x48, 0x85, 0xff, 0x74, 0x07, 0x48, 0x0f, 0xbd, 0xc7, 0x83, 0xf0, 0x3f }),
            .clz_i32_edi_eax => try bytes.appendSlice(allocator, &.{ 0xb8, 0x20, 0x00, 0x00, 0x00, 0x85, 0xff, 0x74, 0x06, 0x0f, 0xbd, 0xc7, 0x83, 0xf0, 0x1f }),
            .ctz_i32_edi_eax => try bytes.appendSlice(allocator, &.{ 0xb8, 0x20, 0x00, 0x00, 0x00, 0x85, 0xff, 0x74, 0x03, 0x0f, 0xbc, 0xc7 }),
            .popcount_i32_edi_eax => try bytes.appendSlice(allocator, &.{
                0x89, 0xf8, // movl %edi, %eax
                0x31, 0xd2, // xorl %edx, %edx
                0x85, 0xc0, // 1: testl %eax, %eax
                0x74, 0x0b, // je 2f
                0x89, 0xc1, // movl %eax, %ecx
                0x83, 0xe9, 0x01, // subl $1, %ecx
                0x21, 0xc8, // andl %ecx, %eax
                0xff, 0xc2, // incl %edx
                0xeb, 0xf1, // jmp 1b
                0x89, 0xd0, // 2: movl %edx, %eax
            }),
            .popcount_rax => try bytes.appendSlice(allocator, &.{
                0x31, 0xd2, // xorl %edx, %edx
                0x48, 0x85, 0xc0, // testq %rax, %rax
                0x74, 0x11, // je 2f
                0x48, 0x89, 0xc1, // 1: movq %rax, %rcx
                0x48, 0x83, 0xe9, 0x01, // subq $1, %rcx
                0x48, 0x21, 0xc8, // andq %rcx, %rax
                0xff, 0xc2, // incl %edx
                0x48, 0x85, 0xc0, // testq %rax, %rax
                0x75, 0xef, // jne 1b
                0x48, 0x89, 0xd0, // 2: movq %rdx, %rax
            }),
            .bit_reverse_i32_edi_eax => try bytes.appendSlice(allocator, &.{
                0x89, 0xf8, 0x0f, 0xc8, 0x89, 0xc2, 0xc1, 0xe8, 0x04, 0x25, 0x0f, 0x0f, 0x0f, 0x0f,
                0x81, 0xe2, 0x0f, 0x0f, 0x0f, 0x0f, 0xc1, 0xe2, 0x04, 0x09, 0xd0, 0x89, 0xc2, 0xc1,
                0xe8, 0x02, 0x25, 0x33, 0x33, 0x33, 0x33, 0x81, 0xe2, 0x33, 0x33, 0x33, 0x33, 0xc1,
                0xe2, 0x02, 0x09, 0xd0, 0x89, 0xc2, 0xd1, 0xe8, 0x25, 0x55, 0x55, 0x55, 0x55, 0x81,
                0xe2, 0x55, 0x55, 0x55, 0x55, 0xd1, 0xe2, 0x09, 0xd0,
            }),
            .bit_reverse_rax => {
                try bytes.appendSlice(allocator, &.{ 0x48, 0x0f, 0xc8 });
                inline for (.{
                    .{ @as(u64, 0x0f0f_0f0f_0f0f_0f0f), @as(u8, 4) },
                    .{ @as(u64, 0x3333_3333_3333_3333), @as(u8, 2) },
                    .{ @as(u64, 0x5555_5555_5555_5555), @as(u8, 1) },
                }) |stage| {
                    try bytes.appendSlice(allocator, &.{ 0x48, 0x89, 0xc2, 0x48, 0xb9 });
                    try appendU64(&bytes, allocator, stage[0]);
                    try bytes.appendSlice(allocator, &.{
                        0x48, 0xc1,     0xe8, stage[1],
                        0x48, 0x21,     0xc8, 0x48,
                        0x21, 0xca,     0x48, 0xc1,
                        0xe2, stage[1], 0x48, 0x09,
                        0xd0,
                    });
                }
            },
            .ushl_sat_i32_edi_imm_eax => |amount| {
                try bytes.appendSlice(allocator, &.{ 0x89, 0xf8, 0xc1, 0xe0, amount, 0x81, 0xff });
                try appendU32(&bytes, allocator, @as(u32, std.math.maxInt(u32)) >> amount);
                try bytes.appendSlice(allocator, &.{ 0xba, 0xff, 0xff, 0xff, 0xff, 0x0f, 0x47, 0xc2 });
            },
            .bswap_eax => try bytes.appendSlice(allocator, &.{ 0x0f, 0xc8 }),
            .bswap_rax => try bytes.appendSlice(allocator, &.{ 0x48, 0x0f, 0xc8 }),
            .rol_ax_imm8 => |amount| try bytes.appendSlice(allocator, &.{ 0x66, 0xc1, 0xc0, amount }),
            .shr_rax_imm6 => |amount| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0xc1, 0xe8 });
                try bytes.append(allocator, amount);
            },
            .shl_rax_imm6 => |amount| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0xc1, 0xe0 });
                try bytes.append(allocator, amount);
            },
            .shl_rdx_imm6 => |amount| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0xc1, 0xe2 });
                try bytes.append(allocator, amount);
            },
            .or_rdx_rax => try bytes.appendSlice(allocator, &.{ 0x48, 0x09, 0xd0 }),
            .neg_rax => try bytes.appendSlice(allocator, &.{ 0x48, 0xf7, 0xd8 }),
            .neg_i128_rdi_rsi_rdx_rax => try bytes.appendSlice(allocator, &.{ 0x48, 0x89, 0xf8, 0x48, 0x89, 0xf2, 0x48, 0xf7, 0xd8, 0x48, 0x83, 0xd2, 0x00, 0x48, 0xf7, 0xda }),
            .ctz_i128_rdi_rsi_eax => try bytes.appendSlice(allocator, &.{
                0xb8, 0x80, 0x00, 0x00, 0x00, 0x48, 0x85, 0xff, 0x75, 0x0e, 0x48, 0x85, 0xf6, 0x74,
                0x0d, 0x48, 0x0f, 0xbc, 0xc6, 0x83, 0xc0, 0x40, 0xeb, 0x04, 0x48, 0x0f, 0xbc, 0xc7,
            }),
            .ctz_i64_rdi_eax => try bytes.appendSlice(allocator, &.{ 0xb8, 0x40, 0x00, 0x00, 0x00, 0x48, 0x85, 0xff, 0x74, 0x04, 0x48, 0x0f, 0xbc, 0xc7 }),
            .ffs_i128_rdi_rsi_eax => try bytes.appendSlice(allocator, &.{
                0x31, 0xc0, 0x48, 0x85, 0xff, 0x75, 0x0e, 0x48, 0x85, 0xf6, 0x74, 0x10, 0x48, 0x0f,
                0xbc, 0xc6, 0x83, 0xc0, 0x41, 0xeb, 0x07, 0x48, 0x0f, 0xbc, 0xc7, 0x83, 0xc0, 0x01,
            }),
            .ffs_i64_rdi_eax => try bytes.appendSlice(allocator, &.{ 0x31, 0xc0, 0x48, 0x85, 0xff, 0x74, 0x07, 0x48, 0x0f, 0xbc, 0xc7, 0x83, 0xc0, 0x01 }),
            .ffs_i32_edi_eax => try bytes.appendSlice(allocator, &.{ 0x31, 0xc0, 0x85, 0xff, 0x74, 0x06, 0x0f, 0xbc, 0xc7, 0x83, 0xc0, 0x01 }),
            .shl_rcx_imm6 => |amount| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0xc1, 0xe1 });
                try bytes.append(allocator, amount);
            },
            .shl_r8_imm6 => |amount| {
                try bytes.appendSlice(allocator, &.{ 0x49, 0xc1, 0xe0 });
                try bytes.append(allocator, amount);
            },
            .or_rcx_rax => try bytes.appendSlice(allocator, &.{ 0x48, 0x09, 0xc8 }),
            .or_rcx_rdx => try bytes.appendSlice(allocator, &.{ 0x48, 0x09, 0xca }),
            .add_rax_imm8 => |value| try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xc0, value }),
            .add_rcx_imm32 => |value| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0x81, 0xc1 });
                try appendI32(&bytes, allocator, value);
            },
            .add_r8_rcx => try bytes.appendSlice(allocator, &.{ 0x4c, 0x01, 0xc1 }),
            .sub_r8_rcx => try bytes.appendSlice(allocator, &.{ 0x4c, 0x29, 0xc1 }),
            .add_ecx_eax => try bytes.appendSlice(allocator, &.{ 0x01, 0xc8 }),
            .xor_ecx_ecx => try bytes.appendSlice(allocator, &.{ 0x31, 0xc9 }),
            .xor_ebp_ebp => try bytes.appendSlice(allocator, &.{ 0x31, 0xed }),
            .add_rdi_rcx4_ptr_eax => try bytes.appendSlice(allocator, &.{ 0x03, 0x04, 0x8f }),
            .load_rdi_rcx4_ptr_r8d => try bytes.appendSlice(allocator, &.{ 0x44, 0x8b, 0x04, 0x8f }),
            .store_eax_rdi_rcx4_ptr => try bytes.appendSlice(allocator, &.{ 0x89, 0x04, 0x8f }),
            .load_rdi_ptr_u8_eax => try bytes.appendSlice(allocator, &.{ 0x0f, 0xb6, 0x07 }),
            .load_rdi_ptr_u16_eax => try bytes.appendSlice(allocator, &.{ 0x0f, 0xb7, 0x07 }),
            .load_rdi_ptr_eax => try bytes.appendSlice(allocator, &.{ 0x8b, 0x07 }),
            .load_rdi_ptr_rax => try bytes.appendSlice(allocator, &.{ 0x48, 0x8b, 0x07 }),
            .atomic_fetch_umin_i8_rdi_sil_eax => try bytes.appendSlice(allocator, &.{
                0x0f, 0xb6, 0x07, // movzbl (%rdi), %eax
                0x89, 0xf1, // movl %esi, %ecx
                0x40, 0x38, 0xf0, // cmpb %sil, %al
                0x77, 0x02, // ja 2f
                0x89, 0xc1, // movl %eax, %ecx
                0xf0, 0x0f, 0xb0, 0x0f, // lock cmpxchgb %cl, (%rdi)
                0x75, 0xf1, // jne 1b
                0x0f, 0xb6, 0xc0, // movzbl %al, %eax
            }),
            .atomic_fetch_umin_i16_rdi_si_eax => try bytes.appendSlice(allocator, &.{
                0x0f, 0xb7, 0x07, // movzwl (%rdi), %eax
                0x89, 0xf1, // movl %esi, %ecx
                0x66, 0x39, 0xf0, // cmpw %si, %ax
                0x77, 0x02, // ja 2f
                0x89, 0xc1, // movl %eax, %ecx
                0xf0, 0x66, 0x0f, 0xb1, 0x0f, // lock cmpxchgw %cx, (%rdi)
                0x75, 0xf0, // jne 1b
                0x0f, 0xb7, 0xc0, // movzwl %ax, %eax
            }),
            .atomic_fetch_umin_i32_rdi_esi_eax => try bytes.appendSlice(allocator, &.{
                0x8b, 0x07, // movl (%rdi), %eax
                0x89, 0xf1, // movl %esi, %ecx
                0x39, 0xf0, // cmpl %esi, %eax
                0x0f, 0x46, 0xc8, // cmovbel %eax, %ecx
                0xf0, 0x0f, 0xb1, 0x0f, // lock cmpxchgl %ecx, (%rdi)
                0x75, 0xf3, // jne 1b
            }),
            .atomic_fetch_umin_i64_rdi_rsi_rax => try bytes.appendSlice(allocator, &.{
                0x48, 0x8b, 0x07, // movq (%rdi), %rax
                0x48, 0x89, 0xf1, // movq %rsi, %rcx
                0x48, 0x39, 0xf0, // cmpq %rsi, %rax
                0x48, 0x0f, 0x46, 0xc8, // cmovbeq %rax, %rcx
                0xf0, 0x48, 0x0f, 0xb1, 0x0f, // lock cmpxchgq %rcx, (%rdi)
                0x75, 0xef, // jne 1b
            }),
            .atomic_fetch_umax_i8_rdi_sil_eax => try bytes.appendSlice(allocator, &.{
                0x0f, 0xb6, 0x07, // movzbl (%rdi), %eax
                0x89, 0xf1, // movl %esi, %ecx
                0x40, 0x38, 0xf0, // cmpb %sil, %al
                0x72, 0x02, // jb 2f
                0x89, 0xc1, // movl %eax, %ecx
                0xf0, 0x0f, 0xb0, 0x0f, // lock cmpxchgb %cl, (%rdi)
                0x75, 0xf1, // jne 1b
                0x0f, 0xb6, 0xc0, // movzbl %al, %eax
            }),
            .atomic_fetch_umax_i16_rdi_si_eax => try bytes.appendSlice(allocator, &.{
                0x0f, 0xb7, 0x07, // movzwl (%rdi), %eax
                0x89, 0xf1, // movl %esi, %ecx
                0x66, 0x39, 0xf0, // cmpw %si, %ax
                0x72, 0x02, // jb 2f
                0x89, 0xc1, // movl %eax, %ecx
                0xf0, 0x66, 0x0f, 0xb1, 0x0f, // lock cmpxchgw %cx, (%rdi)
                0x75, 0xf0, // jne 1b
                0x0f, 0xb7, 0xc0, // movzwl %ax, %eax
            }),
            .atomic_fetch_umax_i32_rdi_esi_eax => try bytes.appendSlice(allocator, &.{
                0x8b, 0x07, // movl (%rdi), %eax
                0x89, 0xf1, // movl %esi, %ecx
                0x39, 0xf0, // cmpl %esi, %eax
                0x0f, 0x43, 0xc8, // cmovael %eax, %ecx
                0xf0, 0x0f, 0xb1, 0x0f, // lock cmpxchgl %ecx, (%rdi)
                0x75, 0xf3, // jne 1b
            }),
            .atomic_fetch_umax_i64_rdi_rsi_rax => try bytes.appendSlice(allocator, &.{
                0x48, 0x8b, 0x07, // movq (%rdi), %rax
                0x48, 0x89, 0xf1, // movq %rsi, %rcx
                0x48, 0x39, 0xf0, // cmpq %rsi, %rax
                0x48, 0x0f, 0x43, 0xc8, // cmovaeq %rax, %rcx
                0xf0, 0x48, 0x0f, 0xb1, 0x0f, // lock cmpxchgq %rcx, (%rdi)
                0x75, 0xef, // jne 1b
            }),
            .atomic_fetch_nand_i8_rdi_sil_eax => try bytes.appendSlice(allocator, &.{
                0x0f, 0xb6, 0x07, // movzbl (%rdi), %eax
                0x89, 0xc1, // movl %eax, %ecx
                0x40, 0x20, 0xf1, // andb %sil, %cl
                0xf6, 0xd1, // notb %cl
                0xf0, 0x0f, 0xb0, 0x0f, // lock cmpxchgb %cl, (%rdi)
                0x75, 0xf3, // jne 1b
                0x0f, 0xb6, 0xc0, // movzbl %al, %eax
            }),
            .atomic_fetch_nand_i16_rdi_si_eax => try bytes.appendSlice(allocator, &.{
                0x0f, 0xb7, 0x07, // movzwl (%rdi), %eax
                0x89, 0xc1, // movl %eax, %ecx
                0x66, 0x21, 0xf1, // andw %si, %cx
                0x66, 0xf7, 0xd1, // notw %cx
                0xf0, 0x66, 0x0f, 0xb1, 0x0f, // lock cmpxchgw %cx, (%rdi)
                0x75, 0xf1, // jne 1b
                0x0f, 0xb7, 0xc0, // movzwl %ax, %eax
            }),
            .atomic_fetch_nand_i32_rdi_esi_eax => try bytes.appendSlice(allocator, &.{
                0x8b, 0x07, // movl (%rdi), %eax
                0x89, 0xc1, // movl %eax, %ecx
                0x21, 0xf1, // andl %esi, %ecx
                0xf7, 0xd1, // notl %ecx
                0xf0, 0x0f, 0xb1, 0x0f, // lock cmpxchgl %ecx, (%rdi)
                0x75, 0xf4, // jne 1b
            }),
            .atomic_fetch_nand_i64_rdi_rsi_rax => try bytes.appendSlice(allocator, &.{
                0x48, 0x8b, 0x07, // movq (%rdi), %rax
                0x48, 0x89, 0xc1, // movq %rax, %rcx
                0x48, 0x21, 0xf1, // andq %rsi, %rcx
                0x48, 0xf7, 0xd1, // notq %rcx
                0xf0, 0x48, 0x0f, 0xb1, 0x0f, // lock cmpxchgq %rcx, (%rdi)
                0x75, 0xf0, // jne 1b
            }),
            .atomic_fetch_xor_i8_rdi_sil_eax => try bytes.appendSlice(allocator, &.{
                0x0f, 0xb6, 0x07, // movzbl (%rdi), %eax
                0x89, 0xc1, // movl %eax, %ecx
                0x40, 0x30, 0xf1, // xorb %sil, %cl
                0xf0, 0x0f, 0xb0, 0x0f, // lock cmpxchgb %cl, (%rdi)
                0x75, 0xf5, // jne 1b
                0x0f, 0xb6, 0xc0, // movzbl %al, %eax
            }),
            .atomic_fetch_xor_i16_rdi_si_eax => try bytes.appendSlice(allocator, &.{
                0x0f, 0xb7, 0x07, // movzwl (%rdi), %eax
                0x89, 0xc1, // movl %eax, %ecx
                0x66, 0x31, 0xf1, // xorw %si, %cx
                0xf0, 0x66, 0x0f, 0xb1, 0x0f, // lock cmpxchgw %cx, (%rdi)
                0x75, 0xf4, // jne 1b
                0x0f, 0xb7, 0xc0, // movzwl %ax, %eax
            }),
            .atomic_fetch_xor_i32_rdi_esi_eax => try bytes.appendSlice(allocator, &.{
                0x8b, 0x07, // movl (%rdi), %eax
                0x89, 0xc1, // movl %eax, %ecx
                0x31, 0xf1, // xorl %esi, %ecx
                0xf0, 0x0f, 0xb1, 0x0f, // lock cmpxchgl %ecx, (%rdi)
                0x75, 0xf6, // jne 1b
            }),
            .atomic_fetch_xor_i64_rdi_rsi_rax => try bytes.appendSlice(allocator, &.{
                0x48, 0x8b, 0x07, // movq (%rdi), %rax
                0x48, 0x89, 0xc1, // movq %rax, %rcx
                0x48, 0x31, 0xf1, // xorq %rsi, %rcx
                0xf0, 0x48, 0x0f, 0xb1, 0x0f, // lock cmpxchgq %rcx, (%rdi)
                0x75, 0xf3, // jne 1b
            }),
            .atomic_fetch_or_i8_rdi_sil_eax => try bytes.appendSlice(allocator, &.{
                0x0f, 0xb6, 0x07, // movzbl (%rdi), %eax
                0x89, 0xc1, // movl %eax, %ecx
                0x40, 0x08, 0xf1, // orb %sil, %cl
                0xf0, 0x0f, 0xb0, 0x0f, // lock cmpxchgb %cl, (%rdi)
                0x75, 0xf5, // jne 1b
                0x0f, 0xb6, 0xc0, // movzbl %al, %eax
            }),
            .atomic_fetch_or_i16_rdi_si_eax => try bytes.appendSlice(allocator, &.{
                0x0f, 0xb7, 0x07, // movzwl (%rdi), %eax
                0x89, 0xc1, // movl %eax, %ecx
                0x66, 0x09, 0xf1, // orw %si, %cx
                0xf0, 0x66, 0x0f, 0xb1, 0x0f, // lock cmpxchgw %cx, (%rdi)
                0x75, 0xf4, // jne 1b
                0x0f, 0xb7, 0xc0, // movzwl %ax, %eax
            }),
            .atomic_fetch_or_i32_rdi_esi_eax => try bytes.appendSlice(allocator, &.{
                0x8b, 0x07, // movl (%rdi), %eax
                0x89, 0xc1, // movl %eax, %ecx
                0x09, 0xf1, // orl %esi, %ecx
                0xf0, 0x0f, 0xb1, 0x0f, // lock cmpxchgl %ecx, (%rdi)
                0x75, 0xf6, // jne 1b
            }),
            .atomic_fetch_or_i64_rdi_rsi_rax => try bytes.appendSlice(allocator, &.{
                0x48, 0x8b, 0x07, // movq (%rdi), %rax
                0x48, 0x89, 0xc1, // movq %rax, %rcx
                0x48, 0x09, 0xf1, // orq %rsi, %rcx
                0xf0, 0x48, 0x0f, 0xb1, 0x0f, // lock cmpxchgq %rcx, (%rdi)
                0x75, 0xf3, // jne 1b
            }),
            .atomic_fetch_and_i8_rdi_sil_eax => try bytes.appendSlice(allocator, &.{
                0x0f, 0xb6, 0x07, // movzbl (%rdi), %eax
                0x89, 0xc1, // movl %eax, %ecx
                0x40, 0x20, 0xf1, // andb %sil, %cl
                0xf0, 0x0f, 0xb0, 0x0f, // lock cmpxchgb %cl, (%rdi)
                0x75, 0xf5, // jne 1b
                0x0f, 0xb6, 0xc0, // movzbl %al, %eax
            }),
            .atomic_fetch_and_i16_rdi_si_eax => try bytes.appendSlice(allocator, &.{
                0x0f, 0xb7, 0x07, // movzwl (%rdi), %eax
                0x89, 0xc1, // movl %eax, %ecx
                0x66, 0x21, 0xf1, // andw %si, %cx
                0xf0, 0x66, 0x0f, 0xb1, 0x0f, // lock cmpxchgw %cx, (%rdi)
                0x75, 0xf4, // jne 1b
                0x0f, 0xb7, 0xc0, // movzwl %ax, %eax
            }),
            .atomic_fetch_and_i32_rdi_esi_eax => try bytes.appendSlice(allocator, &.{
                0x8b, 0x07, // movl (%rdi), %eax
                0x89, 0xc1, // movl %eax, %ecx
                0x21, 0xf1, // andl %esi, %ecx
                0xf0, 0x0f, 0xb1, 0x0f, // lock cmpxchgl %ecx, (%rdi)
                0x75, 0xf6, // jne 1b
            }),
            .atomic_fetch_and_i64_rdi_rsi_rax => try bytes.appendSlice(allocator, &.{
                0x48, 0x8b, 0x07, // movq (%rdi), %rax
                0x48, 0x89, 0xc1, // movq %rax, %rcx
                0x48, 0x21, 0xf1, // andq %rsi, %rcx
                0xf0, 0x48, 0x0f, 0xb1, 0x0f, // lock cmpxchgq %rcx, (%rdi)
                0x75, 0xf3, // jne 1b
            }),
            .atomic_fetch_sub_i8_rdi_sil_eax => try bytes.appendSlice(allocator, &.{
                0x0f, 0xb6, 0x07, // movzbl (%rdi), %eax
                0x89, 0xc1, // movl %eax, %ecx
                0x40, 0x28, 0xf1, // subb %sil, %cl
                0xf0, 0x0f, 0xb0, 0x0f, // lock cmpxchgb %cl, (%rdi)
                0x75, 0xf5, // jne 1b
                0x0f, 0xb6, 0xc0, // movzbl %al, %eax
            }),
            .atomic_fetch_sub_i16_rdi_si_eax => try bytes.appendSlice(allocator, &.{
                0x0f, 0xb7, 0x07, // movzwl (%rdi), %eax
                0x89, 0xc1, // movl %eax, %ecx
                0x66, 0x29, 0xf1, // subw %si, %cx
                0xf0, 0x66, 0x0f, 0xb1, 0x0f, // lock cmpxchgw %cx, (%rdi)
                0x75, 0xf4, // jne 1b
                0x0f, 0xb7, 0xc0, // movzwl %ax, %eax
            }),
            .atomic_fetch_sub_i32_rdi_esi_eax => try bytes.appendSlice(allocator, &.{
                0x8b, 0x07, // movl (%rdi), %eax
                0x89, 0xc1, // movl %eax, %ecx
                0x29, 0xf1, // subl %esi, %ecx
                0xf0, 0x0f, 0xb1, 0x0f, // lock cmpxchgl %ecx, (%rdi)
                0x75, 0xf6, // jne 1b
            }),
            .atomic_fetch_sub_i64_rdi_rsi_rax => try bytes.appendSlice(allocator, &.{
                0x48, 0x8b, 0x07, // movq (%rdi), %rax
                0x48, 0x89, 0xc1, // movq %rax, %rcx
                0x48, 0x29, 0xf1, // subq %rsi, %rcx
                0xf0, 0x48, 0x0f, 0xb1, 0x0f, // lock cmpxchgq %rcx, (%rdi)
                0x75, 0xf3, // jne 1b
            }),
            .atomic_fetch_add_i8_rdi_sil_eax => try bytes.appendSlice(allocator, &.{
                0x0f, 0xb6, 0x07, // movzbl (%rdi), %eax
                0x89, 0xc1, // movl %eax, %ecx
                0x40, 0x00, 0xf1, // addb %sil, %cl
                0xf0, 0x0f, 0xb0, 0x0f, // lock cmpxchgb %cl, (%rdi)
                0x75, 0xf5, // jne 1b
                0x0f, 0xb6, 0xc0, // movzbl %al, %eax
            }),
            .atomic_fetch_add_i16_rdi_si_eax => try bytes.appendSlice(allocator, &.{
                0x0f, 0xb7, 0x07, // movzwl (%rdi), %eax
                0x89, 0xc1, // movl %eax, %ecx
                0x66, 0x01, 0xf1, // addw %si, %cx
                0xf0, 0x66, 0x0f, 0xb1, 0x0f, // lock cmpxchgw %cx, (%rdi)
                0x75, 0xf4, // jne 1b
                0x0f, 0xb7, 0xc0, // movzwl %ax, %eax
            }),
            .atomic_fetch_add_i32_rdi_esi_eax => try bytes.appendSlice(allocator, &.{
                0x8b, 0x07, // movl (%rdi), %eax
                0x89, 0xc1, // movl %eax, %ecx
                0x01, 0xf1, // addl %esi, %ecx
                0xf0, 0x0f, 0xb1, 0x0f, // lock cmpxchgl %ecx, (%rdi)
                0x75, 0xf6, // jne 1b
            }),
            .atomic_fetch_add_i64_rdi_rsi_rax => try bytes.appendSlice(allocator, &.{
                0x48, 0x8b, 0x07, // movq (%rdi), %rax
                0x48, 0x89, 0xc1, // movq %rax, %rcx
                0x48, 0x01, 0xf1, // addq %rsi, %rcx
                0xf0, 0x48, 0x0f, 0xb1, 0x0f, // lock cmpxchgq %rcx, (%rdi)
                0x75, 0xf3, // jne 1b
            }),
            .load_rcx_ptr_u8_eax => try bytes.appendSlice(allocator, &.{ 0x0f, 0xb6, 0x01 }),
            .load_rcx_ptr_u16_eax => try bytes.appendSlice(allocator, &.{ 0x0f, 0xb7, 0x01 }),
            .load_rcx_ptr_eax => try bytes.appendSlice(allocator, &.{ 0x8b, 0x01 }),
            .load_rcx_ptr_rax => try bytes.appendSlice(allocator, &.{ 0x48, 0x8b, 0x01 }),
            .store_al_rcx_ptr => try bytes.appendSlice(allocator, &.{ 0x88, 0x01 }),
            .store_ax_rcx_ptr => try bytes.appendSlice(allocator, &.{ 0x66, 0x89, 0x01 }),
            .store_eax_rcx_ptr => try bytes.appendSlice(allocator, &.{ 0x89, 0x01 }),
            .store_rax_rcx_ptr => try bytes.appendSlice(allocator, &.{ 0x48, 0x89, 0x01 }),
            .cmp_r8d_arg32 => |reg| try encodeCmpArg32ToR8d(&bytes, allocator, reg),
            .add_r8d_eax => try bytes.appendSlice(allocator, &.{ 0x44, 0x01, 0xc0 }),
            .inc_rcx => try bytes.appendSlice(allocator, &.{ 0x48, 0xff, 0xc1 }),
            .movzx_dil_edi => try bytes.appendSlice(allocator, &.{ 0x40, 0x0f, 0xb6, 0xff }),
            .and_edi_imm8 => |value| try bytes.appendSlice(allocator, &.{ 0x83, 0xe7, value }),
            .load_rax_rdi_u8_eax => try bytes.appendSlice(allocator, &.{ 0x0f, 0xb6, 0x04, 0x38 }),
            .bcmp_rdi_rsi_rdx_eax => try bytes.appendSlice(allocator, &.{
                0x48, 0x85, 0xd2, // testq %rdx, %rdx
                0x74, 0x13, // je 2f
                0x31, 0xc9, // xorl %ecx, %ecx
                0x0f, 0xb6, 0x04, 0x0f, // movzbl (%rdi,%rcx), %eax
                0x3a, 0x04, 0x0e, // cmpb (%rsi,%rcx), %al
                0x75, 0x0c, // jne 3f
                0x48, 0xff, 0xc1, // incq %rcx
                0x48, 0x39, 0xca, // cmpq %rcx, %rdx
                0x75, 0xef, // jne 1b
                0x31, 0xc0, // xorl %eax, %eax
                0xeb, 0x05, // jmp 4f
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
            }),
            .memcmp_rdi_rsi_rdx_eax => try bytes.appendSlice(allocator, &.{
                0x48, 0x85, 0xd2, // testq %rdx, %rdx
                0x74, 0x18, // je 2f
                0x31, 0xc9, // xorl %ecx, %ecx
                0x0f, 0xb6, 0x04, 0x0f, // movzbl (%rdi,%rcx), %eax
                0x44, 0x0f, 0xb6, 0x04, 0x0e, // movzbl (%rsi,%rcx), %r8d
                0x44, 0x38, 0xc0, // cmpb %r8b, %al
                0x75, 0x0c, // jne 3f
                0x48, 0xff, 0xc1, // incq %rcx
                0x48, 0x39, 0xca, // cmpq %rcx, %rdx
                0x75, 0xea, // jne 1b
                0x31, 0xc0, // xorl %eax, %eax
                0xeb, 0x03, // jmp 4f
                0x44, 0x29, 0xc0, // subl %r8d, %eax
            }),
            .memcpy_rdi_rsi_rdx_rax => try bytes.appendSlice(allocator, &.{
                0x48, 0x89, 0xf8, // movq %rdi, %rax
                0x48, 0x85, 0xd2, // testq %rdx, %rdx
                0x74, 0x06, // je 2f
                0xfc, // cld
                0x48, 0x89, 0xd1, // movq %rdx, %rcx
                0xf3, 0xa4, // rep movsb
            }),
            .abs_limb64_rdi_rsi_dx_rcx_rax => try bytes.appendSlice(allocator, &.{
                0x0f, 0xb7, 0xd2, // movzwl %dx, %edx
                0x83, 0xc2, 0x3f, // addl $63, %edx
                0xc1, 0xea, 0x06, // shrl $6, %edx
                0x85, 0xd2, // testl %edx, %edx
                0x74, 0x38, // je 3f
                0x89, 0xd1, // movl %edx, %ecx
                0x48, 0x8b, 0x44, 0xce, 0xf8, // movq -8(%rsi,%rcx,8), %rax
                0x48, 0x85, 0xc0, // testq %rax, %rax
                0x78, 0x06, // js 1f
                0xfc, // cld
                0xf3, 0x48, 0xa5, // rep movsq
                0xeb, 0x26, // jmp 3f
                0x31, 0xc9, // xorl %ecx, %ecx
                0x41, 0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %r8d
                0x48, 0x8b, 0x04, 0xce, // movq (%rsi,%rcx,8), %rax
                0x48, 0xf7, 0xd0, // notq %rax
                0x45, 0x0f, 0xb6, 0xc0, // movzbl %r8b, %r8d
                0x4c, 0x01, 0xc0, // addq %r8, %rax
                0x41, 0x0f, 0x92, 0xc0, // setc %r8b
                0x48, 0x89, 0x04, 0xcf, // movq %rax, (%rdi,%rcx,8)
                0x48, 0xff, 0xc1, // incq %rcx
                0x48, 0x39, 0xd1, // cmpq %rdx, %rcx
                0x75, 0xe2, // jne 2b
            }),
            .mulo_limb64_rdi_rsi_rdx_cl_r8w_al => try bytes.appendSlice(allocator, &selector_bytes.mulo_limb64_rdi_rsi_rdx_cl_r8w_al),
            .byteswap_limb64_rdi_rsi_dl_cx => try bytes.appendSlice(allocator, &selector_bytes.byteswap_limb64_rdi_rsi_dl_cx),
            .shr_limb64_rdi_rsi_dx_cl_r8w => try bytes.appendSlice(allocator, &selector_bytes.shr_limb64_rdi_rsi_dx_cl_r8w),
            .shlo_limb64_rdi_rsi_dx_cl_r8w_al => try bytes.appendSlice(allocator, &selector_bytes.shlo_limb64_rdi_rsi_dx_cl_r8w_al),
            .not_limb64_rdi_rsi_dl_cx => try bytes.appendSlice(allocator, &selector_bytes.not_limb64_rdi_rsi_dl_cx),
            .bitwise_limb64_rdi_rsi_rdx_cx => |op| switch (op) {
                .xor => try bytes.appendSlice(allocator, &selector_bytes.xor_limb64_rdi_rsi_rdx_cx),
                .@"or" => try bytes.appendSlice(allocator, &selector_bytes.or_limb64_rdi_rsi_rdx_cx),
                .@"and" => try bytes.appendSlice(allocator, &selector_bytes.and_limb64_rdi_rsi_rdx_cx),
            },
            .cmp_limb64_rdi_rsi_dl_cx_ax => try bytes.appendSlice(allocator, &selector_bytes.cmp_limb64_rdi_rsi_dl_cx_ax),
            .overflow_limb64_rdi_rsi_rdx_cl_r8w_al => |op| switch (op) {
                .add => try bytes.appendSlice(allocator, &selector_bytes.addo_limb64_rdi_rsi_rdx_cl_r8w_al),
                .sub => try bytes.appendSlice(allocator, &selector_bytes.subo_limb64_rdi_rsi_rdx_cl_r8w_al),
            },
            .bitreverse_limb64_rdi_rsi_dl_cx => try bytes.appendSlice(allocator, &selector_bytes.bitreverse_limb64_rdi_rsi_dl_cx),
            .popcount_limb64_rdi_si_ax => try bytes.appendSlice(allocator, &selector_bytes.popcount_limb64_rdi_si_ax),
            .ctz_limb64_rdi_si_ax => try bytes.appendSlice(allocator, &selector_bytes.ctz_limb64_rdi_si_ax),
            .clz_limb64_rdi_si_ax => try bytes.appendSlice(allocator, &selector_bytes.clz_limb64_rdi_si_ax),
            .udivei4_before_intbytesize => try bytes.appendSlice(allocator, &selector_bytes.udivei4_before_intbytesize),
            .udivei4_between_intbytesize_and_memset => try bytes.appendSlice(allocator, &selector_bytes.udivei4_between_intbytesize_and_memset),
            .udivei4_after_memset => try bytes.appendSlice(allocator, &selector_bytes.udivei4_after_memset),
            .umodei5_before_intbytesize => try bytes.appendSlice(allocator, &selector_bytes.umodei5_before_intbytesize),
            .umodei5_between_intbytesize_and_memset => try bytes.appendSlice(allocator, &selector_bytes.umodei5_between_intbytesize_and_memset),
            .umodei5_after_memset_before_memcpy => try bytes.appendSlice(allocator, &selector_bytes.umodei5_after_memset_before_memcpy),
            .umodei5_after_memcpy => try bytes.appendSlice(allocator, &selector_bytes.umodei5_after_memcpy),
            .spinlocked_memcpy_rsi_to_rdx_len_edi => try bytes.appendSlice(allocator, &.{
                0x48, 0x89, 0xf0, // movq %rsi, %rax
                0x48, 0xc1, 0xe8, 0x03, // shrq $3, %rax
                0x48, 0x83, 0xe0, 0x3f, // andq $63, %rax
                0x4c, 0x8d, 0x05, 0, 0, 0, 0, // leaq spinlocks(%rip), %r8
                0x4d, 0x8d, 0x04, 0x00, // leaq (%r8,%rax), %r8
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x49, 0x87, 0x00, // xchgq %rax, (%r8)
                0x48, 0x85, 0xc0, // testq %rax, %rax
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x75, 0xf3, // jne 1b
                0x85, 0xff, // testl %edi, %edi
                0x74, 0x08, // je 2f
                0xfc, // cld
                0x89, 0xf9, // movl %edi, %ecx
                0x48, 0x89, 0xd7, // movq %rdx, %rdi
                0xf3, 0xa4, // rep movsb
                0x49, 0xc7, 0x00, 0, 0, 0, 0, // movq $0, (%r8)
            }),
            .spinlocked_var_cmpxchg_edi_rsi_rdx_rcx_eax => try bytes.appendSlice(allocator, &.{
                0x48, 0x89, 0xf0, // movq %rsi, %rax
                0x48, 0xc1, 0xe8, 0x03, // shrq $3, %rax
                0x48, 0x83, 0xe0, 0x3f, // andq $63, %rax
                0x4c, 0x8d, 0x05, 0, 0, 0, 0, // leaq spinlocks(%rip), %r8
                0x4d, 0x8d, 0x04, 0x00, // leaq (%r8,%rax), %r8
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x49, 0x87, 0x00, // xchgq %rax, (%r8)
                0x48, 0x85, 0xc0, // testq %rax, %rax
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x75, 0xf3, // jne 1b
                0x85, 0xff, // testl %edi, %edi
                0x74, 0x16, // je 4f
                0x45, 0x31, 0xc9, // xorl %r9d, %r9d
                0x42, 0x0f, 0xb6, 0x04, 0x0e, // movzbl (%rsi,%r9), %eax
                0x42, 0x3a, 0x04, 0x0a, // cmpb (%rdx,%r9), %al
                0x75, 0x1d, // jne 5f
                0x49, 0xff, 0xc1, // incq %r9
                0x4c, 0x39, 0xcf, // cmpq %r9, %rdi
                0x75, 0xed, // jne 2b
                0x49, 0x89, 0xca, // movq %rcx, %r10
                0x89, 0xf9, // movl %edi, %ecx
                0x48, 0x89, 0xf7, // movq %rsi, %rdi
                0x4c, 0x89, 0xd6, // movq %r10, %rsi
                0xfc, // cld
                0xf3, 0xa4, // rep movsb
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0xeb, 0x0a, // jmp 6f
                0x89, 0xf9, // movl %edi, %ecx
                0x48, 0x89, 0xd7, // movq %rdx, %rdi
                0xfc, // cld
                0xf3, 0xa4, // rep movsb
                0x31, 0xc0, // xorl %eax, %eax
                0x49, 0xc7, 0x00, 0, 0, 0, 0, // movq $0, (%r8)
            }),
            .spinlocked_var_xchg_edi_rsi_rdx_rcx => try bytes.appendSlice(allocator, &.{
                0x48, 0x89, 0xf0, // movq %rsi, %rax
                0x48, 0xc1, 0xe8, 0x03, // shrq $3, %rax
                0x48, 0x83, 0xe0, 0x3f, // andq $63, %rax
                0x4c, 0x8d, 0x05, 0, 0, 0, 0, // leaq spinlocks(%rip), %r8
                0x4d, 0x8d, 0x04, 0x00, // leaq (%r8,%rax), %r8
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x49, 0x87, 0x00, // xchgq %rax, (%r8)
                0x48, 0x85, 0xc0, // testq %rax, %rax
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x75, 0xf3, // jne 1b
                0x85, 0xff, // testl %edi, %edi
                0x74, 0x1e, // je 2f
                0x49, 0x89, 0xc9, // movq %rcx, %r9
                0x49, 0x89, 0xf2, // movq %rsi, %r10
                0x49, 0x89, 0xd3, // movq %rdx, %r11
                0xfc, // cld
                0x89, 0xf9, // movl %edi, %ecx
                0x4c, 0x89, 0xcf, // movq %r9, %rdi
                0x4c, 0x89, 0xd6, // movq %r10, %rsi
                0xf3, 0xa4, // rep movsb
                0x89, 0xf9, // movl %edi, %ecx
                0x4c, 0x89, 0xd7, // movq %r10, %rdi
                0x4c, 0x89, 0xde, // movq %r11, %rsi
                0xf3, 0xa4, // rep movsb
                0x49, 0xc7, 0x00, 0, 0, 0, 0, // movq $0, (%r8)
            }),
            .spinlocked_var_store_edi_rsi_rdx => try bytes.appendSlice(allocator, &.{
                0x48, 0x89, 0xf0, // movq %rsi, %rax
                0x48, 0xc1, 0xe8, 0x03, // shrq $3, %rax
                0x48, 0x83, 0xe0, 0x3f, // andq $63, %rax
                0x4c, 0x8d, 0x05, 0, 0, 0, 0, // leaq spinlocks(%rip), %r8
                0x4d, 0x8d, 0x04, 0x00, // leaq (%r8,%rax), %r8
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x49, 0x87, 0x00, // xchgq %rax, (%r8)
                0x48, 0x85, 0xc0, // testq %rax, %rax
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x75, 0xf3, // jne 1b
                0x85, 0xff, // testl %edi, %edi
                0x74, 0x11, // je 2f
                0x49, 0x89, 0xf1, // movq %rsi, %r9
                0x49, 0x89, 0xd2, // movq %rdx, %r10
                0xfc, // cld
                0x89, 0xf9, // movl %edi, %ecx
                0x4c, 0x89, 0xcf, // movq %r9, %rdi
                0x4c, 0x89, 0xd6, // movq %r10, %rsi
                0xf3, 0xa4, // rep movsb
                0x49, 0xc7, 0x00, 0, 0, 0, 0, // movq $0, (%r8)
            }),
            .cmpxchg_ptr_expected_desired_i8_eax => try bytes.appendSlice(allocator, &.{
                0x8a, 0x06, // movb (%rsi), %al
                0xf0, 0x0f, 0xb0, 0x17, // lock cmpxchgb %dl, (%rdi)
                0x75, 0x07, // jne 1f
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0xeb, 0x04, // jmp 2f
                0x88, 0x06, // movb %al, (%rsi)
                0x31, 0xc0, // xorl %eax, %eax
            }),
            .cmpxchg_ptr_expected_desired_i16_eax => try bytes.appendSlice(allocator, &.{
                0x66, 0x8b, 0x06, // movw (%rsi), %ax
                0xf0, 0x66, 0x0f, 0xb1, 0x17, // lock cmpxchgw %dx, (%rdi)
                0x75, 0x07, // jne 1f
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0xeb, 0x05, // jmp 2f
                0x66, 0x89, 0x06, // movw %ax, (%rsi)
                0x31, 0xc0, // xorl %eax, %eax
            }),
            .cmpxchg_ptr_expected_desired_i32_eax => try bytes.appendSlice(allocator, &.{
                0x8b, 0x06, // movl (%rsi), %eax
                0xf0, 0x0f, 0xb1, 0x17, // lock cmpxchgl %edx, (%rdi)
                0x75, 0x07, // jne 1f
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0xeb, 0x04, // jmp 2f
                0x89, 0x06, // movl %eax, (%rsi)
                0x31, 0xc0, // xorl %eax, %eax
            }),
            .cmpxchg_ptr_expected_desired_i64_eax => try bytes.appendSlice(allocator, &.{
                0x48, 0x8b, 0x06, // movq (%rsi), %rax
                0xf0, 0x48, 0x0f, 0xb1, 0x17, // lock cmpxchgq %rdx, (%rdi)
                0x75, 0x07, // jne 1f
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0xeb, 0x05, // jmp 2f
                0x48, 0x89, 0x06, // movq %rax, (%rsi)
                0x31, 0xc0, // xorl %eax, %eax
            }),
            .spinlocked_cmpxchg_i128_rdi_rsi_rdx_rcx_eax => try bytes.appendSlice(allocator, &.{
                0x48, 0x89, 0xf8, // movq %rdi, %rax
                0x48, 0xc1, 0xe8, 0x03, // shrq $3, %rax
                0x48, 0x83, 0xe0, 0x3e, // andq $62, %rax
                0x4c, 0x8d, 0x05, 0, 0, 0, 0, // leaq spinlocks(%rip), %r8
                0x4d, 0x8d, 0x04, 0x00, // leaq (%r8,%rax), %r8
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x49, 0x87, 0x00, // xchgq %rax, (%r8)
                0x48, 0x85, 0xc0, // testq %rax, %rax
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x75, 0xf3, // jne 1b
                0x48, 0x8b, 0x07, // movq (%rdi), %rax
                0x4c, 0x8b, 0x57, 0x08, // movq 8(%rdi), %r10
                0x48, 0x3b, 0x06, // cmpq (%rsi), %rax
                0x75, 0x14, // jne 2f
                0x4c, 0x3b, 0x56, 0x08, // cmpq 8(%rsi), %r10
                0x75, 0x0e, // jne 2f
                0x48, 0x89, 0x17, // movq %rdx, (%rdi)
                0x48, 0x89, 0x4f, 0x08, // movq %rcx, 8(%rdi)
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0xeb, 0x09, // jmp 3f
                0x48, 0x89, 0x06, // movq %rax, (%rsi)
                0x4c, 0x89, 0x56, 0x08, // movq %r10, 8(%rsi)
                0x31, 0xc0, // xorl %eax, %eax
                0x49, 0xc7, 0x00, 0, 0, 0, 0, // movq $0, (%r8)
            }),
            .xchg_ptr_value_i8_eax => try bytes.appendSlice(allocator, &.{
                0x40, 0x88, 0xf0, // movb %sil, %al
                0x86, 0x07, // xchgb %al, (%rdi)
                0x0f, 0xb6, 0xc0, // movzbl %al, %eax
            }),
            .xchg_ptr_value_i16_eax => try bytes.appendSlice(allocator, &.{
                0x66, 0x89, 0xf0, // movw %si, %ax
                0x66, 0x87, 0x07, // xchgw %ax, (%rdi)
                0x0f, 0xb7, 0xc0, // movzwl %ax, %eax
            }),
            .xchg_ptr_value_i32_eax => try bytes.appendSlice(allocator, &.{
                0x89, 0xf0, // movl %esi, %eax
                0x87, 0x07, // xchgl %eax, (%rdi)
            }),
            .xchg_ptr_value_i64_rax => try bytes.appendSlice(allocator, &.{
                0x48, 0x89, 0xf0, // movq %rsi, %rax
                0x48, 0x87, 0x07, // xchgq %rax, (%rdi)
            }),
            .atomic_xchg_rdi_disp8_rax => |disp| try bytes.appendSlice(allocator, &.{
                0x48, 0x87, 0x47, @bitCast(disp),
            }),
            .spinlocked_xchg_i128_rdi_rsi_rdx_rax => try bytes.appendSlice(allocator, &.{
                0x49, 0x89, 0xd1, // movq %rdx, %r9
                0x49, 0x89, 0xf8, // movq %rdi, %r8
                0x49, 0xc1, 0xe8, 0x03, // shrq $3, %r8
                0x49, 0x83, 0xe0, 0x3e, // andq $62, %r8
                0x4c, 0x8d, 0x15, 0, 0, 0, 0, // leaq spinlocks(%rip), %r10
                0x4d, 0x01, 0xc2, // addq %r8, %r10
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x49, 0x87, 0x02, // xchgq %rax, (%r10)
                0x48, 0x85, 0xc0, // testq %rax, %rax
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x75, 0xf3, // jne 1b
                0x48, 0x8b, 0x07, // movq (%rdi), %rax
                0x48, 0x8b, 0x4f, 0x08, // movq 8(%rdi), %rcx
                0x48, 0x89, 0x37, // movq %rsi, (%rdi)
                0x4c, 0x89, 0x4f, 0x08, // movq %r9, 8(%rdi)
                0x49, 0xc7, 0x02, 0, 0, 0, 0, // movq $0, (%r10)
                0x48, 0x89, 0xca, // movq %rcx, %rdx
            }),
            .spinlocked_store_i128_rdi_rsi_rdx => try bytes.appendSlice(allocator, &.{
                0x49, 0x89, 0xd1, // movq %rdx, %r9
                0x49, 0x89, 0xf8, // movq %rdi, %r8
                0x49, 0xc1, 0xe8, 0x03, // shrq $3, %r8
                0x49, 0x83, 0xe0, 0x3e, // andq $62, %r8
                0x4c, 0x8d, 0x15, 0, 0, 0, 0, // leaq spinlocks(%rip), %r10
                0x4d, 0x01, 0xc2, // addq %r8, %r10
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x49, 0x87, 0x02, // xchgq %rax, (%r10)
                0x48, 0x85, 0xc0, // testq %rax, %rax
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x75, 0xf3, // jne 1b
                0x48, 0x89, 0x37, // movq %rsi, (%rdi)
                0x4c, 0x89, 0x4f, 0x08, // movq %r9, 8(%rdi)
                0x49, 0xc7, 0x02, 0, 0, 0, 0, // movq $0, (%r10)
            }),
            .spinlocked_load_i128_rdi_rax_rdx => try bytes.appendSlice(allocator, &.{
                0x49, 0x89, 0xf8, // movq %rdi, %r8
                0x49, 0xc1, 0xe8, 0x03, // shrq $3, %r8
                0x49, 0x83, 0xe0, 0x3e, // andq $62, %r8
                0x4c, 0x8d, 0x15, 0, 0, 0, 0, // leaq spinlocks(%rip), %r10
                0x4d, 0x01, 0xc2, // addq %r8, %r10
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x49, 0x87, 0x02, // xchgq %rax, (%r10)
                0x48, 0x85, 0xc0, // testq %rax, %rax
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x75, 0xf3, // jne 1b
                0x48, 0x8b, 0x07, // movq (%rdi), %rax
                0x48, 0x8b, 0x57, 0x08, // movq 8(%rdi), %rdx
                0x49, 0xc7, 0x02, 0, 0, 0, 0, // movq $0, (%r10)
            }),
            .spinlocked_fetch_umin_i128_rdi_rsi_rdx_rax_rdx => try bytes.appendSlice(allocator, &.{
                0x49, 0x89, 0xd1, // movq %rdx, %r9
                0x49, 0x89, 0xf8, // movq %rdi, %r8
                0x49, 0xc1, 0xe8, 0x03, // shrq $3, %r8
                0x49, 0x83, 0xe0, 0x3e, // andq $62, %r8
                0x4c, 0x8d, 0x15, 0, 0, 0, 0, // leaq spinlocks(%rip), %r10
                0x4d, 0x01, 0xc2, // addq %r8, %r10
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x49, 0x87, 0x02, // xchgq %rax, (%r10)
                0x48, 0x85, 0xc0, // testq %rax, %rax
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x75, 0xf3, // jne 1b
                0x48, 0x8b, 0x07, // movq (%rdi), %rax
                0x48, 0x8b, 0x57, 0x08, // movq 8(%rdi), %rdx
                0x4c, 0x39, 0xca, // cmpq %r9, %rdx
                0x72, 0x0e, // jb 2f
                0x77, 0x05, // ja 3f
                0x48, 0x39, 0xf0, // cmpq %rsi, %rax
                0x76, 0x07, // jbe 2f
                0x48, 0x89, 0x37, // movq %rsi, (%rdi)
                0x4c, 0x89, 0x4f, 0x08, // movq %r9, 8(%rdi)
                0x49, 0xc7, 0x02, 0, 0, 0, 0, // movq $0, (%r10)
            }),
            .spinlocked_fetch_umax_i128_rdi_rsi_rdx_rax_rdx => try bytes.appendSlice(allocator, &.{
                0x49, 0x89, 0xd1, // movq %rdx, %r9
                0x49, 0x89, 0xf8, // movq %rdi, %r8
                0x49, 0xc1, 0xe8, 0x03, // shrq $3, %r8
                0x49, 0x83, 0xe0, 0x3e, // andq $62, %r8
                0x4c, 0x8d, 0x15, 0, 0, 0, 0, // leaq spinlocks(%rip), %r10
                0x4d, 0x01, 0xc2, // addq %r8, %r10
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x49, 0x87, 0x02, // xchgq %rax, (%r10)
                0x48, 0x85, 0xc0, // testq %rax, %rax
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x75, 0xf3, // jne 1b
                0x48, 0x8b, 0x07, // movq (%rdi), %rax
                0x48, 0x8b, 0x57, 0x08, // movq 8(%rdi), %rdx
                0x4c, 0x39, 0xca, // cmpq %r9, %rdx
                0x77, 0x0e, // ja 2f
                0x72, 0x05, // jb 3f
                0x48, 0x39, 0xf0, // cmpq %rsi, %rax
                0x73, 0x07, // jae 2f
                0x48, 0x89, 0x37, // movq %rsi, (%rdi)
                0x4c, 0x89, 0x4f, 0x08, // movq %r9, 8(%rdi)
                0x49, 0xc7, 0x02, 0, 0, 0, 0, // movq $0, (%r10)
            }),
            .spinlocked_fetch_nand_i128_rdi_rsi_rdx_rax_rdx => try bytes.appendSlice(allocator, &.{
                0x49, 0x89, 0xd1, // movq %rdx, %r9
                0x49, 0x89, 0xf8, // movq %rdi, %r8
                0x49, 0xc1, 0xe8, 0x03, // shrq $3, %r8
                0x49, 0x83, 0xe0, 0x3e, // andq $62, %r8
                0x4c, 0x8d, 0x15, 0, 0, 0, 0, // leaq spinlocks(%rip), %r10
                0x4d, 0x01, 0xc2, // addq %r8, %r10
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x49, 0x87, 0x02, // xchgq %rax, (%r10)
                0x48, 0x85, 0xc0, // testq %rax, %rax
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x75, 0xf3, // jne 1b
                0x48, 0x8b, 0x07, // movq (%rdi), %rax
                0x48, 0x8b, 0x57, 0x08, // movq 8(%rdi), %rdx
                0x49, 0x89, 0xc0, // movq %rax, %r8
                0x49, 0x21, 0xf0, // andq %rsi, %r8
                0x49, 0xf7, 0xd0, // notq %r8
                0x49, 0x89, 0xd3, // movq %rdx, %r11
                0x4d, 0x21, 0xcb, // andq %r9, %r11
                0x49, 0xf7, 0xd3, // notq %r11
                0x4c, 0x89, 0x07, // movq %r8, (%rdi)
                0x4c, 0x89, 0x5f, 0x08, // movq %r11, 8(%rdi)
                0x49, 0xc7, 0x02, 0, 0, 0, 0, // movq $0, (%r10)
            }),
            .spinlocked_fetch_xor_i128_rdi_rsi_rdx_rax_rdx => try bytes.appendSlice(allocator, &.{
                0x49, 0x89, 0xd1, // movq %rdx, %r9
                0x49, 0x89, 0xf8, // movq %rdi, %r8
                0x49, 0xc1, 0xe8, 0x03, // shrq $3, %r8
                0x49, 0x83, 0xe0, 0x3e, // andq $62, %r8
                0x4c, 0x8d, 0x15, 0, 0, 0, 0, // leaq spinlocks(%rip), %r10
                0x4d, 0x01, 0xc2, // addq %r8, %r10
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x49, 0x87, 0x02, // xchgq %rax, (%r10)
                0x48, 0x85, 0xc0, // testq %rax, %rax
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x75, 0xf3, // jne 1b
                0x48, 0x8b, 0x07, // movq (%rdi), %rax
                0x48, 0x8b, 0x57, 0x08, // movq 8(%rdi), %rdx
                0x49, 0x89, 0xc0, // movq %rax, %r8
                0x49, 0x31, 0xf0, // xorq %rsi, %r8
                0x49, 0x89, 0xd3, // movq %rdx, %r11
                0x4d, 0x31, 0xcb, // xorq %r9, %r11
                0x4c, 0x89, 0x07, // movq %r8, (%rdi)
                0x4c, 0x89, 0x5f, 0x08, // movq %r11, 8(%rdi)
                0x49, 0xc7, 0x02, 0, 0, 0, 0, // movq $0, (%r10)
            }),
            .spinlocked_fetch_or_i128_rdi_rsi_rdx_rax_rdx => try bytes.appendSlice(allocator, &.{
                0x49, 0x89, 0xd1, // movq %rdx, %r9
                0x49, 0x89, 0xf8, // movq %rdi, %r8
                0x49, 0xc1, 0xe8, 0x03, // shrq $3, %r8
                0x49, 0x83, 0xe0, 0x3e, // andq $62, %r8
                0x4c, 0x8d, 0x15, 0, 0, 0, 0, // leaq spinlocks(%rip), %r10
                0x4d, 0x01, 0xc2, // addq %r8, %r10
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x49, 0x87, 0x02, // xchgq %rax, (%r10)
                0x48, 0x85, 0xc0, // testq %rax, %rax
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x75, 0xf3, // jne 1b
                0x48, 0x8b, 0x07, // movq (%rdi), %rax
                0x48, 0x8b, 0x57, 0x08, // movq 8(%rdi), %rdx
                0x49, 0x89, 0xc0, // movq %rax, %r8
                0x49, 0x09, 0xf0, // orq %rsi, %r8
                0x49, 0x89, 0xd3, // movq %rdx, %r11
                0x4d, 0x09, 0xcb, // orq %r9, %r11
                0x4c, 0x89, 0x07, // movq %r8, (%rdi)
                0x4c, 0x89, 0x5f, 0x08, // movq %r11, 8(%rdi)
                0x49, 0xc7, 0x02, 0, 0, 0, 0, // movq $0, (%r10)
            }),
            .spinlocked_fetch_and_i128_rdi_rsi_rdx_rax_rdx => try bytes.appendSlice(allocator, &.{
                0x49, 0x89, 0xd1, // movq %rdx, %r9
                0x49, 0x89, 0xf8, // movq %rdi, %r8
                0x49, 0xc1, 0xe8, 0x03, // shrq $3, %r8
                0x49, 0x83, 0xe0, 0x3e, // andq $62, %r8
                0x4c, 0x8d, 0x15, 0, 0, 0, 0, // leaq spinlocks(%rip), %r10
                0x4d, 0x01, 0xc2, // addq %r8, %r10
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x49, 0x87, 0x02, // xchgq %rax, (%r10)
                0x48, 0x85, 0xc0, // testq %rax, %rax
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x75, 0xf3, // jne 1b
                0x48, 0x8b, 0x07, // movq (%rdi), %rax
                0x48, 0x8b, 0x57, 0x08, // movq 8(%rdi), %rdx
                0x49, 0x89, 0xc0, // movq %rax, %r8
                0x49, 0x21, 0xf0, // andq %rsi, %r8
                0x49, 0x89, 0xd3, // movq %rdx, %r11
                0x4d, 0x21, 0xcb, // andq %r9, %r11
                0x4c, 0x89, 0x07, // movq %r8, (%rdi)
                0x4c, 0x89, 0x5f, 0x08, // movq %r11, 8(%rdi)
                0x49, 0xc7, 0x02, 0, 0, 0, 0, // movq $0, (%r10)
            }),
            .spinlocked_fetch_sub_i128_rdi_rsi_rdx_rax_rdx => try bytes.appendSlice(allocator, &.{
                0x49, 0x89, 0xd1, // movq %rdx, %r9
                0x49, 0x89, 0xf8, // movq %rdi, %r8
                0x49, 0xc1, 0xe8, 0x03, // shrq $3, %r8
                0x49, 0x83, 0xe0, 0x3e, // andq $62, %r8
                0x4c, 0x8d, 0x15, 0, 0, 0, 0, // leaq spinlocks(%rip), %r10
                0x4d, 0x01, 0xc2, // addq %r8, %r10
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x49, 0x87, 0x02, // xchgq %rax, (%r10)
                0x48, 0x85, 0xc0, // testq %rax, %rax
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x75, 0xf3, // jne 1b
                0x48, 0x8b, 0x07, // movq (%rdi), %rax
                0x48, 0x8b, 0x57, 0x08, // movq 8(%rdi), %rdx
                0x49, 0x89, 0xc0, // movq %rax, %r8
                0x49, 0x89, 0xd3, // movq %rdx, %r11
                0x49, 0x29, 0xf0, // subq %rsi, %r8
                0x4d, 0x19, 0xcb, // sbbq %r9, %r11
                0x4c, 0x89, 0x07, // movq %r8, (%rdi)
                0x4c, 0x89, 0x5f, 0x08, // movq %r11, 8(%rdi)
                0x49, 0xc7, 0x02, 0, 0, 0, 0, // movq $0, (%r10)
            }),
            .spinlocked_fetch_add_i128_rdi_rsi_rdx_rax_rdx => try bytes.appendSlice(allocator, &.{
                0x49, 0x89, 0xd1, // movq %rdx, %r9
                0x49, 0x89, 0xf8, // movq %rdi, %r8
                0x49, 0xc1, 0xe8, 0x03, // shrq $3, %r8
                0x49, 0x83, 0xe0, 0x3e, // andq $62, %r8
                0x4c, 0x8d, 0x15, 0, 0, 0, 0, // leaq spinlocks(%rip), %r10
                0x4d, 0x01, 0xc2, // addq %r8, %r10
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x49, 0x87, 0x02, // xchgq %rax, (%r10)
                0x48, 0x85, 0xc0, // testq %rax, %rax
                0xb8, 0x01, 0x00, 0x00, 0x00, // movl $1, %eax
                0x75, 0xf3, // jne 1b
                0x48, 0x8b, 0x07, // movq (%rdi), %rax
                0x48, 0x8b, 0x57, 0x08, // movq 8(%rdi), %rdx
                0x49, 0x89, 0xc0, // movq %rax, %r8
                0x49, 0x89, 0xd3, // movq %rdx, %r11
                0x49, 0x01, 0xf0, // addq %rsi, %r8
                0x4d, 0x11, 0xcb, // adcq %r9, %r11
                0x4c, 0x89, 0x07, // movq %r8, (%rdi)
                0x4c, 0x89, 0x5f, 0x08, // movq %r11, 8(%rdi)
                0x49, 0xc7, 0x02, 0, 0, 0, 0, // movq $0, (%r10)
            }),
            .memmove_rdi_rsi_rdx_rax => try bytes.appendSlice(allocator, &.{
                0x48, 0x89, 0xf8, // movq %rdi, %rax
                0x48, 0x85, 0xd2, // testq %rdx, %rdx
                0x74, 0x1e, // je 4f
                0x48, 0x39, 0xf7, // cmpq %rsi, %rdi
                0x77, 0x08, // ja 2f
                0xfc, // cld
                0x48, 0x89, 0xd1, // movq %rdx, %rcx
                0xf3, 0xa4, // rep movsb
                0xeb, 0x11, // jmp 4f
                0xfd, // std
                0x48, 0x8d, 0x7c, 0x17, 0xff, // leaq -1(%rdi,%rdx), %rdi
                0x48, 0x8d, 0x74, 0x16, 0xff, // leaq -1(%rsi,%rdx), %rsi
                0x48, 0x89, 0xd1, // movq %rdx, %rcx
                0xf3, 0xa4, // rep movsb
                0xfc, // cld
            }),
            .stack_probe_rax_rcx_rsp => try bytes.appendSlice(allocator, &.{
                0x51, // pushq %rcx
                0x48, 0x89, 0xc1, // movq %rax, %rcx
                0x48, 0x81, 0xf9, 0x00, 0x10, 0x00, 0x00, // cmpq $0x1000, %rcx
                0x72, 0x1c, // jb 2f
                0x48, 0x81, 0xec, 0x00, 0x10, 0x00, 0x00, // subq $0x1000, %rsp
                0x83, 0x4c, 0x24, 0x10, 0x00, // orl $0, 16(%rsp)
                0x48, 0x81, 0xe9, 0x00, 0x10, 0x00, 0x00, // subq $0x1000, %rcx
                0x48, 0x81, 0xf9, 0x00, 0x10, 0x00, 0x00, // cmpq $0x1000, %rcx
                0x77, 0xe4, // ja 1b
                0x48, 0x29, 0xcc, // subq %rcx, %rsp
                0x83, 0x4c, 0x24, 0x10, 0x00, // orl $0, 16(%rsp)
                0x48, 0x01, 0xc4, // addq %rax, %rsp
                0x59, // popq %rcx
            }),
            .guarded_memset_rdi_sil_rdx_rcx_rax => try bytes.appendSlice(allocator, &.{
                0x48, 0x39, 0xd1, // cmpq %rdx, %rcx
                0x73, 0x02, // jae 1f
                0x0f, 0x0b, // ud2
                0x48, 0x89, 0xf8, // movq %rdi, %rax
                0x48, 0x85, 0xd2, // testq %rdx, %rdx
                0x74, 0x0e, // je 3f
                0x31, 0xc9, // xorl %ecx, %ecx
                0x40, 0x88, 0x34, 0x0f, // movb %sil, (%rdi,%rcx)
                0x48, 0xff, 0xc1, // incq %rcx
                0x48, 0x39, 0xca, // cmpq %rcx, %rdx
                0x75, 0xf4, // jne 2b
            }),
            .guarded_memcpy_rdi_rsi_rdx_rcx_rax => try bytes.appendSlice(allocator, &.{
                0x48, 0x39, 0xd1, // cmpq %rdx, %rcx
                0x73, 0x02, // jae 1f
                0x0f, 0x0b, // ud2
                0x48, 0x89, 0xf8, // movq %rdi, %rax
                0x48, 0x85, 0xd2, // testq %rdx, %rdx
                0x74, 0x06, // je 2f
                0xfc, // cld
                0x48, 0x89, 0xd1, // movq %rdx, %rcx
                0xf3, 0xa4, // rep movsb
            }),
            .guarded_strncat_rdi_rsi_rdx_rcx_rax => try bytes.appendSlice(allocator, &.{
                0x48, 0x89, 0xf8, // movq %rdi, %rax
                0x48, 0x85, 0xc9, // testq %rcx, %rcx
                0x75, 0x02, // jne 1f
                0x0f, 0x0b, // ud2
                0x45, 0x31, 0xc0, // xorl %r8d, %r8d
                0x42, 0x80, 0x3c, 0x07, 0x00, // cmpb $0, (%rdi,%r8)
                0x74, 0x0a, // je 3f
                0x49, 0xff, 0xc0, // incq %r8
                0x48, 0xff, 0xc9, // decq %rcx
                0x74, 0xec, // je 2b
                0xeb, 0xef, // jmp 2b
                0x4e, 0x8d, 0x0c, 0x07, // leaq (%rdi,%r8), %r9
                0x48, 0x85, 0xd2, // testq %rdx, %rdx
                0x74, 0x1e, // je 5f
                0x45, 0x31, 0xc0, // xorl %r8d, %r8d
                0x46, 0x0f, 0xb6, 0x14, 0x06, // movzbl (%rsi,%r8), %r10d
                0x45, 0x84, 0xd2, // testb %r10b, %r10b
                0x74, 0x11, // je 5f
                0x47, 0x88, 0x14, 0x01, // movb %r10b, (%r9,%r8)
                0x48, 0xff, 0xc9, // decq %rcx
                0x74, 0xcb, // je 1b
                0x49, 0xff, 0xc0, // incq %r8
                0x49, 0x39, 0xd0, // cmpq %rdx, %r8
                0x72, 0xe5, // jb 4b
                0x43, 0xc6, 0x04, 0x01, 0x00, // movb $0, (%r9,%r8)
            }),
            .guarded_strcat_rdi_rsi_rdx_rax => try bytes.appendSlice(allocator, &.{
                0x48, 0x89, 0xf8, // movq %rdi, %rax
                0x48, 0x85, 0xd2, // testq %rdx, %rdx
                0x75, 0x02, // jne 1f
                0x0f, 0x0b, // ud2
                0x45, 0x31, 0xc0, // xorl %r8d, %r8d
                0x42, 0x80, 0x3c, 0x07, 0x00, // cmpb $0, (%rdi,%r8)
                0x74, 0x0a, // je 3f
                0x49, 0xff, 0xc0, // incq %r8
                0x48, 0xff, 0xca, // decq %rdx
                0x74, 0xec, // je 0b
                0xeb, 0xef, // jmp 2b
                0x4e, 0x8d, 0x0c, 0x07, // leaq (%rdi,%r8), %r9
                0x45, 0x31, 0xc0, // xorl %r8d, %r8d
                0x46, 0x0f, 0xb6, 0x14, 0x06, // movzbl (%rsi,%r8), %r10d
                0x45, 0x84, 0xd2, // testb %r10b, %r10b
                0x74, 0x10, // je 5f
                0x47, 0x88, 0x14, 0x01, // movb %r10b, (%r9,%r8)
                0x48, 0xff, 0xca, // decq %rdx
                0x74, 0xd0, // je 0b
                0x49, 0xff, 0xc0, // incq %r8
                0xeb, 0xe8, // jmp 4b
                0x43, 0xc6, 0x04, 0x01, 0x00, // movb $0, (%r9,%r8)
            }),
            .guarded_strncpy_rdi_rsi_rdx_rcx_rax => try bytes.appendSlice(allocator, &.{
                0x48, 0x89, 0xf8, // movq %rdi, %rax
                0x48, 0x39, 0xd1, // cmpq %rdx, %rcx
                0x73, 0x02, // jae 1f
                0x0f, 0x0b, // ud2
                0x48, 0x85, 0xd2, // testq %rdx, %rdx
                0x74, 0x28, // je 5f
                0x45, 0x31, 0xc0, // xorl %r8d, %r8d
                0x46, 0x0f, 0xb6, 0x0c, 0x06, // movzbl (%rsi,%r8), %r9d
                0x45, 0x84, 0xc9, // testb %r9b, %r9b
                0x74, 0x0e, // je 3f
                0x46, 0x88, 0x0c, 0x07, // movb %r9b, (%rdi,%r8)
                0x49, 0xff, 0xc0, // incq %r8
                0x49, 0x39, 0xd0, // cmpq %rdx, %r8
                0x72, 0xea, // jb 2b
                0xeb, 0x0d, // jmp 5f
                0x42, 0xc6, 0x04, 0x07, 0x00, // movb $0, (%rdi,%r8)
                0x49, 0xff, 0xc0, // incq %r8
                0x49, 0x39, 0xd0, // cmpq %rdx, %r8
                0x72, 0xf3, // jb 3b
            }),
            .guarded_strcpy_rdi_rsi_rdx_rax => try bytes.appendSlice(allocator, &.{
                0x48, 0x89, 0xf8, // movq %rdi, %rax
                0x48, 0x85, 0xd2, // testq %rdx, %rdx
                0x75, 0x02, // jne 1f
                0x0f, 0x0b, // ud2
                0x45, 0x31, 0xc0, // xorl %r8d, %r8d
                0x46, 0x0f, 0xb6, 0x0c, 0x06, // movzbl (%rsi,%r8), %r9d
                0x45, 0x84, 0xc9, // testb %r9b, %r9b
                0x74, 0x0e, // je 3f
                0x46, 0x88, 0x0c, 0x07, // movb %r9b, (%rdi,%r8)
                0x48, 0xff, 0xca, // decq %rdx
                0x74, 0xe8, // je 0b
                0x49, 0xff, 0xc0, // incq %r8
                0xeb, 0xe8, // jmp 2b
                0x42, 0xc6, 0x04, 0x07, 0x00, // movb $0, (%rdi,%r8)
            }),
            .memset_rdi_sil_rdx_rax => try bytes.appendSlice(allocator, &.{
                0x48, 0x89, 0xf8, // movq %rdi, %rax
                0x48, 0x85, 0xd2, // testq %rdx, %rdx
                0x74, 0x0e, // je 2f
                0x31, 0xc9, // xorl %ecx, %ecx
                0x40, 0x88, 0x34, 0x0f, // movb %sil, (%rdi,%rcx)
                0x48, 0xff, 0xc1, // incq %rcx
                0x48, 0x39, 0xca, // cmpq %rcx, %rdx
                0x75, 0xf4, // jne 1b
            }),
            .strlen_rdi_rax => try bytes.appendSlice(allocator, &.{
                0x31, 0xc0,
                0x80, 0x3c, 0x07, 0x00,
                0x74, 0x05,
                0x48, 0xff, 0xc0,
                0xeb, 0xf5,
            }),
            .strnlen_rdi_rsi_rax => try bytes.appendSlice(allocator, &.{
                0x31, 0xc0,
                0x48, 0x39, 0xf0,
                0x73, 0x0b,
                0x80, 0x3c, 0x07, 0x00,
                0x74, 0x05,
                0x48, 0xff, 0xc0,
                0xeb, 0xf0,
            }),
            .atomic_try_lock_rdi_al => try bytes.appendSlice(allocator, &.{
                0x31, 0xc0, // xorl %eax, %eax
                0xba, 0x01, 0x00, 0x00, 0x00, // movl $1, %edx
                0xf0, 0x0f, 0xb1, 0x17, // lock cmpxchgl %edx, (%rdi)
                0x0f, 0x94, 0xc0, // sete %al
            }),
            .smin_i32_edi_esi_eax => try bytes.appendSlice(allocator, &.{ 0x89, 0xf8, 0x39, 0xf7, 0x0f, 0x4f, 0xc6 }),
            .umin_i32_edi_esi_eax => try bytes.appendSlice(allocator, &.{ 0x89, 0xf8, 0x39, 0xf7, 0x0f, 0x47, 0xc6 }),
            .smax_i32_edi_esi_eax => try bytes.appendSlice(allocator, &.{ 0x89, 0xf8, 0x39, 0xf7, 0x0f, 0x4c, 0xc6 }),
            .umax_i32_edi_esi_eax => try bytes.appendSlice(allocator, &.{ 0x89, 0xf8, 0x39, 0xf7, 0x0f, 0x42, 0xc6 }),
            .shift_mix_i32_edi_esi_eax => try bytes.appendSlice(allocator, &.{ 0x89, 0xf1, 0x83, 0xe1, 0x1f, 0x89, 0xf8, 0xd3, 0xe0, 0x89, 0xfa, 0xd3, 0xea, 0x31, 0xd0 }),
            .replace_low_i8_dil_sil_al => try bytes.appendSlice(allocator, &.{ 0x89, 0xf8, 0x83, 0xe0, 0xf8, 0x89, 0xf2, 0x83, 0xe2, 0x07, 0x09, 0xd0 }),
            .read_flag_i8_dil_al => try bytes.appendSlice(allocator, &.{ 0x31, 0xc0, 0x40, 0x84, 0xff, 0x0f, 0x98, 0xc0 }),
            .ult_i8_dil_imm8_al => |imm| try bytes.appendSlice(allocator, &.{ 0x31, 0xc0, 0x40, 0x80, 0xff, imm, 0x0f, 0x92, 0xc0 }),
            .cmp_ult_u32_edi_esi_al => try bytes.appendSlice(allocator, &.{ 0x31, 0xc0, 0x39, 0xf7, 0x0f, 0x92, 0xc0 }),
            .ascii_range_u8_dil_imm8_imm8_al => |range| try bytes.appendSlice(allocator, &.{
                0x31, 0xc0,
                0x40, 0x88, 0xf8,
                0x2c, range.low,
                0x3c, range.len,
                0x0f, 0x92, 0xc0,
            }),
            .range_u32_edi_imm32_imm32_al => |range| {
                const low_bytes: [4]u8 = @bitCast(range.low);
                const len_bytes: [4]u8 = @bitCast(range.len);
                try bytes.appendSlice(allocator, &.{
                    0x31, 0xc0,
                    0x81, 0xef, low_bytes[0], low_bytes[1], low_bytes[2], low_bytes[3],
                    0x81, 0xff, len_bytes[0], len_bytes[1], len_bytes[2], len_bytes[3],
                    0x0f, 0x92, 0xc0,
                });
            },
            .ascii_alphabetic_dil_al => try bytes.appendSlice(allocator, &.{
                0x31, 0xc0,
                0x40, 0x88, 0xf8,
                0x24, 0xdf,
                0x2c, 0x41,
                0x3c, 0x1a,
                0x0f, 0x92, 0xc0,
            }),
            .ascii_alphanumeric_dil_al => try bytes.appendSlice(allocator, &.{
                0x31, 0xc0,
                0x40, 0x88, 0xf9,
                0x80, 0xe9, 0x30,
                0x80, 0xf9, 0x0a,
                0x0f, 0x92, 0xc1,
                0x40, 0x88, 0xf8,
                0x24, 0xdf,
                0x2c, 0x41,
                0x3c, 0x1a,
                0x0f, 0x92, 0xc0,
                0x08, 0xc8,
            }),
            .ascii_whitespace_dil_al => try bytes.appendSlice(allocator, &.{
                0x31, 0xc0,
                0x40, 0x80, 0xff, 0x20,
                0x0f, 0x94, 0xc1,
                0x40, 0x88, 0xf8,
                0x2c, 0x09,
                0x3c, 0x05,
                0x0f, 0x92, 0xc0,
                0x08, 0xc8,
            }),
            .ascii_control_dil_al => try bytes.appendSlice(allocator, &.{
                0x31, 0xc0,
                0x40, 0x80, 0xff, 0x1f,
                0x0f, 0x96, 0xc0,
                0x40, 0x80, 0xff, 0x7f,
                0x0f, 0x94, 0xc1,
                0x08, 0xc8,
            }),
            .grow_capacity_u64_rdi_imm32_rax => |imm| {
                if (imm >= -128 and imm <= 127) {
                    try bytes.appendSlice(allocator, &.{
                        0x48, 0x89, 0xf9,
                        0x48, 0xd1, 0xe9,
                        0x48, 0xc7, 0xc0, 0xff, 0xff, 0xff, 0xff,
                        0x48, 0x83, 0xc1, @as(u8, @bitCast(@as(i8, @intCast(imm)))),
                        0x48, 0x01, 0xf9,
                        0x48, 0x0f, 0x43, 0xc1,
                    });
                } else {
                    try bytes.appendSlice(allocator, &.{
                        0x48, 0x89, 0xf9,
                        0x48, 0xd1, 0xe9,
                        0x48, 0xc7, 0xc0, 0xff, 0xff, 0xff, 0xff,
                        0x48, 0x81, 0xc1,
                    });
                    try appendI32(&bytes, allocator, imm);
                    try bytes.appendSlice(allocator, &.{
                        0x48, 0x01, 0xf9,
                        0x48, 0x0f, 0x43, 0xc1,
                    });
                }
            },
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
            .cmp_rdx_rcx => try bytes.appendSlice(allocator, &.{ 0x48, 0x39, 0xd1 }),
            .cmp_rdx_rdi => try bytes.appendSlice(allocator, &.{ 0x48, 0x39, 0xfa }),
            .cmp_rax_rdx => try bytes.appendSlice(allocator, &.{ 0x48, 0x39, 0xd0 }),
            .setb_eax => try bytes.appendSlice(allocator, &.{ 0x0f, 0x92, 0xc0, 0x0f, 0xb6, 0xc0 }),
            .seta_eax => try bytes.appendSlice(allocator, &.{ 0x0f, 0x97, 0xc0, 0x0f, 0xb6, 0xc0 }),
            .sete_eax => try bytes.appendSlice(allocator, &.{ 0x0f, 0x94, 0xc0, 0x0f, 0xb6, 0xc0 }),
            .setg_eax => try bytes.appendSlice(allocator, &.{ 0x0f, 0x9f, 0xc0, 0x0f, 0xb6, 0xc0 }),
            .setl_eax => try bytes.appendSlice(allocator, &.{ 0x0f, 0x9c, 0xc0, 0x0f, 0xb6, 0xc0 }),
            .setne_eax => try bytes.appendSlice(allocator, &.{ 0x0f, 0x95, 0xc0, 0x0f, 0xb6, 0xc0 }),
            .setbe_eax => try bytes.appendSlice(allocator, &.{ 0x0f, 0x96, 0xc0, 0x0f, 0xb6, 0xc0 }),
            .test_eax_eax => try bytes.appendSlice(allocator, &.{ 0x85, 0xc0 }),
            .test_rax_rax => try bytes.appendSlice(allocator, &.{ 0x48, 0x85, 0xc0 }),
            .test_rdx_rdx => try bytes.appendSlice(allocator, &.{ 0x48, 0x85, 0xd2 }),
            .mulsd_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x59, 0xc1 }),
            .mulss_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x59, 0xc1 }),
            .mulsd_xmm => |mul| try encodeScalarXmmOp(&bytes, allocator, 0xf2, 0x59, mul.dst, mul.src),
            .mulss_xmm => |mul| try encodeScalarXmmOp(&bytes, allocator, 0xf3, 0x59, mul.dst, mul.src),
            .subsd_xmm => |sub| try encodeScalarXmmOp(&bytes, allocator, 0xf2, 0x5c, sub.dst, sub.src),
            .subss_xmm => |sub| try encodeScalarXmmOp(&bytes, allocator, 0xf3, 0x5c, sub.dst, sub.src),
            .divsd_xmm => |div| try encodeScalarXmmOp(&bytes, allocator, 0xf2, 0x5e, div.dst, div.src),
            .divss_xmm => |div| try encodeScalarXmmOp(&bytes, allocator, 0xf3, 0x5e, div.dst, div.src),
            .addsd_xmm => |add| try encodeScalarXmmOp(&bytes, allocator, 0xf2, 0x58, add.dst, add.src),
            .addss_xmm => |add| try encodeScalarXmmOp(&bytes, allocator, 0xf3, 0x58, add.dst, add.src),
            .addss_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x58, 0xc1 }),
            .subss_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x5c, 0xc1 }),
            .divsd_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x5e, 0xc1 }),
            .xorps_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0x0f, 0x57, 0xc1 }),
            .movapd_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0x66, 0x0f, 0x28, 0xc1 }),
            .movapd_xmm => |mov| try encodeMovapdXmm(&bytes, allocator, mov.dst, mov.src),
            .addpd_xmm => |op| try encodeScalarXmmOp(&bytes, allocator, 0x66, 0x58, op.dst, op.src),
            .subpd_xmm => |op| try encodeScalarXmmOp(&bytes, allocator, 0x66, 0x5c, op.dst, op.src),
            .mulpd_xmm => |op| try encodeScalarXmmOp(&bytes, allocator, 0x66, 0x59, op.dst, op.src),
            .addps_xmm => |op| try encodeScalarXmmOp(&bytes, allocator, null, 0x58, op.dst, op.src),
            .subps_xmm => |op| try encodeScalarXmmOp(&bytes, allocator, null, 0x5c, op.dst, op.src),
            .mulps_xmm => |op| try encodeScalarXmmOp(&bytes, allocator, null, 0x59, op.dst, op.src),
            .andps_xmm => |op| try encodeScalarXmmOp(&bytes, allocator, null, 0x54, op.dst, op.src),
            .pxor_xmm => |op| try encodeScalarXmmOp(&bytes, allocator, 0x66, 0xef, op.dst, op.src),
            .pcmpgtd_xmm => |op| try encodeScalarXmmOp(&bytes, allocator, 0x66, 0x66, op.dst, op.src),
            .cmpeqps_xmm => |op| {
                try encodeScalarXmmOp(&bytes, allocator, null, 0xc2, op.dst, op.src);
                try bytes.append(allocator, 0x00);
            },
            .cmpeqpd_xmm => |op| {
                try encodeScalarXmmOp(&bytes, allocator, 0x66, 0xc2, op.dst, op.src);
                try bytes.append(allocator, 0x00);
            },
            .movmskps_xmm_eax => |src| try bytes.appendSlice(allocator, &.{ 0x0f, 0x50, 0xc0 | @as(u8, src.lowCode()) }),
            .movmskpd_xmm_eax => |src| try bytes.appendSlice(allocator, &.{ 0x66, 0x0f, 0x50, 0xc0 | @as(u8, src.lowCode()) }),
            .movsd_xmm => |mov| try encodeScalarXmmOp(&bytes, allocator, 0xf2, 0x10, mov.dst, mov.src),
            .movss_xmm => |mov| try encodeScalarXmmOp(&bytes, allocator, 0xf3, 0x10, mov.dst, mov.src),
            .unpcklpd_xmm => |mov| try encodeScalarXmmOp(&bytes, allocator, 0x66, 0x14, mov.dst, mov.src),
            .unpckhpd_xmm => |mov| try encodeScalarXmmOp(&bytes, allocator, 0x66, 0x15, mov.dst, mov.src),
            .shufpd_xmm => |shuffle| {
                try encodeScalarXmmOp(&bytes, allocator, 0x66, 0xc6, shuffle.dst, shuffle.src);
                try bytes.append(allocator, shuffle.imm);
            },
            .unpcklps_xmm => |mov| try bytes.appendSlice(allocator, &.{ 0x0f, 0x14, 0xc0 | (@as(u8, mov.dst.lowCode()) << 3) | @as(u8, mov.src.lowCode()) }),
            .shufps_high_f32_to_low => |reg| try bytes.appendSlice(allocator, &.{ 0x0f, 0xc6, 0xc0 | (@as(u8, reg.lowCode()) << 3) | @as(u8, reg.lowCode()), 0x55 }),
            .shufps_xmm => |shuffle| try bytes.appendSlice(allocator, &.{ 0x0f, 0xc6, 0xc0 | (@as(u8, shuffle.dst.lowCode()) << 3) | @as(u8, shuffle.src.lowCode()), shuffle.imm }),
            .cvtsi2ss_edi_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x2a, 0xc7 }),
            .cvtsi2sd_edi_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x2a, 0xc7 }),
            .cvtsi2ss_rdi_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf3, 0x48, 0x0f, 0x2a, 0xc7 }),
            .cvtsi2sd_rdi_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf2, 0x48, 0x0f, 0x2a, 0xc7 }),
            .cvttss2si_xmm0_eax => try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x2c, 0xc0 }),
            .cvttsd2si_xmm0_eax => try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x2c, 0xc0 }),
            .cvtsd2ss_xmm0_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x5a, 0xc0 }),
            .cvtss2sd_xmm0_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x5a, 0xc0 }),
            .cvtsd2ss_xmm => |cvt| try encodeScalarXmmOp(&bytes, allocator, 0xf2, 0x5a, cvt.dst, cvt.src),
            .cvtss2sd_xmm => |cvt| try encodeScalarXmmOp(&bytes, allocator, 0xf3, 0x5a, cvt.dst, cvt.src),
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
            .ucomiss => |cmp| try bytes.appendSlice(allocator, &.{ 0x0f, 0x2e, 0xc0 | (@as(u8, cmp.dst.lowCode()) << 3) | @as(u8, cmp.src.lowCode()) }),
            .set_fcmp_eax => |predicate| try encodeFcmpResult(&bytes, allocator, predicate),
            .ucomisd_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0x66, 0x0f, 0x2e, 0xc1 }),
            .ucomiss_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0x0f, 0x2e, 0xc1 }),
            .ucomiss_xmm0_xmm1 => try bytes.appendSlice(allocator, &.{ 0x0f, 0x2e, 0xc8 }),
            .oltss_xmm0_xmm1_al => try bytes.appendSlice(allocator, &.{ 0x31, 0xc0, 0x0f, 0x2e, 0xc8, 0x0f, 0x97, 0xc0 }),
            .fneg_x86_fp80_stack8_st0 => try bytes.appendSlice(allocator, &.{ 0xdb, 0x6c, 0x24, 0x08, 0xd9, 0xe0 }),
            .fneg_fp128_xmm0 => try bytes.appendSlice(allocator, &.{ 0x48, 0xb8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0x66, 0x48, 0x0f, 0x6e, 0xc8, 0x66, 0x0f, 0x73, 0xf9, 0x08, 0x0f, 0x57, 0xc1 }),
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
            .sub_rsp_imm8 => |value| try bytes.appendSlice(allocator, &.{ 0x48, 0x83, 0xec, value }),
            .sub_rsp_imm32 => |value| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0x81, 0xec });
                try appendU32(&bytes, allocator, value);
            },
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
            .spill_xmm128_rsp => |spill| try encodeXmmFrameSlot(&bytes, allocator, 0x66, 0x11, spill.reg, spill.frame_index),
            .reload_xmm128_rsp => |reload| try encodeXmmFrameSlot(&bytes, allocator, 0x66, 0x10, reload.reg, reload.frame_index),
            .spill_xmm128ps_rsp => |spill| try encodeXmmFrameSlot(&bytes, allocator, null, 0x11, spill.reg, spill.frame_index),
            .reload_xmm128ps_rsp => |reload| try encodeXmmFrameSlot(&bytes, allocator, null, 0x10, reload.reg, reload.frame_index),
            .spill_rdi_rsi_rsp24 => try bytes.appendSlice(allocator, &.{ 0x48, 0x89, 0x7c, 0x24, 0x08, 0x48, 0x89, 0x74, 0x24, 0x10 }),
            .reload_rdi_rsp24 => try bytes.appendSlice(allocator, &.{ 0x48, 0x8b, 0x7c, 0x24, 0x08 }),
            .reload_rsi_rsp24 => try bytes.appendSlice(allocator, &.{ 0x48, 0x8b, 0x74, 0x24, 0x10 }),
            .spill_eax_rsp => |frame_index| try encodeEaxToFrameSlot(&bytes, allocator, frame_index),
            .reload_rsp_eax => |frame_index| try encodeFrameSlotToEax(&bytes, allocator, frame_index),
            .spill_rax_rsp => |frame_index| try encodeRaxToFrameSlot(&bytes, allocator, frame_index),
            .reload_rsp_rax => |frame_index| try encodeFrameSlotToRax(&bytes, allocator, frame_index),
            .load_stack_disp8_eax => |disp| {
                try bytes.appendSlice(allocator, &.{ 0x8b, 0x44, 0x24 });
                try bytes.append(allocator, disp);
            },
            .load_stack_disp32_eax => |disp| {
                try bytes.appendSlice(allocator, &.{ 0x8b, 0x84, 0x24 });
                try appendU32(&bytes, allocator, disp);
            },
            .load_stack_rcx4_disp8_eax => |disp| {
                try bytes.appendSlice(allocator, &.{ 0x8b, 0x44, 0x8c });
                try bytes.append(allocator, disp);
            },
            .load_stack_rcx4_disp32_eax => |disp| {
                try bytes.appendSlice(allocator, &.{ 0x8b, 0x84, 0x8c });
                try appendU32(&bytes, allocator, disp);
            },
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
            .load_stack_disp8_xmm_f32 => |load| {
                try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x10 });
                try bytes.append(allocator, 0x44 | (@as(u8, load.reg.lowCode()) << 3));
                try bytes.append(allocator, 0x24);
                try bytes.append(allocator, load.disp);
            },
            .load_stack_disp32_xmm_f32 => |load| {
                try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x10 });
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
            .load_rax_ptr_disp32_rax => |disp| {
                try bytes.appendSlice(allocator, &.{ 0x48, 0x8b, 0x80 });
                try appendU32(&bytes, allocator, disp);
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
            .load_arg_ptr_disp32_rax => |load| try encodeArgPtrDisp32ToRax(&bytes, allocator, load.reg, load.offset),
            .load_arg_ptr_disp8_eax => |load| try encodeArgPtrDisp8ToEax(&bytes, allocator, load.reg, load.offset),
            .load_arg_ptr_disp8_u8_eax => |load| try encodeArgPtrDisp8U8ToEax(&bytes, allocator, load.reg, load.offset),
            .load_arg_ptr_disp8_u16_eax => |load| try encodeArgPtrDisp8U16ToEax(&bytes, allocator, load.reg, load.offset),
            .load_arg_ptr_disp8_u16_arg => |load| try encodeArgPtrDisp8U16ToArg(&bytes, allocator, load.base, load.dst, load.offset),
            .load_arg_ptr_disp8_xmm => |load| try encodeArgPtrDisp8ToXmm(&bytes, allocator, load.base, load.dst, load.offset),
            .add_arg_ptr_disp4_eax => |reg| try encodeArgPtrDisp4ToEax(&bytes, allocator, reg),
            .inc_arg_ptr_disp8 => |inc| try encodeIncArgPtrDisp8(&bytes, allocator, inc.reg, inc.offset),
            .store_eax_arg_ptr => |reg| try encodeEaxToArgPtr(&bytes, allocator, reg),
            .store_imm64_arg_ptr_disp8 => |store| try encodeStoreImm64ArgPtrDisp8(&bytes, allocator, store.reg, store.offset, store.imm),
            .store_arg64_arg_ptr_disp8 => |store| try encodeStoreArg64ToArgPtrDisp8(&bytes, allocator, store.ptr_reg, store.src_reg, store.offset),
            .store_arg64_arg_ptr_disp32 => |store| try encodeStoreArg64ToArgPtrDisp32(&bytes, allocator, store.ptr_reg, store.src_reg, store.offset),
            .store_rax_arg_ptr_disp8 => |store| try encodeStoreRaxToArgPtrDisp8(&bytes, allocator, store.reg, store.offset),
            .store_rax_arg_ptr_disp32 => |store| try encodeStoreRaxToArgPtrDisp32(&bytes, allocator, store.reg, store.offset),
            .store_eax_arg_ptr_disp8 => |store| try encodeStoreEaxToArgPtrDisp8(&bytes, allocator, store.reg, store.offset),
            .store_eax_arg_ptr_disp32 => |store| try encodeStoreEaxToArgPtrDisp32(&bytes, allocator, store.reg, store.offset),
            .store_eax_stack_disp8 => |disp| try bytes.appendSlice(allocator, &.{ 0x89, 0x44, 0x24, disp }),
            .store_eax_stack_disp32 => |disp| {
                try bytes.appendSlice(allocator, &.{ 0x89, 0x84, 0x24 });
                try appendU32(&bytes, allocator, disp);
            },
            .store_al_stack_disp8 => |disp| try bytes.appendSlice(allocator, &.{ 0x88, 0x44, 0x24, disp }),
            .store_al_stack_disp32 => |disp| {
                try bytes.appendSlice(allocator, &.{ 0x88, 0x84, 0x24 });
                try appendU32(&bytes, allocator, disp);
            },
            .store_eax_stack_rcx4_disp8 => |disp| try bytes.appendSlice(allocator, &.{ 0x89, 0x44, 0x8c, disp }),
            .store_eax_stack_rcx4_disp32 => |disp| {
                try bytes.appendSlice(allocator, &.{ 0x89, 0x84, 0x8c });
                try appendU32(&bytes, allocator, disp);
            },
            .store_al_arg_ptr_disp8 => |store| try encodeStoreAlToArgPtrDisp8(&bytes, allocator, store.reg, store.offset),
            .store_al_arg_ptr_disp32 => |store| try encodeStoreAlToArgPtrDisp32(&bytes, allocator, store.reg, store.offset),
            .store_ax_arg_ptr_disp8 => |store| try encodeStoreAxToArgPtrDisp8(&bytes, allocator, store.reg, store.offset),
            .store_ax_arg_ptr_disp32 => |store| try encodeStoreAxToArgPtrDisp32(&bytes, allocator, store.reg, store.offset),
            .store_xmm0_arg_ptr_disp8 => |store| try encodeStoreXmm0ToArgPtrDisp8(&bytes, allocator, store.reg, store.offset),
            .store_xmm0_arg_ptr_disp32 => |store| try encodeStoreXmm0ToArgPtrDisp32(&bytes, allocator, store.reg, store.offset),
            .store_xmm0_f32_arg_ptr_disp8 => |store| try encodeStoreXmm0F32ToArgPtrDisp8(&bytes, allocator, store.reg, store.offset),
            .store_xmm0_f32_arg_ptr_disp32 => |store| try encodeStoreXmm0F32ToArgPtrDisp32(&bytes, allocator, store.reg, store.offset),
            .store_imm8_arg_ptr_disp8 => |store| try encodeStoreImm8ArgPtrDisp8(&bytes, allocator, store.reg, store.offset, store.imm),
            .load_f128_arg_ptr_xmm0 => |load| try encodeF128ArgPtrToXmm0(&bytes, allocator, load.reg, load.offset, load.unaligned),
            .load_f128_const_xmm0 => try bytes.appendSlice(allocator, &.{ 0x0f, 0x28, 0x05, 0, 0, 0, 0 }),
            .load_f128_const_xmm1 => try bytes.appendSlice(allocator, &.{ 0x0f, 0x28, 0x0d, 0, 0, 0, 0 }),
            .store_f128_xmm0_arg_ptr => |store| try encodeF128Xmm0ToArgPtr(&bytes, allocator, store.reg, store.offset, store.unaligned),
            .volatile_roundtrip_rdi_esi_eax => try bytes.appendSlice(allocator, &.{ 0x89, 0x37, 0x8b, 0x07 }),
            .load_global_i32_eax => try bytes.appendSlice(allocator, &.{ 0x8b, 0x05, 0, 0, 0, 0 }),
            .load_global_ptr_rax => try bytes.appendSlice(allocator, &.{ 0x48, 0x8b, 0x05, 0, 0, 0, 0 }),
            .lea_global_rax => try bytes.appendSlice(allocator, &.{ 0x48, 0x8d, 0x05, 0, 0, 0, 0 }),
            .lea_global_offset_rax => try bytes.appendSlice(allocator, &.{ 0x48, 0x8d, 0x05, 0, 0, 0, 0 }),
            .lea_global_rdi => try bytes.appendSlice(allocator, &.{ 0x48, 0x8d, 0x3d, 0, 0, 0, 0 }),
            .lea_global_rsi => try bytes.appendSlice(allocator, &.{ 0x48, 0x8d, 0x35, 0, 0, 0, 0 }),
            .lea_global_rdx => try bytes.appendSlice(allocator, &.{ 0x48, 0x8d, 0x15, 0, 0, 0, 0 }),
            .lea_global_arg64 => |lea| {
                try bytes.append(allocator, if (lea.reg.rexR()) 0x4c else 0x48);
                try bytes.appendSlice(allocator, &.{ 0x8d, (@as(u8, lea.reg.lowCode()) << 3) | 0x05, 0, 0, 0, 0 });
            },
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
            .direct_jump => {
                try bytes.append(allocator, 0xe9);
                try appendI32(&bytes, allocator, 0);
            },
            .indirect_call_rax => try bytes.appendSlice(allocator, &.{ 0xff, 0xd0 }),
            .indirect_jump => |jump| {
                if (jump.reg == .r8 or jump.reg == .r9) try bytes.append(allocator, 0x41);
                const code: u8 = switch (jump.reg) { .rdi => 7, .rsi => 6, .rdx => 2, .rcx => 1, .r8 => 0, .r9 => 1 };
                try bytes.appendSlice(allocator, &.{ 0xff, 0xe0 | code });
            },
            .cmp_arg8_imm8 => |cmp| try encodeCmp8Imm(&bytes, allocator, cmp.reg, cmp.imm),
            .test_arg8 => |reg| try encodeTest8(&bytes, allocator, reg),
            .test_arg32 => |reg| try encodeTest32(&bytes, allocator, reg),
            .test_arg64 => |reg| try encodeTest64(&bytes, allocator, reg),
            .base64_raw_args_to_decode4_regs => try bytes.appendSlice(allocator, base64RawArgsToDecode4RegsBytes()),
            .base64_decode4_from_table_rax => try bytes.appendSlice(allocator, base64Decode4FromTableRaxBytes()),
            .syscall => try bytes.appendSlice(allocator, &.{ 0x0f, 0x05 }),
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
            .jc => |label| {
                const target = offsets.get(label) orelse return error.InvalidBranchTarget;
                const next = offset + instructionSize(instruction);
                const displacement: i64 = @as(i64, @intCast(target)) - @as(i64, @intCast(next));
                if (displacement < std.math.minInt(i32) or displacement > std.math.maxInt(i32)) return error.BranchOutOfRange;
                try bytes.appendSlice(allocator, &.{ 0x0f, 0x82 });
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

fn encodeFcmpResult(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, predicate: ir.FcmpPredicate) !void {
    if (predicate == .false or predicate == .true) {
        try bytes.appendSlice(allocator, if (predicate == .true) &.{ 0xb8, 1, 0, 0, 0 } else &.{ 0xb8, 0, 0, 0, 0 });
        return;
    }
    const opcode: u8 = switch (predicate) {
        .oeq, .ueq => 0x94,
        .ogt, .ugt => 0x97,
        .oge, .uge => 0x93,
        .olt, .ult => 0x92,
        .ole, .ule => 0x96,
        .one, .une => 0x95,
        .ord => 0x9b,
        .uno => 0x9a,
        .false, .true => unreachable,
    };
    try bytes.appendSlice(allocator, &.{ 0x0f, opcode, 0xc0 });
    switch (predicate) {
        .oeq, .olt, .ole => try bytes.appendSlice(allocator, &.{ 0x0f, 0x9b, 0xc4, 0x20, 0xe0 }),
        .ugt, .uge, .une => try bytes.appendSlice(allocator, &.{ 0x0f, 0x9a, 0xc4, 0x08, 0xe0 }),
        else => {},
    }
    try bytes.appendSlice(allocator, &.{ 0x0f, 0xb6, 0xc0 });
}

fn fcmpResultSize(predicate: ir.FcmpPredicate) u32 {
    return switch (predicate) {
        .false, .true => 5,
        .oeq, .olt, .ole, .ugt, .uge, .une => 11,
        .ogt, .oge, .one, .ord, .uno, .ueq, .ult, .ule => 6,
    };
}

pub fn instructionSize(instruction: x86_64.Instruction) u32 {
    return switch (instruction) {
        .linux_syscall => |count| if (count >= 4) 5 else 2,
        .register_snapshot_rdi => 78,
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
        .mov_rax_rsi => 3,
        .mov_arg_rax => 3,
        .movq_xmm_rax => 5,
        .movq_rax_xmm => 5,
        .movd_xmm_eax, .movd_eax_xmm => 4,
        .mov_arg_eax => |reg| if (reg.rexR()) 3 else 2,
        .mov_eax_to_arg => |reg| if (reg.rexB()) 3 else 2,
        .mov_rax_to_arg => 3,
        .mov_arg_arg => |mov| if (mov.src.rexR() or mov.dst.rexR()) 3 else 2,
        .mov_arg64_arg, .mov_rsp_arg64 => 3,
        .movsxd_arg32_arg64 => 3,
        .push_arg => |reg| if (reg.rexB()) 2 else 1,
        .pop_arg => |reg| if (reg.rexB()) 2 else 1,
        .push_rax => 1,
        .push_xmm64 => 9,
        .push_byval_tail_arg_ptr => |copy| pushByvalTailArgPtrSize(copy.reg, copy.offset, copy.len),
        .push_byval_tail_stack_ptr => |copy| pushByvalTailStackPtrSize(copy.len),
        .binary_arg_eax => |binary| if (binary.reg.rexR()) 3 else 2,
        .binary_arg_rax => 3,
        .sbb_arg64_rax => 3,
        .adc_rax_imm0 => 4,
        .imul_arg64_arg64 => 4,
        .imul_eax_arg32 => |reg| if (reg.rexB()) 4 else 3,
        .imul_arg64_rax, .imul_rax_arg64 => 4,
        .imul_rax_rsp => |frame_index| imulRaxFrameSlotInstructionSize(frame_index),
        .mul_rax_arg64_full, .imul_rax_arg64_full => |reg| if (reg.rexB()) 4 else 3,
        .xor_edx_edx => 2,
        .div_arg32 => |reg| if (reg.rexB()) 3 else 2,
        .div_arg64, .idiv_arg64 => |reg| if (reg.rexB()) 4 else 3,
        .add_arg64_rax => 3,
        .add_arg64_imm32 => 7,
        .add_arg_high32_eax => |reg| (if (reg.rexR()) @as(u32, 3) else 3) + 6,
        .add_stack_disp8_eax => 4,
        .add_stack_disp8_rax => 5,
        .add_stack_disp32_eax => 7,
        .add_stack_disp32_rax => 8,
        .add_eax_imm32 => 5,
        .shl_eax_imm5, .shr_eax_imm5, .sar_eax_imm5 => 3,
        .shr_arg_imm5 => |shift| if (shift.reg.rexB()) 4 else 3,
        .shr_arg64_imm6, .sar_arg64_imm6 => 4,
        .shl_eax_cl, .shr_eax_cl, .sar_eax_cl => 2,
        .shl_rax_cl, .shr_rax_cl, .sar_rax_cl => 3,
        .fshl_eax_arg32_imm5 => |shift| if (shift.reg.rexR()) 5 else 4,
        .or_eax_imm32 => 5,
        .imul_eax_imm32 => 6,
        .and_eax_imm32 => 5,
        .xor_eax_imm32 => 5,
        .abs_i32_edi_eax => 11,
        .abs_i64_rdi_rax => 16,
        .wide_int_to_fp_rdi_rsi_xmm0 => |conversion| switch (conversion.to_bits) {
            32 => if (conversion.signed) selector_bytes.wide_sitofp_i128_f32.len else selector_bytes.wide_uitofp_i128_f32.len,
            64 => if (conversion.signed) selector_bytes.wide_sitofp_i128_f64.len else selector_bytes.wide_uitofp_i128_f64.len,
            else => 0,
        },
        .clz_i128_rdi_rsi_eax => 34,
        .clz_i64_rdi_eax => 17,
        .clz_i32_edi_eax => 15,
        .ctz_i32_edi_eax => 12,
        .popcount_i32_edi_eax => 21,
        .popcount_rax => 27,
        .bit_reverse_i32_edi_eax => 65,
        .bit_reverse_rax => 93,
        .ushl_sat_i32_edi_imm_eax => 20,
        .bswap_eax => 2,
        .bswap_rax => 3,
        .rol_ax_imm8 => 4,
        .shr_rax_imm6 => 4,
        .shl_rax_imm6 => 4,
        .shl_rdx_imm6 => 4,
        .or_rdx_rax => 3,
        .neg_rax => 3,
        .neg_i128_rdi_rsi_rdx_rax => 16,
        .ctz_i128_rdi_rsi_eax => 28,
        .ctz_i64_rdi_eax => 14,
        .ffs_i128_rdi_rsi_eax => 28,
        .ffs_i64_rdi_eax => 14,
        .ffs_i32_edi_eax => 12,
        .shl_rcx_imm6 => 4,
        .shl_r8_imm6 => 4,
        .or_rcx_rax => 3,
        .or_rcx_rdx => 3,
        .add_rax_imm8 => 4,
        .add_rcx_imm32 => 7,
        .add_r8_rcx => 3,
        .sub_r8_rcx => 3,
        .add_ecx_eax => 2,
        .xor_ecx_ecx => 2,
        .xor_ebp_ebp => 2,
        .add_rdi_rcx4_ptr_eax => 3,
        .load_rdi_rcx4_ptr_r8d => 4,
        .load_rdi_ptr_u8_eax, .load_rdi_ptr_u16_eax => 3,
        .load_rdi_ptr_eax => 2,
        .load_rdi_ptr_rax => 3,
        .atomic_fetch_umin_i8_rdi_sil_eax => 21,
        .atomic_fetch_umin_i16_rdi_si_eax => 22,
        .atomic_fetch_umin_i32_rdi_esi_eax => 15,
        .atomic_fetch_umin_i64_rdi_rsi_rax => 20,
        .atomic_fetch_umax_i8_rdi_sil_eax => 21,
        .atomic_fetch_umax_i16_rdi_si_eax => 22,
        .atomic_fetch_umax_i32_rdi_esi_eax => 15,
        .atomic_fetch_umax_i64_rdi_rsi_rax => 20,
        .atomic_fetch_nand_i8_rdi_sil_eax => 19,
        .atomic_fetch_nand_i16_rdi_si_eax => 21,
        .atomic_fetch_nand_i32_rdi_esi_eax => 14,
        .atomic_fetch_nand_i64_rdi_rsi_rax => 19,
        .atomic_fetch_xor_i8_rdi_sil_eax => 17,
        .atomic_fetch_xor_i16_rdi_si_eax => 18,
        .atomic_fetch_xor_i32_rdi_esi_eax => 12,
        .atomic_fetch_xor_i64_rdi_rsi_rax => 16,
        .atomic_fetch_or_i8_rdi_sil_eax => 17,
        .atomic_fetch_or_i16_rdi_si_eax => 18,
        .atomic_fetch_or_i32_rdi_esi_eax => 12,
        .atomic_fetch_or_i64_rdi_rsi_rax => 16,
        .atomic_fetch_and_i8_rdi_sil_eax => 17,
        .atomic_fetch_and_i16_rdi_si_eax => 18,
        .atomic_fetch_and_i32_rdi_esi_eax => 12,
        .atomic_fetch_and_i64_rdi_rsi_rax => 16,
        .atomic_fetch_sub_i8_rdi_sil_eax => 17,
        .atomic_fetch_sub_i16_rdi_si_eax => 18,
        .atomic_fetch_sub_i32_rdi_esi_eax => 12,
        .atomic_fetch_sub_i64_rdi_rsi_rax => 16,
        .atomic_fetch_add_i8_rdi_sil_eax => 17,
        .atomic_fetch_add_i16_rdi_si_eax => 18,
        .atomic_fetch_add_i32_rdi_esi_eax => 12,
        .atomic_fetch_add_i64_rdi_rsi_rax => 16,
        .store_eax_rdi_rcx4_ptr => 3,
        .load_rcx_ptr_u8_eax => 3,
        .load_rcx_ptr_u16_eax => 3,
        .load_rcx_ptr_eax => 2,
        .load_rcx_ptr_rax => 3,
        .store_al_rcx_ptr => 2,
        .store_ax_rcx_ptr => 3,
        .store_eax_rcx_ptr => 2,
        .store_rax_rcx_ptr => 3,
        .cmp_r8d_arg32 => |reg| if (reg.rexR()) 4 else 3,
        .add_r8d_eax => 3,
        .inc_rcx => 3,
        .movzx_dil_edi, .load_rax_rdi_u8_eax => 4,
        .bcmp_rdi_rsi_rdx_eax => 33,
        .memcmp_rdi_rsi_rdx_eax => 36,
        .memcpy_rdi_rsi_rdx_rax => 14,
        .abs_limb64_rdi_rsi_dx_rcx_rax => 69,
        .mulo_limb64_rdi_rsi_rdx_cl_r8w_al => selector_bytes.mulo_limb64_rdi_rsi_rdx_cl_r8w_al.len,
        .byteswap_limb64_rdi_rsi_dl_cx => selector_bytes.byteswap_limb64_rdi_rsi_dl_cx.len,
        .shr_limb64_rdi_rsi_dx_cl_r8w => selector_bytes.shr_limb64_rdi_rsi_dx_cl_r8w.len,
        .shlo_limb64_rdi_rsi_dx_cl_r8w_al => selector_bytes.shlo_limb64_rdi_rsi_dx_cl_r8w_al.len,
        .not_limb64_rdi_rsi_dl_cx => selector_bytes.not_limb64_rdi_rsi_dl_cx.len,
        .bitwise_limb64_rdi_rsi_rdx_cx => |op| switch (op) {
            .xor => selector_bytes.xor_limb64_rdi_rsi_rdx_cx.len,
            .@"or" => selector_bytes.or_limb64_rdi_rsi_rdx_cx.len,
            .@"and" => selector_bytes.and_limb64_rdi_rsi_rdx_cx.len,
        },
        .cmp_limb64_rdi_rsi_dl_cx_ax => selector_bytes.cmp_limb64_rdi_rsi_dl_cx_ax.len,
        .overflow_limb64_rdi_rsi_rdx_cl_r8w_al => |op| switch (op) {
            .add => selector_bytes.addo_limb64_rdi_rsi_rdx_cl_r8w_al.len,
            .sub => selector_bytes.subo_limb64_rdi_rsi_rdx_cl_r8w_al.len,
        },
        .bitreverse_limb64_rdi_rsi_dl_cx => selector_bytes.bitreverse_limb64_rdi_rsi_dl_cx.len,
        .popcount_limb64_rdi_si_ax => selector_bytes.popcount_limb64_rdi_si_ax.len,
        .ctz_limb64_rdi_si_ax => selector_bytes.ctz_limb64_rdi_si_ax.len,
        .clz_limb64_rdi_si_ax => selector_bytes.clz_limb64_rdi_si_ax.len,
        .udivei4_before_intbytesize => selector_bytes.udivei4_before_intbytesize.len,
        .udivei4_between_intbytesize_and_memset => selector_bytes.udivei4_between_intbytesize_and_memset.len,
        .udivei4_after_memset => selector_bytes.udivei4_after_memset.len,
        .umodei5_before_intbytesize => selector_bytes.umodei5_before_intbytesize.len,
        .umodei5_between_intbytesize_and_memset => selector_bytes.umodei5_between_intbytesize_and_memset.len,
        .umodei5_after_memset_before_memcpy => selector_bytes.umodei5_after_memset_before_memcpy.len,
        .umodei5_after_memcpy => selector_bytes.umodei5_after_memcpy.len,
        .spinlocked_memcpy_rsi_to_rdx_len_edi => 59,
        .spinlocked_var_cmpxchg_edi_rsi_rdx_rcx_eax => 104,
        .spinlocked_var_xchg_edi_rsi_rdx_rcx => 82,
        .spinlocked_var_store_edi_rsi_rdx => 69,
        .cmpxchg_ptr_expected_desired_i8_eax => 19,
        .cmpxchg_ptr_expected_desired_i16_eax => 22,
        .cmpxchg_ptr_expected_desired_i32_eax => 19,
        .cmpxchg_ptr_expected_desired_i64_eax => 22,
        .spinlocked_cmpxchg_i128_rdi_rsi_rdx_rcx_eax => 88,
        .xchg_ptr_value_i8_eax => 8,
        .xchg_ptr_value_i16_eax => 9,
        .xchg_ptr_value_i32_eax => 4,
        .xchg_ptr_value_i64_rax => 6,
        .atomic_xchg_rdi_disp8_rax => 4,
        .spinlocked_xchg_i128_rdi_rsi_rdx_rax => 66,
        .spinlocked_store_i128_rdi_rsi_rdx => 56,
        .spinlocked_load_i128_rdi_rax_rdx => 53,
        .spinlocked_fetch_umin_i128_rdi_rsi_rdx_rax_rdx => 75,
        .spinlocked_fetch_umax_i128_rdi_rsi_rdx_rax_rdx => 75,
        .spinlocked_fetch_nand_i128_rdi_rsi_rdx_rax_rdx => 81,
        .spinlocked_fetch_xor_i128_rdi_rsi_rdx_rax_rdx => 75,
        .spinlocked_fetch_or_i128_rdi_rsi_rdx_rax_rdx => 75,
        .spinlocked_fetch_and_i128_rdi_rsi_rdx_rax_rdx => 75,
        .spinlocked_fetch_sub_i128_rdi_rsi_rdx_rax_rdx => 75,
        .spinlocked_fetch_add_i128_rdi_rsi_rdx_rax_rdx => 75,
        .memmove_rdi_rsi_rdx_rax => 38,
        .stack_probe_rax_rcx_rsp => 53,
        .guarded_memset_rdi_sil_rdx_rcx_rax => 29,
        .guarded_memcpy_rdi_rsi_rdx_rcx_rax => 24,
        .guarded_strncat_rdi_rsi_rdx_rcx_rax => 74,
        .guarded_strcat_rdi_rsi_rdx_rax => 66,
        .guarded_strncpy_rdi_rsi_rdx_rcx_rax => 55,
        .guarded_strcpy_rdi_rsi_rdx_rax => 42,
        .memset_rdi_sil_rdx_rax => 22,
        .strlen_rdi_rax => 13,
        .strnlen_rdi_rsi_rax => 18,
        .atomic_try_lock_rdi_al => 14,
        .and_edi_imm8 => 3,
        .smin_i32_edi_esi_eax, .umin_i32_edi_esi_eax, .smax_i32_edi_esi_eax, .umax_i32_edi_esi_eax => 7,
        .shift_mix_i32_edi_esi_eax => 15,
        .replace_low_i8_dil_sil_al => 12,
        .read_flag_i8_dil_al => 8,
        .ult_i8_dil_imm8_al => 9,
        .cmp_ult_u32_edi_esi_al => 7,
        .ascii_range_u8_dil_imm8_imm8_al => 12,
        .range_u32_edi_imm32_imm32_al => 17,
        .ascii_alphabetic_dil_al => 14,
        .ascii_alphanumeric_dil_al => 28,
        .ascii_whitespace_dil_al => 21,
        .ascii_control_dil_al => 18,
        .grow_capacity_u64_rdi_imm32_rax => |imm| if (imm >= -128 and imm <= 127) 24 else 27,
        .store_imm8_abs => 8,
        .cmp_ecx_arg32 => |reg| if (reg.rexB()) 3 else 2,
        .cmp_rcx_arg64 => 3,
        .cmp_ecx_imm32 => 6,
        .cmp_eax_imm32 => 5,
        .cmp_arg64_imm64 => |cmp| if (cmp.reg.rexB()) 14 else 13,
        .cmp_arg16_imm16 => |cmp| if (cmp.reg.rexB()) 6 else 5,
        .cmp_rdi_imm64 => 13,
        .cmp_rdx_rcx => 3,
        .cmp_rdx_rdi => 3,
        .cmp_rax_rdx => 3,
        .setb_eax, .seta_eax, .sete_eax, .setg_eax, .setl_eax, .setne_eax, .setbe_eax => 6,
        .test_eax_eax => 2,
        .test_rax_rax, .test_rdx_rdx => 3,
        .mulsd_xmm1_xmm0, .mulsd_xmm => 4,
        .mulss_xmm1_xmm0, .mulss_xmm => 4,
        .subsd_xmm, .subss_xmm, .divsd_xmm, .divss_xmm, .addsd_xmm, .addss_xmm => 4,
        .addss_xmm1_xmm0 => 4,
        .subss_xmm1_xmm0 => 4,
        .divsd_xmm1_xmm0, .xorps_xmm1_xmm0 => 4,
        .movapd_xmm1_xmm0, .movapd_xmm, .addpd_xmm, .subpd_xmm, .mulpd_xmm, .movsd_xmm, .movss_xmm, .unpcklpd_xmm, .unpckhpd_xmm => 4,
        .shufpd_xmm => 5,
        .addps_xmm, .subps_xmm, .mulps_xmm, .andps_xmm => 3,
        .pxor_xmm, .pcmpgtd_xmm, .movmskpd_xmm_eax => 4,
        .cmpeqps_xmm => 4,
        .cmpeqpd_xmm => 5,
        .movmskps_xmm_eax => 3,
        .unpcklps_xmm => 3,
        .shufps_high_f32_to_low, .shufps_xmm => 4,
        .cvtsi2ss_edi_xmm0 => 4,
        .cvtsi2sd_edi_xmm0 => 4,
        .cvtsi2ss_rdi_xmm0 => 5,
        .cvtsi2sd_rdi_xmm0 => 5,
        .cvttss2si_xmm0_eax => 4,
        .cvttsd2si_xmm0_eax => 4,
        .cvtsd2ss_xmm0_xmm0, .cvtsd2ss_xmm => 4,
        .cvtss2sd_xmm0_xmm0, .cvtss2sd_xmm => 4,
        .mov_edi_edi => 2,
        .mov_imm64_xmm0 => 15,
        .mov_imm64_xmm1 => 15,
        .mov_imm32_xmm0 => 9,
        .mov_imm32_xmm1 => 9,
        .mov_imm64_xmm => 15,
        .mov_imm32_xmm => 9,
        .ucomisd => 4,
        .ucomiss => 3,
        .set_fcmp_eax => |predicate| fcmpResultSize(predicate),
        .ucomisd_xmm1_xmm0 => 4,
        .ucomiss_xmm1_xmm0 => 3,
        .ucomiss_xmm0_xmm1 => 3,
        .oltss_xmm0_xmm1_al => 8,
        .fneg_x86_fp80_stack8_st0 => 6,
        .fneg_fp128_xmm0 => 23,
        .addsd_xmm1_xmm0 => 4,
        .sub_rsp_8, .add_rsp_8 => 4,
        .push_imm32 => 5,
        .push_stack_disp8 => 4,
        .push_stack_disp32 => 7,
        .sub_rsp_24, .add_rsp_24, .sub_rsp_40, .add_rsp_40, .sub_rsp_56, .add_rsp_56, .sub_rsp_imm8, .add_rsp_imm8 => 4,
        .sub_rsp_imm32, .add_rsp_imm32 => 7,
        .spill_arg_rsp => |spill| frameSlotInstructionSize(spill.reg, spill.frame_index),
        .spill_arg64_rsp => |spill| frameSlotInstructionSize64(spill.reg, spill.frame_index),
        .reload_arg_rsp => |reload| frameSlotInstructionSize(reload.reg, reload.frame_index),
        .reload_arg64_rsp => |reload| frameSlotInstructionSize64(reload.reg, reload.frame_index),
        .spill_xmm32_rsp => |spill| xmmFrameSlotInstructionSize(spill.frame_index),
        .reload_xmm32_rsp => |reload| xmmFrameSlotInstructionSize(reload.frame_index),
        .spill_xmm64_rsp => |spill| xmmFrameSlotInstructionSize(spill.frame_index),
        .reload_xmm64_rsp => |reload| xmmFrameSlotInstructionSize(reload.frame_index),
        .spill_xmm128_rsp => |spill| xmmFrameSlotInstructionSize(spill.frame_index),
        .reload_xmm128_rsp => |reload| xmmFrameSlotInstructionSize(reload.frame_index),
        .spill_xmm128ps_rsp => |spill| xmmFrameSlotInstructionSize(spill.frame_index) - 1,
        .reload_xmm128ps_rsp => |reload| xmmFrameSlotInstructionSize(reload.frame_index) - 1,
        .spill_rdi_rsi_rsp24 => 10,
        .reload_rdi_rsp24, .reload_rsi_rsp24 => 5,
        .spill_eax_rsp => |frame_index| eaxFrameSlotInstructionSize(frame_index),
        .reload_rsp_eax => |frame_index| eaxFrameSlotInstructionSize(frame_index),
        .spill_rax_rsp, .reload_rsp_rax => |frame_index| raxFrameSlotInstructionSize(frame_index),
        .load_stack_disp8_eax => 4,
        .load_stack_disp32_eax => 7,
        .load_stack_rcx4_disp8_eax => 4,
        .load_stack_rcx4_disp32_eax => 7,
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
        .load_stack_disp8_xmm_f32 => 6,
        .load_stack_disp32_xmm_f32 => 9,
        .load_stack_disp8_arg32 => |load| if (load.reg.rexR()) 5 else 4,
        .load_stack_disp8_arg64 => 5,
        .load_stack_disp32_arg32 => |load| if (load.reg.rexR()) 8 else 7,
        .load_stack_disp32_arg64 => 8,
        .load_rax_ptr_disp8_rax => |offset| 3 + if (offset == 0) @as(u32, 0) else 1,
        .load_rax_ptr_disp32_rax => 7,
        .load_rax_ptr_disp8_u8_eax => |offset| 3 + if (offset == 0) @as(u32, 0) else 1,
        .load_rax_ptr_disp8_u16_eax => |offset| 3 + if (offset == 0) @as(u32, 0) else 1,
        .load_rax_ptr_disp8_eax => |offset| 2 + if (offset == 0) @as(u32, 0) else 1,
        .load_rax_ptr_rdx => 3,
        .load_rax_ptr_eax => 2,
        .load_arg_ptr_eax => |reg| if (reg.rexB()) 3 else 2,
        .load_arg_ptr_disp8_rax => |load| 3 + if (load.offset == 0) @as(u32, 0) else 1,
        .load_arg_ptr_disp32_rax => |load| (if (load.reg.rexB()) @as(u32, 1) else 0) + 6,
        .load_arg_ptr_disp8_eax => |load| (if (load.reg.rexB()) @as(u32, 1) else 0) + 2 + if (load.offset == 0) @as(u32, 0) else 1,
        .load_arg_ptr_disp8_u8_eax => |load| (if (load.reg.rexB()) @as(u32, 1) else 0) + 3 + if (load.offset == 0) @as(u32, 0) else 1,
        .load_arg_ptr_disp8_u16_eax => |load| (if (load.reg.rexB()) @as(u32, 1) else 0) + 3 + if (load.offset == 0) @as(u32, 0) else 1,
        .load_arg_ptr_disp8_u16_arg => |load| (if (load.base.rexB() or load.dst.rexR()) @as(u32, 1) else 0) + 3 + if (load.offset == 0) @as(u32, 0) else 1,
        .load_arg_ptr_disp8_xmm => |load| 4 + (if (load.base.rexB()) @as(u32, 1) else 0) + if (load.offset == 0) @as(u32, 0) else 1,
        .add_arg_ptr_disp4_eax => |reg| if (reg.rexB()) 4 else 3,
        .inc_arg_ptr_disp8 => |inc| 2 + if (inc.offset == 0) @as(u32, 1) else 2,
        .store_eax_arg_ptr => |reg| if (reg.rexB()) 3 else 2,
        .store_imm64_arg_ptr_disp8 => |store| 7 + if (store.offset == 0) @as(u32, 0) else 1,
        .store_arg64_arg_ptr_disp8 => |store| 3 + if (store.offset == 0) @as(u32, 0) else 1,
        .store_arg64_arg_ptr_disp32 => 7,
        .store_rax_arg_ptr_disp8 => |store| 3 + if (store.offset == 0) @as(u32, 0) else 1,
        .store_rax_arg_ptr_disp32 => 7,
        .store_eax_arg_ptr_disp8 => |store| (if (store.reg.rexB()) @as(u32, 1) else 0) + 2 + if (store.offset == 0) @as(u32, 0) else 1,
        .store_eax_arg_ptr_disp32 => |store| (if (store.reg.rexB()) @as(u32, 1) else 0) + 6,
        .store_eax_stack_disp8 => 4,
        .store_eax_stack_disp32 => 7,
        .store_al_stack_disp8 => 4,
        .store_al_stack_disp32 => 7,
        .store_eax_stack_rcx4_disp8 => 4,
        .store_eax_stack_rcx4_disp32 => 7,
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
        .load_global_ptr_rax, .lea_global_rax, .lea_global_offset_rax, .lea_global_rdi, .lea_global_rsi, .lea_global_rdx, .lea_global_arg64 => 7,
        .load_tls_i32_eax, .add_tls_i32_eax, .store_eax_tls_i32 => 8,
        .atomic_xadd_global_eax => 8,
        .mov_rsp_rdi => 3,
        .and_rsp_neg16 => 4,
        .direct_call, .noreturn_direct_call => 5,
        .direct_jump => 5,
        .indirect_call_rax => 2,
        .indirect_jump => |jump| if (jump.reg == .r8 or jump.reg == .r9) 3 else 2,
        .cmp_arg8_imm8 => |cmp| if (cmp.reg.needsRex8()) 4 else 3,
        .test_arg8 => |reg| if (reg.needsRex8()) 3 else 2,
        .test_arg32 => |reg| if (reg.rexR()) 3 else 2,
        .test_arg64 => 3,
        .base64_raw_args_to_decode4_regs => @intCast(base64RawArgsToDecode4RegsBytes().len),
        .base64_decode4_from_table_rax => @intCast(base64Decode4FromTableRaxBytes().len),
        .syscall => 2,
        .ud2 => 2,
        .je, .jne, .jo, .jc, .jp, .js, .jae, .jle => 6,
        .jmp => 5,
        .ret => 1,
    };
}
