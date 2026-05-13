# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 11: `loop-rotate` for single-latch counted loops

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `LoopRotatePass::run`, `LoopRotate.cpp`, `LoopRotationUtils`,
      `Loop::getLoopPreheader`, `Loop::getLoopLatch`, and PHI repair behavior.
- [x] Define the accepted local IR surface: preheader, header, body, latch, and
      exit blocks; one latch; one dedicated exit; header condition branches to
      body or exit; latch unconditionally branches back to the header.
- [x] Replace the `loop-rotate` placeholder with a real loop pass for that
      surface.
- [x] Rotate the accepted while-shaped loop into the LLVM-compatible
      do-while-shaped loop for a simple counted integer induction pattern.
- [x] Repair PHI incoming blocks and exit LCSSA PHIs for the accepted shape.
- [x] Add an `opt-22` comparison fixture for the accepted counted loop.
- [x] Keep multi-latch loops, side exits, nested loops, metadata, debug salvage,
      MemorySSA updates, and general PHI duplication out of scope and documented.
- [x] Update loop simplify/rotation and parity docs.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review, commit, and mark Slice 11 complete in the roadmap.
