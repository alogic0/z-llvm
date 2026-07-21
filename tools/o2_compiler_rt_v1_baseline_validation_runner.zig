const std = @import("std");
const builtin = @import("builtin");
const contract = @import("o2_compiler_rt_v1_baseline_validation.zig");
const authoritative_statfs = @cImport({
    @cInclude("sys/statfs.h");
});

const schema = "o2-compiler-rt-v1-baseline-closure-v2";
const source_acceptance_schema = "o2-compiler-rt-v1-cy-source-acceptance-v1";
const contract_source_relative = "tools/o2_compiler_rt_v1_baseline_validation.zig";
const runner_source_relative = "tools/o2_compiler_rt_v1_baseline_validation_runner.zig";
const source_acceptance_directory_relative = "local-state/validations/inbox206cy";
const source_acceptance_name = "cy_source_acceptance_v1.tsv";
const source_acceptance_temporary_name = ".cy_source_acceptance_v1.tsv.tmp";
const expected_zig_version = "0.16.0";
const process_capture_max: usize = 4 * 1024 * 1024;
const closure_max: usize = 64 * 1024;
const closure_name = "baseline-validation-closure-v1.tsv";
const closure_temporary_name = ".baseline-validation-closure-v1.tsv.tmp";
const input_limit = "67108864";
const target = "x86_64-linux";
const maximum_input_bytes: u64 = 64 * 1024 * 1024;
const maximum_artifact_bytes: u64 = 1024 * 1024 * 1024;
const maximum_parsed_tool_output: usize = 64 * 1024 * 1024;
const accepted_registered_worktree_count: usize = 43;

const RunnerError = error{
    InvalidArguments,
    RelativePath,
    NonCanonicalPath,
    PathEscape,
    PathAlias,
    SymlinkRejected,
    WrongPathKind,
    RegisteredWorktreeRejected,
    WrongExecutable,
    WrongArguments,
    WrongEnvironment,
    WrongWorkingDirectory,
    SpawnFailed,
    ChildFailed,
    ChildOutputOverflow,
    IncompleteCapture,
    InconsistentResult,
    MalformedCounterChannel,
    FileCapExceeded,
    RootCapExceeded,
    FamilyCapExceeded,
    AggregateCapExceeded,
    StorageOverflow,
    FamilyOutOfOrder,
    FamilyDuplicate,
    FamilyUnknown,
    FamilyMissing,
    AggregateExclusionDrift,
    RestorationMismatch,
    ClosurePrecondition,
    ClosureCollision,
    ClosureReadBackMismatch,
    ClosureTooLarge,
    ZigVersionMismatch,
    CapacitySyscallFailed,
    CapacityFieldsInvalid,
    CapacityOverflow,
    CapacityRootMismatch,
    SubjectIdentityMismatch,
    SubjectAuthorityMismatch,
    WorktreeMetadataMalformed,
    WorktreeSetMismatch,
    ParentIdentityMismatch,
    IndexMetadataMalformed,
    IndexSetMismatch,
    StagedSourceMismatch,
    GateOrderMismatch,
    GateResultMismatch,
    SourceAcceptanceCollision,
    SourceAcceptanceReadBackMismatch,
    InputIdentityMismatch,
    GitObservationMismatch,
    ValidationRootCollision,
    MissingPhase,
    ResultDrift,
    ParseFailure,
    FunctionCountMismatch,
    OwnerMismatch,
    ManifestMismatch,
    UnsupportedPlatform,
};

const NativeStatfs = extern struct {
    f_type: c_long,
    f_bsize: c_long,
    f_blocks: c_ulong,
    f_bfree: c_ulong,
    f_bavail: c_ulong,
    f_files: c_ulong,
    f_ffree: c_ulong,
    f_fsid: extern struct { values: [2]c_int },
    f_namelen: c_long,
    f_frsize: c_long,
    f_flags: c_long,
    f_spare: [4]c_long,
};

const CapacityFields = struct {
    block_size: i128,
    fragment_size: i128,
    blocks: i128,
    free_blocks: i128,
    available_blocks: i128,
};

const CapacityRootIdentity = struct {
    inode: std.Io.File.INode,
    mode: u32,
    kind: std.Io.File.Kind,
    filesystem_id: [2]c_int,
};

const FileIdentity = struct {
    bytes: u64,
    mode: u32,
    inode: std.Io.File.INode,
    sha256: contract.Digest,
};

const ToolRole = enum {
    zig,
    git,
    llvm_extract,
    objcopy,
    objdump,
    readelf,
};

fn toolRoleName(role: ToolRole) []const u8 {
    return @tagName(role);
}

const ToolSelector = struct {
    role: ToolRole,
    path: []const u8,
    authorized_bytes: u64,
    authorized_sha256: contract.Digest,
    authorized_version: ?[]const u8,
};

const PortableToolIdentity = struct {
    role: ToolRole,
    bytes: u64,
    sha256: contract.Digest,
    version: ?[]const u8,
};

const GitBlobId = [20]u8;

const SourceAcceptanceCli = struct {
    zig: ToolSelector,
    git: ToolSelector,
    repository: []const u8,
    expected_parent: [40]u8,
    contract_source: []const u8,
    runner_source: []const u8,
    output_path: []const u8,
};

const StagedSourceIdentity = struct {
    mode: u32,
    bytes: u64,
    blob: GitBlobId,
    raw_sha256: contract.Digest,
    worktree_inode: std.Io.File.INode,
};

const SourceAcceptanceSnapshot = struct {
    parent: [40]u8,
    contract_source: StagedSourceIdentity,
    runner_source: StagedSourceIdentity,
};

const SourceAcceptanceToolSet = struct {
    zig: AuthenticatedSubject,
    git: AuthenticatedSubject,
};

const SourceAcceptanceGate = enum(u8) {
    format_check = 1,
    no_libc_compile = 2,
    focused_contract = 3,
    focused_runner = 4,
    full_contract = 5,
    full_runner = 6,
};

const SourceAcceptanceGateResult = struct {
    gate: SourceAcceptanceGate,
    exit_status: u8,
    stdout_bytes: u64,
    stdout_sha256: contract.Digest,
    stderr_bytes: u64,
    stderr_sha256: contract.Digest,
};

const SourceAcceptanceEvidence = struct {
    snapshot: SourceAcceptanceSnapshot,
    tools: SourceAcceptanceToolSet,
    gates: [@typeInfo(SourceAcceptanceGate).@"enum".fields.len]SourceAcceptanceGateResult,
    completion: bool,
};

const AuthenticatedSubject = struct {
    path: []const u8,
    identity: FileIdentity,
    portable_tool: ?PortableToolIdentity = null,
};

const SubjectSet = struct {
    zig: AuthenticatedSubject,
    git: AuthenticatedSubject,
    llvm_extract: AuthenticatedSubject,
    objcopy: AuthenticatedSubject,
    objdump: AuthenticatedSubject,
    readelf: AuthenticatedSubject,
};

const InputSet = struct {
    raw: FileIdentity,
    adoption: FileIdentity,
    bundle_manifest: FileIdentity,
    combined_patch: FileIdentity,
    reproduction: FileIdentity,
    retention_pins: FileIdentity,
    retention_policy: FileIdentity,
    cleanup_source: FileIdentity,
    bypass_inventory: FileIdentity,
    facade_manifest: FileIdentity,
    facade_source: FileIdentity,
    external_stage4: FileIdentity,
};

const Cli = struct {
    zig: ToolSelector,
    git: ToolSelector,
    llvm_extract: ToolSelector,
    objcopy: ToolSelector,
    objdump: ToolSelector,
    readelf: ToolSelector,
    repository: []const u8,
    external_zig_repository: []const u8,
    canonical_source: []const u8,
    coverage_source: []const u8,
    raw_input: []const u8,
    adoption_manifest: []const u8,
    bundle_root: []const u8,
    reproduction_manifest: []const u8,
    retention_pins: []const u8,
    retention_policy: []const u8,
    cleanup_source: []const u8,
    bypass_inventory: []const u8,
    facade_manifest: []const u8,
    facade_source: []const u8,
    external_stage4: []const u8,
    validation_root: []const u8,
    registered_worktrees: []const []const u8,
};

const ExpectedFile = struct {
    bytes: u64,
    sha256_hex: []const u8,
    executable: bool = false,
};

const RuntimeEvidence = struct {
    phases: contract.PhaseMachine,
    family_usage: [contract.storage_families.len]FamilyUsage,
    repetitions: [contract.canonical_repetition_count]contract.CanonicalRepetition,
    coverage: contract.CoverageState,
    restoration: contract.RestorationState,
    semantic_equality: contract.SemanticEquality,
    before: RestorationIdentity,
    after: RestorationIdentity,
    available_bytes: u64,
};

const RepositoryObservation = struct {
    head: [40]u8,
    tree: [40]u8,
    status: contract.Digest,
    clean: bool,
};

const RegisteredWorktreeSetIdentity = struct {
    count: u8,
    sha256: contract.Digest,
};

const FunctionRow = struct {
    name: []const u8,
    value: u64,
    size: u64,
};

const PhaseIdentity = struct {
    report_stdout: contract.Digest,
    report_stderr: contract.Digest,
    object: contract.Digest,
    owner: contract.Digest,
    objdump: contract.Digest,
    sections: contract.Digest,
    symbols: contract.Digest,
    text: contract.Digest,
    functions: contract.Digest,
    function_count: u16,
};

const PathKind = enum { file, directory };

const PathFact = struct {
    label: []const u8,
    supplied: []const u8,
    canonical: []const u8,
    kind: PathKind,
    expected_kind: PathKind,
    is_symlink: bool,
    identity: u128,
};

const EnvironmentEntry = struct { name: []const u8, value: []const u8 };

const ProcessRequest = struct {
    executable: []const u8,
    argv: []const []const u8,
    environment: []const EnvironmentEntry,
    cwd: []const u8,
};

const FixedCommand = struct {
    executable: []const u8,
    argv: []const []const u8,
    environment: []const EnvironmentEntry,
    cwd: []const u8,
};

const Termination = union(enum) {
    exited: u8,
    signal: u32,
    stopped: u32,
    unknown: u32,
};

const CapturedResult = struct {
    termination: Termination,
    stdout: []const u8,
    stderr: []const u8,
    stdout_complete: bool,
    stderr_complete: bool,
};

const FamilyUsage = struct {
    family_id: u8,
    retained_bytes: u64,
    largest_file_bytes: u64,
    root_bytes: u64,
    aggregate_exclusions: u32,
};

const FamilyTracker = struct {
    next: usize = 0,
    total_retained_bytes: u64 = 0,
    rows: [contract.storage_families.len]contract.EnforcedStorageFamily = undefined,

    fn close(self: *FamilyTracker, usage: FamilyUsage) RunnerError!void {
        if (usage.family_id == 0 or usage.family_id > contract.storage_families.len)
            return error.FamilyUnknown;
        const index: usize = @intCast(usage.family_id - 1);
        if (index < self.next) return error.FamilyDuplicate;
        if (index != self.next) return error.FamilyOutOfOrder;

        const policies = contract.acceptedEnforcedStorageFamilies() catch
            return error.AggregateExclusionDrift;
        const policy = policies[index];
        if (usage.aggregate_exclusions != policy.aggregate_exclusions)
            return error.AggregateExclusionDrift;
        if (usage.largest_file_bytes > policy.maximum_bytes)
            return error.FileCapExceeded;
        if (usage.root_bytes > policy.maximum_bytes)
            return error.RootCapExceeded;
        if (usage.retained_bytes > policy.maximum_bytes)
            return error.FamilyCapExceeded;
        self.total_retained_bytes = std.math.add(
            u64,
            self.total_retained_bytes,
            usage.retained_bytes,
        ) catch return error.StorageOverflow;
        if (self.total_retained_bytes > contract.accepted_maximum_storage_bytes)
            return error.AggregateCapExceeded;
        self.rows[index] = policy;
        self.next += 1;
    }

    fn finish(self: *const FamilyTracker) RunnerError!void {
        if (self.next != contract.storage_families.len) return error.FamilyMissing;
        if (self.total_retained_bytes > contract.accepted_maximum_storage_bytes)
            return error.AggregateCapExceeded;
    }
};

fn initializeFamilyUsage() [contract.storage_families.len]FamilyUsage {
    var usage: [contract.storage_families.len]FamilyUsage = undefined;
    for (&usage, contract.accepted_storage_policy, 0..) |*row, policy, index| {
        row.* = .{
            .family_id = @intCast(index + 1),
            .retained_bytes = 0,
            .largest_file_bytes = 0,
            .root_bytes = 0,
            .aggregate_exclusions = policy.aggregate_exclusions,
        };
    }
    return usage;
}

fn accountFamilyBytes(
    usage: *[contract.storage_families.len]FamilyUsage,
    family: contract.StorageFamily,
    bytes: u64,
) RunnerError!void {
    const index: usize = @intCast(@intFromEnum(family) - 1);
    const policy = (contract.acceptedEnforcedStorageFamilies() catch
        return error.AggregateExclusionDrift)[index];
    if (bytes > policy.maximum_bytes) return error.FileCapExceeded;
    const total = std.math.add(u64, usage[index].retained_bytes, bytes) catch
        return error.StorageOverflow;
    if (total > policy.maximum_bytes) return error.FamilyCapExceeded;
    usage[index].retained_bytes = total;
    usage[index].root_bytes = total;
    usage[index].largest_file_bytes = @max(usage[index].largest_file_bytes, bytes);
}

const RestorationIdentity = struct {
    repository: contract.Digest,
    canonical_source: contract.Digest,
    coverage_source: contract.Digest,
    accepted_input: contract.Digest,
};

const CompleteRunObservation = struct {
    identities: []const contract.IdentityDescriptor,
    compatibility_keys: []const []const u8,
    repetitions: []const contract.CanonicalRepetition,
    coverage: contract.CoverageState,
    restoration: contract.RestorationState,
    semantic_equality: contract.SemanticEquality,
    phases: contract.PhaseMachine,
    family_usage: []const FamilyUsage,
    available_bytes: u64,
    before: RestorationIdentity,
    after: RestorationIdentity,
};

const SourceIdentityBinding = struct {
    repository: RepositoryObservation,
    external_zig: RepositoryObservation,
    canonical: RepositoryObservation,
    coverage: RepositoryObservation,
    canonical_manifest: contract.Digest,
    coverage_manifest: contract.Digest,
};

const ClosureBinding = struct {
    tools: SubjectSet,
    fixed_sources: contract.Digest,
    fixed_inputs: contract.Digest,
    canonical_artifact: FileIdentity,
    coverage_artifact: FileIdentity,
    canonical_observations: contract.Digest,
    coverage_off_observation: contract.Digest,
    coverage_on_observation: contract.Digest,
    counter_result: contract.Digest,
    registered_worktrees: RegisteredWorktreeSetIdentity,
    family_usage: contract.Digest,
    completion: bool,
};

const ValidatedRun = struct {
    retained_bytes: u64,
    before: RestorationIdentity,
    after: RestorationIdentity,
    available_bytes: u64,
};

const PublishedClosure = struct {
    bytes: u64,
    sha256: contract.Digest,
};

const ParsedCoverageChannel = struct {
    families: contract.FamilyPair,
    unexpected_family_events: u64,
    argument_index_overflow_events: u64,
};

const ManifestLine = struct { digest: contract.Digest, path: []const u8 };

fn parseManifestLine(line: []const u8) RunnerError!ManifestLine {
    if (line.len < 67) return error.ManifestMismatch;
    const digest = try decodeSha256(line[0..64]);
    if (line[64] != ' ' or (line[65] != ' ' and line[65] != '*'))
        return error.ManifestMismatch;
    const path = line[66..];
    if (path.len == 0 or std.fs.path.isAbsolute(path) or
        std.mem.indexOfScalar(u8, path, 0) != null)
    {
        return error.ManifestMismatch;
    }
    var components = std.mem.splitScalar(u8, path, '/');
    while (components.next()) |component| {
        if (component.len == 0 or std.mem.eql(u8, component, ".") or
            std.mem.eql(u8, component, "..")) return error.ManifestMismatch;
    }
    return .{ .digest = digest, .path = path };
}

fn readAuthenticatedBundleMember(
    allocator: std.mem.Allocator,
    io: std.Io,
    bundle_root: []const u8,
    bundle_manifest: []const u8,
    required_path: []const u8,
    registered_worktrees: []const []const u8,
) ![]u8 {
    var found: ?contract.Digest = null;
    var previous: ?[]const u8 = null;
    var lines = std.mem.splitScalar(u8, bundle_manifest, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const entry = try parseManifestLine(line);
        if (previous) |prior| if (std.mem.order(u8, prior, entry.path) != .lt)
            return error.ManifestMismatch;
        previous = entry.path;
        if (std.mem.eql(u8, entry.path, required_path)) {
            if (found != null) return error.ManifestMismatch;
            found = entry.digest;
        }
    }
    const expected = found orelse return error.ManifestMismatch;
    const absolute = try joinAbsolute(allocator, bundle_root, required_path);
    const identity = try observeFile(io, absolute, false, maximum_input_bytes, registered_worktrees);
    if (!std.mem.eql(u8, &identity.sha256, &expected)) return error.ManifestMismatch;
    return readBoundedAbsolute(allocator, io, absolute, maximum_input_bytes);
}

fn verifySourceManifest(
    allocator: std.mem.Allocator,
    io: std.Io,
    source_root: []const u8,
    manifest: []const u8,
    registered_worktrees: []const []const u8,
) !contract.Digest {
    var previous: ?[]const u8 = null;
    var count: usize = 0;
    var total: u64 = 0;
    var lines = std.mem.splitScalar(u8, manifest, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const entry = try parseManifestLine(line);
        if (previous) |prior| if (std.mem.order(u8, prior, entry.path) != .lt)
            return error.ManifestMismatch;
        previous = entry.path;
        const absolute = try joinAbsolute(allocator, source_root, entry.path);
        defer allocator.free(absolute);
        const identity = try observeFile(io, absolute, false, maximum_artifact_bytes, registered_worktrees);
        if (!std.mem.eql(u8, &identity.sha256, &entry.digest)) return error.ManifestMismatch;
        total = std.math.add(u64, total, identity.bytes) catch return error.StorageOverflow;
        if (total > maximum_artifact_bytes) return error.RootCapExceeded;
        count += 1;
        if (count > 1_000_000) return error.RootCapExceeded;
    }
    if (count == 0) return error.ManifestMismatch;
    return sha256(manifest);
}

fn verifyCompatibilityBundleMembers(
    allocator: std.mem.Allocator,
    io: std.Io,
    bundle_root: []const u8,
    bundle_manifest: []const u8,
    registered_worktrees: []const []const u8,
) !void {
    inline for (.{
        "manifests/baseline-source.sha256",
        "manifests/bundled-source.sha256",
        "manifests/combined-apply-source.sha256",
        "manifests/future-tool-identities.sha256",
        "manifests/patch-manifest.tsv",
        "manifests/payload-final-modes.tsv",
        "manifests/preflight-and-apply-proof.txt",
        "manifests/restored-source.sha256",
        "manifests/sequential-apply-source.sha256",
        "manifests/touched-paths.txt",
        "patches/01-aggregate-consumer.patch",
        "patches/02-fixed-observer.patch",
        "patches/03-exact-combined-guard.patch",
        "patches/aggregate-consumer-observer-guard.patch",
    }) |relative| {
        const bytes = try readAuthenticatedBundleMember(
            allocator,
            io,
            bundle_root,
            bundle_manifest,
            relative,
            registered_worktrees,
        );
        allocator.free(bytes);
    }
}

fn validateCanonicalAbsolute(path: []const u8) RunnerError!void {
    if (!std.fs.path.isAbsolute(path)) return error.RelativePath;
    if (path.len == 0 or std.mem.indexOfScalar(u8, path, 0) != null)
        return error.NonCanonicalPath;
    if (path.len > 1 and path[path.len - 1] == '/') return error.NonCanonicalPath;
    var components = std.mem.splitScalar(u8, path[1..], '/');
    while (components.next()) |component| {
        if (component.len == 0 or std.mem.eql(u8, component, ".") or
            std.mem.eql(u8, component, "..")) return error.NonCanonicalPath;
    }
}

fn isPathWithin(path: []const u8, prefix: []const u8) bool {
    if (std.mem.eql(u8, path, prefix)) return true;
    return path.len > prefix.len and std.mem.startsWith(u8, path, prefix) and
        path[prefix.len] == '/';
}

fn validatePathFacts(
    facts: []const PathFact,
    registered_worktree_prefixes: []const []const u8,
) RunnerError!void {
    for (registered_worktree_prefixes) |prefix| try validateCanonicalAbsolute(prefix);
    for (facts, 0..) |fact, index| {
        try validateCanonicalAbsolute(fact.supplied);
        try validateCanonicalAbsolute(fact.canonical);
        if (!std.mem.eql(u8, fact.supplied, fact.canonical)) return error.NonCanonicalPath;
        if (fact.is_symlink) return error.SymlinkRejected;
        if (fact.kind != fact.expected_kind) return error.WrongPathKind;
        for (registered_worktree_prefixes) |prefix| {
            if (isPathWithin(fact.canonical, prefix)) return error.RegisteredWorktreeRejected;
        }
        for (facts[0..index]) |prior| {
            if (std.mem.eql(u8, prior.canonical, fact.canonical) or
                prior.identity == fact.identity) return error.PathAlias;
        }
    }
}

fn validateRegisteredWorktreePrefixes(prefixes: []const []const u8) RunnerError!void {
    if (prefixes.len != accepted_registered_worktree_count) return error.InvalidArguments;
    for (prefixes, 0..) |prefix, index| {
        try validateCanonicalAbsolute(prefix);
        for (prefixes[0..index]) |prior| {
            if (std.mem.eql(u8, prefix, prior)) return error.PathAlias;
        }
    }
}

fn registeredWorktreeAccessExclusions(
    allocator: std.mem.Allocator,
    registered: []const []const u8,
    repository: []const u8,
) ![]const []const u8 {
    try validateRegisteredWorktreePrefixes(registered);
    try validateCanonicalAbsolute(repository);
    var result = std.array_list.Managed([]const u8).init(allocator);
    errdefer result.deinit();
    var repository_matches: usize = 0;
    for (registered) |path| {
        if (std.mem.eql(u8, path, repository)) {
            repository_matches += 1;
        } else {
            try result.append(path);
        }
    }
    if (repository_matches != 1 or result.items.len + 1 != accepted_registered_worktree_count)
        return error.WorktreeSetMismatch;
    return result.toOwnedSlice();
}

fn validateExplicitPath(
    io: std.Io,
    absolute_path: []const u8,
    expected_kind: PathKind,
    registered_worktree_prefixes: []const []const u8,
) RunnerError!u64 {
    try validateCanonicalAbsolute(absolute_path);
    for (registered_worktree_prefixes) |prefix| {
        try validateCanonicalAbsolute(prefix);
        if (isPathWithin(absolute_path, prefix)) return error.RegisteredWorktreeRejected;
    }
    var file = std.Io.Dir.openFileAbsolute(io, absolute_path, .{
        .mode = .read_only,
        .allow_directory = true,
        .path_only = true,
        .follow_symlinks = false,
    }) catch |failure| switch (failure) {
        error.SymLinkLoop => return error.SymlinkRejected,
        else => return error.PathEscape,
    };
    defer file.close(io);
    const metadata = file.stat(io) catch return error.PathEscape;
    const actual_kind: PathKind = switch (metadata.kind) {
        .file => .file,
        .directory => .directory,
        .sym_link => return error.SymlinkRejected,
        else => return error.WrongPathKind,
    };
    if (actual_kind != expected_kind) return error.WrongPathKind;
    var canonical_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const canonical_length = std.Io.Dir.realPathFileAbsolute(
        io,
        absolute_path,
        &canonical_buffer,
    ) catch return error.PathEscape;
    if (!std.mem.eql(u8, absolute_path, canonical_buffer[0..canonical_length]))
        return error.NonCanonicalPath;
    return @intCast(metadata.inode);
}

fn observePathFact(
    io: std.Io,
    label: []const u8,
    absolute_path: []const u8,
    expected_kind: PathKind,
    registered_worktrees: []const []const u8,
) !PathFact {
    _ = try validateExplicitPath(io, absolute_path, expected_kind, registered_worktrees);
    var file = try std.Io.Dir.openFileAbsolute(io, absolute_path, .{
        .mode = .read_only,
        .allow_directory = true,
        .path_only = true,
        .follow_symlinks = false,
    });
    defer file.close(io);
    const stat = try file.stat(io);
    var native: NativeStatfs = undefined;
    const raw = std.os.linux.syscall2(
        .fstatfs,
        @intCast(file.handle),
        @intFromPtr(&native),
    );
    if (std.os.linux.errno(raw) != .SUCCESS) return error.CapacitySyscallFailed;
    const fs0: u32 = @bitCast(native.f_fsid.values[0]);
    const fs1: u32 = @bitCast(native.f_fsid.values[1]);
    const identity = (@as(u128, fs0) << 96) |
        (@as(u128, fs1) << 64) |
        @as(u64, @intCast(stat.inode));
    return .{
        .label = label,
        .supplied = absolute_path,
        .canonical = absolute_path,
        .kind = expected_kind,
        .expected_kind = expected_kind,
        .is_symlink = false,
        .identity = identity,
    };
}

fn deriveAvailableBytes(fields: CapacityFields) RunnerError!u64 {
    if (fields.block_size <= 0 or fields.fragment_size <= 0 or
        fields.blocks <= 0 or fields.free_blocks <= 0 or
        fields.available_blocks <= 0 or
        fields.free_blocks > fields.blocks or
        fields.available_blocks > fields.free_blocks)
    {
        return error.CapacityFieldsInvalid;
    }
    const unit_signed = @min(fields.block_size, fields.fragment_size);
    if (unit_signed > std.math.maxInt(u64) or
        fields.available_blocks > std.math.maxInt(u64))
    {
        return error.CapacityOverflow;
    }
    return std.math.mul(
        u64,
        @intCast(fields.available_blocks),
        @intCast(unit_signed),
    ) catch return error.CapacityOverflow;
}

fn capacityRootIdentity(
    io: std.Io,
    root: std.Io.Dir,
    filesystem_id: [2]c_int,
) !CapacityRootIdentity {
    const metadata = try root.stat(io);
    if (metadata.kind != .directory) return error.WrongPathKind;
    return .{
        .inode = metadata.inode,
        .mode = @intCast(metadata.permissions.toMode() & 0o7777),
        .kind = metadata.kind,
        .filesystem_id = filesystem_id,
    };
}

fn requireCapacityRootStable(
    before: CapacityRootIdentity,
    after: CapacityRootIdentity,
) RunnerError!void {
    if (!std.meta.eql(before, after)) return error.CapacityRootMismatch;
}

fn fstatfs(validation_root: std.Io.Dir) RunnerError!NativeStatfs {
    var native: NativeStatfs = undefined;
    const raw = std.os.linux.syscall2(
        .fstatfs,
        @intCast(validation_root.handle),
        @intFromPtr(&native),
    );
    switch (std.os.linux.errno(raw)) {
        .SUCCESS => {},
        else => return error.CapacitySyscallFailed,
    }
    return native;
}

fn observeAvailableBytes(io: std.Io, validation_root: std.Io.Dir) !u64 {
    const before_native = try fstatfs(validation_root);
    const before = try capacityRootIdentity(io, validation_root, before_native.f_fsid.values);

    const available = try deriveAvailableBytes(.{
        .block_size = before_native.f_bsize,
        .fragment_size = before_native.f_frsize,
        .blocks = before_native.f_blocks,
        .free_blocks = before_native.f_bfree,
        .available_blocks = before_native.f_bavail,
    });
    const after_native = try fstatfs(validation_root);
    const after = try capacityRootIdentity(io, validation_root, after_native.f_fsid.values);
    try requireCapacityRootStable(before, after);
    return available;
}

fn requireSameOutputFilesystem(
    io: std.Io,
    validation_root: std.Io.Dir,
    absolute_directory: []const u8,
) !void {
    var directory = try std.Io.Dir.openDirAbsolute(io, absolute_directory, .{
        .access_sub_paths = false,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer directory.close(io);
    const validation = try fstatfs(validation_root);
    const candidate = try fstatfs(directory);
    if (!std.meta.eql(validation.f_fsid.values, candidate.f_fsid.values))
        return error.CapacityRootMismatch;
}

fn decodeSha256(hex: []const u8) RunnerError!contract.Digest {
    if (hex.len != 64) return error.InputIdentityMismatch;
    var digest: contract.Digest = undefined;
    for (&digest, 0..) |*byte, index| {
        const high = std.fmt.charToDigit(hex[index * 2], 16) catch
            return error.InputIdentityMismatch;
        const low = std.fmt.charToDigit(hex[index * 2 + 1], 16) catch
            return error.InputIdentityMismatch;
        byte.* = @intCast(high * 16 + low);
    }
    return digest;
}

fn observeFile(
    io: std.Io,
    absolute_path: []const u8,
    executable: bool,
    maximum_bytes: u64,
    registered_worktrees: []const []const u8,
) !FileIdentity {
    _ = try validateExplicitPath(io, absolute_path, .file, registered_worktrees);
    var file = std.Io.Dir.openFileAbsolute(io, absolute_path, .{
        .mode = .read_only,
        .follow_symlinks = false,
    }) catch return error.PathEscape;
    defer file.close(io);
    const metadata = try file.stat(io);
    if (metadata.kind != .file or metadata.size == 0 or metadata.size > maximum_bytes)
        return error.InputIdentityMismatch;
    const mode: u32 = @intCast(metadata.permissions.toMode() & 0o7777);
    if (executable and std.Io.File.Permissions.has_executable_bit and mode & 0o111 == 0)
        return error.WrongExecutable;
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    var offset: u64 = 0;
    var buffer: [64 * 1024]u8 = undefined;
    while (true) {
        const count = try file.readPositional(io, &.{&buffer}, offset);
        if (count == 0) break;
        hasher.update(buffer[0..count]);
        offset = std.math.add(u64, offset, count) catch return error.StorageOverflow;
        if (offset > maximum_bytes) return error.FileCapExceeded;
    }
    if (offset != metadata.size) return error.InputIdentityMismatch;
    var digest: contract.Digest = undefined;
    hasher.final(&digest);
    return .{
        .bytes = offset,
        .mode = mode,
        .inode = metadata.inode,
        .sha256 = digest,
    };
}

fn authenticateFile(
    io: std.Io,
    absolute_path: []const u8,
    expected: ExpectedFile,
    maximum_bytes: u64,
    registered_worktrees: []const []const u8,
) !FileIdentity {
    const identity = try observeFile(
        io,
        absolute_path,
        expected.executable,
        maximum_bytes,
        registered_worktrees,
    );
    if (identity.bytes != expected.bytes or
        !std.mem.eql(u8, &identity.sha256, &(try decodeSha256(expected.sha256_hex))))
    {
        return error.InputIdentityMismatch;
    }
    return identity;
}

fn authenticateSubject(
    io: std.Io,
    selector: ToolSelector,
    registered_worktrees: []const []const u8,
) !AuthenticatedSubject {
    const identity = try observeFile(
        io,
        selector.path,
        true,
        maximum_artifact_bytes,
        registered_worktrees,
    );
    if (identity.bytes != selector.authorized_bytes or
        !std.mem.eql(u8, &identity.sha256, &selector.authorized_sha256))
    {
        return error.SubjectIdentityMismatch;
    }
    if (selector.role == .zig) {
        const version = selector.authorized_version orelse
            return error.SubjectAuthorityMismatch;
        if (!std.mem.eql(u8, version, expected_zig_version))
            return error.SubjectAuthorityMismatch;
    } else if (selector.authorized_version != null) {
        return error.SubjectAuthorityMismatch;
    }
    return .{
        .path = selector.path,
        .identity = identity,
        .portable_tool = .{
            .role = selector.role,
            .bytes = selector.authorized_bytes,
            .sha256 = selector.authorized_sha256,
            .version = selector.authorized_version,
        },
    };
}

fn requireSubjectStable(
    io: std.Io,
    subject: AuthenticatedSubject,
    registered_worktrees: []const []const u8,
) !void {
    const current = try observeFile(
        io,
        subject.path,
        true,
        maximum_artifact_bytes,
        registered_worktrees,
    );
    if (!std.meta.eql(subject.identity, current)) return error.SubjectIdentityMismatch;
    if (subject.portable_tool) |portable| {
        if (portable.bytes != current.bytes or
            !std.mem.eql(u8, &portable.sha256, &current.sha256))
        {
            return error.SubjectIdentityMismatch;
        }
    }
}

fn joinAbsolute(
    allocator: std.mem.Allocator,
    base: []const u8,
    relative: []const u8,
) ![]u8 {
    try validateCanonicalAbsolute(base);
    if (relative.len == 0 or std.fs.path.isAbsolute(relative) or
        std.mem.indexOfScalar(u8, relative, 0) != null)
    {
        return error.PathEscape;
    }
    var components = std.mem.splitScalar(u8, relative, '/');
    while (components.next()) |component| {
        if (component.len == 0 or std.mem.eql(u8, component, ".") or
            std.mem.eql(u8, component, "..")) return error.PathEscape;
    }
    return std.fs.path.join(allocator, &.{ base, relative });
}

fn nextArgument(args: *std.process.Args.Iterator) RunnerError![]const u8 {
    return args.next() orelse error.InvalidArguments;
}

fn parseToolRole(text: []const u8) RunnerError!ToolRole {
    inline for (@typeInfo(ToolRole).@"enum".fields) |field| {
        if (std.mem.eql(u8, text, field.name)) return @enumFromInt(field.value);
    }
    return error.InvalidArguments;
}

fn parseToolSelector(
    args: *std.process.Args.Iterator,
    expected_role: ToolRole,
) RunnerError!ToolSelector {
    if (!std.mem.eql(u8, try nextArgument(args), "--tool"))
        return error.InvalidArguments;
    const role = try parseToolRole(try nextArgument(args));
    if (role != expected_role) return error.InvalidArguments;
    const path = try nextArgument(args);
    const authorized_bytes = std.fmt.parseInt(u64, try nextArgument(args), 10) catch
        return error.InvalidArguments;
    if (authorized_bytes == 0) return error.InvalidArguments;
    const authorized_sha256 = decodeSha256(try nextArgument(args)) catch
        return error.InvalidArguments;
    const version_text = try nextArgument(args);
    const authorized_version: ?[]const u8 = if (std.mem.eql(u8, version_text, "-"))
        null
    else
        version_text;
    if ((expected_role == .zig) != (authorized_version != null))
        return error.InvalidArguments;
    return .{
        .role = role,
        .path = path,
        .authorized_bytes = authorized_bytes,
        .authorized_sha256 = authorized_sha256,
        .authorized_version = authorized_version,
    };
}

fn parseBaselineCli(
    allocator: std.mem.Allocator,
    args: *std.process.Args.Iterator,
) !Cli {
    var result = Cli{
        .zig = try parseToolSelector(args, .zig),
        .git = try parseToolSelector(args, .git),
        .llvm_extract = try parseToolSelector(args, .llvm_extract),
        .objcopy = try parseToolSelector(args, .objcopy),
        .objdump = try parseToolSelector(args, .objdump),
        .readelf = try parseToolSelector(args, .readelf),
        .repository = try nextArgument(args),
        .external_zig_repository = try nextArgument(args),
        .canonical_source = try nextArgument(args),
        .coverage_source = try nextArgument(args),
        .raw_input = try nextArgument(args),
        .adoption_manifest = try nextArgument(args),
        .bundle_root = try nextArgument(args),
        .reproduction_manifest = try nextArgument(args),
        .retention_pins = try nextArgument(args),
        .retention_policy = try nextArgument(args),
        .cleanup_source = try nextArgument(args),
        .bypass_inventory = try nextArgument(args),
        .facade_manifest = try nextArgument(args),
        .facade_source = try nextArgument(args),
        .external_stage4 = try nextArgument(args),
        .validation_root = try nextArgument(args),
        .registered_worktrees = undefined,
    };
    var registered = std.array_list.Managed([]const u8).init(allocator);
    errdefer registered.deinit();
    while (args.next()) |marker| {
        if (!std.mem.eql(u8, marker, "--registered-worktree")) return error.InvalidArguments;
        try registered.append(try nextArgument(args));
    }
    result.registered_worktrees = try registered.toOwnedSlice();
    errdefer allocator.free(result.registered_worktrees);
    try validateRegisteredWorktreePrefixes(result.registered_worktrees);
    return result;
}

fn parseExpectedParent(text: []const u8) RunnerError![40]u8 {
    if (!isLowerSha1(text)) return error.InvalidArguments;
    var result: [40]u8 = undefined;
    @memcpy(&result, text);
    return result;
}

fn parseSourceAcceptanceCli(args: *std.process.Args.Iterator) !SourceAcceptanceCli {
    const result = SourceAcceptanceCli{
        .zig = try parseToolSelector(args, .zig),
        .git = try parseToolSelector(args, .git),
        .repository = try nextArgument(args),
        .expected_parent = try parseExpectedParent(try nextArgument(args)),
        .contract_source = try nextArgument(args),
        .runner_source = try nextArgument(args),
        .output_path = try nextArgument(args),
    };
    if (args.next() != null) return error.InvalidArguments;
    return result;
}

fn validateFixedCommand(request: ProcessRequest, expected: FixedCommand) RunnerError!void {
    try validateCanonicalAbsolute(request.executable);
    try validateCanonicalAbsolute(request.cwd);
    if (!std.mem.eql(u8, request.executable, expected.executable)) return error.WrongExecutable;
    if (!std.mem.eql(u8, request.cwd, expected.cwd)) return error.WrongWorkingDirectory;
    if (!equalStringSlices(request.argv, expected.argv)) return error.WrongArguments;
    if (request.environment.len != expected.environment.len) return error.WrongEnvironment;
    for (request.environment, expected.environment) |actual, wanted| {
        if (!std.mem.eql(u8, actual.name, wanted.name) or
            !std.mem.eql(u8, actual.value, wanted.value) or
            std.mem.indexOfScalar(u8, actual.name, 0) != null or
            std.mem.indexOfScalar(u8, actual.value, 0) != null)
        {
            return error.WrongEnvironment;
        }
    }
}

fn equalStringSlices(a: []const []const u8, b: []const []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |left, right| if (!std.mem.eql(u8, left, right)) return false;
    return true;
}

fn validateCapturedResult(result: CapturedResult) RunnerError!void {
    if (!result.stdout_complete or !result.stderr_complete) return error.IncompleteCapture;
    if (result.stdout.len > process_capture_max or result.stderr.len > process_capture_max)
        return error.ChildOutputOverflow;
    switch (result.termination) {
        .exited => |status| if (status != 0) return error.ChildFailed,
        else => return error.ChildFailed,
    }
}

fn requireConsistentResult(a: CapturedResult, b: CapturedResult) RunnerError!void {
    try validateCapturedResult(a);
    try validateCapturedResult(b);
    if (!std.meta.eql(a.termination, b.termination) or
        !std.mem.eql(u8, a.stdout, b.stdout) or
        !std.mem.eql(u8, a.stderr, b.stderr)) return error.InconsistentResult;
}

fn parseUnsigned(field: []const u8) RunnerError!u64 {
    if (field.len == 0) return error.MalformedCounterChannel;
    return std.fmt.parseUnsigned(u64, field, 10) catch error.MalformedCounterChannel;
}

fn parseCoverageChannel(bytes: []const u8) RunnerError!ParsedCoverageChannel {
    var summaries = [_]?contract.FamilyCounters{ null, null };
    var positions_seen = [_][6]bool{[_]bool{false} ** 6} ** 2;
    var schema_count: usize = 0;
    var unexpected: ?u64 = null;
    var overflow: ?u64 = null;
    var lines = std.mem.splitScalar(u8, bytes, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var fields_iterator = std.mem.splitScalar(u8, line, '\t');
        var fields: [8][]const u8 = undefined;
        var field_count: usize = 0;
        while (fields_iterator.next()) |field| {
            if (field_count == fields.len) return error.MalformedCounterChannel;
            fields[field_count] = field;
            field_count += 1;
        }
        if (std.mem.eql(u8, fields[0], "schema")) {
            if (field_count != 2 or !std.mem.eql(u8, fields[1], "o2_calls_crt_v1_coverage_v1"))
                return error.MalformedCounterChannel;
            schema_count += 1;
            continue;
        }
        if (std.mem.eql(u8, fields[0], "unexpected_family_events")) {
            if (field_count != 2 or unexpected != null) return error.MalformedCounterChannel;
            unexpected = try parseUnsigned(fields[1]);
            continue;
        }
        if (std.mem.eql(u8, fields[0], "argument_index_overflow_events")) {
            if (field_count != 2 or overflow != null) return error.MalformedCounterChannel;
            overflow = try parseUnsigned(fields[1]);
            continue;
        }
        const family_index: usize = if (std.mem.eql(u8, fields[0], "direct_call"))
            0
        else if (std.mem.eql(u8, fields[0], "int_byte_size_call"))
            1
        else
            return error.MalformedCounterChannel;
        if (field_count == 8) {
            if (summaries[family_index] != null) return error.MalformedCounterChannel;
            summaries[family_index] = .{
                .transactions = try parseUnsigned(fields[1]),
                .requests = try parseUnsigned(fields[2]),
                .attachments = try parseUnsigned(fields[3]),
                .stages = try parseUnsigned(fields[4]),
                .materializations = try parseUnsigned(fields[5]),
                .actions = try parseUnsigned(fields[6]),
                .commits = try parseUnsigned(fields[7]),
                .position_requests = [_]u64{0} ** 6,
                .position_stages = [_]u64{0} ** 6,
            };
        } else if (field_count == 4) {
            const position_value = try parseUnsigned(fields[1]);
            if (position_value >= 6 or positions_seen[family_index][position_value])
                return error.MalformedCounterChannel;
            if (summaries[family_index] == null) return error.MalformedCounterChannel;
            const position: usize = @intCast(position_value);
            positions_seen[family_index][position] = true;
            summaries[family_index].?.position_requests[position] = try parseUnsigned(fields[2]);
            summaries[family_index].?.position_stages[position] = try parseUnsigned(fields[3]);
        } else {
            return error.MalformedCounterChannel;
        }
    }
    if (schema_count != 1 or summaries[0] == null or summaries[1] == null or
        unexpected == null or overflow == null)
    {
        return error.MalformedCounterChannel;
    }
    for (positions_seen) |family_positions| for (family_positions) |seen| {
        if (!seen) return error.MalformedCounterChannel;
    };
    return .{
        .families = .{
            .direct_call = summaries[0].?,
            .int_byte_size_call = summaries[1].?,
        },
        .unexpected_family_events = unexpected.?,
        .argument_index_overflow_events = overflow.?,
    };
}

fn lessString(_: void, left: []const u8, right: []const u8) bool {
    return std.mem.order(u8, left, right) == .lt;
}

fn parseReportFailures(
    allocator: std.mem.Allocator,
    stderr: []const u8,
) ![]const []const u8 {
    var functions = std.array_list.Managed([]const u8).init(allocator);
    errdefer functions.deinit();
    var summary_count: usize = 0;
    var lines = std.mem.splitScalar(u8, stderr, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var tokens = std.mem.tokenizeScalar(u8, line, ' ');
        const first = tokens.next() orelse return error.ParseFailure;
        if (std.mem.eql(u8, first, "summary")) {
            const second = tokens.next() orelse return error.ParseFailure;
            if (!std.mem.eql(u8, second, "zllvm-codegen-report-all")) continue;
            summary_count += 1;
            continue;
        }
        if (!std.mem.eql(u8, first, "zllvm-codegen-failure")) continue;
        var function: ?[]const u8 = null;
        while (tokens.next()) |token| {
            if (std.mem.startsWith(u8, token, "function=")) {
                if (function != null or token.len == "function=".len) return error.ParseFailure;
                function = token["function=".len..];
            }
        }
        try functions.append(function orelse return error.ParseFailure);
    }
    if (summary_count != 1 or functions.items.len == 0) return error.ParseFailure;
    std.mem.sort([]const u8, functions.items, {}, lessString);
    for (functions.items[1..], functions.items[0 .. functions.items.len - 1]) |current, prior| {
        if (std.mem.eql(u8, current, prior)) return error.ParseFailure;
    }
    return functions.toOwnedSlice();
}

fn validateReportSummary(stderr: []const u8, failure_count: usize) RunnerError!void {
    var summary_seen: usize = 0;
    var lines = std.mem.splitScalar(u8, stderr, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "summary zllvm-codegen-report-all ")) continue;
        summary_seen += 1;
        var selected: ?u64 = null;
        var emitted: ?u64 = null;
        var failed: ?u64 = null;
        var local_fail: ?u64 = null;
        var first_failure = false;
        var first_diagnostic = false;
        var fields = std.mem.tokenizeScalar(u8, line, ' ');
        _ = fields.next();
        _ = fields.next();
        while (fields.next()) |field| {
            const separator = std.mem.indexOfScalar(u8, field, '=') orelse continue;
            const name = field[0..separator];
            const value = field[separator + 1 ..];
            if (std.mem.eql(u8, name, "selected_functions")) selected = try parseUnsigned(value) else if (std.mem.eql(u8, name, "emitted_functions")) emitted = try parseUnsigned(value) else if (std.mem.eql(u8, name, "failed_functions")) failed = try parseUnsigned(value) else if (std.mem.eql(u8, name, "local_fail")) local_fail = try parseUnsigned(value) else if (std.mem.eql(u8, name, "first_failure")) first_failure = value.len != 0 and !std.mem.eql(u8, value, "-") else if (std.mem.eql(u8, name, "first_diagnostic")) first_diagnostic = value.len != 0 and !std.mem.eql(u8, value, "-");
        }
        if (selected == null or emitted == null or failed == null or local_fail == null or
            selected.? != emitted.? + failed.? or emitted.? != contract.successful_function_count or
            failed.? != failure_count or local_fail.? != 1 or !first_failure or !first_diagnostic)
        {
            return error.ParseFailure;
        }
    }
    if (summary_seen != 1) return error.ParseFailure;
}

fn lessFunction(_: void, left: FunctionRow, right: FunctionRow) bool {
    return std.mem.order(u8, left.name, right.name) == .lt;
}

fn parseReadelfFunctions(
    allocator: std.mem.Allocator,
    bytes: []const u8,
) ![]const FunctionRow {
    var rows = std.array_list.Managed(FunctionRow).init(allocator);
    errdefer rows.deinit();
    var lines = std.mem.splitScalar(u8, bytes, '\n');
    while (lines.next()) |line| {
        var fields = std.mem.tokenizeAny(u8, line, " \t");
        const number = fields.next() orelse continue;
        if (number.len < 2 or number[number.len - 1] != ':') continue;
        const value = fields.next() orelse return error.ParseFailure;
        const size = fields.next() orelse return error.ParseFailure;
        const kind = fields.next() orelse return error.ParseFailure;
        _ = fields.next() orelse return error.ParseFailure;
        _ = fields.next() orelse return error.ParseFailure;
        const section = fields.next() orelse return error.ParseFailure;
        const name = fields.next() orelse return error.ParseFailure;
        if (!std.mem.eql(u8, kind, "FUNC") or !std.mem.eql(u8, section, "1")) continue;
        const parsed_size = std.fmt.parseUnsigned(u64, size, 10) catch return error.ParseFailure;
        if (parsed_size == 0) continue;
        try rows.append(.{
            .name = name,
            .value = std.fmt.parseUnsigned(u64, value, 16) catch return error.ParseFailure,
            .size = parsed_size,
        });
    }
    if (rows.items.len != contract.successful_function_count) return error.FunctionCountMismatch;
    std.mem.sort(FunctionRow, rows.items, {}, lessFunction);
    for (rows.items[1..], rows.items[0 .. rows.items.len - 1]) |current, prior| {
        if (std.mem.eql(u8, current.name, prior.name)) return error.ParseFailure;
    }
    return rows.toOwnedSlice();
}

fn validateReadelfSections(bytes: []const u8) RunnerError!void {
    var text_count: usize = 0;
    var lines = std.mem.splitScalar(u8, bytes, '\n');
    while (lines.next()) |line| {
        var fields = std.mem.tokenizeAny(u8, line, " \t");
        while (fields.next()) |field| {
            if (!std.mem.eql(u8, field, ".text")) continue;
            const kind = fields.next() orelse return error.ParseFailure;
            if (!std.mem.eql(u8, kind, "PROGBITS")) return error.ParseFailure;
            text_count += 1;
        }
    }
    if (text_count != 1) return error.ParseFailure;
}

fn validateObjdumpFunctions(bytes: []const u8, rows: []const FunctionRow) RunnerError!void {
    for (rows) |row| {
        var offset: usize = 0;
        var found = false;
        while (std.mem.indexOfPos(u8, bytes, offset, row.name)) |position| {
            const after = position + row.name.len;
            if (position > 0 and bytes[position - 1] == '<' and
                after + 1 < bytes.len and bytes[after] == '>' and bytes[after + 1] == ':')
            {
                found = true;
                break;
            }
            offset = after;
        }
        if (!found) return error.ParseFailure;
    }
}

fn sha256FileRange(
    io: std.Io,
    file: std.Io.File,
    offset: u64,
    size: u64,
) !contract.Digest {
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    var consumed: u64 = 0;
    var buffer: [64 * 1024]u8 = undefined;
    while (consumed < size) {
        const remaining = size - consumed;
        const request: usize = @intCast(@min(remaining, buffer.len));
        const count = try file.readPositionalAll(io, buffer[0..request], offset + consumed);
        if (count != request) return error.IncompleteCapture;
        hasher.update(buffer[0..count]);
        consumed += count;
    }
    var digest: contract.Digest = undefined;
    hasher.final(&digest);
    return digest;
}

fn encodeFunctionManifest(
    allocator: std.mem.Allocator,
    io: std.Io,
    text_path: []const u8,
    text_size: u64,
    rows: []const FunctionRow,
) ![]u8 {
    var file = try std.Io.Dir.openFileAbsolute(io, text_path, .{
        .mode = .read_only,
        .follow_symlinks = false,
    });
    defer file.close(io);
    var output: std.Io.Writer.Allocating = .init(allocator);
    errdefer output.deinit();
    try output.writer.writeAll("name\tvalue_hex\tbytes\tsha256\n");
    for (rows) |row| {
        const end = std.math.add(u64, row.value, row.size) catch return error.StorageOverflow;
        if (end > text_size) return error.ParseFailure;
        const digest = try sha256FileRange(io, file, row.value, row.size);
        const hex = std.fmt.bytesToHex(digest, .lower);
        try output.writer.print("{s}\t{x}\t{d}\t{s}\n", .{ row.name, row.value, row.size, &hex });
    }
    return output.toOwnedSlice();
}

fn validateOwnerManifest(bytes: []const u8) RunnerError!void {
    var lines = std.mem.splitScalar(u8, bytes, '\n');
    const header = lines.next() orelse return error.OwnerMismatch;
    if (!std.mem.eql(u8, header, "row_identity\tselection_owner")) return error.OwnerMismatch;
    var count: usize = 0;
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var fields = std.mem.splitScalar(u8, line, '\t');
        const identity = fields.next() orelse return error.OwnerMismatch;
        const owner = fields.next() orelse return error.OwnerMismatch;
        if (identity.len == 0 or fields.next() != null or
            (!std.mem.eql(u8, owner, "composed_block") and
                !std.mem.eql(u8, owner, "composed_cfg") and
                !std.mem.eql(u8, owner, "legacy_envelope") and
                !std.mem.eql(u8, owner, "structural_fallback")))
        {
            return error.OwnerMismatch;
        }
        count += 1;
    }
    if (count != contract.successful_function_count) return error.OwnerMismatch;
}

fn runBounded(
    allocator: std.mem.Allocator,
    io: std.Io,
    command: FixedCommand,
) (RunnerError || std.mem.Allocator.Error)!std.process.RunResult {
    var environment = std.process.Environ.Map.init(allocator);
    defer environment.deinit();
    for (command.environment) |entry| environment.put(entry.name, entry.value) catch
        return error.OutOfMemory;
    return std.process.run(allocator, io, .{
        .argv = command.argv,
        .cwd = .{ .path = command.cwd },
        .environ_map = &environment,
        .stdout_limit = .limited(process_capture_max),
        .stderr_limit = .limited(process_capture_max),
    }) catch |failure| switch (failure) {
        error.OutOfMemory => return error.OutOfMemory,
        error.StreamTooLong => return error.ChildOutputOverflow,
        else => return error.SpawnFailed,
    };
}

fn processTermination(term: std.process.Child.Term) Termination {
    return switch (term) {
        .exited => |status| .{ .exited = status },
        .signal => |signal| .{ .signal = @intFromEnum(signal) },
        .stopped => |signal| .{ .stopped = @intFromEnum(signal) },
        .unknown => |status| .{ .unknown = status },
    };
}

fn runAuthenticated(
    allocator: std.mem.Allocator,
    io: std.Io,
    subject: AuthenticatedSubject,
    command: FixedCommand,
    expected_status: u8,
    registered_worktrees: []const []const u8,
) !std.process.RunResult {
    if (!std.mem.eql(u8, subject.path, command.executable) or command.argv.len == 0 or
        !std.mem.eql(u8, command.argv[0], subject.path)) return error.WrongExecutable;
    try requireSubjectStable(io, subject, registered_worktrees);
    const result = try runBounded(allocator, io, command);
    errdefer {
        allocator.free(result.stdout);
        allocator.free(result.stderr);
    }
    const captured = CapturedResult{
        .termination = processTermination(result.term),
        .stdout = result.stdout,
        .stderr = result.stderr,
        .stdout_complete = true,
        .stderr_complete = true,
    };
    if (captured.stdout.len > process_capture_max or captured.stderr.len > process_capture_max)
        return error.ChildOutputOverflow;
    switch (captured.termination) {
        .exited => |status| if (status != expected_status) return error.ChildFailed,
        else => return error.ChildFailed,
    }
    try requireSubjectStable(io, subject, registered_worktrees);
    return result;
}

fn fixedEnvironment(home: []const u8, temporary: []const u8) [6]EnvironmentEntry {
    return .{
        .{ .name = "HOME", .value = home },
        .{ .name = "TMPDIR", .value = temporary },
        .{ .name = "LANG", .value = "C" },
        .{ .name = "LC_ALL", .value = "C" },
        .{ .name = "TZ", .value = "UTC0" },
        .{ .name = "SOURCE_DATE_EPOCH", .value = "0" },
    };
}

fn fixedCoverageEnvironment(
    home: []const u8,
    temporary: []const u8,
    channel: []const u8,
) [7]EnvironmentEntry {
    return .{
        .{ .name = "HOME", .value = home },
        .{ .name = "TMPDIR", .value = temporary },
        .{ .name = "LANG", .value = "C" },
        .{ .name = "LC_ALL", .value = "C" },
        .{ .name = "TZ", .value = "UTC0" },
        .{ .name = "SOURCE_DATE_EPOCH", .value = "0" },
        .{ .name = "ZLLVM_CALL_COVERAGE_PATH", .value = channel },
    };
}

fn fixedGitEnvironment() [10]EnvironmentEntry {
    return .{
        .{ .name = "HOME", .value = "/nonexistent-inbox206cy-home" },
        .{ .name = "LANG", .value = "C" },
        .{ .name = "LC_ALL", .value = "C" },
        .{ .name = "TZ", .value = "UTC0" },
        .{ .name = "GIT_OPTIONAL_LOCKS", .value = "0" },
        .{ .name = "GIT_CONFIG_NOSYSTEM", .value = "1" },
        .{ .name = "GIT_CONFIG_SYSTEM", .value = "/dev/null" },
        .{ .name = "GIT_CONFIG_GLOBAL", .value = "/dev/null" },
        .{ .name = "GIT_TERMINAL_PROMPT", .value = "0" },
        .{ .name = "SOURCE_DATE_EPOCH", .value = "0" },
    };
}

fn isLowerSha1(bytes: []const u8) bool {
    if (bytes.len != 40) return false;
    for (bytes) |byte| {
        if (!std.ascii.isDigit(byte) and !(byte >= 'a' and byte <= 'f'))
            return false;
    }
    return true;
}

const WorktreeRecordState = struct {
    path: ?[]const u8 = null,
    head: bool = false,
    disposition: bool = false,
    locked: bool = false,
    prunable: bool = false,
};

fn acceptWorktreeMetadataField(
    state: *WorktreeRecordState,
    field: []const u8,
) RunnerError!void {
    if (std.mem.startsWith(u8, field, "HEAD ")) {
        if (state.head or !isLowerSha1(field[5..])) return error.WorktreeMetadataMalformed;
        state.head = true;
    } else if (std.mem.startsWith(u8, field, "branch ")) {
        if (state.disposition or field.len == "branch ".len)
            return error.WorktreeMetadataMalformed;
        state.disposition = true;
    } else if (std.mem.eql(u8, field, "detached") or std.mem.eql(u8, field, "bare")) {
        if (state.disposition) return error.WorktreeMetadataMalformed;
        state.disposition = true;
    } else if (std.mem.eql(u8, field, "locked") or std.mem.startsWith(u8, field, "locked ")) {
        if (state.locked) return error.WorktreeMetadataMalformed;
        state.locked = true;
    } else if (std.mem.eql(u8, field, "prunable") or std.mem.startsWith(u8, field, "prunable ")) {
        if (state.prunable) return error.WorktreeMetadataMalformed;
        state.prunable = true;
    } else {
        return error.WorktreeMetadataMalformed;
    }
}

fn finishWorktreeRecord(
    state: *WorktreeRecordState,
    paths: *[accepted_registered_worktree_count][]const u8,
    count: *usize,
) RunnerError!void {
    const path = state.path orelse return error.WorktreeMetadataMalformed;
    if (!state.head or !state.disposition or count.* == paths.len)
        return error.WorktreeMetadataMalformed;
    for (paths[0..count.*]) |prior| {
        if (std.mem.eql(u8, prior, path)) return error.WorktreeMetadataMalformed;
    }
    paths[count.*] = path;
    count.* += 1;
    state.* = .{};
}

fn registeredWorktreeSetIdentity(
    observed: []const u8,
    expected: []const []const u8,
) RunnerError!RegisteredWorktreeSetIdentity {
    try validateRegisteredWorktreePrefixes(expected);
    if (observed.len == 0 or observed[observed.len - 1] != 0)
        return error.WorktreeMetadataMalformed;

    var paths: [accepted_registered_worktree_count][]const u8 = undefined;
    var count: usize = 0;
    var state = WorktreeRecordState{};
    var offset: usize = 0;
    while (offset < observed.len) {
        const relative_end = std.mem.indexOfScalar(u8, observed[offset..], 0) orelse
            return error.WorktreeMetadataMalformed;
        const end = std.math.add(usize, offset, relative_end) catch
            return error.WorktreeMetadataMalformed;
        const field = observed[offset..end];
        offset = std.math.add(usize, end, 1) catch
            return error.WorktreeMetadataMalformed;
        if (field.len == 0) {
            try finishWorktreeRecord(&state, &paths, &count);
            continue;
        }
        if (state.path == null) {
            if (!std.mem.startsWith(u8, field, "worktree ") or field.len == "worktree ".len)
                return error.WorktreeMetadataMalformed;
            const path = field["worktree ".len..];
            validateCanonicalAbsolute(path) catch return error.WorktreeMetadataMalformed;
            state.path = path;
        } else {
            try acceptWorktreeMetadataField(&state, field);
        }
    }
    if (state.path != null or count != accepted_registered_worktree_count)
        return error.WorktreeMetadataMalformed;

    for (expected) |wanted| {
        var matches: usize = 0;
        for (paths[0..count]) |actual| {
            if (std.mem.eql(u8, wanted, actual)) matches += 1;
        }
        if (matches != 1) return error.WorktreeSetMismatch;
    }
    for (paths[0..count]) |actual| {
        var matches: usize = 0;
        for (expected) |wanted| {
            if (std.mem.eql(u8, wanted, actual)) matches += 1;
        }
        if (matches != 1) return error.WorktreeSetMismatch;
    }

    var sorted = paths;
    var index: usize = 1;
    while (index < sorted.len) : (index += 1) {
        const value = sorted[index];
        var insert = index;
        while (insert > 0 and std.mem.order(u8, value, sorted[insert - 1]) == .lt) {
            sorted[insert] = sorted[insert - 1];
            insert -= 1;
        }
        sorted[insert] = value;
    }
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    for (sorted) |path| {
        var length: [8]u8 = undefined;
        std.mem.writeInt(u64, &length, @intCast(path.len), .little);
        hasher.update(&length);
        hasher.update(path);
    }
    var digest: contract.Digest = undefined;
    hasher.final(&digest);
    return .{ .count = @intCast(count), .sha256 = digest };
}

fn parseSha1Line(bytes: []const u8) RunnerError![40]u8 {
    if (bytes.len != 41 or bytes[40] != '\n') return error.GitObservationMismatch;
    var result: [40]u8 = undefined;
    for (bytes[0..40], &result) |byte, *output| {
        if (!std.ascii.isDigit(byte) and !(byte >= 'a' and byte <= 'f'))
            return error.GitObservationMismatch;
        output.* = byte;
    }
    return result;
}

fn decodeSha1(hex: []const u8) RunnerError!GitBlobId {
    if (!isLowerSha1(hex)) return error.IndexMetadataMalformed;
    var result: GitBlobId = undefined;
    for (&result, 0..) |*byte, index| {
        const high = std.fmt.charToDigit(hex[index * 2], 16) catch
            return error.IndexMetadataMalformed;
        const low = std.fmt.charToDigit(hex[index * 2 + 1], 16) catch
            return error.IndexMetadataMalformed;
        byte.* = @intCast(high * 16 + low);
    }
    return result;
}

const ParsedStagedEntry = struct {
    path: []const u8,
    mode: u32,
    blob: GitBlobId,
    status: u8,
};

const ParsedStagedSet = struct {
    contract_source: ParsedStagedEntry,
    runner_source: ParsedStagedEntry,
};

fn parseRawStagedEntry(metadata: []const u8, path: []const u8) RunnerError!ParsedStagedEntry {
    if (metadata.len == 0 or metadata[0] != ':' or path.len == 0 or
        std.fs.path.isAbsolute(path) or std.mem.indexOfScalar(u8, path, 0) != null)
    {
        return error.IndexMetadataMalformed;
    }
    try validateRelativeManifestPath(path);
    var fields = std.mem.splitScalar(u8, metadata[1..], ' ');
    const old_mode = fields.next() orelse return error.IndexMetadataMalformed;
    const new_mode = fields.next() orelse return error.IndexMetadataMalformed;
    const old_blob = fields.next() orelse return error.IndexMetadataMalformed;
    const new_blob = fields.next() orelse return error.IndexMetadataMalformed;
    const status = fields.next() orelse return error.IndexMetadataMalformed;
    if (fields.next() != null or old_mode.len != 6 or !isLowerSha1(old_blob) or
        !isLowerSha1(new_blob) or !std.mem.eql(u8, new_mode, "100644") or status.len != 1 or
        (status[0] != 'A' and status[0] != 'M'))
    {
        return error.IndexMetadataMalformed;
    }
    for (old_mode) |byte| if (byte < '0' or byte > '7') return error.IndexMetadataMalformed;
    const zero_blob = "0" ** 40;
    if ((status[0] == 'A' and
        (!std.mem.eql(u8, old_mode, "000000") or !std.mem.eql(u8, old_blob, zero_blob))) or
        (status[0] == 'M' and
            (!std.mem.eql(u8, old_mode, "100644") or std.mem.eql(u8, old_blob, zero_blob))) or
        std.mem.eql(u8, new_blob, zero_blob))
    {
        return error.IndexMetadataMalformed;
    }
    return .{
        .path = path,
        .mode = 0o100644,
        .blob = try decodeSha1(new_blob),
        .status = status[0],
    };
}

fn parseExactCyStagedSet(bytes: []const u8) RunnerError!ParsedStagedSet {
    if (bytes.len == 0 or bytes[bytes.len - 1] != 0) return error.IndexMetadataMalformed;
    var contract_entry: ?ParsedStagedEntry = null;
    var runner_entry: ?ParsedStagedEntry = null;
    var offset: usize = 0;
    var count: usize = 0;
    while (offset < bytes.len) {
        const metadata_end_relative = std.mem.indexOfScalar(u8, bytes[offset..], 0) orelse
            return error.IndexMetadataMalformed;
        const metadata_end = std.math.add(usize, offset, metadata_end_relative) catch
            return error.IndexMetadataMalformed;
        const metadata = bytes[offset..metadata_end];
        offset = std.math.add(usize, metadata_end, 1) catch
            return error.IndexMetadataMalformed;
        if (offset >= bytes.len) return error.IndexMetadataMalformed;
        const path_end_relative = std.mem.indexOfScalar(u8, bytes[offset..], 0) orelse
            return error.IndexMetadataMalformed;
        const path_end = std.math.add(usize, offset, path_end_relative) catch
            return error.IndexMetadataMalformed;
        const path = bytes[offset..path_end];
        offset = std.math.add(usize, path_end, 1) catch
            return error.IndexMetadataMalformed;
        const entry = try parseRawStagedEntry(metadata, path);
        if (std.mem.eql(u8, path, contract_source_relative)) {
            if (contract_entry != null or entry.status != 'M') return error.IndexSetMismatch;
            contract_entry = entry;
        } else if (std.mem.eql(u8, path, runner_source_relative)) {
            if (runner_entry != null or entry.status != 'A') return error.IndexSetMismatch;
            runner_entry = entry;
        } else {
            return error.IndexSetMismatch;
        }
        count += 1;
    }
    if (count != 2) return error.IndexSetMismatch;
    return .{
        .contract_source = contract_entry orelse return error.IndexSetMismatch,
        .runner_source = runner_entry orelse return error.IndexSetMismatch,
    };
}

fn gitBlobIdentity(bytes: []const u8) GitBlobId {
    var header_buffer: [64]u8 = undefined;
    const header = std.fmt.bufPrint(&header_buffer, "blob {d}\x00", .{bytes.len}) catch unreachable;
    var hasher = std.crypto.hash.Sha1.init(.{});
    hasher.update(header);
    hasher.update(bytes);
    var result: GitBlobId = undefined;
    hasher.final(&result);
    return result;
}

fn observeStagedSource(
    allocator: std.mem.Allocator,
    io: std.Io,
    absolute_path: []const u8,
    staged: ParsedStagedEntry,
) !StagedSourceIdentity {
    const bytes = try readBoundedAbsolute(allocator, io, absolute_path, maximum_input_bytes);
    defer allocator.free(bytes);
    const observed = try observeFile(io, absolute_path, false, maximum_input_bytes, &.{});
    const raw_sha256 = sha256(bytes);
    const blob = gitBlobIdentity(bytes);
    if (staged.mode != 0o100644 or observed.mode & 0o111 != 0 or
        observed.bytes != bytes.len or !std.mem.eql(u8, &observed.sha256, &raw_sha256) or
        !std.mem.eql(u8, &staged.blob, &blob))
    {
        return error.StagedSourceMismatch;
    }
    return .{
        .mode = staged.mode,
        .bytes = observed.bytes,
        .blob = blob,
        .raw_sha256 = raw_sha256,
        .worktree_inode = observed.inode,
    };
}

fn runGitObservation(
    allocator: std.mem.Allocator,
    io: std.Io,
    git: AuthenticatedSubject,
    repository: []const u8,
    suffix: []const []const u8,
    registered_worktrees: []const []const u8,
) !std.process.RunResult {
    const prefix = [_][]const u8{
        git.path,
        "--no-optional-locks",
        "-c",
        "core.fsmonitor=false",
        "-c",
        "core.untrackedCache=false",
        "-C",
        repository,
    };
    var argv = std.array_list.Managed([]const u8).init(allocator);
    defer argv.deinit();
    try argv.appendSlice(&prefix);
    try argv.appendSlice(suffix);
    const environment = fixedGitEnvironment();
    return runAuthenticated(allocator, io, git, .{
        .executable = git.path,
        .argv = argv.items,
        .environment = &environment,
        .cwd = repository,
    }, 0, registered_worktrees);
}

fn observeRegisteredWorktreeSet(
    allocator: std.mem.Allocator,
    io: std.Io,
    git: AuthenticatedSubject,
    repository: []const u8,
    expected: []const []const u8,
) !RegisteredWorktreeSetIdentity {
    const result = try runGitObservation(
        allocator,
        io,
        git,
        repository,
        &.{ "worktree", "list", "--porcelain", "-z" },
        expected,
    );
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);
    if (result.stderr.len != 0) return error.GitObservationMismatch;
    return registeredWorktreeSetIdentity(result.stdout, expected);
}

fn validateSourceAcceptanceCliPaths(
    allocator: std.mem.Allocator,
    cli: SourceAcceptanceCli,
) !void {
    try validateCanonicalAbsolute(cli.repository);
    const expected_contract = try joinAbsolute(allocator, cli.repository, contract_source_relative);
    defer allocator.free(expected_contract);
    const expected_runner = try joinAbsolute(allocator, cli.repository, runner_source_relative);
    defer allocator.free(expected_runner);
    const expected_output_relative = source_acceptance_directory_relative ++ "/" ++ source_acceptance_name;
    const expected_output = try joinAbsolute(allocator, cli.repository, expected_output_relative);
    defer allocator.free(expected_output);
    if (!std.mem.eql(u8, cli.contract_source, expected_contract) or
        !std.mem.eql(u8, cli.runner_source, expected_runner) or
        !std.mem.eql(u8, cli.output_path, expected_output))
    {
        return error.PathEscape;
    }
}

fn requireExpectedParent(actual: [40]u8, expected: [40]u8) RunnerError!void {
    if (!std.mem.eql(u8, &actual, &expected)) return error.ParentIdentityMismatch;
}

fn requireSourceAcceptanceSnapshotStable(
    expected: SourceAcceptanceSnapshot,
    current: SourceAcceptanceSnapshot,
) RunnerError!void {
    if (!std.meta.eql(expected, current)) return error.StagedSourceMismatch;
}

fn observeSourceAcceptanceSnapshot(
    allocator: std.mem.Allocator,
    io: std.Io,
    git: AuthenticatedSubject,
    cli: SourceAcceptanceCli,
) !SourceAcceptanceSnapshot {
    const parent_result = try runGitObservation(
        allocator,
        io,
        git,
        cli.repository,
        &.{ "rev-parse", "HEAD" },
        &.{},
    );
    defer allocator.free(parent_result.stdout);
    defer allocator.free(parent_result.stderr);
    if (parent_result.stderr.len != 0) return error.GitObservationMismatch;
    const parent = try parseSha1Line(parent_result.stdout);
    try requireExpectedParent(parent, cli.expected_parent);

    const index_result = try runGitObservation(
        allocator,
        io,
        git,
        cli.repository,
        &.{ "diff", "--cached", "--raw", "-z", "--no-abbrev", "--no-renames" },
        &.{},
    );
    defer allocator.free(index_result.stdout);
    defer allocator.free(index_result.stderr);
    if (index_result.stderr.len != 0) return error.GitObservationMismatch;
    const staged = try parseExactCyStagedSet(index_result.stdout);
    return .{
        .parent = parent,
        .contract_source = try observeStagedSource(
            allocator,
            io,
            cli.contract_source,
            staged.contract_source,
        ),
        .runner_source = try observeStagedSource(
            allocator,
            io,
            cli.runner_source,
            staged.runner_source,
        ),
    };
}

fn observeRepository(
    allocator: std.mem.Allocator,
    io: std.Io,
    git: AuthenticatedSubject,
    repository: []const u8,
    registered_worktrees: []const []const u8,
) !RepositoryObservation {
    _ = try validateExplicitPath(io, repository, .directory, registered_worktrees);
    const head = try runGitObservation(
        allocator,
        io,
        git,
        repository,
        &.{ "rev-parse", "HEAD" },
        registered_worktrees,
    );
    defer allocator.free(head.stdout);
    defer allocator.free(head.stderr);
    if (head.stderr.len != 0) return error.GitObservationMismatch;
    const tree = try runGitObservation(
        allocator,
        io,
        git,
        repository,
        &.{ "rev-parse", "HEAD^{tree}" },
        registered_worktrees,
    );
    defer allocator.free(tree.stdout);
    defer allocator.free(tree.stderr);
    if (tree.stderr.len != 0) return error.GitObservationMismatch;
    const status = try runGitObservation(
        allocator,
        io,
        git,
        repository,
        &.{ "status", "--porcelain=v1", "-z", "--untracked-files=all" },
        registered_worktrees,
    );
    defer allocator.free(status.stdout);
    defer allocator.free(status.stderr);
    if (status.stderr.len != 0) return error.GitObservationMismatch;
    return .{
        .head = try parseSha1Line(head.stdout),
        .tree = try parseSha1Line(tree.stdout),
        .status = sha256(status.stdout),
        .clean = status.stdout.len == 0,
    };
}

fn observeRepositoryStatus(
    allocator: std.mem.Allocator,
    io: std.Io,
    git: AuthenticatedSubject,
    repository: []const u8,
    registered_worktrees: []const []const u8,
) !std.process.RunResult {
    return runGitObservation(
        allocator,
        io,
        git,
        repository,
        &.{ "status", "--porcelain=v1", "-z", "--untracked-files=all" },
        registered_worktrees,
    );
}

fn validateRelativeManifestPath(path: []const u8) RunnerError!void {
    if (path.len == 0 or std.fs.path.isAbsolute(path) or
        std.mem.indexOfScalar(u8, path, 0) != null)
    {
        return error.ManifestMismatch;
    }
    var components = std.mem.splitScalar(u8, path, '/');
    while (components.next()) |component| {
        if (component.len == 0 or std.mem.eql(u8, component, ".") or
            std.mem.eql(u8, component, "..")) return error.ManifestMismatch;
    }
}

fn touchedPathCount(touched: []const u8, wanted: []const u8) RunnerError!usize {
    var count: usize = 0;
    var lines = std.mem.splitScalar(u8, touched, '\n');
    var previous: ?[]const u8 = null;
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        try validateRelativeManifestPath(line);
        if (previous) |prior| if (std.mem.order(u8, prior, line) != .lt)
            return error.ManifestMismatch;
        previous = line;
        if (std.mem.eql(u8, line, wanted)) count += 1;
    }
    return count;
}

fn validateCoverageStatus(status: []const u8, touched: []const u8) RunnerError!void {
    var status_count: usize = 0;
    var records = std.mem.splitScalar(u8, status, 0);
    while (records.next()) |record| {
        if (record.len == 0) continue;
        if (record.len < 4 or record[2] != ' ' or
            record[0] == 'R' or record[1] == 'R' or
            record[0] == 'C' or record[1] == 'C')
        {
            return error.GitObservationMismatch;
        }
        const path = record[3..];
        try validateRelativeManifestPath(path);
        if (try touchedPathCount(touched, path) != 1) return error.GitObservationMismatch;
        status_count += 1;
    }
    var touched_count: usize = 0;
    var lines = std.mem.splitScalar(u8, touched, '\n');
    while (lines.next()) |line| if (line.len != 0) {
        try validateRelativeManifestPath(line);
        touched_count += 1;
    };
    if (status_count == 0 or status_count != touched_count) return error.GitObservationMismatch;
}

fn requireAbsentAbsolute(io: std.Io, absolute_path: []const u8) !void {
    try validateCanonicalAbsolute(absolute_path);
    _ = std.Io.Dir.cwd().statFile(io, absolute_path, .{ .follow_symlinks = false }) catch |failure| switch (failure) {
        error.FileNotFound => return,
        else => return failure,
    };
    return error.ValidationRootCollision;
}

fn createValidationRoot(
    allocator: std.mem.Allocator,
    io: std.Io,
    repository: []const u8,
    validation_root: []const u8,
) !std.Io.Dir {
    const expected = try joinAbsolute(allocator, repository, contract.plannedPath(.validation_root));
    defer allocator.free(expected);
    if (!std.mem.eql(u8, expected, validation_root)) return error.PathEscape;
    try requireAbsentAbsolute(io, validation_root);
    const relative = validation_root[repository.len + 1 ..];
    var created = try createRelativeTreeNoFollow(io, repository, relative);
    created.close(io);
    return std.Io.Dir.openDirAbsolute(io, validation_root, .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    });
}

fn writeExclusiveAbsolute(
    io: std.Io,
    path: []const u8,
    bytes: []const u8,
    mode: u32,
) !FileIdentity {
    var file = try std.Io.Dir.createFileAbsolute(io, path, .{
        .read = true,
        .exclusive = true,
        .truncate = false,
        .permissions = .fromMode(mode),
    });
    defer file.close(io);
    try file.writeStreamingAll(io, bytes);
    try file.sync(io);
    const stat = try file.stat(io);
    if (stat.size != bytes.len) return error.InputIdentityMismatch;
    return .{
        .bytes = stat.size,
        .mode = @intCast(stat.permissions.toMode() & 0o7777),
        .inode = stat.inode,
        .sha256 = sha256(bytes),
    };
}

fn readBoundedAbsolute(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
    maximum: usize,
) ![]u8 {
    var file = try std.Io.Dir.openFileAbsolute(io, path, .{
        .mode = .read_only,
        .follow_symlinks = false,
    });
    defer file.close(io);
    const stat = try file.stat(io);
    if (stat.kind != .file or stat.size > maximum) return error.FileCapExceeded;
    const bytes = try allocator.alloc(u8, @intCast(stat.size));
    errdefer allocator.free(bytes);
    if (try file.readPositionalAll(io, bytes, 0) != bytes.len) return error.IncompleteCapture;
    var trailing: [1]u8 = undefined;
    if (try file.readPositionalAll(io, &trailing, bytes.len) != 0) return error.IncompleteCapture;
    return bytes;
}

fn ensureRelativeDirectory(root: std.Io.Dir, io: std.Io, relative: []const u8) !void {
    if (relative.len == 0 or std.fs.path.isAbsolute(relative)) return error.PathEscape;
    try root.createDirPath(io, relative);
}

fn writeValidationFile(
    allocator: std.mem.Allocator,
    io: std.Io,
    root_path: []const u8,
    relative: []const u8,
    bytes: []const u8,
    family: contract.StorageFamily,
    usage: *[contract.storage_families.len]FamilyUsage,
) !FileIdentity {
    try accountFamilyBytes(usage, family, bytes.len);
    const path = try joinAbsolute(allocator, root_path, relative);
    defer allocator.free(path);
    return writeExclusiveAbsolute(io, path, bytes, 0o444);
}

fn recordProcessResult(
    allocator: std.mem.Allocator,
    io: std.Io,
    root_path: []const u8,
    prefix: []const u8,
    result: std.process.RunResult,
    family: contract.StorageFamily,
    usage: *[contract.storage_families.len]FamilyUsage,
) !void {
    const stdout_name = try std.fmt.allocPrint(allocator, "{s}.stdout.raw", .{prefix});
    defer allocator.free(stdout_name);
    const stderr_name = try std.fmt.allocPrint(allocator, "{s}.stderr.raw", .{prefix});
    defer allocator.free(stderr_name);
    const status_name = try std.fmt.allocPrint(allocator, "{s}.status", .{prefix});
    defer allocator.free(status_name);
    var status_buffer: [16]u8 = undefined;
    const status = switch (result.term) {
        .exited => |code| try std.fmt.bufPrint(&status_buffer, "{d}\n", .{code}),
        else => return error.ChildFailed,
    };
    _ = try writeValidationFile(allocator, io, root_path, stdout_name, result.stdout, family, usage);
    _ = try writeValidationFile(allocator, io, root_path, stderr_name, result.stderr, family, usage);
    _ = try writeValidationFile(allocator, io, root_path, status_name, status, family, usage);
}

fn authenticateSubjects(io: std.Io, cli: Cli) !SubjectSet {
    return .{
        .zig = try authenticateSubject(io, cli.zig, cli.registered_worktrees),
        .git = try authenticateSubject(io, cli.git, cli.registered_worktrees),
        .llvm_extract = try authenticateSubject(io, cli.llvm_extract, cli.registered_worktrees),
        .objcopy = try authenticateSubject(io, cli.objcopy, cli.registered_worktrees),
        .objdump = try authenticateSubject(io, cli.objdump, cli.registered_worktrees),
        .readelf = try authenticateSubject(io, cli.readelf, cli.registered_worktrees),
    };
}

fn authenticateInputs(
    allocator: std.mem.Allocator,
    io: std.Io,
    cli: Cli,
) !InputSet {
    const bundle_manifest = try joinAbsolute(allocator, cli.bundle_root, "manifests/bundle-files.sha256");
    defer allocator.free(bundle_manifest);
    const combined_patch = try joinAbsolute(allocator, cli.bundle_root, "patches/aggregate-consumer-observer-guard.patch");
    defer allocator.free(combined_patch);
    return .{
        .raw = try authenticateFile(io, cli.raw_input, .{
            .bytes = 1_897_410,
            .sha256_hex = "9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1",
        }, maximum_input_bytes, cli.registered_worktrees),
        .adoption = try authenticateFile(io, cli.adoption_manifest, .{
            .bytes = 4_394,
            .sha256_hex = "500e73c8433aa73159adfba5de8a6708ae4030140b97b823ef895caa1528f2bf",
        }, maximum_input_bytes, cli.registered_worktrees),
        .bundle_manifest = try authenticateFile(io, bundle_manifest, .{
            .bytes = 2_519,
            .sha256_hex = "0576d5803400ea9575d65fc501b87d514c97e806540be29018fb5192bd68e7f0",
        }, maximum_input_bytes, cli.registered_worktrees),
        .combined_patch = try authenticateFile(io, combined_patch, .{
            .bytes = 41_140,
            .sha256_hex = "7508d1d8f74b7e9b97ae5722a0822a86c8d2079779a25cd37559ce5bc651036f",
        }, maximum_input_bytes, cli.registered_worktrees),
        .reproduction = try authenticateFile(io, cli.reproduction_manifest, .{
            .bytes = 458_294,
            .sha256_hex = "885008980c8a272e82d06cf89b81652ab5a9669e89364b01d7b9e2761135ff1e",
        }, maximum_input_bytes, cli.registered_worktrees),
        .retention_pins = try authenticateFile(io, cli.retention_pins, .{
            .bytes = 3_051,
            .sha256_hex = "1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3",
        }, maximum_input_bytes, cli.registered_worktrees),
        .retention_policy = try authenticateFile(io, cli.retention_policy, .{
            .bytes = 10_622,
            .sha256_hex = "a31e3fbf7aa03c8544fc5f9921e350c25e4e470cc3c779dfb356136634e052dd",
        }, maximum_input_bytes, cli.registered_worktrees),
        .cleanup_source = try authenticateFile(io, cli.cleanup_source, .{
            .bytes = 50_100,
            .sha256_hex = "8e0c54ad6fed9e46326049dbe64bff743daddcc2527c1dc4d5e02be15fba2d5e",
        }, maximum_input_bytes, cli.registered_worktrees),
        .bypass_inventory = try authenticateFile(io, cli.bypass_inventory, .{
            .bytes = 5_188,
            .sha256_hex = "2d6c8c8819c4b0dff10b9d803a62125d7c46155c04a2c2cf2006f2aecffd8b11",
        }, maximum_input_bytes, cli.registered_worktrees),
        .facade_manifest = try authenticateFile(io, cli.facade_manifest, .{
            .bytes = 2_686,
            .sha256_hex = "2adcd99ee3bfbe0e9f09673f1df02ab305b5ddb2c1b461023152d5d03a079c26",
        }, maximum_input_bytes, cli.registered_worktrees),
        .facade_source = try authenticateFile(io, cli.facade_source, .{
            .bytes = 103,
            .sha256_hex = "4f5887e9d2bce0943df26c1e08e8360053440da64eefd19ddfd9d53225dddd7a",
        }, maximum_input_bytes, cli.registered_worktrees),
        .external_stage4 = try authenticateFile(io, cli.external_stage4, .{
            .bytes = 530_327_885,
            .sha256_hex = "dcea3478273d7ffe3895709c8eed4ccc0724548869cdb86183fc7356164410b7",
            .executable = true,
        }, maximum_artifact_bytes, cli.registered_worktrees),
    };
}

fn validateStorageRoot(
    entries: []const FamilyUsage,
    available_bytes: u64,
) (RunnerError || contract.ContractError)!FamilyTracker {
    _ = try contract.acceptedStorageBudgetTotals(available_bytes);
    var tracker = FamilyTracker{};
    for (entries) |usage| try tracker.close(usage);
    try tracker.finish();
    return tracker;
}

fn requireRestorationEqual(before: RestorationIdentity, after: RestorationIdentity) RunnerError!void {
    if (!std.meta.eql(before, after)) return error.RestorationMismatch;
}

fn validateCompletedPhases(phases: contract.PhaseMachine) RunnerError!void {
    if (phases.first_failure != null or phases.next != phases.statuses.len)
        return error.ClosurePrecondition;
    for (phases.statuses) |status| if (status != .succeeded)
        return error.ClosurePrecondition;
}

fn validateCompleteRun(observation: CompleteRunObservation) !ValidatedRun {
    try contract.validateIdentities(observation.identities);
    try contract.validateCompatibilityKeys(observation.compatibility_keys);
    try contract.validateCanonicalRepetitions(observation.repetitions);
    try contract.validateCoverage(observation.coverage);
    try contract.validateRestoration(observation.restoration);
    try contract.validateSemanticEquality(observation.semantic_equality);
    try validateCompletedPhases(observation.phases);
    const tracker = try validateStorageRoot(observation.family_usage, observation.available_bytes);
    try requireRestorationEqual(observation.before, observation.after);
    return .{
        .retained_bytes = tracker.total_retained_bytes,
        .before = observation.before,
        .after = observation.after,
        .available_bytes = observation.available_bytes,
    };
}

fn encodeClosure(
    allocator: std.mem.Allocator,
    validated: ValidatedRun,
    binding: ClosureBinding,
) ![]u8 {
    const families = try contract.acceptedEnforcedStorageFamilies();
    const storage = completeEnforcementEvidence(&families, validated.available_bytes);
    try contract.validateCompleteEnforcementEvidence(storage);
    try requireRestorationEqual(validated.before, validated.after);
    try validateToolBindings(binding.tools);
    if (!binding.completion or
        binding.registered_worktrees.count != accepted_registered_worktree_count or
        binding.canonical_artifact.bytes == 0 or binding.coverage_artifact.bytes == 0)
    {
        return error.ClosurePrecondition;
    }

    var output: std.Io.Writer.Allocating = .init(allocator);
    errdefer output.deinit();
    try output.writer.print(
        "schema\t{s}\nreadiness\tready\nretained_bytes\t{d}\navailable_bytes\t{d}\nmaximum_bytes\t{d}\nreserve_bytes\t{d}\nidentities\t{d}\ncompatibility_keys\t{d}\nrepetitions\t{d}\nfunctions\t{d}\nphases\t{d}\n",
        .{
            schema,
            validated.retained_bytes,
            validated.available_bytes,
            contract.accepted_maximum_storage_bytes,
            contract.accepted_storage_reserve_bytes,
            storage.identity_count,
            storage.compatibility_key_count,
            storage.repetition_count,
            storage.successful_functions,
            storage.phase_count,
        },
    );
    for (orderedTools(binding.tools)) |tool| {
        const portable = tool.portable_tool orelse return error.SubjectAuthorityMismatch;
        const digest_hex = std.fmt.bytesToHex(portable.sha256, .lower);
        try output.writer.print(
            "tool\t{s}\t{d}\t{s}\t{s}\n",
            .{
                toolRoleName(portable.role),
                portable.bytes,
                &digest_hex,
                portable.version orelse "-",
            },
        );
    }
    const source_hex = std.fmt.bytesToHex(binding.fixed_sources, .lower);
    const input_hex = std.fmt.bytesToHex(binding.fixed_inputs, .lower);
    const canonical_artifact_hex = std.fmt.bytesToHex(binding.canonical_artifact.sha256, .lower);
    const coverage_artifact_hex = std.fmt.bytesToHex(binding.coverage_artifact.sha256, .lower);
    const canonical_observations_hex = std.fmt.bytesToHex(binding.canonical_observations, .lower);
    const coverage_off_hex = std.fmt.bytesToHex(binding.coverage_off_observation, .lower);
    const coverage_on_hex = std.fmt.bytesToHex(binding.coverage_on_observation, .lower);
    const counter_hex = std.fmt.bytesToHex(binding.counter_result, .lower);
    const worktree_hex = std.fmt.bytesToHex(binding.registered_worktrees.sha256, .lower);
    const family_usage_hex = std.fmt.bytesToHex(binding.family_usage, .lower);
    const repository_before_hex = std.fmt.bytesToHex(validated.before.repository, .lower);
    const canonical_before_hex = std.fmt.bytesToHex(validated.before.canonical_source, .lower);
    const coverage_before_hex = std.fmt.bytesToHex(validated.before.coverage_source, .lower);
    const accepted_before_hex = std.fmt.bytesToHex(validated.before.accepted_input, .lower);
    const repository_after_hex = std.fmt.bytesToHex(validated.after.repository, .lower);
    const canonical_after_hex = std.fmt.bytesToHex(validated.after.canonical_source, .lower);
    const coverage_after_hex = std.fmt.bytesToHex(validated.after.coverage_source, .lower);
    const accepted_after_hex = std.fmt.bytesToHex(validated.after.accepted_input, .lower);
    try output.writer.print(
        "fixed_sources_sha256\t{s}\nfixed_inputs_sha256\t{s}\n" ++
            "canonical_artifact\t{d}\t{o}\t{s}\ncoverage_artifact\t{d}\t{o}\t{s}\n" ++
            "canonical_observations_sha256\t{s}\ncoverage_off_observation_sha256\t{s}\n" ++
            "coverage_on_observation_sha256\t{s}\ncounter_result_sha256\t{s}\n" ++
            "registered_worktrees\t{d}\t{s}\nfamily_usage_sha256\t{s}\n" ++
            "restoration_before\t{s}\t{s}\t{s}\t{s}\n" ++
            "restoration_after\t{s}\t{s}\t{s}\t{s}\ncompletion\tcomplete\n",
        .{
            &source_hex,
            &input_hex,
            binding.canonical_artifact.bytes,
            binding.canonical_artifact.mode,
            &canonical_artifact_hex,
            binding.coverage_artifact.bytes,
            binding.coverage_artifact.mode,
            &coverage_artifact_hex,
            &canonical_observations_hex,
            &coverage_off_hex,
            &coverage_on_hex,
            &counter_hex,
            binding.registered_worktrees.count,
            &worktree_hex,
            &family_usage_hex,
            &repository_before_hex,
            &canonical_before_hex,
            &coverage_before_hex,
            &accepted_before_hex,
            &repository_after_hex,
            &canonical_after_hex,
            &coverage_after_hex,
            &accepted_after_hex,
        },
    );
    if (output.writer.end > closure_max) {
        output.deinit();
        return error.ClosureTooLarge;
    }
    return output.toOwnedSlice();
}

fn completeEnforcementEvidence(
    families: []const contract.EnforcedStorageFamily,
    available_bytes: u64,
) contract.CompleteEnforcementEvidence {
    return .{
        .prerequisites = &contract.required_enforcement_prerequisites,
        .storage_families = families,
        .available_bytes = available_bytes,
        .identity_count = contract.closed_identities.len,
        .compatibility_key_count = contract.compatibility_keys.len,
        .v3_path_count = @typeInfo(contract.V3Path).@"enum".fields.len,
        .repetition_count = contract.canonical_repetition_count,
        .successful_functions = contract.successful_function_count,
        .phase_count = @typeInfo(contract.Phase).@"enum".fields.len,
        .stdout_capture_bytes = process_capture_max,
        .stderr_capture_bytes = process_capture_max,
    };
}

fn verifyClosureReadBack(expected: []const u8, actual: []const u8) RunnerError!void {
    if (!std.mem.eql(u8, expected, actual)) return error.ClosureReadBackMismatch;
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

fn publishClosure(
    allocator: std.mem.Allocator,
    directory: std.Io.Dir,
    io: std.Io,
    encoded: []const u8,
) !PublishedClosure {
    if (encoded.len == 0 or encoded.len > closure_max) return error.ClosureTooLarge;
    var temporary = directory.createFile(io, closure_temporary_name, .{
        .read = false,
        .truncate = false,
        .exclusive = true,
        .resolve_beneath = true,
    }) catch |failure| switch (failure) {
        error.PathAlreadyExists => return error.ClosureCollision,
        else => return failure,
    };
    var temporary_open = true;
    var temporary_exists = true;
    var final_published = false;
    defer if (temporary_open) temporary.close(io);
    errdefer {
        if (temporary_exists) {
            directory.deleteFile(io, closure_temporary_name) catch {};
        } else if (final_published) {
            directory.deleteFile(io, closure_name) catch {};
            syncOwnedDirectory(directory, io) catch {};
        }
    }
    try temporary.writeStreamingAll(io, encoded);
    try temporary.sync(io);
    temporary.close(io);
    temporary_open = false;
    directory.renamePreserve(closure_temporary_name, directory, closure_name, io) catch |failure| switch (failure) {
        error.PathAlreadyExists => return error.ClosureCollision,
        else => return failure,
    };
    temporary_exists = false;
    final_published = true;
    try syncOwnedDirectory(directory, io);

    const final = try directory.openFile(io, closure_name, .{
        .mode = .read_only,
        .follow_symlinks = false,
        .resolve_beneath = true,
    });
    defer final.close(io);
    const read_back = try allocator.alloc(u8, encoded.len);
    defer allocator.free(read_back);
    const count = try final.readPositionalAll(io, read_back, 0);
    if (count != encoded.len) return error.ClosureReadBackMismatch;
    var trailing: [1]u8 = undefined;
    if (try final.readPositionalAll(io, &trailing, encoded.len) != 0)
        return error.ClosureReadBackMismatch;
    try verifyClosureReadBack(encoded, read_back);
    return .{ .bytes = @intCast(encoded.len), .sha256 = sha256(encoded) };
}

fn sha256(bytes: []const u8) contract.Digest {
    var digest: contract.Digest = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes, &digest, .{});
    return digest;
}

fn hashU64(hasher: *std.crypto.hash.sha2.Sha256, value: u64) void {
    var encoded: [8]u8 = undefined;
    std.mem.writeInt(u64, &encoded, value, .little);
    hasher.update(&encoded);
}

fn hashBool(hasher: *std.crypto.hash.sha2.Sha256, value: bool) void {
    hasher.update(if (value) "\x01" else "\x00");
}

fn hashBoundedBytes(hasher: *std.crypto.hash.sha2.Sha256, bytes: []const u8) void {
    hashU64(hasher, bytes.len);
    hasher.update(bytes);
}

fn hashFileIdentity(hasher: *std.crypto.hash.sha2.Sha256, identity: FileIdentity) void {
    hashU64(hasher, identity.bytes);
    hashU64(hasher, identity.mode);
    hasher.update(&identity.sha256);
}

fn finishDigest(hasher: *std.crypto.hash.sha2.Sha256) contract.Digest {
    var result: contract.Digest = undefined;
    hasher.final(&result);
    return result;
}

fn digestInputSet(inputs: InputSet) contract.Digest {
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    inline for (std.meta.fields(InputSet)) |field| {
        hashBoundedBytes(&hasher, field.name);
        hashFileIdentity(&hasher, @field(inputs, field.name));
    }
    return finishDigest(&hasher);
}

fn hashRepositoryObservation(
    hasher: *std.crypto.hash.sha2.Sha256,
    observation: RepositoryObservation,
) void {
    hasher.update(&observation.head);
    hasher.update(&observation.tree);
    hasher.update(&observation.status);
    hashBool(hasher, observation.clean);
}

fn digestSourceIdentityBinding(binding: SourceIdentityBinding) contract.Digest {
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    hashRepositoryObservation(&hasher, binding.repository);
    hashRepositoryObservation(&hasher, binding.external_zig);
    hashRepositoryObservation(&hasher, binding.canonical);
    hashRepositoryObservation(&hasher, binding.coverage);
    hasher.update(&binding.canonical_manifest);
    hasher.update(&binding.coverage_manifest);
    return finishDigest(&hasher);
}

fn digestCanonicalObservations(
    repetitions: []const contract.CanonicalRepetition,
) contract.Digest {
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    hashU64(&hasher, repetitions.len);
    for (repetitions) |repetition| {
        hasher.update(&repetition.report);
        hasher.update(&repetition.object);
        hasher.update(&repetition.owner);
        hasher.update(&repetition.function_manifest);
        hashU64(&hasher, repetition.function_count);
        hashBool(&hasher, repetition.accepted_subset_produced);
    }
    return finishDigest(&hasher);
}

fn digestObservationIdentity(observation: ObservationResult) contract.Digest {
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    hasher.update(&observation.semantic.report);
    hasher.update(&observation.semantic.object);
    hasher.update(&observation.semantic.owner);
    hasher.update(&observation.function_manifest);
    return finishDigest(&hasher);
}

fn hashFamilyCounters(
    hasher: *std.crypto.hash.sha2.Sha256,
    counters: contract.FamilyCounters,
) void {
    hashU64(hasher, counters.transactions);
    hashU64(hasher, counters.requests);
    hashU64(hasher, counters.attachments);
    hashU64(hasher, counters.stages);
    hashU64(hasher, counters.materializations);
    hashU64(hasher, counters.actions);
    hashU64(hasher, counters.commits);
    for (counters.position_requests) |value| hashU64(hasher, value);
    for (counters.position_stages) |value| hashU64(hasher, value);
}

fn hashFamilyPair(
    hasher: *std.crypto.hash.sha2.Sha256,
    pair: contract.FamilyPair,
) void {
    hashFamilyCounters(hasher, pair.direct_call);
    hashFamilyCounters(hasher, pair.int_byte_size_call);
}

fn digestCoverageResult(coverage: contract.CoverageState) contract.Digest {
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    inline for (std.meta.fields(@TypeOf(coverage.observation_off))) |field| {
        hashBool(&hasher, @field(coverage.observation_off, field.name));
    }
    inline for (std.meta.fields(@TypeOf(coverage.observation_on))) |field| {
        hashBool(&hasher, @field(coverage.observation_on, field.name));
    }
    for (coverage.on_channel_producers) |value| hashU64(&hasher, value);
    hashU64(&hasher, coverage.unexpected_family_events);
    hashU64(&hasher, coverage.argument_index_overflow_events);
    hashFamilyPair(&hasher, coverage.report);
    hashFamilyPair(&hasher, coverage.object);
    hashFamilyPair(&hasher, coverage.owner);
    return finishDigest(&hasher);
}

fn digestFamilyUsage(usage: []const FamilyUsage) contract.Digest {
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    hashU64(&hasher, usage.len);
    for (usage) |row| {
        hashU64(&hasher, row.family_id);
        hashU64(&hasher, row.retained_bytes);
        hashU64(&hasher, row.largest_file_bytes);
        hashU64(&hasher, row.root_bytes);
        hashU64(&hasher, row.aggregate_exclusions);
    }
    return finishDigest(&hasher);
}

fn orderedTools(subjects: SubjectSet) [6]AuthenticatedSubject {
    return .{
        subjects.zig,
        subjects.git,
        subjects.llvm_extract,
        subjects.objcopy,
        subjects.objdump,
        subjects.readelf,
    };
}

fn validateToolBindings(subjects: SubjectSet) RunnerError!void {
    const tools = orderedTools(subjects);
    const roles = [_]ToolRole{ .zig, .git, .llvm_extract, .objcopy, .objdump, .readelf };
    for (tools, roles) |tool, role| {
        const portable = tool.portable_tool orelse return error.SubjectAuthorityMismatch;
        if (portable.role != role or portable.bytes != tool.identity.bytes or
            !std.mem.eql(u8, &portable.sha256, &tool.identity.sha256))
        {
            return error.SubjectAuthorityMismatch;
        }
        if ((role == .zig) != (portable.version != null))
            return error.SubjectAuthorityMismatch;
        if (portable.version) |version| {
            if (!std.mem.eql(u8, version, expected_zig_version))
                return error.SubjectAuthorityMismatch;
        }
    }
}

fn syntheticFamilyUsage() [contract.storage_families.len]FamilyUsage {
    var result: [contract.storage_families.len]FamilyUsage = undefined;
    for (&result, contract.accepted_storage_policy, 0..) |*usage, policy, index| {
        usage.* = .{
            .family_id = @intCast(index + 1),
            .retained_bytes = if (index == 1) 0 else 1,
            .largest_file_bytes = if (index == 1) 0 else 1,
            .root_bytes = if (index == 1) 0 else 1,
            .aggregate_exclusions = policy.aggregate_exclusions,
        };
    }
    return result;
}

fn syntheticCompleteEvidence(
    families: []const contract.EnforcedStorageFamily,
) contract.CompleteEnforcementEvidence {
    return syntheticCompleteEvidenceForCapacity(families, contract.minimum_available_bytes);
}

fn syntheticCompleteEvidenceForCapacity(
    families: []const contract.EnforcedStorageFamily,
    available_bytes: u64,
) contract.CompleteEnforcementEvidence {
    return .{
        .prerequisites = &contract.required_enforcement_prerequisites,
        .storage_families = families,
        .available_bytes = available_bytes,
        .identity_count = contract.closed_identities.len,
        .compatibility_key_count = contract.compatibility_keys.len,
        .v3_path_count = @typeInfo(contract.V3Path).@"enum".fields.len,
        .repetition_count = contract.canonical_repetition_count,
        .successful_functions = contract.successful_function_count,
        .phase_count = @typeInfo(contract.Phase).@"enum".fields.len,
        .stdout_capture_bytes = process_capture_max,
        .stderr_capture_bytes = process_capture_max,
    };
}

fn syntheticRestoration(byte: u8) RestorationIdentity {
    return .{
        .repository = [_]u8{byte} ** 32,
        .canonical_source = [_]u8{byte +% 1} ** 32,
        .coverage_source = [_]u8{byte +% 2} ** 32,
        .accepted_input = [_]u8{byte +% 3} ** 32,
    };
}

fn syntheticTool(role: ToolRole, byte: u8) AuthenticatedSubject {
    const digest = [_]u8{byte} ** 32;
    const version: ?[]const u8 = if (role == .zig) expected_zig_version else null;
    return .{
        .path = "/synthetic/tool",
        .identity = .{
            .bytes = byte,
            .mode = 0o755,
            .inode = byte,
            .sha256 = digest,
        },
        .portable_tool = .{
            .role = role,
            .bytes = byte,
            .sha256 = digest,
            .version = version,
        },
    };
}

fn syntheticSubjectSet() SubjectSet {
    return .{
        .zig = syntheticTool(.zig, 1),
        .git = syntheticTool(.git, 2),
        .llvm_extract = syntheticTool(.llvm_extract, 3),
        .objcopy = syntheticTool(.objcopy, 4),
        .objdump = syntheticTool(.objdump, 5),
        .readelf = syntheticTool(.readelf, 6),
    };
}

fn syntheticClosureBinding() ClosureBinding {
    return .{
        .tools = syntheticSubjectSet(),
        .fixed_sources = [_]u8{0x71} ** 32,
        .fixed_inputs = [_]u8{0x72} ** 32,
        .canonical_artifact = .{
            .bytes = 101,
            .mode = 0o755,
            .inode = 101,
            .sha256 = [_]u8{0x73} ** 32,
        },
        .coverage_artifact = .{
            .bytes = 102,
            .mode = 0o755,
            .inode = 102,
            .sha256 = [_]u8{0x74} ** 32,
        },
        .canonical_observations = [_]u8{0x75} ** 32,
        .coverage_off_observation = [_]u8{0x76} ** 32,
        .coverage_on_observation = [_]u8{0x77} ** 32,
        .counter_result = [_]u8{0x78} ** 32,
        .registered_worktrees = .{
            .count = accepted_registered_worktree_count,
            .sha256 = [_]u8{0x79} ** 32,
        },
        .family_usage = [_]u8{0x7a} ** 32,
        .completion = true,
    };
}

fn syntheticStagedSource(byte: u8) StagedSourceIdentity {
    return .{
        .mode = 0o100644,
        .bytes = byte,
        .blob = [_]u8{byte} ** 20,
        .raw_sha256 = [_]u8{byte +% 1} ** 32,
        .worktree_inode = byte,
    };
}

fn syntheticSourceAcceptanceEvidence() SourceAcceptanceEvidence {
    var gates: [@typeInfo(SourceAcceptanceGate).@"enum".fields.len]SourceAcceptanceGateResult = undefined;
    for (&gates, 0..) |*gate, index| {
        gate.* = .{
            .gate = @enumFromInt(index + 1),
            .exit_status = 0,
            .stdout_bytes = index,
            .stdout_sha256 = [_]u8{@intCast(index + 1)} ** 32,
            .stderr_bytes = index + 1,
            .stderr_sha256 = [_]u8{@intCast(index + 2)} ** 32,
        };
    }
    return .{
        .snapshot = .{
            .parent = [_]u8{'1'} ** 40,
            .contract_source = syntheticStagedSource(0x21),
            .runner_source = syntheticStagedSource(0x31),
        },
        .tools = .{
            .zig = syntheticTool(.zig, 1),
            .git = syntheticTool(.git, 2),
        },
        .gates = gates,
        .completion = true,
    };
}

fn encodeSyntheticCyIndex(
    allocator: std.mem.Allocator,
    contract_path: []const u8,
    runner_path: ?[]const u8,
    new_mode: []const u8,
    extra_path: ?[]const u8,
) ![]u8 {
    var output: std.Io.Writer.Allocating = .init(allocator);
    errdefer output.deinit();
    try output.writer.print(":100644 {s} {s} {s} M\x00{s}\x00", .{
        new_mode,
        "4" ** 40,
        "1" ** 40,
        contract_path,
    });
    if (runner_path) |path| {
        try output.writer.print(":000000 100644 {s} {s} A\x00{s}\x00", .{
            "0" ** 40,
            "2" ** 40,
            path,
        });
    }
    if (extra_path) |path| {
        try output.writer.print(":100644 100644 {s} {s} M\x00{s}\x00", .{
            "4" ** 40,
            "3" ** 40,
            path,
        });
    }
    return output.toOwnedSlice();
}

fn syntheticWorktreePaths(
    storage: *[accepted_registered_worktree_count][64]u8,
) ![accepted_registered_worktree_count][]const u8 {
    var paths: [accepted_registered_worktree_count][]const u8 = undefined;
    for (&paths, storage, 0..) |*path, *buffer, index| {
        path.* = try std.fmt.bufPrint(buffer, "/synthetic/registered/worktree-{d}", .{index});
    }
    return paths;
}

fn encodeSyntheticWorktreeMetadata(
    allocator: std.mem.Allocator,
    paths: []const []const u8,
) ![]u8 {
    var output: std.Io.Writer.Allocating = .init(allocator);
    errdefer output.deinit();
    for (paths, 0..) |path, index| {
        try output.writer.print(
            "worktree {s}\x00HEAD {s}\x00branch refs/heads/synthetic-{d}\x00\x00",
            .{ path, "0" ** 40, index },
        );
    }
    return output.toOwnedSlice();
}

fn syntheticCanonicalRepetitions() [contract.canonical_repetition_count]contract.CanonicalRepetition {
    const identity = contract.CanonicalRepetition{
        .report = [_]u8{0x11} ** 32,
        .object = [_]u8{0x12} ** 32,
        .owner = [_]u8{0x13} ** 32,
        .function_manifest = [_]u8{0x14} ** 32,
        .function_count = contract.successful_function_count,
        .accepted_subset_produced = false,
    };
    var repetitions = [_]contract.CanonicalRepetition{identity} ** contract.canonical_repetition_count;
    repetitions[0].accepted_subset_produced = true;
    return repetitions;
}

fn syntheticFamilyCounters(family: contract.Family) contract.FamilyCounters {
    return switch (family) {
        .direct_call => .{
            .transactions = 2,
            .requests = 3,
            .attachments = 2,
            .stages = 3,
            .materializations = 2,
            .actions = 2,
            .commits = 2,
            .position_requests = .{ 2, 1, 0, 0, 0, 0 },
            .position_stages = .{ 2, 1, 0, 0, 0, 0 },
        },
        .int_byte_size_call => .{
            .transactions = 2,
            .requests = 2,
            .attachments = 2,
            .stages = 2,
            .materializations = 2,
            .actions = 2,
            .commits = 2,
            .position_requests = .{ 2, 0, 0, 0, 0, 0 },
            .position_stages = .{ 2, 0, 0, 0, 0, 0 },
        },
    };
}

fn syntheticCoverage() contract.CoverageState {
    const families = contract.FamilyPair{
        .direct_call = syntheticFamilyCounters(.direct_call),
        .int_byte_size_call = syntheticFamilyCounters(.int_byte_size_call),
    };
    return .{
        .observation_off = .{ .report = false, .object = false, .owner = false },
        .observation_on = .{ .report = true, .object = true, .owner = true },
        .on_channel_producers = .{ 1, 1, 1 },
        .unexpected_family_events = 0,
        .argument_index_overflow_events = 0,
        .report = families,
        .object = families,
        .owner = families,
    };
}

fn syntheticCompletedPhases() !contract.PhaseMachine {
    var phases = contract.PhaseMachine.init();
    for (0..@typeInfo(contract.Phase).@"enum".fields.len) |index| {
        try phases.succeed(@enumFromInt(index));
    }
    return phases;
}

fn syntheticContractRestoration() contract.RestorationState {
    const manifest = [_]u8{0x41} ** 32;
    return .{
        .head_before = contract.source_commit,
        .head_after = contract.source_commit,
        .tracked_manifest_before = manifest,
        .tracked_manifest_after = manifest,
        .clean = true,
        .observer_source_absent = true,
        .ratchet = contract.bypass_ratchet,
    };
}

fn syntheticSemanticEquality() contract.SemanticEquality {
    const identity = contract.SemanticIdentity{
        .report = [_]u8{0x51} ** 32,
        .object = [_]u8{0x52} ** 32,
        .owner = [_]u8{0x53} ** 32,
    };
    return .{ .canonical = identity, .observation_off = identity, .observation_on = identity };
}

fn expectNoClosure(directory: std.Io.Dir, io: std.Io) !void {
    _ = directory.statFile(io, closure_name, .{ .follow_symlinks = false }) catch |failure| switch (failure) {
        error.FileNotFound => return,
        else => return failure,
    };
    return error.TestUnexpectedResult;
}

const RunPaths = struct {
    root: []const u8,
    canonical: []const u8,
    coverage: []const u8,
    canonical_cache: []const u8,
    canonical_install: []const u8,
    coverage_cache: []const u8,
    coverage_install: []const u8,
    canonical_artifact: []const u8,
    coverage_artifact: []const u8,
    accepted: []const u8,
};

const FileCommandResult = struct {
    term: std.process.Child.Term,
    stderr: []u8,
    output: FileIdentity,

    fn deinit(self: FileCommandResult, allocator: std.mem.Allocator) void {
        allocator.free(self.stderr);
    }
};

const RootUsage = struct { bytes: u64, largest_file: u64 };

fn scanRootBounded(
    io: std.Io,
    absolute_root: []const u8,
    maximum_bytes: u64,
    registered_worktrees: []const []const u8,
) !RootUsage {
    _ = try validateExplicitPath(io, absolute_root, .directory, registered_worktrees);
    var root = try std.Io.Dir.openDirAbsolute(io, absolute_root, .{
        .access_sub_paths = true,
        .iterate = true,
        .follow_symlinks = false,
    });
    defer root.close(io);
    const root_fs = try fstatfs(root);
    var walker = try root.walk(std.heap.page_allocator);
    defer walker.deinit();
    var usage = RootUsage{ .bytes = 0, .largest_file = 0 };
    var first_failure: ?RunnerError = null;
    var entry_count: u64 = 0;
    while (true) {
        const maybe_entry = walker.next(io) catch {
            if (first_failure == null) first_failure = error.PathEscape;
            continue;
        };
        const entry = maybe_entry orelse break;
        entry_count = std.math.add(u64, entry_count, 1) catch {
            if (first_failure == null) first_failure = error.StorageOverflow;
            continue;
        };
        if (entry_count > 1_000_000 and first_failure == null)
            first_failure = error.RootCapExceeded;
        if (entry.kind == .sym_link) {
            if (first_failure == null) first_failure = error.SymlinkRejected;
            continue;
        }
        const containing_fs = fstatfs(entry.dir) catch {
            if (first_failure == null) first_failure = error.CapacitySyscallFailed;
            continue;
        };
        if (!std.meta.eql(root_fs.f_fsid.values, containing_fs.f_fsid.values)) {
            if (first_failure == null) first_failure = error.PathEscape;
            continue;
        }
        switch (entry.kind) {
            .directory => {},
            .file => {
                var file = entry.dir.openFile(io, entry.basename, .{
                    .mode = .read_only,
                    .follow_symlinks = false,
                    .resolve_beneath = true,
                }) catch {
                    if (first_failure == null) first_failure = error.PathEscape;
                    continue;
                };
                defer file.close(io);
                const stat = file.stat(io) catch {
                    if (first_failure == null) first_failure = error.PathEscape;
                    continue;
                };
                usage.bytes = std.math.add(u64, usage.bytes, stat.size) catch {
                    if (first_failure == null) first_failure = error.StorageOverflow;
                    continue;
                };
                usage.largest_file = @max(usage.largest_file, stat.size);
                if (usage.largest_file > maximum_bytes and first_failure == null)
                    first_failure = error.FileCapExceeded;
                if (usage.bytes > maximum_bytes and first_failure == null)
                    first_failure = error.RootCapExceeded;
            },
            else => if (first_failure == null) {
                first_failure = error.WrongPathKind;
            },
        }
    }
    if (first_failure) |failure| return failure;
    return usage;
}

fn setFamilyFromRoot(
    usage: *[contract.storage_families.len]FamilyUsage,
    family: contract.StorageFamily,
    root: RootUsage,
) !void {
    const index: usize = @intCast(@intFromEnum(family) - 1);
    const maximum = (try contract.acceptedEnforcedStorageFamilies())[index].maximum_bytes;
    if (root.largest_file > maximum) return error.FileCapExceeded;
    if (root.bytes > maximum) return error.RootCapExceeded;
    usage[index].retained_bytes = root.bytes;
    usage[index].root_bytes = root.bytes;
    usage[index].largest_file_bytes = root.largest_file;
}

fn createRelativeTreeNoFollow(
    io: std.Io,
    absolute_base: []const u8,
    relative: []const u8,
) !std.Io.Dir {
    try validateCanonicalAbsolute(absolute_base);
    if (relative.len == 0 or std.fs.path.isAbsolute(relative)) return error.PathEscape;
    var current = try std.Io.Dir.openDirAbsolute(io, absolute_base, .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    var current_owned = true;
    errdefer if (current_owned) current.close(io);
    var components = std.mem.splitScalar(u8, relative, '/');
    while (components.next()) |component| {
        if (component.len == 0 or std.mem.eql(u8, component, ".") or
            std.mem.eql(u8, component, "..")) return error.PathEscape;
        current.createDir(io, component, .default_dir) catch |failure| switch (failure) {
            error.PathAlreadyExists => {},
            else => return failure,
        };
        const next = try current.openDir(io, component, .{
            .access_sub_paths = true,
            .iterate = false,
            .follow_symlinks = false,
        });
        current.close(io);
        current = next;
    }
    current_owned = false;
    return current;
}

fn requirePlannedAbsolute(
    allocator: std.mem.Allocator,
    repository: []const u8,
    planned: contract.V3Path,
    actual: []const u8,
) !void {
    const expected = try joinAbsolute(allocator, repository, contract.plannedPath(planned));
    defer allocator.free(expected);
    if (!std.mem.eql(u8, expected, actual)) return error.PathEscape;
}

fn makeRunPaths(
    allocator: std.mem.Allocator,
    repository: []const u8,
    validation_root: []const u8,
) !RunPaths {
    return .{
        .root = validation_root,
        .canonical = try joinAbsolute(allocator, validation_root, "canonical"),
        .coverage = try joinAbsolute(allocator, validation_root, "coverage"),
        .canonical_cache = try joinAbsolute(allocator, repository, contract.plannedPath(.canonical_cache)),
        .canonical_install = try joinAbsolute(allocator, repository, contract.plannedPath(.canonical_install)),
        .coverage_cache = try joinAbsolute(allocator, repository, contract.plannedPath(.coverage_cache)),
        .coverage_install = try joinAbsolute(allocator, repository, contract.plannedPath(.coverage_install)),
        .canonical_artifact = try std.fmt.allocPrint(
            allocator,
            "{s}/{s}/bin/z_llvm",
            .{ repository, contract.plannedPath(.canonical_install) },
        ),
        .coverage_artifact = try std.fmt.allocPrint(
            allocator,
            "{s}/{s}/bin/z_llvm",
            .{ repository, contract.plannedPath(.coverage_install) },
        ),
        .accepted = try joinAbsolute(allocator, validation_root, "canonical/repetition-1/accepted.ll"),
    };
}

fn createRunDirectories(io: std.Io, repository: []const u8, paths: RunPaths) !void {
    inline for (.{
        contract.V3Path.canonical_cache,
        contract.V3Path.canonical_install,
        contract.V3Path.coverage_cache,
        contract.V3Path.coverage_install,
    }) |planned| {
        const absolute = switch (planned) {
            .canonical_cache => paths.canonical_cache,
            .canonical_install => paths.canonical_install,
            .coverage_cache => paths.coverage_cache,
            .coverage_install => paths.coverage_install,
            else => unreachable,
        };
        try requireAbsentAbsolute(io, absolute);
        const directory = try createRelativeTreeNoFollow(io, repository, contract.plannedPath(planned));
        directory.close(io);
    }
    var root = try std.Io.Dir.openDirAbsolute(io, paths.root, .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer root.close(io);
    inline for (.{
        "canonical/build/home",         "canonical/build/tmp",           "canonical/repetition-1/home",
        "canonical/repetition-1/tmp",   "canonical/repetition-2/home",   "canonical/repetition-2/tmp",
        "canonical/repetition-3/home",  "canonical/repetition-3/tmp",    "coverage/build/home",
        "coverage/build/tmp",           "coverage/observation-off/home", "coverage/observation-off/tmp",
        "coverage/observation-on/home", "coverage/observation-on/tmp",
    }) |relative| try root.createDirPath(io, relative);
}

fn runAuthenticatedToFile(
    allocator: std.mem.Allocator,
    io: std.Io,
    subject: AuthenticatedSubject,
    command: FixedCommand,
    output_path: []const u8,
    output_limit: u64,
    expected_status: u8,
    registered_worktrees: []const []const u8,
) !FileCommandResult {
    if (!std.mem.eql(u8, subject.path, command.executable) or command.argv.len == 0 or
        !std.mem.eql(u8, command.argv[0], subject.path)) return error.WrongExecutable;
    try requireSubjectStable(io, subject, registered_worktrees);
    var environment = std.process.Environ.Map.init(allocator);
    defer environment.deinit();
    for (command.environment) |entry| try environment.put(entry.name, entry.value);
    var output = try std.Io.Dir.createFileAbsolute(io, output_path, .{
        .read = true,
        .exclusive = true,
        .truncate = false,
        .permissions = .fromMode(0o444),
    });
    var output_open = true;
    defer if (output_open) output.close(io);
    var child = std.process.spawn(io, .{
        .argv = command.argv,
        .cwd = .{ .path = command.cwd },
        .environ_map = &environment,
        .stdin = .ignore,
        .stdout = .{ .file = output },
        .stderr = .pipe,
    }) catch return error.SpawnFailed;
    defer child.kill(io);
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_reader = child.stderr.?.reader(io, &stderr_buffer);
    const stderr = stderr_reader.interface.allocRemaining(
        allocator,
        .limited(process_capture_max),
    ) catch |failure| switch (failure) {
        error.StreamTooLong => return error.ChildOutputOverflow,
        error.OutOfMemory => return error.OutOfMemory,
        else => return error.IncompleteCapture,
    };
    errdefer allocator.free(stderr);
    const term = try child.wait(io);
    switch (term) {
        .exited => |status| if (status != expected_status) return error.ChildFailed,
        else => return error.ChildFailed,
    }
    try output.sync(io);
    const stat = try output.stat(io);
    if (stat.kind != .file or stat.size == 0 or stat.size > output_limit)
        return error.FileCapExceeded;
    output.close(io);
    output_open = false;
    const identity = try observeFile(io, output_path, false, output_limit, registered_worktrees);
    try requireSubjectStable(io, subject, registered_worktrees);
    return .{ .term = term, .stderr = stderr, .output = identity };
}

fn authenticateGeneratedSubject(
    io: std.Io,
    path: []const u8,
    registered_worktrees: []const []const u8,
) !AuthenticatedSubject {
    return .{
        .path = path,
        .identity = try observeFile(io, path, true, maximum_artifact_bytes, registered_worktrees),
    };
}

fn expectCleanOutput(result: std.process.RunResult) RunnerError!void {
    try validateCapturedResult(.{
        .termination = processTermination(result.term),
        .stdout = result.stdout,
        .stderr = result.stderr,
        .stdout_complete = true,
        .stderr_complete = true,
    });
    if (result.stderr.len != 0) return error.ResultDrift;
}

fn runZigVersion(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig: AuthenticatedSubject,
    cwd: []const u8,
    registered_worktrees: []const []const u8,
) !void {
    const environment = fixedEnvironment("/nonexistent-inbox206cy-home", "/nonexistent-inbox206cy-tmp");
    const argv = [_][]const u8{ zig.path, "version" };
    const result = try runAuthenticated(allocator, io, zig, .{
        .executable = zig.path,
        .argv = &argv,
        .environment = &environment,
        .cwd = cwd,
    }, 0, registered_worktrees);
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);
    try expectCleanOutput(result);
    const portable = zig.portable_tool orelse return error.SubjectAuthorityMismatch;
    if (portable.role != .zig) return error.SubjectAuthorityMismatch;
    const version = portable.version orelse return error.SubjectAuthorityMismatch;
    if (!std.mem.eql(u8, version, expected_zig_version) or
        result.stdout.len != version.len + 1 or result.stdout[result.stdout.len - 1] != '\n' or
        !std.mem.eql(u8, result.stdout[0..version.len], version))
    {
        return error.ZigVersionMismatch;
    }
}

fn runBuildPhase(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig: AuthenticatedSubject,
    source_root: []const u8,
    cache_root: []const u8,
    install_root: []const u8,
    home: []const u8,
    temporary: []const u8,
    record_prefix: []const u8,
    family: contract.StorageFamily,
    usage: *[contract.storage_families.len]FamilyUsage,
    registered_worktrees: []const []const u8,
) !AuthenticatedSubject {
    const local_cache = try joinAbsolute(allocator, cache_root, "local");
    defer allocator.free(local_cache);
    const global_cache = try joinAbsolute(allocator, cache_root, "global");
    defer allocator.free(global_cache);
    var cache_dir = try std.Io.Dir.openDirAbsolute(io, cache_root, .{
        .access_sub_paths = true,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer cache_dir.close(io);
    try cache_dir.createDir(io, "local", .default_dir);
    try cache_dir.createDir(io, "global", .default_dir);
    const environment = fixedEnvironment(home, temporary);
    const argv = [_][]const u8{
        zig.path,             "build",      "--prefix",  install_root, "--cache-dir", local_cache,
        "--global-cache-dir", global_cache, "--summary", "all",
    };
    const result = try runAuthenticated(allocator, io, zig, .{
        .executable = zig.path,
        .argv = &argv,
        .environment = &environment,
        .cwd = source_root,
    }, 0, registered_worktrees);
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);
    try expectCleanOutput(result);
    try recordProcessResult(allocator, io, home[0..std.mem.lastIndexOfScalar(u8, home, '/').?], record_prefix, result, family, usage);
    const artifact = try joinAbsolute(allocator, install_root, "bin/z_llvm");
    return authenticateGeneratedSubject(io, artifact, registered_worktrees);
}

fn runArtifactCapture(
    allocator: std.mem.Allocator,
    io: std.Io,
    artifact: AuthenticatedSubject,
    input: []const u8,
    emit: []const u8,
    report_failures: bool,
    environment: []const EnvironmentEntry,
    cwd: []const u8,
    expected_status: u8,
    registered_worktrees: []const []const u8,
) !std.process.RunResult {
    const argv_report = [_][]const u8{
        artifact.path,         emit,                            "--generic-cfg-selector", "--report-all-codegen-failures",
        "--target=" ++ target, "--input-limit=" ++ input_limit, input,
    };
    const argv_success = [_][]const u8{
        artifact.path,                   emit,  "--generic-cfg-selector", "--target=" ++ target,
        "--input-limit=" ++ input_limit, input,
    };
    return runAuthenticated(allocator, io, artifact, .{
        .executable = artifact.path,
        .argv = if (report_failures) &argv_report else &argv_success,
        .environment = environment,
        .cwd = cwd,
    }, expected_status, registered_worktrees);
}

fn runArtifactToFile(
    allocator: std.mem.Allocator,
    io: std.Io,
    artifact: AuthenticatedSubject,
    input: []const u8,
    emit: []const u8,
    environment: []const EnvironmentEntry,
    cwd: []const u8,
    output_path: []const u8,
    registered_worktrees: []const []const u8,
) !FileCommandResult {
    const argv = [_][]const u8{
        artifact.path,                   emit,  "--generic-cfg-selector", "--target=" ++ target,
        "--input-limit=" ++ input_limit, input,
    };
    return runAuthenticatedToFile(allocator, io, artifact, .{
        .executable = artifact.path,
        .argv = &argv,
        .environment = environment,
        .cwd = cwd,
    }, output_path, maximum_artifact_bytes, 0, registered_worktrees);
}

fn runToolToFile(
    allocator: std.mem.Allocator,
    io: std.Io,
    subject: AuthenticatedSubject,
    argv: []const []const u8,
    environment: []const EnvironmentEntry,
    cwd: []const u8,
    output_path: []const u8,
    maximum_bytes: u64,
    registered_worktrees: []const []const u8,
) !FileCommandResult {
    return runAuthenticatedToFile(allocator, io, subject, .{
        .executable = subject.path,
        .argv = argv,
        .environment = environment,
        .cwd = cwd,
    }, output_path, maximum_bytes, 0, registered_worktrees);
}

fn extractAcceptedSubset(
    allocator: std.mem.Allocator,
    io: std.Io,
    llvm_extract: AuthenticatedSubject,
    failures: []const []const u8,
    raw_input: []const u8,
    accepted_path: []const u8,
    environment: []const EnvironmentEntry,
    cwd: []const u8,
    registered_worktrees: []const []const u8,
) !FileIdentity {
    var argv = std.array_list.Managed([]const u8).init(allocator);
    defer argv.deinit();
    try argv.appendSlice(&.{ llvm_extract.path, "--delete", "-S", "-o", accepted_path });
    for (failures) |function_name| {
        try argv.append("--func");
        try argv.append(function_name);
    }
    try argv.append(raw_input);
    const result = try runAuthenticated(allocator, io, llvm_extract, .{
        .executable = llvm_extract.path,
        .argv = argv.items,
        .environment = environment,
        .cwd = cwd,
    }, 0, registered_worktrees);
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);
    try expectCleanOutput(result);
    if (result.stdout.len != 0) return error.ResultDrift;
    return observeFile(io, accepted_path, false, maximum_input_bytes, registered_worktrees);
}

fn requireNoStderr(result: FileCommandResult) RunnerError!void {
    if (result.stderr.len != 0) return error.ResultDrift;
}

fn canonicalRepetition(
    allocator: std.mem.Allocator,
    io: std.Io,
    subjects: SubjectSet,
    artifact: AuthenticatedSubject,
    raw_input: []const u8,
    accepted_path: []const u8,
    repetition_root: []const u8,
    repetition_index: usize,
    usage: *[contract.storage_families.len]FamilyUsage,
    registered_worktrees: []const []const u8,
) !contract.CanonicalRepetition {
    const home = try joinAbsolute(allocator, repetition_root, "home");
    const temporary = try joinAbsolute(allocator, repetition_root, "tmp");
    const environment = fixedEnvironment(home, temporary);
    const report = try runArtifactCapture(
        allocator,
        io,
        artifact,
        raw_input,
        "--emit=obj",
        true,
        &environment,
        repetition_root,
        1,
        registered_worktrees,
    );
    defer allocator.free(report.stdout);
    defer allocator.free(report.stderr);
    if (report.stdout.len != 0) return error.ResultDrift;
    try accountFamilyBytes(usage, .repetition_raw_report, report.stderr.len);
    const failures = try parseReportFailures(allocator, report.stderr);
    defer allocator.free(failures);
    try validateReportSummary(report.stderr, failures.len);
    if (repetition_index == 0) {
        const accepted_identity = try extractAcceptedSubset(
            allocator,
            io,
            subjects.llvm_extract,
            failures,
            raw_input,
            accepted_path,
            &environment,
            repetition_root,
            registered_worktrees,
        );
        try accountFamilyBytes(usage, .canonical_accepted_ll, accepted_identity.bytes);
    } else {
        _ = try observeFile(io, accepted_path, false, maximum_input_bytes, registered_worktrees);
    }

    const object_path = try joinAbsolute(allocator, repetition_root, "accepted.o");
    const object = try runArtifactToFile(
        allocator,
        io,
        artifact,
        accepted_path,
        "--emit=obj",
        &environment,
        repetition_root,
        object_path,
        registered_worktrees,
    );
    defer object.deinit(allocator);
    try requireNoStderr(object);
    try accountFamilyBytes(usage, .repetition_successful_subset, object.output.bytes);
    const owner_path = try joinAbsolute(allocator, repetition_root, "owner.tsv");
    const owner = try runArtifactToFile(
        allocator,
        io,
        artifact,
        accepted_path,
        "--emit=selection-owner-manifest",
        &environment,
        repetition_root,
        owner_path,
        registered_worktrees,
    );
    defer owner.deinit(allocator);
    try requireNoStderr(owner);
    try accountFamilyBytes(usage, .repetition_successful_subset, owner.output.bytes);

    const objdump_path = try joinAbsolute(allocator, repetition_root, "accepted.objdump");
    const objdump_argv = [_][]const u8{ subjects.objdump.path, "-d", object_path };
    const objdump = try runToolToFile(
        allocator,
        io,
        subjects.objdump,
        &objdump_argv,
        &environment,
        repetition_root,
        objdump_path,
        maximum_artifact_bytes,
        registered_worktrees,
    );
    defer objdump.deinit(allocator);
    try requireNoStderr(objdump);
    try accountFamilyBytes(usage, .canonical_per_function, objdump.output.bytes);

    const sections_path = try joinAbsolute(allocator, repetition_root, "sections.readelf");
    const sections_argv = [_][]const u8{ subjects.readelf.path, "-SW", object_path };
    const sections = try runToolToFile(
        allocator,
        io,
        subjects.readelf,
        &sections_argv,
        &environment,
        repetition_root,
        sections_path,
        process_capture_max,
        registered_worktrees,
    );
    defer sections.deinit(allocator);
    try requireNoStderr(sections);
    try accountFamilyBytes(usage, .canonical_comparisons, sections.output.bytes);

    const symbols_path = try joinAbsolute(allocator, repetition_root, "symbols.readelf");
    const symbols_argv = [_][]const u8{ subjects.readelf.path, "-sW", object_path };
    const symbols = try runToolToFile(
        allocator,
        io,
        subjects.readelf,
        &symbols_argv,
        &environment,
        repetition_root,
        symbols_path,
        process_capture_max,
        registered_worktrees,
    );
    defer symbols.deinit(allocator);
    try requireNoStderr(symbols);
    try accountFamilyBytes(usage, .canonical_per_function, symbols.output.bytes);
    const symbol_bytes = try readBoundedAbsolute(allocator, io, symbols_path, process_capture_max);
    defer allocator.free(symbol_bytes);
    const rows = try parseReadelfFunctions(allocator, symbol_bytes);
    defer allocator.free(rows);
    const section_bytes = try readBoundedAbsolute(
        allocator,
        io,
        sections_path,
        maximum_parsed_tool_output,
    );
    defer allocator.free(section_bytes);
    try validateReadelfSections(section_bytes);
    const objdump_bytes = try readBoundedAbsolute(
        allocator,
        io,
        objdump_path,
        maximum_parsed_tool_output,
    );
    defer allocator.free(objdump_bytes);
    try validateObjdumpFunctions(objdump_bytes, rows);

    const text_path = try joinAbsolute(allocator, repetition_root, "text.bin");
    const dump_argument = try std.fmt.allocPrint(allocator, ".text={s}", .{text_path});
    const objcopy_argv = [_][]const u8{ subjects.objcopy.path, "--dump-section", dump_argument, object_path };
    const objcopy_result = try runAuthenticated(allocator, io, subjects.objcopy, .{
        .executable = subjects.objcopy.path,
        .argv = &objcopy_argv,
        .environment = &environment,
        .cwd = repetition_root,
    }, 0, registered_worktrees);
    defer allocator.free(objcopy_result.stdout);
    defer allocator.free(objcopy_result.stderr);
    try expectCleanOutput(objcopy_result);
    if (objcopy_result.stdout.len != 0) return error.ResultDrift;
    const text_identity = try observeFile(io, text_path, false, maximum_artifact_bytes, registered_worktrees);
    try accountFamilyBytes(usage, .repetition_successful_subset, text_identity.bytes);
    const function_manifest = try encodeFunctionManifest(
        allocator,
        io,
        text_path,
        text_identity.bytes,
        rows,
    );
    defer allocator.free(function_manifest);
    const function_manifest_path = try joinAbsolute(allocator, repetition_root, "functions.tsv");
    const function_manifest_identity = try writeExclusiveAbsolute(
        io,
        function_manifest_path,
        function_manifest,
        0o444,
    );
    try accountFamilyBytes(usage, .canonical_per_function, function_manifest_identity.bytes);
    const owner_bytes = try readBoundedAbsolute(allocator, io, owner_path, process_capture_max);
    defer allocator.free(owner_bytes);
    try validateOwnerManifest(owner_bytes);
    return .{
        .report = sha256(report.stderr),
        .object = object.output.sha256,
        .owner = owner.output.sha256,
        .function_manifest = function_manifest_identity.sha256,
        .function_count = @intCast(rows.len),
        .accepted_subset_produced = repetition_index == 0,
    };
}

const ObservationResult = struct {
    semantic: contract.SemanticIdentity,
    function_manifest: contract.Digest,
    report_channel: ?ParsedCoverageChannel,
    object_channel: ?ParsedCoverageChannel,
    owner_channel: ?ParsedCoverageChannel,
};

fn analyzeObservationObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    subjects: SubjectSet,
    observation_root: []const u8,
    object_path: []const u8,
    environment: []const EnvironmentEntry,
    usage: *[contract.storage_families.len]FamilyUsage,
    registered_worktrees: []const []const u8,
) !contract.Digest {
    const objdump_path = try joinAbsolute(allocator, observation_root, "accepted.objdump");
    const objdump_argv = [_][]const u8{ subjects.objdump.path, "-d", object_path };
    const objdump = try runToolToFile(
        allocator,
        io,
        subjects.objdump,
        &objdump_argv,
        environment,
        observation_root,
        objdump_path,
        maximum_artifact_bytes,
        registered_worktrees,
    );
    defer objdump.deinit(allocator);
    try requireNoStderr(objdump);
    try accountFamilyBytes(usage, .coverage_per_function, objdump.output.bytes);

    const sections_path = try joinAbsolute(allocator, observation_root, "sections.readelf");
    const sections_argv = [_][]const u8{ subjects.readelf.path, "-SW", object_path };
    const sections = try runToolToFile(
        allocator,
        io,
        subjects.readelf,
        &sections_argv,
        environment,
        observation_root,
        sections_path,
        process_capture_max,
        registered_worktrees,
    );
    defer sections.deinit(allocator);
    try requireNoStderr(sections);
    try accountFamilyBytes(usage, .coverage_comparisons, sections.output.bytes);

    const symbols_path = try joinAbsolute(allocator, observation_root, "symbols.readelf");
    const symbols_argv = [_][]const u8{ subjects.readelf.path, "-sW", object_path };
    const symbols = try runToolToFile(
        allocator,
        io,
        subjects.readelf,
        &symbols_argv,
        environment,
        observation_root,
        symbols_path,
        process_capture_max,
        registered_worktrees,
    );
    defer symbols.deinit(allocator);
    try requireNoStderr(symbols);
    try accountFamilyBytes(usage, .coverage_per_function, symbols.output.bytes);
    const symbol_bytes = try readBoundedAbsolute(allocator, io, symbols_path, process_capture_max);
    defer allocator.free(symbol_bytes);
    const rows = try parseReadelfFunctions(allocator, symbol_bytes);
    defer allocator.free(rows);
    const section_bytes = try readBoundedAbsolute(
        allocator,
        io,
        sections_path,
        maximum_parsed_tool_output,
    );
    defer allocator.free(section_bytes);
    try validateReadelfSections(section_bytes);
    const objdump_bytes = try readBoundedAbsolute(
        allocator,
        io,
        objdump_path,
        maximum_parsed_tool_output,
    );
    defer allocator.free(objdump_bytes);
    try validateObjdumpFunctions(objdump_bytes, rows);

    const text_path = try joinAbsolute(allocator, observation_root, "text.bin");
    const dump_argument = try std.fmt.allocPrint(allocator, ".text={s}", .{text_path});
    const objcopy_argv = [_][]const u8{ subjects.objcopy.path, "--dump-section", dump_argument, object_path };
    const objcopy_result = try runAuthenticated(allocator, io, subjects.objcopy, .{
        .executable = subjects.objcopy.path,
        .argv = &objcopy_argv,
        .environment = environment,
        .cwd = observation_root,
    }, 0, registered_worktrees);
    defer allocator.free(objcopy_result.stdout);
    defer allocator.free(objcopy_result.stderr);
    try expectCleanOutput(objcopy_result);
    if (objcopy_result.stdout.len != 0) return error.ResultDrift;
    const text_identity = try observeFile(io, text_path, false, maximum_artifact_bytes, registered_worktrees);
    try accountFamilyBytes(usage, .coverage_per_function, text_identity.bytes);
    const manifest = try encodeFunctionManifest(
        allocator,
        io,
        text_path,
        text_identity.bytes,
        rows,
    );
    defer allocator.free(manifest);
    const manifest_path = try joinAbsolute(allocator, observation_root, "functions.tsv");
    const manifest_identity = try writeExclusiveAbsolute(io, manifest_path, manifest, 0o444);
    try accountFamilyBytes(usage, .coverage_final_manifests, manifest_identity.bytes);
    return manifest_identity.sha256;
}

fn runObservation(
    allocator: std.mem.Allocator,
    io: std.Io,
    subjects: SubjectSet,
    artifact: AuthenticatedSubject,
    raw_input: []const u8,
    accepted_path: []const u8,
    observation_root: []const u8,
    coverage_enabled: bool,
    usage: *[contract.storage_families.len]FamilyUsage,
    registered_worktrees: []const []const u8,
) !ObservationResult {
    const home = try joinAbsolute(allocator, observation_root, "home");
    const temporary = try joinAbsolute(allocator, observation_root, "tmp");
    const report_channel_path = try joinAbsolute(allocator, observation_root, "report.coverage.tsv");
    const object_channel_path = try joinAbsolute(allocator, observation_root, "object.coverage.tsv");
    const owner_channel_path = try joinAbsolute(allocator, observation_root, "owner.coverage.tsv");
    try requireAbsentAbsolute(io, report_channel_path);
    try requireAbsentAbsolute(io, object_channel_path);
    try requireAbsentAbsolute(io, owner_channel_path);

    const off_environment = fixedEnvironment(home, temporary);
    const report_on_environment = fixedCoverageEnvironment(home, temporary, report_channel_path);
    const object_on_environment = fixedCoverageEnvironment(home, temporary, object_channel_path);
    const owner_on_environment = fixedCoverageEnvironment(home, temporary, owner_channel_path);
    const report_environment: []const EnvironmentEntry = if (coverage_enabled)
        &report_on_environment
    else
        &off_environment;
    const object_environment: []const EnvironmentEntry = if (coverage_enabled)
        &object_on_environment
    else
        &off_environment;
    const owner_environment: []const EnvironmentEntry = if (coverage_enabled)
        &owner_on_environment
    else
        &off_environment;

    const report = try runArtifactCapture(
        allocator,
        io,
        artifact,
        raw_input,
        "--emit=obj",
        true,
        report_environment,
        observation_root,
        1,
        registered_worktrees,
    );
    defer allocator.free(report.stdout);
    defer allocator.free(report.stderr);
    if (report.stdout.len != 0) return error.ResultDrift;
    try accountFamilyBytes(
        usage,
        if (coverage_enabled) .observation_on_remaining else .observation_off,
        report.stderr.len,
    );
    const failures = try parseReportFailures(allocator, report.stderr);
    defer allocator.free(failures);
    try validateReportSummary(report.stderr, failures.len);

    const object_path = try joinAbsolute(allocator, observation_root, "accepted.o");
    const object = try runArtifactToFile(
        allocator,
        io,
        artifact,
        accepted_path,
        "--emit=obj",
        object_environment,
        observation_root,
        object_path,
        registered_worktrees,
    );
    defer object.deinit(allocator);
    try requireNoStderr(object);
    try accountFamilyBytes(
        usage,
        if (coverage_enabled) .observation_on_remaining else .observation_off,
        object.output.bytes,
    );
    const owner_path = try joinAbsolute(allocator, observation_root, "owner.tsv");
    const owner = try runArtifactToFile(
        allocator,
        io,
        artifact,
        accepted_path,
        "--emit=selection-owner-manifest",
        owner_environment,
        observation_root,
        owner_path,
        registered_worktrees,
    );
    defer owner.deinit(allocator);
    try requireNoStderr(owner);
    try accountFamilyBytes(
        usage,
        if (coverage_enabled) .observation_on_remaining else .observation_off,
        owner.output.bytes,
    );
    const owner_bytes = try readBoundedAbsolute(allocator, io, owner_path, process_capture_max);
    defer allocator.free(owner_bytes);
    try validateOwnerManifest(owner_bytes);
    const analysis_environment = fixedEnvironment(home, temporary);
    const function_manifest = try analyzeObservationObject(
        allocator,
        io,
        subjects,
        observation_root,
        object_path,
        &analysis_environment,
        usage,
        registered_worktrees,
    );

    var result = ObservationResult{
        .semantic = .{
            .report = sha256(report.stderr),
            .object = object.output.sha256,
            .owner = owner.output.sha256,
        },
        .function_manifest = function_manifest,
        .report_channel = null,
        .object_channel = null,
        .owner_channel = null,
    };
    if (!coverage_enabled) {
        try requireAbsentAbsolute(io, report_channel_path);
        try requireAbsentAbsolute(io, object_channel_path);
        try requireAbsentAbsolute(io, owner_channel_path);
        return result;
    }
    const report_channel = try readBoundedAbsolute(allocator, io, report_channel_path, process_capture_max);
    defer allocator.free(report_channel);
    const object_channel = try readBoundedAbsolute(allocator, io, object_channel_path, process_capture_max);
    defer allocator.free(object_channel);
    const owner_channel = try readBoundedAbsolute(allocator, io, owner_channel_path, process_capture_max);
    defer allocator.free(owner_channel);
    try accountFamilyBytes(usage, .observation_on_channels, report_channel.len);
    try accountFamilyBytes(usage, .observation_on_channels, object_channel.len);
    try accountFamilyBytes(usage, .observation_on_channels, owner_channel.len);
    result.report_channel = try parseCoverageChannel(report_channel);
    result.object_channel = try parseCoverageChannel(object_channel);
    result.owner_channel = try parseCoverageChannel(owner_channel);
    return result;
}

fn requireRepository(
    observation: RepositoryObservation,
    expected_head: []const u8,
    expected_tree: ?[]const u8,
    require_clean: bool,
) RunnerError!void {
    if (!std.mem.eql(u8, &observation.head, expected_head))
        return error.GitObservationMismatch;
    if (expected_tree) |tree| if (!std.mem.eql(u8, &observation.tree, tree))
        return error.GitObservationMismatch;
    if (require_clean and !observation.clean) return error.GitObservationMismatch;
}

fn digestRepository(observation: RepositoryObservation) contract.Digest {
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    hasher.update(&observation.head);
    hasher.update(&observation.tree);
    hasher.update(&observation.status);
    hasher.update(if (observation.clean) "clean" else "dirty");
    var result: contract.Digest = undefined;
    hasher.final(&result);
    return result;
}

fn makeRestorationIdentity(
    repository: RepositoryObservation,
    canonical_source: RepositoryObservation,
    coverage_source: RepositoryObservation,
    accepted: FileIdentity,
) RestorationIdentity {
    return .{
        .repository = digestRepository(repository),
        .canonical_source = digestRepository(canonical_source),
        .coverage_source = digestRepository(coverage_source),
        .accepted_input = accepted.sha256,
    };
}

fn combineRootUsage(a: RootUsage, b: RootUsage, excluded_bytes: u64) RunnerError!RootUsage {
    const combined = std.math.add(u64, a.bytes, b.bytes) catch return error.StorageOverflow;
    return .{
        .bytes = std.math.sub(u64, combined, excluded_bytes) catch return error.StorageOverflow,
        .largest_file = @max(a.largest_file, b.largest_file),
    };
}

fn addRootUsage(a: RootUsage, b: RootUsage) RunnerError!RootUsage {
    return .{
        .bytes = std.math.add(u64, a.bytes, b.bytes) catch return error.StorageOverflow,
        .largest_file = @max(a.largest_file, b.largest_file),
    };
}

fn scanRelativeRoots(
    allocator: std.mem.Allocator,
    io: std.Io,
    base: []const u8,
    relatives: []const []const u8,
    maximum_bytes: u64,
    registered_worktrees: []const []const u8,
) !RootUsage {
    var total = RootUsage{ .bytes = 0, .largest_file = 0 };
    for (relatives) |relative| {
        const absolute = try joinAbsolute(allocator, base, relative);
        defer allocator.free(absolute);
        total = try addRootUsage(
            total,
            try scanRootBounded(io, absolute, maximum_bytes, registered_worktrees),
        );
        if (total.bytes > maximum_bytes) return error.RootCapExceeded;
    }
    return total;
}

fn validateCliPathSet(io: std.Io, cli: Cli) !void {
    const specs = .{
        .{ "repository", cli.repository, PathKind.directory },
        .{ "external_zig_repository", cli.external_zig_repository, PathKind.directory },
        .{ "canonical_source", cli.canonical_source, PathKind.directory },
        .{ "coverage_source", cli.coverage_source, PathKind.directory },
        .{ "bundle_root", cli.bundle_root, PathKind.directory },
        .{ "zig", cli.zig.path, PathKind.file },
        .{ "git", cli.git.path, PathKind.file },
        .{ "llvm_extract", cli.llvm_extract.path, PathKind.file },
        .{ "objcopy", cli.objcopy.path, PathKind.file },
        .{ "objdump", cli.objdump.path, PathKind.file },
        .{ "readelf", cli.readelf.path, PathKind.file },
        .{ "raw_input", cli.raw_input, PathKind.file },
        .{ "adoption_manifest", cli.adoption_manifest, PathKind.file },
        .{ "reproduction_manifest", cli.reproduction_manifest, PathKind.file },
        .{ "retention_pins", cli.retention_pins, PathKind.file },
        .{ "retention_policy", cli.retention_policy, PathKind.file },
        .{ "cleanup_source", cli.cleanup_source, PathKind.file },
        .{ "bypass_inventory", cli.bypass_inventory, PathKind.file },
        .{ "facade_manifest", cli.facade_manifest, PathKind.file },
        .{ "facade_source", cli.facade_source, PathKind.file },
        .{ "external_stage4", cli.external_stage4, PathKind.file },
    };
    var facts: [specs.len]PathFact = undefined;
    inline for (specs, 0..) |spec, index| {
        facts[index] = try observePathFact(
            io,
            spec[0],
            spec[1],
            spec[2],
            cli.registered_worktrees,
        );
    }
    try validatePathFacts(&facts, cli.registered_worktrees);
}

fn executeAcceptedBaseline(init: std.process.Init, supplied_cli: Cli) !void {
    const access_exclusions = try registeredWorktreeAccessExclusions(
        init.gpa,
        supplied_cli.registered_worktrees,
        supplied_cli.repository,
    );
    defer init.gpa.free(access_exclusions);
    var cli = supplied_cli;
    cli.registered_worktrees = access_exclusions;
    var phases = contract.PhaseMachine.init();
    try requirePlannedAbsolute(init.gpa, cli.repository, .validation_root, cli.validation_root);
    try requirePlannedAbsolute(init.gpa, cli.repository, .canonical_source, cli.canonical_source);
    try requirePlannedAbsolute(init.gpa, cli.repository, .coverage_source, cli.coverage_source);
    try validateCanonicalAbsolute(cli.external_zig_repository);
    try requireAbsentAbsolute(init.io, cli.validation_root);

    const git_subject = try authenticateSubject(init.io, cli.git, cli.registered_worktrees);
    const registered_worktree_set = try observeRegisteredWorktreeSet(
        init.gpa,
        init.io,
        git_subject,
        cli.repository,
        supplied_cli.registered_worktrees,
    );
    const subjects = try authenticateSubjects(init.io, cli);
    try validateCliPathSet(init.io, cli);
    const inputs_before = try authenticateInputs(init.gpa, init.io, cli);
    const bundle_manifest_path = try joinAbsolute(
        init.gpa,
        cli.bundle_root,
        "manifests/bundle-files.sha256",
    );
    const bundle_manifest = try readBoundedAbsolute(
        init.gpa,
        init.io,
        bundle_manifest_path,
        maximum_input_bytes,
    );
    defer init.gpa.free(bundle_manifest);
    try verifyCompatibilityBundleMembers(
        init.gpa,
        init.io,
        cli.bundle_root,
        bundle_manifest,
        cli.registered_worktrees,
    );
    const baseline_manifest = try readAuthenticatedBundleMember(
        init.gpa,
        init.io,
        cli.bundle_root,
        bundle_manifest,
        "manifests/baseline-source.sha256",
        cli.registered_worktrees,
    );
    defer init.gpa.free(baseline_manifest);
    const bundled_manifest = try readAuthenticatedBundleMember(
        init.gpa,
        init.io,
        cli.bundle_root,
        bundle_manifest,
        "manifests/bundled-source.sha256",
        cli.registered_worktrees,
    );
    defer init.gpa.free(bundled_manifest);
    const touched_paths = try readAuthenticatedBundleMember(
        init.gpa,
        init.io,
        cli.bundle_root,
        bundle_manifest,
        "manifests/touched-paths.txt",
        cli.registered_worktrees,
    );
    defer init.gpa.free(touched_paths);
    const canonical_manifest_identity = try verifySourceManifest(
        init.gpa,
        init.io,
        cli.canonical_source,
        baseline_manifest,
        cli.registered_worktrees,
    );
    const coverage_manifest_identity = try verifySourceManifest(
        init.gpa,
        init.io,
        cli.coverage_source,
        bundled_manifest,
        cli.registered_worktrees,
    );
    try runZigVersion(init.gpa, init.io, subjects.zig, cli.repository, cli.registered_worktrees);
    const repository_before = try observeRepository(
        init.gpa,
        init.io,
        subjects.git,
        cli.repository,
        cli.registered_worktrees,
    );
    if (!repository_before.clean) return error.GitObservationMismatch;
    const external_before = try observeRepository(
        init.gpa,
        init.io,
        subjects.git,
        cli.external_zig_repository,
        cli.registered_worktrees,
    );
    try requireRepository(
        external_before,
        contract.external_zig_commit,
        contract.external_zig_tree,
        true,
    );
    try phases.succeed(.preflight);

    const canonical_before = try observeRepository(
        init.gpa,
        init.io,
        subjects.git,
        cli.canonical_source,
        cli.registered_worktrees,
    );
    try requireRepository(canonical_before, contract.source_commit, null, true);
    try phases.succeed(.canonical_source);

    const paths = try makeRunPaths(init.gpa, cli.repository, cli.validation_root);
    var validation_root = try createValidationRoot(init.gpa, init.io, cli.repository, cli.validation_root);
    defer validation_root.close(init.io);
    const available_bytes = try observeAvailableBytes(init.io, validation_root);
    _ = try contract.acceptedStorageBudgetTotals(available_bytes);
    try createRunDirectories(init.io, cli.repository, paths);
    try requireSameOutputFilesystem(init.io, validation_root, paths.canonical_cache);
    try requireSameOutputFilesystem(init.io, validation_root, paths.canonical_install);
    try requireSameOutputFilesystem(init.io, validation_root, paths.coverage_cache);
    try requireSameOutputFilesystem(init.io, validation_root, paths.coverage_install);
    var usage = initializeFamilyUsage();

    const canonical_home = try joinAbsolute(init.gpa, paths.canonical, "build/home");
    const canonical_tmp = try joinAbsolute(init.gpa, paths.canonical, "build/tmp");
    const canonical_artifact = try runBuildPhase(
        init.gpa,
        init.io,
        subjects.zig,
        cli.canonical_source,
        paths.canonical_cache,
        paths.canonical_install,
        canonical_home,
        canonical_tmp,
        "build",
        .canonical_build_raw_status,
        &usage,
        cli.registered_worktrees,
    );
    try accountFamilyBytes(&usage, .canonical_artifact, canonical_artifact.identity.bytes);
    try accountFamilyBytes(&usage, .canonical_artifact_identity, @sizeOf(FileIdentity));
    const canonical_cache_usage = try scanRootBounded(
        init.io,
        paths.canonical_cache,
        (try contract.acceptedEnforcedStorageFamilies())[@intFromEnum(contract.StorageFamily.canonical_build_cache_install) - 1].maximum_bytes,
        cli.registered_worktrees,
    );
    const canonical_install_usage = try scanRootBounded(
        init.io,
        paths.canonical_install,
        (try contract.acceptedEnforcedStorageFamilies())[@intFromEnum(contract.StorageFamily.canonical_build_cache_install) - 1].maximum_bytes,
        cli.registered_worktrees,
    );
    try setFamilyFromRoot(
        &usage,
        .canonical_build_cache_install,
        try combineRootUsage(canonical_cache_usage, canonical_install_usage, canonical_artifact.identity.bytes),
    );
    try runZigVersion(init.gpa, init.io, subjects.zig, cli.repository, cli.registered_worktrees);
    try phases.succeed(.canonical_build);

    var repetitions: [contract.canonical_repetition_count]contract.CanonicalRepetition = undefined;
    for (&repetitions, 0..) |*repetition, index| {
        const repetition_root = try std.fmt.allocPrint(
            init.gpa,
            "{s}/canonical/repetition-{d}",
            .{ cli.validation_root, index + 1 },
        );
        repetition.* = try canonicalRepetition(
            init.gpa,
            init.io,
            subjects,
            canonical_artifact,
            cli.raw_input,
            paths.accepted,
            repetition_root,
            index,
            &usage,
            cli.registered_worktrees,
        );
        try phases.succeed(@enumFromInt(@intFromEnum(contract.Phase.canonical_repetition_1) + index));
    }
    try contract.validateCanonicalRepetitions(&repetitions);
    const canonical_home_tmp_max = (try contract.acceptedEnforcedStorageFamilies())[
        @intFromEnum(contract.StorageFamily.canonical_repetition_home_tmp) - 1
    ].maximum_bytes;
    try setFamilyFromRoot(
        &usage,
        .canonical_repetition_home_tmp,
        try scanRelativeRoots(
            init.gpa,
            init.io,
            paths.canonical,
            &.{
                "build/home",        "build/tmp",        "repetition-1/home", "repetition-1/tmp",
                "repetition-2/home", "repetition-2/tmp", "repetition-3/home", "repetition-3/tmp",
            },
            canonical_home_tmp_max,
            cli.registered_worktrees,
        ),
    );
    try accountFamilyBytes(&usage, .accepted_ll_proof, @sizeOf(FileIdentity));
    try accountFamilyBytes(&usage, .canonical_identities, @sizeOf(@TypeOf(repetitions)));
    try accountFamilyBytes(&usage, .canonical_final_manifests, @sizeOf(@TypeOf(repetitions)));
    try phases.succeed(.canonical_finalize);

    const coverage_before = try observeRepository(
        init.gpa,
        init.io,
        subjects.git,
        cli.coverage_source,
        cli.registered_worktrees,
    );
    try requireRepository(coverage_before, contract.source_commit, null, false);
    const coverage_status_before = try observeRepositoryStatus(
        init.gpa,
        init.io,
        subjects.git,
        cli.coverage_source,
        cli.registered_worktrees,
    );
    defer init.gpa.free(coverage_status_before.stdout);
    defer init.gpa.free(coverage_status_before.stderr);
    if (coverage_status_before.stderr.len != 0) return error.GitObservationMismatch;
    try validateCoverageStatus(coverage_status_before.stdout, touched_paths);
    try phases.succeed(.coverage_source);
    const coverage_home = try joinAbsolute(init.gpa, paths.coverage, "build/home");
    const coverage_tmp = try joinAbsolute(init.gpa, paths.coverage, "build/tmp");
    const coverage_artifact = try runBuildPhase(
        init.gpa,
        init.io,
        subjects.zig,
        cli.coverage_source,
        paths.coverage_cache,
        paths.coverage_install,
        coverage_home,
        coverage_tmp,
        "build",
        .coverage_build_cache_install,
        &usage,
        cli.registered_worktrees,
    );
    try accountFamilyBytes(&usage, .coverage_artifact, coverage_artifact.identity.bytes);
    const coverage_cache_usage = try scanRootBounded(
        init.io,
        paths.coverage_cache,
        (try contract.acceptedEnforcedStorageFamilies())[@intFromEnum(contract.StorageFamily.coverage_build_cache_install) - 1].maximum_bytes,
        cli.registered_worktrees,
    );
    const coverage_install_usage = try scanRootBounded(
        init.io,
        paths.coverage_install,
        (try contract.acceptedEnforcedStorageFamilies())[@intFromEnum(contract.StorageFamily.coverage_build_cache_install) - 1].maximum_bytes,
        cli.registered_worktrees,
    );
    const coverage_build_path = try joinAbsolute(init.gpa, paths.coverage, "build");
    defer init.gpa.free(coverage_build_path);
    const coverage_build_usage = try scanRootBounded(
        init.io,
        coverage_build_path,
        (try contract.acceptedEnforcedStorageFamilies())[@intFromEnum(contract.StorageFamily.coverage_build_cache_install) - 1].maximum_bytes,
        cli.registered_worktrees,
    );
    try setFamilyFromRoot(
        &usage,
        .coverage_build_cache_install,
        try addRootUsage(
            try combineRootUsage(coverage_cache_usage, coverage_install_usage, coverage_artifact.identity.bytes),
            coverage_build_usage,
        ),
    );
    try runZigVersion(init.gpa, init.io, subjects.zig, cli.repository, cli.registered_worktrees);
    try phases.succeed(.coverage_build);

    const accepted_identity = try observeFile(
        init.io,
        paths.accepted,
        false,
        maximum_input_bytes,
        cli.registered_worktrees,
    );
    const before = makeRestorationIdentity(
        repository_before,
        canonical_before,
        coverage_before,
        accepted_identity,
    );
    try accountFamilyBytes(&usage, .coverage_reference, @sizeOf(FileIdentity));
    const off_root = try joinAbsolute(init.gpa, paths.coverage, "observation-off");
    const off = try runObservation(
        init.gpa,
        init.io,
        subjects,
        coverage_artifact,
        cli.raw_input,
        paths.accepted,
        off_root,
        false,
        &usage,
        cli.registered_worktrees,
    );
    try phases.succeed(.observation_off);
    const on_root = try joinAbsolute(init.gpa, paths.coverage, "observation-on");
    const on = try runObservation(
        init.gpa,
        init.io,
        subjects,
        coverage_artifact,
        cli.raw_input,
        paths.accepted,
        on_root,
        true,
        &usage,
        cli.registered_worktrees,
    );
    try phases.succeed(.observation_on);
    const report_channel = on.report_channel orelse return error.MalformedCounterChannel;
    const object_channel = on.object_channel orelse return error.MalformedCounterChannel;
    const owner_channel = on.owner_channel orelse return error.MalformedCounterChannel;
    if (report_channel.unexpected_family_events != 0 or
        object_channel.unexpected_family_events != 0 or
        owner_channel.unexpected_family_events != 0 or
        report_channel.argument_index_overflow_events != 0 or
        object_channel.argument_index_overflow_events != 0 or
        owner_channel.argument_index_overflow_events != 0)
    {
        return error.MalformedCounterChannel;
    }
    const coverage = contract.CoverageState{
        .observation_off = .{ .report = false, .object = false, .owner = false },
        .observation_on = .{ .report = true, .object = true, .owner = true },
        .on_channel_producers = .{ 1, 1, 1 },
        .unexpected_family_events = 0,
        .argument_index_overflow_events = 0,
        .report = report_channel.families,
        .object = object_channel.families,
        .owner = owner_channel.families,
    };
    try contract.validateCoverage(coverage);
    const canonical_semantic = contract.SemanticIdentity{
        .report = repetitions[0].report,
        .object = repetitions[0].object,
        .owner = repetitions[0].owner,
    };
    const semantic_equality = contract.SemanticEquality{
        .canonical = canonical_semantic,
        .observation_off = off.semantic,
        .observation_on = on.semantic,
    };
    if (!std.mem.eql(u8, &repetitions[0].function_manifest, &off.function_manifest) or
        !std.mem.eql(u8, &repetitions[0].function_manifest, &on.function_manifest))
    {
        return error.ResultDrift;
    }
    try contract.validateSemanticEquality(semantic_equality);
    try phases.succeed(.coverage_finalize);

    const repository_after = try observeRepository(
        init.gpa,
        init.io,
        subjects.git,
        cli.repository,
        cli.registered_worktrees,
    );
    const canonical_after = try observeRepository(
        init.gpa,
        init.io,
        subjects.git,
        cli.canonical_source,
        cli.registered_worktrees,
    );
    const coverage_after = try observeRepository(
        init.gpa,
        init.io,
        subjects.git,
        cli.coverage_source,
        cli.registered_worktrees,
    );
    const coverage_status_after = try observeRepositoryStatus(
        init.gpa,
        init.io,
        subjects.git,
        cli.coverage_source,
        cli.registered_worktrees,
    );
    defer init.gpa.free(coverage_status_after.stdout);
    defer init.gpa.free(coverage_status_after.stderr);
    if (coverage_status_after.stderr.len != 0 or
        !std.mem.eql(u8, coverage_status_before.stdout, coverage_status_after.stdout))
    {
        return error.GitObservationMismatch;
    }
    try validateCoverageStatus(coverage_status_after.stdout, touched_paths);
    const canonical_manifest_after = try verifySourceManifest(
        init.gpa,
        init.io,
        cli.canonical_source,
        baseline_manifest,
        cli.registered_worktrees,
    );
    const coverage_manifest_after = try verifySourceManifest(
        init.gpa,
        init.io,
        cli.coverage_source,
        bundled_manifest,
        cli.registered_worktrees,
    );
    const external_after = try observeRepository(
        init.gpa,
        init.io,
        subjects.git,
        cli.external_zig_repository,
        cli.registered_worktrees,
    );
    const inputs_after = try authenticateInputs(init.gpa, init.io, cli);
    if (!std.meta.eql(inputs_before, inputs_after)) return error.InputIdentityMismatch;
    const bundle_manifest_after = try readBoundedAbsolute(
        init.gpa,
        init.io,
        bundle_manifest_path,
        maximum_input_bytes,
    );
    defer init.gpa.free(bundle_manifest_after);
    if (!std.mem.eql(u8, bundle_manifest, bundle_manifest_after))
        return error.InputIdentityMismatch;
    try verifyCompatibilityBundleMembers(
        init.gpa,
        init.io,
        cli.bundle_root,
        bundle_manifest_after,
        cli.registered_worktrees,
    );
    if (!std.meta.eql(repository_before, repository_after) or
        !std.meta.eql(canonical_before, canonical_after) or
        !std.meta.eql(coverage_before, coverage_after) or
        !std.meta.eql(external_before, external_after) or
        !std.mem.eql(u8, &canonical_manifest_identity, &canonical_manifest_after) or
        !std.mem.eql(u8, &coverage_manifest_identity, &coverage_manifest_after))
    {
        return error.RestorationMismatch;
    }
    try requireSubjectStable(init.io, subjects.zig, cli.registered_worktrees);
    try requireSubjectStable(init.io, subjects.git, cli.registered_worktrees);
    try requireSubjectStable(init.io, subjects.llvm_extract, cli.registered_worktrees);
    try requireSubjectStable(init.io, subjects.objcopy, cli.registered_worktrees);
    try requireSubjectStable(init.io, subjects.objdump, cli.registered_worktrees);
    try requireSubjectStable(init.io, subjects.readelf, cli.registered_worktrees);
    const registered_worktree_set_after = try observeRegisteredWorktreeSet(
        init.gpa,
        init.io,
        subjects.git,
        cli.repository,
        supplied_cli.registered_worktrees,
    );
    if (!std.meta.eql(registered_worktree_set, registered_worktree_set_after))
        return error.WorktreeSetMismatch;
    try runZigVersion(init.gpa, init.io, subjects.zig, cli.repository, cli.registered_worktrees);
    try requireSubjectStable(init.io, canonical_artifact, cli.registered_worktrees);
    try requireSubjectStable(init.io, coverage_artifact, cli.registered_worktrees);
    const accepted_after = try observeFile(
        init.io,
        paths.accepted,
        false,
        maximum_input_bytes,
        cli.registered_worktrees,
    );
    const after = makeRestorationIdentity(
        repository_after,
        canonical_after,
        coverage_after,
        accepted_after,
    );
    try requireRestorationEqual(before, after);
    try phases.succeed(.restoration);
    try phases.succeed(.complete);

    const restoration = contract.RestorationState{
        .head_before = contract.source_commit,
        .head_after = contract.source_commit,
        .tracked_manifest_before = before.canonical_source,
        .tracked_manifest_after = after.canonical_source,
        .clean = canonical_after.clean,
        .observer_source_absent = canonical_after.clean,
        .ratchet = contract.bypass_ratchet,
    };
    const observation = CompleteRunObservation{
        .identities = &contract.closed_identities,
        .compatibility_keys = &contract.compatibility_keys,
        .repetitions = &repetitions,
        .coverage = coverage,
        .restoration = restoration,
        .semantic_equality = semantic_equality,
        .phases = phases,
        .family_usage = &usage,
        .available_bytes = available_bytes,
        .before = before,
        .after = after,
    };
    const prepublication = try validateCompleteRun(observation);
    var closure_binding = ClosureBinding{
        .tools = subjects,
        .fixed_sources = digestSourceIdentityBinding(.{
            .repository = repository_before,
            .external_zig = external_before,
            .canonical = canonical_before,
            .coverage = coverage_before,
            .canonical_manifest = canonical_manifest_identity,
            .coverage_manifest = coverage_manifest_identity,
        }),
        .fixed_inputs = digestInputSet(inputs_before),
        .canonical_artifact = canonical_artifact.identity,
        .coverage_artifact = coverage_artifact.identity,
        .canonical_observations = digestCanonicalObservations(&repetitions),
        .coverage_off_observation = digestObservationIdentity(off),
        .coverage_on_observation = digestObservationIdentity(on),
        .counter_result = digestCoverageResult(coverage),
        .registered_worktrees = registered_worktree_set,
        .family_usage = digestFamilyUsage(&usage),
        .completion = true,
    };
    _ = try scanRootBounded(
        init.io,
        paths.root,
        contract.accepted_maximum_storage_bytes,
        cli.registered_worktrees,
    );
    const preview = try encodeClosure(init.gpa, prepublication, closure_binding);
    defer init.gpa.free(preview);
    try accountFamilyBytes(&usage, .publication_evidence, preview.len);
    try accountFamilyBytes(&usage, .durability_terminal, @sizeOf(PublishedClosure));
    const validated = try validateCompleteRun(observation);
    closure_binding.family_usage = digestFamilyUsage(&usage);
    const encoded = try encodeClosure(init.gpa, validated, closure_binding);
    defer init.gpa.free(encoded);
    if (encoded.len != preview.len) return error.ResultDrift;
    _ = try publishClosure(init.gpa, validation_root, init.io, encoded);
    _ = try scanRootBounded(
        init.io,
        paths.root,
        contract.accepted_maximum_storage_bytes,
        cli.registered_worktrees,
    );
}

fn validateSourceAcceptanceTools(tools: SourceAcceptanceToolSet) RunnerError!void {
    inline for (.{
        .{ tools.zig, ToolRole.zig },
        .{ tools.git, ToolRole.git },
    }) |entry| {
        const tool = entry[0];
        const role = entry[1];
        const portable = tool.portable_tool orelse return error.SubjectAuthorityMismatch;
        if (portable.role != role or portable.bytes != tool.identity.bytes or
            !std.mem.eql(u8, &portable.sha256, &tool.identity.sha256) or
            ((role == .zig) != (portable.version != null)))
        {
            return error.SubjectAuthorityMismatch;
        }
    }
}

fn sourceAcceptanceGateResult(
    gate: SourceAcceptanceGate,
    captured: CapturedResult,
) RunnerError!SourceAcceptanceGateResult {
    try validateCapturedResult(captured);
    const status = switch (captured.termination) {
        .exited => |value| value,
        else => return error.GateResultMismatch,
    };
    if (status != 0) return error.GateResultMismatch;
    return .{
        .gate = gate,
        .exit_status = status,
        .stdout_bytes = captured.stdout.len,
        .stdout_sha256 = sha256(captured.stdout),
        .stderr_bytes = captured.stderr.len,
        .stderr_sha256 = sha256(captured.stderr),
    };
}

fn validateSourceAcceptanceGateSequence(
    gates: []const SourceAcceptanceGateResult,
) RunnerError!void {
    if (gates.len != @typeInfo(SourceAcceptanceGate).@"enum".fields.len)
        return error.GateOrderMismatch;
    for (gates, 0..) |gate, index| {
        const expected: SourceAcceptanceGate = @enumFromInt(index + 1);
        if (gate.gate != expected) return error.GateOrderMismatch;
        if (gate.exit_status != 0 or gate.stdout_bytes > process_capture_max or
            gate.stderr_bytes > process_capture_max)
        {
            return error.GateResultMismatch;
        }
    }
}

fn validateSourceAcceptanceEvidence(evidence: SourceAcceptanceEvidence) RunnerError!void {
    try validateSourceAcceptanceTools(evidence.tools);
    if (!evidence.completion or evidence.snapshot.contract_source.mode != 0o100644 or
        evidence.snapshot.runner_source.mode != 0o100644 or
        evidence.snapshot.contract_source.bytes == 0 or evidence.snapshot.runner_source.bytes == 0)
    {
        return error.ClosurePrecondition;
    }
    try validateSourceAcceptanceGateSequence(&evidence.gates);
}

fn encodeSourceAcceptance(
    allocator: std.mem.Allocator,
    evidence: SourceAcceptanceEvidence,
) ![]u8 {
    try validateSourceAcceptanceEvidence(evidence);
    var output: std.Io.Writer.Allocating = .init(allocator);
    errdefer output.deinit();
    try output.writer.print("schema\t{s}\nparent\t{s}\n", .{
        source_acceptance_schema,
        &evidence.snapshot.parent,
    });
    inline for (.{
        .{ contract_source_relative, evidence.snapshot.contract_source },
        .{ runner_source_relative, evidence.snapshot.runner_source },
    }) |entry| {
        const identity = entry[1];
        const blob_hex = std.fmt.bytesToHex(identity.blob, .lower);
        const raw_hex = std.fmt.bytesToHex(identity.raw_sha256, .lower);
        try output.writer.print("source\t{s}\t100644\t{d}\t{s}\t{s}\n", .{
            entry[0],
            identity.bytes,
            &blob_hex,
            &raw_hex,
        });
    }
    inline for (.{
        evidence.tools.zig,
        evidence.tools.git,
    }) |tool| {
        const portable = tool.portable_tool orelse return error.SubjectAuthorityMismatch;
        const digest_hex = std.fmt.bytesToHex(portable.sha256, .lower);
        try output.writer.print("tool\t{s}\t{d}\t{s}\t{s}\n", .{
            toolRoleName(portable.role),
            portable.bytes,
            &digest_hex,
            portable.version orelse "-",
        });
    }
    for (evidence.gates) |gate| {
        const stdout_hex = std.fmt.bytesToHex(gate.stdout_sha256, .lower);
        const stderr_hex = std.fmt.bytesToHex(gate.stderr_sha256, .lower);
        try output.writer.print("gate\t{d}\t{d}\t{d}\t{s}\t{d}\t{s}\n", .{
            @intFromEnum(gate.gate),
            gate.exit_status,
            gate.stdout_bytes,
            &stdout_hex,
            gate.stderr_bytes,
            &stderr_hex,
        });
    }
    try output.writer.writeAll("completion\tcomplete\n");
    if (output.writer.end > closure_max) {
        output.deinit();
        return error.ClosureTooLarge;
    }
    return output.toOwnedSlice();
}

fn verifySourceAcceptanceReadBack(expected: []const u8, actual: []const u8) RunnerError!void {
    if (!std.mem.eql(u8, expected, actual)) return error.SourceAcceptanceReadBackMismatch;
}

fn publishSourceAcceptance(
    allocator: std.mem.Allocator,
    directory: std.Io.Dir,
    io: std.Io,
    encoded: []const u8,
) !PublishedClosure {
    if (encoded.len == 0 or encoded.len > closure_max) return error.ClosureTooLarge;
    var temporary = directory.createFile(io, source_acceptance_temporary_name, .{
        .read = false,
        .truncate = false,
        .exclusive = true,
        .resolve_beneath = true,
    }) catch |failure| switch (failure) {
        error.PathAlreadyExists => return error.SourceAcceptanceCollision,
        else => return failure,
    };
    var temporary_open = true;
    var temporary_exists = true;
    var final_published = false;
    defer if (temporary_open) temporary.close(io);
    errdefer {
        if (temporary_exists) {
            directory.deleteFile(io, source_acceptance_temporary_name) catch {};
        } else if (final_published) {
            directory.deleteFile(io, source_acceptance_name) catch {};
            syncOwnedDirectory(directory, io) catch {};
        }
    }
    try temporary.writeStreamingAll(io, encoded);
    try temporary.sync(io);
    temporary.close(io);
    temporary_open = false;
    directory.renamePreserve(
        source_acceptance_temporary_name,
        directory,
        source_acceptance_name,
        io,
    ) catch |failure| switch (failure) {
        error.PathAlreadyExists => return error.SourceAcceptanceCollision,
        else => return failure,
    };
    temporary_exists = false;
    final_published = true;
    try syncOwnedDirectory(directory, io);
    const final = try directory.openFile(io, source_acceptance_name, .{
        .mode = .read_only,
        .follow_symlinks = false,
        .resolve_beneath = true,
    });
    defer final.close(io);
    const metadata = try final.stat(io);
    if (metadata.kind != .file or metadata.size != encoded.len)
        return error.SourceAcceptanceReadBackMismatch;
    const read_back = try allocator.alloc(u8, encoded.len);
    defer allocator.free(read_back);
    const count = try final.readPositional(io, &.{read_back}, 0);
    if (count != encoded.len) return error.SourceAcceptanceReadBackMismatch;
    var extra: [1]u8 = undefined;
    if (try final.readPositional(io, &.{&extra}, count) != 0)
        return error.SourceAcceptanceReadBackMismatch;
    try verifySourceAcceptanceReadBack(encoded, read_back);
    final_published = false;
    return .{ .bytes = @intCast(encoded.len), .sha256 = sha256(encoded) };
}

const SourceAcceptanceCachePaths = struct {
    root: []const u8,
    local: []const u8,
    global: []const u8,
    home: []const u8,
    temporary: []const u8,
};

fn prepareSourceAcceptanceCache(
    allocator: std.mem.Allocator,
    io: std.Io,
    repository: []const u8,
) !SourceAcceptanceCachePaths {
    const relative_root = "local-state/caches/inbox206cy/source-acceptance";
    const root = try joinAbsolute(allocator, repository, relative_root);
    const local = try joinAbsolute(allocator, root, "local");
    const global = try joinAbsolute(allocator, root, "global");
    const home = try joinAbsolute(allocator, root, "home");
    const temporary = try joinAbsolute(allocator, root, "tmp");
    inline for (.{
        relative_root,
        relative_root ++ "/local",
        relative_root ++ "/global",
        relative_root ++ "/home",
        relative_root ++ "/tmp",
    }) |relative| {
        const directory = try createRelativeTreeNoFollow(io, repository, relative);
        directory.close(io);
    }
    return .{ .root = root, .local = local, .global = global, .home = home, .temporary = temporary };
}

fn fixedSourceAcceptanceEnvironment(paths: SourceAcceptanceCachePaths) [8]EnvironmentEntry {
    return .{
        .{ .name = "HOME", .value = paths.home },
        .{ .name = "TMPDIR", .value = paths.temporary },
        .{ .name = "ZIG_LOCAL_CACHE_DIR", .value = paths.local },
        .{ .name = "ZIG_GLOBAL_CACHE_DIR", .value = paths.global },
        .{ .name = "LANG", .value = "C" },
        .{ .name = "LC_ALL", .value = "C" },
        .{ .name = "TZ", .value = "UTC0" },
        .{ .name = "SOURCE_DATE_EPOCH", .value = "0" },
    };
}

fn runSourceAcceptanceGateCommand(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig: AuthenticatedSubject,
    repository: []const u8,
    environment: []const EnvironmentEntry,
    gate: SourceAcceptanceGate,
    argv: []const []const u8,
) !SourceAcceptanceGateResult {
    const result = try runAuthenticated(allocator, io, zig, .{
        .executable = zig.path,
        .argv = argv,
        .environment = environment,
        .cwd = repository,
    }, 0, &.{});
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);
    return sourceAcceptanceGateResult(gate, .{
        .termination = processTermination(result.term),
        .stdout = result.stdout,
        .stderr = result.stderr,
        .stdout_complete = true,
        .stderr_complete = true,
    });
}

fn runSourceAcceptanceGate(
    allocator: std.mem.Allocator,
    io: std.Io,
    tools: SourceAcceptanceToolSet,
    cli: SourceAcceptanceCli,
    environment: []const EnvironmentEntry,
    gate: SourceAcceptanceGate,
) !SourceAcceptanceGateResult {
    return switch (gate) {
        .format_check => runSourceAcceptanceGateCommand(
            allocator,
            io,
            tools.zig,
            cli.repository,
            environment,
            gate,
            &.{ tools.zig.path, "fmt", "--check", cli.contract_source, cli.runner_source },
        ),
        .no_libc_compile => runSourceAcceptanceGateCommand(
            allocator,
            io,
            tools.zig,
            cli.repository,
            environment,
            gate,
            &.{ tools.zig.path, "test", cli.runner_source, "-fno-emit-bin", "-I/usr/include/x86_64-linux-gnu", "-I/usr/include" },
        ),
        .focused_contract => runSourceAcceptanceGateCommand(
            allocator,
            io,
            tools.zig,
            cli.repository,
            environment,
            gate,
            &.{ tools.zig.path, "test", cli.contract_source, "--test-filter", "baseline validation" },
        ),
        .focused_runner => runSourceAcceptanceGateCommand(
            allocator,
            io,
            tools.zig,
            cli.repository,
            environment,
            gate,
            &.{ tools.zig.path, "test", cli.runner_source, "-I/usr/include/x86_64-linux-gnu", "-I/usr/include", "--test-filter", "baseline runner" },
        ),
        .full_contract => runSourceAcceptanceGateCommand(
            allocator,
            io,
            tools.zig,
            cli.repository,
            environment,
            gate,
            &.{ tools.zig.path, "test", cli.contract_source },
        ),
        .full_runner => runSourceAcceptanceGateCommand(
            allocator,
            io,
            tools.zig,
            cli.repository,
            environment,
            gate,
            &.{ tools.zig.path, "test", cli.runner_source, "-I/usr/include/x86_64-linux-gnu", "-I/usr/include" },
        ),
    };
}

fn requireSourceAcceptanceStable(
    allocator: std.mem.Allocator,
    io: std.Io,
    tools: SourceAcceptanceToolSet,
    cli: SourceAcceptanceCli,
    expected: SourceAcceptanceSnapshot,
) !void {
    try requireSubjectStable(io, tools.zig, &.{});
    try requireSubjectStable(io, tools.git, &.{});
    const current = try observeSourceAcceptanceSnapshot(allocator, io, tools.git, cli);
    try requireSourceAcceptanceSnapshotStable(expected, current);
}

fn executeSourceAcceptance(init: std.process.Init, cli: SourceAcceptanceCli) !void {
    try validateSourceAcceptanceCliPaths(init.gpa, cli);
    try requireAbsentAbsolute(init.io, cli.output_path);
    const tools = SourceAcceptanceToolSet{
        .zig = try authenticateSubject(init.io, cli.zig, &.{}),
        .git = try authenticateSubject(init.io, cli.git, &.{}),
    };
    try validateSourceAcceptanceTools(tools);
    try runZigVersion(init.gpa, init.io, tools.zig, cli.repository, &.{});
    const initial = try observeSourceAcceptanceSnapshot(init.gpa, init.io, tools.git, cli);
    const cache = try prepareSourceAcceptanceCache(init.gpa, init.io, cli.repository);
    const environment = fixedSourceAcceptanceEnvironment(cache);
    var gates: [@typeInfo(SourceAcceptanceGate).@"enum".fields.len]SourceAcceptanceGateResult = undefined;
    for (&gates, 0..) |*result, index| {
        const gate: SourceAcceptanceGate = @enumFromInt(index + 1);
        result.* = try runSourceAcceptanceGate(
            init.gpa,
            init.io,
            tools,
            cli,
            &environment,
            gate,
        );
        try requireSourceAcceptanceStable(init.gpa, init.io, tools, cli, initial);
    }
    try runZigVersion(init.gpa, init.io, tools.zig, cli.repository, &.{});
    try requireSourceAcceptanceStable(init.gpa, init.io, tools, cli, initial);
    const evidence = SourceAcceptanceEvidence{
        .snapshot = initial,
        .tools = tools,
        .gates = gates,
        .completion = true,
    };
    const encoded = try encodeSourceAcceptance(init.gpa, evidence);
    defer init.gpa.free(encoded);
    const output_directory = try createRelativeTreeNoFollow(
        init.io,
        cli.repository,
        source_acceptance_directory_relative,
    );
    defer output_directory.close(init.io);
    try requireSourceAcceptanceStable(init.gpa, init.io, tools, cli, initial);
    _ = try publishSourceAcceptance(init.gpa, output_directory, init.io, encoded);
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
    if (std.mem.eql(u8, mode, "--run-accepted-baseline")) {
        const cli = try parseBaselineCli(run_init.gpa, &args);
        try executeAcceptedBaseline(run_init, cli);
    } else if (std.mem.eql(u8, mode, "--accept-cy-source")) {
        const cli = try parseSourceAcceptanceCli(&args);
        try executeSourceAcceptance(run_init, cli);
    } else {
        return error.InvalidArguments;
    }
}

comptime {
    if (builtin.zig_version.major != 0 or
        builtin.zig_version.minor != 16 or
        builtin.zig_version.patch != 0)
    {
        @compileError("baseline validation runner requires exact Zig 0.16.0");
    }
    if (builtin.os.tag != .linux or builtin.cpu.arch != .x86_64 or
        @sizeOf(usize) != 8 or @sizeOf(c_long) != 8 or @sizeOf(c_ulong) != 8)
    {
        @compileError("baseline validation capacity requires native Linux x86_64 LP64");
    }
    if (@intFromEnum(std.os.linux.SYS.fstatfs) != 138)
        @compileError("installed Zig Linux fstatfs syscall selection drifted");
    if (!@hasDecl(authoritative_statfs, "struct_statfs"))
        @compileError("installed authoritative struct statfs is unavailable");
    if (@sizeOf(NativeStatfs) != @sizeOf(authoritative_statfs.struct_statfs) or
        @alignOf(NativeStatfs) != @alignOf(authoritative_statfs.struct_statfs))
    {
        @compileError("native statfs size or alignment disagrees with installed sys/statfs.h");
    }
    for (.{
        "f_type",
        "f_bsize",
        "f_blocks",
        "f_bfree",
        "f_bavail",
        "f_files",
        "f_ffree",
        "f_fsid",
        "f_namelen",
        "f_frsize",
        "f_flags",
        "f_spare",
    }) |field| {
        if (@offsetOf(NativeStatfs, field) != @offsetOf(authoritative_statfs.struct_statfs, field))
            @compileError("native statfs field offset disagrees with installed sys/statfs.h");
    }
}

test "baseline runner derives exact native capacity and rejects invalid overflow and insufficient values" {
    const exact = try deriveAvailableBytes(.{
        .block_size = 4096,
        .fragment_size = 1024,
        .blocks = 1000,
        .free_blocks = 500,
        .available_blocks = 400,
    });
    try std.testing.expectEqual(@as(u64, 409_600), exact);
    try std.testing.expectError(error.CapacityFieldsInvalid, deriveAvailableBytes(.{
        .block_size = 0,
        .fragment_size = 1024,
        .blocks = 1000,
        .free_blocks = 500,
        .available_blocks = 400,
    }));
    try std.testing.expectError(error.CapacityFieldsInvalid, deriveAvailableBytes(.{
        .block_size = -1,
        .fragment_size = 1024,
        .blocks = 1000,
        .free_blocks = 500,
        .available_blocks = 400,
    }));
    try std.testing.expectError(error.CapacityFieldsInvalid, deriveAvailableBytes(.{
        .block_size = 4096,
        .fragment_size = 1024,
        .blocks = 100,
        .free_blocks = 101,
        .available_blocks = 50,
    }));
    try std.testing.expectError(error.CapacityFieldsInvalid, deriveAvailableBytes(.{
        .block_size = 4096,
        .fragment_size = 1024,
        .blocks = 100,
        .free_blocks = 50,
        .available_blocks = 51,
    }));
    try std.testing.expectError(error.CapacityOverflow, deriveAvailableBytes(.{
        .block_size = std.math.maxInt(u64),
        .fragment_size = std.math.maxInt(u64),
        .blocks = std.math.maxInt(u64),
        .free_blocks = std.math.maxInt(u64),
        .available_blocks = 2,
    }));
    try std.testing.expectError(
        error.InsufficientCapacity,
        contract.requireMinimumCapacity(contract.minimum_available_bytes - 1),
    );
}

test "baseline runner capacity identity mismatch fails closed" {
    const identity = CapacityRootIdentity{
        .inode = 11,
        .mode = 0o775,
        .kind = .directory,
        .filesystem_id = .{ 3, 7 },
    };
    try requireCapacityRootStable(identity, identity);
    var drifted = identity;
    drifted.inode += 1;
    try std.testing.expectError(error.CapacityRootMismatch, requireCapacityRootStable(identity, drifted));
    drifted = identity;
    drifted.filesystem_id[1] += 1;
    try std.testing.expectError(error.CapacityRootMismatch, requireCapacityRootStable(identity, drifted));
}

test "baseline runner harmlessly observes existing CY cache capacity" {
    var root = try std.Io.Dir.openDirAbsolute(std.testing.io, "/home/oleg/prog/z_llvm/local-state/caches/inbox206cy", .{
        .access_sub_paths = false,
        .iterate = false,
        .follow_symlinks = false,
    });
    defer root.close(std.testing.io);
    const available = try observeAvailableBytes(std.testing.io, root);
    try std.testing.expect(available > 0);
}

test "baseline runner canonical paths reject relative escape symlink alias and registered prefix" {
    const good = [_]PathFact{
        .{ .label = "repository", .supplied = "/repo", .canonical = "/repo", .kind = .directory, .expected_kind = .directory, .is_symlink = false, .identity = 1 },
        .{ .label = "input", .supplied = "/inputs/module.ll", .canonical = "/inputs/module.ll", .kind = .file, .expected_kind = .file, .is_symlink = false, .identity = 2 },
    };
    try validatePathFacts(&good, &.{"/registered"});
    var bad = good;
    bad[1].supplied = "inputs/module.ll";
    try std.testing.expectError(error.RelativePath, validatePathFacts(&bad, &.{}));
    bad = good;
    bad[1].supplied = "/inputs/../inputs/module.ll";
    bad[1].canonical = "/inputs/module.ll";
    try std.testing.expectError(error.NonCanonicalPath, validatePathFacts(&bad, &.{}));
    bad = good;
    bad[1].is_symlink = true;
    try std.testing.expectError(error.SymlinkRejected, validatePathFacts(&bad, &.{}));
    bad = good;
    bad[1].identity = 1;
    try std.testing.expectError(error.PathAlias, validatePathFacts(&bad, &.{}));
    bad = good;
    bad[1].supplied = "/registered/child";
    bad[1].canonical = "/registered/child";
    try std.testing.expectError(error.RegisteredWorktreeRejected, validatePathFacts(&bad, &.{"/registered"}));
}

test "baseline runner binds strict registered worktree metadata as an order independent exact set" {
    var storage: [accepted_registered_worktree_count][64]u8 = undefined;
    const expected = try syntheticWorktreePaths(&storage);
    const canonical = try encodeSyntheticWorktreeMetadata(std.testing.allocator, &expected);
    defer std.testing.allocator.free(canonical);
    const identity = try registeredWorktreeSetIdentity(canonical, &expected);
    try std.testing.expectEqual(@as(u8, accepted_registered_worktree_count), identity.count);
    const exclusions = try registeredWorktreeAccessExclusions(
        std.testing.allocator,
        &expected,
        expected[0],
    );
    defer std.testing.allocator.free(exclusions);
    try std.testing.expectEqual(@as(usize, accepted_registered_worktree_count - 1), exclusions.len);
    for (exclusions) |path| try std.testing.expect(!std.mem.eql(u8, path, expected[0]));

    var reordered = expected;
    std.mem.reverse([]const u8, &reordered);
    const reordered_bytes = try encodeSyntheticWorktreeMetadata(std.testing.allocator, &reordered);
    defer std.testing.allocator.free(reordered_bytes);
    try std.testing.expectEqual(
        identity,
        try registeredWorktreeSetIdentity(reordered_bytes, &expected),
    );

    var duplicate = expected;
    duplicate[duplicate.len - 1] = duplicate[0];
    const duplicate_bytes = try encodeSyntheticWorktreeMetadata(std.testing.allocator, &duplicate);
    defer std.testing.allocator.free(duplicate_bytes);
    try std.testing.expectError(
        error.WorktreeMetadataMalformed,
        registeredWorktreeSetIdentity(duplicate_bytes, &expected),
    );

    const missing_bytes = try encodeSyntheticWorktreeMetadata(
        std.testing.allocator,
        expected[0 .. expected.len - 1],
    );
    defer std.testing.allocator.free(missing_bytes);
    try std.testing.expectError(
        error.WorktreeMetadataMalformed,
        registeredWorktreeSetIdentity(missing_bytes, &expected),
    );

    var substituted = expected;
    substituted[substituted.len - 1] = "/synthetic/registered/substituted";
    const substituted_bytes = try encodeSyntheticWorktreeMetadata(std.testing.allocator, &substituted);
    defer std.testing.allocator.free(substituted_bytes);
    try std.testing.expectError(
        error.WorktreeSetMismatch,
        registeredWorktreeSetIdentity(substituted_bytes, &expected),
    );

    try std.testing.expectError(
        error.WorktreeMetadataMalformed,
        registeredWorktreeSetIdentity(
            "worktree relative\x00HEAD 0000000000000000000000000000000000000000\x00detached\x00\x00",
            &expected,
        ),
    );
    try std.testing.expectError(
        error.WorktreeMetadataMalformed,
        registeredWorktreeSetIdentity(
            "worktree /synthetic/registered/worktree-0\x00garbage\x00\x00",
            &expected,
        ),
    );
}

test "baseline runner source acceptance parses only the exact two staged paths" {
    const valid = try encodeSyntheticCyIndex(
        std.testing.allocator,
        contract_source_relative,
        runner_source_relative,
        "100644",
        null,
    );
    defer std.testing.allocator.free(valid);
    const parsed = try parseExactCyStagedSet(valid);
    try std.testing.expectEqual(@as(u32, 0o100644), parsed.contract_source.mode);
    try std.testing.expectEqual(@as(u8, 'M'), parsed.contract_source.status);
    try std.testing.expectEqual(@as(u8, 'A'), parsed.runner_source.status);

    const missing = try encodeSyntheticCyIndex(
        std.testing.allocator,
        contract_source_relative,
        null,
        "100644",
        null,
    );
    defer std.testing.allocator.free(missing);
    try std.testing.expectError(error.IndexSetMismatch, parseExactCyStagedSet(missing));

    const extra = try encodeSyntheticCyIndex(
        std.testing.allocator,
        contract_source_relative,
        runner_source_relative,
        "100644",
        "tools/unexpected.zig",
    );
    defer std.testing.allocator.free(extra);
    try std.testing.expectError(error.IndexSetMismatch, parseExactCyStagedSet(extra));

    const wrong = try encodeSyntheticCyIndex(
        std.testing.allocator,
        "tools/wrong.zig",
        runner_source_relative,
        "100644",
        null,
    );
    defer std.testing.allocator.free(wrong);
    try std.testing.expectError(error.IndexSetMismatch, parseExactCyStagedSet(wrong));

    const wrong_mode = try encodeSyntheticCyIndex(
        std.testing.allocator,
        contract_source_relative,
        runner_source_relative,
        "100755",
        null,
    );
    defer std.testing.allocator.free(wrong_mode);
    try std.testing.expectError(error.IndexMetadataMalformed, parseExactCyStagedSet(wrong_mode));
    try std.testing.expectError(
        error.IndexMetadataMalformed,
        parseExactCyStagedSet(valid[0 .. valid.len - 1]),
    );

    const parent = [_]u8{'1'} ** 40;
    const cli = SourceAcceptanceCli{
        .zig = undefined,
        .git = undefined,
        .repository = "/repo",
        .expected_parent = parent,
        .contract_source = "/repo/" ++ contract_source_relative,
        .runner_source = "/repo/" ++ runner_source_relative,
        .output_path = "/repo/" ++ source_acceptance_directory_relative ++ "/" ++ source_acceptance_name,
    };
    try validateSourceAcceptanceCliPaths(std.testing.allocator, cli);
    var wrong_output = cli;
    wrong_output.output_path = "/repo/local-state/validations/inbox206cy/wrong.tsv";
    try std.testing.expectError(
        error.PathEscape,
        validateSourceAcceptanceCliPaths(std.testing.allocator, wrong_output),
    );
}

test "baseline runner source acceptance proves staged worktree identity and parent" {
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    const io = std.testing.io;
    const source = "const accepted: u8 = 1;\n";
    try temporary.dir.writeFile(io, .{ .sub_path = "source.zig", .data = source });
    var root_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const root_length = try temporary.dir.realPath(io, &root_buffer);
    const absolute = try std.fmt.allocPrint(
        std.testing.allocator,
        "{s}/source.zig",
        .{root_buffer[0..root_length]},
    );
    defer std.testing.allocator.free(absolute);
    const staged = ParsedStagedEntry{
        .path = contract_source_relative,
        .mode = 0o100644,
        .blob = gitBlobIdentity(source),
        .status = 'M',
    };
    const identity = try observeStagedSource(std.testing.allocator, io, absolute, staged);
    try std.testing.expectEqual(@as(u64, source.len), identity.bytes);
    var wrong_blob = staged;
    wrong_blob.blob[0] ^= 1;
    try std.testing.expectError(
        error.StagedSourceMismatch,
        observeStagedSource(std.testing.allocator, io, absolute, wrong_blob),
    );
    const parent = [_]u8{'1'} ** 40;
    try requireExpectedParent(parent, parent);
    var wrong_parent = parent;
    wrong_parent[0] = '2';
    try std.testing.expectError(error.ParentIdentityMismatch, requireExpectedParent(parent, wrong_parent));
}

test "baseline runner source acceptance gates fail closed and preserve exact ordering" {
    const success = CapturedResult{
        .termination = .{ .exited = 0 },
        .stdout = "ok\x00binary",
        .stderr = "",
        .stdout_complete = true,
        .stderr_complete = true,
    };
    const accepted = try sourceAcceptanceGateResult(.format_check, success);
    try std.testing.expectEqual(SourceAcceptanceGate.format_check, accepted.gate);
    var failed = success;
    failed.termination = .{ .exited = 1 };
    try std.testing.expectError(error.ChildFailed, sourceAcceptanceGateResult(.format_check, failed));
    failed.termination = .{ .signal = 9 };
    try std.testing.expectError(error.ChildFailed, sourceAcceptanceGateResult(.format_check, failed));
    failed = success;
    failed.stdout_complete = false;
    try std.testing.expectError(error.IncompleteCapture, sourceAcceptanceGateResult(.format_check, failed));
    const oversized = try std.testing.allocator.alloc(u8, process_capture_max + 1);
    defer std.testing.allocator.free(oversized);
    failed = success;
    failed.stderr = oversized;
    try std.testing.expectError(error.ChildOutputOverflow, sourceAcceptanceGateResult(.format_check, failed));

    var evidence = syntheticSourceAcceptanceEvidence();
    try validateSourceAcceptanceGateSequence(&evidence.gates);
    std.mem.swap(SourceAcceptanceGateResult, &evidence.gates[0], &evidence.gates[1]);
    try std.testing.expectError(error.GateOrderMismatch, validateSourceAcceptanceGateSequence(&evidence.gates));
}

test "baseline runner source acceptance detects between gate source and tool drift" {
    const evidence = syntheticSourceAcceptanceEvidence();
    try requireSourceAcceptanceSnapshotStable(evidence.snapshot, evidence.snapshot);
    var changed_source = evidence.snapshot;
    changed_source.runner_source.raw_sha256[0] ^= 1;
    try std.testing.expectError(
        error.StagedSourceMismatch,
        requireSourceAcceptanceSnapshotStable(evidence.snapshot, changed_source),
    );
    var changed_tool = evidence;
    changed_tool.tools.zig.identity.sha256[0] ^= 1;
    try std.testing.expectError(error.SubjectAuthorityMismatch, validateSourceAcceptanceEvidence(changed_tool));
}

test "baseline runner source acceptance encoding publication and readback are fail closed" {
    const evidence = syntheticSourceAcceptanceEvidence();
    const encoded = try encodeSourceAcceptance(std.testing.allocator, evidence);
    defer std.testing.allocator.free(encoded);
    const repeated = try encodeSourceAcceptance(std.testing.allocator, evidence);
    defer std.testing.allocator.free(repeated);
    try std.testing.expectEqualStrings(encoded, repeated);
    try std.testing.expect(std.mem.startsWith(u8, encoded, "schema\t" ++ source_acceptance_schema ++ "\n"));
    try std.testing.expect(std.mem.indexOf(u8, encoded, "zllvm_artifact_store") == null);

    var incomplete = evidence;
    incomplete.completion = false;
    try std.testing.expectError(
        error.ClosurePrecondition,
        encodeSourceAcceptance(std.testing.allocator, incomplete),
    );

    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    const published = try publishSourceAcceptance(
        std.testing.allocator,
        temporary.dir,
        std.testing.io,
        encoded,
    );
    try std.testing.expectEqual(@as(u64, @intCast(encoded.len)), published.bytes);
    try std.testing.expectError(
        error.SourceAcceptanceCollision,
        publishSourceAcceptance(std.testing.allocator, temporary.dir, std.testing.io, encoded),
    );
    try std.testing.expectError(
        error.SourceAcceptanceReadBackMismatch,
        verifySourceAcceptanceReadBack("one", "two"),
    );
}

test "baseline runner authenticates explicit portable tool tuples and rejects authority drift" {
    const io = std.testing.io;
    const path = "/home/oleg/.zig/0.16.0/files/zig";
    const identity = try observeFile(io, path, true, maximum_artifact_bytes, &.{});
    const selector = ToolSelector{
        .role = .zig,
        .path = path,
        .authorized_bytes = identity.bytes,
        .authorized_sha256 = identity.sha256,
        .authorized_version = expected_zig_version,
    };
    const subject = try authenticateSubject(io, selector, &.{});
    try validateToolBindings(.{
        .zig = subject,
        .git = syntheticTool(.git, 2),
        .llvm_extract = syntheticTool(.llvm_extract, 3),
        .objcopy = syntheticTool(.objcopy, 4),
        .objdump = syntheticTool(.objdump, 5),
        .readelf = syntheticTool(.readelf, 6),
    });
    var wrong_length = selector;
    wrong_length.authorized_bytes += 1;
    try std.testing.expectError(error.SubjectIdentityMismatch, authenticateSubject(io, wrong_length, &.{}));
    var wrong_digest = selector;
    wrong_digest.authorized_sha256[0] ^= 1;
    try std.testing.expectError(error.SubjectIdentityMismatch, authenticateSubject(io, wrong_digest, &.{}));
    var wrong_version = selector;
    wrong_version.authorized_version = "0.15.2";
    try std.testing.expectError(error.SubjectAuthorityMismatch, authenticateSubject(io, wrong_version, &.{}));
}

test "baseline runner real path admission rejects symlink wrong kind alias spelling and protected prefix" {
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    const io = std.testing.io;
    try temporary.dir.writeFile(io, .{ .sub_path = "input.ll", .data = "synthetic\n" });
    try temporary.dir.createDir(io, "root", .default_dir);
    try temporary.dir.symLink(io, "root", "root-link", .{ .is_directory = true });
    var root_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const root_length = try temporary.dir.realPath(io, &root_buffer);
    const root = root_buffer[0..root_length];
    const input = try std.fmt.allocPrint(std.testing.allocator, "{s}/input.ll", .{root});
    defer std.testing.allocator.free(input);
    const directory = try std.fmt.allocPrint(std.testing.allocator, "{s}/root", .{root});
    defer std.testing.allocator.free(directory);
    const link = try std.fmt.allocPrint(std.testing.allocator, "{s}/root-link", .{root});
    defer std.testing.allocator.free(link);
    const alias = try std.fmt.allocPrint(std.testing.allocator, "{s}//input.ll", .{root});
    defer std.testing.allocator.free(alias);

    _ = try validateExplicitPath(io, input, .file, &.{});
    _ = try validateExplicitPath(io, directory, .directory, &.{});
    try std.testing.expectError(error.WrongPathKind, validateExplicitPath(io, input, .directory, &.{}));
    try std.testing.expectError(error.SymlinkRejected, validateExplicitPath(io, link, .directory, &.{}));
    try std.testing.expectError(error.NonCanonicalPath, validateExplicitPath(io, alias, .file, &.{}));
    try std.testing.expectError(error.RegisteredWorktreeRejected, validateExplicitPath(io, input, .file, &.{root}));
}

test "baseline runner fixed command rejects executable argv environment and cwd drift" {
    const argv = [_][]const u8{ "/zig", "version" };
    const environment = [_]EnvironmentEntry{.{ .name = "LC_ALL", .value = "C" }};
    const expected = FixedCommand{ .executable = "/zig", .argv = &argv, .environment = &environment, .cwd = "/repo" };
    var request = ProcessRequest{ .executable = "/zig", .argv = &argv, .environment = &environment, .cwd = "/repo" };
    try validateFixedCommand(request, expected);
    request.executable = "zig";
    try std.testing.expectError(error.RelativePath, validateFixedCommand(request, expected));
    request = .{ .executable = "/other", .argv = &argv, .environment = &environment, .cwd = "/repo" };
    try std.testing.expectError(error.WrongExecutable, validateFixedCommand(request, expected));
    const wrong_argv = [_][]const u8{ "/zig", "env" };
    request = .{ .executable = "/zig", .argv = &wrong_argv, .environment = &environment, .cwd = "/repo" };
    try std.testing.expectError(error.WrongArguments, validateFixedCommand(request, expected));
    const wrong_environment = [_]EnvironmentEntry{.{ .name = "LC_ALL", .value = "en_US" }};
    request = .{ .executable = "/zig", .argv = &argv, .environment = &wrong_environment, .cwd = "/repo" };
    try std.testing.expectError(error.WrongEnvironment, validateFixedCommand(request, expected));
    request = .{ .executable = "/zig", .argv = &argv, .environment = &environment, .cwd = "/other" };
    try std.testing.expectError(error.WrongWorkingDirectory, validateFixedCommand(request, expected));
}

test "baseline runner capture validates success overflow status abnormal completeness and consistency" {
    const success = CapturedResult{ .termination = .{ .exited = 0 }, .stdout = "ok\n", .stderr = "", .stdout_complete = true, .stderr_complete = true };
    try validateCapturedResult(success);
    var bad = success;
    bad.termination = .{ .exited = 1 };
    try std.testing.expectError(error.ChildFailed, validateCapturedResult(bad));
    bad.termination = .{ .signal = 9 };
    try std.testing.expectError(error.ChildFailed, validateCapturedResult(bad));
    bad = success;
    bad.stdout_complete = false;
    try std.testing.expectError(error.IncompleteCapture, validateCapturedResult(bad));
    const oversized = try std.testing.allocator.alloc(u8, process_capture_max + 1);
    defer std.testing.allocator.free(oversized);
    bad = success;
    bad.stdout = oversized;
    try std.testing.expectError(error.ChildOutputOverflow, validateCapturedResult(bad));
    bad = success;
    bad.stdout = "different\n";
    try std.testing.expectError(error.InconsistentResult, requireConsistentResult(success, bad));
}

test "baseline runner invokes one harmless absolute Zig command with bounded closed capture" {
    const environment = [_]EnvironmentEntry{
        .{ .name = "LANG", .value = "C" },
        .{ .name = "LC_ALL", .value = "C" },
        .{ .name = "TZ", .value = "UTC0" },
    };
    const argv = [_][]const u8{ "/home/oleg/.zig/0.16.0/files/zig", "version" };
    const result = try runBounded(std.testing.allocator, std.testing.io, .{
        .executable = argv[0],
        .argv = &argv,
        .environment = &environment,
        .cwd = "/home/oleg/prog/z_llvm",
    });
    defer std.testing.allocator.free(result.stdout);
    defer std.testing.allocator.free(result.stderr);
    try std.testing.expectEqualStrings("0.16.0\n", result.stdout);
    try std.testing.expectEqual(@as(usize, 0), result.stderr.len);
}

test "baseline runner bounded file capture authenticates subject and exact output" {
    const io = std.testing.io;
    const zig_path = "/home/oleg/.zig/0.16.0/files/zig";
    const subject = try authenticateGeneratedSubject(io, zig_path, &.{});
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    var root_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const root_length = try temporary.dir.realPath(io, &root_buffer);
    const root = root_buffer[0..root_length];
    const output_path = try std.fmt.allocPrint(std.testing.allocator, "{s}/version.stdout", .{root});
    defer std.testing.allocator.free(output_path);
    const environment = fixedEnvironment(root, root);
    const argv = [_][]const u8{ zig_path, "version" };
    const result = try runAuthenticatedToFile(
        std.testing.allocator,
        io,
        subject,
        .{ .executable = zig_path, .argv = &argv, .environment = &environment, .cwd = root },
        output_path,
        64,
        0,
        &.{},
    );
    defer result.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 0), result.stderr.len);
    const output = try readBoundedAbsolute(std.testing.allocator, io, output_path, 64);
    defer std.testing.allocator.free(output);
    try std.testing.expectEqualStrings("0.16.0\n", output);
}

test "baseline runner parses canonical report summary and rejects result drift" {
    const summary =
        "zllvm-codegen-failure function=bad diagnostic=x selector_tag=y selector_detail=z\n" ++
        "summary zllvm-codegen-report-all selected_functions=286 emitted_functions=285 failed_functions=1 local_fail=1 first_failure=bad first_diagnostic=x\n";
    try validateReportSummary(summary, 1);
    try std.testing.expectError(error.ParseFailure, validateReportSummary(summary, 2));
    try std.testing.expectError(
        error.ParseFailure,
        validateReportSummary(
            "summary zllvm-codegen-report-all selected_functions=286 emitted_functions=284 failed_functions=2 local_fail=1 first_failure=bad first_diagnostic=x\n",
            2,
        ),
    );
}

test "baseline runner coverage status is exactly the authenticated touched set" {
    const touched = "src/a.zig\nsrc/b.zig\n";
    try validateCoverageStatus(" M src/a.zig\x00?? src/b.zig\x00", touched);
    try std.testing.expectError(
        error.GitObservationMismatch,
        validateCoverageStatus(" M src/a.zig\x00", touched),
    );
    try std.testing.expectError(
        error.GitObservationMismatch,
        validateCoverageStatus(" M src/a.zig\x00?? src/c.zig\x00", touched),
    );
    try std.testing.expectError(
        error.GitObservationMismatch,
        validateCoverageStatus("R  src/a.zig\x00?? src/b.zig\x00", touched),
    );
}

test "baseline runner manifest parser rejects malformed and escaping identities" {
    const valid = "00" ** 32 ++ "  src/a.zig";
    const parsed = try parseManifestLine(valid);
    try std.testing.expectEqualStrings("src/a.zig", parsed.path);
    try std.testing.expectError(error.ManifestMismatch, parseManifestLine("00  src/a.zig"));
    try std.testing.expectError(
        error.ManifestMismatch,
        parseManifestLine("00" ** 32 ++ "  ../escape"),
    );
    try std.testing.expectError(
        error.ManifestMismatch,
        parseManifestLine("00" ** 32 ++ "  /absolute"),
    );
}

test "baseline runner function manifest hashes exact bounded ranges" {
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    const io = std.testing.io;
    try temporary.dir.writeFile(io, .{ .sub_path = "text.bin", .data = "abcdef" });
    var root_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const root_length = try temporary.dir.realPath(io, &root_buffer);
    const text_path = try std.fmt.allocPrint(
        std.testing.allocator,
        "{s}/text.bin",
        .{root_buffer[0..root_length]},
    );
    defer std.testing.allocator.free(text_path);
    const rows = [_]FunctionRow{
        .{ .name = "first", .value = 0, .size = 3 },
        .{ .name = "second", .value = 3, .size = 3 },
    };
    const manifest = try encodeFunctionManifest(std.testing.allocator, io, text_path, 6, &rows);
    defer std.testing.allocator.free(manifest);
    try std.testing.expect(std.mem.startsWith(u8, manifest, "name\tvalue_hex\tbytes\tsha256\nfirst\t0\t3\t"));
    var invalid = rows;
    invalid[1].size = 4;
    try std.testing.expectError(
        error.ParseFailure,
        encodeFunctionManifest(std.testing.allocator, io, text_path, 6, &invalid),
    );
}

test "baseline runner parses readelf text section and objdump function ownership" {
    try validateReadelfSections("  [ 1] .text PROGBITS 000000 000040\n");
    try std.testing.expectError(error.ParseFailure, validateReadelfSections("[ 1] .data PROGBITS\n"));
    try std.testing.expectError(
        error.ParseFailure,
        validateReadelfSections("[ 1] .text NOBITS\n"),
    );
    const rows = [_]FunctionRow{
        .{ .name = "alpha", .value = 0, .size = 1 },
        .{ .name = "beta", .value = 1, .size = 1 },
    };
    try validateObjdumpFunctions("0000 <alpha>:\n0001 <beta>:\n", &rows);
    try std.testing.expectError(
        error.ParseFailure,
        validateObjdumpFunctions("0000 <alpha>:\n", &rows),
    );
}

test "baseline runner process spawn failure is fail closed" {
    const environment = [_]EnvironmentEntry{.{ .name = "LC_ALL", .value = "C" }};
    const argv = [_][]const u8{ "/definitely-absent-inbox206cy-executable", "version" };
    try std.testing.expectError(error.SpawnFailed, runBounded(std.testing.allocator, std.testing.io, .{
        .executable = argv[0],
        .argv = &argv,
        .environment = &environment,
        .cwd = "/home/oleg/prog/z_llvm",
    }));
}

test "baseline runner enforces file root family aggregate and closure ordering" {
    var usage = syntheticFamilyUsage();
    var tracker = try validateStorageRoot(&usage, contract.minimum_available_bytes);
    try std.testing.expectEqual(contract.storage_families.len, tracker.next);
    usage[0].largest_file_bytes = contract.accepted_maximum_storage_bytes + 1;
    try std.testing.expectError(error.FileCapExceeded, validateStorageRoot(&usage, contract.minimum_available_bytes));
    usage = syntheticFamilyUsage();
    usage[0].root_bytes = contract.accepted_maximum_storage_bytes + 1;
    try std.testing.expectError(error.RootCapExceeded, validateStorageRoot(&usage, contract.minimum_available_bytes));
    usage = syntheticFamilyUsage();
    usage[0].retained_bytes = contract.accepted_maximum_storage_bytes + 1;
    try std.testing.expectError(error.FamilyCapExceeded, validateStorageRoot(&usage, contract.minimum_available_bytes));
    usage = syntheticFamilyUsage();
    usage[0].family_id = 2;
    try std.testing.expectError(error.FamilyOutOfOrder, validateStorageRoot(&usage, contract.minimum_available_bytes));
    usage = syntheticFamilyUsage();
    usage[1].family_id = 1;
    try std.testing.expectError(error.FamilyDuplicate, validateStorageRoot(&usage, contract.minimum_available_bytes));
    usage = syntheticFamilyUsage();
    try std.testing.expectError(error.FamilyMissing, validateStorageRoot(usage[0 .. usage.len - 1], contract.minimum_available_bytes));
    usage = syntheticFamilyUsage();
    usage[0].aggregate_exclusions ^= 1;
    try std.testing.expectError(error.AggregateExclusionDrift, validateStorageRoot(&usage, contract.minimum_available_bytes));
    usage = syntheticFamilyUsage();
    usage[0].family_id = 0;
    try std.testing.expectError(error.FamilyUnknown, validateStorageRoot(&usage, contract.minimum_available_bytes));
    var overflowing = FamilyTracker{ .total_retained_bytes = std.math.maxInt(u64) };
    try std.testing.expectError(error.StorageOverflow, overflowing.close(syntheticFamilyUsage()[0]));
    tracker.total_retained_bytes = contract.accepted_maximum_storage_bytes + 1;
    try std.testing.expectError(error.AggregateCapExceeded, tracker.finish());
}

test "baseline runner contract phase counter repetition and first failure rules stay binding" {
    var machine = contract.PhaseMachine.init();
    try std.testing.expectError(error.PhaseOutOfOrder, machine.succeed(.canonical_source));
    try machine.fail(.preflight);
    try std.testing.expectEqual(contract.PhaseStatus.failed, machine.status(.preflight));
    try std.testing.expectEqual(contract.PhaseStatus.suppressed, machine.status(.complete));
    try std.testing.expectError(error.PhaseSuppressed, machine.succeed(.canonical_source));
    try std.testing.expectError(error.RepetitionCountMismatch, contract.validateCanonicalRepetitions(&.{}));
    var compatibility = contract.compatibility_keys;
    compatibility[0] = "wrong";
    try std.testing.expectError(error.CompatibilityKeyDrift, contract.validateCompatibilityKeys(&compatibility));
    try contract.validatePlannedPath(.validation_root, .{ .candidate = contract.plannedPath(.validation_root) });
    try std.testing.expectError(error.PathEscape, contract.validatePlannedPath(.validation_root, .{
        .candidate = "local-state/validations/o2-calls/compiler-rt-v1/wrong",
    }));
    const zero_counters = contract.FamilyCounters{
        .transactions = 0,
        .requests = 0,
        .attachments = 0,
        .stages = 0,
        .materializations = 0,
        .actions = 0,
        .commits = 0,
        .position_requests = [_]u64{0} ** 6,
        .position_stages = [_]u64{0} ** 6,
    };
    try std.testing.expectError(error.CounterViolation, contract.validateCoverage(.{
        .observation_off = .{ .report = false, .object = false, .owner = false },
        .observation_on = .{ .report = true, .object = true, .owner = true },
        .on_channel_producers = .{ 1, 1, 1 },
        .unexpected_family_events = 0,
        .argument_index_overflow_events = 0,
        .report = .{ .direct_call = zero_counters, .int_byte_size_call = zero_counters },
        .object = .{ .direct_call = zero_counters, .int_byte_size_call = zero_counters },
        .owner = .{ .direct_call = zero_counters, .int_byte_size_call = zero_counters },
    }));
}

test "baseline runner parses exact coverage counters and rejects malformed duplicate and incomplete channels" {
    const channel =
        "schema\to2_calls_crt_v1_coverage_v1\n" ++
        "direct_call\t2\t3\t2\t3\t2\t2\t2\n" ++
        "direct_call\t0\t2\t2\n" ++
        "direct_call\t1\t1\t1\n" ++
        "direct_call\t2\t0\t0\n" ++
        "direct_call\t3\t0\t0\n" ++
        "direct_call\t4\t0\t0\n" ++
        "direct_call\t5\t0\t0\n" ++
        "int_byte_size_call\t2\t2\t2\t2\t2\t2\t2\n" ++
        "int_byte_size_call\t0\t2\t2\n" ++
        "int_byte_size_call\t1\t0\t0\n" ++
        "int_byte_size_call\t2\t0\t0\n" ++
        "int_byte_size_call\t3\t0\t0\n" ++
        "int_byte_size_call\t4\t0\t0\n" ++
        "int_byte_size_call\t5\t0\t0\n" ++
        "unexpected_family_events\t0\n" ++
        "argument_index_overflow_events\t0\n";
    const parsed = try parseCoverageChannel(channel);
    try std.testing.expectEqual(@as(u64, 3), parsed.families.direct_call.requests);
    try std.testing.expectEqual(@as(u64, 2), parsed.families.int_byte_size_call.transactions);
    try std.testing.expectEqual(@as(u64, 0), parsed.unexpected_family_events);
    try std.testing.expectError(error.MalformedCounterChannel, parseCoverageChannel("schema\twrong\n"));
    try std.testing.expectError(
        error.MalformedCounterChannel,
        parseCoverageChannel(channel ++ "schema\to2_calls_crt_v1_coverage_v1\n"),
    );
    const truncated = channel[0 .. channel.len - "argument_index_overflow_events\t0\n".len];
    try std.testing.expectError(error.MalformedCounterChannel, parseCoverageChannel(truncated));
}

test "baseline runner complete evidence suppresses readiness for every missing prerequisite" {
    const families = try contract.acceptedEnforcedStorageFamilies();
    const complete = syntheticCompleteEvidence(&families);
    try std.testing.expectEqual(contract.ExecutionReadiness.ready, try contract.executionReadinessWithEvidence(complete));
    for (0..contract.required_enforcement_prerequisites.len) |missing| {
        var prerequisites: [contract.required_enforcement_prerequisites.len - 1]contract.EnforcementPrerequisite = undefined;
        var prerequisite_target: usize = 0;
        for (contract.required_enforcement_prerequisites, 0..) |value, index| {
            if (index == missing) continue;
            prerequisites[prerequisite_target] = value;
            prerequisite_target += 1;
        }
        var incomplete = complete;
        incomplete.prerequisites = &prerequisites;
        try std.testing.expectEqual(
            contract.ExecutionReadiness.not_ready_storage_enforcement_absent,
            try contract.executionReadinessWithEvidence(incomplete),
        );
    }
}

test "baseline runner closure requires restoration and publishes atomically without overwrite" {
    const restoration = syntheticRestoration(0x31);
    const repetitions = syntheticCanonicalRepetitions();
    const usage = syntheticFamilyUsage();
    const validated = try validateCompleteRun(.{
        .identities = &contract.closed_identities,
        .compatibility_keys = &contract.compatibility_keys,
        .repetitions = &repetitions,
        .coverage = syntheticCoverage(),
        .restoration = syntheticContractRestoration(),
        .semantic_equality = syntheticSemanticEquality(),
        .phases = try syntheticCompletedPhases(),
        .family_usage = &usage,
        .available_bytes = contract.minimum_available_bytes,
        .before = restoration,
        .after = restoration,
    });
    const binding = syntheticClosureBinding();
    const encoded = try encodeClosure(std.testing.allocator, validated, binding);
    defer std.testing.allocator.free(encoded);
    try std.testing.expect(std.mem.startsWith(u8, encoded, "schema\t" ++ schema ++ "\n"));
    const deterministic = try encodeClosure(std.testing.allocator, validated, binding);
    defer std.testing.allocator.free(deterministic);
    try std.testing.expectEqualStrings(encoded, deterministic);

    var evidence_drift = binding;
    evidence_drift.fixed_inputs[0] ^= 1;
    const changed_inputs = try encodeClosure(std.testing.allocator, validated, evidence_drift);
    defer std.testing.allocator.free(changed_inputs);
    try std.testing.expect(!std.mem.eql(u8, encoded, changed_inputs));
    evidence_drift = binding;
    evidence_drift.registered_worktrees.sha256[0] ^= 1;
    const changed_worktrees = try encodeClosure(std.testing.allocator, validated, evidence_drift);
    defer std.testing.allocator.free(changed_worktrees);
    try std.testing.expect(!std.mem.eql(u8, encoded, changed_worktrees));
    evidence_drift = binding;
    evidence_drift.counter_result[0] ^= 1;
    const changed_counters = try encodeClosure(std.testing.allocator, validated, evidence_drift);
    defer std.testing.allocator.free(changed_counters);
    try std.testing.expect(!std.mem.eql(u8, encoded, changed_counters));
    evidence_drift = binding;
    evidence_drift.canonical_artifact.sha256[0] ^= 1;
    const changed_artifact = try encodeClosure(std.testing.allocator, validated, evidence_drift);
    defer std.testing.allocator.free(changed_artifact);
    try std.testing.expect(!std.mem.eql(u8, encoded, changed_artifact));
    evidence_drift = binding;
    evidence_drift.family_usage[0] ^= 1;
    const changed_usage = try encodeClosure(std.testing.allocator, validated, evidence_drift);
    defer std.testing.allocator.free(changed_usage);
    try std.testing.expect(!std.mem.eql(u8, encoded, changed_usage));
    evidence_drift = binding;
    evidence_drift.completion = false;
    try std.testing.expectError(
        error.ClosurePrecondition,
        encodeClosure(std.testing.allocator, validated, evidence_drift),
    );
    evidence_drift = binding;
    evidence_drift.tools.git.portable_tool.?.sha256[0] ^= 1;
    try std.testing.expectError(
        error.SubjectAuthorityMismatch,
        encodeClosure(std.testing.allocator, validated, evidence_drift),
    );
    var drifted = restoration;
    drifted.repository[0] ^= 1;
    var drifted_run = validated;
    drifted_run.after = drifted;
    try std.testing.expectError(
        error.RestorationMismatch,
        encodeClosure(std.testing.allocator, drifted_run, binding),
    );

    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    const io = std.testing.io;
    const first = try publishClosure(std.testing.allocator, temporary.dir, io, encoded);
    try std.testing.expectEqual(@as(u64, @intCast(encoded.len)), first.bytes);
    try std.testing.expectEqual(sha256(encoded), first.sha256);
    try std.testing.expectError(error.ClosureCollision, publishClosure(std.testing.allocator, temporary.dir, io, encoded));
}

test "baseline runner complete validation rejects typed contract drift before closure" {
    const restoration = syntheticRestoration(0x61);
    var repetitions = syntheticCanonicalRepetitions();
    const usage = syntheticFamilyUsage();
    var phases = try syntheticCompletedPhases();
    var observation = CompleteRunObservation{
        .identities = &contract.closed_identities,
        .compatibility_keys = &contract.compatibility_keys,
        .repetitions = &repetitions,
        .coverage = syntheticCoverage(),
        .restoration = syntheticContractRestoration(),
        .semantic_equality = syntheticSemanticEquality(),
        .phases = phases,
        .family_usage = &usage,
        .available_bytes = contract.minimum_available_bytes,
        .before = restoration,
        .after = restoration,
    };
    _ = try validateCompleteRun(observation);
    repetitions[2].function_count -= 1;
    try std.testing.expectError(error.SuccessfulFunctionCountMismatch, validateCompleteRun(observation));
    repetitions = syntheticCanonicalRepetitions();
    phases.statuses[@intFromEnum(contract.Phase.complete)] = .pending;
    observation.phases = phases;
    try std.testing.expectError(error.ClosurePrecondition, validateCompleteRun(observation));
    phases = try syntheticCompletedPhases();
    observation.phases = phases;
    observation.restoration.clean = false;
    try std.testing.expectError(error.RestorationFailure, validateCompleteRun(observation));
    observation.restoration = syntheticContractRestoration();
    observation.semantic_equality.observation_on.report[0] ^= 1;
    try std.testing.expectError(error.SemanticMismatch, validateCompleteRun(observation));
}

test "baseline runner failed precondition leaves no accepted closure and readback drift fails" {
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    try expectNoClosure(temporary.dir, std.testing.io);
    try std.testing.expectError(error.ClosureReadBackMismatch, verifyClosureReadBack("one", "two"));
    try expectNoClosure(temporary.dir, std.testing.io);
}
