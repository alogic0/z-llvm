//! Fresh workspaces separate disposable work from maintained validation data.
const std = @import("std");
const u = @import("common.zig");
const p = @import("../storage_cleanup/policy.zig");
const lifecycle = @import("storage_lifecycle.zig");
const store = @import("../zllvm_artifact_store/store.zig");
pub const paths = @import("storage_paths.zig");

pub const Workspace = struct {
    project: []const u8,
    record_path: []const u8,
    record: paths.Record,
    lease: std.Io.File,
    previous: ?paths.Paths,

    pub fn close(w: Workspace, c: *u.Context) void {
        c.workspace_paths = w.previous;
        w.lease.unlock(c.io);
        w.lease.close(c.io);
    }
    /// A failed/unfinished producer keeps its scratch, including partial output.
    /// Only an independently readable passed report authorizes whole-workspace GC.
    pub fn finish(w: Workspace, c: *u.Context, result_path: []const u8, diagnostics: []const []const u8) !void {
        if (!p.within(try c.fmt("{s}/{s}", .{ w.project, w.record.evidence_root }), result_path)) return error.InvalidWorkspaceEvidence;
        const result = try c.load(result_path);
        var record = w.record;
        record.state = if (successful(result)) .disposable else .retained;
        record.result = .{ .path = result_path[w.project.len + 1 ..], .sha256 = try c.digest(result_path) };
        const kept = try c.a.alloc(p.Evidence, diagnostics.len);
        for (diagnostics, kept) |path, *ev| {
            if (!p.within(try c.fmt("{s}/{s}", .{ w.project, record.evidence_root }), path)) return error.InvalidWorkspaceEvidence;
            ev.* = .{ .path = path[w.project.len + 1 ..], .sha256 = try c.digest(path) };
        }
        record.diagnostics = kept;
        try paths.validate(c.a, w.record_path[w.project.len + 1 ..], record);
        try c.writeJson(w.record_path, record);
    }
    pub fn finishReport(w: Workspace, c: *u.Context) !void {
        const evidence = try c.fmt("{s}/{s}", .{ w.project, w.record.evidence_root });
        const commands = try c.fmt("{s}/commands.json", .{evidence});
        try w.finish(c, try c.fmt("{s}/report.json", .{evidence}), if (u.exists(c.io, commands)) &.{commands} else &.{});
    }
};

pub fn successful(value: u.Value) bool {
    if (value != .object) return false;
    if (value.object.contains("error") or value.object.contains("runner_error")) return false;
    const status = value.object.get("status") orelse return false;
    if (u.json.is(status, "passed")) return true;
    return u.json.is(status, "finished") and u.json.is(value.object.get("outcome") orelse .null, "completed") and
        u.json.eql(value.object.get("actual_returncode") orelse .null, u.n(0)) and
        u.json.eql(value.object.get("returncode") orelse .null, u.n(0));
}

pub fn start(c: *u.Context, evidence: []const u8, key: []const u8) !?Workspace {
    const project = (try lifecycle.projectRoot(c)) orelse return null;
    if (evidence.len <= project.len or !p.within(project, evidence) or !p.candidate(evidence[project.len + 1 ..])) return null;
    const relative = evidence[project.len + 1 ..];
    var evidence_dir = try store.openDirectory(c.io, evidence, false);
    evidence_dir.close(c.io);
    const temporary = try paths.temporaryRoot(c.a, relative, key);
    const record_path = try c.fmt("{s}/{s}", .{ project, try paths.recordPath(c.a, relative, key) });
    var state = try store.openDirectory(c.io, try c.fmt("{s}/local-state/storage-cleanup", .{project}), true);
    defer state.close(c.io);
    const lease = try state.createFile(c.io, "cleanup.lock", .{ .truncate = false });
    errdefer lease.close(c.io);
    try lease.lock(c.io, .shared);
    const absolute = try c.fmt("{s}/{s}", .{ project, temporary });
    var parent = try store.openDirectory(c.io, std.fs.path.dirname(absolute).?, true);
    defer parent.close(c.io);
    // Never adopt an old tree, follow a symlink, or re-bless an earlier result.
    if (u.exists(c.io, record_path)) return error.WorkspaceAlreadyExists;
    try parent.createDir(c.io, key, .fromMode(0o700));
    const record: paths.Record = .{ .evidence_root = relative, .temporary_root = temporary, .key = key };
    try u.json.writeAtomic(c.gpa, c.io, .{ .path = record_path, .replace = false }, record);
    const previous = c.workspace_paths;
    c.workspace_paths = .{ .evidence = evidence, .temporary = absolute };
    return .{ .project = project, .record_path = record_path, .record = record, .lease = lease, .previous = previous };
}

/// Capture subprocesses inherit the exact checked mapping, never a free-form
/// arbitrary deletion root. The parent retains its lease until they complete.
pub fn exportPaths(c: *u.Context, env: *std.process.Environ.Map) !void {
    if (c.workspace_paths) |mapping| {
        try env.put("ZLLVM_EVIDENCE_ROOT", mapping.evidence);
        try env.put("ZLLVM_TEMPORARY_ROOT", mapping.temporary);
    }
}
pub fn adopt(c: *u.Context) !void {
    const evidence = c.env.get("ZLLVM_EVIDENCE_ROOT") orelse return;
    const temporary = c.env.get("ZLLVM_TEMPORARY_ROOT") orelse return error.MissingWorkspaceMapping;
    const project = (try lifecycle.projectRoot(c)) orelse return error.InvalidWorkspaceScope;
    if (evidence.len <= project.len or temporary.len <= project.len or !p.within(project, evidence) or !p.within(project, temporary)) return error.InvalidWorkspaceScope;
    const key = std.fs.path.basename(temporary);
    const name = try paths.recordPath(c.a, evidence[project.len + 1 ..], key);
    var evidence_dir = try store.openDirectory(c.io, evidence, false);
    evidence_dir.close(c.io);
    const record = try std.json.parseFromValue(paths.Record, c.a, try c.load(try c.fmt("{s}/{s}", .{ project, name })), .{});
    try paths.validate(c.a, name, record.value);
    if (record.value.state != .active or !std.mem.eql(u8, temporary[project.len + 1 ..], record.value.temporary_root)) return error.InvalidWorkspaceScope;
    c.workspace_paths = .{ .evidence = evidence, .temporary = temporary };
}
