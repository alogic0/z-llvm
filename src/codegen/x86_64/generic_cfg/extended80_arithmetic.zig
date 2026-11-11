//! Typed low80 pair operands, balanced x87 evaluation and owned result storage.
const ir = @import("../../../ir.zig");
const state = @import("composed_selector_state.zig");
const Diagnostic = @import("inspection.zig").Diagnostic;
pub const Operation = enum { add, sub, mul, div, sqrt };

pub fn lower(selector: *state.ComposedBlockSelector, result: ?[]const u8, lhs: ir.Value, rhs: ?ir.Value, operation: Operation) !?Diagnostic {
    const name = result orelse return .{ .unsupported_value = "extended80-arithmetic-result" };
    // Capture both canonical pair homes before any physical register changes.
    const left = state.ensurePairSpill(selector, lhs) catch return .{ .no_spill_envelope = "extended80-arithmetic-left" };
    const right = if (rhs) |value| state.ensurePairSpill(selector, value) catch return .{ .no_spill_envelope = "extended80-arithmetic-right" } else null;
    const output = state.allocatePairSpillSlots(selector, name) orelse return .{ .no_spill_envelope = "extended80-arithmetic-output" };
    try state.clobberAccumulator(selector);
    try state.clobberArgReg(selector, .rdx);
    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = left.lo });
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = left.hi } });
    try state.emitEflagsInstruction(selector, .i80_rax_rdx_st0, .clobber);
    if (right) |home| {
        try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = home.lo });
        try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = home.hi } });
        try state.emitEflagsInstruction(selector, .i80_rax_rdx_st0, .clobber);
        try state.emitEflagsInstruction(selector, .{ .x87_binary_pop = switch (operation) {
            .add => .add,
            .sub => .sub,
            .mul => .mul,
            .div => .div,
            .sqrt => unreachable,
        } }, .preserve);
    } else {
        if (operation != .sqrt) return .{ .unsupported_value = "extended80-arithmetic-arity" };
        try state.emitEflagsInstruction(selector, .x87_sqrt_st0, .preserve);
    }
    try state.emitEflagsInstruction(selector, .x87_st0_i80_rax_rdx, .preserve);
    try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = output.lo });
    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .reg = .rdx, .frame_index = output.hi } });
    try state.bindResultLoc(selector, name, .{ .spill128 = output });
    return null;
}

test "floating extended arithmetic encodes ordered operations and balances x87 storage" {
    const std = @import("std");
    const instructions = [_][]const u8{ "fadd x86_fp80 %a,%b", "fsub x86_fp80 %a,%b", "fmul x86_fp80 %a,%b", "fdiv x86_fp80 %a,%b", "call x86_fp80 @llvm.sqrt.f80(x86_fp80 %a)" };
    for (instructions, 0..) |expression, operation| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "target datalayout = \"e-i128:128-f80:128\"\ndeclare x86_fp80 @llvm.sqrt.f80(x86_fp80)\ndefine void @calculate(ptr %left,ptr %right,ptr %output) {{\nentry:\n %a = load x86_fp80,ptr %left,align 1\n %b = load x86_fp80,ptr %right,align 1\n %r = {s}\n store x86_fp80 %r,ptr %output,align 1\n ret void\n}}\n", .{expression});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const machine = @import("../machine.zig");
        const selector = @import("../generic_cfg_selector.zig");
        const context: machine.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
        var output = machine.MachineFunction.init("calculate", .void);
        defer output.deinit(std.testing.allocator);
        const selection = try selector.tryLowerWithContext(std.testing.allocator, &output, module.functions.items[0], &context);
        if (selection == .unsupported) std.debug.print("extended80 arithmetic op{d}: {s}\n", .{ operation, selection.unsupported.detail() });
        try std.testing.expectEqual(selector.SelectionResult.selected, selection);
        try @import("../verify.zig").verifyFunction(output);
        const bytes = try @import("../../../mc/encoding.zig").encodeFunction(std.testing.allocator, output);
        defer std.testing.allocator.free(bytes);
        const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(code);
        @memcpy(code[0..bytes.len], bytes);
        const run: *const fn (*const u8, *const u8, *u8) callconv(.c) void = @ptrCast(code.ptr);
        var left: [10]u8 = undefined;
        var right: [10]u8 = undefined;
        std.mem.writeInt(u80, &left, @bitCast(@as(f80, 3)), .little);
        std.mem.writeInt(u80, &right, @bitCast(@as(f80, 2)), .little);
        var guarded: [16]u8 = @splat(0xa7);
        run(&left[0], &right[0], &guarded[1]);
        const expected: f80 = switch (operation) {
            0 => 5,
            1 => 1,
            2 => 6,
            3 => 1.5,
            else => @sqrt(@as(f80, 3)),
        };
        try std.testing.expectEqual(@as(u80, @bitCast(expected)), std.mem.readInt(u80, guarded[1..11], .little));
        try std.testing.expectEqual(@as(u8, 0xa7), guarded[0]);
        for (guarded[11..]) |byte| try std.testing.expectEqual(@as(u8, 0xa7), byte);
    }
}

test "floating extended arithmetic verifier rejects incomplete operand stacks" {
    const std = @import("std");
    const verifier = @import("../verify_x87.zig");
    var output = @import("../machine.zig").MachineFunction.init("closed", .void);
    defer output.deinit(std.testing.allocator);
    try output.instructions.appendSlice(std.testing.allocator, &.{ .x87_sqrt_st0, .ret });
    try std.testing.expectError(error.X87StackUnderflow, verifier.verify(output));
    output.instructions.clearRetainingCapacity();
    try output.instructions.appendSlice(std.testing.allocator, &.{ .i80_rax_rdx_st0, .{ .x87_binary_pop = .sub }, .ret });
    try std.testing.expectError(error.X87StackUnderflow, verifier.verify(output));
    output.instructions.clearRetainingCapacity();
    try output.instructions.appendSlice(std.testing.allocator, &.{ .i80_rax_rdx_st0, .i80_rax_rdx_st0, .{ .x87_binary_pop = .div }, .x87_st0_i80_rax_rdx, .ret });
    try verifier.verify(output);
}
