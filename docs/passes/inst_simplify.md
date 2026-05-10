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

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/include/llvm/Analysis/InstructionSimplify.h
  llvm-project-22/llvm/lib/Analysis/InstructionSimplify.cpp

LLVM entry points/classes:
  simplifyInstruction
  simplifyBinOp
  simplifyCastInst
  simplifyICmpInst
  simplifySelectInst

Required analyses:
  None for the implemented local subset.

Required IR invariants:
  The verifier has accepted operand types, SSA dominance, and phi structure.

Core LLVM algorithm data structures:
  Query-style simplification over Instruction and Value operands
  Constant folding for integer constants
  Predicate-specific ICmp simplification
  Poison/undef/freeze-aware refusal rules

Local target status:
  LLVM-shaped algorithm subset

Implemented subset:
  Integer identity folds
  Integer constant folds for defined operations
  Cast folds for integer constants
  ICmp constant and same-operand folds
  Select constant-condition and identical-arm folds
  Freeze of integer constants

Intentional divergences:
  No DataLayout, KnownBits, AssumptionCache, DominatorTree, target-library, or
  vector reasoning.
  `undef` and non-constant `freeze` are preserved because full poison/undef
  semantics are not modeled.

Analysis preservation/invalidation:
  This helper does not mutate IR. Mutating users such as InstCombine invalidate
  analyses through the pass manager's conservative policy.

Fixture coverage:
  instcombine_scalar_simplify
  instcombine_safe_scalar
  select_fold

opt-22 comparison command:
  bash scripts/compare_opt.sh

Local-only fixture command:
  zig build test
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
safe variable div/rem identities: x / 1 -> x and x % 1 -> 0
freeze of an integer constant -> that same constant
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
no non-constant freeze simplification
no undef simplification
```
