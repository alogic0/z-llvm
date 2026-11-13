const std = @import("std");
pub const storage = @import("zllvm_artifact_store/store.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.skip();
    const command = args.next() orelse "help";
    var buffer: [4096]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(io, &buffer);
    defer stdout.interface.flush() catch {};
    if (std.mem.eql(u8, command, "help") or std.mem.eql(u8, command, "--help")) {
        try stdout.interface.writeAll(
            "Artifact store (ZLLVM_ARTIFACT_STORE, default local-state/artifacts)\n" ++
                "  publish MANIFEST.json SOURCE_DIRECTORY\n" ++
                "  pin MANIFEST.json (objects already present)\n" ++
                "  verify\n" ++
                "  gc [--delete] [--pins DIRECTORY]\n" ++
                "  get SHA256 OUTPUT_FILE\n" ++
                "  link SHA256 NEW_INPUT_FILE (shared read-only content)\n" ++
                "All manifests pin their objects. Keep accepted manifests in Git as well.\n",
        );
        return;
    }
    const root = init.minimal.environ.getAlloc(allocator, "ZLLVM_ARTIFACT_STORE") catch |err| switch (err) {
        error.EnvironmentVariableMissing => try allocator.dupe(u8, "local-state/artifacts"),
        else => return err,
    };
    defer allocator.free(root);
    if (std.mem.eql(u8, command, "publish") or std.mem.eql(u8, command, "pin")) {
        const publish = std.mem.eql(u8, command, "publish");
        const manifest_path = args.next() orelse return error.MissingManifest;
        const source_root = if (publish) args.next() orelse return error.MissingSource else null;
        if (args.next() != null) return error.UnknownOption;
        const bytes = try storage.readFile(allocator, io, .cwd(), manifest_path);
        defer allocator.free(bytes);
        // Reject malformed requests before creating state.
        const parsed = try storage.parse(allocator, bytes);
        parsed.deinit();
        var store = try storage.Store.open(allocator, io, root, true);
        defer store.deinit();
        if (source_root) |source| try store.publish(bytes, source) else try store.publishManifest(bytes);
        try stdout.interface.print("artifact-store {s} ok\n", .{command});
        return;
    }
    if (!std.mem.eql(u8, command, "verify") and !std.mem.eql(u8, command, "gc") and !std.mem.eql(u8, command, "get") and !std.mem.eql(u8, command, "link")) return error.UnknownCommand;
    var store = try storage.Store.open(allocator, io, root, false);
    defer store.deinit();
    if (std.mem.eql(u8, command, "verify")) {
        if (args.next() != null) return error.UnknownOption;
        try stdout.interface.print("artifact-store verify manifests={} ok\n", .{try store.verify()});
    } else if (std.mem.eql(u8, command, "gc")) {
        var apply = false;
        var pins_path: ?[]const u8 = null;
        while (args.next()) |flag| {
            if (std.mem.eql(u8, flag, "--delete") and !apply) {
                apply = true;
            } else if (std.mem.eql(u8, flag, "--pins") and pins_path == null) {
                pins_path = args.next() orelse return error.MissingPinsDirectory;
            } else return error.UnknownOption;
        }
        const pins = if (pins_path) |path| try storage.openDirectory(io, path, false) else null;
        defer if (pins) |dir| dir.close(io);
        const result = try store.collectWithPins(apply, pins);
        try stdout.interface.print("artifact-store gc files={} bytes={} deleted={}\n", .{ result.files, result.bytes, result.deleted });
    } else {
        const hash = args.next() orelse return error.MissingHash;
        const destination = args.next() orelse return error.MissingDestination;
        if (args.next() != null) return error.UnknownOption;
        try storage.validHash(hash);
        if (std.mem.eql(u8, command, "link")) {
            try store.linkInput(hash, destination);
            try stdout.interface.writeAll("artifact-store link ok\n");
            return;
        }
        const file = try store.objects.openFile(io, hash, .{ .follow_symlinks = false, .allow_directory = false });
        defer file.close(io);
        const identity = try storage.hashFile(io, file);
        if (!std.mem.eql(u8, &identity.hash, hash)) return error.ContentMismatch;
        var parent = try storage.openDirectory(io, std.fs.path.dirname(destination) orelse ".", false);
        defer parent.close(io);
        const name = std.fs.path.basename(destination);
        try storage.validPath(name);
        var atomic = try parent.createFileAtomic(io, name, .{ .replace = false });
        defer atomic.deinit(io);
        var chunk: [65536]u8 = undefined;
        var offset: u64 = 0;
        while (true) {
            const n = try file.readPositional(io, &.{&chunk}, offset);
            if (n == 0) break;
            try atomic.file.writeStreamingAll(io, chunk[0..n]);
            offset += n;
        }
        const copied = try storage.hashFile(io, atomic.file);
        if (!std.mem.eql(u8, &copied.hash, hash)) return error.ContentMismatch;
        try atomic.file.sync(io);
        try atomic.link(io);
        try storage.syncDir(parent);
        try stdout.interface.writeAll("artifact-store get ok\n");
    }
}

test {
    _ = @import("zllvm_artifact_store/tests.zig");
}
