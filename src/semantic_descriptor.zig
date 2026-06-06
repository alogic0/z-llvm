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
    serialized_return_i32: ?i32 = null,
};

pub const InputPayload = enum {
    descriptor_body_name,
    full_descriptor_program,
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
    return descriptor.input_payload == .full_descriptor_program;
}

pub fn usesDescriptorBodyNameInput(descriptor: Descriptor) bool {
    return descriptor.input_payload == .descriptor_body_name;
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
};

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
        .serialized_return_i32 = ret_i32,
    };
}

fn isSourceOwnedFixture(fixture: []const u8) bool {
    return std.mem.startsWith(u8, fixture, "test/distribution/") or
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
