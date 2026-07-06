const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_lowering = @import("zig_air_lowering.zig");
const codegen = @import("codegen.zig");
const mc = @import("mc.zig");
const helpers = @import("uncurated_air_gate_helpers.zig");

const selector_version = "real-candidate-selector-v2";
const default_candidate_path = "docs/evidence/real_candidates_release_v2.tsv";
const ziglang_pin_path = "docs/evidence/ziglang_pin.txt";
const export_cache_dir = "tmp/real_rows_air_export_cache";
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
    mode: ?Mode = null,
    fresh_export: bool = false,
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
        if (options.mode) |selected| {
            if (mode != selected) continue;
        }
        var counters = try runMode(allocator, io, init, &stdout_writer.interface, mode, options, candidates.items, &candidate_hash);
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
        } else if (std.mem.eql(u8, arg, "--fresh-export")) {
            options.fresh_export = true;
        } else if (std.mem.startsWith(u8, arg, "--limit=")) {
            options.limit = try std.fmt.parseUnsigned(usize, arg["--limit=".len..], 10);
        } else if (std.mem.startsWith(u8, arg, "--mode=")) {
            options.mode = try parseMode(io, arg["--mode=".len..]);
        } else if (std.mem.startsWith(u8, arg, "--candidate-file=")) {
            options.candidate_path = arg["--candidate-file=".len..];
        } else {
            try validationError(io, "unexpected argument: {s}\n", .{arg});
        }
    }
    if (options.limit == 0) try validationError(io, "--limit must be greater than zero\n", .{});
    return options;
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

    const temp = try TempDir.init(allocator, io, "distribution_real_rows");
    defer temp.deinit(allocator, io);
    const descriptor_path = try temp.join(allocator, "compiler.air");
    defer allocator.free(descriptor_path);
    const zig_cache_path = try temp.join(allocator, "zig-cache");
    defer allocator.free(zig_cache_path);
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
        candidate_hash,
        descriptor_path,
        zig_cache_path,
        zig_emitter,
    ) orelse {
        for (candidates) |candidate| try setFirstFailure(allocator, &counters, candidate, "air-export");
        return counters;
    };
    defer allocator.free(descriptor);
    for (candidates) |candidate| {
        try runCandidate(allocator, io, init, stdout, mode, temp, descriptor, candidate, candidate_hash, &counters, zig_emitter);
    }
    return counters;
}

fn loadOrExportDescriptor(
    allocator: std.mem.Allocator,
    io: std.Io,
    init: std.process.Init,
    stdout: *std.Io.Writer,
    mode: Mode,
    options: Options,
    candidates: []const Candidate,
    candidate_hash: *const [64]u8,
    descriptor_path: []const u8,
    zig_cache_path: []const u8,
    zig_emitter: []const u8,
) !?[]u8 {
    const ziglang_pin = try readZiglangPin(allocator, io);
    defer allocator.free(ziglang_pin);
    const stage4_version = try readStage4Version(allocator, io, zig_emitter);
    defer allocator.free(stage4_version);
    const z_llvm_export_state = try exporterRelevantStateHash(allocator, io);
    const slice_hash = candidateSliceHash(candidates);
    const cache_key_text = try std.fmt.allocPrint(
        allocator,
        "schema=1\nziglang_pin={s}\nstage4_version={s}\nz_llvm_export_state={s}\nmode={s}\nselector_version={s}\ncandidate_file_hash={s}\nlimit={}\nslice_hash={s}\n",
        .{
            ziglang_pin,
            stage4_version,
            &z_llvm_export_state,
            mode.name(),
            selector_version,
            candidate_hash,
            options.limit,
            &slice_hash,
        },
    );
    defer allocator.free(cache_key_text);
    const cache_key = sha256Hex(cache_key_text);

    if (!options.fresh_export) {
        const cache_start = std.Io.Timestamp.now(io, .awake);
        if (try loadCachedDescriptor(allocator, io, &cache_key, cache_key_text, mode, candidates)) |descriptor| {
            try printCacheEvent(stdout, mode, "hit", elapsedMs(io, cache_start), &cache_key, descriptor.len);
            return descriptor;
        }
        try pruneOldPinCacheEntries(allocator, io, ziglang_pin);
    }

    const export_start = std.Io.Timestamp.now(io, .awake);
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
    try storeCachedDescriptor(allocator, io, &cache_key, cache_key_text, descriptor);
    try printCacheEvent(stdout, mode, if (options.fresh_export) "fresh-export" else "miss-export", duration_ms, &cache_key, descriptor.len);
    return descriptor;
}

fn loadCachedDescriptor(
    allocator: std.mem.Allocator,
    io: std.Io,
    cache_key: *const [64]u8,
    cache_key_text: []const u8,
    mode: Mode,
    candidates: []const Candidate,
) !?[]u8 {
    const meta_path = try cachePath(allocator, cache_key, ".meta");
    defer allocator.free(meta_path);
    const descriptor_path = try cachePath(allocator, cache_key, ".air");
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
    cache_key: *const [64]u8,
    cache_key_text: []const u8,
    descriptor: []const u8,
) !void {
    var cwd = std.Io.Dir.cwd();
    try cwd.createDirPath(io, export_cache_dir);
    const descriptor_path = try cachePath(allocator, cache_key, ".air");
    defer allocator.free(descriptor_path);
    const meta_path = try cachePath(allocator, cache_key, ".meta");
    defer allocator.free(meta_path);

    const descriptor_hash = sha256Hex(descriptor);
    const meta = try std.fmt.allocPrint(
        allocator,
        "schema=1\ncache_key={s}\ndescriptor_sha256={s}\nkey_begin\n{s}key_end\n",
        .{ cache_key, &descriptor_hash, cache_key_text },
    );
    defer allocator.free(meta);
    try cwd.writeFile(io, .{ .sub_path = descriptor_path, .data = descriptor });
    try cwd.writeFile(io, .{ .sub_path = meta_path, .data = meta });
}

fn metadataMatches(meta: []const u8, cache_key: *const [64]u8, cache_key_text: []const u8) bool {
    const schema = metadataValue(meta, "schema") orelse return false;
    if (!std.mem.eql(u8, schema, "1")) return false;
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

fn pruneOldPinCacheEntries(allocator: std.mem.Allocator, io: std.Io, current_pin: []const u8) !void {
    var cache_dir = std.Io.Dir.cwd().openDir(io, export_cache_dir, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => return,
        else => return err,
    };
    defer cache_dir.close(io);

    var iter = cache_dir.iterate();
    while (try iter.next(io)) |entry| {
        if (entry.kind != .file or !std.mem.endsWith(u8, entry.name, ".meta")) continue;
        const stem = entry.name[0 .. entry.name.len - ".meta".len];
        const meta_path = try std.fmt.allocPrint(allocator, "{s}/{s}.meta", .{ export_cache_dir, stem });
        defer allocator.free(meta_path);
        const air_path = try std.fmt.allocPrint(allocator, "{s}/{s}.air", .{ export_cache_dir, stem });
        defer allocator.free(air_path);

        const meta = std.Io.Dir.cwd().readFileAlloc(io, meta_path, allocator, .limited(64 * 1024)) catch continue;
        defer allocator.free(meta);
        const pin = metadataValue(meta, "ziglang_pin") orelse continue;
        if (std.mem.eql(u8, pin, current_pin)) continue;

        std.Io.Dir.cwd().deleteFile(io, meta_path) catch {};
        std.Io.Dir.cwd().deleteFile(io, air_path) catch {};
    }
}

fn cachePath(allocator: std.mem.Allocator, cache_key: *const [64]u8, suffix: []const u8) ![]const u8 {
    return std.fmt.allocPrint(allocator, "{s}/{s}{s}", .{ export_cache_dir, cache_key, suffix });
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
            if (!found[index] and std.mem.eql(u8, name, candidate.function)) {
                found[index] = true;
                found_count += 1;
                if (found_count == candidates.len) return true;
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

fn readStage4Version(allocator: std.mem.Allocator, io: std.Io, zig_emitter: []const u8) ![]const u8 {
    const argv = [_][]const u8{ zig_emitter, "version" };
    const result = try std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(1024 * 1024),
        .stderr_limit = .limited(1024 * 1024),
    });
    defer {
        allocator.free(result.stdout);
        allocator.free(result.stderr);
    }
    if (!helpers.termOk(result.term)) return error.Stage4VersionFailed;
    return try allocator.dupe(u8, std.mem.trim(u8, result.stdout, " \t\r\n"));
}

fn exporterRelevantStateHash(allocator: std.mem.Allocator, io: std.Io) ![64]u8 {
    const files = [_][]const u8{
        "src/distribution_real_rows_gate.zig",
        "src/zig_air_export.zig",
        "docs/evidence/ziglang_pin.txt",
    };
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    for (files) |path| {
        hasher.update(path);
        hasher.update("\n");
        const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(32 * 1024 * 1024));
        defer allocator.free(contents);
        hasher.update(contents);
        hasher.update("\n");
    }
    var digest: [32]u8 = undefined;
    hasher.final(&digest);
    return std.fmt.bytesToHex(digest, .lower);
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
) !void {
    const filtered = extractFunctionDescriptor(allocator, descriptor, candidate.function) catch |err| {
        try recordFailure(allocator, stdout, counters, mode, candidate, "air-extract", @errorName(err));
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

    var parsed = air_export.parse(allocator, filtered) catch |err| {
        try recordFailure(allocator, stdout, counters, mode, candidate, "typed-lowering", @errorName(err));
        return;
    };
    defer parsed.deinit();

    var lowered = air_lowering.lowerCompatible(allocator, parsed) catch |err| {
        try recordFailure(allocator, stdout, counters, mode, candidate, "typed-lowering", @errorName(err));
        return;
    };
    defer lowered.deinit();
    if (lowered.accepted_functions != 1 or lowered.unsupported.len != 0 or lowered.module.functions.items.len != 1) {
        const diagnostic = if (lowered.unsupported.len != 0)
            try std.fmt.allocPrint(allocator, "unsupported:{s}:{s}", .{
                @tagName(lowered.unsupported[0].reason),
                lowered.unsupported[0].opcode,
            })
        else
            try allocator.dupe(u8, "unexpected-lowering-result");
        defer allocator.free(diagnostic);
        try recordFailure(allocator, stdout, counters, mode, candidate, "typed-lowering", diagnostic);
        return;
    }
    counters.real_functions_lowered += 1;

    var machine = codegen.x86_64.lowerFunction(
        allocator,
        target_triple,
        lowered.module.functions.items[0],
    ) catch |err| {
        const diagnostic = try std.fmt.allocPrint(allocator, "x86_64-lower:{s}", .{@errorName(err)});
        defer allocator.free(diagnostic);
        try recordFailure(allocator, stdout, counters, mode, candidate, "object-emission", diagnostic);
        return;
    };
    defer machine.deinit(allocator);
    const machines = [_]codegen.x86_64.MachineFunction{machine};
    const object = mc.elf.buildObjectWithModuleData(
        allocator,
        &machines,
        lowered.module.aliases.items,
        lowered.module.globals.items,
    ) catch |err| {
        const diagnostic = try std.fmt.allocPrint(allocator, "elf-object:{s}", .{@errorName(err)});
        defer allocator.free(diagnostic);
        try recordFailure(allocator, stdout, counters, mode, candidate, "object-emission", diagnostic);
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
        try recordFailure(allocator, stdout, counters, mode, candidate, "native-link", "native-link-nonzero");
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
        try recordFailure(allocator, stdout, counters, mode, candidate, "execute", "execute-nonzero");
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
