# Cycle 1: ADCE Control-Flow Parity

## Goal

Rework local ADCE from scalar dead-instruction cleanup toward LLVM-style
aggressive dead code elimination for the supported IR surface.

## Source Anchors

- LLVM: `llvm/lib/Transforms/Scalar/ADCE.cpp`
- LLVM analyses: `PostDominators`, control dependence, CFG updates
- Local docs: `docs/passes/adce.md`, `docs/analysis/cfg.md`,
  `docs/analysis/dominator.md`
- Backlog source:
  `docs/roadmap/llvm_algorithm_parity_gap_closure_plan.md`

## Plan

- [x] Add or document the LLVM ADCE algorithm contract.
- [x] Add a minimal PostDominatorTree or postdom query for accepted CFGs.
- [x] Add control-dependence queries needed by ADCE.
- [x] Rework ADCE liveness around an optimistic worklist.
- [x] Mark live terminators required by control dependence.
- [x] Remove dead regions when CFG updates are locally safe.
- [x] Keep unsupported CFG rewrites explicit and tested as rejected cases.
- [x] Add fixtures where LLVM removes dead branches or regions, not only dead
      scalar instructions.
- [x] Compare LLVM-equivalent fixtures with `opt-22`.

## Exit Criteria

- [x] ADCE has a documented LLVM source mapping.
- [x] ADCE can delete covered dead control-flow regions safely.
- [x] Postdom/control-dependence limitations are documented.
- [x] Fixtures separate LLVM-equivalent behavior from conservative local gaps.
