# Cycle 6: Loop Pipeline Quality

## Goal

Build the loop optimizer from a scalar-only LICM subset toward the canonical
loop pipeline Zig needs before native backend handoff: loop shape, loop
simplification, LCSSA-adjacent facts, safe LICM, and simple loop instruction
simplification.

## Source Anchors

- LLVM: `llvm/lib/Transforms/Utils/LoopSimplify.cpp`
- LLVM: `llvm/lib/Transforms/Utils/LCSSA.cpp`
- LLVM: `llvm/lib/Transforms/Scalar/LICM.cpp`
- LLVM: `llvm/lib/Transforms/Scalar/LoopInstSimplify.cpp`
- Local docs: `docs/analysis/loop_info.md`, `docs/passes/licm.md`,
  `docs/passes/loop_simplify.md`, `docs/passes/loop_instsimplify.md`
- Local code: `src/analysis/loop_info.zig`, `src/passes/licm.zig`,
  `src/passes/loop_instsimplify.zig`

## Plan

- [ ] Harden LoopInfo around nested loops, multiple latches, multiple exits,
      unreachable blocks, and irreducible control flow.
- [ ] Add explicit helpers for header, latch, preheader, exiting blocks, exit
      blocks, and dedicated exits.
- [ ] Implement or document the smallest LoopSimplify subset needed before
      further LICM work.
- [ ] Add LCSSA-adjacent analysis/docs even if full LCSSA rewriting remains
      deferred.
- [ ] Extend scalar LICM only where hoisted values dominate all uses and are
      safe to speculate.
- [ ] Keep memory LICM disabled until alias/mod-ref and clobber proof are
      strong enough for the specific fixture.
- [ ] Add rejected fixtures for no preheader, multi-latch, variant operands,
      side-effecting memory, and uses before the hoist point.
- [ ] Add Zig-originated loop fixtures for Debug/ReleaseFast where available.
- [ ] Compare LLVM-equivalent cases with `opt-22`.

## Exit Criteria

- [ ] Loop shape queries are reliable enough for later passes.
- [ ] LICM remains correct-first and does not move memory without proof.
- [ ] Loop docs separate implemented behavior from LLVM's broader loop pipeline.
- [ ] `zig build test` and `bash scripts/compare_opt.sh` pass.

