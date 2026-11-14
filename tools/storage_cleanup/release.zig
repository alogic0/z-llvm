//! Explicit owner transition from a fully audited trace to replay evidence.
const std = @import("std");
const core = @import("engine.zig");
const p = core.p;
const u = @import("../validation/common.zig");

fn row(e: *core.Engine, rows: *std.ArrayList(p.Retained), path: []const u8, sha: ?[]const u8, role: @FieldType(p.Retained, "role")) !void {
    const relative = try e.relative(path);
    const hash = sha orelse try e.digest(relative);
    try e.check(.{ .path = relative, .sha256 = hash });
    for (rows.items) |old| if (old.role == role and std.mem.eql(u8, old.path, relative)) return;
    try rows.append(e.c.a, .{ .path = relative, .sha256 = try e.c.a.dupe(u8, hash), .role = role });
}

/// Calling this command is the owner's lifecycle declaration. It publishes no
/// record until the normal collector checks pass, and never removes a payload.
pub fn trace(e: *core.Engine, audit_path: []const u8, build_path: []const u8, reason: []const u8) ![]const u8 {
    return traceWithSources(e, audit_path, build_path, reason, &.{});
}
pub fn traceWithSources(e: *core.Engine, audit_path: []const u8, build_path: []const u8, reason: []const u8, reconstructions: []const p.Evidence) ![]const u8 {
    return publish(e, try traceRequest(e, audit_path, build_path, reason, reconstructions, null));
}
pub fn traceRequest(e: *core.Engine, audit_path: []const u8, build_path: []const u8, reason: []const u8, reconstructions: []const p.Evidence, compiler_retirement: ?p.Evidence) !p.Release {
    return traceRequestWithPeers(e, audit_path, build_path, reason, reconstructions, compiler_retirement, &.{});
}
pub fn traceRequestWithPeers(e: *core.Engine, audit_path: []const u8, build_path: []const u8, reason: []const u8, reconstructions: []const p.Evidence, compiler_retirement: ?p.Evidence, peers: []const p.Evidence) !p.Release {
    if (!p.relative(audit_path) or !p.relative(build_path) or reason.len == 0) return error.InvalidReleaseArguments;
    var audit = try e.load(e.c.gpa, audit_path);
    defer audit.deinit();
    const v = audit.value;
    const raw = try e.relative(try core.str(v, "path"));
    const raw_sha = try core.str(v, "sha256");
    if (!p.artifactName(.{ .path = raw, .sha256 = raw_sha, .kind = .raw_trace, .audit = audit_path })) return error.InvalidReleaseArtifact;
    const top = try core.get(v, "top_report");
    const run = std.fs.path.dirname(try e.relative(try core.str(top, "path"))) orelse return error.InvalidReleaseScope;
    if (!p.candidate(run) or !p.within(run, raw)) return error.InvalidReleaseScope;
    const producer = try core.get(v, "producer");
    const producer_path = try e.relative(try core.str(producer, "path"));
    var rows: std.ArrayList(p.Retained) = .empty;
    var producer_record = try e.load(e.c.gpa, producer_path);
    defer producer_record.deinit();
    if (producer_record.value != .object) return error.ExpectedObject;
    // run_checked stores its combined log beside the run, not inside it.
    for ([_][]const u8{ "log", "stdout", "stderr" }) |key| {
        if (producer_record.value.object.get(key)) |value| {
            if (value != .string) return error.InvalidProducerLog;
            try row(e, &rows, value.string, null, .diagnostic);
        }
    }
    try row(e, &rows, audit_path, null, .audit);
    try row(e, &rows, build_path, null, .build);
    for ([_]struct { key: []const u8, role: @FieldType(p.Retained, "role") }{
        .{ .key = "producer", .role = .result },
        .{ .key = "top_report", .role = .result },
        .{ .key = "backend_report", .role = .diagnostic },
        .{ .key = "input", .role = .input },
    }) |binding| {
        const value = try core.get(v, binding.key);
        try row(e, &rows, try core.str(value, "path"), try core.str(value, "sha256"), binding.role);
    }
    var build = try e.load(e.c.gpa, build_path);
    defer build.deinit();
    if (compiler_retirement) |record| {
        try row(e, &rows, record.path, record.sha256, .other);
    } else try row(e, &rows, try core.str(build.value, "compiler"), try core.str(build.value, "compiler_sha256"), .compiler);
    const sources = try core.get(build.value, "source_sha256");
    if (sources != .object or sources.object.count() == 0) return error.MissingSourceEvidence;
    var source_it = sources.object.iterator();
    const first = source_it.next().?;
    if (first.value_ptr.* != .string or !p.relative(first.key_ptr.*)) return error.InvalidSourceEvidence;
    if (core.eq(build.value, "schema", "zllvm-compiler-build-v1")) {
        // The canonical adapter verifies every source against Git/overrides.
        try row(e, &rows, build_path, null, .source);
    } else try row(e, &rows, try e.c.fmt("{s}/{s}", .{ try core.str(build.value, "source_root"), first.key_ptr.* }), first.value_ptr.string, .source);

    // Keep the rest of the original run, including detailed failure reports,
    // profiles, commands and logs. The full build map is checked by qualify.
    const relative_raw = raw[run.len + 1 ..];
    var excluded: std.ArrayList([]const u8) = .empty;
    try excluded.appendSlice(e.c.a, &.{ relative_raw, "storage-release.json" });
    const identity = core.fa.metadata.identity(try e.metadata(raw));
    for (peers) |peer| {
        if (std.mem.eql(u8, peer.path, raw) or !p.within(run, peer.path)) continue;
        if (!p.artifactName(.{ .path = peer.path, .sha256 = peer.sha256, .kind = .raw_trace, .audit = audit_path })) return error.InvalidTracePeer;
        const m = try e.metadata(peer.path);
        if (m.device != identity.device or m.inode != identity.inode) continue;
        if (!std.mem.eql(u8, peer.sha256, raw_sha)) return error.InvalidTracePeer;
        try e.check(peer);
        try excluded.append(e.c.a, peer.path[run.len + 1 ..]);
    }
    var snapshot = try core.fa.scan(e.c.gpa, e.c.io, try e.absolute(run), .{
        .hash_files = true,
        .max_entries = e.config.max_candidate_entries,
        .exclude_paths = excluded.items,
    });
    defer snapshot.deinit();
    for (snapshot.value.entries) |entry| {
        if (entry.metadata.kind == .directory) continue;
        if (entry.metadata.kind != .file) return error.SpecialReplayEvidence;
        try row(e, &rows, try e.c.fmt("{s}/{s}", .{ run, entry.path }), entry.sha256.?, .other);
    }
    const release = p.Release{
        .schema = "zllvm-storage-release-v1",
        .state = .audited,
        .run_root = run,
        .reason = reason,
        .producer = .{ .path = producer_path, .sha256 = try core.str(producer, "sha256") },
        .retained = rows.items,
        .artifacts = &.{.{ .path = raw, .sha256 = raw_sha, .kind = .raw_trace, .audit = audit_path }},
        .source_reconstructions = reconstructions,
        .compiler_retirement = compiler_retirement,
    };
    // Returned requests must own strings originally borrowed from parsed
    // audit/build documents and the local artifact array.
    return (try std.json.parseFromSlice(p.Release, e.c.a, try std.json.Stringify.valueAlloc(e.c.a, release, .{}), .{ .allocate = .alloc_always })).value;
}

pub fn request(e: *core.Engine, path: []const u8) ![]const u8 {
    if (!p.relative(path)) return error.InvalidEvidencePath;
    try e.addControl(path);
    var parsed = try e.load(e.c.gpa, path);
    defer parsed.deinit();
    var release = try std.json.parseFromValue(p.Release, e.c.gpa, parsed.value, .{});
    defer release.deinit();
    return publish(e, release.value);
}

/// Explicitly close a superseded compiler build after its accepted successor.
/// Sources, build logs, receipt and successor report are kept and reverified.
pub fn compilerBuild(e: *core.Engine, build_path: []const u8, successor_path: []const u8, reason: []const u8, reconstructions: []const p.Evidence) ![]const u8 {
    return publish(e, try buildRequest(e, build_path, successor_path, reason, reconstructions));
}
pub fn buildRequest(e: *core.Engine, build_path: []const u8, successor_path: []const u8, reason: []const u8, reconstructions: []const p.Evidence) !p.Release {
    if (!p.relative(build_path) or !p.relative(successor_path)) return error.InvalidEvidencePath;
    var parsed = try e.load(e.c.gpa, build_path);
    defer parsed.deinit();
    const compiler = try e.relative(try core.str(parsed.value, "compiler"));
    const sha = try e.c.a.dupe(u8, try core.str(parsed.value, "compiler_sha256"));
    var rows: std.ArrayList(p.Retained) = .empty;
    try row(e, &rows, build_path, null, .build);
    try row(e, &rows, build_path, null, .result);
    // For a compiler build, its inputs are the source map and toolchain in
    // this receipt. The build adapter verifies every entry, not these labels.
    try row(e, &rows, build_path, null, .source);
    try row(e, &rows, build_path, null, .input);
    return .{
        .schema = "zllvm-storage-release-v1",
        .state = .superseded,
        .run_root = if (core.eq(parsed.value, "schema", "zllvm-compiler-build-v1")) std.fs.path.dirname(std.fs.path.dirname(compiler).?).? else std.fs.path.dirname(compiler).?,
        .reason = reason,
        .producer = .{ .path = build_path, .sha256 = try e.digest(build_path) },
        .successor = .{ .path = successor_path, .sha256 = try e.digest(successor_path) },
        .retained = rows.items,
        .artifacts = try e.c.a.dupe(p.Artifact, &.{.{ .path = compiler, .sha256 = sha, .kind = .build_output }}),
        .source_reconstructions = reconstructions,
    };
}

pub fn disposableBuild(e: *core.Engine, build_path: []const u8, reason: []const u8) !p.Release {
    if (!p.relative(build_path) or reason.len == 0) return error.InvalidEvidencePath;
    var parsed = try e.load(e.c.gpa, build_path);
    defer parsed.deinit();
    const compiler = try e.relative(try core.str(parsed.value, "compiler"));
    const sha = try e.c.a.dupe(u8, try core.str(parsed.value, "compiler_sha256"));
    return .{
        .schema = "zllvm-storage-release-v1",
        .state = .disposable,
        .run_root = if (core.eq(parsed.value, "schema", "zllvm-compiler-build-v1")) std.fs.path.dirname(std.fs.path.dirname(compiler).?).? else std.fs.path.dirname(compiler).?,
        .reason = reason,
        .producer = .{ .path = build_path, .sha256 = try e.digest(build_path) },
        .retained = &.{},
        .artifacts = try e.c.a.dupe(p.Artifact, &.{.{ .path = compiler, .sha256 = sha, .kind = .build_output }}),
    };
}

pub fn publish(e: *core.Engine, release: p.Release) ![]const u8 {
    if (!std.mem.eql(u8, release.schema, "zllvm-storage-release-v1") or release.state == .held or
        !p.candidate(release.run_root) or release.reason.len == 0 or release.artifacts.len == 0) return error.InvalidReleaseScope;
    const destination = try e.c.fmt("{s}/storage-release.json", .{release.run_root});
    const draft = try e.c.fmt("{s}/release-draft.json", .{e.output});
    try e.write(draft, release);
    // The draft is created during this invocation; the engine's initial clock
    // precedes it even when the policy has no idle delay.
    e.now_ns = std.Io.Clock.real.now(e.c.io).nanoseconds;
    for (release.artifacts) |artifact| {
        if ((!p.artifactName(artifact) and !(release.command_outputs != null and p.commandOutputName(artifact))) or !p.within(release.run_root, artifact.path)) return error.InvalidReleaseArtifact;
        for (e.actions.items) |old| if (p.overlaps(old.path, artifact.path)) return error.DuplicateReleaseArtifact;
        try e.actions.append(e.c.a, .{ .path = try e.c.a.dupe(u8, artifact.path), .run_root = try e.c.a.dupe(u8, release.run_root), .producer = draft, .kind = switch (artifact.kind) {
            .raw_trace => .raw_trace,
            .build_output => .build_output,
            .generated_assembly => .generated_assembly,
            .log => .log,
            .private_cache => .cache,
        }, .sha256 = if (artifact.kind == .private_cache) null else try e.c.a.dupe(u8, artifact.sha256), .released_cache = artifact.kind == .private_cache });
    }
    try e.loadHolds();
    try e.consumers();
    for (e.actions.items, 0..) |action, index| {
        if (action.status != .discovered) return error.ReleaseCandidateHeld;
        try e.qualify(index);
    }
    try e.protectRetained();
    try e.pins();
    for (e.actions.items) |action| {
        if (action.status != .ready) return error.ReleaseCandidateHeld;
        for (action.retained) |ev| try e.check(ev);
    }
    try e.pinRevisions();
    try e.verifyRevisions();
    const data = try std.json.Stringify.valueAlloc(e.c.gpa, release, .{});
    defer e.c.gpa.free(data);
    // No replacement of an existing ownership decision, even under the lock.
    try u.files.writeAtomic(e.c.io, .{ .path = try e.absolute(destination), .replace = false }, &.{ data, "\n" });
    const file = try std.Io.Dir.cwd().openFile(e.c.io, try e.absolute(destination), .{});
    defer file.close(e.c.io);
    try file.sync(e.c.io);
    var parent = try core.fa.metadata.openRoot(e.c.io, try e.absolute(release.run_root));
    defer parent.close(e.c.io);
    if (std.os.linux.errno(std.os.linux.fsync(parent.handle)) != .SUCCESS) return error.DirectorySyncFailed;
    return destination;
}
