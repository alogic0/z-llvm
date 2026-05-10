# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

### Cycle 19: Module Linkage and Attribute Preservation

Source epic: [Target DataLayout and AIR-to-IR Bridge Epic](roadmap/target_datalayout_air_bridge_epic.md)
Epic sections: 2, 7, 8

- [ ] Parse and print function linkage for default, `internal`, `private`, and `external` definitions, with upstream LLVM mapping.
- [ ] Parse and preserve function header attributes that the optimizer does not semantically consume yet.
- [ ] Add explicit parser errors for unsupported global/module-level constructs that would otherwise be silently ignored.
- [ ] Add round-trip tests for module records plus linkage/attribute preservation.
- [ ] Update `docs/ir_module.md`, `docs/unsupported_ir.md`, `docs/testing.md`, and inventory coverage.
- [ ] Run `zig fmt` on touched Zig files, `zig build test`, and `bash scripts/compare_opt.sh`.
