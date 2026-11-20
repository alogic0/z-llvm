# INBOX-51 I64 Immediate Scalar Select Acceptance

schema_version: 1
directive: `INBOX-51 select-value pipeline`
target: `x86_64-linux`
validation_tier: 3
result: pass
closure_status: accepted by the cumulative INBOX-51 Tier 3

The accepted capability baseline is INBOX-50 at 443 selected / 272 emitting /
171 failing. Standalone scalar-fneg P0 commit `1a9b0924` repairs the
wrong-code found during this cycle without changing that report state. The
captured compiler_rt IR md5 is
`b0eda7a6427c3084fdf096a68696f19c`, and the stage4 pin is
`bdee02bc0c7f227c0f11bc9a449df673fe803540`.

Scalar select lowering now materializes exact i64 literal arms directly into
RAX after preserving the accumulator through the existing selector-state
authority. The helper is select-owned: it does not broaden the shared value
materializer or admit integer literals in unrelated contexts. Existing named
i64, narrow integer, and scalar FP select paths are unchanged. I128 and every
other unsupported width remain fail-closed at the existing select-width
boundary.

Permanent execution selects both `minInt(i64)` and `maxInt(i64)` under zero,
one, and high-bit conditions and checks that both exact immediates reach the
machine stream. A negative i128 immediate-select form remains fail-closed.
Full unit passes 1005/1005.

Fresh report-all moves exactly from 443 / 272 / 171 to 443 / 278 / 165. The
six closures are:

- `compiler_rt.floatsidf.__floatsidf`;
- `compiler_rt.fixdfdi.__fixdfdi`;
- `compiler_rt.fixsfdi.__fixsfdi`;
- `compiler_rt.int_from_float.__fixhfdi`;
- `compiler_rt.adddf3.__adddf3`;
- `compiler_rt.subdf3.__subdf3`.

There is no collateral emission or new failure. The conditional INBOX-51
successor is not needed: refresh proves that `__adddf3` and `__subdf3` already
support their later named i64 bitcast selects and were blocked by the same
literal select arms as the four predicted conversion rows. No redundant
named-select admission was added.

A structured parser extracts all six exact captured bodies. Current-source
z_llvm emits one relocation-free 8,800-byte ELF object with six global
symbols. A pinned-Zig `callconv(.c)` caller passes 75/75 frozen checks:

- 7 exact i32-to-f64 conversions, including signed extrema;
- 15 f64-to-i64, 15 f32-to-i64, and 14 f16-to-i64 conversions covering
  signed zeros, subnormals, truncation, saturation boundaries, infinities,
  and both NaN signs;
- 12 add/sub pairs (24 results) covering signed zeros, subnormals, rounding,
  overflow, infinities, and quiet/signaling NaN payloads on both operands.

The subtraction NaN cases are a required post-P0 revalidation and now preserve
the captured fneg sign semantics exactly. Tier 2 passes 24/24 steps and
1013/1013 tests. The cumulative Tier 3 then passes all 17 subgates against
committed implementation tree
`02b0100c022ded30fe2c2b90e9d4159b2e12a49e`, accepting all six closures.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=278 failed_functions=165 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
report delta: directed_closures=6 collateral_emissions=0 new_failures=0
native rows: symbols=6 relocations=0 precomputed_checks=75/75
full unit: pass; tests=1005/1005
tier2: pass; steps=24/24 tests=1013/1013
tier3: pass; subgates=17/17 committed_tree=02b0100c022ded30fe2c2b90e9d4159b2e12a49e
```

Commands:

```text
zig build test --summary all
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
tmp/inbox51_select_post_p0_install/bin/z_llvm --emit=obj --quiet --target=x86_64-linux --generic-cfg-selector --report-all-codegen-failures --input-limit=134217728 <captured-compiler-rt.ll>
tmp/inbox51_select_post_p0_install/bin/z_llvm --emit=obj --target=x86_64-linux --generic-cfg-selector --input-limit=8388608 tmp/inbox51_select_rows.ll
../ziglang/build/stage4/bin/zig build-exe -fno-lld -target x86_64-linux-gnu tmp/inbox51_select_start.zig tmp/inbox51_select_post_p0_rows.o -femit-bin=tmp/inbox51_select_post_p0_acceptance
```

Artifacts:

- report `tmp/inbox51_select_post_p0_report.log`, sha256
  `8c4cb026b209e70db98638999a7b71dc75de668e688199fcfd1f39b30f990a6b`;
- Tier 2 `tmp/inbox51_select_post_p0_tier2.log`, sha256
  `654032e563b3017d2f026b1a9ee9b867428c4b9226f5206e7201d745853e861e`;
- extracted IR `tmp/inbox51_select_rows.ll`, sha256
  `74d0fe85c62a24bba1dee1e68248092a7f0dd1b938abc0c08dc7a561d8060782`;
- object `tmp/inbox51_select_post_p0_rows.o`, sha256
  `f55a6284ea7cfcb2a0a1a9f67b9dff3db8a9e120c09517f2f04e3b5717f2739f`;
- readelf `tmp/inbox51_select_post_p0_readelf.log`, sha256
  `6f8a7c5f4312e1bf21c051883ddd6a998a9bc77147c29cfeb41d94cd93a82ce3`;
- objdump `tmp/inbox51_select_post_p0_objdump.log`, sha256
  `2f516a458bec29cf81f7689334e0050c81b8933f38721bd20c0c9bdf0c6eb72e`;
- executable `tmp/inbox51_select_post_p0_acceptance`, sha256
  `d5b5d4c1f9c3c5c3fac057cc44b44faa303a3c3a9c3cdac0b06c17d470e7c7a4`;
- cumulative Tier-3 acceptance
  `docs/evidence/distribution_all_after_inbox51_select_pipeline.md`.

INBOX-51 is complete and accepted. Stop for periodic review #13; that review
is also the switch-PHI/EI program design discussion.
