const std = @import("std");
const eflags = @import("composed_selector_eflags.zig");

test "EFLAGS compare to setcc has a reaching definition" {
    const instructions = [_]eflags.Instruction{
        .{ .cmp_eax_imm32 = 0 },
        .sete_eax,
        .ret,
    };
    try eflags.validateInstructions(std.testing.allocator, &instructions);
}

test "EFLAGS compare to conditional branch has a reaching definition" {
    const instructions = [_]eflags.Instruction{
        .{ .cmp_eax_imm32 = 0 },
        .{ .je = "done" },
        .{ .mov_imm_eax = 1 },
        .{ .label = "done" },
        .ret,
    };
    try eflags.validateInstructions(std.testing.allocator, &instructions);
}

test "EFLAGS consumer without definition is rejected" {
    const instructions = [_]eflags.Instruction{
        .sete_eax,
        .ret,
    };
    try std.testing.expectError(
        error.EflagsConsumerWithoutDefinition,
        eflags.validateInstructions(std.testing.allocator, &instructions),
    );
}

test "EFLAGS second definition while live is rejected" {
    var state: eflags.Liveness = .{};
    try state.apply(.definition);
    try std.testing.expectError(
        error.EflagsDefinitionOverwrittenWhileLive,
        state.apply(.definition),
    );
}

test "EFLAGS accumulator preparation clobber between definition and use is rejected" {
    var state: eflags.Liveness = .{};
    try state.apply(.definition);
    try std.testing.expectError(
        error.EflagsClobberedWhileLive,
        state.accumulatorPreparation(),
    );
}

test "EFLAGS preserving move between definition and use is accepted" {
    const instructions = [_]eflags.Instruction{
        .{ .cmp_eax_imm32 = 0 },
        .{ .mov_arg_arg = .{ .dst = .r8, .src = .r9 } },
        .sete_eax,
        .ret,
    };
    try eflags.validateInstructions(std.testing.allocator, &instructions);

    var state: eflags.Liveness = .{};
    const saved = state.snapshot();
    try state.apply(.definition);
    state.restore(saved);
    try state.validateSnapshot(saved);
}
