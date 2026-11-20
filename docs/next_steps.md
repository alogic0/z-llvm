# Next steps

**Proposed November 20, 2026.** Can the self-built x86-64 helper emit
`pointer_constants.ll` within the normal 120-second deadline by skipping a
search for a stack allocation that the function does not contain?

- **Baseline.** G2 took 209.2 seconds, G1 took 19.1 seconds and an LLVM-built
  copy of the same helper source took 1.42 seconds. All three emitted the
  same object. [Profile and input](plans/2026-11-20-x86_64-pointer-constants-compile-time.md#what-the-profile-shows)
- **Experiment.** The Implementer will record during frame planning whether a
  function could contain the two-float allocation. Skip the lookup only when
  its absence is established. Compare the whole module and its 16 body/probe
  pairs. [Experiment and controls](plans/2026-11-20-x86_64-pointer-constants-compile-time.md#experiment-and-decision)
- **Decision.** The Reviewer checks that G2 repeatedly finishes direct emission
  in under 120 seconds. Direct and ReleaseFast emission must each preserve
  the baseline object and selection-owner manifest, and all 10,240 native
  observations must match the reference. If those checks pass, measure cold
  ReleaseFast builds of `z_llvm` and then Zig. Otherwise record the first
  correctness difference or remaining hotspot. [Full plan](plans/2026-11-20-x86_64-pointer-constants-compile-time.md)

Completed work includes the [LLVM-free toolchain](plans/2026-11-19-x86_64-releasefast-llvm-dependency-removal.md),
[loop register allocation](plans/2026-11-18-loop-register-residency.md) and
[bounded memory fill](plans/2026-11-18-loop-and-bounded-memset.md).
[Earlier handoffs](roadmap/historical/handoffs-through-2026-11-19.md)
