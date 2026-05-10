# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

### Cycle 26: AIR-Like Scalar Arithmetic Coverage

Source epic: [Target DataLayout and AIR-to-IR Bridge Epic](roadmap/target_datalayout_air_bridge_epic.md)
Epic sections: 4, 7, 8

- [x] Extend the AIR-like helper builder with scalar integer casts, with upstream Zig `FuncGen.zig` mapping.
- [x] Confirm the builder can lower add/sub/mul/bitwise/shift binary operations through the existing `BinaryOp` surface.
- [x] Add round-trip tests covering binary operations and cast lowering.
- [x] Keep overflow intrinsics, poison/flags, vector/floating-point arithmetic, and comparisons out of scope.
- [x] Update AIR lowering docs, testing notes, unsupported IR notes, and target bridge epic progress.
- [x] Run `zig fmt` on touched Zig files, `zig build test`, and `bash scripts/compare_opt.sh`.
