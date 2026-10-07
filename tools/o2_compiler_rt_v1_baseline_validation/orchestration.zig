const std = @import("std");
const builtin = @import("builtin");
const contract = @import("../o2_compiler_rt_v1_baseline_validation.zig");
const accepted_subset = @import("accepted_subset.zig");
const raw_report_parser = @import("raw_report.zig");
const process = @import("process.zig");
const authenticated_inputs = @import("authenticated_inputs.zig");
const storage_validation = @import("storage.zig");
const closure_validation = @import("closure.zig");
const authenticated_process = @import("authenticated_process.zig");
const result_validation = @import("result_validation.zig");

const schema = closure_validation.schema;
const source_acceptance_schema = "o2-compiler-rt-v1-cy-source-acceptance-v1";
const contract_source_relative = "tools/o2_compiler_rt_v1_baseline_validation.zig";
const runner_source_relative = "tools/o2_compiler_rt_v1_baseline_validation_runner.zig";
const source_acceptance_directory_relative = "local-state/validations/inbox206cy";
const source_acceptance_name = "cy_source_acceptance_v1.tsv";
const source_acceptance_temporary_name = ".cy_source_acceptance_v1.tsv.tmp";
const di_controller_identity_schema = "inbox206di-controller-identity-v1";
const di_controller_root_relative = "local-state/caches/inbox206di-acceptance-controller";
const di_source_set_schema = "inbox206di-source-set-v1";
const di_source_paths = [_][]const u8{
    "tools/o2_compiler_rt_v1_baseline_validation.zig",
    "tools/o2_compiler_rt_v1_baseline_validation_runner.zig",
    "tools/o2_compiler_rt_v1_baseline_validation/accepted_subset.zig",
    "tools/o2_compiler_rt_v1_baseline_validation/authenticated_inputs.zig",
    "tools/o2_compiler_rt_v1_baseline_validation/authenticated_process.zig",
    "tools/o2_compiler_rt_v1_baseline_validation/closure.zig",
    "tools/o2_compiler_rt_v1_baseline_validation/orchestration.zig",
    "tools/o2_compiler_rt_v1_baseline_validation/process.zig",
    "tools/o2_compiler_rt_v1_baseline_validation/raw_report.zig",
    "tools/o2_compiler_rt_v1_baseline_validation/result_validation.zig",
    "tools/o2_compiler_rt_v1_baseline_validation/storage.zig",
};
const di_source_normalized_mode: u32 = 0o100644;
const expected_zig_version = authenticated_inputs.expected_zig_version;
const process_capture_max = process.capture_max;
const closure_max = closure_validation.maximum_bytes;
const closure_name = closure_validation.name;
const input_limit = "67108864";
const target = "x86_64-linux";
const maximum_input_bytes = authenticated_inputs.maximum_input_bytes;
const maximum_artifact_bytes = authenticated_inputs.maximum_artifact_bytes;
const maximum_parsed_tool_output: usize = 64 * 1024 * 1024;
const accepted_registered_worktree_count = authenticated_inputs.accepted_registered_worktree_count;

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

const CapacityFields = storage_validation.CapacityFields;
const CapacityRootIdentity = storage_validation.CapacityRootIdentity;

const FileIdentity = authenticated_inputs.FileIdentity;
const ToolRole = authenticated_inputs.ToolRole;
const toolRoleName = authenticated_inputs.toolRoleName;
const ToolSelector = authenticated_inputs.ToolSelector;
const PortableToolIdentity = authenticated_inputs.PortableToolIdentity;

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

const DiControllerIdentityExpected = struct {
    mode: u32,
    bytes: u64,
    inode: std.Io.File.INode,
    sha256: contract.Digest,
};

const DiControllerIdentityCli = struct {
    repository: []const u8,
    controller: []const u8,
    expected: ?DiControllerIdentityExpected,
    registered_worktrees: []const []const u8,
};

const DiSourceSetObservation = struct {
    count: usize,
    aggregate_sha256: contract.Digest,
};

const DiSourceSetCli = struct {
    repository: []const u8,
    expected: ?DiSourceSetObservation,
    registered_worktrees: []const []const u8,
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
    gates: [@typeInfo(SourceAcceptanceGate).@"enum".field_names.len]SourceAcceptanceGateResult,
    completion: bool,
};

const AuthenticatedSubject = authenticated_inputs.AuthenticatedSubject;
const SubjectSet = authenticated_inputs.SubjectSet;
const InputSet = authenticated_inputs.InputSet;

const BaselineExecutionMode = enum {
    accepted,
    development,
    dj_combined_call_ratchet_130,
};

const Cli = struct {
    mode: BaselineExecutionMode,
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

const ExpectedFile = authenticated_inputs.ExpectedFile;

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

const RegisteredWorktreeSetIdentity = closure_validation.RegisteredWorktreeSetIdentity;

const FunctionRow = result_validation.FunctionRow;

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

const PathKind = authenticated_inputs.PathKind;

const PathFact = storage_validation.PathFact;

const EnvironmentEntry = process.EnvironmentEntry;
const ProcessRequest = process.ProcessRequest;
const FixedCommand = process.FixedCommand;
const Termination = process.Termination;
const CapturedResult = process.CapturedResult;
const validateCanonicalAbsolute = process.validateCanonicalAbsolute;
const validateFixedCommand = process.validateFixedCommand;
const validateCapturedResult = process.validateCapturedResult;
const requireConsistentResult = process.requireConsistentResult;
const runBounded = process.runBounded;
const processTermination = process.processTermination;
const fixedEnvironment = process.fixedEnvironment;
const fixedCoverageEnvironment = process.fixedCoverageEnvironment;
const fixedGitEnvironment = process.fixedGitEnvironment;
const validateRegisteredWorktreePrefixes = authenticated_inputs.validateRegisteredWorktreePrefixes;
const registeredWorktreeAccessExclusions = authenticated_inputs.registeredWorktreeAccessExclusions;
const validateExplicitPath = authenticated_inputs.validateExplicitPath;
const decodeSha256 = authenticated_inputs.decodeSha256;
const observeFile = authenticated_inputs.observeFile;
const authenticateFile = authenticated_inputs.authenticateFile;
const authenticateSubject = authenticated_inputs.authenticateSubject;
const requireSubjectStable = authenticated_inputs.requireSubjectStable;
const joinAbsolute = authenticated_inputs.joinAbsolute;
const readBoundedAbsolute = authenticated_inputs.readBoundedAbsolute;
const parseManifestLine = authenticated_inputs.parseManifestLine;
const readAuthenticatedBundleMember = authenticated_inputs.readAuthenticatedBundleMember;
const verifySourceManifest = authenticated_inputs.verifySourceManifest;
const verifyCompatibilityBundleMembers = authenticated_inputs.verifyCompatibilityBundleMembers;
const accepted_bundle_manifest_prefix = authenticated_inputs.accepted_bundle_manifest_prefix;
const FamilyUsage = storage_validation.FamilyUsage;
const FamilyTracker = storage_validation.FamilyTracker;
const initializeFamilyUsage = storage_validation.initializeFamilyUsage;
const accountFamilyBytes = storage_validation.accountFamilyBytes;
const validatePathFacts = storage_validation.validatePathFacts;
const observePathFact = storage_validation.observePathFact;
const deriveAvailableBytes = storage_validation.deriveAvailableBytes;
const capacityRootIdentity = storage_validation.capacityRootIdentity;
const requireCapacityRootStable = storage_validation.requireCapacityRootStable;
const observeAvailableBytes = storage_validation.observeAvailableBytes;
const requireSameOutputFilesystem = storage_validation.requireSameOutputFilesystem;
const RootUsage = storage_validation.RootUsage;
const scanRootBounded = storage_validation.scanRootBounded;
const setFamilyFromRoot = storage_validation.setFamilyFromRoot;
const combineRootUsage = storage_validation.combineRootUsage;
const addRootUsage = storage_validation.addRootUsage;
const scanRelativeRoots = storage_validation.scanRelativeRoots;
const validateStorageRoot = storage_validation.validateStorageRoot;

const RestorationIdentity = closure_validation.RestorationIdentity;
const CompleteRunObservation = closure_validation.CompleteRunObservation;

const SourceIdentityBinding = struct {
    repository: RepositoryObservation,
    external_zig: RepositoryObservation,
    canonical: RepositoryObservation,
    coverage: RepositoryObservation,
    canonical_manifest: contract.Digest,
    coverage_manifest: contract.Digest,
};

const ClosureBinding = closure_validation.Binding;
const ValidatedRun = closure_validation.ValidatedRun;
const PublishedClosure = closure_validation.Published;
const requireRestorationEqual = closure_validation.requireRestorationEqual;
const validateCompletedPhases = closure_validation.validateCompletedPhases;
const validateCompleteRun = closure_validation.validateCompleteRun;
const encodeClosure = closure_validation.encode;
const completeEnforcementEvidence = closure_validation.completeEnforcementEvidence;
const verifyClosureReadBack = closure_validation.verifyReadBack;
const publishClosure = closure_validation.publish;
const validateToolBindings = closure_validation.validateToolBindings;
const syncOwnedDirectory = closure_validation.syncOwnedDirectory;
const runAuthenticated = authenticated_process.runAuthenticated;
const FileCommandResult = authenticated_process.FileCommandResult;
const runAuthenticatedToFile = authenticated_process.runAuthenticatedToFile;
const authenticateGeneratedSubject = authenticated_process.authenticateGeneratedSubject;
const expectCleanOutput = authenticated_process.expectCleanOutput;
const expectSuccessfulBuildOutput = authenticated_process.expectSuccessfulBuildOutput;
const runZigVersion = authenticated_process.runZigVersion;

const ParsedCoverageChannel = result_validation.ParsedCoverageChannel;
const parseCoverageChannel = result_validation.parseCoverageChannel;
const parseReadelfFunctions = result_validation.parseReadelfFunctions;
const validateReadelfSections = result_validation.validateReadelfSections;
const validateObjdumpFunctions = result_validation.validateObjdumpFunctions;
const encodeFunctionManifest = result_validation.encodeFunctionManifest;
const validateOwnerManifest = result_validation.validateOwnerManifest;

fn nextArgument(args: *std.process.Args.Iterator) RunnerError![]const u8 {
    return args.next() orelse error.InvalidArguments;
}

fn parseToolRole(text: []const u8) RunnerError!ToolRole {
    return std.meta.stringToEnum(ToolRole, text) orelse error.InvalidArguments;
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
    mode: BaselineExecutionMode,
) !Cli {
    var result = Cli{
        .mode = mode,
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

fn parseCanonicalUnsigned(comptime T: type, text: []const u8) RunnerError!T {
    if (text.len == 0 or (text.len > 1 and text[0] == '0')) return error.InvalidArguments;
    for (text) |byte| if (!std.ascii.isDigit(byte)) return error.InvalidArguments;
    return std.fmt.parseInt(T, text, 10) catch return error.InvalidArguments;
}

fn parseDiControllerIdentityExpected(
    mode_text: []const u8,
    bytes_text: []const u8,
    inode_text: []const u8,
    sha256_text: []const u8,
) RunnerError!DiControllerIdentityExpected {
    const mode = try parseCanonicalUnsigned(u32, mode_text);
    if (mode > 0o7777) return error.InvalidArguments;
    return .{
        .mode = mode,
        .bytes = try parseCanonicalUnsigned(u64, bytes_text),
        .inode = try parseCanonicalUnsigned(std.Io.File.INode, inode_text),
        .sha256 = decodeSha256(sha256_text) catch return error.InvalidArguments,
    };
}

fn parseDiControllerIdentityCli(
    allocator: std.mem.Allocator,
    args: *std.process.Args.Iterator,
    require_expected: bool,
) !DiControllerIdentityCli {
    var result = DiControllerIdentityCli{
        .repository = try nextArgument(args),
        .controller = try nextArgument(args),
        .expected = if (require_expected) try parseDiControllerIdentityExpected(
            try nextArgument(args),
            try nextArgument(args),
            try nextArgument(args),
            try nextArgument(args),
        ) else null,
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

fn isStrictPathDescendant(path: []const u8, root: []const u8) bool {
    return path.len > root.len and std.mem.startsWith(u8, path, root) and path[root.len] == '/';
}

fn observeDiControllerIdentity(
    allocator: std.mem.Allocator,
    io: std.Io,
    repository: []const u8,
    controller: []const u8,
    registered_worktrees: []const []const u8,
) !FileIdentity {
    try validateCanonicalAbsolute(repository);
    try validateCanonicalAbsolute(controller);
    const excluded = try registeredWorktreeAccessExclusions(allocator, registered_worktrees, repository);
    defer allocator.free(excluded);
    _ = try validateExplicitPath(io, repository, .directory, excluded);
    const controller_root = try joinAbsolute(allocator, repository, di_controller_root_relative);
    defer allocator.free(controller_root);
    if (!isStrictPathDescendant(controller, controller_root)) return error.PathEscape;
    _ = try validateExplicitPath(io, controller_root, .directory, excluded);
    return (try authenticateGeneratedSubject(io, controller, excluded)).identity;
}

fn requireDiControllerIdentity(
    allocator: std.mem.Allocator,
    io: std.Io,
    repository: []const u8,
    controller: []const u8,
    registered_worktrees: []const []const u8,
    expected: DiControllerIdentityExpected,
) !void {
    const observed = try observeDiControllerIdentity(
        allocator,
        io,
        repository,
        controller,
        registered_worktrees,
    );
    if (observed.mode != expected.mode or observed.bytes != expected.bytes or
        observed.inode != expected.inode or !std.mem.eql(u8, &observed.sha256, &expected.sha256))
        return error.SubjectIdentityMismatch;
}

fn encodeDiControllerIdentity(buffer: []u8, identity: FileIdentity) ![]const u8 {
    const digest_hex = std.fmt.bytesToHex(identity.sha256, .lower);
    return std.fmt.bufPrint(buffer, "{s}\t{d}\t{d}\t{d}\t{s}\n", .{
        di_controller_identity_schema,
        identity.mode,
        identity.bytes,
        identity.inode,
        &digest_hex,
    });
}

fn executeDiControllerIdentity(init: std.process.Init, cli: DiControllerIdentityCli) !void {
    if (cli.expected) |expected| {
        return requireDiControllerIdentity(
            init.gpa,
            init.io,
            cli.repository,
            cli.controller,
            cli.registered_worktrees,
            expected,
        );
    }
    const identity = try observeDiControllerIdentity(
        init.gpa,
        init.io,
        cli.repository,
        cli.controller,
        cli.registered_worktrees,
    );
    var encoded_buffer: [192]u8 = undefined;
    const encoded = try encodeDiControllerIdentity(&encoded_buffer, identity);
    var stdout_buffer: [192]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &stdout_buffer);
    try stdout_writer.interface.writeAll(encoded);
    try stdout_writer.interface.flush();
}

fn parseDiSourceSetCli(
    allocator: std.mem.Allocator,
    args: *std.process.Args.Iterator,
    require_expected: bool,
) !DiSourceSetCli {
    var result = DiSourceSetCli{
        .repository = try nextArgument(args),
        .expected = if (require_expected) try parseDiSourceSetExpected(
            try nextArgument(args),
            try nextArgument(args),
        ) else null,
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

fn parseDiSourceSetExpected(
    count_text: []const u8,
    digest_text: []const u8,
) RunnerError!DiSourceSetObservation {
    return .{
        .count = try parseCanonicalUnsigned(usize, count_text),
        .aggregate_sha256 = decodeSha256(digest_text) catch return error.InvalidArguments,
    };
}

fn aggregateDiSourceSetForDomain(
    domain: []const u8,
    paths: []const []const u8,
    identities: []const FileIdentity,
) !contract.Digest {
    if (paths.len != identities.len or paths.len != di_source_paths.len)
        return error.InputIdentityMismatch;
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    hashBoundedBytes(&hasher, domain);
    hashU64(&hasher, paths.len);
    for (paths, identities) |path, identity| {
        hashBoundedBytes(&hasher, path);
        hashU64(&hasher, di_source_normalized_mode);
        hashU64(&hasher, identity.bytes);
        hasher.update(&identity.sha256);
    }
    return finishDigest(&hasher);
}

fn aggregateDiSourceSet(
    paths: []const []const u8,
    identities: []const FileIdentity,
) !contract.Digest {
    return aggregateDiSourceSetForDomain(di_source_set_schema, paths, identities);
}

fn observeDiSourceSet(
    allocator: std.mem.Allocator,
    io: std.Io,
    repository: []const u8,
    registered_worktrees: []const []const u8,
) !DiSourceSetObservation {
    try validateCanonicalAbsolute(repository);
    const excluded = try registeredWorktreeAccessExclusions(allocator, registered_worktrees, repository);
    defer allocator.free(excluded);
    _ = try validateExplicitPath(io, repository, .directory, excluded);
    var identities: [di_source_paths.len]FileIdentity = undefined;
    for (di_source_paths, &identities) |relative, *identity| {
        const absolute = try joinAbsolute(allocator, repository, relative);
        defer allocator.free(absolute);
        if (!isStrictPathDescendant(absolute, repository)) return error.PathEscape;
        identity.* = try observeFile(io, absolute, false, maximum_input_bytes, excluded);
        if (identity.mode & 0o111 != 0) return error.WrongExecutable;
    }
    return .{
        .count = di_source_paths.len,
        .aggregate_sha256 = try aggregateDiSourceSet(&di_source_paths, &identities),
    };
}

fn requireDiSourceSet(
    allocator: std.mem.Allocator,
    io: std.Io,
    repository: []const u8,
    registered_worktrees: []const []const u8,
    expected: DiSourceSetObservation,
) !void {
    const observed = try observeDiSourceSet(allocator, io, repository, registered_worktrees);
    if (observed.count != expected.count or
        !std.mem.eql(u8, &observed.aggregate_sha256, &expected.aggregate_sha256))
        return error.SubjectIdentityMismatch;
}

fn encodeDiSourceSet(buffer: []u8, observation: DiSourceSetObservation) ![]const u8 {
    const digest_hex = std.fmt.bytesToHex(observation.aggregate_sha256, .lower);
    return std.fmt.bufPrint(buffer, "{s}\t{d}\t{s}\n", .{
        di_source_set_schema,
        observation.count,
        &digest_hex,
    });
}

fn executeDiSourceSet(init: std.process.Init, cli: DiSourceSetCli) !void {
    if (cli.expected) |expected| {
        return requireDiSourceSet(
            init.gpa,
            init.io,
            cli.repository,
            cli.registered_worktrees,
            expected,
        );
    }
    const observation = try observeDiSourceSet(
        init.gpa,
        init.io,
        cli.repository,
        cli.registered_worktrees,
    );
    var encoded_buffer: [128]u8 = undefined;
    const encoded = try encodeDiSourceSet(&encoded_buffer, observation);
    var stdout_buffer: [128]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &stdout_buffer);
    try stdout_writer.interface.writeAll(encoded);
    try stdout_writer.interface.flush();
}

fn lessString(_: void, left: []const u8, right: []const u8) bool {
    return std.mem.order(u8, left, right) == .lt;
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
    const zero_blob = "0000000000000000000000000000000000000000";
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
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        try validateRelativeManifestPath(line);
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
    mode: BaselineExecutionMode,
) !std.Io.Dir {
    const expected = try joinAbsolute(allocator, repository, baselinePlannedPath(mode, .validation_root));
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
    inline for (@typeInfo(InputSet).@"struct".field_names) |field_name| {
        hashBoundedBytes(&hasher, field_name);
        hashFileIdentity(&hasher, @field(inputs, field_name));
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
        hashU64(&hasher, repetition.raw_report.selected_functions);
        hashU64(&hasher, repetition.raw_report.actual_successful_functions);
        hashU64(&hasher, repetition.raw_report.failed_functions);
        hasher.update(&repetition.raw_report.failure_order_sha256);
        hasher.update(&repetition.raw_report.successful_manifest_sha256);
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
    inline for (@typeInfo(@TypeOf(coverage.observation_off)).@"struct".field_names) |field_name| {
        hashBool(&hasher, @field(coverage.observation_off, field_name));
    }
    inline for (@typeInfo(@TypeOf(coverage.observation_on)).@"struct".field_names) |field_name| {
        hashBool(&hasher, @field(coverage.observation_on, field_name));
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

const synthetic_actual_successful_functions: u16 = 7;

fn syntheticRawReportBinding() contract.RawReportBinding {
    return .{
        .selected_functions = 11,
        .actual_successful_functions = synthetic_actual_successful_functions,
        .failed_functions = 4,
        .failure_order_sha256 = @splat(0x10),
        .successful_manifest_sha256 = @splat(0x15),
    };
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
        .v3_path_count = @typeInfo(contract.V3Path).@"enum".field_names.len,
        .repetition_count = contract.canonical_repetition_count,
        .actual_successful_functions = synthetic_actual_successful_functions,
        .phase_count = @typeInfo(contract.Phase).@"enum".field_names.len,
        .stdout_capture_bytes = process_capture_max,
        .stderr_capture_bytes = process_capture_max,
    };
}

fn syntheticRestoration(byte: u8) RestorationIdentity {
    return .{
        .repository = @splat(byte),
        .canonical_source = @splat(byte +% 1),
        .coverage_source = @splat(byte +% 2),
        .accepted_input = @splat(byte +% 3),
    };
}

fn syntheticTool(role: ToolRole, byte: u8) AuthenticatedSubject {
    const digest: [32]u8 = @splat(byte);
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
        .fixed_sources = @splat(0x71),
        .fixed_inputs = @splat(0x72),
        .raw_report = syntheticRawReportBinding(),
        .canonical_artifact = .{
            .bytes = 101,
            .mode = 0o755,
            .inode = 101,
            .sha256 = @splat(0x73),
        },
        .coverage_artifact = .{
            .bytes = 102,
            .mode = 0o755,
            .inode = 102,
            .sha256 = @splat(0x74),
        },
        .canonical_observations = @splat(0x75),
        .coverage_off_observation = @splat(0x76),
        .coverage_on_observation = @splat(0x77),
        .counter_result = @splat(0x78),
        .registered_worktrees = .{
            .count = accepted_registered_worktree_count,
            .sha256 = @splat(0x79),
        },
        .family_usage = @splat(0x7a),
        .completion = true,
    };
}

fn syntheticStagedSource(byte: u8) StagedSourceIdentity {
    return .{
        .mode = 0o100644,
        .bytes = byte,
        .blob = @splat(byte),
        .raw_sha256 = @splat(byte +% 1),
        .worktree_inode = byte,
    };
}

fn syntheticSourceAcceptanceEvidence() SourceAcceptanceEvidence {
    var gates: [@typeInfo(SourceAcceptanceGate).@"enum".field_names.len]SourceAcceptanceGateResult = undefined;
    for (&gates, 0..) |*gate, index| {
        gate.* = .{
            .gate = @enumFromInt(index + 1),
            .exit_status = 0,
            .stdout_bytes = index,
            .stdout_sha256 = @splat(@intCast(index + 1)),
            .stderr_bytes = index + 1,
            .stderr_sha256 = @splat(@intCast(index + 2)),
        };
    }
    return .{
        .snapshot = .{
            .parent = @splat('1'),
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
        "4444444444444444444444444444444444444444",
        "1111111111111111111111111111111111111111",
        contract_path,
    });
    if (runner_path) |path| {
        try output.writer.print(":000000 100644 {s} {s} A\x00{s}\x00", .{
            "0000000000000000000000000000000000000000",
            "2222222222222222222222222222222222222222",
            path,
        });
    }
    if (extra_path) |path| {
        try output.writer.print(":100644 100644 {s} {s} M\x00{s}\x00", .{
            "4444444444444444444444444444444444444444",
            "3333333333333333333333333333333333333333",
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
            .{ path, "0000000000000000000000000000000000000000", index },
        );
    }
    return output.toOwnedSlice();
}

fn syntheticCanonicalRepetitions() [contract.canonical_repetition_count]contract.CanonicalRepetition {
    const identity = contract.CanonicalRepetition{
        .raw_report = syntheticRawReportBinding(),
        .report = @splat(0x11),
        .object = @splat(0x12),
        .owner = @splat(0x13),
        .function_manifest = @splat(0x14),
        .function_count = synthetic_actual_successful_functions,
        .accepted_subset_produced = false,
    };
    var repetitions: [contract.canonical_repetition_count]contract.CanonicalRepetition = @splat(identity);
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
    for (0..@typeInfo(contract.Phase).@"enum".field_names.len) |index| {
        try phases.succeed(@enumFromInt(index));
    }
    return phases;
}

fn syntheticContractRestoration() contract.RestorationState {
    const manifest: [32]u8 = @splat(0x41);
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
        .report = @splat(0x51),
        .object = @splat(0x52),
        .owner = @splat(0x53),
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
    mode: BaselineExecutionMode,
    planned: contract.V3Path,
    actual: []const u8,
) !void {
    const expected = try joinAbsolute(allocator, repository, baselinePlannedPath(mode, planned));
    defer allocator.free(expected);
    if (!std.mem.eql(u8, expected, actual)) return error.PathEscape;
}

const development_root_relative =
    "local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3-development";
const dj_combined_call_ratchet_130_root_relative =
    "local-state/validations/o2-calls/compiler-rt-v1/combined-call-ratchet-130-development";

fn baselinePlannedPath(mode: BaselineExecutionMode, path: contract.V3Path) []const u8 {
    return switch (mode) {
        .accepted => contract.plannedPath(path),
        .development => switch (path) {
            .validation_root => development_root_relative ++ "/run",
            .canonical_source => development_root_relative ++ "/repositories/canonical-source",
            .coverage_source => development_root_relative ++ "/repositories/coverage-source",
            .canonical_cache => development_root_relative ++ "/work/canonical/cache",
            .canonical_install => development_root_relative ++ "/work/canonical/install",
            .coverage_cache => development_root_relative ++ "/work/coverage/cache",
            .coverage_install => development_root_relative ++ "/work/coverage/install",
        },
        .dj_combined_call_ratchet_130 => switch (path) {
            .validation_root => dj_combined_call_ratchet_130_root_relative ++ "/run",
            .canonical_source => dj_combined_call_ratchet_130_root_relative ++ "/repositories/canonical-source",
            .coverage_source => dj_combined_call_ratchet_130_root_relative ++ "/repositories/coverage-source",
            .canonical_cache => dj_combined_call_ratchet_130_root_relative ++ "/work/canonical/cache",
            .canonical_install => dj_combined_call_ratchet_130_root_relative ++ "/work/canonical/install",
            .coverage_cache => dj_combined_call_ratchet_130_root_relative ++ "/work/coverage/cache",
            .coverage_install => dj_combined_call_ratchet_130_root_relative ++ "/work/coverage/install",
        },
    };
}

fn makeRunPaths(
    allocator: std.mem.Allocator,
    repository: []const u8,
    validation_root: []const u8,
    mode: BaselineExecutionMode,
) !RunPaths {
    return .{
        .root = validation_root,
        .canonical = try joinAbsolute(allocator, validation_root, "canonical"),
        .coverage = try joinAbsolute(allocator, validation_root, "coverage"),
        .canonical_cache = try joinAbsolute(allocator, repository, baselinePlannedPath(mode, .canonical_cache)),
        .canonical_install = try joinAbsolute(allocator, repository, baselinePlannedPath(mode, .canonical_install)),
        .coverage_cache = try joinAbsolute(allocator, repository, baselinePlannedPath(mode, .coverage_cache)),
        .coverage_install = try joinAbsolute(allocator, repository, baselinePlannedPath(mode, .coverage_install)),
        .canonical_artifact = try std.fmt.allocPrint(
            allocator,
            "{s}/{s}/bin/z_llvm",
            .{ repository, baselinePlannedPath(mode, .canonical_install) },
        ),
        .coverage_artifact = try std.fmt.allocPrint(
            allocator,
            "{s}/{s}/bin/z_llvm",
            .{ repository, baselinePlannedPath(mode, .coverage_install) },
        ),
        .accepted = try joinAbsolute(allocator, validation_root, "canonical/repetition-1/accepted.ll"),
    };
}

fn createRunDirectories(
    io: std.Io,
    repository: []const u8,
    paths: RunPaths,
    mode: BaselineExecutionMode,
) !void {
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
        const directory = try createRelativeTreeNoFollow(io, repository, baselinePlannedPath(mode, planned));
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
    try recordProcessResult(allocator, io, home[0..std.mem.lastIndexOfScalar(u8, home, '/').?], record_prefix, result, family, usage);
    try expectSuccessfulBuildOutput(result);
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

const AcceptedSubsetResult = struct {
    identity: FileIdentity,
    retained_bytes: u64,
};

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
) !AcceptedSubsetResult {
    const extracted_path = try std.fmt.allocPrint(allocator, "{s}.extracted", .{accepted_path});
    defer allocator.free(extracted_path);
    var argv = std.array_list.Managed([]const u8).init(allocator);
    defer argv.deinit();
    try argv.appendSlice(&.{ llvm_extract.path, "--delete", "-S", "-o", extracted_path });
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
    const extracted_identity = try observeFile(
        io,
        extracted_path,
        false,
        maximum_input_bytes,
        registered_worktrees,
    );
    const raw_bytes = try readBoundedAbsolute(allocator, io, raw_input, maximum_input_bytes);
    defer allocator.free(raw_bytes);
    const extracted_bytes = try readBoundedAbsolute(
        allocator,
        io,
        extracted_path,
        maximum_input_bytes,
    );
    defer allocator.free(extracted_bytes);
    const restored = try accepted_subset.restorePrivateLinkage(
        allocator,
        raw_bytes,
        extracted_bytes,
    );
    defer allocator.free(restored);
    const identity = try writeExclusiveAbsolute(io, accepted_path, restored, 0o444);
    return .{
        .identity = identity,
        .retained_bytes = std.math.add(u64, extracted_identity.bytes, identity.bytes) catch
            return error.StorageOverflow,
    };
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
    frozen_raw_report: *?contract.RawReportBinding,
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
        "--emit=selection-owner-manifest",
        true,
        &environment,
        repetition_root,
        1,
        registered_worktrees,
    );
    defer allocator.free(report.stdout);
    defer allocator.free(report.stderr);
    _ = try writeValidationFile(
        allocator,
        io,
        repetition_root,
        "report.stdout.raw",
        report.stdout,
        .repetition_raw_report,
        usage,
    );
    _ = try writeValidationFile(
        allocator,
        io,
        repetition_root,
        "report.stderr.raw",
        report.stderr,
        .repetition_raw_report,
        usage,
    );
    const parsed_report = try raw_report_parser.parse(allocator, report.stdout, report.stderr);
    defer parsed_report.deinit(allocator);
    const report_binding = parsed_report.binding;
    if (frozen_raw_report.*) |expected| {
        try raw_report_parser.requireSame(report_binding, expected);
    } else {
        frozen_raw_report.* = report_binding;
    }
    if (repetition_index == 0) {
        const accepted_identity = try extractAcceptedSubset(
            allocator,
            io,
            subjects.llvm_extract,
            parsed_report.failures,
            raw_input,
            accepted_path,
            &environment,
            repetition_root,
            registered_worktrees,
        );
        try accountFamilyBytes(usage, .canonical_accepted_ll, accepted_identity.retained_bytes);
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
    const rows = try parseReadelfFunctions(
        allocator,
        symbol_bytes,
        parsed_report.successful_functions,
    );
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
    const objcopy_object_path = try joinAbsolute(allocator, repetition_root, "accepted.objcopy.o");
    const dump_argument = try std.fmt.allocPrint(allocator, ".text={s}", .{text_path});
    const objcopy_argv = [_][]const u8{
        subjects.objcopy.path,
        "--dump-section",
        dump_argument,
        object_path,
        objcopy_object_path,
    };
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
    const objcopy_object_identity = try observeFile(
        io,
        objcopy_object_path,
        false,
        maximum_artifact_bytes,
        registered_worktrees,
    );
    try accountFamilyBytes(usage, .canonical_comparisons, objcopy_object_identity.bytes);
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
    try validateOwnerManifest(owner_bytes, report_binding.actual_successful_functions);
    return .{
        .raw_report = report_binding,
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
    successful_functions: []const []const u8,
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
    const rows = try parseReadelfFunctions(allocator, symbol_bytes, successful_functions);
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
    const objcopy_object_path = try joinAbsolute(allocator, observation_root, "accepted.objcopy.o");
    const dump_argument = try std.fmt.allocPrint(allocator, ".text={s}", .{text_path});
    const objcopy_argv = [_][]const u8{
        subjects.objcopy.path,
        "--dump-section",
        dump_argument,
        object_path,
        objcopy_object_path,
    };
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
    const objcopy_object_identity = try observeFile(
        io,
        objcopy_object_path,
        false,
        maximum_artifact_bytes,
        registered_worktrees,
    );
    try accountFamilyBytes(usage, .coverage_per_function, objcopy_object_identity.bytes);
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
    frozen_raw_report: contract.RawReportBinding,
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
        "--emit=selection-owner-manifest",
        true,
        report_environment,
        observation_root,
        1,
        registered_worktrees,
    );
    defer allocator.free(report.stdout);
    defer allocator.free(report.stderr);
    _ = try writeValidationFile(
        allocator,
        io,
        observation_root,
        "report.stdout.raw",
        report.stdout,
        if (coverage_enabled) .observation_on_remaining else .observation_off,
        usage,
    );
    _ = try writeValidationFile(
        allocator,
        io,
        observation_root,
        "report.stderr.raw",
        report.stderr,
        if (coverage_enabled) .observation_on_remaining else .observation_off,
        usage,
    );
    const parsed_report = try raw_report_parser.parse(allocator, report.stdout, report.stderr);
    defer parsed_report.deinit(allocator);
    try raw_report_parser.requireSame(parsed_report.binding, frozen_raw_report);

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
    try validateOwnerManifest(owner_bytes, frozen_raw_report.actual_successful_functions);
    const analysis_environment = fixedEnvironment(home, temporary);
    const function_manifest = try analyzeObservationObject(
        allocator,
        io,
        subjects,
        observation_root,
        object_path,
        &analysis_environment,
        parsed_report.successful_functions,
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
    try requirePlannedAbsolute(init.gpa, cli.repository, cli.mode, .validation_root, cli.validation_root);
    try requirePlannedAbsolute(init.gpa, cli.repository, cli.mode, .canonical_source, cli.canonical_source);
    try requirePlannedAbsolute(init.gpa, cli.repository, cli.mode, .coverage_source, cli.coverage_source);
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
    if (cli.mode == .accepted and !repository_before.clean) return error.GitObservationMismatch;
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

    const paths = try makeRunPaths(init.gpa, cli.repository, cli.validation_root, cli.mode);
    var validation_root = try createValidationRoot(
        init.gpa,
        init.io,
        cli.repository,
        cli.validation_root,
        cli.mode,
    );
    defer validation_root.close(init.io);
    const available_bytes = try observeAvailableBytes(init.io, validation_root);
    _ = try contract.acceptedStorageBudgetTotals(available_bytes);
    try createRunDirectories(init.io, cli.repository, paths, cli.mode);
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
    var frozen_raw_report: ?contract.RawReportBinding = null;
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
            &frozen_raw_report,
            &usage,
            cli.registered_worktrees,
        );
        try phases.succeed(@enumFromInt(@intFromEnum(contract.Phase.canonical_repetition_1) + index));
    }
    const raw_report = frozen_raw_report orelse return error.ClosurePrecondition;
    try contract.validateCanonicalRepetitions(&repetitions, raw_report);
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
        raw_report,
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
        raw_report,
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
        .raw_report = raw_report,
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
        .raw_report = raw_report,
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
    if (gates.len != @typeInfo(SourceAcceptanceGate).@"enum".field_names.len)
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
    var gates: [@typeInfo(SourceAcceptanceGate).@"enum".field_names.len]SourceAcceptanceGateResult = undefined;
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
    if (std.mem.eql(u8, mode, "--run-accepted-baseline") or
        std.mem.eql(u8, mode, "--run-development-baseline") or
        std.mem.eql(u8, mode, "--run-dj-combined-call-ratchet-130-baseline"))
    {
        const execution_mode: BaselineExecutionMode = if (std.mem.eql(u8, mode, "--run-accepted-baseline"))
            .accepted
        else if (std.mem.eql(u8, mode, "--run-development-baseline"))
            .development
        else
            .dj_combined_call_ratchet_130;
        const cli = try parseBaselineCli(run_init.gpa, &args, execution_mode);
        try executeAcceptedBaseline(run_init, cli);
    } else if (std.mem.eql(u8, mode, "--accept-cy-source")) {
        const cli = try parseSourceAcceptanceCli(&args);
        try executeSourceAcceptance(run_init, cli);
    } else if (std.mem.eql(u8, mode, "--observe-di-controller")) {
        const cli = try parseDiControllerIdentityCli(run_init.gpa, &args, false);
        try executeDiControllerIdentity(run_init, cli);
    } else if (std.mem.eql(u8, mode, "--require-di-controller")) {
        const cli = try parseDiControllerIdentityCli(run_init.gpa, &args, true);
        try executeDiControllerIdentity(run_init, cli);
    } else if (std.mem.eql(u8, mode, "--observe-di-source-set")) {
        const cli = try parseDiSourceSetCli(run_init.gpa, &args, false);
        try executeDiSourceSet(run_init, cli);
    } else if (std.mem.eql(u8, mode, "--require-di-source-set")) {
        const cli = try parseDiSourceSetCli(run_init.gpa, &args, true);
        try executeDiSourceSet(run_init, cli);
    } else {
        return error.InvalidArguments;
    }
}

comptime {
    if (builtin.zig_version.major != 0 or
        builtin.zig_version.minor != 17 or
        builtin.zig_version.patch != 0)
    {
        @compileError("baseline validation runner requires exact Zig 0.17.0");
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

test "baseline runner development layout confines every mutable path to one root" {
    inline for (.{
        contract.V3Path.validation_root,
        contract.V3Path.canonical_source,
        contract.V3Path.coverage_source,
        contract.V3Path.canonical_cache,
        contract.V3Path.canonical_install,
        contract.V3Path.coverage_cache,
        contract.V3Path.coverage_install,
    }) |path| {
        const development = baselinePlannedPath(.development, path);
        try std.testing.expect(std.mem.startsWith(
            u8,
            development,
            development_root_relative ++ "/",
        ));
        try std.testing.expectEqualStrings(contract.plannedPath(path), baselinePlannedPath(.accepted, path));
        try std.testing.expect(!std.mem.eql(u8, development, contract.plannedPath(path)));
    }
    try std.testing.expectEqualStrings(
        development_root_relative ++ "/run",
        baselinePlannedPath(.development, .validation_root),
    );
}

test "baseline runner DJ combined-call ratchet layout is fixed and confined" {
    const paths = [_]contract.V3Path{
        .validation_root,
        .canonical_source,
        .coverage_source,
        .canonical_cache,
        .canonical_install,
        .coverage_cache,
        .coverage_install,
    };
    const expected = [_][]const u8{
        dj_combined_call_ratchet_130_root_relative ++ "/run",
        dj_combined_call_ratchet_130_root_relative ++ "/repositories/canonical-source",
        dj_combined_call_ratchet_130_root_relative ++ "/repositories/coverage-source",
        dj_combined_call_ratchet_130_root_relative ++ "/work/canonical/cache",
        dj_combined_call_ratchet_130_root_relative ++ "/work/canonical/install",
        dj_combined_call_ratchet_130_root_relative ++ "/work/coverage/cache",
        dj_combined_call_ratchet_130_root_relative ++ "/work/coverage/install",
    };
    inline for (paths, expected) |path, exact| {
        const dj = baselinePlannedPath(.dj_combined_call_ratchet_130, path);
        try std.testing.expectEqualStrings(exact, dj);
        try std.testing.expect(std.mem.startsWith(
            u8,
            dj,
            dj_combined_call_ratchet_130_root_relative ++ "/",
        ));
        try std.testing.expect(!std.mem.eql(u8, dj, baselinePlannedPath(.accepted, path)));
        try std.testing.expect(!std.mem.eql(u8, dj, baselinePlannedPath(.development, path)));
    }

    const repository = "/repository";
    const exact_validation_root =
        "/repository/" ++ dj_combined_call_ratchet_130_root_relative ++ "/run";
    try requirePlannedAbsolute(
        std.testing.allocator,
        repository,
        .dj_combined_call_ratchet_130,
        .validation_root,
        exact_validation_root,
    );
    inline for (.{
        "/repository/local-state/validations/o2-calls/compiler-rt-v1/combined-call-ratchet-130-development/wrong",
        "/repository/local-state/validations/o2-calls/compiler-rt-v1/combined-call-ratchet-130-development/./run",
        "/repository/local-state/validations/o2-calls/compiler-rt-v1/combined-call-ratchet-130-development/../run",
    }) |rejected| {
        try std.testing.expectError(
            error.PathEscape,
            requirePlannedAbsolute(
                std.testing.allocator,
                repository,
                .dj_combined_call_ratchet_130,
                .validation_root,
                rejected,
            ),
        );
    }
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

    const parent: [40]u8 = @splat('1');
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
    const parent: [40]u8 = @splat('1');
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
    const path = "/home/oleg/.zig/0.17.0/files/zig";
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

fn createSyntheticRegisteredWorktrees(
    allocator: std.mem.Allocator,
    repository: []const u8,
) ![][]const u8 {
    var result = std.array_list.Managed([]const u8).init(allocator);
    errdefer result.deinit();
    try result.append(repository);
    for (1..accepted_registered_worktree_count) |index| {
        const path = try std.fmt.allocPrint(allocator, "/nonexistent-inbox206di-worktree-{d}", .{index});
        errdefer allocator.free(path);
        try result.append(path);
    }
    return result.toOwnedSlice();
}

fn freeSyntheticRegisteredWorktrees(allocator: std.mem.Allocator, paths: [][]const u8) void {
    for (paths[1..]) |path| allocator.free(path);
    allocator.free(paths);
}

fn writeSyntheticExecutable(
    directory: std.Io.Dir,
    io: std.Io,
    sub_path: []const u8,
    bytes: []const u8,
    mode: std.posix.mode_t,
) !void {
    try directory.writeFile(io, .{ .sub_path = sub_path, .data = bytes });
    var file = try directory.openFile(io, sub_path, .{ .mode = .read_write });
    defer file.close(io);
    try file.setPermissions(io, std.Io.File.Permissions.fromMode(mode));
}

const SyntheticDiSourceSetFixture = struct {
    temporary: std.testing.TmpDir,
    repository: []u8,
    registered: [][]const u8,

    fn init() !SyntheticDiSourceSetFixture {
        var temporary = std.testing.tmpDir(.{});
        errdefer temporary.cleanup();
        for (di_source_paths, 0..) |relative, index| {
            const sub_path = try std.fmt.allocPrint(std.testing.allocator, "repo/{s}", .{relative});
            defer std.testing.allocator.free(sub_path);
            if (std.fs.path.dirname(sub_path)) |parent|
                try temporary.dir.createDirPath(std.testing.io, parent);
            const contents = try std.fmt.allocPrint(std.testing.allocator, "source-{d}\n", .{index});
            defer std.testing.allocator.free(contents);
            try temporary.dir.writeFile(std.testing.io, .{ .sub_path = sub_path, .data = contents });
        }
        var temporary_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
        const temporary_length = try temporary.dir.realPath(std.testing.io, &temporary_buffer);
        const repository = try joinAbsolute(
            std.testing.allocator,
            temporary_buffer[0..temporary_length],
            "repo",
        );
        errdefer std.testing.allocator.free(repository);
        const registered = try createSyntheticRegisteredWorktrees(std.testing.allocator, repository);
        errdefer freeSyntheticRegisteredWorktrees(std.testing.allocator, registered);
        return .{ .temporary = temporary, .repository = repository, .registered = registered };
    }

    fn deinit(fixture: *SyntheticDiSourceSetFixture) void {
        freeSyntheticRegisteredWorktrees(std.testing.allocator, fixture.registered);
        std.testing.allocator.free(fixture.repository);
        fixture.temporary.cleanup();
    }

    fn subPath(allocator: std.mem.Allocator, index: usize) ![]u8 {
        return std.fmt.allocPrint(allocator, "repo/{s}", .{di_source_paths[index]});
    }

    fn writeSource(fixture: *SyntheticDiSourceSetFixture, index: usize, contents: []const u8) !void {
        const sub_path = try subPath(std.testing.allocator, index);
        defer std.testing.allocator.free(sub_path);
        try fixture.temporary.dir.writeFile(std.testing.io, .{ .sub_path = sub_path, .data = contents });
    }

    fn setSourceMode(fixture: *SyntheticDiSourceSetFixture, index: usize, mode: std.posix.mode_t) !void {
        const sub_path = try subPath(std.testing.allocator, index);
        defer std.testing.allocator.free(sub_path);
        var file = try fixture.temporary.dir.openFile(std.testing.io, sub_path, .{ .mode = .read_write });
        defer file.close(std.testing.io);
        try file.setPermissions(std.testing.io, std.Io.File.Permissions.fromMode(mode));
    }
};

test "baseline runner DI source set observes requires and canonically encodes" {
    var fixture = try SyntheticDiSourceSetFixture.init();
    defer fixture.deinit();
    const observation = try observeDiSourceSet(
        std.testing.allocator,
        std.testing.io,
        fixture.repository,
        fixture.registered,
    );
    try std.testing.expectEqual(di_source_paths.len, observation.count);
    try requireDiSourceSet(
        std.testing.allocator,
        std.testing.io,
        fixture.repository,
        fixture.registered,
        observation,
    );
    var encoded_buffer: [128]u8 = undefined;
    const encoded = try encodeDiSourceSet(&encoded_buffer, observation);
    const digest_hex = std.fmt.bytesToHex(observation.aggregate_sha256, .lower);
    const expected = try std.fmt.allocPrint(std.testing.allocator, "{s}\t{d}\t{s}\n", .{
        di_source_set_schema,
        di_source_paths.len,
        &digest_hex,
    });
    defer std.testing.allocator.free(expected);
    try std.testing.expectEqualStrings(expected, encoded);
    try std.testing.expect(encoded.len <= encoded_buffer.len);
}

test "baseline runner DI source set rejects byte length and executable permission drift" {
    var fixture = try SyntheticDiSourceSetFixture.init();
    defer fixture.deinit();
    const observation = try observeDiSourceSet(
        std.testing.allocator,
        std.testing.io,
        fixture.repository,
        fixture.registered,
    );
    try fixture.writeSource(0, "SOURCE-0\n");
    try std.testing.expectError(error.SubjectIdentityMismatch, requireDiSourceSet(
        std.testing.allocator,
        std.testing.io,
        fixture.repository,
        fixture.registered,
        observation,
    ));
    try fixture.writeSource(0, "source-0-longer\n");
    try std.testing.expectError(error.SubjectIdentityMismatch, requireDiSourceSet(
        std.testing.allocator,
        std.testing.io,
        fixture.repository,
        fixture.registered,
        observation,
    ));
    try fixture.writeSource(0, "source-0\n");
    try fixture.setSourceMode(0, 0o755);
    try std.testing.expectError(error.WrongExecutable, observeDiSourceSet(
        std.testing.allocator,
        std.testing.io,
        fixture.repository,
        fixture.registered,
    ));
}

test "baseline runner DI source set binds literal order domain and malformed expectations" {
    var identities: [di_source_paths.len]FileIdentity = undefined;
    for (&identities, 0..) |*identity, index| identity.* = .{
        .bytes = index + 1,
        .mode = if (index % 2 == 0) 0o644 else 0o664,
        .inode = index + 100,
        .sha256 = @splat(@intCast(index + 1)),
    };
    const aggregate = try aggregateDiSourceSet(&di_source_paths, &identities);
    var reordered = di_source_paths;
    std.mem.swap([]const u8, &reordered[0], &reordered[1]);
    const reordered_aggregate = try aggregateDiSourceSet(&reordered, &identities);
    try std.testing.expect(!std.mem.eql(u8, &aggregate, &reordered_aggregate));
    var renamed = di_source_paths;
    renamed[0] = "tools/not-the-contract.zig";
    const renamed_aggregate = try aggregateDiSourceSet(&renamed, &identities);
    try std.testing.expect(!std.mem.eql(u8, &aggregate, &renamed_aggregate));
    const other_domain = try aggregateDiSourceSetForDomain("wrong-domain", &di_source_paths, &identities);
    try std.testing.expect(!std.mem.eql(u8, &aggregate, &other_domain));
    try std.testing.expectError(error.InvalidArguments, parseDiSourceSetExpected("011", "0000000000000000000000000000000000000000000000000000000000000000"));
    try std.testing.expectError(error.InvalidArguments, parseDiSourceSetExpected("not-a-count", "0000000000000000000000000000000000000000000000000000000000000000"));
    try std.testing.expectError(error.InvalidArguments, parseDiSourceSetExpected("11", "not-a-digest"));

    var fixture = try SyntheticDiSourceSetFixture.init();
    defer fixture.deinit();
    const observation = try observeDiSourceSet(
        std.testing.allocator,
        std.testing.io,
        fixture.repository,
        fixture.registered,
    );
    var wrong_count = observation;
    wrong_count.count -= 1;
    try std.testing.expectError(error.SubjectIdentityMismatch, requireDiSourceSet(
        std.testing.allocator,
        std.testing.io,
        fixture.repository,
        fixture.registered,
        wrong_count,
    ));
}

test "baseline runner DI source set confines canonical files and rejects symlink and worktree access" {
    var fixture = try SyntheticDiSourceSetFixture.init();
    defer fixture.deinit();
    try std.testing.expectError(error.RelativePath, observeDiSourceSet(
        std.testing.allocator,
        std.testing.io,
        "relative/repository",
        fixture.registered,
    ));
    const alias = try std.fmt.allocPrint(std.testing.allocator, "{s}//", .{fixture.repository});
    defer std.testing.allocator.free(alias);
    try std.testing.expectError(error.NonCanonicalPath, observeDiSourceSet(
        std.testing.allocator,
        std.testing.io,
        alias,
        fixture.registered,
    ));

    const first_sub_path = try SyntheticDiSourceSetFixture.subPath(std.testing.allocator, 0);
    defer std.testing.allocator.free(first_sub_path);
    const first_real = try std.fmt.allocPrint(std.testing.allocator, "{s}.real", .{first_sub_path});
    defer std.testing.allocator.free(first_real);
    try fixture.temporary.dir.rename(first_sub_path, fixture.temporary.dir, first_real, std.testing.io);
    const symlink_target = try std.fmt.allocPrint(std.testing.allocator, "{s}.real", .{std.fs.path.basename(first_sub_path)});
    defer std.testing.allocator.free(symlink_target);
    try fixture.temporary.dir.symLink(std.testing.io, symlink_target, first_sub_path, .{ .is_directory = false });
    try std.testing.expectError(error.SymlinkRejected, observeDiSourceSet(
        std.testing.allocator,
        std.testing.io,
        fixture.repository,
        fixture.registered,
    ));

    try fixture.temporary.dir.deleteFile(std.testing.io, first_sub_path);
    try fixture.temporary.dir.rename(first_real, fixture.temporary.dir, first_sub_path, std.testing.io);
    const old_other = fixture.registered[1];
    const nested_other = try joinAbsolute(
        std.testing.allocator,
        fixture.repository,
        "tools/o2_compiler_rt_v1_baseline_validation",
    );
    fixture.registered[1] = nested_other;
    defer {
        std.testing.allocator.free(old_other);
        fixture.registered[1] = nested_other;
    }
    try std.testing.expectError(error.RegisteredWorktreeRejected, observeDiSourceSet(
        std.testing.allocator,
        std.testing.io,
        fixture.repository,
        fixture.registered,
    ));
}

test "baseline runner DI controller identity observes requires and canonically encodes" {
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    const io = std.testing.io;
    const relative_root = "repo/" ++ di_controller_root_relative;
    const relative_controller = relative_root ++ "/controller";
    try temporary.dir.createDirPath(io, relative_root);
    try writeSyntheticExecutable(temporary.dir, io, relative_controller, "controller-v1\n", 0o755);

    var temporary_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const temporary_length = try temporary.dir.realPath(io, &temporary_buffer);
    const temporary_root = temporary_buffer[0..temporary_length];
    const repository = try joinAbsolute(std.testing.allocator, temporary_root, "repo");
    defer std.testing.allocator.free(repository);
    const controller = try joinAbsolute(
        std.testing.allocator,
        repository,
        di_controller_root_relative ++ "/controller",
    );
    defer std.testing.allocator.free(controller);
    const registered = try createSyntheticRegisteredWorktrees(std.testing.allocator, repository);
    defer freeSyntheticRegisteredWorktrees(std.testing.allocator, registered);

    const identity = try observeDiControllerIdentity(
        std.testing.allocator,
        io,
        repository,
        controller,
        registered,
    );
    try requireDiControllerIdentity(
        std.testing.allocator,
        io,
        repository,
        controller,
        registered,
        .{ .mode = identity.mode, .bytes = identity.bytes, .inode = identity.inode, .sha256 = identity.sha256 },
    );
    var encoded_buffer: [192]u8 = undefined;
    const encoded = try encodeDiControllerIdentity(&encoded_buffer, identity);
    const digest_hex = std.fmt.bytesToHex(identity.sha256, .lower);
    const expected = try std.fmt.allocPrint(std.testing.allocator, "{s}\t{d}\t{d}\t{d}\t{s}\n", .{
        di_controller_identity_schema,
        identity.mode,
        identity.bytes,
        identity.inode,
        &digest_hex,
    });
    defer std.testing.allocator.free(expected);
    try std.testing.expectEqualStrings(expected, encoded);
    try std.testing.expect(encoded.len <= encoded_buffer.len);
}

test "baseline runner DI controller identity rejects drift and malformed expectations" {
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    const io = std.testing.io;
    const relative_root = "repo/" ++ di_controller_root_relative;
    const relative_controller = relative_root ++ "/controller";
    try temporary.dir.createDirPath(io, relative_root);
    try writeSyntheticExecutable(temporary.dir, io, relative_controller, "controller-v1\n", 0o755);
    var temporary_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const temporary_length = try temporary.dir.realPath(io, &temporary_buffer);
    const temporary_root = temporary_buffer[0..temporary_length];
    const repository = try joinAbsolute(std.testing.allocator, temporary_root, "repo");
    defer std.testing.allocator.free(repository);
    const controller = try joinAbsolute(std.testing.allocator, repository, di_controller_root_relative ++ "/controller");
    defer std.testing.allocator.free(controller);
    const registered = try createSyntheticRegisteredWorktrees(std.testing.allocator, repository);
    defer freeSyntheticRegisteredWorktrees(std.testing.allocator, registered);
    const identity = try observeDiControllerIdentity(std.testing.allocator, io, repository, controller, registered);

    var wrong = DiControllerIdentityExpected{
        .mode = identity.mode,
        .bytes = identity.bytes,
        .inode = identity.inode,
        .sha256 = identity.sha256,
    };
    wrong.mode ^= 0o010;
    try std.testing.expectError(error.SubjectIdentityMismatch, requireDiControllerIdentity(
        std.testing.allocator,
        io,
        repository,
        controller,
        registered,
        wrong,
    ));
    wrong.mode = identity.mode;
    wrong.bytes += 1;
    try std.testing.expectError(error.SubjectIdentityMismatch, requireDiControllerIdentity(
        std.testing.allocator,
        io,
        repository,
        controller,
        registered,
        wrong,
    ));
    wrong.bytes = identity.bytes;
    wrong.sha256[0] ^= 1;
    try std.testing.expectError(error.SubjectIdentityMismatch, requireDiControllerIdentity(
        std.testing.allocator,
        io,
        repository,
        controller,
        registered,
        wrong,
    ));
    try std.testing.expectError(error.InvalidArguments, parseDiControllerIdentityExpected(
        "0755",
        "14",
        "1",
        "0000000000000000000000000000000000000000000000000000000000000000",
    ));
    try std.testing.expectError(error.InvalidArguments, parseDiControllerIdentityExpected(
        "493",
        "-1",
        "1",
        "0000000000000000000000000000000000000000000000000000000000000000",
    ));
    try std.testing.expectError(error.InvalidArguments, parseDiControllerIdentityExpected(
        "493",
        "14",
        "1",
        "not-a-digest",
    ));

    try writeSyntheticExecutable(temporary.dir, io, relative_controller, "controller-v2\n", 0o755);
    try std.testing.expectError(error.SubjectIdentityMismatch, requireDiControllerIdentity(
        std.testing.allocator,
        io,
        repository,
        controller,
        registered,
        .{ .mode = identity.mode, .bytes = identity.bytes, .inode = identity.inode, .sha256 = identity.sha256 },
    ));
    try temporary.dir.rename(relative_controller, temporary.dir, relative_root ++ "/controller-old", io);
    try writeSyntheticExecutable(temporary.dir, io, relative_controller, "controller-v1\n", 0o755);
    try std.testing.expectError(error.SubjectIdentityMismatch, requireDiControllerIdentity(
        std.testing.allocator,
        io,
        repository,
        controller,
        registered,
        .{ .mode = identity.mode, .bytes = identity.bytes, .inode = identity.inode, .sha256 = identity.sha256 },
    ));
}

test "baseline runner DI controller identity confines canonical paths and other worktrees" {
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    const io = std.testing.io;
    const relative_root = "repo/" ++ di_controller_root_relative;
    const relative_controller = relative_root ++ "/controller";
    try temporary.dir.createDirPath(io, relative_root);
    try writeSyntheticExecutable(temporary.dir, io, relative_controller, "controller-v1\n", 0o755);
    try temporary.dir.writeFile(io, .{ .sub_path = "repo/outside", .data = "outside\n" });
    try temporary.dir.symLink(io, "controller", relative_root ++ "/controller-link", .{ .is_directory = false });
    var temporary_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const temporary_length = try temporary.dir.realPath(io, &temporary_buffer);
    const temporary_root = temporary_buffer[0..temporary_length];
    const repository = try joinAbsolute(std.testing.allocator, temporary_root, "repo");
    defer std.testing.allocator.free(repository);
    const controller_root = try joinAbsolute(std.testing.allocator, repository, di_controller_root_relative);
    defer std.testing.allocator.free(controller_root);
    const controller = try joinAbsolute(std.testing.allocator, controller_root, "controller");
    defer std.testing.allocator.free(controller);
    const controller_link = try joinAbsolute(std.testing.allocator, controller_root, "controller-link");
    defer std.testing.allocator.free(controller_link);
    const outside = try joinAbsolute(std.testing.allocator, repository, "outside");
    defer std.testing.allocator.free(outside);
    const alias = try std.fmt.allocPrint(std.testing.allocator, "{s}//controller", .{controller_root});
    defer std.testing.allocator.free(alias);
    const registered = try createSyntheticRegisteredWorktrees(std.testing.allocator, repository);
    defer freeSyntheticRegisteredWorktrees(std.testing.allocator, registered);

    try std.testing.expectError(error.RelativePath, observeDiControllerIdentity(
        std.testing.allocator,
        io,
        repository,
        "relative/controller",
        registered,
    ));
    try std.testing.expectError(error.NonCanonicalPath, observeDiControllerIdentity(
        std.testing.allocator,
        io,
        repository,
        alias,
        registered,
    ));
    try std.testing.expectError(error.PathEscape, observeDiControllerIdentity(
        std.testing.allocator,
        io,
        repository,
        outside,
        registered,
    ));
    try std.testing.expectError(error.SymlinkRejected, observeDiControllerIdentity(
        std.testing.allocator,
        io,
        repository,
        controller_link,
        registered,
    ));

    const old_other = registered[1];
    const nested_other = try std.fmt.allocPrint(std.testing.allocator, "{s}/nested-worktree", .{controller_root});
    registered[1] = nested_other;
    defer {
        std.testing.allocator.free(old_other);
        registered[1] = nested_other;
    }
    const nested_controller = try joinAbsolute(std.testing.allocator, nested_other, "controller");
    defer std.testing.allocator.free(nested_controller);
    try temporary.dir.createDirPath(io, relative_root ++ "/nested-worktree");
    try writeSyntheticExecutable(
        temporary.dir,
        io,
        relative_root ++ "/nested-worktree/controller",
        "controller-v1\n",
        0o755,
    );
    try std.testing.expectError(error.RegisteredWorktreeRejected, observeDiControllerIdentity(
        std.testing.allocator,
        io,
        repository,
        nested_controller,
        registered,
    ));
}

test "baseline runner DI controller identity rejects non executable and oversized files" {
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    const io = std.testing.io;
    const relative_root = "repo/" ++ di_controller_root_relative;
    const relative_controller = relative_root ++ "/controller";
    try temporary.dir.createDirPath(io, relative_root);
    try writeSyntheticExecutable(temporary.dir, io, relative_controller, "controller-v1\n", 0o644);
    var temporary_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const temporary_length = try temporary.dir.realPath(io, &temporary_buffer);
    const temporary_root = temporary_buffer[0..temporary_length];
    const repository = try joinAbsolute(std.testing.allocator, temporary_root, "repo");
    defer std.testing.allocator.free(repository);
    const controller = try joinAbsolute(std.testing.allocator, repository, di_controller_root_relative ++ "/controller");
    defer std.testing.allocator.free(controller);
    const registered = try createSyntheticRegisteredWorktrees(std.testing.allocator, repository);
    defer freeSyntheticRegisteredWorktrees(std.testing.allocator, registered);
    try std.testing.expectError(error.WrongExecutable, observeDiControllerIdentity(
        std.testing.allocator,
        io,
        repository,
        controller,
        registered,
    ));

    var file = try temporary.dir.openFile(io, relative_controller, .{ .mode = .read_write });
    try file.setPermissions(io, std.Io.File.Permissions.fromMode(0o755));
    try file.setLength(io, maximum_artifact_bytes + 1);
    file.close(io);
    try std.testing.expectError(error.InputIdentityMismatch, observeDiControllerIdentity(
        std.testing.allocator,
        io,
        repository,
        controller,
        registered,
    ));
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

test "baseline runner accepts only successful bounded Zig build summaries" {
    var empty: [0]u8 = .{};
    var summary = "Build Summary: 3/3 steps succeeded\ninstall success\n".*;
    const valid = std.process.RunResult{
        .term = .{ .exited = 0 },
        .stdout = &empty,
        .stderr = &summary,
    };
    try expectSuccessfulBuildOutput(valid);

    var unexpected = "unexpected\n".*;
    var invalid = valid;
    invalid.stdout = &unexpected;
    try std.testing.expectError(error.ResultDrift, expectSuccessfulBuildOutput(invalid));
    invalid = valid;
    invalid.stderr = &empty;
    try std.testing.expectError(error.ResultDrift, expectSuccessfulBuildOutput(invalid));
    var wrong_prefix = "not a build summary\n".*;
    invalid.stderr = &wrong_prefix;
    try std.testing.expectError(error.ResultDrift, expectSuccessfulBuildOutput(invalid));
    var missing_newline = "Build Summary: 3/3 steps succeeded".*;
    invalid.stderr = &missing_newline;
    try std.testing.expectError(error.ResultDrift, expectSuccessfulBuildOutput(invalid));
}

test "baseline runner bounded file capture authenticates subject and exact output" {
    const io = std.testing.io;
    const zig_path = "/home/oleg/.zig/0.17.0/files/zig";
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
    try std.testing.expectEqualStrings("0.17.0\n", output);
}

test "baseline runner coverage status is exactly the authenticated touched set" {
    const touched = "src/a.zig\nsrc/b.zig\n";
    try validateCoverageStatus(" M src/a.zig\x00?? src/b.zig\x00", touched);
    try validateCoverageStatus(
        " M src/a.zig\x00?? src/b.zig\x00",
        "src/b.zig\nsrc/a.zig\n",
    );
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
        validateCoverageStatus(
            " M src/a.zig\x00?? src/b.zig\x00",
            "src/a.zig\nsrc/a.zig\nsrc/b.zig\n",
        ),
    );
    try std.testing.expectError(
        error.GitObservationMismatch,
        validateCoverageStatus("R  src/a.zig\x00?? src/b.zig\x00", touched),
    );
}

test "baseline runner manifest parser rejects malformed and escaping identities" {
    const valid = "0000000000000000000000000000000000000000000000000000000000000000  src/a.zig";
    const parsed = try parseManifestLine(valid);
    try std.testing.expectEqualStrings("src/a.zig", parsed.path);
    try std.testing.expectError(error.ManifestMismatch, parseManifestLine("00  src/a.zig"));
    try std.testing.expectError(
        error.ManifestMismatch,
        parseManifestLine("0000000000000000000000000000000000000000000000000000000000000000  ../escape"),
    );
    try std.testing.expectError(
        error.ManifestMismatch,
        parseManifestLine("0000000000000000000000000000000000000000000000000000000000000000  /absolute"),
    );
}

test "baseline runner bundle manifest namespace requires exact accepted prefix" {
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    const required_path = "manifests/member.txt";
    const contents = "authenticated bundle member\n";
    try temporary.dir.createDirPath(io, "bundle/manifests");
    try temporary.dir.writeFile(io, .{
        .sub_path = "bundle/" ++ required_path,
        .data = contents,
    });
    var root_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const root_length = try temporary.dir.realPath(io, &root_buffer);
    const bundle_root = try std.fmt.allocPrint(
        allocator,
        "{s}/bundle",
        .{root_buffer[0..root_length]},
    );
    defer allocator.free(bundle_root);

    const digest = sha256(contents);
    const digest_hex = std.fmt.bytesToHex(digest, .lower);
    const exact_manifest = try std.fmt.allocPrint(
        allocator,
        "{s}  {s}{s}\n",
        .{ &digest_hex, accepted_bundle_manifest_prefix, required_path },
    );
    defer allocator.free(exact_manifest);
    const member = try readAuthenticatedBundleMember(
        allocator,
        io,
        bundle_root,
        exact_manifest,
        required_path,
        &.{},
    );
    defer allocator.free(member);
    try std.testing.expectEqualStrings(contents, member);

    const absent_manifest = try std.fmt.allocPrint(
        allocator,
        "{s}  {s}manifests/other.txt\n",
        .{ &digest_hex, accepted_bundle_manifest_prefix },
    );
    defer allocator.free(absent_manifest);
    try std.testing.expectError(
        error.ManifestMismatch,
        readAuthenticatedBundleMember(
            allocator,
            io,
            bundle_root,
            absent_manifest,
            required_path,
            &.{},
        ),
    );

    const unprefixed_manifest = try std.fmt.allocPrint(
        allocator,
        "{s}  {s}\n",
        .{ &digest_hex, required_path },
    );
    defer allocator.free(unprefixed_manifest);
    try std.testing.expectError(
        error.ManifestMismatch,
        readAuthenticatedBundleMember(
            allocator,
            io,
            bundle_root,
            unprefixed_manifest,
            required_path,
            &.{},
        ),
    );

    const wrong_prefix_manifest = try std.fmt.allocPrint(
        allocator,
        "{s}  wrong/{s}\n",
        .{ &digest_hex, required_path },
    );
    defer allocator.free(wrong_prefix_manifest);
    try std.testing.expectError(
        error.ManifestMismatch,
        readAuthenticatedBundleMember(
            allocator,
            io,
            bundle_root,
            wrong_prefix_manifest,
            required_path,
            &.{},
        ),
    );

    const duplicate_manifest = try std.fmt.allocPrint(
        allocator,
        "{s}{s}",
        .{ exact_manifest, exact_manifest },
    );
    defer allocator.free(duplicate_manifest);
    try std.testing.expectError(
        error.ManifestMismatch,
        readAuthenticatedBundleMember(
            allocator,
            io,
            bundle_root,
            duplicate_manifest,
            required_path,
            &.{},
        ),
    );

    var wrong_digest = digest;
    wrong_digest[0] ^= 1;
    const wrong_digest_hex = std.fmt.bytesToHex(wrong_digest, .lower);
    const digest_mismatch_manifest = try std.fmt.allocPrint(
        allocator,
        "{s}  {s}{s}\n",
        .{ &wrong_digest_hex, accepted_bundle_manifest_prefix, required_path },
    );
    defer allocator.free(digest_mismatch_manifest);
    try std.testing.expectError(
        error.ManifestMismatch,
        readAuthenticatedBundleMember(
            allocator,
            io,
            bundle_root,
            digest_mismatch_manifest,
            required_path,
            &.{},
        ),
    );
}

test "baseline runner source manifest preserves accepted nonlexical order and rejects duplicates" {
    var temporary = std.testing.tmpDir(.{});
    defer temporary.cleanup();
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    try temporary.dir.writeFile(io, .{ .sub_path = "z.zig", .data = "z\n" });
    try temporary.dir.writeFile(io, .{ .sub_path = "a.zig", .data = "a\n" });
    var root_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
    const root_length = try temporary.dir.realPath(io, &root_buffer);
    const source_root = root_buffer[0..root_length];
    const z_hex = std.fmt.bytesToHex(sha256("z\n"), .lower);
    const a_hex = std.fmt.bytesToHex(sha256("a\n"), .lower);
    const manifest = try std.fmt.allocPrint(
        allocator,
        "{s}  z.zig\n{s}  a.zig\n",
        .{ &z_hex, &a_hex },
    );
    defer allocator.free(manifest);
    try std.testing.expectEqual(
        sha256(manifest),
        try verifySourceManifest(allocator, io, source_root, manifest, &.{}),
    );

    const duplicate = try std.fmt.allocPrint(
        allocator,
        "{s}  z.zig\n{s}  z.zig\n",
        .{ &z_hex, &z_hex },
    );
    defer allocator.free(duplicate);
    try std.testing.expectError(
        error.ManifestMismatch,
        verifySourceManifest(allocator, io, source_root, duplicate, &.{}),
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
    const parsed = try parseReadelfFunctions(
        std.testing.allocator,
        "0: 0000000000000000 0 NOTYPE LOCAL DEFAULT UND\n" ++
            "1: 0000000000000000 1 FUNC GLOBAL DEFAULT 1 alpha\n" ++
            "2: 0000000000000001 1 FUNC GLOBAL DEFAULT 1 beta\n",
        &.{ "alpha", "beta" },
    );
    defer std.testing.allocator.free(parsed);
    try std.testing.expectEqualStrings("alpha", parsed[0].name);
    try std.testing.expectEqualStrings("beta", parsed[1].name);
    try validateObjdumpFunctions(
        "0000000000000000 <exported_alpha>:\n0000000000000001 <beta>:\n",
        &rows,
    );
    try std.testing.expectError(
        error.ParseFailure,
        validateObjdumpFunctions("0000000000000000 <alpha>:\n", &rows),
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
    try std.testing.expectError(
        error.RepetitionCountMismatch,
        contract.validateCanonicalRepetitions(&.{}, syntheticRawReportBinding()),
    );
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
        .position_requests = @splat(0),
        .position_stages = @splat(0),
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
        "family\ttransactions\trequests_registered\tactions_attached\targuments_staged\tmaterializations_completed\tactions_completed\tcommits\n" ++
        "direct_call\t2\t3\t2\t3\t2\t2\t2\n" ++
        "int_byte_size_call\t2\t2\t2\t2\t2\t2\t2\n" ++
        "unexpected_family_events\t0\n" ++
        "argument_index_overflow_events\t0\n" ++
        "family\tposition\trequests_registered\targuments_staged\n" ++
        "direct_call\t0\t2\t2\n" ++
        "direct_call\t1\t1\t1\n" ++
        "direct_call\t2\t0\t0\n" ++
        "direct_call\t3\t0\t0\n" ++
        "direct_call\t4\t0\t0\n" ++
        "direct_call\t5\t0\t0\n" ++
        "int_byte_size_call\t0\t2\t2\n" ++
        "int_byte_size_call\t1\t0\t0\n" ++
        "int_byte_size_call\t2\t0\t0\n" ++
        "int_byte_size_call\t3\t0\t0\n" ++
        "int_byte_size_call\t4\t0\t0\n" ++
        "int_byte_size_call\t5\t0\t0\n";
    const parsed = try parseCoverageChannel(channel);
    try std.testing.expectEqual(@as(u64, 3), parsed.families.direct_call.requests);
    try std.testing.expectEqual(@as(u64, 2), parsed.families.int_byte_size_call.transactions);
    try std.testing.expectEqual(@as(u64, 0), parsed.unexpected_family_events);
    try std.testing.expectError(error.MalformedCounterChannel, parseCoverageChannel("schema\twrong\n"));
    try std.testing.expectError(
        error.MalformedCounterChannel,
        parseCoverageChannel(channel ++ "schema\to2_calls_crt_v1_coverage_v1\n"),
    );
    const truncated = channel[0 .. channel.len - "int_byte_size_call\t5\t0\t0\n".len];
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
        .raw_report = syntheticRawReportBinding(),
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
    evidence_drift = binding;
    evidence_drift.raw_report.failure_order_sha256[0] ^= 1;
    try std.testing.expectError(
        error.ClosurePrecondition,
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
        .raw_report = syntheticRawReportBinding(),
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
    observation.raw_report.selected_functions += 1;
    observation.raw_report.failed_functions += 1;
    try std.testing.expectError(error.SuccessfulFunctionCountMismatch, validateCompleteRun(observation));
    observation.raw_report = syntheticRawReportBinding();
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
