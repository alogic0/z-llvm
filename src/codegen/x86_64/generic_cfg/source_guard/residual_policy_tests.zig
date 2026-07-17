const support = @import("test_support.zig");

const std = support.std;
const source_dir = support.source_dir;
const source_prefix = support.source_prefix;
const source_suffix = support.source_suffix;
const SourceKind = support.SourceKind;
const ClassifiedSource = support.ClassifiedSource;
const classified_sources = support.classified_sources;
const value_use_leaf_paths = support.value_use_leaf_paths;
const value_use_model_pub_names = support.value_use_model_pub_names;
const value_use_core_pub_names = support.value_use_core_pub_names;
const value_use_planning_pub_names = support.value_use_planning_pub_names;
const value_use_materialization_pub_names = support.value_use_materialization_pub_names;
const value_use_composition_pub_names = support.value_use_composition_pub_names;
const value_use_address_pub_names = support.value_use_address_pub_names;
const value_use_control_pub_names = support.value_use_control_pub_names;
const value_use_calls_pub_names = support.value_use_calls_pub_names;
const frozen_bypass_inventory_path = support.frozen_bypass_inventory_path;
const frozen_bypass_inventory_sha256 = support.frozen_bypass_inventory_sha256;
const value_use_facade_manifest_path = support.value_use_facade_manifest_path;
const value_use_facade_manifest_sha256 = support.value_use_facade_manifest_sha256;
const bypass_operations = support.bypass_operations;
const DirectOperation = support.DirectOperation;
const ResidualClassification = support.ResidualClassification;
const FutureArchitecturalSlice = support.FutureArchitecturalSlice;
const ResidualAllowlistEntry = support.ResidualAllowlistEntry;
const residual_accumulator_allowlist = support.residual_accumulator_allowlist;
const ExclusionOperation = support.ExclusionOperation;
const ExclusionAllowlistEntry = support.ExclusionAllowlistEntry;
const architectural_exclusion_allowlist = support.architectural_exclusion_allowlist;
const FunctionFingerprint = support.FunctionFingerprint;
const residual_function_fingerprints = support.residual_function_fingerprints;
const FunctionBody = support.FunctionBody;
const max_function_bodies = support.max_function_bodies;
const readFrozenBypassInventory = support.readFrozenBypassInventory;
const validateNoPublicPreparedPointer = support.validateNoPublicPreparedPointer;
const validateNoFunctionFamilyPredicate = support.validateNoFunctionFamilyPredicate;
const ParsedBypassSite = support.ParsedBypassSite;
const parseFrozenBypassSite = support.parseFrozenBypassSite;
const frozenBypassExpectedCount = support.frozenBypassExpectedCount;
const isBypassOperation = support.isBypassOperation;
const countPattern = support.countPattern;
const validateEflagsEmissionAuthority = support.validateEflagsEmissionAuthority;
const validateStateDataLifecycle = support.validateStateDataLifecycle;
const validateResidualAccumulatorAllowlist = support.validateResidualAccumulatorAllowlist;
const collectFunctionBodies = support.collectFunctionBodies;
const functionBodyContaining = support.functionBodyContaining;
const functionBodyNamed = support.functionBodyNamed;
const validateFunctionBodyFingerprint = support.validateFunctionBodyFingerprint;
const functionBodyFingerprint = support.functionBodyFingerprint;
const fixtureFunctionFingerprint = support.fixtureFunctionFingerprint;
const validateFunctionFingerprintInventory = support.validateFunctionFingerprintInventory;
const functionHasAllowlistedOperation = support.functionHasAllowlistedOperation;
const functionFingerprint = support.functionFingerprint;
const residualAllowlistIndex = support.residualAllowlistIndex;
const validateArchitecturalExclusionAllowlist = support.validateArchitecturalExclusionAllowlist;
const architecturalExclusionIndex = support.architecturalExclusionIndex;
const validateAccumulatorDisplacementPolicies = support.validateAccumulatorDisplacementPolicies;
const classificationIndex = support.classificationIndex;
const isTestSource = support.isTestSource;
const validateValueUseAuthoritySource = support.validateValueUseAuthoritySource;
const validateValueUseAuthoritySourceWithVisibility = support.validateValueUseAuthoritySourceWithVisibility;
const validateScratchCompareIntentSurface = support.validateScratchCompareIntentSurface;
const validateCurrentHomeEqZeroIntentSurface = support.validateCurrentHomeEqZeroIntentSurface;
const validateSetccEaxCompareIntentSurface = support.validateSetccEaxCompareIntentSurface;
const validateCurrentHomeSignBitIntentSurface = support.validateCurrentHomeSignBitIntentSurface;
const validateI128PairIntentSurface = support.validateI128PairIntentSurface;
const validateScratchComparePreservationPreamble = support.validateScratchComparePreservationPreamble;
const validateCurrentHomeEqZeroSequence = support.validateCurrentHomeEqZeroSequence;
const validateSetccEaxCompareSequence = support.validateSetccEaxCompareSequence;
const validateCurrentHomeSignBitSequence = support.validateCurrentHomeSignBitSequence;
const validateI128PairSequence = support.validateI128PairSequence;
const validateDurableActionIdentityOwnership = support.validateDurableActionIdentityOwnership;
const validatePreparedViewLeafDiscipline = support.validatePreparedViewLeafDiscipline;
const validateScratchCompareProductionSites = support.validateScratchCompareProductionSites;
const validateCurrentHomeEqZeroProductionSites = support.validateCurrentHomeEqZeroProductionSites;
const validateSetccEaxCompareProductionSites = support.validateSetccEaxCompareProductionSites;
const validateCurrentHomeSignBitProductionSites = support.validateCurrentHomeSignBitProductionSites;
const validateI128PairProductionSites = support.validateI128PairProductionSites;
const validateLoadDiagnosticMappingProductionSites = support.validateLoadDiagnosticMappingProductionSites;
const validateDormantLoadActionProductionSites = support.validateDormantLoadActionProductionSites;
const validateAccumulatorCompositionProductionSites = support.validateAccumulatorCompositionProductionSites;
const validateFailureProvenanceProductionSites = support.validateFailureProvenanceProductionSites;
const validateMemcpyActionProductionSites = support.validateMemcpyActionProductionSites;
const validateSwitchActionProductionSites = support.validateSwitchActionProductionSites;
const validateBranchActionProductionSites = support.validateBranchActionProductionSites;
const validateStoreActionProductionSites = support.validateStoreActionProductionSites;
const validateValueUseFacadeSource = support.validateValueUseFacadeSource;
const validateSplitValueUseTree = support.validateSplitValueUseTree;
const appendNormalizedValueUseSource = support.appendNormalizedValueUseSource;
const validateValueUseLeaf = support.validateValueUseLeaf;
const validateValueUseFacadeSurfaceManifest = support.validateValueUseFacadeSurfaceManifest;
const validateValueUseDirectForwardingWrappers = support.validateValueUseDirectForwardingWrappers;
const validateExactTopLevelPubNames = support.validateExactTopLevelPubNames;
const validateCurrentTree = support.validateCurrentTree;
const validateProductionSource = support.validateProductionSource;
const validateAddressDependencyStateAuthority = support.validateAddressDependencyStateAuthority;
const validateAddressDependencyDomainSource = support.validateAddressDependencyDomainSource;
const validateFrozenBypassInventoryHash = support.validateFrozenBypassInventoryHash;
const validateFrozenBypassInventoryForSource = support.validateFrozenBypassInventoryForSource;

test "composed selector source guard rejects all raw map methods outside the authority" {
    const fixtures = [_][:0]const u8{
        "fn bad(selector: anytype) void { _ = selector.values.get(\"x\"); }",
        "fn bad(selector: anytype) void { var it = selector.values.iterator(); _ = &it; }",
        "fn bad(selector: anytype) void { selector.values.put(\"x\", undefined) catch unreachable; }",
        "fn bad(selector: anytype) void { _ = selector.values.remove(\"x\"); }",
    };
    for (fixtures) |fixture| {
        try std.testing.expectError(
            error.RawSelectorValuesAccess,
            validateProductionSource("composed_selector_scalar.zig", fixture),
        );
    }
}
test "composed selector source guard rejects an unclassified production file" {
    try std.testing.expectError(
        error.UnclassifiedComposedSelectorSource,
        validateProductionSource("composed_selector_new_route.zig", "const std = @import(\"std\");"),
    );
}
test "composed selector source guard narrowly permits only state-data lifecycle access" {
    const lifecycle =
        \\    .values = std.StringHashMap(ValueBinding).init(allocator),
        \\    selector.values.deinit();
    ;
    try validateProductionSource("composed_selector_state_data.zig", lifecycle);
    try std.testing.expectError(
        error.UnapprovedStateDataValuesAccess,
        validateProductionSource(
            "composed_selector_state_data.zig",
            lifecycle ++ "    _ = selector.values.get(\"x\");\n",
        ),
    );
}
test "composed selector source guard rejects residual accumulator additions" {
    const source_name = "composed_selector_fixture.zig";
    const accepted_source = "fn keep() void { selector_state.clobberAccumulator(undefined); }";
    const allowlist = [_]ResidualAllowlistEntry{.{
        .source = source_name,
        .function = "keep",
        .operation = .clobber_accumulator,
        .structural_role = "fixture temporary",
        .classification = .internal_temporary,
        .future_slice = .none,
        .expected_count = 1,
    }};
    var fingerprint_storage: [std.crypto.hash.sha2.Sha256.digest_length * 2]u8 = undefined;
    const fingerprints = [_]FunctionFingerprint{try fixtureFunctionFingerprint(
        source_name,
        "keep",
        accepted_source,
        &fingerprint_storage,
    )};
    try validateResidualAccumulatorAllowlist(
        &allowlist,
        &fingerprints,
        source_name,
        accepted_source,
    );
    try std.testing.expectError(
        error.ResidualAccumulatorOccurrenceMismatch,
        validateResidualAccumulatorAllowlist(
            &allowlist,
            &fingerprints,
            source_name,
            "fn keep() void { selector_state.clobberAccumulator(undefined); selector_state.clobberAccumulator(undefined); }",
        ),
    );
}
test "composed selector source guard rejects residual accumulator removal" {
    const source_name = "composed_selector_fixture.zig";
    const accepted_source = "fn keep() void { selector_state.clobberAccumulator(undefined); }";
    const allowlist = [_]ResidualAllowlistEntry{.{
        .source = source_name,
        .function = "keep",
        .operation = .clobber_accumulator,
        .structural_role = "fixture temporary",
        .classification = .internal_temporary,
        .future_slice = .none,
        .expected_count = 1,
    }};
    var fingerprint_storage: [std.crypto.hash.sha2.Sha256.digest_length * 2]u8 = undefined;
    const fingerprints = [_]FunctionFingerprint{try fixtureFunctionFingerprint(
        source_name,
        "keep",
        accepted_source,
        &fingerprint_storage,
    )};
    try std.testing.expectError(
        error.ResidualAccumulatorOccurrenceMismatch,
        validateResidualAccumulatorAllowlist(
            &allowlist,
            &fingerprints,
            source_name,
            "fn keep() void {}",
        ),
    );
}
test "composed selector source guard rejects cross-function residual accumulator relocation" {
    const source_name = "composed_selector_fixture.zig";
    const accepted_source = "fn keep() void { selector_state.bindValueLoc(undefined, \"x\", undefined); }";
    const allowlist = [_]ResidualAllowlistEntry{.{
        .source = source_name,
        .function = "keep",
        .operation = .bind_value_loc,
        .structural_role = "fixture alias",
        .classification = .alias_only_binding,
        .future_slice = .none,
        .expected_count = 1,
    }};
    var fingerprint_storage: [std.crypto.hash.sha2.Sha256.digest_length * 2]u8 = undefined;
    const fingerprints = [_]FunctionFingerprint{try fixtureFunctionFingerprint(
        source_name,
        "keep",
        accepted_source,
        &fingerprint_storage,
    )};
    try std.testing.expectError(
        error.UnallowlistedResidualAccumulatorOperation,
        validateResidualAccumulatorAllowlist(
            &allowlist,
            &fingerprints,
            source_name,
            "fn moved() void { selector_state.bindValueLoc(undefined, \"x\", undefined); }",
        ),
    );
}
test "composed selector source guard rejects same-function semantic-branch relocation" {
    const source_name = "composed_selector_fixture.zig";
    const accepted_source =
        \\fn keep(condition: bool) void {
        \\    if (condition) {
        \\        selector_state.clobberAccumulator(undefined);
        \\    } else {}
        \\}
    ;
    const relocated_source =
        \\fn keep(condition: bool) void {
        \\    if (condition) {} else {
        \\        selector_state.clobberAccumulator(undefined);
        \\    }
        \\}
    ;
    const allowlist = [_]ResidualAllowlistEntry{.{
        .source = source_name,
        .function = "keep",
        .operation = .clobber_accumulator,
        .structural_role = "condition-true temporary",
        .classification = .internal_temporary,
        .future_slice = .none,
        .expected_count = 1,
    }};
    var fingerprint_storage: [std.crypto.hash.sha2.Sha256.digest_length * 2]u8 = undefined;
    const fingerprints = [_]FunctionFingerprint{try fixtureFunctionFingerprint(
        source_name,
        "keep",
        accepted_source,
        &fingerprint_storage,
    )};
    try validateResidualAccumulatorAllowlist(&allowlist, &fingerprints, source_name, accepted_source);
    try std.testing.expectError(
        error.ResidualFunctionFingerprintMismatch,
        validateResidualAccumulatorAllowlist(&allowlist, &fingerprints, source_name, relocated_source),
    );
}
test "composed selector source guard rejects residual accumulator operation outside closed function body" {
    const source_name = "composed_selector_fixture.zig";
    const accepted_source = "fn keep() void { selector_state.clobberAccumulator(undefined); }";
    const allowlist = [_]ResidualAllowlistEntry{.{
        .source = source_name,
        .function = "keep",
        .operation = .clobber_accumulator,
        .structural_role = "fixture temporary",
        .classification = .internal_temporary,
        .future_slice = .none,
        .expected_count = 1,
    }};
    var fingerprint_storage: [std.crypto.hash.sha2.Sha256.digest_length * 2]u8 = undefined;
    const fingerprints = [_]FunctionFingerprint{try fixtureFunctionFingerprint(
        source_name,
        "keep",
        accepted_source,
        &fingerprint_storage,
    )};
    try std.testing.expectError(
        error.ResidualAccumulatorOperationOutsideFunction,
        validateResidualAccumulatorAllowlist(
            &allowlist,
            &fingerprints,
            source_name,
            "fn keep() void {}\nselector_state.clobberAccumulator(undefined);",
        ),
    );
}
test "composed selector source guard rejects residual accumulator reclassification" {
    const source_name = "composed_selector_fixture.zig";
    const accepted_source = "fn keep() void { selector_state.clobberAccumulator(undefined); }";
    const allowlist = [_]ResidualAllowlistEntry{.{
        .source = source_name,
        .function = "keep",
        .operation = .clobber_accumulator,
        .structural_role = "fixture temporary",
        .classification = .internal_temporary,
        .future_slice = .none,
        .expected_count = 1,
    }};
    var fingerprint_storage: [std.crypto.hash.sha2.Sha256.digest_length * 2]u8 = undefined;
    const fingerprints = [_]FunctionFingerprint{try fixtureFunctionFingerprint(
        source_name,
        "keep",
        accepted_source,
        &fingerprint_storage,
    )};
    try std.testing.expectError(
        error.UnallowlistedResidualAccumulatorOperation,
        validateResidualAccumulatorAllowlist(
            &allowlist,
            &fingerprints,
            source_name,
            "fn keep() void { selector_state.bindEax(undefined, \"x\"); }",
        ),
    );
}
test "composed selector source guard requires future-slice ownership for approved exclusions" {
    const source_name = "composed_selector_fixture.zig";
    const accepted_source = "fn keep() void { selector_state.clobberAccumulator(undefined); }";
    const allowlist = [_]ResidualAllowlistEntry{.{
        .source = source_name,
        .function = "keep",
        .operation = .clobber_accumulator,
        .structural_role = "fixture pair result",
        .classification = .approved_pair_rdx_exclusion,
        .future_slice = .none,
        .expected_count = 1,
    }};
    var fingerprint_storage: [std.crypto.hash.sha2.Sha256.digest_length * 2]u8 = undefined;
    const fingerprints = [_]FunctionFingerprint{try fixtureFunctionFingerprint(
        source_name,
        "keep",
        accepted_source,
        &fingerprint_storage,
    )};
    try std.testing.expectError(
        error.ResidualExclusionMissingFutureSlice,
        validateResidualAccumulatorAllowlist(&allowlist, &fingerprints, source_name, accepted_source),
    );
}
test "composed selector source guard requires an explicit accumulator displacement policy" {
    try std.testing.expectError(
        error.MissingAccumulatorDisplacementPolicy,
        validateAccumulatorDisplacementPolicies("fn lower() void { _ = transaction.prepare(.preserve); }"),
    );
    try validateAccumulatorDisplacementPolicies(
        "_ = transaction.prepare(.preserve, .spill_live);" ++
            "_ = transaction.prepare(.preserve, .scratch_preferred);" ++
            "_ = transaction.prepare(.clobber, accumulatorLocDisplacement(value, source));" ++
            "_ = transaction.prepare(.clobber, accumulatorCastDisplacement(value, source));",
    );
}
test "composed selector source guard requires the EFLAGS emission authority" {
    const raw_sites = [_][]const u8{
        "try selector.machine.instructions.append(selector.allocator, .{ .cmp_eax_imm32 = 0 });",
        "try selector.machine.instructions.append(selector.allocator, .setne_eax);",
        "try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_eax = undefined });",
        "try selector.machine.instructions.append(selector.allocator, .{ .jne = target });",
    };
    for (raw_sites) |site| {
        try std.testing.expectError(
            error.RawEflagsInstructionAppend,
            validateEflagsEmissionAuthority("composed_selector_scalar.zig", site),
        );
    }
    try validateEflagsEmissionAuthority(
        "composed_selector_scalar.zig",
        "try selector_state.emitEflagsInstruction(selector, .{ .cmp_eax_imm32 = 0 }, .definition);",
    );
}
