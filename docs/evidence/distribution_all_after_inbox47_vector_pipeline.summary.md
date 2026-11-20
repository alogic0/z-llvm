# Distribution-All After INBOX-47 Vector Pipeline

schema_version: 1
directive: `INBOX-47 cumulative pipeline acceptance`
target: `x86_64-linux-gnu`
validation_tier: 3
status: pass

Implementation identity before the run: committed baseline
`39cc18d5fc683bf52eff0f04e2b9e4c9393e1a0e`, with clean committed tree
`6817bd3a46c4950e73945af7090c930f27bf768c`.

Changed subsystem: x86_64 composed-selector packed vector shapes and scalar FP
intrinsics. Part 1 adds canonical f32x2 select, packed copysign, and the exact
packed unsigned `ult` comparison required by `__divsc3`. Part 2 extends the
same shape-driven helpers to f64x2 select, fabs, and copysign, adds scalar
copysign.f64, and admits exact `[1,0]` / `[1,1]` f64x2 shuffles through the
generalized `shufpd` machine, assembly, encoder, and verifier surfaces.

Tier-3 trigger: INBOX-47 and the `validation_tiers.md` row-closure batching
amendment require one cumulative Tier 3 at this two-step pipeline boundary. It
accepts the Tier-2/native-proven `__divsc3` closure and validates the shared
vector and machine surfaces before the separately reviewed f64x2 PHI cycle.

Exact command and evidence log:

```text
zig build distribution-all --summary all > tmp/distribution_all_after_inbox47_vector_pipeline.log 2>&1
```

Prior evidence could not be reused because the INBOX-46 Tier 3 predates both
INBOX-47 commits, the `__divsc3` emission, canonical packed select/copysign,
f64x2 parity forms, generalized `shufpd`, and their permanent executable
tests. The preface was recorded before the single invocation in
`tmp/inbox47_pipeline_tier3_preface.txt`, sha256
`727e4187d349de4eba11bd1f2151eb0eab7859d0761e73a5d0fe92b935b1d471`.

The invocation passed all 17 subgates. Selected native-link inspection and
probes remain 45/45. Integrated objects remain 146/146 for postopt, preopt,
and IR-writer pipelines. Release-source-owned integrated objects remain
100/100. Strict real rows remain 100/100/100 in ReleaseFast, ReleaseSafe, and
ReleaseSmall. Integrated executables remain 6/6. Release-source object
inspection, native linking, and native probes remain 100/100 each. Boundary
gates are green.

This cumulative result accepts the sole provisional pipeline closure,
`compiler_rt.divsc3.__divsc3`, from Part 1. Part 2 correctly claimed zero
closures. The accepted compiler_rt report state is 443 selected / 261
emitting / 182 failing; `compiler_rt.divdc3.__divdc3` remains at its earlier
`unsupported_value` / `stage2-phi-dst` boundary. Part evidence is
`docs/evidence/std_debug_hello_inbox47_f32x2_select_copysign.summary.md` and
`docs/evidence/std_debug_hello_inbox47_f64x2_parity.summary.md`.

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
summary distribution-all-timing subgates=17 total_duration_ms=2274150 cache_hit_subgates=3 cache_none_subgates=14 fresh_real_rows=false local_fail=0
ok distribution all gates
```

The reported total is 5,792 ms (0.26%) above the INBOX-46 Tier-3 total of
2,268,358 ms. This is not a material runtime change. The slowest uncached
subgate remains integrated preopt at 547,426 ms; all three strict real-row
subgates reported cache hits.

Log: `tmp/distribution_all_after_inbox47_vector_pipeline.log`, sha256
`3423b437fdc152a85656f2425e311027c8f03c6913a24188a37b1dc442df644d`.
