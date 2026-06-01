# Mandatory IPO

LLVM references:

```text
llvm-project-22/llvm/lib/Transforms/IPO/AlwaysInliner.cpp
llvm-project-22/llvm/lib/Transforms/IPO/Inliner.cpp
llvm-project-22/llvm/lib/Transforms/IPO/ArgumentPromotion.cpp
llvm-project-22/llvm/lib/Transforms/IPO/CalledValuePropagation.cpp
llvm-project-22/llvm/lib/Transforms/IPO/DeadArgumentElimination.cpp
llvm-project-22/llvm/lib/Transforms/IPO/FunctionAttrs.cpp
llvm-project-22/llvm/lib/Transforms/Scalar/CallSiteSplitting.cpp
```

These passes operate across function boundaries. Most of this family remains
placeholder-only until the local call graph, attributes, ABI constraints, and
debug-info preservation are strong enough for broad body rewriting. Current
exceptions are narrow `always-inline` and `inline` slices for direct calls to
local single-block callees. `function-attrs` has a direct-call inference slice
for memory effects, simple call attributes, and bounded parameter attributes.

## LLVM Algorithm Contract

```text
LLVM source files:
  llvm-project-22/llvm/lib/Transforms/IPO/AlwaysInliner.cpp
  llvm-project-22/llvm/lib/Transforms/IPO/Inliner.cpp
  llvm-project-22/llvm/lib/Transforms/IPO/ArgumentPromotion.cpp
  llvm-project-22/llvm/lib/Transforms/IPO/CalledValuePropagation.cpp
  llvm-project-22/llvm/lib/Transforms/IPO/DeadArgumentElimination.cpp
  llvm-project-22/llvm/lib/Transforms/IPO/FunctionAttrs.cpp

LLVM entry points/classes:
  AlwaysInlinerPass::run
  InlinerPass::run
  InlineAdvisor::getAdvice
  InlineCostCallAnalyzer
  InlineFunction
  ArgumentPromotionPass::run
  CalledValuePropagationPass::run
  DeadArgumentEliminationPass::run
  PostOrderFunctionAttrsPass::run
  addMemoryAttrs
  addNoRecurseAttrs

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
  inline is an LLVM-shaped cost-gated subset for direct internal single-block
  callees.
  function-attrs is an LLVM-shaped direct-call subset for `memory(none)`,
  `memory(read)`, `memory(argmem: read/write)`, `norecurse`, simple
  nofree/nosync/nounwind/willreturn facts, and direct parameter attributes.
  argpromotion, called-value-propagation, callsite-splitting, deadargelim,
  forceattrs, and inferattrs remain placeholders or analysis
  foundations.
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

inline:
  direct calls to internal/private function definitions are cloned when the
  callee has one basic block ending in ret and fits the local instruction cost
  budget.
  The local pass rejects noinline, recursive, indirect, declaration,
  multi-block, side-effecting, operand-bundle, unsupported call-site attribute,
  and over-budget calls.
  It reuses the same InlineFunction-shaped clone/substitute path as
  always-inline and deletes only local callees made dead by this pass.

remaining IPO passes:
  argpromotion, called-value-propagation, callsite-splitting, and deadargelim
  are executable placeholders.

direct-call graph foundations distinguish definitions from declarations.
function/declaration attribute helpers resolve #N groups for IPO-relevant
attributes such as alwaysinline, noinline, nofree, norecurse, nosync, nounwind,
readnone, readonly, and cold.

function-attrs:
  walks function bodies like LLVM's FunctionAttrs memory-access scan, classifies
  side-effect-free bodies as `memory(none)`, readonly bodies as `memory(read)`,
  parameter-only loads/stores as `memory(argmem: read/write)`, and leaves
  volatile/atomic memory, inline asm, indirect calls, operand bundles, recursive
  SCC memory effects, and unknown calls unannotated.
  The local norecurse inference mirrors LLVM's singleton-SCC guard by rejecting
  direct recursion, mutual recursion, indirect calls, and unannotated external
  calls before adding `norecurse`.
  The local simple-attribute slice infers nofree/nosync/nounwind for bodies
  whose direct calls also prove those facts, mustprogress/willreturn for
  no-call all-return bodies, and readonly/writeonly/captures(none),
  initializes((0, N)), and returned parameter attrs for direct named-parameter
  uses.
  It infers `memory(none)` for local recursive SCCs when the reachable local
  call cycle contains only side-effect-free instructions and local direct calls.
  It materializes opt-style attribute groups only for modules without existing
  groups and only when the function attrs are all known to the local model.
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
no full CGSCC iteration
no general inline cost model
inline cost is a small local instruction budget, not LLVM's full InlineCost
model with TTI, profile, SROA bonuses, and call penalties
debug-location salvage for inlined bodies is not modeled
function-attrs still does not rewrite existing attribute-group tables, does not
run full CGSCC propagation, and does not model broader Attributor-derived facts
```

Fixture coverage:

```text
opt-22 equivalent:
  always_inline_direct
  always_inline_noinline_call
  inline_direct_small
  inline_noinline_call
  function_attrs_direct_calls
  function_attrs_reject

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
  zig build compare-opt -- test/opt/fixtures.tsv
  always_inline_direct compares with opt-22 -passes=always-inline
  always_inline_noinline_call compares with opt-22 -passes=always-inline
```

## Inline Upstream Mapping

```text
LLVM source files:
  llvm-project-22/llvm/lib/Transforms/IPO/Inliner.cpp
  llvm-project-22/llvm/lib/Transforms/Utils/InlineFunction.cpp
  llvm-project-22/llvm/lib/Analysis/InlineCost.cpp

LLVM entry points/classes:
  InlinerPass::run
  InlineAdvisor::getAdvice
  InlineCostCallAnalyzer
  InlineFunction

Reproduced behavior:
  The local pass scans direct calls to defined local callees, rejects noinline
  and unsupported call-site forms, applies a small instruction-budget cost
  check, clones the callee body into the caller, replaces the call result with
  the returned value, and removes callees made dead by this pass.

Accepted local IR surface:
  internal/private callee definitions
  direct calls only
  matching argument count, return type, and calling convention
  one callee basic block ending in ret
  no callee PHIs, calls, stores, atomics, fences, allocas, or EH
  no recursive calls
  no call-site attributes except as a rejection boundary

Known missing behavior:
  no LazyCallGraph/CGSCC update model
  no full InlineAdvisor or InlineCost model
  no multi-block inlining
  no invoke/callbr support
  no operand-bundle support
  no call-site attribute merge beyond preserving rejected calls
  no debug-location salvage

Fixtures and comparison:
  zig build compare-opt -- test/opt/fixtures.tsv
  inline_direct_small compares with opt-22 -passes=cgscc(inline)
  inline_noinline_call compares with opt-22 -passes=cgscc(inline); both
  preserve the noinline call-site attribute group and leave the call in place.
```
