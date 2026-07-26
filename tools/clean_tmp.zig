const std = @import("std");
const common = @import("tool_common.zig");
const headroom_policy = @import("distribution_headroom_policy.zig");

const default_tmp_dir = "tmp";
const default_pin_file = "docs/evidence/ziglang_pin.txt";
const default_retention_manifest = "docs/evidence/tmp_retention_pins.tsv";
const default_max_age_seconds = 2 * 60 * 60;
const default_grace_seconds = 24 * 60 * 60;
const default_tmp_soft_limit_bytes = 8 * 1024 * 1024 * 1024;
const export_cache_name = "real_rows_air_export_cache";
const abi_differential_container_name = "inbox66_abi_diff";
const abi_differential_inbox_number = 66;
const abi_differential_run_class = "abi-differential-scratch-run";

const usage =
    \\usage: zig build clean-tmp -- [--delete] [--tmp-dir=PATH] [--pin-file=PATH] [--older-than-seconds=N] [--keep-newest-per-mode]
    \\       zig build clean-tmp -- --retention-report [report options]
    \\       zig build clean-tmp -- --retention-cleanup [--delete]
    \\         [--only-class=CLASS] [retention options]
    \\
    \\Dry-run is the default. --delete is required to remove stale tmp files.
    \\--keep-newest-per-mode keeps at most one current-pin export-cache entry per mode.
    \\--retention-report emits the deterministic INBOX retention/headroom manifest and rejects --delete.
    \\--retention-cleanup applies the same pin/INBOX/grace classifier to per-INBOX
    \\  directories, nested ABI differential run scratch, and export-cache pairs.
    \\  It is a dry-run unless --delete is also present; delete mode fails closed
    \\  on Git worktrees or open files.
    \\Report options: --retention-manifest=PATH --patched-zig-cache=PATH
    \\  --accepted-through-inbox=N --active-inbox=N --grace-seconds=N --now-seconds=N
    \\  --filesystem-total-bytes=N --filesystem-free-bytes=N --sharding-peak-bytes=N
    \\  --tmp-soft-limit-bytes=N --assert-preserved-file=PATH
    \\
;

const Options = struct {
    delete: bool = false,
    tmp_dir: []const u8 = default_tmp_dir,
    pin_file: []const u8 = default_pin_file,
    older_than_seconds: u64 = default_max_age_seconds,
    keep_newest_per_mode: bool = false,
    retention_report: bool = false,
    retention_cleanup: bool = false,
    retention_manifest: []const u8 = default_retention_manifest,
    only_class: ?[]const u8 = null,
    patched_zig_cache: ?[]const u8 = null,
    accepted_through_inbox: u32 = 0,
    active_inbox: u32 = 0,
    grace_seconds: u64 = default_grace_seconds,
    now_seconds: ?u64 = null,
    filesystem_total_bytes: ?u64 = null,
    filesystem_free_bytes: ?u64 = null,
    sharding_peak_bytes: ?u64 = null,
    tmp_soft_limit_bytes: u64 = default_tmp_soft_limit_bytes,
    assert_preserved_file: ?[]const u8 = null,
};

const Totals = struct {
    candidates: usize = 0,
    deleted: usize = 0,
    bytes_reclaimable: u64 = 0,
    bytes_deleted: u64 = 0,
    old_pin_cache_pairs: usize = 0,
    duplicate_mode_cache_pairs: usize = 0,
    scratch_dirs: usize = 0,
    cache_pairs_kept: usize = 0,
    scratch_dirs_skipped: usize = 0,
};

const CurrentCachePair = struct {
    meta_path: []u8,
    air_path: []u8,
    mode: []u8,
    bytes: u64,
    newest_mtime_ns: i128,

    fn deinit(pair: CurrentCachePair, allocator: std.mem.Allocator) void {
        allocator.free(pair.meta_path);
        allocator.free(pair.air_path);
        allocator.free(pair.mode);
    }
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const options = try parseOptions(allocator, io, init);
    const current_pin = try readPin(allocator, io, options.pin_file);
    defer allocator.free(current_pin);

    if (options.retention_report and options.retention_cleanup) {
        try common.validationError(io, "--retention-report and --retention-cleanup are mutually exclusive\n", .{});
    }
    if (options.only_class != null and !options.retention_cleanup) {
        try common.validationError(io, "--only-class requires --retention-cleanup\n", .{});
    }
    if (options.retention_report) {
        if (options.delete) {
            try common.validationError(io, "--retention-report is report-only and rejects --delete\n", .{});
        }
        const before_contents = if (options.assert_preserved_file) |path|
            try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(1024 * 1024))
        else
            null;
        defer if (before_contents) |contents| allocator.free(contents);

        var stdout_buffer: [4096]u8 = undefined;
        var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
        const stdout = &stdout_writer.interface;
        try runRetentionReport(allocator, io, options, current_pin, stdout);

        if (options.assert_preserved_file) |path| {
            const after_contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(1024 * 1024));
            defer allocator.free(after_contents);
            if (!std.mem.eql(u8, before_contents.?, after_contents)) {
                try common.validationError(io, "report-only preservation failure: {s}\n", .{path});
            }
            try stdout.print("fixture report-only path={s} preserved=true\n", .{path});
        }
        try stdout.flush();
        return;
    }
    if (options.retention_cleanup) {
        var stdout_buffer: [4096]u8 = undefined;
        var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
        const stdout = &stdout_writer.interface;
        try runRetentionCleanup(allocator, io, options, current_pin, stdout);
        try stdout.flush();
        return;
    }

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.print(
        "clean-tmp tmp_dir={s} pin_file={s} current_pin={s} delete={} older_than_seconds={} keep_newest_per_mode={}\n",
        .{ options.tmp_dir, options.pin_file, current_pin, options.delete, options.older_than_seconds, options.keep_newest_per_mode },
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
        "summary clean-tmp mode={s} tmp_dir={s} old_pin_cache_pairs={} duplicate_mode_cache_pairs={} scratch_dirs={} candidates={} deleted={} bytes_reclaimable={} bytes_deleted={} cache_pairs_kept={} scratch_dirs_skipped={} local_fail=0\n",
        .{
            if (options.delete) "delete" else "dry-run",
            options.tmp_dir,
            totals.old_pin_cache_pairs,
            totals.duplicate_mode_cache_pairs,
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
        } else if (std.mem.eql(u8, arg, "--retention-report")) {
            options.retention_report = true;
        } else if (std.mem.eql(u8, arg, "--retention-cleanup")) {
            options.retention_cleanup = true;
        } else if (std.mem.eql(u8, arg, "--keep-newest-per-mode")) {
            options.keep_newest_per_mode = true;
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
        } else if (std.mem.startsWith(u8, arg, "--retention-manifest=")) {
            options.retention_manifest = arg["--retention-manifest=".len..];
        } else if (std.mem.startsWith(u8, arg, "--only-class=")) {
            options.only_class = arg["--only-class=".len..];
        } else if (std.mem.startsWith(u8, arg, "--patched-zig-cache=")) {
            options.patched_zig_cache = arg["--patched-zig-cache=".len..];
        } else if (std.mem.startsWith(u8, arg, "--accepted-through-inbox=")) {
            options.accepted_through_inbox = try std.fmt.parseUnsigned(u32, arg["--accepted-through-inbox=".len..], 10);
        } else if (std.mem.startsWith(u8, arg, "--active-inbox=")) {
            options.active_inbox = try std.fmt.parseUnsigned(u32, arg["--active-inbox=".len..], 10);
        } else if (std.mem.startsWith(u8, arg, "--grace-seconds=")) {
            options.grace_seconds = try std.fmt.parseUnsigned(u64, arg["--grace-seconds=".len..], 10);
        } else if (std.mem.startsWith(u8, arg, "--now-seconds=")) {
            options.now_seconds = try std.fmt.parseUnsigned(u64, arg["--now-seconds=".len..], 10);
        } else if (std.mem.startsWith(u8, arg, "--filesystem-total-bytes=")) {
            options.filesystem_total_bytes = try std.fmt.parseUnsigned(u64, arg["--filesystem-total-bytes=".len..], 10);
        } else if (std.mem.startsWith(u8, arg, "--filesystem-free-bytes=")) {
            options.filesystem_free_bytes = try std.fmt.parseUnsigned(u64, arg["--filesystem-free-bytes=".len..], 10);
        } else if (std.mem.startsWith(u8, arg, "--sharding-peak-bytes=")) {
            options.sharding_peak_bytes = try std.fmt.parseUnsigned(u64, arg["--sharding-peak-bytes=".len..], 10);
        } else if (std.mem.startsWith(u8, arg, "--tmp-soft-limit-bytes=")) {
            options.tmp_soft_limit_bytes = try std.fmt.parseUnsigned(u64, arg["--tmp-soft-limit-bytes=".len..], 10);
        } else if (std.mem.startsWith(u8, arg, "--assert-preserved-file=")) {
            options.assert_preserved_file = arg["--assert-preserved-file=".len..];
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
    const now_ns: i128 = std.Io.Timestamp.now(io, .real).nanoseconds;
    const threshold_ns: i128 = @as(i128, @intCast(options.older_than_seconds)) * std.time.ns_per_s;
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
    var current_pairs: std.ArrayListUnmanaged(CurrentCachePair) = .empty;
    defer {
        for (current_pairs.items) |pair| pair.deinit(allocator);
        current_pairs.deinit(allocator);
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
            const meta_name = try std.fmt.allocPrint(allocator, "{s}.meta", .{stem});
            defer allocator.free(meta_name);
            const meta_path = try std.fs.path.join(allocator, &.{ cache_dir_path, meta_name });
            defer allocator.free(meta_path);
            try maybeReportOrphanCacheFile(io, stdout, options.delete, now_ns, threshold_ns, meta_path, "orphan-cache-meta", totals);
        }
    }
    for (seen_air.keys()) |stem| {
        if (!seen_meta.contains(stem)) {
            const air_name = try std.fmt.allocPrint(allocator, "{s}.air", .{stem});
            defer allocator.free(air_name);
            const air_path = try std.fs.path.join(allocator, &.{ cache_dir_path, air_name });
            defer allocator.free(air_path);
            try maybeReportOrphanCacheFile(io, stdout, options.delete, now_ns, threshold_ns, air_path, "orphan-cache-air", totals);
        }
    }

    for (seen_meta.keys()) |stem| {
        if (!seen_air.contains(stem)) continue;
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
            if (!options.keep_newest_per_mode) {
                totals.cache_pairs_kept += 1;
                continue;
            }

            const mode = metadataValue(meta, "mode") orelse {
                try common.validationError(io, "cache layout error: missing mode in {s}\n", .{meta_path});
            };
            if (modeSlot(mode) == null) {
                try common.validationError(io, "cache layout error: unsupported mode {s} in {s}\n", .{ mode, meta_path });
            }
            const meta_stat = try std.Io.Dir.cwd().statFile(io, meta_path, .{});
            const air_stat = try std.Io.Dir.cwd().statFile(io, air_path, .{});
            const current_pair: CurrentCachePair = .{
                .meta_path = try allocator.dupe(u8, meta_path),
                .air_path = try allocator.dupe(u8, air_path),
                .mode = try allocator.dupe(u8, mode),
                .bytes = meta_stat.size + air_stat.size,
                .newest_mtime_ns = @max(meta_stat.mtime.nanoseconds, air_stat.mtime.nanoseconds),
            };
            errdefer current_pair.deinit(allocator);
            try current_pairs.append(allocator, current_pair);
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

    try pruneDuplicateCurrentCachePairs(io, options, stdout, totals, current_pairs.items);
}

fn pruneDuplicateCurrentCachePairs(
    io: std.Io,
    options: Options,
    stdout: *std.Io.Writer,
    totals: *Totals,
    current_pairs: []const CurrentCachePair,
) !void {
    if (!options.keep_newest_per_mode) return;

    var best_by_mode: [3]?usize = .{ null, null, null };
    for (current_pairs, 0..) |pair, index| {
        const slot = modeSlot(pair.mode) orelse unreachable;
        if (best_by_mode[slot]) |best_index| {
            if (pair.newest_mtime_ns > current_pairs[best_index].newest_mtime_ns) {
                best_by_mode[slot] = index;
            }
        } else {
            best_by_mode[slot] = index;
        }
    }

    for (current_pairs, 0..) |pair, index| {
        const slot = modeSlot(pair.mode) orelse unreachable;
        if (best_by_mode[slot].? == index) {
            totals.cache_pairs_kept += 1;
            continue;
        }

        try reportCandidate(stdout, options.delete, "duplicate-mode-cache", pair.meta_path, pair.bytes, "mode", pair.mode);
        totals.candidates += 1;
        totals.duplicate_mode_cache_pairs += 1;
        totals.bytes_reclaimable += pair.bytes;
        if (options.delete) {
            try std.Io.Dir.cwd().deleteFile(io, pair.meta_path);
            try std.Io.Dir.cwd().deleteFile(io, pair.air_path);
            totals.deleted += 1;
            totals.bytes_deleted += pair.bytes;
        }
    }
}

fn modeSlot(mode: []const u8) ?usize {
    if (std.mem.eql(u8, mode, "ReleaseFast")) return 0;
    if (std.mem.eql(u8, mode, "ReleaseSafe")) return 1;
    if (std.mem.eql(u8, mode, "ReleaseSmall")) return 2;
    return null;
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

        const facts = try treeFacts(allocator, io, path);
        if (now_ns - @as(i128, facts.newest_mtime_ns) < threshold_ns) continue;

        if (facts.contains_protected_file) {
            try reportCandidate(stdout, false, "scratch-dir-skip-protected", path, facts.size, "reason", "contains-log-or-txt");
            totals.scratch_dirs_skipped += 1;
            continue;
        }

        try reportCandidate(stdout, options.delete, "scratch-dir", path, facts.size, "reason", "older-than-threshold");
        totals.candidates += 1;
        totals.scratch_dirs += 1;
        totals.bytes_reclaimable += facts.size;
        if (options.delete) {
            try std.Io.Dir.cwd().deleteTree(io, path);
            totals.deleted += 1;
            totals.bytes_deleted += facts.size;
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

const TreeFacts = struct {
    size: u64 = 0,
    newest_mtime_ns: i128 = std.math.minInt(i128),
    contains_protected_file: bool = false,
    contains_git_marker: bool = false,
};

fn treeFacts(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !TreeFacts {
    const stat = try std.Io.Dir.cwd().statFile(io, path, .{});
    var facts: TreeFacts = .{
        .size = stat.size,
        .newest_mtime_ns = stat.mtime.nanoseconds,
        .contains_protected_file = isProtectedFileName(std.fs.path.basename(path)),
        .contains_git_marker = std.mem.eql(u8, std.fs.path.basename(path), ".git"),
    };
    if (stat.kind != .directory) return facts;

    var dir = try std.Io.Dir.cwd().openDir(io, path, .{ .iterate = true });
    defer dir.close(io);

    var iter = dir.iterate();
    while (try iter.next(io)) |entry| {
        const child = try std.fs.path.join(allocator, &.{ path, entry.name });
        defer allocator.free(child);
        if (entry.kind == .directory) {
            const child_facts = try treeFacts(allocator, io, child);
            facts.size += child_facts.size;
            facts.newest_mtime_ns = @max(facts.newest_mtime_ns, child_facts.newest_mtime_ns);
            facts.contains_protected_file = facts.contains_protected_file or child_facts.contains_protected_file;
            facts.contains_git_marker = facts.contains_git_marker or child_facts.contains_git_marker;
            continue;
        }

        const child_stat = std.Io.Dir.cwd().statFile(io, child, .{}) catch |err| switch (err) {
            error.FileNotFound => continue,
            else => return err,
        };
        facts.size += child_stat.size;
        facts.newest_mtime_ns = @max(facts.newest_mtime_ns, child_stat.mtime.nanoseconds);
        facts.contains_protected_file = facts.contains_protected_file or isProtectedFileName(entry.name);
        facts.contains_git_marker = facts.contains_git_marker or std.mem.eql(u8, entry.name, ".git");
    }
    return facts;
}

fn isProtectedFileName(name: []const u8) bool {
    return std.mem.endsWith(u8, name, ".log") or std.mem.endsWith(u8, name, ".txt");
}

fn maybeReportOrphanCacheFile(
    io: std.Io,
    stdout: *std.Io.Writer,
    delete: bool,
    now_ns: i128,
    threshold_ns: i128,
    path: []const u8,
    kind: []const u8,
    totals: *Totals,
) !void {
    const stat = std.Io.Dir.cwd().statFile(io, path, .{}) catch |err| switch (err) {
        error.FileNotFound => return,
        else => return err,
    };
    if (now_ns - @as(i128, stat.mtime.nanoseconds) < threshold_ns) return;

    try reportCandidate(stdout, delete, kind, path, stat.size, "reason", "missing-pair");
    totals.candidates += 1;
    totals.bytes_reclaimable += stat.size;
    if (delete) {
        try std.Io.Dir.cwd().deleteFile(io, path);
        totals.deleted += 1;
        totals.bytes_deleted += stat.size;
    }
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

const RetentionStatus = enum {
    protected,
    candidate,
};

const RetentionItem = struct {
    path: []u8,
    class: []const u8,
    size_bytes: u64,
    age_seconds: u64,
    root_inode: ?std.Io.File.INode = null,
    pin_or_key: []u8,
    status: RetentionStatus,
    reason: []const u8,
    regeneration_cost: []const u8,

    fn deinit(item: RetentionItem, allocator: std.mem.Allocator) void {
        allocator.free(item.path);
        allocator.free(item.pin_or_key);
    }
};

const ExportReportPair = struct {
    path: []u8,
    size_bytes: u64,
    newest_mtime_ns: i128,
    pin_or_key: []u8,
    mode: ?[]u8,
    complete: bool,
    current: bool,
    metadata_valid: bool,

    fn deinit(pair: ExportReportPair, allocator: std.mem.Allocator) void {
        allocator.free(pair.path);
        allocator.free(pair.pin_or_key);
        if (pair.mode) |mode| allocator.free(mode);
    }
};

fn runRetentionReport(
    allocator: std.mem.Allocator,
    io: std.Io,
    options: Options,
    current_pin: []const u8,
    stdout: *std.Io.Writer,
) !void {
    const total_bytes = options.filesystem_total_bytes orelse {
        try common.validationError(io, "--retention-report requires --filesystem-total-bytes\n", .{});
    };
    const free_bytes = options.filesystem_free_bytes orelse {
        try common.validationError(io, "--retention-report requires --filesystem-free-bytes\n", .{});
    };
    const sharding_peak_bytes = options.sharding_peak_bytes orelse {
        try common.validationError(io, "--retention-report requires --sharding-peak-bytes\n", .{});
    };
    if (options.accepted_through_inbox == 0 or options.active_inbox == 0) {
        try common.validationError(io, "--retention-report requires accepted and active INBOX numbers\n", .{});
    }

    const now_seconds = options.now_seconds orelse @as(u64, @intCast(@divFloor(
        std.Io.Timestamp.now(io, .real).nanoseconds,
        std.time.ns_per_s,
    )));
    const pins = try std.Io.Dir.cwd().readFileAlloc(io, options.retention_manifest, allocator, .limited(64 * 1024));
    defer allocator.free(pins);

    var items: std.ArrayListUnmanaged(RetentionItem) = .empty;
    defer {
        for (items.items) |item| item.deinit(allocator);
        items.deinit(allocator);
    }

    try collectExportRetentionItems(allocator, io, options, current_pin, pins, now_seconds, &items);
    try collectTmpRetentionItems(allocator, io, options, pins, now_seconds, &items);
    if (options.patched_zig_cache) |path| {
        const facts = try treeFacts(allocator, io, path);
        try appendRetentionItem(
            allocator,
            &items,
            path,
            "patched-zig-build-cache",
            facts.size,
            retentionAgeSeconds(now_seconds, facts.newest_mtime_ns),
            current_pin,
            .protected,
            if (retentionPathPinned(pins, path)) "live-pin-current-accepted-generation" else "current-accepted-generation",
            "full-patched-zig-rebuild",
        );
    }

    std.mem.sort(RetentionItem, items.items, {}, retentionItemLessThan);

    const tmp_facts = try treeFacts(allocator, io, options.tmp_dir);
    var total_reclaimable: u64 = 0;
    var candidate_count: usize = 0;
    var protected_count: usize = 0;
    for (items.items) |item| {
        switch (item.status) {
            .candidate => {
                candidate_count += 1;
                total_reclaimable +|= item.size_bytes;
            },
            .protected => protected_count += 1,
        }
    }

    const floor_bytes = (total_bytes + 9) / 10;
    const required_start_bytes = floor_bytes +| sharding_peak_bytes;
    const serial_policy = headroom_policy.forFilesystem(total_bytes);
    const projected_free_after_cleanup = free_bytes +| total_reclaimable;
    const projected_free_after_sharding_peak = projected_free_after_cleanup -| sharding_peak_bytes;

    try stdout.print(
        "# clean-tmp-retention schema=1 mode=report-only observed_at_unix={} tmp_dir={s} pin_file={s} retention_manifest={s}\n",
        .{ now_seconds, options.tmp_dir, options.pin_file, options.retention_manifest },
    );
    try stdout.print(
        "# filesystem_total_bytes={} filesystem_free_bytes={} ten_percent_floor_bytes={} sharding_peak_bytes={} required_start_bytes={} ready_now={}\n",
        .{ total_bytes, free_bytes, floor_bytes, sharding_peak_bytes, required_start_bytes, free_bytes >= required_start_bytes },
    );
    try stdout.print(
        "# serial_headroom schema={} reserve_bytes={} projected_peak_bytes={} required_start_bytes={} ready_now={} authority=tools/distribution_headroom_policy.zig\n",
        .{ headroom_policy.schema_version, serial_policy.reserve_bytes, serial_policy.projected_peak_bytes, serial_policy.required_start_bytes, free_bytes >= serial_policy.required_start_bytes },
    );
    try stdout.print(
        "# tmp_apparent_bytes={} tmp_soft_limit_bytes={} tmp_soft_limit_exceeded={} policy_action=report-only\n",
        .{ tmp_facts.size, options.tmp_soft_limit_bytes, tmp_facts.size > options.tmp_soft_limit_bytes },
    );
    try stdout.writeAll("path\tclass\tsize_bytes\tage_seconds\tpin_or_key\tstatus\treason\tregeneration_cost\treclaimable_bytes\n");
    for (items.items) |item| {
        try stdout.print(
            "{s}\t{s}\t{}\t{}\t{s}\t{s}\t{s}\t{s}\t{}\n",
            .{
                item.path,
                item.class,
                item.size_bytes,
                item.age_seconds,
                item.pin_or_key,
                @tagName(item.status),
                item.reason,
                item.regeneration_cost,
                if (item.status == .candidate) item.size_bytes else 0,
            },
        );
    }
    try stdout.print(
        "# totals entries={} protected={} candidates={} total_reclaimable_bytes={} projected_free_after_cleanup={} projected_free_after_sharding_peak={} projected_ready_after_cleanup={} deleted=0\n",
        .{
            items.items.len,
            protected_count,
            candidate_count,
            total_reclaimable,
            projected_free_after_cleanup,
            projected_free_after_sharding_peak,
            projected_free_after_cleanup >= required_start_bytes,
        },
    );
}

fn runRetentionCleanup(
    allocator: std.mem.Allocator,
    io: std.Io,
    options: Options,
    current_pin: []const u8,
    stdout: *std.Io.Writer,
) !void {
    if (options.accepted_through_inbox == 0 or options.active_inbox == 0) {
        try common.validationError(io, "--retention-cleanup requires accepted and active INBOX numbers\n", .{});
    }
    if (options.delete and !try common.commandExists(allocator, io, "lsof")) {
        try common.validationError(io, "--retention-cleanup --delete requires lsof for open-path checks\n", .{});
    }

    const now_seconds = options.now_seconds orelse @as(u64, @intCast(@divFloor(
        std.Io.Timestamp.now(io, .real).nanoseconds,
        std.time.ns_per_s,
    )));
    const pins = try std.Io.Dir.cwd().readFileAlloc(io, options.retention_manifest, allocator, .limited(64 * 1024));
    defer allocator.free(pins);

    var items: std.ArrayListUnmanaged(RetentionItem) = .empty;
    defer {
        for (items.items) |item| item.deinit(allocator);
        items.deinit(allocator);
    }

    try collectExportRetentionItems(allocator, io, options, current_pin, pins, now_seconds, &items);
    try collectTmpRetentionItems(allocator, io, options, pins, now_seconds, &items);
    if (options.patched_zig_cache) |path| {
        const facts = try treeFacts(allocator, io, path);
        try appendRetentionItem(
            allocator,
            &items,
            path,
            "patched-zig-build-cache",
            facts.size,
            retentionAgeSeconds(now_seconds, facts.newest_mtime_ns),
            current_pin,
            .protected,
            if (retentionPathPinned(pins, path)) "live-pin-current-accepted-generation" else "current-accepted-generation",
            "full-patched-zig-rebuild",
        );
    }
    for (items.items) |*item| {
        if (item.status == .candidate and
            !retentionClassSelected(options.only_class, item.class))
        {
            item.status = .protected;
            item.reason = "filtered-by-only-class";
        }
    }
    std.mem.sort(RetentionItem, items.items, {}, retentionItemLessThan);

    var candidate_count: usize = 0;
    var protected_count: usize = 0;
    var deleted_count: usize = 0;
    var reclaimable_bytes: u64 = 0;
    var deleted_bytes: u64 = 0;

    try stdout.print(
        "# clean-tmp-retention schema=1 mode={s} observed_at_unix={} tmp_dir={s} retention_manifest={s}\n",
        .{
            if (options.delete) "delete" else "dry-run",
            now_seconds,
            options.tmp_dir,
            options.retention_manifest,
        },
    );
    try stdout.writeAll("path\tclass\tsize_bytes\tage_seconds\tpin_or_key\tstatus\treason\tregeneration_cost\taction\n");
    const batch_abi_cleanup = options.delete and retentionClassSelected(
        options.only_class,
        abi_differential_run_class,
    ) and options.only_class != null;
    const abi_container_path = if (batch_abi_cleanup)
        try std.fs.path.join(allocator, &.{ options.tmp_dir, abi_differential_container_name })
    else
        null;
    defer if (abi_container_path) |path| allocator.free(path);

    if (options.delete) {
        if (abi_container_path) |container_path| {
            const current_pins = try std.Io.Dir.cwd().readFileAlloc(
                io,
                options.retention_manifest,
                allocator,
                .limited(64 * 1024),
            );
            defer allocator.free(current_pins);
            for (items.items) |item| {
                if (item.status == .candidate) {
                    try validateAbiDifferentialDeletionCandidate(
                        allocator,
                        io,
                        options,
                        current_pins,
                        now_seconds,
                        container_path,
                        item,
                    );
                }
            }
            try ensurePathUnused(allocator, io, container_path, true);
        } else {
            for (items.items) |item| {
                if (item.status == .candidate) {
                    try ensureRetentionCandidateUnused(allocator, io, item);
                }
            }
        }
    }
    for (items.items) |item| {
        var action: []const u8 = "preserve";
        switch (item.status) {
            .protected => protected_count += 1,
            .candidate => {
                candidate_count += 1;
                reclaimable_bytes +|= item.size_bytes;
                action = if (options.delete) "delete" else "would-delete";
                if (options.delete) {
                    if (abi_container_path) |container_path| {
                        const current_pins = try std.Io.Dir.cwd().readFileAlloc(
                            io,
                            options.retention_manifest,
                            allocator,
                            .limited(64 * 1024),
                        );
                        defer allocator.free(current_pins);
                        try validateAbiDifferentialDeletionCandidate(
                            allocator,
                            io,
                            options,
                            current_pins,
                            now_seconds,
                            container_path,
                            item,
                        );
                    } else {
                        // Repeat immediately before deletion to close most of
                        // the gap between preflight and mutation.
                        try ensureRetentionCandidateUnused(allocator, io, item);
                    }
                    try deleteRetentionCandidate(allocator, io, item);
                    deleted_count += 1;
                    deleted_bytes +|= item.size_bytes;
                }
            },
        }
        try stdout.print(
            "{s}\t{s}\t{}\t{}\t{s}\t{s}\t{s}\t{s}\t{s}\n",
            .{
                item.path,
                item.class,
                item.size_bytes,
                item.age_seconds,
                item.pin_or_key,
                @tagName(item.status),
                item.reason,
                item.regeneration_cost,
                action,
            },
        );
    }
    try stdout.print(
        "# totals entries={} protected={} candidates={} total_reclaimable_bytes={} deleted={} bytes_deleted={} local_fail=0\n",
        .{
            items.items.len,
            protected_count,
            candidate_count,
            reclaimable_bytes,
            deleted_count,
            deleted_bytes,
        },
    );
}

fn ensureRetentionCandidateUnused(
    allocator: std.mem.Allocator,
    io: std.Io,
    item: RetentionItem,
) !void {
    const stat = try std.Io.Dir.cwd().statFile(io, item.path, .{});
    try ensurePathUnused(allocator, io, item.path, stat.kind == .directory);
    if (!std.mem.eql(u8, item.class, "real-rows-air-export-pair")) return;

    const sibling = try exportPairSiblingPath(allocator, item.path);
    defer allocator.free(sibling);
    if (try common.fileExists(io, sibling)) {
        try ensurePathUnused(allocator, io, sibling, false);
    }
}

fn ensurePathUnused(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
    recursive: bool,
) !void {
    const argv: []const []const u8 = if (recursive)
        &.{ "lsof", "-w", "-F", "p", "+D", path }
    else
        &.{ "lsof", "-w", "-F", "p", "--", path };
    const result = try std.process.run(allocator, io, .{
        .argv = argv,
        .stdout_limit = .limited(4 * 1024 * 1024),
        .stderr_limit = .limited(4 * 1024 * 1024),
    });
    defer common.freeRunResult(allocator, result);
    if (result.stdout.len != 0) {
        try common.validationError(io, "retention candidate is in use and cannot be deleted: {s}\n{s}", .{ path, result.stdout });
    }
    switch (result.term) {
        .exited => |code| switch (code) {
            0 => return,
            1 => return,
            else => try common.validationError(io, "lsof failed for retention candidate {s} with exit code {}\n{s}", .{ path, code, result.stderr }),
        },
        else => try common.validationError(io, "lsof terminated abnormally for retention candidate {s}\n", .{path}),
    }
}

fn validateAbiDifferentialDeletionCandidate(
    allocator: std.mem.Allocator,
    io: std.Io,
    options: Options,
    pins: []const u8,
    now_seconds: u64,
    container_path: []const u8,
    item: RetentionItem,
) !void {
    if (!std.mem.eql(u8, item.class, abi_differential_run_class) or
        item.status != .candidate)
    {
        return error.RetentionCandidateClassMismatch;
    }
    const candidate_parent = std.fs.path.dirname(item.path) orelse
        return error.RetentionCandidatePathInvalid;
    const candidate_name = std.fs.path.basename(item.path);
    if (!std.mem.eql(u8, candidate_parent, container_path) or
        !isAbiDifferentialRunName(candidate_name))
    {
        return error.RetentionCandidatePathInvalid;
    }

    const cwd = std.Io.Dir.cwd();
    const container_stat = try cwd.statFile(io, container_path, .{ .follow_symlinks = false });
    if (container_stat.kind != .directory) return error.RetentionContainerNotDirectory;
    const candidate_stat = try cwd.statFile(io, item.path, .{ .follow_symlinks = false });
    if (candidate_stat.kind != .directory) return error.RetentionCandidateNotDirectory;
    if (candidate_stat.inode != (item.root_inode orelse
        return error.RetentionCandidateIdentityMissing))
    {
        return error.RetentionCandidateIdentityChanged;
    }

    const canonical_container = try cwd.realPathFileAlloc(io, container_path, allocator);
    defer allocator.free(canonical_container);
    const canonical_candidate = try cwd.realPathFileAlloc(io, item.path, allocator);
    defer allocator.free(canonical_candidate);
    const canonical_parent = std.fs.path.dirname(canonical_candidate) orelse
        return error.RetentionCandidateOutsideContainer;
    if (!std.mem.eql(u8, canonical_parent, canonical_container)) {
        return error.RetentionCandidateOutsideContainer;
    }

    if (retentionPathPinned(pins, item.path)) return error.RetentionCandidatePinned;
    if (options.active_inbox == abi_differential_inbox_number or
        options.accepted_through_inbox < abi_differential_inbox_number)
    {
        return error.RetentionCandidateIneligible;
    }
    const facts = try treeFacts(allocator, io, item.path);
    if (facts.contains_git_marker) return error.RetentionCandidateContainsGitMarker;
    if (retentionAgeSeconds(now_seconds, facts.newest_mtime_ns) < options.grace_seconds) {
        return error.RetentionCandidateInGracePeriod;
    }
}

fn deleteRetentionCandidate(
    allocator: std.mem.Allocator,
    io: std.Io,
    item: RetentionItem,
) !void {
    if (!std.mem.eql(u8, item.class, "real-rows-air-export-pair")) {
        try std.Io.Dir.cwd().deleteTree(io, item.path);
        return;
    }

    try deleteFileIfPresent(io, item.path);
    const sibling = try exportPairSiblingPath(allocator, item.path);
    defer allocator.free(sibling);
    try deleteFileIfPresent(io, sibling);
}

fn deleteFileIfPresent(io: std.Io, path: []const u8) !void {
    std.Io.Dir.cwd().deleteFile(io, path) catch |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    };
}

fn exportPairSiblingPath(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    if (std.mem.endsWith(u8, path, ".meta")) {
        return std.fmt.allocPrint(allocator, "{s}.air", .{path[0 .. path.len - ".meta".len]});
    }
    if (std.mem.endsWith(u8, path, ".air")) {
        return std.fmt.allocPrint(allocator, "{s}.meta", .{path[0 .. path.len - ".air".len]});
    }
    return error.InvalidRetentionExportPairPath;
}

fn appendRetentionItem(
    allocator: std.mem.Allocator,
    items: *std.ArrayListUnmanaged(RetentionItem),
    path: []const u8,
    class: []const u8,
    size_bytes: u64,
    age_seconds: u64,
    pin_or_key: []const u8,
    status: RetentionStatus,
    reason: []const u8,
    regeneration_cost: []const u8,
) !void {
    const owned_path = try allocator.dupe(u8, path);
    errdefer allocator.free(owned_path);
    const owned_key = try allocator.dupe(u8, pin_or_key);
    errdefer allocator.free(owned_key);
    try items.append(allocator, .{
        .path = owned_path,
        .class = class,
        .size_bytes = size_bytes,
        .age_seconds = age_seconds,
        .root_inode = null,
        .pin_or_key = owned_key,
        .status = status,
        .reason = reason,
        .regeneration_cost = regeneration_cost,
    });
}

fn retentionItemLessThan(_: void, lhs: RetentionItem, rhs: RetentionItem) bool {
    return std.mem.lessThan(u8, lhs.path, rhs.path);
}

fn retentionAgeSeconds(now_seconds: u64, mtime_ns: i128) u64 {
    if (mtime_ns <= 0) return now_seconds;
    const mtime_seconds: u64 = @intCast(@divFloor(mtime_ns, std.time.ns_per_s));
    return now_seconds -| mtime_seconds;
}

fn retentionPathPinned(contents: []const u8, path: []const u8) bool {
    return retentionPinKey(contents, path) != null;
}

fn retentionPinKey(contents: []const u8, path: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t\r");
        if (line.len == 0 or line[0] == '#') continue;
        var fields = std.mem.splitScalar(u8, line, '\t');
        const candidate = fields.next() orelse continue;
        if (std.mem.eql(u8, candidate, "path")) continue;
        if (!std.mem.eql(u8, candidate, path)) continue;
        _ = fields.next() orelse return "explicit-pin";
        return fields.next() orelse "explicit-pin";
    }
    return null;
}

fn collectTmpRetentionItems(
    allocator: std.mem.Allocator,
    io: std.Io,
    options: Options,
    pins: []const u8,
    now_seconds: u64,
    items: *std.ArrayListUnmanaged(RetentionItem),
) !void {
    var tmp_dir = try std.Io.Dir.cwd().openDir(io, options.tmp_dir, .{ .iterate = true });
    defer tmp_dir.close(io);

    var names: std.ArrayListUnmanaged([]u8) = .empty;
    defer {
        for (names.items) |name| allocator.free(name);
        names.deinit(allocator);
    }
    var iter = tmp_dir.iterate();
    while (try iter.next(io)) |entry| {
        if (entry.kind != .directory or std.mem.eql(u8, entry.name, export_cache_name)) continue;
        try names.append(allocator, try allocator.dupe(u8, entry.name));
    }
    std.mem.sort([]u8, names.items, {}, stringSliceLessThan);

    for (names.items) |name| {
        const path = try std.fs.path.join(allocator, &.{ options.tmp_dir, name });
        defer allocator.free(path);
        if (std.mem.eql(u8, name, abi_differential_container_name)) {
            try collectAbiDifferentialRetentionItems(
                allocator,
                io,
                options,
                pins,
                now_seconds,
                path,
                items,
            );
            continue;
        }
        const facts = try treeFacts(allocator, io, path);
        const age_seconds = retentionAgeSeconds(now_seconds, facts.newest_mtime_ns);
        const inbox_number = parseInboxNumber(name);
        const class = tmpRetentionClass(name, inbox_number);
        const regeneration_cost = tmpRegenerationCost(class);

        var status: RetentionStatus = .protected;
        var reason: []const u8 = "unclassified-manual-review";
        if (retentionPathPinned(pins, path)) {
            reason = "explicit-live-pin";
        } else if (facts.contains_git_marker) {
            reason = "contains-git-worktree-marker";
        } else if (age_seconds < options.older_than_seconds) {
            reason = "two-hour-short-run-window";
        } else if (inbox_number) |number| {
            if (number == options.active_inbox) {
                reason = "active-inbox";
            } else if (number > options.accepted_through_inbox) {
                reason = "inbox-not-accepted";
            } else if (age_seconds < options.grace_seconds) {
                reason = "accepted-inbox-grace-window";
            } else {
                status = .candidate;
                reason = "accepted-inbox-after-grace";
            }
        } else if (!std.mem.eql(u8, class, "unclassified-tmp")) {
            status = .candidate;
            reason = "short-run-or-diagnostic-after-two-hours";
        }

        const key = if (retentionPinKey(pins, path)) |pin_key|
            try allocator.dupe(u8, pin_key)
        else if (inbox_number) |number|
            try std.fmt.allocPrint(allocator, "INBOX-{}", .{number})
        else
            try allocator.dupe(u8, "unknown");
        defer allocator.free(key);
        try appendRetentionItem(
            allocator,
            items,
            path,
            class,
            facts.size,
            age_seconds,
            key,
            status,
            reason,
            regeneration_cost,
        );
    }
}

fn collectAbiDifferentialRetentionItems(
    allocator: std.mem.Allocator,
    io: std.Io,
    options: Options,
    pins: []const u8,
    now_seconds: u64,
    container_path: []const u8,
    items: *std.ArrayListUnmanaged(RetentionItem),
) !void {
    var container = try std.Io.Dir.cwd().openDir(io, container_path, .{ .iterate = true });
    defer container.close(io);

    var names: std.ArrayListUnmanaged([]u8) = .empty;
    defer {
        for (names.items) |name| allocator.free(name);
        names.deinit(allocator);
    }
    var iter = container.iterate();
    while (try iter.next(io)) |entry| {
        if (entry.kind != .directory) continue;
        try names.append(allocator, try allocator.dupe(u8, entry.name));
    }
    std.mem.sort([]u8, names.items, {}, stringSliceLessThan);

    for (names.items) |name| {
        const path = try std.fs.path.join(allocator, &.{ container_path, name });
        defer allocator.free(path);
        const root_stat = try std.Io.Dir.cwd().statFile(io, path, .{ .follow_symlinks = false });
        const is_run = isAbiDifferentialRunName(name);
        if (root_stat.kind != .directory) {
            try appendRetentionItem(
                allocator,
                items,
                path,
                if (is_run)
                    "abi-differential-scratch-run"
                else
                    "abi-differential-retained-result",
                root_stat.size,
                0,
                "INBOX-66",
                .protected,
                "not-ordinary-directory",
                if (is_run)
                    "rerun-abi-differential"
                else
                    "named-result-preserved",
            );
            continue;
        }
        const facts = try treeFacts(allocator, io, path);
        const age_seconds = retentionAgeSeconds(now_seconds, facts.newest_mtime_ns);
        const pin_key = retentionPinKey(pins, path);

        var status: RetentionStatus = .protected;
        var reason: []const u8 = "named-result-not-run-scratch";
        if (!is_run) {
            if (pin_key != null) reason = "explicit-live-pin";
        } else if (pin_key != null) {
            reason = "explicit-live-pin";
        } else if (facts.contains_git_marker) {
            reason = "contains-git-worktree-marker";
        } else if (options.active_inbox == abi_differential_inbox_number) {
            reason = "active-inbox";
        } else if (options.accepted_through_inbox < abi_differential_inbox_number) {
            reason = "inbox-not-accepted";
        } else if (age_seconds < options.grace_seconds) {
            reason = "accepted-inbox-grace-window";
        } else {
            status = .candidate;
            reason = "accepted-abi-run-after-grace";
        }

        try appendRetentionItem(
            allocator,
            items,
            path,
            if (is_run)
                abi_differential_run_class
            else
                "abi-differential-retained-result",
            facts.size,
            age_seconds,
            pin_key orelse "INBOX-66",
            status,
            reason,
            if (is_run)
                "rerun-abi-differential"
            else
                "named-result-preserved",
        );
        items.items[items.items.len - 1].root_inode = root_stat.inode;
    }
}

fn isAbiDifferentialRunName(name: []const u8) bool {
    const prefix = "run-";
    if (!std.mem.startsWith(u8, name, prefix) or name.len == prefix.len) return false;
    for (name[prefix.len..]) |byte| {
        if (!std.ascii.isDigit(byte)) return false;
    }
    return true;
}

fn retentionClassSelected(only_class: ?[]const u8, class: []const u8) bool {
    const selected = only_class orelse return true;
    return std.mem.eql(u8, selected, class);
}

fn stringSliceLessThan(_: void, lhs: []u8, rhs: []u8) bool {
    return std.mem.lessThan(u8, lhs, rhs);
}

fn parseInboxNumber(name: []const u8) ?u32 {
    if (!std.mem.startsWith(u8, name, "inbox")) return null;
    var end: usize = "inbox".len;
    while (end < name.len and std.ascii.isDigit(name[end])) : (end += 1) {}
    if (end == "inbox".len) return null;
    return std.fmt.parseUnsigned(u32, name["inbox".len..end], 10) catch null;
}

fn tmpRetentionClass(name: []const u8, inbox_number: ?u32) []const u8 {
    if (inbox_number != null) return "per-inbox-tmp";
    if (isScratchDirName(name) or
        std.mem.endsWith(u8, name, "_probe") or
        std.mem.indexOf(u8, name, "_proto") != null or
        std.mem.eql(u8, name, "clean_tmp_fixture"))
    {
        return "short-run-tmp";
    }
    if (std.mem.endsWith(u8, name, "_cache") or std.mem.indexOf(u8, name, "_cache") != null) {
        return "diagnostic-build-cache";
    }
    return "unclassified-tmp";
}

fn tmpRegenerationCost(class: []const u8) []const u8 {
    if (std.mem.eql(u8, class, "per-inbox-tmp")) return "focused-rebuild-or-reprobe";
    if (std.mem.eql(u8, class, "short-run-tmp")) return "rerun-short-focused-command";
    if (std.mem.eql(u8, class, "diagnostic-build-cache")) return "rebuild-diagnostic-capture";
    return "unknown-review-required";
}

test "ABI differential run names require a numeric run suffix" {
    try std.testing.expect(isAbiDifferentialRunName("run-1"));
    try std.testing.expect(isAbiDifferentialRunName("run-4193611"));
    try std.testing.expect(!isAbiDifferentialRunName("run-"));
    try std.testing.expect(!isAbiDifferentialRunName("run-current"));
    try std.testing.expect(!isAbiDifferentialRunName("focused-final"));
    try std.testing.expect(!isAbiDifferentialRunName("run-12-final"));
}

test "retention class filter fails closed on other classes" {
    try std.testing.expect(retentionClassSelected(null, "anything"));
    try std.testing.expect(retentionClassSelected(
        "abi-differential-scratch-run",
        "abi-differential-scratch-run",
    ));
    try std.testing.expect(!retentionClassSelected(
        "abi-differential-scratch-run",
        "per-inbox-tmp",
    ));
    try std.testing.expect(!retentionClassSelected("", "abi-differential-scratch-run"));
}

fn retentionItemNamed(items: []const RetentionItem, name: []const u8) ?RetentionItem {
    for (items) |item| {
        if (std.mem.eql(u8, std.fs.path.basename(item.path), name)) return item;
    }
    return null;
}

test "ABI retention fixture rejects protected and replaced paths" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();

    const fixture_root = try temp.dir.realPathFileAlloc(io, ".", allocator);
    defer allocator.free(fixture_root);
    const container_path = try std.fs.path.join(
        allocator,
        &.{ fixture_root, abi_differential_container_name },
    );
    defer allocator.free(container_path);
    const candidate_path = try std.fs.path.join(allocator, &.{ container_path, "run-100" });
    defer allocator.free(candidate_path);
    const pinned_path = try std.fs.path.join(allocator, &.{ container_path, "run-300" });
    defer allocator.free(pinned_path);

    try temp.dir.createDirPath(io, abi_differential_container_name ++ "/run-100");
    try temp.dir.createDirPath(io, abi_differential_container_name ++ "/run-200/.git");
    try temp.dir.createDirPath(io, abi_differential_container_name ++ "/run-300");
    try temp.dir.createDirPath(io, abi_differential_container_name ++ "/focused-final");
    try temp.dir.symLink(
        io,
        "run-100",
        abi_differential_container_name ++ "/run-400",
        .{ .is_directory = true },
    );

    const pins = try std.fmt.allocPrint(
        allocator,
        "{s}\tabi-differential-scratch-run\tfixture-pin\n",
        .{pinned_path},
    );
    defer allocator.free(pins);
    const options: Options = .{
        .tmp_dir = fixture_root,
        .accepted_through_inbox = 206,
        .active_inbox = 207,
        .grace_seconds = 0,
    };
    var items: std.ArrayListUnmanaged(RetentionItem) = .empty;
    defer {
        for (items.items) |item| item.deinit(allocator);
        items.deinit(allocator);
    }
    try collectAbiDifferentialRetentionItems(
        allocator,
        io,
        options,
        pins,
        1,
        container_path,
        &items,
    );

    try std.testing.expectEqual(@as(usize, 4), items.items.len);
    const candidate = retentionItemNamed(items.items, "run-100") orelse
        return error.TestExpectedCandidate;
    try std.testing.expectEqual(RetentionStatus.candidate, candidate.status);
    try std.testing.expectEqualStrings(abi_differential_run_class, candidate.class);
    try std.testing.expectEqual(
        RetentionStatus.protected,
        (retentionItemNamed(items.items, "run-200") orelse
            return error.TestExpectedGitMarker).status,
    );
    try std.testing.expectEqual(
        RetentionStatus.protected,
        (retentionItemNamed(items.items, "run-300") orelse
            return error.TestExpectedPinned).status,
    );
    try std.testing.expectEqual(
        RetentionStatus.protected,
        (retentionItemNamed(items.items, "focused-final") orelse
            return error.TestExpectedNamedResult).status,
    );
    try std.testing.expect(retentionItemNamed(items.items, "run-400") == null);

    try validateAbiDifferentialDeletionCandidate(
        allocator,
        io,
        options,
        "",
        1,
        container_path,
        candidate,
    );
    const candidate_pins = try std.fmt.allocPrint(
        allocator,
        "{s}\tabi-differential-scratch-run\tfixture-candidate-pin\n",
        .{candidate_path},
    );
    defer allocator.free(candidate_pins);
    try std.testing.expectError(
        error.RetentionCandidatePinned,
        validateAbiDifferentialDeletionCandidate(
            allocator,
            io,
            options,
            candidate_pins,
            1,
            container_path,
            candidate,
        ),
    );
    var active_options = options;
    active_options.active_inbox = abi_differential_inbox_number;
    try std.testing.expectError(
        error.RetentionCandidateIneligible,
        validateAbiDifferentialDeletionCandidate(
            allocator,
            io,
            active_options,
            "",
            1,
            container_path,
            candidate,
        ),
    );
    var grace_options = options;
    grace_options.grace_seconds = 1;
    try std.testing.expectError(
        error.RetentionCandidateInGracePeriod,
        validateAbiDifferentialDeletionCandidate(
            allocator,
            io,
            grace_options,
            "",
            1,
            container_path,
            candidate,
        ),
    );

    try temp.dir.rename(
        abi_differential_container_name ++ "/run-100",
        temp.dir,
        abi_differential_container_name ++ "/run-100-original",
        io,
    );
    try temp.dir.symLink(
        io,
        "run-100-original",
        abi_differential_container_name ++ "/run-100",
        .{ .is_directory = true },
    );
    try std.testing.expectError(
        error.RetentionCandidateNotDirectory,
        validateAbiDifferentialDeletionCandidate(
            allocator,
            io,
            options,
            "",
            1,
            container_path,
            candidate,
        ),
    );
}

fn collectExportRetentionItems(
    allocator: std.mem.Allocator,
    io: std.Io,
    options: Options,
    current_pin: []const u8,
    pins: []const u8,
    now_seconds: u64,
    items: *std.ArrayListUnmanaged(RetentionItem),
) !void {
    const cache_dir_path = try std.fs.path.join(allocator, &.{ options.tmp_dir, export_cache_name });
    defer allocator.free(cache_dir_path);
    var cache_dir = std.Io.Dir.cwd().openDir(io, cache_dir_path, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => return,
        else => return err,
    };
    defer cache_dir.close(io);

    var stems: std.ArrayListUnmanaged([]u8) = .empty;
    defer {
        for (stems.items) |stem| allocator.free(stem);
        stems.deinit(allocator);
    }
    var iter = cache_dir.iterate();
    while (try iter.next(io)) |entry| {
        if (entry.kind != .file) continue;
        const suffix: []const u8 = if (std.mem.endsWith(u8, entry.name, ".meta"))
            ".meta"
        else if (std.mem.endsWith(u8, entry.name, ".air"))
            ".air"
        else
            continue;
        try stems.append(allocator, try allocator.dupe(u8, entry.name[0 .. entry.name.len - suffix.len]));
    }
    std.mem.sort([]u8, stems.items, {}, stringSliceLessThan);

    var pairs: std.ArrayListUnmanaged(ExportReportPair) = .empty;
    defer {
        for (pairs.items) |pair| pair.deinit(allocator);
        pairs.deinit(allocator);
    }
    var previous: ?[]const u8 = null;
    for (stems.items) |stem| {
        if (previous) |seen| {
            if (std.mem.eql(u8, seen, stem)) continue;
        }
        previous = stem;
        try pairs.append(allocator, try readExportReportPair(allocator, io, cache_dir_path, stem, current_pin));
    }

    var best_by_mode: [3]?usize = .{ null, null, null };
    for (pairs.items, 0..) |pair, index| {
        if (!pair.complete or !pair.current or !pair.metadata_valid) continue;
        const slot = modeSlot(pair.mode.?) orelse continue;
        if (best_by_mode[slot]) |best_index| {
            const best = pairs.items[best_index];
            if (pair.newest_mtime_ns > best.newest_mtime_ns or
                (pair.newest_mtime_ns == best.newest_mtime_ns and std.mem.lessThan(u8, pair.path, best.path)))
            {
                best_by_mode[slot] = index;
            }
        } else {
            best_by_mode[slot] = index;
        }
    }

    for (pairs.items, 0..) |pair, index| {
        var status: RetentionStatus = .candidate;
        var reason: []const u8 = "incomplete-export-pair";
        if (retentionPathPinned(pins, pair.path)) {
            status = .protected;
            reason = "explicit-live-pin";
        } else if (!pair.complete) {
            reason = "incomplete-export-pair";
        } else if (!pair.metadata_valid) {
            reason = "invalid-export-metadata";
        } else if (!pair.current) {
            reason = "old-pin-or-exporter-pair";
        } else {
            const slot = modeSlot(pair.mode.?).?;
            if (best_by_mode[slot].? == index) {
                status = .protected;
                reason = "current-pin-exporter-mode-pair";
            } else {
                reason = "duplicate-current-mode-pair";
            }
        }
        try appendRetentionItem(
            allocator,
            items,
            pair.path,
            "real-rows-air-export-pair",
            pair.size_bytes,
            retentionAgeSeconds(now_seconds, pair.newest_mtime_ns),
            pair.pin_or_key,
            status,
            reason,
            "full-mode-air-export",
        );
    }
}

fn readExportReportPair(
    allocator: std.mem.Allocator,
    io: std.Io,
    cache_dir_path: []const u8,
    stem: []const u8,
    current_pin: []const u8,
) !ExportReportPair {
    const meta_name = try std.fmt.allocPrint(allocator, "{s}.meta", .{stem});
    defer allocator.free(meta_name);
    const air_name = try std.fmt.allocPrint(allocator, "{s}.air", .{stem});
    defer allocator.free(air_name);
    const meta_path = try std.fs.path.join(allocator, &.{ cache_dir_path, meta_name });
    defer allocator.free(meta_path);
    const air_path = try std.fs.path.join(allocator, &.{ cache_dir_path, air_name });
    defer allocator.free(air_path);

    const meta_stat = std.Io.Dir.cwd().statFile(io, meta_path, .{}) catch |err| switch (err) {
        error.FileNotFound => null,
        else => return err,
    };
    const air_stat = std.Io.Dir.cwd().statFile(io, air_path, .{}) catch |err| switch (err) {
        error.FileNotFound => null,
        else => return err,
    };
    const complete = meta_stat != null and air_stat != null;
    const report_path = if (meta_stat != null) meta_path else air_path;
    var size_bytes: u64 = 0;
    var newest_mtime_ns: i128 = 0;
    if (meta_stat) |stat| {
        size_bytes +|= stat.size;
        newest_mtime_ns = @max(newest_mtime_ns, stat.mtime.nanoseconds);
    }
    if (air_stat) |stat| {
        size_bytes +|= stat.size;
        newest_mtime_ns = @max(newest_mtime_ns, stat.mtime.nanoseconds);
    }

    if (!complete) {
        return .{
            .path = try allocator.dupe(u8, report_path),
            .size_bytes = size_bytes,
            .newest_mtime_ns = newest_mtime_ns,
            .pin_or_key = try allocator.dupe(u8, "unknown"),
            .mode = null,
            .complete = false,
            .current = false,
            .metadata_valid = false,
        };
    }

    const meta = try std.Io.Dir.cwd().readFileAlloc(io, meta_path, allocator, .limited(64 * 1024));
    defer allocator.free(meta);
    const pin = metadataValue(meta, "ziglang_pin");
    const mode_value = metadataValue(meta, "mode");
    const exporter = metadataValue(meta, "z_llvm_export_state");
    const metadata_valid = pin != null and mode_value != null and exporter != null and modeSlot(mode_value.?) != null;
    const key = if (pin != null and mode_value != null and exporter != null)
        try std.fmt.allocPrint(allocator, "pin={s};mode={s};exporter={s}", .{ pin.?, mode_value.?, exporter.? })
    else
        try allocator.dupe(u8, "invalid-metadata");
    errdefer allocator.free(key);
    const mode = if (mode_value) |value| try allocator.dupe(u8, value) else null;
    errdefer if (mode) |value| allocator.free(value);
    return .{
        .path = try allocator.dupe(u8, meta_path),
        .size_bytes = size_bytes,
        .newest_mtime_ns = newest_mtime_ns,
        .pin_or_key = key,
        .mode = mode,
        .complete = true,
        .current = pin != null and std.mem.eql(u8, pin.?, current_pin),
        .metadata_valid = metadata_valid,
    };
}
