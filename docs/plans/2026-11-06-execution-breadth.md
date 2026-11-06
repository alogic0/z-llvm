# Execution breadth after Fibonacci

Status: implemented and [accepted](../evidence/execution_breadth_acceptance_20261106.json)
at `f68ab145`, with all 17 gates passing. This follows the
[Fibonacci completion plan](2026-11-05-fibonacci-completion.md), step 7.
Keep the fixed 100-row emission population, executed compiler-core functions,
unchanged programs and native observations separate.

## Implemented order

1. Corrected architecture and pipeline documentation: ordinary object emission
   honors explicit pass requests through shared compilation preparation.
2. Reproduced the retained tagged-union Fast frontier: 1,484 selected functions,
   1,469 emitted, 15 failures. Retained the original diagnostics and compiler hash.
3. Extended the shared value-use planner to preserve parallel transfers across
   calls and scalar register PHIs. Covered cycles, fan-out, aliases, dirty upper
   bits, accumulator sources, pressure, flags, storage failures and rollback.
4. Repaired demonstrated immediate-left multiplication, overlap-safe `memmove`
   planning and symbolic constant-base GEPs through existing shared authorities.
   The retained input now emits all 1,484 functions.
5. Added permanent Fast/Safe/Small execution of unchanged `optionals`,
   `taking_pointer_of_global_tagged_union`, `array_in_anon_struct` and `while_loops`,
   alongside the existing six-assertion Fibonacci regression.
6. Expanded the authenticated compiler-core execution cohort from five to nine
   members without changing the 100-row prefix. Added index arithmetic, guarded
   atomic state transitions and exhaustive packed-byte predicates, together with
   wrong-result, wrong-symbol and memory-clobber controls. The new mutex harness
   exposed and drove a shared atomic width/dataflow/ordering repair.
7. Separated compiler throughput measurements from generated-code performance.
   Compare Debug/ReleaseFast compiler builds on the same Safe Fibonacci IR, timing
   object emission and ownership replay separately and checking identical outputs.

## Acceptance

Freeze source and tool identities. Require Debug and ReleaseSafe unit suites,
structural checks, ABI comparisons, route checks, policy tests, readiness and all
17 integration gates. Require every mode of all five unchanged programs, all nine
compiler-core execution members and all 45 native populations to pass. The cohort
schema, output parser and counters advance together; emission and linkage do not
count as execution.

The expanded source authority changed the AIR cache key. Fresh generation and
cached execution replay pass with 36 matching canonical records. The old
authenticated generation and initial failed runs remain as diagnostic evidence.
The [implementation evidence](../evidence/execution_breadth.md) records the final
program, native and function counts and the compiler-throughput comparison.

Retain compact reports and provenance, the original 13 scratch probes and the
diagnostic worktrees. Create no archives. Keep the 32,949,672,960-byte start
threshold and 24,359,738,368-byte execution reserve.

## Following work

Optional legalizers still recurse and ordinary CLI selection retains its
structural path. Consolidate these around checked normalized inputs, then make
fixed-register effects more explicit in machine representation. Pair/vector PHIs
and spill destinations still use their existing transfer paths. Extend execution
coverage to larger state and memory interactions before broadening readiness claims.

The host blocks `perf` sampling, so compiler hotspot attribution remains open.
The recorded compiler throughput comparison does not establish generated-code
optimization quality; continue measuring the separate fixed workload matrix.
