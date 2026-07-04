# Gate Evidence Summary

schema_version: 1
log_path: `tmp/real_rows_strict_limit100_after_optional_layout.log`
command: `zig build distribution-real-rows -- --strict --limit=100`
z_llvm_commit: `07f7dc215fc25c488dd7446e1474b262b5ab85b7`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `1`
first_failure_line: `real-row-failure mode=ReleaseSafe rank=32 source=../ziglang/src/main.zig function=Io.Limit.limited stage=typed-lowering diagnostic=unsupported:opcode:intcast_safe`

## Ratchet Metadata

candidate_file_hash: `83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d`
selector_version: `real-candidate-selector-v2`
mode: `all`
limit: `100`
comparison_log_path: `n/a`
comparison_summary_lines_match: `n/a`
ratchet_migration_note: `n/a`

## Summary Lines

```text
summary distribution-real-rows mode=ReleaseFast selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSafe selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=97 real_objects_emitted=97 real_native_linked=97 real_executed=0 real_programs_ok=0 first_failing_real_row=../ziglang/src/main.zig/Io.Limit.limited first_failing_stage=typed-lowering local_fail=1
summary distribution-real-rows mode=ReleaseSmall selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
```

## Gate Metadata Lines

```text
primary air-export-cache mode=ReleaseFast status=miss-export duration_ms=516490 cache_key=a83c83b77a9f12e5a83afe2798e3abddbe4a90ade087f91dcba54616468aabe1 descriptor_bytes=1373715837
primary air-export-cache mode=ReleaseSafe status=miss-export duration_ms=528745 cache_key=c0fb59d171b919c85ff3d9defc27f9a6783929421b495582a53cf453bbfd7d38 descriptor_bytes=1501643299
primary air-export-cache mode=ReleaseSmall status=miss-export duration_ms=418543 cache_key=597036b2a4167ff5e7fcd35c43e213ea99d014d1e115bcd5ee48e0f0e76961a2 descriptor_bytes=1135661698
```
