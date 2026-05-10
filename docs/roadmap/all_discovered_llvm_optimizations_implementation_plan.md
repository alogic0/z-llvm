# Zig LLVM Pipeline Optimization Implementation Plan

Goal: implement the LLVM optimization behavior discovered in
`docs/inventory/zig_llvm_pass_pipeline_inventory.md` in dependency order, while
keeping every slice tied to Zig's actual LLVM pipeline use.

This is not a promise to implement LLVM all at once. It is a staged plan for
covering the discovered optimizer surface honestly.

## Ground Rules

- [ ] Start every implementation slice from
      `docs/inventory/zig_llvm_pass_pipeline_inventory.md`.
- [ ] For every pass, document the local target status using exactly one of:
      `LLVM-equivalent for listed fixtures`, `LLVM-shaped algorithm subset`,
      `local conservative substitute`, or `placeholder`.
- [ ] Prefer behavior required for Zig-emitted IR over generic LLVM feature
      breadth.
- [ ] Add or update upstream source mapping before marking a slice complete.
- [ ] Compare with `opt-22` when expected behavior is
      `LLVM-equivalent for listed fixtures`.
- [ ] Add local-only fixtures when this project intentionally rejects behavior
      LLVM supports.
- [ ] Keep optimizer work independent from codegen/MC/object work unless an
      end-to-end fixture is explicitly part of the slice.
- [ ] Do not promote performance-quality passes before the required IR surface,
      verifier rules, and analyses exist.
- [ ] Do not implement a pass before documenting the exact LLVM algorithm and
      data structures being reproduced.
- [ ] Document analysis preservation/invalidation for every pass that mutates
      IR.

## Required LLVM Algorithm Contract

Every implementation slice must add or update the pass/analysis doc with this
contract before code is marked complete:

```text
LLVM source files:
LLVM entry points/classes:
Required analyses:
Required IR invariants:
Core LLVM algorithm data structures:
Local target status:
Implemented subset:
Intentional divergences:
Analysis preservation/invalidation:
Fixture coverage:
opt-22 comparison command:
Local-only fixture command:
```

Examples of algorithm data structures that must be named before implementation:

```text
mem2reg:
  entry-block alloca discovery, promotability checks, dominance frontiers,
  rename stacks

SROA:
  alloca slices, partitions, rewrite decisions, DataLayout offsets

GVN:
  value numbering, leader tables, dominance, memory dependence or MemorySSA

ADCE:
  postdominators, control dependence, optimistic liveness worklist

LICM:
  LoopInfo, DominatorTree, AliasAnalysis, MemorySSA/mod-ref, speculation safety
```

## Semantic Prerequisites

These semantics must be documented and tested before broadening transforms that
depend on them:

- [x] Poison, `undef`, and `freeze` behavior for accepted scalar transforms.
- [ ] Integer overflow flags: `nsw`, `nuw`, `exact`, and when folds must refuse
      to move or drop them.
- [ ] DataLayout-backed type sizes and offsets for stack, GEP, and SROA work.
- [ ] Target-independent versus target-aware folds.
- [ ] Volatile, atomic, call, and unknown-memory barriers.
- [x] SSA dominance, phi incoming predecessor validity, and use-before-def
      checks.

## Required Comparison Recipe

Every LLVM-equivalent fixture must record the exact comparison recipe:

```sh
opt-22 -passes='<llvm-pass-pipeline>' input.ll -S -o /tmp/llvm.ll
zig build run -- --passes=<local-pass-or-pipeline> input.ll > /tmp/z.ll
# normalize both if needed, then diff
diff -u /tmp/llvm.ll /tmp/z.ll
```

Every intentional divergence must have a local-only fixture plus an upstream
behavior note explaining what LLVM does that this project does not yet model.

## Epic 1: Mandatory IR Validity And Pipeline Infrastructure

Goal: make the local IR and pass manager strong enough to run LLVM-like
pipelines without silently accepting invalid inputs.

- [x] Add algorithm contracts for the verifier and pass-manager plumbing before
      expanding implementation.
- [x] Document LLVM verifier source mapping:
      `llvm/lib/IR/Verifier.cpp`, `VerifierPass`, and the IR invariants it
      enforces for the locally accepted IR subset.
- [x] Expand verifier coverage for all IR currently accepted by the parser.
- [x] Add verifier checks needed by known P0 passes:
      dominance for SSA values, phi incoming validity, terminator shape,
      function declaration/reference validity, call signature checks, and
      memory instruction legality.
- [x] Add analysis preservation/invalidation policy for local pass-manager
      nesting and placeholders.
- [x] Add pass pipeline categories matching the inventory:
      mandatory, canonicalization, scalar, memory, loop, IPO, vector,
      instrumentation, LTO.
- [x] Add a local pipeline descriptor for Zig modes:
      `debug-o0`, `release-o3`, `release-oz`, `lto-prelink-o3`,
      `lto-prelink-oz`.
- [x] Keep unsupported passes as explicit pipeline placeholders with targeted
      diagnostics or documented no-op behavior.
- [x] Add pass-limit/trace output that can show the expanded local pipeline.
- [x] Add fixture metadata tying every optimizer fixture to the inventory pass
      it covers.

Passes covered:

- [x] `verify`
- [x] analysis plumbing: `require<...>`, `invalidate<...>` placeholders
- [x] pass-manager nesting placeholders for module/function/loop/CGSCC groups

## Epic 2: P0 Scalar Canonicalization Foundation

Goal: make small Zig-emitted scalar IR canonical in the same broad shape LLVM
expects before deeper optimizations.

- [x] Add algorithm contracts for InstSimplify and InstCombine before expanding
      either pass.
- [x] Document LLVM source mapping:
      `llvm/lib/Analysis/InstructionSimplify.cpp`,
      `llvm/lib/Transforms/InstCombine/`, and
      `llvm/lib/Transforms/AggressiveInstCombine/`.
- [x] Expand InstSimplify for integer identities, comparisons, casts, select,
      freeze/undef-safe cases, and branch conditions currently accepted by IR.
- [x] Expand InstCombine for arithmetic, bitwise, comparisons, casts, select,
      div/rem conservative folds, and canonical operand ordering.
- [x] Add poison/undef/freeze documentation for every transform that depends on
      it; reject or preserve when semantics are not modeled.
- [x] Add fixed-point behavior where LLVM repeatedly runs InstCombine and
      SimplifyCFG in the selected pipelines.
- [x] Add `aggressive-instcombine` as a documented placeholder first; only
      promote concrete transforms after InstCombine coverage is stable.
- [x] Add mode-sensitive fixtures where `O0`, `O3`, and `Oz` differ.

Passes covered:

- [x] `instsimplify`
- [x] `instcombine`
- [x] `aggressive-instcombine` placeholder
- [x] `lower-constant-intrinsics` narrow subset if intrinsics enter IR
- [x] `drop-unnecessary-assumes` placeholder until `assume` exists

## Epic 3: P0 CFG Canonicalization Foundation

Goal: reproduce the CFG cleanups that make later scalar, memory, and loop
passes tractable.

- [x] Add a SimplifyCFG algorithm contract before expanding the pass.
- [x] Document LLVM source mapping:
      `llvm/lib/Transforms/Scalar/SimplifyCFGPass.cpp`,
      `llvm/lib/Transforms/Utils/SimplifyCFG.cpp`, and the helper routines used
      by the selected fixture class.
- [x] Expand SimplifyCFG beyond empty block threading:
      unreachable removal, branch-on-constant folding, trivial phi cleanup,
      merge block with single predecessor, merge return blocks where safe.
- [x] Add switch placeholders or explicit unsupported diagnostics.
- [x] Add CFG update rules so analyses are invalidated or rebuilt correctly.
- [x] Add control-flow fixtures from Zig-emitted IR shapes:
      if/else, early return, loop preheader/latch skeletons, unreachable panic
      paths.
- [x] Compare LLVM-equivalent accepted cases with `opt-22`.
- [x] Document all cases where LLVM speculates, sinks, hoists, or rewrites more
      aggressively than the local subset.

Passes covered:

- [x] `simplifycfg`
- [x] `jump-threading` placeholder
- [x] `correlated-propagation` placeholder
- [x] CFG side of `tailcallelim` placeholder

## Epic 4: Stack Promotion And Scalar Replacement

Goal: cover the stack-to-SSA transformations Zig depends on before memory-heavy
optimizations.

- [x] Add algorithm contracts for mem2reg and SROA before broadening either
      implementation.
- [x] Document LLVM source mapping:
      `llvm/lib/Transforms/Utils/Mem2Reg.cpp`,
      `llvm/lib/Transforms/Utils/PromoteMemoryToRegister.cpp`, and
      `llvm/lib/Transforms/Scalar/SROA.cpp`.
- [x] Expand mem2reg for all Zig-emitted scalar alloca patterns that are safe
      under the current IR model.
- [x] Keep LLVM's entry-block alloca discovery rule.
- [x] Preserve volatile rejection and document the local atomic policy.
- [x] Expand SROA from zero-offset GEP forwarding to known-offset scalar slices
      only when DataLayout can prove size/offset facts.
- [x] Add lifetime intrinsic placeholders or explicit unsupported handling.
- [x] Add fixtures for multiple slots, nested simple GEPs, known disjoint
      stack offsets, and rejected aggregate/vector/unknown-layout cases.
- [x] Add debug-info salvage placeholders but keep debug metadata out of scope
      until the debug-info epic.

Passes covered:

- [x] `mem2reg`
- [x] `sroa`
- [x] stack-relevant parts of `instcombine`
- [x] stack-relevant parts of `simplifycfg`

## Epic 5: Alias, Memory Effects, And DSE Foundation

Goal: provide the shared legality layer needed by DSE, GVN, LICM, memcpyopt,
and later MemorySSA-like behavior.

- [x] Add algorithm contracts for MemoryLocation, AliasAnalysis, ModRef, DSE,
      and the planned MemorySSA-like subset.
- [x] Document LLVM source mapping:
      `llvm/include/llvm/Analysis/MemoryLocation.h`,
      `llvm/include/llvm/Analysis/AliasAnalysis.h`,
      `llvm/lib/Transforms/Scalar/DeadStoreElimination.cpp`, and
      `llvm/lib/Analysis/MemorySSA.cpp`.
- [x] Expand `MemoryLocation` to cover known scalar stack offsets and sizes
      with DataLayout-backed size queries.
- [x] Expand alias analysis for direct stack slots, simple GEP-derived stack
      slots, known disjoint offsets, and conservative unknowns.
- [x] Add mod/ref queries for loads, stores, calls, volatile, atomic, and
      unknown barriers.
- [x] Implement DSE for overwritten stack stores with no intervening read or
      barrier.
- [x] Add local-only conservative fixtures for calls, volatile, atomic,
      unknown pointer, partial overlap, and unsupported aggregate layout.
- [x] Add a MemorySSA design note before implementing MemorySSA-like state.
- [x] Do not add general memory motion until alias/mod-ref proves it safe.

Passes covered:

- [x] `dse`
- [x] `memcpyopt` placeholder
- [x] `mldst-motion` placeholder
- [x] `infer-alignment` narrow subset
- [x] `alignment-from-assumptions` placeholder
- [x] `move-auto-init` placeholder

## Epic 6: EarlyCSE, GVN, SCCP, And Dead-Code Quality

Goal: improve scalar optimization quality after canonicalization and memory
legality foundations are strong enough.

- [x] Add algorithm contracts for EarlyCSE, GVN, SCCP, ADCE, and BDCE before
      broadening their implementations.
- [x] Document LLVM source mapping:
      `llvm/lib/Transforms/Scalar/EarlyCSE.cpp`,
      `llvm/lib/Transforms/Scalar/GVN.cpp`,
      `llvm/lib/Transforms/Scalar/SCCP.cpp`,
      `llvm/lib/Transforms/Scalar/ADCE.cpp`, and
      `llvm/lib/Transforms/Scalar/BDCE.cpp`.
- [ ] Expand EarlyCSE to use scoped value tables over dominator traversal.
- [ ] Add load CSE only for memory facts proven by alias/mod-ref.
- [ ] Expand GVN beyond simple expression domination:
      value numbering for compares, casts, select, simple loads, and phi-aware
      cases where dominance is clear.
- [x] Implement SCCP for constants through branches and phi nodes.
- [ ] Add SCCP support for simple calls only when call semantics are known.
- [ ] Upgrade ADCE from foundation DCE to true control-dependence-aware ADCE
      only after postdominator/control-dependence analysis exists.
- [x] Add BDCE as an explicit placeholder until bit-level known-bits or
      demanded-bits analysis exists.
- [x] Keep `speculative-execution` as an explicit placeholder until
      speculation safety, target cost, and side-effect rules are represented.
- [x] Keep all memory-ambiguous cases conservative.

Passes covered:

- [x] `early-cse`
- [x] `gvn`
- [x] `sccp`
- [x] `ipsccp` placeholder until call graph exists
- [x] `adce`
- [x] `bdce`
- [x] `reassociate`
- [x] `constraint-elimination` placeholder
- [x] `speculative-execution` placeholder

## Epic 7: Loop Canonicalization Before Loop Optimization

Goal: make loops structurally close enough to LLVM's expected loop forms before
attempting performance loop transforms.

- [ ] Add algorithm contracts for LoopInfo, loop-simplify helpers,
      loop-instsimplify, loop-simplifycfg, loop-rotate, and loop-deletion.
- [ ] Document LLVM source mapping:
      `llvm/lib/Analysis/LoopInfo.cpp`,
      `llvm/lib/Transforms/Utils/LoopSimplify.cpp`,
      `llvm/lib/Transforms/Scalar/LoopInstSimplify.cpp`,
      `llvm/lib/Transforms/Scalar/LoopSimplifyCFG.cpp`,
      `llvm/lib/Transforms/Scalar/LoopRotation.cpp`, and
      `llvm/lib/Transforms/Scalar/LoopDeletion.cpp`.
- [ ] Expand LoopInfo to track nested loops, headers, latches, preheaders,
      exits, exiting blocks, and dedicated exits.
- [ ] Add loop-simplify documentation and fixtures:
      preheader creation, single latch, dedicated exits.
- [ ] Implement local loop-simplify helpers only for tiny reducible loops.
- [ ] Implement loop-instsimplify for instructions inside loops using existing
      InstSimplify.
- [ ] Implement loop-simplifycfg for simple loop-local CFG cleanup.
- [ ] Implement loop-rotate for canonical while/for shapes only after CFG
      rewrites are safe.
- [ ] Implement loop-deletion for loops proven side-effect-free and unused.
- [ ] Add opt-22 comparisons for every accepted canonical loop fixture.

Passes covered:

- [ ] `loop-instsimplify`
- [ ] `loop-simplifycfg`
- [ ] `loop-rotate`
- [ ] `loop-deletion`
- [ ] loop structure required by `licm`

## Epic 8: Loop Optimization Quality

Goal: improve loop performance only after canonical loop shape is reliable.

- [ ] Add algorithm contracts for LICM, IndVarSimplify, SimpleLoopUnswitch,
      LoopIdiomRecognize, LoopSink, and LoopUnroll before implementation.
- [ ] Document LLVM source mapping:
      `llvm/lib/Transforms/Scalar/LICM.cpp`,
      `llvm/lib/Transforms/Scalar/IndVarSimplify.cpp`,
      `llvm/lib/Transforms/Scalar/SimpleLoopUnswitch.cpp`,
      `llvm/lib/Transforms/Scalar/LoopIdiomRecognize.cpp`,
      `llvm/lib/Transforms/Scalar/LoopSink.cpp`, and
      `llvm/lib/Transforms/Scalar/LoopUnrollPass.cpp`.
- [ ] Expand LICM with memory legality through alias/mod-ref and MemorySSA-like
      scaffolding.
- [ ] Add IndVarSimplify for simple affine induction variables.
- [ ] Add simple-loop-unswitch only for trivial invariant conditions and small
      loop bodies.
- [ ] Add loop-idiom recognition only for explicit Zig-emitted idioms after
      memory intrinsics are modeled.
- [ ] Add loop-sink after LICM and loop canonicalization are stable.
- [ ] Add loop-unroll/full-unroll only with clear code-size mode gates.
- [ ] Keep loop-distribute, loop-load-elim, vector-prep, and vectorization
      deferred until vector IR and target cost modeling exist.

Passes covered:

- [ ] `licm`
- [ ] `indvars`
- [ ] `simple-loop-unswitch`
- [ ] `loop-idiom`
- [ ] `loop-sink`
- [ ] `loop-unroll`
- [ ] `loop-unroll-full`
- [ ] deferred: `loop-distribute`, `loop-load-elim`,
      `extra-simple-loop-unswitch-passes`

## Epic 9: Calls, Attributes, And Mandatory IPO

Goal: cover interprocedural behavior that is mandatory or unlocks scalar
pipeline correctness for Zig-emitted calls.

Sequencing note: `always-inline` is P0 in the Zig LLVM pass inventory, but it is
delayed until call/declaration IR, call graph basics, and call-site verifier
rules exist. Until then, implementing it would either be a placeholder or would
silently miss the LLVM algorithm's required input surface.

- [ ] Add algorithm contracts for always-inline, attribute inference, call
      graph, and call mod/ref before implementation.
- [ ] Document LLVM source mapping:
      `llvm/lib/Transforms/IPO/AlwaysInliner.cpp`,
      `llvm/lib/Transforms/IPO/ForceFunctionAttrs.cpp`,
      `llvm/lib/Transforms/IPO/FunctionAttrs.cpp`,
      `llvm/lib/Analysis/CallGraph.cpp`, and the new pass-manager CGSCC
      infrastructure used by the selected pipeline.
- [ ] Complete call/declaration IR surface:
      parser, printer, verifier, def-use, side-effect classification.
- [ ] Implement `always-inline` for Zig-required inline cases and small
      mandatory cases before general inlining.
- [ ] Add function attribute parsing/semantics for readonly, readnone, nounwind,
      noinline, alwaysinline, cold, noundef, nonnull, align, and related
      Zig-emitted attributes.
- [ ] Implement attribute inference only where it feeds local passes safely.
- [ ] Add basic call graph analysis.
- [ ] Add call mod/ref classification using attributes.
- [ ] Implement local-only conservative behavior for unknown calls.
- [ ] Defer general inliner, argpromotion, deadargelim, called-value
      propagation, and global IPO until the call graph and ABI semantics are
      mature.

Passes covered:

- [ ] `always-inline`
- [ ] `forceattrs`
- [ ] `inferattrs`
- [ ] `function-attrs`
- [ ] `rpo-function-attrs`
- [ ] `inline` placeholder
- [ ] `ipsccp` after call graph exists
- [ ] deferred: `argpromotion`, `called-value-propagation`,
      `callsite-splitting`, `deadargelim`

## Epic 10: Globals And Module-Level Cleanup

Goal: cover the global/module cleanup behavior that appears in Zig's release
pipelines.

- [ ] Add algorithm contracts for GlobalDCE, GlobalOpt, ConstantMerge,
      ElimAvailExtern, and GlobalsAA before implementation.
- [ ] Document LLVM source mapping:
      `llvm/lib/Transforms/IPO/GlobalDCE.cpp`,
      `llvm/lib/Transforms/IPO/GlobalOpt.cpp`,
      `llvm/lib/Transforms/IPO/ConstantMerge.cpp`,
      `llvm/lib/Transforms/IPO/ElimAvailExtern.cpp`, and
      `llvm/lib/Analysis/GlobalsModRef.cpp`.
- [ ] Expand global IR representation for declarations, definitions, constants,
      linkage, visibility, unnamed addresses, aliases, comdat placeholders, and
      attributes as needed by Zig-emitted IR.
- [ ] Implement GlobalDCE for unreferenced internal/private globals/functions.
- [ ] Implement a small ConstantMerge subset for identical scalar constants if
      Zig emits relevant cases.
- [ ] Implement GlobalOpt only for narrow scalar cases with clear initializer
      semantics.
- [ ] Add available_externally handling only after linkage semantics are solid.
- [ ] Add GlobalsAA only after global memory identity can be represented
      conservatively.
- [ ] Defer MergeFunctions until code-size quality becomes a specific goal.

Passes covered:

- [ ] `globaldce`
- [ ] `globalopt`
- [ ] `constmerge`
- [ ] `elim-avail-extern`
- [ ] `recompute-globalsaa` / `globals-aa`
- [ ] deferred: `mergefunc`

## Epic 11: Codegen-Prep And Library-Call Optimizations

Goal: implement late scalar rewrites that LLVM uses before machine code only
after call, target, and DataLayout facts are available.

- [ ] Add algorithm contracts for lower-expect, div-rem-pairs, tailcallelim,
      libcalls-shrinkwrap, and TargetLibraryInfo-backed transforms.
- [ ] Document LLVM source mapping:
      `llvm/lib/Transforms/Scalar/LowerExpectIntrinsic.cpp`,
      `llvm/lib/Transforms/Scalar/DivRemPairs.cpp`,
      `llvm/lib/Transforms/Scalar/TailRecursionElimination.cpp`,
      `llvm/lib/Transforms/Utils/LibCallsShrinkWrap.cpp`, and
      `llvm/include/llvm/Analysis/TargetLibraryInfo.h`.
- [ ] Add TargetLibraryInfo-style inventory for Zig targets.
- [ ] Implement conservative `lower-expect` support if `llvm.expect` enters IR.
- [ ] Implement `div-rem-pairs` only after target cost/operation lowering
      policies exist.
- [ ] Keep `float2int` as an explicit placeholder until floating-point IR and
      target legality are represented.
- [ ] Implement `tailcallelim` only after call lowering and ABI constraints are
      represented.
- [ ] Implement `libcalls-shrinkwrap` only with target-library facts.
- [ ] Add `inject-tli-mappings` only when vector library mappings matter.
- [ ] Keep transformations target-aware and mode-aware.

Passes covered:

- [ ] `lower-expect`
- [ ] `div-rem-pairs`
- [ ] `float2int` placeholder
- [ ] `tailcallelim`
- [ ] `libcalls-shrinkwrap`
- [ ] `inject-tli-mappings`
- [ ] `rel-lookup-table-converter` placeholder

## Epic 12: Instrumentation, Sanitizers, Debug/Profile Metadata

Goal: model optimizer-visible instrumentation hooks without mixing them into
core scalar optimization too early.

- [ ] Add algorithm contracts or explicit placeholder contracts for metadata,
      AddDiscriminators, annotation passes, SanitizerCoverage, TSan, and
      EntryExitInstrumenter.
- [ ] Document LLVM source mapping:
      `llvm/lib/Transforms/Utils/AddDiscriminators.cpp`,
      `llvm/lib/Transforms/IPO/Annotation2Metadata.cpp`,
      `llvm/lib/Transforms/Instrumentation/SanitizerCoverage.cpp`,
      `llvm/lib/Transforms/Instrumentation/ThreadSanitizer.cpp`, and
      `llvm/lib/Transforms/Utils/EntryExitInstrumenter.cpp`.
- [ ] Add metadata representation needed for debug/profile preservation.
- [ ] Add `AddDiscriminatorsPass` behavior or a conservative placeholder.
- [ ] Add annotation metadata preservation before implementing
      `annotation2metadata`.
- [ ] Add annotation remarks only after diagnostics infrastructure exists.
- [ ] Add SanitizerCoverage and ThreadSanitizer placeholders that fail clearly
      unless instrumentation is explicitly supported.
- [ ] Add `alloc-token` as an explicit allocation-instrumentation placeholder
      until allocation identity and instrumentation metadata are represented.
- [ ] Add EntryExitInstrumenter only if Zig relies on it for selected modes.
- [ ] Keep MemProf, CGProfile, CHR, and transform-warning as deferred unless a
      concrete Zig mode requires them.

Passes covered:

- [ ] `add-discriminators`
- [ ] `annotation2metadata`
- [ ] `annotation-remarks`
- [ ] `sancov`
- [ ] `module-tsan`
- [ ] `tsan`
- [ ] `alloc-token` placeholder
- [ ] `ee-instrument`
- [ ] deferred: `memprof-remove-attributes`, `cg-profile`, `chr`,
      `transform-warning`

## Epic 13: LTO Pre-Link Surface

Goal: cover the LTO pre-link behavior Zig invokes without claiming post-link
LTO replacement too early.

- [ ] Add algorithm contracts or placeholders for canonicalize-aliases,
      name-anon-globals, and LTO pre-link pipeline composition.
- [ ] Document LLVM source mapping:
      `llvm/lib/Passes/PassBuilderPipelines.cpp`,
      `llvm/lib/Transforms/Utils/CanonicalizeAliases.cpp`, and
      `llvm/lib/Transforms/Utils/NameAnonGlobals.cpp`.
- [ ] Keep ThinLTO and FullLTO pre-link modes distinct at the Zig option level.
- [ ] Document that Zig's wrapper currently calls
      `buildLTOPreLinkDefaultPipeline` for any nonzero LTO option.
- [ ] Implement pre-link-only canonicalization required by accepted fixtures.
- [ ] Implement alias canonicalization only after aliases are represented.
- [ ] Implement anonymous global naming only after global identity semantics are
      modeled.
- [ ] Keep summary index, import/export, post-link inlining, WPD, CFI, and
      bitcode summary emission for a later LTO epic.

Passes covered:

- [ ] `canonicalize-aliases`
- [ ] `name-anon-globals`
- [ ] LTO pre-link `verify`
- [ ] LTO pre-link existing P0/P1 scalar passes

## Epic 14: Deferred Vector And Coroutine Surface

Goal: explicitly park discovered passes that require major IR domains not yet
represented.

- [ ] Add vector IR epic before implementing vectorization passes.
- [ ] Add target cost modeling before enabling vectorizer-quality expectations.
- [ ] Add coroutine IR/lowering epic before implementing coroutine passes.
- [ ] Add OpenMP representation before OpenMP optimizer work.
- [ ] Keep these passes listed in inventory as discovered but deferred.

Deferred passes:

- [ ] `loop-vectorize`
- [ ] `slp-vectorizer`
- [ ] `vector-combine`
- [ ] `coro-early`
- [ ] `coro-split`
- [ ] `coro-elide`
- [ ] `coro-cleanup`
- [ ] `coro-annotation-elide`
- [ ] `openmp-opt`
- [ ] `openmp-opt-cgscc`

## Cross-Epic Verification

- [ ] Every epic must update `docs/inventory/zig_llvm_pass_pipeline_inventory.md`
      status for passes it touches.
- [ ] Every epic must add or update pass docs under `docs/passes/` or analysis
      docs under `docs/analysis/`.
- [ ] Every new or broadened pass must include a completed LLVM Algorithm
      Contract block before implementation is marked complete.
- [ ] Every `LLVM-equivalent for listed fixtures` fixture must compare with
      `opt-22`.
- [ ] Every conservative divergence must have a local fixture and an upstream
      behavior note.
- [ ] Every new pass must be reachable through a named local pipeline only
      after it has at least one fixture.
- [ ] Every pass that mutates IR must document preserved analyses, invalidated
      analyses, and whether the local pass manager rebuilds or preserves them.
- [ ] Run `zig build test` and relevant comparison scripts before marking an
      implementation epic complete.

## First Day-Sized Slice To Pull From This Plan

- [x] Create a `Verifier Foundation Epic` in `docs/roadmap/`.
- [x] Pull only verifier expansion and fixture metadata:
      dominance checks, phi predecessor/incoming validity, use-before-def
      rejection, terminator shape validation, and call/reference validation for
      the currently accepted IR.
- [x] Add the `verify` inventory row as the explicit justification.
- [x] Add the LLVM Algorithm Contract for `VerifierPass` and local verifier
      behavior before implementation.
- [x] Add accepted and rejected verifier fixtures with `opt-22` comparison where
      LLVM accepts the same IR surface.
- [x] Keep InstCombine, SimplifyCFG, mem2reg, SROA, DSE, SCCP, loop rotation,
      inlining, globals, vectorization, and LTO out of the first slice.
