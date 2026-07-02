const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_lowering = @import("zig_air_lowering.zig");
const codegen = @import("codegen.zig");
const mc = @import("mc.zig");
const helpers = @import("uncurated_air_gate_helpers.zig");

const selector_version = "real-candidate-selector-v1";
const default_candidate_path = "docs/evidence/real_candidates_releasefast_v1.tsv";
const target_triple = "x86_64-unknown-linux-gnu";
const Mode = helpers.Mode;

const TempDir = struct {
    path: []const u8,

    fn init(allocator: std.mem.Allocator, io: std.Io, prefix: []const u8) !TempDir {
        var cwd = std.Io.Dir.cwd();
        try cwd.createDirPath(io, "tmp");
        const path = try std.fmt.allocPrint(allocator, "tmp/{s}_{}", .{ prefix, std.os.linux.getpid() });
        errdefer allocator.free(path);
        cwd.deleteTree(io, path) catch {};
        try cwd.createDirPath(io, path);
        return .{ .path = path };
    }

    fn deinit(temp: TempDir, allocator: std.mem.Allocator, io: std.Io) void {
        std.Io.Dir.cwd().deleteTree(io, temp.path) catch {};
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
        var counters = try runMode(allocator, io, init, mode, options, candidates.items, &candidate_hash);
        defer {
            if (counters.first_failing_real_row) |value| allocator.free(value);
            if (counters.first_failing_stage) |value| allocator.free(value);
        }
        any_failure = any_failure or counters.hasFailure();
        try printSummary(&stdout_writer.interface, counters, &candidate_hash);
        try stdout_writer.interface.flush();
    }

    if (options.strict and any_failure) std.process.exit(1);
}

fn parseOptions(allocator: std.mem.Allocator, io: std.Io, init: std.process.Init) !Options {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();

    var options: Options = .{};
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--strict")) {
            options.strict = true;
        } else if (std.mem.startsWith(u8, arg, "--limit=")) {
            options.limit = try std.fmt.parseUnsigned(usize, arg["--limit=".len..], 10);
        } else if (std.mem.startsWith(u8, arg, "--candidate-file=")) {
            options.candidate_path = arg["--candidate-file=".len..];
        } else {
            try validationError(io, "unexpected argument: {s}\n", .{arg});
        }
    }
    if (options.limit == 0) try validationError(io, "--limit must be greater than zero\n", .{});
    return options;
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

    const temp = try TempDir.init(allocator, io, "distribution_real_rows");
    defer temp.deinit(allocator, io);
    const descriptor_path = try temp.join(allocator, "compiler.air");
    defer allocator.free(descriptor_path);
    const zig_cache_path = try temp.join(allocator, "zig-cache");
    defer allocator.free(zig_cache_path);
    const zig_emitter = try readStage4Emitter(allocator, io, init);
    defer allocator.free(zig_emitter);

    var env_map = try helpers.cloneEnvironment(allocator, init.environ_map);
    defer env_map.deinit();
    try env_map.put("ZLLVM_AIR_EXPORT_PATH", descriptor_path);
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
        "-Dtarget=x86_64-linux-gnu",
        zigBuildOptimizeArg(mode),
    };
    const build_result = try std.process.run(allocator, io, .{
        .argv = &build_argv,
        .environ_map = &env_map,
        .stdout_limit = .limited(16 * 1024 * 1024),
        .stderr_limit = .limited(32 * 1024 * 1024),
    });
    defer {
        allocator.free(build_result.stdout);
        allocator.free(build_result.stderr);
    }
    if (!helpers.termOk(build_result.term)) {
        for (candidates) |candidate| try setFirstFailure(allocator, &counters, candidate, "air-export");
        return counters;
    }

    const descriptor = try std.Io.Dir.cwd().readFileAlloc(io, descriptor_path, allocator, .limited(2 * 1024 * 1024 * 1024));
    defer allocator.free(descriptor);
    for (candidates) |candidate| {
        try runCandidate(allocator, io, init, mode, temp, descriptor, candidate, candidate_hash, &counters, zig_emitter);
    }
    return counters;
}

fn runCandidate(
    allocator: std.mem.Allocator,
    io: std.Io,
    init: std.process.Init,
    mode: Mode,
    temp: TempDir,
    descriptor: []const u8,
    candidate: Candidate,
    candidate_hash: *const [64]u8,
    counters: *Counters,
    zig_emitter: []const u8,
) !void {
    const filtered = extractFunctionDescriptor(allocator, descriptor, candidate.function) catch {
        try setFirstFailure(allocator, counters, candidate, "air-extract");
        return;
    };
    defer allocator.free(filtered);

    if (try debugDumpMatches(allocator, init, candidate)) {
        var stderr_buffer: [4096]u8 = undefined;
        var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
        try stderr_writer.interface.print(
            "debug-real-row-ir source={s} function={s} mode={s} candidate_file_hash={s}\n{s}\n",
            .{ candidate.source, candidate.function, mode.name(), candidate_hash, filtered },
        );
        try stderr_writer.interface.flush();
    }

    var parsed = air_export.parse(allocator, filtered) catch {
        try setFirstFailure(allocator, counters, candidate, "typed-lowering");
        return;
    };
    defer parsed.deinit();

    var lowered = air_lowering.lowerCompatible(allocator, parsed) catch {
        try setFirstFailure(allocator, counters, candidate, "typed-lowering");
        return;
    };
    defer lowered.deinit();
    if (lowered.accepted_functions != 1 or lowered.unsupported.len != 0 or lowered.module.functions.items.len != 1) {
        try setFirstFailure(allocator, counters, candidate, "typed-lowering");
        return;
    }
    counters.real_functions_lowered += 1;

    var machine = codegen.x86_64.lowerFunction(
        allocator,
        target_triple,
        lowered.module.functions.items[0],
    ) catch {
        try setFirstFailure(allocator, counters, candidate, "object-emission");
        return;
    };
    defer machine.deinit(allocator);
    const machines = [_]codegen.x86_64.MachineFunction{machine};
    const object = mc.elf.buildObjectWithModuleData(
        allocator,
        &machines,
        lowered.module.aliases.items,
        lowered.module.globals.items,
    ) catch {
        try setFirstFailure(allocator, counters, candidate, "object-emission");
        return;
    };
    defer allocator.free(object);
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
        try setFirstFailure(allocator, counters, candidate, "native-link");
        return;
    }
    counters.real_native_linked += 1;

    if (!executionQualified(candidate)) return;
    const run_result = try helpers.runExecutable(allocator, io, exe_path);
    defer {
        allocator.free(run_result.stdout);
        allocator.free(run_result.stderr);
    }
    counters.real_executed += 1;
    if (helpers.termOk(run_result.term)) {
        counters.real_programs_ok += 1;
    } else {
        try setFirstFailure(allocator, counters, candidate, "execute");
    }
}

fn extractFunctionDescriptor(allocator: std.mem.Allocator, descriptor: []const u8, function_name: []const u8) ![]u8 {
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

fn parseValueLine(comptime T: type, line: []const u8, key: []const u8) !T {
    if (!std.mem.startsWith(u8, line, key) or line.len <= key.len or line[key.len] != '=') return error.InvalidValueLine;
    return std.fmt.parseUnsigned(T, line[key.len + 1 ..], 10);
}

fn setFirstFailure(allocator: std.mem.Allocator, counters: *Counters, candidate: Candidate, stage: []const u8) !void {
    if (counters.first_failing_real_row != null) return;
    counters.first_failing_real_row = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ candidate.source, candidate.function });
    counters.first_failing_stage = try allocator.dupe(u8, stage);
}

fn executionQualified(candidate: Candidate) bool {
    return std.mem.startsWith(u8, candidate.harnessable_reason, "harnessable:") and
        !std.mem.eql(u8, candidate.determinism, "assumed_nondeterministic") and
        std.mem.eql(u8, candidate.signature_class, "C-ABI-stable");
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
        "summary distribution-real-rows mode={s} selector_version={s} candidate_file_hash={s} limit={} candidate_rows={} real_functions_lowered={} real_objects_emitted={} real_native_linked={} real_executed={} real_programs_ok={} first_failing_real_row={s} first_failing_stage={s} local_fail={}\n",
        .{
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
