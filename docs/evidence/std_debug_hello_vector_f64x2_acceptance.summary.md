# Packed Double Vector Slice Acceptance

schema_version: 1
directive: `INBOX-24`
target: `x86_64-linux-gnu`
validation_tier: 3
result: pass

The accepted baseline is commits `fd5b5c8e` and `066d36be`, report state
443 selected / 192 emitting / 251 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`.

The composed selector now carries an exact `<2 x double>` packed shape on the
existing XMM value location and register bank. Each SSA location records lane
type, count, width, and a static two-bit defined-lane mask. The admitted forms
are constant lane-0/lane-1 insertion, `<0,0>` splat, full constants with
per-lane poison status, packed `fadd`/`fmul`, constant extraction, copies, and
one atomic pair-slot spill/reload using unaligned `movupd`. Other vector types,
dynamic indexes, non-splat shuffles, packed subtraction, comparisons/masks,
phis, calls/returns, and public vector memory remain fail-closed.

The executable microcanary builds vectors through both admitted construction
paths, keeps ten packed values live, and asserts that at least one 128-bit
spill and reload occur. It compares all 16 output words exactly across signed
zeros, finite positive/negative values, positive/negative minimum subnormals,
infinities, and quiet NaNs with distinct payloads. Focused selector tests also
verify lane-mask union/intersection and the atomic two-slot reservation.

Fresh report-all remains 443 selected / 192 emitting / 251 failing, with no
collateral emission or regression. `tanf`, `sinf`, and `sincosf` clear their
complete admitted packed forms and reach `composed-block-alloca-form`. `cosf`
reaches the same frontier; `__exp2h` and `exp2f` reach
`composed-block-gep-source`. The double `log2` and `log10` rows stop precisely
at excluded non-splat shuffles, `log` stops at excluded packed `fsub`, and
`fma` advances to its next CFG terminator boundary. Half/float vector rows are
reclassified to precise unsupported-type diagnostics and make no capability
claim.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=192 failed_functions=251 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
tier2: pass; unit=890/890 structural/object/selected-modes/executable-canaries=pass
```

Tier-3 pre-run record (recorded before execution):

- changed subsystems: composed selector value representation and allocation,
  private vector spill/reload, machine verifier, assembly, and x86_64 encoder;
- trigger: a new value shape crosses shared selector/register-allocation and
  verifier/encoder surfaces, and INBOX-24 requires periodic final acceptance;
- exact command: `zig build distribution-all > tmp/inbox24_distribution_all.log 2>&1`;
- intended evidence: `tmp/inbox24_distribution_all.log` plus this summary;
- reuse decision: the latest accepted distribution result predates every
  INBOX-24 source change and cannot cover the new packed location or pair spill.

The one authorized Tier-3 run passed all 17 subgates. Post-optimization,
pre-optimization, and IR-writer integrated-object populations passed at
146/146; the release-source-owned IR-writer population passed at 100/100;
native-link probes passed at 45/45 and 100/100; the strict 100-row real-row
gates passed in ReleaseFast, ReleaseSafe, and ReleaseSmall; and boundary gates
passed. The final timing summary reports `local_fail=0`.

```text
summary distribution-all-timing subgates=17 total_duration_ms=2300140 cache_hit_subgates=3 cache_miss_subgates=0 cache_mixed_subgates=0 cache_none_subgates=14 slowest_reported=5 fresh_real_rows=false local_fail=0
ok distribution all gates
```

Logs: `tmp/inbox24_tier2.log`, `tmp/inbox24_vector_final_report.log`, and
`tmp/inbox24_distribution_all.log`.

Dedicated Tier-3 review artifact:
`docs/evidence/distribution_all_after_inbox24_vector_acceptance.summary.md`.
