//! New producers explicitly own a separate temporary tree. Legacy mixed trees
//! still require their existing per-artifact release rules.
const std = @import("std");
const core = @import("engine.zig");
const p = core.p;
const layout = @import("../validation/storage_paths.zig");
const workspace = @import("../validation/storage_workspace.zig");

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
        if (r.state != .disposable) {
            e.actions.items[i].status = .skipped;
            e.actions.items[i].reason = if (r.state == .active) "workspace producer has not closed" else "failed workspace retained for investigation";
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
    if (!std.mem.eql(u8, action.path, r.temporary_root) or !std.mem.eql(u8, action.run_root, r.evidence_root) or r.state != .disposable) return error.WorkspaceNotReleased;
    const result = r.result orelse return error.WorkspaceNotReleased;
    try e.keep(kept, action.producer, try e.digest(action.producer));
    try e.keep(kept, result.path, result.sha256);
    var report = try e.load(e.c.gpa, result.path);
    defer report.deinit();
    if (!workspace.successful(report.value)) return error.WorkspaceResultDidNotPass;
    for (r.diagnostics) |ev| try e.keep(kept, ev.path, ev.sha256);
}
