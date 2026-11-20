# INBOX-51 Scalar Fneg P0 Repair

schema_version: 1
directive: `INBOX-51 interrupt, self-declared P0`
target: `x86_64-linux`
validation_tier: 3
result: pass
closure_status: accepted correctness repair; no new closure claimed

The accepted baseline is INBOX-50 at 443 selected / 272 emitting / 171
failing. The captured compiler_rt IR md5 is
`b0eda7a6427c3084fdf096a68696f19c`, and the stage4 pin is
`bdee02bc0c7f227c0f11bc9a449df673fe803540`.

INBOX-51 native proof exposed confirmed wrong-code before its select-value
closures were accepted. The composed selector treated the parser-normalized
scalar `fneg` form (`fsub -0.0, value`) as arithmetic subtraction. SSE
`subss`/`subsd` is not bit-equivalent to LLVM `fneg`: it can quiet signaling
NaNs and does not reliably toggle a NaN sign. In the captured `__subdf3`
body, a positive right-hand quiet NaN returned positive even though the IR
requires the `fneg`-produced negative payload.

The repair recognizes only the parser's exact scalar f32/f64 negative-zero
left operand and reuses the existing XMM value map, immediate materializer,
and parameterized `pxor` machine operation. Ordinary scalar subtraction is
unchanged. No machine instruction, encoding, ABI, frame, verifier, linker,
relocation, or AIR-export authority changes.

Permanent composed-CFG execution proves exact sign-bit toggling for f32 and
f64 positive/negative zeros, minimum subnormals, normals, infinities, quiet
NaNs, and signaling NaNs. It also proves the selected form contains `pxor`
and no scalar arithmetic subtraction. Full unit passes 1005/1005; Tier 2
passes 24/24 steps and 1013/1013 tests.

Accepted-row audit:

- `compiler_rt.__negdf2` and `compiler_rt.__negsf2` use the pre-existing
  single-block fneg authority, which already emits XOR and never traversed
  the defective composed path. They are retained as exact control rows.
- The previously accepted collateral emission
  `compiler_rt.subsf3.__subsf3` does traverse the defective path with an
  arbitrary RHS and is therefore invalidated until this repair. Its extracted
  row is re-proven exactly here.
- The accepted sin/cos/sincos/round bodies containing composed scalar fneg
  exit or classify non-finite inputs before their later negations; those
  negated intermediates are finite. They cannot exercise the NaN-only
  semantic difference and need no row-exact re-proof.
- `compiler_rt.subdf3.__subdf3` is not part of the accepted 272-row baseline;
  it is one of the interrupted INBOX-51 provisional closures and must be
  proved with that pipeline after this standalone repair lands.

A structured parser extracts the two unaffected control rows plus
`__subsf3`. The clean-tree z_llvm emits one relocation-free 3,408-byte ELF
object with global function sizes 20, 14, and 2,560 bytes. A pinned-Zig
`callconv(.c)` caller passes 34/34 frozen checks: 12 f32 and 12 f64 exact
negations plus 10 `__subsf3` results covering finite arithmetic, signed
zeros, subnormal cancellation, infinities, and both signs of quiet/signaling
NaN payloads. Objdump confirms `pxor` in all three extracted bodies.

Fresh report-all remains exactly 443 / 272 / 171. There is no collateral
emission, regression, or closure movement.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=272 failed_functions=171 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
report delta: directed_closures=0 collateral_emissions=0 new_failures=0
native rows: symbols=3 relocations=0 precomputed_cases=34/34
full unit: pass; tests=1005/1005
tier2: pass; steps=24/24 tests=1013/1013
tier3: pass; immediate wrong-code acceptance; subgates=17/17
```

Commands:

```text
zig build test --summary all
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
tmp/inbox51_fneg_p0_clean_install/bin/z_llvm --emit=obj --quiet --target=x86_64-linux --generic-cfg-selector --report-all-codegen-failures --input-limit=134217728 <captured-compiler-rt.ll>
tmp/inbox51_fneg_p0_clean_install/bin/z_llvm --emit=obj --target=x86_64-linux --generic-cfg-selector --input-limit=8388608 tmp/inbox51_fneg_p0_rows.ll
../ziglang/build/stage4/bin/zig build-exe -fno-lld -target x86_64-linux-gnu tmp/inbox51_fneg_p0_start.zig tmp/inbox51_fneg_p0_clean_rows.o -femit-bin=tmp/inbox51_fneg_p0_clean_acceptance
```

Artifacts:

- clean report `tmp/inbox51_fneg_p0_clean_report.log`, sha256
  `ff99ba8aecc06b20e9b1d8011057bc45a469e8319f551391f43241eb5109ce59`;
- Tier 2 `tmp/inbox51_fneg_p0_tier2.log`, sha256
  `09a345e481af4dd8fa2d2b7b8300fb95ddf3b9949fdc1716e4639b16b6504088`;
- extracted IR `tmp/inbox51_fneg_p0_rows.ll`, sha256
  `c861fc40eeed35fce8536c30bd939bd2257ad7c5167039cda29e4dd273092f45`;
- object `tmp/inbox51_fneg_p0_clean_rows.o`, sha256
  `99584e623dfcc8a6d384024ae1fd10f8f42bc73d68b6e1cb7d304d8e2f36ebf6`;
- readelf `tmp/inbox51_fneg_p0_clean_readelf.log`, sha256
  `1cadef1c9bc15643677712e3685a804295220bfdc20fe5a4f1a294fd420ccc88`;
- objdump `tmp/inbox51_fneg_p0_clean_objdump.log`, sha256
  `6d7de204de39bd5913b769d037ec7e75fbc0f7774580d40b161a413b8462e5ea`;
- executable `tmp/inbox51_fneg_p0_clean_acceptance`, sha256
  `b99d7bf097f6bce1b25b6645fcd5cf18e66bbbfd653e1309dc2234b3eed0056f`.

The mandatory immediate Tier 3 passes against standalone staged tree
`30c201aed2c45bf782e548205a948193408b9310`; see
`docs/evidence/distribution_all_after_inbox51_fneg_p0.md`. Restore and
revalidate the preserved INBOX-51 cycle after committing this repair alone.
