# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

Source cycle:
[Cycle 08: Final Readiness Audit](roadmap/08_final_readiness_audit_cycle.md)

Durable finish table:
[Finish Criteria and Gap Burn-Down Table](roadmap/finish_gap_burndown_table.md)

### Final Readiness Audit Slice

- [ ] Refresh manifest, opt fixture, and pass status counts.
- [ ] Audit unsupported IR, pass docs, and analysis docs for overstated parity
      claims.
- [ ] Update the finish table with final gap statuses.
- [ ] Decide whether to archive this burn-down series or create one more
      measured cycle.
- [ ] Run `bash scripts/run_readiness_checks.sh`.
