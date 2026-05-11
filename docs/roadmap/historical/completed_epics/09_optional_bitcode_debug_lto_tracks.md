# Epic 9: Optional LLVM Bitcode, Debug, And LTO Tracks

## Goal

Keep large optional tracks separated from the core optimizer roadmap while still
documenting how they relate to Zig's LLVM-removal path.

These tracks are important, but each can become a project of its own.

## Inputs

- `zig_upstream_llvm_removal_path.md`
- Dependency inventory from `01_zig_llvm_dependency_inventory.md`
- Zig-emitted IR corpus from `02_zig_emitted_ir_corpus.md`

## Plan

- [x] Split optional work into independent tracks:
      LLVM bitcode handoff, debug-info preservation, ThinLTO/FullLTO behavior,
      sanitizer metadata, vectorization, and target-specific codegen details.
- [x] For direct bitcode output, inventory required bitcode constructs before
      implementing any writer.
- [x] For debug info, inventory metadata emitted by Zig and identify which
      optimizer transforms must preserve or update it.
- [x] For LTO, document Zig's current LLVM pipeline phase choices and decide
      which behavior belongs in local optimizer tests.
- [x] For sanitizer and vectorization behavior, keep implementation deferred
      until scalar and loop foundations are stable.
- [x] Add source-backed activation criteria for each optional track.
- [x] Keep these tracks out of day-sized implementation slices unless the active
      optimizer work depends on them.

## Deliverables

- [x] Optional-track index doc.
- [x] Bitcode construct inventory.
- [x] Debug-info metadata inventory.
- [x] LTO behavior and gap notes.
- [x] Activation criteria table.

## Exit Criteria

- [x] Optional work is visible without blocking core optimizer progress.
- [x] Debug, LTO, sanitizer, vector, and bitcode tasks do not blur together.
- [x] Each optional track has a source-backed reason before implementation.
