# Cycle 23: Bitcode, LTO, and ThinLTO Compatibility Decision

## Goal

Decide, with evidence, whether the next implementation track needs LLVM
bitcode/LTO compatibility or should remain text-IR and native-handoff focused.

## Plan

- [ ] Inventory Zig use cases that still require LLVM bitcode, LTO, ThinLTO,
      sanitizer metadata, or linker-plugin behavior.
- [ ] Compare the cost of a minimal bitcode writer against continuing with
      textual IR fixtures and Zig native backend handoff.
- [ ] Define the smallest bitcode construct set if compatibility is selected.
- [ ] Define explicit non-goals if compatibility remains deferred.
- [ ] Add one proof fixture or fixture design for module summary, bitcode
      round-trip, or text-IR-only validation.
- [ ] Update bitcode, LTO, and upstream integration docs.
- [ ] Record the decision as implementation-ready follow-up cycles.

## Exit Criteria

- [ ] The project has a documented bitcode/LTO decision, not an implicit gap.
- [ ] Required Zig use cases are linked to concrete artifacts.
- [ ] Follow-up work is split into implementable cycles.
