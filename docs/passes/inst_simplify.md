# InstSimplify Helper

LLVM references:

```text
llvm-project-22/llvm/include/llvm/Analysis/InstructionSimplify.h
llvm-project-22/llvm/lib/Analysis/InstructionSimplify.cpp
llvm-project-22/llvm/lib/Transforms/InstCombine/InstructionCombining.cpp
```

Upstream entry points to check:

```text
simplifyInstruction
simplifyBinOp
simplifyCastInst
simplifyICmpInst
simplifySelectInst
InstCombinerImpl::run
```

Implemented subset:

```text
shared scalar simplification helper used by instcombine
shared scalar expression equivalence helper used by GVN and EarlyCSE
commutative binary constant-on-RHS canonicalization helper
existing arithmetic/bitwise/shift/select/icmp folds moved out of instcombine
constant trunc/zext/sext folding for integer constants when no target layout is needed
constant udiv/sdiv/urem/srem folding only when the operation is defined in the current integer model
preserve division by zero, signed min / -1, and non-exact exact division cases
```

Upstream mapping:

```text
LLVM's InstructionSimplify is a shared query layer used by many transforms.
It reasons with DataLayout, DominatorTree, AssumptionCache, KnownBits, poison, freeze, and target/library information.
This helper only centralizes local scalar rewrites that are already safe in the current IR subset.
```

Fixture coverage:

```text
opt-22 equivalent:
  instcombine_scalar_simplify

local-only conservative:
  unsafe division cases are preserved in unit tests

unit-test only:
  flagged arithmetic remains unfused unless a specific safe rule is added later
```

Known gaps:

```text
no DataLayout
no KnownBits
no poison-aware reasoning
no vector simplification
no pointer cast simplification
no assumption or dominance-sensitive simplification
no freeze simplification
```
