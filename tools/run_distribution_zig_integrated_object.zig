const std = @import("std");
const common = @import("tool_common.zig");

const expected_selected_ir_writer_rows = 146;
const expected_release_source_owned_rows = 100;
const source_wrapper_dispatch_case_id = "source-wrapper-dispatch";

const Validation = enum {
    executable,
    link_only,
};

const Pipeline = enum {
    postopt,
    preopt,
};

const Case = struct {
    id: []const u8,
    wrapper: []const u8,
    covered_fixture: []const u8,
    mode: []const u8,
    validation: Validation,
    proof: []const u8 = "integrated Zig build-obj object path plus Zig build-exe native link",
    fallback: []const u8,
};

const SurfaceCounter = struct {
    name: []const u8,
    count: usize = 0,
};

const release_fixture_roots = [_][]const u8{
    "test/distribution/releasefast_x86_64/inputs",
    "test/distribution/releasesafe_x86_64/inputs",
    "test/distribution/releasesmall_x86_64/inputs",
    "test/distribution/releasesmall_x86_64/exclusions",
};

const SourceFixtureSkip = struct {
    path: []const u8,
    reason: []const u8,
};

const source_fixture_skips = [_]SourceFixtureSkip{};

const cases = [_]Case{
    .{
        .id = "releasefast_tiny_scalar",
        .wrapper = "test/zig/integrated/tiny_scalar_main.zig",
        .covered_fixture = "test/zig/inputs/tiny_scalar.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasefast_source_tiny_scalar",
        .wrapper = "test/zig/integrated/tiny_scalar_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/tiny_scalar.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:tiny-scalar",
    },
    .{
        .id = "releasefast_integers",
        .wrapper = "test/zig/integrated/integers_main.zig",
        .covered_fixture = "test/zig/inputs/integers.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasefast_source_integers_add_wrap",
        .wrapper = "test/zig/integrated/integers_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/integers_add_wrap.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:integers-add-wrap",
    },
    .{
        .id = "releasefast_source_integers_cmp_shift",
        .wrapper = "test/zig/integrated/integers_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/integers_cmp_shift.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:integers-cmp-shift",
    },
    .{
        .id = "releasefast_control_flow_calls",
        .wrapper = "test/zig/integrated/control_flow_calls_main.zig",
        .covered_fixture = "test/zig/inputs/control_flow_calls.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasefast_source_control_flow_loop_sum",
        .wrapper = "test/zig/integrated/runtime_loop_sum_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/control_flow_calls_loop_sum.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:control-flow-loop-sum",
    },
    .{
        .id = "releasefast_source_control_flow_call_chain",
        .wrapper = "test/zig/integrated/control_flow_calls_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/control_flow_calls_call_chain.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:control-flow-call-chain",
    },
    .{
        .id = "releasefast_globals_comptime",
        .wrapper = "test/zig/integrated/globals_comptime_main.zig",
        .covered_fixture = "test/zig/inputs/globals_comptime.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasesafe_runtime_read_global",
        .wrapper = "test/zig/integrated/globals_comptime_main.zig",
        .covered_fixture = "test/zig/inputs/globals_comptime.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasefast_error_switch",
        .wrapper = "test/zig/integrated/error_switch_main.zig",
        .covered_fixture = "test/zig/inputs/error_switch.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasefast_source_error_switch_error_switch",
        .wrapper = "test/zig/integrated/error_switch_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/error_switch_error_switch.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:error-switch",
    },
    .{
        .id = "releasefast_runtime_cond_branch",
        .wrapper = "test/zig/integrated/runtime_cond_branch_main.zig",
        .covered_fixture = "test/zig/inputs/switch_control.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasefast_source_switch_branch_mix",
        .wrapper = "test/zig/integrated/runtime_cond_branch_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/switch_control_branch_mix.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:switch-branch-mix",
    },
    .{
        .id = "releasefast_runtime_phi_merge",
        .wrapper = "test/zig/integrated/runtime_phi_merge_main.zig",
        .covered_fixture = "test/zig/inputs/switch_control.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasefast_runtime_loop_sum",
        .wrapper = "test/zig/integrated/runtime_loop_sum_main.zig",
        .covered_fixture = "test/zig/inputs/control_flow_calls.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasesafe_runtime_loop_sum",
        .wrapper = "test/zig/integrated/runtime_loop_sum_main.zig",
        .covered_fixture = "test/zig/inputs/control_flow_calls.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasefast_runtime_switch",
        .wrapper = "test/zig/integrated/runtime_switch_main.zig",
        .covered_fixture = "test/zig/inputs/switch_control.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasefast_source_switch_dense",
        .wrapper = "test/zig/integrated/runtime_switch_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/switch_control_dense_switch.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:switch-dense",
    },
    .{
        .id = "releasefast_runtime_global_update",
        .wrapper = "test/zig/integrated/runtime_global_update_main.zig",
        .covered_fixture = "test/zig/inputs/globals_comptime.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasefast_runtime_pointer_load_store",
        .wrapper = "test/zig/integrated/runtime_pointer_load_store_main.zig",
        .covered_fixture = "test/zig/inputs/pointers_memory.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-pointer-load-store",
    },
    .{
        .id = "releasefast_source_pointers_memory",
        .wrapper = "test/zig/integrated/runtime_pointer_load_store_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/pointers_memory_basic.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:pointers-memory",
    },
    .{
        .id = "releasefast_runtime_volatile_roundtrip",
        .wrapper = "test/zig/integrated/runtime_volatile_roundtrip_main.zig",
        .covered_fixture = "test/zig/inputs/pointers_memory.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-volatile-roundtrip",
    },
    .{
        .id = "releasefast_runtime_optional_pointer",
        .wrapper = "test/zig/integrated/runtime_optional_pointer_main.zig",
        .covered_fixture = "test/zig/inputs/optional_pointer.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-optional-pointer",
    },
    .{
        .id = "releasefast_source_optional_pointer_value",
        .wrapper = "test/zig/integrated/runtime_optional_pointer_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/optional_pointer_value.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:optional-pointer-value",
    },
    .{
        .id = "releasefast_runtime_packed_read_flag",
        .wrapper = "test/zig/integrated/runtime_packed_read_flag_main.zig",
        .covered_fixture = "test/zig/inputs/packed_bits.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-packed-read-flag",
    },
    .{
        .id = "releasefast_source_packed_bits_basic_read_flag",
        .wrapper = "test/zig/integrated/runtime_packed_read_flag_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/packed_bits_basic.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:packed-bits-read-flag",
    },
    .{
        .id = "releasefast_runtime_packed_replace_low",
        .wrapper = "test/zig/integrated/runtime_packed_replace_low_main.zig",
        .covered_fixture = "test/zig/inputs/packed_bits.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-packed-replace-low",
    },
    .{
        .id = "releasefast_source_packed_bits_basic_replace_low",
        .wrapper = "test/zig/integrated/runtime_packed_replace_low_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/packed_bits_basic.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:packed-bits-replace-low",
    },
    .{
        .id = "releasefast_runtime_struct_sum",
        .wrapper = "test/zig/integrated/runtime_struct_sum_main.zig",
        .covered_fixture = "test/zig/inputs/aggregates.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-struct-field-sum",
    },
    .{
        .id = "releasefast_source_aggregates_struct_sum",
        .wrapper = "test/zig/integrated/runtime_struct_sum_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/aggregates_struct_sum.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:aggregates-struct-sum",
    },
    .{
        .id = "releasefast_runtime_array_sum",
        .wrapper = "test/zig/integrated/runtime_array_sum_main.zig",
        .covered_fixture = "test/zig/inputs/aggregates.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-array-scalar-sum",
    },
    .{
        .id = "releasefast_source_aggregates_array_sum",
        .wrapper = "test/zig/integrated/runtime_array_sum_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/aggregates_array_sum.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:aggregates-array-sum",
    },
    .{
        .id = "releasefast_runtime_optional_payload",
        .wrapper = "test/zig/integrated/runtime_optional_payload_main.zig",
        .covered_fixture = "test/zig/inputs/aggregates.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-optional-scalar-payload",
    },
    .{
        .id = "releasefast_source_aggregates_optional_payload",
        .wrapper = "test/zig/integrated/runtime_optional_payload_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/aggregates_optional_payload.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:aggregates-optional-payload",
    },
    .{
        .id = "releasefast_runtime_error_union_payload",
        .wrapper = "test/zig/integrated/runtime_error_union_payload_main.zig",
        .covered_fixture = "test/zig/inputs/aggregates.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-error-union-payload",
    },
    .{
        .id = "releasefast_source_aggregates_error_union_payload",
        .wrapper = "test/zig/integrated/runtime_error_union_payload_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/aggregates_error_union_payload.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:aggregates-error-union-payload",
    },
    .{
        .id = "releasefast_runtime_slice_sum",
        .wrapper = "test/zig/integrated/runtime_slice_sum_main.zig",
        .covered_fixture = "test/zig/inputs/aggregates.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-pointer-indexed-slice-sum",
    },
    .{
        .id = "releasefast_source_aggregates_slice_sum",
        .wrapper = "test/zig/integrated/runtime_slice_sum_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/aggregates_slice_sum.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:aggregates-slice-sum",
    },
    .{
        .id = "releasefast_runtime_fp_constants",
        .wrapper = "test/zig/integrated/runtime_fp_constants_main.zig",
        .covered_fixture = "test/zig/inputs/fp_constants.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-fp-literal-return",
    },
    .{
        .id = "releasefast_source_fp_constants_literals",
        .wrapper = "test/zig/integrated/runtime_fp_constants_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/fp_constants_literals.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:fp-constants-literals",
    },
    .{
        .id = "releasefast_runtime_comptime_const",
        .wrapper = "test/zig/integrated/runtime_comptime_const_main.zig",
        .covered_fixture = "test/zig/inputs/globals_comptime.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-comptime-const-mul",
    },
    .{
        .id = "releasefast_source_globals_comptime_const",
        .wrapper = "test/zig/integrated/runtime_comptime_const_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/globals_comptime_const.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:globals-comptime-const",
    },
    .{
        .id = "releasefast_source_globals_comptime_global_counter",
        .wrapper = "test/zig/integrated/runtime_global_update_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/globals_comptime_global_counter.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:globals-comptime-global-counter",
    },
    .{
        .id = "releasefast_runtime_debug_location",
        .wrapper = "test/zig/integrated/runtime_debug_location_main.zig",
        .covered_fixture = "test/zig/inputs/atomics_inline_asm_debug.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-add-imm-return",
    },
    .{
        .id = "releasefast_source_atomics_debug_location",
        .wrapper = "test/zig/integrated/runtime_debug_location_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/atomics_debug_location.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:atomics-debug-location",
    },
    .{
        .id = "releasefast_runtime_call_chain",
        .wrapper = "test/zig/integrated/control_flow_calls_main.zig",
        .covered_fixture = "test/zig/inputs/control_flow_calls.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasefast_runtime_tls_read",
        .wrapper = "test/zig/integrated/runtime_tls_read_main.zig",
        .covered_fixture = "test/zig/inputs/tls_concurrency.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:x86_64-localexec-tls",
    },
    .{
        .id = "releasefast_source_tls_concurrency_counter_read",
        .wrapper = "test/zig/integrated/runtime_tls_read_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/tls_concurrency_counter.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:tls-concurrency-read",
    },
    .{
        .id = "releasefast_runtime_tls_bump",
        .wrapper = "test/zig/integrated/runtime_tls_bump_main.zig",
        .covered_fixture = "test/zig/inputs/tls_concurrency.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:x86_64-localexec-tls",
    },
    .{
        .id = "releasefast_source_tls_concurrency_counter_bump",
        .wrapper = "test/zig/integrated/runtime_tls_bump_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/tls_concurrency_counter.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:tls-concurrency-bump",
    },
    .{
        .id = "releasefast_runtime_atomic_add",
        .wrapper = "test/zig/integrated/runtime_atomic_add_main.zig",
        .covered_fixture = "test/zig/inputs/atomics_inline_asm_debug.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-monotonic-atomicrmw-add",
    },
    .{
        .id = "releasefast_source_atomics_atomic_add",
        .wrapper = "test/zig/integrated/runtime_atomic_add_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/atomics_atomic_add.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:atomics-atomic-add",
    },
    .{
        .id = "releasefast_runtime_inline_asm_barrier",
        .wrapper = "test/zig/integrated/runtime_inline_asm_barrier_main.zig",
        .covered_fixture = "test/zig/inputs/atomics_inline_asm_debug.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-inline-asm-memory-barrier",
    },
    .{
        .id = "releasefast_source_atomics_inline_asm_barrier",
        .wrapper = "test/zig/integrated/runtime_inline_asm_barrier_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/atomics_inline_asm_barrier.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:atomics-inline-asm-barrier",
    },
    .{
        .id = "releasefast_runtime_aggregate_pair",
        .wrapper = "test/zig/integrated/runtime_aggregate_pair_main.zig",
        .covered_fixture = "test/zig/inputs/aggregate_abi.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-two-i32-aggregate-abi",
    },
    .{
        .id = "releasefast_source_aggregate_abi_pair",
        .wrapper = "test/zig/integrated/runtime_aggregate_pair_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/aggregate_abi_pair.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:aggregate-abi-pair",
    },
    .{
        .id = "releasefast_runtime_float_less",
        .wrapper = "test/zig/integrated/runtime_float_less_main.zig",
        .covered_fixture = "test/zig/inputs/float_compare.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f32-ordered-less-than",
    },
    .{
        .id = "releasefast_source_float_compare",
        .wrapper = "test/zig/integrated/runtime_float_less_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/float_compare_basic.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:float-compare",
    },
    .{
        .id = "releasefast_runtime_float_mul",
        .wrapper = "test/zig/integrated/runtime_float_mul_main.zig",
        .covered_fixture = "test/zig/inputs/float_compare.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f64-multiply",
    },
    .{
        .id = "releasefast_runtime_float_add",
        .wrapper = "test/zig/integrated/runtime_float_add_main.zig",
        .covered_fixture = "test/zig/inputs/floats_math.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f32-add",
    },
    .{
        .id = "releasefast_source_floats_math",
        .wrapper = "test/zig/integrated/runtime_float_add_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/floats_math_basic.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:floats-math",
    },
    .{
        .id = "releasefast_runtime_float_select",
        .wrapper = "test/zig/integrated/runtime_float_select_main.zig",
        .covered_fixture = "test/zig/inputs/floats_math.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f64-select",
    },
    .{
        .id = "releasefast_runtime_float_sub",
        .wrapper = "test/zig/integrated/runtime_float_sub_main.zig",
        .covered_fixture = "test/zig/inputs/fp_extended_ops.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f32-subtract",
    },
    .{
        .id = "releasefast_source_fp_extended_ops",
        .wrapper = "test/zig/integrated/runtime_float_sub_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/fp_extended_ops_basic.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:fp-extended-ops",
    },
    .{
        .id = "releasefast_runtime_double_div",
        .wrapper = "test/zig/integrated/runtime_double_div_main.zig",
        .covered_fixture = "test/zig/inputs/fp_extended_ops.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f64-divide",
    },
    .{
        .id = "releasefast_runtime_float_rem",
        .wrapper = "test/zig/integrated/runtime_float_rem_main.zig",
        .covered_fixture = "test/zig/inputs/fp_extended_ops.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f32-remainder",
    },
    .{
        .id = "releasesafe_error_switch",
        .wrapper = "test/zig/integrated/error_switch_main.zig",
        .covered_fixture = "test/zig/inputs/error_switch.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasesafe_source_error_switch_select",
        .wrapper = "test/zig/integrated/error_switch_main.zig",
        .covered_fixture = "test/distribution/releasesafe_x86_64/inputs/error_switch_select.ll",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:error-switch-select",
    },
    .{
        .id = "releasesafe_runtime_debug_location",
        .wrapper = "test/zig/integrated/runtime_debug_location_main.zig",
        .covered_fixture = "test/zig/inputs/atomics_inline_asm_debug.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_source_atomics_debug_location_checked",
        .wrapper = "test/zig/integrated/runtime_debug_location_main.zig",
        .covered_fixture = "test/distribution/releasesafe_x86_64/inputs/atomics_debug_location_checked.ll",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:atomics-debug-location-checked;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_runtime_comptime_const",
        .wrapper = "test/zig/integrated/runtime_comptime_const_main.zig",
        .covered_fixture = "test/zig/inputs/globals_comptime.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_runtime_global_update",
        .wrapper = "test/zig/integrated/runtime_global_update_main.zig",
        .covered_fixture = "test/zig/inputs/globals_comptime.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_source_globals_checked",
        .wrapper = "test/zig/integrated/runtime_global_update_main.zig",
        .covered_fixture = "test/distribution/releasesafe_x86_64/inputs/globals_comptime_checked.ll",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:globals-checked;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_runtime_pointer_load_store",
        .wrapper = "test/zig/integrated/runtime_pointer_load_store_main.zig",
        .covered_fixture = "test/zig/inputs/pointers_memory.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_source_pointers_memory_checked",
        .wrapper = "test/zig/integrated/runtime_pointer_load_store_main.zig",
        .covered_fixture = "test/distribution/releasesafe_x86_64/inputs/pointers_memory_checked.ll",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:pointers-memory-checked;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_runtime_branch_mix",
        .wrapper = "test/zig/integrated/runtime_branch_mix_main.zig",
        .covered_fixture = "test/zig/inputs/switch_control.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_source_switch_branch_mix_checked",
        .wrapper = "test/zig/integrated/runtime_branch_mix_main.zig",
        .covered_fixture = "test/distribution/releasesafe_x86_64/inputs/switch_control_branch_mix_checked.ll",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:switch-branch-mix-checked;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_runtime_call_chain",
        .wrapper = "test/zig/integrated/control_flow_calls_main.zig",
        .covered_fixture = "test/zig/inputs/control_flow_calls.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_source_control_flow_calls_checked",
        .wrapper = "test/zig/integrated/control_flow_calls_main.zig",
        .covered_fixture = "test/distribution/releasesafe_x86_64/inputs/control_flow_calls_checked.ll",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:control-flow-calls-checked;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_runtime_tls_bump",
        .wrapper = "test/zig/integrated/runtime_tls_bump_main.zig",
        .covered_fixture = "test/zig/inputs/tls_concurrency.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:x86_64-localexec-tls;validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_source_tls_concurrency_checked_bump",
        .wrapper = "test/zig/integrated/runtime_tls_bump_main.zig",
        .covered_fixture = "test/distribution/releasesafe_x86_64/inputs/tls_concurrency_checked.ll",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:tls-concurrency-checked-bump;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_runtime_tls_read",
        .wrapper = "test/zig/integrated/runtime_tls_read_main.zig",
        .covered_fixture = "test/zig/inputs/tls_concurrency.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:x86_64-localexec-tls",
    },
    .{
        .id = "releasesafe_source_tls_concurrency_checked_read",
        .wrapper = "test/zig/integrated/runtime_tls_read_main.zig",
        .covered_fixture = "test/distribution/releasesafe_x86_64/inputs/tls_concurrency_checked.ll",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:tls-concurrency-checked-read",
    },
    .{
        .id = "releasesafe_runtime_array_sum",
        .wrapper = "test/zig/integrated/runtime_array_sum_main.zig",
        .covered_fixture = "test/zig/inputs/aggregates.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_source_aggregates_checked_array",
        .wrapper = "test/zig/integrated/runtime_array_sum_main.zig",
        .covered_fixture = "test/distribution/releasesafe_x86_64/inputs/aggregates_checked_sums.ll",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:aggregates-checked-array;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_runtime_struct_sum",
        .wrapper = "test/zig/integrated/runtime_struct_sum_main.zig",
        .covered_fixture = "test/zig/inputs/aggregates.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_source_aggregates_checked_struct",
        .wrapper = "test/zig/integrated/runtime_struct_sum_main.zig",
        .covered_fixture = "test/distribution/releasesafe_x86_64/inputs/aggregates_checked_sums.ll",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:aggregates-checked-struct;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_runtime_slice_sum",
        .wrapper = "test/zig/integrated/runtime_slice_sum_main.zig",
        .covered_fixture = "test/zig/inputs/aggregates.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_source_aggregates_checked_slice",
        .wrapper = "test/zig/integrated/runtime_slice_sum_main.zig",
        .covered_fixture = "test/distribution/releasesafe_x86_64/inputs/aggregates_checked_sums.ll",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:aggregates-checked-slice;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_tiny_scalar_runtime_boundary",
        .wrapper = "test/zig/integrated/tiny_scalar_releasesafe_boundary_main.zig",
        .covered_fixture = "test/zig/inputs/tiny_scalar.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_source_tiny_scalar_checked_add",
        .wrapper = "test/zig/integrated/tiny_scalar_releasesafe_boundary_main.zig",
        .covered_fixture = "test/distribution/releasesafe_x86_64/inputs/tiny_scalar_checked_add.ll",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:tiny-scalar-checked-add;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_runtime_side_effect_free",
        .wrapper = "test/zig/integrated/runtime_side_effect_free_main.zig",
        .covered_fixture = "test/zig/inputs/tiny_scalar.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-void-noop-call",
    },
    .{
        .id = "releasesmall_globals_comptime",
        .wrapper = "test/zig/integrated/globals_comptime_small_main.zig",
        .covered_fixture = "test/zig/inputs/globals_comptime.zig",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasesmall_runtime_hidden_access",
        .wrapper = "test/zig/integrated/runtime_hidden_access_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_extern_exports_hidden_access.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-hidden-global-access",
    },
    .{
        .id = "releasesmall_source_standalone_extern_exports_hidden_access",
        .wrapper = "test/zig/integrated/runtime_hidden_access_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_extern_exports_hidden_access.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:hidden-access",
    },
    .{
        .id = "releasesmall_runtime_mix_c_add_zig",
        .wrapper = "test/zig/integrated/runtime_mix_c_add_zig_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_zig.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-localexec-c-tls-input",
    },
    .{
        .id = "releasesmall_source_standalone_mix_c_files_add_zig",
        .wrapper = "test/zig/integrated/runtime_mix_c_add_zig_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_zig.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:mixed-c-add-zig",
    },
    .{
        .id = "releasesmall_runtime_mix_c_add_may_panic",
        .wrapper = "test/zig/integrated/runtime_mix_c_add_may_panic_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_may_panic.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-panic-edge",
    },
    .{
        .id = "releasesmall_source_standalone_mix_c_files_add_may_panic",
        .wrapper = "test/zig/integrated/runtime_mix_c_add_may_panic_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_may_panic.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:mixed-c-add-may-panic",
    },
    .{
        .id = "releasesmall_runtime_umul_fix_sat_i64",
        .wrapper = "test/zig/integrated/runtime_umul_fix_sat_i64_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/no_compile_panic_for_unchecked_arith_umul_fix_sat_i64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-umul-fix-sat-i64",
    },
    .{
        .id = "releasesmall_source_no_compile_panic_for_unchecked_arith_umul_fix_sat_i64",
        .wrapper = "test/zig/integrated/runtime_umul_fix_sat_i64_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/no_compile_panic_for_unchecked_arith_umul_fix_sat_i64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:umul-fix-sat-i64",
    },
    .{
        .id = "releasesmall_runtime_inherit_want_safety_i64",
        .wrapper = "test/zig/integrated/runtime_inherit_want_safety_i64_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/inherit_want_safety_i64_return.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-inherit-want-safety-i64-return",
    },
    .{
        .id = "releasesmall_source_inherit_want_safety_i64_return",
        .wrapper = "test/zig/integrated/runtime_inherit_want_safety_i64_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/inherit_want_safety_i64_return.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:inherit-want-safety-i64-return",
    },
    .{
        .id = "releasesmall_runtime_compile_asm_unreachable",
        .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_compile_asm_main_unreachable.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-compile-asm-unreachable-stub",
    },
    .{
        .id = "releasesmall_source_standalone_compile_asm_main_unreachable",
        .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_compile_asm_main_unreachable.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:compile-asm-main-unreachable",
    },
    .{
        .id = "releasesmall_source_address_space_start_trampoline",
        .wrapper = "test/zig/integrated/runtime_start_trampoline_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/address_space_start_trampoline.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:address-space-start-trampoline",
    },
    .{
        .id = "releasesmall_source_array_in_anon_struct_getauxval",
        .wrapper = "test/zig/integrated/runtime_getauxval_pointer_walk_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/array_in_anon_struct_getauxval.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:getauxval-pointer-walk",
    },
    .{
        .id = "releasesmall_source_c_abi_main_f128_sret",
        .wrapper = "test/zig/integrated/runtime_f128_sret_byval_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/c_abi_main_f128_sret.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:f128-sret-byval",
    },
    .{
        .id = "releasesmall_source_compile_errors_logical_ptr_elem_ptr",
        .wrapper = "test/zig/integrated/runtime_noreturn_unreachable_stub_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/compile_errors_illegal_operation_on_logical_ptr_elem_ptr.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:logical-pointer-unreachable",
    },
    .{
        .id = "releasesmall_source_export_keyword_vram_store",
        .wrapper = "test/zig/integrated/runtime_address_space_volatile_store_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/export_keyword_vram_store.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:vram-volatile-store",
    },
    .{
        .id = "releasesmall_source_sizeof_typeof_unreachable_stubs",
        .wrapper = "test/zig/integrated/runtime_noreturn_unreachable_stub_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/sizeof_typeof_unreachable_stubs.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:unreachable-stubs",
    },
    .{
        .id = "releasesmall_source_standalone_install_raw_hex_start_loop",
        .wrapper = "test/zig/integrated/runtime_raw_start_loop_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_install_raw_hex_start_loop.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:raw-start-loop",
    },
    .{
        .id = "releasesmall_source_standalone_libfuzzer_runner_futex_wait",
        .wrapper = "test/zig/integrated/runtime_i1_const_return_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_libfuzzer_runner_futex_wait.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:libfuzzer-futex-wait",
    },
    .{
        .id = "releasesmall_source_standalone_libfuzzer_runner_test_name",
        .wrapper = "test/zig/integrated/runtime_constant_string_slice_return_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_libfuzzer_runner_test_name.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:libfuzzer-test-name",
    },
    .{
        .id = "releasesmall_source_standalone_libfuzzer_runner_test_run",
        .wrapper = "test/zig/integrated/runtime_libfuzzer_vtable_run_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_libfuzzer_runner_test_run.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:libfuzzer-test-run",
    },
    .{
        .id = "releasesmall_runtime_str_from_float_help",
        .wrapper = "test/zig/integrated/runtime_str_from_float_help_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_emit_llvm_no_bin_str_from_float_help.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;whole-function:str-from-float-help",
    },
    .{
        .id = "releasesmall_runtime_base64_decode_base_64_full",
        .wrapper = "test/zig/integrated/runtime_base64_decode_base_64_full_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;whole-function:base64-decode-base-64",
    },
    .{
        .id = "releasesmall_runtime_base64_decode_step",
        .wrapper = "test/zig/integrated/runtime_base64_decode_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-decode-step",
    },
    .{
        .id = "releasesmall_runtime_base64_store_step",
        .wrapper = "test/zig/integrated/runtime_base64_store_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-store-step",
    },
    .{
        .id = "releasesmall_runtime_base64_residual_byte_step",
        .wrapper = "test/zig/integrated/runtime_base64_residual_byte_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-byte-step",
    },
    .{
        .id = "releasesmall_runtime_base64_padding_tail_step",
        .wrapper = "test/zig/integrated/runtime_base64_padding_tail_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-padding-tail-step",
    },
    .{
        .id = "releasesmall_runtime_base64_padding_loop_step",
        .wrapper = "test/zig/integrated/runtime_base64_padding_loop_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-padding-loop-step",
    },
    .{
        .id = "releasesmall_runtime_base64_padding_length_step",
        .wrapper = "test/zig/integrated/runtime_base64_padding_length_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-padding-length-step",
    },
    .{
        .id = "releasesmall_runtime_base64_chunk_guard_step",
        .wrapper = "test/zig/integrated/runtime_base64_chunk_guard_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-chunk-guard-step",
    },
    .{
        .id = "releasesmall_runtime_base64_source_stride_step",
        .wrapper = "test/zig/integrated/runtime_base64_source_stride_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-source-stride-step",
    },
    .{
        .id = "releasesmall_runtime_base64_source_bundle_step",
        .wrapper = "test/zig/integrated/runtime_base64_source_bundle_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-source-bundle-step",
    },
    .{
        .id = "releasesmall_runtime_base64_next_source_bundle_step",
        .wrapper = "test/zig/integrated/runtime_base64_next_source_bundle_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-next-source-bundle-step",
    },
    .{
        .id = "releasesmall_runtime_base64_third_source_bundle_step",
        .wrapper = "test/zig/integrated/runtime_base64_third_source_bundle_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-third-source-bundle-step",
    },
    .{
        .id = "releasesmall_runtime_base64_bit_buffer_store_step",
        .wrapper = "test/zig/integrated/runtime_base64_bit_buffer_store_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-bit-buffer-store-step",
    },
    .{
        .id = "releasesmall_runtime_base64_loop_advance_step",
        .wrapper = "test/zig/integrated/runtime_base64_loop_advance_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-loop-advance-step",
    },
    .{
        .id = "releasesmall_runtime_base64_residual_guard_step",
        .wrapper = "test/zig/integrated/runtime_base64_residual_guard_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-guard-step",
    },
    .{
        .id = "releasesmall_runtime_base64_residual_bundle_step",
        .wrapper = "test/zig/integrated/runtime_base64_residual_bundle_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-bundle-step",
    },
    .{
        .id = "releasesmall_runtime_base64_residual_store_step",
        .wrapper = "test/zig/integrated/runtime_base64_residual_store_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-store-step",
    },
    .{
        .id = "releasesmall_runtime_base64_residual_length_step",
        .wrapper = "test/zig/integrated/runtime_base64_residual_length_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-length-step",
    },
    .{
        .id = "releasesmall_runtime_base64_residual_table_check_step",
        .wrapper = "test/zig/integrated/runtime_base64_residual_table_check_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-table-check-step",
    },
    .{
        .id = "releasesmall_runtime_base64_residual_accumulator_step",
        .wrapper = "test/zig/integrated/runtime_base64_residual_accumulator_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-accumulator-step",
    },
    .{
        .id = "releasesmall_runtime_base64_residual_loop_advance_step",
        .wrapper = "test/zig/integrated/runtime_base64_residual_loop_advance_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-loop-advance-step",
    },
    .{
        .id = "releasesmall_runtime_base64_residual_padding_check_step",
        .wrapper = "test/zig/integrated/runtime_base64_residual_padding_check_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-padding-check-step",
    },
    .{
        .id = "releasesmall_runtime_base64_residual_final_mask_step",
        .wrapper = "test/zig/integrated/runtime_base64_residual_final_mask_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-final-mask-step",
    },
    .{
        .id = "releasesmall_runtime_base64_residual_padding_loop_step",
        .wrapper = "test/zig/integrated/runtime_base64_residual_padding_loop_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-padding-loop-step",
    },
    .{
        .id = "releasesmall_runtime_base64_decode_exit_step",
        .wrapper = "test/zig/integrated/runtime_base64_decode_exit_step_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-decode-exit-step",
    },
    .{
        .id = "releasesmall_i64_arithmetic",
        .wrapper = "test/zig/integrated/i64_arithmetic_main.zig",
        .covered_fixture = "test/zig/inputs/i64_arithmetic.zig",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasesmall_runtime_i64_call",
        .wrapper = "test/zig/integrated/i64_arithmetic_main.zig",
        .covered_fixture = "test/zig/inputs/i64_arithmetic.zig",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasesmall_base64_table_lookup",
        .wrapper = "test/zig/integrated/base64_table_lookup_main.zig",
        .covered_fixture = "test/zig/inputs/base64_table_lookup.zig",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
    },
    .{
        .id = "releasesmall_source_base64_table_lookup",
        .wrapper = "test/zig/integrated/base64_table_lookup_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/base64_table_lookup.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:base64-table-lookup",
    },
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();
    var pipeline: Pipeline = .postopt;
    var mode_filter: ?[]const u8 = null;
    var case_filter: ?[]const u8 = null;
    var use_ir_writer = false;
    var broad_source_backed = false;
    var source_wrapper_dispatch = false;
    var release_source_owned = false;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--pipeline=postopt")) {
            pipeline = .postopt;
        } else if (std.mem.eql(u8, arg, "--pipeline=preopt")) {
            pipeline = .preopt;
        } else if (std.mem.eql(u8, arg, "--ir-writer")) {
            use_ir_writer = true;
            pipeline = .preopt;
        } else if (std.mem.eql(u8, arg, "--source-backed-broad")) {
            use_ir_writer = true;
            broad_source_backed = true;
            pipeline = .preopt;
        } else if (std.mem.eql(u8, arg, "--source-wrapper-dispatch")) {
            use_ir_writer = true;
            source_wrapper_dispatch = true;
            pipeline = .preopt;
        } else if (std.mem.eql(u8, arg, "--release-source-owned")) {
            use_ir_writer = true;
            release_source_owned = true;
            pipeline = .preopt;
        } else if (std.mem.startsWith(u8, arg, "--mode=")) {
            mode_filter = arg["--mode=".len..];
        } else if (std.mem.startsWith(u8, arg, "--case=")) {
            case_filter = arg["--case=".len..];
        } else {
            try common.validationError(io, "unexpected argument for integrated object runner: {s}\n", .{arg});
        }
    }

    const target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);
    const zig_source_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "ZIG_SOURCE_DIR");
    defer if (zig_source_env) |value| allocator.free(value);
    const zig_emitter_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "ZIG_EMITTER");
    defer if (zig_emitter_env) |value| allocator.free(value);
    const zllvm_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "ZLLVM_EXE");
    defer if (zllvm_env) |value| allocator.free(value);

    const target = normalizeZigTarget(target_env orelse "x86_64-linux-gnu");
    const zig_source_dir = zig_source_env orelse "../ziglang";
    const default_zig_emitter = try std.fs.path.join(allocator, &.{ zig_source_dir, "build/stage4/bin/zig" });
    defer allocator.free(default_zig_emitter);
    const zig_emitter = zig_emitter_env orelse default_zig_emitter;
    const zllvm_exe = zllvm_env orelse "zig-out/bin/z_llvm";

    const check_argv = [_][]const u8{ "zig", "run", "tools/check_zig_stage4_emitter.zig" };
    const check_result = try common.runCapture(allocator, io, &check_argv, "tools/check_zig_stage4_emitter.zig");
    common.freeRunResult(allocator, check_result);

    const build_argv = [_][]const u8{ "zig", "build" };
    const build_result = try common.runCapture(allocator, io, &build_argv, "zig build");
    common.freeRunResult(allocator, build_result);

    var env_map = std.process.Environ.Map.init(allocator);
    defer env_map.deinit();
    try copyEnvironment(&env_map, init.environ_map);
    if (use_ir_writer) {
        try env_map.put("ZIG_USE_ZLLVM_IR_WRITER", "1");
        try env_map.put("ZLLVM_IR_WRITER_MODE", "external");
    } else {
        try env_map.put("ZIG_USE_ZLLVM_OBJECT", "1");
    }
    try env_map.put("ZLLVM_PIPELINE", pipelineName(pipeline));
    try env_map.put("ZLLVM_EXE", zllvm_exe);

    const temp = try common.TempDir.init(allocator, io, "zig_integrated_object");
    defer temp.deinit(allocator, io);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    var skipped_with_reason: usize = 0;
    if (broad_source_backed or release_source_owned) {
        skipped_with_reason = try validateBroadSourceBackedInventory(allocator, io, &stdout_writer.interface);
    }
    if (release_source_owned) {
        try reportSourceWrapperDiscoveryBucket(allocator, io, &stdout_writer.interface);
    }
    try stdout_writer.interface.print(
        "zig-integrated-object target={s} pipeline={s} linker=zig build-exe -fno-lld hook={s} zllvm={s}\n",
        .{ target, pipelineName(pipeline), if (use_ir_writer) "ZIG_USE_ZLLVM_IR_WRITER" else "ZIG_USE_ZLLVM_OBJECT", zllvm_exe },
    );
    try stdout_writer.interface.flush();
    if (release_source_owned) {
        try runSourceOwnedWrongSourceTagProbe(allocator, io, temp, zig_emitter, target, pipeline, &env_map, &stdout_writer.interface);
    }

    var executable_ok: usize = 0;
    var link_only_ok: usize = 0;
    var total: usize = 0;
    var scalar_runtime_rows: usize = 0;
    var minimal_wrapper_rows: usize = 0;
    var structured_builder_rows: usize = 0;
    var textual_subset_rows: usize = 0;
    var structured_direct_rows: usize = 0;
    var structured_textual_rows: usize = 0;
    var textual_boundary_rows: usize = 0;
    var generic_codegen_rows: usize = 0;
    var case_specific_codegen_rows: usize = 0;
    var source_backed_rows: usize = 0;
    var source_wrapper_rows: usize = 0;
    var release_source_rows: usize = 0;
    var fallback_rows: usize = 0;
    var case_id_rows: usize = 0;
    var manifest_structured_rows: usize = 0;
    var semantic_lowering_rows: usize = 0;
    var semantic_record_rows: usize = 0;
    var descriptor_v2_rows: usize = 0;
    var real_descriptor_program_rows: usize = 0;
    var full_descriptor_program_rows: usize = 0;
    var descriptor_body_name_rows: usize = 0;
    var zllvm_body_expansion_rows: usize = 0;
    var air_derived_descriptor_rows: usize = 0;
    var static_descriptor_map_rows: usize = 0;
    var air_extracted_descriptor_rows: usize = 0;
    var template_descriptor_rows: usize = 0;
    var wrapper_body_map_rows: usize = 0;
    var source_tag_body_map_rows: usize = 0;
    var zig_compile_context_descriptor_rows: usize = 0;
    var env_source_tag_selector_rows: usize = 0;
    var wrapper_body_selector_rows: usize = 0;
    var source_tag_body_selector_rows: usize = 0;
    var fixture_metadata_selector_rows: usize = 0;
    var source_tag_env_present_rows: usize = 0;
    var surface_to_body_adapter_rows: usize = 0;
    var canned_return_descriptor_rows: usize = 0;
    var legacy_semantic_record_rows: usize = 0;
    var external_writer_delegate_rows: usize = 0;
    var descriptor_owned_rows: usize = 0;
    var manual_fixture_dispatch_rows: usize = 0;
    var surface_dispatch_rows: usize = 0;
    var source_derived_descriptor_rows: usize = 0;
    var tag_table_descriptor_rows: usize = 0;
    var body_enum_dispatch_rows: usize = 0;
    var zig_emitted_descriptor_rows: usize = 0;
    var runner_generated_descriptor_rows: usize = 0;
    var descriptor_file_consumed_rows: usize = 0;
    var serialized_function_rows: usize = 0;
    var serialized_instruction_rows: usize = 0;
    var serialized_global_rows: usize = 0;
    var semantic_serialized_rows: usize = 0;
    var serialized_return_stub_rows: usize = 0;
    var descriptor_program_body_expansion_rows: usize = 0;
    var functions_for_body_rows: usize = 0;
    var globals_for_body_rows: usize = 0;
    var surface_counters = [_]SurfaceCounter{
        .{ .name = "scalar-add-ret" },
        .{ .name = "integer-arithmetic" },
        .{ .name = "error-switch-select" },
        .{ .name = "direct-call" },
        .{ .name = "global-load" },
        .{ .name = "i64-arithmetic" },
        .{ .name = "i64-call-return" },
        .{ .name = "table-indexed-load" },
        .{ .name = "checked-add-runtime-boundary" },
        .{ .name = "runtime-condbr" },
        .{ .name = "runtime-phi-merge" },
        .{ .name = "runtime-loop-sum" },
        .{ .name = "checked-loop-sum-boundary" },
        .{ .name = "runtime-switch" },
        .{ .name = "checked-branch-mix-boundary" },
        .{ .name = "global-update" },
        .{ .name = "pointer-load-store" },
        .{ .name = "volatile-roundtrip" },
        .{ .name = "optional-pointer" },
        .{ .name = "packed-read-flag" },
        .{ .name = "packed-replace-low" },
        .{ .name = "struct-field-sum" },
        .{ .name = "array-scalar-sum" },
        .{ .name = "optional-scalar-payload" },
        .{ .name = "error-union-payload" },
        .{ .name = "slice-loop-sum" },
        .{ .name = "fp-literal-return" },
        .{ .name = "comptime-const-mul" },
        .{ .name = "add-imm-return" },
        .{ .name = "checked-add-imm-boundary" },
        .{ .name = "checked-comptime-const-boundary" },
        .{ .name = "checked-global-update-boundary" },
        .{ .name = "checked-pointer-load-store-boundary" },
        .{ .name = "checked-call-chain-boundary" },
        .{ .name = "checked-array-sum-boundary" },
        .{ .name = "checked-struct-sum-boundary" },
        .{ .name = "checked-slice-loop-sum-boundary" },
        .{ .name = "abi-arg-call" },
        .{ .name = "tls-read" },
        .{ .name = "tls-bump" },
        .{ .name = "checked-tls-bump-boundary" },
        .{ .name = "atomic-add" },
        .{ .name = "inline-asm-barrier" },
        .{ .name = "aggregate-pair-abi" },
        .{ .name = "float-less" },
        .{ .name = "float-mul" },
        .{ .name = "float-add" },
        .{ .name = "float-select" },
        .{ .name = "float-sub" },
        .{ .name = "double-div" },
        .{ .name = "float-rem" },
        .{ .name = "void-noop-call" },
        .{ .name = "hidden-global-access" },
        .{ .name = "mixed-c-zig-add" },
        .{ .name = "mixed-c-zig-panic-add" },
        .{ .name = "umul-fix-sat-i64" },
        .{ .name = "inherit-i64-return" },
        .{ .name = "compile-asm-unreachable" },
        .{ .name = "start-trampoline" },
        .{ .name = "getauxval-pointer-walk" },
        .{ .name = "f128-sret-byval" },
        .{ .name = "noreturn-unreachable-stub" },
        .{ .name = "address-space-volatile-store" },
        .{ .name = "raw-start-loop" },
        .{ .name = "i1-const-return" },
        .{ .name = "constant-string-slice-return" },
        .{ .name = "libfuzzer-vtable-run" },
        .{ .name = "str-from-float-help" },
        .{ .name = "base64-decode-base64-full" },
        .{ .name = "base64-decode-step" },
        .{ .name = "base64-store-step" },
        .{ .name = "base64-residual-byte-step" },
        .{ .name = "base64-padding-tail-step" },
        .{ .name = "base64-padding-loop-step" },
        .{ .name = "base64-padding-length-step" },
        .{ .name = "base64-chunk-guard-step" },
        .{ .name = "base64-source-stride-step" },
        .{ .name = "base64-source-bundle-step" },
        .{ .name = "base64-next-source-bundle-step" },
        .{ .name = "base64-third-source-bundle-step" },
        .{ .name = "base64-bit-buffer-store-step" },
        .{ .name = "base64-loop-advance-step" },
        .{ .name = "base64-residual-guard-step" },
        .{ .name = "base64-residual-bundle-step" },
        .{ .name = "base64-residual-store-step" },
        .{ .name = "base64-residual-length-step" },
        .{ .name = "base64-residual-table-check-step" },
        .{ .name = "base64-residual-accumulator-step" },
        .{ .name = "base64-residual-loop-advance-step" },
        .{ .name = "base64-residual-padding-check-step" },
        .{ .name = "base64-residual-final-mask-step" },
        .{ .name = "base64-residual-padding-loop-step" },
        .{ .name = "base64-decode-exit-step" },
        .{ .name = "minimal-ret0" },
    };
    for (cases) |case| {
        if (broad_source_backed and !isReleaseDistributionFixture(case.covered_fixture)) continue;
        if (release_source_owned and !isReleaseSourceOwnedCase(case)) continue;
        if (source_wrapper_dispatch and !isSourceWrapperDispatchCase(case)) continue;
        if (mode_filter) |filter| {
            if (!std.mem.eql(u8, filter, case.mode)) continue;
        }
        if (case_filter) |filter| {
            if (!std.mem.eql(u8, filter, case.id)) continue;
        }
        try requirePairing(case);
        total += 1;
        if (broad_source_backed) source_backed_rows += 1;
        if (release_source_owned) {
            release_source_rows += 1;
            source_wrapper_rows += 1;
        } else if (source_wrapper_dispatch) {
            source_wrapper_rows += 1;
        }
        const exe = try common.allocTempFile(allocator, temp, case.id, "_integrated");
        defer allocator.free(exe);
        const object = try common.allocTempFile(allocator, temp, case.id, ".o");
        defer allocator.free(object);
        const ir_path = try common.allocTempFile(allocator, temp, case.id, ".external.ll");
        defer allocator.free(ir_path);
        const marker = try common.allocTempFile(allocator, temp, case.id, "_zllvm_marker.txt");
        defer allocator.free(marker);
        const descriptor_path = try common.allocTempFile(allocator, temp, case.id, ".semantic_descriptor");
        defer allocator.free(descriptor_path);
        try env_map.put("ZLLVM_MARKER_PATH", marker);
        try env_map.put("ZLLVM_ZIG_MODE", case.mode);
        const use_source_dispatch = source_wrapper_dispatch or release_source_owned;
        try env_map.put("ZLLVM_CASE_ID", if (use_source_dispatch) source_wrapper_dispatch_case_id else case.id);
        try env_map.put("ZLLVM_WRAPPER", case.wrapper);
        if (source_wrapper_dispatch) try env_map.put("ZLLVM_IR_WRITER_DISPATCH", "source-wrapper");
        if (release_source_owned) {
            try env_map.put("ZLLVM_IR_WRITER_DISPATCH", "source-owned");
            try env_map.put("ZLLVM_SOURCE_FIXTURE", case.covered_fixture);
            try env_map.put("ZLLVM_SEMANTIC_DESCRIPTOR_PATH", descriptor_path);
        }
        if (use_ir_writer) try env_map.put("ZLLVM_IR_PATH", ir_path);
        try buildIntegratedObject(allocator, io, zig_emitter, target, object, case, &env_map);
        if (release_source_owned) {
            const descriptor_emitter = try readDescriptorInputValue(allocator, io, descriptor_path, case, "descriptor_emitter");
            defer allocator.free(descriptor_emitter);
            if (std.mem.eql(u8, descriptor_emitter, "patched-zig-hook")) {
                zig_emitted_descriptor_rows += 1;
            } else if (std.mem.eql(u8, descriptor_emitter, "zllvm-runner")) {
                runner_generated_descriptor_rows += 1;
                try common.validationError(io, "release source-owned row {s} used runner-generated descriptor: descriptor_emitter={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, descriptor_emitter, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
            } else {
                try common.validationError(io, "release source-owned row {s} did not receive a patched Zig emitted descriptor: descriptor_emitter={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, descriptor_emitter, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
            }
        }
        try requireHookMarker(allocator, io, marker, case, pipeline, use_ir_writer, if (use_ir_writer) ir_path else null, if (use_source_dispatch) source_wrapper_dispatch_case_id else case.id);
        const surface = if (use_ir_writer) try readIrWriterSurface(allocator, io, ir_path, case) else "-";
        const construction = if (use_ir_writer) try readIrWriterConstruction(allocator, io, ir_path, case) else "-";
        defer if (use_ir_writer) allocator.free(construction);
        const llvm_text_parse = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_ir_writer_llvm_text_parse = \"", "zllvm_ir_writer_llvm_text_parse") else "-";
        defer if (use_ir_writer) allocator.free(llvm_text_parse);
        const codegen_ownership = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_ir_writer_codegen = \"", "zllvm_ir_writer_codegen") else "-";
        defer if (use_ir_writer) allocator.free(codegen_ownership);
        const writer_dispatch = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_ir_writer_dispatch = \"", "zllvm_ir_writer_dispatch") else "-";
        defer if (use_ir_writer) allocator.free(writer_dispatch);
        const writer_case_id = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_ir_writer_case = \"", "zllvm_ir_writer_case") else "-";
        defer if (use_ir_writer) allocator.free(writer_case_id);
        const lowering_ownership = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_ir_writer_lowering = \"", "zllvm_ir_writer_lowering") else "-";
        defer if (use_ir_writer) allocator.free(lowering_ownership);
        const semantic_descriptor = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_semantic_descriptor = \"", "zllvm_semantic_descriptor") else "-";
        defer if (use_ir_writer) allocator.free(semantic_descriptor);
        const semantic_descriptor_version = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_semantic_descriptor_version = \"", "zllvm_semantic_descriptor_version") else "-";
        defer if (use_ir_writer) allocator.free(semantic_descriptor_version);
        const descriptor_program = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_descriptor_program = \"", "zllvm_descriptor_program") else "-";
        defer if (use_ir_writer) allocator.free(descriptor_program);
        const full_descriptor_program = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_full_descriptor_program = \"", "zllvm_full_descriptor_program") else "-";
        defer if (use_ir_writer) allocator.free(full_descriptor_program);
        const descriptor_body_name = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_descriptor_body_name = \"", "zllvm_descriptor_body_name") else "-";
        defer if (use_ir_writer) allocator.free(descriptor_body_name);
        const zllvm_body_expansion = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_body_expansion = \"", "zllvm_body_expansion") else "-";
        defer if (use_ir_writer) allocator.free(zllvm_body_expansion);
        const serialized_functions = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_serialized_functions = \"", "zllvm_serialized_functions") else "-";
        defer if (use_ir_writer) allocator.free(serialized_functions);
        const serialized_instructions = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_serialized_instructions = \"", "zllvm_serialized_instructions") else "-";
        defer if (use_ir_writer) allocator.free(serialized_instructions);
        const serialized_globals = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_serialized_globals = \"", "zllvm_serialized_globals") else "-";
        defer if (use_ir_writer) allocator.free(serialized_globals);
        const serialized_return_i32 = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_serialized_return_i32 = \"", "zllvm_serialized_return_i32") else "-";
        defer if (use_ir_writer) allocator.free(serialized_return_i32);
        const descriptor_program_body_expansion = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_descriptor_program_body_expansion = \"", "zllvm_descriptor_program_body_expansion") else "-";
        defer if (use_ir_writer) allocator.free(descriptor_program_body_expansion);
        const functions_for_body = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_functions_for_body = \"", "zllvm_functions_for_body") else "-";
        defer if (use_ir_writer) allocator.free(functions_for_body);
        const globals_for_body = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_globals_for_body = \"", "zllvm_globals_for_body") else "-";
        defer if (use_ir_writer) allocator.free(globals_for_body);
        const air_derived_descriptor = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_air_derived_descriptor = \"", "zllvm_air_derived_descriptor") else "-";
        defer if (use_ir_writer) allocator.free(air_derived_descriptor);
        const static_descriptor_map = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_static_descriptor_map = \"", "zllvm_static_descriptor_map") else "-";
        defer if (use_ir_writer) allocator.free(static_descriptor_map);
        const air_extracted_descriptor = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_air_extracted_descriptor = \"", "zllvm_air_extracted_descriptor") else "-";
        defer if (use_ir_writer) allocator.free(air_extracted_descriptor);
        const template_descriptor = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_template_descriptor = \"", "zllvm_template_descriptor") else "-";
        defer if (use_ir_writer) allocator.free(template_descriptor);
        const wrapper_body_map = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_wrapper_body_map = \"", "zllvm_wrapper_body_map") else "-";
        defer if (use_ir_writer) allocator.free(wrapper_body_map);
        const source_tag_body_map = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_source_tag_body_map = \"", "zllvm_source_tag_body_map") else "-";
        defer if (use_ir_writer) allocator.free(source_tag_body_map);
        const zig_compile_context_descriptor = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_zig_compile_context_descriptor = \"", "zllvm_zig_compile_context_descriptor") else "-";
        defer if (use_ir_writer) allocator.free(zig_compile_context_descriptor);
        const env_source_tag_selector = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_env_source_tag_selector = \"", "zllvm_env_source_tag_selector") else "-";
        defer if (use_ir_writer) allocator.free(env_source_tag_selector);
        const wrapper_body_selector = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_wrapper_body_selector = \"", "zllvm_wrapper_body_selector") else "-";
        defer if (use_ir_writer) allocator.free(wrapper_body_selector);
        const source_tag_body_selector = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_source_tag_body_selector = \"", "zllvm_source_tag_body_selector") else "-";
        defer if (use_ir_writer) allocator.free(source_tag_body_selector);
        const fixture_metadata_selector = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_fixture_metadata_selector = \"", "zllvm_fixture_metadata_selector") else "-";
        defer if (use_ir_writer) allocator.free(fixture_metadata_selector);
        const source_tag_env_present = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_source_tag_env_present = \"", "zllvm_source_tag_env_present") else "-";
        defer if (use_ir_writer) allocator.free(source_tag_env_present);
        const surface_to_body_adapter = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_surface_to_body_adapter = \"", "zllvm_surface_to_body_adapter") else "-";
        defer if (use_ir_writer) allocator.free(surface_to_body_adapter);
        const canned_return_descriptor = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_canned_return_descriptor = \"", "zllvm_canned_return_descriptor") else "-";
        defer if (use_ir_writer) allocator.free(canned_return_descriptor);
        const manual_fixture_dispatch = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_manual_fixture_dispatch = \"", "zllvm_manual_fixture_dispatch") else "-";
        defer if (use_ir_writer) allocator.free(manual_fixture_dispatch);
        const surface_dispatch = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_surface_dispatch = \"", "zllvm_surface_dispatch") else "-";
        defer if (use_ir_writer) allocator.free(surface_dispatch);
        const source_derived_descriptor = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_source_derived_descriptor = \"", "zllvm_source_derived_descriptor") else "-";
        defer if (use_ir_writer) allocator.free(source_derived_descriptor);
        const tag_table_descriptor = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_tag_table_descriptor = \"", "zllvm_tag_table_descriptor") else "-";
        defer if (use_ir_writer) allocator.free(tag_table_descriptor);
        const body_enum_dispatch = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_body_enum_dispatch = \"", "zllvm_body_enum_dispatch") else "-";
        defer if (use_ir_writer) allocator.free(body_enum_dispatch);
        const zig_emitted_descriptor = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_zig_emitted_descriptor = \"", "zllvm_zig_emitted_descriptor") else "-";
        defer if (use_ir_writer) allocator.free(zig_emitted_descriptor);
        const runner_generated_descriptor = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_runner_generated_descriptor = \"", "zllvm_runner_generated_descriptor") else "-";
        defer if (use_ir_writer) allocator.free(runner_generated_descriptor);
        const descriptor_file_consumed = if (use_ir_writer) try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_descriptor_file_consumed = \"", "zllvm_descriptor_file_consumed") else "-";
        defer if (use_ir_writer) allocator.free(descriptor_file_consumed);
        if (use_ir_writer) {
            if (source_wrapper_dispatch or release_source_owned) {
                const expected_dispatch = if (release_source_owned) "source-owned" else "source-wrapper";
                if (!std.mem.eql(u8, writer_dispatch, expected_dispatch)) {
                    try common.validationError(io, "{s} dispatch row {s} did not report expected dispatch: {s}\n", .{ expected_dispatch, case.id, writer_dispatch });
                }
                if (!std.mem.eql(u8, writer_case_id, source_wrapper_dispatch_case_id)) {
                    case_id_rows += 1;
                }
            }
            if (release_source_owned) {
                if (std.mem.eql(u8, semantic_descriptor, "descriptor-owned")) {
                    descriptor_owned_rows += 1;
                } else {
                    try common.validationError(io, "release source-owned row {s} did not report descriptor ownership: descriptor={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, semantic_descriptor, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (!std.mem.eql(u8, manual_fixture_dispatch, "not-used")) {
                    manual_fixture_dispatch_rows += 1;
                    try common.validationError(io, "release source-owned row {s} used manual fixture dispatch: manual_fixture_dispatch={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, manual_fixture_dispatch, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (std.mem.eql(u8, semantic_descriptor_version, "v2")) {
                    descriptor_v2_rows += 1;
                } else {
                    try common.validationError(io, "release source-owned row {s} did not report descriptor v2 ownership: version={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, semantic_descriptor_version, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (std.mem.eql(u8, descriptor_program, "real")) {
                    real_descriptor_program_rows += 1;
                } else {
                    try common.validationError(io, "release source-owned row {s} did not report a real descriptor program: descriptor_program={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, descriptor_program, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (std.mem.eql(u8, full_descriptor_program, "used")) {
                    full_descriptor_program_rows += 1;
                } else {
                    try common.validationError(io, "release source-owned row {s} did not consume a full typed descriptor program: full_descriptor_program={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, full_descriptor_program, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (!std.mem.eql(u8, descriptor_body_name, "not-used")) {
                    descriptor_body_name_rows += 1;
                    try common.validationError(io, "release source-owned row {s} used descriptor body-name payload: descriptor_body_name={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, descriptor_body_name, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (!std.mem.eql(u8, zllvm_body_expansion, "not-used")) {
                    zllvm_body_expansion_rows += 1;
                    try common.validationError(io, "release source-owned row {s} expanded a descriptor body name in z_llvm: zllvm_body_expansion={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, zllvm_body_expansion, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (std.mem.eql(u8, serialized_functions, "used")) {
                    serialized_function_rows += 1;
                } else {
                    try common.validationError(io, "release source-owned row {s} did not parse serialized function records: serialized_functions={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, serialized_functions, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (std.mem.eql(u8, serialized_instructions, "used")) {
                    serialized_instruction_rows += 1;
                } else {
                    try common.validationError(io, "release source-owned row {s} did not parse serialized instruction records: serialized_instructions={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, serialized_instructions, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (std.mem.eql(u8, serialized_globals, "used")) {
                    serialized_global_rows += 1;
                } else {
                    try common.validationError(io, "release source-owned row {s} did not parse serialized global records: serialized_globals={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, serialized_globals, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (!std.mem.eql(u8, descriptor_program_body_expansion, "not-used")) {
                    descriptor_program_body_expansion_rows += 1;
                    try common.validationError(io, "release source-owned row {s} expanded descriptor_program_body: descriptor_program_body_expansion={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, descriptor_program_body_expansion, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (!std.mem.eql(u8, functions_for_body, "not-used")) {
                    functions_for_body_rows += 1;
                    try common.validationError(io, "release source-owned row {s} reached functionsForBody: functions_for_body={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, functions_for_body, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (!std.mem.eql(u8, globals_for_body, "not-used")) {
                    globals_for_body_rows += 1;
                    try common.validationError(io, "release source-owned row {s} reached globalsForBody: globals_for_body={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, globals_for_body, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (std.mem.eql(u8, air_derived_descriptor, "used")) {
                    air_derived_descriptor_rows += 1;
                    if (std.mem.eql(u8, serialized_return_i32, "-1")) {
                        semantic_serialized_rows += 1;
                    } else {
                        serialized_return_stub_rows += 1;
                        try common.validationError(io, "release source-owned AIR-derived row {s} used serialized return stub instead of semantic records: serialized_return_i32={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, serialized_return_i32, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                    }
                }
                if (std.mem.eql(u8, static_descriptor_map, "used")) {
                    static_descriptor_map_rows += 1;
                }
                if (std.mem.eql(u8, air_extracted_descriptor, "used")) {
                    air_extracted_descriptor_rows += 1;
                }
                if (std.mem.eql(u8, template_descriptor, "used")) {
                    template_descriptor_rows += 1;
                }
                if (std.mem.eql(u8, wrapper_body_map, "used")) {
                    wrapper_body_map_rows += 1;
                }
                if (std.mem.eql(u8, source_tag_body_map, "used")) {
                    source_tag_body_map_rows += 1;
                }
                if (std.mem.eql(u8, zig_compile_context_descriptor, "used")) {
                    zig_compile_context_descriptor_rows += 1;
                } else {
                    try common.validationError(io, "release source-owned row {s} did not report Zig compile-context descriptor extraction: zig_compile_context_descriptor={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, zig_compile_context_descriptor, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (!std.mem.eql(u8, env_source_tag_selector, "not-used")) {
                    env_source_tag_selector_rows += 1;
                    try common.validationError(io, "release source-owned row {s} used env source-tag descriptor selection: env_source_tag_selector={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, env_source_tag_selector, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (!std.mem.eql(u8, wrapper_body_selector, "not-used")) {
                    wrapper_body_selector_rows += 1;
                    try common.validationError(io, "release source-owned row {s} used wrapper body descriptor selection: wrapper_body_selector={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, wrapper_body_selector, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (!std.mem.eql(u8, source_tag_body_selector, "not-used")) {
                    source_tag_body_selector_rows += 1;
                    try common.validationError(io, "release source-owned row {s} used source-tag body descriptor selection: source_tag_body_selector={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, source_tag_body_selector, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (!std.mem.eql(u8, fixture_metadata_selector, "not-used")) {
                    fixture_metadata_selector_rows += 1;
                    try common.validationError(io, "release source-owned row {s} used fixture metadata descriptor selection: fixture_metadata_selector={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, fixture_metadata_selector, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (!std.mem.eql(u8, source_tag_env_present, "not-present")) {
                    source_tag_env_present_rows += 1;
                    try common.validationError(io, "release source-owned row {s} received deprecated ZLLVM_SOURCE_TAG env: source_tag_env_present={s} wrapper={s} fixture={s} mode={s}\n", .{ case.id, source_tag_env_present, case.wrapper, case.covered_fixture, case.mode });
                }
                const row_air_extracted = std.mem.eql(u8, air_extracted_descriptor, "used");
                const row_template = std.mem.eql(u8, template_descriptor, "used");
                const row_wrapper_body_map = std.mem.eql(u8, wrapper_body_map, "used");
                const row_source_tag_body_map = std.mem.eql(u8, source_tag_body_map, "used");
                if ((row_air_extracted == row_template) or
                    (row_template and (row_wrapper_body_map == row_source_tag_body_map)) or
                    (row_air_extracted and (row_wrapper_body_map or row_source_tag_body_map)))
                {
                    try common.validationError(io, "release source-owned row {s} has ambiguous descriptor provenance: air_extracted={s} template={s} wrapper_body_map={s} source_tag_body_map={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, air_extracted_descriptor, template_descriptor, wrapper_body_map, source_tag_body_map, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (!std.mem.eql(u8, surface_to_body_adapter, "not-used")) {
                    surface_to_body_adapter_rows += 1;
                    try common.validationError(io, "release source-owned row {s} used surface-to-body adapter: surface_to_body_adapter={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, surface_to_body_adapter, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (!std.mem.eql(u8, canned_return_descriptor, "not-used")) {
                    canned_return_descriptor_rows += 1;
                    try common.validationError(io, "release source-owned row {s} used a canned return descriptor: canned_return_descriptor={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, canned_return_descriptor, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (!std.mem.eql(u8, surface_dispatch, "not-used")) {
                    surface_dispatch_rows += 1;
                    try common.validationError(io, "release source-owned row {s} used surface dispatch: surface_dispatch={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, surface_dispatch, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (std.mem.eql(u8, source_derived_descriptor, "used")) {
                    source_derived_descriptor_rows += 1;
                } else {
                    try common.validationError(io, "release source-owned row {s} did not consume a source-derived descriptor: source_derived_descriptor={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, source_derived_descriptor, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (!std.mem.eql(u8, tag_table_descriptor, "not-used")) {
                    tag_table_descriptor_rows += 1;
                    try common.validationError(io, "release source-owned row {s} used tag-table descriptor lookup: tag_table_descriptor={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, tag_table_descriptor, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (!std.mem.eql(u8, body_enum_dispatch, "not-used")) {
                    body_enum_dispatch_rows += 1;
                    try common.validationError(io, "release source-owned row {s} used body-enum descriptor dispatch: body_enum_dispatch={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, body_enum_dispatch, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (std.mem.eql(u8, descriptor_file_consumed, "used")) {
                    descriptor_file_consumed_rows += 1;
                } else {
                    try common.validationError(io, "release source-owned row {s} did not report descriptor file consumption: descriptor_file_consumed={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, descriptor_file_consumed, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (!std.mem.eql(u8, zig_emitted_descriptor, "used")) {
                    try common.validationError(io, "release source-owned row {s} did not report Zig-emitted descriptor input: zig_emitted_descriptor={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, zig_emitted_descriptor, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
                if (!std.mem.eql(u8, runner_generated_descriptor, "not-used")) {
                    runner_generated_descriptor_rows += 1;
                    try common.validationError(io, "release source-owned row {s} reported runner-generated descriptor input: runner_generated_descriptor={s} wrapper={s} fixture={s} mode={s} source_tag={s}\n", .{ case.id, runner_generated_descriptor, case.wrapper, case.covered_fixture, case.mode, sourceMetadataTag(case.fallback) });
                }
            }
            countSurface(&surface_counters, surface);
            if (std.mem.eql(u8, surface, "minimal-ret0")) {
                minimal_wrapper_rows += 1;
            } else {
                scalar_runtime_rows += 1;
            }
            if (std.mem.eql(u8, construction, "ir-construction=zllvm-structured-builder")) {
                structured_builder_rows += 1;
                if (std.mem.eql(u8, lowering_ownership, "lowering=zig-semantic-records")) {
                    semantic_lowering_rows += 1;
                    semantic_record_rows += 1;
                    if (release_source_owned) legacy_semantic_record_rows += 1;
                } else if (std.mem.eql(u8, lowering_ownership, "lowering=semantic-descriptor-v2")) {
                    semantic_lowering_rows += 1;
                } else if (std.mem.eql(u8, lowering_ownership, "lowering=manifest-structured")) {
                    manifest_structured_rows += 1;
                } else if (std.mem.eql(u8, lowering_ownership, "lowering=external-writer-delegate")) {
                    external_writer_delegate_rows += 1;
                } else {
                    try common.validationError(io, "external IR writer selected row {s} reported unsupported structured lowering ownership: {s}\n", .{ case.id, lowering_ownership });
                }
                if (std.mem.eql(u8, llvm_text_parse, "not-used")) {
                    structured_direct_rows += 1;
                    if (std.mem.eql(u8, codegen_ownership, "codegen=generic-x86_64-lowering")) {
                        generic_codegen_rows += 1;
                    } else if (std.mem.eql(u8, codegen_ownership, "codegen=case-specific-x86_64-lowering")) {
                        case_specific_codegen_rows += 1;
                    } else {
                        try common.validationError(io, "external IR writer structured-direct row {s} reported unsupported codegen ownership: {s}\n", .{ case.id, codegen_ownership });
                    }
                } else {
                    structured_textual_rows += 1;
                }
            } else if (std.mem.eql(u8, construction, "ir-construction=z_llvm-external-textual-subset")) {
                textual_subset_rows += 1;
                textual_boundary_rows += 1;
            } else {
                try common.validationError(io, "external IR writer selected row {s} reported unsupported construction ownership: {s}\n", .{ case.id, construction });
            }
        }
        const fallback = effectiveFallback(case, use_ir_writer);
        if (broad_source_backed and !std.mem.startsWith(u8, fallback, "ir-construction:zllvm-structured-builder")) {
            fallback_rows += 1;
        }
        if (release_source_owned and (!std.mem.startsWith(u8, fallback, "ir-construction:zllvm-structured-builder") or !std.mem.eql(u8, construction, "ir-construction=zllvm-structured-builder"))) {
            fallback_rows += 1;
        }
        if (source_wrapper_dispatch and (!std.mem.startsWith(u8, fallback, "ir-construction:zllvm-structured-builder") or !std.mem.eql(u8, construction, "ir-construction=zllvm-structured-builder"))) {
            fallback_rows += 1;
        }
        if (use_ir_writer) try requireSelectedIrWriterOwnership(io, case, fallback, surface, construction);
        try linkIntegratedObject(allocator, io, target, object, exe, case);
        if (case.validation == .executable) {
            try runExecutableCase(allocator, io, exe, case, use_ir_writer);
            executable_ok += 1;
        } else {
            link_only_ok += 1;
        }
        try stdout_writer.interface.print(
            "ok zig-integrated-object {s} wrapper={s} covered_fixture={s} mode={s} proof=\"{s}\" validation={s} fallback={s} construction={s} llvm_text_parse={s} codegen_ownership={s} lowering_ownership={s} ownership={s} ir_writer_surface={s}\n",
            .{ case.id, case.wrapper, case.covered_fixture, case.mode, effectiveProof(use_ir_writer), validationName(case.validation), fallback, construction, llvm_text_parse, codegen_ownership, lowering_ownership, ownershipProof(use_ir_writer), surface },
        );
        try stdout_writer.interface.flush();
    }

    if (use_ir_writer) {
        if (minimal_wrapper_rows != 0) {
            try common.validationError(io, "external IR writer selected rows must not use minimal-ret0; minimal_wrapper_rows={}\n", .{minimal_wrapper_rows});
        }
        if (!broad_source_backed and !release_source_owned and total == expected_selected_ir_writer_rows and structured_direct_rows != expected_selected_ir_writer_rows) {
            try common.validationError(io, "external IR writer selected rows must all be structured-direct at total={}; structured_direct_rows={}\n", .{ expected_selected_ir_writer_rows, structured_direct_rows });
        }
        if (structured_textual_rows != 0) {
            try common.validationError(io, "external IR writer structured rows must not use textual LLVM parse; structured_textual_rows={}\n", .{structured_textual_rows});
        }
        if (textual_boundary_rows != 0) {
            try common.validationError(io, "external IR writer selected rows must not keep textual boundary rows; textual_boundary_rows={}\n", .{textual_boundary_rows});
        }
        if (!broad_source_backed and !release_source_owned and total == expected_selected_ir_writer_rows and (generic_codegen_rows != expected_selected_ir_writer_rows or case_specific_codegen_rows != 0)) {
            try common.validationError(io, "external IR writer structured-direct rows must all use generic x86_64 codegen; structured_direct_rows={} generic_codegen_rows={} case_specific_codegen_rows={}\n", .{ structured_direct_rows, generic_codegen_rows, case_specific_codegen_rows });
        }
        if (broad_source_backed) {
            if (source_backed_rows != total) {
                try common.validationError(io, "broad source-backed gate row accounting mismatch: source_backed_rows={} total={}\n", .{ source_backed_rows, total });
            }
            if (source_backed_rows != 90 or skipped_with_reason != 0) {
                try common.validationError(io, "broad source-backed gate requires exact no-skip source fixture closure; source_backed_rows={} skipped_with_reason={}\n", .{ source_backed_rows, skipped_with_reason });
            }
            if (structured_direct_rows != source_backed_rows or generic_codegen_rows != source_backed_rows) {
                try common.validationError(io, "broad source-backed gate requires every accepted row to be structured-direct and generic; source_backed_rows={} structured_direct_rows={} generic_codegen_rows={}\n", .{ source_backed_rows, structured_direct_rows, generic_codegen_rows });
            }
            if (structured_textual_rows != 0 or textual_boundary_rows != 0 or textual_subset_rows != 0 or case_specific_codegen_rows != 0 or fallback_rows != 0) {
                try common.validationError(io, "broad source-backed gate forbids fallback/textual/case-specific rows; structured_textual_rows={} textual_boundary_rows={} textual_subset_rows={} case_specific_codegen_rows={} fallback_rows={}\n", .{ structured_textual_rows, textual_boundary_rows, textual_subset_rows, case_specific_codegen_rows, fallback_rows });
            }
            try stdout_writer.interface.print(
                "summary source-backed-structured target=x86_64 release_modes=ReleaseFast,ReleaseSafe,ReleaseSmall source_backed_rows={} structured_direct_rows={} generic_codegen_rows={} skipped_with_reason={} fallback_rows={} local_fail=0\n",
                .{ source_backed_rows, structured_direct_rows, generic_codegen_rows, skipped_with_reason, fallback_rows },
            );
        }
        if (release_source_owned) {
            if (release_source_rows != total or source_wrapper_rows != total) {
                try common.validationError(io, "release source-owned row accounting mismatch: release_source_rows={} source_wrapper_rows={} total={}\n", .{ release_source_rows, source_wrapper_rows, total });
            }
            if (release_source_rows != expected_release_source_owned_rows or skipped_with_reason != 0) {
                try common.validationError(io, "release source-owned gate requires exact current fixture inventory closure; release_source_rows={} skipped_with_reason={}\n", .{ release_source_rows, skipped_with_reason });
            }
            if (air_extracted_descriptor_rows + template_descriptor_rows != expected_release_source_owned_rows or wrapper_body_map_rows + source_tag_body_map_rows != template_descriptor_rows) {
                try common.validationError(io, "release source-owned descriptor provenance accounting mismatch: air_extracted_descriptor_rows={} template_descriptor_rows={} wrapper_body_map_rows={} source_tag_body_map_rows={}\n", .{ air_extracted_descriptor_rows, template_descriptor_rows, wrapper_body_map_rows, source_tag_body_map_rows });
            }
            if (air_extracted_descriptor_rows != expected_release_source_owned_rows or template_descriptor_rows != 0 or wrapper_body_map_rows != 0 or source_tag_body_map_rows != 0) {
                try common.validationError(io, "release source-owned gate requires extracted descriptor provenance; air_extracted_descriptor_rows={} template_descriptor_rows={} wrapper_body_map_rows={} source_tag_body_map_rows={}\n", .{ air_extracted_descriptor_rows, template_descriptor_rows, wrapper_body_map_rows, source_tag_body_map_rows });
            }
            if (zig_compile_context_descriptor_rows != expected_release_source_owned_rows or env_source_tag_selector_rows != 0 or wrapper_body_selector_rows != 0 or source_tag_body_selector_rows != 0 or fixture_metadata_selector_rows != 0 or source_tag_env_present_rows != 0) {
                try common.validationError(io, "release source-owned gate requires compile-context descriptor provenance; zig_compile_context_descriptor_rows={} env_source_tag_selector_rows={} wrapper_body_selector_rows={} source_tag_body_selector_rows={} fixture_metadata_selector_rows={} source_tag_env_present_rows={}\n", .{ zig_compile_context_descriptor_rows, env_source_tag_selector_rows, wrapper_body_selector_rows, source_tag_body_selector_rows, fixture_metadata_selector_rows, source_tag_env_present_rows });
            }
            if (descriptor_owned_rows != expected_release_source_owned_rows or descriptor_v2_rows != expected_release_source_owned_rows or real_descriptor_program_rows != expected_release_source_owned_rows or full_descriptor_program_rows != expected_release_source_owned_rows or serialized_function_rows != expected_release_source_owned_rows or serialized_instruction_rows != expected_release_source_owned_rows or serialized_global_rows != expected_release_source_owned_rows or semantic_serialized_rows != expected_release_source_owned_rows or serialized_return_stub_rows != 0 or air_derived_descriptor_rows != expected_release_source_owned_rows or static_descriptor_map_rows != 0 or descriptor_body_name_rows != 0 or zllvm_body_expansion_rows != 0 or descriptor_program_body_expansion_rows != 0 or functions_for_body_rows != 0 or globals_for_body_rows != 0 or zig_emitted_descriptor_rows != expected_release_source_owned_rows or runner_generated_descriptor_rows != 0 or descriptor_file_consumed_rows != expected_release_source_owned_rows or source_derived_descriptor_rows != expected_release_source_owned_rows or tag_table_descriptor_rows != 0 or body_enum_dispatch_rows != 0 or surface_to_body_adapter_rows != 0 or canned_return_descriptor_rows != 0 or manual_fixture_dispatch_rows != 0 or legacy_semantic_record_rows != 0 or semantic_record_rows != 0 or external_writer_delegate_rows != 0 or semantic_lowering_rows != expected_release_source_owned_rows or manifest_structured_rows != 0 or case_id_rows != 0 or surface_dispatch_rows != 0 or fallback_rows != 0 or structured_direct_rows != expected_release_source_owned_rows or generic_codegen_rows != expected_release_source_owned_rows or case_specific_codegen_rows != 0) {
                try common.validationError(io, "release source-owned gate requires semantic serialized AIR-derived DescriptorV2 records; release_source_rows={} descriptor_owned_rows={} descriptor_v2_rows={} real_descriptor_program_rows={} full_descriptor_program_rows={} serialized_function_rows={} serialized_instruction_rows={} serialized_global_rows={} semantic_serialized_rows={} serialized_return_stub_rows={} air_derived_descriptor_rows={} static_descriptor_map_rows={} descriptor_body_name_rows={} zllvm_body_expansion_rows={} descriptor_program_body_expansion_rows={} functions_for_body_rows={} globals_for_body_rows={} zig_emitted_descriptor_rows={} runner_generated_descriptor_rows={} descriptor_file_consumed_rows={} source_derived_descriptor_rows={} structured_direct_rows={} generic_codegen_rows={} fallback_rows={}\n", .{ release_source_rows, descriptor_owned_rows, descriptor_v2_rows, real_descriptor_program_rows, full_descriptor_program_rows, serialized_function_rows, serialized_instruction_rows, serialized_global_rows, semantic_serialized_rows, serialized_return_stub_rows, air_derived_descriptor_rows, static_descriptor_map_rows, descriptor_body_name_rows, zllvm_body_expansion_rows, descriptor_program_body_expansion_rows, functions_for_body_rows, globals_for_body_rows, zig_emitted_descriptor_rows, runner_generated_descriptor_rows, descriptor_file_consumed_rows, source_derived_descriptor_rows, structured_direct_rows, generic_codegen_rows, fallback_rows });
            }
            try stdout_writer.interface.print(
                "summary release-source-owned target=x86_64 release_modes=ReleaseFast,ReleaseSafe,ReleaseSmall release_source_rows={} source_wrapper_rows={} descriptor_owned_rows={} descriptor_v2_rows={} real_descriptor_program_rows={} full_descriptor_program_rows={} serialized_function_rows={} serialized_instruction_rows={} serialized_global_rows={} semantic_serialized_rows={} serialized_return_stub_rows={} descriptor_body_name_rows={} zllvm_body_expansion_rows={} descriptor_program_body_expansion_rows={} functions_for_body_rows={} globals_for_body_rows={} air_derived_descriptor_rows={} static_descriptor_map_rows={} air_extracted_descriptor_rows={} template_descriptor_rows={} wrapper_body_map_rows={} source_tag_body_map_rows={} zig_emitted_descriptor_rows={} runner_generated_descriptor_rows={} descriptor_file_consumed_rows={} source_derived_descriptor_rows={} structured_direct_rows={} generic_codegen_rows={} fallback_rows={} local_fail=0\n",
                .{ release_source_rows, source_wrapper_rows, descriptor_owned_rows, descriptor_v2_rows, real_descriptor_program_rows, full_descriptor_program_rows, serialized_function_rows, serialized_instruction_rows, serialized_global_rows, semantic_serialized_rows, serialized_return_stub_rows, descriptor_body_name_rows, zllvm_body_expansion_rows, descriptor_program_body_expansion_rows, functions_for_body_rows, globals_for_body_rows, air_derived_descriptor_rows, static_descriptor_map_rows, air_extracted_descriptor_rows, template_descriptor_rows, wrapper_body_map_rows, source_tag_body_map_rows, zig_emitted_descriptor_rows, runner_generated_descriptor_rows, descriptor_file_consumed_rows, source_derived_descriptor_rows, structured_direct_rows, generic_codegen_rows, fallback_rows },
            );
            try stdout_writer.interface.print(
                "summary release-source-owned-zero tag_table_descriptor_rows={} body_enum_dispatch_rows={} surface_to_body_adapter_rows={} canned_return_descriptor_rows={} manual_fixture_dispatch_rows={} semantic_lowering_rows={} legacy_semantic_record_rows={} semantic_record_rows={} external_writer_delegate_rows={} manifest_structured_rows={} case_id_rows={} surface_dispatch_rows={} case_specific_codegen_rows={} zig_compile_context_descriptor_rows={} env_source_tag_selector_rows={} wrapper_body_selector_rows={} source_tag_body_selector_rows={} fixture_metadata_selector_rows={} source_tag_env_present_rows={} local_fail=0\n",
                .{ tag_table_descriptor_rows, body_enum_dispatch_rows, surface_to_body_adapter_rows, canned_return_descriptor_rows, manual_fixture_dispatch_rows, semantic_lowering_rows, legacy_semantic_record_rows, semantic_record_rows, external_writer_delegate_rows, manifest_structured_rows, case_id_rows, surface_dispatch_rows, case_specific_codegen_rows, zig_compile_context_descriptor_rows, env_source_tag_selector_rows, wrapper_body_selector_rows, source_tag_body_selector_rows, fixture_metadata_selector_rows, source_tag_env_present_rows },
            );
        }
        if (source_wrapper_dispatch) {
            if (source_wrapper_rows != total) {
                try common.validationError(io, "source-wrapper dispatch row accounting mismatch: source_wrappers={} total={}\n", .{ source_wrapper_rows, total });
            }
            if (case_id_rows != 0 or fallback_rows != 0 or structured_direct_rows != source_wrapper_rows or generic_codegen_rows != source_wrapper_rows or case_specific_codegen_rows != 0) {
                try common.validationError(io, "source-wrapper dispatch gate requires no case-id/fallback and all rows structured-direct generic; source_wrappers={} structured_direct_rows={} case_id_rows={} generic_codegen_rows={} case_specific_codegen_rows={} fallback_rows={}\n", .{ source_wrapper_rows, structured_direct_rows, case_id_rows, generic_codegen_rows, case_specific_codegen_rows, fallback_rows });
            }
            if (semantic_lowering_rows == 0 or semantic_lowering_rows + manifest_structured_rows + external_writer_delegate_rows != source_wrapper_rows) {
                try common.validationError(io, "source-wrapper dispatch gate requires complete lowering accounting with at least one semantic row; source_wrappers={} semantic_lowering_rows={} manifest_structured_rows={} external_writer_delegate_rows={}\n", .{ source_wrapper_rows, semantic_lowering_rows, manifest_structured_rows, external_writer_delegate_rows });
            }
            try stdout_writer.interface.print(
                "summary source-wrapper-structured target=x86_64 release_modes=ReleaseFast,ReleaseSafe,ReleaseSmall source_wrappers={} structured_direct_rows={} case_id_rows={} generic_codegen_rows={} manifest_structured_rows={} semantic_lowering_rows={} semantic_record_rows={} external_writer_delegate_rows={} case_specific_rows={} fallback_rows={} local_fail=0\n",
                .{ source_wrapper_rows, structured_direct_rows, case_id_rows, generic_codegen_rows, manifest_structured_rows, semantic_lowering_rows, semantic_record_rows, external_writer_delegate_rows, case_specific_codegen_rows, fallback_rows },
            );
        }
        try stdout_writer.interface.print(
            "summary zig-integrated-object pipeline={s} ir_writer={} total={} executable_ok={} link_only_ok={} scalar_runtime_rows={} structured_builder_rows={} textual_subset_rows={} structured_direct_rows={} structured_textual_rows={} textual_boundary_rows={} generic_codegen_rows={} case_specific_codegen_rows={} manifest_structured_rows={} semantic_lowering_rows={} semantic_record_rows={} external_writer_delegate_rows={} minimal_wrapper_rows={} local_fail=0\n",
            .{ pipelineName(pipeline), use_ir_writer, total, executable_ok, link_only_ok, scalar_runtime_rows, structured_builder_rows, textual_subset_rows, structured_direct_rows, structured_textual_rows, textual_boundary_rows, generic_codegen_rows, case_specific_codegen_rows, manifest_structured_rows, semantic_lowering_rows, semantic_record_rows, external_writer_delegate_rows, minimal_wrapper_rows },
        );
        try stdout_writer.interface.print("ownership-summary structured-direct:{};structured-textual:{};textual-boundary:{};ir-construction=zllvm-structured-builder:{};ir-construction=z_llvm-external-textual-subset:{};llvm-text-parse=not-used-for-structured;{s}\n", .{ structured_direct_rows, structured_textual_rows, textual_boundary_rows, structured_builder_rows, textual_subset_rows, ownershipProof(use_ir_writer) });
        try stdout_writer.interface.print("lowering-summary manifest-structured:{};zig-semantic-records:{};external-writer-delegate:{}\n", .{ manifest_structured_rows, semantic_record_rows, external_writer_delegate_rows });
        try stdout_writer.interface.print("codegen-summary generic-codegen:{};case-specific-codegen:{};textual-boundary-out-of-scope:{}\n", .{ generic_codegen_rows, case_specific_codegen_rows, textual_boundary_rows });
        try stdout_writer.interface.print("surface-counts", .{});
        for (surface_counters) |counter| {
            try stdout_writer.interface.print(" {s}={}", .{ counter.name, counter.count });
        }
        try stdout_writer.interface.writeByte('\n');
    } else {
        try stdout_writer.interface.print(
            "summary zig-integrated-object pipeline={s} ir_writer={} total={} executable_ok={} link_only_ok={} local_fail=0\n",
            .{ pipelineName(pipeline), use_ir_writer, total, executable_ok, link_only_ok },
        );
    }
    try stdout_writer.interface.flush();
}

fn validateBroadSourceBackedInventory(
    allocator: std.mem.Allocator,
    io: std.Io,
    writer: *std.Io.Writer,
) !usize {
    var fixtures: std.ArrayList([]const u8) = .empty;
    defer {
        for (fixtures.items) |fixture| allocator.free(fixture);
        fixtures.deinit(allocator);
    }
    try collectReleaseLlFixtures(allocator, io, &fixtures);
    std.mem.sort([]const u8, fixtures.items, {}, stringLessThan);

    var accepted_fixtures: usize = 0;
    var skipped_with_reason: usize = 0;
    for (fixtures.items) |fixture| {
        if (hasAcceptedSourceBackedCaseForFixture(fixture)) {
            accepted_fixtures += 1;
            continue;
        }
        const reason = sourceFixtureSkipReason(fixture) orelse {
            try common.validationError(io, "broad source-backed gate discovered unclassified release fixture: {s}\n", .{fixture});
        };
        skipped_with_reason += 1;
        try writer.print("skip source-backed-fixture path={s} reason={s}\n", .{ fixture, reason });
    }
    for (source_fixture_skips) |skip| {
        if (!fixtureWasDiscovered(fixtures.items, skip.path)) {
            try common.validationError(io, "broad source-backed gate skip entry does not match a discovered release fixture: {s}\n", .{skip.path});
        }
    }
    try writer.print(
        "source-backed-inventory target=x86_64 release_modes=ReleaseFast,ReleaseSafe,ReleaseSmall discovered_fixtures={} accepted_fixtures={} skipped_with_reason={}\n",
        .{ fixtures.items.len, accepted_fixtures, skipped_with_reason },
    );
    try writer.flush();
    return skipped_with_reason;
}

fn reportSourceWrapperDiscoveryBucket(
    allocator: std.mem.Allocator,
    io: std.Io,
    writer: *std.Io.Writer,
) !void {
    var dir = std.Io.Dir.cwd().openDir(io, "test/zig/integrated", .{ .iterate = true }) catch |err| {
        try common.validationError(io, "failed to open Zig source-wrapper discovery directory: {any}\n", .{err});
    };
    defer dir.close(io);

    var discovered_source_wrappers: usize = 0;
    var descriptor_supported_wrappers: usize = 0;
    var out_of_scope_wrappers: usize = 0;
    var iterator = dir.iterate();
    while (try iterator.next(io)) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".zig")) continue;
        discovered_source_wrappers += 1;
        const wrapper = try std.fmt.allocPrint(allocator, "test/zig/integrated/{s}", .{entry.name});
        defer allocator.free(wrapper);
        if (sourceWrapperHasReleaseFixtureMetadata(wrapper)) {
            descriptor_supported_wrappers += 1;
        } else {
            out_of_scope_wrappers += 1;
        }
    }
    try writer.print(
        "source-wrapper-discovery target=x86_64 release_modes=ReleaseFast,ReleaseSafe,ReleaseSmall discovered_source_wrappers={} descriptor_supported_wrappers={} out_of_scope_wrappers={} unsupported_with_reason=0 source=zig-wrapper-files\n",
        .{ discovered_source_wrappers, descriptor_supported_wrappers, out_of_scope_wrappers },
    );
    try writer.flush();
}

fn sourceWrapperHasReleaseFixtureMetadata(wrapper: []const u8) bool {
    for (cases) |case| {
        if (!isReleaseSourceOwnedCase(case)) continue;
        if (std.mem.eql(u8, case.wrapper, wrapper)) return true;
    }
    return false;
}

fn collectReleaseLlFixtures(
    allocator: std.mem.Allocator,
    io: std.Io,
    fixtures: *std.ArrayList([]const u8),
) !void {
    for (release_fixture_roots) |root| {
        var root_dir = try std.Io.Dir.cwd().openDir(io, root, .{ .iterate = true });
        defer root_dir.close(io);

        var walker = try root_dir.walk(allocator);
        defer walker.deinit();
        while (try walker.next(io)) |entry| {
            if (entry.kind != .file) continue;
            if (!std.mem.endsWith(u8, entry.path, ".ll")) continue;
            try fixtures.append(allocator, try std.fmt.allocPrint(allocator, "{s}/{s}", .{ root, entry.path }));
        }
    }
}

fn hasAcceptedSourceBackedCaseForFixture(path: []const u8) bool {
    for (cases) |case| {
        if (!isReleaseDistributionFixture(case.covered_fixture)) continue;
        if (std.mem.eql(u8, case.covered_fixture, path)) return true;
    }
    return false;
}

fn fixtureWasDiscovered(fixtures: []const []const u8, path: []const u8) bool {
    for (fixtures) |fixture| {
        if (std.mem.eql(u8, fixture, path)) return true;
    }
    return false;
}

fn sourceFixtureSkipReason(path: []const u8) ?[]const u8 {
    for (source_fixture_skips) |skip| {
        if (std.mem.eql(u8, skip.path, path)) return skip.reason;
    }
    return null;
}

fn isReleaseDistributionFixture(path: []const u8) bool {
    if (!std.mem.startsWith(u8, path, "test/distribution/")) return false;
    if (!std.mem.endsWith(u8, path, ".ll")) return false;
    return std.mem.indexOf(u8, path, "releasefast_x86_64/") != null or
        std.mem.indexOf(u8, path, "releasesafe_x86_64/") != null or
        std.mem.indexOf(u8, path, "releasesmall_x86_64/") != null;
}

fn isReleaseSourceOwnedCase(case: Case) bool {
    if (isReleaseDistributionFixture(case.covered_fixture)) return true;
    return std.mem.eql(u8, case.id, "releasefast_globals_comptime") or
        std.mem.eql(u8, case.id, "releasesmall_globals_comptime") or
        std.mem.eql(u8, case.id, "releasesmall_i64_arithmetic") or
        std.mem.eql(u8, case.id, "releasefast_runtime_double_div") or
        std.mem.eql(u8, case.id, "releasefast_runtime_float_mul") or
        std.mem.eql(u8, case.id, "releasefast_runtime_float_rem") or
        std.mem.eql(u8, case.id, "releasefast_runtime_float_select") or
        std.mem.eql(u8, case.id, "releasefast_runtime_phi_merge") or
        std.mem.eql(u8, case.id, "releasesafe_runtime_side_effect_free") or
        std.mem.eql(u8, case.id, "releasefast_runtime_volatile_roundtrip");
}

fn stringLessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.lessThan(u8, lhs, rhs);
}

fn countSurface(counters: []SurfaceCounter, surface: []const u8) void {
    for (counters) |*counter| {
        if (std.mem.eql(u8, counter.name, surface)) {
            counter.count += 1;
            return;
        }
    }
}

fn copyEnvironment(dst: *std.process.Environ.Map, src: *const std.process.Environ.Map) !void {
    const keys = src.keys();
    const values = src.values();
    for (keys, values) |key, value| {
        try dst.put(key, value);
    }
}

fn requirePairing(case: Case) !void {
    if (case.wrapper.len == 0 or case.covered_fixture.len == 0 or case.mode.len == 0 or case.proof.len == 0) {
        return error.MissingFixturePairing;
    }
}

fn isSourceWrapperDispatchCase(case: Case) bool {
    const ids = [_][]const u8{
        "releasefast_source_tiny_scalar",
        "releasefast_source_integers_add_wrap",
        "releasefast_source_control_flow_call_chain",
        "releasefast_source_control_flow_loop_sum",
        "releasefast_source_error_switch_error_switch",
        "releasefast_source_switch_branch_mix",
        "releasefast_runtime_phi_merge",
        "releasefast_source_switch_dense",
        "releasefast_source_globals_comptime_global_counter",
        "releasefast_source_pointers_memory",
        "releasefast_runtime_volatile_roundtrip",
        "releasefast_source_optional_pointer_value",
        "releasefast_source_packed_bits_basic_read_flag",
        "releasefast_source_packed_bits_basic_replace_low",
        "releasefast_source_aggregates_struct_sum",
        "releasefast_source_aggregates_array_sum",
        "releasefast_source_aggregates_optional_payload",
        "releasefast_source_aggregates_error_union_payload",
        "releasefast_source_aggregates_slice_sum",
        "releasefast_source_fp_constants_literals",
        "releasefast_source_globals_comptime_const",
        "releasefast_source_atomics_debug_location",
        "releasefast_source_tls_concurrency_counter_read",
        "releasefast_source_atomics_atomic_add",
        "releasefast_source_atomics_inline_asm_barrier",
        "releasefast_source_aggregate_abi_pair",
        "releasefast_source_float_compare",
        "releasefast_source_floats_math",
        "releasefast_source_fp_extended_ops",
        "releasesafe_source_error_switch_select",
        "releasesafe_source_atomics_debug_location_checked",
        "releasesafe_source_globals_checked",
        "releasesafe_source_pointers_memory_checked",
        "releasesafe_source_switch_branch_mix_checked",
        "releasesafe_source_control_flow_calls_checked",
        "releasesafe_source_tls_concurrency_checked_read",
        "releasesafe_source_aggregates_checked_array",
        "releasesafe_source_aggregates_checked_struct",
        "releasesafe_source_aggregates_checked_slice",
        "releasesafe_source_tiny_scalar_checked_add",
        "releasesmall_source_standalone_extern_exports_hidden_access",
        "releasesmall_source_standalone_mix_c_files_add_zig",
        "releasesmall_source_standalone_mix_c_files_add_may_panic",
        "releasesmall_source_no_compile_panic_for_unchecked_arith_umul_fix_sat_i64",
        "releasesmall_source_inherit_want_safety_i64_return",
        "releasesmall_source_standalone_compile_asm_main_unreachable",
        "releasesmall_runtime_str_from_float_help",
        "releasesmall_runtime_base64_decode_base_64_full",
        "releasesmall_source_base64_table_lookup",
    };
    for (ids) |id| {
        if (std.mem.eql(u8, case.id, id)) return true;
    }
    return false;
}

fn requireHookMarker(
    allocator: std.mem.Allocator,
    io: std.Io,
    marker: []const u8,
    case: Case,
    pipeline: Pipeline,
    use_ir_writer: bool,
    expected_ir_path: ?[]const u8,
    expected_marker_case_id: []const u8,
) !void {
    const contents = std.Io.Dir.cwd().readFileAlloc(io, marker, allocator, .limited(1024 * 1024)) catch |err| {
        try common.validationError(io, "missing z_llvm hook marker for {s}: {t}\n", .{ case.id, err });
    };
    defer allocator.free(contents);
    try requireMarkerField(io, contents, "pipeline", pipelineName(pipeline), case);
    try requireMarkerField(io, contents, "target", "x86_64-unknown-linux-gnu", case);
    try requireMarkerContains(io, contents, "zig_target=x86_64", case);
    try requireMarkerContains(io, contents, "object=", case);
    try requireMarkerField(io, contents, "case_id", expected_marker_case_id, case);
    try requireMarkerField(io, contents, "wrapper", case.wrapper, case);
    try requireMarkerField(io, contents, "mode", case.mode, case);
    if (expected_ir_path) |ir_path| try requireMarkerField(io, contents, "ir", ir_path, case);
    switch (pipeline) {
        .postopt => try requireMarkerField(io, contents, "zllvm_passes", "", case),
        .preopt => try requireMarkerField(io, contents, "zllvm_passes", acceptedPipeline(case.mode), case),
    }
    if (use_ir_writer) try requireMarkerField(io, contents, "ir_writer", "external", case);
    if (use_ir_writer) try requireMarkerField(io, contents, "ir_writer_mode", "external", case);
}

fn runSourceOwnedWrongSourceTagProbe(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    zig_emitter: []const u8,
    target: []const u8,
    pipeline: Pipeline,
    base_env: *const std.process.Environ.Map,
    output: *std.Io.Writer,
) !void {
    const probe_case: Case = .{
        .id = "release_source_owned_wrong_source_tag_probe",
        .wrapper = "test/zig/integrated/tiny_scalar_main.zig",
        .covered_fixture = "test/distribution/releasefast_x86_64/inputs/tiny_scalar.ll",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;source-backed:wrong-source-tag-probe",
    };
    const object = try common.allocTempFile(allocator, temp, probe_case.id, ".o");
    defer allocator.free(object);
    const ir_path = try common.allocTempFile(allocator, temp, probe_case.id, ".external.ll");
    defer allocator.free(ir_path);
    const marker = try common.allocTempFile(allocator, temp, probe_case.id, "_zllvm_marker.txt");
    defer allocator.free(marker);
    const descriptor_path = try common.allocTempFile(allocator, temp, probe_case.id, ".semantic_descriptor");
    defer allocator.free(descriptor_path);

    var probe_env = std.process.Environ.Map.init(allocator);
    defer probe_env.deinit();
    try copyEnvironment(&probe_env, base_env);
    try probe_env.put("ZLLVM_MARKER_PATH", marker);
    try probe_env.put("ZLLVM_ZIG_MODE", probe_case.mode);
    try probe_env.put("ZLLVM_CASE_ID", source_wrapper_dispatch_case_id);
    try probe_env.put("ZLLVM_WRAPPER", probe_case.wrapper);
    try probe_env.put("ZLLVM_IR_WRITER_DISPATCH", "source-owned");
    try probe_env.put("ZLLVM_SOURCE_FIXTURE", probe_case.covered_fixture);
    try probe_env.put("ZLLVM_SOURCE_TAG", "deliberately-wrong-source-tag");
    try probe_env.put("ZLLVM_SEMANTIC_DESCRIPTOR_PATH", descriptor_path);
    try probe_env.put("ZLLVM_IR_PATH", ir_path);

    try buildIntegratedObject(allocator, io, zig_emitter, target, object, probe_case, &probe_env);
    try requireHookMarker(allocator, io, marker, probe_case, pipeline, true, ir_path, source_wrapper_dispatch_case_id);

    const descriptor_source_tag = try readDescriptorInputValue(allocator, io, descriptor_path, probe_case, "source_tag");
    defer allocator.free(descriptor_source_tag);
    const descriptor_source_tag_env_present = try readDescriptorInputValue(allocator, io, descriptor_path, probe_case, "source_tag_env_present");
    defer allocator.free(descriptor_source_tag_env_present);
    const descriptor_context_selector = try readDescriptorInputValue(allocator, io, descriptor_path, probe_case, "descriptor_context_selector");
    defer allocator.free(descriptor_context_selector);
    const descriptor_body_selector = try readDescriptorInputValue(allocator, io, descriptor_path, probe_case, "descriptor_body_selector");
    defer allocator.free(descriptor_body_selector);
    const diagnostic_surface = try readDescriptorInputValue(allocator, io, descriptor_path, probe_case, "diagnostic_surface");
    defer allocator.free(diagnostic_surface);

    if (!std.mem.eql(u8, descriptor_source_tag, "-") or
        !std.mem.eql(u8, descriptor_source_tag_env_present, "present") or
        !std.mem.eql(u8, descriptor_context_selector, "compile-context") or
        !std.mem.eql(u8, descriptor_body_selector, "source-analysis") or
        !std.mem.eql(u8, diagnostic_surface, "scalar-add-ret"))
    {
        try common.validationError(
            io,
            "source-owned wrong-source-tag probe did not resolve from compile context: source_tag={s} source_tag_env_present={s} context_selector={s} body_selector={s} surface={s}\n",
            .{ descriptor_source_tag, descriptor_source_tag_env_present, descriptor_context_selector, descriptor_body_selector, diagnostic_surface },
        );
    }

    const source_tag_env_present = try readIrWriterHeaderValue(allocator, io, ir_path, probe_case, "; zllvm_source_tag_env_present = \"", "zllvm_source_tag_env_present");
    defer allocator.free(source_tag_env_present);
    const zig_compile_context_descriptor = try readIrWriterHeaderValue(allocator, io, ir_path, probe_case, "; zllvm_zig_compile_context_descriptor = \"", "zllvm_zig_compile_context_descriptor");
    defer allocator.free(zig_compile_context_descriptor);
    const env_source_tag_selector = try readIrWriterHeaderValue(allocator, io, ir_path, probe_case, "; zllvm_env_source_tag_selector = \"", "zllvm_env_source_tag_selector");
    defer allocator.free(env_source_tag_selector);
    const source_tag_body_selector = try readIrWriterHeaderValue(allocator, io, ir_path, probe_case, "; zllvm_source_tag_body_selector = \"", "zllvm_source_tag_body_selector");
    defer allocator.free(source_tag_body_selector);
    if (!std.mem.eql(u8, source_tag_env_present, "present") or
        !std.mem.eql(u8, zig_compile_context_descriptor, "used") or
        !std.mem.eql(u8, env_source_tag_selector, "not-used") or
        !std.mem.eql(u8, source_tag_body_selector, "not-used"))
    {
        try common.validationError(
            io,
            "source-owned wrong-source-tag probe used deprecated selector path: source_tag_env_present={s} compile_context={s} env_source_tag_selector={s} source_tag_body_selector={s}\n",
            .{ source_tag_env_present, zig_compile_context_descriptor, env_source_tag_selector, source_tag_body_selector },
        );
    }

    try output.print(
        "ok release-source-owned wrong-source-tag-probe wrapper={s} mode={s} source_tag_env_present=present context_selector=compile-context env_source_tag_selector=not-used source_tag_body_selector=not-used surface={s}\n",
        .{ probe_case.wrapper, probe_case.mode, diagnostic_surface },
    );
    try output.flush();
}

fn requireMarkerField(io: std.Io, contents: []const u8, field: []const u8, value: []const u8, case: Case) !void {
    var buffer: [512]u8 = undefined;
    const needle = try std.fmt.bufPrint(&buffer, "{s}={s}", .{ field, value });
    try requireMarkerContains(io, contents, needle, case);
}

fn requireMarkerContains(io: std.Io, contents: []const u8, needle: []const u8, case: Case) !void {
    if (std.mem.indexOf(u8, contents, needle) != null) return;
    try common.validationError(io, "z_llvm hook marker for {s} missing {s}\n", .{ case.id, needle });
}

fn buildIntegratedObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_emitter: []const u8,
    target: []const u8,
    object: []const u8,
    case: Case,
    env_map: *const std.process.Environ.Map,
) !void {
    const emit_arg = try std.fmt.allocPrint(allocator, "-femit-bin={s}", .{object});
    defer allocator.free(emit_arg);

    var argv: std.ArrayList([]const u8) = .empty;
    defer argv.deinit(allocator);
    try argv.appendSlice(allocator, &.{
        zig_emitter,
        "build-obj",
        "-fllvm",
        "-flibllvm",
        "-fno-compiler-rt",
    });
    if (shouldStrip(case.mode)) try argv.append(allocator, "-fstrip");
    try argv.appendSlice(allocator, &.{
        "-O",
        case.mode,
        "-target",
        target,
        case.wrapper,
        emit_arg,
    });
    const label = try std.fmt.allocPrint(allocator, "patched Zig integrated z_llvm build-obj emit {s}", .{case.id});
    defer allocator.free(label);
    const result = try common.runCaptureEnv(allocator, io, argv.items, label, env_map);
    common.freeRunResult(allocator, result);
}

fn linkIntegratedObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    target: []const u8,
    object: []const u8,
    exe: []const u8,
    case: Case,
) !void {
    const emit_arg = try std.fmt.allocPrint(allocator, "-femit-bin={s}", .{exe});
    defer allocator.free(emit_arg);
    const argv = [_][]const u8{
        "zig",
        "build-exe",
        "-fno-lld",
        "-fno-compiler-rt",
        "-target",
        target,
        object,
        "-lc",
        emit_arg,
    };
    const label = try std.fmt.allocPrint(allocator, "zig build-exe -fno-lld integrated object {s}", .{case.id});
    defer allocator.free(label);
    const result = try common.runCapture(allocator, io, &argv, label);
    common.freeRunResult(allocator, result);
}

fn runExecutableCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    exe: []const u8,
    case: Case,
    use_ir_writer: bool,
) !void {
    const argv = [_][]const u8{exe};
    const result = try std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(128 * 1024 * 1024),
        .stderr_limit = .limited(32 * 1024 * 1024),
    });
    defer common.freeRunResult(allocator, result);

    const expected_code: u8 = if (use_ir_writer)
        irWriterExpectedExitCode(case)
    else
        integratedExpectedExitCode(case);
    switch (result.term) {
        .exited => |code| if (code == expected_code) return,
        else => {},
    }
    try common.validationError(io, "integrated executable {s} exited with {any}, expected exit code {}\n", .{ case.id, result.term, expected_code });
}

fn integratedExpectedExitCode(case: Case) u8 {
    if (std.mem.eql(u8, case.id, "releasefast_runtime_aggregate_pair")) return 1;
    if (std.mem.eql(u8, case.id, "releasefast_source_aggregate_abi_pair")) return 1;
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_hidden_access")) return 7;
    if (std.mem.eql(u8, case.id, "releasesmall_source_standalone_extern_exports_hidden_access")) return 7;
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_mix_c_add_zig")) return 7;
    if (std.mem.eql(u8, case.id, "releasesmall_source_standalone_mix_c_files_add_zig")) return 7;
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_mix_c_add_may_panic")) return 5;
    if (std.mem.eql(u8, case.id, "releasesmall_source_standalone_mix_c_files_add_may_panic")) return 5;
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_inherit_want_safety_i64")) return 4;
    if (std.mem.eql(u8, case.id, "releasesmall_source_inherit_want_safety_i64_return")) return 4;
    return 0;
}

fn irWriterExpectedExitCode(case: Case) u8 {
    if (std.mem.eql(u8, case.id, "releasefast_tiny_scalar")) return 42;
    if (std.mem.eql(u8, case.id, "releasefast_source_tiny_scalar")) return 42;
    if (std.mem.eql(u8, case.id, "releasefast_control_flow_calls")) return 42;
    if (std.mem.eql(u8, case.id, "releasefast_globals_comptime")) return 5;
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_read_global")) return 5;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_switch")) return 13;
    if (std.mem.eql(u8, case.id, "releasefast_source_switch_dense")) return 13;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_global_update")) return 4;
    if (std.mem.eql(u8, case.id, "releasefast_source_globals_comptime_global_counter")) return 4;
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_global_update")) return 4;
    if (std.mem.eql(u8, case.id, "releasesafe_source_globals_checked")) return 4;
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_hidden_access")) return 7;
    if (std.mem.eql(u8, case.id, "releasesmall_source_standalone_extern_exports_hidden_access")) return 7;
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_mix_c_add_zig")) return 7;
    if (std.mem.eql(u8, case.id, "releasesmall_source_standalone_mix_c_files_add_zig")) return 7;
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_mix_c_add_may_panic")) return 5;
    if (std.mem.eql(u8, case.id, "releasesmall_source_standalone_mix_c_files_add_may_panic")) return 5;
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_inherit_want_safety_i64")) return 4;
    if (std.mem.eql(u8, case.id, "releasesmall_source_inherit_want_safety_i64_return")) return 4;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_call_chain")) return 3;
    if (std.mem.eql(u8, case.id, "releasefast_source_control_flow_call_chain")) return 3;
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_call_chain")) return 3;
    if (std.mem.eql(u8, case.id, "releasesafe_source_control_flow_calls_checked")) return 3;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_tls_read")) return 1;
    if (std.mem.eql(u8, case.id, "releasefast_source_tls_concurrency_counter_read")) return 1;
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_tls_read")) return 1;
    if (std.mem.eql(u8, case.id, "releasesafe_source_tls_concurrency_checked_read")) return 1;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_tls_bump")) return 2;
    if (std.mem.eql(u8, case.id, "releasefast_source_tls_concurrency_counter_bump")) return 2;
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_tls_bump")) return 2;
    if (std.mem.eql(u8, case.id, "releasesafe_source_tls_concurrency_checked_bump")) return 2;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_inline_asm_barrier")) return 1;
    if (std.mem.eql(u8, case.id, "releasefast_source_atomics_inline_asm_barrier")) return 1;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_aggregate_pair")) return 1;
    if (std.mem.eql(u8, case.id, "releasefast_source_aggregate_abi_pair")) return 1;
    if (std.mem.eql(u8, case.id, "releasesmall_globals_comptime")) return 5;
    return 0;
}

fn validationName(validation: Validation) []const u8 {
    return switch (validation) {
        .executable => "executable",
        .link_only => "link-only",
    };
}

fn effectiveProof(use_ir_writer: bool) []const u8 {
    if (use_ir_writer) return "integrated z_llvm IR writer direct structured rows plus local z_llvm object path plus Zig build-exe native link";
    return "integrated Zig build-obj object path plus Zig build-exe native link";
}

fn ownershipProof(use_ir_writer: bool) []const u8 {
    if (use_ir_writer) return "llvm-module=not-used;llvm-optimizer=not-used;llvm-targetmachine=not-used;object-emission=z_llvm;linker=zig-native-fno-lld";
    return "ir-construction=libLLVM;llvm-module=zig-owned;llvm-optimizer=zig-configured;llvm-targetmachine=not-used-by-z_llvm-object-hook;object-emission=z_llvm;linker=zig-native-fno-lld";
}

fn requireSelectedIrWriterOwnership(io: std.Io, case: Case, fallback: []const u8, surface: []const u8, construction: []const u8) !void {
    if (std.mem.eql(u8, surface, "minimal-ret0")) {
        try common.validationError(io, "external IR writer selected row {s} used minimal-ret0 instead of a runtime surface\n", .{case.id});
    }
    if (!std.mem.eql(u8, construction, "ir-construction=zllvm-structured-builder")) {
        try common.validationError(io, "external IR writer selected row {s} reported forbidden construction ownership: {s}\n", .{ case.id, construction });
    }
    if (!std.mem.startsWith(u8, fallback, "ir-construction:zllvm-structured-builder")) {
        try common.validationError(io, "external IR writer selected row {s} reported non-external IR construction fallback: {s}\n", .{ case.id, fallback });
    }
    if (std.mem.indexOf(u8, fallback, "libLLVM") != null or
        std.mem.indexOf(u8, fallback, "llvm-module") != null or
        std.mem.indexOf(u8, fallback, "TargetMachine") != null)
    {
        try common.validationError(io, "external IR writer selected row {s} reported forbidden libLLVM ownership fallback: {s}\n", .{ case.id, fallback });
    }
}

fn sourceMetadataTag(fallback: []const u8) []const u8 {
    const marker = "source-backed:";
    const value_start = (std.mem.indexOf(u8, fallback, marker) orelse return "-") + marker.len;
    const value_end = std.mem.indexOfScalarPos(u8, fallback, value_start, ';') orelse fallback.len;
    return fallback[value_start..value_end];
}

fn effectiveFallback(case: Case, use_ir_writer: bool) []const u8 {
    if (!use_ir_writer) return case.fallback;
    if (case.validation == .link_only) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:zig-panic-runtime";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_tiny_scalar_runtime_boundary")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_tls_read")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:x86_64-localexec-tls";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_tls_read")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:x86_64-localexec-tls";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_side_effect_free")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-void-noop-call";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_hidden_access")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-hidden-global-access";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_mix_c_add_zig")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-localexec-c-tls-input";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_mix_c_add_may_panic")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_umul_fix_sat_i64")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-umul-fix-sat-i64";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_inherit_want_safety_i64")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-inherit-want-safety-i64-return";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_compile_asm_unreachable")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-compile-asm-unreachable-stub";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_str_from_float_help")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;whole-function:str-from-float-help";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_decode_base_64_full")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;whole-function:base64-decode-base-64";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_decode_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-decode-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_store_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-store-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_residual_byte_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-byte-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_padding_tail_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-padding-tail-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_padding_loop_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-padding-loop-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_padding_length_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-padding-length-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_chunk_guard_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-chunk-guard-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_source_stride_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-source-stride-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_source_bundle_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-source-bundle-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_next_source_bundle_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-next-source-bundle-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_third_source_bundle_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-third-source-bundle-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_bit_buffer_store_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-bit-buffer-store-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_loop_advance_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-loop-advance-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_residual_guard_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-guard-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_residual_bundle_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-bundle-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_residual_store_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-store-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_residual_length_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-length-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_residual_table_check_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-table-check-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_residual_accumulator_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-accumulator-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_residual_loop_advance_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-loop-advance-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_residual_padding_check_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-padding-check-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_residual_final_mask_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-final-mask-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_residual_padding_loop_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-padding-loop-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_decode_exit_step")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-decode-exit-step";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_tls_bump")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:x86_64-localexec-tls";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_tls_bump")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:x86_64-localexec-tls;validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_pointer_load_store")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-pointer-load-store";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_volatile_roundtrip")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-volatile-roundtrip";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_optional_pointer")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-optional-pointer";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_packed_read_flag")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-packed-read-flag";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_packed_replace_low")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-packed-replace-low";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_struct_sum")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-struct-field-sum";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_array_sum")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-array-scalar-sum";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_optional_payload")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-optional-scalar-payload";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_error_union_payload")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-error-union-payload";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_slice_sum")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-pointer-indexed-slice-sum";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_loop_sum")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_fp_constants")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-fp-literal-return";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_comptime_const")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-comptime-const-mul";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_debug_location")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-add-imm-return";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_debug_location")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_comptime_const")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_global_update")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_pointer_load_store")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_branch_mix")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_call_chain")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_array_sum")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_struct_sum")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_slice_sum")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_atomic_add")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-monotonic-atomicrmw-add";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_inline_asm_barrier")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-inline-asm-memory-barrier";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_aggregate_pair")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-two-i32-aggregate-abi";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_float_less")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f32-ordered-less-than";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_float_mul")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f64-multiply";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_float_add")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f32-add";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_float_select")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f64-select";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_float_sub")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f32-subtract";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_double_div")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f64-divide";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_float_rem")) {
        return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f32-remainder";
    }
    return "ir-construction:zllvm-structured-builder;object-emission:z_llvm;linker:zig-native-fno-lld";
}

fn readIrWriterSurface(
    allocator: std.mem.Allocator,
    io: std.Io,
    ir_path: []const u8,
    case: Case,
) ![]const u8 {
    const contents = std.Io.Dir.cwd().readFileAlloc(io, ir_path, allocator, .limited(1024 * 1024)) catch |err| {
        try common.validationError(io, "missing external IR writer output for {s}: {t}\n", .{ case.id, err });
    };
    defer allocator.free(contents);
    const prefix = "; zllvm_ir_writer_surface = \"";
    const start = std.mem.indexOf(u8, contents, prefix) orelse {
        try common.validationError(io, "external IR writer output for {s} missing zllvm_ir_writer_surface comment\n", .{case.id});
    };
    const value_start = start + prefix.len;
    const value_end = std.mem.indexOfScalarPos(u8, contents, value_start, '"') orelse {
        try common.validationError(io, "external IR writer output for {s} has malformed zllvm_ir_writer_surface comment\n", .{case.id});
    };
    if (std.mem.eql(u8, contents[value_start..value_end], "scalar-add-ret")) return "scalar-add-ret";
    if (std.mem.eql(u8, contents[value_start..value_end], "integer-arithmetic")) return "integer-arithmetic";
    if (std.mem.eql(u8, contents[value_start..value_end], "error-switch-select")) return "error-switch-select";
    if (std.mem.eql(u8, contents[value_start..value_end], "direct-call")) return "direct-call";
    if (std.mem.eql(u8, contents[value_start..value_end], "global-load")) return "global-load";
    if (std.mem.eql(u8, contents[value_start..value_end], "i64-arithmetic")) return "i64-arithmetic";
    if (std.mem.eql(u8, contents[value_start..value_end], "i64-call-return")) return "i64-call-return";
    if (std.mem.eql(u8, contents[value_start..value_end], "table-indexed-load")) return "table-indexed-load";
    if (std.mem.eql(u8, contents[value_start..value_end], "checked-add-runtime-boundary")) return "checked-add-runtime-boundary";
    if (std.mem.eql(u8, contents[value_start..value_end], "runtime-condbr")) return "runtime-condbr";
    if (std.mem.eql(u8, contents[value_start..value_end], "runtime-phi-merge")) return "runtime-phi-merge";
    if (std.mem.eql(u8, contents[value_start..value_end], "runtime-loop-sum")) return "runtime-loop-sum";
    if (std.mem.eql(u8, contents[value_start..value_end], "checked-loop-sum-boundary")) return "checked-loop-sum-boundary";
    if (std.mem.eql(u8, contents[value_start..value_end], "runtime-switch")) return "runtime-switch";
    if (std.mem.eql(u8, contents[value_start..value_end], "checked-branch-mix-boundary")) return "checked-branch-mix-boundary";
    if (std.mem.eql(u8, contents[value_start..value_end], "global-update")) return "global-update";
    if (std.mem.eql(u8, contents[value_start..value_end], "pointer-load-store")) return "pointer-load-store";
    if (std.mem.eql(u8, contents[value_start..value_end], "volatile-roundtrip")) return "volatile-roundtrip";
    if (std.mem.eql(u8, contents[value_start..value_end], "optional-pointer")) return "optional-pointer";
    if (std.mem.eql(u8, contents[value_start..value_end], "packed-read-flag")) return "packed-read-flag";
    if (std.mem.eql(u8, contents[value_start..value_end], "packed-replace-low")) return "packed-replace-low";
    if (std.mem.eql(u8, contents[value_start..value_end], "struct-field-sum")) return "struct-field-sum";
    if (std.mem.eql(u8, contents[value_start..value_end], "array-scalar-sum")) return "array-scalar-sum";
    if (std.mem.eql(u8, contents[value_start..value_end], "optional-scalar-payload")) return "optional-scalar-payload";
    if (std.mem.eql(u8, contents[value_start..value_end], "error-union-payload")) return "error-union-payload";
    if (std.mem.eql(u8, contents[value_start..value_end], "slice-loop-sum")) return "slice-loop-sum";
    if (std.mem.eql(u8, contents[value_start..value_end], "fp-literal-return")) return "fp-literal-return";
    if (std.mem.eql(u8, contents[value_start..value_end], "comptime-const-mul")) return "comptime-const-mul";
    if (std.mem.eql(u8, contents[value_start..value_end], "add-imm-return")) return "add-imm-return";
    if (std.mem.eql(u8, contents[value_start..value_end], "checked-add-imm-boundary")) return "checked-add-imm-boundary";
    if (std.mem.eql(u8, contents[value_start..value_end], "checked-comptime-const-boundary")) return "checked-comptime-const-boundary";
    if (std.mem.eql(u8, contents[value_start..value_end], "checked-global-update-boundary")) return "checked-global-update-boundary";
    if (std.mem.eql(u8, contents[value_start..value_end], "checked-pointer-load-store-boundary")) return "checked-pointer-load-store-boundary";
    if (std.mem.eql(u8, contents[value_start..value_end], "checked-call-chain-boundary")) return "checked-call-chain-boundary";
    if (std.mem.eql(u8, contents[value_start..value_end], "checked-array-sum-boundary")) return "checked-array-sum-boundary";
    if (std.mem.eql(u8, contents[value_start..value_end], "checked-struct-sum-boundary")) return "checked-struct-sum-boundary";
    if (std.mem.eql(u8, contents[value_start..value_end], "checked-slice-loop-sum-boundary")) return "checked-slice-loop-sum-boundary";
    if (std.mem.eql(u8, contents[value_start..value_end], "abi-arg-call")) return "abi-arg-call";
    if (std.mem.eql(u8, contents[value_start..value_end], "tls-read")) return "tls-read";
    if (std.mem.eql(u8, contents[value_start..value_end], "tls-bump")) return "tls-bump";
    if (std.mem.eql(u8, contents[value_start..value_end], "checked-tls-bump-boundary")) return "checked-tls-bump-boundary";
    if (std.mem.eql(u8, contents[value_start..value_end], "atomic-add")) return "atomic-add";
    if (std.mem.eql(u8, contents[value_start..value_end], "inline-asm-barrier")) return "inline-asm-barrier";
    if (std.mem.eql(u8, contents[value_start..value_end], "aggregate-pair-abi")) return "aggregate-pair-abi";
    if (std.mem.eql(u8, contents[value_start..value_end], "float-less")) return "float-less";
    if (std.mem.eql(u8, contents[value_start..value_end], "float-mul")) return "float-mul";
    if (std.mem.eql(u8, contents[value_start..value_end], "float-add")) return "float-add";
    if (std.mem.eql(u8, contents[value_start..value_end], "float-select")) return "float-select";
    if (std.mem.eql(u8, contents[value_start..value_end], "float-sub")) return "float-sub";
    if (std.mem.eql(u8, contents[value_start..value_end], "double-div")) return "double-div";
    if (std.mem.eql(u8, contents[value_start..value_end], "float-rem")) return "float-rem";
    if (std.mem.eql(u8, contents[value_start..value_end], "void-noop-call")) return "void-noop-call";
    if (std.mem.eql(u8, contents[value_start..value_end], "hidden-global-access")) return "hidden-global-access";
    if (std.mem.eql(u8, contents[value_start..value_end], "mixed-c-zig-add")) return "mixed-c-zig-add";
    if (std.mem.eql(u8, contents[value_start..value_end], "mixed-c-zig-panic-add")) return "mixed-c-zig-panic-add";
    if (std.mem.eql(u8, contents[value_start..value_end], "umul-fix-sat-i64")) return "umul-fix-sat-i64";
    if (std.mem.eql(u8, contents[value_start..value_end], "inherit-i64-return")) return "inherit-i64-return";
    if (std.mem.eql(u8, contents[value_start..value_end], "compile-asm-unreachable")) return "compile-asm-unreachable";
    if (std.mem.eql(u8, contents[value_start..value_end], "start-trampoline")) return "start-trampoline";
    if (std.mem.eql(u8, contents[value_start..value_end], "getauxval-pointer-walk")) return "getauxval-pointer-walk";
    if (std.mem.eql(u8, contents[value_start..value_end], "f128-sret-byval")) return "f128-sret-byval";
    if (std.mem.eql(u8, contents[value_start..value_end], "noreturn-unreachable-stub")) return "noreturn-unreachable-stub";
    if (std.mem.eql(u8, contents[value_start..value_end], "address-space-volatile-store")) return "address-space-volatile-store";
    if (std.mem.eql(u8, contents[value_start..value_end], "raw-start-loop")) return "raw-start-loop";
    if (std.mem.eql(u8, contents[value_start..value_end], "i1-const-return")) return "i1-const-return";
    if (std.mem.eql(u8, contents[value_start..value_end], "constant-string-slice-return")) return "constant-string-slice-return";
    if (std.mem.eql(u8, contents[value_start..value_end], "libfuzzer-vtable-run")) return "libfuzzer-vtable-run";
    if (std.mem.eql(u8, contents[value_start..value_end], "str-from-float-help")) return "str-from-float-help";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-decode-base64-full")) return "base64-decode-base64-full";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-decode-step")) return "base64-decode-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-store-step")) return "base64-store-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-residual-byte-step")) return "base64-residual-byte-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-padding-tail-step")) return "base64-padding-tail-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-padding-loop-step")) return "base64-padding-loop-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-padding-length-step")) return "base64-padding-length-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-chunk-guard-step")) return "base64-chunk-guard-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-source-stride-step")) return "base64-source-stride-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-source-bundle-step")) return "base64-source-bundle-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-next-source-bundle-step")) return "base64-next-source-bundle-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-third-source-bundle-step")) return "base64-third-source-bundle-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-bit-buffer-store-step")) return "base64-bit-buffer-store-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-loop-advance-step")) return "base64-loop-advance-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-residual-guard-step")) return "base64-residual-guard-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-residual-bundle-step")) return "base64-residual-bundle-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-residual-store-step")) return "base64-residual-store-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-residual-length-step")) return "base64-residual-length-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-residual-table-check-step")) return "base64-residual-table-check-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-residual-accumulator-step")) return "base64-residual-accumulator-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-residual-loop-advance-step")) return "base64-residual-loop-advance-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-residual-padding-check-step")) return "base64-residual-padding-check-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-residual-final-mask-step")) return "base64-residual-final-mask-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-residual-padding-loop-step")) return "base64-residual-padding-loop-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-decode-exit-step")) return "base64-decode-exit-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "minimal-ret0")) return "minimal-ret0";
    try common.validationError(io, "external IR writer output for {s} has unsupported surface {s}\n", .{ case.id, contents[value_start..value_end] });
}

fn readIrWriterConstruction(
    allocator: std.mem.Allocator,
    io: std.Io,
    ir_path: []const u8,
    case: Case,
) ![]const u8 {
    const value = try readIrWriterHeaderValue(allocator, io, ir_path, case, "; zllvm_ir_writer_construction = \"", "zllvm_ir_writer_construction");
    errdefer allocator.free(value);
    if (std.mem.eql(u8, value, "ir-construction=zllvm-structured-builder")) return value;
    try common.validationError(io, "external IR writer output for {s} has unsupported construction ownership {s}\n", .{ case.id, value });
}

fn readIrWriterHeaderValue(
    allocator: std.mem.Allocator,
    io: std.Io,
    ir_path: []const u8,
    case: Case,
    prefix: []const u8,
    field_name: []const u8,
) ![]const u8 {
    const contents = std.Io.Dir.cwd().readFileAlloc(io, ir_path, allocator, .limited(1024 * 1024)) catch |err| {
        try common.validationError(io, "missing external IR writer output for {s}: {t}\n", .{ case.id, err });
    };
    defer allocator.free(contents);
    const start = std.mem.indexOf(u8, contents, prefix) orelse {
        try common.validationError(io, "external IR writer output for {s} missing {s} comment\n", .{ case.id, field_name });
    };
    const value_start = start + prefix.len;
    const value_end = std.mem.indexOfScalarPos(u8, contents, value_start, '"') orelse {
        try common.validationError(io, "external IR writer output for {s} has malformed {s} comment\n", .{ case.id, field_name });
    };
    return try allocator.dupe(u8, contents[value_start..value_end]);
}

fn readDescriptorInputValue(
    allocator: std.mem.Allocator,
    io: std.Io,
    descriptor_path: []const u8,
    case: Case,
    key: []const u8,
) ![]const u8 {
    const contents = std.Io.Dir.cwd().readFileAlloc(io, descriptor_path, allocator, .limited(1024 * 1024)) catch |err| {
        try common.validationError(io, "missing Zig-emitted semantic descriptor for {s}: {t}\n", .{ case.id, err });
    };
    defer allocator.free(contents);
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        const separator = std.mem.indexOfScalar(u8, line, '=') orelse continue;
        if (std.mem.eql(u8, line[0..separator], key)) {
            return try allocator.dupe(u8, line[separator + 1 ..]);
        }
    }
    try common.validationError(io, "Zig-emitted semantic descriptor for {s} missing {s}\n", .{ case.id, key });
}

fn pipelineName(pipeline: Pipeline) []const u8 {
    return switch (pipeline) {
        .postopt => "postopt",
        .preopt => "preopt",
    };
}

fn acceptedPipeline(mode: []const u8) []const u8 {
    if (std.mem.eql(u8, mode, "ReleaseFast")) return "zig-release-fast-accepted";
    if (std.mem.eql(u8, mode, "ReleaseSafe")) return "zig-release-safe-accepted";
    if (std.mem.eql(u8, mode, "ReleaseSmall")) return "zig-release-small-accepted";
    return "";
}

fn shouldStrip(mode: []const u8) bool {
    return std.mem.eql(u8, mode, "ReleaseFast") or std.mem.eql(u8, mode, "ReleaseSmall");
}

fn normalizeZigTarget(target: []const u8) []const u8 {
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-gnu")) return "x86_64-linux-gnu";
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-musl")) return "x86_64-linux-musl";
    return target;
}
