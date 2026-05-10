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

Use these to compare each reproduced pass with the matching LLVM pass when `opt` is installed.
The current development environment uses versioned LLVM 22 commands; see [environment.md](environment.md).

```bash
opt-22 -passes=instcombine test/opt/inputs/instcombine.ll -S -o /tmp/llvm_instcombine.ll
opt-22 -passes=dce test/opt/inputs/dce.ll -S -o /tmp/llvm_dce.ll
opt-22 -passes=adce test/opt/inputs/adce_chain.ll -S -o /tmp/llvm_adce.ll
opt-22 -passes=gvn test/opt/inputs/gvn_dominating_expr.ll -S -o /tmp/llvm_gvn.ll
opt-22 -passes='loop-mssa(licm)' test/opt/inputs/licm_invariant.ll -S -o /tmp/llvm_licm.ll
opt-22 -passes=sroa test/opt/inputs/sroa_zero_gep.ll -S -o /tmp/llvm_sroa.ll
opt-22 -passes=simplifycfg test/opt/inputs/simplifycfg.ll -S -o /tmp/llvm_simplifycfg.ll
```

Run all currently mapped LLVM comparisons:

```bash
bash scripts/compare_opt.sh
```

Use a different `opt` binary:

```bash
OPT_BIN=opt bash scripts/compare_opt.sh
```

LLVM algorithms covered so far:

```text
InstCombine: arithmetic, bitwise, shift, select, relational icmp, and commutative canonicalization subsets
DCE: unused pure instruction removal subset
ADCE: unused side-effect-free instruction chain removal subset
SimplifyCFG: constant branch folding, unreachable block removal, phi cleanup, block merge, and empty-block threading subsets
EarlyCSE: same-block repeated pure-expression elimination subset
Mem2Reg: single-block, multi-block, undef, and multi-slot stack promotion subsets
SROA: zero-offset GEP alloca forwarding subset
GVN: dominating repeated pure-expression elimination subset
LoopInfo: natural-loop, preheader, and exit-block analysis subset
LICM: pure loop-invariant instruction hoisting subset
```

Exact byte-for-byte matching with LLVM is not the long-term contract. The normalized form should make semantic differences visible while ignoring harmless formatting differences.
