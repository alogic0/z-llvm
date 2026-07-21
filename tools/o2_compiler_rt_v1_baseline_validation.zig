const std = @import("std");

pub const source_commit = "43de59b06ca3a687368bfaf0595c5759c8ab3a57";
pub const external_zig_commit = "bdee02bc0c7f227c0f11bc9a449df673fe803540";
pub const external_zig_tree = "aa032b2b82a48a4684657f909e6e270a6c925e33";
pub const bypass_ratchet: u16 = 131;
pub const mebibyte_bytes: u64 = 1_048_576;
pub const minimum_available_bytes: u64 = 17_179_869_184;
pub const accepted_maximum_storage_bytes: u64 = 14_321_451_008;
pub const accepted_storage_reserve_bytes: u64 = 2_858_418_176;
pub const canonical_repetition_count: usize = 3;
pub const successful_function_count: u16 = 285;
pub const accepted_process_capture_bytes: u64 = 4 * mebibyte_bytes;

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
    UnknownStorageFamily,
    DuplicateStorageFamily,
    MissingStorageFamily,
    RequiredStorageMaximumZero,
    StorageMaximumMismatch,
    StorageBudgetOverflow,
    StorageReserveUnderflow,
    StoragePolicyDrift,
    AggregateExclusionMismatch,
    MinimumHeadroomSubstitution,
    InsufficientAvailableStorage,
    EnforcementEvidenceIncomplete,
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
    not_ready_storage_enforcement_absent,
    ready,
};

pub fn executionReadiness(available_bytes: u64) ExecutionReadiness {
    if (available_bytes < minimum_available_bytes) return .not_ready_insufficient_capacity;
    std.debug.assert(accepted_maximum_storage_bytes < minimum_available_bytes);
    return .not_ready_storage_enforcement_absent;
}

pub fn requireMinimumCapacity(available_bytes: u64) ContractError!void {
    if (available_bytes < minimum_available_bytes) return error.InsufficientCapacity;
}

pub const EnforcementPrerequisite = enum(u8) {
    canonical_absolute_inputs,
    closed_bounded_processes,
    registered_worktree_prefix_exclusion,
    v3_layout,
    exact_identity_and_key_set,
    file_and_root_caps,
    family_caps,
    aggregate_exclusions,
    repetitions_and_counters,
    phase_and_first_failure,
    restoration_and_semantic_equality,
    atomic_publication_and_readback,
};

pub const required_enforcement_prerequisites = [_]EnforcementPrerequisite{
    .canonical_absolute_inputs,
    .closed_bounded_processes,
    .registered_worktree_prefix_exclusion,
    .v3_layout,
    .exact_identity_and_key_set,
    .file_and_root_caps,
    .family_caps,
    .aggregate_exclusions,
    .repetitions_and_counters,
    .phase_and_first_failure,
    .restoration_and_semantic_equality,
    .atomic_publication_and_readback,
};

pub const EnforcedStorageFamily = struct {
    family: StorageFamily,
    maximum_bytes: u64,
    retention: StorageRetentionClass,
    enforcement: StorageEnforcementPrimitive,
    aggregate_exclusions: u32,
};

pub const CompleteEnforcementEvidence = struct {
    prerequisites: []const EnforcementPrerequisite,
    storage_families: []const EnforcedStorageFamily,
    available_bytes: u64,
    identity_count: usize,
    compatibility_key_count: usize,
    v3_path_count: usize,
    repetition_count: usize,
    successful_functions: u16,
    phase_count: usize,
    stdout_capture_bytes: u64,
    stderr_capture_bytes: u64,
};

pub const StorageFamily = enum(u8) {
    external_preflight_driver_records = 1,
    namespace_parents = 2,
    canonical_build_cache_install = 3,
    canonical_repetition_home_tmp = 4,
    canonical_artifact = 5,
    canonical_artifact_identity = 6,
    canonical_step_status_records = 7,
    canonical_build_raw_status = 8,
    repetition_raw_report = 9,
    canonical_accepted_ll = 10,
    accepted_ll_proof = 11,
    repetition_successful_subset = 12,
    canonical_per_function = 13,
    canonical_comparisons = 14,
    canonical_identities = 15,
    canonical_final_manifests = 16,
    coverage_build_cache_install = 17,
    coverage_artifact = 18,
    coverage_reference = 19,
    observation_off = 20,
    observation_on_channels = 21,
    observation_on_remaining = 22,
    coverage_per_function = 23,
    coverage_comparisons = 24,
    coverage_final_manifests = 25,
    publication_evidence = 26,
    durability_terminal = 27,
};

pub const storage_families = [_]StorageFamily{
    .external_preflight_driver_records,
    .namespace_parents,
    .canonical_build_cache_install,
    .canonical_repetition_home_tmp,
    .canonical_artifact,
    .canonical_artifact_identity,
    .canonical_step_status_records,
    .canonical_build_raw_status,
    .repetition_raw_report,
    .canonical_accepted_ll,
    .accepted_ll_proof,
    .repetition_successful_subset,
    .canonical_per_function,
    .canonical_comparisons,
    .canonical_identities,
    .canonical_final_manifests,
    .coverage_build_cache_install,
    .coverage_artifact,
    .coverage_reference,
    .observation_off,
    .observation_on_channels,
    .observation_on_remaining,
    .coverage_per_function,
    .coverage_comparisons,
    .coverage_final_manifests,
    .publication_evidence,
    .durability_terminal,
};

pub const accepted_storage_cap_mib = [_]u64{
    64,  0,   2048, 384, 1024, 1,  1024, 256,  1536,
    256, 16,  768,  855, 64,   1,  64,   2048, 1024,
    7,   512, 192,  512, 570,  64, 96,   256,  16,
};

pub const StorageRetentionClass = enum {
    retained,
    non_retained_namespace,
};

pub const StorageEnforcementPrimitive = enum {
    bounded_process_capture,
    fixed_count_fixed_size_record,
    explicit_file_size_ceiling,
    bounded_cache_install_root,
    aggregate_only_accounting,
    non_retained_namespace,
};

pub const StorageCapPolicy = struct {
    family: StorageFamily,
    source: StorageCapSource = .accepted_protocol_policy,
    retention: StorageRetentionClass = .retained,
    enforcement: StorageEnforcementPrimitive,
    aggregate_exclusions: u32 = 0,
};

pub const accepted_storage_policy = [_]StorageCapPolicy{
    .{ .family = .external_preflight_driver_records, .enforcement = .bounded_process_capture },
    .{ .family = .namespace_parents, .retention = .non_retained_namespace, .enforcement = .non_retained_namespace },
    .{
        .family = .canonical_build_cache_install,
        .enforcement = .bounded_cache_install_root,
        .aggregate_exclusions = storageFamilyBit(.canonical_artifact),
    },
    .{ .family = .canonical_repetition_home_tmp, .enforcement = .bounded_cache_install_root },
    .{ .family = .canonical_artifact, .enforcement = .explicit_file_size_ceiling },
    .{ .family = .canonical_artifact_identity, .enforcement = .fixed_count_fixed_size_record },
    .{ .family = .canonical_step_status_records, .enforcement = .fixed_count_fixed_size_record },
    .{ .family = .canonical_build_raw_status, .enforcement = .bounded_process_capture },
    .{ .family = .repetition_raw_report, .enforcement = .aggregate_only_accounting },
    .{ .family = .canonical_accepted_ll, .enforcement = .explicit_file_size_ceiling },
    .{ .family = .accepted_ll_proof, .enforcement = .fixed_count_fixed_size_record },
    .{
        .family = .repetition_successful_subset,
        .enforcement = .aggregate_only_accounting,
        .aggregate_exclusions = storageFamilyBit(.canonical_per_function) |
            storageFamilyBit(.canonical_comparisons) |
            storageFamilyBit(.canonical_final_manifests),
    },
    .{ .family = .canonical_per_function, .enforcement = .fixed_count_fixed_size_record },
    .{ .family = .canonical_comparisons, .enforcement = .fixed_count_fixed_size_record },
    .{ .family = .canonical_identities, .enforcement = .fixed_count_fixed_size_record },
    .{ .family = .canonical_final_manifests, .enforcement = .fixed_count_fixed_size_record },
    .{
        .family = .coverage_build_cache_install,
        .enforcement = .bounded_cache_install_root,
        .aggregate_exclusions = storageFamilyBit(.coverage_artifact),
    },
    .{ .family = .coverage_artifact, .enforcement = .aggregate_only_accounting },
    .{ .family = .coverage_reference, .enforcement = .fixed_count_fixed_size_record },
    .{
        .family = .observation_off,
        .enforcement = .aggregate_only_accounting,
        .aggregate_exclusions = storageFamilyBit(.coverage_per_function) |
            storageFamilyBit(.coverage_comparisons) |
            storageFamilyBit(.coverage_final_manifests),
    },
    .{ .family = .observation_on_channels, .enforcement = .fixed_count_fixed_size_record },
    .{
        .family = .observation_on_remaining,
        .enforcement = .aggregate_only_accounting,
        .aggregate_exclusions = storageFamilyBit(.observation_on_channels) |
            storageFamilyBit(.coverage_per_function) |
            storageFamilyBit(.coverage_comparisons) |
            storageFamilyBit(.coverage_final_manifests),
    },
    .{ .family = .coverage_per_function, .enforcement = .fixed_count_fixed_size_record },
    .{ .family = .coverage_comparisons, .enforcement = .fixed_count_fixed_size_record },
    .{ .family = .coverage_final_manifests, .enforcement = .fixed_count_fixed_size_record },
    .{
        .family = .publication_evidence,
        .enforcement = .aggregate_only_accounting,
        .aggregate_exclusions = storageFamilyBit(.durability_terminal),
    },
    .{ .family = .durability_terminal, .enforcement = .fixed_count_fixed_size_record },
};

pub const StorageBudgetEntry = struct {
    family_id: u8,
    retained_bytes_maximum: u64,
    success_retained_bytes: u64,
    failure_retained_bytes: u64,
};

pub const StorageBudgetTotals = struct {
    success_retained_bytes: u64,
    failure_retained_bytes: u64,
    worst_case_retained_bytes: u64,
    available_bytes: u64,
};

pub const StorageCapSource = enum {
    accepted_protocol_policy,
    family_cap_ledger,
    minimum_headroom_policy,
};

pub const StorageBudgetAssessment = union(enum) {
    first_missing: StorageFamily,
    complete_unapproved: StorageBudgetTotals,
};

pub const StorageBudgetLedger = struct {
    entries: []const StorageBudgetEntry,
    cap_source: StorageCapSource,

    pub fn assess(self: StorageBudgetLedger, available_bytes: u64) ContractError!StorageBudgetAssessment {
        if (self.cap_source == .minimum_headroom_policy)
            return error.MinimumHeadroomSubstitution;

        var seen = [_]bool{false} ** storage_families.len;
        for (self.entries) |entry| {
            _ = storageFamilyFromId(entry.family_id) orelse
                return error.UnknownStorageFamily;
            const index: usize = @intCast(entry.family_id - 1);
            if (seen[index]) return error.DuplicateStorageFamily;
            seen[index] = true;
        }

        for (storage_families, 0..) |family, index| {
            if (!seen[index]) return .{ .first_missing = family };
        }

        var success_total: u64 = 0;
        var failure_total: u64 = 0;
        for (self.entries) |entry| {
            const family = storageFamilyFromId(entry.family_id).?;
            if (storageFamilyRequiresBytes(family) and entry.retained_bytes_maximum == 0)
                return error.RequiredStorageMaximumZero;
            if (entry.retained_bytes_maximum !=
                @max(entry.success_retained_bytes, entry.failure_retained_bytes))
            {
                return error.StorageMaximumMismatch;
            }
            success_total = std.math.add(
                u64,
                success_total,
                entry.success_retained_bytes,
            ) catch return error.StorageBudgetOverflow;
            failure_total = std.math.add(
                u64,
                failure_total,
                entry.failure_retained_bytes,
            ) catch return error.StorageBudgetOverflow;
        }

        try requireMinimumCapacity(available_bytes);
        const worst_case = @max(success_total, failure_total);
        if (available_bytes < worst_case) return error.InsufficientAvailableStorage;
        return .{ .complete_unapproved = .{
            .success_retained_bytes = success_total,
            .failure_retained_bytes = failure_total,
            .worst_case_retained_bytes = worst_case,
            .available_bytes = available_bytes,
        } };
    }

    pub fn validateComplete(
        self: StorageBudgetLedger,
        available_bytes: u64,
    ) ContractError!StorageBudgetTotals {
        return switch (try self.assess(available_bytes)) {
            .first_missing => error.MissingStorageFamily,
            .complete_unapproved => |totals| totals,
        };
    }
};

fn storageFamilyFromId(id: u8) ?StorageFamily {
    return switch (id) {
        1 => .external_preflight_driver_records,
        2 => .namespace_parents,
        3 => .canonical_build_cache_install,
        4 => .canonical_repetition_home_tmp,
        5 => .canonical_artifact,
        6 => .canonical_artifact_identity,
        7 => .canonical_step_status_records,
        8 => .canonical_build_raw_status,
        9 => .repetition_raw_report,
        10 => .canonical_accepted_ll,
        11 => .accepted_ll_proof,
        12 => .repetition_successful_subset,
        13 => .canonical_per_function,
        14 => .canonical_comparisons,
        15 => .canonical_identities,
        16 => .canonical_final_manifests,
        17 => .coverage_build_cache_install,
        18 => .coverage_artifact,
        19 => .coverage_reference,
        20 => .observation_off,
        21 => .observation_on_channels,
        22 => .observation_on_remaining,
        23 => .coverage_per_function,
        24 => .coverage_comparisons,
        25 => .coverage_final_manifests,
        26 => .publication_evidence,
        27 => .durability_terminal,
        else => null,
    };
}

fn storageFamilyRequiresBytes(family: StorageFamily) bool {
    return family != .namespace_parents;
}

fn storageFamilyBit(family: StorageFamily) u32 {
    const shift: u5 = @intCast(@intFromEnum(family) - 1);
    return @as(u32, 1) << shift;
}

fn expectedAggregateExclusions(family: StorageFamily) u32 {
    return switch (family) {
        .canonical_build_cache_install => storageFamilyBit(.canonical_artifact),
        .repetition_successful_subset => storageFamilyBit(.canonical_per_function) |
            storageFamilyBit(.canonical_comparisons) |
            storageFamilyBit(.canonical_final_manifests),
        .coverage_build_cache_install => storageFamilyBit(.coverage_artifact),
        .observation_off => storageFamilyBit(.coverage_per_function) |
            storageFamilyBit(.coverage_comparisons) |
            storageFamilyBit(.coverage_final_manifests),
        .observation_on_remaining => storageFamilyBit(.observation_on_channels) |
            storageFamilyBit(.coverage_per_function) |
            storageFamilyBit(.coverage_comparisons) |
            storageFamilyBit(.coverage_final_manifests),
        .publication_evidence => storageFamilyBit(.durability_terminal),
        else => 0,
    };
}

pub fn validateAcceptedStoragePolicy() ContractError!void {
    if (accepted_storage_policy.len != storage_families.len or
        accepted_storage_cap_mib.len != storage_families.len)
    {
        return error.StoragePolicyDrift;
    }

    for (
        accepted_storage_policy,
        storage_families,
        accepted_storage_cap_mib,
    ) |policy, family, cap_mib| {
        if (policy.family != family or policy.source != .accepted_protocol_policy)
            return error.StoragePolicyDrift;
        if (family == .namespace_parents) {
            if (cap_mib != 0 or
                policy.retention != .non_retained_namespace or
                policy.enforcement != .non_retained_namespace)
            {
                return error.StoragePolicyDrift;
            }
        } else if (cap_mib == 0) {
            return error.RequiredStorageMaximumZero;
        } else if (policy.retention != .retained or
            policy.enforcement == .non_retained_namespace)
        {
            return error.StoragePolicyDrift;
        }
        if (policy.aggregate_exclusions != expectedAggregateExclusions(family))
            return error.AggregateExclusionMismatch;
    }
}

pub fn storageMibToBytes(mib: u64) ContractError!u64 {
    return std.math.mul(u64, mib, mebibyte_bytes) catch
        return error.StorageBudgetOverflow;
}

pub fn acceptedStorageBudgetEntries() ContractError![storage_families.len]StorageBudgetEntry {
    try validateAcceptedStoragePolicy();
    var entries: [storage_families.len]StorageBudgetEntry = undefined;
    for (&entries, accepted_storage_policy, accepted_storage_cap_mib) |*entry, policy, cap_mib| {
        const cap_bytes = try storageMibToBytes(cap_mib);
        entry.* = .{
            .family_id = @intFromEnum(policy.family),
            .retained_bytes_maximum = cap_bytes,
            .success_retained_bytes = cap_bytes,
            .failure_retained_bytes = cap_bytes,
        };
    }
    return entries;
}

pub fn acceptedStorageBudgetTotals(available_bytes: u64) ContractError!StorageBudgetTotals {
    const entries = try acceptedStorageBudgetEntries();
    const ledger = StorageBudgetLedger{
        .entries = &entries,
        .cap_source = .accepted_protocol_policy,
    };
    const totals = try ledger.validateComplete(available_bytes);
    if (totals.success_retained_bytes != accepted_maximum_storage_bytes or
        totals.failure_retained_bytes != accepted_maximum_storage_bytes or
        totals.worst_case_retained_bytes != accepted_maximum_storage_bytes)
    {
        return error.StorageMaximumMismatch;
    }
    return totals;
}

pub fn acceptedStorageReserve() ContractError!u64 {
    return std.math.sub(
        u64,
        minimum_available_bytes,
        accepted_maximum_storage_bytes,
    ) catch return error.StorageReserveUnderflow;
}

pub fn acceptedEnforcedStorageFamilies() ContractError![storage_families.len]EnforcedStorageFamily {
    try validateAcceptedStoragePolicy();
    var enforced: [storage_families.len]EnforcedStorageFamily = undefined;
    for (
        &enforced,
        accepted_storage_policy,
        accepted_storage_cap_mib,
    ) |*row, policy, cap_mib| {
        row.* = .{
            .family = policy.family,
            .maximum_bytes = try storageMibToBytes(cap_mib),
            .retention = policy.retention,
            .enforcement = policy.enforcement,
            .aggregate_exclusions = policy.aggregate_exclusions,
        };
    }
    return enforced;
}

pub fn validateCompleteEnforcementEvidence(
    evidence: CompleteEnforcementEvidence,
) ContractError!void {
    try requireMinimumCapacity(evidence.available_bytes);
    _ = try acceptedStorageBudgetTotals(evidence.available_bytes);

    if (!std.mem.eql(
        EnforcementPrerequisite,
        &required_enforcement_prerequisites,
        evidence.prerequisites,
    )) return error.EnforcementEvidenceIncomplete;

    const expected_families = try acceptedEnforcedStorageFamilies();
    if (evidence.storage_families.len != expected_families.len)
        return error.EnforcementEvidenceIncomplete;
    for (expected_families, evidence.storage_families) |expected, actual| {
        if (!std.meta.eql(expected, actual)) return error.EnforcementEvidenceIncomplete;
    }

    if (evidence.identity_count != closed_identities.len or
        evidence.compatibility_key_count != compatibility_keys.len or
        evidence.v3_path_count != @typeInfo(V3Path).@"enum".fields.len or
        evidence.repetition_count != canonical_repetition_count or
        evidence.successful_functions != successful_function_count or
        evidence.phase_count != @typeInfo(Phase).@"enum".fields.len or
        evidence.stdout_capture_bytes != accepted_process_capture_bytes or
        evidence.stderr_capture_bytes != accepted_process_capture_bytes)
    {
        return error.EnforcementEvidenceIncomplete;
    }
}

pub fn executionReadinessWithEvidence(
    evidence: CompleteEnforcementEvidence,
) ContractError!ExecutionReadiness {
    if (evidence.available_bytes < minimum_available_bytes)
        return .not_ready_insufficient_capacity;
    validateCompleteEnforcementEvidence(evidence) catch |failure| switch (failure) {
        error.EnforcementEvidenceIncomplete => return .not_ready_storage_enforcement_absent,
        error.InsufficientCapacity => return .not_ready_insufficient_capacity,
        else => return failure,
    };
    return .ready;
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

fn testStorageBudgetEntries() [storage_families.len]StorageBudgetEntry {
    var entries: [storage_families.len]StorageBudgetEntry = undefined;
    for (&entries, storage_families, 0..) |*entry, family, index| {
        const success_bytes: u64 = @intCast(index + 1);
        const failure_bytes = success_bytes + 1;
        entry.* = .{
            .family_id = @intFromEnum(family),
            .retained_bytes_maximum = failure_bytes,
            .success_retained_bytes = success_bytes,
            .failure_retained_bytes = failure_bytes,
        };
    }
    return entries;
}

fn testStorageBudgetLedger(entries: []const StorageBudgetEntry) StorageBudgetLedger {
    return .{
        .entries = entries,
        .cap_source = .family_cap_ledger,
    };
}

test "baseline validation storage budget accepts complete synthetic structure as unapproved" {
    var entries = testStorageBudgetEntries();
    const ledger = testStorageBudgetLedger(&entries);

    const assessment = try ledger.assess(minimum_available_bytes);
    const totals = switch (assessment) {
        .first_missing => return error.TestUnexpectedResult,
        .complete_unapproved => |value| value,
    };
    var expected_success: u64 = 0;
    var expected_failure: u64 = 0;
    for (entries) |entry| {
        expected_success += entry.success_retained_bytes;
        expected_failure += entry.failure_retained_bytes;
    }
    try std.testing.expectEqual(expected_success, totals.success_retained_bytes);
    try std.testing.expectEqual(expected_failure, totals.failure_retained_bytes);
    try std.testing.expectEqual(expected_failure, totals.worst_case_retained_bytes);
    try std.testing.expectEqual(minimum_available_bytes, totals.available_bytes);
    try std.testing.expectEqual(totals, try ledger.validateComplete(minimum_available_bytes));

    entries[0].retained_bytes_maximum = 0;
    entries[0].success_retained_bytes = 0;
    entries[0].failure_retained_bytes = 0;
    try std.testing.expectError(
        error.RequiredStorageMaximumZero,
        testStorageBudgetLedger(&entries).assess(minimum_available_bytes),
    );

    entries = testStorageBudgetEntries();
    entries[0].retained_bytes_maximum += 1;
    try std.testing.expectError(
        error.StorageMaximumMismatch,
        testStorageBudgetLedger(&entries).assess(minimum_available_bytes),
    );
}

test "baseline validation storage budget reports family one as first missing" {
    const entries = testStorageBudgetEntries();
    const ledger = testStorageBudgetLedger(entries[1..]);

    switch (try ledger.assess(minimum_available_bytes)) {
        .first_missing => |family| try std.testing.expectEqual(
            StorageFamily.external_preflight_driver_records,
            family,
        ),
        .complete_unapproved => return error.TestUnexpectedResult,
    }
    try std.testing.expectError(
        error.MissingStorageFamily,
        ledger.validateComplete(minimum_available_bytes),
    );
}

test "baseline validation storage budget rejects duplicate and unknown families" {
    var duplicate_entries = testStorageBudgetEntries();
    duplicate_entries[duplicate_entries.len - 1].family_id = duplicate_entries[0].family_id;
    try std.testing.expectError(
        error.DuplicateStorageFamily,
        testStorageBudgetLedger(&duplicate_entries).assess(minimum_available_bytes),
    );

    var unknown_entries = testStorageBudgetEntries();
    unknown_entries[0].family_id = 0;
    try std.testing.expectError(
        error.UnknownStorageFamily,
        testStorageBudgetLedger(&unknown_entries).assess(minimum_available_bytes),
    );
}

test "baseline validation storage budget rejects checked overflow" {
    var entries = testStorageBudgetEntries();
    entries[0].retained_bytes_maximum = std.math.maxInt(u64);
    entries[0].success_retained_bytes = std.math.maxInt(u64);
    entries[0].failure_retained_bytes = std.math.maxInt(u64);
    entries[1].retained_bytes_maximum = 1;
    entries[1].success_retained_bytes = 1;
    entries[1].failure_retained_bytes = 1;

    try std.testing.expectError(
        error.StorageBudgetOverflow,
        testStorageBudgetLedger(&entries).assess(std.math.maxInt(u64)),
    );
}

test "baseline validation storage budget includes failure retention" {
    var entries = testStorageBudgetEntries();
    for (&entries) |*entry| {
        entry.retained_bytes_maximum = 1;
        entry.success_retained_bytes = 1;
        entry.failure_retained_bytes = 1;
    }
    entries[0].failure_retained_bytes = minimum_available_bytes + 100;
    entries[0].retained_bytes_maximum = entries[0].failure_retained_bytes;
    const expected_failure = minimum_available_bytes + 100 + entries.len - 1;
    const ledger = testStorageBudgetLedger(&entries);

    const totals = try ledger.validateComplete(expected_failure);
    try std.testing.expectEqual(@as(u64, entries.len), totals.success_retained_bytes);
    try std.testing.expectEqual(expected_failure, totals.failure_retained_bytes);
    try std.testing.expectEqual(expected_failure, totals.worst_case_retained_bytes);
    try std.testing.expectError(
        error.InsufficientAvailableStorage,
        ledger.validateComplete(expected_failure - 1),
    );
}

test "baseline validation storage budget rejects minimum headroom substitution" {
    const entries = testStorageBudgetEntries();
    const ledger = StorageBudgetLedger{
        .entries = &entries,
        .cap_source = .minimum_headroom_policy,
    };

    try std.testing.expectError(
        error.MinimumHeadroomSubstitution,
        ledger.assess(minimum_available_bytes),
    );
}

test "baseline validation accepted storage cap order vector and zero classification" {
    const expected = [_]u64{
        64,  0,   2048, 384, 1024, 1,  1024, 256,  1536,
        256, 16,  768,  855, 64,   1,  64,   2048, 1024,
        7,   512, 192,  512, 570,  64, 96,   256,  16,
    };
    try std.testing.expectEqualSlices(u64, &expected, &accepted_storage_cap_mib);
    try validateAcceptedStoragePolicy();

    for (
        accepted_storage_policy,
        storage_families,
        accepted_storage_cap_mib,
        0..,
    ) |policy, family, cap_mib, index| {
        try std.testing.expectEqual(family, policy.family);
        try std.testing.expectEqual(StorageCapSource.accepted_protocol_policy, policy.source);
        if (index == 1) {
            try std.testing.expectEqual(@as(u64, 0), cap_mib);
            try std.testing.expectEqual(StorageFamily.namespace_parents, family);
            try std.testing.expectEqual(
                StorageRetentionClass.non_retained_namespace,
                policy.retention,
            );
            try std.testing.expectEqual(
                StorageEnforcementPrimitive.non_retained_namespace,
                policy.enforcement,
            );
        } else {
            try std.testing.expect(cap_mib != 0);
            try std.testing.expectEqual(StorageRetentionClass.retained, policy.retention);
        }
    }
}

test "baseline validation accepted storage budget uses checked exact totals" {
    try std.testing.expectEqual(mebibyte_bytes, try storageMibToBytes(1));
    try std.testing.expectError(
        error.StorageBudgetOverflow,
        storageMibToBytes(std.math.maxInt(u64)),
    );

    const entries = try acceptedStorageBudgetEntries();
    const ledger = StorageBudgetLedger{
        .entries = &entries,
        .cap_source = .accepted_protocol_policy,
    };
    const ledger_totals = try ledger.validateComplete(minimum_available_bytes);
    const accepted_totals = try acceptedStorageBudgetTotals(minimum_available_bytes);
    try std.testing.expectEqual(accepted_maximum_storage_bytes, ledger_totals.success_retained_bytes);
    try std.testing.expectEqual(accepted_maximum_storage_bytes, ledger_totals.failure_retained_bytes);
    try std.testing.expectEqual(accepted_maximum_storage_bytes, ledger_totals.worst_case_retained_bytes);
    try std.testing.expectEqual(ledger_totals, accepted_totals);
    try std.testing.expectEqual(accepted_storage_reserve_bytes, try acceptedStorageReserve());
    try std.testing.expectEqual(
        minimum_available_bytes,
        try std.math.add(u64, accepted_maximum_storage_bytes, accepted_storage_reserve_bytes),
    );
}

test "baseline validation accepted storage aggregates exclude separately counted families" {
    try std.testing.expectEqual(
        storageFamilyBit(.canonical_artifact),
        accepted_storage_policy[@intFromEnum(StorageFamily.canonical_build_cache_install) - 1].aggregate_exclusions,
    );
    try std.testing.expectEqual(
        storageFamilyBit(.canonical_per_function) |
            storageFamilyBit(.canonical_comparisons) |
            storageFamilyBit(.canonical_final_manifests),
        accepted_storage_policy[@intFromEnum(StorageFamily.repetition_successful_subset) - 1].aggregate_exclusions,
    );
    try std.testing.expectEqual(
        storageFamilyBit(.coverage_artifact),
        accepted_storage_policy[@intFromEnum(StorageFamily.coverage_build_cache_install) - 1].aggregate_exclusions,
    );
    try std.testing.expectEqual(
        storageFamilyBit(.coverage_per_function) |
            storageFamilyBit(.coverage_comparisons) |
            storageFamilyBit(.coverage_final_manifests),
        accepted_storage_policy[@intFromEnum(StorageFamily.observation_off) - 1].aggregate_exclusions,
    );
    try std.testing.expectEqual(
        storageFamilyBit(.observation_on_channels) |
            storageFamilyBit(.coverage_per_function) |
            storageFamilyBit(.coverage_comparisons) |
            storageFamilyBit(.coverage_final_manifests),
        accepted_storage_policy[@intFromEnum(StorageFamily.observation_on_remaining) - 1].aggregate_exclusions,
    );
    try std.testing.expectEqual(
        storageFamilyBit(.durability_terminal),
        accepted_storage_policy[@intFromEnum(StorageFamily.publication_evidence) - 1].aggregate_exclusions,
    );

    var cap_total_mib: u64 = 0;
    for (accepted_storage_cap_mib) |cap_mib| {
        cap_total_mib = try std.math.add(u64, cap_total_mib, cap_mib);
    }
    try std.testing.expectEqual(@as(u64, 13_658), cap_total_mib);
    try std.testing.expectEqual(
        accepted_maximum_storage_bytes,
        try storageMibToBytes(cap_total_mib),
    );
}

test "baseline validation accepted caps do not imply storage enforcement readiness" {
    try std.testing.expectError(
        error.InsufficientCapacity,
        acceptedStorageBudgetTotals(minimum_available_bytes - 1),
    );
    try std.testing.expectEqual(
        ExecutionReadiness.not_ready_insufficient_capacity,
        executionReadiness(minimum_available_bytes - 1),
    );
    try std.testing.expectEqual(
        ExecutionReadiness.not_ready_storage_enforcement_absent,
        executionReadiness(minimum_available_bytes),
    );
    try std.testing.expect(accepted_maximum_storage_bytes < minimum_available_bytes);
}

test "baseline validation complete typed enforcement evidence alone admits readiness" {
    const families = try acceptedEnforcedStorageFamilies();
    const evidence = CompleteEnforcementEvidence{
        .prerequisites = &required_enforcement_prerequisites,
        .storage_families = &families,
        .available_bytes = minimum_available_bytes,
        .identity_count = closed_identities.len,
        .compatibility_key_count = compatibility_keys.len,
        .v3_path_count = @typeInfo(V3Path).@"enum".fields.len,
        .repetition_count = canonical_repetition_count,
        .successful_functions = successful_function_count,
        .phase_count = @typeInfo(Phase).@"enum".fields.len,
        .stdout_capture_bytes = accepted_process_capture_bytes,
        .stderr_capture_bytes = accepted_process_capture_bytes,
    };
    try validateCompleteEnforcementEvidence(evidence);
    try std.testing.expectEqual(
        ExecutionReadiness.ready,
        try executionReadinessWithEvidence(evidence),
    );
}

test "baseline validation typed enforcement evidence rejects omission drift and capacity" {
    var families = try acceptedEnforcedStorageFamilies();
    var evidence = CompleteEnforcementEvidence{
        .prerequisites = &required_enforcement_prerequisites,
        .storage_families = &families,
        .available_bytes = minimum_available_bytes,
        .identity_count = closed_identities.len,
        .compatibility_key_count = compatibility_keys.len,
        .v3_path_count = @typeInfo(V3Path).@"enum".fields.len,
        .repetition_count = canonical_repetition_count,
        .successful_functions = successful_function_count,
        .phase_count = @typeInfo(Phase).@"enum".fields.len,
        .stdout_capture_bytes = accepted_process_capture_bytes,
        .stderr_capture_bytes = accepted_process_capture_bytes,
    };

    evidence.prerequisites = required_enforcement_prerequisites[1..];
    try std.testing.expectError(
        error.EnforcementEvidenceIncomplete,
        validateCompleteEnforcementEvidence(evidence),
    );
    evidence.prerequisites = &required_enforcement_prerequisites;
    families[0].maximum_bytes -= 1;
    try std.testing.expectError(
        error.EnforcementEvidenceIncomplete,
        validateCompleteEnforcementEvidence(evidence),
    );
    families = try acceptedEnforcedStorageFamilies();
    evidence.available_bytes = minimum_available_bytes - 1;
    try std.testing.expectEqual(
        ExecutionReadiness.not_ready_insufficient_capacity,
        try executionReadinessWithEvidence(evidence),
    );
    evidence.available_bytes = minimum_available_bytes;
    evidence.phase_count -= 1;
    try std.testing.expectEqual(
        ExecutionReadiness.not_ready_storage_enforcement_absent,
        try executionReadinessWithEvidence(evidence),
    );
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
        ExecutionReadiness.not_ready_storage_enforcement_absent,
        executionReadiness(minimum_available_bytes),
    );
    try std.testing.expectEqual(@as(u64, 14_321_451_008), accepted_maximum_storage_bytes);
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
