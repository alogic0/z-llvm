# Scalar IR

LLVM references:

```text
llvm-project-22/llvm/include/llvm/IR/Instruction.def
llvm-project-22/llvm/include/llvm/IR/Instructions.h
llvm-project-22/llvm/lib/IR/AsmWriter.cpp
llvm-project-22/llvm/lib/AsmParser/LLParser.cpp
```

Upstream entry points to check:

```text
BinaryOperator
CastInst
TruncInst
ZExtInst
SExtInst
FreezeInst
Instruction::hasNoSignedWrap
Instruction::hasNoUnsignedWrap
PossiblyExactOperator::isExact
```

Implemented subset:

```text
integer binary ops: add/sub/mul/and/or/xor/shl/lshr/ashr/udiv/sdiv/urem/srem
floating-point binary ops: fadd for scalar float/double parse/verify only
integer casts: trunc, zext, sext
freeze for scalar integer values
binary instruction flags parsed and printed: nsw, nuw, exact
verifier rejects pointer binary ops, pointer casts, invalid cast widths, and invalid flag/op combinations
```

Upstream mapping:

```text
This reproduces the textual IR surface and verifier shape for a small scalar integer subset.
LLVM attaches flags to specific operator classes and uses poison/undef/freeze semantics when simplifying them.
This project preserves flags for round-tripping but does not use them as optimization facts yet.
```

Fixture coverage:

```text
opt-22 equivalent:
  scalar_ir_surface

local-only conservative:
  flagged arithmetic and division are intentionally not folded by instcombine yet

unit-test only:
  parser/printer/verifier round-trip for casts, div/rem, flags, and freeze
  parser/printer/verifier round-trip for scalar float/double fadd and select
  parser rejection for unsupported fmul/fcmp
  instcombine no-fold behavior for flagged add and division
```

Known gaps:

```text
no vectors
no pointer casts
no bitcast/ptrtoint/inttoptr
no floating-point optimization parity
no fmul/fsub/fdiv/frem/fcmp or fast-math flag surface
no poison value
no use of nsw/nuw/exact as optimization facts
no division/remainder constant folding
no target DataLayout-driven legality
```
