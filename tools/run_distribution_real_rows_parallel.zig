const std = @import("std");
const common = @import("tool_common.zig");
const policy_authority = @import("distribution_real_rows_parallel_policy.zig");
const cohort_output = @import("run_distribution_real_rows_parallel/cohort_output.zig");

pub const mode_count = 3;
pub const normalization_schema_version: u32 = policy_authority.schema_version;
pub const memory_policy_label = "os-managed-non-gating";
const monitor_interval_ns: u64 = std.time.ns_per_s;
const proc_meminfo_max_bytes: usize = 64 * 1024;
const proc_loadavg_max_bytes: usize = 4096;
const failure_stdout_max_bytes: u64 = 128 * 1024 * 1024;
const failure_stderr_max_bytes: u64 = 32 * 1024 * 1024;
const modes = [_][]const u8{ "ReleaseFast", "ReleaseSafe", "ReleaseSmall" };

const ProcFile = enum {
    meminfo,
    loadavg,
};

const ProcFileSelection = struct {
    path: []const u8,
    limit: usize,
};

pub const Completed = struct {
    result: std.process.RunResult,
    duration_ms: i96,
};

pub const Evidence = struct {
    cache_mode: CacheMode,
    concurrency: u8,
    run_id: [32]u8,
    root: []u8,
    work_selection_root: []u8,
    export_cache_selection_root: []u8,
    pin_manifest_sha256: [64]u8,
    wall_ms: i96,
    summed_child_ms: i96,
    filesystem_total_bytes: u64,
    post_run_free_floor_bytes: u64,
    projected_peak_bytes: u64,
    required_start_bytes: u64,
    starting_free_bytes: u64,
    minimum_free_bytes: u64,
    final_free_bytes: u64,
    peak_disk_bytes: u64,
    peak_aggregate_rss_bytes: u64,
    minimum_available_memory_bytes: u64,
    load_start: []u8,
    load_end: []u8,

    pub fn deinit(evidence: *Evidence, allocator: std.mem.Allocator) void {
        allocator.free(evidence.load_end);
        allocator.free(evidence.load_start);
        allocator.free(evidence.export_cache_selection_root);
        allocator.free(evidence.work_selection_root);
        allocator.free(evidence.root);
        evidence.* = undefined;
    }
};

pub const GroupResult = struct {
    completed: [mode_count]Completed,
    completed_owned: [mode_count]bool = .{ true, true, true },
    evidence: Evidence,

    pub fn takeCompleted(result: *GroupResult, index: usize) Completed {
        std.debug.assert(result.completed_owned[index]);
        result.completed_owned[index] = false;
        return result.completed[index];
    }

    pub fn deinit(result: *GroupResult, allocator: std.mem.Allocator) void {
        for (&result.completed, result.completed_owned) |*completed, owned| {
            if (owned) common.freeRunResult(allocator, completed.result);
        }
        result.evidence.deinit(allocator);
        result.* = undefined;
    }
};

pub const ParentOptions = struct {
    target_assignment: []const u8,
    zig_emitter_path: ?[]const u8 = null,
    scratch_path: []const u8,
    export_cache_path: ?[]const u8 = null,
    cache_mode: CacheMode = .require_hit,
    concurrency: u8,
    test_options: ?*TestOptions = null,
};

pub const CacheMode = cohort_output.CacheMode;

const ModePaths = struct {
    root: []u8,
    work: []u8,
    local_cache: []u8,
    global_cache: []u8,
    export_cache: []u8,
    result: []u8,
    log: []u8,

    fn deinit(paths: *ModePaths, allocator: std.mem.Allocator) void {
        allocator.free(paths.log);
        allocator.free(paths.result);
        allocator.free(paths.export_cache);
        allocator.free(paths.global_cache);
        allocator.free(paths.local_cache);
        allocator.free(paths.work);
        allocator.free(paths.root);
        paths.* = undefined;
    }
};

const OwnedPaths = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    run_id: [32]u8,
    root: []u8,
    stop: []u8,
    pin_manifest: []u8,
    failure_root: []u8,
    mode_paths: [mode_count]ModePaths,

    fn init(allocator: std.mem.Allocator, io: std.Io, scratch_path: []const u8, export_cache_path: []const u8, cache_mode: CacheMode) !OwnedPaths {
        const scratch_owner = try requireCanonicalContractBase(io, scratch_path);
        const cache_owner = try requireCanonicalContractBase(io, export_cache_path);
        if (!std.mem.eql(u8, scratch_owner, cache_owner)) return error.RealRowsRootSelectionMismatch;
        var random_bytes: [16]u8 = undefined;
        var cwd = std.Io.Dir.cwd();
        var root: []u8 = undefined;
        var run_id: [32]u8 = undefined;
        var attempt: usize = 0;
        while (attempt < 16) : (attempt += 1) {
            io.random(&random_bytes);
            run_id = std.fmt.bytesToHex(random_bytes, .lower);
            root = try std.fmt.allocPrint(allocator, "{s}/real_rows_parallel_{s}", .{ scratch_path, &run_id });
            cwd.createDir(io, root, .default_dir) catch |err| switch (err) {
                error.PathAlreadyExists => {
                    allocator.free(root);
                    continue;
                },
                else => {
                    allocator.free(root);
                    return err;
                },
            };
            break;
        } else return error.RealRowsParallelRootCollisionLimit;
        errdefer {
            cwd.deleteTree(io, root) catch {};
            allocator.free(root);
        }
        const stop = try std.fs.path.join(allocator, &.{ root, "stop" });
        errdefer allocator.free(stop);
        const pin_manifest = try std.fs.path.join(allocator, &.{ root, "live_pins.tsv" });
        errdefer allocator.free(pin_manifest);
        const failure_root = try std.fs.path.join(allocator, &.{ scratch_path, "failures" });
        errdefer allocator.free(failure_root);
        var initialized: usize = 0;
        var mode_paths: [mode_count]ModePaths = undefined;
        errdefer for (mode_paths[0..initialized]) |*paths| {
            cwd.deleteTree(io, paths.work) catch {};
            paths.deinit(allocator);
        };
        for (&mode_paths, modes) |*paths, mode| {
            const mode_root = try std.fs.path.join(allocator, &.{ root, mode });
            errdefer allocator.free(mode_root);
            try cwd.createDir(io, mode_root, .default_dir);
            const work_parent = try std.fs.path.join(allocator, &.{ scratch_path, mode });
            defer allocator.free(work_parent);
            try cwd.createDirPath(io, work_parent);
            const work_name = try std.fmt.allocPrint(allocator, "work_{s}", .{&run_id});
            defer allocator.free(work_name);
            const work = try createOwnedSubdir(allocator, io, work_parent, work_name);
            errdefer cwd.deleteTree(io, work) catch {};
            errdefer allocator.free(work);
            const work_owner = try requireCanonicalModeOwnedDirectory(io, work, mode);
            if (!std.mem.eql(u8, work_owner, scratch_owner)) return error.RealRowsRootSelectionMismatch;
            const local_cache = try createOwnedSubdir(allocator, io, mode_root, "zig-local-cache");
            errdefer allocator.free(local_cache);
            const global_cache = try createOwnedSubdir(allocator, io, mode_root, "zig-global-cache");
            errdefer allocator.free(global_cache);
            const cache_mode_root = try std.fs.path.join(allocator, &.{ export_cache_path, mode });
            defer allocator.free(cache_mode_root);
            if (cache_mode == .fresh) {
                try cwd.createDir(io, cache_mode_root, .default_dir);
                errdefer cwd.deleteTree(io, cache_mode_root) catch {};
            }
            const export_cache = try std.fs.path.join(allocator, &.{ cache_mode_root, "export" });
            errdefer allocator.free(export_cache);
            if (cache_mode == .fresh) try cwd.createDir(io, export_cache, .default_dir);
            const export_owner = try requireCanonicalModeOwnedDirectory(io, export_cache, mode);
            if (!std.mem.eql(u8, export_owner, cache_owner)) return error.RealRowsRootSelectionMismatch;
            const result = try std.fs.path.join(allocator, &.{ mode_root, "result.txt" });
            errdefer allocator.free(result);
            const log = try std.fs.path.join(allocator, &.{ mode_root, "worker.log" });
            paths.* = .{ .root = mode_root, .work = work, .local_cache = local_cache, .global_cache = global_cache, .export_cache = export_cache, .result = result, .log = log };
            initialized += 1;
        }
        return .{ .allocator = allocator, .io = io, .run_id = run_id, .root = root, .stop = stop, .pin_manifest = pin_manifest, .failure_root = failure_root, .mode_paths = mode_paths };
    }

    fn deinit(paths: *OwnedPaths) void {
        std.Io.Dir.cwd().deleteTree(paths.io, paths.root) catch {};
        for (&paths.mode_paths) |*mode_path| {
            std.Io.Dir.cwd().deleteTree(paths.io, mode_path.work) catch {};
            mode_path.deinit(paths.allocator);
        }
        paths.allocator.free(paths.failure_root);
        paths.allocator.free(paths.pin_manifest);
        paths.allocator.free(paths.stop);
        paths.allocator.free(paths.root);
        paths.* = undefined;
    }
};

fn requireCanonicalContractBase(io: std.Io, path: []const u8) ![]const u8 {
    if (path.len == 0 or std.fs.path.isAbsolute(path) or path[path.len - 1] == '/') return error.RealRowsRootSelectionInvalid;
    var last: ?[]const u8 = null;
    var parts = std.mem.splitScalar(u8, path, '/');
    var current = std.Io.Dir.cwd();
    var current_owned = false;
    defer if (current_owned) current.close(io);
    while (parts.next()) |part| {
        if (part.len == 0 or std.mem.eql(u8, part, ".") or std.mem.eql(u8, part, "..") or
            std.mem.indexOfScalar(u8, part, 0) != null)
        {
            return error.RealRowsRootSelectionInvalid;
        }
        for (modes) |mode| if (std.mem.eql(u8, part, mode)) return error.RealRowsRootSelectionModeMismatch;
        const next = current.openDir(io, part, .{ .access_sub_paths = true, .iterate = false, .follow_symlinks = false }) catch {
            return error.RealRowsRootSelectionInvalid;
        };
        if (current_owned) current.close(io);
        current = next;
        current_owned = true;
        last = part;
    }
    return last orelse error.RealRowsRootSelectionInvalid;
}

fn requireCanonicalModeOwnedDirectory(io: std.Io, path: []const u8, mode: []const u8) ![]const u8 {
    if (path.len == 0 or std.fs.path.isAbsolute(path) or path[path.len - 1] == '/') return error.RealRowsRootSelectionInvalid;
    var previous_previous: ?[]const u8 = null;
    var previous: ?[]const u8 = null;
    var selected_mode_count: usize = 0;
    var parts = std.mem.splitScalar(u8, path, '/');
    var current = std.Io.Dir.cwd();
    var current_owned = false;
    defer if (current_owned) current.close(io);
    while (parts.next()) |part| {
        if (part.len == 0 or std.mem.eql(u8, part, ".") or std.mem.eql(u8, part, "..") or
            std.mem.indexOfScalar(u8, part, 0) != null)
        {
            return error.RealRowsRootSelectionInvalid;
        }
        for (modes) |known_mode| if (std.mem.eql(u8, part, known_mode)) {
            if (!std.mem.eql(u8, known_mode, mode)) return error.RealRowsRootSelectionModeMismatch;
            selected_mode_count += 1;
        };
        const next = current.openDir(io, part, .{ .access_sub_paths = true, .iterate = false, .follow_symlinks = false }) catch {
            return error.RealRowsRootSelectionInvalid;
        };
        if (current_owned) current.close(io);
        current = next;
        current_owned = true;
        previous_previous = previous;
        previous = part;
    }
    _ = previous orelse return error.RealRowsRootSelectionInvalid;
    const mode_component = previous_previous orelse return error.RealRowsRootSelectionInvalid;
    if (!std.mem.eql(u8, mode_component, mode) or selected_mode_count != 1) return error.RealRowsRootSelectionModeMismatch;
    const mode_start = @intFromPtr(mode_component.ptr) - @intFromPtr(path.ptr);
    if (mode_start == 0 or path[mode_start - 1] != '/') return error.RealRowsRootSelectionInvalid;
    const owner_end = mode_start - 1;
    const owner_start = if (std.mem.lastIndexOfScalar(u8, path[0..owner_end], '/')) |slash| slash + 1 else 0;
    if (owner_start == owner_end) return error.RealRowsRootSelectionInvalid;
    return path[owner_start..owner_end];
}

fn createOwnedSubdir(allocator: std.mem.Allocator, io: std.Io, root: []const u8, name: []const u8) ![]u8 {
    const path = try std.fs.path.join(allocator, &.{ root, name });
    errdefer allocator.free(path);
    try std.Io.Dir.cwd().createDir(io, path, .default_dir);
    return path;
}

const ArgvStorage = struct {
    allocator: std.mem.Allocator,
    owned: std.ArrayList([]u8) = .empty,
    argv: std.ArrayList([]const u8) = .empty,

    fn deinit(storage: *ArgvStorage) void {
        for (storage.owned.items) |item| storage.allocator.free(item);
        storage.owned.deinit(storage.allocator);
        storage.argv.deinit(storage.allocator);
        storage.* = undefined;
    }

    fn addOwned(storage: *ArgvStorage, comptime fmt: []const u8, args: anytype) !void {
        const value = try std.fmt.allocPrint(storage.allocator, fmt, args);
        storage.owned.append(storage.allocator, value) catch |err| {
            storage.allocator.free(value);
            return err;
        };
        storage.argv.append(storage.allocator, value) catch |err| {
            _ = storage.owned.pop();
            storage.allocator.free(value);
            return err;
        };
    }
};

fn buildWorkerArgv(allocator: std.mem.Allocator, target_assignment: []const u8, zig_emitter_path: []const u8, mode_index: usize, paths: ModePaths, cache_mode: CacheMode, probe_only: bool) !ArgvStorage {
    var storage: ArgvStorage = .{ .allocator = allocator };
    errdefer storage.deinit();
    try storage.argv.appendSlice(allocator, &.{ "env", target_assignment });
    try storage.addOwned("ZIG_EMITTER={s}", .{zig_emitter_path});
    try storage.addOwned("ZIG_LOCAL_CACHE_DIR={s}", .{paths.local_cache});
    try storage.addOwned("ZIG_GLOBAL_CACHE_DIR={s}", .{paths.global_cache});
    try storage.argv.append(allocator, "ZLLVM_REAL_ROWS_PRUNING=suspended");
    try storage.argv.appendSlice(allocator, &.{ "zig", "run", "src/distribution_real_rows_gate.zig", "--" });
    try storage.addOwned("--mode={s}", .{modes[mode_index]});
    try storage.argv.appendSlice(allocator, &.{ "--strict", "--limit=100" });
    try storage.argv.append(allocator, if (probe_only or cache_mode == .require_hit) "--require-cache-hit" else "--fresh-export");
    if (probe_only) try storage.argv.append(allocator, "--cache-probe-only");
    try storage.addOwned("--runner-temp-root={s}", .{paths.work});
    try storage.addOwned("--export-cache-root={s}", .{paths.export_cache});
    return storage;
}

const CachePin = struct { key: [64]u8, descriptor_sha256: [64]u8, descriptor_bytes: usize };

fn fieldValue(line: []const u8, prefix: []const u8) ?[]const u8 {
    var fields = std.mem.tokenizeScalar(u8, line, ' ');
    while (fields.next()) |field| if (std.mem.startsWith(u8, field, prefix)) return field[prefix.len..];
    return null;
}

fn metadataValue(meta: []const u8, key: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, meta, '\n');
    while (lines.next()) |line| {
        if (line.len > key.len and line[key.len] == '=' and std.mem.eql(u8, line[0..key.len], key)) return line[key.len + 1 ..];
    }
    return null;
}

fn parseProbeOutput(allocator: std.mem.Allocator, io: std.Io, output: []const u8, mode: []const u8, export_cache_root: []const u8) !CachePin {
    var cache_line: ?[]const u8 = null;
    var probe_summary = false;
    var lines = std.mem.splitScalar(u8, output, '\n');
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "air-export-cache ")) {
            if (cache_line != null) return error.RealRowsProbeDuplicateCacheEvent;
            cache_line = line;
        }
        if (std.mem.startsWith(u8, line, "summary distribution-real-rows-cache-probe ")) probe_summary = true;
    }
    const line = cache_line orelse return error.RealRowsProbeMissingCacheEvent;
    if (!std.mem.eql(u8, fieldValue(line, "mode=") orelse return error.RealRowsProbeMissingMode, mode)) return error.RealRowsProbeModeMismatch;
    if (!std.mem.eql(u8, fieldValue(line, "status=") orelse return error.RealRowsProbeMissingStatus, "hit")) return error.RealRowsParallelCacheUnavailable;
    if (!probe_summary) return error.RealRowsProbeMissingSummary;
    const key_text = fieldValue(line, "cache_key=") orelse return error.RealRowsProbeMissingKey;
    if (key_text.len != 64) return error.RealRowsProbeInvalidKey;
    const bytes_text = fieldValue(line, "descriptor_bytes=") orelse return error.RealRowsProbeMissingBytes;
    const meta_path = try std.fmt.allocPrint(allocator, "{s}/{s}.meta", .{ export_cache_root, key_text });
    defer allocator.free(meta_path);
    const meta = try std.Io.Dir.cwd().readFileAlloc(io, meta_path, allocator, .limited(64 * 1024));
    defer allocator.free(meta);
    const digest_text = metadataValue(meta, "descriptor_sha256") orelse return error.RealRowsProbeMissingDescriptorDigest;
    if (digest_text.len != 64) return error.RealRowsProbeInvalidDescriptorDigest;
    var pin: CachePin = .{ .key = undefined, .descriptor_sha256 = undefined, .descriptor_bytes = try std.fmt.parseUnsigned(usize, bytes_text, 10) };
    @memcpy(&pin.key, key_text);
    @memcpy(&pin.descriptor_sha256, digest_text);
    return pin;
}

fn verifyPin(allocator: std.mem.Allocator, io: std.Io, pin: CachePin, export_cache_root: []const u8) !void {
    const air_path = try std.fmt.allocPrint(allocator, "{s}/{s}.air", .{ export_cache_root, &pin.key });
    defer allocator.free(air_path);
    const descriptor = try std.Io.Dir.cwd().readFileAlloc(io, air_path, allocator, .limited(2 * 1024 * 1024 * 1024));
    defer allocator.free(descriptor);
    if (descriptor.len != pin.descriptor_bytes) return error.RealRowsPinnedDescriptorSizeChanged;
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(descriptor, &digest, .{});
    const actual = std.fmt.bytesToHex(digest, .lower);
    if (!std.mem.eql(u8, &actual, &pin.descriptor_sha256)) return error.RealRowsPinnedDescriptorDigestChanged;
}

fn probeAndPin(allocator: std.mem.Allocator, io: std.Io, options: ParentOptions, paths: *const OwnedPaths) ![mode_count]CachePin {
    var pins: [mode_count]CachePin = undefined;
    var manifest_buffer: [4096]u8 = undefined;
    var manifest = std.Io.Writer.fixed(&manifest_buffer);
    try manifest.writeAll("schema=1\tpopulation=compiler-rt-real-rows\tpruning=suspended\n");
    for (modes, 0..) |mode, index| {
        if (options.test_options) |test_options| {
            if (!test_options.cache_hits) return error.RealRowsParallelCacheUnavailable;
            {
                @memset(&pins[index].key, @as(u8, 'a') + @as(u8, @intCast(index)));
                @memset(&pins[index].descriptor_sha256, @as(u8, 'd') + @as(u8, @intCast(index)));
                pins[index].descriptor_bytes = 100 + index;
                try manifest.print("mode={s}\tcache_key={s}\tdescriptor_sha256={s}\tdescriptor_bytes={}\n", .{ mode, &pins[index].key, &pins[index].descriptor_sha256, pins[index].descriptor_bytes });
                continue;
            }
        }
        var argv = try buildWorkerArgv(allocator, options.target_assignment, options.zig_emitter_path.?, index, paths.mode_paths[index], .require_hit, true);
        defer argv.deinit();
        const result = try std.process.run(allocator, io, .{ .argv = argv.argv.items, .stdout_limit = .limited(4 * 1024 * 1024), .stderr_limit = .limited(4 * 1024 * 1024) });
        defer common.freeRunResult(allocator, result);
        if (!common.termOk(result.term)) return error.RealRowsParallelCacheUnavailable;
        pins[index] = try parseProbeOutput(allocator, io, result.stdout, mode, paths.mode_paths[index].export_cache);
        try verifyPin(allocator, io, pins[index], paths.mode_paths[index].export_cache);
        try manifest.print("mode={s}\tcache_key={s}\tdescriptor_sha256={s}\tdescriptor_bytes={}\n", .{ mode, &pins[index].key, &pins[index].descriptor_sha256, pins[index].descriptor_bytes });
    }
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = paths.pin_manifest, .data = manifest.buffered() });
    return pins;
}

fn sha256File(allocator: std.mem.Allocator, io: std.Io, path: []const u8) ![64]u8 {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(1024 * 1024));
    defer allocator.free(contents);
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(contents, &digest, .{});
    return std.fmt.bytesToHex(digest, .lower);
}

pub const FilesystemSample = struct { total_bytes: u64, free_bytes: u64 };

const ResourceState = struct {
    filesystem_total_bytes: u64,
    post_run_free_floor_bytes: u64,
    starting_free_bytes: u64,
    minimum_free_bytes: u64,
    final_free_bytes: u64,
    peak_disk_bytes: u64 = 0,
    peak_aggregate_rss_bytes: u64 = 0,
    minimum_available_memory_bytes: u64,
    last_free_bytes: u64 = 0,
    last_disk_bytes: u64 = 0,
    last_aggregate_rss_bytes: u64 = 0,
    last_available_memory_bytes: u64 = 0,
    samples: usize = 0,

    fn observe(state: *ResourceState, sample: FilesystemSample, disk_bytes: u64, rss_bytes: u64, available_memory_bytes: u64) !void {
        if (sample.total_bytes != state.filesystem_total_bytes) return error.RealRowsParallelFilesystemChanged;
        state.samples += 1;
        state.last_free_bytes = sample.free_bytes;
        state.last_disk_bytes = disk_bytes;
        state.last_aggregate_rss_bytes = rss_bytes;
        state.last_available_memory_bytes = available_memory_bytes;
        state.minimum_free_bytes = @min(state.minimum_free_bytes, sample.free_bytes);
        state.final_free_bytes = sample.free_bytes;
        state.peak_disk_bytes = @max(state.peak_disk_bytes, disk_bytes);
        state.peak_aggregate_rss_bytes = @max(state.peak_aggregate_rss_bytes, rss_bytes);
        state.minimum_available_memory_bytes = @min(state.minimum_available_memory_bytes, available_memory_bytes);
        if (sample.free_bytes < state.post_run_free_floor_bytes) return error.RealRowsParallelDiskFloorCrossed;
    }
};

const WorkerWait = struct { term: std.process.Child.Term, duration_ms: i96, max_rss_bytes: ?usize };
const ChildFailureState = enum { not_launched, not_reaped, reaped };
const ChildFailureObservation = struct {
    state: ChildFailureState = .not_launched,
    max_rss_bytes: ?usize = null,
};
const WaitState = struct {
    done: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    failed: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
};

fn waitWorker(io: std.Io, child: *std.process.Child, state: *WaitState, start: std.Io.Timestamp) !WorkerWait {
    defer state.done.store(true, .release);
    const term = try child.wait(io);
    state.failed.store(!common.termOk(term), .release);
    return .{ .term = term, .duration_ms = elapsedMs(io, start), .max_rss_bytes = child.resource_usage_statistics.getMaxRss() };
}

const WorkerFuture = std.Io.Future(@typeInfo(@TypeOf(waitWorker)).@"fn".return_type.?);

const SpawnedWorker = struct {
    mode_index: usize,
    child: std.process.Child,
    pid: std.posix.pid_t,
    result_file: std.Io.File,
    log_file: std.Io.File,
    state: WaitState = .{},
    start: std.Io.Timestamp,
    wait_future_started: bool = false,
    termination_requested: bool = false,
    reaped: bool = false,
    descriptors_closed: bool = false,
};

pub const TestWorkerFixture = enum { production, success, first_child_fails, all_sleep };
pub const LifecycleAudit = struct {
    launched: [mode_count]usize = .{ 0, 0, 0 },
    wait_futures_started: [mode_count]usize = .{ 0, 0, 0 },
    termination_requests: [mode_count]usize = .{ 0, 0, 0 },
    reaped: [mode_count]usize = .{ 0, 0, 0 },
    descriptors_closed: [mode_count]usize = .{ 0, 0, 0 },
    shared_stop_requests: usize = 0,
    close_after_reap: bool = true,
    all_workers_reaped_before_close: bool = true,
    evidence_preserved_before_cleanup: bool = false,
    failure_run_id: [32]u8 = undefined,
    failure_run_id_recorded: bool = false,
};

pub const TestOptions = struct {
    cache_hits: bool = true,
    worker_fixture: TestWorkerFixture = .production,
    fail_wait_future_before_index: ?usize = null,
    filesystem_sample: ?FilesystemSample = null,
    disk_bytes: u64 = 0,
    aggregate_rss_bytes: u64 = 0,
    available_memory_bytes: u64 = 64 * 1024 * 1024 * 1024,
    available_memory_samples: ?[]const u64 = null,
    available_memory_sample_index: usize = 0,
    monitor_interval_ns: u64 = std.time.ns_per_ms,
    failure_evidence_dir: []const u8 = "tmp/real_rows_parallel_fixture_failures",
    audit: *LifecycleAudit,
};

fn spawnWorker(allocator: std.mem.Allocator, io: std.Io, options: ParentOptions, paths: *const OwnedPaths, mode_index: usize) !SpawnedWorker {
    const mode_path = paths.mode_paths[mode_index];
    var argv = try buildWorkerArgv(allocator, options.target_assignment, options.zig_emitter_path.?, mode_index, mode_path, options.cache_mode, false);
    defer argv.deinit();
    const result_file = try std.Io.Dir.cwd().createFile(io, mode_path.result, .{ .exclusive = true });
    errdefer result_file.close(io);
    const log_file = try std.Io.Dir.cwd().createFile(io, mode_path.log, .{ .exclusive = true });
    errdefer log_file.close(io);
    const child = if (options.test_options) |test_options| switch (test_options.worker_fixture) {
        .production => try std.process.spawn(io, .{ .argv = argv.argv.items, .stdin = .ignore, .stdout = .{ .file = result_file }, .stderr = .{ .file = log_file }, .request_resource_usage_statistics = true, .pgid = 0 }),
        .success => blk: {
            const status: []const u8 = if (options.cache_mode == .fresh) "fresh-export" else "hit";
            const output = try cohort_output.syntheticOutputForTest(modes[mode_index], status, allocator);
            defer allocator.free(output);
            break :blk try std.process.spawn(io, .{ .argv = &.{ "/usr/bin/printf", "%s", output }, .stdin = .ignore, .stdout = .{ .file = result_file }, .stderr = .{ .file = log_file }, .request_resource_usage_statistics = true, .pgid = 0 });
        },
        .first_child_fails => if (mode_index == 0)
            try std.process.spawn(io, .{ .argv = &.{ "/bin/sh", "-c", "printf 'injected-real-row-child-stdout\\n'; printf 'injected-real-row-child-stderr\\n' >&2; exit 7" }, .stdin = .ignore, .stdout = .{ .file = result_file }, .stderr = .{ .file = log_file }, .request_resource_usage_statistics = true, .pgid = 0 })
        else
            try std.process.spawn(io, .{ .argv = &.{ "/bin/sh", "-c", "sleep 30" }, .stdin = .ignore, .stdout = .{ .file = result_file }, .stderr = .{ .file = log_file }, .request_resource_usage_statistics = true, .pgid = 0 }),
        .all_sleep => try std.process.spawn(io, .{ .argv = &.{ "/bin/sh", "-c", "sleep 30" }, .stdin = .ignore, .stdout = .{ .file = result_file }, .stderr = .{ .file = log_file }, .request_resource_usage_statistics = true, .pgid = 0 }),
    } else try std.process.spawn(io, .{ .argv = argv.argv.items, .stdin = .ignore, .stdout = .{ .file = result_file }, .stderr = .{ .file = log_file }, .request_resource_usage_statistics = true, .pgid = 0 });
    if (options.test_options) |test_options| test_options.audit.launched[mode_index] += 1;
    return .{ .mode_index = mode_index, .child = child, .pid = child.id.?, .result_file = result_file, .log_file = log_file, .start = std.Io.Timestamp.now(io, .awake) };
}

fn closeWorkerFiles(io: std.Io, worker: *SpawnedWorker, options: ParentOptions) !void {
    if (!worker.reaped or worker.child.id != null) return error.RealRowsDescriptorsClosedBeforeReap;
    if (worker.descriptors_closed) return error.RealRowsDescriptorsClosedTwice;
    worker.result_file.close(io);
    worker.log_file.close(io);
    worker.descriptors_closed = true;
    if (options.test_options) |test_options| {
        var launched_total: usize = 0;
        var reaped_total: usize = 0;
        for (test_options.audit.launched, test_options.audit.reaped) |launched, reaped| {
            launched_total += launched;
            reaped_total += reaped;
        }
        if (reaped_total != launched_total) test_options.audit.all_workers_reaped_before_close = false;
        test_options.audit.descriptors_closed[worker.mode_index] += 1;
        if (test_options.audit.reaped[worker.mode_index] == 0) test_options.audit.close_after_reap = false;
    }
}

const BatchControl = struct { shared_stop_requested: bool = false };

fn requestSharedStop(io: std.Io, paths: *const OwnedPaths, options: ParentOptions, control: *BatchControl) void {
    if (control.shared_stop_requested) return;
    control.shared_stop_requested = true;
    std.Io.Dir.cwd().writeFile(io, .{ .sub_path = paths.stop, .data = "stop\n" }) catch {};
    if (options.test_options) |test_options| test_options.audit.shared_stop_requests += 1;
}

fn requestWorkerTermination(worker: *SpawnedWorker, options: ParentOptions) void {
    if (!worker.wait_future_started or worker.state.done.load(.acquire) or worker.reaped or worker.termination_requested) return;
    worker.termination_requested = true;
    if (options.test_options) |test_options| test_options.audit.termination_requests[worker.mode_index] += 1;
    std.posix.kill(-worker.pid, .KILL) catch {};
}

fn requestBatchTermination(io: std.Io, paths: *const OwnedPaths, workers: []SpawnedWorker, options: ParentOptions, control: *BatchControl) void {
    requestSharedStop(io, paths, options, control);
    for (workers) |*worker| requestWorkerTermination(worker, options);
}

fn allWorkersDone(workers: []const SpawnedWorker) bool {
    for (workers) |*worker| if (!worker.state.done.load(.acquire)) return false;
    return true;
}

fn anyWorkerFailed(workers: []const SpawnedWorker) bool {
    for (workers) |*worker| if (worker.state.failed.load(.acquire)) return true;
    return false;
}

fn markReaped(worker: *SpawnedWorker, options: ParentOptions) void {
    if (worker.reaped) return;
    worker.reaped = true;
    if (options.test_options) |test_options| test_options.audit.reaped[worker.mode_index] += 1;
}

fn directlyKillAndReap(io: std.Io, worker: *SpawnedWorker, options: ParentOptions) void {
    if (worker.reaped) return;
    if (!worker.termination_requested) {
        worker.termination_requested = true;
        if (options.test_options) |test_options| test_options.audit.termination_requests[worker.mode_index] += 1;
    }
    worker.child.kill(io);
    worker.state.done.store(true, .release);
    markReaped(worker, options);
}

fn sampleFilesystem(allocator: std.mem.Allocator, io: std.Io, path: []const u8, options: ParentOptions) !FilesystemSample {
    if (options.test_options) |test_options| if (test_options.filesystem_sample) |sample| return sample;
    const argv = [_][]const u8{ "df", "-B1", "--output=size,avail", path };
    const result = try common.runCapture(allocator, io, &argv, "real-row parallel df sample");
    defer common.freeRunResult(allocator, result);
    var fields = std.mem.tokenizeAny(u8, result.stdout, " \t\r\n");
    _ = fields.next() orelse return error.InvalidRealRowsFilesystemSample;
    _ = fields.next() orelse return error.InvalidRealRowsFilesystemSample;
    const total = fields.next() orelse return error.InvalidRealRowsFilesystemSample;
    const free = fields.next() orelse return error.InvalidRealRowsFilesystemSample;
    if (fields.next() != null) return error.InvalidRealRowsFilesystemSample;
    return .{ .total_bytes = try std.fmt.parseUnsigned(u64, total, 10), .free_bytes = try std.fmt.parseUnsigned(u64, free, 10) };
}

fn sampleDiskBytes(allocator: std.mem.Allocator, io: std.Io, path: []const u8, options: ParentOptions) !u64 {
    if (options.test_options) |test_options| return test_options.disk_bytes;
    const argv = [_][]const u8{ "du", "-sb", path };
    const result = try common.runCapture(allocator, io, &argv, "real-row parallel disk sample");
    defer common.freeRunResult(allocator, result);
    var fields = std.mem.tokenizeAny(u8, result.stdout, " \t\r\n");
    return std.fmt.parseUnsigned(u64, fields.next() orelse return error.InvalidRealRowsDiskSample, 10);
}

fn sampleProcessTreeRssBytes(allocator: std.mem.Allocator, io: std.Io, options: ParentOptions) !u64 {
    if (options.test_options) |test_options| return test_options.aggregate_rss_bytes;
    const argv = [_][]const u8{ "ps", "-e", "-o", "pid=,ppid=,rss=" };
    const result = try common.runCapture(allocator, io, &argv, "real-row parallel memory sample");
    defer common.freeRunResult(allocator, result);
    const Entry = struct { pid: i32, ppid: i32, rss_kib: u64 };
    var entries: std.ArrayList(Entry) = .empty;
    defer entries.deinit(allocator);
    var lines = std.mem.splitScalar(u8, result.stdout, '\n');
    while (lines.next()) |line| {
        var fields = std.mem.tokenizeAny(u8, line, " \t");
        const pid = fields.next() orelse continue;
        const ppid = fields.next() orelse continue;
        const rss = fields.next() orelse continue;
        try entries.append(allocator, .{ .pid = try std.fmt.parseInt(i32, pid, 10), .ppid = try std.fmt.parseInt(i32, ppid, 10), .rss_kib = try std.fmt.parseUnsigned(u64, rss, 10) });
    }
    var descendants = std.AutoHashMap(i32, void).init(allocator);
    defer descendants.deinit();
    try descendants.put(std.os.linux.getpid(), {});
    var changed = true;
    while (changed) {
        changed = false;
        for (entries.items) |entry| if (!descendants.contains(entry.pid) and descendants.contains(entry.ppid)) {
            try descendants.put(entry.pid, {});
            changed = true;
        };
    }
    var total_kib: u64 = 0;
    for (entries.items) |entry| {
        if (descendants.contains(entry.pid)) total_kib +|= entry.rss_kib;
    }
    return total_kib *| 1024;
}

fn sampleAvailableMemory(allocator: std.mem.Allocator, io: std.Io, options: ParentOptions) !u64 {
    if (options.test_options) |test_options| {
        if (test_options.available_memory_samples) |samples| {
            if (test_options.available_memory_sample_index >= samples.len) return error.InvalidRealRowsAvailableMemorySample;
            const sample = samples[test_options.available_memory_sample_index];
            test_options.available_memory_sample_index += 1;
            return sample;
        }
        return test_options.available_memory_bytes;
    }
    const contents = try readProcFileBounded(allocator, io, .meminfo);
    defer allocator.free(contents);
    return parseAvailableMemory(contents);
}

fn readLoadAverage(allocator: std.mem.Allocator, io: std.Io) ![]u8 {
    const contents = try readProcFileBounded(allocator, io, .loadavg);
    defer allocator.free(contents);
    return parseLoadAverage(allocator, contents);
}

fn readProcFileBounded(allocator: std.mem.Allocator, io: std.Io, proc_file: ProcFile) ![]u8 {
    const selection: ProcFileSelection = switch (proc_file) {
        .meminfo => .{ .path = "/proc/meminfo", .limit = proc_meminfo_max_bytes },
        .loadavg => .{ .path = "/proc/loadavg", .limit = proc_loadavg_max_bytes },
    };
    var file = try std.Io.Dir.cwd().openFile(io, selection.path, .{});
    defer file.close(io);
    var buffer: [512]u8 = undefined;
    var reader = file.readerStreaming(io, &buffer);
    return reader.interface.allocRemaining(allocator, .limited(selection.limit)) catch |err| switch (err) {
        error.ReadFailed => return reader.err.?,
        error.OutOfMemory, error.StreamTooLong => |e| return e,
    };
}

fn parseAvailableMemory(contents: []const u8) !u64 {
    if (contents.len == 0 or contents.len > proc_meminfo_max_bytes) return error.InvalidRealRowsAvailableMemorySample;
    var available_bytes: ?u64 = null;
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        var fields = std.mem.tokenizeAny(u8, line, " \t\r");
        const name = fields.next() orelse continue;
        if (!std.mem.eql(u8, name, "MemAvailable:")) continue;
        if (available_bytes != null) return error.InvalidRealRowsAvailableMemorySample;
        const kib_text = fields.next() orelse return error.InvalidRealRowsAvailableMemorySample;
        const unit = fields.next() orelse return error.InvalidRealRowsAvailableMemorySample;
        if (!std.mem.eql(u8, unit, "kB") or fields.next() != null) return error.InvalidRealRowsAvailableMemorySample;
        const kib = std.fmt.parseUnsigned(u64, kib_text, 10) catch return error.InvalidRealRowsAvailableMemorySample;
        available_bytes = std.math.mul(u64, kib, 1024) catch return error.InvalidRealRowsAvailableMemorySample;
    }
    return available_bytes orelse error.InvalidRealRowsAvailableMemorySample;
}

fn parseLoadAverage(allocator: std.mem.Allocator, contents: []const u8) ![]u8 {
    if (contents.len == 0 or contents.len > proc_loadavg_max_bytes) return error.InvalidRealRowsLoadSample;
    var fields = std.mem.tokenizeAny(u8, contents, " \t\r\n");
    const load = fields.next() orelse return error.InvalidRealRowsLoadSample;
    var saw_dot = false;
    for (load, 0..) |byte, index| {
        if (std.ascii.isDigit(byte)) continue;
        if (byte != '.' or saw_dot or index == 0 or index + 1 == load.len) return error.InvalidRealRowsLoadSample;
        saw_dot = true;
    }
    const parsed = std.fmt.parseFloat(f64, load) catch return error.InvalidRealRowsLoadSample;
    if (!std.math.isFinite(parsed)) return error.InvalidRealRowsLoadSample;
    return allocator.dupe(u8, load);
}

fn observeResources(allocator: std.mem.Allocator, io: std.Io, options: ParentOptions, paths: *const OwnedPaths, resource: *ResourceState) !void {
    try resource.observe(
        try sampleFilesystem(allocator, io, paths.root, options),
        try sampleDiskBytes(allocator, io, paths.root, options),
        try sampleProcessTreeRssBytes(allocator, io, options),
        try sampleAvailableMemory(allocator, io, options),
    );
}

fn monitorBatch(allocator: std.mem.Allocator, io: std.Io, options: ParentOptions, paths: *const OwnedPaths, workers: []SpawnedWorker, resource: *ResourceState, control: *BatchControl) !void {
    while (!allWorkersDone(workers)) {
        observeResources(allocator, io, options, paths, resource) catch |err| {
            requestBatchTermination(io, paths, workers, options, control);
            return err;
        };
        if (anyWorkerFailed(workers)) requestBatchTermination(io, paths, workers, options, control);
        const interval = if (options.test_options) |test_options| test_options.monitor_interval_ns else monitor_interval_ns;
        try io.sleep(.fromNanoseconds(interval), .awake);
    }
}

fn runBatch(
    allocator: std.mem.Allocator,
    io: std.Io,
    options: ParentOptions,
    paths: *const OwnedPaths,
    mode_indices: []const usize,
    resource: *ResourceState,
    waits: *[mode_count]?WorkerWait,
    child_observations: *[mode_count]ChildFailureObservation,
) !void {
    var workers: [mode_count]SpawnedWorker = undefined;
    var worker_count: usize = 0;
    var primary_error: ?anyerror = null;
    for (mode_indices) |mode_index| {
        workers[worker_count] = spawnWorker(allocator, io, options, paths, mode_index) catch |err| {
            primary_error = err;
            break;
        };
        child_observations[mode_index] = .{ .state = .not_reaped };
        worker_count += 1;
    }
    var futures: [mode_count]WorkerFuture = undefined;
    var future_count: usize = 0;
    if (primary_error == null) for (workers[0..worker_count], 0..) |*worker, index| {
        if (options.test_options) |test_options| if (test_options.fail_wait_future_before_index == index) {
            primary_error = error.InjectedRealRowsWaitFutureSetupFailure;
            break;
        };
        futures[index] = io.concurrent(waitWorker, .{ io, &worker.child, &worker.state, worker.start }) catch |err| {
            primary_error = err;
            break;
        };
        worker.wait_future_started = true;
        if (options.test_options) |test_options| test_options.audit.wait_futures_started[worker.mode_index] += 1;
        future_count += 1;
    };
    var control: BatchControl = .{};
    if (primary_error == null) {
        monitorBatch(allocator, io, options, paths, workers[0..worker_count], resource, &control) catch |err| {
            primary_error = err;
            requestBatchTermination(io, paths, workers[0..worker_count], options, &control);
        };
        if (anyWorkerFailed(workers[0..worker_count])) requestBatchTermination(io, paths, workers[0..worker_count], options, &control);
    } else requestBatchTermination(io, paths, workers[0..worker_count], options, &control);

    var first_wait_error: ?anyerror = null;
    for (workers[0..future_count], 0..) |*worker, index| {
        const wait = futures[index].await(io) catch |err| {
            if (first_wait_error == null) first_wait_error = err;
            worker.state.failed.store(true, .release);
            if (worker.child.id != null) directlyKillAndReap(io, worker, options) else markReaped(worker, options);
            child_observations[worker.mode_index] = .{
                .state = .reaped,
                .max_rss_bytes = worker.child.resource_usage_statistics.getMaxRss(),
            };
            continue;
        };
        waits[worker.mode_index] = wait;
        if (!common.termOk(wait.term)) worker.state.failed.store(true, .release);
        markReaped(worker, options);
        child_observations[worker.mode_index] = .{ .state = .reaped, .max_rss_bytes = wait.max_rss_bytes };
    }
    for (workers[future_count..worker_count]) |*worker| {
        directlyKillAndReap(io, worker, options);
        child_observations[worker.mode_index] = .{
            .state = .reaped,
            .max_rss_bytes = worker.child.resource_usage_statistics.getMaxRss(),
        };
    }
    if (primary_error == null) {
        if (first_wait_error) |err| primary_error = err;
    }
    if (primary_error == null and anyWorkerFailed(workers[0..worker_count])) primary_error = error.RealRowsParallelChildFailed;
    if (primary_error != null) requestSharedStop(io, paths, options, &control);
    var first_close_error: ?anyerror = null;
    for (workers[0..worker_count]) |*worker| closeWorkerFiles(io, worker, options) catch |err| if (first_close_error == null) {
        first_close_error = err;
    };
    if (primary_error) |err| return err;
    if (first_close_error) |err| return err;
}

fn writeFailureManifest(
    writer: *std.Io.Writer,
    resource: *const ResourceState,
    child_observations: [mode_count]ChildFailureObservation,
    waits: [mode_count]?WorkerWait,
    failure: anyerror,
    run_id: *const [32]u8,
) !void {
    try writer.print("schema=2 run_id={s} failure={s} success_summary_emitted=false\n", .{ run_id, @errorName(failure) });
    try writer.print(
        "resource_state memory_policy={s} samples={} starting_free_bytes={} minimum_free_bytes={} final_free_bytes={} peak_disk_bytes={} peak_aggregate_rss_bytes={} minimum_available_memory_bytes={} last_free_bytes={} last_disk_bytes={} last_aggregate_rss_bytes={} last_available_memory_bytes={}\n",
        .{
            memory_policy_label,
            resource.samples,
            resource.starting_free_bytes,
            resource.minimum_free_bytes,
            resource.final_free_bytes,
            resource.peak_disk_bytes,
            resource.peak_aggregate_rss_bytes,
            resource.minimum_available_memory_bytes,
            resource.last_free_bytes,
            resource.last_disk_bytes,
            resource.last_aggregate_rss_bytes,
            resource.last_available_memory_bytes,
        },
    );
    for (modes, child_observations, waits) |mode, observation, wait| switch (observation.state) {
        .not_launched => {
            if (observation.max_rss_bytes != null or wait != null) return error.RealRowsParallelFailureTopologyInvalid;
            try writer.print("mode={s} child_state=not-launched max_rss_bytes=unavailable term=unavailable duration_ms=unavailable\n", .{mode});
        },
        .not_reaped => {
            if (observation.max_rss_bytes != null or wait != null) return error.RealRowsParallelFailureTopologyInvalid;
            try writer.print("mode={s} child_state=not-reaped max_rss_bytes=unavailable term=unavailable duration_ms=unavailable\n", .{mode});
        },
        .reaped => {
            if (wait) |value| {
                if (observation.max_rss_bytes != value.max_rss_bytes) return error.RealRowsParallelFailureTopologyInvalid;
                if (observation.max_rss_bytes) |max_rss_bytes|
                    try writer.print("mode={s} child_state=reaped max_rss_bytes={} term={any} duration_ms={}\n", .{ mode, max_rss_bytes, value.term, value.duration_ms })
                else
                    try writer.print("mode={s} child_state=reaped max_rss_bytes=unavailable term={any} duration_ms={}\n", .{ mode, value.term, value.duration_ms });
            } else if (observation.max_rss_bytes) |max_rss_bytes| {
                try writer.print("mode={s} child_state=reaped max_rss_bytes={} term=unavailable duration_ms=unavailable\n", .{ mode, max_rss_bytes });
            } else {
                try writer.print("mode={s} child_state=reaped max_rss_bytes=unavailable term=unavailable duration_ms=unavailable\n", .{mode});
            }
        },
    };
}

fn copyFailureStreamBounded(io: std.Io, source_path: []const u8, destination_path: []const u8, maximum_bytes: u64) !u64 {
    var cwd = std.Io.Dir.cwd();
    var source = try cwd.openFile(io, source_path, .{ .allow_directory = false, .follow_symlinks = false });
    defer source.close(io);
    const before = try source.stat(io);
    if (before.kind != .file) return error.RealRowsParallelFailureEvidenceSourceNotFile;
    if (before.size > maximum_bytes) return error.RealRowsParallelFailureEvidenceSourceTooLarge;

    var destination = try cwd.createFile(io, destination_path, .{ .exclusive = true });
    defer destination.close(io);
    var read_buffer: [16 * 1024]u8 = undefined;
    var source_reader = source.readerStreaming(io, &read_buffer);
    var write_buffer: [16 * 1024]u8 = undefined;
    var destination_writer = destination.writerStreaming(io, &write_buffer);
    try source_reader.interface.streamExact64(&destination_writer.interface, before.size);
    if (source_reader.interface.takeByte()) |_| {
        return error.RealRowsParallelFailureEvidenceSourceLengthDrift;
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }
    try destination_writer.interface.flush();
    try destination.sync(io);

    const after_open = try source.stat(io);
    var reopened = try cwd.openFile(io, source_path, .{ .allow_directory = false, .follow_symlinks = false });
    defer reopened.close(io);
    const after_path = try reopened.stat(io);
    if (after_open.kind != .file or
        after_path.kind != .file or
        after_open.inode != before.inode or
        after_path.inode != before.inode or
        after_open.size != before.size or
        after_path.size != before.size or
        after_open.permissions.toMode() != before.permissions.toMode() or
        after_path.permissions.toMode() != before.permissions.toMode())
    {
        return error.RealRowsParallelFailureEvidenceSourceMetadataDrift;
    }
    const destination_stat = try destination.stat(io);
    if (destination_stat.kind != .file or destination_stat.size != before.size)
        return error.RealRowsParallelFailureEvidenceDestinationMismatch;
    return before.size;
}

fn preserveFailureStream(
    allocator: std.mem.Allocator,
    io: std.Io,
    writer: *std.Io.Writer,
    evidence_dir: []const u8,
    run_id: *const [32]u8,
    mode: []const u8,
    stream_name: []const u8,
    suffix: []const u8,
    source_path: []const u8,
    maximum_bytes: u64,
) !void {
    const evidence_name = try std.fmt.allocPrint(allocator, "{s}.{s}.{s}", .{ run_id, mode, suffix });
    defer allocator.free(evidence_name);
    const evidence_path = try std.fs.path.join(allocator, &.{ evidence_dir, evidence_name });
    defer allocator.free(evidence_path);
    const copied_bytes = copyFailureStreamBounded(io, source_path, evidence_path, maximum_bytes) catch |err| {
        try writer.print("mode={s} failure_evidence_stream={s} status=copy-failed error={s}\n", .{ mode, stream_name, @errorName(err) });
        return;
    };
    try writer.print("mode={s} failure_evidence_stream={s} status=preserved bytes={}\n", .{ mode, stream_name, copied_bytes });
}

fn preserveFailureEvidence(
    allocator: std.mem.Allocator,
    io: std.Io,
    options: ParentOptions,
    paths: *const OwnedPaths,
    resource: *const ResourceState,
    child_observations: [mode_count]ChildFailureObservation,
    waits: [mode_count]?WorkerWait,
    failure: anyerror,
) !void {
    const evidence_dir = if (options.test_options) |test_options| test_options.failure_evidence_dir else paths.failure_root;
    var cwd = std.Io.Dir.cwd();
    try cwd.createDirPath(io, evidence_dir);
    const manifest_name = try std.fmt.allocPrint(allocator, "{s}.manifest", .{&paths.run_id});
    defer allocator.free(manifest_name);
    const manifest_path = try std.fs.path.join(allocator, &.{ evidence_dir, manifest_name });
    defer allocator.free(manifest_path);
    var buffer: [4096]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);
    try writeFailureManifest(&writer, resource, child_observations, waits, failure, &paths.run_id);
    for (modes, 0..) |mode, index| {
        if (child_observations[index].state == .not_launched) continue;
        try preserveFailureStream(
            allocator,
            io,
            &writer,
            evidence_dir,
            &paths.run_id,
            mode,
            "stdout",
            "result",
            paths.mode_paths[index].result,
            failure_stdout_max_bytes,
        );
        try preserveFailureStream(
            allocator,
            io,
            &writer,
            evidence_dir,
            &paths.run_id,
            mode,
            "stderr",
            "log",
            paths.mode_paths[index].log,
            failure_stderr_max_bytes,
        );
    }
    try cwd.writeFile(io, .{ .sub_path = manifest_path, .data = writer.buffered() });
    if (options.test_options) |test_options| {
        test_options.audit.evidence_preserved_before_cleanup = try pathExists(io, paths.root);
        test_options.audit.failure_run_id = paths.run_id;
        test_options.audit.failure_run_id_recorded = true;
    }
}

fn preserveFailureEvidenceKeepingPrimary(
    allocator: std.mem.Allocator,
    io: std.Io,
    options: ParentOptions,
    paths: *const OwnedPaths,
    resource: *const ResourceState,
    child_observations: [mode_count]ChildFailureObservation,
    waits: [mode_count]?WorkerWait,
    failure: anyerror,
) void {
    preserveFailureEvidence(allocator, io, options, paths, resource, child_observations, waits, failure) catch |evidence_error| {
        std.debug.print(
            "real-row failure evidence preservation failed primary={s} evidence={s}\n",
            .{ @errorName(failure), @errorName(evidence_error) },
        );
    };
}

fn validateWorkerOutput(output: []const u8, mode: []const u8, cache_mode: CacheMode) !void {
    return cohort_output.validate(output, mode, cache_mode);
}

fn collectCompleted(
    allocator: std.mem.Allocator,
    io: std.Io,
    options: ParentOptions,
    paths: *const OwnedPaths,
    waits: [mode_count]?WorkerWait,
) ![mode_count]Completed {
    var completed: [mode_count]Completed = undefined;
    var initialized: usize = 0;
    errdefer for (completed[0..initialized]) |item| common.freeRunResult(allocator, item.result);
    for (&completed, waits, paths.mode_paths, modes) |*item, maybe_wait, mode_path, mode| {
        const wait = maybe_wait orelse return error.RealRowsParallelMissingWaitResult;
        const stdout = try std.Io.Dir.cwd().readFileAlloc(io, mode_path.result, allocator, .limited(failure_stdout_max_bytes));
        errdefer allocator.free(stdout);
        const stderr = try std.Io.Dir.cwd().readFileAlloc(io, mode_path.log, allocator, .limited(failure_stderr_max_bytes));
        errdefer allocator.free(stderr);
        if (!common.termOk(wait.term)) return error.RealRowsParallelChildFailed;
        if (stderr.len != 0) return error.RealRowsParallelUnexpectedStderr;
        if (options.test_options == null) try validateWorkerOutput(stdout, mode, options.cache_mode);
        item.* = .{ .result = .{ .term = wait.term, .stdout = stdout, .stderr = stderr }, .duration_ms = wait.duration_ms };
        initialized += 1;
    }
    return completed;
}

pub fn runGroup(allocator: std.mem.Allocator, io: std.Io, provided_options: ParentOptions) !GroupResult {
    var options = provided_options;
    if (options.zig_emitter_path == null) {
        if (options.test_options == null) return error.RealRowsZigEmitterMissing;
        options.zig_emitter_path = "/test/stage4/zig";
    } else if (options.test_options == null) {
        try requireCanonicalAbsoluteExecutable(allocator, io, options.zig_emitter_path.?);
    }
    if (options.concurrency != 1 and options.concurrency != 3) return error.InvalidRealRowsConcurrency;
    const export_cache_path = options.export_cache_path orelse return error.RealRowsRootSelectionMissing;
    var paths = try OwnedPaths.init(allocator, io, options.scratch_path, export_cache_path, options.cache_mode);
    defer paths.deinit();
    const wall_start = std.Io.Timestamp.now(io, .awake);
    const preflight = try sampleFilesystem(allocator, io, paths.root, options);
    const policy = try policy_authority.forFilesystem(preflight.total_bytes);
    if (preflight.free_bytes < policy.required_start_bytes) return error.InsufficientRealRowsParallelHeadroom;
    const available_memory = try sampleAvailableMemory(allocator, io, options);
    var pins: [mode_count]CachePin = undefined;
    if (options.cache_mode == .require_hit) pins = try probeAndPin(allocator, io, options, &paths);
    var resource: ResourceState = .{
        .filesystem_total_bytes = preflight.total_bytes,
        .post_run_free_floor_bytes = policy.post_run_free_floor_bytes,
        .starting_free_bytes = preflight.free_bytes,
        .minimum_free_bytes = preflight.free_bytes,
        .final_free_bytes = preflight.free_bytes,
        .minimum_available_memory_bytes = available_memory,
    };
    const load_start = if (options.test_options != null) try allocator.dupe(u8, "fixture") else try readLoadAverage(allocator, io);
    errdefer allocator.free(load_start);
    var waits: [mode_count]?WorkerWait = .{ null, null, null };
    var child_observations: [mode_count]ChildFailureObservation = .{ .{}, .{}, .{} };
    if (options.concurrency == 1) {
        for (0..mode_count) |index| {
            const one = [_]usize{index};
            runBatch(allocator, io, options, &paths, &one, &resource, &waits, &child_observations) catch |err| {
                preserveFailureEvidenceKeepingPrimary(allocator, io, options, &paths, &resource, child_observations, waits, err);
                return err;
            };
        }
    } else {
        const all = [_]usize{ 0, 1, 2 };
        runBatch(allocator, io, options, &paths, &all, &resource, &waits, &child_observations) catch |err| {
            preserveFailureEvidenceKeepingPrimary(allocator, io, options, &paths, &resource, child_observations, waits, err);
            return err;
        };
    }
    observeResources(allocator, io, options, &paths, &resource) catch |err| {
        preserveFailureEvidenceKeepingPrimary(allocator, io, options, &paths, &resource, child_observations, waits, err);
        return err;
    };
    if (options.cache_mode == .fresh) pins = probeAndPin(allocator, io, options, &paths) catch |err| {
        preserveFailureEvidenceKeepingPrimary(allocator, io, options, &paths, &resource, child_observations, waits, err);
        return err;
    };
    const pin_manifest_sha256 = try sha256File(allocator, io, paths.pin_manifest);
    for (pins, paths.mode_paths) |pin, mode_path| if (options.test_options == null) {
        verifyPin(allocator, io, pin, mode_path.export_cache) catch |err| {
            preserveFailureEvidenceKeepingPrimary(allocator, io, options, &paths, &resource, child_observations, waits, err);
            return err;
        };
    };
    const completed = collectCompleted(allocator, io, options, &paths, waits) catch |err| {
        preserveFailureEvidenceKeepingPrimary(allocator, io, options, &paths, &resource, child_observations, waits, err);
        return err;
    };
    errdefer for (completed) |item| common.freeRunResult(allocator, item.result);
    var summed_child_ms: i96 = 0;
    for (waits) |maybe_wait| {
        const wait = maybe_wait orelse return error.RealRowsParallelMissingWaitResult;
        summed_child_ms += wait.duration_ms;
    }
    const load_end = if (options.test_options != null) try allocator.dupe(u8, "fixture") else try readLoadAverage(allocator, io);
    errdefer allocator.free(load_end);
    const evidence_root = try allocator.dupe(u8, paths.root);
    errdefer allocator.free(evidence_root);
    const work_selection_root = try allocator.dupe(u8, options.scratch_path);
    errdefer allocator.free(work_selection_root);
    const export_cache_selection_root = try allocator.dupe(u8, export_cache_path);
    errdefer allocator.free(export_cache_selection_root);
    return .{
        .completed = completed,
        .evidence = .{
            .cache_mode = options.cache_mode,
            .concurrency = options.concurrency,
            .run_id = paths.run_id,
            .root = evidence_root,
            .work_selection_root = work_selection_root,
            .export_cache_selection_root = export_cache_selection_root,
            .pin_manifest_sha256 = pin_manifest_sha256,
            .wall_ms = elapsedMs(io, wall_start),
            .summed_child_ms = summed_child_ms,
            .filesystem_total_bytes = policy.filesystem_total_bytes,
            .post_run_free_floor_bytes = policy.post_run_free_floor_bytes,
            .projected_peak_bytes = policy.projected_peak_bytes,
            .required_start_bytes = policy.required_start_bytes,
            .starting_free_bytes = resource.starting_free_bytes,
            .minimum_free_bytes = resource.minimum_free_bytes,
            .final_free_bytes = resource.final_free_bytes,
            .peak_disk_bytes = resource.peak_disk_bytes,
            .peak_aggregate_rss_bytes = resource.peak_aggregate_rss_bytes,
            .minimum_available_memory_bytes = resource.minimum_available_memory_bytes,
            .load_start = load_start,
            .load_end = load_end,
        },
    };
}

fn requireCanonicalAbsoluteExecutable(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !void {
    if (!std.fs.path.isAbsolute(path)) return error.RealRowsZigEmitterInvalid;
    const canonical = std.Io.Dir.realPathFileAbsoluteAlloc(io, path, allocator) catch return error.RealRowsZigEmitterInvalid;
    defer allocator.free(canonical);
    if (!std.mem.eql(u8, canonical, path)) return error.RealRowsZigEmitterInvalid;
    const file = std.Io.Dir.openFileAbsolute(io, path, .{ .allow_directory = false, .follow_symlinks = false }) catch return error.RealRowsZigEmitterInvalid;
    defer file.close(io);
    std.Io.Dir.cwd().access(io, path, .{ .execute = true }) catch return error.RealRowsZigEmitterInvalid;
}

pub fn writeEvidence(writer: *std.Io.Writer, evidence: *const Evidence) !void {
    const cache_status: []const u8 = if (evidence.cache_mode == .fresh) "fresh-export,fresh-export,fresh-export" else "hit,hit,hit";
    const air_cache: []const u8 = if (evidence.cache_mode == .fresh) "populated-authenticated" else "read-only";
    try writer.print(
        "real-rows-mode-parallel schema_version={} normalization_schema={} memory_policy={s} concurrency={} workers=3 modes=ReleaseFast,ReleaseSafe,ReleaseSmall run_id={s} root={s} work_selection_root={s} export_cache_selection_root={s} fast_temp={s}/ReleaseFast/work_{s} fast_local_cache={s}/ReleaseFast/zig-local-cache fast_global_cache={s}/ReleaseFast/zig-global-cache fast_air_cache={s}/ReleaseFast/export safe_temp={s}/ReleaseSafe/work_{s} safe_local_cache={s}/ReleaseSafe/zig-local-cache safe_global_cache={s}/ReleaseSafe/zig-global-cache safe_air_cache={s}/ReleaseSafe/export small_temp={s}/ReleaseSmall/work_{s} small_local_cache={s}/ReleaseSmall/zig-local-cache small_global_cache={s}/ReleaseSmall/zig-global-cache small_air_cache={s}/ReleaseSmall/export pin_manifest_sha256={s} cache_status={s} air_cache={s} pruning=suspended ",
        .{
            normalization_schema_version,
            normalization_schema_version,
            memory_policy_label,
            evidence.concurrency,
            &evidence.run_id,
            evidence.root,
            evidence.work_selection_root,
            evidence.export_cache_selection_root,
            evidence.work_selection_root,
            &evidence.run_id,
            evidence.root,
            evidence.root,
            evidence.export_cache_selection_root,
            evidence.work_selection_root,
            &evidence.run_id,
            evidence.root,
            evidence.root,
            evidence.export_cache_selection_root,
            evidence.work_selection_root,
            &evidence.run_id,
            evidence.root,
            evidence.root,
            evidence.export_cache_selection_root,
            &evidence.pin_manifest_sha256,
            cache_status,
            air_cache,
        },
    );
    try writer.print(
        "wall_ms={} summed_child_ms={} filesystem_total_bytes={} post_run_free_floor_bytes={} projected_peak_bytes={} required_start_bytes={} starting_free_bytes={} minimum_free_bytes={} final_free_bytes={} peak_disk_bytes={} peak_aggregate_rss_bytes={} minimum_available_memory_bytes={} load_start={s} load_end={s} execution_results_cached=false local_fail=0\n",
        .{
            evidence.wall_ms,
            evidence.summed_child_ms,
            evidence.filesystem_total_bytes,
            evidence.post_run_free_floor_bytes,
            evidence.projected_peak_bytes,
            evidence.required_start_bytes,
            evidence.starting_free_bytes,
            evidence.minimum_free_bytes,
            evidence.final_free_bytes,
            evidence.peak_disk_bytes,
            evidence.peak_aggregate_rss_bytes,
            evidence.minimum_available_memory_bytes,
            evidence.load_start,
            evidence.load_end,
        },
    );
}

fn requireParallelEvidenceSchema(line: []const u8) !void {
    const schema = fieldValue(line, "schema_version=") orelse return error.RealRowsParallelEvidenceSchemaMissing;
    const normalization = fieldValue(line, "normalization_schema=") orelse return error.RealRowsParallelEvidenceSchemaMissing;
    if (!std.mem.eql(u8, schema, "2") or !std.mem.eql(u8, normalization, "2")) {
        return error.RealRowsParallelEvidenceSchemaMismatch;
    }
}

pub fn writeNormalizedOutput(output: []const u8, writer: *std.Io.Writer) !void {
    const volatile_prefixes = [_][]const u8{
        "duration_ms=",                    "wall_ms=",            "summed_child_ms=",  "run_id=",          "root=",
        "starting_free_bytes=",            "minimum_free_bytes=", "final_free_bytes=", "peak_disk_bytes=", "peak_aggregate_rss_bytes=",
        "minimum_available_memory_bytes=", "load_start=",         "load_end=",
    };
    var evidence_count: usize = 0;
    var lines = std.mem.splitScalar(u8, output, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        if (std.mem.startsWith(u8, line, "real-rows-mode-parallel ")) {
            evidence_count += 1;
            if (evidence_count != 1) return error.RealRowsParallelEvidenceDuplicate;
            try requireParallelEvidenceSchema(line);
            continue;
        }
        var fields = std.mem.tokenizeScalar(u8, line, ' ');
        var first = true;
        while (fields.next()) |field| {
            if (!first) try writer.writeByte(' ');
            first = false;
            var normalized = false;
            for (volatile_prefixes) |prefix| if (std.mem.startsWith(u8, field, prefix)) {
                try writer.print("{s}<volatile>", .{prefix});
                normalized = true;
                break;
            };
            if (!normalized) try writer.writeAll(field);
        }
        try writer.writeByte('\n');
    }
    if (evidence_count != 1) return error.RealRowsParallelEvidenceSchemaMissing;
}

fn elapsedMs(io: std.Io, start: std.Io.Timestamp) i96 {
    return @divTrunc(start.durationTo(std.Io.Timestamp.now(io, .awake)).nanoseconds, std.time.ns_per_ms);
}

fn pathExists(io: std.Io, path: []const u8) !bool {
    std.Io.Dir.cwd().access(io, path, .{}) catch |err| switch (err) {
        error.FileNotFound => return false,
        else => return err,
    };
    return true;
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    var concurrency: u8 = 3;
    var scratch_root: ?[]const u8 = null;
    var export_cache_root: ?[]const u8 = null;
    var zig_emitter: ?[]const u8 = null;
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.skip();
    while (args.next()) |arg| {
        if (std.mem.startsWith(u8, arg, "--concurrency=")) {
            concurrency = try std.fmt.parseUnsigned(u8, arg["--concurrency=".len..], 10);
        } else if (std.mem.startsWith(u8, arg, "--scratch-root=")) {
            if (scratch_root != null) return error.DuplicateRealRowsScratchRoot;
            scratch_root = arg["--scratch-root=".len..];
        } else if (std.mem.startsWith(u8, arg, "--export-cache-root=")) {
            if (export_cache_root != null) return error.DuplicateRealRowsExportCacheRoot;
            export_cache_root = arg["--export-cache-root=".len..];
        } else if (std.mem.startsWith(u8, arg, "--zig-emitter=")) {
            if (zig_emitter != null) return error.DuplicateRealRowsZigEmitter;
            zig_emitter = arg["--zig-emitter=".len..];
        } else return error.UnexpectedArgument;
    }
    if (concurrency != 1 and concurrency != 3) return error.InvalidRealRowsConcurrency;
    const selected_scratch_root = scratch_root orelse return error.RealRowsRootSelectionMissing;
    const selected_export_cache_root = export_cache_root orelse return error.RealRowsRootSelectionMissing;
    const selected_zig_emitter = zig_emitter orelse return error.RealRowsZigEmitterMissing;
    const target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);
    const target = target_env orelse "x86_64-unknown-linux-gnu";
    const target_assignment = try std.fmt.allocPrint(allocator, "TARGET={s}", .{target});
    defer allocator.free(target_assignment);
    var result = try runGroup(allocator, io, .{
        .target_assignment = target_assignment,
        .zig_emitter_path = selected_zig_emitter,
        .scratch_path = selected_scratch_root,
        .export_cache_path = selected_export_cache_root,
        .concurrency = concurrency,
    });
    defer result.deinit(allocator);
    var buffer: [4096]u8 = undefined;
    var stdout = std.Io.File.stdout().writer(io, &buffer);
    for (result.completed) |completed| try stdout.interface.writeAll(completed.result.stdout);
    try writeEvidence(&stdout.interface, &result.evidence);
    try stdout.interface.flush();
}

fn joinedArgv(allocator: std.mem.Allocator, argv: []const []const u8) ![]u8 {
    return std.mem.join(allocator, " ", argv);
}

test "fixed group contains exactly fast safe small in manifest order" {
    try std.testing.expectEqual(@as(usize, 3), modes.len);
    try std.testing.expectEqualStrings("ReleaseFast", modes[0]);
    try std.testing.expectEqualStrings("ReleaseSafe", modes[1]);
    try std.testing.expectEqualStrings("ReleaseSmall", modes[2]);
}

test "available memory parser requires one bounded checked MemAvailable kB field" {
    try std.testing.expectEqual(
        @as(u64, 125_952),
        try parseAvailableMemory(
            \\MemTotal:       1024 kB
            \\MemAvailable:    123 kB
            \\
        ),
    );
    try std.testing.expectError(
        error.InvalidRealRowsAvailableMemorySample,
        parseAvailableMemory("MemTotal: 1024 kB\n"),
    );
    try std.testing.expectError(
        error.InvalidRealRowsAvailableMemorySample,
        parseAvailableMemory("MemAvailable: 1 kB\nMemAvailable: 2 kB\n"),
    );
    try std.testing.expectError(
        error.InvalidRealRowsAvailableMemorySample,
        parseAvailableMemory("MemAvailable: 1 MB\n"),
    );
    try std.testing.expectError(
        error.InvalidRealRowsAvailableMemorySample,
        parseAvailableMemory("MemAvailable: not-a-number kB\n"),
    );
    try std.testing.expectError(
        error.InvalidRealRowsAvailableMemorySample,
        parseAvailableMemory("MemAvailable: 18014398509481984 kB\n"),
    );
    var over_bound: [proc_meminfo_max_bytes + 1]u8 = undefined;
    @memset(&over_bound, 'x');
    try std.testing.expectError(
        error.InvalidRealRowsAvailableMemorySample,
        parseAvailableMemory(&over_bound),
    );
}

test "load average parser accepts one bounded decimal token and rejects malformed input" {
    const allocator = std.testing.allocator;
    const load = try parseLoadAverage(allocator, "1.25 0.75 0.50 1/2 3\n");
    defer allocator.free(load);
    try std.testing.expectEqualStrings("1.25", load);

    for ([_][]const u8{
        "",
        " \t\r\n",
        ".25 0 0 1/2 3\n",
        "1. 0 0 1/2 3\n",
        "-1.0 0 0 1/2 3\n",
        "1e3 0 0 1/2 3\n",
    }) |malformed| {
        try std.testing.expectError(
            error.InvalidRealRowsLoadSample,
            parseLoadAverage(allocator, malformed),
        );
    }
    var over_bound: [proc_loadavg_max_bytes + 1]u8 = undefined;
    @memset(&over_bound, '0');
    try std.testing.expectError(
        error.InvalidRealRowsLoadSample,
        parseLoadAverage(allocator, &over_bound),
    );
}

test "production argv construction covers every actual mode and isolated path" {
    const allocator = std.testing.allocator;
    for (modes, 0..) |mode, index| {
        const root = try std.fmt.allocPrint(allocator, "owned/{s}", .{mode});
        defer allocator.free(root);
        var paths: ModePaths = .{
            .root = try allocator.dupe(u8, root),
            .work = try std.fmt.allocPrint(allocator, "{s}/work", .{root}),
            .local_cache = try std.fmt.allocPrint(allocator, "{s}/local", .{root}),
            .global_cache = try std.fmt.allocPrint(allocator, "{s}/global", .{root}),
            .export_cache = try std.fmt.allocPrint(allocator, "cache/contract/{s}/export", .{mode}),
            .result = try std.fmt.allocPrint(allocator, "{s}/result", .{root}),
            .log = try std.fmt.allocPrint(allocator, "{s}/log", .{root}),
        };
        defer paths.deinit(allocator);
        var argv = try buildWorkerArgv(allocator, "TARGET=x86_64-unknown-linux-gnu", "/test/stage4/zig", index, paths, .require_hit, false);
        defer argv.deinit();
        const joined = try joinedArgv(allocator, argv.argv.items);
        defer allocator.free(joined);
        const mode_arg = try std.fmt.allocPrint(allocator, "--mode={s}", .{mode});
        defer allocator.free(mode_arg);
        try std.testing.expect(std.mem.indexOf(u8, joined, mode_arg) != null);
        try std.testing.expect(std.mem.indexOf(u8, joined, "ZIG_EMITTER=/test/stage4/zig") != null);
        try std.testing.expect(std.mem.indexOf(u8, joined, "--require-cache-hit") != null);
        const temp_arg = try std.fmt.allocPrint(allocator, "--runner-temp-root={s}/work", .{root});
        defer allocator.free(temp_arg);
        const local_arg = try std.fmt.allocPrint(allocator, "ZIG_LOCAL_CACHE_DIR={s}/local", .{root});
        defer allocator.free(local_arg);
        const global_arg = try std.fmt.allocPrint(allocator, "ZIG_GLOBAL_CACHE_DIR={s}/global", .{root});
        defer allocator.free(global_arg);
        const export_arg = try std.fmt.allocPrint(allocator, "--export-cache-root=cache/contract/{s}/export", .{mode});
        defer allocator.free(export_arg);
        try std.testing.expect(std.mem.indexOf(u8, joined, temp_arg) != null);
        try std.testing.expect(std.mem.indexOf(u8, joined, local_arg) != null);
        try std.testing.expect(std.mem.indexOf(u8, joined, global_arg) != null);
        try std.testing.expect(std.mem.indexOf(u8, joined, export_arg) != null);
        var fresh = try buildWorkerArgv(allocator, "TARGET=x86_64-unknown-linux-gnu", "/test/stage4/zig", index, paths, .fresh, false);
        defer fresh.deinit();
        const fresh_joined = try joinedArgv(allocator, fresh.argv.items);
        defer allocator.free(fresh_joined);
        try std.testing.expect(std.mem.indexOf(u8, fresh_joined, "--fresh-export") != null);
        try std.testing.expect(std.mem.indexOf(u8, fresh_joined, "--require-cache-hit") == null);
        var probe = try buildWorkerArgv(allocator, "TARGET=x86_64-unknown-linux-gnu", "/test/stage4/zig", index, paths, .fresh, true);
        defer probe.deinit();
        const probe_joined = try joinedArgv(allocator, probe.argv.items);
        defer allocator.free(probe_joined);
        try std.testing.expect(std.mem.indexOf(u8, probe_joined, temp_arg) != null);
        try std.testing.expect(std.mem.indexOf(u8, probe_joined, export_arg) != null);
        try std.testing.expect(std.mem.indexOf(u8, probe_joined, "--cache-probe-only") != null);
    }
}

test "cache policy admits only explicit fresh or authenticated hit operation" {
    try std.testing.expectEqualStrings("fresh", @tagName(CacheMode.fresh));
    try std.testing.expectEqualStrings("require_hit", @tagName(CacheMode.require_hit));
}

test "root selections reject missing absolute escape symlink owner and mode drift before execution" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();
    var roots = try fixtureRoots(allocator, io, &temp);
    defer roots.deinit(allocator);
    var audit: LifecycleAudit = .{};
    var test_options: TestOptions = .{
        .filesystem_sample = .{ .total_bytes = 100 * 1024 * 1024 * 1024, .free_bytes = 90 * 1024 * 1024 * 1024 },
        .failure_evidence_dir = roots.scratch,
        .audit = &audit,
    };
    try std.testing.expectError(error.RealRowsRootSelectionMissing, runGroup(allocator, io, .{
        .target_assignment = "TARGET=test",
        .scratch_path = roots.scratch,
        .concurrency = 3,
        .test_options = &test_options,
    }));
    try std.testing.expectError(error.RealRowsRootSelectionInvalid, requireCanonicalContractBase(io, "/absolute/root"));
    try std.testing.expectError(error.RealRowsRootSelectionInvalid, requireCanonicalContractBase(io, "relative/../escape"));

    const base = std.fs.path.dirname(std.fs.path.dirname(roots.scratch).?).?;
    const other_cache = try std.fs.path.join(allocator, &.{ base, "cache", "other-contract" });
    defer allocator.free(other_cache);
    try std.Io.Dir.cwd().createDirPath(io, other_cache);
    try std.testing.expectError(error.RealRowsRootSelectionMismatch, OwnedPaths.init(allocator, io, roots.scratch, other_cache, .require_hit));

    const symlink = try std.fs.path.join(allocator, &.{ base, "linked-contract" });
    defer allocator.free(symlink);
    try std.Io.Dir.cwd().symLink(io, "validation/contract", symlink, .{ .is_directory = true });
    try std.testing.expectError(error.RealRowsRootSelectionInvalid, requireCanonicalContractBase(io, symlink));

    const wrong_mode = try std.fs.path.join(allocator, &.{ roots.cache, "ReleaseSafe", "export" });
    defer allocator.free(wrong_mode);
    try std.testing.expectError(error.RealRowsRootSelectionModeMismatch, requireCanonicalModeOwnedDirectory(io, wrong_mode, "ReleaseFast"));
    try std.testing.expectEqual(@as(usize, 0), audit.launched[0] + audit.launched[1] + audit.launched[2]);
}

test "fixed capacity admits exact start boundary emits schema two and rejects insufficient capacity" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();
    var roots = try fixtureRoots(allocator, io, &temp);
    defer roots.deinit(allocator);
    var audit: LifecycleAudit = .{};
    var test_options: TestOptions = .{
        .worker_fixture = .success,
        .filesystem_sample = .{ .total_bytes = policy_authority.required_start_bytes, .free_bytes = policy_authority.required_start_bytes },
        .failure_evidence_dir = roots.scratch,
        .audit = &audit,
    };
    var result = try runGroup(allocator, io, .{ .target_assignment = "TARGET=test", .scratch_path = roots.scratch, .export_cache_path = roots.cache, .concurrency = 3, .test_options = &test_options });
    defer result.deinit(allocator);
    try std.testing.expectEqual(policy_authority.post_run_free_floor_bytes, result.evidence.post_run_free_floor_bytes);
    try std.testing.expectEqual(policy_authority.projected_disk_peak_bytes, result.evidence.projected_peak_bytes);
    try std.testing.expectEqual(policy_authority.required_start_bytes, result.evidence.required_start_bytes);
    try std.testing.expectEqual(policy_authority.required_start_bytes, result.evidence.starting_free_bytes);
    try std.testing.expectEqual(policy_authority.required_start_bytes, result.evidence.minimum_free_bytes);
    try std.testing.expectEqual(policy_authority.required_start_bytes, result.evidence.final_free_bytes);
    var evidence_buffer: [8192]u8 = undefined;
    var evidence_writer = std.Io.Writer.fixed(&evidence_buffer);
    try writeEvidence(&evidence_writer, &result.evidence);
    const evidence = evidence_writer.buffered();
    try std.testing.expect(std.mem.indexOf(u8, evidence, "schema_version=2 normalization_schema=2") != null);
    try std.testing.expect(std.mem.indexOf(u8, evidence, "post_run_free_floor_bytes=34359738368") != null);
    try std.testing.expect(std.mem.indexOf(u8, evidence, "projected_peak_bytes=4834125664") != null);
    try std.testing.expect(std.mem.indexOf(u8, evidence, "required_start_bytes=39193864032") != null);

    audit = .{};
    test_options.filesystem_sample = .{ .total_bytes = policy_authority.required_start_bytes, .free_bytes = policy_authority.required_start_bytes - 1 };
    try std.testing.expectError(error.InsufficientRealRowsParallelHeadroom, runGroup(allocator, io, .{ .target_assignment = "TARGET=test", .scratch_path = roots.scratch, .export_cache_path = roots.cache, .concurrency = 3, .test_options = &test_options }));
    try std.testing.expectEqual(@as(usize, 0), audit.launched[0] + audit.launched[1] + audit.launched[2]);

    audit = .{};
    test_options.filesystem_sample = .{ .total_bytes = policy_authority.required_start_bytes - 1, .free_bytes = policy_authority.required_start_bytes - 1 };
    try std.testing.expectError(error.RealRowsParallelFilesystemTooSmall, runGroup(allocator, io, .{ .target_assignment = "TARGET=test", .scratch_path = roots.scratch, .export_cache_path = roots.cache, .concurrency = 3, .test_options = &test_options }));
    try std.testing.expectEqual(@as(usize, 0), audit.launched[0] + audit.launched[1] + audit.launched[2]);
}

test "normalization removes only frozen volatile scheduling fields" {
    const input =
        "distribution-real-rows selector_version=real-candidate-selector-v2 candidate_file=x candidate_file_hash=abc limit=100 strict=true\n" ++
        "air-export-cache mode=ReleaseFast status=hit duration_ms=12 cache_key=key-fast descriptor_bytes=44\n" ++
        "summary distribution-real-rows counter_schema=distribution-real-rows-v2 mode=ReleaseFast candidate_file_hash=abc real_native_linked=100 real_programs_ok=4 local_fail=0\n" ++
        "real-rows-mode-parallel schema_version=2 normalization_schema=2 wall_ms=9 root=owned/run local_fail=0\n" ++
        "air-export-cache mode=ReleaseSafe status=hit duration_ms=13 cache_key=key-safe descriptor_bytes=45\n" ++
        "air-export-cache mode=ReleaseSmall status=hit duration_ms=14 cache_key=key-small descriptor_bytes=46\n";
    var buffer: [4096]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);
    try writeNormalizedOutput(input, &writer);
    const normalized = writer.buffered();
    try std.testing.expect(std.mem.indexOf(u8, normalized, "real-rows-mode-parallel") == null);
    try std.testing.expectEqual(@as(usize, 3), std.mem.count(u8, normalized, "duration_ms=<volatile>"));
    try std.testing.expect(std.mem.indexOf(u8, normalized, "candidate_file_hash=abc") != null);
    try std.testing.expect(std.mem.indexOf(u8, normalized, "real_native_linked=100 real_programs_ok=4 local_fail=0") != null);
    const fast = std.mem.indexOf(u8, normalized, "mode=ReleaseFast").?;
    const safe = std.mem.indexOf(u8, normalized, "mode=ReleaseSafe").?;
    const small = std.mem.indexOf(u8, normalized, "mode=ReleaseSmall").?;
    try std.testing.expect(fast < safe and safe < small);

    const schema_one = try std.mem.replaceOwned(u8, std.testing.allocator, input, "schema_version=2", "schema_version=1");
    defer std.testing.allocator.free(schema_one);
    var schema_one_buffer: [4096]u8 = undefined;
    var schema_one_writer = std.Io.Writer.fixed(&schema_one_buffer);
    try std.testing.expectError(error.RealRowsParallelEvidenceSchemaMismatch, writeNormalizedOutput(schema_one, &schema_one_writer));

    const normalization_one = try std.mem.replaceOwned(u8, std.testing.allocator, input, "normalization_schema=2", "normalization_schema=1");
    defer std.testing.allocator.free(normalization_one);
    var normalization_one_buffer: [4096]u8 = undefined;
    var normalization_one_writer = std.Io.Writer.fixed(&normalization_one_buffer);
    try std.testing.expectError(error.RealRowsParallelEvidenceSchemaMismatch, writeNormalizedOutput(normalization_one, &normalization_one_writer));

    var missing_buffer: [4096]u8 = undefined;
    var missing_writer = std.Io.Writer.fixed(&missing_buffer);
    try std.testing.expectError(error.RealRowsParallelEvidenceSchemaMissing, writeNormalizedOutput("ReleaseFast\n", &missing_writer));
}

test "resource state records os-managed memory and fails closed below disk floor" {
    const floor = policy_authority.post_run_free_floor_bytes;
    var resource: ResourceState = .{
        .filesystem_total_bytes = policy_authority.required_start_bytes,
        .post_run_free_floor_bytes = floor,
        .starting_free_bytes = policy_authority.required_start_bytes,
        .minimum_free_bytes = policy_authority.required_start_bytes,
        .final_free_bytes = policy_authority.required_start_bytes,
        .minimum_available_memory_bytes = 500,
    };
    try resource.observe(.{ .total_bytes = policy_authority.required_start_bytes, .free_bytes = floor }, 1, 2, 1);
    try std.testing.expectEqual(floor, resource.minimum_free_bytes);
    try std.testing.expectEqual(@as(u64, 1), resource.minimum_available_memory_bytes);
    try std.testing.expectError(
        error.RealRowsParallelDiskFloorCrossed,
        resource.observe(.{ .total_bytes = policy_authority.required_start_bytes, .free_bytes = floor - 1 }, 1, 2, 0),
    );
}

test "os-managed memory records low samples without launch block or policy termination" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();
    var roots = try fixtureRootsWithCaches(allocator, io, &temp, false);
    defer roots.deinit(allocator);
    var audit: LifecycleAudit = .{};
    const low_memory_samples = [_]u64{1024} ** 16;
    var test_options: TestOptions = .{
        .worker_fixture = .success,
        .filesystem_sample = .{ .total_bytes = 100 * 1024 * 1024 * 1024, .free_bytes = 90 * 1024 * 1024 * 1024 },
        .available_memory_samples = &low_memory_samples,
        .failure_evidence_dir = roots.scratch,
        .audit = &audit,
    };
    var result = try runGroup(allocator, io, .{
        .target_assignment = "TARGET=test",
        .scratch_path = roots.scratch,
        .export_cache_path = roots.cache,
        .cache_mode = .fresh,
        .concurrency = 1,
        .test_options = &test_options,
    });
    defer result.deinit(allocator);
    try std.testing.expectEqual(@as(u64, 1024), result.evidence.minimum_available_memory_bytes);
    try std.testing.expectEqualSlices(usize, &.{ 1, 1, 1 }, &audit.launched);
    try std.testing.expectEqualSlices(usize, &.{ 1, 1, 1 }, &audit.reaped);
    try std.testing.expectEqualSlices(usize, &.{ 0, 0, 0 }, &audit.termination_requests);
    var evidence_buffer: [8192]u8 = undefined;
    var evidence_writer = std.Io.Writer.fixed(&evidence_buffer);
    try writeEvidence(&evidence_writer, &result.evidence);
    try std.testing.expect(std.mem.indexOf(
        u8,
        evidence_writer.buffered(),
        "memory_policy=os-managed-non-gating",
    ) != null);
}

test "os-managed memory keeps child failure fail closed" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();
    var roots = try fixtureRootsWithCaches(allocator, io, &temp, false);
    defer roots.deinit(allocator);
    var audit: LifecycleAudit = .{};
    var test_options: TestOptions = .{
        .worker_fixture = .first_child_fails,
        .filesystem_sample = .{ .total_bytes = 100 * 1024 * 1024 * 1024, .free_bytes = 90 * 1024 * 1024 * 1024 },
        .available_memory_bytes = 1024,
        .failure_evidence_dir = roots.scratch,
        .audit = &audit,
    };
    try std.testing.expectError(
        error.RealRowsParallelChildFailed,
        runGroup(allocator, io, .{
            .target_assignment = "TARGET=test",
            .scratch_path = roots.scratch,
            .export_cache_path = roots.cache,
            .cache_mode = .fresh,
            .concurrency = 1,
            .test_options = &test_options,
        }),
    );
    try std.testing.expectEqual(@as(usize, 1), audit.launched[0]);
    try std.testing.expectEqual(@as(usize, 1), audit.reaped[0]);
    try std.testing.expectEqual(@as(usize, 0), audit.launched[1] + audit.launched[2]);
    try std.testing.expect(audit.evidence_preserved_before_cleanup);
}

test "failure manifest binds os-managed memory diagnostics and explicit child states" {
    const resource: ResourceState = .{
        .filesystem_total_bytes = 100_000,
        .post_run_free_floor_bytes = 10_000,
        .starting_free_bytes = 90_000,
        .minimum_free_bytes = 80_000,
        .final_free_bytes = 80_000,
        .peak_disk_bytes = 7_000,
        .peak_aggregate_rss_bytes = 6_000,
        .minimum_available_memory_bytes = 1,
        .last_free_bytes = 80_000,
        .last_disk_bytes = 7_000,
        .last_aggregate_rss_bytes = 6_000,
        .last_available_memory_bytes = 1,
        .samples = 4,
    };
    const children: [mode_count]ChildFailureObservation = .{
        .{ .state = .reaped, .max_rss_bytes = 5_000 },
        .{ .state = .not_launched },
        .{ .state = .not_reaped },
    };
    const waits: [mode_count]?WorkerWait = .{ null, null, null };
    const run_id = [_]u8{'a'} ** 32;
    var buffer: [4096]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);
    try writeFailureManifest(&writer, &resource, children, waits, error.RealRowsParallelChildFailed, &run_id);
    try std.testing.expectEqualStrings(
        \\schema=2 run_id=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa failure=RealRowsParallelChildFailed success_summary_emitted=false
        \\resource_state memory_policy=os-managed-non-gating samples=4 starting_free_bytes=90000 minimum_free_bytes=80000 final_free_bytes=80000 peak_disk_bytes=7000 peak_aggregate_rss_bytes=6000 minimum_available_memory_bytes=1 last_free_bytes=80000 last_disk_bytes=7000 last_aggregate_rss_bytes=6000 last_available_memory_bytes=1
        \\mode=ReleaseFast child_state=reaped max_rss_bytes=5000 term=unavailable duration_ms=unavailable
        \\mode=ReleaseSafe child_state=not-launched max_rss_bytes=unavailable term=unavailable duration_ms=unavailable
        \\mode=ReleaseSmall child_state=not-reaped max_rss_bytes=unavailable term=unavailable duration_ms=unavailable
        \\
    , writer.buffered());

    var invalid_children = children;
    invalid_children[1].max_rss_bytes = 1;
    var invalid_buffer: [4096]u8 = undefined;
    var invalid_writer = std.Io.Writer.fixed(&invalid_buffer);
    try std.testing.expectError(
        error.RealRowsParallelFailureTopologyInvalid,
        writeFailureManifest(&invalid_writer, &resource, invalid_children, waits, error.RealRowsParallelChildFailed, &run_id),
    );
}

test "required cache miss fails closed before any worker launch" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();
    var roots = try fixtureRoots(allocator, io, &temp);
    defer roots.deinit(allocator);
    var audit: LifecycleAudit = .{};
    var test_options: TestOptions = .{
        .cache_hits = false,
        .filesystem_sample = .{ .total_bytes = 100 * 1024 * 1024 * 1024, .free_bytes = 90 * 1024 * 1024 * 1024 },
        .failure_evidence_dir = roots.scratch,
        .audit = &audit,
    };
    try std.testing.expectError(error.RealRowsParallelCacheUnavailable, runGroup(allocator, io, .{ .target_assignment = "TARGET=test", .scratch_path = roots.scratch, .export_cache_path = roots.cache, .concurrency = 3, .test_options = &test_options }));
    try std.testing.expectEqual(@as(usize, 0), audit.launched[0] + audit.launched[1] + audit.launched[2]);
}

test "successful fixed group buffers and returns outputs in manifest order" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();
    var roots = try fixtureRoots(allocator, io, &temp);
    defer roots.deinit(allocator);
    for ([_]u8{ 1, 3 }) |concurrency| {
        var audit: LifecycleAudit = .{};
        var test_options: TestOptions = .{
            .worker_fixture = .success,
            .filesystem_sample = .{ .total_bytes = 100 * 1024 * 1024 * 1024, .free_bytes = 90 * 1024 * 1024 * 1024 },
            .failure_evidence_dir = roots.scratch,
            .audit = &audit,
        };
        var result = try runGroup(allocator, io, .{ .target_assignment = "TARGET=test", .scratch_path = roots.scratch, .export_cache_path = roots.cache, .concurrency = concurrency, .test_options = &test_options });
        defer result.deinit(allocator);
        for (result.completed, modes) |completed, mode| {
            try std.testing.expect(std.mem.indexOf(u8, completed.result.stdout, mode) != null);
            try std.testing.expect(std.mem.indexOf(u8, completed.result.stdout, "real_executed=4 real_programs_ok=4") != null);
        }
        for (0..mode_count) |index| {
            try std.testing.expectEqual(@as(usize, 1), audit.reaped[index]);
            try std.testing.expectEqual(@as(usize, 1), audit.descriptors_closed[index]);
        }
    }
}

test "fresh population and authenticated hit reuse share exact mode-owned roots without fallback" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();
    var roots = try fixtureRootsWithCaches(allocator, io, &temp, false);
    defer roots.deinit(allocator);
    var audit: LifecycleAudit = .{};
    var test_options: TestOptions = .{
        .worker_fixture = .success,
        .filesystem_sample = .{ .total_bytes = 100 * 1024 * 1024 * 1024, .free_bytes = 90 * 1024 * 1024 * 1024 },
        .failure_evidence_dir = roots.scratch,
        .audit = &audit,
    };
    var fresh = try runGroup(allocator, io, .{ .target_assignment = "TARGET=test", .scratch_path = roots.scratch, .export_cache_path = roots.cache, .cache_mode = .fresh, .concurrency = 3, .test_options = &test_options });
    defer fresh.deinit(allocator);
    try std.testing.expectEqual(CacheMode.fresh, fresh.evidence.cache_mode);
    for (fresh.completed) |completed| try std.testing.expect(std.mem.indexOf(u8, completed.result.stdout, "status=fresh-export") != null);
    var fresh_evidence_buffer: [8192]u8 = undefined;
    var fresh_evidence_writer = std.Io.Writer.fixed(&fresh_evidence_buffer);
    try writeEvidence(&fresh_evidence_writer, &fresh.evidence);
    try std.testing.expect(std.mem.indexOf(u8, fresh_evidence_writer.buffered(), "cache_status=fresh-export,fresh-export,fresh-export air_cache=populated-authenticated") != null);

    audit = .{};
    var hit = try runGroup(allocator, io, .{ .target_assignment = "TARGET=test", .scratch_path = roots.scratch, .export_cache_path = roots.cache, .cache_mode = .require_hit, .concurrency = 3, .test_options = &test_options });
    defer hit.deinit(allocator);
    try std.testing.expectEqual(CacheMode.require_hit, hit.evidence.cache_mode);
    for (hit.completed) |completed| try std.testing.expect(std.mem.indexOf(u8, completed.result.stdout, "status=hit") != null);
}

const FixtureRoots = struct {
    scratch: []u8,
    cache: []u8,

    fn deinit(roots: *FixtureRoots, allocator: std.mem.Allocator) void {
        allocator.free(roots.cache);
        allocator.free(roots.scratch);
        roots.* = undefined;
    }
};

fn fixtureRoots(allocator: std.mem.Allocator, io: std.Io, temp: *std.testing.TmpDir) !FixtureRoots {
    return fixtureRootsWithCaches(allocator, io, temp, true);
}

fn fixtureRootsWithCaches(allocator: std.mem.Allocator, io: std.Io, temp: *std.testing.TmpDir, populate_caches: bool) !FixtureRoots {
    const base = try std.fs.path.join(allocator, &.{ ".zig-cache", "tmp", &temp.sub_path });
    defer allocator.free(base);
    const scratch = try std.fs.path.join(allocator, &.{ base, "validation", "contract" });
    errdefer allocator.free(scratch);
    const cache = try std.fs.path.join(allocator, &.{ base, "cache", "contract" });
    errdefer allocator.free(cache);
    try std.Io.Dir.cwd().createDirPath(io, scratch);
    try std.Io.Dir.cwd().createDirPath(io, cache);
    if (populate_caches) for (modes) |mode| {
        const export_path = try std.fs.path.join(allocator, &.{ cache, mode, "export" });
        defer allocator.free(export_path);
        try std.Io.Dir.cwd().createDirPath(io, export_path);
    };
    return .{ .scratch = scratch, .cache = cache };
}

test "partial wait-future setup reaps every worker before closing descriptors" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();
    var roots = try fixtureRoots(allocator, io, &temp);
    defer roots.deinit(allocator);
    var audit: LifecycleAudit = .{};
    var test_options: TestOptions = .{ .worker_fixture = .all_sleep, .fail_wait_future_before_index = 1, .filesystem_sample = .{ .total_bytes = 100 * 1024 * 1024 * 1024, .free_bytes = 90 * 1024 * 1024 * 1024 }, .failure_evidence_dir = roots.scratch, .audit = &audit };
    try std.testing.expectError(error.InjectedRealRowsWaitFutureSetupFailure, runGroup(allocator, io, .{ .target_assignment = "TARGET=test", .scratch_path = roots.scratch, .export_cache_path = roots.cache, .concurrency = 3, .test_options = &test_options }));
    try std.testing.expectEqual(@as(usize, 3), audit.launched[0] + audit.launched[1] + audit.launched[2]);
    for (0..mode_count) |index| {
        try std.testing.expectEqual(@as(usize, 1), audit.reaped[index]);
        try std.testing.expectEqual(@as(usize, 1), audit.descriptors_closed[index]);
        try std.testing.expect(audit.termination_requests[index] <= 1);
    }
    try std.testing.expect(audit.close_after_reap);
    try std.testing.expect(audit.all_workers_reaped_before_close);
}

test "injected child failure preserves bounded stdout and stderr after reap without obscuring the primary failure" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();
    var roots = try fixtureRoots(allocator, io, &temp);
    defer roots.deinit(allocator);
    var audit: LifecycleAudit = .{};
    var test_options: TestOptions = .{ .worker_fixture = .first_child_fails, .filesystem_sample = .{ .total_bytes = 100 * 1024 * 1024 * 1024, .free_bytes = 90 * 1024 * 1024 * 1024 }, .failure_evidence_dir = roots.scratch, .audit = &audit };
    try std.testing.expectError(error.RealRowsParallelChildFailed, runGroup(allocator, io, .{ .target_assignment = "TARGET=test", .scratch_path = roots.scratch, .export_cache_path = roots.cache, .concurrency = 3, .test_options = &test_options }));
    try std.testing.expectEqual(@as(usize, 1), audit.shared_stop_requests);
    for (0..mode_count) |index| {
        try std.testing.expectEqual(@as(usize, 1), audit.reaped[index]);
        try std.testing.expectEqual(@as(usize, 1), audit.descriptors_closed[index]);
        try std.testing.expect(audit.termination_requests[index] <= 1);
    }
    try std.testing.expect(audit.close_after_reap);
    try std.testing.expect(audit.all_workers_reaped_before_close);
    try std.testing.expect(audit.evidence_preserved_before_cleanup);
    try std.testing.expect(audit.failure_run_id_recorded);
    const result_name = try std.fmt.allocPrint(allocator, "{s}.ReleaseFast.result", .{&audit.failure_run_id});
    defer allocator.free(result_name);
    const result_path = try std.fs.path.join(allocator, &.{ roots.scratch, result_name });
    defer allocator.free(result_path);
    const result = try std.Io.Dir.cwd().readFileAlloc(io, result_path, allocator, .limited(4096));
    defer allocator.free(result);
    try std.testing.expectEqualStrings("injected-real-row-child-stdout\n", result);
    const log_name = try std.fmt.allocPrint(allocator, "{s}.ReleaseFast.log", .{&audit.failure_run_id});
    defer allocator.free(log_name);
    const log_path = try std.fs.path.join(allocator, &.{ roots.scratch, log_name });
    defer allocator.free(log_path);
    const log = try std.Io.Dir.cwd().readFileAlloc(io, log_path, allocator, .limited(4096));
    defer allocator.free(log);
    try std.testing.expectEqualStrings("injected-real-row-child-stderr\n", log);
    const manifest_name = try std.fmt.allocPrint(allocator, "{s}.manifest", .{&audit.failure_run_id});
    defer allocator.free(manifest_name);
    const manifest_path = try std.fs.path.join(allocator, &.{ roots.scratch, manifest_name });
    defer allocator.free(manifest_path);
    const manifest = try std.Io.Dir.cwd().readFileAlloc(io, manifest_path, allocator, .limited(4096));
    defer allocator.free(manifest);
    try std.testing.expect(std.mem.indexOf(u8, manifest, "failure=RealRowsParallelChildFailed") != null);
    try std.testing.expect(std.mem.indexOf(u8, manifest, "success_summary_emitted=false") != null);
    try std.testing.expect(std.mem.indexOf(u8, manifest, "mode=ReleaseFast failure_evidence_stream=stdout status=preserved bytes=31") != null);
    try std.testing.expect(std.mem.indexOf(u8, manifest, "mode=ReleaseFast failure_evidence_stream=stderr status=preserved bytes=31") != null);
}
