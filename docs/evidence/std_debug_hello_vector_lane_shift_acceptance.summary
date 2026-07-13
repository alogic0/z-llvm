# Packed Vector Lane-Shift Acceptance

schema_version: 1
directive: `INBOX-28`
target: `x86_64-linux`
validation_tier: 2
result: pass

`INBOX-28` is acknowledged. The accepted baseline is commit `ed49ffb4`,
with captured IR md5 `b0eda7a6427c3084fdf096a68696f19c`. The source-only
selector diff used for validation has sha256
`da55a689af762129933a2c7a368a8324bd0574e17a5c24883079c938ce4cd444`.
The current-source z_llvm was built through an isolated cache and prefix and
has sha256
`dc00355f6a7645c37a35a74649bba370c6776716eb3b20f78740b5aebf688272`.

The shared typed packed-two-lane shuffle classifier now admits exactly the
existing lane-0 splat and the constant `<1, poison>` lane shift for f32x2 and
f64x2 values. Lowering reuses `shufps $0x55` for f32x2 and `unpckhpd` for
f64x2. The lane shift defines output lane 0 only when source lane 1 is
defined; output lane 1 remains statically poison. Direct selector tests prove
both full-pair and lane-0-only source propagation. `<1, undef>`, `<0, 3>`,
dynamic masks, cross-input masks, and every other shuffle remain fail-closed.

The permanent f32x2 and f64x2 pressure canaries now execute the lane shift.
Each runs five input pairs covering signed zeros, finite values, signed
minimum subnormals, infinities, and quiet NaNs with payloads. All 170 output
words match exactly, including ten direct lane-shift results, while the
existing pair-slot spill and reload pressure remains active.

Fresh report-all remains 443 selected / 202 emitting / 241 failing. The seven
directed rows do not close: `compiler_rt.log2.__log2h`, `log2`, `log2f`,
`compiler_rt.log10.__log10h`, `log10f`, `compiler_rt.log.__logh`, and `logf`
advance from the excluded lane-shift mask to their concrete scalar `sitofp`
instructions. Collateral `compiler_rt.log10.log10` advances to `sitofp`
without a semantic or closure claim. `compiler_rt.log.log` still stops at
packed `fsub`. Because no row closes and no shared boundary changes, Tier 3
is not triggered.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=202 failed_functions=241 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused tests: unit=906/906 f64x2_cases=5/5 f32x2_cases=5/5 exact_output_words=170/170 lane_shift_words=10/10 near_miss_masks=2/2
tier2: pass; steps=24/24 tests=914/914 structural=8/8 selected object/executable modes=pass integrated_executable=5/5
tier3: not-triggered; no row closure or shared subsystem boundary
```

Commands:

```text
zig build test --summary all
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
zig build -Doptimize=ReleaseFast --cache-dir tmp/inbox28_zig_cache --prefix tmp/inbox28_install
tmp/inbox28_install/bin/z_llvm --emit=obj --target=x86_64-linux --passes=zig-debug-accepted --input-limit=67108864 --report-all-codegen-failures --generic-cfg-selector tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll
```

Logs: `tmp/inbox28_lane_shift_tier2.log` (sha256
`f5c0feac04854651f573220f7dfef08c6c313b0a5cd73aa920a15df8f14545ab`)
and `tmp/inbox28_lane_shift_report.log` (sha256
`f960880cbf8d6e02490196ebe745563ceb3d7d8342117657be9addcd07d0f2c9`).

The pre-authorized packed-fsub successor remains available. This cycle makes
no claim for the seven expected row closures because the captured bodies
expose `sitofp` after the lane shift.
