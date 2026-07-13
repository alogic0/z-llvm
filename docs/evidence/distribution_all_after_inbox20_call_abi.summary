# Tier 3 Gate Evidence

schema_version: 1
directive: `INBOX-20`
log_path: `tmp/distribution_all_after_inbox20_call_abi.log`
preflight_path: `tmp/distribution_all_after_inbox20_call_abi.preflight`
command: `zig build distribution-all`
z_llvm_base_commit: `4149ea5726883e313d4241db51cb516004b3cfa7`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
trigger: `shared x86_64 SysV scalar SSE call ABI, frame, call-lowering, and verifier boundary`
reuse_rejected: `the prior result predates scalar SSE call planning, FP argument staging, call-frame reservation, advisory marker handling, and XMM0 result verification`

This was the single Tier 3 run authorized for final INBOX-20 acceptance. All
17 subgates passed. Strict real-row object and native-link gates remain green
at 100 rows in ReleaseFast, ReleaseSafe, and ReleaseSmall. Integrated object
coverage remains green at 146 rows for postopt, preopt, and Zig-owned IR-writer
paths. The five executable canaries and all 100 release-source-owned object
inspection, native-link, and native-link probe rows pass.

```text
summary zig-integrated-object pipeline=postopt ir_writer=false total=146 executable_ok=146 link_only_ok=0 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=false total=146 executable_ok=146 link_only_ok=0 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=true total=146 executable_ok=146 link_only_ok=0 generic_codegen_rows=146 case_specific_codegen_rows=0 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=true total=100 executable_ok=100 link_only_ok=0 generic_codegen_rows=100 case_specific_codegen_rows=0 local_fail=0
summary distribution-real-rows mode=ReleaseFast limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
summary native-link-object-inspection inventory=release-source-owned inspected=100 elf64_rel=100 unsupported_relocation_rows=0 local_fail=0
summary distribution-native-link inventory=release-source-owned total=100 executable_abi_proof_rows=100 link_only_rows=0 local_object_codegen_failures=0 local_fail=0
summary native-link-probe inventory=release-source-owned accepted=100 failed=0
summary distribution-all-timing subgates=17 total_duration_ms=2434540 cache_hit_subgates=3 cache_miss_subgates=0 cache_mixed_subgates=0 cache_none_subgates=14 slowest_reported=5 fresh_real_rows=false local_fail=0
ok distribution all gates
```
