# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 9: Function call ModRef expansion

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `BasicAAResult::getMemoryEffects`,
      `BasicAAResult::getModRefInfo`, `MemoryEffects`, and `ModRefInfo`.
- [x] Define the accepted local IR surface: direct non-inline-asm calls with
      resolved declaration/function/call-site attributes and pointer arguments.
- [x] Parse and model `memory(none)`, `memory(read)`, `memory(write)`,
      `memory(readwrite)`, `memory(argmem: ...)`, `memory(inaccessiblemem: ...)`,
      `readnone`, `readonly`, `writeonly`, `argmemonly`, and
      `inaccessiblememonly` for ModRef queries.
- [x] Route call ModRef queries through the alias layer so MemorySSA-backed
      GVN, EarlyCSE, DSE, and LICM legality can distinguish no-mod-ref,
      ref-only, mod-only, and unknown direct calls.
- [x] Add unit coverage for readnone, readonly, argmem-only alias/noalias,
      inaccessiblemem-only, and unknown direct calls.
- [x] Add an `opt-22` comparison fixture showing an argmem-only noalias call
      does not clobber a later load.
- [x] Keep existing unknown-call clobber fixtures as negative boundaries.
- [x] Update alias, MemorySSA/call-semantics, and parity docs.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review, commit, and mark Slice 9 complete in the roadmap.
