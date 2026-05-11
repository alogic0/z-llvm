# Cycle 23: Bitcode, LTO, and ThinLTO Compatibility Decision

## Goal

Decide, with evidence, whether the next implementation track needs LLVM
bitcode/LTO compatibility or should remain text-IR and native-handoff focused.

## Plan

- [x] Inventory Zig use cases that still require LLVM bitcode, LTO, ThinLTO,
      sanitizer metadata, or linker-plugin behavior.
- [x] Compare the cost of a minimal bitcode writer against continuing with
      textual IR fixtures and Zig native backend handoff.
- [x] Define the smallest bitcode construct set if compatibility is selected.
- [x] Define explicit non-goals if compatibility remains deferred.
- [x] Add one proof fixture or fixture design for module summary, bitcode
      round-trip, or text-IR-only validation.
- [x] Update bitcode, LTO, and upstream integration docs.
- [x] Record the decision as implementation-ready follow-up cycles.

## Exit Criteria

- [x] The project has a documented bitcode/LTO decision, not an implicit gap.
- [x] Required Zig use cases are linked to concrete artifacts.
- [x] Follow-up work is split into implementable cycles.

## Completed Slice

- Added `docs/bitcode/lto_compatibility_decision.md`.
- Decided to defer bitcode writer/parser, LTO handoff, ThinLTO summaries,
  import/export, WPD, CFI, and post-link LTO until a source-backed activation
  criterion is met.
- Kept current proof fixtures text-IR-based through `zig build test` LTO
  descriptor checks and `scripts/compare_opt.sh` optimizer comparisons.
