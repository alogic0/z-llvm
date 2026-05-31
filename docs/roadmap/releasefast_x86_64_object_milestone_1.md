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
