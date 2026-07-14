# Distribution-All After Half Pointer Stores

schema_version: 1
directive: `INBOX-35 pre-authorized successor`
cycle: `half-pointer-store`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `ac122f64` plus
staged production and permanent-test diff sha256
`926fa413f8940fd15b81f94a0ae58ec17832de4ee6d34f3a6ab4fb04c73462bc`.

Changed subsystem: composed x86_64 scalar FP memory lowering for fp16 stores
through ABI-proven pointer parameters, plus permanent bit-exact execution.

Tier-3 trigger: the directed `compiler_rt.sincos.sincosh` row closure is an
evidence-backed milestone under `docs/validation_tiers.md` and the INBOX-35
row-closure contract.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox35_half_pointer_store.log 2>&1
```

Prior evidence cannot be reused because the newest Tier 3 predates the fp16
pointer-store width, its permanent dual-output payload canary, and the newly
emitting captured `sincosh` body. The Zig pin, target, corpus, and pipeline
arguments are unchanged; the relevant selector source state and expected row
contract are not. The preface and staged implementation identity above were
recorded before the single required invocation.

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
summary distribution-all-timing subgates=17 total_duration_ms=2284111 cache_hit_subgates=3 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Log: `tmp/distribution_all_after_inbox35_half_pointer_store.log`, sha256
`1c3d024e4ceea92b2b77f85931deef78714520867122f04e8cae4a227b25445b`.
