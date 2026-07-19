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
    try validateNamedScalarIntentSurface(source);
    try validateScalarMultiplyIntentSurface(source);
    try validateUnsignedQuotientIntentSurface(source);
    try validateCallIntentSurface(source);
    try validateLifetimeContextAuthority(source);
    if (allow_technical_visibility)
        try validateForwardAdmissionSnapshotAuthority(source);
    try validateImmediateScalarAccumulatorPreamble(source);
    try validateDurableActionIdentityOwnership(source);
    try validateScratchComparePreservationPreamble(source);
    try validateCurrentHomeEqZeroSequence(source);
    try validateSetccEaxCompareSequence(source);
    try validateCurrentHomeSignBitSequence(source);
    try validateI128PairSequence(source);
    try validateScalarCastSequence(source);
}

pub fn validateCallIntentSurface(source: [:0]const u8) !void {
    if (std.mem.indexOf(u8, source, "pub const DirectCallAction = struct {")) |start| {
        const end = std.mem.indexOfPos(
            u8,
            source,
            start,
            "pub const IntByteSizeCallAction = struct {",
        ) orelse return error.ValueUseCallIntentMismatch;
        const body = source[start..end];
        for ([_][]const u8{
            "\n    symbol: ActionIdentity,",
            "\n    result: ?ActionIdentity,",
            "\n    return_type: ir.Type,",
            "\n    arguments: [max_requests]RequestHandle = undefined,",
            "\n    argument_types: [max_requests]ir.Type = undefined,",
            "\n    argument_count: u8 = 0,",
        }) |field| {
            if (countPattern(body, field) != 1)
                return error.ValueUseCallIntentMismatch;
        }
        for ([_][]const u8{
            "ValueLoc", "PreparedView", "ArgReg",        "home",         "destination",
            "staging",  "liveness",     "function_name", "functionName",
        }) |forbidden| {
            if (std.mem.indexOf(u8, body, forbidden) != null)
                return error.ValueUseCallPhysicalIntentEscape;
        }
    }
    if (std.mem.indexOf(u8, source, "pub const IntByteSizeCallAction = struct {")) |start| {
        const end = std.mem.indexOfPos(
            u8,
            source,
            start,
            "pub const CallRequestError = error{",
        ) orelse return error.ValueUseCallIntentMismatch;
        const body = source[start..end];
        for ([_][]const u8{
            "\n    symbol: ActionIdentity,",
            "\n    result: ActionIdentity,",
            "\n    argument: RequestHandle,",
        }) |field| {
            if (countPattern(body, field) != 1)
                return error.ValueUseCallIntentMismatch;
        }
        for ([_][]const u8{
            "ValueLoc", "PreparedView", "ArgReg",        "home",         "destination",
            "staging",  "liveness",     "function_name", "functionName",
        }) |forbidden| {
            if (std.mem.indexOf(u8, body, forbidden) != null)
                return error.ValueUseCallPhysicalIntentEscape;
        }
    }
    if (std.mem.indexOf(u8, source, "pub const CallRequestError = error{")) |start| {
        const end = std.mem.indexOfPos(u8, source, start, "};") orelse
            return error.InvalidZigSource;
        const body = source[start .. end + 2];
        const required = [_][]const u8{
            "ValueUseCallArgumentNotNamed",
            "ValueUseCallArgumentTypeUnsupported",
            "ValueUseCallArgumentWidthUnsupported",
            "ValueUseCallArgumentLocationUnsupported",
            "ValueUseCallPointerLocationUnsupported",
            "ValueUseCallStackDisplacementUnsupported",
        };
        for (required) |member| {
            if (countPattern(body, member) != 1)
                return error.ValueUseCallIntentMismatch;
        }
        if (countPattern(body, ",") != required.len)
            return error.ValueUseCallIntentMismatch;
    }
    if (std.mem.indexOf(u8, source, "pub const PreparedAction = union(enum) {")) |start| {
        const end = std.mem.indexOfPos(u8, source, start, "};") orelse
            return error.InvalidZigSource;
        const body = source[start .. end + 2];
        if (countPattern(body, "direct_call: DirectCallAction,") != 1 or
            countPattern(body, "int_byte_size_call: IntByteSizeCallAction,") != 1)
        {
            return error.ValueUseCallIntentMismatch;
        }
    }
    if (countPattern(source, "pub fn attachCallAction(") > 1)
        return error.ValueUseCallIntentMismatch;

    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    if (functionBodyNamed(bodies, "core_attachCallAction")) |body| {
        const attachment = source[body.start..body.end];
        const validation = std.mem.indexOf(
            u8,
            attachment,
            "validateCallActionAttachment(",
        ) orelse return error.ValueUseCallAttachmentLifecycleMismatch;
        const assignment = std.mem.indexOf(
            u8,
            attachment,
            "transaction.call_action = action;",
        ) orelse return error.ValueUseCallAttachmentLifecycleMismatch;
        if (countPattern(attachment, "transaction.request_phase != .registering") != 1 or
            countPattern(attachment, "error.ValueUseLateRegistration") != 1 or
            countPattern(attachment, "transaction.call_action != null") != 1 or
            countPattern(attachment, "error.ValueUseCallActionAlreadyAttached") != 1 or
            validation >= assignment)
        {
            return error.ValueUseCallAttachmentLifecycleMismatch;
        }
        const registration = functionBodyNamed(bodies, "core_register") orelse
            return error.ValueUseCallAttachmentLifecycleMismatch;
        if (countPattern(
            source[registration.start..registration.end],
            "transaction.call_action != null",
        ) != 1) {
            return error.ValueUseCallAttachmentLifecycleMismatch;
        }
    }
    if (functionBodyNamed(bodies, "buildPreparedRecordUnchecked")) |body| {
        const prepared = source[body.start..body.end];
        if (countPattern(prepared, "pin.call_final_use != null") != 1 or
            countPattern(prepared, "Authority.validateRequestAt(") < 2)
        {
            return error.ValueUseCallFinalUseRevalidationMismatch;
        }
    }
    if (functionBodyNamed(bodies, "refreshCallArguments")) |body| {
        if (countPattern(
            source[body.start..body.end],
            "buildPreparedRecord(",
        ) != 1) {
            return error.ValueUseCallFinalUseRevalidationMismatch;
        }
    }
    if (functionBodyNamed(bodies, "stageValidatedCallArgument")) |body| {
        if (countPattern(
            source[body.start..body.end],
            "validateRequestAt(",
        ) != 1) {
            return error.ValueUseCallFinalUseRevalidationMismatch;
        }
    }
}

pub fn validateForwardAdmissionSnapshotAuthority(source: [:0]const u8) !void {
    const snapshot_start = std.mem.indexOf(
        u8,
        source,
        "pub const ForwardAdmissionSnapshot = struct {",
    ) orelse return error.ValueUseForwardSnapshotMissing;
    const snapshot_fields_end = std.mem.indexOfPos(
        u8,
        source,
        snapshot_start,
        "    pub fn eql(",
    ) orelse return error.ValueUseForwardSnapshotMissing;
    const snapshot_fields = source[snapshot_start..snapshot_fields_end];
    const required_fields = [_][]const u8{
        "plan_identity: usize",
        "identity: Identity",
        "admission_position: usize",
        "definition_position: usize",
        "interval_end: usize",
        "virtual_class: VirtualRegClass",
        "defined_width: u16",
        "assignment: ForwardAssignmentSnapshot",
        "assignment_frame_bytes: ?usize",
        "dependencies: ForwardDependencySnapshot",
    };
    for (required_fields) |field| {
        if (std.mem.indexOf(u8, snapshot_fields, field) == null)
            return error.ValueUseForwardSnapshotMissing;
    }
    if (std.mem.indexOf(u8, snapshot_fields, "ValueLoc") != null or
        std.mem.indexOf(u8, snapshot_fields, "[]") != null or
        std.mem.indexOf(u8, snapshot_fields, "*") != null or
        std.mem.indexOf(u8, snapshot_fields, "generation") != null or
        std.mem.indexOf(u8, snapshot_fields, "hash") != null)
    {
        return error.ValueUseForwardSnapshotBorrowedState;
    }
    if (std.mem.indexOf(u8, source, "forward_snapshots: [max_requests]?ForwardAdmissionSnapshot") == null or
        std.mem.indexOf(u8, source, "pub const max_forward_dependency_owners = 4;") == null or
        std.mem.indexOf(u8, source, "error.ValueUseForwardSnapshotCapacityExceeded") == null or
        std.mem.indexOf(u8, source, "forward_generation") != null or
        std.mem.indexOf(u8, source, "ForwardAdmissionHash") != null)
    {
        return error.ValueUseForwardSnapshotStorageMismatch;
    }

    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const capture_body = functionBodyNamed(bodies, "captureForwardAdmissionSnapshot") orelse
        return error.ValueUseForwardSnapshotCaptureMismatch;
    const capture = source[capture_body.start..capture_body.end];
    const capture_required = [_][]const u8{
        "@intFromPtr(plan)",
        "forward.definition_position",
        "interval_end",
        "forward.metadata.class",
        "forward.metadata.bits",
        "plan.assignment(",
        "transaction.selector.stack_frame_bytes",
        "captureForwardDependencySnapshot(transaction)",
    };
    for (capture_required) |pattern| {
        if (std.mem.indexOf(u8, capture, pattern) == null)
            return error.ValueUseForwardSnapshotCaptureMismatch;
    }
    if (countPattern(source, "fn captureForwardAdmissionSnapshot(") != 1 or
        countPattern(source, "captureForwardAdmissionSnapshot(transaction, index)") != 1)
    {
        return error.ValueUseForwardSnapshotCaptureMismatch;
    }
    const resolve_body = functionBodyNamed(bodies, "resolveRequestCurrent") orelse
        return error.ValueUseForwardSnapshotResolverMismatch;
    const resolve = source[resolve_body.start..resolve_body.end];
    if (countPattern(resolve, "captureForwardAdmissionSnapshot(transaction, index)") != 0 or
        countPattern(resolve, "selector_state.resolveForwardValueForUse(") != 1)
    {
        return error.ValueUseForwardSnapshotResolverMismatch;
    }
    const availability_body = functionBodyNamed(
        bodies,
        "core_availabilityForConsumption",
    ) orelse return error.ValueUseForwardSnapshotCaptureMismatch;
    const availability = source[availability_body.start..availability_body.end];
    if (countPattern(availability, "captureForwardAdmissionSnapshot(transaction, index)") != 1 or
        std.mem.indexOf(u8, availability, "snapshot.eql(&current)") == null or
        std.mem.indexOf(u8, availability, "forward_snapshots[index] = current") == null or
        std.mem.indexOf(u8, availability, "ValueUseUnresolvedSource") != null)
    {
        return error.ValueUseForwardSnapshotCaptureMismatch;
    }
    const closed_errors = [_][]const u8{
        "error.ValueUseForwardPlanMissing",
        "error.ValueUseForwardPlanMalformed",
        "error.ValueUseForwardPlanStale",
        "error.ValueUseForwardIntervalExpired",
        "error.ValueUseForwardTypeMismatch",
        "error.ValueUseForwardAssignmentMissing",
        "error.ValueUseForwardSnapshotCapacityExceeded",
    };
    for (closed_errors) |closed_error| {
        if (std.mem.indexOf(u8, source, closed_error) == null)
            return error.ValueUseForwardSnapshotErrorTableMismatch;
    }
}

pub fn validateLifetimeContextAuthority(source: [:0]const u8) !void {
    const pin_start = std.mem.indexOf(u8, source, "const CallFinalUsePin = struct {") orelse
        return error.ValueUseLifetimeContextMissing;
    const context_start = std.mem.indexOfPos(
        u8,
        source,
        pin_start,
        "const LifetimeContext = struct {",
    ) orelse return error.ValueUseLifetimeContextMissing;
    const pin = source[pin_start..context_start];
    if (std.mem.indexOf(u8, pin, "ValueLoc") != null or
        std.mem.indexOf(u8, pin, "const LifetimePin = struct {") == null or
        std.mem.indexOf(u8, pin, "generation: usize") == null or
        std.mem.indexOf(u8, pin, "const CallFinalUsePin = struct {") == null or
        std.mem.indexOf(u8, pin, "plan_identity: usize") == null or
        std.mem.indexOf(u8, pin, "admission_position: usize") == null or
        std.mem.indexOf(u8, pin, "interval_end: usize") == null or
        std.mem.indexOf(u8, pin, "call_final_use: ?CallFinalUsePin = null") == null or
        std.mem.indexOf(u8, pin, "[]") != null or
        std.mem.indexOf(u8, pin, "*") != null or
        std.mem.indexOf(u8, source, "pub const LifetimePin") != null or
        std.mem.indexOf(u8, source, "pub const LifetimeContext") != null or
        std.mem.indexOf(u8, source, "pub fn availabilityForConsumption") != null or
        std.mem.indexOf(u8, source, "pub fn mustSurviveInstruction") != null or
        std.mem.indexOf(u8, source, "pub fn occupantNeedsPreservation") != null)
    {
        return error.ValueUseLifetimeContextEscaped;
    }

    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const availability_body = functionBodyNamed(
        bodies,
        "core_availabilityForConsumption",
    ) orelse return error.ValueUseLifetimeContextMissing;
    const survival_body = functionBodyNamed(
        bodies,
        "core_mustSurviveInstruction",
    ) orelse return error.ValueUseLifetimeContextMissing;
    const occupant_body = functionBodyNamed(
        bodies,
        "core_occupantNeedsPreservation",
    ) orelse return error.ValueUseLifetimeContextMissing;
    const availability = source[availability_body.start..availability_body.end];
    const survival = source[survival_body.start..survival_body.end];
    const occupant = source[occupant_body.start..occupant_body.end];
    const admit_body = functionBodyNamed(bodies, "admitCallFinalUse") orelse
        return error.ValueUseCallFinalUseAuthorityMissing;
    const revalidate_body = functionBodyNamed(bodies, "revalidateCallFinalUse") orelse
        return error.ValueUseCallFinalUseAuthorityMissing;
    const claim_body = functionBodyNamed(bodies, "callFinalUseClaim") orelse
        return error.ValueUseCallFinalUseAuthorityMissing;
    const validate_body = functionBodyNamed(bodies, "validateCallFinalUseRequest") orelse
        return error.ValueUseCallFinalUseAuthorityMissing;
    const admit = source[admit_body.start..admit_body.end];
    const revalidate = source[revalidate_body.start..revalidate_body.end];
    const claim = source[claim_body.start..claim_body.end];
    const final_validate = source[validate_body.start..validate_body.end];
    const availability_required = [_][]const u8{
        ".int, .null_value => return",
        "error.ValueUseSourcePlanMissing",
        "error.ValueUseSourceIntervalMissing",
        "validateAddressDependenciesForUse(",
        "valueIsLiveAtOrAfterCurrent(",
        "error.ValueUseExpiredSource",
        "pin.generation != binding.vreg.index",
        "error.ValueUseSourceGenerationChanged",
        "admitCallFinalUse(",
        "revalidateCallFinalUse(",
    };
    for (availability_required) |pattern| {
        if (std.mem.indexOf(u8, availability, pattern) == null)
            return error.ValueUseLifetimeContextMissing;
    }
    if (std.mem.indexOf(u8, availability, "ValueLoc") != null or
        countPattern(survival, "core_availabilityForConsumption(") != 1 or
        countPattern(survival, "valueIsLiveAfterCurrent(") != 1 or
        countPattern(survival, "valueIsLiveAtOrAfterCurrent(") != 0 or
        countPattern(occupant, "source_name") < 2 or
        countPattern(occupant, "intervalEnd(") != 1 or
        countPattern(occupant, "validateAddressDependenciesForUse(") != 1 or
        countPattern(occupant, "valueIsLiveAfterCurrent(") != 1 or
        countPattern(occupant, "valueIsLiveAtOrAfterCurrent(") != 0)
    {
        return error.ValueUseLifetimeContextBoundaryMismatch;
    }
    for ([_][]const u8{
        "position == 0",
        "interval_end != position - 1",
        "@intFromPtr(plan)",
        ".call_final_use = .{",
    }) |pattern| {
        if (std.mem.indexOf(u8, admit, pattern) == null)
            return error.ValueUseCallFinalUseAuthorityMismatch;
    }
    for ([_][]const u8{
        "final_use.plan_identity",
        "final_use.admission_position",
        "final_use.interval_end",
        "error.ValueUseSourceGenerationChanged",
    }) |pattern| {
        if (std.mem.indexOf(u8, revalidate, pattern) == null)
            return error.ValueUseCallFinalUseAuthorityMismatch;
    }
    if (countPattern(claim, ".direct_call") != 1 or
        countPattern(claim, ".int_byte_size_call") != 1 or
        countPattern(final_validate, "binding.loc != .eax") != 2 or
        countPattern(final_validate, "binding.loc != .rax") != 1 or
        countPattern(source, "fn admitCallFinalUse(") != 1 or
        countPattern(source, "fn revalidateCallFinalUse(") != 1 or
        std.mem.indexOf(u8, source, "pub fn admitCallFinalUse(") != null or
        std.mem.indexOf(u8, source, "pub fn revalidateCallFinalUse(") != null or
        std.mem.indexOf(u8, admit, "valueIsLive") != null or
        std.mem.indexOf(u8, revalidate, "valueIsLive") != null or
        std.mem.indexOf(u8, final_validate, "valueIsLive") != null)
    {
        return error.ValueUseCallFinalUseAuthorityMismatch;
    }
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

pub fn validateNamedScalarIntentSurface(source: []const u8) !void {
    const declarations = [_]struct {
        declaration: []const u8,
        required: []const []const u8,
    }{
        .{
            .declaration = "pub const NamedScalarBinaryAction = struct {",
            .required = &.{
                "result: ActionIdentity",
                "operation: ir.BinaryOp",
                "integer_ty: ir.Type",
                "exact_ei: bool",
                "rhs: RequestHandle",
            },
        },
        .{
            .declaration = "pub const ExactI52BinaryAction = struct {",
            .required = &.{ "result: ActionIdentity", "rhs: RequestHandle" },
        },
    };
    var present: usize = 0;
    for (declarations) |entry| {
        const start = std.mem.indexOf(u8, source, entry.declaration) orelse continue;
        present += 1;
        const end = std.mem.indexOfPos(u8, source, start, "};") orelse
            return error.InvalidZigSource;
        const body = source[start .. end + 2];
        for (entry.required) |pattern|
            if (countPattern(body, pattern) != 1)
                return error.ValueUseNamedScalarIntentMismatch;
        const forbidden = [_][]const u8{
            "ArgReg",   "RegPair", "ValueLoc", "Destination", "PreparedView",
            "home",     "binding", "scratch",  "spill",       "displacement",
            "sequence", "phase",
        };
        for (forbidden) |pattern|
            if (std.mem.indexOf(u8, body, pattern) != null)
                return error.ValueUseNamedScalarPhysicalIntentEscape;
        if (countPattern(body, ",") != entry.required.len)
            return error.ValueUseNamedScalarIntentMismatch;
    }
    if (present != 0 and present != declarations.len)
        return error.ValueUseNamedScalarIntentMissing;
    if (present == 0) return;

    const exact_sets = [_]struct {
        declaration: []const u8,
        required: []const []const u8,
    }{
        .{
            .declaration = "pub const NamedScalarRequestError = error{",
            .required = &.{
                "ValueUseNamedScalarFormUnsupported",
                "ValueUseNamedScalarWidthUnsupported",
                "ValueUseNamedScalarLocationUnsupported",
                "ValueUseNamedScalarScratchUnavailable",
                "ValueUseNamedScalarExactEiUnsupported",
                "ValueUseNamedScalarI52EnvelopeUnsupported",
            },
        },
        .{
            .declaration = "pub const NamedScalarTestFailure = enum {",
            .required = &.{
                "after_preamble",
                "after_canonical_refresh",
                "after_first_operand_staging",
                "after_accumulator_preparation",
                "after_second_operand_staging",
                "after_first_arithmetic_write",
                "after_second_arithmetic_write",
                "after_result_identity_ownership",
                "after_result_definition",
                "after_finalization",
            },
        },
    };
    for (exact_sets) |entry| {
        const start = std.mem.indexOf(u8, source, entry.declaration) orelse
            return error.ValueUseNamedScalarIntentMissing;
        const end = std.mem.indexOfPos(u8, source, start, "};") orelse
            return error.InvalidZigSource;
        const body = source[start .. end + 2];
        for (entry.required) |pattern|
            if (countPattern(body, pattern) != 1)
                return error.ValueUseNamedScalarIntentMismatch;
        if (countPattern(body, ",") != entry.required.len)
            return error.ValueUseNamedScalarIntentMismatch;
    }

    const exact_members = [_]struct {
        declaration: []const u8,
        member: []const u8,
    }{
        .{ .declaration = "pub const UseForm = enum {", .member = "named_scalar_operand," },
        .{
            .declaration = "pub const PreparedAction = union(enum) {",
            .member = "named_scalar_binary: NamedScalarBinaryAction,",
        },
        .{
            .declaration = "pub const PreparedAction = union(enum) {",
            .member = "exact_i52_binary: ExactI52BinaryAction,",
        },
    };
    for (exact_members) |entry| {
        const start = std.mem.indexOf(u8, source, entry.declaration) orelse
            return error.ValueUseNamedScalarIntentMissing;
        const end = std.mem.indexOfPos(u8, source, start, "};") orelse
            return error.InvalidZigSource;
        if (countPattern(source[start .. end + 2], entry.member) != 1)
            return error.ValueUseNamedScalarIntentMismatch;
    }
    for ([_][]const u8{
        "pub fn attachNamedScalarBinaryAction(",
        "pub fn attachExactI52BinaryAction(",
    }) |pattern|
        if (countPattern(source, pattern) != 1)
            return error.ValueUseNamedScalarIntentMismatch;
}

pub fn validateScalarMultiplyIntentSurface(source: []const u8) !void {
    const declaration = "pub const ScalarMultiplyAction = struct {";
    const start = std.mem.indexOf(u8, source, declaration) orelse return;
    const end = std.mem.indexOfPos(u8, source, start, "};") orelse
        return error.InvalidZigSource;
    const body = source[start .. end + 2];
    for ([_][]const u8{
        "result: ActionIdentity",
        "integer_ty: ir.Type",
        "rhs: RequestHandle",
    }) |field|
        if (countPattern(body, field) != 1)
            return error.ValueUseScalarMultiplyIntentMismatch;
    for ([_][]const u8{
        "ArgReg",  "ValueLoc", "Destination", "PreparedView", "home",
        "binding", "scratch",  "spill",       "displacement", "sequence",
        "phase",
    }) |forbidden|
        if (std.mem.indexOf(u8, body, forbidden) != null)
            return error.ValueUseScalarMultiplyPhysicalIntentEscape;
    if (countPattern(body, ",") != 3)
        return error.ValueUseScalarMultiplyIntentMismatch;

    const exact_sets = [_]struct {
        declaration: []const u8,
        required: []const []const u8,
    }{
        .{
            .declaration = "pub const ScalarMultiplyRequestError = error{",
            .required = &.{
                "ValueUseScalarMultiplyFormUnsupported",
                "ValueUseScalarMultiplyWidthUnsupported",
                "ValueUseScalarMultiplyLocationUnsupported",
                "ValueUseScalarMultiplyDestinationUnavailable",
            },
        },
        .{
            .declaration = "pub const ScalarMultiplyTestFailure = enum {",
            .required = &.{
                "after_destination_selection",
                "after_lhs_preservation",
                "after_canonical_refresh",
                "after_lhs_staging",
                "after_rhs_resolution",
                "after_rhs_staging",
                "after_accumulator_preparation",
                "after_lhs_accumulator_reload",
                "after_multiply",
                "after_result_identity_ownership",
                "after_result_definition",
                "after_finalization",
            },
        },
    };
    for (exact_sets) |entry| {
        const set_start = std.mem.indexOf(u8, source, entry.declaration) orelse
            return error.ValueUseScalarMultiplyIntentMissing;
        const set_end = std.mem.indexOfPos(u8, source, set_start, "};") orelse
            return error.InvalidZigSource;
        const set_body = source[set_start .. set_end + 2];
        for (entry.required) |member|
            if (countPattern(set_body, member) != 1)
                return error.ValueUseScalarMultiplyIntentMismatch;
        if (countPattern(set_body, ",") != entry.required.len)
            return error.ValueUseScalarMultiplyIntentMismatch;
    }
    const action_start = std.mem.indexOf(u8, source, "pub const PreparedAction = union(enum) {") orelse
        return error.ValueUseScalarMultiplyIntentMissing;
    const action_end = std.mem.indexOfPos(u8, source, action_start, "};") orelse
        return error.InvalidZigSource;
    if (countPattern(
        source[action_start .. action_end + 2],
        "scalar_multiply: ScalarMultiplyAction,",
    ) != 1)
        return error.ValueUseScalarMultiplyIntentMismatch;
    if (countPattern(source, "pub fn attachScalarMultiplyAction(") != 1)
        return error.ValueUseScalarMultiplyIntentMismatch;
}

pub fn validateUnsignedQuotientIntentSurface(source: []const u8) !void {
    const declaration = "pub const UnsignedQuotientAction = struct {";
    const start = std.mem.indexOf(u8, source, declaration) orelse return;
    const end = std.mem.indexOfPos(u8, source, start, "};") orelse
        return error.InvalidZigSource;
    const body = source[start .. end + 2];
    for ([_][]const u8{
        "result: ActionIdentity",
        "integer_ty: ir.Type",
        "rhs: RequestHandle",
    }) |field|
        if (countPattern(body, field) != 1)
            return error.ValueUseUnsignedQuotientIntentMismatch;
    for ([_][]const u8{
        "ArgReg",  "ValueLoc", "Destination", "PreparedView", "home",
        "binding", "scratch",  "spill",       "displacement", "sequence",
        "phase",
    }) |forbidden|
        if (std.mem.indexOf(u8, body, forbidden) != null)
            return error.ValueUseUnsignedQuotientPhysicalIntentEscape;
    if (countPattern(body, ",") != 3)
        return error.ValueUseUnsignedQuotientIntentMismatch;

    const exact_sets = [_]struct {
        declaration: []const u8,
        required: []const []const u8,
    }{
        .{
            .declaration = "pub const UnsignedQuotientRequestError = error{",
            .required = &.{
                "ValueUseUnsignedQuotientFormUnsupported",
                "ValueUseUnsignedQuotientWidthUnsupported",
                "ValueUseUnsignedQuotientLocationUnsupported",
            },
        },
        .{
            .declaration = "pub const UnsignedQuotientTestFailure = enum {",
            .required = &.{
                "after_rhs_classification",
                "after_rhs_accumulator_staging",
                "after_accumulator_preparation",
                "after_lhs_materialization",
                "after_rhs_non_accumulator_staging",
                "after_rdx_preservation",
                "after_zero_high_dividend",
                "after_divide",
                "after_result_identity_ownership",
                "after_result_definition",
                "after_finalization",
            },
        },
    };
    for (exact_sets) |entry| {
        const set_start = std.mem.indexOf(u8, source, entry.declaration) orelse
            return error.ValueUseUnsignedQuotientIntentMissing;
        const set_end = std.mem.indexOfPos(u8, source, set_start, "};") orelse
            return error.InvalidZigSource;
        const set_body = source[set_start .. set_end + 2];
        for (entry.required) |member|
            if (countPattern(set_body, member) != 1)
                return error.ValueUseUnsignedQuotientIntentMismatch;
        if (countPattern(set_body, ",") != entry.required.len)
            return error.ValueUseUnsignedQuotientIntentMismatch;
    }
    const action_start = std.mem.indexOf(u8, source, "pub const PreparedAction = union(enum) {") orelse
        return error.ValueUseUnsignedQuotientIntentMissing;
    const action_end = std.mem.indexOfPos(u8, source, action_start, "};") orelse
        return error.InvalidZigSource;
    if (countPattern(
        source[action_start .. action_end + 2],
        "unsigned_quotient: UnsignedQuotientAction,",
    ) != 1)
        return error.ValueUseUnsignedQuotientIntentMismatch;
    if (countPattern(source, "pub fn attachUnsignedQuotientAction(") != 1)
        return error.ValueUseUnsignedQuotientIntentMismatch;
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
    try validateScalarDisplacementAuthorityDistinction(source);

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

pub fn validateScalarDisplacementAuthorityDistinction(source: [:0]const u8) !void {
    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const cast_body = functionBodyNamed(bodies, "scalarCastSourceDisplacement") orelse return;
    const immediate_body = functionBodyNamed(bodies, "immediateSourceDisplacement") orelse
        return error.ValueUseScalarDisplacementAuthorityMismatch;
    const plan_body = functionBodyNamed(bodies, "immediateDisplacementAuthority") orelse
        return error.ValueUseScalarDisplacementAuthorityMismatch;
    const cast = source[cast_body.start..cast_body.end];
    const immediate = source[immediate_body.start..immediate_body.end];
    const plan = source[plan_body.start..plan_body.end];

    // Cast reuse is deliberately location-derived and liveness-independent.
    // Immediate arithmetic reuse is deliberately routed through the private
    // Q2 authority, while exact closed plans retain an independent inclusive
    // preserve-current branch. Cast reuse remains liveness-independent.
    if (countPattern(cast, ".eax, .rax") != 1 or
        countPattern(cast, ".reuse_source") != 1 or
        countPattern(cast, "valueIsLiveAfterCurrent(") != 0 or
        countPattern(cast, "valueIsLiveAtOrAfterCurrent(") != 0 or
        countPattern(immediate, ".eax, .rax") != 2 or
        countPattern(immediate, ".reuse_source") != 1 or
        countPattern(immediate, "Authority.mustSurviveInstruction(") != 1 or
        countPattern(immediate, ".inclusive_preserve_current") != 1 or
        countPattern(immediate, ".spill_source = identity") != 1 or
        countPattern(immediate, "selector_state.valueIsLiveAfterCurrent(") != 0 or
        countPattern(immediate, "valueIsLiveAtOrAfterCurrent(") != 0)
    {
        return error.ValueUseScalarDisplacementAuthorityMismatch;
    }
    const plan_required = [_][]const u8{
        ".r00_signed_divide_by_two,",
        ".r03_arithmetic_shift_right_accumulator,",
        ".r04_narrow_accumulator_immediate,",
        "=> .liveness_aware",
        ".r02_shift_left_accumulator => if (bits <= 32)",
        ".inclusive_preserve_current",
        ".r05_wide_accumulator_immediate => .inclusive_preserve_current",
        ".r01_logical_shift_right_accumulator,",
        ".l01_reverse_subtract,",
        ".l02_variable_shift_left,",
        ".l03_variable_logical_shift_right,",
        "=> .hardcoded",
        ".r06_wide_scratch_immediate,",
        "=> .none",
    };
    for (plan_required) |pattern| {
        if (std.mem.indexOf(u8, plan, pattern) == null)
            return error.ValueUseScalarDisplacementAuthorityMismatch;
    }
    if (std.mem.indexOf(u8, plan, "transaction") != null or
        std.mem.indexOf(u8, plan, "selector") != null or
        std.mem.indexOf(u8, plan, "ValueLoc") != null or
        std.mem.indexOf(u8, plan, "function") != null or
        std.mem.indexOf(u8, plan, "family") != null)
    {
        return error.ValueUseScalarDisplacementAuthorityMismatch;
    }
}

pub fn validateImmediateScalarAccumulatorPreamble(source: [:0]const u8) !void {
    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const execute_body = functionBodyNamed(bodies, "executeImmediateRhsScalar") orelse return;
    const plan_body = functionBodyNamed(bodies, "immediateAccumulatorPreamble") orelse
        return error.ValueUseImmediateScalarPreambleMissing;
    const preserve_body = functionBodyNamed(bodies, "preserveImmediateUnrelatedAccumulator") orelse
        return error.ValueUseImmediateScalarPreambleMissing;
    const refresh_body = functionBodyNamed(bodies, "refreshImmediateScalarSource") orelse
        return error.ValueUseImmediateScalarPreambleMissing;
    const materialize_body = functionBodyNamed(bodies, "materializeImmediateAccumulator") orelse
        return error.ValueUseImmediateScalarPreambleMissing;
    const execute = source[execute_body.start..execute_body.end];
    const plan = source[plan_body.start..plan_body.end];
    const preserve = source[preserve_body.start..preserve_body.end];
    const refresh_source = source[refresh_body.start..refresh_body.end];
    const materialize_source = source[materialize_body.start..materialize_body.end];

    const validate_source = std.mem.indexOf(
        u8,
        execute,
        "try validateImmediateScalarSource(",
    ) orelse return error.ValueUseImmediateScalarPreambleOrder;
    const preserve_call = std.mem.indexOf(
        u8,
        execute,
        "try preserveImmediateUnrelatedAccumulator(",
    ) orelse return error.ValueUseImmediateScalarPreambleMissing;
    const dispatch = std.mem.indexOf(
        u8,
        execute,
        "switch (semantic_plan) {",
    ) orelse return error.ValueUseImmediateScalarPreambleOrder;
    if (!(validate_source < preserve_call and preserve_call < dispatch) or
        countPattern(execute, "preserveImmediateUnrelatedAccumulator(") != 1 or
        countPattern(execute, "immediateAccumulatorPreamble(semantic_plan, bits)") != 1)
    {
        return error.ValueUseImmediateScalarPreambleOrder;
    }

    const plan_forbidden = [_][]const u8{
        "transaction",
        "selector",
        "ValueLoc",
        ".eax",
        ".rax",
        "function",
        "family",
    };
    for (plan_forbidden) |pattern| {
        if (std.mem.indexOf(u8, plan, pattern) != null)
            return error.ValueUseImmediateScalarPreamblePhysicalPredicate;
    }
    if (countPattern(plan, ".r02_shift_left_accumulator => if (bits <= 32) .scratch_preferred else .spill_source") != 1 or
        countPattern(plan, ".r03_arithmetic_shift_right_accumulator,") != 1 or
        countPattern(plan, ".r04_narrow_accumulator_immediate,") != 1 or
        countPattern(plan, "=> .scratch_preferred") != 1 or
        countPattern(plan, ".r05_wide_accumulator_immediate => .spill_source") != 1 or
        countPattern(plan, "=> .none") != 1)
    {
        return error.ValueUseImmediateScalarPreamblePlanMismatch;
    }

    const preserve_required = [_][]const u8{
        "if (preamble == .none) return;",
        "Authority.occupantNeedsPreservation(",
        ".accumulator,",
        "preserveLiveAccumulatorValue(",
        "selector_state.spillValue(",
        ".eax, .rax",
        "selector_state.bindValueLoc(",
        "after_preservation",
        "refreshImmediateScalarSource(",
        "validateImmediateScalarSource(",
        "after_canonical_refresh",
        "eflags.validateSnapshot(flags_before)",
    };
    for (preserve_required) |pattern| {
        if (std.mem.indexOf(u8, preserve, pattern) == null)
            return error.ValueUseImmediateScalarPreambleMissing;
    }
    const preserve_once = [_][]const u8{
        "preserveLiveAccumulatorValue(",
        "selector_state.spillValue(",
        "refreshImmediateScalarSource(",
        "validateImmediateScalarSource(",
        "eflags.validateSnapshot(flags_before)",
    };
    for (preserve_once) |pattern| {
        if (countPattern(preserve, pattern) != 1)
            return error.ValueUseImmediateScalarPreambleOrder;
    }
    const preserve_write = std.mem.indexOf(
        u8,
        preserve,
        "selector_state.bindValueLoc(",
    ) orelse return error.ValueUseImmediateScalarPreambleMissing;
    const refresh = std.mem.indexOf(
        u8,
        preserve,
        "try refreshImmediateScalarSource(",
    ) orelse return error.ValueUseImmediateScalarPreambleMissing;
    if (!(preserve_write < refresh))
        return error.ValueUseImmediateScalarPreambleOrder;

    if (countPattern(preserve, "Authority.occupantNeedsPreservation(") != 1 or
        countPattern(preserve, "source_index,") < 1 or
        countPattern(refresh_source, "Authority.availabilityForConsumption(") != 1 or
        countPattern(materialize_source, "Authority.availabilityForConsumption(") != 1 or
        functionBodyNamed(bodies, "immediateUnrelatedLiveAccumulatorName") != null)
    {
        return error.ValueUseImmediateScalarPreambleLivenessMismatch;
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
    const named_scalar_preamble_count: usize =
        @intFromBool(functionBodyNamed(bodies, "executeNamedScalarBinary") != null);
    const direct_liveness_preamble_count: usize =
        1 +
        @as(usize, @intFromBool(functionBodyNamed(bodies, "preserveCurrentHomeSignBitLiveAccumulator") != null)) +
        named_scalar_preamble_count;
    const preservation_preamble_count =
        direct_liveness_preamble_count +
        @as(usize, @intFromBool(functionBodyNamed(bodies, "preserveImmediateUnrelatedAccumulator") != null)) +
        named_scalar_preamble_count;

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
            direct_liveness_preamble_count or
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
