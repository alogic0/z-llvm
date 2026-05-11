# Cycle 07: FP Lattice and Value Numbering Legality

## Goal

Extend SCCP and value numbering to FP only where FP semantic equality is sound.

## Plan

- [x] Add FP constants to the SCCP lattice with explicit unknown, overdefined,
      undef, poison, and concrete states where already supported for integers.
- [x] Define equality and hashing for FP expression keys using semantic value
      and fast-math legality, not raw text alone.
- [x] Keep NaN, signed-zero, and strict exception-sensitive expressions out of
      CSE unless proven safe.
- [x] Add SCCP fixtures for constant FP branches and arithmetic.
- [x] Add GVN/EarlyCSE fixtures for accepted and rejected FP common
      expressions.
- [x] Compare accepted cases with `opt-22`; document deliberate conservative
      differences.
- [x] Update SCCP, GVN, EarlyCSE, and expression-key docs.

## Exit Criteria

- [x] FP SCCP handles at least constant-only arithmetic and comparisons.
- [x] FP CSE is legal under strict and fast-math rules.
- [x] Conservative non-CSE cases are tested.

## Completed Slice

Cycle 07 extends SCCP's lattice with FP constants and lets those constants flow
into already-legal InstSimplify-backed FP folds. The accepted SCCP fixture
covers `fadd nsz` with `+0.0` and a constant `fcmp ord` branch. Full APFloat
arithmetic remains deferred.

Expression keys now include fast-math flags for FP-capable instructions. GVN and
EarlyCSE continue to admit FP expressions only under the local `fast` boundary,
with explicit rejected non-fast fixtures.
