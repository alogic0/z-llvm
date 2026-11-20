# Distribution-All After Complete F32x4 Slice

schema_version: 1
directive: `INBOX-43`
cycle: `pre-authorized-f32x4-successor`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `078812c2` plus
staged production and permanent-test tree
`d9c26b892347d316630857c8ad70a43e2a4f523e`; the staged diff has sha256
`79b9c5c991084b617bce466e9d6ff7b80e9c316536ba40c2e0a0285203c1d9f4`.
The current-source ReleaseFast z_llvm has sha256
`15c330089611dc6514a46265e07eb4a89e92335bde42e99a9c44ae3eb1ad4b3d`.

Changed subsystem: x86_64 composed-selector four-lane vector value shapes,
definedness and shuffles, packed arithmetic/compare/fabs lowering, scalar
copysign, aggregate return materialization, SSE machine encoding, and verifier
XMM-definition tracking.

Tier-3 trigger: INBOX-43 explicitly requires one acceptance run because this
complete four-lane shape crosses shared selector, machine-encoding, aggregate
return, frame-spill, and verifier surfaces and closes
`compiler_rt.mulsc3.__mulsc3`.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox43_f32x4.log 2>&1
```

Prior evidence cannot be reused because every accepted distribution-all log
predates four-lane static definedness, the exact new shuffle forms, upper-lane
packed operations and masks, scalar copysign, physical packed-return
materialization, and corrected XMM-destination definition tracking. The
preface was recorded before the single invocation in
`tmp/inbox43_f32x4_tier3_preface.txt`, sha256
`4e7971e66d5daa8ec8645498d232ad3be7afa77cc090e8bb2d478a0d17016571`.

The invocation passed all 17 subgates. Selected native-link object inspection
and probes remain 45/45. Strict real-row gates remain green at 100 rows in
ReleaseFast, ReleaseSafe, and ReleaseSmall; all three 146-row integrated-object
modes are green; the integrated executable suite advances to 6/6; release
source-owned object inspection, native link, and probes remain 100/100.

```text
summary native-link-object-inspection inventory=selected-native-link inspected=45 elf64_rel=45 unsupported_relocation_rows=0 local_fail=0
summary native-link-probe target=x86_64-unknown-linux-gnu accepted=45 failed=0
summary zig-integrated-object pipeline=postopt total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=true total=146 executable_ok=146 local_fail=0
summary distribution-real-rows mode=ReleaseFast limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary zig-integrated-exe total=6 build_ok=6 run_ok=6 stdout_ok=6 exit_ok=6 local_fail=0
summary native-link-object-inspection inventory=release-source-owned inspected=100 elf64_rel=100 unsupported_relocation_rows=0 local_fail=0
summary distribution-native-link inventory=release-source-owned total=100 executable_abi_proof_rows=100 local_object_codegen_failures=0 local_fail=0
summary native-link-probe inventory=release-source-owned accepted=100 local_object_codegen_failures=0 failed=0
summary distribution-all-timing subgates=17 total_duration_ms=2349765 cache_hit_subgates=3 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Log: `tmp/distribution_all_after_inbox43_f32x4.log`, sha256
`ecdbabc3ba4656b1d5c91024a767ddce3717df4eb03e63e9fe82e845bd1bc407`.
