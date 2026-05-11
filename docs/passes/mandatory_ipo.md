# Mandatory IPO Placeholders

LLVM references:

```text
llvm-project-22/llvm/lib/Transforms/IPO/AlwaysInliner.cpp
llvm-project-22/llvm/lib/Transforms/IPO/Inliner.cpp
llvm-project-22/llvm/lib/Transforms/IPO/ArgumentPromotion.cpp
llvm-project-22/llvm/lib/Transforms/IPO/CalledValuePropagation.cpp
llvm-project-22/llvm/lib/Transforms/IPO/DeadArgumentElimination.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/CallSiteSplitting.cpp
```

These passes operate across function boundaries. They are intentionally
placeholder-only until the local call graph, attributes, ABI constraints, and
debug-info preservation are strong enough for real body rewriting.

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Transforms/IPO/AlwaysInliner.cpp
  llvm-project-22/llvm/lib/Transforms/IPO/Inliner.cpp
  llvm-project-22/llvm/lib/Transforms/IPO/ArgumentPromotion.cpp
  llvm-project-22/llvm/lib/Transforms/IPO/CalledValuePropagation.cpp
  llvm-project-22/llvm/lib/Transforms/IPO/DeadArgumentElimination.cpp

LLVM entry points/classes:
  AlwaysInlinerPass::run
  InlinerPass::run
  ArgumentPromotionPass::run
  CalledValuePropagationPass::run
  DeadArgumentEliminationPass::run

Required analyses:
  Call graph or LazyCallGraph.
  Function attributes and call-site attributes.
  Alias/mod-ref analysis for argument and call rewriting.
  Target/ABI information for safe call signature changes.

Required IR invariants:
  Inlining must preserve SSA, dominance, attributes, debug information, and
  call ABI semantics.
  Argument promotion and dead argument elimination must update every call site.

Core LLVM algorithm data structures:
  CGSCC worklists.
  Inline cost and mandatory inline checks.
  Argument use summaries.
  Call-site rewrite lists.

Local target status:
  Explicit placeholders backed by direct-call graph and attribute foundations.
```

Implemented subset:

```text
always-inline, inline, argpromotion, called-value-propagation,
callsite-splitting, and deadargelim are executable placeholders.
direct-call graph foundations distinguish definitions from declarations.
function/declaration attribute helpers resolve #N groups for IPO-relevant
attributes such as alwaysinline, noinline, nofree, norecurse, nosync, nounwind,
readnone, readonly, and cold.
```

Intentional divergences:

```text
no function body inlining
no call-site cloning
no argument rewriting
no dead argument removal
no CGSCC iteration
always-inline is a documented no-op until trivial body cloning, SSA repair,
ABI checks, debug-location handling, and recursive-call rejection are
implemented
```

Fixture coverage:

```text
opt-22 equivalent:
  none currently

local-only conservative:
  call graph declaration/definition reachability test
  IPO attribute group resolution test

unit-test only:
  placeholder pass dispatch
```
