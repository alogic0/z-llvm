# Runtime storage and exact integer memory

Status: accepted at `5d71dc80`, following `d06659d1`.
The [all-8,928 plan](../plans/2026-11-08-complete-compiler-selection.md) remains
active with 376 definitions still to select.

Record: [acceptance JSON](runtime_integer_storage_acceptance_20261109.json).
Contract: [private storage and integer memory](../codegen/runtime_integer_storage.md).
Raw evidence: `local-state/validations/compiler-selection-completion-20261108/batch-04/`.

## Implementation and complete-input selection

General private storage views retain ordinary runtime memcpy lengths. Exact
non-native integer memory accesses use bounded byte chunks and register-only
carriers. Mandatory scalar select normalization refines explicit undefined arms
to zero/null while preserving the condition and defined arms. Known pair low
words replace redundant projections; unused pure pair constructions are removed
only with complete operand coverage. Source facts, public signatures, memory
barrier boundaries and the frozen bypass inventory remain intact.

| Population | Before | After | Remaining | Lost successes |
| --- | ---: | ---: | ---: | ---: |
| Compiler | 8,422 / 8,928 | 8,552 / 8,928 | 376 | 0 |
| Runtime | 285 / 455 | 285 / 455 | 170 | 0 |

Of 196 original storage/undefined-select targets, 127 select and 69 reach later
limits. Three additional hash functions select outside that initial group. The
complete terminal census has 8,928 unique compiler definitions; independent
production replay matches every selected identity, owner and remaining rejection
tuple. Balanced audits cover 3,855,224 compiler events and 80,007 runtime events.
Selection does not establish complete compiler objects, startup or self-rebuild.

## Validation

Debug and ReleaseSafe each pass 2,013 units. All 24 structural checks pass in
both modes; Debug reuses its valid unchanged cached result. All nine readiness
commands and captured object smoke pass. Units check source ownership, private
verification, idempotence, exact byte extents, opaque references, identifier
aliases, strict rejection boundaries and seeded machine rollback.

| New native population | Functions | Local observations per compiler build | LLVM references per compiler build |
| --- | ---: | ---: | ---: |
| Runtime storage | 4 | 3,072 | 1,536 |
| Integer memory | 5 | 7,680 | 3,840 |
| Undefined selects | 7 | 5,376 | 2,688 |
| Total | 16 | 16,128 | 8,064 |

Frozen Debug and ReleaseFast compilers each pass both routes in all three release
modes. Checks include initialized 33/4,096-byte and padded named storage, exact
3/5/7/9/12-byte page ends, defined bits, pointer neighbors, live values and
clobbering calls. Four valid IR mutations compiled by LLVM and local Debug
produce eight expected negative detections. Undefined select choices and
non-byte padding are never used as equality oracles.

All 17 serial integration gates pass in 3,571.572 seconds. The 72 native
populations preserve all 69 preceding entries and record 2,104,068 local
observations against 1,052,034 references. Five fixed programs pass 15 mode
pairs; the Zig corpus passes 87 input/mode pairs and 603 controls, and the C
corpus passes 138 pairs and 552 controls. All 21 core fault-control pairs,
22,788 observations and 54 negative controls pass. The prefix remains 100 rows,
the core cohort twelve functions, and the compiler-rt bypass ratchet 130.

All 36 core selected objects and observation fields match the preceding
checkpoint. Linked and reference sizes also match. Reference hashes differ in
24 Fast/Safe records and match in twelve Small records; linked hashes differ
in 32 records and match in four Small records. Executable metadata is reviewed
separately from selected objects and observations.

Zig selected identities and owners are preserved. The additional legalizer stage
changes attempt counters in 1,654/1,873/866 functions across Fast/Safe/Small.
Machine instruction/spill counters change in only 10/11/9 functions. Aggregate
instruction deltas are +25/+19/-836, and spill deltas +28/+24/-240. Only these
three counter fields change. Complete before/after records remain in the sealed
raw review; the acceptance JSON includes its hash, summaries and all machine
counter changes. Profiles are not claimed identical.

## Supervision and retention

The outer full-command and compiler-census supervisors terminated with tool
status 143; the cause is unconfirmed and their command exit statuses are
unavailable. Their interrupted captures are retained unchanged. The isolated
runners continued. All seventeen durable gate-end exit-zero records, final serial
`local_fail=0`, terminal success line and process completion are verified. The
complete census terminal records match the independently completed production
replay. No missing outer return code is inferred and no passing gate was rerun.
The report-retention helper was stopped intentionally after all 116 required
final reports were audited; its FIFO was removed.

The initial i65 development oracle incorrectly used a non-byte load without a
same-type store. Its LLVM reference failure has no compiler wrong-code credit.
The corrected typed-store fixture passes both compilers. Earlier pair-pressure
failures, superseded fixture/registry hashes and failed unit setups remain
retained without final execution credit. Strict storage and rollback tests were
updated to preserve their real boundaries after newly supported forms advanced.

The implementation freezes 1,798 source files and a 3,126-file source snapshot
at revision `5d71dc80300b997717563c6e2f20bfc2da42394f`, tree
`39786e6b79ac0e954ff1ab5b78ca0dc6f8c36e84`. Acceptance documentation follows that
snapshot. The unchanged 443,624,108-byte compiler input retains SHA-256
`de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`.

The raw seal binds 1,212 files with manifest SHA-256
`3c6cd30e04b3b1e4304178d2fd4cf4dfbbbb5ccb25312cf0f9bf31d1f2c64471`.
It is read-only except its excluded verification log. All five preceding seals,
original inputs, thirteen scratch files and authenticated AIR payloads remain
intact. Three AIR hits preserve prior identities and descriptor bytes. Admission
is 20 GB, the working allowance 8 GiB and reserve 11,410,065,408 bytes. The serial
run starts with 44,521,500,672 bytes free and observes a minimum of 40,609,542,144.
No archives or manual cache retirement are introduced. Timings and global space
samples include concurrent activity.

Continue with the remaining CFG, indirect/aggregate PHI, identity, pointer-flow
and wide/FP ABI limits. Read-only sizing finds a 20,976-block original maximum
and a conservative 33,722-block expansion bound; those are research measurements,
not newly admitted CFG sizes. The all-8,928 objective remains active.
