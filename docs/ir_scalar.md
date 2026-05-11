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
floating-point binary ops: fadd/fsub/fmul/fdiv/frem for scalar float/double parse/verify only
floating-point compare: fcmp false/oeq/ogt/oge/olt/ole/one/ord/uno/ueq/ugt/uge/ult/ule/une/true for scalar float/double parse/verify only
floating-point constants: observed decimal spellings plus `nan`, `inf`, and
negative zero are parsed, classified by `analysis/fp_semantics.zig`, verified
against scalar FP types, and printed verbatim
fast-math flags on supported scalar FP binary ops and `fcmp` are parsed,
verified, printed, and ignored by optimizers
strict `fcmp false`/`true` and constant `fcmp ord`/`uno` can be folded by
InstSimplify when no arithmetic, rounding, or exception fact is needed
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
  fp_literal_preserve
  fp_special_literals_preserve
  fp_extended_instcombine_preserve
  fp_extended_dce_preserve
  fp_extended_adce_preserve
  fp_extended_sccp_preserve
  fp_fast_math_preserve
  fp_strict_fcmp_fold

local-only conservative:
  flagged arithmetic and division are intentionally not folded by instcombine yet
  FP literals are classified and preserved but not folded
  fp_extended_gvn_no_cse
  fp_extended_early_cse_no_cse
  fp_strict_sensitive_preserve
  fp_fast_math_sensitive_conservative
  fp_strict_orderedness_fold

unit-test only:
  parser/printer/verifier round-trip for casts, div/rem, flags, and freeze
  parser/printer/verifier round-trip for scalar float/double fadd/fsub/fmul/fdiv/frem, fcmp predicates, and select
  parser/printer/verifier round-trip for observed decimal FP literals
  parser/printer/verifier round-trip and classification for NaN, infinity, and
  signed-zero literal spellings
  parser/verifier rejection for unsupported fcmp predicates, vector FP, invalid fast-math flag placement, and constrained FP calls
  instcombine no-fold behavior for flagged add and division
```

Known gaps:

```text
no scalar optimization over vector instructions; fixed vectors are parsed and
verified only as described in `docs/ir_vectors.md`
no pointer casts
no bitcast/ptrtoint/inttoptr
no floating-point arithmetic optimization parity
no general FP comparison optimization parity beyond strict false/true and
constant ord/uno orderedness
no APFloat-equivalent arithmetic, rounding, exception, or complete bit-pattern
semantic model
no fast-math optimization semantics or FP exception behavior model
no constrained FP intrinsic semantics
no poison value
no use of nsw/nuw/exact as optimization facts
no division/remainder constant folding
no target DataLayout-driven legality
```
