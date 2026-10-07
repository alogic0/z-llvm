const std = @import("std");

const Sha1 = std.crypto.hash.Sha1;
const Sha256 = std.crypto.hash.sha2.Sha256;

pub const generation_root = "local-state/validations/inbox206co/generation-v6";
pub const dispatch_mode = "--accept-generation-v6";
pub const receipt_name = "execution-oracle-v1-acceptance-v2.tsv";

const repository_root = "/home/oleg/prog/z_llvm";
const external_revision_hex = "bdee02bc0c7f227c0f11bc9a449df673fe803540";
const receipt_schema = "execution-oracle-v1-acceptance-v2";
const source_mode: u32 = 0o100644;
const source_max_bytes = 8 * 1024 * 1024;
const process_output_max = 8 * 1024 * 1024;
const receipt_max_bytes = 32 * 1024;
const selector_version_max_bytes = 128;

pub const source_count = 5;
pub const source_paths = [source_count][]const u8{
    "build.zig",
    "src/distribution_real_rows_gate.zig",
    "src/zig_air_export.zig",
    "src/execution_oracle_v1.zig",
    "src/execution_oracle_v1_acceptance.zig",
};

const listing_order = [source_count]usize{ 0, 1, 3, 4, 2 };
const expected_status = [source_count]StagedStatus{ .modified, .modified, .modified, .added, .added };

pub const Identity20 = struct { bytes: [20]u8 };
pub const Identity32 = struct { bytes: [32]u8 };

pub const SourceIdentity = struct {
    mode: u32,
    blob: Identity20,
    raw_sha256: Identity32,
    length: u64,
};

pub const StagedStatus = enum { added, modified };

pub const StructuredClosure = struct {
    sources: [source_count]SourceIdentity,
    statuses: [source_count]StagedStatus,
    staged_tree: Identity20,
};

pub const SelectorIdentity = struct {
    version: [selector_version_max_bytes]u8,
    version_length: u8,
    length: u64,
    sha256: Identity32,

    pub fn init(version: []const u8, length: u64, digest: [32]u8) !SelectorIdentity {
        if (version.len == 0 or version.len > selector_version_max_bytes or
            std.mem.indexOfAny(u8, version, "\x00\t\r\n") != null)
        {
            return error.SelectorEvidenceInvalid;
        }
        var result: SelectorIdentity = .{
            .version = @splat(0),
            .version_length = @intCast(version.len),
            .length = length,
            .sha256 = .{ .bytes = digest },
        };
        @memcpy(result.version[0..version.len], version);
        try validateSelector(&result);
        return result;
    }

    pub fn versionSlice(self: *const SelectorIdentity) []const u8 {
        return self.version[0..self.version_length];
    }
};

pub const SourceEvidence = struct {
    definition_sha256: Identity32,
    import_sha256: Identity32,
    use_sha256: Identity32,
    definition_count: u64,
    use_count: u64,
};

pub const CandidateConvention = enum { default, c };
pub const BridgeConvention = enum { x86_64_sysv, c, auto };
pub const BridgeResult = enum { usize, u64 };
pub const Target = enum { x86_64_linux_gnu };

pub const DescriptorEvidence = struct {
    descriptor_sha256: Identity32,
    function_type_sha256: Identity32,
    instruction_count: u64,
    parameter_count: u64,
    return_bits: u16,
    calling_convention: CandidateConvention,
};

pub const AdmissionEvidence = struct {
    target: Target,
    candidate_calling_convention: CandidateConvention,
    parameter_count: u64,
    return_bits: u16,
    result_type: BridgeResult,
    bridge_calling_convention: BridgeConvention,
    return_value_drives_output: bool,
    expected_result: u64,
    planner_gpr_returns: u8,
    planner_sse_returns: u8,
    planner_memory_return: bool,
};

pub const Termination = enum { exited, signaled, stopped, unknown };

pub const ExecutionRecord = struct {
    termination: Termination,
    status: u8,
    stdout_sha256: Identity32,
    stderr_sha256: Identity32,
    stdout_length: u64,
    stderr_length: u64,
    semantic_result: u64,
    call_occurrence: bool,
};

pub const Counters = struct {
    real_functions_lowered: u64,
    real_objects_emitted: u64,
    real_native_linked: u64,
    real_executed: u64,
    real_programs_ok: u64,
    local_fail: u64,
};

pub const RunEvidence = struct {
    external_revision: Identity20,
    selector_initial: SelectorIdentity,
    selector_final: SelectorIdentity,
    source_initial: SourceEvidence,
    source_final: SourceEvidence,
    descriptor_initial: DescriptorEvidence,
    descriptor_final: DescriptorEvidence,
    admission: AdmissionEvidence,
    reference_record: ExecutionRecord,
    linked_record: ExecutionRecord,
    counters: Counters,
};

pub const ReceiptIdentity = struct {
    length: u64,
    sha256: Identity32,
};

const StagedChange = struct {
    path_index: usize,
    blob: Identity20,
    status: StagedStatus,
};

const OwnedProcessResult = struct {
    stdout: []u8,
    stderr: []u8,
    status: u8,

    fn deinit(self: *OwnedProcessResult, allocator: std.mem.Allocator) void {
        allocator.free(self.stderr);
        allocator.free(self.stdout);
        self.* = undefined;
    }
};

fn sourcePathIndex(path: []const u8) ?usize {
    for (source_paths, 0..) |expected, index| {
        if (std.mem.eql(u8, path, expected)) return index;
    }
    return null;
}

fn isCanonicalRelativePath(path: []const u8) bool {
    if (path.len == 0 or path[0] == '/' or std.mem.indexOfScalar(u8, path, 0) != null) return false;
    var components = std.mem.splitScalar(u8, path, '/');
    while (components.next()) |component| {
        if (component.len == 0 or std.mem.eql(u8, component, ".") or std.mem.eql(u8, component, "..")) return false;
    }
    return true;
}

fn isZero(bytes: []const u8) bool {
    return std.mem.allEqual(u8, bytes, 0);
}

fn sha256(bytes: []const u8) Identity32 {
    var digest: [32]u8 = undefined;
    Sha256.hash(bytes, &digest, .{});
    return .{ .bytes = digest };
}

fn gitBlobIdentity(bytes: []const u8) Identity20 {
    var length_buffer: [32]u8 = undefined;
    const length = std.fmt.bufPrint(&length_buffer, "{d}", .{bytes.len}) catch unreachable;
    var hasher = Sha1.init(.{});
    hasher.update("blob ");
    hasher.update(length);
    hasher.update(&.{0});
    hasher.update(bytes);
    return .{ .bytes = hasher.finalResult() };
}

fn sourceIdentity(bytes: []const u8) !SourceIdentity {
    if (bytes.len == 0 or bytes.len > source_max_bytes) return error.SourceLengthMismatch;
    return .{
        .mode = source_mode,
        .blob = gitBlobIdentity(bytes),
        .raw_sha256 = sha256(bytes),
        .length = @intCast(bytes.len),
    };
}

fn decodeNibble(byte: u8) !u8 {
    return switch (byte) {
        '0'...'9' => byte - '0',
        'a'...'f' => byte - 'a' + 10,
        else => error.GitOutputMalformed,
    };
}

fn decodeLowerHex(bytes: []const u8, output: []u8) !void {
    if (bytes.len != output.len * 2) return error.GitOutputMalformed;
    for (output, 0..) |*byte, index| {
        const high = try decodeNibble(bytes[index * 2]);
        const low = try decodeNibble(bytes[index * 2 + 1]);
        byte.* = (high << 4) | low;
    }
}

fn lowerHexNibble(value: u8) u8 {
    return if (value < 10) '0' + value else 'a' + value - 10;
}

fn encodeLowerHex(bytes: []const u8, output: []u8) void {
    std.debug.assert(output.len == bytes.len * 2);
    for (bytes, 0..) |byte, index| {
        output[index * 2] = lowerHexNibble(byte >> 4);
        output[index * 2 + 1] = lowerHexNibble(byte & 0x0f);
    }
}

fn expectedExternalRevision() Identity20 {
    var result: Identity20 = undefined;
    decodeLowerHex(external_revision_hex, &result.bytes) catch unreachable;
    return result;
}

fn splitStatusRecord(record: []const u8) ![9][]const u8 {
    var fields: [9][]const u8 = undefined;
    var start: usize = 0;
    for (0..8) |index| {
        const relative = std.mem.indexOfScalar(u8, record[start..], ' ') orelse return error.GitOutputMalformed;
        const end = std.math.add(usize, start, relative) catch return error.GitOutputMalformed;
        if (end == start) return error.GitOutputMalformed;
        fields[index] = record[start..end];
        start = std.math.add(usize, end, 1) catch return error.GitOutputMalformed;
    }
    if (start >= record.len or std.mem.indexOfScalar(u8, record[start..], 0) != null) return error.GitOutputMalformed;
    fields[8] = record[start..];
    return fields;
}

fn parseStagedListing(bytes: []const u8) ![source_count]StagedChange {
    if (bytes.len == 0) return error.EmptyStagedSet;
    var result: [source_count]StagedChange = undefined;
    var seen: [source_count]bool = @splat(false);
    var record_index: usize = 0;
    var offset: usize = 0;
    while (offset < bytes.len) {
        const relative_end = std.mem.indexOfScalar(u8, bytes[offset..], 0) orelse return error.GitOutputMalformed;
        const end = std.math.add(usize, offset, relative_end) catch return error.GitOutputMalformed;
        const record = bytes[offset..end];
        offset = std.math.add(usize, end, 1) catch return error.GitOutputMalformed;
        if (record.len == 0) return error.GitOutputMalformed;
        if (record_index >= source_count) return error.ExtraStagedPath;
        const fields = try splitStatusRecord(record);
        if (!std.mem.eql(u8, fields[0], "1") or !std.mem.eql(u8, fields[2], "N...")) {
            return error.GitOutputMalformed;
        }
        const status: StagedStatus = if (std.mem.eql(u8, fields[1], "A."))
            .added
        else if (std.mem.eql(u8, fields[1], "M."))
            .modified
        else
            return error.StagedStatusMismatch;
        if (!std.mem.eql(u8, fields[4], "100644") or !std.mem.eql(u8, fields[5], "100644") or
            (status == .added and !std.mem.eql(u8, fields[3], "000000")) or
            (status == .modified and !std.mem.eql(u8, fields[3], "100644")))
        {
            return error.SourceModeMismatch;
        }
        const path_index = sourcePathIndex(fields[8]) orelse return error.ExtraStagedPath;
        if (seen[path_index]) return error.DuplicateStagedPath;
        if (path_index != listing_order[record_index]) return error.SourceOrderMismatch;
        if (status != expected_status[path_index]) return error.StagedStatusMismatch;
        var blob: Identity20 = undefined;
        try decodeLowerHex(fields[7], &blob.bytes);
        if (isZero(&blob.bytes)) return error.SourceBlobMismatch;
        seen[path_index] = true;
        result[path_index] = .{ .path_index = path_index, .blob = blob, .status = status };
        record_index += 1;
    }
    if (record_index != source_count) return error.MissingStagedPath;
    return result;
}

fn parseTree(bytes: []const u8) !Identity20 {
    if (bytes.len != 41 or bytes[40] != '\n') return error.GitOutputMalformed;
    var result: Identity20 = undefined;
    try decodeLowerHex(bytes[0..40], &result.bytes);
    if (isZero(&result.bytes)) return error.StagedTreeMismatch;
    return result;
}

fn bindSourceSet(
    changes: *const [source_count]StagedChange,
    staged: *const [source_count][]const u8,
    worktree: *const [source_count][]const u8,
) ![source_count]SourceIdentity {
    var result: [source_count]SourceIdentity = undefined;
    for (changes, staged, worktree, &result, 0..) |change, staged_bytes, worktree_bytes, *identity, index| {
        if (change.path_index != index or change.status != expected_status[index]) return error.SourceOrderMismatch;
        if (!std.mem.eql(u8, staged_bytes, worktree_bytes)) return error.SourceWorktreeMismatch;
        identity.* = try sourceIdentity(staged_bytes);
        if (!std.meta.eql(identity.blob, change.blob)) return error.SourceBlobMismatch;
        if (identity.length != staged_bytes.len) return error.SourceLengthMismatch;
    }
    return result;
}

fn createGitEnvironment(allocator: std.mem.Allocator) !std.process.Environ.Map {
    var environment = std.process.Environ.Map.init(allocator);
    errdefer environment.deinit();
    try environment.put("LC_ALL", "C");
    try environment.put("LANG", "C");
    try environment.put("TZ", "UTC0");
    try environment.put("HOME", "/nonexistent");
    try environment.put("XDG_CONFIG_HOME", "/nonexistent");
    try environment.put("GIT_OPTIONAL_LOCKS", "0");
    try environment.put("GIT_CONFIG_NOSYSTEM", "1");
    try environment.put("GIT_CONFIG_SYSTEM", "/dev/null");
    try environment.put("GIT_CONFIG_GLOBAL", "/dev/null");
    try environment.put("GIT_CONFIG_COUNT", "0");
    try environment.put("GIT_TERMINAL_PROMPT", "0");
    try environment.put("GIT_PAGER", "cat");
    try environment.put("PAGER", "cat");
    return environment;
}

fn runGit(
    allocator: std.mem.Allocator,
    io: std.Io,
    repository: []const u8,
    tail: []const []const u8,
    stdout_limit: usize,
) !OwnedProcessResult {
    if (!std.fs.path.isAbsolute(repository) or tail.len == 0) return error.GitCommandFailed;
    const prefix = [_][]const u8{
        "/usr/bin/git", "--no-optional-locks", "-c", "core.fsmonitor=false", "-c", "core.untrackedCache=false", "-C", repository,
    };
    const argv = try allocator.alloc([]const u8, prefix.len + tail.len);
    defer allocator.free(argv);
    @memcpy(argv[0..prefix.len], &prefix);
    @memcpy(argv[prefix.len..], tail);
    var environment = try createGitEnvironment(allocator);
    defer environment.deinit();
    const raw = std.process.run(allocator, io, .{
        .argv = argv,
        .cwd = .{ .path = repository },
        .environ_map = &environment,
        .stdout_limit = .limited(stdout_limit),
        .stderr_limit = .limited(process_output_max),
    }) catch |failure| switch (failure) {
        error.StreamTooLong => return error.GitOutputBoundExceeded,
        else => return error.GitCommandFailed,
    };
    errdefer allocator.free(raw.stdout);
    errdefer allocator.free(raw.stderr);
    const status: u8 = switch (raw.term) {
        .exited => |code| code,
        else => return error.GitCommandFailed,
    };
    return .{ .stdout = raw.stdout, .stderr = raw.stderr, .status = status };
}

fn runGitSuccessful(
    allocator: std.mem.Allocator,
    io: std.Io,
    repository: []const u8,
    tail: []const []const u8,
    stdout_limit: usize,
) !OwnedProcessResult {
    var result = try runGit(allocator, io, repository, tail, stdout_limit);
    errdefer result.deinit(allocator);
    if (result.status != 0 or result.stderr.len != 0) return error.GitCommandFailed;
    return result;
}

fn readBounded(
    allocator: std.mem.Allocator,
    io: std.Io,
    directory: std.Io.Dir,
    path: []const u8,
) ![]u8 {
    if (!isCanonicalRelativePath(path)) return error.SourcePathInvalid;
    var file = try directory.openFile(io, path, .{
        .mode = .read_only,
        .follow_symlinks = false,
        .resolve_beneath = true,
    });
    defer file.close(io);
    var reader = file.reader(io, &.{});
    return reader.interface.allocRemaining(allocator, .limited(source_max_bytes));
}

fn readStaged(
    allocator: std.mem.Allocator,
    io: std.Io,
    repository: []const u8,
    path: []const u8,
) ![]u8 {
    if (sourcePathIndex(path) == null) return error.SourcePathInvalid;
    var specifier_buffer: [256]u8 = undefined;
    const specifier = try std.fmt.bufPrint(&specifier_buffer, ":{s}", .{path});
    const result = try runGitSuccessful(allocator, io, repository, &.{ "show", "--no-textconv", specifier }, source_max_bytes);
    allocator.free(result.stderr);
    return result.stdout;
}

fn observeClosureAt(
    allocator: std.mem.Allocator,
    io: std.Io,
    repository: []const u8,
) !StructuredClosure {
    var format = try runGitSuccessful(allocator, io, repository, &.{ "rev-parse", "--show-object-format" }, 128);
    defer format.deinit(allocator);
    if (!std.mem.eql(u8, format.stdout, "sha1\n")) return error.GitObjectAlgorithmUnsupported;

    var listing = try runGitSuccessful(allocator, io, repository, &.{
        "status", "--porcelain=v2", "-z", "--untracked-files=all", "--no-ahead-behind", "--ignore-submodules=none", "--no-renames",
    }, process_output_max);
    defer listing.deinit(allocator);
    const changes = try parseStagedListing(listing.stdout);

    var tree = try runGitSuccessful(allocator, io, repository, &.{"write-tree"}, 128);
    defer tree.deinit(allocator);
    const staged_tree = try parseTree(tree.stdout);

    var root = try std.Io.Dir.openDirAbsolute(io, repository, .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer root.close(io);
    var staged_owned: [source_count]?[]u8 = @splat(null);
    var worktree_owned: [source_count]?[]u8 = @splat(null);
    defer {
        var index: usize = source_count;
        while (index > 0) {
            index -= 1;
            if (worktree_owned[index]) |bytes| allocator.free(bytes);
            if (staged_owned[index]) |bytes| allocator.free(bytes);
        }
    }
    var staged: [source_count][]const u8 = undefined;
    var worktree: [source_count][]const u8 = undefined;
    for (source_paths, 0..) |path, index| {
        staged_owned[index] = try readStaged(allocator, io, repository, path);
        worktree_owned[index] = try readBounded(allocator, io, root, path);
        staged[index] = staged_owned[index].?;
        worktree[index] = worktree_owned[index].?;
    }
    const sources = try bindSourceSet(&changes, &staged, &worktree);
    var statuses: [source_count]StagedStatus = undefined;
    for (changes, &statuses) |change, *status| status.* = change.status;
    return .{ .sources = sources, .statuses = statuses, .staged_tree = staged_tree };
}

pub fn observeLiveClosure(allocator: std.mem.Allocator, io: std.Io) !StructuredClosure {
    return observeClosureAt(allocator, io, repository_root);
}

pub fn requireSameClosure(expected: *const StructuredClosure, observed: *const StructuredClosure) !void {
    if (!std.meta.eql(expected.*, observed.*)) return error.StructuredClosureDrift;
}

fn validateClosure(closure: *const StructuredClosure) !void {
    if (isZero(&closure.staged_tree.bytes) or !std.meta.eql(closure.statuses, expected_status)) {
        return error.StructuredClosureInvalid;
    }
    for (closure.sources) |source| {
        if (source.mode != source_mode or source.length == 0 or source.length > source_max_bytes or
            isZero(&source.blob.bytes) or isZero(&source.raw_sha256.bytes))
        {
            return error.StructuredClosureInvalid;
        }
    }
}

fn validateSelector(selector: *const SelectorIdentity) !void {
    const length: usize = selector.version_length;
    if (length == 0 or length > selector.version.len or selector.length == 0 or
        isZero(&selector.sha256.bytes) or
        std.mem.indexOfAny(u8, selector.version[0..length], "\x00\t\r\n") != null or
        !std.mem.allEqual(u8, selector.version[length..], 0))
    {
        return error.SelectorEvidenceInvalid;
    }
}

fn validateSource(source: SourceEvidence) !void {
    if (isZero(&source.definition_sha256.bytes) or isZero(&source.import_sha256.bytes) or
        isZero(&source.use_sha256.bytes) or source.definition_count != 1 or source.use_count == 0)
    {
        return error.SourceEvidenceMismatch;
    }
}

fn validateDescriptor(descriptor: DescriptorEvidence) !void {
    if (isZero(&descriptor.descriptor_sha256.bytes) or isZero(&descriptor.function_type_sha256.bytes) or
        descriptor.instruction_count == 0 or descriptor.parameter_count != 0 or descriptor.return_bits != 64 or
        descriptor.calling_convention != .default)
    {
        return error.DescriptorEvidenceMismatch;
    }
}

fn validateAdmission(admission: AdmissionEvidence) !void {
    if (admission.target != .x86_64_linux_gnu or admission.candidate_calling_convention != .default or
        admission.parameter_count != 0 or admission.return_bits != 64 or admission.result_type != .usize or
        admission.bridge_calling_convention != .x86_64_sysv or !admission.return_value_drives_output or
        admission.expected_result != 18 or admission.planner_gpr_returns != 1 or admission.planner_sse_returns != 0 or
        admission.planner_memory_return)
    {
        return error.AdmissionEvidenceMismatch;
    }
}

fn expectedExecutionRecord() ExecutionRecord {
    const stdout = "execution-oracle-v1 result=18 witness=61\n";
    return .{
        .termination = .exited,
        .status = 0,
        .stdout_sha256 = sha256(stdout),
        .stderr_sha256 = sha256(""),
        .stdout_length = stdout.len,
        .stderr_length = 0,
        .semantic_result = 18,
        .call_occurrence = true,
    };
}

pub fn validateRunEvidence(evidence: *const RunEvidence) !void {
    if (!std.meta.eql(evidence.external_revision, expectedExternalRevision())) return error.ExternalRevisionMismatch;
    try validateSelector(&evidence.selector_initial);
    try validateSelector(&evidence.selector_final);
    if (!std.meta.eql(evidence.selector_initial, evidence.selector_final)) return error.SelectorEvidenceDrift;
    try validateSource(evidence.source_initial);
    try validateSource(evidence.source_final);
    if (!std.meta.eql(evidence.source_initial, evidence.source_final)) return error.SourceEvidenceMismatch;
    try validateDescriptor(evidence.descriptor_initial);
    try validateDescriptor(evidence.descriptor_final);
    if (!std.meta.eql(evidence.descriptor_initial, evidence.descriptor_final)) return error.DescriptorEvidenceMismatch;
    try validateAdmission(evidence.admission);
    const expected_record = expectedExecutionRecord();
    if (!std.meta.eql(evidence.reference_record, expected_record) or
        !std.meta.eql(evidence.linked_record, expected_record) or
        !std.meta.eql(evidence.reference_record, evidence.linked_record))
    {
        return error.OracleRecordMismatch;
    }
    if (!std.meta.eql(evidence.counters, Counters{
        .real_functions_lowered = 1,
        .real_objects_emitted = 1,
        .real_native_linked = 1,
        .real_executed = 1,
        .real_programs_ok = 1,
        .local_fail = 0,
    })) return error.CounterMismatch;
}

const admission_receipt_field_names = [3][]const u8{
    "admission_result_type",
    "admission_return_value_drives_output",
    "admission_expected_result",
};

fn parseCanonicalDecimal(bytes: []const u8) !u64 {
    if (bytes.len == 0 or (bytes.len > 1 and bytes[0] == '0')) return error.ReceiptAdmissionMalformed;
    var value: u64 = 0;
    for (bytes) |byte| {
        if (byte < '0' or byte > '9') return error.ReceiptAdmissionMalformed;
        value = std.math.mul(u64, value, 10) catch return error.ReceiptAdmissionMalformed;
        value = std.math.add(u64, value, byte - '0') catch return error.ReceiptAdmissionMalformed;
    }
    return value;
}

fn admissionFieldIndex(name: []const u8) ?usize {
    for (admission_receipt_field_names, 0..) |expected, index| {
        if (std.mem.eql(u8, name, expected)) return index;
    }
    return null;
}

fn validateAdmissionFieldValue(index: usize, value: []const u8, admission: AdmissionEvidence) !void {
    switch (index) {
        0 => {
            if (!std.mem.eql(u8, value, "usize") and !std.mem.eql(u8, value, "u64")) {
                return error.ReceiptAdmissionMalformed;
            }
            if (!std.mem.eql(u8, value, @tagName(admission.result_type))) return error.ReceiptAdmissionDrift;
        },
        1 => {
            if (!std.mem.eql(u8, value, "0") and !std.mem.eql(u8, value, "1")) {
                return error.ReceiptAdmissionMalformed;
            }
            const expected = if (admission.return_value_drives_output) "1" else "0";
            if (!std.mem.eql(u8, value, expected)) return error.ReceiptAdmissionDrift;
        },
        2 => if (try parseCanonicalDecimal(value) != admission.expected_result) {
            return error.ReceiptAdmissionDrift;
        },
        else => unreachable,
    }
}

fn validateReceiptAdmissionFields(bytes: []const u8, admission: AdmissionEvidence) !void {
    try validateAdmission(admission);
    const schema_line = "schema\t" ++ receipt_schema ++ "\n";
    if (!std.mem.startsWith(u8, bytes, schema_line) or bytes.len == 0 or bytes[bytes.len - 1] != '\n') {
        return error.ReceiptAdmissionMalformed;
    }
    var expected_index: usize = 0;
    var started = false;
    var offset: usize = 0;
    while (offset < bytes.len) {
        const relative_end = std.mem.indexOfScalar(u8, bytes[offset..], '\n') orelse
            return error.ReceiptAdmissionMalformed;
        const end = std.math.add(usize, offset, relative_end) catch return error.ReceiptAdmissionMalformed;
        const line = bytes[offset..end];
        offset = std.math.add(usize, end, 1) catch return error.ReceiptAdmissionMalformed;
        if (line.len == 0 or std.mem.indexOfAny(u8, line, "\x00\r") != null) {
            return error.ReceiptAdmissionMalformed;
        }
        const separator = std.mem.indexOfScalar(u8, line, '\t') orelse return error.ReceiptAdmissionMalformed;
        if (separator == 0 or separator + 1 >= line.len or
            std.mem.indexOfScalar(u8, line[separator + 1 ..], '\t') != null)
        {
            return error.ReceiptAdmissionMalformed;
        }
        const name = line[0..separator];
        const value = line[separator + 1 ..];
        if (admissionFieldIndex(name)) |index| {
            if (index != expected_index) return error.ReceiptAdmissionOrderMismatch;
            try validateAdmissionFieldValue(index, value, admission);
            expected_index += 1;
            started = true;
        } else if (started and expected_index != admission_receipt_field_names.len) {
            return error.ReceiptAdmissionMissing;
        }
    }
    if (expected_index != admission_receipt_field_names.len) return error.ReceiptAdmissionMissing;
}

fn writeField(writer: *std.Io.Writer, name: []const u8, value: []const u8) !void {
    if (name.len == 0 or value.len == 0 or std.mem.indexOfAny(u8, name, "\t\r\n") != null or
        std.mem.indexOfAny(u8, value, "\t\r\n") != null)
    {
        return error.ReceiptNonCanonical;
    }
    try writer.writeAll(name);
    try writer.writeByte('\t');
    try writer.writeAll(value);
    try writer.writeByte('\n');
}

fn writeDecimal(writer: *std.Io.Writer, name: []const u8, value: u64) !void {
    var buffer: [32]u8 = undefined;
    const text = try std.fmt.bufPrint(&buffer, "{d}", .{value});
    try writeField(writer, name, text);
}

fn writeIdentity20(writer: *std.Io.Writer, name: []const u8, identity: Identity20) !void {
    var buffer: [40]u8 = undefined;
    encodeLowerHex(&identity.bytes, &buffer);
    try writeField(writer, name, &buffer);
}

fn writeIdentity32(writer: *std.Io.Writer, name: []const u8, identity: Identity32) !void {
    var buffer: [64]u8 = undefined;
    encodeLowerHex(&identity.bytes, &buffer);
    try writeField(writer, name, &buffer);
}

fn writeRecord(writer: *std.Io.Writer, prefix: []const u8, record: ExecutionRecord) !void {
    var name: [96]u8 = undefined;
    try writeField(writer, try std.fmt.bufPrint(&name, "{s}_termination", .{prefix}), @tagName(record.termination));
    try writeDecimal(writer, try std.fmt.bufPrint(&name, "{s}_status", .{prefix}), record.status);
    try writeIdentity32(writer, try std.fmt.bufPrint(&name, "{s}_stdout_sha256", .{prefix}), record.stdout_sha256);
    try writeDecimal(writer, try std.fmt.bufPrint(&name, "{s}_stdout_length", .{prefix}), record.stdout_length);
    try writeIdentity32(writer, try std.fmt.bufPrint(&name, "{s}_stderr_sha256", .{prefix}), record.stderr_sha256);
    try writeDecimal(writer, try std.fmt.bufPrint(&name, "{s}_stderr_length", .{prefix}), record.stderr_length);
    try writeDecimal(writer, try std.fmt.bufPrint(&name, "{s}_semantic_result", .{prefix}), record.semantic_result);
    try writeField(writer, try std.fmt.bufPrint(&name, "{s}_call_occurrence", .{prefix}), if (record.call_occurrence) "1" else "0");
}

pub fn encodeReceipt(
    output: *[receipt_max_bytes]u8,
    closure: *const StructuredClosure,
    evidence: *const RunEvidence,
) ![]const u8 {
    try validateClosure(closure);
    try validateRunEvidence(evidence);
    var stream = std.Io.Writer.fixed(output);
    const writer = &stream;
    try writeField(writer, "schema", receipt_schema);
    try writeField(writer, "generation", "generation-v6");
    try writeDecimal(writer, "source_count", source_count);
    for (source_paths, closure.sources, 0..) |path, source, index| {
        var name: [96]u8 = undefined;
        try writeField(writer, try std.fmt.bufPrint(&name, "source_{d}_path", .{index}), path);
        try writeField(writer, try std.fmt.bufPrint(&name, "source_{d}_mode", .{index}), "100644");
        try writeIdentity20(writer, try std.fmt.bufPrint(&name, "source_{d}_blob_sha1", .{index}), source.blob);
        try writeIdentity32(writer, try std.fmt.bufPrint(&name, "source_{d}_raw_sha256", .{index}), source.raw_sha256);
        try writeDecimal(writer, try std.fmt.bufPrint(&name, "source_{d}_length", .{index}), source.length);
        try writeField(writer, try std.fmt.bufPrint(&name, "source_{d}_staged_worktree_equal", .{index}), "1");
    }
    try writeIdentity20(writer, "staged_tree_sha1", closure.staged_tree);
    try writeIdentity20(writer, "external_zig_revision", evidence.external_revision);
    try writeField(writer, "selector_version", evidence.selector_initial.versionSlice());
    try writeDecimal(writer, "selector_length", evidence.selector_initial.length);
    try writeIdentity32(writer, "selector_sha256", evidence.selector_initial.sha256);
    try writeIdentity32(writer, "definition_source_sha256", evidence.source_initial.definition_sha256);
    try writeIdentity32(writer, "definition_import_sha256", evidence.source_initial.import_sha256);
    try writeIdentity32(writer, "definition_use_sha256", evidence.source_initial.use_sha256);
    try writeDecimal(writer, "definition_count", evidence.source_initial.definition_count);
    try writeDecimal(writer, "use_count", evidence.source_initial.use_count);
    try writeIdentity32(writer, "descriptor_sha256", evidence.descriptor_initial.descriptor_sha256);
    try writeIdentity32(writer, "descriptor_function_type_sha256", evidence.descriptor_initial.function_type_sha256);
    try writeDecimal(writer, "descriptor_instruction_count", evidence.descriptor_initial.instruction_count);
    try writeField(writer, "admission_target", "x86_64-linux-gnu");
    try writeField(writer, "admission_candidate_calling_convention", "default");
    try writeDecimal(writer, "admission_parameter_count", evidence.admission.parameter_count);
    try writeDecimal(writer, "admission_return_bits", evidence.admission.return_bits);
    try writeField(writer, "admission_result_type", @tagName(evidence.admission.result_type));
    try writeField(
        writer,
        "admission_return_value_drives_output",
        if (evidence.admission.return_value_drives_output) "1" else "0",
    );
    try writeDecimal(writer, "admission_expected_result", evidence.admission.expected_result);
    try writeField(writer, "admission_bridge_calling_convention", "x86_64_sysv");
    try writeDecimal(writer, "admission_planner_gpr_returns", evidence.admission.planner_gpr_returns);
    try writeDecimal(writer, "admission_planner_sse_returns", evidence.admission.planner_sse_returns);
    try writeField(writer, "admission_planner_memory_return", if (evidence.admission.planner_memory_return) "1" else "0");
    try writeRecord(writer, "reference", evidence.reference_record);
    try writeRecord(writer, "linked", evidence.linked_record);
    try writeDecimal(writer, "real_functions_lowered", evidence.counters.real_functions_lowered);
    try writeDecimal(writer, "real_objects_emitted", evidence.counters.real_objects_emitted);
    try writeDecimal(writer, "real_native_linked", evidence.counters.real_native_linked);
    try writeDecimal(writer, "real_executed", evidence.counters.real_executed);
    try writeDecimal(writer, "real_programs_ok", evidence.counters.real_programs_ok);
    try writeDecimal(writer, "local_fail", evidence.counters.local_fail);
    try writeField(writer, "completion", "complete");
    const encoded = stream.buffered();
    try validateReceiptAdmissionFields(encoded, evidence.admission);
    return encoded;
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

fn publishInDirectory(
    allocator: std.mem.Allocator,
    io: std.Io,
    directory: std.Io.Dir,
    closure: *const StructuredClosure,
    evidence: *const RunEvidence,
) !ReceiptIdentity {
    var encoded_buffer: [receipt_max_bytes]u8 = undefined;
    const encoded = try encodeReceipt(&encoded_buffer, closure, evidence);
    var atomic_file = try directory.createFileAtomic(io, receipt_name, .{
        .permissions = .fromMode(0o644),
        .replace = false,
    });
    defer atomic_file.deinit(io);
    try atomic_file.file.writeStreamingAll(io, encoded);
    try atomic_file.file.sync(io);
    atomic_file.link(io) catch |failure| switch (failure) {
        error.PathAlreadyExists => return error.ReceiptCollision,
        else => return failure,
    };
    try syncOwnedDirectory(directory, io);
    var file = try directory.openFile(io, receipt_name, .{
        .mode = .read_only,
        .follow_symlinks = false,
        .resolve_beneath = true,
    });
    defer file.close(io);
    var reader = file.reader(io, &.{});
    const read_back = try reader.interface.allocRemaining(allocator, .limited(receipt_max_bytes));
    defer allocator.free(read_back);
    if (!std.mem.eql(u8, encoded, read_back)) return error.ReceiptReadBackMismatch;
    try validateReceiptAdmissionFields(read_back, evidence.admission);
    return .{ .length = @intCast(read_back.len), .sha256 = sha256(read_back) };
}

pub fn finalizeAndPublish(
    allocator: std.mem.Allocator,
    io: std.Io,
    generation_directory: std.Io.Dir,
    initial: *const StructuredClosure,
    final: *const StructuredClosure,
    evidence: *const RunEvidence,
) !ReceiptIdentity {
    try requireSameClosure(initial, final);
    try validateClosure(final);
    try validateRunEvidence(evidence);
    return publishInDirectory(allocator, io, generation_directory, final, evidence);
}

fn syntheticEvidence(seed: u8) RunEvidence {
    const source = SourceEvidence{
        .definition_sha256 = .{ .bytes = @splat(seed) },
        .import_sha256 = .{ .bytes = @splat(seed +% 1) },
        .use_sha256 = .{ .bytes = @splat(seed +% 2) },
        .definition_count = 1,
        .use_count = 1,
    };
    const descriptor = DescriptorEvidence{
        .descriptor_sha256 = .{ .bytes = @splat(seed +% 3) },
        .function_type_sha256 = .{ .bytes = @splat(seed +% 4) },
        .instruction_count = 2,
        .parameter_count = 0,
        .return_bits = 64,
        .calling_convention = .default,
    };
    const selector = SelectorIdentity.init("0.17.0-dev.synthetic", 1234, @as([32]u8, @splat(seed +% 5))) catch unreachable;
    const record = expectedExecutionRecord();
    return .{
        .external_revision = expectedExternalRevision(),
        .selector_initial = selector,
        .selector_final = selector,
        .source_initial = source,
        .source_final = source,
        .descriptor_initial = descriptor,
        .descriptor_final = descriptor,
        .admission = .{
            .target = .x86_64_linux_gnu,
            .candidate_calling_convention = .default,
            .parameter_count = 0,
            .return_bits = 64,
            .result_type = .usize,
            .bridge_calling_convention = .x86_64_sysv,
            .return_value_drives_output = true,
            .expected_result = 18,
            .planner_gpr_returns = 1,
            .planner_sse_returns = 0,
            .planner_memory_return = false,
        },
        .reference_record = record,
        .linked_record = record,
        .counters = .{
            .real_functions_lowered = 1,
            .real_objects_emitted = 1,
            .real_native_linked = 1,
            .real_executed = 1,
            .real_programs_ok = 1,
            .local_fail = 0,
        },
    };
}

fn syntheticClosure(seed: u8) StructuredClosure {
    var sources: [source_count]SourceIdentity = undefined;
    for (&sources, 0..) |*source, index| {
        var bytes: [16]u8 = @splat(seed);
        bytes[0] +%= @intCast(index);
        source.* = sourceIdentity(&bytes) catch unreachable;
    }
    return .{
        .sources = sources,
        .statuses = expected_status,
        .staged_tree = .{ .bytes = @splat(seed +% 10) },
    };
}

fn makeStatusListing(output: *[8192]u8, closure: *const StructuredClosure) ![]const u8 {
    var stream = std.Io.Writer.fixed(output);
    const writer = &stream;
    var zero: [40]u8 = @splat('0');
    for (listing_order) |path_index| {
        const source = closure.sources[path_index];
        var blob: [40]u8 = undefined;
        encodeLowerHex(&source.blob.bytes, &blob);
        const status = expected_status[path_index];
        try writer.print("1 {s} N... {s} 100644 100644 {s} {s} {s}", .{
            if (status == .added) "A." else "M.",
            if (status == .added) "000000" else "100644",
            &zero,
            &blob,
            source_paths[path_index],
        });
        try writer.writeByte(0);
    }
    return stream.buffered();
}

fn runTestGit(allocator: std.mem.Allocator, io: std.Io, repository: []const u8, tail: []const []const u8) !void {
    var result = try runGitSuccessful(allocator, io, repository, tail, process_output_max);
    defer result.deinit(allocator);
}

test "acceptance staged inventory parser is exact ordered and NUL safe" {
    const closure = syntheticClosure(0x21);
    var storage: [8192]u8 = undefined;
    const listing = try makeStatusListing(&storage, &closure);
    const parsed = try parseStagedListing(listing);
    for (parsed, closure.sources, 0..) |change, source, index| {
        try std.testing.expectEqual(index, change.path_index);
        try std.testing.expect(std.meta.eql(change.blob, source.blob));
    }
    const final_separator = std.mem.lastIndexOfScalar(u8, listing[0 .. listing.len - 1], 0) orelse unreachable;
    try std.testing.expectError(error.MissingStagedPath, parseStagedListing(listing[0 .. final_separator + 1]));
    try std.testing.expectError(error.GitOutputMalformed, parseStagedListing(listing[0 .. listing.len - 1]));
    var changed: [8192]u8 = undefined;
    @memcpy(changed[0..listing.len], listing);
    changed[listing.len] = 0;
    try std.testing.expectError(error.GitOutputMalformed, parseStagedListing(changed[0 .. listing.len + 1]));
}

test "acceptance staged inventory rejects duplicate reordered extra mode and blob drift" {
    const closure = syntheticClosure(0x31);
    var storage: [8192]u8 = undefined;
    const listing = try makeStatusListing(&storage, &closure);
    var changed: [8192]u8 = undefined;

    const first_end = (std.mem.indexOfScalar(u8, listing, 0) orelse unreachable) + 1;
    const second_end = first_end + (std.mem.indexOfScalar(u8, listing[first_end..], 0) orelse unreachable) + 1;
    @memcpy(changed[0..first_end], listing[0..first_end]);
    @memcpy(changed[first_end .. first_end * 2], listing[0..first_end]);
    @memcpy(changed[first_end * 2 .. first_end * 2 + listing.len - second_end], listing[second_end..]);
    try std.testing.expectError(error.DuplicateStagedPath, parseStagedListing(changed[0 .. first_end * 2 + listing.len - second_end]));

    @memcpy(changed[0..listing.len], listing);
    const first_record = changed[0 .. first_end - 1];
    const second_record = listing[first_end .. second_end - 1];
    @memcpy(changed[0..second_record.len], second_record);
    changed[second_record.len] = 0;
    @memcpy(changed[second_record.len + 1 .. second_record.len + 1 + first_record.len], first_record);
    changed[second_record.len + 1 + first_record.len] = 0;
    @memcpy(changed[second_end..listing.len], listing[second_end..]);
    try std.testing.expectError(error.SourceOrderMismatch, parseStagedListing(changed[0..listing.len]));

    @memcpy(changed[0..listing.len], listing);
    const mode = std.mem.indexOf(u8, changed[0..listing.len], "100644 100644") orelse unreachable;
    changed[mode] = '0';
    try std.testing.expectError(error.SourceModeMismatch, parseStagedListing(changed[0..listing.len]));

    @memcpy(changed[0..listing.len], listing);
    const path = std.mem.indexOf(u8, changed[0..listing.len], source_paths[0]) orelse unreachable;
    changed[path] = 'x';
    try std.testing.expectError(error.ExtraStagedPath, parseStagedListing(changed[0..listing.len]));

    @memcpy(changed[0..listing.len], listing);
    var encoded_blob: [40]u8 = undefined;
    encodeLowerHex(&closure.sources[0].blob.bytes, &encoded_blob);
    const blob = std.mem.indexOf(u8, changed[0..listing.len], &encoded_blob) orelse unreachable;
    changed[blob] = 'g';
    try std.testing.expectError(error.GitOutputMalformed, parseStagedListing(changed[0..listing.len]));
}

test "source binding rejects worktree bytes blob length and tree drift" {
    const closure = syntheticClosure(0x41);
    var changes: [source_count]StagedChange = undefined;
    var staged_storage: [source_count][16]u8 = undefined;
    var worktree_storage: [source_count][16]u8 = undefined;
    var staged: [source_count][]const u8 = undefined;
    var worktree: [source_count][]const u8 = undefined;
    for (0..source_count) |index| {
        staged_storage[index] = @splat(0x41);
        staged_storage[index][0] +%= @intCast(index);
        worktree_storage[index] = staged_storage[index];
        staged[index] = &staged_storage[index];
        worktree[index] = &worktree_storage[index];
        changes[index] = .{ .path_index = index, .blob = closure.sources[index].blob, .status = expected_status[index] };
    }
    _ = try bindSourceSet(&changes, &staged, &worktree);
    worktree_storage[2][4] ^= 1;
    try std.testing.expectError(error.SourceWorktreeMismatch, bindSourceSet(&changes, &staged, &worktree));
    worktree_storage[2][4] ^= 1;
    changes[3].blob.bytes[0] ^= 1;
    try std.testing.expectError(error.SourceBlobMismatch, bindSourceSet(&changes, &staged, &worktree));

    var final = closure;
    final.staged_tree.bytes[0] ^= 1;
    try std.testing.expectError(error.StructuredClosureDrift, requireSameClosure(&closure, &final));

    const evidence = syntheticEvidence(0x41);
    var output: [receipt_max_bytes]u8 = undefined;
    var malformed = closure;
    malformed.sources[0].mode = 0o100755;
    try std.testing.expectError(error.StructuredClosureInvalid, encodeReceipt(&output, &malformed, &evidence));
    malformed = closure;
    malformed.sources[1].length = 0;
    try std.testing.expectError(error.StructuredClosureInvalid, encodeReceipt(&output, &malformed, &evidence));
    malformed = closure;
    malformed.staged_tree.bytes = @splat(0);
    try std.testing.expectError(error.StructuredClosureInvalid, encodeReceipt(&output, &malformed, &evidence));
}

test "run evidence rejects selector source descriptor admission record result and counter drift" {
    const evidence = syntheticEvidence(0x51);
    try validateRunEvidence(&evidence);
    var changed = evidence;
    changed.selector_final.sha256.bytes[0] ^= 1;
    try std.testing.expectError(error.SelectorEvidenceDrift, validateRunEvidence(&changed));
    changed = evidence;
    changed.source_final.use_sha256.bytes[0] ^= 1;
    try std.testing.expectError(error.SourceEvidenceMismatch, validateRunEvidence(&changed));
    changed = evidence;
    changed.descriptor_final.instruction_count += 1;
    try std.testing.expectError(error.DescriptorEvidenceMismatch, validateRunEvidence(&changed));
    changed = evidence;
    changed.admission.planner_gpr_returns = 2;
    try std.testing.expectError(error.AdmissionEvidenceMismatch, validateRunEvidence(&changed));
    changed = evidence;
    changed.reference_record.stdout_length += 1;
    try std.testing.expectError(error.OracleRecordMismatch, validateRunEvidence(&changed));
    changed = evidence;
    changed.linked_record.semantic_result = 19;
    try std.testing.expectError(error.OracleRecordMismatch, validateRunEvidence(&changed));
    changed = evidence;
    changed.counters.real_programs_ok = 0;
    try std.testing.expectError(error.CounterMismatch, validateRunEvidence(&changed));
}

test "receipt encoding is canonical fixed and omits selector path" {
    const closure = syntheticClosure(0x61);
    const evidence = syntheticEvidence(0x61);
    var first_buffer: [receipt_max_bytes]u8 = undefined;
    var second_buffer: [receipt_max_bytes]u8 = undefined;
    const first = try encodeReceipt(&first_buffer, &closure, &evidence);
    const second = try encodeReceipt(&second_buffer, &closure, &evidence);
    try std.testing.expectEqualSlices(u8, first, second);
    try std.testing.expect(std.mem.startsWith(u8, first, "schema\texecution-oracle-v1-acceptance-v2\n"));
    try std.testing.expect(std.mem.endsWith(u8, first, "completion\tcomplete\n"));
    try std.testing.expect(std.mem.indexOf(u8, first, "selector_path") == null);
    try std.testing.expectEqual(@as(usize, source_count), std.mem.count(u8, first, "_staged_worktree_equal\t1\n"));
    try std.testing.expect(std.mem.indexOf(
        u8,
        first,
        "admission_result_type\tusize\n" ++
            "admission_return_value_drives_output\t1\n" ++
            "admission_expected_result\t18\n",
    ) != null);
}

test "admission receipt fields reject missing reordered malformed and drifted encodings" {
    const admission = syntheticEvidence(0x62).admission;
    const prefix = "schema\texecution-oracle-v1-acceptance-v2\n";
    const result_type = "admission_result_type\tusize\n";
    const drives_output = "admission_return_value_drives_output\t1\n";
    const expected_result = "admission_expected_result\t18\n";
    const suffix = "completion\tcomplete\n";

    try validateReceiptAdmissionFields(
        prefix ++ result_type ++ drives_output ++ expected_result ++ suffix,
        admission,
    );
    try std.testing.expectError(
        error.ReceiptAdmissionMissing,
        validateReceiptAdmissionFields(prefix ++ result_type ++ drives_output ++ suffix, admission),
    );
    try std.testing.expectError(
        error.ReceiptAdmissionOrderMismatch,
        validateReceiptAdmissionFields(prefix ++ drives_output ++ result_type ++ expected_result ++ suffix, admission),
    );
    try std.testing.expectError(
        error.ReceiptAdmissionMalformed,
        validateReceiptAdmissionFields(
            prefix ++ result_type ++ "admission_return_value_drives_output\ttrue\n" ++ expected_result ++ suffix,
            admission,
        ),
    );
    try std.testing.expectError(
        error.ReceiptAdmissionDrift,
        validateReceiptAdmissionFields(
            prefix ++ result_type ++ drives_output ++ "admission_expected_result\t19\n" ++ suffix,
            admission,
        ),
    );
}

test "publication is atomic no replace exact readback and ordered after closure" {
    const io = std.testing.io;
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    var directory = try temporary.dir.openDir(io, ".", .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer directory.close(io);
    const initial = syntheticClosure(0x71);
    const evidence = syntheticEvidence(0x71);
    var drifted = initial;
    drifted.sources[1].raw_sha256.bytes[0] ^= 1;
    try std.testing.expectError(
        error.StructuredClosureDrift,
        finalizeAndPublish(std.testing.allocator, io, directory, &initial, &drifted, &evidence),
    );
    _ = temporary.dir.statFile(io, receipt_name, .{ .follow_symlinks = false }) catch |failure| switch (failure) {
        error.FileNotFound => {},
        else => return failure,
    };
    const published = try finalizeAndPublish(std.testing.allocator, io, directory, &initial, &initial, &evidence);
    try std.testing.expect(published.length > 0);
    try std.testing.expectError(
        error.ReceiptCollision,
        finalizeAndPublish(std.testing.allocator, io, directory, &initial, &initial, &evidence),
    );
}

test "temporary Git repository observation validates exact five staged paths only" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    try temporary.dir.createDir(io, "src", .default_dir);
    try temporary.dir.writeFile(io, .{ .sub_path = source_paths[0], .data = "base-build\n" });
    try temporary.dir.writeFile(io, .{ .sub_path = source_paths[1], .data = "base-gate\n" });
    try temporary.dir.writeFile(io, .{ .sub_path = source_paths[2], .data = "base-air\n" });
    var path_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const path_length = try temporary.dir.realPath(io, &path_buffer);
    const repository = path_buffer[0..path_length];
    try runTestGit(allocator, io, repository, &.{ "init", "-q" });
    try runTestGit(allocator, io, repository, &.{ "add", "--", source_paths[0], source_paths[1], source_paths[2] });
    try runTestGit(allocator, io, repository, &.{
        "-c", "user.name=synthetic", "-c", "user.email=synthetic@example.invalid", "commit", "-q", "-m", "base",
    });
    try temporary.dir.writeFile(io, .{ .sub_path = source_paths[0], .data = "changed-build\n" });
    try temporary.dir.writeFile(io, .{ .sub_path = source_paths[1], .data = "changed-gate\n" });
    try temporary.dir.writeFile(io, .{ .sub_path = source_paths[2], .data = "changed-air\n" });
    try temporary.dir.writeFile(io, .{ .sub_path = source_paths[3], .data = "oracle\n" });
    try temporary.dir.writeFile(io, .{ .sub_path = source_paths[4], .data = "acceptance\n" });
    try runTestGit(allocator, io, repository, &.{ "add", "--", source_paths[0], source_paths[1], source_paths[2], source_paths[3], source_paths[4] });
    const observed = try observeClosureAt(allocator, io, repository);
    try std.testing.expect(std.meta.eql(observed.statuses, expected_status));
    try temporary.dir.writeFile(io, .{ .sub_path = "extra.zig", .data = "extra\n" });
    try runTestGit(allocator, io, repository, &.{ "add", "--", "extra.zig" });
    try std.testing.expectError(error.ExtraStagedPath, observeClosureAt(allocator, io, repository));
}
