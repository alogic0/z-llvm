# Cycle 04: Vector Future Boundary Closure

## Goal

Finalize the `vector_future_release_fast` boundary: keep it as a conservative
accepted boundary or promote exactly one narrow vector optimizer-input slice.

## Evidence

The finish table treats `vector_future_release_fast` as `parse,verify,future`.
The local optimizer already supports pure lane operations, dead lane DCE,
same-lane extract-after-insert, and identical-arm vector select with scalar
`i1` condition.

## Plan

- [x] Inspect the reduced vector row and current vector opt fixtures.
- [x] Decide whether the row should stay `parse,verify,future` or become a
      bounded optimizer-input row.
- [x] If kept future, document the exact blocker: vector FP semantics,
      vector-condition select, scalable vectors, target cost, or native vector
      lowering.
- [x] If promoted, select one target-independent transform only and add opt-22
      comparison fixtures.
- [x] Update vector docs, target-cost docs, manifest classification, and the
      finish table.
- [x] Run `bash scripts/run_readiness_checks.sh` and record the summary.

## Exit Criteria

- [x] The vector future row has a deliberate finish status.
- [x] Vectorizers and target-cost-driven transforms remain out of scope unless
      explicitly activated.
- [x] Existing vector lane memory-safety fixtures remain covered.

## Completed Slice

`vector_future_release_fast` remains `parse,verify,future`. The accepted
optimizer proof stays in target-independent lane fixtures such as
`vector_lane_dead_dce`, `vector_extract_insert_fold`,
`vector_select_same_arms`, and the vector lane memory-safety fixtures. The
future row activates only when target-cost or native vector-lowering work is
selected.

Readiness summary:

```text
ok manifest rows=37 optimizer_input=30
summary accepted=30 unsupported=0 future=4 debug-info-only=0
ok readiness checks
```
