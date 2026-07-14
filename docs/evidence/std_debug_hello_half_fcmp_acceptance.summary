# Half Comparison Acceptance

schema_version: 1
directive: `INBOX-40 Part 1`
target: `x86_64-linux`
validation_tier: 3
result: pass

The accepted baseline is `c7672a26`, report state 443 selected / 239 emitting /
204 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`. The validated production and
permanent-test diff has sha256
`371748460161953366b0418e84d1db22e3b0002e7acaebb9baae8a3ea52c4916`.
The fresh ReleaseFast z_llvm has sha256
`762d69ee1854a186fc3113b2fa34fa517d5a6253f86ffbfe3f8c4b2b24202b18`.

The composed selector now admits only scalar half `fcmp uno` and `fcmp olt`
whose operands are named values or literal half zero, with at least one named
operand. Each half payload is widened through the proven nonrecursive
`__extendhfsf2` helper and compared at float width. For two named operands the
right half payload and widened left value use the existing pair-spill frame
authority across the two helper calls. Named half `oeq` remains restricted to
the established zero-bit test; other half predicates and unsupported operand
forms remain fail-closed.

The directed rows exposed two exact prerequisites. Signed `icmp slt i16
%named, 0` now compares the normalized low 16 bits, and scalar FP select now
admits 16-bit half locations without conversion. Permanent execution covers
upper-bit contamination for the i16 comparison and preserves raw half NaN and
signed-zero payloads through both select outcomes.

The extracted `compiler_rt.fmin.__fminh` and
`compiler_rt.fmax.__fmaxh` object contains two global functions and eight
`R_X86_64_PLT32` relocations to `__extendhfsf2`. A native
`zig build-exe -fno-lld` executable passes 13 precomputed raw-half pairs for
both functions, covering both signed-zero orders, normal and subnormal values,
both infinities, quiet/signaling NaNs in both operand positions, and two NaN
payloads together.

Fresh report-all advances to 443 selected / 243 emitting / 200 failing.
`__fminh` and `__fmaxh` are the two directed, executably proven closures.
`__fixunshfdi` and `__fixunshfsi` emit collaterally through the exact i16
comparison prerequisite; they are recorded without row-level semantic claims.
`__fixunshfti` advances to `stage2-phi-src`. No new failure appears.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=243 failed_functions=200 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused coverage: half_predicate_cases=20/20 half_select_outcomes=2/2 i16_slt_cases=5/5 exact_minmax_calls=26/26 relocations=8/8
report delta: directed_closures=2 collateral_emissions_without_semantic_claims=2 new_failures=0
tier2: pass; steps=24/24 tests=956/956
tier3: pass; subgates=17/17 local_fail=0
```

Commands:

```text
zig build test structural-smoke --summary all
zig build install -Doptimize=ReleaseFast --prefix tmp/inbox40_half_fcmp_select_install
tmp/inbox40_half_fcmp_select_install/bin/z_llvm --emit=obj --target=x86_64-linux --passes=zig-debug-accepted --input-limit=67108864 --report-all-codegen-failures --generic-cfg-selector tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
zig build distribution-all
```

Artifacts:

- `tmp/inbox40_half_fcmp_report.log`, sha256
  `2d46722124f84df8a07da57af5769b134ea01e45c599c23da8a43d9564c85c39`;
- `tmp/inbox40_half_fcmp_tier2.log`, sha256
  `705b0a71442047fbbc41058c4f9f5d2c01a000a1dd6b010b91721575a7f22080`;
- `tmp/inbox40_half_minmax_rows.ll`, sha256
  `e919c3d41719947c6a20b0a9616072a8f26b872f9d18ed3f45bc54a83d480ac1`;
- `tmp/inbox40_half_minmax_rows.o`, sha256
  `53c2c975e7a5722c09fc452665d1066ad06f7b1dbfecdab6e774a2fdacd78e4a`;
- `tmp/inbox40_half_minmax_acceptance`, sha256
  `954f4ec0a020a8a2c98d759c6fa5b89e92d4cb76ba6e93dde4a1ef820d4bdb1e`.

Continue with INBOX-40's pre-authorized half-add successor in a separate clean
cycle. The vector-mask slice remains unauthorized until that pipeline closes.
