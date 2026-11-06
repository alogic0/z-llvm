const std = @import("std");
const ir = @import("../../../ir.zig");

const cases = .{
    .{ @import("aligned_stack.zig"), "%candidate = alloca i32, align 32", true },
    .{ @import("boolean_values.zig"), "%candidate = trunc i32 %x to i1", false },
    .{ @import("comparison_forms.zig"), "%candidate = icmp ule i32 %x, 7", true },
    .{ @import("integer_forms.zig"), "%candidate = sext i32 %x to i64", false },
    .{ @import("integer_intrinsics.zig"), "%candidate = call i8 @llvm.umin.i8(i8 1, i8 2)", false },
    .{ @import("pair_arithmetic.zig"), "%candidate = add i128 1, 2", false },
    .{ @import("pair_memory.zig"), "store i128 7, ptr %out", true },
    .{ @import("scalar_forms.zig"), "%candidate = icmp sle i32 %x, 0", false },
    .{ @import("word_arithmetic.zig"), "%candidate = udiv i32 %x, 3", false },
};

fn legalize(comptime case: anytype, allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    const stage = case[0];
    return if (case[2]) stage.legalize(allocator, function, null) else stage.legalize(allocator, function);
}

test "deferred candidates leave unchanged and removed instructions allocation free" {
    inline for (cases) |case| {
        const text = "declare i8 @llvm.umin.i8(i8, i8)\n" ++
            "define i32 @unchanged(i32 %x, ptr %out) {\nentry:\n" ++
            " %head = add i32 %x, 1\n " ++ case[1] ++ "\n br label %exit\n" ++
            "exit:\n %tail = xor i32 %head, 2\n ret i32 %tail\n}\n";
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const function = module.functions.items[0];
        function.blocks.items[0].instructions.items[1].removed = true;
        var failing = std.testing.FailingAllocator.init(std.testing.allocator, .{ .fail_index = 0 });
        try std.testing.expect(try legalize(case, failing.allocator(), function) == null);
        try std.testing.expectEqual(0, failing.allocated_bytes);
        try std.testing.expect(!failing.has_induced_failure);
    }
}

test "deferred candidates preserve prefixes repeated rewrites terminators and source isolation" {
    inline for (cases) |case| for ([_]bool{ false, true }) |first_instruction| {
        const again = try std.mem.replaceOwned(u8, std.testing.allocator, case[1], "%candidate", "%again");
        defer std.testing.allocator.free(again);
        const changes = try std.fmt.allocPrint(std.testing.allocator, "{s}\n{s}\n", .{ case[1], again });
        defer std.testing.allocator.free(changes);
        const text = try std.fmt.allocPrint(
            std.testing.allocator,
            "declare i8 @llvm.umin.i8(i8, i8)\n" ++
                "define i32 @rewrite(i32 %x, ptr %out) {{\nentry:\n{s}" ++
                " %head = add i32 %x, 1\n br label %middle\n" ++
                "middle:\n %prefix = xor i32 %head, 2\n{s}" ++
                " %suffix = add i32 %prefix, 3\n br label %exit\n" ++
                "exit:\n %tail = xor i32 %suffix, 4\n ret i32 %tail\n}}\n",
            .{ if (first_instruction) changes else "", if (first_instruction) "" else changes },
        );
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const function = module.functions.items[0];
        var failing = std.testing.FailingAllocator.init(std.testing.allocator, .{ .fail_index = 0 });
        try std.testing.expectError(error.OutOfMemory, legalize(case, failing.allocator(), function));
        try module.verify();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const candidate = (try legalize(case, arena.allocator(), function)).?;
        try std.testing.expectEqual(3, candidate.blocks.items.len);
        for (function.blocks.items, candidate.blocks.items) |original, rewritten| {
            try std.testing.expectEqualStrings(original.name, rewritten.name);
            try std.testing.expect(original.instructions.items.ptr != rewritten.instructions.items.ptr);
            try std.testing.expectEqualDeep(original.terminator, rewritten.terminator);
        }
        const middle = candidate.blocks.items[1].instructions.items;
        try std.testing.expectEqualStrings("prefix", middle[0].result.?);
        try std.testing.expectEqualStrings("suffix", middle[middle.len - 1].result.?);
        try std.testing.expectEqualStrings("tail", candidate.blocks.items[2].instructions.items[0].result.?);
        var private_module = module;
        private_module.functions = try module.functions.clone(arena.allocator());
        private_module.functions.items[0] = candidate;
        try private_module.verify();
        candidate.blocks.items[2].instructions.items[0].removed = true;
        try std.testing.expect(!function.blocks.items[2].instructions.items[0].removed);
        try module.verify();
    };
}
