//! Producer-owned holds expire only against the hash-bound terminal receipt.
const std = @import("std");
const core = @import("engine.zig");
const p = core.p;
const lifecycle = @import("../validation/storage_lifecycle.zig");

pub fn validate(e: *core.Engine, job: lifecycle.Job) !bool {
    if (!std.mem.eql(u8, job.schema, "zllvm-storage-job-v1") or !p.candidate(job.run_root) or
        !p.within(job.run_root, job.producer.path) or !p.relative(job.producer.path) or job.started_ns <= 0 or
        (!std.mem.eql(u8, job.working_directory, ".") and (!p.candidate(job.working_directory) or !p.within(job.run_root, job.working_directory)))) return error.InvalidStorageJob;
    if (job.external_working_directory) |cwd| {
        if (!std.mem.eql(u8, job.working_directory, ".") or !std.fs.path.isAbsolute(cwd) or
            !std.mem.eql(u8, cwd, try std.fs.path.resolve(e.c.a, &.{cwd}))) return error.InvalidStorageJob;
    }
    if (job.state == .running) return false;
    try e.check(job.producer);
    var parsed = try e.load(e.c.gpa, job.producer.path);
    defer parsed.deinit();
    const v = parsed.value;
    if (!core.eq(v, "status", "finished") or (!core.eq(v, "outcome", "completed") and !core.eq(v, "outcome", "canceled")) or
        try core.integer(v, "started_ns") != job.started_ns or try core.integer(v, "finished_ns") <= job.started_ns) return error.StorageJobNotTerminal;
    _ = try core.integer(v, "actual_returncode");
    const cwd = job.external_working_directory orelse if (std.mem.eql(u8, job.working_directory, ".")) e.c.root else try e.absolute(job.working_directory);
    if (!core.eq(v, "cwd", cwd)) return error.CacheWorkingDirectoryMismatch;
    return true;
}

pub fn scan(e: *core.Engine, discover: bool) !void {
    const names = try e.discoverPaths(&.{ "-g", "*.json" }, &.{lifecycle.jobs_directory});
    var lines = std.mem.tokenizeScalar(u8, names, '\n');
    while (lines.next()) |name| {
        try e.addControl(name);
        var parsed = try e.load(e.c.gpa, name);
        defer parsed.deinit();
        var record = try std.json.parseFromValue(lifecycle.Job, e.c.gpa, parsed.value, .{});
        defer record.deinit();
        const job = record.value;
        if (!try validate(e, job)) {
            if (!discover) try e.held.append(e.c.a, try e.c.a.dupe(u8, job.run_root));
            continue;
        }
        if (!discover) continue;
        try e.addControl(job.producer.path);
        // External source trees and explicit shared caches stay caller-owned.
        // Their default caches are inside the separately verified workspace.
        const request = if (job.external_working_directory != null) null else @import("private_cache.zig").request(e, .{
            .producer = job.producer.path,
            .run_root = job.run_root,
            .working_directory = job.working_directory,
        }, "Closed producer job; temporary private caches, with diagnostics retained") catch |err| switch (err) {
            error.UnsupportedCacheCommand => null,
            else => return err,
        };
        if (request) |r| try stage(e, r);
        const outputs = try e.discoverPaths(&.{ "-g", "capture-zllvm", "-g", "linked-harness.s" }, &.{job.run_root});
        var paths = std.mem.tokenizeScalar(u8, outputs, '\n');
        while (paths.next()) |path| {
            // A non-passed subtest is deliberately retained for investigation.
            const r = @import("generated.zig").request(e, path, "Completed job's verified generated test output") catch |err| {
                try e.c.print("Retained generated output {s}: {s}\n", .{ path, @errorName(err) });
                continue;
            };
            try stage(e, r);
        }
    }
}

fn stage(e: *core.Engine, r: p.Release) !void {
    // Another explicit owner decision takes precedence over automatic inference.
    for (r.artifacts) |artifact| for (e.actions.items) |old| if (p.overlaps(old.path, artifact.path)) return;
    const path = try e.c.fmt("{s}/job-release-{d}.json", .{ e.output, e.actions.items.len });
    try e.write(path, r);
    e.now_ns = std.Io.Clock.real.now(e.c.io).nanoseconds;
    try e.discoverRelease(path, true);
}
