# ReleaseFast x86_64 Object Milestone 1

Milestone 1 defines the first conservative asm/object boundary for
`ReleaseFast / x86_64-linux-gnu`. It is not a local replacement for all
ReleaseFast object emission. It covers a named Zig-backed optimized-output
subset and records the first blockers for the next milestone.

## Capture Evidence

Broader ReleaseFast optimized-output capture:

```text
tmp/zig_ir/distribution_m1_releasefast_20260530
  test_root=test/zig/inputs
  mode=ReleaseFast
  target=x86_64-linux-gnu
  passes=zig-release-fast-accepted
  processed=17 compile_skip=0 emit_ok=17 local_ok=17
  input_too_large=0 parse_fail=0 verify_fail=0 optimizer_fail=0
  capture_optimized_output=true
```

Only selected reduced optimized outputs are tracked. The broad capture remains a
temporary discovery artifact.

## Selected Fixtures

Tracked manifest:

```text
test/distribution/releasefast_x86_64/manifest.tsv
```

Object-ready selected subset:

| Fixture | Source row | Shape | Validation |
| --- | --- | --- | --- |
| `tiny_scalar` | `tiny_scalar.zig` | scalar arithmetic and void return | local object + readelf |
| `integers_add_wrap` | `integers.zig` | scalar wrapping add | local object + readelf |
| `switch_control_branch_mix` | `switch_control.zig` | branch/select lowered to `select` plus add | local object + readelf |
| `control_flow_calls_call_chain` | `control_flow_calls.zig` | shift and or arithmetic | local object + readelf |
| `globals_comptime_const` | `globals_comptime.zig` | multiply by constant | local object + readelf |
| `optional_pointer_value` | `optional_pointer.zig` | null branch and pointer load | local object + readelf |
| `switch_control_dense_switch` | `switch_control.zig` | switch table load and phi merge, lowered as selected compare/return constants | local object + readelf |

No selected Milestone 1 fixture remains classified as an object-generation
blocker.

## Validation Gate

Run the milestone gate with:

```sh
bash scripts/run_distribution_object_m1.sh
bash scripts/run_distribution_executable_m1.sh
bash scripts/run_handoff_validation.sh
```

`scripts/run_distribution_object_m1.sh` emits local x86_64 ELF relocatable
objects for object-ready fixtures and checks ELF type, machine, `.text`, and
`.symtab` records, including the selected public alias symbol for each fixture.
`scripts/run_distribution_executable_m1.sh` links all selected public aliases
with tiny host harnesses and validates deterministic return values, including
`@sideEffectFree`, `@add`, `@add_wrap`, `@branch_mix`, `@call_chain`,
`@comptime_const`, `@optional_ptr_value`, `@dense_switch`, `@pair_first`, and
`@make_pair`, plus `@error_union_payload` and `@optional_payload`.
`@slice_sum`, `@struct_sum`, and `@array_sum` are also covered by the broader
ReleaseFast object executable gate, as are `@debug_location` and
`@inline_asm_barrier`, selected `@atomic_add`, `@volatile_roundtrip`,
`@load_store`, and selected local-exec TLS `@bump_tls` and `@read_tls`.

## Matrix Result

Milestone 1 promotes:

```text
ReleaseFast / x86_64-linux-gnu / asm-object =
conservative boundary for selected Zig-backed optimized-output subset
```

Explicit exclusions:

```text
general branch/select lowering beyond the selected add/sub pattern
variable shift/or chains beyond the selected shl-by-one plus or-one pattern
integer multiply beyond the selected multiply-by-five pattern
global data and alias/export symbol emission beyond selected local function aliases
pointer loads and null-branch control flow beyond the selected nullable i32 load
switch-table lowering beyond the selected dense constant-return shape
executable validation beyond selected Milestone 1 public aliases
debug/unwind records
linker behavior
target-complete ABI lowering
```

## Milestone 2

The next source-backed blocker was broader ReleaseFast object coverage. A broad
probe over `tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir`
now passes every captured row, including the selected atomics, loop, error
switch, floating-point, globals, integer, pointer/memory, and local-exec TLS
shapes. The current broad object probe is:

```text
optimized_output=tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir
rows=17
object_ok=17
object_fail=0
first_failure=none
```

The compact running dashboard is
`docs/roadmap/releasefast_x86_64_object_coverage_dashboard.md`.

The next measured asm/object row is ReleaseSafe. The bounded ReleaseSafe
optimized-output capture is:

```text
tmp/zig_ir/distribution_m2_releasesafe_20260530
  test_root=test/zig/inputs
  mode=ReleaseSafe
  target=x86_64-linux-gnu
  passes=zig-release-safe-accepted
  processed=17 compile_skip=0 emit_ok=17 local_ok=17
  input_too_large=0 parse_fail=0 verify_fail=0 optimizer_fail=0
  capture_optimized_output=true
```

Object probing those captured rows with `--input-limit=67108864` originally
found 8 local object successes and 9 object failures. The selected
`aggregates.zig.ReleaseSafe.x86_64.optimized.ll` blocker is now object-ok for
`@slice_sum`, `@struct_sum`, and `@array_sum` overflow-checked
`llvm.sadd.with.overflow.i32` shapes with panic-edge relocations. The current
probe is 17 object successes and 0 object failures after closing selected
`atomics_inline_asm_debug.zig.ReleaseSafe.x86_64.optimized.ll` checked
`@debug_location` support and selected
`control_flow_calls.zig.ReleaseSafe.x86_64.optimized.ll` checked `@loop_sum`
plus guarded `@call_chain` support, and selected
`error_switch.zig.ReleaseSafe.x86_64.optimized.ll` straight-line
`@error_switch` `icmp`/`select` support, and selected
`globals_comptime.zig.ReleaseSafe.x86_64.optimized.ll` checked
`@comptime_const`, `@update_global`, and `@read_global` support, and selected
`pointers_memory.zig.ReleaseSafe.x86_64.optimized.ll` checked `@load_store`
support, and selected `switch_control.zig.ReleaseSafe.x86_64.optimized.ll`
checked `@branch_mix` support, and selected
`tiny_scalar.zig.ReleaseSafe.x86_64.optimized.ll` checked `@add` support, and
selected `tls_concurrency.zig.ReleaseSafe.x86_64.optimized.ll` checked
`@bump_tls` support. This promotes ReleaseSafe / x86_64-linux-gnu / asm-object
to a conservative boundary for the captured optimized-output object subset.

The next measured asm/object row is ReleaseSmall. The bounded ReleaseSmall
optimized-output capture is:

```text
tmp/zig_ir/distribution_m3_releasesmall_20260531
  test_root=../ziglang/test
  mode=ReleaseSmall
  target=x86_64-linux-gnu
  passes=zig-release-small-accepted
  processed=1474 compile_skip=1009 emit_ok=465 local_ok=465
  input_too_large=0 parse_fail=0 verify_fail=0 optimizer_fail=0
  capture_optimized_output=true
```

Object probing those captured rows with `--input-limit=67108864` found 263
local object successes and 202 object failures. The first sorted failure is
`behavior_export_keyword.zig.ReleaseSmall.x86_64.optimized.ll`, selected
`@writeToVRam` volatile absolute-address store lowering. That blocker is now
object-ok for `@writeToVRam` and `@testPackedStuff`. The current ReleaseSmall
object probe is 264 successes and 201 failures. The next sorted failure was
`behavior_sizeof_and_typeof.zig.ReleaseSmall.x86_64.optimized.ll`, selected
`@c_fopen` noreturn unreachable-stub lowering. That blocker is now object-ok
for `@c_fopen`, `@c_ftell`, `@c_fputs`, and `@c_printf`. The current
ReleaseSmall object probe is 265 successes and 200 failures. The first sorted
failure is `c_abi_main.zig.ReleaseSmall.x86_64.optimized.ll`, selected
`@zig_f128_f128_struct` C ABI fp128 byval/sret lowering with `__eqtf2`
comparison calls and panic branches. That focused selected shape is now
object-ok. The broad `c_abi_main` row remains the first sorted failure; the
next selected alias in that row is `@zig_f128_struct`, a C ABI fp128
aggregate-return shape with an `__eqtf2` guard and panic edge. The selected
`@zig_f128_struct` and adjacent `@zig_f128` scalar fp128 return shapes are now
object-ok in the focused ReleaseSmall gate. The broad row still remains the
first sorted failure; the next selected alias is `@zig_assert_PD`, a mixed
integer/double assertion shape with stack local aggregate setup, floating-point
comparison, and a diagnostic failure edge. The selected return-code branch
behavior for `@zig_assert_PD` is now object-ok in the focused ReleaseSmall
gate, with diagnostic printing side effects explicitly outside the local
replacement boundary. The broad row still remains the first sorted failure;
the next selected alias is `@zig_ret_PD`, a mixed integer/double aggregate
return. That focused shape is now object-ok. The broad row still remains the
first sorted failure; the next selected alias is `@zig_ret_CFF`, a mixed
integer/float aggregate return. That focused shape is now object-ok. The broad
row still remains the first sorted failure; the next selected alias is
`@zig_assert_CFF`, a mixed integer/float assertion shape with floating-point
comparison and diagnostic failure edge. The selected return-code branch
behavior for `@zig_assert_CFF` is now object-ok in the focused ReleaseSmall
gate, with diagnostic printing side effects explicitly outside the local
replacement boundary. The broad row still remains the first sorted failure;
the next selected alias is `@zig_ret_DC`, a mixed double/integer aggregate
return. That focused shape is now object-ok. The broad row still remains the
first sorted failure; the next selected alias is `@zig_assert_DC`, a mixed
double/integer assertion shape with floating-point comparison, low-byte integer
comparison, and diagnostic failure edge. The selected return-code branch
behavior for `@zig_assert_DC` is now object-ok in the focused ReleaseSmall
gate, with diagnostic printing side effects explicitly outside the local
replacement boundary. The broad row still remains the first sorted failure;
the next selected alias is `@zig_ret_split_struct_mixed`, a two-register
aggregate return. That focused shape is now object-ok. The broad row still
remains the first sorted failure; the next selected alias is
`@zig_ret_med_struct_mixed`, another two-register aggregate return with
different constant bit patterns. That focused shape is now object-ok. The
broad row still remains the first sorted failure; the next selected alias is
`@zig_ret_med_struct_ints`, an integer aggregate return. That focused shape is
now object-ok. The broad row also advances past the adjacent existing
`@zig_ret_small_struct_ints` i32 return. The broad row still remains the first
sorted failure; the next selected alias is `@zig_ret_i64`, a straight-line i64
return. That focused shape is now object-ok. The broad row also advances past
the adjacent existing `@zig_ret_i32` return. The broad row still remains the
first sorted failure; the next selected alias is `@zig_ret_i16`, a
straight-line i16 return. That focused shape is now object-ok. The broad row
still remains the first sorted failure; the next selected alias is
`@zig_ret_i8`, a straight-line i8 return. That focused shape is now object-ok.
The broad row still remains the first sorted failure; the next selected alias
is `@zig_ret_u16`, a straight-line zero-extended u16 return. That focused
shape is now object-ok. The broad row still remains the first sorted failure;
the next selected alias is `@zig_ret_u8`, a straight-line zero-extended u8
return. That focused shape is now object-ok. The broad row still remains the
first sorted failure; the next selected alias is `@zig_ret_bool`, a
straight-line boolean return. That focused shape is now object-ok. The broad
row still remains the first sorted failure; the next selected alias is
`@zig_multiple_struct_floats`, a vector-parameter floating comparison
control-flow shape. That focused shape is now object-ok with local trap
failure edges. The broad row still remains the first sorted failure; the next
selected alias is `@zig_multiple_struct_ints`, a packed-integer comparison
control-flow shape.
That focused shape is now object-ok with local trap failure edges. The broad
row still remains the first sorted failure; the next selected alias is
`@zig_big_struct_both`, a large byval/sret struct check-and-copy shape.
That focused shape is now object-ok with local trap failure edges and selected
sret stores. The broad row still remains the first sorted failure; the next
selected alias is `@zig_split_struct_mixed`, a split mixed integer/float
comparison control-flow shape.
That focused shape is now object-ok with local trap failure edges and an exact
selected packed bit-pattern check. The broad row still remains the first
sorted failure; the next selected alias is `@zig_split_struct_ints`, a split
integer struct comparison control-flow shape.
That focused shape is now object-ok with local trap failure edges and an exact
selected packed integer register payload check. The broad row still remains
the first sorted failure; the next selected alias is `@zig_big_packed_struct`,
a packed i128 struct comparison control-flow shape.
That focused shape is now object-ok with local trap failure edges and selected
low/high register checks. The broad row still remains the first sorted
failure; the next selected alias is `@zig_small_packed_struct`, a packed i8
struct comparison control-flow shape.
That focused shape is now object-ok with local trap failure edges and an exact
selected byte payload check. The broad row still remains the first sorted
failure; the next selected alias is `@zig_med_struct_ints`, a medium integer
struct comparison control-flow shape.
That focused shape is now object-ok with local trap failure edges and selected
packed integer register checks. The broad row still remains the first sorted
failure; the next selected alias is `@zig_small_struct_ints`, a small integer
struct comparison control-flow shape.
That focused shape is now object-ok with local trap failure edges and a
selected packed i32 payload check. The broad row still remains the first
sorted failure; the next selected alias is `@zig_med_struct_mixed`, a medium
mixed struct comparison control-flow shape.
That focused shape is now object-ok with local trap failure edges and selected
packed mixed integer/float register checks. The broad row still remains the
first sorted failure; the next selected alias is `@zig_big_union`, a byval
aggregate comparison control-flow shape.
That focused shape is now object-ok with local trap failure edges and selected
byval field-load checks. The broad row still remains the first sorted failure;
the next selected alias is `@zig_big_struct`, a byval aggregate comparison
control-flow shape.
That focused shape is now object-ok with local trap failure edges and selected
byval field-load checks. The broad row still remains the first sorted failure;
the next selected alias is `@zig_struct_i32_i32`, a packed i32 pair comparison
control-flow shape.
That focused shape is now object-ok with local trap failure edges and a
selected packed i32-pair register check. The broad row still remains the first
sorted failure; the next selected alias is `@zig_struct_f32_f32f32`, a
vector/scalar float struct comparison control-flow shape.
That focused shape is now object-ok for both public aliases
`@zig_struct_f32_f32f32` and `@zig_struct_f32f32_f32` with local trap failure
edges and selected vector/scalar float register checks. The broad row still
remains the first sorted failure; the next selected alias is
`@zig_ret_struct_f32_f32f32`, a vector/scalar float struct return shape.
That focused shape is now object-ok for both public aliases
`@zig_ret_struct_f32_f32f32` and `@zig_ret_struct_f32f32_f32` with selected
`%xmm0`/`%xmm1` return materialization. The broad row still remains the first
sorted failure; the next selected alias is `@zig_struct_f32a8_f32a8`, a
vector/scalar float struct comparison control-flow shape.
That focused shape is now object-ok with local trap failure edges and selected
low-lane float register checks. The broad row still remains the first sorted
failure; the next selected alias is `@zig_ret_struct_f32a8_f32a8`, a
vector/scalar float struct return shape.
That focused shape is now object-ok with selected `%xmm0`/`%xmm1` return
materialization while leaving the undef vector lane unconstrained. The broad
row still remains the first sorted failure; the next selected alias is
`@zig_struct_f32a8`, a scalar float struct comparison control-flow shape.
That focused shape is now object-ok with local trap failure edges and selected
low-lane float register checks. The broad row still remains the first sorted
failure; the next selected alias is `@zig_ret_struct_f32a8`, a scalar float
struct return shape.
That focused shape is now object-ok with selected `%xmm0` return
materialization. The broad row still remains the first sorted failure; the
next selected alias is `@zig_struct_f64`, a scalar double struct comparison
control-flow shape.
That focused shape is now object-ok with local trap failure edges and a
selected scalar double register check. The broad row still remains the first
sorted failure; the next selected alias is `@zig_ret_struct_f64`, a scalar
double struct return shape.
That focused shape is now object-ok with selected `%xmm0` return
materialization. The broad row still remains the first sorted failure; the
next selected alias is `@zig_struct_f32`, a scalar float struct comparison
control-flow shape.
That focused shape is now object-ok with local trap failure edges and a
selected scalar float register check. The broad row still remains the first
sorted failure; the next selected alias is `@zig_ret_struct_f32`, a scalar
float struct return shape.
That focused shape is now object-ok with selected `%xmm0` return
materialization. The broad row still remains the first sorted failure; the
next selected alias is `@zig_struct_u64_u64_8`, a byval two-u64 struct
control-flow shape after eight leading integer arguments.
That focused shape is now object-ok with selected stack argument loads, byval
field loads, and local trap failure edges. The broad row still remains the
first sorted failure; the next selected alias is `@zig_struct_u64_u64_7`, a
byval two-u64 struct control-flow shape after seven leading integer arguments.
That focused shape is now object-ok with selected stack argument loads, byval
field loads, and local trap failure edges. The broad row still remains the
first sorted failure; the next selected alias is `@zig_struct_u64_u64_6`, a
byval two-u64 struct control-flow shape after six leading integer arguments.
That focused shape is now object-ok with selected stack argument loads, byval
field loads, and local trap failure edges. The broad row still remains the
first sorted failure; the next selected alias is `@zig_struct_u64_u64_5`, a
byval two-u64 struct control-flow shape after five leading integer arguments.
That focused shape is now object-ok with selected `%r9` byval field loads,
stack argument load, and local trap failure edges. The broad row still remains
the first sorted failure; the next selected alias is `@zig_struct_u64_u64_4`,
a split u64 pair struct control-flow shape with the final field stack-passed.
That focused shape is now object-ok with selected register and stack argument
checks plus local trap failure edges. The broad row still remains the first
sorted failure; the next selected alias is `@zig_struct_u64_u64_3`, a split
u64 pair struct control-flow shape entirely in argument registers.
That focused shape is now object-ok with selected register checks and local
trap failure edges. The broad row still remains the first sorted failure; the
next selected alias is `@zig_struct_u64_u64_2`, a split u64 pair struct
control-flow shape entirely in argument registers.
That focused shape is now object-ok with selected register checks and local
trap failure edges. The broad row still remains the first sorted failure; the
next selected alias is `@zig_struct_u64_u64_1`, a split u64 pair struct
control-flow shape entirely in argument registers.
That focused shape is now object-ok with selected register checks and local
trap failure edges. The broad row still remains the first sorted failure; the
next selected alias is `@zig_struct_u64_u64_0`, a split u64 pair struct
control-flow shape entirely in argument registers.
That focused shape is now object-ok with selected register checks and local
trap failure edges. The broad row still remains the first sorted failure; the
next selected alias is `@zig_ret_struct_u64_u64`, a two-register u64 pair
return shape.
That focused shape is now object-ok with selected `%rax`/`%rdx` return
materialization. The broad row still remains the first sorted failure; the
next selected alias is `@zig_struct_u64`, a two-u64 control-flow shape.
That focused shape is now object-ok with selected register checks and local
trap failure edges. The broad row still remains the first sorted failure; the
next selected alias is `@zig_ret_struct_u64`, an i64 return shape.
That focused shape is now object-ok with selected `%rax` return
materialization. The broad row still remains the first sorted failure; the
next selected alias is `@zig_struct_u32`, an i32/i64 control-flow shape.
That focused shape is now object-ok with selected i32/i64 register checks and
local trap failure edges. The broad row still remains the first sorted
failure; the next selected alias is `@zig_ret_struct_u32`, an i32 return
shape.
That focused shape is now object-ok through existing straight-line i32 return
lowering. The broad row still remains the first sorted failure; the next
selected alias is `@zig_struct_u16`, an i16/i64 control-flow shape.
That focused shape is now object-ok with selected 16-bit and 64-bit register
checks plus local trap failure edges. The broad row still remains the first
sorted failure; the next selected alias is `@zig_ret_struct_u16`, an i16
return shape.
That focused shape is now object-ok with selected `%eax` return
materialization. The broad row still remains the first sorted failure; the
next selected alias is `@zig_struct_u8`, an i8/i64 control-flow shape.
That focused shape is now object-ok with selected 8-bit and 64-bit register
checks plus local trap failure edges. The broad row still remains the first
sorted failure; the next selected alias is `@zig_ret_struct_u8`, an i8 return
shape.
That focused shape is now object-ok with selected `%eax` return
materialization. The broad row still remains the first sorted failure; the
next selected alias is `@zig_cmultd_comp`, a double-comparison control-flow
shape returning two doubles.
That focused shape is now object-ok with selected `ucomisd` comparisons and
`%xmm0`/`%xmm1` return materialization. The broad row still remains the first
sorted failure; the next selected alias is `@zig_cmultf_comp`, a
float-comparison control-flow shape returning a packed two-float vector.
That focused shape is now object-ok with selected low-lane float comparisons
and packed `%xmm0` vector return materialization. The broad row still remains
the first sorted failure; the next selected alias is `@zig_cmultd`, a
double-comparison control-flow shape returning two doubles.
That focused shape is now object-ok through the shared selected `ucomisd`
comparison path. The broad row still remains the first sorted failure; the
next selected alias is `@zig_cmultf`, a two-vector float comparison shape
returning a packed two-float vector.
That focused shape is now object-ok with selected packed vector comparisons
and packed `%xmm0` return materialization. The broad row still remains the
first sorted failure; the next selected alias is `@zig_bool`, an i1
branch-to-return-or-trap shape.
That focused shape is now object-ok with selected low-byte compare and local
trap failure edge. The broad row still remains the first sorted failure; the
next selected alias is `@zig_ptr`, a pointer equality branch-to-return-or-trap
shape.
That focused shape is now object-ok with selected 64-bit pointer compare and
local trap failure edge. `@zig_longdouble` is already object-ok through
existing straight-line void return lowering. The broad row still remains the
first sorted failure; the next selected alias is `@zig_f64`, a double equality
branch-to-return-or-trap shape.
That focused shape is now object-ok with selected `ucomisd` equality
comparison and local trap failure edge. The broad row still remains the first
sorted failure; the next selected alias is `@zig_f32`, a float equality
branch-to-return-or-trap shape.
That focused shape is now object-ok with selected `ucomiss` equality
comparison and local trap failure edge. The broad row still remains the first
sorted failure; the next selected alias is `@zig_five_floats`, a five-argument
float equality ladder ending in return-or-trap.
That focused shape is now object-ok with selected low-lane float comparisons
through `%xmm4` and a local trap failure edge. The broad row still remains the
first sorted failure; the next selected alias is `@zig_struct_u128`, a split
u128 equality branch-to-return-or-trap shape.
That focused shape is now object-ok with selected low/high i64 comparisons
and a local trap failure edge. The broad row still remains the first sorted
failure; the next selected alias is `@zig_struct_i128`, a split i128 equality
branch-to-return-or-trap shape.
That focused shape is now object-ok with selected low/high i64 comparisons
and a local trap failure edge. The broad row still remains the first sorted
failure; the next selected alias is `@zig_i64`, an i64 equality
branch-to-return-or-trap shape.
That focused shape is now object-ok with a selected 64-bit argument comparison
and a local trap failure edge. The broad row still remains the first sorted
failure; the next selected alias is `@zig_i32`, an i32 equality
branch-to-return-or-trap shape.
That focused shape is now object-ok with a selected 32-bit argument comparison
and a local trap failure edge. The broad row still remains the first sorted
failure; the next selected alias is `@zig_i16`, an i16 equality
branch-to-return-or-trap shape.
That focused shape is now object-ok with a selected 16-bit argument comparison
and a local trap failure edge. The broad row still remains the first sorted
failure; the next selected alias is `@zig_i8`, an i8 equality
branch-to-return-or-trap shape.
That focused shape is now object-ok with a selected 8-bit argument comparison
and a local trap failure edge. The broad row still remains the first sorted
failure; the next selected alias is `@zig_u64`, a u64 equality
branch-to-return-or-trap shape.
That focused shape is now object-ok through the selected 64-bit scalar branch
path. The broad row still remains the first sorted failure; the next selected
alias is `@zig_u32`, a u32 equality branch-to-return-or-trap shape.
That focused shape is now object-ok through the selected 32-bit scalar branch
path. The broad row still remains the first sorted failure; the next selected
alias is `@zig_u16`, a u16 equality branch-to-return-or-trap shape.
That focused shape is now object-ok through the selected 16-bit scalar branch
path. The broad row still remains the first sorted failure; the next selected
alias is `@zig_u8`, a u8 equality branch-to-return-or-trap shape.
That focused shape is now object-ok through the selected 8-bit scalar branch
path. The broad row still remains the first sorted failure; the next selected
alias is `@zig_five_integers`, a five-argument integer equality ladder ending
in return-or-trap.
That focused shape is now object-ok with selected integer argument comparisons
through `%r8d` and a local trap failure edge. The broad row still remains the
first sorted failure; the next selected alias is `@zig_panic`, a noreturn
panic stub ending in unreachable.
That focused shape is now object-ok with a selected local `ud2` panic stub.
The broad `c_abi_main` row is object-clean. The current ReleaseSmall object
probe is 266 successes and 199 failures. The next sorted failure is
`cases_address_space_pointer_access_chaining_pointer_to_optional_array.zig.ReleaseSmall.x86_64.optimized.ll`;
the selected alias is `@_start -> @start._start`, a naked startup inline-asm
trampoline ending in unreachable.
That focused shape is now object-ok with selected startup trampoline lowering
and an `R_X86_64_PLT32` relocation to `start.posixCallMainAndExit`. The
current ReleaseSmall object probe is 327 successes and 138 failures. The next
sorted failure is `cases_array_in_anon_struct.zig.ReleaseSmall.x86_64.optimized.ll`;
the selected alias target is `@getauxval -> @os.linux.getauxvalImpl`, an auxv
scan loop over `@os.linux.elf_aux_maybe`.
That focused shape is now object-ok with PC-relative global-pointer load,
tag/value loop lowering, and a `getauxval` public alias. The current
ReleaseSmall object probe is 455 successes and 10 failures. The next sorted
failure is
`cases_compile_errors_illegal_operation_on_logical_ptr.zig.ReleaseSmall.x86_64.optimized.ll`;
the selected alias is `@elemPtr -> @illegal_operation_on_logical_ptr.elemPtr`,
an empty noreturn unreachable compile-error stub.
That focused shape is now object-ok through the selected `ud2` unreachable
stub path. The current ReleaseSmall object probe is 456 successes and 9
failures. The next sorted failure is
`cases_inherit_want_safety.zig.ReleaseSmall.x86_64.optimized.ll`; the selected
alias is `@entry -> @inherit_want_safety.entry`, an i64 constant return. That
shape is now object-ok through selected `%rax` constant return materialization.
The current ReleaseSmall object probe is 457 successes and 8 failures. The
next sorted failure is
`cases_no_compile_panic_for_unchecked_arith.zig.ReleaseSmall.x86_64.optimized.ll`;
the selected alias is
`@entry -> @no_compile_panic_for_unchecked_arith.entry`, a selected
`llvm.umul.fix.sat.i64` constant-call return. That shape is now object-ok
through selected constant-call materialization. The current ReleaseSmall object
probe is 458 successes and 7 failures. The next sorted failure is
`standalone_compile_asm_main.zig.ReleaseSmall.x86_64.optimized.ll`; the
selected alias is `@main -> @main.main`, an empty noreturn unreachable stub.
That shape is now object-ok through the selected `ud2` unreachable-stub path.
The current ReleaseSmall object probe is 459 successes and 6 failures. The
next sorted failure is
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
shape.
