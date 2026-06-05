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
| `zig build distribution-all` | Run the selected no-LLVM-codegen distribution subset, source-owned release proof, native-link proof/probe, Zig source native-link integration gate, and conservative boundary gates. Use for release-milestone evidence or matrix status changes. |
| `zig build distribution-no-llvm` | Run the selected no-LLVM-codegen x86_64 subset: ReleaseFast, ReleaseSafe, ReleaseSmall, Debug focused object/executable gates, plus handoff validation. Use when validating the positive selected distribution subset without the extra boundary checks. |
| `zig build distribution-boundary` | Run conservative boundary gates: linker/CRT ownership, ReleaseSmall exclusions, Debug unwind/DWARF boundary, and AArch64 object target boundary. Use when boundary docs or boundary behavior changes. |
| `zig build distribution-native-link` | Run selected native Zig linker handoff proof. This emits local objects with `z_llvm`, compiles C harnesses with `zig cc -c`, links with `zig build-exe -fno-lld`, and runs the executables. Use when proving native-linker compatibility for selected local objects. |
| `zig build distribution-zig-source-native-link` | Run the selected Zig source integration gate: stage4 Zig emits LLVM IR, `z_llvm` emits local objects, and Zig's native linker links with `zig build-exe -fno-lld`. Executable rows run; runtime-heavy rows are link-only boundary accounting. |
| `zig build distribution-zig-integrated-object` | Run the patched-Zig integrated postopt object-emission gate. Patched stage4 Zig `build-obj` lets LLVM run Zig's normal module optimization pipeline, writes optimized IR at the object boundary, invokes `z_llvm --emit=obj`, records a hook marker, then `zig build-exe -fno-lld -fno-compiler-rt -lc` links paired C ABI wrapper objects. Use when validating the experimental postopt replacement hook in `../ziglang`. |
| `zig build distribution-zig-integrated-preopt` | Run the patched-Zig integrated preopt gate. Patched stage4 Zig writes pre-optimization LLVM IR before `module_pm.run(...)`, invokes `z_llvm --passes=<accepted Zig-mode pipeline>` and then `z_llvm --emit=obj`, records mode/case/wrapper marker metadata, and links with Zig's native linker. Use `zig build distribution-zig-integrated-preopt -- --mode=ReleaseFast` for the narrow first-pass gate. |
| `zig build distribution-zig-ir-writer-tiny-scalar` | Run the first external z_llvm textual IR writer proof for `releasefast_tiny_scalar`. Patched stage4 Zig uses `ZIG_USE_ZLLVM_IR_WRITER=1` with `ZLLVM_IR_WRITER_MODE=external`, calls `z_llvm --emit=ir-writer` to write `scalar-add-ret` IR, then runs the existing preopt `z_llvm` optimizer/object path and Zig native linker. The executable exits 42. |
| `zig build distribution-zig-ir-writer` | Run the selected 146-row z_llvm IR writer gate. This keeps wrapper/source fixture pairing, proves 146 runtime-surface rows and 0 minimal-wrapper rows, reports per-surface counts, structured-direct ownership counts, generic/case-specific x86_64 codegen counts, and downstream ownership summary. It fails on unexpected `minimal-ret0`, anything other than 146 structured-direct rows, any structured textual LLVM parsing, any textual boundary row, any case-specific codegen row, libLLVM module parse/print fallback, or LLVM TargetMachine fallback. All selected rows build z_llvm-owned internal IR modules directly and use generic x86_64 lowering. The selected rows bypass libLLVM bitcode parsing/printing, LLVM module optimization, LLVM TargetMachine object emission, and LLD; the normal libLLVM fallback remains untouched when the env var is unset. Use `--case=<case-id>` for focused rows; case IDs are defined in `tools/run_distribution_zig_integrated_object.zig`. |
| `zig build distribution-zig-source-structured-direct` | Run the source-wrapper structured-direct compatibility gate. Patched Zig still passes wrapper/mode/target/output/marker metadata, but z_llvm resolves the structured module from wrapper/source metadata instead of using `ZLLVM_CASE_ID` as the primary selector. The current gate reports `source_wrappers=49`, `structured_direct_rows=49`, `case_id_rows=0`, `generic_codegen_rows=49`, `manifest_structured_rows=0`, `semantic_record_rows=48`, `external_writer_delegate_rows=1`, `case_specific_rows=0`, `fallback_rows=0`, and `local_fail=0`. |
| `zig build distribution-x86_64-release-source-owned` | Run the strongest current x86_64 release source-owned gate. It covers the full current ReleaseFast/ReleaseSafe/ReleaseSmall source-backed inventory, starts all rows from wrapper/source metadata rather than `ZLLVM_CASE_ID`, has patched Zig emit `zllvm-source-derived-descriptor-v2` with serialized function/block/instruction/terminator/global-section records, makes z_llvm parse those records directly, verifies DescriptorV2, lowers it to structured-direct IR, and requires `release_source_rows=90`, `source_wrapper_rows=90`, `descriptor_owned_rows=90`, `descriptor_v2_rows=90`, `real_descriptor_program_rows=90`, `full_descriptor_program_rows=90`, `serialized_function_rows=90`, `serialized_instruction_rows=90`, `serialized_global_rows=90`, `semantic_serialized_rows=90`, `serialized_return_stub_rows=0`, `descriptor_body_name_rows=0`, `zllvm_body_expansion_rows=0`, `descriptor_program_body_expansion_rows=0`, `functions_for_body_rows=0`, `globals_for_body_rows=0`, `air_derived_descriptor_rows=90`, `static_descriptor_map_rows=0`, `zig_emitted_descriptor_rows=90`, `runner_generated_descriptor_rows=0`, `descriptor_file_consumed_rows=90`, `source_derived_descriptor_rows=90`, `tag_table_descriptor_rows=0`, `body_enum_dispatch_rows=0`, `surface_to_body_adapter_rows=0`, `canned_return_descriptor_rows=0`, `manual_fixture_dispatch_rows=0`, `legacy_semantic_record_rows=0`, `semantic_record_rows=0`, `external_writer_delegate_rows=0`, `manifest_structured_rows=0`, `case_id_rows=0`, `surface_dispatch_rows=0`, `structured_direct_rows=90`, `generic_codegen_rows=90`, `fallback_rows=0`, `air_extracted_descriptor_rows=0`, `template_descriptor_rows=90`, `wrapper_body_map_rows=32`, `source_tag_body_map_rows=58`, and `local_fail=0`. |
| `zig build distribution-x86_64-selected-zllvm` | Run the stable compact gate for the current selected x86_64 release replacement claim. This wraps the selected IR-writer gate and prints one machine-readable `selected-zllvm` line with total rows, executable/link-only counts, `structured_direct_rows`, `structured_textual_rows`, `textual_boundary_rows`, `generic_codegen_rows`, `case_specific_codegen_rows`, `minimal-ret0`, ownership marker, and first-failure fields. Diagnostics and reproducibility inputs are documented in `docs/x86_64_selected_zllvm_diagnostics.md`. |
| `zig build distribution-x86_64-source-backed-structured` | Run the broad x86_64 release source-backed structured-direct gate. It discovers `.ll` fixtures under the ReleaseFast, ReleaseSafe, ReleaseSmall, and former ReleaseSmall exclusion directories, requires every discovered fixture to be accepted, and fails on any skip, fallback, textual LLVM parse, non-generic codegen, or local failure. The current gate reports `discovered_fixtures=55`, `accepted_fixtures=55`, `source_backed_rows=90`, `structured_direct_rows=90`, `generic_codegen_rows=90`, `skipped_with_reason=0`, `fallback_rows=0`, and `local_fail=0`. |
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

The 146-row full gate includes the original selected runtime rows plus 58
`releasefast_source_*` / `releasesafe_source_*` / `releasesmall_source_*`
rows backed by captured release-mode x86_64 fixtures. Those source rows
intentionally reuse existing surface names and helper-backed writer bodies.
As of the structured-direct closure milestone, all 146 selected rows are built
through `src/structured_ir_builder.zig` into z_llvm-owned internal IR modules.
The full gate enforces `structured_direct_rows=146`,
`structured_textual_rows=0`, `textual_boundary_rows=0`,
`generic_codegen_rows=146`, `case_specific_codegen_rows=0`, `minimal-ret0=0`,
no libLLVM module parse/print fallback, and no LLVM TargetMachine
object-emission fallback. The current measured codegen split is 146 generic
structured-direct rows and 0 case-specific structured-direct rows; see
`docs/roadmap/x86_64_codegen_genericity_audit.md`.

Selected rows print:

```text
construction=ir-construction=zllvm-structured-builder
llvm_text_parse=not-used
codegen_ownership=codegen=generic-x86_64-lowering
lowering_ownership=lowering=manifest-structured|lowering=zig-semantic-records|lowering=semantic-descriptor-v2|lowering=external-writer-delegate
ownership=llvm-module=not-used;llvm-optimizer=not-used;llvm-targetmachine=not-used;object-emission=z_llvm;linker=zig-native-fno-lld
```

No selected row remains a textual boundary, so the selected claim no longer
tracks textual-boundary reason accounting.

The broad source-backed gate is separate from the fixed 146-row selected claim.
It discovers 55 release fixture files and accepts all 55 fixture families as 90
structured-direct rows, with no skip accounting remaining for the current
inventory. Every broad row must report
`ir-construction=zllvm-structured-builder`, `llvm_text_parse=not-used`,
`codegen=generic-x86_64-lowering`, no libLLVM module parse/print, no LLVM
optimizer, no LLVM TargetMachine, `object-emission=z_llvm`, and
`linker=zig-native-fno-lld`.

The strongest current x86_64 release proof is
`zig build distribution-x86_64-release-source-owned`. It keeps the same 90-row
fixture inventory as the broad gate, but requires every row to start from Zig
wrapper/source metadata, have patched Zig emit serialized
`zllvm-source-derived-descriptor-v2` function/block/instruction/terminator/global
records, make z_llvm parse those records directly without body-name expansion,
use
`source-owned` dispatch rather than case-id ownership, report
`lowering=semantic-descriptor-v2`, build a structured-direct module, use
generic x86_64 lowering, avoid fallback, and link through Zig's native linker
handoff. This gate fails unless `descriptor_owned_rows=90`,
`descriptor_v2_rows=90`, `real_descriptor_program_rows=90`,
`full_descriptor_program_rows=90`, `serialized_function_rows=90`,
`serialized_instruction_rows=90`, `serialized_global_rows=90`,
`semantic_serialized_rows=90`, `serialized_return_stub_rows=0`,
`descriptor_body_name_rows=0`, `zllvm_body_expansion_rows=0`,
`descriptor_program_body_expansion_rows=0`, `functions_for_body_rows=0`,
`globals_for_body_rows=0`,
`air_derived_descriptor_rows=90`, `static_descriptor_map_rows=0`,
`zig_emitted_descriptor_rows=90`, `runner_generated_descriptor_rows=0`,
`descriptor_file_consumed_rows=90`, `source_derived_descriptor_rows=90`,
`tag_table_descriptor_rows=0`, `body_enum_dispatch_rows=0`,
`surface_to_body_adapter_rows=0`, `canned_return_descriptor_rows=0`,
`manual_fixture_dispatch_rows=0`, `legacy_semantic_record_rows=0`,
`semantic_record_rows=0`, `surface_dispatch_rows=0`, and
`external_writer_delegate_rows=0`. It also reports descriptor ownership
provenance; the current measured baseline is `air_extracted_descriptor_rows=0`,
`template_descriptor_rows=90`, `wrapper_body_map_rows=32`, and
`source_tag_body_map_rows=58`. It also
prints a source-wrapper discovery bucket from `test/zig/integrated/*.zig`; the
current bucket reports `discovered_source_wrappers=72`,
`descriptor_supported_wrappers=62`, `out_of_scope_wrappers=10`, and
`unsupported_with_reason=0`. Serialized AIR-shaped transport is proven for all
90 rows: every row emits semantic DescriptorV2 records instead of the serialized return stub
(`semantic_serialized_rows=90`, `serialized_return_stub_rows=0`). They cover
the simple scalar/control-flow rows plus repeated memory, aggregate, TLS, FP,
global, atomic, inline-asm barrier, checked-edge, simple ReleaseSmall boundary,
mixed C/Zig, i64, start/noreturn, address-space, raw-start, libfuzzer, base64
full/reduced/table, and `strFromFloatHelp` boundary families. These rows are
still emitted from body templates selected by wrapper/source-tag maps; the
inventory is tracked in
`docs/roadmap/x86_64_source_owned_descriptor_template_inventory.md`. The fixed 146-row
selected proof and the 90-row
broad source-backed proof remain regression gates with separate counters.

The source-wrapper gate is a third, narrower proof that starts from Zig source
wrappers without case-id ownership. It currently covers 49 unambiguous
wrapper/mode rows. Of those, 48 rows are lowered through semantic records in
`src/zig_semantic_lowering.zig` into `src/structured_ir_builder.zig`; one
compatibility row remains an external writer delegate. Details are in
`docs/roadmap/x86_64_source_wrapper_semantic_lowering.md`.

CI/distribution runs should prefer the compact claim gate:

```bash
zig build distribution-x86_64-selected-zllvm
```

It preserves the same selected-row failure policy while suppressing per-row
success logs.

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
| `releasesmall_runtime_base64_loop_advance_step` | ReleaseSmall reduced base64 decoder loop index advance/backedge. |
| `releasesmall_runtime_base64_residual_guard_step` | ReleaseSmall reduced base64 decoder residual/preheader guard. |
| `releasesmall_runtime_base64_residual_bundle_step` | ReleaseSmall reduced base64 decoder residual four-byte source/table bundle. |
| `releasesmall_runtime_base64_residual_store_step` | ReleaseSmall reduced base64 decoder residual output store/backedge. |
| `releasesmall_runtime_base64_residual_length_step` | ReleaseSmall reduced base64 decoder residual remaining-length calculation. |
| `releasesmall_runtime_base64_residual_table_check_step` | ReleaseSmall reduced base64 decoder residual byte/table validity check. |
| `releasesmall_runtime_base64_residual_accumulator_step` | ReleaseSmall reduced base64 decoder residual accumulator update. |
| `releasesmall_runtime_base64_residual_loop_advance_step` | ReleaseSmall reduced base64 decoder residual loop-index advance. |
| `releasesmall_runtime_base64_residual_padding_check_step` | ReleaseSmall reduced base64 decoder residual padding byte/offset check. |
| `releasesmall_runtime_base64_residual_final_mask_step` | ReleaseSmall reduced base64 decoder residual final mask guard. |
| `releasesmall_runtime_base64_residual_padding_loop_step` | ReleaseSmall reduced base64 decoder residual final padding loop. |
| `releasesmall_runtime_base64_decode_exit_step` | ReleaseSmall reduced base64 decoder exit/lifetime cleanup. |
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
