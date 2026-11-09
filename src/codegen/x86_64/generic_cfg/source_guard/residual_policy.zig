const std = @import("std");
const model = @import("model.zig");

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
pub fn validateEflagsEmissionAuthority(name: []const u8, source: []const u8) !void {
    const guarded = std.mem.eql(u8, name, "composed_selector_calls.zig") or
        std.mem.eql(u8, name, "composed_selector_cfg.zig") or
        std.mem.eql(u8, name, "composed_selector_icmp.zig") or
        std.mem.eql(u8, name, "composed_selector_scalar.zig");
    if (!guarded) return;

    const markers = [_][]const u8{
        ".cmp_",        ".test_", ".setb_eax", ".seta_eax", ".sete_eax", ".setg_eax", ".setl_eax", ".setne_eax", ".setbe_eax",
        ".binary_arg_", ".imul_", ".mul_rax",  ".xor_edx",  ".div_arg",  ".add_",     ".sub_",     ".shl_",      ".shr_",
        ".sar_",        ".and_",  ".or_",      ".adc_",     ".sbb_",     ".je ",      ".jne ",     ".jo ",       ".jc ",
        ".jp ",         ".js ",   ".jae ",     ".jle ",
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

pub fn validateStateDataLifecycle(source: []const u8) !void {
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

pub fn validateDurableSpillSlotOwnership(
    name: []const u8,
    source: [:0]const u8,
) !void {
    const raw_put = ".spill_slots.put(";
    const raw_assume = ".spill_slots.putAssumeCapacity(";
    if (!std.mem.eql(u8, name, "composed_selector_state.zig")) {
        if (std.mem.indexOf(u8, source, raw_put) != null or
            std.mem.indexOf(u8, source, raw_assume) != null)
        {
            return error.SpillSlotInsertionOutsideOwnershipBoundary;
        }
        if (std.mem.eql(u8, name, "composed_selector_state_data.zig")) {
            if (std.mem.indexOf(u8, source, "spill_slots:") == null) return;
            const required = [_][]const u8{
                "owned_spill_slot_keys: std.array_hash_map.String([]u8),",
                ".owned_spill_slot_keys = .empty,",
                "selector.owned_spill_slot_keys.keys()",
                "selector.allocator.free(owned_key);",
                "selector.owned_spill_slot_keys.deinit(selector.allocator);",
            };
            for (required) |pattern| {
                if (countPattern(source, pattern) != 1)
                    return error.SpillSlotOwnedKeyLifecycleMissing;
            }
        }
        return;
    }
    if (std.mem.indexOf(u8, source, "pub fn allocateSpillSlot") == null) return;

    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const insert_body = functionBodyNamed(bodies, "insertOwnedSpillSlot") orelse
        return error.SpillSlotOwnershipBoundaryMissing;
    const insert = source[insert_body.start..insert_body.end];
    const ordered_insert = [_][]const u8{
        "selector.spill_slots.get(lookup_name) == null",
        "selector.spill_slots.ensureUnusedCapacity(1)",
        "selector.owned_spill_slot_keys.ensureUnusedCapacity(selector.allocator, 1)",
        "selector.allocator.dupe(u8, lookup_name)",
        "selector.owned_spill_slot_keys.putAssumeCapacity(owned_name, owned_name)",
        "selector.spill_slots.putAssumeCapacity(owned_name, assignment)",
    };
    var cursor: usize = 0;
    for (ordered_insert) |pattern| {
        const found = std.mem.indexOfPos(u8, insert, cursor, pattern) orelse
            return error.SpillSlotOwnershipBoundaryMismatch;
        cursor = found + pattern.len;
    }
    if (countPattern(source, raw_put) != 0 or
        countPattern(source, raw_assume) != 2 or
        countPattern(insert, raw_assume) != 1)
    {
        return error.SpillSlotInsertionOutsideOwnershipBoundary;
    }

    const restore_body = functionBodyNamed(bodies, "restoreSpillSlots") orelse
        return error.SpillSlotRollbackOwnershipMissing;
    const restore = source[restore_body.start..restore_body.end];
    const ordered_restore = [_][]const u8{
        "selector.owned_spill_slot_keys.count() > snapshot.owned_keys_len",
        "selector.owned_spill_slot_keys.pop().?",
        "selector.spill_slots.remove(removed.key)",
        "selector.allocator.free(removed.value)",
        "if (snapshot.entries) |entries|",
        "selector.spill_slots.clearRetainingCapacity()",
        "selector.spill_slots.putAssumeCapacity(entry.name, entry.assignment)",
    };
    cursor = 0;
    for (ordered_restore) |pattern| {
        const found = std.mem.indexOfPos(u8, restore, cursor, pattern) orelse
            return error.SpillSlotRollbackOwnershipMissing;
        cursor = found + pattern.len;
    }

    const capture_body = functionBodyNamed(bodies, "captureSpillSlots") orelse
        return error.SpillSlotSnapshotOwnershipMissing;
    const capture = source[capture_body.start..capture_body.end];
    const ordered_capture = [_][]const u8{
        "const owned_keys_len = selector.owned_spill_slot_keys.count()",
        "if (owned_keys_len == selector.spill_slots.count()) return .{ .owned_keys_len = owned_keys_len }",
        "selector.allocator.alloc(SpillSlotSnapshotEntry, selector.spill_slots.count())",
        "selector.spill_slots.iterator()",
        "entries[index] = .{ .name = entry.key_ptr.*, .assignment = entry.value_ptr.* }",
        "return .{ .owned_keys_len = owned_keys_len, .entries = entries }",
    };
    cursor = 0;
    for (ordered_capture) |pattern| {
        const found = std.mem.indexOfPos(u8, capture, cursor, pattern) orelse
            return error.SpillSlotSnapshotOwnershipMissing;
        cursor = found + pattern.len;
    }

    const allocators = [_][]const u8{ "allocateSpillSlot", "allocatePairSpillSlots" };
    for (allocators) |function_name| {
        const body = functionBodyNamed(bodies, function_name) orelse
            return error.SpillSlotOwnershipBoundaryMissing;
        const function_source = source[body.start..body.end];
        if (countPattern(function_source, "insertOwnedSpillSlot(selector, name,") != 1 or
            std.mem.indexOf(u8, function_source, raw_put) != null or
            std.mem.indexOf(u8, function_source, raw_assume) != null)
        {
            return error.SpillSlotOwnershipBoundaryBypassed;
        }
    }
}

pub fn validateResidualAccumulatorAllowlist(
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
    var counts: [residual_accumulator_allowlist.len]usize = @splat(0);
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

pub fn collectFunctionBodies(source: [:0]const u8, storage: *[max_function_bodies]FunctionBody) ![]const FunctionBody {
    var count: usize = 0;
    var tokenizer = std.zig.Tokenizer.init(source);
    while (true) {
        const token = tokenizer.next();
        switch (token.tag) {
            .eof => return storage[0..count],
            .invalid => return error.InvalidZigSource,
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
                .invalid => return error.InvalidZigSource,
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
                            .invalid => return error.InvalidZigSource,
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

pub fn functionBodyContaining(bodies: []const FunctionBody, offset: usize) ?FunctionBody {
    for (bodies) |body| {
        if (offset > body.start and offset < body.end) return body;
    }
    return null;
}

pub fn functionBodyNamed(bodies: []const FunctionBody, name: []const u8) ?FunctionBody {
    for (bodies) |body| {
        if (std.mem.eql(u8, body.name, name)) return body;
    }
    return null;
}

pub fn validateFunctionBodyFingerprint(
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

pub fn functionBodyFingerprint(source: []const u8, body: FunctionBody) [std.crypto.hash.sha2.Sha256.digest_length * 2]u8 {
    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(source[body.start..body.end], &digest, .{});
    return std.fmt.bytesToHex(digest, .lower);
}

pub fn fixtureFunctionFingerprint(
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

pub fn validateFunctionFingerprintInventory(source_name: []const u8, source: [:0]const u8) !void {
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

pub fn functionHasAllowlistedOperation(source: []const u8, function: []const u8) bool {
    for (residual_accumulator_allowlist) |entry| {
        if (std.mem.eql(u8, entry.source, source) and std.mem.eql(u8, entry.function, function)) return true;
    }
    for (architectural_exclusion_allowlist) |entry| {
        if (std.mem.eql(u8, entry.source, source) and std.mem.eql(u8, entry.function, function)) return true;
    }
    return false;
}

pub fn functionFingerprint(
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

pub fn residualAllowlistIndex(
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

pub fn validateArchitecturalExclusionAllowlist(name: []const u8, source: [:0]const u8) !void {
    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    var counts: [architectural_exclusion_allowlist.len]usize = @splat(0);
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

pub fn architecturalExclusionIndex(
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

pub fn validateAccumulatorDisplacementPolicies(source: []const u8) !void {
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

pub fn classificationIndex(name: []const u8) ?usize {
    for (classified_sources, 0..) |classification, index| {
        if (std.mem.eql(u8, classification.name, name)) return index;
    }
    return null;
}

pub fn isTestSource(name: []const u8) bool {
    return std.mem.endsWith(u8, name, "_tests.zig");
}
