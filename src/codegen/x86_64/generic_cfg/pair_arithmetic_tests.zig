const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("pair_arithmetic.zig");
const cleanup = @import("pair_dead_values.zig");

test "pair division calls preserve operand order source flags and closed helper recursion" {
    const cases = [_]struct { op: []const u8, symbol: []const u8, exact: bool }{
        .{ .op = "udiv", .symbol = "__udivti3", .exact = true },
        .{ .op = "urem", .symbol = "__umodti3", .exact = false },
        .{ .op = "sdiv", .symbol = "__divti3", .exact = true },
        .{ .op = "srem", .symbol = "__modti3", .exact = false },
    };
    for (cases) |case| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\declare i128 @{0s}(i128, i128)
            \\define i128 @checked(i128 %__zllvm_scalar_form_0, i128 %right) {{
            \\entry:
            \\ %answer = {1s} {2s}i128 %__zllvm_scalar_form_0, %right
            \\ ret i128 %answer
            \\}}
        , .{ case.symbol, case.op, if (case.exact) "exact " else "" });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const original = module.functions.items[0];
        const view = (try forms.legalize(arena.allocator(), original)) orelse return error.TestExpectedRewrite;
        try std.testing.expect(try forms.legalize(arena.allocator(), view) == null);
        try std.testing.expect(original.blocks.items[0].instructions.items[0].kind == .binary);
        try std.testing.expectEqual(case.exact, original.blocks.items[0].instructions.items[0].kind.binary.flags.exact);
        const call = view.blocks.items[0].instructions.items[0].kind.call;
        try std.testing.expectEqualStrings(case.symbol, call.callee);
        try std.testing.expect(call.ret_ty.eql(.{ .int = 128 }) and call.args.items.len == 2);
        try std.testing.expectEqualStrings("__zllvm_scalar_form_0", call.args.items[0].value.named);
        try std.testing.expectEqualStrings("right", call.args.items[1].value.named);
        try std.testing.expectEqualStrings("answer", view.blocks.items[0].instructions.items[0].result.?);
        module.functions.items[0] = view;
        defer module.functions.items[0] = original;
        try module.verify();
    }
    for ([_][]const u8{ "__udivti3", "\"__udi\\76ti3\"" }) |name| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i128 @{s}(i128 %a, i128 %b) {{\nentry:\n %r = udiv i128 %a, %b\n ret i128 %r\n}}\n", .{name});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect(try forms.legalize(arena.allocator(), module.functions.items[0]) == null);
    }
}

test "pair division materializes full width literal arguments without mutating source" {
    for ([_][]const u8{ "udiv", "urem", "sdiv", "srem" }) |op| {
        for ([_]bool{ false, true }) |literal_left| {
            const source = try std.fmt.allocPrint(
                std.testing.allocator,
                "declare i128 @__udivti3(i128, i128)\ndeclare i128 @__umodti3(i128, i128)\ndeclare i128 @__divti3(i128, i128)\ndeclare i128 @__modti3(i128, i128)\ndefine i128 @f(i128 %a) {{\nentry:\n %r = {s} i128 {s}, {s}\n ret i128 %r\n}}\n",
                .{ op, if (literal_left) "-79228162514264337593543950339" else "%a", if (literal_left) "%a" else "79228162514264337593543950339" },
            );
            defer std.testing.allocator.free(source);
            var module = try ir.Module.parse(std.testing.allocator, source);
            defer module.deinit();
            try module.verify();
            var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
            defer arena.deinit();
            const original = module.functions.items[0];
            const view = (try forms.legalize(arena.allocator(), original)) orelse return error.TestExpectedRewrite;
            try std.testing.expect(try forms.legalize(arena.allocator(), view) == null);
            try std.testing.expectEqual(@as(usize, 1), original.blocks.items[0].instructions.items.len);
            const call = view.blocks.items[0].instructions.items[view.blocks.items[0].instructions.items.len - 1].kind.call;
            try std.testing.expect(call.args.items[0].value == .named and call.args.items[1].value == .named);
            try std.testing.expectEqualStrings("a", call.args.items[if (literal_left) 1 else 0].value.named);
            module.functions.items[0] = view;
            defer module.functions.items[0] = original;
            try module.verify();
        }
    }
}

test "pair arithmetic constant logical shifts retain primitive projections and terminate" {
    for ([_]u8{ 0, 1, 7, 31, 32, 40, 48, 56, 63, 65, 96, 127 }) |amount| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\define i128 @shift(i128 %__zllvm_scalar_form_0) {{
            \\entry:
            \\ %answer = lshr i128 %__zllvm_scalar_form_0, {d}
            \\ ret i128 %answer
            \\}}
        , .{amount});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const original = module.functions.items[0];
        const view = (try forms.legalize(arena.allocator(), original)) orelse return error.TestExpectedRewrite;
        try std.testing.expect(try forms.legalize(arena.allocator(), view) == null);
        try std.testing.expectEqual(@as(usize, 1), original.blocks.items[0].instructions.items.len);
        try std.testing.expectEqual(@as(i128, amount), original.blocks.items[0].instructions.items[0].kind.binary.rhs.int);
        module.functions.items[0] = view;
        defer module.functions.items[0] = original;
        try module.verify();
    }
}

test "pair arithmetic cleanup owns removals and preserves memory and calls" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\declare void @sink(i128)
        \\define void @keep(i64 %a, i128 %b, ptr %p) {
        \\entry:
        \\ %root = zext i64 %a to i128
        \\ %unused = shl i128 %root, 64
        \\ %live = add i128 %root, %b
        \\ store i128 %live, ptr %p
        \\ %loaded = load i128, ptr %p
        \\ call void @sink(i128 %live)
        \\ %dead_a = zext i64 %a to i128
        \\ %dead_b = or i128 %dead_a, 7
        \\ ret void
        \\}
    );
    defer module.deinit();
    try module.verify();
    const original = module.functions.items[0];
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var view = original;
    view.blocks = try original.blocks.clone(arena.allocator());
    for (view.blocks.items) |*block| block.instructions = try block.instructions.clone(arena.allocator());
    try std.testing.expectEqual(@as(usize, 3), try cleanup.removeUnused(arena.allocator(), &view));
    for (original.blocks.items[0].instructions.items) |inst| try std.testing.expect(!inst.removed);
    for ([_]usize{ 0, 2, 3, 4, 5 }) |index| try std.testing.expect(!view.blocks.items[0].instructions.items[index].removed);
    try std.testing.expectEqual(@as(usize, 0), try cleanup.removeUnused(arena.allocator(), &view));
    var private = module;
    private.functions = try module.functions.clone(arena.allocator());
    private.functions.items[0] = view;
    try private.verify();
    try module.verify();
}

test "pair arithmetic cleanup rejects opaque reference proofs before removing definitions" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\declare void @sink()
        \\define void @opaque(i64 %a) {
        \\entry:
        \\ %value = zext i64 %a to i128
        \\ call void @sink()
        \\ ret void
        \\}
    );
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var view = module.functions.items[0];
    view.blocks = try view.blocks.clone(arena.allocator());
    for (view.blocks.items) |*block| block.instructions = try block.instructions.clone(arena.allocator());
    // Exercise a valid LLVM bundle that this parser deliberately leaves
    // outside its nonempty-bundle envelope. Cleanup cannot prove its uses.
    view.blocks.items[0].instructions.items[1].kind.call.operand_bundle = "[ \"deopt\"(i128 %value) ]";
    try std.testing.expectEqual(@as(usize, 0), try cleanup.removeUnused(arena.allocator(), &view));
    try std.testing.expect(!view.blocks.items[0].instructions.items[0].removed);
    try module.verify();
}

test "pair arithmetic cleanup use counts retain quoted identifier aliases" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i128 @alias(i64 %a) {
        \\entry:
        \\ %"pair" = zext i64 %a to i128
        \\ ret i128 %"pair"
        \\}
    );
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var view = module.functions.items[0];
    view.blocks = try view.blocks.clone(arena.allocator());
    for (view.blocks.items) |*block| block.instructions = try block.instructions.clone(arena.allocator());
    view.blocks.items[0].terminator.?.ret.value = .{ .named = "pair" };
    try std.testing.expectEqual(@as(usize, 0), try cleanup.removeUnused(arena.allocator(), &view));
    try std.testing.expect(!view.blocks.items[0].instructions.items[0].removed);
    try module.verify();
}

test "pair arithmetic private scalar expansion retains inputs and reaches a fixed point" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i128 @calculate(i128 %a, i128 %b) {
        \\entry:
        \\ %product = mul nuw i128 %a, %b
        \\ %shifted = ashr i128 %product, 65
        \\ %result = sdiv i128 %shifted, 1000000000
        \\ ret i128 %result
        \\}
    );
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const original = module.functions.items[0];
    const expanded = (try forms.legalize(arena.allocator(), original)).?;
    try std.testing.expectEqual(@as(usize, 3), original.blocks.items[0].instructions.items.len);
    try std.testing.expect(original.blocks.items[0].instructions.items[0].kind.binary.flags.nuw);
    try std.testing.expectEqual(original.params.items.ptr, expanded.params.items.ptr);
    try std.testing.expectEqual(original.ret_ty, expanded.ret_ty);
    try std.testing.expect((try forms.legalize(arena.allocator(), expanded)) == null);
    for (expanded.blocks.items[0].instructions.items) |inst| {
        try std.testing.expect(inst.kind != .call and inst.kind != .alloca);
        if (inst.kind == .binary) try std.testing.expect(!inst.kind.binary.flags.any());
    }
}

test "pair arithmetic unsupported divisors operands widths and vectors stay closed" {
    for ([_][]const u8{
        "define i128 @f(i128 %a) {\nentry:\n %r = udiv i128 %a, 0\n ret i128 %r\n}\n",
        "define i128 @f(i128 %a) {\nentry:\n %r = sdiv i128 %a, 0\n ret i128 %r\n}\n",
        "define i128 @f(i128 %a) {\nentry:\n %r = udiv i128 %a, undef\n ret i128 %r\n}\n",
        "define i128 @f(i128 %a) {\nentry:\n %r = mul i128 %a, undef\n ret i128 %r\n}\n",
        "define i96 @f(i96 %a, i96 %b) {\nentry:\n %r = mul i96 %a, %b\n ret i96 %r\n}\n",
        "define <2 x i64> @f(<2 x i64> %a, <2 x i64> %b) {\nentry:\n %r = mul <2 x i64> %a, %b\n ret <2 x i64> %r\n}\n",
    }) |source| {
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try forms.legalize(arena.allocator(), module.functions.items[0])) == null);
    }
}

test "pair arithmetic reuses product words after observing the low word" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i128 @project(i64 %a, i64 %b, ptr %out) {
        \\entry:
        \\ %wide_a = zext i64 %a to i128
        \\ %wide_b = zext i64 %b to i128
        \\ %product = mul i128 %wide_a, %wide_b
        \\ %low = trunc i128 %product to i64
        \\ store i64 %low, ptr %out, align 8
        \\ %count = zext i7 -64 to i128
        \\ %high = lshr i128 %product, %count
        \\ ret i128 %high
        \\}
    );
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const original = module.functions.items[0];
    const expanded = (try forms.legalize(arena.allocator(), original)).?;
    for (expanded.blocks.items[0].instructions.items) |inst| {
        if (inst.kind == .binary and inst.kind.binary.ty.eql(.{ .int = 128 }))
            try std.testing.expect(inst.kind.binary.op != .lshr);
    }
    try std.testing.expectEqual(ir.BinaryOp.lshr, original.blocks.items[0].instructions.items[6].kind.binary.op);
    try std.testing.expect((try forms.legalize(arena.allocator(), expanded)) == null);
}

test "pair arithmetic reuses expanded words for immediate high projections" {
    var module = try ir.Module.parse(std.testing.allocator,
        \\define i64 @carry(i64 %a, i64 %b, ptr %out) {
        \\entry:
        \\ %wide_a = zext i64 %a to i128
        \\ %wide_b = zext i64 %b to i128
        \\ %sum = add i128 %wide_a, %wide_b
        \\ %alias = or i128 %sum, 0
        \\ %high = lshr i128 %alias, 64
        \\ %carry = trunc i128 %high to i64
        \\ store i128 %sum, ptr %out, align 1
        \\ ret i64 %carry
        \\}
    );
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const original = module.functions.items[0];
    const expanded = (try forms.legalize(arena.allocator(), original)).?;
    for (expanded.blocks.items[0].instructions.items) |inst| {
        if (inst.kind == .binary and inst.kind.binary.ty.eql(.{ .int = 128 }))
            try std.testing.expect(inst.kind.binary.op != .lshr);
    }
    var private = module;
    private.functions = try module.functions.clone(arena.allocator());
    private.functions.items[0] = expanded;
    try private.verify();
    try std.testing.expectEqual(original.params.items.ptr, expanded.params.items.ptr);
    try std.testing.expectEqual(ir.BinaryOp.lshr, original.blocks.items[0].instructions.items[4].kind.binary.op);
    try std.testing.expect((try forms.legalize(arena.allocator(), expanded)) == null);
}
