# Distribution-All After Half Comparisons

schema_version: 1
directive: `INBOX-40 Part 1`
cycle: `half-fcmp-uno-olt`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `c7672a26` plus
production and permanent-test diff sha256
`371748460161953366b0418e84d1db22e3b0002e7acaebb9baae8a3ea52c4916`.
The current-source ReleaseFast z_llvm has sha256
`762d69ee1854a186fc3113b2fa34fa517d5a6253f86ffbfe3f8c4b2b24202b18`.

Changed subsystem: x86_64 composed-selector half comparison, scalar half
select, exact i16 signed-zero comparison, and helper-call frame preservation.

Tier-3 trigger: exact half comparison closes `compiler_rt.fmin.__fminh` and
`compiler_rt.fmax.__fmaxh` through shared selector, CFG, and helper-call frame
surfaces.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox40_half_fcmp.log 2>&1
```

Prior evidence cannot be reused because the INBOX-39 successor Tier 3 predates
the admitted widened predicates, intra-instruction preservation across two
helper calls, exact i16 comparison prerequisite, half payload selects,
permanent executable regressions, and four newly emitting rows. The preface
was recorded before the single invocation in
`tmp/inbox40_half_fcmp_tier3_preface.txt`, sha256
`28d78509687422048840e9dfac95666d60f7d8d36aeade17dffc0f2d28e3d80b`.

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
summary distribution-all-timing subgates=17 total_duration_ms=2417388 cache_hit_subgates=3 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Log: `tmp/distribution_all_after_inbox40_half_fcmp.log`, sha256
`130f3120174ee01a47198de2c7456d7ef8ccb1440eaed88610cfe9a414c0c221`.
