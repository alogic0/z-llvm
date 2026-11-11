//! Ordered optional rewrites. The driver owns retry policy and termination.
//! Stage order is semantic: every rewrite restarts this search.
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const profiling = @import("../../../compilation_profile.zig");

pub const Stage = enum {
    @"incoming_byval80.zig.legalize",
    @"aligned_stack.zig.legalize",
    @"floating_vectors.zig.legalize",
    @"binary128_arithmetic.zig.legalize",
    @"floating_payloads.zig.legalize",
    @"integer_vectors.zig.legalize",
    @"integer_memory.zig.legalize",
    @"pair_memory.zig.legalize",
    @"wide_integer_forms.zig.legalizeForPhysicalAbi",
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
    @"half_memory.zig.legalizeOrdinaryStores",
    @"scalar_vector_select.zig.legalize",
    @"scalar_integer_conversions.zig.legalize",
    @"extended_math_intrinsics.zig.legalize",
    @"half_math_intrinsics.zig.legalize",
    @"floating_remainders.zig.legalize",
    @"half_classification.zig.legalize",
    @"integer_call_literals.zig.legalize",
    @"pair_memory.zig.legalizeScalarPointers",
    @"indirect_phi_slots.zig.legalizeAll",
    @"stack_addresses.zig.legalizeEscapingOffsets",
    @"hardware_queries.zig.legalize",
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
        .@"incoming_byval80.zig.legalize" => @import("incoming_byval80.zig").legalize(measured, function, context),
        .@"aligned_stack.zig.legalize" => @import("aligned_stack.zig").legalize(measured, function, context),
        .@"floating_vectors.zig.legalize" => @import("floating_vectors.zig").legalize(measured, function, context),
        .@"binary128_arithmetic.zig.legalize" => @import("binary128_arithmetic.zig").legalize(measured, function),
        .@"floating_payloads.zig.legalize" => @import("floating_payloads.zig").legalize(measured, function, context),
        .@"integer_vectors.zig.legalize" => @import("integer_vectors.zig").legalize(measured, function, context),
        .@"integer_memory.zig.legalize" => @import("integer_memory.zig").legalize(measured, function, context),
        .@"pair_memory.zig.legalize" => @import("pair_memory.zig").legalize(measured, function, context),
        .@"wide_integer_forms.zig.legalizeForPhysicalAbi" => @import("wide_integer_forms.zig").legalizeForPhysicalAbi(measured, function),
        .@"flag_pair_values.zig.legalize" => @import("flag_pair_values.zig").legalize(measured, function),
        .@"overflow_values.zig.legalize" => @import("overflow_values.zig").legalizeWithContext(measured, function, context),
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
        .@"half_memory.zig.legalizeOrdinaryStores" => @import("half_memory.zig").legalizeOrdinaryStores(measured, function, context),
        .@"scalar_vector_select.zig.legalize" => @import("scalar_vector_select.zig").legalize(measured, function),
        .@"scalar_integer_conversions.zig.legalize" => @import("scalar_integer_conversions.zig").legalize(measured, function),
        .@"extended_math_intrinsics.zig.legalize" => @import("extended_math_intrinsics.zig").legalize(measured, function, context),
        .@"half_math_intrinsics.zig.legalize" => @import("half_math_intrinsics.zig").legalize(measured, function),
        .@"floating_remainders.zig.legalize" => @import("floating_remainders.zig").legalize(measured, function, context),
        .@"half_classification.zig.legalize" => @import("half_classification.zig").legalize(measured, function),
        .@"integer_call_literals.zig.legalize" => @import("integer_call_literals.zig").legalize(measured, function),
        .@"pair_memory.zig.legalizeScalarPointers" => @import("pair_memory.zig").legalizeScalarPointers(measured, function, context),
        .@"indirect_phi_slots.zig.legalizeAll" => @import("indirect_phi_slots.zig").legalizeAll(measured, function),
        .@"stack_addresses.zig.legalizeEscapingOffsets" => @import("stack_addresses.zig").legalizeEscapingOffsets(measured, function, context),
        .@"hardware_queries.zig.legalize" => @import("hardware_queries.zig").legalize(measured, function, context),
    };
    attempt.outcome = if (candidate != null) .rewritten else .unchanged;
    return if (candidate) |rewritten| .{
        .function = rewritten,
        .retry_original = switch (stage) {
            .@"floating_vectors.zig.legalize" => true,
            .@"comparison_forms.zig.legalize",
            .@"word_arithmetic.zig.legalize",
            .@"integer_forms.zig.legalize",
            .@"pair_arithmetic.zig.legalize",
            .@"switch_phi_edges.zig.legalize",
            .@"address_forms.zig.legalize",
            .@"stack_addresses.zig.legalize",
            .@"pointer_values.zig.legalize",
            .@"block_order.zig.legalize",
            .@"half_memory.zig.legalizeOrdinaryStores",
            .@"scalar_vector_select.zig.legalize",
            .@"scalar_integer_conversions.zig.legalize",
            .@"extended_math_intrinsics.zig.legalize",
            .@"half_math_intrinsics.zig.legalize",
            .@"floating_remainders.zig.legalize",
            .@"half_classification.zig.legalize",
            .@"integer_call_literals.zig.legalize",
            .@"pair_memory.zig.legalizeScalarPointers",
            .@"indirect_phi_slots.zig.legalizeAll",
            .@"stack_addresses.zig.legalizeEscapingOffsets",
            .@"hardware_queries.zig.legalize",
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

test "optional legalization profiling records every registered stage" {
    var module = try ir.Module.parse(std.testing.allocator, "define void @observe() {\nentry:\n ret void\n}\n");
    defer module.deinit();
    var profile = profiling.Profile.init(std.testing.allocator, std.testing.io);
    defer profile.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expect((try next(arena.allocator(), module.functions.items[0], null, &profile)) == null);
    try std.testing.expectEqual(std.enums.values(Stage).len, profile.legalizer_count);
    for (std.enums.values(Stage), 0..) |stage, index| {
        try std.testing.expectEqualStrings(@tagName(stage), profile.legalizers[index].stage);
        try std.testing.expectEqual(@as(u64, 1), profile.legalizers[index].attempts);
        try std.testing.expectEqual(@as(u64, 0), profile.legalizers[index].errors);
    }
}
