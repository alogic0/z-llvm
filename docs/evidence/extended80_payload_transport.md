# Extended80 payload transport and direct calls

Accepted code `50ba1a5dfaadfa8a1d75b768ee835f52bd1c1ca4` selects
**8,838/8,928** original compiler definitions, adding nine with no lost
selections or owner changes. Independent production agrees on every outcome
and rejection tuple. Runtime reaches **331/455**, adding eleven while
preserving every prior selection and owner. All **90 remaining original
compiler definitions** stay in scope. Selection does not establish complete
objects, startup or self-rebuild.

The [acceptance record](extended80_payload_transport_acceptance_20261110.json)
binds the complete replays to code tree
`a9983b2d916450e635059c1b5d3dc4351d31e636`. Local evidence is retained under
`local-state/validations/compiler-selection-completion-20261108/batch-16/`.

## Lowering contracts

The [extended80 payload contract](../codegen/extended80_payloads.md) represents
values privately as exact integer bits. External loads and stores access ten
bytes; owned objects retain sixteen-byte allocation size and stride. Bitcasts,
freezes, selects, PHIs and constants preserve raw payloads, including signed
zero and NaN bits.

Incoming extended80 arguments occupy aligned memory slots without consuming
the integer-register cursor. Direct integer/pointer calls use the existing
stack-argument authority. Returns transfer between the private integer pair
and physical ST0; callers capture and pop every named result, including unused
results. A path-sensitive verifier checks x87 stack depth, control-flow joins,
call boundaries and return depth. It does not prove general register dataflow.
Mixed SSE/extended80 calls and numerical extended80 operations remain closed
in this accepted checkpoint. Source IR and frozen Source/UseForm contracts
remain unchanged.

## Validation

The maintained Zig generator reproduces its IR, C driver and registry entry
exactly. Its population contains **13 functions** and **53,248 observations per
execution**. Integer bit oracles cover arbitrary raw payloads, signaling NaNs,
signed zero, protected-page ten-byte reads, exact stores, sixteen-byte strides,
stable freezes, PHIs, aligned incoming stack arguments and subsequent pointers.
Two provider calls exercise result preservation across real clobbers of nine
GPRs, unused return capture and x87 stack balance. Both compiler builds pass
**319,488 local / 159,744 reference observations** for this population, and all
**54 injected faults** are detected across the two builds.

Debug and ReleaseSafe each pass **2,121 unit, 63 structural and two profiling
checks**. Readiness passes all eight inner procedures with private caches;
ABI differential checks match sixty cases and thirty function/mode combinations.
Both complete **92-population** native suites pass **60,141,858 local /
30,070,929 reference observations per build**. Both strict native comparisons
preserve all preceding 91 entries, **3,377 command outcomes** and **1,386 prior
artifact hashes**: 282 optimizer outputs, 549 owner manifests and 555 objects.

All **seventeen integration gates** pass. Each real-row mode retains the fixed
100 emitted and linked objects and twelve executed core functions. All 36 core
descriptors, selected objects, observations, witnesses and statuses match.
Reference/linked wrapper metadata differs in 28 records, confined to four
audited fields. Strict all-field core comparison retains actual return code
one. Strict full and real-row comparisons also retain actual return code one
at **1,530 versus 1,531** canonical records after adding the mandatory population
summary. Complete log equality is not claimed.

## Complete-input and source binding

Complete census and production traverse all **8,928** original definitions and
agree on **8,838 selections and 90 rejections**. All **4,371,382 compiler event
rows** audit successfully with balanced function begin/end records. Runtime
census, production and events cover all 455 original definitions. Both
production runs finish at the remaining selection failures with expected
actual return code one and verified input/backend identities. Objects remain
incomplete.

All **3,259 frozen file hashes**, including **601 compiler-source hashes** in
the final build receipts, bind to the accepted code tree. The three executed
binaries, 24 frozen contracts, three AIR payloads and thirteen scratch pins
verify after the long runs. The fixed prefix/cohort, ratchet 130 and
accepted-status file remain unchanged. The release source bundle retains
identity `3b65f5608098bf2c5f7816bea4b38a0cf0333797b516d1c7ae21d1f7e89d5249`.
Concurrent timings establish completion without a controlled performance
ratio. Isolated conversion, comparison and sign-operation prototypes receive
no cumulative acceptance credit.

Continue the [all-8,928 plan](../plans/2026-11-08-complete-compiler-selection.md).
