# Cycle 15: InstCombine Integer and Pointer Parity

## Goal

Close high-value integer and pointer InstCombine gaps visible in Zig-emitted
ReleaseFast and ReleaseSmall rows.

## Plan

- [x] Inventory missed integer, compare, select, cast, and GEP combines from
      current opt-22 diffs.
- [x] Prioritize combines that reduce mandatory canonicalization gaps, not
      target-cost-sensitive strength reductions.
- [x] Add poison, `nuw`, `nsw`, `exact`, and `inbounds` legality helpers before
      enabling each transform.
- [x] Add fixtures for accepted and rejected overflow-sensitive combines.
- [x] Share simplification predicates with InstSimplify when possible.
- [x] Compare each enabled combine against `opt-22`.
- [x] Update InstCombine docs with LLVM source references and local gaps.

## Exit Criteria

- [x] Several high-frequency Zig integer or pointer combines match LLVM for
      listed fixtures.
- [x] Overflow and poison-sensitive rejects are covered.
- [x] No transform depends on unstated target cost.

## Completed Slice

Cycle 15 adds checked InstSimplify legality for flagged integer neutral
identities and constant add/sub/mul folds. It also adds a pointer null/self
comparison fixture through the shared ICmp simplifier. Overflow-sensitive
flagged constants remain local-conservative because the local IR does not yet
materialize LLVM poison.
