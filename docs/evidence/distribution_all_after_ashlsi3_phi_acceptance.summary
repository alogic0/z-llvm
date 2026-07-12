# Tier 3 Gate Evidence

schema_version: 1
log_path: `tmp/distribution_all_after_ashlsi3_phi_acceptance.log`
command: `zig build distribution-all`
z_llvm_base_commit: `cb42edcd`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
trigger: `parallel phi-edge allocator change and four integer-helper closures`

```text
summary zig-integrated-object pipeline=postopt ir_writer=false total=146 executable_ok=146 link_only_ok=0 local_fail=0
summary distribution-real-rows mode=ReleaseFast limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
summary distribution-all-timing subgates=17 total_duration_ms=2318600 cache_hit_subgates=3 cache_miss_subgates=0 cache_mixed_subgates=0 cache_none_subgates=14 slowest_reported=5 fresh_real_rows=false local_fail=0
ok distribution all gates
```
