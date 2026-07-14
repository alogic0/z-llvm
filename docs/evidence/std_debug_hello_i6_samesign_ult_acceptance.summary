# Narrow I6 Unsigned Comparison Acceptance

schema_version: 1
directive: `INBOX-35`
target: `x86_64-linux`
validation_tier: 2
result: pass

`INBOX-35` is acknowledged. The accepted baseline is commit `c9dba610`, with
captured IR md5 `b0eda7a6427c3084fdf096a68696f19c`. The implementation
follows the authorized `lowerIcmp` ownership interlude at `60f6fad4`. The
source-only selector and permanent-test diff used for validation has sha256
`924b829892acf7c7537570fd56549d3019e9324f247ef4091392a28562beddae`.
The current-source ReleaseFast z_llvm has sha256
`bdc26d0666671ed5ebbeddc2c0671063b83877c54739b9fe8c2cd0c77ad229c7`.

The comparison selector now admits exactly `icmp samesign ult i6 %x, imm`
for immediate bit patterns 0 through 63. Before the 32-bit physical compare,
it materializes the source in EAX and applies `and eax, 63`; the unsigned
`cmp`/`setb` therefore consumes a zero-extended i6 value regardless of the
source location's unused high bits. Plain `ult`, `samesign ugt`, other narrow
widths, out-of-range immediates, and named RHS values remain fail-closed.

Permanent executable coverage uses semantically defined `samesign` domains:
immediate 24 checks zero and 23/24/25, while immediate 63 checks 62 and the
all-ones i6 value 63. High-bit-contaminated i32 inputs prove that the explicit
mask, rather than incidental producer range information, establishes the
physical comparison invariant.

Fresh report-all remains 443 selected / 232 emitting / 211 failing. The two
expected candidates do not close: `compiler_rt.floatunsisf.__floatunsisf` and
`compiler_rt.floatsisf.__floatsisf` advance from the admitted i6 comparison to
their later concrete `llvm.cttz.i32` intrinsic. That intrinsic is outside this
cycle and remains fail-closed under the accepted INBOX-34 LLVM-intrinsic
boundary. There are no collateral emissions and no row-closure claim, so Tier
3 is not triggered.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=232 failed_functions=211 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused tests: unit=933/933 positive_domain_cases=5/5 negative_domain_cases=3/3 fail_closed_near_misses=5/5
tier2: pass; steps=24/24 tests=941/941 structural=8/8 selected object/executable modes=pass integrated_executable=5/5
tier3: not-triggered; no row closure or shared subsystem boundary
```

Commands:

```text
zig build test --summary all
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
zig build install -Doptimize=ReleaseFast --prefix tmp/inbox35_i6_install
tmp/inbox35_i6_install/bin/z_llvm --emit=obj --target=x86_64-linux --passes=zig-debug-accepted --input-limit=67108864 --report-all-codegen-failures --generic-cfg-selector tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll
```

Logs: `tmp/inbox35_i6_ult_tier2.log`, sha256
`c2aa6a1e909d7d75c1673fcd360b4c0127b87a7432ed951816d26115c88f9d35`,
and `tmp/inbox35_i6_ult_report.log`, sha256
`0265f61c8f393d0afe18e4c48910f5c6431fea19a7e62e74880a92758df73ad2`.

Continue with the pre-authorized half-pointer-store successor. The unresolved
`llvm.cttz.i32` frontier is recorded for the post-pipeline inventory rather
than folded into this comparison cycle.
