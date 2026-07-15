const std = @import("std");
const case_inventory = @import("run_distribution_zig_integrated_object_cases.zig");
const common = @import("tool_common.zig");
const headroom_policy = @import("distribution_headroom_policy.zig");

pub const normalization_schema_version: u32 = 1;
pub const shard_count: usize = 2;
pub const expected_case_count: usize = 146;
const monitor_interval_ns: i64 = 2 * std.time.ns_per_s;

comptime {
    std.debug.assert(case_inventory.cases.len == expected_case_count);
}

pub const Range = struct {
    start: usize,
    end: usize,

    pub fn len(range: Range) usize {
        return range.end - range.start;
    }
};

pub const ParentOptions = struct {
    executable_path: []const u8,
    target: []const u8,
    zllvm_exe: []const u8,
    concurrency: u8,
    explicit_root: ?[]const u8,
    environ_map: *const std.process.Environ.Map,
    test_options: ?TestOptions = null,
};

const WorkerFixture = enum {
    production,
    first_child_fails,
    all_sleep,
};

const BatchAudit = struct {
    launched: [shard_count]usize = .{ 0, 0 },
    wait_futures_started: [shard_count]usize = .{ 0, 0 },
    termination_requests: [shard_count]usize = .{ 0, 0 },
    reaped: [shard_count]usize = .{ 0, 0 },
    descriptors_closed: [shard_count]usize = .{ 0, 0 },
    close_after_reap: bool = true,
    shared_stop_requests: usize = 0,
    evidence_preserved_before_cleanup: bool = false,
    failure_run_id: [32]u8 = undefined,
    failure_run_id_recorded: bool = false,
};

const TestOptions = struct {
    worker_fixture: WorkerFixture = .production,
    fail_wait_future_before_index: ?usize = null,
    monitor_interval_ns: i64 = monitor_interval_ns,
    failure_evidence_dir: []const u8 = "tmp/preopt_sharding_failures",
    filesystem_sample: ?FilesystemSample = null,
    audit: *BatchAudit,
};

pub const WorkerOptions = struct {
    shard_index: usize,
    range: Range,
    root_path: []const u8,
    result_path: []const u8,
    log_path: []const u8,
    stop_path: []const u8,
};

pub fn partition() [shard_count]Range {
    const midpoint = (expected_case_count + 1) / 2;
    return .{
        .{ .start = 0, .end = midpoint },
        .{ .start = midpoint, .end = expected_case_count },
    };
}

pub fn validateWorkerOptions(options: WorkerOptions) !void {
    const ranges = partition();
    if (options.shard_index >= ranges.len) return error.InvalidPreoptShardIndex;
    const expected = ranges[options.shard_index];
    if (options.range.start != expected.start or options.range.end != expected.end) {
        return error.PreoptShardPartitionMismatch;
    }
    if (options.root_path.len == 0 or options.result_path.len == 0 or
        options.log_path.len == 0 or options.stop_path.len == 0)
    {
        return error.IncompletePreoptShardPaths;
    }
}

const ShardPaths = struct {
    root: []u8,
    work: []u8,
    local_cache: []u8,
    global_cache: []u8,
    result: []u8,
    log: []u8,

    fn deinit(paths: *ShardPaths, allocator: std.mem.Allocator) void {
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
    shards: [shard_count]ShardPaths,
    owned: bool = true,

    fn init(
        allocator: std.mem.Allocator,
        io: std.Io,
        explicit_root: ?[]const u8,
    ) !OwnedPaths {
        var cwd = std.Io.Dir.cwd();
        var random_bytes: [16]u8 = undefined;
        io.random(&random_bytes);
        var run_id = std.fmt.bytesToHex(random_bytes, .lower);
        const root = if (explicit_root) |path| blk: {
            const copy = try allocator.dupe(u8, path);
            errdefer allocator.free(copy);
            cwd.createDir(io, copy, .default_dir) catch |err| switch (err) {
                error.PathAlreadyExists => return error.PreoptShardRootAlreadyExists,
                else => return err,
            };
            break :blk copy;
        } else blk: {
            try cwd.createDirPath(io, "tmp");
            var attempt: usize = 0;
            while (attempt < 16) : (attempt += 1) {
                io.random(&random_bytes);
                const candidate_id = std.fmt.bytesToHex(random_bytes, .lower);
                const candidate = try std.fmt.allocPrint(allocator, "tmp/preopt_sharding_{s}", .{&candidate_id});
                cwd.createDir(io, candidate, .default_dir) catch |err| switch (err) {
                    error.PathAlreadyExists => {
                        allocator.free(candidate);
                        continue;
                    },
                    else => {
                        allocator.free(candidate);
                        return err;
                    },
                };
                run_id = candidate_id;
                break :blk candidate;
            }
            return error.PreoptShardRootCollisionLimit;
        };
        errdefer {
            cwd.deleteTree(io, root) catch {};
            allocator.free(root);
        }

        const stop = try std.fs.path.join(allocator, &.{ root, "stop" });
        errdefer allocator.free(stop);
        var initialized: usize = 0;
        var shards: [shard_count]ShardPaths = undefined;
        errdefer {
            for (shards[0..initialized]) |*paths| paths.deinit(allocator);
        }
        for (&shards, 0..) |*paths, shard_index| {
            const name = try std.fmt.allocPrint(allocator, "shard_{}", .{shard_index});
            defer allocator.free(name);
            const shard_root = try std.fs.path.join(allocator, &.{ root, name });
            errdefer allocator.free(shard_root);
            try cwd.createDir(io, shard_root, .default_dir);
            const work = try createOwnedSubdir(allocator, io, shard_root, "work");
            errdefer allocator.free(work);
            const local_cache = try createOwnedSubdir(allocator, io, shard_root, "zig-local-cache");
            errdefer allocator.free(local_cache);
            const global_cache = try createOwnedSubdir(allocator, io, shard_root, "zig-global-cache");
            errdefer allocator.free(global_cache);
            const result = try std.fs.path.join(allocator, &.{ shard_root, "result.txt" });
            errdefer allocator.free(result);
            const log = try std.fs.path.join(allocator, &.{ shard_root, "worker.log" });
            paths.* = .{
                .root = shard_root,
                .work = work,
                .local_cache = local_cache,
                .global_cache = global_cache,
                .result = result,
                .log = log,
            };
            initialized += 1;
        }
        return .{
            .allocator = allocator,
            .io = io,
            .run_id = run_id,
            .root = root,
            .stop = stop,
            .shards = shards,
        };
    }

    fn deinit(paths: *OwnedPaths) void {
        if (paths.owned) std.Io.Dir.cwd().deleteTree(paths.io, paths.root) catch {};
        for (&paths.shards) |*shard| shard.deinit(paths.allocator);
        paths.allocator.free(paths.stop);
        paths.allocator.free(paths.root);
        paths.* = undefined;
    }
};

fn createOwnedSubdir(
    allocator: std.mem.Allocator,
    io: std.Io,
    root: []const u8,
    name: []const u8,
) ![]u8 {
    const path = try std.fs.path.join(allocator, &.{ root, name });
    errdefer allocator.free(path);
    try std.Io.Dir.cwd().createDir(io, path, .default_dir);
    return path;
}

const ResourceState = struct {
    filesystem_total_bytes: u64,
    floor_bytes: u64,
    starting_free_bytes: u64,
    minimum_free_bytes: u64,
    starting_disk_bytes: u64,
    peak_disk_bytes: u64,
    peak_memory_bytes: u64 = 0,
    samples: usize = 0,

    fn observeFree(state: *ResourceState, free_bytes: u64) !void {
        state.samples += 1;
        state.minimum_free_bytes = @min(state.minimum_free_bytes, free_bytes);
        if (free_bytes < state.floor_bytes) return error.PreoptShardingHeadroomFloorCrossed;
    }

    fn observeDisk(state: *ResourceState, disk_bytes: u64) void {
        state.peak_disk_bytes = @max(state.peak_disk_bytes, disk_bytes);
    }

    fn observeMemory(state: *ResourceState, memory_bytes: u64) void {
        state.peak_memory_bytes = @max(state.peak_memory_bytes, memory_bytes);
    }
};

const WorkerWait = struct {
    term: std.process.Child.Term,
    duration_ms: i96,
    max_rss_bytes: usize,
};

const WaitState = struct {
    done: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
    failed: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
};

fn waitWorker(
    io: std.Io,
    child: *std.process.Child,
    state: *WaitState,
    start: std.Io.Timestamp,
) !WorkerWait {
    defer state.done.store(true, .release);
    const term = try child.wait(io);
    const failed = !common.termOk(term);
    state.failed.store(failed, .release);
    return .{
        .term = term,
        .duration_ms = elapsedMs(io, start),
        .max_rss_bytes = child.resource_usage_statistics.getMaxRss() orelse 0,
    };
}

const WorkerFuture = std.Io.Future(@typeInfo(@TypeOf(waitWorker)).@"fn".return_type.?);

const SpawnedWorker = struct {
    shard_index: usize,
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

fn spawnWorker(
    allocator: std.mem.Allocator,
    io: std.Io,
    options: ParentOptions,
    paths: *const OwnedPaths,
    shard_index: usize,
) !SpawnedWorker {
    const ranges = partition();
    const range = ranges[shard_index];
    const shard = paths.shards[shard_index];
    var env_map = std.process.Environ.Map.init(allocator);
    defer env_map.deinit();
    try copyEnvironment(&env_map, options.environ_map);
    try env_map.put("ZIG_LOCAL_CACHE_DIR", shard.local_cache);
    try env_map.put("ZIG_GLOBAL_CACHE_DIR", shard.global_cache);
    try env_map.put("ZLLVM_PREOPT_SHARD_PRUNING", "suspended");

    const shard_arg = try std.fmt.allocPrint(allocator, "--preopt-shard-worker={}", .{shard_index});
    defer allocator.free(shard_arg);
    const start_arg = try std.fmt.allocPrint(allocator, "--preopt-shard-start={}", .{range.start});
    defer allocator.free(start_arg);
    const end_arg = try std.fmt.allocPrint(allocator, "--preopt-shard-end={}", .{range.end});
    defer allocator.free(end_arg);
    const root_arg = try std.fmt.allocPrint(allocator, "--preopt-shard-root={s}", .{shard.work});
    defer allocator.free(root_arg);
    const result_arg = try std.fmt.allocPrint(allocator, "--preopt-shard-result={s}", .{shard.result});
    defer allocator.free(result_arg);
    const log_arg = try std.fmt.allocPrint(allocator, "--preopt-shard-log={s}", .{shard.log});
    defer allocator.free(log_arg);
    const stop_arg = try std.fmt.allocPrint(allocator, "--preopt-shard-stop={s}", .{paths.stop});
    defer allocator.free(stop_arg);
    const argv = [_][]const u8{
        options.executable_path,
        "--pipeline=preopt",
        shard_arg,
        start_arg,
        end_arg,
        root_arg,
        result_arg,
        log_arg,
        stop_arg,
    };
    const result_file = try std.Io.Dir.cwd().createFile(io, shard.result, .{ .exclusive = true });
    errdefer result_file.close(io);
    const log_file = try std.Io.Dir.cwd().createFile(io, shard.log, .{ .exclusive = true });
    errdefer log_file.close(io);
    const child = if (options.test_options) |test_options| switch (test_options.worker_fixture) {
        .production => try std.process.spawn(io, .{
            .argv = &argv,
            .environ_map = &env_map,
            .stdin = .ignore,
            .stdout = .{ .file = result_file },
            .stderr = .{ .file = log_file },
            .request_resource_usage_statistics = true,
            .pgid = 0,
        }),
        .first_child_fails => if (shard_index == 0)
            try std.process.spawn(io, .{
                .argv = &.{ "/bin/sh", "-c", "printf 'injected-original-child-failure\\n' >&2; exit 7" },
                .stdin = .ignore,
                .stdout = .{ .file = result_file },
                .stderr = .{ .file = log_file },
                .request_resource_usage_statistics = true,
                .pgid = 0,
            })
        else
            try std.process.spawn(io, .{
                .argv = &.{ "/bin/sh", "-c", "sleep 30" },
                .stdin = .ignore,
                .stdout = .{ .file = result_file },
                .stderr = .{ .file = log_file },
                .request_resource_usage_statistics = true,
                .pgid = 0,
            }),
        .all_sleep => try std.process.spawn(io, .{
            .argv = &.{ "/bin/sh", "-c", "sleep 30" },
            .stdin = .ignore,
            .stdout = .{ .file = result_file },
            .stderr = .{ .file = log_file },
            .request_resource_usage_statistics = true,
            .pgid = 0,
        }),
    } else try std.process.spawn(io, .{
        .argv = &argv,
        .environ_map = &env_map,
        .stdin = .ignore,
        .stdout = .{ .file = result_file },
        .stderr = .{ .file = log_file },
        .request_resource_usage_statistics = true,
        .pgid = 0,
    });
    if (options.test_options) |test_options| test_options.audit.launched[shard_index] += 1;
    return .{
        .shard_index = shard_index,
        .pid = child.id.?,
        .child = child,
        .result_file = result_file,
        .log_file = log_file,
        .start = std.Io.Timestamp.now(io, .awake),
    };
}

fn closeWorkerFiles(io: std.Io, worker: *SpawnedWorker, options: ParentOptions) !void {
    if (!worker.reaped) return error.PreoptShardDescriptorsClosedBeforeReap;
    if (worker.child.id != null) return error.PreoptShardDescriptorsClosedBeforeChildCleanup;
    if (worker.descriptors_closed) return error.PreoptShardDescriptorsClosedTwice;
    worker.result_file.close(io);
    worker.log_file.close(io);
    worker.descriptors_closed = true;
    if (options.test_options) |test_options| {
        test_options.audit.descriptors_closed[worker.shard_index] += 1;
        if (test_options.audit.reaped[worker.shard_index] == 0) test_options.audit.close_after_reap = false;
    }
}

const BatchControl = struct {
    shared_stop_requested: bool = false,
};

fn requestSharedStop(
    io: std.Io,
    paths: *const OwnedPaths,
    options: ParentOptions,
    control: *BatchControl,
) void {
    if (control.shared_stop_requested) return;
    control.shared_stop_requested = true;
    std.Io.Dir.cwd().writeFile(io, .{ .sub_path = paths.stop, .data = "stop\n" }) catch {};
    if (options.test_options) |test_options| test_options.audit.shared_stop_requests += 1;
}

fn requestWorkerTermination(worker: *SpawnedWorker, options: ParentOptions) void {
    if (!worker.wait_future_started or worker.state.done.load(.acquire) or
        worker.reaped or worker.termination_requested) return;
    worker.termination_requested = true;
    if (options.test_options) |test_options| test_options.audit.termination_requests[worker.shard_index] += 1;
    std.posix.kill(-worker.pid, .KILL) catch |err| switch (err) {
        error.ProcessNotFound => {},
        else => {},
    };
}

fn requestBatchTermination(
    io: std.Io,
    paths: *const OwnedPaths,
    workers: []SpawnedWorker,
    options: ParentOptions,
    control: *BatchControl,
) void {
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

fn markWorkerReaped(worker: *SpawnedWorker, options: ParentOptions) void {
    if (worker.reaped) return;
    worker.reaped = true;
    if (options.test_options) |test_options| test_options.audit.reaped[worker.shard_index] += 1;
}

fn directlyKillAndReapWorker(io: std.Io, worker: *SpawnedWorker, options: ParentOptions) void {
    if (worker.reaped) return;
    if (!worker.termination_requested) {
        worker.termination_requested = true;
        if (options.test_options) |test_options| test_options.audit.termination_requests[worker.shard_index] += 1;
    }
    worker.child.kill(io);
    worker.state.done.store(true, .release);
    markWorkerReaped(worker, options);
}

fn monitorBatch(
    allocator: std.mem.Allocator,
    io: std.Io,
    paths: *const OwnedPaths,
    workers: []SpawnedWorker,
    resource: *ResourceState,
    options: ParentOptions,
    control: *BatchControl,
) !void {
    while (true) {
        if (allWorkersDone(workers)) break;
        const sample = try sampleFilesystemForRun(allocator, io, paths.root, options);
        if (sample.total_bytes != resource.filesystem_total_bytes) return error.PreoptShardingFilesystemChanged;
        resource.observeFree(sample.free_bytes) catch |err| {
            requestBatchTermination(io, paths, workers, options, control);
            return err;
        };
        resource.observeDisk(try sampleDiskBytes(allocator, io, paths.root));
        resource.observeMemory(try sampleProcessTreeRssBytes(allocator, io, std.os.linux.getpid()));
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
    shard_indices: []const usize,
    resource: *ResourceState,
    waits: *[shard_count]?WorkerWait,
) !void {
    var workers: [shard_count]SpawnedWorker = undefined;
    var worker_count: usize = 0;
    var primary_error: ?anyerror = null;
    for (shard_indices) |shard_index| {
        workers[worker_count] = spawnWorker(allocator, io, options, paths, shard_index) catch |err| {
            primary_error = err;
            break;
        };
        worker_count += 1;
    }

    var futures: [shard_count]WorkerFuture = undefined;
    var future_count: usize = 0;
    if (primary_error == null) {
        for (workers[0..worker_count], 0..) |*worker, index| {
            if (options.test_options) |test_options| {
                if (test_options.fail_wait_future_before_index == index) {
                    primary_error = error.InjectedPreoptWaitFutureSetupFailure;
                    break;
                }
            }
            futures[index] = io.concurrent(waitWorker, .{ io, &worker.child, &worker.state, worker.start }) catch |err| {
                primary_error = err;
                break;
            };
            worker.wait_future_started = true;
            if (options.test_options) |test_options| test_options.audit.wait_futures_started[worker.shard_index] += 1;
            future_count += 1;
        }
    }

    var control: BatchControl = .{};
    if (primary_error == null) {
        monitorBatch(allocator, io, paths, workers[0..worker_count], resource, options, &control) catch |err| {
            primary_error = err;
            requestBatchTermination(io, paths, workers[0..worker_count], options, &control);
        };
        if (anyWorkerFailed(workers[0..worker_count])) {
            requestBatchTermination(io, paths, workers[0..worker_count], options, &control);
        }
    } else {
        requestBatchTermination(io, paths, workers[0..worker_count], options, &control);
    }

    var first_wait_error: ?anyerror = null;
    for (workers[0..future_count], 0..) |*worker, index| {
        const result = futures[index].await(io) catch |err| {
            if (first_wait_error == null) first_wait_error = err;
            worker.state.failed.store(true, .release);
            if (worker.child.id != null) directlyKillAndReapWorker(io, worker, options) else markWorkerReaped(worker, options);
            continue;
        };
        waits[shard_indices[index]] = result;
        if (!common.termOk(result.term)) worker.state.failed.store(true, .release);
        markWorkerReaped(worker, options);
    }

    for (workers[future_count..worker_count]) |*worker| directlyKillAndReapWorker(io, worker, options);

    if (primary_error == null) {
        if (first_wait_error) |err| primary_error = err;
    }
    if (primary_error == null and anyWorkerFailed(workers[0..worker_count])) {
        primary_error = error.PreoptShardChildFailed;
    }
    if (primary_error != null) requestSharedStop(io, paths, options, &control);

    var first_close_error: ?anyerror = null;
    for (workers[0..worker_count]) |*worker| {
        closeWorkerFiles(io, worker, options) catch |err| {
            if (first_close_error == null) first_close_error = err;
        };
    }
    if (primary_error) |err| return err;
    if (first_close_error) |err| return err;
}

pub fn writeNormalizedOutput(output: []const u8, writer: *std.Io.Writer) !void {
    var offset: usize = 0;
    while (offset < output.len) {
        const relative_end = std.mem.indexOfScalar(u8, output[offset..], '\n');
        const end = if (relative_end) |value| offset + value else output.len;
        const line = output[offset..end];
        const has_newline = end < output.len;
        if (std.mem.startsWith(u8, line, "preopt-sharding ")) {
            if (!std.mem.startsWith(u8, line, "preopt-sharding schema=1 ")) {
                return error.UnsupportedPreoptShardingNormalizationSchema;
            }
        } else {
            try writer.writeAll(line);
            if (has_newline) try writer.writeByte('\n');
        }
        offset = end + @intFromBool(has_newline);
    }
}

pub fn runParent(
    allocator: std.mem.Allocator,
    io: std.Io,
    options: ParentOptions,
    writer: *std.Io.Writer,
) !void {
    if (options.concurrency != 1 and options.concurrency != 2) return error.InvalidPreoptConcurrency;
    var paths = try OwnedPaths.init(allocator, io, options.explicit_root);
    defer paths.deinit();

    const preflight = try sampleFilesystemForRun(allocator, io, paths.root, options);
    const policy = headroom_policy.shardingForFilesystem(preflight.total_bytes);
    if (preflight.free_bytes < policy.required_start_bytes) return error.InsufficientPreoptShardingHeadroom;
    const starting_disk = try sampleDiskBytes(allocator, io, paths.root);
    var resource: ResourceState = .{
        .filesystem_total_bytes = preflight.total_bytes,
        .floor_bytes = policy.floor_bytes,
        .starting_free_bytes = preflight.free_bytes,
        .minimum_free_bytes = preflight.free_bytes,
        .starting_disk_bytes = starting_disk,
        .peak_disk_bytes = starting_disk,
    };
    const load_start = try readLoadAverage(allocator, io);
    defer allocator.free(load_start);
    const wall_start = std.Io.Timestamp.now(io, .awake);
    var waits: [shard_count]?WorkerWait = .{ null, null };

    if (options.concurrency == 1) {
        const first = [_]usize{0};
        runBatch(allocator, io, options, &paths, &first, &resource, &waits) catch |err| {
            try preserveFailureEvidence(allocator, io, options, &paths, waits, err);
            return err;
        };
        const second = [_]usize{1};
        runBatch(allocator, io, options, &paths, &second, &resource, &waits) catch |err| {
            try preserveFailureEvidence(allocator, io, options, &paths, waits, err);
            return err;
        };
    } else {
        const both = [_]usize{ 0, 1 };
        runBatch(allocator, io, options, &paths, &both, &resource, &waits) catch |err| {
            try preserveFailureEvidence(allocator, io, options, &paths, waits, err);
            return err;
        };
    }

    const final_sample = try sampleFilesystemForRun(allocator, io, paths.root, options);
    try resource.observeFree(final_sample.free_bytes);
    resource.observeDisk(try sampleDiskBytes(allocator, io, paths.root));
    resource.observeMemory(try sampleProcessTreeRssBytes(allocator, io, std.os.linux.getpid()));
    try mergeShardResults(allocator, io, &paths, options.target, options.zllvm_exe, writer);
    const load_end = try readLoadAverage(allocator, io);
    defer allocator.free(load_end);
    var summed_child_ms: i96 = 0;
    var wait_max_rss: usize = 0;
    for (waits) |item| {
        const wait = item orelse return error.PreoptShardMissingWaitResult;
        summed_child_ms += wait.duration_ms;
        wait_max_rss = @max(wait_max_rss, wait.max_rss_bytes);
    }
    const wall_ms = elapsedMs(io, wall_start);
    try writer.print(
        "preopt-sharding schema={} normalization_schema={} run_id={s} root={s} shard0_work={s} shard0_local_cache={s} shard0_global_cache={s} shard1_work={s} shard1_local_cache={s} shard1_global_cache={s} concurrency={} partitions=0:73,73:146 cases=146 wall_ms={} summed_child_ms={} peak_memory_bytes={} wait4_max_rss_bytes={} peak_disk_bytes={} starting_disk_bytes={} starting_free_bytes={} minimum_free_bytes={} final_free_bytes={} floor_bytes={} required_start_bytes={} samples={} execution_results_cached=false pruning=suspended load_start={s} load_end={s} local_fail=0\n",
        .{
            normalization_schema_version,
            normalization_schema_version,
            &paths.run_id,
            paths.root,
            paths.shards[0].work,
            paths.shards[0].local_cache,
            paths.shards[0].global_cache,
            paths.shards[1].work,
            paths.shards[1].local_cache,
            paths.shards[1].global_cache,
            options.concurrency,
            wall_ms,
            summed_child_ms,
            resource.peak_memory_bytes,
            wait_max_rss,
            resource.peak_disk_bytes,
            resource.starting_disk_bytes,
            resource.starting_free_bytes,
            resource.minimum_free_bytes,
            final_sample.free_bytes,
            policy.floor_bytes,
            policy.required_start_bytes,
            resource.samples,
            load_start,
            load_end,
        },
    );
    try writer.flush();
}

fn mergeShardResults(
    allocator: std.mem.Allocator,
    io: std.Io,
    paths: *const OwnedPaths,
    target: []const u8,
    zllvm_exe: []const u8,
    writer: *std.Io.Writer,
) !void {
    var contents: [shard_count][]u8 = undefined;
    var initialized: usize = 0;
    defer for (contents[0..initialized]) |text| allocator.free(text);
    for (&contents, 0..) |*text, index| {
        text.* = try std.Io.Dir.cwd().readFileAlloc(io, paths.shards[index].result, allocator, .limited(128 * 1024 * 1024));
        initialized += 1;
    }
    const ranges = partition();
    var case_lines: [expected_case_count][]const u8 = undefined;
    for (contents, ranges) |text, range| {
        try validateShardOutput(text, target, zllvm_exe, range, &case_lines);
    }

    try writer.print(
        "zig-integrated-object target={s} pipeline=preopt linker=zig build-exe -fno-lld hook=ZIG_USE_ZLLVM_OBJECT zllvm={s}\n",
        .{ target, zllvm_exe },
    );
    for (case_lines) |line| try writer.print("{s}\n", .{line});
    var executable_ok: usize = 0;
    var link_only_ok: usize = 0;
    for (case_inventory.cases) |case| switch (case.validation) {
        .executable => executable_ok += 1,
        .link_only => link_only_ok += 1,
    };
    try writer.print(
        "summary zig-integrated-object pipeline=preopt ir_writer=false total={} executable_ok={} link_only_ok={} local_fail=0\n",
        .{ expected_case_count, executable_ok, link_only_ok },
    );
}

fn validateShardOutput(
    output: []const u8,
    target: []const u8,
    zllvm_exe: []const u8,
    range: Range,
    case_lines: *[expected_case_count][]const u8,
) !void {
    var expected_header_buffer: [1024]u8 = undefined;
    const expected_header = try std.fmt.bufPrint(
        &expected_header_buffer,
        "zig-integrated-object target={s} pipeline=preopt linker=zig build-exe -fno-lld hook=ZIG_USE_ZLLVM_OBJECT zllvm={s}",
        .{ target, zllvm_exe },
    );
    var expected_executable: usize = 0;
    var expected_link_only: usize = 0;
    for (case_inventory.cases[range.start..range.end]) |case| switch (case.validation) {
        .executable => expected_executable += 1,
        .link_only => expected_link_only += 1,
    };
    var expected_summary_buffer: [256]u8 = undefined;
    const expected_summary = try std.fmt.bufPrint(
        &expected_summary_buffer,
        "summary zig-integrated-object pipeline=preopt ir_writer=false total={} executable_ok={} link_only_ok={} local_fail=0",
        .{ range.len(), expected_executable, expected_link_only },
    );

    var lines = std.mem.splitScalar(u8, output, '\n');
    const header = lines.next() orelse return error.PreoptShardMissingHeader;
    if (!std.mem.eql(u8, header, expected_header)) return error.PreoptShardHeaderMismatch;
    for (range.start..range.end) |case_index| {
        const line = lines.next() orelse return error.PreoptShardMissingCaseRecord;
        const case = case_inventory.cases[case_index];
        var prefix_buffer: [512]u8 = undefined;
        const prefix = try std.fmt.bufPrint(&prefix_buffer, "ok zig-integrated-object {s} ", .{case.id});
        if (!std.mem.startsWith(u8, line, prefix)) return error.PreoptShardCaseOrderMismatch;
        case_lines[case_index] = line;
    }
    const summary = lines.next() orelse return error.PreoptShardMissingSummary;
    if (!std.mem.eql(u8, summary, expected_summary)) return error.PreoptShardSummaryMismatch;
    while (lines.next()) |line| {
        if (line.len != 0) return error.PreoptShardExtraRecord;
    }
}

fn preserveFailureEvidence(
    allocator: std.mem.Allocator,
    io: std.Io,
    options: ParentOptions,
    paths: *const OwnedPaths,
    waits: [shard_count]?WorkerWait,
    failure: anyerror,
) !void {
    var cwd = std.Io.Dir.cwd();
    const evidence_dir = if (options.test_options) |test_options| test_options.failure_evidence_dir else "tmp/preopt_sharding_failures";
    try cwd.createDirPath(io, evidence_dir);
    const manifest_name = try std.fmt.allocPrint(allocator, "{s}.manifest", .{&paths.run_id});
    defer allocator.free(manifest_name);
    const manifest_path = try std.fs.path.join(allocator, &.{ evidence_dir, manifest_name });
    defer allocator.free(manifest_path);
    var buffer: [2048]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);
    try writer.print("schema=1 run_id={s} failure={s}\n", .{ &paths.run_id, @errorName(failure) });
    for (waits, 0..) |item, shard_index| {
        if (item) |wait| {
            try writer.print("shard={} range={}:{} term={any} duration_ms={}\n", .{ shard_index, partition()[shard_index].start, partition()[shard_index].end, wait.term, wait.duration_ms });
        } else {
            try writer.print("shard={} range={}:{} term=not-launched-or-not-reaped\n", .{ shard_index, partition()[shard_index].start, partition()[shard_index].end });
        }
        const log = cwd.readFileAlloc(io, paths.shards[shard_index].log, allocator, .limited(64 * 1024)) catch continue;
        defer allocator.free(log);
        const compact_name = try std.fmt.allocPrint(allocator, "{s}.shard{}.log", .{ &paths.run_id, shard_index });
        defer allocator.free(compact_name);
        const compact_path = try std.fs.path.join(allocator, &.{ evidence_dir, compact_name });
        defer allocator.free(compact_path);
        try cwd.writeFile(io, .{ .sub_path = compact_path, .data = log });
    }
    try cwd.writeFile(io, .{ .sub_path = manifest_path, .data = writer.buffered() });
    if (options.test_options) |test_options| {
        test_options.audit.evidence_preserved_before_cleanup = try pathExists(io, paths.root);
        test_options.audit.failure_run_id = paths.run_id;
        test_options.audit.failure_run_id_recorded = true;
    }
}

const FilesystemSample = struct { total_bytes: u64, free_bytes: u64 };

fn sampleFilesystemForRun(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
    options: ParentOptions,
) !FilesystemSample {
    if (options.test_options) |test_options| {
        if (test_options.filesystem_sample) |sample| return sample;
    }
    return sampleFilesystem(allocator, io, path);
}

fn sampleFilesystem(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !FilesystemSample {
    const argv = [_][]const u8{ "df", "-B1", "--output=size,avail", path };
    const result = try common.runCapture(allocator, io, &argv, "preopt sharding df sample");
    defer common.freeRunResult(allocator, result);
    var fields = std.mem.tokenizeAny(u8, result.stdout, " \t\r\n");
    _ = fields.next() orelse return error.InvalidPreoptFilesystemSample;
    _ = fields.next() orelse return error.InvalidPreoptFilesystemSample;
    const total = fields.next() orelse return error.InvalidPreoptFilesystemSample;
    const free = fields.next() orelse return error.InvalidPreoptFilesystemSample;
    if (fields.next() != null) return error.InvalidPreoptFilesystemSample;
    return .{
        .total_bytes = try std.fmt.parseUnsigned(u64, total, 10),
        .free_bytes = try std.fmt.parseUnsigned(u64, free, 10),
    };
}

fn sampleDiskBytes(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !u64 {
    const argv = [_][]const u8{ "du", "-sb", path };
    const result = try common.runCapture(allocator, io, &argv, "preopt sharding disk sample");
    defer common.freeRunResult(allocator, result);
    var fields = std.mem.tokenizeAny(u8, result.stdout, " \t\r\n");
    const field = fields.next() orelse return error.InvalidPreoptDiskSample;
    return std.fmt.parseUnsigned(u64, field, 10);
}

fn sampleProcessTreeRssBytes(
    allocator: std.mem.Allocator,
    io: std.Io,
    root_pid: std.posix.pid_t,
) !u64 {
    const argv = [_][]const u8{ "ps", "-e", "-o", "pid=,ppid=,rss=" };
    const result = try common.runCapture(allocator, io, &argv, "preopt sharding memory sample");
    defer common.freeRunResult(allocator, result);
    const Entry = struct { pid: i32, ppid: i32, rss_kib: u64 };
    var entries: std.ArrayList(Entry) = .empty;
    defer entries.deinit(allocator);
    var lines = std.mem.splitScalar(u8, result.stdout, '\n');
    while (lines.next()) |line| {
        var fields = std.mem.tokenizeAny(u8, line, " \t");
        const pid_text = fields.next() orelse continue;
        const ppid_text = fields.next() orelse continue;
        const rss_text = fields.next() orelse continue;
        try entries.append(allocator, .{
            .pid = try std.fmt.parseInt(i32, pid_text, 10),
            .ppid = try std.fmt.parseInt(i32, ppid_text, 10),
            .rss_kib = try std.fmt.parseUnsigned(u64, rss_text, 10),
        });
    }
    var descendants = std.AutoHashMap(i32, void).init(allocator);
    defer descendants.deinit();
    try descendants.put(root_pid, {});
    var changed = true;
    while (changed) {
        changed = false;
        for (entries.items) |entry| {
            if (!descendants.contains(entry.pid) and descendants.contains(entry.ppid)) {
                try descendants.put(entry.pid, {});
                changed = true;
            }
        }
    }
    var total_kib: u64 = 0;
    for (entries.items) |entry| if (descendants.contains(entry.pid)) {
        total_kib +|= entry.rss_kib;
    };
    return total_kib *| 1024;
}

fn readLoadAverage(allocator: std.mem.Allocator, io: std.Io) ![]u8 {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, "/proc/loadavg", allocator, .limited(4096));
    defer allocator.free(contents);
    const trimmed = std.mem.trim(u8, contents, " \t\r\n");
    const end = std.mem.indexOfScalar(u8, trimmed, ' ') orelse trimmed.len;
    return allocator.dupe(u8, trimmed[0..end]);
}

fn copyEnvironment(destination: *std.process.Environ.Map, source: *const std.process.Environ.Map) !void {
    var iterator = source.iterator();
    while (iterator.next()) |entry| try destination.put(entry.key_ptr.*, entry.value_ptr.*);
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

test "partition covers exactly 146 cases once with stable contiguous assignment" {
    const ranges = partition();
    try std.testing.expectEqual(@as(usize, 2), ranges.len);
    try std.testing.expectEqual(Range{ .start = 0, .end = 73 }, ranges[0]);
    try std.testing.expectEqual(Range{ .start = 73, .end = 146 }, ranges[1]);
    var seen = [_]bool{false} ** expected_case_count;
    for (ranges) |range| for (range.start..range.end) |index| {
        try std.testing.expect(!seen[index]);
        seen[index] = true;
    };
    for (seen) |value| try std.testing.expect(value);
}

test "headroom state fails closed below the ten-percent floor without a sentinel" {
    var state: ResourceState = .{
        .filesystem_total_bytes = 1_000,
        .floor_bytes = 100,
        .starting_free_bytes = 300,
        .minimum_free_bytes = 300,
        .starting_disk_bytes = 0,
        .peak_disk_bytes = 0,
    };
    try state.observeFree(120);
    try std.testing.expectEqual(@as(u64, 120), state.minimum_free_bytes);
    try std.testing.expectError(error.PreoptShardingHeadroomFloorCrossed, state.observeFree(99));
}

test "pre-existing explicit root is refused without mutation" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();
    const existing = try std.fs.path.join(allocator, &.{ ".zig-cache", "tmp", &temp.sub_path });
    defer allocator.free(existing);
    const sentinel = try std.fs.path.join(allocator, &.{ existing, "sentinel" });
    defer allocator.free(sentinel);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = sentinel, .data = "preserve" });
    try std.testing.expectError(error.PreoptShardRootAlreadyExists, OwnedPaths.init(allocator, io, existing));
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, sentinel, allocator, .limited(32));
    defer allocator.free(contents);
    try std.testing.expectEqualStrings("preserve", contents);
}

test "owned paths are unique and cleanup removes only the owned root" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var first = try OwnedPaths.init(allocator, io, null);
    const first_root = try allocator.dupe(u8, first.root);
    defer allocator.free(first_root);
    first.deinit();
    try std.testing.expect(!(try pathExists(io, first_root)));
    var second = try OwnedPaths.init(allocator, io, null);
    defer second.deinit();
    try std.testing.expect(!std.mem.eql(u8, first_root, second.root));
    for (second.shards) |shard| {
        try std.testing.expect(try pathExists(io, shard.work));
        try std.testing.expect(try pathExists(io, shard.local_cache));
        try std.testing.expect(try pathExists(io, shard.global_cache));
    }
}

test "partial shard publication validates before emitting merged output" {
    var case_lines: [expected_case_count][]const u8 = undefined;
    try std.testing.expectError(
        error.PreoptShardHeaderMismatch,
        validateShardOutput("partial\n", "x86_64-linux-gnu", "zig-out/bin/z_llvm", partition()[0], &case_lines),
    );
    var buffer: [64]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);
    try std.testing.expectEqual(@as(usize, 0), writer.buffered().len);
}

test "cleanup eligibility requires every launched worker to be reaped" {
    var states = [_]WaitState{ .{}, .{} };
    try std.testing.expect(!states[0].done.load(.acquire));
    states[0].done.store(true, .release);
    try std.testing.expect(!(states[0].done.load(.acquire) and states[1].done.load(.acquire)));
    states[1].done.store(true, .release);
    try std.testing.expect(states[0].done.load(.acquire) and states[1].done.load(.acquire));
}

test "child failure requests stop while cleanup still waits for every worker" {
    var workers: [2]SpawnedWorker = undefined;
    workers[0].state = .{};
    workers[1].state = .{};
    workers[0].state.failed.store(true, .release);
    workers[0].state.done.store(true, .release);
    try std.testing.expect(anyWorkerFailed(&workers));
    try std.testing.expect(!allWorkersDone(&workers));
    workers[1].state.done.store(true, .release);
    try std.testing.expect(allWorkersDone(&workers));
}

fn expectCompleteBatchAudit(audit: *const BatchAudit) !void {
    try std.testing.expectEqual([2]usize{ 1, 1 }, audit.launched);
    try std.testing.expectEqual([2]usize{ 1, 1 }, audit.reaped);
    try std.testing.expectEqual([2]usize{ 1, 1 }, audit.descriptors_closed);
    try std.testing.expect(audit.close_after_reap);
    try std.testing.expectEqual(@as(usize, 1), audit.shared_stop_requests);
    for (audit.termination_requests) |count| try std.testing.expect(count <= 1);
    try std.testing.expect(audit.evidence_preserved_before_cleanup);
    try std.testing.expect(audit.failure_run_id_recorded);
}

test "production parent preserves child failure and closes once after every worker is reaped" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();
    const base = try std.fs.path.join(allocator, &.{ ".zig-cache", "tmp", &temp.sub_path });
    defer allocator.free(base);
    const root = try std.fs.path.join(allocator, &.{ base, "owned-root" });
    defer allocator.free(root);
    const evidence_dir = try std.fs.path.join(allocator, &.{ base, "compact-evidence" });
    defer allocator.free(evidence_dir);
    var environ = std.process.Environ.Map.init(allocator);
    defer environ.deinit();
    var audit: BatchAudit = .{};
    const test_options: TestOptions = .{
        .worker_fixture = .first_child_fails,
        .monitor_interval_ns = std.time.ns_per_ms,
        .failure_evidence_dir = evidence_dir,
        .filesystem_sample = .{ .total_bytes = 1_000_000_000_000, .free_bytes = 200_000_000_000 },
        .audit = &audit,
    };
    var output_buffer: [4096]u8 = undefined;
    var output = std.Io.Writer.fixed(&output_buffer);
    try std.testing.expectError(error.PreoptShardChildFailed, runParent(allocator, io, .{
        .executable_path = "unused-test-worker",
        .target = "x86_64-unknown-linux-gnu",
        .zllvm_exe = "zig-out/bin/z_llvm",
        .concurrency = 2,
        .explicit_root = root,
        .environ_map = &environ,
        .test_options = test_options,
    }, &output));
    try expectCompleteBatchAudit(&audit);
    try std.testing.expectEqual([2]usize{ 1, 1 }, audit.wait_futures_started);
    try std.testing.expect(!std.mem.containsAtLeast(u8, output.buffered(), 1, "summary zig-integrated-object"));
    try std.testing.expect(!(try pathExists(io, root)));

    const manifest_name = try std.fmt.allocPrint(allocator, "{s}.manifest", .{&audit.failure_run_id});
    defer allocator.free(manifest_name);
    const manifest_path = try std.fs.path.join(allocator, &.{ evidence_dir, manifest_name });
    defer allocator.free(manifest_path);
    const manifest = try std.Io.Dir.cwd().readFileAlloc(io, manifest_path, allocator, .limited(16 * 1024));
    defer allocator.free(manifest);
    try std.testing.expect(std.mem.containsAtLeast(u8, manifest, 1, "failure=PreoptShardChildFailed"));

    const log_name = try std.fmt.allocPrint(allocator, "{s}.shard0.log", .{&audit.failure_run_id});
    defer allocator.free(log_name);
    const log_path = try std.fs.path.join(allocator, &.{ evidence_dir, log_name });
    defer allocator.free(log_path);
    const log = try std.Io.Dir.cwd().readFileAlloc(io, log_path, allocator, .limited(16 * 1024));
    defer allocator.free(log);
    try std.testing.expectEqualStrings("injected-original-child-failure\n", log);
}

test "partial wait-future setup signals future owner then directly kills and reaps remainder" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();
    const base = try std.fs.path.join(allocator, &.{ ".zig-cache", "tmp", &temp.sub_path });
    defer allocator.free(base);
    const root = try std.fs.path.join(allocator, &.{ base, "owned-root" });
    defer allocator.free(root);
    const evidence_dir = try std.fs.path.join(allocator, &.{ base, "compact-evidence" });
    defer allocator.free(evidence_dir);
    var environ = std.process.Environ.Map.init(allocator);
    defer environ.deinit();
    var audit: BatchAudit = .{};
    const test_options: TestOptions = .{
        .worker_fixture = .all_sleep,
        .fail_wait_future_before_index = 1,
        .monitor_interval_ns = std.time.ns_per_ms,
        .failure_evidence_dir = evidence_dir,
        .filesystem_sample = .{ .total_bytes = 1_000_000_000_000, .free_bytes = 200_000_000_000 },
        .audit = &audit,
    };
    var output_buffer: [4096]u8 = undefined;
    var output = std.Io.Writer.fixed(&output_buffer);
    try std.testing.expectError(error.InjectedPreoptWaitFutureSetupFailure, runParent(allocator, io, .{
        .executable_path = "unused-test-worker",
        .target = "x86_64-unknown-linux-gnu",
        .zllvm_exe = "zig-out/bin/z_llvm",
        .concurrency = 2,
        .explicit_root = root,
        .environ_map = &environ,
        .test_options = test_options,
    }, &output));
    try expectCompleteBatchAudit(&audit);
    try std.testing.expectEqual([2]usize{ 1, 0 }, audit.wait_futures_started);
    try std.testing.expectEqual([2]usize{ 1, 1 }, audit.termination_requests);
    try std.testing.expect(!std.mem.containsAtLeast(u8, output.buffered(), 1, "summary zig-integrated-object"));
    try std.testing.expect(!(try pathExists(io, root)));

    const manifest_name = try std.fmt.allocPrint(allocator, "{s}.manifest", .{&audit.failure_run_id});
    defer allocator.free(manifest_name);
    const manifest_path = try std.fs.path.join(allocator, &.{ evidence_dir, manifest_name });
    defer allocator.free(manifest_path);
    const manifest = try std.Io.Dir.cwd().readFileAlloc(io, manifest_path, allocator, .limited(16 * 1024));
    defer allocator.free(manifest);
    try std.testing.expect(std.mem.containsAtLeast(u8, manifest, 1, "failure=InjectedPreoptWaitFutureSetupFailure"));
}

test "bounded fake child failure kills and reaps the active peer" {
    const io = std.testing.io;
    var failed_child = try std.process.spawn(io, .{
        .argv = &.{ "/bin/sh", "-c", "exit 7" },
        .stdin = .ignore,
        .stdout = .ignore,
        .stderr = .ignore,
        .pgid = 0,
    });
    defer failed_child.kill(io);
    var peer_child = try std.process.spawn(io, .{
        .argv = &.{ "/bin/sh", "-c", "sleep 10" },
        .stdin = .ignore,
        .stdout = .ignore,
        .stderr = .ignore,
        .pgid = 0,
    });
    defer peer_child.kill(io);
    const peer_pid = peer_child.id.?;
    var failed_state: WaitState = .{};
    var peer_state: WaitState = .{};
    var failed_future: WorkerFuture = try io.concurrent(waitWorker, .{ io, &failed_child, &failed_state, std.Io.Timestamp.now(io, .awake) });
    var peer_future: WorkerFuture = try io.concurrent(waitWorker, .{ io, &peer_child, &peer_state, std.Io.Timestamp.now(io, .awake) });
    const failed_wait = try failed_future.await(io);
    try std.testing.expect(!common.termOk(failed_wait.term));
    try std.testing.expect(failed_state.failed.load(.acquire));
    try std.posix.kill(-peer_pid, .KILL);
    const peer_wait = try peer_future.await(io);
    try std.testing.expect(!common.termOk(peer_wait.term));
    try std.testing.expect(failed_state.done.load(.acquire));
    try std.testing.expect(peer_state.done.load(.acquire));
}

test "manifest-order validation is stable when shard completion order is reversed" {
    const allocator = std.testing.allocator;
    const ranges = partition();
    var outputs: [shard_count][]u8 = undefined;
    defer for (outputs) |output| allocator.free(output);
    for (&outputs, ranges) |*output, range| {
        var buffer: [128 * 1024]u8 = undefined;
        var writer = std.Io.Writer.fixed(&buffer);
        try writer.writeAll("zig-integrated-object target=x86_64-linux-gnu pipeline=preopt linker=zig build-exe -fno-lld hook=ZIG_USE_ZLLVM_OBJECT zllvm=zig-out/bin/z_llvm\n");
        var executable: usize = 0;
        var link_only: usize = 0;
        for (case_inventory.cases[range.start..range.end]) |case| {
            try writer.print("ok zig-integrated-object {s} fake-record\n", .{case.id});
            switch (case.validation) {
                .executable => executable += 1,
                .link_only => link_only += 1,
            }
        }
        try writer.print(
            "summary zig-integrated-object pipeline=preopt ir_writer=false total={} executable_ok={} link_only_ok={} local_fail=0\n",
            .{ range.len(), executable, link_only },
        );
        output.* = try allocator.dupe(u8, writer.buffered());
    }
    var case_lines: [expected_case_count][]const u8 = undefined;
    try validateShardOutput(outputs[1], "x86_64-linux-gnu", "zig-out/bin/z_llvm", ranges[1], &case_lines);
    try validateShardOutput(outputs[0], "x86_64-linux-gnu", "zig-out/bin/z_llvm", ranges[0], &case_lines);
    for (case_lines, case_inventory.cases) |line, case| {
        var prefix_buffer: [512]u8 = undefined;
        const prefix = try std.fmt.bufPrint(&prefix_buffer, "ok zig-integrated-object {s} ", .{case.id});
        try std.testing.expect(std.mem.startsWith(u8, line, prefix));
    }
}

test "normalization v1 removes only shard bookkeeping records" {
    var buffer: [256]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);
    try writeNormalizedOutput(
        "header\n\npreopt-sharding schema=1 wall_ms=12\nok zig-integrated-object case fake\nsummary stable\n",
        &writer,
    );
    try std.testing.expectEqualStrings(
        "header\n\nok zig-integrated-object case fake\nsummary stable\n",
        writer.buffered(),
    );
    var bad_buffer: [64]u8 = undefined;
    var bad_writer = std.Io.Writer.fixed(&bad_buffer);
    try std.testing.expectError(
        error.UnsupportedPreoptShardingNormalizationSchema,
        writeNormalizedOutput("preopt-sharding schema=2 wall_ms=12\n", &bad_writer),
    );
}
