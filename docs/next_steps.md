# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

### Cycle 17: Target Records and DataLayout Foundation

Source epic: [Target DataLayout and AIR-to-IR Bridge Epic](roadmap/target_datalayout_air_bridge_epic.md)
Epic sections: 1, 2, 3, 7, 8

- [ ] Add a `src/target/` module for target triple parsing and a minimal `DataLayout` query API, with upstream LLVM mapping.
- [ ] Parse and print module-level `source_filename`, `target triple`, and `target datalayout` records.
- [ ] Add `void` return type and `ret void` parsing, printing, and verification for tiny Zig-emitted IR compatibility.
- [ ] Add tests for target record round-tripping, x86_64 datalayout queries, and void-return functions.
- [ ] Update target/module IR docs, `unsupported_ir.md`, `testing.md`, and inventory coverage.
- [ ] Run `zig fmt` on touched Zig files, `zig build test`, and `bash scripts/compare_opt.sh`.
