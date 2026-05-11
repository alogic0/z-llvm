# Cycle 7: Memory Legality Upgrade

## Goal

Strengthen shared memory legality so DCE, ADCE, DSE, GVN, EarlyCSE, LICM, and
SROA use one conservative model for aliasing, ModRef, volatile, atomic, and
DataLayout-aware address reasoning.

## Source Anchors

- LLVM analyses: AliasAnalysis, ModRef, MemorySSA, MemoryDependence
- LLVM users: DSE, GVN, EarlyCSE, LICM, SROA
- Local docs: `docs/analysis/alias.md`, `docs/analysis/memory_effect.md`,
  `docs/analysis/memory_location.md`, `docs/analysis/memory_ssa.md`
- Backlog source:
  `docs/roadmap/llvm_algorithm_parity_gap_closure_plan.md`

## Plan

- [x] Add or document the LLVM memory-legality contract.
- [x] Tighten volatile and atomic barrier classification.
- [x] Add DataLayout-aware GEP offset handling for accepted pointer shapes.
- [x] Strengthen AliasAnalysis/ModRef beyond always-unknown where fixtures need
      it.
- [x] Add a MemorySSA-like clobber helper for supported load/store/call checks.
- [x] Route GVN load availability through the shared clobber helper and keep
      DCE, ADCE, DSE, EarlyCSE, LICM, and SROA on documented conservative
      memory-effect/alias gates for this slice.
- [x] Add paired accepted/rejected memory fixtures for each client pass.
- [x] Compare LLVM-equivalent fixtures with `opt-22`.

## Exit Criteria

- [x] Memory legality is centralized and documented.
- [x] Volatile/atomic cases are protected across all client passes.
- [x] DataLayout-backed offset reasoning is tested.
- [x] Local conservative differences from LLVM are explicit.

## Notes

This slice centralizes the clobber query used by GVN and documents the client
boundaries. EarlyCSE still uses scoped local availability plus the shared
clobber helper for load CSE; DSE keeps its single-block reverse scan. Those are
intentional conservative stages, not full MemorySSA integration.
