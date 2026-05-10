# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

### Cycle 30: AIR-Like Pipeline Driver Helper

Source epic: [Target DataLayout and AIR-to-IR Bridge Epic](roadmap/target_datalayout_air_bridge_epic.md)
Epic sections: 4, 6, 7, 8

- [x] Add a helper driver that lowers an AIR-like spec, prints pre-optimization IR, runs a named pipeline, and prints post-optimization IR.
- [x] Reuse the existing pass manager and pipeline registry instead of adding a separate optimizer path.
- [x] Add tests proving `memory-foundation` can optimize AIR-like stack-memory output.
- [x] Keep CLI text parsing for AIR-like inputs out of scope.
- [x] Update AIR lowering docs, testing notes, unsupported IR notes, and target bridge epic progress.
- [x] Run `zig fmt` on touched Zig files, `zig build test`, and `bash scripts/compare_opt.sh`.
