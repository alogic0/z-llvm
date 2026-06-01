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
  Target-independent identical-arm folding for vector-valued selects with a
  scalar `i1` condition
  Freeze of integer constants
  Strict `fcmp false`/`fcmp true` folds
  Strict `fcmp ord`/`fcmp uno` folds for classified scalar FP constants
  Strict `fsub x, +0.0`, `fmul x, 1.0`, and `fdiv x, 1.0` identity folds
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
  vector_select_same_arms

opt-22 comparison command:
  zig build compare-opt --

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
flagged add/sub/mul and in-range shift constants fold to the APInt-wrapped
integer result, matching LLVM's constant-folding spelling for the covered
scalar widths
constant shifts with counts outside the type bit width fold to `poison`
freeze of an integer constant -> that same constant
strict fcmp false -> false
strict fcmp true -> true
strict fcmp ord/uno for scalar FP constants classified by fp_semantics
strict fsub x, +0.0 -> x
strict fmul x, 1.0 -> x
strict fdiv x, 1.0 -> x
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
  instcombine_flagged_shl_constants
  instcombine_shift_constants
  instcombine_shift_oversized_poison
  instcombine_pointer_compare
  fp_strict_sensitive_preserve
  fp_strict_fcmp_fold
  fp_fast_math_flags_boundary
  fp_fast_math_sensitive_conservative

local-only conservative:
  unsafe division cases are preserved in unit tests
  fp_strict_orderedness_fold covers local APFloat-shaped orderedness folds

unit-test only:
  unsafe strict FP identities remain unfused unless a specific safe rule is added later
```

Known gaps:

```text
no DataLayout
no KnownBits
no poison-aware reasoning beyond oversized constant shifts
no vector simplification beyond scalar-condition identical-arm vector selects
no pointer cast simplification
no general FP arithmetic folding
no fast-math-driven FP simplification beyond the listed nsz/nnan folds
no assumption or dominance-sensitive simplification
no non-constant freeze simplification
no undef simplification
```
