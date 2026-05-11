# Global Cleanup Placeholders

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
  Explicit placeholders except GlobalDCE.
```

Implemented subset:

```text
globalopt, constmerge, elim-avail-extern, recompute-globalsaa, and globals-aa
are executable placeholders.
```

Intentional divergences:

```text
no global initializer rewriting
no identical constant merging
no available_externally model
no GlobalsAA facts yet
weak linkage is handled only by GlobalDCE root classification; it is not used
by GlobalOpt, ConstantMerge, or LTO import/export decisions.
```

Fixture coverage:

```text
opt-22 equivalent:
  none currently

local-only conservative:
  none currently

unit-test only:
  placeholder pass dispatch
```
