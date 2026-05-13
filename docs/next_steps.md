# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 22: `function-attrs` direct-call inference

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `addMemoryAttrs`, `checkFunctionMemoryAccess`,
      `addNoRecurseAttrs`, and `mayHaveRecursiveCallee`.
- [x] Define the accepted local IR surface: function definitions with direct
      calls to local definitions or already annotated declarations.
- [x] Infer `memory(none)` or `memory(read)` from acyclic direct-call bodies
      while rejecting stores, volatile/atomic memory, inline asm, operand
      bundles, indirect calls, and unknown calls.
- [x] Infer `norecurse` for acyclic direct-call bodies while rejecting direct
      recursion, mutual recursion, indirect calls, and unannotated external
      calls.
- [x] Add `opt-22` fixtures for a direct-call inference case and recursive or
      unknown-call rejection boundaries.
- [x] Wire `function-attrs` as a real pass and update function-attribute docs,
      pipeline docs, parity docs, inventory, and roadmap status.
- [x] Run focused comparison.
- [x] Run readiness checks.
- [x] Review and commit Slice 22.
