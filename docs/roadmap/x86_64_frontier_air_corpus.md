# x86_64 Frontier AIR Corpus

The frontier corpus is separate from the cumulative broad, expanded, and scale
gates. It exists to admit new real Zig source rows under
`test/zig/frontier/*.zig` without weakening any closed baseline.

Current corpus coverage:

- `distribution-zig-air-uncurated-release` covers `test/zig/inputs/*.zig`.
- Broad covers `test/zig/inputs/*.zig` plus `test/zig/integrated/*.zig`.
- Expanded covers broad plus `test/zig/expanded/*.zig`.
- Scale covers expanded plus `test/zig/scale/*.zig`.
- Frontier covers only `test/zig/frontier/*.zig`.

Still excluded from real-AIR release gates:

- `.ll` fixtures under `test/zig/captured` and `test/zig/expected`.
- Debug, AArch64, LTO, libc-heavy programs, and non-release modes.
- Broader upstream Zig test directories until they are added through an
  explicit audited bucket.

Current frontier seed:

- `test/zig/frontier/frontier_branch_memory.zig`
- `test/zig/frontier/frontier_comptime_constants.zig`
- `test/zig/frontier/frontier_globals_tls.zig`
- `test/zig/frontier/frontier_helper_graph.zig`
- `test/zig/frontier/frontier_mixed_numeric.zig`
- `test/zig/frontier/frontier_nested_loops.zig`
- `test/zig/frontier/frontier_nested_records.zig`
- `test/zig/frontier/frontier_optionals_errors.zig`
- `test/zig/frontier/frontier_safety_edges.zig`
- `test/zig/frontier/frontier_slice_pointer_arith.zig`
- `test/zig/frontier/frontier_sysv_abi.zig`
- `test/zig/frontier/frontier_sysv_aggregate_classes.zig`
- `test/zig/frontier/frontier_sysv_sret_byval.zig`

Current ReleaseFast, ReleaseSafe, and ReleaseSmall counters:

```text
source_rows=13
discovered_functions=117
structured_functions=117
generic_codegen_functions=117
generic_cfg_functions=117
structural_matcher_functions=0
structured_air_v2_functions=117
typed_air_operand_functions=117
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_lowering_functions=117
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
object_emitted_functions=117
object_failures=0
llvm_targetmachine_rows=0
local_fail=0
```

Object inspection is green for all three modes:

```text
inspected=13
elf64_rel=13
relocation_rows=4
tls_rows=1
undefined_import_rows=1
comdat_rows=0
eh_frame_rows=0
unsupported_relocation_rows=0
local_fail=0
```

Native-link progress is green for all three modes:

```text
native_link_accepted_rows=13
executable_ok_rows=0
link_only_rows=13
runtime_boundary_rows=0
unsupported_zig_linker_feature_rows=0
native_link_failures=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

Executable ABI proof is green for all three modes:

```text
native_link_accepted_rows=13
executable_ok_rows=13
link_only_rows=0
runtime_boundary_rows=0
unsupported_zig_linker_feature_rows=0
native_link_failures=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

Closed in the current memory/aggregate frontier slice:

- nested counted loop-memory CFG through
  `frontier_nested_memory_sum`
- selected nested extern-struct field GEP paths through
  `frontier_nested_field_left_b` and `frontier_nested_field_right_a`
- selected dynamic pointer addition and pointer-element GEP loads through
  `frontier_dynamic_ptr_add` and `frontier_dynamic_ptr_pair_sum`
- branch-local global/TLS add/sub updates through
  `frontier_global_branch` and `frontier_tls_branch`
- first SysV ABI closure-wave rows in `frontier_sysv_abi.zig`: small
  INTEGER/INTEGER aggregate return in `%rax`/`%rdx`, small aggregate field
  argument reads from the SysV integer register pair, and a reusable
  up-to-six-live-i32 direct-call frame that spills and reloads all six SysV
  GPR argument registers through aligned stack slots around the call
- selected sret/byval-style source-backed rows in
  `frontier_sysv_sret_byval.zig`: `{ i64, i64, i64 }`,
  `{ i64, i64, i64, i64 }`, `{ i64, i64, i64, i64, i64 }`, and
  `{ i64, i64, i64, i64, i64, i64 }` plus
  `{ i64, i64, i64, i64, i64, i64, i64 }` returns through a hidden sret pointer
  in `%rdi` with user arguments shifted through the SysV GPR stream; the
  seven-field make row proves multiple stack-passed user arguments after the
  hidden pointer, the normal integer-leaf MEMORY sret/byval typed builder now
  generates field names and ABI attrs instead of using a fixed field-count
  table, and the same selected normal MEMORY aggregates copy all scalar integer
  leaves from the stack-passed by-value argument to the hidden sret destination
  using layout-derived byte offsets, including the nested `{ { i64, i64, i64 },
  { i64, i64, i64 } }` copy/read row and the mixed-width
  `{ i64, i32, i64, i32 }` copy row; the array-backed `{ [5 x i64] }` rows
  prove the same byte-offset copy and by-value field-read paths for integer
  array leaves inside a normal MEMORY aggregate
- first mixed SysV aggregate class row in
  `frontier_sysv_aggregate_classes.zig`: `{ i64, double }`, selected
  `{ i32, double }`, and selected `{ i32, i32, double }` forms are classified as
  mixed INTEGER/SSE, and field reads return low/high integer members from the
  GPR stream and floating members from the SSE stream; construction returns the
  `i64` aggregate in `%rax`/`%xmm0`, while the packed mixed construction row
  packs adjacent low/high `i32` fields into `%rax` and returns the `double` in
  `%xmm0`; a noinline helper-call row returns the same register aggregate
  directly from a private helper without scalarizing through a selected wrapper
- first SSE/SSE aggregate class row in
  `frontier_sysv_aggregate_classes.zig`: `{ double, double }` is classified as
  SSE/SSE, field reads return from the independent SSE argument stream, and
  construction returns the aggregate in `%xmm0`/`%xmm1`
- first reversed mixed aggregate class row in
  `frontier_sysv_aggregate_classes.zig`: `{ double, i64 }`, selected
  `{ double, i32 }`, and selected `{ double, i32, i32 }` forms are classified as
  SSE/INTEGER, field reads return from the independent SSE/GPR streams including
  high 32-bit integer lanes, construction returns the `i64` aggregate in
  `%xmm0`/`%rax`, and the packed reversed construction row packs adjacent
  low/high `i32` fields into `%rax`
- first nested INTEGER aggregate add-chain row in
  `frontier_sysv_aggregate_classes.zig`: nested `{ i32, i32 }` fields are
  flattened through byte offsets, classified as INTEGER/INTEGER, and summed
  from the SysV GPR pair without a function-name-specific lowering path; the
  noinline helper-call row passes the nested aggregate through the same GPR pair
  to a private helper, and the construction-return row builds the nested
  aggregate from four scalar `i32` leaves by tracing typed AIR v2 field paths
  and packing both INTEGER eightbytes into `%rax`/`%rdx`
- first nested mixed aggregate row in
  `frontier_sysv_aggregate_classes.zig`: `{ { i32, i32 }, double }` field
  pointers carry `align(...)` qualifiers from typed AIR v2, lower through
  layout-backed byte offsets, read the nested integer pair from the SysV GPR
  class, read the floating field from the independent SSE class, and construct
  the aggregate in `%rax`/`%xmm0`
- first array-in-struct INTEGER aggregate row in
  `frontier_sysv_aggregate_classes.zig`: `[2]i64` typed AIR pointer-element
  GEPs are lowered from typed v2 and summed from the SysV GPR pair; the
  construction-return row traces typed AIR v2 array-element stores into
  flattened `insertvalue` paths and returns the two `i64` elements in
  `%rax`/`%rdx`
- first stack-passed register aggregate row in
  `frontier_sysv_aggregate_classes.zig`: after six leading `i64` parameters
  exhaust the GPR stream, a `[2]i64` aggregate argument is read from the call
  stack through the same recursive aggregate GEP offset path
- first array-in-struct SSE/SSE aggregate row in
  `frontier_sysv_aggregate_classes.zig`: `[2]f64` field and pointer-element
  GEPs lower from typed AIR v2, the two `double` elements are read from the
  independent SysV SSE argument stream, and construction returns the elements
  in `%xmm0`/`%xmm1`
- first nested SSE/SSE aggregate row in
  `frontier_sysv_aggregate_classes.zig`: `{ { double }, { double } }` nested
  field GEPs lower through layout-backed byte offsets, read both `double`
  leaves from the independent SysV SSE argument stream, and return the nested
  aggregate in `%xmm0`/`%xmm1`
- first SSE live-across-call row in `frontier_sysv_abi.zig`: one live
  `f32`/`f64` parameter is spilled from `%xmm0` to an aligned frame slot,
  another `f32`/`f64` parameter is passed to an external C ABI `void` helper,
  and the saved value is reloaded to `%xmm0` for return
- stack-passed live i32 rows in `frontier_sysv_abi.zig`: all six SysV GPR
  `i32` parameters are spilled/reloaded around a direct helper call while up
  to three stack-passed `i32` parameters are read from the restored incoming
  stack argument area for the post-call add-tree return
- second selected SSE live-across-call row in `frontier_sysv_abi.zig`: two
  live `f32` or `f64` parameters are spilled from `%xmm0`/`%xmm1` to aligned
  frame slots across a no-argument external C ABI `void` helper and reloaded
  for a post-call `fadd` return
- third selected SSE live-across-call row in `frontier_sysv_abi.zig`: three
  live `f32` or `f64` parameters are spilled from `%xmm0`/`%xmm1`/`%xmm2` to
  aligned frame slots across a no-argument external C ABI `void` helper and
  reloaded for a two-step post-call `fadd` return
- fourth selected SSE live-across-call row in `frontier_sysv_abi.zig`: four
  live `f32` or `f64` parameters are spilled from `%xmm0..%xmm3` to aligned
  frame slots across the same no-argument helper shape and reloaded for a
  three-step post-call `fadd` return
- fifth selected SSE live-across-call row in `frontier_sysv_abi.zig`: five
  live `f32` or `f64` parameters are spilled from `%xmm0..%xmm4` to aligned
  frame slots across the same no-argument helper shape and reloaded for a
  four-step post-call `fadd` return
- sixth selected SSE live-across-call row in `frontier_sysv_abi.zig`: six
  live `f32` or `f64` parameters are spilled from `%xmm0..%xmm5` to aligned
  frame slots across the same no-argument helper shape and reloaded for a
  five-step post-call `fadd` return
- selected named FP argument pass-through rows in `frontier_sysv_abi.zig`:
  five `f32` and five `f64` parameters are forwarded to external C ABI helpers
  through `%xmm0..%xmm4`; backend unit/object tests materialize immediate FP
  constants through `%xmm0..%xmm7`

Remaining measured frontier blockers kept out of accepted rows:

- mixed int-to-float plus multiply/add pipelines beyond the current selected
  FP binary subset
- private helper call graphs with more than three stack-passed live values,
  live SSE values beyond the selected no-argument-call spill shapes, or live
  values across multiple calls
- branch safety guards that return from the failure side rather than the
  current checked-runtime boundary shape
- broader unknown aggregate field, pointer arithmetic, and global/TLS address
  forms outside the selected scalar layouts
- full SysV aggregate lowering beyond selected INTEGER/INTEGER, nested
  INTEGER add chains plus nested construction returns, nested mixed INTEGER/SSE field reads/construction, selected
  mixed INTEGER/SSE and SSE/INTEGER low/high `i32`, `i64`, and `double` field
  reads/returns plus selected packed mixed construction returns, SSE/SSE field
  reads/returns including `[2]f64` array-in-struct and nested `{ { double },
  { double } }`, selected stack-passed register aggregate field reads, and generated
  normal MEMORY integer-leaf aggregate sret/byval field/copy forms currently proven
  through eight flat fields, a nested two-Big3 aggregate, a mixed-width
  `{ i64, i32, i64, i32 }` copy, and array-backed `{ [5 x i64] }` copy/read rows; X87,
  packed/unaligned aggregate ABI classes,
  arbitrary non-selected sret/byval copies, varargs, vectors, more than three
  stack-passed live values, and broader SSE live-across-call frames beyond the
  selected one-live through six-live `f32`/`f64` no-argument-call shapes and
  selected named `%xmm0..%xmm4` pass-through calls

These blockers are the next local frontier backlog. They are not accepted rows
and do not use case IDs, wrapper maps, source tags, legacy AIR text lowering,
shape recognizers, LLVM TargetMachine, LLVM optimizer, or LLD.
