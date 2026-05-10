# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

### Cycle 24: Scalar ABI Signature Classification

Source epic: [Target DataLayout and AIR-to-IR Bridge Epic](roadmap/target_datalayout_air_bridge_epic.md)
Epic sections: 3, 7, 8

- [x] Add a target-aware scalar ABI classification helper for void, integer, and pointer returns/parameters, with upstream LLVM mapping.
- [x] Use the initial target matrix and DataLayout pointer-size queries instead of hard-coded pointer widths.
- [x] Keep aggregate, vector, float, varargs, byval/sret, and stack-slot classification explicitly unsupported.
- [x] Add unit tests for scalar return and parameter classification on the initial target matrix.
- [x] Add scalar ABI docs and update inventory, testing notes, unsupported IR notes, and target bridge epic progress.
- [x] Run `zig fmt` on touched Zig files, `zig build test`, and `bash scripts/compare_opt.sh`.
