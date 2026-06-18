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
- `generic_cfg_functions=152` for ReleaseFast, ReleaseSafe, and ReleaseSmall
- `structural_matcher_functions=0` for ReleaseFast, ReleaseSafe, and ReleaseSmall

The expanded corpus is a separate frontier bucket. It adds explicit fixtures
under `test/zig/expanded/*.zig` and must not weaken the broad baseline.

Current expanded seed:

- `test/zig/expanded/expanded_records_memory.zig`
- `test/zig/expanded/expanded_pointer_slices.zig`
- `test/zig/expanded/expanded_float_calls.zig`
- `test/zig/expanded/expanded_error_optional.zig`
- `test/zig/expanded/expanded_numeric_casts.zig`
- `test/zig/expanded/expanded_branch_arrays.zig`
- `test/zig/expanded/expanded_cfg_memory_aggregates.zig`
- `test/zig/expanded/expanded_abi_frontier.zig`

Current expanded diagnostic snapshot for ReleaseFast, ReleaseSafe, and
ReleaseSmall:

```text
source_rows=109
discovered_functions=197
structured_functions=197
structured_air_v2_functions=197
typed_air_operand_functions=197
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_codegen_functions=197
generic_cfg_functions=197
structural_matcher_functions=0
generic_lowering_functions=197
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
first_unsupported_source=-
first_unsupported_function=-
first_unsupported_opcode=-
top_unsupported_construct=-
local_fail=0
```

The expanded slices are clean for discovery/lowering/codegen. The expanded
finish gate adds object emission for all three release modes:

```text
object_emitted_functions=197
object_failures=0
llvm_targetmachine_rows=0
local_fail=0
```

The expanded object-inspection gates are also green for ReleaseFast,
ReleaseSafe, and ReleaseSmall:

```text
inspected=109
elf64_rel=109
relocation_rows=18 (ReleaseSafe: 19)
tls_rows=4
undefined_import_rows=3 (ReleaseSafe: 6)
comdat_rows=0
eh_frame_rows=0
unsupported_relocation_rows=0
local_fail=0
```

Expanded native-link handoff is green for ReleaseFast, ReleaseSafe, and
ReleaseSmall. ReleaseFast and ReleaseSmall native-link progress report:

```text
native_link_accepted_rows=108
executable_ok_rows=0
link_only_rows=108
runtime_boundary_rows=1
unsupported_zig_linker_feature_rows=0
native_link_failures=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

ReleaseSafe native-link progress has additional named safety runtime
boundaries and reports:

```text
native_link_accepted_rows=105
executable_ok_rows=0
link_only_rows=105
runtime_boundary_rows=4
unsupported_zig_linker_feature_rows=0
native_link_failures=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

Expanded executable ABI accounting is also green for ReleaseFast, ReleaseSafe,
and ReleaseSmall:

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

The executable progress gate's remaining named runtime boundary is
`debug.defaultPanic`; ReleaseSafe native-link-only progress also classifies
`outOfBounds`, `integerPartOutOfBounds`, and `unwrapNull` as named safety
runtime boundaries.

Closed expanded blocker families:

- AIR/type lowering gap: expanded aggregate pair ABI function type from
  `expanded_records_memory.expanded_make_pair` and
  `expanded_records_memory.expanded_pair_first`.
- x86_64 backend gap: renamed pointer load/store function from
  `expanded_pointer_slices.expanded_load_store`.
- x86_64 backend gap: expanded slice loop function from
  `expanded_pointer_slices.expanded_slice_sum`.
- executable proof gap: expanded stable C-ABI harnesses for
  `expanded_records_memory`, `expanded_pointer_slices`,
  `expanded_float_calls`, and `expanded_error_optional`.
- typed v2 ReleaseSafe gap: optional-pointer safe-add immediate extraction
  from `expanded_error_optional.expanded_optional_pointer`.
- SysV ABI frontier closure: `expanded_abi_frontier.zig` adds seven- and
  nine-argument exported functions, noinline helper calls with one and three
  stack-passed integer arguments, f32/f64 direct-call returns, mixed
  integer/f64 direct-call returns, a mixed integer/f32/f64 call with a
  stack-passed integer argument, and an i64 mixed-argument call/return. Typed
  v2 now accepts qualified Zig function type spellings such as
  `noinline fn (...)`, and the generic x86_64 SysV direct-call/frame helpers
  cover multiple stack-passed call arguments, the seventh through ninth
  integer parameters, i64 return/pass-through, and separate integer/SSE
  argument register streams. The expanded executable harness checks direct C
  ABI calls plus the internal helper call wrappers.
- IR/backend numeric-cast gap: `sitofp`/`uitofp`/`fptrunc` cast ops were
  missing from the local IR, the AIR `float_from_int` opcode was mapped to the
  wrong cast direction, and the x86_64 backend had no scalar int/float
  conversion lowering. Closed by `expanded_numeric_casts.zig` with
  `cvtsi2ss`/`cvtsi2sd` (signed i32/i64), zero-extended `cvtsi2ssq`/`cvtsi2sdq`
  (unsigned u32), `cvttss2si`/`cvttsd2si`, `cvtsd2ss`, and `cvtss2sd`.
- x86_64 backend structural matcher debt: canonical loop-sum functions, simple
  single-block scalar integer returns, and scalar `icmp eq/ne` plus `select`
  returns now route through strict generic CFG admission with block labels,
  branches, scalar operations, select join labels, returns, and simple integer
  edge-copy phi handling. ReleaseSafe checked guard CFGs for numeric casts and
  table lookup bounds also enter the generic CFG path before reusing the
  checked guard emitters. The expanded
  `expanded_cfg_memory_aggregates.zig` bucket adds branch-to-merge CFG rows for
  pointer loads, side-effecting pointer stores, computed stores, pointer-select
  loads, direct calls on one or both branches, alloca-stored extern-struct field
  loads at offsets 0 and 4, and branch-local field-0 updates; generic typed-v2
  block lowering now constructs real entry/then/else/merge blocks with phi
  incoming values, and the x86_64 generic CFG path lowers the eligible branch
  paths without a structural matcher. Single-block scalar FP binary, compare,
  select, and literal-return rows now use the same generic CFG ownership path.
  Current expanded counters are
  ReleaseFast, ReleaseSafe, and ReleaseSmall all report
  `generic_cfg_functions=197` / `structural_matcher_functions=0`. Expanded
  optional-pointer payload rows with a
  load-plus-add payload block now use the same generic CFG optional-pointer
  path as the load-only forms, and the f32 pipeline row with an unused scalar
  bool parameter now uses generic FP binary CFG lowering. The base64 byte table
  lookup leaf now routes through a shape-based generic byte-table lookup helper
  rather than a function-name-specific backend path. Single-block volatile
  roundtrip helpers now also
  validate volatile store/load ordering through generic CFG; single-block
  packed read/replace helpers validate their mask/shift/OR and sign-bit compare
  shapes through generic CFG; scalar numeric conversion rows validate fpext,
  fptrunc, int-from-float, signed int-to-float, and unsigned int-to-double
  shapes through generic CFG; signed-min `icmp slt`/`select` classifier rows,
  nested `i8` equality error-switch selects, boolean-parameter branch-mix
  add/sub selects, constant-return `i8 switch` CFGs, nested `i8` equality
  error-union/classifier selects, void `i32` global/TLS store helpers,
  small aggregate pair SysV pack/unpack helpers, selected monotonic atomic add,
  selected empty inline-asm memory barriers, empty no-op `ret void` helpers,
  no-arg void-call wrapper mains returning `i32 0`, constant FP/bool
  sibling-wrapper call/check mains, integer-return sibling-wrapper
  call/check mains, pointer-literal sibling-wrapper call/check mains, sibling
  update/get wrapper mains, and constant direct-call wrapper mains with optional
  identity casts validate through generic CFG. Scalar
  `shift_mix`, scalar multiply-by-constant, and i64
  constant-return leaves, including the selected i64 wrapper-family mains that
  reduce to those leaves, validate through generic CFG. Slice-sum, struct-sum,
  and volatile roundtrip wrapper mains now validate their pointer-global calls
  through generic CFG. Two-call aggregate wrapper chains that pass an i64
  return into an i32 helper now emit real calls through generic CFG. Multi-block
  call/global-load checks with a boolean merge now emit real sibling calls and
  RIP-relative global-address arguments through generic CFG, covering
  `runtime_pointer_load_store_main.main`. Multi-block two-call optional-pointer
  wrapper checks now validate `ptr @global` and `ptr null` sibling call
  arguments through generic CFG, covering `runtime_optional_pointer_main.main`.
  The mixed C/Zig panic-edge leaf now also validates the negative guard,
  `debug.defaultPanic` noreturn edge, global load, plain add, and checked
  overflow variant through generic CFG.
- typed v2 CFG/backend gap: nested optional-pointer branch payload from
  `expanded_cfg_memory_aggregates.expanded_optional_pointer_branch`. Typed v2
  now lowers pointer `optional_payload` and `is_non_null`, accepts a nested
  void guard block inside a branch body, records the actual guard-continuation
  predecessor for the merge phi, and the generic x86_64 CFG path lowers the
  guarded optional-pointer branch with the cold panic edge preserved in
  ReleaseSafe plus a phi/immediate return. The expanded executable harness
  covers non-null and false/null fallback paths.
- typed v2 CFG/backend gap: conditional slice-loop update from
  `expanded_cfg_memory_aggregates.expanded_slice_conditional_sum`. Typed v2 now
  validates the nested loop body, inner conditional block, indexed pointer load,
  limit compare, and accumulator update; the generic x86_64 CFG path emits the
  counted pointer loop with conditional accumulation. The expanded executable
  harness covers mixed below/above threshold data, empty length, all-below, and
  all-above inputs.
- expanded frontier bucket: `expanded_branch_arrays.zig` adds a supported
  optional-control-flow source row with executable ABI coverage. A wider
  branch-return and byte-table-return version correctly failed closed with
  `control_flow_shape` / backend diagnostics and remains future generic
  block/select/table-return work.
- AIR export gap: the patched Zig `zllvm-air-export-v1` hook did not classify
  `fpext` as a typed `ty_op` record, forcing a legacy text fallback for
  `expanded_numeric_casts.expanded_double_widen`.
- ReleaseSafe void-guard preservation gap: typed v2 lowering previously
  elided void guard blocks (a safety check whose passing branch is `br void`
  and whose failing branch is a cold noreturn panic call), which made the
  affected ReleaseSafe row behave like ReleaseFast. The only corpus function
  that hit the elision was `base64_table_lookup.base64_table_lookup` (the
  array bounds check). Typed v2 now lowers void guards into real control
  flow (guard branch, dedicated panic-call block, continuation block), the
  backend lowers the guarded table-lookup CFG with a `cmp`/`jae` bounds edge
  and an aligned noreturn `outOfBounds` call, and the executable harness
  stubs the panic symbol. The ReleaseSafe object row gains one undefined
  import for the restored panic boundary.
- typed v2 ReleaseSafe gap: the checked `@intFromFloat` range-guard block
  (`cmp_lte`/`cmp_gte` bound checks, `bit_or`, cold
  `integerPartOutOfBounds` panic call) from
  `expanded_numeric_casts.expanded_int_from_float`. The backend lowers the
  guard CFG with `ucomiss`/`ucomisd` bound compares, `jae` panic edges, and an
  aligned noreturn panic call.

Active expanded blocker families:

- none for the current exported expanded discovery/lowering/codegen/executable
  slices. The named runtime boundary remains `debug.defaultPanic`, but the
  runtime-boundary arithmetic leaf is no longer a structural backend row.

Ownership rules for this frontier:

- no case IDs
- no wrapper/body maps
- no source-tag dispatch
- no legacy AIR text lowering
- no shape recognizers
- no LLVM optimizer
- no LLVM TargetMachine
- no LLD

Current expanded gates:

- `distribution-zig-air-uncurated-releasefast-expanded`
- `distribution-zig-air-uncurated-releasesafe-expanded`
- `distribution-zig-air-uncurated-releasesmall-expanded`
- `distribution-zig-air-uncurated-releasefast-expanded-object`
- `distribution-zig-air-uncurated-releasesafe-expanded-object`
- `distribution-zig-air-uncurated-releasesmall-expanded-object`
- `distribution-zig-air-uncurated-releasefast-expanded-object-inspection`
- `distribution-zig-air-uncurated-releasesafe-expanded-object-inspection`
- `distribution-zig-air-uncurated-releasesmall-expanded-object-inspection`
- `distribution-zig-air-uncurated-releasefast-expanded-native-link`
- `distribution-zig-air-uncurated-releasesafe-expanded-native-link`
- `distribution-zig-air-uncurated-releasesmall-expanded-native-link`
- `distribution-zig-air-uncurated-releasefast-expanded-executable`
- `distribution-zig-air-uncurated-releasesafe-expanded-executable`
- `distribution-zig-air-uncurated-releasesmall-expanded-executable`
- `distribution-zig-air-uncurated-release-expanded-finish`
