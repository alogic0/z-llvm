# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

### Cycle 25: AIR-Like Scalar Builder Bridge

Source epic: [Target DataLayout and AIR-to-IR Bridge Epic](roadmap/target_datalayout_air_bridge_epic.md)
Epic sections: 4, 7, 8

- [x] Add a tiny AIR-like helper builder that lowers scalar function specs into the project IR, with upstream Zig `FuncGen.zig` mapping.
- [x] Lower scalar integer binary operations and returns into one-entry-block functions.
- [x] Preserve target triple and datalayout on lowered modules.
- [x] Keep parsing a full input language, stack memory, loops, calls, comptime, generics, errors, async, and debug info out of scope.
- [x] Add builder round-trip tests and `docs/codegen/air_lowering.md`.
- [x] Update inventory, testing notes, unsupported IR notes, and target bridge epic progress.
- [x] Run `zig fmt` on touched Zig files, `zig build test`, and `bash scripts/compare_opt.sh`.
