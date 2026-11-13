const std = @import("std");
const t = std.testing;
const u = @import("../validation/common.zig");
const core = @import("engine.zig");
const mutation = @import("mutation.zig");
const p = core.p;
const run = "local-state/validations/test/build";
const cache = run ++ "/zig-local-cache";
const report = run ++ "/report.json";
const output = "local-state/retirements/test-cleanup";
const released = "local-state/validations/test/batch/released";
const Fixture = struct {
    tmp: t.TmpDir,
    arena: std.heap.ArenaAllocator,
    c: u.Context,
    fn init() !*Fixture {
        const f = try t.allocator.create(Fixture);
        errdefer t.allocator.destroy(f);
        f.tmp = t.tmpDir(.{ .iterate = true });
        errdefer f.tmp.cleanup();
        f.arena = .init(t.allocator);
        errdefer f.arena.deinit();
        const a = f.arena.allocator();
        f.c = .{ .a = a, .gpa = t.allocator, .io = t.io, .root = try f.tmp.dir.realPathFileAlloc(t.io, ".", a), .env = try t.environ.createMap(a), .quiet = true };
        for ([_][]const u8{ output, "local-state/storage-cleanup", run, cache ++ "/o", "local-state/validations/test/source", "toolchain" }) |path| try f.tmp.dir.createDirPath(t.io, path);
        return f;
    }
    fn deinit(f: *Fixture) void {
        f.tmp.cleanup();
        f.arena.deinit();
        t.allocator.destroy(f);
    }
    fn write(f: *Fixture, path: []const u8, bytes: []const u8) !void {
        try f.tmp.dir.writeFile(t.io, .{ .sub_path = path, .data = bytes });
    }
    fn engine(f: *Fixture) core.Engine {
        var e = core.Engine.init(&f.c, .{ .minimum_idle_hours = 0 }, output, f.c.env.get("ZIGREP") orelse "zigrep");
        e.now_ns += std.time.ns_per_s * 60;
        return e;
    }
    fn build(f: *Fixture, e: *core.Engine) !void {
        try f.write(cache ++ "/o/object", "cache object");
        try f.write(run ++ "/z_llvm", "compiler");
        try f.write(run ++ "/build.stdout", "successful build output");
        try f.write(run ++ "/build.stderr", "");
        try f.write("local-state/validations/test/source/main.zig", "pub fn main() void {}");
        try f.write("toolchain/zig", "compiler toolchain");
        const source = try e.absolute("local-state/validations/test/source");
        const compiler = try e.absolute(run ++ "/z_llvm");
        try e.write(report, .{ .status = "passed", .source_root = source, .compiler = compiler, .compiler_sha256 = try e.digest(compiler), .source_sha256 = .{ .@"main.zig" = try e.digest("local-state/validations/test/source/main.zig") }, .zig = try e.absolute("toolchain/zig"), .zig_sha256 = try e.digest("toolchain/zig"), .commands = .{.{ .actual_returncode = 0, .outcome = "completed", .argv = [_][]const u8{ "zig", "build-exe", "--cache-dir", try e.absolute(cache), try e.c.fmt("-Mroot={s}/main.zig", .{source}), try e.c.fmt("-femit-bin={s}", .{compiler}) }, .stdout = try e.absolute(run ++ "/build.stdout"), .stderr = try e.absolute(run ++ "/build.stderr") }} });
    }
    fn release(f: *Fixture, e: *core.Engine, kind: @FieldType(p.Artifact, "kind"), complete: bool, successor_passed: bool, failed_without_diagnostic: bool) !usize {
        try f.build(e);
        try f.tmp.dir.createDirPath(t.io, released);
        const path = try e.c.fmt("{s}/{s}", .{ released, switch (kind) {
            .log => "old.log",
            .raw_trace => "profile.events.jsonl",
            .build_output => "result.o",
        } });
        try f.write(path, if (kind == .build_output and complete) "\x7fELFsynthetic-object" else "original payload");
        try f.write(released ++ "/input.ll", "original input");
        try e.write(released ++ "/producer.json", .{ .status = if (failed_without_diagnostic) "finished" else "passed", .actual_returncode = if (failed_without_diagnostic) @as(i32, 1) else 0 });
        try e.write(released ++ "/successor.json", .{ .status = if (successor_passed) "passed" else "failed" });
        try e.write(released ++ "/top.json", .{ .backend = .{ .path = try e.absolute(run ++ "/z_llvm"), .sha256 = try e.digest(run ++ "/z_llvm") } });
        try e.write(released ++ "/backend.json", .{ .status = "passed" });
        var rows: std.ArrayList(p.Retained) = .empty;
        for ([_]struct { path: []const u8, role: @FieldType(p.Retained, "role") }{
            .{ .path = "local-state/validations/test/source/main.zig", .role = .source },
            .{ .path = released ++ "/input.ll", .role = .input },
            .{ .path = report, .role = .build },
            .{ .path = released ++ "/producer.json", .role = .result },
            .{ .path = released ++ "/top.json", .role = .other },
            .{ .path = released ++ "/backend.json", .role = .other },
            .{ .path = run ++ "/z_llvm", .role = .compiler },
        }) |r| try rows.append(f.c.a, .{ .path = r.path, .role = r.role, .sha256 = try e.digest(r.path) });
        if (kind == .raw_trace) {
            try e.write(released ++ "/audit.json", .{
                .schema = "zllvm-native-event-audit-v1",
                .status = "verified",
                .path = path,
                .sha256 = try e.digest(path),
                .whole_stream_read = true,
                .whole_stream_semantically_valid = true,
                .report_binding_verified = true,
                .complete = complete,
                .stream_metadata_unchanged = true,
                .recorded_hash_matches = true,
                .producer = .{ .path = released ++ "/producer.json", .sha256 = try e.digest(released ++ "/producer.json") },
                .top_report = .{ .path = released ++ "/top.json", .sha256 = try e.digest(released ++ "/top.json") },
                .backend_report = .{ .path = released ++ "/backend.json", .sha256 = try e.digest(released ++ "/backend.json") },
                .input = .{ .path = try e.absolute(released ++ "/input.ll"), .sha256 = try e.digest(released ++ "/input.ll") },
                .core_source = "local-state/validations/test/source/main.zig",
                .core_sha256 = try e.digest("local-state/validations/test/source/main.zig"),
                .driver_source = "local-state/validations/test/source/main.zig",
                .driver_sha256 = try e.digest("local-state/validations/test/source/main.zig"),
            });
            try rows.append(f.c.a, .{ .path = released ++ "/audit.json", .role = .audit, .sha256 = try e.digest(released ++ "/audit.json") });
        }
        try e.write(released ++ "/storage-release.json", p.Release{ .schema = "zllvm-storage-release-v1", .state = .superseded, .run_root = released, .reason = "Synthetic accepted successor", .producer = .{ .path = released ++ "/producer.json", .sha256 = try e.digest(released ++ "/producer.json") }, .successor = .{ .path = released ++ "/successor.json", .sha256 = try e.digest(released ++ "/successor.json") }, .retained = rows.items, .artifacts = &.{.{ .path = path, .sha256 = try e.digest(path), .kind = kind, .audit = if (kind == .raw_trace) released ++ "/audit.json" else null }} });
        try e.discover();
        for (e.actions.items, 0..) |a, index| if (std.mem.eql(u8, path, a.path)) return index;
        return error.MissingTestCandidate;
    }
};

test "storage cleanup: parsed control bytes cannot be rebound to changed or replaced files" {
    const f = try Fixture.init();
    defer f.deinit();
    for ([_]bool{ false, true }) |replace| {
        var e = f.engine();
        try f.write(report, "{\"status\":\"passed\"}");
        var parsed = try e.load(t.allocator, report);
        defer parsed.deinit();
        if (replace) {
            try f.write(run ++ "/replacement.json", "{\"status\":\"failed\"}");
            try f.tmp.dir.rename(report, f.tmp.dir, run ++ "/old.json", t.io);
            try f.tmp.dir.rename(run ++ "/replacement.json", f.tmp.dir, report, t.io);
        } else try f.write(report, "{\"status\":\"failed\"}");
        e.hash_cache.clearRetainingCapacity();
        try t.expectError(error.FileChanged, e.addControl(report));
        try t.expectError(error.FileChanged, e.load(t.allocator, report));
    }
}

test "storage cleanup: completed owned cache is deleted as a whole and all replay evidence survives" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try t.expectEqual(@as(usize, 1), e.actions.items.len);
    try e.qualify(0);
    const bytes = e.actions.items[0].allocated_bytes;
    try mutation.apply(&e, 0);
    try t.expectEqual(.removed, e.actions.items[0].status);
    try t.expectEqual(bytes, e.actions.items[0].reclaimed_file_bytes);
    try t.expectError(error.FileNotFound, e.metadata(cache));
    for (e.actions.items[0].retained) |row| try e.check(row);
    try t.expectError(error.FileNotFound, e.metadata(mutation.pending_path));
    var again = f.engine();
    try again.discover();
    try t.expectEqual(@as(usize, 0), again.actions.items.len);
}
test "storage cleanup: changed cache contents or retained source refuse deletion" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try e.qualify(0);
    try f.write(cache ++ "/o/object", "changed cache bytes");
    try t.expectError(error.SnapshotChanged, mutation.apply(&e, 0));
    _ = try e.metadata(cache);
    try t.expectError(error.FileNotFound, e.metadata(mutation.pending_path));
}
test "storage cleanup: source edit invalidates the build evidence before cache admission" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.write("local-state/validations/test/source/main.zig", "edited source");
    e.hash_cache.clearRetainingCapacity();
    try t.expectError(error.EvidenceHashMismatch, e.qualify(0));
    _ = try e.metadata(cache);
}
test "storage cleanup: cache with external hardlink is retained" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try f.tmp.dir.hardLink(cache ++ "/o/object", f.tmp.dir, "alias", t.io, .{});
    try e.discover();
    try t.expectError(error.AliasedCacheFile, e.qualify(0));
    try t.expectEqual(@as(u64, 2), (try e.metadata("alias")).links);
}
test "storage cleanup: cache with symlink is retained without following it" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try f.tmp.dir.symLink(t.io, "/tmp", cache ++ "/external", .{});
    try e.discover();
    try t.expectError(error.SpecialCacheEntry, e.qualify(0));
}
test "storage cleanup: minimum idle time protects fresh caches" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    e.config.minimum_idle_hours = 24;
    try e.discover();
    try t.expectError(error.TooRecent, e.qualify(0));
}
test "storage cleanup: new cache membership after preparation blocks removal" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try e.qualify(0);
    try f.write(cache ++ "/o/new-file", "new result");
    try t.expectError(error.SnapshotChanged, mutation.apply(&e, 0));
    _ = try e.metadata(cache ++ "/o/new-file");
}
test "storage cleanup: relative manifest pins resolve through ancestor working directories" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try e.pin("zig-local-cache/o/object", run ++ "/hashes.sha256");
    try t.expectEqual(.skipped, e.actions.items[0].status);
}
test "storage cleanup: hold on a parent run protects a completed cache" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try e.write(e.config.holds_file, p.Holds{ .paths = &.{run} });
    try e.loadHolds();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}
test "storage cleanup: new pins are rechecked before deletion" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try e.qualify(0);
    try f.write(run ++ "/new.sha256", try e.c.fmt("{s}  {s}\n", .{ try e.digest(cache ++ "/o/object"), cache ++ "/o/object" }));
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}
test "storage cleanup: quarantine collision preserves both names" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try e.qualify(0);
    const q = try e.c.fmt(run ++ "/.storage-cleanup-{d}-zig-local-cache", .{std.os.linux.getpid()});
    try f.write(q, "other evidence");
    try t.expectError(error.PathAlreadyExists, mutation.apply(&e, 0));
    _ = try e.metadata(cache);
    _ = try e.metadata(q);
    try t.expectError(error.FileNotFound, e.metadata(mutation.pending_path));
}
test "storage cleanup: real open descriptor blocks a candidate" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    const file = try f.tmp.dir.openFile(t.io, cache ++ "/o/object", .{});
    defer file.close(t.io);
    try e.consumers();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}
test "storage cleanup: failed producer does not qualify a cache from a successful child command" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    var v = try e.load(t.allocator, report);
    defer v.deinit();
    v.value.object.getPtr("status").?.* = .{ .string = "failed" };
    try e.write(report, v.value);
    e = f.engine();
    try e.discover();
    try t.expectError(error.ProducerNotSuccessful, e.qualify(0));
}
test "storage cleanup: metadata comparison detects changed bytes after a quarantine rename" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    var old = try core.fa.scan(t.allocator, t.io, try e.absolute(cache), .{ .hash_files = true });
    defer old.deinit();
    try f.write(cache ++ "/o/object", "replacement");
    var changed = try core.fa.scan(t.allocator, t.io, try e.absolute(cache), .{ .hash_files = true });
    defer changed.deinit();
    try t.expectError(error.QuarantineChanged, mutation.compareMoved(old.value, changed.value));
}
test "storage cleanup: explicit obsolete log release preserves replay material" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    const index = try f.release(&e, .log, true, true, false);
    try e.qualify(index);
    try mutation.apply(&e, index);
    try t.expectError(error.FileNotFound, e.metadata(released ++ "/old.log"));
    for (e.actions.items[index].retained) |row| try e.check(row);
}
test "storage cleanup: release requires an accepted successor" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    const index = try f.release(&e, .log, true, false, false);
    try t.expectError(error.NoAcceptedSuccessor, e.qualify(index));
}
test "storage cleanup: failed producer requires retained diagnostics" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    const index = try f.release(&e, .log, true, true, true);
    try t.expectError(error.MissingFailureEvidence, e.qualify(index));
}
test "storage cleanup: incomplete trace audit never releases its payload" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    const index = try f.release(&e, .raw_trace, false, true, false);
    try t.expectError(error.IncompleteTraceAudit, e.qualify(index));
}
test "storage cleanup: bound full trace audit permits retirement and restores readonly parent" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    const index = try f.release(&e, .raw_trace, true, true, false);
    try e.qualify(index);
    var parent = try f.tmp.dir.openDir(t.io, released, .{ .iterate = true });
    defer parent.close(t.io);
    try parent.setPermissions(t.io, .fromMode(0o555));
    defer parent.setPermissions(t.io, .fromMode(0o755)) catch {};
    try mutation.apply(&e, index);
    try t.expectEqual(@as(u32, 0o555), (try parent.stat(t.io)).permissions.toMode() & 0o7777);
    try t.expectError(error.FileNotFound, e.metadata(released ++ "/profile.events.jsonl"));
}
test "storage cleanup: released ELF object preserves the compiler" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    const index = try f.release(&e, .build_output, true, true, false);
    try e.qualify(index);
    try t.expectEqual(.ready, e.actions.items[index].status);
    try mutation.apply(&e, index);
    _ = try e.metadata(run ++ "/z_llvm");
}
test "storage cleanup: non-object bytes fail the compiled-output check" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    const index = try f.release(&e, .build_output, false, true, false);
    try t.expectError(error.NotCompiledOutput, e.qualify(index));
}
test "storage cleanup: completed snapshot compaction is lossless and idempotent" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try e.qualify(0);
    const original = e.actions.items[0].snapshot.?;
    try mutation.apply(&e, 0);
    try e.compactSnapshots();
    try t.expectEqualStrings(original.sha256, e.actions.items[0].snapshot_uncompressed_sha256.?);
    try t.expectError(error.FileNotFound, e.metadata(original.path));
    const archived = e.actions.items[0].snapshot.?;
    try e.check(archived);
    var record = try e.load(t.allocator, output ++ "/record-0.json");
    defer record.deinit();
    const recorded_snapshot = try core.get(try core.get(record.value, "action"), "snapshot");
    try t.expectEqualStrings(archived.path, try core.str(recorded_snapshot, "path"));
    try t.expectEqualStrings(archived.sha256, try core.str(recorded_snapshot, "sha256"));
    try e.compactSnapshots();
    try t.expectEqualStrings(archived.path, e.actions.items[0].snapshot.?.path);
}
test "storage cleanup: recorded source commits get durable retention refs" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try f.c.env.put("GIT_DIR", try e.absolute(".git"));
    try f.c.env.put("GIT_WORK_TREE", f.c.root);
    _ = try f.c.capture(&.{ "git", "-c", "core.hooksPath=/dev/null", "init", "--quiet" });
    _ = try f.c.capture(&.{ "git", "add", "--", "local-state/validations/test/source/main.zig" });
    _ = try f.c.capture(&.{ "git", "-c", "core.hooksPath=/dev/null", "-c", "commit.gpgsign=false", "-c", "user.name=Storage cleanup test", "-c", "user.email=test@example.invalid", "commit", "--quiet", "-m", "Storage cleanup test fixture" });
    const revision = u.trim(try f.c.capture(&.{ "git", "rev-parse", "HEAD" }));
    var v = try e.load(t.allocator, report);
    defer v.deinit();
    try v.value.object.put(v.arena.allocator(), "source_head", .{ .string = revision });
    try e.write(report, v.value);
    e = f.engine();
    try e.discover();
    try e.qualify(0);
    try t.expectEqual(@as(usize, 1), e.revisions.items.len);
    try e.pinRevisions();
    try mutation.apply(&e, 0);
    try e.verifyRevisions();
    try t.expectEqualStrings(revision, e.revisions.items[0].commit);
}
test "storage cleanup: symlink aliases in retention manifests protect their target" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.tmp.dir.symLink(t.io, cache ++ "/o/object", "pinned-alias", .{});
    try e.pin("pinned-alias", "docs/manifest.sha256");
    try t.expectEqual(.skipped, e.actions.items[0].status);
}
test "storage cleanup: uppercase and BSD checksums remain retention pins" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    const sha = try e.digest(cache ++ "/o/object");
    var upper: [64]u8 = undefined;
    for (sha, 0..) |ch, i| upper[i] = std.ascii.toUpper(ch);
    try f.write(run ++ "/uppercase.sha256", try e.c.fmt("{s}  {s}\n", .{ upper, cache ++ "/o/object" }));
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
    try f.tmp.dir.deleteFile(t.io, run ++ "/uppercase.sha256");
    e = f.engine();
    try e.discover();
    try f.write(run ++ "/bsd.sha256", try e.c.fmt("SHA256 ({s}) = {s}\n", .{ cache ++ "/o/object", sha }));
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}
test "storage cleanup: unrecognized checksum formats fail closed" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.write(run ++ "/unknown.sha256", "unrecognized checksum format\n");
    try t.expectError(error.ValidationFailed, e.pins());
    _ = try e.metadata(cache);
}
test "storage cleanup: a retired manifest exemption is bound to exact bytes" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.write(run ++ "/old.sha256", try e.c.fmt("{s}  {s}\n", .{ try e.digest(cache ++ "/o/object"), cache ++ "/o/object" }));
    e.config.retired_manifests = &.{.{ .path = run ++ "/old.sha256", .sha256 = try e.digest(run ++ "/old.sha256") }};
    try e.pins();
    try t.expectEqual(.discovered, e.actions.items[0].status);
    try f.write(run ++ "/old.sha256", "changed\n");
    e.hash_cache.clearRetainingCapacity();
    try t.expectError(error.EvidenceHashMismatch, e.pins());
}
test "storage cleanup: multiple commands may share one completed private cache" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    var v = try e.load(t.allocator, report);
    defer v.deinit();
    const commands = v.value.object.getPtr("commands").?;
    try commands.array.append(commands.array.items[0]);
    try e.write(report, v.value);
    e = f.engine();
    try e.discover();
    try t.expectEqual(@as(usize, 1), e.actions.items.len);
    try e.qualify(0);
    try t.expectEqual(.ready, e.actions.items[0].status);
}

test "storage cleanup: previous numbered retirement records pin retained evidence" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.tmp.dir.createDirPath(t.io, "local-state/retirements/previous");
    try e.write("local-state/retirements/previous/record-7.json", .{ .status = "complete", .retained = .{.{ .path = cache ++ "/o/object", .sha256 = try e.digest(cache ++ "/o/object") }} });
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

test "storage cleanup: unnamed hash fingerprints hold their entire containing run" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.write(run ++ "/fingerprint.sha256", try e.digest(cache ++ "/o/object"));
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

test "storage cleanup: a mounted root is rejected independently of device comparison" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    var proc = try core.fa.metadata.openRoot(t.io, "/proc");
    defer proc.close(t.io);
    const entries = [_]core.fa.Entry{.{ .path = ".", .metadata = try core.fa.metadata.descriptor(proc.handle), .sha256 = null }};
    try t.expectError(error.MountedCache, e.checkMounts(.{ .root = "/proc", .entries = &entries, .options = .{}, .totals = .{} }));
}

test "storage cleanup: stale inode cache entries do not override a new file identity" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.write(report, "{\"status\":\"passed\"}");
    const actual = try e.metadata(report);
    var stale = actual;
    stale.ctime_ns -= 1;
    const stale_hash = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    try e.hash_cache.put(core.fa.metadata.identity(actual), .{ .metadata = stale, .sha256 = stale_hash });
    try t.expect(!std.mem.eql(u8, stale_hash, try e.digest(report)));
    try e.hash_cache.put(core.fa.metadata.identity(actual), .{ .metadata = stale, .sha256 = stale_hash });
    var parsed = try e.load(t.allocator, report);
    defer parsed.deinit();
    try t.expect(core.eq(parsed.value, "status", "passed"));
}

test "storage cleanup: a fresh pin pass observes changed symlink targets" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.write("unrelated", "keep");
    try f.tmp.dir.symLink(t.io, "unrelated", "pin-alias", .{});
    try f.write(run ++ "/pins.sha256", try e.c.fmt("{s}  {s}\n", .{ try e.digest("unrelated"), try e.absolute("pin-alias") }));
    try e.pins();
    try t.expectEqual(.discovered, e.actions.items[0].status);
    try f.tmp.dir.deleteFile(t.io, "pin-alias");
    try f.tmp.dir.symLink(t.io, cache ++ "/o/object", "pin-alias", .{});
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}
