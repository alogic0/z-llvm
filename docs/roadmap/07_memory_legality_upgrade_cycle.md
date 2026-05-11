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

- [ ] Add or document the LLVM memory-legality contract.
- [ ] Tighten volatile and atomic barrier classification.
- [ ] Add DataLayout-aware GEP offset handling for accepted pointer shapes.
- [ ] Strengthen AliasAnalysis/ModRef beyond always-unknown where fixtures need
      it.
- [ ] Add MemorySSA-like state for supported load/store/call clobber checks.
- [ ] Route DCE, ADCE, DSE, GVN, EarlyCSE, LICM, and SROA through the shared
      legality API.
- [ ] Add paired accepted/rejected memory fixtures for each client pass.
- [ ] Compare LLVM-equivalent fixtures with `opt-22`.

## Exit Criteria

- [ ] Memory legality is centralized and documented.
- [ ] Volatile/atomic cases are protected across all client passes.
- [ ] DataLayout-backed offset reasoning is tested.
- [ ] Local conservative differences from LLVM are explicit.

