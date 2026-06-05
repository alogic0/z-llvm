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

pub fn resolveSourceOwned(wrapper: []const u8, mode: []const u8, fixture: []const u8, tag: []const u8) ?Descriptor {
    if (!isReleaseMode(mode)) return null;
    if (!std.mem.startsWith(u8, fixture, "test/distribution/")) return null;
    const surface = surfaceForSourceMetadata(wrapper, tag) orelse return null;
    const source: Source = .{ .wrapper = wrapper, .mode = mode, .fixture = fixture, .tag = tag };
    const v2_source: sdv2.Source = .{ .wrapper = wrapper, .mode = mode, .fixture = fixture, .tag = tag };
    const v2 = sdv2.programFromSurface(v2_source, surface) orelse return null;
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

fn surfaceForSourceMetadata(wrapper: []const u8, tag: []const u8) ?[]const u8 {
    if (!std.mem.eql(u8, tag, "-")) return surfaceForTag(tag);
    return surfaceForUntaggedWrapper(wrapper);
}

fn surfaceForTag(tag: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, tag, "tiny-scalar")) return "scalar-add-ret";
    if (std.mem.eql(u8, tag, "integers-add-wrap")) return "integer-arithmetic";
    if (std.mem.eql(u8, tag, "integers-cmp-shift")) return "integer-arithmetic";
    if (std.mem.eql(u8, tag, "control-flow-loop-sum")) return "runtime-loop-sum";
    if (std.mem.eql(u8, tag, "control-flow-call-chain")) return "abi-arg-call";
    if (std.mem.eql(u8, tag, "error-switch")) return "error-switch-select";
    if (std.mem.eql(u8, tag, "switch-branch-mix")) return "runtime-condbr";
    if (std.mem.eql(u8, tag, "switch-dense")) return "runtime-switch";
    if (std.mem.eql(u8, tag, "pointers-memory")) return "pointer-load-store";
    if (std.mem.eql(u8, tag, "optional-pointer-value")) return "optional-pointer";
    if (std.mem.eql(u8, tag, "packed-bits-read-flag")) return "packed-read-flag";
    if (std.mem.eql(u8, tag, "packed-bits-replace-low")) return "packed-replace-low";
    if (std.mem.eql(u8, tag, "aggregates-struct-sum")) return "struct-field-sum";
    if (std.mem.eql(u8, tag, "aggregates-array-sum")) return "array-scalar-sum";
    if (std.mem.eql(u8, tag, "aggregates-optional-payload")) return "optional-scalar-payload";
    if (std.mem.eql(u8, tag, "aggregates-error-union-payload")) return "error-union-payload";
    if (std.mem.eql(u8, tag, "aggregates-slice-sum")) return "slice-loop-sum";
    if (std.mem.eql(u8, tag, "fp-constants-literals")) return "fp-literal-return";
    if (std.mem.eql(u8, tag, "globals-comptime-const")) return "comptime-const-mul";
    if (std.mem.eql(u8, tag, "globals-comptime-global-counter")) return "global-update";
    if (std.mem.eql(u8, tag, "atomics-debug-location")) return "add-imm-return";
    if (std.mem.eql(u8, tag, "tls-concurrency-read")) return "tls-read";
    if (std.mem.eql(u8, tag, "tls-concurrency-bump")) return "tls-bump";
    if (std.mem.eql(u8, tag, "atomics-atomic-add")) return "atomic-add";
    if (std.mem.eql(u8, tag, "atomics-inline-asm-barrier")) return "inline-asm-barrier";
    if (std.mem.eql(u8, tag, "aggregate-abi-pair")) return "aggregate-pair-abi";
    if (std.mem.eql(u8, tag, "float-compare")) return "float-less";
    if (std.mem.eql(u8, tag, "floats-math")) return "float-add";
    if (std.mem.eql(u8, tag, "fp-extended-ops")) return "float-sub";
    if (std.mem.eql(u8, tag, "error-switch-select")) return "error-switch-select";
    if (std.mem.eql(u8, tag, "atomics-debug-location-checked")) return "checked-add-imm-boundary";
    if (std.mem.eql(u8, tag, "globals-checked")) return "checked-global-update-boundary";
    if (std.mem.eql(u8, tag, "pointers-memory-checked")) return "checked-pointer-load-store-boundary";
    if (std.mem.eql(u8, tag, "switch-branch-mix-checked")) return "checked-branch-mix-boundary";
    if (std.mem.eql(u8, tag, "control-flow-calls-checked")) return "checked-call-chain-boundary";
    if (std.mem.eql(u8, tag, "tls-concurrency-checked-bump")) return "checked-tls-bump-boundary";
    if (std.mem.eql(u8, tag, "tls-concurrency-checked-read")) return "tls-read";
    if (std.mem.eql(u8, tag, "aggregates-checked-array")) return "checked-array-sum-boundary";
    if (std.mem.eql(u8, tag, "aggregates-checked-struct")) return "checked-struct-sum-boundary";
    if (std.mem.eql(u8, tag, "aggregates-checked-slice")) return "checked-slice-loop-sum-boundary";
    if (std.mem.eql(u8, tag, "tiny-scalar-checked-add")) return "checked-add-runtime-boundary";
    if (std.mem.eql(u8, tag, "hidden-access")) return "hidden-global-access";
    if (std.mem.eql(u8, tag, "mixed-c-add-zig")) return "mixed-c-zig-add";
    if (std.mem.eql(u8, tag, "mixed-c-add-may-panic")) return "mixed-c-zig-panic-add";
    if (std.mem.eql(u8, tag, "umul-fix-sat-i64")) return "umul-fix-sat-i64";
    if (std.mem.eql(u8, tag, "inherit-want-safety-i64-return")) return "inherit-i64-return";
    if (std.mem.eql(u8, tag, "compile-asm-main-unreachable")) return "compile-asm-unreachable";
    if (std.mem.eql(u8, tag, "address-space-start-trampoline")) return "start-trampoline";
    if (std.mem.eql(u8, tag, "getauxval-pointer-walk")) return "getauxval-pointer-walk";
    if (std.mem.eql(u8, tag, "f128-sret-byval")) return "f128-sret-byval";
    if (std.mem.eql(u8, tag, "logical-pointer-unreachable")) return "noreturn-unreachable-stub";
    if (std.mem.eql(u8, tag, "vram-volatile-store")) return "address-space-volatile-store";
    if (std.mem.eql(u8, tag, "unreachable-stubs")) return "noreturn-unreachable-stub";
    if (std.mem.eql(u8, tag, "raw-start-loop")) return "raw-start-loop";
    if (std.mem.eql(u8, tag, "libfuzzer-futex-wait")) return "i1-const-return";
    if (std.mem.eql(u8, tag, "libfuzzer-test-name")) return "constant-string-slice-return";
    if (std.mem.eql(u8, tag, "libfuzzer-test-run")) return "libfuzzer-vtable-run";
    if (std.mem.eql(u8, tag, "base64-table-lookup")) return "table-indexed-load";
    return null;
}

fn surfaceForUntaggedWrapper(wrapper: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_hidden_access_main.zig")) return "hidden-global-access";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_mix_c_add_zig_main.zig")) return "mixed-c-zig-add";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_mix_c_add_may_panic_main.zig")) return "mixed-c-zig-panic-add";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_umul_fix_sat_i64_main.zig")) return "umul-fix-sat-i64";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_inherit_want_safety_i64_main.zig")) return "inherit-i64-return";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_compile_asm_unreachable_main.zig")) return "compile-asm-unreachable";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_str_from_float_help_main.zig")) return "str-from-float-help";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_decode_base_64_full_main.zig")) return "base64-decode-base64-full";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_decode_step_main.zig")) return "base64-decode-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_store_step_main.zig")) return "base64-store-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_residual_byte_step_main.zig")) return "base64-residual-byte-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_padding_tail_step_main.zig")) return "base64-padding-tail-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_padding_loop_step_main.zig")) return "base64-padding-loop-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_padding_length_step_main.zig")) return "base64-padding-length-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_chunk_guard_step_main.zig")) return "base64-chunk-guard-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_source_stride_step_main.zig")) return "base64-source-stride-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_source_bundle_step_main.zig")) return "base64-source-bundle-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_next_source_bundle_step_main.zig")) return "base64-next-source-bundle-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_third_source_bundle_step_main.zig")) return "base64-third-source-bundle-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_bit_buffer_store_step_main.zig")) return "base64-bit-buffer-store-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_loop_advance_step_main.zig")) return "base64-loop-advance-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_residual_guard_step_main.zig")) return "base64-residual-guard-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_residual_bundle_step_main.zig")) return "base64-residual-bundle-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_residual_store_step_main.zig")) return "base64-residual-store-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_residual_length_step_main.zig")) return "base64-residual-length-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_residual_table_check_step_main.zig")) return "base64-residual-table-check-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_residual_accumulator_step_main.zig")) return "base64-residual-accumulator-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_residual_loop_advance_step_main.zig")) return "base64-residual-loop-advance-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_residual_padding_check_step_main.zig")) return "base64-residual-padding-check-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_residual_final_mask_step_main.zig")) return "base64-residual-final-mask-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_residual_padding_loop_step_main.zig")) return "base64-residual-padding-loop-step";
    if (std.mem.eql(u8, wrapper, "test/zig/integrated/runtime_base64_decode_exit_step_main.zig")) return "base64-decode-exit-step";
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
