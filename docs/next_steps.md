# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

Source cycle:
[Cycle 05: Optimizer Quality Burn-Down](roadmap/05_optimizer_quality_burndown_cycle.md)

Durable finish table:
[Finish Criteria and Gap Burn-Down Table](roadmap/finish_gap_burndown_table.md)

### Optimizer Quality Slice: SROA Exact-Cover Aggregate Fields

- [ ] Select one measured optimizer gap from SROA, GVN PRE, or ADCE control
      dependence.
- [ ] Record LLVM source mapping and local unsupported behavior before changes.
- [ ] Add accepted and rejected fixtures for the selected gap.
- [ ] Compare equivalent fixtures against `opt-22`.
- [ ] Update pass docs, analysis docs, fixture table, and the finish table.
- [ ] Run `bash scripts/run_readiness_checks.sh`.
