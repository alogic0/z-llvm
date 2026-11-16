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
const value_use_planning_model_pub_names = model.value_use_planning_model_pub_names;
const value_use_planning_compatibility_pub_names = model.value_use_planning_compatibility_pub_names;
const value_use_planning_lifetime_pub_names = model.value_use_planning_lifetime_pub_names;
const value_use_planning_semantic_pub_names = model.value_use_planning_semantic_pub_names;
const value_use_planning_physical_pub_names = model.value_use_planning_physical_pub_names;
const value_use_materialization_pub_names = model.value_use_materialization_pub_names;
const value_use_composition_pub_names = model.value_use_composition_pub_names;
const value_use_address_pub_names = model.value_use_address_pub_names;
const value_use_control_pub_names = model.value_use_control_pub_names;
const value_use_scalar_arithmetic_pub_names = model.value_use_scalar_arithmetic_pub_names;
const value_use_scalar_cast_pub_names = model.value_use_scalar_cast_pub_names;
const value_use_scalar_immediate_pub_names = model.value_use_scalar_immediate_pub_names;
const value_use_scalar_named_pub_names = model.value_use_scalar_named_pub_names;
const value_use_scalar_multiply_divide_pub_names = model.value_use_scalar_multiply_divide_pub_names;
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
    const combined_source = try allocator.dupeSentinel(u8, combined.writer.buffered(), 0);
    defer allocator.free(combined_source);
    const calls_source = try std.Io.Dir.cwd().readFileAllocOptions(
        io,
        "src/codegen/x86_64/generic_cfg/value_use/actions/calls.zig",
        allocator,
        .limited(2 * 1024 * 1024),
        .of(u8),
        0,
    );
    defer allocator.free(calls_source);
    const materialization_source = try std.Io.Dir.cwd().readFileAllocOptions(
        io,
        "src/codegen/x86_64/generic_cfg/value_use/materialization.zig",
        allocator,
        .limited(2 * 1024 * 1024),
        .of(u8),
        0,
    );
    defer allocator.free(materialization_source);
    try validateAttachedCallRollbackAuthority(
        calls_source,
        materialization_source,
        combined_source,
    );
    try validateValueUseAuthoritySourceWithVisibility(combined_source, true);
}

pub fn validateAttachedCallRollbackAuthority(
    calls_source: [:0]const u8,
    materialization_source: [:0]const u8,
    combined_source: [:0]const u8,
) !void {
    var calls_body_storage: [max_function_bodies]FunctionBody = undefined;
    const calls_bodies = try collectFunctionBodies(calls_source, &calls_body_storage);
    const execute = functionBodyNamed(calls_bodies, "executeAttachedCallAction") orelse
        return error.ValueUseCallRollbackAuthorityMismatch;
    const execute_source = calls_source[execute.start..execute.end];
    if (countPattern(execute_source, "rollbackInternal") != 0)
        return error.ValueUseCallRollbackAuthorityMismatch;

    var materialization_body_storage: [max_function_bodies]FunctionBody = undefined;
    const materialization_bodies = try collectFunctionBodies(
        materialization_source,
        &materialization_body_storage,
    );
    const materialize = functionBodyNamed(materialization_bodies, "materializeAll") orelse
        return error.ValueUseCallRollbackAuthorityMismatch;
    const materialize_source = materialization_source[materialize.start..materialize.end];
    var combined_body_storage: [max_function_bodies]FunctionBody = undefined;
    const combined_bodies = try collectFunctionBodies(combined_source, &combined_body_storage);
    var structural_call_count: usize = 0;
    for (combined_bodies) |body| {
        const body_call_count = countPattern(
            combined_source[body.start..body.end],
            "executeAttachedCallAction(",
        );
        if (body_call_count == 0) continue;
        if (!std.mem.eql(u8, body.name, "materializeAll") or body_call_count != 1)
            return error.ValueUseCallRollbackAuthorityMismatch;
        structural_call_count += body_call_count;
    }
    if (countPattern(
        materialize_source,
        "errdefer Authority.rollbackInternal(Authority, transaction);",
    ) != 1 or
        countPattern(materialize_source, "executeAttachedCallAction(") != 1 or
        countPattern(materialization_source, "executeAttachedCallAction(") != 1 or
        countPattern(combined_source, "executeAttachedCallAction(") != 2 or
        structural_call_count != 1)
    {
        return error.ValueUseCallRollbackAuthorityMismatch;
    }
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
    if (std.mem.indexOf(u8, source, "@typeName(") != null)
        return error.ValueUseTypeNameDependency;
    if (std.mem.indexOf(u8, source, "*const fn") != null or
        std.mem.indexOf(u8, source, "*fn") != null or
        std.mem.indexOf(u8, source, "vtable") != null)
    {
        return error.ValueUseRuntimeDispatchForbidden;
    }

    const root = "src/codegen/x86_64/generic_cfg/value_use/";
    const is_scoped_names = std.mem.eql(u8, path, root ++ "scoped_names.zig");
    const is_model = std.mem.eql(u8, path, root ++ "model.zig");
    const is_core = std.mem.eql(u8, path, root ++ "core.zig");
    const is_planning = std.mem.eql(u8, path, root ++ "planning.zig");
    const is_planning_model = std.mem.eql(u8, path, root ++ "planning/model.zig");
    const is_planning_compatibility = std.mem.eql(u8, path, root ++ "planning/compatibility.zig");
    const is_planning_lifetime = std.mem.eql(u8, path, root ++ "planning/lifetime_admission.zig");
    const is_planning_semantic = std.mem.eql(u8, path, root ++ "planning/semantic_ordering.zig");
    const is_planning_physical = std.mem.eql(u8, path, root ++ "planning/physical_mapping.zig");
    const is_materialization = std.mem.eql(u8, path, root ++ "materialization.zig");
    const is_composition = std.mem.eql(u8, path, root ++ "composition.zig");
    const is_address = std.mem.eql(u8, path, root ++ "actions/address_memory.zig");
    const is_control = std.mem.eql(u8, path, root ++ "actions/control_compare.zig");
    const is_scalar_arithmetic = std.mem.eql(u8, path, root ++ "actions/scalar_arithmetic.zig");
    const is_scalar_cast = std.mem.eql(u8, path, root ++ "actions/scalar_cast.zig");
    const is_scalar_immediate = std.mem.eql(u8, path, root ++ "actions/scalar_immediate.zig");
    const is_scalar_multiply_divide = std.mem.eql(u8, path, root ++ "actions/scalar_multiply_divide.zig");
    const is_scalar_named = std.mem.eql(u8, path, root ++ "actions/scalar_named.zig");
    const is_calls = std.mem.eql(u8, path, root ++ "actions/calls.zig");
    if (!is_scalar_named and !is_scalar_arithmetic)
        try validateNoFunctionFamilyPredicate(source, error.ValueUseFunctionPredicateForbidden);

    const public_names: []const []const u8 = if (is_scoped_names)
        &.{ "freshNamespace", "Identity", "Pool" }
    else if (is_model)
        &value_use_model_pub_names
    else if (is_core)
        &value_use_core_pub_names
    else if (is_planning)
        &value_use_planning_pub_names
    else if (is_planning_model)
        &value_use_planning_model_pub_names
    else if (is_planning_compatibility)
        &value_use_planning_compatibility_pub_names
    else if (is_planning_lifetime)
        &value_use_planning_lifetime_pub_names
    else if (is_planning_semantic)
        &value_use_planning_semantic_pub_names
    else if (is_planning_physical)
        &value_use_planning_physical_pub_names
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
    else if (is_scalar_multiply_divide)
        &value_use_scalar_multiply_divide_pub_names
    else if (is_scalar_named)
        &value_use_scalar_named_pub_names
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
            countPattern(source, "@import(\"planning.zig\")") != 1 or
            std.mem.indexOf(u8, source, "@import(\"planning/") != null or
            std.mem.indexOf(u8, source, "@import(\"actions/scalar_cast.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"actions/scalar_immediate.zig\")") != null)
        {
            return error.ValueUseImportDagMismatch;
        }
        const lifetime_aliases = [_][]const u8{
            "pub const availabilityForConsumption = planning_module.availabilityForConsumption;",
            "pub const mustSurviveInstruction = planning_module.mustSurviveInstruction;",
            "pub const occupantNeedsPreservation = planning_module.occupantNeedsPreservation;",
        };
        for (lifetime_aliases) |alias| {
            if (countPattern(source, alias) != 1)
                return error.ValueUsePlanningLifetimeAliasMismatch;
        }
        if (std.mem.indexOf(u8, source, "core_availabilityForConsumption") != null or
            std.mem.indexOf(u8, source, "core_mustSurviveInstruction") != null or
            std.mem.indexOf(u8, source, "core_occupantNeedsPreservation") != null)
        {
            return error.ValueUsePlanningLifetimeAliasMismatch;
        }
    } else if (std.mem.indexOf(u8, source, "model.Transaction(") != null) {
        return error.ValueUseProductionInstantiationMismatch;
    }

    if (is_scoped_names) {
        // The selector owns this data-only leaf. It cannot import lowering or
        // any transaction authority, including through an inline import.
        if (countPattern(source, "@import(") != 1 or
            countPattern(source, "const std = @import(\"std\");") != 1)
            return error.ValueUseImportDagMismatch;
    } else if (is_model) {
        try validateValueUseFacadeSurfaceManifest(source);
        if (std.mem.indexOf(u8, source, "@import(\"core.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"planning.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"materialization.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"composition.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"actions/") != null)
            return error.ValueUseImportDagMismatch;
    } else if (is_planning) {
        try validatePlanningFacadeSource(source);
    } else if (is_planning_model or is_planning_compatibility or
        is_planning_lifetime or is_planning_semantic or is_planning_physical)
    {
        try validatePlanningLeafImportDag(path, source);
        try validatePlanningInternalOwnership(path, source);
    } else if (is_materialization or is_composition) {
        if (std.mem.indexOf(u8, source, "@import(\"core.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"planning.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"planning/") != null or
            std.mem.indexOf(u8, source, "@import(\"actions/") != null)
            return error.ValueUseImportDagMismatch;
    } else if (is_address or is_control or is_scalar_cast or is_scalar_immediate or
        is_scalar_multiply_divide or is_scalar_named or is_calls)
    {
        if (std.mem.indexOf(u8, source, "@import(\"../core.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"../planning.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"../planning/") != null or
            std.mem.indexOf(u8, source, "@import(\"../actions/") != null or
            std.mem.indexOf(u8, source, "@import(\"scalar_arithmetic.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"scalar_cast.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"scalar_immediate.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"scalar_multiply_divide.zig\")") != null or
            std.mem.indexOf(u8, source, "@import(\"scalar_named.zig\")") != null or
            std.mem.indexOf(u8, source, "Authority.planning") != null)
            return error.ValueUseImportDagMismatch;
    } else if (is_scalar_arithmetic) {
        try validateScalarArithmeticFacadeSource(source);
    }
    if (is_scalar_named and
        (std.mem.indexOf(u8, source, "function.name") != null or
            std.mem.indexOf(u8, source, "function_name") != null or
            std.mem.indexOf(u8, source, "functionName") != null))
        return error.ValueUseNamedScalarFunctionPredicateForbidden;
    if (is_scalar_named and
        (std.mem.indexOf(u8, source, "transaction.selector.values.get(") != null or
            std.mem.indexOf(u8, source, "resolveForwardValueForUse(") != null))
        return error.ValueUseNamedScalarLifetimeAuthorityBypass;

    if (is_control and countPattern(source, "\n") + 1 > 2000)
        return error.ValueUseControlCompareLineBudgetExceeded;
    if (is_scalar_arithmetic and countPattern(source, "\n") + 1 > 2000)
        return error.ValueUseScalarArithmeticLineBudgetExceeded;
    if ((is_scalar_cast or is_scalar_immediate or is_scalar_multiply_divide or is_scalar_named) and
        countPattern(source, "\n") + 1 > 2000)
        return error.ValueUseScalarArithmeticLineBudgetExceeded;
    if (is_calls and countPattern(source, "\n") + 1 > 1200)
        return error.ValueUseCallsLineBudgetExceeded;
    if ((is_planning_model or is_planning_compatibility or is_planning_lifetime or
        is_planning_semantic or is_planning_physical) and
        countPattern(source, "\n") + 1 > 2000)
    {
        return error.ValueUsePlanningLeafLineBudgetExceeded;
    }
    try validateExactTopLevelPubNames(source, public_names);
}

pub fn validatePlanningFacadeSource(source: []const u8) !void {
    const expected =
        "const planning_model = @import(\"planning/model.zig\");\n" ++
        "const compatibility = @import(\"planning/compatibility.zig\");\n" ++
        "const lifetime_admission = @import(\"planning/lifetime_admission.zig\");\n" ++
        "const semantic_ordering = @import(\"planning/semantic_ordering.zig\");\n" ++
        "const physical_mapping = @import(\"planning/physical_mapping.zig\");\n\n" ++
        "pub const actionOwnsOrderedWrites = semantic_ordering.actionOwnsOrderedWrites;\n" ++
        "pub const argRegForNode = physical_mapping.argRegForNode;\n" ++
        "pub const availabilityForConsumption = lifetime_admission.core_availabilityForConsumption;\n" ++
        "pub const mustSurviveInstruction = lifetime_admission.core_mustSurviveInstruction;\n" ++
        "pub const nodeForArgReg = physical_mapping.nodeForArgReg;\n" ++
        "pub const occupantNeedsPreservation = lifetime_admission.core_occupantNeedsPreservation;\n" ++
        "pub const pairSourceNodes = physical_mapping.pairSourceNodes;\n" ++
        "pub const planEarlyMaterializations = semantic_ordering.planEarlyMaterializations;\n" ++
        "pub const requestDestinationNodes = physical_mapping.requestDestinationNodes;\n" ++
        "pub const requestMappings = physical_mapping.requestMappings;\n" ++
        "pub const scalarSourceNode = physical_mapping.scalarSourceNode;\n" ++
        "pub const seal = physical_mapping.seal;\n" ++
        "pub const validateBindingCompatibility = compatibility.validateBindingCompatibility;\n" ++
        "pub const validateEarlyHome = semantic_ordering.validateEarlyHome;\n" ++
        "pub const validateFormAndDestination = lifetime_admission.validateFormAndDestination;\n" ++
        "pub const validateRequest = lifetime_admission.validateRequest;\n" ++
        "pub const validateRequestAt = lifetime_admission.validateRequestAt;\n" ++
        "pub const validateSemanticOrderTopology = semantic_ordering.validateSemanticOrderTopology;\n";
    if (!std.mem.eql(u8, source, expected))
        return error.ValueUsePlanningFacadeMismatch;
}

pub fn validatePlanningLeafImportDag(path: []const u8, source: []const u8) !void {
    const ExpectedImport = struct { name: []const u8, path: []const u8 };
    const model_imports = [_]ExpectedImport{
        .{ .name = "value_use_model", .path = "../model.zig" },
    };
    const compatibility_imports = [_]ExpectedImport{
        .{ .name = "selector_types", .path = "../../selector_types.zig" },
        .{ .name = "Types", .path = "../model.zig" },
        .{ .name = "planning_model", .path = "model.zig" },
    };
    const lifetime_imports = [_]ExpectedImport{
        .{ .name = "std", .path = "std" },
        .{ .name = "selector_types", .path = "../../selector_types.zig" },
        .{ .name = "selector_state", .path = "../../composed_selector_state.zig" },
        .{ .name = "Types", .path = "../model.zig" },
        .{ .name = "planning_model", .path = "model.zig" },
        .{ .name = "compatibility", .path = "compatibility.zig" },
    };
    const semantic_imports = [_]ExpectedImport{
        .{ .name = "std", .path = "std" },
        .{ .name = "x86_64_types", .path = "../../../types.zig" },
        .{ .name = "selector_types", .path = "../../selector_types.zig" },
        .{ .name = "selector_state", .path = "../../composed_selector_state.zig" },
        .{ .name = "Types", .path = "../model.zig" },
        .{ .name = "planning_model", .path = "model.zig" },
        .{ .name = "compatibility", .path = "compatibility.zig" },
    };
    const physical_imports = [_]ExpectedImport{
        .{ .name = "std", .path = "std" },
        .{ .name = "ir", .path = "../../../../../ir.zig" },
        .{ .name = "x86_64_types", .path = "../../../types.zig" },
        .{ .name = "selector_types", .path = "../../selector_types.zig" },
        .{ .name = "state_data", .path = "../../composed_selector_state_data.zig" },
        .{ .name = "selector_state", .path = "../../composed_selector_state.zig" },
        .{ .name = "Types", .path = "../model.zig" },
        .{ .name = "control_compare", .path = "../actions/control_compare.zig" },
        .{ .name = "planning_model", .path = "model.zig" },
        .{ .name = "compatibility", .path = "compatibility.zig" },
        .{ .name = "lifetime_admission", .path = "lifetime_admission.zig" },
        .{ .name = "semantic_ordering", .path = "semantic_ordering.zig" },
    };
    const expected: []const ExpectedImport =
        if (std.mem.endsWith(u8, path, "/planning/model.zig"))
            &model_imports
        else if (std.mem.endsWith(u8, path, "/planning/compatibility.zig"))
            &compatibility_imports
        else if (std.mem.endsWith(u8, path, "/planning/lifetime_admission.zig"))
            &lifetime_imports
        else if (std.mem.endsWith(u8, path, "/planning/semantic_ordering.zig"))
            &semantic_imports
        else if (std.mem.endsWith(u8, path, "/planning/physical_mapping.zig"))
            &physical_imports
        else
            return error.ValueUseImportDagMismatch;
    if (countPattern(source, "@import(") != expected.len)
        return error.ValueUseImportDagMismatch;
    for (expected) |entry| {
        var buffer: [192]u8 = undefined;
        const declaration = std.fmt.bufPrint(
            &buffer,
            "const {s} = @import(\"{s}\");",
            .{ entry.name, entry.path },
        ) catch return error.ValueUseImportDagMismatch;
        if (countPattern(source, declaration) != 1)
            return error.ValueUseImportDagMismatch;
    }
}

pub fn validatePlanningInternalOwnership(path: []const u8, source: [:0]const u8) !void {
    const is_model = std.mem.endsWith(u8, path, "/planning/model.zig");
    const is_semantic = std.mem.endsWith(u8, path, "/planning/semantic_ordering.zig");
    const is_physical = std.mem.endsWith(u8, path, "/planning/physical_mapping.zig");
    if (!is_model and !is_semantic and !is_physical and
        (std.mem.indexOf(u8, source, "planning_model.Mapping") != null or
            std.mem.indexOf(u8, source, "planning_model.CopyVisitState") != null))
    {
        return error.ValueUsePlanningInternalOwnershipMismatch;
    }
    if (is_physical) {
        if (countPattern(source, "const Mapping = planning_model.Mapping;") != 1 or
            countPattern(source, "fn parallelSourceSnapshots(") != 1 or
            countPattern(source, "transaction.parallel_sources = parallelSourceSnapshots(graph);") != 1 or
            countPattern(source, "CopyVisitState") != 0)
            return error.ValueUsePlanningInternalOwnershipMismatch;
    }
    if (is_semantic) {
        if (countPattern(source, "const Mapping = planning_model.Mapping;") != 1 or
            countPattern(source, "const CopyVisitState = planning_model.CopyVisitState;") != 1)
        {
            return error.ValueUsePlanningInternalOwnershipMismatch;
        }
        const reject_name = "rejectSemanticOrderCycles";
        const visit_name = "visitSemanticOrderNode";
        var reject_buffer: [96]u8 = undefined;
        var visit_buffer: [96]u8 = undefined;
        const reject_declaration = std.fmt.bufPrint(
            &reject_buffer,
            "fn {s}(",
            .{reject_name},
        ) catch return error.ValueUsePlanningInternalOwnershipMismatch;
        const visit_declaration = std.fmt.bufPrint(
            &visit_buffer,
            "fn {s}(",
            .{visit_name},
        ) catch return error.ValueUsePlanningInternalOwnershipMismatch;
        const state_storage = "var states: [Types.max_requests]CopyVisitState = @splat(.unseen);";
        const state_parameter = "states: *[Types.max_requests]CopyVisitState,";
        if (countPattern(source, reject_declaration) != 1 or
            countPattern(source, visit_declaration) != 1 or
            countPattern(source, state_storage) != 1 or
            countPattern(source, state_parameter) != 1 or
            countPattern(source, "CopyVisitState") != 4)
        {
            return error.ValueUsePlanningInternalOwnershipMismatch;
        }
    }
}

pub fn validateScalarArithmeticFacadeSource(source: []const u8) !void {
    const expected =
        "const scalar_cast = @import(\"scalar_cast.zig\");\n" ++
        "const scalar_immediate = @import(\"scalar_immediate.zig\");\n" ++
        "const scalar_multiply_divide = @import(\"scalar_multiply_divide.zig\");\n" ++
        "const scalar_named = @import(\"scalar_named.zig\");\n\n" ++
        "pub const executeAccumulatorScalarCast = scalar_cast.executeAccumulatorScalarCast;\n" ++
        "pub const executeImmediateLhsScalar = scalar_immediate.executeImmediateLhsScalar;\n" ++
        "pub const executeImmediateRhsScalar = scalar_immediate.executeImmediateRhsScalar;\n" ++
        "pub const executeScalarMultiply = scalar_multiply_divide.executeScalarMultiply;\n" ++
        "pub const executeUnsignedQuotient = scalar_multiply_divide.executeUnsignedQuotient;\n" ++
        "pub const executeExactI52Binary = scalar_named.executeExactI52Binary;\n" ++
        "pub const executeNamedScalarBinary = scalar_named.executeNamedScalarBinary;\n" ++
        "pub const executePairLowScalarCast = scalar_cast.executePairLowScalarCast;\n" ++
        "pub const executeSignExtendScratch = scalar_cast.executeSignExtendScratch;\n" ++
        "pub const isAccumulatorScalarCast = scalar_cast.isAccumulatorScalarCast;\n" ++
        "pub const isImmediateLhsScalar = scalar_immediate.isImmediateLhsScalar;\n" ++
        "pub const isImmediateRhsScalar = scalar_immediate.isImmediateRhsScalar;\n" ++
        "pub const isScalarMultiply = scalar_multiply_divide.isScalarMultiply;\n" ++
        "pub const isUnsignedQuotient = scalar_multiply_divide.isUnsignedQuotient;\n" ++
        "pub const isExactI52Binary = scalar_named.isExactI52Binary;\n" ++
        "pub const isNamedScalarBinary = scalar_named.isNamedScalarBinary;\n" ++
        "pub const isPairLowScalarCast = scalar_cast.isPairLowScalarCast;\n" ++
        "pub const isSignExtendScratchCast = scalar_cast.isSignExtendScratchCast;\n" ++
        "pub const validateAccumulatorScalarCastAction = scalar_cast.validateAccumulatorScalarCastAction;\n" ++
        "pub const validateImmediateLhsScalarAction = scalar_immediate.validateImmediateLhsScalarAction;\n" ++
        "pub const validateImmediateRhsScalarAction = scalar_immediate.validateImmediateRhsScalarAction;\n" ++
        "pub const validateScalarMultiplyAction = scalar_multiply_divide.validateScalarMultiplyAction;\n" ++
        "pub const validateUnsignedQuotientAction = scalar_multiply_divide.validateUnsignedQuotientAction;\n" ++
        "pub const validateExactI52BinaryAction = scalar_named.validateExactI52BinaryAction;\n" ++
        "pub const validateNamedScalarBinaryAction = scalar_named.validateNamedScalarBinaryAction;\n" ++
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
    const transaction_source = try std.testing.allocator.dupeSentinel(
        u8,
        source[transaction_body.start..transaction_body.end],
        0,
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
    if (declaration_count != manifest_count or manifest_count != 126)
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
    if (wrapper_count != 49) return error.ValueUseWrapperNotDirectForward;
}

pub fn validateExactTopLevelPubNames(source: []const u8, expected: []const []const u8) !void {
    var seen: [128]bool = @splat(false);
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
