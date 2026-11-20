# INBOX-53 Phase 4 Cycle 2 EI Default Bodies

schema_version: 1
directive: `INBOX-53 continuation, phase 4 cycle 2`
target: `x86_64-linux`
validation_tier: 2
result: pass
closure_status: six provisional closures

The accepted Phase 3 baseline is 443 selected / 278 emitting / 165 failing.
Phase 4 cycle 1 cleared the fixed cases and exposed one common default-body
frontier. The frozen census is
`docs/evidence/inbox53_switch_phi_ei_census.md`; captured compiler_rt IR md5
remains `b0eda7a6427c3084fdf096a68696f19c`.

## Bounded Capability

The existing stage-two allocation plan now recognizes only the exact scalar
EI `(readonly ptr, i64) -> half|float|double` family and gives simple scalar
self-loop backedge definitions stable planned GPR/spill homes before their
textual definitions. Edge materialization remains in the existing parallel
PHI-copy authority. Multiple backedges, pointer/vector/aggregate values,
other signatures, other switch sets, and other return types remain
fail-closed.

The same exact family admits its captured readonly derived byte/i32 pointers,
non-overreading i8/i16/i32/i56 loads, odd-width GPR operations for
i3/i4/i5/i13/i14/i26/i27/i55/i56, immediate narrow comparisons, and exact
named-i64 `llvm.usub.sat.i64`. Odd widths above 32 use the 64-bit physical
location and reload authority; narrower values use the 32-bit authority.
Stores, unknown provenance, named narrow comparison RHS values, unsupported
predicates, other widths, and unrelated functions remain fail-closed.

The captured i13/i14-to-half leaves reuse exact f32 conversion followed by
the proven non-recursive `__truncsfhf2` boundary. Every i13/i14 integer is
exact in f32, so this composition cannot introduce double rounding.

## Executable Coverage

The extracted six-row object links through the existing PLT32 call paths and
passes 78/78 frozen bit-exact checks: 11 unsigned and 15 signed inputs, each
checked as f64, f32, and f16. Cases cover zero, signs, half ties and overflow,
f64 mantissa ties around 2^53, high 128-bit limbs, and signed/unsigned extrema.
Expected bits are precomputed from the pinned Zig implementation; the harness
traps on any mismatch. `readelf` records 22 expected helper relocations and no
new relocation kind.

A permanent structural test proves exact `llvm.usub.sat.i64` admission and
rejection. A second canary proves that the family classifier requires the
readonly pointer plus i64 width and rejects mutable/wrong-width lookalikes.
The standalone narrow-return P0 discovered during this cycle is committed and
accepted separately as `17e01194`.

## Honest Frontier Result

The refreshed report moves exactly from 443 / 278 / 165 to
443 / 284 / 159. These six directed rows are absent from the failure report:

- `compiler_rt.floatuneidf.__floatuneidf`;
- `compiler_rt.floatuneisf.__floatuneisf`;
- `compiler_rt.floatuneihf.__floatuneihf`;
- `compiler_rt.floateidf.__floateidf`;
- `compiler_rt.floateisf.__floateisf`;
- `compiler_rt.floateihf.__floateihf`.

There are no collateral emissions and no new failures. The closures remain
provisional until the one cumulative family Tier 3 in Phase 5. Separately,
the P0 audit invalidated historical semantic acceptance of `__udivei5` and
`__umodei4`; their object-emission status does not change this six-row delta.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=284 failed_functions=159 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
report delta: directed_closures=6 directed_advances=0 collateral_emissions=0 new_failures=0
native: pass; checks=78/78
tier2: pass; steps=24/24 tests=1026/1026
```

Commands:

```text
zig build test --summary failures
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
zig-out/bin/z_llvm --emit=obj --quiet --target=x86_64-linux --passes=zig-debug-accepted --generic-cfg-selector --report-all-codegen-failures --input-limit=134217728 <captured-compiler-rt.ll>
zig-out/bin/z_llvm --emit=obj --target=x86_64-linux --generic-cfg-selector --input-limit=8388608 tmp/inbox53_phase4_ei_rows.ll
zig build-exe tmp/inbox53_phase4_ei_start.zig tmp/inbox53_phase4_ei_rows.o -lc -femit-bin=tmp/inbox53_phase4_ei_acceptance
tmp/inbox53_phase4_ei_acceptance
```

Artifacts:

- report `tmp/inbox53_phase4_cycle2_report.log`, sha256
  `590d86d38a305a475732a6ca46eb0aa99eef6dcda847eb581a2280f438813614`;
- Tier 2 `tmp/inbox53_phase4_cycle2_tier2.log`, sha256
  `483fcd4a133f57474cd7a55a9763f129bb6db68d3d7f7eaf5fbbed3a5155665a`;
- extracted IR `tmp/inbox53_phase4_ei_rows.ll`, sha256
  `dc6a95f7e93edcc6de0d95d420c54506947fb2e4d065d754fadbf7ace61a42bf`;
- object `tmp/inbox53_phase4_ei_rows.o`, sha256
  `8c2af3504eabb73b69af7ba6a4c5ee98079adbcd5320a2229c5161562f53b0e3`;
- executable `tmp/inbox53_phase4_ei_acceptance`, sha256
  `d40572176f48e44e88b8f37cd1b9efe84497f98774dd79b8fa822c90f20ac62a`.
