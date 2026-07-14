# INBOX-48 F64x2 Vector-PHI Capability

schema_version: 1
directive: `INBOX-48`
target: `x86_64-linux`
validation_tier: 2
result: pass
closure_status: none

Baseline is the cumulatively accepted INBOX-47 vector pipeline at `4d26e65c`,
with compiler_rt report state 443 selected / 261 emitting / 182 failing,
captured compiler_rt IR md5 `b0eda7a6427c3084fdf096a68696f19c`, and
stage4 pin `bdee02bc0c7f227c0f11bc9a449df673fe803540`.

Stage2 PHI destination admission now accepts exactly a fully defined
`<2 x double>` value. Its existing `.vector_xmm` interval assignment maps to
an XMM destination carrying `f64x2(0b11)` or to the allocation plan's existing
two-slot `.spill_vector` location. Framed PHI destinations use
`allocatePairSpillSlots`; no value-location variant, frame rule, machine
instruction, verifier rule, ABI classifier, or linker behavior changed.

The existing parallel PHI-copy authority now snapshots scalar or vector XMM
sources with their complete XMM shape before sequential edge copies. Vector
register, register-to-spill, spill-to-register, and overlapping
spill-to-spill copies all use the existing shape-checked materializer. A
partial source cannot be weakened into the full destination: exact shape
equality fails closed at its edge.

Permanent executable coverage forces two simultaneous f64x2 loop PHIs with
crossed incoming values. Both destinations are pair-spilled by the framed PHI
authority; alternating one, two, and three iterations prove swapped edge
copies and that copies execute only on the selected edge. Raw lanes include a
quiet NaN payload, negative minimum subnormal, negative infinity, and maximum
subnormal. A second branch canary proves the same named vector reaching one
destination from either predecessor. Focused location tests cover
source-equals-destination and an overlapping spill-to-spill copy through
XMM0.

Structural negatives keep partial f64x2, f32x2, f32x4, canonical mask PHIs,
non-materializable vector constants, and vector values directed to scalar
spill destinations fail-closed.

The fresh compiler_rt report remains exactly 443 selected / 261 emitting /
182 failing. It differs from the accepted INBOX-47 report in one line only:
`compiler_rt.divdc3.__divdc3` advances from `unsupported_value` /
`stage2-phi-dst` to the later `no_emitter` /
`composed-vector-extract-type`. Inspection of the complete captured body
identifies that later form as constant extraction from `<2 x i64>` after the
existing f64x2-to-i64x2 bitcast. It is not part of the reviewed PHI contract.

Therefore the expected `__divdc3` closure did not occur, and no collateral
emission or new failure is claimed. The pinned-Zig five-edge native proof
cannot honestly run because the extracted row does not emit. This evidence
accepts the reusable PHI capability only; it does not accept or reclassify the
row closure.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=261 failed_functions=182 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
report delta: directed_closures=0 collateral_emissions=0 new_failures=0
compiler_rt.divdc3.__divdc3: unsupported_value/stage2-phi-dst -> no_emitter/composed-vector-extract-type
full unit: pass; tests=983/983
tier2: pass; steps=24/24 tests=991/991
tier3: pending; required once for shared CFG/planner acceptance
```

Commands:

```text
zig build test --summary all
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
tmp/inbox48_phi_install/bin/z_llvm --emit=obj --quiet --target=x86_64-linux --generic-cfg-selector --report-all-codegen-failures --input-limit=134217728 <captured-compiler-rt.ll>
```

Artifacts:

- `tmp/inbox48_phi_report.log`, sha256
  `8c63c8e0e0bbe90d0f2d55c7e0978512acc620c33bf7b5a8b706b64f94372803`;
- `tmp/inbox48_phi_tier2.log`, sha256
  `3dd4e1bd3f89f4679495c593cb3629d595b4438bbc2083983b8bc11d1f9b390b`.

