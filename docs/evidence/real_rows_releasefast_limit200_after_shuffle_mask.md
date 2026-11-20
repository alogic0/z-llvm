# Gate Evidence Summary

schema_version: 1
log_path: `tmp/real_rows_releasefast_limit200_after_shuffle_mask.log`
command: `zig build distribution-real-rows -- --mode=ReleaseFast --limit=200 2>&1 | tee tmp/real_rows_releasefast_limit200_after_shuffle_mask.log`
z_llvm_commit: `a8d2849770c7958a78f7794d4f47d1aeac89bcc4`
ziglang_pin: `141bfce0883017ff7ebe03e3af3db07fff0c5dc3`
process_exit_status: `0`
first_failure_line: `real-row-failure mode=ReleaseFast rank=186 source=../ziglang/src/main.zig function=unicode.utf16IsHighSurrogate stage=object-emission diagnostic=x86_64-lower:UnsupportedCodegenInstruction`

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
summary distribution-real-rows mode=ReleaseFast selector_version=real-candidate-selector-v2 candidate_file_hash=83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d limit=200 candidate_rows=200 real_functions_lowered=188 real_objects_emitted=186 real_native_linked=186 real_executed=0 real_programs_ok=0 first_failing_real_row=../ziglang/src/main.zig/unicode.utf16IsHighSurrogate first_failing_stage=object-emission local_fail=1
```

## Gate Metadata Lines

```text
primary air-export-cache mode=ReleaseFast status=hit duration_ms=14639 cache_key=2aa5f28389aaec59887232a8b032b733d805ba6a64ad81ba1a454a7789799796 descriptor_bytes=1373517551
```
