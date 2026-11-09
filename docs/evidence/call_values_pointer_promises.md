# Call values and pointer promises

Status: accepted at `636816de`, following `9ba5e61c`. The
[all-8,928 selection plan](../plans/2026-11-08-complete-compiler-selection.md)
remains active with 758 definitions still to select.

Record: [acceptance JSON](call_values_pointer_promises_acceptance_20261109.json).
Contract: [private call values and pointer promises](../codegen/call_values_pointer_promises.md).
Raw evidence: `local-state/validations/compiler-selection-completion-20261108/batch-02/`.

## Implementation and original-input selections

Mandatory private normalization refines explicit undefined integer and pointer
call operands to zero/null before legacy recognition and narrow ABI widening.
Defined arguments, source attributes and public signatures remain unchanged.
The shared pointer checker admits `readnone`, address/nullness capture promises
and complete, validated initialization ranges without changing machine ABI.

| Population | Before | After | Remaining | Lost successes |
| --- | ---: | ---: | ---: | ---: |
| Compiler | 7,943 / 8,928 | 8,170 / 8,928 | 758 | 0 |
| Runtime | 285 / 455 | 285 / 455 | 170 | 0 |

The initial 215 call targets produce 210 selections and five later rejections.
Seventeen additional selections previously failed casts introduced while
widening narrow undefined call arguments. Including all eighteen preceding
cast failures gives an expanded group of 233: 227 select and six reach later
load-width, select-arm, PHI or call-return limits. The initial narrower scope
check and complete transitions are retained.

Both production replays match their complete censuses on selected identities
and rejection tuples. Event audits cover 3,597,222 compiler events and all
8,928 definitions, plus 73,272 runtime events and all 455 definitions. These
remain blocked selection reports; complete compiler/runtime objects, startup
and self-rebuild are outside this checkpoint's evidence.

## Validation

Debug and ReleaseSafe each pass 1,999 units and 24 structural checks. All nine
readiness commands pass. Units cover private ownership, source preservation,
widths i1 through i128, normalization order, complete signed initialization
ranges and malformed attribute rejection.

The twelve-function call population records 24,576 local observations against
12,288 references per compiler build, through direct/release routes in all three
modes. Frozen Debug and ReleaseFast pass. Undefined parameters are ignored by
LLVM-defined helpers without `noundef`; observations use defined results and
guards. A defined-neighbor mutation fails with exit 10. A separate six-function
i1/i8/i16 probe records 1,536 local observations against 768 reused references
across the two compiler builds' direct route; it adds no mandatory-population
credit.

All 17 integration gates pass in 3,594.03 seconds. The 67 native populations
record 2,067,972 local observations against 1,033,986 references, preserving all
66 preceding population records. Three authenticated AIR cache hits retain
their keys and descriptor sizes. Cache and producer infrastructure are unchanged.

All five fixed programs pass fifteen program/mode pairs. The Zig corpus passes
87 pairs and 603 controls; the C corpus passes 138 pairs and 552 controls.
Zig selected identities, owners and per-function counters match the preceding
checkpoint exactly. Core fault controls retain 21 pairs, 22,788 observations
and all 54 fault detections.

Every core mode retains 100 lowered/emitted/linked functions and twelve
executed/accepted functions. All 36 records preserve selected-object bytes,
descriptors and observation fields. All linked and reference sizes match.
Fast/Safe reference hashes and 31 linked hashes differ; twelve Small reference
hashes and five Small linked hashes match. The established four-field executable
metadata review remains separate; no whole-executable identity is claimed.
The 100-row prefix, twelve-function cohort and bypass ratchet 130 are unchanged.

## Identity and retention

Implementation: `636816def582b8bd28fc23f6191363dc975235db`.
Tree: `f38cdf6393ea2b84816a97849dfec0d9494d0841`.
The 1,783-file source manifest and complete 3,105-file membership snapshot
verify before and after validation. Acceptance documentation follows the freeze.

| Compiler | SHA-256 |
| --- | --- |
| Debug | `9f919168469b16bff94f08b49b62adf329b7a2d923af6eb47ffb5fcb8f1be327` |
| ReleaseSafe | `91c7e68093a653cb04f95e0cacd3d5b6d71d2320d8a4678cc5e8c2082835e7aa` |
| ReleaseFast | `0fa4025ad216e0abc06ab071da6cff6cae0624b968106108559e564fc347676b` |

The suite Debug binary matches frozen Debug. The Fast development native
report uses the byte-identical final Fast binary. The differing development
Debug binary and failed initial unit/readiness attempts are retained and
excluded. Zig remains 0.17.0, the emitter pin remains `1c08b09d1`, and clang is
22.1.8. Original compiler input SHA-256 remains
`de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`.

The new seal covers 648 artifacts, SHA-256
`fab2419947a9bc40c669434efa2e87686c4018e8ed4d548e2594a3cfeadeaee0`.
The preceding 920-artifact and original 602-artifact seals verify. All inputs,
prior evidence, authenticated AIR payloads and thirteen scratch files remain.
No manual cache retirement or archives occurred. The retention helper ended
with status 143 for an unconfirmed cause; all 116 expected final report files
were retained and the complete evidence collector passed.

Serial admission records 70,702,227,456 free bytes; the serial minimum is
64,432,025,600 and the outer capture minimum is 62,823,997,440. The admission
threshold remains 20 GB and the reserve remains 11,410,065,408 bytes. Filesystem
samples and timings include concurrent activity.
