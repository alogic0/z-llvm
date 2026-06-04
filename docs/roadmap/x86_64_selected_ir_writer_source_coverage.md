# x86_64 Selected IR-Writer Source Coverage

This note tracks the broadened source-backed portion of the selected external
IR-writer gate. It is scoped to x86_64 release modes and the Zig native linker.

## Inventory

The current release-mode captured IR inventory is the sorted `.ll` set under:

- `test/distribution/releasefast_x86_64/inputs`
- `test/distribution/releasesafe_x86_64/inputs`
- `test/distribution/releasesmall_x86_64/inputs`
- `test/distribution/releasesmall_x86_64/exclusions`

Measured inventory: 55 fixtures: 27 ReleaseFast, 9 ReleaseSafe, and 19
ReleaseSmall/former-boundary fixtures.

The fixed selected proof remains the 136-row external IR-writer gate. The broad
source-backed proof is a separate discovery gate over the release fixture tree.
It currently accepts 45 fixture families as 80 source-backed structured-direct
rows and records 10 unsupported ReleaseSmall fixtures with explicit skip
reasons.

Fixed selected gate:

```text
zig build distribution-zig-ir-writer
summary zig-integrated-object pipeline=preopt ir_writer=true total=136 executable_ok=136 link_only_ok=0 scalar_runtime_rows=136 structured_direct_rows=136 structured_textual_rows=0 textual_boundary_rows=0 generic_codegen_rows=136 case_specific_codegen_rows=0 minimal_wrapper_rows=0 local_fail=0
ownership-summary structured-direct:136;structured-textual:0;textual-boundary:0;ir-construction=zllvm-structured-builder:136;ir-construction=z_llvm-external-textual-subset:0;llvm-text-parse=not-used-for-structured;llvm-module=not-used;llvm-optimizer=not-used;llvm-targetmachine=not-used;object-emission=z_llvm;linker=zig-native-fno-lld
codegen-summary generic-codegen:136;case-specific-codegen:0;textual-boundary-out-of-scope:0
```

Broad source-backed gate:

```text
zig build distribution-x86_64-source-backed-structured
source-backed-inventory target=x86_64 release_modes=ReleaseFast,ReleaseSafe,ReleaseSmall discovered_fixtures=55 accepted_fixtures=45 skipped_with_reason=10
summary source-backed-structured target=x86_64 release_modes=ReleaseFast,ReleaseSafe,ReleaseSmall source_backed_rows=80 structured_direct_rows=80 generic_codegen_rows=80 skipped_with_reason=10 fallback_rows=0 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=true total=80 executable_ok=80 link_only_ok=0 scalar_runtime_rows=80 structured_builder_rows=80 textual_subset_rows=0 structured_direct_rows=80 structured_textual_rows=0 textual_boundary_rows=0 generic_codegen_rows=80 case_specific_codegen_rows=0 minimal_wrapper_rows=0 local_fail=0
ownership-summary structured-direct:80;structured-textual:0;textual-boundary:0;ir-construction=zllvm-structured-builder:80;ir-construction=z_llvm-external-textual-subset:0;llvm-text-parse=not-used-for-structured;llvm-module=not-used;llvm-optimizer=not-used;llvm-targetmachine=not-used;object-emission=z_llvm;linker=zig-native-fno-lld
codegen-summary generic-codegen:80;case-specific-codegen:0;textual-boundary-out-of-scope:0
```

Every accepted broad row must report
`ir-construction=zllvm-structured-builder`, `structured_direct`,
`codegen=generic-x86_64-lowering`, no textual LLVM IR parse fallback, no LLVM
optimizer, no LLVM TargetMachine, `object-emission=z_llvm`, and
`linker=zig-native-fno-lld`.

## Prior Source-Backed Expansion Rows

The 30-row expansion added these captured fixture aliases without adding new
ad hoc writer bodies:

| Mode | Case | Fixture | Surface |
| --- | --- | --- | --- |
| ReleaseFast | `releasefast_source_tiny_scalar` | `tiny_scalar.ll` | `scalar-add-ret` |
| ReleaseFast | `releasefast_source_error_switch_error_switch` | `error_switch_error_switch.ll` | `error-switch-select` |
| ReleaseFast | `releasefast_source_optional_pointer_value` | `optional_pointer_value.ll` | `optional-pointer` |
| ReleaseFast | `releasefast_source_packed_bits_basic_read_flag` | `packed_bits_basic.ll` | `packed-read-flag` |
| ReleaseFast | `releasefast_source_packed_bits_basic_replace_low` | `packed_bits_basic.ll` | `packed-replace-low` |
| ReleaseFast | `releasefast_source_aggregates_optional_payload` | `aggregates_optional_payload.ll` | `optional-scalar-payload` |
| ReleaseFast | `releasefast_source_aggregates_error_union_payload` | `aggregates_error_union_payload.ll` | `error-union-payload` |
| ReleaseFast | `releasefast_source_fp_constants_literals` | `fp_constants_literals.ll` | `fp-literal-return` |
| ReleaseFast | `releasefast_source_globals_comptime_const` | `globals_comptime_const.ll` | `comptime-const-mul` |
| ReleaseFast | `releasefast_source_globals_comptime_global_counter` | `globals_comptime_global_counter.ll` | `global-update` |
| ReleaseFast | `releasefast_source_atomics_debug_location` | `atomics_debug_location.ll` | `add-imm-return` |
| ReleaseFast | `releasefast_source_tls_concurrency_counter_read` | `tls_concurrency_counter.ll` | `tls-read` |
| ReleaseFast | `releasefast_source_tls_concurrency_counter_bump` | `tls_concurrency_counter.ll` | `tls-bump` |
| ReleaseFast | `releasefast_source_atomics_atomic_add` | `atomics_atomic_add.ll` | `atomic-add` |
| ReleaseFast | `releasefast_source_atomics_inline_asm_barrier` | `atomics_inline_asm_barrier.ll` | `inline-asm-barrier` |
| ReleaseFast | `releasefast_source_aggregate_abi_pair` | `aggregate_abi_pair.ll` | `aggregate-pair-abi` |
| ReleaseSafe | `releasesafe_source_error_switch_select` | `error_switch_select.ll` | `error-switch-select` |
| ReleaseSafe | `releasesafe_source_atomics_debug_location_checked` | `atomics_debug_location_checked.ll` | `checked-add-imm-boundary` |
| ReleaseSafe | `releasesafe_source_control_flow_calls_checked` | `control_flow_calls_checked.ll` | `checked-call-chain-boundary` |
| ReleaseSafe | `releasesafe_source_tls_concurrency_checked_bump` | `tls_concurrency_checked.ll` | `checked-tls-bump-boundary` |
| ReleaseSafe | `releasesafe_source_tls_concurrency_checked_read` | `tls_concurrency_checked.ll` | `tls-read` |
| ReleaseSafe | `releasesafe_source_aggregates_checked_struct` | `aggregates_checked_sums.ll` | `checked-struct-sum-boundary` |
| ReleaseSafe | `releasesafe_source_aggregates_checked_slice` | `aggregates_checked_sums.ll` | `checked-slice-loop-sum-boundary` |
| ReleaseSmall | `releasesmall_source_standalone_extern_exports_hidden_access` | `standalone_extern_exports_hidden_access.ll` | `hidden-global-access` |
| ReleaseSmall | `releasesmall_source_standalone_mix_c_files_add_zig` | `standalone_mix_c_files_add_zig.ll` | `mixed-c-zig-add` |
| ReleaseSmall | `releasesmall_source_standalone_mix_c_files_add_may_panic` | `standalone_mix_c_files_add_may_panic.ll` | `mixed-c-zig-panic-add` |
| ReleaseSmall | `releasesmall_source_no_compile_panic_for_unchecked_arith_umul_fix_sat_i64` | `no_compile_panic_for_unchecked_arith_umul_fix_sat_i64.ll` | `umul-fix-sat-i64` |
| ReleaseSmall | `releasesmall_source_inherit_want_safety_i64_return` | `inherit_want_safety_i64_return.ll` | `inherit-i64-return` |
| ReleaseSmall | `releasesmall_source_standalone_compile_asm_main_unreachable` | `standalone_compile_asm_main_unreachable.ll` | `compile-asm-unreachable` |
| ReleaseSmall | `releasesmall_source_base64_table_lookup` | `base64_table_lookup.ll` | `table-indexed-load` |

## Helper-Family Classification

Covered helper families:

- loops/phis: control-flow loop sum, slice sum, base64 loop slices, selected
  branch/merge rows
- calls: call chain, i64 call return, ReleaseSafe checked call-chain, mixed
  C/Zig call boundaries, writer/vtable boundary rows
- aggregates: struct, array, optional payload, error-union payload, slice, and
  aggregate ABI pair shapes
- pointer/memory: pointer load/store, volatile roundtrip, optional pointer,
  table-indexed loads, base64 stores, memcpy/memset/lifetime rows
- checked arithmetic: ReleaseSafe scalar, global, pointer, branch, call, TLS,
  aggregate, and panic-edge rows
- TLS/globals: global loads/updates, local-exec TLS read/bump, hidden globals
- FP: FP literals, compare, selected binary/check rows, extended fdiv/frem rows
- runtime boundaries: whole-function base64, whole-function strFromFloatHelp,
  ReleaseSmall mixed C/Zig, compile-asm, and i64 helper rows

Remaining future helper candidates:

- address-space and VRAM pointer/addressing rows
- anonymous aggregate/getauxval layout rows
- `f128` C ABI sret rows
- logical-pointer compile-error IR rows
- raw-hex start-loop rows
- libfuzzer futex/name/run runtime-boundary rows
- additional ReleaseSmall runtime boundaries that need a new reusable helper
  before selection

The broad gate currently prints these explicit fixture skips:

| Fixture | Reason |
| --- | --- |
| `address_space_start_trampoline.ll` | `address-space-start-trampoline` |
| `array_in_anon_struct_getauxval.ll` | `libc-getauxval-aggregate-startup-boundary` |
| `c_abi_main_f128_sret.ll` | `f128-sret-c-abi-boundary` |
| `compile_errors_illegal_operation_on_logical_ptr_elem_ptr.ll` | `logical-pointer-compile-error-boundary` |
| `export_keyword_vram_store.ll` | `address-space-vram-store-boundary` |
| `sizeof_typeof_unreachable_stubs.ll` | `unreachable-stub-boundary` |
| `standalone_install_raw_hex_start_loop.ll` | `raw-start-loop-entry-boundary` |
| `standalone_libfuzzer_runner_futex_wait.ll` | `libfuzzer-futex-runtime-boundary` |
| `standalone_libfuzzer_runner_test_name.ll` | `libfuzzer-vtable-name-boundary` |
| `standalone_libfuzzer_runner_test_run.ll` | `libfuzzer-vtable-run-boundary` |

Selection rule: add future rows through the registry and existing helper layer
first. Add a new helper only when at least one measured fixture exposes a
repeated shape; do not add ad hoc case bodies for count expansion.
