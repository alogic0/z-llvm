# Distribution-All After Canonical Vector Masks

schema_version: 1
directive: `INBOX-41`
cycle: `canonical-vector-mask`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `ae35052a` plus
production and permanent-test diff sha256
`987479f463f813087e84a0b2292988b854a4bc5b4d0a962863a51445c85bde9e`.
The current-source ReleaseFast z_llvm has sha256
`987022013bb0f8ceb4823d226f21fb3b163d25cbfe5e65b56ce510fb39bf331f`.

Changed subsystem: x86_64 composed-selector vector value shapes, canonical XMM
masks, packed compare/fabs lowering, mask scalar extraction, SSE machine
instructions, assembly/encoding, verifier handling, and vector pair spills.

Tier-3 trigger: INBOX-41 explicitly requires one acceptance run because this
new reusable value shape crosses shared selector, register-allocation,
machine-encoding, and verifier surfaces and closes
`compiler_rt.comparef.__unordsf2`.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox41_mask.log 2>&1
```

Prior evidence cannot be reused because the accepted `ae35052a` run predates
the canonical mask shape and definedness, vector retagging, packed compares and
fabs, movmsk scalar consumers, seven new SSE forms, mask spills, permanent
execution, and the directed row closure. The preface was recorded before the
single invocation in `tmp/inbox41_mask_tier3_preface.txt`, sha256
`500900ec75101e6f7dfc319111cd695d91fff02307155194d2cc5a53adf8b87e`.

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
summary distribution-all-timing subgates=17 total_duration_ms=2322249 cache_hit_subgates=3 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

The previous accepted run took 2,317,643 ms. This run took 2,322,249 ms, an
increase of 4,606 ms (about 0.2%), so runtime has not changed materially with
the added permanent mask tests.

Log: `tmp/distribution_all_after_inbox41_mask.log`, sha256
`182a1ee14a9c241d0cdeb9029279e79c0d6e944207d0073d25150316d7a2a777`.
