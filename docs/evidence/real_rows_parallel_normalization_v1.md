# Real-Rows Mode-Parallel Equivalence Normalization v1

Directive: `INBOX-69`
Status: frozen for staged validation
Authority: `tools/run_distribution_real_rows_parallel.zig`
Tool: `tools/normalize_real_rows_parallel_output.zig`

The canonical comparison population is the complete buffered output of the
ReleaseFast, ReleaseSafe, and ReleaseSmall real-row gates, in that order. Each
mode must contribute exactly one gate header, one `air-export-cache` hit, and
one `distribution-real-rows-v2` summary. The three summaries must retain the
accepted 100/100/100 lower/object/link counts, `real_executed=0`,
`real_programs_ok=0`, no first failure, and `local_fail=0`.

Normalization may replace only these volatile field families:

- durations (`duration_ms`, group `wall_ms`, and `summed_child_ms`);
- random run identities and runner-owned scratch/cache paths;
- free-space, disk, aggregate-RSS, available-memory, and load samples;
- the separate `real-rows-mode-parallel` scheduling record.

The scheduling record is outside mandatory gate summaries and is omitted from
the canonical comparison. No case or mode identity, ordering, cache status,
counter, diagnostic, classification, candidate hash, cache key, descriptor
hash, or other artifact identity may be normalized. The real-row gate exposes
no per-row object hashes, so this comparison makes no per-row object-identity
claim. Execution results are never cached.
