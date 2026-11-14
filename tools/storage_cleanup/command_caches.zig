//! Explicit private-cache ownership from a passed validation's command ledger.
const std = @import("std");
const core = @import("engine.zig");
const p = core.p;
const u = @import("../validation/common.zig");

fn same(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}
fn named(v: u.Value, key: []const u8, path: []const u8) bool {
    if (v != .object) return false;
    const item = v.object.get(key) orelse return false;
    return if (item == .string) same(item.string, path) else core.eq(item, "path", path);
}
fn zigCommand(report: u.Value, argv: []const []const u8) bool {
    if (argv.len < 2) return false;
    const chain = core.get(report, "toolchain") catch .null;
    if (!same(std.fs.path.basename(argv[0]), "zig") and !named(report, "emitter", argv[0]) and
        !named(report, "frontend", argv[0]) and !named(chain, "zig_emitter", argv[0])) return false;
    return u.contains(&.{ "build", "test", "build-exe", "build-obj", "build-lib", "cc", "c++" }, argv[1]);
}
pub fn owned(run: []const u8, path: []const u8) bool {
    if (!p.candidate(run) or !p.candidate(path) or !p.within(run, path) or !p.commandCacheName(std.fs.path.basename(path))) return false;
    const parent = std.fs.path.dirname(path) orelse return false;
    if (same(parent, run)) return true;
    return same(std.fs.path.dirname(parent) orelse "", run) and
        u.contains(&.{ "Debug", "ReleaseFast", "ReleaseSafe", "ReleaseSmall" }, std.fs.path.basename(parent));
}

const Use = struct { path: []const u8, stdout: []const u8, stderr: []const u8 };
fn uses(e: *core.Engine, run: []const u8, report: u.Value, commands: p.Evidence) ![]const Use {
    if (!core.eq(report, "status", "passed") or !same(commands.path, try e.c.fmt("{s}/commands.json", .{run}))) return error.UnboundCommandCacheOwner;
    try e.check(commands);
    var parsed = try e.load(e.c.gpa, commands.path);
    defer parsed.deinit();
    if (parsed.value != .array or parsed.value.array.items.len == 0) return error.InvalidCacheCommands;
    var result: std.ArrayList(Use) = .empty;
    for (parsed.value.array.items) |command| {
        const argv = try u.stringSlice(e.c.a, try core.get(command, "argv"));
        var i: usize = 0;
        while (i < argv.len) : (i += 1) {
            if (!same(argv[i], "--cache-dir") and !same(argv[i], "--global-cache-dir")) continue;
            i += 1;
            if (i == argv.len or !std.fs.path.isAbsolute(argv[i])) return error.UnsupportedCacheArgument;
            const path = e.relative(argv[i]) catch continue;
            if (!owned(run, path)) continue;
            if (!zigCommand(report, argv)) return error.UnsupportedCacheTool;
            if (!core.eq(command, "outcome", "completed") or !core.has(command, "actual_returncode", .integer) or
                !core.has(command, "returncode", .integer) or
                try core.integer(command, "actual_returncode") != try core.integer(command, "returncode")) return error.CacheCommandNotClosed;
            // A passed parent may contain expected negative compile/link cases.
            // Preserve their original statuses and diagnostics outside the cache.
            try result.append(e.c.a, .{ .path = try e.c.a.dupe(u8, path), .stdout = try e.relative(try core.str(command, "stdout")), .stderr = try e.relative(try core.str(command, "stderr")) });
        }
    }
    return result.items;
}

pub fn verify(e: *core.Engine, a: core.Action, r: p.Release, report: u.Value, kept: *std.ArrayList(p.Evidence)) !void {
    if (r.state != .disposable or r.cache_owner != null or r.command_outputs != null or
        !same(r.producer.path, try e.c.fmt("{s}/report.json", .{r.run_root})) or !owned(r.run_root, a.path)) return error.UnboundCommandCacheOwner;
    for (r.artifacts) |artifact| if (artifact.kind != .private_cache) return error.UnboundCommandCacheOwner;
    const commands = r.command_caches orelse return error.UnboundCommandCacheOwner;
    try e.keep(kept, commands.path, commands.sha256);
    var matched = false;
    for (try uses(e, r.run_root, report, commands)) |use| {
        if (!same(use.path, a.path)) continue;
        matched = true;
        for ([_][]const u8{ use.stdout, use.stderr }) |log| {
            for (r.artifacts) |artifact| if (p.overlaps(artifact.path, log)) return error.RetentionOverlap;
            try @import("retired_logs.zig").keep(e, log, kept);
        }
    }
    if (!matched) return error.UnboundDisposableCache;
}

pub fn request(e: *core.Engine, report_path: []const u8, reason: []const u8) !p.Release {
    if (!p.candidate(report_path) or !same(std.fs.path.basename(report_path), "report.json") or u.trim(reason).len == 0) return error.UnboundCommandCacheOwner;
    const run = std.fs.path.dirname(report_path).?;
    const commands: p.Evidence = .{ .path = try e.c.fmt("{s}/commands.json", .{run}), .sha256 = try e.digest(try e.c.fmt("{s}/commands.json", .{run})) };
    var parsed = try e.load(e.c.gpa, report_path);
    defer parsed.deinit();
    var seen = std.StringHashMap(void).init(e.c.a);
    var artifacts: std.ArrayList(p.Artifact) = .empty;
    for (try uses(e, run, parsed.value, commands)) |use| {
        if (seen.contains(use.path)) continue;
        try seen.put(use.path, {});
        const m = e.metadata(use.path) catch |err| switch (err) {
            error.FileNotFound => continue,
            else => return err,
        };
        if (m.kind != .directory) return error.CacheNotDirectory;
        try artifacts.append(e.c.a, .{ .path = use.path, .kind = .private_cache });
    }
    if (artifacts.items.len == 0) return error.NoPresentCommandCaches;
    const result: p.Release = .{ .schema = "zllvm-storage-release-v1", .state = .disposable, .run_root = run, .reason = reason, .producer = .{ .path = report_path, .sha256 = try e.digest(report_path) }, .command_caches = commands, .retained = &.{}, .artifacts = artifacts.items };
    // Preparation checks every named cache's diagnostics too, before publication.
    var kept: std.ArrayList(p.Evidence) = .empty;
    for (result.artifacts) |artifact| try verify(e, .{ .path = artifact.path, .run_root = run, .producer = report_path, .kind = .cache }, result, parsed.value, &kept);
    return result;
}

pub fn prepare(e: *core.Engine, list: []const u8, reason: []const u8) !void {
    if (!p.relative(list)) return error.InvalidEvidencePath;
    try e.addControl(list);
    const bytes = try e.read(e.c.gpa, list, 4 * 1024 * 1024);
    defer e.c.gpa.free(bytes);
    var lines = std.mem.tokenizeScalar(u8, bytes, '\n');
    var requests: std.ArrayList(p.Evidence) = .empty;
    const Rejected = struct { producer: []const u8, reason: []const u8 };
    var rejected: std.ArrayList(Rejected) = .empty;
    var seen = std.StringHashMap(void).init(e.c.a);
    while (lines.next()) |path| {
        if (seen.count() >= 1024 or seen.contains(path)) return error.InvalidRequestList;
        const owned_path = try e.c.a.dupe(u8, path);
        try seen.put(owned_path, {});
        const r = request(e, owned_path, reason) catch |err| {
            try rejected.append(e.c.a, .{ .producer = owned_path, .reason = @errorName(err) });
            continue;
        };
        const destination = try e.c.fmt("{s}/request-{d}.json", .{ e.output, requests.items.len });
        try e.write(destination, r);
        try requests.append(e.c.a, .{ .path = destination, .sha256 = try e.digest(destination) });
    }
    try e.write(try e.c.fmt("{s}/command-cache-review.json", .{e.output}), .{ .prepared = requests.items.len, .rejected = rejected.items });
    if (requests.items.len != 0) try e.write(try e.c.fmt("{s}/requests.json", .{e.output}), @import("batch.zig").List{ .requests = requests.items });
    try e.c.print("Prepared {d} command-cache requests; {d} entries need review. No payloads changed.\n{s}/command-cache-review.json\n", .{ requests.items.len, rejected.items.len, e.output });
}
