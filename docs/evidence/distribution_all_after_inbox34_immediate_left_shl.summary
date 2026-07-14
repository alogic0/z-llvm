# Distribution-All After Immediate-Left I32 Shift

schema_version: 1
directive: `INBOX-34 pre-authorized successor`
cycle: `immediate-left-i32-shl`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `b24a988f` plus
staged implementation and permanent-test diff sha256
`cf66b50536e9a216951b95b710f62ef1ab240dee7ea847a9ea9169e2d35fc472`.

Changed subsystem: the composed x86_64 scalar selector's typed
immediate-left binary matrix and permanent executable shift regression.

Tier-3 trigger: the directed `ceilf` and `floorf` row closures are an
evidence-backed milestone under `docs/validation_tiers.md` and the INBOX-34
row-closure contract.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox34_immediate_left_shl.log 2>&1
```

Prior evidence cannot be reused because the named-inequality Tier 3 predates
the exact immediate-left i32 shift form, its permanent executable coverage,
and the two newly closed floor/ceil bodies. The Zig pin, target, corpus, and
pipeline arguments are unchanged; the relevant selector source state and
expected-result contract are not.

The preface and staged implementation identity above were recorded before the
single required invocation.

The invocation passed all 17 subgates. Strict real-row gates remain green at
100 rows in ReleaseFast, ReleaseSafe, and ReleaseSmall; the integrated
executable suite remains 5/5; release-source object inspection, native link,
and native-link compatibility remain 100/100.

```text
summary distribution-real-rows mode=ReleaseFast limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 local_fail=0
summary native-link-object-inspection inventory=release-source-owned inspected=100 elf64_rel=100 unsupported_relocation_rows=0 local_fail=0
summary distribution-native-link inventory=release-source-owned total=100 executable_abi_proof_rows=100 local_object_codegen_failures=0 local_fail=0
summary native-link-probe inventory=release-source-owned accepted=100 local_object_codegen_failures=0 failed=0
summary distribution-all-timing subgates=17 total_duration_ms=2324160 cache_hit_subgates=3 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Log: `tmp/distribution_all_after_inbox34_immediate_left_shl.log`,
sha256 `b606a4bd54ec2aa952fa9520c60959f0bc09e522ea04e18cdcf6be80134d9d03`.
