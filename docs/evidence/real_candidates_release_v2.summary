# Gate Evidence Summary

schema_version: 1
log_path: `tmp/real_candidates_release_v2.log`
command: `zig build real-candidates-v2 -- --base=docs/evidence/real_candidates_releasefast_v1.tsv --out=docs/evidence/real_candidates_release_v2.tsv --releasefast-air=tmp/real_rows_air_export_cache/14aafd4cb1a62462316bb158620691968865acf560ce494d3f27569b5a14dfc8.air --releasesafe-air=tmp/real_rows_air_export_cache/28b649e25b667a3d0d63f5f41344d07516d50fe484d577fc0faf4398786e3015.air --releasesmall-air=tmp/real_rows_releasesmall_export_diag/compiler.air --migration-note='selector-v2 filters selector-v1 rows to functions present in ReleaseFast, ReleaseSafe, and ReleaseSmall AIR exports whose leaf claims hold in all three modes; mode-unstable and call-unstable rows leave the all-mode real-row denominator.' 2>&1 | tee tmp/real_candidates_release_v2.log`
z_llvm_commit: `660b268f330b4875b7a1b2e7050a3ef60fed2007`
ziglang_pin: `141bfce0883017ff7ebe03e3af3db07fff0c5dc3`
process_exit_status: `0`
first_failure_line: `none`

## Ratchet Metadata

candidate_file_hash: `83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d`
selector_version: `real-candidate-selector-v2`
mode: `all`
limit: `all`
comparison_log_path: `n/a`
comparison_summary_lines_match: `n/a`
ratchet_migration_note: `selector-v2 migrates from v1 hash eb59ef565de222a4b9dafd8ef7da21e37021e6a602889a60d0d597af1466a204 to v2 hash 83e81a860bb173c3b8c294153faff7af1f1dea73d1217969d6e87b6c08933d5d by removing mode-unstable rows and leaf-claim rows that contain calls in any release mode`

## Summary Lines

```text
summary distribution-real-candidates selector_version=real-candidate-selector-v2 base=docs/evidence/real_candidates_releasefast_v1.tsv path=docs/evidence/real_candidates_release_v2.tsv old_rows=61386 rows=19831 harnessable_rows=1789 not_yet_analyzed_rows=1959 proven_unharnessable_rows=16083 removed_mode_unstable=40432 removed_leaf_unstable=1123 first_removed_mode_unstable=../ziglang/src/main.zig/debug.Dwarf.invalidDebugInfoDetected first_removed_leaf_unstable=../ziglang/src/main.zig/debug.SafetyLock.assertUnlocked migration_note="selector-v2 filters selector-v1 rows to functions present in ReleaseFast, ReleaseSafe, and ReleaseSmall AIR exports whose leaf claims hold in all three modes; mode-unstable and call-unstable rows leave the all-mode real-row denominator." local_fail=0
```
