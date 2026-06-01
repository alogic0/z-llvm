# Mandatory Canonicalization

This document records the Epic 4 canonicalization contract. The goal is not to
claim full LLVM optimizer parity. The goal is to make the accepted
LLVM-compatible IR stable enough that later scalar, memory, and loop passes can
rely on verifier-clean canonical shapes.

## Upstream Mapping

LLVM source areas:

```text
llvm-project-22/llvm/lib/Passes/PassBuilderPipelines.cpp
llvm-project-22/llvm/lib/Transforms/Utils/Mem2Reg.cpp
llvm-project-22/llvm/lib/Transforms/Utils/PromoteMemoryToRegister.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/SROA.cpp
llvm-project-22/llvm/lib/Transforms/InstCombine/
llvm-project-22/llvm/lib/Analysis/InstructionSimplify.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/SimplifyCFGPass.cpp
llvm-project-22/llvm/lib/Transforms/Utils/SimplifyCFG.cpp
```

Zig pipeline source:

```text
ziglang/src/zig_llvm.cpp
ziglang/src/codegen/llvm.zig
docs/inventory/zig_llvm_pass_pipeline_inventory.md
```

## P0 Canonicalization Set

These are the mandatory canonicalization passes from the inventory that this
epic closes for the currently accepted IR surface:

| Pass | Local owner | Current status | Why it is P0 |
| --- | --- | --- | --- |
| `mem2reg` | `src/passes/mem2reg.zig` | `fixture-equivalent` for listed fixtures | Converts promotable stack slots into SSA values before scalar and loop passes reason about values. |
| `sroa` | `src/passes/sroa.zig` | `LLVM-shaped subset` for listed fixtures | Removes trivial alloca/GEP shapes and partitions accepted aggregate fields or whole-aggregate load/store users that block `mem2reg`. |
| `instsimplify` | `src/passes/inst_simplify.zig` | `fixture-equivalent` through InstCombine fixtures | Shared query layer for safe scalar simplifications. |
| `instcombine` | `src/passes/instcombine.zig` | `fixture-equivalent` for listed fixtures | Canonicalizes and folds local scalar expressions. |
| `simplifycfg` | `src/passes/simplifycfg.zig` | `fixture-equivalent` for listed fixtures | Removes unreachable/trivial CFG shapes before SSA and loop reasoning. |

`early-cse` is also a useful canonicalizing scalar pass, but it is P1 in the
inventory and belongs to the scalar optimization epic rather than this P0
mandatory canonicalization milestone.

## Ordering Contract

The local development pipelines use this ordering shape:

```text
simplifycfg
sroa
mem2reg
instcombine
simplifycfg
instcombine
```

Rationale:

- `simplifycfg` first removes unreachable predecessors and trivial branch shapes
  that would otherwise force extra PHI nodes.
- `sroa` forwards zero-offset alloca GEPs, builds accepted fixed struct/array
  field partitions, and rewrites debug-free whole-aggregate loads/stores so
  stack slots become visible to `mem2reg`.
- `mem2reg` promotes stack memory into SSA values, exposing scalar expressions
  to InstSimplify and InstCombine.
- `instcombine` folds and canonicalizes scalar expressions after SSA promotion.
- the second `simplifycfg` and `instcombine` model LLVM's repeated cleanup
  shape, where one transform exposes opportunities for the next.

The pass manager verifies the module after every pass, so later passes can
assume the verifier foundation from Epic 3.

## Implemented Algorithms

`mem2reg`:

```text
entry-block alloca discovery
promotability checks for direct non-volatile non-atomic load/store users
single-block fast path
single-store fast path when the store dominates every load
dominance-frontier PHI placement for multi-block promotion
dominator-tree rename walk
undef replacement for uninitialized promoted loads
conservative rejection of volatile, atomic, escaped, stored, GEP, and non-entry slots
```

`sroa`:

```text
zero-offset GEP forwarding to the base alloca
nested zero-offset GEP forwarding
handoff to mem2reg after forwarding
explicit deferral of aggregate/vector slice partitioning until local aggregate IR exists
```

`instsimplify` and `instcombine`:

```text
integer identity folds
defined integer constant folds
constant cast folds
icmp constant and same-operand folds
select constant-condition and identical-arm folds
freeze constant folding
commutative constant-on-RHS canonicalization
conservative refusal around flags, poison, undef, vectors, and target-dependent facts
```

`simplifycfg`:

```text
constant branch folding
same-target conditional branch folding
unreachable block removal
PHI incoming pruning
trivial PHI replacement
empty branch block threading
single-predecessor branch block merge
matching return block merge
```

## Fixture Coverage

Run all LLVM comparison fixtures:

```sh
zig build compare-opt --
```

Canonicalization fixtures:

```text
instcombine
instcombine_bitwise
instcombine_icmp_rel
instcombine_commute
instcombine_scalar_simplify
instcombine_safe_scalar
select_fold
simplifycfg
simplifycfg_thread_empty
simplifycfg_common_ret
unreachable_simplifycfg
mem2reg
mem2reg_single_store
mem2reg_undef
mem2reg_if
mem2reg_loop
mem2reg_two_slots
mem2reg_unreachable
mem2reg_escape
mem2reg_store_slot
mem2reg_non_entry_alloca
mem2reg_volatile_load
mem2reg_volatile_store
gep_memory
sroa_zero_gep
sroa_nested_zero_gep
sroa_aggregate_load_store
```

Zig-originated fixtures:

```text
test/zig/expected/tiny_scalar.normalized.ll
test/zig/expected/tiny_scalar.project_lowered.ll
test/zig/expected/tiny_scalar.project_optimized.ll
```

The Zig fixture pair demonstrates the current pre/post canonicalization shape
for the AIR-like tiny scalar bridge. Raw Zig-emitted aggregate, pointer, atomic,
and control-flow fixtures remain source-backed inputs for later parser,
verifier, memory, scalar, and loop epics.

## Deliberate Gaps

The following are not mismatches for Epic 4; they are documented unsupported
LLVM behavior outside the current accepted IR surface:

- full SROA alloca slice partition iteration, vector rewrites, debug salvage,
  and complete DataLayout-backed offset splitting;
- LLVM's complete poison, undef, freeze, and flag reasoning in InstSimplify and
  InstCombine;
- target-specific InstCombine and TargetTransformInfo-dependent CFG transforms;
- switch, invoke, landingpad, EH, profile metadata, and debug metadata CFG
  preservation;
- MemorySSA-backed stack and memory canonicalization;
- real PassBuilder analysis preservation and nested pass managers.

Future work should move one gap at a time into a later roadmap epic with
Zig-emitted input, `opt-22` fixtures, and an upstream algorithm mapping.
