# Distribution-All After Named Integer Inequality

schema_version: 1
directive: `INBOX-34`
cycle: `named-integer-inequality`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `cfbb0388` plus
staged implementation and permanent-test diff sha256
`15baee44dca56538b55515b94779c6fae60d8d9c75a760943f2433d8e930b2a0`.

Changed subsystem: the composed x86_64 scalar selector's typed integer
comparison matrix and its permanent executable branch/select regression.

Tier-3 trigger: four directed compiler_rt row closures are an evidence-backed
milestone under `docs/validation_tiers.md` and the INBOX-34 row-closure
contract.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox34_named_integer_inequality.log 2>&1
```

Prior evidence cannot be reused because the prerequisite correctness-repair
Tier 3 predates plain named i32/i64 inequality, its permanent executable
coverage, and the four newly closed comparison-wrapper bodies. The Zig pin,
target, corpus, and pipeline arguments are unchanged; the relevant selector
source state and expected-result contract are not.

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
summary distribution-all-timing subgates=17 total_duration_ms=2366875 cache_hit_subgates=3 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Log: `tmp/distribution_all_after_inbox34_named_integer_inequality.log`,
sha256 `310caee4b219d1e205d0a9dda7b94060258fdb691a53a8d7676025f9e14d5ec3`.
