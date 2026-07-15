# INBOX-53 Phase 4 Cycle 1 EI Fixed-Case Leaves

schema_version: 1
directive: `INBOX-53 continuation, phase 4 cycle 1`
target: `x86_64-linux`
validation_tier: 2
result: pass
closure_status: zero closures; six honest advances

The accepted Phase 3 baseline is commit `6740c300` at 443 selected / 278
emitting / 165 failing. The frozen census is
`docs/evidence/inbox53_switch_phi_ei_census.md`; the captured compiler_rt IR
md5 remains `b0eda7a6427c3084fdf096a68696f19c`.

## Bounded Capability

Direct loads through function parameters carrying the exact `readonly`
attribute now admit i64, i96, and i128 values. The existing GPR/pair value map,
pair spill locations, and frame allocator remain authoritative. I96 loads read
one 64-bit limb plus one 32-bit limb; signed and unsigned conversion normalize
that high limb before use. Stores through those readonly parameters, derived
or unknown pointer provenance, address spaces, barriers, and other widths stay
fail-closed.

Exact signed and unsigned i32/i64/i96/i128 conversion to float and double uses
the existing scalar SSE result locations. Wide conversion retains the target
significand plus round and sticky bits, performs one IEEE ties-to-even rounding,
and then applies an exact power-of-two scale. It does not sum independently
rounded floating limbs and emits no recursive conversion libcall.

Integer-to-half conversion uses the exact float result followed by the already
proved non-recursive `__truncsfhf2` helper. This composition cannot double
round: every integer at the finite-half/overflow boundary is below 2^24 and
therefore exact in float; values outside that interval cannot cross the
boundary under float rounding. Calls from `__truncsfhf2` itself fail closed.

## Executable And Structural Coverage

Permanent executable selector tests lower, verify, encode, and execute direct
readonly i64/i96/i128 loads and signed/unsigned conversion to float and double.
Precomputed bit matrices cover zero, signed values, width extrema, powers of
two, f32/f64 mantissa ties, carry rounding, and f32 overflow at max u128. The
half composition matrix covers mantissa boundaries and both sides of the
65520 overflow threshold. Structural negatives cover missing readonly
provenance, unsupported i80, stores through readonly parameters, unsupported
half source widths, and recursive half-helper use.

Focused Tier 2 passes all 24 steps and 1023/1023 tests, including structural
smoke, assembly/objdump/readelf comparison, object and executable gates, and
the integrated executable.

## Honest Frontier Result

The refreshed report remains exactly 443 selected / 278 emitting / 165
failing. There are zero closures and no collateral report movement. All six
directed EI rows advance to the same default-body diagnostic,
`composed-block-unknown-rhs`:

- `__floatuneidf`, `__floatuneisf`, and `__floatuneihf`;
- `__floateidf`, `__floateisf`, and `__floateihf`.

The approved Phase 4 cycle 2 is therefore the shared default-body scalar-form
cycle. Phase 4 remains provisional; its one cumulative Tier 3 is deferred to
the Phase 5 family boundary as directed.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=278 failed_functions=165 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
report delta: directed_closures=0 directed_advances=6 collateral_emissions=0 new_failures=0
tier2: pass; steps=24/24 tests=1023/1023
```

Commands:

```text
zig build test --summary all
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
tmp/inbox53_phase4_cycle1_install/bin/z_llvm --emit=obj --quiet --target=x86_64-linux --generic-cfg-selector --report-all-codegen-failures --input-limit=134217728 <captured-compiler-rt.ll>
```

Artifacts:

- report `tmp/inbox53_phase4_cycle1_report.log`, sha256
  `6b2256cfb471ca95edb0c949b8c46c8288bbaa9fe65b841bd3510d8d79b83ea9`;
- Tier 2 `tmp/inbox53_phase4_cycle1_tier2.log`, sha256
  `2a5f7c7354b867277fa060f1cdfd2fd68e150df9ad516fa6f9c1099b3ea9a20a`.
