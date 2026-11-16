const std = @import("std");
const builtin = @import("builtin");
const ir = @import("../ir.zig");
const codegen = @import("../codegen.zig");
const encoding = @import("../mc/encoding.zig");
const composed = @import("../codegen/x86_64/generic_cfg/composed_selector_impl.zig");

test "value-use long scalar sources select strictly without private renaming and execute" {
    if (builtin.cpu.arch != .x86_64 or builtin.os.tag != .linux) return error.SkipZigTest;
    const source = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "test/real_programs/identity_names.ll", std.testing.allocator, .limited(131072));
    defer std.testing.allocator.free(source);
    const prefix: [768]u8 = @splat('n');
    const extended_prefix: [4096]u8 = @splat('n');
    const extended = try std.mem.replaceOwned(u8, std.testing.allocator, source, &prefix, &extended_prefix);
    defer std.testing.allocator.free(extended);
    for ([_][]const u8{ source, extended }, [_]usize{ 512, 4096 }) |variant, minimum| {
        var module = try ir.Module.parse(std.testing.allocator, variant);
        defer module.deinit();
        try module.verify();
        var before: std.Io.Writer.Allocating = .init(std.testing.allocator);
        defer before.deinit();
        try @import("../ir/printer.zig").print(module, &before.writer);
        var definitions: usize = 0;
        for (module.functions.items) |function| {
            if (function.blocks.items.len == 0) continue;
            const which = definitions;
            definitions += 1;
            try std.testing.expect(function.params.items[0].name.len > minimum);
            try std.testing.expect(function.params.items[1].name.len > minimum);
            try std.testing.expect(!std.mem.eql(u8, function.params.items[0].name, function.params.items[1].name));
            var machine = codegen.x86_64.MachineFunction.init(function.name, function.ret_ty);
            defer machine.deinit(std.testing.allocator);
            switch (try composed.tryLowerComposedCfg(std.testing.allocator, &machine, function)) {
                .selected => {},
                .unsupported => return error.TestUnexpectedResult,
            }
            try codegen.x86_64.verifyFunction(machine);
            if (which == 3) continue; // Native linked canary qualifies the external relocation.
            const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
            defer std.testing.allocator.free(bytes);
            const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
            defer std.posix.munmap(mapping);
            @memcpy(mapping, bytes);
            const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(mapping.ptr);
            for (0..128) |input| {
                const left = @as(u64, @intCast(input)) *% 0x9e3779b97f4a7c15;
                const right = ~left +% @as(u64, @intCast(input));
                const expected = switch (which) {
                    0 => left +% right,
                    1 => left -% right,
                    2 => ((left ^ right) +% left) -% right,
                    else => unreachable,
                };
                try std.testing.expectEqual(expected, run(left, right));
            }
        }
        try std.testing.expectEqual(@as(usize, 4), definitions);
        var after: std.Io.Writer.Allocating = .init(std.testing.allocator);
        defer after.deinit();
        try @import("../ir/printer.zig").print(module, &after.writer);
        try std.testing.expectEqualStrings(before.written(), after.written());
    }
}
