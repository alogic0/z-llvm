# Gate Evidence Summary

schema_version: 1
log_path: `tmp/real_rows_releasefast_limit200_after_opaque_bitcast.log`
command: `zig build distribution-real-rows -- --mode=ReleaseFast --limit=200 2>&1 | tee tmp/real_rows_releasefast_limit200_after_opaque_bitcast.log`
z_llvm_commit: `2dc41ded1613b794b8e6df9304a8f22f361826ed`
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
summary distribution-real-rows mode=ReleaseFast selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=200 candidate_rows=200 real_functions_lowered=179 real_objects_emitted=49 real_native_linked=49 real_executed=0 real_programs_ok=0 first_failing_real_row=../ziglang/src/main.zig/Io.Limit.limited first_failing_stage=typed-lowering local_fail=1
```

## Gate Metadata Lines

```text
primary air-export-cache mode=ReleaseFast status=hit duration_ms=14295 cache_key=986928b487c1c12307874cfddbc38ad596ff179a7f73b5734557cfdf70bb4fa3 descriptor_bytes=1373517551
```

## Failure Clusters

Cluster key is `first_failing_stage + diagnostic`, derived from
`real-row-failure ...` lines in the saved log.

| Cluster | Size | Representative rows | Suspected shared cause |
| --- | ---: | --- | --- |
| `object-emission UnsupportedCodegenInstruction` | 130 | rank 36 `ascii.isAscii`; ranks 39-43 `bit_set.*.maskIndex`; ranks 66-182 `hash_map.*.Metadata.*` | The opaque-bitcast typed lowering fix moved many rows into x86_64 object emission; backend instruction selection now lacks a shared scalar predicate/bit-test form. |
| `typed-lowering unsupported:function_type:function-type` | 20 | rank 32 `Io.Limit.limited`; rank 33 `Io.Limit.nonzero`; rank 51 `http.Reader.RemainingChunkLen.init` | Remaining function-type rows do not expose a scalar ABI type through the typed bitcast facts covered by this cycle. |
| `typed-lowering unsupported:instruction_type:lowering` | 1 | rank 188 `Air.Liveness.fmtInstSet` | One row still falls through typed lowering to the generic unsupported-instruction path. |
