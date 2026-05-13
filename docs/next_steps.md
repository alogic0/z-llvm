# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 10: `loop-simplifycfg` for loop-local dead branches

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `LoopSimplifyCFGPass::run`, `simplifyLoopCFG`,
      `constantFoldTerminators`, `ConstantTerminatorFoldingImpl::run`, and
      `foldTerminators`.
- [x] Define the accepted local IR surface: one natural loop with preheader,
      dedicated exits, existing LCSSA form, and a non-header loop block whose
      conditional branch has a constant condition.
- [x] Replace the `loop-simplifycfg` placeholder with a real loop pass for that
      surface.
- [x] Fold the loop-local constant conditional branch to an unconditional branch
      and repair PHI predecessor lists through CFG update helpers.
- [x] Remove newly unreachable loop-local blocks when the current loop header
      and latch remain reachable.
- [x] Add an `opt-22` comparison fixture for a loop body branch with a dead
      loop-local successor.
- [x] Keep current loop deletion, non-dedicated exits, indirect entry, switch,
      and LCSSA repair out of scope and documented.
- [x] Update loop simplify and parity docs.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review, commit, and mark Slice 10 complete in the roadmap.
