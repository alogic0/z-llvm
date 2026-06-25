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
discovered_functions=449
structured_functions=449
generic_codegen_functions=449
generic_cfg_functions=449
structural_matcher_functions=0
structured_air_v2_functions=449
typed_air_operand_functions=449
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_lowering_functions=449
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
object_emitted_functions=449
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
  `ScalarArray` follow-up now also proves direct and pointer-callee
  byval-to-sret copies for mixed array-contained integer leaves, array-contained
  double leaves, and a pointer leaf through the same layout-derived MEMORY copy
  path; the
  `BigDouble` row
  adds the first double-leaf MEMORY byval-to-sret copy proof through XMM
  `movsd` stack loads and hidden-sret stores, the `BigPtrDouble` row proves the
  same layout-derived copy path for pointer, `double`, and `i64` leaves in one
  MEMORY aggregate, `BigFloat` proves five `f32` leaves through dedicated
  `movss` stack loads and hidden-sret stores, and `BigDoubleArray` proves an
  array-of-double MEMORY aggregate through the same recursive copy path; the
  `BigArrayMixed` row combines array-contained `i32`, array-contained `f64`,
  and pointer leaves in one byval-to-sret MEMORY aggregate; `Big32` and
  `Big40` raise the same planner-owned byval-to-sret direct and pointer-callee
  copy path through exact-qword MEMORY payloads beyond byte-offset byval loads
  using disp32 source-pointer reloads; the stack-sourced `Big40` direct and
  pointer-callee copy rows prove incoming byval payloads that begin in the
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
  INTEGER and SSE stack eightbytes;
  `frontier_shifted_mixed_call_int` now proves in-register aggregate
  pass-through can move a shifted INTEGER eightbyte from `%rsi` to `%rdi`
  before the helper call instead of requiring exact source/destination slots
- first SSE/SSE aggregate class row in
  `frontier_sysv_aggregate_classes.zig`: `{ double, double }` is classified as
  SSE/SSE, field reads return from the independent SSE argument stream, and
  construction returns the aggregate in `%xmm0`/`%xmm1`; `{ f32, f32 }` is
  classified as one SSE eightbyte, returns low/high f32 lanes from `%xmm0`, and
  constructs the packed f32 pair return through the same generic aggregate
  return path. The f32 pair follow-up forwards the same single-eightbyte SSE
  aggregate through direct, shifted, and pointer-callee helper calls, and the
  helper body adds both f32 fields through generic aggregate field-add
  lowering. The `frontier_stack_array_double_call_sum` row forwards a stack-passed SSE/SSE
  `[2]f64` aggregate into a private helper by loading the source stack
  eightbytes into outgoing XMM aggregate slots
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
  executable C ABI checks
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
  path
  a private helper call using the same register aggregate pass-through helper
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
  `frontier_mixed_indirect_both_f64_f32_results_with_i64_live_across_calls`
  preserve the later FP argument, any second pointer callee, the first FP
  result, and an independent live `double` or `i64` addend across both non-void
  calls before producing the final three-value `double` sum. The `i64` addend
  rows reload the saved GPR value after both calls and convert it to `double`
  before the final add.
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
- selected FP-argument SSE live-across-call rows in `frontier_sysv_abi.zig`:
  two live `f32` or `f64` parameters are spilled, `%xmm1` is assigned to the
  helper's first FP argument, and both live values are reloaded for the
  post-call `fadd` return
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
  rows plus direct and pointer-callee `ScalarArray` byval-to-sret copy rows;
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
  two-live repeated no-argument direct and pointer-callee call shapes, selected
  mixed one-GPR/one-SSE live direct and pointer-callee call shapes, selected
  one-FP-argument pointer-callee call shapes, selected three-/four-/six-live
  two-/three-/five-FP-argument pointer-callee call shapes, and selected named
  `%xmm0..%xmm4` pass-through calls

These blockers are the next local frontier backlog. They are not accepted rows
and do not use case IDs, wrapper maps, source tags, legacy AIR text lowering,
shape recognizers, LLVM TargetMachine, LLVM optimizer, or LLD.
