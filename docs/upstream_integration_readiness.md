# Upstream Integration Readiness

This document summarizes what the project can currently prove for Zig upstream
discussion and what must remain an external experiment.

## Reproducibility

```text
zig version
OPT_BIN=opt-22 zig build compare-opt --
zig build zig-corpus
zig build handoff
zig build generated-scalar-diff
zig build distribution-x86_64-selected-zllvm
zig build distribution-x86_64-release-source-owned
zig build distribution-zig-source-structured-direct
zig build readiness
```

The corpus docs record the Zig compiler version, target triple, optimize mode,
command, and captured IR path for each Zig-emitted fixture.

## Capability Map

| Subsystem | Current capability | Zig boundary |
| --- | --- | --- |
| Parser/printer/verifier | Accepted scalar/control-flow/memory/global/module records with SSA checks | LLVM-compatibility input validation |
| Scalar optimizer | Fixture-equivalent InstCombine, DCE, ADCE, SCCP, EarlyCSE, GVN, BDCE slices | Possible Sema/AIR/native optimizer design input |
| Memory optimizer | Mem2Reg, SROA, DSE, alias/mod-ref, MemoryLocation, conservative MemorySSA slice | LLVM-compatibility legality study; not a Zig stack model |
| Loop optimizer | LoopInfo, simple LCSSA helper, scalar LICM, loop placeholders | AIR/liveness loop optimization study |
| Metadata and mode handling | Debug/profile/module flags, attributes, ReleaseSmall, target features preserved opaquely | Mode and metadata preservation input |
| Backend handoff | Tiny x86_64 Machine IR, asm/object smoke checks | Validation-only, not a backend replacement |
| Selected distribution replacement gate | `distribution-x86_64-selected-zllvm` proves 146 selected x86_64 release-mode structured-direct IR-writer rows, with 146/146 rows on generic x86_64 lowering, no textual boundary rows, no libLLVM module parse/print, no LLVM optimizer, no LLVM TargetMachine object emission, and Zig native `-fno-lld` linking | Selected release rows only; normal Zig/libLLVM fallback remains when env vars are unset |
| Broad source-backed structured gate | `distribution-x86_64-source-backed-structured` discovers 55 x86_64 release `.ll` fixtures and proves all 55 accepted fixture families as 90 structured-direct/generic-codegen rows, with `skipped_with_reason=0`, `fallback_rows=0`, no textual LLVM parse fallback, no LLVM optimizer, no LLVM TargetMachine, z_llvm object emission, and Zig native linker handoff | ReleaseFast/ReleaseSafe/ReleaseSmall x86_64 fixture inventory only; future fixture expansion must fail closed on the first unsupported class |
| Source-owned DescriptorV2 gate | `distribution-x86_64-release-source-owned` proves the current 100-row x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall source-owned wrapper inventory from patched Zig compile-context facts without `ZLLVM_CASE_ID`, `ZLLVM_SOURCE_TAG`, wrapper basename, fixture metadata, body enum dispatch, or template-expansion ownership: patched Zig emits frozen `zllvm-source-facts-v1` `generic-compiler-facts` from compiler context and LLVM-builder summaries, and z_llvm classifies those facts into DescriptorV2 before verifying and lowering the records. Counters require `release_source_rows=100`, `source_wrapper_rows=100`, `descriptor_owned_rows=100`, `descriptor_v2_rows=100`, `real_descriptor_program_rows=100`, `full_descriptor_program_rows=100`, `serialized_function_rows=100`, `serialized_instruction_rows=100`, `serialized_global_rows=100`, `semantic_serialized_rows=100`, `serialized_return_stub_rows=0`, `descriptor_body_name_rows=0`, `zllvm_body_expansion_rows=0`, `descriptor_program_body_expansion_rows=0`, `functions_for_body_rows=0`, `globals_for_body_rows=0`, `air_derived_descriptor_rows=100`, `static_descriptor_map_rows=0`, `zig_compile_context_descriptor_rows=100`, `env_source_tag_selector_rows=0`, `wrapper_body_selector_rows=0`, `source_tag_body_selector_rows=0`, `fixture_metadata_selector_rows=0`, `source_tag_env_present_rows=0`, `zig_emitted_descriptor_rows=100`, `runner_generated_descriptor_rows=0`, `descriptor_file_consumed_rows=100`, `source_fact_stream_rows=100`, `concrete_source_fact_rows=100`, `source_derived_descriptor_rows=100`, `tag_table_descriptor_rows=0`, `body_enum_dispatch_rows=0`, `surface_to_body_adapter_rows=0`, `canned_return_descriptor_rows=0`, `manual_fixture_dispatch_rows=0`, `legacy_semantic_record_rows=0`, `semantic_record_rows=0`, `external_writer_delegate_rows=0`, `manifest_structured_rows=0`, `case_id_rows=0`, `surface_dispatch_rows=0`, `structured_direct_rows=100`, `generic_codegen_rows=100`, `fallback_rows=0`, and `local_fail=0`. It also requires `air_extracted_descriptor_rows=100`, `template_descriptor_rows=0`, `wrapper_body_map_rows=0`, and `source_tag_body_map_rows=0`, so wrapper/source-tag/body-template ownership is rejected. The gate now requires `fact_derived_classification_rows=100`, `root_source_classification_fallback_rows=0`, `source_fact_program_rows=100`, `source_fact_program_direct_rows=100`, `source_fact_body_wrapper_rows=0`, and `body_enum_fallback_rows=0`; a 7-family wrong-facts negative probe rejects mismatched wrapper/fact streams without using root source as a body selector. The DescriptorV2 path runs a local release canonicalizer before structured lowering and reports `release_canonicalizer_rows=100`, `observed_int_fold_rows=57`, `observed_fp_fold_rows=5`, `observed_dead_local_rows=41`, `observed_select_fcmp_rows=7`, `applied_int_fold_rows=57`, `applied_fp_fold_rows=5`, `applied_dead_local_rows=41`, `applied_select_fcmp_rows=7`, `checked_rows=9`, and `checks_preserved_rows=9`; eligible rows fail if they only observe integer/FP/select/CFG opportunities without applying them. The gate scans `test/zig/integrated/*.zig` as a source-wrapper discovery bucket and currently reports `discovered_source_wrappers=82`, `descriptor_supported_wrappers=82`, `out_of_scope_wrappers=0`, `unsupported_with_reason=0`. | Current release source-owned wrapper inventory only; all 100 rows use serialized AIR-shaped semantic records with compile-context fact provenance, direct SourceFactProgram DescriptorV2 construction, and no return-stub, static descriptor map fallback, template descriptor rows, body-map selector rows, root-source classification fallback, or body-enum fallback. This is not full Zig Sema/AIR/Liveness replacement or full ReleaseSmall optimizer parity |
| Source-owned ELF object inspection | `distribution-native-link-object-inspection -- --release-source-owned` proves the same 100-row x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall source-owned replacement boundary emits ELF64 relocatable x86_64 objects through the patched-Zig source-owned z_llvm object path before Zig native linker handoff. The gate runs `readelf -W -h -S -s -r` and `objdump -dr`, requiring accounted sections, symbol binding/type, relocation families, TLS local-exec behavior, no accidental COMDAT, no accidental `.eh_frame`, and no unsupported relocations. Current counters: `inspected=100`, `elf64_rel=100`, `relocation_rows=12`, `tls_rows=8`, `undefined_import_rows=0`, `comdat_rows=0`, `eh_frame_rows=0`, `unsupported_relocation_rows=0`, and `local_fail=0`. | Object-format proof only; final linking, CRT policy, libc, dynamic loader behavior, archives, linker scripts, and new-linker feature gaps remain Zig linker/toolchain ownership |
| Source-owned native-link handoff | `distribution-native-link -- --release-source-owned` and `probe-native-linker -- --release-source-owned` prove the same 100-row source-owned boundary reaches Zig native `-fno-lld` linker handoff from the patched-Zig z_llvm object path. Current executable gate counters: `total=100`, `executable_abi_proof_rows=100`, `link_only_rows=0`, `runtime_compiler_rt_libc_boundary_rows=0`, `unsupported_zig_linker_feature_rows=0`, `local_object_codegen_failures=0`, `local_fail=0`. Companion probe counters: `accepted=100`, `runtime_compiler_rt_libc_boundary_rows=0`, `unsupported_zig_linker_feature_rows=0`, `local_object_codegen_failures=0`, `failed=0`. | Native linker ownership remains Zig-owned; this proves handoff acceptance and runnable ABI behavior for the selected source-owned wrappers, not a z_llvm linker implementation |
| Uncurated real AIR compatibility gate | `distribution-zig-air-uncurated-release` discovers `test/zig/inputs/*.zig`, asks patched Zig for `zllvm-air-export-v1` plus `structured_air-v1` body/branch metadata and typed `structured_air-v2` records, and lowers real ReleaseFast/ReleaseSafe/ReleaseSmall x86_64 AIR without case IDs, wrapper maps, source-fact body classification, or canned DescriptorV2 construction. Current counters for each mode are `source_rows=19`, `discovered_functions=44`, `structured_functions=44`, `generic_codegen_functions=44`, `structured_air_v1_functions=44`, `structured_air_v2_functions=44`, `typed_air_type_functions=44`, `typed_air_operand_functions=44`, `legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`, `generic_lowering_functions=44`, `shape_recognizer_functions=0`, `unsupported_functions=0`, `codegen_failures=0`, `case_id_rows=0`, `source_fact_classification_rows=0`, and `local_fail=0`. | Narrow compatibility gate retained for regression coverage; the broad real-AIR release gates below carry the current strongest typed-v2 ownership claim |
| Broad uncurated ReleaseFast/ReleaseSafe/ReleaseSmall AIR discovery | `distribution-zig-air-uncurated-releasefast-broad`, `distribution-zig-air-uncurated-releasesafe-broad`, and `distribution-zig-air-uncurated-releasesmall-broad` discover `test/zig/inputs/*.zig` plus `test/zig/integrated/*.zig`. Each mode currently reports `source_rows=101`, `discovered_functions=152`, `structured_functions=152`, `generic_codegen_functions=152`, `generic_cfg_functions=65` for ReleaseFast/ReleaseSmall and `66` for ReleaseSafe, `structural_matcher_functions=87` for ReleaseFast/ReleaseSmall and `86` for ReleaseSafe, `structured_air_v1_functions=152`, `structured_air_v2_functions=152`, `typed_air_type_functions=152`, `typed_air_operand_functions=152`, `legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`, `generic_lowering_functions=152`, `shape_recognizer_functions=0`, `unsupported_functions=0`, `codegen_failures=0`, `case_id_rows=0`, `source_fact_classification_rows=0`, and `local_fail=0`. The companion object progress gates for all three modes report `object_emitted_functions=152`, `object_failures=0`, `llvm_targetmachine_rows=0`, and `local_fail=0`; the broad object-inspection gates report `inspected=101`, `elf64_rel=101`, `relocation_rows=14`, `tls_rows=3`, `undefined_import_rows=3`, `comdat_rows=0`, `eh_frame_rows=0`, `unsupported_relocation_rows=0`, and `local_fail=0`. Broad ReleaseFast and ReleaseSmall also have native-link progress gates using `zig build-exe -fno-lld`; each reports `native_link_accepted_rows=100`, `executable_ok_rows=0`, `link_only_rows=100`, `runtime_boundary_rows=1`, `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. The broad executable gates reuse the same object/native-link path and run stable C-ABI harnesses for runnable source modules in ReleaseFast, ReleaseSafe, and ReleaseSmall: `native_link_accepted_rows=100`, `executable_ok_rows=100`, `link_only_rows=0`, `runtime_boundary_rows=1`, `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0` for each mode. | Broad real-AIR lowering/codegen/object evidence for all three release modes. Broad real-AIR native-link has both link-only handoff accounting and executable ABI proof for stable callable rows. `structured_air-v1` and typed `structured_air-v2` are present for every broad function; typed v2 now owns straight-line scalar, load/store, global pointer constants, stack-slot, direct-call, runtime symbol pointer, simple block-result select, struct field-sum, array aggregate-sum, base64 table-lookup, aggregate pair ABI first/make-pair, error-union payload, maybe-error, optional scalar-payload, optional pointer-payload, error-switch/classifier, runtime optional-pointer wrapper main, runtime pointer load/store wrapper main, packed read/replace, slice-sum, selected monotonic atomic add, empty inline-asm memory-barrier, accumulator-loop, dense-switch, conditional slot-update, and mixed C/Zig panic-edge runtime-boundary lowering. No broad function uses legacy AIR text fallback or shape-recognizer ownership. A strict generic CFG x86_64 backend path now owns loop-sum, single-block scalar integer, scalar `icmp`/`select`, and ReleaseSafe checked guard CFGs where eligible, while remaining rows are still counted as structural matcher backend lowering. The closed link-only set was two input modules that needed C ABI harnesses plus two input modules and four integrated wrappers that needed exported global/TLS initializer facts and z_llvm initializer materialization. The named runtime boundary is `debug.defaultPanic`. These gates stay out of `distribution-all` until runtime and executable proof cost is known |
| Expanded uncurated release AIR frontier | `distribution-zig-air-uncurated-releasefast-expanded`, `distribution-zig-air-uncurated-releasesafe-expanded`, and `distribution-zig-air-uncurated-releasesmall-expanded` add explicit sources under `test/zig/expanded/*.zig` on top of the closed broad corpus. The first expanded slice is green for all three release modes and reports `source_rows=107`, `discovered_functions=168`, `structured_functions=168`, `generic_codegen_functions=168`, `generic_cfg_functions=67` for ReleaseFast/ReleaseSmall and `69` for ReleaseSafe, `structural_matcher_functions=101` for ReleaseFast/ReleaseSmall and `99` for ReleaseSafe, `structured_air_v2_functions=168`, `typed_air_operand_functions=168`, `legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`, `generic_lowering_functions=168`, `shape_recognizer_functions=0`, `unsupported_functions=0`, `codegen_failures=0`, and `local_fail=0`. The expanded finish gate reports `object_emitted_functions=168`, `object_failures=0`, `llvm_targetmachine_rows=0`, and `local_fail=0`; expanded object inspection reports `inspected=107`, `elf64_rel=107`, `relocation_rows=15` (`16` for ReleaseSafe), `tls_rows=4`, `undefined_import_rows=3` (`5` for ReleaseSafe), `comdat_rows=0`, `eh_frame_rows=0`, `unsupported_relocation_rows=0`, and `local_fail=0`. Expanded native-link/executable gates are green for all three modes at `native_link_accepted_rows=106`, `executable_ok_rows=106`, `link_only_rows=0`, `runtime_boundary_rows=1`, `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. | New frontier only; aggregate pair ABI function-type lowering, the f32 pipeline backend variant, renamed pointer load/store, expanded slice-loop lowering, optional-control-flow bucket expansion, expanded ELF object inspection, expanded executable ABI harnessing, scalar generic CFG backend routing, and first scalar branch/select CFG promotion are closed. The named runtime boundary remains `debug.defaultPanic`. It does not weaken the closed broad baseline |
| Source-wrapper compatibility gate | `distribution-zig-source-structured-direct` proves 49 selected x86_64 release Zig source wrappers without case-id dispatch ownership: `source_wrappers=49`, `case_id_rows=0`, `structured_direct_rows=49`, `generic_codegen_rows=49`, `fallback_rows=0`. Within that gate, 48 rows lower semantic records through `src/zig_semantic_lowering.zig`; one compatibility row remains an external writer delegate. | Unambiguous wrapper/mode subset only; weaker than the source-owned release gate |
| Differential testing | Generated scalar diff runner plus fail-closed negative generation | Regression infrastructure input |

## External Experiment Boundary

These parts should remain outside Zig upstream until they have stronger proof:

```text
full LLVM IR parser parity
full LLVM pass algorithm parity
target lowering, register allocation, scheduling, and ABI breadth
DWARF/CodeView/unwind emission
TLS lowering and linker integration
PGO, BFI/BPI, TTI, and size-cost decisions
EH pads, inline asm semantics, and full atomic memory model
bitcode writer, LTO, and ThinLTO summary behavior; Cycle 23 keeps these
deferred unless a concrete bitcode or linker-LTO handoff use case activates
that compatibility track
```

## Upstreamable Design Input

The parts most useful for upstream discussion are:

```text
Zig LLVM dependency inventory and pass-pipeline inventory
source-backed Zig-emitted IR corpus manifest
fixture metadata separating opt-equivalent from local-conservative behavior
MemorySSA/alias legality lessons for avoiding unsafe load CSE/GVN
AIR/liveness handoff matrix separating LLVM facts from Zig-native concepts
source-wrapper dispatch and source-owned semantic-record lowering ladder for selected rows
readiness check script that reproduces current claims
```

## Next Roadmap Wave

The next wave should be selected from Zig's actual LLVM-removal blockers:

```text
inline asm and atomicrmw IR representation with verifier fail-closed rules
vector lane-operation boundaries plus target-cost policy decisions
broader AArch64 promotion after target-independent scalar cleanup
Debug-mode reduction work for large source-backed Debug rows
path-aware MemorySSA only after a source-backed fixture requires it
```

The evidence behind that ordering is recorded in
`docs/roadmap/source_backed_readiness_audit.md`.

## Current Verdict

The project is useful as a structured LLVM-removal experiment and regression
corpus, but it is not an LLVM replacement. Its strongest upstream-facing value
is the inventory, fixture discipline, conservative legality boundaries, and
clear split between LLVM-compatible IR work and Zig-native backend ownership.
