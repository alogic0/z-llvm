# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

Source cycle:
[Cycle 03: Future Raw Debug and ReleaseSafe Row Policy](roadmap/03_future_raw_debug_release_safe_policy_cycle.md)

Durable finish table:
[Finish Criteria and Gap Burn-Down Table](roadmap/finish_gap_burndown_table.md)

### Future Raw Debug And ReleaseSafe Policy Slice

- [ ] Inspect `tiny_scalar_debug`, `tiny_scalar_release_safe`, and their
      reduced accepted replacements in `docs/fixtures/zig_ir/manifest.tsv`.
- [ ] Decide whether the broad raw rows remain future evidence or move to a
      historical note.
- [ ] Add precise activation conditions for any row that remains future.
- [ ] Run `bash scripts/run_readiness_checks.sh`.
- [ ] Update `docs/roadmap/finish_gap_burndown_table.md` and
      `docs/unsupported_ir.md` with the final policy.
