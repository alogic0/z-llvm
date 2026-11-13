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
    try row(e, &rows, try core.str(build.value, "compiler"), try core.str(build.value, "compiler_sha256"), .compiler);
    const sources = try core.get(build.value, "source_sha256");
    if (sources != .object or sources.object.count() == 0) return error.MissingSourceEvidence;
    var source_it = sources.object.iterator();
    const first = source_it.next().?;
    if (first.value_ptr.* != .string or !p.relative(first.key_ptr.*)) return error.InvalidSourceEvidence;
    try row(e, &rows, try e.c.fmt("{s}/{s}", .{ try core.str(build.value, "source_root"), first.key_ptr.* }), first.value_ptr.string, .source);

    // Keep the rest of the original run, including detailed failure reports,
    // profiles, commands and logs. The full build map is checked by qualify.
    const destination = try e.c.fmt("{s}/storage-release.json", .{run});
    const relative_raw = raw[run.len + 1 ..];
    var snapshot = try core.fa.scan(e.c.gpa, e.c.io, try e.absolute(run), .{
        .hash_files = true,
        .max_entries = e.config.max_candidate_entries,
        .exclude_paths = &.{ relative_raw, "storage-release.json" },
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
    };
    const draft = try e.c.fmt("{s}/release-draft.json", .{e.output});
    try e.write(draft, release);
    try e.actions.append(e.c.a, .{ .path = raw, .run_root = run, .producer = draft, .kind = .raw_trace, .sha256 = raw_sha });
    const index = e.actions.items.len - 1;
    try e.loadHolds();
    try e.pins();
    try e.consumers();
    if (e.actions.items[index].status != .discovered) return error.ReleaseCandidateHeld;
    try e.qualify(index);
    try e.protectRetained();
    if (e.actions.items[index].status != .ready) return error.ReleaseCandidateHeld;
    for (e.actions.items[index].retained) |ev| try e.check(ev);
    const data = try std.json.Stringify.valueAlloc(e.c.gpa, release, .{});
    defer e.c.gpa.free(data);
    // No replacement of an existing ownership decision, even under the lock.
    try u.files.writeAtomic(e.c.io, .{ .path = try e.absolute(destination), .replace = false }, &.{ data, "\n" });
    const file = try std.Io.Dir.cwd().openFile(e.c.io, try e.absolute(destination), .{});
    defer file.close(e.c.io);
    try file.sync(e.c.io);
    var parent = try core.fa.metadata.openRoot(e.c.io, try e.absolute(run));
    defer parent.close(e.c.io);
    if (std.os.linux.errno(std.os.linux.fsync(parent.handle)) != .SUCCESS) return error.DirectorySyncFailed;
    return destination;
}
