const ir = @import("../../../ir.zig");
const x86_64_match = @import("../match.zig");
const inspection = @import("inspection.zig");
const selector_state = @import("composed_selector_state.zig");
const selector_frame = @import("composed_selector_frame.zig");
const state_data = @import("composed_selector_state_data.zig");

const ComposedBlockSelector = state_data.ComposedBlockSelector;
const Diagnostic = inspection.Diagnostic;

pub fn lowerFpBinary(selector: *ComposedBlockSelector, result: ?[]const u8, binary: ir.BinaryInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (binary.op != .fadd or binary.ty != .float) return .{ .no_emitter = "composed-block-fp-binary-type" };

    if (try materializeFpValue(selector, binary.rhs, .xmm1, 32)) |diagnostic| return diagnostic;
    if (try materializeFpValue(selector, binary.lhs, .xmm0, 32)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, .addss_xmm1_xmm0);
    try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = .xmm0, .bits = 32 } });
    return null;
}

fn materializeFpValue(selector: *ComposedBlockSelector, value: ir.Value, dst: @import("../types.zig").XmmReg, bits: u16) !?Diagnostic {
    switch (value) {
        .named => {
            const source = selector_state.resolveValue(selector, value) orelse return .{ .unsupported_value = "composed-block-fp-source" };
            selector_state.materializeLocIntoLoc(selector, source, .{ .xmm = .{ .reg = dst, .bits = bits } }) catch return .{ .unsupported_value = "composed-block-fp-source" };
        },
        .fp => {
            if (bits != 32) return .{ .no_emitter = "composed-block-fp-immediate-width" };
            try selector_state.clobberXmmReg(selector, dst);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_imm32_xmm = .{ .reg = dst, .bits = try x86_64_match.fp32TextBits(value) } });
        },
        .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "composed-block-fp-source" },
    }
    return null;
}

pub fn lowerFpCast(selector: *ComposedBlockSelector, result: ?[]const u8, cast: ir.CastInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    return switch (cast.op) {
        .fpext => lowerHalfToFloat(selector, result_name, cast),
        .fptrunc => lowerFloatToHalf(selector, result_name, cast),
        .bitcast => lowerFpIntBitcast(selector, result_name, cast),
        else => .{ .no_emitter = "composed-block-fp-cast-op" },
    };
}

pub fn isFpIntBitcast(cast: ir.CastInst) bool {
    return (cast.from_ty == .half and cast.to_ty.eql(.{ .int = 16 })) or
        (cast.from_ty.eql(.{ .int = 16 }) and cast.to_ty == .half) or
        (cast.from_ty == .float and cast.to_ty.eql(.{ .int = 32 })) or
        (cast.from_ty.eql(.{ .int = 32 }) and cast.to_ty == .float);
}

fn lowerFpIntBitcast(selector: *ComposedBlockSelector, result_name: []const u8, cast: ir.CastInst) !?Diagnostic {
    if (!isFpIntBitcast(cast)) return .{ .no_emitter = "composed-block-fp-bitcast-type" };
    if (cast.from_ty == .half or cast.from_ty == .float) {
        const bits: u16 = if (cast.from_ty == .half) 16 else 32;
        const source = selector_state.resolveValue(selector, cast.value) orelse return .{ .unsupported_value = "composed-block-fp-bitcast-source" };
        try selector_state.clobberAccumulator(selector);
        const reg = switch (source) {
            .xmm => |fp| if (fp.bits == bits) fp.reg else return .{ .unsupported_value = "composed-block-fp-bitcast-source" },
            .spill_fp => |fp| blk: {
                if (fp.bits != bits) return .{ .unsupported_value = "composed-block-fp-bitcast-source" };
                selector_state.materializeLocIntoLoc(selector, source, .{ .xmm = .{ .reg = .xmm0, .bits = bits } }) catch return .{ .unsupported_value = "composed-block-fp-bitcast-source" };
                break :blk .xmm0;
            },
            else => return .{ .unsupported_value = "composed-block-fp-bitcast-source" },
        };
        try selector.machine.instructions.append(selector.allocator, .{ .movd_xmm_eax = reg });
        try selector_state.bindEax(selector, result_name);
        return null;
    }

    const bits: u16 = if (cast.to_ty == .half) 16 else 32;
    selector_state.emitValueIntoEax(selector, cast.value) catch return .{ .unsupported_value = "composed-block-fp-bitcast-source" };
    try selector_state.clobberXmmReg(selector, .xmm0);
    try selector.machine.instructions.append(selector.allocator, .{ .movd_eax_xmm = .xmm0 });
    try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = .xmm0, .bits = bits } });
    return null;
}

fn lowerFloatToHalf(selector: *ComposedBlockSelector, result_name: []const u8, cast: ir.CastInst) !?Diagnostic {
    if (cast.from_ty != .float or cast.to_ty != .half) return .{ .no_emitter = "composed-block-fptrunc-type" };
    if (try selector_state.spillLiveCallerClobbersForCall(selector)) |diagnostic| return diagnostic;
    const source = selector_state.resolveValue(selector, cast.value) orelse return .{ .unsupported_value = "composed-block-fptrunc-source" };
    selector_state.materializeLocIntoLoc(selector, source, .{ .xmm = .{ .reg = .xmm0, .bits = 32 } }) catch return .{ .unsupported_value = "composed-block-fptrunc-source" };

    const needs_alignment = selector.stack_frame_bytes == 0;
    if (needs_alignment) try selector_frame.appendSubRsp(selector, 8);
    try selector.machine.instructions.append(selector.allocator, .{ .direct_call = .{ .symbol = "__truncsfhf2", .ret_ty = .half } });
    if (needs_alignment) try selector_frame.appendAddRsp(selector, 8);
    try selector_state.bindValueLoc(selector, result_name, .{ .xmm = .{ .reg = .xmm0, .bits = 16 } });
    return null;
}

fn lowerHalfToFloat(selector: *ComposedBlockSelector, result_name: []const u8, cast: ir.CastInst) !?Diagnostic {
    if (cast.from_ty != .half or cast.to_ty != .float) return .{ .no_emitter = "composed-block-fpext-type" };
    if (try selector_state.spillLiveCallerClobbersForCall(selector)) |diagnostic| return diagnostic;
    const source = selector_state.resolveValue(selector, cast.value) orelse return .{ .unsupported_value = "composed-block-fpext-source" };
    selector_state.materializeLocIntoLoc(selector, source, .{ .xmm = .{ .reg = .xmm0, .bits = 16 } }) catch return .{ .unsupported_value = "composed-block-fpext-source" };

    const needs_alignment = selector.stack_frame_bytes == 0;
    if (needs_alignment) try selector_frame.appendSubRsp(selector, 8);
    try selector.machine.instructions.append(selector.allocator, .{ .direct_call = .{ .symbol = "__extendhfsf2", .ret_ty = .float } });
    if (needs_alignment) try selector_frame.appendAddRsp(selector, 8);
    try selector_state.bindValueLoc(selector, result_name, .{ .xmm = .{ .reg = .xmm0, .bits = 32 } });
    return null;
}
