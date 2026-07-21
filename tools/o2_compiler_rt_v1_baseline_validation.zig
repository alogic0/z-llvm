const std = @import("std");

pub const source_commit = "43de59b06ca3a687368bfaf0595c5759c8ab3a57";
pub const external_zig_commit = "bdee02bc0c7f227c0f11bc9a449df673fe803540";
pub const external_zig_tree = "aa032b2b82a48a4684657f909e6e270a6c925e33";
pub const bypass_ratchet: u16 = 131;
pub const minimum_available_bytes: u64 = 17_179_869_184;
pub const accepted_maximum_storage_bytes: ?u64 = null;
pub const canonical_repetition_count: usize = 3;
pub const successful_function_count: u16 = 285;

pub const IdentityKind = enum {
    sha256,
    git_commit,
    git_tree,
    git_blob,
};

pub const IdentityDescriptor = struct {
    label: []const u8,
    kind: IdentityKind,
    digest: []const u8,
    bytes: ?u64,
};

pub const closed_identities = [_]IdentityDescriptor{
    .{ .label = "baseline_source_commit", .kind = .git_commit, .digest = source_commit, .bytes = null },
    .{ .label = "external_zig_commit", .kind = .git_commit, .digest = external_zig_commit, .bytes = null },
    .{ .label = "external_zig_tree", .kind = .git_tree, .digest = external_zig_tree, .bytes = null },
    .{ .label = "raw_module", .kind = .sha256, .digest = "9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1", .bytes = 1_897_410 },
    .{ .label = "adoption_manifest", .kind = .sha256, .digest = "500e73c8433aa73159adfba5de8a6708ae4030140b97b823ef895caa1528f2bf", .bytes = 4_394 },
    .{ .label = "reproduction_manifest", .kind = .sha256, .digest = "885008980c8a272e82d06cf89b81652ab5a9669e89364b01d7b9e2761135ff1e", .bytes = 458_294 },
    .{ .label = "bundle_manifest", .kind = .sha256, .digest = "0576d5803400ea9575d65fc501b87d514c97e806540be29018fb5192bd68e7f0", .bytes = 2_519 },
    .{ .label = "combined_patch", .kind = .sha256, .digest = "7508d1d8f74b7e9b97ae5722a0822a86c8d2079779a25cd37559ce5bc651036f", .bytes = 41_140 },
    .{ .label = "retention_pins", .kind = .sha256, .digest = "1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3", .bytes = 3_051 },
    .{ .label = "retention_policy", .kind = .sha256, .digest = "a31e3fbf7aa03c8544fc5f9921e350c25e4e470cc3c779dfb356136634e052dd", .bytes = 10_622 },
    .{ .label = "cleanup_source", .kind = .sha256, .digest = "8e0c54ad6fed9e46326049dbe64bff743daddcc2527c1dc4d5e02be15fba2d5e", .bytes = 50_100 },
    .{ .label = "watcher", .kind = .git_blob, .digest = "b64131cf60dd0ef638e815cd33db9ae8595a72cf", .bytes = 10_850 },
    .{ .label = "bypass_inventory", .kind = .sha256, .digest = "2d6c8c8819c4b0dff10b9d803a62125d7c46155c04a2c2cf2006f2aecffd8b11", .bytes = 5_188 },
    .{ .label = "facade_manifest", .kind = .sha256, .digest = "2adcd99ee3bfbe0e9f09673f1df02ab305b5ddb2c1b461023152d5d03a079c26", .bytes = 2_686 },
    .{ .label = "facade_source", .kind = .sha256, .digest = "4f5887e9d2bce0943df26c1e08e8360053440da64eefd19ddfd9d53225dddd7a", .bytes = 103 },
    .{ .label = "external_stage4", .kind = .sha256, .digest = "dcea3478273d7ffe3895709c8eed4ccc0724548869cdb86183fc7356164410b7", .bytes = 530_327_885 },
};

pub const compatibility_keys = [_][]const u8{
    "calls/input/accepted-cohort-ac285/v1",
    "calls/input/compiler-rt-v1/raw/adoption-final/v1",
    "calls/input/compiler-rt-v1/raw/adoption-manifest/v1",
    "calls/input/compiler-rt-v1/raw/module/v1",
    "calls/input/validation-v3/coverage-bundle/manifests/baseline-source.sha256/v1",
    "calls/input/validation-v3/coverage-bundle/manifests/bundle-files.sha256/v1",
    "calls/input/validation-v3/coverage-bundle/manifests/bundled-source.sha256/v1",
    "calls/input/validation-v3/coverage-bundle/manifests/combined-apply-source.sha256/v1",
    "calls/input/validation-v3/coverage-bundle/manifests/future-tool-identities.sha256/v1",
    "calls/input/validation-v3/coverage-bundle/manifests/patch-manifest.tsv/v1",
    "calls/input/validation-v3/coverage-bundle/manifests/payload-final-modes.tsv/v1",
    "calls/input/validation-v3/coverage-bundle/manifests/preflight-and-apply-proof.txt/v1",
    "calls/input/validation-v3/coverage-bundle/manifests/restored-source.sha256/v1",
    "calls/input/validation-v3/coverage-bundle/manifests/sequential-apply-source.sha256/v1",
    "calls/input/validation-v3/coverage-bundle/manifests/touched-paths.txt/v1",
    "calls/input/validation-v3/coverage-bundle/patches/01-aggregate-consumer.patch/v1",
    "calls/input/validation-v3/coverage-bundle/patches/02-fixed-observer.patch/v1",
    "calls/input/validation-v3/coverage-bundle/patches/03-exact-combined-guard.patch/v1",
    "calls/input/validation-v3/coverage-bundle/patches/aggregate-consumer-observer-guard.patch/v1",
};

pub const ContractError = error{
    IdentityCountMismatch,
    IdentityDrift,
    CompatibilityKeyCountMismatch,
    CompatibilityKeyDrift,
    PathEscape,
    PathCollision,
    ExhaustedNamespace,
    SupersededNamespace,
    InsufficientCapacity,
    RepetitionCountMismatch,
    RepetitionMismatch,
    AcceptedSubsetProducerMismatch,
    SuccessfulFunctionCountMismatch,
    ChannelViolation,
    CounterViolation,
    RestorationFailure,
    SemanticMismatch,
    PhaseOutOfOrder,
    PhaseSuppressed,
};

pub fn validateIdentities(observed: []const IdentityDescriptor) ContractError!void {
    if (observed.len != closed_identities.len) return error.IdentityCountMismatch;
    for (closed_identities, observed) |expected, actual| {
        if (!std.mem.eql(u8, expected.label, actual.label) or
            expected.kind != actual.kind or
            !std.mem.eql(u8, expected.digest, actual.digest) or
            expected.bytes != actual.bytes)
        {
            return error.IdentityDrift;
        }
    }
}

pub fn validateCompatibilityKeys(observed: []const []const u8) ContractError!void {
    if (observed.len != compatibility_keys.len) return error.CompatibilityKeyCountMismatch;
    for (compatibility_keys, observed) |expected, actual| {
        if (!std.mem.eql(u8, expected, actual)) return error.CompatibilityKeyDrift;
    }
}

pub const V3Path = enum {
    validation_root,
    canonical_source,
    coverage_source,
    canonical_cache,
    canonical_install,
    coverage_cache,
    coverage_install,
};

pub fn plannedPath(path: V3Path) []const u8 {
    return switch (path) {
        .validation_root => "local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3",
        .canonical_source => "local-state/worktrees/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical-source",
        .coverage_source => "local-state/worktrees/o2-calls/compiler-rt-v1/baseline-validation-v3/coverage-source",
        .canonical_cache => "local-state/caches/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical/cache",
        .canonical_install => "local-state/caches/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical/install",
        .coverage_cache => "local-state/caches/o2-calls/compiler-rt-v1/baseline-validation-v3/coverage/cache",
        .coverage_install => "local-state/caches/o2-calls/compiler-rt-v1/baseline-validation-v3/coverage/install",
    };
}

pub const PathObservation = struct {
    candidate: []const u8,
    exists: bool = false,
    is_symlink: bool = false,
};

pub fn validatePlannedPath(path: V3Path, observation: PathObservation) ContractError!void {
    if (isExhaustedNamespace(observation.candidate)) return error.ExhaustedNamespace;
    if (isSupersededV3(observation.candidate)) return error.SupersededNamespace;
    if (!std.mem.eql(u8, plannedPath(path), observation.candidate)) return error.PathEscape;
    if (observation.exists or observation.is_symlink) return error.PathCollision;
}

fn isExhaustedNamespace(path: []const u8) bool {
    return std.mem.indexOf(u8, path, "baseline_validation_v1") != null or
        std.mem.indexOf(u8, path, "baseline_validation_v2") != null or
        std.mem.indexOf(u8, path, "baseline-validation-v1") != null or
        std.mem.indexOf(u8, path, "baseline-validation-v2") != null;
}

fn isSupersededV3(path: []const u8) bool {
    return std.mem.eql(u8, path, "/home/oleg/prog/z_llvm-baseline-validation-v3") or
        std.mem.eql(u8, path, "tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3") or
        std.mem.eql(u8, path, "/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3");
}

pub const ExecutionReadiness = enum {
    not_ready_insufficient_capacity,
    not_ready_maximum_storage_ceiling_absent,
};

pub fn executionReadiness(available_bytes: u64) ExecutionReadiness {
    if (available_bytes < minimum_available_bytes) return .not_ready_insufficient_capacity;
    std.debug.assert(accepted_maximum_storage_bytes == null);
    return .not_ready_maximum_storage_ceiling_absent;
}

pub fn requireMinimumCapacity(available_bytes: u64) ContractError!void {
    if (available_bytes < minimum_available_bytes) return error.InsufficientCapacity;
}

pub const Phase = enum(u8) {
    preflight,
    canonical_source,
    canonical_build,
    canonical_repetition_1,
    canonical_repetition_2,
    canonical_repetition_3,
    canonical_finalize,
    coverage_source,
    coverage_build,
    observation_off,
    observation_on,
    coverage_finalize,
    restoration,
    complete,
};

pub const PhaseStatus = enum {
    pending,
    succeeded,
    failed,
    suppressed,
};

pub const PhaseMachine = struct {
    statuses: [phase_count]PhaseStatus,
    next: usize,
    first_failure: ?Phase,

    const phase_count = @typeInfo(Phase).@"enum".fields.len;

    pub fn init() PhaseMachine {
        return .{
            .statuses = [_]PhaseStatus{.pending} ** phase_count,
            .next = 0,
            .first_failure = null,
        };
    }

    pub fn succeed(self: *PhaseMachine, phase: Phase) ContractError!void {
        if (self.first_failure != null) return error.PhaseSuppressed;
        const index = @intFromEnum(phase);
        if (index != self.next) return error.PhaseOutOfOrder;
        self.statuses[index] = .succeeded;
        self.next += 1;
    }

    pub fn fail(self: *PhaseMachine, phase: Phase) ContractError!void {
        if (self.first_failure != null) return error.PhaseSuppressed;
        const index = @intFromEnum(phase);
        if (index != self.next) return error.PhaseOutOfOrder;
        self.statuses[index] = .failed;
        self.first_failure = phase;
        for (self.statuses[index + 1 ..]) |*phase_status| phase_status.* = .suppressed;
        self.next = self.statuses.len;
    }

    pub fn status(self: PhaseMachine, phase: Phase) PhaseStatus {
        return self.statuses[@intFromEnum(phase)];
    }
};

pub const Digest = [32]u8;

pub const CanonicalRepetition = struct {
    report: Digest,
    object: Digest,
    owner: Digest,
    function_manifest: Digest,
    function_count: u16,
    accepted_subset_produced: bool,
};

pub fn validateCanonicalRepetitions(repetitions: []const CanonicalRepetition) ContractError!void {
    if (repetitions.len != canonical_repetition_count) return error.RepetitionCountMismatch;
    if (!repetitions[0].accepted_subset_produced or
        repetitions[1].accepted_subset_produced or
        repetitions[2].accepted_subset_produced)
    {
        return error.AcceptedSubsetProducerMismatch;
    }
    for (repetitions) |repetition| {
        if (repetition.function_count != successful_function_count)
            return error.SuccessfulFunctionCountMismatch;
        if (!sameCanonicalIdentity(repetitions[0], repetition))
            return error.RepetitionMismatch;
    }
}

fn sameCanonicalIdentity(a: CanonicalRepetition, b: CanonicalRepetition) bool {
    return std.mem.eql(u8, &a.report, &b.report) and
        std.mem.eql(u8, &a.object, &b.object) and
        std.mem.eql(u8, &a.owner, &b.owner) and
        std.mem.eql(u8, &a.function_manifest, &b.function_manifest);
}

pub const Family = enum {
    direct_call,
    int_byte_size_call,
};

pub const FamilyCounters = struct {
    transactions: u64,
    requests: u64,
    attachments: u64,
    stages: u64,
    materializations: u64,
    actions: u64,
    commits: u64,
    position_requests: [6]u64,
    position_stages: [6]u64,
};

pub const FamilyPair = struct {
    direct_call: FamilyCounters,
    int_byte_size_call: FamilyCounters,
};

pub const ChannelPresence = struct {
    report: bool,
    object: bool,
    owner: bool,
};

pub const CoverageState = struct {
    observation_off: ChannelPresence,
    observation_on: ChannelPresence,
    on_channel_producers: [3]u8,
    unexpected_family_events: u64,
    argument_index_overflow_events: u64,
    report: FamilyPair,
    object: FamilyPair,
    owner: FamilyPair,
};

pub fn validateCoverage(state: CoverageState) ContractError!void {
    if (state.observation_off.report or state.observation_off.object or state.observation_off.owner or
        !state.observation_on.report or !state.observation_on.object or !state.observation_on.owner)
    {
        return error.ChannelViolation;
    }
    for (state.on_channel_producers) |count| {
        if (count != 1) return error.ChannelViolation;
    }
    if (state.unexpected_family_events != 0 or state.argument_index_overflow_events != 0)
        return error.CounterViolation;

    try validateReportFamily(state.report.direct_call);
    try validateReportFamily(state.report.int_byte_size_call);
    try validateSuccessfulFamily(.direct_call, state.object.direct_call);
    try validateSuccessfulFamily(.int_byte_size_call, state.object.int_byte_size_call);
    try validateSuccessfulFamily(.direct_call, state.owner.direct_call);
    try validateSuccessfulFamily(.int_byte_size_call, state.owner.int_byte_size_call);
    if (!std.meta.eql(state.object, state.owner)) return error.CounterViolation;
}

fn validateReportFamily(counters: FamilyCounters) ContractError!void {
    if (counters.transactions == 0 or counters.requests == 0 or
        counters.attachments == 0 or counters.stages == 0 or
        counters.materializations == 0 or counters.actions == 0 or
        counters.commits == 0)
    {
        return error.CounterViolation;
    }
}

fn validateSuccessfulFamily(family: Family, counters: FamilyCounters) ContractError!void {
    if (counters.transactions == 0 or
        counters.transactions != counters.attachments or
        counters.transactions != counters.materializations or
        counters.transactions != counters.actions or
        counters.transactions != counters.commits or
        counters.requests != counters.stages)
    {
        return error.CounterViolation;
    }
    for (counters.position_requests, counters.position_stages) |requests, stages| {
        if (requests != stages) return error.CounterViolation;
    }
    switch (family) {
        .direct_call => if (counters.requests == 0) return error.CounterViolation,
        .int_byte_size_call => {
            if (counters.requests != counters.transactions or
                counters.position_requests[0] != counters.transactions)
            {
                return error.CounterViolation;
            }
            for (counters.position_requests[1..]) |requests| {
                if (requests != 0) return error.CounterViolation;
            }
        },
    }
}

pub const RestorationState = struct {
    head_before: []const u8,
    head_after: []const u8,
    tracked_manifest_before: Digest,
    tracked_manifest_after: Digest,
    clean: bool,
    observer_source_absent: bool,
    ratchet: u16,
};

pub fn validateRestoration(state: RestorationState) ContractError!void {
    if (!std.mem.eql(u8, state.head_before, source_commit) or
        !std.mem.eql(u8, state.head_after, source_commit) or
        !std.mem.eql(u8, &state.tracked_manifest_before, &state.tracked_manifest_after) or
        !state.clean or !state.observer_source_absent or state.ratchet != bypass_ratchet)
    {
        return error.RestorationFailure;
    }
}

pub const SemanticIdentity = struct {
    report: Digest,
    object: Digest,
    owner: Digest,
};

pub const SemanticEquality = struct {
    canonical: SemanticIdentity,
    observation_off: SemanticIdentity,
    observation_on: SemanticIdentity,
};

pub fn validateSemanticEquality(state: SemanticEquality) ContractError!void {
    if (!sameSemanticIdentity(state.canonical, state.observation_off) or
        !sameSemanticIdentity(state.canonical, state.observation_on))
    {
        return error.SemanticMismatch;
    }
}

fn sameSemanticIdentity(a: SemanticIdentity, b: SemanticIdentity) bool {
    return std.mem.eql(u8, &a.report, &b.report) and
        std.mem.eql(u8, &a.object, &b.object) and
        std.mem.eql(u8, &a.owner, &b.owner);
}

fn testDigest(byte: u8) Digest {
    return [_]u8{byte} ** 32;
}

fn testCanonicalRepetitions() [canonical_repetition_count]CanonicalRepetition {
    const identity = CanonicalRepetition{
        .report = testDigest(1),
        .object = testDigest(2),
        .owner = testDigest(3),
        .function_manifest = testDigest(4),
        .function_count = successful_function_count,
        .accepted_subset_produced = false,
    };
    var result = [_]CanonicalRepetition{identity} ** canonical_repetition_count;
    result[0].accepted_subset_produced = true;
    return result;
}

fn testFamilyCounters(family: Family) FamilyCounters {
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

fn testCoverageState() CoverageState {
    const families = FamilyPair{
        .direct_call = testFamilyCounters(.direct_call),
        .int_byte_size_call = testFamilyCounters(.int_byte_size_call),
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

test "baseline validation rejects identity and compatibility-key drift" {
    try validateIdentities(&closed_identities);
    try validateCompatibilityKeys(&compatibility_keys);

    var identities = closed_identities;
    identities[3].digest = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
    try std.testing.expectError(error.IdentityDrift, validateIdentities(&identities));

    var keys = compatibility_keys;
    keys[18] = "calls/input/validation-v3/coverage-bundle/patches/wrong/v1";
    try std.testing.expectError(error.CompatibilityKeyDrift, validateCompatibilityKeys(&keys));
}

test "baseline validation rejects path escape collision and exhausted namespaces" {
    try validatePlannedPath(.validation_root, .{ .candidate = plannedPath(.validation_root) });
    try std.testing.expectError(error.PathCollision, validatePlannedPath(.validation_root, .{
        .candidate = plannedPath(.validation_root),
        .exists = true,
    }));
    try std.testing.expectError(error.PathEscape, validatePlannedPath(.validation_root, .{
        .candidate = "local-state/validations/o2-calls/compiler-rt-v1/elsewhere",
    }));
    try std.testing.expectError(error.ExhaustedNamespace, validatePlannedPath(.validation_root, .{
        .candidate = "tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v2",
    }));
    try std.testing.expectError(error.SupersededNamespace, validatePlannedPath(.validation_root, .{
        .candidate = "/home/oleg/prog/z_llvm-baseline-validation-v3",
    }));
}

test "baseline validation minimum capacity never implies execution readiness" {
    try std.testing.expectError(error.InsufficientCapacity, requireMinimumCapacity(minimum_available_bytes - 1));
    try requireMinimumCapacity(minimum_available_bytes);
    try std.testing.expectEqual(
        ExecutionReadiness.not_ready_insufficient_capacity,
        executionReadiness(minimum_available_bytes - 1),
    );
    try std.testing.expectEqual(
        ExecutionReadiness.not_ready_maximum_storage_ceiling_absent,
        executionReadiness(minimum_available_bytes),
    );
    try std.testing.expect(accepted_maximum_storage_bytes == null);
}

test "baseline validation rejects canonical repetition mismatch" {
    var repetitions = testCanonicalRepetitions();
    try validateCanonicalRepetitions(&repetitions);
    repetitions[2].object = testDigest(9);
    try std.testing.expectError(error.RepetitionMismatch, validateCanonicalRepetitions(&repetitions));
}

test "baseline validation rejects coverage channel and counter violations" {
    var state = testCoverageState();
    try validateCoverage(state);

    state.observation_on.report = false;
    try std.testing.expectError(error.ChannelViolation, validateCoverage(state));
    state = testCoverageState();
    state.unexpected_family_events = 1;
    try std.testing.expectError(error.CounterViolation, validateCoverage(state));
    state = testCoverageState();
    state.object.int_byte_size_call.position_requests[1] = 1;
    state.object.int_byte_size_call.position_stages[1] = 1;
    try std.testing.expectError(error.CounterViolation, validateCoverage(state));
    state = testCoverageState();
    state.owner.direct_call.commits += 1;
    try std.testing.expectError(error.CounterViolation, validateCoverage(state));
}

test "baseline validation rejects restoration failure" {
    const manifest = testDigest(7);
    var state = RestorationState{
        .head_before = source_commit,
        .head_after = source_commit,
        .tracked_manifest_before = manifest,
        .tracked_manifest_after = manifest,
        .clean = true,
        .observer_source_absent = true,
        .ratchet = bypass_ratchet,
    };
    try validateRestoration(state);
    state.clean = false;
    try std.testing.expectError(error.RestorationFailure, validateRestoration(state));
}

test "baseline validation rejects semantic mismatch" {
    const identity = SemanticIdentity{
        .report = testDigest(10),
        .object = testDigest(11),
        .owner = testDigest(12),
    };
    var state = SemanticEquality{
        .canonical = identity,
        .observation_off = identity,
        .observation_on = identity,
    };
    try validateSemanticEquality(state);
    state.observation_on.report = testDigest(13);
    try std.testing.expectError(error.SemanticMismatch, validateSemanticEquality(state));
}

test "baseline validation first failure suppresses every later phase" {
    var machine = PhaseMachine.init();
    try machine.succeed(.preflight);
    try machine.fail(.canonical_source);

    try std.testing.expectEqual(PhaseStatus.succeeded, machine.status(.preflight));
    try std.testing.expectEqual(PhaseStatus.failed, machine.status(.canonical_source));
    try std.testing.expectEqual(PhaseStatus.suppressed, machine.status(.canonical_build));
    try std.testing.expectEqual(PhaseStatus.suppressed, machine.status(.complete));
    try std.testing.expectEqual(Phase.canonical_source, machine.first_failure.?);
    try std.testing.expectError(error.PhaseSuppressed, machine.succeed(.canonical_build));
}
