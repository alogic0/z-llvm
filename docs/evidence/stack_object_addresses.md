# Owned stack-object addresses

Accepted code `948fad9c6801bcda68ff2c1fea3a089008be5889` selects **8,777/8,928** unchanged compiler
definitions, adding 23 without losing a preceding success or changing its owner.
The independent production replay agrees on every outcome and failure detail.
Runtime retains **318/455**. All 151 original compiler rejections remain in scope;
selection does not establish complete objects, startup or self-rebuild.

The [acceptance record](stack_object_addresses_acceptance_20261110.json) retains
the source binding, complete census/production/event audits and validation
results. Local evidence is under
`local-state/validations/compiler-selection-completion-20261108/batch-11/`.

## Change and native proof

The [typed address contract](../codegen/stack_object_addresses.md) admits owned
scalar, integer-pair and i32-array addresses through the existing copy,
pointer-PHI, byte-GEP and direct-call boundaries. Complete frame extents are
validated before address emission; lengths, bounded memset, address spaces and
metadata retain their closed contracts. Source guards, authority policies and
the bypass inventory remain unchanged.

Two executable regressions exposed actual wrong code during implementation:
sequential spilled pointer-PHI swaps overwrote an incoming pointer, and a fixed
RCX address temporary overwrote a pending copy source. PHI snapshots now preserve
the actual earlier-write hazards, using the existing canonical-resolution pass.
Owned copy addresses form directly in their destination register. Both exact
regressions execute in the accepted tests and mandatory population.

The Zig generator reproduces the nineteen-function IR, C driver and appended
registry entry byte for byte. Its oracle checks 9,480 observations per execution:
exact copy lengths, scalar/FP/pair/array objects, both PHI edges, swapping loops,
dynamic offsets, overlapping moves, clobbering calls and protected-page guards.
All three modes and both local routes pass against LLVM with final Debug and
ReleaseFast compilers: **56,880 local / 28,440 reference observations per build**.
Every one of the **90 injected faults per build** is detected.

Both complete **82-population** native suites pass, recording **2,533,722 local /
1,266,861 reference observations per compiler build**. All 81 prior registry
entries and **3,017 prior command outcomes** remain exact. Of 1,236 preceding
compiler artifacts, **1,218 are byte-identical**: 252 optimizer outputs, 489 owner
manifests and 477 objects. Eighteen objects intentionally change across
`address-flow`, `large-frame` and `stack-addresses`, in three modes and two routes.
Their original typed frame addresses now select directly instead of requiring
private pointer-spill rewrites. All affected LLVM comparisons pass; symbol
inventories and old/new disassemblies are retained. The same eighteen hash
changes occur with both compiler builds.

The strict native comparators remain `failed` with
`NativeArtifactsRequireReview`. The explicit artifact review accepts only those
eighteen lowering changes and preserves every raw difference. No complete
artifact-byte equality is claimed. A further comparison proves all final Debug
replay outputs match the preceding same-source Debug outputs.

## Cumulative validation

Debug and ReleaseSafe each pass **2,095 unit, 24 structural and two profile
checks**. All nine readiness procedures pass, including sixty ABI cases across
thirty real function/mode combinations and their negative controls.

The serial Tier-3 run finishes with actual return code zero and all **seventeen
gates** passing. Each real-row mode emits and links 100 objects, executes the
unchanged twelve-function core, and reports no local failure. The release source
object bundle remains byte-identical at
`3b65f5608098bf2c5f7816bea4b38a0cf0333797b516d1c7ae21d1f7e89d5249`,
produced once and consumed three times with no cached executions. All 36 core
selected objects and observations match the preceding checkpoint. Thirty-one
wrapper records differ only in the four retained reference/linked size/hash
fields. Strict full and real-row log comparisons also retain the added mandatory
population summary, reporting 1,520 versus 1,521 canonical records; complete log
equality is not claimed.

The complete unfiltered compiler census and independent production replay both
traverse all 8,928 original definitions and select 8,777. All **4,363,840 compiler
events** balance, including every function begin/end, activity, legalization and
retry. The runtime census, production profile and event audit independently
cover all 455 definitions and retain 318 selections. Both production commands
finish with actual return code one because remaining selection failures prevent
complete object emission.

All **3,195 frozen source file hashes** bind to the accepted code tree. The sole
post-replay source change corrects the padded-frame test expectation for the
newly supported dynamic offset; every production source remains unchanged.
Final ReleaseFast and census rebuilds are byte-identical to the binaries that
completed production, full integration and the original census. Both final
compiler receipts match all 596 compiler source hashes. Final unit-tested source
matches all 3,195 files exactly.

The Debug rebuild differs, so its full native and fault proofs are freshly
replayed. During binary inspection, an `objcopy` invocation repacked the older
and final Debug installs. The final install was restored from the unchanged
build cache and checked against its original receipt. The older install has no
remaining exact cache copy; its receipt, observed discrepancy and superseded
proofs remain explicit in `binary-review-v5/inspection-incident.json` and receive
no final acceptance credit. The ReleaseFast and census files were untouched.

The fixed prefix, core cohort, ratchet 130, accepted-status file, three retained
AIR payloads and thirteen scratch pins all verify. Earlier prototypes and failed
attempts are retained without acceptance credit. No archives or manual cleanup
are introduced. Replay timings under concurrent load establish completion, not
a controlled performance ratio.

## Next frontier

Continue the [all-8,928 plan](../plans/2026-11-08-complete-compiler-selection.md)
through the remaining 151 original definitions. The complete census retains
floating/structured storage, scalar operand, call-attribute and frame-address
boundaries. Diagnose the concrete operands in isolated work, preserve the
original denominator and owners, and accept another count only with complete
census and independent production evidence.
