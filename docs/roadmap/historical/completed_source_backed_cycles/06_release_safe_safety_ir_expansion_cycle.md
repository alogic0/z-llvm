# Cycle 6: ReleaseSafe Safety IR Expansion

## Goal

Expand ReleaseSafe coverage around Zig safety checks, trap paths, branch weights,
and runtime-call boundaries while preserving correctness over optimization
aggressiveness.

## Source Anchors

- Manifest rows: `release_safe_safety_reduced`, future ReleaseSafe captures
- Zig source groups: scalar arithmetic, bounds-like branches, error paths
- LLVM IR: trap branches, profile metadata, calls, selects, phis
- Local code: parser, verifier, SimplifyCFG, SCCP, ADCE

## Plan

- [x] Capture or reduce a small set of ReleaseSafe source-backed safety-check
      examples.
- [x] Preserve branch-weight and safety metadata textually where the local
      optimizer does not interpret it.
- [x] Add verifier tests for trap/control-flow shapes that must not be silently
      dropped.
- [x] Add pass fixtures for conservative handling of safety branches and runtime
      calls.
- [x] Keep panic/runtime lowering and full debug info out of scope unless a
      reduced fixture requires them.
- [x] Update corpus and unsupported docs with accepted ReleaseSafe safety IR.

## Exit Criteria

- [x] ReleaseSafe safety rows have honest parse/verify/optimizer classifications.
- [x] Safety checks are not optimized away unless matched by an explicit LLVM
      comparison fixture.
- [x] Runtime-call and trap-path gaps are documented as future work.

## Completed Slice

Cycle 6 adds `release_safe_call_boundary_reduced`, a reduced ReleaseSafe safety
fixture that keeps a declared opaque panic/runtime call on the trap path and
preserves branch-weight metadata. ADCE and SimplifyCFG fixtures compare this
dynamic safety branch with `opt-22`; sanitizer, `llvm.trap`, panic lowering, and
full debug metadata remain documented future work.
