# Distribution-All After INBOX-49 Baseline Popcount P0

schema_version: 1
directive: `self-declared P0 during INBOX-49 Part 2`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: baseline commit `778b13aa`, staged
tree `a938272b6c22a4cb07393de498cfc0d53223f498`, and staged diff sha256
`1c347ff6dd1d5041b309803e1c4c17725980729232f89c75ede9c1aa2821c5bc`.

Changed subsystem: x86_64 machine encoding/assembly for scalar i32 popcount
and the terminal compiler_rt limb64 selector byte routine.

Tier-3 trigger: confirmed wrong-code repairs require immediate Tier 3 under
`docs/validation_tiers.md`. Accepted objects used POPCNT despite captured
`-popcnt` target attributes.

Exact accepted command and log:

```text
zig build distribution-all --summary all > tmp/distribution_all_after_inbox49_popcount_p0.log 2>&1
```

Prior evidence cannot be reused because every accepted Tier-3 result predates
the replacement of host-dependent POPCNT instructions and therefore cannot
prove either repaired accepted row or the shared machine/encoder surfaces.
The full run passes all 17 subgates.

```text
summary zig-integrated-object pipeline=postopt total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=true total=146 executable_ok=146 local_fail=0
summary distribution-real-rows mode=ReleaseFast limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-native-link inventory=release-source-owned total=100 executable_abi_proof_rows=100 local_fail=0
summary native-link-object-inspection inventory=release-source-owned inspected=100 elf64_rel=100 local_fail=0
summary native-link-probe inventory=release-source-owned accepted=100 failed=0
summary distribution-all-timing subgates=17 total_duration_ms=2430852 cache_hit_subgates=3 cache_miss_subgates=0 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Artifacts:

- preface `tmp/inbox49_popcount_p0_tier3_preface.txt`, sha256
  `2d2e0911c7dfbfeb886f0e96a72e3f3672a09cba7effeafd539acaccb65d5ac6`;
- accepted full log `tmp/distribution_all_after_inbox49_popcount_p0.log`,
  sha256
  `75c6370e83984472d31eab987117d7d4937f1e231c1550b4a5a33e21a2c80b38`.

This accepts the standalone correctness repair and both invalidated-row
re-proofs. It does not accept or implement the preserved INBOX-49 Part 2
range-attributed i64/i128 popcount capability.
