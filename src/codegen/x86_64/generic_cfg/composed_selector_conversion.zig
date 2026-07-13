const ir = @import("../../../ir.zig");
const inspection = @import("inspection.zig");
const selector_state = @import("composed_selector_state.zig");
const state_data = @import("composed_selector_state_data.zig");

const ComposedBlockSelector = state_data.ComposedBlockSelector;
const Diagnostic = inspection.Diagnostic;

pub fn lowerIntToFpCast(selector: *ComposedBlockSelector, result: ?[]const u8, cast: ir.CastInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    const from_bits = intBits(cast.from_ty) orelse return .{ .no_emitter = "composed-int-fp-from-type" };
    const to_bits: u16 = if (cast.to_ty == .float) 32 else if (cast.to_ty == .double) 64 else return .{ .no_emitter = "composed-int-fp-to-type" };
    if (from_bits < 8 or from_bits > 64) return .{ .no_emitter = "composed-int-fp-width" };
    if (cast.op != .sitofp and cast.op != .uitofp) return .{ .no_emitter = "composed-int-fp-op" };

    while (selector_state.liveAccumulatorNameAfterCurrent(selector)) |live_name| {
        if (try selector_state.preserveLiveAccumulatorValue(selector, live_name)) |diagnostic| return diagnostic;
    }
    if (cast.op == .uitofp and from_bits == 64) {
        return lowerUnsignedI64(selector, result_name, cast.value, to_bits);
    }

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
    selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = .xmm0, .bits = to_bits } }) catch return .{ .no_spill_envelope = "composed-int-fp-result" };
    return null;
}

fn lowerUnsignedI64(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, to_bits: u16) !?Diagnostic {
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
    selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = .xmm0, .bits = to_bits } }) catch return .{ .no_spill_envelope = "composed-int-fp-u64-result" };
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
