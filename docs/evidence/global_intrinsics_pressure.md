# Global TLS addresses, scalar bit intrinsics and register pressure

Status: accepted. All 17 cumulative integration gates pass on the frozen sources.
Record: [machine-readable acceptance](global_intrinsics_pressure_acceptance_20261108.json).
Plan: [ordered implementation plan](../plans/2026-11-08-global-intrinsics-pressure.md).
Raw evidence: `local-state/validations/global-intrinsics-pressure-20261108/`.

The implementation is frozen at `4b8eac2a`. The preceding accepted revision is
`761ea199`, documented at `bdd92055`. Logical implementation commits are
`99a26fab` (TLS), `84a1cd3e` (intrinsics), `f31c061a` (reviewed intrinsic guard),
`99b9cab3` (pressure), and `4b8eac2a` (reproducible fixture formatting).

## Shared global-address contract

An observational replay preserves every baseline outcome before changing
selection. Its resolved-global records explain all 378 property rejections:
372 have the main control-flow diagnostic, five have the varargs diagnostic,
and one has an instruction diagnostic. All involve TLS. The concrete properties
are 375 private, eight-byte-aligned thread-local globals; two private,
one-byte-aligned signal-stack arrays; and one internal, one-byte-aligned flag.

The shared symbolic-address path now accepts default and explicit general-dynamic
TLS. It retains the original alias symbol, addend, linkage, visibility, alignment
and dependency checks. The ELF writer places reached TLS definitions in aligned
`.tdata`, marks definitions and external declarations `STT_TLS`, and rejects
mismatched ordinary/TLS address instructions. Relocated TLS initializers remain
explicitly unsupported. Other explicit TLS models retain their prior boundaries.

`tls_address_rax` represents the resolver call and its full caller-saved register
and flags effects. Existing call-preservation transactions protect GPR and SSE
values and align the stack. The encoder and assembly printer emit the standard
16-byte TLSGD sequence, with `R_X86_64_TLSGD` and `R_X86_64_PLT32` relocations;
checked addends are applied to the returned address. This follows the
[x86-64 psABI](https://raw.githubusercontent.com/wiki/hjl-tools/x86-psabi/x86-64-psABI-1.0.pdf).

Two permanent populations run the same six functions as an executable and a
shared library. Five concurrent threads check independent initialization,
mutation, alignment, alias identity, byte arrays, live GPR/SSE values and PHIs.
The shared library exercises the resolver path as well as executable linker
relaxation. Each route has 2,560 observations per mode. Object and shared-library
relocation dumps are retained.

The TLS replay selects 6,763 of 8,928 compiler definitions: eleven additions,
with no lost successes. Runtime stays at 274 of 455. The property rejections
disappear; 327 functions now first reject result-bearing inline assembly.

## Scalar bit intrinsics

The existing integer-intrinsic legalizer now expands missing scalar widths for
`ctpop`, `cttz`, `ctlz`, `abs`, `bswap` and `fshl` into shared native-width
operations. Valid scalar advisory facts are checked and omitted from private
widened calls. Existing native forms remain available, including native `ctpop`
with `fastcc`. The change also covers facts on native min/max and overflow inputs.

Population count masks the logical input before widening. Narrow trailing-zero
count uses a sentinel above the logical width, and leading-zero count subtracts
the carrier padding. Funnel shifts reduce the unsigned count modulo the logical
width, define the zero-count case and avoid shifts by the carrier width. Distinct
left/right inputs and non-power-of-two widths are covered. The semantic basis is
the [LLVM language reference](https://llvm.org/docs/LangRef.html).

`llvm.load.relative.i64` expands to a signed 32-bit displacement load at
`base + offset`, followed by addition to the original base. Positive and negative
table offsets and displacements execute against an independent C oracle.

Executable unit combinations cover fourteen widths from one through 64 bits,
dirty upper bits, live aliases, zero and boundary counts, and unsupported
signatures and semantic envelopes. The native bit population adds fifteen
functions and 7,680 observations per route/mode, including a real clobbering
call. Relative loads add two functions and 512 observations.

The complete intrinsic replay selects 6,976 compiler and 284 runtime functions,
adding 213 and ten respectively without losing a TLS-checkpoint success. All
217 main intrinsic first failures advance: 177 select, while forty expose later
rejections. The additional intrinsic failure with an instruction diagnostic also
selects. These transition counts do not imply that every affected function emits
a complete object.

The largest named groups after this slice are:

| Original first intrinsic | Functions | Now select | Expose later failures |
| --- | ---: | ---: | ---: |
| `llvm.ctpop.i32` | 54 | 45 | 9 |
| `llvm.fshl.i64` | 47 | 42 | 5 |
| `llvm.fshl.i16` | 40 | 29 | 11 |
| `llvm.ctpop.i16` | 13 | 11 | 2 |

The unchanged full inputs and all per-function transitions are retained; these
are not counts from reduced reproductions.

The source guard's `lowerCtpop` fingerprint was reviewed and updated for its
attribute checks. Its register operations and the bypass ratchet are unchanged.

## Register pressure

The post-intrinsic census records 186 pressure rejections, including the separate
outer diagnostic. Their peak live sets range from 39 to 261 values; fifteen also
exceed the independent 1,024-block boundary. The complete classification is
retained in `pressure-classification.json`.

Selection no longer rejects a multi-block function solely for exceeding six
register values plus the minimum 32-slot spill reservation. The existing shared
allocation plan already sizes spill and emergency homes dynamically. Concrete
frame layout, checked arithmetic, frame-index validation, page probing and the
one-MiB limit remain authoritative. The old pressure summary remains available
as a diagnostic comparison with the minimum reservation, not an admission rule.

A concrete frame rejection now includes pressure observations. A regression
checks the frame limit, machine/ownership rollback, and clearing stale observer
state before a subsequent successful selection.

The permanent native pressure fixture covers 48, 96 and 288 live values at both
32 and 64 bits. Values survive a caller-saved-register clobber and a diamond with
PHI permutations and aliases. Weighted results make transfer permutations
observable; an independent C oracle also checks unaligned input and memory
canaries. Six functions supply 768 observations per route/mode. Reproduce the IR
with `zig run tools/generate_register_pressure_fixture.zig`.

The pressure replay selects 7,040 compiler definitions, 64 more than the
intrinsic checkpoint, and retains all 284 runtime selections. Of the original
184 main pressure failures, 61 now select and 123 reach other boundaries. The
separate varargs pressure failure reaches inline assembly. No fixed-threshold
pressure first rejection remains. All 6,752 compiler and 274 runtime successes
from the preceding accepted checkpoint are preserved.

| Checkpoint | Compiler selected / total | Runtime selected / total | Lost prior successes |
| --- | ---: | ---: | ---: |
| Previous accepted baseline | 6,752 / 8,928 | 274 / 455 | — |
| TLS | 6,763 / 8,928 | 274 / 455 | 0 |
| Intrinsics | 6,976 / 8,928 | 284 / 455 | 0 |
| Checked dynamic frames | 7,040 / 8,928 | 284 / 455 | 0 |

The largest final compiler groups are 327 result-bearing inline-assembly
rejections, 179 comparison RHS rejections, 133 general stage-two value
rejections, 123 alloca type rejections, and 113 each for unknown call arguments
and readonly-table globals. Counts are grouped by the full diagnostic/tag/detail
tuple. The next repair should classify the actual inline-assembly operations and
constraints before extending shared instruction effects; do not turn arbitrary
inline assembly into unchecked text emission.

## Acceptance boundaries

All 17 integration gates and 58 native populations pass. The cumulative native
suite records 1,914,372 local observations against 957,186 LLVM references.
All 53 previous population records are preserved. Five unchanged fixed Zig
programs pass in all three modes. The larger Zig corpus preserves all 87
input/mode pairs and 603 observation controls; the C parser preserves 138 pairs
and 552 controls, with unchanged sources and observations. The permanent
compiler-core controls preserve all 21 function/mode pairs, 22,788 observations
and 54 detected faults. The bypass ratchet remains 130.

Debug and ReleaseSafe each pass 1,962 unit tests and 21 structural checks.
Profiling process tests, five whole-compiler reporting checks, seven observer and
source-guard checks, and readiness pass. The five new native populations pass
with both Debug and ReleaseFast compilers: 29 distinct fixture functions supply
84,480 local observations against 42,240 LLVM-reference observations per compiler
build. The TLS fixture runs in two populations, executable and shared-library.

Both frozen production replays match every diagnostic selected-function identity
and complete failure tuple. Audited event streams contain 8,928 and 455 matching
function start/end pairs, respectively. The compiler replay takes 968.27 seconds
including wrapper work, with maximum RSS 6,488,344 KiB; runtime takes 2.87 seconds.
These measurements include profiling and concurrent validation and are not a
controlled throughput comparison.

All 36 compiler-core records preserve selected-object hashes, execution
observations, reference sizes and linked sizes. Twenty-four reference hashes and
32 linked hashes differ and are recorded separately; no blanket executable byte
identity is claimed. The cohort remains 100 lowered/emitted/linked functions and
twelve executed functions per mode.

The original 443,624,107-byte compiler IR and 1,856,543-byte runtime IR remain
unchanged, with SHA-256 identities `de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`
and `ca04995e5bc4d6537f6e1b994a79569ed8dc10d64451f89dfc0714fb40a732af`.
The pinned frontend and compiler-core cohort remain unchanged. Selection counts
do not establish complete compiler/runtime objects, compiler startup or
self-rebuilding capability.

No archives or cleanup were needed. Original inputs, accepted evidence,
diagnostic worktrees, AIR caches and all thirteen user scratch files are retained.
Admission remains 32,949,672,960 bytes and execution reserve 24,359,738,368 bytes.
The full run starts with 43,103,854,592 bytes free. Additional sampling records a
minimum of 30,897,156,096 bytes, above the execution reserve; the gate records
32,955,338,752 bytes free at completion. The acceptance record retains the final
postcheck reading separately. Source membership and content, both compiler
binaries, original input hashes, prior accepted artifacts and scratch hashes
are checked after validation, before sealing the artifact manifest.
