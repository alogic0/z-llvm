# Cycle 02: Stale ReleaseSmall Corpus Row Closure

## Goal

Close the remaining unsupported `tiny_scalar_release_small` raw manifest row so
the finish table no longer has an unowned unsupported blocker.

## Evidence

The finish burn-down table identifies `tiny_scalar_release_small` as the active
next step. The row predates the accepted stripped
`tiny_scalar_release_small_captured` row and still records unsupported aliases,
size attributes, and raw function attributes.

## Plan

- [x] Inspect `tiny_scalar_release_small` and
      `tiny_scalar_release_small_captured` in
      `docs/fixtures/zig_ir/manifest.tsv`.
- [x] Decide whether the old raw row should be removed from the finish corpus,
      replaced by a reduced fixture, or retained as an explicitly historical
      out-of-scope row.
- [x] If retained, update the row classification and notes so it is not a
      finish blocker.
- [x] Update `docs/roadmap/finish_gap_burndown_table.md` with the final
      disposition.
- [x] Update `docs/unsupported_ir.md` so the unsupported/future row count and
      explanation stay honest.
- [x] Run `bash scripts/run_readiness_checks.sh` and record the summary.

## Exit Criteria

- [x] `tiny_scalar_release_small` is no longer an unowned unsupported finish
      blocker.
- [x] Manifest counts and finish-table counts agree.
- [x] `docs/next_steps.md` either marks this slice complete or selects the next
      active slice.

## Completed Slice

`tiny_scalar_release_small` is retained as `future,legacy-bootstrap` historical
evidence and no longer counts as an unsupported finish blocker. The accepted
ReleaseSmall implementation proof is `tiny_scalar_release_small_captured`.

Readiness summary:

```text
ok manifest rows=37 optimizer_input=30
summary accepted=30 unsupported=0 future=4 debug-info-only=0
ok readiness checks
```
