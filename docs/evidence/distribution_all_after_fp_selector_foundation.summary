# Distribution-All After FP Selector Foundation

schema_version: 1
directive: `INBOX-17`
target: `x86_64-linux-gnu`
result: pass
command: `zig build distribution-all`
log: `tmp/distribution_all_after_fp_selector_foundation.log`

```text
summary distribution-all-timing subgates=17 total_duration_ms=2291524 cache_hit_subgates=3 cache_miss_subgates=0 cache_mixed_subgates=0 cache_none_subgates=14 slowest_reported=5 fresh_real_rows=false local_fail=0
ok distribution all gates
```

The shared SysV ABI, composed GPR/XMM allocator, caller-clobber, and frame-spill
changes are accepted across the full distribution gate. Strict real-row gates
passed for ReleaseFast, ReleaseSafe, and ReleaseSmall at limit 100. Native-link
release-source-owned acceptance remained 100/100 with zero local object
codegen failures; the general native-link probe remained 45/45.
