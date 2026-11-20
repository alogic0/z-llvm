# Named I16 Comparison Evidence

schema_version: 1
directive: `INBOX-46 Part 1`
target: `x86_64-linux`
validation_tier: 2
closure_status: `accepted by cumulative pipeline Tier 3`
result: pass

The cycle baseline is `c0424e7e`, whose accepted compiler_rt report is 443
selected / 256 emitting / 187 failing. Captured compiler_rt IR md5 is
`b0eda7a6427c3084fdf096a68696f19c`; the stage4 Zig pin is
`bdee02bc0c7f227c0f11bc9a449df673fe803540`. The production and permanent-test
diff has sha256
`47df69709657b74dc5c2f648cdb0d893b4ffab88b64768b65dd338910b5ae04a`.

The composed selector now admits exact non-`samesign` named-operand i16
`slt`, `sgt`, and `ne`. Both operands use the existing scalar scratch path,
are sign-normalized from their low 16 bits with existing shifts, and then use
the existing i32 compare and setcc forms. No machine instruction, encoding,
or verifier surface changed. Named comparisons at neighboring i15/i17 widths
and `samesign` near misses remain fail-closed.

Permanent selector coverage checks all three admitted predicates, both
neighboring widths, and executable results over raw half encodings. The
matrix includes positive and negative zero, subnormals, normals, infinities,
quiet NaNs, and signaling NaNs. Expected results are precomputed integer
comparison outcomes; no host floating-point comparison is used.

Fresh report-all moves exactly from 443 / 256 / 187 to 443 / 258 / 185. The
two expected rows disappear from the failure report with no collateral
emissions:

- `compiler_rt.gehf2.__gehf2`;
- `compiler_rt.comparef.__cmphf2`.

A structured extraction containing exactly those two captured functions
emits a relocation-free ELF object with two global symbols. A pinned-Zig
`callconv(.c)` executable invokes both z_llvm functions for 14 precomputed
raw-half pairs, or 28 exact calls. It proves ordinary ordering and equality,
signed-zero equality, both subnormal signs, both infinity signs, and the
distinct required unordered results: `__gehf2` returns -1 while `__cmphf2`
returns +1 for quiet and signaling NaNs on either side.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=258 failed_functions=185 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
native rows: symbols=2 relocations=0 raw_half_pairs=14/14 exact_calls=28/28
tier2: pass; steps=24/24 tests=980/980
```

No Tier 3 ran in this capability commit. The later cumulative INBOX-46 gate
accepted both rows; see
`docs/evidence/distribution_all_after_inbox46_named_i16_i128_compare.md`.

Artifacts:

- current-source z_llvm, sha256
  `88855447d027219495521655ca611c9ced7a82b006e8f9b0e928487551969f13`;
- `tmp/inbox46_named_i16_report.log`, sha256
  `aef0631d1d367e64f5bdea8642b2b52ebe6788d358547084bd64f1715072dd4f`;
- `tmp/inbox46_named_i16_rows.ll`, sha256
  `b04b3f1208ca4e6a74306a8d0659a9d291f5300664c3c137985c02584f3f2f1c`;
- `tmp/inbox46_named_i16_rows.o`, sha256
  `e2d6d20c3ddd8a5cb8780df9a878fb2ec5e91787f58dd947c312a4a13e953ecb`;
- `tmp/inbox46_named_i16_start.zig`, sha256
  `ad190f5c0e83ab7aac73caa090d78539e86e9c9056046b93ec47dcd830453251`;
- `tmp/inbox46_named_i16_acceptance`, sha256
  `9e824acfb0f11ba94555d7f869b974134fa96fe7fed5b6fc80ceda5e535b497f`;
- `tmp/inbox46_named_i16_rows_readelf.log`, sha256
  `31420bdb377168d7a05635a286c9fe99db5e11bb1a47fa7ac62b3af4e9fe73e2`;
- `tmp/inbox46_named_i16_rows_objdump.log`, sha256
  `62266cc976c8ae20733d36e4c474a558ed16ba4bfab561bac444c13dbd6110ab`;
- `tmp/inbox46_named_i16_tier2.log`, sha256
  `5f4b32f8d1c151dc88324a97690d8732735871418e92f0468295f2e3e1353218`.
