# Epic 3: LLVM-Compatible IR Verifier Foundation

## Goal

Implement enough verifier and semantic checking to reject malformed IR before
optimizer passes depend on invalid assumptions.

This epic is the safety gate for all later optimizer work.

## Inputs

- Zig-emitted IR corpus from `02_zig_emitted_ir_corpus.md`
- LLVM verifier behavior observed through LLVM 22
- Existing local IR parser and semantics docs

## Plan

- [x] Document verifier scope for the first milestone:
      CFG shape, terminators, PHI placement, type consistency, dominance,
      attributes, globals, function declarations, and data layout basics.
- [x] Add analysis inventory hooks needed by later optimizer parity work:
      DominatorTree, PostDominatorTree, control-dependence queries,
      executable CFG block/edge tracking, sparse value lattice, scoped hash
      tables, MemorySSA-like memory state, AliasAnalysis/ModRef, and global-use
      graph.
- [x] Add block and instruction indexing helpers used by verifier diagnostics.
- [x] Implement CFG validity checks:
      entry block, terminators, predecessor/successor agreement, unreachable
      block handling, and malformed branch targets.
- [x] Implement PHI checks:
      incoming block count, incoming block identity, incoming value type, and
      placement before non-PHI instructions.
- [x] Implement SSA dominance checks for instruction and PHI uses.
- [x] Implement basic type checks for arithmetic, casts, loads, stores, calls,
      returns, comparisons, GEP, and select.
- [x] Implement function declaration and call signature checks.
- [x] Implement data-layout and target-triple validation hooks without trying
      to model every target detail in the first slice.
- [x] Add diagnostic tests that compare accepted/rejected cases with LLVM 22
      where behavior should match.

## Deliverables

- [x] Verifier design doc under `../semantics`.
- [x] Verifier implementation in the local IR layer.
- [x] Analysis prerequisite inventory for optimizer epics.
- [x] Zig-emitted verifier fixture coverage.
- [x] LLVM 22 comparison notes.

## Exit Criteria

- [x] Optimizer passes can require verified IR as input.
- [x] Invalid SSA, PHI, CFG, and obvious type errors are rejected.
- [x] Known verifier gaps are listed with examples.

## Implementation Notes

- Verifier scope and known gaps are documented in
  `docs/semantics/ir_verifier_foundation.md` and `docs/ir_verifier.md`.
- Shared optimizer analysis prerequisites are documented in
  `docs/analysis/optimizer_analysis_prerequisites.md`.
- The local verifier now rejects empty function bodies, duplicate block labels,
  entry-block predecessors, malformed branch targets, PHI/CFG mismatches,
  invalid SSA dominance, call signature and calling-convention mismatches,
  invalid non-power-of-two memory alignment, unknown atomic orderings, and
  malformed target records for the accepted IR subset.
- The first Zig-originated verifier fixture remains the normalized tiny scalar
  corpus from `docs/fixtures/zig_ir/README.md`.
