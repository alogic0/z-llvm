# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

Active cycle:

- [ ] [Cycle 01: Input Size Tooling](roadmap/01_input_size_tooling_cycle.md)
- [x] Source-backed parser blocker: accept constant-expression `getelementptr`
      pointer operands in load, store, atomicrmw, and cmpxchg memory
      instructions. Upstream mapping is recorded in [Memory IR
      Subset](ir_memory.md).

The Cycle 02-08 finish burn-down wave is complete. Discovery Cycles 01-07 are
archived under [Completed Discovery
Cycles](roadmap/historical/completed_discovery_cycles/README.md). Cycle 07
refreshed selected checked stage4 corpus rows byte-identically, so no new
source-backed blocker is active. The durable finish table is [Finish Criteria
and Gap Burn-Down
Table](roadmap/finish_gap_burndown_table.md).

### Selection Rule

- [ ] Select the next bounded slice from
      [Future Optimizer Backlog](roadmap/future_optimizer_backlog.md) or from a
      new measured source-backed blocker.
- [ ] Add upstream LLVM mapping before marking a new future step complete.
