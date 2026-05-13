# Mandatory IPO

LLVM references:

```text
llvm-project-22/llvm/lib/Transforms/IPO/AlwaysInliner.cpp
llvm-project-22/llvm/lib/Transforms/IPO/Inliner.cpp
llvm-project-22/llvm/lib/Transforms/IPO/ArgumentPromotion.cpp
llvm-project-22/llvm/lib/Transforms/IPO/CalledValuePropagation.cpp
llvm-project-22/llvm/lib/Transforms/IPO/DeadArgumentElimination.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/CallSiteSplitting.cpp
```

These passes operate across function boundaries. Most of this family remains
placeholder-only until the local call graph, attributes, ABI constraints, and
debug-info preservation are strong enough for broad body rewriting. The current
exception is a narrow `always-inline` slice for direct calls to local
single-block callees.

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
  always-inline is an LLVM-shaped subset for direct internal single-block
  callees.
  inline, argpromotion, called-value-propagation, callsite-splitting,
  deadargelim, forceattrs, inferattrs, and function-attrs remain placeholders
  or analysis foundations.
```

Implemented subset:

```text
always-inline:
  direct calls to internal/private function definitions with alwaysinline
  attributes are cloned when the callee has one basic block ending in ret.
  The local pass substitutes call arguments for callee parameters, renames
  cloned SSA results with LLVM-style .i suffixes, replaces the call result with
  the inlined return value, removes the call, and removes now-dead local
  alwaysinline definitions when they have no remaining direct call uses.

remaining IPO passes:
  inline, argpromotion, called-value-propagation, callsite-splitting, and
  deadargelim are executable placeholders.

direct-call graph foundations distinguish definitions from declarations.
function/declaration attribute helpers resolve #N groups for IPO-relevant
attributes such as alwaysinline, noinline, nofree, norecurse, nosync, nounwind,
readnone, readonly, and cold.
```

Intentional divergences:

```text
no multi-block inlining
no PHI inlining
no varargs inlining
no recursive inlining
no indirect-call inlining
no exceptional-control-flow inlining
no call-site cloning outside always-inline's supported direct-call shape
no argument rewriting outside call-to-callee parameter substitution
no dead argument removal
no CGSCC iteration
no general inline cost model
debug-location salvage for inlined bodies is not modeled
```

Fixture coverage:

```text
opt-22 equivalent:
  always_inline_direct
  always_inline_noinline_call

local-only conservative:
  call graph declaration/definition reachability test
  IPO attribute group resolution test

unit-test only:
  placeholder pass dispatch for the remaining IPO passes
```

## AlwaysInline Upstream Mapping

```text
LLVM source files:
  llvm-project-22/llvm/lib/Transforms/IPO/AlwaysInliner.cpp
  llvm-project-22/llvm/include/llvm/Transforms/IPO/AlwaysInliner.h
  llvm-project-22/llvm/lib/Transforms/Utils/InlineFunction.cpp

LLVM entry points/classes:
  AlwaysInlinerPass::run
  AlwaysInlineImpl
  InlineFunction
  InlineFunctionInfo
  isInlineViable

Reproduced behavior:
  The local pass scans module functions for direct call users of a function
  with the alwaysinline attribute, skips noinline call sites, clones a supported
  callee body into the caller, replaces the call result with the returned
  value, and deletes now-dead local alwaysinline definitions.

Accepted local IR surface:
  internal/private callee definitions
  direct calls only
  matching argument count and return type
  one callee basic block ending in ret
  no callee PHIs, calls, stores, atomics, fences, allocas, or EH
  no recursive calls

Known missing behavior:
  no multi-block inlining
  no invoke/callbr support
  no lifetime intrinsic insertion
  no assumption cache, AAResults, or ProfileSummaryInfo integration
  no COMDAT dead-function filtering
  no debug-location salvage
  no inlining through unsupported call-site attributes or operand bundles

Fixtures and comparison:
  bash scripts/compare_opt.sh test/opt/fixtures.tsv
  always_inline_direct compares with opt-22 -passes=always-inline
  always_inline_noinline_call compares with opt-22 -passes=always-inline
```
