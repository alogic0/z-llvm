const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("integer_vectors.zig");

test "integer vector lane expansion verifies privately and preserves source definitions" {
    const source = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/real_programs/integer_vectors.ll", std.testing.allocator, .limited(1024 * 1024));
    defer std.testing.allocator.free(source);
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var private = module;
    private.functions = try module.functions.clone(arena.allocator());
    for (module.functions.items, private.functions.items) |original, *replacement| {
        replacement.* = (try forms.legalize(arena.allocator(), original, null)).?;
        try std.testing.expectEqual(original.params.items.ptr, replacement.params.items.ptr);
        try std.testing.expect(original.ret_ty.eql(replacement.ret_ty));
        try std.testing.expect((try forms.legalize(arena.allocator(), replacement.*, null)) == null);
        try std.testing.expect(replacement.blocks.items.ptr != original.blocks.items.ptr);
    }
    try private.verify();
    try module.verify();
    try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[0].kind == .insertelement);
}

test "integer vector lane expansion rejects unsupported memory ABI and indices" {
    for ([_][]const u8{
        "define <8 x i32> @f(<8 x i32> %v) {\nentry:\n ret <8 x i32> %v\n}\n",
        "define void @f(ptr %p) {\nentry:\n %v = load volatile <4 x i32>, ptr %p\n ret void\n}\n",
        "define void @f(ptr %p) {\nentry:\n %v = load <4 x i32>, ptr addrspace(1) %p\n ret void\n}\n",
        "define i32 @f(ptr %p, i128 %index) {\nentry:\n %v = load <4 x i32>, ptr %p\n %r = extractelement <4 x i32> %v, i128 %index\n ret i32 %r\n}\n",
        "declare void @callee(<8 x i32>)\ndefine void @f(ptr %p) {\nentry:\n %v = load <8 x i32>, ptr %p\n call void @callee(<8 x i32> %v)\n ret void\n}\n",
    }) |source| {
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try forms.legalize(arena.allocator(), module.functions.items[0], null)) == null);
    }
}

test "integer vector ABI expansion keeps public signatures and verifies private lane bridges" {
    const source = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/real_programs/vector_abi.ll", std.testing.allocator, .limited(1024 * 1024));
    defer std.testing.allocator.free(source);
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var private = module;
    private.functions = try module.functions.clone(arena.allocator());
    for (module.functions.items, private.functions.items) |original, *replacement| {
        replacement.* = (try forms.legalize(arena.allocator(), original, null)).?;
        try std.testing.expectEqual(original.params.items.ptr, replacement.params.items.ptr);
        try std.testing.expect(original.ret_ty.eql(replacement.ret_ty));
        try std.testing.expect((try forms.legalize(arena.allocator(), replacement.*, null)) == null);
    }
    try private.verify();
    try module.verify();
}
