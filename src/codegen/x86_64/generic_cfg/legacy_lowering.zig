const std = @import("std");
const machine_model = @import("../machine.zig");
const forms = @import("legacy_forms.zig");

pub fn lower(
    allocator: std.mem.Allocator,
    machine: *machine_model.MachineFunction,
    form: forms.Form,
) !void {
    switch (form) {
        .multiply_overflow => {
            try machine.instructions.append(allocator, .mulo_limb64_rdi_rsi_rdx_cl_r8w_al);
        },
        .byte_swap => {
            try machine.instructions.append(allocator, .byteswap_limb64_rdi_rsi_dl_cx);
        },
        .shift_right => {
            try machine.instructions.append(allocator, .shr_limb64_rdi_rsi_dx_cl_r8w);
        },
        .shift_left_overflow => {
            try machine.instructions.append(allocator, .shlo_limb64_rdi_rsi_dx_cl_r8w_al);
        },
        .bit_not => {
            try machine.instructions.append(allocator, .not_limb64_rdi_rsi_dl_cx);
        },
        .bitwise => |op| {
            try machine.instructions.append(allocator, .{ .bitwise_limb64_rdi_rsi_rdx_cx = op });
        },
        .compare => {
            try machine.instructions.append(allocator, .cmp_limb64_rdi_rsi_dl_cx_ax);
        },
        .overflow => |op| {
            try machine.instructions.append(allocator, .{ .overflow_limb64_rdi_rsi_rdx_cl_r8w_al = op });
        },
        .bit_reverse => {
            try machine.instructions.append(allocator, .bitreverse_limb64_rdi_rsi_dl_cx);
        },
        .population_count => {
            try machine.instructions.append(allocator, .popcount_limb64_rdi_si_ax);
        },
        .trailing_zeroes => {
            try machine.instructions.append(allocator, .ctz_limb64_rdi_si_ax);
        },
        .leading_zeroes => {
            try machine.instructions.append(allocator, .clz_limb64_rdi_si_ax);
        },
        .divide => {
            try machine.instructions.append(allocator, .udivei4_before_intbytesize);
            try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "zig.target.intByteSize", .ret_ty = .{ .int = 16 } } });
            try machine.instructions.append(allocator, .udivei4_between_intbytesize_and_memset);
            try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "memset", .ret_ty = .ptr } });
            try machine.instructions.append(allocator, .udivei4_after_memset);
        },
        .remainder => {
            try machine.instructions.append(allocator, .umodei5_before_intbytesize);
            try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "zig.target.intByteSize", .ret_ty = .{ .int = 16 } } });
            try machine.instructions.append(allocator, .umodei5_between_intbytesize_and_memset);
            try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "memset", .ret_ty = .ptr } });
            try machine.instructions.append(allocator, .umodei5_after_memset_before_memcpy);
            try machine.instructions.append(allocator, .{ .direct_jump = "memcpy" });
            try machine.instructions.append(allocator, .umodei5_after_memcpy);
        },
        .pointer_bitwise => |plan| {
            try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_rax = .{ .reg = .rdi, .offset = plan.offset } });
            try machine.instructions.append(allocator, .{ .mov_imm_rcx = plan.mask });
            try machine.instructions.append(allocator, .{ .binary_arg_rax = .{ .op = plan.op, .reg = .rcx } });
            try machine.instructions.append(allocator, .{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = plan.offset } });
            try machine.instructions.append(allocator, .ret);
        },
        .pointer_increment => |plan| {
            try machine.instructions.append(allocator, .{ .inc_arg_ptr_disp8 = .{ .reg = .rdi, .offset = plan.offset } });
            try machine.instructions.append(allocator, .ret);
        },
        .pointer_copy => |plan| {
            if (plan.bits == 64) {
                try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_rax = .{ .reg = .rdi, .offset = plan.src_offset } });
                try machine.instructions.append(allocator, .{ .store_rax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = plan.dst_offset } });
            } else if (plan.bits == 32) {
                try machine.instructions.append(allocator, .{ .load_arg_ptr_disp8_eax = .{ .reg = .rdi, .offset = plan.src_offset } });
                try machine.instructions.append(allocator, .{ .store_eax_arg_ptr_disp8 = .{ .reg = .rdi, .offset = plan.dst_offset } });
            } else return error.UnsupportedLegacyForm;
            try machine.instructions.append(allocator, .ret);
        },
    }
}
