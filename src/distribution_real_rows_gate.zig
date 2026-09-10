const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_lowering = @import("zig_air_lowering.zig");
const codegen = @import("codegen.zig");
const mc = @import("mc.zig");
const target = @import("target.zig");
const helpers = @import("uncurated_air_gate_helpers.zig");
const execution_cohort = @import("distribution_execution_cohort_v1.zig");

const selector_version = "real-candidate-selector-v2";
const default_candidate_path = "docs/evidence/real_candidates_release_v2.tsv";
const ziglang_pin_path = "docs/evidence/ziglang_pin.txt";
const export_cache_dir = "tmp/real_rows_air_export_cache";
const target_triple = "x86_64-unknown-linux-gnu";
const cohort_denominator_sha256 = "83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d";
const cohort_object_max_bytes = 16 * 1024 * 1024;
const cohort_executable_max_bytes = 512 * 1024 * 1024;
const air_generation_contract_schema = "distribution-real-rows-air-generation-v1";
const air_export_target = "x86_64-linux-gnu";
const air_export_target_arg = "-Dtarget=x86_64-linux-gnu";
const air_export_pruning = "suspended";
const air_export_argv_contract =
    "<authenticated-emitter>\x00build\x00--build-file\x00../ziglang/build.zig\x00--cache-dir\x00<runner-cache>\x00-Dno-bin\x00-Dno-lib\x00-Dno-langref\x00-Ddebug-extensions=true\x00-Dtarget=x86_64-linux-gnu\x00<mode-optimize>";
const air_export_environment_contract =
    "LC_ALL=C\x00LANG=C\x00TZ=UTC0\x00HOME=<runner-temp>\x00TMPDIR=<runner-temp>\x00ZIG_LOCAL_CACHE_DIR=<runner-cache>\x00ZIG_GLOBAL_CACHE_DIR=<runner-cache>\x00GIT_OPTIONAL_LOCKS=0\x00GIT_CONFIG_NOSYSTEM=1\x00GIT_CONFIG_SYSTEM=/dev/null\x00GIT_CONFIG_GLOBAL=/dev/null\x00GIT_TERMINAL_PROMPT=0\x00ZLLVM_AIR_EXPORT_PATH=<descriptor-output>\x00ZLLVM_REAL_ROWS_PRUNING=suspended";
const Mode = helpers.Mode;

pub const OracleAbiReturnShape = enum {
    integer,
    floating,
};

pub const OracleAbiProof = struct {
    supported_target: target.SupportedTarget,
    parameter_count: usize,
    return_shape: OracleAbiReturnShape,
    return_bits: u16,
    gpr_returns: usize,
    sse_returns: usize,
    memory_return: bool,
};

pub fn oracleAbiProof() !OracleAbiProof {
    const parsed_target = try target.Triple.parse(target_triple);
    const supported_target = parsed_target.supportedTarget() orelse return error.UnsupportedTarget;
    const return_plan = try codegen.x86_64.sysvReturnPlanCountsForTest(.{ .int = 64 });
    return .{
        .supported_target = supported_target,
        .parameter_count = 0,
        .return_shape = .integer,
        .return_bits = 64,
        .gpr_returns = return_plan.gpr_returns,
        .sse_returns = return_plan.sse_returns,
        .memory_return = return_plan.memory_return,
    };
}

const TempDir = struct {
    path: []const u8,
    owned: bool = true,

    fn init(allocator: std.mem.Allocator, io: std.Io, prefix: []const u8) !TempDir {
        var cwd = std.Io.Dir.cwd();
        try cwd.createDirPath(io, "tmp");
        const path = try std.fmt.allocPrint(allocator, "tmp/{s}_{}", .{ prefix, std.os.linux.getpid() });
        errdefer allocator.free(path);
        cwd.deleteTree(io, path) catch {};
        try cwd.createDirPath(io, path);
        return .{ .path = path };
    }

    fn useRunnerOwned(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !TempDir {
        try std.Io.Dir.cwd().access(io, path, .{});
        return .{ .path = try allocator.dupe(u8, path), .owned = false };
    }

    fn deinit(temp: TempDir, allocator: std.mem.Allocator, io: std.Io) void {
        if (temp.owned) std.Io.Dir.cwd().deleteTree(io, temp.path) catch {};
        allocator.free(temp.path);
    }

    fn join(temp: TempDir, allocator: std.mem.Allocator, name: []const u8) ![]const u8 {
        return std.fs.path.join(allocator, &.{ temp.path, name });
    }
};

const Options = struct {
    limit: usize = 1,
    strict: bool = false,
    candidate_path: []const u8 = default_candidate_path,
    mode: ?Mode = null,
    fresh_export: bool = false,
    require_cache_hit: bool = false,
    cache_probe_only: bool = false,
    runner_temp_root: ?[]const u8 = null,
    export_cache_root: []const u8 = export_cache_dir,
    export_cache_root_explicit: bool = false,
};

const Candidate = struct {
    rank: usize,
    source: []const u8,
    function: []const u8,
    instruction_count: usize,
    signature_class: []const u8,
    call_class: []const u8,
    global_refs: usize,
    runtime_refs: usize,
    determinism: []const u8,
    harnessable_reason: []const u8,
};

const Counters = struct {
    mode: Mode,
    limit: usize,
    candidate_rows: usize,
    real_functions_lowered: usize = 0,
    real_objects_emitted: usize = 0,
    real_native_linked: usize = 0,
    real_executed: usize = 0,
    real_programs_ok: usize = 0,
    first_failing_real_row: ?[]const u8 = null,
    first_failing_stage: ?[]const u8 = null,

    fn hasFailure(self: Counters) bool {
        return self.first_failing_real_row != null;
    }
};

const CohortTracker = struct {
    executed: [execution_cohort.programs.len]bool = [_]bool{false} ** execution_cohort.programs.len,
    accepted: [execution_cohort.programs.len]bool = [_]bool{false} ** execution_cohort.programs.len,

    fn record(tracker: *CohortTracker, program: execution_cohort.Program, pair: execution_cohort.PairCounters) !void {
        const index = @intFromEnum(program);
        if (tracker.executed[index] or tracker.accepted[index] or pair.real_executed != 1 or pair.real_programs_ok != 1) {
            return error.ExecutionCohortPartialCredit;
        }
        tracker.executed[index] = true;
        tracker.accepted[index] = true;
    }

    fn finalize(tracker: CohortTracker, counters: *Counters) !void {
        for (tracker.executed, tracker.accepted) |executed, accepted| {
            if (!executed or !accepted) return error.ExecutionCohortPartialCredit;
        }
        counters.real_executed += execution_cohort.programs.len;
        counters.real_programs_ok += execution_cohort.programs.len;
    }
};

const counter_schema_version = "distribution-real-rows-v2";

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const options = try parseOptions(allocator, io, init);

    const candidate_file = try std.Io.Dir.cwd().readFileAlloc(io, options.candidate_path, allocator, .limited(32 * 1024 * 1024));
    defer allocator.free(candidate_file);
    const candidate_hash = candidateFileHash(candidate_file);
    var candidates = try parseCandidates(allocator, candidate_file, options.limit);
    defer freeCandidates(allocator, &candidates);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print(
        "distribution-real-rows selector_version={s} candidate_file={s} candidate_file_hash={s} limit={} strict={}\n",
        .{ selector_version, options.candidate_path, &candidate_hash, options.limit, options.strict },
    );
    try stdout_writer.interface.flush();

    const modes = [_]Mode{ .ReleaseFast, .ReleaseSafe, .ReleaseSmall };
    var any_failure = false;
    for (modes) |mode| {
        if (options.mode) |selected| {
            if (mode != selected) continue;
        }
        var counters = try runMode(allocator, io, init, &stdout_writer.interface, mode, options, candidates.items, &candidate_hash);
        defer {
            if (counters.first_failing_real_row) |value| allocator.free(value);
            if (counters.first_failing_stage) |value| allocator.free(value);
        }
        any_failure = any_failure or counters.hasFailure();
        if (options.cache_probe_only) {
            try stdout_writer.interface.print(
                "summary distribution-real-rows-cache-probe schema_version=1 mode={s} cache_status=hit pruning=suspended local_fail=0\n",
                .{mode.name()},
            );
        } else {
            try printSummary(&stdout_writer.interface, counters, &candidate_hash);
        }
        try stdout_writer.interface.flush();
    }

    if (options.strict and any_failure) std.process.exit(1);
}

fn parseOptions(allocator: std.mem.Allocator, io: std.Io, init: std.process.Init) !Options {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();

    var raw: std.ArrayList([]const u8) = .empty;
    defer raw.deinit(allocator);
    while (args.next()) |arg| try raw.append(allocator, arg);
    return parseRawOptions(io, raw.items);
}

fn parseRawOptions(io: std.Io, raw_args: []const []const u8) !Options {
    var options: Options = .{};
    for (raw_args) |arg| {
        if (std.mem.eql(u8, arg, "--strict")) {
            options.strict = true;
        } else if (std.mem.eql(u8, arg, "--fresh-export")) {
            options.fresh_export = true;
        } else if (std.mem.eql(u8, arg, "--require-cache-hit")) {
            options.require_cache_hit = true;
        } else if (std.mem.eql(u8, arg, "--cache-probe-only")) {
            options.cache_probe_only = true;
        } else if (std.mem.startsWith(u8, arg, "--limit=")) {
            options.limit = try std.fmt.parseUnsigned(usize, arg["--limit=".len..], 10);
        } else if (std.mem.startsWith(u8, arg, "--mode=")) {
            options.mode = try parseMode(io, arg["--mode=".len..]);
        } else if (std.mem.startsWith(u8, arg, "--candidate-file=")) {
            options.candidate_path = arg["--candidate-file=".len..];
        } else if (std.mem.startsWith(u8, arg, "--runner-temp-root=")) {
            options.runner_temp_root = arg["--runner-temp-root=".len..];
        } else if (std.mem.startsWith(u8, arg, "--export-cache-root=")) {
            options.export_cache_root = arg["--export-cache-root=".len..];
            options.export_cache_root_explicit = true;
        } else {
            try validationError(io, "unexpected argument: {s}\n", .{arg});
        }
    }
    if (options.limit == 0) try validationError(io, "--limit must be greater than zero\n", .{});
    if (options.fresh_export and options.require_cache_hit) {
        return error.FreshExportConflictsWithRequiredCacheHit;
    }
    if (options.cache_probe_only and (!options.require_cache_hit or options.mode == null)) {
        return error.CacheProbeRequiresModeAndRequiredHit;
    }
    if (options.runner_temp_root) |path| if (path.len == 0) {
        return error.EmptyRunnerTempRoot;
    };
    if (options.export_cache_root.len == 0) return error.EmptyExportCacheRoot;
    return options;
}

fn cohortEnabled(options: Options) bool {
    return cohortSelected(options) and !options.cache_probe_only;
}

fn cohortSelected(options: Options) bool {
    return options.strict and options.limit == 100 and
        std.mem.eql(u8, options.candidate_path, default_candidate_path);
}

fn cohortProgram(candidate: Candidate) ?execution_cohort.Program {
    for (execution_cohort.programs) |program| {
        if (std.mem.eql(u8, candidate.source, program.denominatorSource()) and
            std.mem.eql(u8, candidate.function, program.functionName())) return program;
    }
    return null;
}

fn requireCohortDenominator(candidates: []const Candidate, candidate_hash: *const [64]u8) !void {
    if (candidates.len != 100 or !std.mem.eql(u8, candidate_hash, cohort_denominator_sha256)) {
        return error.ExecutionCohortDenominatorDrift;
    }
    var counts = [_]usize{0} ** execution_cohort.programs.len;
    for (candidates) |candidate| if (cohortProgram(candidate)) |program| {
        counts[@intFromEnum(program)] += 1;
    };
    for (counts) |count| if (count != 1) return error.ExecutionCohortMembershipMismatch;
}

fn requireCohortModeRoot(io: std.Io, options: Options, mode: Mode) !void {
    const runner_root = options.runner_temp_root orelse return error.ExecutionCohortRootMissing;
    if (!options.export_cache_root_explicit) return error.ExecutionCohortRootMissing;
    const runner_owner = try requireCanonicalModeOwnedDirectory(io, runner_root, mode);
    const cache_owner = try requireCanonicalModeOwnedDirectory(io, options.export_cache_root, mode);
    if (!std.mem.eql(u8, runner_owner, cache_owner)) return error.ExecutionCohortRootMismatch;
}

fn requireCanonicalModeOwnedDirectory(io: std.Io, path: []const u8, mode: Mode) ![]const u8 {
    if (path.len == 0 or std.fs.path.isAbsolute(path) or path[path.len - 1] == '/') {
        return error.ExecutionCohortRootInvalid;
    }
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
            return error.ExecutionCohortRootInvalid;
        }
        for ([_]Mode{ .ReleaseFast, .ReleaseSafe, .ReleaseSmall }) |known_mode| {
            if (std.mem.eql(u8, part, known_mode.name())) {
                if (known_mode != mode) return error.ExecutionCohortRootModeMismatch;
                selected_mode_count += 1;
            }
        }
        const next = current.openDir(io, part, .{ .access_sub_paths = true, .iterate = false, .follow_symlinks = false }) catch {
            return error.ExecutionCohortRootInvalid;
        };
        if (current_owned) current.close(io);
        current = next;
        current_owned = true;
        previous_previous = previous;
        previous = part;
    }
    const leaf = previous orelse return error.ExecutionCohortRootInvalid;
    _ = leaf;
    const mode_component = previous_previous orelse return error.ExecutionCohortRootInvalid;
    if (!std.mem.eql(u8, mode_component, mode.name()) or selected_mode_count != 1) {
        return error.ExecutionCohortRootModeMismatch;
    }
    const mode_start = @intFromPtr(mode_component.ptr) - @intFromPtr(path.ptr);
    if (mode_start == 0 or path[mode_start - 1] != '/') return error.ExecutionCohortRootInvalid;
    const owner_end = mode_start - 1;
    const owner_start = if (std.mem.lastIndexOfScalar(u8, path[0..owner_end], '/')) |slash| slash + 1 else 0;
    if (owner_start == owner_end) return error.ExecutionCohortRootInvalid;
    return path[owner_start..owner_end];
}

test "parallel worker arguments round-trip through the production parser" {
    const mode_names = [_][]const u8{ "ReleaseFast", "ReleaseSafe", "ReleaseSmall" };
    const expected_modes = [_]Mode{ .ReleaseFast, .ReleaseSafe, .ReleaseSmall };
    for (mode_names, expected_modes) |name, expected| {
        var mode_buffer: [64]u8 = undefined;
        const mode_arg = try std.fmt.bufPrint(&mode_buffer, "--mode={s}", .{name});
        const parsed = try parseRawOptions(std.testing.io, &.{ mode_arg, "--strict", "--limit=100", "--require-cache-hit", "--runner-temp-root=owned/contract/ReleaseFast/work", "--export-cache-root=cache/contract/ReleaseFast/export" });
        try std.testing.expectEqual(expected, parsed.mode.?);
        try std.testing.expect(parsed.strict);
        try std.testing.expectEqual(@as(usize, 100), parsed.limit);
        try std.testing.expect(parsed.require_cache_hit);
        try std.testing.expectEqualStrings("owned/contract/ReleaseFast/work", parsed.runner_temp_root.?);
        try std.testing.expectEqualStrings("cache/contract/ReleaseFast/export", parsed.export_cache_root);
        try std.testing.expect(parsed.export_cache_root_explicit);
    }
}

test "cache probe parser is fail-closed and rejects partial cache authority" {
    const parsed = try parseRawOptions(std.testing.io, &.{ "--mode=ReleaseFast", "--strict", "--limit=100", "--require-cache-hit", "--cache-probe-only", "--runner-temp-root=owned/contract/ReleaseFast/work", "--export-cache-root=cache/contract/ReleaseFast/export" });
    try std.testing.expect(parsed.cache_probe_only);
    try std.testing.expect(cohortSelected(parsed));
    try std.testing.expect(!cohortEnabled(parsed));
    try std.testing.expectError(error.CacheProbeRequiresModeAndRequiredHit, parseRawOptions(std.testing.io, &.{ "--mode=ReleaseFast", "--cache-probe-only" }));
    try std.testing.expectError(error.FreshExportConflictsWithRequiredCacheHit, parseRawOptions(std.testing.io, &.{ "--mode=ReleaseFast", "--fresh-export", "--require-cache-hit" }));
}

test "cohort root contract authenticates complete worker selections and rejects drift" {
    const io = std.testing.io;
    var path_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const fixture = try std.fmt.bufPrint(&path_buffer, "local-state/caches/o2-calls/production-execution-cohort-v1-corrective-development/gate-root-test-{}", .{std.os.linux.getpid()});
    var cwd = std.Io.Dir.cwd();
    cwd.deleteTree(io, fixture) catch {};
    defer cwd.deleteTree(io, fixture) catch {};
    const work = try std.fmt.allocPrint(std.testing.allocator, "{s}/contract-a/ReleaseFast/work", .{fixture});
    defer std.testing.allocator.free(work);
    const cache = try std.fmt.allocPrint(std.testing.allocator, "{s}/contract-a/ReleaseFast/export", .{fixture});
    defer std.testing.allocator.free(cache);
    const other_owner = try std.fmt.allocPrint(std.testing.allocator, "{s}/contract-b/ReleaseFast/export", .{fixture});
    defer std.testing.allocator.free(other_owner);
    const wrong_mode = try std.fmt.allocPrint(std.testing.allocator, "{s}/contract-a/ReleaseSafe/export", .{fixture});
    defer std.testing.allocator.free(wrong_mode);
    try cwd.createDirPath(io, work);
    try cwd.createDirPath(io, cache);
    try cwd.createDirPath(io, other_owner);
    try cwd.createDirPath(io, wrong_mode);
    var options: Options = .{ .strict = true, .limit = 100, .mode = .ReleaseFast, .runner_temp_root = work, .export_cache_root = cache, .export_cache_root_explicit = true };
    try requireCohortModeRoot(io, options, .ReleaseFast);
    options.export_cache_root = other_owner;
    try std.testing.expectError(error.ExecutionCohortRootMismatch, requireCohortModeRoot(io, options, .ReleaseFast));
    options.export_cache_root = wrong_mode;
    try std.testing.expectError(error.ExecutionCohortRootModeMismatch, requireCohortModeRoot(io, options, .ReleaseFast));
    options.export_cache_root = cache;
    options.export_cache_root_explicit = false;
    try std.testing.expectError(error.ExecutionCohortRootMissing, requireCohortModeRoot(io, options, .ReleaseFast));
    options.export_cache_root_explicit = true;
    options.runner_temp_root = "/absolute/contract-a/ReleaseFast/work";
    try std.testing.expectError(error.ExecutionCohortRootInvalid, requireCohortModeRoot(io, options, .ReleaseFast));
    const escaping = try std.fmt.allocPrint(std.testing.allocator, "{s}/contract-a/ReleaseFast/../work", .{fixture});
    defer std.testing.allocator.free(escaping);
    options.runner_temp_root = escaping;
    try std.testing.expectError(error.ExecutionCohortRootInvalid, requireCohortModeRoot(io, options, .ReleaseFast));
    const symlink = try std.fmt.allocPrint(std.testing.allocator, "{s}/contract-a/ReleaseFast/work-link", .{fixture});
    defer std.testing.allocator.free(symlink);
    try cwd.symLink(io, "work", symlink, .{ .is_directory = true });
    options.runner_temp_root = symlink;
    try std.testing.expectError(error.ExecutionCohortRootInvalid, requireCohortModeRoot(io, options, .ReleaseFast));
}

fn syntheticCohortCandidate(source: []const u8, function: []const u8) Candidate {
    return .{
        .rank = 999,
        .source = source,
        .function = function,
        .instruction_count = 2,
        .signature_class = "internal-callable",
        .call_class = "leaf",
        .global_refs = 0,
        .runtime_refs = 0,
        .determinism = "assumed_nondeterministic",
        .harnessable_reason = "harnessable:leaf_no_refs_supported",
    };
}

test "execution cohort denominator is exact rank independent and atomic" {
    var candidates = [_]Candidate{syntheticCohortCandidate("other", "other")} ** 100;
    candidates[17] = syntheticCohortCandidate("../ziglang/src/main.zig", "coff.Symbol.sizeOf");
    candidates[42] = syntheticCohortCandidate("../ziglang/src/main.zig", "link.MachO.CodeSignature.Requirements.size");
    candidates[61] = syntheticCohortCandidate("../ziglang/src/main.zig", "link.MachO.CodeSignature.Requirements.slotType");
    candidates[83] = syntheticCohortCandidate("../ziglang/src/main.zig", "coff.WeakExternalDefinition.sizeOf");
    var digest: [64]u8 = undefined;
    @memcpy(&digest, cohort_denominator_sha256);
    try requireCohortDenominator(&candidates, &digest);
    candidates[83].function = "other";
    try std.testing.expectError(error.ExecutionCohortMembershipMismatch, requireCohortDenominator(&candidates, &digest));
    candidates[83] = candidates[17];
    try std.testing.expectError(error.ExecutionCohortMembershipMismatch, requireCohortDenominator(&candidates, &digest));
    digest[0] = if (digest[0] == '0') '1' else '0';
    try std.testing.expectError(error.ExecutionCohortDenominatorDrift, requireCohortDenominator(&candidates, &digest));

    var tracker: CohortTracker = .{};
    try tracker.record(.symbol_size_of, .{ .real_executed = 1, .real_programs_ok = 1 });
    var counters: Counters = .{ .mode = .ReleaseFast, .limit = 100, .candidate_rows = 100 };
    try std.testing.expectError(error.ExecutionCohortPartialCredit, tracker.finalize(&counters));
    try std.testing.expectEqual(@as(usize, 0), counters.real_executed);
    try std.testing.expectEqual(@as(usize, 0), counters.real_programs_ok);
    try tracker.record(.weak_external_definition_size_of, .{ .real_executed = 1, .real_programs_ok = 1 });
    try std.testing.expectError(error.ExecutionCohortPartialCredit, tracker.finalize(&counters));
    try tracker.record(.requirements_size, .{ .real_executed = 1, .real_programs_ok = 1 });
    try std.testing.expectError(error.ExecutionCohortPartialCredit, tracker.finalize(&counters));
    try tracker.record(.requirements_slot_type, .{ .real_executed = 1, .real_programs_ok = 1 });
    try tracker.finalize(&counters);
    try std.testing.expectEqual(@as(usize, 4), counters.real_executed);
    try std.testing.expectEqual(@as(usize, 4), counters.real_programs_ok);
}

fn airGenerationCacheKeyForTest(identity: DescriptorCacheIdentity) ![64]u8 {
    const text = try airGenerationCacheKeyText(std.testing.allocator, identity);
    defer std.testing.allocator.free(text);
    return sha256Hex(text);
}

fn expectAirGenerationCacheKeyDrift(expected: *const [64]u8, identity: DescriptorCacheIdentity) !void {
    const actual = try airGenerationCacheKeyForTest(identity);
    try std.testing.expect(!std.mem.eql(u8, expected, &actual));
}

test "causal AIR generation cache identity excludes admission parser bytes and binds every generation input" {
    const base: DescriptorCacheIdentity = .{
        .generation = .{
            .ziglang_pin = "pin-a",
            .external_revision = "revision-a",
            .source_authority_sha256 = [_]u8{'a'} ** 64,
            .selector_version = "selector-a",
            .selector_length = 100,
            .selector_sha256 = [_]u8{'b'} ** 64,
            .target = air_export_target,
            .mode = "ReleaseSafe",
            .pruning = air_export_pruning,
            .optimize_argv = "-Doptimize=ReleaseSafe",
            .argv_contract = air_export_argv_contract,
            .environment_contract = air_export_environment_contract,
        },
        .admission_implementation = "admission-a",
        .parser_implementation = "parser-a",
    };
    const expected = try airGenerationCacheKeyForTest(base);

    var non_causal = base;
    non_causal.admission_implementation = "admission-b";
    non_causal.parser_implementation = "parser-b";
    const non_causal_key = try airGenerationCacheKeyForTest(non_causal);
    try std.testing.expectEqualSlices(u8, &expected, &non_causal_key);

    var causal = base;
    causal.generation.ziglang_pin = "pin-b";
    try expectAirGenerationCacheKeyDrift(&expected, causal);
    causal = base;
    causal.generation.source_authority_sha256[0] = 'c';
    try expectAirGenerationCacheKeyDrift(&expected, causal);
    causal = base;
    causal.generation.selector_sha256[0] = 'c';
    try expectAirGenerationCacheKeyDrift(&expected, causal);
    causal = base;
    causal.generation.target = "aarch64-linux-gnu";
    try expectAirGenerationCacheKeyDrift(&expected, causal);
    causal = base;
    causal.generation.mode = "ReleaseFast";
    try expectAirGenerationCacheKeyDrift(&expected, causal);
    causal = base;
    causal.generation.pruning = "enabled";
    try expectAirGenerationCacheKeyDrift(&expected, causal);
    causal = base;
    causal.generation.argv_contract = "different-argv";
    try expectAirGenerationCacheKeyDrift(&expected, causal);
    causal = base;
    causal.generation.environment_contract = "different-environment";
    try expectAirGenerationCacheKeyDrift(&expected, causal);
}

test "cohort descriptor membership requires each selected function exactly once" {
    const candidates = [_]Candidate{syntheticCohortCandidate("../ziglang/src/main.zig", "coff.Symbol.sizeOf")};
    const frame =
        "function_begin\n" ++
        "name_bytes=18\n" ++
        "coff.Symbol.sizeOf\n" ++
        "function_end\n";
    try std.testing.expect(try descriptorContainsAllFunctions(std.testing.allocator, frame, &candidates));
    const duplicate = frame ++ frame;
    try std.testing.expect(!try descriptorContainsAllFunctions(std.testing.allocator, duplicate, &candidates));
}

fn parseMode(io: std.Io, text: []const u8) !Mode {
    if (std.mem.eql(u8, text, "ReleaseFast")) return .ReleaseFast;
    if (std.mem.eql(u8, text, "ReleaseSafe")) return .ReleaseSafe;
    if (std.mem.eql(u8, text, "ReleaseSmall")) return .ReleaseSmall;
    try validationError(io, "unsupported --mode={s}; expected ReleaseFast, ReleaseSafe, or ReleaseSmall\n", .{text});
}

fn parseCandidates(allocator: std.mem.Allocator, contents: []const u8, limit: usize) !std.ArrayList(Candidate) {
    var rows: std.ArrayList(Candidate) = .empty;
    errdefer freeCandidates(allocator, &rows);

    var line_iter = std.mem.splitScalar(u8, contents, '\n');
    _ = line_iter.next();
    while (line_iter.next()) |raw_line| {
        if (rows.items.len >= limit) break;
        const line = std.mem.trim(u8, raw_line, "\r\n");
        if (line.len == 0) continue;
        var fields = std.mem.splitScalar(u8, line, '\t');
        const rank_text = fields.next() orelse return error.InvalidCandidateRow;
        const source = fields.next() orelse return error.InvalidCandidateRow;
        const function = fields.next() orelse return error.InvalidCandidateRow;
        const instruction_count = fields.next() orelse return error.InvalidCandidateRow;
        const signature_class = fields.next() orelse return error.InvalidCandidateRow;
        const call_class = fields.next() orelse return error.InvalidCandidateRow;
        const global_refs = fields.next() orelse return error.InvalidCandidateRow;
        const runtime_refs = fields.next() orelse return error.InvalidCandidateRow;
        const determinism = fields.next() orelse return error.InvalidCandidateRow;
        const harnessable_reason = fields.next() orelse return error.InvalidCandidateRow;
        try rows.append(allocator, .{
            .rank = try std.fmt.parseUnsigned(usize, rank_text, 10),
            .source = try allocator.dupe(u8, source),
            .function = try allocator.dupe(u8, function),
            .instruction_count = try std.fmt.parseUnsigned(usize, instruction_count, 10),
            .signature_class = try allocator.dupe(u8, signature_class),
            .call_class = try allocator.dupe(u8, call_class),
            .global_refs = try std.fmt.parseUnsigned(usize, global_refs, 10),
            .runtime_refs = try std.fmt.parseUnsigned(usize, runtime_refs, 10),
            .determinism = try allocator.dupe(u8, determinism),
            .harnessable_reason = try allocator.dupe(u8, harnessable_reason),
        });
    }
    return rows;
}

fn freeCandidates(allocator: std.mem.Allocator, rows: *std.ArrayList(Candidate)) void {
    for (rows.items) |candidate| {
        allocator.free(candidate.source);
        allocator.free(candidate.function);
        allocator.free(candidate.signature_class);
        allocator.free(candidate.call_class);
        allocator.free(candidate.determinism);
        allocator.free(candidate.harnessable_reason);
    }
    rows.deinit(allocator);
}

fn runMode(
    allocator: std.mem.Allocator,
    io: std.Io,
    init: std.process.Init,
    stdout: *std.Io.Writer,
    mode: Mode,
    options: Options,
    candidates: []const Candidate,
    candidate_hash: *const [64]u8,
) !Counters {
    var counters: Counters = .{
        .mode = mode,
        .limit = options.limit,
        .candidate_rows = candidates.len,
    };
    const cohort_selected = cohortSelected(options);
    const cohort_enabled = cohortEnabled(options);
    if (cohort_selected) {
        try requireCohortDenominator(candidates, candidate_hash);
        try requireCohortModeRoot(io, options, mode);
    }
    var cohort_tracker: CohortTracker = .{};

    const temp = if (options.runner_temp_root) |path|
        try TempDir.useRunnerOwned(allocator, io, path)
    else
        try TempDir.init(allocator, io, "distribution_real_rows");
    defer temp.deinit(allocator, io);
    const descriptor_path = try temp.join(allocator, "compiler.air");
    defer allocator.free(descriptor_path);
    const zig_cache_path = try temp.join(allocator, "zig-cache");
    defer allocator.free(zig_cache_path);
    const generation_source_initial = try observeCohortSourceIdentity(allocator, io, temp.path);
    const zig_emitter = try readStage4Emitter(allocator, io, init);
    defer allocator.free(zig_emitter);

    const descriptor = try loadOrExportDescriptor(
        allocator,
        io,
        init,
        stdout,
        mode,
        options,
        candidates,
        descriptor_path,
        zig_cache_path,
        zig_emitter,
        generation_source_initial,
        options.export_cache_root,
    ) orelse {
        if (options.require_cache_hit) return error.RealRowsCacheHitRequired;
        for (candidates) |candidate| try setFirstFailure(allocator, &counters, candidate, "air-export");
        return counters;
    };
    defer allocator.free(descriptor);
    if (options.cache_probe_only) return counters;
    for (candidates) |candidate| {
        try runCandidate(
            allocator,
            io,
            init,
            stdout,
            mode,
            temp,
            descriptor,
            candidate,
            candidate_hash,
            &counters,
            zig_emitter,
            if (cohort_enabled) &cohort_tracker else null,
        );
    }
    if (cohort_enabled and !counters.hasFailure()) {
        const cohort_source_final = try observeCohortSourceIdentity(allocator, io, temp.path);
        if (!std.meta.eql(generation_source_initial, cohort_source_final)) return error.ExecutionCohortSourceDrift;
        try cohort_tracker.finalize(&counters);
    }
    return counters;
}

fn observeCohortSourceIdentity(
    allocator: std.mem.Allocator,
    io: std.Io,
    temporary_root: []const u8,
) !execution_cohort.SourceIdentity {
    var environment = try execution_cohort.closedEnvironment(allocator, .{
        .home = temporary_root,
        .temporary = temporary_root,
        .local_cache = temporary_root,
        .global_cache = temporary_root,
    });
    defer environment.deinit();
    try execution_cohort.requireExternalRepositoryClean(allocator, io, &environment);
    var sources = try execution_cohort.readCurrentSources(allocator, io, 32 * 1024 * 1024);
    defer sources.deinit(allocator);
    try sources.validate();
    return sources.identity();
}

const AirGenerationInputs = struct {
    ziglang_pin: []const u8,
    external_revision: []const u8,
    source_authority_sha256: [64]u8,
    selector_version: []const u8,
    selector_length: u64,
    selector_sha256: [64]u8,
    target: []const u8,
    mode: []const u8,
    pruning: []const u8,
    optimize_argv: []const u8,
    argv_contract: []const u8,
    environment_contract: []const u8,
};

const DescriptorCacheIdentity = struct {
    generation: AirGenerationInputs,
    admission_implementation: []const u8 = "mandatory-runtime",
    parser_implementation: []const u8 = "mandatory-runtime",
};

fn sourceAuthoritySha256(identity: execution_cohort.SourceIdentity) [64]u8 {
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    inline for (@typeInfo(execution_cohort.SourceIdentity).@"struct".fields) |field| {
        hasher.update(field.name);
        hasher.update("\x00");
        hasher.update(&@field(identity, field.name));
    }
    var digest: [32]u8 = undefined;
    hasher.final(&digest);
    return std.fmt.bytesToHex(digest, .lower);
}

fn airGenerationCacheKeyText(allocator: std.mem.Allocator, identity: DescriptorCacheIdentity) ![]u8 {
    _ = identity.admission_implementation;
    _ = identity.parser_implementation;
    const generation = identity.generation;
    return std.fmt.allocPrint(
        allocator,
        "{s}\nziglang_pin_bytes={}\n{s}\nexternal_revision_bytes={}\n{s}\nsource_authority_sha256={s}\nselector_version_bytes={}\n{s}\nselector_length={}\nselector_sha256={s}\ntarget_bytes={}\n{s}\nmode_bytes={}\n{s}\npruning_bytes={}\n{s}\noptimize_argv_bytes={}\n{s}\nargv_contract_bytes={}\n{s}\nenvironment_contract_bytes={}\n{s}\n",
        .{
            air_generation_contract_schema,
            generation.ziglang_pin.len,
            generation.ziglang_pin,
            generation.external_revision.len,
            generation.external_revision,
            &generation.source_authority_sha256,
            generation.selector_version.len,
            generation.selector_version,
            generation.selector_length,
            &generation.selector_sha256,
            generation.target.len,
            generation.target,
            generation.mode.len,
            generation.mode,
            generation.pruning.len,
            generation.pruning,
            generation.optimize_argv.len,
            generation.optimize_argv,
            generation.argv_contract.len,
            generation.argv_contract,
            generation.environment_contract.len,
            generation.environment_contract,
        },
    );
}

fn loadOrExportDescriptor(
    allocator: std.mem.Allocator,
    io: std.Io,
    init: std.process.Init,
    stdout: *std.Io.Writer,
    mode: Mode,
    options: Options,
    candidates: []const Candidate,
    descriptor_path: []const u8,
    zig_cache_path: []const u8,
    zig_emitter: []const u8,
    source_identity: execution_cohort.SourceIdentity,
    selected_export_cache_root: []const u8,
) !?[]u8 {
    const ziglang_pin = try readZiglangPin(allocator, io);
    defer allocator.free(ziglang_pin);
    if (!std.mem.eql(u8, ziglang_pin, execution_cohort.external_revision)) {
        return error.ExternalRevisionMismatch;
    }
    const temporary_root = std.fs.path.dirname(descriptor_path) orelse return error.InvalidAirGenerationPath;
    var env_map = try execution_cohort.closedEnvironment(allocator, .{
        .home = temporary_root,
        .temporary = temporary_root,
        .local_cache = zig_cache_path,
        .global_cache = zig_cache_path,
    });
    defer env_map.deinit();
    try env_map.put("ZLLVM_AIR_EXPORT_PATH", descriptor_path);
    try env_map.put("ZLLVM_REAL_ROWS_PRUNING", air_export_pruning);
    const inherited_pruning = init.minimal.environ.getAlloc(allocator, "ZLLVM_REAL_ROWS_PRUNING") catch |err| switch (err) {
        error.EnvironmentVariableMissing => return error.AirGenerationPruningMissing,
        else => return err,
    };
    defer allocator.free(inherited_pruning);
    if (!std.mem.eql(u8, inherited_pruning, air_export_pruning)) return error.AirGenerationPruningMismatch;

    const selector_identity = try execution_cohort.observeSelector(allocator, io, zig_emitter, &env_map);
    try execution_cohort.requireSelector(selector_identity);
    const cache_identity: DescriptorCacheIdentity = .{
        .generation = .{
            .ziglang_pin = ziglang_pin,
            .external_revision = execution_cohort.external_revision,
            .source_authority_sha256 = sourceAuthoritySha256(source_identity),
            .selector_version = selector_identity.versionSlice(),
            .selector_length = selector_identity.length,
            .selector_sha256 = std.fmt.bytesToHex(selector_identity.sha256, .lower),
            .target = air_export_target,
            .mode = mode.name(),
            .pruning = air_export_pruning,
            .optimize_argv = zigBuildOptimizeArg(mode),
            .argv_contract = air_export_argv_contract,
            .environment_contract = air_export_environment_contract,
        },
    };
    const cache_key_text = try airGenerationCacheKeyText(allocator, cache_identity);
    defer allocator.free(cache_key_text);
    const cache_key = sha256Hex(cache_key_text);

    if (!options.fresh_export) {
        const cache_start = std.Io.Timestamp.now(io, .awake);
        if (try loadCachedDescriptor(allocator, io, selected_export_cache_root, &cache_key, cache_key_text, mode, candidates)) |descriptor| {
            try printCacheEvent(stdout, mode, "hit", elapsedMs(io, cache_start), &cache_key, descriptor.len);
            return descriptor;
        }
        if (options.require_cache_hit) {
            try printCacheEvent(stdout, mode, "miss-read-only", elapsedMs(io, cache_start), &cache_key, 0);
            return null;
        }
        try pruneOldPinCacheEntries(allocator, io, selected_export_cache_root, ziglang_pin);
    }

    const export_start = std.Io.Timestamp.now(io, .awake);
    const build_argv = [_][]const u8{
        zig_emitter,
        "build",
        "--build-file",
        "../ziglang/build.zig",
        "--cache-dir",
        zig_cache_path,
        "-Dno-bin",
        "-Dno-lib",
        "-Dno-langref",
        "-Ddebug-extensions=true",
        air_export_target_arg,
        zigBuildOptimizeArg(mode),
    };
    const build_result = try std.process.run(allocator, io, .{
        .argv = &build_argv,
        .cwd = .{ .path = execution_cohort.repository_root },
        .environ_map = &env_map,
        .stdout_limit = .limited(16 * 1024 * 1024),
        .stderr_limit = .limited(32 * 1024 * 1024),
    });
    defer {
        allocator.free(build_result.stdout);
        allocator.free(build_result.stderr);
    }
    const duration_ms = elapsedMs(io, export_start);
    if (!helpers.termOk(build_result.term)) {
        try printCacheEvent(stdout, mode, "export-failed", duration_ms, &cache_key, 0);
        return null;
    }

    const descriptor = try std.Io.Dir.cwd().readFileAlloc(io, descriptor_path, allocator, .limited(2 * 1024 * 1024 * 1024));
    errdefer allocator.free(descriptor);
    if (!try descriptorLooksValid(allocator, descriptor, mode, candidates)) {
        try printCacheEvent(stdout, mode, "export-invalid", duration_ms, &cache_key, descriptor.len);
        return null;
    }
    try storeCachedDescriptor(allocator, io, selected_export_cache_root, &cache_key, cache_key_text, ziglang_pin, mode, descriptor);
    try printCacheEvent(stdout, mode, if (options.fresh_export) "fresh-export" else "miss-export", duration_ms, &cache_key, descriptor.len);
    return descriptor;
}

fn loadCachedDescriptor(
    allocator: std.mem.Allocator,
    io: std.Io,
    selected_export_cache_root: []const u8,
    cache_key: *const [64]u8,
    cache_key_text: []const u8,
    mode: Mode,
    candidates: []const Candidate,
) !?[]u8 {
    const meta_path = try cachePath(allocator, selected_export_cache_root, cache_key, ".meta");
    defer allocator.free(meta_path);
    const descriptor_path = try cachePath(allocator, selected_export_cache_root, cache_key, ".air");
    defer allocator.free(descriptor_path);

    const meta = std.Io.Dir.cwd().readFileAlloc(io, meta_path, allocator, .limited(64 * 1024)) catch return null;
    defer allocator.free(meta);
    if (!metadataMatches(meta, cache_key, cache_key_text)) return null;

    const descriptor = std.Io.Dir.cwd().readFileAlloc(io, descriptor_path, allocator, .limited(2 * 1024 * 1024 * 1024)) catch return null;
    errdefer allocator.free(descriptor);
    const expected_hash = metadataValue(meta, "descriptor_sha256") orelse return null;
    const actual_hash = sha256Hex(descriptor);
    if (!std.mem.eql(u8, expected_hash, &actual_hash)) return null;
    if (!try descriptorLooksValid(allocator, descriptor, mode, candidates)) return null;
    return descriptor;
}

fn storeCachedDescriptor(
    allocator: std.mem.Allocator,
    io: std.Io,
    selected_export_cache_root: []const u8,
    cache_key: *const [64]u8,
    cache_key_text: []const u8,
    ziglang_pin: []const u8,
    mode: Mode,
    descriptor: []const u8,
) !void {
    var cwd = std.Io.Dir.cwd();
    try cwd.createDirPath(io, selected_export_cache_root);
    const descriptor_path = try cachePath(allocator, selected_export_cache_root, cache_key, ".air");
    defer allocator.free(descriptor_path);
    const meta_path = try cachePath(allocator, selected_export_cache_root, cache_key, ".meta");
    defer allocator.free(meta_path);

    const descriptor_hash = sha256Hex(descriptor);
    const meta = try std.fmt.allocPrint(
        allocator,
        "schema=3\ncache_key={s}\nziglang_pin={s}\nmode={s}\ndescriptor_sha256={s}\nkey_begin\n{s}key_end\n",
        .{ cache_key, ziglang_pin, mode.name(), &descriptor_hash, cache_key_text },
    );
    defer allocator.free(meta);
    try cwd.writeFile(io, .{ .sub_path = descriptor_path, .data = descriptor });
    try cwd.writeFile(io, .{ .sub_path = meta_path, .data = meta });
}

fn metadataMatches(meta: []const u8, cache_key: *const [64]u8, cache_key_text: []const u8) bool {
    const schema = metadataValue(meta, "schema") orelse return false;
    if (!std.mem.eql(u8, schema, "3")) return false;
    const stored_key = metadataValue(meta, "cache_key") orelse return false;
    if (!std.mem.eql(u8, stored_key, cache_key)) return false;
    const key_begin = std.mem.indexOf(u8, meta, "key_begin\n") orelse return false;
    const key_start = key_begin + "key_begin\n".len;
    const key_end = std.mem.indexOfPos(u8, meta, key_start, "key_end\n") orelse return false;
    return std.mem.eql(u8, meta[key_start..key_end], cache_key_text);
}

fn metadataValue(meta: []const u8, key: []const u8) ?[]const u8 {
    var line_iter = std.mem.splitScalar(u8, meta, '\n');
    while (line_iter.next()) |raw_line| {
        const line = std.mem.trimEnd(u8, raw_line, "\r");
        if (line.len <= key.len or line[key.len] != '=') continue;
        if (std.mem.eql(u8, line[0..key.len], key)) return line[key.len + 1 ..];
    }
    return null;
}

fn pruneOldPinCacheEntries(allocator: std.mem.Allocator, io: std.Io, selected_export_cache_root: []const u8, current_pin: []const u8) !void {
    var cache_dir = std.Io.Dir.cwd().openDir(io, selected_export_cache_root, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => return,
        else => return err,
    };
    defer cache_dir.close(io);

    var iter = cache_dir.iterate();
    while (try iter.next(io)) |entry| {
        if (entry.kind != .file or !std.mem.endsWith(u8, entry.name, ".meta")) continue;
        const stem = entry.name[0 .. entry.name.len - ".meta".len];
        const meta_path = try std.fmt.allocPrint(allocator, "{s}/{s}.meta", .{ selected_export_cache_root, stem });
        defer allocator.free(meta_path);
        const air_path = try std.fmt.allocPrint(allocator, "{s}/{s}.air", .{ selected_export_cache_root, stem });
        defer allocator.free(air_path);

        const meta = std.Io.Dir.cwd().readFileAlloc(io, meta_path, allocator, .limited(64 * 1024)) catch continue;
        defer allocator.free(meta);
        const pin = metadataValue(meta, "ziglang_pin") orelse continue;
        if (std.mem.eql(u8, pin, current_pin)) continue;

        std.Io.Dir.cwd().deleteFile(io, meta_path) catch {};
        std.Io.Dir.cwd().deleteFile(io, air_path) catch {};
    }
}

fn cachePath(allocator: std.mem.Allocator, selected_export_cache_root: []const u8, cache_key: *const [64]u8, suffix: []const u8) ![]const u8 {
    return std.fmt.allocPrint(allocator, "{s}/{s}{s}", .{ selected_export_cache_root, cache_key, suffix });
}

fn descriptorLooksValid(
    allocator: std.mem.Allocator,
    descriptor: []const u8,
    mode: Mode,
    candidates: []const Candidate,
) !bool {
    if (!descriptorHeaderLineEquals(descriptor, "mode", mode.name())) return false;
    if (std.mem.indexOf(u8, descriptor, "\nfunction_count=") == null) return false;
    return try descriptorContainsAllFunctions(allocator, descriptor, candidates);
}

fn descriptorHeaderLineEquals(descriptor: []const u8, key: []const u8, expected: []const u8) bool {
    var line_start: usize = 0;
    while (line_start < descriptor.len) {
        const line_end = std.mem.indexOfScalarPos(u8, descriptor, line_start, '\n') orelse descriptor.len;
        const line = std.mem.trimEnd(u8, descriptor[line_start..line_end], "\r");
        if (std.mem.startsWith(u8, line, "function_count=")) return false;
        if (line.len > key.len and std.mem.eql(u8, line[0..key.len], key) and line[key.len] == '=') {
            return std.mem.eql(u8, line[key.len + 1 ..], expected);
        }
        if (line_end == descriptor.len) break;
        line_start = line_end + 1;
    }
    return false;
}

fn descriptorContainsAllFunctions(
    allocator: std.mem.Allocator,
    descriptor: []const u8,
    candidates: []const Candidate,
) !bool {
    if (candidates.len == 0) return true;
    const found = try allocator.alloc(bool, candidates.len);
    defer allocator.free(found);
    @memset(found, false);
    var found_count: usize = 0;
    var search_start: usize = 0;
    while (std.mem.indexOfPos(u8, descriptor, search_start, "function_begin\n")) |frame_start| {
        const name_line_start = frame_start + "function_begin\n".len;
        const name_line_end = std.mem.indexOfScalarPos(u8, descriptor, name_line_start, '\n') orelse return false;
        const name_len = parseValueLine(usize, descriptor[name_line_start..name_line_end], "name_bytes") catch return false;
        const name_start = name_line_end + 1;
        const name_end = name_start + name_len;
        if (name_end >= descriptor.len) return false;
        const name = descriptor[name_start..name_end];
        const frame_marker_start = std.mem.indexOfPos(u8, descriptor, name_end, "\nfunction_end\n") orelse return false;
        const frame_end = frame_marker_start + "\nfunction_end\n".len;
        for (candidates, 0..) |candidate, index| {
            if (std.mem.eql(u8, name, candidate.function)) {
                if (found[index]) return false;
                found[index] = true;
                found_count += 1;
                break;
            }
        }
        search_start = frame_end;
    }
    return found_count == candidates.len;
}

fn readZiglangPin(allocator: std.mem.Allocator, io: std.Io) ![]const u8 {
    const pin_contents = try std.Io.Dir.cwd().readFileAlloc(io, ziglang_pin_path, allocator, .limited(4096));
    defer allocator.free(pin_contents);
    return try allocator.dupe(u8, std.mem.trim(u8, pin_contents, " \t\r\n"));
}

fn candidateSliceHash(candidates: []const Candidate) [64]u8 {
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    for (candidates) |candidate| {
        hashNumber(&hasher, candidate.rank);
        hasher.update("\t");
        hasher.update(candidate.source);
        hasher.update("\t");
        hasher.update(candidate.function);
        hasher.update("\n");
    }
    var digest: [32]u8 = undefined;
    hasher.final(&digest);
    return std.fmt.bytesToHex(digest, .lower);
}

fn hashNumber(hasher: *std.crypto.hash.sha2.Sha256, value: usize) void {
    var buffer: [32]u8 = undefined;
    const text = std.fmt.bufPrint(&buffer, "{}", .{value}) catch unreachable;
    hasher.update(text);
}

fn sha256Hex(contents: []const u8) [64]u8 {
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(contents, &digest, .{});
    return std.fmt.bytesToHex(digest, .lower);
}

fn elapsedMs(io: std.Io, start: std.Io.Timestamp) i96 {
    const end = std.Io.Timestamp.now(io, .awake);
    return @divTrunc(start.durationTo(end).nanoseconds, std.time.ns_per_ms);
}

fn printCacheEvent(
    writer: *std.Io.Writer,
    mode: Mode,
    status: []const u8,
    duration_ms: i96,
    cache_key: *const [64]u8,
    descriptor_bytes: usize,
) !void {
    try writer.print(
        "air-export-cache mode={s} status={s} duration_ms={} cache_key={s} descriptor_bytes={}\n",
        .{ mode.name(), status, duration_ms, cache_key, descriptor_bytes },
    );
    try writer.flush();
}

const CohortPaths = struct {
    root: []u8,
    home: []u8,
    temporary: []u8,
    local_cache: []u8,
    global_cache: []u8,
    reference_source: []u8,
    linked_source: []u8,
    reference_executable: []u8,
    linked_executable: []u8,

    fn init(allocator: std.mem.Allocator, io: std.Io, temp: TempDir, program: execution_cohort.Program) !CohortPaths {
        const cohort_root = try temp.join(allocator, "execution-cohort-v1");
        defer allocator.free(cohort_root);
        try std.Io.Dir.cwd().createDirPath(io, cohort_root);
        const root = try std.fs.path.join(allocator, &.{ cohort_root, program.functionName() });
        errdefer allocator.free(root);
        try std.Io.Dir.cwd().createDir(io, root, .default_dir);
        const home = try std.fs.path.join(allocator, &.{ root, "home" });
        errdefer allocator.free(home);
        const temporary = try std.fs.path.join(allocator, &.{ root, "tmp" });
        errdefer allocator.free(temporary);
        const local_cache = try std.fs.path.join(allocator, &.{ root, "zig-local-cache" });
        errdefer allocator.free(local_cache);
        const global_cache = try std.fs.path.join(allocator, &.{ root, "zig-global-cache" });
        errdefer allocator.free(global_cache);
        const reference_source = try std.fs.path.join(allocator, &.{ root, "reference.zig" });
        errdefer allocator.free(reference_source);
        const linked_source = try std.fs.path.join(allocator, &.{ root, "linked.zig" });
        errdefer allocator.free(linked_source);
        const reference_executable = try std.fs.path.join(allocator, &.{ root, "reference" });
        errdefer allocator.free(reference_executable);
        const linked_executable = try std.fs.path.join(allocator, &.{ root, "linked" });
        errdefer allocator.free(linked_executable);
        for ([_][]const u8{ home, temporary, local_cache, global_cache }) |path| {
            try std.Io.Dir.cwd().createDir(io, path, .default_dir);
        }
        return .{
            .root = root,
            .home = home,
            .temporary = temporary,
            .local_cache = local_cache,
            .global_cache = global_cache,
            .reference_source = reference_source,
            .linked_source = linked_source,
            .reference_executable = reference_executable,
            .linked_executable = linked_executable,
        };
    }

    fn deinit(paths: *CohortPaths, allocator: std.mem.Allocator) void {
        allocator.free(paths.linked_executable);
        allocator.free(paths.reference_executable);
        allocator.free(paths.linked_source);
        allocator.free(paths.reference_source);
        allocator.free(paths.global_cache);
        allocator.free(paths.local_cache);
        allocator.free(paths.temporary);
        allocator.free(paths.home);
        allocator.free(paths.root);
        paths.* = undefined;
    }
};

fn cohortOptimizeArg(mode: Mode) []const u8 {
    return switch (mode) {
        .ReleaseFast => "-OReleaseFast",
        .ReleaseSafe => "-OReleaseSafe",
        .ReleaseSmall => "-OReleaseSmall",
    };
}

fn absolutePath(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    return std.fs.path.resolve(allocator, &.{ execution_cohort.repository_root, path });
}

fn runCohortPair(
    allocator: std.mem.Allocator,
    io: std.Io,
    stdout: *std.Io.Writer,
    mode: Mode,
    temp: TempDir,
    program: execution_cohort.Program,
    filtered_descriptor: []const u8,
    object: []const u8,
    object_path: []const u8,
    zig_emitter: []const u8,
) !execution_cohort.PairCounters {
    if (!std.fs.path.isAbsolute(zig_emitter)) return error.ExecutionCohortSelectorInvalid;
    var paths = try CohortPaths.init(allocator, io, temp, program);
    defer paths.deinit(allocator);
    const home = try absolutePath(allocator, paths.home);
    defer allocator.free(home);
    const temporary = try absolutePath(allocator, paths.temporary);
    defer allocator.free(temporary);
    const local_cache = try absolutePath(allocator, paths.local_cache);
    defer allocator.free(local_cache);
    const global_cache = try absolutePath(allocator, paths.global_cache);
    defer allocator.free(global_cache);
    const reference_source = try absolutePath(allocator, paths.reference_source);
    defer allocator.free(reference_source);
    const linked_source = try absolutePath(allocator, paths.linked_source);
    defer allocator.free(linked_source);
    const absolute_object = try absolutePath(allocator, object_path);
    defer allocator.free(absolute_object);
    const reference_executable = try absolutePath(allocator, paths.reference_executable);
    defer allocator.free(reference_executable);
    const linked_executable = try absolutePath(allocator, paths.linked_executable);
    defer allocator.free(linked_executable);
    const build_paths: execution_cohort.BuildPaths = .{
        .reference_source = reference_source,
        .linked_source = linked_source,
        .object = absolute_object,
        .reference_executable = reference_executable,
        .linked_executable = linked_executable,
    };
    var environment = try execution_cohort.closedEnvironment(allocator, .{
        .home = home,
        .temporary = temporary,
        .local_cache = local_cache,
        .global_cache = global_cache,
    });
    defer environment.deinit();
    const selector_initial = try execution_cohort.observeSelector(allocator, io, zig_emitter, &environment);
    try execution_cohort.requireSelector(selector_initial);
    try execution_cohort.writeHarnesses(io, program, build_paths);

    var reference_build = try execution_cohort.buildReference(allocator, io, zig_emitter, cohortOptimizeArg(mode), build_paths, &environment);
    defer reference_build.deinit(allocator);
    try execution_cohort.requireExitedZero(reference_build);
    var linked_build = try execution_cohort.buildLinked(allocator, io, zig_emitter, cohortOptimizeArg(mode), build_paths, &environment);
    defer linked_build.deinit(allocator);
    try execution_cohort.requireExitedZero(linked_build);

    const object_identity = try execution_cohort.observeArtifact(allocator, io, absolute_object, false, cohort_object_max_bytes);
    const expected_object_sha = execution_cohort.sha256(object);
    if (object_identity.length != object.len or !std.mem.eql(u8, &object_identity.sha256, &expected_object_sha)) {
        return error.ExecutionCohortObjectMismatch;
    }
    const reference_identity = try execution_cohort.observeArtifact(allocator, io, reference_executable, true, cohort_executable_max_bytes);
    const linked_identity = try execution_cohort.observeArtifact(allocator, io, linked_executable, true, cohort_executable_max_bytes);
    var reference_result = try execution_cohort.runBounded(allocator, io, &.{reference_executable}, &environment);
    defer reference_result.deinit(allocator);
    var linked_result = try execution_cohort.runBounded(allocator, io, &.{linked_executable}, &environment);
    defer linked_result.deinit(allocator);
    const reference_record = try execution_cohort.canonicalProgramExecutionRecord(reference_result, program, true);
    const linked_record = try execution_cohort.canonicalProgramExecutionRecord(linked_result, program, true);
    var pair: execution_cohort.PairCounters = .{};
    try pair.noteBothExecuted(reference_record, linked_record);
    try pair.noteOracleAccepted(reference_record, linked_record);

    const selector_final = try execution_cohort.observeSelector(allocator, io, zig_emitter, &environment);
    try execution_cohort.requireSelector(selector_final);
    if (!std.meta.eql(selector_initial, selector_final) or
        !std.meta.eql(object_identity, try execution_cohort.observeArtifact(allocator, io, absolute_object, false, cohort_object_max_bytes)) or
        !std.meta.eql(reference_identity, try execution_cohort.observeArtifact(allocator, io, reference_executable, true, cohort_executable_max_bytes)) or
        !std.meta.eql(linked_identity, try execution_cohort.observeArtifact(allocator, io, linked_executable, true, cohort_executable_max_bytes)))
    {
        return error.ExecutionCohortIdentityDrift;
    }
    const descriptor_hex = std.fmt.bytesToHex(execution_cohort.sha256(filtered_descriptor), .lower);
    const object_hex = std.fmt.bytesToHex(object_identity.sha256, .lower);
    const reference_hex = std.fmt.bytesToHex(reference_identity.sha256, .lower);
    const linked_hex = std.fmt.bytesToHex(linked_identity.sha256, .lower);
    const result_hex = std.fmt.bytesToHex(reference_record.stdout_sha256, .lower);
    try stdout.print(
        "execution-cohort-row schema={s} mode={s} source={s} function={s} descriptor_sha256={s} object_bytes={} object_sha256={s} reference_bytes={} reference_sha256={s} linked_bytes={} linked_sha256={s} result={} witness={} result_sha256={s} reference_status={} linked_status={} real_executed=1 real_programs_ok=1\n",
        .{
            execution_cohort.schema,
            mode.name(),
            program.denominatorSource(),
            program.functionName(),
            &descriptor_hex,
            object_identity.length,
            &object_hex,
            reference_identity.length,
            &reference_hex,
            linked_identity.length,
            &linked_hex,
            program.expectedResult(),
            program.expectedWitness(),
            &result_hex,
            reference_record.status,
            linked_record.status,
        },
    );
    try stdout.flush();
    return pair;
}

fn runCandidate(
    allocator: std.mem.Allocator,
    io: std.Io,
    init: std.process.Init,
    stdout: *std.Io.Writer,
    mode: Mode,
    temp: TempDir,
    descriptor: []const u8,
    candidate: Candidate,
    candidate_hash: *const [64]u8,
    counters: *Counters,
    zig_emitter: []const u8,
    cohort_tracker: ?*CohortTracker,
) !void {
    const filtered = extractOracleFunctionDescriptor(allocator, descriptor, candidate.function) catch |err| {
        try recordFailure(allocator, stdout, counters, mode, candidate, "air-extract", @errorName(err));
        return;
    };
    defer allocator.free(filtered);
    if (cohortProgram(candidate)) |program| {
        execution_cohort.validateDescriptor(allocator, program, filtered) catch |err| {
            try recordFailure(allocator, stdout, counters, mode, candidate, "cohort-admission", @errorName(err));
            return;
        };
    }

    if (try debugDumpMatches(allocator, init, candidate)) {
        var stderr_buffer: [4096]u8 = undefined;
        var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
        try stderr_writer.interface.print(
            "debug-real-row-ir source={s} function={s} mode={s} candidate_file_hash={s}\n{s}\n",
            .{ candidate.source, candidate.function, mode.name(), candidate_hash, filtered },
        );
        try stderr_writer.interface.flush();
    }

    var outcome = try lowerOracleFunctionToObject(allocator, filtered);
    defer outcome.deinit(allocator);
    const object = switch (outcome) {
        .failure => |failure| {
            if (failure.function_lowered) counters.real_functions_lowered += 1;
            try recordFailure(allocator, stdout, counters, mode, candidate, failure.stage, failure.diagnostic);
            return;
        },
        .success => |object| object,
    };
    counters.real_functions_lowered += 1;
    counters.real_objects_emitted += 1;

    const object_path = try allocTempFile(allocator, temp, candidate.function, ".o");
    defer allocator.free(object_path);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = object_path, .data = object });
    const exe_path = try allocTempFile(allocator, temp, candidate.function, ".link");
    defer allocator.free(exe_path);
    const link_result = try helpers.nativeLinkObject(allocator, io, zig_emitter, mode, object_path, exe_path);
    defer {
        allocator.free(link_result.stdout);
        allocator.free(link_result.stderr);
    }
    if (!helpers.termOk(link_result.term)) {
        try recordFailure(allocator, stdout, counters, mode, candidate, "native-link", "native-link-nonzero");
        return;
    }
    counters.real_native_linked += 1;
    if (cohort_tracker) |tracker| if (cohortProgram(candidate)) |program| {
        const pair = runCohortPair(
            allocator,
            io,
            stdout,
            mode,
            temp,
            program,
            filtered,
            object,
            object_path,
            zig_emitter,
        ) catch |failure| {
            try recordFailure(allocator, stdout, counters, mode, candidate, "paired-execution", @errorName(failure));
            return;
        };
        tracker.record(program, pair) catch |failure| {
            try recordFailure(allocator, stdout, counters, mode, candidate, "paired-execution-credit", @errorName(failure));
            return;
        };
    };
}

pub const OracleObjectFailure = struct {
    stage: []const u8,
    diagnostic: []u8,
    function_lowered: bool,
};

pub const OracleObjectOutcome = union(enum) {
    success: []u8,
    failure: OracleObjectFailure,

    pub fn deinit(self: *OracleObjectOutcome, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .success => |object| allocator.free(object),
            .failure => |failure| allocator.free(failure.diagnostic),
        }
        self.* = undefined;
    }
};

pub fn lowerOracleFunctionToObject(
    allocator: std.mem.Allocator,
    filtered_descriptor: []const u8,
) !OracleObjectOutcome {
    var parsed = air_export.parse(allocator, filtered_descriptor) catch |err| return .{ .failure = .{
        .stage = "typed-lowering",
        .diagnostic = try allocator.dupe(u8, @errorName(err)),
        .function_lowered = false,
    } };
    defer parsed.deinit();

    var lowered = air_lowering.lowerCompatible(allocator, parsed) catch |err| return .{ .failure = .{
        .stage = "typed-lowering",
        .diagnostic = try allocator.dupe(u8, @errorName(err)),
        .function_lowered = false,
    } };
    defer lowered.deinit();
    if (lowered.accepted_functions != 1 or lowered.unsupported.len != 0 or lowered.module.functions.items.len != 1) {
        const diagnostic = if (lowered.unsupported.len != 0)
            try std.fmt.allocPrint(allocator, "unsupported:{s}:{s}", .{
                @tagName(lowered.unsupported[0].reason),
                lowered.unsupported[0].opcode,
            })
        else
            try allocator.dupe(u8, "unexpected-lowering-result");
        return .{ .failure = .{
            .stage = "typed-lowering",
            .diagnostic = diagnostic,
            .function_lowered = false,
        } };
    }

    var machine = codegen.x86_64.lowerFunction(
        allocator,
        target_triple,
        lowered.module.functions.items[0],
    ) catch |err| return .{ .failure = .{
        .stage = "object-emission",
        .diagnostic = try std.fmt.allocPrint(allocator, "x86_64-lower:{s}", .{@errorName(err)}),
        .function_lowered = true,
    } };
    defer machine.deinit(allocator);
    const machines = [_]codegen.x86_64.MachineFunction{machine};
    const object = mc.elf.buildObjectWithModuleData(
        allocator,
        &machines,
        lowered.module.aliases.items,
        lowered.module.globals.items,
    ) catch |err| return .{ .failure = .{
        .stage = "object-emission",
        .diagnostic = try std.fmt.allocPrint(allocator, "elf-object:{s}", .{@errorName(err)}),
        .function_lowered = true,
    } };
    return .{ .success = object };
}

pub fn extractOracleFunctionDescriptor(allocator: std.mem.Allocator, descriptor: []const u8, function_name: []const u8) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);
    try appendHeader(allocator, &out, descriptor);

    var search_start: usize = 0;
    while (std.mem.indexOfPos(u8, descriptor, search_start, "function_begin\n")) |frame_start| {
        const name_line_start = frame_start + "function_begin\n".len;
        const name_line_end = std.mem.indexOfScalarPos(u8, descriptor, name_line_start, '\n') orelse return error.InvalidAirFrame;
        const name_len = try parseValueLine(usize, descriptor[name_line_start..name_line_end], "name_bytes");
        const name_start = name_line_end + 1;
        const name_end = name_start + name_len;
        if (name_end >= descriptor.len) return error.InvalidAirFrame;
        const name = descriptor[name_start..name_end];
        const frame_marker_start = std.mem.indexOfPos(u8, descriptor, name_end, "\nfunction_end\n") orelse return error.InvalidAirFrame;
        const frame_end = frame_marker_start + "\nfunction_end\n".len;
        if (std.mem.eql(u8, name, function_name)) {
            try out.appendSlice(allocator, descriptor[frame_start..frame_end]);
            return out.toOwnedSlice(allocator);
        }
        search_start = frame_end;
    }
    return error.FunctionNotFound;
}

fn appendHeader(allocator: std.mem.Allocator, out: *std.ArrayList(u8), descriptor: []const u8) !void {
    try appendLineByKey(allocator, out, descriptor, null);
    try appendLineByKey(allocator, out, descriptor, "contract_version");
    try appendLineByKey(allocator, out, descriptor, "payload");
    try appendLineByKey(allocator, out, descriptor, "producer");
    try appendLineByKey(allocator, out, descriptor, "root_source");
    try appendLineByKey(allocator, out, descriptor, "wrapper");
    try appendLineByKey(allocator, out, descriptor, "mode");
    try appendLineByKey(allocator, out, descriptor, "target");
    try out.appendSlice(allocator, "function_count=1\n");
    try out.appendSlice(allocator, "global_count=0\n");
    _ = try appendOptionalFramedByKey(allocator, out, descriptor, "aggregate_layout_facts_bytes");
    _ = try appendOptionalFramedByKey(allocator, out, descriptor, "error_union_call_facts_bytes");
}

fn appendLineByKey(
    allocator: std.mem.Allocator,
    out: *std.ArrayList(u8),
    descriptor: []const u8,
    maybe_key: ?[]const u8,
) !void {
    if (maybe_key == null) {
        const end = std.mem.indexOfScalar(u8, descriptor, '\n') orelse return error.InvalidAirHeader;
        try out.appendSlice(allocator, descriptor[0 .. end + 1]);
        return;
    }
    const key = maybe_key.?;
    var line_start: usize = 0;
    while (line_start < descriptor.len) {
        const line_end = std.mem.indexOfScalarPos(u8, descriptor, line_start, '\n') orelse descriptor.len;
        const line = descriptor[line_start..line_end];
        if (std.mem.startsWith(u8, line, key) and line.len > key.len and line[key.len] == '=') {
            try out.appendSlice(allocator, descriptor[line_start..line_end]);
            try out.append(allocator, '\n');
            return;
        }
        if (std.mem.startsWith(u8, line, "function_count=")) break;
        line_start = line_end + 1;
    }
    return error.InvalidAirHeader;
}

fn appendOptionalFramedByKey(
    allocator: std.mem.Allocator,
    out: *std.ArrayList(u8),
    descriptor: []const u8,
    key: []const u8,
) !bool {
    var line_start: usize = 0;
    while (line_start < descriptor.len) {
        const line_end = std.mem.indexOfScalarPos(u8, descriptor, line_start, '\n') orelse descriptor.len;
        const line = descriptor[line_start..line_end];
        if (std.mem.startsWith(u8, line, "function_begin")) return false;
        if (std.mem.startsWith(u8, line, key) and line.len > key.len and line[key.len] == '=') {
            const len = try parseValueLine(usize, line, key);
            const value_start = line_end + 1;
            const value_end = value_start + len;
            if (value_end >= descriptor.len or descriptor[value_end] != '\n') return error.InvalidAirHeader;
            try out.appendSlice(allocator, descriptor[line_start .. value_end + 1]);
            return true;
        }
        line_start = line_end + 1;
    }
    return false;
}

fn parseValueLine(comptime T: type, line: []const u8, key: []const u8) !T {
    if (!std.mem.startsWith(u8, line, key) or line.len <= key.len or line[key.len] != '=') return error.InvalidValueLine;
    return std.fmt.parseUnsigned(T, line[key.len + 1 ..], 10);
}

fn setFirstFailure(allocator: std.mem.Allocator, counters: *Counters, candidate: Candidate, stage: []const u8) !void {
    if (counters.first_failing_real_row != null) return;
    counters.first_failing_real_row = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ candidate.source, candidate.function });
    counters.first_failing_stage = try allocator.dupe(u8, stage);
}

fn recordFailure(
    allocator: std.mem.Allocator,
    writer: *std.Io.Writer,
    counters: *Counters,
    mode: Mode,
    candidate: Candidate,
    stage: []const u8,
    diagnostic: []const u8,
) !void {
    try setFirstFailure(allocator, counters, candidate, stage);
    try writer.print(
        "real-row-failure mode={s} rank={} source={s} function={s} stage={s} diagnostic={s}\n",
        .{ mode.name(), candidate.rank, candidate.source, candidate.function, stage, diagnostic },
    );
    try writer.flush();
}

fn zigBuildOptimizeArg(mode: Mode) []const u8 {
    return switch (mode) {
        .ReleaseFast => "-Doptimize=ReleaseFast",
        .ReleaseSafe => "-Doptimize=ReleaseSafe",
        .ReleaseSmall => "-Doptimize=ReleaseSmall",
    };
}

fn allocTempFile(
    allocator: std.mem.Allocator,
    temp: TempDir,
    stem_text: []const u8,
    suffix: []const u8,
) ![]const u8 {
    const stem = try safeStem(allocator, stem_text);
    defer allocator.free(stem);
    const name = try std.fmt.allocPrint(allocator, "{s}{s}", .{ stem, suffix });
    defer allocator.free(name);
    return temp.join(allocator, name);
}

fn safeStem(allocator: std.mem.Allocator, text: []const u8) ![]const u8 {
    const stem = try allocator.dupe(u8, text);
    for (stem) |*byte| {
        if (!std.ascii.isAlphanumeric(byte.*) and byte.* != '_' and byte.* != '.' and byte.* != '-') {
            byte.* = '_';
        }
    }
    return stem;
}

fn printSummary(writer: *std.Io.Writer, counters: Counters, candidate_hash: *const [64]u8) !void {
    try writer.print(
        "summary distribution-real-rows counter_schema={s} mode={s} selector_version={s} candidate_file_hash={s} limit={} candidate_rows={} real_functions_lowered={} real_objects_emitted={} real_native_linked={} real_executed={} real_programs_ok={} first_failing_real_row={s} first_failing_stage={s} local_fail={}\n",
        .{
            counter_schema_version,
            counters.mode.name(),
            selector_version,
            candidate_hash,
            counters.limit,
            counters.candidate_rows,
            counters.real_functions_lowered,
            counters.real_objects_emitted,
            counters.real_native_linked,
            counters.real_executed,
            counters.real_programs_ok,
            counters.first_failing_real_row orelse "-",
            counters.first_failing_stage orelse "-",
            @intFromBool(counters.hasFailure()),
        },
    );
}

fn candidateFileHash(contents: []const u8) [64]u8 {
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(contents, &digest, .{});
    return std.fmt.bytesToHex(digest, .lower);
}

fn readStage4Emitter(allocator: std.mem.Allocator, io: std.Io, init: std.process.Init) ![]const u8 {
    const zig_emitter_env = init.minimal.environ.getAlloc(allocator, "ZIG_EMITTER") catch |err| switch (err) {
        error.EnvironmentVariableMissing => null,
        else => return err,
    };
    const zig_emitter = zig_emitter_env orelse try allocator.dupe(u8, "../ziglang/build/stage4/bin/zig");
    errdefer allocator.free(zig_emitter);
    std.Io.Dir.cwd().access(io, zig_emitter, .{ .execute = true }) catch {
        try validationError(io, "missing executable Zig emitter: {s}\n", .{zig_emitter});
    };
    return zig_emitter;
}

fn debugDumpMatches(allocator: std.mem.Allocator, init: std.process.Init, candidate: Candidate) !bool {
    const needle = init.minimal.environ.getAlloc(allocator, "ZLLVM_DEBUG_DUMP_IR_SOURCE") catch |err| switch (err) {
        error.EnvironmentVariableMissing => return false,
        else => return err,
    };
    defer allocator.free(needle);
    return std.mem.indexOf(u8, candidate.source, needle) != null or
        std.mem.indexOf(u8, candidate.function, needle) != null;
}

fn validationError(io: std.Io, comptime fmt: []const u8, args: anytype) !noreturn {
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    try stderr_writer.interface.print(fmt, args);
    try stderr_writer.interface.flush();
    std.process.exit(1);
}
