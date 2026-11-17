//! Isolated qualification entrypoint. Never used for real workspace disposal.
const std = @import("std");
const collector = @import("clean_storage.zig");
const core = @import("storage_cleanup/engine.zig");
const mutation = @import("storage_cleanup/mutation.zig");
const u = @import("validation/common.zig");
var reader: ?std.process.Child = null;

pub fn storageCleanupBeforeUnlink(e: *core.Engine, quarantine: []const u8) !void {
    const mode = e.c.env.get("RECOVERY_ROLLBACK_READER") orelse return;
    if (std.mem.indexOf(u8, e.c.root, "/recovery-cases/") == null or
        !std.mem.eql(u8, try e.c.read(try e.c.join(&.{"fixture-only.marker"})), "interrupted-recovery-fixture\n")) return error.NotAnIsolatedRecoveryFixture;
    if (!std.mem.eql(u8, mode, "command") and !std.mem.eql(u8, mode, "descriptor")) return error.InvalidFixtureReader;
    var env = try e.c.env.clone(e.c.a);
    const ready = try e.c.join(&.{ e.output, "fixture-reader-ready" });
    try env.put("RECOVERY_READER_READY", ready);
    try env.put("RECOVERY_READER_PATH", try e.absolute(try e.c.fmt("{s}/local-cache/o/cache", .{quarantine})));
    const argv: []const []const u8 = if (std.mem.eql(u8, mode, "command")) &.{ "/proc/self/exe", "__reader-command", try e.absolute(quarantine) } else &.{ "/proc/self/exe", "__reader-descriptor" };
    reader = try std.process.spawn(e.c.io, .{ .argv = argv, .environ_map = &env, .stdin = .ignore, .stdout = .ignore, .stderr = .ignore });
    for (0..1000) |_| {
        if (u.exists(e.c.io, ready)) return;
        try std.Io.sleep(e.c.io, .fromMilliseconds(5), .awake);
    }
    return error.FixtureReaderDidNotStart;
}
pub fn main(init: std.process.Init) !void {
    defer if (reader) |*child| child.kill(init.io);
    const a = init.arena.allocator();
    const argv = try init.minimal.args.toSlice(a);
    if (argv.len > 1 and (std.mem.eql(u8, argv[1], "__reader-command") or std.mem.eql(u8, argv[1], "__reader-descriptor"))) {
        var file: ?std.Io.File = null;
        defer if (file) |f| f.close(init.io);
        if (std.mem.eql(u8, argv[1], "__reader-descriptor")) file = try std.Io.Dir.cwd().openFile(init.io, init.environ_map.get("RECOVERY_READER_PATH") orelse return error.MissingReaderPath, .{});
        const ready = try std.Io.Dir.cwd().createFile(init.io, init.environ_map.get("RECOVERY_READER_READY") orelse return error.MissingReadyPath, .{});
        try ready.writeStreamingAll(init.io, "ready\n");
        ready.close(init.io);
        try std.Io.sleep(init.io, .fromSeconds(30), .awake);
        return;
    }
    if (argv.len == 4 and std.mem.eql(u8, argv[1], "__compare-rollback")) {
        const before_bytes = try std.Io.Dir.cwd().readFileAlloc(init.io, argv[2], a, .limited(32 * 1024 * 1024));
        const before = try std.json.parseFromSlice(core.fa.Snapshot, a, before_bytes, .{});
        var after = try core.fa.scan(init.gpa, init.io, argv[3], .{ .hash_files = true });
        defer after.deinit();
        try mutation.compareMoved(before.value, after.value);
        return;
    }
    return collector.main(init);
}
