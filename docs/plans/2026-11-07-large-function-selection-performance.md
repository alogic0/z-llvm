# Large-function selection performance

Status: active; authorized by the user's instruction to implement the next
compiler-performance milestone. Successor to the completed
[unchanged Zig input program](2026-11-06-unchanged-zig-input-program.md).

## Intended result

Reduce compiler work on the retained, unchanged Fibonacci and language-reference
migration programs while preserving object bytes, selection ownership and all
execution observations. The accepted Safe migration profile spends 24.11 of
28.15 seconds in selection and optional legalization. Two block-sort
specializations and the DWARF expression interpreter account for 9.78 seconds.
These individual samples identify investigation targets, not a speedup claim.

The initial candidates are repeated identifier comparisons, temporary-name
collision scans and other shared work inside successful rewrites and selection.
Establish the cost with repeatable measurements and bounded diagnostic variants
before accepting a change. Use no function-name exceptions or workload-specific
compiler behavior. Keep ordered rewrites, normalization, retries, rollback,
register transfers and independent ownership replay intact.

## Implementation order

1. Authenticate the accepted ReleaseFast compiler and retained IR/object/owner
   inputs. Record the source state and original probes. Run warm-ups and repeated
   Safe baselines for both programs without concurrent project builds or tests.
2. Isolate the shared costs in the expensive functions. Use existing profiles,
   focused inspection and controlled diagnostic variants; add instrumentation
   only when required to distinguish competing explanations. Record diagnostic
   changes separately from the final implementation.
3. Optimize the demonstrated shared cost. Preserve exact identifier semantics,
   deterministic temporary naming, candidate isolation and failure behavior.
   Add regressions for affected boundaries, including spelling aliases,
   collisions and malformed inputs where applicable. Reuse existing semantic
   and source-authority checks.
4. Compare accepted and final ReleaseFast compilers on identical retained inputs
   in alternating repeated runs. Measure wall/CPU time and peak RSS, retain
   phase/function/legalizer profiles, and compare object and ownership bytes.
   Require a measured improvement on the primary workloads and no unexplained
   regression in the other release modes. Report distributions and measurement
   limits; keep compiler throughput separate from generated-code speed.
5. Run affected units, Debug/Safe unit suites, structural/policy, captured-object,
   ABI, compilation-route, readiness and whole-program checks. Run all 17
   integration gates on a frozen source revision. Review retained observations,
   compiler-core equivalence and native populations before promoting acceptance.

## Acceptance and scope

The two Safe captures are the primary benchmarks. Fast and Small captures are
secondary checks; all three modes of the input-driven Zig and C corpora remain
required. Preserve all seven original executable canaries, the five fixed Zig
programs, the 100-row/nine-function compiler-core cohort, 45 native populations,
and the compiler-rt bypass ratchet of 130. Cohort expansion is subsequent work,
not a performance claim for this slice.

Use the existing Zig 0.17 tooling and pinned frontend revision
`1c08b09d1c847f4f02c8216e3b62df323861a437`. Retain accepted evidence and compilers,
current AIR, diagnostic worktrees and the thirteen original scratch probes.
Create no archives. Use task-owned evidence under
`local-state/validations/large-function-performance-20261107/`.
Admission remains 32,949,672,960 bytes free, with a 24,359,738,368-byte execution
reserve. Initial available space is about 53.25 GB.

## Progress

The initial baselines and controlled diagnostic are complete. A seven-line
shared identifier-comparison change reduces the Safe diagnostic from 27.15 to
17.50 seconds for Fibonacci and from 29.68 to 18.78 seconds for migration.
Objects, ownership and every non-timing profile field match. Most of the observed
reduction is in legalization and reachability; the temporary-name scans remain
unchanged. Thirteen focused tests pass, including spelling classes, malformed
inputs and quoted-name collisions. All 44 timed comparisons and twelve profiles
preserve object/owner bytes and non-timing fields. Safe median compiler time
falls 36.4% for Fibonacci and 35.9% for migration; migration also improves in
Fast and Small, while the short Fibonacci cases remain unresolved at 10 ms
resolution. Debug/Safe units (1,915 each), policy (30 each), structural checks,
captured objects, ABI, compilation routes and readiness pass. Both whole programs
pass all three modes with independent ownership replay; migration retains all
87 input/mode pairs and 603 observation controls. The frozen focused snapshot
and thirteen original probes verify. Full acceptance on the committed source
is next. See the
[implementation evidence](../evidence/large_function_selection_performance.md).
