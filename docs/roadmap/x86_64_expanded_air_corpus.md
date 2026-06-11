# x86_64 Expanded AIR Corpus Frontier

The closed broad corpus remains the regression baseline:

- `test/zig/inputs/*.zig`
- `test/zig/integrated/*.zig`
- `source_rows=101`
- `discovered_functions=152`
- `legacy_air_text_lowering_functions=0`
- `typed_v2_fallback_functions=0`
- `shape_recognizer_functions=0`
- `generic_lowering_functions=152`

The expanded corpus is a separate frontier bucket. It adds explicit fixtures
under `test/zig/expanded/*.zig` and must not weaken the broad baseline.

Current expanded seed:

- `test/zig/expanded/expanded_records_memory.zig`
- `test/zig/expanded/expanded_pointer_slices.zig`
- `test/zig/expanded/expanded_float_calls.zig`
- `test/zig/expanded/expanded_error_optional.zig`

Current expanded diagnostic snapshot for ReleaseFast, ReleaseSafe, and
ReleaseSmall:

```text
source_rows=105
discovered_functions=162
structured_functions=162
structured_air_v2_functions=162
typed_air_operand_functions=162
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_codegen_functions=162
generic_lowering_functions=162
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
first_unsupported_source=-
first_unsupported_function=-
first_unsupported_opcode=-
top_unsupported_construct=-
local_fail=0
```

The first expanded slice is clean for discovery/lowering/codegen. Expanded
object inspection, native-link handoff, and executable ABI accounting are the
next evidence layer.

Closed expanded blocker families:

- AIR/type lowering gap: expanded aggregate pair ABI function type from
  `expanded_records_memory.expanded_make_pair` and
  `expanded_records_memory.expanded_pair_first`.
- x86_64 backend gap: renamed pointer load/store function from
  `expanded_pointer_slices.expanded_load_store`.
- x86_64 backend gap: expanded slice loop function from
  `expanded_pointer_slices.expanded_slice_sum`.

Active expanded blocker families:

- none for the first expanded discovery/lowering/codegen slice.

Ownership rules for this frontier:

- no case IDs
- no wrapper/body maps
- no source-tag dispatch
- no legacy AIR text lowering
- no shape recognizers
- no LLVM optimizer
- no LLVM TargetMachine
- no LLD
