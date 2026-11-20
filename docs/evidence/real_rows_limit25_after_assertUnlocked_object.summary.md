# Gate Evidence Summary

schema_version: 1
log_path: `tmp/real_rows_limit25_after_assertUnlocked_object.log`
command: `ZLLVM_DEBUG_DUMP_IR_SOURCE=assertUnlocked zig build distribution-real-rows -- --mode=ReleaseSafe --limit=25 2>&1 | tee tmp/real_rows_limit25_after_assertUnlocked_object.log`
z_llvm_commit: `c826db4be422c0a1c6927ac81608d031ddbf94ae`
ziglang_pin: `141bfce0883017ff7ebe03e3af3db07fff0c5dc3`
process_exit_status: `0`
first_failure_line: `summary distribution-real-rows mode=ReleaseSafe selector_version=real-candidate-selector-v1 candidate_file_hash=eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204 limit=25 candidate_rows=25 real_functions_lowered=25 real_objects_emitted=25 real_native_linked=24 real_executed=0 real_programs_ok=0 first_failing_real_row=../ziglang/src/main.zig/debug.SafetyLock.assertUnlocked first_failing_stage=native-link local_fail=1`

## Ratchet Metadata

candidate_file_hash: `eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204`
selector_version: `real-candidate-selector-v1`
mode: `ReleaseSafe`
limit: `25`
comparison_log_path: `n/a`
comparison_summary_lines_match: `n/a`
ratchet_migration_note: `n/a`

## Summary Lines

```text
summary distribution-real-rows mode=ReleaseSafe selector_version=real-candidate-selector-v1 candidate_file_hash=eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204 limit=25 candidate_rows=25 real_functions_lowered=25 real_objects_emitted=25 real_native_linked=24 real_executed=0 real_programs_ok=0 first_failing_real_row=../ziglang/src/main.zig/debug.SafetyLock.assertUnlocked first_failing_stage=native-link local_fail=1
```

## Gate Metadata Lines

```text
primary air-export-cache mode=ReleaseSafe status=hit duration_ms=15319 cache_key=28b649e25b667a3d0d63f5f41344d07516d50fe484d577fc0faf4398786e3015 descriptor_bytes=1501444020
```
