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
const validateForwardAdmissionSnapshotAuthority = support.validateForwardAdmissionSnapshotAuthority;
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
const validateImmediateScalarIntentSurface = support.validateImmediateScalarIntentSurface;
const validateNamedScalarIntentSurface = support.validateNamedScalarIntentSurface;
const validateScalarMultiplyIntentSurface = support.validateScalarMultiplyIntentSurface;
const validateUnsignedQuotientIntentSurface = support.validateUnsignedQuotientIntentSurface;
const validateScalarCastDisplacementPlan = support.validateScalarCastDisplacementPlan;
const validateScalarDisplacementAuthorityDistinction = support.validateScalarDisplacementAuthorityDistinction;
const validateLifetimeContextAuthority = support.validateLifetimeContextAuthority;
const validateImmediateScalarAccumulatorPreamble = support.validateImmediateScalarAccumulatorPreamble;
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
    @memcpy(
        result[start + replacement.len ..],
        source[start + needle.len ..],
    );
    return result;
}

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
        "const LifetimePin = struct { identity: u8, generation: usize };" ++
        "const LifetimeContext = struct { pins: u8 };" ++
        "fn core_availabilityForConsumption() void {" ++
        "switch (source) { .int, .null_value => return, else => {} }" ++
        "_ = error.ValueUseSourcePlanMissing;" ++
        "_ = error.ValueUseSourceIntervalMissing;" ++
        "_ = validateAddressDependenciesForUse(source);" ++
        "_ = valueIsLiveAtOrAfterCurrent(source);" ++
        "_ = error.ValueUseExpiredSource;" ++
        "if (pin.generation != binding.vreg.index) _ = error.ValueUseSourceGenerationChanged;" ++
        "}" ++
        "fn core_mustSurviveInstruction() void {" ++
        "_ = core_availabilityForConsumption(source);" ++
        "_ = valueIsLiveAfterCurrent(source);" ++
        "}" ++
        "fn core_occupantNeedsPreservation() void {" ++
        "_ = source_name; _ = source_name;" ++
        "_ = plan.intervalEnd(name);" ++
        "_ = validateAddressDependenciesForUse(name);" ++
        "_ = valueIsLiveAfterCurrent(name);" ++
        "}" ++
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

test "composed selector source guard freezes semantic-only immediate scalar intents" {
    const accepted =
        "pub const ImmediateRhsScalarAction = struct { result: ActionIdentity, operation: ir.BinaryOp, integer_ty: ir.Type, literal: i128, };" ++
        "pub const ImmediateLhsScalarAction = struct { result: ActionIdentity, operation: ir.BinaryOp, integer_ty: ir.Type, literal: i128, };";
    try validateImmediateScalarIntentSurface(accepted);
    try std.testing.expectError(
        error.ValueUseImmediateScalarPhysicalIntentEscape,
        validateImmediateScalarIntentSurface(
            "pub const ImmediateRhsScalarAction = struct { result: ActionIdentity, operation: ir.BinaryOp, integer_ty: ir.Type, literal: i128, destination: ArgReg, };" ++
                "pub const ImmediateLhsScalarAction = struct { result: ActionIdentity, operation: ir.BinaryOp, integer_ty: ir.Type, literal: i128, };",
        ),
    );
    try std.testing.expectError(
        error.ValueUseImmediateScalarIntentMissing,
        validateImmediateScalarIntentSurface(
            "pub const ImmediateRhsScalarAction = struct { result: ActionIdentity, operation: ir.BinaryOp, integer_ty: ir.Type, literal: i128, };",
        ),
    );
}

test "composed selector source guard freezes the closed scalar cast displacement table" {
    const plan_declaration =
        "const AccumulatorScalarCastPlan = enum { " ++
        "c04_exact_ei, c05_narrow_zext, c52_0_trunc_i64_to_i52, " ++
        "c52_1_zext_i6_to_i52, c52_2_zext_i52_to_i64, c52_3_trunc_i52, };";
    const plan =
        "fn scalarCastPlan(action: anytype) void { _ = action; " ++
        "_ = .c04_exact_ei; _ = .c05_narrow_zext; " ++
        "_ = .c52_0_trunc_i64_to_i52; _ = .c52_1_zext_i6_to_i52; " ++
        "_ = .c52_2_zext_i52_to_i64; _ = .c52_3_trunc_i52; }";
    const source_displacement =
        "fn scalarCastSourceDisplacement() void { _ = switch (source) { " ++
        ".int => .spill_live, .named => switch (home) { " ++
        ".eax, .rax => .reuse_source, else => .spill_live, }, }; }";
    const accepted_displacement =
        "fn scalarCastDisplacement() void { " ++
        "if (plan == .c52_0_trunc_i64_to_i52) return .spill_live; " ++
        "return scalarCastSourceDisplacement(); }";
    try validateScalarCastDisplacementPlan(
        plan_declaration ++ plan ++ accepted_displacement ++ source_displacement,
    );

    const widened_displacement =
        "fn scalarCastDisplacement() void { " ++
        "if (plan == .c04_exact_ei) return .spill_live; " ++
        "return scalarCastSourceDisplacement(); }";
    try std.testing.expectError(
        error.ValueUseScalarCastSequenceMismatch,
        validateScalarCastDisplacementPlan(
            plan_declaration ++ plan ++ widened_displacement ++ source_displacement,
        ),
    );
}

test "composed selector source guard freezes distinct cast and arithmetic displacement authorities" {
    const displacement_plan =
        \\fn immediateDisplacementAuthority() void {
        \\    return switch (plan) {
        \\        .r00_signed_divide_by_two,
        \\        .r03_arithmetic_shift_right_accumulator,
        \\        .r04_narrow_accumulator_immediate,
        \\        => .liveness_aware,
        \\        .r02_shift_left_accumulator => if (bits <= 32)
        \\            .liveness_aware
        \\        else
        \\            .inclusive_preserve_current,
        \\        .r05_wide_accumulator_immediate => .inclusive_preserve_current,
        \\        .r01_logical_shift_right_accumulator,
        \\        .l01_reverse_subtract,
        \\        .l02_variable_shift_left,
        \\        .l03_variable_logical_shift_right,
        \\        => .hardcoded,
        \\        .r01_logical_shift_right_scratch,
        \\        .r02_shift_left_scratch32_writeback,
        \\        .r03_arithmetic_shift_right_scratch64,
        \\        .r06_wide_scratch_immediate,
        \\        => .none,
        \\    };
        \\}
    ;
    const cast =
        \\fn scalarCastSourceDisplacement() void {
        \\    return switch (source) {
        \\        .named => switch (home) {
        \\            .eax, .rax => .{ .reuse_source = identity },
        \\            else => .spill_live,
        \\        },
        \\        else => .spill_live,
        \\    };
        \\}
    ;
    const immediate =
        \\fn immediateSourceDisplacement(comptime Authority: type) void {
        \\    const identity = switch (source) {
        \\        .named => name,
        \\        else => return fallback,
        \\    };
        \\    return switch (authority) {
        \\        .liveness_aware => switch (home) {
        \\            .eax, .rax => if (!try Authority.mustSurviveInstruction(Authority, transaction, source_index))
        \\                .{ .reuse_source = identity }
        \\            else
        \\                fallback,
        \\            else => fallback,
        \\        },
        \\        .inclusive_preserve_current => switch (home) {
        \\            .eax, .rax => .{ .spill_source = identity },
        \\            else => fallback,
        \\        },
        \\        else => fallback,
        \\    };
        \\}
    ;
    try validateScalarDisplacementAuthorityDistinction(cast ++ displacement_plan ++ immediate);

    const at_or_after =
        \\fn scalarCastSourceDisplacement() void {
        \\    return switch (source) {
        \\        .named => switch (home) {
        \\            .eax, .rax => .{ .reuse_source = identity },
        \\            else => .spill_live,
        \\        },
        \\        else => .spill_live,
        \\    };
        \\}
        \\fn immediateSourceDisplacement(comptime Authority: type) void {
        \\    const identity = switch (source) {
        \\        .named => name,
        \\        else => return fallback,
        \\    };
        \\    return switch (authority) {
        \\        .liveness_aware => switch (home) {
        \\            .eax, .rax => if (!try Authority.valueIsLiveAtOrAfterCurrent(Authority, transaction, source_index))
        \\                .{ .reuse_source = identity }
        \\            else
        \\                fallback,
        \\            else => fallback,
        \\        },
        \\        .inclusive_preserve_current => switch (home) {
        \\            .eax, .rax => .{ .spill_source = identity },
        \\            else => fallback,
        \\        },
        \\        else => fallback,
        \\    };
        \\}
    ;
    try std.testing.expectError(
        error.ValueUseScalarDisplacementAuthorityMismatch,
        validateScalarDisplacementAuthorityDistinction(displacement_plan ++ at_or_after),
    );
    const widened_cast =
        \\fn scalarCastSourceDisplacement() void {
        \\    _ = try selector_state.valueIsLiveAfterCurrent(selector, identity);
        \\    return switch (source) {
        \\        .named => switch (home) {
        \\            .eax, .rax => .{ .reuse_source = identity },
        \\            else => .spill_live,
        \\        },
        \\        else => .spill_live,
        \\    };
        \\}
    ++ displacement_plan ++ immediate;
    try std.testing.expectError(
        error.ValueUseScalarDisplacementAuthorityMismatch,
        validateScalarDisplacementAuthorityDistinction(widened_cast),
    );
}

test "composed selector source guard freezes private three-question lifetime authority" {
    const accepted: [:0]const u8 =
        @embedFile("../value_use/model.zig") ++
        @embedFile("../value_use/core.zig") ++
        @embedFile("../value_use/planning/lifetime_admission.zig");
    try validateLifetimeContextAuthority(accepted);

    const escaped = try replaceOnceSentinel(
        std.testing.allocator,
        accepted,
        "const LifetimeContext = struct {",
        "pub const LifetimeContext = struct {",
    );
    defer std.testing.allocator.free(escaped);
    try std.testing.expectError(
        error.ValueUseLifetimeContextEscaped,
        validateLifetimeContextAuthority(escaped),
    );

    const retained_location = try replaceOnceSentinel(
        std.testing.allocator,
        accepted,
        "generation: usize,",
        "generation: usize,\n    location: ValueLoc,",
    );
    defer std.testing.allocator.free(retained_location);
    try std.testing.expectError(
        error.ValueUseLifetimeContextEscaped,
        validateLifetimeContextAuthority(retained_location),
    );

    const collapsed_error = try replaceOnceSentinel(
        std.testing.allocator,
        accepted,
        "return error.ValueUseSourcePlanMissing;",
        "return error.ValueUseExpiredSource;",
    );
    defer std.testing.allocator.free(collapsed_error);
    try std.testing.expectError(
        error.ValueUseLifetimeContextMissing,
        validateLifetimeContextAuthority(collapsed_error),
    );

    const collapsed_interval_error = try replaceOnceSentinel(
        std.testing.allocator,
        accepted,
        "return error.ValueUseSourceIntervalMissing;",
        "return error.ValueUseExpiredSource;",
    );
    defer std.testing.allocator.free(collapsed_interval_error);
    try std.testing.expectError(
        error.ValueUseLifetimeContextMissing,
        validateLifetimeContextAuthority(collapsed_interval_error),
    );
}

test "composed selector source guard freezes exact structural forward admission snapshots" {
    const accepted: [:0]const u8 =
        @embedFile("../value_use/model.zig") ++
        @embedFile("../value_use/planning/lifetime_admission.zig");
    try validateForwardAdmissionSnapshotAuthority(accepted);

    const borrowed_plan = try replaceOnceSentinel(
        std.testing.allocator,
        accepted,
        "plan_identity: usize,",
        "plan: *const SelectorAllocationPlan,",
    );
    defer std.testing.allocator.free(borrowed_plan);
    try std.testing.expectError(
        error.ValueUseForwardSnapshotMissing,
        validateForwardAdmissionSnapshotAuthority(borrowed_plan),
    );

    const borrowed_location = try replaceOnceSentinel(
        std.testing.allocator,
        accepted,
        "plan_identity: usize,\n    identity: Identity,",
        "plan_identity: usize,\n    identity: Identity,\n    location: ValueLoc,",
    );
    defer std.testing.allocator.free(borrowed_location);
    try std.testing.expectError(
        error.ValueUseForwardSnapshotBorrowedState,
        validateForwardAdmissionSnapshotAuthority(borrowed_location),
    );

    const hashed = try replaceOnceSentinel(
        std.testing.allocator,
        accepted,
        "defined_width: u16,",
        "defined_width: u16,\n    hash: u64,",
    );
    defer std.testing.allocator.free(hashed);
    try std.testing.expectError(
        error.ValueUseForwardSnapshotBorrowedState,
        validateForwardAdmissionSnapshotAuthority(hashed),
    );

    const missing_capture = try replaceOnceSentinel(
        std.testing.allocator,
        accepted,
        "captureForwardAdmissionSnapshot(transaction, index) catch |err|",
        "reuseForwardAdmissionSnapshot(transaction, index) catch |err|",
    );
    defer std.testing.allocator.free(missing_capture);
    try std.testing.expectError(
        error.ValueUseForwardSnapshotCaptureMismatch,
        validateForwardAdmissionSnapshotAuthority(missing_capture),
    );

    const raw_resolution = try replaceOnceSentinel(
        std.testing.allocator,
        accepted,
        "selector_state.resolveForwardValueForUse(transaction.selector, name)",
        "selector_state.resolveValue(transaction.selector, name)",
    );
    defer std.testing.allocator.free(raw_resolution);
    try std.testing.expectError(
        error.ValueUseForwardSnapshotResolverMismatch,
        validateForwardAdmissionSnapshotAuthority(raw_resolution),
    );
}

test "composed selector source guard freezes immediate plan-derived alias preservation" {
    const accepted: [:0]const u8 =
        @embedFile("../value_use/actions/scalar_immediate.zig");
    try validateImmediateScalarAccumulatorPreamble(accepted);

    const widened_plan = try replaceOnceSentinel(
        std.testing.allocator,
        accepted,
        ".r05_wide_accumulator_immediate => .spill_source,",
        ".r05_wide_accumulator_immediate => .none,",
    );
    defer std.testing.allocator.free(widened_plan);
    try std.testing.expectError(
        error.ValueUseImmediateScalarPreamblePlanMismatch,
        validateImmediateScalarAccumulatorPreamble(widened_plan),
    );

    const source_excluded = try replaceOnceSentinel(
        std.testing.allocator,
        accepted,
        "Authority.occupantNeedsPreservation(",
        "Authority.consumerSelectedOccupant(",
    );
    defer std.testing.allocator.free(source_excluded);
    try std.testing.expectError(
        error.ValueUseImmediateScalarPreambleMissing,
        validateImmediateScalarAccumulatorPreamble(source_excluded),
    );
}

test "value-use named scalar semantic intent is exact and rejects physical choices" {
    const exact_tail =
        "pub const NamedScalarRequestError = error{ ValueUseNamedScalarFormUnsupported, ValueUseNamedScalarWidthUnsupported, ValueUseNamedScalarLocationUnsupported, ValueUseNamedScalarScratchUnavailable, ValueUseNamedScalarExactEiUnsupported, ValueUseNamedScalarI52EnvelopeUnsupported, };" ++
        "pub const NamedScalarTestFailure = enum { after_preamble, after_canonical_refresh, after_first_operand_staging, after_accumulator_preparation, after_second_operand_staging, after_first_arithmetic_write, after_second_arithmetic_write, after_result_identity_ownership, after_result_definition, after_finalization, };" ++
        "pub const UseForm = enum { named_scalar_operand, };" ++
        "pub const PreparedAction = union(enum) { named_scalar_binary: NamedScalarBinaryAction, exact_i52_binary: ExactI52BinaryAction, };" ++
        "pub fn attachNamedScalarBinaryAction() void {}" ++
        "pub fn attachExactI52BinaryAction() void {}";
    const accepted =
        "pub const NamedScalarBinaryAction = struct { result: ActionIdentity, operation: ir.BinaryOp, integer_ty: ir.Type, exact_ei: bool, rhs: RequestHandle, };" ++
        "pub const ExactI52BinaryAction = struct { result: ActionIdentity, rhs: RequestHandle, };" ++
        exact_tail;
    try validateNamedScalarIntentSurface(accepted);
    try std.testing.expectError(
        error.ValueUseNamedScalarPhysicalIntentEscape,
        validateNamedScalarIntentSurface(
            "pub const NamedScalarBinaryAction = struct { result: ActionIdentity, operation: ir.BinaryOp, integer_ty: ir.Type, exact_ei: bool, rhs: RequestHandle, home: ValueLoc, };" ++
                "pub const ExactI52BinaryAction = struct { result: ActionIdentity, rhs: RequestHandle, };" ++
                exact_tail,
        ),
    );
    try std.testing.expectError(
        error.ValueUseNamedScalarIntentMismatch,
        validateNamedScalarIntentSurface(
            "pub const NamedScalarBinaryAction = struct { result: ActionIdentity, operation: ir.BinaryOp, integer_ty: ir.Type, exact_ei: bool, rhs: RequestHandle, semantic_mode: bool, };" ++
                "pub const ExactI52BinaryAction = struct { result: ActionIdentity, rhs: RequestHandle, };" ++
                exact_tail,
        ),
    );
    try std.testing.expectError(
        error.ValueUseNamedScalarIntentMissing,
        validateNamedScalarIntentSurface(
            "pub const NamedScalarBinaryAction = struct { result: ActionIdentity, operation: ir.BinaryOp, integer_ty: ir.Type, exact_ei: bool, rhs: RequestHandle, };",
        ),
    );
}

test "value-use scalar multiply semantic intent is exact and rejects physical choices" {
    const accepted =
        "pub const ScalarMultiplyAction = struct { result: ActionIdentity, integer_ty: ir.Type, rhs: RequestHandle, };" ++
        "pub const ScalarMultiplyRequestError = error{ ValueUseScalarMultiplyFormUnsupported, ValueUseScalarMultiplyWidthUnsupported, ValueUseScalarMultiplyLocationUnsupported, ValueUseScalarMultiplyDestinationUnavailable, };" ++
        "pub const ScalarMultiplyTestFailure = enum { after_destination_selection, after_lhs_preservation, after_canonical_refresh, after_lhs_staging, after_rhs_resolution, after_rhs_staging, after_accumulator_preparation, after_lhs_accumulator_reload, after_multiply, after_result_identity_ownership, after_result_definition, after_finalization, };" ++
        "pub const PreparedAction = union(enum) { scalar_multiply: ScalarMultiplyAction, };" ++
        "pub fn attachScalarMultiplyAction() void {}";
    try validateScalarMultiplyIntentSurface(accepted);
    try std.testing.expectError(
        error.ValueUseScalarMultiplyPhysicalIntentEscape,
        validateScalarMultiplyIntentSurface(
            "pub const ScalarMultiplyAction = struct { result: ActionIdentity, integer_ty: ir.Type, rhs: RequestHandle, home: ValueLoc, };",
        ),
    );
    try std.testing.expectError(
        error.ValueUseScalarMultiplyIntentMismatch,
        validateScalarMultiplyIntentSurface(
            "pub const ScalarMultiplyAction = struct { result: ActionIdentity, integer_ty: ir.Type, rhs: RequestHandle, plan: bool, };",
        ),
    );
}

test "value-use unsigned quotient semantic intent is exact and rejects physical choices" {
    const accepted =
        "pub const UnsignedQuotientAction = struct { result: ActionIdentity, integer_ty: ir.Type, rhs: RequestHandle, };" ++
        "pub const UnsignedQuotientRequestError = error{ ValueUseUnsignedQuotientFormUnsupported, ValueUseUnsignedQuotientWidthUnsupported, ValueUseUnsignedQuotientLocationUnsupported, };" ++
        "pub const UnsignedQuotientTestFailure = enum { after_rhs_classification, after_rhs_accumulator_staging, after_accumulator_preparation, after_lhs_materialization, after_rhs_non_accumulator_staging, after_rdx_preservation, after_zero_high_dividend, after_divide, after_result_identity_ownership, after_result_definition, after_finalization, };" ++
        "pub const PreparedAction = union(enum) { unsigned_quotient: UnsignedQuotientAction, };" ++
        "pub fn attachUnsignedQuotientAction() void {}";
    try validateUnsignedQuotientIntentSurface(accepted);
    try std.testing.expectError(
        error.ValueUseUnsignedQuotientPhysicalIntentEscape,
        validateUnsignedQuotientIntentSurface(
            "pub const UnsignedQuotientAction = struct { result: ActionIdentity, integer_ty: ir.Type, rhs: RequestHandle, home: ValueLoc, };",
        ),
    );
    try std.testing.expectError(
        error.ValueUseUnsignedQuotientIntentMismatch,
        validateUnsignedQuotientIntentSurface(
            "pub const UnsignedQuotientAction = struct { result: ActionIdentity, integer_ty: ir.Type, rhs: RequestHandle, plan: bool, };",
        ),
    );
}
