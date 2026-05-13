# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 25: `vector-combine` for extract/insert lane identity

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `VectorCombine` pass structure and the exact
      extract-after-insert fold owner in `InstCombineVectorOps.cpp`.
- [x] Define the accepted local IR surface: fixed vectors, constant extract and
      insert indices, matching vector type, and matching inserted scalar type.
- [x] Implement same-lane extraction as replacement with the inserted scalar.
- [x] Implement different-lane extraction as replacement with an extract from
      the original vector.
- [x] Remove the now-dead insertelement only when it has no remaining uses.
- [x] Add `opt-22` fixtures for same-lane and different-lane extraction.
- [x] Wire `vector-combine` as a real pass and update vector, target-cost,
      parity, inventory, and roadmap docs.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review and commit Slice 25.
