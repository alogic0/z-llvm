# Distribution-All After Scalar FP Select And Phi

schema_version: 1
directive: `INBOX-26`
cycle: `scalar-fp-select-phi`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `54119042` plus
staged source diff sha256
`5b6ddaf3765f40a1a3c66f38127bf566743d957cee131a73ccc08acde0789936`.

Changed subsystem: the composed selector's scalar FP select lowering and FP
phi-edge parallel-copy path. The latter snapshots float/double edge sources
before destination writes and remains fail-closed when no non-conflicting XMM
snapshot register is available.

Tier-3 trigger: `INBOX-26` requires one full integration run when a directed
trig row closes. The fresh captured compiler-rt report closes
`compiler_rt.tan.tanf`, so the row-closure rule applies.

Exact command and intended log:

```text
zig build distribution-all >tmp/distribution_all_after_scalar_fp_select_phi.log 2>&1
```

The accepted `distribution_all_after_f32x2` result cannot be reused because it
predates scalar FP select lowering, FP constants on phi edges, and source-safe
float/double phi parallel copies. Those selector changes are what make the
captured `tanf` row emit.

The command completed successfully against that staged source identity. Log:
`tmp/distribution_all_after_scalar_fp_select_phi.log`, sha256
`368f6b751cb77e3b78bb7c8c4bd0b7c0d3d85c15c0950eeb738e104d867ba204`.

Acceptance summaries:

```text
summary distribution-real-rows mode=ReleaseFast selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSafe selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSmall selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
summary native-link-object-inspection inventory=release-source-owned target=x86_64-linux-gnu mode=all case=all inspected=100 elf64_rel=100 relocation_rows=12 tls_rows=8 undefined_import_rows=0 comdat_rows=0 eh_frame_rows=0 unsupported_relocation_rows=0 local_fail=0
summary distribution-native-link inventory=release-source-owned target=x86_64-linux-gnu mode=all case=all total=100 executable_abi_proof_rows=100 link_only_rows=0 runtime_compiler_rt_libc_boundary_rows=0 unsupported_zig_linker_feature_rows=0 local_object_codegen_failures=0 local_fail=0
summary distribution-all-timing subgates=17 total_duration_ms=2277831 cache_hit_subgates=3 cache_miss_subgates=0 cache_mixed_subgates=0 cache_none_subgates=14 slowest_reported=5 fresh_real_rows=false local_fail=0
ok distribution all gates
```
