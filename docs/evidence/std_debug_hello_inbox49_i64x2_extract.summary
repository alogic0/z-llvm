# INBOX-49 I64x2 Lane Extraction Provisional Acceptance

schema_version: 1
directive: `INBOX-49 Part 1`
target: `x86_64-linux`
validation_tier: 2
result: pass
closure_status: provisional

The cumulatively accepted INBOX-48 baseline is `bb51cffb`, with compiler_rt
report state 443 selected / 264 emitting / 179 failing, captured compiler_rt
IR md5 `b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`.

The composed vector selector now admits exactly constant lane 0 or 1
extraction from a fully defined `<2 x i64>` value. The source must already
exist in the established XMM or pair-slot `.spill_vector` value shape, as in
the admitted f64x2-to-i64x2 bitcast. Lane 0 uses the low 64-bit XMM value;
lane 1 copies to an available XMM and reuses `unpckhpd` before the existing
register-parametric `movq` transfer to RAX. Partial shapes, dynamic indexes,
other lane widths/counts, and unrelated integer-vector operations remain
fail-closed. No value location, machine instruction, frame rule, ABI
classifier, relocation, or linker behavior changed.

Permanent executable coverage constructs both lanes through the same
f64x2-to-i64x2 bitcast shape and checks literal raw bits for positive and
negative zero, subnormals, infinities, and quiet/signaling-NaN payloads. A
focused pair-spill test proves lane-1 reload, overlap-safe scratch selection,
high-to-low movement, and GPR extraction. Structural negatives cover partial
i64x2, dynamic indexes, and i32x2.

Fresh report-all moves exactly from 443 / 264 / 179 to 443 / 265 / 178.
`compiler_rt.divdc3.__divdc3` is the sole directed closure, with no collateral
emission or new failure.

The extracted row emits a 2,903-byte function with four existing PLT32
relocations to the captured `math.ldexp.ldexp__anon_5959` helper. A pinned-Zig
`callconv(.c)` executable supplies that helper and invokes the z_llvm row with
five literal expected-bit cases: normal, scaled, zero denominator, infinite
numerator, and finite over infinity. These force the five-incoming vector PHI
return join and pass 5/5, including exact signed zeros and infinity recovery.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=265 failed_functions=178 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
report delta: directed_closures=1 collateral_emissions=0 new_failures=0
native row: symbol=1 relocations=4 precomputed_cases=5/5
full unit: pass; tests=989/989
tier2: pass; steps=24/24 tests=997/997
tier3: not run; reserved for cumulative INBOX-49 pipeline acceptance
```

Commands:

```text
zig build test --summary all
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
tmp/inbox49_i64x2_install/bin/z_llvm --emit=obj --quiet --target=x86_64-linux --generic-cfg-selector --report-all-codegen-failures --input-limit=134217728 <captured-compiler-rt.ll>
tmp/inbox49_i64x2_install/bin/z_llvm --emit=obj --target=x86_64-linux --generic-cfg-selector --input-limit=134217728 tmp/inbox48_divdc3.ll > tmp/inbox49_divdc3.o
../ziglang/build/stage4/bin/zig build-exe -fno-lld -target x86_64-linux-gnu tmp/inbox49_divdc3_start.zig tmp/inbox49_divdc3.o -femit-bin=tmp/inbox49_divdc3_acceptance
```

Artifacts:

- `tmp/inbox49_i64x2_report.log`, sha256
  `c87c9fbb05a305644d91c69c0f5302c7bbcdd3c8402a055fd8b80cdc24d3665e`;
- `tmp/inbox49_i64x2_tier2.log`, sha256
  `c0c3be454c8c6d79ffb0752017111f9f0a08c702efb80c0345b1395b34f4e745`;
- `tmp/inbox49_divdc3.o`, sha256
  `829702266746aa63a6f4b9f84d4c9cb08f1847ce52a60d61875e785be87a9cea`;
- `tmp/inbox49_divdc3_start.zig`, sha256
  `abeaae134ee6545eff747aa23fa7ce16be6cc898c00c4fd6931c23186f5146d9`;
- `tmp/inbox49_divdc3_acceptance`, sha256
  `a04ecff0bb83ced37c42c376f0bfc52ae4fb0aaf01e8958531c88bc07917e147`.

Commit this provisional closure, continue with INBOX-49 Part 2, and run the
single cumulative Tier 3 only after the baseline-safe popcount capability is
complete.
