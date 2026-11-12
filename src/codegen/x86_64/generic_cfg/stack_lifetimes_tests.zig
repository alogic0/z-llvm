const std = @import("std");
const ir = @import("../../../ir.zig");
const lifetimes = @import("stack_lifetimes.zig");
const declarations = "declare void @llvm.lifetime.start.p0(ptr)\ndeclare void @llvm.lifetime.end.p0(ptr)\n";

fn backing(function: ir.Function, name: []const u8) []const u8 {
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (inst.result) |result| if (ir.identifiers.eql(result, name)) return inst.kind.gep.ptr.named;
    };
    unreachable;
}
fn verify(source: ir.Module, function: ir.Function, a: std.mem.Allocator) !void {
    var copy = source;
    copy.functions = .empty;
    try copy.functions.append(a, function);
    try @import("../../../ir/verifier.zig").verify(copy);
}

test "stack lifetimes share disjoint full objects and preserve the source" {
    var module = try ir.Module.parse(std.testing.allocator, declarations ++
        "define void @sequential() {\nentry:\n %a = alloca [32768 x i8], align 16\n %b = alloca [32768 x i8], align 8\n" ++
        " call void @llvm.lifetime.start.p0(ptr %a)\n store i8 1, ptr %a\n call void @llvm.lifetime.end.p0(ptr %a)\n" ++
        " call void @llvm.lifetime.start.p0(ptr %b)\n store i8 2, ptr %b\n call void @llvm.lifetime.end.p0(ptr %b)\n ret void\n}\n");
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const original = module.functions.items[0];
    const candidate = (try lifetimes.legalize(arena.allocator(), original, null)).?;
    try verify(module, candidate, arena.allocator());
    try std.testing.expectEqualStrings(backing(candidate, "a"), backing(candidate, "b"));
    try std.testing.expect(original.blocks.items[0].instructions.items[0].kind == .alloca);
    try std.testing.expect(original.blocks.items[0].instructions.items[1].kind == .alloca);
    try std.testing.expectEqual(@as(usize, 8), original.blocks.items[0].instructions.items.len);
    for (candidate.blocks.items) |block| for (block.instructions.items) |inst| try std.testing.expect(inst.kind != .call);
    try std.testing.expect((try lifetimes.legalize(arena.allocator(), candidate, null)) == null);
}

test "stack lifetimes keep loop-carried and maybe-live objects distinct" {
    var module = try ir.Module.parse(std.testing.allocator, declarations ++
        "define void @loop(i1 %again) {\nentry:\n %a = alloca [32768 x i8], align 16\n %b = alloca [32768 x i8], align 16\n %c = alloca [32768 x i8], align 16\n" ++
        " call void @llvm.lifetime.start.p0(ptr %a)\n br label %body\nbody:\n" ++
        " call void @llvm.lifetime.start.p0(ptr %b)\n store i8 3, ptr %a\n store i8 4, ptr %b\n" ++
        " call void @llvm.lifetime.end.p0(ptr %b)\n br i1 %again, label %body, label %exit\nexit:\n" ++
        " call void @llvm.lifetime.end.p0(ptr %a)\n call void @llvm.lifetime.start.p0(ptr %c)\n" ++
        " store i8 5, ptr %c\n call void @llvm.lifetime.end.p0(ptr %c)\n ret void\n}\n");
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const candidate = (try lifetimes.legalize(arena.allocator(), module.functions.items[0], null)).?;
    try verify(module, candidate, arena.allocator());
    try std.testing.expect(!std.mem.eql(u8, backing(candidate, "a"), backing(candidate, "b")));
    try std.testing.expectEqualStrings(backing(candidate, "a"), backing(candidate, "c"));
}

test "stack lifetimes retain unclassified markers and absent lifetime boundaries" {
    var module = try ir.Module.parse(std.testing.allocator, declarations ++
        "define void @opaque(ptr %p) {\nentry:\n %a = alloca [32768 x i8], align 16\n %b = alloca [32768 x i8], align 16\n" ++
        " call void @llvm.lifetime.start.p0(ptr %a)\n call void @llvm.lifetime.end.p0(ptr %a)\n" ++
        " call void @llvm.lifetime.start.p0(ptr %b)\n call void @llvm.lifetime.end.p0(ptr %b)\n" ++
        " call void @llvm.lifetime.start.p0(ptr %p)\n ret void\n}\n" ++
        "define void @missing() {\nentry:\n %a = alloca [32768 x i8], align 16\n %b = alloca [32768 x i8], align 16\n" ++
        " call void @llvm.lifetime.start.p0(ptr %a)\n call void @llvm.lifetime.start.p0(ptr %b)\n ret void\n}\n");
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    for (module.functions.items) |function| try std.testing.expect((try lifetimes.legalize(arena.allocator(), function, null)) == null);
}

test "stack lifetimes do not invent overlap at a join of exclusive starts" {
    var module = try ir.Module.parse(std.testing.allocator, declarations ++
        "define void @exclusive(i1 %side) {\nentry:\n %a = alloca [32768 x i8], align 16\n %b = alloca [32768 x i8], align 16\n" ++
        " br i1 %side, label %left, label %right\nleft:\n call void @llvm.lifetime.start.p0(ptr %a)\n store i8 1, ptr %a\n br label %join\n" ++
        "right:\n call void @llvm.lifetime.start.p0(ptr %b)\n store i8 2, ptr %b\n br label %join\njoin:\n" ++
        " call void @llvm.lifetime.end.p0(ptr %a)\n call void @llvm.lifetime.end.p0(ptr %b)\n ret void\n}\n");
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const candidate = (try lifetimes.legalize(arena.allocator(), module.functions.items[0], null)).?;
    try verify(module, candidate, arena.allocator());
    try std.testing.expectEqualStrings(backing(candidate, "a"), backing(candidate, "b"));
}
