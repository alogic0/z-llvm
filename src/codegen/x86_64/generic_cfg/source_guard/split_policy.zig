const std = @import("std");
const model = @import("model.zig");
const residual = @import("residual_policy.zig");
const authority = @import("authority_policy.zig");

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
const value_use_scalar_arithmetic_pub_names = model.value_use_scalar_arithmetic_pub_names;
const value_use_scalar_cast_pub_names = model.value_use_scalar_cast_pub_names;
const value_use_scalar_immediate_pub_names = model.value_use_scalar_immediate_pub_names;
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
const validateValueUseAuthoritySource = authority.validateValueUseAuthoritySource;
const validateValueUseAuthoritySourceWithVisibility = authority.validateValueUseAuthoritySourceWithVisibility;
const validateScratchCompareIntentSurface = authority.validateScratchCompareIntentSurface;
const validateCurrentHomeEqZeroIntentSurface = authority.validateCurrentHomeEqZeroIntentSurface;
const validateSetccEaxCompareIntentSurface = authority.validateSetccEaxCompareIntentSurface;
const validateCurrentHomeSignBitIntentSurface = authority.validateCurrentHomeSignBitIntentSurface;
const validateI128PairIntentSurface = authority.validateI128PairIntentSurface;
const validateScalarCastIntentSurface = authority.validateScalarCastIntentSurface;
const validateScratchComparePreservationPreamble = authority.validateScratchComparePreservationPreamble;
const validateCurrentHomeEqZeroSequence = authority.validateCurrentHomeEqZeroSequence;
const validateSetccEaxCompareSequence = authority.validateSetccEaxCompareSequence;
const validateCurrentHomeSignBitSequence = authority.validateCurrentHomeSignBitSequence;
const validateI128PairSequence = authority.validateI128PairSequence;
const validateScalarCastSequence = authority.validateScalarCastSequence;
const validateDurableActionIdentityOwnership = authority.validateDurableActionIdentityOwnership;
pub fn validateValueUseFacadeSource(source: []const u8) !void {
    const expected =
        "const core = @import(\"value_use/core.zig\");\n\n" ++
        "pub const ValueUseTransaction = core.ValueUseTransaction;\n";
    if (!std.mem.eql(u8, source, expected)) return error.ValueUseFacadeManifestMismatch;
}

pub fn validateSplitValueUseTree(allocator: std.mem.Allocator) !void {
    const io = std.testing.io;
    var combined: std.Io.Writer.Allocating = .init(allocator);
    defer combined.deinit();

    for (value_use_leaf_paths) |path| {
        const source = try std.Io.Dir.cwd().readFileAllocOptions(
            io,
            path,
            allocator,
            .limited(2 * 1024 * 1024),
            .of(u8),
            0,
        );
        defer allocator.free(source);
        try validateValueUseLeaf(path, source);
        try appendNormalizedValueUseSource(&combined.writer, source);
        try combined.writer.writeByte('\n');
    }
    const combined_source = try allocator.dupeZ(u8, combined.writer.buffered());
    defer allocator.free(combined_source);
    try validateValueUseAuthoritySourceWithVisibility(combined_source, true);
}

pub fn appendNormalizedValueUseSource(writer: *std.Io.Writer, source: []const u8) !void {
    const rewritten = [_]struct { from: []const u8, to: []const u8 }{
        .{
            .from = "transaction.prepared_views[source_index] = try Authority.materialization.buildPreparedRecord(Authority, transaction, source_index);",
            .to = "transaction.prepared_views[source_index] = try transaction.buildPreparedRecord(source_index);",
        },
        .{ .from = "buildPreparedRecord(Authority, transaction, ", .to = "buildPreparedRecord(" },
    };
    const removed = [_][]const u8{
        "Authority, ",
        "Authority.planning.",
        "Authority.materialization.",
        "Authority.composition.",
        "Authority.control_compare.",
        "planning_module.",
        "materialization_module.",
        "composition_module.",
        "control_compare_module.",
        "scalar_arithmetic_module.",
        "address_memory.",
        "control_compare.",
        "scalar_arithmetic.",
        "scalar_cast.",
        "scalar_immediate.",
        "materialization.",
        "composition.",
        "planning.",
        "calls.",
        "model.",
    };
    var cursor: usize = 0;
    while (cursor < source.len) {
        var matched = false;
        for (rewritten) |replacement| {
            if (std.mem.startsWith(u8, source[cursor..], replacement.from)) {
                try writer.writeAll(replacement.to);
                cursor += replacement.from.len;
                matched = true;
                break;
            }
        }
        if (matched) continue;
        for (removed) |pattern| {
            if (std.mem.startsWith(u8, source[cursor..], pattern)) {
                cursor += pattern.len;
                matched = true;
                break;
            }
        }
        if (matched) continue;
        try writer.writeByte(source[cursor]);
        cursor += 1;
    }
}

pub fn validateValueUseLeaf(path: []const u8, source: [:0]const u8) !void {
    try validateNoFunctionFamilyPredicate(source, error.ValueUseFunctionPredicateForbidden);
    if (std.mem.indexOf(u8, source, "@typeName(") != null)
        return error.ValueUseTypeNameDependency;
    if (std.mem.indexOf(u8, source, "*const fn") != null or
        std.mem.indexOf(u8, source, "*fn") != null or
        std.mem.indexOf(u8, source, "vtable") != null)
    {
        return error.ValueUseRuntimeDispatchForbidden;
    }

    const is_model = std.mem.endsWith(u8, path, "/model.zig");
    const is_core = std.mem.endsWith(u8, path, "/core.zig");
    const is_planning = std.mem.endsWith(u8, path, "/planning.zig");
    const is_materialization = std.mem.endsWith(u8, path, "/materialization.zig");
    const is_composition = std.mem.endsWith(u8, path, "/composition.zig");
    const is_address = std.mem.endsWith(u8, path, "/actions/address_memory.zig");
    const is_control = std.mem.endsWith(u8, path, "/actions/control_compare.zig");
    const is_scalar_arithmetic = std.mem.endsWith(u8, path, "/actions/scalar_arithmetic.zig");
    const is_scalar_cast = std.mem.endsWith(u8, path, "/actions/scalar_cast.zig");
    const is_scalar_immediate = std.mem.endsWith(u8, path, "/actions/scalar_immediate.zig");
    const is_calls = std.mem.endsWith(u8, path, "/actions/calls.zig");

    const public_names: []const []const u8 = if (is_model)
        &value_use_model_pub_names
    else if (is_core)
        &value_use_core_pub_names
    else if (is_planning)
        &value_use_planning_pub_names
    else if (is_materialization)
        &value_use_materialization_pub_names
    else if (is_composition)
        &value_use_composition_pub_names
    else if (is_address)
        &value_use_address_pub_names
    else if (is_control)
        &value_use_control_pub_names
    else if (is_scalar_arithmetic)
        &value_use_scalar_arithmetic_pub_names
    else if (is_scalar_cast)
        &value_use_scalar_cast_pub_names
    else if (is_scalar_immediate)
        &value_use_scalar_immediate_pub_names
    else if (is_calls)
        &value_use_calls_pub_names
    else
        return error.ValueUseImportDagMismatch;
    if (is_core) {
        if (countPattern(source, "model.Transaction(Implementation)") != 1)
            return error.ValueUseProductionInstantiationMismatch;
        var body_storage: [max_function_bodies]FunctionBody = undefined;
        const bodies = try collectFunctionBodies(source, &body_storage);
        const dispatch = functionBodyNamed(bodies, "executePreparedActionInternal") orelse
            return error.ValueUseExecutionDispatchMismatch;
        if (countPattern(source[dispatch.start..dispatch.end], "switch (action)") != 1)
            return error.ValueUseExecutionDispatchMismatch;
        if (countPattern(source, "@import(\"actions/scalar_arithmetic.zig\")") != 1 or
            std.mem.indexOf(u8, source, "@import(\"actions/scalar_cast.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"actions/scalar_immediate.zig\")") != null)
        {
            return error.ValueUseImportDagMismatch;
        }
    } else if (std.mem.indexOf(u8, source, "model.Transaction(") != null) {
        return error.ValueUseProductionInstantiationMismatch;
    }

    if (is_model) {
        try validateValueUseFacadeSurfaceManifest(source);
        if (std.mem.indexOf(u8, source, "@import(\"core.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"planning.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"materialization.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"composition.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"actions/") != null)
            return error.ValueUseImportDagMismatch;
    } else if (is_planning) {
        if (std.mem.indexOf(u8, source, "@import(\"core.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"materialization.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"composition.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"actions/address_memory.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"actions/calls.zig\")") != null)
            return error.ValueUseImportDagMismatch;
    } else if (is_materialization or is_composition) {
        if (std.mem.indexOf(u8, source, "@import(\"core.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"planning.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"actions/") != null)
            return error.ValueUseImportDagMismatch;
    } else if (is_address or is_control or is_scalar_cast or is_scalar_immediate or is_calls) {
        if (std.mem.indexOf(u8, source, "@import(\"../core.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"../planning.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"../actions/") != null or
            std.mem.indexOf(u8, source, "@import(\"scalar_arithmetic.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"scalar_cast.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"scalar_immediate.zig\")") != null or
            std.mem.indexOf(u8, source, "Authority.planning") != null)
            return error.ValueUseImportDagMismatch;
    } else if (is_scalar_arithmetic) {
        try validateScalarArithmeticFacadeSource(source);
    }

    if (is_control and countPattern(source, "\n") + 1 > 2000)
        return error.ValueUseControlCompareLineBudgetExceeded;
    if (is_scalar_arithmetic and countPattern(source, "\n") + 1 > 2000)
        return error.ValueUseScalarArithmeticLineBudgetExceeded;
    if ((is_scalar_cast or is_scalar_immediate) and countPattern(source, "\n") + 1 > 2000)
        return error.ValueUseScalarArithmeticLineBudgetExceeded;
    try validateExactTopLevelPubNames(source, public_names);
}

pub fn validateScalarArithmeticFacadeSource(source: []const u8) !void {
    const expected =
        "const scalar_cast = @import(\"scalar_cast.zig\");\n" ++
        "const scalar_immediate = @import(\"scalar_immediate.zig\");\n\n" ++
        "pub const executeAccumulatorScalarCast = scalar_cast.executeAccumulatorScalarCast;\n" ++
        "pub const executeImmediateLhsScalar = scalar_immediate.executeImmediateLhsScalar;\n" ++
        "pub const executeImmediateRhsScalar = scalar_immediate.executeImmediateRhsScalar;\n" ++
        "pub const executePairLowScalarCast = scalar_cast.executePairLowScalarCast;\n" ++
        "pub const executeSignExtendScratch = scalar_cast.executeSignExtendScratch;\n" ++
        "pub const isAccumulatorScalarCast = scalar_cast.isAccumulatorScalarCast;\n" ++
        "pub const isImmediateLhsScalar = scalar_immediate.isImmediateLhsScalar;\n" ++
        "pub const isImmediateRhsScalar = scalar_immediate.isImmediateRhsScalar;\n" ++
        "pub const isPairLowScalarCast = scalar_cast.isPairLowScalarCast;\n" ++
        "pub const isSignExtendScratchCast = scalar_cast.isSignExtendScratchCast;\n" ++
        "pub const validateAccumulatorScalarCastAction = scalar_cast.validateAccumulatorScalarCastAction;\n" ++
        "pub const validateImmediateLhsScalarAction = scalar_immediate.validateImmediateLhsScalarAction;\n" ++
        "pub const validateImmediateRhsScalarAction = scalar_immediate.validateImmediateRhsScalarAction;\n" ++
        "pub const validatePairLowScalarCastAction = scalar_cast.validatePairLowScalarCastAction;\n";
    if (!std.mem.eql(u8, source, expected))
        return error.ValueUseScalarArithmeticFacadeMismatch;
}

pub fn validateValueUseFacadeSurfaceManifest(source: [:0]const u8) !void {
    const manifest = try std.Io.Dir.cwd().readFileAllocOptions(
        std.testing.io,
        value_use_facade_manifest_path,
        std.testing.allocator,
        .limited(32 * 1024),
        .of(u8),
        0,
    );
    defer std.testing.allocator.free(manifest);
    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(manifest, &digest, .{});
    const actual = std.fmt.bytesToHex(digest, .lower);
    if (!std.mem.eql(u8, &actual, value_use_facade_manifest_sha256))
        return error.ValueUseFacadeManifestHashMismatch;

    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const transaction_body = functionBodyNamed(bodies, "Transaction") orelse
        return error.ValueUseFacadeManifestMismatch;
    const transaction_source = try std.testing.allocator.dupeZ(
        u8,
        source[transaction_body.start..transaction_body.end],
    );
    defer std.testing.allocator.free(transaction_source);
    try validateValueUseDirectForwardingWrappers(transaction_source);

    var declaration_count: usize = 0;
    var lines = std.mem.splitScalar(u8, transaction_source, '\n');
    while (lines.next()) |line| {
        const prefix = if (std.mem.startsWith(u8, line, "        pub fn "))
            "        pub fn "
        else if (std.mem.startsWith(u8, line, "        pub const "))
            "        pub const "
        else
            continue;
        const rest = line[prefix.len..];
        var name_end: usize = 0;
        while (name_end < rest.len and
            (std.ascii.isAlphanumeric(rest[name_end]) or rest[name_end] == '_'))
        {
            name_end += 1;
        }
        if (name_end == 0) return error.ValueUseFacadeManifestMismatch;
        const name = rest[0..name_end];
        var needle_buffer: [128]u8 = undefined;
        const needle = std.fmt.bufPrint(&needle_buffer, "\n{s}\n", .{name}) catch
            return error.ValueUseFacadeManifestMismatch;
        if (countPattern(manifest, needle) != 1)
            return error.ValueUseFacadeManifestMismatch;
        declaration_count += 1;
    }

    var manifest_count: usize = 0;
    var previous: ?[]const u8 = null;
    var manifest_lines = std.mem.splitScalar(u8, manifest, '\n');
    if (!std.mem.eql(u8, manifest_lines.next() orelse "", "symbol"))
        return error.ValueUseFacadeManifestMismatch;
    while (manifest_lines.next()) |name| {
        if (name.len == 0) continue;
        if (previous) |prior| {
            if (std.mem.order(u8, prior, name) != .lt)
                return error.ValueUseFacadeManifestMismatch;
        }
        previous = name;
        manifest_count += 1;
    }
    if (declaration_count != manifest_count or manifest_count != 107)
        return error.ValueUseFacadeManifestMismatch;
}

pub fn validateValueUseDirectForwardingWrappers(transaction_source: [:0]const u8) !void {
    var wrapper_count: usize = 0;
    var cursor: usize = 0;
    while (std.mem.indexOfPos(u8, transaction_source, cursor, "\n        pub fn ")) |start| {
        const open = std.mem.indexOfPos(u8, transaction_source, start, "{") orelse
            return error.ValueUseWrapperNotDirectForward;
        const close = std.mem.indexOfPos(u8, transaction_source, open, "}") orelse
            return error.ValueUseWrapperNotDirectForward;
        const implementation = std.mem.trim(u8, transaction_source[open + 1 .. close], " \t\r\n");
        if (!std.mem.startsWith(u8, implementation, "return Impl.") or
            countPattern(implementation, ";") != 1 or
            std.mem.indexOf(u8, implementation, " if ") != null or
            std.mem.indexOf(u8, implementation, "defer") != null or
            std.mem.indexOf(u8, implementation, "catch") != null)
        {
            return error.ValueUseWrapperNotDirectForward;
        }
        wrapper_count += 1;
        cursor = close + 1;
    }
    if (wrapper_count != 43) return error.ValueUseWrapperNotDirectForward;
}

pub fn validateExactTopLevelPubNames(source: []const u8, expected: []const []const u8) !void {
    var seen = [_]bool{false} ** 128;
    if (expected.len > seen.len) return error.ValueUseTechnicalPubBudgetMismatch;
    var lines = std.mem.splitScalar(u8, source, '\n');
    while (lines.next()) |line| {
        const prefix = if (std.mem.startsWith(u8, line, "pub fn "))
            "pub fn "
        else if (std.mem.startsWith(u8, line, "pub const "))
            "pub const "
        else
            continue;
        const rest = line[prefix.len..];
        var name_end: usize = 0;
        while (name_end < rest.len and
            (std.ascii.isAlphanumeric(rest[name_end]) or rest[name_end] == '_'))
        {
            name_end += 1;
        }
        if (name_end == 0) return error.ValueUseTechnicalPubBudgetMismatch;
        const name = rest[0..name_end];
        var found = false;
        for (expected, 0..) |expected_name, index| {
            if (!std.mem.eql(u8, name, expected_name)) continue;
            if (seen[index]) return error.ValueUseTechnicalPubBudgetMismatch;
            seen[index] = true;
            found = true;
            break;
        }
        if (!found) return error.ValueUseTechnicalPubBudgetMismatch;
    }
    for (seen[0..expected.len]) |was_seen| {
        if (!was_seen) return error.ValueUseTechnicalPubBudgetMismatch;
    }
}
