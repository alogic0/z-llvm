const std = @import("std");
const t = std.testing;
const u = @import("../validation/common.zig");
const core = @import("engine.zig");
const mutation = @import("mutation.zig");
const releases = @import("release.zig");
const batches = @import("batch.zig");
const private_cache = @import("private_cache.zig");
const retired_compiler = @import("retired_compiler.zig");
const generated = @import("generated.zig");
const p = core.p;
const run = "local-state/validations/test/batch/build";
const cache = run ++ "/zig-local-cache";
const report = run ++ "/report.json";
const output = "local-state/retirements/test-cleanup";
const released = "local-state/validations/test/batch/released";
const assembly_owner = run ++ "/execution-breadth-controls";
const assembly_dir = assembly_owner ++ "/ReleaseFast/example";
const assembly_path = assembly_dir ++ "/linked-harness.s";
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
        try f.write(run ++ "/z_llvm", "\x7fELFsynthetic compiler");
        try f.write(run ++ "/build.stdout", "successful build output");
        try f.write(run ++ "/build.stderr", "");
        try f.write("local-state/validations/test/source/main.zig", "pub fn main() void {}");
        try f.write("toolchain/zig", "compiler toolchain");
        const source = try e.absolute("local-state/validations/test/source");
        const compiler = try e.absolute(run ++ "/z_llvm");
        try e.write(report, .{ .status = "passed", .source_root = source, .compiler = compiler, .compiler_sha256 = try e.digest(compiler), .source_sha256 = .{ .@"main.zig" = try e.digest("local-state/validations/test/source/main.zig") }, .zig = try e.absolute("toolchain/zig"), .zig_sha256 = try e.digest("toolchain/zig"), .commands = .{.{ .actual_returncode = 0, .outcome = "completed", .argv = [_][]const u8{ "zig", "build-exe", "--cache-dir", try e.absolute(cache), try e.c.fmt("-Mroot={s}/main.zig", .{source}), try e.c.fmt("-femit-bin={s}", .{compiler}) }, .stdout = try e.absolute(run ++ "/build.stdout"), .stderr = try e.absolute(run ++ "/build.stderr") }} });
    }
    fn canonical(f: *Fixture, e: *core.Engine) !void {
        try f.build(e);
        try f.tmp.dir.createDirPath(t.io, run ++ "/bin");
        try f.tmp.dir.createDirPath(t.io, "toolchain/lib");
        try f.write(run ++ "/bin/z_llvm", "\x7fELFsynthetic-compiler");
        try f.write("toolchain/lib/std.zig", "pub const example = 1;");
        _ = try f.c.capture(&.{ "git", "init", "-q" });
        _ = try f.c.capture(&.{ "git", "add", "--", "local-state/validations/test/source/main.zig" });
        _ = try f.c.capture(&.{ "git", "-c", "user.name=Storage Test", "-c", "user.email=storage@example.invalid", "-c", "commit.gpgsign=false", "commit", "-qm", "source fixture" });
        const argv = [_][]const u8{ try e.absolute("toolchain/zig"), "build", "--prefix", try e.absolute(run) };
        const command = .{ .argv = argv, .actual_returncode = 0, .outcome = "completed", .stdout = try e.absolute(run ++ "/build.stdout"), .stderr = try e.absolute(run ++ "/build.stderr") };
        try e.write(report, .{
            .schema = "zllvm-compiler-build-v1",
            .compiler = try e.absolute(run ++ "/bin/z_llvm"),
            .compiler_sha256 = try e.digest(run ++ "/bin/z_llvm"),
            .source_head = u.trim(try f.c.capture(&.{ "git", "rev-parse", "HEAD" })),
            .source_sha256 = .{ .@"local-state/validations/test/source/main.zig" = try e.digest("local-state/validations/test/source/main.zig") },
            .argv = argv,
            .command = command,
            .zig = .{ .path = argv[0], .sha256 = try e.digest("toolchain/zig"), .library = try @import("../validation/toolchain.zig").libraryIdentity(&f.c, try e.absolute("toolchain/lib")) },
        });
    }
    fn privateCache(f: *Fixture, e: *core.Engine, legacy: bool, code: i64, env_args: bool) !p.Release {
        try f.tmp.dir.createDirPath(t.io, run ++ "/evidence/zig-local-Debug-v1/o");
        try f.tmp.dir.createDirPath(t.io, run ++ "/src");
        try f.write(run ++ "/.zigversion", "0.17.0\n");
        try f.write(run ++ "/src/main.zig", "unique original source remains");
        try f.write(run ++ "/evidence/zig-local-Debug-v1/o/test", "temporary test binary");
        try f.write(run ++ "/evidence/unit.log", "complete diagnostics remain");
        const args: []const []const u8 = if (env_args) &.{ "env", "ZIG_LOCAL_CACHE_DIR=evidence/zig-local-Debug-v1", "zig", "build", "test" } else &.{ "zig", "test", "--cache-dir", "evidence/zig-local-Debug-v1", "src/tests.zig" };
        try e.write(run ++ "/evidence/unit.json", .{ .argv = args, .cwd = if (legacy) null else try e.absolute(run), .status = "finished", .outcome = if (code < 0) "canceled" else "completed", .actual_returncode = code, .started_ns = 1, .finished_ns = 2, .log = try e.absolute(run ++ "/evidence/unit.log") });
        return (try private_cache.request(e, .{ .producer = run ++ "/evidence/unit.json", .run_root = run, .working_directory = run, .legacy_working_directory_review = if (legacy) "Reviewed copied project markers, run log and matching private cache arguments" else null }, "Closed temporary native-test cache")).?;
    }
    fn retireCompiler(f: *Fixture, build_report: []const u8) !p.Evidence {
        const retirement_output = "local-state/retirements/automatic-storage-cleanup/fixture";
        try f.tmp.dir.createDirPath(t.io, retirement_output);
        var prepare = f.engine();
        const request = try releases.disposableBuild(&prepare, build_report, "Completed temporary compiler");
        const request_path = try f.c.fmt("{s}/request.json", .{retirement_output});
        try prepare.write(request_path, request);
        var deletion = f.engine();
        deletion.output = retirement_output;
        try deletion.discoverRelease(request_path, true);
        try deletion.qualify(0);
        try mutation.apply(&deletion, 0);
        const path = retirement_output ++ "/record-0.json";
        return .{ .path = path, .sha256 = try deletion.digest(path) };
    }
    fn retiredTrace(f: *Fixture) !p.Evidence {
        var initial = f.engine();
        _ = try f.release(&initial, .raw_trace, true, true, false);
        const receipt = try f.retireCompiler(report);
        var parsed = try initial.load(f.c.a, released ++ "/storage-release.json");
        const record = (try std.json.parseFromValue(p.Release, f.c.a, parsed.value, .{})).value;
        var replacement = record;
        replacement.state = .audited;
        replacement.successor = null;
        replacement.compiler_retirement = receipt;
        var rows: std.ArrayList(p.Retained) = .empty;
        for (record.retained) |row| if (row.role != .compiler) try rows.append(f.c.a, row);
        replacement.retained = rows.items;
        try initial.write(released ++ "/storage-release.json", replacement);
        parsed.deinit();
        return receipt;
    }
    fn release(f: *Fixture, e: *core.Engine, kind: @FieldType(p.Artifact, "kind"), complete: bool, successor_passed: bool, failed_without_diagnostic: bool) !usize {
        try f.build(e);
        try f.tmp.dir.createDirPath(t.io, released);
        const path = try e.c.fmt("{s}/{s}", .{ released, switch (kind) {
            .log => "old.log",
            .raw_trace => "profile.events.jsonl",
            .build_output => "result.o",
            .generated_assembly => "linked-harness.s",
            .private_cache => unreachable,
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

test "storage cleanup: audited trace accepts exact guarded compiler retirement and preserves replay evidence" {
    const f = try Fixture.init();
    defer f.deinit();
    const receipt = try f.retiredTrace();
    var e = f.engine();
    try e.discoverRelease(released ++ "/storage-release.json", true);
    try e.qualify(0);
    try t.expect(e.actions.items[0].retired_compiler != null);
    try t.expect(e.actions.items[0].replay_required);
    try mutation.apply(&e, 0);
    try t.expectError(error.FileNotFound, e.metadata(released ++ "/profile.events.jsonl"));
    try t.expectError(error.FileNotFound, e.metadata(run ++ "/z_llvm"));
    _ = try e.metadata("local-state/validations/test/source/main.zig");
    _ = try e.metadata(released ++ "/input.ll");
    _ = try e.metadata(released ++ "/audit.json");
    _ = try e.metadata(receipt.path);
    var retained: std.ArrayList(core.Evidence) = .empty;
    // A proof is local to its audited release, never a global missing-file waiver.
    try t.expectError(error.FileNotFound, e.buildEvidence(report, &retained, null, &.{}));
}

test "storage cleanup: incomplete or unrelated compiler retirement cannot replace original bytes" {
    for (0..5) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        const original = try f.retiredTrace();
        var edit = f.engine();
        var parsed = try edit.load(f.c.a, original.path);
        switch (case) {
            0 => try u.put(f.c.a, &parsed.value, "status", u.s("pending")),
            1 => try u.put(f.c.a, parsed.value.object.getPtr("action").?, "status", u.s("ready")),
            2 => try u.put(f.c.a, parsed.value.object.getPtr("action").?, "sha256", u.s("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")),
            3 => try u.put(f.c.a, parsed.value.object.getPtr("action").?, "reclaimed_file_bytes", u.n(0)),
            4 => try u.put(f.c.a, &parsed.value, "retained", u.array(f.c.a)),
            else => unreachable,
        }
        try edit.write(original.path, parsed.value);
        var e = f.engine();
        var retained: std.ArrayList(core.Evidence) = .empty;
        const receipt: p.Evidence = .{ .path = original.path, .sha256 = try e.digest(original.path) };
        const result = retired_compiler.verify(&e, receipt, &retained);
        if (result) |_| return error.InvalidRetirementWasAccepted else |_| {}
        _ = try e.metadata(released ++ "/profile.events.jsonl");
    }
}

test "storage cleanup: retired compiler proof requires unchanged owner request and build receipt" {
    for ([_][]const u8{ report, "local-state/retirements/automatic-storage-cleanup/fixture/request.json" }) |path| {
        const f = try Fixture.init();
        defer f.deinit();
        const receipt = try f.retiredTrace();
        try f.write(path, "{\"status\":\"passed\"}\n");
        var e = f.engine();
        var retained: std.ArrayList(core.Evidence) = .empty;
        try t.expectError(error.EvidenceHashMismatch, retired_compiler.verify(&e, receipt, &retained));
    }
}

test "storage cleanup: retired compiler proof is bound to one build and only audited trace releases" {
    const f = try Fixture.init();
    defer f.deinit();
    const receipt = try f.retiredTrace();
    var initial = f.engine();
    var retained: std.ArrayList(core.Evidence) = .empty;
    const proof = try retired_compiler.verify(&initial, receipt, &retained);
    try t.expectError(error.RetiredCompilerBuildMismatch, retired_compiler.bind(&initial, proof, "different-build.json", proof.compiler.path, proof.compiler.sha256));
    var parsed = try initial.load(f.c.a, released ++ "/storage-release.json");
    try u.put(f.c.a, &parsed.value, "state", u.s("superseded"));
    try initial.write(released ++ "/storage-release.json", parsed.value);
    var e = f.engine();
    try e.discoverRelease(released ++ "/storage-release.json", true);
    try t.expectError(error.RetiredCompilerOnlyAuditedTrace, e.qualify(0));
    parsed.deinit();
}

test "storage cleanup: retired compiler and proof records are rechecked before trace mutation" {
    for ([_]bool{ false, true }) |compiler_reappears| {
        const f = try Fixture.init();
        defer f.deinit();
        const receipt = try f.retiredTrace();
        var e = f.engine();
        try e.discoverRelease(released ++ "/storage-release.json", true);
        try e.qualify(0);
        if (compiler_reappears) try f.write(run ++ "/z_llvm", "replacement executable") else try f.write(receipt.path, "{\"status\":\"complete\"}");
        const result = mutation.apply(&e, 0);
        if (result) |_| return error.ChangedRetirementWasAccepted else |_| {}
        _ = try e.metadata(released ++ "/profile.events.jsonl");
        try t.expectError(error.FileNotFound, e.metadata(mutation.pending_path));
    }
}

test "storage cleanup: retired compiler identity does not excuse changed source or incomplete audit" {
    for ([_]bool{ false, true }) |source_changed| {
        const f = try Fixture.init();
        defer f.deinit();
        _ = try f.retiredTrace();
        if (source_changed) try f.write("local-state/validations/test/source/main.zig", "changed source") else try f.write(released ++ "/audit.json", "{\"status\":\"verified\",\"complete\":false}");
        var e = f.engine();
        try e.discoverRelease(released ++ "/storage-release.json", true);
        const result = e.qualify(0);
        if (result) |_| return error.InvalidReplayWasAccepted else |_| {}
    }
}

test "storage cleanup: canonical build sources still qualify after verified compiler retirement" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    try f.canonical(&initial);
    const receipt = try f.retireCompiler(report);
    var e = f.engine();
    var retained: std.ArrayList(core.Evidence) = .empty;
    const proof = try retired_compiler.verify(&e, receipt, &retained);
    var parsed = try e.load(f.c.a, report);
    try @import("historical.zig").canonicalWithRetirement(&e, report, parsed.value, &retained, null, &.{}, proof);
    try t.expectEqual(@as(usize, 1), e.revisions.items.len);
    try f.write("toolchain/lib/std.zig", "changed toolchain");
    try t.expectError(error.ToolchainLibraryChanged, @import("historical.zig").verifyLibraries(&e));
    parsed.deinit();
}

test "storage cleanup: trace preparation owns its audit data and binds retirement proof" {
    const f = try Fixture.init();
    defer f.deinit();
    const receipt = try f.retiredTrace();
    var e = f.engine();
    try e.write("trace-plan.json", .{ .schema = "zllvm-trace-retirement-plan-v1", .traces = [_]batches.TraceEntry{.{ .audit = released ++ "/audit.json", .build = report, .compiler_retirement = receipt.path }} });
    try batches.traces(&e, "trace-plan.json", "Complete audit and retired original identity");
    var fresh = f.engine();
    try batches.discover(&fresh, output ++ "/requests.json");
    try fresh.qualify(0);
    try t.expect(fresh.actions.items[0].retired_compiler != null);
    _ = try fresh.metadata(released ++ "/profile.events.jsonl");
}

test "storage cleanup: canonical receipt reconstructs sources from Git after checkout changes" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.canonical(&e);
    try f.write("local-state/validations/test/source/main.zig", "different current checkout");
    var retained: std.ArrayList(core.Evidence) = .empty;
    try e.buildEvidence(report, &retained, run ++ "/bin/z_llvm", &.{});
    try t.expectEqual(@as(usize, 1), e.revisions.items.len);
    try e.pinRevisions();
    try e.verifyRevisions();
    for (retained.items) |ev| {
        try t.expect(!std.mem.eql(u8, ev.path, run ++ "/bin/z_llvm"));
        try e.check(ev);
    }
    try f.write("toolchain/lib/std.zig", "changed toolchain");
    try t.expectError(error.ToolchainLibraryChanged, @import("historical.zig").verifyLibraries(&e));
}

test "storage cleanup: historical reconstruction checks saved overrides instead of trusting verified flags" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.canonical(&e);
    const original = try f.c.load(try e.absolute(report));
    var modified = original;
    try f.write(output ++ "/override.zig", "historical uncommitted source");
    const sha = try e.digest(output ++ "/override.zig");
    var hashes = try core.get(modified, "source_sha256");
    try hashes.object.put(f.c.a, "local-state/validations/test/source/main.zig", u.s(sha));
    try modified.object.put(f.c.a, "source_sha256", hashes);
    try e.write(report, modified);
    try e.write(output ++ "/reconstruction.json", .{ .sources = .{.{ .sha256 = sha, .saved = output ++ "/override.zig", .verified = true }} });
    var fresh = f.engine();
    var retained: std.ArrayList(core.Evidence) = .empty;
    try t.expectError(error.SourceReconstructionMissing, fresh.buildEvidence(report, &retained, null, &.{}));
    const ledger = core.Evidence{ .path = output ++ "/reconstruction.json", .sha256 = try fresh.digest(output ++ "/reconstruction.json") };
    try fresh.buildEvidence(report, &retained, null, &.{ledger});
    try f.write(output ++ "/override.zig", "wrong bytes");
    var changed = f.engine();
    try t.expectError(error.EvidenceHashMismatch, changed.buildEvidence(report, &retained, null, &.{ledger}));
}

test "storage cleanup: canonical receipts reject failed or redirected commands" {
    for ([_]bool{ false, true }) |failed| {
        const f = try Fixture.init();
        defer f.deinit();
        var e = f.engine();
        try f.canonical(&e);
        var value = try f.c.load(try e.absolute(report));
        var command = try core.get(value, "command");
        if (failed) {
            try command.object.put(f.c.a, "actual_returncode", .{ .integer = 1 });
        } else {
            var argv = try core.get(command, "argv");
            argv.array.items[3] = u.s("local-state/validations/test/wrong");
            try value.object.put(f.c.a, "argv", argv);
            try command.object.put(f.c.a, "argv", argv);
        }
        try value.object.put(f.c.a, "command", command);
        try e.write(report, value);
        var fresh = f.engine();
        var retained: std.ArrayList(core.Evidence) = .empty;
        try t.expectError(if (failed) error.IncompleteBuildCommand else error.SourceCompilerCommandNotBound, fresh.buildEvidence(report, &retained, null, &.{}));
    }
}

fn transitionFixture(f: *Fixture, e: *core.Engine, extra_manifest: bool, current: bool, wrong_hash: bool) !core.Engine {
    const index = try f.release(e, .build_output, true, true, false);
    const artifact = e.actions.items[index];
    const manifest = "local-state/retirements/historical.sha256";
    try f.write(manifest, try e.c.fmt("{s}  {s}\n{s}  {s}/o/object\n", .{ artifact.sha256.?, artifact.path, try e.digest(cache ++ "/o/object"), cache }));
    const value = try f.c.load(try e.absolute(released ++ "/storage-release.json"));
    var parsed = try std.json.parseFromValue(p.Release, f.c.a, value, .{});
    parsed.value.retired_pins = &.{.{ .manifest = .{ .path = manifest, .sha256 = try e.digest(manifest) }, .reference = artifact.path, .target = .{ .path = artifact.path, .sha256 = if (wrong_hash) "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" else artifact.sha256.? }, .reason = "Verified accepted successor replaces this output" }};
    try e.write(released ++ "/storage-release.json", parsed.value);
    if (extra_manifest) try f.write("local-state/retirements/new-pin.sha256", try e.c.fmt("{s}  {s}\n", .{ artifact.sha256.?, artifact.path }));
    var fresh = f.engine();
    if (current) fresh.config.current_manifests = &.{manifest};
    try fresh.discover();
    return fresh;
}

test "storage cleanup: pin transition exempts only its exact file and manifest" {
    for ([_]bool{ false, true }) |extra| {
        const f = try Fixture.init();
        defer f.deinit();
        var original = f.engine();
        var e = try transitionFixture(f, &original, extra, false, false);
        for (e.actions.items, 0..) |_, i| try e.qualify(i);
        try e.pins();
        for (e.actions.items) |action| {
            if (action.kind == .cache) try t.expectEqual(.skipped, action.status) else try t.expectEqual(@as(@FieldType(core.Action, "status"), if (extra) .skipped else .ready), action.status);
        }
        // Reusing parsed manifests must make the identical decision.
        try e.pins();
    }
}

test "storage cleanup: current manifests outside discovery globs still pin retired historical targets" {
    const f = try Fixture.init();
    defer f.deinit();
    var original = f.engine();
    var e = try transitionFixture(f, &original, false, false, false);
    for (e.actions.items, 0..) |action, i| {
        try e.qualify(i);
        if (action.kind == .build_output) try f.write("current-inputs", try e.c.fmt("{s}  {s}\n", .{ action.sha256.?, action.path }));
    }
    e.config.current_manifests = &.{"current-inputs"};
    try e.pins();
    for (e.actions.items) |action| if (action.kind == .build_output) try t.expectEqual(.skipped, action.status);
}

test "storage cleanup: pin transitions reject current manifests, wrong hashes and changed seals" {
    for (0..3) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        var original = f.engine();
        var e = try transitionFixture(f, &original, false, case == 0, case == 1);
        if (case == 2) try f.write("local-state/retirements/historical.sha256", "changed manifest\n");
        for (e.actions.items, 0..) |action, i| if (action.kind == .build_output) {
            try t.expectError(switch (case) {
                0 => error.CurrentManifestCannotBeRetired,
                1 => error.PinTransitionNotAnArtifact,
                else => error.EvidenceHashMismatch,
            }, e.qualify(i));
        };
    }
}

test "storage cleanup: staged historical requests verify hashes and retire only reviewed completed-record pins" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    const index = try f.release(&initial, .build_output, true, true, false);
    const artifact = initial.actions.items[index];
    const request_path = output ++ "/original-request.json";
    const original_release = try f.c.load(try initial.absolute(released ++ "/storage-release.json"));
    try initial.write(request_path, original_release);
    try f.tmp.dir.deleteFile(t.io, released ++ "/storage-release.json");
    try initial.write(output ++ "/requests.json", .{ .schema = "zllvm-storage-requests-v1", .requests = .{.{ .path = request_path, .sha256 = try initial.digest(request_path) }} });
    try initial.write("local-state/retirements/record-old.json", .{ .status = "complete", .retained = .{.{ .path = artifact.path, .sha256 = artifact.sha256.? }} });
    try f.write(run ++ "/milestone.sha256", try f.c.fmt("{s}  {s}\n", .{ artifact.sha256.?, artifact.path }));
    try initial.write(output ++ "/manifest-review.json", .{ .schema = "zllvm-reviewed-pin-manifests-v1", .reason = "Reviewed completed milestone's temporary output", .manifests = .{.{ .path = run ++ "/milestone.sha256", .sha256 = try initial.digest(run ++ "/milestone.sha256") }} });
    var review = f.engine();
    try review.discover();
    try batches.discover(&review, output ++ "/requests.json");
    for (review.actions.items, 0..) |_, i| try review.qualify(i);
    try review.pins();
    try review.write(output ++ "/review.json", .{ .status = "complete", .mode = "review", .controls = review.controls.items, .actions = review.actions.items });
    try review.write(output ++ "/pin-references.json", review.pin_references.items);
    try f.tmp.dir.createDirPath(t.io, output ++ "/prepared");
    var prepare = f.engine();
    prepare.output = output ++ "/prepared";
    try batches.reviewedPins(&prepare, output ++ "/requests.json", output ++ "/review.json", output ++ "/manifest-review.json");
    try f.tmp.dir.createDirPath(t.io, output ++ "/apply");
    var apply = f.engine();
    apply.output = output ++ "/apply";
    try batches.discover(&apply, output ++ "/prepared/requests.json");
    try t.expectEqual(@as(usize, 1), apply.actions.items.len);
    try apply.qualify(0);
    try apply.pins();
    try t.expectEqual(.ready, apply.actions.items[0].status);
    try mutation.apply(&apply, 0);
    try t.expectError(error.FileNotFound, apply.metadata(artifact.path));
    _ = try apply.metadata("local-state/retirements/record-old.json");
    _ = try apply.metadata(cache ++ "/o/object");
    try f.write(request_path, "changed request");
    var changed = f.engine();
    try t.expectError(error.EvidenceHashMismatch, batches.discover(&changed, output ++ "/requests.json"));
}

test "storage cleanup: reviewed milestone adapter cannot exempt a current manifest" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.write(run ++ "/current.sha256", "current contract\n");
    e.config.current_manifests = &.{run ++ "/current.sha256"};
    try e.write(output ++ "/manifest-review.json", .{ .schema = "zllvm-reviewed-pin-manifests-v1", .reason = "Rejected current exemption", .manifests = .{.{ .path = run ++ "/current.sha256", .sha256 = try e.digest(run ++ "/current.sha256") }} });
    try t.expectError(error.CurrentManifestCannotBeRetired, batches.reviewedPins(&e, "unused-requests.json", "unused-review.json", output ++ "/manifest-review.json"));
}

test "storage cleanup: failed release qualification still protects its declared dependencies" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    _ = try f.release(&initial, .build_output, true, false, false);
    var value = try f.c.load(try initial.absolute(released ++ "/storage-release.json"));
    var retained = try core.get(value, "retained");
    try retained.array.append(try u.toValue(f.c.a, p.Retained{ .path = cache ++ "/o/object", .sha256 = try initial.digest(cache ++ "/o/object"), .role = .other }));
    try value.object.put(f.c.a, "retained", retained);
    try initial.write(released ++ "/storage-release.json", value);
    var e = f.engine();
    try e.discover();
    for (e.actions.items, 0..) |action, i| {
        if (action.kind == .cache) try e.qualify(i) else try t.expectError(error.NoAcceptedSuccessor, e.qualify(i));
    }
    try e.protectRetained();
    for (e.actions.items) |action| if (action.kind == .cache) try t.expectEqual(.skipped, action.status);
}

test "storage cleanup: producer compiler release preserves canonical rebuild evidence and accepted successor" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.canonical(&e);
    try e.write(output ++ "/successor.json", .{ .status = "passed" });
    const destination = try releases.compilerBuild(&e, report, output ++ "/successor.json", "New accepted compiler", &.{});
    try t.expectEqualStrings(run ++ "/storage-release.json", destination);
    var apply = f.engine();
    try apply.discover();
    try t.expectEqual(@as(usize, 1), apply.actions.items.len);
    try apply.qualify(0);
    try apply.pinRevisions();
    try mutation.apply(&apply, 0);
    try t.expectError(error.FileNotFound, apply.metadata(run ++ "/bin/z_llvm"));
    _ = try apply.metadata(report);
    _ = try apply.metadata(output ++ "/successor.json");
    _ = try apply.metadata("toolchain/lib/std.zig");
}

test "storage cleanup: inventory counts hardlinks once and respects a required alias" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.write(run ++ "/required", "one allocation with two names");
    _ = try f.c.capture(&.{ "ln", try e.absolute(run ++ "/required"), try e.absolute(output ++ "/alias") });
    try e.held.append(f.c.a, run ++ "/required");
    try @import("inventory.zig").write(&e);
    const result = try f.c.load(try e.absolute(output ++ "/inventory.json"));
    try t.expectEqual((try e.metadata(run ++ "/required")).allocated_bytes, @as(u64, @intCast(try core.integer(result, "required_by_current_contract_bytes"))));
    try t.expectEqual(@as(i64, 0), try core.integer(result, "eligible_bytes"));
}

test "storage cleanup: own release command is not a consumer but other processes remain protected" {
    const own = "    PID COMMAND\n  123 clean-storage release-build --build " ++ report ++ "\n";
    try t.expect(!core.commandUsesRun(own, run, 123));
    try t.expect(core.commandUsesRun(own ++ "  124 reader " ++ run ++ "/z_llvm\n", run, 123));
    try t.expect(core.commandUsesRun(own ++ "  122 parent-job " ++ report ++ "\n", run, 123));
}

test "storage cleanup: disposable compiler needs no source, toolchain or successor reconstruction" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    try f.canonical(&initial);
    try f.tmp.dir.deleteFile(t.io, "local-state/validations/test/source/main.zig");
    try f.tmp.dir.deleteFile(t.io, "toolchain/zig");
    var e = f.engine();
    const request = try releases.disposableBuild(&e, report, "User classifies this closed compiler as temporary");
    _ = try releases.publish(&e, request);
    try t.expectEqual(@as(usize, 0), e.revisions.items.len);
    try t.expectEqual(@as(usize, 0), e.libraries.items.len);
    var apply = f.engine();
    try apply.discover();
    try apply.qualify(0);
    try mutation.apply(&apply, 0);
    try t.expectError(error.FileNotFound, apply.metadata(run ++ "/bin/z_llvm"));
    _ = try apply.metadata(report);
}

test "storage cleanup: disposable outputs require closed producer and never include raw traces or logs" {
    for (0..4) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        var initial = f.engine();
        const kind: @FieldType(p.Artifact, "kind") = if (case == 2) .raw_trace else if (case == 3) .log else .build_output;
        _ = try f.release(&initial, kind, true, false, true);
        if (case == 1) try initial.write(released ++ "/producer.json", .{ .status = "running" });
        var value = try f.c.load(try initial.absolute(released ++ "/storage-release.json"));
        var parsed = try std.json.parseFromValue(p.Release, f.c.a, value, .{});
        parsed.value.state = .disposable;
        parsed.value.retained = &.{};
        parsed.value.successor = null;
        var hash = f.engine();
        parsed.value.producer.sha256 = try hash.digest(released ++ "/producer.json");
        try initial.write(released ++ "/storage-release.json", parsed.value);
        var e = f.engine();
        try e.discover();
        for (e.actions.items, 0..) |action, index| if (action.kind != .cache) {
            if (case == 0) try e.qualify(index) else try t.expectError(if (case == 1) error.ProducerNotTerminal else error.DisposableOnlyBuildOutputs, e.qualify(index));
        };
        // Keep this parsed input live through publication above.
        _ = &value;
    }
}

test "storage cleanup: disposable compiler still obeys current pins" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    try f.canonical(&initial);
    const request = try releases.disposableBuild(&initial, report, "Temporary build");
    try initial.write(run ++ "/storage-release.json", request);
    try f.write("current-inputs", try initial.c.fmt("{s}  {s}\n", .{ request.artifacts[0].sha256, request.artifacts[0].path }));
    var e = f.engine();
    e.config.current_manifests = &.{"current-inputs"};
    try e.discover();
    try e.qualify(0);
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

test "storage cleanup: disposable output does not depend on another action's replay environment" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    try f.canonical(&initial);
    try initial.write(run ++ "/storage-release.json", try releases.disposableBuild(&initial, report, "Temporary build"));
    var e = f.engine();
    try e.discover();
    try e.qualify(0);
    try t.expect(!e.actions.items[0].replay_required);
    // Another, already completed trace action may have registered this replay
    // environment. It must not become a prerequisite for ordinary disposal.
    try e.libraries.append(f.c.a, .{ .path = "missing-other-toolchain", .sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", .files = 1 });
    try e.revisions.append(f.c.a, .{ .commit = "missing-other-commit", .tree = "missing-other-tree", .reference = "refs/retirements/missing-other" });
    try e.verifyEvidence(e.actions.items[0]);
    try mutation.apply(&e, 0);
    try t.expectError(error.FileNotFound, e.metadata(run ++ "/bin/z_llvm"));
}

test "storage cleanup: completed private caches may be disposable without old source or compiler" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    try f.build(&initial);
    try f.tmp.dir.deleteFile(t.io, "local-state/validations/test/source/main.zig");
    try f.tmp.dir.deleteFile(t.io, run ++ "/z_llvm");
    var e = f.engine();
    e.config.cache_evidence = .closed_producer;
    try e.discover();
    try e.qualify(0);
    try mutation.apply(&e, 0);
    try t.expectError(error.FileNotFound, e.metadata(cache));
    _ = try e.metadata(report);
}

test "storage cleanup: private test caches preserve diagnostics for passed failed and canceled commands" {
    for ([_]i64{ 0, 1, -15 }) |code| for ([_]bool{ false, true }) |legacy| {
        const f = try Fixture.init();
        defer f.deinit();
        var initial = f.engine();
        const record = try f.privateCache(&initial, legacy, code, legacy);
        try initial.write(run ++ "/storage-release.json", record);
        var e = f.engine();
        try e.discover();
        try t.expectEqual(@as(usize, 1), e.actions.items.len);
        try e.qualify(0);
        try t.expect(e.actions.items[0].released_cache);
        try t.expect(!e.actions.items[0].replay_required);
        try mutation.apply(&e, 0);
        try t.expectError(error.FileNotFound, e.metadata(run ++ "/evidence/zig-local-Debug-v1"));
        _ = try e.metadata(run ++ "/evidence/unit.log");
        _ = try e.metadata(run ++ "/evidence/unit.json");
        _ = try e.metadata(run ++ "/src/main.zig");
    };
}

test "storage cleanup: legacy cache cwd requires explicit review and modern cwd must match" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    _ = try f.privateCache(&initial, true, 1, false);
    var legacy = f.engine();
    try t.expectError(error.MissingCacheWorkingDirectory, private_cache.request(&legacy, .{ .producer = run ++ "/evidence/unit.json", .run_root = run, .working_directory = run }, "Temporary cache"));
    var modern_setup = f.engine();
    _ = try f.privateCache(&modern_setup, false, 0, false);
    var modern = f.engine();
    try t.expectError(error.CacheWorkingDirectoryMismatch, private_cache.request(&modern, .{ .producer = run ++ "/evidence/unit.json", .run_root = run, .working_directory = run ++ "/different", .legacy_working_directory_review = "Cannot override a recorded cwd" }, "Temporary cache"));
}

test "storage cleanup: copied test project may link source outside its private cache" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    const record = try f.privateCache(&initial, true, 1, false);
    try f.tmp.dir.rename(run ++ "/src", f.tmp.dir, run ++ "/original-source", t.io);
    try f.tmp.dir.symLink(t.io, "original-source", run ++ "/src", .{ .is_directory = true });
    try initial.write(run ++ "/storage-release.json", record);
    var e = f.engine();
    try e.discover();
    try e.qualify(0);
    try mutation.apply(&e, 0);
    try t.expectError(error.FileNotFound, e.metadata(run ++ "/evidence/zig-local-Debug-v1"));
    try t.expectEqual(.symlink, (try e.metadata(run ++ "/src")).kind);
    _ = try e.metadata(run ++ "/original-source/main.zig");
    _ = try e.metadata(run ++ "/evidence/unit.log");
}

test "storage cleanup: private caches reject nonterminal producers missing logs and other release states" {
    for (0..3) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        var initial = f.engine();
        var record = try f.privateCache(&initial, false, 1, false);
        if (case == 0) {
            var v = try initial.load(f.c.a, run ++ "/evidence/unit.json");
            try u.put(f.c.a, &v.value, "status", u.s("running"));
            try initial.write(run ++ "/evidence/unit.json", v.value);
            var fresh = f.engine();
            record.producer.sha256 = try fresh.digest(record.producer.path);
        } else if (case == 1) record.retained = &.{} else record.state = .superseded;
        try initial.write(run ++ "/storage-release.json", record);
        var e = f.engine();
        try e.discover();
        try t.expectError(switch (case) {
            0 => error.ProducerNotTerminal,
            1 => error.MissingCacheDiagnostics,
            else => error.PrivateCacheRequiresDisposable,
        }, e.qualify(0));
    }
}

test "storage cleanup: private cache release cannot claim shared source or arbitrary directories" {
    try t.expect(!p.privateCacheOwned(run, run, "local-state/caches/zig-local-cache"));
    try t.expect(!p.privateCacheOwned(run, run, run ++ "/src/zig-local-cache"));
    try t.expect(!p.privateCacheOwned(run, run, run ++ "/evidence/diagnostics"));
    try t.expect(p.privateCacheOwned(run, run, run ++ "/local-state/zig-global-Debug-v1"));
    try t.expect(!p.artifactName(.{ .path = run ++ "/src", .kind = .private_cache }));
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    const invalid = try u.toValue(f.c.a, .{ .argv = [_][]const u8{ "zig", "test", "--cache-dir", "../shared/zig-local-cache" } });
    try t.expectError(error.InvalidPrivateCacheArgument, private_cache.paths(&e, run, run, invalid));
}

test "storage cleanup: current manifest protects a member of a released private cache" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    const record = try f.privateCache(&initial, false, 0, false);
    try initial.write(run ++ "/storage-release.json", record);
    const member = run ++ "/evidence/zig-local-Debug-v1/o/test";
    try f.write("current-cache", try initial.c.fmt("{s}  {s}\n", .{ try initial.digest(member), member }));
    var e = f.engine();
    e.config.current_manifests = &.{"current-cache"};
    try e.discover();
    try e.qualify(0);
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

test "storage cleanup: cache preparation reports rejected ownership and binds requests" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    _ = try f.privateCache(&initial, false, 0, false);
    try initial.write("cache-plan.json", .{ .schema = "zllvm-private-cache-plan-v1", .runs = [_]private_cache.PlanEntry{
        .{ .producer = run ++ "/evidence/unit.json", .run_root = run, .working_directory = run },
        .{ .producer = run ++ "/evidence/unit.json", .run_root = run, .working_directory = run ++ "/wrong" },
    } });
    try batches.caches(&initial, "cache-plan.json", "Reviewed test cache");
    var e = f.engine();
    try batches.discover(&e, output ++ "/requests.json");
    try t.expectEqual(@as(usize, 1), e.actions.items.len);
    try e.qualify(0);
    _ = try e.metadata(run ++ "/evidence/zig-local-Debug-v1/o/test");
    var review = try e.load(f.c.a, output ++ "/cache-plan-review.json");
    try t.expectEqual(@as(i64, 1), try core.integer(review.value, "prepared"));
    try t.expectEqual(@as(usize, 1), (try core.get(review.value, "rejected")).array.items.len);
    review.deinit();
}

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

test "storage cleanup: minimal lifecycle admits completed fresh cache without waiving source checks" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    e.config.minimum_idle_hours = 24;
    try e.discover();
    try t.expectError(error.TooRecent, e.qualify(0));
    try e.measureHeld(0);
    try t.expect(e.actions.items[0].measured);
    try t.expect(e.actions.items[0].allocated_bytes > 0);
    e.config = p.minimal(e.config);
    // Fresh engine to avoid carrying the observational held byte measurement.
    var minimal = core.Engine.init(&f.c, e.config, output, e.zigrep);
    minimal.now_ns = e.now_ns;
    try minimal.discover();
    try minimal.qualify(0);
    try t.expectEqual(.ready, minimal.actions.items[0].status);
    try f.write("local-state/validations/test/source/main.zig", "changed source");
    var changed = f.engine();
    changed.config = p.minimal(changed.config);
    try changed.discover();
    try t.expectError(error.EvidenceHashMismatch, changed.qualify(0));
}

test "storage cleanup: missing pin parent is refreshed on every pass" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.write(run ++ "/pins.sha256", try e.c.fmt("{s}  future/pin-alias\n", .{try e.digest(cache ++ "/o/object")}));
    try e.pins();
    try t.expectEqual(.discovered, e.actions.items[0].status);
    try f.tmp.dir.createDir(t.io, "future", .default_dir);
    try f.tmp.dir.symLink(t.io, "../" ++ cache ++ "/o/object", "future/pin-alias", .{});
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

test "storage cleanup: repeated missing pin leaves in existing parents are refreshed" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.tmp.dir.createDir(t.io, "future", .default_dir);
    const line = try e.c.fmt("{s}  future/pin-alias\n", .{try e.digest(cache ++ "/o/object")});
    try f.write(run ++ "/pins.sha256", try e.c.fmt("{s}{s}{s}", .{ line, line, line }));
    try e.pins();
    try t.expectEqual(.discovered, e.actions.items[0].status);
    try f.tmp.dir.symLink(t.io, "../" ++ cache ++ "/o/object", "future/pin-alias", .{});
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

test "storage cleanup: changed cached pin manifest aborts refresh" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.write(run ++ "/pins.sha256", "# no pins yet\n");
    try e.pins();
    try f.write(run ++ "/pins.sha256", try e.c.fmt("{s}  {s}\n", .{ try e.digest(cache ++ "/o/object"), cache ++ "/o/object" }));
    try t.expectError(error.PinManifestChanged, e.pins());
}

test "storage cleanup: another candidate's retained evidence always wins" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try e.qualify(0);
    try e.actions.append(f.c.a, .{ .path = released ++ "/unrelated.log", .run_root = released, .producer = report, .kind = .log, .status = .skipped, .retained = &.{.{ .path = try e.absolute(cache ++ "/o/object"), .sha256 = try e.digest(cache ++ "/o/object") }} });
    try e.protectRetained();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

test "storage cleanup: owner can publish audited failed trace without a passed successor" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    _ = try f.release(&e, .raw_trace, true, false, true);
    try f.tmp.dir.deleteFile(t.io, released ++ "/storage-release.json");
    e = f.engine();
    e.now_ns = std.Io.Clock.real.now(t.io).nanoseconds - std.time.ns_per_s;
    const published = try releases.trace(&e, released ++ "/audit.json", report, "Raw detail is audited; preserve the failure and replay inputs");
    try t.expectEqualStrings(released ++ "/storage-release.json", published);
    // Publishing is an ownership transition only.
    _ = try e.metadata(released ++ "/profile.events.jsonl");
    var collector = f.engine();
    try collector.discover();
    for (collector.actions.items, 0..) |a, i| {
        if (a.kind != .raw_trace) continue;
        try collector.qualify(i);
        try mutation.apply(&collector, i);
    }
    try t.expectError(error.FileNotFound, collector.metadata(released ++ "/profile.events.jsonl"));
    var producer = try collector.load(t.allocator, released ++ "/producer.json");
    defer producer.deinit();
    try t.expectEqual(@as(i64, 1), try core.integer(producer.value, "actual_returncode"));
    try t.expect(core.eq(producer.value, "status", "finished"));
}

test "storage cleanup: incomplete audit cannot publish a release" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    _ = try f.release(&e, .raw_trace, false, false, true);
    try f.tmp.dir.deleteFile(t.io, released ++ "/storage-release.json");
    e = f.engine();
    try t.expectError(error.IncompleteTraceAudit, releases.trace(&e, released ++ "/audit.json", report, "Insufficient audit"));
    try t.expectError(error.FileNotFound, e.metadata(released ++ "/storage-release.json"));
    _ = try e.metadata(released ++ "/profile.events.jsonl");
}

test "storage cleanup: audited state cannot release binaries or logs" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    _ = try f.release(&e, .log, true, true, false);
    var v = try e.load(t.allocator, released ++ "/storage-release.json");
    defer v.deinit();
    v.value.object.getPtr("state").?.* = .{ .string = "audited" };
    try e.write(released ++ "/storage-release.json", v.value);
    e = f.engine();
    try e.discover();
    for (e.actions.items, 0..) |a, i| {
        if (a.kind == .log) try t.expectError(error.AuditedReleaseOnlyTraces, e.qualify(i));
    }
}

test "storage cleanup: indexed pins cover ancestors and missing descendants but respect boundaries" {
    const f = try Fixture.init();
    defer f.deinit();
    for ([_][]const u8{ run, cache ++ "/future/file", cache ++ "-neighbor/file" }) |target| {
        var e = f.engine();
        try f.build(&e);
        try e.discover();
        try f.write(run ++ "/index.sha256", try e.c.fmt("{s}  {s}\n", .{ try e.digest(cache ++ "/o/object"), target }));
        try e.pins();
        try t.expectEqual(if (std.mem.eql(u8, target, cache ++ "-neighbor/file")) @as(@FieldType(core.Action, "status"), .discovered) else .skipped, e.actions.items[0].status);
    }
}

test "storage cleanup: minimal mode preserves byte limits and protection declarations" {
    const config: p.Config = .{ .max_reclaim_bytes = 4096, .protected_paths = &.{run}, .current_manifests = &.{"required.sha256"}, .holds_file = "queue.json" };
    const minimal = p.minimal(config);
    try t.expectEqual(@as(u32, 0), minimal.minimum_idle_hours);
    try t.expectEqual(@as(usize, 1024), minimal.max_candidates);
    try t.expectEqual(config.max_reclaim_bytes, minimal.max_reclaim_bytes);
    try t.expectEqualStrings(run, minimal.protected_paths[0]);
    try t.expectEqualStrings("required.sha256", minimal.current_manifests[0]);
    try t.expectEqualStrings(config.holds_file, minimal.holds_file);
}

test "storage cleanup: pinned candidates do not consume the collection budget" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    e.config.max_candidates = 1;
    e.config.max_reclaim_bytes = 4096;
    for ([_]@FieldType(core.Action, "status"){ .skipped, .ready, .ready }) |status| try e.actions.append(f.c.a, .{ .path = cache, .run_root = run, .producer = report, .kind = .cache, .status = status, .allocated_bytes = 4096 });
    e.applyLimits();
    try t.expectEqual(.ready, e.actions.items[1].status);
    try t.expectEqual(.skipped, e.actions.items[2].status);
    try t.expect(e.hasReady());
}

test "storage cleanup: directory pin aliases are resolved anew for each mutation" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    try f.tmp.dir.createDirPath(t.io, "unrelated/o");
    try f.write("unrelated/o/object", "other");
    try f.tmp.dir.symLink(t.io, "unrelated", "directory-alias", .{ .is_directory = true });
    try f.write(run ++ "/directory.sha256", try e.c.fmt("{s}  directory-alias/o/object\n", .{try e.digest("unrelated/o/object")}));
    try e.pins();
    try t.expectEqual(.discovered, e.actions.items[0].status);
    try f.tmp.dir.deleteFile(t.io, "directory-alias");
    try f.tmp.dir.symLink(t.io, cache, "directory-alias", .{ .is_directory = true });
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

test "storage cleanup: pin resolution remains correct beyond the directory descriptor budget" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.build(&e);
    try e.discover();
    var lines: std.ArrayList(u8) = .empty;
    for (0..140) |i| {
        const dir = try e.c.fmt("pin-directories/d{d}", .{i});
        try f.tmp.dir.createDirPath(t.io, dir);
        const path = try e.c.fmt("{s}/file", .{dir});
        try f.write(path, "unrelated");
        try lines.appendSlice(f.c.a, try e.c.fmt("{s}  {s}\n", .{ try e.digest(path), path }));
    }
    try f.tmp.dir.symLink(t.io, "../../" ++ cache ++ "/o/object", "pin-directories/d139/last-alias", .{});
    try lines.appendSlice(f.c.a, try e.c.fmt("{s}  pin-directories/d139/last-alias\n", .{try e.digest(cache ++ "/o/object")}));
    try f.write(run ++ "/many-pins.sha256", lines.items);
    try e.pins();
    try t.expect(e.pin_open_directories <= 128);
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

const GeneratedFault = enum { none, failed_assemble, wrong_output, bad_index, incomplete, wrong_source };
fn assemblyFixture(f: *Fixture, e: *core.Engine, fault: GeneratedFault) !void {
    try f.tmp.dir.createDirPath(t.io, assembly_dir);
    try f.write(assembly_path, ".text\n# disposable generated assembly\n");
    try f.write(assembly_dir ++ "/linked.zig", "pub fn main() void {}\n");
    for ([_][]const u8{ "compile.stdout", "compile.stderr", "assemble.stdout", "assemble.stderr" }) |name|
        try f.write(try f.c.fmt("{s}/{s}", .{ assembly_dir, name }), "original diagnostic\n");
    const emitter = "/reviewed/zig";
    const compile = [_][]const u8{ emitter, "build-exe", try e.absolute(assembly_dir ++ "/linked.zig"), "-fno-emit-bin", try f.c.fmt("-femit-asm={s}", .{try e.absolute(if (fault == .wrong_output) assembly_dir ++ "/unrelated.s" else assembly_path)}) };
    const assemble = [_][]const u8{ emitter, "cc", "-x", "assembler", "-c", try e.absolute(assembly_path), "-o", try e.absolute(assembly_dir ++ "/linked-harness.o") };
    try e.write(assembly_owner ++ "/commands.json", .{
        .{ .argv = compile, .outcome = "completed", .returncode = 0, .actual_returncode = 0, .stdout = try e.absolute(assembly_dir ++ "/compile.stdout"), .stderr = try e.absolute(assembly_dir ++ "/compile.stderr") },
        .{ .argv = assemble, .outcome = "completed", .returncode = if (fault == .failed_assemble) @as(i32, 2) else 0, .actual_returncode = if (fault == .failed_assemble) @as(i32, 2) else 0, .stdout = try e.absolute(assembly_dir ++ "/assemble.stdout"), .stderr = try e.absolute(assembly_dir ++ "/assemble.stderr") },
    });
    try e.write(assembly_owner ++ "/report.json", .{
        .schema = "execution-breadth-controls-v2",
        .status = "passed",
        .rows = .{.{ .mode = "ReleaseFast", .status = if (fault == .incomplete) "failed" else "passed", .harness = .{
            .source = try e.absolute(if (fault == .wrong_source) assembly_dir ++ "/other.zig" else assembly_dir ++ "/linked.zig"),
            .object = try e.absolute(assembly_dir ++ "/linked-harness.o"),
            .producer_commands = [_]usize{ 0, if (fault == .bad_index) 99 else 1 },
            .emitter = .{ .path = emitter },
        } }},
    });
}

test "storage cleanup: generated assembly removal keeps source, commands and diagnostics" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try assemblyFixture(f, &e, .none);
    const request = try generated.request(&e, assembly_path, "Completed generated test output");
    try e.write(run ++ "/generated-release.json", request);
    try e.discoverRelease(run ++ "/generated-release.json", true);
    try e.qualify(0);
    try t.expectEqual(.ready, e.actions.items[0].status);
    try mutation.apply(&e, 0);
    try t.expect(!u.exists(t.io, try e.absolute(assembly_path)));
    for ([_][]const u8{ assembly_dir ++ "/linked.zig", assembly_owner ++ "/report.json", assembly_owner ++ "/commands.json", assembly_dir ++ "/compile.stderr", assembly_dir ++ "/assemble.stderr" }) |path|
        try t.expect(u.exists(t.io, try e.absolute(path)));
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: generated assembly rejects failed, unrelated and incomplete commands" {
    inline for (.{
        .{ GeneratedFault.failed_assemble, error.GeneratedCommandNotSuccessful },
        .{ GeneratedFault.wrong_output, error.UnboundAssemblyProducer },
        .{ GeneratedFault.bad_index, error.InvalidGeneratedCommandIndexes },
        .{ GeneratedFault.incomplete, error.IncompleteGeneratedComparison },
        .{ GeneratedFault.wrong_source, error.UnboundHarnessSource },
    }) |case| {
        const f = try Fixture.init();
        defer f.deinit();
        var e = f.engine();
        try assemblyFixture(f, &e, case[0]);
        try t.expectError(case[1], generated.request(&e, assembly_path, "Review generated output"));
        try t.expect(u.exists(t.io, try e.absolute(assembly_path)));
    }
}

test "storage cleanup: changed generated commands stop mutation and preserve payload" {
    const f = try Fixture.init();
    defer f.deinit();
    var initial = f.engine();
    try assemblyFixture(f, &initial, .none);
    try initial.write(run ++ "/generated-release.json", try generated.request(&initial, assembly_path, "Completed generated test output"));
    var e = f.engine();
    try e.discoverRelease(run ++ "/generated-release.json", true);
    try e.qualify(0);
    try f.write(assembly_owner ++ "/commands.json", "[]\n");
    if (mutation.apply(&e, 0)) |_| return error.ChangedCommandsAccepted else |_| {}
    try t.expect(u.exists(t.io, try e.absolute(assembly_path)));
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: checksum pins still protect generated assembly" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try assemblyFixture(f, &e, .none);
    try e.write(run ++ "/generated-release.json", try generated.request(&e, assembly_path, "Completed generated test output"));
    try e.discoverRelease(run ++ "/generated-release.json", true);
    try e.qualify(0);
    try f.write(run ++ "/accepted.sha256", try f.c.fmt("{s}  {s}\n", .{ try e.digest(assembly_path), assembly_path }));
    try e.pins();
    try t.expectEqual(.skipped, e.actions.items[0].status);
}

fn captureFixture(f: *Fixture, e: *core.Engine, wrong_hash: bool) !void {
    try f.write(run ++ "/capture-zllvm", "\x7fELFsynthetic-validation-runner");
    try f.write(run ++ "/commands.json", "[]\n");
    try e.write(report, .{ .schema = "real-program-v1", .status = "passed", .tool_provenance = .{ .binary_sha256 = if (wrong_hash) "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" else try e.digest(run ++ "/capture-zllvm") }, .rows = .{.{ .mode = "ReleaseFast", .status = "matched" }} });
}

test "storage cleanup: capture helper requires the runner provenance hash" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try captureFixture(f, &e, true);
    try t.expectError(error.CaptureRunnerHashMismatch, generated.request(&e, run ++ "/capture-zllvm", "Completed capture helper"));
    try captureFixture(f, &e, false);
    e = f.engine();
    try e.write(run ++ "/generated-release.json", try generated.request(&e, run ++ "/capture-zllvm", "Completed capture helper"));
    try e.discoverRelease(run ++ "/generated-release.json", true);
    try e.qualify(0);
    try mutation.apply(&e, 0);
    try t.expect(!u.exists(t.io, try e.absolute(run ++ "/capture-zllvm")));
    try t.expect(u.exists(t.io, try e.absolute(report)));
}

test "storage cleanup: aliased capture helpers cannot be removed" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try captureFixture(f, &e, false);
    const file = try f.tmp.dir.openFile(t.io, run ++ "/capture-zllvm", .{});
    defer file.close(t.io);
    try file.hardLink(t.io, f.tmp.dir, run ++ "/still-needed-runner", .{});
    try e.write(run ++ "/generated-release.json", try generated.request(&e, run ++ "/capture-zllvm", "Completed capture helper"));
    try e.discoverRelease(run ++ "/generated-release.json", true);
    try t.expectError(error.AliasedOrNonRegularArtifact, e.qualify(0));
}

test "storage cleanup: generated assembly adapter does not accept arbitrary source files" {
    try t.expect(!p.artifactName(.{ .path = assembly_dir ++ "/original.s", .sha256 = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", .kind = .generated_assembly }));
}

test "storage cleanup: parent integrated job protects finished subtest outputs" {
    const parent = "local-state/validations/example/batch/integrated-v2";
    const scope = generated.consumerRoot(parent ++ "/execution-breadth-controls");
    try t.expectEqualStrings(parent, scope);
    try t.expect(core.commandUsesRun("123 runner --output-root " ++ parent, scope, 456));
    try t.expectEqualStrings(run, generated.consumerRoot(run));
}

fn generatedBatchFixture(f: *Fixture, e: *core.Engine) !void {
    for ([_][]const u8{ "first", "second" }, 0..) |name, index| {
        const owner = try f.c.fmt("{s}/integrated-batch/{s}", .{ run, name });
        const path = try f.c.fmt("{s}/capture-zllvm", .{owner});
        try f.tmp.dir.createDirPath(t.io, owner);
        try f.write(path, "\x7fELFtemporary copied runner");
        try f.write(try f.c.fmt("{s}/commands.json", .{owner}), "[]\n");
        try f.write(try f.c.fmt("{s}/input.ll", .{owner}), "original input remains\n");
        try e.write(try f.c.fmt("{s}/report.json", .{owner}), .{ .schema = "real-program-v1", .status = "passed", .tool_provenance = .{ .binary_sha256 = try e.digest(path) }, .rows = .{.{ .mode = "ReleaseFast", .status = "matched" }} });
        const request_path = try f.c.fmt("{s}/batch-release-{d}.json", .{ run, index });
        try e.write(request_path, try generated.request(e, path, "Completed copied helpers"));
        try e.discoverRelease(request_path, true);
        try e.qualify(index);
    }
}

test "storage cleanup: generated batch removes only named files and records each result" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try generatedBatchFixture(f, &e);
    var parent = try f.tmp.dir.openDir(t.io, run ++ "/integrated-batch/first", .{ .iterate = true });
    try parent.setPermissions(t.io, .fromMode(0o500));
    parent.close(t.io);
    defer {
        var restore = f.tmp.dir.openDir(t.io, run ++ "/integrated-batch/first", .{ .iterate = true }) catch unreachable;
        defer restore.close(t.io);
        restore.setPermissions(t.io, .fromMode(0o700)) catch {};
    }
    try mutation.applyGeneratedBatch(&e, &.{ 0, 1 });
    parent = try f.tmp.dir.openDir(t.io, run ++ "/integrated-batch/first", .{ .iterate = true });
    defer parent.close(t.io);
    try t.expectEqual(@as(u32, 0o500), (try parent.stat(t.io)).permissions.toMode() & 0o7777);
    for (e.actions.items, 0..) |a, index| {
        try t.expectEqual(.removed, a.status);
        try t.expectEqual(a.allocated_bytes, a.reclaimed_file_bytes);
        try t.expect(!u.exists(t.io, try e.absolute(a.path)));
        try t.expect(u.exists(t.io, try e.absolute(try f.c.fmt("{s}/record-{d}.json", .{ output, index }))));
        try t.expect(u.exists(t.io, try e.absolute(try f.c.fmt("{s}/input.ll", .{a.run_root}))));
    }
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: generated batch rolls back every name when a pin appears at refresh" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try generatedBatchFixture(f, &e);
    try f.write(run ++ "/new-pin.sha256", try f.c.fmt("{s}  {s}\n", .{ e.actions.items[1].sha256.?, e.actions.items[1].path }));
    try t.expectError(error.GeneratedBatchBecameHeld, mutation.applyGeneratedBatch(&e, &.{ 0, 1 }));
    for (e.actions.items) |a| {
        try t.expect(u.exists(t.io, try e.absolute(a.path)));
        try t.expectEqual(@as(u64, 0), a.reclaimed_file_bytes);
        try t.expectEqualStrings(a.sha256.?, try f.c.digest(try e.absolute(a.path)));
    }
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: generated batch rejects changed files before any quarantine" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try generatedBatchFixture(f, &e);
    try f.write(e.actions.items[1].path, "changed output");
    try t.expectError(error.CandidateChanged, mutation.applyGeneratedBatch(&e, &.{ 0, 1 }));
    for (e.actions.items) |a| try t.expect(u.exists(t.io, try e.absolute(a.path)));
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: generated batch rejects duplicate members and unrelated generations" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try generatedBatchFixture(f, &e);
    try t.expectError(error.InvalidGeneratedBatch, mutation.applyGeneratedBatch(&e, &.{ 0, 0 }));
    e.actions.items[1].run_root = "local-state/validations/unrelated/batch/integrated-other";
    try t.expectError(error.InvalidGeneratedBatch, mutation.applyGeneratedBatch(&e, &.{ 0, 1 }));
    for (e.actions.items) |a| try t.expect(u.exists(t.io, try e.absolute(a.path)));
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

fn retiredLogFixture(f: *Fixture, e: *core.Engine, size: u64, applied: bool) !void {
    try assemblyFixture(f, e, .none);
    try f.tmp.dir.deleteFile(t.io, assembly_dir ++ "/compile.stdout");
    try f.write(output ++ "/approved-audit.json", "{\"reviewed\":true}\n");
    try e.write(output ++ "/record.json", .{
        .schema = 1,
        .status = "complete",
        .preservation_verified_before = true,
        .preservation_verified_after = true,
        .audit_sha256 = try e.digest(output ++ "/approved-audit.json"),
        .actions = .{.{ .path = assembly_dir ++ "/compile.stdout", .sha256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", .applied = applied, .info = .{ .size = size, .allocated = 0 } }},
    });
    e.config.retired_empty_log_records = try f.c.a.dupe(p.Evidence, &.{.{ .path = output ++ "/record.json", .sha256 = try e.digest(output ++ "/record.json") }});
}

test "storage cleanup: retired empty diagnostics retain verified ledger and audit" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try retiredLogFixture(f, &e, 0, true);
    try e.write(run ++ "/generated-release.json", try generated.request(&e, assembly_path, "Verified empty log retirement"));
    try e.discoverRelease(run ++ "/generated-release.json", true);
    try e.qualify(0);
    try mutation.apply(&e, 0);
    try t.expect(!u.exists(t.io, try e.absolute(assembly_path)));
    try t.expect(u.exists(t.io, try e.absolute(output ++ "/record.json")));
    try t.expect(u.exists(t.io, try e.absolute(output ++ "/approved-audit.json")));
}

test "storage cleanup: missing or nonempty retired diagnostics stay blocked" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try retiredLogFixture(f, &e, 1, true);
    try t.expectError(error.NonemptyOrUnretiredLog, generated.request(&e, assembly_path, "Reject nonempty log"));
    e.config.retired_empty_log_records = &.{};
    try t.expectError(error.MissingDiagnosticRetirement, generated.request(&e, assembly_path, "Reject unknown missing log"));
}

test "storage cleanup: changed retired log audit blocks deletion" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try retiredLogFixture(f, &e, 0, true);
    try e.write(run ++ "/generated-release.json", try generated.request(&e, assembly_path, "Verified empty log retirement"));
    try e.discoverRelease(run ++ "/generated-release.json", true);
    try e.qualify(0);
    try f.write(output ++ "/approved-audit.json", "changed audit\n");
    try t.expectError(error.EvidenceHashMismatch, mutation.apply(&e, 0));
    try t.expect(u.exists(t.io, try e.absolute(assembly_path)));
}

test "storage cleanup: only a terminal receipt closes a job-owned hold" {
    const lifecycle = @import("../validation/storage_lifecycle.zig");
    const jobs = @import("jobs.zig");
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    var job: lifecycle.Job = .{ .run_root = run, .working_directory = run, .producer = .{ .path = report, .sha256 = "" }, .started_ns = 1 };
    try t.expect(!try jobs.validate(&e, job));
    try e.write(report, .{ .status = "finished", .outcome = "completed", .actual_returncode = 1, .started_ns = 1, .finished_ns = 2, .cwd = try e.absolute(run) });
    job.state = .finished;
    job.producer.sha256 = try e.digest(report);
    try t.expect(try jobs.validate(&e, job));
    job.started_ns = 9;
    try t.expectError(error.StorageJobNotTerminal, jobs.validate(&e, job));
    job.started_ns = 1;
    try f.write(report, "{}\n");
    try t.expectError(error.FileChanged, jobs.validate(&e, job));
}

test "storage cleanup: completed job does not expire manual holds" {
    const lifecycle = @import("../validation/storage_lifecycle.zig");
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.tmp.dir.createDirPath(t.io, lifecycle.jobs_directory);
    try e.write(report, .{ .status = "finished", .outcome = "completed", .actual_returncode = 0, .started_ns = 1, .finished_ns = 2, .cwd = try e.absolute(run) });
    const job: lifecycle.Job = .{ .state = .finished, .run_root = run, .working_directory = run, .producer = .{ .path = report, .sha256 = try e.digest(report) }, .started_ns = 1 };
    try e.write(lifecycle.jobs_directory ++ "/test.json", job);
    try e.write(e.config.holds_file, p.Holds{ .paths = &.{run} });
    try e.actions.append(f.c.a, .{ .path = cache, .run_root = run, .producer = report, .kind = .cache });
    try e.loadHolds();
    try t.expectEqual(.skipped, e.actions.items[0].status);
    try t.expect(std.mem.indexOf(u8, e.actions.items[0].reason.?, "protected by hold") != null);
}

test "storage cleanup: shared input migration preserves aliases and rolls back a new hold" {
    const shared = @import("shared_inputs.zig");
    const storage = @import("../zllvm_artifact_store/store.zig");
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.write(run ++ "/input.ll", "identical retained IR\n");
    const file = try f.tmp.dir.openFile(t.io, run ++ "/input.ll", .{});
    try file.hardLink(t.io, f.tmp.dir, run ++ "/alias.ll", .{});
    const sha = try e.digest(run ++ "/input.ll");
    const metadata = try e.metadata(run ++ "/input.ll");
    var store = try storage.Store.open(f.c.a, t.io, try e.absolute("local-state/artifacts"), true);
    defer store.deinit();
    try store.publishFile(file, .{ .name = "input.ll", .sha256 = sha, .bytes = metadata.size });
    file.close(t.io);
    for ([_][]const u8{ run ++ "/input.ll", run ++ "/alias.ll" }) |path|
        try e.actions.append(f.c.a, .{ .path = path, .run_root = run, .producer = report, .kind = .build_output, .status = .ready, .sha256 = sha, .metadata = metadata });
    try e.write(e.config.holds_file, p.Holds{ .paths = &.{run} });
    try t.expectError(error.SharedInputHeld, shared.migrate(&e, &store, &.{ 0, 1 }, metadata, sha));
    try t.expectEqual(metadata.inode, (try e.metadata(run ++ "/input.ll")).inode);
    try t.expectEqual(metadata.inode, (try e.metadata(run ++ "/alias.ll")).inode);
    try t.expectEqual(metadata.links, (try e.metadata(run ++ "/input.ll")).links);
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
    try f.tmp.dir.deleteFile(t.io, e.config.holds_file);
    // Rollback changes ctime; take a fresh observation before retrying.
    e = f.engine();
    const retry = try e.metadata(run ++ "/input.ll");
    for ([_][]const u8{ run ++ "/input.ll", run ++ "/alias.ll" }) |path|
        try e.actions.append(f.c.a, .{ .path = path, .run_root = run, .producer = report, .kind = .build_output, .status = .ready, .sha256 = sha, .metadata = retry });
    try t.expectEqual(retry.allocated_bytes, try shared.migrate(&e, &store, &.{ 0, 1 }, retry, sha));
    const object = try store.objects.statFile(t.io, sha, .{});
    for (e.actions.items) |a| {
        const current = try e.metadata(a.path);
        try t.expectEqual(object.inode, current.inode);
        try t.expectEqual(@as(u32, 0o444), current.mode & 0o7777);
        try t.expectEqualStrings(sha, try e.digest(a.path));
    }
}

test "storage cleanup: shared input migration rejects incomplete aliases and changed content" {
    const shared = @import("shared_inputs.zig");
    const storage = @import("../zllvm_artifact_store/store.zig");
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try f.write(run ++ "/input.ll", "retained IR\n");
    const file = try f.tmp.dir.openFile(t.io, run ++ "/input.ll", .{});
    defer file.close(t.io);
    try file.hardLink(t.io, f.tmp.dir, run ++ "/unknown-alias.ll", .{});
    const metadata = try e.metadata(run ++ "/input.ll");
    const sha = try e.digest(run ++ "/input.ll");
    var store = try storage.Store.open(f.c.a, t.io, try e.absolute("local-state/artifacts"), true);
    defer store.deinit();
    try e.actions.append(f.c.a, .{ .path = run ++ "/input.ll", .run_root = run, .producer = report, .kind = .build_output, .status = .ready, .sha256 = sha, .metadata = metadata });
    try t.expectError(error.IncompleteInputAliases, shared.migrate(&e, &store, &.{0}, metadata, sha));
    try f.tmp.dir.deleteFile(t.io, run ++ "/unknown-alias.ll");
    const single = try e.metadata(run ++ "/input.ll");
    try f.write(run ++ "/input.ll", "changed IR\n");
    try t.expectError(error.SharedInputChanged, shared.migrate(&e, &store, &.{0}, single, sha));
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

fn captureAliasFixture(f: *Fixture, e: *core.Engine) !void {
    try generatedBatchFixture(f, e);
    try f.tmp.dir.deleteFile(t.io, e.actions.items[1].path);
    const file = try f.tmp.dir.openFile(t.io, e.actions.items[0].path, .{});
    defer file.close(t.io);
    try file.hardLink(t.io, f.tmp.dir, e.actions.items[1].path, .{});
    e.allow_capture_aliases = true;
    for (0..2) |i| {
        e.actions.items[i].status = .discovered;
        try e.qualify(i);
    }
    try e.guardCaptureGroups();
}

test "storage cleanup: complete capture alias retirement charges one physical inode" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try captureAliasFixture(f, &e);
    const allocation = e.actions.items[0].metadata.?.allocated_bytes;
    try t.expectEqual(allocation, e.actions.items[0].allocated_bytes + e.actions.items[1].allocated_bytes);
    try mutation.applyGeneratedBatch(&e, &.{ 0, 1 });
    try t.expectEqual(allocation, e.actions.items[0].reclaimed_file_bytes + e.actions.items[1].reclaimed_file_bytes);
    for (e.actions.items) |a| try t.expect(!u.exists(t.io, try e.absolute(a.path)));
}

test "storage cleanup: a current pin on one capture alias protects the group" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try captureAliasFixture(f, &e);
    try f.write(run ++ "/current.sha256", try f.c.fmt("{s}  {s}\n", .{ e.actions.items[1].sha256.?, e.actions.items[1].path }));
    e.config.current_manifests = &.{run ++ "/current.sha256"};
    try e.pins();
    try e.guardCaptureGroups();
    for (e.actions.items) |a| {
        try t.expectEqual(.skipped, a.status);
        try t.expect(u.exists(t.io, try e.absolute(a.path)));
    }
}

test "storage cleanup: newly pinned capture aliases roll back every name" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try captureAliasFixture(f, &e);
    try f.write(run ++ "/new.sha256", try f.c.fmt("{s}  {s}\n", .{ e.actions.items[1].sha256.?, e.actions.items[1].path }));
    try t.expectError(error.GeneratedBatchBecameHeld, mutation.applyGeneratedBatch(&e, &.{ 0, 1 }));
    for (e.actions.items) |a| {
        try t.expectEqual(@as(u64, 2), (try e.metadata(a.path)).links);
        try t.expectEqual(@as(u64, 0), a.reclaimed_file_bytes);
    }
    try t.expect(!u.exists(t.io, try e.absolute(mutation.pending_path)));
}

test "storage cleanup: undeclared capture alias still prevents collection" {
    const f = try Fixture.init();
    defer f.deinit();
    var e = f.engine();
    try captureAliasFixture(f, &e);
    const file = try f.tmp.dir.openFile(t.io, e.actions.items[0].path, .{});
    defer file.close(t.io);
    try file.hardLink(t.io, f.tmp.dir, run ++ "/unlisted-runner", .{});
    e.actions.items[0].status = .discovered;
    try t.expectError(error.AliasedOrNonRegularArtifact, e.qualify(0));
}
