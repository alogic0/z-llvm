# Codegen-Prep And Library-Call Placeholders

LLVM references:

```text
llvm-project-22/llvm/lib/Transforms/Scalar/LowerExpectIntrinsic.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/DivRemPairs.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/Float2Int.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/TailRecursionElimination.cpp
llvm-project-22/llvm/lib/Transforms/Utils/LibCallsShrinkWrap.cpp
llvm-project-22/llvm/lib/Transforms/Utils/InjectTLIMappings.cpp
llvm-project-22/llvm/lib/Transforms/Utils/RelLookupTableConverter.cpp
```

These passes prepare scalar IR for target lowering and library-call expansion.
They require target cost, ABI, and TargetLibraryInfo facts before they can
faithfully reproduce LLVM behavior.

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Transforms/Scalar/LowerExpectIntrinsic.cpp
  llvm-project-22/llvm/lib/Transforms/Scalar/DivRemPairs.cpp
  llvm-project-22/llvm/lib/Transforms/Scalar/TailRecursionElimination.cpp
  llvm-project-22/llvm/lib/Transforms/Utils/LibCallsShrinkWrap.cpp

LLVM entry points/classes:
  LowerExpectIntrinsicPass::run
  DivRemPairsPass::run
  TailCallElimPass::run
  LibCallsShrinkWrapPass::run

Required analyses:
  TargetLibraryInfo.
  TargetTransformInfo.
  DominatorTree and LoopInfo for some rewrites.
  ABI and call-lowering constraints for tail calls.

Required IR invariants:
  Branch weight/profile metadata must remain valid after expect lowering.
  Div/rem pairing must match target operation legality and cost.
  Tail call elimination must preserve ABI and stack-frame semantics.
  Library-call transforms must only use target-available libcalls.

Core LLVM algorithm data structures:
  TargetLibraryInfo libcall table.
  Target cost queries.
  Call and return pattern matching.
  Profile metadata rewrites.

Local target status:
  TargetLibraryInfo foundation, lower-expect i1 branch metadata and scalar
  integer passthrough slices, and executable placeholders for the remaining
  codegen-prep passes.
```

Implemented subset:

```text
lower-expect:
  direct `llvm.expect.i1` calls feeding a same-block conditional branch are
  replaced with their first operand, and the branch receives default
  `!prof !{!"branch_weights", !"expected", i32 2000, i32 1}` metadata when
  the expected value is true, or the inverse weights when it is false.
  Non-branch scalar integer `llvm.expect.iN` calls are replaced with their
  first operand.

div-rem-pairs, float2int, tailcallelim, libcalls-shrinkwrap,
inject-tli-mappings, and rel-lookup-table-converter remain executable
placeholders.
```

Intentional divergences:

```text
no `llvm.expect.with.probability`
no `llvm.expect` switch/select/phi handling
no existing profile metadata merge policy
no div/rem pairing
no floating-point IR legality
no tail recursion elimination
no libcall shrink wrapping or vector library mapping
```

Fixture coverage:

```text
opt-22 equivalent:
  lower_expect_i1_branch
  lower_expect_i32_preserve

unit-test only:
  placeholder pass dispatch and TargetLibraryInfo lookup
```
