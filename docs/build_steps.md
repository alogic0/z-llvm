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
| `zig build distribution-all` | Run the selected no-LLVM-codegen distribution subset, source-owned release proof, native-link object inspection/proof/probe, Zig source native-link integration gate, and conservative boundary gates. This is a milestone confirmation gate, not the development loop. Use it before handoff, before committing a broad claim change, or when evidence from several gates must be refreshed together. |
| `zig build distribution-no-llvm` | Run the selected no-LLVM-codegen x86_64 subset: ReleaseFast, ReleaseSafe, ReleaseSmall, Debug focused object/executable gates, plus handoff validation. Use when validating the positive selected distribution subset without the extra boundary checks. |
| `zig build distribution-boundary` | Run conservative boundary gates: linker/CRT ownership, ReleaseSmall exclusions, Debug unwind/DWARF boundary, and AArch64 object target boundary. Use when boundary docs or boundary behavior changes. |
| `zig build distribution-native-link-object-inspection` | Inspect selected `z_llvm` ELF64 relocatable objects before Zig native linker handoff. It runs `readelf -W -h -S -s -r` and `objdump -dr`, validates section flags/alignment, symbols, relocations, TLS shape, undefined imports, and rejects COMDAT or `.eh_frame` until those are modeled. Use `--release-source-owned` to inspect the full 100-row x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall source-owned replacement boundary through the same patched-Zig z_llvm object path; that mode checks the patched stage4 hook and runs `zig build` during setup, so treat it as a milestone/object-boundary confirmation gate rather than a tiny inner-loop check. The current source-owned object-format proof reports `inspected=100`, `elf64_rel=100`, `relocation_rows=12`, `tls_rows=8`, `undefined_import_rows=0`, `comdat_rows=0`, `eh_frame_rows=0`, `unsupported_relocation_rows=0`, and `local_fail=0`. Use before native-link executable gates when object layout, relocation, symbol, or TLS emission changes. |
| `zig build distribution-native-link` | Run selected native Zig linker handoff proof. This emits local objects with `z_llvm`, compiles C harnesses with `zig cc -c`, links with `zig build-exe -fno-lld`, and runs the executables. Use `--release-source-owned` to reuse the 100-row x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall source-owned inventory and the same patched-Zig z_llvm object path as object inspection; the current source-owned native-link handoff reports `total=100`, `executable_abi_proof_rows=100`, `link_only_rows=0`, `runtime_compiler_rt_libc_boundary_rows=0`, `unsupported_zig_linker_feature_rows=0`, `local_object_codegen_failures=0`, and `local_fail=0`. Use when proving native-linker compatibility for selected local objects. |
| `zig build distribution-zig-source-native-link` | Run the selected Zig source integration gate: stage4 Zig emits LLVM IR, `z_llvm` emits local objects, and Zig's native linker links with `zig build-exe -fno-lld`. Executable rows run; runtime-heavy rows are link-only boundary accounting. |
| `zig build distribution-zig-integrated-object` | Run the patched-Zig integrated postopt object-emission gate. Patched stage4 Zig `build-obj` lets LLVM run Zig's normal module optimization pipeline, writes optimized IR at the object boundary, invokes `z_llvm --emit=obj`, records a hook marker, then `zig build-exe -fno-lld -fno-compiler-rt -lc` links paired C ABI wrapper objects. Use when validating the experimental postopt replacement hook in `../ziglang`. |
| `zig build distribution-zig-integrated-preopt` | Run the patched-Zig integrated preopt gate. Patched stage4 Zig writes pre-optimization LLVM IR before `module_pm.run(...)`, invokes `z_llvm --passes=<accepted Zig-mode pipeline>` and then `z_llvm --emit=obj`, records mode/case/wrapper marker metadata, and links with Zig's native linker. Use `zig build distribution-zig-integrated-preopt -- --mode=ReleaseFast` for the narrow first-pass gate. |
| `zig build distribution-zig-ir-writer-tiny-scalar` | Run the first external z_llvm textual IR writer proof for `releasefast_tiny_scalar`. Patched stage4 Zig uses `ZIG_USE_ZLLVM_IR_WRITER=1` with `ZLLVM_IR_WRITER_MODE=external`, calls `z_llvm --emit=ir-writer` to write `scalar-add-ret` IR, then runs the existing preopt `z_llvm` optimizer/object path and Zig native linker. The executable exits 42. |
| `zig build distribution-zig-ir-writer` | Run the selected 146-row z_llvm IR writer gate. This keeps wrapper/source fixture pairing, proves 146 runtime-surface rows and 0 minimal-wrapper rows, reports per-surface counts, structured-direct ownership counts, generic/case-specific x86_64 codegen counts, and downstream ownership summary. It fails on unexpected `minimal-ret0`, anything other than 146 structured-direct rows, any structured textual LLVM parsing, any textual boundary row, any case-specific codegen row, libLLVM module parse/print fallback, or LLVM TargetMachine fallback. All selected rows build z_llvm-owned internal IR modules directly and use generic x86_64 lowering. The selected rows bypass libLLVM bitcode parsing/printing, LLVM module optimization, LLVM TargetMachine object emission, and LLD; the normal libLLVM fallback remains untouched when the env var is unset. Use `--case=<case-id>` for focused rows; case IDs are defined in `tools/run_distribution_zig_integrated_object.zig`. |
| `zig build distribution-zig-source-structured-direct` | Run the source-wrapper structured-direct compatibility gate. Patched Zig still passes wrapper/mode/target/output/marker metadata, but z_llvm resolves the structured module from wrapper/source metadata instead of using `ZLLVM_CASE_ID` as the primary selector. The current gate reports `source_wrappers=49`, `structured_direct_rows=49`, `case_id_rows=0`, `generic_codegen_rows=49`, `manifest_structured_rows=0`, `semantic_record_rows=48`, `external_writer_delegate_rows=1`, `case_specific_rows=0`, `fallback_rows=0`, and `local_fail=0`. |
| `zig build distribution-x86_64-release-source-owned` | Run the strongest current x86_64 release source-owned gate. It covers the current ReleaseFast/ReleaseSafe/ReleaseSmall source-owned wrapper inventory. Patched Zig emits one frozen `zllvm-source-facts-v1` compile-context fact stream per row with `facts_contract_version=1` and `facts_payload=generic-compiler-facts`, including root source path, mode, target, wrapper, diagnostic fixture, function inventory, exported/main signature, parameter/return types, block/instruction counts, instruction-category summaries, globals, TLS, calls, atomics, and inline-asm capability facts. It does not read or token-count wrapper source and must not emit DescriptorV2 bodies, body names, case IDs, source tags, fixture selectors, wrapper/body maps, source-tag maps, or z_llvm surface names. z_llvm consumes that generic fact stream, classifies it into DescriptorV2 rows, verifies DescriptorV2, lowers it to structured-direct IR, and requires no `ZLLVM_CASE_ID`, `ZLLVM_SOURCE_TAG`, wrapper basename map, source-tag map, fixture selector, body enum dispatch, or template expansion ownership. The full gate requires `release_source_rows=100`, `source_wrapper_rows=100`, `descriptor_owned_rows=100`, `descriptor_v2_rows=100`, `real_descriptor_program_rows=100`, `full_descriptor_program_rows=100`, `serialized_function_rows=100`, `serialized_instruction_rows=100`, `serialized_global_rows=100`, `semantic_serialized_rows=100`, `serialized_return_stub_rows=0`, `descriptor_body_name_rows=0`, `zllvm_body_expansion_rows=0`, `descriptor_program_body_expansion_rows=0`, `functions_for_body_rows=0`, `globals_for_body_rows=0`, `air_derived_descriptor_rows=100`, `static_descriptor_map_rows=0`, `zig_compile_context_descriptor_rows=100`, `env_source_tag_selector_rows=0`, `wrapper_body_selector_rows=0`, `source_tag_body_selector_rows=0`, `fixture_metadata_selector_rows=0`, `source_tag_env_present_rows=0`, `zig_emitted_descriptor_rows=100`, `runner_generated_descriptor_rows=0`, `descriptor_file_consumed_rows=100`, `source_fact_stream_rows=100`, `concrete_source_fact_rows=100`, `source_derived_descriptor_rows=100`, `tag_table_descriptor_rows=0`, `body_enum_dispatch_rows=0`, `surface_to_body_adapter_rows=0`, `canned_return_descriptor_rows=0`, `manual_fixture_dispatch_rows=0`, `legacy_semantic_record_rows=0`, `semantic_record_rows=0`, `external_writer_delegate_rows=0`, `manifest_structured_rows=0`, `case_id_rows=0`, `surface_dispatch_rows=0`, `structured_direct_rows=100`, `generic_codegen_rows=100`, `fallback_rows=0`, `air_extracted_descriptor_rows=100`, `template_descriptor_rows=0`, `wrapper_body_map_rows=0`, `source_tag_body_map_rows=0`, and `local_fail=0`. It now requires `fact_derived_classification_rows=100`, `source_fact_program_rows=100`, `source_fact_program_direct_rows=100`, `source_fact_body_wrapper_rows=0`, `root_source_classification_fallback_rows=0`, and `body_enum_fallback_rows=0`, so the 100-row inventory no longer uses root-source/body-enum fallback. It also requires the z_llvm release canonicalizer on every row and distinguishes observed from applied transformations. The current gate reports `release_canonicalizer_rows=100`, `observed_int_fold_rows=57`, `observed_fp_fold_rows=5`, `observed_dead_local_rows=41`, `observed_select_fcmp_rows=7`, `applied_int_fold_rows=57`, `applied_fp_fold_rows=5`, `applied_dead_local_rows=41`, `applied_select_fcmp_rows=7`, `checked_rows=9`, and `checks_preserved_rows=9`; eligible rows fail if they only observe integer/FP/select/CFG opportunities without applying them. The 7-family wrong-facts probe still rejects mismatched wrapper/fact streams without using root source as a body selector. Use `zig run tools/run_distribution_zig_integrated_object.zig -- --release-source-owned --case=<case-id>` for the focused source-owned row loop. |
| `zig build distribution-zig-air-uncurated-releasefast` | Discover every `.zig` file in `test/zig/inputs`, ask the frozen patched-Zig hook for `zllvm-air-export-v1`, and parse/lower real function AIR and liveness without case IDs, wrapper maps, source-fact body classification, or canned program construction. The hook includes `structured_air-v1` body/branch metadata and typed `structured_air-v2` records. The current x86_64 ReleaseFast result is `source_rows=19`, `discovered_functions=44`, `structured_functions=44`, `generic_codegen_functions=44`, `structured_air_v1_functions=44`, `structured_air_v2_functions=44`, `typed_air_type_functions=44`, `typed_air_operand_functions=44`, `legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`, `generic_lowering_functions=44`, `shape_recognizer_functions=0`, `unsupported_functions=0`, `codegen_failures=0`, `case_id_rows=0`, `source_fact_classification_rows=0`, and `local_fail=0`. Closed families include aggregate ABI helper function types, error-union switch/payload paths, optional pointer/payload paths, loops/branches/switches, slice pointer arithmetic, base64-style `array_elem_val`, packed bit access, simple inline-asm barrier lowering, and FP literal return codegen. |
| `zig build distribution-zig-air-uncurated-releasefast-broad` | Run the broader ReleaseFast real-AIR discovery gate over `test/zig/inputs/*.zig` plus `test/zig/integrated/*.zig`. This is a milestone-cost discovery/progress gate, not part of `distribution-all`. Current measured output is `source_rows=101`, `discovered_functions=152`, `structured_functions=152`, `generic_codegen_functions=152`, `generic_cfg_functions=152`, `structural_matcher_functions=0`, `structured_air_v1_functions=152`, `structured_air_v2_functions=152`, `typed_air_type_functions=152`, `typed_air_operand_functions=152`, `legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`, `generic_lowering_functions=152`, `shape_recognizer_functions=0`, `unsupported_functions=0`, `codegen_failures=0`, `case_id_rows=0`, `source_fact_classification_rows=0`, and `local_fail=0`. The typed-v2 ownership audit is recorded in `docs/roadmap/x86_64_air_shape_recognizer_audit.md`. |
| `zig build distribution-zig-air-uncurated-releasefast-expanded` | Run the expanded ReleaseFast real-AIR frontier corpus: the closed broad corpus plus explicit sources in `test/zig/expanded/*.zig`. Current diagnostic snapshot is `source_rows=109`, `discovered_functions=199`, `structured_functions=199`, `generic_codegen_functions=199`, `generic_cfg_functions=199`, `structural_matcher_functions=0`, `structured_air_v2_functions=199`, `typed_air_operand_functions=199`, `legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`, `generic_lowering_functions=199`, `shape_recognizer_functions=0`, `unsupported_functions=0`, `codegen_failures=0`, and `local_fail=0`; see `docs/roadmap/x86_64_expanded_air_corpus.md`. |
| `zig build distribution-zig-air-uncurated-releasefast-expanded-object` | Emit z_llvm ELF relocatable objects for the expanded ReleaseFast real-AIR functions. Current counters are `object_emitted_functions=199`, `object_failures=0`, `llvm_targetmachine_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasefast-scale` | Run the scale ReleaseFast real-AIR frontier corpus: the expanded corpus plus explicit sources in `test/zig/scale/*.zig`. Current counters are `source_rows=112`, `discovered_functions=216`, `generic_codegen_functions=216`, `generic_cfg_functions=216`, `structural_matcher_functions=0`, `legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`, `shape_recognizer_functions=0`, `unsupported_functions=0`, `codegen_failures=0`, `object_emitted_functions=216`, `object_failures=0`, `llvm_targetmachine_rows=0`, and `local_fail=0`; see `docs/roadmap/x86_64_scale_air_corpus.md`. |
| `zig build distribution-zig-air-uncurated-releasefast-scale-object-inspection` | Inspect scale ReleaseFast real-AIR source-module objects with `readelf -W -h -S -s -r` and `objdump -dr`. Current counters are `inspected=112`, `elf64_rel=112`, `relocation_rows=20`, `tls_rows=5`, `undefined_import_rows=3`, `comdat_rows=0`, `eh_frame_rows=0`, `unsupported_relocation_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasefast-scale-native-link` | Link scale ReleaseFast real-AIR z_llvm objects with Zig's native linker using `zig build-exe -fno-lld`. Current counters are `native_link_accepted_rows=111`, `executable_ok_rows=0`, `link_only_rows=111`, `runtime_boundary_rows=1` (`debug.defaultPanic`), `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasefast-scale-executable` | Run stable C-ABI executable probes for scale ReleaseFast real-AIR z_llvm objects. Current counters are `native_link_accepted_rows=111`, `executable_ok_rows=111`, `link_only_rows=0`, `runtime_boundary_rows=1` (`debug.defaultPanic`), `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasefast-frontier` | Run the isolated frontier ReleaseFast real-AIR corpus under `test/zig/frontier/*.zig` with object progress. Current counters are `source_rows=13`, `discovered_functions=51`, `generic_codegen_functions=51`, `generic_cfg_functions=51`, `structural_matcher_functions=0`, `legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`, `shape_recognizer_functions=0`, `unsupported_functions=0`, `codegen_failures=0`, `object_emitted_functions=51`, `object_failures=0`, `llvm_targetmachine_rows=0`, and `local_fail=0`; see `docs/roadmap/x86_64_frontier_air_corpus.md`. |
| `zig build distribution-zig-air-uncurated-releasefast-frontier-object-inspection` | Inspect frontier ReleaseFast real-AIR source-module objects. Current counters are `inspected=13`, `elf64_rel=13`, `relocation_rows=3`, `tls_rows=1`, `undefined_import_rows=0`, `comdat_rows=0`, `eh_frame_rows=0`, `unsupported_relocation_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasefast-frontier-native-link` | Link frontier ReleaseFast real-AIR z_llvm objects with Zig's native linker using `zig build-exe -fno-lld`. Current counters are `native_link_accepted_rows=13`, `executable_ok_rows=0`, `link_only_rows=13`, `runtime_boundary_rows=0`, `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasefast-frontier-executable` | Run stable C-ABI executable probes for frontier ReleaseFast real-AIR z_llvm objects. Current counters are `native_link_accepted_rows=13`, `executable_ok_rows=13`, `link_only_rows=0`, `runtime_boundary_rows=0`, `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasefast-expanded-object-inspection` | Inspect expanded ReleaseFast real-AIR source-module objects with `readelf -W -h -S -s -r` and `objdump -dr`. Current counters are `inspected=109`, `elf64_rel=109`, `relocation_rows=18`, `tls_rows=4`, `undefined_import_rows=3`, `comdat_rows=0`, `eh_frame_rows=0`, `unsupported_relocation_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasefast-expanded-native-link` | Link expanded ReleaseFast real-AIR z_llvm objects with Zig's native linker using `zig build-exe -fno-lld`. Current counters are `native_link_accepted_rows=108`, `executable_ok_rows=0`, `link_only_rows=108`, `runtime_boundary_rows=1` (`debug.defaultPanic`), `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasefast-expanded-executable` | Run stable C-ABI executable probes for expanded ReleaseFast real-AIR z_llvm objects. Current counters are `native_link_accepted_rows=108`, `executable_ok_rows=108`, `link_only_rows=0`, `runtime_boundary_rows=1` (`debug.defaultPanic`), `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasefast-broad-object` | Emit z_llvm ELF relocatable objects for the broad ReleaseFast real-AIR functions without invoking LLVM TargetMachine. Current progress counters are `object_emitted_functions=152`, `object_failures=0`, `llvm_targetmachine_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasefast-broad-object-inspection` | Inspect broad ReleaseFast real-AIR source-module objects with `readelf -W -h -S -s -r` and `objdump -dr`. Current counters are `inspected=101`, `elf64_rel=101`, `relocation_rows=14`, `tls_rows=3`, `undefined_import_rows=3`, `comdat_rows=0`, `eh_frame_rows=0`, `unsupported_relocation_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasefast-broad-native-link` | Link the broad ReleaseFast real-AIR z_llvm objects with Zig's native linker using `zig build-exe -fno-lld`. This is a progress gate outside `distribution-all`: it uses a tiny C `main` harness per source module, so accepted rows are link-only evidence, not executable ABI proof. Current counters are `native_link_accepted_rows=100`, `executable_ok_rows=0`, `link_only_rows=100`, `runtime_boundary_rows=1` (`debug.defaultPanic`), `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasefast-broad-executable` | Run stable C-ABI executable probes for broad ReleaseFast real-AIR z_llvm objects, while keeping named runtime imports as runtime boundaries. This is a progress gate outside `distribution-all`. Current counters are `native_link_accepted_rows=100`, `executable_ok_rows=100`, `link_only_rows=0`, `runtime_boundary_rows=1` (`debug.defaultPanic`), `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesafe` | Run the same uncurated real-AIR gate in `ReleaseSafe` mode over the same 19-source corpus. It filters the broad ReleaseSafe export to root-source functions, preserves safe return/store/cast opcode variants, and rejects unsupported safety/runtime shapes with explicit AIR opcode diagnostics. The current x86_64 ReleaseSafe result matches ReleaseFast: `source_rows=19`, `discovered_functions=44`, `structured_functions=44`, `generic_codegen_functions=44`, `structured_air_v1_functions=44`, `structured_air_v2_functions=44`, `typed_air_type_functions=44`, `typed_air_operand_functions=44`, `legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`, `generic_lowering_functions=44`, `shape_recognizer_functions=0`, `unsupported_functions=0`, `codegen_failures=0`, `case_id_rows=0`, `source_fact_classification_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesafe-broad` | Run the broad ReleaseSafe real-AIR gate over `test/zig/inputs/*.zig` plus `test/zig/integrated/*.zig`. Current measured output matches ReleaseFast: `source_rows=101`, `discovered_functions=152`, `structured_functions=152`, `generic_codegen_functions=152`, `generic_cfg_functions=152`, `structural_matcher_functions=0`, `structured_air_v1_functions=152`, `structured_air_v2_functions=152`, `typed_air_type_functions=152`, `typed_air_operand_functions=152`, `legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`, `generic_lowering_functions=152`, `shape_recognizer_functions=0`, `unsupported_functions=0`, `codegen_failures=0`, `case_id_rows=0`, `source_fact_classification_rows=0`, and `local_fail=0`. The typed-v2 ownership audit is recorded in `docs/roadmap/x86_64_air_shape_recognizer_audit.md`. |
| `zig build distribution-zig-air-uncurated-releasesafe-expanded` | Run the expanded ReleaseSafe real-AIR frontier corpus. Current counters match ReleaseFast: `source_rows=109`, `discovered_functions=199`, `generic_codegen_functions=199`, `generic_cfg_functions=199`, `structural_matcher_functions=0`, `legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`, `shape_recognizer_functions=0`, `unsupported_functions=0`, `codegen_failures=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesafe-expanded-object` | Emit z_llvm ELF relocatable objects for the expanded ReleaseSafe real-AIR functions. Current counters match ReleaseFast object progress: `object_emitted_functions=199`, `object_failures=0`, `llvm_targetmachine_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesafe-scale` | Run the scale ReleaseSafe real-AIR frontier corpus. Current counters match ReleaseFast scale: `source_rows=112`, `discovered_functions=216`, `generic_codegen_functions=216`, `generic_cfg_functions=216`, `structural_matcher_functions=0`, `legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`, `shape_recognizer_functions=0`, `unsupported_functions=0`, `codegen_failures=0`, `object_emitted_functions=216`, `object_failures=0`, `llvm_targetmachine_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesafe-scale-object-inspection` | Inspect scale ReleaseSafe real-AIR source-module objects. Current counters are `inspected=112`, `elf64_rel=112`, `relocation_rows=21`, `tls_rows=5`, `undefined_import_rows=6`, `comdat_rows=0`, `eh_frame_rows=0`, `unsupported_relocation_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesafe-scale-native-link` | Link scale ReleaseSafe real-AIR z_llvm objects with Zig's native linker using `zig build-exe -fno-lld`. Current counters are `native_link_accepted_rows=108`, `executable_ok_rows=0`, `link_only_rows=108`, `runtime_boundary_rows=4` (`debug.defaultPanic`, `outOfBounds`, `integerPartOutOfBounds`, `unwrapNull`), `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesafe-scale-executable` | Run stable C-ABI executable probes for scale ReleaseSafe real-AIR z_llvm objects. Current counters are `native_link_accepted_rows=111`, `executable_ok_rows=111`, `link_only_rows=0`, `runtime_boundary_rows=1` (`debug.defaultPanic`), `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesafe-frontier` | Run the isolated frontier ReleaseSafe real-AIR corpus with object progress. Current counters match ReleaseFast frontier: `source_rows=13`, `discovered_functions=51`, `generic_cfg_functions=51`, `structural_matcher_functions=0`, `object_emitted_functions=51`, `object_failures=0`, `llvm_targetmachine_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesafe-frontier-object-inspection` | Inspect frontier ReleaseSafe real-AIR source-module objects. Current counters match ReleaseFast frontier inspection: `inspected=13`, `elf64_rel=13`, `relocation_rows=3`, `tls_rows=1`, `undefined_import_rows=0`, `unsupported_relocation_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesafe-frontier-native-link` | Link frontier ReleaseSafe real-AIR z_llvm objects with Zig's native linker using `zig build-exe -fno-lld`. Current counters match ReleaseFast frontier native-link progress: `native_link_accepted_rows=13`, `link_only_rows=13`, `runtime_boundary_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesafe-frontier-executable` | Run stable C-ABI executable probes for frontier ReleaseSafe real-AIR z_llvm objects. Current counters match ReleaseFast frontier executable progress: `native_link_accepted_rows=13`, `executable_ok_rows=13`, `link_only_rows=0`, `runtime_boundary_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesafe-expanded-object-inspection` | Inspect expanded ReleaseSafe real-AIR source-module objects. Current counters are `inspected=109`, `elf64_rel=109`, `relocation_rows=19`, `tls_rows=4`, `undefined_import_rows=6`, `comdat_rows=0`, `eh_frame_rows=0`, `unsupported_relocation_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesafe-expanded-native-link` | Link expanded ReleaseSafe real-AIR z_llvm objects with Zig's native linker using `zig build-exe -fno-lld`. Current counters are `native_link_accepted_rows=105`, `executable_ok_rows=0`, `link_only_rows=105`, `runtime_boundary_rows=4` (`debug.defaultPanic`, `outOfBounds`, `integerPartOutOfBounds`, `unwrapNull`), `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesafe-expanded-executable` | Run stable C-ABI executable probes for expanded ReleaseSafe real-AIR z_llvm objects. Current counters match ReleaseFast expanded executable progress: `native_link_accepted_rows=108`, `executable_ok_rows=108`, `link_only_rows=0`, `runtime_boundary_rows=1` (`debug.defaultPanic`), `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesafe-broad-object` | Emit z_llvm ELF relocatable objects for the broad ReleaseSafe real-AIR functions without invoking LLVM TargetMachine. Current progress counters are `object_emitted_functions=152`, `object_failures=0`, `llvm_targetmachine_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesafe-broad-object-inspection` | Inspect broad ReleaseSafe real-AIR source-module objects with `readelf -W -h -S -s -r` and `objdump -dr`. Current counters are `inspected=101`, `elf64_rel=101`, `relocation_rows=14`, `tls_rows=3`, `undefined_import_rows=3`, `comdat_rows=0`, `eh_frame_rows=0`, `unsupported_relocation_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesafe-broad-executable` | Run the same stable C-ABI executable probe machinery in ReleaseSafe mode. This is a separate milestone-cost progress gate outside `distribution-all`. Current counters are `native_link_accepted_rows=100`, `executable_ok_rows=100`, `link_only_rows=0`, `runtime_boundary_rows=1` (`debug.defaultPanic`), `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesmall-broad` | Run the broad ReleaseSmall real-AIR gate over `test/zig/inputs/*.zig` plus `test/zig/integrated/*.zig`. Current measured output matches ReleaseFast: `source_rows=101`, `discovered_functions=152`, `structured_functions=152`, `generic_codegen_functions=152`, `generic_cfg_functions=152`, `structural_matcher_functions=0`, `structured_air_v1_functions=152`, `structured_air_v2_functions=152`, `typed_air_type_functions=152`, `typed_air_operand_functions=152`, `legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`, `generic_lowering_functions=152`, `shape_recognizer_functions=0`, `unsupported_functions=0`, `codegen_failures=0`, `case_id_rows=0`, `source_fact_classification_rows=0`, and `local_fail=0`. This is release-mode ownership progress, not full ReleaseSmall size-optimizer parity. |
| `zig build distribution-zig-air-uncurated-releasesmall-expanded` | Run the expanded ReleaseSmall real-AIR frontier corpus. Current counters match ReleaseFast: `source_rows=109`, `discovered_functions=199`, `generic_codegen_functions=199`, `generic_cfg_functions=199`, `structural_matcher_functions=0`, `legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`, `shape_recognizer_functions=0`, `unsupported_functions=0`, `codegen_failures=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesmall-expanded-object` | Emit z_llvm ELF relocatable objects for the expanded ReleaseSmall real-AIR functions. Current counters match ReleaseFast object progress: `object_emitted_functions=199`, `object_failures=0`, `llvm_targetmachine_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesmall-scale` | Run the scale ReleaseSmall real-AIR frontier corpus. Current counters match ReleaseFast scale: `source_rows=112`, `discovered_functions=216`, `generic_codegen_functions=216`, `generic_cfg_functions=216`, `structural_matcher_functions=0`, `legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`, `shape_recognizer_functions=0`, `unsupported_functions=0`, `codegen_failures=0`, `object_emitted_functions=216`, `object_failures=0`, `llvm_targetmachine_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesmall-scale-object-inspection` | Inspect scale ReleaseSmall real-AIR source-module objects. Current counters match ReleaseFast scale inspection: `inspected=112`, `elf64_rel=112`, `relocation_rows=20`, `tls_rows=5`, `undefined_import_rows=3`, `comdat_rows=0`, `eh_frame_rows=0`, `unsupported_relocation_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesmall-scale-native-link` | Link scale ReleaseSmall real-AIR z_llvm objects with Zig's native linker using `zig build-exe -fno-lld`. Current counters match ReleaseFast scale native-link progress: `native_link_accepted_rows=111`, `executable_ok_rows=0`, `link_only_rows=111`, `runtime_boundary_rows=1` (`debug.defaultPanic`), `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesmall-scale-executable` | Run stable C-ABI executable probes for scale ReleaseSmall real-AIR z_llvm objects. Current counters match ReleaseFast scale executable progress: `native_link_accepted_rows=111`, `executable_ok_rows=111`, `link_only_rows=0`, `runtime_boundary_rows=1` (`debug.defaultPanic`), `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesmall-frontier` | Run the isolated frontier ReleaseSmall real-AIR corpus with object progress. Current counters match ReleaseFast frontier: `source_rows=13`, `discovered_functions=51`, `generic_cfg_functions=51`, `structural_matcher_functions=0`, `object_emitted_functions=51`, `object_failures=0`, `llvm_targetmachine_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesmall-frontier-object-inspection` | Inspect frontier ReleaseSmall real-AIR source-module objects. Current counters match ReleaseFast frontier inspection: `inspected=13`, `elf64_rel=13`, `relocation_rows=3`, `tls_rows=1`, `undefined_import_rows=0`, `unsupported_relocation_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesmall-frontier-native-link` | Link frontier ReleaseSmall real-AIR z_llvm objects with Zig's native linker using `zig build-exe -fno-lld`. Current counters match ReleaseFast frontier native-link progress: `native_link_accepted_rows=13`, `link_only_rows=13`, `runtime_boundary_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesmall-frontier-executable` | Run stable C-ABI executable probes for frontier ReleaseSmall real-AIR z_llvm objects. Current counters match ReleaseFast frontier executable progress: `native_link_accepted_rows=13`, `executable_ok_rows=13`, `link_only_rows=0`, `runtime_boundary_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesmall-expanded-object-inspection` | Inspect expanded ReleaseSmall real-AIR source-module objects. Current counters match ReleaseFast inspection: `inspected=109`, `elf64_rel=109`, `relocation_rows=18`, `tls_rows=4`, `undefined_import_rows=3`, `comdat_rows=0`, `eh_frame_rows=0`, `unsupported_relocation_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesmall-expanded-native-link` | Link expanded ReleaseSmall real-AIR z_llvm objects with Zig's native linker using `zig build-exe -fno-lld`. Current counters match ReleaseFast expanded native-link progress: `native_link_accepted_rows=108`, `executable_ok_rows=0`, `link_only_rows=108`, `runtime_boundary_rows=1` (`debug.defaultPanic`), `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesmall-expanded-executable` | Run stable C-ABI executable probes for expanded ReleaseSmall real-AIR z_llvm objects. Current counters match ReleaseFast expanded executable progress: `native_link_accepted_rows=108`, `executable_ok_rows=108`, `link_only_rows=0`, `runtime_boundary_rows=1` (`debug.defaultPanic`), `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesmall-broad-object` | Emit z_llvm ELF relocatable objects for the broad ReleaseSmall real-AIR functions without invoking LLVM TargetMachine. Current progress counters are `object_emitted_functions=152`, `object_failures=0`, `llvm_targetmachine_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesmall-broad-object-inspection` | Inspect broad ReleaseSmall real-AIR source-module objects with `readelf -W -h -S -s -r` and `objdump -dr`. Current counters are `inspected=101`, `elf64_rel=101`, `relocation_rows=14`, `tls_rows=3`, `undefined_import_rows=3`, `comdat_rows=0`, `eh_frame_rows=0`, `unsupported_relocation_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesmall-broad-native-link` | Link broad ReleaseSmall real-AIR z_llvm objects with Zig's native linker using `zig build-exe -fno-lld`. Current counters are `native_link_accepted_rows=100`, `executable_ok_rows=0`, `link_only_rows=100`, `runtime_boundary_rows=1` (`debug.defaultPanic`), `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-releasesmall-broad-executable` | Run the stable C-ABI executable probe machinery in ReleaseSmall mode. Current counters are `native_link_accepted_rows=100`, `executable_ok_rows=100`, `link_only_rows=0`, `runtime_boundary_rows=1` (`debug.defaultPanic`), `unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. |
| `zig build distribution-zig-air-uncurated-release-broad-finish` | Strict milestone gate for broad x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall typed AIR v2 ownership and object emission. It runs all three modes with `--corpus=broad --object-progress --strict-finish` and fails unless each mode reports `source_rows=101`, `discovered_functions=152`, `structured_functions=152`, `generic_codegen_functions=152`, `generic_cfg_functions>0`, `typed_air_operand_functions=152`, `legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`, `shape_recognizer_functions=0`, `unsupported_functions=0`, `codegen_failures=0`, `object_emitted_functions=152`, `object_failures=0`, and `local_fail=0`. This is a milestone-cost gate and is not part of `distribution-all`. |
| `zig build distribution-zig-air-uncurated-release-expanded-finish` | Strict milestone gate for the expanded x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall typed AIR v2 slice and object emission. It runs all three modes with `--corpus=expanded --object-progress --strict-finish` and fails unless each mode reports `source_rows=109`, `discovered_functions=199`, `generic_codegen_functions=199`, `generic_cfg_functions>0`, `typed_air_operand_functions=199`, `legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`, `shape_recognizer_functions=0`, `unsupported_functions=0`, `codegen_failures=0`, `object_emitted_functions=199`, `object_failures=0`, and `local_fail=0`. This is a milestone-cost gate and is not part of `distribution-all`. |
| `zig build distribution-zig-air-uncurated-release-scale` | Run the scale x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall frontier with object progress. It fails closed on unsupported functions, typed-v2 fallback, legacy AIR text fallback, shape recognizers, codegen failures, and object failures. Current per-mode counters are `source_rows=112`, `discovered_functions=216`, `generic_cfg_functions=216`, `structural_matcher_functions=0`, `object_emitted_functions=216`, `object_failures=0`, `llvm_targetmachine_rows=0`, and `local_fail=0`. This is a frontier gate outside `distribution-all`. |
| `zig build distribution-zig-air-uncurated-release-frontier` | Run the isolated frontier x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall corpus with object progress. It fails closed on unsupported functions, typed-v2 fallback, legacy AIR text fallback, shape recognizers, structural matcher fallback, codegen failures, and object failures. Current per-mode counters are `source_rows=13`, `discovered_functions=51`, `generic_cfg_functions=51`, `structural_matcher_functions=0`, `object_emitted_functions=51`, `object_failures=0`, `llvm_targetmachine_rows=0`, and `local_fail=0`. This is a frontier gate outside `distribution-all`. |
| `zig build distribution-zig-air-uncurated-release` | Run the uncurated real-AIR release gates for `ReleaseFast`, `ReleaseSafe`, and `ReleaseSmall`. Use this after shared AIR parsing/lowering changes; keep Debug, AArch64, LTO, object inspection, and native-link probes out of this inner loop. |

Set `ZLLVM_DEBUG_CODEGEN_PATHS=1` on any uncurated AIR gate to print
`codegen-path source=... function=... path=...` lines. Use this only for
backend ownership inventory; normal gates keep the compact summary output.
| `zig build distribution-x86_64-selected-zllvm` | Run the stable compact gate for the current selected x86_64 release replacement claim. This wraps the selected IR-writer gate and prints one machine-readable `selected-zllvm` line with total rows, executable/link-only counts, `structured_direct_rows`, `structured_textual_rows`, `textual_boundary_rows`, `generic_codegen_rows`, `case_specific_codegen_rows`, `minimal-ret0`, ownership marker, and first-failure fields. Diagnostics and reproducibility inputs are documented in `docs/x86_64_selected_zllvm_diagnostics.md`. |
| `zig build distribution-x86_64-source-backed-structured` | Run the broad x86_64 release source-backed structured-direct gate. It discovers `.ll` fixtures under the ReleaseFast, ReleaseSafe, ReleaseSmall, and former ReleaseSmall exclusion directories, requires every discovered fixture to be accepted, and fails on any skip, fallback, textual LLVM parse, non-generic codegen, or local failure. The current gate reports `discovered_fixtures=55`, `accepted_fixtures=55`, `source_backed_rows=90`, `structured_direct_rows=90`, `generic_codegen_rows=90`, `skipped_with_reason=0`, `fallback_rows=0`, and `local_fail=0`. |
| `zig build probe-native-linker` | Probe selected local objects against Zig native linker acceptance with `zig build-exe -fno-lld`, classifying the first failure by bad symbol binding/type, missing relocation support, section flag/alignment, TLS model, COMDAT, ABI, runtime/compiler-rt/libc boundary, or Zig linker bug/unsupported feature. Use `--release-source-owned` to run link-acceptance accounting over the same 100-row source-owned boundary; the current source-owned probe reports `accepted=100`, `runtime_compiler_rt_libc_boundary_rows=0`, `unsupported_zig_linker_feature_rows=0`, `local_object_codegen_failures=0`, and `failed=0`. Use before promoting a native-linker object compatibility slice. |
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

Focused selected-row runs use the same build step with arguments forwarded after
`--`:

```bash
zig build distribution-zig-ir-writer -- --case=<case-id>
```

Parameters:

| Parameter | Description |
| --- | --- |
| no parameter | Run the full selected external IR-writer gate. |
| `--case=<case-id>` | Run one selected row. Use this for focused implementation slices and regressions. |
| `--mode=ReleaseFast\|ReleaseSafe\|ReleaseSmall` | Run selected rows for one Zig optimization mode when the runner supports that mode filter. |

Focused source-owned rows should use the runner directly:

```bash
zig run tools/run_distribution_zig_integrated_object.zig -- --release-source-owned --case=<case-id>
```

Use this as the inner loop for source-owned row work. It runs the wrong-tag
and wrong-facts probes, the selected row, and the same per-row provenance checks as the full
source-owned gate, while scaling aggregate counters to the selected row set.

Recommended validation ladder for source-owned work:

```text
1. zig run tools/run_distribution_zig_integrated_object.zig -- --release-source-owned --case=<case-id>
2. zig build test
3. zig build distribution-x86_64-release-source-owned
4. zig build distribution-x86_64-selected-zllvm
5. zig build check-zig-stage4-emitter
6. zig build distribution-native-link-object-inspection -- --release-source-owned
7. zig build distribution-native-link -- --release-source-owned
8. zig build probe-native-linker -- --release-source-owned
9. zig build distribution-all
```

`distribution-native-link-object-inspection -- --release-source-owned` and
the source-owned native-link/probe gates are milestone confirmation gates, not
the development loop. The source-owned inspection and native-link modes
validate the patched stage4 hook and rebuild z_llvm before inspecting or
linking the 100-row boundary. Do not rebuild stage4 for every row. Patch Zig
only when the hook contract changes; otherwise stabilize the hook and iterate
in z_llvm with focused gates.

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
`zig build distribution-x86_64-release-source-owned`. It extends beyond the
90-row broad fixture gate to a 100-row source-owned wrapper inventory, and
requires every row to start from a Zig-emitted compile-context fact stream.
Patched Zig emits frozen `zllvm-source-facts-v1`
`generic-compiler-facts`, not row-specific DescriptorV2 bodies. The fact stream
includes root source path, mode, target, wrapper, diagnostic fixture,
source-tag presence, function inventory, exported/main function signature,
parameter and return types, concrete block/instruction counts,
instruction-category summaries, globals, TLS, calls, atomics, and inline-asm
capability facts. It is derived from compiler context and the LLVM builder
state already available at `Object.emit`; it does not read or token-count
wrapper source. z_llvm classifies that generic fact stream into DescriptorV2,
builds the structured records internally, and verifies/lower those records
without body-name payloads or deprecated selector ownership. The gate uses
`source-owned` dispatch rather than case-id ownership, reports
`lowering=semantic-descriptor-v2`, build a structured-direct module, use
generic x86_64 lowering, avoid fallback, and link through Zig's native linker
handoff. This gate fails unless `descriptor_owned_rows=100`,
`descriptor_v2_rows=100`, `real_descriptor_program_rows=100`,
`full_descriptor_program_rows=100`, `serialized_function_rows=100`,
`serialized_instruction_rows=100`, `serialized_global_rows=100`,
`semantic_serialized_rows=100`, `serialized_return_stub_rows=0`,
`descriptor_body_name_rows=0`, `zllvm_body_expansion_rows=0`,
`descriptor_program_body_expansion_rows=0`, `functions_for_body_rows=0`,
`globals_for_body_rows=0`,
`air_derived_descriptor_rows=100`, `static_descriptor_map_rows=0`,
`zig_emitted_descriptor_rows=100`, `runner_generated_descriptor_rows=0`,
`descriptor_file_consumed_rows=100`, `source_fact_stream_rows=100`,
`concrete_source_fact_rows=100`,
`source_derived_descriptor_rows=100`,
`tag_table_descriptor_rows=0`, `body_enum_dispatch_rows=0`,
`surface_to_body_adapter_rows=0`, `canned_return_descriptor_rows=0`,
`manual_fixture_dispatch_rows=0`, `legacy_semantic_record_rows=0`,
`semantic_record_rows=0`, `surface_dispatch_rows=0`, and
`external_writer_delegate_rows=0`. It also reports descriptor ownership
provenance; the current measured state is `air_extracted_descriptor_rows=100`,
`template_descriptor_rows=0`, `wrapper_body_map_rows=0`,
`source_tag_body_map_rows=0`, `zig_compile_context_descriptor_rows=100`,
`env_source_tag_selector_rows=0`, `wrapper_body_selector_rows=0`,
`source_tag_body_selector_rows=0`, `fixture_metadata_selector_rows=0`, and
`source_tag_env_present_rows=0`. It also reports
`fact_derived_classification_rows=100` and
`root_source_classification_fallback_rows=0`; the gate fails if any accepted row
uses root-source classification fallback, and a 7-family wrong-facts negative probe rejects filename/fact mismatches. It also
prints a source-wrapper discovery bucket from `test/zig/integrated/*.zig`; the
current bucket reports `discovered_source_wrappers=82`,
`descriptor_supported_wrappers=82`, `out_of_scope_wrappers=0`, and
`unsupported_with_reason=0`. Serialized AIR-shaped transport is proven for all
100 rows: every row emits semantic DescriptorV2 records instead of the serialized return stub
(`semantic_serialized_rows=100`, `serialized_return_stub_rows=0`). They cover
the simple scalar/control-flow rows plus repeated memory, aggregate, TLS, FP,
global, atomic, inline-asm barrier, checked-edge, simple ReleaseSmall boundary,
mixed C/Zig, i64, start/noreturn, address-space, raw-start, libfuzzer, base64
full/reduced/table, and `strFromFloatHelp` boundary families. Every
source-owned row now uses the extracted-record path with no body-map selector;
the
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
