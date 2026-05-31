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
| Debug reduced | `test/zig/expected/debug_*.reduced.ll` | 6 | 6 | 0 | 0 | `-` |
| Debug broad tiny scalar | `tmp/zig_ir/debug_object_probe_tiny_scalar_20260531/ir` | 1 | 1 | 0 | 0 | `-` |

ReleaseSmall exclusions:

```text
standalone_emit_llvm_no_bin_main.zig.ReleaseSmall.x86_64.optimized.ll
  reason=float-format-helper-boundary
  boundary=multi-block float-format helper, not a one-slice object reduction

standalone_mix_o_files_base64.zig.ReleaseSmall.x86_64.optimized.ll
  reason=table-decoder-boundary
  boundary=table-driven decoder with broad loop/control-flow lowering
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
| Debug | LLVM fallback required | reduced 6-fixture object subset plus broad `tiny_scalar` object proof; broader Debug remains unproven |

The dashboard does not promote matrix rows by itself. Row status changes belong
in [x86_64_distribution_replacement_matrix.md](x86_64_distribution_replacement_matrix.md)
after a reviewed probe result and explicit boundary decision.

## Remaining Object Gaps

```text
ReleaseSmall excluded:
  standalone_emit_llvm_no_bin_main: float-format helper
  standalone_mix_o_files_base64: table decoder

Debug broad:
  tiny_scalar.Debug.x86_64.ll object-clean as a selected broad row
  control_flow_calls.Debug.ll is the next broad source-backed row to probe
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
