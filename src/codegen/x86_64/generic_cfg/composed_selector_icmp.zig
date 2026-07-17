const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_types = @import("../types.zig");
const inspection = @import("inspection.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const composed_helpers = @import("composed_helpers.zig");
const selector_state = @import("composed_selector_state.zig");
const value_use = @import("composed_selector_value_use_transaction.zig");

const ArgReg = x86_64_types.ArgReg;
const ValueUseTransaction = value_use.ValueUseTransaction;
const pair_a = selector_types.pair_a;
const pair_b = selector_types.pair_b;
const intBits = composed_helpers.intBits;
const i32Value = composed_helpers.i32Value;
const i64Value = composed_helpers.i64Value;
const u16BitPattern = composed_helpers.u16BitPattern;

pub const Diagnostic = inspection.Diagnostic;
pub const ComposedBlockSelector = selector_state.ComposedBlockSelector;

const ScratchCompareSemanticRhs = union(enum) {
    immediate: i128,
    null_pointer,
    named,
};

const ScratchCompareSemantic = struct {
    operand_ty: ir.Type,
    predicate: ir.IcmpPredicate,
    samesign: bool,
    rhs: ScratchCompareSemanticRhs,
};

const ScratchCompareDispatch = union(enum) {
    legacy,
    diagnostic: Diagnostic,
    action: ScratchCompareSemantic,
};

/// Pure semantic dispatch for the reviewed fixed-scratch subgroup. This
/// classifier deliberately has no selector and cannot observe source homes,
/// function identity, allocation state, or family identity.
fn classifyScratchCompare(icmp: ir.IcmpInst) !ScratchCompareDispatch {
    const bits = intBits(icmp.operand_ty);
    if (icmp.predicate == .ne) {
        if (icmp.rhs == .int) {
            const immediate = try i64Value(icmp.rhs.int);
            if (immediate == 0 and
                (bits == 16 or bits == 32 or bits == 64))
            {
                return scratchCompareAction(icmp, .{ .immediate = 0 });
            }
        }
        if (!icmp.samesign and icmp.rhs == .named and
            (bits == 16 or bits == 32 or bits == 64))
        {
            return scratchCompareAction(icmp, .named);
        }
        return .legacy;
    }
    if (icmp.predicate == .eq) {
        if (icmp.operand_ty == .ptr) {
            return switch (icmp.rhs) {
                .null_value => scratchCompareAction(icmp, .null_pointer),
                .named => scratchCompareAction(icmp, .named),
                .int,
                .fp,
                .undef,
                .poison,
                .zero_initializer,
                .vector,
                .constant_expr,
                => .{ .diagnostic = .{ .no_emitter = "composed-block-icmp-rhs" } },
            };
        }
        if (bits == 128 and icmp.rhs.eql(.{ .int = std.math.minInt(i128) }))
            return .legacy;
        if (!icmp.samesign and bits == 52 and icmp.rhs.eql(.{ .int = 0 }))
            return scratchCompareAction(icmp, .{ .immediate = 0 });
        const integer_bits = bits orelse return .legacy;
        if (icmp.rhs == .named) {
            if (integer_bits == 64 or integer_bits <= 32)
                return scratchCompareAction(icmp, .named);
            return .{ .diagnostic = .{ .no_emitter = "composed-block-icmp-rhs" } };
        }
        if (icmp.rhs == .int) {
            const immediate = try i64Value(icmp.rhs.int);
            if (immediate != 0 and integer_bits == 64)
                return scratchCompareAction(icmp, .{ .immediate = icmp.rhs.int });
        }
        return .legacy;
    }
    if ((icmp.predicate == .ult or icmp.predicate == .ugt) and
        bits == 16 and icmp.rhs == .int)
    {
        _ = u16BitPattern(icmp.rhs.int) catch
            return .{ .diagnostic = .{ .no_emitter = "composed-block-icmp-rhs" } };
        return scratchCompareAction(icmp, .{ .immediate = icmp.rhs.int });
    }
    if (icmp.predicate == .ugt and (bits == 32 or bits == 64)) {
        return switch (icmp.rhs) {
            .named => scratchCompareAction(icmp, .named),
            .int => scratchCompareAction(icmp, .{ .immediate = icmp.rhs.int }),
            .fp,
            .undef,
            .poison,
            .null_value,
            .zero_initializer,
            .vector,
            .constant_expr,
            => .legacy,
        };
    }
    if (!icmp.samesign and icmp.predicate == .sgt and bits == 64 and icmp.rhs == .int)
        return scratchCompareAction(icmp, .{ .immediate = icmp.rhs.int });
    if (icmp.predicate == .slt) {
        if (bits == 128 and icmp.rhs.eql(.{ .int = 0 })) return .legacy;
        if ((bits == 64 or bits == 32) and icmp.rhs.eql(.{ .int = 0 })) return .legacy;
        if (bits == 16 and icmp.rhs.eql(.{ .int = 0 }))
            return scratchCompareAction(icmp, .{ .immediate = 0 });
        if (!icmp.samesign and bits == 64 and icmp.rhs == .int)
            return scratchCompareAction(icmp, .{ .immediate = icmp.rhs.int });
    }
    if (!icmp.samesign and (icmp.predicate == .slt or icmp.predicate == .sgt) and
        icmp.rhs == .named and (bits == 16 or bits == 32 or bits == 64))
    {
        return scratchCompareAction(icmp, .named);
    }
    if (icmp.predicate == .ult) {
        if (icmp.samesign and (bits == 6 or bits == 7) and icmp.rhs == .int)
            return .legacy;
        if (!icmp.samesign and bits == 6 and icmp.rhs == .int)
            return .legacy;
        if (bits == 32 and icmp.rhs == .named)
            return scratchCompareAction(icmp, .named);
        if (bits == 64) {
            return switch (icmp.rhs) {
                .int => scratchCompareAction(icmp, .{ .immediate = icmp.rhs.int }),
                .named => if (!icmp.samesign)
                    scratchCompareAction(icmp, .named)
                else
                    .{ .diagnostic = .{ .no_emitter = "composed-block-icmp-rhs" } },
                .fp,
                .undef,
                .poison,
                .null_value,
                .zero_initializer,
                .vector,
                .constant_expr,
                => .{ .diagnostic = .{ .no_emitter = "composed-block-icmp-rhs" } },
            };
        }
    }
    return .legacy;
}

fn scratchCompareAction(
    icmp: ir.IcmpInst,
    rhs: ScratchCompareSemanticRhs,
) ScratchCompareDispatch {
    return .{ .action = .{
        .operand_ty = icmp.operand_ty,
        .predicate = icmp.predicate,
        .samesign = icmp.samesign,
        .rhs = rhs,
    } };
}

fn lowerScratchCompare(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    icmp: ir.IcmpInst,
    action: ScratchCompareSemantic,
) !?Diagnostic {
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const expected = scratchCompareExpected(action.operand_ty);
    const lhs_request = try transaction.register(.{
        .source = icmp.lhs,
        .expected = expected,
        .form = .scratch_compare_operand,
        .destination = .prepared_view,
    });
    const rhs_request: ?ValueUseTransaction.RequestHandle = switch (action.rhs) {
        .named => try transaction.register(.{
            .source = icmp.rhs,
            .expected = expected,
            .form = .scratch_compare_operand,
            .destination = .prepared_source,
        }),
        .immediate, .null_pointer => null,
    };
    try transaction.attachScratchCompareAction(lhs_request, .{
        .result = try ValueUseTransaction.ActionIdentity.init(result_name),
        .operand_ty = action.operand_ty,
        .predicate = action.predicate,
        .samesign = action.samesign,
        .rhs = switch (action.rhs) {
            .immediate => |immediate| .{ .immediate = immediate },
            .null_pointer => .null_pointer,
            .named => .{ .named = rhs_request.? },
        },
    });
    transaction.seal() catch |err|
        return scratchCompareDiagnostic(&transaction, lhs_request, rhs_request, err) orelse return err;
    _ = try transaction.beginAccumulatorSession();
    transaction.prepare() catch |err|
        return scratchCompareDiagnostic(&transaction, lhs_request, rhs_request, err) orelse return err;
    transaction.materializeAll() catch |err|
        return scratchCompareDiagnostic(&transaction, lhs_request, rhs_request, err) orelse return err;
    const lease = transaction.preparedView(lhs_request) catch |err|
        return scratchCompareDiagnostic(&transaction, lhs_request, rhs_request, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return scratchCompareDiagnostic(&transaction, lhs_request, rhs_request, err) orelse return err;
    try transaction.commit();
    return null;
}

fn scratchCompareExpected(ty: ir.Type) ValueUseTransaction.Expected {
    return switch (ty) {
        .int => |bits| .{
            .ty = ty,
            .register_class = if (bits <= 32) .gpr32 else .gpr64,
        },
        .ptr => .{
            .ty = ty,
            .register_class = .gpr64,
            .pointer_address_space = 0,
        },
        else => unreachable,
    };
}

fn scratchCompareDiagnostic(
    transaction: *const ValueUseTransaction,
    lhs_request: ValueUseTransaction.RequestHandle,
    rhs_request: ?ValueUseTransaction.RequestHandle,
    err: anyerror,
) ?Diagnostic {
    if (err == error.ValueUseActionDiagnostic) return transaction.actionDiagnostic();
    if (transaction.failedRequestIs(lhs_request))
        return .{ .unsupported_value = "composed-block-icmp-lhs" };
    if (rhs_request) |request| {
        if (transaction.failedRequestIs(request))
            return .{ .unsupported_value = "composed-block-icmp-rhs" };
    }
    return null;
}

/// Pure semantic dispatch for audit row I13. Fixed-scratch and exact-EI
/// precedence is enforced by the caller before this classifier is consulted.
fn isCurrentHomeEqZeroIcmp(icmp: ir.IcmpInst) bool {
    if (icmp.predicate != .eq or icmp.operand_ty != .int) return false;
    return switch (icmp.rhs) {
        .int => |value| value == 0,
        .named,
        .fp,
        .undef,
        .poison,
        .null_value,
        .zero_initializer,
        .vector,
        .constant_expr,
        => false,
    };
}

fn lowerCurrentHomeEqZeroIcmp(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    icmp: ir.IcmpInst,
) !?Diagnostic {
    const bits = intBits(icmp.operand_ty) orelse unreachable;
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const lhs_request = try transaction.register(.{
        .source = icmp.lhs,
        .expected = .{
            .ty = icmp.operand_ty,
            .register_class = if (bits <= 32) .gpr32 else .gpr64,
        },
        .form = .current_home_eq_zero_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .current_home_eq_zero = .{
            .result = try ValueUseTransaction.ActionIdentity.init(result_name),
            .operand_ty = icmp.operand_ty,
        } },
    });
    transaction.seal() catch |err|
        return currentHomeEqZeroDiagnostic(&transaction, lhs_request, icmp.operand_ty, err) orelse return err;
    _ = try transaction.beginAccumulatorSession();
    transaction.prepare() catch |err|
        return currentHomeEqZeroDiagnostic(&transaction, lhs_request, icmp.operand_ty, err) orelse return err;
    transaction.materializeAll() catch |err|
        return currentHomeEqZeroDiagnostic(&transaction, lhs_request, icmp.operand_ty, err) orelse return err;
    const lease = transaction.preparedView(lhs_request) catch |err|
        return currentHomeEqZeroDiagnostic(&transaction, lhs_request, icmp.operand_ty, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return currentHomeEqZeroDiagnostic(&transaction, lhs_request, icmp.operand_ty, err) orelse return err;
    try transaction.commit();
    return null;
}

fn currentHomeEqZeroDiagnostic(
    transaction: *const ValueUseTransaction,
    lhs_request: ValueUseTransaction.RequestHandle,
    operand_ty: ir.Type,
    err: anyerror,
) ?Diagnostic {
    if (err == error.ValueUseActionDiagnostic) return transaction.actionDiagnostic();
    if (!transaction.failedRequestIs(lhs_request)) return null;
    return switch (err) {
        error.ValueUseUnresolvedSource => .{ .unsupported_value = "composed-block-icmp-lhs" },
        error.ValueUseCurrentHomeEqZeroWidthUnsupported => .{ .no_emitter = "composed-block-icmp-lhs-width" },
        error.ValueUseCurrentHomeEqZeroLocationUnsupported => .{ .no_emitter = "composed-block-icmp-lhs-loc" },
        // The frozen request validator rejects widths above 64 before the
        // action observes a home. Canonical i128 bindings use pair homes, all
        // of which the legacy I13 branch classified as a location failure.
        error.ValueUseTypeMismatch => if (operand_ty == .int and operand_ty.int > 64)
            .{ .no_emitter = "composed-block-icmp-lhs-loc" }
        else
            .{ .no_emitter = "composed-block-icmp-lhs-width" },
        else => null,
    };
}

pub fn lowerIcmp(selector: *ComposedBlockSelector, result: ?[]const u8, icmp: ir.IcmpInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    switch (try classifyScratchCompare(icmp)) {
        .legacy => {},
        .diagnostic => |diagnostic| return diagnostic,
        .action => |action| return lowerScratchCompare(selector, result_name, icmp, action),
    }
    const exact_ei_narrow = isExactEiNarrowIcmp(selector, icmp);
    if (!exact_ei_narrow and isCurrentHomeEqZeroIcmp(icmp))
        return lowerCurrentHomeEqZeroIcmp(selector, result_name, icmp);
    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
    defer transaction.deinit();
    while (try selector_state.liveAccumulatorNameAfterCurrent(selector)) |live_name| {
        if (try selector_state.preserveLiveAccumulatorValue(selector, live_name)) |diagnostic| return diagnostic;
    }
    if (exact_ei_narrow) return lowerExactEiNarrowIcmp(&transaction, result_name, icmp);
    if (icmp.predicate == .eq and icmp.operand_ty.eql(.{ .int = 128 }) and switch (icmp.rhs) {
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
        if (try prepareIcmpResult(&transaction)) |diagnostic| return diagnostic;
        try selector_state.clobberArgReg(selector, temp);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = pair.hi });
        try selector.machine.instructions.append(selector.allocator, switch (temp) {
            .rcx => .{ .mov_imm_rcx = std.math.minInt(i64) },
            .r8 => .{ .mov_imm_r8 = std.math.minInt(i64) },
            else => unreachable,
        });
        try emitIcmpWrite(&transaction, .{ .binary_arg_rax = .{ .op = .xor, .reg = temp } });
        try emitIcmpWrite(&transaction, .{ .binary_arg_rax = .{ .op = .@"or", .reg = pair.lo } });
        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = temp });
        try emitIcmpDefinition(&transaction, .{ .cmp_arg64_imm64 = .{ .reg = temp, .imm = 0 } });
        if (try emitIcmpSetcc(&transaction, .sete_eax)) |diagnostic| return diagnostic;
    } else if (icmp.predicate == .eq) {
        const bits = intBits(icmp.operand_ty) orelse return .{ .no_emitter = "composed-block-icmp-type" };
        const rhs = switch (icmp.rhs) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .no_emitter = "composed-block-icmp-rhs" },
        };
        const imm = try i64Value(rhs);
        std.debug.assert(imm != 0);
        if (bits <= 32) {
            selector_state.emitValueIntoEax(selector, icmp.lhs) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
            try emitIcmpDefinition(&transaction, .{ .cmp_eax_imm32 = try i32Value(rhs) });
        } else return .{ .no_emitter = "composed-block-icmp-eq-rhs" };
        if (try emitIcmpSetcc(&transaction, .sete_eax)) |diagnostic| return diagnostic;
        try finishIcmpResult(&transaction, result_name);
        return null;
    } else if (icmp.predicate == .sgt and icmp.operand_ty.eql(.{ .int = 6 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == -1,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        try selector_state.emitValueIntoEax(selector, icmp.lhs);
        if (try prepareIcmpResult(&transaction)) |diagnostic| return diagnostic;
        try emitIcmpDefinition(&transaction, .{ .and_eax_imm32 = 1 << 5 });
        if (try emitIcmpSetcc(&transaction, .sete_eax)) |diagnostic| return diagnostic;
    } else if (icmp.predicate == .sgt and icmp.operand_ty.eql(.{ .int = 16 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == -1,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        try selector_state.emitValueIntoEax(selector, icmp.lhs);
        if (try prepareIcmpResult(&transaction)) |diagnostic| return diagnostic;
        try emitIcmpDefinition(&transaction, .{ .and_eax_imm32 = 1 << 15 });
        if (try emitIcmpSetcc(&transaction, .sete_eax)) |diagnostic| return diagnostic;
    } else if (icmp.predicate == .sgt and icmp.operand_ty.eql(.{ .int = 32 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == -1,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        try selector_state.emitValueIntoEax(selector, icmp.lhs);
        if (try prepareIcmpResult(&transaction)) |diagnostic| return diagnostic;
        try emitIcmpDefinition(&transaction, .{ .and_eax_imm32 = std.math.minInt(i32) });
        if (try emitIcmpSetcc(&transaction, .sete_eax)) |diagnostic| return diagnostic;
    } else if (icmp.predicate == .sgt and icmp.operand_ty.eql(.{ .int = 32 }) and icmp.rhs == .int) {
        try selector_state.emitValueIntoEax(selector, icmp.lhs);
        try emitIcmpDefinition(&transaction, .{ .cmp_eax_imm32 = try i32Value(icmp.rhs.int) });
        if (try emitIcmpSetcc(&transaction, .setg_eax)) |diagnostic| return diagnostic;
    } else if (icmp.predicate == .slt and icmp.operand_ty.eql(.{ .int = 128 }) and switch (icmp.rhs) {
        .int => |int| int == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        selector_state.emitPairHighLaneIntoRax(selector, icmp.lhs) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        if (try prepareIcmpResult(&transaction)) |diagnostic| return diagnostic;
        try emitIcmpWrite(&transaction, .{ .shr_rax_imm6 = 63 });
    } else if (icmp.predicate == .slt and icmp.operand_ty.eql(.{ .int = 64 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        if (try selector_state.preserveCurrentRaxIntoScratch(selector)) |diagnostic| return diagnostic;
        try selector_state.emitValueIntoRax(selector, icmp.lhs);
        if (try prepareIcmpResult(&transaction)) |diagnostic| return diagnostic;
        try emitIcmpWrite(&transaction, .{ .shr_rax_imm6 = 63 });
    } else if (icmp.predicate == .slt and icmp.operand_ty.eql(.{ .int = 32 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        if (try selector_state.preserveCurrentEaxIntoScratch(selector)) |diagnostic| return diagnostic;
        try selector_state.emitValueIntoEax(selector, icmp.lhs);
        if (try prepareIcmpResult(&transaction)) |diagnostic| return diagnostic;
        try emitIcmpWrite(&transaction, .{ .shr_eax_imm5 = 31 });
    } else if (!icmp.samesign and icmp.predicate == .slt and icmp.rhs == .int and
        icmp.operand_ty.eql(.{ .int = 32 }))
    {
        try selector_state.emitValueIntoEax(selector, icmp.lhs);
        try emitIcmpDefinition(&transaction, .{ .cmp_eax_imm32 = try i32Value(icmp.rhs.int) });
        if (try emitIcmpSetcc(&transaction, .setl_eax)) |diagnostic| return diagnostic;
    } else if (icmp.samesign and (icmp.predicate == .ult or icmp.predicate == .ugt) and
        (icmp.operand_ty.eql(.{ .int = 6 }) or icmp.operand_ty.eql(.{ .int = 7 })) and icmp.rhs == .int)
    {
        const bits: u16 = if (icmp.operand_ty.eql(.{ .int = 6 })) 6 else 7;
        const mask: i32 = if (bits == 6) 63 else 127;
        const imm = try i64Value(icmp.rhs.int);
        if (imm < 0 or imm > mask) return .{ .no_emitter = "composed-block-icmp-rhs" };
        try selector_state.emitValueIntoEax(selector, icmp.lhs);
        try emitIcmpWrite(&transaction, .{ .and_eax_imm32 = mask });
        try emitIcmpDefinition(&transaction, .{ .cmp_eax_imm32 = @intCast(imm) });
        if (try emitIcmpSetcc(&transaction, if (icmp.predicate == .ult) .setb_eax else .seta_eax)) |diagnostic| return diagnostic;
    } else if (!icmp.samesign and icmp.predicate == .ult and icmp.operand_ty.eql(.{ .int = 6 }) and
        icmp.lhs == .named and switch (icmp.rhs) {
        .int => |value| (value & 63) == 51,
        else => false,
    }) {
        try selector_state.emitValueIntoEax(selector, icmp.lhs);
        try emitIcmpWrite(&transaction, .{ .and_eax_imm32 = 63 });
        try emitIcmpDefinition(&transaction, .{ .cmp_eax_imm32 = 51 });
        if (try emitIcmpSetcc(&transaction, .setb_eax)) |diagnostic| return diagnostic;
    } else if (icmp.predicate == .ult and icmp.operand_ty.eql(.{ .int = 32 }) and icmp.rhs == .int) {
        try selector_state.emitValueIntoEax(selector, icmp.lhs);
        try emitIcmpDefinition(&transaction, .{ .cmp_eax_imm32 = try i32Value(icmp.rhs.int) });
        if (try emitIcmpSetcc(&transaction, .setb_eax)) |diagnostic| return diagnostic;
    } else return .{ .no_emitter = "composed-block-icmp-form" };
    try finishIcmpResult(&transaction, result_name);
    return null;
}

fn isExactEiNarrowIcmp(selector: *const ComposedBlockSelector, icmp: ir.IcmpInst) bool {
    const function = selector.function orelse return false;
    if (!stage2_planning.isExactEiScalarFamily(function.*)) return false;
    const bits = intBits(icmp.operand_ty) orelse return false;
    return bits == 3 or bits == 4 or bits == 5 or bits == 13 or bits == 14 or bits == 26 or bits == 27 or bits == 55 or bits == 56;
}

fn lowerExactEiNarrowIcmp(transaction: *selector_state.AccumulatorDefinitionTransaction, result_name: []const u8, icmp: ir.IcmpInst) !?Diagnostic {
    const selector = transaction.selector;
    const bits = intBits(icmp.operand_ty) orelse unreachable;
    const rhs = switch (icmp.rhs) {
        .int => |value| value,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .no_emitter = "composed-block-ei-narrow-icmp-rhs" },
    };
    if (bits > 32) return .{ .no_emitter = "composed-block-ei-narrow-icmp-width" };
    const unsigned_mask: u32 = (@as(u32, 1) << @intCast(bits)) - 1;
    const rhs_bits: u32 = @intCast(rhs & @as(i128, unsigned_mask));
    try selector_state.emitValueIntoEax(selector, icmp.lhs);
    try emitIcmpWrite(transaction, .{ .and_eax_imm32 = @bitCast(unsigned_mask) });
    const signed = icmp.predicate == .slt or icmp.predicate == .sle or icmp.predicate == .sgt or icmp.predicate == .sge;
    var compare_rhs: i32 = @bitCast(rhs_bits);
    if (signed) {
        const shift: u5 = @intCast(32 - bits);
        try emitIcmpWrite(transaction, .{ .shl_eax_imm5 = shift });
        try emitIcmpWrite(transaction, .{ .sar_eax_imm5 = shift });
        const shifted_rhs: i32 = @bitCast(rhs_bits << shift);
        compare_rhs = shifted_rhs >> shift;
    }
    try emitIcmpDefinition(transaction, .{ .cmp_eax_imm32 = compare_rhs });
    if (try emitIcmpSetcc(transaction, switch (icmp.predicate) {
        .eq => .sete_eax,
        .ne => .setne_eax,
        .ult => .setb_eax,
        .ugt => .seta_eax,
        .slt => .setl_eax,
        .sgt => .setg_eax,
        .ule, .uge, .sle, .sge => return .{ .no_emitter = "composed-block-ei-narrow-icmp-predicate" },
    })) |diagnostic| return diagnostic;
    try finishIcmpResult(transaction, result_name);
    return null;
}

fn prepareIcmpResult(transaction: *selector_state.AccumulatorDefinitionTransaction) !?Diagnostic {
    if (transaction.isPrepared()) return null;
    return transaction.prepare(.preserve, .spill_live);
}

fn emitIcmpSetcc(
    transaction: *selector_state.AccumulatorDefinitionTransaction,
    instruction: @import("../machine.zig").Instruction,
) !?Diagnostic {
    if (try prepareIcmpResult(transaction)) |diagnostic| return diagnostic;
    try selector_state.emitEflagsInstruction(transaction.selector, instruction, .use);
    return null;
}

fn emitIcmpDefinition(
    transaction: *selector_state.AccumulatorDefinitionTransaction,
    instruction: @import("../machine.zig").Instruction,
) !void {
    try selector_state.emitEflagsInstruction(transaction.selector, instruction, .definition);
}

fn emitIcmpWrite(
    transaction: *selector_state.AccumulatorDefinitionTransaction,
    instruction: @import("../machine.zig").Instruction,
) !void {
    try selector_state.emitEflagsInstruction(transaction.selector, instruction, .write);
}

fn finishIcmpResult(transaction: *selector_state.AccumulatorDefinitionTransaction, result_name: []const u8) !void {
    try transaction.define(result_name, .zeroExtending(1));
    try transaction.commit();
}

fn normalizeNamedI16CompareOperands(transaction: *selector_state.AccumulatorDefinitionTransaction) !void {
    try emitIcmpWrite(transaction, .{ .shl_rcx_imm6 = 48 });
    try emitIcmpWrite(transaction, .{ .sar_arg64_imm6 = .{ .reg = .rcx, .amount = 48 } });
    try emitIcmpWrite(transaction, .{ .shl_r8_imm6 = 48 });
    try emitIcmpWrite(transaction, .{ .sar_arg64_imm6 = .{ .reg = .r8, .amount = 48 } });
}
