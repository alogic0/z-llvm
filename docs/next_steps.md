# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

### Cycle 20: Visibility and Parameter Attribute Preservation

Source epic: [Target DataLayout and AIR-to-IR Bridge Epic](roadmap/target_datalayout_air_bridge_epic.md)
Epic sections: 2, 3, 7, 8

- [ ] Parse and print function visibility for the first supported forms emitted by tiny Zig examples, with upstream LLVM mapping.
- [ ] Parse and preserve parameter attributes as raw metadata without optimizer semantics.
- [ ] Add round-trip tests for function visibility and parameter attributes.
- [ ] Update module IR docs, unsupported IR notes, testing coverage, inventory status, and target bridge epic progress.
- [ ] Run `zig fmt` on touched Zig files, `zig build test`, and `bash scripts/compare_opt.sh`.
