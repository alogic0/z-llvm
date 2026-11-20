# Distribution-All After INBOX-27 Alloca/Spill Repair

schema_version: 1
directive: `INBOX-27` Part 1
cycle: `alloca-spill-collision-repair`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `656582a7` plus
implementation-only staged tree
`6baea004319537873f96adef3ed4e168b9209270`.

Changed subsystem: the composed selector's shared stack-frame authority and
alloca planning. Every alloca-bearing function now reserves the convenience-
spill range before payload objects are assigned offsets.

Tier-3 trigger: `docs/validation_tiers.md` requires full integration after a
shared frame-layout change.

Exact command and log:

```text
zig build distribution-all >tmp/distribution_all_after_inbox27_alloca_spill_collision.log 2>&1
```

The accepted INBOX-26 result cannot be reused because it predates the changed
frame offsets for all alloca-bearing composed-selector functions. The command
completed successfully. Log sha256:
`01973082e7aabf9b3448ee01874e65cd8a3767b1ae67cc2c4049e4aac29cd2af`.

Acceptance summaries:

```text
summary distribution-real-rows mode=ReleaseFast limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 first_failing_real_row=- first_failing_stage=- local_fail=0
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 local_fail=0
summary native-link-object-inspection inventory=release-source-owned inspected=100 elf64_rel=100 unsupported_relocation_rows=0 local_fail=0
summary distribution-native-link inventory=release-source-owned total=100 executable_abi_proof_rows=100 local_object_codegen_failures=0 local_fail=0
summary distribution-all-timing subgates=17 total_duration_ms=2274211 cache_hit_subgates=3 cache_none_subgates=14 local_fail=0
ok distribution all gates
```
