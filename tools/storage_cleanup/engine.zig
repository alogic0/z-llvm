const std = @import("std");
const u = @import("../validation/common.zig");
const historical = @import("historical.zig");
pub const fa = @import("../vendor/file_audit/src/root.zig");
pub const p = @import("policy.zig");
const D = std.Io.Dir;
pub const Evidence = p.Evidence;
pub const Revision = struct { commit: []const u8, tree: []const u8, reference: []const u8 };
pub const PinReference = struct { candidate: []const u8, manifest: Evidence, reference: ?[]const u8, sha256: ?[]const u8, retired: bool };
const Observed = struct { metadata: fa.Metadata, sha256: []const u8 };
const Pin = struct { path: []const u8, direct: bool = false, sha256: ?[]const u8 = null };
const PinManifest = struct { metadata: fa.Metadata, targets: []const Pin };
const PinIndex = struct {
    roots: std.StringHashMap(usize),
    ancestors: std.StringHashMap(std.ArrayList(usize)),
};
const PinDirectory = struct { dir: ?D, canonical: []const u8 };
pub fn commandUsesRun(processes: []const u8, run_root: []const u8, collector_pid: std.os.linux.pid_t) bool {
    var lines = std.mem.tokenizeScalar(u8, processes, '\n');
    while (lines.next()) |line| {
        const trimmed = std.mem.trimStart(u8, line, " \t");
        const boundary = std.mem.indexOfAny(u8, trimmed, " \t") orelse continue;
        const pid = std.fmt.parseInt(std.os.linux.pid_t, trimmed[0..boundary], 10) catch {
            if (std.mem.indexOf(u8, trimmed, run_root) != null) return true;
            continue;
        };
        // Publishing a release names its own producer on this command line.
        // Ignore only this collector, never another reader or a parent job.
        if (pid != collector_pid and std.mem.indexOf(u8, trimmed[boundary..], run_root) != null) return true;
    }
    return false;
}
pub const Action = struct {
    path: []const u8,
    run_root: []const u8,
    producer: []const u8,
    kind: enum { cache, raw_trace, build_output, log },
    status: enum { discovered, ready, skipped, removed, absent } = .discovered,
    reason: ?[]const u8 = null,
    metadata: ?fa.Metadata = null,
    sha256: ?[]const u8 = null,
    retained: []const Evidence = &.{},
    snapshot: ?Evidence = null,
    snapshot_uncompressed_sha256: ?[]const u8 = null,
    allocated_bytes: u64 = 0,
    file_count: usize = 0,
    reclaimed_file_bytes: u64 = 0,
    measured: bool = false,
    idle_seconds: ?i64 = null,
    retired_pins: []const p.PinTransition = &.{},
};
pub const Engine = struct {
    c: *u.Context,
    config: p.Config,
    output: []const u8,
    zigrep: []const u8,
    now_ns: i128,
    actions: std.ArrayList(Action) = .empty,
    controls: std.ArrayList(Evidence) = .empty,
    held: std.ArrayList([]const u8) = .empty,
    checked_manifests: usize = 0,
    current_integrity_verified: bool = false,
    producer_reports: usize = 0,
    released_records: usize = 0,
    revisions: std.ArrayList(Revision) = .empty,
    collector_binary_sha256: ?[]const u8 = null,
    collector_sources: []const Evidence = &.{},
    control_hashes: std.StringHashMap([]const u8),
    hash_cache: std.AutoHashMap(fa.metadata.Identity, Observed),
    observed_reads: std.StringHashMap(Observed),
    pin_paths: ?*std.StringHashMap(void) = null,
    pin_parents: ?*std.StringHashMap(?PinDirectory) = null,
    pin_target_capacity: usize = 0,
    pin_open_directories: usize = 0,
    pin_manifests: std.StringHashMap(PinManifest),
    collecting_pins: ?*std.ArrayList(Pin) = null,
    pin_bases: ?*std.StringHashMap([]const []const u8) = null,
    pin_allocator: ?std.mem.Allocator = null,
    pin_index: ?*PinIndex = null,
    pin_hash: ?[]const u8 = null,
    pin_reference: ?[]const u8 = null,
    git_sources: std.StringHashMap(std.StringHashMap([]const u8)),
    libraries: std.ArrayList(historical.Library) = .empty,
    pin_references: std.ArrayList(PinReference) = .empty,
    retained_declarations: std.ArrayList([]const u8) = .empty,
    release_holds: std.ArrayList([]const u8) = .empty,

    pub fn init(c: *u.Context, config: p.Config, output: []const u8, zigrep: []const u8) Engine {
        return .{ .c = c, .config = config, .output = output, .zigrep = zigrep, .now_ns = std.Io.Clock.real.now(c.io).nanoseconds, .control_hashes = .init(c.a), .hash_cache = .init(c.a), .observed_reads = .init(c.a), .pin_manifests = .init(c.a), .git_sources = .init(c.a) };
    }
    pub fn absolute(e: *Engine, path: []const u8) ![]const u8 {
        return e.c.join(&.{path});
    }
    pub fn relative(e: *Engine, path: []const u8) ![]const u8 {
        var r = path;
        if (p.within(e.c.root, path) and path.len > e.c.root.len) r = path[e.c.root.len + 1 ..];
        if (!p.relative(r)) return error.NonCanonicalProjectPath;
        return e.c.a.dupe(u8, r);
    }
    pub fn metadata(e: *Engine, path: []const u8) !fa.Metadata {
        const abs = try e.absolute(path);
        var dir = try fa.metadata.openRoot(e.c.io, std.fs.path.dirname(abs).?);
        defer dir.close(e.c.io);
        return fa.metadata.child(e.c.gpa, dir, std.fs.path.basename(abs));
    }
    pub fn digest(e: *Engine, path: []const u8) ![]const u8 {
        const m = try e.metadata(path);
        if (m.kind != .file) return error.NotRegularFile;
        const abs = try e.absolute(path);
        if (e.observed_reads.get(abs)) |previous| if (!previous.metadata.eql(m)) return error.FileChanged;
        if (e.hash_cache.get(fa.metadata.identity(m))) |cached| {
            // An inode can be reused after deleting a different path. Parsed
            // controls are separately bound to their pathname observations.
            if (cached.metadata.eql(m)) return cached.sha256;
        }
        var dir = try fa.metadata.openRoot(e.c.io, std.fs.path.dirname(abs).?);
        defer dir.close(e.c.io);
        const sha = try e.c.a.dupe(u8, &std.fmt.bytesToHex(try fa.metadata.hashFile(e.c.gpa, e.c.io, dir, std.fs.path.basename(abs), m), .lower));
        if (e.observed_reads.get(abs)) |previous| if (!std.mem.eql(u8, previous.sha256, sha)) return error.FileChanged;
        try e.hash_cache.put(fa.metadata.identity(m), .{ .metadata = m, .sha256 = sha });
        return sha;
    }
    pub fn read(e: *Engine, allocator: std.mem.Allocator, path: []const u8, limit: usize) ![]u8 {
        const abs = try e.absolute(path);
        var dir = try fa.metadata.openRoot(e.c.io, std.fs.path.dirname(abs).?);
        defer dir.close(e.c.io);
        const name = std.fs.path.basename(abs);
        const m = try fa.metadata.child(e.c.gpa, dir, name);
        const bytes = try fa.metadata.readFile(allocator, e.c.io, dir, name, m, limit);
        errdefer allocator.free(bytes);
        const sha = try u.digestBytes(e.c.a, bytes);
        if (e.observed_reads.get(abs)) |old| if (!old.metadata.eql(m) or !std.mem.eql(u8, old.sha256, sha)) return error.FileChanged;
        if (e.hash_cache.get(fa.metadata.identity(m))) |old| if (old.metadata.eql(m) and !std.mem.eql(u8, old.sha256, sha)) return error.FileChanged;
        const observed: Observed = .{ .metadata = m, .sha256 = sha };
        try e.observed_reads.put(abs, observed);
        try e.hash_cache.put(fa.metadata.identity(m), observed);
        return bytes;
    }
    pub fn check(e: *Engine, row: Evidence) !void {
        if (!p.hash(row.sha256) or !std.mem.eql(u8, try e.digest(row.path), row.sha256)) return error.EvidenceHashMismatch;
    }
    pub fn load(e: *Engine, allocator: std.mem.Allocator, path: []const u8) !std.json.Parsed(u.Value) {
        const bytes = try e.read(allocator, path, 32 * 1024 * 1024);
        defer allocator.free(bytes);
        return std.json.parseFromSlice(u.Value, allocator, bytes, .{ .allocate = .alloc_always });
    }
    pub fn write(e: *Engine, path: []const u8, value: anytype) !void {
        const data = try std.json.Stringify.valueAlloc(e.c.gpa, value, .{});
        defer e.c.gpa.free(data);
        const abs = try e.absolute(path);
        try u.files.writeAtomic(e.c.io, .{ .path = abs, .replace = true }, &.{ data, "\n" });
        const file = try D.cwd().openFile(e.c.io, abs, .{});
        defer file.close(e.c.io);
        try file.sync(e.c.io);
        var dir = try fa.metadata.openRoot(e.c.io, std.fs.path.dirname(abs).?);
        defer dir.close(e.c.io);
        if (std.os.linux.errno(std.os.linux.fsync(dir.handle)) != .SUCCESS) return error.DirectorySyncFailed;
    }
    pub fn addControl(e: *Engine, path: []const u8) !void {
        const sha = try e.digest(path);
        if (e.control_hashes.get(path)) |old| {
            if (!std.mem.eql(u8, old, sha)) return error.ControlChanged;
            return;
        }
        const owned = try e.c.a.dupe(u8, path);
        try e.controls.append(e.c.a, .{ .path = owned, .sha256 = sha });
        try e.control_hashes.put(owned, sha);
    }
    pub fn keep(e: *Engine, list: *std.ArrayList(Evidence), raw: []const u8, expected: ?[]const u8) !void {
        const path = try e.c.a.dupe(u8, raw);
        const sha = try e.digest(path);
        if (expected) |want| if (!p.hash(want) or !std.mem.eql(u8, sha, want)) return error.EvidenceHashMismatch;
        for (list.items) |old| if (std.mem.eql(u8, path, old.path)) return;
        try list.append(e.c.a, .{ .path = path, .sha256 = sha });
    }
    pub fn oldEnough(e: *const Engine, m: fa.Metadata) bool {
        const latest = @max(m.mtime_ns, m.ctime_ns);
        return e.now_ns >= latest and e.now_ns - latest >= @as(i128, e.config.minimum_idle_hours) * 3600 * std.time.ns_per_s;
    }
    fn add(e: *Engine, path: []const u8, run: []const u8, producer: []const u8, kind: @FieldType(Action, "kind"), sha: ?[]const u8) !usize {
        if (!p.candidate(path)) return error.InvalidCandidateScope;
        for (e.actions.items, 0..) |*old, index| if (p.overlaps(path, old.path)) {
            if (std.mem.eql(u8, path, old.path) and std.mem.eql(u8, producer, old.producer) and kind == old.kind) return index;
            old.status = .skipped;
            old.reason = "overlapping or duplicate ownership declarations";
            return index;
        };
        try e.actions.append(e.c.a, .{ .path = try e.c.a.dupe(u8, path), .run_root = try e.c.a.dupe(u8, run), .producer = try e.c.a.dupe(u8, producer), .kind = kind, .sha256 = if (sha) |h| try e.c.a.dupe(u8, h) else null });
        return e.actions.items.len - 1;
    }
    pub fn discover(e: *Engine) !void {
        const names = try e.discoverPaths(&.{ "-g", "report.json", "-g", "storage-release.json" }, &.{"local-state/validations"});
        var lines = std.mem.tokenizeScalar(u8, names, '\n');
        while (lines.next()) |name| {
            const before = e.actions.items.len;
            if (std.mem.endsWith(u8, name, "/storage-release.json")) {
                e.released_records += 1;
                try e.discoverRelease(name, false);
            } else {
                e.producer_reports += 1;
                try e.discoverBuild(name);
            }
            _ = before;
        }
    }
    fn discoverBuild(e: *Engine, name: []const u8) !void {
        // Only this report family binds all source files to a preserved compiler.
        var parsed = try e.load(e.c.gpa, name);
        defer parsed.deinit();
        const v = parsed.value;
        if (!has(v, "source_root", .string) or !has(v, "source_sha256", .object) or !has(v, "compiler_sha256", .string) or !has(v, "commands", .array)) return;
        const run = std.fs.path.dirname(name).?;
        for ((try get(v, "commands")).array.items) |cmd| {
            if (!has(cmd, "argv", .array)) continue;
            const args = (try get(cmd, "argv")).array.items;
            for (args, 0..) |arg, i| {
                if (arg != .string or (!std.mem.eql(u8, arg.string, "--cache-dir") and !std.mem.eql(u8, arg.string, "--global-cache-dir"))) continue;
                if (i + 1 >= args.len or args[i + 1] != .string) return error.InvalidBuildCacheArgument;
                const path = e.relative(args[i + 1].string) catch continue;
                if (!p.cacheOwned(run, path)) continue;
                const m = e.metadata(path) catch |err| switch (err) {
                    error.FileNotFound => continue,
                    else => return err,
                };
                const index = try e.add(path, run, name, .cache, null);
                if (m.kind != .directory) {
                    const a = &e.actions.items[index];
                    a.status = .skipped;
                    a.reason = "cache path is not a directory";
                }
            }
        }
    }
    pub fn discoverRelease(e: *Engine, name: []const u8, staged: bool) !void {
        var parsed = try e.load(e.c.gpa, name);
        defer parsed.deinit();
        var r = try std.json.parseFromValue(p.Release, e.c.gpa, parsed.value, .{});
        defer r.deinit();
        if (!std.mem.eql(u8, r.value.schema, "zllvm-storage-release-v1")) return error.UnknownReleaseSchema;
        if (!p.candidate(r.value.run_root) or (!staged and !std.mem.eql(u8, std.fs.path.dirname(name).?, r.value.run_root)) or r.value.reason.len == 0) return error.InvalidReleaseScope;
        if (r.value.state == .held) {
            try e.release_holds.append(e.c.a, try e.c.a.dupe(u8, r.value.run_root));
            return;
        }
        var present = false;
        for (r.value.artifacts) |a| {
            if (!p.artifactName(a) or !p.within(r.value.run_root, a.path)) return error.InvalidReleaseArtifact;
            _ = e.metadata(a.path) catch |err| switch (err) {
                error.FileNotFound => continue,
                else => return err,
            };
            _ = try e.add(a.path, r.value.run_root, name, switch (a.kind) {
                .raw_trace => .raw_trace,
                .build_output => .build_output,
                .log => .log,
            }, a.sha256);
            present = true;
        }
        if (present) for (r.value.retained) |row| {
            if (!p.relative(row.path)) return error.InvalidEvidencePath;
            try e.retained_declarations.append(e.c.a, try e.c.a.dupe(u8, row.path));
        };
    }
    pub fn discoverPaths(e: *Engine, filters: []const []const u8, roots: []const []const u8) ![]const u8 {
        var args: std.ArrayList([]const u8) = .empty;
        try args.appendSlice(e.c.a, &.{ e.zigrep, "--no-config", "--files", "--hidden", "--no-ignore" });
        try args.appendSlice(e.c.a, filters);
        var roots_count: usize = 0;
        for (roots) |root| {
            _ = e.metadata(root) catch |err| switch (err) {
                error.FileNotFound => continue,
                else => return err,
            };
            try args.append(e.c.a, root);
            roots_count += 1;
        }
        if (roots_count == 0) return "";
        const result = try u.process.runReport(e.c.gpa, e.c.io, .{ .spawn = .{ .argv = args.items, .cwd = .{ .path = e.c.root }, .environ_map = &e.c.env, .search_path = true }, .timeout_ms = 120_000, .stdout_limit = 64 * 1024 * 1024, .stderr_limit = 1024 * 1024 });
        defer result.deinit(e.c.gpa);
        const no_matches = result.outcome == .completed and result.cleanup_failure == null and result.term != null and result.term.? == .exited and result.term.?.exited == 1;
        if (!result.success() and !no_matches) return e.c.fail("Discovery failed: {s}", .{result.stderr});
        return e.c.a.dupe(u8, result.stdout);
    }
    pub fn loadHolds(e: *Engine) !void {
        e.held.clearRetainingCapacity();
        for (e.config.protected_paths) |s| try e.held.append(e.c.a, s);
        try e.held.appendSlice(e.c.a, e.release_holds.items);
        if (e.metadata(e.config.holds_file)) |_| {
            try e.addControl(e.config.holds_file);
            var parsed = try e.load(e.c.gpa, e.config.holds_file);
            defer parsed.deinit();
            var h = try std.json.parseFromValue(p.Holds, e.c.gpa, parsed.value, .{});
            defer h.deinit();
            if (h.value.schema != 1) return error.InvalidHolds;
            for (h.value.paths) |path| {
                if (!p.relative(path)) return error.InvalidHolds;
                try e.held.append(e.c.a, try e.c.a.dupe(u8, path));
            }
        } else |err| if (err != error.FileNotFound) return err;
        const tsv = "docs/evidence/tmp_retention_pins.tsv";
        if (e.metadata(tsv)) |_| {
            try e.addControl(tsv);
            const text = try e.read(e.c.gpa, tsv, 4 * 1024 * 1024);
            defer e.c.gpa.free(text);
            var lines = std.mem.tokenizeScalar(u8, text, '\n');
            while (lines.next()) |line| {
                if (line.len == 0 or line[0] == '#') continue;
                const path = line[0 .. std.mem.indexOfScalar(u8, line, '\t') orelse line.len];
                if (p.relative(path)) try e.held.append(e.c.a, try e.c.a.dupe(u8, path));
            }
        } else |err| if (err != error.FileNotFound) return err;
        for (e.actions.items) |*a| for (e.held.items) |held| if (a.status != .removed and p.overlaps(held, a.path)) {
            a.status = .skipped;
            a.reason = try e.c.fmt("protected by hold: {s}", .{held});
            break;
        };
    }
    fn pinResolved(e: *Engine, path: []const u8, source: []const u8) !void {
        if (e.pin_index) |index| {
            if (index.ancestors.get(path)) |children| {
                for (children.items) |i| try e.markPinned(i, source);
                return;
            }
            var parent = std.fs.path.dirname(path);
            while (parent) |name| {
                if (index.roots.get(name)) |i| {
                    try e.markPinned(i, source);
                    return;
                }
                parent = std.fs.path.dirname(name);
            }
            return;
        }
        for (e.actions.items) |*a| if (a.status != .removed and p.overlaps(a.path, path)) {
            if (e.transitioned(a.*, source)) continue;
            a.status = .skipped;
            a.reason = try e.c.fmt("pinned by {s}", .{source});
        };
    }
    fn markPinned(e: *Engine, i: usize, source: []const u8) !void {
        const a = &e.actions.items[i];
        var recorded = false;
        for (e.pin_references.items) |old| if (std.mem.eql(u8, old.candidate, a.path) and std.mem.eql(u8, old.manifest.path, source) and
            std.mem.eql(u8, old.reference orelse "", e.pin_reference orelse ""))
        {
            recorded = true;
            break;
        };
        if (!recorded) try e.pin_references.append(e.c.a, .{ .candidate = a.path, .manifest = .{ .path = try e.c.a.dupe(u8, source), .sha256 = try e.digest(source) }, .reference = if (e.pin_reference) |r| try e.c.a.dupe(u8, r) else null, .sha256 = if (e.pin_hash) |h| try e.c.a.dupe(u8, h) else null, .retired = e.transitioned(a.*, source) });
        if (a.status != .discovered and a.status != .ready) return;
        if (e.transitioned(a.*, source)) return;
        a.status = .skipped;
        a.reason = try e.c.fmt("pinned by {s}", .{source});
    }
    fn transitioned(e: *Engine, a: Action, manifest: []const u8) bool {
        if (a.status != .ready) return false;
        const sha = e.pin_hash orelse return false;
        const reference = e.pin_reference orelse return false;
        for (a.retired_pins) |r| {
            if (std.mem.eql(u8, manifest, r.manifest.path) and std.mem.eql(u8, reference, r.reference) and
                std.mem.eql(u8, a.path, r.target.path) and std.ascii.eqlIgnoreCase(sha, r.target.sha256)) return true;
        }
        return false;
    }
    fn pinHash(e: *Engine, raw: []const u8, source: []const u8, sha: ?[]const u8) !void {
        const previous_hash = e.pin_hash;
        const previous_reference = e.pin_reference;
        e.pin_hash = sha;
        e.pin_reference = raw;
        defer {
            e.pin_hash = previous_hash;
            e.pin_reference = previous_reference;
        }
        try e.pin(raw, source);
    }
    // Cache missing directory prefixes, not millions of speculative missing
    // leaves. This cache lasts ONE pin pass, so a newly created alias is seen
    // on the next refresh. Resolving existing leaves remains mandatory.
    fn pinDirectory(e: *Engine, path: []const u8) anyerror!?PinDirectory {
        const parents = e.pin_parents.?;
        if (parents.get(path)) |cached| return cached;
        if (!std.mem.eql(u8, path, "/")) {
            if (try e.pinDirectory(std.fs.path.dirname(path) orelse "/") == null) return null;
        }
        var dir = D.openDirAbsolute(e.c.io, path, .{}) catch |err| switch (err) {
            error.FileNotFound, error.NotDir => {
                try parents.put(try e.c.gpa.dupe(u8, path), null);
                return null;
            },
            else => return err,
        };
        errdefer dir.close(e.c.io);
        const canonical = try e.pinRealPath(dir, ".");
        errdefer e.c.gpa.free(canonical);
        const keep_open = e.pin_open_directories < 128;
        const result: PinDirectory = .{ .dir = if (keep_open) dir else null, .canonical = canonical };
        try parents.put(try e.c.gpa.dupe(u8, path), result);
        if (keep_open) e.pin_open_directories += 1 else dir.close(e.c.io);
        return result;
    }
    fn pinParentExists(e: *Engine, path: []const u8) !bool {
        if (e.pin_parents == null) return true;
        return try e.pinDirectory(path) != null;
    }
    fn pinCanonical(e: *Engine, absolute_path: []const u8, source: []const u8) !void {
        if (e.pin_paths) |seen| {
            if (seen.contains(absolute_path)) return;
        }
        const canonical = e.resolvePin(absolute_path) catch |err| switch (err) {
            error.FileNotFound, error.NotDir => return,
            else => return err,
        };
        defer e.c.gpa.free(canonical);
        // A target still eligible after an exempted historical reference must
        // be checked again if another manifest references it. Irrelevant or
        // already held targets remain reusable across manifests in this pass.
        var reusable = true;
        if (p.within(e.c.root, canonical) and canonical.len > e.c.root.len) {
            const relative_target = canonical[e.c.root.len + 1 ..];
            reusable = !e.indexedOverlap(relative_target);
        }
        if (reusable) if (e.pin_paths) |seen| {
            // Cache only existing targets. Speculative ancestor resolutions
            // often do not exist and otherwise dominate memory on old ledgers.
            const owned = try e.c.gpa.dupe(u8, absolute_path);
            errdefer e.c.gpa.free(owned);
            try seen.put(owned, {});
        };
        if (std.mem.eql(u8, canonical, e.c.root)) return e.pinResolved("local-state/validations", source);
        // The lexical path was already tested by pin(). Only aliases need a
        // second lookup. Parent descriptors are discarded at every refresh.
        if (std.mem.eql(u8, canonical, absolute_path)) return;
        if (p.within(e.c.root, canonical) and canonical.len > e.c.root.len) try e.pinResolved(canonical[e.c.root.len + 1 ..], source);
    }
    fn indexedOverlap(e: *Engine, path: []const u8) bool {
        if (e.pin_index) |index| {
            if (index.ancestors.contains(path)) return true;
            var parent = std.fs.path.dirname(path);
            while (parent) |name| {
                if (index.roots.contains(name)) return true;
                parent = std.fs.path.dirname(name);
            }
            return false;
        }
        for (e.actions.items) |action| if (p.overlaps(action.path, path)) return true;
        return false;
    }
    fn resolvePin(e: *Engine, path: []const u8) ![]const u8 {
        if (e.pin_parents == null) return e.pinRealPath(D.cwd(), path);
        const parent = (try e.pinDirectory(std.fs.path.dirname(path) orelse "/")) orelse return error.FileNotFound;
        var directory = parent.dir orelse try D.openDirAbsolute(e.c.io, std.fs.path.dirname(path) orelse "/", .{});
        defer if (parent.dir == null) directory.close(e.c.io);
        if (parent.dir == null) {
            const canonical = try directory.realPathFileAlloc(e.c.io, ".", e.c.gpa);
            defer e.c.gpa.free(canonical);
            if (!std.mem.eql(u8, canonical, parent.canonical)) return error.PinDirectoryChanged;
        }
        const name = std.fs.path.basename(path);
        if (name.len == 0 or std.mem.eql(u8, path, "/")) return e.c.gpa.dupe(u8, "/");
        const m = try fa.metadata.child(e.c.gpa, directory, name);
        if (m.kind == .symlink) return e.pinRealPath(directory, name);
        return std.fs.path.join(e.c.gpa, &.{ parent.canonical, name });
    }
    fn pinRealPath(e: *Engine, dir: D, path: []const u8) ![]const u8 {
        const terminated = try dir.realPathFileAlloc(e.c.io, path, e.c.gpa);
        defer e.c.gpa.free(terminated);
        return e.c.gpa.dupe(u8, terminated);
    }
    pub fn pin(e: *Engine, raw: []const u8, source: []const u8) !void {
        if (e.collecting_pins) |list| {
            try list.append(e.c.a, .{ .path = try e.c.a.dupe(u8, raw), .sha256 = if (e.pin_hash) |h| try e.c.a.dupe(u8, h) else null });
            return;
        }
        if (std.fs.path.isAbsolute(raw)) {
            if (e.pin_paths) |seen| if (seen.contains(raw)) return;
            if (p.within(e.c.root, raw) and raw.len > e.c.root.len) try e.pinResolved(raw[e.c.root.len + 1 ..], source);
            try e.pinCanonical(raw, source);
            return;
        }
        // Most ledgers contain canonical project-relative paths. Resolve only
        // ancestor bases in which the first component exists (or can overlap
        // a candidate). Missing-prefix knowledge is shared across a manifest,
        // and rebuilt for every refresh, including after each removal.
        if (p.relative(raw) and e.pin_bases != null and std.mem.indexOfScalar(u8, raw, '/') != null) {
            const allocator = e.pin_allocator.?;
            const first = raw[0..std.mem.indexOfScalar(u8, raw, '/').?];
            const source_parent = std.fs.path.dirname(source) orelse ".";
            const key = try std.fmt.allocPrint(e.c.gpa, "{s}\n{s}", .{ source_parent, first });
            defer e.c.gpa.free(key);
            var bases: []const []const u8 = undefined;
            if (e.pin_bases.?.get(key)) |cached| {
                bases = cached;
            } else {
                var list: std.ArrayList([]const u8) = .empty;
                var parent = source_parent;
                while (true) {
                    const base = try std.fs.path.resolve(allocator, &.{ e.c.root, parent });
                    const prefix = try std.fs.path.join(e.c.gpa, &.{ base, first });
                    defer e.c.gpa.free(prefix);
                    var relevant = false;
                    if (p.within(e.c.root, prefix) and prefix.len > e.c.root.len) {
                        const rel = prefix[e.c.root.len + 1 ..];
                        for (e.actions.items) |a| if (p.overlaps(a.path, rel)) {
                            relevant = true;
                            break;
                        };
                    }
                    if (relevant or try e.pinParentExists(prefix)) try list.append(allocator, base);
                    if (std.mem.eql(u8, parent, ".")) break;
                    parent = std.fs.path.dirname(parent) orelse ".";
                }
                bases = try list.toOwnedSlice(allocator);
                try e.pin_bases.?.put(try allocator.dupe(u8, key), bases);
            }
            for (bases) |base| {
                const absolute_path = try std.fs.path.join(e.c.gpa, &.{ base, raw });
                defer e.c.gpa.free(absolute_path);
                if (e.pin_paths) |seen| if (seen.contains(absolute_path)) continue;
                if (p.within(e.c.root, absolute_path) and absolute_path.len > e.c.root.len) try e.pinResolved(absolute_path[e.c.root.len + 1 ..], source);
                try e.pinCanonical(absolute_path, source);
            }
            return;
        }
        if (p.relative(raw)) try e.pinResolved(raw, source);
        var parent = std.fs.path.dirname(source) orelse ".";
        while (true) {
            const absolute_path = try std.fs.path.resolve(e.c.gpa, &.{ e.c.root, parent, raw });
            defer e.c.gpa.free(absolute_path);
            if (p.within(e.c.root, absolute_path) and absolute_path.len > e.c.root.len) try e.pinResolved(absolute_path[e.c.root.len + 1 ..], source);
            try e.pinCanonical(absolute_path, source);
            if (std.mem.eql(u8, parent, ".")) break;
            parent = std.fs.path.dirname(parent) orelse ".";
        }
    }
    fn jsonPins(e: *Engine, v: u.Value, source: []const u8) anyerror!void {
        switch (v) {
            .object => {
                if (v.object.get("path")) |path| if (path == .string) try e.pinHash(path.string, source, str(v, "sha256") catch null);
                var it = v.object.iterator();
                while (it.next()) |kv| try e.jsonPins(kv.value_ptr.*, source);
            },
            .array => for (v.array.items) |item| try e.jsonPins(item, source),
            else => {},
        }
    }
    pub fn pins(e: *Engine) !void {
        // Repeated references resolve once per pass. A fresh map on every
        // refresh still observes newly changed symlink aliases before mutation.
        var seen = std.StringHashMap(void).init(e.c.gpa);
        try seen.ensureTotalCapacity(@intCast(e.pin_target_capacity));
        var parents = std.StringHashMap(?PinDirectory).init(e.c.gpa);
        e.pin_open_directories = 0;
        var arena = std.heap.ArenaAllocator.init(e.c.gpa);
        defer arena.deinit();
        var bases = std.StringHashMap([]const []const u8).init(arena.allocator());
        var index: PinIndex = .{ .roots = .init(arena.allocator()), .ancestors = .init(arena.allocator()) };
        for (e.actions.items, 0..) |a, i| {
            if (a.status != .discovered and a.status != .ready) continue;
            try index.roots.put(a.path, i);
            var parent: ?[]const u8 = a.path;
            while (parent) |name| {
                const entry = try index.ancestors.getOrPut(name);
                if (!entry.found_existing) entry.value_ptr.* = .empty;
                try entry.value_ptr.append(arena.allocator(), i);
                parent = std.fs.path.dirname(name);
            }
        }
        e.pin_index = &index;
        e.pin_bases = &bases;
        e.pin_allocator = arena.allocator();
        e.pin_paths = &seen;
        e.pin_parents = &parents;
        defer {
            e.pin_paths = null;
            e.pin_parents = null;
            e.pin_bases = null;
            e.pin_allocator = null;
            e.pin_index = null;
            e.pin_target_capacity = seen.count();
            var keys = seen.keyIterator();
            while (keys.next()) |key| e.c.gpa.free(key.*);
            seen.deinit();
            var parent_it = parents.iterator();
            while (parent_it.next()) |entry| {
                e.c.gpa.free(entry.key_ptr.*);
                if (entry.value_ptr.*) |directory| {
                    if (directory.dir) |dir| dir.close(e.c.io);
                    e.c.gpa.free(directory.canonical);
                }
            }
            parents.deinit();
        }
        const discovered = try e.discoverPaths(&.{ "-g", "*.sha256", "-g", "*.SHA256SUMS", "-g", "SHA256SUMS", "-g", "record.json", "-g", "record-*.json", "-g", "artifact-manifest.json" }, &.{ "docs", "local-state/validations", "local-state/retirements", "local-state/artifacts/manifests" });
        // Required current manifests are pins regardless of name or location.
        const listing = try e.c.fmt("{s}\n{s}", .{ discovered, try std.mem.join(e.c.a, "\n", e.config.current_manifests) });
        var lines = std.mem.tokenizeScalar(u8, listing, '\n');
        e.checked_manifests = 0;
        while (lines.next()) |path| {
            if (p.within(e.output, path)) continue;
            var retired_manifest = false;
            for (e.config.retired_manifests) |retired| if (std.mem.eql(u8, path, retired.path)) {
                try e.check(retired);
                retired_manifest = true;
                break;
            };
            if (retired_manifest) continue;
            const m = try e.metadata(path);
            if (e.pin_manifests.get(path)) |cached| {
                if (!cached.metadata.eql(m)) return error.PinManifestChanged;
                for (cached.targets) |target| {
                    if (target.direct) try e.pinResolved(target.path, path) else try e.pinHash(target.path, path, target.sha256);
                }
                e.checked_manifests += 1;
                continue;
            }
            const bytes = try e.read(e.c.gpa, path, 512 * 1024 * 1024);
            defer e.c.gpa.free(bytes);
            var targets: std.ArrayList(Pin) = .empty;
            e.collecting_pins = &targets;
            defer e.collecting_pins = null;
            if (std.mem.endsWith(u8, path, ".json")) {
                var parsed = try std.json.parseFromSlice(u.Value, e.c.gpa, bytes, .{});
                defer parsed.deinit();
                const v = parsed.value;
                if (std.mem.endsWith(u8, path, "/record.json") or std.mem.startsWith(u8, std.fs.path.basename(path), "record-")) {
                    if (eq(v, "status", "complete")) {
                        if (v.object.get("retained")) |rows| try e.jsonPins(rows, path);
                    } else try e.jsonPins(v, path);
                } else if (has(v, "root", .string) and has(v, "files", .object)) {
                    var it = (try get(v, "files")).object.iterator();
                    while (it.next()) |kv| try e.pinHash(try e.c.fmt("{s}/{s}", .{ try str(v, "root"), kv.key_ptr.* }), path, if (kv.value_ptr.* == .string) kv.value_ptr.string else null);
                }
            } else {
                var entries = std.mem.tokenizeScalar(u8, bytes, '\n');
                while (entries.next()) |raw| {
                    const line = std.mem.trimStart(u8, raw, " \t");
                    if (std.mem.trim(u8, line, " \t\r").len == 0 or line[0] == '#') continue;
                    if (std.mem.indexOfScalar(u8, line, '\r') != null or std.mem.indexOfScalar(u8, line, 0) != null) return error.UnsupportedChecksumPathEncoding;
                    if (checksumHash(std.mem.trim(u8, line, " \t"))) {
                        // Historical fingerprints contain a bare digest, with
                        // no named file. Hold their entire containing run.
                        try targets.append(e.c.a, .{ .path = try e.c.a.dupe(u8, std.fs.path.dirname(path) orelse "local-state/validations"), .direct = true });
                    } else if (line.len >= 66 and checksumHash(line[0..64]) and (line[64] == ' ' or line[64] == '\t')) {
                        var target = std.mem.trimStart(u8, line[64..], " \t");
                        if (target.len > 0 and target[0] == '*') target = target[1..];
                        if (target.len == 0) return error.EmptyChecksumPath;
                        try e.pinHash(target, path, line[0..64]);
                    } else if (std.mem.startsWith(u8, line, "SHA256 (") and line.len > 76 and checksumHash(line[line.len - 64 ..]) and std.mem.eql(u8, line[line.len - 68 .. line.len - 64], ") = ")) {
                        try e.pinHash(line[8 .. line.len - 68], path, line[line.len - 64 ..]);
                    } else return e.c.fail("Unrecognized checksum manifest entry in {s}; retaining candidates until the format is reviewed.", .{path});
                }
            }
            e.collecting_pins = null;
            const owned_targets = try targets.toOwnedSlice(e.c.a);
            try e.pin_manifests.put(try e.c.a.dupe(u8, path), .{ .metadata = m, .targets = owned_targets });
            for (owned_targets) |target| {
                if (target.direct) try e.pinResolved(target.path, path) else try e.pinHash(target.path, path, target.sha256);
            }
            e.checked_manifests += 1;
        }
    }
    pub fn currentManifests(e: *Engine, verify: bool) !void {
        e.current_integrity_verified = false;
        for (e.config.current_manifests) |path| {
            try e.addControl(path);
            if (verify) _ = try e.c.capture(&.{ "sha256sum", "--check", "--quiet", "--strict", "--", path });
        }
        e.current_integrity_verified = verify;
    }
    pub fn hasReady(e: *const Engine) bool {
        for (e.actions.items) |a| if (a.status == .ready) return true;
        return false;
    }
    pub fn applyLimits(e: *Engine) void {
        var admitted: usize = 0;
        var bytes: u64 = 0;
        for (e.actions.items) |*a| {
            if (a.status != .ready) continue;
            if (admitted >= e.config.max_candidates) {
                a.status = .skipped;
                a.reason = "per-run candidate limit";
            } else if (a.allocated_bytes > e.config.max_reclaim_bytes - bytes) {
                a.status = .skipped;
                a.reason = "per-run allocated-byte limit";
            } else {
                admitted += 1;
                bytes += a.allocated_bytes;
            }
        }
    }
    pub fn consumers(e: *Engine) !void {
        const listing = try e.c.capture(&.{ "lsof", "-nP", "-u", try e.c.fmt("{d}", .{std.os.linux.getuid()}), "-Fn" });
        const processes = try e.c.capture(&.{ "ps", "-eo", "pid,args" });
        for (e.actions.items) |*a| {
            if (a.status == .removed or a.status == .absent or a.status == .skipped) continue;
            const absolute_run = try e.absolute(a.run_root);
            var busy = commandUsesRun(processes, a.run_root, std.os.linux.getpid());
            var lines = std.mem.tokenizeScalar(u8, listing, '\n');
            while (lines.next()) |line| if (line.len > 1 and line[0] == 'n' and p.within(absolute_run, line[1..])) {
                busy = true;
                break;
            };
            if (busy) {
                a.status = .skipped;
                a.reason = "active command, working directory, mapping or open descriptor in this run";
            }
        }
    }
    fn closedCache(e: *Engine, a: Action, list: *std.ArrayList(Evidence)) !void {
        var parsed = try e.load(e.c.gpa, a.producer);
        defer parsed.deinit();
        const v = parsed.value;
        if (!eq(v, "status", "passed")) return error.ProducerNotSuccessful;
        const commands = try get(v, "commands");
        if (commands != .array or commands.array.items.len == 0) return error.MissingBuildCommand;
        var bound = false;
        for (commands.array.items) |command| {
            if (!eq(command, "outcome", "completed") or try integer(command, "actual_returncode") != 0) return error.IncompleteBuildCommand;
            const argv = try get(command, "argv");
            if (argv != .array) return error.MissingBuildCommand;
            for (argv.array.items, 0..) |arg, i| {
                if (arg != .string) return error.MissingBuildCommand;
                if (!std.mem.eql(u8, arg.string, "--cache-dir") and !std.mem.eql(u8, arg.string, "--global-cache-dir")) continue;
                if (i + 1 >= argv.array.items.len or argv.array.items[i + 1] != .string) return error.InvalidBuildCacheArgument;
                if (std.mem.eql(u8, try e.relative(argv.array.items[i + 1].string), a.path)) bound = true;
            }
        }
        if (!bound or !p.cacheOwned(a.run_root, a.path)) return error.UnboundDisposableCache;
        try e.keep(list, a.producer, null);
    }
    pub fn buildEvidence(e: *Engine, report: []const u8, list: *std.ArrayList(Evidence), retiring: ?[]const u8, reconstructions: []const Evidence) !void {
        var parsed = try e.load(e.c.gpa, report);
        defer parsed.deinit();
        const v = parsed.value;
        if (eq(v, "schema", "zllvm-compiler-build-v1")) return historical.canonical(e, report, v, list, retiring, reconstructions);
        if (!eq(v, "status", "passed")) return error.ProducerNotSuccessful;
        try e.sourceRevisions(v);
        const source = try e.relative(try str(v, "source_root"));
        const compiler = try e.relative(try str(v, "compiler"));
        try e.keep(list, report, null);
        const compiler_hash = try str(v, "compiler_sha256");
        try e.check(.{ .path = compiler, .sha256 = compiler_hash });
        if (retiring == null or !std.mem.eql(u8, retiring.?, compiler)) try e.keep(list, compiler, compiler_hash);
        const hashes = try get(v, "source_sha256");
        if (hashes != .object or hashes.object.count() == 0) return error.MissingSourceEvidence;
        var it = hashes.object.iterator();
        while (it.next()) |entry| {
            if (!p.relative(entry.key_ptr.*) or entry.value_ptr.* != .string) return error.InvalidSourceEvidence;
            try e.keep(list, try e.c.fmt("{s}/{s}", .{ source, entry.key_ptr.* }), entry.value_ptr.string);
        }
        try e.keep(list, try str(v, "zig"), try str(v, "zig_sha256"));
        const commands = try get(v, "commands");
        if (commands != .array or commands.array.items.len == 0) return error.MissingBuildCommand;
        var bound = false;
        for (commands.array.items) |cmd| {
            if (!eq(cmd, "outcome", "completed") or try integer(cmd, "actual_returncode") != 0) return error.IncompleteBuildCommand;
            const argv = try get(cmd, "argv");
            if (argv != .array) return error.MissingBuildCommand;
            var input_bound = false;
            var output_bound = false;
            for (argv.array.items) |arg| {
                if (arg != .string) return error.MissingBuildCommand;
                if (std.mem.startsWith(u8, arg.string, "-Mroot=")) {
                    const src = try e.relative(arg.string[7..]);
                    input_bound = p.within(source, src);
                }
                if (std.mem.startsWith(u8, arg.string, "-femit-bin=")) output_bound = std.mem.eql(u8, try e.relative(arg.string[11..]), compiler);
            }
            bound = bound or (input_bound and output_bound);
            try e.keep(list, try str(cmd, "stdout"), null);
            try e.keep(list, try str(cmd, "stderr"), null);
        }
        if (!bound) return error.SourceCompilerCommandNotBound;
    }
    fn releaseEvidence(e: *Engine, a: *Action, list: *std.ArrayList(Evidence)) !void {
        var parsed = try e.load(e.c.gpa, a.producer);
        defer parsed.deinit();
        var rp = try std.json.parseFromValue(p.Release, e.c.gpa, parsed.value, .{});
        defer rp.deinit();
        const r = rp.value;
        if (r.state == .held) return error.ReleaseHeld;
        for ([_]Evidence{r.producer}) |ev| {
            if (!p.relative(ev.path)) return error.InvalidEvidencePath;
            try e.keep(list, ev.path, ev.sha256);
        }
        var producer = try e.load(e.c.gpa, r.producer.path);
        defer producer.deinit();
        if (r.state == .disposable) {
            // Closed ordinary binaries/objects are temporary outputs. Source
            // reconstruction is not a prerequisite for discarding them.
            // Active use, pins, ownership and exact artifact checks still apply.
            if (a.kind != .build_output) return error.DisposableOnlyBuildOutputs;
            for (r.artifacts) |artifact| if (artifact.kind != .build_output) return error.DisposableOnlyBuildOutputs;
            if (!p.within(r.run_root, r.producer.path)) return error.UnboundDisposableProducer;
            if (eq(producer.value, "schema", "zllvm-compiler-build-v1")) {
                const command = try get(producer.value, "command");
                if (!eq(command, "outcome", "completed") or try integer(command, "actual_returncode") != 0) return error.ProducerNotTerminal;
            } else if (!eq(producer.value, "status", "passed") and !eq(producer.value, "status", "finished") and
                !eq(producer.value, "status", "complete") and !eq(producer.value, "status", "failed")) return error.ProducerNotTerminal;
            for (r.retained) |row| {
                if (!p.relative(row.path)) return error.InvalidEvidencePath;
                for (r.artifacts) |artifact| if (p.overlaps(artifact.path, row.path)) return error.RetentionOverlap;
                try e.keep(list, row.path, row.sha256);
            }
            try e.releaseTransitions(a, list, r);
            try e.keep(list, a.producer, null);
            return;
        }
        try e.sourceRevisions(producer.value);
        const canonical_producer = eq(producer.value, "schema", "zllvm-compiler-build-v1");
        if (!canonical_producer and !eq(producer.value, "status", "finished") and !eq(producer.value, "status", "passed") and !eq(producer.value, "status", "complete")) return error.ProducerNotTerminal;
        if (canonical_producer) try e.buildEvidence(r.producer.path, list, if (a.kind == .build_output) a.path else null, r.source_reconstructions);
        if (r.state == .superseded) {
            const next = r.successor orelse return error.NoAcceptedSuccessor;
            if (!p.relative(next.path)) return error.InvalidEvidencePath;
            try e.keep(list, next.path, next.sha256);
            var successor = try e.load(e.c.gpa, next.path);
            defer successor.deinit();
            if (std.mem.eql(u8, r.producer.path, next.path) or !eq(successor.value, "status", "passed")) return error.NoAcceptedSuccessor;
        } else {
            // A complete audit can replace raw tracing detail even for a
            // failed compilation. It never authorizes deleting other outputs.
            for (r.artifacts) |artifact| if (artifact.kind != .raw_trace) return error.AuditedReleaseOnlyTraces;
        }
        var roles: std.EnumSet(@FieldType(p.Retained, "role")) = .empty;
        for (r.retained) |row| {
            if (!p.relative(row.path)) return error.InvalidEvidencePath;
            for (r.artifacts) |artifact| if (p.overlaps(artifact.path, row.path)) return error.RetentionOverlap;
            try e.keep(list, row.path, row.sha256);
            roles.insert(row.role);
        }
        for ([_]@FieldType(p.Retained, "role"){ .source, .input, .build, .result }) |role| if (!roles.contains(role)) return error.MissingRetentionRole;
        // A label alone is not source reconstruction: verify the complete build
        // source map and command/output binding through the same cache rule.
        for (r.retained) |row| if (row.role == .build) try e.buildEvidence(row.path, list, if (a.kind == .build_output) a.path else null, r.source_reconstructions);
        if (!canonical_producer and !eq(producer.value, "status", "passed") and !roles.contains(.diagnostic)) return error.MissingFailureEvidence;
        for (r.source_reconstructions) |ev| try e.keep(list, ev.path, ev.sha256);
        try e.releaseTransitions(a, list, r);
        try e.keep(list, a.producer, null);
        if (a.kind == .raw_trace) {
            if (!roles.contains(.audit) or !roles.contains(.compiler)) return error.MissingTraceReplayEvidence;
            var artifact: ?p.Artifact = null;
            for (r.artifacts) |item| if (std.mem.eql(u8, item.path, a.path)) {
                artifact = item;
                break;
            };
            const audit_path = (artifact orelse return error.ReleaseArtifactMissing).audit orelse return error.MissingTraceAudit;
            var found = false;
            for (r.retained) |ev| if (ev.role == .audit and std.mem.eql(u8, ev.path, audit_path)) {
                found = true;
                break;
            };
            if (!found) return error.UnboundTraceAudit;
            var trace = try e.load(e.c.gpa, audit_path);
            defer trace.deinit();
            const v = trace.value;
            try e.sourceRevisions(v);
            if (!eq(v, "schema", "zllvm-native-event-audit-v1") or !eq(v, "status", "verified") or !eq(v, "path", a.path) or !eq(v, "sha256", a.sha256.?)) return error.TraceAuditMismatch;
            for ([_][]const u8{ "whole_stream_read", "whole_stream_semantically_valid", "report_binding_verified", "complete", "stream_metadata_unchanged", "recorded_hash_matches" }) |key| if (!try boolean(v, key)) return error.IncompleteTraceAudit;
            for ([_][]const u8{ "producer", "backend_report", "top_report", "input" }) |key| {
                const bound = try get(v, key);
                const path = try e.relative(try str(bound, "path"));
                const sha = try str(bound, "sha256");
                var kept = false;
                for (r.retained) |ev| if (std.mem.eql(u8, ev.path, path) and std.mem.eql(u8, ev.sha256, sha)) {
                    kept = true;
                    break;
                };
                if (!kept) return error.MissingTraceBoundEvidence;
            }
            // Bind the replay compiler to the audited run, not just any build.
            var top = try e.load(e.c.gpa, try str(try get(v, "top_report"), "path"));
            defer top.deinit();
            const backend = try get(top.value, "backend");
            const compiler = try e.relative(try str(backend, "path"));
            const compiler_sha = try str(backend, "sha256");
            var bound_build = false;
            for (r.retained) |row| if (row.role == .build) {
                var build = try e.load(e.c.gpa, row.path);
                defer build.deinit();
                if (std.mem.eql(u8, compiler, try e.relative(try str(build.value, "compiler"))) and eq(build.value, "compiler_sha256", compiler_sha)) bound_build = true;
            };
            if (!bound_build) return error.TraceCompilerBuildMismatch;
            for ([_][]const u8{ "core", "driver" }) |key| {
                const source = try str(v, try e.c.fmt("{s}_source", .{key}));
                const sha = try str(v, try e.c.fmt("{s}_sha256", .{key}));
                try e.keep(list, source, sha);
            }
        }
    }
    fn releaseTransitions(e: *Engine, a: *Action, list: *std.ArrayList(Evidence), r: p.Release) !void {
        for (r.retired_pins) |transition| {
            if (!p.relative(transition.manifest.path) or !p.hash(transition.manifest.sha256) or
                transition.reference.len == 0 or transition.reason.len == 0) return error.InvalidPinTransition;
            for (e.config.current_manifests) |current| if (std.mem.eql(u8, current, transition.manifest.path)) return error.CurrentManifestCannotBeRetired;
            var matches = false;
            for (r.artifacts) |artifact| if (std.mem.eql(u8, artifact.path, transition.target.path) and std.mem.eql(u8, artifact.sha256, transition.target.sha256)) {
                matches = true;
                break;
            };
            if (!matches) return error.PinTransitionNotAnArtifact;
            try e.keep(list, transition.manifest.path, transition.manifest.sha256);
        }
        a.retired_pins = (try std.json.parseFromSlice([]const p.PinTransition, e.c.a, try std.json.Stringify.valueAlloc(e.c.a, r.retired_pins, .{}), .{ .allocate = .alloc_always })).value;
    }
    pub fn qualify(e: *Engine, index: usize) !void {
        const a = &e.actions.items[index];
        if (a.status != .discovered) return;
        const m = try e.metadata(a.path);
        a.metadata = m;
        if (m.uid != std.os.linux.getuid()) return error.ForeignOwner;
        const producer_metadata = try e.metadata(a.producer);
        a.idle_seconds = @intCast(@divFloor(e.now_ns - @max(@max(m.mtime_ns, m.ctime_ns), @max(producer_metadata.mtime_ns, producer_metadata.ctime_ns)), std.time.ns_per_s));
        if (!e.oldEnough(m) or !e.oldEnough(producer_metadata)) return error.TooRecent;
        var kept: std.ArrayList(Evidence) = .empty;
        if (a.kind == .cache) {
            if (e.config.cache_evidence == .closed_producer) try e.closedCache(a.*, &kept) else try e.buildEvidence(a.producer, &kept, null, &.{});
        } else try e.releaseEvidence(a, &kept);
        const absolute_candidate = try e.absolute(a.path);
        for (kept.items) |ev| {
            const abs = try e.absolute(ev.path);
            if (p.within(absolute_candidate, abs)) return error.RetentionOverlap;
        }
        a.retained = try kept.toOwnedSlice(e.c.a);
        a.metadata = m;
        if (a.kind == .cache) {
            var snap = try fa.scan(e.c.gpa, e.c.io, try e.absolute(a.path), .{ .hash_files = true, .max_entries = e.config.max_candidate_entries });
            defer snap.deinit();
            try e.checkCache(snap.value);
            a.file_count = snap.value.totals.files;
            for (snap.value.entries) |entry| if (entry.metadata.kind == .file) {
                a.allocated_bytes += entry.metadata.allocated_bytes;
            };
            const snapshot_path = try e.c.fmt("{s}/cache-{d}.json", .{ e.output, index });
            try e.write(snapshot_path, snap.value);
            a.snapshot = .{ .path = snapshot_path, .sha256 = try e.digest(snapshot_path) };
        } else {
            if (m.kind != .file or m.links != 1) return error.AliasedOrNonRegularArtifact;
            try e.check(.{ .path = a.path, .sha256 = a.sha256.? });
            if (a.kind == .build_output) {
                var f = try D.cwd().openFile(e.c.io, try e.absolute(a.path), .{});
                defer f.close(e.c.io);
                var buffer: [16]u8 = undefined;
                const n = try f.readPositionalAll(e.c.io, &buffer, 0);
                if (!std.mem.startsWith(u8, buffer[0..n], "\x7fELF") and !std.mem.startsWith(u8, buffer[0..n], "!<arch>\n")) return error.NotCompiledOutput;
            }
            a.allocated_bytes = m.allocated_bytes;
            a.file_count = 1;
        }
        a.status = .ready;
        a.measured = true;
    }
    /// All retained evidence wins across actions. Normalize each unique path
    /// once, instead of allocating inside the candidate × evidence loops.
    pub fn protectRetained(e: *Engine) !void {
        var evidence = std.StringHashMap(void).init(e.c.gpa);
        defer evidence.deinit();
        for (e.actions.items) |a| for (a.retained) |ev| try evidence.put(ev.path, {});
        for (e.retained_declarations.items) |path| try evidence.put(path, {});
        var it = evidence.keyIterator();
        var normalized: std.ArrayList([]const u8) = .empty;
        while (it.next()) |path| try normalized.append(e.c.a, try e.absolute(path.*));
        for (e.actions.items) |*a| {
            if (a.status != .ready) continue;
            const abs = try e.absolute(a.path);
            for (normalized.items) |path| if (p.overlaps(abs, path)) {
                a.status = .skipped;
                a.reason = "retained evidence of another candidate";
                break;
            };
        }
    }
    pub fn measureHeld(e: *Engine, index: usize) !void {
        const a = &e.actions.items[index];
        if (a.measured) return;
        const m = try e.metadata(a.path);
        a.metadata = m;
        if (a.idle_seconds == null) a.idle_seconds = @intCast(@divFloor(e.now_ns - @max(m.mtime_ns, m.ctime_ns), std.time.ns_per_s));
        a.allocated_bytes = 0;
        a.file_count = 0;
        if (m.kind == .directory) {
            var snapshot = try fa.scan(e.c.gpa, e.c.io, try e.absolute(a.path), .{ .max_entries = e.config.max_candidate_entries });
            defer snapshot.deinit();
            var seen = std.AutoHashMap(fa.metadata.Identity, void).init(e.c.gpa);
            defer seen.deinit();
            for (snapshot.value.entries) |entry| {
                if (entry.metadata.kind != .file) continue;
                if ((try seen.getOrPut(fa.metadata.identity(entry.metadata))).found_existing) continue;
                a.allocated_bytes += entry.metadata.allocated_bytes;
                a.file_count += 1;
            }
        } else if (m.kind == .file) {
            a.allocated_bytes = m.allocated_bytes;
            a.file_count = 1;
        }
        a.measured = true;
    }
    pub fn checkCache(e: *Engine, s: fa.Snapshot) !void {
        if (s.entries.len == 0) return error.EmptySnapshot;
        for (s.entries) |entry| {
            const m = entry.metadata;
            if (m.device != s.entries[0].metadata.device) return error.CrossDeviceCache;
            if (m.uid != std.os.linux.getuid()) return error.ForeignOwner;
            if (!e.oldEnough(m)) return error.TooRecent;
            switch (m.kind) {
                .file => if (m.links != 1 or entry.sha256 == null) return error.AliasedCacheFile,
                .directory => if (m.mode & 0o200 == 0) return error.FrozenCache,
                else => return error.SpecialCacheEntry,
            }
        }
        try e.checkMounts(s);
    }
    pub fn checkMounts(e: *Engine, s: fa.Snapshot) !void {
        var parent = try fa.metadata.openRoot(e.c.io, std.fs.path.dirname(s.root) orelse return error.InvalidCandidateScope);
        defer parent.close(e.c.io);
        const mount_id = try fa.metadata.mountId(parent.handle);
        for (s.entries) |entry| {
            if (entry.metadata.kind != .directory) continue;
            const path = if (std.mem.eql(u8, entry.path, ".")) try e.c.gpa.dupe(u8, s.root) else try std.fs.path.join(e.c.gpa, &.{ s.root, entry.path });
            defer e.c.gpa.free(path);
            var dir = try fa.metadata.openRoot(e.c.io, path);
            defer dir.close(e.c.io);
            if (try fa.metadata.mountId(dir.handle) != mount_id) return error.MountedCache;
        }
    }
    pub fn verifyEvidence(e: *Engine, a: Action) !void {
        e.hash_cache.clearRetainingCapacity();
        for (e.controls.items) |row| try e.check(row);
        for (a.retained) |row| try e.check(row);
        try e.verifyRevisions();
        try historical.verifyLibraries(e);
    }
    pub fn sourceRevisions(e: *Engine, v: u.Value) !void {
        for ([_][]const u8{ "project_revision", "source_head" }) |key| {
            if (!has(v, key, .string)) continue;
            const revision = try str(v, key);
            if (revision.len != 40) return error.InvalidSourceRevision;
            for (revision) |ch| if (!std.ascii.isHex(ch)) return error.InvalidSourceRevision;
            var seen = false;
            for (e.revisions.items) |r| if (std.mem.eql(u8, r.commit, revision)) {
                seen = true;
                break;
            };
            if (seen) continue;
            const commit = u.trim(try e.c.capture(&.{ "git", "rev-parse", "--verify", try e.c.fmt("{s}^{{commit}}", .{revision}) }));
            if (!std.mem.eql(u8, commit, revision)) return error.SourceRevisionMismatch;
            const tree = u.trim(try e.c.capture(&.{ "git", "rev-parse", "--verify", try e.c.fmt("{s}^{{tree}}", .{revision}) }));
            try e.revisions.append(e.c.a, .{ .commit = commit, .tree = tree, .reference = try e.c.fmt("refs/retirements/storage-cleanup/{s}", .{commit}) });
        }
    }
    pub fn pinRevisions(e: *Engine) !void {
        for (e.revisions.items) |r| _ = try e.c.capture(&.{ "git", "update-ref", r.reference, r.commit });
    }
    pub fn verifyRevisions(e: *Engine) !void {
        for (e.revisions.items) |r| {
            if (!std.mem.eql(u8, r.commit, u.trim(try e.c.capture(&.{ "git", "rev-parse", "--verify", r.reference })))) return error.SourceReferenceChanged;
            if (!std.mem.eql(u8, r.tree, u.trim(try e.c.capture(&.{ "git", "rev-parse", "--verify", try e.c.fmt("{s}^{{tree}}", .{r.reference}) })))) return error.SourceTreeChanged;
        }
    }
    pub fn compactSnapshots(e: *Engine) !void {
        for (e.actions.items, 0..) |*a, index| {
            if (a.snapshot_uncompressed_sha256 != null) continue;
            const original = a.snapshot orelse continue;
            try e.check(original);
            _ = try e.c.capture(&.{ "gzip", "-k", "-n", "-9", "--", original.path });
            const compressed = try e.c.fmt("{s}.gz", .{original.path});
            const restored = try u.process.runReport(e.c.gpa, e.c.io, .{ .spawn = .{ .argv = &.{ "gzip", "-dc", "--", compressed }, .cwd = .{ .path = e.c.root }, .environ_map = &e.c.env, .search_path = true }, .timeout_ms = 120_000, .stdout_limit = 512 * 1024 * 1024, .stderr_limit = 1024 * 1024 });
            defer restored.deinit(e.c.gpa);
            if (!restored.success() or !std.mem.eql(u8, original.sha256, try u.digestBytes(e.c.a, restored.stdout))) return error.SnapshotCompressionMismatch;
            a.snapshot_uncompressed_sha256 = original.sha256;
            a.snapshot = .{ .path = compressed, .sha256 = try e.digest(compressed) };
            if (a.status == .removed) try e.write(try e.c.fmt("{s}/record-{d}.json", .{ e.output, index }), .{ .status = "complete", .action = a.*, .retained = a.retained });
            try D.cwd().deleteFile(e.c.io, try e.absolute(original.path));
        }
    }
};
fn checksumHash(text: []const u8) bool {
    if (text.len != 64) return false;
    for (text) |ch| if (!std.ascii.isHex(ch)) return false;
    return true;
}
pub fn get(v: u.Value, key: []const u8) !u.Value {
    if (v != .object) return error.ExpectedObject;
    return v.object.get(key) orelse error.MissingField;
}
pub fn str(v: u.Value, key: []const u8) ![]const u8 {
    const x = try get(v, key);
    if (x != .string) return error.ExpectedString;
    return x.string;
}
pub fn integer(v: u.Value, key: []const u8) !i64 {
    const x = try get(v, key);
    if (x != .integer) return error.ExpectedInteger;
    return x.integer;
}
pub fn boolean(v: u.Value, key: []const u8) !bool {
    const x = try get(v, key);
    if (x != .bool) return error.ExpectedBoolean;
    return x.bool;
}
fn has(v: u.Value, key: []const u8, tag: std.meta.Tag(u.Value)) bool {
    if (v != .object) return false;
    const x = v.object.get(key) orelse return false;
    return std.meta.activeTag(x) == tag;
}
pub fn eq(v: u.Value, key: []const u8, text: []const u8) bool {
    const x = str(v, key) catch return false;
    return std.mem.eql(u8, x, text);
}
