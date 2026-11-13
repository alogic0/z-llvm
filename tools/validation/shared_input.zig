//! Capture immutable IR in the project store and install a read-only alias.
const std = @import("std");
const u = @import("common.zig");
const storage = @import("../zllvm_artifact_store/store.zig");
const lifecycle = @import("storage_lifecycle.zig");

pub fn capture(c: *u.Context, source: []const u8, destination: []const u8) !void {
    const root = (try lifecycle.projectRoot(c)) orelse {
        // Standalone fixtures without project storage keep independent inputs.
        const out = try std.Io.Dir.cwd().createFile(c.io, destination, .{ .exclusive = true });
        out.close(c.io);
        return c.copy(source, destination);
    };
    var parent = try storage.openDirectory(c.io, std.fs.path.dirname(source).?, false);
    defer parent.close(c.io);
    const file = try parent.openFile(c.io, std.fs.path.basename(source), .{ .follow_symlinks = false, .allow_directory = false });
    defer file.close(c.io);
    const identity = try storage.hashFile(c.io, file);
    var store = try storage.Store.openWaiting(c.a, c.io, try c.fmt("{s}/local-state/artifacts", .{root}), true);
    defer store.deinit();
    try store.publishFile(file, .{ .name = "input.ll", .sha256 = &identity.hash, .bytes = identity.bytes });
    try store.linkInput(&identity.hash, destination);
}
