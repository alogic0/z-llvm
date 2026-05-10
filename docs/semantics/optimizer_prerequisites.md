# Optimizer Semantic Prerequisites

This file records the semantic boundary required before local optimization
passes are marked complete in the roadmap.

## Integer Overflow And Exact Flags

LLVM references:

```text
llvm-project-22/llvm/include/llvm/IR/Operator.h
llvm-project-22/llvm/lib/Analysis/InstructionSimplify.cpp
llvm-project-22/llvm/lib/Transforms/InstCombine/
```

Local policy:

```text
nsw, nuw, and exact are preserved by parser/printer.
constant folds refuse overflow-flagged binary instructions unless the local
fold explicitly proves the flag condition.
identity folds refuse nsw/nuw/exact when dropping the operation would hide a
modeled overflow or exactness condition.
exact div/rem constant folds require exact divisibility.
```

## DataLayout Sizes And Offsets

LLVM references:

```text
llvm-project-22/llvm/include/llvm/IR/DataLayout.h
llvm-project-22/llvm/lib/Analysis/MemoryLocation.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/SROA.cpp
```

Local policy:

```text
DataLayout records are parsed and preserved.
Pointer and integer ABI alignments are queryable for supported target records.
MemoryLocation computes only scalar integer sizes and simple GEP-derived offsets.
SROA and alias analysis remain conservative when type size or offset is unknown.
```

## Target-Independent Versus Target-Aware Folds

LLVM references:

```text
llvm-project-22/llvm/include/llvm/Analysis/TargetTransformInfo.h
llvm-project-22/llvm/include/llvm/Analysis/TargetLibraryInfo.h
```

Local policy:

```text
InstSimplify and InstCombine folds are target-independent unless the pass doc
explicitly names TargetLibraryInfo or target DataLayout input.
TargetLibraryInfo currently exposes only a minimal libcall availability table.
Cost-based rewrites remain placeholders until TargetTransformInfo-like facts
exist.
```

## Memory Barriers

LLVM references:

```text
llvm-project-22/llvm/include/llvm/IR/Instruction.h
llvm-project-22/llvm/include/llvm/Analysis/AliasAnalysis.h
llvm-project-22/llvm/lib/Analysis/MemorySSA.cpp
```

Local policy:

```text
volatile and atomic loads/stores are barriers.
unknown calls are mod/ref barriers.
readnone calls may be treated as no memory effect by call attribute analysis.
readonly calls may be treated as readonly memory by call attribute analysis.
load CSE is allowed only when alias/mod-ref proves no clobber in the local
supported region.
```

Fixture coverage:

```text
opt-22 equivalent:
  scalar flag preservation, memory barrier DCE/GVN/LICM/DSE fixtures

local-only conservative:
  volatile/atomic rejection and unknown-memory rejection tests

unit-test only:
  target DataLayout, TargetLibraryInfo, MemoryLocation, and alias/mod-ref tests
```
