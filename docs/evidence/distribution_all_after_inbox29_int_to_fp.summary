# Distribution-All After Scalar Integer-To-FP Lowering

schema_version: 1
directive: `INBOX-29`
cycle: `scalar-integer-to-fp`
target: `x86_64-linux-gnu`
status: pass-after-narrow-infrastructure-retry

Implementation identity before the run: committed baseline
`bdb36f25` plus staged source diff sha256
`15b57e50bd303addcc26747d08c0505cc85fc28b8ed96501acada4c6ffbc8edf`.

Changed subsystem: the composed selector's typed scalar `sitofp`/`uitofp`
lowering and its use of the existing frame authority's emergency spill
reservation for fixed RDI/XMM0 conversions.

Tier-3 trigger: `docs/validation_tiers.md` requires full integration after a
change to shared frame behavior. No compiler-rt row closes in the fresh
report, but recognizing integer-to-FP casts as spill-reservation users changes
when the shared selector frame is allocated.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox29_int_to_fp.log 2>&1
```

The accepted INBOX-28 evidence cannot be reused because it predates both the
new fixed-register conversion lowering and the frame reservation trigger that
allows live values to survive those clobbers.

The full invocation completed subgates 1 through 14, including strict
100-row ReleaseFast, ReleaseSafe, and ReleaseSmall gates and the permanent
integrated executable suite. Its release-source native-link subgate then
stalled in the prerequisite plain `zig build`: historical runs complete the
entire subgate in 87--98 seconds, but this child consumed one CPU for more
than 68 minutes and made no I/O progress for over 20 minutes. The hung child
was terminated, so the orchestrator correctly exited nonzero and did not
print a false final-success line.

The narrowest prerequisite retry, plain `zig build`, then completed
immediately. Per the failed-run rule in `docs/validation_tiers.md`, only the
failed native-link subgate and the two downstream subgates that had not run
were executed. All passed without source changes:

```text
summary distribution-real-rows mode=ReleaseFast selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSafe selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSmall selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
summary native-link-object-inspection inventory=release-source-owned target=x86_64-linux-gnu mode=all case=all inspected=100 elf64_rel=100 relocation_rows=12 tls_rows=8 undefined_import_rows=0 comdat_rows=0 eh_frame_rows=0 unsupported_relocation_rows=0 local_fail=0
summary distribution-native-link inventory=release-source-owned target=x86_64-linux-gnu mode=all case=all total=100 executable_abi_proof_rows=100 link_only_rows=0 runtime_compiler_rt_libc_boundary_rows=0 unsupported_zig_linker_feature_rows=0 local_object_codegen_failures=0 local_fail=0
summary native-link-probe inventory=release-source-owned target=x86_64-linux-gnu mode=all case=all linker=zig build-exe -fno-lld accepted=100 runtime_compiler_rt_libc_boundary_rows=0 unsupported_zig_linker_feature_rows=0 local_object_codegen_failures=0 failed=0
ok distribution boundary gates
```

Evidence logs:

- `tmp/distribution_all_after_inbox29_int_to_fp.log`, sha256
  `6435b8b0c9bf17d374191c2c8838e0394b165753f88c0d3dd17c984eb11a5b85`;
- `tmp/inbox29_native_link_retry.log`, sha256
  `1917580474813bcef333e513db430c769943fb023bc2a5bf3de4ad2e6e3d9364`;
- `tmp/inbox29_native_link_probe_retry.log`, sha256
  `f7df53a74a130f894eca022a24d8f333440cbd3a7bf5fb2ffc642b2bc03296fe`;
- `tmp/inbox29_distribution_boundary_retry.log`, sha256
  `3a8a8850e031eb16edb5d71e78c60ca977329d09790149e2cc1af269f90cbe25`.

Together these logs cover all 17 unchanged-input Tier 3 subgates. No second
full invocation was made solely to reproduce the orchestrator footer.
