# Compiler selection performance

Status: in progress. Successor to the completed
[input-driven execution plan](2026-11-06-input-driven-execution.md).

## Scope

Measure and reduce compiler work in optional legalization and selection while
preserving generated objects, selection ownership and execution behavior.
The retained Safe Fibonacci IR is the primary workload: 1,568 selected
definitions, with 28.66 of 31.75 measured seconds in these two phases. Attempt
counts alone do not establish which checks are expensive.

The larger unchanged Zig program with runtime input and allocation remains a
separate coverage milestone. The existing C corpus remains required; its 552
negative controls mutate observations, not compiler implementations.

## Implementation order

1. Extend opt-in profiles with per-function timing/counters, per-legalizer
   elapsed time split by outcome, allocation requests/bytes, and original-form
   retry time. Use stable stage identifiers and explicit per-compilation state.
   State allocation measurement boundaries and distinguish totals from nested
   time. Test accounting, failures, names and object/ownership neutrality.
2. Build an instrumented compiler before changing lowering algorithms. Profile
   the unchanged retained IR and rank actual costs, including failed attempts
   and discarded candidates. Retain that compiler and its measurements.
3. Optimize demonstrated costs, starting with unnecessary scans or candidate
   allocation. Preserve mandatory normalization, ordered legalizer search,
   rewrite invalidation, original-form retries, rollback, labels and register
   transfer contracts. Introduce no function-name or workload special cases.
   Add focused regressions that exercise the changed eligibility boundaries.
4. Compare the accepted baseline and final ReleaseFast compilers on identical
   inputs in alternating repeated runs. Measure profiling overhead separately;
   compare wall time, allocation work and peak RSS without conflating them.
   Use the C input program as a secondary workload and keep all object and
   ownership bytes identical. Report distributions and limits, not an assumed
   percentage speedup.
5. Run Debug/ReleaseSafe units, policy/structural/ABI/route checks, readiness,
   the input corpus and all 17 integration gates against a frozen revision.
   Verify current core records against accepted execution, preserve existing
   population definitions, then publish evidence and complete this plan.

## Acceptance and storage

Accept a measured reduction on the retained workload with unchanged object and
ownership bytes, green execution checks, and no unexplained secondary-workload
regression. Keep profiler-disabled execution free of timing and allocation
instrumentation. The profile schema must describe its new measurements and
remain checked by permanent compilation-route tests.

Retain prior accepted evidence, baseline compilers, authenticated AIR exports,
diagnostic worktrees and all thirteen original scratch files. Create no archives.
Keep the 32,949,672,960-byte start threshold and 24,359,738,368-byte reserve;
retire only idle, reproducible build products with a recorded cleanup if needed.
