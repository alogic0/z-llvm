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
fast              -> local FP value numbering/CSE boundary
```

The first enabled folds are deliberately narrow:

```text
fadd nsz x, +0.0 -> x
fcmp nnan oeq x, x -> true
```

GVN and EarlyCSE only admit FP expressions when the instruction has `fast`.
That is more conservative than LLVM, but it keeps exception, rounding, and
signed-zero behavior out of value numbering until those models exist.

## Fixture Coverage

```text
fp_fast_math_flags_boundary: checks nnan, ninf, nsz, reassoc, arcp, contract,
afn, and fast flag handling through InstCombine/DCE.
fp_fast_gvn: GVN admits repeated `fadd fast` expressions.
fp_fast_early_cse: EarlyCSE admits repeated `fadd fast` expressions; local
result naming differs from opt-22.
```

## Gaps

```text
no reassociation transforms
no reciprocal expansion or contraction lowering
no approximate-function transforms
no target-cost-sensitive FP transforms
no FP exception or rounding-mode model
no vector FP fast-math transforms
```
