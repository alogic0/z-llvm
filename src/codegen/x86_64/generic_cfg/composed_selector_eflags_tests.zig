const std = @import("std");
const eflags = @import("composed_selector_eflags.zig");
const machine = @import("../machine.zig");
const selector_state = @import("composed_selector_state.zig");

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

test "production EFLAGS authority rejects incidental writes and second definitions before append" {
    var function = machine.MachineFunction.init("eflags-production-reject", .{ .int = 32 });
    defer function.deinit(std.testing.allocator);
    var selector = selector_state.ComposedBlockSelector.init(std.testing.allocator, &function);
    defer selector.deinit();

    try selector_state.emitEflagsInstruction(&selector, .{ .cmp_eax_imm32 = 0 }, .definition);
    const saved = selector.eflags.snapshot();
    try std.testing.expectError(
        error.EflagsClobberedWhileLive,
        selector_state.emitEflagsInstruction(&selector, .{ .add_eax_imm32 = 1 }, .write),
    );
    try std.testing.expectEqual(@as(usize, 1), function.instructions.items.len);
    try selector.eflags.validateSnapshot(saved);
    try std.testing.expectError(
        error.EflagsDefinitionOverwrittenWhileLive,
        selector_state.emitEflagsInstruction(&selector, .{ .cmp_eax_imm32 = 1 }, .definition),
    );
    try std.testing.expectEqual(@as(usize, 1), function.instructions.items.len);
    try selector.eflags.validateSnapshot(saved);
    try selector_state.emitEflagsInstruction(&selector, .sete_eax, .use);
}

test "intentional arithmetic definitions accept only compatible consumers" {
    const producers = [_]machine.Instruction{
        .{ .add_eax_imm32 = 1 },
        .{ .binary_arg_eax = .{ .op = .sub, .reg = .rcx } },
        .{ .imul_eax_arg32 = .rcx },
    };
    for (producers) |producer| {
        var function = machine.MachineFunction.init("eflags-overflow", .{ .int = 32 });
        defer function.deinit(std.testing.allocator);
        var selector = selector_state.ComposedBlockSelector.init(std.testing.allocator, &function);
        defer selector.deinit();
        try selector_state.emitEflagsDefinition(&selector, producer, .overflow);
        try selector_state.emitEflagsInstruction(&selector, .{ .jo = "overflow" }, .use);
        try std.testing.expectEqual(@as(usize, 2), function.instructions.items.len);
    }

    var function = machine.MachineFunction.init("eflags-incompatible", .{ .int = 32 });
    defer function.deinit(std.testing.allocator);
    var selector = selector_state.ComposedBlockSelector.init(std.testing.allocator, &function);
    defer selector.deinit();
    try selector_state.emitEflagsDefinition(&selector, .{ .add_eax_imm32 = 1 }, .overflow);
    const saved = selector.eflags.snapshot();
    try std.testing.expectError(
        error.EflagsIncompatibleConsumer,
        selector_state.emitEflagsInstruction(&selector, .setb_eax, .use),
    );
    try std.testing.expectEqual(@as(usize, 1), function.instructions.items.len);
    try selector.eflags.validateSnapshot(saved);
}

test "carry chains preserve intended links and reject incidental writes" {
    var function = machine.MachineFunction.init("eflags-carry", .{ .int = 64 });
    defer function.deinit(std.testing.allocator);
    var selector = selector_state.ComposedBlockSelector.init(std.testing.allocator, &function);
    defer selector.deinit();
    try selector_state.emitEflagsDefinition(&selector, .{ .add_arg64_rax = .rcx }, .carry);
    try selector_state.emitEflagsInstruction(&selector, .adc_rax_imm0, .use_and_definition);
    const linked = selector.eflags.snapshot();
    try std.testing.expectError(
        error.EflagsClobberedWhileLive,
        selector_state.emitEflagsInstruction(&selector, .{ .add_eax_imm32 = 1 }, .write),
    );
    try selector.eflags.validateSnapshot(linked);
    try selector_state.emitEflagsInstruction(&selector, .{ .sbb_arg64_rax = .rdx }, .use_and_clobber);
}

test "flags-preserving materialization remains valid and division cannot feed a consumer" {
    var function = machine.MachineFunction.init("eflags-preserve", .{ .int = 32 });
    defer function.deinit(std.testing.allocator);
    var selector = selector_state.ComposedBlockSelector.init(std.testing.allocator, &function);
    defer selector.deinit();
    try selector_state.emitEflagsInstruction(&selector, .{ .cmp_eax_imm32 = 0 }, .definition);
    try function.instructions.append(std.testing.allocator, .{ .spill_eax_rsp = .slot0 });
    try function.instructions.append(std.testing.allocator, .{ .reload_rsp_eax = .slot0 });
    try function.instructions.append(std.testing.allocator, .{ .mov_eax_to_arg = .rcx });
    try selector_state.emitEflagsInstruction(&selector, .sete_eax, .use);

    var division = machine.MachineFunction.init("eflags-div", .{ .int = 32 });
    defer division.deinit(std.testing.allocator);
    var div_selector = selector_state.ComposedBlockSelector.init(std.testing.allocator, &division);
    defer div_selector.deinit();
    try selector_state.emitEflagsInstruction(&div_selector, .{ .div_arg32 = .rcx }, .clobber);
    try std.testing.expectError(
        error.EflagsConsumerWithoutDefinition,
        selector_state.emitEflagsInstruction(&div_selector, .sete_eax, .use),
    );
    try std.testing.expectEqual(@as(usize, 1), division.instructions.items.len);
}

test "conditional branch validation covers fallthrough and target paths" {
    const valid = [_]eflags.Instruction{
        .{ .cmp_eax_imm32 = 0 },
        .{ .je = "taken" },
        .setne_eax,
        .{ .jmp = "done" },
        .{ .label = "taken" },
        .sete_eax,
        .{ .label = "done" },
        .ret,
    };
    try eflags.validateInstructions(std.testing.allocator, &valid);

    const clobbered_target = [_]eflags.Instruction{
        .{ .cmp_eax_imm32 = 0 },
        .{ .je = "taken" },
        .setne_eax,
        .{ .jmp = "done" },
        .{ .label = "taken" },
        .{ .div_arg32 = .rcx },
        .sete_eax,
        .{ .label = "done" },
        .ret,
    };
    try std.testing.expectError(
        error.EflagsClobberedWhileLive,
        eflags.validateInstructions(std.testing.allocator, &clobbered_target),
    );

    const definition_free_predecessor = [_]eflags.Instruction{
        .{ .jmp = "consume" },
        .{ .label = "defined" },
        .{ .cmp_eax_imm32 = 0 },
        .{ .jmp = "consume" },
        .{ .label = "consume" },
        .sete_eax,
        .ret,
    };
    try std.testing.expectError(
        error.EflagsConsumerWithoutDefinition,
        eflags.validateInstructions(std.testing.allocator, &definition_free_predecessor),
    );
}
