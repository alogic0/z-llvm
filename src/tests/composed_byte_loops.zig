const std = @import("std");
const ir = @import("../ir.zig");
const impl = @import("../codegen/x86_64/generic_cfg/composed_selector_impl.zig");
const machine_ir = @import("../codegen/x86_64/machine.zig");
const verify = @import("../codegen/x86_64/verify.zig");
const encoding = @import("../mc/encoding.zig");

fn checkMachine(instructions: []const machine_ir.Instruction, expected: ?anyerror) !void {
    var machine = impl.MachineFunction.init("return_join", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.appendSlice(std.testing.allocator, instructions);
    if (expected) |err| {
        try std.testing.expectError(err, verify.verifyFunction(machine));
    } else {
        try verify.verifyFunction(machine);
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        try std.testing.expect(bytes.len != 0);
    }
}

test "byte loops shared return is defined by incoming branches not last block" {
    try checkMachine(&.{
        .sub_rsp_8,
        .{ .je = "loop" },
        .{ .mov_imm_eax = 7 },
        .{ .jmp = "arbitrary_epilogue" },
        .{ .label = "loop" },
        .{ .je = "loop" },
        .{ .mov_imm_eax = 9 },
        .{ .jmp = "arbitrary_epilogue" },
        .{ .label = "unrelated_trap" },
        .ud2,
        .{ .label = "arbitrary_epilogue" },
        .add_rsp_8,
        .ret,
    }, null);
}

test "byte loops shared return rejects undefined incoming branch despite later definition" {
    try checkMachine(&.{
        .{ .je = "defined" },
        .{ .jmp = "end" },
        .{ .label = "defined" },
        .{ .mov_imm_eax = 9 },
        .{ .jmp = "end" },
        .{ .label = "end" },
        .ret,
    }, error.ReturnRegisterUndefined);
}

test "byte loops shared return samples conditional branch before later definition" {
    try checkMachine(&.{
        .{ .je = "end" },
        .{ .mov_imm_eax = 9 },
        .{ .label = "end" },
        .ret,
    }, error.ReturnRegisterUndefined);
}

test "byte loops shared return checks fallthrough and every defined predecessor" {
    try checkMachine(&.{
        .{ .je = "other" },
        .{ .mov_imm_eax = 7 },
        .{ .jmp = "end" },
        .{ .label = "other" },
        .{ .label = "end" },
        .ret,
    }, error.ReturnRegisterUndefined);
    try checkMachine(&.{
        .{ .mov_imm_eax = 7 },
        .{ .je = "end" },
        .{ .mov_imm_eax = 9 },
        .{ .label = "end" },
        .ret,
    }, null);
}

test "byte loops common return before loop body lowers and verifies" {
    const source =
        \\define i32 @compare(ptr %a, ptr %b, i64 %n) {
        \\entry:
        \\ %empty = icmp eq i64 %n, 0
        \\ br i1 %empty, label %done, label %loop
        \\done:
        \\ %r = phi i32 [ 0, %entry ], [ 1, %loop ], [ 0, %next ]
        \\ ret i32 %r
        \\next:
        \\ %j = add i64 %i, 1
        \\ %end = icmp eq i64 %j, %n
        \\ br i1 %end, label %done, label %loop
        \\loop:
        \\ %i = phi i64 [ 0, %entry ], [ %j, %next ]
        \\ %pa = getelementptr i8, ptr %a, i64 %i
        \\ %va = load i8, ptr %pa, align 1
        \\ %pb = getelementptr i8, ptr %b, i64 %i
        \\ %vb = load i8, ptr %pb, align 1
        \\ %same = icmp eq i8 %va, %vb
        \\ br i1 %same, label %next, label %done
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    const function = module.functions.items[0];
    var machine = impl.MachineFunction.init(function.name, function.ret_ty);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expect(try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function) == .selected);
    try verify.verifyFunction(machine);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expect(bytes.len != 0);
}

test "byte loops shared return intersects SSE aggregate definitions" {
    for ([_]bool{ false, true }) |complete| {
        var machine = impl.MachineFunction.init("pair_join", .{ .aggregate = "{ double, double }" });
        defer machine.deinit(std.testing.allocator);
        try machine.instructions.appendSlice(std.testing.allocator, &.{
            .{ .je = "other" },
            .{ .mov_imm64_xmm0 = 0 },
            .{ .mov_imm64_xmm1 = 0 },
            .{ .jmp = "end" },
            .{ .label = "other" },
            .{ .mov_imm64_xmm0 = 0 },
        });
        if (complete) try machine.instructions.append(std.testing.allocator, .{ .mov_imm64_xmm1 = 0 });
        try machine.instructions.appendSlice(std.testing.allocator, &.{ .{ .jmp = "end" }, .{ .label = "end" }, .ret });
        if (complete) try verify.verifyFunction(machine) else try std.testing.expectError(error.ReturnRegisterUndefined, verify.verifyFunction(machine));
    }
}
