# INBOX-49 Baseline Popcount P0 Repair

schema_version: 1
directive: `self-declared P0 during INBOX-49 Part 2`
target: `x86_64-linux-gnu`
validation_tier: 3
result: pass

The INBOX-49 audit found two accepted paths that genuinely violated the
captured x86-64 baseline. Both `frontier_mixed_numeric.frontier_popcount_u32`
and `compiler_rt.limb64.__popcount_limb64` emitted POPCNT even though the
captured target attributes explicitly contain `-popcnt`. Their executable
proofs passed only because the validation host advertises POPCNT. Both
accepted claims are invalidated until this repair and their row-exact
semantic re-proofs are accepted.

The reusable i32 machine operation now uses a 21-byte Kernighan software
loop. The terminal limb64 routine preserves its established outer byte
layout by replacing each five-byte `popcntq` with a same-size relative call
to one appended software helper. No target-feature inference is introduced,
and emitted assembly and object bytes for both paths contain no POPCNT
instruction.

Permanent executable tests cover the i32 machine operation at zero, one,
the high bit, all bits, and a mixed pattern. The limb64 selector test executes
the complete terminal routine at bit lengths 0, 1, 64, 65, and 127. The full
unit suite passes 991/991; Tier 2 passes 24/24 steps and 999/999 tests.

Accepted-row re-proof is explicit:

- the existing `frontier_mixed_numeric` native harness executes
  `frontier_popcount_u32` at zero, all bits, a sparse high/low pair, and a
  mixed pattern; that source module links and exits zero with the repair;
- the structured parser extracts exactly
  `compiler_rt.limb64.__popcount_limb64` from captured compiler_rt IR md5
  `b0eda7a6427c3084fdf096a68696f19c`; its relocation-free 824-byte object
  contains no POPCNT and a pinned-Zig caller passes seven exact results for
  bit lengths 0, 1, 16, 64, 65, 127, and 128.

The direct `distribution-air-release-frontier` invocation is not relabeled
green: `frontier_mixed_numeric` passes, but the umbrella gate later exits one
for the pre-existing `frontier_optionals_errors` native-link failure. That
unrelated failure does not weaken the row-specific positive proof and is
reported honestly rather than hidden.

```text
full unit: pass; tests=991/991
tier2: pass; steps=24/24 tests=999/999
frontier_mixed_numeric: executable-ok
limb64 extracted native: cases=7/7 relocations=0 popcnt=absent
closure accounting: none; standalone correctness repair
tier3: pass; subgates=17 local_fail=0
```

Commands:

```text
zig build test --summary all
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
zig build distribution-air-release-frontier --summary all
tmp/inbox49_popcount_p0_install/bin/z_llvm --emit=obj --target=x86_64-linux --generic-cfg-selector --input-limit=134217728 tmp/inbox49_popcount_limb64.ll
../ziglang/build/stage4/bin/zig build-exe -fno-lld -target x86_64-linux-gnu tmp/inbox49_popcount_limb64_start.zig tmp/inbox49_popcount_limb64.o -femit-bin=tmp/inbox49_popcount_limb64_acceptance
```

Artifacts:

- `tmp/inbox49_popcount_p0_tier2.log`, sha256
  `cb13f6c3e2c69beae453fe8dd2ea15e0ad93f88e325821be5211ee32941cefa4`;
- `tmp/inbox49_popcount_limb64.ll`, sha256
  `de69df3e9453e5f9c41d493dbef7846f706657c4c6456c61ebfe3621083fd433`;
- `tmp/inbox49_popcount_limb64.o`, sha256
  `4d17865e87be1d56e8a600aa3680d2b50854c4a990f6b9b1c67f59b5d78494e3`;
- `tmp/inbox49_popcount_limb64_objdump.log`, sha256
  `9c81df7c9705eed2bad759095118cd38cfcc6f0120461e35a0979ed410303949`;
- `tmp/inbox49_popcount_limb64_acceptance`, sha256
  `58583d7bb413966b5f08a97b3327cd8bbebc15aec5edb82838cae68749cecdb7`.

The mandatory immediate Tier 3 passes and is recorded in
`docs/evidence/distribution_all_after_inbox49_popcount_p0.md`. Accept the
P0 as a standalone commit, then resume the preserved INBOX-49 Part 2 range-
attribute capability.
