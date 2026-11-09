# Scalar comparisons and pointer freeze

Status: accepted at `9ba5e61c`, following `7080d454`. This is an intermediate
checkpoint in the active [all-8,928 selection plan](../plans/2026-11-08-complete-compiler-selection.md).
The remaining 985 definitions are still in scope.

Record: [acceptance JSON](scalar_comparisons_pointer_freeze_acceptance_20261109.json).
Raw evidence: `local-state/validations/compiler-selection-completion-20261108/batch-01/`.
Contracts: [comparisons](../codegen/scalar_comparison_normalization.md) and
[freeze aliases](../codegen/narrow_freeze.md).

## Implementation

Pointer freezes alias compatible argument, scratch, accumulator, spill, frame,
array, derived-address, and readonly-table locations. Freeze emits no instruction
or mask and preserves EFLAGS and wider aliases. Explicit undefined literals and
incompatible locations retain their boundaries.

Private scalar comparison normalization now includes `samesign`, preserving
the source IR and its declared widths. The preceding compiler returned false
for a defined dirty-carrier i8 comparison whose LLVM result is true. The repair
returns true. Immediate comparisons also interpret unsigned-spelled i32 literals
as the same 32-bit patterns for signed predicates. Rollback and the frozen
specialized-bypass inventory remain intact.

## Complete original-input selections

| Population | Before | After | Remaining | Lost successes |
| --- | ---: | ---: | ---: | ---: |
| Compiler | 7,799 / 8,928 | 7,943 / 8,928 | 985 | 0 |
| Runtime | 284 / 455 | 285 / 455 | 170 | 0 |

All 144 compiler additions belong to the 164 targeted first failures: pointer
freeze, integer comparison form, and immediate comparison range. Every targeted
first boundary advances; twenty functions reach later call, cast, memory-width,
or PHI limits. The runtime addition is `compiler_rt.addf3.add_f16`.

Both production replays match their censuses on selected identities and every
rejection tuple. Event audits cover 3,464,216 ordered compiler events and all
8,928 definitions, plus 70,548 runtime events and all 455 definitions. Both
reports remain complete blocked-selection reports. No complete compiler/runtime
object, startup, or self-rebuild success is claimed.

## Validation

Debug and ReleaseSafe each pass 1,995 unit tests and 23 structural checks.
All nine readiness commands pass. Units exercise all ten predicates across
fourteen widths, dirty carriers, literal spellings, source preservation,
physical pointer homes, aliasing, flags, and rejection rollback.

The seven-function pointer population contributes 10,752 local observations
against 5,376 LLVM references per compiler build. The eight-function comparison
population contributes 49,152 local observations against 24,576 references.
Both pass direct/release routes in Fast/Safe/Small with the frozen Debug and
ReleaseFast compilers. The baseline dirty-byte executable fails as expected;
LLVM and the fixed compiler pass. An independently mutated comparison is
rejected by the C oracle with exit status 7.

The cumulative serial run passes all 17 gates in 3,732.75 seconds. Its 66 native
populations record 2,043,396 local observations against 1,021,698 references;
all 64 preceding population records are preserved. Three authenticated AIR
cache hits retain the preceding keys and descriptor sizes. Producer and cache
infrastructure are unchanged, so no fresh/cache pair is required for this slice.

All five fixed programs pass fifteen program/mode pairs. The Zig corpus retains
87 pairs and 603 controls; the C corpus retains 138 pairs and 552 controls.
Core fault controls exactly retain 21 pairs, 22,788 observations, and all 54
fault detections. Zig corpus selected identities and ownership are unchanged.
Its ReleaseSafe `heap.SafeAllocator.AllocFooter.lenLarge` uses one fewer
selection iteration, two fewer instructions, and one fewer spill; other modes'
aggregate counters match. All corpus observations are preserved.

Each core mode retains 100 lowered/emitted/linked functions and twelve
executed/accepted functions. All 36 records preserve selected-object bytes,
descriptors, results, witnesses, counts, and statuses. Executable metadata is
retained separately: 35 linked sizes match; Fast `atomic.Mutex.tryLock` grows
from 6,283,657 to 6,287,753 bytes. Fast/Safe reference wrappers grow by 96 or
104 bytes; Small reference sizes and hashes match. Five Small linked hashes
match; the other 31 differ. The original linked-size comparison failure and
the explicit four-field metadata review are retained. No exact ELF-section
cause or whole-executable byte identity is claimed.

The 100-row prefix, twelve-function cohort, and ratchet 130 remain unchanged.
The separate runtime census count of 285 is not a new compiler-rt ratchet.

## Identity and retention

Implementation: `9ba5e61c20c3ed5632514eeb56ca933fa1e57469`.
Tree: `85de42914a3089185193d7e0b7ca2127bd31101f`.
The 1,779-file source manifest and complete 3,098-file membership snapshot
verify before and after validation. Acceptance documentation follows the freeze.

| Compiler | SHA-256 |
| --- | --- |
| Debug | `53a5282103a984b748a5dbc909df37effba4b26dbac39a63c61f115f82b20cd4` |
| ReleaseSafe | `87b78cead7ebd1dfae26b3ce027de81eb19e429295e6b94064e620808583210c` |
| ReleaseFast | `08c73c739ac47610eeba3d195f8ae26fb3689e6dccef8a535b94c7d046470da1` |

The suite Debug binary matches the frozen Debug binary. Larger input corpora
and fixed Zig hooks use explicit ReleaseFast; the upstream C/native consumer
uses authenticated Debug. Zig remains 0.17.0, the fixture emitter pin remains
`1c08b09d1`, and clang is 22.1.8.

The original compiler input retains SHA-256
`de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`.
Source, compiler, frontend, input, and scratch hashes verify. The preceding
602-artifact seal verifies. The new 920-artifact seal has SHA-256
`971c4bbaa9bddf0d1a6dea79b05ae7d2e1d3ba972566e5345a9295ec2cb725f1`.
Original inputs, preceding evidence, AIR payloads, and all thirteen scratch
files remain. No manual cache retirement or archives were performed.

Serial admission records 40,521,461,760 free bytes; the serial minimum is
36,101,746,688 and the outer capture minimum is 34,547,077,120. All exceed the
unchanged 11,410,065,408-byte reserve. Timings and filesystem samples include
concurrent activity and are not exclusive usage or throughput measurements.
