# INBOX-49 Range-Attributed Popcount Provisional Acceptance

schema_version: 1
directive: `INBOX-49 Part 2`
target: `x86_64-linux`
validation_tier: 2
result: pass
closure_status: provisional

The standalone baseline-ISA P0 is accepted at `76831275`. The accepted
compiler_rt capability baseline remains INBOX-49 Part 1 at `778b13aa`, with
443 selected / 265 emitting / 178 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`.

A shared intrinsic-metadata decoder now parses one typed integer `range`
attribute and rejects malformed bounds, signed bounds, extra attributes, and
wrong widths. The composed selector admits only `llvm.ctpop.i64` with
`range(i64 0, 65)` and `llvm.ctpop.i128` with
`range(i128 0, 129)`. This metadata is operation validation, not an ABI
classification. Missing or unrelated return attributes, wrong signatures,
argument attributes, unsupported widths/intrinsics, indirect/raw calls,
operand bundles, and `musttail` remain fail-closed; ordinary `tail` and
`notail` remain advisory.

The new 64-bit machine operation uses a 27-byte Kernighan software loop and
requires no CPU feature beyond the captured baseline. I128 lowering reserves
the existing pair-spill area, counts the low and high 64-bit limbs with that
same operation, adds the two exact counts, and materializes an i128 result
with a zero high limb for the captured truncation. No POPCNT instruction,
target-feature inference, ABI rule, value location, frame layout, relocation,
linker behavior, or AIR-export surface is added.

Permanent coverage executes the raw i64 and i128 intrinsic results at zero,
one, high-bit, cross-limb, mixed-pattern, and all-ones boundaries. Encoding
and assembly tests prove the software operation contains no POPCNT. Typed
negative coverage exercises every excluded metadata and call form. Full unit
passes 996/996; Tier 2 passes 24/24 steps and 1004/1004 tests.

Fresh report-all moves exactly from 443 / 265 / 178 to 443 / 267 / 176.
`compiler_rt.popcount.__popcountdi2` and
`compiler_rt.popcount.__popcountti2` are the only directed closures, with no
collateral emission or new failure.

A structured parser extracts exactly those two captured bodies. z_llvm emits
one relocation-free 920-byte ELF object with two global function symbols
of 31 and 109 bytes. Objdump confirms both use only software loops. A pinned-
Zig `callconv(.c)` caller passes 12/12 precomputed cases, six per width,
including count maxima 64 and 128.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=267 failed_functions=176 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
report delta: directed_closures=2 collateral_emissions=0 new_failures=0
native rows: symbols=2 relocations=0 popcnt=absent precomputed_cases=12/12
full unit: pass; tests=996/996
tier2: pass; steps=24/24 tests=1004/1004
tier3: not run; reserved for cumulative INBOX-49 pipeline acceptance
```

Commands:

```text
zig build test --summary all
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
tmp/inbox49_popcount_install/bin/z_llvm --emit=obj --quiet --target=x86_64-linux --generic-cfg-selector --report-all-codegen-failures --input-limit=134217728 <captured-compiler-rt.ll>
tmp/inbox49_popcount_install/bin/z_llvm --emit=obj --target=x86_64-linux --generic-cfg-selector --input-limit=134217728 tmp/inbox49_popcount_rows.ll
../ziglang/build/stage4/bin/zig build-exe -fno-lld -target x86_64-linux-gnu tmp/inbox49_popcount_rows_start.zig tmp/inbox49_popcount_rows.o -femit-bin=tmp/inbox49_popcount_rows_acceptance
```

Artifacts:

- `tmp/inbox49_popcount_report.log`, sha256
  `76e7b588929c2887461a609c258b77d44f0d745d2ee91a3b81003925429c5b69`;
- `tmp/inbox49_popcount_tier2.log`, sha256
  `babdee694d2b4cf47dfc2217c2783fd13d8a98a7a01cc4214a19d9fa09d91da5`;
- `tmp/inbox49_popcount_rows.ll`, sha256
  `e4c481e5b7e6db9c4e8a6b18cd13922c9e7e8da021cb459e29b90ba826d9aa97`;
- `tmp/inbox49_popcount_rows.o`, sha256
  `7dcea3c2f503f80fb22503b0e89b86ccd4ad62ffbe1e4449db7bb8f73dfb97d4`;
- `tmp/inbox49_popcount_rows_readelf.log`, sha256
  `ac01c556f2a2cfc99e5e0f4e614de0072f24384d7b1f2bbf36a912b79e03319c`;
- `tmp/inbox49_popcount_rows_objdump.log`, sha256
  `45245799a81810910ad2cc3d9ed3c2c6e532af9d37ff4fbfd1e63ecb97981601`;
- `tmp/inbox49_popcount_rows_acceptance`, sha256
  `d8a704c7e9b854eca3d3ffc631e402b9d94b8e40c01b8f3c7928291f777be991`.

Commit this provisional capability, then run the one cumulative Tier 3 that
accepts INBOX-49 Part 1 (`__divdc3`) and Part 2 (`__popcountdi2` and
`__popcountti2`) together. Stop for periodic review after acceptance.
