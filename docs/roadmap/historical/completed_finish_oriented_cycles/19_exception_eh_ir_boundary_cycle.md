# Cycle 19: Exception And EH IR Boundary

## Goal

Classify LLVM exception-handling IR emitted or reachable from Zig-related paths,
then preserve or reject it safely before any optimizer handling is attempted.

## Source Anchors

- Future source-backed panic/error/EH-adjacent captures
- LLVM IR: `invoke`, `landingpad`, `catchswitch`, `cleanupret`, personality
      functions
- Local parser/verifier/CFG logic
- Docs: unsupported IR and backend handoff

## Plan

- [x] Capture or reduce a source-backed row that exposes EH-like LLVM IR, or
      document that current Zig rows do not emit it.
- [x] Add parser rejection tests for unsupported EH terminators and pads.
- [x] If a narrow form must be accepted, represent CFG edges and personality
      metadata explicitly.
- [x] Prevent CFG simplification and ADCE from mishandling EH edges.
- [x] Keep unwind table emission and language personality lowering out of scope.
- [x] Update unsupported docs with EH boundaries.

## Exit Criteria

- [x] EH IR has source-backed classification.
- [x] Unsupported EH forms fail closed.
- [x] Accepted CFG logic does not drop exceptional edges.

## Completed Slice

- Classified the current accepted Zig error-like rows as ordinary scalar and
  control-flow IR, not LLVM EH pad IR.
- Added fail-closed parser coverage for `catchswitch`, `cleanupret`,
  `catchpad`, `cleanuppad`, and function `personality` attributes on top of
  the existing `invoke`, `landingpad`, and `resume` checks.
- Kept EH CFG, unwind edges, personality lowering, and unwind table emission
  out of scope so SimplifyCFG and ADCE cannot silently drop exceptional edges.
