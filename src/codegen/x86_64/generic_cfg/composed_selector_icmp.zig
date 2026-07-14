const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_types = @import("../types.zig");
const inspection = @import("inspection.zig");
const selector_types = @import("selector_types.zig");
const composed_helpers = @import("composed_helpers.zig");
const selector_state = @import("composed_selector_state.zig");

const ArgReg = x86_64_types.ArgReg;
const pair_a = selector_types.pair_a;
const pair_b = selector_types.pair_b;
const intBits = composed_helpers.intBits;
const i32Value = composed_helpers.i32Value;
const i64Value = composed_helpers.i64Value;

pub const Diagnostic = inspection.Diagnostic;
pub const ComposedBlockSelector = selector_state.ComposedBlockSelector;

pub fn lowerIcmp(selector: *ComposedBlockSelector, result: ?[]const u8, icmp: ir.IcmpInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    while (selector_state.liveAccumulatorNameAfterCurrent(selector)) |live_name| {
        if (try selector_state.preserveLiveAccumulatorValue(selector, live_name)) |diagnostic| return diagnostic;
    }
    const is_ne_zero_i16 = icmp.predicate == .ne and icmp.operand_ty.eql(.{ .int = 16 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
    if (is_ne_zero_i16) {
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 16) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg16_imm16 = .{ .reg = .rcx, .imm = 0 } });
        try selector.machine.instructions.append(selector.allocator, .setne_eax);
    } else if (icmp.predicate == .ne and icmp.operand_ty.eql(.{ .int = 32 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 32) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .test_arg32 = .rcx });
        try selector.machine.instructions.append(selector.allocator, .setne_eax);
    } else if (icmp.predicate == .ne and icmp.operand_ty.eql(.{ .int = 64 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = 0 } });
        try selector.machine.instructions.append(selector.allocator, .setne_eax);
    } else if (!icmp.samesign and icmp.predicate == .ne and icmp.rhs == .named and
        (icmp.operand_ty.eql(.{ .int = 32 }) or icmp.operand_ty.eql(.{ .int = 64 })))
    {
        const bits: u16 = if (icmp.operand_ty.eql(.{ .int = 32 })) 32 else 64;
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, bits) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        selector_state.emitValueIntoScratch(selector, icmp.rhs, .r8, bits) catch return .{ .unsupported_value = "composed-block-icmp-rhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, if (bits == 32) .{ .cmp_ecx_arg32 = .r8 } else .{ .cmp_rcx_arg64 = .r8 });
        try selector.machine.instructions.append(selector.allocator, .setne_eax);
    } else if (icmp.predicate == .eq and icmp.operand_ty.eql(.ptr) and icmp.rhs == .null_value) {
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .test_arg64 = .rcx });
        try selector.machine.instructions.append(selector.allocator, .sete_eax);
    } else if (icmp.predicate == .eq and icmp.operand_ty.eql(.ptr)) {
        if (icmp.rhs != .named) return .{ .no_emitter = "composed-block-icmp-rhs" };
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        selector_state.emitValueIntoScratch(selector, icmp.rhs, .r8, 64) catch return .{ .unsupported_value = "composed-block-icmp-rhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_rcx_arg64 = .r8 });
        try selector.machine.instructions.append(selector.allocator, .sete_eax);
    } else if (icmp.predicate == .eq and icmp.operand_ty.eql(.{ .int = 128 }) and switch (icmp.rhs) {
        .int => |int| int == std.math.minInt(i128),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        const existing = selector_state.resolvePairValue(selector, icmp.lhs);
        const pair = if (existing) |source|
            if (source.contains(pair_a.lo) or source.contains(pair_a.hi)) pair_b else pair_a
        else
            pair_a;
        _ = selector_state.materializePairValue(selector, icmp.lhs, pair) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        const temp: ArgReg = if (pair.contains(.r8)) .rcx else .r8;
        try selector_state.clobberAccumulator(selector);
        try selector_state.clobberArgReg(selector, temp);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = pair.hi });
        try selector.machine.instructions.append(selector.allocator, switch (temp) {
            .rcx => .{ .mov_imm_rcx = std.math.minInt(i64) },
            .r8 => .{ .mov_imm_r8 = std.math.minInt(i64) },
            else => unreachable,
        });
        try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .xor, .reg = temp } });
        try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .@"or", .reg = pair.lo } });
        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = temp });
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg64_imm64 = .{ .reg = temp, .imm = 0 } });
        try selector.machine.instructions.append(selector.allocator, .sete_eax);
    } else if (icmp.predicate == .eq) {
        const bits = intBits(icmp.operand_ty) orelse return .{ .no_emitter = "composed-block-icmp-type" };
        if (icmp.rhs == .named) {
            if (bits == 64) {
                selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
                selector_state.emitValueIntoScratch(selector, icmp.rhs, .r8, 64) catch return .{ .unsupported_value = "composed-block-icmp-rhs" };
            } else if (bits <= 32) {
                selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 32) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
                selector_state.emitValueIntoScratch(selector, icmp.rhs, .r8, 32) catch return .{ .unsupported_value = "composed-block-icmp-rhs" };
            } else return .{ .no_emitter = "composed-block-icmp-rhs" };
            try selector_state.clobberAccumulator(selector);
            try selector.machine.instructions.append(selector.allocator, if (bits == 64) .{ .cmp_rcx_arg64 = .r8 } else .{ .cmp_ecx_arg32 = .r8 });
            try selector.machine.instructions.append(selector.allocator, .sete_eax);
            try selector_state.bindEax(selector, result_name);
            return null;
        }
        const rhs = switch (icmp.rhs) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .no_emitter = "composed-block-icmp-rhs" },
        };
        const imm = try i64Value(rhs);
        if (imm != 0) {
            if (bits == 64) {
                selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
                try selector_state.clobberAccumulator(selector);
                try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = imm } });
            } else if (bits <= 32) {
                selector_state.emitValueIntoEax(selector, icmp.lhs) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
                try selector.machine.instructions.append(selector.allocator, .{ .cmp_eax_imm32 = try i32Value(rhs) });
            } else return .{ .no_emitter = "composed-block-icmp-eq-rhs" };
            try selector.machine.instructions.append(selector.allocator, .sete_eax);
            try selector_state.bindEax(selector, result_name);
            return null;
        }
        const loc = selector_state.resolveValue(selector, icmp.lhs) orelse return .{ .unsupported_value = "composed-block-icmp-lhs" };
        switch (loc) {
            .eax => try selector.machine.instructions.append(selector.allocator, .test_eax_eax),
            .rax => {
                if (bits != 64) return .{ .no_emitter = "composed-block-icmp-lhs-width" };
                try selector.machine.instructions.append(selector.allocator, .test_rax_rax);
            },
            .arg32, .scratch32 => |reg| {
                if (bits > 32) return .{ .no_emitter = "composed-block-icmp-lhs-width" };
                try selector.machine.instructions.append(selector.allocator, .{ .test_arg32 = reg });
            },
            .arg64, .scratch64 => |reg| {
                if (bits != 64) return .{ .no_emitter = "composed-block-icmp-lhs-width" };
                try selector.machine.instructions.append(selector.allocator, .{ .test_arg64 = reg });
            },
            .spill64 => |frame_index| {
                try selector_state.clobberArgReg(selector, .rcx);
                if (bits == 64) {
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                    try selector.machine.instructions.append(selector.allocator, .{ .test_arg64 = .rcx });
                } else if (bits <= 32) {
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                    try selector.machine.instructions.append(selector.allocator, .{ .test_arg32 = .rcx });
                } else return .{ .no_emitter = "composed-block-icmp-lhs-width" };
            },
            .arg128, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector => return .{ .no_emitter = "composed-block-icmp-lhs-loc" },
        }
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .sete_eax);
    } else if ((icmp.predicate == .ult or icmp.predicate == .ugt) and icmp.operand_ty.eql(.{ .int = 16 }) and icmp.rhs == .int) {
        const imm = try i64Value(icmp.rhs.int);
        if (imm < 0 or imm > std.math.maxInt(u16)) return .{ .no_emitter = "composed-block-icmp-rhs" };
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 16) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg16_imm16 = .{ .reg = .rcx, .imm = @intCast(imm) } });
        try selector.machine.instructions.append(selector.allocator, if (icmp.predicate == .ult) .setb_eax else .seta_eax);
    } else if (icmp.predicate == .ugt and (icmp.operand_ty.eql(.{ .int = 32 }) or icmp.operand_ty.eql(.{ .int = 64 })) and icmp.rhs == .named) {
        const bits: u16 = if (icmp.operand_ty.eql(.{ .int = 32 })) 32 else 64;
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, bits) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        selector_state.emitValueIntoScratch(selector, icmp.rhs, .r8, bits) catch return .{ .unsupported_value = "composed-block-icmp-rhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, if (bits == 32) .{ .cmp_ecx_arg32 = .r8 } else .{ .cmp_rcx_arg64 = .r8 });
        try selector.machine.instructions.append(selector.allocator, .setb_eax);
    } else if (icmp.predicate == .ugt and icmp.operand_ty.eql(.{ .int = 64 }) and icmp.rhs == .int) {
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector_state.clobberArgReg(selector, .r8);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_r8 = try i64Value(icmp.rhs.int) });
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_rcx_arg64 = .r8 });
        try selector.machine.instructions.append(selector.allocator, .setb_eax);
    } else if (icmp.predicate == .ugt and icmp.operand_ty.eql(.{ .int = 32 }) and icmp.rhs == .int) {
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 32) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector_state.clobberArgReg(selector, .r8);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_r8 = try i64Value(icmp.rhs.int) });
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_r8d_arg32 = .rcx });
        try selector.machine.instructions.append(selector.allocator, .setb_eax);
    } else if (icmp.predicate == .sgt and icmp.operand_ty.eql(.{ .int = 6 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == -1,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        try selector_state.emitValueIntoEax(selector, icmp.lhs);
        try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = 1 << 5 });
        try selector.machine.instructions.append(selector.allocator, .sete_eax);
    } else if (icmp.predicate == .sgt and icmp.operand_ty.eql(.{ .int = 32 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == -1,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        try selector_state.emitValueIntoEax(selector, icmp.lhs);
        try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = std.math.minInt(i32) });
        try selector.machine.instructions.append(selector.allocator, .sete_eax);
    } else if (icmp.predicate == .sgt and icmp.operand_ty.eql(.{ .int = 32 }) and icmp.rhs == .int) {
        try selector_state.emitValueIntoEax(selector, icmp.lhs);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_eax_imm32 = try i32Value(icmp.rhs.int) });
        try selector.machine.instructions.append(selector.allocator, .setg_eax);
    } else if (!icmp.samesign and icmp.predicate == .sgt and icmp.operand_ty.eql(.{ .int = 64 }) and icmp.rhs == .int) {
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = try i64Value(icmp.rhs.int) } });
        try selector.machine.instructions.append(selector.allocator, .setg_eax);
    } else if (icmp.predicate == .slt and icmp.operand_ty.eql(.{ .int = 128 }) and switch (icmp.rhs) {
        .int => |int| int == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        selector_state.emitPairHighLaneIntoRax(selector, icmp.lhs) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector.machine.instructions.append(selector.allocator, .{ .shr_rax_imm6 = 63 });
    } else if (icmp.predicate == .slt and icmp.operand_ty.eql(.{ .int = 64 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        if (try selector_state.preserveCurrentRaxIntoScratch(selector)) |diagnostic| return diagnostic;
        try selector_state.emitValueIntoRax(selector, icmp.lhs);
        try selector.machine.instructions.append(selector.allocator, .{ .shr_rax_imm6 = 63 });
    } else if (icmp.predicate == .slt and icmp.operand_ty.eql(.{ .int = 32 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        if (try selector_state.preserveCurrentEaxIntoScratch(selector)) |diagnostic| return diagnostic;
        try selector_state.emitValueIntoEax(selector, icmp.lhs);
        try selector.machine.instructions.append(selector.allocator, .{ .shr_eax_imm5 = 31 });
    } else if (icmp.predicate == .slt and icmp.operand_ty.eql(.{ .int = 16 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 16) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg16_imm16 = .{ .reg = .rcx, .imm = 0 } });
        try selector.machine.instructions.append(selector.allocator, .setl_eax);
    } else if (!icmp.samesign and icmp.predicate == .slt and icmp.rhs == .int and
        (icmp.operand_ty.eql(.{ .int = 32 }) or icmp.operand_ty.eql(.{ .int = 64 })))
    {
        if (icmp.operand_ty.eql(.{ .int = 32 })) {
            try selector_state.emitValueIntoEax(selector, icmp.lhs);
            try selector.machine.instructions.append(selector.allocator, .{ .cmp_eax_imm32 = try i32Value(icmp.rhs.int) });
        } else {
            selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
            try selector_state.clobberAccumulator(selector);
            try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = try i64Value(icmp.rhs.int) } });
        }
        try selector.machine.instructions.append(selector.allocator, .setl_eax);
    } else if (!icmp.samesign and (icmp.predicate == .slt or icmp.predicate == .sgt) and icmp.rhs == .named and
        (icmp.operand_ty.eql(.{ .int = 32 }) or icmp.operand_ty.eql(.{ .int = 64 })))
    {
        const bits: u16 = if (icmp.operand_ty.eql(.{ .int = 32 })) 32 else 64;
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, bits) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        selector_state.emitValueIntoScratch(selector, icmp.rhs, .r8, bits) catch return .{ .unsupported_value = "composed-block-icmp-rhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, if (bits == 32) .{ .cmp_ecx_arg32 = .r8 } else .{ .cmp_rcx_arg64 = .r8 });
        try selector.machine.instructions.append(selector.allocator, if (icmp.predicate == .slt) .setg_eax else .setl_eax);
    } else if (icmp.samesign and icmp.predicate == .ult and icmp.operand_ty.eql(.{ .int = 6 }) and icmp.rhs == .int) {
        const imm = try i64Value(icmp.rhs.int);
        if (imm < 0 or imm > 63) return .{ .no_emitter = "composed-block-icmp-rhs" };
        try selector_state.emitValueIntoEax(selector, icmp.lhs);
        try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = 63 });
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_eax_imm32 = @intCast(imm) });
        try selector.machine.instructions.append(selector.allocator, .setb_eax);
    } else if (icmp.predicate == .ult and icmp.operand_ty.eql(.{ .int = 32 }) and icmp.rhs == .named) {
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .r8, 32) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        selector_state.emitValueIntoScratch(selector, icmp.rhs, .rcx, 32) catch return .{ .unsupported_value = "composed-block-icmp-rhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_ecx_arg32 = .r8 });
        try selector.machine.instructions.append(selector.allocator, .setb_eax);
    } else if (icmp.predicate == .ult and icmp.operand_ty.eql(.{ .int = 32 }) and icmp.rhs == .int) {
        try selector_state.emitValueIntoEax(selector, icmp.lhs);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_eax_imm32 = try i32Value(icmp.rhs.int) });
        try selector.machine.instructions.append(selector.allocator, .setb_eax);
    } else if (icmp.predicate == .ult and icmp.operand_ty.eql(.{ .int = 64 })) {
        const rhs = switch (icmp.rhs) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .no_emitter = "composed-block-icmp-rhs" },
        };
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = try i64Value(rhs) } });
        try selector.machine.instructions.append(selector.allocator, .setb_eax);
    } else return .{ .no_emitter = "composed-block-icmp-form" };
    try selector_state.bindEax(selector, result_name);
    return null;
}
