# Cycle 28: Upstream Integration Readiness

## Goal

Define what evidence would make this project useful to Zig upstream: clear
boundaries, reproducible fixtures, correctness proof points, and handoff notes
that align with Zig's native LLVM-removal plan.

## Source Anchors

- Zig upstream LLVM-removal docs and issues already collected in
  `docs/LLVM_replace.md`
- Local roadmap and inventory docs
- Accepted corpus and opt comparison fixtures

## Plan

- [x] Summarize completed local capabilities by subsystem.
- [x] Map every capability to Zig's native backend, AIR/Sema, or LLVM-compat
      boundary.
- [x] Identify which work should remain external experiment versus upstreamable
      design input.
- [x] Add reproducibility instructions for compiler version, fixture generation,
      opt comparison, and corpus runs.
- [x] Create a gap report suitable for Zig contributors to review.
- [x] Decide the next roadmap wave based on upstream alignment, not local
      momentum alone.

## Exit Criteria

- [x] Upstream-facing docs can explain the project without overclaiming.
- [x] Reproduction commands are current and tested.
- [x] The next wave is grounded in Zig's actual removal path.

## Completion Notes

- Added `docs/upstream_integration_readiness.md` as the contributor-facing
  capability and gap report.
- Added `scripts/run_readiness_checks.sh` to reproduce the current claims.
- The next roadmap wave is explicitly tied to Zig-emitted corpus blockers and
  upstream LLVM-removal needs rather than generic LLVM feature growth.
