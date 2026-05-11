# Cycle 07: FP Lattice and Value Numbering Legality

## Goal

Extend SCCP and value numbering to FP only where FP semantic equality is sound.

## Plan

- [ ] Add FP constants to the SCCP lattice with explicit unknown, overdefined,
      undef, poison, and concrete states where already supported for integers.
- [ ] Define equality and hashing for FP expression keys using semantic value
      and fast-math legality, not raw text alone.
- [ ] Keep NaN, signed-zero, and strict exception-sensitive expressions out of
      CSE unless proven safe.
- [ ] Add SCCP fixtures for constant FP branches and arithmetic.
- [ ] Add GVN/EarlyCSE fixtures for accepted and rejected FP common
      expressions.
- [ ] Compare accepted cases with `opt-22`; document deliberate conservative
      differences.
- [ ] Update SCCP, GVN, EarlyCSE, and expression-key docs.

## Exit Criteria

- [ ] FP SCCP handles at least constant-only arithmetic and comparisons.
- [ ] FP CSE is legal under strict and fast-math rules.
- [ ] Conservative non-CSE cases are tested.
