# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

### Cycle 23: Scalar Global Variable Preservation

Source epic: [Target DataLayout and AIR-to-IR Bridge Epic](roadmap/target_datalayout_air_bridge_epic.md)
Epic sections: 2, 7, 8

- [x] Add module-level scalar `global` and `constant` definitions with upstream LLVM mapping.
- [x] Preserve global linkage, integer/undef initializers, and raw suffix attributes without optimizer semantics yet.
- [x] Keep arrays, strings, COMDAT, TLS, aliases, declarations, and metadata explicitly unsupported.
- [x] Add round-trip tests for supported scalar globals and rejection tests for unsupported aggregate globals.
- [x] Update `docs/ir_module.md`, `docs/unsupported_ir.md`, `docs/testing.md`, inventory coverage, and target bridge epic progress.
- [x] Run `zig fmt` on touched Zig files, `zig build test`, and `bash scripts/compare_opt.sh`.
