# Floating conversions, predicates and sign operations

Accepted code `669fd097ba1a411925c2037e54c906fadd4e9608` selects
**8,860/8,928** original compiler definitions, adding 22 with no lost
selections or owner changes. Independent production agrees on every outcome
and rejection tuple. Runtime reaches **351/455**, adding twenty while retaining
every earlier selection and owner. All **68 remaining original compiler
definitions** stay in scope. Selection does not establish complete objects,
compiler startup or self-rebuild.

The [acceptance record](floating_conversions_predicates_acceptance_20261111.json)
binds the complete replays to code tree
`e4674ae47767437119835b94a41589adf66bef38`. Local evidence is retained under
`local-state/validations/compiler-selection-completion-20261108/batch-18/`.

## Lowering contracts

[Extended80 conversions](../codegen/extended80_conversions.md) use standard
runtime helpers through shared physical transfer contracts. Integers of widths
one through 128 extend exactly to i128 before conversion; defined narrower
results truncate exactly from the wider helper result. Half and quad conversions
use their standard helpers. Float/double bridges extend exactly to binary128
before the single requested rounding. Double-to-half uses its direct helper.
Large literals receive exact named pairs. Canonical helper identity, including
quoted names, prevents immediate recursive outlining.

Mixed calls place GPR, SSE and aligned extended80 memory arguments independently.
They share stack staging and preserve live inputs and captured ST0 results.
Unsupported split integer words, SSE overflow, indirect extended80 calls and
incompatible attributes remain closed.

[Predicates and signs](../codegen/extended_floating_predicates_and_signs.md)
lower all sixteen extended80 comparisons through integer representation
classification. Signed zeros compare equal; pseudo-denormals compare like their
normal equivalent, and unsupported explicit-integer-bit encodings are unordered.
Half comparisons widen exactly to binary32. Extended80 and binary128 negation,
absolute value and copy-sign change only the sign bit, preserving NaN payloads
and signaling bits. The established simple negation return shape retains its
structural owner through a shared matcher. Original IR and frozen Source/UseForm
contracts stay unchanged.

## Validation

Four maintained Zig generators reproduce their IR, C drivers and registry
entries exactly. Their populations contain **44 integer/extended80 functions,
12 floating-conversion functions, 34 predicate functions and six sign functions**,
with **1,691,904 observations per execution** in total. Independent integer
rounding/truncation and sign-bit oracles, plus hardware predicate comparisons,
cover edge representations, every half input where specified, mixed physical
arguments, protected input boundaries, exact stores and live values across real
clobbers of nine GPRs and sixteen XMM registers. All **216 injected faults** are
detected across the two compiler builds.

Debug and ReleaseSafe each pass **2,127 unit, 63 structural and two profiling
checks**. Readiness passes all eight inner procedures; ABI differential checks
match sixty cases and thirty function/mode combinations. Both complete
**96-population** native suites pass **70,293,282 local / 35,146,641 reference
observations per build**. Both strict native comparisons preserve all preceding
92 registry entries, **3,413 command outcomes** and **1,401 artifact hashes**:
285 optimizer outputs, 555 owner manifests and 561 objects. No artifact
differences are waived.

All **seventeen integration gates** pass. Each real-row mode retains the fixed
100 emitted and linked objects and twelve executed core functions. All 36 core
descriptors, selected objects, observations, witnesses and statuses match.
Wrapper metadata differs in thirty records, confined to four reviewed fields.
Strict all-field core comparison retains actual return code one. Strict full
and real-row comparisons also retain actual return code one at **1,531 versus
1,535** canonical records after adding four mandatory population summaries.
Complete log equality is not claimed.

## Complete-input and source binding

Census and independent production traverse all **8,928** original definitions
and agree on **8,860 selections and 68 rejections**. The **4,375,366 compiler
event rows** audit successfully, with all function begin/end pairs balanced.
Runtime census, production and events cover all 455 original definitions.
Both production runs finish with expected actual return code one at their
remaining selection failures and verified input/backend identities. Objects
remain incomplete.

All **3,282 frozen file hashes**, including **603 compiler-source/build input
hashes** in the final build receipts, bind to the accepted code tree. Three
executed binaries, 24 frozen contracts, three AIR payloads and thirteen scratch
pins verify after the long runs. The prefix/cohort, ratchet 130 and accepted-status
file stay unchanged. The release source bundle retains identity
`3b65f5608098bf2c5f7816bea4b38a0cf0333797b516d1c7ae21d1f7e89d5249`.
Concurrent timings establish completion without a controlled performance ratio.

Initial acceptance-record construction failed because process receipts
overwrote two binding-report paths. Fresh binding and acceptance records use
distinct names and pass every check; the original captures remain retained.
Earlier prototypes receive no cumulative acceptance credit.

Continue the [all-8,928 plan](../plans/2026-11-08-complete-compiler-selection.md).
Subsequent storage, byte-swap, scalar-select and math work needs its own complete
original-input acceptance.
