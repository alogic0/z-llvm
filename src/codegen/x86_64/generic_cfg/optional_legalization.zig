//! Ordered optional rewrites. The driver owns retry policy and termination.
//! Stage order is semantic: every rewrite restarts this search.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const profiling = @import("../../../compilation_profile.zig");

pub const Stage = enum {
    @"aligned_stack.zig.legalize",
    @"integer_vectors.zig.legalize",
    @"integer_memory.zig.legalize",
    @"pair_memory.zig.legalize",
    @"wide_integer_forms.zig.legalize",
    @"flag_pair_values.zig.legalize",
    @"overflow_values.zig.legalize",
    @"comparison_forms.zig.legalize",
    @"word_arithmetic.zig.legalize",
    @"integer_forms.zig.legalize",
    @"pair_arithmetic.zig.legalize",
    @"integer_intrinsics.zig.legalize",
    @"scalar_forms.zig.legalize",
    @"indirect_phi_slots.zig.legalize",
    @"switch_phi_edges.zig.legalize",
    @"switch_forms.zig.legalize",
    @"boolean_values.zig.legalize",
    @"narrow_abi.zig.legalize",
    @"abi_legalization.zig.integerPair",
    @"abi_legalization.zig.paddedHalf",
    @"word_pair_values.zig.legalize",
    @"word_pair_memory.zig.legalize",
    @"padded_frame.zig.legalize",
    @"padded_frame.zig.legalizeStorage",
    @"address_forms.zig.legalize",
    @"stack_addresses.zig.legalize",
    @"pointer_values.zig.legalize",
    @"global_memory.zig.legalize",
    @"block_order.zig.legalize",
};

pub const Rewrite = struct {
    function: ir.Function,
    retry_original: bool,
    retain_labels: bool = false,
    profile_stage: usize,
    profile_allocation_bytes: u64,
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
    inline for (std.enums.values(Stage)) |stage| {
        if (try apply(stage, allocator, function, context, profile)) |rewrite| return rewrite;
    }
    return null;
}

fn apply(comptime stage: Stage, allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext, profile: ?*profiling.Profile) !?Rewrite {
    var attempt = profiling.Attempt.init(profile, @backingInt(stage), @tagName(stage), allocator);
    defer attempt.end();
    const measured = attempt.allocator();
    const candidate = try switch (stage) {
        .@"aligned_stack.zig.legalize" => @import("aligned_stack.zig").legalize(measured, function, context),
        .@"integer_vectors.zig.legalize" => @import("integer_vectors.zig").legalize(measured, function, context),
        .@"integer_memory.zig.legalize" => @import("integer_memory.zig").legalize(measured, function, context),
        .@"pair_memory.zig.legalize" => @import("pair_memory.zig").legalize(measured, function, context),
        .@"wide_integer_forms.zig.legalize" => @import("wide_integer_forms.zig").legalize(measured, function),
        .@"flag_pair_values.zig.legalize" => @import("flag_pair_values.zig").legalize(measured, function),
        .@"overflow_values.zig.legalize" => @import("overflow_values.zig").legalize(measured, function),
        .@"comparison_forms.zig.legalize" => @import("comparison_forms.zig").legalize(measured, function, context),
        .@"word_arithmetic.zig.legalize" => @import("word_arithmetic.zig").legalize(measured, function),
        .@"integer_forms.zig.legalize" => @import("integer_forms.zig").legalize(measured, function),
        .@"pair_arithmetic.zig.legalize" => @import("pair_arithmetic.zig").legalize(measured, function),
        .@"integer_intrinsics.zig.legalize" => @import("integer_intrinsics.zig").legalize(measured, function),
        .@"scalar_forms.zig.legalize" => @import("scalar_forms.zig").legalize(measured, function),
        .@"indirect_phi_slots.zig.legalize" => @import("indirect_phi_slots.zig").legalize(measured, function),
        .@"switch_phi_edges.zig.legalize" => @import("switch_phi_edges.zig").legalize(measured, function),
        .@"switch_forms.zig.legalize" => @import("switch_forms.zig").legalize(measured, function),
        .@"boolean_values.zig.legalize" => @import("boolean_values.zig").legalize(measured, function),
        .@"narrow_abi.zig.legalize" => @import("narrow_abi.zig").legalize(measured, function),
        .@"abi_legalization.zig.integerPair" => @import("abi_legalization.zig").integerPair(measured, function),
        .@"abi_legalization.zig.paddedHalf" => @import("abi_legalization.zig").paddedHalf(measured, function),
        .@"word_pair_values.zig.legalize" => @import("word_pair_values.zig").legalize(measured, function, context),
        .@"word_pair_memory.zig.legalize" => @import("word_pair_memory.zig").legalize(measured, function, context),
        .@"padded_frame.zig.legalize" => @import("padded_frame.zig").legalize(measured, function, context),
        .@"padded_frame.zig.legalizeStorage" => @import("padded_frame.zig").legalizeStorage(measured, function, context),
        .@"address_forms.zig.legalize" => @import("address_forms.zig").legalize(measured, function, context),
        .@"stack_addresses.zig.legalize" => @import("stack_addresses.zig").legalize(measured, function, context),
        .@"pointer_values.zig.legalize" => @import("pointer_values.zig").legalize(measured, function, context),
        .@"global_memory.zig.legalize" => @import("global_memory.zig").legalize(measured, function, context),
        .@"block_order.zig.legalize" => @import("block_order.zig").legalize(measured, function),
    };
    attempt.outcome = if (candidate != null) .rewritten else .unchanged;
    return if (candidate) |rewritten| .{
        .function = rewritten,
        .retry_original = switch (stage) {
            .@"comparison_forms.zig.legalize",
            .@"word_arithmetic.zig.legalize",
            .@"integer_forms.zig.legalize",
            .@"pair_arithmetic.zig.legalize",
            .@"switch_phi_edges.zig.legalize",
            .@"address_forms.zig.legalize",
            .@"stack_addresses.zig.legalize",
            .@"pointer_values.zig.legalize",
            .@"block_order.zig.legalize",
            => true,
            else => false,
        },
        .retain_labels = switch (stage) {
            .@"switch_phi_edges.zig.legalize", .@"switch_forms.zig.legalize" => true,
            else => false,
        },
        .profile_stage = @backingInt(stage),
        .profile_allocation_bytes = attempt.allocations.bytes(),
    } else null;
}

test "optional legalization budget fails closed instead of recursing indefinitely" {
    var budget: Budget = .{ .remaining = 2 };
    try budget.consume();
    try budget.consume();
    try std.testing.expectError(error.OptionalLegalizationLimitExceeded, budget.consume());
    try std.testing.expectEqual(0, budget.remaining);
}
