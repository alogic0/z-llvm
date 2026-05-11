# AIR-Like Lowering Bridge

LLVM and Zig references:

```text
ziglang/src/codegen/llvm/FuncGen.zig
ziglang/src/codegen/llvm.zig
llvm-project-22/llvm/include/llvm/IR/IRBuilder.h
llvm-project-22/llvm/lib/IR/Instructions.cpp
```

Upstream entry points to check:

```text
FuncGen.airAdd
FuncGen.airSub
FuncGen.airMul
FuncGen.airShl
FuncGen.airShr
FuncGen.airBitAnd
FuncGen.airBitOr
FuncGen.airBitXor
FuncGen.airIntCast
FuncGen.airCmp
FuncGen.airLoop
FuncGen.airRet
FuncGen.airBr
FuncGen.airCondBr
FuncGen.airUnreach
FuncGen.airAlloc
FuncGen.airLoad
FuncGen.airStore
FuncGen.airPtrElemPtr
FuncGen.airRetLoad
FuncGen.resolveInst
IRBuilderBase::CreateAdd
IRBuilderBase::CreateRet
IRBuilderBase::CreateAlloca
IRBuilderBase::CreateLoad
IRBuilderBase::CreateStore
IRBuilderBase::CreateGEP
IRBuilderBase::CreateICmp
PHINode::Create
```

Implemented subset:

```text
test/helper builder, not a text input language
module source_filename, target triple, and datalayout preservation
helper driver for pre-optimization IR, named pipeline execution, and post-optimization IR
one-entry-block functions
explicit basic blocks
scalar integer parameters
scalar integer binary operations
scalar integer casts: trunc, zext, sext
scalar integer comparisons
phi nodes
scalar stack memory: alloca, load, store, getelementptr
return, branch, conditional branch, and unreachable terminators
canonical loop shape: preheader, header, body, latch, exit
```

Upstream mapping:

```text
Zig lowers analyzed AIR instructions through FuncGen into LLVM IRBuilder calls.
This project now has a tiny builder that can construct the same project IR shape for scalar arithmetic examples without invoking the full Zig compiler.
Stack memory lowering maps directly onto the existing LLVM-compatible alloca/load/store/GEP project IR surface; alias analysis, SROA, and mem2reg behavior remain owned by the existing passes.
Loop lowering emits the canonical shape required by the local LoopInfo and LICM foundation: a single preheader branch into a header, a single latch backedge, and a distinct exit block.
The bridge is deliberately synthetic so optimizer and target tests can reduce failures to small inputs.
The helper driver reuses the existing pass manager and pipeline registry; it is not a second optimizer path.
```

Native backend handoff classification:

```text
handoff study: this bridge models AIR-shaped inputs enough to connect local optimizer facts to Zig-owned AIR/native-backend concepts
not a backend replacement: the bridge does not parse real Zig AIR, own Liveness, or produce Zig MIR
handoff doc: docs/codegen/zig_native_backend_handoff.md
```

Fixture coverage:

```text
opt-22 equivalent:
  none currently

local-only conservative:
  none currently

unit-test only:
  scalar add function with two i32 parameters and an SSA return
  scalar sub/and/shl arithmetic with zext return
  conditional branch to return and unreachable blocks
  scalar stack slot with aligned store/load
  scalar zero-index GEP from a stack slot
  canonical loop shape accepted by LoopInfo preheader, latch, exiting block, and exit block queries
  memory-foundation pipeline turns an AIR-like stack slot into a scalar return
  target triple and datalayout preservation on lowered modules
```

Known gaps:

```text
no AIR text parser
no standalone AIR bridge CLI mode
no full Zig AIR semantics
no LoopSimplify or LCSSA insertion
no multi-latch loops
no calls
no select, overflow operations, or intrinsics
no aggregate, optional, error-union, async, comptime, or debug-info lowering
```
