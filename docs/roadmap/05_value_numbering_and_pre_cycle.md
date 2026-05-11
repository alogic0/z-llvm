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

- [ ] Extract shared expression-key construction for EarlyCSE and GVN.
- [ ] Add stable hashing/equality for supported expression keys instead of
      linear scans where practical.
- [ ] Include flags, predicates, types, operands, call attributes, and memory
      location facts in expression keys.
- [ ] Keep load keys gated by the memory-dependence cycle's shared clobber
      helper.
- [ ] Add readnone and readonly call fixtures only when parser and attribute
      support can represent the case honestly.
- [ ] Add duplicate-PHI and phi-translation tests for supported exact cases.
- [ ] Design a narrow PRE insertion rule for pure scalar expressions only:
      no critical-edge splitting unless a CFG helper exists, no memory PRE, no
      partial PHI translation beyond documented cases.
- [ ] Add accepted/rejected fixtures for every PRE shape.
- [ ] Compare LLVM-equivalent cases with `opt-22`.

## Exit Criteria

- [ ] EarlyCSE and GVN use compatible expression identity rules.
- [ ] GVN has documented dominance and insertion-point checks for any PRE it
      performs.
- [ ] Memory value numbering remains conservative and tested.
- [ ] `zig build test` and `bash scripts/compare_opt.sh` pass.

