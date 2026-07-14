# Typed I7 Binary And Stable Phi Acceptance

schema_version: 1
directive: `INBOX-38 Part 1`
target: `x86_64-linux`
validation_tier: 3
result: pass

The accepted baseline is `f851684a`, report state 443 selected / 235 emitting /
208 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`. The production and permanent-test
diff used for validation has sha256
`146cf89be3bc9063395a1154b755909bd7422b69ffe2c4940b017a1a83fbc7de`.
The current-source ReleaseFast z_llvm has sha256
`ab9793b37a7de40c95e5e2951ffc873947f1cbdd9fc80d3d826e856ac0ad55ce`.

The composed selector now admits exact scalar i7 binary operations through the
existing typed integer operation path. This is the shared width exposed by the
four arithmetic and four conversion rows after `llvm.ctlz.i64`: immediate add
appears in the arithmetic rows and immediate xor in the conversion rows. A
permanent executable canary checks i7 add and xor modulo 128 across six cases;
the neighboring i5 width remains fail-closed.

Exact-row execution of `compiler_rt.divdf3.__divdf3` found a latent framed CFG
correctness defect before acceptance. A merge block could be emitted before a
backward predecessor changed a scalar phi destination from a scratch register
to a spill home, leaving the already-emitted merge use stale. Framed scalar
integer phi destinations are now stabilized through the existing single frame
authority before block emission, matching the existing scalar-FP treatment.
Permanent coverage orders the merge before both predecessors and executes both
edges, proving that each reaches the stable frame home.

The exact captured `__divdf3` body emits as one relocation-free ELF function
and executes 23 bit-exact cases. Coverage includes signed zeros, finite exact
and rounded results, division by zero, overflow, infinities, quiet/signaling
NaNs, and signed denormal-result flushing. Expected bits follow the captured
compiler_rt implementation's explicit flush-to-signed-zero policy rather than
host hardware division for subnormal results.

Fresh report-all advances to 443 selected / 236 emitting / 207 failing. The
complete report diff proves exactly one closure and seven directed later
frontiers, with no collateral changes:

- `compiler_rt.divdf3.__divdf3` closes;
- `compiler_rt.muldf3.__muldf3` advances to `composed-block-llvm-intrinsic`;
- `compiler_rt.subdf3.__subdf3` and `compiler_rt.adddf3.__adddf3` advance to
  `composed-block-select-false-value`;
- `compiler_rt.floatundidf.__floatundidf`,
  `compiler_rt.floatundisf.__floatundisf`,
  `compiler_rt.floatdidf.__floatdidf`, and
  `compiler_rt.floatdisf.__floatdisf` advance to `composed-block-icmp-form`.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=236 failed_functions=207 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused coverage: i7_executable_cases=6/6 neighboring_i5_fail_closed=1/1 backward_phi_edges=2/2 exact_divdf3_cases=23/23
report delta: directed_frontier_advances=7 collateral_changes=0 closures=1
tier2: pass; steps=24/24 tests=947/947
tier3: pass; subgates=17/17 local_fail=0
```

Commands:

```text
zig build test structural-smoke --summary all
zig build install -Doptimize=ReleaseFast --prefix tmp/inbox38_i7_phi_install
tmp/inbox38_i7_phi_install/bin/z_llvm --emit=obj --target=x86_64-linux --passes=zig-debug-accepted --input-limit=67108864 --report-all-codegen-failures --generic-cfg-selector tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
zig build distribution-all
```

Artifacts:

- `tmp/inbox38_i7_phi_report.log`, sha256
  `17ae21b5ad3da7e56ff1e84052792836bb3dfb195ec374087ef40dd47af4b6d9`;
- `tmp/inbox38_i7_phi_tier2.log`, sha256
  `1e34ee9772fb947ecf67932d35c80598e4f32e0158d9727e7c97347c2df77baa`;
- `tmp/inbox38_divdf3_row.ll`, sha256
  `ffc21db22fd955193664fc9086bf8f9a08cdec4a99ad4c0947cdd5ffa640f1db`;
- `tmp/inbox38_divdf3_phi_row.o`, sha256
  `a65101dd83ed0f0acf0e9bc42d3d4c5de27559cd328f3617039134f11e0b3e76`;
- `tmp/inbox38_divdf3_readelf.log`, sha256
  `9039428a9e4b4e3d9f5fae604b7e60e6c3370685c577566d7588da20de0ea205`;
- `tmp/inbox38_divdf3_objdump.log`, sha256
  `3b66da8d037ef30ab24182f60997fc14571d3b69167076189751fd454d6e1988`;
- `tmp/inbox38_divdf3_phi_acceptance`, sha256
  `f600302d261479f8e0b8dc4f6a67392f69e9db8415fba274c95a86745c35786c`;
- `tmp/inbox38_divdf3_reference.log`, sha256
  `034a43ccb4875c295d690ff4abe6be94a2a0f010859885ea9bd0a1bbbc231fe5`.

Part 1 commits before the pre-authorized successor. From the refreshed report,
scalar `fptosi` to i32 is the strongest successor: `exp` and `expf` both stop
at that exact instruction, while the alternative signed i32 divide-by-two form
also has two candidates but requires a separate integer-division operation.
