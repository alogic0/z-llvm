# Complete F32x4 Mulsc3 Acceptance

schema_version: 1
directive: `INBOX-43`
cycle: `pre-authorized-f32x4-successor`
target: `x86_64-linux`
validation_tier: 3
result: pass

The accepted baseline is `078812c2`, report state 443 selected / 247 emitting /
196 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`. Before validation, the staged
production and permanent-test tree was
`d9c26b892347d316630857c8ad70a43e2a4f523e`; its diff from the baseline has
sha256 `79b9c5c991084b617bce466e9d6ff7b80e9c316536ba40c2e0a0285203c1d9f4`.

The existing XMM vector location now represents exact four-lane `float`, i32,
and canonical mask shapes with four-bit static lane definedness. Admission is
bounded to the captured `__mulsc3` forms: lane-0/lane-1 constant insertion,
exact `[0,1,1,0]`, `[0,1,0,1]`, `[1,poison,poison,poison]`, and
`[poison,poison,3,poison]` shuffles, packed add/subtract/multiply/fabs/oeq,
constant lane-0/lane-2 extraction, and canonical mask-to-i4 lowering. The
captured scalar `llvm.copysign.f32` prerequisite is lowered by exact magnitude
and sign-bit composition. Arbitrary shuffles, lane-2 insertion, f64x4, AVX,
and noncanonical masks remain fail-closed.

The permanent executable canary constructs the vectors through two equivalent
paths and checks the admitted arithmetic, shuffles, lane extraction, fabs,
oeq, and mask conversion bit-exactly. It also checks copysign across zeros,
subnormals, infinities, and quiet/signaling NaN payloads. This coverage found
and corrected an upper-lane splat defect before acceptance: the two-lane splat
sequence had left lanes 2 and 3 zero instead of replicating the source.

The captured row also exposed reversed XMM-definition bookkeeping for the
XMM-destination `movd`/`movq` forms. The verifier now records their actual
destination definitions. Packed f32x2 aggregate returns are physically
materialized through the existing low-64 XMM/GPR transfer at the terminal or
shared epilogue; the verifier was not weakened and no synthetic definition
marker was introduced.

Fresh report-all advances exactly to 443 selected / 248 emitting / 195
failing. The sole directed closure is `compiler_rt.mulsc3.__mulsc3`; there are
no collateral emissions and no new failures. `__divsc3` advances to
`composed-block-select-cond`, while `__muldc3` remains rejected at its f64x4
`insertelement` boundary.

The exact extracted `__mulsc3` object contains one 2,947-byte global function
and no relocations. Disassembly confirms the existing unaligned pair-slot
spill path (`movups` to and from `0xb0(%rsp)`). A pinned-Zig `callconv(.c)`
caller executes three precomputed complex cases: ordinary finite arithmetic,
signed-zero preservation, and the infinite fallback path.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=248 failed_functions=195 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
report delta: directed_closures=1 collateral_emissions=0 new_failures=0
directed closure: compiler_rt.mulsc3.__mulsc3
full unit: pass; tests=966/966
tier2: pass; steps=24/24 tests=974/974
tier3: pass; subgates=17 local_fail=0
```

Commands:

```text
zig build test --summary all
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
zig build distribution-all > tmp/distribution_all_after_inbox43_f32x4.log 2>&1
```

Artifacts:

- `tmp/inbox43_f32x4_report.log`, sha256
  `5f8ae3358d64ac18bca667d5dc79178c0462e3f52129f3488c0b657774d0d274`;
- `tmp/inbox43_f32x4_tier2.log`, sha256
  `2dffac25b006eae1d57dc48d1bc765f5f91bf12f6eae99da54c8d03064bcf268`;
- `tmp/inbox43_mulsc3.ll`, sha256
  `2ed9ca297d8125251c590520f4ca10f4767a6a1effed06fec0e2e1851bf15217`;
- `tmp/inbox43_mulsc3.o`, sha256
  `b71a0a3059544132ac3fffc11793a46eb74cf03fd5310ff9eac1515013574271`;
- `tmp/inbox43_mulsc3_readelf.log`, sha256
  `f436286bc6a02c10b3b80bf87d9abbfea52c4c98a60b405ca64b31fe3488b419`;
- `tmp/inbox43_mulsc3_objdump.log`, sha256
  `587bca1b1a65af6f37e6b3d675dd2d78335cf256eb4fc2d8a500ca554701db5d`;
- `tmp/inbox43_mulsc3_acceptance`, sha256
  `1c813633aca7b780d223f45fe35b175f0f90e322457ab08c4fec283f25493f7b`.

The INBOX-43 pipeline is exhausted. Stop for periodic review; no successor is
authorized.
