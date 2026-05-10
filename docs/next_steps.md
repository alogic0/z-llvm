# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

### Cycle 38: Mem2Reg Memory Attribute Barriers

Source epic: none; source-level alignment correction from upstream LLVM review.
Epic sections: n/a

- [x] Reject volatile and atomic load/store users in `mem2reg` promotability.
- [x] Add `opt-22` comparison fixtures for volatile load/store alloca users.
- [x] Add local coverage for atomic alloca barriers.
- [x] Update `docs/passes/mem2reg.md` and `docs/testing.md` with the memory-attribute boundary.
- [x] Run `zig fmt`, `zig build test`, and `bash scripts/compare_opt.sh`.
- [ ] Clear `docs/next_steps.md` after committing the implementation.
