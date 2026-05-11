# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

Source cycle:
[Cycle 01: Finish Criteria and Gap Burn-Down](roadmap/01_finish_criteria_and_gap_burndown_cycle.md)

Durable finish table:
[Finish Criteria and Gap Burn-Down Table](roadmap/finish_gap_burndown_table.md)

### Corpus Closure Slice: Stale ReleaseSmall Raw Row

- [ ] Inspect `tiny_scalar_release_small` in
      `docs/fixtures/zig_ir/manifest.tsv` and compare it with the accepted
      `tiny_scalar_release_small_captured` row.
- [ ] Decide whether the old raw unsupported row should be removed, replaced by
      a reduced fixture, or kept as an explicit out-of-scope historical row.
- [ ] If it remains in the manifest, update its classification and notes so it
      is not an unowned finish blocker.
- [ ] Run `bash scripts/run_readiness_checks.sh`.
- [ ] Update `docs/roadmap/finish_gap_burndown_table.md` and
      `docs/unsupported_ir.md` with the final disposition.
