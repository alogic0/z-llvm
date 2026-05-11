# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

Source cycle:
[Cycle 07: Handoff Proof Burn-Down](roadmap/07_handoff_proof_burndown_cycle.md)

Durable finish table:
[Finish Criteria and Gap Burn-Down Table](roadmap/finish_gap_burndown_table.md)

### Handoff Proof Slice

- [ ] Inspect current handoff validation fixtures and identify the weakest
      covered shape.
- [ ] Select one non-trivial shape and keep it inside the existing x86_64 smoke
      path.
- [ ] Add the smallest fixture and validation command needed to prove the
      selected handoff.
- [ ] Update codegen handoff docs, readiness scripts, and the finish table.
- [ ] Keep broad backend parity out of scope.
- [ ] Run `bash scripts/run_readiness_checks.sh`.
