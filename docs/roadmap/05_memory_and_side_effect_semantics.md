# Epic 5: Memory And Side-Effect Semantics

## Goal

Centralize memory and side-effect legality so LICM, GVN, DCE, ADCE,
InstCombine, and later passes do not each grow incompatible local rules.

## Inputs

- Verifier foundation from `03_llvm_compatible_ir_verifier_foundation.md`
- Canonicalization work from `04_mandatory_canonicalization_passes.md`
- Existing LICM, DCE, ADCE, and GVN code

## Plan

- [ ] Define a memory-effect classification API:
      no memory, reads memory, writes memory, reads and writes, volatile
      barrier, atomic barrier, unknown side effect.
- [ ] Record the LLVM memory-related analysis structures this epic is replacing
      or approximating:
      AliasAnalysis/ModRef, MemoryDependence, MemorySSA, load availability,
      clobber checks, and volatile/atomic legality.
- [ ] Parse and represent `align` and `volatile` on load/store before modeling
      more expensive atomic details.
- [ ] Classify atomic forms conservatively as barriers or unsupported syntax.
- [ ] Add helper APIs for:
      may read memory, may write memory, may throw, may trap, may have side
      effects, and safe-to-delete.
- [ ] Add conservative alias/mod-ref stubs with explicit "unknown" behavior.
- [ ] Add DataLayout-aware GEP offset handling before enabling memory
      forwarding, redundant load elimination, or SROA rewrites that depend on
      byte offsets.
- [ ] Add MemorySSA-like state only when a pass needs it, starting with a
      documented conservative approximation.
- [ ] Wire LICM to use the shared memory-effect API.
- [ ] Wire DCE and ADCE to use the shared safe-to-delete API.
- [ ] Wire GVN to use memory legality only where the current alias answer makes
      the transform safe.
- [ ] Wire EarlyCSE, when implemented, through the same available-load,
      available-call, available-store, generation, and clobber rules.
- [ ] Add rejected fixtures:
      volatile load/store, atomic forms, unknown calls, stores, variant pointer
      operands, and trapping operations.
- [ ] Compare only LLVM-equivalent fixtures with `opt-22`; document local-only
      conservative gaps where LLVM uses stronger MemorySSA or alias reasoning.

## Deliverables

- [ ] Memory-effect semantics doc.
- [ ] Shared memory legality API.
- [ ] Alias/ModRef and MemorySSA gap table.
- [ ] Pass integrations for LICM, DCE, ADCE, and GVN.
- [ ] Accepted and rejected memory legality fixtures.

## Exit Criteria

- [ ] Memory-moving and memory-deleting passes share one legality model.
- [ ] Volatile and atomic-like instructions are not accidentally optimized away.
- [ ] Conservative differences from LLVM are documented.
- [ ] Memory-dependent optimizations cannot claim LLVM equivalence without
      fixture evidence and documented alias/mod-ref assumptions.
