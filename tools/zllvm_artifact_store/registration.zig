const std = @import("std");
const digest = @import("digest.zig");

pub const RegistrationSnapshot = struct {
    raw: []u8,
    paths: [][]const u8,
    full_hash: [64]u8,
    path_hash: [64]u8,
    topology_hash: [64]u8,
    non_main_hash: [64]u8,
    repository_tmp_count: usize,
    system_tmp_count: usize,
    other_count: usize,

    pub fn deinit(snapshot: *RegistrationSnapshot, allocator: std.mem.Allocator) void {
        allocator.free(snapshot.paths);
        allocator.free(snapshot.raw);
        snapshot.* = undefined;
    }

    pub fn count(snapshot: RegistrationSnapshot) usize {
        return snapshot.paths.len;
    }

    pub fn eql(a: RegistrationSnapshot, b: RegistrationSnapshot) bool {
        return std.mem.eql(u8, &a.full_hash, &b.full_hash) and
            std.mem.eql(u8, &a.path_hash, &b.path_hash) and
            std.mem.eql(u8, &a.topology_hash, &b.topology_hash) and
            std.mem.eql(u8, &a.non_main_hash, &b.non_main_hash);
    }
};

pub fn parseRegistration(
    allocator: std.mem.Allocator,
    raw_input: []const u8,
) !RegistrationSnapshot {
    if (!std.mem.endsWith(u8, raw_input, "\n\n")) return error.NonCanonicalRegistrationRecord;
    const raw = try allocator.dupe(u8, raw_input);
    errdefer allocator.free(raw);
    var paths_list: std.ArrayList([]const u8) = .empty;
    errdefer paths_list.deinit(allocator);
    var path_record: std.ArrayList(u8) = .empty;
    defer path_record.deinit(allocator);
    var topology_record: std.ArrayList(u8) = .empty;
    defer topology_record.deinit(allocator);
    var repo_count: usize = 0;
    var tmp_count: usize = 0;
    var other_count: usize = 0;

    var lines = std.mem.splitScalar(u8, raw, '\n');
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "worktree ")) {
            const path = line["worktree ".len..];
            if (!std.fs.path.isAbsolute(path)) return error.NonCanonicalRegistrationRecord;
            for (paths_list.items) |prior| {
                if (std.mem.eql(u8, prior, path)) return error.DuplicateRegistration;
            }
            try paths_list.append(allocator, path);
            try path_record.appendSlice(allocator, path);
            try path_record.append(allocator, '\n');
            try topology_record.appendSlice(allocator, path);
            try topology_record.append(allocator, '\n');
            if (std.mem.startsWith(u8, path, "/home/oleg/prog/z_llvm/tmp/")) {
                repo_count += 1;
            } else if (std.mem.startsWith(u8, path, "/tmp/")) {
                tmp_count += 1;
            } else {
                other_count += 1;
            }
        } else if (std.mem.startsWith(u8, line, "branch ") or
            std.mem.eql(u8, line, "detached") or
            std.mem.startsWith(u8, line, "locked") or
            std.mem.startsWith(u8, line, "prunable"))
        {
            try topology_record.appendSlice(allocator, line);
            try topology_record.append(allocator, '\n');
        } else if (line.len == 0 or std.mem.startsWith(u8, line, "HEAD ")) {
            continue;
        } else {
            return error.UnknownRegistrationField;
        }
    }
    if (paths_list.items.len == 0) return error.EmptyRegistration;
    const first_separator = std.mem.indexOf(u8, raw, "\n\n") orelse
        return error.NonCanonicalRegistrationRecord;
    const non_main = raw[first_separator + 2 ..];
    return .{
        .raw = raw,
        .paths = try paths_list.toOwnedSlice(allocator),
        .full_hash = digest.sha256Hex(raw),
        .path_hash = digest.sha256Hex(path_record.items),
        .topology_hash = digest.sha256Hex(topology_record.items),
        .non_main_hash = digest.sha256Hex(non_main),
        .repository_tmp_count = repo_count,
        .system_tmp_count = tmp_count,
        .other_count = other_count,
    };
}
