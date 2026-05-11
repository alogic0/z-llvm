# Cycle 20: TLS and Concurrency IR Acceptance

## Goal

Accept the TLS and concurrency-adjacent IR constructs Zig emits without
lowering them prematurely.

## Plan

- [ ] Inventory TLS globals, thread-local modes, synchronization intrinsics,
      and concurrency-related attributes from Zig rows.
- [ ] Parse and preserve supported TLS global declarations and attributes.
- [ ] Add verifier checks for TLS address-space, linkage, initializer, and
      target restrictions where known.
- [ ] Treat TLS and concurrency intrinsics as optimizer barriers unless local
      semantics are implemented.
- [ ] Add source-backed fixtures for TLS globals and concurrency runtime calls.
- [ ] Update `docs/ir_concurrency_tls.md`, globals docs, and unsupported IR
      docs.
- [ ] Keep object lowering and platform TLS ABI decisions deferred.

## Exit Criteria

- [ ] At least one TLS source-backed row is accepted through parse and verify.
- [ ] Unsupported TLS models or concurrency intrinsics fail closed.
- [ ] Optimizers do not erase required TLS or synchronization behavior.
