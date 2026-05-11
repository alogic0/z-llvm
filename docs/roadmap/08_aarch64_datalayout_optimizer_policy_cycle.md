# Cycle 8: AArch64 DataLayout Optimizer-Input Policy

## Goal

Define when non-host target captures, starting with AArch64, may become optimizer
input and which target/DataLayout differences must be modeled first.

## Source Anchors

- Manifest row: `integers_release_fast_aarch64`
- Local target code: `src/target/datalayout.zig`, `src/target/abi.zig`
- LLVM comparison: target-specific `opt-22` output where relevant
- Docs: target DataLayout and Zig native backend handoff notes

## Plan

- [x] Inventory AArch64 DataLayout differences visible in current Zig captures.
- [x] Identify which local passes are target-independent for the accepted IR
      surface and which depend on type size, alignment, or ABI.
- [x] Add policy docs for promoting non-host captures to `optimizer-input`.
- [x] Add AArch64 parse/verify fixtures that do not run target-sensitive
      transforms yet.
- [x] Add opt comparison fixtures only for target-independent transforms.
- [x] Keep AArch64 codegen, object emission, and ABI lowering out of scope.

## Exit Criteria

- [x] AArch64 corpus rows have a clear policy for parse-only vs optimizer-input.
- [x] Target-independent optimizer acceptance is backed by tests.
- [x] Target-sensitive gaps are documented before any non-host promotion.

## Completed Slice

Cycle 8 adds `docs/target/aarch64_optimizer_policy.md` and keeps
`integers_release_fast_aarch64` as `parse,verify,target-layout,future` until
every selected pipeline pass is audited as target-independent,
DataLayout-aware, or disabled. The new `aarch64_instcombine_target_independent`
fixture compares scalar integer identity folding with `opt-22` while preserving
the AArch64 target records.
