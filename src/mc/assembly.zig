const std = @import("std");
const x86_64 = @import("../codegen/x86_64.zig");
const selector_bytes = @import("../codegen/x86_64/selector_bytes.zig");

pub fn printFunction(function: x86_64.MachineFunction, writer: anytype) !void {
    try writer.writeAll("\t.text\n");
    try writer.print("\t.globl {s}\n", .{function.name});
    try writer.print("{s}:\n", .{function.name});
    for (function.instructions.items) |instruction| {
        switch (instruction) {
            .label => |label| try writer.print(".L{s}_{s}:\n", .{ function.name, label }),
            .mov_imm_eax => |value| try writer.print("\tmovl ${}, %eax\n", .{value}),
            .mov_imm_rax => |value| try writer.print("\tmovabsq ${}, %rax\n", .{value}),
            .mov_imm_rdi => |value| try writer.print("\tmovabsq ${}, %rdi\n", .{value}),
            .mov_imm_rdx => |value| try writer.print("\tmovabsq ${}, %rdx\n", .{value}),
            .mov_imm_rsi => |value| try writer.print("\tmovabsq ${}, %rsi\n", .{value}),
            .mov_imm_rcx => |value| try writer.print("\tmovabsq ${}, %rcx\n", .{value}),
            .mov_imm_r8 => |value| try writer.print("\tmovabsq ${}, %r8\n", .{value}),
            .mov_imm_r9 => |value| try writer.print("\tmovabsq ${}, %r9\n", .{value}),
            .mov_rax_rdi => try writer.writeAll("\tmovq %rax, %rdi\n"),
            .mov_rax_rsi => try writer.writeAll("\tmovq %rax, %rsi\n"),
            .mov_arg_rax => |reg| try writer.print("\tmovq {s}, %rax\n", .{reg.name64()}),
            .movq_xmm_rax => |reg| try writer.print("\tmovq {s}, %rax\n", .{reg.name()}),
            .movq_rax_xmm => |reg| try writer.print("\tmovq %rax, {s}\n", .{reg.name()}),
            .movd_xmm_eax => |reg| try writer.print("\tmovd {s}, %eax\n", .{reg.name()}),
            .movd_eax_xmm => |reg| try writer.print("\tmovd %eax, {s}\n", .{reg.name()}),
            .mov_arg_eax => |reg| try writer.print("\tmovl {s}, %eax\n", .{reg.name32()}),
            .mov_eax_to_arg => |reg| try writer.print("\tmovl %eax, {s}\n", .{reg.name32()}),
            .mov_rax_to_arg => |reg| try writer.print("\tmovq %rax, {s}\n", .{reg.name64()}),
            .mov_arg_arg => |mov| try writer.print("\tmovl {s}, {s}\n", .{ mov.src.name32(), mov.dst.name32() }),
            .mov_arg64_arg => |mov| try writer.print("\tmovq {s}, {s}\n", .{ mov.src.name64(), mov.dst.name64() }),
            .mov_rsp_arg64 => |reg| try writer.print("\tmovq %rsp, {s}\n", .{reg.name64()}),
            .movsxd_arg32_arg64 => |mov| try writer.print("\tmovslq {s}, {s}\n", .{ mov.src.name32(), mov.dst.name64() }),
            .push_arg => |reg| try writer.print("\tpushq {s}\n", .{reg.name64()}),
            .pop_arg => |reg| try writer.print("\tpopq {s}\n", .{reg.name64()}),
            .push_rax => try writer.writeAll("\tpushq %rax\n"),
            .push_xmm64 => |reg| try writer.print("\tsubq $8, %rsp\n\tmovsd {s}, (%rsp)\n", .{reg.name()}),
            .push_byval_tail_arg_ptr => |copy| {
                try writer.writeAll("\tsubq $8, %rsp\n\tmovq $0, (%rsp)\n");
                var index: u8 = 0;
                while (index < copy.len) : (index += 1) {
                    try writer.print("\tmovzbl {}({s}), %eax\n\tmovb %al, {}(%rsp)\n", .{ copy.offset + index, copy.reg.name64(), index });
                }
            },
            .push_byval_tail_stack_ptr => |copy| {
                try writer.print("\tmovq {}(%rsp), %rdx\n\tsubq $8, %rsp\n\tmovq $0, (%rsp)\n", .{copy.stack_disp});
                var index: u8 = 0;
                while (index < copy.len) : (index += 1) {
                    try writer.print("\tmovzbl {}(%rdx), %eax\n\tmovb %al, {}(%rsp)\n", .{ copy.offset + index, index });
                }
            },
            .binary_arg_eax => |binary| try writer.print("\t{s} {s}, %eax\n", .{ binary.op.mnemonic(), binary.reg.name32() }),
            .binary_arg_rax => |binary| try writer.print("\t{s} {s}, %rax\n", .{ binary.op.mnemonic64(), binary.reg.name64() }),
            .sbb_arg64_rax => |reg| try writer.print("\tsbbq {s}, %rax\n", .{reg.name64()}),
            .adc_rax_imm0 => try writer.writeAll("\tadcq $0, %rax\n"),
            .imul_eax_arg32 => |src| try writer.print("\timull {s}, %eax\n", .{src.name32()}),
            .imul_arg64_arg64 => |imul| try writer.print("\timulq {s}, {s}\n", .{ imul.src.name64(), imul.dst.name64() }),
            .imul_arg64_rax => |dst| try writer.print("\timulq %rax, {s}\n", .{dst.name64()}),
            .imul_rax_arg64 => |src| try writer.print("\timulq {s}, %rax\n", .{src.name64()}),
            .imul_rax_rsp => |frame_index| {
                try writer.writeAll("\timulq ");
                try printFrameAddress(writer, frame_index);
                try writer.writeAll(", %rax\n");
            },
            .mul_rax_arg64_full => |src| try writer.print("\tmulq {s}\n", .{src.name64()}),
            .imul_rax_arg64_full => |src| try writer.print("\timulq {s}\n", .{src.name64()}),
            .xor_edx_edx => try writer.writeAll("\txorl %edx, %edx\n"),
            .div_arg32 => |reg| try writer.print("\tdivl {s}\n", .{reg.name32()}),
            .div_arg64 => |reg| try writer.print("\tdivq {s}\n", .{reg.name64()}),
            .add_arg64_rax => |reg| try writer.print("\taddq {s}, %rax\n", .{reg.name64()}),
            .add_arg64_imm32 => |add| try writer.print("\taddq ${}, {s}\n", .{ add.imm, add.reg.name64() }),
            .add_arg_high32_eax => |reg| try writer.print("\tmovq {s}, %rcx\n\tshrq $32, %rcx\n\taddl %ecx, %eax\n", .{reg.name64()}),
            .add_stack_disp8_eax => |offset| try writer.print("\taddl {}(%rsp), %eax\n", .{offset}),
            .add_stack_disp8_rax => |offset| try writer.print("\taddq {}(%rsp), %rax\n", .{offset}),
            .add_stack_disp32_eax => |offset| try writer.print("\taddl {}(%rsp), %eax\n", .{offset}),
            .add_stack_disp32_rax => |offset| try writer.print("\taddq {}(%rsp), %rax\n", .{offset}),
            .add_eax_imm32 => |value| try writer.print("\taddl ${}, %eax\n", .{value}),
            .shl_eax_imm5 => |amount| try writer.print("\tshll ${}, %eax\n", .{amount}),
            .shr_eax_imm5 => |amount| try writer.print("\tshrl ${}, %eax\n", .{amount}),
            .sar_eax_imm5 => |amount| try writer.print("\tsarl ${}, %eax\n", .{amount}),
            .shr_arg_imm5 => |shift| try writer.print("\tshrl ${}, {s}\n", .{ shift.amount, shift.reg.name32() }),
            .shr_arg64_imm6 => |shift| try writer.print("\tshrq ${}, {s}\n", .{ shift.amount, shift.reg.name64() }),
            .sar_arg64_imm6 => |shift| try writer.print("\tsarq ${}, {s}\n", .{ shift.amount, shift.reg.name64() }),
            .shl_eax_cl => try writer.writeAll("\tshll %cl, %eax\n"),
            .shr_eax_cl => try writer.writeAll("\tshrl %cl, %eax\n"),
            .sar_eax_cl => try writer.writeAll("\tsarl %cl, %eax\n"),
            .shl_rax_cl => try writer.writeAll("\tshlq %cl, %rax\n"),
            .shr_rax_cl => try writer.writeAll("\tshrq %cl, %rax\n"),
            .sar_rax_cl => try writer.writeAll("\tsarq %cl, %rax\n"),
            .fshl_eax_arg32_imm5 => |shift| try writer.print("\tshldl ${}, {s}, %eax\n", .{ shift.amount, shift.reg.name32() }),
            .or_eax_imm32 => |value| try writer.print("\torl ${}, %eax\n", .{value}),
            .imul_eax_imm32 => |value| try writer.print("\timull ${}, %eax, %eax\n", .{value}),
            .and_eax_imm32 => |value| try writer.print("\tandl ${}, %eax\n", .{value}),
            .abs_i32_edi_eax => try writer.writeAll("\tmovl %edi, %eax\n\tmovl %edi, %edx\n\tnegl %edx\n\ttestl %edi, %edi\n\tcmovsl %edx, %eax\n"),
            .abs_i64_rdi_rax => try writer.writeAll("\tmovq %rdi, %rax\n\tmovq %rdi, %rdx\n\tnegq %rdx\n\ttestq %rdi, %rdi\n\tcmovsq %rdx, %rax\n"),
            .clz_i128_rdi_rsi_eax => try writer.writeAll(
                "\ttestq %rsi, %rsi\n" ++
                    "\tje 1f\n" ++
                    "\tbsrq %rsi, %rax\n" ++
                    "\txorl $63, %eax\n" ++
                    "\tjmp 2f\n" ++
                    "1:\n" ++
                    "\tmovl $128, %eax\n" ++
                    "\ttestq %rdi, %rdi\n" ++
                    "\tje 2f\n" ++
                    "\tbsrq %rdi, %rax\n" ++
                    "\txorl $63, %eax\n" ++
                    "\taddl $64, %eax\n" ++
                    "2:\n",
            ),
            .clz_i64_rdi_eax => try writer.writeAll("\tmovl $64, %eax\n\ttestq %rdi, %rdi\n\tje 1f\n\tbsrq %rdi, %rax\n\txorl $63, %eax\n1:\n"),
            .clz_i32_edi_eax => try writer.writeAll("\tmovl $32, %eax\n\ttestl %edi, %edi\n\tje 1f\n\tbsrl %edi, %eax\n\txorl $31, %eax\n1:\n"),
            .ctz_i32_edi_eax => try writer.writeAll("\tmovl $32, %eax\n\ttestl %edi, %edi\n\tje 1f\n\tbsfl %edi, %eax\n1:\n"),
            .popcount_i32_edi_eax => try writer.writeAll("\tpopcntl %edi, %eax\n"),
            .bit_reverse_i32_edi_eax => try writer.writeAll(
                "\tmovl %edi, %eax\n" ++
                    "\tbswapl %eax\n" ++
                    "\tmovl %eax, %edx\n" ++
                    "\tshrl $4, %eax\n" ++
                    "\tandl $252645135, %eax\n" ++
                    "\tandl $252645135, %edx\n" ++
                    "\tshll $4, %edx\n" ++
                    "\torl %edx, %eax\n" ++
                    "\tmovl %eax, %edx\n" ++
                    "\tshrl $2, %eax\n" ++
                    "\tandl $858993459, %eax\n" ++
                    "\tandl $858993459, %edx\n" ++
                    "\tshll $2, %edx\n" ++
                    "\torl %edx, %eax\n" ++
                    "\tmovl %eax, %edx\n" ++
                    "\tshrl $1, %eax\n" ++
                    "\tandl $1431655765, %eax\n" ++
                    "\tandl $1431655765, %edx\n" ++
                    "\tshll $1, %edx\n" ++
                    "\torl %edx, %eax\n",
            ),
            .ushl_sat_i32_edi_imm_eax => |amount| try writer.print(
                "\tmovl %edi, %eax\n" ++
                    "\tshll ${}, %eax\n" ++
                    "\tcmpl ${}, %edi\n" ++
                    "\tmovl $-1, %edx\n" ++
                    "\tcmoval %edx, %eax\n",
                .{ amount, @as(u32, std.math.maxInt(u32)) >> amount },
            ),
            .bswap_eax => try writer.writeAll("\tbswapl %eax\n"),
            .bswap_rax => try writer.writeAll("\tbswapq %rax\n"),
            .rol_ax_imm8 => |amount| try writer.print("\trolw ${}, %ax\n", .{amount}),
            .shr_rax_imm6 => |amount| try writer.print("\tshrq ${}, %rax\n", .{amount}),
            .shl_rax_imm6 => |amount| try writer.print("\tshlq ${}, %rax\n", .{amount}),
            .shl_rdx_imm6 => |amount| try writer.print("\tshlq ${}, %rdx\n", .{amount}),
            .or_rdx_rax => try writer.writeAll("\torq %rdx, %rax\n"),
            .neg_rax => try writer.writeAll("\tnegq %rax\n"),
            .neg_i128_rdi_rsi_rdx_rax => try writer.writeAll("\tmovq %rdi, %rax\n\tmovq %rsi, %rdx\n\tnegq %rax\n\tadcq $0, %rdx\n\tnegq %rdx\n"),
            .ctz_i128_rdi_rsi_eax => try writer.writeAll(
                "\tmovl $128, %eax\n" ++
                    "\ttestq %rdi, %rdi\n" ++
                    "\tjne 1f\n" ++
                    "\ttestq %rsi, %rsi\n" ++
                    "\tje 2f\n" ++
                    "\tbsfq %rsi, %rax\n" ++
                    "\taddl $64, %eax\n" ++
                    "\tjmp 2f\n" ++
                    "1:\n" ++
                    "\tbsfq %rdi, %rax\n" ++
                    "2:\n",
            ),
            .ctz_i64_rdi_eax => try writer.writeAll("\tmovl $64, %eax\n\ttestq %rdi, %rdi\n\tje 1f\n\tbsfq %rdi, %rax\n1:\n"),
            .ffs_i128_rdi_rsi_eax => try writer.writeAll(
                "\txorl %eax, %eax\n" ++
                    "\ttestq %rdi, %rdi\n" ++
                    "\tjne 1f\n" ++
                    "\ttestq %rsi, %rsi\n" ++
                    "\tje 2f\n" ++
                    "\tbsfq %rsi, %rax\n" ++
                    "\taddl $65, %eax\n" ++
                    "\tjmp 2f\n" ++
                    "1:\n" ++
                    "\tbsfq %rdi, %rax\n" ++
                    "\taddl $1, %eax\n" ++
                    "2:\n",
            ),
            .ffs_i64_rdi_eax => try writer.writeAll("\txorl %eax, %eax\n\ttestq %rdi, %rdi\n\tje 1f\n\tbsfq %rdi, %rax\n\taddl $1, %eax\n1:\n"),
            .ffs_i32_edi_eax => try writer.writeAll("\txorl %eax, %eax\n\ttestl %edi, %edi\n\tje 1f\n\tbsfl %edi, %eax\n\taddl $1, %eax\n1:\n"),
            .shl_rcx_imm6 => |amount| try writer.print("\tshlq ${}, %rcx\n", .{amount}),
            .shl_r8_imm6 => |amount| try writer.print("\tshlq ${}, %r8\n", .{amount}),
            .or_rcx_rax => try writer.writeAll("\torq %rcx, %rax\n"),
            .or_rcx_rdx => try writer.writeAll("\torq %rcx, %rdx\n"),
            .add_rax_imm8 => |value| try writer.print("\taddq ${}, %rax\n", .{value}),
            .add_rcx_imm32 => |value| try writer.print("\taddq ${}, %rcx\n", .{value}),
            .add_r8_rcx => try writer.writeAll("\taddq %r8, %rcx\n"),
            .sub_r8_rcx => try writer.writeAll("\tsubq %r8, %rcx\n"),
            .add_ecx_eax => try writer.writeAll("\taddl %ecx, %eax\n"),
            .xor_ecx_ecx => try writer.writeAll("\txorl %ecx, %ecx\n"),
            .xor_ebp_ebp => try writer.writeAll("\txorl %ebp, %ebp\n"),
            .add_rdi_rcx4_ptr_eax => try writer.writeAll("\taddl (%rdi,%rcx,4), %eax\n"),
            .load_rdi_rcx4_ptr_r8d => try writer.writeAll("\tmovl (%rdi,%rcx,4), %r8d\n"),
            .store_eax_rdi_rcx4_ptr => try writer.writeAll("\tmovl %eax, (%rdi,%rcx,4)\n"),
            .load_rdi_ptr_u8_eax => try writer.writeAll("\tmovzbl (%rdi), %eax\n"),
            .load_rdi_ptr_u16_eax => try writer.writeAll("\tmovzwl (%rdi), %eax\n"),
            .load_rdi_ptr_eax => try writer.writeAll("\tmovl (%rdi), %eax\n"),
            .load_rdi_ptr_rax => try writer.writeAll("\tmovq (%rdi), %rax\n"),
            .atomic_fetch_umin_i8_rdi_sil_eax => try writer.writeAll(
                "\tmovzbl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %esi, %ecx\n" ++
                    "\tcmpb %sil, %al\n" ++
                    "\tja 2f\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "2:\n" ++
                    "\tlock cmpxchgb %cl, (%rdi)\n" ++
                    "\tjne 1b\n" ++
                    "\tmovzbl %al, %eax\n",
            ),
            .atomic_fetch_umin_i16_rdi_si_eax => try writer.writeAll(
                "\tmovzwl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %esi, %ecx\n" ++
                    "\tcmpw %si, %ax\n" ++
                    "\tja 2f\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "2:\n" ++
                    "\tlock cmpxchgw %cx, (%rdi)\n" ++
                    "\tjne 1b\n" ++
                    "\tmovzwl %ax, %eax\n",
            ),
            .atomic_fetch_umin_i32_rdi_esi_eax => try writer.writeAll(
                "\tmovl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %esi, %ecx\n" ++
                    "\tcmpl %esi, %eax\n" ++
                    "\tcmovbel %eax, %ecx\n" ++
                    "\tlock cmpxchgl %ecx, (%rdi)\n" ++
                    "\tjne 1b\n",
            ),
            .atomic_fetch_umin_i64_rdi_rsi_rax => try writer.writeAll(
                "\tmovq (%rdi), %rax\n" ++
                    "1:\n" ++
                    "\tmovq %rsi, %rcx\n" ++
                    "\tcmpq %rsi, %rax\n" ++
                    "\tcmovbeq %rax, %rcx\n" ++
                    "\tlock cmpxchgq %rcx, (%rdi)\n" ++
                    "\tjne 1b\n",
            ),
            .atomic_fetch_umax_i8_rdi_sil_eax => try writer.writeAll(
                "\tmovzbl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %esi, %ecx\n" ++
                    "\tcmpb %sil, %al\n" ++
                    "\tjb 2f\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "2:\n" ++
                    "\tlock cmpxchgb %cl, (%rdi)\n" ++
                    "\tjne 1b\n" ++
                    "\tmovzbl %al, %eax\n",
            ),
            .atomic_fetch_umax_i16_rdi_si_eax => try writer.writeAll(
                "\tmovzwl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %esi, %ecx\n" ++
                    "\tcmpw %si, %ax\n" ++
                    "\tjb 2f\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "2:\n" ++
                    "\tlock cmpxchgw %cx, (%rdi)\n" ++
                    "\tjne 1b\n" ++
                    "\tmovzwl %ax, %eax\n",
            ),
            .atomic_fetch_umax_i32_rdi_esi_eax => try writer.writeAll(
                "\tmovl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %esi, %ecx\n" ++
                    "\tcmpl %esi, %eax\n" ++
                    "\tcmovael %eax, %ecx\n" ++
                    "\tlock cmpxchgl %ecx, (%rdi)\n" ++
                    "\tjne 1b\n",
            ),
            .atomic_fetch_umax_i64_rdi_rsi_rax => try writer.writeAll(
                "\tmovq (%rdi), %rax\n" ++
                    "1:\n" ++
                    "\tmovq %rsi, %rcx\n" ++
                    "\tcmpq %rsi, %rax\n" ++
                    "\tcmovaeq %rax, %rcx\n" ++
                    "\tlock cmpxchgq %rcx, (%rdi)\n" ++
                    "\tjne 1b\n",
            ),
            .atomic_fetch_nand_i8_rdi_sil_eax => try writer.writeAll(
                "\tmovzbl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "\tandb %sil, %cl\n" ++
                    "\tnotb %cl\n" ++
                    "\tlock cmpxchgb %cl, (%rdi)\n" ++
                    "\tjne 1b\n" ++
                    "\tmovzbl %al, %eax\n",
            ),
            .atomic_fetch_nand_i16_rdi_si_eax => try writer.writeAll(
                "\tmovzwl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "\tandw %si, %cx\n" ++
                    "\tnotw %cx\n" ++
                    "\tlock cmpxchgw %cx, (%rdi)\n" ++
                    "\tjne 1b\n" ++
                    "\tmovzwl %ax, %eax\n",
            ),
            .atomic_fetch_nand_i32_rdi_esi_eax => try writer.writeAll(
                "\tmovl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "\tandl %esi, %ecx\n" ++
                    "\tnotl %ecx\n" ++
                    "\tlock cmpxchgl %ecx, (%rdi)\n" ++
                    "\tjne 1b\n",
            ),
            .atomic_fetch_nand_i64_rdi_rsi_rax => try writer.writeAll(
                "\tmovq (%rdi), %rax\n" ++
                    "1:\n" ++
                    "\tmovq %rax, %rcx\n" ++
                    "\tandq %rsi, %rcx\n" ++
                    "\tnotq %rcx\n" ++
                    "\tlock cmpxchgq %rcx, (%rdi)\n" ++
                    "\tjne 1b\n",
            ),
            .atomic_fetch_xor_i8_rdi_sil_eax => try writer.writeAll(
                "\tmovzbl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "\txorb %sil, %cl\n" ++
                    "\tlock cmpxchgb %cl, (%rdi)\n" ++
                    "\tjne 1b\n" ++
                    "\tmovzbl %al, %eax\n",
            ),
            .atomic_fetch_xor_i16_rdi_si_eax => try writer.writeAll(
                "\tmovzwl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "\txorw %si, %cx\n" ++
                    "\tlock cmpxchgw %cx, (%rdi)\n" ++
                    "\tjne 1b\n" ++
                    "\tmovzwl %ax, %eax\n",
            ),
            .atomic_fetch_xor_i32_rdi_esi_eax => try writer.writeAll(
                "\tmovl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "\txorl %esi, %ecx\n" ++
                    "\tlock cmpxchgl %ecx, (%rdi)\n" ++
                    "\tjne 1b\n",
            ),
            .atomic_fetch_xor_i64_rdi_rsi_rax => try writer.writeAll(
                "\tmovq (%rdi), %rax\n" ++
                    "1:\n" ++
                    "\tmovq %rax, %rcx\n" ++
                    "\txorq %rsi, %rcx\n" ++
                    "\tlock cmpxchgq %rcx, (%rdi)\n" ++
                    "\tjne 1b\n",
            ),
            .atomic_fetch_or_i8_rdi_sil_eax => try writer.writeAll(
                "\tmovzbl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "\torb %sil, %cl\n" ++
                    "\tlock cmpxchgb %cl, (%rdi)\n" ++
                    "\tjne 1b\n" ++
                    "\tmovzbl %al, %eax\n",
            ),
            .atomic_fetch_or_i16_rdi_si_eax => try writer.writeAll(
                "\tmovzwl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "\torw %si, %cx\n" ++
                    "\tlock cmpxchgw %cx, (%rdi)\n" ++
                    "\tjne 1b\n" ++
                    "\tmovzwl %ax, %eax\n",
            ),
            .atomic_fetch_or_i32_rdi_esi_eax => try writer.writeAll(
                "\tmovl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "\torl %esi, %ecx\n" ++
                    "\tlock cmpxchgl %ecx, (%rdi)\n" ++
                    "\tjne 1b\n",
            ),
            .atomic_fetch_or_i64_rdi_rsi_rax => try writer.writeAll(
                "\tmovq (%rdi), %rax\n" ++
                    "1:\n" ++
                    "\tmovq %rax, %rcx\n" ++
                    "\torq %rsi, %rcx\n" ++
                    "\tlock cmpxchgq %rcx, (%rdi)\n" ++
                    "\tjne 1b\n",
            ),
            .atomic_fetch_and_i8_rdi_sil_eax => try writer.writeAll(
                "\tmovzbl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "\tandb %sil, %cl\n" ++
                    "\tlock cmpxchgb %cl, (%rdi)\n" ++
                    "\tjne 1b\n" ++
                    "\tmovzbl %al, %eax\n",
            ),
            .atomic_fetch_and_i16_rdi_si_eax => try writer.writeAll(
                "\tmovzwl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "\tandw %si, %cx\n" ++
                    "\tlock cmpxchgw %cx, (%rdi)\n" ++
                    "\tjne 1b\n" ++
                    "\tmovzwl %ax, %eax\n",
            ),
            .atomic_fetch_and_i32_rdi_esi_eax => try writer.writeAll(
                "\tmovl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "\tandl %esi, %ecx\n" ++
                    "\tlock cmpxchgl %ecx, (%rdi)\n" ++
                    "\tjne 1b\n",
            ),
            .atomic_fetch_and_i64_rdi_rsi_rax => try writer.writeAll(
                "\tmovq (%rdi), %rax\n" ++
                    "1:\n" ++
                    "\tmovq %rax, %rcx\n" ++
                    "\tandq %rsi, %rcx\n" ++
                    "\tlock cmpxchgq %rcx, (%rdi)\n" ++
                    "\tjne 1b\n",
            ),
            .atomic_fetch_sub_i8_rdi_sil_eax => try writer.writeAll(
                "\tmovzbl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "\tsubb %sil, %cl\n" ++
                    "\tlock cmpxchgb %cl, (%rdi)\n" ++
                    "\tjne 1b\n" ++
                    "\tmovzbl %al, %eax\n",
            ),
            .atomic_fetch_sub_i16_rdi_si_eax => try writer.writeAll(
                "\tmovzwl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "\tsubw %si, %cx\n" ++
                    "\tlock cmpxchgw %cx, (%rdi)\n" ++
                    "\tjne 1b\n" ++
                    "\tmovzwl %ax, %eax\n",
            ),
            .atomic_fetch_sub_i32_rdi_esi_eax => try writer.writeAll(
                "\tmovl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "\tsubl %esi, %ecx\n" ++
                    "\tlock cmpxchgl %ecx, (%rdi)\n" ++
                    "\tjne 1b\n",
            ),
            .atomic_fetch_sub_i64_rdi_rsi_rax => try writer.writeAll(
                "\tmovq (%rdi), %rax\n" ++
                    "1:\n" ++
                    "\tmovq %rax, %rcx\n" ++
                    "\tsubq %rsi, %rcx\n" ++
                    "\tlock cmpxchgq %rcx, (%rdi)\n" ++
                    "\tjne 1b\n",
            ),
            .atomic_fetch_add_i8_rdi_sil_eax => try writer.writeAll(
                "\tmovzbl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "\taddb %sil, %cl\n" ++
                    "\tlock cmpxchgb %cl, (%rdi)\n" ++
                    "\tjne 1b\n" ++
                    "\tmovzbl %al, %eax\n",
            ),
            .atomic_fetch_add_i16_rdi_si_eax => try writer.writeAll(
                "\tmovzwl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "\taddw %si, %cx\n" ++
                    "\tlock cmpxchgw %cx, (%rdi)\n" ++
                    "\tjne 1b\n" ++
                    "\tmovzwl %ax, %eax\n",
            ),
            .atomic_fetch_add_i32_rdi_esi_eax => try writer.writeAll(
                "\tmovl (%rdi), %eax\n" ++
                    "1:\n" ++
                    "\tmovl %eax, %ecx\n" ++
                    "\taddl %esi, %ecx\n" ++
                    "\tlock cmpxchgl %ecx, (%rdi)\n" ++
                    "\tjne 1b\n",
            ),
            .atomic_fetch_add_i64_rdi_rsi_rax => try writer.writeAll(
                "\tmovq (%rdi), %rax\n" ++
                    "1:\n" ++
                    "\tmovq %rax, %rcx\n" ++
                    "\taddq %rsi, %rcx\n" ++
                    "\tlock cmpxchgq %rcx, (%rdi)\n" ++
                    "\tjne 1b\n",
            ),
            .load_rcx_ptr_u8_eax => try writer.writeAll("\tmovzbl (%rcx), %eax\n"),
            .load_rcx_ptr_u16_eax => try writer.writeAll("\tmovzwl (%rcx), %eax\n"),
            .load_rcx_ptr_eax => try writer.writeAll("\tmovl (%rcx), %eax\n"),
            .load_rcx_ptr_rax => try writer.writeAll("\tmovq (%rcx), %rax\n"),
            .store_al_rcx_ptr => try writer.writeAll("\tmovb %al, (%rcx)\n"),
            .store_ax_rcx_ptr => try writer.writeAll("\tmovw %ax, (%rcx)\n"),
            .store_eax_rcx_ptr => try writer.writeAll("\tmovl %eax, (%rcx)\n"),
            .store_rax_rcx_ptr => try writer.writeAll("\tmovq %rax, (%rcx)\n"),
            .cmp_r8d_arg32 => |reg| try writer.print("\tcmpl {s}, %r8d\n", .{reg.name32()}),
            .add_r8d_eax => try writer.writeAll("\taddl %r8d, %eax\n"),
            .inc_rcx => try writer.writeAll("\tincq %rcx\n"),
            .movzx_dil_edi => try writer.writeAll("\tmovzbl %dil, %edi\n"),
            .and_edi_imm8 => |value| try writer.print("\tandl ${}, %edi\n", .{value}),
            .load_rax_rdi_u8_eax => try writer.writeAll("\tmovzbl (%rax,%rdi), %eax\n"),
            .bcmp_rdi_rsi_rdx_eax => try writer.writeAll(
                "\ttestq %rdx, %rdx\n" ++
                    "\tje 2f\n" ++
                    "\txorl %ecx, %ecx\n" ++
                    "1:\n" ++
                    "\tmovzbl (%rdi,%rcx), %eax\n" ++
                    "\tcmpb (%rsi,%rcx), %al\n" ++
                    "\tjne 3f\n" ++
                    "\tincq %rcx\n" ++
                    "\tcmpq %rcx, %rdx\n" ++
                    "\tjne 1b\n" ++
                    "2:\n" ++
                    "\txorl %eax, %eax\n" ++
                    "\tjmp 4f\n" ++
                    "3:\n" ++
                    "\tmovl $1, %eax\n" ++
                    "4:\n",
            ),
            .memcmp_rdi_rsi_rdx_eax => try writer.writeAll(
                "\ttestq %rdx, %rdx\n" ++
                    "\tje 2f\n" ++
                    "\txorl %ecx, %ecx\n" ++
                    "1:\n" ++
                    "\tmovzbl (%rdi,%rcx), %eax\n" ++
                    "\tmovzbl (%rsi,%rcx), %r8d\n" ++
                    "\tcmpb %r8b, %al\n" ++
                    "\tjne 3f\n" ++
                    "\tincq %rcx\n" ++
                    "\tcmpq %rcx, %rdx\n" ++
                    "\tjne 1b\n" ++
                    "2:\n" ++
                    "\txorl %eax, %eax\n" ++
                    "\tjmp 4f\n" ++
                    "3:\n" ++
                    "\tsubl %r8d, %eax\n" ++
                    "4:\n",
            ),
            .memcpy_rdi_rsi_rdx_rax => try writer.writeAll(
                "\tmovq %rdi, %rax\n" ++
                    "\ttestq %rdx, %rdx\n" ++
                    "\tje 2f\n" ++
                    "\tcld\n" ++
                    "\tmovq %rdx, %rcx\n" ++
                    "\trep movsb\n" ++
                    "2:\n",
            ),
            .abs_limb64_rdi_rsi_dx_rcx_rax => try writer.writeAll(
                "\tmovzwl %dx, %edx\n" ++
                    "\taddl $63, %edx\n" ++
                    "\tshrl $6, %edx\n" ++
                    "\ttestl %edx, %edx\n" ++
                    "\tje 3f\n" ++
                    "\tmovl %edx, %ecx\n" ++
                    "\tmovq -8(%rsi,%rcx,8), %rax\n" ++
                    "\ttestq %rax, %rax\n" ++
                    "\tjs 1f\n" ++
                    "\tcld\n" ++
                    "\trep movsq\n" ++
                    "\tjmp 3f\n" ++
                    "1:\n" ++
                    "\txorl %ecx, %ecx\n" ++
                    "\tmovl $1, %r8d\n" ++
                    "2:\n" ++
                    "\tmovq (%rsi,%rcx,8), %rax\n" ++
                    "\tnotq %rax\n" ++
                    "\tmovzbl %r8b, %r8d\n" ++
                    "\taddq %r8, %rax\n" ++
                    "\tsetc %r8b\n" ++
                    "\tmovq %rax, (%rdi,%rcx,8)\n" ++
                    "\tincq %rcx\n" ++
                    "\tcmpq %rdx, %rcx\n" ++
                    "\tjne 2b\n" ++
                    "3:\n",
            ),
            .mulo_limb64_rdi_rsi_rdx_cl_r8w_al => try printByteDirective(writer, &selector_bytes.mulo_limb64_rdi_rsi_rdx_cl_r8w_al),
            .byteswap_limb64_rdi_rsi_dl_cx => try printByteDirective(writer, &selector_bytes.byteswap_limb64_rdi_rsi_dl_cx),
            .shr_limb64_rdi_rsi_dx_cl_r8w => try printByteDirective(writer, &selector_bytes.shr_limb64_rdi_rsi_dx_cl_r8w),
            .shlo_limb64_rdi_rsi_dx_cl_r8w_al => try printByteDirective(writer, &selector_bytes.shlo_limb64_rdi_rsi_dx_cl_r8w_al),
            .not_limb64_rdi_rsi_dl_cx => try printByteDirective(writer, &selector_bytes.not_limb64_rdi_rsi_dl_cx),
            .bitwise_limb64_rdi_rsi_rdx_cx => |op| switch (op) {
                .xor => try printByteDirective(writer, &selector_bytes.xor_limb64_rdi_rsi_rdx_cx),
                .@"or" => try printByteDirective(writer, &selector_bytes.or_limb64_rdi_rsi_rdx_cx),
                .@"and" => try printByteDirective(writer, &selector_bytes.and_limb64_rdi_rsi_rdx_cx),
            },
            .cmp_limb64_rdi_rsi_dl_cx_ax => try printByteDirective(writer, &selector_bytes.cmp_limb64_rdi_rsi_dl_cx_ax),
            .overflow_limb64_rdi_rsi_rdx_cl_r8w_al => |op| switch (op) {
                .add => try printByteDirective(writer, &selector_bytes.addo_limb64_rdi_rsi_rdx_cl_r8w_al),
                .sub => try printByteDirective(writer, &selector_bytes.subo_limb64_rdi_rsi_rdx_cl_r8w_al),
            },
            .bitreverse_limb64_rdi_rsi_dl_cx => try printByteDirective(writer, &selector_bytes.bitreverse_limb64_rdi_rsi_dl_cx),
            .popcount_limb64_rdi_si_ax => try printByteDirective(writer, &selector_bytes.popcount_limb64_rdi_si_ax),
            .ctz_limb64_rdi_si_ax => try printByteDirective(writer, &selector_bytes.ctz_limb64_rdi_si_ax),
            .clz_limb64_rdi_si_ax => try printByteDirective(writer, &selector_bytes.clz_limb64_rdi_si_ax),
            .udivei4_before_intbytesize => try printByteDirective(writer, &selector_bytes.udivei4_before_intbytesize),
            .udivei4_between_intbytesize_and_memset => try printByteDirective(writer, &selector_bytes.udivei4_between_intbytesize_and_memset),
            .udivei4_after_memset => try printByteDirective(writer, &selector_bytes.udivei4_after_memset),
            .umodei5_before_intbytesize => try printByteDirective(writer, &selector_bytes.umodei5_before_intbytesize),
            .umodei5_between_intbytesize_and_memset => try printByteDirective(writer, &selector_bytes.umodei5_between_intbytesize_and_memset),
            .umodei5_after_memset_before_memcpy => try printByteDirective(writer, &selector_bytes.umodei5_after_memset_before_memcpy),
            .umodei5_after_memcpy => try printByteDirective(writer, &selector_bytes.umodei5_after_memcpy),
            .spinlocked_memcpy_rsi_to_rdx_len_edi => |symbol| try writer.print(
                "\tmovq %rsi, %rax\n" ++
                    "\tshrq $3, %rax\n" ++
                    "\tandq $63, %rax\n" ++
                    "\tleaq {s}(%rip), %r8\n" ++
                    "\tleaq (%r8,%rax), %r8\n" ++
                    "\tmovl $1, %eax\n" ++
                    "1:\n" ++
                    "\txchgq %rax, (%r8)\n" ++
                    "\ttestq %rax, %rax\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjne 1b\n" ++
                    "\ttestl %edi, %edi\n" ++
                    "\tje 2f\n" ++
                    "\tcld\n" ++
                    "\tmovl %edi, %ecx\n" ++
                    "\tmovq %rdx, %rdi\n" ++
                    "\trep movsb\n" ++
                    "2:\n" ++
                    "\tmovq $0, (%r8)\n",
                .{symbol},
            ),
            .spinlocked_var_cmpxchg_edi_rsi_rdx_rcx_eax => |symbol| try writer.print(
                "\tmovq %rsi, %rax\n" ++
                    "\tshrq $3, %rax\n" ++
                    "\tandq $63, %rax\n" ++
                    "\tleaq {s}(%rip), %r8\n" ++
                    "\tleaq (%r8,%rax), %r8\n" ++
                    "\tmovl $1, %eax\n" ++
                    "1:\n" ++
                    "\txchgq %rax, (%r8)\n" ++
                    "\ttestq %rax, %rax\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjne 1b\n" ++
                    "\ttestl %edi, %edi\n" ++
                    "\tje 4f\n" ++
                    "\txorl %r9d, %r9d\n" ++
                    "2:\n" ++
                    "\tmovzbl (%rsi,%r9), %eax\n" ++
                    "\tcmpb (%rdx,%r9), %al\n" ++
                    "\tjne 5f\n" ++
                    "\tincq %r9\n" ++
                    "\tcmpq %r9, %rdi\n" ++
                    "\tjne 2b\n" ++
                    "4:\n" ++
                    "\tmovq %rcx, %r10\n" ++
                    "\tmovl %edi, %ecx\n" ++
                    "\tmovq %rsi, %rdi\n" ++
                    "\tmovq %r10, %rsi\n" ++
                    "\tcld\n" ++
                    "\trep movsb\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjmp 6f\n" ++
                    "5:\n" ++
                    "\tmovl %edi, %ecx\n" ++
                    "\tmovq %rdx, %rdi\n" ++
                    "\tcld\n" ++
                    "\trep movsb\n" ++
                    "\txorl %eax, %eax\n" ++
                    "6:\n" ++
                    "\tmovq $0, (%r8)\n",
                .{symbol},
            ),
            .spinlocked_var_xchg_edi_rsi_rdx_rcx => |symbol| try writer.print(
                "\tmovq %rsi, %rax\n" ++
                    "\tshrq $3, %rax\n" ++
                    "\tandq $63, %rax\n" ++
                    "\tleaq {s}(%rip), %r8\n" ++
                    "\tleaq (%r8,%rax), %r8\n" ++
                    "\tmovl $1, %eax\n" ++
                    "1:\n" ++
                    "\txchgq %rax, (%r8)\n" ++
                    "\ttestq %rax, %rax\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjne 1b\n" ++
                    "\ttestl %edi, %edi\n" ++
                    "\tje 2f\n" ++
                    "\tmovq %rcx, %r9\n" ++
                    "\tmovq %rsi, %r10\n" ++
                    "\tmovq %rdx, %r11\n" ++
                    "\tcld\n" ++
                    "\tmovl %edi, %ecx\n" ++
                    "\tmovq %r9, %rdi\n" ++
                    "\tmovq %r10, %rsi\n" ++
                    "\trep movsb\n" ++
                    "\tmovl %edi, %ecx\n" ++
                    "\tmovq %r10, %rdi\n" ++
                    "\tmovq %r11, %rsi\n" ++
                    "\trep movsb\n" ++
                    "2:\n" ++
                    "\tmovq $0, (%r8)\n",
                .{symbol},
            ),
            .spinlocked_var_store_edi_rsi_rdx => |symbol| try writer.print(
                "\tmovq %rsi, %rax\n" ++
                    "\tshrq $3, %rax\n" ++
                    "\tandq $63, %rax\n" ++
                    "\tleaq {s}(%rip), %r8\n" ++
                    "\tleaq (%r8,%rax), %r8\n" ++
                    "\tmovl $1, %eax\n" ++
                    "1:\n" ++
                    "\txchgq %rax, (%r8)\n" ++
                    "\ttestq %rax, %rax\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjne 1b\n" ++
                    "\ttestl %edi, %edi\n" ++
                    "\tje 2f\n" ++
                    "\tmovq %rsi, %r9\n" ++
                    "\tmovq %rdx, %r10\n" ++
                    "\tcld\n" ++
                    "\tmovl %edi, %ecx\n" ++
                    "\tmovq %r9, %rdi\n" ++
                    "\tmovq %r10, %rsi\n" ++
                    "\trep movsb\n" ++
                    "2:\n" ++
                    "\tmovq $0, (%r8)\n",
                .{symbol},
            ),
            .cmpxchg_ptr_expected_desired_i8_eax => try writer.writeAll(
                "\tmovb (%rsi), %al\n" ++
                    "\tlock cmpxchgb %dl, (%rdi)\n" ++
                    "\tjne 1f\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjmp 2f\n" ++
                    "1:\n" ++
                    "\tmovb %al, (%rsi)\n" ++
                    "\txorl %eax, %eax\n" ++
                    "2:\n",
            ),
            .cmpxchg_ptr_expected_desired_i16_eax => try writer.writeAll(
                "\tmovw (%rsi), %ax\n" ++
                    "\tlock cmpxchgw %dx, (%rdi)\n" ++
                    "\tjne 1f\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjmp 2f\n" ++
                    "1:\n" ++
                    "\tmovw %ax, (%rsi)\n" ++
                    "\txorl %eax, %eax\n" ++
                    "2:\n",
            ),
            .cmpxchg_ptr_expected_desired_i32_eax => try writer.writeAll(
                "\tmovl (%rsi), %eax\n" ++
                    "\tlock cmpxchgl %edx, (%rdi)\n" ++
                    "\tjne 1f\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjmp 2f\n" ++
                    "1:\n" ++
                    "\tmovl %eax, (%rsi)\n" ++
                    "\txorl %eax, %eax\n" ++
                    "2:\n",
            ),
            .cmpxchg_ptr_expected_desired_i64_eax => try writer.writeAll(
                "\tmovq (%rsi), %rax\n" ++
                    "\tlock cmpxchgq %rdx, (%rdi)\n" ++
                    "\tjne 1f\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjmp 2f\n" ++
                    "1:\n" ++
                    "\tmovq %rax, (%rsi)\n" ++
                    "\txorl %eax, %eax\n" ++
                    "2:\n",
            ),
            .spinlocked_cmpxchg_i128_rdi_rsi_rdx_rcx_eax => |symbol| try writer.print(
                "\tmovq %rdi, %rax\n" ++
                    "\tshrq $3, %rax\n" ++
                    "\tandq $62, %rax\n" ++
                    "\tleaq {s}(%rip), %r8\n" ++
                    "\tleaq (%r8,%rax), %r8\n" ++
                    "\tmovl $1, %eax\n" ++
                    "1:\n" ++
                    "\txchgq %rax, (%r8)\n" ++
                    "\ttestq %rax, %rax\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjne 1b\n" ++
                    "\tmovq (%rdi), %rax\n" ++
                    "\tmovq 8(%rdi), %r10\n" ++
                    "\tcmpq (%rsi), %rax\n" ++
                    "\tjne 2f\n" ++
                    "\tcmpq 8(%rsi), %r10\n" ++
                    "\tjne 2f\n" ++
                    "\tmovq %rdx, (%rdi)\n" ++
                    "\tmovq %rcx, 8(%rdi)\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjmp 3f\n" ++
                    "2:\n" ++
                    "\tmovq %rax, (%rsi)\n" ++
                    "\tmovq %r10, 8(%rsi)\n" ++
                    "\txorl %eax, %eax\n" ++
                    "3:\n" ++
                    "\tmovq $0, (%r8)\n",
                .{symbol},
            ),
            .xchg_ptr_value_i8_eax => try writer.writeAll(
                "\tmovb %sil, %al\n" ++
                    "\txchgb %al, (%rdi)\n" ++
                    "\tmovzbl %al, %eax\n",
            ),
            .xchg_ptr_value_i16_eax => try writer.writeAll(
                "\tmovw %si, %ax\n" ++
                    "\txchgw %ax, (%rdi)\n" ++
                    "\tmovzwl %ax, %eax\n",
            ),
            .xchg_ptr_value_i32_eax => try writer.writeAll(
                "\tmovl %esi, %eax\n" ++
                    "\txchgl %eax, (%rdi)\n",
            ),
            .xchg_ptr_value_i64_rax => try writer.writeAll(
                "\tmovq %rsi, %rax\n" ++
                    "\txchgq %rax, (%rdi)\n",
            ),
            .spinlocked_xchg_i128_rdi_rsi_rdx_rax => |symbol| try writer.print(
                "\tmovq %rdx, %r9\n" ++
                    "\tmovq %rdi, %r8\n" ++
                    "\tshrq $3, %r8\n" ++
                    "\tandq $62, %r8\n" ++
                    "\tleaq {s}(%rip), %r10\n" ++
                    "\taddq %r8, %r10\n" ++
                    "\tmovl $1, %eax\n" ++
                    "1:\n" ++
                    "\txchgq %rax, (%r10)\n" ++
                    "\ttestq %rax, %rax\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjne 1b\n" ++
                    "\tmovq (%rdi), %rax\n" ++
                    "\tmovq 8(%rdi), %rcx\n" ++
                    "\tmovq %rsi, (%rdi)\n" ++
                    "\tmovq %r9, 8(%rdi)\n" ++
                    "\tmovq $0, (%r10)\n" ++
                    "\tmovq %rcx, %rdx\n",
                .{symbol},
            ),
            .spinlocked_store_i128_rdi_rsi_rdx => |symbol| try writer.print(
                "\tmovq %rdx, %r9\n" ++
                    "\tmovq %rdi, %r8\n" ++
                    "\tshrq $3, %r8\n" ++
                    "\tandq $62, %r8\n" ++
                    "\tleaq {s}(%rip), %r10\n" ++
                    "\taddq %r8, %r10\n" ++
                    "\tmovl $1, %eax\n" ++
                    "1:\n" ++
                    "\txchgq %rax, (%r10)\n" ++
                    "\ttestq %rax, %rax\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjne 1b\n" ++
                    "\tmovq %rsi, (%rdi)\n" ++
                    "\tmovq %r9, 8(%rdi)\n" ++
                    "\tmovq $0, (%r10)\n",
                .{symbol},
            ),
            .spinlocked_load_i128_rdi_rax_rdx => |symbol| try writer.print(
                "\tmovq %rdi, %r8\n" ++
                    "\tshrq $3, %r8\n" ++
                    "\tandq $62, %r8\n" ++
                    "\tleaq {s}(%rip), %r10\n" ++
                    "\taddq %r8, %r10\n" ++
                    "\tmovl $1, %eax\n" ++
                    "1:\n" ++
                    "\txchgq %rax, (%r10)\n" ++
                    "\ttestq %rax, %rax\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjne 1b\n" ++
                    "\tmovq (%rdi), %rax\n" ++
                    "\tmovq 8(%rdi), %rdx\n" ++
                    "\tmovq $0, (%r10)\n",
                .{symbol},
            ),
            .spinlocked_fetch_umin_i128_rdi_rsi_rdx_rax_rdx => |symbol| try writer.print(
                "\tmovq %rdx, %r9\n" ++
                    "\tmovq %rdi, %r8\n" ++
                    "\tshrq $3, %r8\n" ++
                    "\tandq $62, %r8\n" ++
                    "\tleaq {s}(%rip), %r10\n" ++
                    "\taddq %r8, %r10\n" ++
                    "\tmovl $1, %eax\n" ++
                    "1:\n" ++
                    "\txchgq %rax, (%r10)\n" ++
                    "\ttestq %rax, %rax\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjne 1b\n" ++
                    "\tmovq (%rdi), %rax\n" ++
                    "\tmovq 8(%rdi), %rdx\n" ++
                    "\tcmpq %r9, %rdx\n" ++
                    "\tjb 2f\n" ++
                    "\tja 3f\n" ++
                    "\tcmpq %rsi, %rax\n" ++
                    "\tjbe 2f\n" ++
                    "3:\n" ++
                    "\tmovq %rsi, (%rdi)\n" ++
                    "\tmovq %r9, 8(%rdi)\n" ++
                    "2:\n" ++
                    "\tmovq $0, (%r10)\n",
                .{symbol},
            ),
            .spinlocked_fetch_umax_i128_rdi_rsi_rdx_rax_rdx => |symbol| try writer.print(
                "\tmovq %rdx, %r9\n" ++
                    "\tmovq %rdi, %r8\n" ++
                    "\tshrq $3, %r8\n" ++
                    "\tandq $62, %r8\n" ++
                    "\tleaq {s}(%rip), %r10\n" ++
                    "\taddq %r8, %r10\n" ++
                    "\tmovl $1, %eax\n" ++
                    "1:\n" ++
                    "\txchgq %rax, (%r10)\n" ++
                    "\ttestq %rax, %rax\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjne 1b\n" ++
                    "\tmovq (%rdi), %rax\n" ++
                    "\tmovq 8(%rdi), %rdx\n" ++
                    "\tcmpq %r9, %rdx\n" ++
                    "\tja 2f\n" ++
                    "\tjb 3f\n" ++
                    "\tcmpq %rsi, %rax\n" ++
                    "\tjae 2f\n" ++
                    "3:\n" ++
                    "\tmovq %rsi, (%rdi)\n" ++
                    "\tmovq %r9, 8(%rdi)\n" ++
                    "2:\n" ++
                    "\tmovq $0, (%r10)\n",
                .{symbol},
            ),
            .spinlocked_fetch_nand_i128_rdi_rsi_rdx_rax_rdx => |symbol| try writer.print(
                "\tmovq %rdx, %r9\n" ++
                    "\tmovq %rdi, %r8\n" ++
                    "\tshrq $3, %r8\n" ++
                    "\tandq $62, %r8\n" ++
                    "\tleaq {s}(%rip), %r10\n" ++
                    "\taddq %r8, %r10\n" ++
                    "\tmovl $1, %eax\n" ++
                    "1:\n" ++
                    "\txchgq %rax, (%r10)\n" ++
                    "\ttestq %rax, %rax\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjne 1b\n" ++
                    "\tmovq (%rdi), %rax\n" ++
                    "\tmovq 8(%rdi), %rdx\n" ++
                    "\tmovq %rax, %r8\n" ++
                    "\tandq %rsi, %r8\n" ++
                    "\tnotq %r8\n" ++
                    "\tmovq %rdx, %r11\n" ++
                    "\tandq %r9, %r11\n" ++
                    "\tnotq %r11\n" ++
                    "\tmovq %r8, (%rdi)\n" ++
                    "\tmovq %r11, 8(%rdi)\n" ++
                    "\tmovq $0, (%r10)\n",
                .{symbol},
            ),
            .spinlocked_fetch_xor_i128_rdi_rsi_rdx_rax_rdx => |symbol| try writer.print(
                "\tmovq %rdx, %r9\n" ++
                    "\tmovq %rdi, %r8\n" ++
                    "\tshrq $3, %r8\n" ++
                    "\tandq $62, %r8\n" ++
                    "\tleaq {s}(%rip), %r10\n" ++
                    "\taddq %r8, %r10\n" ++
                    "\tmovl $1, %eax\n" ++
                    "1:\n" ++
                    "\txchgq %rax, (%r10)\n" ++
                    "\ttestq %rax, %rax\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjne 1b\n" ++
                    "\tmovq (%rdi), %rax\n" ++
                    "\tmovq 8(%rdi), %rdx\n" ++
                    "\tmovq %rax, %r8\n" ++
                    "\txorq %rsi, %r8\n" ++
                    "\tmovq %rdx, %r11\n" ++
                    "\txorq %r9, %r11\n" ++
                    "\tmovq %r8, (%rdi)\n" ++
                    "\tmovq %r11, 8(%rdi)\n" ++
                    "\tmovq $0, (%r10)\n",
                .{symbol},
            ),
            .spinlocked_fetch_or_i128_rdi_rsi_rdx_rax_rdx => |symbol| try writer.print(
                "\tmovq %rdx, %r9\n" ++
                    "\tmovq %rdi, %r8\n" ++
                    "\tshrq $3, %r8\n" ++
                    "\tandq $62, %r8\n" ++
                    "\tleaq {s}(%rip), %r10\n" ++
                    "\taddq %r8, %r10\n" ++
                    "\tmovl $1, %eax\n" ++
                    "1:\n" ++
                    "\txchgq %rax, (%r10)\n" ++
                    "\ttestq %rax, %rax\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjne 1b\n" ++
                    "\tmovq (%rdi), %rax\n" ++
                    "\tmovq 8(%rdi), %rdx\n" ++
                    "\tmovq %rax, %r8\n" ++
                    "\torq %rsi, %r8\n" ++
                    "\tmovq %rdx, %r11\n" ++
                    "\torq %r9, %r11\n" ++
                    "\tmovq %r8, (%rdi)\n" ++
                    "\tmovq %r11, 8(%rdi)\n" ++
                    "\tmovq $0, (%r10)\n",
                .{symbol},
            ),
            .spinlocked_fetch_and_i128_rdi_rsi_rdx_rax_rdx => |symbol| try writer.print(
                "\tmovq %rdx, %r9\n" ++
                    "\tmovq %rdi, %r8\n" ++
                    "\tshrq $3, %r8\n" ++
                    "\tandq $62, %r8\n" ++
                    "\tleaq {s}(%rip), %r10\n" ++
                    "\taddq %r8, %r10\n" ++
                    "\tmovl $1, %eax\n" ++
                    "1:\n" ++
                    "\txchgq %rax, (%r10)\n" ++
                    "\ttestq %rax, %rax\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjne 1b\n" ++
                    "\tmovq (%rdi), %rax\n" ++
                    "\tmovq 8(%rdi), %rdx\n" ++
                    "\tmovq %rax, %r8\n" ++
                    "\tandq %rsi, %r8\n" ++
                    "\tmovq %rdx, %r11\n" ++
                    "\tandq %r9, %r11\n" ++
                    "\tmovq %r8, (%rdi)\n" ++
                    "\tmovq %r11, 8(%rdi)\n" ++
                    "\tmovq $0, (%r10)\n",
                .{symbol},
            ),
            .spinlocked_fetch_sub_i128_rdi_rsi_rdx_rax_rdx => |symbol| try writer.print(
                "\tmovq %rdx, %r9\n" ++
                    "\tmovq %rdi, %r8\n" ++
                    "\tshrq $3, %r8\n" ++
                    "\tandq $62, %r8\n" ++
                    "\tleaq {s}(%rip), %r10\n" ++
                    "\taddq %r8, %r10\n" ++
                    "\tmovl $1, %eax\n" ++
                    "1:\n" ++
                    "\txchgq %rax, (%r10)\n" ++
                    "\ttestq %rax, %rax\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjne 1b\n" ++
                    "\tmovq (%rdi), %rax\n" ++
                    "\tmovq 8(%rdi), %rdx\n" ++
                    "\tmovq %rax, %r8\n" ++
                    "\tmovq %rdx, %r11\n" ++
                    "\tsubq %rsi, %r8\n" ++
                    "\tsbbq %r9, %r11\n" ++
                    "\tmovq %r8, (%rdi)\n" ++
                    "\tmovq %r11, 8(%rdi)\n" ++
                    "\tmovq $0, (%r10)\n",
                .{symbol},
            ),
            .spinlocked_fetch_add_i128_rdi_rsi_rdx_rax_rdx => |symbol| try writer.print(
                "\tmovq %rdx, %r9\n" ++
                    "\tmovq %rdi, %r8\n" ++
                    "\tshrq $3, %r8\n" ++
                    "\tandq $62, %r8\n" ++
                    "\tleaq {s}(%rip), %r10\n" ++
                    "\taddq %r8, %r10\n" ++
                    "\tmovl $1, %eax\n" ++
                    "1:\n" ++
                    "\txchgq %rax, (%r10)\n" ++
                    "\ttestq %rax, %rax\n" ++
                    "\tmovl $1, %eax\n" ++
                    "\tjne 1b\n" ++
                    "\tmovq (%rdi), %rax\n" ++
                    "\tmovq 8(%rdi), %rdx\n" ++
                    "\tmovq %rax, %r8\n" ++
                    "\tmovq %rdx, %r11\n" ++
                    "\taddq %rsi, %r8\n" ++
                    "\tadcq %r9, %r11\n" ++
                    "\tmovq %r8, (%rdi)\n" ++
                    "\tmovq %r11, 8(%rdi)\n" ++
                    "\tmovq $0, (%r10)\n",
                .{symbol},
            ),
            .memmove_rdi_rsi_rdx_rax => try writer.writeAll(
                "\tmovq %rdi, %rax\n" ++
                    "\ttestq %rdx, %rdx\n" ++
                    "\tje 4f\n" ++
                    "\tcmpq %rsi, %rdi\n" ++
                    "\tja 2f\n" ++
                    "1:\n" ++
                    "\tcld\n" ++
                    "\tmovq %rdx, %rcx\n" ++
                    "\trep movsb\n" ++
                    "\tjmp 4f\n" ++
                    "2:\n" ++
                    "\tstd\n" ++
                    "\tleaq -1(%rdi,%rdx), %rdi\n" ++
                    "\tleaq -1(%rsi,%rdx), %rsi\n" ++
                    "\tmovq %rdx, %rcx\n" ++
                    "\trep movsb\n" ++
                    "\tcld\n" ++
                    "4:\n",
            ),
            .stack_probe_rax_rcx_rsp => try writer.writeAll(
                "\tpushq %rcx\n" ++
                    "\tmovq %rax, %rcx\n" ++
                    "\tcmpq $0x1000, %rcx\n" ++
                    "\tjb 2f\n" ++
                    "1:\n" ++
                    "\tsubq $0x1000, %rsp\n" ++
                    "\torl $0, 16(%rsp)\n" ++
                    "\tsubq $0x1000, %rcx\n" ++
                    "\tcmpq $0x1000, %rcx\n" ++
                    "\tja 1b\n" ++
                    "2:\n" ++
                    "\tsubq %rcx, %rsp\n" ++
                    "\torl $0, 16(%rsp)\n" ++
                    "\taddq %rax, %rsp\n" ++
                    "\tpopq %rcx\n",
            ),
            .guarded_memset_rdi_sil_rdx_rcx_rax => try writer.writeAll(
                "\tcmpq %rdx, %rcx\n" ++
                    "\tjae 1f\n" ++
                    "\tud2\n" ++
                    "1:\n" ++
                    "\tmovq %rdi, %rax\n" ++
                    "\ttestq %rdx, %rdx\n" ++
                    "\tje 3f\n" ++
                    "\txorl %ecx, %ecx\n" ++
                    "2:\n" ++
                    "\tmovb %sil, (%rdi,%rcx)\n" ++
                    "\tincq %rcx\n" ++
                    "\tcmpq %rcx, %rdx\n" ++
                    "\tjne 2b\n" ++
                    "3:\n",
            ),
            .guarded_memcpy_rdi_rsi_rdx_rcx_rax => try writer.writeAll(
                "\tcmpq %rdx, %rcx\n" ++
                    "\tjae 1f\n" ++
                    "\tud2\n" ++
                    "1:\n" ++
                    "\tmovq %rdi, %rax\n" ++
                    "\ttestq %rdx, %rdx\n" ++
                    "\tje 2f\n" ++
                    "\tcld\n" ++
                    "\tmovq %rdx, %rcx\n" ++
                    "\trep movsb\n" ++
                    "2:\n",
            ),
            .guarded_strncat_rdi_rsi_rdx_rcx_rax => try writer.writeAll(
                "\tmovq %rdi, %rax\n" ++
                    "\ttestq %rcx, %rcx\n" ++
                    "\tjne 1f\n" ++
                    "0:\n" ++
                    "\tud2\n" ++
                    "1:\n" ++
                    "\txorl %r8d, %r8d\n" ++
                    "2:\n" ++
                    "\tcmpb $0, (%rdi,%r8)\n" ++
                    "\tje 3f\n" ++
                    "\tincq %r8\n" ++
                    "\tdecq %rcx\n" ++
                    "\tje 0b\n" ++
                    "\tjmp 2b\n" ++
                    "3:\n" ++
                    "\tleaq (%rdi,%r8), %r9\n" ++
                    "\ttestq %rdx, %rdx\n" ++
                    "\tje 5f\n" ++
                    "\txorl %r8d, %r8d\n" ++
                    "4:\n" ++
                    "\tmovzbl (%rsi,%r8), %r10d\n" ++
                    "\ttestb %r10b, %r10b\n" ++
                    "\tje 5f\n" ++
                    "\tmovb %r10b, (%r9,%r8)\n" ++
                    "\tdecq %rcx\n" ++
                    "\tje 0b\n" ++
                    "\tincq %r8\n" ++
                    "\tcmpq %rdx, %r8\n" ++
                    "\tjb 4b\n" ++
                    "5:\n" ++
                    "\tmovb $0, (%r9,%r8)\n",
            ),
            .guarded_strcat_rdi_rsi_rdx_rax => try writer.writeAll(
                "\tmovq %rdi, %rax\n" ++
                    "\ttestq %rdx, %rdx\n" ++
                    "\tjne 1f\n" ++
                    "0:\n" ++
                    "\tud2\n" ++
                    "1:\n" ++
                    "\txorl %r8d, %r8d\n" ++
                    "2:\n" ++
                    "\tcmpb $0, (%rdi,%r8)\n" ++
                    "\tje 3f\n" ++
                    "\tincq %r8\n" ++
                    "\tdecq %rdx\n" ++
                    "\tje 0b\n" ++
                    "\tjmp 2b\n" ++
                    "3:\n" ++
                    "\tleaq (%rdi,%r8), %r9\n" ++
                    "\txorl %r8d, %r8d\n" ++
                    "4:\n" ++
                    "\tmovzbl (%rsi,%r8), %r10d\n" ++
                    "\ttestb %r10b, %r10b\n" ++
                    "\tje 5f\n" ++
                    "\tmovb %r10b, (%r9,%r8)\n" ++
                    "\tdecq %rdx\n" ++
                    "\tje 0b\n" ++
                    "\tincq %r8\n" ++
                    "\tjmp 4b\n" ++
                    "5:\n" ++
                    "\tmovb $0, (%r9,%r8)\n",
            ),
            .guarded_strncpy_rdi_rsi_rdx_rcx_rax => try writer.writeAll(
                "\tmovq %rdi, %rax\n" ++
                    "\tcmpq %rdx, %rcx\n" ++
                    "\tjae 1f\n" ++
                    "0:\n" ++
                    "\tud2\n" ++
                    "1:\n" ++
                    "\ttestq %rdx, %rdx\n" ++
                    "\tje 5f\n" ++
                    "\txorl %r8d, %r8d\n" ++
                    "2:\n" ++
                    "\tmovzbl (%rsi,%r8), %r9d\n" ++
                    "\ttestb %r9b, %r9b\n" ++
                    "\tje 3f\n" ++
                    "\tmovb %r9b, (%rdi,%r8)\n" ++
                    "\tincq %r8\n" ++
                    "\tcmpq %rdx, %r8\n" ++
                    "\tjb 2b\n" ++
                    "\tjmp 5f\n" ++
                    "3:\n" ++
                    "\tmovb $0, (%rdi,%r8)\n" ++
                    "\tincq %r8\n" ++
                    "\tcmpq %rdx, %r8\n" ++
                    "\tjb 3b\n",
            ),
            .guarded_strcpy_rdi_rsi_rdx_rax => try writer.writeAll(
                "\tmovq %rdi, %rax\n" ++
                    "\ttestq %rdx, %rdx\n" ++
                    "\tjne 1f\n" ++
                    "0:\n" ++
                    "\tud2\n" ++
                    "1:\n" ++
                    "\txorl %r8d, %r8d\n" ++
                    "2:\n" ++
                    "\tmovzbl (%rsi,%r8), %r9d\n" ++
                    "\ttestb %r9b, %r9b\n" ++
                    "\tje 3f\n" ++
                    "\tmovb %r9b, (%rdi,%r8)\n" ++
                    "\tdecq %rdx\n" ++
                    "\tje 0b\n" ++
                    "\tincq %r8\n" ++
                    "\tjmp 2b\n" ++
                    "3:\n" ++
                    "\tmovb $0, (%rdi,%r8)\n",
            ),
            .memset_rdi_sil_rdx_rax => try writer.writeAll(
                "\tmovq %rdi, %rax\n" ++
                    "\ttestq %rdx, %rdx\n" ++
                    "\tje 2f\n" ++
                    "\txorl %ecx, %ecx\n" ++
                    "1:\n" ++
                    "\tmovb %sil, (%rdi,%rcx)\n" ++
                    "\tincq %rcx\n" ++
                    "\tcmpq %rcx, %rdx\n" ++
                    "\tjne 1b\n" ++
                    "2:\n",
            ),
            .smin_i32_edi_esi_eax => try writer.writeAll("\tmovl %edi, %eax\n\tcmpl %esi, %edi\n\tcmovgl %esi, %eax\n"),
            .umin_i32_edi_esi_eax => try writer.writeAll("\tmovl %edi, %eax\n\tcmpl %esi, %edi\n\tcmoval %esi, %eax\n"),
            .smax_i32_edi_esi_eax => try writer.writeAll("\tmovl %edi, %eax\n\tcmpl %esi, %edi\n\tcmovll %esi, %eax\n"),
            .umax_i32_edi_esi_eax => try writer.writeAll("\tmovl %edi, %eax\n\tcmpl %esi, %edi\n\tcmovbl %esi, %eax\n"),
            .shift_mix_i32_edi_esi_eax => try writer.writeAll("\tmovl %esi, %ecx\n\tandl $31, %ecx\n\tmovl %edi, %eax\n\tshll %cl, %eax\n\tmovl %edi, %edx\n\tshrl %cl, %edx\n\txorl %edx, %eax\n"),
            .replace_low_i8_dil_sil_al => try writer.writeAll("\tmovl %edi, %eax\n\tandl $-8, %eax\n\tmovl %esi, %edx\n\tandl $7, %edx\n\torl %edx, %eax\n"),
            .read_flag_i8_dil_al => try writer.writeAll("\txorl %eax, %eax\n\ttestb %dil, %dil\n\tsets %al\n"),
            .ult_i8_dil_imm8_al => |imm| try writer.print("\txorl %eax, %eax\n\tcmpb ${}, %dil\n\tsetb %al\n", .{imm}),
            .store_imm8_abs => |store| try writer.print("\tmovb ${}, {x}\n", .{ store.value, store.address }),
            .cmp_ecx_arg32 => |reg| try writer.print("\tcmpl %ecx, {s}\n", .{reg.name32()}),
            .cmp_rcx_arg64 => |reg| try writer.print("\tcmpq %rcx, {s}\n", .{reg.name64()}),
            .cmp_ecx_imm32 => |value| try writer.print("\tcmpl ${}, %ecx\n", .{value}),
            .cmp_eax_imm32 => |value| try writer.print("\tcmpl ${}, %eax\n", .{value}),
            .cmp_arg64_imm64 => |cmp| try writer.print("\tmovabsq ${}, %rax\n\tcmpq %rax, {s}\n", .{ cmp.imm, cmp.reg.name64() }),
            .cmp_arg16_imm16 => |cmp| try writer.print("\tcmpw ${}, {s}\n", .{ cmp.imm, cmp.reg.name16() }),
            .cmp_rdi_imm64 => |value| try writer.print("\tmovabsq ${}, %rax\n\tcmpq %rax, %rdi\n", .{value}),
            .cmp_rdx_rcx => try writer.writeAll("\tcmpq %rdx, %rcx\n"),
            .cmp_rdx_rdi => try writer.writeAll("\tcmpq %rdi, %rdx\n"),
            .cmp_rax_rdx => try writer.writeAll("\tcmpq %rdx, %rax\n"),
            .setb_eax => try writer.writeAll("\tsetb %al\n\tmovzbl %al, %eax\n"),
            .seta_eax => try writer.writeAll("\tseta %al\n\tmovzbl %al, %eax\n"),
            .sete_eax => try writer.writeAll("\tsete %al\n\tmovzbl %al, %eax\n"),
            .setg_eax => try writer.writeAll("\tsetg %al\n\tmovzbl %al, %eax\n"),
            .setne_eax => try writer.writeAll("\tsetne %al\n\tmovzbl %al, %eax\n"),
            .test_eax_eax => try writer.writeAll("\ttestl %eax, %eax\n"),
            .test_rax_rax => try writer.writeAll("\ttestq %rax, %rax\n"),
            .test_rdx_rdx => try writer.writeAll("\ttestq %rdx, %rdx\n"),
            .mulsd_xmm1_xmm0 => try writer.writeAll("\tmulsd %xmm1, %xmm0\n"),
            .mulss_xmm1_xmm0 => try writer.writeAll("\tmulss %xmm1, %xmm0\n"),
            .mulsd_xmm => |mul| try writer.print("\tmulsd {s}, {s}\n", .{ mul.src.name(), mul.dst.name() }),
            .mulss_xmm => |mul| try writer.print("\tmulss {s}, {s}\n", .{ mul.src.name(), mul.dst.name() }),
            .subsd_xmm => |sub| try writer.print("\tsubsd {s}, {s}\n", .{ sub.src.name(), sub.dst.name() }),
            .subss_xmm => |sub| try writer.print("\tsubss {s}, {s}\n", .{ sub.src.name(), sub.dst.name() }),
            .divsd_xmm => |div| try writer.print("\tdivsd {s}, {s}\n", .{ div.src.name(), div.dst.name() }),
            .divss_xmm => |div| try writer.print("\tdivss {s}, {s}\n", .{ div.src.name(), div.dst.name() }),
            .addss_xmm1_xmm0 => try writer.writeAll("\taddss %xmm1, %xmm0\n"),
            .subss_xmm1_xmm0 => try writer.writeAll("\tsubss %xmm1, %xmm0\n"),
            .divsd_xmm1_xmm0 => try writer.writeAll("\tdivsd %xmm1, %xmm0\n"),
            .xorps_xmm1_xmm0 => try writer.writeAll("\txorps %xmm1, %xmm0\n"),
            .movapd_xmm1_xmm0 => try writer.writeAll("\tmovapd %xmm1, %xmm0\n"),
            .movapd_xmm => |mov| try writer.print("\tmovapd {s}, {s}\n", .{ mov.src.name(), mov.dst.name() }),
            .unpcklps_xmm => |mov| try writer.print("\tunpcklps {s}, {s}\n", .{ mov.src.name(), mov.dst.name() }),
            .shufps_high_f32_to_low => |reg| try writer.print("\tshufps $85, {s}, {s}\n", .{ reg.name(), reg.name() }),
            .cvtsi2ss_edi_xmm0 => try writer.writeAll("\tcvtsi2ssl %edi, %xmm0\n"),
            .cvtsi2sd_edi_xmm0 => try writer.writeAll("\tcvtsi2sdl %edi, %xmm0\n"),
            .cvtsi2ss_rdi_xmm0 => try writer.writeAll("\tcvtsi2ssq %rdi, %xmm0\n"),
            .cvtsi2sd_rdi_xmm0 => try writer.writeAll("\tcvtsi2sdq %rdi, %xmm0\n"),
            .cvttss2si_xmm0_eax => try writer.writeAll("\tcvttss2si %xmm0, %eax\n"),
            .cvttsd2si_xmm0_eax => try writer.writeAll("\tcvttsd2si %xmm0, %eax\n"),
            .cvtsd2ss_xmm0_xmm0 => try writer.writeAll("\tcvtsd2ss %xmm0, %xmm0\n"),
            .cvtss2sd_xmm0_xmm0 => try writer.writeAll("\tcvtss2sd %xmm0, %xmm0\n"),
            .cvtsd2ss_xmm => |cvt| try writer.print("\tcvtsd2ss {s}, {s}\n", .{ cvt.src.name(), cvt.dst.name() }),
            .cvtss2sd_xmm => |cvt| try writer.print("\tcvtss2sd {s}, {s}\n", .{ cvt.src.name(), cvt.dst.name() }),
            .mov_edi_edi => try writer.writeAll("\tmovl %edi, %edi\n"),
            .mov_imm64_xmm0 => |bits| try writer.print("\tmovabsq ${x}, %rax\n\tmovq %rax, %xmm0\n", .{bits}),
            .mov_imm64_xmm1 => |bits| try writer.print("\tmovabsq ${x}, %rax\n\tmovq %rax, %xmm1\n", .{bits}),
            .mov_imm32_xmm0 => |bits| try writer.print("\tmovl ${x}, %eax\n\tmovd %eax, %xmm0\n", .{bits}),
            .mov_imm32_xmm1 => |bits| try writer.print("\tmovl ${x}, %eax\n\tmovd %eax, %xmm1\n", .{bits}),
            .mov_imm64_xmm => |load| try writer.print("\tmovabsq ${x}, %rax\n\tmovq %rax, {s}\n", .{ load.bits, load.reg.name() }),
            .mov_imm32_xmm => |load| try writer.print("\tmovl ${x}, %eax\n\tmovd %eax, {s}\n", .{ load.bits, load.reg.name() }),
            .ucomisd => |cmp| try writer.print("\tucomisd {s}, {s}\n", .{ cmp.src.name(), cmp.dst.name() }),
            .ucomisd_xmm1_xmm0 => try writer.writeAll("\tucomisd %xmm1, %xmm0\n"),
            .ucomiss_xmm1_xmm0 => try writer.writeAll("\tucomiss %xmm1, %xmm0\n"),
            .ucomiss_xmm0_xmm1 => try writer.writeAll("\tucomiss %xmm0, %xmm1\n"),
            .oltss_xmm0_xmm1_al => try writer.writeAll("\txorl %eax, %eax\n\tucomiss %xmm0, %xmm1\n\tseta %al\n"),
            .fneg_x86_fp80_stack8_st0 => try writer.writeAll("\tfldt 8(%rsp)\n\tfchs\n"),
            .fneg_fp128_xmm0 => try writer.writeAll("\tmovabsq $0x8000000000000000, %rax\n\tmovq %rax, %xmm1\n\tpslldq $8, %xmm1\n\txorps %xmm1, %xmm0\n"),
            .addsd_xmm1_xmm0 => try writer.writeAll("\taddsd %xmm1, %xmm0\n"),
            .sub_rsp_8 => try writer.writeAll("\tsubq $8, %rsp\n"),
            .add_rsp_8 => try writer.writeAll("\taddq $8, %rsp\n"),
            .push_imm32 => |value| try writer.print("\tpushq ${}\n", .{value}),
            .push_stack_disp8 => |offset| try writer.print("\tpushq {}(%rsp)\n", .{offset}),
            .push_stack_disp32 => |offset| try writer.print("\tpushq {}(%rsp)\n", .{offset}),
            .sub_rsp_24 => try writer.writeAll("\tsubq $24, %rsp\n"),
            .add_rsp_24 => try writer.writeAll("\taddq $24, %rsp\n"),
            .sub_rsp_40 => try writer.writeAll("\tsubq $40, %rsp\n"),
            .add_rsp_40 => try writer.writeAll("\taddq $40, %rsp\n"),
            .sub_rsp_56 => try writer.writeAll("\tsubq $56, %rsp\n"),
            .add_rsp_56 => try writer.writeAll("\taddq $56, %rsp\n"),
            .sub_rsp_imm8 => |value| try writer.print("\tsubq ${}, %rsp\n", .{value}),
            .sub_rsp_imm32 => |value| try writer.print("\tsubq ${}, %rsp\n", .{value}),
            .add_rsp_imm8 => |value| try writer.print("\taddq ${}, %rsp\n", .{value}),
            .add_rsp_imm32 => |value| try writer.print("\taddq ${}, %rsp\n", .{value}),
            .spill_arg_rsp => |spill| {
                try writer.print("\tmovl {s}, ", .{spill.reg.name32()});
                try printFrameAddress(writer, spill.frame_index);
                try writer.writeByte('\n');
            },
            .spill_arg64_rsp => |spill| {
                try writer.print("\tmovq {s}, ", .{spill.reg.name64()});
                try printFrameAddress(writer, spill.frame_index);
                try writer.writeByte('\n');
            },
            .reload_arg_rsp => |reload| {
                try writer.writeAll("\tmovl ");
                try printFrameAddress(writer, reload.frame_index);
                try writer.print(", {s}\n", .{reload.reg.name32()});
            },
            .reload_arg64_rsp => |reload| {
                try writer.writeAll("\tmovq ");
                try printFrameAddress(writer, reload.frame_index);
                try writer.print(", {s}\n", .{reload.reg.name64()});
            },
            .spill_xmm32_rsp => |spill| {
                try writer.print("\tmovss {s}, ", .{spill.reg.name()});
                try printFrameAddress(writer, spill.frame_index);
                try writer.writeByte('\n');
            },
            .reload_xmm32_rsp => |reload| {
                try writer.writeAll("\tmovss ");
                try printFrameAddress(writer, reload.frame_index);
                try writer.print(", {s}\n", .{reload.reg.name()});
            },
            .spill_xmm64_rsp => |spill| {
                try writer.print("\tmovsd {s}, ", .{spill.reg.name()});
                try printFrameAddress(writer, spill.frame_index);
                try writer.writeByte('\n');
            },
            .reload_xmm64_rsp => |reload| {
                try writer.writeAll("\tmovsd ");
                try printFrameAddress(writer, reload.frame_index);
                try writer.print(", {s}\n", .{reload.reg.name()});
            },
            .spill_rdi_rsi_rsp24 => try writer.writeAll("\tmovq %rdi, 8(%rsp)\n\tmovq %rsi, 16(%rsp)\n"),
            .reload_rdi_rsp24 => try writer.writeAll("\tmovq 8(%rsp), %rdi\n"),
            .reload_rsi_rsp24 => try writer.writeAll("\tmovq 16(%rsp), %rsi\n"),
            .spill_eax_rsp => |frame_index| {
                try writer.writeAll("\tmovl %eax, ");
                try printFrameAddress(writer, frame_index);
                try writer.writeByte('\n');
            },
            .reload_rsp_eax => |frame_index| {
                try writer.writeAll("\tmovl ");
                try printFrameAddress(writer, frame_index);
                try writer.writeAll(", %eax\n");
            },
            .spill_rax_rsp => |frame_index| {
                try writer.writeAll("\tmovq %rax, ");
                try printFrameAddress(writer, frame_index);
                try writer.writeByte('\n');
            },
            .reload_rsp_rax => |frame_index| {
                try writer.writeAll("\tmovq ");
                try printFrameAddress(writer, frame_index);
                try writer.writeAll(", %rax\n");
            },
            .load_stack_disp8_eax => |offset| try writer.print("\tmovl {}(%rsp), %eax\n", .{offset}),
            .load_stack_disp32_eax => |offset| try writer.print("\tmovl {}(%rsp), %eax\n", .{offset}),
            .load_stack_rcx4_disp8_eax => |offset| try writer.print("\tmovl {}(%rsp,%rcx,4), %eax\n", .{offset}),
            .load_stack_rcx4_disp32_eax => |offset| try writer.print("\tmovl {}(%rsp,%rcx,4), %eax\n", .{offset}),
            .load_stack_disp8_rax => |offset| try writer.print("\tmovq {}(%rsp), %rax\n", .{offset}),
            .load_stack_disp32_rax => |offset| try writer.print("\tmovq {}(%rsp), %rax\n", .{offset}),
            .load_stack_disp8_u8_eax => |offset| try writer.print("\tmovzbl {}(%rsp), %eax\n", .{offset}),
            .load_stack_disp32_u8_eax => |offset| try writer.print("\tmovzbl {}(%rsp), %eax\n", .{offset}),
            .load_stack_disp8_u16_eax => |offset| try writer.print("\tmovzwl {}(%rsp), %eax\n", .{offset}),
            .load_stack_disp32_u16_eax => |offset| try writer.print("\tmovzwl {}(%rsp), %eax\n", .{offset}),
            .load_stack_disp8_xmm0 => |offset| try writer.print("\tmovsd {}(%rsp), %xmm0\n", .{offset}),
            .load_stack_disp32_xmm0 => |offset| try writer.print("\tmovsd {}(%rsp), %xmm0\n", .{offset}),
            .load_stack_disp8_xmm0_f32 => |offset| try writer.print("\tmovss {}(%rsp), %xmm0\n", .{offset}),
            .load_stack_disp32_xmm0_f32 => |offset| try writer.print("\tmovss {}(%rsp), %xmm0\n", .{offset}),
            .load_stack_disp8_xmm => |load| try writer.print("\tmovsd {}(%rsp), {s}\n", .{ load.disp, load.reg.name() }),
            .load_stack_disp32_xmm => |load| try writer.print("\tmovsd {}(%rsp), {s}\n", .{ load.disp, load.reg.name() }),
            .load_stack_disp8_xmm_f32 => |load| try writer.print("\tmovss {}(%rsp), {s}\n", .{ load.disp, load.reg.name() }),
            .load_stack_disp32_xmm_f32 => |load| try writer.print("\tmovss {}(%rsp), {s}\n", .{ load.disp, load.reg.name() }),
            .load_stack_disp8_arg32 => |load| try writer.print("\tmovl {}(%rsp), {s}\n", .{ load.disp, load.reg.name32() }),
            .load_stack_disp8_arg64 => |load| try writer.print("\tmovq {}(%rsp), {s}\n", .{ load.disp, load.reg.name64() }),
            .load_stack_disp32_arg32 => |load| try writer.print("\tmovl {}(%rsp), {s}\n", .{ load.disp, load.reg.name32() }),
            .load_stack_disp32_arg64 => |load| try writer.print("\tmovq {}(%rsp), {s}\n", .{ load.disp, load.reg.name64() }),
            .load_rax_ptr_disp8_rax => |offset| try writer.print("\tmovq {}(%rax), %rax\n", .{offset}),
            .load_rax_ptr_disp32_rax => |offset| try writer.print("\tmovq {}(%rax), %rax\n", .{offset}),
            .load_rax_ptr_disp8_u8_eax => |offset| try writer.print("\tmovzbl {}(%rax), %eax\n", .{offset}),
            .load_rax_ptr_disp8_u16_eax => |offset| try writer.print("\tmovzwl {}(%rax), %eax\n", .{offset}),
            .load_rax_ptr_disp8_eax => |offset| try writer.print("\tmovl {}(%rax), %eax\n", .{offset}),
            .load_rax_ptr_rdx => try writer.writeAll("\tmovq (%rax), %rdx\n"),
            .load_rax_ptr_eax => try writer.writeAll("\tmovl (%rax), %eax\n"),
            .load_arg_ptr_eax => |reg| try writer.print("\tmovl ({s}), %eax\n", .{reg.name64()}),
            .load_arg_ptr_disp8_rax => |load| try writer.print("\tmovq {}({s}), %rax\n", .{ load.offset, load.reg.name64() }),
            .load_arg_ptr_disp32_rax => |load| try writer.print("\tmovq {}({s}), %rax\n", .{ load.offset, load.reg.name64() }),
            .load_arg_ptr_disp8_eax => |load| try writer.print("\tmovl {}({s}), %eax\n", .{ load.offset, load.reg.name64() }),
            .load_arg_ptr_disp8_u8_eax => |load| try writer.print("\tmovzbl {}({s}), %eax\n", .{ load.offset, load.reg.name64() }),
            .load_arg_ptr_disp8_u16_eax => |load| try writer.print("\tmovzwl {}({s}), %eax\n", .{ load.offset, load.reg.name64() }),
            .add_arg_ptr_disp4_eax => |reg| try writer.print("\taddl 4({s}), %eax\n", .{reg.name64()}),
            .store_eax_arg_ptr => |reg| try writer.print("\tmovl %eax, ({s})\n", .{reg.name64()}),
            .store_imm64_arg_ptr_disp8 => |store| try writer.print("\tmovq ${}, {}({s})\n", .{ store.imm, store.offset, store.reg.name64() }),
            .store_arg64_arg_ptr_disp8 => |store| try writer.print("\tmovq {s}, {}({s})\n", .{ store.src_reg.name64(), store.offset, store.ptr_reg.name64() }),
            .store_arg64_arg_ptr_disp32 => |store| try writer.print("\tmovq {s}, {}({s})\n", .{ store.src_reg.name64(), store.offset, store.ptr_reg.name64() }),
            .store_rax_arg_ptr_disp8 => |store| try writer.print("\tmovq %rax, {}({s})\n", .{ store.offset, store.reg.name64() }),
            .store_rax_arg_ptr_disp32 => |store| try writer.print("\tmovq %rax, {}({s})\n", .{ store.offset, store.reg.name64() }),
            .store_eax_arg_ptr_disp8 => |store| try writer.print("\tmovl %eax, {}({s})\n", .{ store.offset, store.reg.name64() }),
            .store_eax_arg_ptr_disp32 => |store| try writer.print("\tmovl %eax, {}({s})\n", .{ store.offset, store.reg.name64() }),
            .store_eax_stack_disp8 => |offset| try writer.print("\tmovl %eax, {}(%rsp)\n", .{offset}),
            .store_eax_stack_disp32 => |offset| try writer.print("\tmovl %eax, {}(%rsp)\n", .{offset}),
            .store_al_stack_disp8 => |offset| try writer.print("\tmovb %al, {}(%rsp)\n", .{offset}),
            .store_al_stack_disp32 => |offset| try writer.print("\tmovb %al, {}(%rsp)\n", .{offset}),
            .store_eax_stack_rcx4_disp8 => |offset| try writer.print("\tmovl %eax, {}(%rsp,%rcx,4)\n", .{offset}),
            .store_eax_stack_rcx4_disp32 => |offset| try writer.print("\tmovl %eax, {}(%rsp,%rcx,4)\n", .{offset}),
            .store_al_arg_ptr_disp8 => |store| try writer.print("\tmovb %al, {}({s})\n", .{ store.offset, store.reg.name64() }),
            .store_al_arg_ptr_disp32 => |store| try writer.print("\tmovb %al, {}({s})\n", .{ store.offset, store.reg.name64() }),
            .store_ax_arg_ptr_disp8 => |store| try writer.print("\tmovw %ax, {}({s})\n", .{ store.offset, store.reg.name64() }),
            .store_ax_arg_ptr_disp32 => |store| try writer.print("\tmovw %ax, {}({s})\n", .{ store.offset, store.reg.name64() }),
            .store_xmm0_arg_ptr_disp8 => |store| try writer.print("\tmovsd %xmm0, {}({s})\n", .{ store.offset, store.reg.name64() }),
            .store_xmm0_arg_ptr_disp32 => |store| try writer.print("\tmovsd %xmm0, {}({s})\n", .{ store.offset, store.reg.name64() }),
            .store_xmm0_f32_arg_ptr_disp8 => |store| try writer.print("\tmovss %xmm0, {}({s})\n", .{ store.offset, store.reg.name64() }),
            .store_xmm0_f32_arg_ptr_disp32 => |store| try writer.print("\tmovss %xmm0, {}({s})\n", .{ store.offset, store.reg.name64() }),
            .store_imm8_arg_ptr_disp8 => |store| try writer.print("\tmovb ${}, {}({s})\n", .{ store.imm, store.offset, store.reg.name64() }),
            .load_f128_arg_ptr_xmm0 => |load| try writer.print("\tmovaps {}({s}), %xmm0\n", .{ load.offset, load.reg.name64() }),
            .load_f128_const_xmm0 => |symbol| try writer.print("\tmovaps {s}(%rip), %xmm0\n", .{symbol}),
            .load_f128_const_xmm1 => |symbol| try writer.print("\tmovaps {s}(%rip), %xmm1\n", .{symbol}),
            .store_f128_xmm0_arg_ptr => |store| try writer.print("\tmovaps %xmm0, {}({s})\n", .{ store.offset, store.reg.name64() }),
            .volatile_roundtrip_rdi_esi_eax => try writer.writeAll("\tmovl %esi, (%rdi)\n\tmovl (%rdi), %eax\n"),
            .load_global_i32_eax => |symbol| try writer.print("\tmovl {s}(%rip), %eax\n", .{symbol}),
            .load_global_ptr_rax => |symbol| try writer.print("\tmovq {s}(%rip), %rax\n", .{symbol}),
            .lea_global_rax => |symbol| try writer.print("\tleaq {s}(%rip), %rax\n", .{symbol}),
            .lea_global_rdi => |symbol| try writer.print("\tleaq {s}(%rip), %rdi\n", .{symbol}),
            .lea_global_rsi => |symbol| try writer.print("\tleaq {s}(%rip), %rsi\n", .{symbol}),
            .lea_global_rdx => |symbol| try writer.print("\tleaq {s}(%rip), %rdx\n", .{symbol}),
            .store_eax_global_i32 => |symbol| try writer.print("\tmovl %eax, {s}(%rip)\n", .{symbol}),
            .load_tls_i32_eax => |symbol| try writer.print("\tmovl %fs:{s}@TPOFF, %eax\n", .{symbol}),
            .add_tls_i32_eax => |symbol| try writer.print("\taddl %fs:{s}@TPOFF, %eax\n", .{symbol}),
            .store_eax_tls_i32 => |symbol| try writer.print("\tmovl %eax, %fs:{s}@TPOFF\n", .{symbol}),
            .atomic_xadd_global_eax => |symbol| try writer.print("\tlock xaddl %eax, {s}(%rip)\n", .{symbol}),
            .mov_rsp_rdi => try writer.writeAll("\tmovq %rsp, %rdi\n"),
            .and_rsp_neg16 => try writer.writeAll("\tandq $-16, %rsp\n"),
            .direct_call => |call| try writer.print("\tcallq {s}\n", .{call.symbol}),
            .direct_jump => |symbol| try writer.print("\tjmp {s}\n", .{symbol}),
            .indirect_call_rax => try writer.writeAll("\tcallq *%rax\n"),
            .noreturn_direct_call => |symbol| try writer.print("\tcallq {s}\n", .{symbol}),
            .cmp_arg8_imm8 => |cmp| try writer.print("\tcmpb ${}, {s}\n", .{ cmp.imm, cmp.reg.name8() }),
            .test_arg8 => |reg| try writer.print("\ttestb {s}, {s}\n", .{ reg.name8(), reg.name8() }),
            .test_arg32 => |reg| try writer.print("\ttestl {s}, {s}\n", .{ reg.name32(), reg.name32() }),
            .test_arg64 => |reg| try writer.print("\ttestq {s}, {s}\n", .{ reg.name64(), reg.name64() }),
            .base64_raw_args_to_decode4_regs => try writer.writeAll(
                \\    addq $4096, %rax
                \\    movq %rdi, %r8
                \\    movq %rdx, %rdi
                \\    movq %r8, %rdx
                \\    movq %rsi, %r8
                \\    movq %rcx, %rsi
                \\    movq %r8, %rcx
                \\
            ),
            .base64_decode4_from_table_rax => try writer.writeAll(
                \\    cmpq $4, %rsi
                \\    jne .Lbase64_decode4_fail
                \\    movzbl 0(%rdi), %r8d
                \\    movzbl (%rax,%r8), %r8d
                \\    cmpb $255, %r8b
                \\    je .Lbase64_decode4_fail
                \\    movzbl 1(%rdi), %r9d
                \\    movzbl (%rax,%r9), %r9d
                \\    cmpb $255, %r9b
                \\    je .Lbase64_decode4_fail
                \\    movzbl 2(%rdi), %r10d
                \\    cmpb $61, %r10b
                \\    je .Lbase64_decode4_two_pad
                \\    movzbl (%rax,%r10), %r10d
                \\    cmpb $255, %r10b
                \\    je .Lbase64_decode4_fail
                \\    movzbl 3(%rdi), %r11d
                \\    cmpb $61, %r11b
                \\    je .Lbase64_decode4_one_pad
                \\    movzbl (%rax,%r11), %r11d
                \\    cmpb $255, %r11b
                \\    je .Lbase64_decode4_fail
                \\    cmpq $3, %rcx
                \\    jb .Lbase64_decode4_fail
                \\    shll $18, %r8d
                \\    shll $12, %r9d
                \\    orl %r9d, %r8d
                \\    shll $6, %r10d
                \\    orl %r10d, %r8d
                \\    orl %r11d, %r8d
                \\    movl %r8d, %r9d
                \\    shrl $16, %r9d
                \\    movb %r9b, 0(%rdx)
                \\    movl %r8d, %r9d
                \\    shrl $8, %r9d
                \\    movb %r9b, 1(%rdx)
                \\    movb %r8b, 2(%rdx)
                \\    movl $3, %eax
                \\    retq
                \\.Lbase64_decode4_one_pad:
                \\    cmpq $2, %rcx
                \\    jb .Lbase64_decode4_fail
                \\    shll $18, %r8d
                \\    shll $12, %r9d
                \\    orl %r9d, %r8d
                \\    shll $6, %r10d
                \\    orl %r10d, %r8d
                \\    movl %r8d, %r9d
                \\    shrl $16, %r9d
                \\    movb %r9b, 0(%rdx)
                \\    movl %r8d, %r9d
                \\    shrl $8, %r9d
                \\    movb %r9b, 1(%rdx)
                \\    movl $2, %eax
                \\    retq
                \\.Lbase64_decode4_two_pad:
                \\    cmpb $61, 3(%rdi)
                \\    jne .Lbase64_decode4_fail
                \\    cmpq $1, %rcx
                \\    jb .Lbase64_decode4_fail
                \\    shll $18, %r8d
                \\    shll $12, %r9d
                \\    orl %r9d, %r8d
                \\    movl %r8d, %r9d
                \\    shrl $16, %r9d
                \\    movb %r9b, 0(%rdx)
                \\    movl $1, %eax
                \\    retq
                \\.Lbase64_decode4_fail:
                \\    movabsq $-1, %rax
                \\    retq
                \\
            ),
            .syscall => try writer.writeAll("\tsyscall\n"),
            .ud2 => try writer.writeAll("\tud2\n"),
            .je => |label| try writer.print("\tje .L{s}_{s}\n", .{ function.name, label }),
            .jne => |label| try writer.print("\tjne .L{s}_{s}\n", .{ function.name, label }),
            .jo => |label| try writer.print("\tjo .L{s}_{s}\n", .{ function.name, label }),
            .jc => |label| try writer.print("\tjc .L{s}_{s}\n", .{ function.name, label }),
            .jp => |label| try writer.print("\tjp .L{s}_{s}\n", .{ function.name, label }),
            .js => |label| try writer.print("\tjs .L{s}_{s}\n", .{ function.name, label }),
            .jae => |label| try writer.print("\tjae .L{s}_{s}\n", .{ function.name, label }),
            .jle => |label| try writer.print("\tjle .L{s}_{s}\n", .{ function.name, label }),
            .jmp => |label| try writer.print("\tjmp .L{s}_{s}\n", .{ function.name, label }),
            .ret => try writer.writeAll("\tretq\n"),
        }
    }
}

fn printByteDirective(writer: anytype, bytes: []const u8) !void {
    var index: usize = 0;
    while (index < bytes.len) : (index += 1) {
        if (index % 16 == 0) {
            if (index != 0) try writer.writeByte('\n');
            try writer.writeAll("\t.byte ");
        } else {
            try writer.writeAll(", ");
        }
        try writer.print("0x{x:0>2}", .{bytes[index]});
    }
    try writer.writeByte('\n');
}

fn printFrameAddress(writer: anytype, frame_index: x86_64.FrameIndex) !void {
    const disp = frame_index.byteOffset() catch unreachable;
    if (disp == 0) {
        try writer.writeAll("(%rsp)");
    } else {
        try writer.print("{}(%rsp)", .{disp});
    }
}
