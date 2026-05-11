# AIR And Liveness Handoff

This note maps accepted optimized LLVM-compatible IR shapes to the Zig-native
concepts they validate. It is not a request to copy LLVM IR into Zig's native
backend. The goal is to identify which facts should survive as AIR, Liveness,
or target-lowering inputs.

## Source Anchors

```text
ziglang/src/Air.zig
ziglang/src/Liveness.zig
ziglang/src/arch/
z_llvm/src/codegen/
z_llvm/src/mc/
```

## Accepted Handoff Facts

| Local optimized IR shape | Zig-native concept | Handoff use |
| --- | --- | --- |
| Scalar integer return after InstCombine/DCE | AIR value plus function return lowering | Validates that safe scalar folds can happen before native instruction selection. |
| Direct scalar call | AIR call instruction plus calling convention lowering | Validates argument register assignment and call result use without modeling LLVM call-site metadata. |
| Fixed stack slot after memory cleanup | AIR allocation/liveness plus frame slot assignment | Validates that stack locations are explicit by backend handoff time, without adopting LLVM alloca promotion as the native model. |
| Branch-pruned scalar CFG | AIR control-flow plus Liveness reachability | Validates that unreachable local work is removed before backend lowering when proven safe. |
| Loop-invariant scalar chain | AIR loop body values plus Liveness ranges | Validates pure scalar loop facts while keeping memory LICM out of native handoff until alias precision improves. |

## Facts That Should Disappear

```text
LLVM PHI node spelling
LLVM alloca and mem2reg mechanics
LLVM GEP slice mechanics
LLVM pass names and pass-order assumptions
opaque metadata used only to satisfy LLVM's verifier
```

## Current Validation Cases

```text
bash scripts/run_handoff_validation.sh
```

The script checks:

```text
return_constant: scalar return lowering
call_one_arg: direct scalar call lowering
stack_slot: fixed stack-slot lowering
compare_codegen_asm.sh: full current tiny x86_64 assembly smoke matrix
```

## Boundary

Register allocation, instruction scheduling, target-cost modeling, debug/unwind
emission, and object/linker ownership remain outside this handoff cycle. They
should be added only when a source-backed Zig fixture requires that level of
backend validation.
