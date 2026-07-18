const std = @import("std");
const model = @import("model.zig");
const residual = @import("residual_policy.zig");
const authority = @import("authority_policy.zig");
const consumers = @import("consumer_policy.zig");
const split = @import("split_policy.zig");

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
const validateDurableSpillSlotOwnership = residual.validateDurableSpillSlotOwnership;
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
const validateScratchComparePreservationPreamble = authority.validateScratchComparePreservationPreamble;
const validateCurrentHomeEqZeroSequence = authority.validateCurrentHomeEqZeroSequence;
const validateSetccEaxCompareSequence = authority.validateSetccEaxCompareSequence;
const validateCurrentHomeSignBitSequence = authority.validateCurrentHomeSignBitSequence;
const validateI128PairSequence = authority.validateI128PairSequence;
const validateDurableActionIdentityOwnership = authority.validateDurableActionIdentityOwnership;
const validatePreparedViewLeafDiscipline = consumers.validatePreparedViewLeafDiscipline;
const validateScratchCompareProductionSites = consumers.validateScratchCompareProductionSites;
const validateCurrentHomeEqZeroProductionSites = consumers.validateCurrentHomeEqZeroProductionSites;
const validateSetccEaxCompareProductionSites = consumers.validateSetccEaxCompareProductionSites;
const validateCurrentHomeSignBitProductionSites = consumers.validateCurrentHomeSignBitProductionSites;
const validateI128PairProductionSites = consumers.validateI128PairProductionSites;
const validateLoadDiagnosticMappingProductionSites = consumers.validateLoadDiagnosticMappingProductionSites;
const validateDormantLoadActionProductionSites = consumers.validateDormantLoadActionProductionSites;
const validateAccumulatorCompositionProductionSites = consumers.validateAccumulatorCompositionProductionSites;
const validateFailureProvenanceProductionSites = consumers.validateFailureProvenanceProductionSites;
const validateMemcpyActionProductionSites = consumers.validateMemcpyActionProductionSites;
const validateSwitchActionProductionSites = consumers.validateSwitchActionProductionSites;
const validateBranchActionProductionSites = consumers.validateBranchActionProductionSites;
const validateStoreActionProductionSites = consumers.validateStoreActionProductionSites;
const validateValueUseFacadeSource = split.validateValueUseFacadeSource;
const validateSplitValueUseTree = split.validateSplitValueUseTree;
const appendNormalizedValueUseSource = split.appendNormalizedValueUseSource;
const validateValueUseLeaf = split.validateValueUseLeaf;
const validateValueUseFacadeSurfaceManifest = split.validateValueUseFacadeSurfaceManifest;
const validateValueUseDirectForwardingWrappers = split.validateValueUseDirectForwardingWrappers;
const validateExactTopLevelPubNames = split.validateExactTopLevelPubNames;
pub fn validateCurrentTree(allocator: std.mem.Allocator) !void {
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
    try validateSplitValueUseTree(allocator);
}

pub fn validateProductionSource(name: []const u8, source: [:0]const u8) !void {
    const index = classificationIndex(name) orelse return error.UnclassifiedComposedSelectorSource;
    try validateDurableSpillSlotOwnership(name, source);
    switch (classified_sources[index].kind) {
        .authority => try validateAddressDependencyStateAuthority(source),
        .address_dependency_domain => try validateAddressDependencyDomainSource(source),
        .value_use_authority => try validateValueUseFacadeSource(source),
        .lifecycle => try validateStateDataLifecycle(source),
        .consumer => {
            if (std.mem.indexOf(u8, source, "@import(\"value_use/") != null or
                std.mem.indexOf(u8, source, "@import(\"./value_use/") != null)
            {
                return error.ValueUseProductionInternalImport;
            }
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

pub fn validateAddressDependencyStateAuthority(source: [:0]const u8) !void {
    var body_storage: [max_function_bodies]FunctionBody = undefined;
    const bodies = try collectFunctionBodies(source, &body_storage);
    const body = functionBodyNamed(bodies, "valueIsLiveAfterCurrent") orelse
        return error.AddressDependencyLivenessAuthorityMissing;
    const liveness_body = source[body.start..body.end];
    if (std.mem.indexOf(u8, liveness_body, "stack_i32_ptr") != null)
        return error.StackPointerLivenessSpecialCaseReintroduced;
}

pub fn validateAddressDependencyDomainSource(source: [:0]const u8) !void {
    try validateNoFunctionFamilyPredicate(source, error.AddressDependencyFunctionPredicateForbidden);
}

pub fn validateFrozenBypassInventoryHash(inventory: []const u8) !void {
    var digest: [std.crypto.hash.sha2.Sha256.digest_length]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(inventory, &digest, .{});
    const actual = std.fmt.bytesToHex(digest, .lower);
    if (!std.mem.eql(u8, &actual, frozen_bypass_inventory_sha256))
        return error.FrozenBypassInventoryHashMismatch;
}

pub fn validateFrozenBypassInventoryForSource(
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
