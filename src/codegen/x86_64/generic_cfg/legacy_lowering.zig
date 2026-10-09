const std = @import("std");
const ir = @import("../../../ir.zig");
const machine_model = @import("../machine.zig");
const legacy_envelopes = @import("legacy_envelopes.zig");

pub fn tryLower(
    allocator: std.mem.Allocator,
    machine: *machine_model.MachineFunction,
    function: ir.Function,
) !bool {
    if (legacy_envelopes.matchesMuloLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .mulo_limb64_rdi_rsi_rdx_cl_r8w_al);
        return true;
    }
    if (legacy_envelopes.matchesByteswapLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .byteswap_limb64_rdi_rsi_dl_cx);
        return true;
    }
    if (legacy_envelopes.matchesShrLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .shr_limb64_rdi_rsi_dx_cl_r8w);
        return true;
    }
    if (legacy_envelopes.matchesShloLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .shlo_limb64_rdi_rsi_dx_cl_r8w_al);
        return true;
    }
    if (legacy_envelopes.matchesNotLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .not_limb64_rdi_rsi_dl_cx);
        return true;
    }
    if (legacy_envelopes.matchesBitwiseLimb64Envelope(function)) |op| {
        try machine.instructions.append(allocator, .{ .bitwise_limb64_rdi_rsi_rdx_cx = op });
        return true;
    }
    if (legacy_envelopes.matchesCmpLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .cmp_limb64_rdi_rsi_dl_cx_ax);
        return true;
    }
    if (legacy_envelopes.matchesOverflowLimb64Envelope(function)) |op| {
        try machine.instructions.append(allocator, .{ .overflow_limb64_rdi_rsi_rdx_cl_r8w_al = op });
        return true;
    }
    if (legacy_envelopes.matchesBitreverseLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .bitreverse_limb64_rdi_rsi_dl_cx);
        return true;
    }
    if (legacy_envelopes.matchesPopcountLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .popcount_limb64_rdi_si_ax);
        return true;
    }
    if (legacy_envelopes.matchesCtzLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .ctz_limb64_rdi_si_ax);
        return true;
    }
    if (legacy_envelopes.matchesClzLimb64Envelope(function)) {
        try machine.instructions.append(allocator, .clz_limb64_rdi_si_ax);
        return true;
    }
    if (legacy_envelopes.matchesUdivei4Envelope(function)) {
        try machine.instructions.append(allocator, .udivei4_before_intbytesize);
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "zig.target.intByteSize", .ret_ty = .{ .int = 16 } } });
        try machine.instructions.append(allocator, .udivei4_between_intbytesize_and_memset);
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "memset", .ret_ty = .ptr } });
        try machine.instructions.append(allocator, .udivei4_after_memset);
        return true;
    }
    if (legacy_envelopes.matchesUmodei5Envelope(function)) {
        try machine.instructions.append(allocator, .umodei5_before_intbytesize);
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "zig.target.intByteSize", .ret_ty = .{ .int = 16 } } });
        try machine.instructions.append(allocator, .umodei5_between_intbytesize_and_memset);
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "memset", .ret_ty = .ptr } });
        try machine.instructions.append(allocator, .umodei5_after_memset_before_memcpy);
        try machine.instructions.append(allocator, .{ .direct_jump = "memcpy" });
        try machine.instructions.append(allocator, .umodei5_after_memcpy);
        return true;
    }
    if (legacy_envelopes.matchesPointerOffsetBitwiseRmwEnvelope(function)) |plan| {
        try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_rax = .{ .reg = .rdi, .offset = plan.offset } });
        try machine.instructions.append(allocator, .{ .mov_imm_rcx = plan.mask });
        try machine.instructions.append(allocator, .{ .binary_arg_rax = .{ .op = plan.op, .reg = .rcx } });
        try machine.instructions.append(allocator, .{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = plan.offset } });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
}
