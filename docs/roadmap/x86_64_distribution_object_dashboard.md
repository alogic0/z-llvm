# x86_64 Distribution Object Dashboard

This dashboard tracks object-stage evidence for the current
`x86_64-linux-gnu` distribution replacement path. It summarizes automated
broad probes, focused gates, executable coverage, and explicit exclusions.

## Automated Probe

Probe helper:

```text
zig build probe-distribution-objects --
```

The helper builds `z_llvm` once and invokes `zig-out/bin/z_llvm` directly, so
failure logs preserve the local codegen diagnostic and function name for
source-backed blocker selection. The public shell command is a compatibility
shim over `tools/probe_distribution_objects.zig`.

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
| Debug continuous prefix 400 | `tmp/zig_ir/debug_object_probe_continuous_prefix400_20260531/ir` | 400 | 399 | 0 | 1 | `-` |
| Debug continuous full 465 | `tmp/zig_ir/debug_object_probe_continuous_full465_20260531/ir` | 465 | 463 | 0 | 2 | `-` |

ReleaseSmall exclusions:

```text
standalone_emit_llvm_no_bin_main.zig.ReleaseSmall.x86_64.optimized.ll
  reason=float-format-helper-boundary
  boundary=multi-block float-format helper, not a one-slice object reduction
  direct_probe=tmp/zig_ir/releasesmall_exclusion_emit_llvm_no_bin_20260531/ir
  tracked_fixture=test/distribution/releasesmall_x86_64/exclusions/standalone_emit_llvm_no_bin_str_from_float_help.ll
  result=1 fail, category=unsupported-control-flow

standalone_mix_o_files_base64.zig.ReleaseSmall.x86_64.optimized.ll
  reason=table-decoder-boundary
  boundary=table-driven decoder with broad loop/control-flow lowering
  direct_probe=tmp/zig_ir/releasesmall_exclusion_mix_o_files_base64_20260531/ir
  tracked_fixture=test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll
  result=1 fail, category=unsupported-control-flow
```

## Focused Gates

| Gate | Coverage | Latest Result |
| --- | --- | --- |
| `zig build distribution-object` | selected ReleaseFast objects | pass |
| `zig build distribution-executable` | selected ReleaseFast executable ABI checks | pass |
| `zig build distribution-releasesafe-object` | selected ReleaseSafe safety/runtime-call objects plus executable ABI checks | pass for GNU and musl targets |
| `zig build distribution-releasesmall-object` | selected ReleaseSmall object subset | pass |
| `zig build distribution-releasesmall-executable` | selected ReleaseSmall executable ABI checks | pass for GNU and musl targets |
| `zig build distribution-releasesmall-boundary` | tracked ReleaseSmall exclusion boundary fixtures | pass for GNU and musl targets |
| `zig build distribution-debug-object` | reduced Debug objects plus selected Debug/O0 distribution objects | pass |
| `zig build distribution-debug-executable` | selected Debug executable ABI proof | pass |
| `zig build distribution-debug-unwind` | selected Debug object boundary: no DWARF or unwind sections emitted | pass for GNU and musl targets |
| `zig build handoff` | optimizer-to-codegen handoff smoke coverage plus selected Debug/O0 handoff | pass |
| `zig build distribution-no-llvm` | selected no-LLVM-codegen distribution subset, including ReleaseSmall and Debug executable gates | pass |
| `zig build distribution-native-link` | selected native Zig linker handoff proof for ABI-stable ReleaseFast, ReleaseSafe, ReleaseSmall, and Debug/O0 objects, using `zig build-exe -fno-lld` | pass |
| `zig build probe-native-linker` | selected native Zig linker compatibility probe for the same ABI-stable object set; classifies first failure by symbol, relocation, section, TLS model, COMDAT, alignment, ABI, or unknown linker compatibility | pass, 40 accepted / 0 failed |
| `zig build distribution-native-link-releasefast` | ReleaseFast native-link proof for the full current executable harness set | pass, 27 executed |
| `zig build distribution-native-link-releasesafe` | ReleaseSafe native-link proof for the full current executable ABI set | pass, 9 executed |
| `zig build distribution-native-link-releasesmall` | selected ReleaseSmall native-link proof | pass, 3 executed |
| `zig build distribution-native-link-debug` | selected Debug/O0 native-link proof | pass, 1 executed |
| `zig build probe-native-linker-releasefast` | ReleaseFast native-link compatibility probe for the full current executable harness set | pass, 27 accepted / 0 failed |
| `zig build probe-native-linker-releasesafe` | ReleaseSafe native-link compatibility probe for the full current executable ABI set | pass, 9 accepted / 0 failed |
| `zig build probe-native-linker-releasesmall` | selected ReleaseSmall native-link compatibility probe | pass, 3 accepted / 0 failed |
| `zig build probe-native-linker-debug` | selected Debug/O0 native-link compatibility probe | pass, 1 accepted / 0 failed |
| `zig build distribution-musl-object` | selected x86_64 musl object subset plus embedded ReleaseSafe ABI checks, no broad Zig-linker integration proof | pass |
| `zig build distribution-musl-executable` | selected x86_64 musl executable subset including ReleaseFast, ReleaseSafe M2, ReleaseSmall M3, and Debug fixtures | pass |
| `zig build distribution-linker-boundary` | explicit linker/CRT ownership boundary: local emit modes stop at `ir`/`asm`/`obj`, executable gates hand local objects to Zig's linker/toolchain through `zig cc` | pass |
| `zig build distribution-aarch64-boundary` | explicit non-x86_64 object boundary for AArch64 Linux | pass |
| `zig build distribution-boundary` | composed conservative boundary gates: linker, ReleaseSmall exclusions, Debug unwind, AArch64 object target | pass |
| `zig build distribution-all` | selected positive no-LLVM-codegen subset plus native-link proof/probe and conservative boundary gates | pass |

## Matrix Boundary

| Mode | Asm/Object Status | Boundary |
| --- | --- | --- |
| ReleaseFast | conservative boundary | captured 17-row optimized-output object set, selected executable proof |
| ReleaseSafe | conservative boundary | captured 17-row optimized-output object set, selected safety/runtime-call executable proof |
| ReleaseSmall | conservative boundary | adjusted 463-row object-clean subset with 2 explicit exclusions, selected executable proof |
| Debug | conservative boundary | adjusted continuous 463-row object-clean subset with 2 explicit exclusions |

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
  continuous Debug prefix 400 now advances past
    standalone_libfuzzer_main.zig.Debug.x86_64.ll after the selected Debug/O0
    libfuzzer runner alias fixture covers alloca/extractvalue slice
    materialization, llvm.memcpy, and fuzzer_* call relocations; the refreshed
    prefix-400 probe is 397 object successes, 2 object failures, and 1
    excluded row, with standalone_load_dynamic_library_add.zig.Debug.x86_64.ll
    as the first remaining failure
  continuous Debug prefix 400 now advances past
    standalone_load_dynamic_library_add.zig.Debug.x86_64.ll after reusing the
    selected checked-add overflow lowering for @add -> @add.add; the refreshed
    prefix-400 probe is 398 object successes, 1 object failure, and 1 excluded
    row, with standalone_mix_c_files_main.zig.Debug.x86_64.ll as the first
    remaining failure
  continuous Debug prefix 400 now advances past
    standalone_mix_c_files_main.zig.Debug.x86_64.ll after selected Debug/O0
    mix-C add_zig/add_may_panic checked-add and panic-edge lowering; the
    refreshed prefix-400 probe is 399 object successes, 0 object failures, and
    1 excluded row
  continuous Debug full 465 uses the full available optimizer-ok Debug corpus
    from tmp/zig_ir/continuous_20260530_151319_debug/report.tsv; the adjusted
    probe is 463 object successes, 0 object failures, and 2 excluded rows
  continuous Debug full 465 excludes
    standalone_mix_o_files_base64.zig.Debug.x86_64.ll under the
    debug-table-decoder-boundary, matching the existing ReleaseSmall base64
    table-decoder boundary for @decode_base_64 -> @base64.decode_base_64
  continuous Debug full 465 now advances past
    standalone_shared_library_mathtest.zig.Debug.x86_64.ll after selected
    Debug/O0 mathtest.add checked-add and panic-edge lowering
  DWARF/unwind emission
    focused_gate=zig build distribution-debug-unwind
  full O0 codegen surface
  variable-location salvage
  broad std Debug rows
  target-complete ABI lowering

Global exclusions:
  broad register allocation
  scheduling
  final executable/library/archive linking owned by Zig's linker/toolchain
  executable emission in `z_llvm` (`--emit=exe` is rejected by the linker
    boundary gate; final links are delegated to Zig's linker/toolchain)
  x86_64 musl executable proof outside selected ReleaseFast, ReleaseSafe,
    ReleaseSmall, and Debug executable fixtures; broad linker/CRT/libc
    ownership remains Zig-owned
  native Zig linker proof outside the selected `zig build distribution-native-link`
    and `zig build probe-native-linker` subset
  bitcode/LTO artifact handoff to Zig's linker/toolchain until activation
    criteria are met
  dynamic TLS models
  non-x86_64 object formats
  AArch64 object emission (`--emit=obj --target=aarch64-unknown-linux-gnu`
    fails closed at the target boundary)
```
