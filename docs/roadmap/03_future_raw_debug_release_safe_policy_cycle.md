# Cycle 03: Future Raw Debug and ReleaseSafe Row Policy

## Goal

Decide the finish policy for broad raw `tiny_scalar_debug` and
`tiny_scalar_release_safe` future rows without expanding the finish line to
whole-program Debug or ReleaseSafe IR.

## Evidence

The finish table classifies both rows as later measured blockers. Reduced Debug
and ReleaseSafe fixtures already cover the accepted local boundaries.

## Plan

- [x] Re-read the manifest rows for `tiny_scalar_debug`,
      `tiny_scalar_release_safe`, and their reduced accepted replacements.
- [x] Decide whether broad raw rows remain in the manifest as future evidence,
      move to a historical note, or get replaced by smaller reduced fixtures.
- [x] If a row remains future, add a precise activation condition tied to a
      source-backed construct that is not already covered.
- [x] If a row moves out of the active finish corpus, update manifest counts,
      unsupported docs, and the finish table.
- [x] Verify that Debug and ReleaseSafe accepted reduced rows still run through
      the readiness gate.
- [x] Run `bash scripts/run_readiness_checks.sh` and record the summary.

## Exit Criteria

- [x] Broad raw Debug and ReleaseSafe rows have an explicit finish policy.
- [x] Reduced fixtures remain the accepted implementation evidence.
- [x] No broad raw row is treated as an undefined finish blocker.

## Completed Slice

`tiny_scalar_debug` and `tiny_scalar_release_safe` remain in the manifest as
historical `future,legacy-bootstrap` evidence. Each row now has an activation
condition tied to reducing a concrete source-backed Debug, safety, or
runtime-call construct not already covered by accepted reduced rows.

Readiness summary:

```text
ok manifest rows=37 optimizer_input=30
summary accepted=30 unsupported=0 future=4 debug-info-only=0
ok readiness checks
```
