# Cycle 20: TLS and Concurrency IR Acceptance

## Goal

Accept the TLS and concurrency-adjacent IR constructs Zig emits without
lowering them prematurely.

## Plan

- [x] Inventory TLS globals, thread-local modes, synchronization intrinsics,
      and concurrency-related attributes from Zig rows.
- [x] Parse and preserve supported TLS global declarations and attributes.
- [x] Add verifier checks for TLS model spelling, linkage, initializer, and
      target restrictions where known.
- [x] Treat TLS and concurrency intrinsics as optimizer barriers unless local
      semantics are implemented.
- [x] Add source-backed fixtures for TLS globals and concurrency runtime calls.
- [x] Update `docs/ir_concurrency_tls.md`, globals docs, and unsupported IR
      docs.
- [x] Keep object lowering and platform TLS ABI decisions deferred.

## Exit Criteria

- [x] At least one TLS source-backed row is accepted through parse and verify.
- [x] Unsupported TLS models or concurrency intrinsics fail closed.
- [x] Optimizers do not erase required TLS or synchronization behavior.

## Completed Slice

- Preserved known LLVM TLS model spellings on globals and rejected unknown TLS
  model text in the verifier.
- Added `globaldce_tls_model_root` to keep modeled TLS globals as conservative
  GlobalDCE roots.
- Documented that TLS model selection, relocations, thread-pointer lowering,
  and platform ABI behavior remain backend work.
