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

- [ ] Add or document the LLVM SCCP algorithm contract.
- [ ] Implement lattice states:
      unknown, undef, constant, and overdefined.
- [ ] Track executable blocks and executable edges.
- [ ] Add sparse instruction visitor structure for supported instructions.
- [ ] Fold branches when the condition lattice proves a taken edge.
- [ ] Fold unreachable blocks and unreachable PHI incoming values.
- [ ] Add an undef-resolution loop for covered cases.
- [ ] Keep IPSCCP deferred until call graph and interprocedural summaries are
      strong enough.
- [ ] Compare LLVM-equivalent fixtures with `opt-22`.

## Exit Criteria

- [ ] SCCP behavior is driven by a documented sparse lattice.
- [ ] Branch and PHI behavior matches LLVM for listed fixtures.
- [ ] IPSCCP remains explicitly deferred with prerequisites.
- [ ] Conservative gaps are documented.

