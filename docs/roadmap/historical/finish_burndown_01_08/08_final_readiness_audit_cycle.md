# Cycle 08: Final Readiness Audit

## Goal

Re-run the finish evidence after Cycles 02-07 and decide whether remaining gaps
are accepted boundaries, later measured blockers, active next work, or out of
scope.

## Plan

- [x] Run `bash scripts/run_readiness_checks.sh`.
- [x] Refresh manifest counts:
      accepted, unsupported, future, debug-info-only, optimizer-input.
- [x] Refresh opt fixture counts:
      `opt-equivalent`, `local-conservative`, `parse-preserve-only`, and total.
- [x] Refresh pass status counts.
- [x] Audit `docs/unsupported_ir.md` against the manifest and finish table.
- [x] Audit pass and analysis docs for overstated LLVM parity claims.
- [x] Update `docs/roadmap/finish_gap_burndown_table.md` with final gap
      statuses.
- [x] Decide whether to archive this finish-burn-down cycle series or create
      one more measured cycle.

## Exit Criteria

- [x] Readiness gates pass or failures are explicit blockers.
- [x] No remaining gap has an undefined status.
- [x] The README reflects the final active/archive state.
- [x] The project has a concrete next decision: archive, one more measured
      cycle, or stop.

## Completed Audit

```text
Readiness:
  ok manifest rows=37 optimizer_input=30
  summary accepted=30 unsupported=0 future=4 debug-info-only=0
  ok readiness checks

Manifest counts:
  accepted optimizer-input rows: 30
  unsupported rows: 0
  future rows: 4
  debug-info-only rows: 0

Opt fixture counts:
  opt-equivalent: 116
  local-conservative: 44
  parse-preserve-only: 7
  total: 167

Pass status counts:
  placeholder: 70
  LLVM-shaped subset: 2
  fixture-equivalent: 13
  algorithm-parity target: 0
```

Audit result: the unsupported IR document matches the finish table boundaries,
and the pass/analysis docs keep full LLVM algorithm parity out of the current
finish line. The concrete decision is to stop this burn-down wave. Future work
must come from the future optimizer backlog or a new measured source-backed
blocker.
