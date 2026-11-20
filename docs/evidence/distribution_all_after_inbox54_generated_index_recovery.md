# Distribution-All After INBOX-54 Generated-Index Recovery

schema_version: 1
directive: `INBOX-54`
target: `x86_64-linux-gnu`
status: pass

Staged implementation tree identity before the run:
`0ea52d889d0d48a41fd8218893a8188fe4c916fe`, based on accepted commit
`aadeb6ad`.

Changed subsystem: x86_64 generic-CFG stack-`i32` load accumulator ownership
and permanent exact compiler_rt executable coverage.

Tier-3 trigger: confirmed wrong-code in an accepted shared selector path. A
stack load overwrote EAX while an i64 accumulator value remained live only
through a PHI edge, producing a generated index of `0x80000001`.

Exact command and log:

```text
zig build distribution-all --summary all > tmp/distribution_all_after_inbox54_generated_index_recovery.log 2>&1
```

Prior evidence cannot be reused because every earlier Tier-3 result predates
the stack-load accumulator repair and cannot prove either the generated-index
correction or the exact six-row quotient/remainder matrix. All 17 subgates
pass:

```text
summary zig-integrated-object pipeline=postopt total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=true total=146 executable_ok=146 local_fail=0
summary distribution-real-rows mode=ReleaseFast limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary zig-integrated-exe total=6 build_ok=6 run_ok=6 stdout_ok=6 exit_ok=6 local_fail=0
summary native-link-object-inspection inventory=release-source-owned inspected=100 elf64_rel=100 local_fail=0
summary distribution-native-link inventory=release-source-owned total=100 executable_abi_proof_rows=100 local_fail=0
summary native-link-probe inventory=release-source-owned accepted=100 failed=0
summary distribution-all-timing subgates=17 total_duration_ms=2085875 cache_hit_subgates=3 cache_miss_subgates=0 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Actual wall time was approximately 1,381.901 seconds (23m01.901s), measured
from the log birth and final modification timestamps. Summed child duration
was 2,085.875 seconds and is not wall time.

This gate accepts the INBOX-54 P0 and re-accepts the exact semantic closures
of `compiler_rt.udivmodei4.__udivei5` and
`compiler_rt.udivmodei4.__umodei4`. It also re-proves the four accepted signed
siblings identified by the object audit: `__divei4`, `__divei5`, `__modei4`,
and `__modei5`. The permanent native canary executes 54 independently checked
quotient/remainder operations. Report-all remains exactly 443 selected / 284
emitting / 159 failing; this is a correctness recovery, not a counter move.

Artifacts:

- preface `tmp/inbox54_generated_index_recovery_tier3_preface.txt`, sha256
  `0e64ff22c50c0fb09788298a07b57eb406fb23678a3e16831afb4fe61dcca844`;
- accepted log
  `tmp/distribution_all_after_inbox54_generated_index_recovery.log`, sha256
  `1e9f6808399e109966669f882ca9b3d9ff0823bfe690e333bbe39f2b74f17b8b`.

No fma capability or preopt sharding work is included. Stop after this
acceptance and request the required review.
