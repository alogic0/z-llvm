# x86_64 Structured IR Builder Milestone

This milestone adds `src/structured_ir_builder.zig` and moves a measured subset
of selected x86_64 release IR-writer rows from handwritten body strings to a
local structured construction API that prints LLVM-compatible textual IR.

## Measured Gate

```text
gate=zig build distribution-zig-ir-writer
total=136 executable_ok=136 link_only_ok=0 local_fail=0
structured_builder_rows=51
textual_subset_rows=85
minimal-ret0=0
ownership=llvm-module=not-used; llvm-optimizer=not-used;
          llvm-targetmachine=not-used; object-emission=z_llvm;
          linker=zig-native-fno-lld
```

The full selected gate fails if `structured_builder_rows < 30`, any selected
row reports `minimal-ret0`, any selected row reports libLLVM module
parse/print, or any selected row reports LLVM TargetMachine object emission.

## Converted Rows

The following selected rows now report
`ir-construction=zllvm-structured-builder`:

```text
releasefast_tiny_scalar
releasefast_source_tiny_scalar
releasefast_integers
releasefast_source_integers_add_wrap
releasefast_source_integers_cmp_shift
releasefast_error_switch
releasefast_source_error_switch_error_switch
releasefast_control_flow_calls
releasefast_source_control_flow_loop_sum
releasefast_source_control_flow_call_chain
releasefast_globals_comptime
releasesafe_runtime_read_global
releasefast_runtime_cond_branch
releasefast_source_switch_branch_mix
releasefast_runtime_phi_merge
releasefast_runtime_loop_sum
releasefast_runtime_switch
releasefast_source_switch_dense
releasesafe_runtime_branch_mix
releasefast_runtime_global_update
releasesafe_runtime_global_update
releasesafe_source_globals_checked
releasefast_runtime_pointer_load_store
releasefast_source_pointers_memory
releasesafe_runtime_pointer_load_store
releasesafe_source_pointers_memory_checked
releasefast_runtime_struct_sum
releasefast_source_aggregates_struct_sum
releasefast_runtime_array_sum
releasefast_source_aggregates_array_sum
releasefast_runtime_slice_sum
releasefast_source_aggregates_slice_sum
releasefast_runtime_fp_constants
releasefast_source_fp_constants_literals
releasefast_runtime_comptime_const
releasefast_source_globals_comptime_const
releasefast_source_globals_comptime_global_counter
releasefast_runtime_debug_location
releasefast_source_atomics_debug_location
releasefast_runtime_call_chain
releasefast_runtime_float_mul
releasefast_runtime_float_add
releasefast_source_floats_math
releasefast_runtime_float_sub
releasefast_source_fp_extended_ops
releasesafe_error_switch
releasesafe_source_error_switch_select
releasesafe_tiny_scalar_runtime_boundary
releasesafe_source_tiny_scalar_checked_add
releasesafe_source_switch_branch_mix_checked
releasesmall_globals_comptime
```

## Helper Families Covered

`src/structured_ir_builder.zig` now models modules, functions, named blocks,
values, types, constants, globals, TLS globals, branches, conditional branches,
returns, phis, binary operations, casts, integer/FP compares, selects, calls,
alloca, GEP, loads, stores, lifetime intrinsics, memcpy, memset, and checked
signed add/mul panic-edge helpers.

The first converted families are tiny scalar rows, integer arithmetic,
error-switch/select rows, direct-call and call-chain rows, global load/update
rows, loop/phi rows, pointer load/store rows, struct/array/slice rows, FP
literal and simple FP binary rows, and ReleaseSafe checked add/global/pointer
and branch panic-edge rows.

## Remaining Textual Rows

The 85 textual-subset rows remain valid selected evidence, but their bodies are
still emitted through the older helper/textual path. Remaining families include
i64 call/arithmetic, base64 table/full/reduced decoder rows, full
`strFromFloatHelp`, volatile/optional/packed/error-union rows, TLS and checked
TLS rows, atomics, inline asm, aggregate pair ABI, selected float-less/select,
double-div and float-rem rows, ReleaseSafe checked loop/call/aggregate/slice
rows, ReleaseSmall mixed C/Zig rows, hidden globals, fixed-point saturation,
inherit-want-safety, and compile-asm unreachable rows.

Those rows are future helper candidates only where repeated structure exists.
Highly specific semantic fixtures should stay case-specific until a reusable
structured helper removes real duplication.

## Boundary

This is not full Zig IR construction replacement. The structured builder still
prints LLVM-compatible textual IR, covers only selected x86_64 release-mode
IR-writer rows, and is invoked only under the explicit external writer
environment. It does not replace Zig's normal libLLVM-backed IR construction,
Debug/LTO/AArch64 paths, arbitrary source lowering, LLVM IR parsing for normal
fallback builds, compiler-rt/libc replacement, or target-complete object
coverage.
