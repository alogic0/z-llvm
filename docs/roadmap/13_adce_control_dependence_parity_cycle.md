# Cycle 13: ADCE Control-Dependence Parity

## Goal

Make ADCE reason about control dependence and observable behavior more like
LLVM for the supported CFG surface.

## Plan

- [ ] Document LLVM ADCE roots, post-dominator usage, and control-dependence
      rules.
- [ ] Ensure terminators needed for live side effects are retained through
      post-dominator reasoning.
- [ ] Add branch-to-branch simplification only when it preserves required
      control dependence.
- [ ] Add fixtures for live calls, stores, unreachable blocks, infinite loops,
      debug-bearing instructions, and branches guarding side effects.
- [ ] Share side-effect classification with DCE, GVN, EarlyCSE, and LICM.
- [ ] Compare equivalent ADCE fixtures with `opt-22`.
- [ ] Update ADCE, postdominator, and memory-effect docs.

## Exit Criteria

- [ ] ADCE deletes one non-trivial dead control region.
- [ ] ADCE preserves branches required for observable side effects.
- [ ] Infinite-loop and debug-bearing boundaries are documented.
