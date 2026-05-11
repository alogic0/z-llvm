# Cycle 28: Upstream Integration Readiness

## Goal

Define what evidence would make this project useful to Zig upstream: clear
boundaries, reproducible fixtures, correctness proof points, and handoff notes
that align with Zig's native LLVM-removal plan.

## Source Anchors

- Zig upstream LLVM-removal docs and issues already collected in
  `docs/roadmap/zig_upstream_llvm_removal_path.md`
- Local roadmap and inventory docs
- Accepted corpus and opt comparison fixtures

## Plan

- [ ] Summarize completed local capabilities by subsystem.
- [ ] Map every capability to Zig's native backend, AIR/Sema, or LLVM-compat
      boundary.
- [ ] Identify which work should remain external experiment versus upstreamable
      design input.
- [ ] Add reproducibility instructions for compiler version, fixture generation,
      opt comparison, and corpus runs.
- [ ] Create a gap report suitable for Zig contributors to review.
- [ ] Decide the next roadmap wave based on upstream alignment, not local
      momentum alone.

## Exit Criteria

- [ ] Upstream-facing docs can explain the project without overclaiming.
- [ ] Reproduction commands are current and tested.
- [ ] The next wave is grounded in Zig's actual removal path.

