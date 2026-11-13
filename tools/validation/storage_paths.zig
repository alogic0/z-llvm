//! The maintained tree names evidence; the mirrored temporary tree owns work.
const std = @import("std");
const p = @import("../storage_cleanup/policy.zig");

pub const Paths = struct { evidence: []const u8, temporary: []const u8 };
pub const Record = struct {
    schema: []const u8 = "zllvm-storage-workspace-v1",
    evidence_root: []const u8,
    temporary_root: []const u8,
    key: []const u8,
    state: enum { active, retained, disposable } = .active,
    result: ?p.Evidence = null,
    diagnostics: []const p.Evidence = &.{},
};
pub fn validKey(key: []const u8) bool {
    if (key.len == 0) return false;
    for (key) |ch| if (!std.ascii.isAlphanumeric(ch) and ch != '-' and ch != '_') return false;
    return true;
}
pub fn temporaryRoot(a: std.mem.Allocator, evidence: []const u8, key: []const u8) ![]const u8 {
    if (!p.candidate(evidence) or !validKey(key)) return error.InvalidWorkspaceScope;
    return std.fmt.allocPrint(a, "local-state/tmp/validations/{s}/.workspaces/{s}", .{ evidence["local-state/validations/".len..], key });
}
pub fn recordPath(a: std.mem.Allocator, evidence: []const u8, key: []const u8) ![]const u8 {
    if (!p.candidate(evidence) or !validKey(key)) return error.InvalidWorkspaceScope;
    return std.fmt.allocPrint(a, "{s}/{s}.storage-layout.json", .{ evidence, key });
}
pub fn validTemporary(path: []const u8) bool {
    if (!p.relative(path) or !std.mem.startsWith(u8, path, "local-state/tmp/validations/")) return false;
    const parent = std.fs.path.dirname(path) orelse return false;
    return std.mem.eql(u8, std.fs.path.basename(parent), ".workspaces") and validKey(std.fs.path.basename(path));
}
pub fn validate(a: std.mem.Allocator, path: []const u8, r: Record) !void {
    if (!std.mem.eql(u8, r.schema, "zllvm-storage-workspace-v1") or
        !std.mem.eql(u8, path, try recordPath(a, r.evidence_root, r.key)) or
        !std.mem.eql(u8, r.temporary_root, try temporaryRoot(a, r.evidence_root, r.key))) return error.InvalidWorkspaceScope;
    if (r.result) |ev| if (!p.relative(ev.path) or !p.within(r.evidence_root, ev.path) or !p.hash(ev.sha256)) return error.InvalidWorkspaceEvidence;
    for (r.diagnostics) |ev| if (!p.relative(ev.path) or !p.within(r.evidence_root, ev.path) or !p.hash(ev.sha256)) return error.InvalidWorkspaceEvidence;
}
