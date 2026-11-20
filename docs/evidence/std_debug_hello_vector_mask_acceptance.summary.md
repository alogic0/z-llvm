# Canonical Vector Mask Acceptance

schema_version: 1
directive: `INBOX-41`
target: `x86_64-linux`
validation_tier: 3
result: pass

The accepted baseline is `ae35052a`, report state 443 selected / 246 emitting /
197 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`. The validated production and
permanent-test diff has sha256
`987479f463f813087e84a0b2292988b854a4bc5b4d0a962863a51445c85bde9e`.
The current-source ReleaseFast z_llvm has sha256
`987022013bb0f8ceb4823d226f21fb3b163d25cbfe5e65b56ce510fb39bf331f`.

The existing XMM vector location now distinguishes ordinary packed data from a
canonical mask. A canonical mask records two lanes, 32- or 64-bit source lane
width, static defined-lane bits, and the invariant that every defined lane is
all zero or all one bits. It uses the existing XMM register class and pair
spill slots; no parallel mask register, pointer, frame, or spill authority was
introduced.

The bounded selector slice admits:

- packed `<2 x float>` `llvm.fabs.v2f32` as `andps` with a sign-clear mask,
  preserving every non-sign payload bit;
- no-movement `<2 x float|double>` to `<2 x i32|i64>` bitcast retagging;
- packed `fcmp oeq` for the admitted f32x2/f64x2 data shapes, producing the
  canonical mask with intersection-defined lanes;
- exact `icmp samesign ugt <2 x i32>` through an explicit `0x80000000` bias on
  both operands before `pcmpgtd`. XOR with the sign bit maps unsigned order to
  signed order, so no signed comparison is silently substituted;
- constant lane 0/1 extraction through `movmskps`/`movmskpd`, constant shift,
  and bit test, with each scalar result immediately moved to its allocation-
  plan GPR so two extracts do not alias EAX.

The machine, assembly, encoder, and verifier surfaces own `andps`, `pxor`,
`pcmpgtd`, packed f32/f64 equality, and both `movmsk` forms. Canonical masks
spill and reload through the existing 16-byte pair-slot path. Undefined-lane
extraction is rejected by the selector. Dynamic lane indexes, `<4 x i1>` to
`i4`, mask-conditioned vector selects, packed divide/copysign, wider vectors,
and other compare predicates remain fail-closed.

Permanent execution compiles the exact `__unordsf2` body and checks eight
precomputed ordered/NaN cases covering both signed zeros, subnormals, finite
values, infinities, quiet NaNs, signaling NaNs, varied payloads, and both
operand orders. Separate lane checks prove packed fabs clears only the sign
bit for all 16 lane observations, including signaling-NaN payloads. Packed
f32/f64 `oeq` execution covers signed-zero equality, unequal values, and NaN
unordered behavior. Encoding bytes, mask definedness, pair spilling, and all
standing fail-closed forms are permanent tests.

The extracted `compiler_rt.comparef.__unordsf2` object has one 128-byte global
function and no relocations. A native `zig build-exe -fno-lld` harness passes
the same eight precomputed raw-f32 pairs. Fresh report-all advances exactly to
443 selected / 247 emitting / 196 failing. `__unordsf2` is the sole directed
closure; there are no collateral emissions and no new failures.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=247 failed_functions=196 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused coverage: unordsf2_cases=8/8 fabs_payload_lanes=16/16 packed_oeq_cases=6/6 object_symbols=1/1 relocations=0 native_calls=8/8
report delta: directed_closures=1 collateral_emissions=0 new_failures=0
tier2: pass; steps=24/24 tests=964/964
tier3: pass; subgates=17/17 local_fail=0
```

Commands:

```text
zig build test
zig build install -Doptimize=ReleaseFast --prefix tmp/inbox41_mask_acceptance_install
tmp/inbox41_mask_acceptance_install/bin/z_llvm --emit=obj --target=x86_64-linux --passes=zig-debug-accepted --input-limit=67108864 --report-all-codegen-failures --generic-cfg-selector tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
zig build distribution-all
```

Artifacts:

- `tmp/inbox41_mask_report.log`, sha256
  `447396cb94e1602e9e9d06dcd5046e930641625a35d61ab6478d9597314412a1`;
- `tmp/inbox41_mask_tier2.log`, sha256
  `4cd6e246ed8dbd00d4a58e9a690fe892c57d4d4f62c4c4f0a6e4517aa5ebf983`;
- `tmp/inbox41_unordsf2.ll`, sha256
  `73310662f860e4d767b711bc2bbda9f44f1bc1c9de1577da4727f7e0c480180a`;
- `tmp/inbox41_unordsf2.o`, sha256
  `7d440c6b007b06183693f3a191d14dac2b456be0ff22bb1f0507d00b669efc3c`;
- `tmp/inbox41_unordsf2_acceptance`, sha256
  `d919fa352ee028fde40cf50ff4759b546818e4a443d5b9d516df8b62e0f9bc3c`.

INBOX-41 has no successor. Stop for the aggregate-ABI architectural review:
complex `{ float, float }` / `{ double, double }` returns and aggregate allocas
must be classified through `sysv_abi.zig`; vector-select implementation is not
authorized by this closure.
