# Distribution-All After F32x2 Packed Shape

schema_version: 1
directive: `INBOX-25` pre-authorized successor
cycle: `f32x2`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `c7e01c3a` plus
staged source diff sha256
`b2798e4fe47a805c158bc27ecb5542ac0f6c0e2e517609a085cd53b6428cd60b`.

Changed subsystem: the composed selector's packed XMM value shape and shared
allocation class, vector spill/reload selection, machine instruction union,
encoder/assembly printer, and machine verifier.

Tier-3 trigger: `docs/validation_tiers.md` requires full integration after a
shared register-allocation change and periodically after a series of selector
capability commits. This cycle generalizes the accepted f64x2-only allocation
tag to the shared packed-XMM class and admits f32x2 through that authority.

Exact command and intended log:

```text
zig build distribution-all >tmp/distribution_all_after_f32x2.log 2>&1
```

The accepted `830dc0af` distribution-all result cannot be reused because it
predates the f32x2 value shape, packed-XMM allocation-class generalization,
packed-single instructions, and `movups` vector spill path now under test.

The command completed successfully against that staged source identity. Log:
`tmp/distribution_all_after_f32x2.log`, sha256
`e8f7adc0366b12dfb1ed5eb7d672b494ad11370778e6e1043e7c32b6789a40be`.

Acceptance summaries:

```text
summary distribution-real-rows mode=ReleaseFast selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSafe selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSmall selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
summary native-link-object-inspection inventory=release-source-owned target=x86_64-linux-gnu mode=all case=all inspected=100 elf64_rel=100 relocation_rows=12 tls_rows=8 undefined_import_rows=0 comdat_rows=0 eh_frame_rows=0 unsupported_relocation_rows=0 local_fail=0
summary distribution-native-link inventory=release-source-owned target=x86_64-linux-gnu mode=all case=all total=100 executable_abi_proof_rows=100 link_only_rows=0 runtime_compiler_rt_libc_boundary_rows=0 unsupported_zig_linker_feature_rows=0 local_object_codegen_failures=0 local_fail=0
summary distribution-all-timing subgates=17 total_duration_ms=2285013 cache_hit_subgates=3 cache_miss_subgates=0 cache_mixed_subgates=0 cache_none_subgates=14 slowest_reported=5 fresh_real_rows=false local_fail=0
ok distribution all gates
```
