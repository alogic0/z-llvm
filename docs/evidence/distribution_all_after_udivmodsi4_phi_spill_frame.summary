# Tier 3 Gate Evidence

schema_version: 1
log_path: `tmp/distribution_all_after_udivmodsi4_phi_spill_frame.log`
command: `zig build distribution-all`
z_llvm_base_commit: `2e0303d1`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
trigger: `spill/frame acceptance boundary`

```text
zig build test: status=0 tests=812/812
summary distribution-real-rows mode=ReleaseFast limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
summary native-link-object-inspection inventory=release-source-owned target=x86_64-linux-gnu mode=all case=all inspected=100 elf64_rel=100 relocation_rows=12 tls_rows=8 undefined_import_rows=0 comdat_rows=0 eh_frame_rows=0 unsupported_relocation_rows=0 local_fail=0
summary distribution-all-timing subgates=17 total_duration_ms=2401621 cache_hit_subgates=3 cache_miss_subgates=0 cache_mixed_subgates=0 cache_none_subgates=14 slowest_reported=5 fresh_real_rows=false local_fail=0
ok distribution all gates
```
