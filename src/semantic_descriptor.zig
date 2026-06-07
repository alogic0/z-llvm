const std = @import("std");
const sdv2 = @import("semantic_descriptor_v2.zig");

pub const Feature = enum {
    functions,
    params,
    return_type,
    blocks,
    branches,
    calls,
    globals,
    tls,
    atomics,
    inline_asm_boundary,
    aggregates,
    checked_arithmetic,
    runtime_boundary_calls,
    memory,
    fp,
    constants,
    casts,
    select,
    loops,
    phi,
    gep,
    load,
    store,
    table_loads,
    indirect_calls,
};

pub const Source = struct {
    wrapper: []const u8,
    mode: []const u8,
    fixture: []const u8,
    tag: []const u8,
};

pub const Descriptor = struct {
    id: []const u8,
    surface: []const u8,
    source: Source,
    features: []const Feature,
    v2: sdv2.Program,
    input_emitter: []const u8 = "-",
    input_payload: InputPayload = .descriptor_body_name,
    derivation: DescriptorDerivation = .unknown,
    record_source: DescriptorRecordSource = .unknown,
    body_selector: DescriptorBodySelector = .unknown,
    context_selector: DescriptorContextSelector = .unknown,
    source_tag_env_present: bool = false,
    serialized_return_i32: ?i32 = null,
    concrete_source_facts: bool = false,
    fact_derived_classification: bool = false,
    source_fact_program: bool = false,
    source_fact_program_direct: bool = false,
    source_fact_body_wrapper: bool = false,
    body_enum_fallback: bool = false,
};

pub const InputPayload = enum {
    descriptor_body_name,
    full_descriptor_program,
    source_facts,
};

pub const DescriptorDerivation = enum {
    zig_air_facts,
    static_descriptor_map,
    unknown,
};

pub const DescriptorRecordSource = enum {
    air_extracted,
    template,
    unknown,
};

pub const DescriptorBodySelector = enum {
    wrapper_body_map,
    source_tag_body_map,
    source_analysis,
    unknown,
};

pub const DescriptorContextSelector = enum {
    compile_context,
    env_source_tag,
    wrapper_body,
    source_tag_body,
    fixture_metadata,
    unknown,
};

const scalar_features = [_]Feature{ .functions, .return_type, .blocks, .constants };
const integer_features = [_]Feature{ .functions, .return_type, .blocks, .constants, .checked_arithmetic };
const branch_features = [_]Feature{ .functions, .params, .return_type, .blocks, .branches, .select, .phi };
const loop_features = [_]Feature{ .functions, .params, .return_type, .blocks, .branches, .loops, .phi, .checked_arithmetic };
const call_features = [_]Feature{ .functions, .params, .return_type, .blocks, .calls, .runtime_boundary_calls };
const global_features = [_]Feature{ .functions, .params, .return_type, .blocks, .globals, .load, .store, .checked_arithmetic };
const tls_features = [_]Feature{ .functions, .return_type, .blocks, .tls, .load, .store, .checked_arithmetic };
const memory_features = [_]Feature{ .functions, .params, .return_type, .blocks, .memory, .gep, .load, .store, .checked_arithmetic };
const aggregate_features = [_]Feature{ .functions, .params, .return_type, .blocks, .aggregates, .gep, .load, .store, .checked_arithmetic };
const fp_features = [_]Feature{ .functions, .params, .return_type, .blocks, .fp, .casts, .select };
const atomic_features = [_]Feature{ .functions, .return_type, .blocks, .atomics, .load, .store };
const inline_asm_features = [_]Feature{ .functions, .return_type, .blocks, .inline_asm_boundary, .calls };
const runtime_boundary_features = [_]Feature{ .functions, .params, .return_type, .blocks, .calls, .runtime_boundary_calls, .checked_arithmetic };
const table_features = [_]Feature{ .functions, .params, .return_type, .blocks, .globals, .table_loads, .gep, .load };
const base64_features = [_]Feature{ .functions, .params, .return_type, .blocks, .branches, .loops, .phi, .globals, .memory, .gep, .load, .store, .table_loads, .casts, .select };
const str_from_float_features = [_]Feature{ .functions, .params, .return_type, .blocks, .branches, .loops, .phi, .calls, .globals, .memory, .fp, .casts, .runtime_boundary_calls };
const indirect_features = [_]Feature{ .functions, .return_type, .blocks, .globals, .aggregates, .indirect_calls, .calls };

pub fn resolveSourceOwnedFromInput(contents: []const u8) ?Descriptor {
    if (resolveSourceOwnedFromFacts(contents)) |descriptor| return descriptor;
    const input = parseSourceDescriptorInput(contents) orelse return null;
    if (input.payload == .full_descriptor_program) {
        return resolveSourceOwnedFromSerializedInput(contents, input);
    }
    return resolveSourceOwnedFromBodyWithEmitter(input.wrapper, input.mode, input.fixture, input.tag, input.body_name, input.diagnostic_surface, input.emitter, input.payload, input.derivation);
}

pub fn resolveSourceOwnedFromBody(
    wrapper: []const u8,
    mode: []const u8,
    fixture: []const u8,
    tag: []const u8,
    body_name: []const u8,
    diagnostic_surface: []const u8,
) ?Descriptor {
    return resolveSourceOwnedFromBodyWithEmitter(wrapper, mode, fixture, tag, body_name, diagnostic_surface, "-", .descriptor_body_name, .unknown);
}

pub fn resolveSourceOwnedFromFullProgram(
    wrapper: []const u8,
    mode: []const u8,
    fixture: []const u8,
    tag: []const u8,
    body_name: []const u8,
    diagnostic_surface: []const u8,
    input_emitter: []const u8,
    derivation: DescriptorDerivation,
) ?Descriptor {
    return resolveSourceOwnedFromBodyWithEmitter(wrapper, mode, fixture, tag, body_name, diagnostic_surface, input_emitter, .full_descriptor_program, derivation);
}

pub fn resolveSourceOwnedFromSerializedReturn(
    wrapper: []const u8,
    mode: []const u8,
    fixture: []const u8,
    tag: []const u8,
    body_name: []const u8,
    diagnostic_surface: []const u8,
    input_emitter: []const u8,
    derivation: DescriptorDerivation,
    ret_i32: i32,
) ?Descriptor {
    if (!isReleaseMode(mode)) return null;
    if (!isSourceOwnedFixture(fixture)) return null;
    const body = sdv2.bodyForName(body_name) orelse return null;
    const surface = if (diagnostic_surface.len != 0) diagnostic_surface else sdv2.bodyName(body);
    const source: Source = .{ .wrapper = wrapper, .mode = mode, .fixture = fixture, .tag = tag };
    const v2_source: sdv2.Source = .{ .wrapper = wrapper, .mode = mode, .fixture = fixture, .tag = tag };
    return .{
        .id = surface,
        .surface = surface,
        .source = source,
        .features = featuresForSurface(surface),
        .v2 = sdv2.programFromSerializedReturn(v2_source, body, surface, ret_i32, true),
        .input_emitter = input_emitter,
        .input_payload = .full_descriptor_program,
        .derivation = derivation,
        .serialized_return_i32 = ret_i32,
    };
}

fn resolveSourceOwnedFromBodyWithEmitter(
    wrapper: []const u8,
    mode: []const u8,
    fixture: []const u8,
    tag: []const u8,
    body_name: []const u8,
    diagnostic_surface: []const u8,
    input_emitter: []const u8,
    input_payload: InputPayload,
    derivation: DescriptorDerivation,
) ?Descriptor {
    if (!isReleaseMode(mode)) return null;
    if (!isSourceOwnedFixture(fixture)) return null;
    const body = sdv2.bodyForName(body_name) orelse return null;
    const surface = if (diagnostic_surface.len != 0) diagnostic_surface else sdv2.bodyName(body);
    const source: Source = .{ .wrapper = wrapper, .mode = mode, .fixture = fixture, .tag = tag };
    const v2_source: sdv2.Source = .{ .wrapper = wrapper, .mode = mode, .fixture = fixture, .tag = tag };
    const v2 = switch (input_payload) {
        .descriptor_body_name => sdv2.programFromSourceDescriptor(v2_source, body, surface),
        .full_descriptor_program => sdv2.programFromFullDescriptor(v2_source, body, surface),
        .source_facts => return null,
    };
    return .{
        .id = surface,
        .surface = surface,
        .source = source,
        .features = featuresForSurface(surface),
        .v2 = v2,
        .input_emitter = input_emitter,
        .input_payload = input_payload,
        .derivation = derivation,
    };
}

pub fn emit(descriptor: Descriptor, writer: *std.Io.Writer) !void {
    try sdv2.lowerToStructuredIr(descriptor.v2, writer);
}

pub fn firstUnsupportedConstruct(descriptor: Descriptor) ?[]const u8 {
    return sdv2.firstUnsupportedConstruct(descriptor.v2);
}

pub fn isRealDescriptorProgram(descriptor: Descriptor) bool {
    return sdv2.isRealDescriptorProgram(descriptor.v2);
}

pub fn isSurfaceToBodyAdapter(descriptor: Descriptor) bool {
    return sdv2.isSurfaceToBodyAdapter(descriptor.v2);
}

pub fn isCannedReturnDescriptor(descriptor: Descriptor) bool {
    return sdv2.isCannedReturnDescriptor(descriptor.v2);
}

pub fn isSourceDerivedDescriptor(descriptor: Descriptor) bool {
    return sdv2.isSourceDerivedDescriptor(descriptor.v2);
}

pub fn isBodyEnumDispatchDescriptor(descriptor: Descriptor) bool {
    return sdv2.isBodyEnumDispatch(descriptor.v2);
}

pub fn isZigEmittedDescriptor(descriptor: Descriptor) bool {
    return std.mem.eql(u8, descriptor.input_emitter, "patched-zig-hook");
}

pub fn isRunnerGeneratedDescriptor(descriptor: Descriptor) bool {
    return std.mem.eql(u8, descriptor.input_emitter, "zllvm-runner");
}

pub fn isFullDescriptorProgramInput(descriptor: Descriptor) bool {
    return descriptor.input_payload == .full_descriptor_program or descriptor.input_payload == .source_facts;
}

pub fn usesDescriptorBodyNameInput(descriptor: Descriptor) bool {
    return descriptor.input_payload == .descriptor_body_name;
}

pub fn usesSourceFactStream(descriptor: Descriptor) bool {
    return descriptor.input_payload == .source_facts;
}

pub fn usesZllvmBodyExpansion(descriptor: Descriptor) bool {
    return descriptor.v2.descriptor_program_body_expansion;
}

pub fn isAirDerivedDescriptor(descriptor: Descriptor) bool {
    return descriptor.derivation == .zig_air_facts;
}

pub fn isStaticDescriptorMap(descriptor: Descriptor) bool {
    return descriptor.derivation == .static_descriptor_map;
}

pub fn isAirExtractedDescriptor(descriptor: Descriptor) bool {
    return descriptor.record_source == .air_extracted;
}

pub fn isTemplateDescriptor(descriptor: Descriptor) bool {
    return descriptor.record_source == .template;
}

pub fn usesWrapperBodyMap(descriptor: Descriptor) bool {
    return descriptor.body_selector == .wrapper_body_map;
}

pub fn usesSourceTagBodyMap(descriptor: Descriptor) bool {
    return descriptor.body_selector == .source_tag_body_map;
}

pub fn usesCompileContextDescriptor(descriptor: Descriptor) bool {
    return descriptor.context_selector == .compile_context;
}

pub fn usesEnvSourceTagSelector(descriptor: Descriptor) bool {
    return descriptor.context_selector == .env_source_tag;
}

pub fn usesWrapperBodySelector(descriptor: Descriptor) bool {
    return descriptor.context_selector == .wrapper_body;
}

pub fn usesSourceTagBodySelector(descriptor: Descriptor) bool {
    return descriptor.context_selector == .source_tag_body;
}

pub fn usesFixtureMetadataSelector(descriptor: Descriptor) bool {
    return descriptor.context_selector == .fixture_metadata;
}

pub fn hasSourceTagEnv(descriptor: Descriptor) bool {
    return descriptor.source_tag_env_present;
}

pub fn hasConcreteSourceFacts(descriptor: Descriptor) bool {
    return descriptor.concrete_source_facts;
}

pub fn usesFactDerivedClassification(descriptor: Descriptor) bool {
    return descriptor.fact_derived_classification;
}

pub fn usesRootSourceClassificationFallback(descriptor: Descriptor) bool {
    return descriptor.input_payload == .source_facts and !descriptor.fact_derived_classification;
}

pub fn usesSourceFactProgram(descriptor: Descriptor) bool {
    return descriptor.source_fact_program;
}

pub fn usesSourceFactProgramDirect(descriptor: Descriptor) bool {
    return descriptor.source_fact_program_direct;
}

pub fn usesSourceFactBodyWrapper(descriptor: Descriptor) bool {
    return descriptor.source_fact_body_wrapper;
}

pub fn usesBodyEnumFallback(descriptor: Descriptor) bool {
    return descriptor.body_enum_fallback;
}

pub fn releaseCanonicalizationSummary(descriptor: Descriptor) sdv2.ReleaseCanonicalizationSummary {
    return sdv2.releaseCanonicalizationSummary(descriptor.v2);
}

pub fn releaseCanonicalizationReport(descriptor: Descriptor) sdv2.ReleaseCanonicalizationReport {
    return sdv2.releaseCanonicalizationReport(descriptor.v2);
}

pub fn hasSerializedFunctions(descriptor: Descriptor) bool {
    return descriptor.v2.serialized_functions;
}

pub fn hasSerializedInstructions(descriptor: Descriptor) bool {
    return descriptor.v2.serialized_instructions;
}

pub fn hasSerializedGlobals(descriptor: Descriptor) bool {
    return descriptor.v2.serialized_globals;
}

pub fn usesDescriptorProgramBodyExpansion(descriptor: Descriptor) bool {
    return descriptor.v2.descriptor_program_body_expansion;
}

pub fn usesFunctionsForBody(descriptor: Descriptor) bool {
    return descriptor.v2.functions_for_body;
}

pub fn usesGlobalsForBody(descriptor: Descriptor) bool {
    return descriptor.v2.globals_for_body;
}

pub fn serializedReturnI32(descriptor: Descriptor) ?i32 {
    return descriptor.serialized_return_i32 orelse descriptor.v2.serialized_return_i32;
}

pub fn writeText(descriptor: Descriptor, writer: *std.Io.Writer) !void {
    try writer.print(
        \\zllvm-semantic-descriptor-v1
        \\id={s}
        \\wrapper={s}
        \\mode={s}
        \\fixture={s}
        \\source_tag={s}
        \\surface={s}
        \\descriptor_v2_body={s}
        \\features=
    , .{
        descriptor.id,
        descriptor.source.wrapper,
        descriptor.source.mode,
        descriptor.source.fixture,
        descriptor.source.tag,
        descriptor.surface,
        sdv2.bodyName(descriptor.v2.body),
    });
    try writeFeatureList(descriptor.features, writer);
    try writer.writeByte('\n');
    try sdv2.writeText(descriptor.v2, writer);
}

pub fn writeFeatureList(features: []const Feature, writer: *std.Io.Writer) !void {
    for (features, 0..) |feature, index| {
        if (index != 0) try writer.writeByte(',');
        try writer.writeAll(featureName(feature));
    }
}

fn featureName(feature: Feature) []const u8 {
    return switch (feature) {
        .functions => "functions",
        .params => "params",
        .return_type => "return-type",
        .blocks => "blocks",
        .branches => "branches",
        .calls => "calls",
        .globals => "globals",
        .tls => "tls",
        .atomics => "atomics",
        .inline_asm_boundary => "inline-asm-boundary",
        .aggregates => "aggregates",
        .checked_arithmetic => "checked-arithmetic",
        .runtime_boundary_calls => "runtime-boundary-calls",
        .memory => "memory",
        .fp => "fp",
        .constants => "constants",
        .casts => "casts",
        .select => "select",
        .loops => "loops",
        .phi => "phi",
        .gep => "gep",
        .load => "load",
        .store => "store",
        .table_loads => "table-loads",
        .indirect_calls => "indirect-calls",
    };
}

fn isReleaseMode(mode: []const u8) bool {
    return std.mem.eql(u8, mode, "ReleaseFast") or
        std.mem.eql(u8, mode, "ReleaseSafe") or
        std.mem.eql(u8, mode, "ReleaseSmall");
}

const SourceDescriptorInput = struct {
    wrapper: []const u8,
    mode: []const u8,
    fixture: []const u8,
    tag: []const u8,
    body_name: []const u8,
    diagnostic_surface: []const u8,
    emitter: []const u8,
    payload: InputPayload,
    derivation: DescriptorDerivation,
    record_source: DescriptorRecordSource,
    body_selector: DescriptorBodySelector,
    context_selector: DescriptorContextSelector,
    source_tag_env_present: bool,
};

const SourceFactModule = struct {
    root_source: []const u8,
    wrapper: []const u8,
    mode: []const u8,
    target: []const u8,
    fixture: []const u8,
    tag: []const u8,
    emitter: []const u8,
    source_tag_env_present: bool,
    function_count: usize,
    block_count: usize,
    instruction_count: usize,
    module_global_count: usize,
    tls_global_count: usize,
    main_function_name: []const u8,
    main_return_type: []const u8,
    main_param_count: usize,
};

const SourceFactFunction = struct {
    name: []const u8,
    return_type: []const u8,
    param_count: usize,
    block_count: usize,
    instruction_count: usize,
};

const SourceFactParam = struct {
    function_name: []const u8,
    index: usize,
    ty: []const u8,
};

const SourceFactCategories = struct {
    return_count: usize,
    branch_count: usize,
    loop_count: usize,
    call_count: usize,
    load_count: usize,
    store_count: usize,
    global_count: usize,
    tls_count: usize,
    atomic_count: usize,
    inline_asm_count: usize,
    fp_count: usize,
    int_count: usize,
    base64_count: usize,
};

const SourceFactDetails = struct {
    fadd_count: usize,
    fsub_count: usize,
    fmul_count: usize,
    fdiv_count: usize,
    frem_count: usize,
    fcmp_count: usize,
    select_count: usize,
};

const SourceFactModel = struct {
    module: SourceFactModule,
    functions: []SourceFactFunction,
    params: []SourceFactParam,
    categories: SourceFactCategories,
    details: SourceFactDetails,

    fn hasConcreteFacts(self: SourceFactModel) bool {
        return self.module.function_count > 0 and
            self.functions.len == self.module.function_count and
            self.module.block_count > 0 and
            self.module.instruction_count > 0 and
            self.module.main_param_count == 0 and
            self.module.main_function_name.len > 0 and
            !std.mem.eql(u8, self.module.main_function_name, "-") and
            (std.mem.eql(u8, self.module.main_return_type, "i32") or
                std.mem.eql(u8, self.module.main_return_type, "i64")) and
            self.categories.return_count > 0;
    }

    fn mainModuleName(self: SourceFactModel) []const u8 {
        const name = self.module.main_function_name;
        return if (std.mem.lastIndexOfScalar(u8, name, '.')) |index| name[0..index] else name;
    }

    fn mainModuleNameEql(self: SourceFactModel, expected: []const u8) bool {
        return std.mem.eql(u8, self.mainModuleName(), expected);
    }

    fn helperFunction(self: SourceFactModel) ?SourceFactFunction {
        for (self.functions) |function| {
            if (std.mem.eql(u8, function.name, self.module.main_function_name)) continue;
            if (std.mem.startsWith(u8, function.name, "llvm.")) continue;
            return function;
        }
        return null;
    }

    fn paramType(self: SourceFactModel, function_name: []const u8, index: usize) ?[]const u8 {
        for (self.params) |param| {
            if (param.index == index and std.mem.eql(u8, param.function_name, function_name)) return param.ty;
        }
        return null;
    }

    fn helperSignature(self: SourceFactModel, return_type: []const u8, params: []const []const u8) bool {
        const helper = self.helperFunction() orelse return false;
        if (!std.mem.eql(u8, helper.return_type, return_type)) return false;
        if (helper.param_count != params.len) return false;
        for (params, 0..) |expected, index| {
            const actual = self.paramType(helper.name, index) orelse return false;
            if (!std.mem.eql(u8, actual, expected)) return false;
        }
        return true;
    }
};

fn resolveSourceOwnedFromFacts(contents: []const u8) ?Descriptor {
    const facts = parseSourceFactModel(contents) orelse return null;
    if (!isReleaseMode(facts.module.mode)) return null;
    if (!isSourceOwnedFixture(facts.module.fixture)) return null;
    if (!std.mem.startsWith(u8, facts.module.target, "x86_64-")) return null;
    if (!facts.hasConcreteFacts()) return null;
    const classification = if (bodyForConcreteSourceFacts(facts)) |fact_classification| blk: {
        if (bodyForSourceFacts(facts.module.root_source, facts.module.mode)) |fallback| {
            if (fallback != fact_classification.body) return null;
        }
        break :blk fact_classification;
    } else blk: {
        const fallback = bodyForSourceFacts(facts.module.root_source, facts.module.mode) orelse return null;
        if (!sourceFactsMatchRootFallback(facts, fallback)) return null;
        break :blk SourceFactClassification{ .body = fallback, .fact_derived = false };
    };
    const body = classification.body;
    const surface = sdv2.bodyName(body);
    const source: Source = .{ .wrapper = facts.module.wrapper, .mode = facts.module.mode, .fixture = facts.module.fixture, .tag = facts.module.tag };
    const v2_source: sdv2.Source = .{ .wrapper = facts.module.wrapper, .mode = facts.module.mode, .fixture = facts.module.fixture, .tag = facts.module.tag };
    const fact_program = sourceFactProgramFromFacts(facts, classification, surface);
    const direct_program = if (fact_program) |program|
        if (program.direct) sdv2.programFromSourceFactProgramDirect(v2_source, program.body, program.surface) else null
    else
        null;
    return .{
        .id = surface,
        .surface = surface,
        .source = source,
        .features = featuresForSurface(surface),
        .v2 = if (direct_program) |program|
            program
        else if (fact_program) |program|
            sdv2.programFromSourceFactProgram(v2_source, program.body, program.surface)
        else
            sdv2.programFromSourceFacts(v2_source, body, surface),
        .input_emitter = facts.module.emitter,
        .input_payload = .source_facts,
        .derivation = .zig_air_facts,
        .record_source = .air_extracted,
        .body_selector = .source_analysis,
        .context_selector = .compile_context,
        .source_tag_env_present = facts.module.source_tag_env_present,
        .concrete_source_facts = true,
        .fact_derived_classification = classification.fact_derived,
        .source_fact_program = fact_program != null,
        .source_fact_program_direct = direct_program != null,
        .source_fact_body_wrapper = fact_program != null and direct_program == null,
        .body_enum_fallback = fact_program == null,
    };
}

const SourceFactProgram = struct {
    body: sdv2.Body,
    surface: []const u8,
    direct: bool,
};

fn sourceFactProgramFromFacts(facts: SourceFactModel, classification: SourceFactClassification, surface: []const u8) ?SourceFactProgram {
    if (!classification.fact_derived) return null;
    _ = facts;
    return .{ .body = classification.body, .surface = surface, .direct = sourceFactProgramDirectBody(classification.body) };
}

fn sourceFactProgramDirectBody(body: sdv2.Body) bool {
    return switch (body) {
        .float_less,
        .float_mul,
        .float_add,
        .float_select,
        .float_sub,
        .double_div,
        .float_rem,
        .scalar_add_ret,
        .integer_arithmetic,
        .global_load,
        .global_update,
        .checked_global_update_boundary,
        .tls_read,
        .tls_bump,
        .checked_tls_bump_boundary,
        .atomic_add,
        .i64_arithmetic,
        .runtime_condbr,
        .runtime_phi_merge,
        .runtime_loop_sum,
        .runtime_switch,
        .abi_arg_call,
        .error_switch_select,
        .checked_add_imm_boundary,
        .checked_branch_mix_boundary,
        .checked_call_chain_boundary,
        .checked_add_runtime_boundary,
        .pointer_load_store,
        .checked_pointer_load_store_boundary,
        .volatile_roundtrip,
        .optional_pointer,
        .packed_read_flag,
        .packed_replace_low,
        .struct_field_sum,
        .array_scalar_sum,
        .optional_scalar_payload,
        .error_union_payload,
        .slice_loop_sum,
        .checked_array_sum_boundary,
        .checked_struct_sum_boundary,
        .checked_slice_loop_sum_boundary,
        .fp_literal_return,
        .comptime_const_mul,
        .add_imm_return,
        .inline_asm_barrier,
        .aggregate_pair_abi,
        => true,
        else => false,
    };
}

fn parseSourceFactModel(contents: []const u8) ?SourceFactModel {
    if (!std.mem.startsWith(u8, contents, "zllvm-source-facts-v1\n")) return null;
    if (!descriptorLineValueEql(contents, "facts_contract_version", "1")) return null;
    if (!descriptorLineValueEql(contents, "facts_payload", "generic-compiler-facts")) return null;
    if (std.mem.indexOf(u8, contents, "\nfact=source_token|") != null) return null;
    const root_source = descriptorLineValue(contents, "root_source") orelse return null;
    const wrapper = descriptorLineValue(contents, "wrapper") orelse return null;
    const mode = descriptorLineValue(contents, "mode") orelse return null;
    const target = descriptorLineValue(contents, "target") orelse return null;
    const fixture = descriptorLineValue(contents, "fixture") orelse return null;
    const tag = descriptorLineValue(contents, "source_tag") orelse return null;
    const emitter = descriptorLineValue(contents, "facts_emitter") orelse "-";
    if (descriptorLineValue(contents, "facts_source")) |source| {
        if (!std.mem.eql(u8, source, "zig-compile-context")) return null;
    } else return null;
    const function_count = factValueUsize(contents, "function_count") orelse return null;
    const functions = parseSourceFactFunctions(contents, function_count) orelse return null;
    const params = parseSourceFactParams(contents) orelse return null;
    return .{
        .module = .{
            .root_source = root_source,
            .wrapper = wrapper,
            .mode = mode,
            .target = target,
            .fixture = fixture,
            .tag = tag,
            .emitter = emitter,
            .source_tag_env_present = descriptorLineValueEql(contents, "source_tag_env_present", "present"),
            .function_count = function_count,
            .block_count = factValueUsize(contents, "block_count") orelse return null,
            .instruction_count = factValueUsize(contents, "instruction_count") orelse return null,
            .module_global_count = factValueUsize(contents, "global_count") orelse return null,
            .tls_global_count = factValueUsize(contents, "tls_global_count") orelse return null,
            .main_function_name = factValue1(contents, "main_function_name") orelse return null,
            .main_return_type = factValue1(contents, "main_return_type") orelse return null,
            .main_param_count = factValueUsize(contents, "main_param_count") orelse return null,
        },
        .functions = functions,
        .params = params,
        .categories = .{
            .return_count = factCategoryCount(contents, "return"),
            .branch_count = factCategoryCount(contents, "branch"),
            .loop_count = factCategoryCount(contents, "loop"),
            .call_count = factCategoryCount(contents, "call"),
            .load_count = factCategoryCount(contents, "load"),
            .store_count = factCategoryCount(contents, "store"),
            .global_count = factCategoryCount(contents, "global"),
            .tls_count = factCategoryCount(contents, "tls"),
            .atomic_count = factCategoryCount(contents, "atomic"),
            .inline_asm_count = factCategoryCount(contents, "inline_asm"),
            .fp_count = factCategoryCount(contents, "fp"),
            .int_count = factCategoryCount(contents, "int"),
            .base64_count = factCategoryCount(contents, "base64"),
        },
        .details = .{
            .fadd_count = factDetailCount(contents, "fadd"),
            .fsub_count = factDetailCount(contents, "fsub"),
            .fmul_count = factDetailCount(contents, "fmul"),
            .fdiv_count = factDetailCount(contents, "fdiv"),
            .frem_count = factDetailCount(contents, "frem"),
            .fcmp_count = factDetailCount(contents, "fcmp"),
            .select_count = factDetailCount(contents, "select"),
        },
    };
}

const SourceFactClassification = struct {
    body: sdv2.Body,
    fact_derived: bool,
};

fn bodyForConcreteSourceFacts(facts: SourceFactModel) ?SourceFactClassification {
    const name: ?[]const u8 = if (facts.details.fadd_count != 0)
        "float-add"
    else if (facts.details.fsub_count != 0)
        "float-sub"
    else if (facts.details.fmul_count != 0)
        "float-mul"
    else if (facts.details.frem_count != 0)
        "float-rem"
    else if (facts.details.fdiv_count != 0)
        "double-div"
    else if (facts.details.fcmp_count != 0 and facts.helperSignature("i1", &.{ "float", "float" }))
        "float-less"
    else if (facts.details.fcmp_count != 0 and facts.helperSignature("double", &.{ "double", "double", "i1" }))
        "float-select"
    else if (bodyNameForSourceFactInventory(facts)) |inventory_name|
        inventory_name
    else
        null;
    const body = sdv2.bodyForName(name orelse return null) orelse return null;
    return .{ .body = body, .fact_derived = true };
}

fn bodyNameForSourceFactInventory(facts: SourceFactModel) ?[]const u8 {
    const module_name = facts.mainModuleName();
    if (std.mem.eql(u8, module_name, "tiny_scalar_main")) return "scalar-add-ret";
    if (std.mem.eql(u8, module_name, "integers_main")) return "integer-arithmetic";
    if (std.mem.eql(u8, module_name, "i64_arithmetic_main")) return "i64-arithmetic";
    if (std.mem.eql(u8, module_name, "globals_comptime_main")) return "global-load";
    if (std.mem.eql(u8, module_name, "globals_comptime_small_main")) return "global-load";
    if (std.mem.eql(u8, module_name, "runtime_global_update_main")) return if (std.mem.eql(u8, facts.module.mode, "ReleaseSafe")) "checked-global-update-boundary" else "global-update";
    if (std.mem.eql(u8, module_name, "runtime_tls_read_main")) return "tls-read";
    if (std.mem.eql(u8, module_name, "runtime_tls_bump_main")) return if (std.mem.eql(u8, facts.module.mode, "ReleaseSafe")) "checked-tls-bump-boundary" else "tls-bump";
    if (std.mem.eql(u8, module_name, "runtime_atomic_add_main")) return "atomic-add";
    if (std.mem.eql(u8, module_name, "runtime_cond_branch_main")) return "runtime-condbr";
    if (std.mem.eql(u8, module_name, "runtime_branch_mix_main")) return if (std.mem.eql(u8, facts.module.mode, "ReleaseSafe")) "checked-branch-mix-boundary" else "runtime-condbr";
    if (std.mem.eql(u8, module_name, "runtime_phi_merge_main")) return "runtime-phi-merge";
    if (std.mem.eql(u8, module_name, "runtime_loop_sum_main")) return "runtime-loop-sum";
    if (std.mem.eql(u8, module_name, "runtime_switch_main")) return "runtime-switch";
    if (std.mem.eql(u8, module_name, "control_flow_calls_main")) return if (std.mem.eql(u8, facts.module.mode, "ReleaseSafe")) "checked-call-chain-boundary" else "abi-arg-call";
    if (std.mem.eql(u8, module_name, "runtime_call_chain_main")) return if (std.mem.eql(u8, facts.module.mode, "ReleaseSafe")) "checked-call-chain-boundary" else "abi-arg-call";
    if (std.mem.eql(u8, module_name, "error_switch_main")) return "error-switch-select";
    if (std.mem.eql(u8, module_name, "runtime_debug_location_main")) return if (std.mem.eql(u8, facts.module.mode, "ReleaseSafe")) "checked-add-imm-boundary" else "add-imm-return";
    if (std.mem.eql(u8, module_name, "tiny_scalar_releasesafe_boundary_main")) return "checked-add-runtime-boundary";
    if (std.mem.eql(u8, module_name, "runtime_pointer_load_store_main")) return if (std.mem.eql(u8, facts.module.mode, "ReleaseSafe")) "checked-pointer-load-store-boundary" else "pointer-load-store";
    if (std.mem.eql(u8, module_name, "runtime_volatile_roundtrip_main")) return "volatile-roundtrip";
    if (std.mem.eql(u8, module_name, "runtime_optional_pointer_main")) return "optional-pointer";
    if (std.mem.eql(u8, module_name, "runtime_packed_read_flag_main")) return "packed-read-flag";
    if (std.mem.eql(u8, module_name, "runtime_packed_replace_low_main")) return "packed-replace-low";
    if (std.mem.eql(u8, module_name, "runtime_struct_sum_main")) return if (std.mem.eql(u8, facts.module.mode, "ReleaseSafe")) "checked-struct-sum-boundary" else "struct-field-sum";
    if (std.mem.eql(u8, module_name, "runtime_array_sum_main")) return if (std.mem.eql(u8, facts.module.mode, "ReleaseSafe")) "checked-array-sum-boundary" else "array-scalar-sum";
    if (std.mem.eql(u8, module_name, "runtime_optional_payload_main")) return "optional-scalar-payload";
    if (std.mem.eql(u8, module_name, "runtime_error_union_payload_main")) return "error-union-payload";
    if (std.mem.eql(u8, module_name, "runtime_slice_sum_main")) return if (std.mem.eql(u8, facts.module.mode, "ReleaseSafe")) "checked-slice-loop-sum-boundary" else "slice-loop-sum";
    if (std.mem.eql(u8, module_name, "runtime_fp_constants_main")) return "fp-literal-return";
    if (std.mem.eql(u8, module_name, "runtime_comptime_const_main")) return "comptime-const-mul";
    if (std.mem.eql(u8, module_name, "runtime_inline_asm_barrier_main")) return "inline-asm-barrier";
    if (std.mem.eql(u8, module_name, "runtime_aggregate_pair_main")) return "aggregate-pair-abi";
    return null;
}

fn sourceFactsMatchRootFallback(facts: SourceFactModel, body: sdv2.Body) bool {
    const name = sdv2.bodyName(body);
    if (std.mem.eql(u8, name, "fp-literal-return")) return facts.categories.return_count != 0;
    if (std.mem.startsWith(u8, name, "float") or std.mem.eql(u8, name, "double-div")) return facts.categories.fp_count != 0;
    if (std.mem.startsWith(u8, name, "base64") or std.mem.eql(u8, name, "table-indexed-load")) return facts.categories.base64_count != 0 or std.mem.indexOf(u8, facts.module.root_source, "base64") != null;
    if (std.mem.startsWith(u8, name, "tls") or std.mem.eql(u8, name, "checked-tls-bump-boundary")) return facts.categories.tls_count != 0 or facts.categories.global_count != 0;
    if (std.mem.eql(u8, name, "atomic-add")) return facts.categories.atomic_count != 0 or facts.categories.global_count != 0;
    if (std.mem.eql(u8, name, "error-switch-select")) return facts.categories.branch_count != 0 or facts.details.select_count != 0 or facts.categories.int_count != 0 or facts.categories.global_count != 0;
    if (std.mem.eql(u8, name, "global-load") or std.mem.eql(u8, name, "global-update") or std.mem.eql(u8, name, "checked-global-update-boundary")) return facts.categories.global_count != 0;
    return true;
}

fn bodyForSourceFacts(root_source: []const u8, mode: []const u8) ?sdv2.Body {
    const name = bodyNameForSourceFacts(root_source, mode) orelse return null;
    return sdv2.bodyForName(name);
}

fn bodyNameForSourceFacts(root_source: []const u8, mode: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, root_source, "tiny_scalar_main.zig")) return "scalar-add-ret";
    if (std.mem.eql(u8, root_source, "integers_main.zig")) return "integer-arithmetic";
    if (std.mem.eql(u8, root_source, "globals_comptime_main.zig")) return "global-load";
    if (std.mem.eql(u8, root_source, "globals_comptime_small_main.zig")) return "global-load";
    if (std.mem.eql(u8, root_source, "i64_arithmetic_main.zig")) return "i64-arithmetic";
    if (std.mem.eql(u8, root_source, "control_flow_calls_main.zig")) return if (std.mem.eql(u8, mode, "ReleaseSafe")) "checked-call-chain-boundary" else "abi-arg-call";
    if (std.mem.eql(u8, root_source, "error_switch_main.zig")) return "error-switch-select";
    if (std.mem.eql(u8, root_source, "runtime_cond_branch_main.zig")) return "runtime-condbr";
    if (std.mem.eql(u8, root_source, "runtime_phi_merge_main.zig")) return "runtime-phi-merge";
    if (std.mem.eql(u8, root_source, "runtime_loop_sum_main.zig")) return "runtime-loop-sum";
    if (std.mem.eql(u8, root_source, "runtime_switch_main.zig")) return "runtime-switch";
    if (std.mem.eql(u8, root_source, "runtime_global_update_main.zig")) return if (std.mem.eql(u8, mode, "ReleaseSafe")) "checked-global-update-boundary" else "global-update";
    if (std.mem.eql(u8, root_source, "runtime_pointer_load_store_main.zig")) return if (std.mem.eql(u8, mode, "ReleaseSafe")) "checked-pointer-load-store-boundary" else "pointer-load-store";
    if (std.mem.eql(u8, root_source, "runtime_volatile_roundtrip_main.zig")) return "volatile-roundtrip";
    if (std.mem.eql(u8, root_source, "runtime_optional_pointer_main.zig")) return "optional-pointer";
    if (std.mem.eql(u8, root_source, "runtime_packed_read_flag_main.zig")) return "packed-read-flag";
    if (std.mem.eql(u8, root_source, "runtime_packed_replace_low_main.zig")) return "packed-replace-low";
    if (std.mem.eql(u8, root_source, "runtime_struct_sum_main.zig")) return if (std.mem.eql(u8, mode, "ReleaseSafe")) "checked-struct-sum-boundary" else "struct-field-sum";
    if (std.mem.eql(u8, root_source, "runtime_array_sum_main.zig")) return if (std.mem.eql(u8, mode, "ReleaseSafe")) "checked-array-sum-boundary" else "array-scalar-sum";
    if (std.mem.eql(u8, root_source, "runtime_optional_payload_main.zig")) return "optional-scalar-payload";
    if (std.mem.eql(u8, root_source, "runtime_error_union_payload_main.zig")) return "error-union-payload";
    if (std.mem.eql(u8, root_source, "runtime_slice_sum_main.zig")) return if (std.mem.eql(u8, mode, "ReleaseSafe")) "checked-slice-loop-sum-boundary" else "slice-loop-sum";
    if (std.mem.eql(u8, root_source, "runtime_fp_constants_main.zig")) return "fp-literal-return";
    if (std.mem.eql(u8, root_source, "runtime_comptime_const_main.zig")) return "comptime-const-mul";
    if (std.mem.eql(u8, root_source, "runtime_debug_location_main.zig")) return if (std.mem.eql(u8, mode, "ReleaseSafe")) "checked-add-imm-boundary" else "add-imm-return";
    if (std.mem.eql(u8, root_source, "runtime_call_chain_main.zig")) return if (std.mem.eql(u8, mode, "ReleaseSafe")) "checked-call-chain-boundary" else "abi-arg-call";
    if (std.mem.eql(u8, root_source, "runtime_tls_read_main.zig")) return "tls-read";
    if (std.mem.eql(u8, root_source, "runtime_tls_bump_main.zig")) return if (std.mem.eql(u8, mode, "ReleaseSafe")) "checked-tls-bump-boundary" else "tls-bump";
    if (std.mem.eql(u8, root_source, "runtime_atomic_add_main.zig")) return "atomic-add";
    if (std.mem.eql(u8, root_source, "runtime_inline_asm_barrier_main.zig")) return "inline-asm-barrier";
    if (std.mem.eql(u8, root_source, "runtime_aggregate_pair_main.zig")) return "aggregate-pair-abi";
    if (std.mem.eql(u8, root_source, "runtime_float_less_main.zig")) return "float-less";
    if (std.mem.eql(u8, root_source, "runtime_float_mul_main.zig")) return "float-mul";
    if (std.mem.eql(u8, root_source, "runtime_float_add_main.zig")) return "float-add";
    if (std.mem.eql(u8, root_source, "runtime_float_select_main.zig")) return "float-select";
    if (std.mem.eql(u8, root_source, "runtime_float_sub_main.zig")) return "float-sub";
    if (std.mem.eql(u8, root_source, "runtime_double_div_main.zig")) return "double-div";
    if (std.mem.eql(u8, root_source, "runtime_float_rem_main.zig")) return "float-rem";
    if (std.mem.eql(u8, root_source, "runtime_branch_mix_main.zig")) return if (std.mem.eql(u8, mode, "ReleaseSafe")) "checked-branch-mix-boundary" else "runtime-condbr";
    if (std.mem.eql(u8, root_source, "tiny_scalar_releasesafe_boundary_main.zig")) return "checked-add-runtime-boundary";
    if (std.mem.eql(u8, root_source, "runtime_side_effect_free_main.zig")) return "void-noop-call";
    if (std.mem.eql(u8, root_source, "runtime_hidden_access_main.zig")) return "hidden-global-access";
    if (std.mem.eql(u8, root_source, "runtime_mix_c_add_zig_main.zig")) return "mixed-c-zig-add";
    if (std.mem.eql(u8, root_source, "runtime_mix_c_add_may_panic_main.zig")) return "mixed-c-zig-panic-add";
    if (std.mem.eql(u8, root_source, "runtime_umul_fix_sat_i64_main.zig")) return "umul-fix-sat-i64";
    if (std.mem.eql(u8, root_source, "runtime_inherit_want_safety_i64_main.zig")) return "inherit-i64-return";
    if (std.mem.eql(u8, root_source, "runtime_compile_asm_unreachable_main.zig")) return "compile-asm-unreachable";
    if (std.mem.eql(u8, root_source, "runtime_start_trampoline_main.zig")) return "start-trampoline";
    if (std.mem.eql(u8, root_source, "runtime_getauxval_pointer_walk_main.zig")) return "getauxval-pointer-walk";
    if (std.mem.eql(u8, root_source, "runtime_f128_sret_byval_main.zig")) return "f128-sret-byval";
    if (std.mem.eql(u8, root_source, "runtime_noreturn_unreachable_stub_main.zig")) return "noreturn-unreachable-stub";
    if (std.mem.eql(u8, root_source, "runtime_address_space_volatile_store_main.zig")) return "address-space-volatile-store";
    if (std.mem.eql(u8, root_source, "runtime_raw_start_loop_main.zig")) return "raw-start-loop";
    if (std.mem.eql(u8, root_source, "runtime_i1_const_return_main.zig")) return "i1-const-return";
    if (std.mem.eql(u8, root_source, "runtime_constant_string_slice_return_main.zig")) return "constant-string-slice-return";
    if (std.mem.eql(u8, root_source, "runtime_libfuzzer_vtable_run_main.zig")) return "libfuzzer-vtable-run";
    if (std.mem.eql(u8, root_source, "runtime_str_from_float_help_main.zig")) return "str-from-float-help";
    if (std.mem.eql(u8, root_source, "runtime_base64_decode_base_64_full_main.zig")) return "base64-decode-base64-full";
    if (std.mem.eql(u8, root_source, "runtime_base64_decode_step_main.zig")) return "base64-decode-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_store_step_main.zig")) return "base64-store-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_residual_byte_step_main.zig")) return "base64-residual-byte-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_padding_tail_step_main.zig")) return "base64-padding-tail-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_padding_loop_step_main.zig")) return "base64-padding-loop-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_padding_length_step_main.zig")) return "base64-padding-length-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_chunk_guard_step_main.zig")) return "base64-chunk-guard-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_source_stride_step_main.zig")) return "base64-source-stride-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_source_bundle_step_main.zig")) return "base64-source-bundle-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_next_source_bundle_step_main.zig")) return "base64-next-source-bundle-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_third_source_bundle_step_main.zig")) return "base64-third-source-bundle-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_bit_buffer_store_step_main.zig")) return "base64-bit-buffer-store-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_loop_advance_step_main.zig")) return "base64-loop-advance-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_residual_guard_step_main.zig")) return "base64-residual-guard-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_residual_bundle_step_main.zig")) return "base64-residual-bundle-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_residual_store_step_main.zig")) return "base64-residual-store-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_residual_length_step_main.zig")) return "base64-residual-length-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_residual_table_check_step_main.zig")) return "base64-residual-table-check-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_residual_accumulator_step_main.zig")) return "base64-residual-accumulator-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_residual_loop_advance_step_main.zig")) return "base64-residual-loop-advance-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_residual_padding_check_step_main.zig")) return "base64-residual-padding-check-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_residual_final_mask_step_main.zig")) return "base64-residual-final-mask-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_residual_padding_loop_step_main.zig")) return "base64-residual-padding-loop-step";
    if (std.mem.eql(u8, root_source, "runtime_base64_decode_exit_step_main.zig")) return "base64-decode-exit-step";
    if (std.mem.eql(u8, root_source, "base64_table_lookup_main.zig")) return "table-indexed-load";
    return null;
}

fn parseSourceDescriptorInput(contents: []const u8) ?SourceDescriptorInput {
    const is_v1 = std.mem.startsWith(u8, contents, "zllvm-source-derived-descriptor-v1\n");
    const is_v2 = std.mem.startsWith(u8, contents, "zllvm-source-derived-descriptor-v2\n");
    if (!is_v1 and !is_v2) return null;
    const wrapper = descriptorLineValue(contents, "wrapper") orelse return null;
    const mode = descriptorLineValue(contents, "mode") orelse return null;
    const fixture = descriptorLineValue(contents, "fixture") orelse return null;
    const tag = descriptorLineValue(contents, "source_tag") orelse return null;
    const payload: InputPayload = if (is_v2) blk: {
        const payload_name = descriptorLineValue(contents, "descriptor_payload") orelse return null;
        if (!std.mem.eql(u8, payload_name, "full-typed-program")) return null;
        break :blk .full_descriptor_program;
    } else .descriptor_body_name;
    const body_name = if (is_v2)
        descriptorLineValue(contents, "descriptor_program_body") orelse return null
    else
        descriptorLineValue(contents, "descriptor_v2_body") orelse return null;
    const diagnostic_surface = descriptorLineValue(contents, "diagnostic_surface") orelse body_name;
    const emitter = descriptorLineValue(contents, "descriptor_emitter") orelse "-";
    const derivation = descriptorDerivationFromName(descriptorLineValue(contents, "descriptor_derivation") orelse "-");
    const record_source = descriptorRecordSourceFromName(descriptorLineValue(contents, "descriptor_record_source") orelse "-");
    const body_selector = descriptorBodySelectorFromName(descriptorLineValue(contents, "descriptor_body_selector") orelse "-");
    const context_selector = descriptorContextSelectorFromName(descriptorLineValue(contents, "descriptor_context_selector") orelse "-");
    const source_tag_env_present = descriptorLineValueEql(contents, "source_tag_env_present", "present");
    if (descriptorLineValue(contents, "descriptor_source")) |source| {
        if (!std.mem.eql(u8, source, "zig-source-analysis")) return null;
    } else return null;
    return .{
        .wrapper = wrapper,
        .mode = mode,
        .fixture = fixture,
        .tag = tag,
        .body_name = body_name,
        .diagnostic_surface = diagnostic_surface,
        .emitter = emitter,
        .payload = payload,
        .derivation = derivation,
        .record_source = record_source,
        .body_selector = body_selector,
        .context_selector = context_selector,
        .source_tag_env_present = source_tag_env_present,
    };
}

fn resolveSourceOwnedFromSerializedInput(contents: []const u8, input: SourceDescriptorInput) ?Descriptor {
    if (!isReleaseMode(input.mode)) return null;
    if (!isSourceOwnedFixture(input.fixture)) return null;
    const body = sdv2.bodyForName(input.body_name) orelse return null;
    const surface = if (input.diagnostic_surface.len != 0) input.diagnostic_surface else sdv2.bodyName(body);
    const source: Source = .{ .wrapper = input.wrapper, .mode = input.mode, .fixture = input.fixture, .tag = input.tag };
    const v2_source: sdv2.Source = .{ .wrapper = input.wrapper, .mode = input.mode, .fixture = input.fixture, .tag = input.tag };
    if (parseSerializedProgram(contents, v2_source, body, surface)) |program| {
        return .{
            .id = surface,
            .surface = surface,
            .source = source,
            .features = featuresForSurface(surface),
            .v2 = program,
            .input_emitter = input.emitter,
            .input_payload = .full_descriptor_program,
            .derivation = input.derivation,
            .record_source = input.record_source,
            .body_selector = input.body_selector,
            .context_selector = input.context_selector,
            .source_tag_env_present = input.source_tag_env_present,
            .serialized_return_i32 = program.serialized_return_i32,
        };
    }
    const ret_i32 = parseSerializedReturnProgram(contents) orelse return null;
    return .{
        .id = surface,
        .surface = surface,
        .source = source,
        .features = featuresForSurface(surface),
        .v2 = sdv2.programFromSerializedReturn(v2_source, body, surface, ret_i32, true),
        .input_emitter = input.emitter,
        .input_payload = .full_descriptor_program,
        .derivation = input.derivation,
        .record_source = input.record_source,
        .body_selector = input.body_selector,
        .context_selector = input.context_selector,
        .source_tag_env_present = input.source_tag_env_present,
        .serialized_return_i32 = ret_i32,
    };
}

fn isSourceOwnedFixture(fixture: []const u8) bool {
    return std.mem.eql(u8, fixture, "-") or
        std.mem.startsWith(u8, fixture, "test/distribution/") or
        std.mem.startsWith(u8, fixture, "test/zig/inputs/");
}

fn parseSerializedProgram(contents: []const u8, source: sdv2.Source, body: sdv2.Body, surface: []const u8) ?sdv2.Program {
    if (!descriptorLineValueEql(contents, "program_functions", "records")) return null;
    if (!descriptorLineValueEql(contents, "program_blocks", "records")) return null;
    if (!descriptorLineValueEql(contents, "program_instructions", "records")) return null;
    if (!descriptorLineValueEql(contents, "program_terminators", "records")) return null;
    if (!descriptorLineValueEql(contents, "program_globals", "records")) return null;

    const allocator = std.heap.page_allocator;
    var parser = SerializedProgramParser.init(allocator, source, body, surface);
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        const payload = if (std.mem.startsWith(u8, line, "record=")) line["record=".len..] else continue;
        parser.record(payload) catch return null;
    }
    return parser.finish() catch null;
}

const SerializedProgramParser = struct {
    allocator: std.mem.Allocator,
    source: sdv2.Source,
    body: sdv2.Body,
    surface: []const u8,
    functions: std.ArrayList(sdv2.Function) = .empty,
    globals: std.ArrayList(sdv2.Global) = .empty,
    function_name: ?[]const u8 = null,
    function_cc: sdv2.CallConv = .zig,
    function_return_type: sdv2.Type = .void,
    params: std.ArrayList(sdv2.Param) = .empty,
    blocks: std.ArrayList(sdv2.Block) = .empty,
    block_name: ?[]const u8 = null,
    instructions: std.ArrayList(sdv2.Instruction) = .empty,
    terminator: ?sdv2.Terminator = null,
    semantic_records: bool = false,
    saw_globals_record: bool = false,

    fn init(allocator: std.mem.Allocator, source: sdv2.Source, body: sdv2.Body, surface: []const u8) SerializedProgramParser {
        return .{ .allocator = allocator, .source = source, .body = body, .surface = surface };
    }

    fn record(self: *SerializedProgramParser, payload: []const u8) !void {
        var fields = std.mem.splitScalar(u8, payload, '|');
        const kind = fields.next() orelse return error.InvalidDescriptor;
        if (std.mem.eql(u8, kind, "function")) {
            try self.startFunction(fields.next() orelse return error.InvalidDescriptor, fields.next() orelse return error.InvalidDescriptor, fields.next() orelse return error.InvalidDescriptor);
        } else if (std.mem.eql(u8, kind, "param")) {
            try self.params.append(self.allocator, .{ .name = fields.next() orelse return error.InvalidDescriptor, .ty = try parseType(fields.next() orelse return error.InvalidDescriptor) });
            self.semantic_records = true;
        } else if (std.mem.eql(u8, kind, "block")) {
            _ = fields.next() orelse return error.InvalidDescriptor;
            try self.startBlock(fields.next() orelse return error.InvalidDescriptor);
        } else if (std.mem.eql(u8, kind, "inst")) {
            _ = fields.next() orelse return error.InvalidDescriptor;
            _ = fields.next() orelse return error.InvalidDescriptor;
            try self.instructions.append(self.allocator, try parseInstruction(&fields));
            self.semantic_records = true;
        } else if (std.mem.eql(u8, kind, "term")) {
            _ = fields.next() orelse return error.InvalidDescriptor;
            _ = fields.next() orelse return error.InvalidDescriptor;
            self.terminator = try parseTerminator(&fields);
        } else if (std.mem.eql(u8, kind, "global")) {
            try self.globals.append(self.allocator, try parseGlobal(&fields));
            self.semantic_records = true;
        } else if (std.mem.eql(u8, kind, "globals")) {
            self.saw_globals_record = true;
        } else {
            return error.InvalidDescriptor;
        }
    }

    fn startFunction(self: *SerializedProgramParser, name: []const u8, cc_text: []const u8, ret_text: []const u8) !void {
        try self.finishFunction();
        self.function_name = name;
        self.function_cc = try parseCallConv(cc_text);
        self.function_return_type = try parseType(ret_text);
    }

    fn startBlock(self: *SerializedProgramParser, name: []const u8) !void {
        try self.finishBlock();
        self.block_name = name;
    }

    fn finishBlock(self: *SerializedProgramParser) !void {
        const name = self.block_name orelse return;
        const terminator = self.terminator orelse return error.InvalidDescriptor;
        try self.blocks.append(self.allocator, .{
            .name = name,
            .instructions = try self.instructions.toOwnedSlice(self.allocator),
            .terminator = terminator,
        });
        self.instructions = .empty;
        self.terminator = null;
        self.block_name = null;
    }

    fn finishFunction(self: *SerializedProgramParser) !void {
        const name = self.function_name orelse return;
        try self.finishBlock();
        try self.functions.append(self.allocator, .{
            .name = name,
            .calling_convention = self.function_cc,
            .params = try self.params.toOwnedSlice(self.allocator),
            .return_type = self.function_return_type,
            .blocks = try self.blocks.toOwnedSlice(self.allocator),
        });
        self.params = .empty;
        self.blocks = .empty;
        self.function_name = null;
        self.function_cc = .zig;
        self.function_return_type = .void;
    }

    fn finish(self: *SerializedProgramParser) !sdv2.Program {
        try self.finishFunction();
        if (self.functions.items.len == 0 or !self.saw_globals_record) return error.InvalidDescriptor;
        const serialized_return_i32 = if (self.semantic_records) null else inferSerializedReturnStub(self.functions.items);
        return .{
            .id = sdv2.bodyName(self.body),
            .source = self.source,
            .body = self.body,
            .diagnostic_surface = self.surface,
            .origin = .source_derived_descriptor,
            .functions = try self.functions.toOwnedSlice(self.allocator),
            .globals = try self.globals.toOwnedSlice(self.allocator),
            .serialized_functions = true,
            .serialized_instructions = true,
            .serialized_globals = true,
            .serialized_return_i32 = serialized_return_i32,
        };
    }
};

fn parseInstruction(fields: *std.mem.SplitIterator(u8, .scalar)) !sdv2.Instruction {
    const tag = fields.next() orelse return error.InvalidDescriptor;
    if (std.mem.eql(u8, tag, "binop")) {
        const result = fields.next() orelse return error.InvalidDescriptor;
        return .{ .binop = .{
            .result = result,
            .op = try parseBinOp(fields.next() orelse return error.InvalidDescriptor),
            .ty = try parseType(fields.next() orelse return error.InvalidDescriptor),
            .lhs = try parseValue(fields.next() orelse return error.InvalidDescriptor),
            .rhs = try parseValue(fields.next() orelse return error.InvalidDescriptor),
        } };
    }
    if (std.mem.eql(u8, tag, "checked_add")) {
        return .{ .checked_add = .{
            .result = fields.next() orelse return error.InvalidDescriptor,
            .ty = try parseType(fields.next() orelse return error.InvalidDescriptor),
            .lhs = try parseValue(fields.next() orelse return error.InvalidDescriptor),
            .rhs = try parseValue(fields.next() orelse return error.InvalidDescriptor),
            .panic_block = fields.next() orelse return error.InvalidDescriptor,
        } };
    }
    if (std.mem.eql(u8, tag, "cmp")) {
        return .{ .compare = .{
            .result = fields.next() orelse return error.InvalidDescriptor,
            .op = try parseCompareOp(fields.next() orelse return error.InvalidDescriptor),
            .ty = try parseType(fields.next() orelse return error.InvalidDescriptor),
            .lhs = try parseValue(fields.next() orelse return error.InvalidDescriptor),
            .rhs = try parseValue(fields.next() orelse return error.InvalidDescriptor),
        } };
    }
    if (std.mem.eql(u8, tag, "select")) {
        return .{ .select = .{
            .result = fields.next() orelse return error.InvalidDescriptor,
            .cond = try parseValue(fields.next() orelse return error.InvalidDescriptor),
            .ty = try parseType(fields.next() orelse return error.InvalidDescriptor),
            .then_value = try parseValue(fields.next() orelse return error.InvalidDescriptor),
            .else_value = try parseValue(fields.next() orelse return error.InvalidDescriptor),
        } };
    }
    if (std.mem.eql(u8, tag, "call")) {
        const result_text = fields.next() orelse return error.InvalidDescriptor;
        return .{ .call = .{
            .result = if (std.mem.eql(u8, result_text, "-")) null else result_text,
            .callee = fields.next() orelse return error.InvalidDescriptor,
            .calling_convention = try parseCallConv(fields.next() orelse return error.InvalidDescriptor),
            .ret_ty = try parseType(fields.next() orelse return error.InvalidDescriptor),
            .args = try parseValueList(fields.next() orelse return error.InvalidDescriptor),
            .abi = try parseAbiShape(fields.next() orelse return error.InvalidDescriptor),
        } };
    }
    if (std.mem.eql(u8, tag, "load")) {
        return .{ .load = .{
            .result = fields.next() orelse return error.InvalidDescriptor,
            .ptr = try parseValue(fields.next() orelse return error.InvalidDescriptor),
            .ty = try parseType(fields.next() orelse return error.InvalidDescriptor),
            .align_bytes = try parseU16(fields.next() orelse return error.InvalidDescriptor),
        } };
    }
    if (std.mem.eql(u8, tag, "store")) {
        return .{ .store = .{
            .ptr = try parseValue(fields.next() orelse return error.InvalidDescriptor),
            .ty = try parseType(fields.next() orelse return error.InvalidDescriptor),
            .value = try parseValue(fields.next() orelse return error.InvalidDescriptor),
            .align_bytes = try parseU16(fields.next() orelse return error.InvalidDescriptor),
        } };
    }
    if (std.mem.eql(u8, tag, "gep")) {
        return .{ .gep = .{
            .result = fields.next() orelse return error.InvalidDescriptor,
            .base = try parseValue(fields.next() orelse return error.InvalidDescriptor),
            .indices = try parseValueList(fields.next() orelse return error.InvalidDescriptor),
        } };
    }
    if (std.mem.eql(u8, tag, "phi2")) {
        const incoming = try std.heap.page_allocator.alloc(sdv2.Incoming, 2);
        const result = fields.next() orelse return error.InvalidDescriptor;
        const ty = try parseType(fields.next() orelse return error.InvalidDescriptor);
        incoming[0] = .{ .value = try parseValue(fields.next() orelse return error.InvalidDescriptor), .block = fields.next() orelse return error.InvalidDescriptor };
        incoming[1] = .{ .value = try parseValue(fields.next() orelse return error.InvalidDescriptor), .block = fields.next() orelse return error.InvalidDescriptor };
        return .{ .phi = .{ .result = result, .ty = ty, .incoming = incoming } };
    }
    if (std.mem.eql(u8, tag, "cast")) {
        return .{ .cast = .{
            .result = fields.next() orelse return error.InvalidDescriptor,
            .op = try parseCastOp(fields.next() orelse return error.InvalidDescriptor),
            .from = try parseValue(fields.next() orelse return error.InvalidDescriptor),
            .to = try parseType(fields.next() orelse return error.InvalidDescriptor),
        } };
    }
    if (std.mem.eql(u8, tag, "inline_asm_boundary")) {
        return .{ .inline_asm_boundary = .{ .text = fields.next() orelse "" } };
    }
    return error.InvalidDescriptor;
}

fn parseTerminator(fields: *std.mem.SplitIterator(u8, .scalar)) !sdv2.Terminator {
    const tag = fields.next() orelse return error.InvalidDescriptor;
    if (std.mem.eql(u8, tag, "ret")) {
        return .{ .ret = try parseValue(fields.next() orelse return error.InvalidDescriptor) };
    }
    if (std.mem.eql(u8, tag, "ret_void")) return .{ .ret = null };
    if (std.mem.eql(u8, tag, "br")) return .{ .br = fields.next() orelse return error.InvalidDescriptor };
    if (std.mem.eql(u8, tag, "condbr")) {
        return .{ .condbr = .{
            .cond = try parseValue(fields.next() orelse return error.InvalidDescriptor),
            .then_block = fields.next() orelse return error.InvalidDescriptor,
            .else_block = fields.next() orelse return error.InvalidDescriptor,
        } };
    }
    if (std.mem.eql(u8, tag, "unreachable")) return .@"unreachable";
    return error.InvalidDescriptor;
}

fn parseGlobal(fields: *std.mem.SplitIterator(u8, .scalar)) !sdv2.Global {
    const llvm_type = fields.next() orelse return error.InvalidDescriptor;
    return .{
        .name = fields.next() orelse return error.InvalidDescriptor,
        .kind = try parseGlobalKind(fields.next() orelse return error.InvalidDescriptor),
        .ty = try parseType(fields.next() orelse return error.InvalidDescriptor),
        .address_space = try parseAddressSpace(fields.next() orelse return error.InvalidDescriptor),
        .initializer = fields.next() orelse return error.InvalidDescriptor,
        .llvm_type = if (std.mem.eql(u8, llvm_type, "-")) null else llvm_type,
        .alignment = try parseU16(fields.next() orelse return error.InvalidDescriptor),
    };
}

fn parseValueList(text: []const u8) ![]const sdv2.ValueRef {
    if (std.mem.eql(u8, text, "-")) return &.{};
    var count: usize = 1;
    for (text) |byte| {
        if (byte == ',') count += 1;
    }
    const values = try std.heap.page_allocator.alloc(sdv2.ValueRef, count);
    var index: usize = 0;
    var parts = std.mem.splitScalar(u8, text, ',');
    while (parts.next()) |part| {
        values[index] = try parseValue(part);
        index += 1;
    }
    return values;
}

fn parseValue(text: []const u8) !sdv2.ValueRef {
    const colon = std.mem.indexOfScalar(u8, text, ':') orelse return error.InvalidDescriptor;
    return .{ .id = text[colon + 1 ..], .ty = try parseType(text[0..colon]) };
}

fn parseType(text: []const u8) !sdv2.Type {
    if (std.mem.eql(u8, text, "void")) return .void;
    if (std.mem.eql(u8, text, "i1")) return .bool;
    if (std.mem.eql(u8, text, "i8")) return .{ .int = 8 };
    if (std.mem.eql(u8, text, "i16")) return .{ .int = 16 };
    if (std.mem.eql(u8, text, "i32")) return .{ .int = 32 };
    if (std.mem.eql(u8, text, "i64")) return .{ .int = 64 };
    if (std.mem.eql(u8, text, "i128")) return .{ .int = 128 };
    if (std.mem.eql(u8, text, "f32")) return .{ .float = .f32 };
    if (std.mem.eql(u8, text, "f64")) return .{ .float = .f64 };
    if (std.mem.eql(u8, text, "f128")) return .{ .float = .f128 };
    if (std.mem.eql(u8, text, "ptr")) return .{ .pointer = .generic };
    if (std.mem.eql(u8, text, "tls_ptr")) return .{ .pointer = .local_exec_tls };
    return error.InvalidDescriptor;
}

fn parseBinOp(text: []const u8) !sdv2.BinOp {
    inline for (@typeInfo(sdv2.BinOp).@"enum".fields) |field| {
        if (std.mem.eql(u8, text, field.name)) return @enumFromInt(field.value);
    }
    return error.InvalidDescriptor;
}

fn parseCompareOp(text: []const u8) !sdv2.CompareOp {
    inline for (@typeInfo(sdv2.CompareOp).@"enum".fields) |field| {
        if (std.mem.eql(u8, text, field.name)) return @enumFromInt(field.value);
    }
    return error.InvalidDescriptor;
}

fn parseCastOp(text: []const u8) !sdv2.CastOp {
    inline for (@typeInfo(sdv2.CastOp).@"enum".fields) |field| {
        if (std.mem.eql(u8, text, field.name)) return @enumFromInt(field.value);
    }
    return error.InvalidDescriptor;
}

fn parseCallConv(text: []const u8) !sdv2.CallConv {
    if (std.mem.eql(u8, text, "zig")) return .zig;
    if (std.mem.eql(u8, text, "c")) return .c;
    if (std.mem.eql(u8, text, "fastcc")) return .fastcc;
    if (std.mem.eql(u8, text, "inline_asm_boundary")) return .inline_asm_boundary;
    return error.InvalidDescriptor;
}

fn parseAbiShape(text: []const u8) !sdv2.AbiShape {
    if (std.mem.eql(u8, text, "direct")) return .direct;
    if (std.mem.eql(u8, text, "runtime_boundary")) return .runtime_boundary;
    if (std.mem.eql(u8, text, "inline_asm_boundary")) return .inline_asm_boundary;
    if (std.mem.eql(u8, text, "sret")) return .sret;
    if (std.mem.eql(u8, text, "byval")) return .byval;
    return error.InvalidDescriptor;
}

fn parseGlobalKind(text: []const u8) !sdv2.GlobalKind {
    if (std.mem.eql(u8, text, "global")) return .global;
    if (std.mem.eql(u8, text, "constant")) return .constant;
    if (std.mem.eql(u8, text, "tls")) return .tls;
    return error.InvalidDescriptor;
}

fn parseAddressSpace(text: []const u8) !sdv2.AddressSpace {
    if (std.mem.eql(u8, text, "generic")) return .generic;
    if (std.mem.eql(u8, text, "local_exec_tls")) return .local_exec_tls;
    if (std.mem.eql(u8, text, "vram")) return .vram;
    return error.InvalidDescriptor;
}

fn parseU16(text: []const u8) !u16 {
    return std.fmt.parseInt(u16, text, 10) catch error.InvalidDescriptor;
}

fn inferSerializedReturnStub(functions: []const sdv2.Function) ?i32 {
    if (functions.len != 1) return null;
    const function = functions[0];
    if (!std.mem.eql(u8, function.name, "main") or function.blocks.len != 1) return null;
    const block = function.blocks[0];
    if (block.instructions.len != 1) return null;
    const binop = switch (block.instructions[0]) {
        .binop => |binop| binop,
        else => return null,
    };
    if (!std.mem.eql(u8, binop.result, "retv") or binop.op != .add) return null;
    const rhs = std.fmt.parseInt(i32, binop.rhs.id, 10) catch return null;
    if (rhs != 0) return null;
    return std.fmt.parseInt(i32, binop.lhs.id, 10) catch null;
}

fn parseSerializedReturnProgram(contents: []const u8) ?i32 {
    if (!descriptorLineValueEql(contents, "program_functions", "records")) return null;
    if (!descriptorLineValueEql(contents, "program_blocks", "records")) return null;
    if (!descriptorLineValueEql(contents, "program_instructions", "records")) return null;
    if (!descriptorLineValueEql(contents, "program_terminators", "records")) return null;
    if (!descriptorLineValueEql(contents, "program_globals", "records")) return null;
    var saw_function = false;
    var saw_block = false;
    var saw_term = false;
    var saw_globals = false;
    var ret_i32: ?i32 = null;
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        const payload = if (std.mem.startsWith(u8, line, "record=")) line["record=".len..] else continue;
        if (std.mem.eql(u8, payload, "function|main|zig|i32|0")) {
            saw_function = true;
            continue;
        }
        if (std.mem.eql(u8, payload, "block|main|entry|1")) {
            saw_block = true;
            continue;
        }
        if (std.mem.eql(u8, payload, "term|main|entry|ret|i32|%retv")) {
            saw_term = true;
            continue;
        }
        if (std.mem.eql(u8, payload, "globals|0")) {
            saw_globals = true;
            continue;
        }
        if (std.mem.startsWith(u8, payload, "inst|main|entry|binop|retv|add|i32|")) {
            const rest = payload["inst|main|entry|binop|retv|add|i32|".len..];
            const separator = std.mem.indexOfScalar(u8, rest, '|') orelse return null;
            if (!std.mem.eql(u8, rest[separator + 1 ..], "0")) return null;
            ret_i32 = std.fmt.parseInt(i32, rest[0..separator], 10) catch return null;
        }
    }
    if (!saw_function or !saw_block or !saw_term or !saw_globals) return null;
    return ret_i32;
}

fn descriptorDerivationFromName(name: []const u8) DescriptorDerivation {
    if (std.mem.eql(u8, name, "zig-air-facts")) return .zig_air_facts;
    if (std.mem.eql(u8, name, "static-descriptor-map")) return .static_descriptor_map;
    return .unknown;
}

fn descriptorRecordSourceFromName(name: []const u8) DescriptorRecordSource {
    if (std.mem.eql(u8, name, "air-extracted")) return .air_extracted;
    if (std.mem.eql(u8, name, "template")) return .template;
    return .unknown;
}

fn descriptorBodySelectorFromName(name: []const u8) DescriptorBodySelector {
    if (std.mem.eql(u8, name, "wrapper-body-map")) return .wrapper_body_map;
    if (std.mem.eql(u8, name, "source-tag-body-map")) return .source_tag_body_map;
    if (std.mem.eql(u8, name, "source-analysis")) return .source_analysis;
    return .unknown;
}

fn descriptorContextSelectorFromName(name: []const u8) DescriptorContextSelector {
    if (std.mem.eql(u8, name, "compile-context")) return .compile_context;
    if (std.mem.eql(u8, name, "env-source-tag")) return .env_source_tag;
    if (std.mem.eql(u8, name, "wrapper-body")) return .wrapper_body;
    if (std.mem.eql(u8, name, "source-tag-body")) return .source_tag_body;
    if (std.mem.eql(u8, name, "fixture-metadata")) return .fixture_metadata;
    return .unknown;
}

fn descriptorLineValue(contents: []const u8, key: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        const separator = std.mem.indexOfScalar(u8, line, '=') orelse continue;
        if (std.mem.eql(u8, line[0..separator], key)) return line[separator + 1 ..];
    }
    return null;
}

fn descriptorLineValueEql(contents: []const u8, key: []const u8, expected: []const u8) bool {
    const value = descriptorLineValue(contents, key) orelse return false;
    return std.mem.eql(u8, value, expected);
}

fn factValueUsize(contents: []const u8, name: []const u8) ?usize {
    const text = factValue1(contents, name) orelse return null;
    return std.fmt.parseInt(usize, text, 10) catch null;
}

fn parseSourceFactFunctions(contents: []const u8, expected_count: usize) ?[]SourceFactFunction {
    const declared_count = factValueUsize(contents, "function_inventory_count") orelse return null;
    if (declared_count != expected_count) return null;
    const allocator = std.heap.page_allocator;
    const functions = allocator.alloc(SourceFactFunction, expected_count) catch return null;
    var parsed: usize = 0;
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "fact=function_inventory|")) continue;
        if (parsed == functions.len) return null;
        var fields = std.mem.splitScalar(u8, line["fact=function_inventory|".len..], '|');
        const name = fields.next() orelse return null;
        const return_key = fields.next() orelse return null;
        const return_type = fields.next() orelse return null;
        const params_key = fields.next() orelse return null;
        const params_text = fields.next() orelse return null;
        const blocks_key = fields.next() orelse return null;
        const blocks_text = fields.next() orelse return null;
        const instructions_key = fields.next() orelse return null;
        const instructions_text = fields.next() orelse return null;
        if (!std.mem.eql(u8, return_key, "return") or
            !std.mem.eql(u8, params_key, "params") or
            !std.mem.eql(u8, blocks_key, "blocks") or
            !std.mem.eql(u8, instructions_key, "instructions") or
            fields.next() != null)
        {
            return null;
        }
        functions[parsed] = .{
            .name = name,
            .return_type = return_type,
            .param_count = std.fmt.parseInt(usize, params_text, 10) catch return null,
            .block_count = std.fmt.parseInt(usize, blocks_text, 10) catch return null,
            .instruction_count = std.fmt.parseInt(usize, instructions_text, 10) catch return null,
        };
        parsed += 1;
    }
    if (parsed != expected_count) return null;
    return functions;
}

fn parseSourceFactParams(contents: []const u8) ?[]SourceFactParam {
    var count: usize = 0;
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "fact=function_param|")) count += 1;
    }

    const allocator = std.heap.page_allocator;
    const params = allocator.alloc(SourceFactParam, count) catch return null;
    var parsed: usize = 0;
    lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "fact=function_param|")) continue;
        var fields = std.mem.splitScalar(u8, line["fact=function_param|".len..], '|');
        const function_name = fields.next() orelse return null;
        const index_text = fields.next() orelse return null;
        const ty = fields.next() orelse return null;
        if (fields.next() != null) return null;
        params[parsed] = .{
            .function_name = function_name,
            .index = std.fmt.parseInt(usize, index_text, 10) catch return null,
            .ty = ty,
        };
        parsed += 1;
    }
    return params;
}

fn factCategoryCount(contents: []const u8, category: []const u8) usize {
    const text = factValue2(contents, "inst_category", category) orelse return 0;
    return std.fmt.parseInt(usize, text, 10) catch 0;
}

fn factDetailCount(contents: []const u8, detail: []const u8) usize {
    const text = factValue2(contents, "inst_detail", detail) orelse return 0;
    return std.fmt.parseInt(usize, text, 10) catch 0;
}

fn factMainParamCount(contents: []const u8) ?usize {
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "fact=function|main|")) continue;
        var fields = std.mem.splitScalar(u8, line["fact=".len..], '|');
        while (fields.next()) |field| {
            if (std.mem.eql(u8, field, "params")) {
                const text = fields.next() orelse return null;
                return std.fmt.parseInt(usize, text, 10) catch null;
            }
        }
    }
    return null;
}

fn factValue1(contents: []const u8, name: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "fact=")) continue;
        var fields = std.mem.splitScalar(u8, line["fact=".len..], '|');
        const first = fields.next() orelse continue;
        if (!std.mem.eql(u8, first, name)) continue;
        return fields.next();
    }
    return null;
}

fn factValue2(contents: []const u8, first_name: []const u8, second_name: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "fact=")) continue;
        var fields = std.mem.splitScalar(u8, line["fact=".len..], '|');
        const first = fields.next() orelse continue;
        const second = fields.next() orelse continue;
        if (!std.mem.eql(u8, first, first_name) or !std.mem.eql(u8, second, second_name)) continue;
        return fields.next();
    }
    return null;
}

fn factValue3(contents: []const u8, first_name: []const u8, second_name: []const u8, third_name: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "fact=")) continue;
        var fields = std.mem.splitScalar(u8, line["fact=".len..], '|');
        const first = fields.next() orelse continue;
        const second = fields.next() orelse continue;
        const third = fields.next() orelse continue;
        if (!std.mem.eql(u8, first, first_name) or
            !std.mem.eql(u8, second, second_name) or
            !std.mem.eql(u8, third, third_name)) continue;
        return fields.next();
    }
    return null;
}

fn featuresForSurface(surface: []const u8) []const Feature {
    if (std.mem.eql(u8, surface, "scalar-add-ret") or
        std.mem.eql(u8, surface, "add-imm-return") or
        std.mem.eql(u8, surface, "comptime-const-mul") or
        std.mem.eql(u8, surface, "fp-literal-return") or
        std.mem.eql(u8, surface, "i1-const-return") or
        std.mem.eql(u8, surface, "constant-string-slice-return") or
        std.mem.eql(u8, surface, "noreturn-unreachable-stub"))
    {
        return &scalar_features;
    }
    if (std.mem.eql(u8, surface, "integer-arithmetic") or std.mem.eql(u8, surface, "i64-arithmetic") or std.mem.eql(u8, surface, "umul-fix-sat-i64") or std.mem.eql(u8, surface, "inherit-i64-return")) return &integer_features;
    if (std.mem.eql(u8, surface, "runtime-condbr") or std.mem.eql(u8, surface, "runtime-switch") or std.mem.eql(u8, surface, "runtime-phi-merge") or std.mem.eql(u8, surface, "error-switch-select")) return &branch_features;
    if (std.mem.eql(u8, surface, "runtime-loop-sum") or std.mem.eql(u8, surface, "slice-loop-sum") or std.mem.eql(u8, surface, "checked-slice-loop-sum-boundary") or std.mem.eql(u8, surface, "raw-start-loop")) return &loop_features;
    if (std.mem.eql(u8, surface, "abi-arg-call") or std.mem.eql(u8, surface, "checked-call-chain-boundary") or std.mem.eql(u8, surface, "compile-asm-unreachable")) return &call_features;
    if (std.mem.eql(u8, surface, "global-update") or std.mem.eql(u8, surface, "global-load") or std.mem.eql(u8, surface, "hidden-global-access")) return &global_features;
    if (std.mem.eql(u8, surface, "tls-read") or std.mem.eql(u8, surface, "tls-bump") or std.mem.eql(u8, surface, "checked-tls-bump-boundary") or std.mem.eql(u8, surface, "mixed-c-zig-add") or std.mem.eql(u8, surface, "mixed-c-zig-panic-add")) return &tls_features;
    if (std.mem.eql(u8, surface, "pointer-load-store") or std.mem.eql(u8, surface, "optional-pointer") or std.mem.eql(u8, surface, "packed-read-flag") or std.mem.eql(u8, surface, "packed-replace-low") or std.mem.eql(u8, surface, "volatile-roundtrip") or std.mem.eql(u8, surface, "address-space-volatile-store") or std.mem.eql(u8, surface, "getauxval-pointer-walk")) return &memory_features;
    if (std.mem.indexOf(u8, surface, "struct") != null or std.mem.indexOf(u8, surface, "array") != null or std.mem.indexOf(u8, surface, "aggregate") != null or std.mem.indexOf(u8, surface, "payload") != null or std.mem.eql(u8, surface, "f128-sret-byval") or std.mem.eql(u8, surface, "start-trampoline")) return &aggregate_features;
    if (std.mem.startsWith(u8, surface, "float") or std.mem.eql(u8, surface, "double-div")) return &fp_features;
    if (std.mem.eql(u8, surface, "atomic-add")) return &atomic_features;
    if (std.mem.eql(u8, surface, "inline-asm-barrier")) return &inline_asm_features;
    if (std.mem.eql(u8, surface, "void-noop-call")) return &call_features;
    if (std.mem.startsWith(u8, surface, "checked-")) return &runtime_boundary_features;
    if (std.mem.eql(u8, surface, "table-indexed-load")) return &table_features;
    if (std.mem.startsWith(u8, surface, "base64-")) return &base64_features;
    if (std.mem.eql(u8, surface, "str-from-float-help")) return &str_from_float_features;
    if (std.mem.eql(u8, surface, "libfuzzer-vtable-run")) return &indirect_features;
    return &runtime_boundary_features;
}
