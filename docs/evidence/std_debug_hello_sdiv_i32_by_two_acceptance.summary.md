# Exact Signed I32 Division By Two Acceptance

schema_version: 1
directive: `INBOX-39 Part 1`
target: `x86_64-linux`
validation_tier: 3
result: pass

The accepted baseline is `e4507f60`, report state 443 selected / 236 emitting /
207 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`. The production and permanent-test
diff used for validation has sha256
`7968f4d804a5045b61667ce41e7d76210eb438834c1db67e0358bd1cd20bb60b`.
The current-source ReleaseFast z_llvm has sha256
`2ea7e44fc804279a5da7786095b5b8a94525d82d0c961ce66d3d1b069484873d`.

The composed selector admits only exact `sdiv i32 %named, 2`. It implements
LLVM's signed truncation-toward-zero rule as
`(x + ((u32)x >> 31)) >> 1`, preserving any live EAX value before using EAX
and ECX. A bare arithmetic shift is deliberately not used because it rounds
negative odd values toward negative infinity. Other divisors, i64 division,
immediate-left division, and named divisors remain fail-closed.

Permanent executable coverage checks 12 values including `INT_MIN`,
`INT_MAX`, both signs, zero, and the negative odd values -7, -5, -3, and -1.
The four neighboring unadmitted forms are also checked fail-closed.

The first exact captured-row execution exposed a separate shared-CFG defect:
conditional phi edges were stabilized while their edge bodies were emitted.
The first edge could therefore mutate a common source binding into a spill
whose store existed only on that runtime edge; the second edge then reloaded
that uninitialized/stale slot. Both successor source sets are now stabilized
before the conditional jump. A permanent framed FP regression executes both
successors when they share the same phi source.

The exact captured `__powidf2` and `__powisf2` bodies emit as two global,
relocation-free ELF functions and execute 22 bit-exact calls. Eleven paired
cases include negative odd exponents -7, -5, -3, and -1, negative bases,
positive and zero exponents, and both float and double results. Expected bits
come from a pinned-algorithm-equivalent reference rather than host `pow`.

Fresh report-all advances to 443 selected / 238 emitting / 205 failing. The
complete report diff removes exactly these two failures and introduces none:

- `compiler_rt.powiXf2.__powidf2` closes;
- `compiler_rt.powiXf2.__powisf2` closes.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=238 failed_functions=205 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused coverage: sdiv_executable_cases=12/12 fail_closed_shapes=4/4 conditional_phi_paths=4/4 exact_powi_calls=22/22
report delta: collateral_changes=0 closures=2
tier2: pass; steps=24/24 tests=952/952
tier3: pass; subgates=17/17 local_fail=0
```

Commands:

```text
zig build test structural-smoke --summary all
zig build install -Doptimize=ReleaseFast --prefix tmp/inbox39_sdiv2_install
tmp/inbox39_sdiv2_install/bin/z_llvm --emit=obj --target=x86_64-linux --passes=zig-debug-accepted --input-limit=67108864 --report-all-codegen-failures --generic-cfg-selector tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
zig build distribution-all
```

Artifacts:

- `tmp/inbox39_sdiv2_report.log`, sha256
  `409126d383d82208f82cda27c9db6821809ca40d525e0e93a4e3f22c23ce9515`;
- `tmp/inbox39_sdiv2_tier2.log`, sha256
  `551ddbc4e00142582f594ad7aa876f49806d2c4541834747e0902542c05b0670`;
- `tmp/inbox39_powi_rows.o`, sha256
  `83578b9021fede5de465d79bebaa4f721dde2d3607a61a60100efaa84da88341`;
- `tmp/inbox39_powi_rows_readelf.log`, sha256
  `a7c86348c3bce83179fa5d48b4f05f277dabb4cedb877e3e8fae6bf74e27492d`;
- `tmp/inbox39_powi_rows_objdump.log`, sha256
  `d69eb6ca08b440861da302aed655df1b533a2ec7ea08aed842beda417970b68f`;
- `tmp/inbox39_powi_rows_acceptance`, sha256
  `3bd9acaf5b8146e0e03b5072b1c029ea3e86a473eef7b76eb10cf7ce049b8333`;
- `tmp/inbox39_powi_reference.log`, sha256
  `cba757d7c17415aec44e443fa4a9460ad7f9b13944868356e5c4ddbe88e504e1`.

Part 1 commits before the pre-authorized successor. Continue with exact
half-to-double `fpext` composition through the proven half-to-float helper and
the existing scalar float-to-double conversion, targeting `__fmah`.
