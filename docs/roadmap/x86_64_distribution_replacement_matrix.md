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
| ReleaseSmall | local replacement | local replacement | local replacement | conservative boundary | conservative boundary |

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

Debug asm/object remains `LLVM fallback required` for the broad row. A bounded
reduced object probe is now clean for selected Debug fixtures:

```text
bash scripts/run_distribution_debug_object_m4.sh
  target=x86_64-unknown-linux-gnu
  inputs=test/zig/expected/debug_*.reduced.ll
  object_probe=7 ok, 0 fail
  covered_shapes=call-chain add-immediate, dbg.declare/dbg.value no-op object
                 lowering, simple loop sum, metadata add, scope branch phi,
                 O0 alloca debug prologue plus volatile pointer roundtrip
  excluded=DWARF/unwind emission, full O0 codegen, variable-location salvage,
           broad Debug std rows, target-complete ABI lowering
```

The selected broad raw Debug rows also have object evidence:

```text
source=tmp/zig_ir/raw/tiny_scalar.Debug.x86_64.ll
probe=tmp/zig_ir/debug_object_probe_tiny_scalar_20260531/ir
object_probe=1 ok, 0 fail
closed_boundaries=#dbg_* records dropped as non-semantic object records,
                  ret/unreachable metadata accepted, sizeless DIBasicType,
                  columnless DILocation

source=tmp/zig_ir/raw/control_flow_calls.Debug.ll
probe=tmp/zig_ir/debug_object_probe_control_flow_calls_20260531/ir
object_probe=1 ok, 0 fail

source=tmp/zig_ir/raw/pointers_memory.Debug.ll
probe=tmp/zig_ir/debug_object_probe_pointers_memory_20260531/ir
object_probe=1 ok, 0 fail
closed_boundary=selected O0 alloca debug prologue before volatile pointer
                store/load roundtrip

source=tmp/zig_ir/raw/tiny_scalar.Debug.ll
probe=tmp/zig_ir/debug_object_probe_tiny_scalar_plain_20260531/ir
object_probe=1 ok, 0 fail
```

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

The first named no-LLVM-codegen x86_64 distribution subset gate is:

```text
bash scripts/run_distribution_no_llvm_codegen_subset.sh
  target=x86_64-unknown-linux-gnu
  includes=ReleaseFast object/executable gates, ReleaseSafe object gate,
           selected ReleaseSmall object gate, handoff validation
  result=pass
```

Automated broad object probing is now available through:

```text
bash scripts/probe_distribution_objects.sh
  ReleaseFast:  total=17  ok=17  fail=0 excluded=0 first_failure=-
  ReleaseSafe:  total=17  ok=17  fail=0 excluded=0 first_failure=-
  ReleaseSmall: total=465 ok=463 fail=0 excluded=2 first_failure=-
  ReleaseSmall excluded rows:
    standalone_emit_llvm_no_bin_main.zig.ReleaseSmall.x86_64.optimized.ll
      reason=float-format-helper-boundary
    standalone_mix_o_files_base64.zig.ReleaseSmall.x86_64.optimized.ll
      reason=table-decoder-boundary
```

The compact object-stage dashboard is
`docs/roadmap/x86_64_distribution_object_dashboard.md`.

Asm/object remains LLVM fallback required for broad Debug, and for ReleaseFast,
ReleaseSafe, and ReleaseSmall outside their named captured subsets. Existing
docs explicitly exclude broad register allocation, scheduling, debug/unwind
object records, linker ownership, and target-complete ABI lowering.

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
intermediate_object_probe=265 ok, 200 fail with --input-limit=67108864
closed_blocker=behavior_sizeof_and_typeof.zig.ReleaseSmall.x86_64.optimized.ll selected c_fopen/c_ftell/c_fputs/c_printf
closed_blocker=c_abi_main.zig.ReleaseSmall.x86_64.optimized.ll selected public aliases through @zig_panic
intermediate_object_probe=266 ok, 199 fail with --input-limit=67108864
closed_blocker=cases_address_space_pointer_access_chaining_pointer_to_optional_array.zig.ReleaseSmall.x86_64.optimized.ll selected @_start -> @start._start startup trampoline
intermediate_object_probe=327 ok, 138 fail with --input-limit=67108864
closed_blocker=cases_array_in_anon_struct.zig.ReleaseSmall.x86_64.optimized.ll selected @getauxval -> @os.linux.getauxvalImpl auxv scan
intermediate_object_probe=455 ok, 10 fail with --input-limit=67108864
closed_blocker=cases_compile_errors_illegal_operation_on_logical_ptr.zig.ReleaseSmall.x86_64.optimized.ll selected @elemPtr -> @illegal_operation_on_logical_ptr.elemPtr
intermediate_object_probe=456 ok, 9 fail with --input-limit=67108864
closed_blocker=cases_inherit_want_safety.zig.ReleaseSmall.x86_64.optimized.ll selected @entry -> @inherit_want_safety.entry i64 constant return
intermediate_object_probe=457 ok, 8 fail with --input-limit=67108864
closed_blocker=cases_no_compile_panic_for_unchecked_arith.zig.ReleaseSmall.x86_64.optimized.ll selected @entry -> @no_compile_panic_for_unchecked_arith.entry llvm.umul.fix.sat.i64 constant-call return
intermediate_object_probe=458 ok, 7 fail with --input-limit=67108864
closed_blocker=standalone_compile_asm_main.zig.ReleaseSmall.x86_64.optimized.ll selected @main -> @main.main empty noreturn unreachable stub
boundary_exclusion=standalone_emit_llvm_no_bin_main.zig.ReleaseSmall.x86_64.optimized.ll selected @strFromFloatHelp -> @main.strFromFloatHelp multi-block float-format helper
closed_blocker=standalone_extern_exports.zig.ReleaseSmall.x86_64.optimized.ll selected @getHidden/@updateHidden hidden i32 global access
intermediate_adjusted_object_probe=460 ok, 4 fail, 1 excluded with --input-limit=67108864
closed_blocker=standalone_install_raw_hex_main.zig.ReleaseSmall.x86_64.optimized.ll selected @_start -> @main._start two-block infinite loop
intermediate_adjusted_object_probe=461 ok, 3 fail, 1 excluded with --input-limit=67108864
closed_blocker=standalone_libfuzzer_main.zig.ReleaseSmall.x86_64.optimized.ll selected libfuzzer runner aliases
closed_alias_in_blocker=@runner_futex_wait -> @main.runner_futex_wait i1 constant return
closed_alias_in_blocker=@runner_test_name -> @main.runner_test_name string-slice aggregate return
closed_alias_in_blocker=@runner_test_run -> @main.runner_test_run selected runtime-call lowering
intermediate_adjusted_object_probe=462 ok, 2 fail, 1 excluded with --input-limit=67108864
closed_blocker=standalone_mix_c_files_main.zig.ReleaseSmall.x86_64.optimized.ll selected mix-C aliases
closed_alias_in_blocker=@add_zig -> @main.add_zig mixed Zig/C global-add i32 return
closed_alias_in_blocker=@add_may_panic -> @main.add_may_panic checked add/panic branch
intermediate_adjusted_object_probe=463 ok, 1 fail, 1 excluded with --input-limit=67108864
boundary_exclusion=standalone_mix_o_files_base64.zig.ReleaseSmall.x86_64.optimized.ll selected @decode_base_64 -> @base64.decode_base_64 table-driven multi-block decoder
current_adjusted_object_probe=463 ok, 0 fail, 2 excluded with --input-limit=67108864
ReleaseSmall asm/object status=conservative boundary for named captured subset with explicit exclusions
```
