//! Mandatory width semantics precede every selector, including legacy envelopes.
//! Optional instruction-form rewrites remain in the selector. Each mandatory
//! stage runs once and must discharge its invariant; selection cannot retry the
//! original function when this phase fails.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const integers = @import("integer_forms.zig");
const comparisons = @import("comparison_forms.zig");
const legacy = @import("legacy_forms.zig");
const phi_values = @import("phi_values.zig");
const call_values = @import("call_values.zig");
const select_values = @import("select_values.zig");
const profiling = @import("../../../compilation_profile.zig");

pub const Function = struct {
    ir_function: ir.Function,
    whole_function: ?legacy.Form = null,
};

pub fn check(function: ir.Function) !void {
    if (phi_values.requiresNormalization(function) or call_values.requiresNormalization(function) or select_values.requiresNormalization(function) or
        integers.requiresNormalization(function) or comparisons.requiresNarrowNormalization(function))
        return error.UnsupportedSemanticNormalization;
}

/// The caller owns an arena for private instructions. Source definitions and
/// the function's ABI remain borrowed and unchanged. Bounded stages avoid a
/// recursive fixed-point search and make failure to normalize explicit.
pub fn normalize(allocator: std.mem.Allocator, source: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !Function {
    return normalizeProfiled(allocator, source, context, null);
}

pub fn normalizeProfiled(allocator: std.mem.Allocator, source: ir.Function, context: ?*const machine.ReadOnlyModuleContext, profile: ?*profiling.Profile) !Function {
    var function = source;
    {
        const activity = profiling.activity(profile, "normalize-phi-values");
        defer activity.end();
        if (phi_values.requiresNormalization(function)) function = try phi_values.normalize(allocator, function);
    }
    {
        const activity = profiling.activity(profile, "normalize-call-values");
        defer activity.end();
        if (call_values.requiresNormalization(function)) function = try call_values.normalize(allocator, function);
    }
    {
        const activity = profiling.activity(profile, "normalize-select-values");
        defer activity.end();
        if (select_values.requiresNormalization(function)) function = try select_values.normalize(allocator, function);
    }
    {
        const activity = profiling.activity(profile, "recognize-legacy-envelope");
        defer activity.end();
        if (legacy.recognize(function)) |form| return .{ .ir_function = function, .whole_function = form };
    }
    {
        const activity = profiling.activity(profile, "normalize-narrow-comparisons");
        defer activity.end();
        if (comparisons.requiresNarrowNormalization(function))
            function = (try comparisons.legalize(allocator, function, context)) orelse return error.UnsupportedSemanticNormalization;
    }
    {
        const activity = profiling.activity(profile, "normalize-integers");
        defer activity.end();
        if (integers.requiresNormalization(function))
            function = (try integers.legalize(allocator, function)) orelse return error.UnsupportedSemanticNormalization;
    }
    {
        const activity = profiling.activity(profile, "check-normalized-invariants");
        defer activity.end();
        try check(function);
    }
    if (!function.ret_ty.eql(source.ret_ty) or function.params.items.ptr != source.params.items.ptr)
        return error.SemanticNormalizationChangedAbi;
    return .{ .ir_function = function };
}
