//! Job-owned storage holds. A terminal receipt closes only its own hold.
//! Manual/queued investigation holds remain independent.
const std = @import("std");
const u = @import("common.zig");
const p = @import("../storage_cleanup/policy.zig");
const store = @import("../zllvm_artifact_store/store.zig");

pub const jobs_directory = "local-state/storage-cleanup/jobs";
pub const Job = struct {
    schema: []const u8 = "zllvm-storage-job-v1",
    state: enum { running, finished } = .running,
    run_root: []const u8,
    working_directory: []const u8,
    producer: p.Evidence,
    started_ns: i128,
};
pub const Session = struct {
    root: []const u8,
    path: []const u8,
    job: Job,
    lease: std.Io.File,
    pub fn close(s: Session, c: *u.Context) void {
        s.lease.unlock(c.io);
        s.lease.close(c.io);
    }
    pub fn finish(s: Session, c: *u.Context) !void {
        const receipt = try c.load(try c.fmt("{s}/{s}", .{ s.root, s.job.producer.path }));
        const actual = receipt.object.get("actual_returncode") orelse return;
        if (actual != .integer) return; // launch/supervision failures keep the hold
        var job = s.job;
        job.state = .finished;
        job.producer.sha256 = try c.digest(try c.fmt("{s}/{s}", .{ s.root, job.producer.path }));
        try c.writeJson(s.path, job);
    }
};

pub fn projectRoot(c: *u.Context) !?[]const u8 {
    var root: ?[]const u8 = c.root;
    while (root) |path| : (root = std.fs.path.dirname(path)) {
        if (u.exists(c.io, try c.fmt("{s}/docs/storage_cleanup_policy.json", .{path})) and
            u.exists(c.io, try c.fmt("{s}/tools/clean-storage", .{path}))) return path;
    }
    return null;
}

pub fn start(c: *u.Context, output: []const u8, producer: []const u8, started_ns: i128) !?Session {
    const root = (try projectRoot(c)) orelse return null;
    if (!p.within(root, output) or !p.within(output, producer)) return null;
    const run = if (p.within(try c.fmt("{s}/local-state/validations", .{root}), c.root)) c.root else output;
    const run_relative = run[root.len + 1 ..];
    if (!p.candidate(run_relative)) return null;
    var state = try store.openDirectory(c.io, try c.fmt("{s}/local-state/storage-cleanup", .{root}), true);
    defer state.close(c.io);
    const lease = try state.createFile(c.io, "cleanup.lock", .{ .truncate = false });
    errdefer lease.close(c.io);
    try lease.lock(c.io, .shared);
    const jobs = try store.openDirectory(c.io, try c.fmt("{s}/{s}", .{ root, jobs_directory }), true);
    jobs.close(c.io);
    const session: Session = .{
        .root = root,
        .path = try c.fmt("{s}/{s}/{d}-{d}.json", .{ root, jobs_directory, started_ns, std.os.linux.getpid() }),
        .job = .{
            .run_root = run_relative,
            .working_directory = if (std.mem.eql(u8, c.root, root)) "." else c.root[root.len + 1 ..],
            .producer = .{ .path = producer[root.len + 1 ..], .sha256 = "" },
            .started_ns = started_ns,
        },
        .lease = lease,
    };
    try u.json.writeAtomic(c.gpa, c.io, .{ .path = session.path, .replace = false }, session.job);
    return session;
}

/// A terminal exec drops the producer's argv and descriptors before collection.
/// A failed hook preserves the producer result and leaves durable job evidence.
pub fn collect(c: *u.Context, root: []const u8, code: u8) void {
    c.env.put("ZLLVM_PROJECT_ROOT", root) catch return;
    const argv = [_][]const u8{
        c.fmt("{s}/tools/clean-storage", .{root}) catch return,
        "__finish-job",
        c.fmt("{d}", .{code}) catch return,
    };
    const err = std.process.replace(c.io, .{ .argv = &argv, .cwd = .{ .path = root }, .environ_map = &c.env });
    std.Io.File.stderr().writeStreamingAll(c.io, c.fmt("storage completion hook: {s}; job evidence retained\n", .{@errorName(err)}) catch return) catch {};
}
