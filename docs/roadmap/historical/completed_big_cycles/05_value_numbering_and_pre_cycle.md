# Cycle 5: Value Numbering And PRE Foundation

## Goal

Make GVN and EarlyCSE share stronger value-numbering infrastructure, then add a
very narrow PRE foundation only where insertion points, dominance, and memory
legality are fully proven.

## Source Anchors

- LLVM: `llvm/lib/Transforms/Scalar/GVN.cpp`
- LLVM: `llvm/lib/Transforms/Scalar/NewGVN.cpp`
- LLVM: `llvm/lib/Transforms/Scalar/EarlyCSE.cpp`
- LLVM analyses: `DominatorTree`, `MemorySSA`, `AssumptionCache`,
  `TargetLibraryInfo`
- Local docs: `docs/passes/gvn.md`, `docs/passes/early_cse.md`,
  `docs/analysis/dominator.md`, `docs/analysis/target_library_info.md`
- Local code: `src/passes/gvn.zig`, `src/passes/early_cse.zig`,
  `src/passes/inst_simplify.zig`

## Plan

- [x] Extract shared expression-key construction for EarlyCSE and GVN.
- [x] Add stable hashing/equality for supported expression keys instead of
      linear scans where practical.
- [x] Include flags, predicates, types, operands, call attributes, and memory
      location facts in expression keys.
- [x] Keep load keys gated by the memory-dependence cycle's shared clobber
      helper.
- [x] Add readnone and readonly call fixtures only when parser and attribute
      support can represent the case honestly.
- [x] Add duplicate-PHI and phi-translation tests for supported exact cases.
- [x] Design a narrow PRE insertion rule for pure scalar expressions only:
      no critical-edge splitting unless a CFG helper exists, no memory PRE, no
      partial PHI translation beyond documented cases.
- [x] Add accepted/rejected fixtures for every PRE shape.
- [x] Compare LLVM-equivalent cases with `opt-22`.

## Exit Criteria

- [x] EarlyCSE and GVN use compatible expression identity rules.
- [x] GVN has documented dominance and insertion-point checks for any PRE it
      performs.
- [x] Memory value numbering remains conservative and tested.
- [x] `zig build test` and `bash scripts/compare_opt.sh` pass.

## Completed Shared Expression-Key Slice

- [x] Added `src/analysis/expression_key.zig` as the shared identity helper for
      EarlyCSE and GVN.
- [x] Centralized scalar expression, exact PHI, non-barrier must-alias load, and
      readnone direct-call equivalence rules.
- [x] Routed both `src/passes/early_cse.zig` and `src/passes/gvn.zig` through
      the shared helper while preserving MemorySSA-like clobber checks for load
      availability.
- [x] Documented the helper and its LLVM mapping in
      `docs/analysis/expression_key.md`.
- [x] Verified with `zig build test` and `bash scripts/compare_opt.sh`.

## PRE Boundary

- [x] PRE remains a documented no-op for now. The accepted local rule is:
      insert only pure scalar expressions when all predecessor insertion blocks
      already exist, no critical edge must be split, all inserted operands
      dominate the insertion point, and the merge rewrite can be represented
      with an exact PHI.
- [x] No current local CFG shape satisfies that full rule with enough
      infrastructure to beat LLVM safely, so GVN performs no PRE insertion in
      this cycle.
- [x] Memory PRE is explicitly rejected; load value numbering remains limited
      to dominating available loads gated by the shared clobber helper.
- [x] Existing accepted fixtures cover dominating scalar GVN, exact duplicate
      PHIs, memory clobber rejection, and EarlyCSE memory rejection. Readnone
      call value numbering remains unit-test/local-only until attribute-group
      parsing is broad enough for an opt-22 fixture.

## Future Backlog Handoff

- [x] Add deterministic hash prefilters for supported non-memory expression
      keys.
- [x] Move full scoped hash buckets to
      `docs/roadmap/future_optimizer_backlog.md` because that work depends on
      richer alias-sensitive expression keys beyond this completed cycle.
