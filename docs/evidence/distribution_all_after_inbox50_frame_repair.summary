# Distribution-All After INBOX-50 Frame Repair

schema_version: 1
directive: `INBOX-50 Part 1 immediate acceptance`
target: `x86_64-linux-gnu`
status: pass

Staged implementation tree identity before the run:
`0ec31119087ee5b2ca33e104582ae6e95742432e`.

Changed subsystem: x86_64 generic-CFG allocation planning, shared frame
reservation, framed single-block parameter stabilization, and permanent
executable tests.

Tier-3 trigger: the false-rejection repair crosses the shared frame/register-
allocation boundary and provisionally closes `__divmodsi4`, `__modsi3`, and
`__divsi3`.

Exact accepted command and log:

```text
zig build distribution-all --summary all > tmp/distribution_all_after_inbox50_frame_repair.log 2>&1
```

Prior evidence cannot be reused because INBOX-49 predates preservation-demand
planning and stable single-block parameter homes. The full run passes all 17
subgates.

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
summary distribution-all-timing subgates=17 total_duration_ms=2324516 cache_hit_subgates=3 cache_miss_subgates=0 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

This accepts the shared preservation-frame repair and the exact executable
`__divmodsi4`, `__modsi3`, and `__divsi3` proofs. The compiler_rt report is
now 443 selected / 270 emitting / 173 failing. The accepted-row audit found
no prior accepted hit; `__divdi3` and `__divmoddi4` remain unaccepted at the
separate unknown-pointer call boundary.

Artifacts:

- preface `tmp/inbox50_frame_tier3_preface.txt`, sha256
  `ba3ddbb46de0506bd43828fccd94b4f45d95233a7b13e171b187c7dfdd0e34f2`;
- accepted full log `tmp/distribution_all_after_inbox50_frame_repair.log`,
  sha256
  `7038a4432baea7ecb91c5070b8a0f18edb26e012226181a1b49f3e536385e490`.

Continue with the pre-authorized INBOX-50 comparison-RHS pipeline. Its four
closures remain provisional until that pipeline's separate cumulative Tier 3.
