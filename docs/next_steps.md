# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

### Cycle 29: AIR-Like Canonical Loop Builder

Source epic: [Target DataLayout and AIR-to-IR Bridge Epic](roadmap/target_datalayout_air_bridge_epic.md)
Epic sections: 4, 7, 8

- [x] Extend the AIR-like helper builder with phi and icmp specs, with upstream Zig `FuncGen.zig` mapping.
- [x] Lower canonical preheader/header/body/latch/exit loop shapes into project IR.
- [x] Verify the lowered loop is accepted by LoopInfo preheader, latch, exiting block, and exit block queries.
- [x] Keep loop creation, LoopSimplify, LCSSA, multi-latch loops, and memory loop lowering out of scope.
- [x] Update AIR lowering docs, testing notes, unsupported IR notes, and target bridge epic progress.
- [x] Run `zig fmt` on touched Zig files, `zig build test`, and `bash scripts/compare_opt.sh`.
