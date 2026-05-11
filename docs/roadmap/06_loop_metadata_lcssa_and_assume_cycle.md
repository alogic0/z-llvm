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

- [ ] Inventory loop metadata, assume calls, and PHI/LCSSA-like values in the
      control-flow corpus.
- [ ] Parse and preserve loop metadata attachments as inert metadata first.
- [ ] Model `llvm.assume` conservatively for memory/control side effects.
- [ ] Add verifier checks for LCSSA-adjacent loop exit value shapes where the
      local IR can represent them.
- [ ] Extend LoopInfo tests from synthetic loops to corpus-derived loops.
- [ ] Keep loop memory optimizations disabled unless Cycle 3 legality proves
      them.
- [ ] Promote a reduced control-flow/calls fixture to accepted optimizer input.

## Exit Criteria

- [ ] Corpus loop metadata no longer blocks parsing when it can be preserved
      inertly.
- [ ] Loop analyses classify corpus-derived loops without crashing or
      over-transforming.
- [ ] LICM and loop simplification remain correct-first.

