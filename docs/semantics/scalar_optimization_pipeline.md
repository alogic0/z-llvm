# Scalar Optimization Pipeline

This document records the Epic 6 scalar optimization contract. The local scalar
pipeline is selected from Zig's LLVM pass inventory, but each pass is limited to
the accepted IR surface and must advertise whether it is fixture-equivalent,
unit-test-only, placeholder, or deferred.

## Upstream Mapping

LLVM source areas:

```text
llvm-project-22/llvm/lib/Passes/PassBuilderPipelines.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/DCE.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/ADCE.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/SCCP.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/GVN.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/EarlyCSE.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/DeadStoreElimination.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/JumpThreading.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/CorrelatedValuePropagation.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/Reassociate.cpp
```

Zig pipeline source:

```text
ziglang/src/zig_llvm.cpp
docs/inventory/zig_llvm_pass_pipeline_inventory.md
src/pipelines.zig
```

## Dependency Map

| Layer | Passes | Status | Dependency |
| --- | --- | --- | --- |
| Canonical IR | `simplifycfg`, `instcombine`, `sroa`, `mem2reg` | closed in Epic 4 | verifier-clean SSA, simplified CFG, stack promotion |
| Shared legality | memory-effect, alias/mod-ref, MemoryLocation | closed in Epic 5 | safe deletion, speculation, and memory clobber checks |
| Dead code cleanup | `dce`, `adce` foundation | fixture-equivalent for listed fixtures | shared safe-to-delete rule |
| Sparse constants | `sccp` foundation | fixture-equivalent for listed fixtures | InstSimplify, PHI simplification, SimplifyCFG cleanup |
| Redundancy removal | `early-cse`, `gvn` foundation | `gvn` fixture-equivalent; `early-cse` unit-test-only for current broader local behavior | DominatorTree, InstSimplify equivalence, alias/mod-ref |
| Memory cleanup | `dse` foundation | fixture-equivalent for listed fixtures | MemoryLocation, alias/mod-ref barriers |
| Deferred scalar CFG/range passes | `jump-threading`, `correlated-propagation`, `reassociate`, `constraint-elimination`, `speculative-execution`, `bdce` | placeholder/deferred | requires richer PHI translation, range facts, poison/flag model, KnownBits, or speculation policy |

## Implemented Scalar Passes

| Pass | Local owner | Fixture status | Notes |
| --- | --- | --- | --- |
| `dce` | `src/passes/dce.zig` | fixture-equivalent for listed fixtures | Removes unused side-effect-free instructions through `isSafeToDelete`. |
| `adce` | `src/passes/adce.zig` | fixture-equivalent for listed dead-chain fixture | Still a data-dependence foundation, not full LLVM ADCE control-dependence. |
| `sccp` | `src/passes/sccp.zig` | fixture-equivalent for listed branch fixture | Constant folds through local aliases, PHIs with identical incoming constants, direct constant-return calls, and relies on SimplifyCFG/DCE cleanup. |
| `gvn` | `src/passes/gvn.zig` | fixture-equivalent for listed fixtures | Dominating pure expression elimination plus conservative load value numbering when mod/ref proves no clobber. |
| `early-cse` | `src/passes/early_cse.zig` | unit-test-only for current cross-block/load subset | Uses dominator-scoped available values, but `opt-22` keeps different SSA names for a comparable same-block fixture, so no fixture-equivalent claim yet. |
| `dse` | `src/passes/dse.zig` | fixture-equivalent for listed fixtures | Single-block overwritten stack-store removal with intervening read/barrier rejection. |

## Pipeline Order

The development scalar pipeline is:

```text
simplifycfg
jump-threading placeholder
correlated-propagation placeholder
instcombine
simplifycfg
jump-threading placeholder
correlated-propagation placeholder
instcombine
aggressive-instcombine placeholder
lower-constant-intrinsics placeholder
early-cse
sccp
gvn
dce
adce
```

Release-mode descriptors additionally include memory cleanup (`dse`), loop
passes, IPO placeholders, and verifier passes. The ordering keeps
canonicalization before scalar reasoning, then runs redundancy/constant cleanup
before DCE-style cleanup.

## Fixture Coverage

`opt-22` equivalent fixtures:

```text
dce
memory_dce
dce_scalar_with_memory
dce_volatile_load_reject
adce_chain
sccp_branch
gvn_dominating_expr
gvn_scalar_with_memory
dse_overwrite
dse_load_barrier
```

Unit-test-only local coverage:

```text
early-cse same-block pure expression CSE
early-cse dominating expression and safe-load CSE
GVN duplicate PHI and safe-load CSE
SCCP direct constant-return call folding
scalar-foundation and release-mode pipeline ordering
```

Run:

```sh
zig build test
bash scripts/compare_opt.sh
```

## Deferred Work

These passes stay placeholders or deferred until their prerequisites exist:

- real LLVM ADCE: PostDominatorTree, control-dependence, live branch marking,
  and CFG update logic;
- full SCCP: unknown/undef/constant/overdefined lattice, executable edge/block
  tracking, sparse visitor, and undef resolution loop;
- full GVN/NewGVN: ValueTable, leader tables, MemoryDependence or MemorySSA,
  PRE, duplicate-PHI cleanup, and call/load value numbering;
- EarlyCSE parity: scoped hash tables with LLVM-compatible naming behavior,
  available calls/stores, store-to-load forwarding, and MemorySSA generation
  checks;
- jump threading: PHI translation, branch condition reasoning, and robust
  SimplifyCFG follow-up;
- reassociation and correlated value propagation: poison/flag/range semantics;
- BDCE: KnownBits and bit-level demanded-use analysis;
- pointer-null SCCP and richer pointer constants: local IR does not yet
  represent typed null pointer constants separately from integer constants.
