# Cycle 24: Concurrency And TLS

## Goal

Classify thread-local storage and concurrency-related IR so optimizer passes
preserve target and memory semantics.

## Source Anchors

- Zig source: TLS and atomics fixtures to be added when needed
- LLVM IR: `thread_local`, atomic memory model, fences
- Local analyses: memory effects, globals, target DataLayout

## Plan

- [ ] Add source-backed Zig fixtures for TLS if Zig emits relevant LLVM IR.
- [ ] Parse or reject `thread_local` global forms explicitly.
- [ ] Parse fence instructions as barriers if accepted.
- [ ] Treat concurrency-related globals and calls as conservative roots.
- [ ] Add fixtures ensuring DCE/GlobalDCE do not remove live TLS state.
- [ ] Document target-specific TLS lowering as backend/out-of-scope until
      native handoff requires it.

## Exit Criteria

- [ ] TLS/concurrency constructs are not silently ignored.
- [ ] Memory passes respect fences and atomic barriers.
- [ ] Backend-specific TLS lowering remains separated from optimizer legality.

