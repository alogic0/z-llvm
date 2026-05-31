# ReleaseFast x86_64 Object Coverage Dashboard

This dashboard tracks the broad optimized-output object probe for
`mode=ReleaseFast`, `target=x86_64-linux-gnu`, `stage=asm/object`.

## Current Probe

```text
optimized_output=tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir
probe_date=2026-05-30
rows=17
object_ok=16
object_fail=1
gate=zig build run -- --emit=obj --target=x86_64-unknown-linux-gnu <row.ll>
```

## Passing Broad Rows

```text
aggregate_abi.zig.ReleaseFast.x86_64.optimized.ll
aggregates.zig.ReleaseFast.x86_64.optimized.ll
atomics_inline_asm_debug.zig.ReleaseFast.x86_64.optimized.ll
control_flow_calls.zig.ReleaseFast.x86_64.optimized.ll
error_switch.zig.ReleaseFast.x86_64.optimized.ll
float_compare.zig.ReleaseFast.x86_64.optimized.ll
floats_math.zig.ReleaseFast.x86_64.optimized.ll
fp_constants.zig.ReleaseFast.x86_64.optimized.ll
fp_extended_ops.zig.ReleaseFast.x86_64.optimized.ll
globals_comptime.zig.ReleaseFast.x86_64.optimized.ll
integers.zig.ReleaseFast.x86_64.optimized.ll
optional_pointer.zig.ReleaseFast.x86_64.optimized.ll
packed_bits.zig.ReleaseFast.x86_64.optimized.ll
pointers_memory.zig.ReleaseFast.x86_64.optimized.ll
switch_control.zig.ReleaseFast.x86_64.optimized.ll
tiny_scalar.zig.ReleaseFast.x86_64.optimized.ll
```

## Current Blockers

```text
tls_concurrency.zig.ReleaseFast.x86_64.optimized.ll       UnsupportedCodegenInstruction
```

## Active Slice

```text
row=tls_concurrency.zig.ReleaseFast.x86_64.optimized.ll
selected_aliases=@bump_tls,@read_tls
missing_capability=thread-local i32 load/store lowering
boundary=selected source-backed shape only
```
