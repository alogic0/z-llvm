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
- Frontier ABI boundary proof covers only `test/zig/frontier_boundaries/*.zig`
  and is intentionally separate from accepted executable rows.

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
- `test/zig/frontier/frontier_union_tags.zig`

`frontier_optionals_errors.zig` now includes source-backed error-union
wrap/error/payload matching and selected direct/nested `try` propagation. It
proves typed AIR v2 lowering for
`wrap_errunion_payload`, `wrap_errunion_err`, `is_non_err`,
`unwrap_errunion_payload`, `unwrap_errunion_err`, and the direct
`try:pl_op` continuation shape where the error path returns the original
error-union value and the ok path unwraps, computes, rewraps, and returns. It
also covers a nested two-`try` chain and a payload continuation branch where
both terminal arms rewrap payload-derived values, a local-slot continuation
where the unwrapped payload is stored, reloaded, and rewrapped after a
data-flow check proves the slot is function-local, plus source-backed
`try_ptr` and `try_ptr_cold` rows where the Zig hook exports pointer operands
for `try_ptr`/`try_ptr_cold` and `unwrap_errunion_err_ptr` and z_llvm lowers
the selected error-union pointer slot/payload path without AIR text fallback.
The direct payload-pointer row also proves `unwrap_errunion_payload_ptr:ty_op`
from typed-v2 facts: the exported instruction carries the error-union pointer
operand, z_llvm decodes the selected i32 payload into a synthetic pointer
payload value, the success arm now lowers a nested compare with add/sub
terminal returns against an ABI parameter, and the executable harness checks
both payload arms plus the error arm.
The follow-up direct payload-pointer row pairs the same success-arm payload
path with an error-arm switch over the extracted error tag, proving the
pointer-form payload path composes with the existing error-tag switch return
lowering without a selected function-name gate.
The catch/remap row adds a post-try catch body that switches over the
unwrapped error tag, returns remapped error-union constants from the cold arms,
and rewraps the hot payload after arithmetic through typed-v2 block lowering
and generic CFG backend codegen.
The catch/branch remap sibling covers the same unwrapped error-tag ownership
with `cond_br` instead of `switch_br`: z_llvm proves the direct helper call,
try guard, tag compare, terminal packed error returns, and payload add/rewrap
return from typed-v2/generic CFG facts without source-name admission.
The scalar catch/value row adds the plain-`i32` variant: a direct error-union
helper call feeds a catch-side `switch_br` over the unwrapped error tag, each
error arm returns a value derived from a live ABI parameter, and the success arm
returns payload arithmetic. The x86_64 generic CFG emitter now spills that live
`i32` parameter across the helper call and materializes the switch-phi incoming
values without source-name admission.
The catch/helper-call rows reduce refreshed compiler-core
`try:pl_op` / `unwrap_errunion_err:ty_op` shapes from
`start.posixCallMainAndExit` and `main.main`: one row catches an error-union
payload helper, and the newer `Error!void` row catches a void-success helper
where the success continuation returns ordinary `i32` arithmetic. The generic
CFG backend validates the try guard, error-tag extraction, helper-call argument
flow, generic success return, and live-parameter spill/reload instead of
admitting either row by function name.
The companion `Error!void` catch-switch row covers the `root.main() catch |err|
switch (err)` topology from `std/start.zig`: the catch side switches over the
unwrapped `i16` error tag into a merge phi, while the success continuation
returns a generic terminal `i32` expression. The same error-tag switch planner
now handles payload and void-success forms.
The `frontier_try_void_payload_match` row adds the producer-side sibling: a
helper performs `try` on an `Error!void` call, returns a new `Error!i32`
payload expression on the success edge, and rewraps the original error tag on
the failure edge. Typed-v2 lowering now represents the void try continuation as
a void value instead of requiring an `i32` payload, while the returned
`Error!i32` payload and error wraps remain driven by generic CFG data flow.
The `frontier_try_void_chain_match` row covers repeated compiler-core
`Error!void` try chains: two sequential void-success `try` operations execute
inside an `Error!void` helper, the final success returns void, and the caller
catch path classifies the propagated error. This is reduced from the preserved
ReleaseFast `main.main` / `print_targets.cmdTargets` descriptor shape and uses
the same typed-v2 try ownership rather than a row-name recognizer.
The producer-side `frontier_wrap_error_switch_match` row covers a masked
integer switch that returns either a wrapped payload or wrapped error constants
through an `i64` error-union phi. The x86_64 switch-to-phi path now accepts a
single entry-local `arg & const` condition, while still requiring the arms and
default to branch to one proven merge phi.
The `frontier_wrap_error_branch_match` row covers the direct branch variant:
terminal `cond_br` arms return wrapped error constants without a merge phi,
proving the existing typed-v2 terminal branch path owns selected
`wrap_errunion_err` constants outside the switch shape.
The `frontier_error_tag_branch` row covers the branch classifier variant:
`unwrap_errunion_err` feeds an `i16` equality guard and two terminal constant
returns, while the success arm reuses payload arithmetic from the same direct
error-union helper call.
The `frontier_error_catch_default_merge` row covers a catch-to-value merge:
the success arm unwraps the payload into an `i32` phi, the catch arm contributes
a live fallback parameter, and the merged value feeds post-merge arithmetic with
the fallback parameter spilled across the helper call. The companion
`frontier_error_catch_const_merge` row proves the same merge plan with a
constant catch fallback.
The `frontier_try_call_result_match` row covers a post-`try` payload-call
continuation: the success arm unwraps the helper payload, passes it with a live
`i32` parameter to a second direct helper call, wraps that call result into the
error-union return, and the error arm propagates the original error-union
value. Generic CFG codegen validates the payload-to-call argument data flow and
spills the live parameter across the first helper call; admission is not based
on the row or helper name.
The `frontier_catch_return_error_match` row covers the explicit
`catch |err| return err` producer shape: the cold path extracts the error bits
from the direct error-union call, truncates them to the error tag, re-extends
them into the returned `i64` error-union encoding, and the hot path rewraps
payload arithmetic. The accepted lowering validates that error-bit data flow
instead of treating it as the simpler "return original call result" try edge.
The switch-local try row adds a switch arm whose nested value-producing block
contains a `try` call; the error edge returns the original error-union value
and the success edge rewraps payload arithmetic into the outer switch phi.
Typed-v2 block/value facts own the admission, and x86_64 generic CFG lowers
the call, guard, branch-to-merge, and i64 error-union return without a
function-name gate.
The counted-loop try rows now include a post-loop switch continuation:
`frontier_loop_try_post_switch` carries the loop accumulator through the helper
`try` guard, computes `total & 3` after loop exit, and returns one of two
explicit switch-case addends or the default addend. The typed-v2 lowerer emits a
real switch terminator for that continuation, and generic CFG validates the
case targets and terminal return values before codegen. The model summary now
derives the mask and addends from the typed AIR `bit_and`, branch-to-block,
load, and add data flow rather than fixed row constants.
The sibling post-loop branch summary similarly derives its threshold argument
and terminal add/sub constants from the typed AIR `cmp_gt`, accumulator load,
and return-value flow.
The optional scalar payload branch row now validates `wrap_optional`,
`is_non_null`, and `optional_payload` data flow from typed-v2 facts, lowers the
payload add/sub branch through generic single-block CFG, and has executable
proof for both payload arms and the null fallback in ReleaseFast, ReleaseSafe,
and ReleaseSmall. This is still a selected optional-payload branch subset, not
arbitrary optional control-flow lowering.
The same pointer-form path now includes a post-try payload branch where both
arms rewrap add/sub results, including the unsigned payload compare emitted by
this AIR shape, plus a nested two-`try_ptr` chain that feeds the first payload
into the second helper call before rewrapping the final payload. The
pointer-form switch row now feeds the synthetic payload into a selected integer
switch and rewraps all chosen arms, extending the same semantic pointer-slot
model beyond branch continuations. Broader
arbitrary compiler-core `try` and pointer-form error-union forms remain a
separate compiler-core priority.
The `frontier_error_name_len` row now proves typed-v2 ownership for AIR
`error_name`: Zig exports the operand tying `error_name` to the selected
error-set value and z_llvm lowers the sentinel `u8` slice result from typed-v2
facts without AIR-text recovery or sidecars. The executable proof checks
`@errorName(err).len` for both selected error values. The companion
`frontier_error_name_three_len` row proves the same typed-v2 path for a
three-name concrete error set by deriving pointer/length selects from the
exported error-set names and the runtime error code. ReleaseSafe now keeps the
integer-to-error validation enabled for that row: Zig exports
`error_set_has_value` as a versioned typed unary membership record with the
checked operand and destination error-set type, and z_llvm lowers the selected
dense concrete error-set membership check from those facts. The executable
harness checks valid error values and a child-process trap for an invalid error
code. Arbitrary sparse/non-dense error-set membership and arbitrary error-name
payload materialization remain outside this narrow row.

`frontier_mixed_numeric.zig` now includes scalar `@byteSwap` rows for `u16`,
`u32`, and `u64`. Zig exports AIR `byte_swap` as the versioned
`zllvm-byte-swap-v1` typed `ty_op` record with an operand ref, integer result
type, operand text, and bit width. z_llvm lowers those typed facts through the
generic scalar transform path to x86_64 `rolw`/`bswapl`/`bswapq` instructions,
so the accepted rows do not leave `llvm.bswap.*` as linker-visible symbols.
Vector byte swaps, aggregate `byteSwapAllFields`, `u8` identity policy, and
odd-width integer byte swaps remain future/boundary work.
The same source now includes signed `i32` `@max` and `@min` rows. Zig exports
AIR `max` and `min` as typed `bin_op` records, z_llvm lowers the operands to
signed compare/select forms, and the x86_64 generic CFG backend emits the
shared signed max/min machine patterns. Unsigned max/min, wider integer
max/min, vector max/min, and odd-width integer scalar transforms remain future
work.
The same scalar-transform family now includes selected signed `i32` `@abs`.
Zig exports AIR `abs` as a versioned `zllvm-abs-v1` typed `ty_op` record with
the operand ref, result type, bit width, and operand signedness. z_llvm lowers
the supported `i32 -> u32` form through generic compare/sub/select IR, and the
C harness checks positive, negative, and zero inputs. Wider integer abs, vector
abs, odd-width integer abs, and explicit ReleaseSafe overflow/minInt
negative-path proof remain future work.

`frontier_union_tags.zig` adds the first source-backed tagged-union tag/payload
switch proof. The patched Zig typed-v2 exporter emits versioned
`zllvm-union-tag-facts-v1` facts for `set_union_tag` and `get_union_tag`, plus
`zllvm-switch-facts-v1` case tag indexes for the union-tag `switch_br`. z_llvm
admits the row from those typed facts and the structural payload data-flow, not
from a function-name gate. The model now accepts reversed source switch-arm
ordering when the exported case tag indexes prove the same selected tag set.
It also proves either selected tag arm may store the raw second argument or a
constant add of that argument before the payload return add. Branch-to-tag
selection now comes from structured-air then/else bodies, so the reordered-field
row proves the selected lowering no longer assumes tag index 0 is always the
true branch. The C harness checks both `.small` and `.large` payload paths
across ReleaseFast, ReleaseSafe, and ReleaseSmall. General union ABI/layout
lowering remains future work; this row only owns the selected frontier
tag/payload switch shape.

`frontier_slice_pointer_arith.zig` now covers the next pointer/slice family
after `slice_len`: direct `slice_len`, `slice_ptr`, `ptr_slice_ptr_ptr`,
`slice_elem_ptr`, runtime and comptime `ptr_add`, chained `ptr_add`,
constant `ptr_sub`, runtime `ptr_sub` with one additive and one subtractive
dynamic index term, pointer-add-fed loads, pointer-add-fed stores, and
load/store through derived slice element pointers. The same typed address path
now covers `slice.ptr` plus constant offset plus runtime index feeding a
store/reload, so the slice pointer proof is not load-only. It also covers a
pointer-to-array slice (`values[0..]`) lowered from typed
`bitcast`/`ptr_add`/`ptr_elem_ptr` facts. The x86_64 generic CFG path now uses
a reusable typed address model with a base pointer, additive and subtractive
dynamic index terms, constant byte offset, scalar width, and conservative
element-size checks. Accepted rows prove
i8, i16, i32, and i64 scalar pointer loads/stores, including dynamic-index and
constant-offset forms. The accepted rows now include a two-term dynamic address
where the subtractive index arrives in `%rcx`; the emitter consumes that term
before reusing `%rcx` as the final address register. Forms that also need `%r8`
preserved while `%r8` is the scratch register remain explicitly fail-closed.
The accepted `slice_elem_ptr` rows still include
unchecked pointer-address proof, and `frontier_checked_slice_elem_ptr_load` now
adds the checked bounds guard: the hot path lowers through the same typed
address model, the cold path preserves the `outOfBounds(index, len)` noreturn
runtime call, and the C harness proves both the in-bounds result and
child-process trap behavior.

The aggregate/type-layout ownership milestone has started without changing the
strict frontier counters. `src/zig_air_type_layout.zig` now owns named aggregate
decoding, recursive field/leaf queries, field byte offsets, and supported
scalar-leaf collection. `src/zig_air_types.zig` delegates nominal aggregate
parsing to that decoder, while `src/zig_air_capabilities.zig`,
`src/codegen/x86_64/sysv_abi.zig`, and generic CFG C ABI aggregate lowering
consume the same layout model for field access, aggregate copy planning,
construction/return paths, and SysV aggregate classification. Existing
source-backed rows in `frontier_nested_records.zig`, `frontier_sysv_abi.zig`,
`frontier_sysv_aggregate_classes.zig`, and `frontier_sysv_sret_byval.zig` are
the representative object/native-link/executable proof for the first slice.
The follow-up slice removes the former ambiguous nominal `Pair` compatibility:
nominal `Pair` is normalized as `{ i32, i32 }`, and runtime aggregate-pair
compatibility lowerers admit by normalized layout plus construction/call/return
data flow rather than exact aggregate-pair symbol names. `AggregateLayoutPlan`
now supplies the shared normalized field/leaf plan for pair admission and
sret/byval aggregate copy/make planning, and typed-v2 register aggregate
construction admission validates operands against the same plan before using
typed AIR pointer paths for insertvalue indices. SysV classification consumes
the same normalized aggregate type. `AggregateLayoutSummary` records layout
source, field count, scalar leaves, and construction/store/load evidence. The
compatibility fallback table has been removed, the temporary static source fact
provider is empty, and the sidecar files are header-only. The patched Zig
stage4 emitter writes `zllvm-aggregate-layout-facts-v1` directly into AIR
descriptors for supported aggregate semantic layouts; z_llvm parses the
optional `aggregate_layout_facts_bytes` section and gives descriptor facts
precedence over compatibility sidecars. The current empty-sidecar provider
audit reports `exported_facts=0`, `static_source_facts=0`,
`boundary_provider=2`, `generated_examples=0`, `sidecar_exported_facts=0`,
and `descriptor_exported_facts=0`. The same audit tool accepts
`--from-air=<descriptor>` for saved AIR descriptors; the saved
`tmp/aggregate_hook_check.air` descriptor reports `descriptor_exported_facts=14`
and `static_source_facts=0`, proving descriptor-owned aggregate facts are now
machine-readable evidence rather than only gate-internal state. The former
non-frontier sidecar compatibility facts have been retired.
The 2 packed/unaligned targeted entries are boundary-owned through
`src/zig_air_aggregate_layout_boundaries.zig`.
Register aggregate
construction and sret/byval make rows now add function-local typed AIR
inference on top of the nominal summaries: `ret_ptr` plus field/element pointer
stores and `ret_load` are used to validate the aggregate shape, including the
selected single-field array-leaf form, before the row is admitted. Register
aggregate construction and direct sret aggregate make validation now classify
and plan from the inferred layout before provider facts when the store paths
prove the shape. Sret/byval
copy rows now mechanically validate that the terminal return is the typed
aggregate argument, and sret/byval call-wrapper rows validate that the typed
aggregate argument feeds the single call and that the aggregate terminal return
is produced by that call. The remaining source-fact table is still static, so
the next aggregate ownership step is to derive more of those layouts from
exported Zig field facts or broader function-local construction/copy evidence.

Current frontier ABI boundary seed:

- `test/zig/frontier_boundaries/frontier_varargs_boundary.zig`
- `test/zig/frontier_boundaries/frontier_vector_boundary.zig`
- `test/zig/frontier_boundaries/frontier_x87_boundary.zig`
- `test/zig/frontier_boundaries/frontier_packed_aggregate_boundary.zig`
- `test/zig/frontier_boundaries/frontier_tail_call_boundary.zig`
- `test/zig/frontier_boundaries/frontier_callconv_boundary.zig`
- `test/zig/frontier_boundaries/frontier_pointer_slice_boundary.zig`
- `test/zig/frontier_boundaries/frontier_tag_name_boundary.zig`
- `test/zig/frontier_boundaries/frontier_union_payload_boundary.zig`

Current ReleaseFast, ReleaseSafe, and ReleaseSmall counters:

```text
source_rows=14
discovered_functions=740
structured_functions=740
generic_codegen_functions=740
generic_cfg_functions=740
structural_matcher_functions=0
structured_air_v2_functions=740
typed_air_operand_functions=740
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_lowering_functions=740
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
object_emitted_functions=740
object_failures=0
llvm_targetmachine_rows=0
local_fail=0
```

Object inspection is green for all three modes:

```text
inspected=13
elf64_rel=13
relocation_rows=5
tls_rows=1
undefined_import_rows=1
comdat_rows=0
eh_frame_rows=0
unsupported_relocation_rows=0
local_fail=0
```

Native-link progress is green for all three modes:

```text
native_link_accepted_rows=14
executable_ok_rows=14
link_only_rows=0
runtime_boundary_rows=0
unsupported_zig_linker_feature_rows=0
native_link_failures=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

Source-backed ABI and pointer/slice boundary proof is green for all three modes through
`zig build distribution-air-release-frontier-boundaries`:

```text
source_rows=10
discovered_functions=16
varargs_boundary_rows=2
vector_boundary_rows=2
x87_boundary_rows=2
packed_aggregate_boundary_rows=2
tail_call_boundary_rows=1
callconv_boundary_rows=1
stack_pressure_boundary_rows=0
safety_edge_boundary_rows=0
pointer_slice_boundary_rows=2
tag_name_boundary_rows=1
union_payload_boundary_rows=1
optional_error_mix_boundary_rows=2
unexpected_accept_rows=0
wrong_diagnostic_rows=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

These boundary rows are expected unsupported source-backed ABI surfaces. They
are not counted in the accepted 14-source / 734-function strict frontier
executable proof. Stack-pressure forwarding for the previous
Big80/Big81/Big96/Big128/Big160/Big192/Big224/Big256 indirect and stack-source
rows is now accepted in the frontier corpus; the boundary gate keeps
`stack_pressure_boundary_rows=0` as a regression guard. Checked slice-element
bounds CFG is accepted in the strict frontier corpus, so
`safety_edge_boundary_rows=0` is now a regression guard rather than an active
boundary. Checked slice-element stores are also accepted in the strict frontier
corpus. The active `pointer_slice_boundary_rows=2` entries cover volatile and
atomic derived-pointer forms that remain fail-closed with
`UnsupportedPointerSliceAbi`. The `tag_name_boundary_rows=1` row covers
source-backed `@tagName` string/sentinel-slice lowering; ReleaseFast reaches
`tag_name`, while ReleaseSafe/ReleaseSmall can fail earlier at the associated
`is_named_enum_value` guard, and both forms are classified as the same
runtime/string boundary. The `union_payload_boundary_rows=1` row covers a
non-selected three-tag payload switch shape and keeps unsupported union payload
layouts fail-closed.

Executable ABI proof is green for all three modes:

```text
native_link_accepted_rows=14
executable_ok_rows=14
link_only_rows=0
runtime_boundary_rows=0
unsupported_zig_linker_feature_rows=0
native_link_failures=0
llvm_targetmachine_rows=0
lld_rows=0
local_fail=0
```

Closed in the current runtime/safety-edge slice:

- panic-slice runtime-call lowering no longer uses a selected message-length
  immediate in the strict release path; `debug.defaultPanic` slice lengths are
  derived from typed AIR values for direct constants, `{ ptr, i64 }` slice
  aggregates, i64 parameters, loaded i64 globals/parameter pointers, and simple
  i64 add/sub expressions
- selected multi-input length selection is now lowered through typed AIR
  `select` values before the noreturn runtime call
- selected loaded payload pointer objects are materialized into `%rdi` when the
  payload remains a `{ ptr, i64 }` panic slice
- ReleaseSafe slice-panic guard CFGs with an ok return, bounds check block,
  cold `outOfBounds` edge, default panic continuation, and noreturn/unreachable
  runtime blocks now route through generic CFG
- new frontier rows cover parameter-derived, computed, and loaded panic-slice
  lengths while keeping stable executable probes on the non-panic path
- child-process negative-path executable proof covers non-constant panic-slice
  calls, explicit signed/unsigned checked-overflow panic rows, and ReleaseSafe
  bounds/null/int-conversion panic rows

Remaining runtime/safety-edge debt:

- arbitrary phi/control-flow length selection beyond the current typed AIR
  `select` form remains future work
- arbitrary panic payload forms and computed payload pointers outside the
  current slice-pointer plus i64-length subset remain future runtime-call work

Closed in the current memory/aggregate frontier slice:

- nested counted loop-memory CFG through
  `frontier_nested_memory_sum`
- selected nested extern-struct field GEP paths through
  `frontier_nested_field_left_b` and `frontier_nested_field_right_a`
- selected dynamic/comptime/chained pointer addition and pointer-element GEP
  loads/stores through a reusable typed address model in
  `frontier_dynamic_ptr_add`, `frontier_dynamic_ptr_pair_sum`,
  `frontier_comptime_ptr_add`, `frontier_chained_ptr_add`,
  `frontier_ptr_add_store`, `frontier_slice_ptr_load`,
  `frontier_slice_elem_ptr_load`, `frontier_slice_elem_ptr_store`,
  `frontier_ptr_add_load_u8`, `frontier_ptr_add_load_u16`,
  `frontier_ptr_add_load_u64`, `frontier_ptr_add_store_u8`,
  `frontier_ptr_add_store_u16`, and `frontier_ptr_add_store_u64`
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
  using layout-derived byte offsets, including the flat thirty-two-field BigN row,
  the nested `{ { i64, i64, i64 },
  { i64, i64, i64 } }` copy/read row and the mixed-width
  `{ i64, i32, i64, i32 }` copy row; the nested
  `{ i8, { i16, i32 }, i64 }` copy row proves byte/word leaves use
  width-correct stack loads and `%al`/`%ax` stores in the same layout-derived
  copy path; the
  array-backed `{ [5 x i64] }` rows prove the same byte-offset copy and
  by-value field-read paths for integer array leaves inside a normal MEMORY
  aggregate; the flat `BigN` typed parser
  now covers larger normal integer-leaf MEMORY aggregates through `Big20`
  construction, field-read, and byval-to-sret copy rows, and `ScalarMixed`
  proves a direct scalar-parameter hidden-sret make row for top-level `i8`,
  `i16`, `i32`, `i64`, pointer, `f32`, and `f64` fields; `ScalarNested`
  proves recursive supported-leaf scalar-parameter hidden-sret construction
  through layout-derived byte-offset stores, and `ScalarArray` proves the same
  scalar-param construction path for array-backed `i32`/`f64` leaves; the
  `ScalarMixed`/`ScalarNested`/`ScalarArray` follow-up now also proves direct
  and pointer-callee byval-to-sret copies for top-level supported leaves,
  nested supported leaves, mixed array-contained integer leaves,
  array-contained double leaves, and pointer leaves through the same
  layout-derived MEMORY copy path; the
  `BigDouble` row
  adds the first double-leaf MEMORY byval-to-sret copy proof through XMM
  `movsd` stack loads and hidden-sret stores, the `BigPtrDouble` row proves the
  same layout-derived copy path for pointer, `double`, and `i64` leaves in one
  MEMORY aggregate, `BigPtrFloat` proves pointer, `f32`, and `i64` leaves in
  the same MEMORY copy path, `BigFloat` proves five `f32` leaves through
  dedicated `movss` stack loads and hidden-sret stores, `BigFloatArray` proves
  array-contained `f32` leaves through the recursive copy path, and `BigDoubleArray` proves an
  array-of-double MEMORY aggregate through the same recursive copy path; the
  `BigArrayMixed` row combines array-contained `i32`, array-contained `f64`,
  and pointer leaves in one byval-to-sret MEMORY aggregate; the
  `BigNestedArrayMixed` row nests array-contained `f32` and `f64` leaves with
  pointer and `i64` leaves and proves the same direct and pointer-callee
  byval-to-sret copy path for a deeper supported-leaf MEMORY layout; the
  `BigStructArrayMixed` row proves array elements that are themselves
  aggregate leaves (`{ i32, double }`) through the same recursive
  byval-to-sret copy path; the `BigDeepMixed` row composes nested
  array-backed float/double leaves, array-of-aggregate records, recursively
  nested scalar leaves, pointer arrays, and an integer tail through the same
  direct and pointer-callee byval-to-sret copy path; `Big32`, `Big40`,
  `Big48`, `Big64`, `Big80`, `Big81`, `Big96`, `Big128`, `Big160`, `Big192`, `Big224`, and `Big256` raise the same planner-owned byval-to-sret direct
  copy path through exact-qword MEMORY payloads beyond byte-offset byval loads
  using disp32 source-pointer reloads through the current 256-stack-argument
  planner cap; Big80, Big81, Big96, Big128, Big160, Big192, Big224, and Big256 now also prove pointer-callee
  byval forwarding, with Big81 covering a non-qword tail, and the stack-sourced
  `Big40`, `Big48`, `Big64`, `Big80`, `Big81`, `Big96`, `Big128`, `Big160`, `Big192`, `Big224`, and `Big256` direct
  and pointer-callee copy rows prove incoming byval payloads that begin in the
  caller stack argument area are copied as payload slots rather than treated as
  pointers;
  `frontier_direct_big5_copy`,
  `frontier_indirect_big5_copy`, `frontier_direct_big_double_copy`,
  `frontier_indirect_big_double_copy`, `frontier_direct_big_float_copy`,
  `frontier_indirect_big_float_copy`, `frontier_direct_big_double_array_copy`,
  `frontier_indirect_big_double_array_copy`,
  `frontier_direct_big_ptr_double_copy`, and
  `frontier_indirect_big_ptr_double_copy`, `frontier_direct_big_narrow_copy`,
  and `frontier_indirect_big_narrow_copy` prove normal supported-leaf MEMORY
  aggregates with integer, pure FP, pointer, and mixed pointer/FP/integer
  leaves can flow through direct and indirect calls by preserving the hidden
  sret pointer, forwarding pointer callees through `%rax` when needed, and
  copying incoming by-value stack slots to outgoing stack slots before the
  call; `frontier_direct_big_nested_copy`,
  `frontier_indirect_big_nested_copy`, `frontier_direct_big_array_copy`, and
  `frontier_indirect_big_array_copy` prove the same call path for recursive
  nested aggregate leaves and array-backed aggregate leaves
- first mixed SysV aggregate class row in
  `frontier_sysv_aggregate_classes.zig`: `{ i64, double }`, selected
  `{ i32, double }`, and selected `{ i32, i32, double }` forms are classified as
  mixed INTEGER/SSE, and field reads return low/high integer members from the
  GPR stream and floating members from the SSE stream; construction returns the
  `i64` aggregate in `%rax`/`%xmm0`, while the packed mixed construction row
  packs adjacent low/high `i32` fields into `%rax` and returns the `double` in
  `%xmm0`; a noinline helper-call row returns the same register aggregate
  directly from a private helper without scalarizing through a selected wrapper;
  `frontier_stack_array_pair_call_sum` forwards a stack-passed INTEGER
  aggregate into a private helper by loading the stack eightbytes into outgoing
  GPR aggregate slots, `frontier_stack_mixed_call_int` forwards a stack-passed
  `{ i64, double }` mixed aggregate into outgoing register aggregate slots, and
  `frontier_stack_mixed_call_int_after_pressure` plus
  `frontier_stack_mixed_call_float_after_pressure` prove the same mixed
  aggregate can be stack-passed into a helper after both the GPR and SSE
  argument streams are exhausted; the helper field returns cover both the
  INTEGER and SSE stack eightbytes; `frontier_stack_nested_mixed_forward_after_pressure`
  returns the same stack-passed nested mixed aggregate by reloading the caller
  stack eightbytes into `%rax`/`%xmm0`;
  `frontier_shifted_mixed_call_int` now proves in-register aggregate
  pass-through can move a shifted INTEGER eightbyte from `%rsi` to `%rdi`
  before the helper call instead of requiring exact source/destination slots;
  direct and pointer-callee nested mixed aggregate forward rows now also prove
  register-class aggregate pass-through returns without selected sret rewriting
- first SSE/SSE aggregate class row in
  `frontier_sysv_aggregate_classes.zig`: `{ double, double }` is classified as
  SSE/SSE, field reads return from the independent SSE argument stream, and
  construction returns the aggregate in `%xmm0`/`%xmm1`; `{ f32, f32 }` is
  classified as one SSE eightbyte, returns low/high f32 lanes from `%xmm0`, and
  constructs the packed f32 pair return through the same generic aggregate
  return path. The f32 pair follow-up forwards the same single-eightbyte SSE
  aggregate through direct, shifted, and pointer-callee helper calls, and the
  helper body adds both f32 fields through generic aggregate field-add
  lowering. `frontier_stack_float_pair_forward_after_pressure` returns the same
  single-eightbyte SSE aggregate from a caller-stack argument by reloading it
  into `%xmm0` after the SSE argument stream is exhausted.
  `frontier_stack_float_pair_indirect_forward_after_pressure` uses the same
  caller-stack reload before a function-pointer call and returns the callee's
  `%xmm0` result. The
  `frontier_stack_array_double_call_sum` row forwards a stack-passed SSE/SSE
  `[2]f64` aggregate into a private helper by loading the source stack
  eightbytes into outgoing XMM aggregate slots; the
  `frontier_stack_array_double_forward_after_pressure` row returns the same
  stack-passed `[2]f64` aggregate by reloading caller-stack eightbytes into
  `%xmm0`/`%xmm1`
- first reversed mixed aggregate class row in
  `frontier_sysv_aggregate_classes.zig`: `{ double, i64 }`, selected
  `{ double, i32 }`, and selected `{ double, i32, i32 }` forms are classified as
  SSE/INTEGER, field reads return from the independent SSE/GPR streams including
  high 32-bit integer lanes, construction returns the `i64` aggregate in
  `%xmm0`/`%rax`, and the packed reversed construction row packs adjacent
  low/high `i32` fields into `%rax`; `frontier_shifted_reverse_mixed_call_float`
  proves shifted in-register SSE aggregate pass-through by moving `%xmm1` to
  `%xmm0` with the generic XMM move helper before a private helper call.
  `frontier_indirect_reverse_mixed_call_float` and
  `frontier_indirect_reverse_mixed_make` prove the same SSE/INTEGER aggregate
  argument and return classes through pointer-callee SysV call planning with
  executable C ABI checks. `frontier_stack_reverse_mixed_forward_after_pressure`
  returns a stack-passed `{ double, i64 }` aggregate by reloading caller-stack
  eightbytes into `%xmm0`/`%rax`
- first nested INTEGER aggregate add-chain row in
  `frontier_sysv_aggregate_classes.zig`: nested `{ i32, i32 }` fields are
  flattened through byte offsets, classified as INTEGER/INTEGER, and summed
  from the SysV GPR pair without a function-name-specific lowering path; the
  noinline helper-call row passes the nested aggregate through the same GPR pair
  to a private helper, and the construction-return row builds the nested
  aggregate from four scalar `i32` leaves by tracing typed AIR v2 field paths
  and packing both INTEGER eightbytes into `%rax`/`%rdx`
- shifted nested mixed aggregate helper-call row in
  `frontier_sysv_aggregate_classes.zig`: `frontier_shifted_nested_mixed_call_int`
  proves an INTEGER/SSE aggregate can shift both the GPR and SSE streams before
  a private helper call, and the pointer-callee follow-up proves
  `{ { i32, i32 }, double }` INTEGER/SSE aggregate arguments and returns through
  indirect helper calls using the same SysV planner-owned register assignment
  path. `frontier_nested_mixed_call_forward` and
  `frontier_indirect_nested_mixed_forward` keep the same nested mixed aggregate
  in the register ABI, forwarding incoming GPR/SSE eightbytes to
  `%rax`/`%xmm0` for direct and pointer-callee helper returns without sret
  rewriting
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
  stack through the same recursive aggregate GEP offset path; the follow-up
  `frontier_stack_array_pair_call_sum_after_six` row passes the same
  stack-sourced aggregate through to a helper whose outgoing aggregate
  destination is also the SysV stack area, proving integer aggregate stack
  argument forwarding without register-slot assumptions; the
  `frontier_register_array_pair_call_sum_after_six` row proves the companion
  register-sourced form by pushing the aggregate eightbytes before the six
  leading scalar call arguments reuse `%rdi`/`%rsi`; the
  `frontier_deep_stack_array_pair_call_sum_after_six` row places the incoming
  aggregate past the disp8 stack window and proves disp32 stack-source
  aggregate forwarding into outgoing stack slots
- stack-passed nested mixed aggregate row in
  `frontier_sysv_aggregate_classes.zig`:
  `frontier_stack_nested_mixed_call_int_after_pressure` exhausts both the GPR
  and SSE argument streams before passing `{ { i32, i32 }, double }` through a
  private helper; the generic aggregate field path now loads stack-passed
  `i32` fields into `%eax` before add-chain returns
- first array-in-struct SSE/SSE aggregate row in
  `frontier_sysv_aggregate_classes.zig`: `[2]f64` field and pointer-element
  GEPs lower from typed AIR v2, the two `double` elements are read from the
  independent SysV SSE argument stream, and construction returns the elements
  in `%xmm0`/`%xmm1`; `frontier_register_array_double_call_sum_after_eight`
  proves register-sourced SSE/SSE aggregate stack forwarding after the callee
  SSE stream is exhausted by eight leading scalar `double` arguments
- shifted array-in-struct SSE/SSE aggregate rows in
  `frontier_sysv_aggregate_classes.zig`:
  `frontier_shifted_array_double_second` and
  `frontier_shifted_array_double_call_sum` prove that `[2]f64` fields shifted
  into `%xmm1`/`%xmm2` are returned or forwarded through generic XMM moves
- deep stack-sourced SSE/SSE aggregate row in
  `frontier_sysv_aggregate_classes.zig`:
  `frontier_deep_stack_array_double_call_sum` exhausts the SSE argument stream
  before passing `[2]f64`; the aggregate is reloaded from a disp32 stack-source
  offset and forwarded into the helper's XMM aggregate argument registers
- first nested SSE/SSE aggregate row in
  `frontier_sysv_aggregate_classes.zig`: `{ { double }, { double } }` nested
  field GEPs lower through layout-backed byte offsets, read both `double`
  leaves from the independent SysV SSE argument stream, and return the nested
  aggregate in `%xmm0`/`%xmm1`
- `[4]f32` SSE/SSE aggregate rows in
  `frontier_sysv_aggregate_classes.zig`: typed AIR v2 array-element paths
  extract four `float` lanes from `%xmm0`/`%xmm1`, construction returns pack
  two f32 lanes into each SSE return register, and direct plus pointer-callee
  helper calls spill/reload the paired SSE eightbytes while lowering the
  helper's four-lane f32 add body generically
- stack-passed `[4]f32` SSE/SSE aggregate row in
  `frontier_sysv_aggregate_classes.zig`:
  `frontier_stack_float_array_call_sum_after_eight` exhausts the SSE argument
  stream before passing `[4]f32` through a private helper; the generic f32
  aggregate term path now loads stack-resident float fields into arbitrary XMM
  temporaries with `movss`
- first SSE live-across-call row in `frontier_sysv_abi.zig`: one live
  `f32`/`f64` parameter is spilled from `%xmm0` to an aligned frame slot,
  another `f32`/`f64` parameter is passed to an external C ABI `void` helper,
  and the saved value is reloaded to `%xmm0` for return
- deep stack-resident `f32`/`f64` parameter returns in
  `frontier_sysv_abi.zig`: `frontier_deep_stack_f32_return` and
  `frontier_deep_stack_f64_return` exhaust the SSE argument stream and prove
  direct FP parameter returns can load a stack-passed float or double through
  a disp32 incoming stack offset; `frontier_deep_stack_f32_live_after_call`
  and `frontier_deep_stack_f64_live_after_call` prove the same stack FP
  reload after a side-effecting void call restores `%rsp`
- stack-passed `f32`/`f64` call-argument reload rows in `frontier_sysv_abi.zig`:
  `frontier_f32_stack_arg_to_registers` and
  `frontier_indirect_f32_stack_arg_to_registers` plus the matching
  `frontier_f64_stack_arg_to_registers` rows exhaust the SSE argument stream,
  then reload incoming stack-passed FP parameters into outgoing XMM helper-call
  registers for direct and pointer-callee calls
- outgoing stack-passed `f32`/`f64` helper-call rows in
  `frontier_sysv_abi.zig`: `frontier_nine_f32_stack_arg_call`,
  `frontier_indirect_nine_f32_stack_arg_call`, and the matching `f64` rows
  pass a ninth FP argument through the SysV stack slot for direct and
  pointer-callee helper calls; `frontier_nine_f32_const_stack_arg_call` and
  `frontier_nine_f64_const_stack_arg_call` prove the same outgoing stack-slot
  path for immediate FP constants
- mixed GPR/SSE outgoing stack row in `frontier_sysv_abi.zig`:
  `frontier_mixed_gpr_sse_stack_arg_call` calls an external C ABI helper with
  eight `i32` and ten `double` arguments, forcing both the GPR and SSE argument
  streams to overflow into SysV stack slots in the same call; the
  `frontier_indirect_mixed_gpr_sse_stack_arg_call` companion proves the same
  stack-slot assignment through a function-pointer callee;
  `frontier_mixed_gpr_sse_f32_stack_arg_call` and
  `frontier_indirect_mixed_gpr_sse_f32_stack_arg_call` prove the same direct
  and pointer-callee stack-slot path for ten `float` arguments; and
  `frontier_mixed_i64_sse_f32_stack_arg_call` plus
  `frontier_indirect_mixed_i64_sse_f32_stack_arg_call` extend that path to
  eight `i64` plus ten `float` arguments;
  `frontier_mixed_i64_sse_stack_arg_call` and
  `frontier_indirect_mixed_i64_sse_stack_arg_call` prove the same independent
  cursor/stack-slot assignment for eight `i64` plus ten `double` arguments
- stack-passed live i32 rows in `frontier_sysv_abi.zig`: all six SysV GPR
  `i32` parameters are spilled/reloaded around a direct helper call while more
  than six stack-passed `i32` parameters are read from the restored incoming
  stack argument area for the post-call add-tree return; current executable
  rows prove seven, eight, twelve, thirteen, fourteen, and eighteen
  stack-passed live `i32` values, and
  `frontier_deep_stack_live_after_call` proves post-call reload of a deep
  stack-passed `i32` parameter through a disp32 incoming stack offset, and
  `frontier_deep_stack_i64_return` and `frontier_deep_stack_ptr_return`
  prove direct return of deep stack-passed `i64` and pointer values, while
  `frontier_deep_stack_i64_live_after_call` and
  `frontier_deep_stack_ptr_live_after_call` prove the same restored incoming
  stack path after a void call
- six stack-passed scalar `i32` call arguments in `frontier_sysv_abi.zig`:
  `frontier_six_stack_arg_call` calls a C helper with 12 scalar arguments. The
  backend reserves alignment padding before pushing stack arguments so arg 7 is
  visible at the callee's first stack-argument slot.
- eight, twelve, and eighteen stack-passed scalar `i32` call arguments in
  `frontier_sysv_abi.zig`: `frontier_eight_stack_arg_call`,
  `frontier_twelve_stack_arg_call`, and `frontier_eighteen_stack_arg_call`
  reuse the same push-based SysV planner and clean larger outgoing stack areas
  with immediate `%rsp` adjustment. The indirect eighteen-stack-argument row
  also proves disp32 stack-source reloads after outgoing stack pushes.
- named stack-parameter forwarding for stack-passed scalar `i32` call
  arguments in `frontier_sysv_abi.zig`: `frontier_stack_arg_forward` forwards
  all 12 incoming C ABI arguments to an external helper, copying the incoming
  stack slots into outgoing stack argument slots after alignment padding.
- named stack-parameter register assignment for scalar `i32` call arguments in
  `frontier_sysv_abi.zig`: `frontier_stack_arg_to_registers` loads incoming
  stack-passed parameters into outgoing `%edi`..`%r9d` argument registers for a
  six-argument helper call. `frontier_ptr_stack_arg_to_registers` and
  `frontier_indirect_ptr_stack_arg_to_registers` prove the same cursor-derived
  incoming stack reload path for pointer parameters assigned into outgoing GPR
  registers for direct and function-pointer helper calls.
- selected computed stack-passed scalar `i32` call argument in
  `frontier_sysv_abi.zig`: `frontier_computed_stack_arg_call` computes a
  block-local `i32`, materializes it through `%eax`, and pushes it into the
  outgoing stack argument area through the shared SysV scalar planner.
- typed AIR v2 pointer-callee register assignment in
  `frontier_sysv_abi.zig`: `frontier_indirect_stack_arg_to_registers` resolves
  operand 0 as a callee value, copies it to `%rax`, loads incoming stack-passed
  `i32` parameters into outgoing `%edi`..`%r9d`, and emits `callq *%rax`.
- typed AIR v2 pointer-callee stack forwarding in
  `frontier_sysv_abi.zig`: `frontier_indirect_stack_arg_forward` uses the same
  indirect `%rax` call path while forwarding 12 `i32` arguments, including
  outgoing stack slots, through the shared SysV planner.
- typed AIR v2 pointer-callee stack forwarding through the larger cleanup path
  in `frontier_sysv_abi.zig`: `frontier_indirect_eight_stack_arg_forward`
  forwards 14 `i32` arguments through `callq *%rax`, proving the indirect path
  uses the same immediate `%rsp` cleanup as direct calls with eight outgoing
  stack slots.
- typed AIR v2 pointer-callee SSE calls in `frontier_sysv_abi.zig`:
  `frontier_indirect_five_f32_external_call` and
  `frontier_indirect_five_f64_external_call` return through `%xmm0` after
  assigning five `f32` or `f64` arguments through the independent SSE cursor.
- `i64` scalar stack/GPR rows in `frontier_sysv_abi.zig`:
  `frontier_i64_stack_arg_to_registers` loads incoming stack-passed `i64`
  parameters into outgoing GPR call slots, and
  `frontier_indirect_i64_stack_arg_forward` combines pointer-callee `%rax`
  calls with 64-bit register moves plus outgoing stack argument forwarding.
- selected indirect register aggregate rows in `frontier_sysv_abi.zig` and
  `frontier_sysv_aggregate_classes.zig`: `frontier_indirect_pair64_make` and
  `frontier_indirect_pair64_first` prove INTEGER/INTEGER aggregate return and
  argument forwarding through function pointers,
  `frontier_indirect_nested_pair_sum` and
  `frontier_indirect_array_pair_sum` prove nested and array-in-struct
  INTEGER/INTEGER aggregate argument forwarding through the same pointer-callee
  planner path, while
  `frontier_indirect_array_double_make` and
  `frontier_indirect_array_double_sum` prove the same `%rax` indirect-call path
  for SSE/SSE `[2]f64` aggregate return and argument forwarding.
- selected live-across-indirect-call row in `frontier_sysv_abi.zig`:
  `frontier_indirect_two_live_after_call` uses the same generic CFG
  spill/reload frame as direct calls while copying the pointer callee to `%rax`
  and assigning the scalar call argument through `%edi`.
- selected computed stack-passed scalar `i64` call argument in
  `frontier_sysv_abi.zig`: `frontier_computed_i64_stack_arg_call` computes a
  block-local `i64`, materializes it through `%rax`, and pushes it into the
  outgoing stack argument area through the same shared SysV scalar planner.
- selected pointer stack-argument forwarding in `frontier_sysv_abi.zig`:
  `frontier_ptr_stack_arg_forward` and
  `frontier_indirect_ptr_stack_arg_forward` pass eight pointer arguments through
  direct and function-pointer calls, proving pointer GPR assignment plus
  stack-passed pointer slots through executable C ABI checks.
- selected pointer return rows in `frontier_sysv_abi.zig`:
  `frontier_ptr_return_param`, `frontier_ptr_return_direct_call`, and
  `frontier_ptr_return_indirect_call` return pointer values through `%rax`
  from a parameter, a direct C ABI helper, and a function-pointer C ABI helper
  using the generic SysV GPR return path.
- selected full-width GPR argument shuffle rows in `frontier_sysv_abi.zig`:
  `frontier_i32_swapped_direct_call`, `frontier_i64_swapped_direct_call`,
  `frontier_ptr_swapped_direct_call`, `frontier_i32_swapped_indirect_call`,
  `frontier_i64_swapped_indirect_call`, and
  `frontier_ptr_swapped_indirect_call` prove two-register swaps; the
  `frontier_i32_three_cycle_direct_call` and
  `frontier_i64_three_cycle_direct_call` rows prove three-register
  permutations, and `frontier_i32_six_cycle_direct_call` proves the same
  scheduler across all six GPR argument registers. These rows use the generic
  push/pop parallel-copy scheduler for integer and pointer register-source call
  arguments across direct and function-pointer C ABI calls with executable
  checks.
- selected XMM call-argument permutations in `frontier_sysv_abi.zig`:
  `frontier_f32_swapped_direct_call`, `frontier_f64_swapped_direct_call`,
  `frontier_f32_swapped_indirect_call`, and
  `frontier_f64_swapped_indirect_call` snapshot source XMM registers to
  temporary stack slots, reload the outgoing SSE argument registers, and
  restore `%rsp` before direct or function-pointer calls through the shared
  SysV scalar call planner.
- selected multi-call live-value frame in `frontier_sysv_abi.zig`:
  `frontier_two_void_calls_six_live` keeps six live GPR `i32` values across two
  void C ABI calls through the generic CFG live-param spill/reload helper;
  `frontier_two_indirect_void_calls_six_live` proves the same frame path around
  two pointer-callee `callq *%rax` calls.
  `frontier_two_void_calls_two_f32_live_sum` and
  `frontier_two_void_calls_two_f64_live_sum` keep two live FP values across two
  direct no-argument `void` calls through the same FP live-addend frame helper
  used by the single-call rows; `frontier_two_indirect_void_calls_two_f32_live_sum`
  and `frontier_two_indirect_void_calls_two_f64_live_sum` prove the same shape
  for repeated function-pointer calls by preserving and reloading the pointer
  callee from the frame before each `callq *%rax`.
  `frontier_mixed_i32_f32_live_sum_after_call`,
  `frontier_mixed_i32_f64_live_sum_after_call`,
  `frontier_indirect_mixed_i32_f32_live_sum_after_call`, and
  `frontier_indirect_mixed_i32_f64_live_sum_after_call` spill an integer GPR
  and one SSE parameter across direct and pointer-callee `void` calls, reload
  the integer through `%edi`, convert it with `sitofp`, and add the preserved
  FP value. `frontier_mixed_i64_f32_live_sum_after_call`,
  `frontier_mixed_i64_f64_live_sum_after_call`,
  `frontier_indirect_mixed_i64_f32_live_sum_after_call`, and
  `frontier_indirect_mixed_i64_f64_live_sum_after_call` use the same frame with
  64-bit GPR spill/reload and `%rdi` int-to-FP conversion.
  `frontier_two_void_calls_mixed_i32_f32_live_sum`,
  `frontier_two_void_calls_mixed_i32_f64_live_sum`,
  `frontier_two_void_calls_mixed_i64_f32_live_sum`,
  `frontier_two_void_calls_mixed_i64_f64_live_sum`,
  `frontier_two_indirect_void_calls_mixed_i32_f32_live_sum`, and
  `frontier_two_indirect_void_calls_mixed_i32_f64_live_sum`,
  `frontier_two_indirect_void_calls_mixed_i64_f32_live_sum`, and
  `frontier_two_indirect_void_calls_mixed_i64_f64_live_sum` extend that same
  mixed GPR/SSE frame to two direct or pointer-callee `void` calls with 32-bit
  and 64-bit integer live values.
- selected ordered call-result live frame in `frontier_sysv_abi.zig`:
  `frontier_call_result_live_across_second_call` spills the first C ABI
  `i32` call result from `%eax`, preserves the live `i32` parameter in a frame
  slot, emits a later side-effecting `void` C ABI call in source order, reloads
  the first result, and returns the post-call add. The executable harness uses
  an order-sensitive helper state to prove the first call is not moved after
  the second call.
- selected two-result ordered call frame in `frontier_sysv_abi.zig`:
  `frontier_two_i32_results_across_calls` keeps the first C ABI `i32` call
  result in a frame slot while the second C ABI `i32` call receives its own
  planned scalar argument and returns through `%eax`; the backend then adds the
  first result and the saved live parameter after the second call. The harness
  uses ordered helpers to prove both calls execute in source order and both
  call results are used.
- selected indirect two-result ordered call frame in `frontier_sysv_abi.zig`:
  `frontier_two_i32_results_across_indirect_call`,
  `frontier_indirect_first_two_i32_results_across_calls`, and
  `frontier_indirect_both_two_i32_results_across_calls` route the first ordered
  call, second ordered call, or both ordered calls through function pointer
  targets, preserve the second pointer callee and its `i32` argument across the
  first ordered `i32` call when needed, and use the SysV planner for `callq
  *%rax` argument/return before combining both call results with the saved live
  parameter.
- selected two-result live-across-later-call frame in `frontier_sysv_abi.zig`:
  `frontier_two_i32_results_live_across_void_call` preserves two ordered C ABI
  `i32` call results and the live `i32` parameter across a later side-effecting
  `void` call, then reloads both saved results from frame slots for the final
  add tree.
- selected indirect two-result live-across-later-call frame in
  `frontier_sysv_abi.zig`:
  `frontier_two_i32_results_live_across_indirect_void_call` preserves the later
  `void` pointer callee across both ordered `i32` calls in a 64-bit frame slot,
  reloads it before `callq *%rax`, then reloads both saved `i32` results for
  the final add tree.
- selected indirect-first two-result live-across-later-call frame in
  `frontier_sysv_abi.zig`:
  `frontier_indirect_first_i32_result_live_across_void_call`,
  `frontier_indirect_second_i32_result_live_across_void_call`, and
  `frontier_indirect_both_i32_results_live_across_indirect_void_call` route the
  first ordered call, second ordered call, or both ordered calls through
  function pointer targets, preserve any later pointer-callee `void` call in a
  non-overlapping 64-bit frame slot, then reload both saved `i32` results for
  the final add tree.
- selected FP call-result live-across-later-call frames in
  `frontier_sysv_abi.zig`:
  `frontier_f64_result_live_across_void_call`,
  `frontier_f64_result_live_across_indirect_void_call`,
  `frontier_indirect_f64_result_live_across_void_call`,
  `frontier_indirect_f64_result_live_across_indirect_void_call`,
  `frontier_f32_result_live_across_void_call`,
  `frontier_f32_result_live_across_indirect_void_call`,
  `frontier_indirect_f32_result_live_across_void_call`, and
  `frontier_indirect_f32_result_live_across_indirect_void_call` spill a direct
  or pointer-callee C ABI `float` or `double` call result from `%xmm0`,
  preserve the live FP addend, emit a later direct or pointer-callee
  side-effecting `void` call, then reload both XMM frame slots for the final
  post-call `fadd` return.
- selected two-result FP call frames in `frontier_sysv_abi.zig`:
  `frontier_two_f64_results_across_calls`,
  `frontier_two_f32_results_across_calls`,
  `frontier_indirect_first_f64_results_across_calls`,
  `frontier_indirect_first_f32_results_across_calls`,
  `frontier_indirect_second_f64_results_across_calls`, and
  `frontier_indirect_second_f32_results_across_calls` spill the first C ABI
  `float` or `double` call result across a second direct or pointer-callee FP
  result call, preserve the second call's FP argument and pointer callee when
  needed, then reload the first result for the final `fadd`.
- selected two-result `i64` call frames in `frontier_sysv_abi.zig`:
  `frontier_two_i64_results_across_calls`,
  `frontier_indirect_first_i64_results_across_calls`,
  `frontier_indirect_second_i64_results_across_calls`, and
  `frontier_indirect_both_i64_results_across_calls` spill the first C ABI
  `i64` result to a frame slot, preserve a later pointer callee when needed,
  lower both calls through the SysV scalar planner, add the saved stack value
  back into `%rax`, and return the combined `i64` result.
- selected two-result `i64` call frames with live addend in
  `frontier_sysv_abi.zig`: `frontier_two_i64_results_with_live_across_calls`,
  `frontier_indirect_first_i64_results_with_live_across_calls`,
  `frontier_indirect_second_i64_results_with_live_across_calls`, and
  `frontier_indirect_both_i64_results_with_live_across_calls` preserve the
  first `%rax` result, the second call's live argument, the second pointer
  callee when needed, and an independent live `i64` addend across both
  non-void calls before returning the three-value sum.
- selected i64 result live-across-void frames in `frontier_sysv_abi.zig`:
  `frontier_i64_result_live_across_void_call`,
  `frontier_i64_result_live_across_indirect_void_call`,
  `frontier_indirect_i64_result_live_across_void_call`, and
  `frontier_indirect_i64_result_live_across_indirect_void_call` spill the live
  `i64` addend and any later pointer callee before the first result call,
  reload the saved `%rax` result after the side-effecting `void` call, and
  finish the add through the same SysV target/planner path.
- selected two-result i64 live-across-later-void frames in
  `frontier_sysv_abi.zig`:
  `frontier_two_i64_results_live_across_void_call`,
  `frontier_two_i64_results_live_across_indirect_void_call`,
  `frontier_indirect_first_two_i64_results_live_across_void_call`,
  `frontier_indirect_second_two_i64_results_live_across_void_call`, and
  `frontier_indirect_both_two_i64_results_live_across_indirect_void_call` spill
  the second call's live argument before the first call, preserve pointer
  callees for the second result and later `void` call when needed, save both
  `i64` results in aligned frame slots, then reload and add those saved `%rax`
  results after a later direct or pointer-callee `void` call.
- selected two-result i64 live-addend-across-later-void frames in
  `frontier_sysv_abi.zig`:
  `frontier_two_i64_results_with_live_across_void_call`,
  `frontier_two_i64_results_with_live_across_indirect_void_call`,
  `frontier_indirect_first_two_i64_results_with_live_across_void_call`,
  `frontier_indirect_second_two_i64_results_with_live_across_void_call`, and
  `frontier_indirect_both_two_i64_results_with_live_across_indirect_void_call`
  reuse the same two-result/later-void lowering path while also spilling an
  independent live `i64` addend across both non-void calls and the final direct
  or pointer-callee `void` call before producing the three-value sum.
- selected mixed integer/FP non-void result frames in `frontier_sysv_abi.zig`:
  `frontier_mixed_i64_f64_results_across_calls`,
  `frontier_mixed_indirect_first_i64_f64_results_across_calls`,
  `frontier_mixed_indirect_second_i64_f64_results_across_calls`, and
  `frontier_mixed_indirect_both_i64_f64_results_across_calls` preserve a later
  `double` argument and optional second pointer callee across the first `i64`
  result call, save `%rax`, run the later `double` result call, convert the
  saved integer result with `sitofp`, and return the mixed `double` sum.
  `frontier_mixed_i64_f32_results_across_calls`,
  `frontier_mixed_indirect_first_i64_f32_results_across_calls`,
  `frontier_mixed_indirect_second_i64_f32_results_across_calls`, and
  `frontier_mixed_indirect_both_i64_f32_results_across_calls` cover the same
  ordered integer/FP result shape when the later FP result is `float` and must
  be extended before the final `double` add.
  `frontier_mixed_f64_i64_results_across_calls`,
  `frontier_mixed_indirect_first_f64_i64_results_across_calls`,
  `frontier_mixed_indirect_second_f64_i64_results_across_calls`, and
  `frontier_mixed_indirect_both_f64_i64_results_across_calls` prove the
  mirrored order: save the first `double` result, preserve the later `i64`
  argument and optional second pointer callee, run the `i64` result call,
  convert `%rax` with `sitofp`, and add it to the saved `double`.
  `frontier_mixed_f32_i64_results_across_calls`,
  `frontier_mixed_indirect_first_f32_i64_results_across_calls`,
  `frontier_mixed_indirect_second_f32_i64_results_across_calls`, and
  `frontier_mixed_indirect_both_f32_i64_results_across_calls` cover the same
  later `i64` result shape when the first FP result is `float` and must be
  extended before the final `double` add.
- selected mixed-width FP call-result frames in `frontier_sysv_abi.zig`:
  `frontier_mixed_f32_f64_results_across_calls`,
  `frontier_mixed_indirect_first_f32_f64_results_across_calls`,
  `frontier_mixed_indirect_second_f32_f64_results_across_calls`,
  `frontier_mixed_indirect_both_f32_f64_results_across_calls`,
  `frontier_mixed_f64_f32_results_across_calls`,
  `frontier_mixed_indirect_first_f64_f32_results_across_calls`,
  `frontier_mixed_indirect_second_f64_f32_results_across_calls`, and
  `frontier_mixed_indirect_both_f64_f32_results_across_calls` spill the first
  FP call result, preserve the later FP call argument and pointer callee when
  needed, extend the `float` result with `cvtss2sd`, and return the final
  `double` add.
- selected mixed-width FP call-result frames with live addend in
  `frontier_sysv_abi.zig`:
  `frontier_mixed_f32_f64_results_with_live_across_calls`,
  `frontier_mixed_indirect_first_f32_f64_results_with_live_across_calls`,
  `frontier_mixed_indirect_second_f32_f64_results_with_live_across_calls`, and
  `frontier_mixed_indirect_both_f32_f64_results_with_live_across_calls`, plus
  the reversed `frontier_mixed_f64_f32_results_with_live_across_calls`,
  `frontier_mixed_indirect_first_f64_f32_results_with_live_across_calls`,
  `frontier_mixed_indirect_second_f64_f32_results_with_live_across_calls`, and
  `frontier_mixed_indirect_both_f64_f32_results_with_live_across_calls`, plus
  `frontier_mixed_f32_f64_results_with_i64_live_across_calls`,
  `frontier_mixed_indirect_first_f32_f64_results_with_i64_live_across_calls`,
  `frontier_mixed_indirect_second_f32_f64_results_with_i64_live_across_calls`,
  and
  `frontier_mixed_indirect_both_f32_f64_results_with_i64_live_across_calls`,
  plus the reversed
  `frontier_mixed_f64_f32_results_with_i64_live_across_calls`,
  `frontier_mixed_indirect_first_f64_f32_results_with_i64_live_across_calls`,
  `frontier_mixed_indirect_second_f64_f32_results_with_i64_live_across_calls`,
  and
  `frontier_mixed_indirect_both_f64_f32_results_with_i64_live_across_calls`,
  plus
  `frontier_mixed_f32_f64_results_with_f32_live_across_calls`,
  `frontier_mixed_indirect_first_f32_f64_results_with_f32_live_across_calls`,
  `frontier_mixed_indirect_second_f32_f64_results_with_f32_live_across_calls`,
  and
  `frontier_mixed_indirect_both_f32_f64_results_with_f32_live_across_calls`,
  plus the reversed
  `frontier_mixed_f64_f32_results_with_f32_live_across_calls`,
  `frontier_mixed_indirect_first_f64_f32_results_with_f32_live_across_calls`,
  `frontier_mixed_indirect_second_f64_f32_results_with_f32_live_across_calls`,
  and
  `frontier_mixed_indirect_both_f64_f32_results_with_f32_live_across_calls`
  preserve the later FP argument, any second pointer callee, the first FP
  result, and an independent live `double`, `float`, or `i64` addend across
  both non-void calls before producing the final three-value `double` sum. The
  `float` and `i64` addend rows reload the saved value after both calls and
  extend or convert it to `double` before the final add.
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
- selected stack-passed SSE live-across-call rows in `frontier_sysv_abi.zig`:
  `frontier_stack_f32_live_sum_after_call` and
  `frontier_stack_f64_live_sum_after_call` plus the
  `frontier_indirect_stack_*` pointer-callee variants and
  `frontier_two_void_calls_stack_*` repeated-direct variants and
  `frontier_two_indirect_void_calls_stack_*` repeated pointer-callee variants
  skip the first two XMM parameters, spill the six register-backed FP addends from `%xmm2..%xmm7`,
  preserve the repeated pointer callee in a non-overlapping frame slot,
  reload two additional stack-passed FP addends through adjusted incoming stack
  offsets after the no-argument helper call or calls, and return the
  eight-value post-call `fadd` sum
- ten-, twelve-, fourteen-, eighteen-, twenty-, and twenty-four-addend stack-passed SSE live-across-call
  rows in `frontier_sysv_abi.zig`: `frontier_ten_fp_live_stack_*`,
  `frontier_twelve_fp_live_stack_*`, `frontier_fourteen_fp_live_stack_*`,
  `frontier_eighteen_fp_live_stack_*`, `frontier_twenty_fp_live_stack_*`,
  `frontier_twenty_four_fp_live_stack_*`, and
  their indirect variants reuse the same generic addend collector with six
  spilled XMM addends plus up to eighteen
  incoming stack-passed FP addends across direct and pointer-callee no-argument
  `void` calls before the post-call `fadd` return
- selected FP-argument SSE live-across-call rows in `frontier_sysv_abi.zig`:
  two live `f32` or `f64` parameters are spilled, `%xmm1` is assigned to the
  helper's first FP argument, and both live values are reloaded for the
  post-call `fadd` return; the `frontier_fp_arg_call_stack_*` and
  `frontier_indirect_fp_arg_call_stack_*` rows extend the same helper-call
  argument setup to six spilled XMM addends plus two stack-passed addends
  across direct and function-pointer one-FP-argument `void` calls before the
  post-call `fadd` return; the `frontier_nine_fp_arg_call_live_*` direct and
  indirect rows also prove aligned-frame cleanup for a `void` helper call with
  a ninth FP argument passed on the stack while live FP values are preserved
  across the call; the `frontier_nine_fp_arg_call_stack_*` direct and indirect
  rows combine both forms by preserving six spilled XMM addends and two
  incoming stack-passed addends while the helper's ninth FP argument is also
  passed through the outgoing stack area
- selected FP-result live-across-stack-argument rows in `frontier_sysv_abi.zig`:
  `frontier_f64_result_live_across_const_stack_arg_call` and
  `frontier_f32_result_live_across_const_stack_arg_call` spill the first
  direct FP call result, while
  `frontier_f64_result_live_across_indirect_const_stack_arg_call` and
  `frontier_f32_result_live_across_indirect_const_stack_arg_call` preserve the
  function-pointer callee for the same second-call shape. All four rows emit a
  second FP-result helper call with eight constant XMM arguments plus a
  constant ninth outgoing stack argument, then reload the first result for the
  final `fadd`
- selected indirect SSE live-across-call rows in `frontier_sysv_abi.zig`: two
  live `f32` or `f64` parameters are spilled, the pointer callee is moved to
  `%rax`, `callq *%rax` is emitted for both no-argument and one-FP-argument
  helper shapes, and both live values are reloaded for the post-call `fadd`
  return
- selected three-/four-/six-live indirect SSE call rows in `frontier_sysv_abi.zig`:
  three, four, or six live `f32`/`f64` parameters are spilled, two, three, or
  five live values are assigned to the pointer callee's FP argument registers, and all
  live values are reloaded for the post-call `fadd` return
- selected named FP argument pass-through rows in `frontier_sysv_abi.zig`:
  five `f32` and five `f64` parameters are forwarded to external C ABI helpers
  through `%xmm0..%xmm4`; backend unit/object tests materialize immediate FP
  constants through `%xmm0..%xmm7`
- mixed integer-to-FP arithmetic rows in `frontier_mixed_numeric.zig`:
  `frontier_i32_to_f32_add`, `frontier_i32_to_f32_mul_add`, and
  `frontier_i32_to_f64_mul_add` lower typed AIR v2 `sitofp` plus `fadd` or
  `fmul`/`fadd` pipelines through the generic CFG FP path, including `mulss`
  and `mulsd` codegen, and executable probes validate the exact C ABI results
- guard-return safety-edge rows in `frontier_safety_edges.zig`:
  `frontier_guard_return_else` lowers typed AIR v2 branch-return/continue CFG
  directly through generic CFG codegen, using a strict unsigned i64 guard and
  the dynamic pointer indexed-load path; executable probes validate both the
  loaded result and equality/out-of-bounds `-1` return path
- runtime/safety-edge rows in `frontier_safety_edges.zig`:
  `frontier_checked_uadd`, `frontier_bounds_direct`,
  `frontier_optional_unwrap`, and `frontier_int_from_float_checked` now remain
  typed-v2/generic-CFG owned across ReleaseFast, ReleaseSafe, and ReleaseSmall.
  The optional unwrap row uses the generic optional-pointer null/panic edge;
  the integer-conversion row uses the checked int-from-float guard plus
  `integerPartOutOfBounds` noreturn call in safe modes.

Remaining measured frontier blockers kept out of accepted rows:

- private helper call graphs with stack-passed live values beyond the current
  selected direct-call/void-call model, live SSE values beyond the selected no-argument-call
  spill shapes and selected direct two-/three-/six-live FP-argument call shapes,
  and arbitrary mixed/non-void live values
  across multiple calls beyond the selected direct/indirect/later-void,
  indirect-later-void, and indirect-first ordered `i32` result rows
- broader unknown aggregate field, pointer arithmetic, and global/TLS address
  forms outside the selected scalar layouts
- full SysV aggregate lowering beyond planner-owned register aggregate and
  normal MEMORY aggregate by-value argument assignment, selected INTEGER/INTEGER, nested
  INTEGER add chains plus nested construction returns, nested mixed INTEGER/SSE field reads/construction, selected
  mixed INTEGER/SSE and SSE/INTEGER low/high `i32`, `i64`, and `double` field
  reads/returns plus selected packed mixed construction returns, SSE/SSE field
  reads/returns including single-eightbyte `{ f32, f32 }` direct/shifted/indirect
  call pass-through, `[2]f64`
  array-in-struct, and nested `{ { double }, { double } }`, selected
  stack-passed register aggregate field reads, and generated
  normal MEMORY aggregate sret/byval field/copy forms currently proven
  through thirty-two flat fields, a nested two-Big3 aggregate, mixed-width
  `{ i64, i32, i64, i32 }` and `{ i8, { i16, i32 }, i64 }` copies,
  array-backed `{ [5 x i64] }` copy/read rows,
  a `double`-leaf copy, a mixed pointer/`double`/`i64` copy, and the
  `ScalarMixed`/`ScalarNested`/`ScalarArray` direct scalar-param sret make
  rows plus direct and pointer-callee `ScalarMixed`/`ScalarNested`/`ScalarArray`
  byval-to-sret copy rows;
  explicit `ptr byval(...)` calls now include single-`i8`, single-`i16`,
  single-`i32`, and `[3 x i32]` tail stack-copy proof, while source-owned
  MEMORY byval-to-sret rows now include `[17 x i8]`, `[21 x i8]`,
  `[22 x i8]`, `[23 x i8]`, and `[9 x i16]` byte-/word-tail copies through
  direct and pointer-callee calls; the 21/22/23-byte rows prove composite
  5-/6-/7-byte final stack-copy tails are byte-composed and zero-padded
  instead of rejected. Supported
  `ptr sret(...)` call arguments now use the normal GPR hidden-result-pointer
  planner path; X87,
  packed/unaligned aggregate ABI classes,
  arbitrary non-selected sret/byval copies, varargs, vectors, more than six
  stack-passed live values, and broader SSE live-across-call frames beyond the
  selected one-live through six-live `f32`/`f64` no-argument-call shapes,
  selected direct two-/three-/six-live FP-argument call shapes, selected
  stack-passed `f32`/`f64` addend sums after no-argument calls, selected
  direct/pointer-callee f32/f64 result live-across-later constant-stack-argument FP call frames, selected
  two-live repeated no-argument direct and pointer-callee call shapes, selected
  mixed one-GPR/one-SSE live direct and pointer-callee call shapes, selected
  one-FP-argument pointer-callee call shapes, selected three-/four-/six-live
  two-/three-/five-FP-argument pointer-callee call shapes, and selected named
  `%xmm0..%xmm4` pass-through calls

These blockers are the next local frontier backlog. They are not accepted rows
and do not use case IDs, wrapper maps, source tags, legacy AIR text lowering,
shape recognizers, LLVM TargetMachine, LLVM optimizer, or LLD.
