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
InstCombinerImpl::visitICmpInst
InstCombinerImpl::visitSelectInst
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
```

Upstream mapping:

```text
This reproduces a small identity-folding and constant-folding subset of InstCombine.
LLVM's InstCombine is much broader: flags, poison semantics, canonicalization, reassociation, casts, vectors, and target-specific combines all matter upstream.
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
no flags such as nsw/nuw/exact
no poison/undef/freeze handling
no vectors
no width-aware constant folding for non-zero shifts
unsigned constant folding is limited to integer widths below 128 bits
no casts
no canonical reassociation
no non-constant operand complexity ordering
no target-specific combines
```
