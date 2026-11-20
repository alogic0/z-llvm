# Distribution-All After Typed Integer Switch Lowering

schema_version: 1
directive: `INBOX-27 Part 2`
cycle: `typed-integer-switch-compare-chain`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline
`3716cbebda4459044cdd65e1ef91fe65ecbafe8f` plus staged source diff sha256
`48c8c7b777891f60cf3dff160617a3f9579f5423727df409fb09ec3e170753fd`.

Changed subsystem: the composed selector's typed integer switch terminator.
The bounded compare-chain lowering handles i1 through i32, normalizes narrow
conditions and constants, and recognizes only the explicit `and 3` exhaustive
range proof before omitting an unreachable default edge.

Tier-3 trigger: the fresh captured compiler-rt report closes
`compiler_rt.sin.sinf`, `compiler_rt.cos.cosf`, and
`compiler_rt.sincos.sincosf`, so the standing row-closure rule requires one
full integration run. The preface was recorded before execution at
`tmp/inbox27_switch_tier3_preface.txt` (sha256
`5735638948a68213eff0188d8ab93c23afd19296a8297d9b86280e966fa57aea`).

Exact command and log:

```text
zig build distribution-all >tmp/distribution_all_after_inbox27_typed_switch.log 2>&1
```

The accepted INBOX-27 Part 1 result cannot be reused because it predates
compare-chain switch lowering, typed narrow-condition normalization, and the
masked-range proof that closes the three captured trig rows.

The command completed successfully against that staged source identity. Log:
`tmp/distribution_all_after_inbox27_typed_switch.log`, sha256
`84060b0fde34b032bebf3dcc8009a31b152da5c281841a7d530f875b3ee9c435`.

Acceptance summaries:

```text
summary distribution-real-rows mode=ReleaseFast selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSafe selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSmall selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
summary native-link-object-inspection inventory=release-source-owned target=x86_64-linux-gnu mode=all case=all inspected=100 elf64_rel=100 relocation_rows=12 tls_rows=8 undefined_import_rows=0 comdat_rows=0 eh_frame_rows=0 unsupported_relocation_rows=0 local_fail=0
summary distribution-native-link inventory=release-source-owned target=x86_64-linux-gnu mode=all case=all total=100 executable_abi_proof_rows=100 link_only_rows=0 runtime_compiler_rt_libc_boundary_rows=0 unsupported_zig_linker_feature_rows=0 local_object_codegen_failures=0 local_fail=0
summary distribution-all-timing subgates=17 total_duration_ms=2269998 cache_hit_subgates=3 cache_miss_subgates=0 cache_mixed_subgates=0 cache_none_subgates=14 slowest_reported=5 fresh_real_rows=false local_fail=0
ok distribution all gates
```
