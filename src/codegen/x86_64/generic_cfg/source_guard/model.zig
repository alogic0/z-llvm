const std = @import("std");

pub const source_dir = "src/codegen/x86_64/generic_cfg";
pub const source_prefix = "composed_selector_";
pub const source_suffix = ".zig";

pub const SourceKind = enum {
    authority,
    address_dependency_domain,
    value_use_authority,
    lifecycle,
    consumer,
};

pub const ClassifiedSource = struct {
    name: []const u8,
    kind: SourceKind,
};

// Every production composed-selector source must appear here. Test sources are
// white-box fixtures and are deliberately classified by their `_tests.zig`
// suffix instead.
pub const classified_sources = [_]ClassifiedSource{
    .{ .name = "composed_selector_address_dependencies.zig", .kind = .address_dependency_domain },
    .{ .name = "composed_selector_aggregate.zig", .kind = .consumer },
    .{ .name = "composed_selector_calls.zig", .kind = .consumer },
    .{ .name = "composed_selector_cfg.zig", .kind = .consumer },
    .{ .name = "composed_selector_conversion.zig", .kind = .consumer },
    .{ .name = "composed_selector_eflags.zig", .kind = .consumer },
    .{ .name = "composed_selector_fp.zig", .kind = .consumer },
    .{ .name = "composed_selector_frame.zig", .kind = .consumer },
    .{ .name = "composed_selector_icmp.zig", .kind = .consumer },
    .{ .name = "composed_selector_impl.zig", .kind = .consumer },
    .{ .name = "composed_selector_memory.zig", .kind = .consumer },
    .{ .name = "composed_selector_scalar.zig", .kind = .consumer },
    .{ .name = "composed_selector_state.zig", .kind = .authority },
    .{ .name = "composed_selector_state_data.zig", .kind = .lifecycle },
    .{ .name = "composed_selector_value_use_transaction.zig", .kind = .value_use_authority },
    .{ .name = "composed_selector_vector.zig", .kind = .consumer },
};

pub const value_use_leaf_paths = [_][]const u8{
    "src/codegen/x86_64/generic_cfg/value_use/model.zig",
    "src/codegen/x86_64/generic_cfg/value_use/core.zig",
    "src/codegen/x86_64/generic_cfg/value_use/planning.zig",
    "src/codegen/x86_64/generic_cfg/value_use/planning/model.zig",
    "src/codegen/x86_64/generic_cfg/value_use/planning/compatibility.zig",
    "src/codegen/x86_64/generic_cfg/value_use/planning/lifetime_admission.zig",
    "src/codegen/x86_64/generic_cfg/value_use/planning/semantic_ordering.zig",
    "src/codegen/x86_64/generic_cfg/value_use/planning/physical_mapping.zig",
    "src/codegen/x86_64/generic_cfg/value_use/materialization.zig",
    "src/codegen/x86_64/generic_cfg/value_use/composition.zig",
    "src/codegen/x86_64/generic_cfg/value_use/actions/address_memory.zig",
    "src/codegen/x86_64/generic_cfg/value_use/actions/control_compare.zig",
    "src/codegen/x86_64/generic_cfg/value_use/actions/scalar_arithmetic.zig",
    "src/codegen/x86_64/generic_cfg/value_use/actions/scalar_cast.zig",
    "src/codegen/x86_64/generic_cfg/value_use/actions/scalar_immediate.zig",
    "src/codegen/x86_64/generic_cfg/value_use/actions/scalar_multiply_divide.zig",
    "src/codegen/x86_64/generic_cfg/value_use/actions/scalar_named.zig",
    "src/codegen/x86_64/generic_cfg/value_use/actions/calls.zig",
};

pub const value_use_model_pub_names = [_][]const u8{
    "AccumulatorScalarCastAction",       "AccumulatorSessionHandle",       "ActionIdentity",
    "AddressOffset",                     "ByteAddressAction",              "CallRequestError",
    "CopyDestination",                   "DirectCallAction",               "IntByteSizeCallAction",
    "CurrentHomeEqZeroAction",           "CurrentHomeEqZeroRequestError",  "CurrentHomeEqZeroTestFailure",
    "CurrentHomeSignBitAction",          "CurrentHomeSignBitRequestError", "CurrentHomeSignBitTestFailure",
    "Destination",                       "EarlyPlan",                      "EarlyPreparedHome",
    "Expected",                          "ForwardAdmissionSnapshot",       "ForwardAssignmentSnapshot",
    "ForwardDependencyBindingSnapshot",  "ForwardDependencyEdgeSnapshot",  "ForwardDependencyOwnerSnapshot",
    "ForwardDependencySnapshot",         "I128EqMinAction",                "I128EqMinTestFailure",
    "I128PairRequestError",              "I128SignBitAction",              "I128SignBitTestFailure",
    "Identity",                          "ImmediateLhsScalarAction",       "ImmediateRhsScalarAction",
    "ImmediateScalarRequestError",       "ImmediateScalarTestFailure",     "Lifecycle",
    "ExactI52BinaryAction",              "LoadRequestError",               "LoadTestFailure",
    "MemsetAction",                      "MemcpyAction",                   "MemcpyTestFailure",
    "NamedScalarBinaryAction",           "NamedScalarRequestError",        "NamedScalarTestFailure",
    "OperandPhase",                      "OrderedOperand",                 "PhysicalNode",
    "PreparedAction",                    "PairLowScalarCastAction",        "PreparedAddressComponent",
    "PreparedAddressDescriptor",         "PreparedCondition",              "PreparedIdentity",
    "PreparedPairLimb",                  "PreparedReadOnlyPair",           "PreparedRecord",
    "PreparedRegister",                  "PreparedScalarHome",             "PreparedShape",
    "PreparedStackF32PairAddress",       "PreparedStackObject",            "PreparedTablePointer",
    "PreparedView",                      "PreparedViewLease",              "ReadOnlyPairLoadAction",
    "ReadOnlyTableAddressAction",        "ReadOnlyTableI16LoadAction",     "Request",
    "RequestHandle",                     "RequestPhase",                   "ScalarCastRequestError",
    "ScalarCastTestFailure",             "ScalarLoadAction",               "ScalarLoadKind",
    "ScalarMultiplyAction",              "ScalarMultiplyRequestError",     "ScalarMultiplyTestFailure",
    "ScaledAddressAction",               "ScratchCompareAction",           "ScratchCompareRhs",
    "ScratchCompareTestFailure",         "SemanticRole",                   "SetccEaxCompareAction",
    "SetccEaxCompareRequestError",       "SetccEaxCompareStructure",       "SetccEaxCompareTestFailure",
    "SignExtendScratchAction",           "Source",                         "StackI128AliasLoadAction",
    "StoreI64Action",                    "StoreImmediateAction",           "StoreScalarAction",
    "StoreStackPointerAction",           "StoredRequest",                  "SwitchCaseIntent",
    "SwitchCompareChainAction",          "Transaction",                    "UnsignedQuotientAction",
    "UnsignedQuotientRequestError",      "UnsignedQuotientTestFailure",    "UseForm",
    "address_domain_copies_per_request", "address_domain_snapshot_bytes",  "address_domain_snapshot_copies",
    "max_identity_bytes",                "max_forward_dependency_owners",  "max_mappings",
    "max_requests",                      "max_switch_cases",               "physical_node_count",
};
pub const value_use_core_pub_names = [_][]const u8{"ValueUseTransaction"};
pub const value_use_planning_pub_names = [_][]const u8{
    "actionOwnsOrderedWrites",      "argRegForNode",             "availabilityForConsumption",
    "mustSurviveInstruction",       "nodeForArgReg",             "occupantNeedsPreservation",
    "pairSourceNodes",              "planEarlyMaterializations", "requestDestinationNodes",
    "requestMappings",              "scalarSourceNode",          "seal",
    "validateBindingCompatibility", "validateEarlyHome",         "validateFormAndDestination",
    "validateRequest",              "validateRequestAt",         "validateSemanticOrderTopology",
};
pub const value_use_planning_model_pub_names = [_][]const u8{
    "CopyVisitState",
    "Mapping",
    "PhysicalNode",
};
pub const value_use_planning_compatibility_pub_names = [_][]const u8{
    "validateBindingCompatibility",
    "validateCopyActionForm",
    "validateExpectedType",
    "validateI64StorePointer",
    "validateMemcpyLengthOperand",
    "validateMemcpyPointerOperand",
    "validateSourceView",
    "validateStackPointerStoreViews",
    "validateStoreI64ValueOperand",
    "validateStorePointerOperand",
    "validateStoreStackObjectOperand",
};
pub const value_use_planning_lifetime_pub_names = [_][]const u8{
    "core_availabilityForConsumption",
    "core_mustSurviveInstruction",
    "core_occupantNeedsPreservation",
    "validateDeferredSwitchRequest",
    "validateFormAndDestination",
    "validateRequest",
    "validateRequestAt",
};
pub const value_use_planning_semantic_pub_names = [_][]const u8{
    "actionOwnsOrderedWrites",
    "planEarlyMaterializations",
    "resetSemanticOrderPlan",
    "validateEarlyHome",
    "validateSemanticOrderTopology",
};
pub const value_use_planning_physical_pub_names = [_][]const u8{
    "argRegForNode",
    "nodeForArgReg",
    "pairSourceNodes",
    "requestDestinationNodes",
    "requestMappings",
    "scalarSourceNode",
    "seal",
};
pub const value_use_materialization_pub_names = [_][]const u8{
    "buildPreparedRecord",             "clobberPhysicalNode",     "materializeAll",
    "materializeByteAddressPointer",   "materializeEarlyPlans",   "materializeNull",
    "materializePair",                 "materializePairLimb",     "materializePointer",
    "materializeRequest",              "materializeScalar32",     "materializeScalar64",
    "materializeStackAddress",         "prepare",                 "preparedConditionView",
    "preparedMemcpyScalarView",        "preparedPairView",        "preparedPointerView",
    "preparedRecordEql",               "preparedScalarView",      "preparedScratchCompareView",
    "preparedStackF32PairAddressView", "preparedStackObjectView", "preparedViewFromLoc",
    "preparedViewLoc",                 "resolveNamedCurrent",     "validatePreparedShape",
};
pub const value_use_composition_pub_names = [_][]const u8{
    "beginAccumulatorSession",               "beginAccumulatorSessionForPreparedAction",
    "commitAccumulatorSession",              "defineAccumulatorResult",
    "finalizeAccumulatorResult",             "finishAccumulatorCallPreparationAfterArguments",
    "materializeAccumulator",                "ownActionIdentity",
    "ownRegisteredOperandName",              "prepareAccumulator",
    "prepareAccumulatorCallBeforeArguments", "spillAccumulatorValue",
};
pub const value_use_address_pub_names = [_][]const u8{
    "executeByteAddress",          "executeReadOnlyPairLoad",
    "executeReadOnlyTableAddress", "executeReadOnlyTableI16Load",
    "executeScalarLoad",           "executeScaledAddress",
    "executeStackI128AliasLoad",   "executeStoreI64",
    "executeStoreImmediate",       "executeStoreScalar",
    "executeStoreStackPointer",
};
pub const value_use_control_pub_names = [_][]const u8{
    "classifyScratchCompare",    "executeBranchCondition",
    "executeCurrentHomeEqZero",  "executeCurrentHomeSignBit",
    "executeI128EqMin",          "executeI128SignBit",
    "executeScratchCompare",     "executeSetccEaxCompare",
    "executeSwitchCompareChain", "isCurrentHomeSignBitIcmp",
    "isI128EqMinIcmp",           "isI128SignBitIcmp",
};
pub const value_use_scalar_arithmetic_pub_names = [_][]const u8{
    "executeAccumulatorScalarCast",        "executeImmediateLhsScalar",
    "executeImmediateRhsScalar",           "executeExactI52Binary",
    "executeNamedScalarBinary",            "executePairLowScalarCast",
    "executeScalarMultiply",               "executeSignExtendScratch",
    "executeUnsignedQuotient",             "isAccumulatorScalarCast",
    "isImmediateLhsScalar",                "isImmediateRhsScalar",
    "isExactI52Binary",                    "isNamedScalarBinary",
    "isScalarMultiply",                    "isUnsignedQuotient",
    "isPairLowScalarCast",                 "isSignExtendScratchCast",
    "validateAccumulatorScalarCastAction", "validateImmediateLhsScalarAction",
    "validateImmediateRhsScalarAction",    "validateExactI52BinaryAction",
    "validateNamedScalarBinaryAction",     "validatePairLowScalarCastAction",
    "validateScalarMultiplyAction",        "validateUnsignedQuotientAction",
};
pub const value_use_scalar_cast_pub_names = [_][]const u8{
    "executeAccumulatorScalarCast",
    "executePairLowScalarCast",
    "executeSignExtendScratch",
    "isAccumulatorScalarCast",
    "isPairLowScalarCast",
    "isSignExtendScratchCast",
    "validateAccumulatorScalarCastAction",
    "validatePairLowScalarCastAction",
};
pub const value_use_scalar_immediate_pub_names = [_][]const u8{
    "executeImmediateLhsScalar",
    "executeImmediateRhsScalar",
    "isImmediateLhsScalar",
    "isImmediateRhsScalar",
    "validateImmediateLhsScalarAction",
    "validateImmediateRhsScalarAction",
};
pub const value_use_scalar_named_pub_names = [_][]const u8{
    "executeExactI52Binary",
    "executeNamedScalarBinary",
    "isExactI52Binary",
    "isNamedScalarBinary",
    "validateExactI52BinaryAction",
    "validateNamedScalarBinaryAction",
};
pub const value_use_scalar_multiply_divide_pub_names = [_][]const u8{
    "executeScalarMultiply",
    "executeUnsignedQuotient",
    "isScalarMultiply",
    "isUnsignedQuotient",
    "validateScalarMultiplyAction",
    "validateUnsignedQuotientAction",
};
pub const value_use_calls_pub_names = [_][]const u8{
    "CallTestFailure",
    "executeAttachedCallAction",
    "executeInlineMemcpy",
    "executeInlineMemset",
    "setCallTestFailureForTest",
    "validateCallActionAttachment",
};

pub const frozen_bypass_inventory_path = "docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv";
pub const frozen_bypass_inventory_sha256 = "2d6c8c8819c4b0dff10b9d803a62125d7c46155c04a2c2cf2006f2aecffd8b11";
pub const value_use_facade_manifest_path = "docs/evidence/inbox128_o2_r1_facade_manifest.tsv";
pub const value_use_facade_manifest_sha256 = "2adcd99ee3bfbe0e9f09673f1df02ab305b5ddb2c1b461023152d5d03a079c26";
pub const bypass_operations = [_][]const u8{
    "directValueLocInstructionMaterializer",
    "emitBinaryLocIntoAccumulator",
    "emitValueIntoAccumulator",
    "emitValueIntoEax",
    "emitValueIntoFpReturn",
    "emitValueIntoI128Return",
    "emitValueIntoLoc",
    "emitValueIntoRax",
    "emitValueIntoScratch",
    "emitValueIntoScratchAndRelocate",
    "lowerHalfLocToFloatXmm0",
    "lowerStoreI64",
    "materializeF64Loc",
    "materializeLocIntoLoc",
    "materializeLocIntoLocWithBits",
    "materializePairValue",
    "materializeScalarPhiSnapshot",
    "resolvePairValue",
    "resolveValue",
    "valueLoc",
};

pub const DirectOperation = enum {
    bind_eax,
    bind_rax,
    bind_accumulator,
    clobber_accumulator,
    bind_value_loc,

    pub fn pattern(operation: DirectOperation) []const u8 {
        return switch (operation) {
            .bind_eax => "bindEax(",
            .bind_rax => "bindRax(",
            .bind_accumulator => "bindAccumulator(",
            .clobber_accumulator => "clobberAccumulator(",
            .bind_value_loc => "bindValueLoc(",
        };
    }
};

pub const ResidualClassification = enum {
    internal_temporary,
    alias_only_binding,
    approved_pair_rdx_exclusion,
    non_accumulator_result_path,
};

pub const FutureArchitecturalSlice = enum {
    none,
    pair_rdx_authority,
};

pub const ResidualAllowlistEntry = struct {
    source: []const u8,
    function: []const u8,
    operation: DirectOperation,
    structural_role: []const u8,
    classification: ResidualClassification,
    future_slice: FutureArchitecturalSlice,
    expected_count: usize,
};

// Exact INBOX-79 residual inventory. Every production occurrence is scoped to
// its enclosing function; additions, moves, and operation reclassification
// therefore fail closed. Ordinary EAX/RAX result producers are absent.
pub const residual_accumulator_allowlist = [_]ResidualAllowlistEntry{
    .{ .source = "composed_selector_aggregate.zig", .function = "lowerInsertValue", .operation = .bind_value_loc, .structural_role = "fixed aggregate-SSE result binding", .classification = .non_accumulator_result_path, .future_slice = .none, .expected_count = 3 },

    .{ .source = "composed_selector_calls.zig", .function = "lowerFpAbs", .operation = .clobber_accumulator, .structural_role = "temporary GPR bit-mask path for an XMM result", .classification = .internal_temporary, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_calls.zig", .function = "lowerUnsignedOverflowI32", .operation = .clobber_accumulator, .structural_role = "aggregate overflow flag temporary after value relocation to RDX", .classification = .approved_pair_rdx_exclusion, .future_slice = .pair_rdx_authority, .expected_count = 1 },
    .{ .source = "composed_selector_calls.zig", .function = "lowerSmulOverflowI64", .operation = .clobber_accumulator, .structural_role = "full-product RAX/RDX aggregate overflow flag temporary", .classification = .approved_pair_rdx_exclusion, .future_slice = .pair_rdx_authority, .expected_count = 1 },
    .{ .source = "composed_selector_calls.zig", .function = "lowerCtpop", .operation = .clobber_accumulator, .structural_role = "i128 pair-result limb accumulation temporary", .classification = .approved_pair_rdx_exclusion, .future_slice = .pair_rdx_authority, .expected_count = 1 },
    .{ .source = "composed_selector_calls.zig", .function = "lowerBitPermutation", .operation = .clobber_accumulator, .structural_role = "i128 pair-result limb permutation temporary", .classification = .approved_pair_rdx_exclusion, .future_slice = .pair_rdx_authority, .expected_count = 1 },

    .{ .source = "composed_selector_cfg.zig", .function = "lowerSelect", .operation = .bind_accumulator, .structural_role = "alias-only binding after both scalar select arms materialize", .classification = .alias_only_binding, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_cfg.zig", .function = "emitScalarSelectValue", .operation = .clobber_accumulator, .structural_role = "scalar select immediate-arm materialization temporary", .classification = .internal_temporary, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_cfg.zig", .function = "restoreDisplacedPhiDestinations", .operation = .bind_value_loc, .structural_role = "computed PHI destination alias restoration", .classification = .alias_only_binding, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_cfg.zig", .function = "emitPhiEdgeMoves", .operation = .bind_value_loc, .structural_role = "computed PHI edge destination alias binding", .classification = .alias_only_binding, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_cfg.zig", .function = "materializeScalarPhiSnapshot", .operation = .clobber_accumulator, .structural_role = "PHI snapshot copy-through-accumulator temporary", .classification = .internal_temporary, .future_slice = .none, .expected_count = 3 },
    .{ .source = "composed_selector_cfg.zig", .function = "emitValueIntoLoc", .operation = .clobber_accumulator, .structural_role = "PHI edge scratch/spill materialization temporary", .classification = .internal_temporary, .future_slice = .none, .expected_count = 4 },

    .{ .source = "composed_selector_conversion.zig", .function = "lowerUnsignedI64", .operation = .clobber_accumulator, .structural_role = "integer-to-FP conversion temporary for an XMM result", .classification = .internal_temporary, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_conversion.zig", .function = "lowerWideInteger", .operation = .clobber_accumulator, .structural_role = "wide integer-to-FP conversion temporary for an XMM result", .classification = .internal_temporary, .future_slice = .none, .expected_count = 1 },

    .{ .source = "composed_selector_fp.zig", .function = "lowerHalfFadd", .operation = .bind_value_loc, .structural_role = "fixed XMM0 half result binding", .classification = .non_accumulator_result_path, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_fp.zig", .function = "lowerCopySign", .operation = .clobber_accumulator, .structural_role = "GPR mask temporary for an XMM result", .classification = .internal_temporary, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_fp.zig", .function = "materializeFpValue", .operation = .clobber_accumulator, .structural_role = "FP immediate materialization temporary", .classification = .internal_temporary, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_fp.zig", .function = "lowerFcmp", .operation = .clobber_accumulator, .structural_role = "specialized FP compare result preparation", .classification = .internal_temporary, .future_slice = .none, .expected_count = 2 },
    .{ .source = "composed_selector_fp.zig", .function = "lowerFcmp", .operation = .bind_eax, .structural_role = "alias-only binding after specialized FP setcc", .classification = .alias_only_binding, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_fp.zig", .function = "lowerHalfOeqZero", .operation = .clobber_accumulator, .structural_role = "specialized half-zero compare result preparation", .classification = .internal_temporary, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_fp.zig", .function = "lowerHalfOeqZero", .operation = .bind_eax, .structural_role = "alias-only binding after specialized half-zero setcc", .classification = .alias_only_binding, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_fp.zig", .function = "lowerHalfFcmp", .operation = .clobber_accumulator, .structural_role = "specialized half compare conversion/result temporary", .classification = .internal_temporary, .future_slice = .none, .expected_count = 2 },
    .{ .source = "composed_selector_fp.zig", .function = "lowerHalfFcmp", .operation = .bind_eax, .structural_role = "alias-only binding after specialized half setcc", .classification = .alias_only_binding, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_fp.zig", .function = "lowerFpIntBitcast", .operation = .clobber_accumulator, .structural_role = "FP-to-integer bitcast result preparation", .classification = .internal_temporary, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_fp.zig", .function = "lowerFpIntBitcast", .operation = .bind_eax, .structural_role = "alias-only EAX binding after FP bit transfer", .classification = .alias_only_binding, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_fp.zig", .function = "lowerFpIntBitcast", .operation = .bind_rax, .structural_role = "alias-only RAX binding after FP bit transfer", .classification = .alias_only_binding, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_fp.zig", .function = "lowerFloatToHalf", .operation = .bind_value_loc, .structural_role = "fixed XMM0 half conversion result binding", .classification = .non_accumulator_result_path, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_fp.zig", .function = "lowerHalfExtension", .operation = .bind_value_loc, .structural_role = "fixed XMM0 half extension result binding", .classification = .non_accumulator_result_path, .future_slice = .none, .expected_count = 1 },

    .{ .source = "composed_selector_frame.zig", .function = "prepareStackFrame", .operation = .bind_value_loc, .structural_role = "fixed stack object and pointer binding", .classification = .non_accumulator_result_path, .future_slice = .none, .expected_count = 4 },

    .{ .source = "composed_selector_impl.zig", .function = "bindParams", .operation = .bind_value_loc, .structural_role = "fixed incoming ABI parameter binding", .classification = .non_accumulator_result_path, .future_slice = .none, .expected_count = 7 },
    .{ .source = "composed_selector_impl.zig", .function = "bindPhiResults", .operation = .bind_value_loc, .structural_role = "computed planned PHI destination alias binding", .classification = .alias_only_binding, .future_slice = .none, .expected_count = 3 },
    .{ .source = "composed_selector_impl.zig", .function = "stabilizeFramedPhiDestinations", .operation = .bind_value_loc, .structural_role = "computed stabilized PHI destination alias binding", .classification = .alias_only_binding, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_impl.zig", .function = "enterBlock", .operation = .bind_value_loc, .structural_role = "computed predecessor PHI location alias binding", .classification = .alias_only_binding, .future_slice = .none, .expected_count = 1 },

    .{ .source = "composed_selector_memory.zig", .function = "lowerStoreFp", .operation = .clobber_accumulator, .structural_role = "FP store address/value transfer temporary", .classification = .internal_temporary, .future_slice = .none, .expected_count = 2 },
    .{ .source = "composed_selector_memory.zig", .function = "loadStackU64IntoRax", .operation = .clobber_accumulator, .structural_role = "stack-to-RAX helper temporary with no result binding", .classification = .internal_temporary, .future_slice = .none, .expected_count = 1 },

    .{ .source = "composed_selector_scalar.zig", .function = "lowerCast", .operation = .bind_value_loc, .structural_role = "computed no-emission cast alias binding", .classification = .alias_only_binding, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_scalar.zig", .function = "lowerFreeze", .operation = .bind_value_loc, .structural_role = "computed no-emission freeze alias binding", .classification = .alias_only_binding, .future_slice = .none, .expected_count = 1 },

    .{ .source = "composed_selector_vector.zig", .function = "lowerMask4ToI4", .operation = .clobber_accumulator, .structural_role = "specialized vector-mask scalar extraction preparation", .classification = .internal_temporary, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_vector.zig", .function = "lowerI64x2ExtractElement", .operation = .clobber_accumulator, .structural_role = "specialized vector lane scalar extraction preparation", .classification = .internal_temporary, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_vector.zig", .function = "lowerI64x2ExtractElement", .operation = .bind_rax, .structural_role = "alias-only RAX binding after vector lane transfer", .classification = .alias_only_binding, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_vector.zig", .function = "lowerMaskExtractElement", .operation = .clobber_accumulator, .structural_role = "specialized vector-mask lane extraction preparation", .classification = .internal_temporary, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_vector.zig", .function = "bindMaskScalarResult", .operation = .bind_accumulator, .structural_role = "alias-only mask scalar result binding", .classification = .alias_only_binding, .future_slice = .none, .expected_count = 3 },
    .{ .source = "composed_selector_vector.zig", .function = "materializeLaneBits", .operation = .clobber_accumulator, .structural_role = "lane-bit immediate transfer temporary for an XMM result", .classification = .internal_temporary, .future_slice = .none, .expected_count = 1 },
};

pub const ExclusionOperation = enum {
    urem_rdx_result,
    full_product_rax_rdx,
    pair_result,

    pub fn pattern(operation: ExclusionOperation) []const u8 {
        return switch (operation) {
            .urem_rdx_result => "bindScratch(selector, result_name, .rdx, bits)",
            .full_product_rax_rdx => "prepareFixedProductDefs(selector)",
            .pair_result => "bindPairScratch(selector, result_name,",
        };
    }
};

pub const ExclusionAllowlistEntry = struct {
    source: []const u8,
    function: []const u8,
    operation: ExclusionOperation,
    structural_role: []const u8,
    future_slice: FutureArchitecturalSlice,
    expected_count: usize,
};

// The predeclared non-ordinary producer exclusions are pinned independently
// from the accumulator-call inventory so their non-EAX/RAX result bindings
// cannot move or multiply unnoticed.
pub const architectural_exclusion_allowlist = [_]ExclusionAllowlistEntry{
    .{ .source = "composed_selector_scalar.zig", .function = "lowerUnsignedRem", .operation = .urem_rdx_result, .structural_role = "unsigned remainder result in RDX", .future_slice = .pair_rdx_authority, .expected_count = 1 },
    .{ .source = "composed_selector_calls.zig", .function = "lowerSmulOverflowI64", .operation = .full_product_rax_rdx, .structural_role = "signed full-product RAX/RDX aggregate value", .future_slice = .pair_rdx_authority, .expected_count = 1 },
    .{ .source = "composed_selector_calls.zig", .function = "lowerCtpop", .operation = .pair_result, .structural_role = "i128 population-count pair result", .future_slice = .pair_rdx_authority, .expected_count = 1 },
    .{ .source = "composed_selector_calls.zig", .function = "lowerBitPermutation", .operation = .pair_result, .structural_role = "i128 bit-permutation pair result", .future_slice = .pair_rdx_authority, .expected_count = 1 },
    .{ .source = "composed_selector_calls.zig", .function = "lowerAbsI128", .operation = .pair_result, .structural_role = "i128 absolute-value pair result", .future_slice = .pair_rdx_authority, .expected_count = 1 },
    .{ .source = "composed_selector_scalar.zig", .function = "lowerBinaryImmediateLhs", .operation = .pair_result, .structural_role = "i128 immediate-LHS pair result", .future_slice = .pair_rdx_authority, .expected_count = 1 },
    .{ .source = "composed_selector_scalar.zig", .function = "lowerPairBinary", .operation = .pair_result, .structural_role = "i128 binary pair result", .future_slice = .pair_rdx_authority, .expected_count = 4 },
    .{ .source = "composed_selector_scalar.zig", .function = "lowerCast", .operation = .pair_result, .structural_role = "integer-to-i128 cast pair result", .future_slice = .pair_rdx_authority, .expected_count = 1 },
};

pub const FunctionFingerprint = struct {
    source: []const u8,
    function: []const u8,
    body_sha256: []const u8,
};

// Each allowlisted operation is additionally anchored by the exact tokenized
// function body that encloses it. Moving an operation between semantic
// branches changes this fingerprint even when the function-level count holds.
pub const residual_function_fingerprints = [_]FunctionFingerprint{
    .{ .source = "composed_selector_aggregate.zig", .function = "lowerInsertValue", .body_sha256 = "fc92d603662eeb6958b5797a0343f1ef9ec785dd9afcba5b69d5948108a1cc05" },

    .{ .source = "composed_selector_calls.zig", .function = "lowerFpAbs", .body_sha256 = "c6abc1b3e6db1cb525680f9fc387476665f04bb05e65faec8f0a959e0b5bfc68" },
    .{ .source = "composed_selector_calls.zig", .function = "lowerUnsignedOverflowI32", .body_sha256 = "4dc4da7d4dd45a3ddb97b01d1c722605a902b76c147962bfc5581e59333d0121" },
    .{ .source = "composed_selector_calls.zig", .function = "lowerSmulOverflowI64", .body_sha256 = "2a2054e1320aecd14ce33eea5acce117193675bcf71cbf9efc8160f573b98ded" },
    .{ .source = "composed_selector_calls.zig", .function = "lowerCtpop", .body_sha256 = "386892044354332641c3184338b678f04aa018652f909cb27820bb82788fd66a" },
    .{ .source = "composed_selector_calls.zig", .function = "lowerBitPermutation", .body_sha256 = "7ae35efc097e20cbd351e3b31531210c4c4dbf3395add38c8ddc5d8901b7d2b7" },
    .{ .source = "composed_selector_calls.zig", .function = "lowerAbsI128", .body_sha256 = "cf69f866c281db4b54bbeec420603927e57fc1b11220102ce0da5d2137296d79" },

    .{ .source = "composed_selector_cfg.zig", .function = "lowerSelect", .body_sha256 = "7de55a040bf63ee1db4c709fde09ddf8c865a3dc6ba7ceadcd3677520937a5f1" },
    .{ .source = "composed_selector_cfg.zig", .function = "emitScalarSelectValue", .body_sha256 = "3cfedbd0e4c15ed10dbf266fcc09854fcc0a183f9eb6367f21c5a2a17832143a" },
    .{ .source = "composed_selector_cfg.zig", .function = "restoreDisplacedPhiDestinations", .body_sha256 = "60fd82341b65b3871cd42cc35b5b2b9accadccf217c551d619b742da4664dd1a" },
    .{ .source = "composed_selector_cfg.zig", .function = "emitPhiEdgeMoves", .body_sha256 = "01698460d35fe4d18ab53ffd9b16d92f778625d29c4d9dde5d16b41251311d70" },
    .{ .source = "composed_selector_cfg.zig", .function = "materializeScalarPhiSnapshot", .body_sha256 = "b4362e002bdf4d9d26b75e6c054c0294250fbe894a34c42e4ad4b542d8a75616" },
    .{ .source = "composed_selector_cfg.zig", .function = "emitValueIntoLoc", .body_sha256 = "d2a8cdd3327dca52cf55a1bc5825b5b5e3210dad426c33073233d4a2ea00de3c" },

    .{ .source = "composed_selector_conversion.zig", .function = "lowerUnsignedI64", .body_sha256 = "5529a412ec2efd88d5155aa6042341963928853fd75dc01ca9f5f897a391d941" },
    .{ .source = "composed_selector_conversion.zig", .function = "lowerWideInteger", .body_sha256 = "1156e47aa1ca42b16dc2abd52f99caf2ad2ad3dcec871fea124b873023a49dad" },

    .{ .source = "composed_selector_fp.zig", .function = "lowerHalfFadd", .body_sha256 = "017cf5df4a1e73f5b342c9f2714c952b3479cffb13b662ec9291b34cfa3e3fb0" },
    .{ .source = "composed_selector_fp.zig", .function = "lowerCopySign", .body_sha256 = "3cc9a52f65a3ae0aa7a02f815c529662218ab923b2658aa8d8530937a2fee831" },
    .{ .source = "composed_selector_fp.zig", .function = "materializeFpValue", .body_sha256 = "0127e07639dabb6ece03faf1cc240af3547904a1124fe2a4ed76a6f52e136645" },
    .{ .source = "composed_selector_fp.zig", .function = "lowerFcmp", .body_sha256 = "fa502ad214048f3afb55e11dd87872af687fef9816470ea4c59ee34840665484" },
    .{ .source = "composed_selector_fp.zig", .function = "lowerHalfOeqZero", .body_sha256 = "de1f42d09aebc6de4e9f5c35aeb59330f2e6871443d66e0b870eb46df603aeb5" },
    .{ .source = "composed_selector_fp.zig", .function = "lowerHalfFcmp", .body_sha256 = "e429cc984c62e169d1d294144f8fb330aa6c4fc6b2fc8e7aec4ab2b40bdf194b" },
    .{ .source = "composed_selector_fp.zig", .function = "lowerFpIntBitcast", .body_sha256 = "f02eefad53336dd24e5261f34f6a19e7011849404e3ea3932b822db9780e4012" },
    .{ .source = "composed_selector_fp.zig", .function = "lowerFloatToHalf", .body_sha256 = "ee1a865fa09595be9ac940a938d7ec3b5996b25a835a92afa7b17fbb72016960" },
    .{ .source = "composed_selector_fp.zig", .function = "lowerHalfExtension", .body_sha256 = "86cd446354c4986acf2cc70c24d18f69f054f2a38703ab9ee7f2e47ae1e6be2c" },

    .{ .source = "composed_selector_frame.zig", .function = "prepareStackFrame", .body_sha256 = "c552e672aa7b21cc0ed1777e8f54ab6147e41a5c5d73b72a30777ae1a0d3d7ec" },

    .{ .source = "composed_selector_impl.zig", .function = "bindParams", .body_sha256 = "8202324e1f10f6ca3472eb35af58f1a73d14555125d754007526b35a5f571279" },
    .{ .source = "composed_selector_impl.zig", .function = "bindPhiResults", .body_sha256 = "283fc0d5adddb7c7ac2fad47020bf99b026be3e2c09accabd0077d6e8b7abcf8" },
    .{ .source = "composed_selector_impl.zig", .function = "stabilizeFramedPhiDestinations", .body_sha256 = "84522a7d762d08de43dcffc4c9284f642605be75b0078f0bf74516df20f1196f" },
    .{ .source = "composed_selector_impl.zig", .function = "enterBlock", .body_sha256 = "edb2e130813a5ca0847f5e5060f9088d196db18deaec281dbd95a58b7db92b1f" },

    .{ .source = "composed_selector_memory.zig", .function = "lowerStoreFp", .body_sha256 = "08773e5639dfcc22a932d0a4d702bbe8ff4b3ecb5e398c3b06a9de056fb8a81d" },
    .{ .source = "composed_selector_memory.zig", .function = "loadStackU64IntoRax", .body_sha256 = "3fd7fcf3653b5083f8123224f83a04abd16bbb7411dac2d4279079a74cf7648d" },

    .{ .source = "composed_selector_scalar.zig", .function = "lowerCast", .body_sha256 = "44a3371c3c0125f6fc7b76d70cbe1a138c109d94d2b51df69410d7358f970249" },
    .{ .source = "composed_selector_scalar.zig", .function = "lowerFreeze", .body_sha256 = "110d9c541f057cdb2a9a350cb9c16a1f9eac811c9739ed6cda8826d614b70b84" },
    .{ .source = "composed_selector_scalar.zig", .function = "lowerUnsignedRem", .body_sha256 = "8536b14d20e330bce4f1717f6dda9d3f6b663664507cf302d1e4d6a68fccf211" },
    .{ .source = "composed_selector_scalar.zig", .function = "lowerBinaryImmediateLhs", .body_sha256 = "00006893705d1a9313e51fff70572cac4aafed354d56edacf66ada2e8203aad1" },
    .{ .source = "composed_selector_scalar.zig", .function = "lowerPairBinary", .body_sha256 = "eb1fd1587c460328e15d5fc0a5805364a08b26538f233134211def686696c204" },

    .{ .source = "composed_selector_vector.zig", .function = "lowerMask4ToI4", .body_sha256 = "1e62b361133724f37967c07e4ad6896dd1a83c1b5dd48f394a7f677373f2f912" },
    .{ .source = "composed_selector_vector.zig", .function = "lowerI64x2ExtractElement", .body_sha256 = "a2910ce5399d079e9843b0d0cfb84744322f7a8d8c49c70d3656f3b5b4dadca5" },
    .{ .source = "composed_selector_vector.zig", .function = "lowerMaskExtractElement", .body_sha256 = "f0266e26516fdac573f2884fc2633783cffc309e3a18c3205e696eb91c2bdda7" },
    .{ .source = "composed_selector_vector.zig", .function = "bindMaskScalarResult", .body_sha256 = "09ae0154e05f25471555c6a8c7c213f9879b128ff820693611199dac4afe36f1" },
    .{ .source = "composed_selector_vector.zig", .function = "materializeLaneBits", .body_sha256 = "1da4969d92d741be7fe53dc07461046dee0acf56fd161e50c94e666863c5c639" },
};

pub const FunctionBody = struct {
    name: []const u8,
    start: usize,
    end: usize,
};

pub const max_function_bodies = 512;

pub fn readFrozenBypassInventory(allocator: std.mem.Allocator) ![:0]u8 {
    return std.Io.Dir.cwd().readFileAllocOptions(
        std.testing.io,
        frozen_bypass_inventory_path,
        allocator,
        .limited(128 * 1024),
        .of(u8),
        0,
    );
}

pub fn validateNoPublicPreparedPointer(source: []const u8) !void {
    var cursor: usize = 0;
    while (std.mem.indexOfPos(u8, source, cursor, "pub fn ")) |start| {
        const signature_end = std.mem.indexOfPos(u8, source, start, "{") orelse
            return error.InvalidZigSource;
        const signature = source[start..signature_end];
        if (std.mem.indexOf(u8, signature, "*const PreparedView") != null or
            std.mem.indexOf(u8, signature, "*PreparedView") != null or
            std.mem.indexOf(u8, signature, "*const PreparedRecord") != null or
            std.mem.indexOf(u8, signature, "*PreparedRecord") != null)
        {
            return error.ValueUsePreparedLocationEscape;
        }
        cursor = signature_end + 1;
    }
}

pub fn validateNoFunctionFamilyPredicate(source: [:0]const u8, forbidden_error: anyerror) !void {
    var tokenizer = std.zig.Tokenizer.init(source);
    while (true) {
        const token = tokenizer.next();
        switch (token.tag) {
            .eof => return,
            .invalid => return error.InvalidZigSource,
            .identifier => {
                const identifier = source[token.loc.start..token.loc.end];
                const reviewed_exact_i52_identifier =
                    std.mem.eql(u8, identifier, "Function") or
                    std.mem.eql(u8, identifier, "isExactI52Binary") or
                    std.mem.eql(u8, identifier, "isExactI52ShiftCount") or
                    std.mem.eql(u8, identifier, "isExactCtlzI52Envelope") or
                    std.mem.eql(u8, identifier, "ExactI52BinaryAction") or
                    std.mem.eql(u8, identifier, "ExactI52Plan") or
                    std.mem.eql(u8, identifier, "executeExactI52Binary") or
                    std.mem.eql(u8, identifier, "validateExactI52BinaryAction") or
                    std.mem.eql(u8, identifier, "callee") or
                    std.mem.eql(u8, identifier, "callee_value") or
                    std.mem.eql(u8, identifier, "callee_function_ty");
                if (reviewed_exact_i52_identifier) continue;
                if (std.mem.indexOf(u8, identifier, "function") != null or
                    std.mem.indexOf(u8, identifier, "Function") != null or
                    std.mem.indexOf(u8, identifier, "family") != null or
                    std.mem.indexOf(u8, identifier, "Family") != null or
                    std.mem.indexOf(u8, identifier, "callee") != null or
                    std.mem.indexOf(u8, identifier, "Callee") != null or
                    std.mem.startsWith(u8, identifier, "isExact"))
                {
                    return forbidden_error;
                }
            },
            else => {},
        }
    }
}

pub const ParsedBypassSite = struct {
    operation: []const u8,
    count: usize,
};

pub fn parseFrozenBypassSite(site: []const u8) !ParsedBypassSite {
    const separator = std.mem.lastIndexOf(u8, site, "×") orelse
        return error.MalformedFrozenBypassInventory;
    const operation = site[0..separator];
    const count_text = site[separator + "×".len ..];
    if (operation.len == 0 or count_text.len == 0) return error.MalformedFrozenBypassInventory;
    return .{
        .operation = operation,
        .count = std.fmt.parseUnsigned(usize, count_text, 10) catch
            return error.MalformedFrozenBypassInventory,
    };
}

pub fn frozenBypassExpectedCount(
    inventory: []const u8,
    source_name: []const u8,
    function_name: []const u8,
    operation: []const u8,
) !?usize {
    var matching_row = false;
    var result: ?usize = null;
    var lines = std.mem.splitScalar(u8, inventory, '\n');
    _ = lines.next();
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var fields = std.mem.splitScalar(u8, line, '\t');
        const file = fields.next() orelse return error.MalformedFrozenBypassInventory;
        const function = fields.next() orelse return error.MalformedFrozenBypassInventory;
        const sites = fields.next() orelse return error.MalformedFrozenBypassInventory;
        if (!std.mem.eql(u8, file, source_name) or !std.mem.eql(u8, function, function_name)) continue;
        if (matching_row) return error.DuplicateFrozenBypassInventoryRow;
        matching_row = true;
        var site_it = std.mem.splitSequence(u8, sites, ", ");
        while (site_it.next()) |site| {
            const parsed = try parseFrozenBypassSite(site);
            if (!std.mem.eql(u8, parsed.operation, operation)) continue;
            if (result != null) return error.DuplicateFrozenBypassOperation;
            result = parsed.count;
        }
    }
    return if (matching_row) result orelse 0 else null;
}

pub fn isBypassOperation(operation: []const u8) bool {
    for (bypass_operations) |allowed| if (std.mem.eql(u8, allowed, operation)) return true;
    return false;
}

pub fn countPattern(source: []const u8, pattern: []const u8) usize {
    var count: usize = 0;
    var search_from: usize = 0;
    while (std.mem.indexOfPos(u8, source, search_from, pattern)) |offset| {
        count += 1;
        search_from = offset + pattern.len;
    }
    return count;
}
