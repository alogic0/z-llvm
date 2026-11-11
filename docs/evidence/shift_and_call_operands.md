# Shift operands and call attributes

Accepted code `2eb2fc9b` selects **8,807/8,928** unchanged compiler definitions,
adding fifteen with no lost selections or owner changes. Independent production
agrees on every outcome and failure tuple. Runtime retains **318/455**. All
**121 remaining original compiler rejections** stay in the main plan; complete
objects, compiler startup and self-rebuild remain separate claims.

The [acceptance record](shift_and_call_operands_acceptance_20261110.json) binds
the complete replays, source, binaries and explicit artifact reviews to the code
tree. Local evidence remains under
`local-state/validations/compiler-selection-completion-20261108/batch-13/`.

## Shared operand and ABI changes

The [private shift view](../codegen/integer_shift_operands.md) materializes a
constant left operand before ordinary 32/64-bit shifting. It also admits
nonprimitive constant i128 logical-right shifts through the existing scalar-word
expansion, while retaining primitive projections and original-form retries.
Source opcodes, flags, result identities and defined shift-count domains remain
intact. The original SipHash final function now selects through the composed
block owner; the canary retains its full computation and an independent C oracle.

The [call-attribute change](../codegen/call_return_attributes.md) admits `zeroext`
integers below 32 bits through existing clean carriers, and typed
`dereferenceable_or_null(N)` pointer promises. The verifier validates their
spelling, type, range and duplicate attributes. Sign-extension admission remains
closed. New selections include threaded concurrency, thread spawning, linker
flush/dispatch, operand lowering, LLVM emission and integer-bound functions.
No frozen Source/UseForm interface or name-based admission is added.

## Native and cumulative checks

The 36-function shift population checks **22,536 observations per execution**:
word shifts, full-width pair counts, live values, guarded unaligned stores and
the original SipHash computation, including protected-page input boundaries.
The 15-function call population checks **520 observations per execution** over
six integer widths, eight arguments with stack traffic, actual register
clobbers, live values and nullable pointer returns. Return probes observe only
the AL/AX/EAX container guaranteed by the LLVM zero-extension ABI.

Both Zig generators reproduce their tracked IR and C files exactly. Both final
compiler builds pass both local routes and all three modes for the new
populations: **138,336 local / 69,168 reference observations per build**. All
**162 injected fault controls** are detected. Debug and ReleaseSafe each pass
**2,106 unit, 25 structural and two profiling checks**. All nine readiness
procedures pass, including sixty ABI cases and thirty function/mode matches
with their negative controls.

Both complete **86-population** native suites pass **2,697,042 local /
1,348,521 reference observations per build**. All preceding 84 registry entries
and **3,125 prior command outcomes** are preserved. Of the prior 1,281 compiler
artifacts, **1,269 remain byte-identical**: 261 optimizer outputs, 507 owner
manifests and 501 objects. Twelve object records require the explicit review
below; neither strict native comparator is reported as passing.

All **seventeen integration gates** pass with actual return code zero. Each
real-row mode emits and links the fixed 100 objects and executes the unchanged
twelve core functions. The release source bundle retains identity
`3b65f5608098bf2c5f7816bea4b38a0cf0333797b516d1c7ae21d1f7e89d5249`,
produced once and consumed three times without cached executions. Strict full
and real-row log comparisons retain actual return code one at **1,523 versus
1,525** canonical records. Complete log equality is not claimed.

## Explicit object reviews

The twelve native object differences affect only `vector_graph_repack` and
`vector_mask_reverse128`, repeated across modes and routes. A read-only ELF
inventory proves every other function body in those objects is unchanged. The
new constant-pair shift admission selects the existing scalar-word expansion;
a one-predicate ablation restores **all twelve prior objects byte for byte**.
Both final compiler builds produce the same reviewed differences and pass the
unchanged LLVM/C native oracles. Strict requires-review reports remain retained.

Nine core object hashes also change: `ascii.isAscii` and the two metadata byte
predicates in three modes. Authenticated AIR descriptors reproduce both old and
current objects exactly, with identical public IR. Every changed body grows
from 50 to 55 bytes solely by inserting one `AND EAX,255` immediately after the
same existing mask. All other function bytes match. This redundant mask follows
the new incoming-byte normalization. All 36 identities, descriptors, object
extents, observations, witnesses and statuses are preserved. The strict core
comparison retains actual return code five; the separate review records the
nine intentional hash changes and wrapper metadata differences in 33 records.
Inspection uses read-only ELF parsing and disassembly.

## Source and complete-input binding

Complete census and independent production each traverse all 8,928 original
definitions and agree on 8,807 selections and 121 failures. Every previous
selection and owner is preserved, and all **4,366,614 compiler events** balance.
Runtime census, production and events cover all 455 original definitions and
retain 318 selections. Both production runs finish at their remaining selection
failures with expected actual return code one and verified source/backend
identities; complete object emission is not established.

All **3,218 frozen file hashes**, including **596 compiler-source hashes** in
both final build receipts, bind to code tree
`735bf1b7f3ec713caf842a01ca1a1ced91190cb6`. Source and executed binaries verify
after the long runs. The fixed prefix/cohort, ratchet 130, accepted-status file,
three AIR payloads and thirteen scratch pins remain unchanged. Failed fixtures,
the corrected return probe and earlier diagnostics remain retained without
acceptance credit. Concurrent timings establish completion without a controlled
performance ratio.

Continue the [all-8,928 plan](../plans/2026-11-08-complete-compiler-selection.md).
The next coherent group addresses full-width integer division, typed i52
truncations and freezing existing two-word records, followed by every remaining
original compiler rejection. Its isolated bounded diagnostics receive no
cumulative credit before complete original-input acceptance.
