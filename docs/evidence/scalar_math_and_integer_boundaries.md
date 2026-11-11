# Scalar math and integer boundaries

Accepted code `516c7b43bc5e1a95e1f4e0ae2beab11ecf92c6f0` selects
**8,879/8,928** original compiler definitions, adding nineteen without lost
selections or owner changes. Independent production agrees on every outcome
and rejection tuple. Runtime reaches **353/455**, adding two and preserving every
earlier selection and owner. All **49 remaining original compiler definitions**
stay in scope. Selection does not establish complete objects, compiler startup
or self-rebuild.

The [acceptance record](scalar_math_and_integer_boundaries_acceptance_20261111.json)
binds the replays to code tree `145e0e4b73194596d590a6d32d80ba18fe9cdb30`.
Local evidence is retained under
`local-state/validations/compiler-selection-completion-20261108/batch-22/`.

## Lowering contracts

Store-only half storage retains exact two-byte accesses. Wide byte swaps use
the existing exact integer pairs; scalar i1 choices between two FP lanes use
the validated scalar/vector boundary. The
[integer and scalar-vector contracts](../codegen/integer_and_scalar_vector_boundaries.md)
retain the existing owners and defined-lane rules.

[Scalar integer conversions](../codegen/scalar_integer_conversions.md) cover
half, f32, f64 and binary128 numerical conversions with integers through 128
bits. Existing shared helpers and exact pair construction preserve the source
conversion and its defined range. The i128-to-i52 bridge retains the low word
before applying the original width.

[Ordinary math intrinsics](../codegen/extended_math_intrinsics.md) use standard
libm operations through the shared physical call contracts, with canonical
module-alias recursion guards. The native runner accepts explicit optional
libraries for the new population; the preceding default command arguments
remain identical. Helper names live for the complete machine-function lifetime.

Profiling storage now derives its legalizer capacity from the stage enum.
A unit check visits every registered stage. Initial whole-input/native/full-run
attempts hit the old fixed capacity and were canceled through their owned
runners; their captures remain retained. Fresh v11 binaries supply acceptance.
Source IR, value-use interfaces and all frozen guard inventories remain unchanged.

## Validation

Five maintained Zig generators reproduce IR, C drivers and registry entries
exactly. Their populations contain **181 functions** and **1,036,288 observations
per execution**, covering half stores, wide swaps, scalar vector selects,
integer conversions and ordinary math. Independent C/LLVM oracles check edge
representations, rounding, exact stores, protected inputs, guarded outputs and
live values across caller clobbers. All **270 injected faults** are detected
across the Debug and ReleaseFast builds.

Debug and ReleaseSafe each pass **2,139 unit, 63 structural and two profiling
checks**. Readiness passes all eight procedures; ABI differential checks match
sixty cases and thirty function/mode combinations. Both complete
**101-population** native suites pass **76,511,010 local / 38,255,505 reference
observations per build**. Strict comparisons preserve all preceding 96 registry
entries, **3,557 command outcomes** and **1,461 artifact hashes** per build:
297 optimizer outputs, 579 owner manifests and 585 objects. No artifact
differences are waived.

All **seventeen integration gates** pass. The three real-row modes retain
100 emitted/linked objects and twelve executed core functions each. All 36 core
descriptors, selected objects, observations, witnesses and statuses match.
Wrapper metadata differs in 32 records, confined to the four reviewed reference
and linked size/hash fields. The strict all-field core comparison retains actual
return code one. Strict full and real-row comparisons also retain actual one at
**1,535 versus 1,540** canonical records after five mandatory population summaries
were added. Complete log equality is not claimed.

## Complete inputs and retained identities

Census and independent production traverse all **8,928** original definitions
and agree on **8,879 selections and 49 rejections**. All **4,397,032 compiler
event rows** audit successfully, with balanced function begin/end pairs.
Runtime census, production and events cover all 455 original definitions and
agree on 353 selections. Production runs finish with expected actual return
code one at the remaining failures; input and backend identities verify.

All **3,311 frozen file hashes**, including **607 compiler source/build inputs**
in the final receipts, bind to the accepted code tree. Three executed binaries,
24 frozen contracts, three AIR payloads and thirteen scratch pins verify after
the long runs. The prefix/cohort, ratchet 130 and accepted-status file remain
unchanged. The retained release bundle manifest verifies identity
`3b65f5608098bf2c5f7816bea4b38a0cf0333797b516d1c7ae21d1f7e89d5249`.
Concurrent timings establish completion without a controlled performance ratio.

Continue the [all-8,928 plan](../plans/2026-11-08-complete-compiler-selection.md).
Subsequent half math, extended80 arithmetic, remainders, vector classification,
wide counts and larger storage remain provisional until their own complete
original-input acceptance.
