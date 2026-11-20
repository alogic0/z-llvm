# Distribution-All After Named I1 Or

schema_version: 1
directive: `INBOX-32`
cycle: `named-i1-or`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `fdd5084f` plus
staged implementation and acceptance diff sha256
`b8ec1bb5a7b404404aac61b2d7381ecc845182468ade4dd622d734cf690e76f7`.

Changed subsystem: the composed x86_64 scalar selector's exact named i1
binary-operation admission and its permanent executable predicate coverage.

Tier-3 trigger: the three directed compiler-rt row closures are
evidence-backed milestones under `docs/validation_tiers.md` and INBOX-32
explicitly requires one Tier 3 after executable row proof.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox32_named_i1_or.log 2>&1
```

Prior evidence cannot be reused because the accepted INBOX-31 Tier 3 predates
named i1 OR admission, the new permanent predicate truth-table canary, and the
three newly closed compiler-rt bodies. The Zig pin, target, corpus, and
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
summary distribution-all-timing subgates=17 total_duration_ms=2283132 cache_hit_subgates=3 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Log: `tmp/distribution_all_after_inbox32_named_i1_or.log`, sha256
`bc5ccd97f6ccfcc146ff294f3968bb6f34a3ad239d67b71dc889ec4c2fdeb065`.
