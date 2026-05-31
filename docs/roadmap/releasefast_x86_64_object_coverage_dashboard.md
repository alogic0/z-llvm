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
closed_failure_12=c_abi_main.zig.ReleaseSmall.x86_64.optimized.ll
closed_aliases_12=selected public c_abi_main aliases through @zig_panic
closed_failure_13=cases_address_space_pointer_access_chaining_pointer_to_optional_array.zig.ReleaseSmall.x86_64.optimized.ll
closed_aliases_13=@_start -> @start._start
closed_failure_14=cases_array_in_anon_struct.zig.ReleaseSmall.x86_64.optimized.ll
closed_aliases_14=@getauxval -> @os.linux.getauxvalImpl
closed_failure_15=cases_compile_errors_illegal_operation_on_logical_ptr.zig.ReleaseSmall.x86_64.optimized.ll
closed_aliases_15=@elemPtr -> @illegal_operation_on_logical_ptr.elemPtr
closed_failure_16=cases_inherit_want_safety.zig.ReleaseSmall.x86_64.optimized.ll
closed_aliases_16=@entry -> @inherit_want_safety.entry
closed_failure_17=cases_no_compile_panic_for_unchecked_arith.zig.ReleaseSmall.x86_64.optimized.ll
closed_aliases_17=@entry -> @no_compile_panic_for_unchecked_arith.entry
closed_failure_18=standalone_compile_asm_main.zig.ReleaseSmall.x86_64.optimized.ll
closed_aliases_18=@main -> @main.main
boundary_exclusion_1=standalone_emit_llvm_no_bin_main.zig.ReleaseSmall.x86_64.optimized.ll selected @strFromFloatHelp -> @main.strFromFloatHelp multi-block float-format helper
closed_failure_19=standalone_extern_exports.zig.ReleaseSmall.x86_64.optimized.ll
closed_aliases_19=@getHidden,@updateHidden selected hidden i32 global access
closed_failure_20=standalone_install_raw_hex_main.zig.ReleaseSmall.x86_64.optimized.ll
closed_aliases_20=@_start -> @main._start
intermediate_adjusted_object_probe=461 object-ok, 3 object-fail, 1 excluded
closed_failure_21=standalone_libfuzzer_main.zig.ReleaseSmall.x86_64.optimized.ll
closed_aliases_21=@runner_futex_wait -> @main.runner_futex_wait,@runner_test_name -> @main.runner_test_name,@runner_test_run -> @main.runner_test_run
current_adjusted_object_probe=462 object-ok, 2 object-fail, 1 excluded
first_adjusted_failure=standalone_mix_c_files_main.zig.ReleaseSmall.x86_64.optimized.ll
selected_alias=@add_zig -> @main.add_zig
missing_capability=selected mixed Zig/C global-add i32 return lowering
```
