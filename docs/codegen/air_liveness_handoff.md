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

## Optimizer-To-AIR Mapping

| Local optimizer result | Zig-owned equivalent | Handoff note |
| --- | --- | --- |
| InstSimplify/InstCombine scalar identities | Sema/AIR scalar canonicalization or target instruction selection peepholes | Backend-neutral when integer flags, poison, FP, and target-cost boundaries are explicit. |
| Mem2Reg promoted entry allocas | AIR values plus Liveness death facts | Useful as a stack-traffic expectation, but native codegen does not need LLVM allocas or PHIs. |
| SROA zero-GEP and small aggregate splitting | AIR aggregate field access or source-level aggregate decomposition | Treat as a semantic comparison only; do not require LLVM GEP slicing in Zig-owned IR. |
| SimplifyCFG/SCCP branch pruning | AIR block reachability and branch lowering | Backend-neutral when the pruned edge is proven unreachable without profile-only assumptions. |
| DCE/ADCE removed pure operations | Liveness unreferenced instruction facts | Backend-neutral when side-effect and may-throw classification is shared. |
| DSE removed overwritten stores | Frame-slot or memory-location liveness | Requires explicit alias/mod-ref proof before mapping to native stack slots. |
| GVN/EarlyCSE repeated integer expressions | Optional AIR/MIR commoning | Release-quality optimization input, not a mandatory backend representation. |
| LICM scalar hoisting | AIR/MIR loop invariant value placement | Only pure scalar hoisting maps today; memory LICM needs alias and MemorySSA precision. |
| LoopInfo preheader/latch/exits | AIR loop region and Liveness loop live-ins | Useful for source-backed loop shape tests, not an LLVM loop-canonical-form requirement. |

## LLVM-Only Mechanics

These should remain comparison-IR details unless a Zig upstream design explicitly
chooses a matching representation:

```text
PHI node spelling and incoming-edge storage
entry-block alloca promotion as the source of SSA values
GEP index arithmetic as the native aggregate model
LLVM metadata graphs as optimizer legality facts
pass names and pass pipeline order as the native optimizer architecture
MemorySSA access-list storage layout
```

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
instcombine_safe_scalar: backend-neutral scalar fold expectation
dse_overwrite: overwritten store cleanup expectation
licm_invariant: pure loop-invariant scalar motion expectation
globaldce_basic: global reachability expectation
compare_codegen_asm.sh: full current tiny x86_64 assembly smoke matrix
```

## Boundary

Register allocation, instruction scheduling, target-cost modeling, debug/unwind
emission, and object/linker ownership remain outside this handoff cycle. They
should be added only when a source-backed Zig fixture requires that level of
backend validation.
