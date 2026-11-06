# Compiler selection performance

Implementation and measurement are in progress. Full checkpoint acceptance is
pending. The [plan](../plans/2026-11-06-compiler-selection-performance.md) follows
the accepted input-driven execution milestone without changing its populations.
Raw artifacts are in `local-state/validations/selection-performance-20261106`.

## Measurement contract

`--profile=PATH` emits `compilation-profile-v2`. Global phases are exclusive;
function phase rows describe the selection interval for that function. Legalizer
times nest inside `legalize`, and `original_form_ns` nests inside `select`.
Original-form retry time includes successful selections and must not be treated
as wholly wasted work. Legalizer elapsed times split into rewritten, unchanged
and error outcomes. Function rows retain owned names, input sizes, counters and
legalizer allocation totals, including failed selections.

Allocation counters observe each legalizer's allocator interface above the
selector arena. `allocated_bytes + grown_bytes` counts successful logical
requests, including repeated candidate work; it is neither peak live memory nor
resident memory. Profiler storage is excluded. Discarded-candidate bytes are a
subset of those allocations, not additional bytes. Disabled profiling does not
read clocks or install allocator wrappers. Route tests compare objects and
ownership with profiling disabled, enabled and independently replayed, and check
failed-module accounting without publishing an object or ownership sidecar.

The primary input is the retained Safe Fibonacci IR, SHA-256
`972e8117c6180e2aade331f1595a7d1e3547937babc91f5e3db101a0fa9f3e46`.
It selects 1,568 definitions. The pre-optimization instrumented build produced
the accepted object and ownership bytes and the same counters: 139,415 legalizer
attempts, 7,233 rewrites, 2,869 original-form retries and 1,034 successful retries.
It recorded 7,759,243,275 logical allocation bytes, of which 6,488,386,095 were
requested by unchanged attempts. Its single timing sample is diagnostic, not
the repeated comparison used for acceptance.

## Implementation

Nine instruction legalizers now defer candidate copies until the first actual
rewrite: aligned stack, pair memory, comparisons, word arithmetic, integer
forms, pair arithmetic, integer intrinsics, scalar forms and boolean values.
The shared candidate builder copies earlier blocks and the current instruction
prefix at that point, then accumulates the remaining output. Successful
candidates retain independent block and instruction arrays. Eligibility checks,
SSA name generation, mandatory normalization, stage order, search restarts,
original-form retries and rollback are unchanged. There is no memoized rejection
or workload-specific dispatch.

Regressions exercise all nine stages with removed instructions, rewrites at the
first instruction and after untouched blocks, repeated rewrites, retained
prefixes/suffixes and terminators, allocation failure, verifier checks and source
isolation. Existing executable width, alias, PHI, call and pressure tests remain
required.

The optimized diagnostic run retains identical objects, ownership and all
selection counters. Logical allocations fall to 2,273,076,323 bytes; unchanged
attempts account for 1,002,034,287 bytes, with zero in the nine changed stages.
These are allocation-work counts, not an estimate of elapsed-time improvement.
Both Debug and ReleaseSafe pass 1,910 unit tests, 28 policy tests and 19
structural checks. The route contract and all 138 C input/mode pairs pass.

## Reproduction and boundaries

`measure.sh` in the raw artifact directory records two untimed warm-ups, five
alternating baseline/final/profiled Fibonacci runs and 25 alternating baseline
and final parser runs. Every sample is a fresh compiler process; every object
and ownership manifest is compared byte for byte. GNU time records wall/CPU
time and maximum RSS. No other project validation runs during timed samples.
The small parser measurements have 10 ms wall-time resolution.

This work measures compiler throughput. It does not establish generated-code
optimization quality, self-hosting, or broader frontend coverage. The C parser's
552 negative controls mutate observations, not compiler implementations. A
larger unchanged Zig program using runtime input and allocation remains the
next separate coverage milestone.
