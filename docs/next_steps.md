# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 30: Inline asm memory-effect refinement

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `InlineAsm` extra-info flags, memory constraint classes, and
      `CallBase` memory-effect handling.
- [x] Represent inline-asm side effects separately from memory read/write
      effects.
- [x] Derive local `may_load`/`may_store` facts from `~{memory}` and simple
      memory constraints.
- [x] Keep non-`sideeffect` inline asm and target-specific constraint lowering
      documented as local boundaries.
- [x] Add unit and opt fixture coverage for side-effect-only and memory-clobber
      inline asm behavior.
- [x] Update atomic/inline-asm, memory-effect, parity, and roadmap docs.
- [x] Run focused inline-asm comparison/tests.
- [x] Run readiness checks.
- [x] Review and commit Slice 30.
