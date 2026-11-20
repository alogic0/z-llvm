# INBOX-53 Phase 3 Exact EI Switch-PHI Edges

schema_version: 1
directive: `INBOX-53 continuation, phase 3`
target: `x86_64-linux`
validation_tier: 3
result: accepted
closure_status: zero closures; six honest advances

The accepted Phase 2 baseline is implementation `4fc11d68`, acceptance
`9fee54dc`, and report 443 selected / 278 emitting / 165 failing. The frozen
contract and 29-row census are in
`docs/evidence/inbox53_switch_phi_ei_census.md`. The captured compiler_rt IR
md5 remains `b0eda7a6427c3084fdf096a68696f19c`, and the stage4 pin remains
`bdee02bc0c7f227c0f11bc9a449df673fe803540`.

## Bounded Capability

PHI-bearing switches enter a new typed admission inside the existing
compare-chain selector only when all frozen facts hold:

- the switch is the function's sole switch, in entry block zero, with
  condition type exactly i16;
- the five case values are exact integer constants forming the set `0..4`,
  with distinct targets and a distinct live default target;
- case 0 targets the function's sole six-incoming scalar FP return PHI,
  whose type and return type are exactly half, float, or double;
- the entry incoming is exact positive zero (`0xH0000` for half or
  `0.000000e+00` for float/double);
- cases 1 through 4 branch directly to the return join with named values;
- the one remaining named PHI incoming is reached from the default target
  through only owned direct and conditional branches and itself branches to
  the return join.

The existing integer compare chain is retained. It emits six owned edge
stubs, one for each case/default edge. Every stub invokes the existing
`emitPhiEdgeMoves` parallel-copy authority before jumping to the real target;
no switch-specific PHI materializer, jump table, indirect branch, or second
CFG authority is introduced.

Admission rejects wrong condition widths, missing/extra/duplicate cases,
duplicate targets, multiple switches, indirect branches, non-scalar or
non-six-way PHIs, multiple six-way scalar FP joins, nonzero case-0 values,
non-direct case joins, and defaults not proven to reach the exact remaining
join predecessor. Existing parser/type checks retain non-integer switch-case
rejection. Pointer/vector/aggregate PHIs and x87/fp128 returns remain outside
the admitted return types. Fma remains excluded because it has four switches
of i11/i32 shape.

## Executable And Structural Coverage

Permanent executable canaries lower, verify, encode, and execute exact half,
float, and double shapes. Each type exercises case 0, cases 1 through 4, and
an out-of-range default. Bit checks include positive and negative zero,
minimum subnormals, positive/negative infinity, and quiet-NaN payloads.

Structural negatives cover an i32 condition, an incomplete case/join set, a
nonzero half case-0 value, an unreachable/unproven default, and duplicate
case ambiguity. The pre-existing masked-switch negative continues to prove
that generic unreachable defaults require the separate masked-range proof.

Full unit validation passes 1011/1011 tests. Focused Tier 2 passes 24/24 steps
and 1019/1019 tests, including structural smoke, assembly/objdump/readelf
comparison, object and executable gates, and the integrated executable.

## Mandatory Refreshed Frontier

The final report remains exactly 443 selected / 278 emitting / 165 failing.
There are zero closures, zero collateral emissions, and zero new failures.
The report diff contains exactly these six directed advances:

- `__floatuneidf`, `__floatuneisf`, `__floateidf`, and `__floateisf` move
  from `stage2-switch-phi-edge` to `composed-block-load-ptr-width`;
- `__floatuneihf` and `__floateihf` move from `stage2-switch-phi-edge` to
  `composed-int-fp-to-type`.

This refresh exposes two Phase 4 supporting-form populations rather than
closures: f32/f64 first reach the unsupported i96 case load, while half first
reaches an unsupported integer-to-half conversion. The captured default loops
and narrow PHIs remain later in the same six bodies. `compiler_rt.fma.fma`
stays at `stage2-switch-phi-edge`; the four EI x87/fp128 siblings stay at
`unsupported-return-type`. Every other report row is unchanged.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=278 failed_functions=165 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
report delta: directed_closures=0 directed_advances=6 collateral_emissions=0 new_failures=0
full unit: pass; tests=1011/1011
tier2: pass; steps=24/24 tests=1019/1019
tier3: pass; subgates=17/17 implementation=0d0fdb59 tree=81b43c4f67e4ba9b029f9fb8203b3287a6157da1
```

Commands:

```text
zig build test --summary all
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
tmp/inbox53_phase3_install/bin/z_llvm --emit=obj --quiet --target=x86_64-linux --generic-cfg-selector --report-all-codegen-failures --input-limit=134217728 <captured-compiler-rt.ll>
```

Artifacts:

- report `tmp/inbox53_phase3_report.log`, sha256
  `0cdf49f5a88c4afa82d5eba729feed5543aaa3a0da565c215ee351f512ddcf97`;
- Tier 2 `tmp/inbox53_phase3_tier2.log`, sha256
  `c894344bbf04489161c9bb660a469df17630eabdd7941ca1ae38f6b92e76600c`.

## Tier 3 Preface

Changed subsystem: x86_64 generic-CFG typed switch admission and shared PHI
edge planning/materialization.

Trigger: Phase 3 adds a new value path through shared CFG planning and the
parallel PHI-copy authority, so the frozen contract requires exactly one Tier
3 at the phase boundary.

Exact command and intended log:

```text
zig build distribution-all --summary all > tmp/distribution_all_after_inbox53_phase3.log 2>&1
```

Prior evidence cannot be reused because Phase 2 predates the exact EI switch
admission, six owned switch-edge stubs, and the new three-type executable and
negative canaries. Commit the implementation and this preface before the
single phase-boundary run.

The single committed-tree run passes all 17 subgates for implementation
`0d0fdb596892571d5d829f622e3fc6035583cc80` and tree
`81b43c4f67e4ba9b029f9fb8203b3287a6157da1`. Acceptance evidence is in
`docs/evidence/distribution_all_after_inbox53_phase3.summary.md`.
