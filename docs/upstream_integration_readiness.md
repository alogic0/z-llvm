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

### Parser/printer/verifier

Current capability:
Accepted scalar, control-flow, memory, global, and module records with SSA
checks.

Zig boundary:
LLVM-compatibility input validation.

### Scalar optimizer

Current capability:
Fixture-equivalent InstCombine, DCE, ADCE, SCCP, EarlyCSE, GVN, and BDCE
slices.

Zig boundary:
Possible Sema/AIR/native optimizer design input.

### Memory optimizer

Current capability:
Mem2Reg, SROA, DSE, alias/mod-ref, MemoryLocation, and conservative MemorySSA
slice.

Zig boundary:
LLVM-compatibility legality study; not a Zig stack model.

### Loop optimizer

Current capability:
LoopInfo, simple LCSSA helper, scalar LICM, and loop placeholders.

Zig boundary:
AIR/liveness loop optimization study.

### Metadata and mode handling

Current capability:
Debug/profile/module flags, attributes, ReleaseSmall, and target features are
preserved opaquely.

Zig boundary:
Mode and metadata preservation input.

### Backend handoff

Current capability:
Tiny x86_64 Machine IR plus asm/object smoke checks.

Zig boundary:
Validation-only, not a backend replacement.

### Selected distribution replacement gate

Current capability:
`distribution-x86_64-selected-zllvm` proves selected x86_64 release-mode
structured-direct IR-writer rows:

```text
total_rows=146
generic_x86_64_lowering_rows=146
textual_boundary_rows=0
libLLVM_module_parse_print_rows=0
llvm_optimizer_rows=0
llvm_targetmachine_rows=0
linker=zig-native-fno-lld
```

Zig boundary:
Selected release rows only; normal Zig/libLLVM fallback remains when env vars
are unset.

### Broad source-backed structured gate

Current capability:
`distribution-x86_64-source-backed-structured` discovers 55 x86_64 release
`.ll` fixtures and proves all accepted fixture families as structured rows:

```text
fixture_families=55
structured_direct_rows=90
generic_codegen_rows=90
skipped_with_reason=0
fallback_rows=0
textual_llvm_parse_fallback_rows=0
llvm_optimizer_rows=0
llvm_targetmachine_rows=0
object_emission=z_llvm
linker=zig-native
```

Zig boundary:
ReleaseFast/ReleaseSafe/ReleaseSmall x86_64 fixture inventory only; future
fixture expansion must fail closed on the first unsupported class.

### Source-owned DescriptorV2 gate

Current capability:
`distribution-x86_64-release-source-owned` proves the current 100-row x86_64
ReleaseFast/ReleaseSafe/ReleaseSmall source-owned wrapper inventory from
patched Zig compile-context facts.

The path does not use `ZLLVM_CASE_ID`, `ZLLVM_SOURCE_TAG`, wrapper basenames,
fixture metadata, body enum dispatch, or template-expansion ownership. Patched
Zig emits frozen `zllvm-source-facts-v1` `generic-compiler-facts`; z_llvm
classifies those facts into DescriptorV2 before verification and lowering.

Required ownership counters:

```text
release_source_rows=100
source_wrapper_rows=100
descriptor_owned_rows=100
descriptor_v2_rows=100
real_descriptor_program_rows=100
full_descriptor_program_rows=100
serialized_function_rows=100
serialized_instruction_rows=100
serialized_global_rows=100
semantic_serialized_rows=100
serialized_return_stub_rows=0
descriptor_body_name_rows=0
zllvm_body_expansion_rows=0
descriptor_program_body_expansion_rows=0
functions_for_body_rows=0
globals_for_body_rows=0
air_derived_descriptor_rows=100
static_descriptor_map_rows=0
zig_compile_context_descriptor_rows=100
env_source_tag_selector_rows=0
wrapper_body_selector_rows=0
source_tag_body_selector_rows=0
fixture_metadata_selector_rows=0
source_tag_env_present_rows=0
zig_emitted_descriptor_rows=100
runner_generated_descriptor_rows=0
descriptor_file_consumed_rows=100
source_fact_stream_rows=100
concrete_source_fact_rows=100
source_derived_descriptor_rows=100
tag_table_descriptor_rows=0
body_enum_dispatch_rows=0
surface_to_body_adapter_rows=0
canned_return_descriptor_rows=0
manual_fixture_dispatch_rows=0
legacy_semantic_record_rows=0
semantic_record_rows=0
external_writer_delegate_rows=0
manifest_structured_rows=0
case_id_rows=0
surface_dispatch_rows=0
structured_direct_rows=100
generic_codegen_rows=100
fallback_rows=0
local_fail=0
```

Additional ownership requirements:

```text
air_extracted_descriptor_rows=100
template_descriptor_rows=0
wrapper_body_map_rows=0
source_tag_body_map_rows=0
fact_derived_classification_rows=100
root_source_classification_fallback_rows=0
source_fact_program_rows=100
source_fact_program_direct_rows=100
source_fact_body_wrapper_rows=0
body_enum_fallback_rows=0
```

Release canonicalizer counters:

```text
release_canonicalizer_rows=100
observed_int_fold_rows=57
observed_fp_fold_rows=5
observed_dead_local_rows=41
observed_select_fcmp_rows=7
applied_int_fold_rows=57
applied_fp_fold_rows=5
applied_dead_local_rows=41
applied_select_fcmp_rows=7
checked_rows=9
checks_preserved_rows=9
```

Source-wrapper discovery counters:

```text
discovered_source_wrappers=82
descriptor_supported_wrappers=82
out_of_scope_wrappers=0
unsupported_with_reason=0
```

Zig boundary:
Current release source-owned wrapper inventory only. All 100 rows use
serialized AIR-shaped semantic records with compile-context fact provenance and
direct SourceFactProgram DescriptorV2 construction. This is not full Zig
Sema/AIR/Liveness replacement or full ReleaseSmall optimizer parity.

### Source-owned ELF object inspection

Current capability:
`distribution-native-link-object-inspection -- --release-source-owned` proves
the same 100-row boundary emits ELF64 relocatable x86_64 objects through the
patched-Zig source-owned z_llvm object path before Zig native linker handoff.

```text
inspected=100
elf64_rel=100
relocation_rows=12
tls_rows=8
undefined_import_rows=0
comdat_rows=0
eh_frame_rows=0
unsupported_relocation_rows=0
local_fail=0
```

Zig boundary:
Object-format proof only. Final linking, CRT policy, libc, dynamic loader
behavior, archives, linker scripts, and new-linker feature gaps remain Zig
linker/toolchain ownership.

### Source-owned native-link handoff

Current capability:
`distribution-native-link -- --release-source-owned` and
`probe-native-linker -- --release-source-owned` prove the same 100-row
source-owned boundary reaches Zig native `-fno-lld` linker handoff.

Executable gate counters:

```text
total=100
executable_abi_proof_rows=100
link_only_rows=0
runtime_compiler_rt_libc_boundary_rows=0
unsupported_zig_linker_feature_rows=0
local_object_codegen_failures=0
local_fail=0
```

Companion probe counters:

```text
accepted=100
runtime_compiler_rt_libc_boundary_rows=0
unsupported_zig_linker_feature_rows=0
local_object_codegen_failures=0
failed=0
```

Zig boundary:
Native linker ownership remains Zig-owned. This proves handoff acceptance and
runnable ABI behavior for selected source-owned wrappers, not a z_llvm linker
implementation.

### Uncurated real AIR compatibility gate

Current capability:
`distribution-zig-air-uncurated-release` discovers `test/zig/inputs/*.zig`,
asks patched Zig for `zllvm-air-export-v1` plus `structured_air-v1`
body/branch metadata and typed `structured_air-v2` records, and lowers real
ReleaseFast/ReleaseSafe/ReleaseSmall x86_64 AIR without case IDs, wrapper maps,
source-fact body classification, or canned DescriptorV2 construction.

Current counters for each mode:

```text
source_rows=19
discovered_functions=44
structured_functions=44
generic_codegen_functions=44
structured_air_v1_functions=44
structured_air_v2_functions=44
typed_air_type_functions=44
typed_air_operand_functions=44
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_lowering_functions=44
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
case_id_rows=0
source_fact_classification_rows=0
local_fail=0
```

Zig boundary:
Narrow compatibility gate retained for regression coverage. The broad real-AIR
release gates below carry the current strongest typed-v2 ownership claim.

### Broad uncurated ReleaseFast/ReleaseSafe/ReleaseSmall AIR discovery

Current capability:
`distribution-zig-air-uncurated-releasefast-broad`,
`distribution-zig-air-uncurated-releasesafe-broad`, and
`distribution-zig-air-uncurated-releasesmall-broad` discover
`test/zig/inputs/*.zig` plus `test/zig/integrated/*.zig`.

Discovery counters for each mode:

```text
source_rows=101
discovered_functions=152
structured_functions=152
generic_codegen_functions=152
generic_cfg_functions=152
structural_matcher_functions=0
structured_air_v1_functions=152
structured_air_v2_functions=152
typed_air_type_functions=152
typed_air_operand_functions=152
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_lowering_functions=152
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
case_id_rows=0
source_fact_classification_rows=0
local_fail=0
```

Object progress counters:

```text
object_emitted_functions=152
object_failures=0
llvm_targetmachine_rows=0
local_fail=0
```

Object-inspection counters:

```text
inspected=101
elf64_rel=101
relocation_rows=14
tls_rows=3
undefined_import_rows=3
comdat_rows=0
eh_frame_rows=0
unsupported_relocation_rows=0
local_fail=0
```

ReleaseFast and ReleaseSmall native-link progress:

```text
native_link_accepted_rows=100
executable_ok_rows=0
link_only_rows=100
runtime_boundary_rows=1
unsupported_zig_linker_feature_rows=0
native_link_failures=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

Executable proof counters for ReleaseFast, ReleaseSafe, and ReleaseSmall:

```text
native_link_accepted_rows=100
executable_ok_rows=100
link_only_rows=0
runtime_boundary_rows=1
unsupported_zig_linker_feature_rows=0
native_link_failures=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

Zig boundary:
Broad real-AIR lowering/codegen/object evidence for all three release modes.
The named runtime boundary is `debug.defaultPanic`. These gates stay out of
`distribution-all` until runtime and executable proof cost is known.

### Expanded uncurated release AIR frontier

Current capability:
`distribution-zig-air-uncurated-releasefast-expanded`,
`distribution-zig-air-uncurated-releasesafe-expanded`, and
`distribution-zig-air-uncurated-releasesmall-expanded` add explicit sources
under `test/zig/expanded/*.zig` on top of the closed broad corpus.

Discovery counters for all three release modes:

```text
source_rows=109
discovered_functions=199
structured_functions=199
generic_codegen_functions=199
generic_cfg_functions=199
structural_matcher_functions=0
structured_air_v2_functions=199
typed_air_operand_functions=199
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_lowering_functions=199
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
local_fail=0
```

Object progress:

```text
object_emitted_functions=199
object_failures=0
llvm_targetmachine_rows=0
local_fail=0
```

Object inspection:

```text
inspected=109
elf64_rel=109
relocation_rows=18  # 19 for ReleaseSafe
tls_rows=4
undefined_import_rows=3  # 6 for ReleaseSafe
comdat_rows=0
eh_frame_rows=0
unsupported_relocation_rows=0
local_fail=0
```

Native-link progress:

```text
ReleaseFast/ReleaseSmall:
native_link_accepted_rows=108
link_only_rows=108
runtime_boundary_rows=1

ReleaseSafe:
native_link_accepted_rows=105
link_only_rows=105
runtime_boundary_rows=4
```

Executable proof for all three modes:

```text
native_link_accepted_rows=108
executable_ok_rows=108
link_only_rows=0
runtime_boundary_rows=1
unsupported_zig_linker_feature_rows=0
native_link_failures=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

Zig boundary:
New frontier only. The slice closes additional scalar CFG, memory, call,
optional/error, branch/select, global/TLS, aggregate, atomic, inline-asm, and
expanded stack/mixed SysV ABI rows. Remaining non-selected ABI boundaries are
full aggregate classification beyond selected INTEGER/normal integer-leaf
MEMORY forms, arbitrary non-selected sret/byval copies, varargs, vectors, and
high-register-pressure spill/reload-heavy call frames.

### Scale uncurated release AIR frontier

Current capability:
`distribution-zig-air-uncurated-releasefast-scale`,
`distribution-zig-air-uncurated-releasesafe-scale`, and
`distribution-zig-air-uncurated-releasesmall-scale` add explicit sources under
`test/zig/scale/*.zig` on top of the expanded corpus.

Discovery and object counters:

```text
source_rows=112
discovered_functions=216
structured_functions=216
generic_codegen_functions=216
generic_cfg_functions=216
structural_matcher_functions=0
structured_air_v2_functions=216
typed_air_operand_functions=216
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_lowering_functions=216
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
object_emitted_functions=216
object_failures=0
llvm_targetmachine_rows=0
local_fail=0
```

Object inspection:

```text
inspected=112
elf64_rel=112
unsupported_relocation_rows=0
local_fail=0

ReleaseFast/ReleaseSmall:
relocation_rows=20
undefined_import_rows=3

ReleaseSafe:
relocation_rows=21
undefined_import_rows=6
```

Native-link progress:

```text
ReleaseFast/ReleaseSmall:
native_link_accepted_rows=111
link_only_rows=111
runtime_boundary_rows=1

ReleaseSafe:
native_link_accepted_rows=108
link_only_rows=108
runtime_boundary_rows=4
```

Executable proof:

```text
native_link_accepted_rows=111
executable_ok_rows=111
link_only_rows=0
runtime_boundary_rows=1
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

Zig boundary:
Frontier only. It keeps broad/expanded claims intact while adding broader SysV
call shapes, memory loops, branch-local pointer memory, extern two-i32 field
updates, direct-call branch merges, globals, and TLS.

### Frontier uncurated release AIR corpus

Current capability:
`distribution-zig-air-uncurated-release-frontier` covers only
`test/zig/frontier/*.zig`, separate from the cumulative broad, expanded, and
scale gates.

ReleaseFast/ReleaseSafe/ReleaseSmall counters:

```text
source_rows=13
discovered_functions=410
structured_functions=410
generic_codegen_functions=410
generic_cfg_functions=410
structural_matcher_functions=0
structured_air_v2_functions=410
typed_air_operand_functions=410
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_lowering_functions=410
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
object_emitted_functions=410
object_failures=0
llvm_targetmachine_rows=0
local_fail=0
```

Object inspection:

```text
inspected=13
elf64_rel=13
relocation_rows=4
tls_rows=1
undefined_import_rows=1
unsupported_relocation_rows=0
local_fail=0
```

Native-link and executable proof:

```text
native_link_accepted_rows=13
executable_ok_rows=13
link_only_rows=0
runtime_boundary_rows=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

Accepted frontier evidence:

```text
typed_air_v2=accepted
generic_cfg=accepted
selected_nested_loop_memory=accepted
selected_aggregate_field_pointer_gep_global_tls=accepted
selected_sysv_integer_integer=accepted
selected_nested_integer_aggregate=accepted
selected_nested_mixed_aggregate=accepted
selected_array_integer_and_sse_aggregate=accepted
selected_f32_pair_aggregate_call_passthrough=accepted
selected_stack_passed_register_aggregate_fields=accepted
selected_memory_sret_byval_integer_leaf=accepted
selected_mixed_width_memory_aggregate=accepted
selected_array_backed_memory_copy_read=accepted
selected_mixed_integer_sse_and_sse_integer=accepted
selected_sse_sse_aggregate=accepted
selected_f32_array_aggregate=accepted
selected_up_to_six_live_i32_spills=accepted
selected_up_to_six_stack_passed_live_i32=accepted
selected_six_stack_passed_i32_call_args=accepted
selected_two_call_six_live_i32_gpr_frame=accepted
selected_ordered_i32_call_result_across_second_call=accepted
selected_two_i32_call_results_across_calls=accepted
selected_indirect_two_i32_call_results_across_calls=accepted
selected_two_i32_call_results_across_later_void_call=accepted
selected_two_i32_call_results_across_indirect_later_void_call=accepted
selected_two_i64_call_results_across_calls=accepted
selected_i64_call_result_across_later_void_call=accepted
selected_two_i64_call_results_across_later_void_call=accepted
selected_one_to_six_live_f32_f64_spills=accepted
selected_two_live_f32_f64_arg_call_spills=accepted
selected_xmm0_to_xmm4_call_args=accepted
backend_fp_constants_xmm0_to_xmm7=accepted
```

Remaining non-accepted blockers:

```text
broader aggregate lowering beyond selected INTEGER/SSE/MEMORY frontier
arbitrary non-selected sret/byval copies
varargs
vectors
stack-passed live-value scheduling beyond the current selected direct-call/void-call model
broader SSE live-across-call helpers beyond selected no-argument-call shapes, selected repeated two-live direct/pointer-callee no-argument shapes, selected mixed one-GPR/one-SSE i32/i64 one-/two-call direct/pointer-callee shapes, selected direct two-/three-/six-live FP-argument shapes, pointer-callee shapes through six live values and five FP helper arguments, selected direct/pointer-callee f32/f64 call-result live-across-later-call frames, selected same-width two-result f32/f64 call frames, selected mixed f32/f64 two-result call frames, selected mixed f32/f64 two-result frames with one live double or i64 addend, selected mixed i64/f64, i64/f32, f64/i64, and f32/i64 two-result frames, selected direct/pointer-callee i64 result live-across-later-void frames, and selected direct/pointer-callee two-result i64 live-across-later-void frames
alternate safety-guard control flow
```

Zig boundary:
New source-frontier evidence only. Accepted rows use typed AIR v2 and generic
CFG; unsupported rows remain measured boundaries.

### Source-wrapper compatibility gate

Current capability:
`distribution-zig-source-structured-direct` proves 49 selected x86_64 release
Zig source wrappers without case-id dispatch ownership:

```text
source_wrappers=49
case_id_rows=0
structured_direct_rows=49
generic_codegen_rows=49
fallback_rows=0
semantic_record_rows=48
external_writer_delegate_rows=1
```

Zig boundary:
Unambiguous wrapper/mode subset only; weaker than the source-owned release gate.

### Differential testing

Current capability:
Generated scalar diff runner plus fail-closed negative generation.

Zig boundary:
Regression infrastructure input.

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
source-wrapper dispatch and source-owned semantic-record lowering ladder for
selected rows
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
