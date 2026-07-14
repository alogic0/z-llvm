# Distribution-All After Exact Signed I32 Division By Two

schema_version: 1
directive: `INBOX-39 Part 1`
cycle: `exact-sdiv-i32-by-two`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `e4507f60` plus
staged production and permanent-test diff sha256
`7968f4d804a5045b61667ce41e7d76210eb438834c1db67e0358bd1cd20bb60b`.
The current-source ReleaseFast z_llvm has sha256
`2ea7e44fc804279a5da7786095b5b8a94525d82d0c961ce66d3d1b069484873d`.

Changed subsystem: x86_64 composed-selector exact signed i32 division and
conditional-phi edge-source stabilization.

Tier-3 trigger: the reusable division form closes `__powidf2` and `__powisf2`,
and exact row execution exposed and repaired a stale conditional-phi source
binding through the shared selector CFG surface.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox39_sdiv2.log 2>&1
```

Prior evidence cannot be reused because every accepted Tier 3 predates the
exact truncation-toward-zero lowering, the conditional-phi stabilization
repair, their permanent regressions, and the two newly emitting rows. The
preface was recorded before the single invocation in
`tmp/inbox39_sdiv2_tier3_preface.txt`, sha256
`ccb0f2183012b27aa25174523e8b2a37e78bf78a1510e7cae302eb33657224cc`.

The invocation passed all 17 subgates. Strict real-row gates remain green at
100 rows in ReleaseFast, ReleaseSafe, and ReleaseSmall; all three 146-row
integrated-object modes are green; the integrated executable suite remains
5/5; release-source object inspection, native link, and native-link
compatibility remain 100/100.

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
summary distribution-all-timing subgates=17 total_duration_ms=2266064 cache_hit_subgates=3 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Log: `tmp/distribution_all_after_inbox39_sdiv2.log`, sha256
`c38ebbdbd9c55e85788e8f209df27b4cc088f8106bc3ebd05787ca9d41478f5e`.
