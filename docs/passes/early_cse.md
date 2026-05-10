# early-cse

LLVM reference:

```text
/home/oleg/prog/llvm-project-22/llvm/lib/Transforms/Scalar/EarlyCSE.cpp
```

Early CSE removes redundant computations early in the scalar optimization pipeline.

Implemented subset:

```text
same-basic-block common subexpression elimination
pure add/sub/mul expression matching
pure icmp eq/ne expression matching
later uses in the same block are rewritten to the earlier value
```

Example:

```text
before:
  %x = add i32 %a, 1
  %y = add i32 %a, 1
  ret i32 %y

after early-cse:
  %x = add i32 %a, 1
  ret i32 %x
```

Known gaps:

```text
no dominator-tree walk yet
no memory value numbering
no load CSE
no commutative operand canonicalization
no control-flow-aware replacement
no target-library knowledge
no debug-info salvage
```
