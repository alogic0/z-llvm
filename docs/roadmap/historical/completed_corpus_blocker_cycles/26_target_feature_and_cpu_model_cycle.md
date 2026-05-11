# Cycle 26: Target Feature And CPU Model

## Goal

Track target CPU/features enough to avoid wrong optimizer assumptions and to
prepare future target-cost or backend-handoff work.

## Source Anchors

- Zig target model: `../ziglang/src/target.zig`
- LLVM: TargetMachine, TargetTransformInfo, subtarget features
- Local target docs: `docs/target/datalayout.md`,
  `docs/target/scalar_abi.md`

## Plan

- [x] Inventory target feature strings emitted or implied by Zig fixtures.
- [x] Parse target-cpu and target-features attributes when present.
- [x] Preserve feature attributes through parser/printer.
- [x] Avoid using target features for transforms until local TTI exists.
- [x] Add target-feature docs for vector and codegen future cycles.
- [x] Add non-host target fixture checks for feature preservation.

## Exit Criteria

- [x] Target feature metadata is preserved or rejected explicitly.
- [x] Optimizer docs state that no target-cost decisions use features yet.
- [x] Non-host fixtures keep target facts visible.

## Completion Notes

- Added `src/target/features.zig` to extract `target-cpu` and
  `target-features` from preserved raw LLVM attribute text.
- Added docs stating that feature metadata is not used for optimization or
  codegen decisions until a local TTI/subtarget model exists.
- Existing non-host target/DataLayout tests keep target facts visible; this
  cycle does not add a CPU model database or feature implication graph.
