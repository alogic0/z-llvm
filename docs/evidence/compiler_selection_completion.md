# Complete original compiler selection

Accepted code `efa62fa2d182bf0a5f2c5e7b1b239dcbb0aab898` selects
**8,928/8,928** definitions from the unchanged original compiler input. Complete
census and independent production agree on every function, adding all 49
remaining selections without losing a preceding selection or changing an owner.
Runtime reaches **387/455**, adding 34 and preserving every earlier selection
and owner. The [all-8,928 selection plan](../plans/2026-11-08-complete-compiler-selection.md)
is complete.

The [acceptance record](compiler_selection_completion_acceptance_20261111.json)
binds the proofs to code tree `1463c97bf2380279d773caf446a779a25750e05d`.
Retained evidence is under
`local-state/validations/compiler-selection-completion-20261108/batch-30/`.

Selection remains distinct from object emission, startup and self-rebuild.
Independent production completes all 8,928 selections, then returns actual
code one with `UnsupportedGlobalData` during `object_write`. Its complete event
stream and unchanged source/backend identities verify. No complete compiler
object, startup or self-rebuild is claimed. The remaining 68 runtime definitions
also receive no completion credit.

## Lowering contracts

[Half math and square root](../codegen/half_math_and_scalar_sqrt.md),
[extended80 arithmetic](../codegen/extended80_arithmetic.md) and
[floating remainders](../codegen/floating_remainders.md) reuse typed payloads,
physical ABI planning and ordinary helper calls. Literal SSE arguments stage
without overwriting earlier operands. Temporary homes are reclaimed only when
the captured allocation suffix contains exactly those staged homes; durable
allocations prevent reclamation. A 97-call executable case checks bounded
staging, and complete runtime evidence preserves the earlier cosq/sinq owners.

[Integer call boundaries](../codegen/integer_call_boundaries.md),
[wide integer values](../codegen/wide_integer_counts_and_calls.md),
[vector counts and half classification](../codegen/vector_counts_and_half_classes.md)
and [larger storage](../codegen/large_objects_and_scalar_pointer_loads.md)
retain source widths, defined ranges, exact stores and the shared physical ABI.
Unsigned i128 multiply-overflow uses ordinary wrapped products and a guarded
division identity. Private layout legalization retains the original owned-object
authority for larger allocations.

[Vector transport and PHI fallback](../codegen/vector_transport_and_phi_fallback.md)
handle nonnative wide aliases, byte-vector GEPs and binary128 payloads through
existing typed operations and owned storage. Parallel PHI snapshots preserve
cycles; packed literals retain their source bits. Defined eight-byte sentinel
address round trips use private pointer arithmetic. Frozen Source/value-use
interfaces, frame authority and guard inventories remain unchanged.

[CPU queries](../codegen/hardware_queries.md) admit the exact pinned CPUID and
ECX-zeroing XGETBV forms. A private verifier marker, packed integer outputs,
canonical i32 extraction definitions and shared typed preparation preserve
live values. CPUID saves RBX with zero net stack displacement. Source guards
instruction availability. Independent execution checks all four outputs,
delayed comparisons, guarded XCR0, live pairs, RBX, stack and byte guards.

## Validation and preservation

Debug and ReleaseSafe each pass **2,157 unit, 63 structural and two profiling
checks**. All eight readiness procedures pass; ABI differential validation
matches sixty cases and thirty function/mode combinations. Eleven maintained
Zig generators reproduce all **22 IR/C files** and exact registry entries.
Their eleven populations contain **133 functions** and **3,010,560 observations
per executable**. All **594 injected faults** are detected across the Debug
and ReleaseFast builds.

Both complete **112-population** native suites pass **94,574,370 local /
47,287,185 reference observations per build**. Strict comparisons preserve all
101 prior registry entries, **3,737 command outcomes** and **1,536 artifact
hashes** per build: 312 optimizer outputs, 609 owner manifests and 615 objects.
No artifact differences are waived.

All **seventeen integration gates** pass. The three real-row modes retain
100 emitted/linked objects and twelve executed core functions each. All 36
core descriptors, selected objects, observations, witnesses and statuses match.
Thirty wrapper records differ only in the four reviewed reference/link size
and hash fields; strict all-field comparison retains actual one. Strict full
and real-row log comparisons also retain actual one at **1,540 versus 1,551**
canonical records after eleven mandatory population summaries were added.
Complete log equality is not claimed.

The retained 100-object release bundle verifies every object against its
manifest. That manifest is byte-identical to the accepted identity
`3b65f5608098bf2c5f7816bea4b38a0cf0333797b516d1c7ae21d1f7e89d5249`;
the full run independently records its production and three consumers.

## Complete inputs and retained identities

Compiler census and production cover the original **443,624,107 bytes** and
all **8,928 definitions**, SHA-256
`de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`.
All **4,492,466 compiler event records** audit successfully, including balanced
begin/end pairs for all 8,928 functions. Runtime census, production and events
cover all 455 original definitions and agree on 387 selections and 68
rejections, preserving every preceding identity and owner.

All **3,373 frozen file hashes**, including **614 compiler source/build inputs**,
bind to the accepted code tree. Three executed binaries, 24 frozen contracts,
three AIR payloads and thirteen scratch pins verify after the long runs. The
preceding checkpoint's artifact seal verifies unchanged. The prefix/cohort,
ratchet 130 and accepted-status file remain unchanged. Concurrent timings
establish completion without a controlled performance ratio.

The [Zig helper migration](batch08_zig_helpers.md) and
[validation-performance delivery](validation_performance.md) remain accepted.
Next work is the `UnsupportedGlobalData` object boundary and remaining runtime
definitions, followed by unchanged whole-compiler linking, startup and
self-rebuild validation.
