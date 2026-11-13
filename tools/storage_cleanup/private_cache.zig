//! Explicit ownership review for private caches of closed native test runs.
const std = @import("std");
const core = @import("engine.zig");
const u = @import("../validation/common.zig");
const p = core.p;

pub const PlanEntry = struct {
    producer: []const u8,
    run_root: []const u8,
    working_directory: []const u8,
    legacy_working_directory_review: ?[]const u8 = null,
};

fn ownedArgument(e: *core.Engine, run: []const u8, cwd: []const u8, raw: []const u8) !?[]const u8 {
    const path = if (std.fs.path.isAbsolute(raw)) e.relative(raw) catch return null else blk: {
        if (!p.relative(raw)) return error.InvalidPrivateCacheArgument;
        break :blk try e.c.fmt("{s}/{s}", .{ cwd, raw });
    };
    return if (p.privateCacheOwned(run, cwd, path)) path else null;
}

pub fn paths(e: *core.Engine, run: []const u8, cwd: []const u8, v: u.Value) ![]const []const u8 {
    const argv = try core.get(v, "argv");
    if (argv != .array or argv.array.items.len < 2) return error.UnsupportedCacheCommand;
    for (argv.array.items) |arg| if (arg != .string) return error.UnsupportedCacheCommand;
    var result: std.ArrayList([]const u8) = .empty;
    var command: usize = 0;
    if (std.mem.eql(u8, argv.array.items[0].string, "env")) {
        command = 1;
        while (command < argv.array.items.len and std.mem.indexOfScalar(u8, argv.array.items[command].string, '=') != null) : (command += 1) {
            const assignment = argv.array.items[command].string;
            for ([_][]const u8{ "ZIG_LOCAL_CACHE_DIR=", "ZIG_GLOBAL_CACHE_DIR=" }) |prefix| {
                if (std.mem.startsWith(u8, assignment, prefix)) if (try ownedArgument(e, run, cwd, assignment[prefix.len..])) |path| try result.append(e.c.a, path);
            }
        }
    }
    if (command + 1 >= argv.array.items.len or !std.mem.eql(u8, std.fs.path.basename(argv.array.items[command].string), "zig")) return error.UnsupportedCacheCommand;
    const subcommand = argv.array.items[command + 1].string;
    var supported = false;
    for ([_][]const u8{ "test", "build", "build-exe", "build-lib", "build-obj" }) |name| if (std.mem.eql(u8, name, subcommand)) {
        supported = true;
        break;
    };
    if (!supported) return error.UnsupportedCacheCommand;
    var i = command + 2;
    while (i < argv.array.items.len) : (i += 1) {
        const arg = argv.array.items[i].string;
        if (!std.mem.eql(u8, arg, "--cache-dir") and !std.mem.eql(u8, arg, "--global-cache-dir")) continue;
        i += 1;
        if (i >= argv.array.items.len) return error.InvalidPrivateCacheArgument;
        if (try ownedArgument(e, run, cwd, argv.array.items[i].string)) |path| try result.append(e.c.a, path);
    }
    // Ambiguous reuse is an ownership issue, not permission to delete twice.
    for (result.items, 0..) |path, a| for (result.items[0..a]) |old| if (std.mem.eql(u8, old, path)) return error.DuplicateCacheArgument;
    return result.toOwnedSlice(e.c.a);
}

fn owner(e: *core.Engine, run: []const u8, producer: []const u8, binding: p.CacheOwner, v: u.Value) ![]const u8 {
    const cwd = binding.working_directory;
    if (!p.candidate(run) or !p.candidate(cwd) or !p.within(run, cwd) or !p.within(run, producer)) return error.UnboundPrivateCacheOwner;
    if (!core.eq(v, "status", "finished") or (!core.eq(v, "outcome", "completed") and !core.eq(v, "outcome", "canceled"))) return error.ProducerNotTerminal;
    _ = try core.integer(v, "actual_returncode");
    if (try core.integer(v, "finished_ns") <= try core.integer(v, "started_ns")) return error.ProducerNotTerminal;
    if (core.has(v, "cwd", .string)) {
        if (!std.mem.eql(u8, cwd, try e.relative(try core.str(v, "cwd")))) return error.CacheWorkingDirectoryMismatch;
    } else {
        // Older run_checked receipts omitted cwd. Never infer it automatically
        // from a missing field: the explicit release records the operator's
        // review of this copied project, its logs and matching private layout.
        const review = binding.legacy_working_directory_review orelse return error.MissingCacheWorkingDirectory;
        if (review.len == 0) return error.MissingCacheWorkingDirectory;
        const version = try e.metadata(try e.c.fmt("{s}/.zigversion", .{cwd}));
        if (version.kind != .file or version.uid != std.os.linux.getuid()) return error.UnboundPrivateCacheOwner;
        // prepare_unit_project links src to the research tree. Inspect the
        // owned marker itself, never traverse or retain that source tree just
        // to retire a private cache. Cache paths still reject every symlink.
        const source = try e.metadata(try e.c.fmt("{s}/src", .{cwd}));
        if ((source.kind != .directory and source.kind != .symlink) or source.uid != std.os.linux.getuid()) return error.UnboundPrivateCacheOwner;
    }
    const log = try e.relative(try core.str(v, "log"));
    if (!p.within(run, log) or std.mem.eql(u8, run, log)) return error.UnboundPrivateCacheLog;
    return log;
}

pub fn verify(e: *core.Engine, action: core.Action, record: p.Release, producer: u.Value) !void {
    const binding = record.cache_owner orelse return error.MissingCacheOwner;
    const log = try owner(e, record.run_root, record.producer.path, binding, producer);
    if (!p.privateCacheOwned(record.run_root, binding.working_directory, action.path)) return error.UnboundPrivateCacheOwner;
    var bound = false;
    for (try paths(e, record.run_root, binding.working_directory, producer)) |path| if (std.mem.eql(u8, path, action.path)) {
        bound = true;
        break;
    };
    if (!bound) return error.UnboundDisposableCache;
    for (record.retained) |row| if (row.role == .diagnostic and std.mem.eql(u8, row.path, log)) return;
    return error.MissingCacheDiagnostics;
}

pub fn request(e: *core.Engine, entry: PlanEntry, reason: []const u8) !?p.Release {
    if (!p.relative(entry.producer) or reason.len == 0) return error.InvalidEvidencePath;
    const binding: p.CacheOwner = .{ .working_directory = entry.working_directory, .legacy_working_directory_review = entry.legacy_working_directory_review };
    var parsed = try e.load(e.c.gpa, entry.producer);
    defer parsed.deinit();
    const log = try owner(e, entry.run_root, entry.producer, binding, parsed.value);
    var artifacts: std.ArrayList(p.Artifact) = .empty;
    for (try paths(e, entry.run_root, entry.working_directory, parsed.value)) |path| {
        const m = e.metadata(path) catch |err| switch (err) {
            error.FileNotFound => continue,
            else => return err,
        };
        if (m.kind != .directory) return error.CacheNotDirectory;
        try artifacts.append(e.c.a, .{ .path = path, .kind = .private_cache });
    }
    if (artifacts.items.len == 0) return null;
    return .{
        .schema = "zllvm-storage-release-v1",
        .state = .disposable,
        .run_root = entry.run_root,
        .reason = reason,
        .producer = .{ .path = entry.producer, .sha256 = try e.digest(entry.producer) },
        .retained = try e.c.a.dupe(p.Retained, &.{.{ .path = log, .sha256 = try e.digest(log), .role = .diagnostic }}),
        .artifacts = artifacts.items,
        .cache_owner = binding,
    };
}
