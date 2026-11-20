# Distribution-All After INBOX-53 Narrow-Return P0

schema_version: 1
directive: `INBOX-53 continuation, self-declared P0 correctness interrupt`
target: `x86_64-linux-gnu`
status: pass

Standalone staged implementation tree identity before the run:
`6a2fb4a2b42f53f198aa67835b0239c26d3ea2a0`. The INBOX-53 Phase 4 cycle-2
changes were stashed and are not part of this tree.

Changed subsystem: x86_64 generic-CFG specialized direct-call ABI lowering
and permanent executable selector coverage.

Tier-3 trigger: confirmed wrong-code in an accepted shared call path. The i16
`zig.target.intByteSize` result retained ABI-undefined upper EAX bits.

Exact command and log:

```text
zig build distribution-all --summary all > tmp/distribution_all_after_inbox53_intbytesize_p0.log 2>&1
```

Prior evidence cannot be reused because it predates the i16 return
normalization and cannot prove captured-row call behavior or the hostile
upper-EAX correction. All 17 subgates pass:

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
summary distribution-all-timing subgates=17 total_duration_ms=2043308 cache_hit_subgates=3 cache_miss_subgates=0 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Actual wall time was approximately 1,357.356 seconds (22m37.356s), measured
from 22:05:40.812 to 22:28:18.168. Summed child duration was 2,043.308
seconds and is not wall time.

This accepts only the standalone narrow-return P0. It does not re-accept the
audited `__udivei5` or `__umodei4` semantic closures; the separate general
division generated-index failure remains open as recorded in the focused
evidence.

Artifacts:

- preface `tmp/inbox53_intbytesize_p0_tier3_preface.txt`, sha256
  `959a80d8d0bbbc92fbc449de1140ff7c0bed18e2b622537c73d71d351197816e`;
- accepted log `tmp/distribution_all_after_inbox53_intbytesize_p0.log`,
  sha256
  `a430aaf2c8c400d2f5ba1139b67a0c7605586e9467bf7b6f9ebba972bf2daade`.
