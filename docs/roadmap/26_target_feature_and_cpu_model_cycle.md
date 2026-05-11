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

- [ ] Inventory target feature strings emitted or implied by Zig fixtures.
- [ ] Parse target-cpu and target-features attributes when present.
- [ ] Preserve feature attributes through parser/printer.
- [ ] Avoid using target features for transforms until local TTI exists.
- [ ] Add target-feature docs for vector and codegen future cycles.
- [ ] Add non-host target fixture checks for feature preservation.

## Exit Criteria

- [ ] Target feature metadata is preserved or rejected explicitly.
- [ ] Optimizer docs state that no target-cost decisions use features yet.
- [ ] Non-host fixtures keep target facts visible.

