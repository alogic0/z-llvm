# Scalar FP Pointer Store Acceptance

schema_version: 1
directive: `INBOX-26` pre-authorized successor
target: `x86_64-linux-gnu`
validation_tier: 2
result: pass

The accepted baseline is commit `5131ad43`, report state 443 selected / 199
emitting / 244 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`.

The composed selector records pointer-typed ABI parameters in selector-owned
provenance state and admits scalar float/double stores only when the store
target is that exact named parameter. The target may remain in its ABI GPR or
be stabilized to a scalar spill; the latter reloads through the existing
64-bit value-location and frame authorities. Derived GEP targets and all
other unproven pointer values remain fail-closed. Local FP stack stores retain
their existing path.

Executable coverage stores five exact f32 patterns directly, five exact f64
patterns directly, and the same five f32 patterns through a framed two-block
function where both the FP value and pointer parameter are spilled. The cases
cover positive/negative zero, minimum subnormal, infinity, and a NaN payload.
Structural assertions prove the framed path reloads the f32 value, reloads the
64-bit pointer into RCX, and stores through RCX. A derived byte-pointer GEP is
rejected at `composed-block-store-fp-ptr`.

Fresh report-all remains 443 selected / 199 emitting / 244 failing. The only
frontier change is `compiler_rt.sincos.sincosf`, which clears
`composed-block-store-fp-ptr` and now stops at the existing
`stage2-terminator-not-owned` switch boundary alongside `sinf` and `cosf`.
There are no collateral emissions and no row-closure claim, so Tier 3 is not
triggered.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=199 failed_functions=244 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused tests: unit=902/902 direct_f32=5/5 direct_f64=5/5 framed_spill_f32=5/5 derived_pointer_fail_closed=1/1
tier2: pass; structural-smoke=pass selected_zllvm_executable=146/146
tier3: not-triggered; no directed row closure, ratchet move, or shared ABI/frame change
```

Logs: `tmp/inbox26_fp_pointer_store_tier2.log` (sha256
`a223688521470ca0a088982381797c93beecba0786be426be1c3f8c47bafe83e`)
and `tmp/inbox26_fp_pointer_store_report.log` (sha256
`72b23805a44ccf77dc7d7c5c65834db1970c36520f6c44b74770c73751ad39f3`).

The INBOX-26 one-cycle pipeline is exhausted. Stop for review before starting
another capability cycle.
