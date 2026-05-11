# Cycle 17: Loop Optimization Parity

## Goal

Move the loop pipeline from shape recognition and scalar LICM into broader
LLVM-compatible loop optimization foundations for accepted Zig-emitted loops.

## Source Anchors

- LLVM: `LoopSimplify`, `LCSSA`, `LICM`, `IndVarSimplify`, `LoopRotate`,
  `LoopDeletion`, `LoopUnswitch`
- Local code: `src/analysis/loop_info.zig`, `src/passes/licm.zig`,
  `src/passes/loop_instsimplify.zig`
- Corpus: `control_flow_calls_release_fast`

## Plan

- [ ] Implement or explicitly reject LoopRotate cases in accepted IR.
- [ ] Add LCSSA rewriting for simple scalar loop exits.
- [ ] Extend LICM to selected memory-free scalar chains across nested loops.
- [ ] Add induction-variable recognition only for source-backed loop fixtures.
- [ ] Add loop deletion for side-effect-free proven-dead loops if safe.
- [ ] Keep unswitching and vectorization deferred unless fixtures demand them.
- [ ] Compare accepted loop cases with `opt-22`.

## Exit Criteria

- [ ] Corpus-derived loops have a documented local pipeline.
- [ ] Loop transforms maintain verifier, dominance, and LCSSA invariants.
- [ ] Unsupported loop optimizations are explicitly blocked.

