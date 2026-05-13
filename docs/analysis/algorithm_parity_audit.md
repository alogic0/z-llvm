# LLVM Algorithm Parity Audit

This is the current single parity table for LLVM optimization behavior used by
Zig's LLVM pipeline. It records what the local project actually implements,
which LLVM sources define the upstream algorithm, which local files own the
subset, and which gaps block stronger parity claims.

Status meanings match `docs/README.md`:

```text
placeholder: pass is registered but not implemented
LLVM-shaped subset: broad LLVM structure exists for the accepted IR surface
fixture-equivalent: output matches LLVM 22 for listed fixtures
algorithm-parity target: same core LLVM data structures and flow for supported IR
```

Cycle 01 finish rule: no pass in the current inventory is an
`algorithm-parity target`. The implemented pass set is either
fixture-equivalent for listed fixtures or an LLVM-shaped/local conservative
subset. Treat stronger LLVM algorithm parity as future quality work selected
from measured fixture or corpus gaps, not as part of the current finish line.

## Implemented And Foundation Passes

| Pass | Status | LLVM source | Local source/docs | Fixture proof | Missing analyses | Missing IR surface | Follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `verify` | LLVM-shaped subset | `llvm/lib/IR/Verifier.cpp` | `src/ir/verifier.zig`, `docs/ir_verifier.md` | Zig corpus runner and unit tests | full attribute, metadata, DataLayout, EH, atomics validation | vector, token, EH, operand bundles, COMDAT/module flags | Cycle 23, Cycle 24 |
| `instsimplify` | fixture-equivalent through InstCombine fixtures | `llvm/lib/Analysis/InstructionSimplify.cpp` | `src/passes/inst_simplify.zig`, `docs/passes/inst_simplify.md` | `instcombine_*`, `select_fold`, scalar fixtures | AssumptionCache, DataLayout facts, TLI | vectors, floats, poison-rich cases | Cycle 18 |
| `instcombine` | fixture-equivalent | `llvm/lib/Transforms/InstCombine/` | `src/passes/instcombine.zig`, `docs/passes/instcombine.md` | `instcombine_*`, `select_fold`, including flagged neutral and zero-result folds, strict scalar FP literal comparisons, selected strict FP arithmetic constants, and `debug_instcombine_dbg_salvage` | AssumptionCache, TLI, richer DataLayout, full debug salvage | general APFloat result printing, vectors, complex casts, poison/undef breadth, variable-location intrinsics | Cycle 18 plus Stub Replacement Slices 17-18 and 28 expansions |
| `simplifycfg` | fixture-equivalent | `llvm/lib/Transforms/Scalar/SimplifyCFGPass.cpp` | `src/passes/simplifycfg.zig`, `docs/passes/simplifycfg.md` | `simplifycfg_*`, `unreachable_simplifycfg`, ADCE CFG fixtures, including `simplifycfg_diamond_select_prof` | DomTree preservation, TTI, AssumptionCache, broad profile metadata updates | switch, invoke, EH pads, indirectbr, callbr | Cycle 18, Cycle 21; Stub Replacement Slice 27 profile slice |
| `dce` | fixture-equivalent | `llvm/lib/Transforms/Scalar/DCE.cpp` | `src/passes/dce.zig`, `docs/passes/dce.md` | `dce`, `memory_dce`, volatile rejection fixtures | richer side-effect queries, MemorySSA for broad memory | atomics/fences, operand bundles, metadata uses | Cycle 16, Cycle 24 |
| `adce` | fixture-equivalent for listed CFG fixtures | `llvm/lib/Transforms/Scalar/ADCE.cpp` | `src/passes/adce.zig`, `docs/passes/adce.md` | `adce_*` including dead branch/diamond fixtures | full PostDominatorTree semantics, control dependence updates | switch/EH/complex terminators | Cycle 18, Cycle 21 |
| `sccp` | fixture-equivalent | `llvm/lib/Transforms/Scalar/SCCP.cpp` | `src/passes/sccp.zig`, `docs/passes/sccp.md` | `sccp_*` | full SparseSolver, LVI, IPSCCP call graph | richer constants, aggregates, interprocedural calls | Cycle 18 |
| `early-cse` | fixture-equivalent for memory and scalar fixtures | `llvm/lib/Transforms/Scalar/EarlyCSE.cpp` | `src/passes/early_cse.zig`, `docs/passes/early_cse.md` | `early_cse_*`, including `fp_early_cse_flags` | full optimized MemorySSA walker/updater, AssumptionCache, TLI | broader call attrs, metadata, atomics/fences, constrained FP | Cycle 16 access-list slice complete; Stub Replacement Slices 5-6 walker API/client complete; Slices 9 and 19 call ModRef/FP CSE complete |
| `gvn` | fixture-equivalent | `llvm/lib/Transforms/Scalar/GVN.cpp` | `src/passes/gvn.zig`, `docs/passes/gvn.md` | `gvn_*`, including `gvn_argmemonly_call_no_clobber` and `fp_gvn_flags` | MemoryDependence/full optimized MemorySSA walker, general PRE, full ValueTable | complex loads/calls, vectors, aggregates, constrained FP | Cycle 16 access-list slice complete; Stub Replacement Slices 5, 7, 9, and 19 walker/load-PRE/call-ModRef/FP CSE slices complete |
| `dse` | fixture-equivalent | `llvm/lib/Transforms/Scalar/DeadStoreElimination.cpp` | `src/passes/dse.zig`, `docs/passes/dse.md` | `dse_*` | full optimized MemorySSA walker/updater, AAResults, MemoryLocation metadata | memset/memcpy, broad partial stores, atomics/fences | Cycle 16 same-block query complete; Stub Replacement Slices 5 and 8 walker/partial-overwrite slices complete; deeper DSE remains |
| `mem2reg` | fixture-equivalent | `llvm/lib/Transforms/Utils/Mem2Reg.cpp`, `PromoteMemoryToRegister.cpp` | `src/passes/mem2reg.zig`, `docs/passes/mem2reg.md` | `mem2reg_*` | full live-in pruning parity and debug intrinsic updates | complex alloca users, debug intrinsics | Cycle 18 |
| `sroa` | LLVM-shaped subset for listed stack slices | `llvm/lib/Transforms/Scalar/SROA.cpp` | `src/passes/sroa.zig`, `docs/passes/sroa.md` | `sroa_*`, including DataLayout-backed pointer field scalarization and whole-aggregate load/store rewriting | full partition iterator, AA, complete DataLayout rewrite legality | arbitrary aggregates, vectors, memcpy/memset | Cycle 05 finish burn-down plus Stub Replacement Slices 15-16 partition builder and debug-free rewrite |
| `licm` | LLVM-shaped subset | `llvm/lib/Transforms/Scalar/LICM.cpp` | `src/passes/licm.zig`, `docs/passes/licm.md` | `licm_*` | MemorySSA updater, AAResults, LoopSafetyInfo, AssumptionCache | general memory LICM, sinking, non-canonical loops, exceptions | Cycle 17 scalar/nested slice plus Stub Replacement Slice 14 one-slot promotion |
| `loop-instsimplify` | LLVM-shaped subset | `llvm/lib/Transforms/Scalar/LoopInstSimplify.cpp` | `src/passes/loop_instsimplify.zig`, `docs/passes/loop_instsimplify.md` | unit tests and loop pipeline docs | LoopInfo preservation, AssumptionCache, SCEV | broader loop metadata and vector forms | Cycle 17 |
| `always-inline` | fixture-equivalent for listed direct-call fixtures | `llvm/lib/Transforms/IPO/AlwaysInliner.cpp` | `src/passes/always_inline.zig`, `docs/passes/mandatory_ipo.md` | `always_inline_direct`, `always_inline_noinline_call` | AssumptionCache, AAResults, ProfileSummaryInfo, InlineFunctionInfo | multi-block callees, PHIs, varargs, recursion, EH, COMDAT, debug salvage | Stub Replacement Slice 1 |
| `inline` | LLVM-shaped subset for one cost-gated direct-call shape | `llvm/lib/Transforms/IPO/Inliner.cpp`, `llvm/lib/Analysis/InlineCost.cpp` | `src/passes/inline.zig`, `src/passes/always_inline.zig`, `docs/passes/mandatory_ipo.md` | `inline_direct_small`, `inline_noinline_call` | full LazyCallGraph/CGSCC updates, InlineAdvisor, InlineCost, AA/BFI/PSI, attribute merging | multi-block callees, PHIs, invokes/callbr, operand bundles, recursive SCCs, debug salvage | Stub Replacement Slice 23 |
| `jump-threading` | LLVM-shaped subset for branch-on-PHI predecessor constants | `llvm/lib/Transforms/Scalar/JumpThreading.cpp` | `src/passes/jump_threading.zig`, `docs/passes/jump_threading.md` | `jump_threading_phi_const`, `jump_threading_non_phi_reject` | LazyValueInfo, block duplication, generic PHI translation, profile updates | switches, indirectbr, loop-header threading, metadata/debug salvage | Stub Replacement Slice 2 |
| `correlated-propagation` | LLVM-shaped subset for branch-implied integer `icmp` facts | `llvm/lib/Transforms/Scalar/CorrelatedValuePropagation.cpp`, `llvm/lib/Analysis/LazyValueInfo.cpp` | `src/passes/correlated_propagation.zig`, `src/analysis/lazy_value_info.zig`, `docs/passes/correlated_propagation.md`, `docs/analysis/lazy_value_info.md` | `correlated_propagation_icmp_eq`, `correlated_propagation_multipred_reject` | ValueLatticeElement, ConstantRange, PHI/select/switch/range reasoning | assumes, guards, overflow intrinsics, min/max, multi-predecessor edge-sensitive joins | Stub Replacement Slice 3 |
| `lower-expect` | LLVM-shaped subset for direct `llvm.expect.i1` branch metadata | `llvm/lib/Transforms/Scalar/LowerExpectIntrinsic.cpp` | `src/passes/lower_expect.zig`, `docs/passes/codegen_prep_library_calls.md` | `lower_expect_i1_branch`, `lower_expect_i32_preserve` | expect.with.probability, switch/select/phi handling, profile merge policy | non-i1 expect lowering, debug salvage, metadata interpretation beyond branch weights | Stub Replacement Slice 4 |
| `globalopt` | LLVM-shaped subset for scalar direct-load cleanup | `llvm/lib/Transforms/IPO/GlobalOpt.cpp` | `src/passes/globalopt.zig`, `docs/passes/global_cleanup_placeholders.md` | `globalopt_internal_scalar_load`, `globalopt_store_addr_reject` | full GlobalStatus, DataLayout constant folding, TTI/TLI, ctor evaluator | aggregates, aliases, GEP/bitcast users, global-to-local stack promotion, TLS/COMDAT | Stub Replacement Slice 20 |
| `constmerge` | LLVM-shaped subset for scalar private constants | `llvm/lib/Transforms/IPO/ConstantMerge.cpp` | `src/passes/constmerge.zig`, `docs/passes/global_cleanup_placeholders.md` | `constmerge_private_unnamed_scalar`, `constmerge_no_unnamed_reject` | full Constant pointer equality, llvm.used handling, metadata, alignment merge | aggregates, strings, vectors, non-default address spaces, COMDAT, TLS | Stub Replacement Slice 21 |
| `function-attrs` | LLVM-shaped subset for direct-call memory and norecurse inference | `llvm/lib/Transforms/IPO/FunctionAttrs.cpp` | `src/passes/function_attrs.zig`, `docs/analysis/function_attrs.md`, `docs/passes/mandatory_ipo.md` | `function_attrs_direct_calls`, `function_attrs_reject` | full CGSCC/LazyCallGraph traversal, AAResults, Attributor, writeonly/nofree/nosync/nounwind/willreturn inference | indirect calls, operand bundles, recursive SCCs, unknown external calls, volatile/atomic memory | Stub Replacement Slice 22 |
| `globaldce` | fixture-equivalent for listed graph fixtures | `llvm/lib/Transforms/IPO/GlobalDCE.cpp` | `src/passes/globaldce.zig`, `docs/passes/globaldce.md` | `globaldce_basic`, `globaldce_alias_root` | comdat graph, metadata/global initializer graph breadth | ifuncs, COMDAT, aliases beyond accepted surface | Cycle 23 |

## Placeholder And Deferred Pass Surface

| Pass family | Inventory entries | Current status | Blocking surface | Follow-up |
| --- | --- | --- | --- | --- |
| Loop canonicalization and transforms | `loop-simplifycfg`, `loop-rotate`, `loop-deletion`, `indvars`, `simple-loop-unswitch`, `loop-idiom`, `loop-unroll`, `loop-sink`, `loop-load-elim`, `loop-distribute` | `loop-simplifycfg` has a constant-branch/block-merge LLVM-shaped subset, `loop-rotate` has a single-latch counted-loop subset, `loop-deletion` deletes dead `mustprogress` counted loops, and `indvars` rewrites one affine derived-IV exit value; remaining loop transforms are placeholders except `licm`, `loop-instsimplify`, LoopInfo induction recognition, and simple LCSSA helper | LoopSimplify, full LCSSA, full SCEV, MemorySSA, branch probability, TTI | Stub Replacement Slices 10-13 complete; future loop quality work |
| Scalar quality passes | `reassociate`, `constraint-elimination`, `speculative-execution`, `tailcallelim`, `div-rem-pairs`, `float2int`, `lower-constant-intrinsics`, `drop-unnecessary-assumes` | placeholders or folded into smaller local scalar rules; `jump-threading`, `correlated-propagation`, and `lower-expect` have narrow LLVM-shaped slices | richer IR, full LazyValueInfo, AssumptionCache, TLI, profile metadata | Cycle 18 and Stub Replacement Slices 2-4 |
| Memory precision passes | `memcpyopt`, `mldst-motion`, `infer-alignment`, `alignment-from-assumptions`, `move-auto-init` | placeholders | MemorySSA, AAResults stack, DataLayout, memcpy/memset intrinsics | Cycle 16 |
| IPO and attributes | `inline`, `argpromotion`, `called-value-propagation`, `callsite-splitting`, `deadargelim`, `forceattrs`, `inferattrs`, `function-attrs`, `rpo-function-attrs`, `mergefunc`, `globalopt`, `constmerge` | `always-inline` has a direct-call fixture-equivalent slice; `inline` has one cost-gated direct-call slice; `function-attrs` has direct-call memory/norecurse inference; `globalopt` has scalar direct-load cleanup; `constmerge` has scalar private constant merging; remaining entries are placeholders or call graph and attribute foundations only | broader function cloning, call-site attrs, linkage/comdat, interprocedural analysis | Stub Replacement Slices 1, 20, 21, 22, and 23; Cycle 18, Cycle 23 |
| Vector and target-cost passes | `loop-vectorize`, `slp-vectorizer`, `vector-combine` | TargetTransformInfo has an analysis-only x86_64/AArch64 cost skeleton; vector-combine has one extract/insert lane-identity slice; slp-vectorizer has a recognition-only same-op scalar bundle diagnostic slice; loop-vectorize remains a placeholder | vector IR, BoUpSLP tree construction/scheduling, LoopAccessAnalysis, ScalarEvolution, complete TargetTransformInfo consumption, target codegen validation | Cycle 11 boundary; Stub Replacement Slices 24-26; future vector transform work |
| Sanitizer/profile/instrumentation | `sancov`, `module-tsan`, `tsan`, `cg-profile`, `chr`, `ee-instrument`, `add-discriminators`, `alloc-token`, `memprof-remove-attributes` | placeholders plus explicit sanitizer/trap rejection | runtime ABI, inserted calls, debug/profile metadata semantics | Cycle 12 boundary; future sanitizer track |
| LTO/global canonicalization | `canonicalize-aliases`, `name-anon-globals`, `elim-avail-extern`, `require<profile-summary>` | placeholders | bitcode writer, summary index, COMDAT/linkage semantics | Cycle 13 boundary, Cycle 23 |
| Coroutine/OpenMP | `coro-*`, `openmp-opt`, `openmp-opt-cgscc` | placeholders | coroutine tokens/intrinsics, OpenMP runtime calls and metadata | future optional track |

## High-Risk Gaps

| Gap | Why it matters | Roadmap owner |
| --- | --- | --- |
| MemorySSA and AA precision | Blocks faithful GVN load PRE, DSE, LICM memory motion, EarlyCSE load/call availability | Cycle 16 |
| Loop canonical form and SCEV | Blocks full LoopRotate, full LoopDeletion, full IndVarSimplify, loop unswitching, unrolling, and loop idiom recognition | Cycle 17 and Stub Replacement Slices 10-13 |
| Scalar quality beyond fixture folds | Blocks Zig ReleaseFast quality for branch threading, CVP, reassociation, div/rem, expect lowering, and TLI-guided transforms | Cycle 18 |
| Machine IR/codegen boundary | Needed before optimizer output can be validated against backend lowering beyond tiny fixtures | Cycle 19 |
| Object/debug/unwind boundary | Needed before emitted-code validation can cover debug/unwind correctness | Cycle 20 |
| EH IR | Blocks invoke/landingpad/cleanup/catch semantics and CFG legality | Cycle 21 |
| Atomics, inline asm, and concurrency | Blocks memory side-effect parity for atomics/fences/asm and threaded code | Cycle 22, Cycle 24 |
| Module flags, COMDAT, linkage | Blocks IPO/global cleanup parity and LTO correctness | Cycle 23 |
| PGO/size target behavior | Blocks ReleaseSmall and profile-guided quality claims | Cycle 25 |
| Target features and CPU model | Blocks TTI, vectorization, libcall, and backend cost claims | Cycle 26 |

## Audit Maintenance Rule

Update this table whenever a pass moves between status levels. A status upgrade
must cite:

```text
LLVM source file or entry point
local source owner
required analyses used locally
fixture names and opt-22 comparison command or reason for local-only coverage
remaining parser/verifier blockers
roadmap owner for the highest-risk missing LLVM behavior
```
