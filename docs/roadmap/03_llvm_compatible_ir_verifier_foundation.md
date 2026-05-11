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

- [ ] Document verifier scope for the first milestone:
      CFG shape, terminators, PHI placement, type consistency, dominance,
      attributes, globals, function declarations, and data layout basics.
- [ ] Add analysis inventory hooks needed by later optimizer parity work:
      DominatorTree, PostDominatorTree, control-dependence queries,
      executable CFG block/edge tracking, sparse value lattice, scoped hash
      tables, MemorySSA-like memory state, AliasAnalysis/ModRef, and global-use
      graph.
- [ ] Add block and instruction indexing helpers used by verifier diagnostics.
- [ ] Implement CFG validity checks:
      entry block, terminators, predecessor/successor agreement, unreachable
      block handling, and malformed branch targets.
- [ ] Implement PHI checks:
      incoming block count, incoming block identity, incoming value type, and
      placement before non-PHI instructions.
- [ ] Implement SSA dominance checks for instruction and PHI uses.
- [ ] Implement basic type checks for arithmetic, casts, loads, stores, calls,
      returns, comparisons, GEP, and select.
- [ ] Implement function declaration and call signature checks.
- [ ] Implement data-layout and target-triple validation hooks without trying
      to model every target detail in the first slice.
- [ ] Add diagnostic tests that compare accepted/rejected cases with LLVM 22
      where behavior should match.

## Deliverables

- [ ] Verifier design doc under `../semantics`.
- [ ] Verifier implementation in the local IR layer.
- [ ] Analysis prerequisite inventory for optimizer epics.
- [ ] Zig-emitted verifier fixture coverage.
- [ ] LLVM 22 comparison notes.

## Exit Criteria

- [ ] Optimizer passes can require verified IR as input.
- [ ] Invalid SSA, PHI, CFG, and obvious type errors are rejected.
- [ ] Known verifier gaps are listed with examples.
