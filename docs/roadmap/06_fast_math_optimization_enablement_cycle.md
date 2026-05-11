# Cycle 06: Fast-Math Optimization Enablement

## Goal

Use parsed fast-math flags as optimization facts for a narrow, LLVM-shaped
subset of FP transforms.

## Plan

- [ ] Map parsed fast-math flags to local legality predicates matching LLVM's
      flag meanings.
- [ ] Enable selected folds only under the exact required flags.
- [ ] Add fixtures for `nnan`, `ninf`, `nsz`, `reassoc`, `arcp`, `contract`,
      `afn`, and `fast` combinations that appear in Zig-emitted rows or
      reduced tests.
- [ ] Reject or preserve transforms needing target-cost, contraction lowering,
      or exception modeling not yet implemented.
- [ ] Share fast-math legality between InstSimplify, InstCombine, GVN, and
      EarlyCSE.
- [ ] Document local differences from LLVM's full `FastMathFlags` users.
- [ ] Compare equivalent fixtures with `opt-22`.

## Exit Criteria

- [ ] At least one fast-math-only fold is implemented and compared.
- [ ] Missing flags prevent the transform.
- [ ] Target-cost-sensitive fast-math transforms remain deferred.
