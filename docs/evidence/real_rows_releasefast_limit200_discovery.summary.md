# Gate Evidence Summary

schema_version: 1
log_path: `tmp/real_rows_releasefast_limit200_discovery.log`
command: `zig build distribution-real-rows -- --mode=ReleaseFast --limit=200 2>&1 | tee tmp/real_rows_releasefast_limit200_discovery.log`
z_llvm_commit: `50738511aebc9dc9136ad1800bf4a23106a7a6a3`
ziglang_pin: `141bfce0883017ff7ebe03e3af3db07fff0c5dc3`
process_exit_status: `0`
first_failure_line: `real-row-failure mode=ReleaseFast rank=28 source=../ziglang/src/main.zig function=InternPool.PackedU64.get stage=typed-lowering diagnostic=unsupported:function_type:function-type`

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
summary distribution-real-rows mode=ReleaseFast selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=200 candidate_rows=200 real_functions_lowered=42 real_objects_emitted=33 real_native_linked=33 real_executed=0 real_programs_ok=0 first_failing_real_row=../ziglang/src/main.zig/InternPool.PackedU64.get first_failing_stage=typed-lowering local_fail=1
```

## Gate Metadata Lines

```text
primary air-export-cache mode=ReleaseFast status=miss-export duration_ms=491227 cache_key=986928b487c1c12307874cfddbc38ad596ff179a7f73b5734557cfdf70bb4fa3 descriptor_bytes=1373517551
```

## Failure Clusters

Cluster key is `first_failing_stage + diagnostic`, derived from
`real-row-failure ...` lines in the saved log.

| Cluster | Size | Representative rows | Suspected shared cause |
| --- | ---: | --- | --- |
| `typed-lowering unsupported:function_type:function-type` | 157 | rank 28 `InternPool.PackedU64.get`; rank 29 `InternPool.PackedU64.init`; rank 32 `Io.Limit.limited` | Typed AIR function-type acceptance is still too narrow for the next wide set of real leaf rows, especially packed/index wrapper and hash-map metadata helpers. |
| `object-emission UnsupportedCodegenInstruction` | 9 | rank 36 `ascii.isAscii`; ranks 39-43 `bit_set.*.maskIndex`; rank 184 `os.linux.W.IFEXITED` | Typed lowering accepts these rows, but generic x86_64 object emission lacks one or more instruction/value forms used by simple bit-test and predicate helpers. |
| `typed-lowering unsupported:instruction_type:lowering` | 1 | rank 188 `Air.Liveness.fmtInstSet` | One row falls through typed lowering to the generic unsupported-instruction path rather than the function-type filter. |
