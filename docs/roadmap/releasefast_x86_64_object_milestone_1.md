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

Classified blockers from representative non-empty optimized output:

| Fixture | Source row | Shape | Current blocker |
| --- | --- | --- | --- |
| `switch_control_branch_mix` | `switch_control.zig` | branch/select lowered to `select` plus add | `UnsupportedCodegenInstruction` |
| `control_flow_calls_call_chain` | `control_flow_calls.zig` | shift and or arithmetic | `UnsupportedCodegenValue` |
| `globals_comptime_const` | `globals_comptime.zig` | multiply by constant | `UnsupportedCodegenInstruction` |
| `optional_pointer_value` | `optional_pointer.zig` | null branch and pointer load | `UnsupportedCodegenControlFlow` |
| `switch_control_dense_switch` | `switch_control.zig` | switch table load and phi merge | `UnsupportedCodegenControlFlow` |

## Validation Gate

Run the milestone gate with:

```sh
bash scripts/run_distribution_object_m1.sh
bash scripts/run_handoff_validation.sh
```

`scripts/run_distribution_object_m1.sh` emits local x86_64 ELF relocatable
objects for object-ready fixtures and checks ELF type, machine, `.text`, and
`.symtab` records. Executable checks are not used in this milestone because the
selected Zig-backed optimized outputs expose public aliases while the current
validation-only object writer emits function symbols only; alias/export symbol
coverage is a separate object-replacement blocker.

## Matrix Result

Milestone 1 promotes:

```text
ReleaseFast / x86_64-linux-gnu / asm-object =
conservative boundary for selected Zig-backed optimized-output subset
```

Explicit exclusions:

```text
branch/select lowering
variable shift/or chains
integer multiply by constant
global data and alias/export symbol emission
pointer loads and null-branch control flow
switch table lowering and phi merge codegen
debug/unwind records
linker behavior
target-complete ABI lowering
```

## Milestone 2

The first uncovered blocker is `switch_control_branch_mix`: selected
ReleaseFast optimized output with a `select` value feeding integer arithmetic.
Milestone 2 should add only the x86_64 lowering, encoding, fixture evidence, and
validation needed for that shape.
