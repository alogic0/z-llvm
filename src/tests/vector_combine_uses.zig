const std = @import("std");
const ir = @import("../ir.zig");
const vector_combine = @import("../passes/vector_combine.zig");
const pass_manager = @import("../pass_manager.zig");

fn run(module: *ir.Module) !pass_manager.PassResult {
    var context: pass_manager.Context = .{ .allocator = module.allocator };
    return vector_combine.pass.run(module, &context);
}

const scalar_source =
    \\define i32 @scalar(i32 %x, i1 %c) {
    \\entry:
    \\ %v = insertelement <2 x i32> poison, i32 %x, i32 1
    \\ %r = extractelement <2 x i32> %v, i32 1
    \\ %n = add i32 %r, %r
    \\ %mem = alloca i8, i32 %r
    \\ br i1 %c, label %other, label %merge
    \\other:
    \\ br label %merge
    \\merge:
    \\ %p = phi i32 [ %r, %entry ], [ %n, %other ]
    \\ ret i32 %p
    \\}
;

test "vector use migration: substitution includes repeated operands, alloca and PHI edges" {
    var module = try ir.Module.parse(std.testing.allocator, scalar_source);
    defer module.deinit();
    try module.verify();
    try std.testing.expectEqual(.changed, try run(&module));
    try module.verify();
    const f = &module.functions.items[0];
    try std.testing.expectEqual(@as(usize, 0), ir.operands.functionUses(f, "r", null).occurrences);
    try std.testing.expectEqual(@as(usize, 4), ir.operands.functionUses(f, "x", .{ .int = 32 }).occurrences);
    try std.testing.expect(f.blocks.items[0].instructions.items[0].removed);
    try std.testing.expect(f.blocks.items[0].instructions.items[1].removed);
    try std.testing.expectEqual(.unchanged, try run(&module));
}

test "vector use migration: unknown references leave complete IR and bookkeeping unchanged" {
    var module = try ir.Module.parse(std.testing.allocator, scalar_source);
    defer module.deinit();
    const f = &module.functions.items[0];
    f.blocks.items[0].instructions.items[2].metadata = "!annotation !0";
    const block_pointer = f.blocks.items.ptr;
    const instruction_pointer = f.blocks.items[0].instructions.items.ptr;
    var before: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer before.deinit();
    try module.print(&before.writer);
    try std.testing.expectEqual(.unchanged, try run(&module));
    var after: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer after.deinit();
    try module.print(&after.writer);
    try std.testing.expectEqualStrings(before.written(), after.written());
    try std.testing.expectEqual(block_pointer, f.blocks.items.ptr);
    try std.testing.expectEqual(instruction_pointer, f.blocks.items[0].instructions.items.ptr);
    for (f.blocks.items) |block| for (block.instructions.items) |inst| {
        try std.testing.expect(!inst.removed and inst.replacement == null);
    };
}

test "vector use migration: indirect pointer callee and independent insert consumer remain live" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i32 @callee(ptr %fn, i32 %lane) {
        \\entry:
        \\ %v = insertelement <2 x ptr> poison, ptr %fn, i32 0
        \\ %r = extractelement <2 x ptr> %v, i32 0
        \\ %other = extractelement <2 x ptr> %v, i32 %lane
        \\ %n = call i32 %r()
        \\ ret i32 %n
        \\}
    );
    defer module.deinit();
    try module.verify();
    try std.testing.expectEqual(.changed, try run(&module));
    try module.verify();
    const insts = module.functions.items[0].blocks.items[0].instructions.items;
    try std.testing.expectEqualStrings("fn", insts[3].kind.call.callee_value.?.named);
    try std.testing.expect(insts[1].removed);
    try std.testing.expect(!insts[0].removed);
}

test "vector use migration: cross-block PHI edges and current insert operands" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i32 @chain(i32 %x) {
        \\entry:
        \\ %a = insertelement <2 x i32> poison, i32 %x, i32 0
        \\ br label %producer
        \\build:
        \\ %b = insertelement <2 x i32> poison, i32 %first, i32 1
        \\ br label %next
        \\producer:
        \\ %first = extractelement <2 x i32> %a, i32 0
        \\ br label %build
        \\next:
        \\ %r = extractelement <2 x i32> %b, i32 1
        \\ br label %merge
        \\merge:
        \\ %p = phi i32 [ %r, %next ]
        \\ ret i32 %p
        \\}
    );
    defer module.deinit();
    try module.verify();
    try std.testing.expectEqual(.changed, try run(&module));
    try module.verify();
    const phi = module.functions.items[0].blocks.items[4].instructions.items[0].kind.phi;
    try std.testing.expectEqualStrings("x", phi.incoming.items[0].value.named);
}

test "vector use migration: a non-dominating producer refuses before mutation" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i32 @bad(i1 %c, i32 %x) {
        \\entry:
        \\ br i1 %c, label %left, label %right
        \\left:
        \\ %v = insertelement <2 x i32> poison, i32 %x, i32 0
        \\ br label %right
        \\right:
        \\ %r = extractelement <2 x i32> %v, i32 0
        \\ ret i32 %r
        \\}
    );
    defer module.deinit();
    // Deliberately invalid SSA tests the rewrite's own preflight contract.
    try std.testing.expectEqual(.unchanged, try run(&module));
    const f = module.functions.items[0];
    try std.testing.expect(!f.blocks.items[1].instructions.items[0].removed);
    try std.testing.expect(!f.blocks.items[2].instructions.items[0].removed);
    try std.testing.expect(f.blocks.items[2].instructions.items[0].replacement == null);
}

test "vector use migration: preflight rejects incompatible structured use without mutation" {
    var module = try ir.Module.parse(std.testing.allocator, scalar_source);
    defer module.deinit();
    const f = &module.functions.items[0];
    f.blocks.items[0].instructions.items[2].kind.binary.ty = .{ .int = 64 };
    try std.testing.expectEqual(.unchanged, try run(&module));
    for (f.blocks.items) |block| for (block.instructions.items) |inst| {
        try std.testing.expect(!inst.removed and inst.replacement == null);
    };
    try std.testing.expectEqualStrings("r", f.blocks.items[0].instructions.items[2].kind.binary.lhs.named);
}
