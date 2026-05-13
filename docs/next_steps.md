# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 13: `indvars` canonical IV recognition and rewrite

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `IndVarSimplifyPass::run`, `rewriteLoopExitValues`,
      `simplifyAndExtend`, and ScalarEvolution affine AddRec construction.
- [x] Define the accepted local IR surface: self-latch counted loop, canonical
      `{0,+,1}` IV, one derived affine integer IV, equality exit on the
      canonical post-inc value, one dedicated exit, and exit use of the derived
      post-inc value.
- [x] Add a small SCEV-like affine AddRec helper for recognized LoopInfo IVs.
- [x] Replace the `indvars` placeholder with a real pass for that surface.
- [x] Rewrite the accepted derived IV exit value to the closed form computed
      from the loop limit, matching LLVM's narrow output shape.
- [x] Add an `opt-22` comparison fixture for the accepted affine IV rewrite.
- [x] Keep widening, non-self-latch loops, non-affine recurrences, non-equality
      exits, multiple exits, memory effects, debug salvage, and general
      ScalarEvolution out of scope and documented.
- [x] Update IndVarSimplify, SCEV, inventory, parity, and loop pipeline docs.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review, commit, and mark Slice 13 complete in the roadmap.
