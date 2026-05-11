# LLVM Algorithm Parity Gap Closure Plan

Goal: close the gaps between the local Zig implementation and the original LLVM
optimization algorithms used by Zig's LLVM pipeline.

This plan tracks algorithm reproduction, not only pass-name coverage. A pass is
not considered reproduced just because a local pass with the same name exists.

This file records parity gaps and the cycle slices that closed fixture-backed
parts of them for the currently accepted IR surface. A `Closed` item means the
planned slice is closed, not that every LLVM behavior in that area is complete.
Remaining exact-LLVM work is deferred where the local IR cannot yet represent
the LLVM construct being discussed.

## Reproduction Levels

- `Closed`: Define and use these status levels consistently in pass docs:
  - `placeholder`: pass is known but not implemented.
  - `LLVM-shaped subset`: local implementation follows the broad LLVM structure.
  - `fixture-equivalent`: local output matches LLVM for listed fixtures.
  - `algorithm-parity target`: local code implements the same core LLVM data
    structures and algorithm flow for the supported IR surface.
- `Closed`: Do not mark a pass as reproduced unless it reaches at least
      `fixture-equivalent`.
- `Closed`: Keep exact LLVM reproduction limited to the supported local IR surface, and
      document every unsupported LLVM behavior explicitly.

## Phase 1: Shared Infrastructure

- `Closed`: Add a parity checklist to every pass doc:
  - LLVM source files.
  - LLVM entry points/classes.
  - Required analyses.
  - Core LLVM data structures.
  - Unsupported LLVM behavior.
  - Exact fixtures compared with `opt-22`.
- `Closed`: Implement or document missing analysis foundations:
  - PostDominatorTree.
  - Control-dependence queries.
  - Sparse value lattice.
  - Executable CFG block and edge tracking.
  - Scoped hash tables.
  - MemorySSA-like memory state.
  - Stronger AliasAnalysis/ModRef.
  - Global-use graph for constants, globals, aliases, and comdats.

## Phase 2: Highest Algorithm Mismatches

- `Closed`: Rework `ADCE` toward LLVM ADCE:
  - Optimistic liveness worklist.
  - Postdominator-based control dependence.
  - Live branch marking.
  - Dead region and CFG update logic.
  - Fixtures where LLVM removes control-flow, not only dead scalar instructions.
- `Closed`: Rework `SCCP` toward LLVM SCCP:
  - Lattice values: unknown, undef, constant, and overdefined.
  - Executable block and edge tracking.
  - Sparse instruction visitor.
  - Undef resolution loop.
  - Unreachable edge and block folding.
  - Delay `IPSCCP` until call graph support is strong.
- `Closed`: Rework `GVN` toward LLVM GVN:
  - ValueTable.
  - Leader tables.
  - Value numbering for expressions, phi nodes, casts, calls, and loads.
  - Load availability.
  - MemoryDependence or MemorySSA-backed memory checks.
  - PRE and duplicate-phi elimination as separate slices.
- `Closed`: Rework `EarlyCSE` toward LLVM EarlyCSE:
  - Scoped hash table per dominator scope.
  - Available loads, calls, and stores.
  - MemorySSA-backed generation and clobber checks.
  - Store-to-load forwarding.
  - Call CSE guarded by matching memory/effect rules.

## Phase 3: Memory And Stack Passes

- `Done`: Tighten `mem2reg` for the accepted IR surface:
  - Keep LLVM's entry-block alloca discovery rule.
  - Add LLVM-style single-store fast path.
  - Add LLVM-style single-block fast path.
  - Add live-in pruning.
  - Add dominance-frontier PHI placement.
  - Add rename-stack comparison fixtures.
- `Closed`: Rebuild `SROA` around LLVM's real model:
  - Alloca slices.
  - Partitions.
  - DataLayout offset and size reasoning.
  - Rewrite decisions.
  - Explicit rejection for unsupported aggregate and vector cases.
- `Closed`: Expand shared memory legality:
  - Exact volatile and atomic barriers.
  - DataLayout-aware GEP offset handling.
  - Consistent ModRef queries for DCE, ADCE, GVN, EarlyCSE, LICM, and DSE.

## Phase 4: Globals And IPO

- `Closed`: Rework `GlobalDCE`:
  - Represent global references from constants and initializers.
  - Build LLVM-style global dependency graph.
  - Support aliases and ifunc placeholders safely.
  - Model comdat groups before deleting members.
  - Compare with LLVM on internal/private globals, functions, aliases, and
    constants.
- `Deferred`: Delay exact inlining until the required IR exists:
  - Function declarations.
  - Call instructions.
  - Function and call-site attributes.
  - Call graph.
  - SSA-preserving clone/import logic.

## Phase 5: Verification Loop

- `Closed`: For each pass, add paired fixtures:
  - Accepted fixture compared with `opt-22`.
  - Rejected fixture documenting LLVM behavior and the local reason for
    rejection or deferral.
  - Pipeline fixture using the same pass sequence Zig uses.
- `Closed`: Update `docs/roadmap/all_discovered_llvm_optimizations_implementation_plan.md`
      so every checked item says one of:
  - `exact for fixtures`.
  - `subset`.
  - `placeholder`.
  - `not implemented`.

## Recommended Implementation Order

- `Closed`: `ADCE`
- `Closed`: `SCCP`
- `Closed`: `EarlyCSE`
- `Closed`: `GVN`
- `Closed`: `mem2reg` accepted-surface fixture coverage
- `Closed`: `SROA`
- `Closed`: `GlobalDCE`
