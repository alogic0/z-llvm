# Scalable CFGs and indirect scalar PHIs

Status: accepted after complete production matching and artifact sealing.
Implementation: `bb74a371b7b84c023da8356ef4d7a13da3b7ca35`, tree
`6efce2b146f61893661aedd10963e93328d05122`, following `5d71dc80`.
The [all-8,928 plan](../plans/2026-11-08-complete-compiler-selection.md) remains
active with 264 definitions still to select in the complete census.

Record: [acceptance JSON](scalable_cfg_indirect_phi_acceptance_20261109.json).
Contract: [scalable CFGs and indirect scalar PHIs](../codegen/scalable_cfg_indirect_phi.md).
Raw evidence: `local-state/validations/compiler-selection-completion-20261108/batch-05/`.

## Implementation and complete-input selection

Canonical block indexes replace repeated graph, verifier and selector lookups.
The predecessor worklist computes liveness over every terminator successor,
including indirect branches. Unique predecessors retain switch-edge multiplicity.
Traversal storage uses the actual graph size and the private block ceiling is
65,536. Label retention performs a single indexed instruction scan, with all
fallible ownership work completed before machine mutation.

Indirect-target scalar PHIs use distinct private entry slots. Each predecessor
stores its frozen incoming value before branching, and target loads retain the
original result name and type. Direct and indirect predecessors, simultaneous
copies, i128 high words, pointers and half/float/double bits are covered. Original
block addresses, target lists, public signatures and source instruction arrays
remain unchanged. Inactive poison values stay unobserved in private slots.

Owned value-use identities grow from 192 to 512 bytes, with u16 length fields.
The bounded transaction grows by 322,368 bytes to 688,656 bytes, alignment 16.
The separate 192-byte address-dependency identity bound remains unchanged.

| Population | Before | Census after | Remaining | Lost successes |
| --- | ---: | ---: | ---: | ---: |
| Compiler | 8,552 / 8,928 | 8,664 / 8,928 | 264 | 0 |
| Runtime | 285 / 455 | 285 / 455 | 170 | 0 |

Of 132 original CFG/indirect-PHI/identity targets, 111 select and 21 reach later
limits. `codegen.generateFunction` also selects outside that initial set.
Independent production replays match every selected identity, owner and remaining
rejection tuple. Balanced audits cover 3,976,792 compiler events and 81,761 runtime
events, with exactly 8,928/455 unique definitions and matching begin/end counts.
Selection does not establish complete compiler objects, startup or self-rebuild.

## Validation

Debug and ReleaseSafe each pass 2,030 units and 24 freshly executed structural
checks. Nine readiness commands and captured object smoke pass. Units cover
canonical indexing, edge multiplicity, independent full-sweep liveness results,
loops/unreachable blocks, owned index transfer, scalar PHI transport, source
ownership, idempotence, long shared prefixes and every injected allocation failure.

| New native population | Functions | Local observations per compiler build | LLVM references per compiler build |
| --- | ---: | ---: | ---: |
| Large CFGs | 5 | 15,744 | 7,872 |
| Indirect scalar PHIs | 17 | 13,056 | 6,528 |

Both populations pass with frozen Debug and ReleaseFast compilers, through both
routes in all three release modes. Observable original block-address anchors
retain a 20,976-block chain, a 2,048-block all-SSA chain, 1,025 unique switch
successors, repeated/default targets, and 406-byte shared-prefix labels. The PHI
population checks widths 1 through 128, full FP bits, pointer contents, looping
parallel swaps, clobbering helpers, live results and defined poison neighbors.
Five valid LLVM IR mutants produce ten expected LLVM/local negative detections.
Existing indirect-branch execution is rerun separately without new population credit.

All 17 serial integration gates pass in 4,593.977 seconds, with actual checked
process exit 0 and terminal success. The 74 native populations preserve all 72
preceding entries and record 2,132,868 local observations against 1,066,434
references. Five fixed programs pass 15 mode pairs; the Zig corpus passes 87
pairs and 603 controls; the C corpus passes 138 pairs and 552 controls. All 21
core fault-control pairs, 22,788 observations and 54 negative controls pass.
The strict prefix remains 100 rows, the core cohort twelve functions, and the
compiler-rt bypass ratchet 130.

All 36 core selected objects, descriptors, observations, linked sizes and
reference sizes match the preceding checkpoint. Reference hashes differ in 24
Fast/Safe records and match in twelve Small records; linked hashes differ in
32 records and match in four Small records. These executable metadata fields
are reviewed separately from selected objects and observations.

Zig selected identities and owners are preserved. Attempt counters change in
1,642/1,852/860 functions across Fast/Safe/Small. Only `Io.Threaded.posixExec`
changes machine counters: instructions +15/+11/+15 and spills +9/+7/+9.
Only attempt, instruction and spill counters change; complete before/after
records and their hash remain in the raw evidence and acceptance record.

## Supervision, retained attempts and boundaries

The serial full command has durable actual checked exit 0. All 116 required
final reports are retained; the retention helper exits normally and removes
its FIFO. Both complete census commands have actual checked exit 0.

The first compiler production command reached its default one-hour deadline:
backend `timed_out`, actual backend exit -15, no terminal selection proof.
Its incomplete captures remain retained and excluded from acceptance. The same
frozen compiler and unchanged original input were replayed using the existing
explicit two-hour deadline option. That retry completed with actual checked outer
exit 1 because 264 selections remain blocked; its backend selection completed and
supplies the verified compiler proof. The runtime replay completed independently.
An idle old waiting helper was
intentionally terminated after its runtime child completed; no child command
was interrupted and its wrapper exit 143 is recorded explicitly.

Early root-only test filters, superseded fixtures, input-limit and runner-deadline
attempts, parser/linkage boundaries and weaker initial i1 oracle inputs remain
retained without passing credit. The final giant fixture passes unchanged runner
limits. A separate original all-SSA 20,976-block Debug execution uses an explicit
8 MiB input limit and checks 2,624 observations; it is auxiliary and excluded
from registry totals. Read-only frame/snapshot/wide-float research adds no
acceptance selections, unit counts or execution populations.

The implementation freezes 1,808 source files and a 3,139-file complete source
snapshot. The unchanged compiler input has 443,624,107 bytes and SHA-256
`de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`.
The CLI input allowance is one byte larger than the file. Source, binary, input,
frontend, thirteen scratch-file and prior seal hashes are checked independently.
The read-only raw seal binds 2,759 files with manifest SHA-256
`c1d16c0abcaf0de509830660f71e2299b523a81c8d4e59247e898dd70021901e`.
Its excluded verification log remains writable. All six preceding seals verify.

Three authenticated AIR cache hits retain their prior payload keys and byte
counts. Admission remains 20 GB, the working allowance 8 GiB and reserve
11,410,065,408 bytes. The serial run starts with 33,040,187,392 bytes free and
observes a minimum of 23,458,652,160. Samples and timings include concurrent
census/replay/research work. No archives or manual cache retirement are introduced.

At this frozen checkpoint, the private frame ceiling remains 1 MiB. The
canonical indexes do not generalize raw SSA-definition keys or every existing
PHI target-spelling comparison. Scalar PHI transport, identity storage, aggregate
and floating ABIs retain explicit boundaries. Continue with the remaining 264
original-input failures; the all-8,928 objective remains active.
