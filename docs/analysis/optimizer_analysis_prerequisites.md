# Optimizer Analysis Prerequisites

This inventory records the analysis hooks needed before later optimizer epics
claim LLVM algorithm parity. It is intentionally separate from pass docs: these
analyses are shared legality and reasoning primitives.

## Upstream Mapping

LLVM source areas:

```text
llvm-project-22/llvm/include/llvm/Analysis/
llvm-project-22/llvm/lib/Analysis/
llvm-project-22/llvm/include/llvm/Transforms/Utils/
llvm-project-22/llvm/lib/Transforms/Utils/
```

Representative LLVM analyses and utilities:

```text
DominatorTree
PostDominatorTree
LoopInfo
AssumptionCache
LazyValueInfo
SparsePropagation
ScopedHashTable
MemorySSA
AAResults
ModRefInfo
MemoryLocation
CallGraph
TargetLibraryInfo
```

## Current Local Hooks

| Hook | Local owner | Status | Used by |
| --- | --- | --- | --- |
| CFG predecessor/successor facts | `src/analysis/cfg.zig`, `src/ir/verifier.zig` | LLVM-shaped subset | verifier, SimplifyCFG, loop analysis |
| Dominator tree/facts | `src/analysis/dominator.zig`, `src/ir/verifier.zig` | LLVM-shaped subset | verifier, Mem2Reg, GVN, LICM |
| Def-use/use counts | `src/analysis/def_use.zig` | LLVM-shaped subset | DCE, ADCE, local pass diagnostics |
| LoopInfo | `src/analysis/loop_info.zig` | LLVM-shaped subset | LICM and loop roadmap slices |
| Memory effects | `src/analysis/memory_effect.zig` | LLVM-shaped subset | DCE, ADCE, GVN, LICM, memory legality |
| Memory locations | `src/analysis/memory_location.zig` | local conservative subset | alias, DSE, SROA-related memory checks |
| Alias/ModRef | `src/analysis/alias.zig` | local conservative subset | DSE and memory legality foundation |
| MemorySSA-like state | `docs/analysis/memory_ssa.md` | design/foundation | later MemorySSA-backed LICM/GVN/DSE |
| Function attributes | `src/analysis/function_attrs.zig` | LLVM-shaped subset | call memory-effect classification |
| Call graph/global reachability | `src/analysis/call_graph.zig` | LLVM-shaped subset | GlobalDCE foundation |
| TargetLibraryInfo | `src/analysis/target_library_info.zig` | placeholder subset | libcall-aware scalar optimization |

## Missing Hooks For Algorithm Parity

| Hook | LLVM role | First likely consumer |
| --- | --- | --- |
| PostDominatorTree | Control-dependence and dead-control reasoning | ADCE parity, SimplifyCFG |
| Control-dependence queries | Determines live terminators and control edges | ADCE parity |
| Executable CFG block/edge tracking | Sparse conditional propagation and unreachable-edge pruning | SCCP parity |
| Sparse value lattice | Constant/overdefined/undef lattice propagation | SCCP, IPSCCP |
| Scoped hash tables | Dominance-scoped expression and value numbering state | GVN/NewGVN parity |
| MemorySSA walker/updater | Memory dependence through CFG with updates after transforms | LICM, GVN load PRE, DSE |
| Complete AAResults stack | Query composition across BasicAA, TBAA, globals, calls | memory legality, LICM, DSE, GVN |
| AssumptionCache | Uses `llvm.assume` and known facts for transforms | InstSimplify, LICM, CVP |
| TargetTransformInfo | Cost and legality model | loop/vector/scalar cost-based passes |
| Global-use graph with linkage semantics | IPO/global cleanup correctness | GlobalDCE, inlining, internalization |

## Local Policy

Do not mark a pass as LLVM algorithm parity unless all analyses required by the
LLVM algorithm are either implemented for the accepted IR surface or documented
as conservative blockers for the fixture under test.

Each future pass slice should list:

- LLVM source files and entry points;
- exact local analysis hooks used;
- missing LLVM analyses and the conservative fallback;
- fixtures and `opt-22` commands used for comparison;
- unsupported Zig-emitted IR constructs that prevented broader coverage.
