const std = @import("std");
const model = @import("model.zig");
const residual = @import("residual_policy.zig");

const source_dir = model.source_dir;
const source_prefix = model.source_prefix;
const source_suffix = model.source_suffix;
const SourceKind = model.SourceKind;
const ClassifiedSource = model.ClassifiedSource;
const classified_sources = model.classified_sources;
const value_use_leaf_paths = model.value_use_leaf_paths;
const value_use_model_pub_names = model.value_use_model_pub_names;
const value_use_core_pub_names = model.value_use_core_pub_names;
const value_use_planning_pub_names = model.value_use_planning_pub_names;
const value_use_materialization_pub_names = model.value_use_materialization_pub_names;
const value_use_composition_pub_names = model.value_use_composition_pub_names;
const value_use_address_pub_names = model.value_use_address_pub_names;
const value_use_control_pub_names = model.value_use_control_pub_names;
const value_use_calls_pub_names = model.value_use_calls_pub_names;
const frozen_bypass_inventory_path = model.frozen_bypass_inventory_path;
const frozen_bypass_inventory_sha256 = model.frozen_bypass_inventory_sha256;
const value_use_facade_manifest_path = model.value_use_facade_manifest_path;
const value_use_facade_manifest_sha256 = model.value_use_facade_manifest_sha256;
const bypass_operations = model.bypass_operations;
const DirectOperation = model.DirectOperation;
const ResidualClassification = model.ResidualClassification;
const FutureArchitecturalSlice = model.FutureArchitecturalSlice;
const ResidualAllowlistEntry = model.ResidualAllowlistEntry;
const residual_accumulator_allowlist = model.residual_accumulator_allowlist;
const ExclusionOperation = model.ExclusionOperation;
const ExclusionAllowlistEntry = model.ExclusionAllowlistEntry;
const architectural_exclusion_allowlist = model.architectural_exclusion_allowlist;
const FunctionFingerprint = model.FunctionFingerprint;
const residual_function_fingerprints = model.residual_function_fingerprints;
const FunctionBody = model.FunctionBody;
const max_function_bodies = model.max_function_bodies;
const readFrozenBypassInventory = model.readFrozenBypassInventory;
const validateNoPublicPreparedPointer = model.validateNoPublicPreparedPointer;
const validateNoFunctionFamilyPredicate = model.validateNoFunctionFamilyPredicate;
const ParsedBypassSite = model.ParsedBypassSite;
const parseFrozenBypassSite = model.parseFrozenBypassSite;
const frozenBypassExpectedCount = model.frozenBypassExpectedCount;
const isBypassOperation = model.isBypassOperation;
const countPattern = model.countPattern;
const validateEflagsEmissionAuthority = residual.validateEflagsEmissionAuthority;
const validateStateDataLifecycle = residual.validateStateDataLifecycle;
const validateResidualAccumulatorAllowlist = residual.validateResidualAccumulatorAllowlist;
const collectFunctionBodies = residual.collectFunctionBodies;
const functionBodyContaining = residual.functionBodyContaining;
const functionBodyNamed = residual.functionBodyNamed;
const validateFunctionBodyFingerprint = residual.validateFunctionBodyFingerprint;
const functionBodyFingerprint = residual.functionBodyFingerprint;
const fixtureFunctionFingerprint = residual.fixtureFunctionFingerprint;
const validateFunctionFingerprintInventory = residual.validateFunctionFingerprintInventory;
const functionHasAllowlistedOperation = residual.functionHasAllowlistedOperation;
const functionFingerprint = residual.functionFingerprint;
const residualAllowlistIndex = residual.residualAllowlistIndex;
const validateArchitecturalExclusionAllowlist = residual.validateArchitecturalExclusionAllowlist;
const architecturalExclusionIndex = residual.architecturalExclusionIndex;
const validateAccumulatorDisplacementPolicies = residual.validateAccumulatorDisplacementPolicies;
const classificationIndex = residual.classificationIndex;
const isTestSource = residual.isTestSource;
pub fn validatePreparedViewLeafDiscipline(source_name: []const u8, source: [:0]const u8) !void {
    if (std.mem.indexOf(u8, source, "readPreparedView(") != null or
        std.mem.indexOf(u8, source, "consumePreparedView(") != null or
        std.mem.indexOf(u8, source, ".PreparedView") != null or
        std.mem.indexOf(u8, source, ".prepared_views") != null or
        (std.mem.indexOf(u8, source, "fn consume(") != null and
            (std.mem.indexOf(u8, source, "view: anytype") != null or
                std.mem.indexOf(u8, source, "view: *") != null)))
    {
        return error.ValueUsePreparedLocationEscape;
    }
    if (std.mem.indexOf(u8, source, ".validate_shape") != null)
        return error.ValueUsePreparedTestActionInProduction;
    try validateSwitchActionProductionSites(source_name, source);
    try validateBranchActionProductionSites(source_name, source);
    try validateStoreActionProductionSites(source_name, source);
    try validateMemcpyActionProductionSites(source_name, source);
    try validateLoadDiagnosticMappingProductionSites(source_name, source);
    try validateDormantLoadActionProductionSites(source_name, source);
    try validateFailureProvenanceProductionSites(source_name, source);
    try validateAccumulatorCompositionProductionSites(source_name, source);
    try validateScratchCompareProductionSites(source_name, source);
    try validateCurrentHomeEqZeroProductionSites(source_name, source);
    try validateSetccEaxCompareProductionSites(source_name, source);
    try validateCurrentHomeSignBitProductionSites(source_name, source);
    try validateI128PairProductionSites(source_name, source);
    try validateScalarCastProductionSites(source_name, source);
    try validateDormantImmediateScalarProductionSites(source_name, source);
    const forbidden = [_][]const u8{
        "bindValueLoc(",
        "bindEax(",
        "bindRax(",
        "bindAccumulator(",
        "clobberAccumulator(",
        "spillValue(",
    };
    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    for (bodies) |body| {
        const function_source = source[body.start..body.end];
        if (std.mem.indexOf(u8, function_source, ".preparedView(") == null and
            std.mem.indexOf(u8, function_source, ".executePreparedAction(") == null) continue;
        for (bypass_operations) |operation| {
            const occurrence = std.mem.indexOf(u8, function_source, operation) orelse continue;
            if (std.mem.eql(u8, body.name, "lowerLoad") and
                std.mem.eql(u8, operation, "resolveValue") and
                countPattern(function_source, operation) == 1)
            {
                const begin = std.mem.indexOf(u8, function_source, "ValueUseTransaction.begin(selector)") orelse
                    return error.ValueUsePreparedLeafRawOperation;
                if (occurrence < begin) continue;
            }
            return error.ValueUsePreparedLeafRawOperation;
        }
        for (forbidden) |pattern| {
            if (std.mem.indexOf(u8, function_source, pattern) != null)
                return error.ValueUsePreparedLeafRawOperation;
        }
    }
}

pub fn validateDormantImmediateScalarProductionSites(
    source_name: []const u8,
    source: [:0]const u8,
) !void {
    _ = source_name;
    const forbidden = [_][]const u8{
        ".immediate_rhs_scalar_operand",
        ".immediate_lhs_scalar_operand",
        ".immediate_rhs_scalar",
        ".immediate_lhs_scalar",
        "isImmediateRhsScalar(",
        "isImmediateLhsScalar(",
        "setImmediateScalarTestFailure(",
    };
    for (forbidden) |pattern| {
        if (std.mem.indexOf(u8, source, pattern) != null)
            return error.ValueUseImmediateScalarActionNotWired;
    }
}

pub fn validateScalarCastProductionSites(source_name: []const u8, source: [:0]const u8) !void {
    const pair_form = ".form = .pair_low_scalar_cast_operand";
    const accumulator_form = ".form = .accumulator_scalar_cast_operand";
    const sign_form = ".form = .sign_extend_scratch_operand";
    const pair_action = ".prepared_action = .{ .pair_low_scalar_cast";
    const accumulator_action = ".prepared_action = .{ .accumulator_scalar_cast";
    const sign_action = ".prepared_action = .{ .sign_extend_scratch";
    const pair_classifier = "isPairLowScalarCast(";
    const accumulator_classifier = "isAccumulatorScalarCast(";
    const sign_classifier = "isSignExtendScratchCast(";
    const marker_total =
        countPattern(source, pair_form) +
        countPattern(source, accumulator_form) +
        countPattern(source, sign_form) +
        countPattern(source, pair_action) +
        countPattern(source, accumulator_action) +
        countPattern(source, sign_action) +
        countPattern(source, pair_classifier) +
        countPattern(source, accumulator_classifier) +
        countPattern(source, sign_classifier);
    if (!std.mem.eql(u8, source_name, "composed_selector_scalar.zig")) {
        if (marker_total != 0)
            return error.ValueUseScalarCastActionOutsideAllowlist;
        return;
    }

    if (countPattern(source, pair_form) != 1 or
        countPattern(source, accumulator_form) != 1 or
        countPattern(source, sign_form) != 1 or
        countPattern(source, pair_action) != 1 or
        countPattern(source, accumulator_action) != 1 or
        countPattern(source, sign_action) != 1 or
        countPattern(source, pair_classifier) != 1 or
        countPattern(source, accumulator_classifier) != 2 or
        countPattern(source, sign_classifier) != 1 or
        countPattern(source, "accumulatorCastSource") != 0)
    {
        return error.ValueUseScalarCastActionAllowlistMismatch;
    }

    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const lower_cast = functionBodyNamed(bodies, "lowerCast") orelse
        return error.ValueUseScalarCastActionAllowlistMismatch;
    const lower_i52_cast = functionBodyNamed(bodies, "lowerI52Cast") orelse
        return error.ValueUseScalarCastActionAllowlistMismatch;
    const pair_lowerer = functionBodyNamed(bodies, "lowerPairLowScalarCast") orelse
        return error.ValueUseScalarCastActionAllowlistMismatch;
    const accumulator_lowerer = functionBodyNamed(bodies, "lowerAccumulatorScalarCast") orelse
        return error.ValueUseScalarCastActionAllowlistMismatch;
    const sign_lowerer = functionBodyNamed(bodies, "lowerSignExtendScratchCast") orelse
        return error.ValueUseScalarCastActionAllowlistMismatch;
    const mapper = functionBodyNamed(bodies, "scalarCastValueUseDiagnostic") orelse
        return error.ValueUseScalarCastActionAllowlistMismatch;
    const lower_cast_source = source[lower_cast.start..lower_cast.end];
    const lower_i52_source = source[lower_i52_cast.start..lower_i52_cast.end];

    const LowererContract = struct {
        body: FunctionBody,
        form: []const u8,
        action: []const u8,
        accumulator_sessions: usize,
    };
    const lowerers = [_]LowererContract{
        .{ .body = pair_lowerer, .form = pair_form, .action = pair_action, .accumulator_sessions = 0 },
        .{ .body = accumulator_lowerer, .form = accumulator_form, .action = accumulator_action, .accumulator_sessions = 1 },
        .{ .body = sign_lowerer, .form = sign_form, .action = sign_action, .accumulator_sessions = 0 },
    };
    for (lowerers) |lowerer| {
        const body_source = source[lowerer.body.start..lowerer.body.end];
        if (countPattern(body_source, "ValueUseTransaction.begin(selector)") != 1 or
            countPattern(body_source, "transaction.register(") != 1 or
            countPattern(body_source, lowerer.form) != 1 or
            countPattern(body_source, lowerer.action) != 1 or
            countPattern(body_source, "transaction.seal()") != 1 or
            countPattern(body_source, "transaction.prepare()") != 1 or
            countPattern(body_source, "transaction.materializeAll()") != 1 or
            countPattern(body_source, "transaction.preparedView(") != 1 or
            countPattern(body_source, "transaction.executePreparedAction(") != 1 or
            countPattern(body_source, "transaction.commit()") != 1 or
            countPattern(body_source, "transaction.beginAccumulatorSession()") != lowerer.accumulator_sessions or
            countPattern(body_source, "scalarCastValueUseDiagnostic(") != 5 or
            countPattern(body_source, "orelse return err") != 5)
        {
            return error.ValueUseScalarCastActionAllowlistMismatch;
        }
        const forbidden = [_][]const u8{
            "resolveValue(",
            "ValueLoc",
            "bindValueLoc(",
            "bindAccumulator(",
            "emitValueInto",
            ".spill64",
            ".spill128",
            ".eax",
            ".rax",
        };
        for (forbidden) |pattern| {
            if (std.mem.indexOf(u8, body_source, pattern) != null)
                return error.ValueUseScalarCastConsumerHomeClassification;
        }
    }

    const mapper_source = source[mapper.start..mapper.end];
    if (countPattern(mapper_source, ".failedRequestIs(") != 1 or
        countPattern(mapper_source, "error.ValueUseActionDiagnostic") != 1 or
        countPattern(mapper_source, "transaction.actionDiagnostic()") != 1)
    {
        return error.ValueUseScalarCastActionAllowlistMismatch;
    }

    // C02 remains an alias-only binding and C03 remains a pair-result path.
    if (countPattern(lower_cast_source, "selector_state.resolveValue(") != 1 or
        countPattern(lower_cast_source, "selector_state.emitValueIntoScratch(") != 1 or
        countPattern(lower_cast_source, "selector_state.resolvePairValue(") != 0 or
        countPattern(lower_cast_source, "selector_state.bindValueLoc(") != 1 or
        countPattern(lower_cast_source, "selector_state.bindPairScratch(") != 1)
    {
        return error.ValueUseScalarCastResidualOwnershipMismatch;
    }
    for (bypass_operations) |operation| {
        if (std.mem.indexOf(u8, lower_i52_source, operation) != null)
            return error.ValueUseScalarCastResidualOwnershipMismatch;
    }

    // The exact-EI structural decision remains between the C03 pair-result
    // branch and the ordinary accumulator-cast classifier.
    const i52_dispatch = std.mem.indexOf(u8, lower_cast_source, accumulator_classifier) orelse
        return error.ValueUseScalarCastDispatchOrderMismatch;
    const i52_fallback = std.mem.indexOf(u8, lower_cast_source, "return lowerI52Cast(cast)") orelse
        return error.ValueUseScalarCastDispatchOrderMismatch;
    const pair_dispatch = std.mem.indexOf(u8, lower_cast_source, pair_classifier) orelse
        return error.ValueUseScalarCastDispatchOrderMismatch;
    const pair_residual = std.mem.indexOf(u8, lower_cast_source, "const loc = selector_state.resolveValue(") orelse
        return error.ValueUseScalarCastDispatchOrderMismatch;
    const c03_residual = std.mem.indexOf(u8, lower_cast_source, "if (from_bits == 64 and to_bits == 128)") orelse
        return error.ValueUseScalarCastDispatchOrderMismatch;
    const exact_ei = std.mem.indexOf(u8, lower_cast_source, "const exact_ei_narrow =") orelse
        return error.ValueUseScalarCastDispatchOrderMismatch;
    const ordinary_accumulator = std.mem.lastIndexOf(u8, lower_cast_source, accumulator_classifier) orelse
        return error.ValueUseScalarCastDispatchOrderMismatch;
    const sign_width = std.mem.indexOf(u8, lower_cast_source, "if (from_bits != 32 or to_bits != 64)") orelse
        return error.ValueUseScalarCastDispatchOrderMismatch;
    const sign_dispatch = std.mem.indexOf(u8, lower_cast_source, sign_classifier) orelse
        return error.ValueUseScalarCastDispatchOrderMismatch;
    if (!(i52_dispatch < i52_fallback and
        pair_dispatch < pair_residual and
        c03_residual < exact_ei and
        exact_ei < ordinary_accumulator and
        sign_width < sign_dispatch))
    {
        return error.ValueUseScalarCastDispatchOrderMismatch;
    }
}

pub fn validateScratchCompareProductionSites(source_name: []const u8, source: [:0]const u8) !void {
    const form_pattern = ".form = .scratch_compare_operand";
    const attach_pattern = "attachScratchCompareAction(";
    const form_total = countPattern(source, form_pattern);
    const attach_total = countPattern(source, attach_pattern);
    if (!std.mem.eql(u8, source_name, "composed_selector_icmp.zig")) {
        if (form_total != 0 or attach_total != 0)
            return error.ValueUseScratchCompareActionOutsideAllowlist;
        return;
    }

    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const classifier_body = functionBodyNamed(bodies, "classifyScratchCompare") orelse
        return error.ValueUseScratchCompareActionAllowlistMismatch;
    const action_body = functionBodyNamed(bodies, "lowerScratchCompare") orelse
        return error.ValueUseScratchCompareActionAllowlistMismatch;
    const dispatch_body = functionBodyNamed(bodies, "lowerIcmp") orelse
        return error.ValueUseScratchCompareActionAllowlistMismatch;
    const classifier_source = source[classifier_body.start..classifier_body.end];
    const action_source = source[action_body.start..action_body.end];
    const dispatch_source = source[dispatch_body.start..dispatch_body.end];

    // The partial-family split is semantic only: the classifier cannot observe
    // selector state, current homes, functions, or family identity.
    const classifier_forbidden = [_][]const u8{
        "selector",
        "resolveValue(",
        "valueLoc(",
        "allocation_plan",
        "ValueLoc",
        "function",
        "Function",
        "family",
        "Family",
        "callee",
        "Callee",
        "isExact",
        ".spill64",
        ".spill128",
        ".eax",
        ".rax",
        ".arg32",
        ".arg64",
        ".scratch32",
        ".scratch64",
    };
    for (classifier_forbidden) |pattern| {
        if (std.mem.indexOf(u8, classifier_source, pattern) != null)
            return error.ValueUseScratchCompareClassifierStatePredicate;
    }

    const dispatch_index = std.mem.indexOf(u8, dispatch_source, "classifyScratchCompare(icmp)") orelse
        return error.ValueUseScratchCompareDispatchMismatch;
    const legacy_begin_index = std.mem.indexOf(
        u8,
        dispatch_source,
        "AccumulatorDefinitionTransaction.begin(selector)",
    ) orelse return error.ValueUseScratchCompareDispatchMismatch;
    if (dispatch_index >= legacy_begin_index or
        countPattern(dispatch_source, "classifyScratchCompare(icmp)") != 1 or
        countPattern(dispatch_source, "lowerScratchCompare(selector, result_name, icmp, action)") != 1 or
        countPattern(dispatch_source, "ValueUseTransaction.begin(selector)") != 0 or
        countPattern(dispatch_source, "AccumulatorDefinitionTransaction.begin(selector)") != 1 or
        countPattern(action_source, form_pattern) != 2 or
        countPattern(action_source, attach_pattern) != 1 or
        countPattern(action_source, "ValueUseTransaction.begin(selector)") != 1 or
        countPattern(action_source, "beginAccumulatorSession()") != 1 or
        countPattern(action_source, "AccumulatorDefinitionTransaction.begin(") != 0 or
        countPattern(action_source, ".preparedView(") != 1 or
        countPattern(action_source, ".executePreparedAction(") != 1 or
        countPattern(action_source, ".commit()") != 1 or
        form_total != 2 or
        attach_total != 1)
    {
        return error.ValueUseScratchCompareActionAllowlistMismatch;
    }
}

pub fn validateCurrentHomeEqZeroProductionSites(
    source_name: []const u8,
    source: [:0]const u8,
) !void {
    const production_markers = [_][]const u8{
        ".form = .current_home_eq_zero_operand",
        ".current_home_eq_zero =",
        "ValueUseCurrentHomeEqZeroWidthUnsupported",
        "ValueUseCurrentHomeEqZeroLocationUnsupported",
    };
    var has_wiring = false;
    for (production_markers) |pattern| {
        if (std.mem.indexOf(u8, source, pattern) != null) has_wiring = true;
    }
    if (!has_wiring) return;
    if (!std.mem.eql(u8, source_name, "composed_selector_icmp.zig"))
        return error.ValueUseCurrentHomeEqZeroProductionWiringForbidden;

    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const classifier_body = functionBodyNamed(bodies, "isCurrentHomeEqZeroIcmp") orelse
        return error.ValueUseCurrentHomeEqZeroProductionAllowlistMismatch;
    const action_body = functionBodyNamed(bodies, "lowerCurrentHomeEqZeroIcmp") orelse
        return error.ValueUseCurrentHomeEqZeroProductionAllowlistMismatch;
    const mapper_body = functionBodyNamed(bodies, "currentHomeEqZeroDiagnostic") orelse
        return error.ValueUseCurrentHomeEqZeroProductionAllowlistMismatch;
    const dispatch_body = functionBodyNamed(bodies, "lowerIcmp") orelse
        return error.ValueUseCurrentHomeEqZeroProductionAllowlistMismatch;
    const classifier = source[classifier_body.start..classifier_body.end];
    const action = source[action_body.start..action_body.end];
    const mapper = source[mapper_body.start..mapper_body.end];
    const dispatch = source[dispatch_body.start..dispatch_body.end];

    const classifier_forbidden = [_][]const u8{
        "selector",
        "resolveValue(",
        "valueLoc(",
        "allocation_plan",
        "ValueLoc",
        "function",
        "Function",
        "family",
        "Family",
        "callee",
        "Callee",
        "isExact",
        ".eax",
        ".rax",
        ".arg32",
        ".arg64",
        ".scratch32",
        ".scratch64",
        ".spill64",
        ".spill128",
    };
    for (classifier_forbidden) |pattern| {
        if (std.mem.indexOf(u8, classifier, pattern) != null)
            return error.ValueUseCurrentHomeEqZeroClassifierStatePredicate;
    }
    const classifier_required = [_][]const u8{
        "icmp.predicate != .eq",
        "icmp.operand_ty != .int",
        ".int => |value| value == 0",
    };
    for (classifier_required) |pattern| {
        if (std.mem.indexOf(u8, classifier, pattern) == null)
            return error.ValueUseCurrentHomeEqZeroClassifierMismatch;
    }

    const scratch_dispatch = std.mem.indexOf(u8, dispatch, "classifyScratchCompare(icmp)") orelse
        return error.ValueUseCurrentHomeEqZeroDispatchMismatch;
    const exact_dispatch = std.mem.indexOf(
        u8,
        dispatch,
        "const exact_ei_narrow = isExactEiNarrowIcmp(selector, icmp);",
    ) orelse return error.ValueUseCurrentHomeEqZeroDispatchMismatch;
    const current_dispatch = std.mem.indexOf(
        u8,
        dispatch,
        "if (isCurrentHomeEqZeroIcmp(icmp))",
    ) orelse return error.ValueUseCurrentHomeEqZeroDispatchMismatch;
    const legacy_begin = std.mem.indexOf(
        u8,
        dispatch,
        "AccumulatorDefinitionTransaction.begin(selector)",
    ) orelse return error.ValueUseCurrentHomeEqZeroDispatchMismatch;
    if (!(scratch_dispatch < exact_dispatch and exact_dispatch < current_dispatch and
        current_dispatch < legacy_begin) or
        countPattern(dispatch, "isExactEiNarrowIcmp(selector, icmp)") != 1 or
        countPattern(dispatch, "lowerSetccEaxCompare(selector, result_name, icmp, .exact_ei)") != 1 or
        countPattern(dispatch, "isCurrentHomeEqZeroIcmp(icmp)") != 1 or
        countPattern(dispatch, "lowerCurrentHomeEqZeroIcmp(selector, result_name, icmp)") != 1 or
        countPattern(dispatch, "AccumulatorDefinitionTransaction.begin(selector)") != 1 or
        countPattern(dispatch, "ValueUseTransaction.begin(selector)") != 0)
    {
        return error.ValueUseCurrentHomeEqZeroDispatchMismatch;
    }

    if (countPattern(action, "ValueUseTransaction.begin(selector)") != 1 or
        countPattern(action, ".form = .current_home_eq_zero_operand") != 1 or
        countPattern(action, ".current_home_eq_zero =") != 1 or
        countPattern(action, ".register(") != 1 or
        countPattern(action, ".seal()") != 1 or
        countPattern(action, ".beginAccumulatorSession()") != 1 or
        countPattern(action, ".prepare()") != 1 or
        countPattern(action, ".materializeAll()") != 1 or
        countPattern(action, ".preparedView(") != 1 or
        countPattern(action, ".executePreparedAction(") != 1 or
        countPattern(action, ".commit()") != 1 or
        countPattern(action, "AccumulatorDefinitionTransaction.begin(") != 0 or
        countPattern(action, "resolveValue(") != 0 or
        countPattern(action, "valueLoc(") != 0)
    {
        return error.ValueUseCurrentHomeEqZeroProductionAllowlistMismatch;
    }

    const mapper_required = [_][]const u8{
        "failedRequestIs(lhs_request)",
        "ValueUseUnresolvedSource",
        "ValueUseCurrentHomeEqZeroWidthUnsupported",
        "ValueUseCurrentHomeEqZeroLocationUnsupported",
        "ValueUseTypeMismatch",
        "composed-block-icmp-lhs",
        "composed-block-icmp-lhs-width",
        "composed-block-icmp-lhs-loc",
    };
    for (mapper_required) |pattern| {
        if (std.mem.indexOf(u8, mapper, pattern) == null)
            return error.ValueUseCurrentHomeEqZeroDiagnosticMapperMismatch;
    }
    if (countPattern(mapper, "failedRequestIs(") != 1 or
        countPattern(mapper, "resolveValue(") != 0 or
        countPattern(mapper, "valueLoc(") != 0)
    {
        return error.ValueUseCurrentHomeEqZeroDiagnosticMapperMismatch;
    }

    for (bodies) |body| {
        const body_source = source[body.start..body.end];
        var contains_marker = false;
        for (production_markers) |pattern| {
            if (std.mem.indexOf(u8, body_source, pattern) != null) contains_marker = true;
        }
        if (!contains_marker) continue;
        if (!std.mem.eql(u8, body.name, "lowerCurrentHomeEqZeroIcmp") and
            !std.mem.eql(u8, body.name, "currentHomeEqZeroDiagnostic"))
        {
            return error.ValueUseCurrentHomeEqZeroProductionAllowlistMismatch;
        }
    }
}

pub fn validateSetccEaxCompareProductionSites(
    source_name: []const u8,
    source: [:0]const u8,
) !void {
    const production_markers = [_][]const u8{
        ".form = .setcc_eax_compare_operand",
        ".setcc_eax_compare =",
        "ValueUseSetccEaxCompareWidthUnsupported",
        "ValueUseSetccEaxCompareLocationUnsupported",
    };
    var has_wiring = false;
    for (production_markers) |pattern| {
        if (std.mem.indexOf(u8, source, pattern) != null) has_wiring = true;
    }
    if (!has_wiring) return;
    if (!std.mem.eql(u8, source_name, "composed_selector_icmp.zig"))
        return error.ValueUseSetccEaxCompareProductionWiringForbidden;

    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const classifier_body = functionBodyNamed(bodies, "isSetccEaxCompareIcmp") orelse
        return error.ValueUseSetccEaxCompareProductionAllowlistMismatch;
    const action_body = functionBodyNamed(bodies, "lowerSetccEaxCompare") orelse
        return error.ValueUseSetccEaxCompareProductionAllowlistMismatch;
    const mapper_body = functionBodyNamed(bodies, "setccEaxCompareDiagnostic") orelse
        return error.ValueUseSetccEaxCompareProductionAllowlistMismatch;
    const dispatch_body = functionBodyNamed(bodies, "lowerIcmp") orelse
        return error.ValueUseSetccEaxCompareProductionAllowlistMismatch;
    const classifier = source[classifier_body.start..classifier_body.end];
    const action = source[action_body.start..action_body.end];
    const mapper = source[mapper_body.start..mapper_body.end];
    const dispatch = source[dispatch_body.start..dispatch_body.end];

    const classifier_forbidden = [_][]const u8{
        "selector",
        "resolveValue(",
        "valueLoc(",
        "allocation_plan",
        "ValueLoc",
        "function",
        "Function",
        "family",
        "Family",
        "callee",
        "Callee",
        "isExact",
        ".eax",
        ".rax",
        ".arg32",
        ".arg64",
        ".scratch32",
        ".scratch64",
        ".spill64",
        ".spill128",
    };
    for (classifier_forbidden) |pattern| {
        if (std.mem.indexOf(u8, classifier, pattern) != null)
            return error.ValueUseSetccEaxCompareClassifierStatePredicate;
    }

    const scratch_dispatch = std.mem.indexOf(u8, dispatch, "classifyScratchCompare(icmp)") orelse
        return error.ValueUseSetccEaxCompareDispatchMismatch;
    const exact_dispatch = std.mem.indexOf(
        u8,
        dispatch,
        "const exact_ei_narrow = isExactEiNarrowIcmp(selector, icmp);",
    ) orelse return error.ValueUseSetccEaxCompareDispatchMismatch;
    const exact_action = std.mem.indexOf(
        u8,
        dispatch,
        "lowerSetccEaxCompare(selector, result_name, icmp, .exact_ei)",
    ) orelse return error.ValueUseSetccEaxCompareDispatchMismatch;
    const current_dispatch = std.mem.indexOf(
        u8,
        dispatch,
        "isCurrentHomeEqZeroIcmp(icmp)",
    ) orelse return error.ValueUseSetccEaxCompareDispatchMismatch;
    const ordinary_dispatch = std.mem.indexOf(
        u8,
        dispatch,
        "isSetccEaxCompareIcmp(icmp)",
    ) orelse return error.ValueUseSetccEaxCompareDispatchMismatch;
    const ordinary_action = std.mem.indexOf(
        u8,
        dispatch,
        "lowerSetccEaxCompare(selector, result_name, icmp, .ordinary)",
    ) orelse return error.ValueUseSetccEaxCompareDispatchMismatch;
    const legacy_begin = std.mem.indexOf(
        u8,
        dispatch,
        "AccumulatorDefinitionTransaction.begin(selector)",
    ) orelse return error.ValueUseSetccEaxCompareDispatchMismatch;
    if (!(scratch_dispatch < exact_dispatch and exact_dispatch < exact_action and
        exact_action < current_dispatch and current_dispatch < ordinary_dispatch and
        ordinary_dispatch < ordinary_action and ordinary_action < legacy_begin) or
        countPattern(dispatch, "isExactEiNarrowIcmp(selector, icmp)") != 1 or
        countPattern(dispatch, "isCurrentHomeEqZeroIcmp(icmp)") != 1 or
        countPattern(dispatch, "isSetccEaxCompareIcmp(icmp)") != 1 or
        countPattern(dispatch, "lowerSetccEaxCompare(") != 2 or
        countPattern(dispatch, "AccumulatorDefinitionTransaction.begin(selector)") != 1 or
        countPattern(dispatch, "ValueUseTransaction.begin(selector)") != 0)
    {
        return error.ValueUseSetccEaxCompareDispatchMismatch;
    }

    if (countPattern(action, "ValueUseTransaction.begin(selector)") != 1 or
        countPattern(action, ".form = .setcc_eax_compare_operand") != 1 or
        countPattern(action, ".setcc_eax_compare =") != 1 or
        countPattern(action, ".register(") != 1 or
        countPattern(action, ".seal()") != 1 or
        countPattern(action, ".beginAccumulatorSession()") != 1 or
        countPattern(action, ".prepare()") != 1 or
        countPattern(action, ".materializeAll()") != 1 or
        countPattern(action, ".preparedView(") != 1 or
        countPattern(action, ".executePreparedAction(") != 1 or
        countPattern(action, ".commit()") != 1 or
        countPattern(action, "AccumulatorDefinitionTransaction.begin(") != 0 or
        countPattern(action, "resolveValue(") != 0 or
        countPattern(action, "valueLoc(") != 0)
    {
        return error.ValueUseSetccEaxCompareProductionAllowlistMismatch;
    }

    const mapper_required = [_][]const u8{
        "failedRequestIs(lhs_request)",
        "ValueUseUnresolvedSource",
        "ValueUseSetccEaxCompareWidthUnsupported",
        "ValueUseSetccEaxCompareLocationUnsupported",
        "composed-block-icmp-lhs",
        "composed-block-icmp-lhs-width",
        "composed-block-icmp-lhs-loc",
    };
    for (mapper_required) |pattern| {
        if (std.mem.indexOf(u8, mapper, pattern) == null)
            return error.ValueUseSetccEaxCompareDiagnosticMapperMismatch;
    }
    if (countPattern(mapper, "failedRequestIs(") != 1 or
        countPattern(mapper, "resolveValue(") != 0 or
        countPattern(mapper, "valueLoc(") != 0)
    {
        return error.ValueUseSetccEaxCompareDiagnosticMapperMismatch;
    }

    for (bodies) |body| {
        const body_source = source[body.start..body.end];
        var contains_marker = false;
        for (production_markers) |pattern| {
            if (std.mem.indexOf(u8, body_source, pattern) != null) contains_marker = true;
        }
        if (!contains_marker) continue;
        if (!std.mem.eql(u8, body.name, "lowerSetccEaxCompare") and
            !std.mem.eql(u8, body.name, "setccEaxCompareDiagnostic"))
        {
            return error.ValueUseSetccEaxCompareProductionAllowlistMismatch;
        }
    }
}

pub fn validateCurrentHomeSignBitProductionSites(
    source_name: []const u8,
    source: [:0]const u8,
) !void {
    const production_markers = [_][]const u8{
        ".form = .current_home_sign_bit_operand",
        ".current_home_sign_bit =",
        "ValueUseCurrentHomeSignBitWidthUnsupported",
        "ValueUseCurrentHomeSignBitLocationUnsupported",
        "isCurrentHomeSignBitIcmp(",
    };
    var has_wiring = false;
    for (production_markers) |pattern| {
        if (std.mem.indexOf(u8, source, pattern) != null) has_wiring = true;
    }
    if (!has_wiring) return;
    if (!std.mem.eql(u8, source_name, "composed_selector_icmp.zig"))
        return error.ValueUseCurrentHomeSignBitProductionWiringForbidden;

    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const action_body = functionBodyNamed(bodies, "lowerCurrentHomeSignBitIcmp") orelse
        return error.ValueUseCurrentHomeSignBitProductionAllowlistMismatch;
    const mapper_body = functionBodyNamed(bodies, "currentHomeSignBitDiagnostic") orelse
        return error.ValueUseCurrentHomeSignBitProductionAllowlistMismatch;
    const dispatch_body = functionBodyNamed(bodies, "lowerIcmp") orelse
        return error.ValueUseCurrentHomeSignBitProductionAllowlistMismatch;
    const action = source[action_body.start..action_body.end];
    const mapper = source[mapper_body.start..mapper_body.end];
    const dispatch = source[dispatch_body.start..dispatch_body.end];

    const scratch_dispatch = std.mem.indexOf(u8, dispatch, "classifyScratchCompare(icmp)") orelse
        return error.ValueUseCurrentHomeSignBitDispatchMismatch;
    const exact_dispatch = std.mem.indexOf(
        u8,
        dispatch,
        "const exact_ei_narrow = isExactEiNarrowIcmp(selector, icmp);",
    ) orelse return error.ValueUseCurrentHomeSignBitDispatchMismatch;
    const current_dispatch = std.mem.indexOf(
        u8,
        dispatch,
        "isCurrentHomeEqZeroIcmp(icmp)",
    ) orelse return error.ValueUseCurrentHomeSignBitDispatchMismatch;
    const setcc_dispatch = std.mem.indexOf(
        u8,
        dispatch,
        "isSetccEaxCompareIcmp(icmp)",
    ) orelse return error.ValueUseCurrentHomeSignBitDispatchMismatch;
    const sign_bit_dispatch = std.mem.indexOf(
        u8,
        dispatch,
        "ValueUseTransaction.isCurrentHomeSignBitIcmp(icmp)",
    ) orelse return error.ValueUseCurrentHomeSignBitDispatchMismatch;
    const legacy_begin = std.mem.indexOf(
        u8,
        dispatch,
        "AccumulatorDefinitionTransaction.begin(selector)",
    ) orelse return error.ValueUseCurrentHomeSignBitDispatchMismatch;
    if (!(scratch_dispatch < exact_dispatch and exact_dispatch < current_dispatch and
        current_dispatch < setcc_dispatch and setcc_dispatch < sign_bit_dispatch and
        sign_bit_dispatch < legacy_begin) or
        countPattern(dispatch, "ValueUseTransaction.isCurrentHomeSignBitIcmp(icmp)") != 1 or
        countPattern(dispatch, "lowerCurrentHomeSignBitIcmp(selector, result_name, icmp)") != 1 or
        countPattern(dispatch, "AccumulatorDefinitionTransaction.begin(selector)") != 1 or
        countPattern(dispatch, "ValueUseTransaction.begin(selector)") != 0 or
        countPattern(dispatch, "emitValueIntoEax(selector, icmp.lhs)") != 0 or
        countPattern(dispatch, "emitValueIntoRax(selector, icmp.lhs)") != 0)
    {
        return error.ValueUseCurrentHomeSignBitDispatchMismatch;
    }

    if (countPattern(action, "ValueUseTransaction.begin(selector)") != 1 or
        countPattern(action, ".form = .current_home_sign_bit_operand") != 1 or
        countPattern(action, ".current_home_sign_bit =") != 1 or
        countPattern(action, ".register(") != 1 or
        countPattern(action, ".seal()") != 1 or
        countPattern(action, ".beginAccumulatorSession()") != 1 or
        countPattern(action, ".prepare()") != 1 or
        countPattern(action, ".materializeAll()") != 1 or
        countPattern(action, ".preparedView(") != 1 or
        countPattern(action, ".executePreparedAction(") != 1 or
        countPattern(action, ".commit()") != 1 or
        countPattern(action, "AccumulatorDefinitionTransaction.begin(") != 0 or
        countPattern(action, "resolveValue(") != 0 or
        countPattern(action, "valueLoc(") != 0 or
        countPattern(action, ".eax") != 0 or
        countPattern(action, ".rax") != 0 or
        countPattern(action, ".spill64") != 0 or
        countPattern(action, ".spill128") != 0)
    {
        return error.ValueUseCurrentHomeSignBitProductionAllowlistMismatch;
    }

    const mapper_required = [_][]const u8{
        "failedRequestIs(lhs_request)",
        "ValueUseUnresolvedSource",
        "ValueUseCurrentHomeSignBitWidthUnsupported",
        "ValueUseCurrentHomeSignBitLocationUnsupported",
        "composed-block-icmp-lhs",
        "composed-block-icmp-lhs-width",
        "composed-block-icmp-lhs-loc",
    };
    for (mapper_required) |pattern| {
        if (std.mem.indexOf(u8, mapper, pattern) == null)
            return error.ValueUseCurrentHomeSignBitDiagnosticMapperMismatch;
    }
    if (countPattern(mapper, "failedRequestIs(") != 1 or
        countPattern(mapper, "resolveValue(") != 0 or
        countPattern(mapper, "valueLoc(") != 0)
    {
        return error.ValueUseCurrentHomeSignBitDiagnosticMapperMismatch;
    }

    for (bodies) |body| {
        const body_source = source[body.start..body.end];
        var contains_marker = false;
        for (production_markers) |pattern| {
            if (std.mem.indexOf(u8, body_source, pattern) != null) contains_marker = true;
        }
        if (!contains_marker) continue;
        if (!std.mem.eql(u8, body.name, "lowerCurrentHomeSignBitIcmp") and
            !std.mem.eql(u8, body.name, "currentHomeSignBitDiagnostic") and
            !std.mem.eql(u8, body.name, "lowerIcmp"))
        {
            return error.ValueUseCurrentHomeSignBitProductionAllowlistMismatch;
        }
    }
}

pub fn validateI128PairProductionSites(source_name: []const u8, source: [:0]const u8) !void {
    const production_markers = [_][]const u8{
        ".form = .i128_icmp_pair_operand",
        ".prepared_action = .{ .i128_eq_min",
        ".prepared_action = .{ .i128_sign_bit",
        "ValueUseI128PairWidthUnsupported",
        "ValueUseI128PairLocationUnsupported",
    };
    var has_wiring = false;
    for (production_markers) |pattern| {
        if (std.mem.indexOf(u8, source, pattern) != null) has_wiring = true;
    }
    if (!has_wiring) return;
    if (!std.mem.eql(u8, source_name, "composed_selector_icmp.zig"))
        return error.ValueUseI128PairProductionWiringForbidden;

    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const eq_body = functionBodyNamed(bodies, "lowerI128EqMinIcmp") orelse
        return error.ValueUseI128PairProductionAllowlistMismatch;
    const sign_body = functionBodyNamed(bodies, "lowerI128SignBitIcmp") orelse
        return error.ValueUseI128PairProductionAllowlistMismatch;
    const mapper_body = functionBodyNamed(bodies, "i128PairDiagnostic") orelse
        return error.ValueUseI128PairProductionAllowlistMismatch;
    const dispatch_body = functionBodyNamed(bodies, "lowerIcmp") orelse
        return error.ValueUseI128PairProductionAllowlistMismatch;
    const eq = source[eq_body.start..eq_body.end];
    const sign = source[sign_body.start..sign_body.end];
    const mapper = source[mapper_body.start..mapper_body.end];
    const dispatch = source[dispatch_body.start..dispatch_body.end];

    const action_functions = [_][]const u8{ eq, sign };
    for (action_functions) |action| {
        if (countPattern(action, "ValueUseTransaction.begin(selector)") != 1 or
            countPattern(action, ".form = .i128_icmp_pair_operand") != 1 or
            countPattern(action, ".register(") != 1 or
            countPattern(action, ".seal()") != 1 or
            countPattern(action, ".beginAccumulatorSession()") != 1 or
            countPattern(action, ".prepare()") != 1 or
            countPattern(action, ".materializeAll()") != 1 or
            countPattern(action, ".preparedView(") != 1 or
            countPattern(action, ".executePreparedAction(") != 1 or
            countPattern(action, ".commit()") != 1 or
            countPattern(action, "AccumulatorDefinitionTransaction.begin(") != 0 or
            countPattern(action, "resolveValue(") != 0 or
            countPattern(action, "valueLoc(") != 0 or
            countPattern(action, "resolvePairValue(") != 0 or
            countPattern(action, "materializePairValue(") != 0 or
            countPattern(action, "emitPairHighLaneIntoRax(") != 0)
        {
            return error.ValueUseI128PairProductionAllowlistMismatch;
        }
    }
    if (countPattern(eq, ".prepared_action = .{ .i128_eq_min") != 1 or
        countPattern(eq, ".prepared_action = .{ .i128_sign_bit") != 0 or
        countPattern(sign, ".prepared_action = .{ .i128_sign_bit") != 1 or
        countPattern(sign, ".prepared_action = .{ .i128_eq_min") != 0 or
        countPattern(source, ".form = .i128_icmp_pair_operand") != 2 or
        countPattern(source, ".prepared_action = .{ .i128_eq_min") != 1 or
        countPattern(source, ".prepared_action = .{ .i128_sign_bit") != 1)
    {
        return error.ValueUseI128PairProductionAllowlistMismatch;
    }

    const mapper_required = [_][]const u8{
        "transaction.actionDiagnostic()",
        "transaction.failedRequestIs(lhs_request)",
        "ValueUseUnresolvedSource",
        "UnsupportedCodegenValue",
        "ValueUseI128PairWidthUnsupported",
        "ValueUseI128PairLocationUnsupported",
        "composed-block-icmp-lhs",
        "composed-block-icmp-lhs-width",
        "composed-block-icmp-lhs-loc",
    };
    for (mapper_required) |pattern| {
        if (std.mem.indexOf(u8, mapper, pattern) == null)
            return error.ValueUseI128PairDiagnosticMapperMismatch;
    }
    if (countPattern(mapper, "failedRequestIs(") != 1 or
        countPattern(mapper, "resolveValue(") != 0 or
        countPattern(mapper, "valueLoc(") != 0)
    {
        return error.ValueUseI128PairDiagnosticMapperMismatch;
    }

    const current_sign_bit = std.mem.indexOf(
        u8,
        dispatch,
        "ValueUseTransaction.isCurrentHomeSignBitIcmp(icmp)",
    ) orelse return error.ValueUseI128PairDispatchMismatch;
    const eq_dispatch = std.mem.indexOf(
        u8,
        dispatch,
        "ValueUseTransaction.isI128EqMinIcmp(icmp)",
    ) orelse return error.ValueUseI128PairDispatchMismatch;
    const sign_dispatch = std.mem.indexOf(
        u8,
        dispatch,
        "ValueUseTransaction.isI128SignBitIcmp(icmp)",
    ) orelse return error.ValueUseI128PairDispatchMismatch;
    const legacy_begin = std.mem.indexOf(
        u8,
        dispatch,
        "AccumulatorDefinitionTransaction.begin(selector)",
    ) orelse return error.ValueUseI128PairDispatchMismatch;
    if (!(current_sign_bit < eq_dispatch and eq_dispatch < sign_dispatch and
        sign_dispatch < legacy_begin) or
        countPattern(dispatch, "ValueUseTransaction.isI128EqMinIcmp(icmp)") != 1 or
        countPattern(dispatch, "ValueUseTransaction.isI128SignBitIcmp(icmp)") != 1 or
        countPattern(dispatch, "lowerI128EqMinIcmp(selector, result_name, icmp)") != 1 or
        countPattern(dispatch, "lowerI128SignBitIcmp(selector, result_name, icmp)") != 1 or
        countPattern(dispatch, "AccumulatorDefinitionTransaction.begin(selector)") != 1 or
        countPattern(dispatch, "ValueUseTransaction.begin(selector)") != 0 or
        countPattern(dispatch, "resolvePairValue(") != 0 or
        countPattern(dispatch, "materializePairValue(") != 0 or
        countPattern(dispatch, "emitPairHighLaneIntoRax(") != 0)
    {
        return error.ValueUseI128PairDispatchMismatch;
    }

    for (bodies) |body| {
        const body_source = source[body.start..body.end];
        var contains_marker = false;
        for (production_markers) |pattern| {
            if (std.mem.indexOf(u8, body_source, pattern) != null) contains_marker = true;
        }
        if (!contains_marker) continue;
        if (!std.mem.eql(u8, body.name, "lowerI128EqMinIcmp") and
            !std.mem.eql(u8, body.name, "lowerI128SignBitIcmp") and
            !std.mem.eql(u8, body.name, "i128PairDiagnostic"))
        {
            return error.ValueUseI128PairProductionAllowlistMismatch;
        }
    }
}

pub fn validateLoadDiagnosticMappingProductionSites(source_name: []const u8, source: [:0]const u8) !void {
    const semantic_errors = [_][]const u8{
        "ValueUseLoadOrdinaryStackWidth",
        "ValueUseLoadOrdinaryStackArrayWidth",
        "ValueUseLoadOrdinaryPointerWidth",
        "ValueUseLoadOrdinaryPointerRejected",
        "ValueUseLoadReadonlyPointerProvenance",
        "ValueUseLoadReadonlyPointerSpill",
        "ValueUseLoadReadonlyPointerAlias",
        "ValueUseLoadReadonlyWidth",
        "ValueUseLoadReadonlyPairUnavailable",
        "ValueUseLoadReadonlyTableOffset",
        "ValueUseLoadReadonlyTableType",
        "ValueUseLoadReadonlyTableSpill",
    };
    var has_mapping = false;
    for (semantic_errors) |pattern| {
        if (std.mem.indexOf(u8, source, pattern) != null) has_mapping = true;
    }
    if (!has_mapping) return;
    if (!std.mem.eql(u8, source_name, "composed_selector_memory.zig"))
        return error.ValueUseLoadDiagnosticMappingOutsideAllowlist;

    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    for (bodies) |body| {
        const function_source = source[body.start..body.end];
        var body_has_mapping = false;
        for (semantic_errors) |pattern| {
            if (std.mem.indexOf(u8, function_source, pattern) != null) body_has_mapping = true;
        }
        if (!body_has_mapping) continue;
        const approved = std.mem.eql(u8, body.name, "lowerLoad") or
            std.mem.eql(u8, body.name, "ordinaryLoadValueUseDiagnostic") or
            std.mem.eql(u8, body.name, "lowerReadOnlyPointerIntegerLoad") or
            std.mem.eql(u8, body.name, "readOnlyPointerLoadValueUseDiagnostic") or
            std.mem.eql(u8, body.name, "lowerReadOnlyTableLoad") or
            std.mem.eql(u8, body.name, "readOnlyTableLoadValueUseDiagnostic");
        if (!approved) return error.ValueUseLoadDiagnosticMappingOutsideAllowlist;
        const forbidden_home_queries = [_][]const u8{
            "valueLoc(",
            "storePointerDiagnosticClass(",
            "switch (ptr)",
            "switch (current)",
            ".stack_scalar =>",
            ".stack128 =>",
            ".stack_i32_array =>",
            ".stack_i32_ptr =>",
            ".arg32 =>",
            ".arg64 =>",
            ".arg128 =>",
            ".scratch32 =>",
            ".scratch64 =>",
            ".scratch128 =>",
            ".eax =>",
            ".rax =>",
            ".xmm =>",
            ".spill64 =>",
            ".spill128 =>",
            ".spill_fp =>",
            ".spill_vector =>",
            ".aggregate_sse =>",
            "== .stack_scalar",
            "== .stack128",
            "== .stack_i32_array",
            "== .stack_i32_ptr",
            "== .arg64",
            "== .spill64",
        };
        for (forbidden_home_queries) |pattern| {
            if (std.mem.indexOf(u8, function_source, pattern) != null)
                return error.ValueUseLoadConsumerHomeClassification;
        }
    }
}

pub fn validateDormantLoadActionProductionSites(source_name: []const u8, source: [:0]const u8) !void {
    if (std.mem.indexOf(u8, source, ".setLoadTestFailure(") != null)
        return error.ValueUseLoadTestHookInProduction;
    const address_pattern = ".load_address";
    const scalar_pattern = ".load_scalar";
    const pair_pattern = ".load_readonly_pair";
    const alias_pattern = ".load_stack_i128_alias";
    const table_pattern = ".load_readonly_table_i16";
    const address_total = countPattern(source, address_pattern);
    const scalar_total = countPattern(source, scalar_pattern);
    const pair_total = countPattern(source, pair_pattern);
    const alias_total = countPattern(source, alias_pattern);
    const table_total = countPattern(source, table_pattern);
    const action_total = scalar_total + pair_total + alias_total + table_total;
    if (address_total == 0 and action_total == 0) return;
    if (!std.mem.eql(u8, source_name, "composed_selector_memory.zig"))
        return error.ValueUseLoadActionNotWired;

    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const ordinary_body = functionBodyNamed(bodies, "lowerLoad") orelse
        return error.ValueUseLoadActionNotWired;
    const readonly_body = functionBodyNamed(bodies, "lowerReadOnlyPointerIntegerLoad") orelse
        return error.ValueUseLoadActionNotWired;
    const table_dispatch_body = functionBodyNamed(bodies, "lowerReadOnlyTableLoad") orelse
        return error.ValueUseLoadActionNotWired;
    const table_i16_body = functionBodyNamed(bodies, "lowerReadOnlyTableI16Transactional") orelse
        return error.ValueUseLoadActionNotWired;
    const ordinary_source = source[ordinary_body.start..ordinary_body.end];
    const readonly_source = source[readonly_body.start..readonly_body.end];
    const table_dispatch_source = source[table_dispatch_body.start..table_dispatch_body.end];
    const table_i16_source = source[table_i16_body.start..table_i16_body.end];
    const table_branch =
        "if (ptr.shape == .i16_128 and ptr.offset == 0 and load.ty.eql(.{ .int = 16 }))";
    const table_branch_index = std.mem.indexOf(u8, table_dispatch_source, table_branch) orelse
        return error.ValueUseLoadActionNotWired;
    const table_call_index = std.mem.indexOf(
        u8,
        table_dispatch_source,
        "return lowerReadOnlyTableI16Transactional(selector, result_name, load);",
    ) orelse return error.ValueUseLoadActionNotWired;
    const direct_materialization_index = std.mem.indexOf(
        u8,
        table_dispatch_source,
        "selector_state.materializeLocIntoLoc(",
    ) orelse return error.ValueUseLoadActionNotWired;
    const double_type_index = std.mem.indexOf(
        u8,
        table_dispatch_source,
        "if (load.ty != .double)",
    ) orelse return error.ValueUseLoadActionNotWired;
    if (countPattern(ordinary_source, address_pattern) != 1 or
        countPattern(ordinary_source, scalar_pattern) != 1 or
        countPattern(ordinary_source, alias_pattern) != 1 or
        countPattern(ordinary_source, pair_pattern) != 0 or
        countPattern(ordinary_source, table_pattern) != 0 or
        countPattern(ordinary_source, "ValueUseTransaction.begin(selector)") != 1 or
        countPattern(ordinary_source, ".executePreparedAction(") != 1 or
        countPattern(ordinary_source, ".commit()") != 1 or
        countPattern(readonly_source, address_pattern) != 1 or
        countPattern(readonly_source, scalar_pattern) != 1 or
        countPattern(readonly_source, pair_pattern) != 1 or
        countPattern(readonly_source, alias_pattern) != 0 or
        countPattern(readonly_source, table_pattern) != 0 or
        countPattern(readonly_source, "ValueUseTransaction.begin(selector)") != 1 or
        countPattern(readonly_source, ".executePreparedAction(") != 1 or
        countPattern(readonly_source, ".commit()") != 1 or
        countPattern(table_dispatch_source, address_pattern) != 0 or
        countPattern(table_dispatch_source, table_pattern) != 0 or
        countPattern(table_dispatch_source, "ValueUseTransaction.begin(selector)") != 0 or
        countPattern(table_dispatch_source, "selector_state.materializeLocIntoLoc(") != 1 or
        countPattern(table_dispatch_source, "selector_state.clobberXmmReg(") != 1 or
        countPattern(table_i16_source, address_pattern) != 1 or
        countPattern(table_i16_source, table_pattern) != 1 or
        countPattern(table_i16_source, scalar_pattern) != 0 or
        countPattern(table_i16_source, pair_pattern) != 0 or
        countPattern(table_i16_source, alias_pattern) != 0 or
        countPattern(table_i16_source, "ValueUseTransaction.begin(selector)") != 1 or
        countPattern(table_i16_source, ".executePreparedAction(") != 1 or
        countPattern(table_i16_source, ".commit()") != 1 or
        countPattern(source, "lowerReadOnlyTableI16Transactional(") != 2 or
        table_branch_index >= table_call_index or
        table_call_index >= direct_materialization_index or
        direct_materialization_index >= double_type_index or
        address_total != 3 or scalar_total != 2 or alias_total != 1 or
        pair_total != 1 or table_total != 1)
    {
        return error.ValueUseLoadActionNotWired;
    }
}

pub fn validateAccumulatorCompositionProductionSites(source_name: []const u8, source: [:0]const u8) !void {
    const composition_api = [_][]const u8{
        "beginAccumulatorSession(",
        "prepareAccumulator(",
        "prepareAccumulatorCallBeforeArguments(",
        "finishAccumulatorCallPreparationAfterArguments(",
        "materializeAccumulator(",
        "spillAccumulatorValue(",
        "defineAccumulatorResult(",
        "finalizeAccumulatorResult(",
        "commitAccumulatorSession(",
        "AccumulatorDefinitionSession.init(",
    };
    var has_composition_api = false;
    for (composition_api) |pattern| {
        if (std.mem.indexOf(u8, source, pattern) != null) has_composition_api = true;
    }
    if (!has_composition_api) return;
    if (std.mem.eql(u8, source_name, "composed_selector_icmp.zig")) {
        var body_storage: [max_function_bodies]FunctionBody = undefined;
        const bodies = try collectFunctionBodies(source, &body_storage);
        const action_body = functionBodyNamed(bodies, "lowerScratchCompare") orelse
            return error.ValueUseAccumulatorCompositionAllowlistMismatch;
        const current_home_body = functionBodyNamed(bodies, "lowerCurrentHomeEqZeroIcmp") orelse
            return error.ValueUseAccumulatorCompositionAllowlistMismatch;
        const setcc_body = functionBodyNamed(bodies, "lowerSetccEaxCompare") orelse
            return error.ValueUseAccumulatorCompositionAllowlistMismatch;
        const sign_bit_body = functionBodyNamed(bodies, "lowerCurrentHomeSignBitIcmp") orelse
            return error.ValueUseAccumulatorCompositionAllowlistMismatch;
        const i128_eq_min_body = functionBodyNamed(bodies, "lowerI128EqMinIcmp") orelse
            return error.ValueUseAccumulatorCompositionAllowlistMismatch;
        const i128_sign_bit_body = functionBodyNamed(bodies, "lowerI128SignBitIcmp") orelse
            return error.ValueUseAccumulatorCompositionAllowlistMismatch;
        const scratch_source = source[action_body.start..action_body.end];
        const current_home_source = source[current_home_body.start..current_home_body.end];
        const setcc_source = source[setcc_body.start..setcc_body.end];
        const sign_bit_source = source[sign_bit_body.start..sign_bit_body.end];
        const i128_eq_min_source = source[i128_eq_min_body.start..i128_eq_min_body.end];
        const i128_sign_bit_source = source[i128_sign_bit_body.start..i128_sign_bit_body.end];
        if (countPattern(scratch_source, "beginAccumulatorSession(") != 1 or
            countPattern(scratch_source, "ValueUseTransaction.begin(selector)") != 1 or
            countPattern(scratch_source, ".executePreparedAction(") != 1 or
            countPattern(scratch_source, ".commit()") != 1 or
            countPattern(scratch_source, "AccumulatorDefinitionTransaction.begin(") != 0 or
            countPattern(current_home_source, "beginAccumulatorSession(") != 1 or
            countPattern(current_home_source, "ValueUseTransaction.begin(selector)") != 1 or
            countPattern(current_home_source, ".executePreparedAction(") != 1 or
            countPattern(current_home_source, ".commit()") != 1 or
            countPattern(current_home_source, "AccumulatorDefinitionTransaction.begin(") != 0 or
            countPattern(setcc_source, "beginAccumulatorSession(") != 1 or
            countPattern(setcc_source, "ValueUseTransaction.begin(selector)") != 1 or
            countPattern(setcc_source, ".executePreparedAction(") != 1 or
            countPattern(setcc_source, ".commit()") != 1 or
            countPattern(setcc_source, "AccumulatorDefinitionTransaction.begin(") != 0 or
            countPattern(sign_bit_source, "beginAccumulatorSession(") != 1 or
            countPattern(sign_bit_source, "ValueUseTransaction.begin(selector)") != 1 or
            countPattern(sign_bit_source, ".executePreparedAction(") != 1 or
            countPattern(sign_bit_source, ".commit()") != 1 or
            countPattern(sign_bit_source, "AccumulatorDefinitionTransaction.begin(") != 0 or
            countPattern(i128_eq_min_source, "beginAccumulatorSession(") != 1 or
            countPattern(i128_eq_min_source, "ValueUseTransaction.begin(selector)") != 1 or
            countPattern(i128_eq_min_source, ".executePreparedAction(") != 1 or
            countPattern(i128_eq_min_source, ".commit()") != 1 or
            countPattern(i128_eq_min_source, "AccumulatorDefinitionTransaction.begin(") != 0 or
            countPattern(i128_sign_bit_source, "beginAccumulatorSession(") != 1 or
            countPattern(i128_sign_bit_source, "ValueUseTransaction.begin(selector)") != 1 or
            countPattern(i128_sign_bit_source, ".executePreparedAction(") != 1 or
            countPattern(i128_sign_bit_source, ".commit()") != 1 or
            countPattern(i128_sign_bit_source, "AccumulatorDefinitionTransaction.begin(") != 0 or
            countPattern(source, "beginAccumulatorSession(") != 6)
        {
            return error.ValueUseAccumulatorCompositionAllowlistMismatch;
        }
        return;
    }
    if (std.mem.eql(u8, source_name, "composed_selector_scalar.zig")) {
        var body_storage: [max_function_bodies]FunctionBody = undefined;
        const bodies = try collectFunctionBodies(source, &body_storage);
        const body = functionBodyNamed(bodies, "lowerAccumulatorScalarCast") orelse
            return error.ValueUseAccumulatorCompositionAllowlistMismatch;
        const function_source = source[body.start..body.end];
        if (countPattern(function_source, "beginAccumulatorSession(") != 1 or
            countPattern(function_source, "ValueUseTransaction.begin(selector)") != 1 or
            countPattern(function_source, ".executePreparedAction(") != 1 or
            countPattern(function_source, ".commit()") != 1 or
            countPattern(function_source, "AccumulatorDefinitionTransaction.begin(") != 0 or
            countPattern(source, "beginAccumulatorSession(") != 1)
        {
            return error.ValueUseAccumulatorCompositionAllowlistMismatch;
        }
        return;
    }
    if (std.mem.eql(u8, source_name, "composed_selector_memory.zig")) {
        var body_storage: [max_function_bodies]FunctionBody = undefined;
        const bodies = try collectFunctionBodies(source, &body_storage);
        var classified_count: usize = 0;
        for (bodies) |body| {
            const function_source = source[body.start..body.end];
            var contains_api = false;
            for (composition_api) |pattern| {
                if (std.mem.indexOf(u8, function_source, pattern) != null) contains_api = true;
            }
            if (!contains_api) continue;
            const allowed = std.mem.eql(u8, body.name, "lowerLoad") or
                std.mem.eql(u8, body.name, "lowerReadOnlyPointerIntegerLoad");
            if (!allowed or
                countPattern(function_source, "beginAccumulatorSession(") != 1 or
                countPattern(function_source, "defineAccumulatorResult(") != 1 or
                countPattern(function_source, "finalizeAccumulatorResult(") != 1 or
                countPattern(function_source, "ValueUseTransaction.begin(selector)") != 1 or
                countPattern(function_source, "transaction.commit()") != 1 or
                countPattern(function_source, "prepareAccumulator(") != 0 or
                countPattern(function_source, "prepareAccumulatorCallBeforeArguments(") != 0 or
                countPattern(function_source, "finishAccumulatorCallPreparationAfterArguments(") != 0 or
                countPattern(function_source, "materializeAccumulator(") != 0 or
                countPattern(function_source, "spillAccumulatorValue(") != 0 or
                countPattern(function_source, "commitAccumulatorSession(") != 0 or
                countPattern(function_source, "AccumulatorDefinitionSession.init(") != 0 or
                countPattern(function_source, "AccumulatorDefinitionTransaction.begin(") != 0)
            {
                return error.ValueUseAccumulatorCompositionAllowlistMismatch;
            }
            classified_count += 1;
        }
        if (classified_count != 2)
            return error.ValueUseAccumulatorCompositionAllowlistMismatch;
        return;
    }
    if (!std.mem.eql(u8, source_name, "composed_selector_calls.zig"))
        return error.ValueUseAccumulatorCompositionOutsideAllowlist;

    const allowed_functions = [_][]const u8{
        "lowerAbsI32",
        "lowerAbsI64",
        "lowerCtlzI32",
        "lowerCtlzI52",
        "lowerCtlzI64",
        "lowerCttzI32",
        "lowerCttzI64",
    };
    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    var seen = [_]bool{false} ** allowed_functions.len;
    for (bodies) |body| {
        const function_source = source[body.start..body.end];
        var contains_api = false;
        for (composition_api) |pattern| {
            if (std.mem.indexOf(u8, function_source, pattern) != null) contains_api = true;
        }
        if (!contains_api) continue;

        var allowed_index: ?usize = null;
        for (allowed_functions, 0..) |function_name, index| {
            if (std.mem.eql(u8, body.name, function_name)) allowed_index = index;
        }
        const index = allowed_index orelse
            return error.ValueUseAccumulatorCompositionOutsideAllowlist;
        if (seen[index]) return error.ValueUseAccumulatorCompositionAllowlistMismatch;
        seen[index] = true;

        if (countPattern(function_source, "beginAccumulatorSession(") != 1 or
            countPattern(function_source, "prepareAccumulator(") != 1 or
            countPattern(function_source, "defineAccumulatorResult(") != 1 or
            countPattern(function_source, "finalizeAccumulatorResult(") != 1 or
            countPattern(function_source, "ValueUseTransaction.begin(selector)") != 1 or
            countPattern(function_source, "transaction.commit()") != 1 or
            countPattern(function_source, "prepareAccumulatorCallBeforeArguments(") != 0 or
            countPattern(function_source, "finishAccumulatorCallPreparationAfterArguments(") != 0 or
            countPattern(function_source, "materializeAccumulator(") != 0 or
            countPattern(function_source, "spillAccumulatorValue(") != 0 or
            countPattern(function_source, "commitAccumulatorSession(") != 0 or
            countPattern(function_source, "AccumulatorDefinitionSession.init(") != 0 or
            countPattern(function_source, "AccumulatorDefinitionTransaction.begin(") != 0 or
            countPattern(function_source, "emitValueIntoScratch(") != 0)
        {
            return error.ValueUseAccumulatorCompositionAllowlistMismatch;
        }
    }

    // The real production source must contain the complete seven-function
    // pilot. Small guard fixtures may intentionally exercise one function.
    if (std.mem.indexOf(u8, source, "pub fn lowerAbsI32(selector: *ComposedBlockSelector") != null) {
        for (seen) |present| if (!present)
            return error.ValueUseAccumulatorCompositionAllowlistMismatch;
    }
}

pub fn validateFailureProvenanceProductionSites(source_name: []const u8, source: [:0]const u8) !void {
    const query_count = countPattern(source, ".failedRequestIs(");
    if (query_count == 0) return;
    if (std.mem.eql(u8, source_name, "composed_selector_scalar.zig")) {
        var body_storage: [max_function_bodies]FunctionBody = undefined;
        const bodies = try collectFunctionBodies(source, &body_storage);
        const mapper = functionBodyNamed(bodies, "scalarCastValueUseDiagnostic") orelse
            return error.ValueUseFailureProvenanceOutsideAllowlist;
        if (countPattern(source[mapper.start..mapper.end], ".failedRequestIs(") != 1 or
            query_count != 1)
        {
            return error.ValueUseFailureProvenanceAllowlistMismatch;
        }
        return;
    }
    if (std.mem.eql(u8, source_name, "composed_selector_icmp.zig")) {
        var body_storage: [max_function_bodies]FunctionBody = undefined;
        const bodies = try collectFunctionBodies(source, &body_storage);
        const scratch_mapper = functionBodyNamed(bodies, "scratchCompareDiagnostic") orelse
            return error.ValueUseFailureProvenanceOutsideAllowlist;
        const current_home_mapper = functionBodyNamed(bodies, "currentHomeEqZeroDiagnostic") orelse
            return error.ValueUseFailureProvenanceOutsideAllowlist;
        const setcc_mapper = functionBodyNamed(bodies, "setccEaxCompareDiagnostic") orelse
            return error.ValueUseFailureProvenanceOutsideAllowlist;
        const sign_bit_mapper = functionBodyNamed(bodies, "currentHomeSignBitDiagnostic") orelse
            return error.ValueUseFailureProvenanceOutsideAllowlist;
        const i128_pair_mapper = functionBodyNamed(bodies, "i128PairDiagnostic") orelse
            return error.ValueUseFailureProvenanceOutsideAllowlist;
        if (countPattern(source[scratch_mapper.start..scratch_mapper.end], ".failedRequestIs(") != 2 or
            countPattern(source[current_home_mapper.start..current_home_mapper.end], ".failedRequestIs(") != 1 or
            countPattern(source[setcc_mapper.start..setcc_mapper.end], ".failedRequestIs(") != 1 or
            countPattern(source[sign_bit_mapper.start..sign_bit_mapper.end], ".failedRequestIs(") != 1 or
            countPattern(source[i128_pair_mapper.start..i128_pair_mapper.end], ".failedRequestIs(") != 1 or
            query_count != 6)
        {
            return error.ValueUseFailureProvenanceAllowlistMismatch;
        }
        return;
    }
    if (std.mem.eql(u8, source_name, "composed_selector_memory.zig")) {
        var body_storage: [max_function_bodies]FunctionBody = undefined;
        const bodies = try collectFunctionBodies(source, &body_storage);
        var classified_count: usize = 0;
        for (bodies) |body| {
            const function_source = source[body.start..body.end];
            const body_count = countPattern(function_source, ".failedRequestIs(");
            if (body_count == 0) continue;
            const approved = std.mem.eql(u8, body.name, "lowerLoad") or
                std.mem.eql(u8, body.name, "ordinaryLoadValueUseDiagnostic") or
                std.mem.eql(u8, body.name, "lowerReadOnlyPointerIntegerLoad") or
                std.mem.eql(u8, body.name, "readOnlyPointerLoadValueUseDiagnostic") or
                std.mem.eql(u8, body.name, "lowerReadOnlyTableLoad") or
                std.mem.eql(u8, body.name, "readOnlyTableLoadValueUseDiagnostic");
            if (!approved or std.mem.indexOf(u8, function_source, "ValueUseLoad") == null)
                return error.ValueUseFailureProvenanceOutsideAllowlist;
            classified_count += body_count;
        }
        if (classified_count != query_count)
            return error.ValueUseFailureProvenanceAllowlistMismatch;
        return;
    }
    if (!std.mem.eql(u8, source_name, "composed_selector_calls.zig"))
        return error.ValueUseFailureProvenanceOutsideAllowlist;

    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const mapper = functionBodyNamed(bodies, "inlineMemcpyValueUseDiagnostic") orelse
        return error.ValueUseFailureProvenanceOutsideAllowlist;
    if (countPattern(source[mapper.start..mapper.end], ".failedRequestIs(") != 3 or
        query_count != 3)
    {
        return error.ValueUseFailureProvenanceAllowlistMismatch;
    }
}

pub fn validateMemcpyActionProductionSites(source_name: []const u8, source: [:0]const u8) !void {
    const pointer_pattern = ".form = .memcpy_pointer";
    const length_pattern = ".form = .memcpy_length";
    const action_pattern = ".inline_memcpy";
    const pointer_total = countPattern(source, pointer_pattern);
    const length_total = countPattern(source, length_pattern);
    const action_total = countPattern(source, action_pattern);
    if (std.mem.indexOf(u8, source, ".setMemcpyTestFailure(") != null)
        return error.ValueUseMemcpyTestHookInProduction;
    if (!std.mem.eql(u8, source_name, "composed_selector_calls.zig")) {
        if (pointer_total != 0 or length_total != 0 or action_total != 0)
            return error.ValueUseMemcpyActionOutsideAllowlist;
        return;
    }

    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const body = functionBodyNamed(bodies, "lowerInlineMemcpy") orelse
        return error.ValueUseMemcpyActionAllowlistMismatch;
    const function_source = source[body.start..body.end];
    if (countPattern(function_source, pointer_pattern) != 2 or
        countPattern(function_source, length_pattern) != 1 or
        countPattern(function_source, action_pattern) != 1 or
        pointer_total != 2 or length_total != 1 or action_total != 1)
    {
        return error.ValueUseMemcpyActionAllowlistMismatch;
    }
    const operand_validation = std.mem.indexOf(u8, function_source, "if (dst.ty != .ptr") orelse
        return error.ValueUseMemcpyDispatchOrderingMismatch;
    const transaction_begin = std.mem.indexOf(u8, function_source, "ValueUseTransaction.begin(selector)") orelse
        return error.ValueUseMemcpyDispatchOrderingMismatch;
    if (operand_validation >= transaction_begin or
        countPattern(function_source, "ValueUseTransaction.begin(selector)") != 1 or
        countPattern(function_source, "spillLiveCallerClobbersForCall(") != 0 or
        countPattern(function_source, "emitValueIntoScratch(") != 0)
    {
        return error.ValueUseMemcpyDispatchOrderingMismatch;
    }
}

pub fn validateSwitchActionProductionSites(source_name: []const u8, source: [:0]const u8) !void {
    const form_pattern = ".form = .switch_condition";
    const action_pattern = ".switch_compare_chain = switch_action";
    const form_total = countPattern(source, form_pattern);
    const action_total = countPattern(source, action_pattern);
    if (!std.mem.eql(u8, source_name, "composed_selector_cfg.zig")) {
        if (form_total != 0 or action_total != 0) return error.ValueUseSwitchActionOutsideAllowlist;
        return;
    }

    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const body = functionBodyNamed(bodies, "lowerSwitch") orelse
        return error.ValueUseSwitchActionAllowlistMismatch;
    const function_source = source[body.start..body.end];
    if (countPattern(function_source, form_pattern) != 1 or
        countPattern(function_source, action_pattern) != 1 or
        form_total != 1 or action_total != 1)
    {
        return error.ValueUseSwitchActionAllowlistMismatch;
    }
    const phi_dispatch = std.mem.indexOf(u8, function_source, "if (has_phi_edge)") orelse
        return error.ValueUseSwitchActionDispatchOrderingMismatch;
    const ordinary_boundary = std.mem.indexOf(u8, function_source, "const exhaustive_case = maskedSwitchExhaustiveCaseIndex") orelse
        return error.ValueUseSwitchActionDispatchOrderingMismatch;
    const transaction_begin = std.mem.indexOf(u8, function_source, "ValueUseTransaction.begin(selector)") orelse
        return error.ValueUseSwitchActionDispatchOrderingMismatch;
    if (!(phi_dispatch < ordinary_boundary and ordinary_boundary < transaction_begin))
        return error.ValueUseSwitchActionDispatchOrderingMismatch;
}

pub fn validateBranchActionProductionSites(source_name: []const u8, source: [:0]const u8) !void {
    const form_pattern = ".form = .branch_condition";
    const action_pattern = ".prepared_action = .branch_condition";
    const total = countPattern(source, ".branch_condition");
    if (!std.mem.eql(u8, source_name, "composed_selector_cfg.zig")) {
        if (total != 0) return error.ValueUseBranchActionOutsideAllowlist;
        return;
    }

    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const body = functionBodyNamed(bodies, "emitBranchCondition") orelse
        return error.ValueUseBranchActionAllowlistMismatch;
    const function_source = source[body.start..body.end];
    if (countPattern(function_source, form_pattern) != 1 or
        countPattern(function_source, action_pattern) != 1 or
        countPattern(source, form_pattern) != 1 or
        countPattern(source, action_pattern) != 1 or
        total != 2)
    {
        return error.ValueUseBranchActionAllowlistMismatch;
    }
}

pub fn validateStoreActionProductionSites(source_name: []const u8, source: [:0]const u8) !void {
    const allowed = [_]struct { function: []const u8, pattern: []const u8 }{
        .{ .function = "lowerStoreScalarTransactional", .pattern = ".store_scalar" },
        .{ .function = "lowerStoreScalarTransactional", .pattern = ".store_immediate" },
        .{ .function = "lowerStoreI64Transactional", .pattern = ".store_i64" },
        .{ .function = "lowerStoreStackPointer", .pattern = ".store_stack_pointer" },
    };
    var total_store_actions: usize = 0;
    for (allowed) |entry| total_store_actions += countPattern(source, entry.pattern);
    if (!std.mem.eql(u8, source_name, "composed_selector_memory.zig")) {
        if (total_store_actions != 0) return error.ValueUseStoreActionOutsideAllowlist;
        return;
    }

    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    for (allowed) |entry| {
        const body = functionBodyNamed(bodies, entry.function) orelse
            return error.ValueUseStoreActionAllowlistMismatch;
        if (countPattern(source[body.start..body.end], entry.pattern) != 1 or
            countPattern(source, entry.pattern) != 1)
        {
            return error.ValueUseStoreActionAllowlistMismatch;
        }
    }
}
