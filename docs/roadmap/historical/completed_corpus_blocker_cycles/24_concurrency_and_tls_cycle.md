# Cycle 24: Concurrency And TLS

## Goal

Classify thread-local storage and concurrency-related IR so optimizer passes
preserve target and memory semantics.

## Source Anchors

- Zig source: TLS and atomics fixtures to be added when needed
- LLVM IR: `thread_local`, atomic memory model, fences
- Local analyses: memory effects, globals, target DataLayout

## Plan

- [x] Add source-backed Zig fixtures for TLS if Zig emits relevant LLVM IR.
- [x] Parse or reject `thread_local` global forms explicitly.
- [x] Parse fence instructions as barriers if accepted.
- [x] Treat concurrency-related globals and calls as conservative roots.
- [x] Add fixtures ensuring DCE/GlobalDCE do not remove live TLS state.
- [x] Document target-specific TLS lowering as backend/out-of-scope until
      native handoff requires it.

## Exit Criteria

- [x] TLS/concurrency constructs are not silently ignored.
- [x] Memory passes respect fences and atomic barriers.
- [x] Backend-specific TLS lowering remains separated from optimizer legality.

## Completion Notes

- `thread_local` scalar global/constant forms are parsed and printed as raw
  address attributes.
- GlobalDCE treats thread-local globals as conservative roots.
- Added `globaldce_tls_root` as a local-conservative fixture.
- Fence, atomic RMW, compare-exchange, syncscope, and inline asm remain
  fail-closed through the atomics/inline-asm boundary.
