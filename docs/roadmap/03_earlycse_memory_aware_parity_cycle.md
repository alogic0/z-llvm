# Cycle 3: EarlyCSE Memory-Aware Parity

## Goal

Move EarlyCSE toward LLVM's dominator-scoped common subexpression elimination,
including conservative memory-aware load, store, and call handling.

## Source Anchors

- LLVM: `llvm/lib/Transforms/Scalar/EarlyCSE.cpp`
- LLVM memory support: MemorySSA, clobber checks, available values
- Local docs: `docs/passes/early_cse.md`,
  `docs/analysis/memory_effect.md`, `docs/analysis/memory_ssa.md`
- Backlog source:
  `docs/roadmap/llvm_algorithm_parity_gap_closure_plan.md`

## Plan

- [ ] Add or document the LLVM EarlyCSE algorithm contract.
- [ ] Add scoped hash tables keyed by dominator scope.
- [ ] Track available pure expressions.
- [ ] Track available loads only when alias/mod-ref proves reuse safe.
- [ ] Add conservative store-to-load forwarding.
- [ ] Add call CSE only for calls with matching no-memory or safe memory-effect
      classification.
- [ ] Add MemorySSA-like generation and clobber checks where needed.
- [ ] Add rejected fixtures for volatile, atomic, unknown call, and ambiguous
      alias cases.
- [ ] Compare LLVM-equivalent fixtures with `opt-22`.

## Exit Criteria

- [ ] EarlyCSE uses dominator-scoped availability.
- [ ] Memory CSE is routed through shared legality APIs.
- [ ] Unsafe memory cases are rejected conservatively.
- [ ] LLVM-equivalent and local-only behavior are separated in fixtures.

