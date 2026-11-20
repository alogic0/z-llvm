# Reduce x86-64 compile time for pointer constants

**Proposed, November 20, 2026.** Use the published LLVM-free toolchain as
the baseline. The Implementer owns the selector change and measurements.
The Reviewer independently checks correctness, timings and the decision to
proceed to a cold self-build. [Published toolchain and source revisions](../evidence/llvm_free_self_rebuild_20261119.md#accepted-g2-package)

## What the profile shows

On the same 32-definition module, direct object emission took 209.2 seconds
with the self-built helper (G2), 19.1 seconds with the first-generation
helper (G1) and 1.42 seconds with an LLVM-built copy of the same helper
source. All three produced the same 240,912-byte object. In the G2
profile, 1,885 of 2,117 samples were in byte equality. All 400 verified
call chains went through `pointerViewDepth` and `findInstruction`. This
lookup searches for an originating two-float stack allocation. The input
contains zero stack allocations. [Input](../../test/real_programs/pointer_constants.ll) · [Timings, profile and 16 original body/probe pairs](../evidence/llvm_free_self_rebuild_20261119.md#pointer-constants-emission-time)

## Experiment and decision

1. **Skip the search when it cannot succeed.** During the existing frame
   planning pass, record per function whether a qualifying `{float,float}`
   allocation is possible. Reuse the selector's type and address-space
   rules, including named types. When lowering a byte GEP (pointer offset),
   skip the definition lookup only when absence is established. Use the
   existing pointer traversal whenever eligibility is unknown or a
   qualifying allocation exists. [Frame planner](../../src/codegen/x86_64/generic_cfg/composed_selector_frame.zig) · [Byte GEP lowering](../../src/codegen/x86_64/generic_cfg/composed_selector_memory.zig) · [Pointer traversal](../../src/codegen/x86_64/generic_cfg/aggregate_object.zig)
2. **Prove the emitted code is preserved.** Compare baseline and candidate
   whole-object bytes and selection-owner manifests separately for direct
   and ReleaseFast emission. Link each object to the same C driver and
   require all 10,240 observations to match the reference. Exercise a real
   pair allocation, a named pair type, a byte offset, and a PHI joining
   equal offsets. Check rejection for mismatched offsets and out-of-bounds
   accesses. Run the selector Tier 2 checks. [Validation tiers](../validation_tiers.md#change-impact-routing)
3. **Measure the actual helper.** Time the whole module and each of the
   original 16 body/probe pairs, including the two 64-lane cases. Compare
   baseline and candidate built by the same route, using identical inputs,
   flags and host conditions. Alternate uninstrumented runs, record binary
   hashes and report individual times and medians. Keep G1 and the
   LLVM-built helper as controls. The first target is repeatable G2
   direct emission under the normal 120-second deadline. Report the
   remaining gap to G1's 19.1 seconds.
4. **Measure whole-build impact if the focused experiment passes.** With
   empty caches for each run, time baseline and candidate on an ordinary
   ReleaseFast build of `z_llvm`, then of Zig, for baseline
   `x86_64-linux-gnu`. Pin the workload sources and compiler flags, and
   verify which helper the child compiler actually used. Report compiler
   wall time and native object-emission time separately where available.
   Apply the milestone Tier 3 checks before proposing a successor release.
   If correctness differs or direct emission still exceeds the deadline,
   record the first difference or remaining hotspot before another self-build.

## Evidence and storage

Use `local-state/validations/pointer-constants-compile-time-20261120/batch-01/`
with a fresh run directory for each build, comparison and review. Declare
the producers, consumers and release conditions in each run's `retention.md`.
Use `tools/run-validation` and its `--command` mode for scripts. Keep
private caches, extracted SDKs, candidate helpers, objects and driver
executables in managed temporary storage. Retain shared products through
their comparisons and independent review. Keep commands, source and binary
identities, oracle results, timings and the review decision as evidence.
The published package remains the maintained baseline. Release each
pipeline after its last consumer, collect at stage boundaries, and record
the final receipt and disposition of any remaining temporary roots.
[Development storage contract](../development_storage.md)
