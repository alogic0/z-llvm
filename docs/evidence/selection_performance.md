# Compiler selection performance

Accepted at `fbb249a7d9a10b118696af3ef1b378a11a3e45aa`, tree
`10bff8f7b829b0d234e656cfcca0abdae23da278`: all 17 integration gates pass.
The [acceptance record](selection_performance_acceptance_20261106.json) retains
the measurements, source identity and artifact hashes. The completed
[plan](../plans/2026-11-06-compiler-selection-performance.md) follows the
input-driven execution milestone without changing its populations.
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

## Repeated measurements

Both compilers are built with ReleaseFast. The baseline is the preceding
accepted compiler, SHA-256
`35ac57259e973d74494162de81935a4e9de3fb56cd393af71eb610099fc3ee66`;
the final compiler is
`575ce31bd3ca38a39ccdeda43fb534f5e88032b0ad9bfe9f9dc7e3f2eb0e6290`.
The primary route emits an object and ownership from the same selection run on
the retained Safe Fibonacci IR. Profiling is disabled for the baseline/final
speed comparison. The secondary route uses the retained raw parser IR with
`--passes=memory-foundation,zig-release-safe-accepted`.

| Workload/configuration | Runs | Median wall time | Range | Median peak RSS |
| --- | ---: | ---: | ---: | ---: |
| Fibonacci baseline | 5 | 29.78 s | 29.64–30.47 s | 598,260 KiB |
| Fibonacci final | 5 | 27.28 s | 27.13–27.55 s | 239,124 KiB |
| Fibonacci final, profile enabled | 5 | 27.21 s | 27.12–27.79 s | 238,896 KiB |
| Parser baseline | 25 | 0.08 s | 0.08–0.09 s | 26,852 KiB |
| Parser final | 25 | 0.07 s | 0.07–0.08 s | 16,816 KiB |

Median Fibonacci elapsed time falls 8.4%, and peak RSS falls 60.0%. Median CPU
time falls from 29.77 s to 27.27 s. Every timed object and ownership manifest
matches byte for byte. All five final profiles have the same per-function and
per-stage counters as the instrumentation-only build. Logical legalizer bytes
fall 70.7%, and bytes requested by unchanged attempts fall 84.6%.

The profiled and unprofiled timing ranges overlap. Their slightly reversed
medians do not establish a speedup from profiling; overhead is unresolved at
this sample size and host variability. The small parser samples show no
regression, but 10 ms timing resolution limits precision. These are local
measurements, not a cross-machine performance claim.

The first final profile attributes 10.22 s to optional legalization and 13.86 s
to selection. Ordered scans and original-form retries remain substantial work;
this change reduces copying without skipping eligibility checks. The two block
sort instantiations and DWARF functions remain prominent in the function
profiles. Their names and stage timings are retained to guide subsequent work,
without treating unsuccessful-attempt counts alone as a cost estimate.

## Acceptance

The frozen 2,959-file source snapshot and compiler hashes were verified after
the full run. All 17 gates pass, with 1,471 canonical records. The compiler-core
population remains 100 lowered/emitted/linked and nine executed functions per
mode; all 36 core records match prior fresh execution. All 45 native populations
pass 1,767,660 local observations against 883,830 reference observations.

All five unchanged Zig programs match LLVM in Fast, Safe and Small, including
all six Fibonacci assertions and 1,568 emitted Safe definitions. The parser
again matches 138 input/mode pairs, with 552 rejected observation mutations.
All 27 execution-breadth controls pass. Debug and ReleaseSafe each pass 1,910
unit tests, 28 policy tests and 19 structural checks. Readiness, 60 ABI
comparisons, profile/ownership neutrality and failed-module route checks pass.

The full run takes 3,146.422 s. Minimum free space is 30,689,878,016 bytes, above
the unchanged 24,359,738,368-byte execution reserve. The 32,949,672,960-byte start
threshold remains unchanged. All thirteen original scratch files, prior accepted
evidence, baseline compilers, diagnostic worktrees and authenticated AIR caches
are preserved. No archives were created.

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
