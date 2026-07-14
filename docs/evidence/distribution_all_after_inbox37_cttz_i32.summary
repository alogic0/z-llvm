# Distribution-All After Typed I32 Count-Trailing-Zeros

schema_version: 1
directive: `INBOX-37 Part 1`
cycle: `typed-cttz-i32`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `e6c145f7` plus
staged production and permanent-test diff sha256
`071bcde5e638e9d6bf419b1a220c3fa72a15951575632393ed486de81fc957f6`.
The current-source ReleaseFast z_llvm has sha256
`a65e48282542d44a3fa901346e54f79590018258413b2c8522e8cfd2fba18665`.

Changed subsystem: x86_64 composed-selector LLVM intrinsic lowering for exact
typed `llvm.cttz.i32`, plus permanent selector/encoder/verifier execution.

Tier-3 trigger: the new reusable typed capability closes the directed
`compiler_rt.floatunsisf.__floatunsisf` and
`compiler_rt.floatsisf.__floatsisf` rows under the INBOX-37 row-closure
contract.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox37_cttz_i32.log 2>&1
```

Prior evidence cannot be reused because the newest Tier 3 predates the
`llvm.cttz.i32` selector admission, its permanent executable canary, and the
two newly emitting captured rows. The preface and staged implementation
identity above were recorded before the single required invocation in
`tmp/inbox37_cttz_i32_tier3_preface.txt`, sha256
`41f0be431c94b93d0dfaf5f9f0e512978bf5f1fad0af6b2867807555aa8add9a`.

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
summary distribution-all-timing subgates=17 total_duration_ms=2291582 cache_hit_subgates=3 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Log: `tmp/distribution_all_after_inbox37_cttz_i32.log`, sha256
`2f8d133739578359b9fb6144a1621d563ad765d5a16e3d9d0a829545cd41ed88`.
