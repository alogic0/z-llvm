const std = @import("std");
const ir = @import("../../../ir.zig");
test "optional assembly hints and plain pointer facts preserve defined scalar and memory results" {
    const a = std.testing.allocator;
    for ([_][]const u8{ "tail", "notail" }) |hint| {
        const source = try std.fmt.allocPrint(a, "attributes #7 = {{ nounwind }}\ndefine i64 @probe(ptr %input,ptr %out,i32 %value) {{\nentry:\n" ++
            " {0s} call void asm sideeffect \"\",\"m,~{{dirflag}},~{{fpsr}},~{{flags}}\"(ptr nonnull %input) #7\n" ++
            " %v = {0s} call i32 asm \"addl ${{1}}, ${{0}}\",\"=r,r,0,~{{flags}},~{{dirflag}},~{{fpsr}},~{{flags}}\"(i32 13,i32 %value) #7\n" ++
            " %z = zext i32 %v to i64\n %k = {0s} call i64 asm sideeffect \"mov $$123, ${{0}}\",\"=r,~{{dirflag}},~{{fpsr}},~{{flags}}\"() #7\n" ++
            " %sum = add i64 %z,%k\n %loaded = load i64,ptr %input,align 1\n %answer = xor i64 %sum,%loaded\n store i64 %answer,ptr %out,align 1\n ret i64 %answer\n}}\n", .{hint});
        defer a.free(source);
        var module = try ir.Module.parse(a, source);
        defer module.deinit();
        try module.verify();
        var selected = try @import("../../../compilation.zig").select(a, "x86_64-unknown-linux-gnu", module.functions.items[0], .{ .generic_cfg_selector = true });
        defer selected.deinit(a);
        try @import("../verify.zig").verifyFunction(selected);
        const bytes = try @import("../../../mc/encoding.zig").encodeFunction(a, selected);
        defer a.free(bytes);
        const memory = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(memory);
        @memcpy(memory[0..bytes.len], bytes);
        const run: *const fn (*const u64, *u64, u32) callconv(.c) u64 = @ptrCast(memory.ptr);
        const input: u64 = 0xabcdef0123456789;
        for ([_]u32{ 0, 1, 13, 0x80000000, 0xffffffff }) |value| {
            const expected = (@as(u64, value +% 13) + 123) ^ input;
            var output: u64 = 0;
            try std.testing.expectEqual(expected, run(&input, &output, value));
            try std.testing.expectEqual(expected, output);
        }
        try std.testing.expectEqualStrings(hint, module.functions.items[0].blocks.items[0].instructions.items[0].kind.call.tail_kind.?);
        try module.verify();
    }
}
