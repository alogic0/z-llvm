# Tier 3 Gate Evidence

schema_version: 1
log_path: `tmp/distribution_all_after_i128_shift_acceptance.log`
command: `zig build distribution-all`
z_llvm_base_commit: `8d896719`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
trigger: `shared phi-edge source stabilization and three integer-helper closures`

```text
summary zig-integrated-object pipeline=postopt ir_writer=false total=146 executable_ok=146 link_only_ok=0 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=false total=146 executable_ok=146 link_only_ok=0 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=true total=146 executable_ok=146 link_only_ok=0 local_fail=0
summary distribution-real-rows mode=ReleaseFast limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 local_fail=0
summary distribution-all-timing subgates=17 total_duration_ms=2283919 cache_hit_subgates=3 cache_miss_subgates=0 cache_mixed_subgates=0 cache_none_subgates=14 slowest_reported=5 fresh_real_rows=false local_fail=0
```

All 17 subgates passed. The three strict real-row prefixes were cache hits;
captured-object, source-owned, native-link, and executable gates ran against
the current selector inputs.
