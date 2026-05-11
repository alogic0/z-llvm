# Epic 5: Memory And Side-Effect Semantics

## Goal

Centralize memory and side-effect legality so LICM, GVN, DCE, ADCE,
InstCombine, and later passes do not each grow incompatible local rules.

## Inputs

- Verifier foundation from `03_llvm_compatible_ir_verifier_foundation.md`
- Canonicalization work from `04_mandatory_canonicalization_passes.md`
- Existing LICM, DCE, ADCE, and GVN code

## Plan

- [x] Define a memory-effect classification API:
      no memory, reads memory, writes memory, reads and writes, volatile
      barrier, atomic barrier, unknown side effect.
- [x] Record the LLVM memory-related analysis structures this epic is replacing
      or approximating:
      AliasAnalysis/ModRef, MemoryDependence, MemorySSA, load availability,
      clobber checks, and volatile/atomic legality.
- [x] Parse and represent `align` and `volatile` on load/store before modeling
      more expensive atomic details.
- [x] Classify atomic forms conservatively as barriers or unsupported syntax.
- [x] Add helper APIs for:
      may read memory, may write memory, may throw, may trap, may have side
      effects, and safe-to-delete.
- [x] Add conservative alias/mod-ref stubs with explicit "unknown" behavior.
- [x] Add DataLayout-shaped scalar GEP offset handling before enabling memory
      forwarding, redundant load elimination, or SROA rewrites that depend on
      byte offsets.
- [x] Add MemorySSA-like state only when a pass needs it, starting with a
      documented conservative approximation.
- [x] Wire LICM to use the shared memory-effect API.
- [x] Wire DCE and ADCE to use the shared safe-to-delete API.
- [x] Wire GVN to use memory legality only where the current alias answer makes
      the transform safe.
- [x] Wire EarlyCSE through the same available-load and clobber rules; keep
      available-call and available-store handling documented as later gaps.
- [x] Add rejected fixtures:
      volatile load/store, atomic forms, unknown calls, stores, variant pointer
      operands, and trapping operations.
- [x] Compare only LLVM-equivalent fixtures with `opt-22`; document local-only
      conservative gaps where LLVM uses stronger MemorySSA or alias reasoning.

## Deliverables

- [x] Memory-effect semantics doc.
- [x] Shared memory legality API.
- [x] Alias/ModRef and MemorySSA gap table.
- [x] Pass integrations for LICM, DCE, ADCE, and GVN.
- [x] Accepted and rejected memory legality fixtures.

## Exit Criteria

- [x] Memory-moving and memory-deleting passes share one legality model.
- [x] Volatile and atomic-like instructions are not accidentally optimized away.
- [x] Conservative differences from LLVM are documented.
- [x] Memory-dependent optimizations cannot claim LLVM equivalence without
      fixture evidence and documented alias/mod-ref assumptions.

## Implementation Notes

- Shared semantics are documented in
  `docs/semantics/memory_side_effect_semantics.md`.
- The core APIs live in `src/analysis/memory_effect.zig`,
  `src/analysis/memory_location.zig`, and `src/analysis/alias.zig`.
- DCE, ADCE, LICM, GVN, EarlyCSE, and DSE now use the shared legality model for
  deletion, speculation, clobber, or barrier decisions.
- MemorySSA remains a documented gap in `docs/analysis/memory_ssa.md`; current
  memory optimizations use conservative local scans and alias/mod-ref queries.
