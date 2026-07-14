# Distribution-All After Typed I7 Binary And Stable Phi Homes

schema_version: 1
directive: `INBOX-38 Part 1`
cycle: `typed-i7-binary-stable-phi`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `f851684a` plus
staged production and permanent-test diff sha256
`146cf89be3bc9063395a1154b755909bd7422b69ffe2c4940b017a1a83fbc7de`.
The current-source ReleaseFast z_llvm has sha256
`ab9793b37a7de40c95e5e2951ffc873947f1cbdd9fc80d3d826e856ac0ad55ce`.

Changed subsystem: x86_64 composed-selector narrow integer lowering for exact
typed i7 binaries and stable framed scalar phi homes.

Tier-3 trigger: the reusable i7 capability closes
`compiler_rt.divdf3.__divdf3`, and exact executable acceptance exposed and
repaired a captured backward-phi stale-register miscompile through the shared
selector CFG and frame surfaces.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox38_i7_phi.log 2>&1
```

Prior evidence cannot be reused because the newest Tier 3 predates the i7
binary admission, the framed scalar-phi stabilization repair, its permanent
executable regressions, and the newly emitting captured row. The preface and
staged implementation identity above were recorded before the single required
invocation in `tmp/inbox38_i7_phi_tier3_preface.txt`, sha256
`6792dcebb61076a53a0dd10caa91b56a1932008fc8c70e20a77604a2f40bbf09`.

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
summary distribution-all-timing subgates=17 total_duration_ms=2267901 cache_hit_subgates=3 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Log: `tmp/distribution_all_after_inbox38_i7_phi.log`, sha256
`e231c885df3c631b4c81455aec2d60571128476b03697073fcec206399e3880c`.
