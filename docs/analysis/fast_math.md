# Fast-Math Legality

LLVM references:

```text
llvm-project-22/llvm/include/llvm/IR/InstrTypes.h
llvm-project-22/llvm/include/llvm/IR/Operator.h
llvm-project-22/llvm/lib/Analysis/InstructionSimplify.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/EarlyCSE.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/GVN.cpp
```

## LLVM Mapping

LLVM stores floating-point optimization facts in `FastMathFlags`. The local
`src/analysis/fast_math.zig` helper maps the accepted textual flags to explicit
legality predicates:

```text
fast or nnan      -> no NaNs
fast or ninf      -> no infinities
fast or nsz       -> no signed-zero distinction
fast or arcp      -> reciprocal transforms may be legal later
fast or contract  -> contraction may be legal later
fast or afn       -> approximate library functions may be legal later
fast or reassoc   -> reassociation may be legal later
all scalar non-constrained FP ops -> local FP value numbering/CSE candidates
```

The first enabled folds are deliberately narrow:

```text
fadd nsz x, +0.0 -> x
fcmp nnan oeq x, x -> true
```

GVN and EarlyCSE follow LLVM's expression-key shape for the accepted local
surface: scalar non-constrained FP binary ops and `fcmp` are value-numbered by
opcode, type, predicate where present, and operands. Fast-math flags do not make
two otherwise identical expressions different. When a redundant FP expression is
removed, the retained leader intersects its fast-math flags with the removed
instruction, matching LLVM EarlyCSE's `combineIRFlags` category and GVN's
flag-insensitive expression numbering behavior.

## Fixture Coverage

```text
fp_fast_math_flags_boundary: checks nnan, ninf, nsz, reassoc, arcp, contract,
afn, and fast flag handling through InstCombine/DCE.
fp_fast_gvn: GVN admits repeated `fadd fast` expressions.
fp_gvn_flags: GVN admits strict, partial-FMF, and mixed-FMF scalar FP
expressions and intersects the retained leader flags.
fp_early_cse_flags: EarlyCSE admits strict, partial-FMF, and mixed-FMF scalar
FP expressions and intersects the retained leader flags.
fp_fast_early_cse: EarlyCSE admits repeated `fadd fast` expressions; local
result naming differs from opt-22.
```

## Gaps

```text
no reassociation transforms
no reciprocal expansion or contraction lowering
no approximate-function transforms
no target-cost-sensitive FP transforms
no constrained-FP intrinsic, dynamic-rounding, or strict-exception model
no vector FP fast-math transforms
no commuted FP CSE beyond exact operand order
```
