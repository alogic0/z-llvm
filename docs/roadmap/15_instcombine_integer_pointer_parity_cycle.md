# Cycle 15: InstCombine Integer and Pointer Parity

## Goal

Close high-value integer and pointer InstCombine gaps visible in Zig-emitted
ReleaseFast and ReleaseSmall rows.

## Plan

- [ ] Inventory missed integer, compare, select, cast, and GEP combines from
      current opt-22 diffs.
- [ ] Prioritize combines that reduce mandatory canonicalization gaps, not
      target-cost-sensitive strength reductions.
- [ ] Add poison, `nuw`, `nsw`, `exact`, and `inbounds` legality helpers before
      enabling each transform.
- [ ] Add fixtures for accepted and rejected overflow-sensitive combines.
- [ ] Share simplification predicates with InstSimplify when possible.
- [ ] Compare each enabled combine against `opt-22`.
- [ ] Update InstCombine docs with LLVM source references and local gaps.

## Exit Criteria

- [ ] Several high-frequency Zig integer or pointer combines match LLVM for
      listed fixtures.
- [ ] Overflow and poison-sensitive rejects are covered.
- [ ] No transform depends on unstated target cost.
