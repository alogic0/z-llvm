const std = @import("std");
const x86_64 = @import("../codegen/x86_64.zig");
const selector_bytes = @import("../codegen/x86_64/selector_bytes.zig");

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
            .shr_eax_imm5 => |amount| {
                try bytes.appendSlice(allocator, &.{ 0xc1, 0xe8 });
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
            .abs_i64_rdi_rax => try bytes.appendSlice(allocator, &.{ 0x48, 0x89, 0xf8, 0x48, 0x89, 0xfa, 0x48, 0xf7, 0xda, 0x48, 0x85, 0xff, 0x48, 0x0f, 0x48, 0xc2 }),
            .clz_i128_rdi_rsi_eax => try bytes.appendSlice(allocator, &.{
                0x48, 0x85, 0xf6, 0x74, 0x09, 0x48, 0x0f, 0xbd, 0xc6, 0x83, 0xf0, 0x3f, 0xeb, 0x14,
                0xb8, 0x80, 0x00, 0x00, 0x00, 0x48, 0x85, 0xff, 0x74, 0x0a, 0x48, 0x0f, 0xbd, 0xc7,
                0x83, 0xf0, 0x3f, 0x83, 0xc0, 0x40,
            }),
            .clz_i64_rdi_eax => try bytes.appendSlice(allocator, &.{ 0xb8, 0x40, 0x00, 0x00, 0x00, 0x48, 0x85, 0xff, 0x74, 0x07, 0x48, 0x0f, 0xbd, 0xc7, 0x83, 0xf0, 0x3f }),
            .clz_i32_edi_eax => try bytes.appendSlice(allocator, &.{ 0xb8, 0x20, 0x00, 0x00, 0x00, 0x85, 0xff, 0x74, 0x06, 0x0f, 0xbd, 0xc7, 0x83, 0xf0, 0x1f }),
            .ctz_i32_edi_eax => try bytes.appendSlice(allocator, &.{ 0xb8, 0x20, 0x00, 0x00, 0x00, 0x85, 0xff, 0x74, 0x03, 0x0f, 0xbc, 0xc7 }),
            .popcount_i32_edi_eax => try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0xb8, 0xc7 }),
            .bit_reverse_i32_edi_eax => try bytes.appendSlice(allocator, &.{
                0x89, 0xf8, 0x0f, 0xc8, 0x89, 0xc2, 0xc1, 0xe8, 0x04, 0x25, 0x0f, 0x0f, 0x0f, 0x0f,
                0x81, 0xe2, 0x0f, 0x0f, 0x0f, 0x0f, 0xc1, 0xe2, 0x04, 0x09, 0xd0, 0x89, 0xc2, 0xc1,
                0xe8, 0x02, 0x25, 0x33, 0x33, 0x33, 0x33, 0x81, 0xe2, 0x33, 0x33, 0x33, 0x33, 0xc1,
                0xe2, 0x02, 0x09, 0xd0, 0x89, 0xc2, 0xd1, 0xe8, 0x25, 0x55, 0x55, 0x55, 0x55, 0x81,
                0xe2, 0x55, 0x55, 0x55, 0x55, 0xd1, 0xe2, 0x09, 0xd0,
            }),
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
            .smin_i32_edi_esi_eax => try bytes.appendSlice(allocator, &.{ 0x89, 0xf8, 0x39, 0xf7, 0x0f, 0x4f, 0xc6 }),
            .umin_i32_edi_esi_eax => try bytes.appendSlice(allocator, &.{ 0x89, 0xf8, 0x39, 0xf7, 0x0f, 0x47, 0xc6 }),
            .smax_i32_edi_esi_eax => try bytes.appendSlice(allocator, &.{ 0x89, 0xf8, 0x39, 0xf7, 0x0f, 0x4c, 0xc6 }),
            .umax_i32_edi_esi_eax => try bytes.appendSlice(allocator, &.{ 0x89, 0xf8, 0x39, 0xf7, 0x0f, 0x42, 0xc6 }),
            .shift_mix_i32_edi_esi_eax => try bytes.appendSlice(allocator, &.{ 0x89, 0xf1, 0x83, 0xe1, 0x1f, 0x89, 0xf8, 0xd3, 0xe0, 0x89, 0xfa, 0xd3, 0xea, 0x31, 0xd0 }),
            .replace_low_i8_dil_sil_al => try bytes.appendSlice(allocator, &.{ 0x89, 0xf8, 0x83, 0xe0, 0xf8, 0x89, 0xf2, 0x83, 0xe2, 0x07, 0x09, 0xd0 }),
            .read_flag_i8_dil_al => try bytes.appendSlice(allocator, &.{ 0x31, 0xc0, 0x40, 0x84, 0xff, 0x0f, 0x98, 0xc0 }),
            .ult_i8_dil_imm8_al => |imm| try bytes.appendSlice(allocator, &.{ 0x31, 0xc0, 0x40, 0x80, 0xff, imm, 0x0f, 0x92, 0xc0 }),
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
            .test_eax_eax => try bytes.appendSlice(allocator, &.{ 0x85, 0xc0 }),
            .test_rax_rax => try bytes.appendSlice(allocator, &.{ 0x48, 0x85, 0xc0 }),
            .test_rdx_rdx => try bytes.appendSlice(allocator, &.{ 0x48, 0x85, 0xd2 }),
            .mulsd_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x59, 0xc1 }),
            .mulss_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x59, 0xc1 }),
            .addss_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x58, 0xc1 }),
            .subss_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf3, 0x0f, 0x5c, 0xc1 }),
            .divsd_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0xf2, 0x0f, 0x5e, 0xc1 }),
            .xorps_xmm1_xmm0 => try bytes.appendSlice(allocator, &.{ 0x0f, 0x57, 0xc1 }),
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
            .load_stack_disp8_eax => |disp| {
                try bytes.appendSlice(allocator, &.{ 0x8b, 0x44, 0x24 });
                try bytes.append(allocator, disp);
            },
            .load_stack_disp32_eax => |disp| {
                try bytes.appendSlice(allocator, &.{ 0x8b, 0x84, 0x24 });
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
        .mov_rax_rsi => 3,
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
        .add_arg64_rax => 3,
        .add_arg_high32_eax => |reg| (if (reg.rexR()) @as(u32, 3) else 3) + 6,
        .add_stack_disp8_eax => 4,
        .add_stack_disp8_rax => 5,
        .add_stack_disp32_eax => 7,
        .add_stack_disp32_rax => 8,
        .add_eax_imm32 => 5,
        .shl_eax_imm5 => 3,
        .shr_eax_imm5 => 3,
        .or_eax_imm32 => 5,
        .imul_eax_imm32 => 6,
        .and_eax_imm32 => 5,
        .abs_i64_rdi_rax => 16,
        .clz_i128_rdi_rsi_eax => 34,
        .clz_i64_rdi_eax => 17,
        .clz_i32_edi_eax => 15,
        .ctz_i32_edi_eax => 12,
        .popcount_i32_edi_eax => 4,
        .bit_reverse_i32_edi_eax => 65,
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
        .and_edi_imm8 => 3,
        .smin_i32_edi_esi_eax, .umin_i32_edi_esi_eax, .smax_i32_edi_esi_eax, .umax_i32_edi_esi_eax => 7,
        .shift_mix_i32_edi_esi_eax => 15,
        .replace_low_i8_dil_sil_al => 12,
        .read_flag_i8_dil_al => 8,
        .ult_i8_dil_imm8_al => 9,
        .store_imm8_abs => 8,
        .cmp_ecx_arg32 => |reg| if (reg.rexB()) 3 else 2,
        .cmp_rcx_arg64 => |reg| if (reg.rexB()) 4 else 3,
        .cmp_ecx_imm32 => 6,
        .cmp_eax_imm32 => 5,
        .cmp_arg64_imm64 => |cmp| if (cmp.reg.rexB()) 14 else 13,
        .cmp_arg16_imm16 => |cmp| if (cmp.reg.rexB()) 6 else 5,
        .cmp_rdi_imm64 => 13,
        .cmp_rdx_rcx => 3,
        .cmp_rdx_rdi => 3,
        .cmp_rax_rdx => 3,
        .test_eax_eax => 2,
        .test_rax_rax, .test_rdx_rdx => 3,
        .mulsd_xmm1_xmm0 => 4,
        .mulss_xmm1_xmm0 => 4,
        .addss_xmm1_xmm0 => 4,
        .subss_xmm1_xmm0 => 4,
        .divsd_xmm1_xmm0, .xorps_xmm1_xmm0 => 4,
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
        .fneg_x86_fp80_stack8_st0 => 6,
        .fneg_fp128_xmm0 => 23,
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
        .load_stack_disp8_eax => 4,
        .load_stack_disp32_eax => 7,
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
        .syscall => 2,
        .ud2 => 2,
        .je, .jne, .jo, .jc, .jp, .js, .jae, .jle => 6,
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
        .slot11 => 44,
        .slot12 => 48,
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

fn encodeArgPtrDisp32ToRax(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, reg: x86_64.ArgReg, offset: u32) !void {
    try bytes.append(allocator, if (reg.rexB()) 0x49 else 0x48);
    try bytes.append(allocator, 0x8b);
    try bytes.append(allocator, 0x80 | @as(u8, reg.lowCode()));
    try appendU32(bytes, allocator, offset);
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
