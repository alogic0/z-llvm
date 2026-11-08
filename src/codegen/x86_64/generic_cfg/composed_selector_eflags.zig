const std = @import("std");
const machine = @import("../machine.zig");

pub const Instruction = machine.Instruction;

pub const Effect = enum {
    preserve,
    definition,
    use,
    use_and_definition,
    use_and_clobber,
    write,
    clobber,
};

pub const DefinitionPurpose = enum {
    comparison,
    overflow,
    carry,
};

pub const ConsumerPurpose = enum {
    comparison,
    overflow,
    carry,
};

pub const Liveness = struct {
    const Status = enum {
        undefined,
        defined_unused,
        defined_used,
    };

    pub const Snapshot = struct {
        status: Status,
        definition_purpose: ?DefinitionPurpose,
    };

    status: Status = .undefined,
    definition_purpose: ?DefinitionPurpose = null,

    pub fn snapshot(liveness: Liveness) Snapshot {
        return .{ .status = liveness.status, .definition_purpose = liveness.definition_purpose };
    }

    pub fn restore(liveness: *Liveness, saved: Snapshot) void {
        liveness.status = saved.status;
        liveness.definition_purpose = saved.definition_purpose;
    }

    pub fn validateSnapshot(liveness: Liveness, saved: Snapshot) !void {
        if (liveness.status != saved.status or liveness.definition_purpose != saved.definition_purpose)
            return error.EflagsSnapshotMismatch;
    }

    pub fn apply(liveness: *Liveness, effect: Effect) !void {
        switch (effect) {
            .preserve => {},
            .definition => {
                if (liveness.status == .defined_unused) return error.EflagsDefinitionOverwrittenWhileLive;
                liveness.status = .defined_unused;
                liveness.definition_purpose = null;
            },
            .use => {
                if (liveness.status == .undefined) return error.EflagsConsumerWithoutDefinition;
                liveness.status = .defined_used;
            },
            .use_and_definition => {
                if (liveness.status == .undefined) return error.EflagsConsumerWithoutDefinition;
                liveness.status = .defined_unused;
                liveness.definition_purpose = null;
            },
            .use_and_clobber => {
                if (liveness.status == .undefined) return error.EflagsConsumerWithoutDefinition;
                liveness.status = .undefined;
                liveness.definition_purpose = null;
            },
            .write, .clobber => {
                if (liveness.status == .defined_unused) return error.EflagsClobberedWhileLive;
                liveness.status = .undefined;
                liveness.definition_purpose = null;
            },
        }
    }

    pub fn defineFor(liveness: *Liveness, purpose: DefinitionPurpose) !void {
        try liveness.apply(.definition);
        liveness.definition_purpose = purpose;
    }

    pub fn useFor(liveness: *Liveness, purpose: ConsumerPurpose, final: bool) !void {
        if (liveness.status == .undefined) return error.EflagsConsumerWithoutDefinition;
        if (liveness.definition_purpose) |definition| {
            const compatible = definition == .comparison or switch (purpose) {
                .comparison => false,
                .overflow => definition == .overflow,
                .carry => definition == .carry,
            };
            if (!compatible) return error.EflagsIncompatibleConsumer;
        }
        liveness.status = if (final) .undefined else .defined_used;
        if (final) liveness.definition_purpose = null;
    }

    pub fn carryLink(liveness: *Liveness, final: bool) !void {
        try liveness.useFor(.carry, final);
        if (!final) {
            liveness.status = .defined_unused;
            liveness.definition_purpose = .carry;
        }
    }

    pub fn accumulatorPreparation(liveness: *Liveness) !void {
        try liveness.apply(.clobber);
    }
};

pub fn instructionEffect(instruction: Instruction) Effect {
    // DIV leaves arithmetic flags undefined. Keep this fail-closed override
    // ahead of the exhaustive physical-write classification below.
    switch (instruction) {
        .div_arg32, .div_arg64, .idiv_arg64 => return .clobber,
        else => {},
    }
    return switch (instruction) {
        .indirect_jump => .preserve,
        .linux_syscall, .register_snapshot_rdi => .clobber,
        .cmp_r8d_arg32, .cmp_ecx_arg32, .cmp_rcx_arg64, .cmp_ecx_imm32, .cmp_eax_imm32, .cmp_arg64_imm64, .cmp_arg16_imm16, .cmp_rdi_imm64, .cmp_rdx_rcx, .cmp_rdx_rdi, .cmp_rax_rdx, .test_eax_eax, .test_rax_rax, .test_rdx_rdx, .ucomisd, .ucomiss, .ucomisd_xmm1_xmm0, .ucomiss_xmm1_xmm0, .ucomiss_xmm0_xmm1, .cmp_arg8_imm8, .test_arg8, .test_arg32, .test_arg64 => .definition,
        .setb_eax, .seta_eax, .sete_eax, .setg_eax, .setl_eax, .setne_eax, .setbe_eax, .je, .jne, .jo, .jc, .jp, .js, .jae, .jle => .use,
        .sbb_arg64_rax, .adc_rax_imm0 => .use_and_definition,
        .set_fcmp_eax => |predicate| switch (predicate) {
            .false, .true => .preserve,
            .oeq,
            .ogt,
            .oge,
            .olt,
            .ole,
            .one,
            .ord,
            .uno,
            .ueq,
            .ugt,
            .uge,
            .ult,
            .ule,
            .une,
            => .use_and_clobber,
        },
        .binary_arg_eax, .binary_arg_rax, .imul_eax_arg32, .imul_arg64_arg64, .imul_arg64_rax, .imul_rax_arg64, .imul_rax_rsp, .mul_rax_arg64_full, .imul_rax_arg64_full, .xor_edx_edx, .div_arg32, .div_arg64, .idiv_arg64, .add_arg64_rax, .add_arg64_imm32, .add_arg_high32_eax, .add_stack_disp8_eax, .add_stack_disp8_rax, .add_stack_disp32_eax, .add_stack_disp32_rax, .add_eax_imm32, .shl_eax_imm5, .shr_eax_imm5, .sar_eax_imm5, .shr_arg_imm5, .shr_arg64_imm6, .sar_arg64_imm6, .shl_eax_cl, .shr_eax_cl, .sar_eax_cl, .shl_rax_cl, .shr_rax_cl, .sar_rax_cl, .fshl_eax_arg32_imm5, .or_eax_imm32, .imul_eax_imm32, .and_eax_imm32, .xor_eax_imm32, .rol_ax_imm8, .shr_rax_imm6, .shl_rax_imm6, .shl_rdx_imm6, .or_rdx_rax, .neg_rax, .shl_rcx_imm6, .shl_r8_imm6, .or_rcx_rax, .or_rcx_rdx, .add_rax_imm8, .add_rcx_imm32, .add_r8_rcx, .sub_r8_rcx, .add_ecx_eax, .xor_ecx_ecx, .xor_ebp_ebp, .add_rdi_rcx4_ptr_eax, .add_r8d_eax, .inc_rcx, .inc_arg_ptr_disp8, .and_edi_imm8, .sub_rsp_8, .add_rsp_8, .sub_rsp_24, .add_rsp_24, .sub_rsp_40, .add_rsp_40, .sub_rsp_56, .add_rsp_56, .sub_rsp_imm8, .sub_rsp_imm32, .add_rsp_imm8, .add_rsp_imm32, .add_arg_ptr_disp4_eax, .add_tls_i32_eax, .atomic_xadd_global_eax, .and_rsp_neg16 => .write,
        .tls_address_rax, .push_byval_tail_arg_ptr, .push_byval_tail_stack_ptr, .abs_i32_edi_eax, .abs_i64_rdi_rax, .wide_int_to_fp_rdi_rsi_xmm0, .clz_i128_rdi_rsi_eax, .clz_i64_rdi_eax, .clz_i32_edi_eax, .ctz_i32_edi_eax, .popcount_i32_edi_eax, .popcount_rax, .bit_reverse_i32_edi_eax, .bit_reverse_rax, .ushl_sat_i32_edi_imm_eax, .neg_i128_rdi_rsi_rdx_rax, .abs_limb64_rdi_rsi_dx_rcx_rax, .mulo_limb64_rdi_rsi_rdx_cl_r8w_al, .byteswap_limb64_rdi_rsi_dl_cx, .shr_limb64_rdi_rsi_dx_cl_r8w, .shlo_limb64_rdi_rsi_dx_cl_r8w_al, .not_limb64_rdi_rsi_dl_cx, .bitwise_limb64_rdi_rsi_rdx_cx, .cmp_limb64_rdi_rsi_dl_cx_ax, .overflow_limb64_rdi_rsi_rdx_cl_r8w_al, .bitreverse_limb64_rdi_rsi_dl_cx, .popcount_limb64_rdi_si_ax, .ctz_limb64_rdi_si_ax, .clz_limb64_rdi_si_ax, .udivei4_before_intbytesize, .udivei4_between_intbytesize_and_memset, .udivei4_after_memset, .umodei5_before_intbytesize, .umodei5_between_intbytesize_and_memset, .umodei5_after_memset_before_memcpy, .umodei5_after_memcpy, .ctz_i128_rdi_rsi_eax, .ctz_i64_rdi_eax, .ffs_i128_rdi_rsi_eax, .ffs_i64_rdi_eax, .ffs_i32_edi_eax, .atomic_fetch_umin_i8_rdi_sil_eax, .atomic_fetch_umin_i16_rdi_si_eax, .atomic_fetch_umin_i32_rdi_esi_eax, .atomic_fetch_umin_i64_rdi_rsi_rax, .atomic_fetch_umax_i8_rdi_sil_eax, .atomic_fetch_umax_i16_rdi_si_eax, .atomic_fetch_umax_i32_rdi_esi_eax, .atomic_fetch_umax_i64_rdi_rsi_rax, .atomic_fetch_nand_i8_rdi_sil_eax, .atomic_fetch_nand_i16_rdi_si_eax, .atomic_fetch_nand_i32_rdi_esi_eax, .atomic_fetch_nand_i64_rdi_rsi_rax, .atomic_fetch_xor_i8_rdi_sil_eax, .atomic_fetch_xor_i16_rdi_si_eax, .atomic_fetch_xor_i32_rdi_esi_eax, .atomic_fetch_xor_i64_rdi_rsi_rax, .atomic_fetch_or_i8_rdi_sil_eax, .atomic_fetch_or_i16_rdi_si_eax, .atomic_fetch_or_i32_rdi_esi_eax, .atomic_fetch_or_i64_rdi_rsi_rax, .atomic_fetch_and_i8_rdi_sil_eax, .atomic_fetch_and_i16_rdi_si_eax, .atomic_fetch_and_i32_rdi_esi_eax, .atomic_fetch_and_i64_rdi_rsi_rax, .atomic_fetch_sub_i8_rdi_sil_eax, .atomic_fetch_sub_i16_rdi_si_eax, .atomic_fetch_sub_i32_rdi_esi_eax, .atomic_fetch_sub_i64_rdi_rsi_rax, .atomic_fetch_add_i8_rdi_sil_eax, .atomic_fetch_add_i16_rdi_si_eax, .atomic_fetch_add_i32_rdi_esi_eax, .atomic_fetch_add_i64_rdi_rsi_rax, .bcmp_rdi_rsi_rdx_eax, .memcmp_rdi_rsi_rdx_eax, .memcpy_rdi_rsi_rdx_rax, .spinlocked_memcpy_rsi_to_rdx_len_edi, .spinlocked_var_cmpxchg_edi_rsi_rdx_rcx_eax, .spinlocked_var_xchg_edi_rsi_rdx_rcx, .spinlocked_var_store_edi_rsi_rdx, .cmpxchg_ptr_expected_desired_i8_eax, .cmpxchg_ptr_expected_desired_i16_eax, .cmpxchg_ptr_expected_desired_i32_eax, .cmpxchg_ptr_expected_desired_i64_eax, .spinlocked_cmpxchg_i128_rdi_rsi_rdx_rcx_eax, .xchg_ptr_value_i8_eax, .xchg_ptr_value_i16_eax, .xchg_ptr_value_i32_eax, .xchg_ptr_value_i64_rax, .atomic_xchg_rdi_disp8_rax, .spinlocked_xchg_i128_rdi_rsi_rdx_rax, .spinlocked_store_i128_rdi_rsi_rdx, .spinlocked_load_i128_rdi_rax_rdx, .spinlocked_fetch_umin_i128_rdi_rsi_rdx_rax_rdx, .spinlocked_fetch_umax_i128_rdi_rsi_rdx_rax_rdx, .spinlocked_fetch_nand_i128_rdi_rsi_rdx_rax_rdx, .spinlocked_fetch_xor_i128_rdi_rsi_rdx_rax_rdx, .spinlocked_fetch_or_i128_rdi_rsi_rdx_rax_rdx, .spinlocked_fetch_and_i128_rdi_rsi_rdx_rax_rdx, .spinlocked_fetch_sub_i128_rdi_rsi_rdx_rax_rdx, .spinlocked_fetch_add_i128_rdi_rsi_rdx_rax_rdx, .memmove_rdi_rsi_rdx_rax, .stack_probe_rax_rcx_rsp, .guarded_memset_rdi_sil_rdx_rcx_rax, .guarded_memcpy_rdi_rsi_rdx_rcx_rax, .guarded_strncat_rdi_rsi_rdx_rcx_rax, .guarded_strcat_rdi_rsi_rdx_rax, .guarded_strncpy_rdi_rsi_rdx_rcx_rax, .guarded_strcpy_rdi_rsi_rdx_rax, .memset_rdi_sil_rdx_rax, .strlen_rdi_rax, .strnlen_rdi_rsi_rax, .atomic_try_lock_rdi_al, .smin_i32_edi_esi_eax, .umin_i32_edi_esi_eax, .smax_i32_edi_esi_eax, .umax_i32_edi_esi_eax, .shift_mix_i32_edi_esi_eax, .replace_low_i8_dil_sil_al, .read_flag_i8_dil_al, .ult_i8_dil_imm8_al, .cmp_ult_u32_edi_esi_al, .ascii_range_u8_dil_imm8_imm8_al, .range_u32_edi_imm32_imm32_al, .ascii_alphabetic_dil_al, .ascii_alphanumeric_dil_al, .ascii_whitespace_dil_al, .ascii_control_dil_al, .grow_capacity_u64_rdi_imm32_rax, .oltss_xmm0_xmm1_al, .volatile_roundtrip_rdi_esi_eax, .direct_call, .indirect_call_rax, .noreturn_direct_call, .base64_raw_args_to_decode4_regs, .base64_decode4_from_table_rax, .syscall => .clobber,
        .label, .mov_imm_eax, .mov_imm_rax, .mov_imm_rdi, .mov_imm_rdx, .mov_imm_rsi, .mov_imm_rcx, .mov_imm_r8, .mov_imm_r9, .mov_rax_rdi, .mov_rax_rsi, .mov_arg_rax, .movq_xmm_rax, .movq_rax_xmm, .movd_xmm_eax, .movd_eax_xmm, .mov_arg_eax, .mov_eax_to_arg, .mov_rax_to_arg, .mov_arg_arg, .mov_arg64_arg, .mov_rsp_arg64, .movsxd_arg32_arg64, .push_arg, .pop_arg, .push_rax, .push_xmm64, .bswap_eax, .bswap_rax, .load_rdi_rcx4_ptr_r8d, .store_eax_rdi_rcx4_ptr, .load_rdi_ptr_u8_eax, .load_rdi_ptr_u16_eax, .load_rdi_ptr_eax, .load_rdi_ptr_rax, .load_rcx_ptr_u8_eax, .load_rcx_ptr_u16_eax, .load_rcx_ptr_eax, .load_rcx_ptr_rax, .store_al_rcx_ptr, .store_ax_rcx_ptr, .store_eax_rcx_ptr, .store_rax_rcx_ptr, .movzx_dil_edi, .load_rax_rdi_u8_eax, .store_imm8_abs, .mulsd_xmm1_xmm0, .mulss_xmm1_xmm0, .mulsd_xmm, .mulss_xmm, .subsd_xmm, .subss_xmm, .divsd_xmm, .divss_xmm, .addsd_xmm, .addss_xmm, .addsd_xmm1_xmm0, .addss_xmm1_xmm0, .subss_xmm1_xmm0, .divsd_xmm1_xmm0, .xorps_xmm1_xmm0, .movapd_xmm1_xmm0, .movapd_xmm, .addpd_xmm, .subpd_xmm, .mulpd_xmm, .addps_xmm, .subps_xmm, .mulps_xmm, .andps_xmm, .pxor_xmm, .pcmpgtd_xmm, .cmpeqps_xmm, .cmpeqpd_xmm, .movmskps_xmm_eax, .movmskpd_xmm_eax, .movsd_xmm, .movss_xmm, .unpcklpd_xmm, .unpckhpd_xmm, .shufpd_xmm, .unpcklps_xmm, .shufps_high_f32_to_low, .shufps_xmm, .cvtsi2ss_edi_xmm0, .cvtsi2sd_edi_xmm0, .cvtsi2ss_rdi_xmm0, .cvtsi2sd_rdi_xmm0, .cvttss2si_xmm0_eax, .cvttsd2si_xmm0_eax, .cvtsd2ss_xmm0_xmm0, .cvtss2sd_xmm0_xmm0, .cvtsd2ss_xmm, .cvtss2sd_xmm, .mov_edi_edi, .mov_imm64_xmm0, .mov_imm64_xmm1, .mov_imm32_xmm0, .mov_imm32_xmm1, .mov_imm64_xmm, .mov_imm32_xmm, .fneg_x86_fp80_stack8_st0, .fneg_fp128_xmm0, .push_imm32, .push_stack_disp8, .push_stack_disp32, .spill_arg_rsp, .spill_arg64_rsp, .reload_arg_rsp, .reload_arg64_rsp, .spill_xmm32_rsp, .reload_xmm32_rsp, .spill_xmm64_rsp, .reload_xmm64_rsp, .spill_xmm128_rsp, .reload_xmm128_rsp, .spill_xmm128ps_rsp, .reload_xmm128ps_rsp, .spill_rdi_rsi_rsp24, .reload_rdi_rsp24, .reload_rsi_rsp24, .spill_eax_rsp, .reload_rsp_eax, .spill_rax_rsp, .reload_rsp_rax, .load_stack_disp8_eax, .load_stack_disp32_eax, .load_stack_rcx4_disp8_eax, .load_stack_rcx4_disp32_eax, .load_stack_disp8_rax, .load_stack_disp32_rax, .load_stack_disp8_u8_eax, .load_stack_disp32_u8_eax, .load_stack_disp8_u16_eax, .load_stack_disp32_u16_eax, .load_stack_disp8_xmm0, .load_stack_disp32_xmm0, .load_stack_disp8_xmm0_f32, .load_stack_disp32_xmm0_f32, .load_stack_disp8_xmm, .load_stack_disp32_xmm, .load_stack_disp8_xmm_f32, .load_stack_disp32_xmm_f32, .load_stack_disp8_arg32, .load_stack_disp8_arg64, .load_stack_disp32_arg32, .load_stack_disp32_arg64, .load_rax_ptr_disp8_rax, .load_rax_ptr_disp32_rax, .load_rax_ptr_disp8_u8_eax, .load_rax_ptr_disp8_u16_eax, .load_rax_ptr_disp8_eax, .load_rax_ptr_rdx, .load_rax_ptr_eax, .load_arg_ptr_eax, .load_arg_ptr_disp8_rax, .load_arg_ptr_disp32_rax, .load_arg_ptr_disp8_eax, .load_arg_ptr_disp8_u8_eax, .load_arg_ptr_disp8_u16_eax, .load_arg_ptr_disp8_u16_arg, .load_arg_ptr_disp8_xmm, .store_eax_arg_ptr, .store_imm64_arg_ptr_disp8, .store_arg64_arg_ptr_disp8, .store_arg64_arg_ptr_disp32, .store_rax_arg_ptr_disp8, .store_rax_arg_ptr_disp32, .store_eax_arg_ptr_disp8, .store_eax_arg_ptr_disp32, .store_eax_stack_disp8, .store_eax_stack_disp32, .store_al_stack_disp8, .store_al_stack_disp32, .store_eax_stack_rcx4_disp8, .store_eax_stack_rcx4_disp32, .store_al_arg_ptr_disp8, .store_al_arg_ptr_disp32, .store_ax_arg_ptr_disp8, .store_ax_arg_ptr_disp32, .store_xmm0_arg_ptr_disp8, .store_xmm0_arg_ptr_disp32, .store_xmm0_f32_arg_ptr_disp8, .store_xmm0_f32_arg_ptr_disp32, .store_imm8_arg_ptr_disp8, .load_f128_arg_ptr_xmm0, .load_f128_const_xmm0, .load_f128_const_xmm1, .store_f128_xmm0_arg_ptr, .load_global_i32_eax, .load_global_ptr_rax, .lea_global_rax, .lea_global_offset_rax, .lea_global_rdi, .lea_global_rsi, .lea_global_rdx, .lea_global_arg64, .store_eax_global_i32, .load_tls_i32_eax, .store_eax_tls_i32, .mov_rsp_rdi, .direct_jump, .jmp, .ud2, .ret => .preserve,
    };
}

pub fn validateSemanticEffect(physical: Effect, semantic: Effect) !void {
    const compatible = switch (physical) {
        .preserve => semantic == .preserve,
        .definition => semantic == .definition,
        .use => semantic == .use,
        .use_and_definition => semantic == .use_and_definition or semantic == .use_and_clobber,
        .use_and_clobber => semantic == .use_and_clobber,
        .write => semantic == .write or semantic == .definition or semantic == .clobber,
        .clobber => semantic == .clobber,
    };
    if (!compatible) return error.EflagsSemanticEffectMismatch;
}

pub fn consumerPurpose(instruction: Instruction) ?ConsumerPurpose {
    return switch (instruction) {
        .setb_eax, .seta_eax, .setbe_eax, .jc, .jae => .carry,
        .jo => .overflow,
        .sete_eax, .setg_eax, .setl_eax, .setne_eax, .je, .jne, .jp, .js, .jle, .set_fcmp_eax => .comparison,
        else => null,
    };
}

pub fn validateInstructions(allocator: std.mem.Allocator, instructions: []const Instruction) !void {
    return validateInstructionsImpl(allocator, instructions, null);
}

pub fn validateInstructionsWithEffects(
    allocator: std.mem.Allocator,
    instructions: []const Instruction,
    effects: []const Effect,
) !void {
    if (instructions.len != effects.len) return error.EflagsEffectCountMismatch;
    return validateInstructionsImpl(allocator, instructions, effects);
}

fn validateInstructionsImpl(
    allocator: std.mem.Allocator,
    instructions: []const Instruction,
    effects: ?[]const Effect,
) !void {
    if (instructions.len == 0) return;

    const live_in = try allocator.alloc(bool, instructions.len);
    defer allocator.free(live_in);
    @memset(live_in, false);

    var changed = true;
    while (changed) {
        changed = false;
        var reverse_index = instructions.len;
        while (reverse_index != 0) {
            reverse_index -= 1;
            const live_out = try successorLive(instructions, live_in, reverse_index);
            const next_live_in = switch (effectAt(instructions, effects, reverse_index)) {
                .preserve => live_out,
                .definition, .write => false,
                .use, .use_and_definition, .use_and_clobber => true,
                .clobber => false,
            };
            if (live_in[reverse_index] != next_live_in) {
                live_in[reverse_index] = next_live_in;
                changed = true;
            }
        }
    }

    for (instructions, 0..) |_, index| {
        const live_out = try successorLive(instructions, live_in, index);
        switch (effectAt(instructions, effects, index)) {
            .clobber, .use_and_clobber => if (live_out) return error.EflagsClobberedWhileLive,
            .preserve, .definition, .use, .use_and_definition, .write => {},
        }
    }
    if (live_in[0]) return error.EflagsConsumerWithoutDefinition;

    try validateReachingDefinitions(allocator, instructions, effects);
}

fn validateReachingDefinitions(allocator: std.mem.Allocator, instructions: []const Instruction, effects: ?[]const Effect) !void {
    const reachable = try allocator.alloc(bool, instructions.len);
    defer allocator.free(reachable);
    @memset(reachable, false);
    reachable[0] = true;

    // `undefined_in` is a may-property: true means at least one reachable path
    // enters the instruction without a flags definition.  Starting at the
    // function entry and joining with OR makes loop and diamond handling
    // independent of instruction adjacency.
    const undefined_in = try allocator.alloc(bool, instructions.len);
    defer allocator.free(undefined_in);
    @memset(undefined_in, false);
    undefined_in[0] = true;

    var changed = true;
    while (changed) {
        changed = false;
        for (instructions, 0..) |_, index| {
            if (!reachable[index]) continue;
            const undefined_out = switch (effectAt(instructions, effects, index)) {
                .definition, .use_and_definition, .write => false,
                .preserve, .use => undefined_in[index],
                .use_and_clobber, .clobber => true,
            };
            try propagateToSuccessors(
                instructions,
                index,
                undefined_out,
                reachable,
                undefined_in,
                &changed,
            );
        }
    }

    for (instructions, 0..) |_, index| {
        if (!reachable[index] or !undefined_in[index]) continue;
        switch (effectAt(instructions, effects, index)) {
            .use, .use_and_definition, .use_and_clobber => return error.EflagsConsumerWithoutDefinition,
            .preserve, .definition, .write, .clobber => {},
        }
    }
}

fn effectAt(instructions: []const Instruction, effects: ?[]const Effect, index: usize) Effect {
    return if (effects) |semantic| semantic[index] else instructionEffect(instructions[index]);
}

fn successorLive(instructions: []const Instruction, live_in: []const bool, index: usize) !bool {
    const instruction = instructions[index];
    return switch (instruction) {
        .indirect_jump => |jump| blk: {
            var live = false;
            for (jump.targets) |target| live = live or live_in[try requireLabelIndex(instructions, target)];
            break :blk live;
        },
        .jmp => |target| live_in[try requireLabelIndex(instructions, target)],
        .je, .jne, .jo, .jc, .jp, .js, .jae, .jle => |target| blk: {
            const fallthrough = if (index + 1 < instructions.len) live_in[index + 1] else false;
            break :blk fallthrough or live_in[try requireLabelIndex(instructions, target)];
        },
        .ret, .ud2, .direct_jump, .noreturn_direct_call => false,
        else => if (index + 1 < instructions.len) live_in[index + 1] else false,
    };
}

fn propagateToSuccessors(
    instructions: []const Instruction,
    index: usize,
    undefined_out: bool,
    reachable: []bool,
    undefined_in: []bool,
    changed: *bool,
) !void {
    const instruction = instructions[index];
    switch (instruction) {
        .indirect_jump => |jump| for (jump.targets) |target| {
            propagate(try requireLabelIndex(instructions, target), undefined_out, reachable, undefined_in, changed);
        },
        .jmp => |target| propagate(
            try requireLabelIndex(instructions, target),
            undefined_out,
            reachable,
            undefined_in,
            changed,
        ),
        .je, .jne, .jo, .jc, .jp, .js, .jae, .jle => |target| {
            if (index + 1 < instructions.len) {
                propagate(index + 1, undefined_out, reachable, undefined_in, changed);
            }
            propagate(
                try requireLabelIndex(instructions, target),
                undefined_out,
                reachable,
                undefined_in,
                changed,
            );
        },
        .ret, .ud2, .direct_jump, .noreturn_direct_call => {},
        else => if (index + 1 < instructions.len) {
            propagate(index + 1, undefined_out, reachable, undefined_in, changed);
        },
    }
}

fn propagate(
    successor: usize,
    undefined_out: bool,
    reachable: []bool,
    undefined_in: []bool,
    changed: *bool,
) void {
    if (!reachable[successor]) {
        reachable[successor] = true;
        changed.* = true;
    }
    if (undefined_out and !undefined_in[successor]) {
        undefined_in[successor] = true;
        changed.* = true;
    }
}

fn requireLabelIndex(instructions: []const Instruction, name: []const u8) !usize {
    return labelIndex(instructions, name) orelse error.EflagsUnknownBranchTarget;
}

fn labelIndex(instructions: []const Instruction, name: []const u8) ?usize {
    for (instructions, 0..) |instruction, index| switch (instruction) {
        .label => |label| if (std.mem.eql(u8, label, name)) return index,
        else => {},
    };
    return null;
}
