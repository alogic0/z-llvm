# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

Source cycle:
[Cycle 04: Vector Future Boundary Closure](roadmap/04_vector_future_boundary_closure_cycle.md)

Durable finish table:
[Finish Criteria and Gap Burn-Down Table](roadmap/finish_gap_burndown_table.md)

### Vector Future Boundary Closure Slice

- [ ] Inspect `vector_future_release_fast` and current vector opt fixtures.
- [ ] Decide whether the row stays `parse,verify,future` or becomes a bounded
      optimizer-input row.
- [ ] If kept future, document the exact blocker and activation condition.
- [ ] Run `bash scripts/run_readiness_checks.sh`.
- [ ] Update vector docs, target-cost docs, manifest notes, and the finish
      table with the final boundary.
