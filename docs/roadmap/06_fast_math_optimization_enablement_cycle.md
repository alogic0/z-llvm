# Cycle 06: Fast-Math Optimization Enablement

## Goal

Use parsed fast-math flags as optimization facts for a narrow, LLVM-shaped
subset of FP transforms.

## Plan

- [x] Map parsed fast-math flags to local legality predicates matching LLVM's
      flag meanings.
- [x] Enable selected folds only under the exact required flags.
- [x] Add fixtures for `nnan`, `ninf`, `nsz`, `reassoc`, `arcp`, `contract`,
      `afn`, and `fast` combinations that appear in Zig-emitted rows or
      reduced tests.
- [x] Reject or preserve transforms needing target-cost, contraction lowering,
      or exception modeling not yet implemented.
- [x] Share fast-math legality between InstSimplify, InstCombine, GVN, and
      EarlyCSE.
- [x] Document local differences from LLVM's full `FastMathFlags` users.
- [x] Compare equivalent fixtures with `opt-22`.

## Exit Criteria

- [x] At least one fast-math-only fold is implemented and compared.
- [x] Missing flags prevent the transform.
- [x] Target-cost-sensitive fast-math transforms remain deferred.

## Completed Slice

Cycle 06 adds `src/analysis/fast_math.zig` as the shared legality layer for the
accepted `FastMathFlags` spelling. The implemented transforms are:

- `fadd nsz x, +0.0 -> x`
- `fcmp nnan oeq x, x -> true`
- GVN and EarlyCSE admit repeated FP expressions only under `fast`

The remaining flags are parsed, verified, printed, and covered by fixtures, but
they do not trigger reassociation, reciprocal, contraction, approximate-function,
or target-cost-sensitive transforms yet.
