const std = @import("std");
const common = @import("tool_common.zig");

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
        .id = "releasefast_integers",
        .wrapper = "test/zig/integrated/integers_main.zig",
        .covered_fixture = "test/zig/inputs/integers.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
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
        .id = "releasefast_runtime_cond_branch",
        .wrapper = "test/zig/integrated/runtime_cond_branch_main.zig",
        .covered_fixture = "test/zig/inputs/switch_control.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld",
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
        .id = "releasefast_runtime_packed_read_flag",
        .wrapper = "test/zig/integrated/runtime_packed_read_flag_main.zig",
        .covered_fixture = "test/zig/inputs/packed_bits.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-packed-read-flag",
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
        .id = "releasefast_runtime_struct_sum",
        .wrapper = "test/zig/integrated/runtime_struct_sum_main.zig",
        .covered_fixture = "test/zig/inputs/aggregates.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-struct-field-sum",
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
        .id = "releasefast_runtime_optional_payload",
        .wrapper = "test/zig/integrated/runtime_optional_payload_main.zig",
        .covered_fixture = "test/zig/inputs/aggregates.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-optional-scalar-payload",
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
        .id = "releasefast_runtime_slice_sum",
        .wrapper = "test/zig/integrated/runtime_slice_sum_main.zig",
        .covered_fixture = "test/zig/inputs/aggregates.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-pointer-indexed-slice-sum",
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
        .id = "releasefast_runtime_comptime_const",
        .wrapper = "test/zig/integrated/runtime_comptime_const_main.zig",
        .covered_fixture = "test/zig/inputs/globals_comptime.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-comptime-const-mul",
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
        .id = "releasefast_runtime_tls_bump",
        .wrapper = "test/zig/integrated/runtime_tls_read_main.zig",
        .covered_fixture = "test/zig/inputs/tls_concurrency.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:x86_64-localexec-tls",
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
        .id = "releasefast_runtime_inline_asm_barrier",
        .wrapper = "test/zig/integrated/runtime_inline_asm_barrier_main.zig",
        .covered_fixture = "test/zig/inputs/atomics_inline_asm_debug.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-inline-asm-memory-barrier",
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
        .id = "releasefast_runtime_float_less",
        .wrapper = "test/zig/integrated/runtime_float_less_main.zig",
        .covered_fixture = "test/zig/inputs/float_compare.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f32-ordered-less-than",
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
        .id = "releasesafe_runtime_debug_location",
        .wrapper = "test/zig/integrated/runtime_debug_location_main.zig",
        .covered_fixture = "test/zig/inputs/atomics_inline_asm_debug.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge",
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
        .id = "releasesafe_runtime_pointer_load_store",
        .wrapper = "test/zig/integrated/runtime_pointer_load_store_main.zig",
        .covered_fixture = "test/zig/inputs/pointers_memory.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge",
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
        .id = "releasesafe_runtime_call_chain",
        .wrapper = "test/zig/integrated/control_flow_calls_main.zig",
        .covered_fixture = "test/zig/inputs/control_flow_calls.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge",
    },
    .{
        .id = "releasesafe_runtime_tls_bump",
        .wrapper = "test/zig/integrated/runtime_tls_read_main.zig",
        .covered_fixture = "test/zig/inputs/tls_concurrency.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:x86_64-localexec-tls;validated-zig-panic-edge",
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
        .id = "releasesafe_runtime_array_sum",
        .wrapper = "test/zig/integrated/runtime_array_sum_main.zig",
        .covered_fixture = "test/zig/inputs/aggregates.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge",
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
        .id = "releasesafe_runtime_slice_sum",
        .wrapper = "test/zig/integrated/runtime_slice_sum_main.zig",
        .covered_fixture = "test/zig/inputs/aggregates.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge",
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
        .id = "releasesmall_runtime_mix_c_add_zig",
        .wrapper = "test/zig/integrated/runtime_mix_c_add_zig_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_zig.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-localexec-c-tls-input",
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
        .id = "releasesmall_runtime_umul_fix_sat_i64",
        .wrapper = "test/zig/integrated/runtime_umul_fix_sat_i64_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/no_compile_panic_for_unchecked_arith_umul_fix_sat_i64.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-umul-fix-sat-i64",
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
        .id = "releasesmall_runtime_compile_asm_unreachable",
        .wrapper = "test/zig/integrated/runtime_compile_asm_unreachable_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_compile_asm_main_unreachable.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-compile-asm-unreachable-stub",
    },
    .{
        .id = "releasesmall_runtime_str_from_float_help",
        .wrapper = "test/zig/integrated/runtime_str_from_float_help_main.zig",
        .covered_fixture = "test/distribution/releasesmall_x86_64/exclusions/standalone_emit_llvm_no_bin_str_from_float_help.ll",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .fallback = "ir-construction:libLLVM;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-str-from-float-prologue",
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
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--pipeline=postopt")) {
            pipeline = .postopt;
        } else if (std.mem.eql(u8, arg, "--pipeline=preopt")) {
            pipeline = .preopt;
        } else if (std.mem.eql(u8, arg, "--ir-writer")) {
            use_ir_writer = true;
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
    try stdout_writer.interface.print(
        "zig-integrated-object target={s} pipeline={s} linker=zig build-exe -fno-lld hook={s} zllvm={s}\n",
        .{ target, pipelineName(pipeline), if (use_ir_writer) "ZIG_USE_ZLLVM_IR_WRITER" else "ZIG_USE_ZLLVM_OBJECT", zllvm_exe },
    );
    try stdout_writer.interface.flush();

    var executable_ok: usize = 0;
    var link_only_ok: usize = 0;
    var total: usize = 0;
    var scalar_runtime_rows: usize = 0;
    var minimal_wrapper_rows: usize = 0;
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
        .{ .name = "str-from-float-prologue" },
        .{ .name = "base64-decode-step" },
        .{ .name = "base64-store-step" },
        .{ .name = "base64-residual-byte-step" },
        .{ .name = "base64-padding-tail-step" },
        .{ .name = "base64-padding-loop-step" },
        .{ .name = "minimal-ret0" },
    };
    for (cases) |case| {
        if (mode_filter) |filter| {
            if (!std.mem.eql(u8, filter, case.mode)) continue;
        }
        if (case_filter) |filter| {
            if (!std.mem.eql(u8, filter, case.id)) continue;
        }
        try requirePairing(case);
        total += 1;
        const exe = try common.allocTempFile(allocator, temp, case.id, "_integrated");
        defer allocator.free(exe);
        const object = try common.allocTempFile(allocator, temp, case.id, ".o");
        defer allocator.free(object);
        const ir_path = try common.allocTempFile(allocator, temp, case.id, ".external.ll");
        defer allocator.free(ir_path);
        const marker = try common.allocTempFile(allocator, temp, case.id, "_zllvm_marker.txt");
        defer allocator.free(marker);
        try env_map.put("ZLLVM_MARKER_PATH", marker);
        try env_map.put("ZLLVM_ZIG_MODE", case.mode);
        try env_map.put("ZLLVM_CASE_ID", case.id);
        try env_map.put("ZLLVM_WRAPPER", case.wrapper);
        if (use_ir_writer) try env_map.put("ZLLVM_IR_PATH", ir_path);
        try buildIntegratedObject(allocator, io, zig_emitter, target, object, case, &env_map);
        try requireHookMarker(allocator, io, marker, case, pipeline, use_ir_writer, if (use_ir_writer) ir_path else null);
        const surface = if (use_ir_writer) try readIrWriterSurface(allocator, io, ir_path, case) else "-";
        if (use_ir_writer) {
            countSurface(&surface_counters, surface);
            if (std.mem.eql(u8, surface, "minimal-ret0")) {
                minimal_wrapper_rows += 1;
            } else {
                scalar_runtime_rows += 1;
            }
        }
        try linkIntegratedObject(allocator, io, target, object, exe);
        if (case.validation == .executable) {
            try runExecutableCase(allocator, io, exe, case, use_ir_writer);
            executable_ok += 1;
        } else {
            link_only_ok += 1;
        }
        try stdout_writer.interface.print(
            "ok zig-integrated-object {s} wrapper={s} covered_fixture={s} mode={s} proof=\"{s}\" validation={s} fallback={s} ir_writer_surface={s}\n",
            .{ case.id, case.wrapper, case.covered_fixture, case.mode, effectiveProof(use_ir_writer), validationName(case.validation), effectiveFallback(case, use_ir_writer), surface },
        );
        try stdout_writer.interface.flush();
    }

    if (use_ir_writer) {
        if (minimal_wrapper_rows != 0) {
            try common.validationError(io, "external IR writer selected rows must not use minimal-ret0; minimal_wrapper_rows={}\n", .{minimal_wrapper_rows});
        }
        try stdout_writer.interface.print(
            "summary zig-integrated-object pipeline={s} ir_writer={} total={} executable_ok={} link_only_ok={} scalar_runtime_rows={} minimal_wrapper_rows={} local_fail=0\n",
            .{ pipelineName(pipeline), use_ir_writer, total, executable_ok, link_only_ok, scalar_runtime_rows, minimal_wrapper_rows },
        );
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

fn requireHookMarker(
    allocator: std.mem.Allocator,
    io: std.Io,
    marker: []const u8,
    case: Case,
    pipeline: Pipeline,
    use_ir_writer: bool,
    expected_ir_path: ?[]const u8,
) !void {
    const contents = std.Io.Dir.cwd().readFileAlloc(io, marker, allocator, .limited(1024 * 1024)) catch |err| {
        try common.validationError(io, "missing z_llvm hook marker for {s}: {t}\n", .{ case.id, err });
    };
    defer allocator.free(contents);
    try requireMarkerField(io, contents, "pipeline", pipelineName(pipeline), case);
    try requireMarkerField(io, contents, "target", "x86_64-unknown-linux-gnu", case);
    try requireMarkerContains(io, contents, "zig_target=x86_64", case);
    try requireMarkerContains(io, contents, "object=", case);
    try requireMarkerField(io, contents, "case_id", case.id, case);
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
    const result = try common.runCaptureEnv(allocator, io, argv.items, "patched Zig integrated z_llvm build-obj emit", env_map);
    common.freeRunResult(allocator, result);
}

fn linkIntegratedObject(
    allocator: std.mem.Allocator,
    io: std.Io,
    target: []const u8,
    object: []const u8,
    exe: []const u8,
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
    const result = try common.runCapture(allocator, io, &argv, "zig build-exe -fno-lld integrated object");
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
        0;
    switch (result.term) {
        .exited => |code| if (code == expected_code) return,
        else => {},
    }
    try common.validationError(io, "integrated executable {s} exited with {any}, expected exit code {}\n", .{ case.id, result.term, expected_code });
}

fn irWriterExpectedExitCode(case: Case) u8 {
    if (std.mem.eql(u8, case.id, "releasefast_tiny_scalar")) return 42;
    if (std.mem.eql(u8, case.id, "releasefast_control_flow_calls")) return 42;
    if (std.mem.eql(u8, case.id, "releasefast_globals_comptime")) return 5;
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_read_global")) return 5;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_switch")) return 13;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_global_update")) return 4;
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_global_update")) return 4;
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_hidden_access")) return 7;
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_mix_c_add_zig")) return 7;
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_mix_c_add_may_panic")) return 5;
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_inherit_want_safety_i64")) return 4;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_call_chain")) return 3;
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_call_chain")) return 3;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_tls_read")) return 1;
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_tls_read")) return 1;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_tls_bump")) return 2;
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_tls_bump")) return 2;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_inline_asm_barrier")) return 1;
    if (std.mem.eql(u8, case.id, "releasefast_runtime_aggregate_pair")) return 1;
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
    if (use_ir_writer) return "integrated external z_llvm textual IR writer plus z_llvm optimizer/object path plus Zig build-exe native link";
    return "integrated Zig build-obj object path plus Zig build-exe native link";
}

fn effectiveFallback(case: Case, use_ir_writer: bool) []const u8 {
    if (!use_ir_writer) return case.fallback;
    if (case.validation == .link_only) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:zig-panic-runtime";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_tiny_scalar_runtime_boundary")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_tls_read")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:x86_64-localexec-tls";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_tls_read")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:x86_64-localexec-tls";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_side_effect_free")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-void-noop-call";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_hidden_access")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-hidden-global-access";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_mix_c_add_zig")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-localexec-c-tls-input";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_mix_c_add_may_panic")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_umul_fix_sat_i64")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-umul-fix-sat-i64";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_inherit_want_safety_i64")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-inherit-want-safety-i64-return";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_compile_asm_unreachable")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-compile-asm-unreachable-stub";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_str_from_float_help")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-str-from-float-prologue";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_decode_step")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-decode-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_store_step")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-store-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_residual_byte_step")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-residual-byte-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_padding_tail_step")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-padding-tail-step";
    }
    if (std.mem.eql(u8, case.id, "releasesmall_runtime_base64_padding_loop_step")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-base64-padding-loop-step";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_tls_bump")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:x86_64-localexec-tls";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_tls_bump")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:x86_64-localexec-tls;validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_pointer_load_store")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-pointer-load-store";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_volatile_roundtrip")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-volatile-roundtrip";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_optional_pointer")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-optional-pointer";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_packed_read_flag")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-packed-read-flag";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_packed_replace_low")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-packed-replace-low";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_struct_sum")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-struct-field-sum";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_array_sum")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-array-scalar-sum";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_optional_payload")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-optional-scalar-payload";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_error_union_payload")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-error-union-payload";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_slice_sum")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-pointer-indexed-slice-sum";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_loop_sum")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_fp_constants")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-fp-literal-return";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_comptime_const")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-comptime-const-mul";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_debug_location")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-add-imm-return";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_debug_location")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_comptime_const")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_global_update")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_pointer_load_store")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_branch_mix")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_call_chain")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_array_sum")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_struct_sum")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasesafe_runtime_slice_sum")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:validated-zig-panic-edge";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_atomic_add")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-monotonic-atomicrmw-add";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_inline_asm_barrier")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-inline-asm-memory-barrier";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_aggregate_pair")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-two-i32-aggregate-abi";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_float_less")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f32-ordered-less-than";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_float_mul")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f64-multiply";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_float_add")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f32-add";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_float_select")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f64-select";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_float_sub")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f32-subtract";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_double_div")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f64-divide";
    }
    if (std.mem.eql(u8, case.id, "releasefast_runtime_float_rem")) {
        return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld;boundary:selected-f32-remainder";
    }
    return "ir-construction:z_llvm-external-textual-subset;object-emission:z_llvm;linker:zig-native-fno-lld";
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
    if (std.mem.eql(u8, contents[value_start..value_end], "str-from-float-prologue")) return "str-from-float-prologue";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-decode-step")) return "base64-decode-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-store-step")) return "base64-store-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-residual-byte-step")) return "base64-residual-byte-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-padding-tail-step")) return "base64-padding-tail-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "base64-padding-loop-step")) return "base64-padding-loop-step";
    if (std.mem.eql(u8, contents[value_start..value_end], "minimal-ret0")) return "minimal-ret0";
    try common.validationError(io, "external IR writer output for {s} has unsupported surface {s}\n", .{ case.id, contents[value_start..value_end] });
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
