# Distribution-All After Mul64 RAX RHS Repair

schema_version: 1
directive: `INBOX-33`
cycle: `mul64-rax-rhs-repair`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `13257128` plus
staged implementation and acceptance diff sha256
`b39ae406d64591b2073d83648e70257b52da65ea6227483320a78193ce4c4e1e`.

Changed subsystem: the composed x86_64 scalar selector's existing i64
multiply operand-location matrix and its permanent executable regression.

Tier-3 trigger: the directed `compiler_rt.sqrt.sqrtf` row closure is an
evidence-backed milestone under `docs/validation_tiers.md` and the INBOX-33
row-closure contract.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox33_mul64_rax_rhs.log 2>&1
```

Prior evidence cannot be reused because the accepted INBOX-32 successor Tier 3
predates the repaired RAX RHS location, its permanent executable regression,
and the newly closed `sqrtf` body. The Zig pin, target, corpus, and pipeline
arguments are unchanged; the relevant selector source state and expected-result
contract are not.

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
summary distribution-all-timing subgates=17 total_duration_ms=2361144 cache_hit_subgates=3 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Log: `tmp/distribution_all_after_inbox33_mul64_rax_rhs.log`, sha256
`e084fb6eb8c3a21e40599a06678c78940993e71dc9710d143c1983965f22de1a`.
