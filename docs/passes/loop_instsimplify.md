# loop-instsimplify

LLVM reference:

```text
llvm-project-22/llvm/lib/Transforms/Scalar/LoopInstSimplify.cpp
```

`loop-instsimplify` applies instruction simplification to instructions inside
recognized loops. It is a loop-local cleanup pass that relies on LoopInfo shape
instead of scanning the whole function as a generic scalar pass.

## LLVM Algorithm Contract

```text
LLVM source file:
  llvm-project-22/llvm/lib/Transforms/Scalar/LoopInstSimplify.cpp

LLVM entry points/classes:
  LoopInstSimplifyPass::run
  simplifyLoopInst
  InstructionSimplify

Required analyses:
  LoopInfo.
  DominatorTree and AssumptionCache in LLVM's richer implementation.

Required IR invariants:
  Verified SSA.
  Loop membership must come from LoopInfo natural-loop discovery.

Core LLVM algorithm data structures:
  Loop block traversal.
  InstructionSimplify query helpers.
  Replacement of simplified loop-local instruction uses.

Local target status:
  LLVM-shaped algorithm subset.
```

Implemented subset:

```text
build LoopInfo for each function
collect all blocks that are members of recognized natural loops
run the local InstSimplify helper on instructions in those blocks
rewrite later operands and terminator conditions through folded aliases
```

Intentional divergences:

```text
no LCSSA, MemorySSA, AssumptionCache, or target-library queries
no loop pass manager adaptor; this is a module pass that uses LoopInfo
no edge-sensitive undef/poison reasoning beyond the existing InstSimplify subset
```

Fixture coverage:

```text
opt-22 equivalent:
  none currently

local-only conservative:
  none currently

unit-test only:
  release-o3 pipeline inclusion and pass dispatch
```
