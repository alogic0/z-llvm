# INBOX-48 Bit-Permutation Leaves Provisional Acceptance

schema_version: 1
directive: `INBOX-48 successor`
target: `x86_64-linux`
validation_tier: 2
result: pass
closure_status: provisional

The accepted f64x2 PHI baseline is `0d568bfe`, with compiler_rt report state
443 selected / 261 emitting / 182 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`. The production and permanent-test
diff has sha256
`95e68e8a52dc92795154ecc3036549611aa0b3ed92c5496b92e2b7c43ea0eaec`.

The composed selector now admits exactly `llvm.bswap.i128(i128)`,
`llvm.bitreverse.i64(i64)`, and `llvm.bitreverse.i128(i128)` as direct calls
with an absent or advisory `tail` marker. Result and operand widths must match
the intrinsic exactly. Wrong widths, `llvm.bswap.i64`, `musttail`, indirect or
inline-assembly forms, raw arguments, operand bundles, and other LLVM
intrinsics remain fail-closed.

The machine layer adds one `bit_reverse_rax` operation. It byte-swaps RAX and
then performs exact nibble, pair-bit, and adjacent-bit permutations with the
three 64-bit masks. Its RCX/RDX scratch clobbers are explicit at the selector
call site. Encoding and assembly tests cover the 93-byte operation, and the
machine verifier records its RAX result.

I128 byte-swap and bit-reverse reuse the existing SysV pair value, pair-spill,
and frame-object authorities. The exact i128 calls reserve the ordinary spill
area, stabilize the source as one existing two-slot pair spill, transform the
two limbs through RAX, exchange limb positions, and bind the result in the
existing R8:R9 scratch pair. No new value location, spill namespace, frame
layout rule, ABI classifier, relocation, or linker behavior is introduced.

Permanent executable coverage checks zeros, both end bits, all ones, and
asymmetric patterned values. The expected values are literal precomputed bit
patterns, including cross-limb i128 reversal. Structural negatives cover wrong
return and operand widths, `musttail`, and the deliberately unsupported i64
byte-swap form.

Fresh report-all moves exactly from 443 / 261 / 182 to 443 / 264 / 179. The
three expected rows disappear from the failure report with no collateral
emission and no new failure:

- `compiler_rt.bswap.__bswapti2`;
- `compiler_rt.bitreverse.__bitreversedi2`;
- `compiler_rt.bitreverse.__bitreverseti2`.

A structured extraction containing exactly those three captured wrappers
emits a relocation-free ELF object with three global function symbols. A
pinned-Zig `callconv(.c)` executable invokes the z_llvm rows for 14 precomputed
cases: five i64 bit reversals, four i128 byte swaps, and five i128 bit
reversals. Every exact result matches.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=264 failed_functions=179 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
report delta: directed_closures=3 collateral_emissions=0 new_failures=0
native rows: symbols=3 relocations=0 precomputed_cases=14/14
full unit: pass; tests=987/987
tier2: pass; steps=24/24 tests=995/995
tier3: not run; reserved for cumulative bit-permutation pipeline acceptance
```

Commands:

```text
zig build test --summary all
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
tmp/inbox48_bit_permutation_install/bin/z_llvm --emit=obj --target=x86_64-linux --generic-cfg-selector --report-all-codegen-failures --input-limit=134217728 <captured-compiler-rt.ll>
../ziglang/build/stage4/bin/zig build-exe -fno-lld -target x86_64-linux-gnu tmp/inbox48_bit_permutation_start.zig tmp/inbox48_bit_permutation_rows.o -femit-bin=tmp/inbox48_bit_permutation_acceptance
```

Artifacts:

- current-source z_llvm, sha256
  `5c49aa8c73c161c7967c680ab2c46c1ccec7d2786144ff9b9b3671bbe8980360`;
- `tmp/inbox48_bit_permutation_report.log`, sha256
  `603698bb434cf71eaeee2c60b707d82fae0051d0c542235dab5c7bab93849453`;
- `tmp/inbox48_bit_permutation_rows.ll`, sha256
  `80034a8ba52b7000a9d4eaf254503cf78c4d5096e050bd6bdb25afe3a3fc2568`;
- `tmp/inbox48_bit_permutation_rows.o`, sha256
  `456a13337538b0038763d054c50641613b47b2bbec0efa545ae8fa0caf260e31`;
- `tmp/inbox48_bit_permutation_rows_readelf.log`, sha256
  `04253854cdd1a1a328387c20336215b36eec979886ba44b5164ef1fac601e457`;
- `tmp/inbox48_bit_permutation_rows_objdump.log`, sha256
  `74f9d8cfbe922de48cbdb5678fb34653b1f776ab4cd6bfb7bbb978d157a46968`;
- `tmp/inbox48_bit_permutation_start.zig`, sha256
  `ccd7b8e9c0d8f9d3d1cde20ef33e7e8f929bae1fc3c50321c39a7d060e6d5118`;
- `tmp/inbox48_bit_permutation_acceptance`, sha256
  `56d3b2c440d32f97aedc0f59fca17a54071eea3a9dfb5a70ed33bdc0f3655914`;
- `tmp/inbox48_bit_permutation_tier2.log`, sha256
  `d2392e09a0fe474ecf3e62f362e623260175aa05a58e16bc6e1180dcd0e938b4`.

Commit this provisional three-row slice, then run the single cumulative Tier 3
for the bit-permutation pipeline.
