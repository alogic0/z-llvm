# Testing

The replacement uses LLVM-compatible normalized IR as its first debugging contract.

The comparison loop is:

```text
input LLVM-compatible IR
  -> parse into z_llvm IR
  -> run selected z_llvm passes
  -> print normalized LLVM-compatible IR
  -> compare against a golden file or LLVM `opt` output
```

The first golden comparison covers the implemented `instcombine` and `dce` subsets:

```text
test/inputs/instcombine.ll
test/expected/instcombine_dce.ll
```

LLVM `opt` comparison fixtures live under:

```text
test/opt/inputs/
test/opt/expected/z_llvm/
```

Use these to compare each reproduced pass with the matching LLVM pass when `opt` is installed:

```bash
opt -passes=instcombine test/opt/inputs/instcombine.ll -S -o /tmp/llvm_instcombine.ll
opt -passes=dce test/opt/inputs/dce.ll -S -o /tmp/llvm_dce.ll
opt -passes=simplifycfg test/opt/inputs/simplifycfg.ll -S -o /tmp/llvm_simplifycfg.ll
```

LLVM algorithms covered so far:

```text
InstCombine: identity arithmetic and integer constant folding subset
DCE: unused pure add/sub/mul removal subset
SimplifyCFG: constant branch folding and unreachable block removal subset
```

Exact byte-for-byte matching with LLVM is not the long-term contract. The normalized form should make semantic differences visible while ignoring harmless formatting differences.
