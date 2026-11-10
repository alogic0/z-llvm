# Physical integer ABI checkpoint

Accepted source: `7d41908043d249f993843a2f4e465e253a38ecb6`, following
`dba98f43`. The [all-8,928 plan](../plans/2026-11-08-complete-compiler-selection.md)
continues through all 189 remaining original compiler definitions.

Record: [acceptance JSON](integer_physical_abi_acceptance_20261110.json).
Raw evidence: `local-state/validations/compiler-selection-completion-20261108/batch-09/`.
`accepted-artifacts.sha256` pins the source seals, compilers and proof records.

| Population | Before | After | Remaining | Lost successes |
| --- | ---: | ---: | ---: | ---: |
| Compiler | 8,722 / 8,928 | 8,739 / 8,928 | 189 | 0 |
| Runtime | 285 / 455 | 296 / 455 | 159 | 0 |

## Shared physical locations

Caller preparation, incoming parameter capture and frame reservation share one
integer layout, bounded at 32 direct arguments. Native i128 stays in a consecutive
register pair or aligned complete stack slot. Other two-word integers can split
between R9 and the stack and retain independent-word alignment. Private i128
carriers preserve their original 65–127-bit ABI classification in explicit
metadata. Original functions, declarations, types and attributes remain immutable.
Validated range promises stay tied to their source widths.

Incoming words are captured into owned homes without clobbering register inputs
needed by the first instruction. Outgoing values are preserved before staging;
push offsets include alignment holes and the changing RSP. Reservation covers
unused incoming words. Pair-low casts under full register pressure preserve
overlapping values and aliases through the existing transfer authority, with
transactional failure checks. The original fingerprinted parameter binder,
688,656-byte transaction assertion and source guards remain unchanged.

The [typed contract and upstream mapping](../codegen/integer_physical_abi.md)
identify LLVM 22's consecutive-i128 classification and independent-word rules.
Indirect calls retain their preceding envelopes. Integer80 payload support does
not establish x87 or floating arithmetic support.

## Complete original-input proof

The compiler input remains 443,624,107 bytes, SHA-256
`de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`.
`compiler-census-audit-v3.json` verifies an unfiltered stream over all 8,928 unique
original definitions, balanced terminal counts, seventeen new selections and no
lost success or changed owner. The earlier 49-function diagnostic contains every
gain and records three functions reaching later boundaries.

`compiler-production-audit-v3.json` independently matches every function outcome,
selected identity and rejection tuple. The event audit verifies 4,110,759 ordered,
balanced records and all 8,928 unique function begin/end pairs. Complete runtime
census and production likewise agree on all 455 identities and outcomes, adding
eleven selections while retaining every preceding success and owner. Its event
audit verifies 85,320 records.

Both production processes complete with expected checked status one at the
remaining selection boundary. Source and backend verification succeeds. Neither
process produces a complete object; compiler startup and self-rebuild remain
unproven.

## Native and integration validation

Debug and ReleaseSafe each pass 2,076 units, 24 structural checks and two profile
checks. All nine readiness procedures are covered, including 60 ABI differential
cases and 30 function/mode comparisons.

The Zig generator adds forty functions and an independent C oracle. Each
execution checks 20,480 observations across scalar counts 18/32, integer widths
65/66/80/96/127/128, split and aligned stack positions, default/fastcc calls,
constants, nested calls, dirty returned bits, clobbers, fields and guards.
Both Debug and ReleaseFast pass direct/release routes in all three modes: 122,880
local observations and 61,440 LLVM references per build. Each detects all 63
calibrated faults after nine positive executions.

All 80 native populations pass with both compilers. Per build, all 79 preceding
registry entries, 2,945 command outcomes and 1,206 compiler artifacts match:
246 optimizer outputs, 483 objects and 477 ownership manifests. The total native
observations are 2,446,596 local and 1,223,298 reference per build. Debug's
cross-worktree command view changes only verified argv path prefixes; its audit
preserves every non-argv field and original artifact byte/hash. Fast compares
directly using the preceding upstream aliases.

All seventeen serial integration gates pass with actual checked status zero,
run ID `6f16df308a693c0fc6f65a7460693403`. Each real-row mode retains 100 lowered,
emitted and linked functions and twelve core executions, with authenticated AIR
cache hits. The 100-object bundle retains identity
`3b65f5608098bf2c5f7816bea4b38a0cf0333797b516d1c7ae21d1f7e89d5249`,
one producer and three consumers; executions are not cached. All 54 execution
controls pass over 21 function/mode combinations and 22,788 observations.

All 36 core-cohort records preserve descriptors, selected objects, results,
witnesses, observation counts and statuses. Thirty-four records differ in
reference/linked wrapper size or hash metadata; raw before/after fields remain
retained. Strict full-log comparison also rejects the changed canonical record
count, 1,518 versus 1,519: the mandatory new population adds a summary record.
No exact full-log equality or ELF-section explanation is claimed.

The 3,173-file source seal verifies after integration and production. Every
sealed hash matches the committed tree and both 591-file build receipts.
Debug compiler SHA-256 is
`30085fce87d8540315300e04d4c67b79a82a82567958e283247d10b73a52d291`;
ReleaseFast is
`fee523603387f9ac815267d8da90f0fda4128b2f19876106e63ef013018eec5c`.
The original inputs, three AIR payloads and thirteen scratch pins remain intact.
The fixed prefix, core cohort, ratchet 130 and `accepted_status.json` are unchanged.

## Retained limits and continuation

The invalid first fixture's range(0,0) promise supplies no semantic evidence;
corrected fixtures use truthful promises and pass LLVM. A compiler build whose
source changed during compilation is also excluded. Earlier native runs using
canonical upstream paths have nine real filename-dependent artifact differences;
the exact-alias runs above supply preservation evidence without masking hashes.
Failed worktree integration attempts remain retained. The final run uses the
main checkout required by the frozen cohort harness; no harness is weakened.

The complete census takes 3,729.39 seconds, independent production 4,072.53
seconds and the checked integration wrapper 3,067.96 seconds. Concurrent load
precludes a controlled performance-ratio claim. All required replays finish;
performance work is not an active blocker.

`compiler-frontier-v3.json` classifies all 189 remaining definitions. The largest
observed group is fp128 storage/transport; remaining groups include structured
values, symbolic pointer operands, call attributes and wider arithmetic forms.
Continue through shared typed contracts and executable LLVM comparisons. Full
original-input census and independent production remain cumulative acceptance
checks until all 8,928 definitions select.
