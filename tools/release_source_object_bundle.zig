const std = @import("std");

pub const env_name = "ZLLVM_RELEASE_SOURCE_OBJECT_BUNDLE";
const manifest_name = "manifest.v1";

pub const Row = struct {
    id: []const u8,
    mode: []const u8,
    wrapper: []const u8,
    fixture: []const u8,
};

pub const Publisher = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    root: []const u8,
    target: []const u8,
    entries: std.ArrayList(u8) = .empty,
    rows: usize = 0,
    finished: bool = false,

    pub fn init(
        allocator: std.mem.Allocator,
        io: std.Io,
        root: []const u8,
        target: []const u8,
    ) !Publisher {
        try validateToken(target);
        const objects_dir = try std.fs.path.join(allocator, &.{ root, "objects" });
        defer allocator.free(objects_dir);
        try std.Io.Dir.cwd().createDirPath(io, objects_dir);

        const manifest_path = try std.fs.path.join(allocator, &.{ root, manifest_name });
        defer allocator.free(manifest_path);
        var existing = std.Io.Dir.cwd().openFile(io, manifest_path, .{}) catch |err| switch (err) {
            error.FileNotFound => return .{
                .allocator = allocator,
                .io = io,
                .root = root,
                .target = target,
            },
            else => return err,
        };
        existing.close(io);
        return error.BundleAlreadyPublished;
    }

    pub fn deinit(publisher: *Publisher) void {
        publisher.entries.deinit(publisher.allocator);
        publisher.* = undefined;
    }

    pub fn publish(publisher: *Publisher, row: Row, source_object: []const u8) !void {
        if (publisher.finished) return error.BundleAlreadyPublished;
        try validateRow(row);

        const destination = try objectPath(publisher.allocator, publisher.root, row.id);
        defer publisher.allocator.free(destination);
        try std.Io.Dir.cwd().copyFile(
            source_object,
            std.Io.Dir.cwd(),
            destination,
            publisher.io,
            .{ .make_path = true, .replace = false },
        );

        const identity = try fileIdentity(publisher.allocator, publisher.io, destination);
        const entry = try std.fmt.allocPrint(
            publisher.allocator,
            "row\t{s}\t{s}\t{s}\t{s}\t{}\t{s}\n",
            .{ row.id, row.mode, row.wrapper, row.fixture, identity.size, &identity.sha256 },
        );
        defer publisher.allocator.free(entry);
        try publisher.entries.appendSlice(publisher.allocator, entry);
        publisher.rows += 1;
    }

    pub fn finish(publisher: *Publisher, expected_rows: usize) ![64]u8 {
        if (publisher.finished) return error.BundleAlreadyPublished;
        if (publisher.rows != expected_rows) return error.BundleRowCountMismatch;

        const header = try std.fmt.allocPrint(
            publisher.allocator,
            "schema_version=1\ntarget={s}\nrows={}\n",
            .{ publisher.target, publisher.rows },
        );
        defer publisher.allocator.free(header);

        const manifest_path = try std.fs.path.join(publisher.allocator, &.{ publisher.root, manifest_name });
        defer publisher.allocator.free(manifest_path);
        var atomic_file = try std.Io.Dir.cwd().createFileAtomic(publisher.io, manifest_path, .{
            .make_path = true,
            .replace = false,
        });
        defer atomic_file.deinit(publisher.io);
        var buffer: [4096]u8 = undefined;
        var writer = atomic_file.file.writer(publisher.io, &buffer);
        try writer.interface.writeAll(header);
        try writer.interface.writeAll(publisher.entries.items);
        try writer.interface.flush();
        try atomic_file.link(publisher.io);
        publisher.finished = true;

        return (try fileIdentity(publisher.allocator, publisher.io, manifest_path)).sha256;
    }
};

pub const Consumer = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    root: []const u8,
    manifest: []u8,
    rows: usize,
    manifest_sha256: [64]u8,

    pub fn init(
        allocator: std.mem.Allocator,
        io: std.Io,
        root: []const u8,
        target: []const u8,
        expected_rows: ?usize,
    ) !Consumer {
        const manifest_path = try std.fs.path.join(allocator, &.{ root, manifest_name });
        defer allocator.free(manifest_path);
        const manifest = try std.Io.Dir.cwd().readFileAlloc(io, manifest_path, allocator, .limited(16 * 1024 * 1024));
        errdefer allocator.free(manifest);

        var lines = std.mem.splitScalar(u8, manifest, '\n');
        if (!std.mem.eql(u8, lines.next() orelse return error.InvalidBundleManifest, "schema_version=1")) {
            return error.InvalidBundleManifest;
        }
        const target_line = lines.next() orelse return error.InvalidBundleManifest;
        if (!std.mem.startsWith(u8, target_line, "target=") or
            !std.mem.eql(u8, target_line["target=".len..], target))
        {
            return error.BundleTargetMismatch;
        }
        const rows_line = lines.next() orelse return error.InvalidBundleManifest;
        if (!std.mem.startsWith(u8, rows_line, "rows=")) return error.InvalidBundleManifest;
        const declared_rows = try std.fmt.parseInt(usize, rows_line["rows=".len..], 10);
        if (expected_rows) |expected| {
            if (declared_rows != expected) return error.BundleRowCountMismatch;
        }

        var seen = std.StringHashMap(void).init(allocator);
        defer seen.deinit();
        var actual_rows: usize = 0;
        while (lines.next()) |line| {
            if (line.len == 0) continue;
            const fields = try parseEntry(line);
            const result = try seen.getOrPut(fields.id);
            if (result.found_existing) return error.DuplicateBundleRow;
            actual_rows += 1;
        }
        if (actual_rows != declared_rows) return error.BundleRowCountMismatch;

        return .{
            .allocator = allocator,
            .io = io,
            .root = root,
            .manifest = manifest,
            .rows = declared_rows,
            .manifest_sha256 = sha256(manifest),
        };
    }

    pub fn deinit(consumer: *Consumer) void {
        consumer.allocator.free(consumer.manifest);
        consumer.* = undefined;
    }

    pub fn identity(consumer: *const Consumer) []const u8 {
        return &consumer.manifest_sha256;
    }

    pub fn objectForRow(consumer: *const Consumer, row: Row) ![]const u8 {
        try validateRow(row);
        var lines = std.mem.splitScalar(u8, consumer.manifest, '\n');
        _ = lines.next();
        _ = lines.next();
        _ = lines.next();
        while (lines.next()) |line| {
            if (line.len == 0) continue;
            const fields = try parseEntry(line);
            if (!std.mem.eql(u8, fields.id, row.id)) continue;
            if (!std.mem.eql(u8, fields.mode, row.mode) or
                !std.mem.eql(u8, fields.wrapper, row.wrapper) or
                !std.mem.eql(u8, fields.fixture, row.fixture))
            {
                return error.BundleInputIdentityMismatch;
            }
            const path = try objectPath(consumer.allocator, consumer.root, row.id);
            errdefer consumer.allocator.free(path);
            const object_identity = try fileIdentity(consumer.allocator, consumer.io, path);
            if (object_identity.size != fields.size or !std.mem.eql(u8, &object_identity.sha256, fields.sha256)) {
                return error.BundleObjectIdentityMismatch;
            }
            return path;
        }
        return error.BundleRowMissing;
    }
};

const Entry = struct {
    id: []const u8,
    mode: []const u8,
    wrapper: []const u8,
    fixture: []const u8,
    size: u64,
    sha256: []const u8,
};

const FileIdentity = struct {
    size: u64,
    sha256: [64]u8,
};

fn parseEntry(line: []const u8) !Entry {
    var fields = std.mem.splitScalar(u8, line, '\t');
    if (!std.mem.eql(u8, fields.next() orelse return error.InvalidBundleManifest, "row")) {
        return error.InvalidBundleManifest;
    }
    const id = fields.next() orelse return error.InvalidBundleManifest;
    const mode = fields.next() orelse return error.InvalidBundleManifest;
    const wrapper = fields.next() orelse return error.InvalidBundleManifest;
    const fixture = fields.next() orelse return error.InvalidBundleManifest;
    const size_text = fields.next() orelse return error.InvalidBundleManifest;
    const digest = fields.next() orelse return error.InvalidBundleManifest;
    if (fields.next() != null or digest.len != 64) return error.InvalidBundleManifest;
    return .{
        .id = id,
        .mode = mode,
        .wrapper = wrapper,
        .fixture = fixture,
        .size = try std.fmt.parseInt(u64, size_text, 10),
        .sha256 = digest,
    };
}

fn validateRow(row: Row) !void {
    if (row.id.len == 0) return error.InvalidBundleRow;
    for (row.id) |byte| {
        if (!std.ascii.isAlphanumeric(byte) and byte != '_' and byte != '-' and byte != '.') {
            return error.InvalidBundleRow;
        }
    }
    try validateToken(row.mode);
    try validateToken(row.wrapper);
    try validateToken(row.fixture);
}

fn validateToken(token: []const u8) !void {
    if (token.len == 0 or std.mem.indexOfAny(u8, token, "\t\r\n") != null) {
        return error.InvalidBundleToken;
    }
}

fn objectPath(allocator: std.mem.Allocator, root: []const u8, id: []const u8) ![]const u8 {
    const name = try std.fmt.allocPrint(allocator, "{s}.o", .{id});
    defer allocator.free(name);
    return std.fs.path.join(allocator, &.{ root, "objects", name });
}

fn fileIdentity(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !FileIdentity {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(128 * 1024 * 1024));
    defer allocator.free(contents);
    return .{
        .size = contents.len,
        .sha256 = sha256(contents),
    };
}

fn sha256(contents: []const u8) [64]u8 {
    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(contents, &digest, .{});
    return std.fmt.bytesToHex(digest, .lower);
}

test "bundle publisher and consumer preserve row and content identity" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();

    const root = try std.fs.path.join(allocator, &.{ ".zig-cache", "tmp", &temp.sub_path });
    defer allocator.free(root);
    const object = try std.fs.path.join(allocator, &.{ root, "source.o" });
    defer allocator.free(object);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = object, .data = "object bytes" });

    const row: Row = .{
        .id = "releasefast_example",
        .mode = "ReleaseFast",
        .wrapper = "test/wrapper.zig",
        .fixture = "test/input.zig",
    };
    var publisher = try Publisher.init(allocator, io, root, "x86_64-linux-gnu");
    defer publisher.deinit();
    try publisher.publish(row, object);
    _ = try publisher.finish(1);

    var consumer = try Consumer.init(allocator, io, root, "x86_64-linux-gnu", 1);
    defer consumer.deinit();
    const bundled = try consumer.objectForRow(row);
    defer allocator.free(bundled);
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, bundled, allocator, .limited(1024));
    defer allocator.free(contents);
    try std.testing.expectEqualStrings("object bytes", contents);

    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = bundled, .data = "tampered" });
    try std.testing.expectError(error.BundleObjectIdentityMismatch, consumer.objectForRow(row));
}
