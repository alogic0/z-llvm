const std = @import("std");
const sd = @import("semantic_descriptor.zig");
const sib = @import("structured_ir_builder.zig");
const zsl = @import("zig_semantic_lowering.zig");
const irw = @import("ir_writer_helpers.zig");
const base64_rows = @import("main_base64_rows.zig");

const writeBase64SourceByte = base64_rows.writeBase64SourceByte;
const writeBase64OutputStore = base64_rows.writeBase64OutputStore;
const writeBase64FourByteBundleLoads = base64_rows.writeBase64FourByteBundleLoads;
const base64DecodeTableValue = base64_rows.base64DecodeTableValue;
const writeBase64FullTableConstant = base64_rows.writeBase64FullTableConstant;
const writeBase64FullMainCheck = base64_rows.writeBase64FullMainCheck;
const base64FullTableInitializer = base64_rows.base64FullTableInitializer;
const writeBase64FullStructuredModule = base64_rows.writeBase64FullStructuredModule;
const writeBase64FullMainCheckStructured = base64_rows.writeBase64FullMainCheckStructured;
const writeBase64FullTableLoadStructured = base64_rows.writeBase64FullTableLoadStructured;
const writeBase64OutputStoreStructured = base64_rows.writeBase64OutputStoreStructured;
const writeReleaseSmallRuntimeBase64DecodeBase64FullIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64DecodeBase64FullIrWriterBody;
const writeReleaseSmallRuntimeBase64DecodeBase64FullTextualIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64DecodeBase64FullTextualIrWriterBody;
const writeReleaseSmallRuntimeBase64DecodeStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64DecodeStepIrWriterBody;
const writeBase64DecodeStepStructuredModule = base64_rows.writeBase64DecodeStepStructuredModule;
const writeReleaseSmallRuntimeBase64StoreStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64StoreStepIrWriterBody;
const writeBase64StoreStepStructuredModule = base64_rows.writeBase64StoreStepStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualByteStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualByteStepIrWriterBody;
const writeBase64ResidualByteStepStructuredModule = base64_rows.writeBase64ResidualByteStepStructuredModule;
const writeReleaseSmallRuntimeBase64PaddingTailStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64PaddingTailStepIrWriterBody;
const writeBase64PaddingTailStepStructuredModule = base64_rows.writeBase64PaddingTailStepStructuredModule;
const writeReleaseSmallRuntimeBase64PaddingLoopStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64PaddingLoopStepIrWriterBody;
const writeBase64PaddingLoopStepStructuredModule = base64_rows.writeBase64PaddingLoopStepStructuredModule;
const writeReleaseSmallRuntimeBase64PaddingLengthStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64PaddingLengthStepIrWriterBody;
const writeBase64PaddingLengthStepStructuredModule = base64_rows.writeBase64PaddingLengthStepStructuredModule;
const writeReleaseSmallRuntimeBase64ChunkGuardStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ChunkGuardStepIrWriterBody;
const writeBase64ChunkGuardStepStructuredModule = base64_rows.writeBase64ChunkGuardStepStructuredModule;
const writeReleaseSmallRuntimeBase64SourceStrideStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64SourceStrideStepIrWriterBody;
const writeBase64SourceStrideStructuredModule = base64_rows.writeBase64SourceStrideStructuredModule;
const writeReleaseSmallRuntimeBase64SourceBundleStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64SourceBundleStepIrWriterBody;
const writeReleaseSmallRuntimeBase64NextSourceBundleStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64NextSourceBundleStepIrWriterBody;
const writeReleaseSmallRuntimeBase64ThirdSourceBundleStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ThirdSourceBundleStepIrWriterBody;
const writeBase64SourceBundleStructuredModule = base64_rows.writeBase64SourceBundleStructuredModule;
const writeBase64FourByteBundleStructured = base64_rows.writeBase64FourByteBundleStructured;
const writeBase64BundleTableLoad = base64_rows.writeBase64BundleTableLoad;
const writeReleaseSmallRuntimeBase64BitBufferStoreStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64BitBufferStoreStepIrWriterBody;
const writeBase64BitBufferStoreStructuredModule = base64_rows.writeBase64BitBufferStoreStructuredModule;
const writeReleaseSmallRuntimeBase64LoopAdvanceStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64LoopAdvanceStepIrWriterBody;
const writeBase64LoopAdvanceStructuredModule = base64_rows.writeBase64LoopAdvanceStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualGuardStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualGuardStepIrWriterBody;
const writeBase64ResidualGuardStructuredModule = base64_rows.writeBase64ResidualGuardStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualBundleStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualBundleStepIrWriterBody;
const writeReleaseSmallRuntimeBase64ResidualStoreStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualStoreStepIrWriterBody;
const writeBase64ResidualStoreStructuredModule = base64_rows.writeBase64ResidualStoreStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualLengthStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualLengthStepIrWriterBody;
const writeBase64ResidualLengthStructuredModule = base64_rows.writeBase64ResidualLengthStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualTableCheckStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualTableCheckStepIrWriterBody;
const writeBase64ResidualTableCheckStructuredModule = base64_rows.writeBase64ResidualTableCheckStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualAccumulatorStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualAccumulatorStepIrWriterBody;
const writeBase64ResidualAccumulatorStructuredModule = base64_rows.writeBase64ResidualAccumulatorStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualLoopAdvanceStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualLoopAdvanceStepIrWriterBody;
const writeBase64ResidualLoopAdvanceStructuredModule = base64_rows.writeBase64ResidualLoopAdvanceStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualPaddingCheckStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualPaddingCheckStepIrWriterBody;
const writeBase64ResidualPaddingCheckStructuredModule = base64_rows.writeBase64ResidualPaddingCheckStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualFinalMaskStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualFinalMaskStepIrWriterBody;
const writeBase64ResidualFinalMaskStructuredModule = base64_rows.writeBase64ResidualFinalMaskStructuredModule;
const writeReleaseSmallRuntimeBase64ResidualPaddingLoopStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64ResidualPaddingLoopStepIrWriterBody;
const writeBase64ResidualPaddingLoopStructuredModule = base64_rows.writeBase64ResidualPaddingLoopStructuredModule;
const writeReleaseSmallRuntimeBase64DecodeExitStepIrWriterBody = base64_rows.writeReleaseSmallRuntimeBase64DecodeExitStepIrWriterBody;
const writeBase64DecodeExitStructuredModule = base64_rows.writeBase64DecodeExitStructuredModule;
const writeBase64TableLookupIrWriterBody = base64_rows.writeBase64TableLookupIrWriterBody;
const writeBase64TableLookupStructuredModule = base64_rows.writeBase64TableLookupStructuredModule;

pub fn fatal(io: std.Io, comptime fmt: []const u8, args: anytype) noreturn {
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    stderr_writer.interface.print(fmt, args) catch {};
    stderr_writer.interface.flush() catch {};
    std.process.exit(2);
}

pub const IrWriterBodyFn = *const fn (std.Io, *std.Io.Writer, []const u8) anyerror!void;

pub const IrConstruction = enum {
    structured_builder,
    textual_subset,

    pub fn marker(self: IrConstruction) []const u8 {
        return switch (self) {
            .structured_builder => "ir-construction=zllvm-structured-builder",
            .textual_subset => "ir-construction=z_llvm-external-textual-subset",
        };
    }
};

pub const CodegenOwnership = enum {
    generic,
    case_specific,
    textual_boundary,

    pub fn marker(self: CodegenOwnership) []const u8 {
        return switch (self) {
            .generic => "codegen=generic-x86_64-lowering",
            .case_specific => "codegen=case-specific-x86_64-lowering",
            .textual_boundary => "codegen=out-of-scope-textual-boundary",
        };
    }
};

pub const StructuredLoweringOwnership = enum {
    manifest_structured,
    semantic_record,
    descriptor_v2,
    external_writer_delegate,

    pub fn marker(self: StructuredLoweringOwnership) []const u8 {
        return switch (self) {
            .manifest_structured => "lowering=manifest-structured",
            .semantic_record => "lowering=zig-semantic-records",
            .descriptor_v2 => "lowering=semantic-descriptor-v2",
            .external_writer_delegate => "lowering=external-writer-delegate",
        };
    }
};

pub const SourceWrapperDispatchEntry = struct {
    wrapper: []const u8,
    mode: []const u8,
    case_id: []const u8,
};

pub const ReleaseSourceOwnedDispatchEntry = struct {
    wrapper: []const u8,
    mode: []const u8,
    fixture: []const u8,
    tag: []const u8,
    case_id: []const u8,
};

pub const IrWriterCase = struct {
    id: []const u8,
    surface: []const u8,
    write: IrWriterBodyFn,
    construction: IrConstruction = .textual_subset,
};

pub const source_wrapper_dispatch_case_id = "source-wrapper-dispatch";
pub const source_wrapper_dispatch_name = "source-wrapper";
pub const source_owned_dispatch_name = "source-owned";

pub const source_wrapper_dispatch_entries = [_]SourceWrapperDispatchEntry{

    .{ .wrapper = "test/zig/integrated/tiny_scalar_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_tiny_scalar" },
    .{ .wrapper = "test/zig/integrated/integers_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_integers_add_wrap" },
    .{ .wrapper = "test/zig/integrated/control_flow_calls_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_control_flow_call_chain" },
    .{ .wrapper = "test/zig/integrated/runtime_loop_sum_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_control_flow_loop_sum" },
    .{ .wrapper = "test/zig/integrated/error_switch_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_error_switch_error_switch" },
    .{ .wrapper = "test/zig/integrated/runtime_cond_branch_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_switch_branch_mix" },
    .{ .wrapper = "test/zig/integrated/runtime_phi_merge_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_runtime_phi_merge" },
    .{ .wrapper = "test/zig/integrated/runtime_switch_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_switch_dense" },
    .{ .wrapper = "test/zig/integrated/runtime_global_update_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_globals_comptime_global_counter" },
    .{ .wrapper = "test/zig/integrated/runtime_pointer_load_store_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_pointers_memory" },
    .{ .wrapper = "test/zig/integrated/runtime_volatile_roundtrip_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_runtime_volatile_roundtrip" },
    .{ .wrapper = "test/zig/integrated/runtime_optional_pointer_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_optional_pointer_value" },
    .{ .wrapper = "test/zig/integrated/runtime_packed_read_flag_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_packed_bits_basic_read_flag" },
    .{ .wrapper = "test/zig/integrated/runtime_packed_replace_low_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_packed_bits_basic_replace_low" },
    .{ .wrapper = "test/zig/integrated/runtime_struct_sum_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_aggregates_struct_sum" },
    .{ .wrapper = "test/zig/integrated/runtime_array_sum_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_aggregates_array_sum" },
    .{ .wrapper = "test/zig/integrated/runtime_optional_payload_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_aggregates_optional_payload" },
    .{ .wrapper = "test/zig/integrated/runtime_error_union_payload_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_aggregates_error_union_payload" },
    .{ .wrapper = "test/zig/integrated/runtime_slice_sum_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_aggregates_slice_sum" },
    .{ .wrapper = "test/zig/integrated/runtime_fp_constants_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_fp_constants_literals" },
    .{ .wrapper = "test/zig/integrated/runtime_comptime_const_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_globals_comptime_const" },
    .{ .wrapper = "test/zig/integrated/runtime_debug_location_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_atomics_debug_location" },
    .{ .wrapper = "test/zig/integrated/runtime_tls_read_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_tls_concurrency_counter_read" },
    .{ .wrapper = "test/zig/integrated/runtime_atomic_add_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_atomics_atomic_add" },
    .{ .wrapper = "test/zig/integrated/runtime_inline_asm_barrier_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_atomics_inline_asm_barrier" },
    .{ .wrapper = "test/zig/integrated/runtime_aggregate_pair_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_aggregate_abi_pair" },
    .{ .wrapper = "test/zig/integrated/runtime_float_less_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_float_compare" },
    .{ .wrapper = "test/zig/integrated/runtime_float_add_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_floats_math" },
    .{ .wrapper = "test/zig/integrated/runtime_float_sub_main.zig", .mode = "ReleaseFast", .case_id = "releasefast_source_fp_extended_ops" },
    .{ .wrapper = "test/zig/integrated/error_switch_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_error_switch_select" },
    .{ .wrapper = "test/zig/integrated/runtime_debug_location_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_atomics_debug_location_checked" },
    .{ .wrapper = "test/zig/integrated/runtime_global_update_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_globals_checked" },
    .{ .wrapper = "test/zig/integrated/runtime_pointer_load_store_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_pointers_memory_checked" },
    .{ .wrapper = "test/zig/integrated/runtime_branch_mix_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_switch_branch_mix_checked" },
    .{ .wrapper = "test/zig/integrated/control_flow_calls_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_control_flow_calls_checked" },
    .{ .wrapper = "test/zig/integrated/runtime_tls_read_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_tls_concurrency_checked_read" },
    .{ .wrapper = "test/zig/integrated/runtime_array_sum_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_aggregates_checked_array" },
    .{ .wrapper = "test/zig/integrated/runtime_struct_sum_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_aggregates_checked_struct" },
    .{ .wrapper = "test/zig/integrated/runtime_slice_sum_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_aggregates_checked_slice" },
    .{ .wrapper = "test/zig/integrated/tiny_scalar_releasesafe_boundary_main.zig", .mode = "ReleaseSafe", .case_id = "releasesafe_source_tiny_scalar_checked_add" },
    .{ .wrapper = "test/zig/integrated/runtime_hidden_access_main.zig", .mode = "ReleaseSmall", .case_id = "releasesmall_source_standalone_extern_exports_hidden_access" },
    .{ .wrapper = "test/zig/integrated/runtime_mix_c_add_zig_main.zig", .mode = "ReleaseSmall", .case_id = "releasesmall_source_standalone_mix_c_files_add_zig" },
    .{ .wrapper = "test/zig/integrated/runtime_mix_c_add_may_panic_main.zig", .mode = "ReleaseSmall", .case_id = "releasesmall_source_standalone_mix_c_files_add_may_panic" },
    .{ .wrapper = "test/zig/integrated/runtime_umul_fix_sat_i64_main.zig", .mode = "ReleaseSmall", .case_id = "releasesmall_source_no_compile_panic_for_unchecked_arith_umul_fix_sat_i64" },
    .{ .wrapper = "test/zig/integrated/runtime_inherit_want_safety_i64_main.zig", .mode = "ReleaseSmall", .case_id = "releasesmall_source_inherit_want_safety_i64_return" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .case_id = "releasesmall_source_standalone_compile_asm_main_unreachable" },
    .{ .wrapper = "test/zig/integrated/runtime_str_from_float_help_main.zig", .mode = "ReleaseSmall", .case_id = "releasesmall_runtime_str_from_float_help" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_decode_base_64_full_main.zig", .mode = "ReleaseSmall", .case_id = "releasesmall_runtime_base64_decode_base_64_full" },
    .{ .wrapper = "test/zig/integrated/base64_table_lookup_main.zig", .mode = "ReleaseSmall", .case_id = "releasesmall_source_base64_table_lookup" },
};

pub const release_source_owned_dispatch_entries = [_]ReleaseSourceOwnedDispatchEntry{
    .{ .wrapper = "test/zig/integrated/tiny_scalar_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/tiny_scalar.ll", .tag = "tiny-scalar", .case_id = "releasefast_source_tiny_scalar" },
    .{ .wrapper = "test/zig/integrated/integers_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/integers_add_wrap.ll", .tag = "integers-add-wrap", .case_id = "releasefast_source_integers_add_wrap" },
    .{ .wrapper = "test/zig/integrated/integers_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/integers_cmp_shift.ll", .tag = "integers-cmp-shift", .case_id = "releasefast_source_integers_cmp_shift" },
    .{ .wrapper = "test/zig/integrated/runtime_loop_sum_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/control_flow_calls_loop_sum.ll", .tag = "control-flow-loop-sum", .case_id = "releasefast_source_control_flow_loop_sum" },
    .{ .wrapper = "test/zig/integrated/control_flow_calls_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/control_flow_calls_call_chain.ll", .tag = "control-flow-call-chain", .case_id = "releasefast_source_control_flow_call_chain" },
    .{ .wrapper = "test/zig/integrated/error_switch_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/error_switch_error_switch.ll", .tag = "error-switch", .case_id = "releasefast_source_error_switch_error_switch" },
    .{ .wrapper = "test/zig/integrated/runtime_cond_branch_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/switch_control_branch_mix.ll", .tag = "switch-branch-mix", .case_id = "releasefast_source_switch_branch_mix" },
    .{ .wrapper = "test/zig/integrated/runtime_switch_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/switch_control_dense_switch.ll", .tag = "switch-dense", .case_id = "releasefast_source_switch_dense" },
    .{ .wrapper = "test/zig/integrated/runtime_pointer_load_store_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/pointers_memory_basic.ll", .tag = "pointers-memory", .case_id = "releasefast_source_pointers_memory" },
    .{ .wrapper = "test/zig/integrated/runtime_optional_pointer_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/optional_pointer_value.ll", .tag = "optional-pointer-value", .case_id = "releasefast_source_optional_pointer_value" },
    .{ .wrapper = "test/zig/integrated/runtime_packed_read_flag_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/packed_bits_basic.ll", .tag = "packed-bits-read-flag", .case_id = "releasefast_source_packed_bits_basic_read_flag" },
    .{ .wrapper = "test/zig/integrated/runtime_packed_replace_low_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/packed_bits_basic.ll", .tag = "packed-bits-replace-low", .case_id = "releasefast_source_packed_bits_basic_replace_low" },
    .{ .wrapper = "test/zig/integrated/runtime_struct_sum_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/aggregates_struct_sum.ll", .tag = "aggregates-struct-sum", .case_id = "releasefast_source_aggregates_struct_sum" },
    .{ .wrapper = "test/zig/integrated/runtime_array_sum_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/aggregates_array_sum.ll", .tag = "aggregates-array-sum", .case_id = "releasefast_source_aggregates_array_sum" },
    .{ .wrapper = "test/zig/integrated/runtime_optional_payload_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/aggregates_optional_payload.ll", .tag = "aggregates-optional-payload", .case_id = "releasefast_source_aggregates_optional_payload" },
    .{ .wrapper = "test/zig/integrated/runtime_error_union_payload_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/aggregates_error_union_payload.ll", .tag = "aggregates-error-union-payload", .case_id = "releasefast_source_aggregates_error_union_payload" },
    .{ .wrapper = "test/zig/integrated/runtime_slice_sum_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/aggregates_slice_sum.ll", .tag = "aggregates-slice-sum", .case_id = "releasefast_source_aggregates_slice_sum" },
    .{ .wrapper = "test/zig/integrated/runtime_fp_constants_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/fp_constants_literals.ll", .tag = "fp-constants-literals", .case_id = "releasefast_source_fp_constants_literals" },
    .{ .wrapper = "test/zig/integrated/runtime_comptime_const_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/globals_comptime_const.ll", .tag = "globals-comptime-const", .case_id = "releasefast_source_globals_comptime_const" },
    .{ .wrapper = "test/zig/integrated/runtime_global_update_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/globals_comptime_global_counter.ll", .tag = "globals-comptime-global-counter", .case_id = "releasefast_source_globals_comptime_global_counter" },
    .{ .wrapper = "test/zig/integrated/runtime_debug_location_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/atomics_debug_location.ll", .tag = "atomics-debug-location", .case_id = "releasefast_source_atomics_debug_location" },
    .{ .wrapper = "test/zig/integrated/runtime_tls_read_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/tls_concurrency_counter.ll", .tag = "tls-concurrency-read", .case_id = "releasefast_source_tls_concurrency_counter_read" },
    .{ .wrapper = "test/zig/integrated/runtime_tls_read_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/tls_concurrency_counter.ll", .tag = "tls-concurrency-bump", .case_id = "releasefast_source_tls_concurrency_counter_bump" },
    .{ .wrapper = "test/zig/integrated/runtime_atomic_add_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/atomics_atomic_add.ll", .tag = "atomics-atomic-add", .case_id = "releasefast_source_atomics_atomic_add" },
    .{ .wrapper = "test/zig/integrated/runtime_inline_asm_barrier_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/atomics_inline_asm_barrier.ll", .tag = "atomics-inline-asm-barrier", .case_id = "releasefast_source_atomics_inline_asm_barrier" },
    .{ .wrapper = "test/zig/integrated/runtime_aggregate_pair_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/aggregate_abi_pair.ll", .tag = "aggregate-abi-pair", .case_id = "releasefast_source_aggregate_abi_pair" },
    .{ .wrapper = "test/zig/integrated/runtime_float_less_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/float_compare_basic.ll", .tag = "float-compare", .case_id = "releasefast_source_float_compare" },
    .{ .wrapper = "test/zig/integrated/runtime_float_add_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/floats_math_basic.ll", .tag = "floats-math", .case_id = "releasefast_source_floats_math" },
    .{ .wrapper = "test/zig/integrated/runtime_float_sub_main.zig", .mode = "ReleaseFast", .fixture = "test/distribution/releasefast_x86_64/inputs/fp_extended_ops_basic.ll", .tag = "fp-extended-ops", .case_id = "releasefast_source_fp_extended_ops" },
    .{ .wrapper = "test/zig/integrated/error_switch_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/error_switch_select.ll", .tag = "error-switch-select", .case_id = "releasesafe_source_error_switch_select" },
    .{ .wrapper = "test/zig/integrated/runtime_debug_location_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/atomics_debug_location_checked.ll", .tag = "atomics-debug-location-checked", .case_id = "releasesafe_source_atomics_debug_location_checked" },
    .{ .wrapper = "test/zig/integrated/runtime_global_update_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/globals_comptime_checked.ll", .tag = "globals-checked", .case_id = "releasesafe_source_globals_checked" },
    .{ .wrapper = "test/zig/integrated/runtime_pointer_load_store_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/pointers_memory_checked.ll", .tag = "pointers-memory-checked", .case_id = "releasesafe_source_pointers_memory_checked" },
    .{ .wrapper = "test/zig/integrated/runtime_branch_mix_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/switch_control_branch_mix_checked.ll", .tag = "switch-branch-mix-checked", .case_id = "releasesafe_source_switch_branch_mix_checked" },
    .{ .wrapper = "test/zig/integrated/control_flow_calls_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/control_flow_calls_checked.ll", .tag = "control-flow-calls-checked", .case_id = "releasesafe_source_control_flow_calls_checked" },
    .{ .wrapper = "test/zig/integrated/runtime_tls_read_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/tls_concurrency_checked.ll", .tag = "tls-concurrency-checked-bump", .case_id = "releasesafe_source_tls_concurrency_checked_bump" },
    .{ .wrapper = "test/zig/integrated/runtime_tls_read_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/tls_concurrency_checked.ll", .tag = "tls-concurrency-checked-read", .case_id = "releasesafe_source_tls_concurrency_checked_read" },
    .{ .wrapper = "test/zig/integrated/runtime_array_sum_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/aggregates_checked_sums.ll", .tag = "aggregates-checked-array", .case_id = "releasesafe_source_aggregates_checked_array" },
    .{ .wrapper = "test/zig/integrated/runtime_struct_sum_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/aggregates_checked_sums.ll", .tag = "aggregates-checked-struct", .case_id = "releasesafe_source_aggregates_checked_struct" },
    .{ .wrapper = "test/zig/integrated/runtime_slice_sum_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/aggregates_checked_sums.ll", .tag = "aggregates-checked-slice", .case_id = "releasesafe_source_aggregates_checked_slice" },
    .{ .wrapper = "test/zig/integrated/tiny_scalar_releasesafe_boundary_main.zig", .mode = "ReleaseSafe", .fixture = "test/distribution/releasesafe_x86_64/inputs/tiny_scalar_checked_add.ll", .tag = "tiny-scalar-checked-add", .case_id = "releasesafe_source_tiny_scalar_checked_add" },
    .{ .wrapper = "test/zig/integrated/runtime_hidden_access_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_extern_exports_hidden_access.ll", .tag = "-", .case_id = "releasesmall_runtime_hidden_access" },
    .{ .wrapper = "test/zig/integrated/runtime_hidden_access_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_extern_exports_hidden_access.ll", .tag = "hidden-access", .case_id = "releasesmall_source_standalone_extern_exports_hidden_access" },
    .{ .wrapper = "test/zig/integrated/runtime_mix_c_add_zig_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_zig.ll", .tag = "-", .case_id = "releasesmall_runtime_mix_c_add_zig" },
    .{ .wrapper = "test/zig/integrated/runtime_mix_c_add_zig_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_zig.ll", .tag = "mixed-c-add-zig", .case_id = "releasesmall_source_standalone_mix_c_files_add_zig" },
    .{ .wrapper = "test/zig/integrated/runtime_mix_c_add_may_panic_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_may_panic.ll", .tag = "-", .case_id = "releasesmall_runtime_mix_c_add_may_panic" },
    .{ .wrapper = "test/zig/integrated/runtime_mix_c_add_may_panic_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_may_panic.ll", .tag = "mixed-c-add-may-panic", .case_id = "releasesmall_source_standalone_mix_c_files_add_may_panic" },
    .{ .wrapper = "test/zig/integrated/runtime_umul_fix_sat_i64_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/no_compile_panic_for_unchecked_arith_umul_fix_sat_i64.ll", .tag = "-", .case_id = "releasesmall_runtime_umul_fix_sat_i64" },
    .{ .wrapper = "test/zig/integrated/runtime_umul_fix_sat_i64_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/no_compile_panic_for_unchecked_arith_umul_fix_sat_i64.ll", .tag = "umul-fix-sat-i64", .case_id = "releasesmall_source_no_compile_panic_for_unchecked_arith_umul_fix_sat_i64" },
    .{ .wrapper = "test/zig/integrated/runtime_inherit_want_safety_i64_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/inherit_want_safety_i64_return.ll", .tag = "-", .case_id = "releasesmall_runtime_inherit_want_safety_i64" },
    .{ .wrapper = "test/zig/integrated/runtime_inherit_want_safety_i64_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/inherit_want_safety_i64_return.ll", .tag = "inherit-want-safety-i64-return", .case_id = "releasesmall_source_inherit_want_safety_i64_return" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_compile_asm_main_unreachable.ll", .tag = "-", .case_id = "releasesmall_runtime_compile_asm_unreachable" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_compile_asm_main_unreachable.ll", .tag = "compile-asm-main-unreachable", .case_id = "releasesmall_source_standalone_compile_asm_main_unreachable" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/address_space_start_trampoline.ll", .tag = "address-space-start-trampoline", .case_id = "releasesmall_source_address_space_start_trampoline" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/array_in_anon_struct_getauxval.ll", .tag = "getauxval-pointer-walk", .case_id = "releasesmall_source_array_in_anon_struct_getauxval" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/c_abi_main_f128_sret.ll", .tag = "f128-sret-byval", .case_id = "releasesmall_source_c_abi_main_f128_sret" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/compile_errors_illegal_operation_on_logical_ptr_elem_ptr.ll", .tag = "logical-pointer-unreachable", .case_id = "releasesmall_source_compile_errors_logical_ptr_elem_ptr" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/export_keyword_vram_store.ll", .tag = "vram-volatile-store", .case_id = "releasesmall_source_export_keyword_vram_store" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/sizeof_typeof_unreachable_stubs.ll", .tag = "unreachable-stubs", .case_id = "releasesmall_source_sizeof_typeof_unreachable_stubs" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_install_raw_hex_start_loop.ll", .tag = "raw-start-loop", .case_id = "releasesmall_source_standalone_install_raw_hex_start_loop" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_libfuzzer_runner_futex_wait.ll", .tag = "libfuzzer-futex-wait", .case_id = "releasesmall_source_standalone_libfuzzer_runner_futex_wait" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_libfuzzer_runner_test_name.ll", .tag = "libfuzzer-test-name", .case_id = "releasesmall_source_standalone_libfuzzer_runner_test_name" },
    .{ .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_libfuzzer_runner_test_run.ll", .tag = "libfuzzer-test-run", .case_id = "releasesmall_source_standalone_libfuzzer_runner_test_run" },
    .{ .wrapper = "test/zig/integrated/runtime_str_from_float_help_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_emit_llvm_no_bin_str_from_float_help.ll", .tag = "-", .case_id = "releasesmall_runtime_str_from_float_help" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_decode_base_64_full_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_decode_base_64_full" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_decode_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_decode_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_store_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_store_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_byte_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_byte_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_padding_tail_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_padding_tail_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_padding_loop_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_padding_loop_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_padding_length_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_padding_length_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_chunk_guard_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_chunk_guard_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_source_stride_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_source_stride_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_source_bundle_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_source_bundle_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_next_source_bundle_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_next_source_bundle_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_third_source_bundle_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_third_source_bundle_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_bit_buffer_store_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_bit_buffer_store_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_loop_advance_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_loop_advance_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_guard_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_guard_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_bundle_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_bundle_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_store_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_store_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_length_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_length_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_table_check_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_table_check_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_accumulator_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_accumulator_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_loop_advance_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_loop_advance_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_padding_check_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_padding_check_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_final_mask_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_final_mask_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_residual_padding_loop_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_residual_padding_loop_step" },
    .{ .wrapper = "test/zig/integrated/runtime_base64_decode_exit_step_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll", .tag = "-", .case_id = "releasesmall_runtime_base64_decode_exit_step" },
    .{ .wrapper = "test/zig/integrated/base64_table_lookup_main.zig", .mode = "ReleaseSmall", .fixture = "test/distribution/releasesmall_x86_64/inputs/base64_table_lookup.ll", .tag = "base64-table-lookup", .case_id = "releasesmall_source_base64_table_lookup" },
};

pub const ir_writer_cases = [_]IrWriterCase{
    .{ .id = "releasefast_tiny_scalar", .surface = "scalar-add-ret", .write = case_writers.writeTinyScalarIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_tiny_scalar", .surface = "scalar-add-ret", .write = case_writers.writeTinyScalarIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_integers", .surface = "integer-arithmetic", .write = case_writers.writeIntegersIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_integers_add_wrap", .surface = "integer-arithmetic", .write = case_writers.writeIntegersIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_integers_cmp_shift", .surface = "integer-arithmetic", .write = case_writers.writeIntegersIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_error_switch", .surface = "error-switch-select", .write = case_writers.writeErrorSwitchIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_error_switch_error_switch", .surface = "error-switch-select", .write = case_writers.writeErrorSwitchIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_control_flow_calls", .surface = "direct-call", .write = case_writers.writeControlFlowCallsIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_control_flow_loop_sum", .surface = "runtime-loop-sum", .write = case_writers.writeRuntimeLoopSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_control_flow_call_chain", .surface = "abi-arg-call", .write = case_writers.writeRuntimeCallChainIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_globals_comptime", .surface = "global-load", .write = case_writers.writeGlobalsComptimeIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_read_global", .surface = "global-load", .write = case_writers.writeReleaseSafeRuntimeReadGlobalIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_cond_branch", .surface = "runtime-condbr", .write = case_writers.writeRuntimeCondBranchIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_switch_branch_mix", .surface = "runtime-condbr", .write = case_writers.writeRuntimeCondBranchIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_phi_merge", .surface = "runtime-phi-merge", .write = case_writers.writeRuntimePhiMergeIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_loop_sum", .surface = "runtime-loop-sum", .write = case_writers.writeRuntimeLoopSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_loop_sum", .surface = "checked-loop-sum-boundary", .write = case_writers.writeReleaseSafeRuntimeLoopSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_switch", .surface = "runtime-switch", .write = case_writers.writeRuntimeSwitchIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_switch_dense", .surface = "runtime-switch", .write = case_writers.writeRuntimeSwitchIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_branch_mix", .surface = "checked-branch-mix-boundary", .write = case_writers.writeReleaseSafeRuntimeBranchMixIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_global_update", .surface = "global-update", .write = case_writers.writeRuntimeGlobalUpdateIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_global_update", .surface = "checked-global-update-boundary", .write = case_writers.writeReleaseSafeRuntimeGlobalUpdateIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_globals_checked", .surface = "checked-global-update-boundary", .write = case_writers.writeReleaseSafeRuntimeGlobalUpdateIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_pointer_load_store", .surface = "pointer-load-store", .write = case_writers.writeRuntimePointerLoadStoreIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_pointers_memory", .surface = "pointer-load-store", .write = case_writers.writeRuntimePointerLoadStoreIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_pointer_load_store", .surface = "checked-pointer-load-store-boundary", .write = case_writers.writeReleaseSafeRuntimePointerLoadStoreIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_pointers_memory_checked", .surface = "checked-pointer-load-store-boundary", .write = case_writers.writeReleaseSafeRuntimePointerLoadStoreIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_volatile_roundtrip", .surface = "volatile-roundtrip", .write = case_writers.writeRuntimeVolatileRoundtripIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_optional_pointer", .surface = "optional-pointer", .write = case_writers.writeRuntimeOptionalPointerIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_optional_pointer_value", .surface = "optional-pointer", .write = case_writers.writeRuntimeOptionalPointerIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_packed_read_flag", .surface = "packed-read-flag", .write = case_writers.writeRuntimePackedReadFlagIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_packed_bits_basic_read_flag", .surface = "packed-read-flag", .write = case_writers.writeRuntimePackedReadFlagIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_packed_replace_low", .surface = "packed-replace-low", .write = case_writers.writeRuntimePackedReplaceLowIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_packed_bits_basic_replace_low", .surface = "packed-replace-low", .write = case_writers.writeRuntimePackedReplaceLowIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_struct_sum", .surface = "struct-field-sum", .write = case_writers.writeRuntimeStructSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_aggregates_struct_sum", .surface = "struct-field-sum", .write = case_writers.writeRuntimeStructSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_struct_sum", .surface = "checked-struct-sum-boundary", .write = case_writers.writeReleaseSafeRuntimeStructSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_aggregates_checked_struct", .surface = "checked-struct-sum-boundary", .write = case_writers.writeReleaseSafeRuntimeStructSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_array_sum", .surface = "array-scalar-sum", .write = case_writers.writeRuntimeArraySumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_aggregates_array_sum", .surface = "array-scalar-sum", .write = case_writers.writeRuntimeArraySumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_array_sum", .surface = "checked-array-sum-boundary", .write = case_writers.writeReleaseSafeRuntimeArraySumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_aggregates_checked_array", .surface = "checked-array-sum-boundary", .write = case_writers.writeReleaseSafeRuntimeArraySumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_optional_payload", .surface = "optional-scalar-payload", .write = case_writers.writeRuntimeOptionalPayloadIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_aggregates_optional_payload", .surface = "optional-scalar-payload", .write = case_writers.writeRuntimeOptionalPayloadIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_error_union_payload", .surface = "error-union-payload", .write = case_writers.writeRuntimeErrorUnionPayloadIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_aggregates_error_union_payload", .surface = "error-union-payload", .write = case_writers.writeRuntimeErrorUnionPayloadIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_slice_sum", .surface = "slice-loop-sum", .write = case_writers.writeRuntimeSliceSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_aggregates_slice_sum", .surface = "slice-loop-sum", .write = case_writers.writeRuntimeSliceSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_slice_sum", .surface = "checked-slice-loop-sum-boundary", .write = case_writers.writeReleaseSafeRuntimeSliceSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_aggregates_checked_slice", .surface = "checked-slice-loop-sum-boundary", .write = case_writers.writeReleaseSafeRuntimeSliceSumIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_fp_constants", .surface = "fp-literal-return", .write = case_writers.writeRuntimeFpConstantsIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_fp_constants_literals", .surface = "fp-literal-return", .write = case_writers.writeRuntimeFpConstantsIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_comptime_const", .surface = "comptime-const-mul", .write = case_writers.writeRuntimeComptimeConstIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_globals_comptime_const", .surface = "comptime-const-mul", .write = case_writers.writeRuntimeComptimeConstIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_globals_comptime_global_counter", .surface = "global-update", .write = case_writers.writeRuntimeGlobalUpdateIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_comptime_const", .surface = "checked-comptime-const-boundary", .write = case_writers.writeReleaseSafeRuntimeComptimeConstIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_debug_location", .surface = "add-imm-return", .write = case_writers.writeRuntimeDebugLocationIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_atomics_debug_location", .surface = "add-imm-return", .write = case_writers.writeRuntimeDebugLocationIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_debug_location", .surface = "checked-add-imm-boundary", .write = case_writers.writeReleaseSafeRuntimeDebugLocationIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_atomics_debug_location_checked", .surface = "checked-add-imm-boundary", .write = case_writers.writeReleaseSafeRuntimeDebugLocationIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_call_chain", .surface = "abi-arg-call", .write = case_writers.writeRuntimeCallChainIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_call_chain", .surface = "checked-call-chain-boundary", .write = case_writers.writeReleaseSafeRuntimeCallChainIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_control_flow_calls_checked", .surface = "checked-call-chain-boundary", .write = case_writers.writeReleaseSafeRuntimeCallChainIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_tls_read", .surface = "tls-read", .write = case_writers.writeRuntimeTlsReadIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_tls_concurrency_counter_read", .surface = "tls-read", .write = case_writers.writeRuntimeTlsReadIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_tls_read", .surface = "tls-read", .write = case_writers.writeRuntimeTlsReadIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_tls_concurrency_checked_read", .surface = "tls-read", .write = case_writers.writeRuntimeTlsReadIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_tls_bump", .surface = "tls-bump", .write = case_writers.writeRuntimeTlsBumpIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_tls_concurrency_counter_bump", .surface = "tls-bump", .write = case_writers.writeRuntimeTlsBumpIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_tls_bump", .surface = "checked-tls-bump-boundary", .write = case_writers.writeReleaseSafeRuntimeTlsBumpIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_tls_concurrency_checked_bump", .surface = "checked-tls-bump-boundary", .write = case_writers.writeReleaseSafeRuntimeTlsBumpIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_atomic_add", .surface = "atomic-add", .write = case_writers.writeRuntimeAtomicAddIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_atomics_atomic_add", .surface = "atomic-add", .write = case_writers.writeRuntimeAtomicAddIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_inline_asm_barrier", .surface = "inline-asm-barrier", .write = case_writers.writeRuntimeInlineAsmBarrierIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_atomics_inline_asm_barrier", .surface = "inline-asm-barrier", .write = case_writers.writeRuntimeInlineAsmBarrierIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_aggregate_pair", .surface = "aggregate-pair-abi", .write = case_writers.writeRuntimeAggregatePairIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_aggregate_abi_pair", .surface = "aggregate-pair-abi", .write = case_writers.writeRuntimeAggregatePairIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_float_less", .surface = "float-less", .write = case_writers.writeRuntimeFloatLessIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_float_compare", .surface = "float-less", .write = case_writers.writeRuntimeFloatLessIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_float_mul", .surface = "float-mul", .write = case_writers.writeRuntimeFloatMulIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_float_add", .surface = "float-add", .write = case_writers.writeRuntimeFloatAddIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_floats_math", .surface = "float-add", .write = case_writers.writeRuntimeFloatAddIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_float_select", .surface = "float-select", .write = case_writers.writeRuntimeFloatSelectIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_float_sub", .surface = "float-sub", .write = case_writers.writeRuntimeFloatSubIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_source_fp_extended_ops", .surface = "float-sub", .write = case_writers.writeRuntimeFloatSubIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_double_div", .surface = "double-div", .write = case_writers.writeRuntimeDoubleDivIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasefast_runtime_float_rem", .surface = "float-rem", .write = case_writers.writeRuntimeFloatRemIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_error_switch", .surface = "error-switch-select", .write = case_writers.writeErrorSwitchIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_error_switch_select", .surface = "error-switch-select", .write = case_writers.writeErrorSwitchIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_tiny_scalar_runtime_boundary", .surface = "checked-add-runtime-boundary", .write = case_writers.writeCheckedAddRuntimeBoundaryIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_tiny_scalar_checked_add", .surface = "checked-add-runtime-boundary", .write = case_writers.writeCheckedAddRuntimeBoundaryIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_source_switch_branch_mix_checked", .surface = "checked-branch-mix-boundary", .write = case_writers.writeReleaseSafeRuntimeBranchMixIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesafe_runtime_side_effect_free", .surface = "void-noop-call", .write = case_writers.writeReleaseSafeRuntimeSideEffectFreeIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_globals_comptime", .surface = "global-load", .write = case_writers.writeGlobalsComptimeIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_hidden_access", .surface = "hidden-global-access", .write = case_writers.writeReleaseSmallRuntimeHiddenAccessIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_standalone_extern_exports_hidden_access", .surface = "hidden-global-access", .write = case_writers.writeReleaseSmallRuntimeHiddenAccessIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_mix_c_add_zig", .surface = "mixed-c-zig-add", .write = case_writers.writeReleaseSmallRuntimeMixCAddZigIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_standalone_mix_c_files_add_zig", .surface = "mixed-c-zig-add", .write = case_writers.writeReleaseSmallRuntimeMixCAddZigIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_mix_c_add_may_panic", .surface = "mixed-c-zig-panic-add", .write = case_writers.writeReleaseSmallRuntimeMixCAddMayPanicIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_standalone_mix_c_files_add_may_panic", .surface = "mixed-c-zig-panic-add", .write = case_writers.writeReleaseSmallRuntimeMixCAddMayPanicIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_umul_fix_sat_i64", .surface = "umul-fix-sat-i64", .write = case_writers.writeReleaseSmallRuntimeUmulFixSatI64IrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_no_compile_panic_for_unchecked_arith_umul_fix_sat_i64", .surface = "umul-fix-sat-i64", .write = case_writers.writeReleaseSmallRuntimeUmulFixSatI64IrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_inherit_want_safety_i64", .surface = "inherit-i64-return", .write = case_writers.writeReleaseSmallRuntimeInheritWantSafetyI64IrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_inherit_want_safety_i64_return", .surface = "inherit-i64-return", .write = case_writers.writeReleaseSmallRuntimeInheritWantSafetyI64IrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_compile_asm_unreachable", .surface = "compile-asm-unreachable", .write = case_writers.writeReleaseSmallRuntimeCompileAsmUnreachableIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_standalone_compile_asm_main_unreachable", .surface = "compile-asm-unreachable", .write = case_writers.writeReleaseSmallRuntimeCompileAsmUnreachableIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_address_space_start_trampoline", .surface = "start-trampoline", .write = case_writers.writeReleaseSmallAddressSpaceStartTrampolineIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_array_in_anon_struct_getauxval", .surface = "getauxval-pointer-walk", .write = case_writers.writeReleaseSmallGetauxvalIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_c_abi_main_f128_sret", .surface = "f128-sret-byval", .write = case_writers.writeReleaseSmallCAbiF128SretIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_compile_errors_logical_ptr_elem_ptr", .surface = "noreturn-unreachable-stub", .write = case_writers.writeReleaseSmallLogicalPtrUnreachableIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_export_keyword_vram_store", .surface = "address-space-volatile-store", .write = case_writers.writeReleaseSmallVramStoreIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_sizeof_typeof_unreachable_stubs", .surface = "noreturn-unreachable-stub", .write = case_writers.writeReleaseSmallSizeofTypeofUnreachableIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_standalone_install_raw_hex_start_loop", .surface = "raw-start-loop", .write = case_writers.writeReleaseSmallRawStartLoopIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_standalone_libfuzzer_runner_futex_wait", .surface = "i1-const-return", .write = case_writers.writeReleaseSmallLibfuzzerFutexWaitIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_standalone_libfuzzer_runner_test_name", .surface = "constant-string-slice-return", .write = case_writers.writeReleaseSmallLibfuzzerTestNameIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_standalone_libfuzzer_runner_test_run", .surface = "libfuzzer-vtable-run", .write = case_writers.writeReleaseSmallLibfuzzerTestRunIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_str_from_float_help", .surface = "str-from-float-help", .write = case_writers.writeReleaseSmallRuntimeStrFromFloatHelpIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_decode_base_64_full", .surface = "base64-decode-base64-full", .write = case_writers.writeReleaseSmallRuntimeBase64DecodeBase64FullIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_decode_step", .surface = "base64-decode-step", .write = case_writers.writeReleaseSmallRuntimeBase64DecodeStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_store_step", .surface = "base64-store-step", .write = case_writers.writeReleaseSmallRuntimeBase64StoreStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_byte_step", .surface = "base64-residual-byte-step", .write = case_writers.writeReleaseSmallRuntimeBase64ResidualByteStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_padding_tail_step", .surface = "base64-padding-tail-step", .write = case_writers.writeReleaseSmallRuntimeBase64PaddingTailStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_padding_loop_step", .surface = "base64-padding-loop-step", .write = case_writers.writeReleaseSmallRuntimeBase64PaddingLoopStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_padding_length_step", .surface = "base64-padding-length-step", .write = case_writers.writeReleaseSmallRuntimeBase64PaddingLengthStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_chunk_guard_step", .surface = "base64-chunk-guard-step", .write = case_writers.writeReleaseSmallRuntimeBase64ChunkGuardStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_source_stride_step", .surface = "base64-source-stride-step", .write = case_writers.writeReleaseSmallRuntimeBase64SourceStrideStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_source_bundle_step", .surface = "base64-source-bundle-step", .write = case_writers.writeReleaseSmallRuntimeBase64SourceBundleStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_next_source_bundle_step", .surface = "base64-next-source-bundle-step", .write = case_writers.writeReleaseSmallRuntimeBase64NextSourceBundleStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_third_source_bundle_step", .surface = "base64-third-source-bundle-step", .write = case_writers.writeReleaseSmallRuntimeBase64ThirdSourceBundleStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_bit_buffer_store_step", .surface = "base64-bit-buffer-store-step", .write = case_writers.writeReleaseSmallRuntimeBase64BitBufferStoreStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_loop_advance_step", .surface = "base64-loop-advance-step", .write = case_writers.writeReleaseSmallRuntimeBase64LoopAdvanceStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_guard_step", .surface = "base64-residual-guard-step", .write = case_writers.writeReleaseSmallRuntimeBase64ResidualGuardStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_bundle_step", .surface = "base64-residual-bundle-step", .write = case_writers.writeReleaseSmallRuntimeBase64ResidualBundleStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_store_step", .surface = "base64-residual-store-step", .write = case_writers.writeReleaseSmallRuntimeBase64ResidualStoreStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_length_step", .surface = "base64-residual-length-step", .write = case_writers.writeReleaseSmallRuntimeBase64ResidualLengthStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_table_check_step", .surface = "base64-residual-table-check-step", .write = case_writers.writeReleaseSmallRuntimeBase64ResidualTableCheckStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_accumulator_step", .surface = "base64-residual-accumulator-step", .write = case_writers.writeReleaseSmallRuntimeBase64ResidualAccumulatorStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_loop_advance_step", .surface = "base64-residual-loop-advance-step", .write = case_writers.writeReleaseSmallRuntimeBase64ResidualLoopAdvanceStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_padding_check_step", .surface = "base64-residual-padding-check-step", .write = case_writers.writeReleaseSmallRuntimeBase64ResidualPaddingCheckStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_final_mask_step", .surface = "base64-residual-final-mask-step", .write = case_writers.writeReleaseSmallRuntimeBase64ResidualFinalMaskStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_residual_padding_loop_step", .surface = "base64-residual-padding-loop-step", .write = case_writers.writeReleaseSmallRuntimeBase64ResidualPaddingLoopStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_base64_decode_exit_step", .surface = "base64-decode-exit-step", .write = case_writers.writeReleaseSmallRuntimeBase64DecodeExitStepIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_i64_arithmetic", .surface = "i64-arithmetic", .write = case_writers.writeI64ArithmeticIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_runtime_i64_call", .surface = "i64-call-return", .write = case_writers.writeRuntimeI64CallIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_base64_table_lookup", .surface = "table-indexed-load", .write = case_writers.writeBase64TableLookupIrWriterBody, .construction = .structured_builder },
    .{ .id = "releasesmall_source_base64_table_lookup", .surface = "table-indexed-load", .write = case_writers.writeBase64TableLookupIrWriterBody, .construction = .structured_builder },
};

pub fn findIrWriterCase(case_id: []const u8) ?IrWriterCase {
    for (ir_writer_cases) |case| {
        if (std.mem.eql(u8, case.id, case_id)) return case;
    }
    return null;
}

pub fn resolveSourceWrapperDispatchCase(wrapper: []const u8, mode: []const u8) ?IrWriterCase {
    for (source_wrapper_dispatch_entries) |entry| {
        if (std.mem.eql(u8, entry.wrapper, wrapper) and std.mem.eql(u8, entry.mode, mode)) {
            return findIrWriterCase(entry.case_id);
        }
    }
    return null;
}

pub fn resolveReleaseSourceOwnedDispatchCase(
    wrapper: []const u8,
    mode: []const u8,
    fixture: []const u8,
    tag: []const u8,
) ?IrWriterCase {
    for (release_source_owned_dispatch_entries) |entry| {
        if (std.mem.eql(u8, entry.wrapper, wrapper) and
            std.mem.eql(u8, entry.mode, mode) and
            std.mem.eql(u8, entry.fixture, fixture) and
            std.mem.eql(u8, entry.tag, tag))
        {
            return findIrWriterCase(entry.case_id);
        }
    }
    return null;
}

pub fn codegenOwnershipForCase(case: IrWriterCase) CodegenOwnership {
    if (case.construction != .structured_builder) return .textual_boundary;
    return .generic;
}

pub fn structuredLoweringOwnershipForCase(case: IrWriterCase) StructuredLoweringOwnership {
    if (zsl.isSemanticSurface(case.surface)) return .semantic_record;
    if (case.construction == .structured_builder) return .external_writer_delegate;
    return .manifest_structured;
}

pub fn semanticProgramForCase(case: IrWriterCase) ?zsl.Program {
    if (case.construction != .structured_builder) return null;
    const surface = case.surface;
    if (std.mem.eql(u8, surface, "scalar-add-ret")) return .tiny_scalar;
    if (std.mem.eql(u8, surface, "integer-arithmetic")) return .integer_arithmetic;
    if (std.mem.eql(u8, surface, "error-switch-select")) return .error_switch_select;
    if (std.mem.eql(u8, surface, "direct-call")) return .direct_call;
    if (std.mem.eql(u8, surface, "abi-arg-call")) return .call_chain;
    if (std.mem.eql(u8, surface, "runtime-condbr")) return .cond_branch;
    if (std.mem.eql(u8, surface, "runtime-phi-merge")) return .phi_merge;
    if (std.mem.eql(u8, surface, "runtime-loop-sum")) return .loop_sum;
    if (std.mem.eql(u8, surface, "global-update")) return .global_update;
    if (std.mem.eql(u8, surface, "pointer-load-store")) return .pointer_load_store;
    if (std.mem.eql(u8, surface, "struct-field-sum")) return .struct_sum;
    if (std.mem.eql(u8, surface, "array-scalar-sum")) return .array_sum;
    if (std.mem.eql(u8, surface, "optional-scalar-payload")) return .optional_payload;
    if (std.mem.eql(u8, surface, "error-union-payload")) return .error_union_payload;
    if (std.mem.eql(u8, surface, "slice-loop-sum")) return .slice_sum;
    if (std.mem.eql(u8, surface, "fp-literal-return")) return .fp_literals;
    if (std.mem.eql(u8, surface, "comptime-const-mul")) return .comptime_const;
    if (std.mem.eql(u8, surface, "add-imm-return")) return .debug_location;
    if (std.mem.eql(u8, surface, "tls-read")) return .tls_read;
    if (std.mem.eql(u8, surface, "atomic-add")) return .atomic_add;
    return null;
}


const case_writers = @import("main_flow_ir_writer_case_writers.zig");
pub const writeMinimalIrWriterBody = case_writers.writeMinimalIrWriterBody;
