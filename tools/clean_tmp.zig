const std = @import("std");
const common = @import("tool_common.zig");

const default_tmp_dir = "tmp";
const default_pin_file = "docs/evidence/ziglang_pin.txt";
const default_max_age_seconds = 2 * 60 * 60;
const export_cache_name = "real_rows_air_export_cache";

const usage =
    \\usage: zig build clean-tmp -- [--delete] [--tmp-dir=PATH] [--pin-file=PATH] [--older-than-seconds=N]
    \\
    \\Dry-run is the default. --delete is required to remove stale tmp files.
    \\
;

const Options = struct {
    delete: bool = false,
    tmp_dir: []const u8 = default_tmp_dir,
    pin_file: []const u8 = default_pin_file,
    older_than_seconds: u64 = default_max_age_seconds,
};

const Totals = struct {
    candidates: usize = 0,
    deleted: usize = 0,
    bytes_reclaimable: u64 = 0,
    bytes_deleted: u64 = 0,
    old_pin_cache_pairs: usize = 0,
    scratch_dirs: usize = 0,
    cache_pairs_kept: usize = 0,
    scratch_dirs_skipped: usize = 0,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const options = try parseOptions(allocator, io, init);
    const current_pin = try readPin(allocator, io, options.pin_file);
    defer allocator.free(current_pin);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.print(
        "clean-tmp tmp_dir={s} pin_file={s} current_pin={s} delete={} older_than_seconds={}\n",
        .{ options.tmp_dir, options.pin_file, current_pin, options.delete, options.older_than_seconds },
    );

    var cwd = std.Io.Dir.cwd();
    cwd.createDirPath(io, options.tmp_dir) catch |err| switch (err) {
        error.AccessDenied, error.PermissionDenied => return err,
        else => {},
    };

    var totals: Totals = .{};
    try scanExportCache(allocator, io, options, current_pin, stdout, &totals);
    try scanScratchDirs(allocator, io, options, stdout, &totals);

    try stdout.print(
        "summary clean-tmp mode={s} tmp_dir={s} old_pin_cache_pairs={} scratch_dirs={} candidates={} deleted={} bytes_reclaimable={} bytes_deleted={} cache_pairs_kept={} scratch_dirs_skipped={} local_fail=0\n",
        .{
            if (options.delete) "delete" else "dry-run",
            options.tmp_dir,
            totals.old_pin_cache_pairs,
            totals.scratch_dirs,
            totals.candidates,
            totals.deleted,
            totals.bytes_reclaimable,
            totals.bytes_deleted,
            totals.cache_pairs_kept,
            totals.scratch_dirs_skipped,
        },
    );
    try stdout.flush();
}

fn parseOptions(allocator: std.mem.Allocator, io: std.Io, init: std.process.Init) !Options {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();

    var options: Options = .{};
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--delete")) {
            options.delete = true;
        } else if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            var stdout_buffer: [1024]u8 = undefined;
            var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
            try stdout_writer.interface.writeAll(usage);
            try stdout_writer.interface.flush();
            std.process.exit(0);
        } else if (std.mem.startsWith(u8, arg, "--tmp-dir=")) {
            options.tmp_dir = arg["--tmp-dir=".len..];
        } else if (std.mem.startsWith(u8, arg, "--pin-file=")) {
            options.pin_file = arg["--pin-file=".len..];
        } else if (std.mem.startsWith(u8, arg, "--older-than-seconds=")) {
            options.older_than_seconds = try std.fmt.parseUnsigned(u64, arg["--older-than-seconds=".len..], 10);
        } else {
            try common.validationError(io, "unexpected argument: {s}\n{s}", .{ arg, usage });
        }
    }
    return options;
}

fn readPin(allocator: std.mem.Allocator, io: std.Io, path: []const u8) ![]u8 {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(4096));
    defer allocator.free(contents);
    return allocator.dupe(u8, std.mem.trim(u8, contents, " \t\r\n"));
}

fn scanExportCache(
    allocator: std.mem.Allocator,
    io: std.Io,
    options: Options,
    current_pin: []const u8,
    stdout: *std.Io.Writer,
    totals: *Totals,
) !void {
    const cache_dir_path = try std.fs.path.join(allocator, &.{ options.tmp_dir, export_cache_name });
    defer allocator.free(cache_dir_path);

    var cache_dir = std.Io.Dir.cwd().openDir(io, cache_dir_path, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => return,
        else => return err,
    };
    defer cache_dir.close(io);

    var seen_meta: std.StringArrayHashMapUnmanaged(void) = .empty;
    defer {
        for (seen_meta.keys()) |key| allocator.free(key);
        seen_meta.deinit(allocator);
    }
    var seen_air: std.StringArrayHashMapUnmanaged(void) = .empty;
    defer {
        for (seen_air.keys()) |key| allocator.free(key);
        seen_air.deinit(allocator);
    }

    var iter = cache_dir.iterate();
    while (try iter.next(io)) |entry| {
        if (entry.kind != .file) continue;
        if (std.mem.endsWith(u8, entry.name, ".meta")) {
            const stem = entry.name[0 .. entry.name.len - ".meta".len];
            const owned_stem = try allocator.dupe(u8, stem);
            errdefer allocator.free(owned_stem);
            try seen_meta.put(allocator, owned_stem, {});
        } else if (std.mem.endsWith(u8, entry.name, ".air")) {
            const stem = entry.name[0 .. entry.name.len - ".air".len];
            const owned_stem = try allocator.dupe(u8, stem);
            errdefer allocator.free(owned_stem);
            try seen_air.put(allocator, owned_stem, {});
        } else if (std.mem.endsWith(u8, entry.name, ".log") or std.mem.endsWith(u8, entry.name, ".txt")) {
            continue;
        } else {
            continue;
        }
    }

    for (seen_meta.keys()) |stem| {
        if (!seen_air.contains(stem)) {
            try common.validationError(io, "cache layout error: missing .air pair for {s}/{s}.meta\n", .{ cache_dir_path, stem });
        }
    }
    for (seen_air.keys()) |stem| {
        if (!seen_meta.contains(stem)) {
            try common.validationError(io, "cache layout error: missing .meta pair for {s}/{s}.air\n", .{ cache_dir_path, stem });
        }
    }

    for (seen_meta.keys()) |stem| {
        const meta_name = try std.fmt.allocPrint(allocator, "{s}.meta", .{stem});
        defer allocator.free(meta_name);
        const air_name = try std.fmt.allocPrint(allocator, "{s}.air", .{stem});
        defer allocator.free(air_name);
        const meta_path = try std.fs.path.join(allocator, &.{ cache_dir_path, meta_name });
        defer allocator.free(meta_path);
        const air_path = try std.fs.path.join(allocator, &.{ cache_dir_path, air_name });
        defer allocator.free(air_path);

        const meta = try std.Io.Dir.cwd().readFileAlloc(io, meta_path, allocator, .limited(64 * 1024));
        defer allocator.free(meta);
        const pin = metadataValue(meta, "ziglang_pin") orelse {
            try common.validationError(io, "cache layout error: missing ziglang_pin in {s}\n", .{meta_path});
        };
        if (std.mem.eql(u8, pin, current_pin)) {
            totals.cache_pairs_kept += 1;
            continue;
        }

        const bytes = (try std.Io.Dir.cwd().statFile(io, meta_path, .{})).size +
            (try std.Io.Dir.cwd().statFile(io, air_path, .{})).size;
        try reportCandidate(stdout, options.delete, "old-pin-cache", meta_path, bytes, "pin", pin);
        totals.candidates += 1;
        totals.old_pin_cache_pairs += 1;
        totals.bytes_reclaimable += bytes;
        if (options.delete) {
            try std.Io.Dir.cwd().deleteFile(io, meta_path);
            try std.Io.Dir.cwd().deleteFile(io, air_path);
            totals.deleted += 1;
            totals.bytes_deleted += bytes;
        }
    }
}

fn scanScratchDirs(
    allocator: std.mem.Allocator,
    io: std.Io,
    options: Options,
    stdout: *std.Io.Writer,
    totals: *Totals,
) !void {
    var tmp_dir = std.Io.Dir.cwd().openDir(io, options.tmp_dir, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => return,
        else => return err,
    };
    defer tmp_dir.close(io);

    const now_ns: i128 = std.Io.Timestamp.now(io, .real).nanoseconds;
    const threshold_ns: i128 = @as(i128, @intCast(options.older_than_seconds)) * std.time.ns_per_s;

    var iter = tmp_dir.iterate();
    while (try iter.next(io)) |entry| {
        if (entry.kind != .directory or !isScratchDirName(entry.name)) continue;
        const path = try std.fs.path.join(allocator, &.{ options.tmp_dir, entry.name });
        defer allocator.free(path);
        const stat = try std.Io.Dir.cwd().statFile(io, path, .{});
        if (now_ns - @as(i128, stat.mtime.nanoseconds) < threshold_ns) continue;

        const protected = try containsProtectedFile(allocator, io, path);
        const bytes = try treeSize(allocator, io, path);
        if (protected) {
            try reportCandidate(stdout, false, "scratch-dir-skip-protected", path, bytes, "reason", "contains-log-or-txt");
            totals.scratch_dirs_skipped += 1;
            continue;
        }

        try reportCandidate(stdout, options.delete, "scratch-dir", path, bytes, "reason", "older-than-threshold");
        totals.candidates += 1;
        totals.scratch_dirs += 1;
        totals.bytes_reclaimable += bytes;
        if (options.delete) {
            try std.Io.Dir.cwd().deleteTree(io, path);
            totals.deleted += 1;
            totals.bytes_deleted += bytes;
        }
    }
}

fn isScratchDirName(name: []const u8) bool {
    const prefixes = [_][]const u8{
        "distribution_real_rows_",
        "distribution_zig_air_inventory_",
        "uncurated_zig_air_",
        "zig_integrated_object_",
        "zig_integrated_exe_",
        "handoff_validation_",
    };
    for (prefixes) |prefix| {
        if (std.mem.startsWith(u8, name, prefix)) return true;
    }
    return false;
}

fn containsProtectedFile(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !bool {
    var dir = std.Io.Dir.cwd().openDir(io, path, .{ .iterate = true }) catch |err| switch (err) {
        error.NotDir => return false,
        else => return err,
    };
    defer dir.close(io);

    var iter = dir.iterate();
    while (try iter.next(io)) |entry| {
        if (entry.kind == .file and (std.mem.endsWith(u8, entry.name, ".log") or std.mem.endsWith(u8, entry.name, ".txt"))) return true;
        if (entry.kind == .directory) {
            const child = try std.fs.path.join(allocator, &.{ path, entry.name });
            defer allocator.free(child);
            if (try containsProtectedFile(allocator, io, child)) return true;
        }
    }
    return false;
}

fn treeSize(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !u64 {
    const stat = try std.Io.Dir.cwd().statFile(io, path, .{});
    if (stat.kind != .directory) return stat.size;

    var dir = try std.Io.Dir.cwd().openDir(io, path, .{ .iterate = true });
    defer dir.close(io);

    var size: u64 = 0;
    var iter = dir.iterate();
    while (try iter.next(io)) |entry| {
        const child = try std.fs.path.join(allocator, &.{ path, entry.name });
        defer allocator.free(child);
        size += try treeSize(allocator, io, child);
    }
    return size;
}

fn reportCandidate(
    stdout: *std.Io.Writer,
    delete: bool,
    kind: []const u8,
    path: []const u8,
    bytes: u64,
    reason_key: []const u8,
    reason_value: []const u8,
) !void {
    try stdout.print(
        "clean-tmp item kind={s} action={s} path={s} bytes={} {s}={s}\n",
        .{ kind, if (delete) "delete" else "dry-run", path, bytes, reason_key, reason_value },
    );
}

fn metadataValue(meta: []const u8, key: []const u8) ?[]const u8 {
    var line_iter = std.mem.splitScalar(u8, meta, '\n');
    while (line_iter.next()) |raw_line| {
        const line = std.mem.trimEnd(u8, raw_line, "\r");
        if (line.len <= key.len or line[key.len] != '=') continue;
        if (std.mem.eql(u8, line[0..key.len], key)) return line[key.len + 1 ..];
    }
    return null;
}
