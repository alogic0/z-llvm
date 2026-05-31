# ReleaseFast x86_64 Object Coverage Dashboard

This dashboard tracks the broad optimized-output object probe for
`mode=ReleaseFast`, `target=x86_64-linux-gnu`, `stage=asm/object`.

## Current Probe

```text
optimized_output=tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir
probe_date=2026-05-30
rows=17
object_ok=17
object_fail=0
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
tls_concurrency.zig.ReleaseFast.x86_64.optimized.ll
```

## Current Blockers

```text
none in this captured ReleaseFast object set
```

## Active Slice

```text
next_row=ReleaseSafe x86_64 asm/object
optimized_output=tmp/zig_ir/distribution_m2_releasesafe_20260530/optimized-ir
closed_failure_1=aggregates.zig.ReleaseSafe.x86_64.optimized.ll
closed_aliases_1=@slice_sum,@struct_sum,@array_sum
closed_failure_2=atomics_inline_asm_debug.zig.ReleaseSafe.x86_64.optimized.ll
closed_aliases_2=@debug_location,@inline_asm_barrier,@atomic_add
closed_failure_3=control_flow_calls.zig.ReleaseSafe.x86_64.optimized.ll
closed_aliases_3=@loop_sum,@call_chain
closed_failure_4=error_switch.zig.ReleaseSafe.x86_64.optimized.ll
closed_aliases_4=@error_switch
current_probe=12 object-ok, 5 object-fail
first_failure=globals_comptime.zig.ReleaseSafe.x86_64.optimized.ll
selected_alias=@comptime_const
missing_capability=ReleaseSafe checked multiply-by-constant and panic-edge lowering
```
