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
const validateScalarCastIntentSurface = support.validateScalarCastIntentSurface;
const validateScratchComparePreservationPreamble = support.validateScratchComparePreservationPreamble;
const validateCurrentHomeEqZeroSequence = support.validateCurrentHomeEqZeroSequence;
const validateSetccEaxCompareSequence = support.validateSetccEaxCompareSequence;
const validateCurrentHomeSignBitSequence = support.validateCurrentHomeSignBitSequence;
const validateI128PairSequence = support.validateI128PairSequence;
const validateScalarCastSequence = support.validateScalarCastSequence;
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

test "composed selector source guard rejects the retired stack pointer liveness scan" {
    const accepted =
        "fn valueIsLiveAfterCurrent(selector: anytype, name: []const u8) !bool {\n" ++
        "    return selector.address_dependencies.dependencyIsRequired(name, undefined);\n" ++
        "}\n";
    try validateProductionSource("composed_selector_state.zig", accepted);

    const reintroduced =
        "fn valueIsLiveAfterCurrent(selector: anytype, name: []const u8) !bool {\n" ++
        "    var it = selector.values.iterator();\n" ++
        "    while (it.next()) |entry| switch (entry.value_ptr.loc) {\n" ++
        "        .stack_i32_ptr => return true,\n" ++
        "        else => {},\n" ++
        "    };\n" ++
        "    return false;\n" ++
        "}\n";
    try std.testing.expectError(
        error.StackPointerLivenessSpecialCaseReintroduced,
        validateProductionSource("composed_selector_state.zig", reintroduced),
    );
}
test "composed selector source guard rejects function and family predicates in the address dependency domain" {
    try validateProductionSource(
        "composed_selector_address_dependencies.zig",
        "const Domain = struct { pub fn validate(_: *const Domain) !void {} };",
    );
    const fixtures = [_][:0]const u8{
        "fn bad(function: anytype) bool { return std.mem.eql(u8, function.name, \"stack_i32_ptr\"); }",
        "fn bad(function_family: []const u8) bool { return function_family.len != 0; }",
    };
    for (fixtures) |fixture| {
        try std.testing.expectError(
            error.AddressDependencyFunctionPredicateForbidden,
            validateProductionSource("composed_selector_address_dependencies.zig", fixture),
        );
    }
}
test "composed selector source guard rejects frozen bypass inventory growth" {
    const inventory =
        "file\tenclosing_function\tresolution_or_materialization_sites\n" ++
        "composed_selector_fixture.zig\tkeep\tresolveValue×1\n";
    const accepted: [:0]const u8 =
        "fn keep() void { _ = selector_state.resolveValue(undefined, undefined); }";
    try validateFrozenBypassInventoryForSource(inventory, "composed_selector_fixture.zig", accepted);
    try std.testing.expectError(
        error.FrozenBypassOccurrenceMismatch,
        validateFrozenBypassInventoryForSource(
            inventory,
            "composed_selector_fixture.zig",
            "fn keep() void { _ = selector_state.resolveValue(undefined, undefined); _ = selector_state.resolveValue(undefined, undefined); }",
        ),
    );
    try std.testing.expectError(
        error.FrozenBypassOccurrenceMismatch,
        validateFrozenBypassInventoryForSource(
            inventory,
            "composed_selector_fixture.zig",
            "fn keep() void { _ = selector_state.resolveValue(undefined, undefined); } fn added() void { _ = selector_state.valueLoc(undefined, \"x\"); }",
        ),
    );
}
test "composed selector source guard rejects function predicates in the value-use authority" {
    const accepted =
        "fn resolveNamedCurrent() void { _ = resolveValue(undefined, undefined); }" ++
        "fn begin() void { _ = Snapshot.init(selector); " ++
        "_ = AccumulatorDefinitionSession.init(transaction.selector); }";
    try validateValueUseAuthoritySource(accepted);
    try std.testing.expectError(
        error.ValueUseFunctionPredicateForbidden,
        validateValueUseAuthoritySource(accepted ++ "fn bad(function_family: []const u8) void { _ = function_family; }"),
    );
    try std.testing.expectError(
        error.ValueUsePreparedLocationEscape,
        validateValueUseAuthoritySource(accepted ++ "pub const PreparedView = union(enum) { register: u8 };"),
    );
    try std.testing.expectError(
        error.ValueUsePreparedLocationEscape,
        validateValueUseAuthoritySource(accepted ++ "pub fn readPreparedView() PreparedView { return undefined; }"),
    );
    try std.testing.expectError(
        error.ValueUsePreparedLocationEscape,
        validateValueUseAuthoritySource(accepted ++ "pub fn consumePreparedView(consumer: anytype) void { _ = consumer; }"),
    );
    try std.testing.expectError(
        error.ValueUsePreparedLocationEscape,
        validateValueUseAuthoritySource(accepted ++ "pub fn leak(view: *const PreparedView) void { _ = view; }"),
    );
    try std.testing.expectError(
        error.ValueUseConsumerOrderingForbidden,
        validateValueUseAuthoritySource(accepted ++ "pub const SemanticRole = enum { primary, secondary };"),
    );
    try std.testing.expectError(
        error.ValueUseConsumerOrderingForbidden,
        validateValueUseAuthoritySource(accepted ++ "const Request = struct { ordering_priority: u8 };"),
    );
    try std.testing.expectError(
        error.ValueUseFailureProvenanceEscape,
        validateValueUseAuthoritySource(accepted ++ "pub fn failedRequestHandle() usize { return 0; }"),
    );
    try std.testing.expectError(
        error.ValueUseFailureProvenanceEscape,
        validateValueUseAuthoritySource(accepted ++ "pub fn retryFailedRequest() void {}"),
    );
    try std.testing.expectError(
        error.ValueUseLoadHomeClassificationEscape,
        validateValueUseAuthoritySource(accepted ++ "pub fn loadSourceHome() void {}"),
    );
    try std.testing.expectError(
        error.ValueUseLoadHomeClassificationEscape,
        validateValueUseAuthoritySource(accepted ++ "pub const LoadHome = enum { stack, pointer };"),
    );
    try std.testing.expectError(
        error.ValueUseNestedAccumulatorSnapshot,
        validateValueUseAuthoritySource(accepted ++ "fn nested() void { _ = AccumulatorDefinitionTransaction.begin(selector); }"),
    );
    try std.testing.expectError(
        error.ValueUseCompositionSnapshotContractMismatch,
        validateValueUseAuthoritySource(accepted ++ "fn second() void { _ = Snapshot.init(selector); }"),
    );
}
test "composed selector source guard rejects callback escapes and raw operations around closed actions" {
    try validatePreparedViewLeafDiscipline(
        "composed_selector_fixture.zig",
        "fn lower() void { const lease = try transaction.preparedView(handle); try transaction.executePreparedAction(lease); }",
    );
    try std.testing.expectError(
        error.ValueUsePreparedLeafRawOperation,
        validatePreparedViewLeafDiscipline(
            "composed_selector_fixture.zig",
            "fn lower() void { const lease = try transaction.preparedView(handle); try transaction.executePreparedAction(lease); _ = selector_state.resolveValue(selector, source); }",
        ),
    );
    try std.testing.expectError(
        error.ValueUsePreparedLeafRawOperation,
        validatePreparedViewLeafDiscipline(
            "composed_selector_fixture.zig",
            "fn lower() void { _ = try transaction.preparedView(handle); try selector_state.materializeLocIntoLoc(selector, source, destination); }",
        ),
    );
    try std.testing.expectError(
        error.ValueUsePreparedLocationEscape,
        validatePreparedViewLeafDiscipline(
            "composed_selector_fixture.zig",
            "fn lower() void { const retained: Transaction.PreparedView = try transaction.readPreparedView(lease); _ = retained.register; }",
        ),
    );
    try std.testing.expectError(
        error.ValueUsePreparedLocationEscape,
        validatePreparedViewLeafDiscipline(
            "composed_selector_fixture.zig",
            "const Escaper = struct { fn consume(self: *@This(), view: anytype) void { self.saved = @intFromPtr(view); } }; fn lower() void { const lease = try transaction.preparedView(handle); try transaction.executePreparedAction(lease); }",
        ),
    );
    try std.testing.expectError(
        error.ValueUsePreparedLocationEscape,
        validatePreparedViewLeafDiscipline(
            "composed_selector_fixture.zig",
            "fn consume(self: *@This(), view: *const Transaction.PreparedView) void { self.saved = view; }",
        ),
    );
    try std.testing.expectError(
        error.ValueUsePreparedTestActionInProduction,
        validatePreparedViewLeafDiscipline(
            "composed_selector_fixture.zig",
            "fn lower() void { const action: Transaction.PreparedAction = .{ .validate_shape = expected }; _ = action; }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseStoreActionOutsideAllowlist,
        validatePreparedViewLeafDiscipline(
            "composed_selector_fixture.zig",
            "fn lowerStore() void { const action: Transaction.PreparedAction = .{ .store_i64 = intent }; _ = action; }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseMemcpyActionOutsideAllowlist,
        validatePreparedViewLeafDiscipline(
            "composed_selector_fixture.zig",
            "fn lowerInlineMemcpy() void { const action: Transaction.PreparedAction = .{ .inline_memcpy = intent }; _ = action; }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseMemcpyTestHookInProduction,
        validatePreparedViewLeafDiscipline(
            "composed_selector_calls.zig",
            "fn lowerInlineMemcpy() void { _ = transaction.setMemcpyTestFailure(.after_source); }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseLoadActionNotWired,
        validatePreparedViewLeafDiscipline(
            "composed_selector_fixture.zig",
            "fn lowerLoad() void { _ = .{ .form = .load_address, .load_scalar = intent }; }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseLoadActionNotWired,
        validatePreparedViewLeafDiscipline(
            "composed_selector_fixture.zig",
            "fn lowerReadOnlyPointerIntegerLoad() void { _ = .load_readonly_pair; }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseLoadTestHookInProduction,
        validatePreparedViewLeafDiscipline(
            "composed_selector_fixture.zig",
            "fn lowerLoad() void { _ = transaction.setLoadTestFailure(.after_pointer_staging); }",
        ),
    );
}

test "composed selector source guard freezes semantic-only scalar cast intents" {
    const accepted =
        "pub const PairLowScalarCastAction = struct { result: ActionIdentity, op: ir.CastOp, from_bits: u16, to_bits: u16, };" ++
        "pub const AccumulatorScalarCastAction = struct { result: ActionIdentity, op: ir.CastOp, from_bits: u16, to_bits: u16, immediate: ?i128 = null, exact_ei: bool = false, };" ++
        "pub const SignExtendScratchAction = struct { result: ActionIdentity, };";
    try validateScalarCastIntentSurface(accepted);
    try std.testing.expectError(
        error.ValueUseScalarCastPhysicalIntentEscape,
        validateScalarCastIntentSurface(
            "pub const PairLowScalarCastAction = struct { result: ActionIdentity, op: ir.CastOp, from_bits: u16, to_bits: u16, register: ArgReg, };" ++
                "pub const AccumulatorScalarCastAction = struct { result: ActionIdentity, op: ir.CastOp, from_bits: u16, to_bits: u16, immediate: ?i128 = null, exact_ei: bool = false, };" ++
                "pub const SignExtendScratchAction = struct { result: ActionIdentity, };",
        ),
    );
    try std.testing.expectError(
        error.ValueUseScalarCastIntentMissing,
        validateScalarCastIntentSurface(
            "pub const SignExtendScratchAction = struct { result: ActionIdentity, };",
        ),
    );
}
