# Cycle 2: SCCP Sparse Lattice Parity

## Goal

Move SCCP toward LLVM's sparse conditional constant propagation model for the
supported scalar and CFG surface.

## Source Anchors

- LLVM: `llvm/lib/Transforms/Scalar/SCCP.cpp`
- LLVM IPO variant: `llvm/lib/Transforms/IPO/SCCP.cpp`
- Local docs: `docs/passes/sccp.md`, `docs/analysis/cfg.md`
- Backlog source:
  `docs/roadmap/llvm_algorithm_parity_gap_closure_plan.md`

## Plan

- [x] Add or document the LLVM SCCP algorithm contract.
- [x] Implement lattice states:
      unknown, undef, constant, and overdefined.
- [x] Track executable blocks and executable edges.
- [x] Add sparse instruction visitor structure for supported instructions.
- [x] Fold branches when the condition lattice proves a taken edge.
- [x] Fold unreachable blocks and unreachable PHI incoming values.
- [x] Add an undef-resolution loop for covered cases.
- [x] Keep IPSCCP deferred until call graph and interprocedural summaries are
      strong enough.
- [x] Compare LLVM-equivalent fixtures with `opt-22`.

## Exit Criteria

- [x] SCCP behavior is driven by a documented sparse lattice.
- [x] Branch and PHI behavior matches LLVM for listed fixtures.
- [x] IPSCCP remains explicitly deferred with prerequisites.
- [x] Conservative gaps are documented.
