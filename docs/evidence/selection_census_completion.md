# Compiler selection census completion

Status: accepted at `5ad6c51c`. Both diagnostic censuses complete and all 17
cumulative gates pass. Compiler-core counts remain unchanged; no whole-compiler
object, startup or self-hosting success is claimed.

Plan: [complete compiler selection census](../plans/2026-11-07-selection-census-completion.md).
Raw evidence: `local-state/validations/selection-census-20261107/`.
Previous accepted implementation: `9d3f24b3`; working base: `5d07d94e`.
Machine-readable [acceptance record](selection_census_completion_acceptance_20261107.json).
Implementation commits: `c47f00b6` (profiling), `62943daa` (selection performance),
`5ad6c51c` (call and memory attributes).

## Interruption-safe profiling

`--profile-events=PATH` independently enables flushed JSONL progress records.
The existing `compilation-profile-v2` final summary remains unchanged. Events
carry a sequence number, elapsed time, active function and phase, and balanced
function, normalization activity, legalizer and retry records. Each record uses
a streaming writer and flushes before returning. A killed process can leave a
partial final record; it cannot claim completion of its active function.

The whole-compiler runner accepts `--profile-events`, retains the stream's path,
size and digest, and reads only its bounded tail after termination. A progress
tail explicitly does not verify the whole stream or complete a selection census.
The final replay additionally audits every event, sequence, function identity
and begin/end pair. Compilation failure and completed diagnostic traversal are
separate facts: a complete rejected census ends with `succeeded: false`.

Permanent process tests compare profiled/unprofiled object bytes, reject output
conflicts including dotted paths and symbolic links, and terminate an owned
child during an active legalizer. Unit tests cover readable prefixes and write
failures. A 100 ms whole-compiler interruption retains the input-phase event and
correctly reports interruption with absent census totals. It grants no coverage.

## Measured large-function repair

The focused diagnostic selects exactly
`codegen.loongarch.Assemble.parseInstruction`, retaining all original module
definitions, declarations, globals, named types and layout. It parses and verifies
the full input before selecting the function. No extracted substitute program or
function skip is used. The function has 20,976 blocks and 133,719 instructions.

| ReleaseFast diagnostic | Wall seconds | Result |
| --- | ---: | --- |
| Original name scans, activity trace | 180 deadline | Interrupted in narrow-comparison normalization |
| Shared scalar temporary index | 132.64 | Complete `stage2-block-count` rejection |
| Indexed frame temporaries and stack uses | 33.87 | Same complete `stage2-block-count` rejection |

The trace identifies repeated whole-function collision scans for each generated
temporary. The lazy collision index preserves the same first available serial,
including quoted/escaped aliases and removed definitions, while scanning names
once per immutable source and prefix. Scalar legalizers and padded frame storage
share it. The deterministic scaling regression requests 4,096 temporaries after
indexing 2,049 names, without another name scan.

After the first repair, padded frame storage still consumed 49.11 seconds in one
attempt; stack-address legalization consumed 47.52 seconds across three attempts.
Their indexed versions take about 0.08 seconds per frame attempt and at most 0.11
seconds per stack attempt in the recorded sample. Stack-use collection preserves
width bounds, invalid memory-length rejection, quoted identities and original
allocation traversal order. Full-module setup and other selection work remain in
the 33.87-second total. These are local diagnostic samples, not a general compiler
throughput or emitted-code optimization benchmark.

`focused-probes.sha256` identifies the retained development probe binaries; the
`slow-traced`, `slow-indexed` and `slow-indexed-all` streams, time records and
available final profiles retain their results. The earlier `slow-initial` probe
used the frontend target spelling rather than the explicit backend target and
is excluded from these measurements. Final acceptance separately binds the
complete production-source manifest and both compiler builds.

## Call and memory attributes

The prior partial compiler census reported 1,648 call-attribute failures. A
read-only scan of all original calls finds rejected contracts in 1,634 of those
functions: 1,621 contain rejected `dead_on_unwind` pointer facts, 293 return-range
facts, 164 `noundef` return facts, and 82 argument-range facts. These groups overlap
and do not identify each function's first failing instruction. Fourteen failures
are not attributed by the original-call scan; private rewrites can change call
forms. All original rows and unattributed names are retained.

Ordinary nonvolatile memcpy and memmove use the common validated pointer-fact
contract and accept validated `noundef`/range facts on their i64 lengths.
The first complete census exposed that length case in `link.Coff.navSection`;
it is included in the final implementation and native regression.
Ordinary calls accept `dead_on_unwind`, validated integer range facts,
and supported return facts without changing register placement. Range validation
checks grammar, matching type, bounds and wrapped endpoints. Parameter-only
attributes remain excluded from returns. Inline assembly, operand bundles,
sign/zero extension, byval/sret payloads and unsupported address spaces retain
their existing explicit boundaries. Semantics follow the
[LLVM attribute definitions](https://llvm.org/docs/LangRef.html#parameter-attributes).

The new `call_attributes` native population contains five functions. Each of three
modes compares two local routes with LLVM, covering zero/nonzero and unaligned
copies, both overlap directions and identical memmove pointers, clobbering calls,
wrapped 32/64-bit ranges, preserved live arguments, exact writes and inaccessible
page boundaries. Both copy lengths carry range facts, in different attribute
orders. It supplies 14,790 local and 7,395 reference observations per
compiler build. Both final Debug and ReleaseFast builds pass. Negative selector
tests retain malformed-attribute and ABI rejection without machine-state changes.

The final completed census reports 71 remaining `UnsupportedCallAttributeAbi`
failures. None is explained by a rejected original call in the read-only scan;
inspecting rewritten call contracts is needed to attribute them. This scan does
not prove support for those functions or justify dropping their attributes.

## Diagnostic and acceptance results

The unchanged 455-definition runtime replay completes with 274 successful
selections and 181 failures. All 272 previous successes remain; newly selected
functions are `compiler_rt.sincos.sincosf` and `compiler_rt.sincos.sincosh`.
This is selection evidence and publishes no complete runtime object.

The unchanged compiler replay completes all 8,928 definitions: 3,524 selections
succeed and 5,404 fail. Wall time is 759.67 seconds, with 6,434,792 KB maximum RSS.
The final length-attribute fix adds `link.Coff.navSection` without losing any of
the intermediate census's 3,523 successes. Every original function is attempted;
the dependency analysis remains conservative rather than proving precise
reachability. Neither rejected replay publishes a complete object or earns
compiler startup/self-rebuild credit.

The compiler stream contains 3,535,753 events and the runtime stream 70,370.
Complete audits check sequence, elapsed-time ordering, unique function identity,
balanced activities/legalizers/retries and exact agreement with final counters.
The compiler stream is 1,052,627,590 bytes, SHA-256
`bda41192cdc861d104dcf9abc7d7d4cd50b87bf633d698c421c3d60515ec0620`.
The runner retains exact backend arguments, unchanged input identities, all
rejected functions and complete profiles in `compiler-replay-accepted/` and
`runtime-replay-accepted/` under the evidence root.

Largest compiler first-failure groups:

| Shared boundary | Functions |
| --- | ---: |
| Call argument width | 1,086 |
| LLVM intrinsic lowering | 785 |
| Call return width | 771 |
| Memcpy source ownership/form | 751 |
| Global GEP properties | 364 |
| i8 parameter extension | 314 |
| Register pressure | 184 |

These are first rejections, not estimates of how many functions a repair will
complete. The full profile records 201.17 seconds in reachability, 316.26 in
optional legalization and 205.75 in selection. Integer-form legalization accounts
for 197.66 seconds across 60,609 attempts. Those are retained follow-up leads;
this slice does not claim to resolve the remaining costs.

The cumulative run passes all 17 gates in 3,504.97 seconds. Its 49 native
populations supply 1,803,204 local observations against 901,602 references.
The prior 48 populations retain their fixture hashes and observation counts.
Debug and ReleaseSafe each pass 1,944 units and 21 structural checks. The two
profiling process tests, five whole-compiler reporting tests and readiness pass.
The new native population passes independently with both Debug and ReleaseFast
compilers before the cumulative run.

All five fixed Zig programs pass in three modes. The unchanged Zig migration
corpus passes 87 input/mode pairs and 603 observation controls; the input-driven
C corpus passes 138 pairs and 552 observation controls. Execution-breadth controls
pass 21 function/mode pairs, 22,788 observations and all 54 deliberate faults.
The behavioral suite retains 24 program/mode pairs and 6,528 observations.

Core counts remain 100 lowered/emitted/linked and 12 executed per mode, with
bypass ratchet 130. All 36 selected-object and observation records match the
previous acceptance, including linked sizes. Independent reference-wrapper sizes
differ in 12 records, and wrapper hashes vary with their output paths; these
fields are excluded explicitly and the deltas retained. There is no blanket
byte-identity claim for linked/reference executables.

Only `full-acceptance.log` and the `*-replay-accepted/` roots supply final
acceptance. Earlier setup-only and interrupted `full-census-v1` runs remain as
superseded evidence; the latter was stopped to include the length-attribute fix.
Postchecks verify frozen source membership and hashes, compiler identities,
both original inputs and all thirteen original scratch files. No archives are
created. Disk admission remains 32,949,672,960 bytes; execution reserve remains
24,359,738,368 bytes. The final compiler replay samples no reserve violation,
with a minimum of 46,856,355,840 available bytes. Cumulative gate-boundary and
additional periodic disk samples are retained separately in the acceptance record.
