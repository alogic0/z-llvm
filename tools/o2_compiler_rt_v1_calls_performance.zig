const std = @import("std");
const builtin = @import("builtin");

const schema = "o2-compiler-rt-v1-calls-performance-development-v2";
const repository_root = "/home/oleg/prog/z_llvm";
const retained_v1_root = repository_root ++
    "/local-state/validations/o2-calls/compiler-rt-v1/post-dj-ratchet-130-performance-development";
const development_root = repository_root ++
    "/local-state/validations/o2-calls/compiler-rt-v1/post-dj-ratchet-130-performance-v2-development";
const workload_path = repository_root ++ "/tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll";
const retained_a_path = retained_v1_root ++ "/artifacts/a/z_llvm";
const retained_b_path = retained_v1_root ++ "/artifacts/b/z_llvm";
const prepared_a_path = development_root ++ "/artifacts/a/z_llvm";
const prepared_b_path = development_root ++ "/artifacts/b/z_llvm";
const result_directory_relative = "result";
const result_name = "calls-performance-v2.tsv";
const result_temporary_name = ".calls-performance-v2.tsv.tmp";

const workload_bytes: u64 = 1_897_410;
const workload_sha256_hex = "9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1";
const accepted_a_bytes: u64 = 93_862_659;
const accepted_a_sha256_hex = "fea7143f98e6d288dbb18be31d4191b1d3a78f57682e78806eece5a62cfe603c";

const selected_functions: u64 = 443;
const successful_functions: u64 = 264;
const failed_functions: u64 = 179;
const expected_exit_status: u8 = 1;
const capture_max: usize = 4 * 1024 * 1024;
const result_max: usize = 256 * 1024;
const artifact_max: u64 = 1024 * 1024 * 1024;
const idle_windows_per_check: usize = 1;
const warmups_per_artifact: usize = 1;
const pair_count: usize = 6;
const rss_limit_bytes: u64 = 16 * 1024 * 1024;
const absolute_time_allowance_ns: u64 = 100 * std.time.ns_per_ms;

const schedule = [pair_count][2]ArtifactRole{
    .{ .a, .b }, .{ .b, .a }, .{ .a, .b },
    .{ .b, .a }, .{ .a, .b }, .{ .b, .a },
};

const Digest = [32]u8;

const ArtifactRole = enum { a, b };

const Termination = union(enum) {
    exited: u8,
    signal: u32,
    stopped: u32,
    unknown: u32,
};

const FileIdentity = struct {
    bytes: u64,
    mode: u32,
    sha256: Digest,
};

const ReportCounters = struct {
    selected: u64,
    successful: u64,
    failed: u64,
};

const OutputIdentity = struct {
    termination: Termination,
    stdout_bytes: u64,
    stdout_sha256: Digest,
    stderr_bytes: u64,
    stderr_sha256: Digest,
    report_bytes: u64,
    report_sha256: Digest,
    object_bytes: u64,
    object_sha256: Digest,
    semantic_failure_sha256: Digest,
    counters: ReportCounters,
};

const ProcessObservation = struct {
    output: OutputIdentity,
    wall_ns: u64,
    max_rss_bytes: u64,
    voluntary_context_switches: u64,
    involuntary_context_switches: u64,
};

const FrozenArtifact = struct {
    file: FileIdentity,
    output: OutputIdentity,
};

const IdleCounters = struct {
    user: u64,
    nice: u64,
    system: u64,
    idle: u64,
    iowait: u64,
    irq: u64,
    softirq: u64,
    steal: u64,
};

const IdleWindow = struct {
    idle_iowait_delta: u64,
    total_delta: u64,
    pass: bool,
};

const EnvironmentEntry = struct { name: []const u8, value: []const u8 };

const Sample = struct {
    role: ArtifactRole,
    pair_index: usize,
    order_index: usize,
    observation: ProcessObservation,
};

const Pair = struct {
    a: ProcessObservation,
    b: ProcessObservation,
    ratio: f64,
};

const Analysis = struct {
    median_a_ns: u64,
    median_b_ns: u64,
    median_paired_delta_ns: i128,
    time_allowance_ns: u64,
    time_pass: bool,
    median_ratio: f64,
    ratio_min: f64,
    ratio_max: f64,
    ratio_mad: f64,
    max_rss_a: u64,
    max_rss_b: u64,
    rss_pass: bool,
    overall_pass: bool,
};

fn sha256(bytes: []const u8) Digest {
    var digest: Digest = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes, &digest, .{});
    return digest;
}

fn decodeDigest(hex: []const u8) !Digest {
    if (hex.len != 64) return error.IdentityMismatch;
    var result: Digest = undefined;
    for (&result, 0..) |*byte, index| {
        const high = std.fmt.charToDigit(hex[index * 2], 16) catch return error.IdentityMismatch;
        const low = std.fmt.charToDigit(hex[index * 2 + 1], 16) catch return error.IdentityMismatch;
        byte.* = @intCast(high * 16 + low);
    }
    return result;
}

fn validateCanonicalAbsolute(path: []const u8) !void {
    if (!std.fs.path.isAbsolute(path)) return error.RelativePath;
    if (path.len == 0 or std.mem.indexOfScalar(u8, path, 0) != null or
        (path.len > 1 and path[path.len - 1] == '/')) return error.NonCanonicalPath;
    var components = std.mem.splitScalar(u8, path[1..], '/');
    while (components.next()) |component| {
        if (component.len == 0 or std.mem.eql(u8, component, ".") or
            std.mem.eql(u8, component, "..")) return error.NonCanonicalPath;
    }
}

fn isStrictDescendant(path: []const u8, root: []const u8) bool {
    return path.len > root.len and std.mem.startsWith(u8, path, root) and path[root.len] == '/';
}

fn requireStrictDescendant(path: []const u8) !void {
    try validateCanonicalAbsolute(path);
    if (!isStrictDescendant(path, development_root)) return error.PathEscape;
}

fn observeFile(io: std.Io, path: []const u8, maximum: u64, require_executable: bool) !FileIdentity {
    try validateCanonicalAbsolute(path);
    var file = std.Io.Dir.openFileAbsolute(io, path, .{
        .mode = .read_only,
        .follow_symlinks = false,
    }) catch |failure| switch (failure) {
        error.SymLinkLoop => return error.SymlinkRejected,
        else => return failure,
    };
    defer file.close(io);
    const metadata = try file.stat(io);
    if (metadata.kind != .file or metadata.size == 0 or metadata.size > maximum)
        return error.IdentityMismatch;
    const mode: u32 = @intCast(metadata.permissions.toMode() & 0o7777);
    if (require_executable and mode & 0o111 == 0) return error.NotExecutable;
    var canonical: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const canonical_len = try std.Io.Dir.realPathFileAbsolute(io, path, &canonical);
    if (!std.mem.eql(u8, path, canonical[0..canonical_len])) return error.NonCanonicalPath;
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    var buffer: [64 * 1024]u8 = undefined;
    var offset: u64 = 0;
    while (true) {
        const amount = try file.readPositional(io, &.{&buffer}, offset);
        if (amount == 0) break;
        hasher.update(buffer[0..amount]);
        offset = std.math.add(u64, offset, amount) catch return error.ArithmeticOverflow;
        if (offset > maximum) return error.OutputOverflow;
    }
    if (offset != metadata.size) return error.IdentityMismatch;
    var digest: Digest = undefined;
    hasher.final(&digest);
    return .{ .bytes = offset, .mode = mode, .sha256 = digest };
}

fn requireIdentity(actual: FileIdentity, bytes: u64, digest_hex: []const u8) !void {
    if (actual.bytes != bytes or !std.mem.eql(u8, &actual.sha256, &(try decodeDigest(digest_hex))))
        return error.IdentityMismatch;
}

fn requireFileIdentityEqual(expected: FileIdentity, actual: FileIdentity) !void {
    if (expected.bytes != actual.bytes or expected.mode != actual.mode or
        !std.mem.eql(u8, &expected.sha256, &actual.sha256)) return error.IdentityMismatch;
}

fn lowestCpu(set: std.os.linux.cpu_set_t) !usize {
    for (0..std.os.linux.CPU_SETSIZE * 8) |cpu| {
        const bits = @bitSizeOf(usize);
        if (set[cpu / bits] & (@as(usize, 1) << @intCast(cpu % bits)) != 0) return cpu;
    }
    return error.EmptyAffinity;
}

fn requireSingleCpu(set: std.os.linux.cpu_set_t, expected: usize) !void {
    if (try lowestCpu(set) != expected or std.os.linux.CPU_COUNT(set) != 1)
        return error.AffinityPinFailed;
}

fn selectAndPinLowestCpu() !usize {
    if (builtin.os.tag != .linux) return error.UnsupportedPlatform;
    const inherited = try std.posix.sched_getaffinity(0);
    const cpu = try lowestCpu(inherited);
    var selected: [std.os.linux.CPU_SETSIZE / @sizeOf(usize)]usize = @splat(0);
    const bits = @bitSizeOf(usize);
    selected[cpu / bits] |= @as(usize, 1) << @intCast(cpu % bits);
    std.os.linux.sched_setaffinity(0, &selected) catch return error.AffinityPinFailed;
    const confirmed = try std.posix.sched_getaffinity(0);
    try requireSingleCpu(confirmed, cpu);
    return cpu;
}

fn parseCpuLine(bytes: []const u8, selected_cpu: usize) !IdleCounters {
    var label_buffer: [32]u8 = undefined;
    const label = try std.fmt.bufPrint(&label_buffer, "cpu{d}", .{selected_cpu});
    var lines = std.mem.splitScalar(u8, bytes, '\n');
    while (lines.next()) |line| {
        var fields = std.mem.tokenizeScalar(u8, line, ' ');
        const first = fields.next() orelse continue;
        if (!std.mem.eql(u8, first, label)) continue;
        var values: [8]u64 = undefined;
        for (&values) |*value| {
            const token = fields.next() orelse return error.MalformedProcStat;
            value.* = std.fmt.parseInt(u64, token, 10) catch return error.MalformedProcStat;
        }
        return .{
            .user = values[0],
            .nice = values[1],
            .system = values[2],
            .idle = values[3],
            .iowait = values[4],
            .irq = values[5],
            .softirq = values[6],
            .steal = values[7],
        };
    }
    return error.CpuStatMissing;
}

fn counterTotal(value: IdleCounters) !u64 {
    var total: u64 = 0;
    inline for (@typeInfo(IdleCounters).@"struct".field_names) |field_name| {
        total = std.math.add(u64, total, @field(value, field_name)) catch return error.ArithmeticOverflow;
    }
    return total;
}

fn idleWindow(before: IdleCounters, after: IdleCounters) !IdleWindow {
    const before_total = try counterTotal(before);
    const after_total = try counterTotal(after);
    if (after_total <= before_total or after.idle < before.idle or after.iowait < before.iowait)
        return error.CounterReset;
    const total_delta = after_total - before_total;
    const idle_delta = after.idle - before.idle;
    const iowait_delta = after.iowait - before.iowait;
    const idle_iowait_delta = std.math.add(u64, idle_delta, iowait_delta) catch
        return error.ArithmeticOverflow;
    const lhs = std.math.mul(u64, idle_iowait_delta, 100) catch return error.ArithmeticOverflow;
    const rhs = std.math.mul(u64, total_delta, 95) catch return error.ArithmeticOverflow;
    return .{ .idle_iowait_delta = idle_iowait_delta, .total_delta = total_delta, .pass = lhs >= rhs };
}

fn readProcStat(allocator: std.mem.Allocator, io: std.Io, cpu: usize) !IdleCounters {
    var file = try std.Io.Dir.openFileAbsolute(io, "/proc/stat", .{
        .mode = .read_only,
        .follow_symlinks = false,
    });
    defer file.close(io);
    const metadata = try file.stat(io);
    if (metadata.kind != .file or metadata.size > 1024 * 1024) return error.MalformedProcStat;
    const capacity: usize = if (metadata.size == 0) 64 * 1024 else @intCast(metadata.size);
    const bytes = try allocator.alloc(u8, capacity);
    defer allocator.free(bytes);
    const amount = try file.readPositionalAll(io, bytes, 0);
    if (amount == bytes.len and metadata.size == 0) return error.MalformedProcStat;
    return parseCpuLine(bytes[0..amount], cpu);
}

fn performIdleCheck(
    allocator: std.mem.Allocator,
    io: std.Io,
    cpu: usize,
    records: *std.array_list.Managed(IdleWindow),
) !void {
    var prior = try readProcStat(allocator, io, cpu);
    for (0..idle_windows_per_check) |_| {
        try std.Io.sleep(io, .fromSeconds(1), .awake);
        const next = try readProcStat(allocator, io, cpu);
        const window = try idleWindow(prior, next);
        try records.append(window);
        prior = next;
    }
}

fn rssKiBToBytes(value: isize) !u64 {
    if (value < 0) return error.InvalidResourceUsage;
    return std.math.mul(u64, @intCast(value), 1024) catch return error.ArithmeticOverflow;
}

fn contextSwitches(value: isize) !u64 {
    if (value < 0) return error.InvalidResourceUsage;
    return @intCast(value);
}

fn processTermination(term: std.process.Child.Term) Termination {
    return switch (term) {
        .exited => |status| .{ .exited = status },
        .signal => |signal| .{ .signal = @intFromEnum(signal) },
        .stopped => |signal| .{ .stopped = @intFromEnum(signal) },
        .unknown => |status| .{ .unknown = status },
    };
}

fn requireExpectedTermination(term: Termination) !void {
    switch (term) {
        .exited => |status| if (status != expected_exit_status) return error.ChildFailed,
        else => return error.ChildFailed,
    }
}

fn parseCanonicalU64(text: []const u8) !u64 {
    if (text.len == 0 or (text.len > 1 and text[0] == '0')) return error.MalformedReport;
    for (text) |byte| if (!std.ascii.isDigit(byte)) return error.MalformedReport;
    return std.fmt.parseInt(u64, text, 10) catch return error.MalformedReport;
}

fn parseReport(stderr: []const u8) !ReportCounters {
    var summary_count: usize = 0;
    var parsed: ?ReportCounters = null;
    var lines = std.mem.splitScalar(u8, stderr, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "summary zllvm-codegen-report-all ")) continue;
        summary_count += 1;
        var selected: ?u64 = null;
        var successful: ?u64 = null;
        var failed: ?u64 = null;
        var local_fail = false;
        var fields = std.mem.tokenizeScalar(u8, line, ' ');
        _ = fields.next();
        _ = fields.next();
        while (fields.next()) |field| {
            const split = std.mem.indexOfScalar(u8, field, '=') orelse continue;
            const name = field[0..split];
            const value = field[split + 1 ..];
            if (std.mem.eql(u8, name, "selected_functions")) selected = try parseCanonicalU64(value) else if (std.mem.eql(u8, name, "emitted_functions")) successful = try parseCanonicalU64(value) else if (std.mem.eql(u8, name, "failed_functions")) failed = try parseCanonicalU64(value) else if (std.mem.eql(u8, name, "local_fail")) local_fail = std.mem.eql(u8, value, "1");
        }
        if (!local_fail or selected == null or successful == null or failed == null)
            return error.MalformedReport;
        parsed = .{ .selected = selected.?, .successful = successful.?, .failed = failed.? };
    }
    if (summary_count != 1) return error.MalformedReport;
    const counters = parsed.?;
    if (counters.selected != selected_functions or counters.successful != successful_functions or
        counters.failed != failed_functions or counters.selected != counters.successful + counters.failed)
        return error.CounterMismatch;
    return counters;
}

fn semanticFailureDigest(stderr: []const u8, counters: ReportCounters) Digest {
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    var lines = std.mem.splitScalar(u8, stderr, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "zllvm-codegen-failure ")) continue;
        var encoded_length: [8]u8 = undefined;
        std.mem.writeInt(u64, &encoded_length, line.len, .little);
        hasher.update(&encoded_length);
        hasher.update(line);
    }
    var encoded: [24]u8 = undefined;
    std.mem.writeInt(u64, encoded[0..8], counters.selected, .little);
    std.mem.writeInt(u64, encoded[8..16], counters.successful, .little);
    std.mem.writeInt(u64, encoded[16..24], counters.failed, .little);
    hasher.update(&encoded);
    var result: Digest = undefined;
    hasher.final(&result);
    return result;
}

fn outputIdentity(term: Termination, stdout: []const u8, stderr: []const u8) !OutputIdentity {
    try requireExpectedTermination(term);
    if (stdout.len > capture_max or stderr.len > capture_max) return error.OutputOverflow;
    const counters = try parseReport(stderr);
    return .{
        .termination = term,
        .stdout_bytes = stdout.len,
        .stdout_sha256 = sha256(stdout),
        .stderr_bytes = stderr.len,
        .stderr_sha256 = sha256(stderr),
        .report_bytes = stderr.len,
        .report_sha256 = sha256(stderr),
        .object_bytes = stdout.len,
        .object_sha256 = sha256(stdout),
        .semantic_failure_sha256 = semanticFailureDigest(stderr, counters),
        .counters = counters,
    };
}

fn requireArtifactOutput(expected: OutputIdentity, actual: OutputIdentity) !void {
    if (!std.meta.eql(expected.termination, actual.termination) or
        expected.stdout_bytes != actual.stdout_bytes or
        !std.mem.eql(u8, &expected.stdout_sha256, &actual.stdout_sha256) or
        expected.object_bytes != actual.object_bytes or
        !std.mem.eql(u8, &expected.object_sha256, &actual.object_sha256) or
        !std.meta.eql(expected.counters, actual.counters) or
        !std.mem.eql(u8, &expected.semantic_failure_sha256, &actual.semantic_failure_sha256))
        return error.OutputIdentityMismatch;
}

fn requireSemanticAgreement(a: OutputIdentity, b: OutputIdentity) !void {
    if (!std.meta.eql(a.termination, b.termination) or !std.meta.eql(a.counters, b.counters) or
        !std.mem.eql(u8, &a.semantic_failure_sha256, &b.semantic_failure_sha256))
        return error.SemanticMismatch;
}

fn durationNanoseconds(start: std.Io.Clock.Timestamp, finish: std.Io.Clock.Timestamp) !u64 {
    const raw = start.durationTo(finish).raw.nanoseconds;
    if (raw <= 0 or raw > std.math.maxInt(u64)) return error.InvalidMonotonicTime;
    return @intCast(raw);
}

fn fixedEnvironmentEntries(
    home: []const u8,
    temporary: []const u8,
    xdg: []const u8,
    local_cache: []const u8,
    global_cache: []const u8,
) [8]EnvironmentEntry {
    return .{
        .{ .name = "LC_ALL", .value = "C" },
        .{ .name = "LANG", .value = "C" },
        .{ .name = "TZ", .value = "UTC" },
        .{ .name = "HOME", .value = home },
        .{ .name = "TMPDIR", .value = temporary },
        .{ .name = "XDG_CACHE_HOME", .value = xdg },
        .{ .name = "ZIG_LOCAL_CACHE_DIR", .value = local_cache },
        .{ .name = "ZIG_GLOBAL_CACHE_DIR", .value = global_cache },
    };
}

fn validateFixedEnvironment(sample_root: []const u8, entries: [8]EnvironmentEntry) !void {
    try requireStrictDescendant(sample_root);
    const expected_names = [_][]const u8{
        "LC_ALL", "LANG", "TZ", "HOME", "TMPDIR", "XDG_CACHE_HOME", "ZIG_LOCAL_CACHE_DIR", "ZIG_GLOBAL_CACHE_DIR",
    };
    for (entries, expected_names, 0..) |entry, expected_name, index| {
        if (!std.mem.eql(u8, entry.name, expected_name) or
            std.mem.indexOfScalar(u8, entry.name, 0) != null or
            std.mem.indexOfScalar(u8, entry.value, 0) != null)
            return error.EnvironmentDrift;
        if (index < 3) {
            const expected_value = [_][]const u8{ "C", "C", "UTC" };
            if (!std.mem.eql(u8, entry.value, expected_value[index])) return error.EnvironmentDrift;
        } else if (!isStrictDescendant(entry.value, sample_root)) return error.EnvironmentDrift;
    }
}

fn runCaptured(
    allocator: std.mem.Allocator,
    io: std.Io,
    executable: []const u8,
    sample_root: []const u8,
) !ProcessObservation {
    try validateCanonicalAbsolute(executable);
    try requireStrictDescendant(sample_root);
    const home = try std.fs.path.join(allocator, &.{ sample_root, "home" });
    const temporary = try std.fs.path.join(allocator, &.{ sample_root, "tmp" });
    const xdg = try std.fs.path.join(allocator, &.{ sample_root, "xdg-cache" });
    const local_cache = try std.fs.path.join(allocator, &.{ sample_root, "zig-local" });
    const global_cache = try std.fs.path.join(allocator, &.{ sample_root, "zig-global" });
    const environment_entries = fixedEnvironmentEntries(home, temporary, xdg, local_cache, global_cache);
    try validateFixedEnvironment(sample_root, environment_entries);
    var environment = std.process.Environ.Map.init(allocator);
    defer environment.deinit();
    for (environment_entries) |entry| try environment.put(entry.name, entry.value);
    const argv = [_][]const u8{
        executable,
        "--emit=obj",
        "--generic-cfg-selector",
        "--report-all-codegen-failures",
        "--target=x86_64-linux",
        "--input-limit=67108864",
        workload_path,
    };
    const start = std.Io.Clock.Timestamp.now(io, .awake);
    var child = std.process.spawn(io, .{
        .argv = &argv,
        .cwd = .{ .path = repository_root },
        .environ_map = &environment,
        .stdin = .ignore,
        .stdout = .pipe,
        .stderr = .pipe,
        .request_resource_usage_statistics = true,
    }) catch return error.SpawnFailed;
    defer child.kill(io);
    var reader_buffer: std.Io.File.MultiReader.Buffer(2) = undefined;
    var reader: std.Io.File.MultiReader = undefined;
    reader.init(allocator, io, reader_buffer.toStreams(), &.{ child.stdout.?, child.stderr.? });
    defer reader.deinit();
    const stdout_reader = reader.reader(0);
    const stderr_reader = reader.reader(1);
    while (reader.fill(64, .none)) |_| {
        if (stdout_reader.buffered().len > capture_max or stderr_reader.buffered().len > capture_max)
            return error.OutputOverflow;
    } else |failure| switch (failure) {
        error.EndOfStream => {},
        else => return failure,
    }
    try reader.checkAnyError();
    const term = child.wait(io) catch return error.WaitFailed;
    const finish = std.Io.Clock.Timestamp.now(io, .awake);
    const stdout = try reader.toOwnedSlice(0);
    defer allocator.free(stdout);
    const stderr = try reader.toOwnedSlice(1);
    defer allocator.free(stderr);
    const usage = child.resource_usage_statistics.rusage orelse return error.ResourceUsageUnavailable;
    const involuntary = try contextSwitches(usage.nivcsw);
    return .{
        .output = try outputIdentity(processTermination(term), stdout, stderr),
        .wall_ns = try durationNanoseconds(start, finish),
        .max_rss_bytes = try rssKiBToBytes(usage.maxrss),
        .voluntary_context_switches = try contextSwitches(usage.nvcsw),
        .involuntary_context_switches = involuntary,
    };
}

fn openRoot(io: std.Io) !std.Io.Dir {
    try validateCanonicalAbsolute(development_root);
    var canonical: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const length = try std.Io.Dir.realPathFileAbsolute(io, development_root, &canonical);
    if (!std.mem.eql(u8, development_root, canonical[0..length])) return error.NonCanonicalPath;
    return std.Io.Dir.openDirAbsolute(io, development_root, .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
}

fn createSampleDirectory(allocator: std.mem.Allocator, root: std.Io.Dir, io: std.Io, name: []const u8) ![]u8 {
    const relative = try std.fmt.allocPrint(allocator, "samples/{s}", .{name});
    try createFreshDirectory(root, io, relative);
    var directory = try root.openDir(io, relative, .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer directory.close(io);
    inline for (.{ "home", "tmp", "xdg-cache", "zig-local", "zig-global" }) |child|
        try directory.createDir(io, child, .default_dir);
    return std.fs.path.join(allocator, &.{ development_root, relative });
}

fn createFreshDirectory(directory: std.Io.Dir, io: std.Io, relative: []const u8) !void {
    directory.createDir(io, relative, .default_dir) catch |failure| switch (failure) {
        error.PathAlreadyExists => return error.SampleCollision,
        else => return failure,
    };
}

fn requireSampleShape(samples: []const Sample) !void {
    if (samples.len != pair_count * 2) return error.SampleCountDrift;
    for (schedule, 0..) |roles, pair_index| {
        for (roles, 0..) |role, order_index| {
            const sample = samples[pair_index * 2 + order_index];
            if (sample.role != role or sample.pair_index != pair_index or sample.order_index != order_index)
                return error.ScheduleDrift;
        }
    }
}

fn syncOwnedDirectory(directory: std.Io.Dir, io: std.Io) !void {
    const owned = try directory.openFile(io, ".", .{
        .mode = .read_only,
        .allow_directory = true,
        .path_only = false,
        .follow_symlinks = false,
        .resolve_beneath = true,
    });
    defer owned.close(io);
    try owned.sync(io);
}

fn prepareArtifacts(io: std.Io) !void {
    const a_source_identity = try observeFile(io, retained_a_path, artifact_max, true);
    try requireIdentity(a_source_identity, accepted_a_bytes, accepted_a_sha256_hex);
    const b_source_identity = try observeFile(io, retained_b_path, artifact_max, true);
    std.Io.Dir.createDirAbsolute(io, development_root, .default_dir) catch |failure| switch (failure) {
        error.PathAlreadyExists => return error.ResultCollision,
        else => return failure,
    };
    var root = try openRoot(io);
    defer root.close(io);
    try root.createDirPath(io, "artifacts/a");
    try root.createDirPath(io, "artifacts/b");
    try std.Io.Dir.copyFileAbsolute(retained_a_path, prepared_a_path, io, .{
        .permissions = std.Io.File.Permissions.fromMode(@intCast(a_source_identity.mode)),
        .replace = false,
    });
    try std.Io.Dir.copyFileAbsolute(retained_b_path, prepared_b_path, io, .{
        .permissions = std.Io.File.Permissions.fromMode(@intCast(b_source_identity.mode)),
        .replace = false,
    });
    const a = try observeFile(io, prepared_a_path, artifact_max, true);
    const b = try observeFile(io, prepared_b_path, artifact_max, true);
    try requireIdentity(a, accepted_a_bytes, accepted_a_sha256_hex);
    try requireFileIdentityEqual(a_source_identity, a);
    try requireFileIdentityEqual(b_source_identity, b);
    if (a.mode != 0o555 or b.mode != 0o555) return error.ArtifactNotImmutable;
    try syncOwnedDirectory(root, io);
}

fn medianU64(values: [pair_count]u64) !u64 {
    var sorted = values;
    std.mem.sort(u64, &sorted, {}, std.sort.asc(u64));
    const sum = std.math.add(u64, sorted[2], sorted[3]) catch return error.ArithmeticOverflow;
    return sum / 2;
}

fn medianF64(values: [pair_count]f64) !f64 {
    var sorted = values;
    for (&sorted) |value| if (!std.math.isFinite(value) or value <= 0) return error.InvalidStatistic;
    std.mem.sort(f64, &sorted, {}, std.sort.asc(f64));
    return (sorted[2] + sorted[3]) / 2.0;
}

fn analyzePairs(pairs: [pair_count]Pair) !Analysis {
    var a_times: [pair_count]u64 = undefined;
    var b_times: [pair_count]u64 = undefined;
    var ratios: [pair_count]f64 = undefined;
    var deltas: [pair_count]i128 = undefined;
    var max_a: u64 = 0;
    var max_b: u64 = 0;
    for (pairs, 0..) |pair, index| {
        a_times[index] = pair.a.wall_ns;
        b_times[index] = pair.b.wall_ns;
        ratios[index] = pair.ratio;
        deltas[index] = @as(i128, pair.b.wall_ns) - @as(i128, pair.a.wall_ns);
        max_a = @max(max_a, pair.a.max_rss_bytes);
        max_b = @max(max_b, pair.b.max_rss_bytes);
    }
    const median_a = try medianU64(a_times);
    const median_b = try medianU64(b_times);
    const five_percent = median_a / 20;
    const allowance = @max(five_percent, absolute_time_allowance_ns);
    std.mem.sort(i128, &deltas, {}, std.sort.asc(i128));
    const delta_sum = std.math.add(i128, deltas[2], deltas[3]) catch return error.ArithmeticOverflow;
    const median_delta = @divTrunc(delta_sum, 2);
    const time_pass = median_delta <= @as(i128, allowance);
    var sorted_ratios = ratios;
    std.mem.sort(f64, &sorted_ratios, {}, std.sort.asc(f64));
    const ratio_median = try medianF64(ratios);
    var deviations: [pair_count]f64 = undefined;
    for (ratios, 0..) |ratio, index| deviations[index] = @abs(ratio - ratio_median);
    const mad = try medianF64AllowZero(deviations);
    const rss_limit = std.math.add(u64, max_a, rss_limit_bytes) catch return error.ArithmeticOverflow;
    const rss_pass = max_b <= rss_limit;
    return .{
        .median_a_ns = median_a,
        .median_b_ns = median_b,
        .median_paired_delta_ns = median_delta,
        .time_allowance_ns = allowance,
        .time_pass = time_pass,
        .median_ratio = ratio_median,
        .ratio_min = sorted_ratios[0],
        .ratio_max = sorted_ratios[pair_count - 1],
        .ratio_mad = mad,
        .max_rss_a = max_a,
        .max_rss_b = max_b,
        .rss_pass = rss_pass,
        .overall_pass = time_pass and rss_pass,
    };
}

fn medianF64AllowZero(values: [pair_count]f64) !f64 {
    var sorted = values;
    for (&sorted) |value| if (!std.math.isFinite(value) or value < 0) return error.InvalidStatistic;
    std.mem.sort(f64, &sorted, {}, std.sort.asc(f64));
    return (sorted[2] + sorted[3]) / 2.0;
}

fn verifySchedule(actual: [pair_count][2]ArtifactRole) !void {
    if (!std.meta.eql(actual, schedule)) return error.ScheduleDrift;
}

fn publishResult(allocator: std.mem.Allocator, directory: std.Io.Dir, io: std.Io, encoded: []const u8) !FileIdentity {
    if (encoded.len == 0 or encoded.len > result_max) return error.OutputOverflow;
    var temporary = directory.createFile(io, result_temporary_name, .{
        .read = false,
        .truncate = false,
        .exclusive = true,
        .resolve_beneath = true,
    }) catch |failure| switch (failure) {
        error.PathAlreadyExists => return error.ResultCollision,
        else => return failure,
    };
    var temporary_open = true;
    defer if (temporary_open) temporary.close(io);
    try temporary.writeStreamingAll(io, encoded);
    try temporary.sync(io);
    temporary.close(io);
    temporary_open = false;
    directory.renamePreserve(result_temporary_name, directory, result_name, io) catch |failure| switch (failure) {
        error.PathAlreadyExists => return error.ResultCollision,
        else => return failure,
    };
    try syncOwnedDirectory(directory, io);
    const final = try directory.openFile(io, result_name, .{
        .mode = .read_only,
        .follow_symlinks = false,
        .resolve_beneath = true,
    });
    defer final.close(io);
    const readback = try allocator.alloc(u8, encoded.len);
    defer allocator.free(readback);
    if (try final.readPositionalAll(io, readback, 0) != encoded.len or !std.mem.eql(u8, encoded, readback))
        return error.ResultReadbackMismatch;
    var trailing: [1]u8 = undefined;
    if (try final.readPositionalAll(io, &trailing, encoded.len) != 0) return error.ResultReadbackMismatch;
    const stat = try final.stat(io);
    return .{ .bytes = stat.size, .mode = @intCast(stat.permissions.toMode() & 0o7777), .sha256 = sha256(encoded) };
}

fn appendIdentity(writer: *std.Io.Writer, label: []const u8, identity: FileIdentity) !void {
    const digest = std.fmt.bytesToHex(identity.sha256, .lower);
    try writer.print("{s}\t{d}\t{o}\t{s}\n", .{ label, identity.bytes, identity.mode, &digest });
}

fn appendOutput(writer: *std.Io.Writer, label: []const u8, output: OutputIdentity) !void {
    const stdout_digest = std.fmt.bytesToHex(output.stdout_sha256, .lower);
    const stderr_digest = std.fmt.bytesToHex(output.stderr_sha256, .lower);
    const object_digest = std.fmt.bytesToHex(output.object_sha256, .lower);
    const report_digest = std.fmt.bytesToHex(output.report_sha256, .lower);
    try writer.print(
        "{s}\t{d}\t{s}\t{d}\t{s}\t{d}\t{s}\t{d}\t{s}\t{d}\t{d}\t{d}\n",
        .{ label, output.stdout_bytes, &stdout_digest, output.stderr_bytes, &stderr_digest, output.object_bytes, &object_digest, output.report_bytes, &report_digest, output.counters.selected, output.counters.successful, output.counters.failed },
    );
}

fn encodeResult(
    allocator: std.mem.Allocator,
    cpu: usize,
    workload: FileIdentity,
    a: FrozenArtifact,
    b: FrozenArtifact,
    idle: []const IdleWindow,
    samples: [pair_count * 2]Sample,
    pairs: [pair_count]Pair,
    analysis: Analysis,
) ![]u8 {
    var output: std.Io.Writer.Allocating = .init(allocator);
    errdefer output.deinit();
    try output.writer.print("schema\t{s}\nselected_cpu\t{d}\n", .{ schema, cpu });
    try appendIdentity(&output.writer, "workload", workload);
    try appendIdentity(&output.writer, "artifact_a", a.file);
    try appendIdentity(&output.writer, "artifact_b", b.file);
    try appendOutput(&output.writer, "frozen_a", a.output);
    try appendOutput(&output.writer, "frozen_b", b.output);
    try output.writer.print("idle_windows\t{d}\n", .{idle.len});
    for (idle, 0..) |window, index| try output.writer.print(
        "idle\t{d}\t{d}\t{d}\t{}\n",
        .{ index + 1, window.idle_iowait_delta, window.total_delta, window.pass },
    );
    for (samples) |sample| try output.writer.print(
        "sample\t{d}\t{d}\t{s}\t{d}\t{d}\t{d}\t{d}\n",
        .{ sample.pair_index + 1, sample.order_index + 1, @tagName(sample.role), sample.observation.wall_ns, sample.observation.max_rss_bytes, sample.observation.voluntary_context_switches, sample.observation.involuntary_context_switches },
    );
    for (pairs, 0..) |pair, index| try output.writer.print(
        "pair\t{d}\t{d}\t{d}\t{d}\n",
        .{ index + 1, pair.a.wall_ns, pair.b.wall_ns, pair.ratio },
    );
    try output.writer.print(
        "analysis\t{d}\t{d}\t{d}\t{d}\t{}\t{d}\t{d}\t{d}\t{d}\t{d}\t{d}\t{}\t{}\ncompletion\tcomplete\n",
        .{ analysis.median_a_ns, analysis.median_b_ns, analysis.median_paired_delta_ns, analysis.time_allowance_ns, analysis.time_pass, analysis.median_ratio, analysis.ratio_min, analysis.ratio_max, analysis.ratio_mad, analysis.max_rss_a, analysis.max_rss_b, analysis.rss_pass, analysis.overall_pass },
    );
    if (output.writer.end > result_max) {
        output.deinit();
        return error.OutputOverflow;
    }
    return output.toOwnedSlice();
}

fn freezeArtifact(correctness: ProcessObservation, file: FileIdentity) FrozenArtifact {
    return .{ .file = file, .output = correctness.output };
}

fn verifySample(frozen: FrozenArtifact, observation: ProcessObservation) !void {
    try requireArtifactOutput(frozen.output, observation.output);
}

fn runBenchmark(init: std.process.Init, a_path: []const u8, b_path: []const u8) !void {
    if (!std.mem.eql(u8, a_path, prepared_a_path) or !std.mem.eql(u8, b_path, prepared_b_path))
        return error.PathEscape;
    const cpu = try selectAndPinLowestCpu();
    var root = try openRoot(init.io);
    defer root.close(init.io);
    root.createDir(init.io, "samples", .default_dir) catch |failure| switch (failure) {
        error.PathAlreadyExists => return error.SampleCollision,
        else => return failure,
    };
    root.createDir(init.io, result_directory_relative, .default_dir) catch |failure| switch (failure) {
        error.PathAlreadyExists => return error.ResultCollision,
        else => return failure,
    };
    const workload = try observeFile(init.io, workload_path, 64 * 1024 * 1024, false);
    try requireIdentity(workload, workload_bytes, workload_sha256_hex);
    const a_file = try observeFile(init.io, a_path, artifact_max, true);
    const b_file = try observeFile(init.io, b_path, artifact_max, true);
    try requireIdentity(a_file, accepted_a_bytes, accepted_a_sha256_hex);
    if (a_file.mode != 0o555 or b_file.mode != 0o555) return error.ArtifactNotImmutable;
    var idle_records = std.array_list.Managed(IdleWindow).init(init.gpa);
    defer idle_records.deinit();

    try performIdleCheck(init.gpa, init.io, cpu, &idle_records);
    const ca1_dir = try createSampleDirectory(init.gpa, root, init.io, "correctness-a");
    const ca1 = try runCaptured(init.gpa, init.io, a_path, ca1_dir);
    const cb1_dir = try createSampleDirectory(init.gpa, root, init.io, "correctness-b");
    const cb1 = try runCaptured(init.gpa, init.io, b_path, cb1_dir);
    const frozen_a = freezeArtifact(ca1, a_file);
    const frozen_b = freezeArtifact(cb1, b_file);
    try requireSemanticAgreement(frozen_a.output, frozen_b.output);

    const warmup_roles = [_]ArtifactRole{ .a, .b };
    for (warmup_roles, 0..) |role, index| {
        var name_buffer: [64]u8 = undefined;
        const name = try std.fmt.bufPrint(&name_buffer, "warmup-{s}-{d}", .{ @tagName(role), index + 1 });
        const directory = try createSampleDirectory(init.gpa, root, init.io, name);
        const observation = try runCaptured(init.gpa, init.io, if (role == .a) a_path else b_path, directory);
        try verifySample(if (role == .a) frozen_a else frozen_b, observation);
    }

    var samples: [pair_count * 2]Sample = undefined;
    var pairs: [pair_count]Pair = undefined;
    for (schedule, 0..) |roles, pair_index| {
        try performIdleCheck(init.gpa, init.io, cpu, &idle_records);
        var pair_a: ?ProcessObservation = null;
        var pair_b: ?ProcessObservation = null;
        for (roles, 0..) |role, order_index| {
            var name_buffer: [64]u8 = undefined;
            const name = try std.fmt.bufPrint(&name_buffer, "timed-{d}-{d}-{s}", .{ pair_index + 1, order_index + 1, @tagName(role) });
            const directory = try createSampleDirectory(init.gpa, root, init.io, name);
            const observation = try runCaptured(init.gpa, init.io, if (role == .a) a_path else b_path, directory);
            try verifySample(if (role == .a) frozen_a else frozen_b, observation);
            samples[pair_index * 2 + order_index] = .{
                .role = role,
                .pair_index = pair_index,
                .order_index = order_index,
                .observation = observation,
            };
            if (role == .a) pair_a = observation else pair_b = observation;
        }
        const a = pair_a orelse return error.ScheduleDrift;
        const b = pair_b orelse return error.ScheduleDrift;
        if (a.wall_ns == 0) return error.InvalidStatistic;
        pairs[pair_index] = .{ .a = a, .b = b, .ratio = @as(f64, @floatFromInt(b.wall_ns)) / @as(f64, @floatFromInt(a.wall_ns)) };
    }
    const analysis = try analyzePairs(pairs);
    try requireSampleShape(&samples);
    try requireFileIdentityEqual(a_file, try observeFile(init.io, a_path, artifact_max, true));
    try requireFileIdentityEqual(b_file, try observeFile(init.io, b_path, artifact_max, true));
    try requireFileIdentityEqual(workload, try observeFile(init.io, workload_path, 64 * 1024 * 1024, false));
    const encoded = try encodeResult(init.gpa, cpu, workload, frozen_a, frozen_b, idle_records.items, samples, pairs, analysis);
    defer init.gpa.free(encoded);
    var result_directory = try root.openDir(init.io, result_directory_relative, .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer result_directory.close(init.io);
    _ = try publishResult(init.gpa, result_directory, init.io, encoded);
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &stdout_buffer);
    try stdout_writer.interface.print(
        "performance_complete overall_pass={} median_a_ns={d} median_b_ns={d} median_paired_delta_ns={d} time_allowance_ns={d} median_ratio={d} ratio_interval=[{d},{d}] mad={d} max_rss_a={d} max_rss_b={d}\n",
        .{ analysis.overall_pass, analysis.median_a_ns, analysis.median_b_ns, analysis.median_paired_delta_ns, analysis.time_allowance_ns, analysis.median_ratio, analysis.ratio_min, analysis.ratio_max, analysis.ratio_mad, analysis.max_rss_a, analysis.max_rss_b },
    );
    try stdout_writer.interface.flush();
}

fn nextArgument(args: *std.process.Args.Iterator) ![]const u8 {
    return args.next() orelse error.InvalidArguments;
}

pub fn main(init: std.process.Init) !void {
    var arena = std.heap.ArenaAllocator.init(init.gpa);
    defer arena.deinit();
    var run_init = init;
    run_init.gpa = arena.allocator();
    var args = try std.process.Args.Iterator.initAllocator(run_init.minimal.args, run_init.gpa);
    defer args.deinit();
    _ = args.next() orelse return error.InvalidArguments;
    const mode = try nextArgument(&args);
    if (std.mem.eql(u8, mode, "--prepare-artifacts")) {
        if (args.next() != null) return error.InvalidArguments;
        try prepareArtifacts(run_init.io);
    } else if (std.mem.eql(u8, mode, "--run")) {
        const a_path = try nextArgument(&args);
        const b_path = try nextArgument(&args);
        if (args.next() != null) return error.InvalidArguments;
        try runBenchmark(run_init, a_path, b_path);
    } else return error.InvalidArguments;
}

comptime {
    if (builtin.zig_version.major != 0 or builtin.zig_version.minor != 17 or builtin.zig_version.patch != 0)
        @compileError("performance runner requires exact Zig 0.17.0");
    if (builtin.os.tag != .linux or builtin.cpu.arch != .x86_64)
        @compileError("performance runner requires native x86_64 Linux");
}

test "accepted identities decode and wrong identities reject" {
    try std.testing.expectEqual(@as(usize, 32), (try decodeDigest(workload_sha256_hex)).len);
    const identity = FileIdentity{ .bytes = workload_bytes, .mode = 0o444, .sha256 = try decodeDigest(workload_sha256_hex) };
    try requireIdentity(identity, workload_bytes, workload_sha256_hex);
    try std.testing.expectError(error.IdentityMismatch, requireIdentity(identity, workload_bytes + 1, workload_sha256_hex));
    try std.testing.expectError(error.IdentityMismatch, decodeDigest("00"));
}

test "absolute executable and strict DK confinement reject relative aliases and escapes" {
    try validateCanonicalAbsolute(prepared_a_path);
    try requireStrictDescendant(prepared_a_path);
    try std.testing.expectError(error.RelativePath, validateCanonicalAbsolute("z_llvm"));
    try std.testing.expectError(error.NonCanonicalPath, validateCanonicalAbsolute(development_root ++ "/../escape"));
    try std.testing.expectError(error.PathEscape, requireStrictDescendant(repository_root ++ "/escape"));
    try std.testing.expect(!isStrictDescendant(development_root, development_root));
}

test "lowest inherited CPU selection and empty affinity fail closed" {
    var set: [std.os.linux.CPU_SETSIZE / @sizeOf(usize)]usize = @splat(0);
    set[0] = (@as(usize, 1) << 9) | (@as(usize, 1) << 3);
    try std.testing.expectEqual(@as(usize, 3), try lowestCpu(set));
    try std.testing.expectError(error.AffinityPinFailed, requireSingleCpu(set, 3));
    set[0] = @as(usize, 1) << 3;
    try requireSingleCpu(set, 3);
    try std.testing.expectError(error.AffinityPinFailed, requireSingleCpu(set, 4));
    set[0] = 0;
    try std.testing.expectError(error.EmptyAffinity, lowestCpu(set));
}

test "closed environment and fresh sample state are fixed and confined" {
    const sample = development_root ++ "/samples/test";
    const entries = fixedEnvironmentEntries(
        sample ++ "/home",
        sample ++ "/tmp",
        sample ++ "/xdg-cache",
        sample ++ "/zig-local",
        sample ++ "/zig-global",
    );
    try validateFixedEnvironment(sample, entries);
    var drift = entries;
    drift[3].value = repository_root;
    try std.testing.expectError(error.EnvironmentDrift, validateFixedEnvironment(sample, drift));
    drift = entries;
    drift[0].value = "en_US";
    try std.testing.expectError(error.EnvironmentDrift, validateFixedEnvironment(sample, drift));
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    try createFreshDirectory(temporary.dir, std.testing.io, "sample");
    try std.testing.expectError(error.SampleCollision, createFreshDirectory(temporary.dir, std.testing.io, "sample"));
}

test "proc stat parsing exact idle boundary reset zero and malformed fields" {
    const before = try parseCpuLine("cpu0 0 0 0 0 0 0 0 0 0 0\ncpu1 9 9 9 9 9 9 9 9\n", 0);
    const after = try parseCpuLine("cpu0 5 0 0 95 0 0 0 0 0 0\n", 0);
    const exact = try idleWindow(before, after);
    try std.testing.expect(exact.pass);
    var below_after = after;
    below_after.idle = 94;
    below_after.user = 6;
    try std.testing.expect(!(try idleWindow(before, below_after)).pass);
    try std.testing.expectError(error.CounterReset, idleWindow(after, before));
    try std.testing.expectError(error.CounterReset, idleWindow(before, before));
    try std.testing.expectError(error.MalformedProcStat, parseCpuLine("cpu0 1 bad\n", 0));
    try std.testing.expectError(error.CpuStatMissing, parseCpuLine("cpu1 1 2 3 4 5 6 7 8\n", 0));
}

test "checked idle arithmetic and RSS conversion reject overflow and invalid values" {
    var huge = IdleCounters{ .user = std.math.maxInt(u64), .nice = 1, .system = 0, .idle = 0, .iowait = 0, .irq = 0, .softirq = 0, .steal = 0 };
    try std.testing.expectError(error.ArithmeticOverflow, counterTotal(huge));
    huge.nice = 0;
    try std.testing.expectEqual(std.math.maxInt(u64), try counterTotal(huge));
    try std.testing.expectEqual(@as(u64, 4096), try rssKiBToBytes(4));
    try std.testing.expectError(error.InvalidResourceUsage, rssKiBToBytes(-1));
    try std.testing.expectError(error.InvalidResourceUsage, contextSwitches(-1));
}

test "monotonic duration is positive and rejects zero or reversed timestamps" {
    const start = std.Io.Clock.Timestamp{ .raw = .{ .nanoseconds = 10 }, .clock = .awake };
    const finish = std.Io.Clock.Timestamp{ .raw = .{ .nanoseconds = 25 }, .clock = .awake };
    try std.testing.expectEqual(@as(u64, 15), try durationNanoseconds(start, finish));
    try std.testing.expectError(error.InvalidMonotonicTime, durationNanoseconds(start, start));
    try std.testing.expectError(error.InvalidMonotonicTime, durationNanoseconds(finish, start));
}

const synthetic_report =
    "zllvm-codegen-failure function=one diagnostic=x selector_tag=y selector_detail=z\n" ++
    "summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=264 failed_functions=179 first_failing_function=one first_failing_diagnostic=x first_failing_selector_tag=y first_failing_selector_detail=z local_fail=1\n";

test "bounded status report is fail closed and context switches remain diagnostic" {
    const good = try outputIdentity(.{ .exited = 1 }, "object", synthetic_report);
    try std.testing.expectEqual(selected_functions, good.counters.selected);
    try std.testing.expectError(error.ChildFailed, outputIdentity(.{ .exited = 0 }, "object", synthetic_report));
    try std.testing.expectError(error.ChildFailed, outputIdentity(.{ .signal = 9 }, "object", synthetic_report));
    const large = try std.testing.allocator.alloc(u8, capture_max + 1);
    defer std.testing.allocator.free(large);
    try std.testing.expectError(error.OutputOverflow, outputIdentity(.{ .exited = 1 }, large, synthetic_report));
    try std.testing.expectError(error.InvalidResourceUsage, contextSwitches(-2));
}

test "semantic and artifact identity freeze reject object and counter drift" {
    const a1 = ProcessObservation{ .output = try outputIdentity(.{ .exited = 1 }, "a-object", synthetic_report), .wall_ns = 1, .max_rss_bytes = 1, .voluntary_context_switches = 0, .involuntary_context_switches = 0 };
    const file = FileIdentity{ .bytes = 1, .mode = 0o555, .sha256 = sha256("a") };
    const frozen = freezeArtifact(a1, file);
    try verifySample(frozen, a1);
    var contaminated = a1;
    contaminated.involuntary_context_switches = 1;
    try verifySample(frozen, contaminated);
    try std.testing.expectEqual(@as(u64, 1), contaminated.involuntary_context_switches);
    var changed = a1;
    changed.output.object_sha256[0] ^= 1;
    try std.testing.expectError(error.OutputIdentityMismatch, requireArtifactOutput(a1.output, changed.output));
    const b = ProcessObservation{ .output = try outputIdentity(.{ .exited = 1 }, "b-object", synthetic_report), .wall_ns = 1, .max_rss_bytes = 1, .voluntary_context_switches = 0, .involuntary_context_switches = 0 };
    try requireSemanticAgreement(a1.output, b.output);
    changed = b;
    changed.output.semantic_failure_sha256[0] ^= 1;
    try std.testing.expectError(error.SemanticMismatch, requireSemanticAgreement(a1.output, changed.output));
}

test "harmless diagnostic drift preserves semantic and artifact identity" {
    const report_a = "note: first harmless diagnostic\n" ++ synthetic_report;
    const report_b = "note: different harmless diagnostic bytes\n" ++ synthetic_report;
    const output_a = try outputIdentity(.{ .exited = 1 }, "object", report_a);
    const output_b = try outputIdentity(.{ .exited = 1 }, "object", report_b);
    try std.testing.expect(!std.mem.eql(u8, &output_a.stderr_sha256, &output_b.stderr_sha256));
    try requireArtifactOutput(output_a, output_b);
    try requireSemanticAgreement(output_a, output_b);
}

test "fixed schedule and sample count reject drift" {
    try verifySchedule(schedule);
    var changed = schedule;
    changed[0] = .{ .b, .a };
    try std.testing.expectError(error.ScheduleDrift, verifySchedule(changed));
    try std.testing.expectEqual(@as(usize, 1), warmups_per_artifact);
    try std.testing.expectEqual(@as(usize, 1), idle_windows_per_check);
    try std.testing.expectEqual(@as(usize, 6), pair_count);
    var samples: [pair_count * 2]Sample = undefined;
    for (schedule, 0..) |roles, pair_index| for (roles, 0..) |role, order_index| {
        samples[pair_index * 2 + order_index] = .{
            .role = role,
            .pair_index = pair_index,
            .order_index = order_index,
            .observation = undefined,
        };
    };
    try requireSampleShape(&samples);
    try std.testing.expectError(error.SampleCountDrift, requireSampleShape(samples[0 .. samples.len - 1]));
    samples[0].role = .b;
    try std.testing.expectError(error.ScheduleDrift, requireSampleShape(&samples));
}

fn syntheticObservation(time: u64, rss: u64) ProcessObservation {
    return .{
        .output = undefined,
        .wall_ns = time,
        .max_rss_bytes = rss,
        .voluntary_context_switches = 0,
        .involuntary_context_switches = 0,
    };
}

fn syntheticPairs(a: [pair_count]u64, b: [pair_count]u64, rss_a: u64, rss_b: u64) [pair_count]Pair {
    var pairs: [pair_count]Pair = undefined;
    for (&pairs, 0..) |*pair, index| pair.* = .{
        .a = syntheticObservation(a[index], rss_a),
        .b = syntheticObservation(b[index], rss_b),
        .ratio = @as(f64, @floatFromInt(b[index])) / @as(f64, @floatFromInt(a[index])),
    };
    return pairs;
}

test "statistics preserve raw ratios exact CI MAD and threshold edges" {
    const a = [_]u64{ 1_000_000_000, 1_010_000_000, 990_000_000, 1_000_000_000, 1_020_000_000, 980_000_000 };
    const b = [_]u64{ 1_050_000_000, 1_060_500_000, 1_039_500_000, 1_050_000_000, 1_071_000_000, 1_029_000_000 };
    const analysis = try analyzePairs(syntheticPairs(a, b, 100, 100 + rss_limit_bytes));
    try std.testing.expect(analysis.time_pass);
    try std.testing.expect(analysis.rss_pass);
    try std.testing.expect(analysis.overall_pass);
    try std.testing.expectEqual(@as(i128, 50_000_000), analysis.median_paired_delta_ns);
    try std.testing.expectApproxEqAbs(@as(f64, 1.05), analysis.median_ratio, 0.000000001);
    try std.testing.expect(analysis.ratio_min <= analysis.median_ratio);
    try std.testing.expect(analysis.ratio_max >= analysis.median_ratio);
    try std.testing.expect(analysis.ratio_mad >= 0);
    const failing_b: [pair_count]u64 = @splat(1_200_000_000);
    const failing_a: [pair_count]u64 = @splat(1_000_000_000);
    const failing = try analyzePairs(syntheticPairs(failing_a, failing_b, 100, 101 + rss_limit_bytes));
    try std.testing.expect(!failing.time_pass);
    try std.testing.expect(!failing.rss_pass);
    try std.testing.expect(!failing.overall_pass);
}

test "atomic result publication is exact and collision preserving" {
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    const first = try publishResult(std.testing.allocator, temporary.dir, std.testing.io, "exact\n");
    try std.testing.expectEqual(@as(u64, 6), first.bytes);
    try std.testing.expectEqualSlices(u8, &sha256("exact\n"), &first.sha256);
    try std.testing.expectError(error.ResultCollision, publishResult(std.testing.allocator, temporary.dir, std.testing.io, "different\n"));
    const bytes = try temporary.dir.readFileAlloc(std.testing.io, result_name, std.testing.allocator, .limited(64));
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualStrings("exact\n", bytes);
}
