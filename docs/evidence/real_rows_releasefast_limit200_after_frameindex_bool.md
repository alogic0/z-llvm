# Gate Evidence Summary

schema_version: 1
log_path: `tmp/real_rows_releasefast_limit200_after_frameindex_bool.log`
command: `zig build distribution-real-rows -- --mode=ReleaseFast --limit=200 2>&1 | tee tmp/real_rows_releasefast_limit200_after_frameindex_bool.log`
z_llvm_commit: `a4eac81429b9846e016097687cd74741f3e83730`
ziglang_pin: `141bfce0883017ff7ebe03e3af3db07fff0c5dc3`
process_exit_status: `0`
first_failure_line: `real-row-failure mode=ReleaseFast rank=32 source=../ziglang/src/main.zig function=Io.Limit.limited stage=typed-lowering diagnostic=unsupported:function_type:function-type`

## Ratchet Metadata

candidate_file_hash: `83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d`
selector_version: `real-candidate-selector-v2`
mode: `ReleaseFast`
limit: `200`
comparison_log_path: `n/a`
comparison_summary_lines_match: `n/a`
ratchet_migration_note: `n/a`

## Summary Lines

```text
summary distribution-real-rows mode=ReleaseFast selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=200 candidate_rows=200 real_functions_lowered=179 real_objects_emitted=176 real_native_linked=176 real_executed=0 real_programs_ok=0 first_failing_real_row=../ziglang/src/main.zig/Io.Limit.limited first_failing_stage=typed-lowering local_fail=1
```

## Gate Metadata Lines

```text
primary air-export-cache mode=ReleaseFast status=hit duration_ms=15986 cache_key=3d5609ef9bdf372eb08864cfb3a86bfafcd386053ee454192de8f814d5bf10c4 descriptor_bytes=1373517551
```
