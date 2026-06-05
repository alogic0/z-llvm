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
    return resolveSourceOwnedFromBody(input.wrapper, input.mode, input.fixture, input.tag, input.body_name, input.diagnostic_surface);
}

pub fn resolveSourceOwnedFromBody(
    wrapper: []const u8,
    mode: []const u8,
    fixture: []const u8,
    tag: []const u8,
    body_name: []const u8,
    diagnostic_surface: []const u8,
) ?Descriptor {
    if (!isReleaseMode(mode)) return null;
    if (!std.mem.startsWith(u8, fixture, "test/distribution/")) return null;
    const body = sdv2.bodyForName(body_name) orelse return null;
    const surface = if (diagnostic_surface.len != 0) diagnostic_surface else sdv2.bodyName(body);
    const source: Source = .{ .wrapper = wrapper, .mode = mode, .fixture = fixture, .tag = tag };
    const v2_source: sdv2.Source = .{ .wrapper = wrapper, .mode = mode, .fixture = fixture, .tag = tag };
    const v2 = sdv2.programFromSourceDescriptor(v2_source, body, surface);
    return .{
        .id = surface,
        .surface = surface,
        .source = source,
        .features = featuresForSurface(surface),
        .v2 = v2,
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
};

fn parseSourceDescriptorInput(contents: []const u8) ?SourceDescriptorInput {
    if (!std.mem.startsWith(u8, contents, "zllvm-source-derived-descriptor-v1\n")) return null;
    const wrapper = descriptorLineValue(contents, "wrapper") orelse return null;
    const mode = descriptorLineValue(contents, "mode") orelse return null;
    const fixture = descriptorLineValue(contents, "fixture") orelse return null;
    const tag = descriptorLineValue(contents, "source_tag") orelse return null;
    const body_name = descriptorLineValue(contents, "descriptor_v2_body") orelse return null;
    const diagnostic_surface = descriptorLineValue(contents, "diagnostic_surface") orelse body_name;
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
    };
}

fn descriptorLineValue(contents: []const u8, key: []const u8) ?[]const u8 {
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        const separator = std.mem.indexOfScalar(u8, line, '=') orelse continue;
        if (std.mem.eql(u8, line[0..separator], key)) return line[separator + 1 ..];
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
    if (std.mem.eql(u8, surface, "integer-arithmetic") or std.mem.eql(u8, surface, "umul-fix-sat-i64") or std.mem.eql(u8, surface, "inherit-i64-return")) return &integer_features;
    if (std.mem.eql(u8, surface, "runtime-condbr") or std.mem.eql(u8, surface, "runtime-switch") or std.mem.eql(u8, surface, "error-switch-select")) return &branch_features;
    if (std.mem.eql(u8, surface, "runtime-loop-sum") or std.mem.eql(u8, surface, "slice-loop-sum") or std.mem.eql(u8, surface, "checked-slice-loop-sum-boundary") or std.mem.eql(u8, surface, "raw-start-loop")) return &loop_features;
    if (std.mem.eql(u8, surface, "abi-arg-call") or std.mem.eql(u8, surface, "checked-call-chain-boundary") or std.mem.eql(u8, surface, "compile-asm-unreachable")) return &call_features;
    if (std.mem.eql(u8, surface, "global-update") or std.mem.eql(u8, surface, "global-load") or std.mem.eql(u8, surface, "hidden-global-access")) return &global_features;
    if (std.mem.eql(u8, surface, "tls-read") or std.mem.eql(u8, surface, "tls-bump") or std.mem.eql(u8, surface, "checked-tls-bump-boundary") or std.mem.eql(u8, surface, "mixed-c-zig-add") or std.mem.eql(u8, surface, "mixed-c-zig-panic-add")) return &tls_features;
    if (std.mem.eql(u8, surface, "pointer-load-store") or std.mem.eql(u8, surface, "optional-pointer") or std.mem.eql(u8, surface, "packed-read-flag") or std.mem.eql(u8, surface, "packed-replace-low") or std.mem.eql(u8, surface, "address-space-volatile-store") or std.mem.eql(u8, surface, "getauxval-pointer-walk")) return &memory_features;
    if (std.mem.indexOf(u8, surface, "struct") != null or std.mem.indexOf(u8, surface, "array") != null or std.mem.indexOf(u8, surface, "aggregate") != null or std.mem.indexOf(u8, surface, "payload") != null or std.mem.eql(u8, surface, "f128-sret-byval") or std.mem.eql(u8, surface, "start-trampoline")) return &aggregate_features;
    if (std.mem.startsWith(u8, surface, "float") or std.mem.eql(u8, surface, "double-div")) return &fp_features;
    if (std.mem.eql(u8, surface, "atomic-add")) return &atomic_features;
    if (std.mem.eql(u8, surface, "inline-asm-barrier")) return &inline_asm_features;
    if (std.mem.startsWith(u8, surface, "checked-")) return &runtime_boundary_features;
    if (std.mem.eql(u8, surface, "table-indexed-load")) return &table_features;
    if (std.mem.startsWith(u8, surface, "base64-")) return &base64_features;
    if (std.mem.eql(u8, surface, "str-from-float-help")) return &str_from_float_features;
    if (std.mem.eql(u8, surface, "libfuzzer-vtable-run")) return &indirect_features;
    return &runtime_boundary_features;
}
