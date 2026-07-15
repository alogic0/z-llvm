const std = @import("std");
const ir = @import("../../../ir.zig");
const inspection = @import("inspection.zig");
const selector_frame = @import("composed_selector_frame.zig");
const selector_state = @import("composed_selector_state.zig");
const selector_types = @import("selector_types.zig");
const state_data = @import("composed_selector_state_data.zig");

const ComposedBlockSelector = state_data.ComposedBlockSelector;
const Diagnostic = inspection.Diagnostic;

pub fn isFpToSignedI32Cast(cast: ir.CastInst) bool {
    return cast.op == .fptosi and (cast.from_ty == .float or cast.from_ty == .double) and cast.to_ty.eql(.{ .int = 32 });
}

pub fn lowerIntToFpCast(selector: *ComposedBlockSelector, result: ?[]const u8, cast: ir.CastInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    const from_bits = intBits(cast.from_ty) orelse return .{ .no_emitter = "composed-int-fp-from-type" };
    const to_half = cast.to_ty == .half;
    const to_bits: u16 = if (cast.to_ty == .half or cast.to_ty == .float) 32 else if (cast.to_ty == .double) 64 else return .{ .no_emitter = "composed-int-fp-to-type" };
    if (to_half and from_bits != 32 and from_bits != 64 and from_bits != 96 and from_bits != 128)
        return .{ .no_emitter = "composed-int-fp-half-width" };
    if ((from_bits < 8 or from_bits > 64) and from_bits != 96 and from_bits != 128)
        return .{ .no_emitter = "composed-int-fp-width" };
    if (cast.op != .sitofp and cast.op != .uitofp) return .{ .no_emitter = "composed-int-fp-op" };

    if (from_bits > 64) {
        if (try lowerWideInteger(selector, cast, to_bits)) |diagnostic| return diagnostic;
    } else {
        while (selector_state.liveAccumulatorNameAfterCurrent(selector)) |live_name| {
            if (try selector_state.preserveLiveAccumulatorValue(selector, live_name)) |diagnostic| return diagnostic;
        }
        if (cast.op == .uitofp and from_bits == 64) {
            if (try lowerUnsignedI64(selector, cast.value, to_bits)) |diagnostic| return diagnostic;
        } else {
            const use_i64_source = cast.op == .uitofp or from_bits > 32;
            if (from_bits <= 32) {
                selector_state.emitValueIntoEax(selector, cast.value) catch return .{ .unsupported_value = "composed-int-fp-source" };
                if (from_bits < 32) {
                    if (cast.op == .sitofp) {
                        const amount: u5 = @intCast(32 - from_bits);
                        try selector.machine.instructions.append(selector.allocator, .{ .shl_eax_imm5 = amount });
                        try selector.machine.instructions.append(selector.allocator, .{ .sar_eax_imm5 = amount });
                    } else {
                        const mask: i32 = @bitCast((@as(u32, 1) << @intCast(from_bits)) - 1);
                        try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = mask });
                    }
                }
                selector_state.clobberArgReg(selector, .rdi) catch return .{ .no_spill_envelope = "composed-int-fp-rdi" };
                try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = .rdi });
            } else {
                selector_state.emitValueIntoRax(selector, cast.value) catch return .{ .unsupported_value = "composed-int-fp-source" };
                if (from_bits < 64) {
                    const amount: u6 = @intCast(64 - from_bits);
                    try selector.machine.instructions.append(selector.allocator, .{ .shl_rax_imm6 = amount });
                }
                selector_state.clobberArgReg(selector, .rdi) catch return .{ .no_spill_envelope = "composed-int-fp-rdi" };
                try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = .rdi });
                if (from_bits < 64) {
                    const amount: u6 = @intCast(64 - from_bits);
                    try selector.machine.instructions.append(selector.allocator, if (cast.op == .sitofp)
                        .{ .sar_arg64_imm6 = .{ .reg = .rdi, .amount = amount } }
                    else
                        .{ .shr_arg64_imm6 = .{ .reg = .rdi, .amount = amount } });
                }
            }

            selector_state.clobberXmmReg(selector, .xmm0) catch return .{ .no_spill_envelope = "composed-int-fp-xmm0" };
            try appendSignedConversion(selector, to_bits, use_i64_source);
        }
    }

    const result_bits: u16 = if (to_half) 16 else to_bits;
    if (to_half) {
        if (try appendHalfTruncation(selector)) |diagnostic| return diagnostic;
    }
    selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = .xmm0, .bits = result_bits } }) catch return .{ .no_spill_envelope = "composed-int-fp-result" };
    return null;
}

pub fn lowerFpToSignedIntCast(selector: *ComposedBlockSelector, result: ?[]const u8, cast: ir.CastInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (!isFpToSignedI32Cast(cast)) return .{ .no_emitter = "composed-fp-int-type" };
    const from_bits: u16 = if (cast.from_ty == .float)
        32
    else if (cast.from_ty == .double)
        64
    else
        return .{ .no_emitter = "composed-fp-int-from-type" };
    while (selector_state.liveAccumulatorNameAfterCurrent(selector)) |live_name| {
        if (try selector_state.preserveLiveAccumulatorValue(selector, live_name)) |diagnostic| return diagnostic;
    }
    const source = selector_state.resolveValue(selector, cast.value) orelse return .{ .unsupported_value = "composed-fp-int-source" };
    selector_state.materializeLocIntoLoc(selector, source, .{ .xmm = .{ .reg = .xmm0, .bits = from_bits } }) catch return .{ .unsupported_value = "composed-fp-int-source" };
    try selector.machine.instructions.append(selector.allocator, if (from_bits == 32) .cvttss2si_xmm0_eax else .cvttsd2si_xmm0_eax);
    try selector_state.bindEax(selector, result_name);
    return null;
}

fn lowerUnsignedI64(selector: *ComposedBlockSelector, value: ir.Value, to_bits: u16) !?Diagnostic {
    selector_state.emitValueIntoRax(selector, value) catch return .{ .unsupported_value = "composed-int-fp-source" };
    selector_state.clobberArgReg(selector, .rdi) catch return .{ .no_spill_envelope = "composed-int-fp-u64-rdi" };
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = .rdi });
    selector_state.clobberAccumulator(selector) catch return .{ .no_spill_envelope = "composed-int-fp-u64-rax" };
    selector_state.clobberXmmReg(selector, .xmm0) catch return .{ .no_spill_envelope = "composed-int-fp-u64-xmm0" };

    const correction_label = try selector_state.allocateEdgeLabel(selector);
    const end_label = try selector_state.allocateEdgeLabel(selector);
    try selector.machine.instructions.append(selector.allocator, .test_rax_rax);
    try selector.machine.instructions.append(selector.allocator, .{ .js = correction_label });
    try appendSignedConversion(selector, to_bits, true);
    try selector.machine.instructions.append(selector.allocator, .{ .jmp = end_label });
    try selector.machine.instructions.append(selector.allocator, .{ .label = correction_label });
    try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = 1 });
    try selector.machine.instructions.append(selector.allocator, .{ .shr_arg64_imm6 = .{ .reg = .rdi, .amount = 1 } });
    try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .@"or", .reg = .rdi } });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = .rdi });
    try appendSignedConversion(selector, to_bits, true);
    try selector.machine.instructions.append(selector.allocator, if (to_bits == 32)
        .{ .addss_xmm = .{ .dst = .xmm0, .src = .xmm0 } }
    else
        .{ .addsd_xmm = .{ .dst = .xmm0, .src = .xmm0 } });
    try selector.machine.instructions.append(selector.allocator, .{ .label = end_label });
    return null;
}

fn lowerWideInteger(selector: *ComposedBlockSelector, cast: ir.CastInst, to_bits: u16) !?Diagnostic {
    if (try selector_state.spillLiveCallerClobbersForCall(selector)) |diagnostic| return diagnostic;
    _ = selector_state.materializePairValue(selector, cast.value, .{ .lo = .rdi, .hi = .rsi }) catch
        return .{ .unsupported_value = "composed-int-fp-wide-source" };
    for (selector_types.selector_allocatable_regs) |reg|
        selector_state.clobberArgReg(selector, reg) catch return .{ .no_spill_envelope = "composed-int-fp-wide-gpr" };
    selector_state.clobberAccumulator(selector) catch return .{ .no_spill_envelope = "composed-int-fp-wide-rax" };
    selector_state.clobberXmmReg(selector, .xmm0) catch return .{ .no_spill_envelope = "composed-int-fp-wide-xmm0" };
    selector_state.clobberXmmReg(selector, .xmm1) catch return .{ .no_spill_envelope = "composed-int-fp-wide-xmm1" };

    const from_bits = intBits(cast.from_ty).?;
    if (from_bits == 96) {
        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = .rsi });
        if (cast.op == .sitofp) {
            try selector.machine.instructions.append(selector.allocator, .{ .shl_rax_imm6 = 32 });
            try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = .rsi });
            try selector.machine.instructions.append(selector.allocator, .{ .sar_arg64_imm6 = .{ .reg = .rsi, .amount = 32 } });
        } else {
            try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = -1 });
            try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = .rsi });
        }
    }
    try selector.machine.instructions.append(selector.allocator, .{ .wide_int_to_fp_rdi_rsi_xmm0 = .{
        .signed = cast.op == .sitofp,
        .to_bits = to_bits,
    } });
    return null;
}

fn appendHalfTruncation(selector: *ComposedBlockSelector) !?Diagnostic {
    const function = selector.function orelse return .{ .no_emitter = "composed-int-fp-half-function" };
    if (std.mem.eql(u8, function.name, "__truncsfhf2")) return .{ .no_emitter = "composed-int-fp-half-recursive" };
    // Every integer near the finite-half/overflow boundary is exactly representable
    // in f32. Values outside that interval cannot cross it under f32 rounding, so
    // the f32 intermediate and __truncsfhf2 produce the direct integer-to-half result.
    if (try selector_state.spillLiveCallerClobbersForCall(selector)) |diagnostic| return diagnostic;
    const needs_alignment = selector.stack_frame_bytes == 0;
    if (needs_alignment) try selector_frame.appendSubRsp(selector, 8);
    try selector.machine.instructions.append(selector.allocator, .{ .direct_call = .{ .symbol = "__truncsfhf2", .ret_ty = .half } });
    if (needs_alignment) try selector_frame.appendAddRsp(selector, 8);
    return null;
}

fn appendSignedConversion(selector: *ComposedBlockSelector, to_bits: u16, source_is_i64: bool) !void {
    try selector.machine.instructions.append(selector.allocator, if (source_is_i64)
        if (to_bits == 32) .cvtsi2ss_rdi_xmm0 else .cvtsi2sd_rdi_xmm0
    else if (to_bits == 32)
        .cvtsi2ss_edi_xmm0
    else
        .cvtsi2sd_edi_xmm0);
}

fn intBits(ty: ir.Type) ?u16 {
    return switch (ty) {
        .int => |bits| bits,
        else => null,
    };
}
