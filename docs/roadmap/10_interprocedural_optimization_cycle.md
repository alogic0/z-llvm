# Cycle 10: Interprocedural Optimization And Inlining Boundary

## Goal

Implement the small interprocedural facts Zig's LLVM pipeline relies on before
full backend handoff: function attributes, call graph roots, always-inline
boundaries, internal function cleanup, and conservative no-op behavior for IPO
passes that are not yet locally reproduced.

## Source Anchors

- LLVM: `AlwaysInliner`, `FunctionAttrs`, `GlobalOpt`, `IPSCCP`,
  `CalledValuePropagation`
- Local code: `src/analysis/call_graph.zig`,
  `src/analysis/function_attrs.zig`, `src/passes/globaldce.zig`
- Local docs: `docs/passes/mandatory_ipo.md`,
  `docs/passes/globaldce.md`,
  `docs/inventory/zig_llvm_pass_pipeline_inventory.md`

## Plan

- [x] Refresh IPO pass usage from Zig's current LLVM pipeline.
- [x] Extend function attribute parsing and conservative propagation.
- [x] Add call graph support for direct internal call roots and declarations.
- [x] Define the local always-inline boundary: inline only trivial accepted IR
      or keep as documented no-op.
- [x] Add fixtures for internal helper retention/removal across call graph edges.
- [x] Keep indirect calls, recursion, varargs, and complex ABI lowering
      conservative.
- [x] Document which IPO passes are real, placeholder, or deferred.

## Exit Criteria

- [x] IPO placeholders cannot silently claim reproduced LLVM behavior.
- [x] Direct-call graph facts are tested against GlobalDCE and function attrs.
- [x] Zig pipeline conformance docs explain every IPO no-op in accepted rows.

## Completion Notes

- `src/analysis/call_graph.zig` now models function definitions and
  declarations separately, tracks known direct callees, and can compute
  reachable definition roots without treating declarations as local bodies.
- `src/analysis/function_attrs.zig` recognizes additional IPO-relevant
  attributes and exposes resolved definition/declaration helpers for `#N`
  attribute groups.
- `always-inline`, `inline`, `argpromotion`, `called-value-propagation`,
  `callsite-splitting`, and `deadargelim` remain executable placeholders. The
  local `always-inline` boundary is documented as no-op until body cloning, SSA
  repair, ABI checks, recursion handling, and debug-location handling exist.
