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
| Source-owned DescriptorV2 gate | `distribution-x86_64-release-source-owned` proves the current 100-row x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall source-owned wrapper inventory from patched Zig compile-context descriptor extraction without `ZLLVM_CASE_ID`, `ZLLVM_SOURCE_TAG`, wrapper basename, fixture metadata, body enum, or template-expansion ownership: patched Zig emits `zllvm-source-derived-descriptor-v2` with serialized function/block/instruction/terminator/global-section records and z_llvm parses those records directly. Counters require `release_source_rows=100`, `source_wrapper_rows=100`, `descriptor_owned_rows=100`, `descriptor_v2_rows=100`, `real_descriptor_program_rows=100`, `full_descriptor_program_rows=100`, `serialized_function_rows=100`, `serialized_instruction_rows=100`, `serialized_global_rows=100`, `semantic_serialized_rows=100`, `serialized_return_stub_rows=0`, `descriptor_body_name_rows=0`, `zllvm_body_expansion_rows=0`, `descriptor_program_body_expansion_rows=0`, `functions_for_body_rows=0`, `globals_for_body_rows=0`, `air_derived_descriptor_rows=100`, `static_descriptor_map_rows=0`, `zig_compile_context_descriptor_rows=100`, `env_source_tag_selector_rows=0`, `wrapper_body_selector_rows=0`, `source_tag_body_selector_rows=0`, `fixture_metadata_selector_rows=0`, `source_tag_env_present_rows=0`, `zig_emitted_descriptor_rows=100`, `runner_generated_descriptor_rows=0`, `descriptor_file_consumed_rows=100`, `source_derived_descriptor_rows=100`, `tag_table_descriptor_rows=0`, `body_enum_dispatch_rows=0`, `surface_to_body_adapter_rows=0`, `canned_return_descriptor_rows=0`, `manual_fixture_dispatch_rows=0`, `legacy_semantic_record_rows=0`, `semantic_record_rows=0`, `external_writer_delegate_rows=0`, `manifest_structured_rows=0`, `case_id_rows=0`, `surface_dispatch_rows=0`, `structured_direct_rows=100`, `generic_codegen_rows=100`, `fallback_rows=0`, and `local_fail=0`. It also requires `air_extracted_descriptor_rows=100`, `template_descriptor_rows=0`, `wrapper_body_map_rows=0`, and `source_tag_body_map_rows=0`, so wrapper/source-tag/body-template ownership is rejected. The gate scans `test/zig/integrated/*.zig` as a source-wrapper discovery bucket and currently reports `discovered_source_wrappers=82`, `descriptor_supported_wrappers=82`, `out_of_scope_wrappers=0`, `unsupported_with_reason=0`. | Current release source-owned wrapper inventory only; all 100 rows use serialized AIR-shaped semantic records with compile-context provenance and no return-stub, static descriptor map fallback, template descriptor rows, or body-map selector rows. This is not full Zig Sema/AIR/Liveness replacement |
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
