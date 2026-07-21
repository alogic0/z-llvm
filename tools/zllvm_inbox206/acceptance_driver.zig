const std = @import("std");
const builtin = @import("builtin");
const provenance = @import("provenance.zig");
const receipt_module = @import("receipt.zig");

const GitSha1Identity = provenance.GitSha1Identity;
const RawSha256Identity = provenance.RawSha256Identity;
const CanonicalRepositoryPath = provenance.CanonicalRepositoryPath;
const CanonicalSourceIdentity = provenance.CanonicalSourceIdentity;
const CanonicalSourceSet = provenance.CanonicalSourceSet;
const capability_source_count = provenance.capability_source_count;
const capability_source_paths = provenance.capability_source_paths;
const capability_source_mode = provenance.capability_source_mode;
const canonical_git_sha1_algorithm = provenance.canonical_git_sha1_algorithm;
const fixedIdentity = provenance.fixedIdentity;
const canonicalRepositoryPath = provenance.canonicalRepositoryPath;
const validateCanonicalRepositoryPath = provenance.validateCanonicalRepositoryPath;
const equalGitIdentity = provenance.equalGitIdentity;
const equalRawIdentity = provenance.equalRawIdentity;
const equalCanonicalPath = provenance.equalCanonicalPath;
const equalCanonicalSourceIdentity = provenance.equalCanonicalSourceIdentity;
const equalCanonicalSourceSet = provenance.equalCanonicalSourceSet;
const canonicalSourceIdentity = provenance.canonicalSourceIdentity;
const canonicalSourceSetFromBytes = provenance.canonicalSourceSetFromBytes;

fn validatedCanonicalPathSlice(path: *const CanonicalRepositoryPath) ![]const u8 {
    try validateCanonicalRepositoryPath(path);
    const length = std.math.cast(usize, path.length) orelse return error.StagedPathMismatch;
    return path.bytes[0..length];
}

const receipt_schema_version = receipt_module.receipt_schema_version;
const receipt_capability_version = receipt_module.receipt_capability_version;
const receipt_required_semantic_bits = receipt_module.receipt_required_semantic_bits;
const CanonicalReceiptToken = receipt_module.CanonicalReceiptToken;
const CanonicalAcceptanceReceipt = receipt_module.CanonicalAcceptanceReceipt;
const PublicationResult = receipt_module.PublicationResult;
const validateCanonicalReceiptToken = receipt_module.validateCanonicalReceiptToken;
const validateCanonicalReceipt = receipt_module.validateCanonicalReceipt;
const encodeCanonicalReceipt = receipt_module.encodeCanonicalReceipt;
const canonicalReceiptToken = receipt_module.canonicalReceiptToken;
const encodeLowerHex = receipt_module.encodeLowerHex;
const decodeLowerHex = receipt_module.decodeLowerHex;
const canonicalReceiptBytesSlice = receipt_module.canonicalReceiptBytesSlice;
const publicationReceiptBytesSlice = receipt_module.publicationReceiptBytesSlice;
const equalPublicationReceiptBytes = receipt_module.equalPublicationReceiptBytes;
const validatePublicationTargetValue = receipt_module.validatePublicationTargetValue;

pub const AuthorityDescriptorIdentity = struct {
    device_major: u32,
    device_minor: u32,
    inode: u64,
    mount_id_unique: u64,
};

pub const DriverError = error{
    AcceptanceAdaptersUnavailable,
    DriverPhaseViolation,
    AuthorityContextMismatch,
    RepositoryDescriptorMismatch,
    ValidationDescriptorMismatch,
    DriverLaunchMismatch,
    ToolchainMismatch,
    ReceiptIdentityMalformed,
    ProcessSpecificationMismatch,
    ProcessExecutableMismatch,
    ProcessOutputUnbounded,
    ProcessOutputTruncated,
    ProcessOutputIncomplete,
    ProcessArgumentMalformed,
    ProcessArgvMismatch,
    ProcessEnvironmentInherited,
    ProcessEnvironmentDuplicate,
    ProcessEnvironmentMalformed,
    ProcessEnvironmentUnexpected,
    ProcessEnvironmentMismatch,
    ProcessWorkingDirectoryMismatch,
    ProcessExecutablePathMismatch,
    ProcessExecutableDescriptorMismatch,
    ProcessExecutableHandoffMismatch,
    ProcessExecutableAuthorityUnavailable,
    ProcessFixtureConsumed,
    ProcessLaunchFailure,
    ProcessReadFailure,
    ProcessWaitFailure,
    CaptureUnavailable,
    ProcessExitedNonzero,
    ProcessSignaled,
    ProcessStopped,
    ProcessTerminationUnknown,
    GitOutputMalformed,
    GitOutputExtra,
    GitObjectAlgorithmUnsupported,
    StagedPathMismatch,
    ExtraStagedPath,
    MissingStagedPath,
    DuplicateStagedPath,
    StagedOrderMismatch,
    StagedStatusMismatch,
    StagedModeMismatch,
    StagedStageMismatch,
    StagedRecordTypeUnsupported,
    StagedRecordTrailing,
    IndexStateUnexpected,
    SourceBytesMismatch,
    SourceCaptureOversized,
    SourceLengthMismatch,
    SourceDigestMismatch,
    StagedBlobMismatch,
    StagedTreeMismatch,
    SemanticGateFailed,
    SemanticGateDuplicate,
    SemanticGateMissing,
    SemanticGateUnknown,
    PublicationPreparedMismatch,
    PublicationContextMismatch,
    PublicationDirectoryMismatch,
    PublicationTargetMismatch,
    PublicationBytesMismatch,
    PublicationDigestMismatch,
    PublicationLengthMismatch,
    PublicationIncomplete,
    PublicationTargetInvalid,
    PathBFixedInputMismatch,
    PathBLaunchFailed,
    PathBStatusMismatch,
    PathBOutputBoundExceeded,
    PathBInconsistentResult,
    PathBReceiptMalformed,
    PathBReceiptBindingMismatch,
};

pub const DriverProcessId = enum {
    git_object_format,
    git_staged_listing,
    git_staged_tree,
    zig_format_check,
    zig_focused_test,
};

pub const ProcessEnvironmentMode = enum {
    closed_allowlist,
};

pub const ProcessTermination = union(enum) {
    exited: u8,
    signaled: u8,
    stopped: u8,
    unknown: u32,
};

pub const FixedProcessSpecification = struct {
    id: DriverProcessId,
    executable: []const u8,
    argv: []const []const u8,
    environment: []const []const u8,
    environment_mode: ProcessEnvironmentMode,
    stdout_limit: usize,
    stderr_limit: usize,
    permitted_termination: ProcessTermination = .{ .exited = 0 },
};

pub const git_environment = [_][]const u8{
    "LC_ALL=C",
    "GIT_CONFIG_NOSYSTEM=1",
    "GIT_CONFIG_GLOBAL=/dev/null",
    "GIT_CONFIG_COUNT=0",
    "GIT_OPTIONAL_LOCKS=0",
    "GIT_TERMINAL_PROMPT=0",
    "GIT_PAGER=cat",
    "PAGER=cat",
};

pub const zig_environment = [_][]const u8{
    "LC_ALL=C",
    "ZIG_LOCAL_CACHE_DIR=local-state/caches/inbox206cn/local",
    "ZIG_GLOBAL_CACHE_DIR=local-state/caches/inbox206cn/global",
};

pub const git_object_format_argv = [_][]const u8{
    "/usr/bin/git",
    "-C",
    "/home/oleg/prog/z_llvm",
    "rev-parse",
    "--show-object-format",
};

pub const git_staged_listing_argv = [_][]const u8{
    "/usr/bin/git",
    "-C",
    "/home/oleg/prog/z_llvm",
    "-c",
    "core.fsmonitor=false",
    "-c",
    "core.untrackedCache=false",
    "status",
    "--porcelain=v2",
    "-z",
    "--untracked-files=all",
    "--no-ahead-behind",
    "--ignore-submodules=none",
    "--no-renames",
};

pub const git_staged_tree_argv = [_][]const u8{
    "/usr/bin/git",
    "-C",
    "/home/oleg/prog/z_llvm",
    "write-tree",
};

pub const zig_format_argv = [_][]const u8{
    "/home/oleg/.zig/0.16.0/files/zig",
    "fmt",
    "--check",
    capability_source_paths[0],
    capability_source_paths[1],
    capability_source_paths[2],
    capability_source_paths[3],
    capability_source_paths[4],
};

pub const zig_focused_test_argv = [_][]const u8{
    "/home/oleg/.zig/0.16.0/files/zig",
    "build",
    "test-inbox206-descriptor-identity",
};

pub const driver_process_specs = [_]FixedProcessSpecification{
    .{
        .id = .git_object_format,
        .executable = "/usr/bin/git",
        .argv = &git_object_format_argv,
        .environment = &git_environment,
        .environment_mode = .closed_allowlist,
        .stdout_limit = 16,
        .stderr_limit = 4096,
    },
    .{
        .id = .git_staged_listing,
        .executable = "/usr/bin/git",
        .argv = &git_staged_listing_argv,
        .environment = &git_environment,
        .environment_mode = .closed_allowlist,
        .stdout_limit = 4096,
        .stderr_limit = 4096,
    },
    .{
        .id = .git_staged_tree,
        .executable = "/usr/bin/git",
        .argv = &git_staged_tree_argv,
        .environment = &git_environment,
        .environment_mode = .closed_allowlist,
        .stdout_limit = 64,
        .stderr_limit = 4096,
    },
    .{
        .id = .zig_format_check,
        .executable = "/home/oleg/.zig/0.16.0/files/zig",
        .argv = &zig_format_argv,
        .environment = &zig_environment,
        .environment_mode = .closed_allowlist,
        .stdout_limit = 4096,
        .stderr_limit = 65536,
    },
    .{
        .id = .zig_focused_test,
        .executable = "/home/oleg/.zig/0.16.0/files/zig",
        .argv = &zig_focused_test_argv,
        .environment = &zig_environment,
        .environment_mode = .closed_allowlist,
        .stdout_limit = 65536,
        .stderr_limit = 65536,
    },
};

pub fn processSpecification(id: DriverProcessId) *const FixedProcessSpecification {
    return &driver_process_specs[@intFromEnum(id)];
}

pub const source_capture_max_bytes: usize = 1024 * 1024;

/// Borrowed process bytes are valid only for the duration of one normalizer
/// call. No value returned from this module retains either slice.
pub const ObservedProcessResult = struct {
    specification_id: DriverProcessId,
    executable_identity: RawSha256Identity,
    stdout: []const u8,
    stderr: []const u8,
    stdout_truncated: bool = false,
    stderr_truncated: bool = false,
    termination: ProcessTermination = .{ .exited = 0 },
};

pub const AuthenticatedProcessResult = struct {
    context: *const AcceptanceAuthorityContext,
    bootstrap: AuthenticatedBootstrap,
    specification_id: DriverProcessId,
};

pub const ObservedRepositoryScope = struct {
    descriptor_identity: AuthorityDescriptorIdentity,
};

pub const ValidatedRepositoryScope = struct {
    descriptor_identity: AuthorityDescriptorIdentity,
};

pub const AuthenticatedRepositoryScope = struct {
    context: *const AcceptanceAuthorityContext,
    descriptor_identity: AuthorityDescriptorIdentity,
};

pub const ObservedBootstrap = struct {
    driver_launch_identity: RawSha256Identity,
    zig_executable_identity: RawSha256Identity,
    git_executable_identity: RawSha256Identity,
    zig_toolchain_identity: CanonicalReceiptToken,
};

pub const ValidatedBootstrap = struct {
    driver_launch_identity: RawSha256Identity,
    zig_executable_identity: RawSha256Identity,
    git_executable_identity: RawSha256Identity,
    zig_toolchain_identity: CanonicalReceiptToken,
};

pub const AuthenticatedBootstrap = struct {
    context: *const AcceptanceAuthorityContext,
    zig_executable_identity: RawSha256Identity,
    git_executable_identity: RawSha256Identity,
    zig_toolchain_identity: CanonicalReceiptToken,
};

/// Borrowed source bytes are consumed completely by one staged-source
/// normalizer call. Returned authenticated values contain identities only.
pub const ObservedSourceCapture = struct {
    context: *const AcceptanceAuthorityContext,
    path: CanonicalRepositoryPath,
    staged_bytes: []const u8,
    worktree_bytes: []const u8,
};

pub const ObservedStagedSource = struct {
    object_format: ObservedProcessResult,
    staged_listing: ObservedProcessResult,
    staged_tree: ObservedProcessResult,
    sources: [capability_source_count]ObservedSourceCapture,
};

pub const ValidatedStagedSource = struct {
    context: *const AcceptanceAuthorityContext,
    source_set: CanonicalSourceSet,
    tree_identity: GitSha1Identity,
};

pub const AuthenticatedStagedSource = struct {
    context: *const AcceptanceAuthorityContext,
    source_set: CanonicalSourceSet,
    tree_identity: GitSha1Identity,
};

pub const ObservedValidationDirectory = struct {
    descriptor_identity: AuthorityDescriptorIdentity,
};

pub const ValidatedValidationDirectory = struct {
    descriptor_identity: AuthorityDescriptorIdentity,
};

pub const AuthenticatedValidationDirectory = struct {
    context: *const AcceptanceAuthorityContext,
    descriptor_identity: AuthorityDescriptorIdentity,
};

pub const AcceptanceAuthorityContext = struct {
    repository_identity: AuthorityDescriptorIdentity,
    validation_identity: AuthorityDescriptorIdentity,
    driver_launch_identity: RawSha256Identity,
    zig_executable_identity: RawSha256Identity,
    git_executable_identity: RawSha256Identity,
    zig_toolchain_identity: CanonicalReceiptToken,
    source_set: CanonicalSourceSet,
    tree_identity: GitSha1Identity,
};

fn validateAuthenticatedBootstrapBuffers(
    bootstrap: AuthenticatedBootstrap,
    context: *const AcceptanceAuthorityContext,
) !void {
    if (bootstrap.context != context) return error.AuthorityContextMismatch;
    validateCanonicalReceiptToken(&bootstrap.zig_toolchain_identity) catch
        return error.ReceiptIdentityMalformed;
    validateCanonicalReceiptToken(&context.zig_toolchain_identity) catch
        return error.ReceiptIdentityMalformed;
}

pub fn validateObservedRepositoryScope(
    observed: ObservedRepositoryScope,
) ValidatedRepositoryScope {
    return .{ .descriptor_identity = observed.descriptor_identity };
}

pub fn authenticateValidatedRepositoryScope(
    validated: ValidatedRepositoryScope,
    context: *const AcceptanceAuthorityContext,
) DriverError!AuthenticatedRepositoryScope {
    if (!std.meta.eql(validated.descriptor_identity, context.repository_identity)) {
        return error.RepositoryDescriptorMismatch;
    }
    return .{
        .context = context,
        .descriptor_identity = validated.descriptor_identity,
    };
}

pub fn validateObservedBootstrap(observed: ObservedBootstrap) !ValidatedBootstrap {
    validateCanonicalReceiptToken(&observed.zig_toolchain_identity) catch
        return error.ReceiptIdentityMalformed;
    return .{
        .driver_launch_identity = observed.driver_launch_identity,
        .zig_executable_identity = observed.zig_executable_identity,
        .git_executable_identity = observed.git_executable_identity,
        .zig_toolchain_identity = observed.zig_toolchain_identity,
    };
}

pub fn authenticateValidatedBootstrap(
    validated: ValidatedBootstrap,
    context: *const AcceptanceAuthorityContext,
) DriverError!AuthenticatedBootstrap {
    validateCanonicalReceiptToken(&validated.zig_toolchain_identity) catch
        return error.ReceiptIdentityMalformed;
    validateCanonicalReceiptToken(&context.zig_toolchain_identity) catch
        return error.ReceiptIdentityMalformed;
    if (!equalRawIdentity(validated.driver_launch_identity, context.driver_launch_identity)) {
        return error.DriverLaunchMismatch;
    }
    if (!equalRawIdentity(validated.zig_executable_identity, context.zig_executable_identity) or
        !equalRawIdentity(validated.git_executable_identity, context.git_executable_identity) or
        !std.meta.eql(validated.zig_toolchain_identity, context.zig_toolchain_identity))
    {
        return error.ToolchainMismatch;
    }
    return .{
        .context = context,
        .zig_executable_identity = validated.zig_executable_identity,
        .git_executable_identity = validated.git_executable_identity,
        .zig_toolchain_identity = validated.zig_toolchain_identity,
    };
}

fn validateProcessObservation(
    observed: ObservedProcessResult,
    expected_id: DriverProcessId,
    stdout: []const u8,
    stderr: []const u8,
    bootstrap: AuthenticatedBootstrap,
    context: *const AcceptanceAuthorityContext,
) DriverError!AuthenticatedProcessResult {
    if (observed.specification_id != expected_id) {
        return error.ProcessSpecificationMismatch;
    }
    const specification = processSpecification(expected_id);
    if (observed.stdout_truncated or observed.stderr_truncated) {
        return error.ProcessOutputTruncated;
    }
    if (stdout.len > specification.stdout_limit or
        stderr.len > specification.stderr_limit)
    {
        return error.ProcessOutputUnbounded;
    }
    if (!std.meta.eql(observed.termination, specification.permitted_termination)) {
        switch (observed.termination) {
            .exited => return error.ProcessExitedNonzero,
            .signaled => return error.ProcessSignaled,
            .stopped => return error.ProcessStopped,
            .unknown => return error.ProcessTerminationUnknown,
        }
    }
    try validateAuthenticatedBootstrapBuffers(bootstrap, context);
    if (!equalRawIdentity(bootstrap.zig_executable_identity, context.zig_executable_identity) or
        !equalRawIdentity(bootstrap.git_executable_identity, context.git_executable_identity) or
        !std.meta.eql(bootstrap.zig_toolchain_identity, context.zig_toolchain_identity))
    {
        return error.ToolchainMismatch;
    }
    const expected_identity = switch (observed.specification_id) {
        .git_object_format, .git_staged_listing, .git_staged_tree => bootstrap.git_executable_identity,
        .zig_format_check, .zig_focused_test => bootstrap.zig_executable_identity,
    };
    if (!equalRawIdentity(observed.executable_identity, expected_identity)) {
        return error.ProcessExecutableMismatch;
    }
    return .{
        .context = context,
        .bootstrap = bootstrap,
        .specification_id = expected_id,
    };
}

/// Copies raw captures into this call frame, validates only those copies, and
/// frees both allocations before returning a fixed, safely copyable token.
pub fn normalizeAuthenticatedProcessResult(
    allocator: std.mem.Allocator,
    observed: ObservedProcessResult,
    expected_id: DriverProcessId,
    bootstrap: AuthenticatedBootstrap,
    context: *const AcceptanceAuthorityContext,
) !AuthenticatedProcessResult {
    const specification = processSpecification(expected_id);
    if (observed.stdout.len > specification.stdout_limit or
        observed.stderr.len > specification.stderr_limit)
    {
        return error.ProcessOutputUnbounded;
    }
    const stdout = try allocator.dupe(u8, observed.stdout);
    defer allocator.free(stdout);
    const stderr = try allocator.dupe(u8, observed.stderr);
    defer allocator.free(stderr);
    return validateProcessObservation(
        observed,
        expected_id,
        stdout,
        stderr,
        bootstrap,
        context,
    );
}

const expected_supplier_witness = struct { marker: u8 }{ .marker = 1 };
const observation_supplier_witness = struct { marker: u8 }{ .marker = 2 };
const admitted_executable_witness = struct { marker: u8 }{ .marker = 3 };
const forged_executable_witness = struct { marker: u8 }{ .marker = 4 };

const SyntheticExpectedExecutableFacts = struct {
    context: *const AcceptanceAuthorityContext,
    process_id: DriverProcessId,
    canonical_path_sha256: RawSha256Identity,
    sha256: RawSha256Identity,
    authorized_channel_identity: RawSha256Identity,
};

const SyntheticExpectedExecutableCapability = struct {
    witness: ?*const anyopaque,
    facts: SyntheticExpectedExecutableFacts,
};

const SyntheticObservedExecutableFacts = struct {
    context: *const AcceptanceAuthorityContext,
    process_id: DriverProcessId,
    descriptor_identity: AuthorityDescriptorIdentity,
    canonical_path_sha256: RawSha256Identity,
    sha256: RawSha256Identity,
    authorized_channel_identity: RawSha256Identity,
    handoff_identity: RawSha256Identity,
    observation_boundary_identity: RawSha256Identity,
};

const SyntheticObservedExecutableCapability = struct {
    witness: ?*const anyopaque,
    facts: SyntheticObservedExecutableFacts,
};

/// Fixed, ownership-free admission result. The canonical path is represented
/// only by its checked digest; no borrowed raw authority enters the request.
const AuthenticatedExecutableToken = struct {
    context: *const AcceptanceAuthorityContext,
    process_id: DriverProcessId,
    descriptor_identity: AuthorityDescriptorIdentity,
    canonical_path_sha256: RawSha256Identity,
    executable_sha256: RawSha256Identity,
    handoff_identity: RawSha256Identity,
    witness: ?*const anyopaque,
};

const SyntheticWorkingDirectoryAuthority = struct {
    context: *const AcceptanceAuthorityContext,
    descriptor_identity: AuthorityDescriptorIdentity,
    authenticated: bool,
};

const SyntheticClosedEnvironment = struct {
    constructed_from_empty: bool,
    entries: []const []const u8,
};

const SyntheticNativeProcessRequest = struct {
    executable: AuthenticatedExecutableToken,
    argv: []const []const u8,
    environment: SyntheticClosedEnvironment,
    working_directory: SyntheticWorkingDirectoryAuthority,
};

const SyntheticProcessStream = enum {
    stdout,
    stderr,
};

/// One readiness event from a synthetic deadlock-safe dual-stream drain. The
/// adapter consumes the complete ordered event sequence rather than draining
/// either stream to completion before observing the other.
const SyntheticProcessReadEvent = union(enum) {
    chunk: struct {
        stream: SyntheticProcessStream,
        bytes: []const u8,
    },
    eof: SyntheticProcessStream,
    truncated: SyntheticProcessStream,
    read_failure: SyntheticProcessStream,
};

const SyntheticNativeProcessFixture = struct {
    events: []const SyntheticProcessReadEvent,
    termination: ProcessTermination = .{ .exited = 0 },
    launch_failure: bool = false,
    wait_failure: bool = false,
    launch_attempts: usize = 0,
    wait_attempts: usize = 0,
    lifecycle: SyntheticChildLifecycle = .not_launched,
    drained_events: usize = 0,
    stdout_events: usize = 0,
    stderr_events: usize = 0,
};

const SyntheticChildLifecycle = enum {
    not_launched,
    launched_pending,
    wait_attempted_unconfirmed,
    confirmed_reaped,
    wait_failed_disposition_unknown,
};

fn expectedExecutableIdentity(
    process_id: DriverProcessId,
    bootstrap: AuthenticatedBootstrap,
) RawSha256Identity {
    return switch (process_id) {
        .git_object_format, .git_staged_listing, .git_staged_tree => bootstrap.git_executable_identity,
        .zig_format_check, .zig_focused_test => bootstrap.zig_executable_identity,
    };
}

fn descriptorIdentityIsZero(identity: AuthorityDescriptorIdentity) bool {
    return identity.device_major == 0 and
        identity.device_minor == 0 and
        identity.inode == 0 and
        identity.mount_id_unique == 0;
}

fn rawIdentityIsZero(identity: RawSha256Identity) bool {
    return std.mem.allEqual(u8, &identity.bytes, 0);
}

fn validateCanonicalAbsoluteExecutablePath(path: []const u8) DriverError!void {
    if (path.len < 2 or path[0] != '/' or path[path.len - 1] == '/' or
        std.mem.indexOfScalar(u8, path, 0) != null)
    {
        return error.ProcessExecutablePathMismatch;
    }
    var components = std.mem.splitScalar(u8, path[1..], '/');
    while (components.next()) |component| {
        if (component.len == 0 or
            std.mem.eql(u8, component, ".") or
            std.mem.eql(u8, component, ".."))
        {
            return error.ProcessExecutablePathMismatch;
        }
    }
}

fn executablePathIdentity(path: []const u8) RawSha256Identity {
    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(path, &digest, .{});
    return .{ .bytes = digest };
}

fn hasPrivateWitness(actual: ?*const anyopaque, expected: *const anyopaque) bool {
    return actual != null and actual.? == expected;
}

fn validateExpectedExecutableCapability(
    capability: SyntheticExpectedExecutableCapability,
    expected_id: DriverProcessId,
    bootstrap: AuthenticatedBootstrap,
    context: *const AcceptanceAuthorityContext,
) DriverError!void {
    if (!hasPrivateWitness(capability.witness, &expected_supplier_witness)) {
        return error.ProcessExecutableAuthorityUnavailable;
    }
    if (capability.facts.context != context) return error.AuthorityContextMismatch;
    if (capability.facts.process_id != expected_id) return error.ProcessSpecificationMismatch;
    const specification = processSpecification(expected_id);
    if (!equalRawIdentity(
        capability.facts.canonical_path_sha256,
        executablePathIdentity(specification.executable),
    )) return error.ProcessExecutablePathMismatch;
    if (!equalRawIdentity(
        capability.facts.sha256,
        expectedExecutableIdentity(expected_id, bootstrap),
    )) return error.ProcessExecutableMismatch;
    if (!equalRawIdentity(
        capability.facts.authorized_channel_identity,
        syntheticExecutableChannelIdentity(expected_id),
    )) return error.ProcessExecutableHandoffMismatch;
}

fn validateObservedExecutableCapability(
    capability: SyntheticObservedExecutableCapability,
    expected_id: DriverProcessId,
    bootstrap: AuthenticatedBootstrap,
    context: *const AcceptanceAuthorityContext,
) DriverError!void {
    if (!hasPrivateWitness(capability.witness, &observation_supplier_witness)) {
        return error.ProcessExecutableAuthorityUnavailable;
    }
    if (capability.facts.context != context) return error.AuthorityContextMismatch;
    if (capability.facts.process_id != expected_id) return error.ProcessSpecificationMismatch;
    if (!std.meta.eql(
        capability.facts.descriptor_identity,
        syntheticExecutableDescriptorIdentity(expected_id),
    )) return error.ProcessExecutableDescriptorMismatch;
    const specification = processSpecification(expected_id);
    if (!equalRawIdentity(
        capability.facts.canonical_path_sha256,
        executablePathIdentity(specification.executable),
    )) return error.ProcessExecutablePathMismatch;
    if (!equalRawIdentity(
        capability.facts.sha256,
        expectedExecutableIdentity(expected_id, bootstrap),
    )) return error.ProcessExecutableMismatch;
    const channel_identity = syntheticExecutableChannelIdentity(expected_id);
    if (!equalRawIdentity(
        capability.facts.authorized_channel_identity,
        channel_identity,
    ) or !equalRawIdentity(capability.facts.handoff_identity, channel_identity)) {
        return error.ProcessExecutableHandoffMismatch;
    }
    if (!equalRawIdentity(
        capability.facts.observation_boundary_identity,
        syntheticObservationBoundaryIdentity(expected_id),
    )) return error.ProcessExecutableAuthorityUnavailable;
}

fn admitSyntheticExecutableToken(
    expected: SyntheticExpectedExecutableCapability,
    observed: SyntheticObservedExecutableCapability,
    expected_id: DriverProcessId,
    bootstrap: AuthenticatedBootstrap,
    context: *const AcceptanceAuthorityContext,
) DriverError!AuthenticatedExecutableToken {
    try validateAuthenticatedBootstrapBuffers(bootstrap, context);
    try validateExpectedExecutableCapability(expected, expected_id, bootstrap, context);
    try validateObservedExecutableCapability(observed, expected_id, bootstrap, context);
    const specification = processSpecification(expected_id);
    try validateCanonicalAbsoluteExecutablePath(specification.executable);
    const required_path_identity = executablePathIdentity(specification.executable);
    if (!equalRawIdentity(expected.facts.canonical_path_sha256, required_path_identity) or
        !equalRawIdentity(observed.facts.canonical_path_sha256, required_path_identity) or
        !equalRawIdentity(
            expected.facts.canonical_path_sha256,
            observed.facts.canonical_path_sha256,
        ))
    {
        return error.ProcessExecutablePathMismatch;
    }
    if (descriptorIdentityIsZero(observed.facts.descriptor_identity)) {
        return error.ProcessExecutableAuthorityUnavailable;
    }
    const required_sha256 = expectedExecutableIdentity(expected_id, bootstrap);
    if (!equalRawIdentity(expected.facts.sha256, required_sha256) or
        !equalRawIdentity(observed.facts.sha256, required_sha256) or
        !equalRawIdentity(expected.facts.sha256, observed.facts.sha256))
    {
        return error.ProcessExecutableMismatch;
    }
    if (rawIdentityIsZero(expected.facts.authorized_channel_identity) or
        rawIdentityIsZero(observed.facts.authorized_channel_identity) or
        rawIdentityIsZero(observed.facts.handoff_identity))
    {
        return error.ProcessExecutableAuthorityUnavailable;
    }
    if (!equalRawIdentity(
        expected.facts.authorized_channel_identity,
        observed.facts.authorized_channel_identity,
    ) or !equalRawIdentity(
        observed.facts.authorized_channel_identity,
        observed.facts.handoff_identity,
    )) {
        return error.ProcessExecutableHandoffMismatch;
    }
    return .{
        .context = context,
        .process_id = expected_id,
        .descriptor_identity = observed.facts.descriptor_identity,
        .canonical_path_sha256 = required_path_identity,
        .executable_sha256 = observed.facts.sha256,
        .handoff_identity = observed.facts.handoff_identity,
        .witness = &admitted_executable_witness,
    };
}

fn validateAuthenticatedExecutableToken(
    token: AuthenticatedExecutableToken,
    expected_id: DriverProcessId,
    bootstrap: AuthenticatedBootstrap,
    context: *const AcceptanceAuthorityContext,
) DriverError!void {
    if (!hasPrivateWitness(token.witness, &admitted_executable_witness)) {
        return error.ProcessExecutableAuthorityUnavailable;
    }
    if (token.context != context) return error.AuthorityContextMismatch;
    if (token.process_id != expected_id) return error.ProcessSpecificationMismatch;
    if (descriptorIdentityIsZero(token.descriptor_identity) or
        rawIdentityIsZero(token.handoff_identity))
    {
        return error.ProcessExecutableAuthorityUnavailable;
    }
    const specification = processSpecification(expected_id);
    const required_path_identity = executablePathIdentity(specification.executable);
    if (!equalRawIdentity(token.canonical_path_sha256, required_path_identity)) {
        return error.ProcessExecutablePathMismatch;
    }
    if (!equalRawIdentity(
        token.executable_sha256,
        expectedExecutableIdentity(expected_id, bootstrap),
    )) return error.ProcessExecutableMismatch;
    if (!equalRawIdentity(
        token.handoff_identity,
        syntheticExecutableChannelIdentity(expected_id),
    )) return error.ProcessExecutableHandoffMismatch;
    if (!std.meta.eql(
        token.descriptor_identity,
        syntheticExecutableDescriptorIdentity(expected_id),
    )) return error.ProcessExecutableDescriptorMismatch;
}

fn validateEnvironmentName(entry: []const u8) DriverError![]const u8 {
    if (entry.len == 0 or std.mem.indexOfScalar(u8, entry, 0) != null) {
        return error.ProcessEnvironmentMalformed;
    }
    const separator = std.mem.indexOfScalar(u8, entry, '=') orelse
        return error.ProcessEnvironmentMalformed;
    if (separator == 0) return error.ProcessEnvironmentMalformed;
    const name = entry[0..separator];
    if (!(std.ascii.isAlphabetic(name[0]) or name[0] == '_')) {
        return error.ProcessEnvironmentMalformed;
    }
    for (name[1..]) |byte| {
        if (!(std.ascii.isAlphanumeric(byte) or byte == '_')) {
            return error.ProcessEnvironmentMalformed;
        }
    }
    return name;
}

fn validateClosedEnvironment(
    observed: SyntheticClosedEnvironment,
    expected: []const []const u8,
) DriverError!void {
    if (!observed.constructed_from_empty) return error.ProcessEnvironmentInherited;
    for (observed.entries, 0..) |entry, index| {
        const name = try validateEnvironmentName(entry);
        for (observed.entries[0..index]) |prior| {
            const prior_name = try validateEnvironmentName(prior);
            if (std.mem.eql(u8, name, prior_name)) {
                return error.ProcessEnvironmentDuplicate;
            }
        }
        var expected_entry: ?[]const u8 = null;
        for (expected) |candidate| {
            const candidate_name = validateEnvironmentName(candidate) catch
                return error.ProcessEnvironmentMalformed;
            if (std.mem.eql(u8, name, candidate_name)) {
                expected_entry = candidate;
                break;
            }
        }
        const fixed = expected_entry orelse return error.ProcessEnvironmentUnexpected;
        if (!std.mem.eql(u8, entry, fixed)) return error.ProcessEnvironmentMismatch;
        if (index >= expected.len or !std.mem.eql(u8, entry, expected[index])) {
            return error.ProcessEnvironmentMismatch;
        }
    }
    if (observed.entries.len != expected.len) return error.ProcessEnvironmentMismatch;
}

fn validateSyntheticNativeProcessRequest(
    request: SyntheticNativeProcessRequest,
    expected_id: DriverProcessId,
    bootstrap: AuthenticatedBootstrap,
    context: *const AcceptanceAuthorityContext,
) DriverError!void {
    try validateAuthenticatedBootstrapBuffers(bootstrap, context);
    const specification = processSpecification(expected_id);
    try validateAuthenticatedExecutableToken(
        request.executable,
        expected_id,
        bootstrap,
        context,
    );
    if (request.working_directory.context != context) {
        return error.AuthorityContextMismatch;
    }
    if (request.argv.len != specification.argv.len) return error.ProcessArgvMismatch;
    for (request.argv, specification.argv) |actual, expected| {
        if (actual.len == 0 or std.mem.indexOfScalar(u8, actual, 0) != null) {
            return error.ProcessArgumentMalformed;
        }
        if (!std.mem.eql(u8, actual, expected)) return error.ProcessArgvMismatch;
    }
    try validateClosedEnvironment(request.environment, specification.environment);
    if (!request.working_directory.authenticated or
        !std.meta.eql(
            request.working_directory.descriptor_identity,
            context.repository_identity,
        ))
    {
        return error.ProcessWorkingDirectoryMismatch;
    }
}

fn recordProcessDrainFailure(slot: *?DriverError, failure: DriverError) void {
    if (slot.* == null) slot.* = failure;
}

fn attemptSyntheticWait(
    fixture: *SyntheticNativeProcessFixture,
) DriverError!ProcessTermination {
    if (fixture.lifecycle != .launched_pending or fixture.wait_attempts != 0) {
        return error.ProcessFixtureConsumed;
    }
    fixture.lifecycle = .wait_attempted_unconfirmed;
    fixture.wait_attempts += 1;
    if (fixture.wait_failure) {
        fixture.lifecycle = .wait_failed_disposition_unknown;
        return error.ProcessWaitFailure;
    }
    fixture.lifecycle = .confirmed_reaped;
    return fixture.termination;
}

fn earlierFailureAfterWait(
    fixture: *SyntheticNativeProcessFixture,
    earlier_failure: anyerror,
) anyerror {
    _ = attemptSyntheticWait(fixture) catch |wait_failure| return wait_failure;
    return earlier_failure;
}

/// DEVELOPMENT-only injected process boundary. It never launches a real
/// process. Raw captures are owned only by this frame and the returned token
/// contains no capture, allocator, handle, or resource ownership.
fn runInjectedSyntheticNativeProcess(
    allocator: std.mem.Allocator,
    request: SyntheticNativeProcessRequest,
    fixture: *SyntheticNativeProcessFixture,
    expected_id: DriverProcessId,
    bootstrap: AuthenticatedBootstrap,
    context: *const AcceptanceAuthorityContext,
) !AuthenticatedProcessResult {
    try validateSyntheticNativeProcessRequest(request, expected_id, bootstrap, context);
    if (fixture.launch_attempts != 0 or
        fixture.wait_attempts != 0 or
        fixture.lifecycle != .not_launched or
        fixture.drained_events != 0)
    {
        return error.ProcessFixtureConsumed;
    }
    fixture.launch_attempts += 1;
    if (fixture.launch_failure) return error.ProcessLaunchFailure;
    fixture.lifecycle = .launched_pending;

    const specification = processSpecification(expected_id);
    const stdout_buffer = allocator.alloc(u8, specification.stdout_limit) catch |failure|
        return earlierFailureAfterWait(fixture, failure);
    defer allocator.free(stdout_buffer);
    const stderr_buffer = allocator.alloc(u8, specification.stderr_limit) catch |failure|
        return earlierFailureAfterWait(fixture, failure);
    defer allocator.free(stderr_buffer);
    var stdout_length: usize = 0;
    var stderr_length: usize = 0;
    var stdout_eof = false;
    var stderr_eof = false;
    var drain_failure: ?DriverError = null;

    for (fixture.events) |event| {
        fixture.drained_events += 1;
        const stream = switch (event) {
            .chunk => |chunk| chunk.stream,
            .eof => |value| value,
            .truncated => |value| value,
            .read_failure => |value| value,
        };
        switch (stream) {
            .stdout => fixture.stdout_events += 1,
            .stderr => fixture.stderr_events += 1,
        }
        switch (event) {
            .chunk => |chunk| {
                const eof_seen = switch (chunk.stream) {
                    .stdout => stdout_eof,
                    .stderr => stderr_eof,
                };
                if (eof_seen) {
                    recordProcessDrainFailure(&drain_failure, error.ProcessOutputIncomplete);
                    continue;
                }
                const destination = switch (chunk.stream) {
                    .stdout => stdout_buffer,
                    .stderr => stderr_buffer,
                };
                const current = switch (chunk.stream) {
                    .stdout => stdout_length,
                    .stderr => stderr_length,
                };
                const next = @addWithOverflow(current, chunk.bytes.len);
                if (next[1] != 0 or next[0] > destination.len) {
                    recordProcessDrainFailure(&drain_failure, error.ProcessOutputUnbounded);
                    continue;
                }
                @memcpy(destination[current..next[0]], chunk.bytes);
                switch (chunk.stream) {
                    .stdout => stdout_length = next[0],
                    .stderr => stderr_length = next[0],
                }
            },
            .eof => |value| switch (value) {
                .stdout => {
                    if (stdout_eof) {
                        recordProcessDrainFailure(&drain_failure, error.ProcessOutputIncomplete);
                    }
                    stdout_eof = true;
                },
                .stderr => {
                    if (stderr_eof) {
                        recordProcessDrainFailure(&drain_failure, error.ProcessOutputIncomplete);
                    }
                    stderr_eof = true;
                },
            },
            .truncated => recordProcessDrainFailure(
                &drain_failure,
                error.ProcessOutputTruncated,
            ),
            .read_failure => recordProcessDrainFailure(
                &drain_failure,
                error.ProcessReadFailure,
            ),
        }
    }
    if (!stdout_eof or !stderr_eof) {
        recordProcessDrainFailure(&drain_failure, error.ProcessOutputIncomplete);
    }

    const termination = try attemptSyntheticWait(fixture);
    if (drain_failure) |failure| return failure;
    return validateProcessObservation(
        .{
            .specification_id = request.executable.process_id,
            .executable_identity = request.executable.executable_sha256,
            .stdout = stdout_buffer[0..stdout_length],
            .stderr = stderr_buffer[0..stderr_length],
            .termination = termination,
        },
        expected_id,
        stdout_buffer[0..stdout_length],
        stderr_buffer[0..stderr_length],
        bootstrap,
        context,
    );
}

pub fn parseGitSha1Line(bytes: []const u8) DriverError!GitSha1Identity {
    if (bytes.len != 41 or bytes[40] != '\n') return error.GitOutputMalformed;
    var identity = GitSha1Identity{ .bytes = undefined };
    decodeLowerHex(bytes[0..40], &identity.bytes) catch return error.GitOutputMalformed;
    return identity;
}

pub const StagedChangeKind = enum { added, modified };

pub const StagedChange = struct {
    path: CanonicalRepositoryPath,
    blob_identity: GitSha1Identity,
    kind: StagedChangeKind,
};

fn sourcePathIndex(path: []const u8) ?usize {
    for (capability_source_paths, 0..) |expected, index| {
        if (std.mem.eql(u8, path, expected)) return index;
    }
    return null;
}

fn isZeroGitIdentity(identity: GitSha1Identity) bool {
    return std.mem.allEqual(u8, &identity.bytes, 0);
}

pub fn parseStagedListing(
    bytes: []const u8,
) DriverError![capability_source_count]StagedChange {
    var result: [capability_source_count]StagedChange = undefined;
    var seen = [_]bool{false} ** capability_source_count;
    var record_index: usize = 0;
    var offset: usize = 0;
    while (offset < bytes.len) {
        const relative_end = std.mem.indexOfScalar(u8, bytes[offset..], 0) orelse
            return error.StagedRecordTrailing;
        const record = bytes[offset .. offset + relative_end];
        offset += relative_end + 1;
        if (record.len == 0) return error.GitOutputMalformed;
        if (record_index >= capability_source_count) return error.ExtraStagedPath;
        if (!std.mem.startsWith(u8, record, "1 ")) {
            return error.StagedRecordTypeUnsupported;
        }

        var fields: [9][]const u8 = undefined;
        var field_count: usize = 0;
        var field_iterator = std.mem.splitScalar(u8, record, ' ');
        while (field_iterator.next()) |field| {
            if (field.len == 0 or field_count >= fields.len) return error.GitOutputMalformed;
            fields[field_count] = field;
            field_count += 1;
        }
        if (field_count != fields.len or !std.mem.eql(u8, fields[0], "1")) {
            return error.GitOutputMalformed;
        }
        const path_index = sourcePathIndex(fields[8]) orelse return error.ExtraStagedPath;
        if (seen[path_index]) return error.DuplicateStagedPath;
        seen[path_index] = true;
        if (path_index != record_index) return error.StagedOrderMismatch;
        const expected_kind: StagedChangeKind = if (path_index + 1 == capability_source_count)
            .modified
        else
            .added;
        const expected_status = if (expected_kind == .modified) "M." else "A.";
        if (!std.mem.eql(u8, fields[1], expected_status)) {
            return error.StagedStatusMismatch;
        }
        if (!std.mem.eql(u8, fields[2], "N...") or
            !std.mem.eql(u8, fields[4], "100644") or
            !std.mem.eql(u8, fields[5], "100644"))
        {
            return error.StagedModeMismatch;
        }
        if (expected_kind == .added) {
            if (!std.mem.eql(u8, fields[3], "000000")) return error.StagedModeMismatch;
        } else if (!std.mem.eql(u8, fields[3], "100644")) {
            return error.StagedModeMismatch;
        }
        var head_identity = GitSha1Identity{ .bytes = undefined };
        decodeLowerHex(fields[6], &head_identity.bytes) catch return error.GitOutputMalformed;
        var index_identity = GitSha1Identity{ .bytes = undefined };
        decodeLowerHex(fields[7], &index_identity.bytes) catch return error.GitOutputMalformed;
        if ((expected_kind == .added) != isZeroGitIdentity(head_identity)) {
            return error.StagedStatusMismatch;
        }
        if (isZeroGitIdentity(index_identity)) return error.StagedStageMismatch;
        result[record_index] = .{
            .path = canonicalRepositoryPath(fields[8]) catch return error.GitOutputMalformed,
            .blob_identity = index_identity,
            .kind = expected_kind,
        };
        record_index += 1;
    }
    if (record_index != capability_source_count) return error.MissingStagedPath;
    return result;
}

pub fn normalizeAuthenticatedStagedSource(
    allocator: std.mem.Allocator,
    observed: ObservedStagedSource,
    bootstrap: AuthenticatedBootstrap,
    context: *const AcceptanceAuthorityContext,
) !AuthenticatedStagedSource {
    const process_observations = [_]ObservedProcessResult{
        observed.object_format,
        observed.staged_listing,
        observed.staged_tree,
    };
    const process_ids = [_]DriverProcessId{
        .git_object_format,
        .git_staged_listing,
        .git_staged_tree,
    };
    for (process_observations, process_ids) |process, id| {
        const specification = processSpecification(id);
        if (process.stdout.len > specification.stdout_limit or
            process.stderr.len > specification.stderr_limit)
        {
            return error.ProcessOutputUnbounded;
        }
    }
    for (&observed.sources, 0..) |*source, index| {
        if (source.staged_bytes.len > source_capture_max_bytes or
            source.worktree_bytes.len > source_capture_max_bytes)
        {
            return error.SourceCaptureOversized;
        }
        if (source.context != context) return error.AuthorityContextMismatch;
        const expected_path = canonicalRepositoryPath(capability_source_paths[index]) catch unreachable;
        if (!equalCanonicalPath(&source.path, &expected_path)) return error.StagedPathMismatch;
    }

    var process_stdout = [_]?[]u8{null} ** process_observations.len;
    var process_stderr = [_]?[]u8{null} ** process_observations.len;
    defer {
        var index = process_observations.len;
        while (index > 0) {
            index -= 1;
            if (process_stderr[index]) |bytes| allocator.free(bytes);
            if (process_stdout[index]) |bytes| allocator.free(bytes);
        }
    }
    for (process_observations, 0..) |process, index| {
        process_stdout[index] = try allocator.dupe(u8, process.stdout);
        process_stderr[index] = try allocator.dupe(u8, process.stderr);
        _ = try validateProcessObservation(
            process,
            process_ids[index],
            process_stdout[index].?,
            process_stderr[index].?,
            bootstrap,
            context,
        );
    }

    var staged_sources = [_]?[]u8{null} ** capability_source_count;
    var worktree_sources = [_]?[]u8{null} ** capability_source_count;
    defer {
        var index: usize = capability_source_count;
        while (index > 0) {
            index -= 1;
            if (worktree_sources[index]) |bytes| allocator.free(bytes);
            if (staged_sources[index]) |bytes| allocator.free(bytes);
        }
    }
    for (&observed.sources, 0..) |*source, index| {
        staged_sources[index] = try allocator.dupe(u8, source.staged_bytes);
        worktree_sources[index] = try allocator.dupe(u8, source.worktree_bytes);
    }

    const object_format_stdout = process_stdout[0].?;
    const staged_listing_stdout = process_stdout[1].?;
    const staged_tree_stdout = process_stdout[2].?;
    if (!std.mem.eql(u8, object_format_stdout, "sha1\n")) {
        return error.GitObjectAlgorithmUnsupported;
    }
    const listing = try parseStagedListing(staged_listing_stdout);
    const tree = try parseGitSha1Line(staged_tree_stdout);
    var source_set: CanonicalSourceSet = undefined;
    for (&observed.sources, &listing, &source_set.entries, 0..) |
        *source,
        *staged_change,
        *source_identity,
        index,
    | {
        const expected_path = canonicalRepositoryPath(capability_source_paths[index]) catch unreachable;
        if (!equalCanonicalPath(&source.path, &expected_path) or
            !equalCanonicalPath(&staged_change.path, &expected_path))
        {
            return error.StagedPathMismatch;
        }
        const staged_bytes = staged_sources[index].?;
        const worktree_bytes = worktree_sources[index].?;
        if (!std.mem.eql(u8, staged_bytes, worktree_bytes)) {
            return error.SourceBytesMismatch;
        }
        if (@as(u64, @intCast(staged_bytes.len)) !=
            context.source_set.entries[index].exact_length)
        {
            return error.SourceLengthMismatch;
        }
        source_identity.* = canonicalSourceIdentity(
            capability_source_paths[index],
            staged_bytes,
        ) catch return error.GitOutputMalformed;
        if (!equalGitIdentity(
            source_identity.git_blob_identity,
            staged_change.blob_identity,
        )) return error.StagedBlobMismatch;
    }
    const validated = ValidatedStagedSource{
        .context = context,
        .source_set = source_set,
        .tree_identity = tree,
    };
    return authenticateValidatedStagedSource(validated, context);
}

pub fn authenticateValidatedStagedSource(
    validated: ValidatedStagedSource,
    context: *const AcceptanceAuthorityContext,
) DriverError!AuthenticatedStagedSource {
    if (validated.context != context) return error.AuthorityContextMismatch;
    if (!equalCanonicalSourceSet(&validated.source_set, &context.source_set)) {
        for (&validated.source_set.entries, &context.source_set.entries) |
            *actual,
            *expected,
        | {
            if (!equalCanonicalPath(&actual.path, &expected.path)) return error.StagedPathMismatch;
            if (actual.mode != expected.mode) return error.StagedModeMismatch;
            if (!equalGitIdentity(actual.git_blob_identity, expected.git_blob_identity)) {
                return error.StagedBlobMismatch;
            }
            if (!equalRawIdentity(actual.raw_sha256, expected.raw_sha256) or
                actual.exact_length != expected.exact_length)
            {
                if (actual.exact_length != expected.exact_length) {
                    return error.SourceLengthMismatch;
                }
                return error.SourceDigestMismatch;
            }
        }
        return error.SourceDigestMismatch;
    }
    if (!equalGitIdentity(validated.tree_identity, context.tree_identity)) {
        return error.StagedTreeMismatch;
    }
    return .{
        .context = context,
        .source_set = validated.source_set,
        .tree_identity = validated.tree_identity,
    };
}

pub fn validateObservedValidationDirectory(
    observed: ObservedValidationDirectory,
) ValidatedValidationDirectory {
    return .{ .descriptor_identity = observed.descriptor_identity };
}

pub fn authenticateValidatedValidationDirectory(
    validated: ValidatedValidationDirectory,
    context: *const AcceptanceAuthorityContext,
) DriverError!AuthenticatedValidationDirectory {
    if (!std.meta.eql(validated.descriptor_identity, context.validation_identity)) {
        return error.ValidationDescriptorMismatch;
    }
    return .{
        .context = context,
        .descriptor_identity = validated.descriptor_identity,
    };
}

pub const SemanticGateId = enum(u8) {
    canonical_tuple_admission,
    synthetic_authority_binding,
    pre_descriptor_rejection,
    post_seal_length_sha,
    fresh_owned_replay,
    consumed_handoff_rejection,
    ownership_exactly_once_close,
};

pub const AuthenticatedSemanticGate = struct {
    context: *const AcceptanceAuthorityContext,
    id: SemanticGateId,
};

pub fn requireSyntheticGate(
    context: *const AcceptanceAuthorityContext,
    pass: bool,
    comptime id: SemanticGateId,
) DriverError!AuthenticatedSemanticGate {
    if (!pass) return error.SemanticGateFailed;
    return .{ .context = context, .id = id };
}

pub fn gateCanonicalTupleAdmission(context: *const AcceptanceAuthorityContext, pass: bool) DriverError!AuthenticatedSemanticGate {
    return requireSyntheticGate(context, pass, .canonical_tuple_admission);
}

pub fn gateSyntheticAuthorityBinding(context: *const AcceptanceAuthorityContext, pass: bool) DriverError!AuthenticatedSemanticGate {
    return requireSyntheticGate(context, pass, .synthetic_authority_binding);
}

pub fn gatePreDescriptorRejection(context: *const AcceptanceAuthorityContext, pass: bool) DriverError!AuthenticatedSemanticGate {
    return requireSyntheticGate(context, pass, .pre_descriptor_rejection);
}

pub fn gatePostSealLengthSha(context: *const AcceptanceAuthorityContext, pass: bool) DriverError!AuthenticatedSemanticGate {
    return requireSyntheticGate(context, pass, .post_seal_length_sha);
}

pub fn gateFreshOwnedReplay(context: *const AcceptanceAuthorityContext, pass: bool) DriverError!AuthenticatedSemanticGate {
    return requireSyntheticGate(context, pass, .fresh_owned_replay);
}

pub fn gateConsumedHandoffRejection(context: *const AcceptanceAuthorityContext, pass: bool) DriverError!AuthenticatedSemanticGate {
    return requireSyntheticGate(context, pass, .consumed_handoff_rejection);
}

pub fn gateOwnershipExactlyOnceClose(context: *const AcceptanceAuthorityContext, pass: bool) DriverError!AuthenticatedSemanticGate {
    return requireSyntheticGate(context, pass, .ownership_exactly_once_close);
}

pub fn collectSemanticGateBits(
    context: *const AcceptanceAuthorityContext,
    gates: []const AuthenticatedSemanticGate,
) DriverError!u32 {
    var bits: u32 = 0;
    for (gates) |gate| {
        if (gate.context != context) return error.AuthorityContextMismatch;
        const bit: u32 = @as(u32, 1) << @intCast(@intFromEnum(gate.id));
        if (bit & receipt_required_semantic_bits == 0) return error.SemanticGateUnknown;
        if (bits & bit != 0) return error.SemanticGateDuplicate;
        bits |= bit;
    }
    if (bits != receipt_required_semantic_bits) return error.SemanticGateMissing;
    return bits;
}

pub const ValidatedPublicationTarget = receipt_module.ValidatedPublicationTarget;
pub const validatePublicationTarget = receipt_module.validatePublicationTarget;
pub const equalPublicationTarget = receipt_module.equalPublicationTarget;
pub const BoundReceipt = receipt_module.BoundReceiptTypes(
    AcceptanceAuthorityContext,
    AuthenticatedValidationDirectory,
);
pub const PreparedReceipt = BoundReceipt.PreparedReceipt;
pub const PublishedReceipt = BoundReceipt.PublishedReceipt;
pub const bindPublishedReceipt = BoundReceipt.bindPublishedReceipt;

/// The only pointer admitted by the fixed-value protocol is the immutable,
/// non-owning cohort pointer. Its referent must outlive every carrying value.
pub fn isRecursivelySafeAcceptanceValue(comptime T: type) bool {
    if (T == *const AcceptanceAuthorityContext) return true;
    if (T == bool or T == u8 or T == u16 or T == u32 or T == u64) return true;
    return switch (@typeInfo(T)) {
        .@"enum" => true,
        .array => |array| isRecursivelySafeAcceptanceValue(array.child),
        .optional => |optional| isRecursivelySafeAcceptanceValue(optional.child),
        .@"struct" => |structure| block: {
            inline for (structure.fields) |field| {
                if (!isRecursivelySafeAcceptanceValue(field.type)) break :block false;
            }
            break :block true;
        },
        .@"union" => |union_info| block: {
            inline for (union_info.fields) |field| {
                if (!isRecursivelySafeAcceptanceValue(field.type)) break :block false;
            }
            break :block true;
        },
        else => false,
    };
}

pub const DriverPhase = enum {
    initialized,
    repository_authenticated,
    bootstrap_authenticated,
    staged_source_authenticated,
    format_passed,
    focused_test_passed,
    semantic_gates_passed,
    validation_directory_authenticated,
    receipt_ready,
    published,
    deinitialized,
};

pub const AcceptanceDriver = struct {
    phase: DriverPhase = .initialized,
    context: ?*const AcceptanceAuthorityContext = null,
    repository: ?AuthenticatedRepositoryScope = null,
    staged_source: ?AuthenticatedStagedSource = null,
    bootstrap: ?AuthenticatedBootstrap = null,
    validation_directory: ?AuthenticatedValidationDirectory = null,
    semantic_bits: u32 = 0,
    prepared_receipt: ?PreparedReceipt = null,
    published_receipt: ?PublishedReceipt = null,

    pub fn deinit(self: *AcceptanceDriver) void {
        if (self.phase == .deinitialized) return;
        self.published_receipt = null;
        self.prepared_receipt = null;
        self.validation_directory = null;
        self.semantic_bits = 0;
        self.staged_source = null;
        self.bootstrap = null;
        self.repository = null;
        self.context = null;
        self.phase = .deinitialized;
    }

    pub fn requirePhase(self: *const AcceptanceDriver, expected: DriverPhase) DriverError!void {
        if (self.phase != expected) return error.DriverPhaseViolation;
    }

    pub fn requireContext(
        self: *const AcceptanceDriver,
        context: *const AcceptanceAuthorityContext,
    ) DriverError!void {
        if (self.context == null or self.context.? != context) {
            return error.AuthorityContextMismatch;
        }
    }

    pub fn acceptRepository(
        self: *AcceptanceDriver,
        repository: AuthenticatedRepositoryScope,
    ) DriverError!void {
        try self.requirePhase(.initialized);
        self.context = repository.context;
        self.repository = repository;
        self.phase = .repository_authenticated;
    }

    pub fn acceptBootstrap(
        self: *AcceptanceDriver,
        bootstrap: AuthenticatedBootstrap,
    ) DriverError!void {
        try self.requirePhase(.repository_authenticated);
        try self.requireContext(bootstrap.context);
        const context = self.context orelse return error.AuthorityContextMismatch;
        try validateAuthenticatedBootstrapBuffers(bootstrap, context);
        self.bootstrap = bootstrap;
        self.phase = .bootstrap_authenticated;
    }

    pub fn acceptStagedSource(
        self: *AcceptanceDriver,
        staged_source: AuthenticatedStagedSource,
    ) DriverError!void {
        try self.requirePhase(.bootstrap_authenticated);
        try self.requireContext(staged_source.context);
        self.staged_source = staged_source;
        self.phase = .staged_source_authenticated;
    }

    pub fn acceptFormatResult(
        self: *AcceptanceDriver,
        result: AuthenticatedProcessResult,
    ) DriverError!void {
        try self.requirePhase(.staged_source_authenticated);
        try self.requireContext(result.context);
        const context = self.context orelse return error.AuthorityContextMismatch;
        try validateAuthenticatedBootstrapBuffers(result.bootstrap, context);
        try validateAuthenticatedBootstrapBuffers(self.bootstrap.?, context);
        if (!std.meta.eql(result.bootstrap, self.bootstrap.?)) {
            return error.ToolchainMismatch;
        }
        if (result.specification_id != .zig_format_check) {
            return error.ProcessSpecificationMismatch;
        }
        self.phase = .format_passed;
    }

    pub fn acceptFocusedTestResult(
        self: *AcceptanceDriver,
        result: AuthenticatedProcessResult,
    ) DriverError!void {
        try self.requirePhase(.format_passed);
        try self.requireContext(result.context);
        const context = self.context orelse return error.AuthorityContextMismatch;
        try validateAuthenticatedBootstrapBuffers(result.bootstrap, context);
        try validateAuthenticatedBootstrapBuffers(self.bootstrap.?, context);
        if (!std.meta.eql(result.bootstrap, self.bootstrap.?)) {
            return error.ToolchainMismatch;
        }
        if (result.specification_id != .zig_focused_test) {
            return error.ProcessSpecificationMismatch;
        }
        self.phase = .focused_test_passed;
    }

    pub fn acceptSemanticGates(
        self: *AcceptanceDriver,
        gates: []const AuthenticatedSemanticGate,
    ) DriverError!void {
        try self.requirePhase(.focused_test_passed);
        const context = self.context orelse return error.AuthorityContextMismatch;
        const semantic_bits = try collectSemanticGateBits(context, gates);
        self.semantic_bits = semantic_bits;
        self.phase = .semantic_gates_passed;
    }

    pub fn acceptValidationDirectory(
        self: *AcceptanceDriver,
        directory: AuthenticatedValidationDirectory,
    ) DriverError!void {
        try self.requirePhase(.semantic_gates_passed);
        try self.requireContext(directory.context);
        self.validation_directory = directory;
        self.phase = .validation_directory_authenticated;
    }

    pub fn prepareReceipt(
        self: *AcceptanceDriver,
        final_target: ValidatedPublicationTarget,
    ) !PreparedReceipt {
        try self.requirePhase(.validation_directory_authenticated);
        try validatePublicationTargetValue(&final_target);
        const context = self.context orelse return error.AuthorityContextMismatch;
        const staged = self.staged_source orelse return error.DriverPhaseViolation;
        const bootstrap = self.bootstrap orelse return error.DriverPhaseViolation;
        const validation_directory = self.validation_directory orelse
            return error.DriverPhaseViolation;
        try self.requireContext(staged.context);
        try self.requireContext(bootstrap.context);
        try self.requireContext(validation_directory.context);
        const receipt = CanonicalAcceptanceReceipt{
            .schema_version = receipt_schema_version,
            .capability_version = receipt_capability_version,
            .source_set = staged.source_set,
            .staged_tree_hash_algorithm = canonical_git_sha1_algorithm,
            .staged_tree_identity = staged.tree_identity,
            .zig_toolchain_identity = bootstrap.zig_toolchain_identity,
            .format_status = 0,
            .focused_test_status = 0,
            .semantic_gate_bits = self.semantic_bits,
            .completion_state = .complete,
        };
        try validateCanonicalReceipt(&receipt);
        const canonical_bytes = try encodeCanonicalReceipt(&receipt);
        const canonical_slice = try canonicalReceiptBytesSlice(&canonical_bytes);
        var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(canonical_slice, &digest, .{});
        const prepared = PreparedReceipt{
            .context = context,
            .validation_directory = validation_directory,
            .final_target = final_target,
            .receipt = receipt,
            .canonical_bytes = canonical_bytes,
            .canonical_sha256 = .{ .bytes = digest },
            .exact_length = canonical_bytes.length,
        };
        self.prepared_receipt = prepared;
        self.phase = .receipt_ready;
        return prepared;
    }

    pub fn acceptPublishedReceipt(
        self: *AcceptanceDriver,
        published: PublishedReceipt,
    ) !void {
        try self.requirePhase(.receipt_ready);
        const context = self.context orelse return error.AuthorityContextMismatch;
        const prepared = self.prepared_receipt orelse return error.DriverPhaseViolation;
        const validation_directory = self.validation_directory orelse
            return error.DriverPhaseViolation;
        if (published.context != context or prepared.context != context) {
            return error.PublicationContextMismatch;
        }
        if (published.validation_directory.context != context or
            !std.meta.eql(
                published.validation_directory.descriptor_identity,
                validation_directory.descriptor_identity,
            ) or
            !std.meta.eql(
                prepared.validation_directory.descriptor_identity,
                validation_directory.descriptor_identity,
            ))
        {
            return error.PublicationDirectoryMismatch;
        }
        try validateCanonicalReceipt(&published.receipt);
        try validateCanonicalReceipt(&prepared.receipt);
        try validatePublicationTargetValue(&published.final_target);
        try validatePublicationTargetValue(&prepared.final_target);
        _ = try publicationReceiptBytesSlice(&published.canonical_bytes);
        _ = try publicationReceiptBytesSlice(&prepared.canonical_bytes);
        if (!try equalPublicationTarget(&published.final_target, &prepared.final_target)) {
            return error.PublicationTargetMismatch;
        }
        if (!std.meta.eql(published.receipt, prepared.receipt)) {
            return error.PublicationPreparedMismatch;
        }
        if (published.publication_identity.completion_status != .complete) {
            return error.PublicationIncomplete;
        }
        if (published.exact_length == 0 or
            published.exact_length != prepared.exact_length or
            published.canonical_bytes.length != published.exact_length or
            prepared.canonical_bytes.length != prepared.exact_length or
            published.publication_identity.exact_length != published.exact_length)
        {
            return error.PublicationLengthMismatch;
        }
        const encoded = try encodeCanonicalReceipt(&prepared.receipt);
        if (!try equalPublicationReceiptBytes(&encoded, &prepared.canonical_bytes) or
            !try equalPublicationReceiptBytes(&encoded, &published.canonical_bytes))
        {
            return error.PublicationBytesMismatch;
        }
        var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(
            try publicationReceiptBytesSlice(&encoded),
            &digest,
            .{},
        );
        const computed = RawSha256Identity{ .bytes = digest };
        if (!equalRawIdentity(computed, prepared.canonical_sha256) or
            !equalRawIdentity(computed, published.canonical_sha256) or
            !equalRawIdentity(computed, published.publication_identity.final_sha256))
        {
            return error.PublicationDigestMismatch;
        }
        if (encoded.length != prepared.exact_length or
            encoded.length != published.publication_identity.exact_length)
        {
            return error.PublicationLengthMismatch;
        }
        self.published_receipt = published;
        self.phase = .published;
    }
};

comptime {
    if (!isRecursivelySafeAcceptanceValue(AuthenticatedRepositoryScope) or
        !isRecursivelySafeAcceptanceValue(AuthenticatedBootstrap) or
        !isRecursivelySafeAcceptanceValue(AuthenticatedProcessResult) or
        !isRecursivelySafeAcceptanceValue(AuthenticatedStagedSource) or
        !isRecursivelySafeAcceptanceValue(AuthenticatedValidationDirectory) or
        !isRecursivelySafeAcceptanceValue(AuthenticatedSemanticGate) or
        !isRecursivelySafeAcceptanceValue(PreparedReceipt) or
        !isRecursivelySafeAcceptanceValue(PublishedReceipt) or
        !isRecursivelySafeAcceptanceValue(AcceptanceDriver))
    {
        @compileError("acceptance values must contain recursively audited fixed leaves only");
    }
}

pub fn syntheticDescriptorIdentity(seed: u64) AuthorityDescriptorIdentity {
    return .{
        .device_major = @truncate(seed),
        .device_minor = @truncate(seed >> 8),
        .inode = seed *% 17 +% 3,
        .mount_id_unique = seed *% 31 +% 7,
    };
}

pub const synthetic_source_bytes = [capability_source_count][]const u8{
    "synthetic acceptance driver source",
    "synthetic acceptance driver test source",
    "synthetic provenance source",
    "synthetic receipt source",
    "synthetic materializer root source",
};

pub fn syntheticAuthorityContext(
    source_bytes: [capability_source_count][]const u8,
) !AcceptanceAuthorityContext {
    return .{
        .repository_identity = syntheticDescriptorIdentity(11),
        .validation_identity = syntheticDescriptorIdentity(22),
        .driver_launch_identity = .{ .bytes = fixedIdentity(32, 0x81) },
        .zig_executable_identity = .{ .bytes = fixedIdentity(32, 0x82) },
        .git_executable_identity = .{ .bytes = fixedIdentity(32, 0x83) },
        .zig_toolchain_identity = try canonicalReceiptToken("zig-0.16.0-x86_64-linux"),
        .source_set = try canonicalSourceSetFromBytes(source_bytes),
        .tree_identity = .{ .bytes = fixedIdentity(20, 0x85) },
    };
}

pub fn syntheticObservedProcess(
    id: DriverProcessId,
    executable_identity: RawSha256Identity,
    stdout: []const u8,
) ObservedProcessResult {
    return .{
        .specification_id = id,
        .executable_identity = executable_identity,
        .stdout = stdout,
        .stderr = "",
    };
}

fn alternateSyntheticProcessId(id: DriverProcessId) DriverProcessId {
    return if (id == .zig_format_check) .zig_focused_test else .zig_format_check;
}

fn syntheticExecutableChannelIdentity(id: DriverProcessId) RawSha256Identity {
    return .{ .bytes = fixedIdentity(32, 0x90 + @as(u8, @intFromEnum(id))) };
}

fn syntheticExecutableDescriptorIdentity(id: DriverProcessId) AuthorityDescriptorIdentity {
    return syntheticDescriptorIdentity(700 + @as(u64, @intFromEnum(id)));
}

fn syntheticObservationBoundaryIdentity(id: DriverProcessId) RawSha256Identity {
    return .{ .bytes = fixedIdentity(32, 0xb0 + @as(u8, @intFromEnum(id))) };
}

/// Private expected-authority supplier path. It never observes or supplies a
/// descriptor and exposes no capability outside this module.
fn syntheticExpectedExecutableCapability(
    id: DriverProcessId,
    bootstrap: AuthenticatedBootstrap,
    context: *const AcceptanceAuthorityContext,
) SyntheticExpectedExecutableCapability {
    const specification = processSpecification(id);
    return .{
        .witness = &expected_supplier_witness,
        .facts = .{
            .context = context,
            .process_id = id,
            .canonical_path_sha256 = executablePathIdentity(specification.executable),
            .sha256 = expectedExecutableIdentity(id, bootstrap),
            .authorized_channel_identity = syntheticExecutableChannelIdentity(id),
        },
    };
}

/// Private sealed-observation supplier path. Descriptor identity originates
/// only here; real observation and same-object execution remain fail closed.
fn syntheticObservedExecutableCapability(
    id: DriverProcessId,
    bootstrap: AuthenticatedBootstrap,
    context: *const AcceptanceAuthorityContext,
) SyntheticObservedExecutableCapability {
    const specification = processSpecification(id);
    const channel_identity = syntheticExecutableChannelIdentity(id);
    return .{
        .witness = &observation_supplier_witness,
        .facts = .{
            .context = context,
            .process_id = id,
            .descriptor_identity = syntheticExecutableDescriptorIdentity(id),
            .canonical_path_sha256 = executablePathIdentity(specification.executable),
            .sha256 = expectedExecutableIdentity(id, bootstrap),
            .authorized_channel_identity = channel_identity,
            .handoff_identity = channel_identity,
            .observation_boundary_identity = syntheticObservationBoundaryIdentity(id),
        },
    };
}

fn syntheticAuthenticatedExecutableToken(
    id: DriverProcessId,
    bootstrap: AuthenticatedBootstrap,
    context: *const AcceptanceAuthorityContext,
) AuthenticatedExecutableToken {
    const expected = syntheticExpectedExecutableCapability(id, bootstrap, context);
    const observed = syntheticObservedExecutableCapability(id, bootstrap, context);
    return admitSyntheticExecutableToken(
        expected,
        observed,
        id,
        bootstrap,
        context,
    ) catch unreachable;
}

fn syntheticNativeProcessRequest(
    id: DriverProcessId,
    bootstrap: AuthenticatedBootstrap,
    context: *const AcceptanceAuthorityContext,
) SyntheticNativeProcessRequest {
    const specification = processSpecification(id);
    return .{
        .executable = syntheticAuthenticatedExecutableToken(id, bootstrap, context),
        .argv = specification.argv,
        .environment = .{
            .constructed_from_empty = true,
            .entries = specification.environment,
        },
        .working_directory = .{
            .context = context,
            .descriptor_identity = context.repository_identity,
            .authenticated = true,
        },
    };
}

fn privateTestSourceBytes(label: []const u8) [capability_source_count][]const u8 {
    var result = synthetic_source_bytes;
    result[capability_source_count - 1] = label;
    return result;
}

test "private executable suppliers and admitted token reject every forgery" {
    const source_bytes = privateTestSourceBytes("private executable supplier source");
    const context_value = try syntheticAuthorityContext(source_bytes);
    const contexts = [2]AcceptanceAuthorityContext{ context_value, context_value };
    const context_a = &contexts[0];
    const context_b = &contexts[1];
    const bootstrap = try syntheticAuthenticatedBootstrap(context_a);
    const expected = syntheticExpectedExecutableCapability(
        .zig_format_check,
        bootstrap,
        context_a,
    );
    const observed = syntheticObservedExecutableCapability(
        .zig_format_check,
        bootstrap,
        context_a,
    );
    comptime {
        if (@TypeOf(expected) == @TypeOf(observed)) {
            @compileError("supplier capabilities must remain domain-distinct");
        }
        if (@hasField(@TypeOf(expected.facts), "descriptor_identity")) {
            @compileError("expected authority must never claim the observed descriptor");
        }
        if (@hasField(AuthenticatedExecutableToken, "admission") or
            @hasField(AuthenticatedExecutableToken, "sealed_facts") or
            @hasField(AuthenticatedExecutableToken, "admission_binding"))
        {
            @compileError("admitted tokens must not expose success tags or duplicated seals");
        }
    }

    const admitted = try admitSyntheticExecutableToken(
        expected,
        observed,
        .zig_format_check,
        bootstrap,
        context_a,
    );
    const admitted_copy = admitted;
    try validateAuthenticatedExecutableToken(
        admitted_copy,
        .zig_format_check,
        bootstrap,
        context_a,
    );

    var absent_expected = expected;
    absent_expected.witness = null;
    var absent_observed = observed;
    absent_observed.witness = null;
    try std.testing.expectEqualDeep(expected.facts.context, observed.facts.context);
    try std.testing.expect(equalRawIdentity(
        expected.facts.canonical_path_sha256,
        observed.facts.canonical_path_sha256,
    ));
    try std.testing.expect(equalRawIdentity(expected.facts.sha256, observed.facts.sha256));
    try std.testing.expectError(
        error.ProcessExecutableAuthorityUnavailable,
        admitSyntheticExecutableToken(
            absent_expected,
            observed,
            .zig_format_check,
            bootstrap,
            context_a,
        ),
    );
    try std.testing.expectError(
        error.ProcessExecutableAuthorityUnavailable,
        admitSyntheticExecutableToken(
            expected,
            absent_observed,
            .zig_format_check,
            bootstrap,
            context_a,
        ),
    );
    try std.testing.expectError(
        error.ProcessExecutableAuthorityUnavailable,
        admitSyntheticExecutableToken(
            absent_expected,
            absent_observed,
            .zig_format_check,
            bootstrap,
            context_a,
        ),
    );

    var swapped_expected = expected;
    swapped_expected.witness = &observation_supplier_witness;
    var swapped_observed = observed;
    swapped_observed.witness = &expected_supplier_witness;
    try std.testing.expectError(
        error.ProcessExecutableAuthorityUnavailable,
        admitSyntheticExecutableToken(
            swapped_expected,
            observed,
            .zig_format_check,
            bootstrap,
            context_a,
        ),
    );
    try std.testing.expectError(
        error.ProcessExecutableAuthorityUnavailable,
        admitSyntheticExecutableToken(
            expected,
            swapped_observed,
            .zig_format_check,
            bootstrap,
            context_a,
        ),
    );

    var changed_expected = expected;
    changed_expected.facts.context = context_b;
    try std.testing.expectError(
        error.AuthorityContextMismatch,
        admitSyntheticExecutableToken(
            changed_expected,
            observed,
            .zig_format_check,
            bootstrap,
            context_a,
        ),
    );
    var changed_observed = observed;
    changed_observed.facts.context = context_b;
    try std.testing.expectError(
        error.AuthorityContextMismatch,
        admitSyntheticExecutableToken(
            expected,
            changed_observed,
            .zig_format_check,
            bootstrap,
            context_a,
        ),
    );

    changed_expected = expected;
    changed_expected.facts.process_id = alternateSyntheticProcessId(.zig_format_check);
    try std.testing.expectError(
        error.ProcessSpecificationMismatch,
        admitSyntheticExecutableToken(
            changed_expected,
            observed,
            .zig_format_check,
            bootstrap,
            context_a,
        ),
    );
    changed_observed = observed;
    changed_observed.facts.process_id = alternateSyntheticProcessId(.zig_format_check);
    try std.testing.expectError(
        error.ProcessSpecificationMismatch,
        admitSyntheticExecutableToken(
            expected,
            changed_observed,
            .zig_format_check,
            bootstrap,
            context_a,
        ),
    );

    changed_expected = expected;
    changed_expected.facts.canonical_path_sha256.bytes[0] ^= 1;
    try std.testing.expectError(
        error.ProcessExecutablePathMismatch,
        admitSyntheticExecutableToken(
            changed_expected,
            observed,
            .zig_format_check,
            bootstrap,
            context_a,
        ),
    );
    changed_observed = observed;
    changed_observed.facts.canonical_path_sha256.bytes[0] ^= 1;
    try std.testing.expectError(
        error.ProcessExecutablePathMismatch,
        admitSyntheticExecutableToken(
            expected,
            changed_observed,
            .zig_format_check,
            bootstrap,
            context_a,
        ),
    );

    changed_expected = expected;
    changed_expected.facts.sha256.bytes[0] ^= 1;
    try std.testing.expectError(
        error.ProcessExecutableMismatch,
        admitSyntheticExecutableToken(
            changed_expected,
            observed,
            .zig_format_check,
            bootstrap,
            context_a,
        ),
    );
    changed_observed = observed;
    changed_observed.facts.sha256.bytes[0] ^= 1;
    try std.testing.expectError(
        error.ProcessExecutableMismatch,
        admitSyntheticExecutableToken(
            expected,
            changed_observed,
            .zig_format_check,
            bootstrap,
            context_a,
        ),
    );

    changed_expected = expected;
    changed_expected.facts.authorized_channel_identity.bytes[0] ^= 1;
    try std.testing.expectError(
        error.ProcessExecutableHandoffMismatch,
        admitSyntheticExecutableToken(
            changed_expected,
            observed,
            .zig_format_check,
            bootstrap,
            context_a,
        ),
    );
    changed_observed = observed;
    changed_observed.facts.authorized_channel_identity.bytes[0] ^= 1;
    try std.testing.expectError(
        error.ProcessExecutableHandoffMismatch,
        admitSyntheticExecutableToken(
            expected,
            changed_observed,
            .zig_format_check,
            bootstrap,
            context_a,
        ),
    );
    changed_observed = observed;
    changed_observed.facts.handoff_identity.bytes[0] ^= 1;
    try std.testing.expectError(
        error.ProcessExecutableHandoffMismatch,
        admitSyntheticExecutableToken(
            expected,
            changed_observed,
            .zig_format_check,
            bootstrap,
            context_a,
        ),
    );
    changed_observed = observed;
    changed_observed.facts.descriptor_identity.inode += 1;
    try std.testing.expectError(
        error.ProcessExecutableDescriptorMismatch,
        admitSyntheticExecutableToken(
            expected,
            changed_observed,
            .zig_format_check,
            bootstrap,
            context_a,
        ),
    );
    changed_observed = observed;
    changed_observed.facts.observation_boundary_identity.bytes[0] ^= 1;
    try std.testing.expectError(
        error.ProcessExecutableAuthorityUnavailable,
        admitSyntheticExecutableToken(
            expected,
            changed_observed,
            .zig_format_check,
            bootstrap,
            context_a,
        ),
    );

    var matching_facts_forgery = admitted;
    matching_facts_forgery.witness = &forged_executable_witness;
    try std.testing.expectError(
        error.ProcessExecutableAuthorityUnavailable,
        validateAuthenticatedExecutableToken(
            matching_facts_forgery,
            .zig_format_check,
            bootstrap,
            context_a,
        ),
    );
    try std.testing.expectError(
        error.AuthorityContextMismatch,
        validateAuthenticatedExecutableToken(
            admitted_copy,
            .zig_format_check,
            bootstrap,
            context_b,
        ),
    );
    try std.testing.expectError(
        error.ProcessSpecificationMismatch,
        validateAuthenticatedExecutableToken(
            admitted_copy,
            .zig_focused_test,
            bootstrap,
            context_a,
        ),
    );
}

const PrivateProcessScenarioId = enum {
    success,
    matching_facts_forgery,
    context_mismatch,
    specification_mismatch,
    fixture_reuse,
    launch_failure,
    stdout_allocation_failure,
    stderr_allocation_failure,
    read_failure,
    output_unbounded,
    output_truncated,
    incomplete_eof,
    wait_failure,
    wait_failure_over_read,
    nonzero_exit,
    signal,
    stop,
    unknown_termination,
};

const PrivateProcessResult = enum {
    success,
    authority_unavailable,
    context_mismatch,
    specification_mismatch,
    fixture_consumed,
    launch_failure,
    out_of_memory,
    read_failure,
    output_unbounded,
    output_truncated,
    output_incomplete,
    wait_failure,
    nonzero_exit,
    signal,
    stop,
    unknown_termination,
};

const PrivateNormalizedLifecycle = enum {
    not_launched,
    launched_pending,
    wait_attempted_unconfirmed,
    confirmed_reaped,
    wait_failed_disposition_unknown,
};

const PrivateProcessOutcome = struct {
    result: PrivateProcessResult,
    launch_attempts: u8,
    wait_attempts: u8,
    lifecycle: PrivateNormalizedLifecycle,
    driver_unchanged: bool,
    authority_unchanged: bool,
};

fn normalizePrivateProcessError(failure: anyerror) PrivateProcessResult {
    return switch (failure) {
        error.ProcessExecutableAuthorityUnavailable => .authority_unavailable,
        error.AuthorityContextMismatch => .context_mismatch,
        error.ProcessSpecificationMismatch => .specification_mismatch,
        error.ProcessFixtureConsumed => .fixture_consumed,
        error.ProcessLaunchFailure => .launch_failure,
        error.OutOfMemory => .out_of_memory,
        error.ProcessReadFailure => .read_failure,
        error.ProcessOutputUnbounded => .output_unbounded,
        error.ProcessOutputTruncated => .output_truncated,
        error.ProcessOutputIncomplete => .output_incomplete,
        error.ProcessWaitFailure => .wait_failure,
        error.ProcessExitedNonzero => .nonzero_exit,
        error.ProcessSignaled => .signal,
        error.ProcessStopped => .stop,
        error.ProcessTerminationUnknown => .unknown_termination,
        else => unreachable,
    };
}

fn normalizePrivateLifecycle(value: SyntheticChildLifecycle) PrivateNormalizedLifecycle {
    return switch (value) {
        .not_launched => .not_launched,
        .launched_pending => .launched_pending,
        .wait_attempted_unconfirmed => .wait_attempted_unconfirmed,
        .confirmed_reaped => .confirmed_reaped,
        .wait_failed_disposition_unknown => .wait_failed_disposition_unknown,
    };
}

fn runPrivateProcessScenario(id: PrivateProcessScenarioId) !PrivateProcessOutcome {
    const source_bytes = privateTestSourceBytes("private process scenario source");
    const context_value = try syntheticAuthorityContext(source_bytes);
    const contexts = [2]AcceptanceAuthorityContext{ context_value, context_value };
    const context = &contexts[0];
    const bootstrap = try syntheticAuthenticatedBootstrap(context);
    var request = syntheticNativeProcessRequest(.git_object_format, bootstrap, context);
    var driver = AcceptanceDriver{};
    try driver.acceptRepository(try syntheticAuthenticatedRepository(context));
    const driver_before = driver;

    const complete_events = [_]SyntheticProcessReadEvent{
        .{ .eof = .stdout },
        .{ .eof = .stderr },
    };
    const read_failure_events = [_]SyntheticProcessReadEvent{
        .{ .read_failure = .stderr },
        .{ .eof = .stdout },
        .{ .eof = .stderr },
    };
    const truncated_events = [_]SyntheticProcessReadEvent{
        .{ .truncated = .stdout },
        .{ .eof = .stdout },
        .{ .eof = .stderr },
    };
    const incomplete_events = [_]SyntheticProcessReadEvent{.{ .eof = .stdout }};
    const oversized = [_]u8{'x'} ** 17;
    const oversized_events = [_]SyntheticProcessReadEvent{
        .{ .chunk = .{ .stream = .stdout, .bytes = &oversized } },
        .{ .eof = .stdout },
        .{ .eof = .stderr },
    };
    var fixture = SyntheticNativeProcessFixture{ .events = &complete_events };
    switch (id) {
        .matching_facts_forgery => request.executable.witness = &forged_executable_witness,
        .context_mismatch => request.executable.context = &contexts[1],
        .specification_mismatch => request.executable.process_id = .zig_format_check,
        .launch_failure => fixture.launch_failure = true,
        .read_failure => fixture.events = &read_failure_events,
        .output_unbounded => fixture.events = &oversized_events,
        .output_truncated => fixture.events = &truncated_events,
        .incomplete_eof => fixture.events = &incomplete_events,
        .wait_failure => fixture.wait_failure = true,
        .wait_failure_over_read => {
            fixture.events = &read_failure_events;
            fixture.wait_failure = true;
        },
        .nonzero_exit => fixture.termination = .{ .exited = 1 },
        .signal => fixture.termination = .{ .signaled = 9 },
        .stop => fixture.termination = .{ .stopped = 19 },
        .unknown_termination => fixture.termination = .{ .unknown = 0xffff },
        else => {},
    }
    const authority_before = request.executable;

    var result: PrivateProcessResult = .success;
    if (id == .stdout_allocation_failure or id == .stderr_allocation_failure) {
        var failing_allocator = std.testing.FailingAllocator.init(
            std.testing.allocator,
            .{ .fail_index = if (id == .stdout_allocation_failure) 0 else 1 },
        );
        if (runInjectedSyntheticNativeProcess(
            failing_allocator.allocator(),
            request,
            &fixture,
            .git_object_format,
            bootstrap,
            context,
        )) |_| {} else |failure| result = normalizePrivateProcessError(failure);
        try std.testing.expectEqual(
            failing_allocator.allocated_bytes,
            failing_allocator.freed_bytes,
        );
    } else if (id == .fixture_reuse) {
        _ = try runInjectedSyntheticNativeProcess(
            std.testing.allocator,
            request,
            &fixture,
            .git_object_format,
            bootstrap,
            context,
        );
        if (runInjectedSyntheticNativeProcess(
            std.testing.allocator,
            request,
            &fixture,
            .git_object_format,
            bootstrap,
            context,
        )) |_| {} else |failure| result = normalizePrivateProcessError(failure);
    } else {
        if (runInjectedSyntheticNativeProcess(
            std.testing.allocator,
            request,
            &fixture,
            .git_object_format,
            bootstrap,
            context,
        )) |_| {} else |failure| result = normalizePrivateProcessError(failure);
    }
    return .{
        .result = result,
        .launch_attempts = @intCast(fixture.launch_attempts),
        .wait_attempts = @intCast(fixture.wait_attempts),
        .lifecycle = normalizePrivateLifecycle(fixture.lifecycle),
        .driver_unchanged = std.meta.eql(driver_before, driver),
        .authority_unchanged = std.meta.eql(authority_before, request.executable),
    };
}

pub const test_support = if (builtin.is_test) struct {
    pub const ScenarioId = PrivateProcessScenarioId;
    pub const Result = PrivateProcessResult;
    pub const Lifecycle = PrivateNormalizedLifecycle;
    pub const Outcome = PrivateProcessOutcome;

    pub fn run(id: ScenarioId) !Outcome {
        return runPrivateProcessScenario(id);
    }
} else struct {};

test "private process scenarios preserve lifecycle precedence and state" {
    const cases = [_]struct {
        id: PrivateProcessScenarioId,
        result: PrivateProcessResult,
        launches: u8,
        waits: u8,
        lifecycle: PrivateNormalizedLifecycle,
    }{
        .{ .id = .success, .result = .success, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .matching_facts_forgery, .result = .authority_unavailable, .launches = 0, .waits = 0, .lifecycle = .not_launched },
        .{ .id = .context_mismatch, .result = .context_mismatch, .launches = 0, .waits = 0, .lifecycle = .not_launched },
        .{ .id = .specification_mismatch, .result = .specification_mismatch, .launches = 0, .waits = 0, .lifecycle = .not_launched },
        .{ .id = .fixture_reuse, .result = .fixture_consumed, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .launch_failure, .result = .launch_failure, .launches = 1, .waits = 0, .lifecycle = .not_launched },
        .{ .id = .stdout_allocation_failure, .result = .out_of_memory, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .stderr_allocation_failure, .result = .out_of_memory, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .read_failure, .result = .read_failure, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .output_unbounded, .result = .output_unbounded, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .output_truncated, .result = .output_truncated, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .incomplete_eof, .result = .output_incomplete, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .wait_failure, .result = .wait_failure, .launches = 1, .waits = 1, .lifecycle = .wait_failed_disposition_unknown },
        .{ .id = .wait_failure_over_read, .result = .wait_failure, .launches = 1, .waits = 1, .lifecycle = .wait_failed_disposition_unknown },
        .{ .id = .nonzero_exit, .result = .nonzero_exit, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .signal, .result = .signal, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .stop, .result = .stop, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
        .{ .id = .unknown_termination, .result = .unknown_termination, .launches = 1, .waits = 1, .lifecycle = .confirmed_reaped },
    };
    for (cases) |case| {
        const outcome = try runPrivateProcessScenario(case.id);
        try std.testing.expectEqual(case.result, outcome.result);
        try std.testing.expectEqual(case.launches, outcome.launch_attempts);
        try std.testing.expectEqual(case.waits, outcome.wait_attempts);
        try std.testing.expectEqual(case.lifecycle, outcome.lifecycle);
        try std.testing.expect(outcome.driver_unchanged);
        try std.testing.expect(outcome.authority_unchanged);
    }
}

pub fn syntheticStagedListing(
    context: *const AcceptanceAuthorityContext,
    output: *[4096]u8,
) ![]const u8 {
    var stream = std.Io.Writer.fixed(output);
    for (&context.source_set.entries, 0..) |*entry, index| {
        var blob_hex: [40]u8 = undefined;
        encodeLowerHex(&entry.git_blob_identity.bytes, &blob_hex);
        if (index + 1 == capability_source_count) {
            try stream.print(
                "1 M. N... 100644 100644 100644 1111111111111111111111111111111111111111 {s} {s}\x00",
                .{ &blob_hex, try validatedCanonicalPathSlice(&entry.path) },
            );
        } else {
            try stream.print(
                "1 A. N... 000000 100644 100644 0000000000000000000000000000000000000000 {s} {s}\x00",
                .{ &blob_hex, try validatedCanonicalPathSlice(&entry.path) },
            );
        }
    }
    return stream.buffered();
}

pub const SyntheticStagedListingFault = enum {
    exact,
    missing,
    extra,
    duplicate,
    reordered,
    deleted,
    renamed,
    copied,
    unmerged,
    untracked,
    unsupported_type,
    intent_to_add,
    wrong_mode,
    type_change,
    wrong_blob,
    malformed,
    trailing,
};

pub fn syntheticStagedListingWithFault(
    context: *const AcceptanceAuthorityContext,
    output: *[4096]u8,
    fault: SyntheticStagedListingFault,
) ![]const u8 {
    if (fault == .exact) return syntheticStagedListing(context, output);
    var stream = std.Io.Writer.fixed(output);
    const count: usize = if (fault == .missing)
        capability_source_count - 1
    else
        capability_source_count;
    for (0..count) |record_index| {
        if (fault == .malformed and record_index == 0) {
            try stream.writeAll("1 malformed\x00");
            continue;
        }
        if (record_index == 0 and fault == .renamed) {
            try stream.writeAll("2 R. synthetic\x00");
            continue;
        }
        if (record_index == 0 and fault == .copied) {
            try stream.writeAll("2 C. synthetic\x00");
            continue;
        }
        if (record_index == 0 and fault == .unmerged) {
            try stream.writeAll("u synthetic\x00");
            continue;
        }
        if (record_index == 0 and fault == .untracked) {
            try stream.writeAll("? tools/untracked.zig\x00");
            continue;
        }
        if (record_index == 0 and fault == .unsupported_type) {
            try stream.writeAll("? synthetic\x00");
            continue;
        }
        const source_index = if (fault == .duplicate and record_index == 1)
            0
        else if (fault == .reordered and record_index < 2)
            1 - record_index
        else
            record_index;
        const entry = &context.source_set.entries[source_index];
        var blob_hex: [40]u8 = undefined;
        encodeLowerHex(&entry.git_blob_identity.bytes, &blob_hex);
        const kind: StagedChangeKind = if (source_index + 1 == capability_source_count)
            .modified
        else
            .added;
        const status = if (fault == .deleted and record_index == 0)
            "D."
        else if (kind == .modified)
            "M."
        else
            "A.";
        const head_mode = if (kind == .modified) "100644" else "000000";
        const index_mode = if (fault == .wrong_mode and record_index == 0)
            "100755"
        else if (fault == .type_change and record_index == 0)
            "120000"
        else
            "100644";
        const head_blob = if (kind == .modified)
            "1111111111111111111111111111111111111111"
        else
            "0000000000000000000000000000000000000000";
        const index_blob = if (fault == .intent_to_add and record_index == 0)
            "0000000000000000000000000000000000000000"
        else if (fault == .wrong_blob and record_index == 0)
            "2222222222222222222222222222222222222222"
        else
            &blob_hex;
        try stream.print(
            "1 {s} N... {s} {s} 100644 {s} {s} {s}\x00",
            .{
                status,
                head_mode,
                index_mode,
                head_blob,
                index_blob,
                try validatedCanonicalPathSlice(&entry.path),
            },
        );
    }
    if (fault == .extra) {
        try stream.writeAll(
            "1 A. N... 000000 100644 100644 0000000000000000000000000000000000000000 1111111111111111111111111111111111111111 tools/extra.zig\x00",
        );
    }
    const result = stream.buffered();
    return if (fault == .trailing) result[0 .. result.len - 1] else result;
}

pub fn syntheticTreeOutput(
    context: *const AcceptanceAuthorityContext,
    output: *[64]u8,
) ![]const u8 {
    var tree_hex: [40]u8 = undefined;
    encodeLowerHex(&context.tree_identity.bytes, &tree_hex);
    return std.fmt.bufPrint(output, "{s}\n", .{&tree_hex});
}

pub fn syntheticAuthenticatedBootstrap(
    context: *const AcceptanceAuthorityContext,
) !AuthenticatedBootstrap {
    const observed = ObservedBootstrap{
        .driver_launch_identity = context.driver_launch_identity,
        .zig_executable_identity = context.zig_executable_identity,
        .git_executable_identity = context.git_executable_identity,
        .zig_toolchain_identity = context.zig_toolchain_identity,
    };
    return authenticateValidatedBootstrap(
        try validateObservedBootstrap(observed),
        context,
    );
}

pub fn syntheticAuthenticatedProcess(
    allocator: std.mem.Allocator,
    id: DriverProcessId,
    stdout: []const u8,
    bootstrap: AuthenticatedBootstrap,
    context: *const AcceptanceAuthorityContext,
) !AuthenticatedProcessResult {
    const executable_identity = switch (id) {
        .git_object_format, .git_staged_listing, .git_staged_tree => bootstrap.git_executable_identity,
        .zig_format_check, .zig_focused_test => bootstrap.zig_executable_identity,
    };
    const observed = syntheticObservedProcess(id, executable_identity, stdout);
    return normalizeAuthenticatedProcessResult(
        allocator,
        observed,
        id,
        bootstrap,
        context,
    );
}

pub fn syntheticObservedStagedSource(
    source_bytes: [capability_source_count][]const u8,
    context: *const AcceptanceAuthorityContext,
    bootstrap: AuthenticatedBootstrap,
    listing_buffer: *[4096]u8,
    tree_buffer: *[64]u8,
) !ObservedStagedSource {
    const listing = try syntheticStagedListing(context, listing_buffer);
    const tree = try syntheticTreeOutput(context, tree_buffer);
    const object_format = syntheticObservedProcess(
        .git_object_format,
        bootstrap.git_executable_identity,
        "sha1\n",
    );
    const staged_listing = syntheticObservedProcess(
        .git_staged_listing,
        bootstrap.git_executable_identity,
        listing,
    );
    const staged_tree = syntheticObservedProcess(
        .git_staged_tree,
        bootstrap.git_executable_identity,
        tree,
    );
    const sources = syntheticObservedSourceCaptures(source_bytes, context);
    return .{
        .object_format = object_format,
        .staged_listing = staged_listing,
        .staged_tree = staged_tree,
        .sources = sources,
    };
}

pub fn syntheticAuthenticatedStagedSource(
    allocator: std.mem.Allocator,
    source_bytes: [capability_source_count][]const u8,
    context: *const AcceptanceAuthorityContext,
    bootstrap: AuthenticatedBootstrap,
) !AuthenticatedStagedSource {
    var listing_buffer: [4096]u8 = undefined;
    var tree_buffer: [64]u8 = undefined;
    const observed = try syntheticObservedStagedSource(
        source_bytes,
        context,
        bootstrap,
        &listing_buffer,
        &tree_buffer,
    );
    return normalizeAuthenticatedStagedSource(
        allocator,
        observed,
        bootstrap,
        context,
    );
}

pub fn syntheticObservedSourceCaptures(
    source_bytes: [capability_source_count][]const u8,
    context: *const AcceptanceAuthorityContext,
) [capability_source_count]ObservedSourceCapture {
    var result: [capability_source_count]ObservedSourceCapture = undefined;
    for (&result, source_bytes, capability_source_paths) |*entry, bytes, path| {
        entry.* = .{
            .context = context,
            .path = canonicalRepositoryPath(path) catch unreachable,
            .staged_bytes = bytes,
            .worktree_bytes = bytes,
        };
    }
    return result;
}

pub fn syntheticSemanticGates(context: *const AcceptanceAuthorityContext) ![7]AuthenticatedSemanticGate {
    return .{
        try gateCanonicalTupleAdmission(context, true),
        try gateSyntheticAuthorityBinding(context, true),
        try gatePreDescriptorRejection(context, true),
        try gatePostSealLengthSha(context, true),
        try gateFreshOwnedReplay(context, true),
        try gateConsumedHandoffRejection(context, true),
        try gateOwnershipExactlyOnceClose(context, true),
    };
}

pub fn syntheticAuthenticatedRepository(
    context: *const AcceptanceAuthorityContext,
) !AuthenticatedRepositoryScope {
    return authenticateValidatedRepositoryScope(
        validateObservedRepositoryScope(.{
            .descriptor_identity = context.repository_identity,
        }),
        context,
    );
}

pub fn syntheticAuthenticatedValidationDirectory(
    context: *const AcceptanceAuthorityContext,
) !AuthenticatedValidationDirectory {
    return authenticateValidatedValidationDirectory(
        validateObservedValidationDirectory(.{
            .descriptor_identity = context.validation_identity,
        }),
        context,
    );
}

pub fn advanceSyntheticDriverToPreparedReceipt(
    allocator: std.mem.Allocator,
    driver: *AcceptanceDriver,
    context: *const AcceptanceAuthorityContext,
    source_bytes: [capability_source_count][]const u8,
    final_target: ValidatedPublicationTarget,
) !PreparedReceipt {
    const repository = try syntheticAuthenticatedRepository(context);
    const bootstrap = try syntheticAuthenticatedBootstrap(context);
    const staged_source = try syntheticAuthenticatedStagedSource(
        allocator,
        source_bytes,
        context,
        bootstrap,
    );
    const format_result = try syntheticAuthenticatedProcess(
        allocator,
        .zig_format_check,
        "",
        bootstrap,
        context,
    );
    const focused_result = try syntheticAuthenticatedProcess(
        allocator,
        .zig_focused_test,
        "",
        bootstrap,
        context,
    );
    const gates = try syntheticSemanticGates(context);
    const validation_directory = try syntheticAuthenticatedValidationDirectory(context);
    try driver.acceptRepository(repository);
    try driver.acceptBootstrap(bootstrap);
    try driver.acceptStagedSource(staged_source);
    try driver.acceptFormatResult(format_result);
    try driver.acceptFocusedTestResult(focused_result);
    try driver.acceptSemanticGates(&gates);
    try driver.acceptValidationDirectory(validation_directory);
    return driver.prepareReceipt(final_target);
}

pub fn syntheticPublishedReceipt(
    prepared: PreparedReceipt,
) !PublishedReceipt {
    return bindPublishedReceipt(
        &prepared,
        prepared.context,
        prepared.validation_directory,
        prepared.final_target,
        .{
            .final_sha256 = prepared.canonical_sha256,
            .exact_length = prepared.exact_length,
            .completion_status = .complete,
        },
    );
}

pub fn failClosedRealRepositoryAdapter() DriverError!ObservedRepositoryScope {
    return error.AcceptanceAdaptersUnavailable;
}

pub fn failClosedRealBootstrapAdapter() DriverError!ObservedBootstrap {
    return error.AcceptanceAdaptersUnavailable;
}

pub fn failClosedRealProcessAdapter() DriverError!ObservedProcessResult {
    return error.AcceptanceAdaptersUnavailable;
}

pub fn failClosedRealNativeProcessAdapter() DriverError!AuthenticatedProcessResult {
    return error.AcceptanceAdaptersUnavailable;
}

pub fn failClosedRealValidationDirectoryAdapter() DriverError!ObservedValidationDirectory {
    return error.AcceptanceAdaptersUnavailable;
}

const path_b_validation_directory = "local-state/validations/inbox206cn";
const path_b_receipt_name = "path_b_synthetic_receipt.tsv";
const path_b_cwd = "/home/oleg/prog/z_llvm";
const path_b_child_switch = "--path-b-child";
const path_b_self_test_switch = "--path-b-self-test";
const path_b_environment = [_][]const u8{
    "LC_ALL=C",
    "ZLLVM_PATH_B_SYNTHETIC=1",
};
const path_b_success_stdout = "path-b-child-ok\n";
const path_b_success_stderr = "path-b-child-note\n";
const path_b_receipt_max_bytes = 4096;

const PathBScenario = enum {
    success,
    exit_7,
    oversized_stdout,
    inconsistent_output,

    fn name(self: PathBScenario) []const u8 {
        return switch (self) {
            .success => "success",
            .exit_7 => "exit-7",
            .oversized_stdout => "oversized-stdout",
            .inconsistent_output => "inconsistent-output",
        };
    }
};

const PathBInvocation = struct {
    executable: []const u8,
    argv: [3][]const u8,
    environment: [path_b_environment.len][]const u8,
    cwd: []const u8,
    scenario: PathBScenario,
    stdout_limit: usize,
    stderr_limit: usize,
    expected_stdout: []const u8,
    expected_stderr: []const u8,
    permitted_termination: ProcessTermination,
};

const PathBOwnedResult = struct {
    stdout: []u8,
    stderr: []u8,
    termination: ProcessTermination,

    fn deinit(self: *PathBOwnedResult, allocator: std.mem.Allocator) void {
        allocator.free(self.stdout);
        allocator.free(self.stderr);
        self.* = undefined;
    }
};

fn pathBInvocation(executable: []const u8, scenario: PathBScenario) PathBInvocation {
    const stdout_limit: usize = switch (scenario) {
        .oversized_stdout => 64,
        else => 256,
    };
    return .{
        .executable = executable,
        .argv = .{ executable, path_b_child_switch, scenario.name() },
        .environment = path_b_environment,
        .cwd = path_b_cwd,
        .scenario = scenario,
        .stdout_limit = stdout_limit,
        .stderr_limit = 256,
        .expected_stdout = path_b_success_stdout,
        .expected_stderr = path_b_success_stderr,
        .permitted_termination = .{ .exited = 0 },
    };
}

fn containsNul(bytes: []const u8) bool {
    return std.mem.indexOfScalar(u8, bytes, 0) != null;
}

fn validatePathBInvocation(invocation: *const PathBInvocation) DriverError!void {
    if (!std.fs.path.isAbsolute(invocation.executable) or containsNul(invocation.executable)) {
        return error.PathBFixedInputMismatch;
    }
    const expected = pathBInvocation(invocation.executable, invocation.scenario);
    if (invocation.argv.len != expected.argv.len or
        invocation.environment.len != expected.environment.len or
        !std.mem.eql(u8, invocation.cwd, expected.cwd) or
        invocation.stdout_limit != expected.stdout_limit or
        invocation.stderr_limit != expected.stderr_limit or
        !std.mem.eql(u8, invocation.expected_stdout, expected.expected_stdout) or
        !std.mem.eql(u8, invocation.expected_stderr, expected.expected_stderr) or
        !std.meta.eql(invocation.permitted_termination, expected.permitted_termination))
    {
        return error.PathBFixedInputMismatch;
    }
    for (invocation.argv, expected.argv) |actual, fixed| {
        if (containsNul(actual) or !std.mem.eql(u8, actual, fixed)) {
            return error.PathBFixedInputMismatch;
        }
    }
    for (invocation.environment, expected.environment) |actual, fixed| {
        if (containsNul(actual) or !std.mem.eql(u8, actual, fixed)) {
            return error.PathBFixedInputMismatch;
        }
    }
}

fn pathBEnvironment(allocator: std.mem.Allocator) !std.process.Environ.Map {
    var environment = std.process.Environ.Map.init(allocator);
    errdefer environment.deinit();
    for (path_b_environment) |entry| {
        const separator = std.mem.indexOfScalar(u8, entry, '=') orelse unreachable;
        try environment.put(entry[0..separator], entry[separator + 1 ..]);
    }
    return environment;
}

fn pathBTermination(term: std.process.Child.Term) ProcessTermination {
    return switch (term) {
        .exited => |code| .{ .exited = code },
        .signal => |signal| .{ .signaled = @intCast(@intFromEnum(signal)) },
        .stopped => |signal| .{ .stopped = @intCast(@intFromEnum(signal)) },
        .unknown => |status| .{ .unknown = status },
    };
}

fn runPathBProcess(
    allocator: std.mem.Allocator,
    io: std.Io,
    invocation: *const PathBInvocation,
) !PathBOwnedResult {
    try validatePathBInvocation(invocation);
    var environment = try pathBEnvironment(allocator);
    defer environment.deinit();

    const raw = std.process.run(allocator, io, .{
        .argv = &invocation.argv,
        .cwd = .{ .path = invocation.cwd },
        .environ_map = &environment,
        .stdout_limit = .limited(invocation.stdout_limit),
        .stderr_limit = .limited(invocation.stderr_limit),
    }) catch |failure| switch (failure) {
        error.StreamTooLong => return error.PathBOutputBoundExceeded,
        else => return error.PathBLaunchFailed,
    };
    errdefer allocator.free(raw.stdout);
    errdefer allocator.free(raw.stderr);

    const termination = pathBTermination(raw.term);
    if (!std.meta.eql(termination, invocation.permitted_termination)) {
        return error.PathBStatusMismatch;
    }
    if (!std.mem.eql(u8, raw.stdout, invocation.expected_stdout) or
        !std.mem.eql(u8, raw.stderr, invocation.expected_stderr))
    {
        return error.PathBInconsistentResult;
    }
    return .{
        .stdout = raw.stdout,
        .stderr = raw.stderr,
        .termination = termination,
    };
}

fn writeHex(writer: *std.Io.Writer, bytes: []const u8) !void {
    const alphabet = "0123456789abcdef";
    for (bytes) |byte| {
        try writer.writeByte(alphabet[byte >> 4]);
        try writer.writeByte(alphabet[byte & 0x0f]);
    }
}

fn writeHexSequence(writer: *std.Io.Writer, values: []const []const u8) !void {
    for (values, 0..) |value, index| {
        if (index != 0) try writer.writeByte(',');
        try writeHex(writer, value);
    }
}

fn writePathBTermination(writer: *std.Io.Writer, termination: ProcessTermination) !void {
    switch (termination) {
        .exited => |code| try writer.print("exited:{}", .{code}),
        .signaled => |signal| try writer.print("signaled:{}", .{signal}),
        .stopped => |signal| try writer.print("stopped:{}", .{signal}),
        .unknown => |status| try writer.print("unknown:{}", .{status}),
    }
}

fn encodePathBReceipt(
    output: *[path_b_receipt_max_bytes]u8,
    invocation: *const PathBInvocation,
    result: *const PathBOwnedResult,
) ![]const u8 {
    try validatePathBInvocation(invocation);
    var stream = std.Io.Writer.fixed(output);
    const writer = &stream;
    try writer.writeAll("schema\tzllvm-inbox206cn-path-b-synthetic-v1\n");
    try writer.writeAll("executable\t");
    try writeHex(writer, invocation.executable);
    try writer.writeByte('\n');
    try writer.writeAll("argv\t");
    try writeHexSequence(writer, &invocation.argv);
    try writer.writeByte('\n');
    try writer.writeAll("environment\t");
    try writeHexSequence(writer, &invocation.environment);
    try writer.writeByte('\n');
    try writer.writeAll("cwd\t");
    try writeHex(writer, invocation.cwd);
    try writer.writeByte('\n');
    try writer.writeAll("termination\t");
    try writePathBTermination(writer, result.termination);
    try writer.writeByte('\n');
    try writer.writeAll("stdout\t");
    try writeHex(writer, result.stdout);
    try writer.writeByte('\n');
    try writer.writeAll("stderr\t");
    try writeHex(writer, result.stderr);
    try writer.writeByte('\n');
    try writer.writeAll("completion\tcomplete\n");

    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(stream.buffered(), &digest, .{});
    var digest_hex: [64]u8 = undefined;
    encodeLowerHex(&digest, &digest_hex);
    try writer.print("binding_sha256\t{s}\n", .{&digest_hex});
    return stream.buffered();
}

fn verifyPathBReceipt(
    bytes: []const u8,
    invocation: *const PathBInvocation,
    result: *const PathBOwnedResult,
) DriverError!void {
    const digest_record_bytes = "binding_sha256\t".len + 64 + 1;
    if (bytes.len <= digest_record_bytes) return error.PathBReceiptMalformed;
    const digest_record_start = bytes.len - digest_record_bytes;
    if (!std.mem.eql(
        u8,
        bytes[digest_record_start .. digest_record_start + "binding_sha256\t".len],
        "binding_sha256\t",
    ) or bytes[bytes.len - 1] != '\n') return error.PathBReceiptMalformed;

    var recorded_digest: [32]u8 = undefined;
    decodeLowerHex(
        bytes[digest_record_start + "binding_sha256\t".len .. bytes.len - 1],
        &recorded_digest,
    ) catch return error.PathBReceiptMalformed;
    var actual_digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes[0..digest_record_start], &actual_digest, .{});
    if (!std.mem.eql(u8, &recorded_digest, &actual_digest)) {
        return error.PathBReceiptBindingMismatch;
    }

    var expected_buffer: [path_b_receipt_max_bytes]u8 = undefined;
    const expected = encodePathBReceipt(&expected_buffer, invocation, result) catch
        return error.PathBReceiptMalformed;
    if (!std.mem.eql(u8, bytes, expected)) return error.PathBReceiptBindingMismatch;
}

fn publishAndVerifyPathBReceipt(
    allocator: std.mem.Allocator,
    io: std.Io,
    bytes: []const u8,
    invocation: *const PathBInvocation,
    result: *const PathBOwnedResult,
) !void {
    var directory = try std.Io.Dir.cwd().openDir(io, path_b_validation_directory, .{
        .access_sub_paths = true,
        .iterate = false,
    });
    defer directory.close(io);
    var atomic_file = try directory.createFileAtomic(io, path_b_receipt_name, .{
        .permissions = .fromMode(0o644),
        .replace = true,
    });
    defer atomic_file.deinit(io);
    try atomic_file.file.writeStreamingAll(io, bytes);
    try atomic_file.file.sync(io);
    try atomic_file.replace(io);

    const read_back = try directory.readFileAlloc(
        io,
        path_b_receipt_name,
        allocator,
        .limited(path_b_receipt_max_bytes),
    );
    defer allocator.free(read_back);
    try verifyPathBReceipt(read_back, invocation, result);
}

fn runPathBSelfTest(
    allocator: std.mem.Allocator,
    io: std.Io,
    executable: []const u8,
) !void {
    const missing = pathBInvocation("/__zllvm_inbox206cn_missing_child__", .success);
    try std.testing.expectError(
        error.PathBLaunchFailed,
        runPathBProcess(allocator, io, &missing),
    );

    const nonzero = pathBInvocation(executable, .exit_7);
    try std.testing.expectError(
        error.PathBStatusMismatch,
        runPathBProcess(allocator, io, &nonzero),
    );

    const oversized = pathBInvocation(executable, .oversized_stdout);
    try std.testing.expectError(
        error.PathBOutputBoundExceeded,
        runPathBProcess(allocator, io, &oversized),
    );

    const inconsistent = pathBInvocation(executable, .inconsistent_output);
    try std.testing.expectError(
        error.PathBInconsistentResult,
        runPathBProcess(allocator, io, &inconsistent),
    );

    const success = pathBInvocation(executable, .success);
    var first = try runPathBProcess(allocator, io, &success);
    defer first.deinit(allocator);
    var second = try runPathBProcess(allocator, io, &success);
    defer second.deinit(allocator);
    try std.testing.expectEqualSlices(u8, first.stdout, second.stdout);
    try std.testing.expectEqualSlices(u8, first.stderr, second.stderr);
    try std.testing.expect(std.meta.eql(first.termination, second.termination));

    var first_buffer: [path_b_receipt_max_bytes]u8 = undefined;
    const first_receipt = try encodePathBReceipt(&first_buffer, &success, &first);
    var second_buffer: [path_b_receipt_max_bytes]u8 = undefined;
    const second_receipt = try encodePathBReceipt(&second_buffer, &success, &second);
    try std.testing.expectEqualSlices(u8, first_receipt, second_receipt);
    try publishAndVerifyPathBReceipt(allocator, io, first_receipt, &success, &first);
}

fn requirePathBChildContext(init: std.process.Init) !void {
    if (init.environ_map.count() != path_b_environment.len or
        !std.mem.eql(u8, init.environ_map.get("LC_ALL") orelse "", "C") or
        !std.mem.eql(
            u8,
            init.environ_map.get("ZLLVM_PATH_B_SYNTHETIC") orelse "",
            "1",
        ))
    {
        return error.PathBFixedInputMismatch;
    }
    const cwd = try std.process.currentPathAlloc(init.io, init.gpa);
    defer init.gpa.free(cwd);
    if (!std.mem.eql(u8, cwd, path_b_cwd)) return error.PathBFixedInputMismatch;
}

fn runPathBChild(init: std.process.Init, scenario_name: []const u8) !void {
    try requirePathBChildContext(init);
    var stdout_buffer: [1024]u8 = undefined;
    var stderr_buffer: [256]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &stdout_buffer);
    var stderr_writer = std.Io.File.stderr().writer(init.io, &stderr_buffer);

    if (std.mem.eql(u8, scenario_name, PathBScenario.success.name())) {
        try stdout_writer.interface.writeAll(path_b_success_stdout);
        try stderr_writer.interface.writeAll(path_b_success_stderr);
    } else if (std.mem.eql(u8, scenario_name, PathBScenario.exit_7.name())) {
        try stderr_writer.interface.writeAll(path_b_success_stderr);
        try stderr_writer.interface.flush();
        std.process.exit(7);
    } else if (std.mem.eql(u8, scenario_name, PathBScenario.oversized_stdout.name())) {
        const oversized = [_]u8{'x'} ** 512;
        try stdout_writer.interface.writeAll(&oversized);
        try stderr_writer.interface.writeAll(path_b_success_stderr);
    } else if (std.mem.eql(u8, scenario_name, PathBScenario.inconsistent_output.name())) {
        try stdout_writer.interface.writeAll("path-b-child-inconsistent\n");
        try stderr_writer.interface.writeAll(path_b_success_stderr);
    } else {
        return error.PathBFixedInputMismatch;
    }
    try stdout_writer.interface.flush();
    try stderr_writer.interface.flush();
}

pub const path_b_test_support = if (builtin.is_test) struct {
    pub const ScenarioId = enum {
        exact,
        wrong_command,
        wrong_environment,
        wrong_cwd,
        corrupt_receipt,
        trailing_receipt,
    };

    pub const Result = enum {
        accepted,
        fixed_input_rejected,
        receipt_rejected,
    };

    pub fn run(id: ScenarioId) !Result {
        var invocation = pathBInvocation("/synthetic/path-b-child", .success);
        switch (id) {
            .exact => {
                try validatePathBInvocation(&invocation);
                return .accepted;
            },
            .wrong_command => invocation.argv[1] = "--wrong-child-switch",
            .wrong_environment => invocation.environment[1] = "ZLLVM_PATH_B_SYNTHETIC=0",
            .wrong_cwd => invocation.cwd = "/synthetic/wrong-cwd",
            .corrupt_receipt, .trailing_receipt => {
                var stdout = path_b_success_stdout.*;
                var stderr = path_b_success_stderr.*;
                const result = PathBOwnedResult{
                    .stdout = stdout[0..path_b_success_stdout.len],
                    .stderr = stderr[0..path_b_success_stderr.len],
                    .termination = .{ .exited = 0 },
                };
                var bytes: [path_b_receipt_max_bytes]u8 = undefined;
                const encoded = try encodePathBReceipt(&bytes, &invocation, &result);
                if (id == .corrupt_receipt) {
                    bytes[0] = 'x';
                    verifyPathBReceipt(encoded, &invocation, &result) catch
                        return .receipt_rejected;
                } else {
                    bytes[encoded.len] = 'x';
                    verifyPathBReceipt(bytes[0 .. encoded.len + 1], &invocation, &result) catch
                        return .receipt_rejected;
                }
                return .accepted;
            },
        }
        validatePathBInvocation(&invocation) catch return .fixed_input_rejected;
        return .accepted;
    }
} else struct {};

pub fn main(init: std.process.Init) !void {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, init.gpa);
    defer args.deinit();
    const executable = args.next() orelse return error.AcceptanceAdaptersUnavailable;
    const command = args.next() orelse return error.AcceptanceAdaptersUnavailable;
    if (std.mem.eql(u8, command, path_b_child_switch)) {
        const scenario = args.next() orelse return error.PathBFixedInputMismatch;
        if (args.next() != null) return error.PathBFixedInputMismatch;
        return runPathBChild(init, scenario);
    }
    if (std.mem.eql(u8, command, path_b_self_test_switch)) {
        if (args.next() != null) return error.PathBFixedInputMismatch;
        var executable_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined;
        const executable_length = try std.Io.Dir.cwd().realPathFile(
            init.io,
            executable,
            &executable_buffer,
        );
        const absolute_executable = executable_buffer[0..executable_length];
        if (!std.fs.path.isAbsolute(absolute_executable)) return error.PathBFixedInputMismatch;
        try runPathBSelfTest(init.gpa, init.io, absolute_executable);
        var stdout_buffer: [128]u8 = undefined;
        var stdout_writer = std.Io.File.stdout().writer(init.io, &stdout_buffer);
        try stdout_writer.interface.writeAll("INBOX206CN_PATH_B_OK\n");
        try stdout_writer.interface.flush();
        return;
    }
    return error.AcceptanceAdaptersUnavailable;
}
