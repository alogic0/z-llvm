const std = @import("std");
const digest = @import("digest.zig");
const path_policy = @import("path_policy.zig");
const process_result = @import("process_result.zig");

pub const main_repository = "/home/oleg/prog/z_llvm";
pub const main_git_common_dir = "/home/oleg/prog/z_llvm/.git";

const expected_path_hash = "f31d8542baafc7b64cd5ee6fe8cc4194842ca696b97a7ffc8df06ce12d553d7e";
const expected_topology_hash = "6c868e3b6d436cfba92a1e2b21dbd616391763961f1cba9b6670b1ed4a6ebb62";
const expected_non_main_hash = "ebc30a376b3db4c6fbf788f49ea85f4ce792471e539c0a89308068efdf96ebbe";

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

pub const RegistrationGuard = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    frozen: RegistrationSnapshot,

    pub fn init(allocator: std.mem.Allocator, io: std.Io) !RegistrationGuard {
        const frozen = try captureRegistration(allocator, io);
        errdefer {
            var mutable = frozen;
            mutable.deinit(allocator);
        }
        try validateExpectedRegistration(frozen);
        return .{ .allocator = allocator, .io = io, .frozen = frozen };
    }

    pub fn deinit(guard: *RegistrationGuard) void {
        guard.frozen.deinit(guard.allocator);
        guard.* = undefined;
    }

    pub fn assertCurrent(guard: *const RegistrationGuard) !void {
        var current = try captureRegistration(guard.allocator, guard.io);
        defer current.deinit(guard.allocator);
        if (!guard.frozen.eql(current)) return error.RegisteredWorktreeDrift;
    }

    pub fn assertStoreRoot(guard: *const RegistrationGuard, absolute_path: []const u8) !void {
        try guard.assertDisjointFromEveryRegistration(absolute_path);
    }

    pub fn assertReadSource(
        guard: *const RegistrationGuard,
        bounded_root: []const u8,
        absolute_path: []const u8,
    ) !void {
        const normalized_root = try path_policy.normalizedAbsolute(guard.allocator, bounded_root);
        defer guard.allocator.free(normalized_root);
        const normalized_path = try path_policy.normalizedAbsolute(guard.allocator, absolute_path);
        defer guard.allocator.free(normalized_path);
        if (!std.mem.eql(u8, normalized_root, bounded_root) or
            !std.mem.eql(u8, normalized_path, absolute_path))
        {
            return error.PathNotNormalized;
        }
        if (!path_policy.pathContains(main_repository, bounded_root) or
            !path_policy.pathContains(bounded_root, absolute_path))
        {
            return error.ReadSourceOutsideBound;
        }
        for (guard.frozen.paths[1..]) |protected| {
            if (path_policy.pathContains(protected, bounded_root) or
                path_policy.pathContains(protected, absolute_path) or
                path_policy.pathContains(bounded_root, protected))
            {
                return error.RegisteredWorktreeOverlap;
            }
        }
    }

    pub fn assertSyntheticWrite(
        guard: *const RegistrationGuard,
        store_root: []const u8,
        absolute_path: []const u8,
    ) !void {
        try guard.assertStoreRoot(store_root);
        const normalized = try path_policy.normalizedAbsolute(guard.allocator, absolute_path);
        defer guard.allocator.free(normalized);
        if (!std.mem.eql(u8, normalized, absolute_path)) return error.PathNotNormalized;
        if (!path_policy.pathContains(store_root, absolute_path)) {
            return error.WriteOutsideSyntheticStore;
        }
    }

    fn assertDisjointFromEveryRegistration(
        guard: *const RegistrationGuard,
        absolute_path: []const u8,
    ) !void {
        if (!std.fs.path.isAbsolute(absolute_path)) return error.PathNotAbsolute;
        const normalized = try path_policy.normalizedAbsolute(guard.allocator, absolute_path);
        defer guard.allocator.free(normalized);
        if (!std.mem.eql(u8, normalized, absolute_path)) return error.PathNotNormalized;
        for (guard.frozen.paths) |protected| {
            if (path_policy.pathContains(protected, absolute_path) or
                path_policy.pathContains(absolute_path, protected))
            {
                return error.RegisteredWorktreeOverlap;
            }
        }
    }
};

fn captureRegistration(allocator: std.mem.Allocator, io: std.Io) !RegistrationSnapshot {
    const result = try std.process.run(allocator, io, .{
        .argv = &.{
            "/usr/bin/git",
            "--git-dir=" ++ main_git_common_dir,
            "worktree",
            "list",
            "--porcelain",
        },
        .stdout_limit = .limited(1024 * 1024),
        .stderr_limit = .limited(1024 * 1024),
    });
    defer process_result.freeRunResult(allocator, result);
    if (!process_result.termSuccess(result.term)) return error.RegistrationInventoryFailed;
    return parseRegistration(allocator, result.stdout);
}

fn validateExpectedRegistration(snapshot: RegistrationSnapshot) !void {
    if (snapshot.count() != 43 or
        snapshot.repository_tmp_count != 33 or
        snapshot.system_tmp_count != 8 or
        snapshot.other_count != 2 or
        !std.mem.eql(u8, &snapshot.path_hash, expected_path_hash) or
        !std.mem.eql(u8, &snapshot.topology_hash, expected_topology_hash) or
        !std.mem.eql(u8, &snapshot.non_main_hash, expected_non_main_hash))
    {
        return error.UnexpectedRegistrationInventory;
    }
}

test "registration drift is modeled without mutating git" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var actual = try captureRegistration(allocator, io);
    defer actual.deinit(allocator);
    try validateExpectedRegistration(actual);

    const changed = try std.mem.replaceOwned(
        u8,
        allocator,
        actual.raw,
        "worktree /home/oleg/prog/z_llvm\n",
        "worktree /home/oleg/prog/z_llvm-drift\n",
    );
    defer allocator.free(changed);
    var drift = try parseRegistration(allocator, changed);
    defer drift.deinit(allocator);
    try std.testing.expect(!actual.eql(drift));
}
