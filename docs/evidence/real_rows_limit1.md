# Gate Evidence Summary

schema_version: 1
log_path: `tmp/real_rows_limit1.log`
command: `zig build distribution-real-rows -- --limit=1`
z_llvm_commit: `6489fffca6bb82e5f317561f0c72e99572456661`
ziglang_pin: `141bfce0883017ff7ebe03e3af3db07fff0c5dc3`
process_exit_status: `0`
first_failure_line: `none`

## Ratchet Metadata

candidate_file_hash: `eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204`
selector_version: `real-candidate-selector-v1`
mode: `ReleaseFast,ReleaseSafe,ReleaseSmall`
limit: `1`
ratchet_migration_note: `n/a`

## Summary Lines

```text
summary distribution-real-rows mode=ReleaseFast selector_version=real-candidate-selector-v1 candidate_file_hash=eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204 limit=1 candidate_rows=1 real_functions_lowered=1 real_objects_emitted=1 real_native_linked=1 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSafe selector_version=real-candidate-selector-v1 candidate_file_hash=eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204 limit=1 candidate_rows=1 real_functions_lowered=1 real_objects_emitted=1 real_native_linked=1 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSmall selector_version=real-candidate-selector-v1 candidate_file_hash=eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204 limit=1 candidate_rows=1 real_functions_lowered=1 real_objects_emitted=1 real_native_linked=1 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
```
