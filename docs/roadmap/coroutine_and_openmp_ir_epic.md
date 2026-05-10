# Coroutine And OpenMP IR Epic

Status: future epic.

Goal: add explicit coroutine and OpenMP IR domains before enabling the
coroutine or OpenMP optimizer placeholders.

## Required Coroutine Slices

- Parse and verify coroutine intrinsics used by LLVM coroutine lowering.
- Represent coroutine frame, suspend, resume, and cleanup state.
- Add lowering fixtures before enabling `coro-early`, `coro-split`,
  `coro-elide`, `coro-cleanup`, or `coro-annotation-elide`.

## Required OpenMP Slices

- Inventory whether Zig-selected LLVM modes can emit OpenMP optimizer inputs.
- Represent OpenMP runtime calls and metadata if a concrete Zig mode needs them.
- Add explicit local diagnostics for unsupported OpenMP optimizer input.

## Upstream Mapping

```text
llvm-project-22/llvm/lib/Transforms/Coroutines/
llvm-project-22/llvm/lib/Transforms/IPO/OpenMPOpt.cpp
```
