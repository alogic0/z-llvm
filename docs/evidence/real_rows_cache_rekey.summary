# Gate Evidence Summary

schema_version: 1
log_path: `tmp/real_rows_cache_rekey_hit.log`
command: `zig build distribution-real-rows -- --strict --limit=100`
z_llvm_commit: `f513318f082bbf509a3a72816b7da2320e53bf8d`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
process_exit_status: `0`
first_failure_line: `none`

## Ratchet Metadata

candidate_file_hash: `83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d`
selector_version: `real-candidate-selector-v2`
mode: `all-release-modes`
limit: `100`
comparison_log_path: `tmp/real_rows_cache_rekey_fresh.log`
comparison_summary_lines_match: `true`
ratchet_migration_note: `export-cache storage re-keyed to schema 2 on ziglang pin, exporter-relevant z_llvm state, and mode; selector version, candidate-file hash, limit, and slice validation remain read-layer checks`

## Summary Lines

```text
summary distribution-real-rows mode=ReleaseFast selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSafe selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSmall selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=100 candidate_rows=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
```

## Gate Metadata Lines

```text
compare air-export-cache mode=ReleaseFast status=fresh-export duration_ms=512197 cache_key=92de5d7dc23761e92d01694ca13470b6d3c34da543554791dfbe70fd15d6cb61 descriptor_bytes=1373715837
compare air-export-cache mode=ReleaseSafe status=fresh-export duration_ms=531795 cache_key=196f53065eb715990b6e24d04afcb875285675e5adb675a6a30bae4de6873192 descriptor_bytes=1501643299
compare air-export-cache mode=ReleaseSmall status=fresh-export duration_ms=425464 cache_key=283ed9184522c06666973850c5c3a8158e1743a7076d17962281c70fcf34e8d8 descriptor_bytes=1135661698
primary air-export-cache mode=ReleaseFast status=hit duration_ms=15686 cache_key=92de5d7dc23761e92d01694ca13470b6d3c34da543554791dfbe70fd15d6cb61 descriptor_bytes=1373715837
primary air-export-cache mode=ReleaseSafe status=hit duration_ms=17114 cache_key=196f53065eb715990b6e24d04afcb875285675e5adb675a6a30bae4de6873192 descriptor_bytes=1501643299
primary air-export-cache mode=ReleaseSmall status=hit duration_ms=12541 cache_key=283ed9184522c06666973850c5c3a8158e1743a7076d17962281c70fcf34e8d8 descriptor_bytes=1135661698
```

## Cache Directory Check

```text
cleanup_log_path: tmp/clean_tmp_cache_rekey.log
clean-tmp command: zig build clean-tmp -- --keep-newest-per-mode --older-than-seconds=999999999 --delete
clean-tmp result: duplicate_mode_cache_pairs=10 cache_pairs_kept=3 local_fail=0
remaining meta entries:
92de5d7dc23761e92d01694ca13470b6d3c34da543554791dfbe70fd15d6cb61 mode=ReleaseFast
196f53065eb715990b6e24d04afcb875285675e5adb675a6a30bae4de6873192 mode=ReleaseSafe
283ed9184522c06666973850c5c3a8158e1743a7076d17962281c70fcf34e8d8 mode=ReleaseSmall
```
