# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

Active cycle:

- [ ] [Cycle 01: Input Size Tooling](roadmap/01_input_size_tooling_cycle.md)
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
