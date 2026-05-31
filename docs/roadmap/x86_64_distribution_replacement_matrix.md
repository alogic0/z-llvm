# x86_64 Distribution Replacement Matrix

This matrix tracks the initial `x86_64-linux-gnu` replacement path by Zig mode
and stage. It is narrower than the historical finish line: a row is useful only
when it changes, proves, or bounds removal of Zig's LLVM library fallback for
the selected distribution path.

Status keys:

```text
local replacement: current local implementation has source-backed evidence
conservative boundary: accepted locally only with documented narrower behavior
LLVM fallback required: Zig still needs LLVM or Zig-owned backend work here
out of scope: not part of the current x86_64 milestone
```

## Matrix

| Mode | Parse | Verify | Optimize | Handoff | Asm/Object |
| --- | --- | --- | --- | --- | --- |
| Debug | conservative boundary | conservative boundary | conservative boundary | LLVM fallback required | LLVM fallback required |
| ReleaseFast | local replacement | local replacement | local replacement | conservative boundary | conservative boundary |
| ReleaseSafe | local replacement | local replacement | local replacement | conservative boundary | conservative boundary |
| ReleaseSmall | local replacement | local replacement | local replacement | conservative boundary | LLVM fallback required |

## Evidence

ReleaseFast, ReleaseSafe, and ReleaseSmall parse/verify/optimize rows are backed
by the accepted x86_64 sweeps recorded in
`docs/roadmap/source_backed_readiness_audit.md`:

```text
tmp/zig_ir/accepted_20260530_193848_releasefast
tmp/zig_ir/accepted_20260530_195245_releasesafe
tmp/zig_ir/accepted_20260530_201347_releasesmall
```

Each completed with:

```text
processed=1474 compile_skip=1009 emit_ok=465 local_ok=465
input_too_large=0 parse_fail=0 verify_fail=0 optimizer_fail=0
```

Debug parse/verify/optimize remains a conservative boundary for the distribution
matrix because broad raw Debug rows are still future evidence; reduced Debug
metadata rows and the accepted Debug sweep prove only the documented local
subset.

Handoff is conservative for release modes because
`bash scripts/run_handoff_validation.sh` validates selected scalar, memory,
loop, global, stack, and optimized scalar shapes, but not arbitrary accepted
ReleaseFast, ReleaseSafe, or ReleaseSmall optimized output. The focused
ReleaseFast CFG-sensitive optimized-output baseline is:

```text
tmp/zig_ir/optimized_cfg_releasefast_20260530
  mode=ReleaseFast
  target=x86_64-linux-gnu
  passes=zig-release-fast-accepted
  processed=11 emit_ok=11 local_ok=11
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0
  optimized_output=tmp/zig_ir/optimized_cfg_releasefast_20260530/optimized-ir
```

No prior optimized-output artifact directory existed for a historical diff, so
this is a baseline for future canonical-form comparisons rather than evidence
that optimized forms were unchanged across commits.

The first ReleaseFast asm/object fallback reduction tracks the selected empty
optimized module as `test/handoff/inputs/releasefast_empty_module.ll`. The
handoff gate now proves that a metadata-only accepted optimized module emits no
assembly and still produces an x86_64 ELF relocatable object with `.text` and
`.symtab` records.

ReleaseFast asm/object is now a conservative boundary for the captured
Zig-backed optimized-output set recorded in
`docs/roadmap/releasefast_x86_64_object_milestone_1.md`. The broad object probe
over `tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir` has 17
local object successes and 0 failures, with executable validation for the
selected public aliases. It still explicitly excludes target-complete ABI
lowering, arbitrary Zig source outside the captured set, debug/unwind records,
linker ownership, dynamic TLS models, cross-target TLS relocations, and broad
runtime completeness.

Asm/object remains LLVM fallback required for Debug and ReleaseSmall, and for
ReleaseFast and ReleaseSafe outside their named captured subsets.
Existing docs explicitly exclude broad register allocation, scheduling,
debug/unwind object records, linker ownership, and target-complete ABI lowering.

## First Fallback Row

The first implementation target should be:

```text
mode=ReleaseFast
target=x86_64-linux-gnu
stage=asm/object
status=conservative boundary
```

Reason: ReleaseFast is the primary optimizer replacement row and a common Zig
distribution path. The next bounded slice should not attempt broad backend
parity. It should reduce one concrete accepted ReleaseFast optimized-output
shape that cannot pass the existing x86_64 handoff or asm/object validation
subset, then add the smallest fixture and validation gate for that shape.

Milestone 1 selected that row and closed the first subset boundary. Milestone 2
closed the broad captured ReleaseFast object set. The next measured row starts
ReleaseSafe object replacement:

```text
mode=ReleaseSafe
target=x86_64-linux-gnu
stage=asm/object
status=LLVM fallback required
optimized_output=tmp/zig_ir/distribution_m2_releasesafe_20260530/optimized-ir
object_probe=17 ok, 0 fail with --input-limit=67108864
closed_blocker=aggregates.zig.ReleaseSafe.x86_64.optimized.ll selected checked aggregate sums
closed_blocker=atomics_inline_asm_debug.zig.ReleaseSafe.x86_64.optimized.ll selected checked debug_location
closed_blocker=control_flow_calls.zig.ReleaseSafe.x86_64.optimized.ll selected checked loop_sum/call_chain
closed_blocker=error_switch.zig.ReleaseSafe.x86_64.optimized.ll selected straight-line error_switch
closed_blocker=globals_comptime.zig.ReleaseSafe.x86_64.optimized.ll selected checked comptime_const/update_global/read_global
closed_blocker=pointers_memory.zig.ReleaseSafe.x86_64.optimized.ll selected checked load_store
closed_blocker=switch_control.zig.ReleaseSafe.x86_64.optimized.ll selected checked branch_mix plus dense_switch
closed_blocker=tiny_scalar.zig.ReleaseSafe.x86_64.optimized.ll selected checked add plus sideEffectFree
closed_blocker=tls_concurrency.zig.ReleaseSafe.x86_64.optimized.ll selected checked bump_tls plus read_tls
promoted_status=conservative boundary for captured ReleaseSafe optimized-output object subset
```

The next measured row starts ReleaseSmall object replacement:

```text
mode=ReleaseSmall
target=x86_64-linux-gnu
stage=asm/object
status=LLVM fallback required
optimized_output=tmp/zig_ir/distribution_m3_releasesmall_20260531/optimized-ir
optimizer_capture=465 ok, 0 fail, 1009 compile_skip
previous_object_probe=264 ok, 201 fail with --input-limit=67108864
closed_blocker=behavior_export_keyword.zig.ReleaseSmall.x86_64.optimized.ll selected writeToVRam/testPackedStuff
current_object_probe=265 ok, 200 fail with --input-limit=67108864
closed_blocker=behavior_sizeof_and_typeof.zig.ReleaseSmall.x86_64.optimized.ll selected c_fopen/c_ftell/c_fputs/c_printf
first_blocker=c_abi_main.zig.ReleaseSmall.x86_64.optimized.ll
closed_aliases_in_first_blocker=@zig_f128_f128_struct selected C ABI fp128 byval/sret lowering; @zig_f128_struct/@zig_f128 selected fp128 returns; @zig_assert_PD selected return-code branch behavior; @zig_ret_PD selected mixed integer/double return; @zig_ret_CFF selected mixed integer/float return; @zig_assert_CFF selected return-code branch behavior; @zig_ret_DC selected mixed double/integer return; @zig_assert_DC selected return-code branch behavior; @zig_ret_split_struct_mixed selected two-register aggregate return; @zig_ret_med_struct_mixed selected two-register aggregate return; @zig_ret_med_struct_ints selected integer aggregate return; @zig_ret_small_struct_ints existing i32 return; @zig_ret_i64 selected i64 return; @zig_ret_i32 existing i32 return; @zig_ret_i16 selected i16 return; @zig_ret_i8 selected i8 return; @zig_ret_u16 selected zero-extended u16 return; @zig_ret_u8 selected zero-extended u8 return; @zig_ret_bool selected i1 return; @zig_multiple_struct_floats selected vector comparison control-flow; @zig_multiple_struct_ints selected packed-integer comparison control-flow; @zig_big_struct_both selected large byval/sret struct check-and-copy; @zig_split_struct_mixed selected split mixed integer/float comparison control-flow; @zig_split_struct_ints selected split integer struct comparison control-flow; @zig_big_packed_struct selected packed i128 struct comparison control-flow; @zig_small_packed_struct selected packed i8 struct comparison control-flow; @zig_med_struct_ints selected medium integer struct comparison control-flow; @zig_small_struct_ints selected small integer struct comparison control-flow; @zig_med_struct_mixed selected medium mixed struct comparison control-flow; @zig_big_union selected byval aggregate comparison control-flow; @zig_big_struct selected byval aggregate comparison control-flow; @zig_struct_i32_i32 selected packed i32 pair comparison control-flow; @zig_struct_f32_f32f32/@zig_struct_f32f32_f32 selected vector/scalar float struct comparison control-flow; @zig_ret_struct_f32_f32f32/@zig_ret_struct_f32f32_f32 selected vector/scalar float struct return; @zig_struct_f32a8_f32a8 selected vector/scalar float struct comparison control-flow; @zig_ret_struct_f32a8_f32a8 selected vector/scalar float struct return; @zig_struct_f32a8 selected scalar float struct comparison control-flow
missing capability=selected @zig_ret_struct_f32a8 scalar float struct return lowering
```
