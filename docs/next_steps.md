# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 28: Debug location salvage for InstCombine

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM InstCombine `replaceInstUsesWith` users and
      `llvm/lib/Transforms/Utils/Local.cpp` debug salvage utilities.
- [x] Choose one accepted local surface: a folded instruction with `!dbg`
      whose later user has no metadata.
- [x] Transfer the removed instruction `!dbg` attachment to the first
      metadata-free user before operand replacement.
- [x] Keep full `salvageDebugInfo` and variable-location rewriting documented
      as unsupported.
- [x] Add fixture coverage for the debug-location transfer.
- [x] Update InstCombine, debug metadata, parity, and roadmap docs.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review and commit Slice 28.
