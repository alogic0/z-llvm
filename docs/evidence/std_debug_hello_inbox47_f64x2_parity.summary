# INBOX-47 F64x2 Parity Provisional Acceptance

schema_version: 1
directive: `INBOX-47`
cycle: `part-2-f64x2-parity`
target: `x86_64-linux`
validation_tier: 2
result: pass
closure_status: provisional

The committed Part 1 baseline is `84bd7111`, report state 443 selected / 261
emitting / 182 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`.

The packed vector owner now derives exact two-lane select, fabs, and copysign
behavior from the lane shape. F32x2 and f64x2 therefore share one canonical
mask select implementation, one bitwise copysign implementation, and one
lane-width fabs implementation; there is no parallel double-only lowering.
F64x2 select requires a fully defined canonical 64-bit-lane mask and fully
defined alternatives. Partial masks, masks with the wrong lane width, partial
data, and other vector shapes remain fail-closed.

The machine layer's existing fixed `shufpd $2` form is now the same bounded
instruction with an immediate. The selector emits only the three reviewed
immediates: 1 for exact `[1,0]`, 3 for exact `[1,1]`, and the existing 2 for
cross-input `[0,3]`. The typed constant decoder admits the two new masks only
for f64x2 and static defined-lane propagation is covered directly.

Scalar `llvm.copysign.f32/f64` now shares one width-parametric bitwise
implementation. Its work registers remain distinct from both source
locations, preserving the prior alias-safe behavior while extending the sign
mask from 32 to 64 bits.

Permanent execution covers both lanes of canonical f64x2 select, vector fabs
and copysign, the `[1,0]` shuffle, the high lane of `[1,1]`, and scalar
copysign.f64. The raw-bit matrix includes both zeros, subnormals, infinities,
and quiet/signaling NaN payloads. Encoding checks cover all three admitted
`shufpd` immediates; rejection checks cover partial and wrong-width f64 masks.

Fresh report-all is byte-identical to Part 1 and remains 443 selected / 261
emitting / 182 failing. There are zero directed closures, zero collateral
emissions, and zero new failures. `compiler_rt.divdc3.__divdc3` still fails at
its earlier `unsupported_value` / `stage2-phi-dst` boundary, so none of the
later vector forms is credited as a row advance.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=261 failed_functions=182 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
report delta: directed_closures=0 collateral_emissions=0 new_failures=0
compiler_rt.divdc3.__divdc3: unsupported_value/stage2-phi-dst
full unit: pass; tests=980/980
tier2: pass; steps=24/24 tests=988/988
tier3: not run; reserved for the single cumulative INBOX-47 pipeline gate
```

Commands:

```text
zig build test --summary all
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
```

Artifacts:

- `tmp/inbox47_f64x2_report.log`, sha256
  `82ef48f2e5dca11262e5dfe8e7ca3e29baa4573ef29e264983f576eeb8ae02b2`;
- `tmp/inbox47_f64x2_tier2.log`, sha256
  `e407e4f07ea410159d94bb15baed23fe29caec91c70824ea5d3cc57d36241081`;
- `tmp/inbox47_f64x2_acceptance_install/bin/z_llvm`, sha256
  `1e2d62092aa5c8dae8e7cb06236f2d82a5dc9066a1b13ea2c8052f893b099a8c`.

Commit this zero-closure parity slice, run the one cumulative Tier 3 against
the committed tree, then stop for the f64x2 PHI architectural review.
