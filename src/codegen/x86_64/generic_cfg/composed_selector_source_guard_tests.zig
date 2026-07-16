const std = @import("std");

const source_dir = "src/codegen/x86_64/generic_cfg";
const source_prefix = "composed_selector_";
const source_suffix = ".zig";

const SourceKind = enum {
    authority,
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
    .{ .name = "composed_selector_vector.zig", .kind = .consumer },
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
        const source = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(2 * 1024 * 1024));
        defer allocator.free(source);
        try validateProductionSource(entry.name, source);
    }

    for (seen) |was_seen| {
        if (!was_seen) return error.MissingClassifiedComposedSelectorSource;
    }
}

fn validateProductionSource(name: []const u8, source: []const u8) !void {
    const index = classificationIndex(name) orelse return error.UnclassifiedComposedSelectorSource;
    switch (classified_sources[index].kind) {
        .authority => {},
        .lifecycle => try validateStateDataLifecycle(source),
        .consumer => {
            if (std.mem.indexOf(u8, source, ".values") != null) return error.RawSelectorValuesAccess;
            try validateResidualAccumulatorAllowlist(&residual_accumulator_allowlist, name, source);
            try validateArchitecturalExclusionAllowlist(name, source);
            try validateAccumulatorDisplacementPolicies(source);
            try validateEflagsEmissionAuthority(name, source);
        },
    }
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
    name: []const u8,
    source: []const u8,
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

    var counts = [_]usize{0} ** residual_accumulator_allowlist.len;
    var current_function: ?[]const u8 = null;
    var lines = std.mem.splitScalar(u8, source, '\n');
    while (lines.next()) |line| {
        if (functionName(line)) |function| current_function = function;
        for (std.meta.tags(DirectOperation)) |operation| {
            const occurrences = std.mem.count(u8, line, operation.pattern());
            if (occurrences == 0) continue;
            const function = current_function orelse return error.ResidualAccumulatorOperationOutsideFunction;
            const index = residualAllowlistIndex(allowlist, name, function, operation) orelse
                return error.UnallowlistedResidualAccumulatorOperation;
            counts[index] += occurrences;
        }
    }

    for (allowlist, 0..) |entry, index| {
        if (!std.mem.eql(u8, entry.source, name)) continue;
        if (counts[index] != entry.expected_count) return error.ResidualAccumulatorOccurrenceMismatch;
        if (entry.classification == .approved_pair_rdx_exclusion and entry.future_slice != .pair_rdx_authority) {
            return error.ResidualExclusionMissingFutureSlice;
        }
        if (entry.classification != .approved_pair_rdx_exclusion and entry.future_slice != .none) {
            return error.ResidualNonExclusionOwnsFutureSlice;
        }
        if (entry.structural_role.len == 0) return error.ResidualStructuralRoleMissing;
    }
}

fn functionName(line: []const u8) ?[]const u8 {
    const trimmed = std.mem.trimStart(u8, line, " \t");
    const prefixes = [_][]const u8{ "pub inline fn ", "inline fn ", "pub fn ", "fn " };
    for (prefixes) |prefix| {
        if (!std.mem.startsWith(u8, trimmed, prefix)) continue;
        const rest = trimmed[prefix.len..];
        const end = std.mem.indexOfScalar(u8, rest, '(') orelse return null;
        return rest[0..end];
    }
    return null;
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

fn validateArchitecturalExclusionAllowlist(name: []const u8, source: []const u8) !void {
    var counts = [_]usize{0} ** architectural_exclusion_allowlist.len;
    var current_function: ?[]const u8 = null;
    var lines = std.mem.splitScalar(u8, source, '\n');
    while (lines.next()) |line| {
        if (functionName(line)) |function| current_function = function;
        for (std.meta.tags(ExclusionOperation)) |operation| {
            const occurrences = std.mem.count(u8, line, operation.pattern());
            if (occurrences == 0) continue;
            const function = current_function orelse return error.ArchitecturalExclusionOutsideFunction;
            const index = architecturalExclusionIndex(name, function, operation) orelse
                return error.UnallowlistedArchitecturalExclusion;
            counts[index] += occurrences;
        }
    }

    for (architectural_exclusion_allowlist, 0..) |entry, index| {
        if (!std.mem.eql(u8, entry.source, name)) continue;
        if (counts[index] != entry.expected_count) return error.ArchitecturalExclusionOccurrenceMismatch;
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
    const fixtures = [_][]const u8{
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
    const allowlist = [_]ResidualAllowlistEntry{.{
        .source = "composed_selector_fixture.zig",
        .function = "keep",
        .operation = .clobber_accumulator,
        .structural_role = "fixture temporary",
        .classification = .internal_temporary,
        .future_slice = .none,
        .expected_count = 1,
    }};
    try validateResidualAccumulatorAllowlist(
        &allowlist,
        "composed_selector_fixture.zig",
        "fn keep() void { selector_state.clobberAccumulator(undefined); }",
    );
    try std.testing.expectError(
        error.ResidualAccumulatorOccurrenceMismatch,
        validateResidualAccumulatorAllowlist(
            &allowlist,
            "composed_selector_fixture.zig",
            "fn keep() void { selector_state.clobberAccumulator(undefined); selector_state.clobberAccumulator(undefined); }",
        ),
    );
}

test "composed selector source guard rejects residual accumulator relocation" {
    const allowlist = [_]ResidualAllowlistEntry{.{
        .source = "composed_selector_fixture.zig",
        .function = "keep",
        .operation = .bind_value_loc,
        .structural_role = "fixture alias",
        .classification = .alias_only_binding,
        .future_slice = .none,
        .expected_count = 1,
    }};
    try std.testing.expectError(
        error.UnallowlistedResidualAccumulatorOperation,
        validateResidualAccumulatorAllowlist(
            &allowlist,
            "composed_selector_fixture.zig",
            "fn moved() void { selector_state.bindValueLoc(undefined, \"x\", undefined); }",
        ),
    );
}

test "composed selector source guard rejects residual accumulator reclassification" {
    const allowlist = [_]ResidualAllowlistEntry{.{
        .source = "composed_selector_fixture.zig",
        .function = "keep",
        .operation = .clobber_accumulator,
        .structural_role = "fixture temporary",
        .classification = .internal_temporary,
        .future_slice = .none,
        .expected_count = 1,
    }};
    try std.testing.expectError(
        error.UnallowlistedResidualAccumulatorOperation,
        validateResidualAccumulatorAllowlist(
            &allowlist,
            "composed_selector_fixture.zig",
            "fn keep() void { selector_state.bindEax(undefined, \"x\"); }",
        ),
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

test "composed selector source guard accepts the fully classified current tree" {
    try validateCurrentTree(std.testing.allocator);
}
