# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

### Cycle 34: Target Diagnostic Integration

Source epic: [Target DataLayout and AIR-to-IR Bridge Epic](roadmap/target_datalayout_air_bridge_epic.md)
Epic sections: 6, 7, 8

- [x] Add explicit CLI diagnostics for invalid target triples and datalayout strings supplied by flags.
- [x] Add explicit CLI diagnostics for missing or unsupported assembly targets.
- [x] Keep diagnostics scoped to current target-aware bridge and x86_64 assembly bootstrap support.
- [x] Smoke-test supported and unsupported target paths.
- [x] Update testing docs, unsupported IR notes, and target bridge epic progress.
- [x] Run `zig fmt` on touched Zig files, `zig build test`, and `bash scripts/compare_opt.sh`.
