# Epic 4: Mandatory Canonicalization Passes

## Goal

Implement the canonicalization passes that later optimization slices assume are
available, starting with behavior Zig actually gets from LLVM's pass pipeline.

## Inputs

- `../inventory/zig_llvm_pass_pipeline_inventory.md`
- Verifier foundation from `03_llvm_compatible_ir_verifier_foundation.md`
- Zig-emitted IR corpus

## Plan

- [ ] Define the P0 canonicalization pass set from the pass-pipeline inventory.
- [ ] Add the optimizer parity checklist to every canonicalization pass doc:
      LLVM source files, entry points/classes, required analyses, core data
      structures, unsupported behavior, and `opt-22` fixtures.
- [ ] Implement `mem2reg` for allocas that satisfy conservative promotability
      rules.
- [ ] Tighten `mem2reg` toward LLVM's algorithm in slices:
      entry-block alloca discovery, single-store fast path, single-block fast
      path, live-in pruning, IDF-based PHI placement, and rename-stack fixtures.
- [ ] Implement basic SROA for scalar and simple aggregate alloca patterns
      observed in Zig-emitted IR.
- [ ] Rebuild SROA around LLVM's real model as the supported IR surface grows:
      alloca slices, partitions, DataLayout offset/size reasoning, rewrite
      decisions, and explicit rejection for unsupported aggregate/vector cases.
- [ ] Implement InstSimplify rules needed by fixtures:
      identity arithmetic, constant comparisons, select simplifications, and
      simple cast folding.
- [ ] Implement InstCombine rules only when backed by a fixture and a local
      correctness note.
- [ ] Implement SimplifyCFG basics:
      empty block folding, branch-on-constant, unreachable successor cleanup,
      trivial PHI cleanup, and simple return merging where safe.
- [ ] Add pass ordering docs explaining why each canonicalization must run
      before scalar or loop optimization.
- [ ] For each canonicalization pass, mark status as `placeholder`,
      `LLVM-shaped subset`, `fixture-equivalent`, or `algorithm-parity target`.
- [ ] Compare LLVM-equivalent fixtures against `opt-22`.
- [ ] Document deliberate local conservative gaps separately from mismatches.

## Deliverables

- [ ] Canonicalization design doc.
- [ ] P0 pass implementations or status tables.
- [ ] Per-pass parity checklist entries.
- [ ] Zig-emitted before/after fixtures.
- [ ] `opt-22` comparison notes.

## Exit Criteria

- [ ] Later scalar and loop passes can rely on stable canonical IR shapes.
- [ ] Mandatory correctness-preserving transforms have fixture coverage.
- [ ] Non-implemented LLVM behavior is explicitly marked as a gap.
- [ ] No canonicalization pass is marked reproduced below `fixture-equivalent`.
