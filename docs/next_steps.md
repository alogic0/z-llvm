# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

### Cycle 33: Target-Aware Function Signature Model

Source epic: [Target DataLayout and AIR-to-IR Bridge Epic](roadmap/target_datalayout_air_bridge_epic.md)
Epic sections: 3, 7, 8

- [x] Add a target-aware function signature classification model over project IR functions, with upstream LLVM ABI mapping.
- [x] Classify scalar return and parameter ABI slots using the existing target matrix and DataLayout queries.
- [x] Keep aggregate ABI lowering documented as out of scope.
- [x] Add tests for scalar integer, pointer, and void function signatures.
- [x] Update scalar ABI docs, testing notes, unsupported IR notes, and target bridge epic progress.
- [x] Run `zig fmt` on touched Zig files, `zig build test`, and `bash scripts/compare_opt.sh`.
