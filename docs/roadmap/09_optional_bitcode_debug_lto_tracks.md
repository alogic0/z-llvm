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

- [ ] Split optional work into independent tracks:
      LLVM bitcode handoff, debug-info preservation, ThinLTO/FullLTO behavior,
      sanitizer metadata, vectorization, and target-specific codegen details.
- [ ] For direct bitcode output, inventory required bitcode constructs before
      implementing any writer.
- [ ] For debug info, inventory metadata emitted by Zig and identify which
      optimizer transforms must preserve or update it.
- [ ] For LTO, document Zig's current LLVM pipeline phase choices and decide
      which behavior belongs in local optimizer tests.
- [ ] For sanitizer and vectorization behavior, keep implementation deferred
      until scalar and loop foundations are stable.
- [ ] Add source-backed activation criteria for each optional track.
- [ ] Keep these tracks out of day-sized implementation slices unless the active
      optimizer work depends on them.

## Deliverables

- [ ] Optional-track index doc.
- [ ] Bitcode construct inventory.
- [ ] Debug-info metadata inventory.
- [ ] LTO behavior and gap notes.
- [ ] Activation criteria table.

## Exit Criteria

- [ ] Optional work is visible without blocking core optimizer progress.
- [ ] Debug, LTO, sanitizer, vector, and bitcode tasks do not blur together.
- [ ] Each optional track has a source-backed reason before implementation.
