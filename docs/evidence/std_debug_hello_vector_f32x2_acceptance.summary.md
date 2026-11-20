# Packed Float Vector Slice Acceptance

schema_version: 1
directive: `INBOX-25` pre-authorized successor
target: `x86_64-linux-gnu`
validation_tier: 3
result: pass

The committed prerequisite is `c7e01c3a`, which closes the scalar FP stack
memory and out-parameter cycle and acknowledges `INBOX-25`. The accepted
compiler_rt baseline is 443 selected / 193 emitting / 250 failing, captured
IR md5 `b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`.

The IR layer now owns one typed fixed-vector constant parser and one typed
splat-mask predicate. They preserve the existing source-backed value slices
without adding allocator ownership, expose lane values and definedness as a
structured result, and are shared by selector inspection and lowering. The
selector no longer parses lane syntax or compares splat-mask strings, and it
describes each constant operand once before materialization.

The existing XMM value model now names its register location `XmmValueLoc`
and uses one `vector_xmm` allocation class for the accepted f64x2 and f32x2
shapes. The new f32x2 shape carries lane type, count, width, and the static
two-lane defined mask. It admits constant lane-0/lane-1 insertion, `<0,0>`
splat, full two-lane constants, packed `addps`/`mulps`, constant extraction,
copies, and atomic pair-slot spill/reload with unaligned `movups`. Existing
f64x2 values retain `movupd` spills and their accepted operation set.

Everything outside the bounded slice remains fail-closed: dynamic indexes,
non-splat/lane-shift/cross-input shuffles, packed subtraction and division,
vector compares, masks, calls and returns, vector phis, public vector memory,
other lane counts/types, and aligned-move requirements.

The dual-construction executable canary covers lane-0 plus splat and lane-0
plus distinct lane-1 construction. Ten simultaneously live packed values
force both a `movups` spill and reload. Five exact input pairs cover signed
zeros, finite values, signed subnormals, infinities, and quiet NaNs with
payloads; all 80 extracted/constructed/arithmetic output words match exactly.
Encoding tests separately prove `addps`, `mulps`, `movss`, `unpcklps`,
`shufps`, and both unaligned frame moves.

Fresh report-all remains 443 selected / 193 emitting / 250 failing, with no
new row closure or collateral emission. `__log2h`, `log2f`, `__log10h`,
`log10f`, `__logh`, and `logf` pass their captured f32x2 insertion, splat,
constant, multiply, add, and extraction forms before stopping uniformly at
the excluded lane-shift `shufflevector` mask. `__unordsf2` passes its two-lane
construction and stops at the excluded vector-returning `llvm.fabs.v2f32`
call boundary.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=193 failed_functions=250 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused tests: unit=897/897 executable_f32x2_cases=5/5 exact_output_words=80/80 movups_spill=1 movups_reload=1
tier2: pass; unit/structural/readiness/parser/codegen/object/native-link/executable checks=pass
tier3: pass; subgates=17 strict_real_rows=100/100/all_modes integrated_exe=5/5 release_source_native_link=100/100 local_fail=0
```

Logs: `tmp/inbox25_f32x2_tier2.log` (sha256
`9ac584771592b3245897d8eac905e24fdf41d1f2c000ac319332bbefafdb48be`),
`tmp/inbox25_f32x2_final_report.log` (sha256
`ab6e9e8e3d05980e264b6c47b38df79b169281f30df5baefd428b3c666aaace9`),
and `tmp/distribution_all_after_f32x2.log` (sha256
`e8f7adc0366b12dfb1ed5eb7d672b494ad11370778e6e1043e7c32b6789a40be`).
The required Tier 3 preface and final summary are recorded in
`docs/evidence/distribution_all_after_f32x2.summary.md`.

This is the only pre-authorized successor under `INBOX-25`. No third cycle is
authorized; stop for review after commit.
