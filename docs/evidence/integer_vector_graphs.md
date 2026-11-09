# Integer vector graphs and pressured shifts

Status: accepted at `d06659d1`, following `636816de`.
The [all-8,928 selection plan](../plans/2026-11-08-complete-compiler-selection.md)
remains active with 506 definitions still to select.

Record: [acceptance JSON](integer_vector_graphs_acceptance_20261109.json).
Contract: [private integer vector graphs](../codegen/integer_vector_graphs.md).
Raw evidence: `local-state/validations/compiler-selection-completion-20261108/batch-03/`.

## Implementation and original-input selections

The private lane graph now handles exact mask bitcasts, stable forward/backedge
PHIs, pointer lanes, internal integer lanes through i128, wider vector repacking,
scalar freeze and closed lane-wise intrinsics. Public vector ABI admission stays
separate. Scalar pair projections reuse computed words; the typed R01 shift
falls back to a preserving accumulator session under GPR pressure. The verifier
requires equal lane counts for pointer/integer vector casts. Original IR,
function signatures, source attributes and frozen bypass inventory remain intact.

| Population | Before | After | Remaining | Lost successes |
| --- | ---: | ---: | ---: | ---: |
| Compiler | 8,170 / 8,928 | 8,422 / 8,928 | 506 | 0 |
| Runtime | 285 / 455 | 285 / 455 | 170 | 0 |

Of the original 169 mask targets, 152 select and seventeen reach later limits.
Another hundred selections come from the broader graph capabilities. Both
production replays match their complete censuses on selected identities and
rejection tuples. Balanced audits cover 3,589,628 compiler events and all 8,928
definitions, plus 73,778 runtime events and all 455 definitions. These are
selection proofs; complete objects, startup and self-rebuild are not established.

## Validation

Debug and ReleaseSafe each pass 2,004 units and 24 structural checks. All nine
readiness commands and captured object smoke pass. Units cover source ownership,
private verification, idempotence, forward PHIs, scalar freeze retention,
malformed vector casts, pressure preservation and transactional rollback.

The nine-function `vector_masks` population records 13,824 local observations
against 6,912 references per compiler build. The eight-function `vector_graphs`
population records 6,144 local observations against 3,072 references. Frozen
Debug and ReleaseFast compilers both pass both routes in all three modes.
Checks include independent expected bits, exact guarded memory, page ends,
128-bit carries, pointer round trips, parallel PHIs and clobbering calls.
Undefined lanes are overwritten before equality observations; freeze consistency
is checked separately. LLVM and local builds both reject each wrong-pack,
wrong-PHI and wrong-carry mutation, for six independent driver detections.

All 17 integration gates pass in 3,497.45 seconds. The 69 native populations
record 2,087,940 local observations against 1,043,970 references, preserving
all 67 preceding population records. The three authenticated AIR cache hits
retain their keys and descriptor sizes; producer and cache infrastructure are
unchanged.

The five fixed programs pass fifteen program/mode pairs. The Zig corpus passes
87 pairs and 603 controls, and the C corpus passes 138 pairs and 552 controls.
Zig selected identities and owners match the preceding checkpoint. Instruction
or spill counters change in nineteen Fast, seventeen Safe and nineteen Small
functions; the complete per-function differences are retained. Other function
counters match. Core fault controls retain 21 pairs, 22,788 observations and
all 54 expected detections.

The core retains 100 lowered/emitted/linked functions and twelve executed and
accepted functions per mode. All 36 selected-object, descriptor and observation
records match. All linked and reference sizes match. Fast/Safe reference hashes
and 35 linked hashes differ; twelve Small reference hashes and one Small linked
hash match. The established four-field executable metadata review stays separate
from selected-object and behavior equality. The 100-row prefix, twelve-function
cohort and bypass ratchet 130 are unchanged.

## Identity and retention

Implementation: `d06659d1d1e256edc4148f4b3c44770136daa6a0`.
Tree: `33aa089ed5ee52b201db58579e6785bfe88460c6`.
The 1,787-file source manifest and complete 3,112-file membership snapshot bind
the frozen implementation. Acceptance documentation follows source validation.

| Compiler | SHA-256 |
| --- | --- |
| Debug | `5f5314052508093429d98d916a9c1cd6651c02820603a5c0f6d92d1ab8a39dd7` |
| ReleaseSafe | `1ccb96c0db0f8cf076f191723287178c7cb23e9a2341ce71301d0ea55b8c8b34` |
| ReleaseFast | `1c017755f21e7b31f9859fb7ce205517e6aec5c1156e3fea08423b9e1f20089f` |

All final native reports bind these binaries and current fixture hashes.
Earlier graph, pressure and verifier failures are retained and superseded by
final passing results. The development full census was intentionally stopped
after the final verifier change; its partial capture has no complete-input
credit. An initial carry mutation reached a selection limit; the final shift65
mutation compiles in both backends and is independently rejected. The first
full launch failed root canonicalization before gate 1 because its required
directory was missing; the same frozen command restarted after creating it.

The new seal covers 1,593 artifacts, SHA-256
`9c93240be5c1293aed2b3ec43e3a5e5ab41ce77ad20a260ba362a0b33acf9b44`.
The preceding 648-, 920-, 602- and 461-artifact seals verify. Original inputs,
emitter, authenticated AIR payloads and thirteen scratch files remain intact.
No archives or manual cache retirement occurred. All 116 expected report files
were retained and the complete evidence collector passed.

The outer tool session and retention helper each reported status 143 for an
unconfirmed cause. The authoritative checked runner and full-script exit record
are both zero; all 17 gates and final report audits pass. These session statuses
are retained separately from the execution result.

Serial admission records 57,219,485,696 free bytes, with a serial minimum of
52,374,331,392 and an outer-capture minimum of 51,389,620,224. The admission
threshold remains 20 GB, the working allowance 8 GiB and the reserve
11,410,065,408 bytes. Timings and filesystem samples include concurrent activity.
