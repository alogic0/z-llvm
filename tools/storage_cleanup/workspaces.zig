//! New producers explicitly own a separate temporary tree. Legacy mixed trees
//! still require their existing per-artifact release rules.
const std = @import("std");
const core = @import("engine.zig");
const p = core.p;
const layout = @import("../validation/storage_paths.zig");
const workspace = @import("../validation/storage_workspace.zig");
const u = @import("../validation/common.zig");

pub fn discover(e: *core.Engine) !void {
    const names = try e.discoverPaths(&.{ "-g", "*.storage-layout.json" }, &.{"local-state/validations"});
    var lines = std.mem.tokenizeScalar(u8, names, '\n');
    while (lines.next()) |name| {
        var parsed = try e.load(e.c.gpa, name);
        defer parsed.deinit();
        var record = try std.json.parseFromValue(layout.Record, e.c.gpa, parsed.value, .{});
        defer record.deinit();
        const r = record.value;
        try layout.validate(e.c.a, name, r);
        _ = e.metadata(r.temporary_root) catch |err| switch (err) {
            error.FileNotFound => continue,
            else => return err,
        };
        try e.addControl(name);
        const i = try e.add(r.temporary_root, r.evidence_root, name, .temporary_workspace, null);
        e.actions.items[i].replay_required = false;
        const released = try layout.releasePath(e.c.a, r);
        const has_release = u.exists(e.c.io, try e.absolute(released));
        if (has_release) try e.addControl(released);
        if (r.state != .disposable and !has_release) {
            e.actions.items[i].status = .skipped;
            e.actions.items[i].reason = if (r.state == .active) "workspace producer has not closed" else if (r.lifetime == .pipeline) "pipeline awaits explicit release" else "failed workspace retained for investigation";
        }
    }
}

pub fn verify(e: *core.Engine, action: core.Action, kept: *std.ArrayList(p.Evidence)) !void {
    var parsed = try e.load(e.c.gpa, action.producer);
    defer parsed.deinit();
    var record = try std.json.parseFromValue(layout.Record, e.c.gpa, parsed.value, .{});
    defer record.deinit();
    const r = record.value;
    try layout.validate(e.c.a, action.producer, r);
    if (!std.mem.eql(u8, action.path, r.temporary_root) or !std.mem.eql(u8, action.run_root, r.evidence_root) or r.state == .active) return error.WorkspaceNotReleased;
    const result = r.result orelse return error.WorkspaceNotReleased;
    try e.keep(kept, action.producer, try e.digest(action.producer));
    try e.keep(kept, result.path, result.sha256);
    var report = try e.load(e.c.gpa, result.path);
    defer report.deinit();
    const release_path = action.workspace_release orelse try layout.releasePath(e.c.a, r);
    if (u.exists(e.c.io, try e.absolute(release_path))) {
        var released = try e.load(e.c.gpa, release_path);
        defer released.deinit();
        var authorization = try std.json.parseFromValue(layout.Release, e.c.gpa, released.value, .{});
        defer authorization.deinit();
        const auth = authorization.value;
        if (!std.mem.eql(u8, auth.schema, "zllvm-workspace-release-v1") or u.trim(auth.reason).len == 0 or
            !std.mem.eql(u8, auth.layout.path, action.producer) or !std.mem.eql(u8, auth.result.path, result.path) or
            !std.mem.eql(u8, auth.result.sha256, result.sha256) or !closed(report.value)) return error.InvalidWorkspaceRelease;
        try e.keep(kept, auth.layout.path, auth.layout.sha256);
        try e.keep(kept, release_path, try e.digest(release_path));
    } else if (r.state != .disposable or r.lifetime != .validation or !workspace.successful(report.value)) return error.WorkspaceResultDidNotPass;
    for (r.diagnostics) |ev| try e.keep(kept, ev.path, ev.sha256);
}

/// An owner's decision can resolve a failed result, but cannot turn an
/// unfinished producer into a completed one or rewrite its original outcome.
pub fn closed(v: u.Value) bool {
    if (workspace.successful(v)) return true;
    if (v != .object) return false;
    if (u.json.is(v.object.get("status") orelse .null, "failed")) return true;
    return u.json.is(v.object.get("status") orelse .null, "finished") and
        (v.object.get("actual_returncode") orelse .null) == .integer;
}

pub fn publish(e: *core.Engine, name: []const u8, reason: []const u8) ![]const u8 {
    if (!p.relative(name) or u.trim(reason).len == 0) return error.InvalidReleaseArguments;
    var parsed = try e.load(e.c.gpa, name);
    defer parsed.deinit();
    var record = try std.json.parseFromValue(layout.Record, e.c.gpa, parsed.value, .{});
    defer record.deinit();
    const r = record.value;
    try layout.validate(e.c.a, name, r);
    if (r.state == .active or r.result == null) return error.WorkspaceProducerNotClosed;
    const destination = try layout.releasePath(e.c.a, r);
    if (u.exists(e.c.io, try e.absolute(destination))) return error.WorkspaceAlreadyReleased;
    const release: layout.Release = .{ .layout = .{ .path = name, .sha256 = try e.digest(name) }, .result = r.result.?, .reason = reason };
    const draft = try e.c.fmt("{s}/workspace-release-draft.json", .{e.output});
    try e.write(draft, release);
    const i = try e.add(r.temporary_root, r.evidence_root, name, .temporary_workspace, null);
    e.actions.items[i].workspace_release = draft;
    e.now_ns = std.Io.Clock.real.now(e.c.io).nanoseconds;
    try e.loadHolds();
    try e.consumers();
    if (e.actions.items[i].status != .discovered) return error.ReleaseCandidateHeld;
    try e.qualify(i);
    try e.protectRetained();
    try e.pins();
    if (e.actions.items[i].status != .ready) return error.ReleaseCandidateHeld;
    for (e.actions.items[i].retained) |ev| try e.check(ev);
    for (e.controls.items) |ev| try e.check(ev);
    const bytes = try std.json.Stringify.valueAlloc(e.c.gpa, release, .{ .whitespace = .indent_2 });
    defer e.c.gpa.free(bytes);
    try u.files.writeAtomic(e.c.io, .{ .path = try e.absolute(destination), .replace = false }, &.{ bytes, "\n" });
    const file = try std.Io.Dir.cwd().openFile(e.c.io, try e.absolute(destination), .{});
    defer file.close(e.c.io);
    try file.sync(e.c.io);
    var parent = try core.fa.metadata.openRoot(e.c.io, try e.absolute(r.evidence_root));
    defer parent.close(e.c.io);
    if (std.os.linux.errno(std.os.linux.fsync(parent.handle)) != .SUCCESS) return error.DirectorySyncFailed;
    return destination;
}
