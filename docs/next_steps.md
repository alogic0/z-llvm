# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

### Cycle 36: Target Bridge Epic Closeout

Source epic: [Target DataLayout and AIR-to-IR Bridge Epic](roadmap/target_datalayout_air_bridge_epic.md)
Epic sections: 1, 2, 4, 7, 8

- [x] Mark completed suggested-slice and documentation checklist items in the target bridge epic.
- [x] Confirm unsupported target, ABI, module, and AIR constructs are documented.
- [x] Keep MC/Object bootstrap explicitly out of scope until this epic is closed.
- [x] Run final verification: `zig fmt`, `zig build test`, `bash scripts/compare_opt.sh`, and Zig-emitted fixture tests.
- [ ] Clear `docs/next_steps.md` after committing the closeout.
