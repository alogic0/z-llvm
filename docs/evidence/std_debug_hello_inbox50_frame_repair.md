# INBOX-50 Preservation-Frame Repair Acceptance

schema_version: 1
directive: `INBOX-50 Part 1`
target: `x86_64-linux`
validation_tier: 3
result: pass
closure_status: accepted after the immediate Tier 3 recorded separately

The accepted baseline is INBOX-49 at 443 selected / 267 emitting / 176
failing. The captured compiler_rt IR md5 is
`b0eda7a6427c3084fdf096a68696f19c`, and the stage4 pin is
`bdee02bc0c7f227c0f11bc9a449df673fe803540`.

The stage-two allocation plan now records the maximum scalar spill demand at
selection-time preservation barriers in addition to ordinary interval
pressure. Shared frame preparation reserves its existing spill area when
that demand is nonzero. For single-block framed functions, only parameters
that are live across a recorded barrier receive stable frame homes;
multi-block parameter handling is unchanged. Stack objects, spill layout,
frame-index ownership, and the spill allocator remain unchanged.

The regression has zero ordinary planned spill slots but two preservation
slots across `llvm.abs.i32`, and therefore fails on the old under-reservation.
It proves a 264-byte shared frame, an actual scalar preservation spill, and
the expected absolute-value and division operations. Permanent Linux JIT
execution checks six precomputed signed cases for each of quotient,
remainder, and quotient-plus-pointer-remainder shapes, including all sign
combinations, `minInt(i32) / 7`, and `maxInt(i32) / -1`. A control wrapper
with no live value across `llvm.abs.i32` remains frameless.

The executable divmod proof initially exposed a distinct preservation bug:
the output pointer remained in RDX across division and was clobbered. The
final implementation gives a stable frame home only to single-block
parameters proven live across a preservation barrier. Broad stabilization of
all single-block parameters was rejected after it regressed unrelated
structural tests.

Accepted-row audit: 31 production `spillValue`/`spillValueOrError` call sites
were inspected. Every no-frame path either propagates its diagnostic or
converts it to an error; no production caller suppresses a failed dynamic
spill. A row that encountered the defective envelope necessarily failed
selection before object acceptance. Therefore no previously accepted row
could have traversed the exact multiple-live-value/no-frame path, and no
row-exact re-proof is required under the audit-invalidation convention.

Fresh report-all moves from 443 / 267 / 176 to 443 / 270 / 173. Exactly
`compiler_rt.int.__divmodsi4`, `compiler_rt.int.__modsi3`, and
`compiler_rt.int.__divsi3` close. The two other directed rows advance honestly:
`__divdi3` and `__divmoddi4` now reach the separate
`composed-block-call-unknown-ptr-arg` boundary. `compiler_rt.udivmod.__divti3`
advances collaterally to that same boundary. There is no collateral emission
and no new failure; pointer-null direct-call admission is outside this repair.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=270 failed_functions=173 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
report delta: directed_closures=3 directed_advances=2 collateral_advances=1 collateral_emissions=0 new_failures=0
executable matrix: signed_quotient=6/6 signed_remainder=6/6 signed_divmod=6/6
full unit: pass; tests=998/998
tier2: pass; steps=24/24 tests=1006/1006
tier3: immediate acceptance; see docs/evidence/distribution_all_after_inbox50_frame_repair.md
```

Commands:

```text
zig build test --summary all
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
tmp/inbox50_frame_install/bin/z_llvm --emit=obj --quiet --target=x86_64-linux --generic-cfg-selector --report-all-codegen-failures --input-limit=134217728 <captured-compiler-rt.ll>
zig build distribution-all --summary all > tmp/distribution_all_after_inbox50_frame_repair.log 2>&1
```

Artifacts:

- focused Tier-2 log `tmp/inbox50_frame_tier2.log`, sha256
  `25ee924d6dfeefc7cdf5acd110240be0846797182ba174c3b741bbe8dff4c48d`;
- report-all log `tmp/inbox50_frame_report.log`, sha256
  `71977641b3634512cdf6fd9625fc201b8923343505e8c626413e8ed1f405aa75`;
- Tier-3 preface `tmp/inbox50_frame_tier3_preface.txt`, sha256
  `ba3ddbb46de0506bd43828fccd94b4f45d95233a7b13e171b187c7dfdd0e34f2`.

INBOX-50 is acknowledged. After this standalone repair is committed and its
immediate Tier 3 is accepted, continue with the pre-authorized two-cycle
comparison-RHS pipeline.
