const std = @import("std");
const ir = @import("../../../ir.zig");
const inspection = @import("inspection.zig");
const stage2_planning = @import("stage2_planning.zig");
const composed_helpers = @import("composed_helpers.zig");
const selector_state = @import("composed_selector_state.zig");
const value_use = @import("composed_selector_value_use_transaction.zig");

const ValueUseTransaction = value_use.ValueUseTransaction;
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

/// Pure semantic dispatch for the nine ordinary setcc-producing EAX forms.
/// Exact-EI admission remains owned by isExactEiNarrowIcmp and is deliberately
/// not duplicated here.
fn isSetccEaxCompareIcmp(icmp: ir.IcmpInst) bool {
    const bits = intBits(icmp.operand_ty) orelse return false;
    const immediate = switch (icmp.rhs) {
        .int => |value| value,
        .named,
        .fp,
        .undef,
        .poison,
        .null_value,
        .zero_initializer,
        .vector,
        .constant_expr,
        => return false,
    };
    if (icmp.predicate == .eq and bits <= 32 and immediate != 0) return true;
    if (icmp.predicate == .sgt and
        ((immediate == -1 and (bits == 6 or bits == 16 or bits == 32)) or bits == 32))
    {
        return true;
    }
    if (!icmp.samesign and icmp.predicate == .slt and bits == 32 and immediate != 0)
        return true;
    if (icmp.samesign and (icmp.predicate == .ult or icmp.predicate == .ugt) and
        (bits == 6 or bits == 7))
    {
        const mask: i128 = if (bits == 6) 63 else 127;
        return immediate >= 0 and immediate <= mask;
    }
    if (!icmp.samesign and icmp.predicate == .ult and bits == 6 and
        icmp.lhs == .named and (immediate & 63) == 51)
    {
        return true;
    }
    return icmp.predicate == .ult and bits == 32;
}

fn lowerSetccEaxCompare(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    icmp: ir.IcmpInst,
    structure: ValueUseTransaction.SetccEaxCompareStructure,
) !?Diagnostic {
    const bits = intBits(icmp.operand_ty) orelse unreachable;
    const immediate = switch (icmp.rhs) {
        .int => |value| value,
        .named,
        .fp,
        .undef,
        .poison,
        .null_value,
        .zero_initializer,
        .vector,
        .constant_expr,
        => unreachable,
    };
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const lhs_request = try transaction.register(.{
        .source = icmp.lhs,
        .expected = .{
            .ty = icmp.operand_ty,
            .register_class = if (bits <= 32) .gpr32 else .gpr64,
        },
        .form = .setcc_eax_compare_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .setcc_eax_compare = .{
            .result = try ValueUseTransaction.ActionIdentity.init(result_name),
            .operand_ty = icmp.operand_ty,
            .predicate = icmp.predicate,
            .samesign = icmp.samesign,
            .immediate = immediate,
            .structure = structure,
        } },
    });
    transaction.seal() catch |err|
        return setccEaxCompareDiagnostic(&transaction, lhs_request, err) orelse return err;
    _ = try transaction.beginAccumulatorSession();
    transaction.prepare() catch |err|
        return setccEaxCompareDiagnostic(&transaction, lhs_request, err) orelse return err;
    transaction.materializeAll() catch |err|
        return setccEaxCompareDiagnostic(&transaction, lhs_request, err) orelse return err;
    const lease = transaction.preparedView(lhs_request) catch |err|
        return setccEaxCompareDiagnostic(&transaction, lhs_request, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return setccEaxCompareDiagnostic(&transaction, lhs_request, err) orelse return err;
    try transaction.commit();
    return null;
}

fn setccEaxCompareDiagnostic(
    transaction: *const ValueUseTransaction,
    lhs_request: ValueUseTransaction.RequestHandle,
    err: anyerror,
) ?Diagnostic {
    if (err == error.ValueUseActionDiagnostic) return transaction.actionDiagnostic();
    if (!transaction.failedRequestIs(lhs_request)) return null;
    return switch (err) {
        error.ValueUseUnresolvedSource => .{ .unsupported_value = "composed-block-icmp-lhs" },
        error.ValueUseSetccEaxCompareWidthUnsupported => .{ .no_emitter = "composed-block-icmp-lhs-width" },
        error.ValueUseSetccEaxCompareLocationUnsupported => .{ .no_emitter = "composed-block-icmp-lhs-loc" },
        else => null,
    };
}

fn lowerCurrentHomeSignBitIcmp(
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
        .form = .current_home_sign_bit_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .current_home_sign_bit = .{
            .result = try ValueUseTransaction.ActionIdentity.init(result_name),
            .operand_ty = icmp.operand_ty,
        } },
    });
    transaction.seal() catch |err|
        return currentHomeSignBitDiagnostic(&transaction, lhs_request, err) orelse return err;
    _ = try transaction.beginAccumulatorSession();
    transaction.prepare() catch |err|
        return currentHomeSignBitDiagnostic(&transaction, lhs_request, err) orelse return err;
    transaction.materializeAll() catch |err|
        return currentHomeSignBitDiagnostic(&transaction, lhs_request, err) orelse return err;
    const lease = transaction.preparedView(lhs_request) catch |err|
        return currentHomeSignBitDiagnostic(&transaction, lhs_request, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return currentHomeSignBitDiagnostic(&transaction, lhs_request, err) orelse return err;
    try transaction.commit();
    return null;
}

fn currentHomeSignBitDiagnostic(
    transaction: *const ValueUseTransaction,
    lhs_request: ValueUseTransaction.RequestHandle,
    err: anyerror,
) ?Diagnostic {
    if (err == error.ValueUseActionDiagnostic) return transaction.actionDiagnostic();
    if (!transaction.failedRequestIs(lhs_request)) return null;
    return switch (err) {
        error.ValueUseUnresolvedSource => .{ .unsupported_value = "composed-block-icmp-lhs" },
        error.ValueUseCurrentHomeSignBitWidthUnsupported => .{ .no_emitter = "composed-block-icmp-lhs-width" },
        error.ValueUseCurrentHomeSignBitLocationUnsupported => .{ .no_emitter = "composed-block-icmp-lhs-loc" },
        else => null,
    };
}

fn lowerI128EqMinIcmp(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    icmp: ir.IcmpInst,
) !?Diagnostic {
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const lhs_request = try transaction.register(.{
        .source = icmp.lhs,
        .expected = .{
            .ty = .{ .int = 128 },
            .register_class = .gpr128,
        },
        .form = .i128_icmp_pair_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .i128_eq_min = .{
            .result = try ValueUseTransaction.ActionIdentity.init(result_name),
        } },
    });
    transaction.seal() catch |err|
        return i128PairDiagnostic(&transaction, lhs_request, err) orelse return err;
    _ = try transaction.beginAccumulatorSession();
    transaction.prepare() catch |err|
        return i128PairDiagnostic(&transaction, lhs_request, err) orelse return err;
    transaction.materializeAll() catch |err|
        return i128PairDiagnostic(&transaction, lhs_request, err) orelse return err;
    const lease = transaction.preparedView(lhs_request) catch |err|
        return i128PairDiagnostic(&transaction, lhs_request, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return i128PairDiagnostic(&transaction, lhs_request, err) orelse return err;
    try transaction.commit();
    return null;
}

fn lowerI128SignBitIcmp(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    icmp: ir.IcmpInst,
) !?Diagnostic {
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const lhs_request = try transaction.register(.{
        .source = icmp.lhs,
        .expected = .{
            .ty = .{ .int = 128 },
            .register_class = .gpr128,
        },
        .form = .i128_icmp_pair_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .i128_sign_bit = .{
            .result = try ValueUseTransaction.ActionIdentity.init(result_name),
        } },
    });
    transaction.seal() catch |err|
        return i128PairDiagnostic(&transaction, lhs_request, err) orelse return err;
    _ = try transaction.beginAccumulatorSession();
    transaction.prepare() catch |err|
        return i128PairDiagnostic(&transaction, lhs_request, err) orelse return err;
    transaction.materializeAll() catch |err|
        return i128PairDiagnostic(&transaction, lhs_request, err) orelse return err;
    const lease = transaction.preparedView(lhs_request) catch |err|
        return i128PairDiagnostic(&transaction, lhs_request, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return i128PairDiagnostic(&transaction, lhs_request, err) orelse return err;
    try transaction.commit();
    return null;
}

fn i128PairDiagnostic(
    transaction: *const ValueUseTransaction,
    lhs_request: ValueUseTransaction.RequestHandle,
    err: anyerror,
) ?Diagnostic {
    if (err == error.ValueUseActionDiagnostic) return transaction.actionDiagnostic();
    if (!transaction.failedRequestIs(lhs_request)) return null;
    return switch (err) {
        error.ValueUseUnresolvedSource,
        error.UnsupportedCodegenValue,
        => .{ .unsupported_value = "composed-block-icmp-lhs" },
        error.ValueUseI128PairWidthUnsupported => .{ .no_emitter = "composed-block-icmp-lhs-width" },
        error.ValueUseI128PairLocationUnsupported => .{ .no_emitter = "composed-block-icmp-lhs-loc" },
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
    if (exact_ei_narrow)
        return lowerSetccEaxCompare(selector, result_name, icmp, .exact_ei);
    if (isCurrentHomeEqZeroIcmp(icmp))
        return lowerCurrentHomeEqZeroIcmp(selector, result_name, icmp);
    if (isSetccEaxCompareIcmp(icmp))
        return lowerSetccEaxCompare(selector, result_name, icmp, .ordinary);
    if (ValueUseTransaction.isCurrentHomeSignBitIcmp(icmp))
        return lowerCurrentHomeSignBitIcmp(selector, result_name, icmp);
    if (ValueUseTransaction.isI128EqMinIcmp(icmp))
        return lowerI128EqMinIcmp(selector, result_name, icmp);
    if (ValueUseTransaction.isI128SignBitIcmp(icmp))
        return lowerI128SignBitIcmp(selector, result_name, icmp);
    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
    defer transaction.deinit();
    while (try selector_state.liveAccumulatorNameAfterCurrent(selector)) |live_name| {
        if (try selector_state.preserveLiveAccumulatorValue(selector, live_name)) |diagnostic| return diagnostic;
    }
    return .{ .no_emitter = "composed-block-icmp-form" };
}

fn isExactEiNarrowIcmp(selector: *const ComposedBlockSelector, icmp: ir.IcmpInst) bool {
    const function = selector.function orelse return false;
    if (!stage2_planning.isExactEiScalarFamily(function.*)) return false;
    const bits = intBits(icmp.operand_ty) orelse return false;
    return bits == 3 or bits == 4 or bits == 5 or bits == 13 or bits == 14 or bits == 26 or bits == 27 or bits == 55 or bits == 56;
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
