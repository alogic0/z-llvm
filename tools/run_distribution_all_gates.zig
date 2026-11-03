const std = @import("std");
const common = @import("tool_common.zig");
const headroom_policy = @import("distribution_headroom_policy.zig");
const release_bundle = @import("release_source_object_bundle.zig");
const real_rows_parallel = @import("run_distribution_real_rows_parallel.zig");

const Tool = struct {
    id: []const u8,
    path: []const u8,
    args: []const []const u8 = &.{},
    cache_contract: CacheContract = .unreported,
    artifact_contract: ArtifactContract = .none,
};

const ArtifactContract = enum {
    none,
    release_source_object_bundle_v1,
};

const CacheContract = enum {
    unreported,
    air_export_v1,
};

const CacheStatus = enum {
    none,
    hit,
    miss,
    mixed,
};

const Measurement = struct {
    tool_index: usize,
    duration_ms: i96,
    cache_status: CacheStatus,
};

const CompletedTool = struct {
    result: std.process.RunResult,
    duration_ms: i96,
};

const ExecutionMode = enum {
    parallel,
    serial,
    inventory,
};

const Options = struct {
    allocator: std.mem.Allocator,
    mode: ExecutionMode = .parallel,
    fresh_real_rows: bool = false,
    real_rows_concurrency: u8 = 3,
    real_rows_concurrency_explicit: bool = false,
    zig_emitter: ?[]u8 = null,
    real_rows_validation_root: ?[]u8 = null,
    real_rows_cache_root: ?[]u8 = null,
    serial_root: ?[]u8 = null,

    fn deinit(options: *Options) void {
        if (options.zig_emitter) |path| options.allocator.free(path);
        if (options.real_rows_cache_root) |path| options.allocator.free(path);
        if (options.real_rows_validation_root) |path| options.allocator.free(path);
        if (options.serial_root) |path| options.allocator.free(path);
        options.* = undefined;
    }
};

const FilesystemSample = struct {
    total_bytes: u64,
    free_bytes: u64,
};

const RunMetrics = struct {
    measurements: [tools.len]Measurement = undefined,
    total_duration_ms: i96 = 0,
    cache_hits: usize = 0,
    cache_misses: usize = 0,
    cache_mixed: usize = 0,
    cache_none: usize = 0,
};

const tools = [_]Tool{
    .{ .id = "selected-object-suite", .path = "tools/run_distribution_no_llvm_codegen_subset.zig" },
    .{ .id = "selected-object-inspection", .path = "tools/run_native_link_object_inspection.zig" },
    .{ .id = "selected-native-link", .path = "tools/run_distribution_native_link_m5.zig" },
    .{ .id = "selected-native-probe", .path = "tools/probe_native_linker_compatibility.zig" },
    .{ .id = "zig-source-native-link", .path = "tools/run_distribution_zig_source_native_link.zig" },
    .{ .id = "integrated-object-postopt", .path = "tools/run_distribution_zig_integrated_object.zig" },
    .{ .id = "integrated-object-preopt", .path = "tools/run_distribution_zig_integrated_object.zig", .args = &.{"--pipeline=preopt"} },
    .{ .id = "integrated-object-ir-writer", .path = "tools/run_distribution_zig_integrated_object.zig", .args = &.{"--ir-writer"} },
    .{ .id = "integrated-object-release", .path = "tools/run_distribution_zig_integrated_object.zig", .args = &.{"--release-source-owned"}, .artifact_contract = .release_source_object_bundle_v1 },
    .{ .id = "real-rows-release-fast", .path = "src/distribution_real_rows_gate.zig", .args = &.{ "--mode=ReleaseFast", "--strict", "--limit=100" }, .cache_contract = .air_export_v1 },
    .{ .id = "real-rows-release-safe", .path = "src/distribution_real_rows_gate.zig", .args = &.{ "--mode=ReleaseSafe", "--strict", "--limit=100" }, .cache_contract = .air_export_v1 },
    .{ .id = "real-rows-release-small", .path = "src/distribution_real_rows_gate.zig", .args = &.{ "--mode=ReleaseSmall", "--strict", "--limit=100" }, .cache_contract = .air_export_v1 },
    .{ .id = "integrated-executable", .path = "tools/run_distribution_zig_integrated_exe.zig" },
    .{ .id = "release-object-inspection", .path = "tools/run_native_link_object_inspection.zig", .args = &.{"--release-source-owned"}, .artifact_contract = .release_source_object_bundle_v1 },
    .{ .id = "release-native-link", .path = "tools/run_distribution_native_link_m5.zig", .args = &.{"--release-source-owned"}, .artifact_contract = .release_source_object_bundle_v1 },
    .{ .id = "release-native-probe", .path = "tools/probe_native_linker_compatibility.zig", .args = &.{"--release-source-owned"}, .artifact_contract = .release_source_object_bundle_v1 },
    .{ .id = "boundary-gates", .path = "tools/run_distribution_boundary_gates.zig" },
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    var options = try parseArgs(allocator, init);
    defer options.deinit();

    const target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);
    const target = target_env orelse "x86_64-unknown-linux-gnu";
    if (options.mode == .inventory) return writeInventory(io, target);
    _ = try real_rows_parallel.validateRoots(io, options.real_rows_validation_root.?, options.real_rows_cache_root.?);
    real_rows_parallel.validateCacheSelection(io, options.real_rows_cache_root.?, if (options.fresh_real_rows) .fresh else .require_hit) catch |err| {
        if (err == error.RealRowsFreshCacheAlreadyExists) std.debug.print(
            "fresh real-row cache already exists under {s}; select an unused cache generation or run without --fresh-real-rows to require a cache hit\n",
            .{options.real_rows_cache_root.?},
        );
        return err;
    };
    const target_assignment = try std.fmt.allocPrint(allocator, "TARGET={s}", .{target});
    defer allocator.free(target_assignment);
    if (options.mode == .serial) {
        return runSerial(allocator, io, target, target_assignment, options);
    }
    const fresh_real_rows = options.fresh_real_rows;
    const bundle_temp = try common.TempDir.init(allocator, io, "distribution_all_release_bundle");
    defer bundle_temp.deinit(allocator, io);
    const bundle_assignment = try std.fmt.allocPrint(allocator, "{s}={s}", .{ release_bundle.env_name, bundle_temp.path });
    defer allocator.free(bundle_assignment);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print("distribution all gates target={s}\n", .{target});
    try writeMemoryPolicyEvidence(&stdout_writer.interface);
    try stdout_writer.interface.flush();

    var metrics: RunMetrics = .{};

    var tool_index: usize = 0;
    while (tool_index < tools.len) {
        if (tool_index == 9) {
            var group = try real_rows_parallel.runGroup(allocator, io, realRowsParentOptions(target_assignment, options));
            defer group.deinit(allocator);
            for (0..real_rows_parallel.mode_count) |offset| {
                const completed_index = tool_index + offset;
                try writeToolStart(&stdout_writer.interface, completed_index, target, fresh_real_rows);
                const group_completed = group.takeCompleted(offset);
                const completed: CompletedTool = .{ .result = group_completed.result, .duration_ms = group_completed.duration_ms };
                defer common.freeRunResult(allocator, completed.result);
                try recordToolCompletion(&stdout_writer.interface, completed_index, completed, &metrics);
            }
            try real_rows_parallel.writeEvidence(&stdout_writer.interface, &group.evidence);
            tool_index += real_rows_parallel.mode_count;
            continue;
        }
        const completed = try runTool(allocator, io, target_assignment, bundle_assignment, tool_index, fresh_real_rows);
        try recordTool(
            &stdout_writer.interface,
            tool_index,
            completed,
            &metrics,
            target,
            fresh_real_rows,
        );
        common.freeRunResult(allocator, completed.result);
        tool_index += 1;
    }

    try writeRunSummaries(&stdout_writer.interface, &metrics, target, fresh_real_rows);
    try stdout_writer.interface.writeAll("ok distribution all gates\n");
    try stdout_writer.interface.flush();
}

const OwnedSerialPaths = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    run_id: [32]u8,
    scratch_path: []u8,
    bundle_path: []u8,
    owned: bool = true,

    fn init(
        allocator: std.mem.Allocator,
        io: std.Io,
        explicit_scratch_path: ?[]const u8,
    ) !OwnedSerialPaths {
        var cwd = std.Io.Dir.cwd();
        var random_bytes: [16]u8 = undefined;
        io.random(&random_bytes);
        var run_id = std.fmt.bytesToHex(random_bytes, .lower);

        const scratch_path = if (explicit_scratch_path) |path| blk: {
            const owned_path = try allocator.dupe(u8, path);
            errdefer allocator.free(owned_path);
            cwd.createDir(io, owned_path, .default_dir) catch |err| switch (err) {
                error.PathAlreadyExists => return error.SerialScratchAlreadyExists,
                else => return err,
            };
            break :blk owned_path;
        } else blk: {
            try cwd.createDirPath(io, "tmp");
            var attempt: usize = 0;
            while (attempt < 16) : (attempt += 1) {
                io.random(&random_bytes);
                const candidate_id = std.fmt.bytesToHex(random_bytes, .lower);
                run_id = candidate_id;
                const candidate = try std.fmt.allocPrint(allocator, "tmp/distribution_all_serial_{s}", .{&candidate_id});
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
                break :blk candidate;
            }
            return error.SerialScratchCollisionLimit;
        };
        errdefer {
            cwd.deleteTree(io, scratch_path) catch {};
            allocator.free(scratch_path);
        }

        const bundle_path = try std.fs.path.join(allocator, &.{ scratch_path, "release_source_object_bundle" });
        errdefer allocator.free(bundle_path);
        cwd.createDir(io, bundle_path, .default_dir) catch |err| switch (err) {
            error.PathAlreadyExists => return error.SerialBundleAlreadyExists,
            else => return err,
        };

        return .{
            .allocator = allocator,
            .io = io,
            .run_id = run_id,
            .scratch_path = scratch_path,
            .bundle_path = bundle_path,
        };
    }

    fn deinit(paths: *OwnedSerialPaths) void {
        if (paths.owned) {
            std.Io.Dir.cwd().deleteTree(paths.io, paths.scratch_path) catch {};
        }
        paths.allocator.free(paths.bundle_path);
        paths.allocator.free(paths.scratch_path);
        paths.* = undefined;
    }
};

const FreeSpaceSampler = struct {
    context: *anyopaque,
    sampleFn: *const fn (*anyopaque, std.mem.Allocator, std.Io, []const u8) anyerror!FilesystemSample,

    fn sample(
        sampler: FreeSpaceSampler,
        allocator: std.mem.Allocator,
        io: std.Io,
        path: []const u8,
    ) !FilesystemSample {
        return sampler.sampleFn(sampler.context, allocator, io, path);
    }
};

const ToolExecutor = struct {
    context: *anyopaque,
    runFn: *const fn (*anyopaque, std.mem.Allocator, std.Io, usize, bool) anyerror!CompletedTool,

    fn run(
        executor: ToolExecutor,
        allocator: std.mem.Allocator,
        io: std.Io,
        tool_index: usize,
        fresh_real_rows: bool,
    ) !CompletedTool {
        return executor.runFn(executor.context, allocator, io, tool_index, fresh_real_rows);
    }
};

const RealSampler = struct {
    fn interface(sampler: *RealSampler) FreeSpaceSampler {
        return .{ .context = sampler, .sampleFn = sample };
    }

    fn sample(
        context: *anyopaque,
        allocator: std.mem.Allocator,
        io: std.Io,
        path: []const u8,
    ) !FilesystemSample {
        _ = context;
        return sampleFilesystem(allocator, io, path);
    }
};

const RealExecutor = struct {
    target_assignment: []const u8,
    bundle_assignment: []const u8,

    fn interface(executor: *RealExecutor) ToolExecutor {
        return .{ .context = executor, .runFn = run };
    }

    fn run(
        context: *anyopaque,
        allocator: std.mem.Allocator,
        io: std.Io,
        tool_index: usize,
        fresh_real_rows: bool,
    ) !CompletedTool {
        const executor: *RealExecutor = @ptrCast(@alignCast(context));
        return runTool(
            allocator,
            io,
            executor.target_assignment,
            executor.bundle_assignment,
            tool_index,
            fresh_real_rows,
        );
    }
};

const BundleEvidence = struct {
    identity: [64]u8 = undefined,
    identity_set: bool = false,
    producer_count: usize = 0,
    consumer_count: usize = 0,

    fn observe(evidence: *BundleEvidence, tool_index: usize, output: []const u8) !void {
        if (tools[tool_index].artifact_contract != .release_source_object_bundle_v1) return;
        var matched_lines: usize = 0;
        var lines = std.mem.splitScalar(u8, output, '\n');
        while (lines.next()) |line| {
            if (!std.mem.startsWith(u8, line, "summary release-source-object-bundle ")) continue;
            matched_lines += 1;
            const identity_text = fieldValue(line, "identity=") orelse return error.MissingBundleIdentity;
            if (identity_text.len != evidence.identity.len) return error.InvalidBundleIdentity;
            if (!evidence.identity_set) {
                @memcpy(&evidence.identity, identity_text);
                evidence.identity_set = true;
            } else if (!std.mem.eql(u8, &evidence.identity, identity_text)) {
                return error.BundleIdentityMismatch;
            }

            if (std.mem.eql(u8, tools[tool_index].id, "integrated-object-release")) {
                if (std.mem.indexOf(u8, line, "status=produced") == null or
                    std.mem.indexOf(u8, line, "atomic_publication=true") == null)
                {
                    return error.InvalidBundleProducerSummary;
                }
                evidence.producer_count += 1;
            } else {
                if (std.mem.indexOf(u8, line, "status=reused") == null or
                    std.mem.indexOf(u8, line, "executions_cached=false") == null)
                {
                    return error.InvalidBundleConsumerSummary;
                }
                evidence.consumer_count += 1;
            }
        }
        if (matched_lines != 1) return error.BundleSummaryCountMismatch;
    }

    fn finish(evidence: *const BundleEvidence) !void {
        if (!evidence.identity_set or evidence.producer_count != 1 or evidence.consumer_count != 3) {
            return error.BundleEvidenceIncomplete;
        }
    }
};

fn runSerial(
    allocator: std.mem.Allocator,
    io: std.Io,
    target: []const u8,
    target_assignment: []const u8,
    options: Options,
) !void {
    const run_wall_start = std.Io.Timestamp.now(io, .awake);
    var paths = try OwnedSerialPaths.init(allocator, io, options.serial_root);
    defer paths.deinit();
    const bundle_assignment = try std.fmt.allocPrint(allocator, "{s}={s}", .{ release_bundle.env_name, paths.bundle_path });
    defer allocator.free(bundle_assignment);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const writer = &stdout_writer.interface;
    try writer.print("distribution all gates target={s}\n", .{target});
    try writeMemoryPolicyEvidence(writer);

    var real_sampler: RealSampler = .{};
    const sampler = real_sampler.interface();
    const preflight = try sampler.sample(allocator, io, paths.scratch_path);
    const policy = headroom_policy.forFilesystem(preflight.total_bytes);
    var tracker = headroom_policy.Tracker.init(preflight.free_bytes);
    try writer.print(
        "summary distribution-all-serial-run schema_version=1 phase=preflight run_id={s} scratch_path={s} bundle_path={s} target={s} mode=serial fresh_real_rows={} local_fail=0\n",
        .{ &paths.run_id, paths.scratch_path, paths.bundle_path, target, options.fresh_real_rows },
    );
    try writer.print(
        "summary distribution-all-headroom-policy schema_version={} filesystem_total_bytes={} reserve_bytes={} projected_peak_bytes={} required_start_bytes={} authority=tools/distribution_headroom_policy.zig local_fail=0\n",
        .{ headroom_policy.schema_version, policy.filesystem_total_bytes, policy.reserve_bytes, policy.projected_peak_bytes, policy.required_start_bytes },
    );
    try writer.print(
        "headroom-preflight free_bytes={} required_start_bytes={} serial_ready={}\n",
        .{ preflight.free_bytes, policy.required_start_bytes, preflight.free_bytes >= policy.required_start_bytes },
    );
    try writer.flush();
    if (preflight.free_bytes < policy.required_start_bytes) return error.InsufficientSerialHeadroom;

    var real_executor: RealExecutor = .{
        .target_assignment = target_assignment,
        .bundle_assignment = bundle_assignment,
    };
    var metrics: RunMetrics = .{};
    var bundle_evidence: BundleEvidence = .{};
    try executeSerialTools(
        allocator,
        io,
        writer,
        target,
        paths.scratch_path,
        options.fresh_real_rows,
        policy,
        &tracker,
        sampler,
        real_executor.interface(),
        realRowsParentOptions(target_assignment, options),
        &metrics,
        &bundle_evidence,
    );
    try bundle_evidence.finish();

    const final_sample = try sampler.sample(allocator, io, paths.scratch_path);
    if (final_sample.total_bytes != policy.filesystem_total_bytes) return error.FilesystemIdentityChanged;
    tracker.observe(final_sample.free_bytes);
    try writeRunSummaries(writer, &metrics, target, options.fresh_real_rows);
    try writer.print(
        "summary distribution-all-serial-bundle schema_version=1 produced={} consumers={} identity={s} executions_cached=false local_fail=0\n",
        .{ bundle_evidence.producer_count, bundle_evidence.consumer_count, &bundle_evidence.identity },
    );
    try writer.print("headroom-final free_bytes={}\n", .{final_sample.free_bytes});
    try writer.print(
        "summary distribution-all-serial schema_version=1 run_id={s} scratch_path={s} bundle_path={s} target={s} mode=serial real_rows_concurrency={} subgates={} wall_ms={} starting_free_bytes={} minimum_observed_free_bytes={} final_free_bytes={} observed_peak_bytes={} reserve_bytes={} required_start_bytes={} local_fail=0\n",
        .{
            &paths.run_id,
            paths.scratch_path,
            paths.bundle_path,
            target,
            options.real_rows_concurrency,
            tools.len,
            elapsedMs(io, run_wall_start),
            tracker.starting_free_bytes,
            tracker.minimum_free_bytes,
            final_sample.free_bytes,
            tracker.observedPeakBytes(),
            policy.reserve_bytes,
            policy.required_start_bytes,
        },
    );
    try writer.writeAll("ok distribution all gates\n");
    try writer.flush();
}

fn realRowsParentOptions(target_assignment: []const u8, options: Options) real_rows_parallel.ParentOptions {
    return .{
        .target_assignment = target_assignment,
        .zig_emitter_path = options.zig_emitter.?,
        .scratch_path = options.real_rows_validation_root.?,
        .export_cache_path = options.real_rows_cache_root.?,
        .cache_mode = if (options.fresh_real_rows) .fresh else .require_hit,
        .concurrency = options.real_rows_concurrency,
    };
}

fn writeMemoryPolicyEvidence(writer: *std.Io.Writer) !void {
    try writer.print(
        "summary distribution-all-real-rows-memory-policy memory_policy={s} local_fail=0\n",
        .{real_rows_parallel.memory_policy_label},
    );
}

fn executeSerialTools(
    allocator: std.mem.Allocator,
    io: std.Io,
    writer: *std.Io.Writer,
    target: []const u8,
    scratch_path: []const u8,
    fresh_real_rows: bool,
    policy: headroom_policy.Policy,
    tracker: *headroom_policy.Tracker,
    sampler: FreeSpaceSampler,
    executor: ToolExecutor,
    real_rows_options: real_rows_parallel.ParentOptions,
    metrics: *RunMetrics,
    bundle_evidence: *BundleEvidence,
) !void {
    var tool_index: usize = 0;
    while (tool_index < tools.len) {
        if (tool_index == 9) {
            var nested_options = real_rows_options;
            nested_options.minimum_free_floor_bytes = @max(nested_options.minimum_free_floor_bytes, policy.reserve_bytes);
            var group = try real_rows_parallel.runGroup(
                allocator,
                io,
                nested_options,
            );
            defer group.deinit(allocator);
            try observeNestedMinimum(policy, tracker, group.evidence.filesystem_total_bytes, group.evidence.minimum_free_bytes);
            for (0..real_rows_parallel.mode_count) |offset| {
                const current_index = tool_index + offset;
                try sampleBeforeTool(allocator, io, writer, scratch_path, current_index, policy, tracker, sampler);
                try writeToolStart(writer, current_index, target, fresh_real_rows);
                const group_completed = group.takeCompleted(offset);
                const completed: CompletedTool = .{ .result = group_completed.result, .duration_ms = group_completed.duration_ms };
                defer common.freeRunResult(allocator, completed.result);
                try recordToolCompletion(writer, current_index, completed, metrics);
            }
            try real_rows_parallel.writeEvidence(writer, &group.evidence);
            tool_index += real_rows_parallel.mode_count;
            continue;
        }
        try sampleBeforeTool(allocator, io, writer, scratch_path, tool_index, policy, tracker, sampler);
        try writeToolStart(writer, tool_index, target, fresh_real_rows);
        const completed = try executor.run(allocator, io, tool_index, fresh_real_rows);
        defer common.freeRunResult(allocator, completed.result);
        try bundle_evidence.observe(tool_index, completed.result.stdout);
        try recordToolCompletion(writer, tool_index, completed, metrics);
        tool_index += 1;
    }
}

fn observeNestedMinimum(policy: headroom_policy.Policy, tracker: *headroom_policy.Tracker, filesystem_total_bytes: u64, minimum_free_bytes: u64) !void {
    if (filesystem_total_bytes != policy.filesystem_total_bytes) return error.FilesystemIdentityChanged;
    tracker.observe(minimum_free_bytes);
    if (minimum_free_bytes < policy.reserve_bytes) return error.SerialHeadroomReserveViolated;
}

test "serial tracker retains a nested transient low even after free space recovers" {
    const policy: headroom_policy.Policy = .{ .filesystem_total_bytes = 1000, .reserve_bytes = 100, .projected_peak_bytes = 200, .required_start_bytes = 300 };
    var tracker = headroom_policy.Tracker.init(900);
    try observeNestedMinimum(policy, &tracker, 1000, 500);
    tracker.observe(850);
    try std.testing.expectEqual(@as(u64, 500), tracker.minimum_free_bytes);
    try std.testing.expectEqual(@as(u64, 400), tracker.observedPeakBytes());
    try std.testing.expectError(error.FilesystemIdentityChanged, observeNestedMinimum(policy, &tracker, 1001, 400));
    try std.testing.expectError(error.SerialHeadroomReserveViolated, observeNestedMinimum(policy, &tracker, 1000, 99));
}

fn sampleBeforeTool(
    allocator: std.mem.Allocator,
    io: std.Io,
    writer: *std.Io.Writer,
    scratch_path: []const u8,
    tool_index: usize,
    policy: headroom_policy.Policy,
    tracker: *headroom_policy.Tracker,
    sampler: FreeSpaceSampler,
) !void {
    const tool = tools[tool_index];
    const sample = try sampler.sample(allocator, io, scratch_path);
    if (sample.total_bytes != policy.filesystem_total_bytes) return error.FilesystemIdentityChanged;
    tracker.observe(sample.free_bytes);
    try writer.print(
        "headroom-before index={} id={s} free_bytes={} reserve_bytes={}\n",
        .{ tool_index + 1, tool.id, sample.free_bytes, policy.reserve_bytes },
    );
    if (sample.free_bytes < policy.reserve_bytes) return error.SerialHeadroomReserveViolated;
}

fn sampleFilesystem(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
) !FilesystemSample {
    const argv = [_][]const u8{ "df", "-B1", "--output=size,avail", path };
    const result = try common.runCapture(allocator, io, &argv, "df serial headroom sample");
    defer common.freeRunResult(allocator, result);
    return parseFilesystemSample(result.stdout);
}

fn parseFilesystemSample(output: []const u8) !FilesystemSample {
    var fields = std.mem.tokenizeAny(u8, output, " \t\r\n");
    _ = fields.next() orelse return error.InvalidFilesystemSample;
    _ = fields.next() orelse return error.InvalidFilesystemSample;
    const total = fields.next() orelse return error.InvalidFilesystemSample;
    const free = fields.next() orelse return error.InvalidFilesystemSample;
    if (fields.next() != null) return error.InvalidFilesystemSample;
    return .{
        .total_bytes = try std.fmt.parseUnsigned(u64, total, 10),
        .free_bytes = try std.fmt.parseUnsigned(u64, free, 10),
    };
}

fn fieldValue(line: []const u8, prefix: []const u8) ?[]const u8 {
    var fields = std.mem.tokenizeScalar(u8, line, ' ');
    while (fields.next()) |field| {
        if (std.mem.startsWith(u8, field, prefix)) return field[prefix.len..];
    }
    return null;
}

fn writeInventory(io: std.Io, target: []const u8) !void {
    var buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &buffer);
    const writer = &stdout_writer.interface;
    try writer.print("distribution-all-command-contract schema_version=1 subgates={} target={s}\n", .{ tools.len, target });
    for (tools, 0..) |tool, tool_index| {
        try writer.print("gate-contract index={} id={s} command=env TARGET={s}", .{ tool_index + 1, tool.id, target });
        if (tool.artifact_contract == .release_source_object_bundle_v1) {
            try writer.writeAll(" ZLLVM_RELEASE_SOURCE_OBJECT_BUNDLE=<runner-owned-bundle>");
        }
        try writer.print(" zig run {s}", .{tool.path});
        if (tool.args.len != 0) {
            try writer.writeAll(" --");
            for (tool.args) |arg| try writer.print(" {s}", .{arg});
        }
        try writer.writeAll("\n");
    }
    try writer.flush();
}

fn recordTool(
    writer: *std.Io.Writer,
    tool_index: usize,
    completed: CompletedTool,
    metrics: *RunMetrics,
    target: []const u8,
    fresh_real_rows: bool,
) !void {
    try writeToolStart(writer, tool_index, target, fresh_real_rows);
    try recordToolCompletion(writer, tool_index, completed, metrics);
}

fn writeToolStart(
    writer: *std.Io.Writer,
    tool_index: usize,
    target: []const u8,
    fresh_real_rows: bool,
) !void {
    const tool = tools[tool_index];
    const cache_mode: []const u8 = if (tool.cache_contract == .air_export_v1)
        (if (fresh_real_rows) "fresh" else "require-hit")
    else
        "default";
    try writer.print(
        "gate-input id={s} tool={s}",
        .{ tool.id, tool.path },
    );
    for (tool.args) |arg| try writer.print(" {s}", .{arg});
    try writer.print(
        " target={s} runner=zig-run input_scope=runner-command cache_contract={s} cache_mode={s} artifact_contract={s}\n",
        .{ target, @tagName(tool.cache_contract), cache_mode, @tagName(tool.artifact_contract) },
    );
    try writer.print("gate-start id={s} tool={s}", .{ tool.id, tool.path });
    for (tool.args) |arg| try writer.print(" {s}", .{arg});
    try writer.writeAll("\n");
    try writer.flush();
}

fn recordToolCompletion(
    writer: *std.Io.Writer,
    tool_index: usize,
    completed: CompletedTool,
    metrics: *RunMetrics,
) !void {
    const tool = tools[tool_index];
    const cache_status = cacheStatus(completed.result.stdout);
    switch (tool.cache_contract) {
        .air_export_v1 => if (cache_status == .none) return error.MissingDeclaredCacheTelemetry,
        .unreported => if (cache_status != .none) return error.UnclassifiedCacheTelemetry,
    }
    metrics.measurements[tool_index] = .{
        .tool_index = tool_index,
        .duration_ms = completed.duration_ms,
        .cache_status = cache_status,
    };
    metrics.total_duration_ms += completed.duration_ms;
    switch (cache_status) {
        .hit => metrics.cache_hits += 1,
        .miss => metrics.cache_misses += 1,
        .mixed => metrics.cache_mixed += 1,
        .none => metrics.cache_none += 1,
    }
    try writer.writeAll(completed.result.stdout);
    try writer.print("gate-end id={s} tool={s}", .{ tool.id, tool.path });
    for (tool.args) |arg| try writer.print(" {s}", .{arg});
    try writer.print(" exit_status=0 duration_ms={} cache_status={s}\n", .{ completed.duration_ms, @tagName(cache_status) });
    try writer.flush();
}

fn writeRunSummaries(
    writer: *std.Io.Writer,
    metrics: *const RunMetrics,
    target: []const u8,
    fresh_real_rows: bool,
) !void {
    var ranked_indices: [tools.len]usize = undefined;
    for (&ranked_indices, 0..) |*index, value| index.* = value;
    sortSlowestFirst(&ranked_indices, &metrics.measurements);
    const slowest_count = @min(@as(usize, 5), tools.len);
    for (ranked_indices[0..slowest_count], 1..) |measurement_index, rank| {
        const measurement = metrics.measurements[measurement_index];
        const tool = tools[measurement.tool_index];
        try writer.print("summary distribution-all-slowest rank={} tool={s}", .{ rank, tool.path });
        for (tool.args) |arg| try writer.print(" {s}", .{arg});
        try writer.print(" duration_ms={} cache_status={s}\n", .{ measurement.duration_ms, @tagName(measurement.cache_status) });
    }
    const reported_cache_contracts = countCacheContracts(.air_export_v1);
    const unreported_cache_contracts = countCacheContracts(.unreported);
    const release_bundle_contracts = countArtifactContracts(.release_source_object_bundle_v1);
    const no_artifact_contracts = countArtifactContracts(.none);
    try writer.print(
        "summary distribution-all-gate-inventory schema_version=1 subgates={} runner=zig-run runner_input_scope=command target={s} reported_cache_contracts={} unreported_cache_contracts={} release_source_object_bundle_contracts={} no_artifact_contracts={} local_fail=0\n",
        .{ tools.len, target, reported_cache_contracts, unreported_cache_contracts, release_bundle_contracts, no_artifact_contracts },
    );
    try writer.print(
        "summary distribution-all-timing subgates={} total_duration_ms={} cache_hit_subgates={} cache_miss_subgates={} cache_mixed_subgates={} cache_none_subgates={} cache_observation_unreported_subgates={} slowest_reported={} fresh_real_rows={} local_fail=0\n",
        .{ tools.len, metrics.total_duration_ms, metrics.cache_hits, metrics.cache_misses, metrics.cache_mixed, metrics.cache_none, unreported_cache_contracts, slowest_count, fresh_real_rows },
    );
}

fn countCacheContracts(contract: CacheContract) usize {
    var count: usize = 0;
    for (tools) |tool| {
        if (tool.cache_contract == contract) count += 1;
    }
    return count;
}

fn countArtifactContracts(contract: ArtifactContract) usize {
    var count: usize = 0;
    for (tools) |tool| {
        if (tool.artifact_contract == contract) count += 1;
    }
    return count;
}

fn runTool(
    allocator: std.mem.Allocator,
    io: std.Io,
    target_assignment: []const u8,
    bundle_assignment: []const u8,
    tool_index: usize,
    fresh_real_rows: bool,
) !CompletedTool {
    const tool = tools[tool_index];
    if (tool.cache_contract == .air_export_v1) return error.RealRowsMustUseSharedRunner;
    var argv: std.ArrayList([]const u8) = .empty;
    defer argv.deinit(allocator);
    try argv.appendSlice(allocator, &.{ "env", target_assignment });
    if (tool.artifact_contract == .release_source_object_bundle_v1) {
        try argv.append(allocator, bundle_assignment);
    }
    try argv.appendSlice(allocator, &.{ "zig", "run", tool.path });
    if (tool.args.len != 0) {
        try argv.append(allocator, "--");
        try argv.appendSlice(allocator, tool.args);
    }
    _ = fresh_real_rows;
    const start = std.Io.Timestamp.now(io, .awake);
    return .{
        .result = try common.runCapture(allocator, io, argv.items, tool.path),
        .duration_ms = elapsedMs(io, start),
    };
}

fn parseArgs(allocator: std.mem.Allocator, init: std.process.Init) !Options {
    var options: Options = .{ .allocator = allocator };
    errdefer options.deinit();
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.skip();
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--fresh-real-rows")) {
            options.fresh_real_rows = true;
        } else if (std.mem.eql(u8, arg, "--serial")) {
            if (options.mode != .parallel) return error.ConflictingExecutionMode;
            options.mode = .serial;
        } else if (std.mem.eql(u8, arg, "--print-inventory")) {
            if (options.mode != .parallel) return error.ConflictingExecutionMode;
            options.mode = .inventory;
        } else if (std.mem.startsWith(u8, arg, "--real-rows-concurrency=")) {
            if (options.real_rows_concurrency_explicit) return error.DuplicateRealRowsConcurrency;
            options.real_rows_concurrency = try std.fmt.parseUnsigned(u8, arg["--real-rows-concurrency=".len..], 10);
            options.real_rows_concurrency_explicit = true;
        } else if (std.mem.startsWith(u8, arg, "--serial-root=")) {
            if (options.serial_root != null) return error.DuplicateSerialRoot;
            const path = arg["--serial-root=".len..];
            if (path.len == 0) return error.InvalidSerialRoot;
            options.serial_root = try allocator.dupe(u8, path);
        } else if (std.mem.startsWith(u8, arg, "--real-rows-validation-root=")) {
            if (options.real_rows_validation_root != null) return error.DuplicateRealRowsValidationRoot;
            const path = arg["--real-rows-validation-root=".len..];
            if (path.len == 0) return error.InvalidRealRowsValidationRoot;
            options.real_rows_validation_root = try allocator.dupe(u8, path);
        } else if (std.mem.startsWith(u8, arg, "--real-rows-cache-root=")) {
            if (options.real_rows_cache_root != null) return error.DuplicateRealRowsCacheRoot;
            const path = arg["--real-rows-cache-root=".len..];
            if (path.len == 0) return error.InvalidRealRowsCacheRoot;
            options.real_rows_cache_root = try allocator.dupe(u8, path);
        } else if (std.mem.startsWith(u8, arg, "--zig-emitter=")) {
            if (options.zig_emitter != null) return error.DuplicateRealRowsZigEmitter;
            const path = arg["--zig-emitter=".len..];
            if (path.len == 0) return error.InvalidRealRowsZigEmitter;
            options.zig_emitter = try allocator.dupe(u8, path);
        } else {
            return error.UnexpectedArgument;
        }
    }
    if (options.serial_root != null and options.mode != .serial) {
        return error.SerialRootRequiresSerialMode;
    }
    if (options.real_rows_concurrency != 1 and options.real_rows_concurrency != 3) {
        return error.InvalidRealRowsConcurrency;
    }
    if (options.mode == .inventory and options.fresh_real_rows) {
        return error.InventoryDoesNotRunGates;
    }
    if (options.mode == .inventory and options.real_rows_concurrency_explicit) return error.InventoryDoesNotRunGates;
    if (options.mode != .inventory and (options.real_rows_validation_root == null or options.real_rows_cache_root == null or options.zig_emitter == null)) {
        return error.RealRowsRootSelectionMissing;
    }
    if (options.mode == .inventory and (options.real_rows_validation_root != null or options.real_rows_cache_root != null or options.zig_emitter != null)) {
        return error.InventoryDoesNotRunGates;
    }
    return options;
}

fn elapsedMs(io: std.Io, start: std.Io.Timestamp) i96 {
    return @divTrunc(start.durationTo(std.Io.Timestamp.now(io, .awake)).nanoseconds, std.time.ns_per_ms);
}

fn cacheStatus(output: []const u8) CacheStatus {
    var saw_hit = false;
    var saw_miss = false;
    var lines = std.mem.splitScalar(u8, output, '\n');
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, "cache") == null) continue;
        if (std.mem.indexOf(u8, line, "status=hit") != null) saw_hit = true;
        if (std.mem.indexOf(u8, line, "status=miss") != null or
            std.mem.indexOf(u8, line, "status=fresh") != null)
        {
            saw_miss = true;
        }
    }
    if (saw_hit and saw_miss) return .mixed;
    if (saw_hit) return .hit;
    if (saw_miss) return .miss;
    return .none;
}

fn sortSlowestFirst(indices: []usize, measurements: []const Measurement) void {
    var index: usize = 1;
    while (index < indices.len) : (index += 1) {
        const candidate = indices[index];
        var insert_at = index;
        while (insert_at > 0 and measurements[indices[insert_at - 1]].duration_ms < measurements[candidate].duration_ms) {
            indices[insert_at] = indices[insert_at - 1];
            insert_at -= 1;
        }
        indices[insert_at] = candidate;
    }
}

const FakeSamplerContext = struct {
    samples: []const FilesystemSample,
    index: usize = 0,

    fn interface(context: *FakeSamplerContext) FreeSpaceSampler {
        return .{ .context = context, .sampleFn = sample };
    }

    fn sample(
        context_ptr: *anyopaque,
        allocator: std.mem.Allocator,
        io: std.Io,
        path: []const u8,
    ) !FilesystemSample {
        _ = allocator;
        _ = io;
        _ = path;
        const context: *FakeSamplerContext = @ptrCast(@alignCast(context_ptr));
        if (context.index >= context.samples.len) return error.FakeSampleExhausted;
        defer context.index += 1;
        return context.samples[context.index];
    }
};

const FakeExecutorContext = struct {
    call_order: [tools.len]usize = undefined,
    call_count: usize = 0,

    fn interface(context: *FakeExecutorContext) ToolExecutor {
        return .{ .context = context, .runFn = run };
    }

    fn run(
        context_ptr: *anyopaque,
        allocator: std.mem.Allocator,
        io: std.Io,
        tool_index: usize,
        fresh_real_rows: bool,
    ) !CompletedTool {
        _ = io;
        _ = fresh_real_rows;
        const context: *FakeExecutorContext = @ptrCast(@alignCast(context_ptr));
        if (context.call_count >= context.call_order.len) return error.FakeCallOverflow;
        context.call_order[context.call_count] = tool_index;
        context.call_count += 1;

        const identity = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
        const stdout = if (std.mem.eql(u8, tools[tool_index].id, "integrated-object-release"))
            try std.fmt.allocPrint(
                allocator,
                "fake bounded subgate {s}\nsummary release-source-object-bundle status=produced rows=100 identity={s} atomic_publication=true local_fail=0\n",
                .{ tools[tool_index].id, identity },
            )
        else if (tools[tool_index].artifact_contract == .release_source_object_bundle_v1)
            try std.fmt.allocPrint(
                allocator,
                "fake bounded subgate {s}\nsummary release-source-object-bundle status=reused consumer=fake rows=100 identity={s} executions_cached=false local_fail=0\n",
                .{ tools[tool_index].id, identity },
            )
        else if (tools[tool_index].cache_contract == .air_export_v1)
            try std.fmt.allocPrint(
                allocator,
                "fake bounded subgate {s}\nair-export-cache status=hit\n",
                .{tools[tool_index].id},
            )
        else
            try std.fmt.allocPrint(allocator, "fake bounded subgate {s}\n", .{tools[tool_index].id});
        errdefer allocator.free(stdout);
        const stderr = try allocator.dupe(u8, "");
        return .{
            .result = .{
                .term = .{ .exited = 0 },
                .stdout = stdout,
                .stderr = stderr,
            },
            .duration_ms = @intCast(tool_index + 1),
        };
    }
};

fn pathExists(io: std.Io, path: []const u8) !bool {
    std.Io.Dir.cwd().access(io, path, .{}) catch |err| switch (err) {
        error.FileNotFound => return false,
        else => return err,
    };
    return true;
}

test "cache status classifies hit miss mixed and absent output" {
    try std.testing.expectEqual(CacheStatus.hit, cacheStatus("air-export-cache status=hit\n"));
    try std.testing.expectEqual(CacheStatus.miss, cacheStatus("air-export-cache status=miss-export\n"));
    try std.testing.expectEqual(CacheStatus.miss, cacheStatus("air-export-cache status=fresh-export\n"));
    try std.testing.expectEqual(CacheStatus.mixed, cacheStatus("cache status=hit\ncache status=miss-export\n"));
    try std.testing.expectEqual(CacheStatus.none, cacheStatus("summary local_fail=0\n"));
}

test "slowest measurements sort by descending duration" {
    const measurements = [_]Measurement{
        .{ .tool_index = 0, .duration_ms = 10, .cache_status = .none },
        .{ .tool_index = 1, .duration_ms = 30, .cache_status = .hit },
        .{ .tool_index = 2, .duration_ms = 20, .cache_status = .miss },
    };
    var indices = [_]usize{ 0, 1, 2 };
    sortSlowestFirst(&indices, &measurements);
    try std.testing.expectEqualSlices(usize, &.{ 1, 2, 0 }, &indices);
}

test "cache contracts distinguish explicit telemetry from unreported gates" {
    try std.testing.expectEqual(@as(usize, 3), countCacheContracts(.air_export_v1));
    try std.testing.expectEqual(@as(usize, 14), countCacheContracts(.unreported));
}

test "artifact contracts identify the producer and three consumers" {
    try std.testing.expectEqual(@as(usize, 4), countArtifactContracts(.release_source_object_bundle_v1));
    try std.testing.expectEqual(@as(usize, 13), countArtifactContracts(.none));
}

test "tracked parallel activation is bounded to real-row gates ten through twelve" {
    try std.testing.expectEqualStrings("integrated-object-preopt", tools[6].id);
    try std.testing.expectEqualSlices([]const u8, &.{"--pipeline=preopt"}, tools[6].args);
    const expected = [_][]const u8{ "real-rows-release-fast", "real-rows-release-safe", "real-rows-release-small" };
    for (expected, 9..) |id, index| {
        try std.testing.expectEqualStrings(id, tools[index].id);
        try std.testing.expectEqual(CacheContract.air_export_v1, tools[index].cache_contract);
    }
    try std.testing.expectEqual(CacheContract.unreported, tools[8].cache_contract);
    try std.testing.expectEqual(CacheContract.unreported, tools[12].cache_contract);
}

test "default and serial cohort paths compose the same explicit shared-runner contract" {
    const allocator = std.testing.allocator;
    var fresh: Options = .{
        .allocator = allocator,
        .fresh_real_rows = true,
        .real_rows_concurrency = 1,
        .zig_emitter = try allocator.dupe(u8, "/test/stage4/zig"),
        .real_rows_validation_root = try allocator.dupe(u8, "local-state/validations/contract"),
        .real_rows_cache_root = try allocator.dupe(u8, "local-state/caches/contract"),
    };
    defer fresh.deinit();
    const fresh_parent = realRowsParentOptions("TARGET=x86_64-unknown-linux-gnu", fresh);
    try std.testing.expectEqual(real_rows_parallel.CacheMode.fresh, fresh_parent.cache_mode);
    try std.testing.expectEqual(@as(u8, 1), fresh_parent.concurrency);
    try std.testing.expectEqualStrings(fresh.real_rows_validation_root.?, fresh_parent.scratch_path);
    try std.testing.expectEqualStrings(fresh.real_rows_cache_root.?, fresh_parent.export_cache_path.?);

    fresh.fresh_real_rows = false;
    fresh.mode = .serial;
    fresh.real_rows_concurrency = 1;
    const hit_parent = realRowsParentOptions("TARGET=x86_64-unknown-linux-gnu", fresh);
    try std.testing.expectEqual(real_rows_parallel.CacheMode.require_hit, hit_parent.cache_mode);
    try std.testing.expectEqual(@as(u8, 1), hit_parent.concurrency);
}

test "distribution all emits one constant os-managed non-gating memory label" {
    var buffer: [512]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buffer);
    try writeMemoryPolicyEvidence(&writer);
    try std.testing.expectEqualStrings(
        "summary distribution-all-real-rows-memory-policy memory_policy=os-managed-non-gating local_fail=0\n",
        writer.buffered(),
    );
}

test "filesystem sample parser reads df size and available bytes" {
    const sample = try parseFilesystemSample(
        "1B-blocks        Avail\n982240026624 115192393728\n",
    );
    try std.testing.expectEqual(@as(u64, 982_240_026_624), sample.total_bytes);
    try std.testing.expectEqual(@as(u64, 115_192_393_728), sample.free_bytes);
}

test "bounded fake serial orchestration uses all 17 authoritative subgates in order" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    const total_bytes = 100 * 1024 * 1024 * 1024;
    var samples: [tools.len]FilesystemSample = undefined;
    for (&samples, 0..) |*sample, index| {
        sample.* = .{
            .total_bytes = total_bytes,
            .free_bytes = 900_000 - @as(u64, @intCast(index * 1_000)),
        };
    }
    var sampler_context: FakeSamplerContext = .{ .samples = &samples };
    var executor_context: FakeExecutorContext = .{};
    var tracker = headroom_policy.Tracker.init(901_000);
    const policy: headroom_policy.Policy = .{
        .filesystem_total_bytes = total_bytes,
        .reserve_bytes = 100_000,
        .projected_peak_bytes = 10_000,
        .required_start_bytes = 110_000,
    };
    var output_buffer: [128 * 1024]u8 = undefined;
    var writer = std.Io.Writer.fixed(&output_buffer);
    var metrics: RunMetrics = .{};
    var bundle_evidence: BundleEvidence = .{};
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();
    const base = try std.fs.path.join(allocator, &.{ ".zig-cache", "tmp", &temp.sub_path });
    defer allocator.free(base);
    const real_rows_validation = try std.fs.path.join(allocator, &.{ base, "validation", "contract" });
    defer allocator.free(real_rows_validation);
    const real_rows_cache = try std.fs.path.join(allocator, &.{ base, "cache", "contract" });
    defer allocator.free(real_rows_cache);
    try std.Io.Dir.cwd().createDirPath(io, real_rows_validation);
    for ([_][]const u8{ "ReleaseFast", "ReleaseSafe", "ReleaseSmall" }) |mode| {
        const export_path = try std.fs.path.join(allocator, &.{ real_rows_cache, mode, "export" });
        defer allocator.free(export_path);
        try std.Io.Dir.cwd().createDirPath(io, export_path);
    }
    var audit: real_rows_parallel.LifecycleAudit = .{};
    var real_rows_test_options: real_rows_parallel.TestOptions = .{
        .worker_fixture = .success,
        .filesystem_sample = .{ .total_bytes = 100 * 1024 * 1024 * 1024, .free_bytes = 90 * 1024 * 1024 * 1024 },
        .failure_evidence_dir = real_rows_validation,
        .audit = &audit,
    };

    try executeSerialTools(
        allocator,
        io,
        &writer,
        "x86_64-unknown-linux-gnu",
        "fake-owned-scratch",
        false,
        policy,
        &tracker,
        sampler_context.interface(),
        executor_context.interface(),
        .{
            .target_assignment = "TARGET=x86_64-unknown-linux-gnu",
            .scratch_path = real_rows_validation,
            .export_cache_path = real_rows_cache,
            .concurrency = 1,
            .test_options = &real_rows_test_options,
        },
        &metrics,
        &bundle_evidence,
    );
    try bundle_evidence.finish();

    try std.testing.expectEqual(@as(usize, tools.len - real_rows_parallel.mode_count), executor_context.call_count);
    try std.testing.expectEqual(@as(usize, tools.len), sampler_context.index);
    const expected_call_order = [_]usize{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 12, 13, 14, 15, 16 };
    try std.testing.expectEqualSlices(usize, &expected_call_order, executor_context.call_order[0..executor_context.call_count]);
    try std.testing.expectEqual(@as(usize, 1), bundle_evidence.producer_count);
    try std.testing.expectEqual(@as(usize, 3), bundle_evidence.consumer_count);
    try std.testing.expectEqual(@as(u64, 17_000), tracker.observedPeakBytes());
    try std.testing.expectEqual(@as(usize, tools.len), std.mem.count(u8, writer.buffered(), "gate-start id="));
    try std.testing.expectEqual(@as(usize, tools.len), std.mem.count(u8, writer.buffered(), "gate-end id="));
    try std.testing.expectEqual(@as(usize, tools.len), std.mem.count(u8, writer.buffered(), "headroom-before index="));
    try std.testing.expect(std.mem.indexOf(u8, writer.buffered(), "schema_version=3 normalization_schema=3") != null);
    try std.testing.expect(std.mem.indexOf(u8, writer.buffered(), "serial-fallback") == null);
}

test "generated serial paths are unique across repeated invocations" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var first = try OwnedSerialPaths.init(allocator, io, null);
    const first_path = try allocator.dupe(u8, first.scratch_path);
    defer allocator.free(first_path);
    first.deinit();

    var second = try OwnedSerialPaths.init(allocator, io, null);
    defer second.deinit();
    try std.testing.expect(!std.mem.eql(u8, first_path, second.scratch_path));
    try std.testing.expect(try pathExists(io, second.scratch_path));
    try std.testing.expect(try pathExists(io, second.bundle_path));
}

test "explicit pre-existing serial path is refused without mutation" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var temp = std.testing.tmpDir(.{});
    defer temp.cleanup();
    const existing = try std.fs.path.join(allocator, &.{ ".zig-cache", "tmp", &temp.sub_path });
    defer allocator.free(existing);
    const sentinel = try std.fs.path.join(allocator, &.{ existing, "sentinel" });
    defer allocator.free(sentinel);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = sentinel, .data = "preserve" });

    try std.testing.expectError(
        error.SerialScratchAlreadyExists,
        OwnedSerialPaths.init(allocator, io, existing),
    );
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, sentinel, allocator, .limited(1024));
    defer allocator.free(contents);
    try std.testing.expectEqualStrings("preserve", contents);
}

test "partial bundle publication is cleaned only with its run-owned scratch" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var paths = try OwnedSerialPaths.init(allocator, io, null);
    const scratch_copy = try allocator.dupe(u8, paths.scratch_path);
    defer allocator.free(scratch_copy);
    const source_object = try std.fs.path.join(allocator, &.{ paths.scratch_path, "partial.o" });
    defer allocator.free(source_object);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = source_object, .data = "partial object" });

    var publisher = try release_bundle.Publisher.init(
        allocator,
        io,
        paths.bundle_path,
        "x86_64-linux-gnu",
    );
    try publisher.publish(.{
        .id = "partial",
        .mode = "ReleaseFast",
        .wrapper = "fake-wrapper",
        .fixture = "fake-fixture",
    }, source_object);
    publisher.deinit();
    try std.testing.expect(try pathExists(io, paths.bundle_path));

    paths.deinit();
    try std.testing.expect(!(try pathExists(io, scratch_copy)));
}

test "published run-owned bundle refuses a second publisher" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var paths = try OwnedSerialPaths.init(allocator, io, null);
    defer paths.deinit();
    const source_object = try std.fs.path.join(allocator, &.{ paths.scratch_path, "complete.o" });
    defer allocator.free(source_object);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = source_object, .data = "complete object" });

    var publisher = try release_bundle.Publisher.init(
        allocator,
        io,
        paths.bundle_path,
        "x86_64-linux-gnu",
    );
    try publisher.publish(.{
        .id = "complete",
        .mode = "ReleaseFast",
        .wrapper = "fake-wrapper",
        .fixture = "fake-fixture",
    }, source_object);
    _ = try publisher.finish(1);
    publisher.deinit();

    try std.testing.expectError(
        error.BundleAlreadyPublished,
        release_bundle.Publisher.init(
            allocator,
            io,
            paths.bundle_path,
            "x86_64-linux-gnu",
        ),
    );
}

test "bundle evidence rejects consumer identity movement" {
    var evidence: BundleEvidence = .{};
    try evidence.observe(
        8,
        "summary release-source-object-bundle status=produced rows=100 identity=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa atomic_publication=true local_fail=0\n",
    );
    try std.testing.expectError(
        error.BundleIdentityMismatch,
        evidence.observe(
            13,
            "summary release-source-object-bundle status=reused consumer=fake rows=100 identity=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb executions_cached=false local_fail=0\n",
        ),
    );
}
