# Cycle 6: Loop Metadata, LCSSA, And Assume

## Goal

Accept the control-flow loop corpus surface without pretending to implement
LLVM's full loop pipeline: loop metadata preservation, `llvm.assume`,
LCSSA-adjacent verification, inlined calls, and safer loop pass gating.

## Source Anchors

- Corpus row: `control_flow_calls_release_fast`
- Local code: `src/analysis/loop_info.zig`, `src/passes/licm.zig`,
  `src/passes/loop_instsimplify.zig`, `src/passes/simplifycfg.zig`
- LLVM: `LoopSimplify`, `LCSSA`, `LICM`, `LoopInstSimplify`

## Plan

- [x] Inventory loop metadata, assume calls, and PHI/LCSSA-like values in the
      control-flow corpus.
- [x] Parse and preserve loop metadata attachments as inert metadata first.
- [x] Model `llvm.assume` conservatively for memory/control side effects.
- [x] Add verifier checks for LCSSA-adjacent loop exit value shapes where the
      local IR can represent them.
- [x] Extend LoopInfo tests from synthetic loops to corpus-derived loops.
- [x] Keep loop memory optimizations disabled unless Cycle 3 legality proves
      them.
- [x] Promote a reduced control-flow/calls fixture to accepted optimizer input.

## Exit Criteria

- [x] Corpus loop metadata no longer blocks parsing when it can be preserved
      inertly.
- [x] Loop analyses classify corpus-derived loops without crashing or
      over-transforming.
- [x] LICM and loop simplification remain correct-first.

## Completed Slice 1: Inert Loop Metadata Preservation

- `src/ir/parser.zig` now preserves trailing branch metadata attachments such
  as `!llvm.loop !0` on `br`/conditional `br` terminators.
- `src/ir/printer.zig` round-trips those attachments without interpreting the
  metadata graph.
- `llvm.assume` remains a conservative side-effecting call from Cycle 2.
- Existing LoopInfo LCSSA-adjacent tests cover accepted and rejected synthetic
  loop exit value shapes.

## Completed Slice 2: Corpus-Shaped LoopInfo Test

- Added a reduced `control_flow_calls`-style loop with numeric entry label,
  `.lr.ph` labels, LCSSA-like exit PHI, and inert `!llvm.loop` metadata.
- Verified LoopInfo header, latch, preheader, exiting block, exit block, and
  LCSSA checks on that corpus-derived shape.
