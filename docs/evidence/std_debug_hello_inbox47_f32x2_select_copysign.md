# INBOX-47 F32x2 Select And Copysign Provisional Closure

schema_version: 1
directive: `INBOX-47`
cycle: `part-1-f32x2-select-copysign`
target: `x86_64-linux`
validation_tier: 2
result: pass
closure_status: provisional

The accepted baseline is `2d3b4aa1`, report state 443 selected / 260 emitting /
183 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`.

Exact `<2 x float>` select now consumes only a fully defined canonical
`<2 x i1>` XMM mask and fully defined f32x2 alternatives. It uses the existing
packed XMM value shape and bitwise forms. Exact `llvm.copysign.v2f32` composes
the magnitude with the sign lanes through a shared lane-width helper. Partial
or noncanonical masks, partial data vectors, other vector widths, and other
copysign signatures remain fail-closed. Constant materialization now protects
both live XMM operands; the permanent executable canary caught the prior alias
pressure defect before this closure was claimed.

The refreshed captured row exposed one incorrect inventory assumption:
`__divsc3` also contains exact `icmp samesign ult <2 x i32>`. This is the
operand-swapped member of the already accepted packed unsigned comparison
family, so inspection and lowering now admit only exact `ugt` and `ult` for
fully defined i32x2 values. Permanent execution covers unsigned values around
the signed boundary and prevents silent signed substitution.

The permanent mmap canary constructs independent vector select and copysign
functions, exercises all four mask patterns, and checks zeros, subnormals,
infinities, and quiet/signaling NaN payloads bit-exactly. It also verifies that
partial canonical masks, noncanonical masks, and partial data are rejected.

Fresh report-all advances exactly to 443 selected / 261 emitting / 182
failing. The sole directed provisional closure is
`compiler_rt.divsc3.__divsc3`; there are no collateral emissions and no new
failures. `compiler_rt.divdc3.__divdc3` remains at `stage2-phi-dst`.

The exact extracted row is a 3,704-byte object with four existing PLT32
relocations to its internal `ldexp` helper. A pinned-Zig `callconv(.c)` harness
supplies that helper and executes five precomputed cases: ordinary finite
division, exponent-scaled finite division, zero denominator, infinite
numerator recovery, and finite-over-infinite signed-zero recovery. All result
bits match exactly.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=261 failed_functions=182 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
report delta: directed_closures=1 collateral_emissions=0 new_failures=0
directed provisional closure: compiler_rt.divsc3.__divsc3
full unit: pass; tests=978/978
tier2: pass; steps=24/24 tests=986/986
tier3: not run; deferred to the single cumulative INBOX-47 pipeline gate
```

Commands:

```text
zig build test --summary all
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
```

Artifacts:

- `tmp/inbox47_f32x2_report.log`, sha256
  `82ef48f2e5dca11262e5dfe8e7ca3e29baa4573ef29e264983f576eeb8ae02b2`;
- `tmp/inbox47_f32x2_tier2.log`, sha256
  `83d5d6e4d5466fe915954b3d88ab797391668a2e09592f0ae1ac9adace8a161f`;
- `tmp/inbox47_divsc3.ll`, sha256
  `d93cab40294be267467c79d2b1904453ccad48afb17396224198539d58f1b3e9`;
- `tmp/inbox47_divsc3.o`, sha256
  `4e8cbb707ddf7b8ee7545191387ce1c11f43ca5b02110caadd4c7261a6583d2d`;
- `tmp/inbox47_divsc3_readelf.log`, sha256
  `6b59146f9d417b143581db72a93913127fdf8a1844ac3f20786be21c75243a54`;
- `tmp/inbox47_divsc3_objdump.log`, sha256
  `6fb44c6912b2f311fd5d0a0a166d1f1312b0caf362adb4852ff18276bb4c7902`;
- `tmp/inbox47_divsc3_acceptance`, sha256
  `f4cb01ae66e0da4769db5de635de426db17578193270e79ea9ed941a14a8c4e8`.

Continue with INBOX-47's pre-authorized f64x2 parity successor. The one Tier 3
acceptance gate remains reserved for the complete pipeline.
