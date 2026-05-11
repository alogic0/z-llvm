# instcombine

LLVM reference:

```text
llvm-project-22/llvm/lib/Transforms/InstCombine/
```

Upstream entry points to check:

```text
InstCombinePass::run
InstructionCombiningPass
InstCombinerImpl::canonicalizeOperands
InstCombinerImpl::visitAdd
InstCombinerImpl::visitSub
InstCombinerImpl::visitMul
InstCombinerImpl::visitAnd
InstCombinerImpl::visitOr
InstCombinerImpl::visitXor
InstCombinerImpl::visitShl
InstCombinerImpl::visitLShr
InstCombinerImpl::visitAShr
InstCombinerImpl::visitUDiv
InstCombinerImpl::visitSDiv
InstCombinerImpl::visitURem
InstCombinerImpl::visitSRem
InstCombinerImpl::visitTrunc
InstCombinerImpl::visitZExt
InstCombinerImpl::visitSExt
InstCombinerImpl::visitICmpInst
InstCombinerImpl::visitSelectInst
InstructionSimplify helpers used by InstCombine
```

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Transforms/InstCombine/
  llvm-project-22/llvm/lib/Transforms/AggressiveInstCombine/
  llvm-project-22/llvm/lib/Analysis/InstructionSimplify.cpp

LLVM entry points/classes:
  InstCombinePass::run
  InstCombinerImpl::run
  InstCombinerImpl::canonicalizeOperands
  AggressiveInstCombinePass

Required analyses:
  None for the implemented local subset.

Required IR invariants:
  Verified scalar integer IR with valid SSA dominance and PHI structure.

Core LLVM algorithm data structures:
  Worklist-style instruction combining
  InstructionSimplify query helpers
  Operand canonicalization for commutative instructions
  Conservative poison/undef/freeze refusal rules

Local target status:
  fixture-equivalent for listed fixtures

Implemented subset:
  Local instruction scan with alias replacement
  Arithmetic, bitwise, shift, cast, ICmp, select, div/rem, and freeze-constant
  scalar simplifications delegated to the InstSimplify helper
  Constant-on-RHS canonicalization for supported commutative binary ops

Intentional divergences:
  The local pass is a linear scan, not LLVM's full fixed-point worklist.
  Selected mode pipelines repeat InstCombine and SimplifyCFG to model the
  repeated canonicalization shape used by LLVM.
  AggressiveInstCombine is an explicit placeholder until concrete rules are
  implemented.

Analysis preservation/invalidation:
  InstCombine mutates IR and invalidates analyses under the local pass-manager
  policy. The pass manager verifies after execution.

Fixture coverage:
  instcombine
  instcombine_bitwise
  instcombine_icmp_rel
  instcombine_commute
  instcombine_scalar_simplify
  instcombine_safe_scalar
  select_fold
  fp_instcombine_preserve
  fp_extended_instcombine_preserve

opt-22 comparison command:
  bash scripts/compare_opt.sh

Local-only fixture command:
  zig build test
```

This pass canonicalizes and folds simple instructions. The first Zig implementation is intentionally small and covers only enough behavior to prove the pass infrastructure and LLVM-compatible IR comparison loop.

Implemented subset:

```text
x + 0 -> x
0 + x -> x
commutative binary constants on the LHS are swapped to the RHS
x - 0 -> x
x * 1 -> x
1 * x -> x
x * 0 -> 0
0 * x -> 0
integer constant folding for add/sub/mul
integer constant folding for and/or/xor
x & 0 -> 0
x & -1 -> x
x & x -> x
x | 0 -> x
x | x -> x
x ^ 0 -> x
x ^ x -> 0
x << 0 -> x
x >> 0 -> x for logical and arithmetic shift
0 << x -> 0
0 >> x -> 0 for logical and arithmetic shift
icmp eq/ne constant folding
icmp eq/ne same-operand folding
icmp signed and unsigned relational constant folding
icmp signed and unsigned relational same-operand folding
select constant-condition folding
select identical-arm folding
preserve `nsw`, `nuw`, and `exact` flags without using them for folds
constant `trunc`, `zext`, and `sext` folding for integer constants
defined constant `udiv`, `sdiv`, `urem`, and `srem` folding
safe variable div/rem identities: x / 1 -> x and x % 1 -> 0
freeze of an integer constant -> that same constant
preserve `freeze` instructions
```

Upstream mapping:

```text
This reproduces a small identity-folding and constant-folding subset of InstCombine.
LLVM's InstCombine is much broader: flags, poison semantics, canonicalization, reassociation, casts, vectors, division/remainder transforms, and target-specific combines all matter upstream.
The current implementation deliberately avoids using `nsw`, `nuw`, `exact`, division/remainder, or freeze facts for simplification.
Floating-point `fadd`, `fsub`, `fmul`, `fdiv`, `frem`, and `fcmp` are preserved rather than folded
because fast-math, NaN, signed-zero, and FP constant semantics are not modeled.
Common local folds now live in [inst_simplify.md](inst_simplify.md) so GVN and EarlyCSE can share scalar expression equivalence with InstCombine.
```

Example:

```text
before:
  %x = add i32 %a, 0
  %y = mul i32 %x, 1
  ret i32 %y

after instcombine + dce:
  ret i32 %a
```

Known gaps:

```text
no use of nsw/nuw/exact for folds
no poison/undef simplification
no non-constant freeze simplification
no vector folds; fixed-vector IR is parser/verifier-only and excluded from
InstCombine equivalence claims
no width-aware constant folding for non-zero shifts
no demanded-bits cleanup in InstCombine; the first source-backed integer mask
quality case is implemented in the separate `bdce` pass
unsigned constant folding is limited to integer widths below 128 bits
no non-constant cast simplification yet
no unsafe division/remainder simplification
no canonical reassociation
no non-constant operand complexity ordering
no floating-point folds or reassociation
no target-specific combines
```
