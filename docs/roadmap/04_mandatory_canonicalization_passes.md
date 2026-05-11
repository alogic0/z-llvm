# Epic 4: Mandatory Canonicalization Passes

## Goal

Implement the canonicalization passes that later optimization slices assume are
available, starting with behavior Zig actually gets from LLVM's pass pipeline.

## Inputs

- `../inventory/zig_llvm_pass_pipeline_inventory.md`
- Verifier foundation from `03_llvm_compatible_ir_verifier_foundation.md`
- Zig-emitted IR corpus

## Plan

- [x] Define the P0 canonicalization pass set from the pass-pipeline inventory.
- [x] Add the optimizer parity checklist to every canonicalization pass doc:
      LLVM source files, entry points/classes, required analyses, core data
      structures, unsupported behavior, and `opt-22` fixtures.
- [x] Implement `mem2reg` for allocas that satisfy conservative promotability
      rules.
- [x] Tighten `mem2reg` toward LLVM's algorithm in slices:
      entry-block alloca discovery, single-store fast path, single-block fast
      path, live-in pruning, IDF-based PHI placement, and rename-stack fixtures.
- [x] Implement basic SROA for scalar and simple aggregate alloca patterns
      observed in Zig-emitted IR, with aggregate/vector cases explicitly
      deferred until the local IR type surface supports them.
- [x] Document the SROA rebuild path around LLVM's real model as the supported
      IR surface grows:
      alloca slices, partitions, DataLayout offset/size reasoning, rewrite
      decisions, and explicit rejection for unsupported aggregate/vector cases.
- [x] Implement InstSimplify rules needed by fixtures:
      identity arithmetic, constant comparisons, select simplifications, and
      simple cast folding.
- [x] Implement InstCombine rules only when backed by a fixture and a local
      correctness note.
- [x] Implement SimplifyCFG basics:
      empty block folding, branch-on-constant, unreachable successor cleanup,
      trivial PHI cleanup, and simple return merging where safe.
- [x] Add pass ordering docs explaining why each canonicalization must run
      before scalar or loop optimization.
- [x] For each canonicalization pass, mark status as `placeholder`,
      `LLVM-shaped subset`, `fixture-equivalent`, or `algorithm-parity target`.
- [x] Compare LLVM-equivalent fixtures against `opt-22`.
- [x] Document deliberate local conservative gaps separately from mismatches.

## Deliverables

- [x] Canonicalization design doc.
- [x] P0 pass implementations or status tables.
- [x] Per-pass parity checklist entries.
- [x] Zig-emitted before/after fixtures.
- [x] `opt-22` comparison notes.

## Exit Criteria

- [x] Later scalar and loop passes can rely on stable canonical IR shapes.
- [x] Mandatory correctness-preserving transforms have fixture coverage.
- [x] Non-implemented LLVM behavior is explicitly marked as a gap.
- [x] No P0 mandatory canonicalization pass in this epic is marked reproduced
      below `fixture-equivalent`.

## Implementation Notes

- Canonicalization scope, pass ordering, P0 status, fixture coverage, and gaps
  are documented in `docs/semantics/mandatory_canonicalization.md`.
- P0 pass docs now carry fixture-equivalent status for the listed accepted IR
  fixtures: `mem2reg`, `sroa`, `instsimplify`, `instcombine`, and
  `simplifycfg`.
- `mem2reg` now has an explicit single-store fast path when the single store
  dominates every load, with an `opt-22` comparison fixture.
- Full aggregate/vector SROA remains a documented unsupported LLVM behavior
  until the local IR represents aggregate and vector types.
