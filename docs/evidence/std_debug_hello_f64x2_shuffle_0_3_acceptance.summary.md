# Exact F64x2 Two-Source Shuffle Acceptance

schema_version: 1
directive: `INBOX-30` pre-authorized successor
target: `x86_64-linux-gnu`
validation_tier: 3
result: pass

The shared typed shuffle classifier now admits exactly the f64x2 LLVM mask
`<0, 3>` in addition to the previously accepted single-source masks. The
composed vector selector materializes both packed operands in independent XMM
locations, emits fixed `shufpd $2, src, dst`, and records result lane 0 as
defined only when source A lane 0 is defined and result lane 1 as defined only
when source B lane 1 is defined. Other two-source masks and the f32x2 `<0, 3>`
shape remain fail-closed; no arbitrary shuffle-immediate surface was added.

Machine, assembly, encoding, verifier, selector-state, and executable tests
cover the fixed instruction and register-parametric lowering. The permanent
microcanary constructs A and B independently and extracts both result lanes.
It preserves exact signed-zero, minimum-subnormal, infinity, quiet-NaN, and
signaling-NaN payload bits from A0 and B1. Focused repository tests pass
915/915; the Tier-2 close passes all 24 build steps and 923/923 tests.

Fresh report-all advances from 443 selected / 213 emitting / 230 failing to
443 selected / 214 emitting / 229 failing. The only removed failure is
`compiler_rt.log10.log10`, previously stopped at `shufflevector-mask`; there
are no collateral emissions.

A parser/printer-derived module exports only the exact
`compiler_rt.log10.log10` body. Its emitted ELF object contains a 1,600-byte
global function, the expected `shufpd $2` instruction, and no relocations. A
freestanding native executable linked with `zig build-exe -fno-lld` passes 15
precomputed raw-f64 results from the pinned compiler-rt source: both zeros,
minimum subnormal, minimum normal, finite polynomial paths, maximum finite,
both infinities, and positive/negative quiet and signaling NaNs.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=214 failed_functions=229 first_failing_function=compiler_rt.trunc.truncl local_fail=1
focused tests: unit=915/915 native_log10_calls=15/15
tier2: pass; 24/24 steps, 923/923 tests
tier3: pass; one recorded invocation, all 17 subgates green
```

Logs and artifacts:

- `tmp/inbox30_shuffle_report.log`, sha256 `e983dbdd1afcf245af851bca379dd91a588c57c3bd313880c0899b2b27d0c7fd`;
- `tmp/inbox30_shuffle_tier2.log`, sha256 `6f87162f34ed091201d2aaf13047135e94cde4b59f01d6d442fd567208c4db5c`;
- `tmp/inbox30_log10_reference.log`, sha256 `05d2d8c738cb37441279cc1a2ada400223ad2f9724dc9248f1e43dc4ae5bb6ca`;
- `tmp/inbox30_log10_row.o`, sha256 `b92906640f99c437e2b00c9bd4db84ec3b288ab904dcdf0ac7af19cf75b2c6fa`;
- `tmp/inbox30_log10_acceptance`, sha256 `8c53151418e8bb1a836e2763982e7cf49f5d31b81777d2a08a09e792f4f11c85`.

Tier-3 preface, staged identity, and final summaries are recorded in
`docs/evidence/distribution_all_after_inbox30_f64x2_shuffle_0_3.summary.md`.
