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

The fixed selected proof remains the 146-row external IR-writer gate. The broad
source-backed proof is a separate discovery gate over the release fixture tree.
It currently accepts all 55 fixture families as 90 source-backed
structured-direct rows and records no skips for the current inventory.

Fixed selected gate:

```text
zig build distribution-zig-ir-writer
summary zig-integrated-object pipeline=preopt ir_writer=true total=146 executable_ok=146 link_only_ok=0 scalar_runtime_rows=146 structured_direct_rows=146 structured_textual_rows=0 textual_boundary_rows=0 generic_codegen_rows=146 case_specific_codegen_rows=0 minimal_wrapper_rows=0 local_fail=0
ownership-summary structured-direct:146;structured-textual:0;textual-boundary:0;ir-construction=zllvm-structured-builder:146;ir-construction=z_llvm-external-textual-subset:0;llvm-text-parse=not-used-for-structured;llvm-module=not-used;llvm-optimizer=not-used;llvm-targetmachine=not-used;object-emission=z_llvm;linker=zig-native-fno-lld
codegen-summary generic-codegen:146;case-specific-codegen:0;textual-boundary-out-of-scope:0
```

Broad source-backed gate:

```text
zig build distribution-x86_64-source-backed-structured
source-backed-inventory target=x86_64 release_modes=ReleaseFast,ReleaseSafe,ReleaseSmall discovered_fixtures=55 accepted_fixtures=55 skipped_with_reason=0
summary source-backed-structured target=x86_64 release_modes=ReleaseFast,ReleaseSafe,ReleaseSmall source_backed_rows=90 structured_direct_rows=90 generic_codegen_rows=90 skipped_with_reason=0 fallback_rows=0 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=true total=90 executable_ok=90 link_only_ok=0 scalar_runtime_rows=90 structured_builder_rows=90 textual_subset_rows=0 structured_direct_rows=90 structured_textual_rows=0 textual_boundary_rows=0 generic_codegen_rows=90 case_specific_codegen_rows=0 minimal_wrapper_rows=0 local_fail=0
ownership-summary structured-direct:90;structured-textual:0;textual-boundary:0;ir-construction=zllvm-structured-builder:90;ir-construction=z_llvm-external-textual-subset:0;llvm-text-parse=not-used-for-structured;llvm-module=not-used;llvm-optimizer=not-used;llvm-targetmachine=not-used;object-emission=z_llvm;linker=zig-native-fno-lld
codegen-summary generic-codegen:90;case-specific-codegen:0;textual-boundary-out-of-scope:0
```

Source-wrapper structured-direct gate:

```text
zig build distribution-zig-source-structured-direct
summary source-wrapper-structured target=x86_64 release_modes=ReleaseFast,ReleaseSafe,ReleaseSmall source_wrappers=49 structured_direct_rows=49 case_id_rows=0 generic_codegen_rows=49 manifest_structured_rows=28 semantic_lowering_rows=21 case_specific_rows=0 fallback_rows=0 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=true total=49 executable_ok=49 link_only_ok=0 scalar_runtime_rows=49 structured_builder_rows=49 textual_subset_rows=0 structured_direct_rows=49 structured_textual_rows=0 textual_boundary_rows=0 generic_codegen_rows=49 case_specific_codegen_rows=0 manifest_structured_rows=28 semantic_lowering_rows=21 minimal_wrapper_rows=0 local_fail=0
lowering-summary manifest-structured:28;zig-semantic-records:21
```

Every accepted broad row must report
`ir-construction=zllvm-structured-builder`, `structured_direct`,
`codegen=generic-x86_64-lowering`, no textual LLVM IR parse fallback, no LLVM
optimizer, no LLVM TargetMachine, `object-emission=z_llvm`, and
`linker=zig-native-fno-lld`.

Combined claim: the fixed selected 146-row proof and the broad 90-row
source-backed proof are both green, but their counters remain separate. The
selected proof is a stable surface claim; the broad proof is a discovery-based
fixture inventory claim over the current x86_64 release corpus.

The source-wrapper proof is separate again: it starts from Zig source wrappers
and resolves the structured module from wrapper/source metadata for the 49
unambiguous wrapper/mode rows. The semantic lowering subset is tracked in
`docs/roadmap/x86_64_source_wrapper_semantic_lowering.md`.

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
| ReleaseSmall | `releasesmall_source_address_space_start_trampoline` | `address_space_start_trampoline.ll` | `start-trampoline` |
| ReleaseSmall | `releasesmall_source_array_in_anon_struct_getauxval` | `array_in_anon_struct_getauxval.ll` | `getauxval-pointer-walk` |
| ReleaseSmall | `releasesmall_source_c_abi_main_f128_sret` | `c_abi_main_f128_sret.ll` | `f128-sret-byval` |
| ReleaseSmall | `releasesmall_source_compile_errors_logical_ptr_elem_ptr` | `compile_errors_illegal_operation_on_logical_ptr_elem_ptr.ll` | `noreturn-unreachable-stub` |
| ReleaseSmall | `releasesmall_source_export_keyword_vram_store` | `export_keyword_vram_store.ll` | `address-space-volatile-store` |
| ReleaseSmall | `releasesmall_source_sizeof_typeof_unreachable_stubs` | `sizeof_typeof_unreachable_stubs.ll` | `noreturn-unreachable-stub` |
| ReleaseSmall | `releasesmall_source_standalone_install_raw_hex_start_loop` | `standalone_install_raw_hex_start_loop.ll` | `raw-start-loop` |
| ReleaseSmall | `releasesmall_source_standalone_libfuzzer_runner_futex_wait` | `standalone_libfuzzer_runner_futex_wait.ll` | `i1-const-return` |
| ReleaseSmall | `releasesmall_source_standalone_libfuzzer_runner_test_name` | `standalone_libfuzzer_runner_test_name.ll` | `constant-string-slice-return` |
| ReleaseSmall | `releasesmall_source_standalone_libfuzzer_runner_test_run` | `standalone_libfuzzer_runner_test_run.ll` | `libfuzzer-vtable-run` |

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
  ReleaseSmall mixed C/Zig, compile-asm, i64 helper rows, start trampolines,
  getauxval pointer walking, raw start loops, libfuzzer futex/name/run
  boundaries, logical-pointer unreachable stubs, and f128 sret/byval ABI rows

Remaining future helper candidates: none for the current
ReleaseFast/ReleaseSafe/ReleaseSmall x86_64 fixture inventory. New unsupported
classes should be added only when a newly discovered fixture exposes a repeated
shape that needs a reusable builder or generic lowering helper.

Selection rule: add future rows through the registry and existing helper layer
first. Add a new helper only when at least one measured fixture exposes a
repeated shape; do not add ad hoc case bodies for count expansion.
