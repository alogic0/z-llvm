const std = @import("std");
const u = @import("../validation/common.zig");
pub const fa = @import("../vendor/file_audit/src/root.zig");
pub const p = @import("policy.zig");
const D = std.Io.Dir;
pub const Evidence = p.Evidence;
pub const Revision = struct { commit: []const u8, tree: []const u8, reference: []const u8 };
const Observed = struct { metadata: fa.Metadata, sha256: []const u8 };
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
    producer_reports: usize = 0,
    released_records: usize = 0,
    revisions: std.ArrayList(Revision) = .empty,
    collector_binary_sha256: ?[]const u8 = null,
    collector_sources: []const Evidence = &.{},
    control_hashes: std.StringHashMap([]const u8),
    hash_cache: std.AutoHashMap(fa.metadata.Identity, Observed),
    observed_reads: std.StringHashMap(Observed),
    pin_paths: ?*std.StringHashMap(void) = null,

    pub fn init(c: *u.Context, config: p.Config, output: []const u8, zigrep: []const u8) Engine {
        return .{ .c = c, .config = config, .output = output, .zigrep = zigrep, .now_ns = std.Io.Clock.real.now(c.io).nanoseconds, .control_hashes = .init(c.a), .hash_cache = .init(c.a), .observed_reads = .init(c.a) };
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
    fn keep(e: *Engine, list: *std.ArrayList(Evidence), raw: []const u8, expected: ?[]const u8) !void {
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
                try e.discoverRelease(name);
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
    fn discoverRelease(e: *Engine, name: []const u8) !void {
        var parsed = try e.load(e.c.gpa, name);
        defer parsed.deinit();
        var r = try std.json.parseFromValue(p.Release, e.c.gpa, parsed.value, .{});
        defer r.deinit();
        if (!std.mem.eql(u8, r.value.schema, "zllvm-storage-release-v1")) return error.UnknownReleaseSchema;
        if (r.value.state == .held) return;
        if (!p.candidate(r.value.run_root) or !std.mem.eql(u8, std.fs.path.dirname(name).?, r.value.run_root) or r.value.reason.len == 0) return error.InvalidReleaseScope;
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
        }
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
        for (e.actions.items) |*a| for (e.held.items) |held| if (p.overlaps(held, a.path)) {
            a.status = .skipped;
            a.reason = try e.c.fmt("protected by hold: {s}", .{held});
            break;
        };
    }
    fn pinResolved(e: *Engine, path: []const u8, source: []const u8) !void {
        for (e.actions.items) |*a| if (a.status != .removed and p.overlaps(a.path, path)) {
            a.status = .skipped;
            a.reason = try e.c.fmt("pinned by {s}", .{source});
        };
    }
    fn pinCanonical(e: *Engine, absolute_path: []const u8, source: []const u8) !void {
        if (e.pin_paths) |seen| {
            if (seen.contains(absolute_path)) return;
        }
        const canonical = D.cwd().realPathFileAlloc(e.c.io, absolute_path, e.c.gpa) catch |err| switch (err) {
            error.FileNotFound, error.NotDir => return,
            else => return err,
        };
        defer e.c.gpa.free(canonical);
        if (e.pin_paths) |seen| {
            // Cache only existing targets. Speculative ancestor resolutions
            // often do not exist and otherwise dominate memory on old ledgers.
            const owned = try e.c.gpa.dupe(u8, absolute_path);
            errdefer e.c.gpa.free(owned);
            try seen.put(owned, {});
        }
        if (std.mem.eql(u8, canonical, e.c.root)) return e.pinResolved("local-state/validations", source);
        if (p.within(e.c.root, canonical) and canonical.len > e.c.root.len) try e.pinResolved(canonical[e.c.root.len + 1 ..], source);
    }
    pub fn pin(e: *Engine, raw: []const u8, source: []const u8) !void {
        if (std.fs.path.isAbsolute(raw)) {
            if (p.within(e.c.root, raw) and raw.len > e.c.root.len) try e.pinResolved(raw[e.c.root.len + 1 ..], source);
            try e.pinCanonical(raw, source);
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
                if (v.object.get("path")) |path| if (path == .string) try e.pin(path.string, source);
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
        e.pin_paths = &seen;
        defer {
            e.pin_paths = null;
            var keys = seen.keyIterator();
            while (keys.next()) |key| e.c.gpa.free(key.*);
            seen.deinit();
        }
        const listing = try e.discoverPaths(&.{ "-g", "*.sha256", "-g", "*.SHA256SUMS", "-g", "SHA256SUMS", "-g", "record.json", "-g", "record-*.json", "-g", "artifact-manifest.json" }, &.{ "docs", "local-state/validations", "local-state/retirements", "local-state/artifacts/manifests" });
        var lines = std.mem.tokenizeScalar(u8, listing, '\n');
        e.checked_manifests = 0;
        while (lines.next()) |path| {
            if (p.within(e.output, path)) continue;
            var historical = false;
            for (e.config.retired_manifests) |retired| if (std.mem.eql(u8, path, retired.path)) {
                try e.check(retired);
                historical = true;
                break;
            };
            if (historical) continue;
            const bytes = try e.read(e.c.gpa, path, 512 * 1024 * 1024);
            defer e.c.gpa.free(bytes);
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
                    while (it.next()) |kv| try e.pin(try e.c.fmt("{s}/{s}", .{ try str(v, "root"), kv.key_ptr.* }), path);
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
                        try e.pinResolved(std.fs.path.dirname(path) orelse "local-state/validations", path);
                    } else if (line.len >= 66 and checksumHash(line[0..64]) and (line[64] == ' ' or line[64] == '\t')) {
                        var target = std.mem.trimStart(u8, line[64..], " \t");
                        if (target.len > 0 and target[0] == '*') target = target[1..];
                        if (target.len == 0) return error.EmptyChecksumPath;
                        try e.pin(target, path);
                    } else if (std.mem.startsWith(u8, line, "SHA256 (") and line.len > 76 and checksumHash(line[line.len - 64 ..]) and std.mem.eql(u8, line[line.len - 68 .. line.len - 64], ") = ")) {
                        try e.pin(line[8 .. line.len - 68], path);
                    } else return e.c.fail("Unrecognized checksum manifest entry in {s}; retaining candidates until the format is reviewed.", .{path});
                }
            }
            e.checked_manifests += 1;
        }
    }
    pub fn currentManifests(e: *Engine, verify: bool) !void {
        for (e.config.current_manifests) |path| {
            try e.addControl(path);
            if (verify) _ = try e.c.capture(&.{ "sha256sum", "--check", "--quiet", "--strict", "--", path });
        }
    }
    pub fn consumers(e: *Engine) !void {
        const listing = try e.c.capture(&.{ "lsof", "-nP", "-u", try e.c.fmt("{d}", .{std.os.linux.getuid()}), "-Fn" });
        const processes = try e.c.capture(&.{ "ps", "-eo", "pid,args" });
        for (e.actions.items) |*a| {
            if (a.status == .removed or a.status == .absent or a.status == .skipped) continue;
            const absolute_run = try e.absolute(a.run_root);
            var busy = std.mem.indexOf(u8, processes, a.run_root) != null;
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
    fn buildEvidence(e: *Engine, report: []const u8, list: *std.ArrayList(Evidence), retiring: ?[]const u8) !void {
        var parsed = try e.load(e.c.gpa, report);
        defer parsed.deinit();
        const v = parsed.value;
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
        if (r.state != .superseded) return error.ReleaseHeld;
        for ([_]Evidence{ r.producer, r.successor }) |ev| {
            if (!p.relative(ev.path)) return error.InvalidEvidencePath;
            try e.keep(list, ev.path, ev.sha256);
        }
        var producer = try e.load(e.c.gpa, r.producer.path);
        defer producer.deinit();
        try e.sourceRevisions(producer.value);
        if (!eq(producer.value, "status", "finished") and !eq(producer.value, "status", "passed") and !eq(producer.value, "status", "complete")) return error.ProducerNotTerminal;
        var successor = try e.load(e.c.gpa, r.successor.path);
        defer successor.deinit();
        if (std.mem.eql(u8, r.producer.path, r.successor.path) or !eq(successor.value, "status", "passed")) return error.NoAcceptedSuccessor;
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
        for (r.retained) |row| if (row.role == .build) try e.buildEvidence(row.path, list, if (a.kind == .build_output) a.path else null);
        if (!eq(producer.value, "status", "passed") and !roles.contains(.diagnostic)) return error.MissingFailureEvidence;
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
    pub fn qualify(e: *Engine, index: usize) !void {
        const a = &e.actions.items[index];
        if (a.status != .discovered) return;
        const m = try e.metadata(a.path);
        if (m.uid != std.os.linux.getuid()) return error.ForeignOwner;
        if (!e.oldEnough(m) or !e.oldEnough(try e.metadata(a.producer))) return error.TooRecent;
        var kept: std.ArrayList(Evidence) = .empty;
        if (a.kind == .cache) try e.buildEvidence(a.producer, &kept, null) else try e.releaseEvidence(a, &kept);
        for (kept.items) |ev| {
            const abs = try e.absolute(ev.path);
            if (p.within(try e.absolute(a.path), abs)) return error.RetentionOverlap;
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
    }
    fn sourceRevisions(e: *Engine, v: u.Value) !void {
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
