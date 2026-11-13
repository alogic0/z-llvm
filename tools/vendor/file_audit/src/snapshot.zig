const std = @import("std");
const meta = @import("metadata.zig");
const Io = std.Io;

pub const Options = struct {
    hash_files: bool = false,
    /// Relative paths, including whole subtrees. No glob or basename matching.
    exclude_paths: []const []const u8 = &.{},
    max_entries: usize = 1_000_000,
    max_depth: usize = 128,
};
pub const Entry = struct { path: []const u8, metadata: meta.Metadata, sha256: ?[]const u8 = null };
pub const Totals = struct {
    files: usize = 0,
    directories: usize = 0,
    symlinks: usize = 0,
    other: usize = 0,
    logical_file_bytes: u64 = 0,
    /// Blocks counted once per (device,inode), including directory blocks.
    unique_allocated_bytes: u64 = 0,
    unique_file_inodes: usize = 0,
};
pub const Snapshot = struct {
    schema: u32 = 1,
    root: []const u8,
    options: Options,
    totals: Totals,
    /// Root itself is '.', followed by lexical relative path order.
    entries: []const Entry,
};
pub const OwnedSnapshot = struct {
    arena: std.heap.ArenaAllocator,
    value: Snapshot,
    pub fn deinit(self: *OwnedSnapshot) void {
        self.arena.deinit();
        self.* = undefined;
    }
};

pub fn validRelative(p: []const u8) bool {
    if (p.len == 0 or std.fs.path.isAbsolute(p) or std.mem.indexOfScalar(u8, p, 0) != null) return false;
    var parts = std.mem.splitScalar(u8, p, '/');
    while (parts.next()) |part| if (part.len == 0 or std.mem.eql(u8, part, ".") or std.mem.eql(u8, part, "..")) return false;
    return true;
}
fn within(root: []const u8, p: []const u8) bool {
    return std.mem.eql(u8, root, p) or (p.len > root.len and std.mem.startsWith(u8, p, root) and p[root.len] == '/');
}
fn less(_: void, a: []const u8, b: []const u8) bool {
    return std.mem.lessThan(u8, a, b);
}
fn lessEntry(_: void, a: Entry, b: Entry) bool {
    return std.mem.lessThan(u8, a.path, b.path);
}
const Seen = struct { metadata: meta.Metadata, hash: ?[]const u8 };
const State = struct {
    a: std.mem.Allocator,
    io: Io,
    options: Options,
    entries: std.ArrayList(Entry) = .empty,
    seen: std.AutoHashMap(meta.Identity, Seen),
    totals: Totals = .{},

    fn excluded(s: *const State, p: []const u8) bool {
        for (s.options.exclude_paths) |e| if (within(e, p)) return true;
        return false;
    }
    fn add(s: *State, p: []const u8, m: meta.Metadata, hash: ?[]const u8) !void {
        if (s.entries.items.len >= s.options.max_entries) return error.EntryLimitExceeded;
        const seen = try s.seen.getOrPut(meta.identity(m));
        if (seen.found_existing) {
            if (!seen.value_ptr.metadata.eql(m)) return error.FileChanged;
            if (m.kind == .directory) return error.DirectoryAlias;
        } else {
            seen.value_ptr.* = .{ .metadata = m, .hash = hash };
            s.totals.unique_allocated_bytes = try std.math.add(u64, s.totals.unique_allocated_bytes, m.allocated_bytes);
            if (m.kind == .file) s.totals.unique_file_inodes += 1;
        }
        switch (m.kind) {
            .file => {
                s.totals.files += 1;
                s.totals.logical_file_bytes = try std.math.add(u64, s.totals.logical_file_bytes, m.size);
            },
            .directory => s.totals.directories += 1,
            .symlink => s.totals.symlinks += 1,
            .other => s.totals.other += 1,
        }
        try s.entries.append(s.a, .{ .path = p, .metadata = m, .sha256 = hash });
    }

    fn walk(s: *State, dir: Io.Dir, relative: []const u8, expected: meta.Metadata, depth: usize) anyerror!void {
        if (depth > s.options.max_depth) return error.DepthLimitExceeded;
        if (!expected.eql(try meta.descriptor(dir.handle))) return error.DirectoryChanged;
        try s.add(relative, expected, null);
        var names: std.ArrayList([]const u8) = .empty;
        var iterator = dir.iterate();
        while (try iterator.next(s.io)) |e| {
            if (names.items.len >= s.options.max_entries) return error.EntryLimitExceeded;
            if (!std.unicode.utf8ValidateSlice(e.name)) return error.InvalidUtf8Path;
            try names.append(s.a, try s.a.dupe(u8, e.name));
        }
        std.mem.sort([]const u8, names.items, {}, less);
        for (names.items) |name| {
            const p = if (std.mem.eql(u8, relative, ".")) try s.a.dupe(u8, name) else try std.fs.path.join(s.a, &.{ relative, name });
            if (s.excluded(p)) continue;
            const m = try meta.child(s.a, dir, name);
            if (m.kind == .directory) {
                var child = try dir.openDir(s.io, name, .{ .iterate = true, .follow_symlinks = false });
                defer child.close(s.io);
                try s.walk(child, p, m, depth + 1);
                if (!m.eql(try meta.child(s.a, dir, name))) return error.DirectoryChanged;
            } else {
                var hash: ?[]const u8 = null;
                if (m.kind == .file and s.options.hash_files) {
                    if (s.seen.get(meta.identity(m))) |earlier| {
                        if (!earlier.metadata.eql(m)) return error.FileChanged;
                        hash = earlier.hash;
                    } else hash = try s.a.dupe(u8, &std.fmt.bytesToHex(try meta.hashFile(s.a, s.io, dir, name, m), .lower));
                }
                try s.add(p, m, hash);
            }
        }
        if (!expected.eql(try meta.descriptor(dir.handle))) return error.DirectoryChanged;
    }
};

/// Snapshot a root without following symlinks. Symlinks and special files are
/// recorded, never opened for content. A changed observed entry fails the scan.
/// This is observation with change detection, not an atomic filesystem snapshot.
pub fn scan(allocator: std.mem.Allocator, io: Io, root: []const u8, options: Options) !OwnedSnapshot {
    if (options.max_entries == 0 or options.max_depth > 256) return error.InvalidLimits;
    if (root.len == 0 or !std.unicode.utf8ValidateSlice(root) or std.mem.indexOfScalar(u8, root, 0) != null) return error.InvalidRoot;
    // Do not lexically erase a symlink component followed by '..'.
    var components = std.mem.tokenizeScalar(u8, root, '/');
    while (components.next()) |part| if (std.mem.eql(u8, part, "..")) return error.InvalidRoot;
    var arena = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();
    const a = arena.allocator();
    const cwd = try Io.Dir.cwd().realPathFileAlloc(io, ".", a);
    const absolute = try std.fs.path.resolve(a, &.{ cwd, root });
    const exclusions = try a.alloc([]const u8, options.exclude_paths.len);
    for (options.exclude_paths, 0..) |p, i| {
        if (!validRelative(p) or !std.unicode.utf8ValidateSlice(p)) return error.InvalidExclusion;
        exclusions[i] = try a.dupe(u8, p);
    }
    std.mem.sort([]const u8, exclusions, {}, less);
    var copied_options = options;
    copied_options.exclude_paths = exclusions;
    var dir = try meta.openRoot(io, absolute);
    defer dir.close(io);
    const initial = try meta.descriptor(dir.handle);
    var state: State = .{ .a = a, .io = io, .options = copied_options, .seen = .init(a) };
    try state.walk(dir, ".", initial, 0);
    // Detect a root pathname replacement while its old descriptor was open.
    var current = try meta.openRoot(io, absolute);
    defer current.close(io);
    if (!initial.eql(try meta.descriptor(current.handle))) return error.DirectoryChanged;
    std.mem.sort(Entry, state.entries.items, {}, lessEntry);
    return .{ .arena = arena, .value = .{
        .root = absolute,
        .options = copied_options,
        .totals = state.totals,
        .entries = try state.entries.toOwnedSlice(a),
    } };
}

/// Rescan the full recorded population, including directory membership and
/// exclusions. Preserves exact integer metadata when the caller uses typed JSON.
pub fn verify(allocator: std.mem.Allocator, io: Io, snapshot: Snapshot) !void {
    if (snapshot.schema != 1) return error.UnsupportedSchema;
    if (!std.fs.path.isAbsolute(snapshot.root)) return error.InvalidRoot;
    var current = try scan(allocator, io, snapshot.root, snapshot.options);
    defer current.deinit();
    if (!std.meta.eql(snapshot.totals, current.value.totals) or snapshot.entries.len != current.value.entries.len) return error.SnapshotChanged;
    for (snapshot.entries, current.value.entries) |expected, actual| {
        if (!std.mem.eql(u8, expected.path, actual.path) or !expected.metadata.eql(actual.metadata)) return error.SnapshotChanged;
        if (expected.sha256) |hash| {
            if (actual.sha256 == null or !std.mem.eql(u8, hash, actual.sha256.?)) return error.SnapshotChanged;
        } else if (actual.sha256 != null) return error.SnapshotChanged;
    }
}
