const std = @import("std");
const options = @import("test_options");
const a = std.testing.allocator;
const io = std.testing.io;

const Case = struct {
    text: []const u8,
    pattern: []const u8,
    mode: []const u8 = "match",
    status: u8 = 0,
    diagnostic: []const u8 = "",
};

test "tool regex preserves linewise assertions POSIX classes Unicode and process diagnostics" {
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();
    var buffer: [4096]u8 = undefined;
    const directory = buffer[0..try temp.dir.realPath(io, &buffer)];
    const path = try std.fs.path.join(a, &.{ directory, "input.txt" });
    defer a.free(path);
    for ([_]Case{
        .{ .text = "before\r\nhello 123\r\nafter", .pattern = "^[[:alpha:]]+[[:space:]]+[[:digit:]]+$" },
        .{ .text = "before\nlast", .pattern = "^last$" },
        .{ .text = "", .pattern = "^$" },
        .{ .text = "prefix\nΣσ\n", .pattern = "^\\p{Greek}+$" },
        .{ .text = "CATDog", .pattern = "(?i)^cat(?-i:Dog)$" },
        .{ .text = "ab\tF09\n", .pattern = "^[[:alnum:]]+[[:blank:]][[:xdigit:]]+$" },
        .{ .text = "A\nB", .pattern = "A.+B", .mode = "absent" },
        .{ .text = "other", .pattern = "needle", .status = 1, .diagnostic = "missing regex match in " },
        .{ .text = "needle", .pattern = "needle", .mode = "absent", .status = 1, .diagnostic = "unexpected regex match in " },
        .{ .text = "other", .pattern = "[", .status = 1, .diagnostic = "invalid regex pattern for " },
    }) |case| {
        try temp.dir.writeFile(io, .{ .sub_path = "input.txt", .data = case.text });
        const result = try std.process.run(a, io, .{
            .argv = &.{ options.probe, case.mode, path, case.pattern },
            .stdout_limit = .limited(16 * 1024),
            .stderr_limit = .limited(16 * 1024),
        });
        defer a.free(result.stdout);
        defer a.free(result.stderr);
        try std.testing.expectEqual(std.process.Child.Term{ .exited = case.status }, result.term);
        try std.testing.expectEqualStrings("", result.stdout);
        if (case.diagnostic.len == 0) {
            try std.testing.expectEqualStrings("", result.stderr);
        } else {
            try std.testing.expect(std.mem.startsWith(u8, result.stderr, case.diagnostic));
            try std.testing.expect(std.mem.indexOf(u8, result.stderr, case.pattern) != null);
        }
    }
}
