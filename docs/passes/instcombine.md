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
preserve `freeze` instructions
```

Upstream mapping:

```text
This reproduces a small identity-folding and constant-folding subset of InstCombine.
LLVM's InstCombine is much broader: flags, poison semantics, canonicalization, reassociation, casts, vectors, division/remainder transforms, and target-specific combines all matter upstream.
The current implementation deliberately avoids using `nsw`, `nuw`, `exact`, division/remainder, or freeze facts for simplification.
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
no poison/undef/freeze simplification
no vectors
no width-aware constant folding for non-zero shifts
unsigned constant folding is limited to integer widths below 128 bits
no non-constant cast simplification yet
no unsafe division/remainder simplification
no canonical reassociation
no non-constant operand complexity ordering
no target-specific combines
```
