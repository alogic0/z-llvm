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
probe is 16 object successes and 1 object failure after closing selected
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
`tiny_scalar.zig.ReleaseSafe.x86_64.optimized.ll` checked `@add` support. The
first sorted failure is now `tls_concurrency.zig.ReleaseSafe.x86_64.optimized.ll`
with selected `@bump_tls` checked local-exec TLS update and panic-edge lowering.
