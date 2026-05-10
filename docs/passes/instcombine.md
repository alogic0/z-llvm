# instcombine

LLVM reference:

```text
/home/oleg/prog/llvm-project-22/llvm/lib/Transforms/InstCombine/
```

Upstream entry points to check:

```text
InstCombinePass::run
InstructionCombiningPass
InstCombinerImpl::visitAdd
InstCombinerImpl::visitSub
InstCombinerImpl::visitMul
InstCombinerImpl::visitICmpInst
```

This pass canonicalizes and folds simple instructions. The first Zig implementation is intentionally small and covers only enough behavior to prove the pass infrastructure and LLVM-compatible IR comparison loop.

Implemented subset:

```text
x + 0 -> x
0 + x -> x
x - 0 -> x
x * 1 -> x
1 * x -> x
x * 0 -> 0
0 * x -> 0
integer constant folding for add/sub/mul
icmp eq/ne constant folding
icmp eq/ne same-operand folding
```

Upstream mapping:

```text
This reproduces a tiny identity-folding and constant-folding subset of InstCombine.
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
no icmp predicates other than eq/ne
no casts
no canonical reassociation
no target-specific combines
```
