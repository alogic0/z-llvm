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

Selected source-backed rows: 48 of the 136 external IR-writer rows carry a
captured release-mode fixture marker. They intentionally reuse existing
registry surfaces and helper-backed writer bodies.

Current gate:

```text
zig build distribution-zig-ir-writer
summary zig-integrated-object pipeline=preopt ir_writer=true total=136 executable_ok=136 link_only_ok=0 scalar_runtime_rows=136 structured_direct_rows=104 structured_textual_rows=0 textual_boundary_rows=32 textual_boundary_reason_missing_rows=0 minimal_wrapper_rows=0 local_fail=0
ownership-summary structured-direct:104;structured-textual:0;textual-boundary:32;ir-construction=zllvm-structured-builder:104;ir-construction=z_llvm-external-textual-subset:32;llvm-text-parse=not-used-for-structured;llvm-module=not-used;llvm-optimizer=not-used;llvm-targetmachine=not-used;object-emission=z_llvm;linker=zig-native-fno-lld
```

## Added Rows

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

Selection rule: add future rows through the registry and existing helper layer
first. Add a new helper only when at least one measured fixture exposes a
repeated shape; do not add ad hoc case bodies for count expansion.
