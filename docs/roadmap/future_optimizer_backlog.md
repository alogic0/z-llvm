# Future Optimizer Backlog

This file holds optional follow-up work after the completed finish burn-down
for replacing Zig's LLVM library dependency. It is not an active roadmap.
Promote one item only after selecting a concrete source-backed fixture,
opt-22 delta, or readiness-gate failure.

The current finish state has no active source-backed blocker:

```text
manifest rows=40
optimizer_input=33
unsupported=0
future=4
debug-info-only=0
```

The four future rows are explicit boundaries, not unowned blockers:

```text
tiny_scalar_debug: future
tiny_scalar_release_safe: future
tiny_scalar_release_small: future
vector_future_release_fast: parse,verify,future
```

Latest accepted-pipeline freshness sweep:

```text
tmp/zig_ir/continuous_20260530_151319_debug
  mode=Debug
  passes=zig-debug-accepted
  processed=1474 emit_ok=465 local_ok=465
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0

tmp/zig_ir/continuous_20260530_151319_releasefast
  mode=ReleaseFast
  passes=zig-release-fast-accepted
  processed=1474 emit_ok=465 local_ok=465
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0

tmp/zig_ir/continuous_20260530_151319_releasesafe
  mode=ReleaseSafe
  passes=zig-release-safe-accepted
  processed=1474 emit_ok=465 local_ok=465
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0

tmp/zig_ir/continuous_20260530_151319_releasesmall
  mode=ReleaseSmall
  passes=zig-release-small-accepted
  processed=1474 emit_ok=465 local_ok=465
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0
```

No backlog item is promoted from this sweep because it found no measured
source-backed blocker, no opt-22 mismatch, and no readiness-gate failure.

Latest x86_64 accepted optimizer refresh after the SimplifyCFG common-code
hoist follow-up:

```text
tmp/zig_ir/accepted_20260530_193848_releasefast
  local_commit=d35c341
  mode=ReleaseFast
  target=x86_64-linux-gnu
  passes=zig-release-fast-accepted
  summary=tmp/zig_ir/accepted_20260530_193848_releasefast/summary.txt
  processed=1474 compile_skip=1009 emit_ok=465 local_ok=465
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0

tmp/zig_ir/accepted_20260530_195245_releasesafe
  local_commit=d35c341
  mode=ReleaseSafe
  target=x86_64-linux-gnu
  passes=zig-release-safe-accepted
  summary=tmp/zig_ir/accepted_20260530_195245_releasesafe/summary.txt
  processed=1474 compile_skip=1009 emit_ok=465 local_ok=465
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0

tmp/zig_ir/accepted_20260530_201347_releasesmall
  local_commit=d35c341
  mode=ReleaseSmall
  target=x86_64-linux-gnu
  passes=zig-release-small-accepted
  summary=tmp/zig_ir/accepted_20260530_201347_releasesmall/summary.txt
  processed=1474 compile_skip=1009 emit_ok=465 local_ok=465
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0
```

ReleaseFast remains the primary optimizer replacement row. ReleaseSafe was
refreshed only because SimplifyCFG can affect safety/runtime-call CFG shapes,
and ReleaseSmall was refreshed as milestone evidence. Debug remains optional
for this refresh because no debug metadata or O0 behavior changed. The refreshed
ReleaseFast, ReleaseSafe, and ReleaseSmall discovery artifacts did not capture
optimized output for canonical-form comparison; they prove only that no new
failing source row appeared under the accepted pipelines. Under the focused
validation policy, no handoff/codegen gate was promoted. The four future rows
above are reaffirmed as boundaries; no new evidence changes their status, and
no implementation slice is promoted.

Optimized-output capture is now available through
`tools/zig_corpus_discovery.zig --capture-optimized-output`. The focused
ReleaseFast CFG-sensitive baseline is:

```text
tmp/zig_ir/optimized_cfg_releasefast_20260530
  mode=ReleaseFast
  target=x86_64-linux-gnu
  passes=zig-release-fast-accepted
  processed=11 compile_skip=0 emit_ok=11 local_ok=11
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0
  optimized_output=tmp/zig_ir/optimized_cfg_releasefast_20260530/optimized-ir
```

No prior optimized-output artifact directory existed for a historical diff, so
this baseline does not promote a handoff/codegen gate by itself.

Milestone 1 for `ReleaseFast / x86_64-linux-gnu / asm-object` records a
conservative boundary for the selected Zig-backed object subset in
`docs/roadmap/releasefast_x86_64_object_milestone_1.md`. The broader captured
ReleaseFast object probe over
`tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir` now succeeds for
all 17 rows, including the selected `aggregate_abi`, `aggregates`,
`atomics_inline_asm_debug`, `control_flow_calls`, `error_switch`,
floating-point, globals, integer, pointer/memory, switch, and local-exec TLS
shapes.

The next measured object row is ReleaseSafe. The bounded capture
`tmp/zig_ir/distribution_m2_releasesafe_20260530/optimized-ir` has 17 optimizer
successes. Object probing with `--input-limit=67108864` originally found 8
successes and 9 failures. The selected
`aggregates.zig.ReleaseSafe.x86_64.optimized.ll` blocker is now object-ok for
the checked aggregate sum aliases. The current probe is 9 successes and 8
failures. The selected
`atomics_inline_asm_debug.zig.ReleaseSafe.x86_64.optimized.ll` blocker is now
object-ok for the checked `@debug_location` alias and the already covered
inline-asm/atomic aliases. The current probe is 10 successes and 7 failures.
The selected `control_flow_calls.zig.ReleaseSafe.x86_64.optimized.ll` blocker
is now object-ok for checked `@loop_sum` and guarded `@call_chain`. The current
probe is 11 successes and 6 failures. The selected
`error_switch.zig.ReleaseSafe.x86_64.optimized.ll` blocker is now object-ok for
straight-line `@error_switch` `icmp`/`select` lowering. The current probe is 12
successes and 5 failures. The first sorted blocker is
`globals_comptime.zig.ReleaseSafe.x86_64.optimized.ll`, selected
`@comptime_const` checked multiply-by-constant and panic-edge lowering. That
blocker is now object-ok for `@comptime_const`, `@update_global`, and
`@read_global`. The current probe is 13 successes and 4 failures. The first
sorted blocker is `pointers_memory.zig.ReleaseSafe.x86_64.optimized.ll`,
selected `@load_store` checked pointer load/add/store and panic-edge lowering.
That blocker is now object-ok for `@load_store`. The current probe is 14
successes and 3 failures. The first sorted blocker is
`switch_control.zig.ReleaseSafe.x86_64.optimized.ll`, selected `@branch_mix`
checked add-or-sub branch phi and panic-edge lowering. That blocker is now
object-ok for `@branch_mix` and the already covered `@dense_switch`. The
current probe is 15 successes and 2 failures. The first sorted blocker is
`tiny_scalar.zig.ReleaseSafe.x86_64.optimized.ll`, selected `@add` checked
scalar add and panic-edge lowering. That blocker is now object-ok for `@add`
and `@sideEffectFree`. The current probe is 16 successes and 1 failure. The
first sorted blocker is `tls_concurrency.zig.ReleaseSafe.x86_64.optimized.ll`,
selected `@bump_tls` checked local-exec TLS update and panic-edge lowering.
That blocker is now object-ok for `@bump_tls` and `@read_tls`. The ReleaseSafe
object probe is now clean at 17 successes and 0 failures, promoting
ReleaseSafe / x86_64-linux-gnu / asm-object to a conservative boundary for the
captured optimized-output object subset.

The next measured object row is ReleaseSmall. The bounded capture
`tmp/zig_ir/distribution_m3_releasesmall_20260531/optimized-ir` has 465
optimizer successes, 1009 Zig compile skips, and 0 local optimizer failures.
Object probing with `--input-limit=67108864` found 263 successes and 202
failures. The first sorted blocker is
`behavior_export_keyword.zig.ReleaseSmall.x86_64.optimized.ll`, selected
`@writeToVRam` volatile absolute-address store lowering. That blocker is now
object-ok for `@writeToVRam` and `@testPackedStuff`. The current ReleaseSmall
object probe is 264 successes and 201 failures. The first sorted blocker was
`behavior_sizeof_and_typeof.zig.ReleaseSmall.x86_64.optimized.ll`, selected
`@c_fopen` noreturn unreachable-stub lowering. That blocker is now object-ok
for `@c_fopen`, `@c_ftell`, `@c_fputs`, and `@c_printf`. The current
ReleaseSmall object probe is 265 successes and 200 failures. The first sorted
blocker is `c_abi_main.zig.ReleaseSmall.x86_64.optimized.ll`, selected
`@zig_f128_f128_struct` C ABI fp128 byval/sret lowering with `__eqtf2`
comparison calls and panic branches. That focused selected shape is now
object-ok. The broad `c_abi_main` row remains the first sorted blocker; the
next selected alias in that row is `@zig_f128_struct`, a C ABI fp128
aggregate-return shape with an `__eqtf2` guard and panic edge. The selected
`@zig_f128_struct` and adjacent `@zig_f128` scalar fp128 return shapes are now
object-ok in the focused ReleaseSmall gate. The broad row still remains the
first sorted blocker; the next selected alias is `@zig_assert_PD`, a mixed
integer/double assertion shape with stack local aggregate setup, floating-point
comparison, and a diagnostic failure edge. The selected return-code branch
behavior for `@zig_assert_PD` is now object-ok in the focused ReleaseSmall
gate, with diagnostic printing side effects explicitly outside the local
replacement boundary. The broad row still remains the first sorted blocker;
the next selected alias is `@zig_ret_PD`, a mixed integer/double aggregate
return. That focused shape is now object-ok. The broad row still remains the
first sorted blocker; the next selected alias is `@zig_ret_CFF`, a mixed
integer/float aggregate return. That focused shape is now object-ok. The broad
row still remains the first sorted blocker; the next selected alias is
`@zig_assert_CFF`, a mixed integer/float assertion shape with floating-point
comparison and diagnostic failure edge. The selected return-code branch
behavior for `@zig_assert_CFF` is now object-ok in the focused ReleaseSmall
gate, with diagnostic printing side effects explicitly outside the local
replacement boundary. The broad row still remains the first sorted blocker;
the next selected alias is `@zig_ret_DC`, a mixed double/integer aggregate
return. That focused shape is now object-ok. The broad row still remains the
first sorted blocker; the next selected alias is `@zig_assert_DC`, a mixed
double/integer assertion shape with floating-point comparison, low-byte integer
comparison, and diagnostic failure edge. The selected return-code branch
behavior for `@zig_assert_DC` is now object-ok in the focused ReleaseSmall
gate, with diagnostic printing side effects explicitly outside the local
replacement boundary. The broad row still remains the first sorted blocker;
the next selected alias is `@zig_ret_split_struct_mixed`, a two-register
aggregate return. That focused shape is now object-ok. The broad row still
remains the first sorted blocker; the next selected alias is
`@zig_ret_med_struct_mixed`, another two-register aggregate return with
different constant bit patterns. That focused shape is now object-ok. The
broad row still remains the first sorted blocker; the next selected alias is
`@zig_ret_med_struct_ints`, an integer aggregate return. That focused shape is
now object-ok. The broad row also advances past the adjacent existing
`@zig_ret_small_struct_ints` i32 return. The broad row still remains the first
sorted blocker; the next selected alias is `@zig_ret_i64`, a straight-line i64
return. That focused shape is now object-ok. The broad row also advances past
the adjacent existing `@zig_ret_i32` return. The broad row still remains the
first sorted blocker; the next selected alias is `@zig_ret_i16`, a
straight-line i16 return. That focused shape is now object-ok. The broad row
still remains the first sorted blocker; the next selected alias is
`@zig_ret_i8`, a straight-line i8 return. That focused shape is now object-ok.
The broad row still remains the first sorted blocker; the next selected alias
is `@zig_ret_u16`, a straight-line zero-extended u16 return. That focused
shape is now object-ok. The broad row still remains the first sorted blocker;
the next selected alias is `@zig_ret_u8`, a straight-line zero-extended u8
return. That focused shape is now object-ok. The broad row still remains the
first sorted blocker; the next selected alias is `@zig_ret_bool`, a
straight-line boolean return. That focused shape is now object-ok. The broad
row still remains the first sorted blocker; the next selected alias is
`@zig_multiple_struct_floats`, a vector-parameter floating comparison
control-flow shape. That focused shape is now object-ok with local trap
failure edges. The broad row still remains the first sorted blocker; the next
selected alias is `@zig_multiple_struct_ints`, a packed-integer comparison
control-flow shape.
That focused shape is now object-ok with local trap failure edges. The broad
row still remains the first sorted blocker; the next selected alias is
`@zig_big_struct_both`, a large byval/sret struct check-and-copy shape.
That focused shape is now object-ok with local trap failure edges and selected
sret stores. The broad row still remains the first sorted blocker; the next
selected alias is `@zig_split_struct_mixed`, a split mixed integer/float
comparison control-flow shape.
That focused shape is now object-ok with local trap failure edges and an exact
selected packed bit-pattern check. The broad row still remains the first
sorted blocker; the next selected alias is `@zig_split_struct_ints`, a split
integer struct comparison control-flow shape.
That focused shape is now object-ok with local trap failure edges and an exact
selected packed integer register payload check. The broad row still remains
the first sorted blocker; the next selected alias is
`@zig_big_packed_struct`, a packed i128 struct comparison control-flow shape.
That focused shape is now object-ok with local trap failure edges and selected
low/high register checks. The broad row still remains the first sorted
blocker; the next selected alias is `@zig_small_packed_struct`, a packed i8
struct comparison control-flow shape.
That focused shape is now object-ok with local trap failure edges and an exact
selected byte payload check. The broad row still remains the first sorted
blocker; the next selected alias is `@zig_med_struct_ints`, a medium integer
struct comparison control-flow shape.
That focused shape is now object-ok with local trap failure edges and selected
packed integer register checks. The broad row still remains the first sorted
blocker; the next selected alias is `@zig_small_struct_ints`, a small integer
struct comparison control-flow shape.
That focused shape is now object-ok with local trap failure edges and a
selected packed i32 payload check. The broad row still remains the first
sorted blocker; the next selected alias is `@zig_med_struct_mixed`, a medium
mixed struct comparison control-flow shape.
That focused shape is now object-ok with local trap failure edges and selected
packed mixed integer/float register checks. The broad row still remains the
first sorted blocker; the next selected alias is `@zig_big_union`, a byval
aggregate comparison control-flow shape.
That focused shape is now object-ok with local trap failure edges and selected
byval field-load checks. The broad row still remains the first sorted blocker;
the next selected alias is `@zig_big_struct`, a byval aggregate comparison
control-flow shape.
That focused shape is now object-ok with local trap failure edges and selected
byval field-load checks. The broad row still remains the first sorted blocker;
the next selected alias is `@zig_struct_i32_i32`, a packed i32 pair comparison
control-flow shape.
That focused shape is now object-ok with local trap failure edges and a
selected packed i32-pair register check. The broad row still remains the first
sorted blocker; the next selected alias is `@zig_struct_f32_f32f32`, a
vector/scalar float struct comparison control-flow shape.
That focused shape is now object-ok for both public aliases
`@zig_struct_f32_f32f32` and `@zig_struct_f32f32_f32` with local trap failure
edges and selected vector/scalar float register checks. The broad row still
remains the first sorted blocker; the next selected alias is
`@zig_ret_struct_f32_f32f32`, a vector/scalar float struct return shape.
That focused shape is now object-ok for both public aliases
`@zig_ret_struct_f32_f32f32` and `@zig_ret_struct_f32f32_f32` with selected
`%xmm0`/`%xmm1` return materialization. The broad row still remains the first
sorted blocker; the next selected alias is `@zig_struct_f32a8_f32a8`, a
vector/scalar float struct comparison control-flow shape.
That focused shape is now object-ok with local trap failure edges and selected
low-lane float register checks. The broad row still remains the first sorted
blocker; the next selected alias is `@zig_ret_struct_f32a8_f32a8`, a
vector/scalar float struct return shape.
That focused shape is now object-ok with selected `%xmm0`/`%xmm1` return
materialization while leaving the undef vector lane unconstrained. The broad
row still remains the first sorted blocker; the next selected alias is
`@zig_struct_f32a8`, a scalar float struct comparison control-flow shape.
That focused shape is now object-ok with local trap failure edges and selected
low-lane float register checks. The broad row still remains the first sorted
blocker; the next selected alias is `@zig_ret_struct_f32a8`, a scalar float
struct return shape.
That focused shape is now object-ok with selected `%xmm0` return
materialization. The broad row still remains the first sorted blocker; the
next selected alias is `@zig_struct_f64`, a scalar double struct comparison
control-flow shape.
That focused shape is now object-ok with local trap failure edges and a
selected scalar double register check. The broad row still remains the first
sorted blocker; the next selected alias is `@zig_ret_struct_f64`, a scalar
double struct return shape.
That focused shape is now object-ok with selected `%xmm0` return
materialization. The broad row still remains the first sorted blocker; the
next selected alias is `@zig_struct_f32`, a scalar float struct comparison
control-flow shape.
That focused shape is now object-ok with local trap failure edges and a
selected scalar float register check. The broad row still remains the first
sorted blocker; the next selected alias is `@zig_ret_struct_f32`, a scalar
float struct return shape.
That focused shape is now object-ok with selected `%xmm0` return
materialization. The broad row still remains the first sorted blocker; the
next selected alias is `@zig_struct_u64_u64_8`, a byval two-u64 struct
control-flow shape after eight leading integer arguments.
That focused shape is now object-ok with selected stack argument loads, byval
field loads, and local trap failure edges. The broad row still remains the
first sorted blocker; the next selected alias is `@zig_struct_u64_u64_7`, a
byval two-u64 struct control-flow shape after seven leading integer arguments.
That focused shape is now object-ok with selected stack argument loads, byval
field loads, and local trap failure edges. The broad row still remains the
first sorted blocker; the next selected alias is `@zig_struct_u64_u64_6`, a
byval two-u64 struct control-flow shape after six leading integer arguments.
That focused shape is now object-ok with selected stack argument loads, byval
field loads, and local trap failure edges. The broad row still remains the
first sorted blocker; the next selected alias is `@zig_struct_u64_u64_5`, a
byval two-u64 struct control-flow shape after five leading integer arguments.
That focused shape is now object-ok with selected `%r9` byval field loads,
stack argument load, and local trap failure edges. The broad row still remains
the first sorted blocker; the next selected alias is `@zig_struct_u64_u64_4`,
a split u64 pair struct control-flow shape with the final field stack-passed.
That focused shape is now object-ok with selected register and stack argument
checks plus local trap failure edges. The broad row still remains the first
sorted blocker; the next selected alias is `@zig_struct_u64_u64_3`, a split
u64 pair struct control-flow shape entirely in argument registers.
That focused shape is now object-ok with selected register checks and local
trap failure edges. The broad row still remains the first sorted blocker; the
next selected alias is `@zig_struct_u64_u64_2`, a split u64 pair struct
control-flow shape entirely in argument registers.
That focused shape is now object-ok with selected register checks and local
trap failure edges. The broad row still remains the first sorted blocker; the
next selected alias is `@zig_struct_u64_u64_1`, a split u64 pair struct
control-flow shape entirely in argument registers.
That focused shape is now object-ok with selected register checks and local
trap failure edges. The broad row still remains the first sorted blocker; the
next selected alias is `@zig_struct_u64_u64_0`, a split u64 pair struct
control-flow shape entirely in argument registers.
That focused shape is now object-ok with selected register checks and local
trap failure edges. The broad row still remains the first sorted blocker; the
next selected alias is `@zig_ret_struct_u64_u64`, a two-register u64 pair
return shape.
That focused shape is now object-ok with selected `%rax`/`%rdx` return
materialization. The broad row still remains the first sorted blocker; the
next selected alias is `@zig_struct_u64`, a two-u64 control-flow shape.
That focused shape is now object-ok with selected register checks and local
trap failure edges. The broad row still remains the first sorted blocker; the
next selected alias is `@zig_ret_struct_u64`, an i64 return shape.
That focused shape is now object-ok with selected `%rax` return
materialization. The broad row still remains the first sorted blocker; the
next selected alias is `@zig_struct_u32`, an i32/i64 control-flow shape.
That focused shape is now object-ok with selected i32/i64 register checks and
local trap failure edges. The broad row still remains the first sorted
blocker; the next selected alias is `@zig_ret_struct_u32`, an i32 return
shape.
That focused shape is now object-ok through existing straight-line i32 return
lowering. The broad row still remains the first sorted blocker; the next
selected alias is `@zig_struct_u16`, an i16/i64 control-flow shape.
That focused shape is now object-ok with selected 16-bit and 64-bit register
checks plus local trap failure edges. The broad row still remains the first
sorted blocker; the next selected alias is `@zig_ret_struct_u16`, an i16
return shape.
That focused shape is now object-ok with selected `%eax` return
materialization. The broad row still remains the first sorted blocker; the
next selected alias is `@zig_struct_u8`, an i8/i64 control-flow shape.
That focused shape is now object-ok with selected 8-bit and 64-bit register
checks plus local trap failure edges. The broad row still remains the first
sorted blocker; the next selected alias is `@zig_ret_struct_u8`, an i8 return
shape.
That focused shape is now object-ok with selected `%eax` return
materialization. The broad row still remains the first sorted blocker; the
next selected alias is `@zig_cmultd_comp`, a double-comparison control-flow
shape returning two doubles.
That focused shape is now object-ok with selected `ucomisd` comparisons and
`%xmm0`/`%xmm1` return materialization. The broad row still remains the first
sorted blocker; the next selected alias is `@zig_cmultf_comp`, a
float-comparison control-flow shape returning a packed two-float vector.
That focused shape is now object-ok with selected low-lane float comparisons
and packed `%xmm0` vector return materialization. The broad row still remains
the first sorted blocker; the next selected alias is `@zig_cmultd`, a
double-comparison control-flow shape returning two doubles.
That focused shape is now object-ok through the shared selected `ucomisd`
comparison path. The broad row still remains the first sorted blocker; the
next selected alias is `@zig_cmultf`, a two-vector float comparison shape
returning a packed two-float vector.
That focused shape is now object-ok with selected packed vector comparisons
and packed `%xmm0` return materialization. The broad row still remains the
first sorted blocker; the next selected alias is `@zig_bool`, an i1
branch-to-return-or-trap shape.
That focused shape is now object-ok with selected low-byte compare and local
trap failure edge. The broad row still remains the first sorted blocker; the
next selected alias is `@zig_ptr`, a pointer equality branch-to-return-or-trap
shape.
That focused shape is now object-ok with selected 64-bit pointer compare and
local trap failure edge. `@zig_longdouble` is already object-ok through
existing straight-line void return lowering. The broad row still remains the
first sorted blocker; the next selected alias is `@zig_f64`, a double equality
branch-to-return-or-trap shape.
That focused shape is now object-ok with selected `ucomisd` equality
comparison and local trap failure edge. The broad row still remains the first
sorted blocker; the next selected alias is `@zig_f32`, a float equality
branch-to-return-or-trap shape.
That focused shape is now object-ok with selected `ucomiss` equality
comparison and local trap failure edge. The broad row still remains the first
sorted blocker; the next selected alias is `@zig_five_floats`, a five-argument
float equality ladder ending in return-or-trap.
That focused shape is now object-ok with selected low-lane float comparisons
through `%xmm4` and a local trap failure edge. The broad row still remains the
first sorted blocker; the next selected alias is `@zig_struct_u128`, a split
u128 equality branch-to-return-or-trap shape.
That focused shape is now object-ok with selected low/high i64 comparisons
and a local trap failure edge. The broad row still remains the first sorted
blocker; the next selected alias is `@zig_struct_i128`, a split i128 equality
branch-to-return-or-trap shape.
That focused shape is now object-ok with selected low/high i64 comparisons
and a local trap failure edge. The broad row still remains the first sorted
blocker; the next selected alias is `@zig_i64`, an i64 equality
branch-to-return-or-trap shape.
That focused shape is now object-ok with a selected 64-bit argument comparison
and a local trap failure edge. The broad row still remains the first sorted
blocker; the next selected alias is `@zig_i32`, an i32 equality
branch-to-return-or-trap shape.
That focused shape is now object-ok with a selected 32-bit argument comparison
and a local trap failure edge. The broad row still remains the first sorted
blocker; the next selected alias is `@zig_i16`, an i16 equality
branch-to-return-or-trap shape.
That focused shape is now object-ok with a selected 16-bit argument comparison
and a local trap failure edge. The broad row still remains the first sorted
blocker; the next selected alias is `@zig_i8`, an i8 equality
branch-to-return-or-trap shape.
That focused shape is now object-ok with a selected 8-bit argument comparison
and a local trap failure edge. The broad row still remains the first sorted
blocker; the next selected alias is `@zig_u64`, a u64 equality
branch-to-return-or-trap shape.
That focused shape is now object-ok through the selected 64-bit scalar branch
path. The broad row still remains the first sorted blocker; the next selected
alias is `@zig_u32`, a u32 equality branch-to-return-or-trap shape.
That focused shape is now object-ok through the selected 32-bit scalar branch
path. The broad row still remains the first sorted blocker; the next selected
alias is `@zig_u16`, a u16 equality branch-to-return-or-trap shape.
That focused shape is now object-ok through the selected 16-bit scalar branch
path. The broad row still remains the first sorted blocker; the next selected
alias is `@zig_u8`, a u8 equality branch-to-return-or-trap shape.
That focused shape is now object-ok through the selected 8-bit scalar branch
path. The broad row still remains the first sorted blocker; the next selected
alias is `@zig_five_integers`, a five-argument integer equality ladder ending
in return-or-trap.
That focused shape is now object-ok with selected integer argument comparisons
through `%r8d` and a local trap failure edge. The broad row still remains the
first sorted blocker; the next selected alias is `@zig_panic`, a noreturn
panic stub ending in unreachable.
That focused shape is now object-ok with a selected local `ud2` panic stub.
The broad `c_abi_main` row is object-clean. The current ReleaseSmall object
probe is 266 successes and 199 failures. The next sorted blocker is
`cases_address_space_pointer_access_chaining_pointer_to_optional_array.zig.ReleaseSmall.x86_64.optimized.ll`;
the selected alias is `@_start -> @start._start`, a naked startup inline-asm
trampoline ending in unreachable.
That focused shape is now object-ok with selected startup trampoline lowering
and an `R_X86_64_PLT32` relocation to `start.posixCallMainAndExit`. The
current ReleaseSmall object probe is 327 successes and 138 failures. The next
sorted blocker is `cases_array_in_anon_struct.zig.ReleaseSmall.x86_64.optimized.ll`;
the selected alias target is `@getauxval -> @os.linux.getauxvalImpl`, an auxv
scan loop over `@os.linux.elf_aux_maybe`.
That focused shape is now object-ok with PC-relative global-pointer load,
tag/value loop lowering, and a `getauxval` public alias. The current
ReleaseSmall object probe is 455 successes and 10 failures. The next sorted
blocker is
`cases_compile_errors_illegal_operation_on_logical_ptr.zig.ReleaseSmall.x86_64.optimized.ll`;
the selected alias is `@elemPtr -> @illegal_operation_on_logical_ptr.elemPtr`,
an empty noreturn unreachable compile-error stub.
That focused shape is now object-ok through the selected `ud2` unreachable
stub path. The current ReleaseSmall object probe is 456 successes and 9
failures. The next sorted blocker is
`cases_inherit_want_safety.zig.ReleaseSmall.x86_64.optimized.ll`; the selected
alias is `@entry -> @inherit_want_safety.entry`, an i64 constant return. That
shape is now object-ok through selected `%rax` constant return materialization.
The current ReleaseSmall object probe is 457 successes and 8 failures. The
next sorted blocker is
`cases_no_compile_panic_for_unchecked_arith.zig.ReleaseSmall.x86_64.optimized.ll`;
the selected alias is
`@entry -> @no_compile_panic_for_unchecked_arith.entry`, a selected
`llvm.umul.fix.sat.i64` constant-call return. That shape is now object-ok
through selected constant-call materialization. The current ReleaseSmall object
probe is 458 successes and 7 failures. The next sorted blocker is
`standalone_compile_asm_main.zig.ReleaseSmall.x86_64.optimized.ll`; the
selected alias is `@main -> @main.main`, an empty noreturn unreachable stub.
That shape is now object-ok through the selected `ud2` unreachable-stub path.
The current ReleaseSmall object probe is 459 successes and 6 failures. The
next sorted blocker is
`standalone_emit_llvm_no_bin_main.zig.ReleaseSmall.x86_64.optimized.ll`; the
selected alias is `@strFromFloatHelp -> @main.strFromFloatHelp`, a multi-block
float-format helper. That row is a boundary exclusion for the current
ReleaseSmall object subset because it is broad float-format/backend work, not a
single defensible lowering slice. With that row excluded, the selected
`standalone_extern_exports.zig.ReleaseSmall.x86_64.optimized.ll`
`@getHidden`/`@updateHidden` hidden i32 global access shapes are now object-ok.
The adjusted ReleaseSmall object probe is 460 successes, 4 failures, and 1
excluded row. The next sorted implementation blocker is
`standalone_install_raw_hex_main.zig.ReleaseSmall.x86_64.optimized.ll`; the
selected alias is `@_start -> @main._start`, a two-block infinite loop. That
shape is now object-ok through selected unconditional self-branch lowering. The
adjusted ReleaseSmall object probe is 461 successes, 3 failures, and 1
excluded row. The next sorted implementation blocker is
`standalone_libfuzzer_main.zig.ReleaseSmall.x86_64.optimized.ll`; the selected
alias is `@runner_futex_wait -> @main.runner_futex_wait`, an i1 constant
return. That focused shape is now object-ok, but the broad row still fails on
the next selected public alias:
`@runner_test_name -> @main.runner_test_name`, a string-slice aggregate return
for the `"test"` name. That focused shape is now object-ok, but the broad row
still fails on the next selected public alias:
`@runner_test_run -> @main.runner_test_run`, a selected libfuzzer runtime-call
shape. That focused shape is now object-ok through selected call argument
materialization, PC-relative symbol addresses, PLT32 call relocations, and
private string constants. The adjusted ReleaseSmall object probe is 462
successes, 2 failures, and 1 excluded row. The next sorted implementation
blocker is
`standalone_mix_c_files_main.zig.ReleaseSmall.x86_64.optimized.ll`; the
selected alias is `@add_zig -> @main.add_zig`, a mixed Zig/C global-add i32
return shape. That focused shape is now object-ok through selected private
global load, external TLS global add, and `R_X86_64_TPOFF32` relocation
support. The adjusted broad row still fails in
`standalone_mix_c_files_main.zig.ReleaseSmall.x86_64.optimized.ll`, so the
adjusted ReleaseSmall object probe remains 462 successes, 2 failures, and 1
excluded row. The next selected public alias in that row is
`@add_may_panic -> @main.add_may_panic`, a checked add/panic branch shape.
That focused shape is now object-ok through selected negative-branch lowering,
panic-edge call relocation, selected panic string data, and private global add
return lowering. The `standalone_mix_c_files_main` row is object-clean. The
adjusted ReleaseSmall object probe is 463 successes, 1 failure, and 1 excluded
row. The next sorted implementation blocker is
`standalone_mix_o_files_base64.zig.ReleaseSmall.x86_64.optimized.ll`; the
selected alias is `@decode_base_64 -> @base64.decode_base_64`, a large
table-driven base64 decoder. This row is a documented boundary exclusion for
the current ReleaseSmall object subset: it is broad multi-block decoder/table
lowering, not a defensible one-slice backend reduction. With that row and the
existing float-format helper excluded, the adjusted ReleaseSmall object probe
is clean: 463 successes, 0 failures, and 2 excluded rows. ReleaseSmall
asm/object is now a conservative boundary for the named captured subset.
The first named no-LLVM-codegen x86_64 distribution subset gate is
`bash scripts/run_distribution_no_llvm_codegen_subset.sh`; it composes the
ReleaseFast object/executable gates, ReleaseSafe object gate, selected
ReleaseSmall object gate, and handoff validation, and it passes locally for
`TARGET=x86_64-unknown-linux-gnu`.

The bounded Debug x86_64 asm/object feasibility probe over
`test/zig/expected/debug_*.reduced.ll` is clean: 6 object successes and 0
failures in `bash scripts/run_distribution_debug_object_m4.sh`. The closed
selected blockers are call-result plus immediate-add lowering,
`llvm.dbg.declare`/`llvm.dbg.value` object no-ops, the reduced Debug loop-sum
shape, and the reduced Debug scope-branch phi shape. Broad Debug asm/object
still requires LLVM fallback because DWARF/unwind emission, full O0 codegen,
variable-location salvage, broad std Debug rows, and target-complete ABI
lowering remain outside this reduced subset.

## Activation Rule

- Start new work only from a measured source-backed blocker, a concrete
  opt-22 mismatch, or a failing readiness check.
- Add or identify the fixture before creating a new cycle.
- Record the LLVM upstream source mapping before marking the cycle complete.
- Keep local conservative behavior documented when LLVM is broader.
- Run `bash scripts/run_readiness_checks.sh` before closing the cycle.

## Corpus Discovery Candidates

- Refresh selected Zig-emitted IR rows from the current `../ziglang` stage4
  compiler and compare them with the checked manifest rows.
- Add one small Zig source fixture only when it exposes a construct not already
  covered by accepted rows.
- Reduce broad Debug IR only when it contains a concrete uncovered Debug
  construct.
- Reduce broad ReleaseSafe IR only when it contains a concrete uncovered safety
  or runtime-call construct.
- Promote the vector future row only when vector FP semantics, vector-condition
  legality, scalable-vector policy, target-cost modeling, or native vector
  lowering becomes a measured requirement.

## Optimizer Quality Candidates

These are quality improvements, not finish blockers. Pick one only when a
fixture shows the current local behavior is too conservative for a Zig-backed
case.

- SROA: extend aggregate rewriting only when a new fixture shows pressure
  beyond covered scalar leaf partitions, such as memcpy/memmove, padding,
  widening, packed aggregates, or vector fields.
- GVN: add one measured PRE or load-availability slice beyond the current
  MemorySSA-backed fixtures.
- ADCE: improve one measured control-dependence case beyond the current acyclic
  dead-region fixtures.
- DSE: extend MemorySSA-backed byte-range reasoning only for a concrete
  source-backed store pattern.
- EarlyCSE: replace linear expression scans with scoped hash buckets only after
  expression keys include all needed alias-sensitive memory facts.

## Floating-Point Candidates

The parser/verifier and conservative optimizer boundary already cover the
current accepted FP corpus. Further FP work needs new source-backed pressure or
explicit opt-22 parity work.

- Expand the APFloat-shaped semantic model only for a fixture involving NaN,
  infinity, signed zero, subnormals, or target-dependent literals.
- Teach InstSimplify/InstCombine strict FP identities only after legal
  NaN/signed-zero/exception fixtures exist.
- Use fast-math flags as optimization facts only after matching the required
  LLVM `FastMathFlags` legality for the chosen transform.
- Extend SCCP with an FP constant lattice only after APFloat comparison fixtures
  exist.
- Enable FP value numbering/CSE only after strict and fast-math equality rules
  are represented.

## Debug Candidates

Current debug-location-only behavior is fixture-backed. Full variable-location
salvage remains outside the finish scope.

- Treat reduced Debug object emission as a conservative subset only; do not
  promote broad Debug asm/object until a source-backed broad Debug row is
  captured, probed, and reduced from a concrete first blocker.
- Add a debug salvage slice only when a source-backed transform removes or
  replaces an instruction carrying `!dbg` in a way not covered by existing
  fixtures.
- Keep `llvm.dbg.value` and `llvm.dbg.declare` transform pipelines disabled
  until variable-location salvage is represented.
- Reduce new Debug-mode rows only when they contain an uncovered DI node,
  intrinsic, or verifier requirement.

## Backend And Handoff Candidates

The local backend remains validation-only and bounded to documented x86_64
smoke coverage.

- Add one handoff proof only when an accepted optimized IR shape cannot be
  validated by the existing scalar, memory, loop, global, call, stack, and
  stack-memory-to-call cases.
- Keep broad register allocation, scheduling, unwind/debug object generation,
  target-complete ABI lowering, and multi-object-format parity out of scope.

## Explicitly Completed Or Superseded Items

The following earlier backlog ideas are no longer active backlog items because
they were completed, superseded, or converted into conservative boundaries:

- [x] Inline asm representation and barrier preservation.
- [x] `atomicrmw`, `cmpxchg`, and `fence` representation with fail-closed
      verifier rules.
- [x] Vector parser/verifier bootstrap and narrow lane-operation transforms.
- [x] AArch64 target-independent optimizer-input policy.
- [x] Reduced Debug metadata rows for the accepted Debug boundary.
- [x] Path-aware MemorySSA foundation and follow-up vector-lane clobber fix.
- [x] Stale ReleaseSmall unsupported-row closure.
- [x] Selected stage4 corpus freshness audit for `tiny_scalar`, `integers`,
      `switch_control`, and `optional_pointer` ReleaseFast checked captures.
