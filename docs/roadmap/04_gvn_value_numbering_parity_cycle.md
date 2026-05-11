# Cycle 4: GVN Value Numbering Parity

## Goal

Move GVN toward LLVM's value numbering model for supported expressions, PHIs,
casts, calls, and memory-safe loads.

## Source Anchors

- LLVM: `llvm/lib/Transforms/Scalar/GVN.cpp`
- LLVM support: value tables, leader tables, load availability, PRE
- Local docs: `docs/passes/gvn.md`, `docs/analysis/alias.md`,
  `docs/analysis/memory_location.md`
- Backlog source:
  `docs/roadmap/llvm_algorithm_parity_gap_closure_plan.md`

## Plan

- [x] Add or document the LLVM GVN algorithm contract.
- [x] Add a ValueTable for supported expression forms.
- [x] Add leader tables scoped by dominance.
- [x] Number expressions, PHIs, casts, calls, and loads for accepted IR.
- [x] Add load availability using conservative MemoryDependence or
      MemorySSA-like checks.
- [x] Add duplicate-PHI elimination as a separate safe slice.
- [x] Add conservative PRE only after dominance and insertion-point rules are
      explicit.
- [x] Add fixtures where LLVM eliminates redundant expressions and loads.
- [x] Compare LLVM-equivalent fixtures with `opt-22`.

## Exit Criteria

- [x] GVN has a real local value numbering model.
- [x] Memory-dependent GVN is legality-gated.
- [x] PRE is either implemented narrowly or explicitly deferred.
- [x] Fixture docs explain unsupported LLVM behavior.
