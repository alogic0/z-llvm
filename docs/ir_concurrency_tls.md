# Concurrency And TLS IR

This cycle classifies concurrency-related IR so optimizer passes do not silently
drop thread-visible state.

## Implemented Surface

```text
@name = [linkage] thread_local global iN <int-or-undef>
@name = [linkage] thread_local constant iN <int-or-undef>
@name = [linkage] thread_local(<known-model>) [unnamed_addr] global iN <int-or-undef>
```

The `thread_local` spelling is preserved as a raw global address attribute.
GlobalDCE treats thread-local globals as conservative roots, even when their
linkage is local, because TLS allocation and access can be target/linker
visible.

Known TLS model spellings are preserved textually:

```text
localexec
initialexec
localdynamic
generaldynamic
```

## Fail-Closed Surface

```text
non-sideeffect or malformed inline asm
unknown TLS model spellings
target-specific TLS lowering and relocation selection
```

Narrow `fence`, `atomicrmw`, `cmpxchg`, and side-effecting inline asm forms are
classified through the conservative atomics/inline-asm barrier boundary in
`docs/ir_atomics_inline_asm.md`.

## Fixture Coverage

```text
local-only conservative opt fixture:
  globaldce_tls_root
  globaldce_tls_concurrency_root
  globaldce_tls_model_root
  gvn_tls_store_clobber_reject

opt-equivalent fixture:
  dce_tls_store_preserve
  early_cse_tls_store_clobber_reject
  dse_tls_load_barrier

unit tests:
  thread-local global preservation through GlobalDCE
  known TLS model preservation and unknown TLS model rejection
  fence, atomicrmw, cmpxchg, and inline asm barrier preservation
  atomic syncscope preservation through the atomic parser boundary
  volatile/atomic memory-effect barriers
```

## Backend Boundary

TLS model selection, TLS relocations, thread pointer access sequences, and
platform-specific lowering are backend/linker work. They are not modeled by the
optimizer beyond preserving thread-local globals and refusing to optimize across
atomic/fence-like barriers.

The optimizer treatment in this project is therefore limited to symbol/root
preservation and conservative memory legality. Native TLS lowering remains
deferred until backend handoff fixtures require a concrete relocation and access
sequence.
