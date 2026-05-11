# Cycle 13: ADCE Control-Dependence Parity

## Goal

Make ADCE reason about control dependence and observable behavior more like
LLVM for the supported CFG surface.

## Plan

- [x] Document LLVM ADCE roots, post-dominator usage, and control-dependence
      rules.
- [x] Ensure terminators needed for live side effects are retained through
      post-dominator reasoning.
- [x] Add branch-to-branch simplification only when it preserves required
      control dependence.
- [x] Add fixtures for live calls, stores, unreachable blocks, infinite loops,
      debug-bearing instructions, and branches guarding side effects.
- [x] Share side-effect classification with DCE, GVN, EarlyCSE, and LICM.
- [x] Compare equivalent ADCE fixtures with `opt-22`.
- [x] Update ADCE, postdominator, and memory-effect docs.

## Exit Criteria

- [x] ADCE deletes one non-trivial dead control region.
- [x] ADCE preserves branches required for observable side effects.
- [x] Infinite-loop and debug-bearing boundaries are documented.

## Completed Slice

Cycle 13 extends ADCE control-dependence coverage with side-effecting call and
infinite-loop rejection fixtures. The local pass continues to rewrite only
acyclic, side-effect-free dead control regions that reconverge at an immediate
postdominator.
