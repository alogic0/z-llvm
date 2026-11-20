# Distribution-All After Half Addition

schema_version: 1
directive: `INBOX-40 pre-authorized successor`
cycle: `half-fadd`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `25052481` plus
production and permanent-test diff sha256
`5400ac64c450ff92fb7bd609bab2ec6ff695354aa5bc7dcde870b6fce78aabf8`.
The current-source ReleaseFast z_llvm has sha256
`fabb6f5dcf9dd7f448e06b28fbcd438fe17c4bb21bee811f4ae11b02becd2ccc`.

Changed subsystem: x86_64 composed-selector half addition, exact i16 scalar
prerequisites, and captured stack-memory-barrier frame/call/memory handling.

Tier-3 trigger: exact half addition closes
`compiler_rt.floor_ceil.__floorh` and `__ceilh` through shared selector, CFG,
frame, call, memory, and helper-call surfaces.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox40_half_fadd.log 2>&1
```

Prior evidence cannot be reused because the INBOX-40 Part 1 Tier 3 predates
half extend-add-truncate composition, the captured half/pointer local-memory
barrier path, exact i16 shift/sign prerequisites, half literal materialization,
their permanent executable regressions, two directed closures, and one
collateral emission. The preface was recorded before the single invocation in
`tmp/inbox40_half_fadd_tier3_preface.txt`, sha256
`d099b1e0c26c17238ccd677d3f46cf9748c9236a6d27ebbd1e9a68525509cd51`.

The invocation passed all 17 subgates. Strict real-row gates remain green at
100 rows in ReleaseFast, ReleaseSafe, and ReleaseSmall; all three 146-row
integrated-object modes are green; the integrated executable suite remains
5/5; release-source object inspection, native link, and compatibility remain
100/100.

```text
summary zig-integrated-object pipeline=postopt total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=true total=146 executable_ok=146 local_fail=0
summary distribution-real-rows mode=ReleaseFast limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 local_fail=0
summary native-link-object-inspection inventory=release-source-owned inspected=100 elf64_rel=100 unsupported_relocation_rows=0 local_fail=0
summary distribution-native-link inventory=release-source-owned total=100 executable_abi_proof_rows=100 local_object_codegen_failures=0 local_fail=0
summary native-link-probe inventory=release-source-owned accepted=100 local_object_codegen_failures=0 failed=0
summary distribution-all-timing subgates=17 total_duration_ms=2317643 cache_hit_subgates=3 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Log: `tmp/distribution_all_after_inbox40_half_fadd.log`, sha256
`0f5600ab8a98c2510767660a81f4514043b0ac46e77a28d13dad5e3221748473`.
