# Epic 6: Scalar Optimization Pipeline

## Goal

Implement Zig-relevant scalar optimization behavior in dependency order, using
the discovered LLVM pass pipeline as the selection source.

## Inputs

- `../inventory/zig_llvm_pass_pipeline_inventory.md`
- Canonicalization passes from `04_mandatory_canonicalization_passes.md`
- Memory legality from `05_memory_and_side_effect_semantics.md`

## Plan

- [ ] Build a scalar-pass dependency map from the inventory.
- [ ] Keep each pass behind a fixture-backed status:
      `placeholder`, `LLVM-shaped subset`, `fixture-equivalent`,
      `algorithm-parity target`, or deferred.
- [ ] Add the optimizer parity checklist to every scalar pass doc:
      LLVM source files, entry points/classes, required analyses, core data
      structures, unsupported behavior, and `opt-22` fixtures.
- [ ] Implement DCE and ADCE through the shared side-effect API.
- [ ] Rework ADCE toward LLVM's algorithm in slices:
      optimistic liveness worklist, PostDominatorTree-based control dependence,
      live branch marking, dead region handling, and CFG update fixtures.
- [ ] Implement SCCP for integer, pointer-null, branch, PHI, and select cases
      observed in Zig-emitted IR.
- [ ] Rework SCCP toward LLVM's algorithm in slices:
      unknown/undef/constant/overdefined lattice values, executable block and
      edge tracking, sparse instruction visitor, undef resolution loop, and
      unreachable edge/block folding.
- [ ] Implement GVN for pure expressions and memory-safe cases only.
- [ ] Rework GVN toward LLVM's algorithm in slices:
      ValueTable, leader tables, value numbering for expressions/PHIs/casts/
      calls/loads, load availability, MemoryDependence or MemorySSA-backed
      checks, PRE, and duplicate-PHI elimination.
- [ ] Implement EarlyCSE after memory legality supports it:
      scoped hash table per dominator scope, available loads/calls/stores,
      MemorySSA-backed generation and clobber checks, store-to-load forwarding,
      and call CSE guarded by effect rules.
- [ ] Implement jump threading only after branch conditions, PHI translation,
      and CFG simplification are stable.
- [ ] Implement reassociation only for operations where flags and poison
      semantics are documented.
- [ ] Implement correlated value propagation and related range folds only after
      comparison and branch semantics are stable.
- [ ] Add pass manager ordering tests for selected scalar pipelines.
- [ ] For every accepted fixture, add a paired rejected or deferred fixture when
      LLVM handles a broader case than the local implementation.
- [ ] Add pipeline fixtures using the same pass sequence Zig uses for the
      covered optimization mode.
- [ ] Compare LLVM-equivalent fixtures against `opt-22`.

## Deliverables

- [ ] Scalar optimization dependency map.
- [ ] Per-pass design notes and gap tables.
- [ ] Per-pass parity checklist entries.
- [ ] Zig-emitted scalar optimization fixtures.
- [ ] Pipeline ordering tests.

## Exit Criteria

- [ ] The local scalar pipeline improves canonical IR without relying on
      undocumented LLVM assumptions.
- [ ] Each scalar pass has explicit semantic prerequisites and known gaps.
- [ ] Fixture results separate LLVM-equivalent behavior from conservative local
      behavior.
- [ ] No scalar pass is marked reproduced below `fixture-equivalent`.
