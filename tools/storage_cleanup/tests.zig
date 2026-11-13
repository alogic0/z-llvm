const std = @import("std");
const t = std.testing;
const u = @import("../validation/common.zig");
const core = @import("engine.zig");
const mutation = @import("mutation.zig");
const releases = @import("release.zig");
const batches = @import("batch.zig");
const p = core.p;
const run = "local-state/validations/test/batch/build";
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
    try batches.historicalPins(&prepare, output ++ "/requests.json", output ++ "/review.json");
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
