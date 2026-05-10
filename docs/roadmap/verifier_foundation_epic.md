# Verifier Foundation Epic

Source plan: [all_discovered_llvm_optimizations_implementation_plan.md](all_discovered_llvm_optimizations_implementation_plan.md)

Inventory justification:
[zig_llvm_pass_pipeline_inventory.md](../inventory/zig_llvm_pass_pipeline_inventory.md)
lists `verify` / `VerifierPass` as mandatory P0 pipeline functionality owned
by `llvm/lib/IR/Verifier.cpp`.

## Goal

Make the local IR validity gate strong enough that optimizer work starts from
the same broad invariants LLVM requires for the accepted IR subset.

## Scope

This epic covers verifier expansion only. It does not expand InstCombine,
SimplifyCFG semantics beyond verifier-clean output, mem2reg, SROA, DSE, SCCP,
loop rotation, inlining, globals, vectorization, or LTO.

## Checklist

- [x] Add the verifier LLVM Algorithm Contract in [ir_verifier.md](../ir_verifier.md).
- [x] Add `verify` inventory mapping as the explicit justification.
- [x] Check dominance for ordinary named SSA value uses.
- [x] Reject same-block use-before-def.
- [x] Validate phi incoming blocks against exact CFG predecessors.
- [x] Reject duplicate or missing phi incoming predecessors.
- [x] Validate phi incoming values on predecessor edges.
- [x] Reject phi nodes after non-phi instructions.
- [x] Keep terminator target validation and call/reference validation in the
      verifier slice.
- [x] Update SimplifyCFG cleanup so rewritten CFGs keep phi incoming lists
      verifier-clean.
- [x] Add accepted and rejected local verifier fixtures.
- [x] Update testing and unsupported-IR documentation for verifier coverage.

## LLVM Alignment

The implemented verifier is an LLVM-shaped subset of `VerifierPass`, not a full
port. It reproduces the SSA dominance and PHI predecessor invariants that are
critical for the optimizer slices in the discovered Zig LLVM pipeline. The local
implementation uses compact per-function matrices for CFG predecessor and
dominance facts instead of LLVM's full verifier infrastructure.
