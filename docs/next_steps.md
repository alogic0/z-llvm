# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

Active cycle:

- [x] Corpus tooling throughput blocker: add `z_llvm --quiet` and make
      `tools/zig_corpus_discovery.zig` use it by default for local checks, so
      full Debug sweeps verify rows without printing multi-megabyte modules.
- [x] Verifier throughput blocker: replace dense per-candidate dominator
      recomputation with bitset dominator sets, restoring fast verification for
      large Debug functions such as `behavior/sizeof_and_typeof.zig`.
- [x] [Cycle 01: Input Size Tooling](roadmap/01_input_size_tooling_cycle.md)
- [x] Source-backed parser blocker: accept constant-expression `getelementptr`
      pointer operands in load, store, atomicrmw, and cmpxchg memory
      instructions. Upstream mapping is recorded in [Memory IR
      Subset](ir_memory.md).
- [x] Source-backed parser blocker: parse, verify, print, and preserve
      `extractvalue` for aggregate cmpxchg result values. Upstream mapping is
      recorded in [IR Values](ir_values.md).
- [x] Source-backed parser blocker: parse, verify, print, and preserve
      aggregate-valued direct call results, including Zig stage4 overflow
      intrinsic calls. Upstream mapping is recorded in [IR Values](ir_values.md).
- [x] Source-backed parser blocker: parse, verify, print, and preserve
      LLVM vector splat constants such as `splat (i8 10)` in vector compare
      operands. Upstream mapping is recorded in [Vector IR Boundary](ir_vectors.md).
- [x] Source-backed parser blocker: parse, verify, print, and preserve
      fixed-vector source types in cast instructions, including vector mask
      bitcasts to equal-width scalar integers. Upstream mapping is recorded in
      [Vector IR Boundary](ir_vectors.md).
- [x] Source-backed parser blocker: parse, verify, print, and preserve
      quoted branch labels containing commas. Upstream mapping is recorded in
      [Control Flow IR](ir_control_flow.md).
- [x] Source-backed parser blocker: parse, verify, print, and preserve
      `insertvalue` aggregate construction. Upstream mapping is recorded in
      [IR Values](ir_values.md).
- [x] Source-backed parser blocker: parse, verify, print, and preserve
      aggregate-typed PHI nodes and aggregate constant incoming values. Upstream
      mapping is recorded in [IR Values](ir_values.md).
- [x] Source-backed parser blocker: preserve named types inside parameter
      attributes such as `sret({ i16, %Named.Type })` without confusing them
      for SSA parameter names.
- [x] Source-backed parser blocker: parse, verify, print, and preserve call-site
      return attributes such as `call range(i16 0, 17) i16 @llvm.ctpop.i16(...)`.
      Upstream mapping is recorded in [Intrinsics And Call
      Semantics](semantics/intrinsics_and_call_semantics.md).
- [x] Source-backed parser blocker: parse, verify, print, and preserve
      `indirectbr` terminators as conservative multi-successor CFG boundaries.
      Upstream mapping is recorded in [Control Flow IR](ir_control_flow.md).
- [x] Source-backed parser blocker: parse, verify, print, and preserve vector
      splat constants in call arguments such as `<4 x i32> splat (i32 16)`.
      Upstream mapping is recorded in [Vector IR Boundary](ir_vectors.md).
- [x] Source-backed parser blocker: parse, verify, print, and preserve `poison`
      as a compact call argument value such as `i64 poison`. Upstream mapping is
      recorded in [IR Values](ir_values.md).
- [x] Source-backed verifier blocker: accept preserved pointer parameter
      `captures(...)` attributes including `captures(address)` and
      `captures(address, ret: address, provenance)` while keeping capture
      semantics conservative.
- [x] Source-backed parser/verifier blocker: infer numeric implicit entry block
      names from the first unnamed instruction result so PHI incoming references
      such as `%0` resolve correctly.
- [x] Source-backed verifier blocker: classify fixed-vector `icmp`/`fcmp`
      results as `<N x i1>` masks so source-backed vector compare masks can
      feed equal-width bitcasts. Upstream mapping is recorded in [Vector IR
      Boundary](ir_vectors.md).
- [x] Source-backed verifier blocker: accept lane-wise vector `select`
      conditions of type `<N x i1>` when the selected values are fixed vectors
      with the same lane count. Upstream mapping is recorded in [Vector IR
      Boundary](ir_vectors.md).
- [x] Source-backed verifier blocker: type `cmpxchg` results as `{ T, i1 }`
      for the compared value type `T` so non-`i32` cmpxchg pairs can feed
      `extractvalue`. Upstream mapping is recorded in [Memory IR
      Subset](ir_memory.md) and [IR Values](ir_values.md).
- [x] Source-backed verifier blocker: accept register-argument calls to
      zero-parameter `naked` function definitions while preserving ordinary
      direct-call signature checks. Upstream mapping is recorded in [Intrinsics
      And Call Semantics](semantics/intrinsics_and_call_semantics.md).
- [x] Source-backed parser/verifier blocker: preserve scalar `x86_fp80` and
      `fp128` ABI surface for C ABI rows, including loads, stores, calls,
      returns, aggregate fields, and `0xL...` literals without adding FP
      optimization semantics. Upstream mapping is recorded in
      [Scalar IR](ir_scalar.md).
- [x] Source-backed parser/verifier blocker: infer unnamed implicit entry block
      `%0` when the first instruction result is nonnumeric, so PHI incoming
      edges from `%0` in stage4 standalone IR verify correctly. Upstream mapping
      is recorded in [Control Flow IR](ir_control_flow.md).
- [x] Source-backed parser blocker: split top-level named type definitions at
      an assignment separator outside quoted identifiers, so long quoted type
      names containing `=` parse and verify. Upstream mapping is recorded in
      [Named Type Definitions](ir_named_types.md).
- [x] Source-backed parser blocker: parse quoted named aggregate type prefixes
      on globals and leading instruction types, preserving opaque aggregate
      initializers without interpreting layout. Upstream mapping is recorded in
      [Module-Level IR](ir_module.md).
- [x] Source-backed parser blocker: preserve `!nonnull`, `!noundef`, and
      `!unpredictable` instruction metadata opaquely while keeping the metadata graph
      uninterpreted. Upstream mapping is recorded in
      [Alias Metadata Policy](analysis/alias_metadata.md).
- [x] Source-backed parser blocker: preserve observed global pre-kind
      visibility/preemption spellings such as `extern_weak hidden constant`
      without assigning linker semantics locally. Upstream mapping is recorded
      in [Module-Level IR](ir_module.md).
- [x] Source-backed verifier blocker: accept lane-wise integer vector casts
      such as `zext <2 x i32> ... to <2 x i64>` when lane counts and element
      widths match LLVM verifier rules. Upstream mapping is recorded in
      [Vector IR Boundary](ir_vectors.md).
- [x] Source-backed ReleaseSafe parser blocker: find switch case-list closing
      brackets outside quoted labels, so generated labels containing `[]` do
      not terminate the switch early. Upstream mapping is recorded in
      [Control Flow IR](ir_control_flow.md).
- [x] Source-backed discovery tooling blocker: run local corpus checks through
      an optimized `z_llvm` path by default, keep stage4 Zig for IR emission,
      and make trace output opt-in so large debug-heavy rows such as
      `standalone/coff_dwarf/main.zig` do not dominate discovery sweeps.
- [x] Full ReleaseSafe source-backed sweep with the optimized local checker:
      `processed=1474/1474`, `emit-ok=465`, `local-ok=465`, and zero
      input-size, parse, verify, or optimizer failures.
- [x] Source-backed Debug parser blocker: parse, verify, print, and preserve
      pointer global constants initialized by supported constant expressions
      such as `inttoptr (...)`. Upstream mapping is recorded in
      [Module-Level IR](ir_module.md).
- [x] Source-backed Debug parser blocker: parse, verify, print, and preserve
      address-space pointer function return spellings such as
      `ptr addrspace(256)`. Upstream mapping is recorded in
      [Module-Level IR](ir_module.md).
- [x] Source-backed Debug verifier blocker: parse, verify, print, and preserve
      address-space pointer operands on `getelementptr`, avoiding misclassification
      of `addrspace(...)` as a floating-point value. Upstream mapping is recorded
      in [Memory IR Subset](ir_memory.md).
- [x] Source-backed Debug parser blocker: parse, verify, print, and preserve
      address-space pointer value types on `alloca`, `load`, and `store` while
      keeping opaque-pointer semantics conservative. Upstream mapping is recorded
      in [Memory IR Subset](ir_memory.md).
- [x] Source-backed Debug parser blocker: parse, verify, print, and preserve
      `fpext float ... to double` used by C-varargs float promotion. Upstream
      mapping is recorded in [Scalar IR](ir_scalar.md).
- [x] Source-backed Debug parser blocker: parse, verify, print, and preserve
      `fptosi`/`fptoui` casts used by int-from-float safety checks without adding
      local FP-to-int folding semantics. Upstream mapping is recorded in
      [Scalar IR](ir_scalar.md).
- [x] Source-backed Debug parser/verifier blocker: parse, verify, print, and
      preserve fixed-vector global initializers and vector `fptosi`/`fptoui`
      casts used by vector int-from-float safety checks. Upstream mapping is
      recorded in [Vector IR Boundary](ir_vectors.md).
- [x] Source-backed Debug parser blocker: parse, verify, print, and preserve
      Zig-emitted `musttail call`/`notail call` markers as call facts while
      keeping full tail-call legality and lowering out of scope. Upstream
      mapping is recorded in [Intrinsics And Call
      Semantics](semantics/intrinsics_and_call_semantics.md).

The Cycle 02-08 finish burn-down wave is complete. Discovery Cycles 01-07 are
archived under [Completed Discovery
Cycles](roadmap/historical/completed_discovery_cycles/README.md). Cycle 07
refreshed selected checked stage4 corpus rows byte-identically, so no new
source-backed blocker is active. The durable finish table is [Finish Criteria
and Gap Burn-Down
Table](roadmap/finish_gap_burndown_table.md).

### Selection Rule

- [ ] Select the next bounded slice from
      [Future Optimizer Backlog](roadmap/future_optimizer_backlog.md) or from a
      new measured source-backed blocker.
- [ ] Add upstream LLVM mapping before marking a new future step complete.
