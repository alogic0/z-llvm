# Distribution-All After Half-To-Double Extension Composition

schema_version: 1
directive: `INBOX-39 pre-authorized successor`
cycle: `half-to-double-fpext-composition`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `e6166c0a` plus
staged production and permanent-test diff sha256
`8830909c56ae3fe746c51c2c4945462cb96f6c82d22085c5ceb6426fc79c056f`.
The current-source ReleaseFast z_llvm has sha256
`80cb404747a0147e540987ea908df6c7f241f54f17061888ae5fa92734fde74e`.

Changed subsystem: x86_64 composed-selector half extension and implicit
scalar-SSE helper-call frame reservation.

Tier-3 trigger: exact half-to-double extension closes
`compiler_rt.fma.__fmah`, and the row's three helper calls required a shared
frame/call preplanning repair so live XMM values can use the existing spill
authority.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox39_half_double.log 2>&1
```

Prior evidence cannot be reused because the INBOX-39 Part 1 Tier 3 predates
half-to-double extension, implicit half-conversion helper frame reservation,
their permanent regressions, and the newly emitting row. The preface was
recorded before the single invocation in
`tmp/inbox39_half_double_tier3_preface.txt`, sha256
`7a0dd36a749da7a15b8568a1ce014d3fa0747ffcff54241f573921844340aeca`.

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
summary distribution-all-timing subgates=17 total_duration_ms=2314605 cache_hit_subgates=3 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Log: `tmp/distribution_all_after_inbox39_half_double.log`, sha256
`168ee043685f0c64ac68c7c55048642967cf12b4aa93405fd71b87122e130423`.
