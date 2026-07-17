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
pub fn validateValueUseAuthoritySource(source: [:0]const u8) !void {
    return validateValueUseAuthoritySourceWithVisibility(source, false);
}

pub fn validateValueUseAuthoritySourceWithVisibility(
    source: [:0]const u8,
    allow_technical_visibility: bool,
) !void {
    try validateNoFunctionFamilyPredicate(source, error.ValueUseFunctionPredicateForbidden);
    if ((!allow_technical_visibility and
        (std.mem.indexOf(u8, source, "pub const SemanticRole") != null or
            std.mem.indexOf(u8, source, "pub const OperandPhase") != null or
            std.mem.indexOf(u8, source, "pub const OrderedOperand") != null)) or
        std.mem.indexOf(u8, source, "semantic_priority") != null or
        std.mem.indexOf(u8, source, "ordering_priority") != null)
    {
        return error.ValueUseConsumerOrderingForbidden;
    }
    if ((!allow_technical_visibility and
        std.mem.indexOf(u8, source, "pub const PreparedView =") != null) or
        std.mem.indexOf(u8, source, "pub fn readPreparedView") != null or
        std.mem.indexOf(u8, source, "pub fn invalidatePreparedViews") != null or
        std.mem.indexOf(u8, source, "pub fn consumePreparedView") != null or
        std.mem.indexOf(u8, source, "consumer: anytype") != null)
    {
        return error.ValueUsePreparedLocationEscape;
    }
    if (std.mem.indexOf(u8, source, "pub fn failedRequestHandle") != null or
        std.mem.indexOf(u8, source, "pub fn failedRequestIndex") != null or
        std.mem.indexOf(u8, source, "pub fn failedRequestRole") != null or
        std.mem.indexOf(u8, source, "pub fn failedRequestSource") != null or
        std.mem.indexOf(u8, source, "pub fn failedRequestLocation") != null or
        std.mem.indexOf(u8, source, "pub fn failedRequestBinding") != null or
        std.mem.indexOf(u8, source, "pub fn retryFailedRequest") != null)
    {
        return error.ValueUseFailureProvenanceEscape;
    }
    if (std.mem.indexOf(u8, source, "pub fn loadHome") != null or
        std.mem.indexOf(u8, source, "pub fn loadSourceHome") != null or
        std.mem.indexOf(u8, source, "pub fn loadBinding") != null or
        std.mem.indexOf(u8, source, "pub const LoadHome") != null)
    {
        return error.ValueUseLoadHomeClassificationEscape;
    }
    if (!allow_technical_visibility) try validateNoPublicPreparedPointer(source);
    const required = [_]struct { function: []const u8, pattern: []const u8, count: usize }{
        .{ .function = "resolveNamedCurrent", .pattern = "resolveValue(", .count = 1 },
    };
    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    for (required) |entry| {
        const body = functionBodyNamed(bodies, entry.function) orelse return error.ValueUseResolutionAuthorityMissing;
        if (countPattern(source[body.start..body.end], entry.pattern) != entry.count)
            return error.ValueUseResolutionAuthorityMismatch;
    }
    if (countPattern(source, "resolveValue(") != 1) return error.ValueUseResolutionAuthorityMismatch;
    if (countPattern(source, "Snapshot.init(selector)") != 1 or
        countPattern(source, "AccumulatorDefinitionSession.init(transaction.selector)") != 1)
    {
        return error.ValueUseCompositionSnapshotContractMismatch;
    }
    if (std.mem.indexOf(u8, source, "AccumulatorDefinitionTransaction.begin(") != null)
        return error.ValueUseNestedAccumulatorSnapshot;
    try validateScratchCompareIntentSurface(source);
    try validateCurrentHomeEqZeroIntentSurface(source);
    try validateSetccEaxCompareIntentSurface(source);
    try validateCurrentHomeSignBitIntentSurface(source);
    try validateI128PairIntentSurface(source);
    try validateScalarCastIntentSurface(source);
    try validateImmediateScalarIntentSurface(source);
    try validateDurableActionIdentityOwnership(source);
    try validateScratchComparePreservationPreamble(source);
    try validateCurrentHomeEqZeroSequence(source);
    try validateSetccEaxCompareSequence(source);
    try validateCurrentHomeSignBitSequence(source);
    try validateI128PairSequence(source);
    try validateScalarCastSequence(source);
}

pub fn validateScratchCompareIntentSurface(source: []const u8) !void {
    const declarations = [_][]const u8{
        "pub const ScratchCompareRhs = union(enum) {",
        "pub const ScratchCompareAction = struct {",
    };
    const has_rhs = std.mem.indexOf(u8, source, declarations[0]) != null;
    const has_action = std.mem.indexOf(u8, source, declarations[1]) != null;
    if (!has_rhs and !has_action) return;
    if (!has_rhs or !has_action) return error.ValueUseScratchCompareIntentMissing;
    const forbidden = [_][]const u8{
        "ArgReg",
        "ValueLoc",
        "Destination",
        "FrameIndex",
        "PreparedView",
        "PreparedScalarHome",
        "preserve",
        "early",
        "phase",
    };
    for (declarations) |declaration| {
        const start = std.mem.indexOf(u8, source, declaration).?;
        const end = std.mem.indexOfPos(u8, source, start, "};") orelse
            return error.InvalidZigSource;
        const body = source[start .. end + 2];
        for (forbidden) |pattern| {
            if (std.mem.indexOf(u8, body, pattern) != null)
                return error.ValueUseScratchComparePhysicalIntentEscape;
        }
    }
}

pub fn validateCurrentHomeEqZeroIntentSurface(source: []const u8) !void {
    const declaration = "pub const CurrentHomeEqZeroAction = struct {";
    const start = std.mem.indexOf(u8, source, declaration) orelse return;
    const end = std.mem.indexOfPos(u8, source, start, "};") orelse
        return error.InvalidZigSource;
    const body = source[start .. end + 2];
    const forbidden = [_][]const u8{
        "ArgReg",
        "ValueLoc",
        "Destination",
        "FrameIndex",
        "PreparedView",
        "Label",
        "target",
        "home",
        "binding",
        "register",
        "scratch",
        "spill",
        "preserve",
        "displacement",
        "reuse_source",
        "early",
        "phase",
    };
    for (forbidden) |pattern| {
        if (std.mem.indexOf(u8, body, pattern) != null)
            return error.ValueUseCurrentHomeEqZeroPhysicalIntentEscape;
    }
    if (countPattern(body, "result: ActionIdentity") != 1 or
        countPattern(body, "operand_ty: ir.Type") != 1)
    {
        return error.ValueUseCurrentHomeEqZeroIntentMismatch;
    }
}

pub fn validateSetccEaxCompareIntentSurface(source: []const u8) !void {
    const declaration = "pub const SetccEaxCompareAction = struct {";
    const start = std.mem.indexOf(u8, source, declaration) orelse return;
    const end = std.mem.indexOfPos(u8, source, start, "};") orelse
        return error.InvalidZigSource;
    const body = source[start .. end + 2];
    const forbidden = [_][]const u8{
        "ArgReg",
        "ValueLoc",
        "Destination",
        "FrameIndex",
        "PreparedView",
        "Label",
        "target",
        "home",
        "binding",
        "register",
        "scratch",
        "spill",
        "preserve",
        "displacement",
        "sequence",
        "early",
        "phase",
    };
    for (forbidden) |pattern| {
        if (std.mem.indexOf(u8, body, pattern) != null)
            return error.ValueUseSetccEaxComparePhysicalIntentEscape;
    }
    const required = [_][]const u8{
        "result: ActionIdentity",
        "operand_ty: ir.Type",
        "predicate: ir.IcmpPredicate",
        "samesign: bool",
        "immediate: i128",
        "structure: SetccEaxCompareStructure",
    };
    for (required) |pattern| {
        if (countPattern(body, pattern) != 1)
            return error.ValueUseSetccEaxCompareIntentMismatch;
    }
}

pub fn validateCurrentHomeSignBitIntentSurface(source: []const u8) !void {
    const declaration = "pub const CurrentHomeSignBitAction = struct {";
    const start = std.mem.indexOf(u8, source, declaration) orelse return;
    const end = std.mem.indexOfPos(u8, source, start, "};") orelse
        return error.InvalidZigSource;
    const body = source[start .. end + 2];
    const forbidden = [_][]const u8{
        "ArgReg",
        "ValueLoc",
        "Destination",
        "FrameIndex",
        "PreparedView",
        "predicate",
        "rhs",
        "register",
        "shift",
        "home",
        "binding",
        "scratch",
        "spill",
        "preserve",
        "displacement",
        "reuse_source",
        "early",
        "phase",
    };
    for (forbidden) |pattern| {
        if (std.mem.indexOf(u8, body, pattern) != null)
            return error.ValueUseCurrentHomeSignBitPhysicalIntentEscape;
    }
    if (countPattern(body, "result: ActionIdentity") != 1 or
        countPattern(body, "operand_ty: ir.Type") != 1)
    {
        return error.ValueUseCurrentHomeSignBitIntentMismatch;
    }
}

pub fn validateI128PairIntentSurface(source: []const u8) !void {
    const declarations = [_][]const u8{
        "pub const I128EqMinAction = struct {",
        "pub const I128SignBitAction = struct {",
    };
    for (declarations) |declaration| {
        const start = std.mem.indexOf(u8, source, declaration) orelse continue;
        const end = std.mem.indexOfPos(u8, source, start, "};") orelse
            return error.InvalidZigSource;
        const body = source[start .. end + 2];
        const forbidden = [_][]const u8{
            "ArgReg",
            "RegPair",
            "ValueLoc",
            "Destination",
            "FrameIndex",
            "PreparedView",
            "predicate",
            "rhs",
            "constant",
            "register",
            "home",
            "binding",
            "pair",
            "scratch",
            "spill",
            "preserve",
            "sequence",
            "phase",
        };
        for (forbidden) |pattern| {
            if (std.mem.indexOf(u8, body, pattern) != null)
                return error.ValueUseI128PairPhysicalIntentEscape;
        }
        if (countPattern(body, "result: ActionIdentity") != 1)
            return error.ValueUseI128PairIntentMismatch;
    }
}

pub fn validateScalarCastIntentSurface(source: []const u8) !void {
    const declarations = [_]struct {
        declaration: []const u8,
        required: []const []const u8,
    }{
        .{
            .declaration = "pub const PairLowScalarCastAction = struct {",
            .required = &.{ "result: ActionIdentity", "op: ir.CastOp", "from_bits: u16", "to_bits: u16" },
        },
        .{
            .declaration = "pub const AccumulatorScalarCastAction = struct {",
            .required = &.{
                "result: ActionIdentity",
                "op: ir.CastOp",
                "from_bits: u16",
                "to_bits: u16",
                "immediate: ?i128",
                "exact_ei: bool",
            },
        },
        .{
            .declaration = "pub const SignExtendScratchAction = struct {",
            .required = &.{"result: ActionIdentity"},
        },
    };
    var present: usize = 0;
    for (declarations) |entry| {
        const start = std.mem.indexOf(u8, source, entry.declaration) orelse continue;
        present += 1;
        const end = std.mem.indexOfPos(u8, source, start, "};") orelse
            return error.InvalidZigSource;
        const body = source[start .. end + 2];
        const forbidden = [_][]const u8{
            "ArgReg",
            "RegPair",
            "ValueLoc",
            "Destination",
            "PreparedView",
            "register",
            "home",
            "binding",
            "scratch",
            "spill",
            "displacement",
            "sequence",
            "phase",
        };
        for (forbidden) |pattern| {
            if (std.mem.indexOf(u8, body, pattern) != null)
                return error.ValueUseScalarCastPhysicalIntentEscape;
        }
        for (entry.required) |pattern| {
            if (countPattern(body, pattern) != 1)
                return error.ValueUseScalarCastIntentMismatch;
        }
    }
    if (present != 0 and present != declarations.len)
        return error.ValueUseScalarCastIntentMissing;
}

pub fn validateImmediateScalarIntentSurface(source: []const u8) !void {
    const declarations = [_][]const u8{
        "pub const ImmediateRhsScalarAction = struct {",
        "pub const ImmediateLhsScalarAction = struct {",
    };
    var present: usize = 0;
    for (declarations) |declaration| {
        const start = std.mem.indexOf(u8, source, declaration) orelse continue;
        present += 1;
        const end = std.mem.indexOfPos(u8, source, start, "};") orelse
            return error.InvalidZigSource;
        const body = source[start .. end + 2];
        const required = [_][]const u8{
            "result: ActionIdentity",
            "operation: ir.BinaryOp",
            "integer_ty: ir.Type",
            "literal: i128",
        };
        for (required) |pattern| {
            if (countPattern(body, pattern) != 1)
                return error.ValueUseImmediateScalarIntentMismatch;
        }
        const forbidden = [_][]const u8{
            "ArgReg",
            "RegPair",
            "ValueLoc",
            "Destination",
            "PreparedView",
            "register",
            "home",
            "binding",
            "scratch",
            "spill",
            "displacement",
            "sequence",
            "phase",
            "request",
        };
        for (forbidden) |pattern| {
            if (std.mem.indexOf(u8, body, pattern) != null)
                return error.ValueUseImmediateScalarPhysicalIntentEscape;
        }
    }
    if (present != 0 and present != declarations.len)
        return error.ValueUseImmediateScalarIntentMissing;
}

pub fn validateScalarCastSequence(source: [:0]const u8) !void {
    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const pair_body = functionBodyNamed(bodies, "executePairLowScalarCast") orelse return;
    const accumulator_body = functionBodyNamed(bodies, "executeAccumulatorScalarCast") orelse
        return error.ValueUseScalarCastSequenceMismatch;
    const sign_extend_body = functionBodyNamed(bodies, "executeSignExtendScratch") orelse
        return error.ValueUseScalarCastSequenceMismatch;
    const pair = source[pair_body.start..pair_body.end];
    const accumulator = source[accumulator_body.start..accumulator_body.end];
    const sign_extend = source[sign_extend_body.start..sign_extend_body.end];

    const pair_order = [_][]const u8{
        "validatePairLowScalarCastAction(action)",
        "scalarCastNamedSource(",
        "emitPairLowLaneIntoScratch(",
        "ownActionIdentity(",
        "bindScratch(",
    };
    var cursor: usize = 0;
    for (pair_order) |pattern| {
        const found = std.mem.indexOfPos(u8, pair, cursor, pattern) orelse
            return error.ValueUseScalarCastSequenceMismatch;
        cursor = found + pattern.len;
    }
    const accumulator_order = [_][]const u8{
        "validateAccumulatorScalarCastAction(action)",
        "scalarCastSourceValue(",
        "scalarCastPlan(action)",
        "scalarCastDisplacement(",
        "session.prepare(",
        "session.materialize(",
        "emitEflagsInstruction(",
        "ownActionIdentity(",
        "session.define(",
        "session.finalize()",
    };
    cursor = 0;
    for (accumulator_order) |pattern| {
        const found = std.mem.indexOfPos(u8, accumulator, cursor, pattern) orelse
            return error.ValueUseScalarCastSequenceMismatch;
        cursor = found + pattern.len;
    }
    const sign_extend_order = [_][]const u8{
        "scalarCastNamedSource(",
        ".arg32, .scratch32",
        ".movsxd_arg32_arg64",
        "ownActionIdentity(",
        "bindScratch(",
    };
    cursor = 0;
    for (sign_extend_order) |pattern| {
        const found = std.mem.indexOfPos(u8, sign_extend, cursor, pattern) orelse
            return error.ValueUseScalarCastSequenceMismatch;
        cursor = found + pattern.len;
    }
    if (countPattern(pair, "emitPairLowLaneIntoScratch(") != 1 or
        countPattern(pair, "bindPairScratch(") != 0 or
        countPattern(pair, "materializePairValue(") != 0 or
        countPattern(accumulator, "session.prepare(") != 1 or
        countPattern(accumulator, "session.materialize(") != 1 or
        countPattern(accumulator, "session.define(") != 1 or
        countPattern(accumulator, "session.finalize()") != 1 or
        countPattern(sign_extend, ".arg32, .scratch32") != 1 or
        countPattern(sign_extend, ".spill64") != 0 or
        countPattern(sign_extend, ".eax") != 0 or
        countPattern(sign_extend, ".rax") != 0)
    {
        return error.ValueUseScalarCastSequenceMismatch;
    }

    try validateScalarCastDisplacementPlan(source);

    const classifier_names = [_][]const u8{
        "isPairLowScalarCast",
        "isAccumulatorScalarCast",
        "isSignExtendScratchCast",
    };
    for (classifier_names) |name| {
        const classifier_body = functionBodyNamed(bodies, name) orelse
            return error.ValueUseScalarCastClassifierMissing;
        const classifier = source[classifier_body.start..classifier_body.end];
        const forbidden = [_][]const u8{
            "selector",
            "resolveValue(",
            "valueLoc(",
            "ValueLoc",
            "function",
            "family",
            ".arg",
            ".scratch",
            ".spill",
            ".eax",
            ".rax",
        };
        for (forbidden) |pattern| {
            if (std.mem.indexOf(u8, classifier, pattern) != null)
                return error.ValueUseScalarCastClassifierStatePredicate;
        }
    }
}

pub fn validateScalarCastDisplacementPlan(source: [:0]const u8) !void {
    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const plan_body = functionBodyNamed(bodies, "scalarCastPlan") orelse
        return error.ValueUseScalarCastSequenceMismatch;
    const displacement_body = functionBodyNamed(bodies, "scalarCastDisplacement") orelse
        return error.ValueUseScalarCastSequenceMismatch;
    const source_displacement_body = functionBodyNamed(bodies, "scalarCastSourceDisplacement") orelse
        return error.ValueUseScalarCastSequenceMismatch;
    const plan = source[plan_body.start..plan_body.end];
    const displacement = source[displacement_body.start..displacement_body.end];
    const source_displacement = source[source_displacement_body.start..source_displacement_body.end];
    const cast_plans = [_][]const u8{
        "c04_exact_ei",
        "c05_narrow_zext",
        "c52_0_trunc_i64_to_i52",
        "c52_1_zext_i6_to_i52",
        "c52_2_zext_i52_to_i64",
        "c52_3_trunc_i52",
    };
    if (std.mem.indexOf(u8, source, "const AccumulatorScalarCastPlan = enum {") == null)
        return error.ValueUseScalarCastSequenceMismatch;
    for (cast_plans) |cast_plan| {
        if (std.mem.indexOf(u8, source, cast_plan) == null)
            return error.ValueUseScalarCastSequenceMismatch;
    }
    const plan_forbidden = [_][]const u8{
        "transaction",
        "selector",
        "prepared_views",
        "ValueLoc",
        ".eax",
        ".rax",
        ".spill",
    };
    for (plan_forbidden) |pattern| {
        if (std.mem.indexOf(u8, plan, pattern) != null)
            return error.ValueUseScalarCastPhysicalIntentEscape;
    }
    if (countPattern(displacement, "plan == .c52_0_trunc_i64_to_i52") != 1 or
        countPattern(displacement, "return .spill_live") != 1 or
        countPattern(displacement, "scalarCastSourceDisplacement(") != 1 or
        countPattern(source_displacement, ".eax, .rax") != 1 or
        countPattern(source_displacement, ".reuse_source") != 1 or
        countPattern(source_displacement, ".spill_live") != 2)
    {
        return error.ValueUseScalarCastSequenceMismatch;
    }
}

pub fn validateScratchComparePreservationPreamble(source: [:0]const u8) !void {
    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const execute_body = functionBodyNamed(bodies, "executeScratchCompare") orelse return;
    const preserve_body = functionBodyNamed(bodies, "preserveScratchCompareLiveAccumulator") orelse
        return error.ValueUseScratchComparePreservationPreambleMissing;
    const refresh_body = functionBodyNamed(bodies, "refreshScratchCompareOperandViews") orelse
        return error.ValueUseScratchComparePreservationPreambleMissing;
    const execute_source = source[execute_body.start..execute_body.end];
    const preserve_source = source[preserve_body.start..preserve_body.end];
    const refresh_source = source[refresh_body.start..refresh_body.end];
    const preservation_preamble_count: usize =
        1 +
        @as(usize, @intFromBool(functionBodyNamed(bodies, "preserveCurrentHomeSignBitLiveAccumulator") != null)) +
        @as(usize, @intFromBool(functionBodyNamed(bodies, "executeImmediateRhsScalar") != null));

    const preserve_call = std.mem.indexOf(
        u8,
        execute_source,
        "try preserveScratchCompareLiveAccumulator(transaction);",
    ) orelse return error.ValueUseScratchComparePreservationPreambleMissing;
    const refresh_call = std.mem.indexOf(
        u8,
        execute_source,
        "try refreshScratchCompareOperandViews(transaction, lhs_index, action);",
    ) orelse return error.ValueUseScratchCompareCanonicalRefreshMissing;
    const stage_call = std.mem.indexOf(
        u8,
        execute_source,
        "try stageScratchCompareOperand(",
    ) orelse return error.ValueUseScratchComparePreservationOrder;
    const prepare_call = std.mem.indexOf(
        u8,
        execute_source,
        "if (try session.prepare(.preserve, .spill_live))",
    ) orelse return error.ValueUseScratchComparePreservationOrder;
    if (!(preserve_call < refresh_call and refresh_call < stage_call and stage_call < prepare_call) or
        countPattern(execute_source, "preserveScratchCompareLiveAccumulator(transaction)") != 1 or
        countPattern(execute_source, "refreshScratchCompareOperandViews(transaction, lhs_index, action)") != 1 or
        countPattern(execute_source, "initial_lhs_view") != 1 or
        countPattern(execute_source, "after_canonical_view_refresh") != 1 or
        countPattern(execute_source, "&transaction.prepared_views[lhs_index].view") != 1 or
        countPattern(preserve_source, "liveAccumulatorNameAfterCurrent(transaction.selector)") != 1 or
        countPattern(preserve_source, "preserveLiveAccumulatorValue(transaction.selector, live_name)") != 1 or
        countPattern(preserve_source, "after_first_accumulator_preservation") != 1 or
        countPattern(preserve_source, "eflags.validateSnapshot(flags_before)") != 1 or
        countPattern(preserve_source, "eflags_semantics.items.len") != 2 or
        countPattern(refresh_source, "buildPreparedRecord(lhs_index)") != 1 or
        countPattern(refresh_source, "buildPreparedRecord(rhs_index)") != 1 or
        countPattern(source, "liveAccumulatorNameAfterCurrent(transaction.selector)") !=
            preservation_preamble_count or
        countPattern(source, "preserveLiveAccumulatorValue(") != preservation_preamble_count)
    {
        return error.ValueUseScratchComparePreservationOrder;
    }
}

pub fn validateCurrentHomeEqZeroSequence(source: [:0]const u8) !void {
    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const body = functionBodyNamed(bodies, "executeCurrentHomeEqZero") orelse return;
    const function_source = source[body.start..body.end];
    const preserve = std.mem.indexOf(
        u8,
        function_source,
        "try preserveScratchCompareLiveAccumulator(transaction);",
    ) orelse return error.ValueUseCurrentHomeEqZeroSequenceMismatch;
    const refresh = std.mem.indexOf(
        u8,
        function_source,
        "transaction.prepared_views[source_index] = try transaction.buildPreparedRecord(source_index);",
    ) orelse return error.ValueUseCurrentHomeEqZeroSequenceMismatch;
    const classify = std.mem.indexOf(
        u8,
        function_source,
        "classifyCurrentHomeEqZero(binding, request.expected, current)",
    ) orelse return error.ValueUseCurrentHomeEqZeroSequenceMismatch;
    const test_definition = std.mem.indexOf(
        u8,
        function_source,
        "failCurrentHomeEqZeroForTest(transaction, .after_test_definition)",
    ) orelse return error.ValueUseCurrentHomeEqZeroSequenceMismatch;
    const prepare = std.mem.indexOf(
        u8,
        function_source,
        "if (try session.prepare(.preserve, .spill_live))",
    ) orelse return error.ValueUseCurrentHomeEqZeroSequenceMismatch;
    const after_prepare = std.mem.indexOf(
        u8,
        function_source,
        "failCurrentHomeEqZeroForTest(transaction, .after_accumulator_preparation)",
    ) orelse return error.ValueUseCurrentHomeEqZeroSequenceMismatch;
    const setcc = std.mem.indexOf(
        u8,
        function_source,
        "emitEflagsInstruction(transaction.selector, .sete_eax, .use)",
    ) orelse return error.ValueUseCurrentHomeEqZeroSequenceMismatch;
    const own = std.mem.indexOf(
        u8,
        function_source,
        "const result_name = try ownActionIdentity(transaction, &stored_action.result);",
    ) orelse return error.ValueUseCurrentHomeEqZeroSequenceMismatch;
    const define = std.mem.indexOf(
        u8,
        function_source,
        "try session.define(result_name, .zeroExtending(1));",
    ) orelse return error.ValueUseCurrentHomeEqZeroSequenceMismatch;
    const finalize = std.mem.indexOf(
        u8,
        function_source,
        "try session.finalize();",
    ) orelse return error.ValueUseCurrentHomeEqZeroSequenceMismatch;
    if (!(preserve < refresh and refresh < classify and classify < test_definition and
        test_definition < prepare and prepare < after_prepare and after_prepare < setcc and
        setcc < own and own < define and define < finalize) or
        countPattern(function_source, "preserveScratchCompareLiveAccumulator(transaction)") != 1 or
        countPattern(function_source, "buildPreparedRecord(source_index)") != 1 or
        countPattern(function_source, ".canonical_source_loc") != 1 or
        countPattern(function_source, ".reuse_source") != 0 or
        countPattern(function_source, "preparedViewLoc(") != 0 or
        countPattern(function_source, "resolveValue(") != 0)
    {
        return error.ValueUseCurrentHomeEqZeroSequenceMismatch;
    }

    const classifier = functionBodyNamed(bodies, "classifyCurrentHomeEqZero") orelse
        return error.ValueUseCurrentHomeEqZeroSequenceMismatch;
    const classifier_source = source[classifier.start..classifier.end];
    const required_homes = [_][]const u8{
        ".eax",
        ".rax",
        ".arg32",
        ".scratch32",
        ".arg64",
        ".scratch64",
        ".spill64",
        ".spill128 => error.ValueUseCurrentHomeEqZeroLocationUnsupported",
    };
    for (required_homes) |pattern| {
        if (std.mem.indexOf(u8, classifier_source, pattern) == null)
            return error.ValueUseCurrentHomeEqZeroHomeClassificationMissing;
    }
}

pub fn validateSetccEaxCompareSequence(source: [:0]const u8) !void {
    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const body = functionBodyNamed(bodies, "executeSetccEaxCompare") orelse return;
    const function_source = source[body.start..body.end];
    const required_order = [_][]const u8{
        "try preserveScratchCompareLiveAccumulator(transaction);",
        "failSetccEaxCompareForTest(transaction, .after_preamble)",
        "transaction.prepared_views[source_index] = try transaction.buildPreparedRecord(source_index);",
        "const plan = try classifySetccEaxCompare(action);",
        "validateSetccEaxCompareHome(binding, request.expected, current)",
        "selector_state.emitValueIntoEax(transaction.selector",
        "failSetccEaxCompareForTest(transaction, .after_materialization)",
        "failSetccEaxCompareForTest(transaction, .after_normalization_or_mask)",
        "if (plan.prepare_before_definition)",
        "selector_state.emitEflagsInstruction(transaction.selector, definition, .definition)",
        "failSetccEaxCompareForTest(transaction, .after_eflags_definition)",
        "if (!plan.prepare_before_definition)",
        "const setcc = plan.setcc orelse",
        "selector_state.emitEflagsInstruction(transaction.selector, setcc, .use)",
        "const result_name = try ownActionIdentity(transaction, &stored_action.result);",
        "try session.define(result_name, .zeroExtending(1));",
        "try session.finalize();",
    };
    var cursor: usize = 0;
    for (required_order) |pattern| {
        const found = std.mem.indexOfPos(u8, function_source, cursor, pattern) orelse
            return error.ValueUseSetccEaxCompareSequenceMismatch;
        cursor = found + pattern.len;
    }
    if (countPattern(function_source, "session.prepare(.preserve, .spill_live)") != 2 or
        countPattern(function_source, "failSetccEaxCompareForTest(transaction, .after_accumulator_preparation)") != 2 or
        countPattern(function_source, "buildPreparedRecord(source_index)") != 1 or
        countPattern(function_source, ".canonical_source_loc") != 1 or
        countPattern(function_source, "preparedViewLoc(") != 0 or
        countPattern(function_source, "resolveValue(") != 0 or
        countPattern(function_source, ".reuse_source") != 0)
    {
        return error.ValueUseSetccEaxCompareSequenceMismatch;
    }
}

pub fn validateCurrentHomeSignBitSequence(source: [:0]const u8) !void {
    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const body = functionBodyNamed(bodies, "executeCurrentHomeSignBit") orelse return;
    const function_source = source[body.start..body.end];
    const required_order = [_][]const u8{
        "try preserveCurrentHomeSignBitLiveAccumulator(transaction);",
        "failCurrentHomeSignBitForTest(transaction, .after_global_preamble)",
        "const plan = classifyCurrentHomeSignBit(action)",
        "selector_state.preserveCurrentEaxIntoScratch(transaction.selector)",
        "selector_state.preserveCurrentRaxIntoScratch(transaction.selector)",
        "failCurrentHomeSignBitForTest(transaction, .after_current_home_preservation)",
        "transaction.prepared_views[source_index] = try transaction.buildPreparedRecord(source_index);",
        "validateCurrentHomeSignBitHome(binding, request.expected, current)",
        "failCurrentHomeSignBitForTest(transaction, .after_materialization)",
        "if (try session.prepare(.preserve, .spill_live))",
        "failCurrentHomeSignBitForTest(transaction, .after_accumulator_preparation)",
        "emitEflagsInstruction(transaction.selector, plan.shift, .write)",
        "failCurrentHomeSignBitForTest(transaction, .after_shift)",
        "const result_name = try ownActionIdentity(transaction, &stored_action.result);",
        "try session.define(result_name, .zeroExtending(1));",
        "failCurrentHomeSignBitForTest(transaction, .after_result_definition)",
        "try session.finalize();",
        "failCurrentHomeSignBitForTest(transaction, .after_finalization)",
    };
    var cursor: usize = 0;
    for (required_order) |pattern| {
        const found = std.mem.indexOfPos(u8, function_source, cursor, pattern) orelse
            return error.ValueUseCurrentHomeSignBitSequenceMismatch;
        cursor = found + pattern.len;
    }
    if (countPattern(function_source, "session.prepare(.preserve, .spill_live)") != 1 or
        countPattern(function_source, "buildPreparedRecord(source_index)") != 1 or
        countPattern(function_source, ".canonical_source_loc") != 1 or
        countPattern(function_source, "emitValueIntoEax(") != 1 or
        countPattern(function_source, "emitValueIntoRax(") != 1 or
        countPattern(function_source, ".definition") != 0 or
        countPattern(function_source, ".use") != 0 or
        countPattern(function_source, "setcc") != 0 or
        countPattern(function_source, "resolveValue(") != 0 or
        countPattern(function_source, ".reuse_source") != 0)
    {
        return error.ValueUseCurrentHomeSignBitSequenceMismatch;
    }

    const classifier_body = functionBodyNamed(bodies, "isCurrentHomeSignBitIcmp") orelse
        return error.ValueUseCurrentHomeSignBitClassifierMissing;
    const classifier = source[classifier_body.start..classifier_body.end];
    const classifier_required = [_][]const u8{
        "icmp.predicate != .slt",
        "icmp.samesign",
        "bits != 32 and bits != 64",
        "icmp.lhs != .named",
        "value == 0",
    };
    for (classifier_required) |pattern| {
        if (std.mem.indexOf(u8, classifier, pattern) == null)
            return error.ValueUseCurrentHomeSignBitClassifierMismatch;
    }
    const classifier_forbidden = [_][]const u8{
        "selector",
        "resolveValue(",
        "valueLoc(",
        "ValueLoc",
        "function",
        "family",
        ".eax",
        ".rax",
        ".spill64",
        ".spill128",
    };
    for (classifier_forbidden) |pattern| {
        if (std.mem.indexOf(u8, classifier, pattern) != null)
            return error.ValueUseCurrentHomeSignBitClassifierStatePredicate;
    }

    const plan_body = functionBodyNamed(bodies, "classifyCurrentHomeSignBit") orelse
        return error.ValueUseCurrentHomeSignBitSequenceMismatch;
    const plan = source[plan_body.start..plan_body.end];
    if (countPattern(plan, ".shr_eax_imm5 = 31") != 1 or
        countPattern(plan, ".shr_rax_imm6 = 63") != 1 or
        countPattern(plan, ".sar_") != 0)
    {
        return error.ValueUseCurrentHomeSignBitLogicalShiftMismatch;
    }

    const preserve_body =
        functionBodyNamed(bodies, "preserveCurrentHomeSignBitLiveAccumulator") orelse
        return error.ValueUseCurrentHomeSignBitPreambleMissing;
    const preserve = source[preserve_body.start..preserve_body.end];
    const preserve_required = [_][]const u8{
        "liveAccumulatorNameAfterCurrent(transaction.selector)",
        "preserveLiveAccumulatorValue(",
        "valueIsLiveAfterCurrent(",
        "selector_state.bindValueLoc(",
        "eflags.validateSnapshot(flags_before)",
    };
    for (preserve_required) |pattern| {
        if (std.mem.indexOf(u8, preserve, pattern) == null)
            return error.ValueUseCurrentHomeSignBitPreambleMissing;
    }
}

pub fn validateI128PairSequence(source: [:0]const u8) !void {
    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const eq_body = functionBodyNamed(bodies, "executeI128EqMin") orelse return;
    const sign_body = functionBodyNamed(bodies, "executeI128SignBit") orelse
        return error.ValueUseI128PairSequenceMismatch;
    const home_body = functionBodyNamed(bodies, "validateI128PairHome") orelse
        return error.ValueUseI128PairSequenceMismatch;
    const destinations_body = functionBodyNamed(bodies, "requestDestinationNodes") orelse
        return error.ValueUseI128PairSequenceMismatch;
    const eq = source[eq_body.start..eq_body.end];
    const sign = source[sign_body.start..sign_body.end];
    const home = source[home_body.start..home_body.end];
    const destinations = source[destinations_body.start..destinations_body.end];

    const eq_order = [_][]const u8{
        "try preserveScratchCompareLiveAccumulator(transaction);",
        "failI128EqMinForTest(transaction, .after_preamble)",
        "refreshAndValidateI128PairSource(transaction, source_index)",
        "failI128EqMinForTest(transaction, .after_canonical_refresh)",
        "selector_state.resolvePairValue(",
        "failI128EqMinForTest(transaction, .after_pair_selection)",
        "selector_state.materializePairValue(",
        "failI128EqMinForTest(transaction, .after_pair_materialization)",
        "if (try session.prepare(.preserve, .spill_live))",
        "failI128EqMinForTest(transaction, .after_accumulator_preparation)",
        "try selector_state.clobberArgReg(transaction.selector, temp);",
        "failI128EqMinForTest(transaction, .after_temp_clobber)",
        ".mov_arg_rax = pair.hi",
        "failI128EqMinForTest(transaction, .after_high_to_rax)",
        "std.math.minInt(i64)",
        "failI128EqMinForTest(transaction, .after_min_int)",
        ".op = .xor",
        ".write",
        "failI128EqMinForTest(transaction, .after_xor)",
        ".op = .@\"or\"",
        ".write",
        "failI128EqMinForTest(transaction, .after_or)",
        ".mov_rax_to_arg = temp",
        "failI128EqMinForTest(transaction, .after_temp_copy)",
        ".cmp_arg64_imm64",
        ".definition",
        "failI128EqMinForTest(transaction, .after_cmp)",
        ".sete_eax",
        ".use",
        "failI128EqMinForTest(transaction, .after_sete)",
        "const result_name = try ownActionIdentity(transaction, &stored_action.result);",
        "failI128EqMinForTest(transaction, .after_result_identity_ownership)",
        "try session.define(result_name, .zeroExtending(1));",
        "failI128EqMinForTest(transaction, .after_result_definition)",
        "try session.finalize();",
        "failI128EqMinForTest(transaction, .after_finalization)",
    };
    var cursor: usize = 0;
    for (eq_order) |pattern| {
        const found = std.mem.indexOfPos(u8, eq, cursor, pattern) orelse
            return error.ValueUseI128PairSequenceMismatch;
        cursor = found + pattern.len;
    }

    const sign_order = [_][]const u8{
        "try preserveScratchCompareLiveAccumulator(transaction);",
        "failI128SignBitForTest(transaction, .after_preamble)",
        "refreshAndValidateI128PairSource(transaction, source_index)",
        "failI128SignBitForTest(transaction, .after_canonical_refresh)",
        "selector_state.emitPairHighLaneIntoRax(",
        "failI128SignBitForTest(transaction, .after_high_limb_load)",
        "if (try session.prepare(.preserve, .spill_live))",
        "failI128SignBitForTest(transaction, .after_accumulator_preparation)",
        ".shr_rax_imm6 = 63",
        ".write",
        "failI128SignBitForTest(transaction, .after_shift)",
        "const result_name = try ownActionIdentity(transaction, &stored_action.result);",
        "failI128SignBitForTest(transaction, .after_result_identity_ownership)",
        "try session.define(result_name, .zeroExtending(1));",
        "failI128SignBitForTest(transaction, .after_result_definition)",
        "try session.finalize();",
        "failI128SignBitForTest(transaction, .after_finalization)",
    };
    cursor = 0;
    for (sign_order) |pattern| {
        const found = std.mem.indexOfPos(u8, sign, cursor, pattern) orelse
            return error.ValueUseI128PairSequenceMismatch;
        cursor = found + pattern.len;
    }
    if (countPattern(eq, "resolvePairValue(") != 1 or
        countPattern(eq, "materializePairValue(") != 1 or
        countPattern(eq, "session.prepare(.preserve, .spill_live)") != 1 or
        countPattern(eq, "ownActionIdentity(") != 1 or
        countPattern(sign, "emitPairHighLaneIntoRax(") != 1 or
        countPattern(sign, "session.prepare(.preserve, .spill_live)") != 1 or
        countPattern(sign, "ownActionIdentity(") != 1 or
        countPattern(sign, ".definition") != 0 or
        countPattern(sign, ".use") != 0 or
        countPattern(sign, "setcc") != 0 or
        countPattern(home, ".arg128") != 1 or
        countPattern(home, ".scratch128") != 1 or
        countPattern(home, ".stack128_value") != 1 or
        countPattern(home, ".spill128") != 1 or
        countPattern(destinations, ".stack128_value, .spill128 => null") != 1)
    {
        return error.ValueUseI128PairSequenceMismatch;
    }

    const classifier_names = [_][]const u8{ "isI128EqMinIcmp", "isI128SignBitIcmp" };
    for (classifier_names) |name| {
        const classifier_body = functionBodyNamed(bodies, name) orelse
            return error.ValueUseI128PairClassifierMissing;
        const classifier = source[classifier_body.start..classifier_body.end];
        const forbidden = [_][]const u8{
            "selector",
            "resolveValue(",
            "valueLoc(",
            "ValueLoc",
            "function",
            "family",
            ".arg128",
            ".scratch128",
            ".stack128_value",
            ".spill128",
        };
        for (forbidden) |pattern| {
            if (std.mem.indexOf(u8, classifier, pattern) != null)
                return error.ValueUseI128PairClassifierStatePredicate;
        }
    }
}

pub fn validateDurableActionIdentityOwnership(source: [:0]const u8) !void {
    if (std.mem.indexOf(u8, source, ".result.slice()") != null)
        return error.ValueUseDurableActionIdentityNotOwned;
    const durable_apis = [_][]const u8{
        "session.define(",
        "selector_state.bindValueLoc(",
        "selector_state.bindResultLoc(",
        "selector_state.bindScratch(",
        "selector_state.bindPairScratch(",
    };
    for (durable_apis) |api| {
        var cursor: usize = 0;
        while (std.mem.indexOfPos(u8, source, cursor, api)) |start| {
            const end = std.mem.indexOfPos(u8, source, start, ";") orelse
                return error.InvalidZigSource;
            if (std.mem.indexOf(u8, source[start..end], ".slice()") != null)
                return error.ValueUseDurableActionIdentityNotOwned;
            cursor = end + 1;
        }
    }

    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const body = functionBodyNamed(bodies, "executeScratchCompare") orelse return;
    const function_source = source[body.start..body.end];
    const own_pattern = "const result_name = try ownActionIdentity(transaction, &stored_action.result);";
    const define_pattern = "try session.define(result_name, .zeroExtending(1));";
    const own_index = std.mem.indexOf(u8, function_source, own_pattern) orelse
        return error.ValueUseDurableActionIdentityOwnershipMissing;
    const define_index = std.mem.indexOf(u8, function_source, define_pattern) orelse
        return error.ValueUseDurableActionIdentityOwnershipMissing;
    if (own_index >= define_index) return error.ValueUseDurableActionIdentityOwnershipOrder;
    const between = function_source[own_index + own_pattern.len .. define_index];
    if (countPattern(between, "failScratchCompareForTest(transaction, .after_result_identity_ownership);") != 1)
        return error.ValueUseDurableActionIdentityOwnershipOrder;

    if (functionBodyNamed(bodies, "executeCurrentHomeEqZero")) |current_home_body| {
        const current_home_source = source[current_home_body.start..current_home_body.end];
        const current_own = std.mem.indexOf(u8, current_home_source, own_pattern) orelse
            return error.ValueUseDurableActionIdentityOwnershipMissing;
        const current_define = std.mem.indexOf(u8, current_home_source, define_pattern) orelse
            return error.ValueUseDurableActionIdentityOwnershipMissing;
        if (current_own >= current_define)
            return error.ValueUseDurableActionIdentityOwnershipOrder;
    }
    if (functionBodyNamed(bodies, "executeSetccEaxCompare")) |setcc_body| {
        const setcc_source = source[setcc_body.start..setcc_body.end];
        const setcc_own = std.mem.indexOf(u8, setcc_source, own_pattern) orelse
            return error.ValueUseDurableActionIdentityOwnershipMissing;
        const setcc_define = std.mem.indexOf(u8, setcc_source, define_pattern) orelse
            return error.ValueUseDurableActionIdentityOwnershipMissing;
        if (setcc_own >= setcc_define)
            return error.ValueUseDurableActionIdentityOwnershipOrder;
    }
    if (functionBodyNamed(bodies, "executeCurrentHomeSignBit")) |sign_bit_body| {
        const sign_bit_source = source[sign_bit_body.start..sign_bit_body.end];
        const sign_bit_own = std.mem.indexOf(u8, sign_bit_source, own_pattern) orelse
            return error.ValueUseDurableActionIdentityOwnershipMissing;
        const sign_bit_define = std.mem.indexOf(u8, sign_bit_source, define_pattern) orelse
            return error.ValueUseDurableActionIdentityOwnershipMissing;
        if (sign_bit_own >= sign_bit_define)
            return error.ValueUseDurableActionIdentityOwnershipOrder;
    }
    const i128_functions = [_][]const u8{ "executeI128EqMin", "executeI128SignBit" };
    for (i128_functions) |name| {
        if (functionBodyNamed(bodies, name)) |pair_body| {
            const pair_source = source[pair_body.start..pair_body.end];
            const pair_own = std.mem.indexOf(u8, pair_source, own_pattern) orelse
                return error.ValueUseDurableActionIdentityOwnershipMissing;
            const pair_define = std.mem.indexOf(u8, pair_source, define_pattern) orelse
                return error.ValueUseDurableActionIdentityOwnershipMissing;
            if (pair_own >= pair_define)
                return error.ValueUseDurableActionIdentityOwnershipOrder;
        }
    }
}
