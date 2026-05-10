# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

### Cycle 35: Zig Fixture Pair Equivalence

Source epic: [Target DataLayout and AIR-to-IR Bridge Epic](roadmap/target_datalayout_air_bridge_epic.md)
Epic sections: 5, 6, 7, 8

- [x] Add project-lowered and optimized fixture outputs for the tiny Zig scalar fixture.
- [x] Extend the AIR-like builder to preserve function linkage needed by normalized Zig-emitted fixtures.
- [x] Add tests proving Zig-emitted normalized IR and AIR-like project-lowered IR agree on module records and scalar function signatures.
- [x] Keep exact instruction flag parity, raw aliases, debug metadata, and attribute groups out of scope.
- [x] Update fixture docs, testing docs, unsupported IR notes, and target bridge epic progress.
- [x] Run `zig fmt` on touched Zig files, `zig build test`, and `bash scripts/compare_opt.sh`.
