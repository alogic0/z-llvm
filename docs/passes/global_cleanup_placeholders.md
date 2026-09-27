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

## ConstMerge correctness checkpoint mapping (2026-09-26)

The [completed checkpoint](../roadmap/correctness_checkpoint.md) maps the reference
rewrite/deletion contract to `ConstantMergePass::run` and its
`Old->replaceAllUsesWith(NewConstant)` operation in
`llvm/lib/Transforms/IPO/ConstantMerge.cpp`. LLVM rewrites structured constant
expression users; the local IR still stores some of those users as opaque text.
The local-conservative boundary therefore retains candidates whenever shared
reference discovery reports unknown coverage, and checks remaining references
before deletion. Structured scalar, array, instruction and alias uses remain
rewritable. This repairs invalid optimizer output without adding a parser
surface, removing a Zig fallback or claiming full LLVM ConstantMerge parity.

Comparison: `test/opt/inputs/optimizer_checkpoint.ll` under `constmerge` and
`release-o3`, LLVM 22 verification and native execution through
`zig build optimizer-correctness`; unit tests also require positive structured
merges and alias rewriting to remain enabled.
