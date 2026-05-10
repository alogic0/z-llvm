# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

### Cycle 39: MC/Object Bootstrap

Source epic: [MC/Object Bootstrap Epic](roadmap/mc_object_bootstrap_epic.md)
Epic sections: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11

- [x] Align the existing x86_64 assembly bootstrap with upstream LLVM CodeGen/MC entry points.
- [x] Extend Machine IR for x86_64 SysV argument registers, scalar binary ops, labels, and simple conditional returns.
- [x] Add a machine verifier for return-register and branch-label invariants.
- [x] Add x86_64 binary instruction encoding tests independent from ELF writing.
- [x] Add a minimal ELF64 relocatable object writer for `.text`, `.symtab`, `.strtab`, and `.shstrtab`.
- [x] Add `--emit=obj` and codegen fixtures for constant, argument, add, bitwise, and conditional-return shapes.
- [x] Update MC/Object docs, inventory, unsupported-IR docs, testing docs, and epic checkboxes.
- [x] Run `zig fmt`, `zig build test`, `bash scripts/compare_opt.sh`, assembly/object smoke checks, and upstream-alignment checks.
- [ ] Clear `docs/next_steps.md` after committing the implementation.
