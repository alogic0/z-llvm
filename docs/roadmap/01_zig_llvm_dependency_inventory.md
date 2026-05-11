# Epic 1: Zig LLVM Dependency Inventory

## Goal

Identify exactly what LLVM, LLD, and Clang-adjacent behavior Zig currently uses,
then keep that inventory source-backed as Zig changes.

This epic answers: what must this repository understand before it implements or
compares anything?

## Inputs

- `zig_upstream_llvm_removal_path.md`
- `../inventory/zig_llvm_api_inventory.md`
- `../inventory/zig_llvm_pass_pipeline_inventory.md`
- Zig source files that call into LLVM, LLD, Clang, or LLVM IR emission

## Plan

- [ ] Create a single inventory index that links API, pass-pipeline, target,
      debug-info, object, linker, and C frontend dependency inventories.
- [ ] Mark each dependency as one of:
      `optimizer`, `IR semantics`, `codegen`, `debug info`, `object/linker`,
      `C frontend`, `LTO`, or `tooling`.
- [ ] For every LLVM API use, record:
      source file, call site, upstream subsystem, local replacement status, and
      whether this repository should implement, compare, document, or ignore it.
- [ ] For every pass-pipeline entry, record:
      optimization mode, pass name, LLVM pipeline position, local priority, and
      semantic prerequisites.
- [ ] Separate hard dependencies from optional handoff paths.
- [ ] Add a "not this repository" table for LLD, Clang, archive tooling,
      translate-c, and preprocessor work unless they affect optimizer behavior.
- [ ] Add a maintenance note explaining how to refresh the inventory when Zig
      updates its LLVM integration.

## Deliverables

- [ ] `../inventory/zig_llvm_dependency_inventory_index.md`
- [ ] Updated API inventory links and status fields.
- [ ] Updated pass-pipeline inventory links and status fields.
- [ ] Gap table for unknown or unclassified dependencies.

## Exit Criteria

- [ ] A reader can tell which LLVM responsibilities are in scope for this repo.
- [ ] Optimizer work can be selected from a source-backed pipeline list.
- [ ] Backend/linker/C frontend work is clearly separated from optimizer work.
