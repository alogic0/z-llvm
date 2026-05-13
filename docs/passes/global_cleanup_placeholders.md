# Global Cleanup

LLVM references:

```text
llvm-project-22/llvm/lib/Transforms/IPO/GlobalOpt.cpp
llvm-project-22/llvm/lib/Transforms/IPO/ConstantMerge.cpp
llvm-project-22/llvm/lib/Transforms/IPO/ElimAvailExtern.cpp
llvm-project-22/llvm/lib/Analysis/GlobalsModRef.cpp
```

Global cleanup passes optimize module-scope state after linkage, initializer,
and global memory identity semantics are available.

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Transforms/IPO/GlobalOpt.cpp
  llvm-project-22/llvm/lib/Transforms/IPO/ConstantMerge.cpp
  llvm-project-22/llvm/lib/Transforms/IPO/ElimAvailExtern.cpp
  llvm-project-22/llvm/lib/Analysis/GlobalsModRef.cpp

LLVM entry points/classes:
  GlobalOptPass::run
  OptimizeGlobalVars
  processInternalGlobal
  CleanupConstantGlobalUsers
  ConstantMergePass::run
  EliminateAvailableExternallyPass::run
  GlobalsAA

Required analyses:
  Complete global initializer graph.
  Linkage and visibility semantics.
  Alias/mod-ref facts for globals.

Required IR invariants:
  Global merging and deletion must preserve externally visible symbol behavior.
  Available-externally deletion must respect linkage semantics.

Core LLVM algorithm data structures:
  Global value use graph.
  Constant initializer equivalence classes.
  GlobalsAA mod/ref summaries.

Local target status:
  GlobalOpt has an LLVM-shaped scalar direct-load cleanup slice. ConstantMerge,
  has an LLVM-shaped scalar private constant merge slice. ElimAvailExtern,
  recompute-globalsaa, and globals-aa remain explicit placeholders.
```

Implemented subset:

```text
globalopt:
  scans local non-TLS scalar `global` definitions
  accepts integer/FP/null/zero/undef/poison scalar initializers
  requires every use to be a direct non-volatile load of the exact global type
  replaces accepted loads with the initializer value
  deletes the global when all accepted load uses are removed

constmerge:
  builds a small initializer-key map for local non-TLS scalar `constant`
  definitions
  requires `unnamed_addr`, matching type, matching scalar initializer, matching
  attrs, and no COMDAT
  chooses the later private constant as the canonical representative, matching
  the accepted LLVM fixture shape
  rewrites global value operands from the duplicate to the canonical constant
  deletes the duplicate global

elim-avail-extern, recompute-globalsaa, and globals-aa are executable
placeholders.
```

Intentional divergences:

```text
no aggregate global initializer rewriting
no global-to-local stack localization
no store-to-initializer evaluation beyond direct load cleanup
no constant-expression, GEP, bitcast, addrspacecast, or alias users
no aggregate/string/vector constant merging
no alignment merging beyond requiring matching attrs
no available_externally model
no GlobalsAA facts yet
weak linkage is handled only by GlobalDCE root classification; it is not used
by GlobalOpt, ConstantMerge, or LTO import/export decisions.
```

Fixture coverage:

```text
opt-22 equivalent:
  globalopt_internal_scalar_load
  globalopt_store_addr_reject
  constmerge_private_unnamed_scalar
  constmerge_no_unnamed_reject

local-only conservative:
  none currently

unit-test only:
  placeholder pass dispatch for the remaining global cleanup passes
```
