# Bounded allocation-planning throughput improvement

Date: 2026-11-09. Follows the
[validation performance delivery](validation_performance.md), committed at
`c19bdc66`. The [record](compiler_throughput_20261109.json) binds source states,
build receipts, inputs, commands, measurements and validation results.

## Changes and measured work

Preservation planning previously scanned every value interval at every call,
fixed-scalar operation and store. One captured selector-private form of
`codegen.loongarch.Assemble.parseInstruction` has 304,022 intervals, 2,026
preservation barriers, 2,026 call-preparation sites, 35,667 fixed-scalar sites
and five stores: **12,076,969,928 interval/site pairs per plan**. Three private
forms were captured during a bounded 90-second diagnostic.

Each interval now contributes its slot width to a contiguous range of ordered
sites. Binary bounds identify that range, and a difference sweep obtains the
same maximum simultaneous reserve. The preservation stage costs
`O(intervals × log(sites + 1) + sites)` per site class, with temporary storage
proportional to the site count. Preservation membership is inserted once per
interval. Register assignment and the liveness interval construction are
unchanged.

The implementation preserves strict crossing at ordinary clobbers, inclusive
final-use ends during call argument placement, two-slot wide values, the store
exclusion for entry parameters/non-scalar values, and fixed-scalar reserve
without adding preservation membership. Frame limits and selection admission
are unchanged.

The same diagnostic flushed at least **389,857,280 dependency queries**, all
against empty dependency domains. Ordinary interval liveness now skips graph
validation/traversal when the domain is empty. Populated-domain graph, binding,
plan and live-context checks remain unchanged; there is no cached query result.
Tests query an empty domain, add a malformed graph and require the original
failure at the next query. A proposed fused populated-domain API was deferred
because this workload supplied no measured need for it.

## Completed component comparisons

Raw evidence is under
`local-state/validations/compiler-throughput-20261109/`. Baseline and candidate
use the same Zig, target, CPU, flags and probe sources. Warmups precede three
alternating repetitions with hardware/compiler profiling disabled. CPU times,
peak RSS, host load and pressure snapshots are retained per process.

| Completed replay | Baseline median | Candidate median | Comparison |
| --- | --- | --- | --- |
| Private plan 0, allocation stage | 10.975 s | 0.452 s | Exact plan bytes in all repetitions |
| Private plan 2, allocation stage | 10.989 s | 0.460 s | Exact plan bytes in all repetitions |
| Plan 0, whole probe process | 12.239 s | 1.767 s | Includes parse, canonical output and publication |
| Plan 2, whole probe process | 12.289 s | 1.767 s | Includes parse, canonical output and publication |
| 250 million empty-domain queries | 1.747 s | 1.774 s | Identical results; no speedup established |

The first plan compares 314,042 value records, including pressure-exempt values,
with 301,264 ordinary spill slots and 18 preservation slots. Canonical output
retains each assignment, interval end, forward-value fact and preservation bit,
plus aggregate plan counts. Both captured forms match byte-for-byte. Maximum
RSS across plan replays is 479,564–480,432 KiB, with similar baseline/candidate
memory use. These results quantify the completed allocation component.

The captures are selector-private IR. Their rewritten call signatures can fail
standalone module verification (`CallSignatureMismatch`), so the final probe
explicitly selects `--private-ir`, matching the production planner entry
contract. The unchanged original extraction remains separately LLVM-verified.
Private plan comparisons do not establish a complete LLVM module or object.
The rejected pre-normalization and standalone-verification probes are retained.

## Current compiler sampling

The final ReleaseFast compiler retains debug symbols and frame pointers.
Host preflight succeeds for `cycles:u,instructions:u`. A fresh 90-second
`cycles:u` recording at 199 Hz with frame-pointer user callchains records
**17,956 samples**, zero reported losses and decoded compiler callers. The
process times out with status 124: wall 90.23 s, user 72.78 s, system 17.41 s,
peak RSS 3,250,176 KiB. No completed profile, ownership output or object is
accepted from the interruption.

Allocation planning accounts for 0.12% of this recording's self samples.
Dependency graph query/validation symbols are absent from its self-sample
inventory. The largest entries are hashing (23.86%), ordinary interval liveness
(19.67%) and byte comparison (13.05%). The last flushed event is selection retry
sequence 485 at 6.421 s; selection remains active at interruption. The preceding
recording's corresponding event was at 27.293 s. Sampling covers different
progress within the same time limit, so these percentages and event times do
not establish a whole-function speedup.

The next bounded question is repeated ordinary interval lookups and binding
scans. Any future reuse must respect current position, boundary, plan and domain
mutations and retain every ownership/frame guard. This delivery does not resume
the complete compiler-selection goal.

## Validation and retention

Debug and ReleaseSafe each pass **2,046 compiler units**, **24 structural checks**
and **two profiling/interruption tests**. New checks compare preservation against
independent site scans over 200 generated cases in four policies, including
duplicate positions, endpoints, wide values and maximum positions. Existing
allocation-failure tests cover cleanup and unchanged source ownership. Empty
domain tests retain both liveness boundaries and require revalidation after a
graph is added. The unchanged 36 policy tests per mode are reused from
`c19bdc66`: validation tools, process libraries, policies and their fixtures did
not change.

The public compilation contract and focused `large_frame` and `bounded_storage`
canaries pass; both populations execute direct/release routes in all three input
modes. Complete Debug and ReleaseFast native suites each retain **76 populations**,
**2,200,836 local observations** and **1,100,418 references**, plus the C
fixture's paired executions and call/heap checks. Within each compiler build
mode, all **2,837 command outcomes** and **1,161 successful compiler artifacts**
match the preceding baseline exactly: 237 optimized IR outputs, 465 objects and
459 ownership manifests. No byte normalization or artifact exception is needed.

All **17 serial integration gates** pass in 2,860.21 s (47.67 minutes), including
the three required-hit 100-row modes. The execution-control population retains
21 function/mode pairs, 22,788 observations and all 54 fault controls. All unchanged
Zig programs, the 87-pair file corpus with 603 controls, and the 138-pair stdin
corpus with 552 controls pass. The complete source snapshot verifies after the
full run. Final free space is 38,738,030,592 bytes, with a minimum observed
36,839,227,392 bytes, above the unchanged 11,410,065,408-byte reserve. Admission
remains 20,000,000,000 bytes.

The Tier-3 trigger is the shared selector/allocation/frame and milestone policy.
The previous full result cannot accept changed compiler dependencies. The new
run uses the authenticated existing AIR generation, with a new owned scratch
root and every backend row/observation rerun. AIR production and cache policy
are unchanged. Complete Debug native execution runs independently alongside
Tier 3; these concurrent wall times are not isolated performance measurements.
The source snapshot remains frozen throughout acceptance.

The diagnostic instrumentation and probe sources are retained in an isolated
checkout and patches; they are absent from production compiler builds. Original
inputs, accepted evidence, authenticated AIR, bundles and thirteen scratch probes
are preserved. No archives or cleanup are introduced. Accepted counts remain
**8,664/8,928** compiler and **285/455** runtime definitions, with the all-8,928
goal paused.
