# Padded GEP stride correctness repair

Status: accepted after fresh Tier-3 qualification and storage closure.
Evidence root:
`local-state/validations/compiler-generalization/follow-up-20261116/stage-01`.
Admission is `e5a092db`, with compiler source `11fd57ec`; the preceding consumer
fallback repair is already committed and storage-closed.

The required layout audit confirms a runtime defect in address analysis.
With explicit i24:32 and f80:128 alignment, i24 has store/allocation sizes 3/4,
and x86_fp80 has 10/16. GEP's first step incorrectly uses store size. Two
different byte addresses then appear identical to alias analysis, which feeds
EarlyCSE/GVN forwarding, DSE, MemorySSA and SROA.

The preserved four-function input checks positive and negative scalar steps.
LLVM verifies it and its native reference returns 11 with both required stores
preserved in all four cases. Actual project transformations produce:

| Pipeline | Returned byte | Nearby stored byte | Native outcome |
| --- | --- | --- | --- |
| EarlyCSE | 22 | 11 | Four failures, exit 1 |
| GVN | 22 | 11 | Four failures, exit 1 |
| DSE | 131 | 131 | Four failures, exit 1 |
| release-o3 | 22 | 131 | Four failures, exit 1 |

These are independent native executions of transformed IR, compiled by LLVM;
the audit wrapper's successful status records reproduction, not successful
project semantics. Baseline compiler SHA-256 is
`19ad0133b35049359ef925ecd798a1fc830270a44e1c8357da647c2093766b89`.
The original failed quiet-output wrapper and conservative release-prefix refusal
remain diagnosed and unchanged; they earn no project execution credit.

The new unit regressions fail on unchanged production with actual offsets 3
instead of 4 and returned value 22 instead of 11. Their reproduction wrapper
separately records the actual Zig test exit 1 and two failing regressions.

The narrow correction uses allocation size for layout-aware GEP steps and keeps
access widths on store size. Padded scalar steps without layout remain unknown.
No shared layout abstraction or broader pointer-fact migration is included in
this correctness slice. All 76 layout tests pass in Debug and Fast, all 2,425
Fast units and 74 structural checks pass. The new eight-function native canary
covers positive/negative i24, i40, x86_fp80 and padded-vector steps, with 256
independent guarded observations per execution. Generation is deterministic and
LLVM verifies the input.

Candidate compiler is
`9014202809500d3262f80641810fb611fb4627f5ad53b550fdf73f04553ce429`.
Its direct canary/fixed Debug objects and owner reports equal the retained
predecessor. The fixed input retains object hash `92825c8e...`. Four optimizer
pipelines, each with explicit and absent layout, match the native oracle.
Three-mode direct/release native checks match 1,536 local with 768 reference
observations and detect all 72 injected failures. Registry count is now 236;
existing populations and compiler-core/rt ratchets are unchanged.

The first qualification aggregate remains failed with actual exit 2: its final
Git whitespace check found an extra generated newline at EOF. Its semantic
checks all completed successfully. `format-followup` preserves that receipt,
proves the refreshed fixture equals the original minus one final newline and
has identical canonical/optimized IR, direct object and owner output. It verifies
unchanged consumed compiler/test source for unit reuse, repeats generation,
reference/native/fault checks and structural smoke, and passes the whitespace
check. The compiler binary is unchanged.

The completed predecessor compiler is released and guarded collection reclaims
654,049,280 allocated file bytes at
`local-state/retirements/automatic-storage-cleanup/1794892610187828568-3527718/report.json`.
Compared object workspaces close before integration. The fresh mandatory serial
run `2fb41b11c92e577d5e199904a61844af` passes all seventeen gates and all 236
native populations. Only authenticated frontend AIR is reused; backend, objects,
links and executions run afresh. The new canary again records 1,536 local and
768 reference observations. Source, compiler identities and all seven current
integrity manifests verify unchanged after execution.

The ordinary Debug compiler produced by the legacy gates is retired after exact
identity, prefix inventory, consumer and integrity checks. No new main temporary
directory remains. Original failure and busy-release receipts stay unchanged.
`semantic-repair-closure-v2/report.json` passes: its final collector receipt is
`local-state/retirements/automatic-storage-cleanup/1794899066081353320-3737857/report.json`,
with 461,258,752 allocated bytes reclaimed after the preceding completed-job
collection reclaimed 3,977,166,848 bytes. All seven contracts and seventeen
independent holds are unchanged.

Two explicitly adopted pipelines continue into the authorized layout-query
slice: the qualified 90142028 compiler for predecessor comparisons, and the
isolated source/probe copy for query qualification and promotion. Their paths,
consumers and release conditions are recorded in the closure retention notes.
All other task temporary roots are closed. This acceptance makes no new
ReleaseSafe milestone or performance claim.

The remaining layout audit independently confirms five integer alignment/native
geometry errors. An isolated shared-query prototype matches 48 verified LLVM
cases; backend/table callers and the audited analysis migration have focused
checks. Those proposed sources are not part of this correction or its acceptance
and require separate production qualification after promotion.
