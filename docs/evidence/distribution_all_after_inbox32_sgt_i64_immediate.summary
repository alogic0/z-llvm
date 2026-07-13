# Distribution-All After Signed-Greater I64 Immediate

schema_version: 1
directive: `INBOX-32` pre-authorized successor
cycle: `sgt-i64-immediate`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `17259c21` plus
staged implementation and acceptance diff sha256
`bb1b8da4bb4d02c59596d7fe8dd5ff2c1bdd42ac5a53cb50125cbca5bca45e6b`.

Changed subsystem: the composed x86_64 scalar selector's exact plain i64
signed-greater immediate admission and permanent executable boundary coverage.

Tier-3 trigger: the directed `compiler_rt.exp2.exp2` row closure is an
evidence-backed milestone under `docs/validation_tiers.md`, and INBOX-32
requires the successor to follow the same one-Tier-3 row-closure rule.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox32_sgt_i64_immediate.log 2>&1
```

Prior evidence cannot be reused because the accepted named-i1-OR Tier 3
predates the new i64 signed comparison, its permanent executable boundary
cases, and the newly closed `exp2` body. The Zig pin, target, corpus, and
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
summary distribution-all-timing subgates=17 total_duration_ms=2279543 cache_hit_subgates=3 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Log: `tmp/distribution_all_after_inbox32_sgt_i64_immediate.log`, sha256
`4de4516c43bda6df700b6b1e39f9a14f901db8cec57ad94a10044194522ddc2b`.
