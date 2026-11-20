# INBOX-50 Named I64 ULT Provisional Acceptance

schema_version: 1
directive: `INBOX-50 comparison-RHS cycle 2`
target: `x86_64-linux`
validation_tier: 2
result: pass
closure_status: provisional

The accepted baseline is the INBOX-50 Part 1 state at 443 selected / 270
emitting / 173 failing. Comparison cycle 1 at `0f8e243a` contributes zero
provisional closures. Captured compiler_rt IR md5 is
`b0eda7a6427c3084fdf096a68696f19c`, and the stage4 pin is
`bdee02bc0c7f227c0f11bc9a449df673fe803540`.

The scalar comparison selector now admits only plain named `icmp ult i64`.
It materializes the LHS in R8 and RHS in RCX, emits `cmp rcx, r8`, and consumes
the unsigned-below flag with `setb`. The structural test fixes this operand
order. Ten executable cases force equality, both small asymmetric orders, the
signed/unsigned high-bit crossing, and both orders around `maxInt(u64)`.
The samesign form remains fail-closed; immediate, other-width, and other-
predicate ownership is unchanged.

Full unit passes 1002/1002. Tier 2 passes 24/24 steps and 1010/1010 tests.
Fresh report-all moves exactly from 443 / 270 / 173 to 443 / 272 / 171,
provisionally closing `compiler_rt.truncdfsf2.__truncdfsf2` and
`compiler_rt.truncdfhf2.__truncdfhf2`, with no collateral emission or new
failure.

A structured parser extracts exactly those two captured bodies. z_llvm emits
a relocation-free ELF object with two 979-byte global functions. A pinned-Zig
`callconv(.c)` executable checks 23 frozen double inputs against precomputed
float and half results, 46 exact calls total. The matrix covers signed zeros,
double underflow, float subnormal/normal transitions, half normal and rounding
transitions, finite overflow, infinities, and positive/negative quiet and
signaling NaN payload behavior.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=272 failed_functions=171 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
report delta: directed_closures=2 collateral_emissions=0 new_failures=0
native rows: symbols=2 relocations=0 truncdfsf2_cases=23/23 truncdfhf2_cases=23/23
full unit: pass; tests=1002/1002
tier2: pass; steps=24/24 tests=1010/1010
tier3: not run; reserved for cumulative INBOX-50 comparison-pipeline acceptance
```

Artifacts:

- report `tmp/inbox50_i64_ult_report.log`, sha256
  `ff99ba8aecc06b20e9b1d8011057bc45a469e8319f551391f43241eb5109ce59`;
- Tier-2 log `tmp/inbox50_i64_ult_tier2.log`, sha256
  `a401c9f8076506d5d7eb3132a18bc0a6455826c032b12e188db1a66c72c18c07`;
- extracted IR `tmp/inbox50_truncdf_rows.ll`, sha256
  `5c52eea9edec35c78dc327ac3399bcd0caf48ad836b861e575739e9ca923050a`;
- emitted object `tmp/inbox50_truncdf_rows.o`, sha256
  `3cf0778e7911bb6c0b4cca06c646724ab001a292d212d52332b278ad2fc9ec4d`;
- readelf log `tmp/inbox50_truncdf_readelf.log`, sha256
  `1202f4fb3615ca0e5d660a93aaad30b8c26dddfdd0c9db020511213c82f9a90d`;
- objdump log `tmp/inbox50_truncdf_objdump.log`, sha256
  `ac9fa72855d6b999ff4834b292ac3227c30ff040c4d0e1ed731f517ae762e1e9`;
- pinned executable `tmp/inbox50_truncdf_acceptance`, sha256
  `d75502f1c37d267169578f87e24497708d9d31c533553b6ae6f8787696e6542f`;
- frozen-reference output `tmp/inbox50_truncdf_reference.log`, sha256
  `d453059ef6fe3f46b40c07264238ba1cd69899973b074b590c06d248e6453899`.

Commit this provisional cycle, then run the one cumulative Tier 3 for the
complete INBOX-50 comparison pipeline. The pipeline has two, not four,
provisional closures because cycle 1 exposed later half frontiers.
