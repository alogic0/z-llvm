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

test "composed selector source guard keeps scratch compare intent semantic and production wiring narrow" {
    const accepted_intent: [:0]const u8 =
        "pub const ScratchCompareRhs = union(enum) { immediate: i128, null_pointer, named: RequestHandle, }; " ++
        "pub const ScratchCompareAction = struct { result: ActionIdentity, operand_ty: ir.Type, " ++
        "predicate: ir.IcmpPredicate, samesign: bool, rhs: ScratchCompareRhs, };";
    try validateScratchCompareIntentSurface(accepted_intent);
    try std.testing.expectError(
        error.ValueUseScratchComparePhysicalIntentEscape,
        validateScratchCompareIntentSurface(
            "pub const ScratchCompareRhs = union(enum) { named: RequestHandle, }; " ++
                "pub const ScratchCompareAction = struct { physical_lhs: ArgReg, };",
        ),
    );

    const accepted_wiring: [:0]const u8 =
        "fn classifyScratchCompare() void { _ = semantic_form; } " ++
        "fn lowerScratchCompare() void { " ++
        "var transaction = try ValueUseTransaction.begin(selector); " ++
        "_ = .{ .form = .scratch_compare_operand }; " ++
        "_ = .{ .form = .scratch_compare_operand }; " ++
        "try transaction.attachScratchCompareAction(lhs, action); " ++
        "_ = try transaction.beginAccumulatorSession(); " ++
        "const lease = try transaction.preparedView(lhs); " ++
        "try transaction.executePreparedAction(lease); " ++
        "try transaction.commit(); } " ++
        "fn lowerIcmp() void { " ++
        "_ = classifyScratchCompare(icmp); " ++
        "_ = lowerScratchCompare(selector, result_name, icmp, action); " ++
        "_ = AccumulatorDefinitionTransaction.begin(selector); }";
    try validateScratchCompareProductionSites("composed_selector_icmp.zig", accepted_wiring);
    try std.testing.expectError(
        error.ValueUseScratchCompareActionOutsideAllowlist,
        validateScratchCompareProductionSites("composed_selector_scalar.zig", accepted_wiring),
    );

    const classifier_state_fixture: [:0]const u8 =
        "fn classifyScratchCompare() void { _ = selector.valueLoc(source); } " ++
        accepted_wiring["fn classifyScratchCompare() void { _ = semantic_form; } ".len..];
    try std.testing.expectError(
        error.ValueUseScratchCompareClassifierStatePredicate,
        validateScratchCompareProductionSites("composed_selector_icmp.zig", classifier_state_fixture),
    );
    const classifier_family_fixture: [:0]const u8 =
        "fn classifyScratchCompare() void { _ = family_name; } " ++
        accepted_wiring["fn classifyScratchCompare() void { _ = semantic_form; } ".len..];
    try std.testing.expectError(
        error.ValueUseScratchCompareClassifierStatePredicate,
        validateScratchCompareProductionSites("composed_selector_icmp.zig", classifier_family_fixture),
    );
    const nested_fixture: [:0]const u8 =
        "fn classifyScratchCompare() void { _ = semantic_form; } " ++
        "fn lowerScratchCompare() void { " ++
        "var transaction = try ValueUseTransaction.begin(selector); " ++
        "_ = .{ .form = .scratch_compare_operand }; " ++
        "_ = .{ .form = .scratch_compare_operand }; " ++
        "try transaction.attachScratchCompareAction(lhs, action); " ++
        "_ = try transaction.beginAccumulatorSession(); " ++
        "_ = AccumulatorDefinitionTransaction.begin(selector); " ++
        "const lease = try transaction.preparedView(lhs); " ++
        "try transaction.executePreparedAction(lease); " ++
        "try transaction.commit(); } " ++
        "fn lowerIcmp() void { " ++
        "_ = classifyScratchCompare(icmp); " ++
        "_ = lowerScratchCompare(selector, result_name, icmp, action); " ++
        "_ = AccumulatorDefinitionTransaction.begin(selector); }";
    try std.testing.expectError(
        error.ValueUseScratchCompareActionAllowlistMismatch,
        validateScratchCompareProductionSites("composed_selector_icmp.zig", nested_fixture),
    );

    const preamble_helpers =
        "fn preserveScratchCompareLiveAccumulator() void { " ++
        "const flags_before = transaction.selector.eflags.snapshot(); " ++
        "const semantic_records_before = transaction.selector.eflags_semantics.items.len; " ++
        "while (try liveAccumulatorNameAfterCurrent(transaction.selector)) |live_name| { " ++
        "_ = try preserveLiveAccumulatorValue(transaction.selector, live_name); " ++
        "try failScratchCompareForTest(transaction, .after_first_accumulator_preservation); } " ++
        "try transaction.selector.eflags.validateSnapshot(flags_before); " ++
        "if (transaction.selector.eflags_semantics.items.len != semantic_records_before) return error.Changed; } " ++
        "fn refreshScratchCompareOperandViews() void { " ++
        "transaction.prepared_views[lhs_index] = try transaction.buildPreparedRecord(lhs_index); " ++
        "transaction.prepared_views[rhs_index] = try transaction.buildPreparedRecord(rhs_index); }";
    const accepted_preamble: [:0]const u8 =
        "fn executeScratchCompare() void { " ++
        "_ = initial_lhs_view; " ++
        "try preserveScratchCompareLiveAccumulator(transaction); " ++
        "try refreshScratchCompareOperandViews(transaction, lhs_index, action); " ++
        "try failScratchCompareForTest(transaction, .after_canonical_view_refresh); " ++
        "try stageScratchCompareOperand(transaction, lhs_index, &transaction.prepared_views[lhs_index].view); " ++
        "if (try session.prepare(.preserve, .spill_live)) return; } " ++
        preamble_helpers;
    try validateScratchComparePreservationPreamble(accepted_preamble);
    const reordered_preamble: [:0]const u8 =
        "fn executeScratchCompare() void { " ++
        "_ = initial_lhs_view; " ++
        "try stageScratchCompareOperand(transaction, lhs_index, &transaction.prepared_views[lhs_index].view); " ++
        "try preserveScratchCompareLiveAccumulator(transaction); " ++
        "try refreshScratchCompareOperandViews(transaction, lhs_index, action); " ++
        "try failScratchCompareForTest(transaction, .after_canonical_view_refresh); " ++
        "if (try session.prepare(.preserve, .spill_live)) return; } " ++
        preamble_helpers;
    try std.testing.expectError(
        error.ValueUseScratchComparePreservationOrder,
        validateScratchComparePreservationPreamble(reordered_preamble),
    );
    try std.testing.expectError(
        error.ValueUseScratchComparePreservationPreambleMissing,
        validateScratchComparePreservationPreamble(
            "fn executeScratchCompare() void { try stageScratchCompareOperand(); }",
        ),
    );

    const accepted_identity: [:0]const u8 =
        "fn executeScratchCompare() void { " ++
        "const result_name = try ownActionIdentity(transaction, &stored_action.result); " ++
        "try failScratchCompareForTest(transaction, .after_result_identity_ownership); " ++
        "try session.define(result_name, .zeroExtending(1)); }";
    try validateDurableActionIdentityOwnership(accepted_identity);
    try std.testing.expectError(
        error.ValueUseDurableActionIdentityNotOwned,
        validateDurableActionIdentityOwnership(
            "fn executeScratchCompare() void { try session.define(stored_action.result.slice(), .zeroExtending(1)); }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseDurableActionIdentityNotOwned,
        validateDurableActionIdentityOwnership(
            "fn durable() void { try selector_state.bindValueLoc(selector, action.symbol.slice(), .rax); }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseDurableActionIdentityOwnershipMissing,
        validateDurableActionIdentityOwnership(
            "fn executeScratchCompare() void { try session.define(result_name, .zeroExtending(1)); }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseDurableActionIdentityOwnershipOrder,
        validateDurableActionIdentityOwnership(
            "fn executeScratchCompare() void { " ++
                "try session.define(result_name, .zeroExtending(1)); " ++
                "const result_name = try ownActionIdentity(transaction, &stored_action.result); " ++
                "try failScratchCompareForTest(transaction, .after_result_identity_ownership); }",
        ),
    );
}
test "composed selector source guard keeps current-home eq-zero wiring semantic narrow and ordered" {
    try validateCurrentHomeEqZeroIntentSurface(
        "pub const CurrentHomeEqZeroAction = struct { " ++
            "result: ActionIdentity, operand_ty: ir.Type, };",
    );
    try std.testing.expectError(
        error.ValueUseCurrentHomeEqZeroPhysicalIntentEscape,
        validateCurrentHomeEqZeroIntentSurface(
            "pub const CurrentHomeEqZeroAction = struct { " ++
                "result: ActionIdentity, operand_ty: ir.Type, source_home: ValueLoc, };",
        ),
    );
    const accepted_wiring: [:0]const u8 =
        "fn isCurrentHomeEqZeroIcmp() void { " ++
        "_ = icmp.predicate != .eq; _ = icmp.operand_ty != .int; " ++
        "_ = .int => |value| value == 0; } " ++
        "fn lowerCurrentHomeEqZeroIcmp() void { " ++
        "var transaction = try ValueUseTransaction.begin(selector); " ++
        "const lhs_request = try transaction.register(.{ " ++
        ".form = .current_home_eq_zero_operand, " ++
        ".current_home_eq_zero = action, }); " ++
        "try transaction.seal(); _ = try transaction.beginAccumulatorSession(); " ++
        "try transaction.prepare(); try transaction.materializeAll(); " ++
        "const lease = try transaction.preparedView(lhs_request); " ++
        "try transaction.executePreparedAction(lease); try transaction.commit(); } " ++
        "fn currentHomeEqZeroDiagnostic() void { " ++
        "_ = transaction.failedRequestIs(lhs_request); " ++
        "_ = error.ValueUseUnresolvedSource; " ++
        "_ = error.ValueUseCurrentHomeEqZeroWidthUnsupported; " ++
        "_ = error.ValueUseCurrentHomeEqZeroLocationUnsupported; " ++
        "_ = error.ValueUseTypeMismatch; " ++
        "_ = \"composed-block-icmp-lhs\"; " ++
        "_ = \"composed-block-icmp-lhs-width\"; " ++
        "_ = \"composed-block-icmp-lhs-loc\"; } " ++
        "fn lowerIcmp() void { " ++
        "_ = classifyScratchCompare(icmp); " ++
        "const exact_ei_narrow = isExactEiNarrowIcmp(selector, icmp); " ++
        "if (exact_ei_narrow) _ = lowerSetccEaxCompare(selector, result_name, icmp, .exact_ei); " ++
        "if (isCurrentHomeEqZeroIcmp(icmp)) " ++
        "_ = lowerCurrentHomeEqZeroIcmp(selector, result_name, icmp); " ++
        "_ = AccumulatorDefinitionTransaction.begin(selector); }";
    try validateCurrentHomeEqZeroProductionSites(
        "composed_selector_icmp.zig",
        accepted_wiring,
    );
    try std.testing.expectError(
        error.ValueUseCurrentHomeEqZeroProductionWiringForbidden,
        validateCurrentHomeEqZeroProductionSites(
            "composed_selector_calls.zig",
            "fn lower() void { _ = .{ .current_home_eq_zero = action }; }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseCurrentHomeEqZeroClassifierStatePredicate,
        validateCurrentHomeEqZeroProductionSites(
            "composed_selector_icmp.zig",
            "fn isCurrentHomeEqZeroIcmp() void { _ = selector.valueLoc(source); " ++
                "_ = icmp.predicate != .eq; _ = icmp.operand_ty != .int; " ++
                "_ = .int => |value| value == 0; } " ++
                "fn lowerCurrentHomeEqZeroIcmp() void { " ++
                "var transaction = try ValueUseTransaction.begin(selector); " ++
                "const lhs_request = try transaction.register(.{ " ++
                ".form = .current_home_eq_zero_operand, " ++
                ".current_home_eq_zero = action, }); " ++
                "try transaction.seal(); _ = try transaction.beginAccumulatorSession(); " ++
                "try transaction.prepare(); try transaction.materializeAll(); " ++
                "const lease = try transaction.preparedView(lhs_request); " ++
                "try transaction.executePreparedAction(lease); try transaction.commit(); } " ++
                "fn currentHomeEqZeroDiagnostic() void { " ++
                "_ = transaction.failedRequestIs(lhs_request); " ++
                "_ = error.ValueUseUnresolvedSource; " ++
                "_ = error.ValueUseCurrentHomeEqZeroWidthUnsupported; " ++
                "_ = error.ValueUseCurrentHomeEqZeroLocationUnsupported; " ++
                "_ = error.ValueUseTypeMismatch; " ++
                "_ = \"composed-block-icmp-lhs\"; " ++
                "_ = \"composed-block-icmp-lhs-width\"; " ++
                "_ = \"composed-block-icmp-lhs-loc\"; } " ++
                "fn lowerIcmp() void { " ++
                "_ = classifyScratchCompare(icmp); " ++
                "const exact_ei_narrow = isExactEiNarrowIcmp(selector, icmp); " ++
                "if (exact_ei_narrow) _ = lowerSetccEaxCompare(selector, result_name, icmp, .exact_ei); " ++
                "if (isCurrentHomeEqZeroIcmp(icmp)) " ++
                "_ = lowerCurrentHomeEqZeroIcmp(selector, result_name, icmp); " ++
                "_ = AccumulatorDefinitionTransaction.begin(selector); }",
        ),
    );

    const classifier =
        "fn classifyCurrentHomeEqZero() void { " ++
        "_ = .eax; _ = .rax; _ = .arg32; _ = .scratch32; " ++
        "_ = .arg64; _ = .scratch64; _ = .spill64; " ++
        "_ = .spill128 => error.ValueUseCurrentHomeEqZeroLocationUnsupported; }";
    const accepted: [:0]const u8 =
        "fn executeCurrentHomeEqZero() void { " ++
        "try preserveScratchCompareLiveAccumulator(transaction); " ++
        "transaction.prepared_views[source_index] = try transaction.buildPreparedRecord(source_index); " ++
        "_ = transaction.prepared_views[source_index].canonical_source_loc; " ++
        "_ = classifyCurrentHomeEqZero(binding, request.expected, current); " ++
        "try failCurrentHomeEqZeroForTest(transaction, .after_test_definition); " ++
        "if (try session.prepare(.preserve, .spill_live)) return; " ++
        "try failCurrentHomeEqZeroForTest(transaction, .after_accumulator_preparation); " ++
        "try emitEflagsInstruction(transaction.selector, .sete_eax, .use); " ++
        "const result_name = try ownActionIdentity(transaction, &stored_action.result); " ++
        "try session.define(result_name, .zeroExtending(1)); " ++
        "try session.finalize(); } " ++ classifier;
    try validateCurrentHomeEqZeroSequence(accepted);

    const reordered: [:0]const u8 =
        "fn executeCurrentHomeEqZero() void { " ++
        "try preserveScratchCompareLiveAccumulator(transaction); " ++
        "transaction.prepared_views[source_index] = try transaction.buildPreparedRecord(source_index); " ++
        "_ = transaction.prepared_views[source_index].canonical_source_loc; " ++
        "_ = classifyCurrentHomeEqZero(binding, request.expected, current); " ++
        "if (try session.prepare(.preserve, .spill_live)) return; " ++
        "try failCurrentHomeEqZeroForTest(transaction, .after_test_definition); " ++
        "try failCurrentHomeEqZeroForTest(transaction, .after_accumulator_preparation); " ++
        "try emitEflagsInstruction(transaction.selector, .sete_eax, .use); " ++
        "const result_name = try ownActionIdentity(transaction, &stored_action.result); " ++
        "try session.define(result_name, .zeroExtending(1)); " ++
        "try session.finalize(); } " ++ classifier;
    try std.testing.expectError(
        error.ValueUseCurrentHomeEqZeroSequenceMismatch,
        validateCurrentHomeEqZeroSequence(reordered),
    );

    const owned_identity: [:0]const u8 =
        "fn executeScratchCompare() void { " ++
        "const result_name = try ownActionIdentity(transaction, &stored_action.result); " ++
        "try failScratchCompareForTest(transaction, .after_result_identity_ownership); " ++
        "try session.define(result_name, .zeroExtending(1)); } " ++
        "fn executeCurrentHomeEqZero() void { " ++
        "const result_name = try ownActionIdentity(transaction, &stored_action.result); " ++
        "try session.define(result_name, .zeroExtending(1)); }";
    try validateDurableActionIdentityOwnership(owned_identity);
    try std.testing.expectError(
        error.ValueUseDurableActionIdentityOwnershipOrder,
        validateDurableActionIdentityOwnership(
            "fn executeScratchCompare() void { " ++
                "const result_name = try ownActionIdentity(transaction, &stored_action.result); " ++
                "try failScratchCompareForTest(transaction, .after_result_identity_ownership); " ++
                "try session.define(result_name, .zeroExtending(1)); } " ++
                "fn executeCurrentHomeEqZero() void { " ++
                "try session.define(result_name, .zeroExtending(1)); " ++
                "const result_name = try ownActionIdentity(transaction, &stored_action.result); }",
        ),
    );
}
test "composed selector source guard keeps setcc EAX compare production wiring semantic and ordered" {
    try validateSetccEaxCompareIntentSurface(
        "pub const SetccEaxCompareAction = struct { " ++
            "result: ActionIdentity, operand_ty: ir.Type, predicate: ir.IcmpPredicate, " ++
            "samesign: bool, immediate: i128, structure: SetccEaxCompareStructure, };",
    );
    try std.testing.expectError(
        error.ValueUseSetccEaxComparePhysicalIntentEscape,
        validateSetccEaxCompareIntentSurface(
            "pub const SetccEaxCompareAction = struct { " ++
                "result: ActionIdentity, operand_ty: ir.Type, predicate: ir.IcmpPredicate, " ++
                "samesign: bool, immediate: i128, structure: SetccEaxCompareStructure, " ++
                "source_home: ValueLoc, };",
        ),
    );
    const accepted_wiring: [:0]const u8 =
        "fn isSetccEaxCompareIcmp() void { _ = icmp.predicate; _ = icmp.operand_ty; _ = icmp.rhs; } " ++
        "fn lowerSetccEaxCompare() void { " ++
        "var transaction = try ValueUseTransaction.begin(selector); " ++
        "const lhs_request = try transaction.register(.{ " ++
        ".form = .setcc_eax_compare_operand, .setcc_eax_compare = action, }); " ++
        "try transaction.seal(); _ = try transaction.beginAccumulatorSession(); " ++
        "try transaction.prepare(); try transaction.materializeAll(); " ++
        "const lease = try transaction.preparedView(lhs_request); " ++
        "try transaction.executePreparedAction(lease); try transaction.commit(); } " ++
        "fn setccEaxCompareDiagnostic() void { " ++
        "_ = transaction.failedRequestIs(lhs_request); " ++
        "_ = error.ValueUseUnresolvedSource; " ++
        "_ = error.ValueUseSetccEaxCompareWidthUnsupported; " ++
        "_ = error.ValueUseSetccEaxCompareLocationUnsupported; " ++
        "_ = \"composed-block-icmp-lhs\"; " ++
        "_ = \"composed-block-icmp-lhs-width\"; " ++
        "_ = \"composed-block-icmp-lhs-loc\"; } " ++
        "fn lowerIcmp() void { " ++
        "_ = classifyScratchCompare(icmp); " ++
        "const exact_ei_narrow = isExactEiNarrowIcmp(selector, icmp); " ++
        "if (exact_ei_narrow) _ = lowerSetccEaxCompare(selector, result_name, icmp, .exact_ei); " ++
        "if (isCurrentHomeEqZeroIcmp(icmp)) return; " ++
        "if (isSetccEaxCompareIcmp(icmp)) " ++
        "_ = lowerSetccEaxCompare(selector, result_name, icmp, .ordinary); " ++
        "_ = AccumulatorDefinitionTransaction.begin(selector); }";
    try validateSetccEaxCompareProductionSites(
        "composed_selector_icmp.zig",
        accepted_wiring,
    );
    try std.testing.expectError(
        error.ValueUseSetccEaxCompareProductionWiringForbidden,
        validateSetccEaxCompareProductionSites(
            "composed_selector_calls.zig",
            "fn lower() void { _ = .{ .form = .setcc_eax_compare_operand }; }",
        ),
    );
    const stateful_wiring: [:0]const u8 =
        "fn isSetccEaxCompareIcmp() void { _ = selector.valueLoc(source); } " ++
        accepted_wiring["fn isSetccEaxCompareIcmp() void { _ = icmp.predicate; _ = icmp.operand_ty; _ = icmp.rhs; } ".len..];
    try std.testing.expectError(
        error.ValueUseSetccEaxCompareClassifierStatePredicate,
        validateSetccEaxCompareProductionSites(
            "composed_selector_icmp.zig",
            stateful_wiring,
        ),
    );

    const accepted: [:0]const u8 =
        "fn executeSetccEaxCompare() void { " ++
        "try preserveScratchCompareLiveAccumulator(transaction); " ++
        "try failSetccEaxCompareForTest(transaction, .after_preamble); " ++
        "transaction.prepared_views[source_index] = try transaction.buildPreparedRecord(source_index); " ++
        "_ = transaction.prepared_views[source_index].canonical_source_loc; " ++
        "const plan = try classifySetccEaxCompare(action); " ++
        "_ = try validateSetccEaxCompareHome(binding, request.expected, current); " ++
        "try selector_state.emitValueIntoEax(transaction.selector, source); " ++
        "try failSetccEaxCompareForTest(transaction, .after_materialization); " ++
        "try failSetccEaxCompareForTest(transaction, .after_normalization_or_mask); " ++
        "if (plan.prepare_before_definition) { " ++
        "_ = try session.prepare(.preserve, .spill_live); " ++
        "try failSetccEaxCompareForTest(transaction, .after_accumulator_preparation); } " ++
        "try selector_state.emitEflagsInstruction(transaction.selector, definition, .definition); " ++
        "try failSetccEaxCompareForTest(transaction, .after_eflags_definition); " ++
        "if (!plan.prepare_before_definition) { " ++
        "_ = try session.prepare(.preserve, .spill_live); " ++
        "try failSetccEaxCompareForTest(transaction, .after_accumulator_preparation); } " ++
        "const setcc = plan.setcc orelse return error.Unsupported; " ++
        "try selector_state.emitEflagsInstruction(transaction.selector, setcc, .use); " ++
        "const result_name = try ownActionIdentity(transaction, &stored_action.result); " ++
        "try session.define(result_name, .zeroExtending(1)); " ++
        "try session.finalize(); }";
    try validateSetccEaxCompareSequence(accepted);
    try std.testing.expectError(
        error.ValueUseSetccEaxCompareSequenceMismatch,
        validateSetccEaxCompareSequence(
            "fn executeSetccEaxCompare() void { " ++
                "try selector_state.emitValueIntoEax(transaction.selector, source); " ++
                "try preserveScratchCompareLiveAccumulator(transaction); }",
        ),
    );
}
test "composed selector source guard keeps current-home sign-bit production wiring closed and ordered" {
    try validateCurrentHomeSignBitIntentSurface(
        "pub const CurrentHomeSignBitAction = struct { " ++
            "result: ActionIdentity, operand_ty: ir.Type, };",
    );
    try std.testing.expectError(
        error.ValueUseCurrentHomeSignBitPhysicalIntentEscape,
        validateCurrentHomeSignBitIntentSurface(
            "pub const CurrentHomeSignBitAction = struct { " ++
                "result: ActionIdentity, operand_ty: ir.Type, register: ArgReg, };",
        ),
    );
    const accepted_wiring: [:0]const u8 =
        "fn lowerCurrentHomeSignBitIcmp() void { " ++
        "var transaction = try ValueUseTransaction.begin(selector); " ++
        "const lhs_request = try transaction.register(.{ " ++
        ".form = .current_home_sign_bit_operand, " ++
        ".prepared_action = .{ .current_home_sign_bit = action }, }); " ++
        "try transaction.seal(); _ = try transaction.beginAccumulatorSession(); " ++
        "try transaction.prepare(); try transaction.materializeAll(); " ++
        "const lease = try transaction.preparedView(lhs_request); " ++
        "try transaction.executePreparedAction(lease); try transaction.commit(); } " ++
        "fn currentHomeSignBitDiagnostic() void { " ++
        "_ = transaction.failedRequestIs(lhs_request); " ++
        "_ = error.ValueUseUnresolvedSource; " ++
        "_ = error.ValueUseCurrentHomeSignBitWidthUnsupported; " ++
        "_ = error.ValueUseCurrentHomeSignBitLocationUnsupported; " ++
        "_ = \"composed-block-icmp-lhs\"; " ++
        "_ = \"composed-block-icmp-lhs-width\"; " ++
        "_ = \"composed-block-icmp-lhs-loc\"; } " ++
        "fn lowerIcmp() void { " ++
        "_ = classifyScratchCompare(icmp); " ++
        "const exact_ei_narrow = isExactEiNarrowIcmp(selector, icmp); " ++
        "if (isCurrentHomeEqZeroIcmp(icmp)) return; " ++
        "if (isSetccEaxCompareIcmp(icmp)) return; " ++
        "if (ValueUseTransaction.isCurrentHomeSignBitIcmp(icmp)) " ++
        "_ = lowerCurrentHomeSignBitIcmp(selector, result_name, icmp); " ++
        "_ = AccumulatorDefinitionTransaction.begin(selector); }";
    try validateCurrentHomeSignBitProductionSites(
        "composed_selector_icmp.zig",
        accepted_wiring,
    );
    try std.testing.expectError(
        error.ValueUseCurrentHomeSignBitProductionAllowlistMismatch,
        validateCurrentHomeSignBitProductionSites(
            "composed_selector_icmp.zig",
            accepted_wiring ++
                " fn lowerOther() void { _ = .{ .form = .current_home_sign_bit_operand }; }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseCurrentHomeSignBitProductionWiringForbidden,
        validateCurrentHomeSignBitProductionSites(
            "composed_selector_calls.zig",
            "fn lowerCall() void { _ = ValueUseCurrentHomeSignBitWidthUnsupported; }",
        ),
    );
    const home_check: [:0]const u8 =
        "fn lowerCurrentHomeSignBitIcmp() void { " ++
        "var transaction = try ValueUseTransaction.begin(selector); " ++
        "_ = selector.valueLoc(source); " ++
        "const lhs_request = try transaction.register(.{ " ++
        ".form = .current_home_sign_bit_operand, " ++
        ".prepared_action = .{ .current_home_sign_bit = action }, }); " ++
        "try transaction.seal(); _ = try transaction.beginAccumulatorSession(); " ++
        "try transaction.prepare(); try transaction.materializeAll(); " ++
        "const lease = try transaction.preparedView(lhs_request); " ++
        "try transaction.executePreparedAction(lease); try transaction.commit(); } " ++
        "fn currentHomeSignBitDiagnostic() void { " ++
        "_ = transaction.failedRequestIs(lhs_request); " ++
        "_ = error.ValueUseUnresolvedSource; " ++
        "_ = error.ValueUseCurrentHomeSignBitWidthUnsupported; " ++
        "_ = error.ValueUseCurrentHomeSignBitLocationUnsupported; " ++
        "_ = \"composed-block-icmp-lhs\"; " ++
        "_ = \"composed-block-icmp-lhs-width\"; " ++
        "_ = \"composed-block-icmp-lhs-loc\"; } " ++
        "fn lowerIcmp() void { " ++
        "_ = classifyScratchCompare(icmp); " ++
        "const exact_ei_narrow = isExactEiNarrowIcmp(selector, icmp); " ++
        "if (isCurrentHomeEqZeroIcmp(icmp)) return; " ++
        "if (isSetccEaxCompareIcmp(icmp)) return; " ++
        "if (ValueUseTransaction.isCurrentHomeSignBitIcmp(icmp)) " ++
        "_ = lowerCurrentHomeSignBitIcmp(selector, result_name, icmp); " ++
        "_ = AccumulatorDefinitionTransaction.begin(selector); }";
    try std.testing.expectError(
        error.ValueUseCurrentHomeSignBitProductionAllowlistMismatch,
        validateCurrentHomeSignBitProductionSites(
            "composed_selector_icmp.zig",
            home_check,
        ),
    );
}
test "composed selector source guard keeps i128 pair wrappers semantic and production wiring narrow" {
    try validateI128PairIntentSurface(
        "pub const I128EqMinAction = struct { result: ActionIdentity, }; " ++
            "pub const I128SignBitAction = struct { result: ActionIdentity, };",
    );
    try std.testing.expectError(
        error.ValueUseI128PairPhysicalIntentEscape,
        validateI128PairIntentSurface(
            "pub const I128EqMinAction = struct { result: ActionIdentity, pair: RegPair, };",
        ),
    );

    const eq_action =
        "fn lowerI128EqMinIcmp() void { " ++
        "_ = ValueUseTransaction.begin(selector); _ = transaction.register(.{ " ++
        ".form = .i128_icmp_pair_operand, " ++
        ".prepared_action = .{ .i128_eq_min = intent }, }); " ++
        "_ = transaction.seal(); _ = transaction.beginAccumulatorSession(); " ++
        "_ = transaction.prepare(); _ = transaction.materializeAll(); " ++
        "_ = transaction.preparedView(lhs_request); " ++
        "_ = transaction.executePreparedAction(lease); _ = transaction.commit(); } ";
    const sign_action =
        "fn lowerI128SignBitIcmp() void { " ++
        "_ = ValueUseTransaction.begin(selector); _ = transaction.register(.{ " ++
        ".form = .i128_icmp_pair_operand, " ++
        ".prepared_action = .{ .i128_sign_bit = intent }, }); " ++
        "_ = transaction.seal(); _ = transaction.beginAccumulatorSession(); " ++
        "_ = transaction.prepare(); _ = transaction.materializeAll(); " ++
        "_ = transaction.preparedView(lhs_request); " ++
        "_ = transaction.executePreparedAction(lease); _ = transaction.commit(); } ";
    const mapper =
        "fn i128PairDiagnostic() void { _ = transaction.actionDiagnostic(); " ++
        "_ = transaction.failedRequestIs(lhs_request); " ++
        "_ = error.ValueUseUnresolvedSource; _ = error.UnsupportedCodegenValue; " ++
        "_ = error.ValueUseI128PairWidthUnsupported; " ++
        "_ = error.ValueUseI128PairLocationUnsupported; " ++
        "_ = \"composed-block-icmp-lhs\"; _ = \"composed-block-icmp-lhs-width\"; " ++
        "_ = \"composed-block-icmp-lhs-loc\"; } ";
    const dispatch =
        "fn lowerIcmp() void { " ++
        "if (ValueUseTransaction.isCurrentHomeSignBitIcmp(icmp)) return; " ++
        "if (ValueUseTransaction.isI128EqMinIcmp(icmp)) " ++
        "_ = lowerI128EqMinIcmp(selector, result_name, icmp); " ++
        "if (ValueUseTransaction.isI128SignBitIcmp(icmp)) " ++
        "_ = lowerI128SignBitIcmp(selector, result_name, icmp); " ++
        "_ = AccumulatorDefinitionTransaction.begin(selector); }";
    const accepted: [:0]const u8 = eq_action ++ sign_action ++ mapper ++ dispatch;
    try validateI128PairProductionSites("composed_selector_icmp.zig", accepted);

    try std.testing.expectError(
        error.ValueUseI128PairProductionWiringForbidden,
        validateI128PairProductionSites(
            "composed_selector_calls.zig",
            "fn lowerIcmp() void { _ = .{ .form = .i128_icmp_pair_operand }; }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseI128PairProductionAllowlistMismatch,
        validateI128PairProductionSites(
            "composed_selector_icmp.zig",
            accepted ++
                " fn relocated() void { _ = .{ .form = .i128_icmp_pair_operand }; }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseI128PairDispatchMismatch,
        validateI128PairProductionSites(
            "composed_selector_icmp.zig",
            eq_action ++ sign_action ++ mapper ++
                "fn lowerIcmp() void { " ++
                "if (ValueUseTransaction.isCurrentHomeSignBitIcmp(icmp)) return; " ++
                "if (ValueUseTransaction.isI128SignBitIcmp(icmp)) " ++
                "_ = lowerI128SignBitIcmp(selector, result_name, icmp); " ++
                "if (ValueUseTransaction.isI128EqMinIcmp(icmp)) " ++
                "_ = lowerI128EqMinIcmp(selector, result_name, icmp); " ++
                "_ = AccumulatorDefinitionTransaction.begin(selector); }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseI128PairProductionAllowlistMismatch,
        validateI128PairProductionSites(
            "composed_selector_icmp.zig",
            "fn lowerI128EqMinIcmp() void { _ = ValueUseTransaction.begin(selector); " ++
                "_ = selector.valueLoc(source); _ = transaction.register(.{ " ++
                ".form = .i128_icmp_pair_operand, " ++
                ".prepared_action = .{ .i128_eq_min = intent }, }); " ++
                "_ = transaction.seal(); _ = transaction.beginAccumulatorSession(); " ++
                "_ = transaction.prepare(); _ = transaction.materializeAll(); " ++
                "_ = transaction.preparedView(lhs_request); " ++
                "_ = transaction.executePreparedAction(lease); _ = transaction.commit(); } " ++
                sign_action ++ mapper ++ dispatch,
        ),
    );
}
