# Distribution-All After Exact F32 Aggregate Stack Objects

schema_version: 1
directive: `INBOX-42`
cycle: `exact-f32-aggregate-stack-object`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `4e0645bf` plus
implementation-only staged tree
`943de086aa1c01775b2ad14c9a7324581fd72fcb`.

Changed subsystem: composed-selector frame objects, typed stack-pointer value
locations, allocation-planner liveness, pointer-PHI edge materialization,
bounded scalar stores and packed loads, and verifier XMM definedness.

Tier-3 trigger: `docs/validation_tiers.md` requires full integration after
changes to shared frame layout and register-allocation behavior. This exact
8-byte, 4-aligned aggregate object is allocated by the existing frame authority
and its pointer can cross CFG edges through existing register or spill homes.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox42_aggregate_object.log 2>&1
```

Prior evidence cannot be reused because the accepted INBOX-42 slice-1 run
predates the aggregate frame object, bounded field pointers, frame-object PHI
sources, packed stack loads, and the correction that keeps pressure-exempt
frame objects out of `phi_out` register allocation.

The single invocation passed all 17 subgates. All three 146-row integrated-
object pipelines, the 100-row release-source-owned pipeline, and strict real-
row gates in ReleaseFast, ReleaseSafe, and ReleaseSmall remain green. The six
permanent integrated executables and both 100-row native-link ownership gates
also remain green.

```text
summary zig-integrated-object pipeline=postopt ir_writer=false total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=false total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=true total=146 executable_ok=146 local_fail=0
summary distribution-real-rows mode=ReleaseFast limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary zig-integrated-exe total=6 build_ok=6 run_ok=6 stdout_ok=6 exit_ok=6 local_fail=0
summary native-link-object-inspection inventory=release-source-owned inspected=100 elf64_rel=100 unsupported_relocation_rows=0 local_fail=0
summary distribution-native-link inventory=release-source-owned total=100 executable_abi_proof_rows=100 local_object_codegen_failures=0 local_fail=0
summary native-link-probe inventory=release-source-owned accepted=100 local_object_codegen_failures=0 failed=0
summary distribution-all-timing subgates=17 total_duration_ms=2394083 cache_hit_subgates=3 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

The previous accepted run took 2,311,993 ms. This run took 2,394,083 ms, an
increase of 82,090 ms (about 3.6%), so runtime has not changed materially.

Log: `tmp/distribution_all_after_inbox42_aggregate_object.log`, sha256
`7cb780d87daa1a3b422231b9c4c8459829caf36c3d7aced5b316f85d93296bc3`.
