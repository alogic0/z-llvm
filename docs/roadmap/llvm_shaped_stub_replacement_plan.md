# LLVM-Shaped Stub Replacement Plan

This plan turns the current placeholder and local-conservative optimizer
surface into bounded LLVM-shaped implementation slices. It is not a single
milestone. Pull one slice at a time into `docs/next_steps.md`, implement it,
compare with LLVM where possible, document the upstream mapping, then commit.

## Slice Completion Rules

Each slice is complete only when it has:

- [ ] LLVM source file and entry-point mapping.
- [ ] Accepted local IR preconditions.
- [ ] Implementation that follows the LLVM-shaped algorithm for that surface.
- [ ] `opt-22` fixture comparison, or a documented reason LLVM comparison is
      not applicable.
- [ ] Updated pass or analysis docs with missing behavior.
- [ ] No completed placeholder behavior. If infrastructure is missing, the
      slice must say which LLVM algorithm is still blocked and why.

## Phase 1: Mandatory Scalar Pipeline Stubs

- [x] Slice 1: `always-inline` for direct internal calls.
      Reproduce the narrow `AlwaysInliner` behavior for functions marked
      always-inline, direct calls only, no recursion, no varargs, no exceptional
      control flow. Required upstream mapping:
      `llvm/lib/Transforms/IPO/AlwaysInliner.cpp` and LLVM call graph update
      behavior.
- [ ] Slice 2: `jump-threading` for constant predecessor conditions.
      Implement LLVM-shaped predecessor threading for blocks whose branch
      condition is known along a predecessor edge. Keep PHI repair modeled
      after LLVM CFG update helpers. Required upstream mapping:
      `llvm/lib/Transforms/Scalar/JumpThreading.cpp`.
- [ ] Slice 3: `correlated-propagation` for branch-implied integer facts.
      Add a small LazyValueInfo-shaped fact table for `icmp` facts coming from
      dominating branches. Required upstream mapping:
      `llvm/lib/Transforms/Scalar/CorrelatedValuePropagation.cpp` and
      `llvm/lib/Analysis/LazyValueInfo.cpp`.
- [ ] Slice 4: `lower-expect` and branch-weight metadata preservation.
      Lower simple `llvm.expect` integer forms into branch-weight metadata or
      preserve them with an explicit unsupported diagnostic when metadata
      support is insufficient. Required upstream mapping:
      `llvm/lib/Transforms/Scalar/LowerExpectIntrinsic.cpp`.

## Phase 2: MemorySSA And Alias Parity

- [ ] Slice 5: MemorySSA walker API for clobber queries.
      Replace local block-range scans with a walker-shaped query over MemoryUse,
      MemoryDef, and MemoryPhi records. Required upstream mapping:
      `llvm/lib/Analysis/MemorySSA.cpp` and `MemorySSAUpdater`.
- [ ] Slice 6: EarlyCSE load availability through MemorySSA.
      Rework load CSE to use the new walker instead of ad hoc clobber scans.
      Required upstream mapping: `llvm/lib/Transforms/Scalar/EarlyCSE.cpp`.
- [ ] Slice 7: GVN load availability and simple load PRE.
      Implement one LLVM-shaped load PRE slice for a diamond where all required
      values are available or safely insertable. Required upstream mapping:
      `llvm/lib/Transforms/Scalar/GVN.cpp`.
- [ ] Slice 8: DSE overwrite lattice for partial stores.
      Replace reject-only partial overwrite behavior with a byte-interval
      lattice for selected integer stores. Required upstream mapping:
      `llvm/lib/Transforms/Scalar/DeadStoreElimination.cpp`.
- [ ] Slice 9: Function call ModRef expansion.
      Model readonly, readnone, argmemonly, inaccessiblememonly, and direct
      call effects in the local alias/ModRef layer. Required upstream mapping:
      `llvm/lib/Analysis/BasicAliasAnalysis.cpp` and LLVM `ModRefInfo`.

## Phase 3: Loop Pipeline Placeholders

- [ ] Slice 10: `loop-simplifycfg` for loop-local dead branches.
      Implement CFG cleanup that preserves loop canonical structure and updates
      LoopInfo/LCSSA. Required upstream mapping:
      `llvm/lib/Transforms/Scalar/LoopSimplifyCFG.cpp`.
- [ ] Slice 11: `loop-rotate` for single-latch counted loops.
      Reproduce the smallest LLVM loop-rotation shape with preheader, header,
      latch, and dedicated exits. Required upstream mapping:
      `llvm/lib/Transforms/Scalar/LoopRotation.cpp`.
- [ ] Slice 12: `loop-deletion` for provably side-effect-free finite loops.
      Use ScalarEvolution-shaped trip-count facts only for simple counted loops.
      Required upstream mapping:
      `llvm/lib/Transforms/Scalar/LoopDeletion.cpp`.
- [ ] Slice 13: `indvars` canonical IV recognition and rewrite.
      Introduce a small SCEV-like representation and rewrite one affine IV
      pattern. Required upstream mapping:
      `llvm/lib/Transforms/Scalar/IndVarSimplify.cpp` and
      `llvm/lib/Analysis/ScalarEvolution.cpp`.
- [ ] Slice 14: LICM memory promotion.
      Move beyond load hoisting into scalar promotion for one stack slot with no
      aliasing writes, preserving LCSSA. Required upstream mapping:
      `llvm/lib/Transforms/Scalar/LICM.cpp`.

## Phase 4: SROA, InstCombine, And FP Parity

- [ ] Slice 15: SROA slice partition builder.
      Replace one-off aggregate forwarding with an LLVM-shaped slice graph for
      fixed-size structs and arrays. Required upstream mapping:
      `llvm/lib/Transforms/Scalar/SROA.cpp`.
- [ ] Slice 16: SROA rewrite for debug-free aggregate allocas.
      Rewrite alloca users through partitioned scalar allocas, then run mem2reg.
      Keep debug salvage as an explicit blocker. Required upstream mapping:
      `llvm/lib/Transforms/Scalar/SROA.cpp`.
- [ ] Slice 17: InstCombine overflow-flag legality.
      Preserve and drop `nsw`, `nuw`, and exact flags according to LLVM's
      legality checks for selected integer folds. Required upstream mapping:
      `llvm/lib/Transforms/InstCombine/`.
- [ ] Slice 18: APFloat-backed strict FP folds.
      Replace conservative FP pass-through with APFloat-equivalent constant
      folding for selected `fadd`, `fmul`, and `fcmp` cases. Required upstream
      mapping: `llvm/lib/Analysis/InstructionSimplify.cpp` and APFloat users.
- [ ] Slice 19: Fast-math CSE legality.
      Allow EarlyCSE/GVN only when fast-math flags make the expression
      equivalence LLVM-compatible. Required upstream mapping:
      `EarlyCSE.cpp`, `GVN.cpp`, and LLVM fast-math flag handling.

## Phase 5: IPO And Global Optimization

- [ ] Slice 20: `globalopt` for internal constant globals.
      Implement one GlobalOpt rewrite for internal immutable globals with all
      constant uses. Required upstream mapping:
      `llvm/lib/Transforms/IPO/GlobalOpt.cpp`.
- [ ] Slice 21: `constmerge` for identical private constants.
      Merge identical private constants while preserving linkage and COMDAT
      constraints. Required upstream mapping:
      `llvm/lib/Transforms/IPO/ConstantMerge.cpp`.
- [ ] Slice 22: `function-attrs` direct-call inference.
      Infer readonly/readnone/norecurse for local direct-call SCCs. Required
      upstream mapping: `llvm/lib/Transforms/IPO/FunctionAttrs.cpp`.
- [ ] Slice 23: `inline` for one direct internal call shape.
      Build on `always-inline`, but add basic cost gating and call-site
      attribute preservation. Required upstream mapping:
      `llvm/lib/Transforms/IPO/Inliner.cpp`.

## Phase 6: Vector, Target Cost, And Size/PGO Boundaries

- [ ] Slice 24: TargetTransformInfo skeleton.
      Add target-cost query objects for x86_64 and AArch64 scalar/vector costs.
      Required upstream mapping: LLVM `TargetTransformInfo`.
- [ ] Slice 25: `vector-combine` for extract/insert lane identity.
      Replace the current mismatch reject fixture with one LLVM-shaped vector
      combine. Required upstream mapping:
      `llvm/lib/Transforms/Vectorize/VectorCombine.cpp`.
- [ ] Slice 26: SLP vectorizer recognition-only pass.
      Detect one straight-line isomorphic operation group and emit an explicit
      unsupported diagnostic before transformation. This is a planning slice,
      not a completed algorithm. Required upstream mapping:
      `llvm/lib/Transforms/Vectorize/SLPVectorizer.cpp`.
- [ ] Slice 27: PGO/profile metadata propagation for SimplifyCFG.
      Preserve or update branch weights for one CFG rewrite. Required upstream
      mapping: `SimplifyCFG.cpp` profile metadata update paths.

## Phase 7: Debug, Atomics, LTO, And Backend-Adjacent Boundaries

- [ ] Slice 28: Debug location salvage for InstCombine.
      Salvage one replaced value's debug location instead of dropping it.
      Required upstream mapping: LLVM debug value salvage utilities.
- [ ] Slice 29: Atomic ordering semantic verifier.
      Move from atomic-as-barrier only to LLVM-compatible validation of ordering
      and syncscope combinations. Required upstream mapping:
      `llvm/lib/IR/Verifier.cpp`.
- [ ] Slice 30: Inline asm memory effect refinement.
      Classify side effects from inline asm constraints and sideeffect markers.
      Required upstream mapping: LLVM inline asm memory effect handling.
- [ ] Slice 31: LTO prelink alias canonicalization.
      Replace `canonicalize-aliases` placeholder for one alias-to-global shape.
      Required upstream mapping:
      `llvm/lib/Transforms/Utils/CanonicalizeAliases.cpp`.
- [ ] Slice 32: Backend handoff validation for one optimized pattern.
      Take one completed optimizer pattern through local Machine IR/object smoke
      validation and compare to LLVM/assembler behavior where practical.

## Suggested First Pull

Start with Slice 1, `always-inline`, because it is P0 in the Zig pipeline
inventory and unlocks later direct-call IPO work. If call cloning exposes too
much IR surface at once, split it into:

- [x] function body cloning without PHIs;
- [x] argument substitution and return replacement;
- [x] PHI and multiple-return rejection through documented unsupported local
      IR preconditions;
- [x] debug/location preservation policy documented as missing behavior.
