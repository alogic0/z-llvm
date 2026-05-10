# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

### Cycle 31: Zig-Emitted IR Fixture Harness

Source epic: [Target DataLayout and AIR-to-IR Bridge Epic](roadmap/target_datalayout_air_bridge_epic.md)
Epic sections: 3, 5, 7, 8

- [x] Add a tiny Zig source fixture and documented Zig command that emits LLVM IR through Zig's LLVM backend.
- [x] Add a normalized Zig-emitted LLVM IR fixture for the scalar signature subset this project can parse.
- [x] Add tests comparing normalized Zig-emitted function signatures and module records against the project parser/printer.
- [x] Classify the fixture as `zig-equivalent` and document unsupported raw Zig IR constructs.
- [x] Update testing docs, inventory, unsupported IR notes, and target bridge epic progress.
- [x] Run `zig fmt` on touched Zig files, `zig build test`, and `bash scripts/compare_opt.sh`.
