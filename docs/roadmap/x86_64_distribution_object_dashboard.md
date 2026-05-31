# x86_64 Distribution Object Dashboard

This dashboard tracks object-stage evidence for the current
`x86_64-linux-gnu` distribution replacement path. It summarizes automated
broad probes, focused gates, executable coverage, and explicit exclusions.

## Automated Probe

Probe helper:

```text
bash scripts/probe_distribution_objects.sh
```

Current automated summaries:

| Mode | Input | Total | Object OK | Object Fail | Excluded | First Failure |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| ReleaseFast | `tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir` | 17 | 17 | 0 | 0 | `-` |
| ReleaseSafe | `tmp/zig_ir/distribution_m2_releasesafe_20260530/optimized-ir` | 17 | 17 | 0 | 0 | `-` |
| ReleaseSmall | `tmp/zig_ir/distribution_m3_releasesmall_20260531/optimized-ir` | 465 | 463 | 0 | 2 | `-` |
| Debug reduced | `test/zig/expected/debug_*.reduced.ll` | 9 | 9 | 0 | 0 | `-` |
| Debug broad tiny scalar | `tmp/zig_ir/debug_object_probe_tiny_scalar_20260531/ir` | 1 | 1 | 0 | 0 | `-` |
| Debug broad control flow calls | `tmp/zig_ir/debug_object_probe_control_flow_calls_20260531/ir` | 1 | 1 | 0 | 0 | `-` |
| Debug broad pointers memory | `tmp/zig_ir/debug_object_probe_pointers_memory_20260531/ir` | 1 | 1 | 0 | 0 | `-` |
| Debug broad tiny scalar plain | `tmp/zig_ir/debug_object_probe_tiny_scalar_plain_20260531/ir` | 1 | 1 | 0 | 0 | `-` |
| Debug continuous prefix 100 | `tmp/zig_ir/debug_object_probe_continuous_prefix100_20260531/ir` | 100 | 100 | 0 | 0 | `-` |
| Debug continuous prefix 200 | `tmp/zig_ir/debug_object_probe_continuous_prefix200_20260531/ir` | 200 | 200 | 0 | 0 | `-` |
| Debug continuous prefix 300 | `tmp/zig_ir/debug_object_probe_continuous_prefix300_20260531/ir` | 300 | 300 | 0 | 0 | `-` |
| Debug continuous prefix 400 | `tmp/zig_ir/debug_object_probe_continuous_prefix400_20260531/ir` | 400 | 396 | 3 | 1 | `standalone_libfuzzer_main.zig.Debug.x86_64.ll` |

ReleaseSmall exclusions:

```text
standalone_emit_llvm_no_bin_main.zig.ReleaseSmall.x86_64.optimized.ll
  reason=float-format-helper-boundary
  boundary=multi-block float-format helper, not a one-slice object reduction
  direct_probe=tmp/zig_ir/releasesmall_exclusion_emit_llvm_no_bin_20260531/ir
  result=1 fail, category=unsupported-control-flow

standalone_mix_o_files_base64.zig.ReleaseSmall.x86_64.optimized.ll
  reason=table-decoder-boundary
  boundary=table-driven decoder with broad loop/control-flow lowering
  direct_probe=tmp/zig_ir/releasesmall_exclusion_mix_o_files_base64_20260531/ir
  result=1 fail, category=unsupported-control-flow
```

## Focused Gates

| Gate | Coverage | Latest Result |
| --- | --- | --- |
| `bash scripts/run_distribution_object_m1.sh` | selected ReleaseFast objects | pass |
| `bash scripts/run_distribution_executable_m1.sh` | selected ReleaseFast executable ABI checks | pass |
| `bash scripts/run_distribution_releasesafe_object_m2.sh` | selected ReleaseSafe safety/runtime-call objects | pass |
| `bash scripts/run_distribution_releasesmall_object_m3.sh` | selected ReleaseSmall object subset | pass |
| `bash scripts/run_distribution_debug_object_m4.sh` | reduced Debug objects | pass |
| `bash scripts/run_handoff_validation.sh` | optimizer-to-codegen handoff smoke coverage | pass |
| `bash scripts/run_distribution_no_llvm_codegen_subset.sh` | selected no-LLVM-codegen distribution subset | pass |

## Matrix Boundary

| Mode | Asm/Object Status | Boundary |
| --- | --- | --- |
| ReleaseFast | conservative boundary | captured 17-row optimized-output object set, selected executable proof |
| ReleaseSafe | conservative boundary | captured 17-row optimized-output object set, selected safety/runtime-call objects |
| ReleaseSmall | conservative boundary | adjusted 463-row object-clean subset with 2 explicit exclusions |
| Debug | LLVM fallback required | reduced 9-fixture object subset plus selected broad raw and continuous-prefix object proof; broader Debug std rows remain unproven |

The dashboard does not promote matrix rows by itself. Row status changes belong
in [x86_64_distribution_replacement_matrix.md](x86_64_distribution_replacement_matrix.md)
after a reviewed probe result and explicit boundary decision.

## Remaining Object Gaps

```text
ReleaseSmall excluded:
  standalone_emit_llvm_no_bin_main: float-format helper
    direct no-exclusion probe fails unsupported-control-flow
  standalone_mix_o_files_base64: table decoder
    direct no-exclusion probe fails unsupported-control-flow

Debug broad:
  tiny_scalar.Debug.x86_64.ll object-clean as a selected broad row
  control_flow_calls.Debug.ll object-clean as a selected broad row
  pointers_memory.Debug.ll object-clean after the selected O0 alloca debug
    prologue plus volatile roundtrip fixture
  tiny_scalar.Debug.ll object-clean as the remaining selected raw row
  continuous Debug prefix 100 object-clean after selected panic-call C stubs
  continuous Debug prefix 200 now advances past c_abi_main.zig.Debug.x86_64.ll
    after selected Debug/O0 C ABI aliases, aggregate stack returns, scalar
    returns, selected packed struct/union shapes, and panic-call stubs
  continuous Debug prefix 200 also advances past selected address-space
    pointer rows after accepting the Debug/O0 start trampoline trap tail and
    Debug/O0 getauxval auxv scan shape
  continuous Debug prefix 200 also advances past
    cases_compile_errors_illegal_operation_on_logical_ptr.zig.Debug.x86_64.ll
    after the selected object-only Debug/O0 logical-pointer compile-error
    fixture
  continuous Debug prefix 200 also advances past
    cases_compile_errors_spirv_merge_logical_pointers.zig.Debug.x86_64.ll
    after the selected object-only Debug/O0 SPIR-V logical-pointer merge
    fixture
  continuous Debug prefix 200 also advances past
    cases_inherit_want_safety.zig.Debug.x86_64.ll after selected Debug/O0
    counter-control-flow lowering to the ABI-visible i64 return value
  continuous Debug prefix 200 also advances past
    cases_no_compile_panic_for_unchecked_arith.zig.Debug.x86_64.ll after
    selected Debug/O0 unchecked/saturating arithmetic chain lowering to the
    ABI-visible i64 return value
  continuous Debug prefix 200 is object-clean
  continuous Debug prefix 300 is object-clean
  continuous Debug prefix 400 now advances past
    standalone_compile_asm_main.zig.Debug.x86_64.ll after accepting the
    selected Debug/O0 panic-unreachable entry shape; the refreshed prefix-400
    probe then advanced to standalone_emit_llvm_no_bin_main.zig.Debug.x86_64.ll
    as the first remaining failure
  continuous Debug prefix 400 excludes
    standalone_emit_llvm_no_bin_main.zig.Debug.x86_64.ll under the
    debug-float-format-helper-boundary, matching the existing ReleaseSmall
    float-format helper boundary for @strFromFloatHelp
  continuous Debug prefix 400 now advances past
    standalone_issue_339_test.zig.Debug.x86_64.ll after selected Debug/O0
    @foo -> @test.foo error-success edge lowering; the refreshed prefix-400
    probe is 396 object successes, 3 object failures, and 1 excluded row, with
    standalone_libfuzzer_main.zig.Debug.x86_64.ll as the first remaining
    failure
  DWARF/unwind emission
  full O0 codegen surface
  variable-location salvage
  broad std Debug rows
  target-complete ABI lowering

Global exclusions:
  broad register allocation
  scheduling
  linker ownership
  dynamic TLS models
  non-x86_64 object formats
```
