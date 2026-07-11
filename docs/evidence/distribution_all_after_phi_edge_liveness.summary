# Tier 3 Validation Evidence

schema_version: 1
log_path: `tmp/distribution_all_after_phi_edge_liveness.log`
command: `zig build distribution-all > tmp/distribution_all_after_phi_edge_liveness.log 2>&1`
z_llvm_base_commit: `2ff0af12`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-unknown-linux-gnu`
process_exit_status: `0`
trigger: `shared register-allocation interval construction changed`
result: `pass`

```text
summary distribution-all-timing subgates=17 total_duration_ms=2197898 cache_hit_subgates=3 cache_miss_subgates=0 cache_mixed_subgates=0 cache_none_subgates=14 slowest_reported=5 fresh_real_rows=false local_fail=0
```

All correctness, expected-failure, strict real-row, executable, native-link,
release-source, and boundary summaries completed with `local_fail=0`.
