const std = @import("std");

const source_dir = "src/codegen/x86_64/generic_cfg";
const source_prefix = "composed_selector_";
const source_suffix = ".zig";

const SourceKind = enum {
    authority,
    address_dependency_domain,
    value_use_authority,
    lifecycle,
    consumer,
};

const ClassifiedSource = struct {
    name: []const u8,
    kind: SourceKind,
};

// Every production composed-selector source must appear here. Test sources are
// white-box fixtures and are deliberately classified by their `_tests.zig`
// suffix instead.
const classified_sources = [_]ClassifiedSource{
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

const frozen_bypass_inventory_path = "docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv";
const frozen_bypass_inventory_sha256 = "281ef86923fbc72fd4254bfadc6586030bab00dd73aeeb528556622a0803a9b1";
const bypass_operations = [_][]const u8{
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

const DirectOperation = enum {
    bind_eax,
    bind_rax,
    bind_accumulator,
    clobber_accumulator,
    bind_value_loc,

    fn pattern(operation: DirectOperation) []const u8 {
        return switch (operation) {
            .bind_eax => "bindEax(",
            .bind_rax => "bindRax(",
            .bind_accumulator => "bindAccumulator(",
            .clobber_accumulator => "clobberAccumulator(",
            .bind_value_loc => "bindValueLoc(",
        };
    }
};

const ResidualClassification = enum {
    internal_temporary,
    alias_only_binding,
    approved_pair_rdx_exclusion,
    non_accumulator_result_path,
};

const FutureArchitecturalSlice = enum {
    none,
    pair_rdx_authority,
};

const ResidualAllowlistEntry = struct {
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
const residual_accumulator_allowlist = [_]ResidualAllowlistEntry{
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

    .{ .source = "composed_selector_impl.zig", .function = "bindParams", .operation = .bind_value_loc, .structural_role = "fixed incoming ABI parameter binding", .classification = .non_accumulator_result_path, .future_slice = .none, .expected_count = 5 },
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

const ExclusionOperation = enum {
    urem_rdx_result,
    full_product_rax_rdx,
    pair_result,

    fn pattern(operation: ExclusionOperation) []const u8 {
        return switch (operation) {
            .urem_rdx_result => "bindScratch(selector, result_name, .rdx, bits)",
            .full_product_rax_rdx => "prepareFixedProductDefs(selector)",
            .pair_result => "bindPairScratch(selector, result_name,",
        };
    }
};

const ExclusionAllowlistEntry = struct {
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
const architectural_exclusion_allowlist = [_]ExclusionAllowlistEntry{
    .{ .source = "composed_selector_scalar.zig", .function = "lowerUnsignedRem", .operation = .urem_rdx_result, .structural_role = "unsigned remainder result in RDX", .future_slice = .pair_rdx_authority, .expected_count = 1 },
    .{ .source = "composed_selector_calls.zig", .function = "lowerSmulOverflowI64", .operation = .full_product_rax_rdx, .structural_role = "signed full-product RAX/RDX aggregate value", .future_slice = .pair_rdx_authority, .expected_count = 1 },
    .{ .source = "composed_selector_calls.zig", .function = "lowerCtpop", .operation = .pair_result, .structural_role = "i128 population-count pair result", .future_slice = .pair_rdx_authority, .expected_count = 1 },
    .{ .source = "composed_selector_calls.zig", .function = "lowerBitPermutation", .operation = .pair_result, .structural_role = "i128 bit-permutation pair result", .future_slice = .pair_rdx_authority, .expected_count = 1 },
    .{ .source = "composed_selector_calls.zig", .function = "lowerAbsI128", .operation = .pair_result, .structural_role = "i128 absolute-value pair result", .future_slice = .pair_rdx_authority, .expected_count = 1 },
    .{ .source = "composed_selector_scalar.zig", .function = "lowerBinaryImmediateLhs", .operation = .pair_result, .structural_role = "i128 immediate-LHS pair result", .future_slice = .pair_rdx_authority, .expected_count = 1 },
    .{ .source = "composed_selector_scalar.zig", .function = "lowerPairBinary", .operation = .pair_result, .structural_role = "i128 binary pair result", .future_slice = .pair_rdx_authority, .expected_count = 4 },
    .{ .source = "composed_selector_scalar.zig", .function = "lowerCast", .operation = .pair_result, .structural_role = "integer-to-i128 cast pair result", .future_slice = .pair_rdx_authority, .expected_count = 1 },
};

const FunctionFingerprint = struct {
    source: []const u8,
    function: []const u8,
    body_sha256: []const u8,
};

// Each allowlisted operation is additionally anchored by the exact tokenized
// function body that encloses it. Moving an operation between semantic
// branches changes this fingerprint even when the function-level count holds.
const residual_function_fingerprints = [_]FunctionFingerprint{
    .{ .source = "composed_selector_aggregate.zig", .function = "lowerInsertValue", .body_sha256 = "fc92d603662eeb6958b5797a0343f1ef9ec785dd9afcba5b69d5948108a1cc05" },

    .{ .source = "composed_selector_calls.zig", .function = "lowerFpAbs", .body_sha256 = "c6abc1b3e6db1cb525680f9fc387476665f04bb05e65faec8f0a959e0b5bfc68" },
    .{ .source = "composed_selector_calls.zig", .function = "lowerUnsignedOverflowI32", .body_sha256 = "4dc4da7d4dd45a3ddb97b01d1c722605a902b76c147962bfc5581e59333d0121" },
    .{ .source = "composed_selector_calls.zig", .function = "lowerSmulOverflowI64", .body_sha256 = "7354791d4df4eba960278a7e0662130d91700494cb73b4c83233fcf662f76cb9" },
    .{ .source = "composed_selector_calls.zig", .function = "lowerCtpop", .body_sha256 = "386892044354332641c3184338b678f04aa018652f909cb27820bb82788fd66a" },
    .{ .source = "composed_selector_calls.zig", .function = "lowerBitPermutation", .body_sha256 = "498fb6091e5385483eb55a6b67d2c813fb7ce8a401c41f837a451adf1150a497" },
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

    .{ .source = "composed_selector_frame.zig", .function = "prepareStackFrame", .body_sha256 = "a8bcdf56e974a472cccd313a71889df9c6724bd7db069754dbb15556f166516c" },

    .{ .source = "composed_selector_impl.zig", .function = "bindParams", .body_sha256 = "7c01485e0ef99b02379254f22843a201d6e020ad7d020587ee6f0c8158ad7afb" },
    .{ .source = "composed_selector_impl.zig", .function = "bindPhiResults", .body_sha256 = "9b28317ec222e3cfab3bba08a458b2168ff1cf7c3266edda61536781a8e47c0c" },
    .{ .source = "composed_selector_impl.zig", .function = "stabilizeFramedPhiDestinations", .body_sha256 = "84522a7d762d08de43dcffc4c9284f642605be75b0078f0bf74516df20f1196f" },
    .{ .source = "composed_selector_impl.zig", .function = "enterBlock", .body_sha256 = "edb2e130813a5ca0847f5e5060f9088d196db18deaec281dbd95a58b7db92b1f" },

    .{ .source = "composed_selector_memory.zig", .function = "lowerStoreFp", .body_sha256 = "08773e5639dfcc22a932d0a4d702bbe8ff4b3ecb5e398c3b06a9de056fb8a81d" },
    .{ .source = "composed_selector_memory.zig", .function = "loadStackU64IntoRax", .body_sha256 = "3fd7fcf3653b5083f8123224f83a04abd16bbb7411dac2d4279079a74cf7648d" },

    .{ .source = "composed_selector_scalar.zig", .function = "lowerCast", .body_sha256 = "84e76037ccb926b8edcfd5965355fcb81461d96318b71ae6e47ae96b74e3766d" },
    .{ .source = "composed_selector_scalar.zig", .function = "lowerFreeze", .body_sha256 = "110d9c541f057cdb2a9a350cb9c16a1f9eac811c9739ed6cda8826d614b70b84" },
    .{ .source = "composed_selector_scalar.zig", .function = "lowerUnsignedRem", .body_sha256 = "8536b14d20e330bce4f1717f6dda9d3f6b663664507cf302d1e4d6a68fccf211" },
    .{ .source = "composed_selector_scalar.zig", .function = "lowerBinaryImmediateLhs", .body_sha256 = "6db0334ddb212391cd4c3ee92e7aa6fe86768a2196e7235af1fef35a09919626" },
    .{ .source = "composed_selector_scalar.zig", .function = "lowerPairBinary", .body_sha256 = "16f097aeb8b2391b7ab68a68810854781d3bcfee4c276645d37b7355442ee650" },

    .{ .source = "composed_selector_vector.zig", .function = "lowerMask4ToI4", .body_sha256 = "1e62b361133724f37967c07e4ad6896dd1a83c1b5dd48f394a7f677373f2f912" },
    .{ .source = "composed_selector_vector.zig", .function = "lowerI64x2ExtractElement", .body_sha256 = "a2910ce5399d079e9843b0d0cfb84744322f7a8d8c49c70d3656f3b5b4dadca5" },
    .{ .source = "composed_selector_vector.zig", .function = "lowerMaskExtractElement", .body_sha256 = "f0266e26516fdac573f2884fc2633783cffc309e3a18c3205e696eb91c2bdda7" },
    .{ .source = "composed_selector_vector.zig", .function = "bindMaskScalarResult", .body_sha256 = "09ae0154e05f25471555c6a8c7c213f9879b128ff820693611199dac4afe36f1" },
    .{ .source = "composed_selector_vector.zig", .function = "materializeLaneBits", .body_sha256 = "1da4969d92d741be7fe53dc07461046dee0acf56fd161e50c94e666863c5c639" },
};

const FunctionBody = struct {
    name: []const u8,
    start: usize,
    end: usize,
};

const max_function_bodies = 256;

fn validateCurrentTree(allocator: std.mem.Allocator) !void {
    const io = std.testing.io;
    var dir = try std.Io.Dir.cwd().openDir(io, source_dir, .{ .iterate = true });
    defer dir.close(io);

    var seen = [_]bool{false} ** classified_sources.len;
    var iterator = dir.iterate();
    while (try iterator.next(io)) |entry| {
        if (entry.kind != .file or
            !std.mem.startsWith(u8, entry.name, source_prefix) or
            !std.mem.endsWith(u8, entry.name, source_suffix) or
            isTestSource(entry.name)) continue;

        const classification_index = classificationIndex(entry.name) orelse return error.UnclassifiedComposedSelectorSource;
        seen[classification_index] = true;
        const path = try std.fs.path.join(allocator, &.{ source_dir, entry.name });
        defer allocator.free(path);
        const source = try std.Io.Dir.cwd().readFileAllocOptions(
            io,
            path,
            allocator,
            .limited(2 * 1024 * 1024),
            .of(u8),
            0,
        );
        defer allocator.free(source);
        try validateProductionSource(entry.name, source);
    }

    for (seen) |was_seen| {
        if (!was_seen) return error.MissingClassifiedComposedSelectorSource;
    }
    const inventory = try readFrozenBypassInventory(allocator);
    defer allocator.free(inventory);
    try validateFrozenBypassInventoryHash(inventory);
}

fn validateProductionSource(name: []const u8, source: [:0]const u8) !void {
    const index = classificationIndex(name) orelse return error.UnclassifiedComposedSelectorSource;
    switch (classified_sources[index].kind) {
        .authority => try validateAddressDependencyStateAuthority(source),
        .address_dependency_domain => try validateAddressDependencyDomainSource(source),
        .value_use_authority => try validateValueUseAuthoritySource(source),
        .lifecycle => try validateStateDataLifecycle(source),
        .consumer => {
            if (std.mem.indexOf(u8, source, ".values") != null) return error.RawSelectorValuesAccess;
            const inventory = try readFrozenBypassInventory(std.testing.allocator);
            defer std.testing.allocator.free(inventory);
            try validateFrozenBypassInventoryForSource(inventory, name, source);
            try validateFunctionFingerprintInventory(name, source);
            try validateResidualAccumulatorAllowlist(&residual_accumulator_allowlist, &residual_function_fingerprints, name, source);
            try validateArchitecturalExclusionAllowlist(name, source);
            try validateAccumulatorDisplacementPolicies(source);
            try validateEflagsEmissionAuthority(name, source);
            try validatePreparedViewLeafDiscipline(name, source);
        },
    }
}

fn readFrozenBypassInventory(allocator: std.mem.Allocator) ![:0]u8 {
    return std.Io.Dir.cwd().readFileAllocOptions(
        std.testing.io,
        frozen_bypass_inventory_path,
        allocator,
        .limited(128 * 1024),
        .of(u8),
        0,
    );
}

fn validateValueUseAuthoritySource(source: [:0]const u8) !void {
    try validateNoFunctionFamilyPredicate(source, error.ValueUseFunctionPredicateForbidden);
    if (std.mem.indexOf(u8, source, "pub const SemanticRole") != null or
        std.mem.indexOf(u8, source, "pub const OperandPhase") != null or
        std.mem.indexOf(u8, source, "pub const OrderedOperand") != null or
        std.mem.indexOf(u8, source, "semantic_priority") != null or
        std.mem.indexOf(u8, source, "ordering_priority") != null)
    {
        return error.ValueUseConsumerOrderingForbidden;
    }
    if (std.mem.indexOf(u8, source, "pub const PreparedView =") != null or
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
    try validateNoPublicPreparedPointer(source);
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
    try validateDurableActionIdentityOwnership(source);
    try validateScratchComparePreservationPreamble(source);
    try validateCurrentHomeEqZeroSequence(source);
    try validateSetccEaxCompareSequence(source);
    try validateCurrentHomeSignBitSequence(source);
}

fn validatePreparedViewLeafDiscipline(source_name: []const u8, source: [:0]const u8) !void {
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

fn validateScratchCompareIntentSurface(source: []const u8) !void {
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

fn validateCurrentHomeEqZeroIntentSurface(source: []const u8) !void {
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

fn validateSetccEaxCompareIntentSurface(source: []const u8) !void {
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

fn validateCurrentHomeSignBitIntentSurface(source: []const u8) !void {
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

fn validateScratchComparePreservationPreamble(source: [:0]const u8) !void {
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
        if (functionBodyNamed(bodies, "preserveCurrentHomeSignBitLiveAccumulator") != null)
            2
        else
            1;

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

fn validateCurrentHomeEqZeroSequence(source: [:0]const u8) !void {
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

fn validateSetccEaxCompareSequence(source: [:0]const u8) !void {
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

fn validateCurrentHomeSignBitSequence(source: [:0]const u8) !void {
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

fn validateDurableActionIdentityOwnership(source: [:0]const u8) !void {
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
}

fn validateScratchCompareProductionSites(source_name: []const u8, source: [:0]const u8) !void {
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

fn validateCurrentHomeEqZeroProductionSites(
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

fn validateSetccEaxCompareProductionSites(
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

fn validateCurrentHomeSignBitProductionSites(
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

fn validateLoadDiagnosticMappingProductionSites(source_name: []const u8, source: [:0]const u8) !void {
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

fn validateDormantLoadActionProductionSites(source_name: []const u8, source: [:0]const u8) !void {
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

fn validateAccumulatorCompositionProductionSites(source_name: []const u8, source: [:0]const u8) !void {
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
        const scratch_source = source[action_body.start..action_body.end];
        const current_home_source = source[current_home_body.start..current_home_body.end];
        const setcc_source = source[setcc_body.start..setcc_body.end];
        const sign_bit_source = source[sign_bit_body.start..sign_bit_body.end];
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
            countPattern(source, "beginAccumulatorSession(") != 4)
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

fn validateFailureProvenanceProductionSites(source_name: []const u8, source: [:0]const u8) !void {
    const query_count = countPattern(source, ".failedRequestIs(");
    if (query_count == 0) return;
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
        if (countPattern(source[scratch_mapper.start..scratch_mapper.end], ".failedRequestIs(") != 2 or
            countPattern(source[current_home_mapper.start..current_home_mapper.end], ".failedRequestIs(") != 1 or
            countPattern(source[setcc_mapper.start..setcc_mapper.end], ".failedRequestIs(") != 1 or
            countPattern(source[sign_bit_mapper.start..sign_bit_mapper.end], ".failedRequestIs(") != 1 or
            query_count != 5)
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

fn validateMemcpyActionProductionSites(source_name: []const u8, source: [:0]const u8) !void {
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

fn validateSwitchActionProductionSites(source_name: []const u8, source: [:0]const u8) !void {
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

fn validateBranchActionProductionSites(source_name: []const u8, source: [:0]const u8) !void {
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

fn validateStoreActionProductionSites(source_name: []const u8, source: [:0]const u8) !void {
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

fn validateNoPublicPreparedPointer(source: []const u8) !void {
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

fn validateNoFunctionFamilyPredicate(source: [:0]const u8, forbidden_error: anyerror) !void {
    var tokenizer = std.zig.Tokenizer.init(source);
    while (true) {
        const token = tokenizer.next();
        switch (token.tag) {
            .eof => return,
            .invalid, .invalid_periodasterisks => return error.InvalidZigSource,
            .identifier => {
                const identifier = source[token.loc.start..token.loc.end];
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

fn validateAddressDependencyStateAuthority(source: [:0]const u8) !void {
    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const body = functionBodyNamed(bodies, "valueIsLiveAfterCurrent") orelse
        return error.AddressDependencyLivenessAuthorityMissing;
    const liveness_body = source[body.start..body.end];
    if (std.mem.indexOf(u8, liveness_body, "stack_i32_ptr") != null)
        return error.StackPointerLivenessSpecialCaseReintroduced;
}

fn validateAddressDependencyDomainSource(source: [:0]const u8) !void {
    try validateNoFunctionFamilyPredicate(source, error.AddressDependencyFunctionPredicateForbidden);
}

fn validateFrozenBypassInventoryHash(inventory: []const u8) !void {
    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(inventory, &digest, .{});
    const actual = std.fmt.bytesToHex(digest, .lower);
    if (!std.mem.eql(u8, &actual, frozen_bypass_inventory_sha256))
        return error.FrozenBypassInventoryHashMismatch;
}

fn validateFrozenBypassInventoryForSource(
    inventory: []const u8,
    source_name: []const u8,
    source: [:0]const u8,
) !void {
    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);

    for (bodies) |body| {
        for (bypass_operations) |operation| {
            var pattern_storage: [96]u8 = undefined;
            const pattern = try std.fmt.bufPrint(&pattern_storage, "{s}(", .{operation});
            const actual = if (std.mem.eql(u8, operation, "directValueLocInstructionMaterializer"))
                @as(usize, if (std.mem.eql(u8, body.name, "materializeF64Loc")) 1 else 0)
            else
                countPattern(source[body.start..body.end], pattern);
            const expected_count = try frozenBypassExpectedCount(
                inventory,
                source_name,
                body.name,
                operation,
            ) orelse 0;
            if (actual != expected_count) return error.FrozenBypassOccurrenceMismatch;
        }
    }

    var lines = std.mem.splitScalar(u8, inventory, '\n');
    _ = lines.next();
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var fields = std.mem.splitScalar(u8, line, '\t');
        const file = fields.next() orelse return error.MalformedFrozenBypassInventory;
        const function = fields.next() orelse return error.MalformedFrozenBypassInventory;
        const sites = fields.next() orelse return error.MalformedFrozenBypassInventory;
        if (fields.next() != null) return error.MalformedFrozenBypassInventory;
        if (!std.mem.eql(u8, file, source_name)) continue;
        if (std.mem.eql(u8, function, "-")) {
            if (!std.mem.eql(u8, sites, "none×0")) return error.MalformedFrozenBypassInventory;
            continue;
        }
        if (functionBodyNamed(bodies, function) == null) return error.FrozenBypassFunctionMissing;
        var site_it = std.mem.splitSequence(u8, sites, ", ");
        while (site_it.next()) |site| {
            const parsed = try parseFrozenBypassSite(site);
            if (!isBypassOperation(parsed.operation)) return error.FrozenBypassOperationUnclassified;
        }
    }
}

const ParsedBypassSite = struct {
    operation: []const u8,
    count: usize,
};

fn parseFrozenBypassSite(site: []const u8) !ParsedBypassSite {
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

fn frozenBypassExpectedCount(
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

fn isBypassOperation(operation: []const u8) bool {
    for (bypass_operations) |allowed| if (std.mem.eql(u8, allowed, operation)) return true;
    return false;
}

fn countPattern(source: []const u8, pattern: []const u8) usize {
    var count: usize = 0;
    var search_from: usize = 0;
    while (std.mem.indexOfPos(u8, source, search_from, pattern)) |offset| {
        count += 1;
        search_from = offset + pattern.len;
    }
    return count;
}

fn validateEflagsEmissionAuthority(name: []const u8, source: []const u8) !void {
    const guarded = std.mem.eql(u8, name, "composed_selector_calls.zig") or
        std.mem.eql(u8, name, "composed_selector_cfg.zig") or
        std.mem.eql(u8, name, "composed_selector_icmp.zig") or
        std.mem.eql(u8, name, "composed_selector_scalar.zig");
    if (!guarded) return;

    const markers = [_][]const u8{
        ".cmp_",        ".test_", ".setb_eax", ".seta_eax", ".sete_eax", ".setg_eax", ".setl_eax", ".setne_eax",
        ".binary_arg_", ".imul_", ".mul_rax",  ".xor_edx",  ".div_arg",  ".add_",     ".sub_",     ".shl_",
        ".shr_",        ".sar_",  ".and_",     ".or_",      ".adc_",     ".sbb_",     ".je ",      ".jne ",
        ".jo ",         ".jc ",   ".jp ",      ".js ",      ".jae ",     ".jle ",
    };
    inline for (markers) |marker| {
        var search_from: usize = 0;
        while (std.mem.indexOfPos(u8, source, search_from, marker)) |index| {
            const statement_start = if (std.mem.lastIndexOfScalar(u8, source[0..index], ';')) |semicolon| semicolon + 1 else 0;
            const statement_end = if (std.mem.indexOfScalarPos(u8, source, index, ';')) |semicolon| semicolon + 1 else source.len;
            const statement = source[statement_start..statement_end];
            if (std.mem.indexOf(u8, statement, "instructions.append") != null or
                std.mem.indexOf(u8, statement, "instructions.appendSlice") != null)
            {
                return error.RawEflagsInstructionAppend;
            }
            search_from = index + marker.len;
        }
    }
}

fn validateStateDataLifecycle(source: []const u8) !void {
    const init_site = ".values = std.StringHashMap(ValueBinding).init(allocator),";
    const deinit_site = "selector.values.deinit();";
    var init_count: usize = 0;
    var deinit_count: usize = 0;
    var lines = std.mem.splitScalar(u8, source, '\n');
    while (lines.next()) |line| {
        if (std.mem.indexOf(u8, line, ".values") == null) continue;
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (std.mem.eql(u8, trimmed, init_site)) {
            init_count += 1;
        } else if (std.mem.eql(u8, trimmed, deinit_site)) {
            deinit_count += 1;
        } else {
            return error.UnapprovedStateDataValuesAccess;
        }
    }
    if (init_count != 1 or deinit_count != 1) return error.StateDataLifecycleInventoryMismatch;
}

fn validateResidualAccumulatorAllowlist(
    allowlist: []const ResidualAllowlistEntry,
    fingerprints: []const FunctionFingerprint,
    name: []const u8,
    source: [:0]const u8,
) !void {
    if (allowlist.len > residual_accumulator_allowlist.len) return error.ResidualAllowlistTooLarge;
    for (allowlist, 0..) |entry, index| {
        for (allowlist[index + 1 ..]) |other| {
            if (entry.operation == other.operation and
                std.mem.eql(u8, entry.source, other.source) and
                std.mem.eql(u8, entry.function, other.function))
            {
                return error.DuplicateResidualAllowlistEntry;
            }
        }
    }

    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    var counts = [_]usize{0} ** residual_accumulator_allowlist.len;
    for (std.meta.tags(DirectOperation)) |operation| {
        var search_from: usize = 0;
        while (std.mem.indexOfPos(u8, source, search_from, operation.pattern())) |operation_offset| {
            const body = functionBodyContaining(bodies, operation_offset) orelse
                return error.ResidualAccumulatorOperationOutsideFunction;
            const index = residualAllowlistIndex(allowlist, name, body.name, operation) orelse
                return error.UnallowlistedResidualAccumulatorOperation;
            counts[index] += 1;
            search_from = operation_offset + operation.pattern().len;
        }
    }

    for (allowlist, 0..) |entry, index| {
        if (!std.mem.eql(u8, entry.source, name)) continue;
        if (counts[index] != entry.expected_count) return error.ResidualAccumulatorOccurrenceMismatch;
        const body = functionBodyNamed(bodies, entry.function) orelse return error.ResidualAllowlistedFunctionMissing;
        try validateFunctionBodyFingerprint(fingerprints, name, body, source);
        if (entry.classification == .approved_pair_rdx_exclusion and entry.future_slice != .pair_rdx_authority) {
            return error.ResidualExclusionMissingFutureSlice;
        }
        if (entry.classification != .approved_pair_rdx_exclusion and entry.future_slice != .none) {
            return error.ResidualNonExclusionOwnsFutureSlice;
        }
        if (entry.structural_role.len == 0) return error.ResidualStructuralRoleMissing;
    }
}

fn collectFunctionBodies(source: [:0]const u8, storage: *[max_function_bodies]FunctionBody) ![]const FunctionBody {
    var count: usize = 0;
    var tokenizer = std.zig.Tokenizer.init(source);
    while (true) {
        const token = tokenizer.next();
        switch (token.tag) {
            .eof => return storage[0..count],
            .invalid, .invalid_periodasterisks => return error.InvalidZigSource,
            .keyword_fn => {},
            else => continue,
        }

        const name_token = tokenizer.next();
        if (name_token.tag != .identifier) continue;
        const function_name = source[name_token.loc.start..name_token.loc.end];
        var paren_depth: usize = 0;
        var bracket_depth: usize = 0;
        var signature_brace_depth: usize = 0;
        var next_brace_is_type = false;
        while (true) {
            const signature_token = tokenizer.next();
            switch (signature_token.tag) {
                .eof => return error.UnclosedFunctionDeclaration,
                .invalid, .invalid_periodasterisks => return error.InvalidZigSource,
                .l_paren => paren_depth += 1,
                .r_paren => {
                    if (paren_depth == 0) return error.MalformedFunctionDeclaration;
                    paren_depth -= 1;
                },
                .l_bracket => bracket_depth += 1,
                .r_bracket => {
                    if (bracket_depth == 0) return error.MalformedFunctionDeclaration;
                    bracket_depth -= 1;
                },
                .keyword_error, .keyword_struct, .keyword_union, .keyword_enum, .keyword_opaque => next_brace_is_type = true,
                .l_brace => {
                    if (paren_depth != 0 or bracket_depth != 0 or signature_brace_depth != 0 or next_brace_is_type) {
                        signature_brace_depth += 1;
                        next_brace_is_type = false;
                        continue;
                    }
                    if (count == storage.len) return error.TooManyFunctionBodies;
                    var body_depth: usize = 1;
                    while (body_depth != 0) {
                        const body_token = tokenizer.next();
                        switch (body_token.tag) {
                            .eof => return error.UnclosedFunctionBody,
                            .invalid, .invalid_periodasterisks => return error.InvalidZigSource,
                            .l_brace => body_depth += 1,
                            .r_brace => {
                                body_depth -= 1;
                                if (body_depth == 0) {
                                    storage[count] = .{
                                        .name = function_name,
                                        .start = signature_token.loc.start,
                                        .end = body_token.loc.end,
                                    };
                                    count += 1;
                                }
                            },
                            else => {},
                        }
                    }
                    break;
                },
                .r_brace => {
                    if (signature_brace_depth == 0) return error.MalformedFunctionDeclaration;
                    signature_brace_depth -= 1;
                },
                .semicolon => if (paren_depth == 0 and bracket_depth == 0 and signature_brace_depth == 0) break,
                else => next_brace_is_type = false,
            }
        }
    }
}

fn functionBodyContaining(bodies: []const FunctionBody, offset: usize) ?FunctionBody {
    for (bodies) |body| {
        if (offset > body.start and offset < body.end) return body;
    }
    return null;
}

fn functionBodyNamed(bodies: []const FunctionBody, name: []const u8) ?FunctionBody {
    for (bodies) |body| {
        if (std.mem.eql(u8, body.name, name)) return body;
    }
    return null;
}

fn validateFunctionBodyFingerprint(
    fingerprints: []const FunctionFingerprint,
    source_name: []const u8,
    body: FunctionBody,
    source: []const u8,
) !void {
    const expected = functionFingerprint(fingerprints, source_name, body.name) orelse
        return error.ResidualFunctionFingerprintMissing;
    if (expected.len != std.crypto.hash.sha2.Sha256.digest_length * 2) return error.MalformedResidualFunctionFingerprint;
    const actual = functionBodyFingerprint(source, body);
    if (!std.mem.eql(u8, &actual, expected)) return error.ResidualFunctionFingerprintMismatch;
}

fn functionBodyFingerprint(source: []const u8, body: FunctionBody) [std.crypto.hash.sha2.Sha256.digest_length * 2]u8 {
    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(source[body.start..body.end], &digest, .{});
    return std.fmt.bytesToHex(digest, .lower);
}

fn fixtureFunctionFingerprint(
    source_name: []const u8,
    function: []const u8,
    source: [:0]const u8,
    storage: *[std.crypto.hash.sha2.Sha256.digest_length * 2]u8,
) !FunctionFingerprint {
    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const body = functionBodyNamed(bodies, function) orelse return error.FixtureFunctionMissing;
    storage.* = functionBodyFingerprint(source, body);
    return .{
        .source = source_name,
        .function = function,
        .body_sha256 = storage,
    };
}

fn validateFunctionFingerprintInventory(source_name: []const u8, source: [:0]const u8) !void {
    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    for (residual_function_fingerprints, 0..) |fingerprint, index| {
        if (!std.mem.eql(u8, fingerprint.source, source_name)) continue;
        for (residual_function_fingerprints[0..index]) |prior| {
            if (std.mem.eql(u8, prior.source, fingerprint.source) and
                std.mem.eql(u8, prior.function, fingerprint.function))
            {
                return error.DuplicateResidualFunctionFingerprint;
            }
        }
        if (!functionHasAllowlistedOperation(source_name, fingerprint.function)) {
            return error.OrphanResidualFunctionFingerprint;
        }
        const body = functionBodyNamed(bodies, fingerprint.function) orelse
            return error.ResidualAllowlistedFunctionMissing;
        try validateFunctionBodyFingerprint(&residual_function_fingerprints, source_name, body, source);
    }
}

fn functionHasAllowlistedOperation(source: []const u8, function: []const u8) bool {
    for (residual_accumulator_allowlist) |entry| {
        if (std.mem.eql(u8, entry.source, source) and std.mem.eql(u8, entry.function, function)) return true;
    }
    for (architectural_exclusion_allowlist) |entry| {
        if (std.mem.eql(u8, entry.source, source) and std.mem.eql(u8, entry.function, function)) return true;
    }
    return false;
}

fn functionFingerprint(
    fingerprints: []const FunctionFingerprint,
    source: []const u8,
    function: []const u8,
) ?[]const u8 {
    var result: ?[]const u8 = null;
    for (fingerprints) |fingerprint| {
        if (!std.mem.eql(u8, fingerprint.source, source) or
            !std.mem.eql(u8, fingerprint.function, function)) continue;
        if (result != null) return null;
        result = fingerprint.body_sha256;
    }
    return result;
}

fn residualAllowlistIndex(
    allowlist: []const ResidualAllowlistEntry,
    source: []const u8,
    function: []const u8,
    operation: DirectOperation,
) ?usize {
    for (allowlist, 0..) |entry, index| {
        if (entry.operation == operation and
            std.mem.eql(u8, entry.source, source) and
            std.mem.eql(u8, entry.function, function)) return index;
    }
    return null;
}

fn validateArchitecturalExclusionAllowlist(name: []const u8, source: [:0]const u8) !void {
    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    var counts = [_]usize{0} ** architectural_exclusion_allowlist.len;
    for (std.meta.tags(ExclusionOperation)) |operation| {
        var search_from: usize = 0;
        while (std.mem.indexOfPos(u8, source, search_from, operation.pattern())) |operation_offset| {
            const body = functionBodyContaining(bodies, operation_offset) orelse
                return error.ArchitecturalExclusionOutsideFunction;
            const index = architecturalExclusionIndex(name, body.name, operation) orelse
                return error.UnallowlistedArchitecturalExclusion;
            counts[index] += 1;
            search_from = operation_offset + operation.pattern().len;
        }
    }

    for (architectural_exclusion_allowlist, 0..) |entry, index| {
        if (!std.mem.eql(u8, entry.source, name)) continue;
        if (counts[index] != entry.expected_count) return error.ArchitecturalExclusionOccurrenceMismatch;
        const body = functionBodyNamed(bodies, entry.function) orelse return error.ArchitecturalExclusionFunctionMissing;
        try validateFunctionBodyFingerprint(&residual_function_fingerprints, name, body, source);
        if (entry.future_slice != .pair_rdx_authority) return error.ArchitecturalExclusionMissingFutureSlice;
        if (entry.structural_role.len == 0) return error.ArchitecturalExclusionStructuralRoleMissing;
    }
}

fn architecturalExclusionIndex(
    source: []const u8,
    function: []const u8,
    operation: ExclusionOperation,
) ?usize {
    for (architectural_exclusion_allowlist, 0..) |entry, index| {
        if (entry.operation == operation and
            std.mem.eql(u8, entry.source, source) and
            std.mem.eql(u8, entry.function, function)) return index;
    }
    return null;
}

fn validateAccumulatorDisplacementPolicies(source: []const u8) !void {
    const call_prefix = "transaction.prepare(";
    var search_from: usize = 0;
    while (std.mem.indexOfPos(u8, source, search_from, call_prefix)) |call_start| {
        const open_paren = call_start + call_prefix.len - 1;
        var depth: usize = 0;
        var call_end: ?usize = null;
        for (source[open_paren..], open_paren..) |byte, index| {
            switch (byte) {
                '(' => depth += 1,
                ')' => {
                    depth -= 1;
                    if (depth == 0) {
                        call_end = index + 1;
                        break;
                    }
                },
                else => {},
            }
        }
        const end = call_end orelse return error.MalformedAccumulatorPrepareCall;
        const call = source[call_start..end];
        // ValueUseTransaction preparation has no accumulator displacement;
        // its subordinate accumulator session carries the explicit policy.
        if (std.mem.eql(u8, call, "transaction.prepare()")) {
            search_from = end;
            continue;
        }
        if (std.mem.indexOf(u8, call, ".spill_live") == null and
            std.mem.indexOf(u8, call, ".spill_source") == null and
            std.mem.indexOf(u8, call, ".scratch_preferred") == null and
            std.mem.indexOf(u8, call, "accumulatorInputDisplacement(") == null and
            std.mem.indexOf(u8, call, "accumulatorLocDisplacement(") == null and
            std.mem.indexOf(u8, call, "accumulatorCastDisplacement(") == null)
        {
            return error.MissingAccumulatorDisplacementPolicy;
        }
        search_from = end;
    }
}

fn classificationIndex(name: []const u8) ?usize {
    for (classified_sources, 0..) |classification, index| {
        if (std.mem.eql(u8, classification.name, name)) return index;
    }
    return null;
}

fn isTestSource(name: []const u8) bool {
    return std.mem.endsWith(u8, name, "_tests.zig");
}

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

test "composed selector source guard confines failure provenance to the memcpy mapper" {
    const accepted: [:0]const u8 =
        "fn inlineMemcpyValueUseDiagnostic() void { " ++
        "_ = transaction.failedRequestIs(destination); " ++
        "_ = transaction.failedRequestIs(source); " ++
        "_ = transaction.failedRequestIs(length); }";
    try validateFailureProvenanceProductionSites("composed_selector_calls.zig", accepted);
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
            accepted ++ " fn successPath() void { _ = transaction.failedRequestIs(source); }",
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
        error.ValueUseAccumulatorCompositionOutsideAllowlist,
        validateAccumulatorCompositionProductionSites(
            "composed_selector_scalar.zig",
            "fn lowerAbsI32() void { _ = transaction.beginAccumulatorSession(); }",
        ),
    );
}

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

test "composed selector source guard accepts the fully classified current tree" {
    try validateCurrentTree(std.testing.allocator);
}
