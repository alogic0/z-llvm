const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const types = @import("../types.zig");
const verify = @import("../verify.zig");
const selector = @import("../generic_cfg_selector.zig");
const flags = @import("composed_selector_eflags.zig");
const encoding = @import("../../../mc/encoding.zig");
const elf = @import("../../../mc/elf.zig");

test "indirect jump executes every register encoding and validates all declared targets" {
    for (std.meta.tags(types.ArgReg)) |reg| {
        var output = machine.MachineFunction.init("indirect-register", .{ .int = 32 });
        defer output.deinit(std.testing.allocator);
        try output.instructions.appendSlice(std.testing.allocator, &.{
            .{ .mov_arg64_arg = .{ .dst = reg, .src = .rdi } },
            .{ .indirect_jump = .{ .reg = reg, .targets = &.{"target"} } },
            .{ .label = "target" },
            .{ .mov_imm_eax = 42 },
            .ret,
        });
        try verify.verifyFunction(output);
        const code = try encoding.encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(code);
        const memory = try std.posix.mmap(null, code.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..code.len], code);
        const run: *const fn (*const u8) callconv(.c) u32 = @ptrCast(memory.ptr);
        const offset = encoding.instructionSize(output.instructions.items[0]) + encoding.instructionSize(output.instructions.items[1]);
        try std.testing.expectEqual(@as(u32, 42), run(&memory[offset]));
        output.instructions.items[1].indirect_jump.targets = &.{ "target", "missing" };
        try std.testing.expectError(error.InvalidBranchTarget, verify.verifyFunction(output));
        output.instructions.items[1].indirect_jump.targets = &.{};
        try std.testing.expectError(error.InvalidBranchTarget, verify.verifyFunction(output));
    }
}

test "indirect jump propagates flag liveness to every successor" {
    var instructions = [_]machine.Instruction{
        .test_eax_eax,
        .{ .indirect_jump = .{ .reg = .rcx, .targets = &.{ "plain", "consumer" } } },
        .{ .label = "plain" },
        .ret,
        .{ .label = "consumer" },
        .sete_eax,
        .ret,
    };
    try flags.validateInstructions(std.testing.allocator, &instructions);
    instructions[0] = .{ .mov_imm_eax = 0 };
    try std.testing.expectError(error.EflagsConsumerWithoutDefinition, flags.validateInstructions(std.testing.allocator, &instructions));
    instructions[0] = .{ .direct_call = .{ .symbol = "clobber", .ret_ty = .void } };
    try std.testing.expectError(error.EflagsClobberedWhileLive, flags.validateInstructions(std.testing.allocator, &instructions));
}

test "indirect branch retains the unsupported PHI edge boundary" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i64 @f(ptr %address, i64 %value) {
        \\entry:
        \\ indirectbr ptr %address, [label %target]
        \\target:
        \\ %p = phi i64 [ %value, %entry ]
        \\ ret i64 %p
        \\}
    );
    defer module.deinit();
    try module.verify();
    var output = machine.MachineFunction.init("f", .{ .int = 64 });
    defer output.deinit(std.testing.allocator);
    const result = try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]);
    try std.testing.expect(result == .unsupported);
    try std.testing.expectEqualStrings("stage2-indirect-phi", result.unsupported.detail());
}

test "block address relocations reject absent and duplicate machine labels" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\@jump = global [1 x ptr] [ptr blockaddress(@f, %target)]
        \\define void @f() {
        \\entry:
        \\ br label %target
        \\target:
        \\ ret void
        \\}
    );
    defer module.deinit();
    try module.verify();
    const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = null, .functions = module.functions.items, .emit_all_globals = true };
    var output = machine.MachineFunction.init("f", .void);
    defer output.deinit(std.testing.allocator);
    try output.instructions.append(std.testing.allocator, .ret);
    try std.testing.expectError(error.UnresolvedBlockAddress, elf.buildObjectWithModuleContext(std.testing.allocator, &.{output}, &.{}, context));
    try output.instructions.appendSlice(std.testing.allocator, &.{ .{ .label = "target" }, .ret });
    const object = try elf.buildObjectWithModuleContext(std.testing.allocator, &.{output}, &.{}, context);
    defer std.testing.allocator.free(object);
    try output.instructions.appendSlice(std.testing.allocator, &.{ .{ .label = "target" }, .ret });
    try std.testing.expectError(error.UnresolvedBlockAddress, elf.buildObjectWithModuleContext(std.testing.allocator, &.{output}, &.{}, context));
    try std.testing.expectError(error.UnresolvedBlockAddress, elf.buildObjectWithModuleContext(std.testing.allocator, &.{}, &.{}, context));
}
