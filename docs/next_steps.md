# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

### Cycle 37: LLVM Alignment Tightening

Source epic: none; source-level alignment correction from upstream LLVM review.
Epic sections: n/a

- [x] Restrict `mem2reg` alloca discovery to the function entry block, matching LLVM's `Mem2Reg.cpp` wrapper.
- [x] Add an `opt-22` comparison fixture for non-entry allocas that must not be promoted.
- [x] Update `docs/passes/mem2reg.md` with the entry-block alloca rule and fixture coverage.
- [x] Tighten `docs/analysis/memory_location.md` around the scalar-only GEP offset boundary.
- [x] Keep `docs/passes/adce.md` explicitly named as an ADCE foundation until post-dominator/control-dependence logic exists.
- [x] Run `zig fmt`, `zig build test`, and `bash scripts/compare_opt.sh`.
- [ ] Clear `docs/next_steps.md` after committing the implementation.
