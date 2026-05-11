# Optional Bitcode, Debug, And LTO Tracks

This document keeps large optional LLVM-removal tracks visible without making
them blockers for the core verifier and optimizer roadmap.

## Track Index

| Track | Primary doc | Current local status | Activation rule |
| --- | --- | --- | --- |
| LLVM bitcode handoff | `docs/bitcode/construct_inventory.md` | Inventory only; no writer. | Activate only when Zig needs LLVM IR/bitcode output without libLLVM or when a fixture requires bitcode round-trip validation. |
| Debug-info preservation | `docs/debug/metadata_inventory.md` | Raw module metadata preservation plus sanitizer/debug placeholders. | Activate when a Zig-emitted fixture includes debug metadata that a local parser/pass would otherwise drop or corrupt. |
| ThinLTO/FullLTO behavior | `docs/lto/behavior_gaps.md` | Pre-link pipeline names and placeholders only. | Activate when a source-backed LTO mode needs local pre-link behavior beyond the current scalar/global foundations. |
| Sanitizer and instrumentation metadata | `docs/passes/instrumentation_metadata.md` | Placeholder passes and raw metadata round-trip only. | Activate when sanitizer runtime declarations, callback insertion, or sanitizer attributes are represented in accepted IR. |
| Vectorization | `docs/roadmap/historical/vector_ir_and_target_cost_epic.md` | Deferred placeholder surface. | Activate only after vector IR, target features, TargetTransformInfo, LoopAccessAnalysis, and cost modeling are represented. |
| Target-specific codegen details | `docs/codegen/zig_native_backend_handoff.md` | Validation-only x86_64 SysV bootstrap. | Activate only for tiny validation fixtures or source-backed target layout assumptions. |

## Zig Source Anchors

All paths are relative to `prog`.

```text
ziglang/src/Compilation/Config.zig:
  selects LTO mode, debug format, sanitizer options, and LLVM backend needs

ziglang/src/codegen/llvm.zig:
  builds LLVM modules, debug metadata, bitcode buffers, TargetMachine options,
  sanitizer attributes, and final emit options

ziglang/src/codegen/llvm/bindings.zig:
  exposes MemoryBuffer, bitcode parsing, broken-debug-info checks, and
  TargetMachine emit options

ziglang/src/zig_llvm.cpp:
  constructs LLVM pass pipelines, sanitizer callbacks, LTO pre-link pipelines,
  bitcode/object/asm/text-IR emission, and debug-info diagnostics

ziglang/src/link/Lld.zig:
  shapes LLD LTO flags, debug-section compression flags, and sanitizer-related
  link behavior
```

## Separation Rules

```text
bitcode is a compatibility and migration track, not the local optimizer's main IR
debug metadata must be preserved or explicitly rejected before passes transform it
LTO is a pipeline and summary-index track, not just "more optimization passes"
sanitizer passes require runtime ABI and inserted-call support before implementation
vectorization requires vector IR, memory dependence, target cost, and codegen support
codegen experiments remain validation-only unless a source-backed slice activates them
```

## Activation Criteria

| Optional track | Required before implementation |
| --- | --- |
| Bitcode writer | Module records, type table, constants, functions, metadata, attributes, target records, and use-list order for the accepted IR subset are inventoried. |
| Bitcode parser | A Zig or LLVM fixture exists where text IR is insufficient and bitcode input is the actual handoff artifact. |
| Debug metadata preservation | Parser/printer can attach metadata to modules, globals, functions, instructions, and debug locations without silently dropping unknown nodes. |
| Debug metadata updating | A pass mutates instructions or CFG with attached debug locations and has a documented LLVM updater behavior to reproduce. |
| LTO pre-link expansion | Alias/global/summary-related IR constructs exist locally and `opt-22` comparison fixtures are available. |
| ThinLTO summary behavior | Bitcode summary index, import/export, WPD, and post-link pipeline decisions are inventoried. |
| Sanitizer coverage or TSan | Runtime hooks, attributes, memory-access modeling, and module/function metadata are represented. |
| Vectorization | Vector types/instructions, LoopAccessAnalysis, ScalarEvolution, TTI, and target codegen validation are available. |

## Current Local Boundary

Implemented today:

```text
raw top-level module metadata round-trip
debug/profile/sanitizer pass placeholders
lto-prelink-o3 and lto-prelink-oz pipeline names
canonicalize-aliases and name-anon-globals placeholders
vectorization pass placeholders
tiny x86_64 assembly/object validation path
```

Not implemented:

```text
LLVM bitcode writer or parser
metadata graph semantics
debug locations on instructions
debug-info updater behavior in passes
sanitizer callback insertion
ThinLTO summary index or post-link pipeline behavior
loop or SLP vectorization
general target codegen replacement
```

## Development Rule

When an optional track becomes relevant, first add a bounded source-backed slice
to the track's own doc and only then pull a small implementation task into the
active roadmap. Do not mix bitcode, debug, LTO, sanitizer, vector, and backend
work in one implementation slice.
