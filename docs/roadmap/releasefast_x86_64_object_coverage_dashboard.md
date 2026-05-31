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
closed_failure_5=globals_comptime.zig.ReleaseSafe.x86_64.optimized.ll
closed_aliases_5=@comptime_const,@update_global,@read_global
closed_failure_6=pointers_memory.zig.ReleaseSafe.x86_64.optimized.ll
closed_aliases_6=@load_store
closed_failure_7=switch_control.zig.ReleaseSafe.x86_64.optimized.ll
closed_aliases_7=@branch_mix,@dense_switch
closed_failure_8=tiny_scalar.zig.ReleaseSafe.x86_64.optimized.ll
closed_aliases_8=@add,@sideEffectFree
closed_failure_9=tls_concurrency.zig.ReleaseSafe.x86_64.optimized.ll
closed_aliases_9=@bump_tls,@read_tls
current_probe=17 object-ok, 0 object-fail
promoted_row=ReleaseSafe x86_64 asm/object conservative boundary for captured subset
next_row=ReleaseSmall x86_64 asm/object
next_optimized_output=tmp/zig_ir/distribution_m3_releasesmall_20260531/optimized-ir
next_optimizer_capture=465 object candidates, 0 local optimizer failures
closed_failure_10=behavior_export_keyword.zig.ReleaseSmall.x86_64.optimized.ll
closed_aliases_10=@writeToVRam,@testPackedStuff
closed_failure_11=behavior_sizeof_and_typeof.zig.ReleaseSmall.x86_64.optimized.ll
closed_aliases_11=@c_fopen,@c_ftell,@c_fputs,@c_printf
next_object_probe=265 object-ok, 200 object-fail
first_failure=c_abi_main.zig.ReleaseSmall.x86_64.optimized.ll
closed_aliases_in_first_failure=@zig_f128_f128_struct,@zig_f128_struct,@zig_f128,@zig_assert_PD,@zig_ret_PD,@zig_ret_CFF,@zig_assert_CFF,@zig_ret_DC,@zig_assert_DC,@zig_ret_split_struct_mixed,@zig_ret_med_struct_mixed,@zig_ret_med_struct_ints,@zig_ret_small_struct_ints,@zig_ret_i64,@zig_ret_i32
selected_alias=@zig_ret_i16
missing_capability=ReleaseSmall straight-line i16 return lowering
```
