# Epic 6: Scalar Optimization Pipeline

## Goal

Implement Zig-relevant scalar optimization behavior in dependency order, using
the discovered LLVM pass pipeline as the selection source.

## Inputs

- `../inventory/zig_llvm_pass_pipeline_inventory.md`
- Canonicalization passes from `04_mandatory_canonicalization_passes.md`
- Memory legality from `05_memory_and_side_effect_semantics.md`

## Plan

- [x] Build a scalar-pass dependency map from the inventory.
- [x] Keep each pass behind a fixture-backed status:
      `placeholder`, `LLVM-shaped subset`, `fixture-equivalent`,
      `algorithm-parity target`, or deferred.
- [x] Add the optimizer parity checklist to every scalar pass doc:
      LLVM source files, entry points/classes, required analyses, core data
      structures, unsupported behavior, and `opt-22` fixtures.
- [x] Implement DCE and ADCE through the shared side-effect API.
- [x] Document the ADCE rework path toward LLVM's algorithm:
      optimistic liveness worklist, PostDominatorTree-based control dependence,
      live branch marking, dead region handling, and CFG update fixtures.
- [x] Implement SCCP for integer, branch, PHI, select-through-InstSimplify, and
      direct constant-return call cases observed in supported fixtures; document
      pointer-null SCCP as deferred until the IR has typed null pointer values.
- [x] Document the SCCP rework path toward LLVM's algorithm:
      unknown/undef/constant/overdefined lattice values, executable block and
      edge tracking, sparse instruction visitor, undef resolution loop, and
      unreachable edge/block folding.
- [x] Implement GVN for pure expressions and memory-safe cases only.
- [x] Document the GVN rework path toward LLVM's algorithm:
      ValueTable, leader tables, value numbering for expressions/PHIs/casts/
      calls/loads, load availability, MemoryDependence or MemorySSA-backed
      checks, PRE, and duplicate-PHI elimination.
- [x] Implement EarlyCSE after memory legality supports it:
      dominator-scoped available values and available loads with conservative
      alias/mod-ref clobber checks; document calls, stores, MemorySSA
      generation checks, and store-to-load forwarding as deferred.
- [x] Defer jump threading until branch conditions, PHI translation,
      and CFG simplification are stable.
- [x] Defer reassociation until operations where flags and poison
      semantics are documented.
- [x] Defer correlated value propagation and related range folds until
      comparison and branch semantics are stable.
- [x] Add pass manager ordering tests for selected scalar pipelines.
- [x] For every accepted fixture, add a paired rejected or deferred fixture when
      LLVM handles a broader case than the local implementation.
- [x] Add pipeline fixtures using the same pass sequence Zig uses for the
      covered optimization mode.
- [x] Compare LLVM-equivalent fixtures against `opt-22`.

## Deliverables

- [x] Scalar optimization dependency map.
- [x] Per-pass design notes and gap tables.
- [x] Per-pass parity checklist entries.
- [x] Zig-emitted scalar optimization fixtures.
- [x] Pipeline ordering tests.

## Exit Criteria

- [x] The local scalar pipeline improves canonical IR without relying on
      undocumented LLVM assumptions.
- [x] Each scalar pass has explicit semantic prerequisites and known gaps.
- [x] Fixture results separate LLVM-equivalent behavior from conservative local
      behavior.
- [x] No scalar pass is marked reproduced below `fixture-equivalent`; EarlyCSE
      remains an LLVM-shaped foundation and is not claimed as reproduced.

## Implementation Notes

- Scalar pipeline scope, dependency order, statuses, fixtures, and deferred
  algorithms are documented in
  `docs/semantics/scalar_optimization_pipeline.md`.
- `dce`, `adce`, `sccp`, `gvn`, and `dse` are fixture-equivalent for listed
  fixtures only. Broader LLVM algorithms remain documented gaps.
- `early-cse` is implemented as a useful LLVM-shaped foundation with unit-test
  coverage, but it is not marked reproduced because small `opt-22` fixtures can
  differ in preserved SSA names.
- JumpThreading, CorrelatedValuePropagation, Reassociate, ConstraintElimination,
  SpeculativeExecution, BDCE, and IPSCCP remain explicit placeholders or
  deferred work until their prerequisites are implemented.
