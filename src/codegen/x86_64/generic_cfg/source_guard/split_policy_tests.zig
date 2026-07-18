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
const value_use_scalar_arithmetic_pub_names = support.value_use_scalar_arithmetic_pub_names;
const value_use_scalar_cast_pub_names = support.value_use_scalar_cast_pub_names;
const value_use_scalar_immediate_pub_names = support.value_use_scalar_immediate_pub_names;
const value_use_scalar_named_pub_names = support.value_use_scalar_named_pub_names;
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
const validateScalarArithmeticFacadeSource = support.validateScalarArithmeticFacadeSource;
const validatePlanningFacadeSource = support.validatePlanningFacadeSource;
const validatePlanningLeafImportDag = support.validatePlanningLeafImportDag;
const validatePlanningInternalOwnership = support.validatePlanningInternalOwnership;
const validateValueUseFacadeSurfaceManifest = support.validateValueUseFacadeSurfaceManifest;
const validateValueUseDirectForwardingWrappers = support.validateValueUseDirectForwardingWrappers;
const validateExactTopLevelPubNames = support.validateExactTopLevelPubNames;
const validateCurrentTree = support.validateCurrentTree;
const validateProductionSource = support.validateProductionSource;
const validateAddressDependencyStateAuthority = support.validateAddressDependencyStateAuthority;
const validateAddressDependencyDomainSource = support.validateAddressDependencyDomainSource;
const validateFrozenBypassInventoryHash = support.validateFrozenBypassInventoryHash;
const validateFrozenBypassInventoryForSource = support.validateFrozenBypassInventoryForSource;

fn replaceOnceSentinel(
    allocator: std.mem.Allocator,
    source: [:0]const u8,
    needle: []const u8,
    replacement: []const u8,
) ![:0]u8 {
    const start = std.mem.indexOf(u8, source, needle) orelse return error.TestNeedleMissing;
    const result_len = source.len - needle.len + replacement.len;
    const result = try allocator.allocSentinel(u8, result_len, 0);
    @memcpy(result[0..start], source[0..start]);
    @memcpy(result[start..][0..replacement.len], replacement);
    @memcpy(result[start + replacement.len ..], source[start + needle.len ..]);
    return result;
}

test "composed selector source guard accepts the fully classified current tree" {
    try validateCurrentTree(std.testing.allocator);
}
test "value-use split guard rejects facade widening and internal production imports" {
    try std.testing.expectError(
        error.ValueUseFacadeManifestMismatch,
        validateValueUseFacadeSource(
            "const core = @import(\"value_use/core.zig\");\n" ++
                "pub const ValueUseTransaction = core.ValueUseTransaction;\n" ++
                "pub const Internal = core.Internal;\n",
        ),
    );
    try std.testing.expectError(
        error.ValueUseProductionInternalImport,
        validateProductionSource(
            "composed_selector_scalar.zig",
            "@import(\"value_use/model.zig\");",
        ),
    );
}
test "value-use split guard rejects runtime dispatch type-name coupling and extra instantiations" {
    try std.testing.expectError(
        error.ValueUseRuntimeDispatchForbidden,
        validateValueUseLeaf(
            "src/codegen/x86_64/generic_cfg/value_use/model.zig",
            "const callback: *const fn () void = undefined;",
        ),
    );
    try std.testing.expectError(
        error.ValueUseTypeNameDependency,
        validateValueUseLeaf(
            "src/codegen/x86_64/generic_cfg/value_use/model.zig",
            "const name = @typeName(usize);",
        ),
    );
    try std.testing.expectError(
        error.ValueUseProductionInstantiationMismatch,
        validateValueUseLeaf(
            "src/codegen/x86_64/generic_cfg/value_use/core.zig",
            "const A = model.Transaction(Implementation); const B = model.Transaction(Implementation);",
        ),
    );
}
test "value-use split guard rejects reverse imports and control-compare budget growth" {
    try std.testing.expectError(
        error.ValueUseImportDagMismatch,
        validateValueUseLeaf(
            "src/codegen/x86_64/generic_cfg/value_use/actions/control_compare.zig",
            "const planning = @import(\"../planning.zig\");",
        ),
    );
    try std.testing.expectError(
        error.ValueUseImportDagMismatch,
        validateValueUseLeaf(
            "src/codegen/x86_64/generic_cfg/value_use/actions/control_compare.zig",
            "fn reverse(comptime Authority: type) void { _ = Authority.planning; }",
        ),
    );
    const oversized = "// line\n" ** 2001;
    try std.testing.expectError(
        error.ValueUseControlCompareLineBudgetExceeded,
        validateValueUseLeaf(
            "src/codegen/x86_64/generic_cfg/value_use/actions/control_compare.zig",
            oversized,
        ),
    );
    try std.testing.expectError(
        error.ValueUseImportDagMismatch,
        validateValueUseLeaf(
            "src/codegen/x86_64/generic_cfg/value_use/actions/scalar_cast.zig",
            "const planning = @import(\"../planning.zig\");",
        ),
    );
    try std.testing.expectError(
        error.ValueUseImportDagMismatch,
        validateValueUseLeaf(
            "src/codegen/x86_64/generic_cfg/value_use/actions/scalar_immediate.zig",
            "fn reverse(comptime Authority: type) void { _ = Authority.planning; }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseScalarArithmeticLineBudgetExceeded,
        validateValueUseLeaf(
            "src/codegen/x86_64/generic_cfg/value_use/actions/scalar_immediate.zig",
            oversized,
        ),
    );
    try std.testing.expectError(
        error.ValueUseTechnicalPubBudgetMismatch,
        validateExactTopLevelPubNames(
            "pub fn executeAccumulatorScalarCast() void {}\n",
            &value_use_scalar_arithmetic_pub_names,
        ),
    );
    try std.testing.expectError(
        error.ValueUseTechnicalPubBudgetMismatch,
        validateExactTopLevelPubNames(
            "pub fn executePairLowScalarCast() void {}\n",
            &value_use_scalar_cast_pub_names,
        ),
    );
    try std.testing.expectError(
        error.ValueUseTechnicalPubBudgetMismatch,
        validateExactTopLevelPubNames(
            "pub fn executeNamedScalarBinary() void {}\n",
            &value_use_scalar_named_pub_names,
        ),
    );
    try std.testing.expectError(
        error.ValueUseTechnicalPubBudgetMismatch,
        validateExactTopLevelPubNames(
            "pub fn executeImmediateRhsScalar() void {}\n",
            &value_use_scalar_immediate_pub_names,
        ),
    );
    try std.testing.expectError(
        error.ValueUseTechnicalPubBudgetMismatch,
        validateExactTopLevelPubNames(
            "pub const ValueUseTransaction = model.Transaction(Implementation);\n" ++
                "pub const Widened = usize;\n",
            &value_use_core_pub_names,
        ),
    );
    try std.testing.expectError(
        error.ValueUseWrapperNotDirectForward,
        validateValueUseDirectForwardingWrappers(
            "fn altered() void { if (true) return; }\n",
        ),
    );
}

test "value-use scalar arithmetic facade is aliases only and core imports only it" {
    const accepted: [:0]const u8 =
        @embedFile("../value_use/actions/scalar_arithmetic.zig");
    try validateScalarArithmeticFacadeSource(accepted);

    const branched =
        "const scalar_cast = @import(\"scalar_cast.zig\");\n" ++
        "const scalar_immediate = @import(\"scalar_immediate.zig\");\n" ++
        "pub fn executeAccumulatorScalarCast() void { if (true) return; }\n";
    try std.testing.expectError(
        error.ValueUseScalarArithmeticFacadeMismatch,
        validateScalarArithmeticFacadeSource(branched),
    );
    try std.testing.expectError(
        error.ValueUseImportDagMismatch,
        validateValueUseLeaf(
            "src/codegen/x86_64/generic_cfg/value_use/core.zig",
            "const model = @import(\"model.zig\");\n" ++
                "const a = @import(\"actions/scalar_arithmetic.zig\");\n" ++
                "const b = @import(\"actions/scalar_cast.zig\");\n" ++
                "const T = model.Transaction(Implementation);\n" ++
                "fn executePreparedActionInternal() void { switch (action) {} }\n",
        ),
    );
}

test "value-use scalar named classifier rejects function-name admission" {
    const accepted: [:0]const u8 =
        @embedFile("../value_use/actions/scalar_named.zig");
    const altered = try replaceOnceSentinel(
        std.testing.allocator,
        accepted,
        "const body = ir_body orelse return false;",
        "const body = ir_body orelse return false;\n" ++
            "    if (function.name.len != 0) return false;",
    );
    defer std.testing.allocator.free(altered);
    try std.testing.expectError(
        error.ValueUseNamedScalarFunctionPredicateForbidden,
        validateValueUseLeaf(
            "src/codegen/x86_64/generic_cfg/value_use/actions/scalar_named.zig",
            altered,
        ),
    );
}

test "value-use planning split guard freezes the revised facade DAG and internal ownership" {
    const facade: [:0]const u8 = @embedFile("../value_use/planning.zig");
    try validatePlanningFacadeSource(facade);
    const widened_facade = try replaceOnceSentinel(
        std.testing.allocator,
        facade,
        "pub const seal = physical_mapping.seal;",
        "pub const seal = physical_mapping.seal;\npub const widened = physical_mapping.seal;",
    );
    defer std.testing.allocator.free(widened_facade);
    try std.testing.expectError(
        error.ValueUsePlanningFacadeMismatch,
        validatePlanningFacadeSource(widened_facade),
    );

    const lifetime: [:0]const u8 =
        @embedFile("../value_use/planning/lifetime_admission.zig");
    try validatePlanningLeafImportDag(
        "src/codegen/x86_64/generic_cfg/value_use/planning/lifetime_admission.zig",
        lifetime,
    );
    const reverse_import = try replaceOnceSentinel(
        std.testing.allocator,
        lifetime,
        "const compatibility = @import(\"compatibility.zig\");",
        "const compatibility = @import(\"physical_mapping.zig\");",
    );
    defer std.testing.allocator.free(reverse_import);
    try std.testing.expectError(
        error.ValueUseImportDagMismatch,
        validatePlanningLeafImportDag(
            "src/codegen/x86_64/generic_cfg/value_use/planning/lifetime_admission.zig",
            reverse_import,
        ),
    );

    try std.testing.expectError(
        error.ValueUsePlanningInternalOwnershipMismatch,
        validatePlanningInternalOwnership(
            "src/codegen/x86_64/generic_cfg/value_use/planning/compatibility.zig",
            "const leaked = planning_model.Mapping;\n",
        ),
    );

    const core: [:0]const u8 = @embedFile("../value_use/core.zig");
    const bypassed_alias = try replaceOnceSentinel(
        std.testing.allocator,
        core,
        "pub const mustSurviveInstruction = planning_module.mustSurviveInstruction;",
        "pub const mustSurviveInstruction = core_mustSurviveInstruction;",
    );
    defer std.testing.allocator.free(bypassed_alias);
    try std.testing.expectError(
        error.ValueUsePlanningLifetimeAliasMismatch,
        validateValueUseLeaf(
            "src/codegen/x86_64/generic_cfg/value_use/core.zig",
            bypassed_alias,
        ),
    );
}
