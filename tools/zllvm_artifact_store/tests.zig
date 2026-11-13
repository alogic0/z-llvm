const std = @import("std");
const storage = @import("store.zig");
const allocator = std.testing.allocator;
const io = std.testing.io;
const hello_sha = "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824";
const hello = storage.Artifact{ .name = "input.txt", .sha256 = hello_sha, .bytes = 5 };

fn manifest(artifacts: []const storage.Artifact) ![]u8 {
    return std.json.Stringify.valueAlloc(allocator, storage.Manifest{
        .schema = 1,
        .run_id = "test-run",
        .command = &.{ "zig", "test" },
        .source_revision = "test",
        .compiler = "0.17.0",
        .result = "passed",
        .artifacts = artifacts,
    }, .{});
}
fn tempPath(tmp: std.testing.TmpDir, buffer: []u8) ![]const u8 {
    return buffer[0..try tmp.dir.realPath(io, buffer)];
}

test "shared input installation preserves names, permissions and GC references" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var buffer: [4096]u8 = undefined;
    const path = try tempPath(tmp, &buffer);
    try tmp.dir.writeFile(io, .{ .sub_path = "source", .data = "hello" });
    var store = try storage.Store.open(allocator, io, path, true);
    defer store.deinit();
    const file = try tmp.dir.openFile(io, "source", .{});
    defer file.close(io);
    try store.publishFile(file, hello);
    const destination = try std.fmt.allocPrint(allocator, "{s}/shared.ll", .{path});
    defer allocator.free(destination);
    try store.linkInput(hello_sha, destination);
    const object = try store.objects.statFile(io, hello_sha, .{});
    const shared = try tmp.dir.statFile(io, "shared.ll", .{});
    try std.testing.expectEqual(object.inode, shared.inode);
    try std.testing.expectEqual(@as(u32, 0o444), shared.permissions.toMode() & 0o7777);
    try std.testing.expectError(error.PathAlreadyExists, store.linkInput(hello_sha, destination));
    try std.testing.expectEqual(@as(usize, 0), (try store.collect(true)).files);
    try tmp.dir.deleteFile(io, "shared.ll");
    try std.testing.expectEqual(@as(usize, 1), (try store.collect(true)).files);
}

test "shared input refuses a writable or corrupt store object" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var buffer: [4096]u8 = undefined;
    const path = try tempPath(tmp, &buffer);
    var store = try storage.Store.open(allocator, io, path, true);
    defer store.deinit();
    try store.objects.writeFile(io, .{ .sub_path = hello_sha, .data = "hello" });
    const destination = try std.fmt.allocPrint(allocator, "{s}/shared.ll", .{path});
    defer allocator.free(destination);
    try std.testing.expectError(error.WritableSharedObject, store.linkInput(hello_sha, destination));
    const file = try store.objects.openFile(io, hello_sha, .{ .mode = .read_write });
    defer file.close(io);
    try file.writeStreamingAll(io, "wrong");
    try file.setPermissions(io, .fromMode(0o444));
    try std.testing.expectError(error.ContentMismatch, store.linkInput(hello_sha, destination));
}

test "manifest rejects ambiguity unsafe paths unknown fields and conflicting sizes" {
    const bytes = try manifest(&.{hello});
    defer allocator.free(bytes);
    const good = try storage.parse(allocator, bytes);
    good.deinit();
    const duplicates = try manifest(&.{ hello, hello });
    defer allocator.free(duplicates);
    try std.testing.expectError(error.DuplicateArtifact, storage.parse(allocator, duplicates));
    const bad_cases = [_][2][]const u8{
        .{ "\"schema\":1", "\"schema\":1,\"schema\":1" },
        .{ "\"schema\":1", "\"schema\":2" },
        .{ "\"schema\":1", "\"schema\":\"1\"" },
        .{ "\"schema\":1", "\"schema\":1.0" },
        .{ "\"bytes\":5", "\"bytes\":\"5\"" },
        .{ "\"bytes\":5", "\"bytes\":5e0" },
        .{ "\"bytes\":5", "\"bytes\":-1" },
        .{ "\"schema\":1", "\"schema\":1,\"unknown\":1" },
        .{ "input.txt", "../escape" },
        .{ "input.txt", "/absolute" },
        .{ "input.txt", "a//b" },
        .{ "test-run", "../run" },
        .{ hello_sha, "abc" },
    };
    for (bad_cases) |pair| {
        const bad = try std.mem.replaceOwned(u8, allocator, bytes, pair[0], pair[1]);
        defer allocator.free(bad);
        if (storage.parse(allocator, bad)) |parsed| {
            parsed.deinit();
            return error.InvalidManifestAccepted;
        } else |_| {}
    }
}

test "publish verifies content reuses objects and never replaces conflicting manifests" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var path_buffer: [4096]u8 = undefined;
    const path = try tempPath(tmp, &path_buffer);
    try tmp.dir.writeFile(io, .{ .sub_path = "input.txt", .data = "hello" });
    var store = try storage.Store.open(allocator, io, path, true);
    defer store.deinit();
    const bytes = try manifest(&.{hello});
    defer allocator.free(bytes);
    try store.publish(bytes, path);
    try store.publish(bytes, path);
    try std.testing.expectEqual(@as(usize, 1), try store.verify());
    try std.testing.expectEqual(@as(usize, 0), (try store.collect(false)).files);
    const changed = try std.mem.replaceOwned(u8, allocator, bytes, "passed", "failed");
    defer allocator.free(changed);
    try std.testing.expectError(error.ManifestAlreadyExists, store.publishManifest(changed));
    try tmp.dir.writeFile(io, .{ .sub_path = "input.txt", .data = "wrong" });
    try std.testing.expectError(error.ContentMismatch, store.publish(bytes, path));
    try store.verifyObject(hello);
}

test "missing objects never publish a manifest and GC collects interrupted publication" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var path_buffer: [4096]u8 = undefined;
    const path = try tempPath(tmp, &path_buffer);
    var store = try storage.Store.open(allocator, io, path, true);
    defer store.deinit();
    const bytes = try manifest(&.{hello});
    defer allocator.free(bytes);
    try std.testing.expectError(error.FileNotFound, store.publishManifest(bytes));
    try tmp.dir.writeFile(io, .{ .sub_path = "source", .data = "hello" });
    const file = try tmp.dir.openFile(io, "source", .{});
    defer file.close(io);
    try store.publishFile(file, hello);
    try store.incoming.writeFile(io, .{ .sub_path = "abandoned", .data = "partial" });
    const preview = try store.collect(false);
    try std.testing.expectEqual(@as(usize, 2), preview.files);
    try std.testing.expectEqual(@as(u64, 12), preview.bytes);
    try store.verifyObject(hello);
    const deleted = try store.collect(true);
    try std.testing.expectEqual(preview.files, deleted.files);
    try std.testing.expectEqual(@as(usize, 0), (try store.collect(false)).files);
}

test "invalid manifest and corrupt pinned objects prevent every GC deletion" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var buffer: [4096]u8 = undefined;
    const path = try tempPath(tmp, &buffer);
    try tmp.dir.writeFile(io, .{ .sub_path = "input.txt", .data = "hello" });
    var store = try storage.Store.open(allocator, io, path, true);
    defer store.deinit();
    const bytes = try manifest(&.{hello});
    defer allocator.free(bytes);
    try store.publish(bytes, path);
    try store.incoming.writeFile(io, .{ .sub_path = "keep-on-failure", .data = "data" });
    try store.manifests.writeFile(io, .{ .sub_path = "bad.json", .data = "{}" });
    if (store.collect(true)) |_| return error.InvalidManifestAccepted else |_| {}
    try store.manifests.deleteFile(io, "bad.json");
    try store.objects.setFilePermissions(io, hello_sha, .fromMode(0o600), .{ .follow_symlinks = false });
    try store.objects.writeFile(io, .{ .sub_path = hello_sha, .data = "wrong" });
    try std.testing.expectError(error.ContentMismatch, store.collect(true));
    try std.testing.expectError(error.ContentMismatch, store.publish(bytes, path));
    const retained = try storage.readFile(allocator, io, store.incoming, "keep-on-failure");
    defer allocator.free(retained);
    try std.testing.expectEqualStrings("data", retained);
}

test "store lock excludes a second publisher or collector" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var buffer: [4096]u8 = undefined;
    const path = try tempPath(tmp, &buffer);
    var first = try storage.Store.open(allocator, io, path, true);
    try std.testing.expectError(error.WouldBlock, storage.Store.open(allocator, io, path, false));
    first.deinit();
    var second = try storage.Store.open(allocator, io, path, false);
    second.deinit();
}

test "source directory symlinks and store symlinks cannot escape" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var buffer: [4096]u8 = undefined;
    const path = try tempPath(tmp, &buffer);
    try tmp.dir.writeFile(io, .{ .sub_path = "outside", .data = "hello" });
    try tmp.dir.symLink(io, "outside", "input.txt", .{});
    var store = try storage.Store.open(allocator, io, path, true);
    defer store.deinit();
    const bytes = try manifest(&.{hello});
    defer allocator.free(bytes);
    if (store.publish(bytes, path)) |_| return error.SymlinkAccepted else |_| {}
    try store.objects.symLink(io, "../outside", hello_sha, .{});
    if (store.collect(true)) |_| return error.SymlinkAccepted else |_| {}
    const outside = try storage.readFile(allocator, io, tmp.dir, "outside");
    defer allocator.free(outside);
    try std.testing.expectEqualStrings("hello", outside);
}

test "versioned pins survive a missing local manifest and fail closed on missing content" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var buffer: [4096]u8 = undefined;
    const path = try tempPath(tmp, &buffer);
    try tmp.dir.writeFile(io, .{ .sub_path = "input.txt", .data = "hello" });
    try tmp.dir.createDir(io, "pins", .default_dir);
    const pins = try tmp.dir.openDir(io, "pins", .{ .iterate = true });
    defer pins.close(io);
    var store = try storage.Store.open(allocator, io, path, true);
    defer store.deinit();
    const bytes = try manifest(&.{hello});
    defer allocator.free(bytes);
    try store.publish(bytes, path);
    try pins.writeFile(io, .{ .sub_path = "test-run.json", .data = bytes });
    try store.manifests.deleteFile(io, "test-run.json");
    try std.testing.expectEqual(@as(usize, 0), (try store.collectWithPins(true, pins)).files);
    try store.verifyObject(hello);
    try store.objects.deleteFile(io, hello_sha);
    try store.incoming.writeFile(io, .{ .sub_path = "retain", .data = "partial" });
    try std.testing.expectError(error.FileNotFound, store.collectWithPins(true, pins));
    const retained = try storage.readFile(allocator, io, store.incoming, "retain");
    defer allocator.free(retained);
    try std.testing.expectEqualStrings("partial", retained);
}

test "publication rejects intermediate directory symlinks and size mismatches" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    var buffer: [4096]u8 = undefined;
    const path = try tempPath(tmp, &buffer);
    try tmp.dir.createDir(io, "source", .default_dir);
    try tmp.dir.writeFile(io, .{ .sub_path = "source/input.txt", .data = "hello" });
    try tmp.dir.symLink(io, "source", "alias", .{ .is_directory = true });
    var store = try storage.Store.open(allocator, io, path, true);
    defer store.deinit();
    var nested = hello;
    nested.name = "alias/input.txt";
    const bytes = try manifest(&.{nested});
    defer allocator.free(bytes);
    if (store.publish(bytes, path)) |_| return error.SymlinkAccepted else |_| {}
    nested.name = "source/input.txt";
    nested.bytes = 6;
    const wrong_size = try manifest(&.{nested});
    defer allocator.free(wrong_size);
    try std.testing.expectError(error.ContentMismatch, store.publish(wrong_size, path));
    try std.testing.expectEqual(@as(usize, 0), try store.verify());
}
