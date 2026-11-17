//! Read-only full native snapshot for an explicit recovery authorization.
const std = @import("std");
const audit = @import("vendor/file_audit/src/root.zig");
pub fn main(init: std.process.Init) !void {
    const a = init.arena.allocator();
    const args = try init.minimal.args.toSlice(a);
    if (args.len == 3 and std.mem.eql(u8, args[1], "--verify")) {
        const bytes = try std.Io.Dir.cwd().readFileAlloc(init.io, args[2], a, .limited(32 * 1024 * 1024));
        const saved = try std.json.parseFromSlice(audit.Snapshot, a, bytes, .{});
        return audit.verify(init.gpa, init.io, saved.value);
    }
    if (args.len != 2) return error.ExpectedScratchDirectory;
    var snapshot = try audit.scan(init.gpa, init.io, args[1], .{ .hash_files = true });
    defer snapshot.deinit();
    var buffer: [65536]u8 = undefined;
    var out = std.Io.File.stdout().writerStreaming(init.io, &buffer);
    try std.json.Stringify.value(snapshot.value, .{}, &out.interface);
    try out.interface.writeByte('\n');
    try out.interface.flush();
}
