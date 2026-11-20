# Gate Evidence Summary

schema_version: 1
log_path: `tmp/real_rows_export_cache_cached.log`
command: `zig build distribution-real-rows -- --strict --limit=10`
z_llvm_commit: `7266f3fece550cdbe02bebf3920aa82ba73c0b42`
ziglang_pin: `141bfce0883017ff7ebe03e3af3db07fff0c5dc3`
process_exit_status: `0`
first_failure_line: `none`

## Ratchet Metadata

candidate_file_hash: `eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204`
selector_version: `real-candidate-selector-v1`
mode: `ReleaseFast,ReleaseSafe,ReleaseSmall`
limit: `10`
comparison_log_path: `tmp/real_rows_export_cache_fresh.log`
comparison_summary_lines_match: `true`
ratchet_migration_note: `n/a`

## Summary Lines

```text
summary distribution-real-rows mode=ReleaseFast selector_version=real-candidate-selector-v1 candidate_file_hash=eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204 limit=10 candidate_rows=10 real_functions_lowered=10 real_objects_emitted=10 real_native_linked=10 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSafe selector_version=real-candidate-selector-v1 candidate_file_hash=eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204 limit=10 candidate_rows=10 real_functions_lowered=10 real_objects_emitted=10 real_native_linked=10 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
summary distribution-real-rows mode=ReleaseSmall selector_version=real-candidate-selector-v1 candidate_file_hash=eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204 limit=10 candidate_rows=10 real_functions_lowered=10 real_objects_emitted=10 real_native_linked=10 real_executed=0 real_programs_ok=0 first_failing_real_row=- first_failing_stage=- local_fail=0
```

## Gate Metadata Lines

```text
compare air-export-cache mode=ReleaseFast status=fresh-export duration_ms=533085 cache_key=6e42a7e6d9319b4d914be73b2a4a1ec119e92ffd11e699168a18b927563d8d76 descriptor_bytes=1373517551
compare air-export-cache mode=ReleaseSafe status=fresh-export duration_ms=554181 cache_key=f25a200ef7f2f2251c59a62882cc5dd90a9fcbbc8e2881638645f648bd1dd7db descriptor_bytes=1501444020
compare air-export-cache mode=ReleaseSmall status=fresh-export duration_ms=437433 cache_key=5380d30de2aad10de2090cc28f5a192dfaf5647a2ae64002a57148353904dd8f descriptor_bytes=1135470341
primary air-export-cache mode=ReleaseFast status=hit duration_ms=15548 cache_key=6e42a7e6d9319b4d914be73b2a4a1ec119e92ffd11e699168a18b927563d8d76 descriptor_bytes=1373517551
primary air-export-cache mode=ReleaseSafe status=hit duration_ms=16972 cache_key=f25a200ef7f2f2251c59a62882cc5dd90a9fcbbc8e2881638645f648bd1dd7db descriptor_bytes=1501444020
primary air-export-cache mode=ReleaseSmall status=hit duration_ms=12236 cache_key=5380d30de2aad10de2090cc28f5a192dfaf5647a2ae64002a57148353904dd8f descriptor_bytes=1135470341
```
