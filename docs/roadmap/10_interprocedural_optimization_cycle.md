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

- [ ] Refresh IPO pass usage from Zig's current LLVM pipeline.
- [ ] Extend function attribute parsing and conservative propagation.
- [ ] Add call graph support for direct internal call roots and declarations.
- [ ] Define the local always-inline boundary: inline only trivial accepted IR
      or keep as documented no-op.
- [ ] Add fixtures for internal helper retention/removal across call graph edges.
- [ ] Keep indirect calls, recursion, varargs, and complex ABI lowering
      conservative.
- [ ] Document which IPO passes are real, placeholder, or deferred.

## Exit Criteria

- [ ] IPO placeholders cannot silently claim reproduced LLVM behavior.
- [ ] Direct-call graph facts are tested against GlobalDCE and function attrs.
- [ ] Zig pipeline conformance docs explain every IPO no-op in accepted rows.

