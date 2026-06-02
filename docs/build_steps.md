# Build Steps

This file summarizes the project-specific `zig build` steps and what each one
is for. Use `zig build --help` to see the authoritative current list.

## Core Steps

| Step | Purpose |
| --- | --- |
| `zig build` | Build and install the `z_llvm` executable into `zig-out/bin/z_llvm`. |
| `zig build run -- <args>` | Run `z_llvm` with arguments passed after `--`. |
| `zig build test` | Run the unit test suite. Use this for ordinary implementation slices that touch parser, verifier, optimizer, codegen, or shared tool behavior. |

## Validation Gates

| Step | Purpose |
| --- | --- |
| `zig build readiness` | Run the full readiness gate: unit tests, optimizer comparison, manifest linting, Zig corpus validation, handoff validation, and generated scalar differential checks. Use for parser, verifier, pass-manager, manifest, or broad evidence changes. |
| `zig build handoff` | Run optimizer-to-codegen handoff validation and selected x86_64 asm/object smoke checks. Use when optimizer output, codegen handoff, assembly emission, object emission, or selected Debug/O0 handoff behavior changes. |
| `zig build distribution-all` | Run the selected no-LLVM-codegen distribution subset, native-link proof/probe, Zig source native-link integration gate, and conservative boundary gates. Use for release-milestone evidence or matrix status changes. |
| `zig build distribution-no-llvm` | Run the selected no-LLVM-codegen x86_64 subset: ReleaseFast, ReleaseSafe, ReleaseSmall, Debug focused object/executable gates, plus handoff validation. Use when validating the positive selected distribution subset without the extra boundary checks. |
| `zig build distribution-boundary` | Run conservative boundary gates: linker/CRT ownership, ReleaseSmall exclusions, Debug unwind/DWARF boundary, and AArch64 object target boundary. Use when boundary docs or boundary behavior changes. |
| `zig build distribution-native-link` | Run selected native Zig linker handoff proof. This emits local objects with `z_llvm`, compiles C harnesses with `zig cc -c`, links with `zig build-exe -fno-lld`, and runs the executables. Use when proving native-linker compatibility for selected local objects. |
| `zig build distribution-zig-source-native-link` | Run the selected Zig source integration gate: stage4 Zig emits LLVM IR, `z_llvm` emits local objects, and Zig's native linker links with `zig build-exe -fno-lld`. Executable rows run; runtime-heavy rows are link-only boundary accounting. |
| `zig build distribution-zig-integrated-object` | Run the patched-Zig integrated postopt object-emission gate. Patched stage4 Zig `build-obj` lets LLVM run Zig's normal module optimization pipeline, writes optimized IR at the object boundary, invokes `z_llvm --emit=obj`, records a hook marker, then `zig build-exe -fno-lld -fno-compiler-rt -lc` links paired C ABI wrapper objects. Use when validating the experimental postopt replacement hook in `../ziglang`. |
| `zig build distribution-zig-integrated-preopt` | Run the patched-Zig integrated preopt gate. Patched stage4 Zig writes pre-optimization LLVM IR before `module_pm.run(...)`, invokes `z_llvm --passes=<accepted Zig-mode pipeline>` and then `z_llvm --emit=obj`, records mode/case/wrapper marker metadata, and links with Zig's native linker. Use `zig build distribution-zig-integrated-preopt -- --mode=ReleaseFast` for the narrow first-pass gate. |
| `zig build distribution-zig-ir-writer-tiny-scalar` | Run the first external z_llvm textual IR writer proof for `releasefast_tiny_scalar`. Patched stage4 Zig uses `ZIG_USE_ZLLVM_IR_WRITER=1` with `ZLLVM_IR_WRITER_MODE=external`, calls `z_llvm --emit=ir-writer` to write `scalar-add-ret` IR, then runs the existing preopt `z_llvm` optimizer/object path and Zig native linker. The executable exits 42. |
| `zig build distribution-zig-ir-writer` | Run the selected 75-row external z_llvm textual IR writer gate. This keeps wrapper/source fixture pairing, proves 75 runtime-surface rows and 0 minimal-wrapper rows, reports per-surface counts, fails on unexpected `minimal-ret0`, bypasses libLLVM bitcode parsing/printing and LLVM module optimization for the selected emitted wrapper objects, and leaves the normal libLLVM fallback untouched when the env var is unset. Use `--case=<case-id>` for focused rows; case IDs are defined in `tools/run_distribution_zig_integrated_object.zig`. |
| `zig build probe-native-linker` | Probe selected local objects against Zig native linker acceptance with `zig build-exe -fno-lld`, classifying the first failure by symbol, relocation, section, TLS model, COMDAT, alignment, ABI, or unknown linker compatibility. Use before promoting a native-linker object compatibility slice. |
| `zig build probe-native-linker-broad -- --mode=ReleaseFast\|ReleaseSafe\|ReleaseSmall\|Debug` | Probe broad optimized IR/input directories for link-only acceptance through Zig's native linker. This emits local `.o` files with `z_llvm`, generates safe stubs only for unresolved function symbols, links with `zig build-exe -fno-lld`, and records link-only counts separately from executable ABI proof. |
| `zig build distribution-native-link-boundary2` | Run the broad x86_64 native-link boundary gate for ReleaseFast, ReleaseSafe, ReleaseSmall, and Debug. This fails on any unclassified local object/link failure or generic `runtime-symbol` bucket, while accepting explicitly classified Zig runtime, TLS, compiler-rt/libc, or boundary-excluded rows. |
| `zig build distribution-native-link-releasefast` | Run the ReleaseFast native-link executable proof for the full current executable harness set. |
| `zig build distribution-native-link-releasesafe` | Run the ReleaseSafe native-link executable proof for the full current executable ABI set. |
| `zig build distribution-native-link-releasesmall` | Run the ReleaseSmall native-link executable proof for the full current executable ABI set. |
| `zig build distribution-native-link-debug` | Run only the selected Debug/O0 native-link executable proof. |
| `zig build probe-native-linker-releasefast` | Probe the ReleaseFast native-link object set for the full current executable harness set. |
| `zig build probe-native-linker-releasesafe` | Probe the ReleaseSafe native-link object set for the full current executable ABI set. |
| `zig build probe-native-linker-releasesmall` | Probe the ReleaseSmall native-link object set for the full current executable ABI set. |
| `zig build probe-native-linker-debug` | Probe only the selected Debug/O0 native-link object set. |
| `zig build distribution-musl-object` | Run selected x86_64 musl object subset gates. Use when target, object, ABI, relocation, or musl-specific object behavior changes. |
| `zig build distribution-musl-executable` | Run selected x86_64 musl executable ABI proof gates. Use when object output must be proven through Zig's musl linker/toolchain handoff. |

## External IR Writer Parameters

Focused runs use the same build step with arguments forwarded after `--`:

```bash
zig build distribution-zig-ir-writer -- --case=<case-id>
```

Parameters:

| Parameter | Description |
| --- | --- |
| no parameter | Run the full selected external IR-writer gate. |
| `--case=<case-id>` | Run one selected row. Use this for focused implementation slices and regressions. |
| `--mode=ReleaseFast\|ReleaseSafe\|ReleaseSmall` | Run selected rows for one Zig optimization mode when the runner supports that mode filter. |

Focused `--case` values:

| Case ID | Focus |
| --- | --- |
| `releasesmall_base64_table_lookup` | Table/global indexed-load regression. |
| `releasefast_runtime_cond_branch` | Runtime conditional branch. |
| `releasefast_runtime_phi_merge` | Phi/merge value. |
| `releasefast_runtime_loop_sum` | Loop sum. |
| `releasesafe_runtime_loop_sum` | ReleaseSafe checked loop-sum boundary. |
| `releasefast_runtime_switch` | Dense switch. |
| `releasesafe_runtime_branch_mix` | ReleaseSafe checked branch-mix boundary. |
| `releasefast_runtime_global_update` | Mutable global update. |
| `releasefast_runtime_pointer_load_store` | Pointer load/store. |
| `releasefast_runtime_volatile_roundtrip` | Volatile roundtrip. |
| `releasefast_runtime_optional_pointer` | Optional pointer. |
| `releasefast_runtime_packed_read_flag` | Packed read-flag. |
| `releasefast_runtime_packed_replace_low` | Packed replace-low. |
| `releasefast_runtime_struct_sum` | Struct field-sum. |
| `releasesafe_runtime_struct_sum` | ReleaseSafe checked struct-sum boundary. |
| `releasefast_runtime_array_sum` | Scalarized array-sum. |
| `releasesafe_runtime_array_sum` | ReleaseSafe checked array-sum boundary. |
| `releasefast_runtime_optional_payload` | Optional scalar-payload. |
| `releasefast_runtime_error_union_payload` | Error-union payload. |
| `releasefast_runtime_slice_sum` | Pointer-indexed slice-sum. |
| `releasesafe_runtime_slice_sum` | ReleaseSafe checked slice-sum boundary. |
| `releasefast_runtime_fp_constants` | FP literal-return. |
| `releasefast_runtime_comptime_const` | Comptime constant multiply. |
| `releasefast_runtime_debug_location` | Add-immediate return. |
| `releasesafe_runtime_debug_location` | ReleaseSafe checked add-immediate boundary. |
| `releasesafe_runtime_comptime_const` | ReleaseSafe checked comptime constant boundary. |
| `releasesafe_runtime_global_update` | ReleaseSafe checked global-update boundary. |
| `releasesafe_runtime_read_global` | ReleaseSafe global-load. |
| `releasesafe_runtime_pointer_load_store` | ReleaseSafe checked pointer load/store boundary. |
| `releasesafe_runtime_call_chain` | ReleaseSafe checked call-chain boundary. |
| `releasesafe_runtime_tls_bump` | ReleaseSafe checked TLS bump boundary. |
| `releasesafe_runtime_tls_read` | ReleaseSafe local-exec TLS read. |
| `releasesafe_runtime_side_effect_free` | ReleaseSafe no-op void-return. |
| `releasesmall_runtime_hidden_access` | ReleaseSmall hidden global load/store. |
| `releasesmall_runtime_mix_c_add_zig` | ReleaseSmall mixed C/Zig add. |
| `releasesmall_runtime_mix_c_add_may_panic` | ReleaseSmall mixed C/Zig panic-edge add. |
| `releasesmall_runtime_umul_fix_sat_i64` | ReleaseSmall `llvm.umul.fix.sat.i64`. |
| `releasesmall_runtime_inherit_want_safety_i64` | ReleaseSmall inherit-want-safety i64 return. |
| `releasesmall_runtime_compile_asm_unreachable` | ReleaseSmall compile-asm empty unreachable stub. |
| `releasesmall_runtime_str_from_float_help` | ReleaseSmall reduced `strFromFloatHelp` double prologue. |
| `releasesmall_runtime_base64_decode_step` | ReleaseSmall reduced base64 decoder table-load/OR/validity step. |
| `releasesmall_runtime_base64_store_step` | ReleaseSmall reduced base64 decoder output store step. |
| `releasesmall_runtime_base64_residual_byte_step` | ReleaseSmall reduced base64 decoder residual-byte emit step. |
| `releasesmall_runtime_base64_padding_tail_step` | ReleaseSmall reduced base64 decoder padding-tail byte check. |
| `releasesmall_runtime_base64_padding_loop_step` | ReleaseSmall reduced base64 decoder padding-tail loop walk. |
| `releasesmall_runtime_base64_padding_length_step` | ReleaseSmall reduced base64 decoder padding length adjustment. |
| `releasesmall_runtime_base64_chunk_guard_step` | ReleaseSmall reduced base64 decoder wide-chunk loop guard. |
| `releasesmall_runtime_base64_source_stride_step` | ReleaseSmall reduced base64 decoder source-byte stride/table load. |
| `releasesmall_runtime_base64_source_bundle_step` | ReleaseSmall reduced base64 decoder four-byte source bundle/table combine. |
| `releasesmall_runtime_base64_next_source_bundle_step` | ReleaseSmall reduced base64 decoder next four-byte source bundle/table combine. |
| `releasesmall_runtime_base64_third_source_bundle_step` | ReleaseSmall reduced base64 decoder third four-byte source bundle/table combine. |
| `releasesmall_runtime_base64_bit_buffer_store_step` | ReleaseSmall reduced base64 decoder i128 bit-buffer combine/store. |
| `releasefast_runtime_call_chain` | ABI-argument direct call. |
| `releasesmall_runtime_i64_call` | i64 call-return. |
| `releasefast_runtime_tls_read` | Local-exec TLS read. |
| `releasefast_runtime_tls_bump` | Local-exec TLS update. |
| `releasefast_runtime_atomic_add` | Atomic add. |
| `releasefast_runtime_inline_asm_barrier` | Inline-asm memory barrier. |
| `releasefast_runtime_aggregate_pair` | Two-i32 aggregate ABI. |
| `releasefast_runtime_float_less` | Ordered f32 compare. |
| `releasefast_runtime_float_mul` | f64 multiply. |
| `releasefast_runtime_float_add` | f32 add. |
| `releasefast_runtime_float_select` | f64 select. |
| `releasefast_runtime_float_sub` | f32 subtract. |
| `releasefast_runtime_double_div` | f64 divide. |
| `releasefast_runtime_float_rem` | f32 remainder. |

The executable gates hand local objects to Zig's driver through `zig cc`. They
prove Zig-driver/toolchain handoff, not necessarily native Zig linker use,
because Zig may still select an LLD-backed linker path internally.
`zig build distribution-native-link` is the stricter native-linker-only
execution proof for the selected ABI-stable subset. `zig build
probe-native-linker` is the matching selected acceptance probe. `zig build
probe-native-linker-broad -- --mode=...` is broader link-only evidence: it does
not claim ABI behavior, but it exposes object/linker compatibility problems.
A failure in either native-link probe becomes a local object compatibility task
unless evidence points to Zig-owned runtime/linker behavior.

## Utility Steps

These steps forward arguments after `--`.

| Step | Purpose |
| --- | --- |
| `zig build probe-distribution-objects -- <args>` | Run object-probe automation over an optimized-output directory. Use to produce stable ok/fail/excluded summaries and select the next measured object blocker. |
| `zig build capture-zig-ir -- <args>` | Capture authoritative Zig-emitted LLVM IR from the configured stage4 Zig emitter. Use when refreshing checked Zig source-backed fixtures. |

Examples:

```bash
zig build probe-distribution-objects -- \
  --input-dir=tmp/zig_ir/distribution_m3_releasesmall_20260531/optimized-ir \
  --summary=tmp/zig_ir/release_small_object_probe.summary

zig build capture-zig-ir -- test/zig/inputs/tiny_scalar.zig ReleaseFast
```

## Shell Scripts

There are no supported shell compatibility entrypoints. Current usage goes
through `zig build` steps. Archived roadmap documents may still mention old
script commands as historical transcripts; use the build steps above for new
validation runs.
