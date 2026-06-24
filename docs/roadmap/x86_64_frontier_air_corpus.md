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
discovered_functions=226
structured_functions=226
generic_codegen_functions=226
generic_cfg_functions=226
structural_matcher_functions=0
structured_air_v2_functions=226
typed_air_operand_functions=226
legacy_air_text_lowering_functions=0
typed_v2_fallback_functions=0
generic_lowering_functions=226
shape_recognizer_functions=0
unsupported_functions=0
codegen_failures=0
object_emitted_functions=226
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
  using layout-derived byte offsets, including the flat twenty-field BigN row,
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
  construction, field-read, and byval-to-sret copy rows; the `BigDouble` row
  adds the first double-leaf MEMORY byval-to-sret copy proof through XMM
  `movsd` stack loads and hidden-sret stores, the `BigPtrDouble` row proves the
  same layout-derived copy path for pointer, `double`, and `i64` leaves in one
  MEMORY aggregate, and `BigFloat` proves five `f32` leaves through dedicated
  `movss` stack loads and hidden-sret stores; `frontier_direct_big5_copy`,
  `frontier_indirect_big5_copy`, `frontier_direct_big_double_copy`,
  `frontier_indirect_big_double_copy`, `frontier_direct_big_float_copy`,
  `frontier_indirect_big_float_copy`,
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
  GPR aggregate slots, and `frontier_stack_mixed_call_int` forwards a
  stack-passed `{ i64, double }` mixed aggregate by loading the INTEGER
  eightbyte into the outgoing GPR stream and the SSE eightbyte into `%xmm0`;
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
  leading scalar call arguments reuse `%rdi`/`%rsi`
- first array-in-struct SSE/SSE aggregate row in
  `frontier_sysv_aggregate_classes.zig`: `[2]f64` field and pointer-element
  GEPs lower from typed AIR v2, the two `double` elements are read from the
  independent SysV SSE argument stream, and construction returns the elements
  in `%xmm0`/`%xmm1`; `frontier_register_array_double_call_sum_after_eight`
  proves register-sourced SSE/SSE aggregate stack forwarding after the callee
  SSE stream is exhausted by eight leading scalar `double` arguments
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
  `i32` parameters are spilled/reloaded around a direct helper call while more
  than six stack-passed `i32` parameters are read from the restored incoming
  stack argument area for the post-call add-tree return; current executable
  rows prove seven, eight, twelve, thirteen, fourteen, and eighteen
  stack-passed live `i32` values within
  the backend's disp8-safe stack offset model
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
  six-argument helper call.
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
  argument forwarding through function pointers, while
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
- selected multi-call live-value frame in `frontier_sysv_abi.zig`:
  `frontier_two_void_calls_six_live` keeps six live GPR `i32` values across two
  void C ABI calls through the generic CFG live-param spill/reload helper;
  `frontier_two_indirect_void_calls_six_live` proves the same frame path around
  two pointer-callee `callq *%rax` calls.
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
  `frontier_two_i32_results_across_indirect_call` preserves the pointer callee
  and its `i32` argument across the first ordered `i32` call, reloads the
  pointer callee through the shared 64-bit frame spill/reload path, and uses the
  SysV planner for the second `callq *%rax` argument/return before combining
  both call results with the saved live parameter.
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
  `frontier_indirect_first_i32_result_live_across_void_call` routes the first
  ordered `i32` call through a function pointer target, then preserves the
  second ordered result and later side-effecting `void` call sequence through
  the same generic SysV call-target and frame spill/reload path.
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

Remaining measured frontier blockers kept out of accepted rows:

- private helper call graphs with stack-passed live values beyond the current
  disp8-safe selected model, live SSE values beyond the selected no-argument-call spill shapes and
  two-live FP-argument call shape, and arbitrary mixed/non-void live values
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
  through twenty flat fields, a nested two-Big3 aggregate, mixed-width
  `{ i64, i32, i64, i32 }` and `{ i8, { i16, i32 }, i64 }` copies,
  array-backed `{ [5 x i64] }` copy/read rows,
  a `double`-leaf copy, and a mixed pointer/`double`/`i64` copy; X87,
  packed/unaligned aggregate ABI classes,
  arbitrary non-selected sret/byval copies, varargs, vectors, more than six
  stack-passed live values, and broader SSE live-across-call frames beyond the
  selected one-live through six-live `f32`/`f64` no-argument-call shapes,
  two-live FP-argument call shape, selected two-live no-argument and
  one-FP-argument pointer-callee call shapes, selected three-/four-/six-live
  two-/three-/five-FP-argument pointer-callee call shapes, and selected named
  `%xmm0..%xmm4` pass-through calls

These blockers are the next local frontier backlog. They are not accepted rows
and do not use case IDs, wrapper maps, source tags, legacy AIR text lowering,
shape recognizers, LLVM TargetMachine, LLVM optimizer, or LLD.
