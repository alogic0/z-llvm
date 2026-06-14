# x86_64 Distribution Replacement Matrix

This matrix tracks the initial `x86_64-linux-gnu` replacement path by Zig mode
and stage. It is narrower than the historical finish line: a row is useful only
when it changes, proves, or bounds removal of Zig's LLVM library fallback for
the selected distribution path.

Status keys:

```text
local replacement: current local implementation has source-backed evidence
conservative boundary: accepted locally only with documented narrower behavior
LLVM fallback required: Zig still needs LLVM or Zig-owned backend work here
out of scope: not part of the current x86_64 milestone
```

## Matrix

| Mode | Parse | Verify | Optimize | Handoff | Asm/Object |
| --- | --- | --- | --- | --- | --- |
| Debug | conservative boundary | conservative boundary | conservative boundary | conservative boundary | conservative boundary |
| ReleaseFast | local replacement | local replacement | local replacement | conservative boundary | conservative boundary |
| ReleaseSafe | local replacement | local replacement | local replacement | conservative boundary | conservative boundary |
| ReleaseSmall | local replacement | local replacement | local replacement | conservative boundary | conservative boundary |

## Evidence

ReleaseFast, ReleaseSafe, and ReleaseSmall parse/verify/optimize rows are backed
by the accepted x86_64 sweeps recorded in
`docs/roadmap/source_backed_readiness_audit.md`:

```text
tmp/zig_ir/accepted_20260530_193848_releasefast
tmp/zig_ir/accepted_20260530_195245_releasesafe
tmp/zig_ir/accepted_20260530_201347_releasesmall
```

Each completed with:

```text
processed=1474 compile_skip=1009 emit_ok=465 local_ok=465
input_too_large=0 parse_fail=0 verify_fail=0 optimizer_fail=0
```

Debug parse/verify/optimize remains a conservative boundary for the distribution
matrix because broad raw Debug rows are still future evidence; reduced Debug
metadata rows and the accepted Debug sweep prove only the documented local
subset.

Debug asm/object is a conservative boundary for the adjusted continuous
captured subset, not target-complete Debug backend ownership. A bounded reduced
object probe is also clean for selected Debug fixtures:

```text
zig build distribution-debug-object
  target=x86_64-unknown-linux-gnu
  inputs=test/zig/expected/debug_*.reduced.ll plus selected Debug/O0
         distribution fixtures
  object_probe=pass
  covered_shapes=call-chain add-immediate, dbg.declare/dbg.value no-op object
                 lowering, simple loop sum, metadata add, scope branch phi,
                 O0 alloca debug prologue plus volatile pointer roundtrip,
                 Debug/O0 c_* panic-call unreachable stubs,
                 Debug/O0 f128 sret C ABI shape,
                 selected Debug/O0 libfuzzer runner aliases
  excluded=DWARF/unwind emission, full O0 codegen, variable-location salvage,
           broad Debug std rows, target-complete ABI lowering
```

The selected broad raw Debug rows also have object evidence:

```text
source=tmp/zig_ir/raw/tiny_scalar.Debug.x86_64.ll
probe=tmp/zig_ir/debug_object_probe_tiny_scalar_20260531/ir
object_probe=1 ok, 0 fail
closed_boundaries=#dbg_* records dropped as non-semantic object records,
                  ret/unreachable metadata accepted, sizeless DIBasicType,
                  columnless DILocation

source=tmp/zig_ir/raw/control_flow_calls.Debug.ll
probe=tmp/zig_ir/debug_object_probe_control_flow_calls_20260531/ir
object_probe=1 ok, 0 fail

source=tmp/zig_ir/raw/pointers_memory.Debug.ll
probe=tmp/zig_ir/debug_object_probe_pointers_memory_20260531/ir
object_probe=1 ok, 0 fail
closed_boundary=selected O0 alloca debug prologue before volatile pointer
                store/load roundtrip

source=tmp/zig_ir/raw/tiny_scalar.Debug.ll
probe=tmp/zig_ir/debug_object_probe_tiny_scalar_plain_20260531/ir
object_probe=1 ok, 0 fail

source=tmp/zig_ir/continuous_20260530_151319_debug/report.tsv first 100 optimizer-ok rows
probe=tmp/zig_ir/debug_object_probe_continuous_prefix100_20260531/ir
object_probe=100 ok, 0 fail
closed_boundary=Debug/O0 sizeof_and_typeof c_* panic-call unreachable stubs

source=tmp/zig_ir/continuous_20260530_151319_debug/report.tsv first 200 optimizer-ok rows
probe=tmp/zig_ir/debug_object_probe_continuous_prefix200_20260531/ir
object_probe=200 ok, 0 fail
first_failure=-
first_failure_category=-
closed_blocker=c_abi_main.zig.Debug.x86_64.ll
closed_boundary=selected Debug/O0 C ABI aliases, stack-materialized aggregate
                returns, scalar returns, packed struct/union checks, and
                panic-call stubs; selected Debug/O0 start trampoline trap tail
                and getauxval auxv scan shape; selected object-only Debug/O0
                logical-pointer compile-error and SPIR-V logical-pointer merge
                fixtures; selected Debug/O0 inherit_want_safety counter return;
                selected Debug/O0 unchecked/saturating arithmetic chain return

source=tmp/zig_ir/continuous_20260530_151319_debug/report.tsv first 300 optimizer-ok rows
probe=tmp/zig_ir/debug_object_probe_continuous_prefix300_20260531/ir
object_probe=300 ok, 0 fail
first_failure=-
first_failure_category=-

source=tmp/zig_ir/continuous_20260530_151319_debug/report.tsv first 400 optimizer-ok rows
probe=tmp/zig_ir/debug_object_probe_continuous_prefix400_20260531/ir
object_probe=399 ok, 0 fail, 1 excluded
excluded=standalone_emit_llvm_no_bin_main.zig.Debug.x86_64.ll
excluded_reason=debug-float-format-helper-boundary
first_failure=-
first_failure_category=-
closed_boundary=selected Debug/O0 panic-unreachable compile-asm entry,
                issue-339 error-success edge, libfuzzer runner aliases, and
                dynamic-library checked add; selected Debug/O0 mix-C
                add_zig/add_may_panic checked-add and panic-edge lowering

source=tmp/zig_ir/continuous_20260530_151319_debug/report.tsv all 465 optimizer-ok rows
probe=tmp/zig_ir/debug_object_probe_continuous_full465_20260531/ir
object_probe=465 ok, 0 fail, 0 excluded
excluded=standalone_emit_llvm_no_bin_main.zig.Debug.x86_64.ll
excluded_reason=debug-float-format-helper-boundary
excluded=standalone_mix_o_files_base64.zig.Debug.x86_64.ll
excluded_reason=debug-table-decoder-boundary
first_failure=-
first_failure_category=-
closed_boundary=Debug/O0 base64 table decoder matches the existing
                ReleaseSmall table-decoder boundary for @decode_base_64
closed_blocker=standalone_shared_library_mathtest.zig.Debug.x86_64.ll
               selected @add -> @mathtest.add checked add with panic edge
```

Debug handoff is a conservative boundary for the selected Debug/O0 handoff
fixture in `zig build handoff`:

```text
source=test/distribution/debug_x86_64/inputs/shared_library_mathtest_add_o0.ll
gate=zig build handoff
handoff_case=debug_o0_mathtest_checked_add
checks=emit asm, checked-add branch, panic-call relocation, ELF relocatable
boundary=selected Debug/O0 checked-add handoff only; not broad Debug codegen,
         debug/unwind records, or target-complete ABI lowering
```

Debug object support explicitly excludes DWARF and unwind section ownership:

```text
gate=zig build distribution-debug-unwind
targets=x86_64-unknown-linux-gnu, x86_64-unknown-linux-musl
source_fixture=test/zig/expected/debug_metadata.reduced.ll
result=pass, object has .text but no .debug_* or .eh_frame sections
boundary=selected Debug object lowering only; not DWARF, CFI, unwind tables,
         variable-location salvage, or debugger-quality metadata emission
```

Handoff is conservative for release modes because
`zig build handoff` validates selected scalar, memory,
loop, global, stack, and optimized scalar shapes, but not arbitrary accepted
ReleaseFast, ReleaseSafe, or ReleaseSmall optimized output. The focused
ReleaseFast CFG-sensitive optimized-output baseline is:

```text
tmp/zig_ir/optimized_cfg_releasefast_20260530
  mode=ReleaseFast
  target=x86_64-linux-gnu
  passes=zig-release-fast-accepted
  processed=11 emit_ok=11 local_ok=11
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0
  optimized_output=tmp/zig_ir/optimized_cfg_releasefast_20260530/optimized-ir
```

No prior optimized-output artifact directory existed for a historical diff, so
this is a baseline for future canonical-form comparisons rather than evidence
that optimized forms were unchanged across commits.

The first ReleaseFast asm/object fallback reduction tracks the selected empty
optimized module as `test/handoff/inputs/releasefast_empty_module.ll`. The
handoff gate now proves that a metadata-only accepted optimized module emits no
assembly and still produces an x86_64 ELF relocatable object with `.text` and
`.symtab` records.

ReleaseFast asm/object is now a conservative boundary for the captured
Zig-backed optimized-output set recorded in
`docs/roadmap/releasefast_x86_64_object_milestone_1.md`. The broad object probe
over `tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir` has 17
local object successes and 0 failures, with executable validation for the
selected public aliases. It still explicitly excludes target-complete ABI
lowering, arbitrary Zig source outside the captured set, debug/unwind records,
final-linker work owned by Zig's linker/toolchain, dynamic TLS models,
cross-target TLS relocations, and broad runtime completeness.

The first named no-LLVM-codegen x86_64 distribution subset gate is:

```text
zig build distribution-no-llvm
  target=x86_64-unknown-linux-gnu
  includes=ReleaseFast object/executable gates, ReleaseSafe object/executable gate,
           selected ReleaseSmall object/executable gates, selected Debug
           object/executable gates, handoff validation
  result=pass
```

The uncurated real-AIR release gate is now green for the current
`test/zig/inputs/*.zig` source corpus in both ReleaseFast and ReleaseSafe:

```text
zig build distribution-zig-air-uncurated-release
  target=x86_64-linux-gnu
  modes=ReleaseFast,ReleaseSafe
  source_rows_per_mode=19
  discovered_functions_per_mode=44
  structured_functions_per_mode=44
  generic_codegen_functions_per_mode=44
  unsupported_functions_per_mode=0
  codegen_failures_per_mode=0
  case_id_rows=0
  source_fact_classification_rows=0
  local_fail=0
```

This is the strongest current real-AIR ownership evidence: patched Zig exports
compiler-owned AIR/liveness via `zllvm-air-export-v1` and `structured_air-v1`,
while z_llvm parses and lowers the source functions without selected case IDs,
wrapper maps, source-fact body classification, canned DescriptorV2 bodies,
LLVM module parse/print, LLVM optimizer ownership, or LLVM TargetMachine
codegen. Object-format proof covers ReleaseFast and ReleaseSafe broad gates,
and native-link/executable progress is tracked as separate milestone-cost gates
outside `distribution-all`.

The broader ReleaseFast discovery gate is green for real AIR lowering and
generic x86_64 codegen:

```text
zig build distribution-zig-air-uncurated-releasefast-broad
  target=x86_64-linux-gnu
  source_roots=test/zig/inputs,test/zig/integrated
  source_rows=101
  discovered_functions=152
  structured_functions=152
  generic_codegen_functions=152
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

The companion object-emission progress gates emit all broad ReleaseFast,
ReleaseSafe, and ReleaseSmall machine functions through z_llvm's ELF object
path without LLVM TargetMachine:

```text
zig build distribution-zig-air-uncurated-releasefast-broad-object
zig build distribution-zig-air-uncurated-releasesafe-broad-object
zig build distribution-zig-air-uncurated-releasesmall-broad-object
  object_emitted_functions=152
  object_failures=0
  llvm_targetmachine_rows=0
  local_fail=0
```

The broad object-inspection gates validate the emitted source-module ELF
objects before native linker handoff:

```text
zig build distribution-zig-air-uncurated-releasefast-broad-object-inspection
zig build distribution-zig-air-uncurated-releasesafe-broad-object-inspection
zig build distribution-zig-air-uncurated-releasesmall-broad-object-inspection
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

The strict finish-line gate
`zig build distribution-zig-air-uncurated-release-broad-finish` combines the
three broad release modes with object emission and fail-closed counter checks.
It requires each mode to stay at `source_rows=101`,
`discovered_functions=152`, `structured_functions=152`,
`generic_codegen_functions=152`, `generic_cfg_functions>0`,
`typed_air_operand_functions=152`,
`legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`,
`shape_recognizer_functions=0`, `unsupported_functions=0`,
`codegen_failures=0`, `object_emitted_functions=152`,
`object_failures=0`, and `local_fail=0`.

The expanded corpus frontier is intentionally separate:
`distribution-zig-air-uncurated-releasefast-expanded`,
`distribution-zig-air-uncurated-releasesafe-expanded`, and
`distribution-zig-air-uncurated-releasesmall-expanded` add explicit sources from
`test/zig/expanded/*.zig`. The first expanded slice is green for all three
release modes at `source_rows=107`, `discovered_functions=168`,
`generic_codegen_functions=168`, `generic_cfg_functions=1` for ReleaseFast and
ReleaseSmall, `generic_cfg_functions=3` for ReleaseSafe,
`legacy_air_text_lowering_functions=0`,
`typed_v2_fallback_functions=0`, `shape_recognizer_functions=0`,
`unsupported_functions=0`, `codegen_failures=0`, and `local_fail=0`. Expanded
object emission is also green for all three modes at
`object_emitted_functions=168`, `object_failures=0`,
`llvm_targetmachine_rows=0`, and `local_fail=0`; expanded object inspection
reports `inspected=107`, `elf64_rel=107`, `relocation_rows=15`
(`16` for ReleaseSafe), `tls_rows=4`, `undefined_import_rows=3`
(`5` for ReleaseSafe), `comdat_rows=0`, `eh_frame_rows=0`,
`unsupported_relocation_rows=0`, and `local_fail=0`. Expanded native-link and
executable progress are also green for all three modes at
`native_link_accepted_rows=106`, `executable_ok_rows=106`,
`link_only_rows=0`, `runtime_boundary_rows=1` (`debug.defaultPanic`),
`unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`,
`llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. The expanded
audit lives in `docs/roadmap/x86_64_expanded_air_corpus.md`.

The broad native-link progress gates link the z_llvm object for each broad
source module with a tiny C `main` harness and Zig's native linker:

```text
zig build distribution-zig-air-uncurated-releasefast-broad-native-link
zig build distribution-zig-air-uncurated-releasesmall-broad-native-link
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

The executable progress layer keeps that same object/native-link path but uses
small C harnesses for stable callable ABI source modules and runs the linked
executables:

```text
zig build distribution-zig-air-uncurated-releasefast-broad-executable
zig build distribution-zig-air-uncurated-releasesafe-broad-executable
zig build distribution-zig-air-uncurated-releasesmall-broad-executable
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

The executable layer now covers all 100 accepted broad native-link rows in each
release mode. The closed link-only set was two input modules that needed C ABI
harnesses plus two input modules and four integrated wrappers that needed
global/TLS initializer materialization. The named runtime boundary remains
`debug.defaultPanic`. ReleaseSafe and ReleaseSmall report the same executable
split as ReleaseFast.

The one runtime boundary row is the named `debug.defaultPanic` import from
`runtime_mix_c_add_may_panic_main.zig`; the gate is link-only progress evidence
and remains outside `distribution-all`.

The broad ReleaseSafe and ReleaseSmall gates now match ReleaseFast through
lowering/codegen:

```text
zig build distribution-zig-air-uncurated-releasesafe-broad
zig build distribution-zig-air-uncurated-releasesmall-broad
  source_rows=101
  discovered_functions=152
  structured_functions=152
  generic_codegen_functions=152
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
  local_fail=0
```

The typed-v2 shape-recognizer closure is audited in
`docs/roadmap/x86_64_air_shape_recognizer_audit.md`. `structured_air-v1` and
`structured_air-v2` are present for every accepted broad function. The v2
transport now carries typed operand records for all broad functions, and z_llvm
uses typed-v2 lowering authority for all 152 broad functions. No broad function
uses legacy AIR text fallback or shape-recognizer ownership.

These broad gates remain outside `distribution-all` while executable ABI
evidence is promoted separately.

Link/LTO handoff remains a deferred boundary rather than an implementation row
for the selected x86_64 distribution subset:

```text
source=docs/bitcode/lto_compatibility_decision.md
source=docs/bitcode/construct_inventory.md
source=docs/lto/behavior_gaps.md
validation=zig build test
covered=LTO pre-link pipeline descriptors, text-IR optimizer surface
not_covered=bitcode writer/parser, LTO linker handoff bitcode, ThinLTO
            summaries, combined indexes, import/export, WPD, CFI, post-link LTO
status=deferred until a source-backed activation criterion requires bitcode or
       linker LTO handoff
```

The strongest current release-mode source-owned replacement gate is:

```text
gate=zig build distribution-x86_64-release-source-owned
target=x86_64
modes=ReleaseFast,ReleaseSafe,ReleaseSmall
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
air_extracted_descriptor_rows=100
template_descriptor_rows=0
wrapper_body_map_rows=0
source_tag_body_map_rows=0
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
fact_derived_classification_rows=100
root_source_classification_fallback_rows=0
source_fact_program_rows=100
source_fact_program_direct_rows=100
source_fact_body_wrapper_rows=0
body_enum_fallback_rows=0
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
tag_table_descriptor_rows=0
body_enum_dispatch_rows=0
surface_to_body_adapter_rows=0
canned_return_descriptor_rows=0
manual_fixture_dispatch_rows=0
legacy_semantic_record_rows=0
semantic_record_rows=0
external_writer_delegate_rows=0
semantic_lowering_rows=100
manifest_structured_rows=0
case_id_rows=0
surface_dispatch_rows=0
structured_direct_rows=100
generic_codegen_rows=100
fallback_rows=0
local_fail=0
ownership=llvm-module=not-used;llvm-optimizer=not-used;
          llvm-targetmachine=not-used;object-emission=z_llvm;
          linker=zig-native-fno-lld
source_wrapper_discovery=discovered_source_wrappers=82
                         descriptor_supported_wrappers=82
                         out_of_scope_wrappers=0
                         unsupported_with_reason=0
```

This supersedes the older claim shape for the current release source-backed
inventory: rows start from patched Zig compile-context fact provenance rather
than case IDs, source tags, wrapper basename maps, fixture metadata, body
enums, or template expansion. Patched Zig emits frozen
`zllvm-source-facts-v1` `generic-compiler-facts` from compiler context and
LLVM-builder module summaries: root source, mode, target, function inventory,
exported/main signature, parameter and return types, block/instruction counts,
instruction-category summaries, globals, TLS, calls, atomics, and inline-asm
capability facts. It does not read or token-count wrapper source and does not
emit z_llvm surface names. z_llvm classifies those facts into DescriptorV2
before verifying and lowering the records into structured-direct IR. All 100
rows use serialized DescriptorV2 transport and semantic serialized records, and
the gate fails if any row falls back to the serialized return stub. The current
provenance split is 100 rows on the separate extracted-record path with
compile-context fact provenance, no body-map selector, no source-tag selector,
and 0 template-owned rows. The gate now requires all 100 rows to be classified
from concrete facts into direct SourceFactProgram DescriptorV2 records:
`fact_derived_classification_rows=100`,
`root_source_classification_fallback_rows=0`,
`source_fact_program_rows=100`,
`source_fact_program_direct_rows=100`,
`source_fact_body_wrapper_rows=0`, and
`body_enum_fallback_rows=0`. All rows must have concrete facts, the
fact-program counters must account for all rows, and the 7-family wrong-facts
probe rejects mismatched wrapper/fact streams without using root source as a
body selector.
The same source-owned path now runs a z_llvm release canonicalizer before
structured lowering and applies selected transformations to eligible
DescriptorV2 programs rather than reporting observation-only counters. The
current gate reports 100 canonicalizer rows, 57 rows with observed and applied
integer folds, 5 rows with observed and applied conservative FP folds, 41 rows
with observed and applied neutral/dead local cleanup, 7 rows with observed and
applied compare/select cleanup, and 9 ReleaseSafe checked rows with all 9
checked boundaries preserved. Large semantic boundary rows such as full base64
and `strFromFloatHelp` keep their current shape until their generic lowering is
ready for canonicalized CFG.
`ZLLVM_SOURCE_TAG` is not present in accepted source-owned rows. The
source-owned gate fails if any row delegates back to the external
writer body path, uses the old semantic-record ownership marker, uses surface
dispatch as the ownership selector, uses a tag-table descriptor lookup, uses
body-enum descriptor dispatch, expands a descriptor body name inside z_llvm, or
uses the temporary manual fixture dispatch oracle.
The fixed 146-row selected gate, 90-row broad source-backed gate, and 49-row
source-wrapper gate remain regression checks with separate counters.

The strongest current real-AIR ownership gate is the broad x86_64 release
source-discovered gate rather than row-selected case IDs:

```text
gate=zig build distribution-zig-air-uncurated-releasefast-broad
gate=zig build distribution-zig-air-uncurated-releasesafe-broad
gate=zig build distribution-zig-air-uncurated-releasesmall-broad
target=x86_64-linux-gnu
modes=ReleaseFast,ReleaseSafe,ReleaseSmall
source_rows=101
discovered_functions=152
structured_functions=152
generic_codegen_functions=152
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
case_id_rows=0
source_fact_classification_rows=0
top_unsupported_construct=-
top_unsupported_count=0
local_fail=0
```

Patched Zig emits `zllvm-air-export-v1` with the legacy AIR text and a
`structured_air-v1` section containing reachable body records, instruction
tags, branch/conditional-branch records, and repeat metadata, plus typed
`structured_air-v2` operand/type records. z_llvm consumes that compiler-owned
stream directly for the broad uncurated gates; it does not select rows by case
ID, source facts, wrapper maps, or canned DescriptorV2 bodies. The broad
ReleaseFast/ReleaseSafe/ReleaseSmall gates now lower all 152 discovered
functions from typed-v2 authority without legacy AIR text fallback or
shape-recognizer ownership. This is still a selected x86_64 release corpus, not
a full AIR/liveness lowering replacement for every Zig source.

The same 100-row release source-owned replacement boundary now has a pre-link
ELF object-format proof before Zig native linker handoff:

```text
gate=zig build distribution-native-link-object-inspection -- --release-source-owned
target=x86_64-linux-gnu
modes=ReleaseFast,ReleaseSafe,ReleaseSmall
inventory=release-source-owned
inspected=100
elf64_rel=100
relocation_rows=12
tls_rows=8
undefined_import_rows=0
comdat_rows=0
eh_frame_rows=0
unsupported_relocation_rows=0
local_fail=0
checks=readelf -W -h -S -s -r; objdump -dr
object_contract=ELF64 REL x86_64, accounted section flags/alignment,
                symbol binding/type, allowed relocation families, local-exec
                TLS shape, no accidental COMDAT, no accidental unwind
linker_boundary=final linking remains Zig-owned through native ELF linker;
                z_llvm does not implement a linker
```

The same boundary now has Zig native-link handoff accounting through the
patched-Zig source-owned object path:

```text
gate=zig build distribution-native-link -- --release-source-owned
target=x86_64-linux-gnu
linker_selection=zig build-exe -fno-lld
inventory=release-source-owned
total=100
executable_abi_proof_rows=100
link_only_rows=0
runtime_compiler_rt_libc_boundary_rows=0
unsupported_zig_linker_feature_rows=0
local_object_codegen_failures=0
local_fail=0

probe=zig build probe-native-linker -- --release-source-owned
accepted=100
runtime_compiler_rt_libc_boundary_rows=0
unsupported_zig_linker_feature_rows=0
local_object_codegen_failures=0
failed=0
```

The selected x86_64 musl object subset is a target-boundary proof. It also
inherits the selected ReleaseSafe executable harnesses embedded in the M2 gate,
but does not claim broad executable replacement or local linker ownership for
musl:

```text
gate=zig build distribution-musl-object
target=x86_64-unknown-linux-musl
includes=ReleaseFast object gate, ReleaseSafe object gate,
         ReleaseSmall object gate, selected Debug object gate
result=pass
boundary=no broad musl executable harnesses; final linker/toolchain ownership
         stays with Zig; no local CRT/start-file, libc integration, or dynamic
         loader behavior
```

The selected x86_64 musl executable subset is also target-backed for stable ABI
fixtures:

```text
gate=zig build distribution-musl-executable
target=x86_64-unknown-linux-musl
cc_target=x86_64-linux-musl
includes=ReleaseFast executable gate, selected ReleaseSafe M2
         safety/runtime-call executable harnesses, selected ReleaseSmall M3
         executable harnesses, selected Debug mathtest executable gate
result=pass
boundary=no broad musl executable expansion beyond selected harnesses; Zig's
         linker/toolchain owns final linking, CRT policy, libc integration, and
         dynamic loader behavior beyond the selected harnesses
```

The selected native Zig linker handoff subset is intentionally smaller and
stricter than the `zig cc` executable gates:

```text
object_contract=docs/native_elf_linker_handoff.md
pre_link_gate=zig build distribution-native-link-object-inspection
pre_link_checks=ELF64 REL, section flags/alignment, symbols, relocations,
                TLS local-exec shape, undefined imports, no COMDAT, no
                .eh_frame
failure_categories=missing-relocation-support, bad-symbol-binding-type,
                   section-flag-alignment, tls-model, comdat,
                   unwind-boundary, runtime/compiler-rt/libc-boundary,
                   zig-linker-bug-or-unsupported-feature
```

```text
gate=zig build distribution-native-link
target=x86_64-unknown-linux-gnu
linker_selection=zig build-exe -fno-lld
includes=ReleaseFast full current executable harness set, 27 fixtures,
         ReleaseSafe checked-add object with panic stub and error-switch object,
         ReleaseSmall i64 constant-return, unchecked-arith, hidden-access,
         mix-C, libfuzzer runner, and reduced base64 table lookup objects,
         selected Debug/O0 mathtest add object with panic stub
result=pass
boundary=native Zig linker proof only for this ABI-stable subset; broad
         executable/linker coverage, CRT policy, libc integration, dynamic
         loading, archives, and shared libraries remain Zig-owned
```

The matching native-linker compatibility probe is source-backed and currently
clean for the same selected subset:

```text
gate=zig build probe-native-linker
target=x86_64-unknown-linux-gnu
linker_selection=zig build-exe -fno-lld
accepted=45
failed=0
per_mode=ReleaseFast 27/27 accepted, ReleaseSafe 9/9 accepted,
         ReleaseSmall 8/8 accepted, Debug 1/1 accepted
failure_categories=bad-symbol-binding-type, missing-relocation-support,
                   section-flag-alignment, tls-model, comdat, abi,
                   runtime/compiler-rt/libc-boundary,
                   zig-linker-bug-or-unsupported-feature
next_blocker=none measured; first future failure becomes a local object
             compatibility slice unless evidence proves Zig linker behavior
```

Broad native-link acceptance is tracked as link-only evidence, not executable
ABI proof. It proves selected local objects are structurally acceptable to
Zig's native linker path with safe unresolved function stubs, while keeping
runtime/TLS/linker ownership boundaries visible:

```text
gate=zig build distribution-native-link-boundary2
summary=tmp/zig_ir/native_link_boundary2_releasefast.summary
mode=ReleaseFast
accepted=16 accounted=1 local_fail=0 excluded=0 accounted_total=17
accounted_category=libc/compiler-rt=1
status=strongest current x86_64 native-link conservative boundary; all
       captured ReleaseFast rows are accepted or exactly accounted with no
       local object/link failures

summary=tmp/zig_ir/native_link_boundary2_releasesafe.summary
mode=ReleaseSafe
accepted=8 accounted=9 local_fail=0 excluded=0 accounted_total=17
accounted_category=libc/compiler-rt=1
accounted_category=zig-panic-runtime=8
boundary=debug.FullPanic safety runtime ownership remains Zig-owned

summary=tmp/zig_ir/native_link_boundary2_releasesmall.summary
mode=ReleaseSmall
accepted=273 accounted=192 local_fail=0 excluded=0 accounted_total=465
accounted_category=libc/compiler-rt=1
accounted_category=zig-startup-runtime=190
accounted_category=zig-tls-runtime=1
boundary=start.posixCallMainAndExit startup/runtime and selected TLS ownership
         remain Zig-owned
closed_local_blocker=c_abi_main.zig.ReleaseSmall.x86_64.optimized.ll
                     selected fp128 constants are now defined in local objects
closed_reduced_boundary=base64_table_lookup selected table constant/indexed
                        byte load fixture; full base64 decoder remains excluded

summary=tmp/zig_ir/native_link_boundary2_debug.summary
mode=Debug
accepted=6 accounted=4 local_fail=0 excluded=0 accounted_total=10
accounted_category=zig-panic-runtime=2
accounted_category=zig-test-runtime=1
accounted_category=zig-tls-runtime=1
closed_local_blocker=libfuzzer_runner_o0.ll selected byte-array constants and
                     main.testOne helper now link through Zig native linker
boundary=Debug/O0 panic runtime and TLS ownership remain Zig-owned
```

The named distribution slice is
[x86_64_native_link_distribution_slice.md](x86_64_native_link_distribution_slice.md).
The captured release-mode native-link claim is
[x86_64_captured_release_native_link_claim.md](x86_64_captured_release_native_link_claim.md).
The Zig-source integration slice is
[x86_64_zig_source_native_link_slice.md](x86_64_zig_source_native_link_slice.md).
The Zig integrated object-emission slice is
[x86_64_zig_integrated_object_emit_slice.md](x86_64_zig_integrated_object_emit_slice.md).
Per-mode native-link build aliases exist for ReleaseFast, ReleaseSafe,
ReleaseSmall, and Debug so each promotion can be refreshed independently.

Zig source integration is now a first-class evidence block above fixture-only
object/native-link proof:

```text
gate=zig build distribution-zig-source-native-link
path=Zig source -> stage4 LLVM IR -> z_llvm object -> zig build-exe -fno-lld
total=10 executable_ok=9 link_only_ok=1 local_fail=0
ReleaseFast executable=5 source rows
ReleaseSafe executable=1 source row
ReleaseSafe link_only=1 zig-panic-runtime boundary row
ReleaseSmall executable=3 source rows
fallback=stage4 Zig still emits LLVM IR; no LLVM codegen after IR emission for
         executable rows in this selected slice
```

Zig integrated object emission is the experimental in-Zig hook stage above the
external source capture pipeline. It is tracked in three levels:

```text
gate=zig build distribution-zig-integrated-object
stage=Zig integrated object emit, postopt hook
path=Zig build-obj -> patched Zig optimized IR -> z_llvm object
     -> zig build-exe -fno-lld
status=experimental conservative boundary
claim=LLVM target-machine object emission removed for selected x86_64 source
      rows after Zig constructs LLVM IR
total=10 executable_ok=9 link_only_ok=1 local_fail=0
fixture_pairing=each wrapper row records covered_fixture, mode, and proof
remaining_libllvm_dependency=Zig IR construction still uses libLLVM
excluded=AArch64, wasm, LTO, Debug expansion, broad runtime/TLS/compiler-rt

gate=zig build distribution-zig-integrated-preopt
stage=Zig integrated object emit, preopt hook
path=Zig build-obj -> patched Zig pre-optimization IR
     -> z_llvm --passes=<accepted Zig-mode pipeline>
     -> z_llvm --emit=obj
     -> zig build-exe -fno-lld
status=experimental conservative boundary
claim=LLVM target-machine object emission and LLVM's module optimization
      pipeline are bypassed for selected x86_64 source rows
total=10 executable_ok=9 link_only_ok=1 local_fail=0
ReleaseFast_narrow_gate=zig build distribution-zig-integrated-preopt -- --mode=ReleaseFast
mode_pipelines=ReleaseFast:zig-release-fast-accepted,
               ReleaseSafe:zig-release-safe-accepted,
               ReleaseSmall:zig-release-small-accepted
marker=pipeline, zllvm_passes, target, zig_target, object, ir, case_id,
       wrapper, mode
remaining_libllvm_dependency=Zig still uses libLLVM to parse, hold, and print
                            the module after Zig IR construction
wrapper_scope=compile-time semantic checks plus minimal C ABI main; broader
              callable ABI behavior remains covered by object/native-link
              fixture gates
excluded=AArch64, wasm, LTO, Debug expansion, broad runtime/TLS/compiler-rt

gate=zig build distribution-x86_64-selected-zllvm
detailed_gate=zig build distribution-zig-ir-writer
first_gate=zig build distribution-zig-ir-writer-tiny-scalar
stage=external z_llvm IR writer, selected wrapper subset
path=Zig build-obj -> patched Zig Object.emit validates external contract
     -> z_llvm --emit=ir-writer writes selected LLVM IR through the
        structured direct builder
     -> z_llvm --passes=<accepted Zig-mode pipeline>
     -> z_llvm --emit=obj
     -> zig build-exe -fno-lld
status=experimental conservative boundary
claim=selected wrapper objects bypass LLVM module optimization, LLVM
      TargetMachine object emission, and libLLVM bitcode parse/print of the
      selected emitted module; z_llvm owns structured IR construction and
      generic x86_64 lowering for the selected release subset, while
      the normal Zig/libLLVM fallback remains available when env vars are unset
construction=ir-construction=zllvm-structured-builder:146;
             ir-construction=z_llvm-external-textual-subset:0
construction_split=structured_direct_rows=146 structured_textual_rows=0
                   textual_boundary_rows=0
codegen_split=generic_codegen_rows=146 case_specific_codegen_rows=0
              textual_boundary_rows_out_of_scope=0
lowering_split=semantic_record_rows=136 external_writer_delegate_rows=10
               manifest_structured_rows=0
ownership=llvm-module=not-used; llvm-optimizer=not-used;
          llvm-targetmachine=not-used; object-emission=z_llvm;
          linker=zig-native-fno-lld
ownership_gate=selected IR-writer rows fail on libLLVM module parse/print,
               LLVM TargetMachine object emission fallback, minimal-ret0, or
               full-gate structured-direct count other than 146, structured
               textual parsing, textual boundary rows, or case-specific
               structured codegen ownership
compact_output=selected-zllvm status=<ok|fail> total=<rows>
               executable_ok=<count> link_only_ok=<count>
               structured_direct_rows=<count> structured_textual_rows=<count>
               textual_boundary_rows=<count>
               generic_codegen_rows=<count>
               case_specific_codegen_rows=<count>
               minimal-ret0=<count>
               ownership=<marker> first_failure_case_id=<case-or-->
               first_failure_wrapper=<wrapper-or-->
               first_failure_mode=<mode-or-->
               first_failure_pipeline=<pipeline-or-->
               first_failure_error=<error-or-->
diagnostics=docs/x86_64_selected_zllvm_diagnostics.md
total=146 executable_ok=146 link_only_ok=0 local_fail=0
structured_direct_rows=146 structured_textual_rows=0 textual_boundary_rows=0
generic_codegen_rows=146 case_specific_codegen_rows=0
minimal-ret0=0
structured_inventory=docs/roadmap/x86_64_structured_ir_builder_milestone.md
codegen_inventory=docs/roadmap/x86_64_codegen_genericity_audit.md
source_backed_broad_gate=zig build distribution-x86_64-source-backed-structured
source_backed_broad_claim=x86_64 release fixture discovery gate over
                          ReleaseFast/ReleaseSafe/ReleaseSmall `.ll`
                          fixtures; every discovered fixture is accepted,
                          structured-direct, and generic-codegen only
source_backed_broad_inventory=discovered_fixtures=55 accepted_fixtures=55
                              skipped_with_reason=0
source_backed_broad_rows=source_backed_rows=90 structured_direct_rows=90
                         generic_codegen_rows=90 fallback_rows=0
                         local_fail=0
source_wrapper_gate=zig build distribution-zig-source-structured-direct
source_wrapper_claim=selected Zig source-wrapper dispatch without case-id
                     ownership for the unambiguous wrapper/mode subset
source_wrapper_rows=source_wrappers=49 structured_direct_rows=49
                    case_id_rows=0 generic_codegen_rows=49
                    manifest_structured_rows=0 semantic_record_rows=48
                    external_writer_delegate_rows=1
                    case_specific_rows=0 fallback_rows=0 local_fail=0
release_source_owned_gate=zig build distribution-x86_64-release-source-owned
release_source_owned_rows=release_source_rows=100 source_wrapper_rows=100
                          descriptor_owned_rows=100 descriptor_v2_rows=100
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
                          zig_emitted_descriptor_rows=100
                          runner_generated_descriptor_rows=0
                          descriptor_file_consumed_rows=100
                          source_fact_stream_rows=100
                          concrete_source_fact_rows=100
                          source_derived_descriptor_rows=100
                          fact_derived_classification_rows=100
                          root_source_classification_fallback_rows=0
                          source_fact_program_rows=100
                          source_fact_program_direct_rows=100
                          source_fact_body_wrapper_rows=0
                          body_enum_fallback_rows=0
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
                          tag_table_descriptor_rows=0
                          body_enum_dispatch_rows=0
                          surface_to_body_adapter_rows=0
                          canned_return_descriptor_rows=0
                          manual_fixture_dispatch_rows=0
                          legacy_semantic_record_rows=0 semantic_record_rows=0
                          external_writer_delegate_rows=0
                          manifest_structured_rows=0 case_id_rows=0
                          surface_dispatch_rows=0 structured_direct_rows=100
                          generic_codegen_rows=100 fallback_rows=0 local_fail=0
uncurated_real_air_gate=zig build distribution-zig-air-uncurated-releasefast
uncurated_real_air_rows=source_rows=19 discovered_functions=44
                         structured_functions=44 generic_codegen_functions=44
                         unsupported_functions=0 codegen_failures=0
                         case_id_rows=0 source_fact_classification_rows=0
                         top_unsupported_construct=-
                         top_unsupported_count=0 local_fail=0
semantic_lowering_inventory=docs/roadmap/x86_64_source_wrapper_semantic_lowering.md
combined_current_claim=fixed_selected_rows=146 broad_source_backed_rows=90;
                       release_source_owned_rows=100;
                       source_wrapper_rows=49; counters remain separate; the
                       source-owned rung is strongest and all release source
                       rows are DescriptorV2-owned from Zig-emitted generic
                       fact streams; all 100 rows use serialized AIR-shaped
                       semantic records with no return-stub fallback or static
                       descriptor map fallback; current provenance is
                       compile-context fact extracted
                       (air_extracted_descriptor_rows=100,
                       template_descriptor_rows=0, wrapper_body_map_rows=0,
                       source_tag_body_map_rows=0,
                       zig_compile_context_descriptor_rows=100,
                       env_source_tag_selector_rows=0,
                       wrapper_body_selector_rows=0,
                       source_tag_body_selector_rows=0,
                       fixture_metadata_selector_rows=0,
                       source_tag_env_present_rows=0);
                       all gates require
                       structured-direct construction,
                       generic x86_64 lowering, no textual LLVM parse
                       fallback, no LLVM optimizer, no LLVM TargetMachine,
                       z_llvm object emission, and Zig native linker handoff
source_backed_remaining_unsupported=none for the current
                                    ReleaseFast/ReleaseSafe/ReleaseSmall
                                    x86_64 fixture inventory
first_gate_result=releasefast_tiny_scalar executable_ok=1 local_fail=0
table_load_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_base64_table_lookup
runtime_condbr_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_cond_branch
runtime_phi_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_phi_merge
runtime_loop_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_loop_sum
releasesafe_loop_sum_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_loop_sum
runtime_switch_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_switch
releasesafe_branch_mix_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_branch_mix
runtime_global_update_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_global_update
runtime_pointer_load_store_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_pointer_load_store
runtime_volatile_roundtrip_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_volatile_roundtrip
runtime_optional_pointer_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_optional_pointer
runtime_packed_read_flag_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_packed_read_flag
runtime_packed_replace_low_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_packed_replace_low
runtime_call_chain_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_call_chain
i64_call_return_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_i64_call
tls_read_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_tls_read
tls_bump_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_tls_bump
atomic_add_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_atomic_add
inline_asm_barrier_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_inline_asm_barrier
aggregate_pair_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_aggregate_pair
float_less_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_float_less
float_mul_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_float_mul
float_add_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_float_add
float_select_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_float_select
float_sub_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_float_sub
double_div_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_double_div
float_rem_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_float_rem
struct_sum_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_struct_sum
releasesafe_struct_sum_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_struct_sum
array_sum_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_array_sum
releasesafe_array_sum_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_array_sum
optional_payload_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_optional_payload
error_union_payload_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_error_union_payload
slice_sum_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_slice_sum
releasesafe_slice_sum_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_slice_sum
fp_constants_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_fp_constants
comptime_const_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_comptime_const
debug_location_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_debug_location
releasesafe_debug_location_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_debug_location
releasesafe_comptime_const_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_comptime_const
releasesafe_global_update_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_global_update
releasesafe_read_global_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_read_global
releasesafe_pointer_load_store_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_pointer_load_store
releasesafe_call_chain_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_call_chain
releasesafe_tls_bump_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_tls_bump
releasesafe_tls_read_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_tls_read
releasesafe_side_effect_free_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_side_effect_free
releasesmall_hidden_access_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_hidden_access
releasesmall_mix_c_add_zig_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_mix_c_add_zig
releasesmall_mix_c_add_may_panic_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_mix_c_add_may_panic
releasesmall_umul_fix_sat_i64_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_umul_fix_sat_i64
releasesmall_inherit_want_safety_i64_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_inherit_want_safety_i64
releasesmall_compile_asm_unreachable_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_compile_asm_unreachable
releasesmall_str_from_float_help_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_str_from_float_help
releasesmall_base64_decode_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_decode_step
releasesmall_base64_store_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_store_step
releasesmall_base64_residual_byte_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_byte_step
releasesmall_base64_padding_tail_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_padding_tail_step
releasesmall_base64_padding_loop_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_padding_loop_step
releasesmall_base64_padding_length_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_padding_length_step
releasesmall_base64_chunk_guard_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_chunk_guard_step
releasesmall_base64_source_stride_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_source_stride_step
releasesmall_base64_source_bundle_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_source_bundle_step
releasesmall_base64_next_source_bundle_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_next_source_bundle_step
releasesmall_base64_third_source_bundle_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_third_source_bundle_step
releasesmall_base64_bit_buffer_store_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_bit_buffer_store_step
releasesmall_base64_loop_advance_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_loop_advance_step
releasesmall_base64_residual_guard_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_guard_step
releasesmall_base64_residual_bundle_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_bundle_step
releasesmall_base64_residual_store_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_store_step
releasesmall_base64_residual_length_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_length_step
releasesmall_base64_residual_table_check_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_table_check_step
releasesmall_base64_residual_accumulator_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_accumulator_step
releasesmall_base64_residual_loop_advance_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_loop_advance_step
releasesmall_base64_residual_padding_check_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_padding_check_step
releasesmall_base64_residual_final_mask_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_final_mask_step
releasesmall_base64_residual_padding_loop_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_padding_loop_step
releasesmall_base64_decode_exit_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_decode_exit_step
next_releasesmall_probe_gate=zig build distribution-releasesmall-object
ir_writer_rows=scalar_runtime_rows=146, structured_direct_rows=146,
               structured_textual_rows=0, textual_boundary_rows=0,
               generic_codegen_rows=146, case_specific_codegen_rows=0,
               minimal_wrapper_rows=0
surface_counts=scalar-add-ret=2, integer-arithmetic=3,
               error-switch-select=4, direct-call=1, global-load=3,
               i64-arithmetic=1, i64-call-return=1, table-indexed-load=2,
               checked-add-runtime-boundary=2, runtime-condbr=2,
               runtime-phi-merge=1, runtime-loop-sum=2,
               checked-loop-sum-boundary=1, runtime-switch=2,
               checked-branch-mix-boundary=2, global-update=2,
               pointer-load-store=2, volatile-roundtrip=1,
               optional-pointer=2, packed-read-flag=2,
               packed-replace-low=2, struct-field-sum=2,
               array-scalar-sum=2, optional-scalar-payload=2,
               error-union-payload=2, slice-loop-sum=2,
               fp-literal-return=2, comptime-const-mul=2,
               add-imm-return=2, checked-add-imm-boundary=2,
               checked-comptime-const-boundary=1,
               checked-global-update-boundary=2,
               checked-pointer-load-store-boundary=2,
               checked-call-chain-boundary=2,
               checked-array-sum-boundary=2,
               checked-struct-sum-boundary=2,
               checked-slice-loop-sum-boundary=2, abi-arg-call=2,
               tls-read=4, tls-bump=2, checked-tls-bump-boundary=2,
               atomic-add=2, inline-asm-barrier=2,
               aggregate-pair-abi=2, float-less=2, float-mul=1,
               float-add=2, float-select=1, float-sub=2,
               double-div=1, float-rem=1, void-noop-call=1,
               hidden-global-access=2, mixed-c-zig-add=2,
               mixed-c-zig-panic-add=2, umul-fix-sat-i64=2,
               inherit-i64-return=2, compile-asm-unreachable=2,
               str-from-float-help=1, base64-decode-base64-full=1,
               base64-decode-step=1, base64-store-step=1,
               base64-residual-byte-step=1, base64-padding-tail-step=1,
               base64-padding-loop-step=1, base64-padding-length-step=1,
               base64-chunk-guard-step=1, base64-source-stride-step=1,
               base64-source-bundle-step=1,
               base64-next-source-bundle-step=1,
               base64-third-source-bundle-step=1,
               base64-bit-buffer-store-step=1,
               base64-loop-advance-step=1,
               base64-residual-guard-step=1,
               base64-residual-bundle-step=1,
               base64-residual-store-step=1,
               base64-residual-length-step=1,
               base64-residual-table-check-step=1,
               base64-residual-accumulator-step=1,
               base64-residual-loop-advance-step=1,
               base64-residual-padding-check-step=1,
               base64-residual-final-mask-step=1,
               base64-residual-padding-loop-step=1,
               base64-decode-exit-step=1, minimal-ret0=0
marker=pipeline, zllvm_passes, target, zig_target, object, ir, case_id,
       wrapper, mode, ir_writer=external, ir_writer_mode=external
construction_marker=per-row output includes construction=ir-construction=zllvm-structured-builder
ownership_marker=per-row output includes ownership=llvm-module=not-used; llvm-optimizer=not-used;
                 llvm-targetmachine=not-used; object-emission=z_llvm;
                 linker=zig-native-fno-lld
FuncGen_emitted_surface=releasefast_tiny_scalar scalar-add-ret,
                        releasefast_integers integer-arithmetic,
                        releasefast_error_switch error-switch-select,
                        releasefast_control_flow_calls direct-call,
                        releasefast_globals_comptime global-load,
                        releasesafe_runtime_read_global global-load,
                        releasefast_runtime_cond_branch runtime-condbr,
                        releasefast_runtime_phi_merge runtime-phi-merge,
                        releasefast_runtime_loop_sum runtime-loop-sum,
                        releasesafe_runtime_loop_sum
                        checked-loop-sum-boundary,
                        releasefast_runtime_switch runtime-switch,
                        releasesafe_runtime_branch_mix
                        checked-branch-mix-boundary,
                        releasefast_runtime_global_update global-update,
                        releasefast_runtime_pointer_load_store
                        pointer-load-store,
                        releasefast_runtime_volatile_roundtrip
                        volatile-roundtrip,
                        releasefast_runtime_optional_pointer
                        optional-pointer,
                        releasefast_runtime_packed_read_flag
                        packed-read-flag,
                        releasefast_runtime_packed_replace_low
                        packed-replace-low,
                        releasefast_runtime_call_chain abi-arg-call,
                        releasefast_runtime_tls_read tls-read,
                        releasesafe_runtime_tls_read tls-read,
                        releasefast_runtime_tls_bump tls-bump,
                        releasefast_runtime_atomic_add atomic-add,
                        releasefast_runtime_inline_asm_barrier
                        inline-asm-barrier,
                        releasefast_runtime_aggregate_pair
                        aggregate-pair-abi,
                        releasefast_runtime_float_less float-less,
                        releasefast_runtime_float_mul float-mul,
                        releasefast_runtime_float_add float-add,
                        releasefast_runtime_float_select float-select,
                        releasefast_runtime_float_sub float-sub,
                        releasefast_runtime_double_div double-div,
                        releasefast_runtime_float_rem float-rem,
                        releasefast_runtime_struct_sum struct-field-sum,
                        releasefast_runtime_array_sum array-scalar-sum,
                        releasefast_runtime_optional_payload
                        optional-scalar-payload,
                        releasefast_runtime_error_union_payload
                        error-union-payload,
                        releasefast_runtime_slice_sum slice-loop-sum,
                        releasefast_runtime_fp_constants
                        fp-literal-return,
                        releasefast_runtime_comptime_const
                        comptime-const-mul,
                        releasefast_runtime_debug_location
                        add-imm-return,
                        releasesafe_runtime_debug_location
                        checked-add-imm-boundary,
                        releasesafe_runtime_comptime_const
                        checked-comptime-const-boundary,
                        releasesafe_runtime_global_update
                        checked-global-update-boundary,
                        releasesafe_runtime_pointer_load_store
                        checked-pointer-load-store-boundary,
                        releasesafe_runtime_call_chain
                        checked-call-chain-boundary,
                        releasesafe_runtime_tls_bump
                        checked-tls-bump-boundary,
                        releasesafe_runtime_array_sum
                        checked-array-sum-boundary,
                        releasesafe_runtime_struct_sum
                        checked-struct-sum-boundary,
                        releasesafe_runtime_slice_sum
                        checked-slice-loop-sum-boundary,
                        releasesafe_error_switch error-switch-select,
                        releasesafe_tiny_scalar_runtime_boundary
                        checked-add-runtime-boundary,
                        releasesafe_runtime_side_effect_free
                        void-noop-call,
                        releasesmall_runtime_hidden_access
                        hidden-global-access,
                        releasesmall_runtime_mix_c_add_zig
                        mixed-c-zig-add,
                        releasesmall_runtime_mix_c_add_may_panic
                        mixed-c-zig-panic-add,
                        releasesmall_runtime_umul_fix_sat_i64
                        umul-fix-sat-i64,
                        releasesmall_runtime_inherit_want_safety_i64
                        inherit-i64-return,
                        releasesmall_runtime_compile_asm_unreachable
                        compile-asm-unreachable,
                        releasesmall_runtime_str_from_float_help
                        str-from-float-help,
                        releasesmall_runtime_base64_decode_step
                        base64-decode-step,
                        releasesmall_runtime_base64_store_step
                        base64-store-step,
                        releasesmall_runtime_base64_residual_byte_step
                        base64-residual-byte-step,
                        releasesmall_runtime_base64_padding_tail_step
                        base64-padding-tail-step,
                        releasesmall_runtime_base64_padding_loop_step
                        base64-padding-loop-step,
                        releasesmall_runtime_base64_padding_length_step
                        base64-padding-length-step,
                        releasesmall_runtime_base64_chunk_guard_step
                        base64-chunk-guard-step,
                        releasesmall_runtime_base64_source_stride_step
                        base64-source-stride-step,
                        releasesmall_runtime_base64_source_bundle_step
                        base64-source-bundle-step,
                        releasesmall_runtime_base64_next_source_bundle_step
                        base64-next-source-bundle-step,
                        releasesmall_runtime_base64_third_source_bundle_step
                        base64-third-source-bundle-step,
                        releasesmall_runtime_base64_bit_buffer_store_step
                        base64-bit-buffer-store-step,
                        releasesmall_runtime_base64_loop_advance_step
                        base64-loop-advance-step,
                        releasesmall_runtime_base64_residual_guard_step
                        base64-residual-guard-step,
                        releasesmall_runtime_base64_residual_bundle_step
                        base64-residual-bundle-step,
                        releasesmall_runtime_base64_residual_store_step
                        base64-residual-store-step,
                        releasesmall_runtime_base64_residual_length_step
                        base64-residual-length-step,
                        releasesmall_runtime_base64_residual_table_check_step
                        base64-residual-table-check-step,
                        releasesmall_runtime_base64_residual_accumulator_step
                        base64-residual-accumulator-step,
                        releasesmall_runtime_base64_residual_loop_advance_step
                        base64-residual-loop-advance-step,
                        releasesmall_runtime_base64_residual_padding_check_step
                        base64-residual-padding-check-step,
                        releasesmall_runtime_base64_residual_final_mask_step
                        base64-residual-final-mask-step,
                        releasesmall_runtime_base64_residual_padding_loop_step
                        base64-residual-padding-loop-step,
                        releasesmall_runtime_base64_decode_exit_step
                        base64-decode-exit-step,
                        releasesmall_globals_comptime global-load,
                        releasesmall_i64_arithmetic i64-arithmetic,
                        releasesmall_runtime_i64_call i64-call-return,
                        releasesmall_base64_table_lookup table-indexed-load;
                        no selected rows use minimal-ret0
source_fixture_pairing=each row still records covered_fixture and mode; source
                       behavior is enforced by comptime checks or existing
                       object/native-link fixture gates
remaining_dependency=general Zig LLVM Builder state remains; full FuncGen and
                     broad Zig IR construction are not replaced
excluded=runtime arithmetic beyond selected rows, stores beyond the selected
         mutable global update, ABI calls beyond the selected i32 argument
         direct call and selected i64 call return, TLS beyond selected
         local-exec read/update, atomics beyond selected monotonic add,
         inline asm beyond the selected memory barrier, aggregate ABI beyond
         the selected two-i32 pair, vectors, debug/unwind, AArch64, wasm, LTO,
         broad runtime/TLS/compiler-rt
```

The linker/CRT boundary is now explicit and validated as an ownership boundary,
not a future `z_llvm` linker plan. `z_llvm` emits LLVM-compatible IR, assembly,
and selected relocatable objects; final executable, shared-library, archive,
linker-script, CRT, libc, and dynamic-loader behavior stays in Zig's
linker/toolchain.

```text
gate=zig build distribution-linker-boundary
local_emit_modes=ir, asm, obj
rejected_emit_mode=exe
executable_validation_handoff=zig cc -target "$cc_target"
native_linker_proof=zig build distribution-native-link
result=pass
boundary=no z_llvm executable emission, CRT/start-file policy, libc integration,
         dynamic loader behavior, archive ownership, or linker script handling;
         broad executable gates hand local objects to Zig's driver/toolchain;
         only the `zig build-exe -fno-lld` gate is native-linker evidence
```

AArch64 object emission is an explicit target boundary for the current
distribution matrix:

```text
gate=zig build distribution-aarch64-boundary
target=aarch64-unknown-linux-gnu
source_fixture=test/distribution/releasefast_x86_64/inputs/tiny_scalar.ll
result=pass, rejected with unsupported codegen target
boundary=local object emission is x86_64-linux only; AArch64 parse/verify/
         optimize evidence does not imply backend, ABI, relocation, or object
         ownership
```

The current conservative boundary gates are composed by:

```text
gate=zig build distribution-boundary
includes=linker/CRT boundary, tracked ReleaseSmall exclusion boundaries,
         Debug DWARF/unwind boundary, AArch64 object target boundary
result=pass
```

The combined selected distribution validation entrypoint is:

```text
gate=zig build distribution-all
includes=selected no-LLVM-codegen object/executable subset,
         conservative boundary gates
result=pass
```

Automated broad object probing is now available through:

```text
zig build probe-distribution-objects --
  implementation=tools/probe_distribution_objects.zig
  ReleaseFast:  total=17  ok=17  fail=0 excluded=0 first_failure=-
  ReleaseSafe:  total=17  ok=17  fail=0 excluded=0 first_failure=-
  ReleaseSmall: total=465 ok=465 fail=0 excluded=0 first_failure=-
  ReleaseSmall former exclusions:
    standalone_emit_llvm_no_bin_main.zig.ReleaseSmall.x86_64.optimized.ll
      tracked_fixture=test/distribution/releasesmall_x86_64/exclusions/standalone_emit_llvm_no_bin_str_from_float_help.ll
      result=local object evidence through whole-function:str-from-float-help
    standalone_mix_o_files_base64.zig.ReleaseSmall.x86_64.optimized.ll
      tracked_fixture=test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll
      result=local object evidence plus executable whole-function:base64-decode-base-64
```

The compact object-stage dashboard is
`docs/roadmap/x86_64_distribution_object_dashboard.md`.

Asm/object remains LLVM fallback required for broad Debug, and for ReleaseFast,
ReleaseSafe, and ReleaseSmall outside their named captured subsets. Existing
docs explicitly exclude broad register allocation, scheduling, debug/unwind
object records, final-linker work owned by Zig's linker/toolchain, and
target-complete ABI lowering.

## First Fallback Row

The first implementation target should be:

```text
mode=ReleaseFast
target=x86_64-linux-gnu
stage=asm/object
status=conservative boundary
```

Reason: ReleaseFast is the primary optimizer replacement row and a common Zig
distribution path. The next bounded slice should not attempt broad backend
parity. It should reduce one concrete accepted ReleaseFast optimized-output
shape that cannot pass the existing x86_64 handoff or asm/object validation
subset, then add the smallest fixture and validation gate for that shape.

Milestone 1 selected that row and closed the first subset boundary. Milestone 2
closed the broad captured ReleaseFast object set. The next measured row starts
ReleaseSafe object replacement:

```text
mode=ReleaseSafe
target=x86_64-linux-gnu
stage=asm/object
status=LLVM fallback required
optimized_output=tmp/zig_ir/distribution_m2_releasesafe_20260530/optimized-ir
object_probe=17 ok, 0 fail with --input-limit=67108864
closed_blocker=aggregates.zig.ReleaseSafe.x86_64.optimized.ll selected checked aggregate sums
closed_blocker=atomics_inline_asm_debug.zig.ReleaseSafe.x86_64.optimized.ll selected checked debug_location
closed_blocker=control_flow_calls.zig.ReleaseSafe.x86_64.optimized.ll selected checked loop_sum/call_chain
closed_blocker=error_switch.zig.ReleaseSafe.x86_64.optimized.ll selected straight-line error_switch
closed_blocker=globals_comptime.zig.ReleaseSafe.x86_64.optimized.ll selected checked comptime_const/update_global/read_global
closed_blocker=pointers_memory.zig.ReleaseSafe.x86_64.optimized.ll selected checked load_store
closed_blocker=switch_control.zig.ReleaseSafe.x86_64.optimized.ll selected checked branch_mix plus dense_switch
closed_blocker=tiny_scalar.zig.ReleaseSafe.x86_64.optimized.ll selected checked add plus sideEffectFree
closed_blocker=tls_concurrency.zig.ReleaseSafe.x86_64.optimized.ll selected checked bump_tls plus read_tls
promoted_status=conservative boundary for captured ReleaseSafe optimized-output object subset
```

The next measured row starts ReleaseSmall object replacement:

```text
mode=ReleaseSmall
target=x86_64-linux-gnu
stage=asm/object
status=LLVM fallback required
optimized_output=tmp/zig_ir/distribution_m3_releasesmall_20260531/optimized-ir
optimizer_capture=465 ok, 0 fail, 1009 compile_skip
previous_object_probe=264 ok, 201 fail with --input-limit=67108864
closed_blocker=behavior_export_keyword.zig.ReleaseSmall.x86_64.optimized.ll selected writeToVRam/testPackedStuff
intermediate_object_probe=265 ok, 200 fail with --input-limit=67108864
closed_blocker=behavior_sizeof_and_typeof.zig.ReleaseSmall.x86_64.optimized.ll selected c_fopen/c_ftell/c_fputs/c_printf
closed_blocker=c_abi_main.zig.ReleaseSmall.x86_64.optimized.ll selected public aliases through @zig_panic
intermediate_object_probe=266 ok, 199 fail with --input-limit=67108864
closed_blocker=cases_address_space_pointer_access_chaining_pointer_to_optional_array.zig.ReleaseSmall.x86_64.optimized.ll selected @_start -> @start._start startup trampoline
intermediate_object_probe=327 ok, 138 fail with --input-limit=67108864
closed_blocker=cases_array_in_anon_struct.zig.ReleaseSmall.x86_64.optimized.ll selected @getauxval -> @os.linux.getauxvalImpl auxv scan
intermediate_object_probe=455 ok, 10 fail with --input-limit=67108864
closed_blocker=cases_compile_errors_illegal_operation_on_logical_ptr.zig.ReleaseSmall.x86_64.optimized.ll selected @elemPtr -> @illegal_operation_on_logical_ptr.elemPtr
intermediate_object_probe=456 ok, 9 fail with --input-limit=67108864
closed_blocker=cases_inherit_want_safety.zig.ReleaseSmall.x86_64.optimized.ll selected @entry -> @inherit_want_safety.entry i64 constant return
intermediate_object_probe=457 ok, 8 fail with --input-limit=67108864
closed_blocker=cases_no_compile_panic_for_unchecked_arith.zig.ReleaseSmall.x86_64.optimized.ll selected @entry -> @no_compile_panic_for_unchecked_arith.entry llvm.umul.fix.sat.i64 constant-call return
intermediate_object_probe=458 ok, 7 fail with --input-limit=67108864
closed_blocker=standalone_compile_asm_main.zig.ReleaseSmall.x86_64.optimized.ll selected @main -> @main.main empty noreturn unreachable stub
closed_blocker=standalone_emit_llvm_no_bin_main.zig.ReleaseSmall.x86_64.optimized.ll @strFromFloatHelp -> @main.strFromFloatHelp multi-block float-format helper
boundary_probe=zig build distribution-releasesmall-boundary local-object
tracked_boundary_fixture=test/distribution/releasesmall_x86_64/exclusions/standalone_emit_llvm_no_bin_str_from_float_help.ll
whole_function_boundary_status=closed; executable @main calls @main.strFromFloatHelp, and the helper covers stack slots, lifetime markers, double bitcast/exponent classification, pow5/inv-pow5 table loads, decimal loop CFG, i128 arithmetic/truncation, llvm.assume, llvm.memcpy/llvm.memset, fastcc pointer helper calls, and writer-vtable indirect-call boundary; proof label is whole-function:str-from-float-help
whole_function_boundary_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_str_from_float_help
closed_blocker=standalone_extern_exports.zig.ReleaseSmall.x86_64.optimized.ll selected @getHidden/@updateHidden hidden i32 global access
intermediate_adjusted_object_probe=460 ok, 4 fail, 1 excluded with --input-limit=67108864
closed_blocker=standalone_install_raw_hex_main.zig.ReleaseSmall.x86_64.optimized.ll selected @_start -> @main._start two-block infinite loop
intermediate_adjusted_object_probe=461 ok, 3 fail, 1 excluded with --input-limit=67108864
closed_blocker=standalone_libfuzzer_main.zig.ReleaseSmall.x86_64.optimized.ll selected libfuzzer runner aliases
closed_alias_in_blocker=@runner_futex_wait -> @main.runner_futex_wait i1 constant return
closed_alias_in_blocker=@runner_test_name -> @main.runner_test_name string-slice aggregate return
closed_alias_in_blocker=@runner_test_run -> @main.runner_test_run selected runtime-call lowering
intermediate_adjusted_object_probe=462 ok, 2 fail, 1 excluded with --input-limit=67108864
closed_blocker=standalone_mix_c_files_main.zig.ReleaseSmall.x86_64.optimized.ll selected mix-C aliases
closed_alias_in_blocker=@add_zig -> @main.add_zig mixed Zig/C global-add i32 return
closed_alias_in_blocker=@add_may_panic -> @main.add_may_panic checked add/panic branch
intermediate_adjusted_object_probe=463 ok, 1 fail, 1 excluded with --input-limit=67108864
closed_blocker=standalone_mix_o_files_base64.zig.ReleaseSmall.x86_64.optimized.ll @decode_base_64 -> @base64.decode_base_64 table-driven multi-block decoder
boundary_probe=zig build distribution-releasesmall-boundary local-object
tracked_boundary_fixture=test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll
focused_boundary_gate=zig build distribution-releasesmall-boundary
whole_function_boundary_inventory=@decode_base_64 -> @base64.decode_base_64 full textual IR body registered as releasesmall_runtime_base64_decode_base_64_full
whole_function_boundary_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_decode_base_64_full
whole_function_boundary_status=closed; external IR-writer @main validates TWFu -> Man, TWE= -> Ma, TQ== -> M, and invalid !!!! -> -1 through real x86_64 table-driven @base64.decode_base_64 lowering; proof label is whole-function:base64-decode-base-64
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected four-entry decode table load/OR/validity step
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_decode_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected output pointer store step
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_store_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual byte mask/shift/trunc/store step
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_byte_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected padding-tail byte load/equals check
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_padding_tail_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected padding-tail phi/add/backedge loop walk
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_padding_loop_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected trailing padding output-length adjustment
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_padding_length_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected wide-chunk loop guard
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_chunk_guard_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected source-byte stride/table load
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_source_stride_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected four-byte source bundle/table OR validity check
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_source_bundle_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected next four-byte source bundle/table OR validity check
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_next_source_bundle_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected third four-byte source bundle/table OR validity check
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_third_source_bundle_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected i128 bit-buffer combine/store
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_bit_buffer_store_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected loop index advance/backedge
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_loop_advance_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual/preheader guard
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_guard_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual four-byte source/table bundle
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_bundle_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual output store/backedge
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_store_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual remaining-length calculation
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_length_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual byte/table validity check
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_table_check_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual accumulator update
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_accumulator_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual loop-index advance
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_loop_advance_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual padding byte/offset check
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_padding_check_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual final mask guard
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_final_mask_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual final padding loop
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_padding_loop_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected decoder exit/lifetime cleanup
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_decode_exit_step
reduced_closed_fixture=test/distribution/releasesmall_x86_64/inputs/base64_table_lookup.ll
reduced_closed_shape=@base64_table_lookup -> @base64.table_lookup four-byte table constant plus indexed i8 load
reduced_gates=zig build distribution-releasesmall-object, zig build distribution-native-link-releasesmall
current_adjusted_object_probe=465 ok, 0 fail, 0 excluded with --input-limit=67108864
ReleaseSmall asm/object status=conservative boundary for named captured subset with no explicit exclusions
```
