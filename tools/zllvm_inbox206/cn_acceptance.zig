const std = @import("std");

const Sha1 = std.crypto.hash.Sha1;
const Sha256 = std.crypto.hash.sha2.Sha256;

const repository_root = "/home/oleg/prog/z_llvm";
const external_zig_root = "/home/oleg/prog/ziglang";
const required_zig_version = "0.16.0";
const pinned_external_zig_revision = "bdee02bc0c7f227c0f11bc9a449df673fe803540";
const completion_receipt_name = "combined_acceptance_receipt_v1.tsv";
const mapper_sidecar_path = "local-state/validations/inbox206cn-definition-mapper/rank2_definition_mapping_v1.tsv";
const path_b_receipt_path = "local-state/validations/inbox206cn/path_b_synthetic_receipt.tsv";
const local_cache_directory = "local-state/caches/inbox206cn/local";
const global_cache_directory = "local-state/caches/inbox206cn/global";
const receipt_schema = "inbox206cn-combined-acceptance-v1";
const source_mode: u32 = 0o100644;
const source_count = 8;
const receipt_max_bytes = 16 * 1024;
const source_max_bytes = 4 * 1024 * 1024;
const process_stdout_max = 4 * 1024 * 1024;
const process_stderr_max = 4 * 1024 * 1024;
const zig_executable_max_bytes = 512 * 1024 * 1024;

const source_paths = [source_count][]const u8{
    "build.zig",
    "tools/derive_real_candidate_definition.zig",
    "tools/zllvm_inbox206/acceptance_driver.zig",
    "tools/zllvm_inbox206/acceptance_driver_test.zig",
    "tools/zllvm_inbox206/cn_acceptance.zig",
    "tools/zllvm_inbox206/provenance.zig",
    "tools/zllvm_inbox206/receipt.zig",
    "tools/zllvm_inbox206_materialize.zig",
};

const GateId = enum(u8) {
    format_check,
    path_b_test,
    mapper_test,
    mapper_ordinary,
    mapper_poisoned,
};

const gate_count = @typeInfo(GateId).@"enum".fields.len;
const closure_check_count = gate_count + 1;
const gate_field_names = [gate_count][]const u8{
    "gate_format_status",
    "gate_path_b_test_status",
    "gate_mapper_test_status",
    "gate_mapper_ordinary_status",
    "gate_mapper_poisoned_status",
};

const gate_diagnostic_magic = "ZLLVMGD1";
const gate_diagnostic_header_size = gate_diagnostic_magic.len + 4 + 8 + 8;

const GateTermination = enum(u8) {
    exited = 1,
};

const Identity20 = struct { bytes: [20]u8 };
const Identity32 = struct { bytes: [32]u8 };

const SourceIdentity = struct {
    mode: u32,
    blob: Identity20,
    raw_sha256: Identity32,
    length: u64,
};

const ArtifactIdentity = struct {
    raw_sha256: Identity32,
    length: u64,
};

const GateResults = struct {
    status: [gate_count]u8,
};

const AcceptanceEvidence = struct {
    sources: [source_count]SourceIdentity,
    staged_worktree_equal: [source_count]bool,
    staged_tree: Identity20,
    external_zig_revision: Identity20,
    zig_executable: ArtifactIdentity,
    gates: GateResults,
    path_b_receipt: ArtifactIdentity,
    mapper_ordinary: ArtifactIdentity,
    mapper_poisoned: ArtifactIdentity,
};

const StructuredClosure = struct {
    sources: [source_count]SourceIdentity,
    staged_status: [source_count]StagedStatus,
    staged_tree: Identity20,
    external_zig_revision: Identity20,
    external_zig_clean: bool,
    zig_executable: ArtifactIdentity,
};

const AcceptanceError = error{
    ArtifactEmpty,
    ArtifactMismatch,
    ChildFailed,
    ChildOutputBoundExceeded,
    CompletionCollision,
    CompletionReadBackMismatch,
    ClosureExternalRevisionMismatch,
    ClosureSourceMismatch,
    ClosureTreeMismatch,
    ClosureZigExecutableMismatch,
    DuplicateStagedPath,
    EmptyStagedSet,
    ExternalRevisionMismatch,
    ExtraStagedPath,
    GateFailed,
    GitObjectAlgorithmUnsupported,
    GitOutputMalformed,
    InvalidArguments,
    InvalidSourceLength,
    InvalidSourceMode,
    MapperResultMismatch,
    MissingStagedPath,
    NonCanonicalReceipt,
    SourceBlobMismatch,
    SourceBytesMismatch,
    SourceDigestMismatch,
    SourceOrderMismatch,
    StagedStatusMismatch,
    StagedTreeInvalid,
    ZigExecutableInvalid,
    ZigExecutableNotRegular,
    ZigExecutableNotExecutable,
    ZigSelectorInvalid,
    ZigVersionMismatch,
};

const ProcessClass = enum {
    git,
    zig,
    zig_poisoned_mapper,
};

const FixedProcess = struct {
    class: ProcessClass,
    argv: []const []const u8,
    cwd: []const u8,
    stdout_limit: usize,
    stderr_limit: usize,
};

const git_environment = [_][]const u8{
    "LC_ALL=C",
    "LANG=C",
    "TZ=UTC0",
    "HOME=/nonexistent",
    "XDG_CONFIG_HOME=/nonexistent",
    "GIT_OPTIONAL_LOCKS=0",
    "GIT_CONFIG_NOSYSTEM=1",
    "GIT_CONFIG_SYSTEM=/dev/null",
    "GIT_CONFIG_GLOBAL=/dev/null",
    "GIT_CONFIG_COUNT=0",
    "GIT_TERMINAL_PROMPT=0",
    "GIT_PAGER=cat",
    "PAGER=cat",
};

const zig_environment = [_][]const u8{
    "LC_ALL=C",
    "LANG=C",
    "TZ=UTC0",
    "HOME=/nonexistent",
    "XDG_CONFIG_HOME=/nonexistent",
    "ZIG_LOCAL_CACHE_DIR=" ++ local_cache_directory,
    "ZIG_GLOBAL_CACHE_DIR=" ++ global_cache_directory,
};

const zig_poisoned_mapper_environment = [_][]const u8{
    "LC_ALL=tr_TR.UTF-8",
    "LANG=tr_TR.UTF-8",
    "TZ=Pacific/Kiritimati",
    "HOME=/nonexistent",
    "XDG_CONFIG_HOME=/nonexistent",
    "ZIG_LOCAL_CACHE_DIR=" ++ local_cache_directory,
    "ZIG_GLOBAL_CACHE_DIR=" ++ global_cache_directory,
    "GIT_CONFIG_NOSYSTEM=0",
    "GIT_CONFIG_SYSTEM=/__zllvm_inbox206cn_poison_system_config__",
    "GIT_CONFIG_GLOBAL=/__zllvm_inbox206cn_poison_global_config__",
    "GIT_OPTIONAL_LOCKS=1",
    "GIT_DIR=/__zllvm_inbox206cn_poison_git_dir__",
    "GIT_WORK_TREE=/__zllvm_inbox206cn_poison_work_tree__",
    "GIT_INDEX_FILE=/__zllvm_inbox206cn_poison_index__",
    "GIT_COMMON_DIR=/__zllvm_inbox206cn_poison_common__",
    "GIT_OBJECT_DIRECTORY=/__zllvm_inbox206cn_poison_objects__",
    "GIT_ALTERNATE_OBJECT_DIRECTORIES=/__zllvm_inbox206cn_poison_alternates__",
};

const git_object_format_argv = [_][]const u8{
    "/usr/bin/git", "--no-optional-locks", "-c",        "core.fsmonitor=false", "-c", "core.untrackedCache=false",
    "-C",           repository_root,       "rev-parse", "--show-object-format",
};

const git_staged_listing_argv = [_][]const u8{
    "/usr/bin/git",      "--no-optional-locks",      "-c",           "core.fsmonitor=false", "-c", "core.untrackedCache=false",
    "-C",                repository_root,            "status",       "--porcelain=v2",       "-z", "--untracked-files=all",
    "--no-ahead-behind", "--ignore-submodules=none", "--no-renames",
};

const git_staged_tree_argv = [_][]const u8{
    "/usr/bin/git", "--no-optional-locks", "-c",         "core.fsmonitor=false", "-c", "core.untrackedCache=false",
    "-C",           repository_root,       "write-tree",
};

const git_external_revision_argv = [_][]const u8{
    "/usr/bin/git", "--no-optional-locks", "-c",        "core.fsmonitor=false", "-c", "core.untrackedCache=false",
    "-C",           external_zig_root,     "rev-parse", "HEAD",
};

const git_external_status_argv = [_][]const u8{
    "/usr/bin/git", "--no-optional-locks", "-c",     "core.fsmonitor=false", "-c", "core.untrackedCache=false",
    "-C",           external_zig_root,     "status", "--short",
};

fn zigFormatArgv(executable: []const u8) [source_count + 3][]const u8 {
    return .{
        executable,      "fmt",           "--check",
        source_paths[0], source_paths[1], source_paths[2],
        source_paths[3], source_paths[4], source_paths[5],
        source_paths[6], source_paths[7],
    };
}

fn zigPathBTestArgv(executable: []const u8) [3][]const u8 {
    return .{ executable, "build", "test-inbox206-path-b-real-process" };
}

fn zigMapperTestArgv(executable: []const u8) [3][]const u8 {
    return .{ executable, "build", "test-real-candidate-definition-mapper" };
}

fn zigMapperDeriveArgv(executable: []const u8) [3][]const u8 {
    return .{ executable, "build", "derive-real-candidate-definition" };
}

fn zigVersionArgv(executable: []const u8) [2][]const u8 {
    return .{ executable, "version" };
}

fn fixedProcess(class: ProcessClass, argv: []const []const u8, cwd: []const u8) FixedProcess {
    return .{
        .class = class,
        .argv = argv,
        .cwd = cwd,
        .stdout_limit = process_stdout_max,
        .stderr_limit = process_stderr_max,
    };
}

fn isCanonicalRelativePath(path: []const u8) bool {
    if (path.len == 0 or path[0] == '/' or std.mem.indexOfScalar(u8, path, 0) != null) return false;
    var components = std.mem.splitScalar(u8, path, '/');
    while (components.next()) |component| {
        if (component.len == 0 or std.mem.eql(u8, component, ".") or std.mem.eql(u8, component, "..")) return false;
    }
    return true;
}

fn sourcePathIndex(path: []const u8) ?usize {
    for (source_paths, 0..) |expected, index| {
        if (std.mem.eql(u8, path, expected)) return index;
    }
    return null;
}

fn rawIdentity(bytes: []const u8) Identity32 {
    var digest: [Sha256.digest_length]u8 = undefined;
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

fn sourceIdentity(bytes: []const u8) AcceptanceError!SourceIdentity {
    if (bytes.len == 0 or bytes.len > source_max_bytes) return error.InvalidSourceLength;
    return .{
        .mode = source_mode,
        .blob = gitBlobIdentity(bytes),
        .raw_sha256 = rawIdentity(bytes),
        .length = @intCast(bytes.len),
    };
}

fn artifactIdentity(bytes: []const u8) AcceptanceError!ArtifactIdentity {
    if (bytes.len == 0) return error.ArtifactEmpty;
    return .{ .raw_sha256 = rawIdentity(bytes), .length = @intCast(bytes.len) };
}

fn equalIdentity20(left: Identity20, right: Identity20) bool {
    return std.mem.eql(u8, &left.bytes, &right.bytes);
}

fn equalIdentity32(left: Identity32, right: Identity32) bool {
    return std.mem.eql(u8, &left.bytes, &right.bytes);
}

fn equalArtifact(left: ArtifactIdentity, right: ArtifactIdentity) bool {
    return left.length == right.length and equalIdentity32(left.raw_sha256, right.raw_sha256);
}

fn requireSameClosure(
    expected: *const StructuredClosure,
    observed: *const StructuredClosure,
) AcceptanceError!void {
    for (expected.sources, observed.sources) |left, right| {
        if (left.mode != right.mode or left.length != right.length or
            !equalIdentity20(left.blob, right.blob) or
            !equalIdentity32(left.raw_sha256, right.raw_sha256))
        {
            return error.ClosureSourceMismatch;
        }
    }
    if (!std.meta.eql(expected.staged_status, observed.staged_status)) {
        return error.ClosureSourceMismatch;
    }
    if (!equalIdentity20(expected.staged_tree, observed.staged_tree)) {
        return error.ClosureTreeMismatch;
    }
    if (!expected.external_zig_clean or !observed.external_zig_clean or
        !equalIdentity20(expected.external_zig_revision, observed.external_zig_revision))
    {
        return error.ClosureExternalRevisionMismatch;
    }
    if (!equalArtifact(expected.zig_executable, observed.zig_executable)) {
        return error.ClosureZigExecutableMismatch;
    }
}

fn finalizeEvidence(
    initial: *const StructuredClosure,
    successive: *const [closure_check_count]StructuredClosure,
    gates: GateResults,
    path_b_receipt: ArtifactIdentity,
    mapper_ordinary_claim: ArtifactIdentity,
    mapper_poisoned_claim: ArtifactIdentity,
    mapper_final: ArtifactIdentity,
) AcceptanceError!AcceptanceEvidence {
    for (successive) |*observed| try requireSameClosure(initial, observed);
    if (!equalArtifact(mapper_ordinary_claim, mapper_poisoned_claim) or
        !equalArtifact(mapper_ordinary_claim, mapper_final))
    {
        return error.MapperResultMismatch;
    }
    const evidence = AcceptanceEvidence{
        .sources = initial.sources,
        .staged_worktree_equal = [_]bool{true} ** source_count,
        .staged_tree = initial.staged_tree,
        .external_zig_revision = initial.external_zig_revision,
        .zig_executable = initial.zig_executable,
        .gates = gates,
        .path_b_receipt = path_b_receipt,
        .mapper_ordinary = mapper_ordinary_claim,
        .mapper_poisoned = mapper_poisoned_claim,
    };
    try validateEvidence(&evidence);
    return evidence;
}

fn validateEvidence(evidence: *const AcceptanceEvidence) AcceptanceError!void {
    for (evidence.sources, evidence.staged_worktree_equal) |source, equal| {
        if (source.mode != source_mode) return error.InvalidSourceMode;
        if (source.length == 0 or source.length > source_max_bytes) return error.InvalidSourceLength;
        if (!equal) return error.SourceBytesMismatch;
    }
    if (std.mem.allEqual(u8, &evidence.staged_tree.bytes, 0)) return error.StagedTreeInvalid;
    var expected_revision: [20]u8 = undefined;
    decodeLowerHex(pinned_external_zig_revision, &expected_revision) catch unreachable;
    if (!std.mem.eql(u8, &evidence.external_zig_revision.bytes, &expected_revision)) {
        return error.ExternalRevisionMismatch;
    }
    if (evidence.zig_executable.length == 0 or
        evidence.zig_executable.length > zig_executable_max_bytes or
        std.mem.allEqual(u8, &evidence.zig_executable.raw_sha256.bytes, 0))
    {
        return error.ZigExecutableInvalid;
    }
    for (evidence.gates.status) |status| if (status != 0) return error.GateFailed;
    if (!equalArtifact(evidence.mapper_ordinary, evidence.mapper_poisoned)) {
        return error.MapperResultMismatch;
    }
    if (evidence.path_b_receipt.length == 0 or evidence.mapper_ordinary.length == 0) {
        return error.ArtifactEmpty;
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

fn decodeLowerHex(bytes: []const u8, output: []u8) !void {
    if (bytes.len != output.len * 2) return error.GitOutputMalformed;
    for (output, 0..) |*byte, index| {
        const high = try decodeNibble(bytes[index * 2]);
        const low = try decodeNibble(bytes[index * 2 + 1]);
        byte.* = (high << 4) | low;
    }
}

fn decodeNibble(byte: u8) !u8 {
    return switch (byte) {
        '0'...'9' => byte - '0',
        'a'...'f' => byte - 'a' + 10,
        else => error.GitOutputMalformed,
    };
}

fn writeHex(writer: *std.Io.Writer, bytes: []const u8) !void {
    for (bytes) |byte| {
        try writer.writeByte(lowerHexNibble(byte >> 4));
        try writer.writeByte(lowerHexNibble(byte & 0x0f));
    }
}

fn writeField(writer: *std.Io.Writer, name: []const u8, value: []const u8) !void {
    if (name.len == 0 or value.len == 0 or
        std.mem.indexOfAny(u8, name, "\t\r\n") != null or
        std.mem.indexOfAny(u8, value, "\t\r\n") != null)
    {
        return error.NonCanonicalReceipt;
    }
    try writer.writeAll(name);
    try writer.writeByte('\t');
    try writer.writeAll(value);
    try writer.writeByte('\n');
}

fn writeDecimalField(writer: *std.Io.Writer, name: []const u8, value: u64) !void {
    var buffer: [32]u8 = undefined;
    const encoded = try std.fmt.bufPrint(&buffer, "{d}", .{value});
    try writeField(writer, name, encoded);
}

fn encodeReceipt(output: *[receipt_max_bytes]u8, evidence: *const AcceptanceEvidence) ![]const u8 {
    try validateEvidence(evidence);
    var stream = std.Io.Writer.fixed(output);
    const writer = &stream;
    try writeField(writer, "schema", receipt_schema);
    try writeDecimalField(writer, "source_count", source_count);
    for (source_paths, evidence.sources, 0..) |path, source, index| {
        var name_buffer: [64]u8 = undefined;
        const path_name = try std.fmt.bufPrint(&name_buffer, "source_{d}_path", .{index});
        try writeField(writer, path_name, path);
        const mode_name = try std.fmt.bufPrint(&name_buffer, "source_{d}_mode", .{index});
        try writeField(writer, mode_name, "100644");
        var blob_hex: [40]u8 = undefined;
        encodeLowerHex(&source.blob.bytes, &blob_hex);
        const blob_name = try std.fmt.bufPrint(&name_buffer, "source_{d}_blob_sha1", .{index});
        try writeField(writer, blob_name, &blob_hex);
        var raw_hex: [64]u8 = undefined;
        encodeLowerHex(&source.raw_sha256.bytes, &raw_hex);
        const raw_name = try std.fmt.bufPrint(&name_buffer, "source_{d}_raw_sha256", .{index});
        try writeField(writer, raw_name, &raw_hex);
        const length_name = try std.fmt.bufPrint(&name_buffer, "source_{d}_length", .{index});
        try writeDecimalField(writer, length_name, source.length);
        const equality_name = try std.fmt.bufPrint(&name_buffer, "source_{d}_staged_worktree_equal", .{index});
        try writeField(writer, equality_name, "1");
    }
    var hex20: [40]u8 = undefined;
    encodeLowerHex(&evidence.staged_tree.bytes, &hex20);
    try writeField(writer, "staged_tree_sha1", &hex20);
    encodeLowerHex(&evidence.external_zig_revision.bytes, &hex20);
    try writeField(writer, "external_zig_revision", &hex20);
    var hex32: [64]u8 = undefined;
    try writeField(writer, "zig_version", required_zig_version);
    encodeLowerHex(&evidence.zig_executable.raw_sha256.bytes, &hex32);
    try writeField(writer, "zig_executable_sha256", &hex32);
    try writeDecimalField(writer, "zig_executable_length", evidence.zig_executable.length);
    for (evidence.gates.status, gate_field_names) |status, name| {
        try writeDecimalField(writer, name, status);
    }
    encodeLowerHex(&evidence.path_b_receipt.raw_sha256.bytes, &hex32);
    try writeField(writer, "path_b_receipt_sha256", &hex32);
    try writeDecimalField(writer, "path_b_receipt_length", evidence.path_b_receipt.length);
    encodeLowerHex(&evidence.mapper_ordinary.raw_sha256.bytes, &hex32);
    try writeField(writer, "mapper_sidecar_sha256", &hex32);
    try writeDecimalField(writer, "mapper_sidecar_length", evidence.mapper_ordinary.length);
    try writeField(writer, "mapper_ordinary_poisoned_equal", "1");
    try writeField(writer, "completion", "complete");
    return stream.buffered();
}

const StagedStatus = enum { added, modified };

const StagedChange = struct {
    path_index: usize,
    blob: Identity20,
    status: StagedStatus,
};

fn parseStagedListing(bytes: []const u8) AcceptanceError![source_count]StagedChange {
    if (bytes.len == 0) return error.EmptyStagedSet;
    var result: [source_count]StagedChange = undefined;
    var seen = [_]bool{false} ** source_count;
    var record_index: usize = 0;
    var offset: usize = 0;
    while (offset < bytes.len) {
        const relative_end = std.mem.indexOfScalar(u8, bytes[offset..], 0) orelse return error.GitOutputMalformed;
        const record = bytes[offset .. offset + relative_end];
        offset += relative_end + 1;
        if (record.len == 0 or !std.mem.startsWith(u8, record, "1 ")) return error.GitOutputMalformed;
        if (record_index >= source_count) return error.ExtraStagedPath;
        var fields: [9][]const u8 = undefined;
        var field_count: usize = 0;
        var iterator = std.mem.splitScalar(u8, record, ' ');
        while (iterator.next()) |field| {
            if (field.len == 0 or field_count == fields.len) return error.GitOutputMalformed;
            fields[field_count] = field;
            field_count += 1;
        }
        if (field_count != fields.len or !std.mem.eql(u8, fields[0], "1")) return error.GitOutputMalformed;
        if (!std.mem.eql(u8, fields[1], "A.") and !std.mem.eql(u8, fields[1], "M.")) return error.StagedStatusMismatch;
        if (!std.mem.eql(u8, fields[2], "N...") or
            !std.mem.eql(u8, fields[4], "100644") or
            !std.mem.eql(u8, fields[5], "100644")) return error.InvalidSourceMode;
        if ((std.mem.eql(u8, fields[1], "A.") and !std.mem.eql(u8, fields[3], "000000")) or
            (std.mem.eql(u8, fields[1], "M.") and !std.mem.eql(u8, fields[3], "100644")))
        {
            return error.InvalidSourceMode;
        }
        const path_index = sourcePathIndex(fields[8]) orelse return error.ExtraStagedPath;
        if (seen[path_index]) return error.DuplicateStagedPath;
        if (path_index != record_index) return error.SourceOrderMismatch;
        var blob: [20]u8 = undefined;
        decodeLowerHex(fields[7], &blob) catch return error.GitOutputMalformed;
        if (std.mem.allEqual(u8, &blob, 0)) return error.SourceBlobMismatch;
        seen[path_index] = true;
        result[record_index] = .{
            .path_index = path_index,
            .blob = .{ .bytes = blob },
            .status = if (std.mem.eql(u8, fields[1], "A.")) .added else .modified,
        };
        record_index += 1;
    }
    if (record_index != source_count) return error.MissingStagedPath;
    return result;
}

fn parseSha1Line(bytes: []const u8) AcceptanceError!Identity20 {
    if (bytes.len != 41 or bytes[40] != '\n') return error.GitOutputMalformed;
    var identity: [20]u8 = undefined;
    decodeLowerHex(bytes[0..40], &identity) catch return error.GitOutputMalformed;
    if (std.mem.allEqual(u8, &identity, 0)) return error.GitOutputMalformed;
    return .{ .bytes = identity };
}

fn parseCanonicalDecimal(bytes: []const u8) AcceptanceError!u64 {
    if (bytes.len == 0 or (bytes.len > 1 and bytes[0] == '0')) return error.GitOutputMalformed;
    var value: u64 = 0;
    for (bytes) |byte| {
        if (byte < '0' or byte > '9') return error.GitOutputMalformed;
        value = std.math.mul(u64, value, 10) catch return error.GitOutputMalformed;
        value = std.math.add(u64, value, byte - '0') catch return error.GitOutputMalformed;
    }
    return value;
}

fn parseMapperResult(bytes: []const u8) AcceptanceError!ArtifactIdentity {
    const prefix = "rank2-definition-mapping-ok schema=execution-oracle-definition-mapping-v1 path=" ++ mapper_sidecar_path ++ " bytes=";
    const separator = " sha256=";
    if (!std.mem.startsWith(u8, bytes, prefix) or bytes.len <= prefix.len or bytes[bytes.len - 1] != '\n') {
        return error.ArtifactMismatch;
    }
    const separator_offset = std.mem.indexOf(u8, bytes[prefix.len..], separator) orelse return error.ArtifactMismatch;
    const length_end = prefix.len + separator_offset;
    const digest_start = length_end + separator.len;
    if (digest_start + 64 + 1 != bytes.len) return error.ArtifactMismatch;
    const length = parseCanonicalDecimal(bytes[prefix.len..length_end]) catch return error.ArtifactMismatch;
    var digest: [32]u8 = undefined;
    decodeLowerHex(bytes[digest_start .. digest_start + 64], &digest) catch return error.ArtifactMismatch;
    if (length == 0 or std.mem.allEqual(u8, &digest, 0)) return error.ArtifactMismatch;
    return .{ .raw_sha256 = .{ .bytes = digest }, .length = length };
}

fn synthesizeEvidence(seed: u8) AcceptanceEvidence {
    var sources: [source_count]SourceIdentity = undefined;
    for (&sources, 0..) |*source, index| {
        var bytes = [_]u8{seed} ** 16;
        bytes[0] +%= @intCast(index);
        source.* = sourceIdentity(&bytes) catch unreachable;
    }
    var revision: [20]u8 = undefined;
    decodeLowerHex(pinned_external_zig_revision, &revision) catch unreachable;
    return .{
        .sources = sources,
        .staged_worktree_equal = [_]bool{true} ** source_count,
        .staged_tree = .{ .bytes = [_]u8{0x55} ** 20 },
        .external_zig_revision = .{ .bytes = revision },
        .zig_executable = .{ .raw_sha256 = .{ .bytes = [_]u8{0x66} ** 32 }, .length = 12345 },
        .gates = .{ .status = [_]u8{0} ** gate_count },
        .path_b_receipt = .{ .raw_sha256 = .{ .bytes = [_]u8{0x77} ** 32 }, .length = 962 },
        .mapper_ordinary = .{ .raw_sha256 = .{ .bytes = [_]u8{0x88} ** 32 }, .length = 1055 },
        .mapper_poisoned = .{ .raw_sha256 = .{ .bytes = [_]u8{0x88} ** 32 }, .length = 1055 },
    };
}

fn closureFromEvidence(evidence: *const AcceptanceEvidence) StructuredClosure {
    return .{
        .sources = evidence.sources,
        .staged_status = [_]StagedStatus{.modified} ** source_count,
        .staged_tree = evidence.staged_tree,
        .external_zig_revision = evidence.external_zig_revision,
        .external_zig_clean = true,
        .zig_executable = evidence.zig_executable,
    };
}

fn makeStatusListing(output: *[8192]u8, evidence: *const AcceptanceEvidence) ![]const u8 {
    var stream = std.Io.Writer.fixed(output);
    const writer = &stream;
    var zero: [40]u8 = [_]u8{'0'} ** 40;
    _ = &zero;
    for (source_paths, evidence.sources) |path, source| {
        var blob: [40]u8 = undefined;
        encodeLowerHex(&source.blob.bytes, &blob);
        try writer.print("1 A. N... 000000 100644 100644 {s} {s} {s}", .{ &zero, &blob, path });
        try writer.writeByte(0);
    }
    return stream.buffered();
}

fn bindSourceSet(
    changes: *const [source_count]StagedChange,
    staged: *const [source_count][]const u8,
    worktree: *const [source_count][]const u8,
) AcceptanceError![source_count]SourceIdentity {
    var result: [source_count]SourceIdentity = undefined;
    for (changes, staged, worktree, &result, 0..) |change, staged_bytes, worktree_bytes, *identity, index| {
        if (change.path_index != index) return error.SourceOrderMismatch;
        if (!std.mem.eql(u8, staged_bytes, worktree_bytes)) return error.SourceBytesMismatch;
        identity.* = try sourceIdentity(staged_bytes);
        if (!equalIdentity20(identity.blob, change.blob)) return error.SourceBlobMismatch;
    }
    return result;
}

fn createEnvironment(
    allocator: std.mem.Allocator,
    entries: []const []const u8,
) !std.process.Environ.Map {
    var environment = std.process.Environ.Map.init(allocator);
    errdefer environment.deinit();
    for (entries) |entry| {
        const separator = std.mem.indexOfScalar(u8, entry, '=') orelse return error.ChildFailed;
        if (separator == 0 or separator + 1 > entry.len) return error.ChildFailed;
        try environment.put(entry[0..separator], entry[separator + 1 ..]);
    }
    return environment;
}

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

fn encodeGateFailureDiagnostic(
    writer: *std.Io.Writer,
    gate: GateId,
    result: *const OwnedProcessResult,
) !void {
    if (result.stdout.len > process_stdout_max or result.stderr.len > process_stderr_max) {
        return error.DiagnosticCaptureBoundExceeded;
    }
    const stdout_length = std.math.cast(u64, result.stdout.len) orelse
        return error.DiagnosticCaptureBoundExceeded;
    const stderr_length = std.math.cast(u64, result.stderr.len) orelse
        return error.DiagnosticCaptureBoundExceeded;

    var header: [gate_diagnostic_header_size]u8 = undefined;
    @memcpy(header[0..gate_diagnostic_magic.len], gate_diagnostic_magic);
    header[gate_diagnostic_magic.len] = @intFromEnum(gate);
    header[gate_diagnostic_magic.len + 1] = @intFromEnum(GateTermination.exited);
    header[gate_diagnostic_magic.len + 2] = result.status;
    header[gate_diagnostic_magic.len + 3] = 0;
    std.mem.writeInt(u64, header[gate_diagnostic_magic.len + 4 ..][0..8], stdout_length, .little);
    std.mem.writeInt(u64, header[gate_diagnostic_magic.len + 12 ..][0..8], stderr_length, .little);

    try writer.writeAll(&header);
    try writer.writeAll(result.stdout);
    try writer.writeAll(result.stderr);
}

fn requireGateSuccess(
    writer: *std.Io.Writer,
    gate: GateId,
    result: *const OwnedProcessResult,
) AcceptanceError!void {
    if (result.status == 0) return;
    encodeGateFailureDiagnostic(writer, gate, result) catch {};
    return error.GateFailed;
}

fn reportGateFailure(gate: GateId, result: *const OwnedProcessResult) AcceptanceError {
    var buffer: [4096]u8 = undefined;
    const stderr = std.debug.lockStderr(&buffer);
    defer std.debug.unlockStderr();
    requireGateSuccess(&stderr.file_writer.interface, gate, result) catch |failure| return failure;
    unreachable;
}

fn processEnvironment(class: ProcessClass) []const []const u8 {
    return switch (class) {
        .git => &git_environment,
        .zig => &zig_environment,
        .zig_poisoned_mapper => &zig_poisoned_mapper_environment,
    };
}

fn runFixedProcess(
    allocator: std.mem.Allocator,
    io: std.Io,
    specification: FixedProcess,
) !OwnedProcessResult {
    if (specification.argv.len == 0 or
        !std.fs.path.isAbsolute(specification.argv[0]) or
        !std.fs.path.isAbsolute(specification.cwd))
    {
        return error.ChildFailed;
    }
    var environment = try createEnvironment(allocator, processEnvironment(specification.class));
    defer environment.deinit();
    const raw = std.process.run(allocator, io, .{
        .argv = specification.argv,
        .cwd = .{ .path = specification.cwd },
        .environ_map = &environment,
        .stdout_limit = .limited(specification.stdout_limit),
        .stderr_limit = .limited(specification.stderr_limit),
    }) catch |failure| switch (failure) {
        error.StreamTooLong => return error.ChildOutputBoundExceeded,
        else => return error.ChildFailed,
    };
    errdefer allocator.free(raw.stdout);
    errdefer allocator.free(raw.stderr);
    const status: u8 = switch (raw.term) {
        .exited => |code| code,
        else => return error.ChildFailed,
    };
    return .{ .stdout = raw.stdout, .stderr = raw.stderr, .status = status };
}

fn runSuccessful(
    allocator: std.mem.Allocator,
    io: std.Io,
    specification: FixedProcess,
) !OwnedProcessResult {
    var result = try runFixedProcess(allocator, io, specification);
    errdefer result.deinit(allocator);
    if (result.status != 0) return error.ChildFailed;
    return result;
}

fn readBounded(
    allocator: std.mem.Allocator,
    io: std.Io,
    directory: std.Io.Dir,
    path: []const u8,
    maximum: usize,
) ![]u8 {
    if (!isCanonicalRelativePath(path)) return error.ChildFailed;
    var file = try directory.openFile(io, path, .{
        .mode = .read_only,
        .follow_symlinks = false,
        .resolve_beneath = true,
    });
    defer file.close(io);
    var reader = file.reader(io, &.{});
    return reader.interface.allocRemaining(allocator, .limited(maximum));
}

fn readArtifact(
    allocator: std.mem.Allocator,
    io: std.Io,
    root: std.Io.Dir,
    path: []const u8,
    maximum: usize,
) !ArtifactIdentity {
    const bytes = try readBounded(allocator, io, root, path, maximum);
    defer allocator.free(bytes);
    return artifactIdentity(bytes);
}

fn runGitShow(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
) ![]u8 {
    if (sourcePathIndex(path) == null) return error.ChildFailed;
    var stage_specifier_buffer: [256]u8 = undefined;
    const stage_specifier = try std.fmt.bufPrint(&stage_specifier_buffer, ":{s}", .{path});
    const argv = [_][]const u8{
        "/usr/bin/git", "--no-optional-locks", "-c",   "core.fsmonitor=false", "-c", "core.untrackedCache=false",
        "-C",           repository_root,       "show", stage_specifier,
    };
    const result = try runSuccessful(
        allocator,
        io,
        .{
            .class = .git,
            .argv = &argv,
            .cwd = repository_root,
            .stdout_limit = source_max_bytes,
            .stderr_limit = process_stderr_max,
        },
    );
    defer allocator.free(result.stderr);
    return result.stdout;
}

fn verifyExternalRevision(
    allocator: std.mem.Allocator,
    io: std.Io,
) !Identity20 {
    var status = try runSuccessful(
        allocator,
        io,
        fixedProcess(.git, &git_external_status_argv, repository_root),
    );
    defer status.deinit(allocator);
    if (status.stdout.len != 0) return error.ExternalRevisionMismatch;

    var revision = try runSuccessful(
        allocator,
        io,
        fixedProcess(.git, &git_external_revision_argv, repository_root),
    );
    defer revision.deinit(allocator);
    const parsed = try parseSha1Line(revision.stdout);
    var expected: [20]u8 = undefined;
    try decodeLowerHex(pinned_external_zig_revision, &expected);
    if (!std.mem.eql(u8, &parsed.bytes, &expected)) return error.ExternalRevisionMismatch;
    return parsed;
}

fn validateZigSelector(
    selector: ?[]const u8,
    extra: ?[]const u8,
) AcceptanceError![]const u8 {
    const path = selector orelse return error.ZigSelectorInvalid;
    if (extra != null or !std.fs.path.isAbsolute(path) or
        std.mem.eql(u8, path, "zig") or std.mem.indexOfScalar(u8, path, 0) != null)
    {
        return error.ZigSelectorInvalid;
    }
    return path;
}

fn canonicalizeZigSelector(
    io: std.Io,
    selector: []const u8,
    output: []u8,
) ![]const u8 {
    _ = try validateZigSelector(selector, null);
    const length = try std.Io.Dir.realPathFileAbsolute(io, selector, output);
    const canonical = output[0..length];
    if (!std.fs.path.isAbsolute(canonical)) return error.ZigSelectorInvalid;
    return canonical;
}

fn requireZigVersionOutput(bytes: []const u8) AcceptanceError!void {
    if (!std.mem.eql(u8, bytes, required_zig_version ++ "\n")) {
        return error.ZigVersionMismatch;
    }
}

fn validateZigMeasurement(
    kind: std.Io.File.Kind,
    executable: bool,
    metadata_size: u64,
    bytes: []const u8,
    version_output: []const u8,
) AcceptanceError!ArtifactIdentity {
    if (kind != .file) return error.ZigExecutableNotRegular;
    if (!executable) return error.ZigExecutableNotExecutable;
    const observed = try artifactIdentity(bytes);
    if (observed.length != metadata_size) return error.ZigExecutableInvalid;
    try requireZigVersionOutput(version_output);
    return observed;
}

fn observeZigExecutable(
    allocator: std.mem.Allocator,
    io: std.Io,
    canonical_path: []const u8,
) !ArtifactIdentity {
    if (!std.fs.path.isAbsolute(canonical_path)) return error.ZigSelectorInvalid;
    var file = try std.Io.Dir.openFileAbsolute(io, canonical_path, .{
        .mode = .read_only,
        .follow_symlinks = false,
    });
    defer file.close(io);
    const metadata = try file.stat(io);
    const executable = !std.Io.File.Permissions.has_executable_bit or metadata.permissions.toMode() & 0o111 != 0;
    var reader = file.reader(io, &.{});
    const bytes = try reader.interface.allocRemaining(allocator, .limited(zig_executable_max_bytes));
    defer allocator.free(bytes);
    const version_argv = zigVersionArgv(canonical_path);
    var version = try runSuccessful(
        allocator,
        io,
        fixedProcess(.zig, &version_argv, repository_root),
    );
    defer version.deinit(allocator);
    if (version.stderr.len != 0) return error.ZigVersionMismatch;
    return validateZigMeasurement(metadata.kind, executable, metadata.size, bytes, version.stdout);
}

fn observeStructuredClosure(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_path: []const u8,
) !StructuredClosure {
    var root = try std.Io.Dir.openDirAbsolute(io, repository_root, .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer root.close(io);

    var object_format = try runSuccessful(
        allocator,
        io,
        fixedProcess(.git, &git_object_format_argv, repository_root),
    );
    defer object_format.deinit(allocator);
    if (!std.mem.eql(u8, object_format.stdout, "sha1\n")) return error.GitObjectAlgorithmUnsupported;

    var listing_result = try runSuccessful(
        allocator,
        io,
        fixedProcess(.git, &git_staged_listing_argv, repository_root),
    );
    defer listing_result.deinit(allocator);
    const changes = try parseStagedListing(listing_result.stdout);

    var tree_result = try runSuccessful(
        allocator,
        io,
        fixedProcess(.git, &git_staged_tree_argv, repository_root),
    );
    defer tree_result.deinit(allocator);
    const staged_tree = try parseSha1Line(tree_result.stdout);

    var staged_owned: [source_count]?[]u8 = [_]?[]u8{null} ** source_count;
    var worktree_owned: [source_count]?[]u8 = [_]?[]u8{null} ** source_count;
    defer {
        var index: usize = source_count;
        while (index > 0) {
            index -= 1;
            if (worktree_owned[index]) |bytes| allocator.free(bytes);
            if (staged_owned[index]) |bytes| allocator.free(bytes);
        }
    }
    var staged_slices: [source_count][]const u8 = undefined;
    var worktree_slices: [source_count][]const u8 = undefined;
    for (source_paths, 0..) |path, index| {
        staged_owned[index] = try runGitShow(allocator, io, path);
        worktree_owned[index] = try readBounded(allocator, io, root, path, source_max_bytes);
        staged_slices[index] = staged_owned[index].?;
        worktree_slices[index] = worktree_owned[index].?;
    }
    const sources = try bindSourceSet(&changes, &staged_slices, &worktree_slices);
    var staged_status: [source_count]StagedStatus = undefined;
    for (changes, &staged_status) |change, *status| status.* = change.status;
    const external_revision = try verifyExternalRevision(allocator, io);
    const zig_identity = try observeZigExecutable(allocator, io, zig_path);

    return .{
        .sources = sources,
        .staged_status = staged_status,
        .staged_tree = staged_tree,
        .external_zig_revision = external_revision,
        .external_zig_clean = true,
        .zig_executable = zig_identity,
    };
}

fn collectRealEvidence(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_path: []const u8,
) !AcceptanceEvidence {
    const initial = try observeStructuredClosure(allocator, io, zig_path);
    var successive: [closure_check_count]StructuredClosure = undefined;
    var gates = GateResults{ .status = [_]u8{0} ** gate_count };

    const format_argv = zigFormatArgv(zig_path);
    const path_b_argv = zigPathBTestArgv(zig_path);
    const mapper_test_argv = zigMapperTestArgv(zig_path);
    const mapper_derive_argv = zigMapperDeriveArgv(zig_path);

    const gate_specs = [_]FixedProcess{
        fixedProcess(.zig, &format_argv, repository_root),
        fixedProcess(.zig, &path_b_argv, repository_root),
        fixedProcess(.zig, &mapper_test_argv, repository_root),
    };
    for (gate_specs, 0..) |specification, index| {
        var result = try runFixedProcess(allocator, io, specification);
        defer result.deinit(allocator);
        gates.status[index] = result.status;
        if (result.status != 0) {
            const gate: GateId = @enumFromInt(@as(u8, @intCast(index)));
            return reportGateFailure(gate, &result);
        }
        successive[index] = try observeStructuredClosure(allocator, io, zig_path);
        try requireSameClosure(&initial, &successive[index]);
    }

    var ordinary = try runFixedProcess(
        allocator,
        io,
        fixedProcess(.zig, &mapper_derive_argv, repository_root),
    );
    defer ordinary.deinit(allocator);
    gates.status[@intFromEnum(GateId.mapper_ordinary)] = ordinary.status;
    if (ordinary.status != 0) return reportGateFailure(.mapper_ordinary, &ordinary);
    const mapper_ordinary_claim = try parseMapperResult(ordinary.stdout);
    successive[@intFromEnum(GateId.mapper_ordinary)] = try observeStructuredClosure(allocator, io, zig_path);
    try requireSameClosure(&initial, &successive[@intFromEnum(GateId.mapper_ordinary)]);

    var poisoned = try runFixedProcess(
        allocator,
        io,
        fixedProcess(.zig_poisoned_mapper, &mapper_derive_argv, repository_root),
    );
    defer poisoned.deinit(allocator);
    gates.status[@intFromEnum(GateId.mapper_poisoned)] = poisoned.status;
    if (poisoned.status != 0) return reportGateFailure(.mapper_poisoned, &poisoned);
    const mapper_poisoned_claim = try parseMapperResult(poisoned.stdout);
    successive[@intFromEnum(GateId.mapper_poisoned)] = try observeStructuredClosure(allocator, io, zig_path);
    try requireSameClosure(&initial, &successive[@intFromEnum(GateId.mapper_poisoned)]);

    var root = try std.Io.Dir.openDirAbsolute(io, repository_root, .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer root.close(io);
    const mapper_final = try readArtifact(
        allocator,
        io,
        root,
        mapper_sidecar_path,
        source_max_bytes,
    );
    const path_b_receipt = try readArtifact(
        allocator,
        io,
        root,
        path_b_receipt_path,
        source_max_bytes,
    );
    successive[gate_count] = try observeStructuredClosure(allocator, io, zig_path);
    try requireSameClosure(&initial, &successive[gate_count]);

    return finalizeEvidence(
        &initial,
        &successive,
        gates,
        path_b_receipt,
        mapper_ordinary_claim,
        mapper_poisoned_claim,
        mapper_final,
    );
}

fn publishCompletionInDirectory(
    allocator: std.mem.Allocator,
    io: std.Io,
    directory: std.Io.Dir,
    evidence: *const AcceptanceEvidence,
) !ArtifactIdentity {
    var encoded_buffer: [receipt_max_bytes]u8 = undefined;
    const encoded = try encodeReceipt(&encoded_buffer, evidence);
    var atomic_file = try directory.createFileAtomic(io, completion_receipt_name, .{
        .permissions = .fromMode(0o644),
        .replace = false,
    });
    defer atomic_file.deinit(io);
    try atomic_file.file.writeStreamingAll(io, encoded);
    try atomic_file.file.sync(io);
    atomic_file.link(io) catch |failure| switch (failure) {
        error.PathAlreadyExists => return error.CompletionCollision,
        else => return failure,
    };
    try syncOwnedDirectory(directory, io);

    const read_back = try readBounded(
        allocator,
        io,
        directory,
        completion_receipt_name,
        receipt_max_bytes,
    );
    defer allocator.free(read_back);
    if (!std.mem.eql(u8, read_back, encoded)) return error.CompletionReadBackMismatch;
    return artifactIdentity(read_back);
}

fn syncOwnedDirectory(directory: std.Io.Dir, io: std.Io) !void {
    const owned_directory_file = try directory.openFile(io, ".", .{
        .mode = .read_only,
        .allow_directory = true,
        .path_only = false,
        .follow_symlinks = false,
        .resolve_beneath = true,
    });
    defer owned_directory_file.close(io);
    try owned_directory_file.sync(io);
}

fn openLiteralValidationDirectoryAt(
    io: std.Io,
    absolute_root: []const u8,
) !std.Io.Dir {
    if (!std.fs.path.isAbsolute(absolute_root)) return error.ZigSelectorInvalid;
    var root = try std.Io.Dir.openDirAbsolute(io, absolute_root, .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer root.close(io);
    var local_state = try root.openDir(io, "local-state", .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer local_state.close(io);
    var validations = try local_state.openDir(io, "validations", .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer validations.close(io);
    return validations.openDir(io, "inbox206cn", .{
        .access_sub_paths = false,
        .iterate = false,
        .follow_symlinks = false,
    });
}

fn publishCompletion(
    allocator: std.mem.Allocator,
    io: std.Io,
    evidence: *const AcceptanceEvidence,
) !ArtifactIdentity {
    var directory = try openLiteralValidationDirectoryAt(io, repository_root);
    defer directory.close(io);
    return publishCompletionInDirectory(allocator, io, directory, evidence);
}

pub fn main(init: std.process.Init) !void {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, init.gpa);
    defer args.deinit();
    _ = args.next() orelse return error.InvalidArguments;
    const selector = try validateZigSelector(args.next(), args.next());
    var canonical_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const canonical_zig = try canonicalizeZigSelector(init.io, selector, &canonical_buffer);
    const evidence = try collectRealEvidence(init.gpa, init.io, canonical_zig);
    _ = try publishCompletion(init.gpa, init.io, &evidence);
}

fn expectEvidenceError(expected: anyerror, evidence: AcceptanceEvidence) !void {
    try std.testing.expectError(expected, validateEvidence(&evidence));
}

fn syntheticFinalizeAndPublish(
    initial: *const StructuredClosure,
    successive: *const [closure_check_count]StructuredClosure,
    evidence: *const AcceptanceEvidence,
    mapper_final: ArtifactIdentity,
    publish_count: *usize,
) !void {
    _ = try finalizeEvidence(
        initial,
        successive,
        evidence.gates,
        evidence.path_b_receipt,
        evidence.mapper_ordinary,
        evidence.mapper_poisoned,
        mapper_final,
    );
    publish_count.* += 1;
}

test "combined acceptance canonical receipt binds eight sources and numeric gates" {
    const evidence = synthesizeEvidence(0x11);
    var output: [receipt_max_bytes]u8 = undefined;
    const encoded = try encodeReceipt(&output, &evidence);
    try std.testing.expect(std.mem.startsWith(u8, encoded, "schema\tinbox206cn-combined-acceptance-v1\nsource_count\t8\n"));
    try std.testing.expect(std.mem.endsWith(u8, encoded, "mapper_ordinary_poisoned_equal\t1\ncompletion\tcomplete\n"));
    try std.testing.expect(std.mem.indexOf(u8, encoded, "zig_version\t0.16.0\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, encoded, "zig_executable_path") == null);
    try std.testing.expectEqual(@as(usize, source_count), std.mem.count(u8, encoded, "_staged_worktree_equal\t1\n"));
    try std.testing.expectEqual(@as(usize, gate_count), std.mem.count(u8, encoded, "_status\t0\n"));
    for ([_][]const u8{ "command", "argv", "timestamp", "transcript", "session", "cache_inventory" }) |forbidden| {
        try std.testing.expect(std.mem.indexOf(u8, encoded, forbidden) == null);
    }
}

test "combined acceptance evidence rejects every independently inconsistent result" {
    const baseline = synthesizeEvidence(0x21);
    try validateEvidence(&baseline);
    var changed = baseline;
    changed.sources[2].mode = 0o100755;
    try expectEvidenceError(error.InvalidSourceMode, changed);
    changed = baseline;
    changed.sources[4].length = 0;
    try expectEvidenceError(error.InvalidSourceLength, changed);
    changed = baseline;
    changed.staged_worktree_equal[6] = false;
    try expectEvidenceError(error.SourceBytesMismatch, changed);
    changed = baseline;
    changed.staged_tree.bytes = [_]u8{0} ** 20;
    try expectEvidenceError(error.StagedTreeInvalid, changed);
    changed = baseline;
    changed.external_zig_revision.bytes[0] ^= 1;
    try expectEvidenceError(error.ExternalRevisionMismatch, changed);
    changed = baseline;
    changed.zig_executable.length = 0;
    try expectEvidenceError(error.ZigExecutableInvalid, changed);
    changed = baseline;
    changed.gates.status[@intFromEnum(GateId.mapper_test)] = 1;
    try expectEvidenceError(error.GateFailed, changed);
    changed = baseline;
    changed.mapper_poisoned.raw_sha256.bytes[31] ^= 1;
    try expectEvidenceError(error.MapperResultMismatch, changed);
    changed = baseline;
    changed.mapper_poisoned.length += 1;
    try expectEvidenceError(error.MapperResultMismatch, changed);
}

test "Zig selector is explicit absolute singular and version exact" {
    const alternate = "/opt/synthetic-zig-0.16.0/bin/zig";
    try std.testing.expectEqualStrings(alternate, try validateZigSelector(alternate, null));
    const alternate_bytes = "synthetic alternate Zig executable";
    const alternate_identity = try validateZigMeasurement(
        .file,
        true,
        alternate_bytes.len,
        alternate_bytes,
        "0.16.0\n",
    );
    try std.testing.expectEqual(@as(u64, alternate_bytes.len), alternate_identity.length);
    try std.testing.expectError(error.ZigSelectorInvalid, validateZigSelector(null, null));
    try std.testing.expectError(error.ZigSelectorInvalid, validateZigSelector("zig", null));
    try std.testing.expectError(error.ZigSelectorInvalid, validateZigSelector("relative/zig", null));
    try std.testing.expectError(error.ZigSelectorInvalid, validateZigSelector(alternate, "extra"));
    try requireZigVersionOutput("0.16.0\n");
    try std.testing.expectError(error.ZigVersionMismatch, requireZigVersionOutput("0.15.2\n"));
    try std.testing.expectError(error.ZigVersionMismatch, requireZigVersionOutput("0.16.0-dev\n"));
    try std.testing.expectError(
        error.ZigExecutableNotRegular,
        validateZigMeasurement(.directory, true, alternate_bytes.len, alternate_bytes, "0.16.0\n"),
    );
    try std.testing.expectError(
        error.ZigExecutableNotExecutable,
        validateZigMeasurement(.file, false, alternate_bytes.len, alternate_bytes, "0.16.0\n"),
    );
    try std.testing.expectError(
        error.ZigExecutableInvalid,
        validateZigMeasurement(.file, true, alternate_bytes.len + 1, alternate_bytes, "0.16.0\n"),
    );
}

test "Zig selector canonicalizes an alternate absolute executable location" {
    const io = std.testing.io;
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    var file = try temporary.dir.createFile(io, "zig-alternate", .{
        .read = true,
        .exclusive = true,
    });
    try file.writeStreamingAll(io, "synthetic Zig executable bytes");
    try file.setPermissions(io, .fromMode(0o755));
    file.close(io);

    var root_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const root_length = try temporary.dir.realPath(io, &root_buffer);
    var selector_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const selector = try std.fmt.bufPrint(
        &selector_buffer,
        "{s}/zig-alternate",
        .{root_buffer[0..root_length]},
    );
    var canonical_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const canonical = try canonicalizeZigSelector(io, selector, &canonical_buffer);
    try std.testing.expectEqualStrings(selector, canonical);
}

test "structured closure detects source tree pin and Zig drift before publication" {
    const evidence = synthesizeEvidence(0x29);
    const initial = closureFromEvidence(&evidence);
    var successive = [_]StructuredClosure{initial} ** closure_check_count;
    var publish_count: usize = 0;

    successive[0].sources[0].blob.bytes[0] ^= 1;
    try std.testing.expectError(
        error.ClosureSourceMismatch,
        syntheticFinalizeAndPublish(&initial, &successive, &evidence, evidence.mapper_ordinary, &publish_count),
    );
    try std.testing.expectEqual(@as(usize, 0), publish_count);
    successive = [_]StructuredClosure{initial} ** closure_check_count;

    successive[0].staged_status[1] = .added;
    try std.testing.expectError(
        error.ClosureSourceMismatch,
        syntheticFinalizeAndPublish(&initial, &successive, &evidence, evidence.mapper_ordinary, &publish_count),
    );
    successive = [_]StructuredClosure{initial} ** closure_check_count;

    successive[1].staged_tree.bytes[0] ^= 1;
    try std.testing.expectError(
        error.ClosureTreeMismatch,
        syntheticFinalizeAndPublish(&initial, &successive, &evidence, evidence.mapper_ordinary, &publish_count),
    );
    successive = [_]StructuredClosure{initial} ** closure_check_count;

    successive[2].external_zig_revision.bytes[0] ^= 1;
    try std.testing.expectError(
        error.ClosureExternalRevisionMismatch,
        syntheticFinalizeAndPublish(&initial, &successive, &evidence, evidence.mapper_ordinary, &publish_count),
    );
    successive = [_]StructuredClosure{initial} ** closure_check_count;

    successive[2].external_zig_clean = false;
    try std.testing.expectError(
        error.ClosureExternalRevisionMismatch,
        syntheticFinalizeAndPublish(&initial, &successive, &evidence, evidence.mapper_ordinary, &publish_count),
    );
    successive = [_]StructuredClosure{initial} ** closure_check_count;

    successive[3].zig_executable.raw_sha256.bytes[0] ^= 1;
    try std.testing.expectError(
        error.ClosureZigExecutableMismatch,
        syntheticFinalizeAndPublish(&initial, &successive, &evidence, evidence.mapper_ordinary, &publish_count),
    );
    try std.testing.expectEqual(@as(usize, 0), publish_count);
}

test "final artifact mismatch publishes nothing and stable closure admits once" {
    const evidence = synthesizeEvidence(0x2a);
    const initial = closureFromEvidence(&evidence);
    const successive = [_]StructuredClosure{initial} ** closure_check_count;
    var publish_count: usize = 0;
    var mismatched = evidence.mapper_ordinary;
    mismatched.raw_sha256.bytes[0] ^= 1;
    try std.testing.expectError(
        error.MapperResultMismatch,
        syntheticFinalizeAndPublish(&initial, &successive, &evidence, mismatched, &publish_count),
    );
    try std.testing.expectEqual(@as(usize, 0), publish_count);
    try syntheticFinalizeAndPublish(&initial, &successive, &evidence, evidence.mapper_ordinary, &publish_count);
    try std.testing.expectEqual(@as(usize, 1), publish_count);
}

test "staged listing admits exactly the ordered eight-path set" {
    const evidence = synthesizeEvidence(0x31);
    var bytes: [8192]u8 = undefined;
    const listing = try makeStatusListing(&bytes, &evidence);
    const parsed = try parseStagedListing(listing);
    for (parsed, evidence.sources, 0..) |change, source, index| {
        try std.testing.expectEqual(index, change.path_index);
        try std.testing.expect(equalIdentity20(change.blob, source.blob));
    }

    const final_path_offset = std.mem.lastIndexOf(u8, listing, source_paths[7]) orelse unreachable;
    const final_record_separator = std.mem.lastIndexOfScalar(u8, listing[0..final_path_offset], 0) orelse unreachable;
    try std.testing.expectError(error.MissingStagedPath, parseStagedListing(listing[0 .. final_record_separator + 1]));
    try std.testing.expectError(error.EmptyStagedSet, parseStagedListing(""));
}

test "staged listing rejects duplicate, extra, malformed, and reordered records" {
    const evidence = synthesizeEvidence(0x41);
    var bytes: [8192]u8 = undefined;
    const listing = try makeStatusListing(&bytes, &evidence);
    var changed: [8192]u8 = undefined;
    const first_end = (std.mem.indexOfScalar(u8, listing, 0) orelse unreachable) + 1;
    const second_relative_end = std.mem.indexOfScalar(u8, listing[first_end..], 0) orelse unreachable;
    const second_end = first_end + second_relative_end + 1;
    @memcpy(changed[0..first_end], listing[0..first_end]);
    @memcpy(changed[first_end .. first_end * 2], listing[0..first_end]);
    @memcpy(changed[first_end * 2 .. first_end * 2 + listing.len - second_end], listing[second_end..]);
    const duplicate_length = first_end * 2 + listing.len - second_end;
    try std.testing.expectError(error.DuplicateStagedPath, parseStagedListing(changed[0..duplicate_length]));

    @memcpy(changed[0..listing.len], listing);
    const path_position = std.mem.indexOf(u8, changed[0..listing.len], source_paths[0]) orelse unreachable;
    changed[path_position] = 'x';
    try std.testing.expectError(error.ExtraStagedPath, parseStagedListing(changed[0..listing.len]));

    @memcpy(changed[0..listing.len], listing);
    const first_mode = std.mem.indexOf(u8, changed[0..listing.len], "100644 100644") orelse unreachable;
    changed[first_mode] = '0';
    try std.testing.expectError(error.InvalidSourceMode, parseStagedListing(changed[0..listing.len]));

    @memcpy(changed[0..listing.len], listing);
    changed[2] = 'R';
    try std.testing.expectError(error.StagedStatusMismatch, parseStagedListing(changed[0..listing.len]));

    try std.testing.expectError(error.GitOutputMalformed, parseStagedListing(listing[0 .. listing.len - 1]));
}

test "fixed gate failure diagnostic framing is deterministic and binary safe" {
    var stdout_bytes = [_]u8{ 0, 0xff, '\n', '\t' };
    var stderr_bytes = [_]u8{ 0x80, 0, '\r' };
    const result = OwnedProcessResult{
        .stdout = &stdout_bytes,
        .stderr = &stderr_bytes,
        .status = 37,
    };

    var first_storage: [128]u8 = undefined;
    var first: std.Io.Writer = .fixed(&first_storage);
    try encodeGateFailureDiagnostic(&first, .mapper_ordinary, &result);
    const encoded = first.buffered();

    var second_storage: [128]u8 = undefined;
    var second: std.Io.Writer = .fixed(&second_storage);
    try encodeGateFailureDiagnostic(&second, .mapper_ordinary, &result);
    try std.testing.expectEqualSlices(u8, encoded, second.buffered());

    try std.testing.expectEqualSlices(u8, gate_diagnostic_magic, encoded[0..gate_diagnostic_magic.len]);
    try std.testing.expectEqual(@as(u8, @intFromEnum(GateId.mapper_ordinary)), encoded[8]);
    try std.testing.expectEqual(@as(u8, @intFromEnum(GateTermination.exited)), encoded[9]);
    try std.testing.expectEqual(@as(u8, 37), encoded[10]);
    try std.testing.expectEqual(@as(u8, 0), encoded[11]);
    try std.testing.expectEqual(@as(u64, stdout_bytes.len), std.mem.readInt(u64, encoded[12..20], .little));
    try std.testing.expectEqual(@as(u64, stderr_bytes.len), std.mem.readInt(u64, encoded[20..28], .little));
    try std.testing.expectEqualSlices(u8, &stdout_bytes, encoded[gate_diagnostic_header_size..][0..stdout_bytes.len]);
    try std.testing.expectEqualSlices(u8, &stderr_bytes, encoded[gate_diagnostic_header_size + stdout_bytes.len ..]);
}

test "fixed gate failure diagnostic accepts exact capture bounds" {
    const allocator = std.testing.allocator;
    const stdout_storage = try allocator.alloc(u8, process_stdout_max + 1);
    defer allocator.free(stdout_storage);
    const stderr_storage = try allocator.alloc(u8, process_stderr_max);
    defer allocator.free(stderr_storage);
    @memset(stdout_storage, 0xa5);
    @memset(stderr_storage, 0x5a);

    var result = OwnedProcessResult{
        .stdout = stdout_storage[0..process_stdout_max],
        .stderr = stderr_storage,
        .status = 1,
    };
    var discard_buffer: [4096]u8 = undefined;
    var discarding: std.Io.Writer.Discarding = .init(&discard_buffer);
    try std.testing.expectError(
        error.GateFailed,
        requireGateSuccess(&discarding.writer, .mapper_poisoned, &result),
    );
    try std.testing.expectEqual(
        @as(u64, gate_diagnostic_header_size + process_stdout_max + process_stderr_max),
        discarding.fullCount(),
    );

    result.stdout = stdout_storage;
    var rejected: std.Io.Writer.Discarding = .init(&discard_buffer);
    try std.testing.expectError(
        error.DiagnosticCaptureBoundExceeded,
        encodeGateFailureDiagnostic(&rejected.writer, .mapper_poisoned, &result),
    );
    try std.testing.expectEqual(@as(u64, 0), rejected.fullCount());
}

test "fixed gate diagnostic emits only on failure and preserves publication semantics" {
    var stdout_bytes = [_]u8{ 'o', 'u', 't' };
    var stderr_bytes = [_]u8{ 'e', 'r', 'r' };
    var result = OwnedProcessResult{
        .stdout = &stdout_bytes,
        .stderr = &stderr_bytes,
        .status = 0,
    };
    var diagnostic_storage: [128]u8 = undefined;
    var diagnostic: std.Io.Writer = .fixed(&diagnostic_storage);
    try requireGateSuccess(&diagnostic, .format_check, &result);
    try std.testing.expectEqual(@as(usize, 0), diagnostic.buffered().len);

    const evidence = synthesizeEvidence(0x4f);
    const initial = closureFromEvidence(&evidence);
    const successive = [_]StructuredClosure{initial} ** closure_check_count;
    var publish_count: usize = 0;
    try syntheticFinalizeAndPublish(
        &initial,
        &successive,
        &evidence,
        evidence.mapper_ordinary,
        &publish_count,
    );
    try std.testing.expectEqual(@as(usize, 1), publish_count);
    try std.testing.expectEqual(@as(usize, 0), diagnostic.buffered().len);

    result.status = 9;
    try std.testing.expectError(
        error.GateFailed,
        requireGateSuccess(&diagnostic, .format_check, &result),
    );
    try std.testing.expect(diagnostic.buffered().len != 0);

    var no_storage: [0]u8 = .{};
    var failing_writer: std.Io.Writer = .fixed(&no_storage);
    try std.testing.expectError(
        error.GateFailed,
        requireGateSuccess(&failing_writer, .format_check, &result),
    );
}

test "fixed process specifications are closed bounded and path independent" {
    const synthetic_zig = "/synthetic/zig-0.16.0";
    const format_argv = zigFormatArgv(synthetic_zig);
    const path_b_argv = zigPathBTestArgv(synthetic_zig);
    const mapper_test_argv = zigMapperTestArgv(synthetic_zig);
    const mapper_derive_argv = zigMapperDeriveArgv(synthetic_zig);
    const specs = [_]FixedProcess{
        fixedProcess(.git, &git_object_format_argv, repository_root),
        fixedProcess(.git, &git_staged_listing_argv, repository_root),
        fixedProcess(.git, &git_staged_tree_argv, repository_root),
        fixedProcess(.git, &git_external_revision_argv, repository_root),
        fixedProcess(.git, &git_external_status_argv, repository_root),
        fixedProcess(.zig, &format_argv, repository_root),
        fixedProcess(.zig, &path_b_argv, repository_root),
        fixedProcess(.zig, &mapper_test_argv, repository_root),
        fixedProcess(.zig, &mapper_derive_argv, repository_root),
        fixedProcess(.zig_poisoned_mapper, &mapper_derive_argv, repository_root),
    };
    for (specs) |spec| {
        try std.testing.expect(std.fs.path.isAbsolute(spec.argv[0]));
        try std.testing.expect(std.fs.path.isAbsolute(spec.cwd));
        try std.testing.expect(spec.stdout_limit != 0 and spec.stderr_limit != 0);
        for (spec.argv) |arg| try std.testing.expect(std.mem.indexOfScalar(u8, arg, 0) == null);
    }
    try std.testing.expectEqual(@as(usize, git_environment.len), 13);
    try std.testing.expectEqual(@as(usize, zig_environment.len), 7);
    try std.testing.expectEqualStrings(synthetic_zig, format_argv[0]);
}

test "poisoned mapper environment is the complete accepted anti-drift vector" {
    const expected = [_][]const u8{
        "LC_ALL=tr_TR.UTF-8",
        "LANG=tr_TR.UTF-8",
        "TZ=Pacific/Kiritimati",
        "HOME=/nonexistent",
        "XDG_CONFIG_HOME=/nonexistent",
        "ZIG_LOCAL_CACHE_DIR=" ++ local_cache_directory,
        "ZIG_GLOBAL_CACHE_DIR=" ++ global_cache_directory,
        "GIT_CONFIG_NOSYSTEM=0",
        "GIT_CONFIG_SYSTEM=/__zllvm_inbox206cn_poison_system_config__",
        "GIT_CONFIG_GLOBAL=/__zllvm_inbox206cn_poison_global_config__",
        "GIT_OPTIONAL_LOCKS=1",
        "GIT_DIR=/__zllvm_inbox206cn_poison_git_dir__",
        "GIT_WORK_TREE=/__zllvm_inbox206cn_poison_work_tree__",
        "GIT_INDEX_FILE=/__zllvm_inbox206cn_poison_index__",
        "GIT_COMMON_DIR=/__zllvm_inbox206cn_poison_common__",
        "GIT_OBJECT_DIRECTORY=/__zllvm_inbox206cn_poison_objects__",
        "GIT_ALTERNATE_OBJECT_DIRECTORIES=/__zllvm_inbox206cn_poison_alternates__",
    };
    try std.testing.expectEqual(expected.len, zig_poisoned_mapper_environment.len);
    for (expected, zig_poisoned_mapper_environment) |wanted, actual| {
        try std.testing.expectEqualStrings(wanted, actual);
    }
}

test "source binding derives blob digest length and staged-worktree equality" {
    const evidence = synthesizeEvidence(0x51);
    var changes: [source_count]StagedChange = undefined;
    var staged_storage: [source_count][16]u8 = undefined;
    var worktree_storage: [source_count][16]u8 = undefined;
    var staged: [source_count][]const u8 = undefined;
    var worktree: [source_count][]const u8 = undefined;
    for (0..source_count) |index| {
        staged_storage[index] = [_]u8{0x51} ** 16;
        staged_storage[index][0] +%= @intCast(index);
        worktree_storage[index] = staged_storage[index];
        staged[index] = &staged_storage[index];
        worktree[index] = &worktree_storage[index];
        changes[index] = .{
            .path_index = index,
            .blob = evidence.sources[index].blob,
            .status = .modified,
        };
    }
    const bound = try bindSourceSet(&changes, &staged, &worktree);
    try std.testing.expect(std.meta.eql(bound, evidence.sources));

    worktree_storage[3][5] ^= 1;
    try std.testing.expectError(error.SourceBytesMismatch, bindSourceSet(&changes, &staged, &worktree));
    worktree_storage[3][5] ^= 1;
    changes[5].blob.bytes[0] ^= 1;
    try std.testing.expectError(error.SourceBlobMismatch, bindSourceSet(&changes, &staged, &worktree));
}

test "completion publication is atomic exact read-back and no-replace" {
    const io = std.testing.io;
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    var non_iterable_directory = try temporary.dir.openDir(io, ".", .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer non_iterable_directory.close(io);
    const evidence = synthesizeEvidence(0x61);
    var expected_buffer: [receipt_max_bytes]u8 = undefined;
    const expected = try encodeReceipt(&expected_buffer, &evidence);
    const published = try publishCompletionInDirectory(
        std.testing.allocator,
        io,
        non_iterable_directory,
        &evidence,
    );
    try std.testing.expectEqual(@as(u64, @intCast(expected.len)), published.length);
    try std.testing.expect(equalIdentity32(rawIdentity(expected), published.raw_sha256));
    const read_back = try temporary.dir.readFileAlloc(
        io,
        completion_receipt_name,
        std.testing.allocator,
        .limited(receipt_max_bytes),
    );
    defer std.testing.allocator.free(read_back);
    try std.testing.expectEqualSlices(u8, expected, read_back);
    try std.testing.expectError(
        error.CompletionCollision,
        publishCompletionInDirectory(std.testing.allocator, io, non_iterable_directory, &evidence),
    );
}

test "literal validation traversal is absolute and caller cwd independent" {
    const io = std.testing.io;
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    try temporary.dir.createDirPath(io, "local-state/validations/inbox206cn");
    var root_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const root_length = try temporary.dir.realPath(io, &root_buffer);
    const absolute_root = root_buffer[0..root_length];
    var validation = try openLiteralValidationDirectoryAt(io, absolute_root);
    validation.close(io);
    try std.testing.expectError(error.ZigSelectorInvalid, openLiteralValidationDirectoryAt(io, "."));
}

test "literal validation traversal rejects symlinked components" {
    const io = std.testing.io;
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    try temporary.dir.createDirPath(io, "actual/validations/inbox206cn");
    try temporary.dir.symLink(io, "actual", "local-state", .{ .is_directory = true });
    var root_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const root_length = try temporary.dir.realPath(io, &root_buffer);
    const absolute_root = root_buffer[0..root_length];
    if (openLiteralValidationDirectoryAt(io, absolute_root)) |directory| {
        directory.close(io);
        return error.TestUnexpectedResult;
    } else |failure| switch (failure) {
        error.SymLinkLoop, error.NotDir => {},
        else => return failure,
    }
}
