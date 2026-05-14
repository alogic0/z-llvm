# Epic 1: Zig LLVM Dependency Inventory

## Goal

Identify exactly what LLVM, LLD, and Clang-adjacent behavior Zig currently uses,
then keep that inventory source-backed as Zig changes.

This epic answers: what must this repository understand before it implements or
compares anything?

## Inputs

- `docs/LLVM_replace.md`
- `../inventory/zig_llvm_api_inventory.md`
- `../inventory/zig_llvm_pass_pipeline_inventory.md`
- Zig source files that call into LLVM, LLD, Clang, or LLVM IR emission

## Plan

- [x] Create a single inventory index that links API, pass-pipeline, target,
      debug-info, object, linker, and C frontend dependency inventories.
- [x] Mark each dependency as one of:
      `optimizer`, `IR semantics`, `target/data-layout`, `codegen`,
      `debug info`, `object/linker`, `C frontend`, `LTO`,
      `sanitizer/instrumentation`, or `tooling`.
- [x] For every LLVM API use, record:
      source file, call site, upstream subsystem, local replacement status, and
      whether this repository should implement, compare, document, or ignore it.
- [x] For every pass-pipeline entry, record:
      optimization mode, pass name, LLVM pipeline position, local priority, and
      semantic prerequisites.
- [x] Separate hard dependencies from optional handoff paths.
- [x] Add a "not this repository" table for LLD, Clang, archive tooling,
      translate-c, and preprocessor work unless they affect optimizer behavior.
- [x] Add a maintenance note explaining how to refresh the inventory when Zig
      updates its LLVM integration.

## Deliverables

- [x] `../inventory/zig_llvm_dependency_inventory_index.md`
- [x] Updated API inventory links and status fields.
- [x] Updated pass-pipeline inventory links and status fields.
- [x] Gap table for unknown or unclassified dependencies.

## Exit Criteria

- [x] A reader can tell which LLVM responsibilities are in scope for this repo.
- [x] Optimizer work can be selected from a source-backed pipeline list.
- [x] Backend/linker/C frontend work is clearly separated from optimizer work.

## Implementation Notes

- Added `../inventory/zig_llvm_dependency_inventory_index.md` as the durable
  dependency index.
- The project goal is now explicitly Zig-aligned: source-backed inventory first,
  Zig-emitted IR fixtures second, verifier/semantic prerequisites third, and
  optimizer reproduction only from Zig's actual LLVM pipeline.
- Linker, archive, Clang, broad backend, sanitizer, debug, bitcode, and LTO work
  are visible in the inventory but are not optimizer scope unless a future
  source-backed slice activates them.
