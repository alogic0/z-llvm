# Parallel Strict Real-Row Tier 3 Evidence

schema_version: 1
date: 2026-07-11
source_base_commit: `5901a3b0`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
target: `x86_64-unknown-linux-gnu`
command: `/usr/bin/time -f 'wall_seconds=%e' -o tmp/distribution_all_parallel_real_rows.time zig build distribution-all`
log: `tmp/distribution_all_parallel_real_rows.log`
process_exit_status: `0`
inbox: `INBOX-13`

## Selection Basis

The previous accepted cached run spent 1,053.421 seconds across the three
strict real-row modes, 45.7% of its 2,304.061-second wall time. Each mode uses
a distinct AIR-export cache key and PID-scoped work directory. The predicted
wall saving was approximately the sum minus the slowest mode, 668.220 seconds
or 29.0%.

Inspection found no safe artifact-reuse boundary between integrated post-opt,
pre-opt, and IR-writer gates: their pipeline and ownership contracts differ.
The three real-row descriptors are also mode-specific, so sharing descriptor
artifacts would be incorrect. Scheduling those independent mode consumers
concurrently was the bounded optimization with a source-backed >10% estimate.

## Result

```text
previous cached wall: 2304.061 s
current cached wall:  1751.710 s
incremental saving:    552.351 s (23.97%)
Phase 0 cached wall:   2289.680 s
cumulative saving:     537.970 s (23.50%)
current summed child:  2447.599 s
canonical records:     53
semantic match:        true
```

Contention increased individual strict-mode durations to 369.130,
461.037, and 327.133 seconds, but their overlapped wall interval remained
materially below the former sequential sum. Deterministic output is buffered
and replayed in the original gate order.

Canonical comparison:

```text
zig run tools/compare_distribution_all_logs.zig -- tmp/distribution_all_after_divei4_mixed_frame.log tmp/distribution_all_parallel_real_rows.log
summary distribution-all-equivalence schema_version=1 expected=tmp/distribution_all_after_divei4_mixed_frame.log actual=tmp/distribution_all_parallel_real_rows.log canonical_records=53 semantic_match=true local_fail=0
```

Tier 3 retained strict `100/100/100` lowered, emitted, and native-linked rows
in ReleaseFast, ReleaseSafe, and ReleaseSmall; all other summaries ended with
`local_fail=0`, and the run ended with `ok distribution all gates`.
