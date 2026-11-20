# INBOX-53 Phase 2 Multiway Scalar PHI Foundation

schema_version: 1
directive: `INBOX-53 continuation, phase 2`
target: `x86_64-linux`
validation_tier: 3
result: pass
closure_status: accepted foundation; zero closures and six honest advances

The accepted phase-1 baseline is commit `725818d2` at 443 selected / 278
emitting / 165 failing. The frozen contract and 29-row census are in
`docs/evidence/inbox53_switch_phi_ei_census.md`. The captured compiler_rt IR
md5 remains `b0eda7a6427c3084fdf096a68696f19c`, and the stage4 pin remains
`bdee02bc0c7f227c0f11bc9a449df673fe803540`.

## Bounded Capability

The existing stage-two PHI destination map already admitted the captured
scalar destination classes and arbitrary predecessor counts. Phase 2 extends
only the existing generic-CFG parallel edge-copy authority:

- exact i128 integer PHI literals are split into low/high bit patterns and
  materialized into the existing pair-spill destination;
- named scalar PHI sources are stabilized before any destination move;
- scalar sources overlapping a PHI destination are snapshotted before edge
  copies begin;
- snapshots use only the existing selector GPR/pair envelope, exclude all
  live PHI source and destination registers, and fail closed at
  `stage2-phi-scalar-snapshot` when that envelope is insufficient;
- no new value map, frame allocator, destination class, or edge-copy path is
  introduced.

Pointer, aggregate, partial or unsupported vector, poison/undef, nonzero FP
constant, x87/fp128, and unsupported destination forms remain fail-closed.
Positive scalar FP zero continues through its pre-existing exact path; this
cycle does not broaden FP constant materialization.

## Executable Coverage And Repair Audit

Permanent executable canaries cover:

- a four-predecessor i128 PHI with exact `0`, `-1`, named, and `minInt(i128)`
  incoming values;
- two crossed i128 loop PHIs plus an i32 loop PHI, forcing overlap-safe pair
  copies on odd and even iterations;
- a seven-predecessor f64 PHI with bit-exact positive/negative zero,
  subnormal, normal, infinity, quiet-NaN payload, and signaling-NaN payload;
- paired four-predecessor i32/i64 PHIs with named and exact literal sources.

The crossed i128 canary exposed a latent sequential-copy defect while this
phase was in flight: pair-spill destination writes could overwrite the next
PHI source. The repair stays inside the existing parallel edge-copy authority.
An instrumented traversal of all 443 selected functions in the frozen module
reported zero scalar snapshot events. An independent SSA-order scan also
found no edge where a later captured scalar PHI reads an earlier PHI result.
Therefore no previously accepted compiler_rt row hit the defective shape and
no row-exact closure re-proof is required. The synthetic crossed canary is the
first known hit and permanently proves the repair.

Full unit validation passes 1008/1008 tests. Focused Tier 2 passes 24/24 steps
and 1016/1016 tests, including structural smoke, assembly/objdump/readelf
comparison, object and executable gates, and the integrated executable.

## Honest Frontier Result

The final report remains exactly 443 selected / 278 emitting / 165 failing.
There are zero closures, zero collateral emissions, and zero new failures.
The six scalar-FP-to-i128 rows advance from `stage2-phi-src`:

- `__fixunsdfti`, `__fixunssfti`, and `__fixunshfti` now stop at
  `composed-block-cast-width`;
- `__fixdfti`, `__fixsfti`, and `__fixhfti` now stop at
  `composed-block-select-width`.

`compiler_rt.fma.fma` and the six scalar EI entry-switch rows remain at
`stage2-switch-phi-edge`. The four x87/fp128 EI siblings remain at
`unsupported-return-type`. Every other row in the frozen 29-row population is
unchanged. No closure is provisional because none occurred.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=278 failed_functions=165 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
report delta: directed_closures=0 directed_advances=6 collateral_emissions=0 new_failures=0
full unit: pass; tests=1008/1008
tier2: pass; steps=24/24 tests=1016/1016
tier3: pass; subgates=17/17 committed_tree=2a5a2889f848521a7cb125ad1bc2390e696d68de
```

Commands:

```text
zig build test --summary all
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
tmp/inbox53_phase2_install/bin/z_llvm --emit=obj --quiet --target=x86_64-linux --generic-cfg-selector --report-all-codegen-failures --input-limit=134217728 <captured-compiler-rt.ll>
```

Artifacts:

- report `tmp/inbox53_phase2_report.log`, sha256
  `b3730646b8663849d917de9310f7edce04d586dc020ff498376528c2155fa795`;
- Tier 2 `tmp/inbox53_phase2_tier2.log`, sha256
  `5998a3b3cb86af96adb00d44c847fa60475ebebf41fbb7a44843f9e5bc2de567`;
- temporary audit report `tmp/inbox53_phase2_audit_report.log`, identical to
  the final report and containing zero scalar snapshot records;
- Tier 3 acceptance
  `docs/evidence/distribution_all_after_inbox53_phase2.summary.md`.

## Tier 3 Preface

Changed subsystem: x86_64 generic-CFG stage-two scalar PHI source
materialization and shared parallel edge-copy planning.

Trigger: the phase crosses shared CFG planning and introduces overlap-safe
scalar edge copies, so the frozen contract requires exactly one Tier 3 at the
phase boundary.

Exact command and intended log:

```text
zig build distribution-all --summary all > tmp/distribution_all_after_inbox53_phase2.log 2>&1
```

Prior evidence cannot be reused because the newest accepted Tier 3 predates
the i128 literal source admission, scalar overlap snapshots, and the new
multiway/crossed executable canaries. Commit the implementation and this
preface before the single phase-boundary run.

The committed implementation is `4fc11d68` with tree
`2a5a2889f848521a7cb125ad1bc2390e696d68de`. Its single Tier 3 passes all 17
subgates. Phase 2 is accepted with zero closures and six advances. Stop for
the Phase 3 exact EI entry-switch-edge review; no Phase 3 implementation is
authorized by this record.
