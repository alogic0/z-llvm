# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [LLVM-Shaped Stub Replacement Plan](roadmap/llvm_shaped_stub_replacement_plan.md)

Active slice: Slice 29: Atomic ordering semantic verifier

Goal: replace placeholder/local-conservative behavior with LLVM-shaped behavior.

- [x] Map LLVM `Verifier.cpp` atomic load/store, `cmpxchg`, `atomicrmw`,
      and fence validation.
- [x] Add LLVM-shaped atomic access type and byte-sized power-of-two checks
      for the local scalar/vector surface.
- [x] Add LLVM-shaped `atomicrmw` operation/type and `cmpxchg` operand-type
      validation.
- [x] Keep DataLayout-dependent pointer and vector-pointer sizing documented
      as a local boundary.
- [x] Add unit coverage for accepted ordering/syncscope forms and rejected
      LLVM verifier cases.
- [x] Update atomic/verifier/parity/roadmap docs.
- [x] Run focused verifier tests.
- [x] Run readiness checks.
- [x] Review and commit Slice 29.
