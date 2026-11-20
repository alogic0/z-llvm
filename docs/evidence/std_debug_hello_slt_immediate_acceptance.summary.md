# Signed-Less-Than Immediate Acceptance

schema_version: 1
directive: `INBOX-29` pre-authorized successor
target: `x86_64-linux-gnu`
validation_tier: 3
result: pass

The cycle choice was recorded before implementation: the refreshed INBOX-29
frontier had four rows sharing plain signed-less-than against an immediate,
versus three half-comparison rows and one row each at cross-input shuffle and
global-table GEP. This bounded typed i32/i64 comparison form therefore ranked
highest by closure per effort.

The composed selector now admits only plain, scalar `icmp slt` with an i32 or
i64 operand and an immediate right-hand side. It uses width-correct compare
forms and materializes the predicate with `setl`; `samesign`, named right-hand
operands, other widths, and other predicates do not enter the new path. The
existing zero-specialized lowering remains authoritative and unchanged.

Focused executable tests cover negative one, threshold minus one, the exact
threshold, and the signed maximum for both captured thresholds: 8388608 for
i32 and 4503599627370496 for i64. Structural coverage checks the exact machine
forms, and a `samesign slt` near miss remains fail-closed.

Four directed captured rows now emit and pass one parser/printer-derived native
module with precomputed result bits from the pinned Zig compiler-rt sources:

- `compiler_rt.log2.log2`;
- `compiler_rt.log2.log2f`;
- `compiler_rt.log10.log10f`;
- `compiler_rt.log.logf`.

The native matrix executes 24 f32 calls and 8 f64 calls over positive and
negative zero, minimum subnormal, 0.5, 1, 2, 3, and positive infinity. All 32
raw result bits match the precomputed literals. The emitted object exports all
four exact symbols. Reference and acceptance evidence is in
`tmp/inbox29_log_reference.log` and
`tmp/inbox29_log_rows_acceptance.log` (sha256
`b56cdb1583fcd9ec75557df275149e80064c39a64eeee904ac02f77c3e43e272`).

Fresh report-all advances from 443 selected / 202 emitting / 241 failing to
443 selected / 210 emitting / 233 failing. In addition to the four directed
closures, these four emissions are collateral and carry no separate semantic
claim: `compiler_rt.divsf3.__divsf3`, `compiler_rt.mulsf3.__mulsf3`,
`compiler_rt.subsf3.__subsf3`, and `compiler_rt.addsf3.__addsf3`.

The remaining targeted log frontier is three half wrappers at scalar half
`fcmp`, double `log10` at cross-input shuffle mask `<0, 3>`, and double `log`
at a global-table GEP source.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=210 failed_functions=233 first_failing_function=compiler_rt.trunc.truncl local_fail=1
focused tests: unit=910/910 slt_boundary_results=8/8 samesign_near_miss=1/1 native_log_calls=32/32
tier2: pass; steps=24/24 tests=918/918 structural=8/8 assembly/encoding/object inspection=pass integrated_executable=5/5
tier3: pass; one recorded invocation, all strict and boundary gates green
```

Logs: `tmp/inbox29_slt_report.log` (sha256
`d6d9a5b74559f30afe1cb061e0c038a93e32a6b4d1c1f34eab60e2f8d4d2172c`)
and `tmp/inbox29_slt_tier2.log` (sha256
`d5ffc3e5dbd1f9abc780f04b7a52129c54604f4272842a66b927bedffefa74bd`).
The Tier 3 preface, staged-source identity, and final summaries are recorded in
`docs/evidence/distribution_all_after_inbox29_slt_immediate.summary.md`.
