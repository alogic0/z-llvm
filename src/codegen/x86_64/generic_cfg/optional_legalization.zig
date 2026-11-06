//! Ordered optional rewrites. The driver, not individual legalizers, owns
//! retry policy and termination. Semantic normalization is mandatory each time.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const profiling = @import("../../../compilation_profile.zig");

pub const Rewrite = struct {
    function: ir.Function,
    retry_original: bool,
    retain_labels: bool = false,
};

pub const Budget = struct {
    remaining: usize = 1024,
    pub fn consume(budget: *Budget) !void {
        if (budget.remaining == 0) return error.OptionalLegalizationLimitExceeded;
        budget.remaining -= 1;
    }
};

pub fn next(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext, profile: ?*profiling.Profile) !?Rewrite {
    const scope = profiling.enter(profile, .legalize);
    defer scope.end();
    if (profile) |p| p.attempt("aligned_stack.zig.legalize");
    if (try @import("aligned_stack.zig").legalize(allocator, function, context)) |rewritten| {
        if (profile) |p| p.rewritten("aligned_stack.zig.legalize");
        return .{ .function = rewritten, .retry_original = false, .retain_labels = false };
    }
    if (profile) |p| p.attempt("integer_vectors.zig.legalize");
    if (try @import("integer_vectors.zig").legalize(allocator, function, context)) |rewritten| {
        if (profile) |p| p.rewritten("integer_vectors.zig.legalize");
        return .{ .function = rewritten, .retry_original = false, .retain_labels = false };
    }
    if (profile) |p| p.attempt("pair_memory.zig.legalize");
    if (try @import("pair_memory.zig").legalize(allocator, function, context)) |rewritten| {
        if (profile) |p| p.rewritten("pair_memory.zig.legalize");
        return .{ .function = rewritten, .retry_original = false, .retain_labels = false };
    }
    if (profile) |p| p.attempt("wide_integer_forms.zig.legalize");
    if (try @import("wide_integer_forms.zig").legalize(allocator, function)) |rewritten| {
        if (profile) |p| p.rewritten("wide_integer_forms.zig.legalize");
        return .{ .function = rewritten, .retry_original = false, .retain_labels = false };
    }
    if (profile) |p| p.attempt("overflow_values.zig.legalize");
    if (try @import("overflow_values.zig").legalize(allocator, function)) |rewritten| {
        if (profile) |p| p.rewritten("overflow_values.zig.legalize");
        return .{ .function = rewritten, .retry_original = false, .retain_labels = false };
    }
    if (profile) |p| p.attempt("comparison_forms.zig.legalize");
    if (try @import("comparison_forms.zig").legalize(allocator, function, context)) |rewritten| {
        if (profile) |p| p.rewritten("comparison_forms.zig.legalize");
        return .{ .function = rewritten, .retry_original = true, .retain_labels = false };
    }
    if (profile) |p| p.attempt("word_arithmetic.zig.legalize");
    if (try @import("word_arithmetic.zig").legalize(allocator, function)) |rewritten| {
        if (profile) |p| p.rewritten("word_arithmetic.zig.legalize");
        return .{ .function = rewritten, .retry_original = true, .retain_labels = false };
    }
    if (profile) |p| p.attempt("integer_forms.zig.legalize");
    if (try @import("integer_forms.zig").legalize(allocator, function)) |rewritten| {
        if (profile) |p| p.rewritten("integer_forms.zig.legalize");
        return .{ .function = rewritten, .retry_original = true, .retain_labels = false };
    }
    if (profile) |p| p.attempt("pair_arithmetic.zig.legalize");
    if (try @import("pair_arithmetic.zig").legalize(allocator, function)) |rewritten| {
        if (profile) |p| p.rewritten("pair_arithmetic.zig.legalize");
        return .{ .function = rewritten, .retry_original = true, .retain_labels = false };
    }
    if (profile) |p| p.attempt("integer_intrinsics.zig.legalize");
    if (try @import("integer_intrinsics.zig").legalize(allocator, function)) |rewritten| {
        if (profile) |p| p.rewritten("integer_intrinsics.zig.legalize");
        return .{ .function = rewritten, .retry_original = false, .retain_labels = false };
    }
    if (profile) |p| p.attempt("scalar_forms.zig.legalize");
    if (try @import("scalar_forms.zig").legalize(allocator, function)) |rewritten| {
        if (profile) |p| p.rewritten("scalar_forms.zig.legalize");
        return .{ .function = rewritten, .retry_original = false, .retain_labels = false };
    }
    if (profile) |p| p.attempt("switch_phi_edges.zig.legalize");
    if (try @import("switch_phi_edges.zig").legalize(allocator, function)) |rewritten| {
        if (profile) |p| p.rewritten("switch_phi_edges.zig.legalize");
        return .{ .function = rewritten, .retry_original = true, .retain_labels = true };
    }
    if (profile) |p| p.attempt("switch_forms.zig.legalize");
    if (try @import("switch_forms.zig").legalize(allocator, function)) |rewritten| {
        if (profile) |p| p.rewritten("switch_forms.zig.legalize");
        return .{ .function = rewritten, .retry_original = false, .retain_labels = true };
    }
    if (profile) |p| p.attempt("boolean_values.zig.legalize");
    if (try @import("boolean_values.zig").legalize(allocator, function)) |rewritten| {
        if (profile) |p| p.rewritten("boolean_values.zig.legalize");
        return .{ .function = rewritten, .retry_original = false, .retain_labels = false };
    }
    if (profile) |p| p.attempt("narrow_abi.zig.legalize");
    if (try @import("narrow_abi.zig").legalize(allocator, function)) |rewritten| {
        if (profile) |p| p.rewritten("narrow_abi.zig.legalize");
        return .{ .function = rewritten, .retry_original = false, .retain_labels = false };
    }
    if (profile) |p| p.attempt("abi_legalization.zig.integerPair");
    if (try @import("abi_legalization.zig").integerPair(allocator, function)) |rewritten| {
        if (profile) |p| p.rewritten("abi_legalization.zig.integerPair");
        return .{ .function = rewritten, .retry_original = false, .retain_labels = false };
    }
    if (profile) |p| p.attempt("abi_legalization.zig.paddedHalf");
    if (try @import("abi_legalization.zig").paddedHalf(allocator, function)) |rewritten| {
        if (profile) |p| p.rewritten("abi_legalization.zig.paddedHalf");
        return .{ .function = rewritten, .retry_original = false, .retain_labels = false };
    }
    if (profile) |p| p.attempt("word_pair_values.zig.legalize");
    if (try @import("word_pair_values.zig").legalize(allocator, function, context)) |rewritten| {
        if (profile) |p| p.rewritten("word_pair_values.zig.legalize");
        return .{ .function = rewritten, .retry_original = false, .retain_labels = false };
    }
    if (profile) |p| p.attempt("word_pair_memory.zig.legalize");
    if (try @import("word_pair_memory.zig").legalize(allocator, function, context)) |rewritten| {
        if (profile) |p| p.rewritten("word_pair_memory.zig.legalize");
        return .{ .function = rewritten, .retry_original = false, .retain_labels = false };
    }
    if (profile) |p| p.attempt("padded_frame.zig.legalize");
    if (try @import("padded_frame.zig").legalize(allocator, function, context)) |rewritten| {
        if (profile) |p| p.rewritten("padded_frame.zig.legalize");
        return .{ .function = rewritten, .retry_original = false, .retain_labels = false };
    }
    if (profile) |p| p.attempt("padded_frame.zig.legalizeStorage");
    if (try @import("padded_frame.zig").legalizeStorage(allocator, function, context)) |rewritten| {
        if (profile) |p| p.rewritten("padded_frame.zig.legalizeStorage");
        return .{ .function = rewritten, .retry_original = false, .retain_labels = false };
    }
    if (profile) |p| p.attempt("address_forms.zig.legalize");
    if (try @import("address_forms.zig").legalize(allocator, function, context)) |rewritten| {
        if (profile) |p| p.rewritten("address_forms.zig.legalize");
        return .{ .function = rewritten, .retry_original = true, .retain_labels = false };
    }
    if (profile) |p| p.attempt("stack_addresses.zig.legalize");
    if (try @import("stack_addresses.zig").legalize(allocator, function, context)) |rewritten| {
        if (profile) |p| p.rewritten("stack_addresses.zig.legalize");
        return .{ .function = rewritten, .retry_original = true, .retain_labels = false };
    }
    if (profile) |p| p.attempt("pointer_values.zig.legalize");
    if (try @import("pointer_values.zig").legalize(allocator, function, context)) |rewritten| {
        if (profile) |p| p.rewritten("pointer_values.zig.legalize");
        return .{ .function = rewritten, .retry_original = true, .retain_labels = false };
    }
    if (profile) |p| p.attempt("global_memory.zig.legalize");
    if (try @import("global_memory.zig").legalize(allocator, function, context)) |rewritten| {
        if (profile) |p| p.rewritten("global_memory.zig.legalize");
        return .{ .function = rewritten, .retry_original = false, .retain_labels = false };
    }
    if (profile) |p| p.attempt("block_order.zig.legalize");
    if (try @import("block_order.zig").legalize(allocator, function)) |rewritten| {
        if (profile) |p| p.rewritten("block_order.zig.legalize");
        return .{ .function = rewritten, .retry_original = true, .retain_labels = false };
    }
    return null;
}

test "optional legalization budget fails closed instead of recursing indefinitely" {
    var budget: Budget = .{ .remaining = 2 };
    try budget.consume();
    try budget.consume();
    try std.testing.expectError(error.OptionalLegalizationLimitExceeded, budget.consume());
    try std.testing.expectEqual(0, budget.remaining);
}
