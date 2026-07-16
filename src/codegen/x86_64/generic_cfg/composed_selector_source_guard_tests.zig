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
const frozen_bypass_inventory_sha256 = "1590b6d3fe37c79ed04829a74271095ab6524f6c1bdc8aaa83ceb6f174b63e54";
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

    .{ .source = "composed_selector_memory.zig", .function = "lowerLoad", .operation = .bind_value_loc, .structural_role = "fixed stack128 aggregate load binding", .classification = .non_accumulator_result_path, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_memory.zig", .function = "lowerStoreFp", .operation = .clobber_accumulator, .structural_role = "FP store address/value transfer temporary", .classification = .internal_temporary, .future_slice = .none, .expected_count = 2 },
    .{ .source = "composed_selector_memory.zig", .function = "lowerGep", .operation = .bind_value_loc, .structural_role = "fixed stack i32 pointer alias binding", .classification = .non_accumulator_result_path, .future_slice = .none, .expected_count = 1 },
    .{ .source = "composed_selector_memory.zig", .function = "lowerI32ElementPointerGep", .operation = .bind_value_loc, .structural_role = "fixed stack i32 element pointer alias binding", .classification = .non_accumulator_result_path, .future_slice = .none, .expected_count = 2 },
    .{ .source = "composed_selector_memory.zig", .function = "lowerBytePointerGep", .operation = .bind_value_loc, .structural_role = "fixed stack/readonly byte pointer alias binding", .classification = .non_accumulator_result_path, .future_slice = .none, .expected_count = 3 },
    .{ .source = "composed_selector_memory.zig", .function = "lowerReadOnlyTableGep", .operation = .bind_value_loc, .structural_role = "fixed readonly-table pointer alias binding", .classification = .non_accumulator_result_path, .future_slice = .none, .expected_count = 1 },
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

    .{ .source = "composed_selector_memory.zig", .function = "lowerLoad", .body_sha256 = "22736bb4f166cedae30f077d2f5a8daeccc8293a83f016401b092b595bbd1526" },
    .{ .source = "composed_selector_memory.zig", .function = "lowerStoreFp", .body_sha256 = "08773e5639dfcc22a932d0a4d702bbe8ff4b3ecb5e398c3b06a9de056fb8a81d" },
    .{ .source = "composed_selector_memory.zig", .function = "lowerGep", .body_sha256 = "27fb6d9820346eb3b3e20aae1a9abb29875a9a6df30f9b793dc016d723dcd203" },
    .{ .source = "composed_selector_memory.zig", .function = "lowerI32ElementPointerGep", .body_sha256 = "63a8f52f1abf750d00286104d79577d6a39cb4c1e50209b740ecd5ac86d523b3" },
    .{ .source = "composed_selector_memory.zig", .function = "lowerBytePointerGep", .body_sha256 = "2b3a2e0da2ecbab1b40062000122d50a0943673d6feb968c22b7c2683ebfe863" },
    .{ .source = "composed_selector_memory.zig", .function = "lowerReadOnlyTableGep", .body_sha256 = "1a62f83a6009ed69f9ef1cc4cd721fb525b4cc5082fc1a73c1f95a27ac33320b" },
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
            try validatePreparedViewLeafDiscipline(source);
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
    if (std.mem.indexOf(u8, source, "pub const PreparedView =") != null or
        std.mem.indexOf(u8, source, "pub fn readPreparedView") != null or
        std.mem.indexOf(u8, source, "pub fn invalidatePreparedViews") != null)
    {
        return error.ValueUsePreparedLocationEscape;
    }
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
}

fn validatePreparedViewLeafDiscipline(source: [:0]const u8) !void {
    if (std.mem.indexOf(u8, source, "readPreparedView(") != null or
        std.mem.indexOf(u8, source, ".PreparedView") != null or
        std.mem.indexOf(u8, source, ".prepared_views") != null)
    {
        return error.ValueUsePreparedLocationEscape;
    }
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
            std.mem.indexOf(u8, function_source, ".consumePreparedView(") == null) continue;
        for (bypass_operations) |operation| {
            if (std.mem.indexOf(u8, function_source, operation) != null)
                return error.ValueUsePreparedLeafRawOperation;
        }
        for (forbidden) |pattern| {
            if (std.mem.indexOf(u8, function_source, pattern) != null)
                return error.ValueUsePreparedLeafRawOperation;
        }
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
        "fn resolveNamedCurrent() void { _ = resolveValue(undefined, undefined); }";
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
}

test "composed selector source guard rejects retained views and raw operations after checked consumption" {
    try validatePreparedViewLeafDiscipline(
        "fn lower() void { const lease = try transaction.preparedView(handle); try transaction.consumePreparedView(lease, &consumer); }",
    );
    try std.testing.expectError(
        error.ValueUsePreparedLeafRawOperation,
        validatePreparedViewLeafDiscipline(
            "fn lower() void { const lease = try transaction.preparedView(handle); try transaction.consumePreparedView(lease, &consumer); _ = selector_state.resolveValue(selector, source); }",
        ),
    );
    try std.testing.expectError(
        error.ValueUsePreparedLeafRawOperation,
        validatePreparedViewLeafDiscipline(
            "fn lower() void { _ = try transaction.preparedView(handle); try selector_state.materializeLocIntoLoc(selector, source, destination); }",
        ),
    );
    try std.testing.expectError(
        error.ValueUsePreparedLocationEscape,
        validatePreparedViewLeafDiscipline(
            "fn lower() void { const retained: Transaction.PreparedView = try transaction.readPreparedView(lease); _ = retained.register; }",
        ),
    );
}

test "composed selector source guard accepts the fully classified current tree" {
    try validateCurrentTree(std.testing.allocator);
}
