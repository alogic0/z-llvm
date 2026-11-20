# Tier 3 Gate Evidence

schema_version: 1
log_path: `tmp/distribution_all_after_udivei5_acceptance.log`
command: `zig build distribution-all --summary all`
z_llvm_base_commit: `0fc6498b40ce88b0b747824a99048ea881371ad7`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
trigger: `shared frame/epilogue change and __udivei5 tracker closure`

```text
summary native-link-object-inspection inventory=selected-native-link target=x86_64-unknown-linux-gnu mode=all case=all inspected=45 elf64_rel=45 relocation_rows=18 tls_rows=3 undefined_import_rows=12 comdat_rows=0 eh_frame_rows=0 unsupported_relocation_rows=0 local_fail=0
summary native-link-probe target=x86_64-unknown-linux-gnu mode=all linker=zig build-exe -fno-lld accepted=45 failed=0
summary zig-source-native-link total=10 executable_ok=9 link_only_ok=1 local_fail=0
summary zig-integrated-object pipeline=postopt ir_writer=false total=146 executable_ok=146 link_only_ok=0 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=false total=146 executable_ok=146 link_only_ok=0 local_fail=0
summary distribution-real-rows mode=ReleaseFast selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSafe selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSmall selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
summary native-link-object-inspection inventory=release-source-owned target=x86_64-linux-gnu mode=all case=all inspected=100 elf64_rel=100 relocation_rows=12 tls_rows=8 undefined_import_rows=0 comdat_rows=0 eh_frame_rows=0 unsupported_relocation_rows=0 local_fail=0
summary distribution-native-link inventory=release-source-owned target=x86_64-linux-gnu mode=all case=all total=100 executable_abi_proof_rows=100 link_only_rows=0 runtime_compiler_rt_libc_boundary_rows=0 unsupported_zig_linker_feature_rows=0 local_object_codegen_failures=0 local_fail=0
summary native-link-probe inventory=release-source-owned target=x86_64-linux-gnu mode=all case=all linker=zig build-exe -fno-lld accepted=100 runtime_compiler_rt_libc_boundary_rows=0 unsupported_zig_linker_feature_rows=0 local_object_codegen_failures=0 failed=0
summary distribution-all-timing subgates=17 total_duration_ms=2220592 cache_hit_subgates=3 cache_miss_subgates=0 cache_mixed_subgates=0 cache_none_subgates=14 slowest_reported=5 fresh_real_rows=false local_fail=0
ok distribution all gates
```
