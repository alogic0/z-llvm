# x86_64 Scale AIR Corpus Frontier

The broad and expanded real-AIR gates remain the closed regression baselines.
The scale corpus is a separate frontier bucket for growing x86_64
ReleaseFast/ReleaseSafe/ReleaseSmall coverage without weakening either
baseline.

Current scale seed:

- `test/zig/scale/scale_abi_calls.zig`
- `test/zig/scale/scale_memory_loops.zig`
- `test/zig/scale/scale_records_globals.zig`

The scale bucket currently stresses:

- multiple stack-passed integer arguments and mixed integer/f32/f64 call
  streams
- i64 argument and return paths
- slice-like counted loops and conditional slice accumulation
- branch-local pointer loads/stores and load-after-store returns
- extern two-i32 struct field reads/updates
- direct calls in branch bodies with merged scalar results
- scalar global and TLS read/update forms

Current scale diagnostic snapshot for ReleaseFast, ReleaseSafe, and
ReleaseSmall:

```text
source_rows=112
discovered_functions=216
structured_functions=216
structured_air_v2_functions=216
typed_air_operand_functions=216
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_codegen_functions=216
generic_cfg_functions=216
structural_matcher_functions=0
generic_lowering_functions=216
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
first_unsupported_source=-
first_unsupported_function=-
first_unsupported_opcode=-
top_unsupported_construct=-
local_fail=0
```

The scale gates include object progress:

```text
object_emitted_functions=216
object_failures=0
llvm_targetmachine_rows=0
local_fail=0
```

Scale object inspection now covers the source-module objects for all three
release modes:

```text
inspected=112
elf64_rel=112
relocation_rows=20 (ReleaseSafe: 21)
tls_rows=5
undefined_import_rows=3 (ReleaseSafe: 6)
comdat_rows=0
eh_frame_rows=0
unsupported_relocation_rows=0
local_fail=0
```

Scale native-link handoff is green. ReleaseFast and ReleaseSmall report:

```text
native_link_accepted_rows=111
executable_ok_rows=0
link_only_rows=111
runtime_boundary_rows=1
unsupported_zig_linker_feature_rows=0
native_link_failures=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

ReleaseSafe native-link-only progress has named safety runtime boundaries and
reports:

```text
native_link_accepted_rows=108
executable_ok_rows=0
link_only_rows=108
runtime_boundary_rows=4
unsupported_zig_linker_feature_rows=0
native_link_failures=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

Scale executable ABI accounting is green for ReleaseFast, ReleaseSafe, and
ReleaseSmall:

```text
native_link_accepted_rows=111
executable_ok_rows=111
link_only_rows=0
runtime_boundary_rows=1
unsupported_zig_linker_feature_rows=0
native_link_failures=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

Ownership rules for this frontier:

- no case IDs
- no wrapper/body maps
- no source-tag dispatch
- no legacy AIR text lowering
- no typed-v2 fallback
- no shape recognizers
- no structural matcher backend fallback
- no LLVM optimizer
- no LLVM TargetMachine
- no LLD

Current scale gates:

- `distribution-zig-air-uncurated-releasefast-scale`
- `distribution-zig-air-uncurated-releasesafe-scale`
- `distribution-zig-air-uncurated-releasesmall-scale`
- `distribution-zig-air-uncurated-release-scale`
- `distribution-zig-air-uncurated-releasefast-scale-object-inspection`
- `distribution-zig-air-uncurated-releasesafe-scale-object-inspection`
- `distribution-zig-air-uncurated-releasesmall-scale-object-inspection`
- `distribution-zig-air-uncurated-releasefast-scale-native-link`
- `distribution-zig-air-uncurated-releasesafe-scale-native-link`
- `distribution-zig-air-uncurated-releasesmall-scale-native-link`
- `distribution-zig-air-uncurated-releasefast-scale-executable`
- `distribution-zig-air-uncurated-releasesafe-scale-executable`
- `distribution-zig-air-uncurated-releasesmall-scale-executable`

Active scale blocker families:

- none for current discovery/lowering/codegen/object progress.

Next evidence layer:

- the next isolated source frontier lives in
  `docs/roadmap/x86_64_frontier_air_corpus.md`
- future scale expansion should keep object-inspection, native-link, and
  executable proof paired with accepted rows so new rows do not remain
  object-only evidence
