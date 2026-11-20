# Distribution-All After LLVM Intrinsic Boundary Repair

schema_version: 1
directive: `INBOX-34 prerequisite correctness repair`
cycle: `llvm-intrinsic-call-boundary-repair`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `71ffd846` plus
staged implementation and focused-test diff sha256
`c30d63ae55af2ef86f97eaee7a043086c5a694b4f1fb44628a07769d2ed7994c`.

Changed subsystem: the composed x86_64 call selector's LLVM-intrinsic
boundary, the typed scalar `llvm.fabs.f64` lowering, and permanent executable
selector regressions.

Tier-3 trigger: this correctness repair changes shared call classification and
corrects the evidence baseline by invalidating three rows that had been
reported as emitted despite retaining unresolved LLVM intrinsic calls.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox34_llvm_intrinsic_boundary_repair.log 2>&1
```

Prior evidence cannot be reused because the accepted INBOX-33 successor Tier 3
predates both the fail-closed LLVM-intrinsic boundary and the local f64 `fabs`
lowering. The Zig pin, target, corpus, and pipeline arguments are unchanged;
the relevant call-selector state and emitted-row contract are not.

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
summary distribution-all-timing subgates=17 total_duration_ms=2366735 cache_hit_subgates=3 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Log:
`tmp/distribution_all_after_inbox34_llvm_intrinsic_boundary_repair.log`,
sha256 `ab13fea72bab0041ce9cd5d8477d6e1c5965b92d5a049bbec43ee5ce40df3bf7`.
