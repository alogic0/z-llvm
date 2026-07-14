# INBOX-50 I16 Negative-Literal Comparison Cycle

schema_version: 1
directive: `INBOX-50 comparison-RHS cycle 1`
target: `x86_64-linux`
validation_tier: 2
result: pass
closure_status: no provisional closures

The accepted baseline is `dcd41895`, report state 443 selected / 270 emitting /
173 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`.

Unsigned i16 immediate comparisons now decode LLVM integer constants as exact
16-bit patterns. Textual constants from `minInt(i16)` through `maxInt(u16)`
are admitted, so negative spellings such as `-30` and `-31743` retain their
modulo-16-bit values. Values outside that envelope, other widths, predicates,
and operand forms remain fail-closed. The existing `cmp r16, imm16` plus
`setb`/`seta` machine paths are reused without changing value, frame, CFG, or
verifier ownership.

Permanent instruction-shape tests prove `-30 -> 0xffe2` and
`-31743 -> 0x8401`, and reject `-32769` and `65536`. Executable tests cover
11 unsigned raw-i16 values around zero, the sign boundary, both admitted
thresholds, and `0xffff` for each predicate. Full unit passes 1000/1000; Tier
2 passes 24/24 steps and 1008/1008 tests.

The fresh compiler_rt report remains 443 / 270 / 173. The capability advances
`compiler_rt.mulhf3.__mulhf3` from `composed-block-icmp-rhs` to the later
`composed-block-binary-width` frontier and
`compiler_rt.addhf3.__addhf3` from `composed-block-icmp-rhs` to the later
`composed-block-icmp-form` frontier. Neither row emits, so the cycle records
zero provisional closures, no collateral emission, and no new failure.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=270 failed_functions=173 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
report delta: directed_closures=0 directed_advances=2 collateral_emissions=0 new_failures=0
focused execution: ult_cases=11/11 ugt_cases=11/11 out_of_range_negatives=2/2
full unit: pass; tests=1000/1000
tier2: pass; steps=24/24 tests=1008/1008
tier3: not run; reserved for the cumulative INBOX-50 comparison pipeline
```

Artifacts:

- report `tmp/inbox50_i16_report.log`, sha256
  `7f0a7b2c6c03a75302a50e21955810d53d42a5a505187e6f3d8261769fd7535d`;
- Tier-2 log `tmp/inbox50_i16_tier2.log`, sha256
  `9e2e18495498721b65d620929302fe818d649cf9e959a2a0f53d5e2f4a7a7b85`.

Commit the exact capability, then continue with the pre-authorized named i64
`ult` cycle. Do not absorb either newly exposed half frontier.
