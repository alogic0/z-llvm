const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const Sha256 = std.crypto.hash.sha2.Sha256;

pub const Artifact = struct { name: []const u8, sha256: []const u8, bytes: u64 };
pub const Input = struct { name: []const u8, identity: []const u8 };
pub const Manifest = struct {
    schema: u32,
    run_id: []const u8,
    command: []const []const u8,
    source_revision: []const u8,
    compiler: []const u8,
    inputs: []const Input = &.{},
    result: []const u8,
    artifacts: []const Artifact,
};
pub const manifest_limit = 16 * 1024 * 1024;
pub const Collection = struct { files: usize = 0, bytes: u64 = 0, deleted: bool = false };

pub fn validName(name: []const u8) !void {
    if (name.len == 0 or name.len > 160 or std.mem.eql(u8, name, ".") or std.mem.eql(u8, name, "..")) return error.InvalidName;
    for (name) |c| if (!std.ascii.isAlphanumeric(c) and c != '-' and c != '_' and c != '.') return error.InvalidName;
}

pub fn validHash(hash: []const u8) !void {
    if (hash.len != 64) return error.InvalidHash;
    for (hash) |c| if (!std.ascii.isDigit(c) and !(c >= 'a' and c <= 'f')) return error.InvalidHash;
}

pub fn validPath(path: []const u8) !void {
    if (std.fs.path.isAbsolute(path) or std.mem.indexOfScalar(u8, path, 0) != null or std.mem.indexOfScalar(u8, path, '\\') != null) return error.UnsafePath;
    var parts = std.mem.splitScalar(u8, path, '/');
    while (parts.next()) |part| if (part.len == 0 or std.mem.eql(u8, part, ".") or std.mem.eql(u8, part, "..")) return error.UnsafePath;
}

pub fn parse(allocator: Allocator, bytes: []const u8) !std.json.Parsed(Manifest) {
    if (bytes.len > manifest_limit) return error.ManifestTooLarge;
    // Zig's typed JSON parser also accepts numbers encoded as strings and
    // integral floats. The manifest contract requires unsigned JSON integers.
    const json = try std.json.parseFromSlice(std.json.Value, allocator, bytes, .{ .parse_numbers = false });
    defer json.deinit();
    if (json.value != .object) return error.InvalidManifest;
    try unsignedJson(json.value.object.get("schema") orelse return error.InvalidManifest);
    const artifacts = json.value.object.get("artifacts") orelse return error.InvalidManifest;
    if (artifacts != .array) return error.InvalidManifest;
    for (artifacts.array.items) |artifact| {
        if (artifact != .object) return error.InvalidManifest;
        try unsignedJson(artifact.object.get("bytes") orelse return error.InvalidManifest);
    }
    const parsed = try std.json.parseFromSlice(Manifest, allocator, bytes, .{ .allocate = .alloc_always });
    errdefer parsed.deinit();
    const m = parsed.value;
    if (m.schema != 1 or m.command.len == 0 or m.source_revision.len == 0 or m.compiler.len == 0 or m.result.len == 0) return error.InvalidManifest;
    try validName(m.run_id);
    for (m.command) |arg| if (std.mem.indexOfScalar(u8, arg, 0) != null) return error.InvalidManifest;
    if (m.command[0].len == 0) return error.InvalidManifest;
    for (m.inputs, 0..) |input, i| {
        try validName(input.name);
        if (input.identity.len == 0) return error.InvalidManifest;
        for (m.inputs[0..i]) |previous| if (std.mem.eql(u8, previous.name, input.name)) return error.DuplicateInput;
    }
    var names = std.StringHashMap(void).init(allocator);
    defer names.deinit();
    var sizes = std.StringHashMap(u64).init(allocator);
    defer sizes.deinit();
    for (m.artifacts) |artifact| {
        try validPath(artifact.name);
        try validHash(artifact.sha256);
        if ((try names.getOrPut(artifact.name)).found_existing) return error.DuplicateArtifact;
        const size = try sizes.getOrPut(artifact.sha256);
        if (size.found_existing and size.value_ptr.* != artifact.bytes) return error.ConflictingSize;
        size.value_ptr.* = artifact.bytes;
    }
    return parsed;
}

fn unsignedJson(value: std.json.Value) !void {
    if (value != .number_string) return error.InvalidManifestNumber;
    const number = value.number_string;
    if (number.len == 0 or (number.len > 1 and number[0] == '0')) return error.InvalidManifestNumber;
    for (number) |c| if (!std.ascii.isDigit(c)) return error.InvalidManifestNumber;
    _ = std.fmt.parseInt(u64, number, 10) catch return error.InvalidManifestNumber;
}

pub fn syncDir(dir: Io.Dir) !void {
    switch (std.os.linux.errno(std.os.linux.fsync(dir.handle))) {
        .SUCCESS => {},
        else => |err| return std.posix.unexpectedErrno(err),
    }
}

/// Resolve each component with no-follow opens. Relative roots are cwd-relative.
pub fn openDirectory(io: Io, path: []const u8, create: bool) !Io.Dir {
    const absolute = std.fs.path.isAbsolute(path);
    var current = try Io.Dir.cwd().openDir(io, if (absolute) "/" else ".", .{ .iterate = true });
    errdefer current.close(io);
    if (std.mem.eql(u8, path, ".") or std.mem.eql(u8, path, "/")) return current;
    const relative = if (absolute) path[1..] else path;
    try validPath(relative);
    var parts = std.mem.splitScalar(u8, relative, '/');
    while (parts.next()) |part| {
        const next = try childDir(io, current, part, create);
        current.close(io);
        current = next;
    }
    return current;
}

fn childDir(io: Io, parent: Io.Dir, name: []const u8, create: bool) !Io.Dir {
    if (create) parent.createDir(io, name, .default_dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    const dir = try parent.openDir(io, name, .{ .iterate = true, .follow_symlinks = false });
    errdefer dir.close(io);
    if (create) try syncDir(parent);
    return dir;
}

pub fn readFile(allocator: Allocator, io: Io, dir: Io.Dir, name: []const u8) ![]u8 {
    var file = try dir.openFile(io, name, .{ .follow_symlinks = false, .allow_directory = false });
    defer file.close(io);
    const stat = try file.stat(io);
    if (stat.kind != .file or stat.size > manifest_limit) return error.InvalidManifestFile;
    const bytes = try allocator.alloc(u8, @intCast(stat.size));
    errdefer allocator.free(bytes);
    var offset: usize = 0;
    while (offset < bytes.len) {
        const n = try file.readPositional(io, &.{bytes[offset..]}, offset);
        if (n == 0) return error.FileChanged;
        offset += n;
    }
    if ((try file.stat(io)).size != stat.size) return error.FileChanged;
    return bytes;
}

pub fn hashFile(io: Io, file: Io.File) !struct { hash: [64]u8, bytes: u64 } {
    const before = try file.stat(io);
    if (before.kind != .file) return error.NotRegularFile;
    var hasher = Sha256.init(.{});
    var buffer: [64 * 1024]u8 = undefined;
    var offset: u64 = 0;
    while (true) {
        const n = try file.readPositional(io, &.{&buffer}, offset);
        if (n == 0) break;
        hasher.update(buffer[0..n]);
        offset += n;
    }
    const after = try file.stat(io);
    if (before.size != offset or after.size != offset or !std.meta.eql(before.mtime, after.mtime)) return error.FileChanged;
    return .{ .hash = std.fmt.bytesToHex(hasher.finalResult(), .lower), .bytes = offset };
}

fn verifyFile(io: Io, file: Io.File, artifact: Artifact) !void {
    const actual = try hashFile(io, file);
    if (actual.bytes != artifact.bytes or !std.mem.eql(u8, &actual.hash, artifact.sha256)) return error.ContentMismatch;
}

pub const Store = struct {
    allocator: Allocator,
    io: Io,
    root: Io.Dir,
    objects: Io.Dir,
    manifests: Io.Dir,
    incoming: Io.Dir,
    lock: Io.File,

    /// The lock covers the entire operation, including source reads and GC.
    pub fn open(allocator: Allocator, io: Io, path: []const u8, create: bool) !Store {
        return openWithLock(allocator, io, path, create, true);
    }
    pub fn openWaiting(allocator: Allocator, io: Io, path: []const u8, create: bool) !Store {
        return openWithLock(allocator, io, path, create, false);
    }
    fn openWithLock(allocator: Allocator, io: Io, path: []const u8, create: bool, nonblocking: bool) !Store {
        const root = try openDirectory(io, path, create);
        errdefer root.close(io);
        if (create) {
            const created = root.createFile(io, "store.lock", .{ .exclusive = true }) catch |err| switch (err) {
                error.PathAlreadyExists => null,
                else => return err,
            };
            if (created) |file| file.close(io);
        }
        const lock = try root.openFile(io, "store.lock", .{ .mode = .read_write, .follow_symlinks = false, .allow_directory = false, .lock = .exclusive, .lock_nonblocking = nonblocking });
        errdefer lock.close(io);
        if ((try lock.stat(io)).kind != .file) return error.InvalidLock;
        const objects = try childDir(io, root, "objects", create);
        errdefer objects.close(io);
        const manifests = try childDir(io, root, "manifests", create);
        errdefer manifests.close(io);
        const incoming = try childDir(io, root, "incoming", create);
        errdefer incoming.close(io);
        return .{ .allocator = allocator, .io = io, .root = root, .objects = objects, .manifests = manifests, .incoming = incoming, .lock = lock };
    }

    pub fn deinit(self: *Store) void {
        self.incoming.close(self.io);
        self.manifests.close(self.io);
        self.objects.close(self.io);
        self.lock.close(self.io);
        self.root.close(self.io);
        self.* = undefined;
    }

    pub fn verifyObject(self: *Store, artifact: Artifact) !void {
        try validHash(artifact.sha256);
        const file = try self.objects.openFile(self.io, artifact.sha256, .{ .follow_symlinks = false, .allow_directory = false });
        defer file.close(self.io);
        try verifyFile(self.io, file, artifact);
    }

    pub fn publishFile(self: *Store, source: Io.File, artifact: Artifact) !void {
        try validHash(artifact.sha256);
        if (self.verifyObject(artifact)) |_| {
            // Existing immutable content needs no second temporary payload.
            try verifyFile(self.io, source, artifact);
            return;
        } else |err| if (err != error.FileNotFound) return err;
        // Named temporary files on filesystems without O_TMPFILE must remain
        // collectible after a crash; never leave them among objects/manifests.
        var atomic = try self.incoming.createFileAtomic(self.io, artifact.sha256, .{ .replace = false, .permissions = .fromMode(0o600) });
        defer atomic.deinit(self.io);
        var buffer: [64 * 1024]u8 = undefined;
        var offset: u64 = 0;
        while (true) {
            const n = try source.readPositional(self.io, &.{&buffer}, offset);
            if (n == 0) break;
            try atomic.file.writeStreamingAll(self.io, buffer[0..n]);
            offset += n;
        }
        try verifyFile(self.io, atomic.file, artifact);
        try atomic.file.setPermissions(self.io, .fromMode(0o444));
        try atomic.file.sync(self.io);
        atomic.file.hardLink(self.io, self.objects, artifact.sha256, .{}) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };
        try syncDir(self.objects);
        try self.verifyObject(artifact);
    }

    /// Install a new immutable input name, never replacing an existing file.
    /// Consumers that need to modify content must request an independent copy.
    pub fn linkInput(self: *Store, hash: []const u8, destination: []const u8) !void {
        try validHash(hash);
        const file = try self.objects.openFile(self.io, hash, .{ .follow_symlinks = false, .allow_directory = false });
        defer file.close(self.io);
        const before = try file.stat(self.io);
        if (before.kind != .file or before.permissions.toMode() & 0o222 != 0) return error.WritableSharedObject;
        const actual = try hashFile(self.io, file);
        if (!std.mem.eql(u8, &actual.hash, hash)) return error.ContentMismatch;
        var parent = try openDirectory(self.io, std.fs.path.dirname(destination) orelse ".", false);
        defer parent.close(self.io);
        const name = std.fs.path.basename(destination);
        try validPath(name);
        try file.hardLink(self.io, parent, name, .{});
        try syncDir(parent);
    }

    /// All objects must exist before the immutable run manifest is published.
    pub fn publishManifest(self: *Store, bytes: []const u8) !void {
        const parsed = try parse(self.allocator, bytes);
        defer parsed.deinit();
        for (parsed.value.artifacts) |artifact| try self.verifyObject(artifact);
        const canonical = try std.json.Stringify.valueAlloc(self.allocator, parsed.value, .{ .whitespace = .indent_2 });
        defer self.allocator.free(canonical);
        const name = try std.fmt.allocPrint(self.allocator, "{s}.json", .{parsed.value.run_id});
        defer self.allocator.free(name);
        var atomic = try self.incoming.createFileAtomic(self.io, name, .{ .replace = false });
        defer atomic.deinit(self.io);
        try atomic.file.writeStreamingAll(self.io, canonical);
        try atomic.file.sync(self.io);
        atomic.file.hardLink(self.io, self.manifests, name, .{}) catch |err| switch (err) {
            error.PathAlreadyExists => {
                const existing = try readFile(self.allocator, self.io, self.manifests, name);
                defer self.allocator.free(existing);
                const previous = try parse(self.allocator, existing);
                defer previous.deinit();
                const normalized = try std.json.Stringify.valueAlloc(self.allocator, previous.value, .{ .whitespace = .indent_2 });
                defer self.allocator.free(normalized);
                if (!std.mem.eql(u8, normalized, canonical)) return error.ManifestAlreadyExists;
            },
            else => return err,
        };
        try syncDir(self.manifests);
    }

    pub fn publish(self: *Store, bytes: []const u8, source_root: []const u8) !void {
        const parsed = try parse(self.allocator, bytes);
        defer parsed.deinit();
        const source = try openDirectory(self.io, source_root, false);
        defer source.close(self.io);
        for (parsed.value.artifacts) |artifact| {
            var parent = try source.openDir(self.io, ".", .{ .iterate = true });
            defer parent.close(self.io);
            var parts = std.mem.splitScalar(u8, artifact.name, '/');
            var component = parts.next().?;
            while (parts.next()) |next| {
                const child = try childDir(self.io, parent, component, false);
                parent.close(self.io);
                parent = child;
                component = next;
            }
            const file = try parent.openFile(self.io, component, .{ .follow_symlinks = false, .allow_directory = false });
            defer file.close(self.io);
            if ((try file.stat(self.io)).kind != .file) return error.NotRegularFile;
            try self.publishFile(file, artifact);
        }
        try self.publishManifest(bytes);
    }

    pub fn verify(self: *Store) !usize {
        var iterator = self.manifests.iterate();
        var count: usize = 0;
        while (try iterator.next(self.io)) |entry| {
            if (entry.kind != .file or !std.mem.endsWith(u8, entry.name, ".json")) return error.InvalidManifestFile;
            const bytes = try readFile(self.allocator, self.io, self.manifests, entry.name);
            defer self.allocator.free(bytes);
            const parsed = try parse(self.allocator, bytes);
            defer parsed.deinit();
            if (!std.mem.eql(u8, entry.name[0 .. entry.name.len - 5], parsed.value.run_id)) return error.ManifestNameMismatch;
            for (parsed.value.artifacts) |artifact| try self.verifyObject(artifact);
            count += 1;
        }
        return count;
    }

    /// Every retained local manifest is a pin. Removing a manifest unpins its run.
    /// Validate the entire plan before deleting anything, including unknown entries.
    pub fn collect(self: *Store, apply: bool) !Collection {
        return self.collectWithPins(apply, null);
    }

    /// An explicitly opened directory of versioned manifests also pins objects,
    /// even when a local run manifest was accidentally removed. Non-JSON files
    /// in the evidence directory are documentation, not manifests.
    pub fn collectWithPins(self: *Store, apply: bool, pins: ?Io.Dir) !Collection {
        _ = try self.verify();
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        var live: std.StringHashMap(void) = .init(allocator);
        var iterator = self.manifests.iterate();
        while (try iterator.next(self.io)) |entry| {
            const bytes = try readFile(allocator, self.io, self.manifests, entry.name);
            const parsed = try parse(allocator, bytes);
            for (parsed.value.artifacts) |artifact| try live.put(artifact.sha256, {});
        }
        if (pins) |dir| {
            var entries = dir.iterate();
            while (try entries.next(self.io)) |entry| {
                if (!std.mem.endsWith(u8, entry.name, ".json")) continue;
                if (entry.kind != .file) return error.InvalidManifestFile;
                const bytes = try readFile(allocator, self.io, dir, entry.name);
                const parsed = try parse(allocator, bytes);
                if (!std.mem.eql(u8, entry.name[0 .. entry.name.len - 5], parsed.value.run_id)) return error.ManifestNameMismatch;
                for (parsed.value.artifacts) |artifact| {
                    try self.verifyObject(artifact);
                    try live.put(artifact.sha256, {});
                }
            }
        }
        const Candidate = struct { dir: Io.Dir, name: []const u8, bytes: u64 };
        var candidates: std.ArrayList(Candidate) = .empty;
        var result: Collection = .{ .deleted = apply };
        for ([_]Io.Dir{ self.objects, self.incoming }, 0..) |dir, index| {
            var entries = dir.iterate();
            while (try entries.next(self.io)) |entry| {
                if (entry.kind != .file) return error.UnsafeStoreEntry;
                if (index == 0) {
                    try validHash(entry.name);
                    if (live.contains(entry.name)) continue;
                }
                const stat = try dir.statFile(self.io, entry.name, .{ .follow_symlinks = false });
                // Installed input aliases are live references even without a
                // run manifest. Unlinking the store name would reclaim no data.
                if (index == 0 and stat.nlink > 1) continue;
                try candidates.append(allocator, .{ .dir = dir, .name = try allocator.dupe(u8, entry.name), .bytes = stat.size });
                result.files += 1;
                result.bytes += stat.size;
            }
        }
        if (apply) {
            for (candidates.items) |candidate| try candidate.dir.deleteFile(self.io, candidate.name);
            try syncDir(self.objects);
            try syncDir(self.incoming);
        }
        return result;
    }
};
