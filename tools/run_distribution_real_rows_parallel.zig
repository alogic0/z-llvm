const std = @import("std");
const common = @import("tool_common.zig");
const policy_authority = @import("distribution_real_rows_parallel_policy.zig");

pub const mode_count = 3;
pub const normalization_schema_version: u32 = 1;
const monitor_interval_ns: u64 = std.time.ns_per_s;
const modes = [_][]const u8{ "ReleaseFast", "ReleaseSafe", "ReleaseSmall" };

pub const Completed = struct {
    result: std.process.RunResult,
    duration_ms: i96,
};

pub const Evidence = struct {
    concurrency: u8,
    run_id: [32]u8,
    root: []u8,
    pin_manifest_sha256: [64]u8,
    wall_ms: i96,
    summed_child_ms: i96,
    filesystem_total_bytes: u64,
    floor_bytes: u64,
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
    scratch_path: []const u8,
    concurrency: u8,
    test_options: ?*TestOptions = null,
};

const ModePaths = struct {
    root: []u8,
    work: []u8,
    local_cache: []u8,
    global_cache: []u8,
    result: []u8,
    log: []u8,

    fn deinit(paths: *ModePaths, allocator: std.mem.Allocator) void {
        allocator.free(paths.log);
        allocator.free(paths.result);
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
    mode_paths: [mode_count]ModePaths,

    fn init(allocator: std.mem.Allocator, io: std.Io, scratch_path: []const u8) !OwnedPaths {
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
        var initialized: usize = 0;
        var mode_paths: [mode_count]ModePaths = undefined;
        errdefer for (mode_paths[0..initialized]) |*paths| paths.deinit(allocator);
        for (&mode_paths, modes) |*paths, mode| {
            const mode_root = try std.fs.path.join(allocator, &.{ root, mode });
            errdefer allocator.free(mode_root);
            try cwd.createDir(io, mode_root, .default_dir);
            const work = try createOwnedSubdir(allocator, io, mode_root, "work");
            errdefer allocator.free(work);
            const local_cache = try createOwnedSubdir(allocator, io, mode_root, "zig-local-cache");
            errdefer allocator.free(local_cache);
            const global_cache = try createOwnedSubdir(allocator, io, mode_root, "zig-global-cache");
            errdefer allocator.free(global_cache);
            const result = try std.fs.path.join(allocator, &.{ mode_root, "result.txt" });
            errdefer allocator.free(result);
            const log = try std.fs.path.join(allocator, &.{ mode_root, "worker.log" });
            paths.* = .{ .root = mode_root, .work = work, .local_cache = local_cache, .global_cache = global_cache, .result = result, .log = log };
            initialized += 1;
        }
        return .{ .allocator = allocator, .io = io, .run_id = run_id, .root = root, .stop = stop, .pin_manifest = pin_manifest, .mode_paths = mode_paths };
    }

    fn deinit(paths: *OwnedPaths) void {
        std.Io.Dir.cwd().deleteTree(paths.io, paths.root) catch {};
        for (&paths.mode_paths) |*mode_path| mode_path.deinit(paths.allocator);
        paths.allocator.free(paths.pin_manifest);
        paths.allocator.free(paths.stop);
        paths.allocator.free(paths.root);
        paths.* = undefined;
    }
};

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

fn buildWorkerArgv(allocator: std.mem.Allocator, target_assignment: []const u8, mode_index: usize, paths: ModePaths, probe_only: bool) !ArgvStorage {
    var storage: ArgvStorage = .{ .allocator = allocator };
    errdefer storage.deinit();
    try storage.argv.appendSlice(allocator, &.{ "env", target_assignment });
    try storage.addOwned("ZIG_LOCAL_CACHE_DIR={s}", .{paths.local_cache});
    try storage.addOwned("ZIG_GLOBAL_CACHE_DIR={s}", .{paths.global_cache});
    try storage.argv.append(allocator, "ZLLVM_REAL_ROWS_PRUNING=suspended");
    try storage.argv.appendSlice(allocator, &.{ "zig", "run", "src/distribution_real_rows_gate.zig", "--" });
    try storage.addOwned("--mode={s}", .{modes[mode_index]});
    try storage.argv.appendSlice(allocator, &.{ "--strict", "--limit=100", "--require-cache-hit" });
    if (probe_only) try storage.argv.append(allocator, "--cache-probe-only");
    try storage.addOwned("--runner-temp-root={s}", .{paths.work});
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

fn parseProbeOutput(allocator: std.mem.Allocator, io: std.Io, output: []const u8, mode: []const u8) !CachePin {
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
    const meta_path = try std.fmt.allocPrint(allocator, "tmp/real_rows_air_export_cache/{s}.meta", .{key_text});
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

fn verifyPin(allocator: std.mem.Allocator, io: std.Io, pin: CachePin) !void {
    const air_path = try std.fmt.allocPrint(allocator, "tmp/real_rows_air_export_cache/{s}.air", .{&pin.key});
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
        var argv = try buildWorkerArgv(allocator, options.target_assignment, index, paths.mode_paths[index], true);
        defer argv.deinit();
        const result = try std.process.run(allocator, io, .{ .argv = argv.argv.items, .stdout_limit = .limited(4 * 1024 * 1024), .stderr_limit = .limited(4 * 1024 * 1024) });
        defer common.freeRunResult(allocator, result);
        if (!common.termOk(result.term)) return error.RealRowsParallelCacheUnavailable;
        pins[index] = try parseProbeOutput(allocator, io, result.stdout, mode);
        try verifyPin(allocator, io, pins[index]);
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

const FilesystemSample = struct { total_bytes: u64, free_bytes: u64 };

const ResourceState = struct {
    filesystem_total_bytes: u64,
    floor_bytes: u64,
    minimum_available_threshold_bytes: u64,
    starting_free_bytes: u64,
    minimum_free_bytes: u64,
    final_free_bytes: u64,
    peak_disk_bytes: u64 = 0,
    peak_aggregate_rss_bytes: u64 = 0,
    minimum_available_memory_bytes: u64,
    samples: usize = 0,

    fn observe(state: *ResourceState, sample: FilesystemSample, disk_bytes: u64, rss_bytes: u64, available_memory_bytes: u64) !void {
        if (sample.total_bytes != state.filesystem_total_bytes) return error.RealRowsParallelFilesystemChanged;
        state.samples += 1;
        state.minimum_free_bytes = @min(state.minimum_free_bytes, sample.free_bytes);
        state.final_free_bytes = sample.free_bytes;
        state.peak_disk_bytes = @max(state.peak_disk_bytes, disk_bytes);
        state.peak_aggregate_rss_bytes = @max(state.peak_aggregate_rss_bytes, rss_bytes);
        state.minimum_available_memory_bytes = @min(state.minimum_available_memory_bytes, available_memory_bytes);
        if (sample.free_bytes < state.floor_bytes) return error.RealRowsParallelDiskFloorCrossed;
        if (available_memory_bytes < state.minimum_available_threshold_bytes) return error.RealRowsParallelMemoryFloorCrossed;
    }
};

const WorkerWait = struct { term: std.process.Child.Term, duration_ms: i96, max_rss_bytes: usize };
const WaitState = struct {
    done: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    failed: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
};

fn waitWorker(io: std.Io, child: *std.process.Child, state: *WaitState, start: std.Io.Timestamp) !WorkerWait {
    defer state.done.store(true, .release);
    const term = try child.wait(io);
    state.failed.store(!common.termOk(term), .release);
    return .{ .term = term, .duration_ms = elapsedMs(io, start), .max_rss_bytes = child.resource_usage_statistics.getMaxRss() orelse 0 };
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

const TestWorkerFixture = enum { production, success, first_child_fails, all_sleep };
const LifecycleAudit = struct {
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
    monitor_interval_ns: u64 = std.time.ns_per_ms,
    failure_evidence_dir: []const u8 = "tmp/real_rows_parallel_fixture_failures",
    audit: *LifecycleAudit,
};

fn spawnWorker(allocator: std.mem.Allocator, io: std.Io, options: ParentOptions, paths: *const OwnedPaths, mode_index: usize) !SpawnedWorker {
    const mode_path = paths.mode_paths[mode_index];
    var argv = try buildWorkerArgv(allocator, options.target_assignment, mode_index, mode_path, false);
    defer argv.deinit();
    const result_file = try std.Io.Dir.cwd().createFile(io, mode_path.result, .{ .exclusive = true });
    errdefer result_file.close(io);
    const log_file = try std.Io.Dir.cwd().createFile(io, mode_path.log, .{ .exclusive = true });
    errdefer log_file.close(io);
    const child = if (options.test_options) |test_options| switch (test_options.worker_fixture) {
        .production => try std.process.spawn(io, .{ .argv = argv.argv.items, .stdin = .ignore, .stdout = .{ .file = result_file }, .stderr = .{ .file = log_file }, .request_resource_usage_statistics = true, .pgid = 0 }),
        .success => try std.process.spawn(io, .{ .argv = &.{ "/bin/sh", "-c", "printf '%s\\n' \"$1\"", "real-row-fixture", modes[mode_index] }, .stdin = .ignore, .stdout = .{ .file = result_file }, .stderr = .{ .file = log_file }, .request_resource_usage_statistics = true, .pgid = 0 }),
        .first_child_fails => if (mode_index == 0)
            try std.process.spawn(io, .{ .argv = &.{ "/bin/sh", "-c", "printf 'injected-original-real-row-child-failure\\n' >&2; exit 7" }, .stdin = .ignore, .stdout = .{ .file = result_file }, .stderr = .{ .file = log_file }, .request_resource_usage_statistics = true, .pgid = 0 })
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
    if (options.test_options) |test_options| return test_options.available_memory_bytes;
    const result = try common.runCapture(allocator, io, &.{ "awk", "/^MemAvailable:/ { print $2 }", "/proc/meminfo" }, "real-row parallel available memory sample");
    defer common.freeRunResult(allocator, result);
    return try std.fmt.parseUnsigned(u64, std.mem.trim(u8, result.stdout, " \t\r\n"), 10) *| 1024;
}

fn readLoadAverage(allocator: std.mem.Allocator, io: std.Io) ![]u8 {
    const result = try common.runCapture(allocator, io, &.{ "awk", "{ print $1 }", "/proc/loadavg" }, "real-row parallel load sample");
    defer common.freeRunResult(allocator, result);
    return allocator.dupe(u8, std.mem.trim(u8, result.stdout, " \t\r\n"));
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

fn runBatch(allocator: std.mem.Allocator, io: std.Io, options: ParentOptions, paths: *const OwnedPaths, mode_indices: []const usize, resource: *ResourceState, waits: *[mode_count]?WorkerWait) !void {
    var workers: [mode_count]SpawnedWorker = undefined;
    var worker_count: usize = 0;
    var primary_error: ?anyerror = null;
    for (mode_indices) |mode_index| {
        workers[worker_count] = spawnWorker(allocator, io, options, paths, mode_index) catch |err| {
            primary_error = err;
            break;
        };
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
            continue;
        };
        waits[worker.mode_index] = wait;
        if (!common.termOk(wait.term)) worker.state.failed.store(true, .release);
        markReaped(worker, options);
    }
    for (workers[future_count..worker_count]) |*worker| directlyKillAndReap(io, worker, options);
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

fn preserveFailureEvidence(allocator: std.mem.Allocator, io: std.Io, options: ParentOptions, paths: *const OwnedPaths, waits: [mode_count]?WorkerWait, failure: anyerror) !void {
    const evidence_dir = if (options.test_options) |test_options| test_options.failure_evidence_dir else "tmp/real_rows_parallel_failures";
    var cwd = std.Io.Dir.cwd();
    try cwd.createDirPath(io, evidence_dir);
    const manifest_name = try std.fmt.allocPrint(allocator, "{s}.manifest", .{&paths.run_id});
    defer allocator.free(manifest_name);
    const manifest_path = try std.fs.path.join(allocator, &.{ evidence_dir, manifest_name });
    defer allocator.free(manifest_path);
    var buffer: [4096]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);
    try writer.print("schema=1 run_id={s} failure={s} success_summary_emitted=false\n", .{ &paths.run_id, @errorName(failure) });
    for (modes, waits, 0..) |mode, wait, index| {
        if (wait) |value| try writer.print("mode={s} term={any} duration_ms={}\n", .{ mode, value.term, value.duration_ms }) else try writer.print("mode={s} term=not-launched-or-not-reaped\n", .{mode});
        const log = cwd.readFileAlloc(io, paths.mode_paths[index].log, allocator, .limited(64 * 1024)) catch continue;
        defer allocator.free(log);
        const log_name = try std.fmt.allocPrint(allocator, "{s}.{s}.log", .{ &paths.run_id, mode });
        defer allocator.free(log_name);
        const log_path = try std.fs.path.join(allocator, &.{ evidence_dir, log_name });
        defer allocator.free(log_path);
        try cwd.writeFile(io, .{ .sub_path = log_path, .data = log });
    }
    try cwd.writeFile(io, .{ .sub_path = manifest_path, .data = writer.buffered() });
    if (options.test_options) |test_options| {
        test_options.audit.evidence_preserved_before_cleanup = try pathExists(io, paths.root);
        test_options.audit.failure_run_id = paths.run_id;
        test_options.audit.failure_run_id_recorded = true;
    }
}

fn validateWorkerOutput(output: []const u8, mode: []const u8) !void {
    var header_count: usize = 0;
    var cache_count: usize = 0;
    var summary_count: usize = 0;
    var lines = std.mem.splitScalar(u8, output, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        if (std.mem.startsWith(u8, line, "distribution-real-rows ")) {
            header_count += 1;
            continue;
        }
        if (std.mem.startsWith(u8, line, "air-export-cache ")) {
            cache_count += 1;
            if (!std.mem.eql(u8, fieldValue(line, "mode=") orelse return error.RealRowsOutputMissingCacheMode, mode)) return error.RealRowsOutputCacheModeMismatch;
            if (!std.mem.eql(u8, fieldValue(line, "status=") orelse return error.RealRowsOutputMissingCacheStatus, "hit")) return error.RealRowsOutputCacheNotHit;
            continue;
        }
        if (std.mem.startsWith(u8, line, "summary distribution-real-rows ")) {
            summary_count += 1;
            if (!std.mem.eql(u8, fieldValue(line, "mode=") orelse return error.RealRowsOutputMissingSummaryMode, mode)) return error.RealRowsOutputSummaryModeMismatch;
            const required = [_][]const u8{
                "counter_schema=distribution-real-rows-v2", "limit=100",                "candidate_rows=100",
                "real_functions_lowered=100",               "real_objects_emitted=100", "real_native_linked=100",
                "real_executed=0",                          "real_programs_ok=0",       "first_failing_real_row=-",
                "first_failing_stage=-",                    "local_fail=0",
            };
            for (required) |field| if (std.mem.indexOf(u8, line, field) == null) return error.RealRowsOutputCounterMismatch;
            continue;
        }
        return error.RealRowsOutputUnexpectedRecord;
    }
    if (header_count != 1 or cache_count != 1 or summary_count != 1) return error.RealRowsOutputTopologyMismatch;
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
        const stdout = try std.Io.Dir.cwd().readFileAlloc(io, mode_path.result, allocator, .limited(128 * 1024 * 1024));
        errdefer allocator.free(stdout);
        const stderr = try std.Io.Dir.cwd().readFileAlloc(io, mode_path.log, allocator, .limited(32 * 1024 * 1024));
        errdefer allocator.free(stderr);
        if (!common.termOk(wait.term)) return error.RealRowsParallelChildFailed;
        if (stderr.len != 0) return error.RealRowsParallelUnexpectedStderr;
        if (options.test_options == null) try validateWorkerOutput(stdout, mode);
        item.* = .{ .result = .{ .term = wait.term, .stdout = stdout, .stderr = stderr }, .duration_ms = wait.duration_ms };
        initialized += 1;
    }
    return completed;
}

pub fn runGroup(allocator: std.mem.Allocator, io: std.Io, options: ParentOptions) !GroupResult {
    if (options.concurrency != 1 and options.concurrency != 3) return error.InvalidRealRowsConcurrency;
    var paths = try OwnedPaths.init(allocator, io, options.scratch_path);
    defer paths.deinit();
    const wall_start = std.Io.Timestamp.now(io, .awake);
    const preflight = try sampleFilesystem(allocator, io, paths.root, options);
    const policy = policy_authority.forFilesystem(preflight.total_bytes);
    if (preflight.free_bytes < policy.required_start_bytes) return error.InsufficientRealRowsParallelHeadroom;
    const available_memory = try sampleAvailableMemory(allocator, io, options);
    if (available_memory < policy.minimum_available_memory_bytes) return error.InsufficientRealRowsParallelMemory;
    const pins = try probeAndPin(allocator, io, options, &paths);
    const pin_manifest_sha256 = try sha256File(allocator, io, paths.pin_manifest);
    var resource: ResourceState = .{
        .filesystem_total_bytes = preflight.total_bytes,
        .floor_bytes = policy.floor_bytes,
        .minimum_available_threshold_bytes = policy.minimum_available_memory_bytes,
        .starting_free_bytes = preflight.free_bytes,
        .minimum_free_bytes = preflight.free_bytes,
        .final_free_bytes = preflight.free_bytes,
        .minimum_available_memory_bytes = available_memory,
    };
    const load_start = if (options.test_options != null) try allocator.dupe(u8, "fixture") else try readLoadAverage(allocator, io);
    errdefer allocator.free(load_start);
    var waits: [mode_count]?WorkerWait = .{ null, null, null };
    if (options.concurrency == 1) {
        for (0..mode_count) |index| {
            const one = [_]usize{index};
            runBatch(allocator, io, options, &paths, &one, &resource, &waits) catch |err| {
                try preserveFailureEvidence(allocator, io, options, &paths, waits, err);
                return err;
            };
        }
    } else {
        const all = [_]usize{ 0, 1, 2 };
        runBatch(allocator, io, options, &paths, &all, &resource, &waits) catch |err| {
            try preserveFailureEvidence(allocator, io, options, &paths, waits, err);
            return err;
        };
    }
    observeResources(allocator, io, options, &paths, &resource) catch |err| {
        try preserveFailureEvidence(allocator, io, options, &paths, waits, err);
        return err;
    };
    for (pins) |pin| if (options.test_options == null) {
        verifyPin(allocator, io, pin) catch |err| {
            try preserveFailureEvidence(allocator, io, options, &paths, waits, err);
            return err;
        };
    };
    const completed = collectCompleted(allocator, io, options, &paths, waits) catch |err| {
        try preserveFailureEvidence(allocator, io, options, &paths, waits, err);
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
    return .{
        .completed = completed,
        .evidence = .{
            .concurrency = options.concurrency,
            .run_id = paths.run_id,
            .root = try allocator.dupe(u8, paths.root),
            .pin_manifest_sha256 = pin_manifest_sha256,
            .wall_ms = elapsedMs(io, wall_start),
            .summed_child_ms = summed_child_ms,
            .filesystem_total_bytes = policy.filesystem_total_bytes,
            .floor_bytes = policy.floor_bytes,
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

pub fn writeEvidence(writer: *std.Io.Writer, evidence: *const Evidence) !void {
    try writer.print(
        "real-rows-mode-parallel schema_version={} normalization_schema={} concurrency={} workers=3 modes=ReleaseFast,ReleaseSafe,ReleaseSmall run_id={s} root={s} fast_temp={s}/ReleaseFast/work fast_local_cache={s}/ReleaseFast/zig-local-cache fast_global_cache={s}/ReleaseFast/zig-global-cache safe_temp={s}/ReleaseSafe/work safe_local_cache={s}/ReleaseSafe/zig-local-cache safe_global_cache={s}/ReleaseSafe/zig-global-cache small_temp={s}/ReleaseSmall/work small_local_cache={s}/ReleaseSmall/zig-local-cache small_global_cache={s}/ReleaseSmall/zig-global-cache pin_manifest_sha256={s} cache_status=hit,hit,hit air_cache=read-only pruning=suspended wall_ms={} summed_child_ms={} filesystem_total_bytes={} floor_bytes={} projected_peak_bytes={} required_start_bytes={} starting_free_bytes={} minimum_free_bytes={} final_free_bytes={} peak_disk_bytes={} peak_aggregate_rss_bytes={} minimum_available_memory_bytes={} memory_floor_bytes={} load_start={s} load_end={s} execution_results_cached=false local_fail=0\n",
        .{ normalization_schema_version, normalization_schema_version, evidence.concurrency, &evidence.run_id, evidence.root, evidence.root, evidence.root, evidence.root, evidence.root, evidence.root, evidence.root, evidence.root, evidence.root, evidence.root, &evidence.pin_manifest_sha256, evidence.wall_ms, evidence.summed_child_ms, evidence.filesystem_total_bytes, evidence.floor_bytes, evidence.projected_peak_bytes, evidence.required_start_bytes, evidence.starting_free_bytes, evidence.minimum_free_bytes, evidence.final_free_bytes, evidence.peak_disk_bytes, evidence.peak_aggregate_rss_bytes, evidence.minimum_available_memory_bytes, policy_authority.minimum_available_memory_bytes, evidence.load_start, evidence.load_end },
    );
}

pub fn writeNormalizedOutput(output: []const u8, writer: *std.Io.Writer) !void {
    const volatile_prefixes = [_][]const u8{
        "duration_ms=",                    "wall_ms=",            "summed_child_ms=",  "run_id=",          "root=",
        "starting_free_bytes=",            "minimum_free_bytes=", "final_free_bytes=", "peak_disk_bytes=", "peak_aggregate_rss_bytes=",
        "minimum_available_memory_bytes=", "load_start=",         "load_end=",
    };
    var lines = std.mem.splitScalar(u8, output, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        if (std.mem.startsWith(u8, line, "real-rows-mode-parallel ")) continue;
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

pub const Admission = enum { parallel, serial_fallback };

pub fn admission(fresh_real_rows: bool, cache_hits: [mode_count]bool) Admission {
    if (fresh_real_rows) return .serial_fallback;
    for (cache_hits) |hit| if (!hit) return .serial_fallback;
    return .parallel;
}

fn createFocusedScratch(allocator: std.mem.Allocator, io: std.Io) ![]u8 {
    try std.Io.Dir.cwd().createDirPath(io, "tmp");
    var random: [16]u8 = undefined;
    var attempt: usize = 0;
    while (attempt < 16) : (attempt += 1) {
        io.random(&random);
        const id = std.fmt.bytesToHex(random, .lower);
        const path = try std.fmt.allocPrint(allocator, "tmp/real_rows_focused_{s}", .{&id});
        std.Io.Dir.cwd().createDir(io, path, .default_dir) catch |err| switch (err) {
            error.PathAlreadyExists => {
                allocator.free(path);
                continue;
            },
            else => {
                allocator.free(path);
                return err;
            },
        };
        return path;
    }
    return error.RealRowsFocusedRootCollisionLimit;
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    var concurrency: u8 = 3;
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.skip();
    while (args.next()) |arg| {
        if (std.mem.startsWith(u8, arg, "--concurrency=")) concurrency = try std.fmt.parseUnsigned(u8, arg["--concurrency=".len..], 10) else return error.UnexpectedArgument;
    }
    if (concurrency != 1 and concurrency != 3) return error.InvalidRealRowsConcurrency;
    const target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);
    const target = target_env orelse "x86_64-unknown-linux-gnu";
    const target_assignment = try std.fmt.allocPrint(allocator, "TARGET={s}", .{target});
    defer allocator.free(target_assignment);
    const scratch = try createFocusedScratch(allocator, io);
    defer {
        std.Io.Dir.cwd().deleteTree(io, scratch) catch {};
        allocator.free(scratch);
    }
    var result = try runGroup(allocator, io, .{ .target_assignment = target_assignment, .scratch_path = scratch, .concurrency = concurrency });
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
            .result = try std.fmt.allocPrint(allocator, "{s}/result", .{root}),
            .log = try std.fmt.allocPrint(allocator, "{s}/log", .{root}),
        };
        defer paths.deinit(allocator);
        var argv = try buildWorkerArgv(allocator, "TARGET=x86_64-unknown-linux-gnu", index, paths, false);
        defer argv.deinit();
        const joined = try joinedArgv(allocator, argv.argv.items);
        defer allocator.free(joined);
        const mode_arg = try std.fmt.allocPrint(allocator, "--mode={s}", .{mode});
        defer allocator.free(mode_arg);
        try std.testing.expect(std.mem.indexOf(u8, joined, mode_arg) != null);
        try std.testing.expect(std.mem.indexOf(u8, joined, "--require-cache-hit") != null);
        const temp_arg = try std.fmt.allocPrint(allocator, "--runner-temp-root={s}/work", .{root});
        defer allocator.free(temp_arg);
        const local_arg = try std.fmt.allocPrint(allocator, "ZIG_LOCAL_CACHE_DIR={s}/local", .{root});
        defer allocator.free(local_arg);
        const global_arg = try std.fmt.allocPrint(allocator, "ZIG_GLOBAL_CACHE_DIR={s}/global", .{root});
        defer allocator.free(global_arg);
        try std.testing.expect(std.mem.indexOf(u8, joined, temp_arg) != null);
        try std.testing.expect(std.mem.indexOf(u8, joined, local_arg) != null);
        try std.testing.expect(std.mem.indexOf(u8, joined, global_arg) != null);
    }
}

test "parallel admission requires three hits and rejects fresh rows" {
    try std.testing.expectEqual(Admission.parallel, admission(false, .{ true, true, true }));
    try std.testing.expectEqual(Admission.serial_fallback, admission(false, .{ true, false, true }));
    try std.testing.expectEqual(Admission.serial_fallback, admission(true, .{ true, true, true }));
}

test "normalization removes only frozen volatile scheduling fields" {
    const input =
        "distribution-real-rows selector_version=real-candidate-selector-v2 candidate_file=x candidate_file_hash=abc limit=100 strict=true\n" ++
        "air-export-cache mode=ReleaseFast status=hit duration_ms=12 cache_key=key-fast descriptor_bytes=44\n" ++
        "summary distribution-real-rows counter_schema=distribution-real-rows-v2 mode=ReleaseFast candidate_file_hash=abc real_native_linked=100 real_programs_ok=0 local_fail=0\n" ++
        "real-rows-mode-parallel schema_version=1 wall_ms=9 root=owned/run local_fail=0\n" ++
        "air-export-cache mode=ReleaseSafe status=hit duration_ms=13 cache_key=key-safe descriptor_bytes=45\n" ++
        "air-export-cache mode=ReleaseSmall status=hit duration_ms=14 cache_key=key-small descriptor_bytes=46\n";
    var buffer: [4096]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);
    try writeNormalizedOutput(input, &writer);
    const normalized = writer.buffered();
    try std.testing.expect(std.mem.indexOf(u8, normalized, "real-rows-mode-parallel") == null);
    try std.testing.expectEqual(@as(usize, 3), std.mem.count(u8, normalized, "duration_ms=<volatile>"));
    try std.testing.expect(std.mem.indexOf(u8, normalized, "candidate_file_hash=abc") != null);
    try std.testing.expect(std.mem.indexOf(u8, normalized, "real_native_linked=100 real_programs_ok=0 local_fail=0") != null);
    const fast = std.mem.indexOf(u8, normalized, "mode=ReleaseFast").?;
    const safe = std.mem.indexOf(u8, normalized, "mode=ReleaseSafe").?;
    const small = std.mem.indexOf(u8, normalized, "mode=ReleaseSmall").?;
    try std.testing.expect(fast < safe and safe < small);
}

test "resource state fails closed at disk and memory floors" {
    var disk: ResourceState = .{ .filesystem_total_bytes = 1000, .floor_bytes = 100, .minimum_available_threshold_bytes = 200, .starting_free_bytes = 500, .minimum_free_bytes = 500, .final_free_bytes = 500, .minimum_available_memory_bytes = 500 };
    try std.testing.expectError(error.RealRowsParallelDiskFloorCrossed, disk.observe(.{ .total_bytes = 1000, .free_bytes = 99 }, 1, 2, 500));
    var memory: ResourceState = .{ .filesystem_total_bytes = 1000, .floor_bytes = 100, .minimum_available_threshold_bytes = 200, .starting_free_bytes = 500, .minimum_free_bytes = 500, .final_free_bytes = 500, .minimum_available_memory_bytes = 500 };
    try std.testing.expectError(error.RealRowsParallelMemoryFloorCrossed, memory.observe(.{ .total_bytes = 1000, .free_bytes = 400 }, 1, 2, 199));
}

test "cache miss is a serial-fallback signal before any worker launch" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();
    const scratch = try fixtureScratch(allocator, &temp);
    defer allocator.free(scratch);
    var audit: LifecycleAudit = .{};
    var test_options: TestOptions = .{
        .cache_hits = false,
        .filesystem_sample = .{ .total_bytes = 100 * 1024 * 1024 * 1024, .free_bytes = 90 * 1024 * 1024 * 1024 },
        .failure_evidence_dir = scratch,
        .audit = &audit,
    };
    try std.testing.expectError(error.RealRowsParallelCacheUnavailable, runGroup(allocator, io, .{ .target_assignment = "TARGET=test", .scratch_path = scratch, .concurrency = 3, .test_options = &test_options }));
    try std.testing.expectEqual(@as(usize, 0), audit.launched[0] + audit.launched[1] + audit.launched[2]);
}

test "successful fixed group buffers and returns outputs in manifest order" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();
    const scratch = try fixtureScratch(allocator, &temp);
    defer allocator.free(scratch);
    for ([_]u8{ 1, 3 }) |concurrency| {
        var audit: LifecycleAudit = .{};
        var test_options: TestOptions = .{
            .worker_fixture = .success,
            .filesystem_sample = .{ .total_bytes = 100 * 1024 * 1024 * 1024, .free_bytes = 90 * 1024 * 1024 * 1024 },
            .failure_evidence_dir = scratch,
            .audit = &audit,
        };
        var result = try runGroup(allocator, io, .{ .target_assignment = "TARGET=test", .scratch_path = scratch, .concurrency = concurrency, .test_options = &test_options });
        defer result.deinit(allocator);
        for (result.completed, modes) |completed, mode| {
            var expected_buffer: [64]u8 = undefined;
            const expected = try std.fmt.bufPrint(&expected_buffer, "{s}\n", .{mode});
            try std.testing.expectEqualStrings(expected, completed.result.stdout);
        }
        for (0..mode_count) |index| {
            try std.testing.expectEqual(@as(usize, 1), audit.reaped[index]);
            try std.testing.expectEqual(@as(usize, 1), audit.descriptors_closed[index]);
        }
    }
}

fn fixtureScratch(allocator: std.mem.Allocator, temp: *std.testing.TmpDir) ![]u8 {
    return std.fs.path.join(allocator, &.{ ".zig-cache", "tmp", &temp.sub_path });
}

test "partial wait-future setup reaps every worker before closing descriptors" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();
    const scratch = try fixtureScratch(allocator, &temp);
    defer allocator.free(scratch);
    var audit: LifecycleAudit = .{};
    var test_options: TestOptions = .{ .worker_fixture = .all_sleep, .fail_wait_future_before_index = 1, .filesystem_sample = .{ .total_bytes = 100 * 1024 * 1024 * 1024, .free_bytes = 90 * 1024 * 1024 * 1024 }, .failure_evidence_dir = scratch, .audit = &audit };
    try std.testing.expectError(error.InjectedRealRowsWaitFutureSetupFailure, runGroup(allocator, io, .{ .target_assignment = "TARGET=test", .scratch_path = scratch, .concurrency = 3, .test_options = &test_options }));
    try std.testing.expectEqual(@as(usize, 3), audit.launched[0] + audit.launched[1] + audit.launched[2]);
    for (0..mode_count) |index| {
        try std.testing.expectEqual(@as(usize, 1), audit.reaped[index]);
        try std.testing.expectEqual(@as(usize, 1), audit.descriptors_closed[index]);
        try std.testing.expect(audit.termination_requests[index] <= 1);
    }
    try std.testing.expect(audit.close_after_reap);
    try std.testing.expect(audit.all_workers_reaped_before_close);
}

test "injected production-batch child failure preserves the original failure and lifecycle" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();
    const scratch = try fixtureScratch(allocator, &temp);
    defer allocator.free(scratch);
    var audit: LifecycleAudit = .{};
    var test_options: TestOptions = .{ .worker_fixture = .first_child_fails, .filesystem_sample = .{ .total_bytes = 100 * 1024 * 1024 * 1024, .free_bytes = 90 * 1024 * 1024 * 1024 }, .failure_evidence_dir = scratch, .audit = &audit };
    try std.testing.expectError(error.RealRowsParallelChildFailed, runGroup(allocator, io, .{ .target_assignment = "TARGET=test", .scratch_path = scratch, .concurrency = 3, .test_options = &test_options }));
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
    const log_name = try std.fmt.allocPrint(allocator, "{s}.ReleaseFast.log", .{&audit.failure_run_id});
    defer allocator.free(log_name);
    const log_path = try std.fs.path.join(allocator, &.{ scratch, log_name });
    defer allocator.free(log_path);
    const log = try std.Io.Dir.cwd().readFileAlloc(io, log_path, allocator, .limited(4096));
    defer allocator.free(log);
    try std.testing.expect(std.mem.indexOf(u8, log, "injected-original-real-row-child-failure") != null);
    const manifest_name = try std.fmt.allocPrint(allocator, "{s}.manifest", .{&audit.failure_run_id});
    defer allocator.free(manifest_name);
    const manifest_path = try std.fs.path.join(allocator, &.{ scratch, manifest_name });
    defer allocator.free(manifest_path);
    const manifest = try std.Io.Dir.cwd().readFileAlloc(io, manifest_path, allocator, .limited(4096));
    defer allocator.free(manifest);
    try std.testing.expect(std.mem.indexOf(u8, manifest, "failure=RealRowsParallelChildFailed") != null);
    try std.testing.expect(std.mem.indexOf(u8, manifest, "success_summary_emitted=false") != null);
}
