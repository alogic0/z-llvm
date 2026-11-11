//! Explicit self-rebuild affinity; the initial emitter keeps its input identity.
const std = @import("std");

pub const launcher = "/usr/bin/taskset";

pub fn cpuIndex(text: []const u8) !u32 {
    if (text.len == 0) return error.InvalidSelfCpu;
    for (text) |byte| if (!std.ascii.isDigit(byte)) return error.InvalidSelfCpu;
    return std.fmt.parseInt(u32, text, 10) catch return error.InvalidSelfCpu;
}

pub fn command(a: std.mem.Allocator, cpu: ?[]const u8, argv: []const []const u8) ![]const []const u8 {
    if (argv.len == 0) return error.EmptySelfCommand;
    const text = cpu orelse return argv;
    const index = try std.fmt.allocPrint(a, "{d}", .{try cpuIndex(text)});
    return std.mem.concat(a, []const u8, &.{ &.{ launcher, "--cpu-list", index }, argv });
}

test "self affinity preserves every frontend argument and leaves default commands unchanged" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const argv: []const []const u8 = &.{ "/candidate/zig", "build", "--build-file", "/source with spaces/build.zig", "-Dcpu=baseline" };
    try std.testing.expect((try command(a, null, argv)).ptr == argv.ptr);
    const wrapped = try command(a, "000", argv);
    for ([_][]const u8{ launcher, "--cpu-list", "0" }, wrapped[0..3]) |expected, actual| try std.testing.expectEqualStrings(expected, actual);
    for (argv, wrapped[3..]) |expected, actual| try std.testing.expectEqualStrings(expected, actual);
}

test "self affinity rejects malformed controls and empty commands" {
    for ([_][]const u8{ "", "-1", "+1", "0,1", "0-3", " 0", "0 ", "4294967296", "0;true" }) |text| {
        try std.testing.expectError(error.InvalidSelfCpu, cpuIndex(text));
    }
    try std.testing.expectEqual(@as(u32, 17), try cpuIndex("17"));
    try std.testing.expectError(error.EmptySelfCommand, command(std.testing.allocator, null, &.{}));
}
