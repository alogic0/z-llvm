const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("integer_vectors.zig");

test "integer vector GEP indices preserve scalar source strides and pointer lanes" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i64 @offsets(ptr %base, i64 %offset) {
        \\entry:
        \\ %one = insertelement <4 x i64> <i64 -8, i64 0, i64 8, i64 16>, i64 %offset, i64 1
        \\ %pointers = getelementptr i8, ptr %base, <4 x i64> %one
        \\ %picked = extractelement <4 x ptr> %pointers, i64 1
        \\ %value = load i64, ptr %picked, align 1
        \\ ret i64 %value
        \\}
    );
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const expanded = (try forms.legalize(arena.allocator(), module.functions.items[0], null)).?;
    var private = module;
    private.functions = try module.functions.clone(arena.allocator());
    private.functions.items[0] = expanded;
    try private.verify();
    try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[1].kind.gep.resultType() == .vector);
    for (expanded.blocks.items[0].instructions.items) |inst| if (inst.kind == .gep) {
        try std.testing.expect(inst.kind.gep.resultType() == .ptr);
        try std.testing.expect(inst.kind.gep.source_ty.eql(.{ .int = 8 }));
    };
    try std.testing.expect((try forms.legalize(arena.allocator(), expanded, null)) == null);
}

test "integer vector aliases retain non-native wide carrier compatibility" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i64 @bytes(i80 %raw, ptr %out) {
        \\entry:
        \\ %one = insertelement <8 x i80> poison, i80 %raw, i64 0
        \\ %all = shufflevector <8 x i80> %one, <8 x i80> poison, <8 x i32> zeroinitializer
        \\ %parts = lshr <8 x i80> %all, <i80 0, i80 8, i80 16, i80 24, i80 32, i80 40, i80 48, i80 56>
        \\ %small = trunc <8 x i80> %parts to <8 x i8>
        \\ store <8 x i8> %small, ptr %out, align 1
        \\ %result = trunc i80 %raw to i64
        \\ ret i64 %result
        \\}
    );
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const expanded = (try forms.legalize(arena.allocator(), module.functions.items[0], null)).?;
    const widened = (try @import("wide_integer_forms.zig").legalizeForPhysicalAbi(arena.allocator(), expanded)) orelse return error.TestExpectedWideRewrite;
    var private = module;
    private.functions = try module.functions.clone(arena.allocator());
    private.functions.items[0] = widened;
    try private.verify();
    try module.verify();
    try std.testing.expectEqual(@as(u16, 80), module.functions.items[0].params.items[0].ty.int);
}

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
        "define void @f(ptr %p) {\nentry:\n %v = load volatile <2 x ptr>, ptr %p\n ret void\n}\n",
        "define void @f(ptr %p) {\nentry:\n %v = load <4 x i32>, ptr addrspace(1) %p\n ret void\n}\n",
        "define <2 x i128> @f(<2 x i128> %v) {\nentry:\n ret <2 x i128> %v\n}\n",
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

test "integer vector scalar bitcasts preserve exact source widths and private ownership" {
    const source = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/real_programs/vector_masks.ll", std.testing.allocator, .limited(1024 * 1024));
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
    try std.testing.expect(module.functions.items[0].blocks.items[0].instructions.items[4].kind.cast.from_ty == .vector);
}

test "integer vector graphs retain forward PHI identities and typed pointer lanes" {
    const source = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/real_programs/vector_graphs.ll", std.testing.allocator, .limited(1024 * 1024));
    defer std.testing.allocator.free(source);
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var private = module;
    private.functions = try module.functions.clone(arena.allocator());
    var scalar_freezes: usize = 0;
    for (module.functions.items, private.functions.items) |original, *replacement| {
        replacement.* = (try forms.legalize(arena.allocator(), original, null)).?;
        try std.testing.expectEqual(original.params.items.ptr, replacement.params.items.ptr);
        try std.testing.expect(original.ret_ty.eql(replacement.ret_ty));
        try std.testing.expect((try forms.legalize(arena.allocator(), replacement.*, null)) == null);
        for (replacement.blocks.items) |block| for (block.instructions.items) |inst| {
            if (!inst.removed and inst.kind == .phi) try std.testing.expect(inst.kind.phi.ty != .vector);
            if (!inst.removed and inst.kind == .freeze) {
                try std.testing.expect(inst.kind.freeze.ty != .vector);
                scalar_freezes += 1;
            }
        };
    }
    try std.testing.expect(scalar_freezes > 0);
    try private.verify();
    try module.verify();
    try std.testing.expect(module.functions.items[0].blocks.items[1].instructions.items[1].kind.phi.ty == .vector);
}
