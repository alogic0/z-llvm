const std = @import("std");
const u = @import("common.zig");

pub fn sample(c: *u.Context, record: *u.Value) !void {
    const output = try c.capture(&.{ "df", "-B1", "--output=avail", c.root });
    var words = std.mem.tokenizeAny(u8, output, " \t\r\n");
    _ = words.next() orelse return error.InvalidDiskSample;
    const available = try std.fmt.parseInt(i64, words.next() orelse return error.InvalidDiskSample, 10);
    if (words.next() != null) return error.InvalidDiskSample;
    var row = try u.toValue(c.a, .{ .time_ns = std.Io.Clock.real.now(c.io).nanoseconds, .available_bytes = available });
    if (record.object.get("air_roots")) |roots| try u.put(c.a, &row, "air_files", try airFiles(c, try u.str(roots, "raw"), try u.str(roots, "cache")));
    try u.add(record.object.getPtr("samples").?, row);
}
pub fn airFiles(c: *u.Context, raw_root: []const u8, cache_root: []const u8) !u.Value {
    var result = u.array(c.a);
    for ([_][]const u8{ raw_root, cache_root }, [_][]const u8{ "raw", "cache" }) |root, role| for (u.modes) |mode| {
        const mode_path = try c.join(&.{ root, mode });
        var directory = std.Io.Dir.cwd().openDir(c.io, mode_path, .{ .iterate = true }) catch |err| switch (err) {
            error.FileNotFound => continue,
            else => return err,
        };
        defer directory.close(c.io);
        var entries = directory.iterate();
        while (try entries.next(c.io)) |entry| {
            if (entry.kind != .directory) continue;
            if (std.mem.eql(u8, role, "raw")) {
                if (!std.mem.startsWith(u8, entry.name, "work")) continue;
                try appendFile(c, &result, try c.join(&.{ mode_path, entry.name, "compiler.air" }), role, mode);
            } else {
                if (!std.mem.eql(u8, entry.name, "export")) continue;
                var exports = try directory.openDir(c.io, "export", .{ .iterate = true });
                defer exports.close(c.io);
                var files = exports.iterate();
                while (try files.next(c.io)) |file| if (std.mem.endsWith(u8, file.name, ".air")) {
                    try appendFile(c, &result, try c.join(&.{ mode_path, "export", file.name }), role, mode);
                };
            }
        }
    };
    return result;
}
fn appendFile(c: *u.Context, result: *u.Value, path: []const u8, role: []const u8, mode: []const u8) !void {
    const linux = std.os.linux;
    var state: linux.Statx = undefined;
    switch (linux.errno(linux.statx(linux.AT.FDCWD, try c.a.dupeSentinel(u8, path, 0), 0, .{ .INO = true, .SIZE = true, .BLOCKS = true }, &state))) {
        .SUCCESS => {},
        .NOENT => return,
        else => return error.AirStatFailed,
    }
    if (!state.mask.INO or !state.mask.SIZE or !state.mask.BLOCKS) return error.IncompleteAirStat;
    const major: u64 = state.dev_major;
    const minor: u64 = state.dev_minor;
    const device = (major & 0xfff) << 8 | (minor & 0xff) | (major & ~@as(u64, 0xfff)) << 32 | (minor & ~@as(u64, 0xff)) << 12;
    try u.add(result, try u.toValue(c.a, .{ .path = path, .role = role, .mode = mode, .device = device, .inode = state.ino, .bytes = state.size, .allocated_bytes = state.blocks * 512 }));
}
