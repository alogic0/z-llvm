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
| Debug | conservative boundary | conservative boundary | conservative boundary | conservative boundary | conservative boundary |
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

Debug asm/object is a conservative boundary for the adjusted continuous
captured subset, not target-complete Debug backend ownership. A bounded reduced
object probe is also clean for selected Debug fixtures:

```text
bash scripts/run_distribution_debug_object_m4.sh
  target=x86_64-unknown-linux-gnu
  inputs=test/zig/expected/debug_*.reduced.ll plus selected Debug/O0
         distribution fixtures
  object_probe=pass
  covered_shapes=call-chain add-immediate, dbg.declare/dbg.value no-op object
                 lowering, simple loop sum, metadata add, scope branch phi,
                 O0 alloca debug prologue plus volatile pointer roundtrip,
                 Debug/O0 c_* panic-call unreachable stubs,
                 Debug/O0 f128 sret C ABI shape,
                 selected Debug/O0 libfuzzer runner aliases
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

source=tmp/zig_ir/continuous_20260530_151319_debug/report.tsv first 100 optimizer-ok rows
probe=tmp/zig_ir/debug_object_probe_continuous_prefix100_20260531/ir
object_probe=100 ok, 0 fail
closed_boundary=Debug/O0 sizeof_and_typeof c_* panic-call unreachable stubs

source=tmp/zig_ir/continuous_20260530_151319_debug/report.tsv first 200 optimizer-ok rows
probe=tmp/zig_ir/debug_object_probe_continuous_prefix200_20260531/ir
object_probe=200 ok, 0 fail
first_failure=-
first_failure_category=-
closed_blocker=c_abi_main.zig.Debug.x86_64.ll
closed_boundary=selected Debug/O0 C ABI aliases, stack-materialized aggregate
                returns, scalar returns, packed struct/union checks, and
                panic-call stubs; selected Debug/O0 start trampoline trap tail
                and getauxval auxv scan shape; selected object-only Debug/O0
                logical-pointer compile-error and SPIR-V logical-pointer merge
                fixtures; selected Debug/O0 inherit_want_safety counter return;
                selected Debug/O0 unchecked/saturating arithmetic chain return

source=tmp/zig_ir/continuous_20260530_151319_debug/report.tsv first 300 optimizer-ok rows
probe=tmp/zig_ir/debug_object_probe_continuous_prefix300_20260531/ir
object_probe=300 ok, 0 fail
first_failure=-
first_failure_category=-

source=tmp/zig_ir/continuous_20260530_151319_debug/report.tsv first 400 optimizer-ok rows
probe=tmp/zig_ir/debug_object_probe_continuous_prefix400_20260531/ir
object_probe=399 ok, 0 fail, 1 excluded
excluded=standalone_emit_llvm_no_bin_main.zig.Debug.x86_64.ll
excluded_reason=debug-float-format-helper-boundary
first_failure=-
first_failure_category=-
closed_boundary=selected Debug/O0 panic-unreachable compile-asm entry,
                issue-339 error-success edge, libfuzzer runner aliases, and
                dynamic-library checked add; selected Debug/O0 mix-C
                add_zig/add_may_panic checked-add and panic-edge lowering

source=tmp/zig_ir/continuous_20260530_151319_debug/report.tsv all 465 optimizer-ok rows
probe=tmp/zig_ir/debug_object_probe_continuous_full465_20260531/ir
object_probe=463 ok, 0 fail, 2 excluded
excluded=standalone_emit_llvm_no_bin_main.zig.Debug.x86_64.ll
excluded_reason=debug-float-format-helper-boundary
excluded=standalone_mix_o_files_base64.zig.Debug.x86_64.ll
excluded_reason=debug-table-decoder-boundary
first_failure=-
first_failure_category=-
closed_boundary=Debug/O0 base64 table decoder matches the existing
                ReleaseSmall table-decoder boundary for @decode_base_64
closed_blocker=standalone_shared_library_mathtest.zig.Debug.x86_64.ll
               selected @add -> @mathtest.add checked add with panic edge
```

Debug handoff is a conservative boundary for the selected Debug/O0 handoff
fixture in `bash scripts/run_handoff_validation.sh`:

```text
source=test/distribution/debug_x86_64/inputs/shared_library_mathtest_add_o0.ll
gate=bash scripts/run_handoff_validation.sh
handoff_case=debug_o0_mathtest_checked_add
checks=emit asm, checked-add branch, panic-call relocation, ELF relocatable
boundary=selected Debug/O0 checked-add handoff only; not broad Debug codegen,
         debug/unwind records, or target-complete ABI lowering
```

Debug object support explicitly excludes DWARF and unwind section ownership:

```text
gate=bash scripts/run_distribution_debug_unwind_boundary.sh
targets=x86_64-unknown-linux-gnu, x86_64-unknown-linux-musl
source_fixture=test/zig/expected/debug_metadata.reduced.ll
result=pass, object has .text but no .debug_* or .eh_frame sections
boundary=selected Debug object lowering only; not DWARF, CFI, unwind tables,
         variable-location salvage, or debugger-quality metadata emission
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
  includes=ReleaseFast object/executable gates, ReleaseSafe object/executable gate,
           selected ReleaseSmall object/executable gates, selected Debug
           object/executable gates, handoff validation
  result=pass
```

Link/LTO handoff remains a deferred boundary rather than an implementation row
for the selected x86_64 distribution subset:

```text
source=docs/bitcode/lto_compatibility_decision.md
source=docs/bitcode/construct_inventory.md
source=docs/lto/behavior_gaps.md
validation=zig build test
covered=LTO pre-link pipeline descriptors, text-IR optimizer surface
not_covered=bitcode writer/parser, LTO linker handoff bitcode, ThinLTO
            summaries, combined indexes, import/export, WPD, CFI, post-link LTO
status=deferred until a source-backed activation criterion requires bitcode or
       linker LTO handoff
```

The selected x86_64 musl object subset is a target-boundary proof. It also
inherits the selected ReleaseSafe executable harnesses embedded in the M2 gate,
but does not claim broad executable or linker replacement for musl:

```text
gate=bash scripts/run_distribution_x86_64_musl_object_subset.sh
target=x86_64-unknown-linux-musl
includes=ReleaseFast object gate, ReleaseSafe object gate,
         ReleaseSmall object gate, selected Debug object gate
result=pass
boundary=no broad musl executable harnesses, linker ownership, CRT/start files,
         libc integration, or dynamic loader behavior
```

The selected x86_64 musl executable subset is also target-backed for stable ABI
fixtures:

```text
gate=bash scripts/run_distribution_x86_64_musl_executable_subset.sh
target=x86_64-unknown-linux-musl
cc_target=x86_64-linux-musl
includes=ReleaseFast executable gate, selected ReleaseSafe M2
         safety/runtime-call executable harnesses, selected ReleaseSmall M3
         executable harnesses, selected Debug mathtest executable gate
result=pass
boundary=no broad musl executable expansion beyond selected harnesses; no
         linker ownership, CRT policy, libc integration, or dynamic loader
         behavior beyond the selected harnesses
```

The linker/CRT boundary is now explicit and validated:

```text
gate=bash scripts/run_distribution_linker_boundary.sh
local_emit_modes=ir, asm, obj
rejected_emit_mode=exe
executable_validation_handoff=zig cc -target "$cc_target"
result=pass
boundary=no local executable emission, CRT/start-file policy, libc integration,
         dynamic loader behavior, archive ownership, or linker script handling
```

AArch64 object emission is an explicit target boundary for the current
distribution matrix:

```text
gate=bash scripts/run_distribution_aarch64_object_boundary.sh
target=aarch64-unknown-linux-gnu
source_fixture=test/distribution/releasefast_x86_64/inputs/tiny_scalar.ll
result=pass, rejected with unsupported codegen target
boundary=local object emission is x86_64-linux only; AArch64 parse/verify/
         optimize evidence does not imply backend, ABI, relocation, or object
         ownership
```

The current conservative boundary gates are composed by:

```text
gate=bash scripts/run_distribution_boundary_gates.sh
includes=linker/CRT boundary, tracked ReleaseSmall exclusion boundaries,
         Debug DWARF/unwind boundary, AArch64 object target boundary
result=pass
```

The combined selected distribution validation entrypoint is:

```text
gate=bash scripts/run_distribution_all_gates.sh
includes=selected no-LLVM-codegen object/executable subset,
         conservative boundary gates
result=pass
```

Automated broad object probing is now available through:

```text
bash scripts/probe_distribution_objects.sh
  implementation=tools/probe_distribution_objects.zig
  ReleaseFast:  total=17  ok=17  fail=0 excluded=0 first_failure=-
  ReleaseSafe:  total=17  ok=17  fail=0 excluded=0 first_failure=-
  ReleaseSmall: total=465 ok=463 fail=0 excluded=2 first_failure=-
  ReleaseSmall excluded rows:
    standalone_emit_llvm_no_bin_main.zig.ReleaseSmall.x86_64.optimized.ll
      reason=float-format-helper-boundary
      direct_probe=tmp/zig_ir/releasesmall_exclusion_emit_llvm_no_bin_20260531/ir
      tracked_fixture=test/distribution/releasesmall_x86_64/exclusions/standalone_emit_llvm_no_bin_str_from_float_help.ll
      result=1 fail, category=unsupported-control-flow
    standalone_mix_o_files_base64.zig.ReleaseSmall.x86_64.optimized.ll
      reason=table-decoder-boundary
      direct_probe=tmp/zig_ir/releasesmall_exclusion_mix_o_files_base64_20260531/ir
      tracked_fixture=test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll
      result=1 fail, category=unsupported-control-flow
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
boundary_probe=tmp/zig_ir/releasesmall_exclusion_emit_llvm_no_bin_20260531/ir total=1 ok=0 fail=1 category=unsupported-control-flow
tracked_boundary_fixture=test/distribution/releasesmall_x86_64/exclusions/standalone_emit_llvm_no_bin_str_from_float_help.ll
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
boundary_probe=tmp/zig_ir/releasesmall_exclusion_mix_o_files_base64_20260531/ir total=1 ok=0 fail=1 category=unsupported-control-flow
tracked_boundary_fixture=test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll
focused_boundary_gate=bash scripts/run_distribution_releasesmall_boundary_m3.sh
current_adjusted_object_probe=463 ok, 0 fail, 2 excluded with --input-limit=67108864
ReleaseSmall asm/object status=conservative boundary for named captured subset with explicit exclusions
```
