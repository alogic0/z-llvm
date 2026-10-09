const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const types = @import("../types.zig");

pub fn matchesMuloLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 1 })) return false;
    if (function.params.items.len != 5) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.ptr)) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[4].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_uadd_overflow = false;
    var saw_usub_overflow = false;
    var overflow_extracts: usize = 0;
    var mul_i64_count: usize = 0;
    var result_i64_stores: usize = 0;
    var i8_allocas: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .alloca => |alloca| {
                    if (alloca.allocated_ty.eql(.{ .int = 8 })) i8_allocas += 1;
                },
                .binary => |binary| {
                    if (binary.op == .mul and binary.ty.eql(.{ .int = 64 })) mul_i64_count += 1;
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    }
                    if (std.mem.eql(u8, call.callee, "llvm.uadd.with.overflow.i64")) saw_uadd_overflow = true;
                    if (std.mem.eql(u8, call.callee, "llvm.usub.with.overflow.i64")) saw_usub_overflow = true;
                },
                .extractvalue => |extract| {
                    if (extract.aggregate_ty.eql(.{ .aggregate = "{ i64, i1 }" })) overflow_extracts += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) result_i64_stores += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_uadd_overflow and
        saw_usub_overflow and
        overflow_extracts >= 4 and
        mul_i64_count >= 4 and
        result_i64_stores >= 2 and
        i8_allocas >= 1;
}

pub fn matchesByteswapLimb64Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 16 })) return false;

    var saw_freeze_bits = false;
    var saw_int_byte_size = false;
    var saw_assume = false;
    var saw_bswap_i64 = false;
    var saw_limb_count_math = false;
    var saw_remainder_mask = false;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .freeze => |freeze| {
                    if (freeze.ty.eql(.{ .int = 16 })) saw_freeze_bits = true;
                },
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add) saw_limb_count_math = true;
                        if (binary.op == .lshr) saw_limb_count_math = true;
                        if (binary.op == .@"and") saw_remainder_mask = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.assume") and call.ret_ty == .void) {
                        saw_assume = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.bswap.i64") and
                        call.ret_ty.eql(.{ .int = 64 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 64 }))
                    {
                        saw_bswap_i64 = true;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    return saw_freeze_bits and
        saw_int_byte_size and
        saw_assume and
        saw_bswap_i64 and
        saw_limb_count_math and
        saw_remainder_mask and
        i64_loads >= 1 and
        i64_stores >= 1;
}

pub fn matchesShrLimb64Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 5) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 16 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[4].ty.eql(.{ .int = 16 })) return false;

    var saw_freeze_shift = false;
    var saw_int_byte_size = false;
    var saw_assume = false;
    var saw_shift_assert = false;
    var saw_limb_count_math = false;
    var saw_shift_decompose = false;
    var saw_sign_select = false;
    var saw_lshr_i64 = false;
    var saw_shl_i64 = false;
    var saw_or_i64 = false;
    var saw_fix_sign_extend = false;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .freeze => |freeze| {
                    if (freeze.ty.eql(.{ .int = 16 })) saw_freeze_shift = true;
                },
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add) saw_limb_count_math = true;
                        if (binary.op == .lshr) {
                            saw_limb_count_math = true;
                            saw_shift_decompose = true;
                        }
                        if (binary.op == .@"and") saw_shift_decompose = true;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .lshr) saw_lshr_i64 = true;
                        if (binary.op == .shl) saw_shl_i64 = true;
                        if (binary.op == .@"or") saw_or_i64 = true;
                        if (binary.op == .ashr) saw_fix_sign_extend = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.assume") and call.ret_ty == .void) {
                        saw_assume = true;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.operand_ty.eql(.{ .int = 16 }) and icmp.predicate == .ult) saw_shift_assert = true;
                },
                .select => |select| {
                    if (select.cond_ty.eql(.{ .int = 1 }) and select.ty.eql(.{ .int = 1 })) saw_sign_select = true;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    return saw_freeze_shift and
        saw_int_byte_size and
        saw_assume and
        saw_shift_assert and
        saw_limb_count_math and
        saw_shift_decompose and
        saw_sign_select and
        saw_lshr_i64 and
        saw_shl_i64 and
        saw_or_i64 and
        saw_fix_sign_extend and
        i64_loads >= 2 and
        i64_stores >= 2;
}

pub fn matchesShloLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 1 })) return false;
    if (function.params.items.len != 5) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 16 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[4].ty.eql(.{ .int = 16 })) return false;

    var saw_freeze_shift = false;
    var saw_int_byte_size = false;
    var saw_assume = false;
    var saw_shift_assert = false;
    var saw_limb_count_math = false;
    var saw_shift_decompose = false;
    var saw_left_shift = false;
    var saw_carry_shift = false;
    var saw_or_chain = false;
    var saw_tail_mask = false;
    var saw_tail_sign_extend = false;
    var saw_tail_wrap_select = false;
    var saw_expected_carry = false;
    var saw_overflow_compare = false;
    var saw_overflow_select = false;
    var saw_return_i1 = false;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .freeze => |freeze| {
                    if (freeze.ty.eql(.{ .int = 16 })) saw_freeze_shift = true;
                },
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add) saw_limb_count_math = true;
                        if (binary.op == .lshr) {
                            saw_limb_count_math = true;
                            saw_shift_decompose = true;
                        }
                        if (binary.op == .@"and") saw_shift_decompose = true;
                        if (binary.op == .sub) saw_shift_decompose = true;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .shl) saw_left_shift = true;
                        if (binary.op == .lshr) {
                            saw_carry_shift = true;
                            saw_tail_mask = true;
                            saw_expected_carry = true;
                        }
                        if (binary.op == .@"or") saw_or_chain = true;
                        if (binary.op == .@"and") saw_tail_mask = true;
                        if (binary.op == .ashr) saw_tail_sign_extend = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.assume") and call.ret_ty == .void) {
                        saw_assume = true;
                    }
                },
                .cast => |cast| {
                    if (cast.op == .sext and cast.from_ty.eql(.{ .int = 1 }) and cast.to_ty.eql(.{ .int = 64 })) {
                        saw_expected_carry = true;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.operand_ty.eql(.{ .int = 16 }) and icmp.predicate == .ult) saw_shift_assert = true;
                    if (icmp.operand_ty.eql(.{ .int = 64 }) and icmp.predicate == .ne) saw_overflow_compare = true;
                    if (icmp.operand_ty.eql(.{ .int = 64 }) and icmp.predicate == .slt) saw_expected_carry = true;
                },
                .select => |select| {
                    if (select.cond_ty.eql(.{ .int = 1 }) and select.ty.eql(.{ .int = 64 })) saw_tail_wrap_select = true;
                    if (select.cond_ty.eql(.{ .int = 1 }) and select.ty.eql(.{ .int = 1 })) saw_overflow_select = true;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
        if (block.terminator) |terminator| {
            switch (terminator) {
                .ret => |ret| {
                    if (ret.ty.eql(.{ .int = 1 }) and ret.value != null) saw_return_i1 = true;
                },
                else => {},
            }
        }
    }

    return saw_freeze_shift and
        saw_int_byte_size and
        saw_assume and
        saw_shift_assert and
        saw_limb_count_math and
        saw_shift_decompose and
        saw_left_shift and
        saw_carry_shift and
        saw_or_chain and
        saw_tail_mask and
        saw_tail_sign_extend and
        saw_tail_wrap_select and
        saw_expected_carry and
        saw_overflow_compare and
        saw_overflow_select and
        saw_return_i1 and
        i64_loads >= 3 and
        i64_stores >= 2;
}

pub fn matchesBitreverseLimb64Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 16 })) return false;

    var saw_freeze_bits = false;
    var saw_int_byte_size = false;
    var saw_umax = false;
    var saw_bitreverse_i64 = false;
    var saw_limb_count_math = false;
    var saw_remainder_mask = false;
    var saw_tail_shift = false;
    var saw_fix_sign_extend = false;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .freeze => |freeze| {
                    if (freeze.ty.eql(.{ .int = 16 })) saw_freeze_bits = true;
                },
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr) saw_limb_count_math = true;
                        if (binary.op == .@"and") saw_remainder_mask = true;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .lshr or binary.op == .shl or binary.op == .@"or") saw_tail_shift = true;
                        if (binary.op == .ashr) saw_fix_sign_extend = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.umax.i64") and
                        call.ret_ty.eql(.{ .int = 64 }))
                    {
                        saw_umax = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.bitreverse.i64") and
                        call.ret_ty.eql(.{ .int = 64 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 64 }))
                    {
                        saw_bitreverse_i64 = true;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    return saw_freeze_bits and
        saw_int_byte_size and
        saw_umax and
        saw_bitreverse_i64 and
        saw_limb_count_math and
        saw_remainder_mask and
        saw_tail_shift and
        saw_fix_sign_extend and
        i64_loads >= 2 and
        i64_stores >= 2;
}

pub fn matchesNotLimb64Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_assume = false;
    var saw_limb_count_math = false;
    var saw_limb_count_select = false;
    var saw_unary_not = false;
    var saw_partial_unsigned_mask = false;
    var saw_signed_high_fill = false;
    var saw_fix_last_limb_compare = false;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr) saw_limb_count_math = true;
                        if (binary.op == .@"and" or binary.op == .sub) saw_partial_unsigned_mask = true;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .xor and (binary.rhs.eql(.{ .int = -1 }) or binary.lhs.eql(.{ .int = -1 }))) {
                            saw_unary_not = true;
                        }
                        if (binary.op == .lshr or binary.op == .@"and") saw_partial_unsigned_mask = true;
                        if (binary.op == .ashr) saw_signed_high_fill = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.assume") and call.ret_ty == .void) {
                        saw_assume = true;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.operand_ty.eql(.{ .int = 16 })) saw_fix_last_limb_compare = true;
                    if (icmp.operand_ty.eql(.{ .int = 64 }) and icmp.predicate == .slt) saw_signed_high_fill = true;
                },
                .select => |select| {
                    if (select.cond_ty.eql(.{ .int = 1 }) and select.ty.eql(.{ .int = 16 })) saw_limb_count_select = true;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_assume and
        saw_limb_count_math and
        saw_limb_count_select and
        saw_unary_not and
        saw_partial_unsigned_mask and
        saw_signed_high_fill and
        saw_fix_last_limb_compare and
        i64_loads >= 2 and
        i64_stores >= 2;
}

pub fn matchesBitwiseLimb64Envelope(function: ir.Function) ?x86_64_machine.Limb64BitwiseOp {
    if (function.ret_ty != .void) return null;
    if (function.params.items.len != 4) return null;
    if (!function.params.items[0].ty.eql(.ptr)) return null;
    if (!function.params.items[1].ty.eql(.ptr)) return null;
    if (!function.params.items[2].ty.eql(.ptr)) return null;
    if (!function.params.items[3].ty.eql(.{ .int = 16 })) return null;

    var saw_int_byte_size = false;
    var saw_umax = false;
    var saw_assume = false;
    var saw_limb_count_math = false;
    var saw_unroll_remainder = false;
    var xor_i64_count: usize = 0;
    var or_i64_count: usize = 0;
    var and_i64_count: usize = 0;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .lshr) saw_limb_count_math = true;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        switch (binary.op) {
                            .xor => xor_i64_count += 1,
                            .@"or" => or_i64_count += 1,
                            .@"and" => {
                                and_i64_count += 1;
                                saw_unroll_remainder = true;
                            },
                            else => {},
                        }
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.umax.i16") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 2)
                    {
                        saw_umax = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.assume") and call.ret_ty == .void) {
                        saw_assume = true;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    if (!saw_int_byte_size or
        !saw_umax or
        !saw_assume or
        !saw_limb_count_math or
        !saw_unroll_remainder or
        i64_loads < 4 or
        i64_stores < 2)
    {
        return null;
    }

    if (xor_i64_count >= 2) return .xor;
    if (and_i64_count >= 2) return .@"and";
    if (or_i64_count >= 2) return .@"or";
    return null;
}

pub fn matchesCmpLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 8 })) return false;
    if (function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.{ .int = 1 })) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_limb_count_math = false;
    var saw_limb_count_select = false;
    var saw_reverse_index_sub = false;
    var saw_signed_less = false;
    var saw_signed_greater = false;
    var saw_unsigned_less = false;
    var saw_unsigned_greater = false;
    var i64_loads: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr) saw_limb_count_math = true;
                    } else if (binary.ty.eql(.{ .int = 64 }) and binary.op == .sub) {
                        saw_reverse_index_sub = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.operand_ty.eql(.{ .int = 64 })) {
                        switch (icmp.predicate) {
                            .slt => saw_signed_less = true,
                            .sgt => saw_signed_greater = true,
                            .ult => saw_unsigned_less = true,
                            .ugt => saw_unsigned_greater = true,
                            else => {},
                        }
                    }
                },
                .select => |select| {
                    if (select.cond_ty.eql(.{ .int = 1 }) and select.ty.eql(.{ .int = 16 })) {
                        saw_limb_count_select = true;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_limb_count_math and
        saw_limb_count_select and
        saw_reverse_index_sub and
        saw_signed_less and
        saw_signed_greater and
        saw_unsigned_less and
        saw_unsigned_greater and
        i64_loads >= 4;
}

pub fn matchesOverflowLimb64Envelope(function: ir.Function) ?x86_64_machine.Limb64OverflowOp {
    if (!function.ret_ty.eql(.{ .int = 1 })) return null;
    if (function.params.items.len != 5) return null;
    if (!function.params.items[0].ty.eql(.ptr)) return null;
    if (!function.params.items[1].ty.eql(.ptr)) return null;
    if (!function.params.items[2].ty.eql(.ptr)) return null;
    if (!function.params.items[3].ty.eql(.{ .int = 1 })) return null;
    if (!function.params.items[4].ty.eql(.{ .int = 16 })) return null;

    var saw_int_byte_size = false;
    var saw_limb_count_math = false;
    var saw_limb_count_select = false;
    var saw_partial_limb_wrap = false;
    var saw_fix_last_limb_fill = false;
    var uadd_overflow_count: usize = 0;
    var sadd_overflow_count: usize = 0;
    var usub_overflow_count: usize = 0;
    var ssub_overflow_count: usize = 0;
    var i64_loads: usize = 0;
    var i64_stores: usize = 0;
    var i1_allocas: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .alloca => |alloca| {
                    if (alloca.allocated_ty.eql(.{ .int = 8 }) or alloca.allocated_ty.eql(.{ .int = 1 })) {
                        i1_allocas += 1;
                    }
                },
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr or binary.op == .@"and") saw_limb_count_math = true;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .shl or binary.op == .ashr or binary.op == .lshr) saw_partial_limb_wrap = true;
                        if (binary.op == .sub) saw_fix_last_limb_fill = true;
                    } else if (binary.ty.eql(.{ .int = 8 }) and binary.op == .@"or") {
                        saw_limb_count_math = true;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.uadd.with.overflow.i64")) {
                        uadd_overflow_count += 1;
                    } else if (std.mem.eql(u8, call.callee, "llvm.sadd.with.overflow.i64")) {
                        sadd_overflow_count += 1;
                    } else if (std.mem.eql(u8, call.callee, "llvm.usub.with.overflow.i64")) {
                        usub_overflow_count += 1;
                    } else if (std.mem.eql(u8, call.callee, "llvm.ssub.with.overflow.i64")) {
                        ssub_overflow_count += 1;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.operand_ty.eql(.{ .int = 16 })) saw_limb_count_math = true;
                },
                .select => |select| {
                    if (select.cond_ty.eql(.{ .int = 1 }) and select.ty.eql(.{ .int = 16 })) {
                        saw_limb_count_select = true;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 64 })) i64_stores += 1;
                },
                else => {},
            }
        }
    }

    if (!saw_int_byte_size or
        !saw_limb_count_math or
        !saw_limb_count_select or
        !saw_partial_limb_wrap or
        !saw_fix_last_limb_fill or
        i64_loads < 4 or
        i64_stores < 2 or
        i1_allocas < 1)
    {
        return null;
    }

    if (uadd_overflow_count >= 4 and sadd_overflow_count >= 2 and usub_overflow_count == 0 and ssub_overflow_count == 0) {
        return .add;
    }
    if (usub_overflow_count >= 4 and ssub_overflow_count >= 2 and uadd_overflow_count == 0 and sadd_overflow_count == 0) {
        return .sub;
    }
    return null;
}

pub fn matchesPopcountLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 16 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_limb_count_math = false;
    var saw_remainder_mask = false;
    var saw_tail_shift = false;
    var ctpop_i64_count: usize = 0;
    var trunc_i64_to_i16_count: usize = 0;
    var add_i16_count: usize = 0;
    var i64_loads: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr) saw_limb_count_math = true;
                        if (binary.op == .@"and") saw_remainder_mask = true;
                        if (binary.op == .add) add_i16_count += 1;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .shl) saw_tail_shift = true;
                    }
                },
                .cast => |cast| {
                    if (cast.op == .trunc and
                        cast.from_ty.eql(.{ .int = 64 }) and
                        cast.to_ty.eql(.{ .int = 16 }))
                    {
                        trunc_i64_to_i16_count += 1;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.ctpop.i64") and
                        call.ret_ty.eql(.{ .int = 64 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 64 }))
                    {
                        ctpop_i64_count += 1;
                    }
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_limb_count_math and
        saw_remainder_mask and
        saw_tail_shift and
        ctpop_i64_count >= 2 and
        trunc_i64_to_i16_count >= 2 and
        add_i16_count >= 2 and
        i64_loads >= 2;
}

pub fn matchesCtzLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 16 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_limb_count_math = false;
    var saw_remainder_mask = false;
    var saw_zero_limb_branch = false;
    var cttz_i64_count: usize = 0;
    var trunc_i64_to_i16_count: usize = 0;
    var add_i16_count: usize = 0;
    var or_i16_count: usize = 0;
    var i64_loads: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr or binary.op == .shl) saw_limb_count_math = true;
                        if (binary.op == .@"and") saw_remainder_mask = true;
                        if (binary.op == .add) add_i16_count += 1;
                        if (binary.op == .@"or") or_i16_count += 1;
                    }
                },
                .cast => |cast| {
                    if (cast.op == .trunc and
                        cast.from_ty.eql(.{ .int = 64 }) and
                        cast.to_ty.eql(.{ .int = 16 }))
                    {
                        trunc_i64_to_i16_count += 1;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.cttz.i64") and
                        call.ret_ty.eql(.{ .int = 64 }) and call.args.items.len == 2 and
                        call.args.items[0].ty.eql(.{ .int = 64 }) and
                        call.args.items[1].ty.eql(.{ .int = 1 }))
                    {
                        cttz_i64_count += 1;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.predicate == .eq and icmp.operand_ty.eql(.{ .int = 64 })) saw_zero_limb_branch = true;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_limb_count_math and
        saw_remainder_mask and
        saw_zero_limb_branch and
        cttz_i64_count >= 2 and
        trunc_i64_to_i16_count >= 2 and
        add_i16_count >= 2 and
        or_i16_count >= 1 and
        i64_loads >= 2;
}

pub fn matchesClzLimb64Envelope(function: ir.Function) bool {
    if (!function.ret_ty.eql(.{ .int = 16 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.{ .int = 16 })) return false;

    var saw_int_byte_size = false;
    var saw_limb_count_math = false;
    var saw_remainder_mask = false;
    var saw_zero_limb_branch = false;
    var saw_reverse_index_sub = false;
    var saw_partial_shift = false;
    var ctlz_i64_count: usize = 0;
    var trunc_i64_to_i16_count: usize = 0;
    var add_i16_count: usize = 0;
    var i64_loads: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (binary.ty.eql(.{ .int = 16 })) {
                        if (binary.op == .add or binary.op == .lshr) saw_limb_count_math = true;
                        if (binary.op == .@"and") saw_remainder_mask = true;
                        if (binary.op == .add) add_i16_count += 1;
                    } else if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .sub) saw_reverse_index_sub = true;
                        if (binary.op == .shl) saw_partial_shift = true;
                    }
                },
                .cast => |cast| {
                    if (cast.op == .trunc and
                        cast.from_ty.eql(.{ .int = 64 }) and
                        cast.to_ty.eql(.{ .int = 16 }))
                    {
                        trunc_i64_to_i16_count += 1;
                    }
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.ctlz.i64") and
                        call.ret_ty.eql(.{ .int = 64 }) and call.args.items.len == 2 and
                        call.args.items[0].ty.eql(.{ .int = 64 }) and
                        call.args.items[1].ty.eql(.{ .int = 1 }))
                    {
                        ctlz_i64_count += 1;
                    }
                },
                .icmp => |icmp| {
                    if (icmp.predicate == .eq and icmp.operand_ty.eql(.{ .int = 64 })) saw_zero_limb_branch = true;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 64 })) i64_loads += 1;
                },
                else => {},
            }
        }
    }

    return saw_int_byte_size and
        saw_limb_count_math and
        saw_remainder_mask and
        saw_zero_limb_branch and
        saw_reverse_index_sub and
        saw_partial_shift and
        ctlz_i64_count >= 2 and
        trunc_i64_to_i16_count >= 2 and
        add_i16_count >= 2 and
        i64_loads >= 2;
}

pub fn matchesUdivei4Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 4) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.ptr)) return false;
    if (!function.params.items[3].ty.eql(.{ .int = 64 })) return false;

    var saw_un: bool = false;
    var saw_vn: bool = false;
    var saw_int_byte_size = false;
    var saw_ctlz_i32 = false;
    var saw_udiv_i64 = false;
    var saw_urem_i64 = false;
    var saw_limb_count_lshr_i16 = false;
    var saw_byte_count_shl_i64 = false;
    var aggregate_allocas: usize = 0;
    var other_allocas: usize = 0;
    var i32_stores: usize = 0;
    var i32_loads: usize = 0;
    var u64_from_i32_exts: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .alloca => |alloca| switch (alloca.allocated_ty) {
                    .aggregate => |text| {
                        aggregate_allocas += 1;
                        if (std.mem.eql(u8, text, "[2049 x i32]")) saw_un = true;
                        if (std.mem.eql(u8, text, "[2048 x i32]")) saw_vn = true;
                    },
                    else => other_allocas += 1,
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.ctlz.i32") and
                        call.ret_ty.eql(.{ .int = 32 }) and call.args.items.len == 2 and
                        call.args.items[0].ty.eql(.{ .int = 32 }) and
                        call.args.items[1].ty.eql(.{ .int = 1 }))
                    {
                        saw_ctlz_i32 = true;
                    }
                },
                .binary => |binary| {
                    if (binary.op == .lshr and binary.ty.eql(.{ .int = 16 })) {
                        saw_limb_count_lshr_i16 = true;
                    }
                    if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .udiv) saw_udiv_i64 = true;
                        if (binary.op == .urem) saw_urem_i64 = true;
                        if (binary.op == .shl) saw_byte_count_shl_i64 = true;
                    }
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 32 })) i32_stores += 1;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 32 })) i32_loads += 1;
                },
                .cast => |cast| {
                    if (cast.op == .zext and
                        cast.from_ty.eql(.{ .int = 32 }) and
                        cast.to_ty.eql(.{ .int = 64 }))
                    {
                        u64_from_i32_exts += 1;
                    }
                },
                else => {},
            }
        }
    }

    return saw_un and
        saw_vn and
        aggregate_allocas == 2 and
        other_allocas == 0 and
        saw_int_byte_size and
        saw_ctlz_i32 and
        saw_udiv_i64 and
        saw_urem_i64 and
        saw_limb_count_lshr_i16 and
        saw_byte_count_shl_i64 and
        i32_stores >= 8 and
        i32_loads >= 8 and
        u64_from_i32_exts >= 2;
}

pub fn matchesUmodei5Envelope(function: ir.Function) bool {
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 5) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (!function.params.items[1].ty.eql(.ptr)) return false;
    if (!function.params.items[2].ty.eql(.ptr)) return false;
    if (!function.params.items[3].ty.eql(.ptr)) return false;
    if (!function.params.items[4].ty.eql(.{ .int = 64 })) return false;

    var saw_un: bool = false;
    var saw_vn: bool = false;
    var saw_int_byte_size = false;
    var saw_ctlz_i32 = false;
    var saw_inline_memcpy = false;
    var saw_udiv_i64 = false;
    var saw_urem_i64 = false;
    var saw_lshr_i16 = false;
    var saw_limb_count_lshr_i64 = false;
    var aggregate_allocas: usize = 0;
    var other_allocas: usize = 0;
    var i32_stores: usize = 0;
    var i32_loads: usize = 0;
    var u64_from_i32_exts: usize = 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .alloca => |alloca| switch (alloca.allocated_ty) {
                    .aggregate => |text| {
                        aggregate_allocas += 1;
                        if (std.mem.eql(u8, text, "[2049 x i32]")) saw_un = true;
                        if (std.mem.eql(u8, text, "[2048 x i32]")) saw_vn = true;
                    },
                    else => other_allocas += 1,
                },
                .call => |call| {
                    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize") and
                        call.ret_ty.eql(.{ .int = 16 }) and call.args.items.len == 1 and
                        call.args.items[0].ty.eql(.{ .int = 16 }))
                    {
                        saw_int_byte_size = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.ctlz.i32") and
                        call.ret_ty.eql(.{ .int = 32 }) and call.args.items.len == 2 and
                        call.args.items[0].ty.eql(.{ .int = 32 }) and
                        call.args.items[1].ty.eql(.{ .int = 1 }))
                    {
                        saw_ctlz_i32 = true;
                    } else if (std.mem.eql(u8, call.callee, "llvm.memcpy.inline.p0.p0.i64")) {
                        saw_inline_memcpy = true;
                    }
                },
                .binary => |binary| {
                    if (binary.op == .lshr and binary.ty.eql(.{ .int = 16 })) saw_lshr_i16 = true;
                    if (binary.ty.eql(.{ .int = 64 })) {
                        if (binary.op == .udiv) saw_udiv_i64 = true;
                        if (binary.op == .urem) saw_urem_i64 = true;
                        if (binary.op == .lshr) saw_limb_count_lshr_i64 = true;
                    }
                },
                .store => |store| {
                    if (store.ty.eql(.{ .int = 32 })) i32_stores += 1;
                },
                .load => |load| {
                    if (load.ty.eql(.{ .int = 32 })) i32_loads += 1;
                },
                .cast => |cast| {
                    if (cast.op == .zext and
                        cast.from_ty.eql(.{ .int = 32 }) and
                        cast.to_ty.eql(.{ .int = 64 }))
                    {
                        u64_from_i32_exts += 1;
                    }
                },
                else => {},
            }
        }
    }

    return saw_un and
        saw_vn and
        aggregate_allocas == 2 and
        other_allocas == 0 and
        saw_int_byte_size and
        saw_ctlz_i32 and
        saw_inline_memcpy and
        saw_udiv_i64 and
        saw_urem_i64 and
        !saw_lshr_i16 and
        saw_limb_count_lshr_i64 and
        i32_stores >= 8 and
        i32_loads >= 8 and
        u64_from_i32_exts >= 2;
}

pub const PointerOffsetBitwiseRmw = struct {
    offset: u8,
    op: types.MachineBinaryOp,
    mask: i64,
};

pub fn matchesPointerOffsetBitwiseRmwEnvelope(function: ir.Function) ?PointerOffsetBitwiseRmw {
    if (function.ret_ty != .void or function.params.items.len != 1) return null;
    if (!function.params.items[0].ty.eql(.ptr) or function.blocks.items.len != 1) return null;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (ret.ty != .void or ret.value != null) return null;

    var gep_offset: u8 = 0;
    var gep_result: ?[]const u8 = null;
    var load_result: ?[]const u8 = null;
    var binary_op: ?types.MachineBinaryOp = null;
    var binary_result: ?[]const u8 = null;
    var binary_mask: ?i64 = null;
    var store_val: ?[]const u8 = null;
    var store_ptr: ?[]const u8 = null;

    for (block.instructions.items) |inst| {
        if (inst.removed) continue;
        switch (inst.kind) {
            .gep => |gep| {
                if (gep.source_ty.eql(.{ .int = 8 }) and gep.indices.items.len == 1) {
                    switch (gep.indices.items[0].value) {
                        .int => |val| {
                            if (val >= 0 and val <= std.math.maxInt(u8)) {
                                gep_offset = @intCast(val);
                                gep_result = inst.result;
                            }
                        },
                        else => {},
                    }
                }
            },
            .load => |load| {
                if (load.ty.eql(.{ .int = 64 })) {
                    load_result = inst.result;
                }
            },
            .binary => |binary| {
                if (binary.ty.eql(.{ .int = 64 }) and (binary.op == .@"and" or binary.op == .xor)) {
                    binary_op = if (binary.op == .@"and") .@"and" else .xor;
                    binary_result = inst.result;
                    const l_res = load_result orelse return null;
                    switch (binary.lhs) {
                        .int => |val| {
                            if (binary.rhs == .named and std.mem.eql(u8, binary.rhs.named, l_res)) {
                                binary_mask = @truncate(val);
                            }
                        },
                        .named => |name| {
                            if (std.mem.eql(u8, name, l_res) and binary.rhs == .int) {
                                binary_mask = @truncate(binary.rhs.int);
                            }
                        },
                        else => {},
                    }
                }
            },
            .store => |store| {
                if (store.ty.eql(.{ .int = 64 })) {
                    if (store.value == .named) store_val = store.value.named;
                    if (store.ptr == .named) store_ptr = store.ptr.named;
                }
            },
            .alloca, .cast => {},
            else => {},
        }
    }

    const op = binary_op orelse return null;
    const mask = binary_mask orelse return null;
    const b_res = binary_result orelse return null;
    const s_val = store_val orelse return null;
    const s_ptr = store_ptr orelse return null;

    if (!std.mem.eql(u8, s_val, b_res)) return null;
    if (gep_result) |g_res| {
        if (!std.mem.eql(u8, s_ptr, g_res)) return null;
    }

    return .{
        .offset = gep_offset,
        .op = op,
        .mask = mask,
    };
}

pub const PointerOffsetIncrementRmw = struct {
    offset: u8,
};

pub fn matchesPointerOffsetIncrementRmwEnvelope(function: ir.Function) ?PointerOffsetIncrementRmw {
    if (function.ret_ty != .void or function.params.items.len != 1) return null;
    if (!function.params.items[0].ty.eql(.ptr) or function.blocks.items.len != 1) return null;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (ret.ty != .void or ret.value != null) return null;

    const param_name = function.params.items[0].name;
    var gep_offset: u8 = 0;
    var gep_result: ?[]const u8 = null;
    var load_result: ?[]const u8 = null;
    var binary_result: ?[]const u8 = null;
    var is_increment = false;
    var store_val: ?[]const u8 = null;
    var store_ptr: ?[]const u8 = null;

    for (block.instructions.items) |inst| {
        if (inst.removed) continue;
        switch (inst.kind) {
            .gep => |gep| {
                if (gep.source_ty.eql(.{ .int = 8 }) and gep.indices.items.len == 1) {
                    if (gep.ptr == .named and std.mem.eql(u8, gep.ptr.named, param_name)) {
                        switch (gep.indices.items[0].value) {
                            .int => |val| {
                                if (val >= 0 and val <= std.math.maxInt(u8)) {
                                    gep_offset = @intCast(val);
                                    gep_result = inst.result;
                                }
                            },
                            else => {},
                        }
                    }
                }
            },
            .load => |load| {
                if (load.ty.eql(.{ .int = 64 })) {
                    const ptr_name = switch (load.ptr) {
                        .named => |name| name,
                        else => return null,
                    };
                    if (gep_result) |g_res| {
                        if (std.mem.eql(u8, ptr_name, g_res)) {
                            load_result = inst.result;
                        }
                    } else if (std.mem.eql(u8, ptr_name, param_name)) {
                        load_result = inst.result;
                    }
                }
            },
            .binary => |binary| {
                if (binary.ty.eql(.{ .int = 64 }) and binary.op == .add) {
                    const l_res = load_result orelse return null;
                    if (binary.lhs == .named and std.mem.eql(u8, binary.lhs.named, l_res) and
                        binary.rhs == .int and binary.rhs.int == 1)
                    {
                        binary_result = inst.result;
                        is_increment = true;
                    } else if (binary.rhs == .named and std.mem.eql(u8, binary.rhs.named, l_res) and
                        binary.lhs == .int and binary.lhs.int == 1)
                    {
                        binary_result = inst.result;
                        is_increment = true;
                    }
                }
            },
            .store => |store| {
                if (store.ty.eql(.{ .int = 64 })) {
                    if (store.value == .named) store_val = store.value.named;
                    if (store.ptr == .named) store_ptr = store.ptr.named;
                }
            },
            .alloca, .cast => {},
            else => return null,
        }
    }

    if (!is_increment) return null;
    const b_res = binary_result orelse return null;
    const s_val = store_val orelse return null;
    const s_ptr = store_ptr orelse return null;

    if (!std.mem.eql(u8, s_val, b_res)) return null;
    if (gep_result) |g_res| {
        if (!std.mem.eql(u8, s_ptr, g_res)) return null;
    } else {
        if (!std.mem.eql(u8, s_ptr, param_name)) return null;
    }

    return .{
        .offset = gep_offset,
    };
}
