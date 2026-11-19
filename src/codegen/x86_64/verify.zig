const std = @import("std");
const machine_ir = @import("machine.zig");
const sysv_abi = @import("sysv_abi.zig");

const MachineFunction = machine_ir.MachineFunction;

pub fn verifyFunction(function: MachineFunction) !void {
    try @import("function_alignment.zig").validate(function.symbol_alignment);
    const tail_depths = try @import("verify_tail_calls.zig").prove(function);
    defer if (tail_depths) |depths| std.heap.page_allocator.free(depths);
    try @import("verify_x87.zig").verify(function);
    for (function.instructions.items) |instruction| switch (instruction) {
        .indirect_jump => |jump| {
            if (jump.targets.len == 0) return error.InvalidBranchTarget;
            for (jump.targets) |target_name| if (!hasLabel(function, target_name)) return error.InvalidBranchTarget;
        },
        .linux_syscall => |count| if (count > 6) return error.UnsupportedCodegenInstruction,
        .read_thread_pointer_rax, .linux_clone_trampoline, .register_snapshot_rdi, .cpuid_packed, .xgetbv_eax, .valgrind_client_request => {},
        .je, .jne, .jo, .jc, .jp, .js, .jae, .jle, .jmp => |target_name| if (!hasLabel(function, target_name)) return error.InvalidBranchTarget,
        .push_byval_tail_arg_ptr => |copy| try validateByvalTail(copy.offset, copy.len),
        .push_byval_tail_stack_ptr => |copy| try validateByvalTail(copy.offset, copy.len),
        .label,
        .mov_imm_eax,
        .mov_imm_rax,
        .mov_imm_rdi,
        .mov_imm_rdx,
        .mov_imm_rsi,
        .mov_imm_rcx,
        .mov_imm_r8,
        .mov_imm_r9,
        .mov_rax_rdi,
        .mov_rax_rsi,
        .mov_arg_rax,
        .movq_xmm_rax,
        .movq_rax_xmm,
        .movd_xmm_eax,
        .movd_eax_xmm,
        .mov_arg_eax,
        .mov_eax_to_arg,
        .mov_rax_to_arg,
        .mov_arg_arg,
        .mov_arg64_arg,
        .mov_rsp_arg64,
        .movsxd_arg32_arg64,
        .binary_arg_eax,
        .binary_arg_rax,
        .sbb_arg64_rax,
        .adc_rax_imm0,
        .imul_eax_arg32,
        .imul_arg64_arg64,
        .imul_arg64_rax,
        .imul_rax_arg64,
        .imul_rax_rsp,
        .mul_rax_arg64_full,
        .imul_rax_arg64_full,
        .xor_edx_edx,
        .div_arg32,
        .div_arg64,
        .idiv_arg64,
        .add_arg64_rax,
        .add_arg64_imm32,
        .add_arg_high32_eax,
        .add_stack_disp8_eax,
        .add_stack_disp8_rax,
        .add_stack_disp32_eax,
        .add_stack_disp32_rax,
        .add_eax_imm32,
        .shl_eax_imm5,
        .shr_eax_imm5,
        .sar_eax_imm5,
        .shr_arg_imm5,
        .shr_arg64_imm6,
        .sar_arg64_imm6,
        .shl_eax_cl,
        .shr_eax_cl,
        .sar_eax_cl,
        .shl_rax_cl,
        .shr_rax_cl,
        .sar_rax_cl,
        .fshl_eax_arg32_imm5,
        .or_eax_imm32,
        .imul_eax_imm32,
        .and_eax_imm32,
        .abs_i32_edi_eax,
        .abs_i64_rdi_rax,
        .wide_int_to_fp_rdi_rsi_xmm0,
        .clz_i128_rdi_rsi_eax,
        .clz_i64_rdi_eax,
        .clz_i32_edi_eax,
        .ctz_i32_edi_eax,
        .popcount_i32_edi_eax,
        .popcount_rax,
        .bit_reverse_i32_edi_eax,
        .bit_reverse_rax,
        .ushl_sat_i32_edi_imm_eax,
        .bswap_eax,
        .bswap_rax,
        .rol_ax_imm8,
        .shr_rax_imm6,
        .shl_rax_imm6,
        .shl_rdx_imm6,
        .or_rdx_rax,
        .neg_rax,
        .neg_i128_rdi_rsi_rdx_rax,
        .abs_limb64_rdi_rsi_dx_rcx_rax,
        .mulo_limb64_rdi_rsi_rdx_cl_r8w_al,
        .byteswap_limb64_rdi_rsi_dl_cx,
        .shr_limb64_rdi_rsi_dx_cl_r8w,
        .shlo_limb64_rdi_rsi_dx_cl_r8w_al,
        .not_limb64_rdi_rsi_dl_cx,
        .bitwise_limb64_rdi_rsi_rdx_cx,
        .cmp_limb64_rdi_rsi_dl_cx_ax,
        .overflow_limb64_rdi_rsi_rdx_cl_r8w_al,
        .bitreverse_limb64_rdi_rsi_dl_cx,
        .popcount_limb64_rdi_si_ax,
        .ctz_limb64_rdi_si_ax,
        .clz_limb64_rdi_si_ax,
        .udivei4_before_intbytesize,
        .udivei4_between_intbytesize_and_memset,
        .udivei4_after_memset,
        .umodei5_before_intbytesize,
        .umodei5_between_intbytesize_and_memset,
        .umodei5_after_memset_before_memcpy,
        .umodei5_after_memcpy,
        .ctz_i128_rdi_rsi_eax,
        .ctz_i64_rdi_eax,
        .ffs_i128_rdi_rsi_eax,
        .ffs_i64_rdi_eax,
        .ffs_i32_edi_eax,
        .shl_rcx_imm6,
        .shl_r8_imm6,
        .or_rcx_rax,
        .or_rcx_rdx,
        .add_rax_imm8,
        .add_rcx_imm32,
        .add_r8_rcx,
        .sub_r8_rcx,
        .add_ecx_eax,
        .xor_ecx_ecx,
        .xor_ebp_ebp,
        .add_rdi_rcx4_ptr_eax,
        .load_rdi_rcx4_ptr_r8d,
        .store_eax_rdi_rcx4_ptr,
        .load_rdi_ptr_u8_eax,
        .load_rdi_ptr_u16_eax,
        .load_rdi_ptr_eax,
        .load_rdi_ptr_rax,
        .atomic_fetch_umin_i8_rdi_sil_eax,
        .atomic_fetch_umin_i16_rdi_si_eax,
        .atomic_fetch_umin_i32_rdi_esi_eax,
        .atomic_fetch_umin_i64_rdi_rsi_rax,
        .atomic_fetch_umax_i8_rdi_sil_eax,
        .atomic_fetch_umax_i16_rdi_si_eax,
        .atomic_fetch_umax_i32_rdi_esi_eax,
        .atomic_fetch_umax_i64_rdi_rsi_rax,
        .atomic_fetch_nand_i8_rdi_sil_eax,
        .atomic_fetch_nand_i16_rdi_si_eax,
        .atomic_fetch_nand_i32_rdi_esi_eax,
        .atomic_fetch_nand_i64_rdi_rsi_rax,
        .atomic_fetch_xor_i8_rdi_sil_eax,
        .atomic_fetch_xor_i16_rdi_si_eax,
        .atomic_fetch_xor_i32_rdi_esi_eax,
        .atomic_fetch_xor_i64_rdi_rsi_rax,
        .atomic_fetch_or_i8_rdi_sil_eax,
        .atomic_fetch_or_i16_rdi_si_eax,
        .atomic_fetch_or_i32_rdi_esi_eax,
        .atomic_fetch_or_i64_rdi_rsi_rax,
        .atomic_fetch_and_i8_rdi_sil_eax,
        .atomic_fetch_and_i16_rdi_si_eax,
        .atomic_fetch_and_i32_rdi_esi_eax,
        .atomic_fetch_and_i64_rdi_rsi_rax,
        .atomic_fetch_sub_i8_rdi_sil_eax,
        .atomic_fetch_sub_i16_rdi_si_eax,
        .atomic_fetch_sub_i32_rdi_esi_eax,
        .atomic_fetch_sub_i64_rdi_rsi_rax,
        .atomic_fetch_add_i8_rdi_sil_eax,
        .atomic_fetch_add_i16_rdi_si_eax,
        .atomic_fetch_add_i32_rdi_esi_eax,
        .atomic_fetch_add_i64_rdi_rsi_rax,
        .load_rcx_ptr_u8_eax,
        .load_rcx_ptr_u16_eax,
        .load_rcx_ptr_eax,
        .load_rcx_ptr_rax,
        .store_al_rcx_ptr,
        .store_ax_rcx_ptr,
        .store_eax_rcx_ptr,
        .store_rax_rcx_ptr,
        .cmp_r8d_arg32,
        .add_r8d_eax,
        .inc_rcx,
        .movzx_dil_edi,
        .and_edi_imm8,
        .load_rax_rdi_u8_eax,
        .bcmp_rdi_rsi_rdx_eax,
        .memcmp_rdi_rsi_rdx_eax,
        .memcpy_rdi_rsi_rdx_rax,
        .spinlocked_memcpy_rsi_to_rdx_len_edi,
        .spinlocked_var_cmpxchg_edi_rsi_rdx_rcx_eax,
        .spinlocked_var_xchg_edi_rsi_rdx_rcx,
        .spinlocked_var_store_edi_rsi_rdx,
        .cmpxchg_ptr_expected_desired_i8_eax,
        .cmpxchg_ptr_expected_desired_i16_eax,
        .cmpxchg_ptr_expected_desired_i32_eax,
        .cmpxchg_ptr_expected_desired_i64_eax,
        .spinlocked_cmpxchg_i128_rdi_rsi_rdx_rcx_eax,
        .xchg_ptr_value_i8_eax,
        .xchg_ptr_value_i16_eax,
        .xchg_ptr_value_i32_eax,
        .xchg_ptr_value_i64_rax,
        .atomic_xchg_rdi_disp8_rax,
        .spinlocked_xchg_i128_rdi_rsi_rdx_rax,
        .spinlocked_store_i128_rdi_rsi_rdx,
        .spinlocked_load_i128_rdi_rax_rdx,
        .spinlocked_fetch_umin_i128_rdi_rsi_rdx_rax_rdx,
        .spinlocked_fetch_umax_i128_rdi_rsi_rdx_rax_rdx,
        .spinlocked_fetch_nand_i128_rdi_rsi_rdx_rax_rdx,
        .spinlocked_fetch_xor_i128_rdi_rsi_rdx_rax_rdx,
        .spinlocked_fetch_or_i128_rdi_rsi_rdx_rax_rdx,
        .spinlocked_fetch_and_i128_rdi_rsi_rdx_rax_rdx,
        .spinlocked_fetch_sub_i128_rdi_rsi_rdx_rax_rdx,
        .spinlocked_fetch_add_i128_rdi_rsi_rdx_rax_rdx,
        .memmove_rdi_rsi_rdx_rax,
        .stack_probe_rax_rcx_rsp,
        .guarded_memset_rdi_sil_rdx_rcx_rax,
        .guarded_memcpy_rdi_rsi_rdx_rcx_rax,
        .guarded_strncat_rdi_rsi_rdx_rcx_rax,
        .guarded_strcat_rdi_rsi_rdx_rax,
        .guarded_strncpy_rdi_rsi_rdx_rcx_rax,
        .guarded_strcpy_rdi_rsi_rdx_rax,
        .memset_rdi_sil_rdx_rax,
        .strlen_rdi_rax,
        .strnlen_rdi_rsi_rax,
        .atomic_try_lock_rdi_al,
        .smin_i32_edi_esi_eax,
        .umin_i32_edi_esi_eax,
        .smax_i32_edi_esi_eax,
        .umax_i32_edi_esi_eax,
        .shift_mix_i32_edi_esi_eax,
        .replace_low_i8_dil_sil_al,
        .read_flag_i8_dil_al,
        .ult_i8_dil_imm8_al,
        .cmp_ult_u32_edi_esi_al,
        .ascii_range_u8_dil_imm8_imm8_al,
        .range_u32_edi_imm32_imm32_al,
        .ascii_alphabetic_dil_al,
        .ascii_alphanumeric_dil_al,
        .ascii_whitespace_dil_al,
        .ascii_control_dil_al,
        .grow_capacity_u64_rdi_imm32_rax,
        .xor_eax_imm32,
        .store_imm8_abs,
        .cmp_ecx_arg32,
        .cmp_rcx_arg64,
        .cmp_arg64_imm64,
        .cmp_arg16_imm16,
        .cmp_rdi_imm64,
        .cmp_rdx_rcx,
        .cmp_rdx_rdi,
        .cmp_rax_rdx,
        .setb_eax,
        .seta_eax,
        .sete_eax,
        .setg_eax,
        .setl_eax,
        .setne_eax,
        .setbe_eax,
        .test_eax_eax,
        .test_rax_rax,
        .test_rdx_rdx,
        .mulsd_xmm1_xmm0,
        .mulss_xmm1_xmm0,
        .mulsd_xmm,
        .mulss_xmm,
        .subsd_xmm,
        .subss_xmm,
        .divsd_xmm,
        .divss_xmm,
        .addsd_xmm,
        .addss_xmm,
        .addsd_xmm1_xmm0,
        .addss_xmm1_xmm0,
        .subss_xmm1_xmm0,
        .divsd_xmm1_xmm0,
        .xorps_xmm1_xmm0,
        .movapd_xmm1_xmm0,
        .movapd_xmm,
        .addpd_xmm,
        .subpd_xmm,
        .mulpd_xmm,
        .addps_xmm,
        .subps_xmm,
        .mulps_xmm,
        .andps_xmm,
        .pxor_xmm,
        .pcmpgtd_xmm,
        .cmpeqps_xmm,
        .cmpeqpd_xmm,
        .movmskps_xmm_eax,
        .movmskpd_xmm_eax,
        .movsd_xmm,
        .movss_xmm,
        .unpcklpd_xmm,
        .unpckhpd_xmm,
        .shufpd_xmm,
        .unpcklps_xmm,
        .shufps_high_f32_to_low,
        .shufps_xmm,
        .cvtsi2ss_edi_xmm0,
        .cvtsi2sd_edi_xmm0,
        .cvtsi2ss_rdi_xmm0,
        .cvtsi2sd_rdi_xmm0,
        .cvttss2si_xmm0_eax,
        .cvttsd2si_xmm0_eax,
        .cvtsd2ss_xmm0_xmm0,
        .cvtss2sd_xmm0_xmm0,
        .sqrtss_xmm0,
        .sqrtsd_xmm0,
        .cvtsd2ss_xmm,
        .cvtss2sd_xmm,
        .mov_edi_edi,
        .mov_imm64_xmm0,
        .mov_imm64_xmm1,
        .mov_imm32_xmm0,
        .mov_imm32_xmm1,
        .mov_imm64_xmm,
        .mov_imm32_xmm,
        .ucomisd,
        .ucomiss,
        .set_fcmp_eax,
        .ucomisd_xmm1_xmm0,
        .ucomiss_xmm1_xmm0,
        .ucomiss_xmm0_xmm1,
        .oltss_xmm0_xmm1_al,
        .fneg_x86_fp80_stack8_st0,
        .i80_rax_rdx_st0,
        .x87_st0_i80_rax_rdx,
        .x87_binary_pop,
        .x87_sqrt_st0,
        .fneg_fp128_xmm0,
        .sub_rsp_8,
        .add_rsp_8,
        .push_imm32,
        .push_stack_disp8,
        .push_stack_disp32,
        .push_arg,
        .pop_arg,
        .push_rax,
        .push_xmm64,
        .sub_rsp_24,
        .add_rsp_24,
        .sub_rsp_40,
        .add_rsp_40,
        .sub_rsp_56,
        .add_rsp_56,
        .sub_rsp_imm8,
        .sub_rsp_imm32,
        .add_rsp_imm8,
        .add_rsp_imm32,
        .spill_arg_rsp,
        .spill_arg64_rsp,
        .reload_arg_rsp,
        .reload_arg64_rsp,
        .spill_xmm32_rsp,
        .reload_xmm32_rsp,
        .spill_xmm64_rsp,
        .reload_xmm64_rsp,
        .spill_xmm128_rsp,
        .reload_xmm128_rsp,
        .spill_xmm128ps_rsp,
        .reload_xmm128ps_rsp,
        .spill_rdi_rsi_rsp24,
        .reload_rdi_rsp24,
        .reload_rsi_rsp24,
        .spill_eax_rsp,
        .reload_rsp_eax,
        .spill_rax_rsp,
        .reload_rsp_rax,
        .load_stack_disp8_eax,
        .load_stack_disp32_eax,
        .load_stack_rcx4_disp8_eax,
        .load_stack_rcx4_disp32_eax,
        .load_stack_disp8_rax,
        .load_stack_disp32_rax,
        .load_stack_disp8_u8_eax,
        .load_stack_disp32_u8_eax,
        .load_stack_disp8_u16_eax,
        .load_stack_disp32_u16_eax,
        .load_stack_disp8_xmm0,
        .load_stack_disp32_xmm0,
        .load_stack_disp8_xmm0_f32,
        .load_stack_disp32_xmm0_f32,
        .load_stack_disp8_xmm,
        .load_stack_disp32_xmm,
        .load_stack_disp8_xmm_f32,
        .load_stack_disp32_xmm_f32,
        .load_stack_disp8_arg32,
        .load_stack_disp8_arg64,
        .load_stack_disp32_arg32,
        .load_stack_disp32_arg64,
        .load_rax_ptr_disp8_rax,
        .load_rax_ptr_disp32_rax,
        .load_rax_ptr_disp8_u8_eax,
        .load_rax_ptr_disp8_u16_eax,
        .load_rax_ptr_disp8_eax,
        .load_rax_ptr_rdx,
        .load_rax_ptr_eax,
        .load_arg_ptr_eax,
        .load_arg_ptr_disp8_rax,
        .load_arg_ptr_disp32_rax,
        .load_arg_ptr_disp8_eax,
        .load_arg_ptr_disp8_u8_eax,
        .load_arg_ptr_disp8_u16_eax,
        .load_arg_ptr_disp8_u16_arg,
        .load_arg_ptr_disp8_xmm,
        .add_arg_ptr_disp4_eax,
        .inc_arg_ptr_disp8,
        .store_eax_arg_ptr,
        .store_imm64_arg_ptr_disp8,
        .store_arg64_arg_ptr_disp8,
        .store_arg64_arg_ptr_disp32,
        .store_rax_arg_ptr_disp8,
        .store_rax_arg_ptr_disp32,
        .store_eax_arg_ptr_disp8,
        .store_eax_arg_ptr_disp32,
        .store_eax_stack_disp8,
        .store_eax_stack_disp32,
        .store_al_stack_disp8,
        .store_al_stack_disp32,
        .store_eax_stack_rcx4_disp8,
        .store_eax_stack_rcx4_disp32,
        .store_al_arg_ptr_disp8,
        .store_al_arg_ptr_disp32,
        .store_ax_arg_ptr_disp8,
        .store_ax_arg_ptr_disp32,
        .store_xmm0_arg_ptr_disp8,
        .store_xmm0_arg_ptr_disp32,
        .store_xmm0_f32_arg_ptr_disp8,
        .store_xmm0_f32_arg_ptr_disp32,
        .store_imm8_arg_ptr_disp8,
        .load_f128_arg_ptr_xmm0,
        .load_f128_const_xmm0,
        .load_f128_const_xmm1,
        .store_f128_xmm0_arg_ptr,
        .volatile_roundtrip_rdi_esi_eax,
        .load_global_i32_eax,
        .load_global_ptr_rax,
        .lea_global_rax,
        .lea_global_offset_rax,
        .lea_global_rdi,
        .lea_global_rsi,
        .lea_global_rdx,
        .lea_global_arg64,
        .store_eax_global_i32,
        .load_tls_i32_eax,
        .add_tls_i32_eax,
        .store_eax_tls_i32,
        .atomic_xadd_global_eax,
        .mov_rsp_rdi,
        .and_rsp_neg16,
        .direct_call,
        .tls_address_rax,
        .direct_jump,
        .tail_jump_rax,
        .indirect_call_rax,
        .noreturn_direct_call,
        .cmp_arg8_imm8,
        .cmp_ecx_imm32,
        .cmp_eax_imm32,
        .test_arg8,
        .test_arg32,
        .test_arg64,
        .base64_raw_args_to_decode4_regs,
        .base64_decode4_from_table_rax,
        .syscall,
        .ud2,
        .ret,
        => {},
    };

    const returns_scalar_sse = sysv_abi.isScalarSseAbiType(function.ret_ty);
    const aggregate_return_kind = sysv_abi.sseAggregateReturnKind(function.ret_ty);
    var eax_defined = function.ret_ty == .void or returns_scalar_sse or
        sysv_abi.aggregateReturnHasNoGpr(function.ret_ty);
    var eax_defined_before_label = eax_defined;
    var xmm0_defined = returns_scalar_sse;
    var xmm0_defined_before_label = xmm0_defined;
    var xmm_defined_bits = function.entry_xmm_defined_bits;
    var xmm_defined_bits_before_label = xmm_defined_bits;
    var saw_terminator = false;
    var preserve_eax_at_next_label = false;
    var rsp_mod16: u4 = 8;
    const return_join = finalReturnJoin(function);
    var join_definitions: ReturnDefinitions = .{};
    for (function.instructions.items, 0..) |instruction, instruction_index| {
        if (tail_depths) |depths| if (depths[instruction_index]) |depth| {
            rsp_mod16 = @intCast((24 - depth % 16) % 16);
        };
        if (return_join) |join| {
            const target: ?[]const u8 = switch (instruction) {
                .je, .jne, .jo, .jc, .jp, .js, .jae, .jle, .jmp => |name| name,
                else => null,
            };
            if (target) |name| if (std.mem.eql(u8, name, function.instructions.items[join].label)) {
                join_definitions.include(eax_defined, xmm0_defined, xmm_defined_bits);
            };
        }
        recordXmmDefinitions(instruction, &xmm_defined_bits);
        // Generic register loads/transfers also restore scalar XMM0 after a
        // call has invalidated it; they do not all use an XMM0-specific opcode.
        if (returns_scalar_sse and xmm_defined_bits[0] >= (if (function.ret_ty == .half) @as(u16, 16) else if (function.ret_ty == .float) @as(u16, 32) else @as(u16, 64))) xmm0_defined = true;
        switch (instruction) {
            .i80_rax_rdx_st0 => {},
            .x87_st0_i80_rax_rdx => eax_defined = true,
            .x87_binary_pop, .x87_sqrt_st0 => {},
            .read_thread_pointer_rax, .linux_clone_trampoline, .linux_syscall, .register_snapshot_rdi, .cpuid_packed, .xgetbv_eax => eax_defined = true,
            .valgrind_client_request => {},
            .indirect_jump => saw_terminator = true,
            .label => |label| {
                eax_defined_before_label = eax_defined;
                xmm0_defined_before_label = xmm0_defined;
                xmm_defined_bits_before_label = xmm_defined_bits;
                if (return_join == instruction_index and join_definitions.incoming != 0) {
                    if (instruction_index == 0 or fallsThrough(function.instructions.items[instruction_index - 1])) {
                        join_definitions.include(eax_defined, xmm0_defined, xmm_defined_bits);
                    }
                    eax_defined = join_definitions.eax;
                    xmm0_defined = join_definitions.xmm0;
                    xmm_defined_bits = join_definitions.xmm_bits;
                    preserve_eax_at_next_label = false;
                } else if (preserve_eax_at_next_label) {
                    preserve_eax_at_next_label = false;
                } else if (!std.mem.endsWith(u8, label, "generic_cfg_select_end") and
                    !std.mem.endsWith(u8, label, "generic_cfg_pointer_select_end") and
                    !std.mem.endsWith(u8, label, "conditional_slice_sum_skip"))
                {
                    eax_defined = function.ret_ty == .void or sysv_abi.aggregateReturnHasNoGpr(function.ret_ty);
                    xmm0_defined = returns_scalar_sse;
                    xmm_defined_bits = function.entry_xmm_defined_bits;
                }
            },
            .shl_eax_cl => eax_defined = true,
            .shl_rax_cl => eax_defined = true,
            .shr_rax_cl => eax_defined = true,
            .sar_rax_cl => eax_defined = true,
            .adc_rax_imm0 => eax_defined = true,
            .movd_xmm_eax => eax_defined = true,
            .movq_rax_xmm, .movd_eax_xmm => {},
            .mulsd_xmm, .mulss_xmm, .subsd_xmm, .subss_xmm, .divsd_xmm, .divss_xmm, .addsd_xmm, .addss_xmm, .cvtsd2ss_xmm, .cvtss2sd_xmm, .addpd_xmm, .subpd_xmm, .mulpd_xmm, .addps_xmm, .subps_xmm, .mulps_xmm, .andps_xmm, .pxor_xmm, .pcmpgtd_xmm, .cmpeqps_xmm, .cmpeqpd_xmm, .movsd_xmm, .movss_xmm, .unpcklpd_xmm, .unpckhpd_xmm, .shufpd_xmm, .shufps_xmm => {},
            .movmskps_xmm_eax, .movmskpd_xmm_eax => eax_defined = true,
            .bit_reverse_rax, .popcount_rax => eax_defined = true,
            .wide_int_to_fp_rdi_rsi_xmm0 => |conversion| {
                if (conversion.to_bits != 32 and conversion.to_bits != 64) return error.InvalidMachineInstruction;
                eax_defined = true;
                xmm0_defined = true;
            },
            .mov_imm_eax, .mov_imm_rax, .mov_arg_rax, .movq_xmm_rax, .mov_arg_eax, .binary_arg_eax, .binary_arg_rax, .sbb_arg64_rax, .add_arg64_rax, .add_arg_high32_eax, .add_stack_disp8_eax, .add_stack_disp8_rax, .add_stack_disp32_eax, .add_stack_disp32_rax, .add_eax_imm32, .shl_eax_imm5, .shr_eax_imm5, .sar_eax_imm5, .shr_eax_cl, .sar_eax_cl, .fshl_eax_arg32_imm5, .or_eax_imm32, .imul_eax_arg32, .imul_eax_imm32, .imul_rax_arg64, .imul_rax_rsp, .mul_rax_arg64_full, .imul_rax_arg64_full, .and_eax_imm32, .abs_i32_edi_eax, .abs_i64_rdi_rax, .clz_i128_rdi_rsi_eax, .clz_i64_rdi_eax, .clz_i32_edi_eax, .ctz_i32_edi_eax, .popcount_i32_edi_eax, .bit_reverse_i32_edi_eax, .ushl_sat_i32_edi_imm_eax, .bswap_eax, .bswap_rax, .rol_ax_imm8, .shr_rax_imm6, .shl_rax_imm6, .or_rdx_rax, .neg_rax, .neg_i128_rdi_rsi_rdx_rax, .abs_limb64_rdi_rsi_dx_rcx_rax, .ctz_i128_rdi_rsi_eax, .ctz_i64_rdi_eax, .ffs_i128_rdi_rsi_eax, .ffs_i64_rdi_eax, .ffs_i32_edi_eax, .add_rax_imm8, .add_ecx_eax, .add_rdi_rcx4_ptr_eax, .add_r8d_eax, .load_rax_rdi_u8_eax, .bcmp_rdi_rsi_rdx_eax, .memcmp_rdi_rsi_rdx_eax, .memcpy_rdi_rsi_rdx_rax, .spinlocked_var_cmpxchg_edi_rsi_rdx_rcx_eax, .cmpxchg_ptr_expected_desired_i8_eax, .cmpxchg_ptr_expected_desired_i16_eax, .cmpxchg_ptr_expected_desired_i32_eax, .cmpxchg_ptr_expected_desired_i64_eax, .spinlocked_cmpxchg_i128_rdi_rsi_rdx_rcx_eax, .xchg_ptr_value_i8_eax, .xchg_ptr_value_i16_eax, .xchg_ptr_value_i32_eax, .xchg_ptr_value_i64_rax, .atomic_xchg_rdi_disp8_rax, .spinlocked_xchg_i128_rdi_rsi_rdx_rax, .spinlocked_load_i128_rdi_rax_rdx, .spinlocked_fetch_umin_i128_rdi_rsi_rdx_rax_rdx, .spinlocked_fetch_umax_i128_rdi_rsi_rdx_rax_rdx, .spinlocked_fetch_nand_i128_rdi_rsi_rdx_rax_rdx, .spinlocked_fetch_xor_i128_rdi_rsi_rdx_rax_rdx, .spinlocked_fetch_or_i128_rdi_rsi_rdx_rax_rdx, .spinlocked_fetch_and_i128_rdi_rsi_rdx_rax_rdx, .spinlocked_fetch_sub_i128_rdi_rsi_rdx_rax_rdx, .spinlocked_fetch_add_i128_rdi_rsi_rdx_rax_rdx, .memmove_rdi_rsi_rdx_rax, .guarded_memset_rdi_sil_rdx_rcx_rax, .guarded_memcpy_rdi_rsi_rdx_rcx_rax, .guarded_strncat_rdi_rsi_rdx_rcx_rax, .guarded_strcat_rdi_rsi_rdx_rax, .guarded_strncpy_rdi_rsi_rdx_rcx_rax, .guarded_strcpy_rdi_rsi_rdx_rax, .memset_rdi_sil_rdx_rax, .strlen_rdi_rax, .strnlen_rdi_rsi_rax, .atomic_try_lock_rdi_al, .load_rdi_ptr_u8_eax, .load_rdi_ptr_u16_eax, .load_rdi_ptr_eax, .load_rdi_ptr_rax, .atomic_fetch_umin_i8_rdi_sil_eax, .atomic_fetch_umin_i16_rdi_si_eax, .atomic_fetch_umin_i32_rdi_esi_eax, .atomic_fetch_umin_i64_rdi_rsi_rax, .atomic_fetch_umax_i8_rdi_sil_eax, .atomic_fetch_umax_i16_rdi_si_eax, .atomic_fetch_umax_i32_rdi_esi_eax, .atomic_fetch_umax_i64_rdi_rsi_rax, .atomic_fetch_nand_i8_rdi_sil_eax, .atomic_fetch_nand_i16_rdi_si_eax, .atomic_fetch_nand_i32_rdi_esi_eax, .atomic_fetch_nand_i64_rdi_rsi_rax, .atomic_fetch_xor_i8_rdi_sil_eax, .atomic_fetch_xor_i16_rdi_si_eax, .atomic_fetch_xor_i32_rdi_esi_eax, .atomic_fetch_xor_i64_rdi_rsi_rax, .atomic_fetch_or_i8_rdi_sil_eax, .atomic_fetch_or_i16_rdi_si_eax, .atomic_fetch_or_i32_rdi_esi_eax, .atomic_fetch_or_i64_rdi_rsi_rax, .atomic_fetch_and_i8_rdi_sil_eax, .atomic_fetch_and_i16_rdi_si_eax, .atomic_fetch_and_i32_rdi_esi_eax, .atomic_fetch_and_i64_rdi_rsi_rax, .atomic_fetch_sub_i8_rdi_sil_eax, .atomic_fetch_sub_i16_rdi_si_eax, .atomic_fetch_sub_i32_rdi_esi_eax, .atomic_fetch_sub_i64_rdi_rsi_rax, .atomic_fetch_add_i8_rdi_sil_eax, .atomic_fetch_add_i16_rdi_si_eax, .atomic_fetch_add_i32_rdi_esi_eax, .atomic_fetch_add_i64_rdi_rsi_rax, .load_rcx_ptr_u8_eax, .load_rcx_ptr_u16_eax, .load_rcx_ptr_eax, .load_rcx_ptr_rax, .smin_i32_edi_esi_eax, .umin_i32_edi_esi_eax, .smax_i32_edi_esi_eax, .umax_i32_edi_esi_eax, .shift_mix_i32_edi_esi_eax, .replace_low_i8_dil_sil_al, .read_flag_i8_dil_al, .ult_i8_dil_imm8_al, .cmp_ult_u32_edi_esi_al, .ascii_range_u8_dil_imm8_imm8_al, .range_u32_edi_imm32_imm32_al, .ascii_alphabetic_dil_al, .ascii_alphanumeric_dil_al, .ascii_whitespace_dil_al, .ascii_control_dil_al, .grow_capacity_u64_rdi_imm32_rax, .xor_eax_imm32, .setb_eax, .seta_eax, .sete_eax, .setg_eax, .setl_eax, .load_stack_disp8_eax, .load_stack_disp32_eax, .load_stack_rcx4_disp8_eax, .load_stack_rcx4_disp32_eax, .load_stack_disp8_rax, .load_stack_disp32_rax, .load_stack_disp8_u8_eax, .load_stack_disp32_u8_eax, .load_stack_disp8_u16_eax, .load_stack_disp32_u16_eax, .load_rax_ptr_disp8_rax, .load_rax_ptr_disp32_rax, .load_rax_ptr_disp8_u8_eax, .load_rax_ptr_disp8_u16_eax, .load_rax_ptr_disp8_eax, .load_rax_ptr_eax, .load_arg_ptr_eax, .load_arg_ptr_disp8_rax, .load_arg_ptr_disp32_rax, .load_arg_ptr_disp8_eax, .load_arg_ptr_disp8_u8_eax, .load_arg_ptr_disp8_u16_eax, .add_arg_ptr_disp4_eax, .volatile_roundtrip_rdi_esi_eax, .load_global_i32_eax, .load_global_ptr_rax, .lea_global_rax, .lea_global_offset_rax, .load_tls_i32_eax, .add_tls_i32_eax, .atomic_xadd_global_eax, .mulsd_xmm1_xmm0, .mulss_xmm1_xmm0, .addsd_xmm1_xmm0, .addss_xmm1_xmm0, .subss_xmm1_xmm0, .divsd_xmm1_xmm0, .xorps_xmm1_xmm0, .movapd_xmm1_xmm0, .movapd_xmm, .unpcklps_xmm, .shufps_high_f32_to_low, .cvtsi2ss_edi_xmm0, .cvtsi2sd_edi_xmm0, .cvtsi2ss_rdi_xmm0, .cvtsi2sd_rdi_xmm0, .cvttss2si_xmm0_eax, .cvttsd2si_xmm0_eax, .cvtsd2ss_xmm0_xmm0, .cvtss2sd_xmm0_xmm0, .sqrtss_xmm0, .sqrtsd_xmm0, .mov_imm64_xmm0, .mov_imm32_xmm0, .load_stack_disp8_xmm0, .load_stack_disp32_xmm0, .load_stack_disp8_xmm0_f32, .load_stack_disp32_xmm0_f32, .load_f128_const_xmm0, .oltss_xmm0_xmm1_al, .fneg_x86_fp80_stack8_st0, .fneg_fp128_xmm0 => eax_defined = true,
            .mov_imm64_xmm => |load| {
                if (load.reg == .xmm0) eax_defined = true;
            },
            .setne_eax, .setbe_eax, .set_fcmp_eax => eax_defined = true,
            .mov_imm32_xmm => |load| {
                if (load.reg == .xmm0) eax_defined = true;
            },
            .load_arg_ptr_disp8_xmm => |load| {
                if (load.dst == .xmm0) xmm0_defined = true;
            },
            .load_arg_ptr_disp8_u16_arg => {},
            .mov_imm_rdi, .mov_imm_rdx, .mov_imm_rsi, .mov_imm_rcx, .mov_imm_r8, .mov_imm_r9, .mov_rax_rdi, .mov_rax_rsi, .mov_eax_to_arg, .mov_rax_to_arg, .movsxd_arg32_arg64, .imul_arg64_arg64, .imul_arg64_rax, .div_arg32, .div_arg64, .idiv_arg64, .add_arg64_imm32, .shr_arg_imm5, .shr_arg64_imm6, .sar_arg64_imm6, .mov_rsp_arg64, .lea_global_rdi, .lea_global_rsi, .lea_global_rdx, .lea_global_arg64, .load_stack_disp8_arg32, .load_stack_disp8_arg64, .load_stack_disp32_arg32, .load_stack_disp32_arg64, .spinlocked_var_xchg_edi_rsi_rdx_rcx, .spinlocked_var_store_edi_rsi_rdx => {},
            .reload_rsp_eax, .reload_rsp_rax => {
                if (rsp_mod16 != 0) return error.StackSlotWithoutFrame;
                eax_defined = true;
            },
            .direct_call => |call| {
                if (rsp_mod16 != 0) return error.MisalignedStackBeforeCall;
                const call_returns_scalar_sse = sysv_abi.isScalarSseAbiType(call.ret_ty) or sysv_abi.isVector128AbiType(call.ret_ty);
                eax_defined = function.ret_ty == .void or (!call_returns_scalar_sse and call.ret_ty != .void);
                if (call_returns_scalar_sse) xmm0_defined = true;
            },
            .tls_address_rax => {
                if (rsp_mod16 != 0) return error.MisalignedStackBeforeCall;
                eax_defined = true;
                xmm0_defined = false;
                @memset(&xmm_defined_bits, 0);
            },
            .direct_jump => {
                if (!@import("verify_tail_calls.zig").ownsLegacyDirectJump(function, instruction_index) and rsp_mod16 != 8) return error.UnbalancedStackFrame;
                saw_terminator = true;
            },
            .tail_jump_rax => {
                if (rsp_mod16 != 8) return error.UnbalancedStackFrame;
                if (!eax_defined) return error.ReturnRegisterUndefined;
                saw_terminator = true;
            },
            .indirect_call_rax => |ret_ty| {
                if (rsp_mod16 != 0) return error.MisalignedStackBeforeCall;
                const call_returns_scalar_sse = sysv_abi.isScalarSseAbiType(ret_ty);
                eax_defined = function.ret_ty == .void or (!call_returns_scalar_sse and ret_ty != .void);
                if (call_returns_scalar_sse) xmm0_defined = true;
            },
            .sub_rsp_8, .add_rsp_8 => rsp_mod16 = @intCast((@as(u8, rsp_mod16) + 8) % 16),
            .push_imm32, .push_stack_disp8, .push_stack_disp32, .push_arg, .pop_arg, .push_rax, .push_xmm64, .push_byval_tail_arg_ptr, .push_byval_tail_stack_ptr => rsp_mod16 = @intCast((@as(u8, rsp_mod16) + 8) % 16),
            .sub_rsp_24, .add_rsp_24 => rsp_mod16 = @intCast((@as(u8, rsp_mod16) + 24) % 16),
            .sub_rsp_40, .add_rsp_40 => rsp_mod16 = @intCast((@as(u8, rsp_mod16) + 40) % 16),
            .sub_rsp_56, .add_rsp_56 => rsp_mod16 = @intCast((@as(u8, rsp_mod16) + 56) % 16),
            .sub_rsp_imm8 => |bytes| rsp_mod16 = @intCast((@as(u8, rsp_mod16) + bytes) % 16),
            .sub_rsp_imm32 => |bytes| rsp_mod16 = @intCast((@as(u8, rsp_mod16) + bytes) % 16),
            .add_rsp_imm8 => |bytes| rsp_mod16 = @intCast((@as(u8, rsp_mod16) + bytes) % 16),
            .add_rsp_imm32 => |bytes| rsp_mod16 = @intCast((@as(u8, rsp_mod16) + bytes) % 16),
            .spill_arg_rsp, .spill_arg64_rsp => if (rsp_mod16 != 0) return error.StackSlotWithoutFrame,
            .reload_arg_rsp, .reload_arg64_rsp => if (rsp_mod16 != 0) return error.StackSlotWithoutFrame,
            .spill_xmm32_rsp, .spill_xmm64_rsp, .spill_xmm128_rsp, .spill_xmm128ps_rsp => if (rsp_mod16 != 0) return error.StackSlotWithoutFrame,
            .reload_xmm32_rsp, .reload_xmm64_rsp, .reload_xmm128_rsp, .reload_xmm128ps_rsp => {
                if (rsp_mod16 != 0) return error.StackSlotWithoutFrame;
                eax_defined = true;
            },
            .spill_rdi_rsi_rsp24, .reload_rdi_rsp24, .reload_rsi_rsp24 => {
                if (rsp_mod16 != 0) return error.StackSlotWithoutFrame;
            },
            .spill_eax_rsp, .spill_rax_rsp => if (rsp_mod16 != 0) return error.StackSlotWithoutFrame,
            .store_eax_stack_disp8, .store_eax_stack_disp32, .store_al_stack_disp8, .store_al_stack_disp32, .store_eax_stack_rcx4_disp8, .store_eax_stack_rcx4_disp32 => if (rsp_mod16 != 0) return error.StackSlotWithoutFrame,
            .and_rsp_neg16 => rsp_mod16 = 0,
            .noreturn_direct_call => {
                if (rsp_mod16 != 0) return error.MisalignedStackBeforeCall;
                if (function.ret_ty != .void) return error.ReturnTypeMismatch;
                saw_terminator = true;
                eax_defined = true;
            },
            .base64_decode4_from_table_rax => {
                if (!function.ret_ty.eql(.{ .int = 64 })) return error.ReturnTypeMismatch;
                if (rsp_mod16 != 8) return error.UnbalancedStackFrame;
                saw_terminator = true;
                eax_defined = true;
            },
            .mulo_limb64_rdi_rsi_rdx_cl_r8w_al => {
                if (!function.ret_ty.eql(.{ .int = 1 })) return error.ReturnTypeMismatch;
                if (rsp_mod16 != 8) return error.UnbalancedStackFrame;
                saw_terminator = true;
                eax_defined = function.ret_ty == .void;
            },
            .byteswap_limb64_rdi_rsi_dl_cx => {
                if (function.ret_ty != .void) return error.ReturnTypeMismatch;
                if (rsp_mod16 != 8) return error.UnbalancedStackFrame;
                saw_terminator = true;
                eax_defined = true;
            },
            .shr_limb64_rdi_rsi_dx_cl_r8w => {
                if (function.ret_ty != .void) return error.ReturnTypeMismatch;
                if (rsp_mod16 != 8) return error.UnbalancedStackFrame;
                saw_terminator = true;
                eax_defined = true;
            },
            .shlo_limb64_rdi_rsi_dx_cl_r8w_al => {
                if (!function.ret_ty.eql(.{ .int = 1 })) return error.ReturnTypeMismatch;
                if (rsp_mod16 != 8) return error.UnbalancedStackFrame;
                saw_terminator = true;
                eax_defined = function.ret_ty == .void;
            },
            .not_limb64_rdi_rsi_dl_cx => {
                if (function.ret_ty != .void) return error.ReturnTypeMismatch;
                if (rsp_mod16 != 8) return error.UnbalancedStackFrame;
                saw_terminator = true;
                eax_defined = true;
            },
            .bitwise_limb64_rdi_rsi_rdx_cx => {
                if (function.ret_ty != .void) return error.ReturnTypeMismatch;
                if (rsp_mod16 != 8) return error.UnbalancedStackFrame;
                saw_terminator = true;
                eax_defined = true;
            },
            .cmp_limb64_rdi_rsi_dl_cx_ax => {
                if (!function.ret_ty.eql(.{ .int = 8 })) return error.ReturnTypeMismatch;
                if (rsp_mod16 != 8) return error.UnbalancedStackFrame;
                saw_terminator = true;
                eax_defined = true;
            },
            .overflow_limb64_rdi_rsi_rdx_cl_r8w_al => {
                if (!function.ret_ty.eql(.{ .int = 1 })) return error.ReturnTypeMismatch;
                if (rsp_mod16 != 8) return error.UnbalancedStackFrame;
                saw_terminator = true;
                eax_defined = function.ret_ty == .void;
            },
            .bitreverse_limb64_rdi_rsi_dl_cx => {
                if (function.ret_ty != .void) return error.ReturnTypeMismatch;
                if (rsp_mod16 != 8) return error.UnbalancedStackFrame;
                saw_terminator = true;
                eax_defined = true;
            },
            .popcount_limb64_rdi_si_ax => {
                if (!function.ret_ty.eql(.{ .int = 16 })) return error.ReturnTypeMismatch;
                if (rsp_mod16 != 8) return error.UnbalancedStackFrame;
                saw_terminator = true;
                eax_defined = true;
            },
            .ctz_limb64_rdi_si_ax => {
                if (!function.ret_ty.eql(.{ .int = 16 })) return error.ReturnTypeMismatch;
                if (rsp_mod16 != 8) return error.UnbalancedStackFrame;
                saw_terminator = true;
                eax_defined = true;
            },
            .clz_limb64_rdi_si_ax => {
                if (!function.ret_ty.eql(.{ .int = 16 })) return error.ReturnTypeMismatch;
                if (rsp_mod16 != 8) return error.UnbalancedStackFrame;
                saw_terminator = true;
                eax_defined = true;
            },
            .udivei4_before_intbytesize => {
                if (function.ret_ty != .void) return error.ReturnTypeMismatch;
                if (rsp_mod16 != 8) return error.UnbalancedStackFrame;
                rsp_mod16 = 0;
                eax_defined = true;
            },
            .udivei4_between_intbytesize_and_memset => {
                if (function.ret_ty != .void) return error.ReturnTypeMismatch;
                if (rsp_mod16 != 0) return error.UnbalancedStackFrame;
                eax_defined = true;
            },
            .udivei4_after_memset => {
                if (function.ret_ty != .void) return error.ReturnTypeMismatch;
                if (rsp_mod16 != 0) return error.UnbalancedStackFrame;
                rsp_mod16 = 8;
                saw_terminator = true;
                eax_defined = true;
            },
            .umodei5_before_intbytesize => {
                if (function.ret_ty != .void) return error.ReturnTypeMismatch;
                if (rsp_mod16 != 8) return error.UnbalancedStackFrame;
                rsp_mod16 = 0;
                eax_defined = true;
            },
            .umodei5_between_intbytesize_and_memset => {
                if (function.ret_ty != .void) return error.ReturnTypeMismatch;
                if (rsp_mod16 != 0) return error.UnbalancedStackFrame;
                eax_defined = true;
            },
            .umodei5_after_memset_before_memcpy => {
                if (function.ret_ty != .void) return error.ReturnTypeMismatch;
                if (rsp_mod16 != 0) return error.UnbalancedStackFrame;
                eax_defined = true;
            },
            .umodei5_after_memcpy => {
                if (function.ret_ty != .void) return error.ReturnTypeMismatch;
                if (rsp_mod16 != 0) return error.UnbalancedStackFrame;
                rsp_mod16 = 8;
                saw_terminator = true;
                eax_defined = true;
            },
            .mov_arg_arg, .mov_arg64_arg, .xor_edx_edx, .shl_rdx_imm6, .shl_rcx_imm6, .shl_r8_imm6, .or_rcx_rax, .or_rcx_rdx, .add_rcx_imm32, .add_r8_rcx, .sub_r8_rcx, .xor_ecx_ecx, .xor_ebp_ebp, .load_rdi_rcx4_ptr_r8d, .store_eax_rdi_rcx4_ptr, .store_al_rcx_ptr, .store_ax_rcx_ptr, .store_eax_rcx_ptr, .store_rax_rcx_ptr, .inc_rcx, .movzx_dil_edi, .and_edi_imm8, .mov_edi_edi, .mov_rsp_rdi, .load_rax_ptr_rdx, .cmp_ecx_arg32, .cmp_rcx_arg64, .cmp_r8d_arg32, .cmp_ecx_imm32, .cmp_eax_imm32, .cmp_arg64_imm64, .cmp_arg16_imm16, .cmp_rdi_imm64, .cmp_rdx_rcx, .cmp_rdx_rdi, .cmp_rax_rdx, .cmp_arg8_imm8, .test_eax_eax, .test_rax_rax, .test_rdx_rdx, .test_arg8, .test_arg32, .test_arg64, .base64_raw_args_to_decode4_regs, .stack_probe_rax_rcx_rsp, .spinlocked_memcpy_rsi_to_rdx_len_edi, .spinlocked_store_i128_rdi_rsi_rdx, .store_eax_arg_ptr, .store_imm64_arg_ptr_disp8, .inc_arg_ptr_disp8, .store_arg64_arg_ptr_disp8, .store_arg64_arg_ptr_disp32, .store_rax_arg_ptr_disp8, .store_rax_arg_ptr_disp32, .store_eax_arg_ptr_disp8, .store_eax_arg_ptr_disp32, .store_al_arg_ptr_disp8, .store_al_arg_ptr_disp32, .store_ax_arg_ptr_disp8, .store_ax_arg_ptr_disp32, .store_xmm0_arg_ptr_disp8, .store_xmm0_arg_ptr_disp32, .store_xmm0_f32_arg_ptr_disp8, .store_xmm0_f32_arg_ptr_disp32, .store_imm8_arg_ptr_disp8, .load_stack_disp8_xmm, .load_stack_disp32_xmm, .load_stack_disp8_xmm_f32, .load_stack_disp32_xmm_f32, .mov_imm64_xmm1, .mov_imm32_xmm1, .ucomisd, .ucomiss, .ucomisd_xmm1_xmm0, .ucomiss_xmm1_xmm0, .ucomiss_xmm0_xmm1, .load_f128_arg_ptr_xmm0, .load_f128_const_xmm1, .store_f128_xmm0_arg_ptr, .store_eax_global_i32, .store_eax_tls_i32, .store_imm8_abs, .syscall, .je, .jne, .jo, .jc, .jp, .js, .jae, .jle, .jmp => {},
            .ret => {
                if (function.ret_ty == .fp128 or sysv_abi.isVector128AbiType(function.ret_ty)) {
                    if (xmm_defined_bits[0] < 128) return error.ReturnRegisterUndefined;
                } else if (returns_scalar_sse) {
                    if (!xmm0_defined) return error.ReturnRegisterUndefined;
                } else if (aggregate_return_kind) |kind| {
                    switch (kind) {
                        .packed_f32x2 => if (xmm_defined_bits[0] < 64) return error.ReturnRegisterUndefined,
                        .split_f64x2 => if (xmm_defined_bits[0] < 64 or xmm_defined_bits[1] < 64) return error.ReturnRegisterUndefined,
                    }
                } else if (function.ret_ty != .x86_fp80 and !eax_defined) return error.ReturnRegisterUndefined;
                if (rsp_mod16 != 8) return error.UnbalancedStackFrame;
                saw_terminator = true;
                eax_defined = function.ret_ty == .void;
                xmm0_defined = false;
                xmm_defined_bits = @splat(0);
            },
            .ud2 => {
                saw_terminator = true;
                eax_defined = eax_defined_before_label;
                xmm0_defined = xmm0_defined_before_label;
                xmm_defined_bits = xmm_defined_bits_before_label;
                preserve_eax_at_next_label = true;
            },
        }
    }
    // A closed branch cycle is a valid nonreturning function. Label targets
    // were checked above; requiring a final jump rules out falling off the end.
    if (!saw_terminator and (function.instructions.items.len == 0 or
        function.instructions.items[function.instructions.items.len - 1] != .jmp))
        return error.MissingMachineReturn;
}

// Prove the incoming return-register definitions for a final shared epilogue.
// Its suffix only restores rsp and returns, so all incoming branches precede
// it. Other joins keep their existing conservative block-local checks; this is
// not a general CFG dataflow analysis or an exemption based on a label name.
fn finalReturnJoin(function: MachineFunction) ?usize {
    const instructions = function.instructions.items;
    if (instructions.len == 0 or instructions[instructions.len - 1] != .ret) return null;
    var index = instructions.len - 1;
    while (index > 0) {
        index -= 1;
        switch (instructions[index]) {
            .label => return index,
            .add_rsp_8, .add_rsp_24, .add_rsp_40, .add_rsp_56, .add_rsp_imm8, .add_rsp_imm32 => {},
            else => return null,
        }
    }
    return null;
}

fn fallsThrough(instruction: machine_ir.Instruction) bool {
    return switch (instruction) {
        .jmp, .indirect_jump, .ret, .ud2, .direct_jump, .tail_jump_rax, .noreturn_direct_call => false,
        else => true,
    };
}

const ReturnDefinitions = struct {
    incoming: usize = 0,
    eax: bool = true,
    xmm0: bool = true,
    xmm_bits: [8]u16 = @splat(std.math.maxInt(u16)),

    fn include(self: *ReturnDefinitions, eax: bool, xmm0: bool, xmm_bits: [8]u16) void {
        self.incoming += 1;
        self.eax = self.eax and eax;
        self.xmm0 = self.xmm0 and xmm0;
        for (&self.xmm_bits, xmm_bits) |*bits, incoming| bits.* = @min(bits.*, incoming);
    }
};

fn recordXmmDefinitions(instruction: machine_ir.Instruction, defined_bits: *[8]u16) void {
    switch (instruction) {
        .sqrtss_xmm0 => defined_bits[0] = if (defined_bits[0] >= 32) 32 else 0,
        .sqrtsd_xmm0 => defined_bits[0] = if (defined_bits[0] >= 64) 64 else 0,
        .direct_call => |call| if (sysv_abi.isVector128AbiType(call.ret_ty)) {
            defined_bits[0] = 128;
        },
        .wide_int_to_fp_rdi_rsi_xmm0 => |conversion| defined_bits[0] = conversion.to_bits,
        .mov_imm32_xmm0 => defined_bits[0] = 32,
        .mov_imm32_xmm1 => defined_bits[1] = 32,
        .mov_imm64_xmm0 => defined_bits[0] = 64,
        .mov_imm64_xmm1 => defined_bits[1] = 64,
        .mov_imm32_xmm => |move| defined_bits[@backingInt(move.reg)] = 32,
        .mov_imm64_xmm => |move| defined_bits[@backingInt(move.reg)] = 64,
        .movapd_xmm1_xmm0 => defined_bits[0] = defined_bits[1],
        .movapd_xmm => |move| defined_bits[@backingInt(move.dst)] = defined_bits[@backingInt(move.src)],
        .unpcklps_xmm => |unpack| {
            const dst = @backingInt(unpack.dst);
            const src = @backingInt(unpack.src);
            defined_bits[dst] = if (defined_bits[dst] >= 32 and defined_bits[src] >= 32) 64 else 0;
        },
        .unpcklpd_xmm => |unpack| {
            const dst = @backingInt(unpack.dst);
            const src = @backingInt(unpack.src);
            defined_bits[dst] = if (defined_bits[dst] >= 64 and defined_bits[src] >= 64) 128 else 0;
        },
        .unpckhpd_xmm => |unpack| {
            const dst = @backingInt(unpack.dst);
            const src = @backingInt(unpack.src);
            defined_bits[dst] = if (defined_bits[dst] >= 128 and defined_bits[src] >= 128) 128 else 0;
        },
        .load_f128_arg_ptr_xmm0, .load_f128_const_xmm0 => defined_bits[0] = 128,
        .load_f128_const_xmm1 => defined_bits[1] = 128,
        .reload_xmm32_rsp => |reload| defined_bits[@backingInt(reload.reg)] = 32,
        .reload_xmm64_rsp => |reload| defined_bits[@backingInt(reload.reg)] = 64,
        .reload_xmm128_rsp => |reload| defined_bits[@backingInt(reload.reg)] = 128,
        .reload_xmm128ps_rsp => |reload| defined_bits[@backingInt(reload.reg)] = 128,
        .load_stack_disp8_xmm0, .load_stack_disp32_xmm0 => defined_bits[0] = 64,
        .load_stack_disp8_xmm0_f32, .load_stack_disp32_xmm0_f32 => defined_bits[0] = 32,
        .load_stack_disp8_xmm => |load| defined_bits[@backingInt(load.reg)] = 64,
        .load_stack_disp32_xmm => |load| defined_bits[@backingInt(load.reg)] = 64,
        .load_stack_disp8_xmm_f32 => |load| defined_bits[@backingInt(load.reg)] = 32,
        .load_stack_disp32_xmm_f32 => |load| defined_bits[@backingInt(load.reg)] = 32,
        .load_arg_ptr_disp8_xmm => |load| defined_bits[@backingInt(load.dst)] = 64,
        .movd_eax_xmm => |reg| defined_bits[@backingInt(reg)] = 32,
        .movq_rax_xmm => |reg| defined_bits[@backingInt(reg)] = 64,
        .movss_xmm => |move| {
            const dst = @backingInt(move.dst);
            defined_bits[dst] = @max(defined_bits[dst], @as(u16, 32));
        },
        .movsd_xmm => |move| {
            const dst = @backingInt(move.dst);
            defined_bits[dst] = @max(defined_bits[dst], @as(u16, 64));
        },
        .addps_xmm => |binary| defined_bits[@backingInt(binary.dst)] = 128,
        .subps_xmm => |binary| defined_bits[@backingInt(binary.dst)] = 128,
        .mulps_xmm => |binary| defined_bits[@backingInt(binary.dst)] = 128,
        .addpd_xmm => |binary| defined_bits[@backingInt(binary.dst)] = 128,
        .subpd_xmm => |binary| defined_bits[@backingInt(binary.dst)] = 128,
        .mulpd_xmm => |binary| defined_bits[@backingInt(binary.dst)] = 128,
        .andps_xmm => |binary| defined_bits[@backingInt(binary.dst)] = 128,
        .pxor_xmm => |binary| defined_bits[@backingInt(binary.dst)] = 128,
        .pcmpgtd_xmm => |binary| defined_bits[@backingInt(binary.dst)] = 128,
        .cmpeqps_xmm => |binary| defined_bits[@backingInt(binary.dst)] = 128,
        .cmpeqpd_xmm => |binary| defined_bits[@backingInt(binary.dst)] = 128,
        else => {},
    }
}

fn hasLabel(function: MachineFunction, name: []const u8) bool {
    for (function.instructions.items) |instruction| switch (instruction) {
        .read_thread_pointer_rax, .linux_clone_trampoline, .linux_syscall, .register_snapshot_rdi, .cpuid_packed, .xgetbv_eax, .valgrind_client_request, .indirect_jump => {},
        .label => |label_name| if (std.mem.eql(u8, label_name, name)) return true,
        .mov_imm_eax,
        .mov_imm_rax,
        .mov_imm_rdi,
        .mov_imm_rdx,
        .mov_imm_rsi,
        .mov_imm_rcx,
        .mov_imm_r8,
        .mov_imm_r9,
        .mov_rax_rdi,
        .mov_rax_rsi,
        .mov_arg_rax,
        .movq_xmm_rax,
        .movq_rax_xmm,
        .movd_xmm_eax,
        .movd_eax_xmm,
        .mov_arg_eax,
        .mov_eax_to_arg,
        .mov_rax_to_arg,
        .mov_arg_arg,
        .mov_arg64_arg,
        .mov_rsp_arg64,
        .movsxd_arg32_arg64,
        .binary_arg_eax,
        .binary_arg_rax,
        .sbb_arg64_rax,
        .adc_rax_imm0,
        .imul_eax_arg32,
        .imul_arg64_arg64,
        .imul_arg64_rax,
        .imul_rax_arg64,
        .imul_rax_rsp,
        .mul_rax_arg64_full,
        .imul_rax_arg64_full,
        .xor_edx_edx,
        .div_arg32,
        .div_arg64,
        .idiv_arg64,
        .add_arg64_rax,
        .add_arg64_imm32,
        .add_arg_high32_eax,
        .add_stack_disp8_eax,
        .add_stack_disp8_rax,
        .add_stack_disp32_eax,
        .add_stack_disp32_rax,
        .add_eax_imm32,
        .shl_eax_imm5,
        .shr_eax_imm5,
        .sar_eax_imm5,
        .shr_arg_imm5,
        .shr_arg64_imm6,
        .sar_arg64_imm6,
        .shl_eax_cl,
        .shr_eax_cl,
        .sar_eax_cl,
        .shl_rax_cl,
        .shr_rax_cl,
        .sar_rax_cl,
        .fshl_eax_arg32_imm5,
        .or_eax_imm32,
        .imul_eax_imm32,
        .and_eax_imm32,
        .abs_i32_edi_eax,
        .abs_i64_rdi_rax,
        .wide_int_to_fp_rdi_rsi_xmm0,
        .clz_i128_rdi_rsi_eax,
        .clz_i64_rdi_eax,
        .clz_i32_edi_eax,
        .ctz_i32_edi_eax,
        .popcount_i32_edi_eax,
        .popcount_rax,
        .bit_reverse_i32_edi_eax,
        .bit_reverse_rax,
        .ushl_sat_i32_edi_imm_eax,
        .bswap_eax,
        .bswap_rax,
        .rol_ax_imm8,
        .shr_rax_imm6,
        .shl_rax_imm6,
        .shl_rdx_imm6,
        .or_rdx_rax,
        .neg_rax,
        .neg_i128_rdi_rsi_rdx_rax,
        .abs_limb64_rdi_rsi_dx_rcx_rax,
        .mulo_limb64_rdi_rsi_rdx_cl_r8w_al,
        .byteswap_limb64_rdi_rsi_dl_cx,
        .shr_limb64_rdi_rsi_dx_cl_r8w,
        .shlo_limb64_rdi_rsi_dx_cl_r8w_al,
        .not_limb64_rdi_rsi_dl_cx,
        .bitwise_limb64_rdi_rsi_rdx_cx,
        .cmp_limb64_rdi_rsi_dl_cx_ax,
        .overflow_limb64_rdi_rsi_rdx_cl_r8w_al,
        .bitreverse_limb64_rdi_rsi_dl_cx,
        .popcount_limb64_rdi_si_ax,
        .ctz_limb64_rdi_si_ax,
        .clz_limb64_rdi_si_ax,
        .udivei4_before_intbytesize,
        .udivei4_between_intbytesize_and_memset,
        .udivei4_after_memset,
        .umodei5_before_intbytesize,
        .umodei5_between_intbytesize_and_memset,
        .umodei5_after_memset_before_memcpy,
        .umodei5_after_memcpy,
        .ctz_i128_rdi_rsi_eax,
        .ctz_i64_rdi_eax,
        .ffs_i128_rdi_rsi_eax,
        .ffs_i64_rdi_eax,
        .ffs_i32_edi_eax,
        .shl_rcx_imm6,
        .shl_r8_imm6,
        .or_rcx_rax,
        .or_rcx_rdx,
        .add_rax_imm8,
        .add_rcx_imm32,
        .add_r8_rcx,
        .sub_r8_rcx,
        .add_ecx_eax,
        .xor_ecx_ecx,
        .xor_ebp_ebp,
        .add_rdi_rcx4_ptr_eax,
        .load_rdi_rcx4_ptr_r8d,
        .store_eax_rdi_rcx4_ptr,
        .load_rdi_ptr_u8_eax,
        .load_rdi_ptr_u16_eax,
        .load_rdi_ptr_eax,
        .load_rdi_ptr_rax,
        .load_rcx_ptr_u8_eax,
        .load_rcx_ptr_u16_eax,
        .load_rcx_ptr_eax,
        .load_rcx_ptr_rax,
        .store_al_rcx_ptr,
        .store_ax_rcx_ptr,
        .store_eax_rcx_ptr,
        .store_rax_rcx_ptr,
        .cmp_r8d_arg32,
        .add_r8d_eax,
        .inc_rcx,
        .movzx_dil_edi,
        .and_edi_imm8,
        .load_rax_rdi_u8_eax,
        .bcmp_rdi_rsi_rdx_eax,
        .memcmp_rdi_rsi_rdx_eax,
        .memcpy_rdi_rsi_rdx_rax,
        .spinlocked_memcpy_rsi_to_rdx_len_edi,
        .spinlocked_var_cmpxchg_edi_rsi_rdx_rcx_eax,
        .spinlocked_var_xchg_edi_rsi_rdx_rcx,
        .spinlocked_var_store_edi_rsi_rdx,
        .cmpxchg_ptr_expected_desired_i8_eax,
        .cmpxchg_ptr_expected_desired_i16_eax,
        .cmpxchg_ptr_expected_desired_i32_eax,
        .cmpxchg_ptr_expected_desired_i64_eax,
        .spinlocked_cmpxchg_i128_rdi_rsi_rdx_rcx_eax,
        .xchg_ptr_value_i8_eax,
        .xchg_ptr_value_i16_eax,
        .xchg_ptr_value_i32_eax,
        .xchg_ptr_value_i64_rax,
        .atomic_xchg_rdi_disp8_rax,
        .atomic_fetch_umin_i8_rdi_sil_eax,
        .atomic_fetch_umin_i16_rdi_si_eax,
        .atomic_fetch_umin_i32_rdi_esi_eax,
        .atomic_fetch_umin_i64_rdi_rsi_rax,
        .atomic_fetch_umax_i8_rdi_sil_eax,
        .atomic_fetch_umax_i16_rdi_si_eax,
        .atomic_fetch_umax_i32_rdi_esi_eax,
        .atomic_fetch_umax_i64_rdi_rsi_rax,
        .atomic_fetch_nand_i8_rdi_sil_eax,
        .atomic_fetch_nand_i16_rdi_si_eax,
        .atomic_fetch_nand_i32_rdi_esi_eax,
        .atomic_fetch_nand_i64_rdi_rsi_rax,
        .atomic_fetch_xor_i8_rdi_sil_eax,
        .atomic_fetch_xor_i16_rdi_si_eax,
        .atomic_fetch_xor_i32_rdi_esi_eax,
        .atomic_fetch_xor_i64_rdi_rsi_rax,
        .atomic_fetch_or_i8_rdi_sil_eax,
        .atomic_fetch_or_i16_rdi_si_eax,
        .atomic_fetch_or_i32_rdi_esi_eax,
        .atomic_fetch_or_i64_rdi_rsi_rax,
        .atomic_fetch_and_i8_rdi_sil_eax,
        .atomic_fetch_and_i16_rdi_si_eax,
        .atomic_fetch_and_i32_rdi_esi_eax,
        .atomic_fetch_and_i64_rdi_rsi_rax,
        .atomic_fetch_sub_i8_rdi_sil_eax,
        .atomic_fetch_sub_i16_rdi_si_eax,
        .atomic_fetch_sub_i32_rdi_esi_eax,
        .atomic_fetch_sub_i64_rdi_rsi_rax,
        .atomic_fetch_add_i8_rdi_sil_eax,
        .atomic_fetch_add_i16_rdi_si_eax,
        .atomic_fetch_add_i32_rdi_esi_eax,
        .atomic_fetch_add_i64_rdi_rsi_rax,
        .spinlocked_xchg_i128_rdi_rsi_rdx_rax,
        .spinlocked_store_i128_rdi_rsi_rdx,
        .spinlocked_load_i128_rdi_rax_rdx,
        .spinlocked_fetch_umin_i128_rdi_rsi_rdx_rax_rdx,
        .spinlocked_fetch_umax_i128_rdi_rsi_rdx_rax_rdx,
        .spinlocked_fetch_nand_i128_rdi_rsi_rdx_rax_rdx,
        .spinlocked_fetch_xor_i128_rdi_rsi_rdx_rax_rdx,
        .spinlocked_fetch_or_i128_rdi_rsi_rdx_rax_rdx,
        .spinlocked_fetch_and_i128_rdi_rsi_rdx_rax_rdx,
        .spinlocked_fetch_sub_i128_rdi_rsi_rdx_rax_rdx,
        .spinlocked_fetch_add_i128_rdi_rsi_rdx_rax_rdx,
        .memmove_rdi_rsi_rdx_rax,
        .stack_probe_rax_rcx_rsp,
        .guarded_memset_rdi_sil_rdx_rcx_rax,
        .guarded_memcpy_rdi_rsi_rdx_rcx_rax,
        .guarded_strncat_rdi_rsi_rdx_rcx_rax,
        .guarded_strcat_rdi_rsi_rdx_rax,
        .guarded_strncpy_rdi_rsi_rdx_rcx_rax,
        .guarded_strcpy_rdi_rsi_rdx_rax,
        .memset_rdi_sil_rdx_rax,
        .strlen_rdi_rax,
        .strnlen_rdi_rsi_rax,
        .atomic_try_lock_rdi_al,
        .smin_i32_edi_esi_eax,
        .umin_i32_edi_esi_eax,
        .smax_i32_edi_esi_eax,
        .umax_i32_edi_esi_eax,
        .shift_mix_i32_edi_esi_eax,
        .replace_low_i8_dil_sil_al,
        .read_flag_i8_dil_al,
        .ult_i8_dil_imm8_al,
        .cmp_ult_u32_edi_esi_al,
        .ascii_range_u8_dil_imm8_imm8_al,
        .range_u32_edi_imm32_imm32_al,
        .ascii_alphabetic_dil_al,
        .ascii_alphanumeric_dil_al,
        .ascii_whitespace_dil_al,
        .ascii_control_dil_al,
        .grow_capacity_u64_rdi_imm32_rax,
        .xor_eax_imm32,
        .store_imm8_abs,
        .cmp_ecx_arg32,
        .cmp_rcx_arg64,
        .cmp_arg64_imm64,
        .cmp_arg16_imm16,
        .cmp_rdi_imm64,
        .cmp_rdx_rcx,
        .cmp_rdx_rdi,
        .cmp_rax_rdx,
        .setb_eax,
        .seta_eax,
        .sete_eax,
        .setg_eax,
        .setl_eax,
        .setne_eax,
        .setbe_eax,
        .test_eax_eax,
        .test_rax_rax,
        .test_rdx_rdx,
        .mulsd_xmm1_xmm0,
        .mulss_xmm1_xmm0,
        .mulsd_xmm,
        .mulss_xmm,
        .subsd_xmm,
        .subss_xmm,
        .divsd_xmm,
        .divss_xmm,
        .addsd_xmm,
        .addss_xmm,
        .addsd_xmm1_xmm0,
        .addss_xmm1_xmm0,
        .subss_xmm1_xmm0,
        .divsd_xmm1_xmm0,
        .xorps_xmm1_xmm0,
        .movapd_xmm1_xmm0,
        .movapd_xmm,
        .addpd_xmm,
        .subpd_xmm,
        .mulpd_xmm,
        .addps_xmm,
        .subps_xmm,
        .mulps_xmm,
        .andps_xmm,
        .pxor_xmm,
        .pcmpgtd_xmm,
        .cmpeqps_xmm,
        .cmpeqpd_xmm,
        .movmskps_xmm_eax,
        .movmskpd_xmm_eax,
        .movsd_xmm,
        .movss_xmm,
        .unpcklpd_xmm,
        .unpckhpd_xmm,
        .shufpd_xmm,
        .unpcklps_xmm,
        .shufps_high_f32_to_low,
        .shufps_xmm,
        .cvtsi2ss_edi_xmm0,
        .cvtsi2sd_edi_xmm0,
        .cvtsi2ss_rdi_xmm0,
        .cvtsi2sd_rdi_xmm0,
        .cvttss2si_xmm0_eax,
        .cvttsd2si_xmm0_eax,
        .cvtsd2ss_xmm0_xmm0,
        .cvtss2sd_xmm0_xmm0,
        .sqrtss_xmm0,
        .sqrtsd_xmm0,
        .cvtsd2ss_xmm,
        .cvtss2sd_xmm,
        .mov_edi_edi,
        .mov_imm64_xmm0,
        .mov_imm64_xmm1,
        .mov_imm32_xmm0,
        .mov_imm32_xmm1,
        .mov_imm64_xmm,
        .mov_imm32_xmm,
        .ucomisd,
        .ucomiss,
        .set_fcmp_eax,
        .ucomisd_xmm1_xmm0,
        .ucomiss_xmm1_xmm0,
        .ucomiss_xmm0_xmm1,
        .oltss_xmm0_xmm1_al,
        .fneg_x86_fp80_stack8_st0,
        .i80_rax_rdx_st0,
        .x87_st0_i80_rax_rdx,
        .x87_binary_pop,
        .x87_sqrt_st0,
        .fneg_fp128_xmm0,
        .sub_rsp_8,
        .add_rsp_8,
        .push_imm32,
        .push_stack_disp8,
        .push_stack_disp32,
        .push_arg,
        .pop_arg,
        .push_rax,
        .push_xmm64,
        .push_byval_tail_arg_ptr,
        .push_byval_tail_stack_ptr,
        .sub_rsp_24,
        .add_rsp_24,
        .sub_rsp_40,
        .add_rsp_40,
        .sub_rsp_56,
        .add_rsp_56,
        .sub_rsp_imm8,
        .sub_rsp_imm32,
        .add_rsp_imm8,
        .add_rsp_imm32,
        .spill_arg_rsp,
        .spill_arg64_rsp,
        .reload_arg_rsp,
        .reload_arg64_rsp,
        .spill_xmm32_rsp,
        .reload_xmm32_rsp,
        .spill_xmm64_rsp,
        .reload_xmm64_rsp,
        .spill_xmm128_rsp,
        .reload_xmm128_rsp,
        .spill_xmm128ps_rsp,
        .reload_xmm128ps_rsp,
        .spill_rdi_rsi_rsp24,
        .reload_rdi_rsp24,
        .reload_rsi_rsp24,
        .spill_eax_rsp,
        .reload_rsp_eax,
        .spill_rax_rsp,
        .reload_rsp_rax,
        .load_stack_disp8_eax,
        .load_stack_disp32_eax,
        .load_stack_rcx4_disp8_eax,
        .load_stack_rcx4_disp32_eax,
        .load_stack_disp8_rax,
        .load_stack_disp32_rax,
        .load_stack_disp8_u8_eax,
        .load_stack_disp32_u8_eax,
        .load_stack_disp8_u16_eax,
        .load_stack_disp32_u16_eax,
        .load_stack_disp8_xmm0,
        .load_stack_disp32_xmm0,
        .load_stack_disp8_xmm0_f32,
        .load_stack_disp32_xmm0_f32,
        .load_stack_disp8_xmm,
        .load_stack_disp32_xmm,
        .load_stack_disp8_xmm_f32,
        .load_stack_disp32_xmm_f32,
        .load_stack_disp8_arg32,
        .load_stack_disp8_arg64,
        .load_stack_disp32_arg32,
        .load_stack_disp32_arg64,
        .load_rax_ptr_disp8_rax,
        .load_rax_ptr_disp32_rax,
        .load_rax_ptr_disp8_u8_eax,
        .load_rax_ptr_disp8_u16_eax,
        .load_rax_ptr_disp8_eax,
        .load_rax_ptr_rdx,
        .load_rax_ptr_eax,
        .load_arg_ptr_eax,
        .load_arg_ptr_disp8_rax,
        .load_arg_ptr_disp32_rax,
        .load_arg_ptr_disp8_eax,
        .load_arg_ptr_disp8_u8_eax,
        .load_arg_ptr_disp8_u16_eax,
        .load_arg_ptr_disp8_u16_arg,
        .load_arg_ptr_disp8_xmm,
        .add_arg_ptr_disp4_eax,
        .inc_arg_ptr_disp8,
        .store_eax_arg_ptr,
        .store_imm64_arg_ptr_disp8,
        .store_arg64_arg_ptr_disp8,
        .store_arg64_arg_ptr_disp32,
        .store_rax_arg_ptr_disp8,
        .store_rax_arg_ptr_disp32,
        .store_eax_arg_ptr_disp8,
        .store_eax_arg_ptr_disp32,
        .store_eax_stack_disp8,
        .store_eax_stack_disp32,
        .store_al_stack_disp8,
        .store_al_stack_disp32,
        .store_eax_stack_rcx4_disp8,
        .store_eax_stack_rcx4_disp32,
        .store_al_arg_ptr_disp8,
        .store_al_arg_ptr_disp32,
        .store_ax_arg_ptr_disp8,
        .store_ax_arg_ptr_disp32,
        .store_xmm0_arg_ptr_disp8,
        .store_xmm0_arg_ptr_disp32,
        .store_xmm0_f32_arg_ptr_disp8,
        .store_xmm0_f32_arg_ptr_disp32,
        .store_imm8_arg_ptr_disp8,
        .load_f128_arg_ptr_xmm0,
        .load_f128_const_xmm0,
        .load_f128_const_xmm1,
        .store_f128_xmm0_arg_ptr,
        .volatile_roundtrip_rdi_esi_eax,
        .load_global_i32_eax,
        .load_global_ptr_rax,
        .lea_global_rax,
        .lea_global_offset_rax,
        .lea_global_rdi,
        .lea_global_rsi,
        .lea_global_rdx,
        .lea_global_arg64,
        .store_eax_global_i32,
        .load_tls_i32_eax,
        .add_tls_i32_eax,
        .store_eax_tls_i32,
        .atomic_xadd_global_eax,
        .mov_rsp_rdi,
        .and_rsp_neg16,
        .direct_call,
        .tls_address_rax,
        .direct_jump,
        .tail_jump_rax,
        .indirect_call_rax,
        .noreturn_direct_call,
        .cmp_arg8_imm8,
        .cmp_ecx_imm32,
        .cmp_eax_imm32,
        .test_arg8,
        .test_arg32,
        .test_arg64,
        .base64_raw_args_to_decode4_regs,
        .base64_decode4_from_table_rax,
        .syscall,
        .ud2,
        .je,
        .jne,
        .jo,
        .jc,
        .jp,
        .js,
        .jae,
        .jle,
        .jmp,
        .ret,
        => {},
    };
    return false;
}

fn validateByvalTail(offset: u8, len: u8) !void {
    switch (len) {
        3, 5, 6, 7 => {},
        else => return error.UnsupportedSretByvalAbi,
    }
    if (@as(u16, offset) + @as(u16, len) > 256) return error.UnsupportedCodegenAbi;
}
