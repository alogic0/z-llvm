# Distribution-All After Named Signed Comparisons

schema_version: 1
directive: `INBOX-33` evidence-ranked successor
cycle: `signed-named-comparisons`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `894ca55e` plus
staged implementation and acceptance diff sha256
`5c6c70c9053fe7a5b4a5914f9c50b36e43d9356ebdf8deeab37b4d02516880ab`.

Changed subsystem: the composed x86_64 scalar selector's typed i32/i64
comparison admission and its permanent executable regression coverage.

Tier-3 trigger: the `compiler_rt.fmod.fmod` and
`compiler_rt.fmod.fmodf` closures are an evidence-backed row milestone under
`docs/validation_tiers.md` and the standing row-closure contract.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox33_signed_named_comparisons.log 2>&1
```

Prior evidence cannot be reused because the accepted INBOX-33 repair Tier 3
predates the named signed-comparison selector path, its permanent executable
coverage, and both newly closed fmod bodies. The Zig pin, target, corpus, and
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
summary distribution-all-timing subgates=17 total_duration_ms=2371496 cache_hit_subgates=3 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Log: `tmp/distribution_all_after_inbox33_signed_named_comparisons.log`, sha256
`783ee2184ebf78e78e1762c8e7f460a03e3ed36e8e09b8d555bbae04c43aee3f`.
