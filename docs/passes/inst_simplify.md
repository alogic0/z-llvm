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
  fixture-equivalent through listed InstCombine fixtures

Implemented subset:
  Integer identity folds
  Integer constant folds for defined operations
  Checked flagged integer identity and constant folds for local `nuw`/`nsw`
  legality
  Cast folds for integer constants using source-width bit patterns
  ICmp constant and same-operand folds
  Select constant-condition and identical-arm folds
  Freeze of integer constants
  Strict `fcmp false`/`fcmp true` folds
  Strict `fcmp ord`/`fcmp uno` folds for classified scalar FP constants
  `fadd nsz x, +0.0` folds through the shared fast-math legality helper
  `fcmp nnan oeq x, x` folds through the shared fast-math legality helper

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
width-aware zext/sext bitpattern folding for constants such as `zext i8 -1`
and `sext i8 255`
constant udiv/sdiv/urem/srem folding only when the operation is defined in the current integer model
preserve division by zero, signed min / -1, and non-exact exact division cases
safe variable div/rem identities: x / 1 -> x and x % 1 -> 0
selected flagged integer identities when `nuw`, `nsw`, or `exact` does not
change overflow behavior
checked flagged add/sub/mul constants when signed and unsigned overflow cannot
occur in the local bit-width model
preserve flagged integer constants when overflow would be required
freeze of an integer constant -> that same constant
strict fcmp false -> false
strict fcmp true -> true
strict fcmp ord/uno for scalar FP constants classified by fp_semantics
fadd nsz x, +0.0 -> x
fcmp nnan oeq x, x -> true
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
  instcombine_cast_bitpatterns
  instcombine_flagged_identities
  instcombine_flagged_constants
  instcombine_pointer_compare
  fp_strict_fcmp_fold
  fp_fast_math_flags_boundary

local-only conservative:
  instcombine_flagged_overflow_reject preserves a case where LLVM can reason in
  terms of poison, which the local IR does not yet materialize.
  unsafe division cases are preserved in unit tests
  fp_strict_orderedness_fold covers local APFloat-shaped orderedness folds

unit-test only:
  unsafe strict FP identities remain unfused unless a specific safe rule is added later
```

Known gaps:

```text
no DataLayout
no KnownBits
no poison-aware reasoning
no vector simplification
no pointer cast simplification
no general FP arithmetic folding
no fast-math-driven FP simplification beyond the listed nsz/nnan folds
no assumption or dominance-sensitive simplification
no non-constant freeze simplification
no undef simplification
```
