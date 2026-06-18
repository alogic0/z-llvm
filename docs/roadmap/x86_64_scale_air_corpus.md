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
discovered_functions=214
structured_functions=214
structured_air_v2_functions=214
typed_air_operand_functions=214
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_codegen_functions=214
generic_cfg_functions=214
structural_matcher_functions=0
generic_lowering_functions=214
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
object_emitted_functions=214
object_failures=0
llvm_targetmachine_rows=0
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

Active scale blocker families:

- none for current discovery/lowering/codegen/object progress.

Next evidence layer:

- add scale object-inspection gates
- add scale native-link/executable gates for stable C ABI rows
- expand the scale bucket with larger call graphs, broader aggregate layouts,
  additional TLS/global initializer forms, and more optional/error-union
  control-flow shapes
