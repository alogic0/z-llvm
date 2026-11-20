# Tier 3 Gate Evidence

schema_version: 1
log_path: `tmp/distribution_all_after_inbox15_selector_split.log`
preflight_path: `tmp/distribution_all_after_inbox15_selector_split.preflight`
command: `zig build distribution-all`
z_llvm_base_commit: `e3dc600491ad1c0ee06aa851bf72bc91b2b04ed8`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
trigger: `INBOX-15 completed selector, allocator, frame, call, memory, and CFG ownership split`
reuse_rejected: `the previous untracked run predated e3dc6004 selector-memory lowering and could not prove the finished current-HEAD structure`

`composed_selector_impl.zig` is now a 297-line dispatch facade. The extracted
modules preserve one authoritative value-location map in selector state and one
frame authority while separating scalar, memory, call, and CFG lowering.

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
summary distribution-all-timing subgates=17 total_duration_ms=2325065 cache_hit_subgates=3 cache_miss_subgates=0 cache_mixed_subgates=0 cache_none_subgates=14 slowest_reported=5 fresh_real_rows=false local_fail=0
ok distribution all gates
```
