# Cycle 06: Debug Salvage Boundary Burn-Down

## Goal

Tighten debug-location behavior for transforms that already run, without
claiming full LLVM debug variable-location salvage.

## Evidence

The finish table keeps full debug variable-location salvage out of scope for
the finish line. Existing fixtures preserve `llvm.dbg.value` and
`llvm.dbg.declare` but skip transform passes when variable-location intrinsics
are present.

## Plan

- [x] Inventory transforms that remove or replace instructions carrying `!dbg`.
- [x] Add or refine fixtures for DCE, InstCombine, EarlyCSE, GVN, and the
      optimizer-quality pass selected in Cycle 05 if relevant.
- [x] Preserve debug locations on unchanged or leader instructions.
- [x] Drop debug locations only with removed instructions unless a local salvage
      rule is explicitly implemented.
- [x] Keep `llvm.dbg.value` and `llvm.dbg.declare` transform pipelines disabled
      until variable-location salvage exists.
- [x] Update debug metadata docs, affected pass docs, unsupported IR docs, and
      the finish table.
- [x] Run `bash scripts/run_readiness_checks.sh` and record the summary.

## Exit Criteria

- [x] Debug-location behavior is documented for each transform that touches it.
- [x] No accepted transform leaves dangling debug references.
- [x] Full variable-location salvage remains clearly out of scope.

## Completed Slice

```text
DCE, InstCombine, EarlyCSE, and GVN already had debug-location-only fixtures.
Cycle 06 adds `debug_sroa_dbg_drop` for the Cycle 05 optimizer-quality SROA
slice. The fixture proves aggregate stack instructions carrying `!dbg` can be
removed while unchanged scalar instructions keep their locations. Debug value
and declare intrinsics remain verifier-only transform blockers until
variable-location salvage is implemented.
Readiness passed with `manifest rows=37 optimizer_input=30` and
`summary accepted=30 unsupported=0 future=4 debug-info-only=0`.
```
