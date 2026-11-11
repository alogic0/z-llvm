# Half arithmetic and extended conversions

Accepted code `52d29d4c` selects **8,829/8,928** original compiler definitions,
adding six with no lost selections or owner changes. Independent production
agrees on every outcome and rejection tuple. Runtime reaches **320/455**,
adding `__subhf3` and `__powihf2` while preserving all prior selections and
owners. All **99 remaining original compiler definitions** stay in scope.
Selection does not establish complete objects, startup or self-rebuild.

The [acceptance record](half_and_extended_conversions_acceptance_20261110.json)
binds the complete replays to code tree
`2f6bfe4dca22599dc7868407fb37197712bb4898`. Local evidence is retained under
`local-state/validations/compiler-selection-completion-20261108/batch-15/`.

## Lowering contracts

[Half products and quotients](../codegen/half_arithmetic.md) widen operands
privately to binary32 and round the result to binary16. Finite products fit
exactly in binary32. The quotient rounding bound separates non-midpoint half
results by more than binary32 rounding error. Negation flips the representation
sign bit, preserving NaN payloads and signed zero. Ordinary half memory uses
exact two-byte integer accesses with matching allocation size and stride.
Barriers, address spaces and incompatible layouts remain closed.

[Extended conversions](../codegen/extended_float_conversions.md) use standard
LLVM runtime helpers for half/quad and i128/quad conversions. Large integer
literals receive exact named pairs. Canonical symbol identity prevents a
helper from outlining itself recursively. Mixed scalar-SSE calls place i128
values in complete consecutive GPR pairs and preserve simultaneous inputs and
pair results. Whole outgoing stack-pair boundaries remain closed.

Source IR and frozen Source/UseForm contracts remain unchanged. The earlier
half-addition lowering retains its exact implementation.

## Validation

The two maintained Zig generators reproduce their IR, C drivers and registry
entries exactly. Their populations contain **41 half functions** and **10
conversion functions**, producing **9,371,648** and **139,264 observations per
execution**. Integer product, rational division, rounding and bitwise conversion
oracles supply independent expected results. Native tests cover every half
input pattern against eighteen edge operands, literal positions, exact stores,
stack arguments, live values and providers that clobber nine GPRs and sixteen
XMM registers. All **108 injected faults** are detected across both builds.

Debug and ReleaseSafe each pass **2,114 unit, 63 structural and two profiling
checks**. Readiness passes all eight inner procedures with private caches;
ABI differential checks match sixty cases and thirty function/mode combinations.
Both complete **91-population** native suites pass **59,822,370 local /
29,911,185 reference observations per build**. Both strict native comparisons
preserve all preceding 89 entries, **3,305 command outcomes** and **1,356 prior
artifact hashes**: 276 optimizer outputs, 537 owner manifests and 543 objects.

All **seventeen integration gates** pass. Each real-row mode retains the fixed
100 emitted and linked objects and twelve executed core functions. All 36 core
descriptors, selected objects, observations, witnesses and statuses match.
Reference/linked wrapper metadata differs in 31 records, confined to four
audited fields. Strict all-field core comparison retains actual return code
one. Strict full and real-row comparisons also retain actual return code one
at **1,528 versus 1,530** canonical records after adding the two mandatory
population summaries. Complete log equality is not claimed.

The initial `full-v16` launch failed because its canonical real-row base
directory was absent; it ran no subgates. That failure remains explicit. The
fresh, same-source `full-v17` passes every gate with actual return code zero.

## Complete-input and source binding

Complete census and production traverse all **8,928** original definitions and
agree on **8,829 selections and 99 rejections**. Event audits balance every
function begin/end. Runtime census, production and events cover all 455
original definitions. Both production runs finish at the remaining selection
failures with expected actual return code one and verified input/backend
identities. These are completed selection proofs with incomplete objects.

All **3,249 frozen file hashes**, including **598 compiler-source hashes** in
the final build receipts, bind to the accepted code tree. The three executed
binaries, 24 frozen contracts, three AIR payloads and thirteen scratch pins
verify after the long runs. The fixed prefix/cohort, ratchet 130 and
accepted-status file remain unchanged. The release source bundle retains
identity `3b65f5608098bf2c5f7816bea4b38a0cf0333797b516d1c7ae21d1f7e89d5249`.
Concurrent timings demonstrate completion without a controlled performance
ratio. Earlier prototypes retain no cumulative acceptance credit.

Continue the [all-8,928 plan](../plans/2026-11-08-complete-compiler-selection.md).
The isolated extended80 payload and direct-call successor requires its own
complete original-input acceptance.
