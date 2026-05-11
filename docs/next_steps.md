# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

Source cycle:
[Cycle 06: Debug Salvage Boundary Burn-Down](roadmap/06_debug_salvage_boundary_burndown_cycle.md)

Durable finish table:
[Finish Criteria and Gap Burn-Down Table](roadmap/finish_gap_burndown_table.md)

### Debug Salvage Boundary Slice

- [ ] Inventory transforms that remove or replace instructions carrying `!dbg`.
- [ ] Add or refine fixtures for DCE, InstCombine, EarlyCSE, GVN, and SROA
      where relevant.
- [ ] Preserve debug locations on unchanged or leader instructions.
- [ ] Keep `llvm.dbg.value` and `llvm.dbg.declare` transform pipelines
      disabled until variable-location salvage exists.
- [ ] Update debug metadata docs, affected pass docs, unsupported IR docs, and
      the finish table.
- [ ] Run `bash scripts/run_readiness_checks.sh`.
