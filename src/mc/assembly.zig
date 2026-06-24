const x86_64 = @import("../codegen/x86_64.zig");

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
            .mov_arg_rax => |reg| try writer.print("\tmovq {s}, %rax\n", .{reg.name64()}),
            .movq_xmm_rax => |reg| try writer.print("\tmovq {s}, %rax\n", .{reg.name()}),
            .mov_arg_eax => |reg| try writer.print("\tmovl {s}, %eax\n", .{reg.name32()}),
            .mov_arg_arg => |mov| try writer.print("\tmovl {s}, {s}\n", .{ mov.src.name32(), mov.dst.name32() }),
            .mov_arg64_arg => |mov| try writer.print("\tmovq {s}, {s}\n", .{ mov.src.name64(), mov.dst.name64() }),
            .push_arg => |reg| try writer.print("\tpushq {s}\n", .{reg.name64()}),
            .push_rax => try writer.writeAll("\tpushq %rax\n"),
            .push_xmm64 => |reg| try writer.print("\tsubq $8, %rsp\n\tmovsd {s}, (%rsp)\n", .{reg.name()}),
            .binary_arg_eax => |binary| try writer.print("\t{s} {s}, %eax\n", .{ binary.op.mnemonic(), binary.reg.name32() }),
            .add_arg64_rax => |reg| try writer.print("\taddq {s}, %rax\n", .{reg.name64()}),
            .add_arg_high32_eax => |reg| try writer.print("\tmovq {s}, %rcx\n\tshrq $32, %rcx\n\taddl %ecx, %eax\n", .{reg.name64()}),
            .add_stack_disp8_eax => |offset| try writer.print("\taddl {}(%rsp), %eax\n", .{offset}),
            .add_stack_disp8_rax => |offset| try writer.print("\taddq {}(%rsp), %rax\n", .{offset}),
            .add_stack_disp32_eax => |offset| try writer.print("\taddl {}(%rsp), %eax\n", .{offset}),
            .add_stack_disp32_rax => |offset| try writer.print("\taddq {}(%rsp), %rax\n", .{offset}),
            .add_eax_imm32 => |value| try writer.print("\taddl ${}, %eax\n", .{value}),
            .shl_eax_imm5 => |amount| try writer.print("\tshll ${}, %eax\n", .{amount}),
            .or_eax_imm32 => |value| try writer.print("\torl ${}, %eax\n", .{value}),
            .imul_eax_imm32 => |value| try writer.print("\timull ${}, %eax, %eax\n", .{value}),
            .and_eax_imm32 => |value| try writer.print("\tandl ${}, %eax\n", .{value}),
            .shr_rax_imm6 => |amount| try writer.print("\tshrq ${}, %rax\n", .{amount}),
            .shl_rdx_imm6 => |amount| try writer.print("\tshlq ${}, %rdx\n", .{amount}),
            .or_rdx_rax => try writer.writeAll("\torq %rdx, %rax\n"),
            .shl_rcx_imm6 => |amount| try writer.print("\tshlq ${}, %rcx\n", .{amount}),
            .or_rcx_rax => try writer.writeAll("\torq %rcx, %rax\n"),
            .or_rcx_rdx => try writer.writeAll("\torq %rcx, %rdx\n"),
            .add_rax_imm8 => |value| try writer.print("\taddq ${}, %rax\n", .{value}),
            .add_ecx_eax => try writer.writeAll("\taddl %ecx, %eax\n"),
            .xor_ecx_ecx => try writer.writeAll("\txorl %ecx, %ecx\n"),
            .xor_ebp_ebp => try writer.writeAll("\txorl %ebp, %ebp\n"),
            .add_rdi_rcx4_ptr_eax => try writer.writeAll("\taddl (%rdi,%rcx,4), %eax\n"),
            .load_rdi_rcx4_ptr_r8d => try writer.writeAll("\tmovl (%rdi,%rcx,4), %r8d\n"),
            .cmp_r8d_arg32 => |reg| try writer.print("\tcmpl {s}, %r8d\n", .{reg.name32()}),
            .add_r8d_eax => try writer.writeAll("\taddl %r8d, %eax\n"),
            .inc_rcx => try writer.writeAll("\tincq %rcx\n"),
            .movzx_dil_edi => try writer.writeAll("\tmovzbl %dil, %edi\n"),
            .and_edi_imm8 => |value| try writer.print("\tandl ${}, %edi\n", .{value}),
            .load_rax_rdi_u8_eax => try writer.writeAll("\tmovzbl (%rax,%rdi), %eax\n"),
            .smin_i32_edi_esi_eax => try writer.writeAll("\tmovl %edi, %eax\n\tcmpl %esi, %edi\n\tcmovgl %esi, %eax\n"),
            .shift_mix_i32_edi_esi_eax => try writer.writeAll("\tmovl %esi, %ecx\n\tandl $31, %ecx\n\tmovl %edi, %eax\n\tshll %cl, %eax\n\tmovl %edi, %edx\n\tshrl %cl, %edx\n\txorl %edx, %eax\n"),
            .replace_low_i8_dil_sil_al => try writer.writeAll("\tmovl %edi, %eax\n\tandl $-8, %eax\n\tmovl %esi, %edx\n\tandl $7, %edx\n\torl %edx, %eax\n"),
            .read_flag_i8_dil_al => try writer.writeAll("\txorl %eax, %eax\n\ttestb %dil, %dil\n\tsets %al\n"),
            .store_imm8_abs => |store| try writer.print("\tmovb ${}, {x}\n", .{ store.value, store.address }),
            .cmp_ecx_arg32 => |reg| try writer.print("\tcmpl %ecx, {s}\n", .{reg.name32()}),
            .cmp_rcx_arg64 => |reg| try writer.print("\tcmpq %rcx, {s}\n", .{reg.name64()}),
            .cmp_ecx_imm32 => |value| try writer.print("\tcmpl ${}, %ecx\n", .{value}),
            .cmp_eax_imm32 => |value| try writer.print("\tcmpl ${}, %eax\n", .{value}),
            .cmp_arg64_imm64 => |cmp| try writer.print("\tmovabsq ${}, %rax\n\tcmpq %rax, {s}\n", .{ cmp.imm, cmp.reg.name64() }),
            .cmp_arg16_imm16 => |cmp| try writer.print("\tcmpw ${}, {s}\n", .{ cmp.imm, cmp.reg.name16() }),
            .cmp_rdi_imm64 => |value| try writer.print("\tmovabsq ${}, %rax\n\tcmpq %rax, %rdi\n", .{value}),
            .cmp_rdx_rdi => try writer.writeAll("\tcmpq %rdi, %rdx\n"),
            .cmp_rax_rdx => try writer.writeAll("\tcmpq %rdx, %rax\n"),
            .test_eax_eax => try writer.writeAll("\ttestl %eax, %eax\n"),
            .test_rax_rax => try writer.writeAll("\ttestq %rax, %rax\n"),
            .test_rdx_rdx => try writer.writeAll("\ttestq %rdx, %rdx\n"),
            .mulsd_xmm1_xmm0 => try writer.writeAll("\tmulsd %xmm1, %xmm0\n"),
            .mulss_xmm1_xmm0 => try writer.writeAll("\tmulss %xmm1, %xmm0\n"),
            .addss_xmm1_xmm0 => try writer.writeAll("\taddss %xmm1, %xmm0\n"),
            .subss_xmm1_xmm0 => try writer.writeAll("\tsubss %xmm1, %xmm0\n"),
            .divsd_xmm1_xmm0 => try writer.writeAll("\tdivsd %xmm1, %xmm0\n"),
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
            .add_rsp_imm8 => |value| try writer.print("\taddq ${}, %rsp\n", .{value}),
            .add_rsp_imm32 => |value| try writer.print("\taddq ${}, %rsp\n", .{value}),
            .spill_arg_rsp => |spill| try writer.print("\tmovl {s}, {s}\n", .{ spill.reg.name32(), frameAddress(spill.frame_index) }),
            .reload_arg_rsp => |reload| try writer.print("\tmovl {s}, {s}\n", .{ frameAddress(reload.frame_index), reload.reg.name32() }),
            .spill_xmm32_rsp => |spill| try writer.print("\tmovss {s}, {s}\n", .{ spill.reg.name(), frameAddress(spill.frame_index) }),
            .reload_xmm32_rsp => |reload| try writer.print("\tmovss {s}, {s}\n", .{ frameAddress(reload.frame_index), reload.reg.name() }),
            .spill_xmm64_rsp => |spill| try writer.print("\tmovsd {s}, {s}\n", .{ spill.reg.name(), frameAddress(spill.frame_index) }),
            .reload_xmm64_rsp => |reload| try writer.print("\tmovsd {s}, {s}\n", .{ frameAddress(reload.frame_index), reload.reg.name() }),
            .spill_rdi_rsi_rsp24 => try writer.writeAll("\tmovq %rdi, 8(%rsp)\n\tmovq %rsi, 16(%rsp)\n"),
            .reload_rdi_rsp24 => try writer.writeAll("\tmovq 8(%rsp), %rdi\n"),
            .reload_rsi_rsp24 => try writer.writeAll("\tmovq 16(%rsp), %rsi\n"),
            .reload_rsp_eax => try writer.writeAll("\tmovl (%rsp), %eax\n"),
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
            .load_stack_disp8_arg32 => |load| try writer.print("\tmovl {}(%rsp), {s}\n", .{ load.disp, load.reg.name32() }),
            .load_stack_disp8_arg64 => |load| try writer.print("\tmovq {}(%rsp), {s}\n", .{ load.disp, load.reg.name64() }),
            .load_stack_disp32_arg32 => |load| try writer.print("\tmovl {}(%rsp), {s}\n", .{ load.disp, load.reg.name32() }),
            .load_stack_disp32_arg64 => |load| try writer.print("\tmovq {}(%rsp), {s}\n", .{ load.disp, load.reg.name64() }),
            .load_rax_ptr_disp8_rax => |offset| try writer.print("\tmovq {}(%rax), %rax\n", .{offset}),
            .load_rax_ptr_rdx => try writer.writeAll("\tmovq (%rax), %rdx\n"),
            .load_rax_ptr_eax => try writer.writeAll("\tmovl (%rax), %eax\n"),
            .load_arg_ptr_eax => |reg| try writer.print("\tmovl ({s}), %eax\n", .{reg.name64()}),
            .load_arg_ptr_disp8_rax => |load| try writer.print("\tmovq {}({s}), %rax\n", .{ load.offset, load.reg.name64() }),
            .load_arg_ptr_disp8_u8_eax => |load| try writer.print("\tmovzbl {}({s}), %eax\n", .{ load.offset, load.reg.name64() }),
            .add_arg_ptr_disp4_eax => |reg| try writer.print("\taddl 4({s}), %eax\n", .{reg.name64()}),
            .store_eax_arg_ptr => |reg| try writer.print("\tmovl %eax, ({s})\n", .{reg.name64()}),
            .store_imm64_arg_ptr_disp8 => |store| try writer.print("\tmovq ${}, {}({s})\n", .{ store.imm, store.offset, store.reg.name64() }),
            .store_arg64_arg_ptr_disp8 => |store| try writer.print("\tmovq {s}, {}({s})\n", .{ store.src_reg.name64(), store.offset, store.ptr_reg.name64() }),
            .store_arg64_arg_ptr_disp32 => |store| try writer.print("\tmovq {s}, {}({s})\n", .{ store.src_reg.name64(), store.offset, store.ptr_reg.name64() }),
            .store_rax_arg_ptr_disp8 => |store| try writer.print("\tmovq %rax, {}({s})\n", .{ store.offset, store.reg.name64() }),
            .store_rax_arg_ptr_disp32 => |store| try writer.print("\tmovq %rax, {}({s})\n", .{ store.offset, store.reg.name64() }),
            .store_eax_arg_ptr_disp8 => |store| try writer.print("\tmovl %eax, {}({s})\n", .{ store.offset, store.reg.name64() }),
            .store_eax_arg_ptr_disp32 => |store| try writer.print("\tmovl %eax, {}({s})\n", .{ store.offset, store.reg.name64() }),
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
            .ud2 => try writer.writeAll("\tud2\n"),
            .je => |label| try writer.print("\tje .L{s}_{s}\n", .{ function.name, label }),
            .jne => |label| try writer.print("\tjne .L{s}_{s}\n", .{ function.name, label }),
            .jo => |label| try writer.print("\tjo .L{s}_{s}\n", .{ function.name, label }),
            .jp => |label| try writer.print("\tjp .L{s}_{s}\n", .{ function.name, label }),
            .js => |label| try writer.print("\tjs .L{s}_{s}\n", .{ function.name, label }),
            .jae => |label| try writer.print("\tjae .L{s}_{s}\n", .{ function.name, label }),
            .jle => |label| try writer.print("\tjle .L{s}_{s}\n", .{ function.name, label }),
            .jmp => |label| try writer.print("\tjmp .L{s}_{s}\n", .{ function.name, label }),
            .ret => try writer.writeAll("\tretq\n"),
        }
    }
}

fn frameAddress(frame_index: x86_64.FrameIndex) []const u8 {
    return switch (frame_index) {
        .slot0 => "(%rsp)",
        .slot1 => "4(%rsp)",
        .slot2 => "8(%rsp)",
        .slot3 => "12(%rsp)",
        .slot4 => "16(%rsp)",
        .slot5 => "20(%rsp)",
        .slot6 => "24(%rsp)",
        .slot7 => "28(%rsp)",
        .slot8 => "32(%rsp)",
        .slot9 => "36(%rsp)",
        .slot10 => "40(%rsp)",
    };
}
