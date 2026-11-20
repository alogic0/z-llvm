# Gate Evidence Summary

schema_version: 1
log_path: `tmp/real_rows_limit25_releasesmall_fresh_recheck.log`
command: `zig build distribution-real-rows -- --mode=ReleaseSmall --limit=25 --fresh-export 2>&1 | tee tmp/real_rows_limit25_releasesmall_fresh_recheck.log`
z_llvm_commit: `a203945b8e417cc525e81cc126cb561bf71d9ce8`
ziglang_pin: `141bfce0883017ff7ebe03e3af3db07fff0c5dc3`
process_exit_status: `0`
first_failure_line: `summary distribution-real-rows mode=ReleaseSmall selector_version=real-candidate-selector-v1 candidate_file_hash=eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204 limit=25 candidate_rows=25 real_functions_lowered=0 real_objects_emitted=0 real_native_linked=0 real_executed=0 real_programs_ok=0 first_failing_real_row=../ziglang/src/main.zig/math.raiseInvalid first_failing_stage=air-export local_fail=1`

## Ratchet Metadata

candidate_file_hash: `eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204`
selector_version: `real-candidate-selector-v1`
mode: `ReleaseSmall`
limit: `25`
comparison_log_path: `n/a`
comparison_summary_lines_match: `n/a`
ratchet_migration_note: `n/a`

## Summary Lines

```text
summary distribution-real-rows mode=ReleaseSmall selector_version=real-candidate-selector-v1 candidate_file_hash=eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204 limit=25 candidate_rows=25 real_functions_lowered=0 real_objects_emitted=0 real_native_linked=0 real_executed=0 real_programs_ok=0 first_failing_real_row=../ziglang/src/main.zig/math.raiseInvalid first_failing_stage=air-export local_fail=1
```

## Gate Metadata Lines

```text
primary air-export-cache mode=ReleaseSmall status=export-invalid duration_ms=424474 cache_key=275c6125ee401cc3ff25bf60bbe7c861d5acb0c43cfdbd592d0eea84bd5c0fc6 descriptor_bytes=1135470341
```
