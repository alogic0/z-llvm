# Exact Scalar Maxnum Acceptance

schema_version: 1
directive: `INBOX-43`
cycle: `part-1-scalar-maxnum`
target: `x86_64-linux`
validation_tier: 2
result: pass

The accepted baseline is `da84470b`, report state 443 selected / 247 emitting /
196 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`.

The composed FP selector now admits exactly `llvm.maxnum.f32` and
`llvm.maxnum.f64`. Existing scalar XMM comparisons distinguish NaNs before the
ordered comparison. A NaN on either side returns the other operand unchanged;
the ordered greater operand wins; equal operands are merged bitwise so mixed
signed zeros produce positive zero while two negative zeros preserve negative
zero. This avoids relying on the operand-dependent NaN and equal-value behavior
of raw `maxss`/`maxsd`. No new machine operation, encoding, ABI, frame, spill,
or register class is introduced.

Permanent mmap execution covers seven precomputed raw-bit cases per width:
ordinary ordered pairs in both winner positions, both mixed signed-zero orders,
two negative zeros, a left quiet NaN with a subnormal right operand, and a right
signaling NaN with an infinite left operand. `llvm.minnum.f32` remains rejected
at `composed-block-llvm-intrinsic` because the captured corpus has no demand for
it.

Fresh report-all remains exactly 443 selected / 247 emitting / 196 failing,
with zero directed closures and zero collateral emissions. `__divdc3` advances
from `llvm.maxnum.f64` to `stage2-phi-dst`, its captured `<2 x double>` return
join. `__divsc3` advances from `llvm.maxnum.f32` to the generic intrinsic
diagnostic; the next intrinsic in its captured instruction order is scalar
`llvm.copysign.f32`. The four-lane multiply rows remain at their existing
construction frontiers.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=247 failed_functions=196 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
report delta: directed_closures=0 collateral_emissions=0 new_failures=0
focused coverage: widths=2 cases_per_width=7 minnum_fail_closed=pass
tier2: pass; steps=24/24 tests=972/972
```

Commands:

```text
zig build test --summary all -- --test-filter "scalar maxnum"
zig build install -Doptimize=ReleaseFast --prefix tmp/inbox43_maxnum_acceptance_install
tmp/inbox43_maxnum_acceptance_install/bin/z_llvm --emit=obj --target=x86_64-linux --passes=zig-debug-accepted --input-limit=67108864 --report-all-codegen-failures --generic-cfg-selector tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
```

Artifacts:

- `tmp/inbox43_maxnum_report.log`, sha256
  `2b39d9238c97f7787daf5a61b5aa4089edd448b7eef49d9e928849a128089db8`;
- `tmp/inbox43_maxnum_tier2.log`, sha256
  `f443ec0291971d113241df8253c08e56e49cbfb13144d6f8700523e6b7f15269`.

Continue with INBOX-43's pre-authorized complete `<4 x float>` successor. It
must close exactly `__mulsc3` and run the directive's single Tier 3 at
acceptance.
