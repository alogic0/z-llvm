# Loop Optimization Pipeline

This document records the local loop pipeline boundary for Zig-emitted LLVM IR.
It is a conservative LLVM 22-aligned foundation, not a complete reproduction of
LLVM's loop optimizer.

## Upstream Mapping

```text
LoopInfo:
  llvm-project-22/llvm/include/llvm/Analysis/LoopInfo.h
  llvm-project-22/llvm/lib/Analysis/LoopInfo.cpp

LoopSimplify:
  llvm-project-22/llvm/lib/Transforms/Utils/LoopSimplify.cpp

LCSSA:
  llvm-project-22/llvm/lib/Transforms/Utils/LCSSA.cpp

LICM:
  llvm-project-22/llvm/lib/Transforms/Scalar/LICM.cpp

LoopInstSimplify:
  llvm-project-22/llvm/lib/Transforms/Scalar/LoopInstSimplify.cpp

Deferred loop passes:
  llvm-project-22/llvm/lib/Transforms/Scalar/LoopSimplifyCFG.cpp
  llvm-project-22/llvm/lib/Transforms/Scalar/LoopRotation.cpp
  llvm-project-22/llvm/lib/Transforms/Scalar/SimpleLoopUnswitch.cpp
  llvm-project-22/llvm/lib/Transforms/Scalar/LoopUnrollPass.cpp
  llvm-project-22/llvm/lib/Transforms/Vectorize/LoopVectorize.cpp
```

## Canonical Loop Shape

The current local optimizer accepts only a simple natural-loop shape for code
motion:

```text
preheader:
  br label %header

header:
  ...
  br i1 %cond, label %body_or_latch, label %exit

latch:
  ...
  br label %header

exit:
  ...
```

Terms match LLVM's `Loop` API:

```text
header: the single loop entry block
latch: a loop block with a backedge to the header
preheader: a non-loop predecessor that branches unconditionally to the header
exiting block: an in-loop block with a successor outside the loop
exit block: an outside block reached from an in-loop predecessor
dedicated exit: an exit block whose predecessors are all in the loop
LCSSA: every loop-defined value used outside the loop flows through exit phis
```

The local code can query dedicated exits and check whether a loop is already in
LCSSA form, but it does not split exits or insert LCSSA phis yet. LCSSA
formation is a required future boundary before loop deletion, unswitching,
sinking, or richer loop transforms can claim LLVM parity.

## Local Helper APIs

`src/analysis/loop_info.zig` now exposes the loop queries expected by later
loop passes:

```text
NaturalLoop.headerBlock
NaturalLoop.latchBlock
NaturalLoop.latchBlocks
NaturalLoop.preheader
NaturalLoop.exitingBlocks
NaturalLoop.exitBlocks
NaturalLoop.hasDedicatedExits
NaturalLoop.hasLcssaForm
NaturalLoop.containsBlock
NaturalLoop.backedge
NaturalLoop.depthLevel
NaturalLoop.isLoopInvariantValue
LoopInfo.loopForHeader
LoopInfo.loopForBlock
LoopInfo.loopDepth
LoopInfo.latchesForHeader
LoopInfo.backedges
```

Top-level loops have depth level 1. A block outside all recognized loops has
loop depth 0.

## Current Pass Status

| Pass | Local status | Boundary |
| --- | --- | --- |
| `LoopInfo` | LLVM-shaped subset | Natural loops from dominator backedges, loop nesting, preheader/exit queries |
| `loop-instsimplify` | LLVM-shaped subset | Applies local InstSimplify only inside recognized loop blocks |
| `licm` | fixture-equivalent for listed fixtures | Hoists pure scalar invariant instructions to an existing preheader |
| `loop-simplifycfg` | LLVM-shaped subset | Constant loop-local branch folding and simple loop-block merging for accepted LCSSA/preheader/dedicated-exit loops |
| `loop-rotate` | placeholder | Deferred until loop-shape invariants and phi rewrites are robust |
| `simple-loop-unswitch` | placeholder | Deferred until branch duplication and dominance updates are robust |
| `loop-unroll` | placeholder | Deferred until trip-count proof and code-size policy exist |
| loop vectorization | out of scope | Requires LoopAccessAnalysis, SCEV, TTI, vector IR, and target lowering |

## LICM Legality

Local LICM can hoist only instructions that satisfy all of these checks:

```text
the loop has one current NaturalLoop record for the header
the loop has an existing unconditional preheader
the preheader dominates the loop header
the instruction is side-effect-free
the instruction is safe to execute speculatively
all operands are loop invariant
the preheader definition dominates all uses after the move
```

Loads, stores, calls, atomics, volatile operations, trapping division, and
unknown memory operations remain non-hoistable.

## Missing LLVM Analyses

These LLVM analyses are intentionally not reproduced yet and remain blockers
for broader loop optimization:

```text
ScalarEvolution: trip counts, induction variables, deletion, unroll decisions
LoopAccessAnalysis: vectorization and memory dependence in loops
MemorySSA: memory LICM, memory sinking, loop deletion legality
TargetTransformInfo: rotate, unroll, vectorization, and profitability decisions
BlockFrequencyInfo/ProfileSummaryInfo: profile-guided loop profitability
AssumptionCache: condition and range facts used by simplification and LICM
```

## Fixture Coverage

```text
opt-22 compared:
  licm_invariant
  licm_variant_operand
  licm_dominates_uses
  licm_scalar_with_memory

local-only conservative:
  no-preheader LICM rejection
  memory load/store LICM rejection
  aligned-load LICM rejection
  trapping-division LICM rejection
  atomic/volatile memory barrier preservation
  multi-latch LICM rejection

unit-test only:
  LoopInfo helper API coverage
  LCSSA-form check for outside loop uses
  loop pass pipeline dispatch
```
