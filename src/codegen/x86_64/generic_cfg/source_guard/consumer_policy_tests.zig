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
const validateScalarCastProductionSites = support.validateScalarCastProductionSites;
const validateImmediateScalarSemanticPartition = support.validateImmediateScalarSemanticPartition;
const validateImmediateScalarProductionSites = support.validateImmediateScalarProductionSites;
const validateNamedScalarProductionSites = support.validateNamedScalarProductionSites;
const validateScalarMultiplyProductionSites = support.validateScalarMultiplyProductionSites;
const validateUnsignedQuotientProductionSites = support.validateUnsignedQuotientProductionSites;
const validateLoadDiagnosticMappingProductionSites = support.validateLoadDiagnosticMappingProductionSites;
const validateDormantLoadActionProductionSites = support.validateDormantLoadActionProductionSites;
const validateAccumulatorCompositionProductionSites = support.validateAccumulatorCompositionProductionSites;
const validateFailureProvenanceProductionSites = support.validateFailureProvenanceProductionSites;
const validateMemcpyActionProductionSites = support.validateMemcpyActionProductionSites;
const validateSwitchActionProductionSites = support.validateSwitchActionProductionSites;
const validateBranchActionProductionSites = support.validateBranchActionProductionSites;
const validateStoreActionProductionSites = support.validateStoreActionProductionSites;
const validateDormantCallActionProductionSites = support.validateDormantCallActionProductionSites;
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

test "composed selector source guard confines forward resolution to the transaction authority" {
    try std.testing.expectError(
        error.ValueUsePreparedLeafRawOperation,
        validatePreparedViewLeafDiscipline(
            "composed_selector_calls.zig",
            "fn bad() void { _ = selector_state.resolveForwardValueForUse(undefined, \"x\"); }",
        ),
    );
}

test "value-use call action wiring is function scoped and registration precedes attachment" {
    const accepted: [:0]const u8 = @embedFile("../composed_selector_calls.zig");
    try validateDormantCallActionProductionSites("composed_selector_calls.zig", accepted);
    const wired: [:0]const u8 =
        "fn lowerCall() void { " ++
        "if (call.ret_ty.eql(.{ .int = 1 })) return lowerBooleanCall(selector, result, call); " ++
        "return lowerIntByteSizeCall(selector, call); } " ++
        "fn lowerIntByteSizeCall() void { " ++
        "var transaction = ValueUseTransaction.begin(selector); " ++
        "_ = transaction.register(argument); " ++
        "_ = transaction.attachCallAction(.{ .int_byte_size_call = " ++
        "IntByteSizeCallAction.init(symbol, result, argument) }); " ++
        "_ = transaction.seal(); _ = transaction.prepare(); " ++
        "_ = transaction.materializeAll(); _ = transaction.commit(); } " ++
        "fn lowerBooleanCall() void { " ++
        "var transaction = ValueUseTransaction.begin(selector); " ++
        "_ = transaction.register(boolean_argument); " ++
        "_ = transaction.attachCallAction(.{ .direct_call = " ++
        "DirectCallAction.init(symbol, result, arguments, types) }); " ++
        "_ = transaction.seal(); _ = transaction.prepare(); " ++
        "_ = transaction.materializeAll(); _ = transaction.commit(); }";
    try validateDormantCallActionProductionSites("composed_selector_calls.zig", wired);
    try validateDormantCallActionProductionSites(
        "composed_selector_eflags.zig",
        "fn instructionEffect() void { _ = .direct_call; }",
    );
    try std.testing.expectError(
        error.ValueUseCallActionPrematureProductionUse,
        validateDormantCallActionProductionSites("composed_selector_scalar.zig", wired),
    );
    inline for (.{
        .{ "call.ret_ty.eql(.{ .int = 1 })", "call.ret_ty.eql(.{ .int = 8 })" },
        .{ "call.ret_ty.eql(.{ .int = 1 })", "true" },
        .{ "transaction.register(boolean_argument)", "transaction.resolveValue(boolean_argument)" },
        .{ "transaction.register(boolean_argument)", "transaction.register(boolean_argument); _ = selector.valueLoc(argument)" },
        .{ "transaction.register(boolean_argument)", "transaction.register(boolean_argument); _ = selector_state.emitEflagsInstruction(selector, instruction)" },
        .{ "transaction.register(boolean_argument)", "transaction.register(boolean_argument); _ = selector.valueIsLive(argument)" },
        .{ "transaction.register(boolean_argument)", "transaction.register(boolean_argument); _ = transaction.preparedView(argument)" },
        .{ "transaction.register(boolean_argument)", "transaction.register(boolean_argument); _ = selector.machine.instructions" },
        .{ "transaction.register(boolean_argument)", "transaction.register(boolean_argument); _ = transaction.register(extra)" },
        .{ "_ = transaction.register(boolean_argument); ", "" },
        .{ "_ = transaction.register(argument); ", "" },
        .{
            "transaction.register(boolean_argument); _ = transaction.attachCallAction(.{ .direct_call = DirectCallAction.init(symbol, result, arguments, types) })",
            "transaction.attachCallAction(.{ .direct_call = DirectCallAction.init(symbol, result, arguments, types) }); _ = transaction.register(boolean_argument)",
        },
        .{
            "transaction.register(argument); _ = transaction.attachCallAction(.{ .int_byte_size_call = IntByteSizeCallAction.init(symbol, result, argument) })",
            "transaction.attachCallAction(.{ .int_byte_size_call = IntByteSizeCallAction.init(symbol, result, argument) }); _ = transaction.register(argument)",
        },
        .{ "transaction.seal(); _ = transaction.prepare()", "transaction.prepare(); _ = transaction.seal()" },
        .{ "transaction.materializeAll(); _ = transaction.commit()", "transaction.commit(); _ = transaction.materializeAll()" },
        .{ "_ = transaction.materializeAll(); ", "" },
    }) |mutation| {
        const changed = try std.mem.replaceOwned(u8, std.testing.allocator, wired, mutation[0], mutation[1]);
        defer std.testing.allocator.free(changed);
        const fixture = try std.testing.allocator.dupeSentinel(u8, changed, 0);
        defer std.testing.allocator.free(fixture);
        try std.testing.expectError(
            error.ValueUseCallActionPrematureProductionUse,
            validateDormantCallActionProductionSites("composed_selector_calls.zig", fixture),
        );
    }
    inline for (.{
        "fn other() void { _ = transaction.attachCallAction(action); }",
        "fn other() void { _ = DirectCallAction; }",
        "fn other() void { _ = lowerBooleanCall(selector, result, call); }",
        "fn other() void { _ = IntByteSizeCallAction; }",
    }) |extra| {
        try std.testing.expectError(
            error.ValueUseCallActionPrematureProductionUse,
            validateDormantCallActionProductionSites("composed_selector_calls.zig", wired ++ extra),
        );
    }
}

test "composed selector source guard admits only the complete ordinary readonly-pointer and table-i16 load action sets" {
    const table_fixture =
        "fn lowerReadOnlyTableLoad() void { " ++
        "if (ptr.shape == .i16_128 and ptr.offset == 0 and load.ty.eql(.{ .int = 16 })) { " ++
        "return lowerReadOnlyTableI16Transactional(selector, result_name, load); } " ++
        "_ = selector_state.materializeLocIntoLoc(selector, source, destination); " ++
        "if (load.ty != .double) return; _ = selector_state.clobberXmmReg(selector, .xmm0); } " ++
        "fn lowerReadOnlyTableI16Transactional() void { _ = .load_address; " ++
        "_ = .load_readonly_table_i16; _ = ValueUseTransaction.begin(selector); " ++
        "_ = transaction.executePreparedAction(lease); _ = transaction.commit(); }";
    const accepted: [:0]const u8 =
        "fn lowerLoad() void { _ = .load_address; _ = .load_scalar; " ++
        "_ = .load_stack_i128_alias; _ = ValueUseTransaction.begin(selector); " ++
        "_ = transaction.executePreparedAction(lease); _ = transaction.commit(); } " ++
        "fn lowerReadOnlyPointerIntegerLoad() void { _ = .load_address; _ = .load_scalar; " ++
        "_ = .load_readonly_pair; _ = ValueUseTransaction.begin(selector); " ++
        "_ = transaction.executePreparedAction(lease); _ = transaction.commit(); } " ++
        table_fixture;
    try validateDormantLoadActionProductionSites("composed_selector_memory.zig", accepted);
    try std.testing.expectError(
        error.ValueUseLoadActionNotWired,
        validateDormantLoadActionProductionSites(
            "composed_selector_memory.zig",
            accepted ++ " fn relocated() void { _ = .load_scalar; }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseLoadActionNotWired,
        validateDormantLoadActionProductionSites(
            "composed_selector_memory.zig",
            "fn lowerLoad() void { _ = .load_address; _ = .load_scalar; " ++
                "_ = .load_stack_i128_alias; " ++
                "_ = ValueUseTransaction.begin(selector); " ++
                "_ = transaction.executePreparedAction(lease); _ = transaction.commit(); } " ++
                "fn lowerReadOnlyPointerIntegerLoad() void { _ = .load_address; _ = .load_scalar; " ++
                "_ = .load_readonly_pair; _ = ValueUseTransaction.begin(selector); " ++
                "_ = transaction.executePreparedAction(lease); _ = transaction.commit(); " ++
                "_ = .load_readonly_pair; } " ++ table_fixture,
        ),
    );
    const misplaced_direct_materialization: [:0]const u8 =
        "fn lowerLoad() void { _ = .load_address; _ = .load_scalar; " ++
        "_ = .load_stack_i128_alias; _ = ValueUseTransaction.begin(selector); " ++
        "_ = transaction.executePreparedAction(lease); _ = transaction.commit(); } " ++
        "fn lowerReadOnlyPointerIntegerLoad() void { _ = .load_address; _ = .load_scalar; " ++
        "_ = .load_readonly_pair; _ = ValueUseTransaction.begin(selector); " ++
        "_ = transaction.executePreparedAction(lease); _ = transaction.commit(); } " ++
        "fn lowerReadOnlyTableLoad() void { " ++
        "if (ptr.shape == .i16_128 and ptr.offset == 0 and load.ty.eql(.{ .int = 16 })) { " ++
        "_ = selector_state.materializeLocIntoLoc(selector, source, destination); " ++
        "return lowerReadOnlyTableI16Transactional(selector, result_name, load); } " ++
        "if (load.ty != .double) return; _ = selector_state.clobberXmmReg(selector, .xmm0); } " ++
        "fn lowerReadOnlyTableI16Transactional() void { _ = .load_address; " ++
        "_ = .load_readonly_table_i16; _ = ValueUseTransaction.begin(selector); " ++
        "_ = transaction.executePreparedAction(lease); _ = transaction.commit(); }";
    try std.testing.expectError(
        error.ValueUseLoadActionNotWired,
        validateDormantLoadActionProductionSites(
            "composed_selector_memory.zig",
            misplaced_direct_materialization,
        ),
    );
}
test "composed selector source guard permits the sole readonly dispatch resolve only before lowerLoad transaction mutation" {
    const store_fixture =
        "fn lowerStoreScalarTransactional() void { _ = .store_scalar; _ = .store_immediate; } " ++
        "fn lowerStoreI64Transactional() void { _ = .store_i64; } " ++
        "fn lowerStoreStackPointer() void { _ = .store_stack_pointer; } ";
    const readonly_fixture =
        "fn lowerReadOnlyPointerIntegerLoad() void { _ = .load_address; _ = .load_scalar; " ++
        "_ = .load_readonly_pair; _ = ValueUseTransaction.begin(selector); " ++
        "_ = transaction.executePreparedAction(lease); _ = transaction.commit(); } ";
    const table_fixture =
        "fn lowerReadOnlyTableLoad() void { " ++
        "if (ptr.shape == .i16_128 and ptr.offset == 0 and load.ty.eql(.{ .int = 16 })) { " ++
        "return lowerReadOnlyTableI16Transactional(selector, result_name, load); } " ++
        "_ = selector_state.materializeLocIntoLoc(selector, source, destination); " ++
        "if (load.ty != .double) return; _ = selector_state.clobberXmmReg(selector, .xmm0); } " ++
        "fn lowerReadOnlyTableI16Transactional() void { _ = .load_address; " ++
        "_ = .load_readonly_table_i16; _ = ValueUseTransaction.begin(selector); " ++
        "_ = transaction.executePreparedAction(lease); _ = transaction.commit(); } ";
    const before: [:0]const u8 = store_fixture ++
        "fn lowerLoad() void { _ = selector_state.resolveValue(selector, pointer); " ++
        "_ = .load_address; _ = .load_scalar; _ = .load_stack_i128_alias; " ++
        "_ = ValueUseTransaction.begin(selector); _ = transaction.executePreparedAction(lease); " ++
        "_ = transaction.commit(); } " ++ readonly_fixture ++ table_fixture;
    try validatePreparedViewLeafDiscipline("composed_selector_memory.zig", before);
    try std.testing.expectError(
        error.ValueUsePreparedLeafRawOperation,
        validatePreparedViewLeafDiscipline(
            "composed_selector_memory.zig",
            store_fixture ++ "fn lowerLoad() void { _ = .load_address; _ = .load_scalar; " ++
                "_ = .load_stack_i128_alias; _ = ValueUseTransaction.begin(selector); " ++
                "_ = selector_state.resolveValue(selector, pointer); " ++
                "_ = transaction.executePreparedAction(lease); _ = transaction.commit(); } " ++
                readonly_fixture ++ table_fixture,
        ),
    );
}
test "composed selector source guard confines load diagnostic mapping without home queries" {
    const accepted: [:0]const u8 =
        "fn lowerLoad() void { _ = transaction.failedRequestIs(pointer); " ++
        "_ = switch (err) { error.ValueUseLoadOrdinaryStackWidth => diagnostic, " ++
        "error.ValueUseLoadOrdinaryStackArrayWidth => diagnostic, " ++
        "error.ValueUseLoadOrdinaryPointerWidth => diagnostic, " ++
        "error.ValueUseLoadOrdinaryPointerRejected => diagnostic, else => null }; }";
    try validateLoadDiagnosticMappingProductionSites("composed_selector_memory.zig", accepted);
    try validateFailureProvenanceProductionSites("composed_selector_memory.zig", accepted);
    try std.testing.expectError(
        error.ValueUseLoadDiagnosticMappingOutsideAllowlist,
        validateLoadDiagnosticMappingProductionSites(
            "composed_selector_calls.zig",
            "fn lowerCall() void { _ = error.ValueUseLoadOrdinaryPointerWidth; }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseLoadDiagnosticMappingOutsideAllowlist,
        validateLoadDiagnosticMappingProductionSites(
            "composed_selector_memory.zig",
            "fn lowerStore() void { _ = error.ValueUseLoadOrdinaryPointerWidth; }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseLoadConsumerHomeClassification,
        validateLoadDiagnosticMappingProductionSites(
            "composed_selector_memory.zig",
            "fn lowerLoad() void { _ = error.ValueUseLoadOrdinaryPointerWidth; " ++
                "switch (ptr) { .stack_scalar => {}, else => {} } }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseFailureProvenanceOutsideAllowlist,
        validateFailureProvenanceProductionSites(
            "composed_selector_memory.zig",
            "fn lowerStore() void { _ = transaction.failedRequestIs(pointer); " ++
                "_ = error.ValueUseLoadOrdinaryPointerWidth; }",
        ),
    );
}
test "composed selector source guard conditionally confines call provenance mappers" {
    const memcpy: [:0]const u8 =
        "fn inlineMemcpyValueUseDiagnostic() void { " ++
        "_ = transaction.failedRequestIs(destination); " ++
        "_ = transaction.failedRequestIs(source); " ++
        "_ = transaction.failedRequestIs(length); }";
    const direct: [:0]const u8 =
        "fn directCallValueUseDiagnostic() void { " ++
        "for (arguments) |argument| _ = transaction.failedRequestIs(argument); }";
    const int_byte_size: [:0]const u8 =
        "fn lowerIntByteSizeCall() void { " ++
        "_ = transaction.failedRequestIs(argument); }";
    const boolean: [:0]const u8 =
        "fn lowerBooleanCall() void { " ++
        "for (arguments) |argument| _ = transaction.failedRequestIs(argument); }";
    try validateFailureProvenanceProductionSites("composed_selector_calls.zig", memcpy);
    try validateFailureProvenanceProductionSites("composed_selector_calls.zig", direct);
    try validateFailureProvenanceProductionSites("composed_selector_calls.zig", int_byte_size);
    try validateFailureProvenanceProductionSites("composed_selector_calls.zig", memcpy ++ direct);
    try validateFailureProvenanceProductionSites("composed_selector_calls.zig", memcpy ++ direct ++ int_byte_size);
    try validateFailureProvenanceProductionSites("composed_selector_calls.zig", boolean);
    try validateFailureProvenanceProductionSites("composed_selector_calls.zig", memcpy ++ direct ++ int_byte_size ++ boolean);
    try std.testing.expectError(
        error.ValueUseFailureProvenanceAllowlistMismatch,
        validateFailureProvenanceProductionSites(
            "composed_selector_calls.zig",
            boolean ++ " fn successPath() void { _ = transaction.failedRequestIs(source); }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseFailureProvenanceAllowlistMismatch,
        validateFailureProvenanceProductionSites(
            "composed_selector_calls.zig",
            memcpy ++ " fn lowerBooleanCall() void {}",
        ),
    );
    try validateFailureProvenanceProductionSites("composed_selector_calls.zig", "fn lowerInlineMemcpy() void {}");
    try std.testing.expectError(
        error.ValueUseFailureProvenanceOutsideAllowlist,
        validateFailureProvenanceProductionSites(
            "composed_selector_memory.zig",
            "fn lowerStore() void { _ = transaction.failedRequestIs(value); }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseFailureProvenanceOutsideAllowlist,
        validateFailureProvenanceProductionSites(
            "composed_selector_calls.zig",
            "fn lowerInlineMemcpy() void { _ = transaction.failedRequestIs(source); }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseFailureProvenanceAllowlistMismatch,
        validateFailureProvenanceProductionSites(
            "composed_selector_calls.zig",
            "fn inlineMemcpyValueUseDiagnostic() void { " ++
                "_ = transaction.failedRequestIs(destination); " ++
                "_ = transaction.failedRequestIs(source); }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseFailureProvenanceAllowlistMismatch,
        validateFailureProvenanceProductionSites(
            "composed_selector_calls.zig",
            memcpy ++ " fn successPath() void { _ = transaction.failedRequestIs(source); }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseFailureProvenanceAllowlistMismatch,
        validateFailureProvenanceProductionSites(
            "composed_selector_calls.zig",
            direct ++ " fn successPath() void { _ = transaction.failedRequestIs(source); }",
        ),
    );
}
test "composed selector source guard freezes memcpy action to lowerInlineMemcpy" {
    const accepted: [:0]const u8 =
        "fn lowerInlineMemcpy() void { if (dst.ty != .ptr) return; " ++
        "_ = ValueUseTransaction.begin(selector); " ++
        "_ = .{ .form = .memcpy_pointer }; _ = .{ .form = .memcpy_length }; " ++
        "_ = .{ .form = .memcpy_pointer, .inline_memcpy = intent }; }";
    try validateMemcpyActionProductionSites("composed_selector_calls.zig", accepted);
    try std.testing.expectError(
        error.ValueUseMemcpyActionAllowlistMismatch,
        validateMemcpyActionProductionSites(
            "composed_selector_calls.zig",
            accepted ++ " fn relocated() void { _ = .{ .form = .memcpy_pointer }; }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseMemcpyDispatchOrderingMismatch,
        validateMemcpyActionProductionSites(
            "composed_selector_calls.zig",
            "fn lowerInlineMemcpy() void { _ = ValueUseTransaction.begin(selector); " ++
                "if (dst.ty != .ptr) return; _ = .{ .form = .memcpy_pointer }; " ++
                "_ = .{ .form = .memcpy_length }; _ = .{ .form = .memcpy_pointer, .inline_memcpy = intent }; }",
        ),
    );
}
test "composed selector source guard freezes production store actions by function" {
    const accepted: [:0]const u8 =
        "fn lowerStoreScalarTransactional() void { _ = .store_scalar; _ = .store_immediate; } " ++
        "fn lowerStoreI64Transactional() void { _ = .store_i64; } " ++
        "fn lowerStoreStackPointer() void { _ = .store_stack_pointer; }";
    try validateStoreActionProductionSites("composed_selector_memory.zig", accepted);
    try std.testing.expectError(
        error.ValueUseStoreActionAllowlistMismatch,
        validateStoreActionProductionSites(
            "composed_selector_memory.zig",
            "fn lowerStoreScalarTransactional() void { _ = .store_scalar; _ = .store_immediate; _ = .store_i64; } " ++
                "fn lowerStoreI64Transactional() void {} " ++
                "fn lowerStoreStackPointer() void { _ = .store_stack_pointer; }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseStoreActionAllowlistMismatch,
        validateStoreActionProductionSites("composed_selector_memory.zig", accepted ++ " fn extra() void { _ = .store_scalar; }"),
    );
}
test "composed selector source guard freezes branch and ordinary switch actions" {
    try std.testing.expectError(
        error.ValueUseBranchActionOutsideAllowlist,
        validatePreparedViewLeafDiscipline(
            "composed_selector_fixture.zig",
            "fn lower() void { _ = .branch_condition; }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseSwitchActionOutsideAllowlist,
        validatePreparedViewLeafDiscipline(
            "composed_selector_fixture.zig",
            "fn lower() void { _ = .{ .form = .switch_condition, .switch_compare_chain = switch_action }; }",
        ),
    );

    const accepted: [:0]const u8 =
        "fn emitBranchCondition() void { _ = .{ .form = .branch_condition, .prepared_action = .branch_condition }; }";
    try validateBranchActionProductionSites("composed_selector_cfg.zig", accepted);
    try std.testing.expectError(
        error.ValueUseBranchActionAllowlistMismatch,
        validateBranchActionProductionSites(
            "composed_selector_cfg.zig",
            accepted ++ " fn relocated() void { _ = .branch_condition; }",
        ),
    );

    const accepted_switch: [:0]const u8 =
        "fn lowerSwitch() void { if (has_phi_edge) return; " ++
        "const exhaustive_case = maskedSwitchExhaustiveCaseIndex(); " ++
        "_ = .{ .form = .switch_condition, .switch_compare_chain = switch_action }; " ++
        "_ = ValueUseTransaction.begin(selector); }";
    try validateSwitchActionProductionSites("composed_selector_cfg.zig", accepted_switch);
    try std.testing.expectError(
        error.ValueUseSwitchActionDispatchOrderingMismatch,
        validateSwitchActionProductionSites(
            "composed_selector_cfg.zig",
            "fn lowerSwitch() void { _ = .{ .form = .switch_condition, .switch_compare_chain = switch_action }; " ++
                "_ = ValueUseTransaction.begin(selector); if (has_phi_edge) return; " ++
                "const exhaustive_case = maskedSwitchExhaustiveCaseIndex(); }",
        ),
    );
}
test "composed selector source guard admits only reviewed accumulator composition consumers" {
    try validateAccumulatorCompositionProductionSites(
        "composed_selector_memory.zig",
        "fn lowerLoad() void { " ++
            "_ = ValueUseTransaction.begin(selector); " ++
            "_ = transaction.beginAccumulatorSession(); " ++
            "_ = transaction.defineAccumulatorResult(accumulator, \"result\", definition); " ++
            "_ = transaction.finalizeAccumulatorResult(accumulator); " ++
            "_ = transaction.commit(); } " ++
            "fn lowerReadOnlyPointerIntegerLoad() void { " ++
            "_ = ValueUseTransaction.begin(selector); " ++
            "_ = transaction.beginAccumulatorSession(); " ++
            "_ = transaction.defineAccumulatorResult(accumulator, \"result\", definition); " ++
            "_ = transaction.finalizeAccumulatorResult(accumulator); " ++
            "_ = transaction.commit(); }",
    );
    try validateAccumulatorCompositionProductionSites(
        "composed_selector_calls.zig",
        "fn lowerAbsI32() void { " ++
            "_ = ValueUseTransaction.begin(selector); " ++
            "_ = transaction.beginAccumulatorSession(); " ++
            "_ = transaction.prepareAccumulator(accumulator, .clobber, .spill_live); " ++
            "_ = transaction.defineAccumulatorResult(accumulator, \"result\", definition); " ++
            "_ = transaction.finalizeAccumulatorResult(accumulator); " ++
            "_ = transaction.commit(); }",
    );
    const rejected = [_][:0]const u8{
        "fn lowerUnary() void { _ = transaction.beginAccumulatorSession(); }",
        "fn lowerAbsI32() void { _ = transaction.beginAccumulatorSession(); }",
        "fn lowerAbsI32() void { _ = ValueUseTransaction.begin(selector); " ++
            "_ = transaction.beginAccumulatorSession(); " ++
            "_ = transaction.prepareAccumulator(accumulator, .clobber, .spill_live); " ++
            "_ = transaction.defineAccumulatorResult(accumulator, \"result\", definition); " ++
            "_ = transaction.finalizeAccumulatorResult(accumulator); " ++
            "_ = transaction.commitAccumulatorSession(accumulator); }",
        "fn lowerAbsI32() void { _ = ValueUseTransaction.begin(selector); " ++
            "_ = transaction.beginAccumulatorSession(); " ++
            "_ = transaction.prepareAccumulator(accumulator, .clobber, .spill_live); " ++
            "_ = transaction.defineAccumulatorResult(accumulator, \"result\", definition); " ++
            "_ = transaction.finalizeAccumulatorResult(accumulator); " ++
            "_ = AccumulatorDefinitionTransaction.begin(selector); " ++
            "_ = transaction.commit(); }",
    };
    for (rejected) |fixture| {
        try std.testing.expectError(
            if (std.mem.indexOf(u8, fixture, "lowerUnary") != null)
                error.ValueUseAccumulatorCompositionOutsideAllowlist
            else
                error.ValueUseAccumulatorCompositionAllowlistMismatch,
            validateAccumulatorCompositionProductionSites("composed_selector_calls.zig", fixture),
        );
    }
    try std.testing.expectError(
        error.ValueUseAccumulatorCompositionAllowlistMismatch,
        validateAccumulatorCompositionProductionSites(
            "composed_selector_scalar.zig",
            "fn lowerAbsI32() void { _ = transaction.beginAccumulatorSession(); }",
        ),
    );
}

test "composed selector source guard confines active scalar cast actions" {
    const outside = [_][:0]const u8{
        "fn lowerCast() void { _ = .{ .form = .pair_low_scalar_cast_operand }; }",
        "fn lowerCast() void { _ = .{ .prepared_action = .{ .accumulator_scalar_cast = action } }; }",
        "fn lowerCast() void { _ = isSignExtendScratchCast(cast); }",
    };
    for (outside) |fixture| {
        try std.testing.expectError(
            error.ValueUseScalarCastActionOutsideAllowlist,
            validateScalarCastProductionSites("composed_selector_calls.zig", fixture),
        );
    }
    try std.testing.expectError(
        error.ValueUseScalarCastActionAllowlistMismatch,
        validateScalarCastProductionSites(
            "composed_selector_scalar.zig",
            "fn lowerCast() void { _ = .{ .form = .pair_low_scalar_cast_operand }; }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseScalarCastActionAllowlistMismatch,
        validateScalarCastProductionSites(
            "composed_selector_scalar.zig",
            "fn lowerCast() void { _ = AccumulatorDefinitionTransaction.begin(selector); }",
        ),
    );
}

test "composed selector source guard confines narrowed immediate scalar actions" {
    const fixtures = [_][:0]const u8{
        "fn lowerBinaryImmediateRhs() void { _ = .{ .form = .immediate_rhs_scalar_operand }; }",
        "fn lowerBinaryImmediateLhs() void { _ = .{ .prepared_action = .{ .immediate_lhs_scalar = action } }; }",
        "fn lowerBinary() void { _ = isImmediateRhsScalar(binary); }",
        "fn lowerBinary() void { _ = isImmediateLhsScalar(binary); }",
        "fn lowerBinaryImmediateRhs() void { _ = isScalarImmediateLiveSharedSourcePreservation(binary); }",
        "fn scalar_immediate_live_shared_source_preservation() void {}",
        "fn lowerBinaryImmediateRhs() void { _ = isScalarImmediateMultiAliasPreservation(binary); }",
        "fn scalar_immediate_multi_alias_preservation() void {}",
    };
    for (fixtures) |fixture| {
        try std.testing.expectError(
            error.ValueUseImmediateScalarActionOutsideAllowlist,
            validateImmediateScalarProductionSites(
                "composed_selector_calls.zig",
                fixture,
            ),
        );
    }
    try std.testing.expectError(
        error.ValueUseImmediateScalarActionAllowlistMismatch,
        validateImmediateScalarProductionSites(
            "composed_selector_scalar.zig",
            "fn lowerBinary() void { _ = .{ .form = .immediate_rhs_scalar_operand }; }",
        ),
    );
}

const immediate_partition_fixture: [:0]const u8 =
    \\fn isScalarImmediateLiveSharedSourcePreservation(binary: anytype) bool {
    \\    if (binary.lhs != .named or binary.rhs != .int) return false;
    \\    const bits = intBits(binary.ty) orelse return false;
    \\    if (bits == 0) return false;
    \\    return binary.op == .ashr and (bits <= 32 or bits == 64);
    \\}
    \\fn scalar_immediate_live_shared_source_preservation() void {
    \\    while (liveAccumulatorNameAfterCurrent()) |_| { preserveLiveAccumulatorValue(); }
    \\    AccumulatorDefinitionTransaction.begin(selector);
    \\    accumulatorArithmeticDisplacement(.spill_live);
    \\    emitValueIntoScratch();
    \\    bindScratch();
    \\    spillValue();
    \\    _ = .sar_eax_imm5;
    \\    _ = .sar_arg64_imm6;
    \\}
    \\fn isScalarImmediateMultiAliasPreservation(binary: anytype) bool {
    \\    if (binary.lhs != .named or binary.rhs != .int) return false;
    \\    const bits = intBits(binary.ty) orelse return false;
    \\    if (bits == 0 or bits > 32) return false;
    \\    return switch (binary.op) { .@"and", .@"or", .add, .sub, .xor => true, else => false };
    \\}
    \\fn scalar_immediate_multi_alias_preservation() void {
    \\    while (liveAccumulatorNameAfterCurrent()) |_| { preserveLiveAccumulatorValue(); }
    \\    switch (binary.op) {
    \\        .@"and" => { AccumulatorDefinitionTransaction.begin(selector); accumulatorArithmeticDisplacement(.scratch_preferred); },
    \\        .@"or" => { AccumulatorDefinitionTransaction.begin(selector); accumulatorArithmeticDisplacement(.scratch_preferred); },
    \\        .add => { AccumulatorDefinitionTransaction.begin(selector); accumulatorArithmeticDisplacement(.scratch_preferred); },
    \\        .sub => { AccumulatorDefinitionTransaction.begin(selector); accumulatorArithmeticDisplacement(.scratch_preferred); },
    \\        .xor => { AccumulatorDefinitionTransaction.begin(selector); accumulatorArithmeticDisplacement(.scratch_preferred); },
    \\    }
    \\}
    \\fn lowerBinaryImmediateRhs() void {
    \\    if (isScalarImmediateLiveSharedSourcePreservation(binary))
    \\        return scalar_immediate_live_shared_source_preservation(selector, result_name, binary, bits, literal);
    \\    if (isScalarImmediateMultiAliasPreservation(binary))
    \\        return scalar_immediate_multi_alias_preservation(selector, result_name, binary, bits, literal);
    \\    if (ValueUseTransaction.isImmediateRhsScalar(binary)) return lowerImmediateRhsScalar();
    \\    return switch (binary.op) {
    \\        .lshr => if (bits == 128) { selector_state.emitPairLshrImmediate(); },
    \\        .shl => if (bits == 128) { selector_state.emitPairShlImmediate(); },
    \\        .ashr => if (bits == 128) { selector_state.emitPairSignMask(); },
    \\    };
    \\}
    \\fn lowerBinaryImmediateLhs() void {
    \\    if (binary.op == .sub and bits == 128 and literal == 0) {
    \\        selector_state.materializePairValue();
    \\        selector_state.bindPairScratch();
    \\    }
    \\    if (ValueUseTransaction.isImmediateLhsScalar(binary)) return lowerImmediateLhsScalar();
    \\}
;

test "composed selector source guard freezes immediate semantic partition anchors" {
    try validateImmediateScalarSemanticPartition(immediate_partition_fixture);

    const r03_after_action = std.mem.replaceOwned(
        u8,
        std.testing.allocator,
        immediate_partition_fixture,
        "if (isScalarImmediateLiveSharedSourcePreservation(binary))",
        "if (ValueUseTransaction.isImmediateRhsScalar(binary))",
    ) catch unreachable;
    defer std.testing.allocator.free(r03_after_action);
    const r03_after_action_z = try std.testing.allocator.dupeSentinel(u8, r03_after_action, 0);
    defer std.testing.allocator.free(r03_after_action_z);
    try std.testing.expectError(
        error.ValueUseImmediateScalarDispatchOrderMismatch,
        validateImmediateScalarSemanticPartition(r03_after_action_z),
    );

    const r03_transactional = std.mem.replaceOwned(
        u8,
        std.testing.allocator,
        immediate_partition_fixture,
        "while (liveAccumulatorNameAfterCurrent())",
        "ValueUseTransaction.begin(selector); while (liveAccumulatorNameAfterCurrent())",
    ) catch unreachable;
    defer std.testing.allocator.free(r03_transactional);
    const r03_transactional_z = try std.testing.allocator.dupeSentinel(u8, r03_transactional, 0);
    defer std.testing.allocator.free(r03_transactional_z);
    try std.testing.expectError(
        error.ValueUseImmediateScalarResidualOwnershipMismatch,
        validateImmediateScalarSemanticPartition(r03_transactional_z),
    );

    const r04_after_action = std.mem.replaceOwned(
        u8,
        std.testing.allocator,
        immediate_partition_fixture,
        "if (isScalarImmediateMultiAliasPreservation(binary))",
        "if (ValueUseTransaction.isImmediateRhsScalar(binary))",
    ) catch unreachable;
    defer std.testing.allocator.free(r04_after_action);
    const r04_after_action_z = try std.testing.allocator.dupeSentinel(u8, r04_after_action, 0);
    defer std.testing.allocator.free(r04_after_action_z);
    try std.testing.expectError(
        error.ValueUseImmediateScalarDispatchOrderMismatch,
        validateImmediateScalarSemanticPartition(r04_after_action_z),
    );

    const second_preamble = std.mem.lastIndexOf(
        u8,
        immediate_partition_fixture,
        "while (liveAccumulatorNameAfterCurrent())",
    ) orelse unreachable;
    const r04_transactional = try std.mem.concat(std.testing.allocator, u8, &.{
        immediate_partition_fixture[0..second_preamble],
        "ValueUseTransaction.begin(selector); ",
        immediate_partition_fixture[second_preamble..],
    });
    defer std.testing.allocator.free(r04_transactional);
    const r04_transactional_z = try std.testing.allocator.dupeSentinel(u8, r04_transactional, 0);
    defer std.testing.allocator.free(r04_transactional_z);
    try std.testing.expectError(
        error.ValueUseImmediateScalarResidualOwnershipMismatch,
        validateImmediateScalarSemanticPartition(r04_transactional_z),
    );

    const r00_legacy = std.mem.replaceOwned(
        u8,
        std.testing.allocator,
        immediate_partition_fixture,
        "return switch (binary.op)",
        "mov_eax_to_arg; return switch (binary.op)",
    ) catch unreachable;
    defer std.testing.allocator.free(r00_legacy);
    const r00_legacy_z = try std.testing.allocator.dupeSentinel(u8, r00_legacy, 0);
    defer std.testing.allocator.free(r00_legacy_z);
    try std.testing.expectError(
        error.ValueUseImmediateScalarResidualOwnershipMismatch,
        validateImmediateScalarSemanticPartition(r00_legacy_z),
    );

    const r05_legacy = std.mem.replaceOwned(
        u8,
        std.testing.allocator,
        immediate_partition_fixture,
        "return switch (binary.op)",
        "accumulatorPreserveCurrentDisplacement(); return switch (binary.op)",
    ) catch unreachable;
    defer std.testing.allocator.free(r05_legacy);
    const r05_legacy_z = try std.testing.allocator.dupeSentinel(u8, r05_legacy, 0);
    defer std.testing.allocator.free(r05_legacy_z);
    try std.testing.expectError(
        error.ValueUseImmediateScalarResidualOwnershipMismatch,
        validateImmediateScalarSemanticPartition(r05_legacy_z),
    );

    const stateful_classifier = std.mem.replaceOwned(
        u8,
        std.testing.allocator,
        immediate_partition_fixture,
        "const bits = intBits(binary.ty)",
        "_ = selector; const bits = intBits(binary.ty)",
    ) catch unreachable;
    defer std.testing.allocator.free(stateful_classifier);
    const stateful_classifier_z = try std.testing.allocator.dupeSentinel(u8, stateful_classifier, 0);
    defer std.testing.allocator.free(stateful_classifier_z);
    try std.testing.expectError(
        error.ValueUseImmediateScalarResidualClassifierStateful,
        validateImmediateScalarSemanticPartition(stateful_classifier_z),
    );
}

test "composed selector source guard rejects unclassified immediate scalar production" {
    try std.testing.expectError(
        error.ValueUseImmediateScalarActionOutsideAllowlist,
        validateImmediateScalarProductionSites(
            "composed_selector_calls.zig",
            "fn lowerBinaryImmediateRhs() void { _ = .{ .form = .immediate_rhs_scalar_operand }; }",
        ),
    );
    try std.testing.expectError(
        error.ValueUseImmediateScalarActionAllowlistMismatch,
        validateImmediateScalarProductionSites(
            "composed_selector_scalar.zig",
            "fn lowerBinaryImmediateRhs() void { _ = isImmediateRhsScalar(binary); }",
        ),
    );
}

test "value-use named scalar production wiring freezes accepted and retained families" {
    const accepted: [:0]const u8 = @embedFile("../composed_selector_scalar.zig");
    try validateNamedScalarProductionSites("composed_selector_scalar.zig", accepted);

    try std.testing.expectError(
        error.ValueUseNamedScalarActionOutsideAllowlist,
        validateNamedScalarProductionSites(
            "composed_selector_calls.zig",
            "fn lower() void { _ = ValueUseTransaction.isNamedScalarBinary(binary, false); }",
        ),
    );

    const reintroduced_interval_owner = try std.fmt.allocPrint(
        std.testing.allocator,
        "{s}\nfn scalar_named_b03_interval_admission() void {{}}\n",
        .{accepted},
    );
    defer std.testing.allocator.free(reintroduced_interval_owner);
    const reintroduced_interval_owner_z = try std.testing.allocator.dupeSentinel(u8, reintroduced_interval_owner, 0);
    defer std.testing.allocator.free(reintroduced_interval_owner_z);
    try std.testing.expectError(
        error.ValueUseNamedScalarMigratedResidualReintroduced,
        validateNamedScalarProductionSites(
            "composed_selector_scalar.zig",
            reintroduced_interval_owner_z,
        ),
    );

    const wrong_b03_dispatch = try std.mem.replaceOwned(
        u8,
        std.testing.allocator,
        accepted,
        "binary, bits, exact_ei_narrow, .b03",
        "binary, bits, exact_ei_narrow, .b07",
    );
    defer std.testing.allocator.free(wrong_b03_dispatch);
    const wrong_b03_dispatch_z = try std.testing.allocator.dupeSentinel(u8, wrong_b03_dispatch, 0);
    defer std.testing.allocator.free(wrong_b03_dispatch_z);
    try std.testing.expectError(
        error.ValueUseNamedScalarDispatchMismatch,
        validateNamedScalarProductionSites(
            "composed_selector_scalar.zig",
            wrong_b03_dispatch_z,
        ),
    );

    const attempted_fallback = try std.mem.replaceOwned(
        u8,
        std.testing.allocator,
        accepted,
        "try transaction.commit();\n    return null;\n}\n\nfn namedScalarValueUseDiagnostic",
        "try transaction.commit();\n    return scalar_named_b07_rhs_admission();\n}\n\nfn namedScalarValueUseDiagnostic",
    );
    defer std.testing.allocator.free(attempted_fallback);
    const attempted_fallback_z = try std.testing.allocator.dupeSentinel(u8, attempted_fallback, 0);
    defer std.testing.allocator.free(attempted_fallback_z);
    try std.testing.expectError(
        error.ValueUseNamedScalarAttemptThenFallback,
        validateNamedScalarProductionSites(
            "composed_selector_scalar.zig",
            attempted_fallback_z,
        ),
    );

    const missing_b07_dispatch = try std.mem.replaceOwned(
        u8,
        std.testing.allocator,
        accepted,
        "binary, bits, exact_ei_narrow, .b07",
        "binary, bits, exact_ei_narrow, .b06",
    );
    defer std.testing.allocator.free(missing_b07_dispatch);
    const missing_b07_dispatch_z = try std.testing.allocator.dupeSentinel(u8, missing_b07_dispatch, 0);
    defer std.testing.allocator.free(missing_b07_dispatch_z);
    try std.testing.expectError(
        error.ValueUseNamedScalarDispatchMismatch,
        validateNamedScalarProductionSites(
            "composed_selector_scalar.zig",
            missing_b07_dispatch_z,
        ),
    );

    const reintroduced_b07_owner = try std.fmt.allocPrint(
        std.testing.allocator,
        "{s}\nfn scalar_named_b07_rhs_admission() void {{}}\n",
        .{accepted},
    );
    defer std.testing.allocator.free(reintroduced_b07_owner);
    const reintroduced_b07_owner_z = try std.testing.allocator.dupeSentinel(u8, reintroduced_b07_owner, 0);
    defer std.testing.allocator.free(reintroduced_b07_owner_z);
    try std.testing.expectError(
        error.ValueUseNamedScalarMigratedResidualReintroduced,
        validateNamedScalarProductionSites(
            "composed_selector_scalar.zig",
            reintroduced_b07_owner_z,
        ),
    );
}

test "scalar multiply production wiring is complete and exclusive" {
    const accepted: [:0]const u8 = @embedFile("../composed_selector_scalar.zig");
    try validateScalarMultiplyProductionSites("composed_selector_scalar.zig", accepted);

    try std.testing.expectError(
        error.ValueUseScalarMultiplyPrematureProductionUse,
        validateScalarMultiplyProductionSites(
            "composed_selector_calls.zig",
            "fn lowerMul64() void { _ = isScalarMultiply(binary); }",
        ),
    );

    const missing_action = try std.mem.replaceOwned(
        u8,
        std.testing.allocator,
        accepted,
        "transaction.attachScalarMultiplyAction(",
        "transaction.attachNamedScalarBinaryAction(",
    );
    defer std.testing.allocator.free(missing_action);
    const missing_action_z = try std.testing.allocator.dupeSentinel(u8, missing_action, 0);
    defer std.testing.allocator.free(missing_action_z);
    try std.testing.expectError(
        error.ValueUseScalarMultiplyPrematureProductionUse,
        validateScalarMultiplyProductionSites(
            "composed_selector_scalar.zig",
            missing_action_z,
        ),
    );

    const reintroduced_fallback = try std.fmt.allocPrint(
        std.testing.allocator,
        "{s}\npub fn lowerMul64SpillLhsThroughRax() void {{}}\n",
        .{accepted},
    );
    defer std.testing.allocator.free(reintroduced_fallback);
    const reintroduced_fallback_z = try std.testing.allocator.dupeSentinel(u8, reintroduced_fallback, 0);
    defer std.testing.allocator.free(reintroduced_fallback_z);
    try std.testing.expectError(
        error.ValueUseScalarMultiplyPrematureProductionUse,
        validateScalarMultiplyProductionSites(
            "composed_selector_scalar.zig",
            reintroduced_fallback_z,
        ),
    );

    const raw_resolution = try std.mem.replaceOwned(
        u8,
        std.testing.allocator,
        accepted,
        "var transaction = try ValueUseTransaction.begin(selector);",
        "_ = selector_state.resolveValue(selector, binary.lhs);\n    var transaction = try ValueUseTransaction.begin(selector);",
    );
    defer std.testing.allocator.free(raw_resolution);
    const raw_resolution_z = try std.testing.allocator.dupeSentinel(u8, raw_resolution, 0);
    defer std.testing.allocator.free(raw_resolution_z);
    try std.testing.expectError(
        error.ValueUseScalarMultiplyPrematureProductionUse,
        validateScalarMultiplyProductionSites(
            "composed_selector_scalar.zig",
            raw_resolution_z,
        ),
    );
}

test "unsigned quotient production wiring is complete and exclusive" {
    const accepted: [:0]const u8 = @embedFile("../composed_selector_scalar.zig");
    try validateUnsignedQuotientProductionSites("composed_selector_scalar.zig", accepted);

    inline for ([_][:0]const u8{
        "fn lowerUnsignedDivRem() void { _ = isUnsignedQuotient(binary); }",
        "fn lowerUnsignedDivRem() void { transaction.attachUnsignedQuotientAction(lhs, action); }",
        "fn lowerUnsignedDivRem() void { _ = .unsigned_quotient; }",
        "fn lowerUnsignedDivRem() void { executeUnsignedQuotient(); }",
    }) |source| {
        try std.testing.expectError(
            error.ValueUseUnsignedQuotientPrematureProductionUse,
            validateUnsignedQuotientProductionSites(
                "composed_selector_scalar.zig",
                source,
            ),
        );
    }

    try std.testing.expectError(
        error.ValueUseUnsignedQuotientPrematureProductionUse,
        validateUnsignedQuotientProductionSites(
            "composed_selector_calls.zig",
            "fn lowerCall() void { _ = isUnsignedQuotient(binary); }",
        ),
    );

    const raw_resolution = try std.mem.replaceOwned(
        u8,
        std.testing.allocator,
        accepted,
        "var transaction = try ValueUseTransaction.begin(selector);",
        "_ = selector_state.resolveValue(selector, binary.rhs);\n    var transaction = try ValueUseTransaction.begin(selector);",
    );
    defer std.testing.allocator.free(raw_resolution);
    const raw_resolution_z = try std.testing.allocator.dupeSentinel(u8, raw_resolution, 0);
    defer std.testing.allocator.free(raw_resolution_z);
    try std.testing.expectError(
        error.ValueUseUnsignedQuotientPrematureProductionUse,
        validateUnsignedQuotientProductionSites(
            "composed_selector_scalar.zig",
            raw_resolution_z,
        ),
    );

    const reordered_remainder = try std.mem.replaceOwned(
        u8,
        std.testing.allocator,
        accepted,
        "if (binary.op == .urem) return lowerUnsignedRem(selector, result_name, binary, bits);",
        "if (false) return lowerUnsignedRem(selector, result_name, binary, bits);",
    );
    defer std.testing.allocator.free(reordered_remainder);
    const reordered_remainder_z = try std.testing.allocator.dupeSentinel(u8, reordered_remainder, 0);
    defer std.testing.allocator.free(reordered_remainder_z);
    try std.testing.expectError(
        error.ValueUseUnsignedQuotientPrematureProductionUse,
        validateUnsignedQuotientProductionSites(
            "composed_selector_scalar.zig",
            reordered_remainder_z,
        ),
    );
}

test "composed selector source guard confines scalar atomics accumulator composition" {
    const source = @embedFile("../composed_selector_atomic.zig");
    try validateAccumulatorCompositionProductionSites("composed_selector_atomic.zig", source);
    for ([_][2][]const u8{
        .{ "fn lowerRmw(", "fn unreviewedAtomic(" },
        .{ "transaction.seal()", "transaction.skipSeal()" },
        .{ "transaction.prepare()", "transaction.skipPrepare()" },
        .{ "transaction.materializeAll()", "transaction.skipMaterialization()" },
        .{ "transaction.commit()", "transaction.commitAccumulatorSession(accumulator)" },
        .{ "normalization.commit()", "normalization.skipCommit()" },
    }) |mutation| {
        const changed = try std.mem.replaceOwned(u8, std.testing.allocator, source, mutation[0], mutation[1]);
        defer std.testing.allocator.free(changed);
        const terminated = try std.testing.allocator.dupeSentinel(u8, changed, 0);
        defer std.testing.allocator.free(terminated);
        try std.testing.expectError(error.ValueUseAccumulatorCompositionAllowlistMismatch, validateAccumulatorCompositionProductionSites("composed_selector_atomic.zig", terminated));
    }
}
