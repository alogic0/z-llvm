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

- [x] Implement or explicitly reject LoopRotate cases in accepted IR.
- [x] Add LCSSA rewriting for simple scalar loop exits.
- [x] Extend LICM to selected memory-free scalar chains across nested loops.
- [x] Add induction-variable recognition only for source-backed loop fixtures.
- [x] Add loop deletion for side-effect-free proven-dead loops if safe.
- [x] Keep unswitching and vectorization deferred unless fixtures demand them.
- [x] Compare accepted loop cases with `opt-22`.

## Exit Criteria

- [x] Corpus-derived loops have a documented local pipeline.
- [x] Loop transforms maintain verifier, dominance, and LCSSA invariants.
- [x] Unsupported loop optimizations are explicitly blocked.

## Slice 1 Notes

- `src/analysis/loop_info.zig` now recognizes simple integer induction PHIs in
  the reduced Zig corpus loop shape.
- LoopInfo can classify side-effect-free loop-deletion candidates, but no
  deletion transform runs yet.
- LoopRotate mutation, full LCSSA insertion, IndVarSimplify rewrites, and
  LoopDeletion mutation remain explicit future work.

## Completion Notes

- Added a simple scalar LCSSA formation helper for one-exit accepted loop shapes
  with dedicated exits and verifier-clean rewrite coverage. Non-dedicated exits
  are rejected so inserted PHIs cannot miss outside-predecessor incoming edges.
- Added explicit LoopRotate status classification. Current accepted self-latch
  and non-canonical cases are rejected rather than transformed.
- Added LoopDeletion status classification. Side-effect-free loops can be
  recognized as eligible, but deletion remains blocked until exit/progress and
  CFG rewrite safety are implemented.
- Added `licm_nested_scalar_chain` as an `opt-22` compared fixture for nested
  memory-free scalar-chain LICM.
- Unswitching, vectorization, full LoopRotate, full LCSSA, IndVarSimplify
  rewrites, and LoopDeletion mutation remain deferred.
