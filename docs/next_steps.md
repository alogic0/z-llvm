# Next Steps

- [x] Add LLVM IR normalization and golden-output comparison.
- [x] Expand the parser to support multiple functions and basic branches.
- [x] Implement `simplifycfg` for trivial branch and unreachable-block cleanup.
- [ ] Add `opt` comparison fixtures for `instcombine`, `dce`, and `simplifycfg`.
- [ ] Add def-use maintenance instead of recomputing usage ad hoc.
- [ ] Document unsupported LLVM IR constructs and parser errors.

## Reproduced LLVM Algorithms

Track each reproduced LLVM algorithm here as it lands:

- `instcombine` subset: documented in [passes/instcombine.md](passes/instcombine.md).
- `dce` subset: documented in [passes/dce.md](passes/dce.md).
- `simplifycfg` subset: documented in [passes/simplifycfg.md](passes/simplifycfg.md).

## Completed Step Notes

- LLVM IR normalization and golden-output comparison is infrastructure, not an optimization pass. It is now used to check the implemented `instcombine` and `dce` subsets against normalized expected LLVM-compatible IR.
- Parser support for multiple functions plus `br` and conditional `br` is infrastructure for reproducing LLVM's `simplifycfg` algorithm.
- `simplifycfg` now folds constant conditional branches and removes blocks unreachable from function entry.
