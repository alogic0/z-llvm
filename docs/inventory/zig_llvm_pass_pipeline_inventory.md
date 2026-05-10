# Zig LLVM Pass Pipeline Inventory

This inventory records the LLVM IR optimization pipelines that Zig invokes
through its LLVM backend. Paths are relative to `prog`.

The purpose is to choose optimizer work from Zig's actual LLVM use, not from a
generic list of familiar LLVM passes.

## Source Anchors

Zig entry points:

- `ziglang/src/codegen/llvm.zig:1006`: reads the root optimize mode.
- `ziglang/src/codegen/llvm.zig:1008`: maps `Debug` to LLVM codegen opt level
  `None`; every non-debug mode uses `Aggressive`.
- `ziglang/src/codegen/llvm.zig:1057`: builds `TargetMachine.EmitOptions`.
- `ziglang/src/codegen/llvm.zig:1062`: maps Zig LTO mode to
  `None`, `ThinPreLink`, or `FullPreLink`.
- `ziglang/src/codegen/llvm.zig:1121`: calls `TargetMachine.emitToFile`.
- `ziglang/src/zig_llvm.cpp:285`: creates LLVM `PipelineTuningOptions`.
- `ziglang/src/zig_llvm.cpp:322`: registers Zig's pipeline-start callback.
- `ziglang/src/zig_llvm.cpp:335`: registers Zig's optimizer-early callback.
- `ziglang/src/zig_llvm.cpp:350`: registers Zig's optimizer-last callback.
- `ziglang/src/zig_llvm.cpp:371`: maps Zig emit options to LLVM
  `OptimizationLevel`.
- `ziglang/src/zig_llvm.cpp:381`: chooses the PassBuilder pipeline entry
  point.

LLVM pipeline sources:

- `llvm-project-22/llvm/lib/Passes/PassBuilderPipelines.cpp`
- `llvm-project-22/llvm/lib/Passes/PassBuilder.cpp`
- `llvm-project-22/llvm/include/llvm/Passes/PassBuilder.h`

Primary LLVM entry points:

- `PassBuilder::buildO0DefaultPipeline`
- `PassBuilder::buildPerModuleDefaultPipeline`
- `PassBuilder::buildLTOPreLinkDefaultPipeline`
- `PassBuilder::buildModuleSimplificationPipeline`
- `PassBuilder::buildModuleOptimizationPipeline`
- `PassBuilder::buildFunctionSimplificationPipeline`
- `PassBuilder::buildDefaultAAPipeline`

## Zig Mode Mapping

| Zig mode/path | LLVM optimization level | PassBuilder entry point | LTO phase | Notes |
| --- | --- | --- | --- | --- |
| `Debug` | `O0` | `buildO0DefaultPipeline` | usually `None` | Minimal optimization; always-inlining and required instrumentation still run. |
| `ReleaseFast` | `O3` | `buildPerModuleDefaultPipeline` | `None` | Same LLVM optimization level as `ReleaseSafe`; Zig-emitted IR differs because safety checks differ before LLVM. |
| `ReleaseSafe` | `O3` | `buildPerModuleDefaultPipeline` | `None` | Track separately from `ReleaseFast` because frontend/AIR lowering keeps safety behavior. |
| `ReleaseSmall` | `Oz` | `buildPerModuleDefaultPipeline` | `None` | Size-focused LLVM pipeline; loop/vector choices differ from `O3`. |
| non-debug + `-flto=thin` | `O3` or `Oz` | `buildLTOPreLinkDefaultPipeline` | Zig option is `ThinPreLink`; effective PassBuilder phase is `FullLTOPreLink` | Zig currently calls LLVM's full LTO pre-link builder for any nonzero LTO option in `zig_llvm.cpp`. |
| non-debug + `-flto=full` | `O3` or `Oz` | `buildLTOPreLinkDefaultPipeline` | Zig option is `FullPreLink`; effective PassBuilder phase is `FullLTOPreLink` | Same PassBuilder entry point as ThinLTO in Zig's wrapper. |
| debug + LTO | `O0` | `buildO0DefaultPipeline` | passed through to LLVM | Kept visible for completeness; not the first replacement target. |

Important correction: LLVM has a separate textual
`thinlto-pre-link<...>` pipeline, but Zig's non-debug wrapper currently calls
`buildLTOPreLinkDefaultPipeline` whenever `options->lto` is nonzero.

## Zig-Specific Pipeline Options

Zig does not invoke the bare LLVM defaults. It configures `PipelineTuningOptions`
before constructing `PassBuilder`:

| Option | Zig setting | Inventory consequence |
| --- | --- | --- |
| `LoopUnrolling` | `!is_debug` | Release pipelines may run unroll passes; debug should not. |
| `SLPVectorization` | `!is_debug` | Release pipelines include SLP vectorization unless size/target gates suppress it. |
| `LoopVectorization` | `false` | Zig intentionally disables normal loop vectorization. Do not prioritize full loop-vectorizer replacement yet. |
| `LoopInterleaving` | `!is_debug` | Release loop-vectorizer/interleaving behavior remains target-cost dependent. |
| `MergeFunctions` | `!is_debug` | Release pipelines include `mergefunc`; debug does not. |
| `allow_fast_isel` | `true` | Codegen setting, not an IR optimizer pass. |
| `allow_machine_outliner` | disabled for RISC-V | Codegen setting, not an IR optimizer pass. |

Zig also inserts passes through extension points:

| Extension point | Zig pass | Condition |
| --- | --- | --- |
| Pipeline start | `VerifierPass` | assertion-enabled builds |
| Pipeline start | `AddDiscriminatorsPass` | non-debug mode |
| Optimizer early | `SanitizerCoveragePass` | debug + sanitizer coverage |
| Optimizer early | `ModuleThreadSanitizerPass`, `ThreadSanitizerPass` | debug + TSan |
| Optimizer last | `SanitizerCoveragePass` | non-debug + sanitizer coverage |
| Optimizer last | `ModuleThreadSanitizerPass`, `ThreadSanitizerPass` | non-debug + TSan |
| Optimizer last | `VerifierPass` | assertion-enabled builds |

## Extraction Commands

These commands are useful for refreshing this inventory against LLVM 22:

```sh
opt-22 -passes='default<O0>' -print-pipeline-passes -disable-output /dev/null
opt-22 --enable-merge-functions -passes='default<O3>' -print-pipeline-passes -disable-output /dev/null
opt-22 --enable-merge-functions -passes='default<Oz>' -print-pipeline-passes -disable-output /dev/null
opt-22 --enable-merge-functions -passes='lto-pre-link<O3>' -print-pipeline-passes -disable-output /dev/null
opt-22 --enable-merge-functions -passes='lto-pre-link<Oz>' -print-pipeline-passes -disable-output /dev/null
```

The printed pipelines are best-effort textual expansions. Treat
`ziglang/src/zig_llvm.cpp` and `PassBuilderPipelines.cpp` as the authority when
`opt-22` command-line flags cannot exactly express Zig's in-process
`PipelineTuningOptions`.

## Pipeline Summary

`Debug` / `O0` is intentionally small:

```text
EntryExitInstrumenter
Zig pipeline-start callbacks
AlwaysInliner
optional extension-point callbacks
coroutine cleanup wrapper
AllocToken when not LTO pre-link
Zig optimizer-last callbacks
annotation remarks
```

Release non-LTO pipelines follow this broad order:

```text
module setup and attributes
Zig pipeline-start callbacks
module simplification
inliner / CGSCC simplification
module optimization
late global cleanup
annotation remarks
verification when enabled
```

Release LTO pre-link pipelines reuse LLVM's per-module default pipeline with
`FullLTOPreLink` phase through `buildLTOPreLinkDefaultPipeline`, then add the
required pre-link passes such as alias canonicalization and anonymous global
naming.

## Concrete Pass Inventory

Priority meanings:

- `P0`: mandatory correctness, validity, or canonical form needed early.
- `P1`: high-leverage scalar/memory canonicalization for small Zig-emitted IR.
- `P2`: performance quality once the IR surface and analyses are broader.
- `P3`: defer until calls, globals, vectors, profiling, sanitizer, debug info,
  or LTO support exists.

Status meanings:

- `foundation`: local implementation exists but is intentionally narrower than
  LLVM.
- `partial`: local IR or analysis support exists, but the pass is not a real
  implementation yet.
- `placeholder`: executable no-op pipeline entry exists so the discovered
  pipeline surface is explicit, but the LLVM algorithm is not implemented.
- `missing`: no meaningful local implementation.
- `defer`: not a near-term optimizer target.

| LLVM pass | Category | Priority | Local status | Upstream owner |
| --- | --- | --- | --- | --- |
| `verify` / `VerifierPass` | mandatory | P0 | foundation: SSA dominance and phi predecessor checks for accepted IR | `llvm/lib/IR/Verifier.cpp` |
| `always-inline` | mandatory IPO | P0 | placeholder | `llvm/lib/Transforms/IPO/AlwaysInliner.cpp` |
| `mem2reg` | canonicalization | P0 | foundation | `llvm/lib/Transforms/Utils/Mem2Reg.cpp` |
| `sroa` | canonicalization / memory | P0 | foundation | `llvm/lib/Transforms/Scalar/SROA.cpp` |
| `instcombine` | canonicalization | P0 | foundation | `llvm/lib/Transforms/InstCombine/` |
| `instsimplify` | canonicalization query | P0 | foundation | `llvm/lib/Analysis/InstructionSimplify.cpp` |
| `simplifycfg` | canonicalization / CFG | P0 | foundation | `llvm/lib/Transforms/Scalar/SimplifyCFGPass.cpp` |
| `early-cse` | canonicalization / scalar | P1 | foundation | `llvm/lib/Transforms/Scalar/EarlyCSE.cpp` |
| `dse` | memory optimization | P1 | foundation | `llvm/lib/Transforms/Scalar/DeadStoreElimination.cpp` |
| `adce` | scalar DCE | P1 | foundation | `llvm/lib/Transforms/Scalar/ADCE.cpp` |
| `bdce` | scalar DCE | P2 | placeholder | `llvm/lib/Transforms/Scalar/BDCE.cpp` |
| `sccp` / `ipsccp` | scalar / IPO | P1 | foundation / IPSCCP placeholder | `llvm/lib/Transforms/Scalar/SCCP.cpp`, `llvm/lib/Transforms/IPO/SCCP.cpp` |
| `gvn` | scalar / memory | P1 | foundation | `llvm/lib/Transforms/Scalar/GVN.cpp` |
| `licm` | loop / memory | P1 | foundation | `llvm/lib/Transforms/Scalar/LICM.cpp` |
| `loop-instsimplify` | loop canonicalization | P1 | foundation | `llvm/lib/Transforms/Scalar/LoopInstSimplify.cpp` |
| `loop-simplifycfg` | loop canonicalization | P1 | placeholder | `llvm/lib/Transforms/Scalar/LoopSimplifyCFG.cpp` |
| `loop-rotate` | loop canonicalization | P1 | placeholder | `llvm/lib/Transforms/Scalar/LoopRotation.cpp` |
| `loop-deletion` | loop cleanup | P1 | placeholder | `llvm/lib/Transforms/Scalar/LoopDeletion.cpp` |
| `indvars` | loop canonicalization | P2 | placeholder | `llvm/lib/Transforms/Scalar/IndVarSimplify.cpp` |
| `simple-loop-unswitch` | loop optimization | P2 | placeholder | `llvm/lib/Transforms/Scalar/SimpleLoopUnswitch.cpp` |
| `loop-idiom` | loop/memory optimization | P2 | placeholder | `llvm/lib/Transforms/Scalar/LoopIdiomRecognize.cpp` |
| `loop-unroll`, `loop-unroll-full` | loop optimization | P2 | placeholder | `llvm/lib/Transforms/Scalar/LoopUnrollPass.cpp` |
| `loop-distribute` | loop/vector prep | P3 | placeholder | `llvm/lib/Transforms/Scalar/LoopDistribute.cpp` |
| `loop-load-elim` | loop/memory optimization | P3 | placeholder | `llvm/lib/Transforms/Scalar/LoopLoadElimination.cpp` |
| `loop-sink` | loop canonicalization | P2 | placeholder | `llvm/lib/Transforms/Scalar/LoopSink.cpp` |
| `extra-simple-loop-unswitch-passes` | loop optimization | P3 | placeholder | `llvm/lib/Passes/PassBuilderPipelines.cpp` |
| `jump-threading` | CFG/scalar | P2 | placeholder | `llvm/lib/Transforms/Scalar/JumpThreading.cpp` |
| `correlated-propagation` | scalar | P2 | placeholder | `llvm/lib/Transforms/Scalar/CorrelatedValuePropagation.cpp` |
| `reassociate` | scalar canonicalization | P2 | placeholder | `llvm/lib/Transforms/Scalar/Reassociate.cpp` |
| `constraint-elimination` | scalar | P2 | placeholder | `llvm/lib/Transforms/Scalar/ConstraintElimination.cpp` |
| `speculative-execution` | scalar/code motion | P3 | placeholder | `llvm/lib/Transforms/Scalar/SpeculativeExecution.cpp` |
| `tailcallelim` | call/CFG | P2 | placeholder | `llvm/lib/Transforms/Scalar/TailRecursionElimination.cpp` |
| `div-rem-pairs` | scalar/codegen prep | P2 | placeholder | `llvm/lib/Transforms/Scalar/DivRemPairs.cpp` |
| `float2int` | scalar | P3 | placeholder | `llvm/lib/Transforms/Scalar/Float2Int.cpp` |
| `lower-expect` | canonicalization / profiling metadata | P2 | placeholder | `llvm/lib/Transforms/Scalar/LowerExpectIntrinsic.cpp` |
| `lower-constant-intrinsics` | canonicalization | P2 | placeholder | `llvm/lib/Transforms/Scalar/LowerConstantIntrinsics.cpp` |
| `drop-unnecessary-assumes` | canonicalization | P2 | placeholder | `llvm/lib/Transforms/Scalar/DropUnnecessaryAssumes.cpp` |
| `infer-alignment` | memory / target facts | P2 | placeholder | `llvm/lib/Transforms/Scalar/InferAlignment.cpp` |
| `alignment-from-assumptions` | memory / target facts | P3 | placeholder | `llvm/lib/Transforms/Scalar/AlignmentFromAssumptions.cpp` |
| `memcpyopt` | memory optimization | P2 | placeholder | `llvm/lib/Transforms/Scalar/MemCpyOptimizer.cpp` |
| `mldst-motion` | memory optimization | P2 | placeholder | `llvm/lib/Transforms/Scalar/MergedLoadStoreMotion.cpp` |
| `move-auto-init` | memory/security | P3 | placeholder | `llvm/lib/Transforms/Scalar/MoveAutoInit.cpp` |
| `aggressive-instcombine` | canonicalization | P2 | placeholder | `llvm/lib/Transforms/AggressiveInstCombine/` |
| `annotation2metadata` | metadata canonicalization | P3 | placeholder | `llvm/lib/Transforms/IPO/Annotation2Metadata.cpp` |
| `annotation-remarks` | diagnostics/remarks | P3 | placeholder | `llvm/lib/Transforms/Scalar/AnnotationRemarks.cpp` |
| `forceattrs` | attribute IPO | P2 | placeholder | `llvm/lib/Transforms/IPO/ForceFunctionAttrs.cpp` |
| `inferattrs` | attribute IPO | P2 | placeholder | `llvm/lib/Transforms/IPO/InferFunctionAttrs.cpp` |
| `function-attrs` | attribute IPO | P2 | placeholder | `llvm/lib/Transforms/IPO/FunctionAttrs.cpp` |
| `rpo-function-attrs` | attribute IPO | P2 | placeholder | `llvm/lib/Transforms/IPO/FunctionAttrs.cpp` |
| `called-value-propagation` | IPO | P3 | placeholder | `llvm/lib/Transforms/IPO/CalledValuePropagation.cpp` |
| `argpromotion` | IPO | P3 | placeholder | `llvm/lib/Transforms/IPO/ArgumentPromotion.cpp` |
| `inline` | IPO | P2 | placeholder | `llvm/lib/Transforms/IPO/Inliner.cpp` |
| `callsite-splitting` | IPO/scalar | P3 | placeholder | `llvm/lib/Transforms/Scalar/CallSiteSplitting.cpp` |
| `deadargelim` | IPO cleanup | P3 | placeholder | `llvm/lib/Transforms/IPO/DeadArgumentElimination.cpp` |
| `globalopt` | global optimization | P2 | placeholder; partial globals only | `llvm/lib/Transforms/IPO/GlobalOpt.cpp` |
| `globaldce` | global cleanup | P2 | foundation | `llvm/lib/Transforms/IPO/GlobalDCE.cpp` |
| `constmerge` | global cleanup | P3 | placeholder | `llvm/lib/Transforms/IPO/ConstantMerge.cpp` |
| `mergefunc` | size IPO | P3 | placeholder | `llvm/lib/Transforms/IPO/MergeFunctions.cpp` |
| `elim-avail-extern` | LTO/global cleanup | P3 | placeholder | `llvm/lib/Transforms/IPO/ElimAvailExtern.cpp` |
| `recompute-globalsaa` / `globals-aa` | analysis | P2 | placeholder | `llvm/lib/Analysis/GlobalsModRef.cpp` |
| `require<globals-aa>` | analysis plumbing | P2 | placeholder | `llvm/include/llvm/IR/PassManager.h` |
| `invalidate<aa>` | analysis plumbing | P2 | placeholder | `llvm/include/llvm/IR/PassManager.h` |
| `require<profile-summary>` | analysis plumbing | P3 | placeholder | `llvm/include/llvm/IR/PassManager.h` |
| `require<should-not-run-function-passes>` | pipeline guard | P3 | placeholder | `llvm/lib/Passes/PassBuilderPipelines.cpp` |
| `openmp-opt`, `openmp-opt-cgscc` | OpenMP IPO | P3 | defer | `llvm/lib/Transforms/IPO/OpenMPOpt.cpp` |
| `libcalls-shrinkwrap` | library-call optimization | P3 | placeholder | `llvm/lib/Transforms/Utils/LibCallsShrinkWrap.cpp` |
| `inject-tli-mappings` | TLI/vector library metadata | P3 | placeholder | `llvm/lib/Transforms/Utils/InjectTLIMappings.cpp` |
| `loop-vectorize` | vectorization | P3 | defer | `llvm/lib/Transforms/Vectorize/LoopVectorize.cpp` |
| `slp-vectorizer` | vectorization | P3 | defer | `llvm/lib/Transforms/Vectorize/SLPVectorizer.cpp` |
| `vector-combine` | vector canonicalization | P3 | defer | `llvm/lib/Transforms/Vectorize/VectorCombine.cpp` |
| `chr` | control-height reduction | P3 | defer | `llvm/lib/Transforms/Instrumentation/ControlHeightReduction.cpp` |
| `cg-profile` | profile metadata | P3 | defer | `llvm/lib/Transforms/Instrumentation/CGProfile.cpp` |
| `ee-instrument` | instrumentation | P3 | placeholder | `llvm/lib/Transforms/Utils/EntryExitInstrumenter.cpp` |
| `add-discriminators` | debug/profile metadata | P3 | placeholder | `llvm/lib/Transforms/Utils/AddDiscriminators.cpp` |
| `sancov` / `SanitizerCoveragePass` | sanitizer instrumentation | P3 | placeholder | `llvm/lib/Transforms/Instrumentation/SanitizerCoverage.cpp` |
| `module-tsan`, `tsan` | sanitizer instrumentation | P3 | placeholder | `llvm/lib/Transforms/Instrumentation/ThreadSanitizer.cpp` |
| `coro-early` | coroutine lowering | P3 | defer | `llvm/lib/Transforms/Coroutines/CoroEarly.cpp` |
| `coro-split` | coroutine lowering | P3 | defer | `llvm/lib/Transforms/Coroutines/CoroSplit.cpp` |
| `coro-elide` | coroutine lowering | P3 | defer | `llvm/lib/Transforms/Coroutines/CoroElide.cpp` |
| `coro-cleanup` | coroutine lowering | P3 | defer | `llvm/lib/Transforms/Coroutines/CoroCleanup.cpp` |
| `coro-annotation-elide` | coroutine lowering | P3 | defer | `llvm/lib/Transforms/Coroutines/CoroAnnotationElide.cpp` |
| `alloc-token` | allocation instrumentation | P3 | placeholder | `llvm/lib/Transforms/Instrumentation/AllocToken.cpp` |
| `memprof-remove-attributes` | MemProf cleanup | P3 | defer | `llvm/lib/Transforms/Instrumentation/MemProfUse.cpp` |
| `canonicalize-aliases` | LTO/global canonicalization | P3 | placeholder | `llvm/lib/Transforms/Utils/CanonicalizeAliases.cpp` |
| `name-anon-globals` | LTO/global canonicalization | P3 | placeholder | `llvm/lib/Transforms/Utils/NameAnonGlobals.cpp` |
| `rel-lookup-table-converter` | codegen/linker prep | P3 | placeholder | `llvm/lib/Transforms/Utils/RelLookupTableConverter.cpp` |
| `transform-warning` | diagnostics | P3 | defer | `llvm/lib/Transforms/Scalar/WarnMissedTransforms.cpp` |

## Immediate Replacement Order

Use this order for the next optimizer epic:

- [ ] P0 verifier and unsupported-IR diagnostics.
- [ ] P0 SROA/mem2reg stack-shape expansion for Zig-emitted IR.
- [ ] P0 InstSimplify/InstCombine scalar canonicalization.
- [ ] P0 SimplifyCFG for common Zig-emitted block shapes.
- [ ] P1 EarlyCSE/GVN/SCCP foundations once call/global side effects are modeled.
- [ ] P1 memory legality: DSE, MemoryLocation, alias/mod-ref, and MemorySSA-like
      scaffolding only where needed by accepted fixtures.
- [ ] P1 loop canonicalization before loop performance transforms:
      loop-instsimplify, loop-simplifycfg, loop-rotate, loop-deletion.
- [ ] Defer vectorization, broad IPO, sanitizer instrumentation, coroutine
      lowering, and post-link LTO until the IR surface can represent the needed
      constructs honestly.

## Existing Local Coverage Links

- `docs/passes/mem2reg.md`
- `docs/passes/sroa.md`
- `docs/passes/inst_simplify.md`
- `docs/passes/instcombine.md`
- `docs/passes/simplifycfg.md`
- `docs/passes/dce.md`
- `docs/passes/adce.md`
- `docs/passes/early_cse.md`
- `docs/passes/gvn.md`
- `docs/passes/licm.md`
- `docs/analysis/alias.md`
- `docs/analysis/memory_effect.md`
- `docs/analysis/memory_location.md`
