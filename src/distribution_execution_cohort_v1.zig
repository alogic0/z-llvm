const std = @import("std");

const Sha256 = std.crypto.hash.sha2.Sha256;

pub const schema = "distribution-execution-cohort-v1";
pub const repository_root = "/home/oleg/prog/z_llvm";
pub const external_repository_root = "/home/oleg/prog/ziglang";
pub const external_revision = "bdee02bc0c7f227c0f11bc9a449df673fe803540";
pub const definition_path = "lib/std/coff.zig";
pub const import_path = "lib/std/std.zig";
pub const use_path = "src/libs/mingw/implib.zig";
pub const expected_result: usize = 18;
pub const expected_witness: usize = 61;
pub const expected_stdout = "execution-oracle-v1 result=18 witness=61\n";
pub const process_output_max: usize = 16 * 1024 * 1024;
pub const selector_version = "0.17.0-dev.364+bdee02bc0";
pub const selector_length: u64 = 530_327_885;
pub const selector_sha256 = [_]u8{
    0xdc, 0xea, 0x34, 0x78, 0x27, 0x3d, 0x7f, 0xfe,
    0x38, 0x95, 0x70, 0x9c, 0x8e, 0xed, 0x4c, 0xcc,
    0x07, 0x24, 0x54, 0x88, 0x69, 0xcd, 0xb8, 0x61,
    0x83, 0xfc, 0x73, 0x56, 0x16, 0x44, 0x10, 0xb7,
};

pub const Program = enum {
    symbol_size_of,
    weak_external_definition_size_of,

    pub fn functionName(program: Program) []const u8 {
        return switch (program) {
            .symbol_size_of => "coff.Symbol.sizeOf",
            .weak_external_definition_size_of => "coff.WeakExternalDefinition.sizeOf",
        };
    }

    pub fn denominatorSource(program: Program) []const u8 {
        _ = program;
        return "../ziglang/src/main.zig";
    }

    pub fn linkedHarness(program: Program) []const u8 {
        return switch (program) {
            .symbol_size_of => symbol_linked_harness_source,
            .weak_external_definition_size_of => weak_external_linked_harness_source,
        };
    }
};

pub const programs = [_]Program{ .symbol_size_of, .weak_external_definition_size_of };

pub const reference_harness_source =
    \\const std = @import("std");
    \\pub fn main(init: std.process.Init) !void {
    \\    const result: usize = 18;
    \\    const witness = result *% 3 +% 7;
    \\    var buffer: [128]u8 = undefined;
    \\    var writer = std.Io.File.stdout().writer(init.io, &buffer);
    \\    try writer.interface.print("execution-oracle-v1 result={} witness={}\n", .{ result, witness });
    \\    try writer.interface.flush();
    \\}
    \\
;

pub const symbol_linked_harness_source =
    \\const std = @import("std");
    \\const size_of = @extern(*const fn () callconv(.{ .x86_64_sysv = .{} }) usize, .{ .name = "coff.Symbol.sizeOf" });
    \\pub fn main(init: std.process.Init) !void {
    \\    const result = size_of();
    \\    const witness = result *% 3 +% 7;
    \\    var buffer: [128]u8 = undefined;
    \\    var writer = std.Io.File.stdout().writer(init.io, &buffer);
    \\    try writer.interface.print("execution-oracle-v1 result={} witness={}\n", .{ result, witness });
    \\    try writer.interface.flush();
    \\}
    \\
;

pub const weak_external_linked_harness_source =
    \\const std = @import("std");
    \\const size_of = @extern(*const fn () callconv(.{ .x86_64_sysv = .{} }) usize, .{ .name = "coff.WeakExternalDefinition.sizeOf" });
    \\pub fn main(init: std.process.Init) !void {
    \\    const result = size_of();
    \\    const witness = result *% 3 +% 7;
    \\    var buffer: [128]u8 = undefined;
    \\    var writer = std.Io.File.stdout().writer(init.io, &buffer);
    \\    try writer.interface.print("execution-oracle-v1 result={} witness={}\n", .{ result, witness });
    \\    try writer.interface.flush();
    \\}
    \\
;

pub const Termination = enum {
    exited,
    signaled,
    stopped,
    unknown,
};

pub const ExecutionRecord = struct {
    termination: Termination,
    status: u8,
    stdout_sha256: [Sha256.digest_length]u8,
    stderr_sha256: [Sha256.digest_length]u8,
    stdout_length: usize,
    stderr_length: usize,
    semantic_result: usize,
    call_occurrence: bool,
};

pub const PairCounters = struct {
    real_executed: usize = 0,
    real_programs_ok: usize = 0,

    pub fn noteBothExecuted(counters: *PairCounters, reference: ExecutionRecord, linked: ExecutionRecord) !void {
        if (reference.termination != .exited or linked.termination != .exited or
            reference.status != 0 or linked.status != 0)
        {
            return error.ProcessInconsistent;
        }
        counters.real_executed += 1;
    }

    pub fn noteOracleAccepted(counters: *PairCounters, reference: ExecutionRecord, linked: ExecutionRecord) !void {
        if (counters.real_executed != 1) return error.ProcessInconsistent;
        if (!reference.call_occurrence or !linked.call_occurrence) return error.CallOccurrenceMissing;
        if (!std.meta.eql(reference, linked)) return error.OracleMismatch;
        counters.real_programs_ok += 1;
    }
};

pub const OwnedProcessResult = struct {
    term: std.process.Child.Term,
    stdout: []u8,
    stderr: []u8,

    pub fn deinit(result: *OwnedProcessResult, allocator: std.mem.Allocator) void {
        allocator.free(result.stdout);
        allocator.free(result.stderr);
        result.* = undefined;
    }
};

pub const ArtifactIdentity = struct {
    length: u64,
    sha256: [Sha256.digest_length]u8,
    executable: bool,
};

pub const SelectorIdentity = struct {
    version: [128]u8,
    version_length: u8,
    length: u64,
    sha256: [Sha256.digest_length]u8,

    pub fn versionSlice(identity: *const SelectorIdentity) []const u8 {
        return identity.version[0..identity.version_length];
    }
};

pub const BuildPaths = struct {
    reference_source: []const u8,
    linked_source: []const u8,
    object: []const u8,
    reference_executable: []const u8,
    linked_executable: []const u8,
};

pub const EnvironmentPaths = struct {
    home: []const u8,
    temporary: []const u8,
    local_cache: []const u8,
    global_cache: []const u8,
};

pub const SourceIdentity = struct {
    definition_sha256: [Sha256.digest_length]u8,
    import_sha256: [Sha256.digest_length]u8,
    use_sha256: [Sha256.digest_length]u8,
};

pub const OwnedSourceFiles = struct {
    definition: []u8,
    import_source: []u8,
    use_source: []u8,

    pub fn deinit(files: *OwnedSourceFiles, allocator: std.mem.Allocator) void {
        allocator.free(files.use_source);
        allocator.free(files.import_source);
        allocator.free(files.definition);
        files.* = undefined;
    }

    pub fn identity(files: *const OwnedSourceFiles) SourceIdentity {
        return .{
            .definition_sha256 = sha256(files.definition),
            .import_sha256 = sha256(files.import_source),
            .use_sha256 = sha256(files.use_source),
        };
    }
};

pub fn sha256(bytes: []const u8) [Sha256.digest_length]u8 {
    var digest: [Sha256.digest_length]u8 = undefined;
    Sha256.hash(bytes, &digest, .{});
    return digest;
}

pub fn validateHarnesses(program: Program) !void {
    if (std.mem.count(u8, reference_harness_source, "const result: usize = 18;") != 1 or
        std.mem.count(u8, reference_harness_source, "witness={}\\n") != 1 or
        std.mem.count(u8, reference_harness_source, "witness={}\\\\n") != 0)
    {
        return error.HarnessBindingMismatch;
    }
    const linked = program.linkedHarness();
    if (std.mem.count(u8, linked, program.functionName()) != 1 or
        std.mem.count(u8, linked, "size_of()") != 1 or
        std.mem.count(u8, linked, "callconv(.{ .x86_64_sysv = .{} })") != 1 or
        std.mem.count(u8, linked, "const witness = result *% 3 +% 7;") != 1 or
        std.mem.count(u8, linked, "witness={}\\n") != 1 or
        std.mem.count(u8, linked, "witness={}\\\\n") != 0)
    {
        return error.HarnessBindingMismatch;
    }
}

pub fn writeHarnesses(io: std.Io, program: Program, paths: BuildPaths) !void {
    try validateHarnesses(program);
    const cwd = std.Io.Dir.cwd();
    try cwd.writeFile(io, .{ .sub_path = paths.reference_source, .data = reference_harness_source });
    try cwd.writeFile(io, .{ .sub_path = paths.linked_source, .data = program.linkedHarness() });
}

pub fn closedEnvironment(allocator: std.mem.Allocator, paths: EnvironmentPaths) !std.process.Environ.Map {
    var environment = std.process.Environ.Map.init(allocator);
    errdefer environment.deinit();
    try environment.put("LC_ALL", "C");
    try environment.put("LANG", "C");
    try environment.put("TZ", "UTC0");
    try environment.put("HOME", paths.home);
    try environment.put("TMPDIR", paths.temporary);
    try environment.put("ZIG_LOCAL_CACHE_DIR", paths.local_cache);
    try environment.put("ZIG_GLOBAL_CACHE_DIR", paths.global_cache);
    try environment.put("GIT_OPTIONAL_LOCKS", "0");
    try environment.put("GIT_CONFIG_NOSYSTEM", "1");
    try environment.put("GIT_CONFIG_SYSTEM", "/dev/null");
    try environment.put("GIT_CONFIG_GLOBAL", "/dev/null");
    try environment.put("GIT_TERMINAL_PROMPT", "0");
    return environment;
}

pub fn runBounded(
    allocator: std.mem.Allocator,
    io: std.Io,
    argv: []const []const u8,
    environment: ?*const std.process.Environ.Map,
) !OwnedProcessResult {
    if (argv.len == 0 or !std.fs.path.isAbsolute(argv[0])) return error.ChildFailed;
    const result = std.process.run(allocator, io, .{
        .argv = argv,
        .cwd = .{ .path = repository_root },
        .environ_map = environment,
        .stdout_limit = .limited(process_output_max),
        .stderr_limit = .limited(process_output_max),
    }) catch |failure| switch (failure) {
        error.StreamTooLong => return error.ChildOutputBoundExceeded,
        else => return error.ChildFailed,
    };
    return .{ .term = result.term, .stdout = result.stdout, .stderr = result.stderr };
}

pub fn requireExitedZero(result: OwnedProcessResult) !void {
    switch (result.term) {
        .exited => |code| if (code != 0) return error.ChildFailed,
        else => return error.ChildFailed,
    }
}

pub fn buildReference(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_path: []const u8,
    optimize_arg: []const u8,
    paths: BuildPaths,
    environment: *const std.process.Environ.Map,
) !OwnedProcessResult {
    var emit_buffer: [std.Io.Dir.max_path_bytes + 32]u8 = undefined;
    const emit = try std.fmt.bufPrint(&emit_buffer, "-femit-bin={s}", .{paths.reference_executable});
    return runBounded(allocator, io, &.{ zig_path, "build-exe", paths.reference_source, optimize_arg, emit }, environment);
}

pub fn buildLinked(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_path: []const u8,
    optimize_arg: []const u8,
    paths: BuildPaths,
    environment: *const std.process.Environ.Map,
) !OwnedProcessResult {
    var emit_buffer: [std.Io.Dir.max_path_bytes + 32]u8 = undefined;
    const emit = try std.fmt.bufPrint(&emit_buffer, "-femit-bin={s}", .{paths.linked_executable});
    return runBounded(
        allocator,
        io,
        &.{ zig_path, "build-exe", "-fno-lld", paths.linked_source, paths.object, optimize_arg, emit },
        environment,
    );
}

pub fn observeArtifact(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
    require_executable: bool,
    max_bytes: usize,
) !ArtifactIdentity {
    var file = try std.Io.Dir.openFileAbsolute(io, path, .{ .mode = .read_only, .follow_symlinks = false });
    defer file.close(io);
    const metadata = try file.stat(io);
    const executable = std.Io.File.Permissions.has_executable_bit and metadata.permissions.toMode() & 0o111 != 0;
    if (metadata.kind != .file or metadata.size == 0 or metadata.size > max_bytes or executable != require_executable) {
        return error.ExecutionArtifactInvalid;
    }
    var reader = file.reader(io, &.{});
    const bytes = try reader.interface.allocRemaining(allocator, .limited(max_bytes));
    defer allocator.free(bytes);
    if (bytes.len != metadata.size) return error.ExecutionArtifactInvalid;
    return .{ .length = metadata.size, .sha256 = sha256(bytes), .executable = executable };
}

pub fn observeSelector(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
    environment: *const std.process.Environ.Map,
) !SelectorIdentity {
    if (!std.fs.path.isAbsolute(path)) return error.SelectorDrift;
    const artifact = try observeArtifact(allocator, io, path, true, 512 * 1024 * 1024);
    var version_result = try runBounded(allocator, io, &.{ path, "version" }, environment);
    defer version_result.deinit(allocator);
    try requireExitedZero(version_result);
    if (version_result.stderr.len != 0) return error.SelectorDrift;
    const version = std.mem.trim(u8, version_result.stdout, " \t\r\n");
    if (version.len == 0 or version.len > 128) return error.SelectorDrift;
    var identity: SelectorIdentity = .{
        .version = [_]u8{0} ** 128,
        .version_length = @intCast(version.len),
        .length = artifact.length,
        .sha256 = artifact.sha256,
    };
    @memcpy(identity.version[0..version.len], version);
    return identity;
}

pub fn requireSelector(identity: SelectorIdentity) !void {
    if (!std.mem.eql(u8, identity.versionSlice(), selector_version) or identity.length != selector_length or
        !std.mem.eql(u8, &identity.sha256, &selector_sha256))
    {
        return error.SelectorDrift;
    }
}

pub fn requireExternalRepositoryClean(
    allocator: std.mem.Allocator,
    io: std.Io,
    environment: *const std.process.Environ.Map,
) !void {
    const prefix = [_][]const u8{
        "/usr/bin/git", "--no-optional-locks", "-c", "core.fsmonitor=false", "-c", "core.untrackedCache=false", "-C", external_repository_root,
    };
    const head_argv = prefix ++ [_][]const u8{ "rev-parse", "HEAD" };
    var head = try runBounded(allocator, io, &head_argv, environment);
    defer head.deinit(allocator);
    try requireExitedZero(head);
    if (!std.mem.eql(u8, head.stdout, external_revision ++ "\n") or head.stderr.len != 0) {
        return error.ExternalRevisionMismatch;
    }
    const status_argv = prefix ++ [_][]const u8{ "status", "--porcelain=v1", "--untracked-files=all" };
    var status = try runBounded(allocator, io, &status_argv, environment);
    defer status.deinit(allocator);
    try requireExitedZero(status);
    if (status.stdout.len != 0 or status.stderr.len != 0) return error.ExternalRepositoryDirty;
}

pub fn readCurrentSources(allocator: std.mem.Allocator, io: std.Io, max_bytes: usize) !OwnedSourceFiles {
    var root = try std.Io.Dir.openDirAbsolute(io, external_repository_root, .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer root.close(io);
    const definition = try root.readFileAlloc(io, definition_path, allocator, .limited(max_bytes));
    errdefer allocator.free(definition);
    const import_source = try root.readFileAlloc(io, import_path, allocator, .limited(max_bytes));
    errdefer allocator.free(import_source);
    const use_source = try root.readFileAlloc(io, use_path, allocator, .limited(max_bytes));
    return .{ .definition = definition, .import_source = import_source, .use_source = use_source };
}

pub fn canonicalExecutionRecord(
    result: OwnedProcessResult,
    semantic_result: usize,
    call_occurrence: bool,
) !ExecutionRecord {
    const termination: Termination, const status: u8 = switch (result.term) {
        .exited => |code| .{ .exited, code },
        .signal => .{ .signaled, 0 },
        .stopped => .{ .stopped, 0 },
        .unknown => .{ .unknown, 0 },
    };
    if (result.stdout.len > process_output_max or result.stderr.len > process_output_max) {
        return error.ChildOutputBoundExceeded;
    }
    if (termination != .exited or status != 0 or !std.mem.eql(u8, result.stdout, expected_stdout) or result.stderr.len != 0) {
        return error.ProcessInconsistent;
    }
    return .{
        .termination = termination,
        .status = status,
        .stdout_sha256 = sha256(result.stdout),
        .stderr_sha256 = sha256(result.stderr),
        .stdout_length = result.stdout.len,
        .stderr_length = result.stderr.len,
        .semantic_result = semantic_result,
        .call_occurrence = call_occurrence,
    };
}

test "fixed cohort identities and harnesses are exact" {
    try std.testing.expectEqual(@as(usize, 2), programs.len);
    try std.testing.expectEqualStrings("coff.Symbol.sizeOf", programs[0].functionName());
    try std.testing.expectEqualStrings("coff.WeakExternalDefinition.sizeOf", programs[1].functionName());
    try validateHarnesses(.symbol_size_of);
    try validateHarnesses(.weak_external_definition_size_of);
    try std.testing.expectEqual(@as(usize, 0), std.mem.count(u8, programs[0].linkedHarness(), programs[1].functionName()));
}

test "paired counters reject partial status semantic and call drift" {
    const good = ExecutionRecord{
        .termination = .exited,
        .status = 0,
        .stdout_sha256 = sha256(expected_stdout),
        .stderr_sha256 = sha256(""),
        .stdout_length = expected_stdout.len,
        .stderr_length = 0,
        .semantic_result = expected_result,
        .call_occurrence = true,
    };
    var counters: PairCounters = .{};
    try counters.noteBothExecuted(good, good);
    try counters.noteOracleAccepted(good, good);
    try std.testing.expectEqual(@as(usize, 1), counters.real_executed);
    try std.testing.expectEqual(@as(usize, 1), counters.real_programs_ok);

    var nonzero = good;
    nonzero.status = 1;
    var failed: PairCounters = .{};
    try std.testing.expectError(error.ProcessInconsistent, failed.noteBothExecuted(good, nonzero));
    var semantic = good;
    semantic.semantic_result = 19;
    failed.real_executed = 1;
    try std.testing.expectError(error.OracleMismatch, failed.noteOracleAccepted(good, semantic));
    var missing_call = good;
    missing_call.call_occurrence = false;
    try std.testing.expectError(error.CallOccurrenceMissing, failed.noteOracleAccepted(good, missing_call));
}

test "canonical execution records are bounded exact and binary sensitive" {
    const allocator = std.testing.allocator;
    var stdout = try allocator.dupe(u8, expected_stdout);
    defer allocator.free(stdout);
    const stderr = try allocator.dupe(u8, "");
    defer allocator.free(stderr);
    const good = OwnedProcessResult{ .term = .{ .exited = 0 }, .stdout = stdout, .stderr = stderr };
    const record = try canonicalExecutionRecord(good, expected_result, true);
    try std.testing.expectEqual(expected_result, record.semantic_result);
    stdout[0] ^= 1;
    try std.testing.expectError(error.ProcessInconsistent, canonicalExecutionRecord(good, expected_result, true));
}
