const std = @import("std");
const ir = @import("../ir.zig");
const adce = @import("../passes/adce.zig");
const pass_manager = @import("../pass_manager.zig");

fn optimize(module: *ir.Module) !void {
    try module.verify();
    var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
    _ = try adce.pass.run(module, &context);
    try module.verify();
}

test "adce operands: indirect callees and their producer chains stay live" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i32 @invoke(ptr %slot, i32 %x) {
        \\entry:
        \\  %address = getelementptr ptr, ptr %slot, i64 0
        \\  %callee = load ptr, ptr %address
        \\  %arg = add i32 %x, 1
        \\  %dead = add i32 %x, 2
        \\  %v = call i32 %callee(i32 %arg)
        \\  ret i32 %v
        \\}
    );
    defer module.deinit();
    try optimize(&module);
    const insts = module.functions.items[0].blocks.items[0].instructions.items;
    for (insts, 0..) |inst, index| try std.testing.expectEqual(index == 3, inst.removed);
}

test "adce operands: vector values indices and shuffle inputs stay live" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i32 @vectors(i32 %x, i32 %index) {
        \\entry:
        \\  %a = add i32 %x, 3
        \\  %b = add i32 %x, 4
        \\  %i = and i32 %index, 1
        \\  %v0 = insertelement <2 x i32> zeroinitializer, i32 %a, i32 %i
        \\  %v1 = insertelement <2 x i32> zeroinitializer, i32 %b, i32 0
        \\  %v2 = shufflevector <2 x i32> %v0, <2 x i32> %v1, <2 x i32> zeroinitializer
        \\  %out = extractelement <2 x i32> %v2, i32 %i
        \\  %dead = add i32 %x, 5
        \\  ret i32 %out
        \\}
    );
    defer module.deinit();
    try optimize(&module);
    const insts = module.functions.items[0].blocks.items[0].instructions.items;
    for (insts, 0..) |inst, index| try std.testing.expectEqual(index == 7, inst.removed);
}

test "adce operands: terminator values and PHI incoming producers remain live" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i32 @choose(i32 %x) {
        \\entry:
        \\  %c = icmp eq i32 %x, 0
        \\  br i1 %c, label %left, label %right
        \\left:
        \\  %a = add i32 %x, 1
        \\  br label %join
        \\right:
        \\  %b = add i32 %x, 2
        \\  br label %join
        \\join:
        \\  %p = phi i32 [ %a, %left ], [ %b, %right ]
        \\  ret i32 %p
        \\}
    );
    defer module.deinit();
    try optimize(&module);
    for (module.functions.items[0].blocks.items) |block| {
        for (block.instructions.items) |inst| try std.testing.expect(!inst.removed);
    }
    try std.testing.expect(module.functions.items[0].blocks.items[0].terminator.? == .condbr);
}

const opaque_function =
    \\declare void @sink()
    \\define void @f(i1 %c, i32 %x) {
    \\entry:
    \\  %dead = add i32 %x, 1
    \\  br i1 %c, label %left, label %right
    \\left:
    \\  br label %join
    \\right:
    \\  br label %join
    \\join:
    \\  call void @sink()
    \\  ret void
    \\}
;

test "adce operands: opaque coverage blocks both instruction and control flow deletion" {
    // Synthetic raw fields exercise coverage independently of parser support.
    for (0..7) |kind| {
        var module = try ir.Module.parse(std.testing.allocator, opaque_function);
        defer module.deinit();
        const function = &module.functions.items[0];
        const call = &function.blocks.items[3].instructions.items[0];
        switch (kind) {
            0 => call.kind.call.raw_args = "metadata !0",
            1 => call.kind.call.operand_bundle = "[ opaque ]",
            2 => call.kind.call.attrs = "nounwind",
            3 => call.metadata = "!annotation !0",
            4 => function.blocks.items[0].terminator.?.condbr.metadata = "!prof !0",
            5 => call.kind.call.inline_asm = .{ .template = "", .constraints = "", .sideeffect = true },
            6 => function.blocks.items[0].instructions.items[0].kind.binary.lhs = .{ .constant_expr = "opaque" },
            else => unreachable,
        }
        var context: pass_manager.Context = .{ .allocator = std.testing.allocator };
        const result = try adce.pass.run(&module, &context);
        try std.testing.expectEqual(pass_manager.PassResult.unchanged, result);
        try std.testing.expect(!function.blocks.items[0].instructions.items[0].removed);
        try std.testing.expect(function.blocks.items[0].terminator.? == .condbr);
    }
}

test "adce operands: parsed opaque vector values preserve their containing function" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define <2 x i32> @f(i32 %x) {
        \\entry:
        \\  %dead = add i32 %x, 1
        \\  ret <2 x i32> <i32 0, i32 1>
        \\}
    );
    defer module.deinit();
    try optimize(&module);
    try std.testing.expect(!module.functions.items[0].blocks.items[0].instructions.items[0].removed);
}

test "adce operands: removed opaque instructions do not block dead code removal" {
    var module = try ir.Module.parse(std.testing.allocator, opaque_function);
    defer module.deinit();
    const call = &module.functions.items[0].blocks.items[3].instructions.items[0];
    call.removed = true;
    call.kind.call.raw_args = "opaque";
    try optimize(&module);
    try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[0].removed);
    try std.testing.expect(module.functions.items[0].blocks.items[0].terminator.? == .br);
}
